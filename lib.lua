local dbg = require("debuglib")
require("util")

---------------------------------------------------------------------------
-- globals
local active_nets = {}
local proxies = {} -- all proxies
local rx = {}      -- all receivers
local tx = {}      -- all transmitters
local mod_state = {}

---------------------------------------------------------------------------
local n_tiers = 3
local rate_increment = 15       -- whenever a research is finished, the item transport rate is increased by this amount
local rate_increment_factor = 2 -- whenever the infinite research is finished, multiply the item transport rate by this amount
local slot_bar = 2              -- the combinator's slot which stores the state of the inventory bar (TODO)
local slot_filter = 1           -- the combinator's slot which stores the filter
local wire = defines.wire_type.red

local prefix = "transport-cables:"
local names = {}
for tier = 1, n_tiers do
    names[tier] = {
        cable = prefix .. "cable-t" .. tostring(tier),
        container = prefix .. "container-t" .. tostring(tier),
        lamp = prefix .. "lamp-t" .. tostring(tier),
        node = prefix .. "node-t" .. tostring(tier),
        receiver = prefix .. "receiver-t" .. tostring(tier),
        transmitter = prefix .. "transmitter-t" .. tostring(tier),
        underground_cable = prefix .. "underground-cable-t" .. tostring(tier),
        --
        gui_filter = prefix .. "filter-t" .. tostring(tier),
        gui_frame = prefix .. "frame-t" .. tostring(tier)
    }
end

local network_update_data = {}      -- data collected when the update is triggered
local network_update_scheduled = {} -- is an update of the network ids necessary?

-- When a cable which is connected to another cable (a neighbor) is destroyed, the neighbor might get new neighbors
-- (for example, the neighbor might have been curved and is now straight). But this happens only after the cable
-- has been destroyed. So an update needs to be scheduled on_mined_entity but it cannot be made directly.
-- A similar case can occur when a cable is built and its neighbor turns from curved to straight.
local cable_connection_update = {}

---------------------------------------------------------------------------
-- Move `distance` from `position` in `direction`, yielding a position vector.
local function move_position(position, direction, distance)
    distance = distance or 1

    if direction == defines.direction.north then
        return {
            x = position.x,
            y = position.y - distance
        }
    elseif direction == defines.direction.south then
        return {
            x = position.x,
            y = position.y + distance
        }
    elseif direction == defines.direction.east then
        return {
            x = position.x + distance,
            y = position.y
        }
    elseif direction == defines.direction.west then
        return {
            x = position.x - distance,
            y = position.y
        }
    end
end

local function equal_position(position1, position2)
    return position1.x == position2.x and position1.y == position2.y
end

---------------------------------------------------------------------------
local function get_inventory(entity)
    return entity.get_inventory(defines.inventory.item_main)
end

---------------------------------------------------------------------------
-- Get the proxy associated with `identifier`. The argument `identifier` is
-- either a unit_number or an entity.
local function get_proxy(identifier)
    if type(identifier) == "number" then
        return proxies[identifier]
    else
        return proxies[identifier.unit_number]
    end
end

-- Connect the two proxies associated with `source_entity` and `target_entity`.
local function connect_proxies(source_entity, target_entity)
    if source_entity.type ~= "entity-ghost" and target_entity.type ~= "entity-ghost" then
        get_proxy(source_entity).connect_neighbour {
            wire = wire,
            target_entity = get_proxy(target_entity)
        }

        if dbg.flags.print_connect_proxies then
            dbg.print("connect_proxies(): " .. source_entity.name .. " < == > " .. target_entity.name)
        end
    end
end

-- Destroy the proxy associated with `entity`.
local function destroy_proxy(entity, proxy)
    local destroyed = proxy.destroy()
    proxies[entity.unit_number] = nil
    return destroyed
end

-- Disconnect the circuit connections associated with `entity`'s proxy.
local function disconnect_proxies(entity)
    local proxy = get_proxy(entity)
    if proxy then
        proxy.disconnect_neighbour(wire)
    end

    if dbg.flags.print_connect_proxies then
        dbg.print("disconnect_proxies(): " .. entity.name)
    end
end

---------------------------------------------------------------------------
-- Create a container and associate it with `entity`.
local function create_container(receiver, force, tier)
    -- If there already is a container, do not create a new one.
    local found = game.surfaces[1].find_entity(names[tier].container, receiver.position)
    if found then
        if dbg.flags.print_create_container then
            dbg.print("create_container(): found.unit_number = " ..
                tostring(found.unit_number) .. tostring(", tier = ") .. tostring(tier))
        end
        proxies[receiver.unit_number] = found
        return found
    end

    -- If an upgrade happened, there is a container of a previous tier.
    if tier > 1 then
        -- TODO: should we search through all previous tiers here (e.g., due to double update)?
        local old_container = game.surfaces[1].find_entity(names[tier - 1].container, receiver.position)
        if old_container then
            if dbg.flags.print_create_container then
                dbg.print("create_container(): old_container.unit_number = " ..
                    tostring(old_container.unit_number) .. tostring(", tier = ") .. tostring(tier - 1))
            end
            proxies[receiver.unit_number] = game.surfaces[1].create_entity {
                name = names[tier].container,
                position = receiver.position,
                force = force
            }
            -- copy items from old container to new container
            local new_inventory = get_inventory(proxies[receiver.unit_number])
            local old_inventory = get_inventory(old_container)
            for name, count in pairs(old_inventory.get_contents()) do
                new_inventory.insert({ name = name, count = count })
            end
            old_container.destroy()
            return proxies[receiver.unit_number]
        end
    end

    -- ... otherwise create one.
    proxies[receiver.unit_number] = game.surfaces[1].create_entity {
        name = names[tier].container,
        position = receiver.position,
        force = force
    }
    if dbg.flags.print_create_container then
        dbg.print("create_container(): container.unit_number = " ..
            tostring(proxies[receiver.unit_number].unit_number))
    end
    return proxies[receiver.unit_number]
end

-- Create a lamp and associate it with `entity`.
local function create_lamp(entity, force, tier)
    proxies[entity.unit_number] = game.surfaces[1].create_entity {
        name = names[tier].lamp,
        position = entity.position,
        force = force
    }
    return proxies[entity.unit_number]
end

---------------------------------------------------------------------------
local function get_net_id(proxy)
    local net_id

    local circuit_network = proxy.get_circuit_network(wire)
    if circuit_network then
        net_id = circuit_network.network_id
    end

    if dbg.flags.print_net_id then
        dbg.print("get_net_id(): net_id = " .. tostring(net_id))
    end

    return net_id
end

-- Get what the receiver wants to receive.
local function get_rx_filter(container, tier)
    -- see if the combinator has a signal
    local combinator = game.surfaces[1].find_entity(names[tier].receiver, container.position)
    local signal = combinator.get_control_behavior().get_signal(slot_filter)
    if signal and signal.signal then
        return signal.signal.name
    else
        return nil
    end
end

-- Set what the receiver wants to receive.
local function set_rx_filter_from_container(container, elem_value, tier)
    -- the filter needs to be set for the combinator
    local combinator = game.surfaces[1].find_entity(names[tier].receiver, container.position)
    if combinator then
        local cb = combinator.get_control_behavior()
        if elem_value then
            cb.set_signal(slot_filter, { signal = { type = "item", name = elem_value }, count = 1 })
        else
            cb.set_signal(slot_filter, nil)
        end
    end

    if dbg.flags.print_set_rx_filter then
        dbg.print("set_rx_filter_from_container(): elem_value = " .. tostring(elem_value))
    end
end

local function set_rx_filter(combinator, elem_value)
    local cb = combinator.get_control_behavior()
    if elem_value then
        cb.set_signal(slot_filter, { signal = { type = "item", name = elem_value }, count = 1 })
    else
        cb.set_signal(slot_filter, nil)
    end

    if dbg.flags.print_set_rx_filter then
        dbg.print("set_rx_filter(): elem_value = " .. tostring(elem_value))
    end
end

-- All containers with the same network_id as `container` get the filter of
-- `container`.
local function set_rx_filter_in_same_network_as(container, tier)
    if dbg.flags.print_set_rx_filter then
        dbg.print("set_rx_filter_in_same_network_as(): rx[" .. tostring(tier) .. "].net_id =", true)
        dbg.block(rx[tier].net_id)
    end

    local net_id = get_net_id(container)

    if net_id and net_id > 0 then
        if rx[tier].net_id_and_un[net_id] then -- if there are other receivers in this network
            local filter = get_rx_filter(container, tier)
            for _, unit_number in ipairs(rx[tier].net_id_and_un[net_id]) do
                set_rx_filter(rx[tier].un[unit_number], filter)
            end
        end
    end
end

-- Store the circuit network id of all transmitters and receivers. Also, find
-- transmitters and receivers with the same circuit network id.
local function update_net_id(tier)
    local circuit_network
    local filter
    local net_id
    local new_net_id

    if dbg.flags.print_net_id then
        dbg.print("update_net_id(): rx[" .. tostring(tier) .. "].un =", true)
        for unit_number, _ in pairs(rx[tier].un) do
            dbg.print("\tun = " .. tostring(unit_number))
        end

        dbg.print("update_net_id(): tx[" .. tostring(tier) .. "].un =")
        for unit_number, _ in pairs(tx[tier].un) do
            dbg.print("\tun = " .. tostring(unit_number))
        end
    end

    -- If an entity has been built, some receivers might have gotten a new network_id and need their filters updated.
    if network_update_data[tier].built then
        local built_net_id = get_net_id(network_update_data[tier].proxy)
        -- Only if other receivers with network_id = `built_net_id` exist does it make sense to update a filter.
        if rx[tier].net_id_and_un[built_net_id] then
            -- Get the filter of one of the receivers with network_id = `built_net_id`.
            filter = get_rx_filter(get_proxy(rx[tier].net_id_and_un[built_net_id][1]), tier)
            -- Find all receivers which have a new network_id ...
            for un, n_id in pairs(rx[tier].net_id) do
                -- Compare a receiver's (potentially old) network_id with its (potentially new) network_id.
                if n_id ~= built_net_id then
                    new_net_id = get_net_id(get_proxy(un))
                    if built_net_id == new_net_id then
                        -- ... and update their filter if that is the case.
                        set_rx_filter(rx[tier].un[un], filter)
                    end
                end
            end
        end
    end

    active_nets[tier] = {}
    tx[tier].net_id_and_un = {}
    rx[tier].net_id_and_un = {}
    rx[tier].net_id_and_priority = {}

    -- store network_id of all transmitters
    for unit_number, entity in pairs(tx[tier].un) do
        circuit_network = get_proxy(entity).get_circuit_network(wire)
        if circuit_network then
            net_id = circuit_network.network_id

            tx[tier].net_id[unit_number] = net_id
            rendering.set_text(tx[tier].text_id[unit_number], "ID: " .. tostring(net_id))

            -- collect all transmitters with the same network_id
            tx[tier].net_id_and_un[net_id] = tx[tier].net_id_and_un[net_id] or {}
            table.insert(tx[tier].net_id_and_un[net_id], unit_number)
        end
    end

    -- store network_id of all receivers
    for unit_number, entity in pairs(rx[tier].un) do
        local proxy = get_proxy(entity)
        if proxy then
            circuit_network = proxy.get_circuit_network(wire)
            if circuit_network then
                net_id = circuit_network.network_id

                rx[tier].net_id[unit_number] = net_id
                rendering.set_text(rx[tier].text_id[unit_number], "ID: " .. tostring(net_id))

                -- collect all receivers with the same network_id
                rx[tier].net_id_and_un[net_id] = rx[tier].net_id_and_un[net_id] or {}
                table.insert(rx[tier].net_id_and_un[net_id], unit_number)

                -- reset the priority
                rx[tier].net_id_and_priority[net_id] = rx[tier].net_id_and_priority[net_id] or {}
                rx[tier].net_id_and_priority[net_id][unit_number] = 0

                -- find transmitters and receivers with the same network_id
                if tx[tier].net_id_and_un[net_id] then
                    active_nets[tier][net_id] = true
                end
            end
        end
    end

    if dbg.flags.print_net_id then
        dbg.print("update_net_id(): rx[" .. tostring(tier) .. "].net_id =")
        for unit_number, net_id in pairs(rx[tier].net_id) do
            dbg.print("\tun = " .. tostring(unit_number) .. " | net_id = " .. tostring(net_id))
        end

        dbg.print("update_net_id(): tx[" .. tostring(tier) .. "].net_id =")
        for unit_number, net_id in pairs(tx[tier].net_id) do
            dbg.print("\tun = " .. tostring(unit_number) .. " | net_id = " .. tostring(net_id))
        end

        dbg.print("update_net_id(): active_nets[" .. tostring(tier) .. "] =")
        local str = "\tnet_id = "
        for net_id, _ in pairs(active_nets[tier]) do
            str = str .. tostring(net_id) .. ", "
        end
        dbg.print(str)
    end
end

---------------------------------------------------------------------------
-- Connect a cable to suitable neighbors.
-- Note: A curved cable's direction is the direction of its front part.
local function cable_connect_to_neighbors(entity, tier)
    -- connect to neighboring cables
    for _, val in pairs(entity.belt_neighbours) do
        for _, neighbor in ipairs(val) do
            if neighbor.name == names[tier].cable then
                if entity.direction == neighbor.direction then
                    connect_proxies(entity, neighbor)
                elseif entity.direction ~= util.oppositedirection(neighbor.direction)
                    and equal_position(move_position(neighbor.position, neighbor.direction), entity.position)
                    and entity.belt_shape ~= "straight" then
                    -- entity is in front of neighbor

                    connect_proxies(entity, neighbor)
                elseif entity.direction ~= util.oppositedirection(neighbor.direction)
                    and equal_position(move_position(entity.position, entity.direction), neighbor.position)
                    and neighbor.belt_shape ~= "straight" then
                    -- neighbor is in front of entity and curved

                    connect_proxies(entity, neighbor)
                end
            elseif neighbor.name == names[tier].underground_cable then
                if entity.direction == neighbor.direction then
                    connect_proxies(entity, neighbor)
                end

                if entity.belt_shape ~= "straight" and entity.direction ~= util.oppositedirection(neighbor.direction) then
                    connect_proxies(entity, neighbor)
                end
            end
        end
    end

    -- connect to receiver north of cable
    local position = move_position(entity.position, entity.direction, 1)
    local receiver = game.surfaces[1].find_entity(names[tier].receiver, position)
    if receiver then
        connect_proxies(entity, receiver)
    end

    -- connect to transmitter south of cable
    position = move_position(entity.position, entity.direction, -1)
    local transmitter = game.surfaces[1].find_entity(names[tier].transmitter, position)
    if transmitter then
        connect_proxies(entity, transmitter)
    end

    -- connect to node north of cable
    position = move_position(entity.position, entity.direction, 1)
    local entity_node = game.surfaces[1].find_entity(names[tier].node, position)
    if entity_node then
        connect_proxies(entity, entity_node)
    end

    -- connect to node south of cable
    position = move_position(entity.position, entity.direction, -1)
    entity_node = game.surfaces[1].find_entity(names[tier].node, position)
    if entity_node and entity.belt_shape == "straight" then
        connect_proxies(entity, entity_node)
    end
end

---------------------------------------------------------------------------
-- Connect an underground cable to suitable neighbors.
local function underground_cable_connect_to_neighbors(entity, tier)
    -- connect to neighboring underground_cable
    if entity.neighbours then
        connect_proxies(entity, entity.neighbours)
    end

    -- connect to underground_cable north of underground_cable if it is facing in the same direction
    local position = move_position(entity.position, entity.direction, 1)
    local entity_cable = game.surfaces[1].find_entity(names[tier].underground_cable, position)
    if entity_cable then
        if entity_cable.direction == entity.direction then
            connect_proxies(entity, entity_cable)
        end
    end

    -- connect to underground_cable south of underground_cable if it is facing in the same direction
    position = move_position(entity.position, entity.direction, -1)
    entity_cable = game.surfaces[1].find_entity(names[tier].underground_cable, position)
    if entity_cable then
        if entity_cable.direction == entity.direction then
            connect_proxies(entity, entity_cable)
        end
    end

    -- connect to cable north of underground_cable if it is not facing towards
    -- the underground_cable
    position = move_position(entity.position, entity.direction, 1)
    entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
    if entity_cable then
        if entity_cable.direction ~= util.oppositedirection(entity.direction) then
            connect_proxies(entity, entity_cable)
        end
    end

    -- connect to cable south of underground_cable if it is facing in the
    -- same direction
    position = move_position(entity.position, entity.direction, -1)
    entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
    if entity_cable then
        if entity_cable.direction == entity.direction then
            connect_proxies(entity, entity_cable)
        end
    end

    -- connect to node north of underground_cable
    position = move_position(entity.position, entity.direction, 1)
    local entity_node = game.surfaces[1].find_entity(names[tier].node, position)
    if entity_node and entity.belt_to_ground_type == "output" then
        connect_proxies(entity, entity_node)
    end

    -- connect to node south of underground_cable
    position = move_position(entity.position, entity.direction, -1)
    entity_node = game.surfaces[1].find_entity(names[tier].node, position)
    if entity_node and entity.belt_to_ground_type == "input" then
        connect_proxies(entity, entity_node)
    end

    -- connect to receiver north of underground cable
    position = move_position(entity.position, entity.direction, 1)
    local receiver = game.surfaces[1].find_entity(names[tier].receiver, position)
    if receiver and entity.belt_to_ground_type == "output" then
        connect_proxies(entity, receiver)
    end

    -- connect to transmitter south of cable
    position = move_position(entity.position, entity.direction, -1)
    local transmitter = game.surfaces[1].find_entity(names[tier].transmitter, position)
    if transmitter and entity.belt_to_ground_type == "input" then
        connect_proxies(entity, transmitter)
    end
end

---------------------------------------------------------------------------
-- Create a choose-element-button next to the container gui.
local function create_gui(player, tier)
    local anchor = {
        gui = defines.relative_gui_type.container_gui,
        position = defines.relative_gui_position.right
    }
    local frame = player.gui.relative.add({
        type = "frame",
        name = names[tier].gui_frame,
        anchor = anchor,
        caption = { "transport-cables.button-caption" }
    })
    local button = frame.add({
        type = "choose-elem-button",
        name = names[tier].gui_filter,
        elem_type = "item",
        tooltip = { "transport-cables.button-tooltip" }
    })
    local filter = get_rx_filter(player.opened, tier)
    if filter then
        button.elem_value = filter
    end
    frame.add({
        type = "label",
        caption = tostring(mod_state[tier].rate) .. " / s"
    })
end

---------------------------------------------------------------------------
local function destroy_gui(player, tier)
    if not player then
        return
    end

    local frame = player.gui.relative[names[tier].gui_frame]

    if not frame then
        return
    end

    frame.destroy()
end

---------------------------------------------------------------------------
local function on_built_entity(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    local force = "player"
    if event.player_index then
        force = game.players[event.player_index].force
    elseif event.robot then
        force = event.robot.force
    end

    for tier = 1, n_tiers do
        if entity.name == names[tier].cable then
            local proxy = create_lamp(entity, force, tier)
            if not proxy then
                entity.destroy()
            end

            cable_connect_to_neighbors(entity, tier)

            local belt_neighbors = entity.belt_neighbours
            if belt_neighbors then
                cable_connection_update.belt_neighbors = belt_neighbors
                cable_connection_update.scheduled = true
                cable_connection_update.tier = tier
            end

            network_update_scheduled[tier] = true
            network_update_data[tier] = { proxy = proxy, built = true }
            return
        elseif entity.name == names[tier].node then
            local proxy = create_lamp(entity, force, tier)
            if not proxy then
                entity.destroy()
            end

            -- connect to neighboring cables (if they are facing towards or away from the node)
            -- and connect to neighboring nodes
            local position
            local direction
            local entity_neighbor
            for i = 0, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = move_position(entity.position, direction, 1)

                -- neighboring cable
                entity_neighbor = game.surfaces[1].find_entity(names[tier].cable, position)
                if entity_neighbor then
                    if entity_neighbor.direction == direction or entity_neighbor.direction == util.oppositedirection(direction) then
                        connect_proxies(entity, entity_neighbor)
                    end
                end

                -- neighboring node
                entity_neighbor = game.surfaces[1].find_entity(names[tier].node, position)
                if entity_neighbor then
                    connect_proxies(entity, entity_neighbor)
                end
            end

            -- connect to neighbors
            local neighbor
            for i = 0, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = move_position(entity.position, direction, 1)

                --  node
                neighbor = game.surfaces[1].find_entity(names[tier].node, position)
                if neighbor and ((neighbor.direction == direction) or (neighbor.direction == util.oppositedirection(direction))) then
                    connect_proxies(entity, neighbor)
                end

                -- receiver
                neighbor = game.surfaces[1].find_entity(names[tier].receiver, position)
                if neighbor then
                    connect_proxies(entity, neighbor)
                end

                -- transmitter
                neighbor = game.surfaces[1].find_entity(names[tier].transmitter, position)
                if neighbor then
                    connect_proxies(entity, neighbor)
                end
            end

            network_update_scheduled[tier] = true
            network_update_data[tier] = { proxy = proxy, built = true }
            return
        elseif entity.name == names[tier].receiver then
            local proxy = create_container(entity, force, tier)
            if not proxy then
                entity.destroy()
            end

            local position

            rx[tier].un[entity.unit_number] = entity

            -- default ID
            rx[tier].net_id[entity.unit_number] = -1

            -- display ID
            rx[tier].text_id[entity.unit_number] = rendering.draw_text {
                text = "ID: -1",
                surface = game.surfaces[1],
                target = entity,
                target_offset = { -0.75, 0 },
                color = {
                    r = 1,
                    g = 1,
                    b = 1,
                    a = 0.9
                },
                scale = 1.0
            }

            -- connect to neighbors
            local direction
            local neighbor
            for i = 0, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = move_position(entity.position, direction, 1)

                -- cable north, east, south, west of receiver if it is facing towards the receiver
                neighbor = game.surfaces[1].find_entity(names[tier].cable, position)
                if neighbor and neighbor.direction == util.oppositedirection(direction) then
                    connect_proxies(entity, neighbor)
                end

                -- node
                neighbor = game.surfaces[1].find_entity(names[tier].node, position)
                if neighbor then
                    connect_proxies(entity, neighbor)
                end

                -- underground cable north, east, south, west of receiver if it is facing towards the receiver and an output
                neighbor = game.surfaces[1].find_entity(names[tier].underground_cable, position)
                if neighbor and neighbor.belt_to_ground_type == "output" and neighbor.direction == util.oppositedirection(direction) then
                    connect_proxies(entity, neighbor)
                end
            end

            network_update_scheduled[tier] = true
            network_update_data[tier] = { proxy = proxy, built = true }
            return
        elseif entity.name == names[tier].transmitter then
            local proxy = create_lamp(entity, force, tier)
            if not proxy then
                entity.destroy()
            end

            tx[tier].un[entity.unit_number] = entity

            -- default ID
            tx[tier].net_id[entity.unit_number] = -1

            -- display ID
            tx[tier].text_id[entity.unit_number] = rendering.draw_text {
                text = "ID: -1",
                surface = game.surfaces[1],
                target = entity,
                target_offset = { -0.75, 0.25 },
                color = {
                    r = 1,
                    g = 1,
                    b = 1,
                    a = 0.9
                },
                scale = 1.0
            }

            -- connect to neighbors
            local position
            local direction
            local neighbor
            for i = 0, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = move_position(entity.position, direction, 1)

                -- cable north, east, south, west of transmitter if it is facing away from the transmitter
                neighbor = game.surfaces[1].find_entity(names[tier].cable, position)
                if neighbor and neighbor.direction == direction then
                    connect_proxies(entity, neighbor)
                end

                -- node
                neighbor = game.surfaces[1].find_entity(names[tier].node, position)
                if neighbor then
                    connect_proxies(entity, neighbor)
                end

                -- underground cable north, east, south, west of transmitter if it is facing away from the transmitter and an input
                neighbor = game.surfaces[1].find_entity(names[tier].underground_cable, position)
                if neighbor and neighbor.belt_to_ground_type == "input" and neighbor.direction == direction then
                    connect_proxies(entity, neighbor)
                end
            end

            network_update_scheduled[tier] = true
            network_update_data[tier] = { proxy = proxy, built = true }
            return
        elseif entity.name == names[tier].underground_cable then
            local proxy = create_lamp(entity, force, tier)
            if not proxy then
                entity.destroy()
            end

            underground_cable_connect_to_neighbors(entity, tier)

            network_update_scheduled[tier] = true
            network_update_data[tier] = { proxy = proxy, built = true }
            return
        end
    end
end

---------------------------------------------------------------------------
local on_built_filter = {}
for tier = 1, n_tiers do
    table.insert(on_built_filter, { filter = "name", name = names[tier].cable })
    table.insert(on_built_filter, { filter = "name", name = names[tier].node })
    table.insert(on_built_filter, { filter = "name", name = names[tier].transmitter })
    table.insert(on_built_filter, { filter = "name", name = names[tier].receiver })
    table.insert(on_built_filter, { filter = "name", name = names[tier].underground_cable })
end

---------------------------------------------------------------------------
local function on_console_command(command)
    if command.name == dbg.commands.combinator_selectale then
        dbg.flags.combinator_selectale = not dbg.flags.combinator_selectale
        dbg.print("combinator_selectale = " .. tostring(dbg.flags.combinator_selectale))
    elseif command.name == dbg.commands.print_off then
        dbg.flags.print_connect_proxies = false
        dbg.flags.print_gui = false
        dbg.flags.print_on_research_finished = false
        dbg.flags.print_set_rx_filter = false
        dbg.flags.print_net_id = false
        dbg.flags.print_update_receiver_filter = false
        dbg.print("set all print flags false")
    elseif command.name == dbg.commands.print_on then
        dbg.flags.print_connect_proxies = true
        dbg.flags.print_gui = true
        dbg.flags.print_on_research_finished = true
        dbg.flags.print_set_rx_filter = true
        dbg.flags.print_net_id = true
        dbg.flags.print_update_receiver_filter = true
        dbg.print("set all print flags true")
    elseif command.name == dbg.commands.print_connect_proxies then
        dbg.flags.print_connect_proxies = not dbg.flags.print_connect_proxies
        dbg.print("print_connect_proxies = " .. tostring(dbg.flags.print_connect_proxies))
    elseif command.name == dbg.commands.print_net_id then
        dbg.flags.print_net_id = not dbg.flags.print_net_id
        dbg.print("print_net_id = " .. tostring(dbg.flags.print_net_id))
    elseif command.name == dbg.commands.print_gui then
        dbg.flags.print_gui = not dbg.flags.print_gui
        dbg.print("print_gui = " .. tostring(dbg.flags.print_gui))
    elseif command.name == dbg.commands.print_on_research_finished then
        dbg.flags.print_on_research_finished = not dbg.flags.print_on_research_finished
        dbg.print("print_on_research_finished = " .. tostring(dbg.flags.print_on_research_finished))
    elseif command.name == dbg.commands.print_set_rx_filter then
        dbg.flags.print_set_rx_filter = not dbg.flags.print_set_rx_filter
        dbg.print("print_set_rx_filter = " .. tostring(dbg.flags.print_set_rx_filter))
    elseif command.name == dbg.commands.print_update_receiver_filter then
        dbg.flags.print_update_receiver_filter = not dbg.flags.print_update_receiver_filter
        dbg.print("print_update_receiver_filter = " .. tostring(dbg.flags.print_update_receiver_filter))
    elseif command.name == dbg.commands.research_all_technologies then
        game.players[command.player_index].force.research_all_technologies()
    elseif command.name == dbg.commands.set_rate then
        if command.parameter then
            local p_tier = tonumber(string.sub(command.parameter, 1, 1))
            local p_rate = tonumber(string.sub(command.parameter, 3, string.len(command.parameter)))
            dbg.print("set rate[" .. tostring(p_tier) .. "] = " .. tostring(p_rate))
            mod_state[p_tier].rate = p_rate
        end
    end
end

---------------------------------------------------------------------------
local function on_entity_settings_pasted(event)
    for tier = 1, n_tiers do
        if event.source.name == names[tier].receiver and event.destination.name == names[tier].receiver then
            set_rx_filter_from_container(event.destination, get_rx_filter(event.source, tier), tier)
            set_rx_filter_in_same_network_as(get_proxy(event.destination), tier)
            return
        end
    end
end

---------------------------------------------------------------------------
local function on_gui_closed(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if dbg.flags.print_gui then
        dbg.print("on_gui_closed(): entity.name = " .. tostring(entity.name))
    end

    for tier = 1, n_tiers do
        if event.entity.name == names[tier].container then
            set_rx_filter_in_same_network_as(event.entity, tier)
            destroy_gui(game.players[event.player_index], tier)
            return
        end
    end
end

---------------------------------------------------------------------------
local function on_gui_elem_changed(event)
    local element = event.element

    if not element then
        return
    end

    for tier = 1, n_tiers do
        if element.name == names[tier].gui_filter then
            if get_rx_filter(game.players[event.player_index].opened, tier) ~= event.element.elem_value then
                set_rx_filter_from_container(game.players[event.player_index].opened, event.element.elem_value, tier)
            end
            return
        end
    end
end

---------------------------------------------------------------------------
local function on_gui_opened(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if dbg.flags.print_gui then
        dbg.print("on_gui_opened(): entity.name = " .. tostring(entity.name))
    end

    for tier = 1, n_tiers do
        if entity.name == names[tier].receiver then
            if not dbg.flags.combinator_selectale then
                -- don't show the receiver GUI - switch to the container GUI
                game.players[event.player_index].opened = get_proxy(entity)
            end
            return
        elseif entity.name == names[tier].container then
            create_gui(game.players[event.player_index], tier)
            return
        end
    end
end

---------------------------------------------------------------------------
local function on_mined_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    for tier = 1, n_tiers do
        if entity.name == names[tier].cable then
            local proxy = get_proxy(entity)
            network_update_data[tier] = { proxy = proxy, mined = true }

            local belt_neighbors = entity.belt_neighbours
            if belt_neighbors then
                cable_connection_update.belt_neighbors = belt_neighbors
                cable_connection_update.scheduled = true
                cable_connection_update.tier = tier
            end

            destroy_proxy(entity, proxy)

            network_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].node then
            local proxy = get_proxy(entity)
            network_update_data[tier] = { proxy = proxy, mined = true }

            destroy_proxy(entity, proxy)

            network_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].receiver then
            local proxy = get_proxy(entity)
            network_update_data[tier] = { proxy = proxy, mined = true }
            if entity.to_be_upgraded() then
                -- Keep the container if the entity is to be upgraded but remove
                -- the reference to the container as it will be destroyed soon.
                proxies[entity.unit_number] = nil
            else
                destroy_proxy(entity, proxy)
            end

            rx[tier].un[entity.unit_number] = nil

            -- and the displayed text
            rendering.destroy(rx[tier].text_id[entity.unit_number])
            rx[tier].text_id[entity.unit_number] = nil

            -- and the ID
            rx[tier].net_id[entity.unit_number] = nil

            network_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].transmitter then
            local proxy = get_proxy(entity)
            network_update_data[tier] = { proxy = proxy, mined = true }

            destroy_proxy(entity, proxy)

            tx[tier].un[entity.unit_number] = nil

            -- also destroy the displayed text
            rendering.destroy(tx[tier].text_id[entity.unit_number])
            tx[tier].text_id[entity.unit_number] = nil

            -- and the ID
            tx[tier].net_id[entity.unit_number] = nil

            network_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].underground_cable then
            local proxy = get_proxy(entity)
            network_update_data[tier] = { proxy = proxy, mined = true }

            destroy_proxy(entity, proxy)

            network_update_scheduled[tier] = true
            return
        end
    end

    -- Note:
    -- After `entity` is destroyed, the circuit network is updated. At this
    -- point, we want to call update_net_id. That's why the update is only
    -- scheduled here.
end

---------------------------------------------------------------------------
local on_mined_filter = {}
for tier = 1, n_tiers do
    table.insert(on_mined_filter, { filter = "name", name = names[tier].cable })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].node })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].transmitter })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].receiver })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].underground_cable })
end

---------------------------------------------------------------------------
local function on_player_created(event)
    for tier = 1, n_tiers do
        network_update_scheduled[tier] = true
    end
end

---------------------------------------------------------------------------
-- Whenever a technology is researched, increment the item rate.
local function on_research_finished(event)
    local research = event.research

    if dbg.flags.print_on_research_finished then
        dbg.print("on_research_finished(): research.name = " .. research.name)
    end

    if research.name == prefix .. "t1"
        or research.name == prefix .. "t1-speed"
    then
        mod_state[1].rate = mod_state[1].rate + rate_increment
    end
    if research.name == prefix .. "t2"
        or research.name == prefix .. "t2-speed1"
        or research.name == prefix .. "t2-speed2"
    then
        mod_state[2].rate = mod_state[2].rate + rate_increment
    end
    if research.name == prefix .. "t3"
        or research.name == prefix .. "t3-speed1"
        or research.name == prefix .. "t3-speed2"
        or research.name == prefix .. "t3-speed3"
    then
        mod_state[3].rate = mod_state[3].rate + rate_increment
    end
    if research.name == prefix .. "t3-infinite-speed"
    then
        mod_state[3].rate = math.ceil(mod_state[3].rate * rate_increment_factor)
    end
end

---------------------------------------------------------------------------
local function on_rotated_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    for tier = 1, n_tiers do
        if entity.name == names[tier].cable then
            disconnect_proxies(entity)
            cable_connect_to_neighbors(entity, tier)

            network_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].underground_cable then
            disconnect_proxies(entity)
            underground_cable_connect_to_neighbors(entity, tier)

            -- also make the neighboring underground cable react
            if entity.neighbours then
                disconnect_proxies(entity.neighbours)
                underground_cable_connect_to_neighbors(entity.neighbours, tier)
            end

            network_update_scheduled[tier] = true
            return
        end
    end
end

---------------------------------------------------------------------------
local function keys_sorted_by_value(t)
    local keys = {}
    for key in pairs(t) do
        table.insert(keys, key)
    end

    table.sort(keys) -- ascending order

    return keys
end

---------------------------------------------------------------------------
local function on_tick(event)
    for tier = 1, n_tiers do
        if network_update_scheduled[tier] then
            network_update_scheduled[tier] = false
            update_net_id(tier)
        end
    end

    if cable_connection_update.scheduled then
        cable_connection_update.scheduled = false
        for _, val in pairs(cable_connection_update.belt_neighbors) do
            for _, neighbor in ipairs(val) do
                disconnect_proxies(neighbor)
                cable_connect_to_neighbors(neighbor, cable_connection_update.tier)
            end
        end
    end
end

---------------------------------------------------------------------------
local function get_inventory_rx(entity)
    return get_inventory(get_proxy(entity))
end

local function get_item_count(entity, item)
    return get_inventory(entity).get_item_count(item)
end

-- Iterate over the key-value-pairs of the table `t` such that the values
-- appear in descending order.
local function pairs_by_value(t)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, function(k1, k2)
        return t[k1] > t[k2]
    end)
    local i = 0
    local function iter()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            -- dbg.print(string.format("un = %4i, priority = %2.5f", a[i], t[a[i]]))
            return a[i], t[a[i]]
        end
    end
    return iter
end

local count                       -- counts items
local count_tx                    -- unit number -> number of items in a transmitter
local tx_un_array_sorted_by_count -- transmitter inventory keys
local n_count_tx                  -- total number of items in transmitters
local n_items_inserted            -- the number of items that has already been inserted into receivers
local n_items_insertable          -- the number of items that can be inserted into the given receiver's inventory
local n_items_per_tx              -- the average number of items to be moved per transmitter
local n_items_per_rx              -- the average number of items to be moved per receiver
local n_items_removable           -- the number of items that can be removed from the given transmitter's inventory
local n_items_to_move             -- the number of items that needs to be moved in this network
local n_items_to_remove           -- the number of items that need to be removed from transmitters
local n_tx                        -- the number of transmitters with the current network id
local n_rx                        -- the number of receivers with the current network id
local rx_priority_array           -- array of all receiver priorities with the current network id
local rx_un_array                 -- array of all receiver unit numbers with the current network id
local tx_un_array                 -- array of all transmitter unit numbers with the current network id
local rx_inventory                -- a receiver's inventory
local tx_inventory                -- a transmitter's inventory
local filter                      -- the kind of item that should be moved in the current network
local i
local item_dividend
local item_remainder
local n_insert
local n_remove
local function on_nth_tick(event)
    -- move items between transmitter-receiver-pairs
    for tier = 1, n_tiers do
        for net_id, _ in pairs(active_nets[tier]) do
            -- all transmitter unit numbers with this network_id
            tx_un_array = tx[tier].net_id_and_un[net_id]
            n_tx = #tx_un_array

            -- all receiver unit numbers with this network_id
            rx_un_array = rx[tier].net_id_and_un[net_id]
            n_rx = #rx_un_array

            -- all receiver priorities with this network_id
            rx_priority_array = rx[tier].net_id_and_priority[net_id]

            if rx_priority_array then
                -- the filter of all receivers with this network_id
                filter = get_rx_filter(get_proxy(rx_un_array[1]), tier)

                if filter then
                    -- Count the total number of items in all transmitters' inventories.
                    n_count_tx = 0
                    count_tx = {}
                    for _, un in ipairs(tx_un_array) do
                        count = get_item_count(tx[tier].un[un], filter)
                        count_tx[un] = count
                        n_count_tx = n_count_tx + count
                    end
                    -- Sort the transmitters ascendingly by their item count.
                    tx_un_array_sorted_by_count = keys_sorted_by_value(count_tx)

                    -- Try to move `rate` many items unless there are not enough items in all transmitters combined.
                    n_items_to_move = math.min(mod_state[tier].rate, n_count_tx)

                    if n_items_to_move > 0 then
                        -- On average, insert this many items into every receiver.
                        n_items_per_rx = n_items_to_move / n_rx

                        item_dividend = math.floor(n_items_per_rx)
                        item_remainder = n_items_to_move % n_rx
                        i = -1

                        n_items_inserted = 0
                        -- Try to give every receiver the necessary amount of items ...
                        for un, _ in pairs_by_value(rx_priority_array) do
                            i = i + 1
                            n_insert = item_dividend
                            if i < item_remainder then
                                n_insert = item_dividend + 1
                            end

                            rx_inventory = get_inventory_rx(rx[tier].un[un])
                            n_items_insertable = rx_inventory.get_insertable_count(filter)
                            if n_items_insertable >= n_insert then
                                -- ... if enough items can be inserted ...
                                if n_insert > 0 then
                                    rx_inventory.insert({ name = filter, count = n_insert })
                                    n_items_inserted = n_items_inserted + n_insert
                                end
                            else
                                -- ... and otherwise insert as many as possible.
                                if n_items_insertable > 0 then
                                    rx_inventory.insert({ name = filter, count = n_items_insertable })
                                    n_items_inserted = n_items_inserted + n_items_insertable
                                end
                            end
                            -- update the priority
                            rx_priority_array[un] = rx_priority_array[un] - n_insert + n_items_per_rx
                        end

                        -- On average, remove this many items from every transmitter.
                        n_items_per_tx = n_items_inserted / n_tx

                        item_dividend = math.floor(n_items_per_tx)
                        item_remainder = n_items_inserted % n_tx
                        i = -1

                        n_items_to_remove = n_items_inserted
                        -- Remove as many items as have been inserted from the transmitters ...
                        for _, un in ipairs(tx_un_array_sorted_by_count) do
                            i = i + 1
                            if i < item_remainder then
                                n_remove = item_dividend + 1
                            else
                                n_remove = item_dividend
                            end

                            tx_inventory = get_inventory(tx[tier].un[un])
                            n_items_removable = tx_inventory.get_item_count(filter)
                            if n_items_removable >= n_remove then
                                -- ... if enough items can be removed ...
                                if n_remove > 0 then
                                    tx_inventory.remove({ name = filter, count = n_remove })
                                    n_items_to_remove = n_items_to_remove - n_remove
                                end
                            else
                                -- ... and otherwise remove as many as possible.
                                if n_items_removable > 0 then
                                    tx_inventory.remove({ name = filter, count = n_items_removable })
                                    n_items_to_remove = n_items_to_remove - n_items_removable
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------------
local function initialize(global)
    active_nets = global.active_nets
    cable_connection_update = global.cable_connection_update
    mod_state = global.mod_state
    network_update_data = global.network_update_data
    network_update_scheduled = global.network_update_scheduled
    proxies = global.proxies
    rx = global.receiver
    tx = global.transmitter
end

---------------------------------------------------------------------------
return {
    initialize = initialize,
    on_built_entity = on_built_entity,
    on_built_filter = on_built_filter,
    on_console_command = on_console_command,
    on_entity_settings_pasted = on_entity_settings_pasted,
    on_gui_closed = on_gui_closed,
    on_gui_elem_changed = on_gui_elem_changed,
    on_gui_opened = on_gui_opened,
    on_mined_entity = on_mined_entity,
    on_mined_filter = on_mined_filter,
    on_nth_tick = on_nth_tick,
    on_player_created = on_player_created,
    on_research_finished = on_research_finished,
    on_rotated_entity = on_rotated_entity,
    on_tick = on_tick,
    prefix = prefix,
    n_tiers = n_tiers
}
