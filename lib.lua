local dbg = require("debuglib")
require("util")

---------------------------------------------------------------------------
-- globals
local active_nets = {}
local proxies = {} -- all proxies
local rx = {}      -- all receivers
local tx = {}      -- all transmitters
local rates = {}

---------------------------------------------------------------------------
local n_tiers = 3
local rate_increment = 15       -- whenever a research is finished, the item transport rate is increased by this amount
local rate_increment_factor = 2 -- whenever the infinite research is finished, multiply the item transport rate by this amount
local slot_bar = 2              -- the combinator's slot which stores the state of the inventory bar (TODO)
local slot_filter = 1           -- the combinator's slot which stores the filter
local wire = defines.wire_type.red
local wire_str = "red"

---------------------------------------------------------------------------
local prefix = "transport-cables:"

local tier_to_name = {
    cable = {},
    container = {},
    lamp = {},
    node = {},
    receiver = {},
    transmitter = {},
    underground_cable = {},
    gui_filter = {},
    gui_frame = {}
}
for tier = 1, n_tiers do
    tier_to_name.cable[tier] = prefix .. "cable-t" .. tostring(tier)
    tier_to_name.container[tier] = prefix .. "container-t" .. tostring(tier)
    tier_to_name.lamp[tier] = prefix .. "lamp-t" .. tostring(tier)
    tier_to_name.node[tier] = prefix .. "node-t" .. tostring(tier)
    tier_to_name.receiver[tier] = prefix .. "receiver-t" .. tostring(tier)
    tier_to_name.transmitter[tier] = prefix .. "transmitter-t" .. tostring(tier)
    tier_to_name.underground_cable[tier] = prefix .. "underground-cable-t" .. tostring(tier)
    tier_to_name.gui_filter[tier] = prefix .. "filter-t" .. tostring(tier)
    tier_to_name.gui_frame[tier] = prefix .. "frame-t" .. tostring(tier)
end

local name_to_tier = {
    cable = {},
    container = {},
    lamp = {},
    node = {},
    receiver = {},
    transmitter = {},
    underground_cable = {},
    gui_filter = {},
    gui_frame = {}
}
for tier = 1, n_tiers do
    name_to_tier.cable[prefix .. "cable-t" .. tostring(tier)] = tier
    name_to_tier.container[prefix .. "container-t" .. tostring(tier)] = tier
    name_to_tier.lamp[prefix .. "lamp-t" .. tostring(tier)] = tier
    name_to_tier.node[prefix .. "node-t" .. tostring(tier)] = tier
    name_to_tier.receiver[prefix .. "receiver-t" .. tostring(tier)] = tier
    name_to_tier.transmitter[prefix .. "transmitter-t" .. tostring(tier)] = tier
    name_to_tier.underground_cable[prefix .. "underground-cable-t" .. tostring(tier)] = tier
    name_to_tier.gui_filter[prefix .. "filter-t" .. tostring(tier)] = tier
    name_to_tier.gui_frame[prefix .. "frame-t" .. tostring(tier)] = tier
end

---------------------------------------------------------------------------
local network_update_data      -- data collected when the update is triggered
local network_update_scheduled -- is an update of the network ids necessary?

-- When a cable which is connected to another cable (a neighbor) is destroyed, the neighbor might get new neighbors
-- (for example, the neighbor might have been curved and is now straight). But this happens only after the cable
-- has been destroyed. So an update needs to be scheduled on_mined_entity but it cannot be made directly.
-- A similar case can occur when a cable is built and its neighbor turns from curved to straight.
local cable_connection_update_data
local cable_connection_update_scheduled

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

-- Are the two positions vectors `position1` and `position2` equal?
local function equal_position(position1, position2)
    return position1.x == position2.x and position1.y == position2.y
end

---------------------------------------------------------------------------
local function get_inventory(entity)
    if not entity or not entity.valid then
        return
    else
        return entity.get_inventory(defines.inventory.item_main)
    end
end

---------------------------------------------------------------------------
-- Append table `tt` to table `t`.
local function append(t, tt)
    if tt then
        t = t or {}
        for k, v in pairs(tt) do
            t[k] = v
        end
    end
    return t
end

---------------------------------------------------------------------------
-- Get the circuit network_id of `proxy`.
local function get_net_id(proxy)
    if not proxy or not proxy.valid then
        return
    end

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
local function connect_proxies(t)
    local source_entity = t[1] or t.source
    local target_entity = t[2] or t.target
    local source_is_rx = t.source_is_rx or false
    local source_is_tx = t.source_is_tx or false

    if not source_entity or (not source_entity.valid or (not target_entity or not target_entity.valid)) then
        return
    end

    if source_entity.type ~= "entity-ghost" and target_entity.type ~= "entity-ghost" then
        local t_net_requires_update

        local source_proxy = get_proxy(source_entity)
        local target_proxy = get_proxy(target_entity)

        local source_net_id_pre = get_net_id(source_proxy)
        local target_net_id_pre = get_net_id(target_proxy)

        if source_proxy and (source_proxy.valid and (target_proxy and target_proxy.valid)) then
            source_proxy.connect_neighbour {
                wire = wire,
                target_entity = target_proxy
            }
        end

        local source_net_id_post = get_net_id(source_proxy)
        local target_net_id_post = get_net_id(target_proxy)

        if source_is_rx then
            -- A receiver was not yet part of a network but is now.
            if not source_net_id_pre and source_net_id_post then
                -- update the displayed text
                rx.net_id[source_entity.unit_number] = source_net_id_post
                rendering.set_text(rx.text_id[source_entity.unit_number], "ID: " .. tostring(source_net_id_post))

                -- collect all receivers with the same network_id
                rx.net_id_and_un[source_net_id_post] = rx.net_id_and_un[source_net_id_post] or {}
                rx.net_id_and_un[source_net_id_post][source_entity.unit_number] = true

                -- number of receivers in network changed: reset priority
                rx.net_id_and_priority[source_net_id_post] = rx.net_id_and_priority[source_net_id_post] or {}
                for un, _ in pairs(rx.net_id_and_priority[source_net_id_post]) do
                    rx.net_id_and_priority[source_net_id_post][un] = 0
                end
                rx.net_id_and_priority[source_net_id_post][source_entity.unit_number] = 0
            end
        end

        if source_is_tx then
            -- A transmitter was not yet part of a network but is now.
            if not source_net_id_pre and source_net_id_post then
                -- update the displayed text
                tx.net_id[source_entity.unit_number] = source_net_id_post
                rendering.set_text(tx.text_id[source_entity.unit_number], "ID: " .. tostring(source_net_id_post))

                -- collect all transmitters with the same network_id
                tx.net_id_and_un[source_net_id_post] = tx.net_id_and_un[source_net_id_post] or {}
                tx.net_id_and_un[source_net_id_post][source_entity.unit_number] = true
            end
        end

        -- two previously not connected networks are now connected
        if source_net_id_pre and source_net_id_pre ~= source_net_id_post then     -- `source_entity` already had a network_id and got a new one
            t_net_requires_update = t_net_requires_update or {}
            t_net_requires_update[source_net_id_pre] = true                       -- all rx/tx entities with `source_entity`'s previous network_id got/need an update
        elseif target_net_id_pre and target_net_id_pre ~= target_net_id_post then -- `target_entity` already had a network_id and got a new one
            t_net_requires_update = t_net_requires_update or {}
            t_net_requires_update[target_net_id_pre] = true                       -- all rx/tx entities with `target_entity`'s previous network_id got/need an update
        end

        if dbg.flags.print_connect_proxies then
            dbg.print("connect_proxies(): " .. source_entity.name .. " < == > " .. target_entity.name)
            if source_net_id_pre and (t_net_requires_update and t_net_requires_update[source_net_id_pre]) then
                dbg.print("connect_proxies(): net_id = " ..
                    tostring(source_net_id_pre) .. " was updated to net_id = " .. tostring(source_net_id_post))
            end
            if target_net_id_pre and (t_net_requires_update and t_net_requires_update[target_net_id_pre]) then
                dbg.print("connect_proxies(): net_id = " ..
                    tostring(target_net_id_pre) .. " was updated to net_id = " .. tostring(target_net_id_post))
            end
        end

        return t_net_requires_update
    end
end

-- Disconnect the circuit connections associated with `entity`'s proxy.
local function disconnect_proxy(entity)
    if not entity or not entity.valid then
        return
    end

    local t_net_requires_update
    local proxy = get_proxy(entity)
    if proxy then
        -- Remember the neighbors' network IDs before disconnecting from them.
        local net_id
        local circuit_connected_entities = proxy.circuit_connected_entities
        if circuit_connected_entities and circuit_connected_entities[wire_str] then
            for _, proxy in pairs(circuit_connected_entities[wire_str]) do
                net_id = get_net_id(proxy)
                if net_id then
                    t_net_requires_update = t_net_requires_update or {}
                    t_net_requires_update[net_id] = true
                end
            end
        end

        proxy.disconnect_neighbour(wire)
    end

    if dbg.flags.print_connect_proxies then
        dbg.print("disconnect_proxy(): " .. entity.name)
    end

    return t_net_requires_update
end

-- Destroy the proxy associated with `entity`.
local function destroy_proxy(entity, proxy)
    if not entity or not entity.valid then
        return
    end

    if not proxy or not proxy.valid then
        return
    end

    local t_net_requires_update = disconnect_proxy(proxy)

    local destroyed = proxy.destroy()
    proxies[entity.unit_number] = nil
    return t_net_requires_update, destroyed
end

---------------------------------------------------------------------------
-- Create a container and associate it with `entity`.
local function create_container(receiver, force, tier)
    -- If there already is a container, do not create a new one.
    local found = game.surfaces[1].find_entity(tier_to_name.container[tier], receiver.position)
    if found then
        if dbg.flags.print_create_container then
            dbg.print("create_container(): found.unit_number = " ..
                tostring(found.unit_number) .. tostring(", tier = ") .. tostring(tier))
        end
        proxies[receiver.unit_number] = found
        return found
    end

    -- If an upgrade happened, there is a container of a previous tier ...
    if tier > 1 then
        local old_container
        for previous_tier = 1, tier - 1 do
            old_container = game.surfaces[1].find_entity(tier_to_name.container[previous_tier], receiver.position)
            if old_container then
                if dbg.flags.print_create_container then
                    dbg.print("create_container(): old_container.unit_number = " ..
                        tostring(old_container.unit_number) .. tostring(", tier = ") .. tostring(tier - 1))
                end
                proxies[receiver.unit_number] = game.surfaces[1].create_entity {
                    name = tier_to_name.container[tier],
                    position = receiver.position,
                    force = force
                }
                -- copy items from old container to new container
                local new_inventory = get_inventory(proxies[receiver.unit_number])
                local old_inventory = get_inventory(old_container)
                if old_inventory and new_inventory then
                    for name, count in pairs(old_inventory.get_contents()) do
                        new_inventory.insert({ name = name, count = count })
                    end
                end
                old_container.destroy()
                return proxies[receiver.unit_number]
            end
        end
    end

    -- ... otherwise create one.
    proxies[receiver.unit_number] = game.surfaces[1].create_entity {
        name = tier_to_name.container[tier],
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
        name = tier_to_name.lamp[tier],
        position = entity.position,
        force = force
    }
    return proxies[entity.unit_number]
end

---------------------------------------------------------------------------
-- Get what the receiver wants to receive.
local function get_rx_filter(container, tier)
    if not container or not container.valid then
        return
    end

    -- see if the combinator has a signal
    local combinator = game.surfaces[1].find_entity(tier_to_name.receiver[tier], container.position)
    local signal = combinator.get_control_behavior().get_signal(slot_filter)
    if signal and signal.signal then
        return signal.signal.name
    else
        return nil
    end
end

-- Set what the receiver wants to receive.
local function set_rx_filter_from_container(container, elem_value, tier)
    if not container or not container.valid then
        return
    end

    -- the filter needs to be set for the combinator
    local combinator = game.surfaces[1].find_entity(tier_to_name.receiver[tier], container.position)
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
    if not combinator or not combinator.valid then
        return
    end

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
    if not container or not container.valid then
        return
    end

    if dbg.flags.print_set_rx_filter then
        dbg.print("set_rx_filter_in_same_network_as(): rx.net_id =", true)
        dbg.block(rx.net_id)
    end

    local net_id = get_net_id(container)

    if net_id and net_id > 0 then
        if rx.net_id_and_un[net_id] then -- if there are other receivers in this network
            local filter = get_rx_filter(container, tier)
            -- for _, unit_number in ipairs(rx.net_id_and_un[net_id]) do
            for unit_number, _ in ipairs(rx.net_id_and_un[net_id]) do
                set_rx_filter(rx.un[unit_number], filter)
            end
        end
    end
end

-- Store the circuit network id of all transmitters and receivers. Also, find
-- transmitters and receivers with the same circuit network id.
local function update_net_id(event)
    local circuit_network
    local net_id

    if dbg.flags.print_net_id then
        dbg.print("update_net_id(): rx.un =", true)
        for unit_number, _ in pairs(rx.un) do
            dbg.print("\tun = " .. tostring(unit_number))
        end

        dbg.print("update_net_id(): tx.un =")
        for unit_number, _ in pairs(tx.un) do
            dbg.print("\tun = " .. tostring(unit_number))
        end
    end

    -- Two existing networks have been connected.
    local new_net_ids = {}
    if event.t_net_requires_update then
        for net_id_old, _ in pairs(event.t_net_requires_update) do
            rx.net_id_and_un[net_id_old] = rx.net_id_and_un[net_id_old] or {}
            -- At this point, the old network no longer exists.
            -- All its entities are in the new network, so we need to update our variables:
            for un, _ in pairs(rx.net_id_and_un[net_id_old]) do
                net_id = get_net_id(get_proxy(un))
                if net_id then
                    rx.net_id_and_un[net_id] = rx.net_id_and_un[net_id] or {}
                    rx.net_id_and_un[net_id][un] = true

                    new_net_ids[net_id] = true

                    -- update the displayed text
                    rx.net_id[un] = net_id
                    rendering.set_text(rx.text_id[un], "ID: " .. tostring(net_id))
                else
                    if rx.net_id[un] then
                        -- update the displayed text
                        rx.net_id[un] = -1
                        rendering.set_text(rx.text_id[un], "ID: -1")
                    end
                end
            end

            tx.net_id_and_un[net_id_old] = tx.net_id_and_un[net_id_old] or {}
            for un, _ in pairs(tx.net_id_and_un[net_id_old]) do
                net_id = get_net_id(get_proxy(un))
                if net_id then
                    tx.net_id_and_un[net_id] = tx.net_id_and_un[net_id] or {}
                    tx.net_id_and_un[net_id][un] = true

                    tx.net_id_and_un[net_id_old][un] = nil

                    -- update the displayed text
                    tx.net_id[un] = net_id
                    rendering.set_text(tx.text_id[un], "ID: " .. tostring(net_id))
                else
                    if tx.net_id[un] then
                        -- update the displayed text
                        tx.net_id[un] = -1
                        rendering.set_text(tx.text_id[un], "ID: -1")
                    end
                end
            end
            -- Since the old network no longer exists:
            rx.net_id_and_un[net_id_old] = nil
            rx.net_id_and_priority[net_id_old] = nil
            tx.net_id_and_un[net_id_old] = nil

            -- All networks which are affected by the receiver network change
            -- might have more receivers: Reset the priorities.
            for n_id, _ in pairs(new_net_ids) do
                rx.net_id_and_priority[n_id] = rx.net_id_and_priority[n_id] or {}
                for un, _ in pairs(rx.net_id_and_priority[n_id]) do
                    rx.net_id_and_priority[n_id][un] = 0
                end
            end
        end
    end

    -- find transmitters and receivers with the same network_id
    active_nets[event.tier] = {}
    for _, entity in pairs(rx.un) do
        local proxy = get_proxy(entity)
        if proxy then
            circuit_network = proxy.get_circuit_network(wire)
            if circuit_network then
                net_id = circuit_network.network_id

                if tx.net_id_and_un[net_id] then
                    active_nets[event.tier][net_id] = true
                end
            end
        end
    end

    if dbg.flags.print_net_id then
        dbg.print("update_net_id(): rx.net_id =")
        for unit_number, net_id in pairs(rx.net_id) do
            dbg.print("\tun = " .. tostring(unit_number) .. " | net_id = " .. tostring(net_id))
        end

        dbg.print("update_net_id(): tx.net_id =")
        for unit_number, net_id in pairs(tx.net_id) do
            dbg.print("\tun = " .. tostring(unit_number) .. " | net_id = " .. tostring(net_id))
        end

        dbg.print("update_net_id(): active_nets[" .. tostring(event.tier) .. "] =")
        local str = "\tnet_id = "
        for net_id, _ in pairs(active_nets[event.tier]) do
            str = str .. tostring(net_id) .. ", "
        end
        dbg.print(str)
    end
end

---------------------------------------------------------------------------
-- Connect a cable to suitable neighbors.
-- Note: A curved cable's direction is the direction of its front part.
local function cable_connect_to_neighbors(entity, tier)
    if not entity or not entity.valid then
        return
    end

    local t_net_requires_update

    -- connect to neighboring cables
    for _, val in pairs(entity.belt_neighbours) do
        for _, neighbor in ipairs(val) do
            if neighbor and neighbor.valid then
                if neighbor.name == tier_to_name.cable[tier] then
                    if entity.direction == neighbor.direction then
                        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
                    elseif entity.direction ~= util.oppositedirection(neighbor.direction)
                        and equal_position(move_position(neighbor.position, neighbor.direction), entity.position) -- entity is in front of neighbor
                        and entity.belt_shape ~= "straight" then                                                  -- and curved
                        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
                    elseif entity.direction ~= util.oppositedirection(neighbor.direction)
                        and equal_position(move_position(entity.position, entity.direction), neighbor.position) -- neighbor is in front of entity
                        and neighbor.belt_shape ~= "straight" then                                              -- and curved
                        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
                    end
                elseif neighbor.name == tier_to_name.underground_cable[tier] then
                    if entity.direction == neighbor.direction then
                        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
                    end

                    if entity.belt_shape ~= "straight" and entity.direction ~= util.oppositedirection(neighbor.direction) then
                        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
                    end
                end
            end
        end
    end

    -- connect to receiver north of cable
    local position = move_position(entity.position, entity.direction, 1)
    local neighbor = game.surfaces[1].find_entity(tier_to_name.receiver[tier], position)
    if neighbor then
        t_net_requires_update = append(t_net_requires_update,
            connect_proxies { source = neighbor, target = entity, source_is_rx = true })
    end

    -- connect to node north of cable
    position = move_position(entity.position, entity.direction, 1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.node[tier], position)
    if neighbor then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
    end

    if entity.belt_shape == "straight" then
        -- connect to transmitter south of cable
        position = move_position(entity.position, entity.direction, -1)
        neighbor = game.surfaces[1].find_entity(tier_to_name.transmitter[tier], position)
        if neighbor then
            t_net_requires_update = append(t_net_requires_update,
                connect_proxies { source = neighbor, target = entity, source_is_tx = true })
        end

        -- connect to node south of cable
        position = move_position(entity.position, entity.direction, -1)
        neighbor = game.surfaces[1].find_entity(tier_to_name.node[tier], position)
        if neighbor and entity.belt_shape == "straight" then
            t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
        end
    end

    return t_net_requires_update
end

-- Connect an underground cable to suitable neighbors.
local function underground_cable_connect_to_neighbors(entity, tier)
    if not entity or not entity.valid then
        return
    end

    local t_net_requires_update

    -- connect to neighboring underground_cable
    if entity.neighbours then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, entity.neighbor })
    end

    -- connect to underground_cable north of underground_cable if it is facing in the same direction
    local position = move_position(entity.position, entity.direction, 1)
    local neighbor = game.surfaces[1].find_entity(tier_to_name.underground_cable[tier], position)
    if neighbor and neighbor.direction == entity.direction then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
    end

    -- connect to underground_cable south of underground_cable if it is facing in the same direction
    position = move_position(entity.position, entity.direction, -1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.underground_cable[tier], position)
    if neighbor and neighbor.direction == entity.direction then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
    end

    -- connect to cable north of underground_cable if it is not facing towards
    -- the underground_cable
    position = move_position(entity.position, entity.direction, 1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.cable[tier], position)
    if neighbor and neighbor.direction ~= util.oppositedirection(entity.direction) and entity.belt_to_ground_type == "output" then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
    end

    -- connect to cable south of underground_cable if it is facing in the
    -- same direction
    position = move_position(entity.position, entity.direction, -1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.cable[tier], position)
    if neighbor and neighbor.direction == entity.direction then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
    end

    -- connect to node north of underground_cable
    position = move_position(entity.position, entity.direction, 1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.node[tier], position)
    if neighbor and entity.belt_to_ground_type == "output" then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
    end

    -- connect to node south of underground_cable
    position = move_position(entity.position, entity.direction, -1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.node[tier], position)
    if neighbor and entity.belt_to_ground_type == "input" then
        t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
    end

    -- connect to receiver north of underground cable
    position = move_position(entity.position, entity.direction, 1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.receiver[tier], position)
    if neighbor and entity.belt_to_ground_type == "output" then
        t_net_requires_update = append(t_net_requires_update,
            connect_proxies { source = neighbor, target = entity, source_is_rx = true })
    end

    -- connect to transmitter south of cable
    position = move_position(entity.position, entity.direction, -1)
    neighbor = game.surfaces[1].find_entity(tier_to_name.transmitter[tier], position)
    if neighbor and entity.belt_to_ground_type == "input" then
        t_net_requires_update = append(t_net_requires_update,
            connect_proxies { source = neighbor, target = entity, source_is_tx = true })
    end

    return t_net_requires_update
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
        name = tier_to_name.gui_frame[tier],
        anchor = anchor,
        caption = { "transport-cables.button-caption" }
    })
    local button = frame.add({
        type = "choose-elem-button",
        name = tier_to_name.gui_filter[tier],
        elem_type = "item",
        tooltip = { "transport-cables.button-tooltip" }
    })
    local filter = get_rx_filter(player.opened, tier)
    if filter then
        button.elem_value = filter
    end
    frame.add({
        type = "label",
        caption = tostring(rates[tier]) .. " / s"
    })
end

---------------------------------------------------------------------------
local function destroy_gui(player, tier)
    if not player then
        return
    end

    local frame = player.gui.relative[tier_to_name.gui_frame[tier]]

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

    if name_to_tier.cable[entity.name] then
        local tier = name_to_tier.cable[entity.name]

        local proxy = create_lamp(entity, force, tier)
        if not proxy then
            entity.destroy()
        end

        -- A connection to the non-proxy entity can happen with a fast replace
        entity.disconnect_neighbour(wire) -- but we don't want that.

        local t_net_requires_update = cable_connect_to_neighbors(entity, tier)

        local belt_neighbors = entity.belt_neighbours
        if belt_neighbors then
            cable_connection_update_scheduled = true
            table.insert(cable_connection_update_data, { belt_neighbors = belt_neighbors, tier = tier })
        end

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
        return
    elseif name_to_tier.node[entity.name] then
        local tier = name_to_tier.node[entity.name]

        local proxy = create_lamp(entity, force, tier)
        if not proxy then
            entity.destroy()
        end

        -- A connection to the non-proxy entity can happen with a fast replace
        entity.disconnect_neighbour(wire) -- but we don't want that.

        local t_net_requires_update

        -- connect to neighbors
        local position
        local direction
        local neighbor
        for i = 0, 6, 2 do
            -- rotate direction by i / 2 * 90°
            direction = (entity.direction + i) % 8
            position = move_position(entity.position, direction, 1)

            -- cable (if it is straight and facing towards or away from the node)
            neighbor = game.surfaces[1].find_entity(tier_to_name.cable[tier], position)
            if neighbor and (neighbor.belt_shape == "straight" and (neighbor.direction == direction or neighbor.direction == util.oppositedirection(direction))) then
                t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
            end

            -- node
            neighbor = game.surfaces[1].find_entity(tier_to_name.node[tier], position)
            if neighbor then
                t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
            end

            -- receiver
            neighbor = game.surfaces[1].find_entity(tier_to_name.receiver[tier], position)
            if neighbor then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = neighbor, target = entity, source_is_rx = true })
            end

            -- transmitter
            neighbor = game.surfaces[1].find_entity(tier_to_name.transmitter[tier], position)
            if neighbor then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = neighbor, target = entity, source_is_tx = true })
            end

            -- underground_cable (input)
            neighbor = game.surfaces[1].find_entity(tier_to_name.underground_cable[tier], position)
            if neighbor and (neighbor.belt_to_ground_type == "input" and neighbor.direction == direction) then
                t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
            end

            -- underground_cable (output)
            if neighbor and (neighbor.belt_to_ground_type == "output" and neighbor.direction == util.oppositedirection(direction)) then
                t_net_requires_update = append(t_net_requires_update, connect_proxies { entity, neighbor })
            end
        end

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
        return
    elseif name_to_tier.receiver[entity.name] then
        local tier = name_to_tier.receiver[entity.name]

        local proxy = create_container(entity, force, tier)
        if not proxy then
            entity.destroy()
        end

        -- A connection to the non-proxy entity can happen with a fast replace
        entity.disconnect_neighbour(wire) -- but we don't want that.

        local position

        rx.un[entity.unit_number] = entity

        -- default ID
        rx.net_id[entity.unit_number] = -1

        -- display ID
        rx.text_id[entity.unit_number] = rendering.draw_text {
            text = "ID: -1",
            surface = game.surfaces[1],
            target = entity,
            target_offset = { -0.6, 0 },
            color = {
                r = 1,
                g = 1,
                b = 1,
                a = 0.9
            },
            scale = 0.8
        }

        local t_net_requires_update

        -- connect to neighbors
        local direction
        local neighbor
        for i = 0, 6, 2 do
            -- rotate direction by i / 2 * 90°
            direction = (entity.direction + i) % 8
            position = move_position(entity.position, direction, 1)

            -- cable north, east, south, west of receiver if it is facing towards the receiver
            neighbor = game.surfaces[1].find_entity(tier_to_name.cable[tier], position)
            if neighbor and neighbor.direction == util.oppositedirection(direction) then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = entity, target = neighbor, source_is_rx = true })
            end

            -- node
            neighbor = game.surfaces[1].find_entity(tier_to_name.node[tier], position)
            if neighbor then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = entity, target = neighbor, source_is_rx = true })
            end

            -- underground cable north, east, south, west of receiver if it is facing towards the receiver and an output
            neighbor = game.surfaces[1].find_entity(tier_to_name.underground_cable[tier], position)
            if neighbor and (neighbor.belt_to_ground_type == "output" and neighbor.direction == util.oppositedirection(direction)) then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = entity, target = neighbor, source_is_rx = true })
            end
        end

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
        return
    elseif name_to_tier.transmitter[entity.name] then
        local tier = name_to_tier.transmitter[entity.name]

        local proxy = create_lamp(entity, force, tier)
        if not proxy then
            entity.destroy()
        end

        -- A connection to the non-proxy entity can happen with a fast replace
        entity.disconnect_neighbour(wire) -- but we don't want that.

        tx.un[entity.unit_number] = entity

        -- default ID
        tx.net_id[entity.unit_number] = -1

        -- display ID
        tx.text_id[entity.unit_number] = rendering.draw_text {
            text = "ID: -1",
            surface = game.surfaces[1],
            target = entity,
            target_offset = { -0.6, 0 },
            color = {
                r = 1,
                g = 1,
                b = 1,
                a = 0.9
            },
            scale = 0.8
        }

        local t_net_requires_update

        -- connect to neighbors
        local position
        local direction
        local neighbor
        for i = 0, 6, 2 do
            -- rotate direction by i / 2 * 90°
            direction = (entity.direction + i) % 8
            position = move_position(entity.position, direction, 1)

            -- cable north, east, south, west of transmitter if it is facing away from the transmitter
            neighbor = game.surfaces[1].find_entity(tier_to_name.cable[tier], position)
            if neighbor and neighbor.direction == direction then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = entity, target = neighbor, source_is_tx = true })
            end

            -- node
            neighbor = game.surfaces[1].find_entity(tier_to_name.node[tier], position)
            if neighbor then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = entity, target = neighbor, source_is_tx = true })
            end

            -- underground cable north, east, south, west of transmitter if it is facing away from the transmitter and an input
            neighbor = game.surfaces[1].find_entity(tier_to_name.underground_cable[tier], position)
            if neighbor and (neighbor.belt_to_ground_type == "input" and neighbor.direction == direction) then
                t_net_requires_update = append(t_net_requires_update,
                    connect_proxies { source = entity, target = neighbor, source_is_tx = true })
            end
        end

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
        return
    elseif name_to_tier.underground_cable[entity.name] then
        local tier = name_to_tier.underground_cable[entity.name]

        local proxy = create_lamp(entity, force, tier)
        if not proxy then
            entity.destroy()
        end

        -- A connection to the non-proxy entity can happen with a fast replace
        entity.disconnect_neighbour(wire) -- but we don't want that.

        local t_net_requires_update = underground_cable_connect_to_neighbors(entity, tier)

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
        return
    end
end

---------------------------------------------------------------------------
local on_built_filter = {}
for tier = 1, n_tiers do
    table.insert(on_built_filter, { filter = "name", name = tier_to_name.cable[tier] })
    table.insert(on_built_filter, { filter = "name", name = tier_to_name.node[tier] })
    table.insert(on_built_filter, { filter = "name", name = tier_to_name.transmitter[tier] })
    table.insert(on_built_filter, { filter = "name", name = tier_to_name.receiver[tier] })
    table.insert(on_built_filter, { filter = "name", name = tier_to_name.underground_cable[tier] })
end

---------------------------------------------------------------------------
local function on_console_command(command)
    if command.name == dbg.commands.combinator_selectale then
        dbg.flags.combinator_selectale = not dbg.flags.combinator_selectale
        dbg.print("combinator_selectale = " .. tostring(dbg.flags.combinator_selectale))
    elseif command.name == dbg.commands.print_off then
        dbg.flags.print_connect_proxies = false
        dbg.flags.print_create_container = false
        dbg.flags.print_gui = false
        dbg.flags.print_on_research_finished = false
        dbg.flags.print_set_rx_filter = false
        dbg.flags.print_net_id = false
        dbg.flags.print_update_receiver_filter = false
        dbg.print("set all print flags false")
    elseif command.name == dbg.commands.print_on then
        dbg.flags.print_connect_proxies = true
        dbg.flags.print_create_container = true
        dbg.flags.print_gui = true
        dbg.flags.print_on_research_finished = true
        dbg.flags.print_set_rx_filter = true
        dbg.flags.print_net_id = true
        dbg.flags.print_update_receiver_filter = true
        dbg.print("set all print flags true")
    elseif command.name == dbg.commands.print_connect_proxies then
        dbg.flags.print_connect_proxies = not dbg.flags.print_connect_proxies
        dbg.print("print_connect_proxies = " .. tostring(dbg.flags.print_connect_proxies))
    elseif command.name == dbg.commands.print_create_container then
        dbg.flags.print_create_container = not dbg.flags.print_create_container
        dbg.print("print_create_container = " .. tostring(dbg.flags.print_create_container))
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
            if p_tier then
                rates[p_tier] = p_rate
            end
        end
    end
end

---------------------------------------------------------------------------
local function on_entity_settings_pasted(event)
    if name_to_tier.receiver[event.source.name]
        and name_to_tier.receiver[event.destination.name]
        and name_to_tier.receiver[event.source.name] == name_to_tier.receiver[event.destination.name] then
        local tier = name_to_tier.receiver[event.source.name]
        set_rx_filter_from_container(event.destination, get_rx_filter(event.source, tier), tier)
        set_rx_filter_in_same_network_as(get_proxy(event.destination), tier)
        return
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

    if name_to_tier.container[entity.name] then
        local tier = name_to_tier.container[entity.name]
        set_rx_filter_in_same_network_as(entity, tier)
        destroy_gui(game.players[event.player_index], tier)
        return
    end
end

---------------------------------------------------------------------------
local function on_gui_elem_changed(event)
    local element = event.element

    if not element then
        return
    end

    if name_to_tier.gui_filter[element.name] then
        local tier = name_to_tier.gui_filter[element.name]
        if get_rx_filter(game.players[event.player_index].opened, tier) ~= event.element.elem_value then
            set_rx_filter_from_container(game.players[event.player_index].opened, event.element.elem_value, tier)
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

    if name_to_tier.receiver[entity.name] then
        if not dbg.flags.combinator_selectale then
            -- don't show the receiver GUI - switch to the container GUI
            game.players[event.player_index].opened = get_proxy(entity)
        end
    elseif name_to_tier.container[entity.name] then
        create_gui(game.players[event.player_index], name_to_tier.container[entity.name])
    end
end

---------------------------------------------------------------------------
local function on_mined_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if name_to_tier.cable[entity.name] then
        local tier = name_to_tier.cable[entity.name]

        local proxy = get_proxy(entity)

        local belt_neighbors = entity.belt_neighbours
        if belt_neighbors then
            cable_connection_update_scheduled = true
            table.insert(cable_connection_update_data, { belt_neighbors = belt_neighbors, tier = tier })
        end

        local t_net_requires_update = destroy_proxy(entity, proxy)

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
    elseif name_to_tier.node[entity.name] then
        local tier = name_to_tier.node[entity.name]

        local proxy = get_proxy(entity)

        local t_net_requires_update = destroy_proxy(entity, proxy)

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
    elseif name_to_tier.receiver[entity.name] then
        local tier = name_to_tier.receiver[entity.name]

        local proxy = get_proxy(entity)
        local t_net_requires_update
        if entity.to_be_upgraded() then
            -- Keep the container if the entity is to be upgraded but remove
            -- the reference to the container as it will be destroyed soon.
            proxies[entity.unit_number] = nil
        else
            t_net_requires_update = destroy_proxy(entity, proxy)
        end

        rx.un[entity.unit_number] = nil

        -- and the displayed text
        rendering.destroy(rx.text_id[entity.unit_number])
        rx.text_id[entity.unit_number] = nil

        -- and the ID
        rx.net_id[entity.unit_number] = nil

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
    elseif name_to_tier.transmitter[entity.name] then
        local tier = name_to_tier.transmitter[entity.name]

        local proxy = get_proxy(entity)

        local t_net_requires_update = destroy_proxy(entity, proxy)

        tx.un[entity.unit_number] = nil

        -- also destroy the displayed text
        rendering.destroy(tx.text_id[entity.unit_number])
        tx.text_id[entity.unit_number] = nil

        -- and the ID
        tx.net_id[entity.unit_number] = nil

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
    elseif name_to_tier.underground_cable[entity.name] then
        local tier = name_to_tier.underground_cable[entity.name]

        local proxy = get_proxy(entity)

        local t_net_requires_update = destroy_proxy(entity, proxy)

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
    end
end

---------------------------------------------------------------------------
local on_mined_filter = {}
for tier = 1, n_tiers do
    table.insert(on_mined_filter, { filter = "name", name = tier_to_name.cable[tier] })
    table.insert(on_mined_filter, { filter = "name", name = tier_to_name.node[tier] })
    table.insert(on_mined_filter, { filter = "name", name = tier_to_name.transmitter[tier] })
    table.insert(on_mined_filter, { filter = "name", name = tier_to_name.receiver[tier] })
    table.insert(on_mined_filter, { filter = "name", name = tier_to_name.underground_cable[tier] })
end

---------------------------------------------------------------------------
local function on_player_created(event)
    network_update_scheduled = true
    for tier = 1, n_tiers do
        table.insert(network_update_data, { tier = tier })
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
        rates[1] = rates[1] + rate_increment
    end
    if research.name == prefix .. "t2"
        or research.name == prefix .. "t2-speed1"
        or research.name == prefix .. "t2-speed2"
    then
        rates[2] = rates[2] + rate_increment
    end
    if research.name == prefix .. "t3"
        or research.name == prefix .. "t3-speed1"
        or research.name == prefix .. "t3-speed2"
        or research.name == prefix .. "t3-speed3"
    then
        rates[3] = rates[3] + rate_increment
    end
    if research.name == prefix .. "t3-infinite-speed"
    then
        rates[3] = math.ceil(rates[3] * rate_increment_factor)
    end
end

---------------------------------------------------------------------------
local function on_rotated_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    local belt_neighbors = { inputs = {} } -- use same table structure as entity.belt_neighbours
    local direction
    local neighbor
    local position
    if name_to_tier.cable[entity.name] then
        local tier = name_to_tier.cable[entity.name]

        -- After a rotation, what used to be a belt_neighbor might no longer be a belt_neighbor but still needs an upgrade.
        -- Search for (underground) cables north, east, south, west.
        for i = 0, 6, 2 do
            -- rotate direction by i / 2 * 90°
            direction = (entity.direction + i) % 8
            position = move_position(entity.position, direction, 1)

            neighbor = game.surfaces[1].find_entity(tier_to_name.cable[tier], position)
            if neighbor then
                table.insert(belt_neighbors.inputs, neighbor)
            end
            neighbor = game.surfaces[1].find_entity(tier_to_name.underground_cable[tier], position)
            if neighbor then
                table.insert(belt_neighbors.inputs, neighbor)
            end
        end

        local t_net_requires_update = disconnect_proxy(entity)
        t_net_requires_update = append(t_net_requires_update, cable_connect_to_neighbors(entity, tier))

        if belt_neighbors then
            cable_connection_update_scheduled = true
            table.insert(cable_connection_update_data, { belt_neighbors = belt_neighbors, tier = tier })
        end

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
    elseif name_to_tier.underground_cable[entity.name] then
        local tier = name_to_tier.underground_cable[entity.name]

        local t_net_requires_update = disconnect_proxy(entity)
        t_net_requires_update = append(t_net_requires_update, underground_cable_connect_to_neighbors(entity, tier))

        -- also make the neighboring underground cable react
        if entity.neighbours then
            t_net_requires_update = append(t_net_requires_update, disconnect_proxy(entity.neighbours))
            t_net_requires_update = append(t_net_requires_update,
                underground_cable_connect_to_neighbors(entity.neighbours, tier))
        end

        if t_net_requires_update then
            network_update_scheduled = true
            table.insert(network_update_data, { tier = tier, t_net_requires_update = t_net_requires_update })
        end
    end
end

---------------------------------------------------------------------------
local function on_tick(event)
    if network_update_scheduled then
        network_update_scheduled = false
        for _, event in pairs(network_update_data) do
            if event then
                update_net_id(event)
            end
        end
        network_update_data = {}
    end

    if cable_connection_update_scheduled then
        cable_connection_update_scheduled = false
        for _, event in pairs(cable_connection_update_data) do
            for _, val in pairs(event.belt_neighbors) do
                for _, neighbor in ipairs(val) do
                    if neighbor and neighbor.valid then
                        disconnect_proxy(neighbor)
                        if neighbor.name == tier_to_name.cable[event.tier] then
                            cable_connect_to_neighbors(neighbor, event.tier)
                        elseif neighbor.name == tier_to_name.underground_cable[event.tier] then
                            underground_cable_connect_to_neighbors(neighbor, event.tier)
                        end
                    end
                end
            end
        end
        cable_connection_update_data = {}
    end
end

---------------------------------------------------------------------------
local function get_inventory_rx(entity)
    if not entity or not entity.valid then
        return
    else
        return get_inventory(get_proxy(entity))
    end
end

local function get_item_count(entity, item)
    if not entity or not entity.valid then
        return
    else
        return get_inventory(entity).get_item_count(item)
    end
end

---------------------------------------------------------------------------
-- Sort the keys in the table `t` by their values.
local function keys_sorted_by_value(t)
    local keys = {}
    for key in pairs(t) do
        table.insert(keys, key)
    end

    table.sort(keys) -- ascending order

    return keys
end

-- Iterate over the key-value-pairs of the table `t` such that the values
-- appear in descending order.
local function pairs_by_descending_value(t)
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
        active_nets[tier] = {}
        for net_id, _ in pairs(active_nets[tier]) do
            -- all receiver priorities with this network_id
            rx_priority_array = rx.net_id_and_priority[net_id]

            if rx_priority_array then
                -- all receiver unit numbers with this network_id
                rx_un_array = rx.net_id_and_un[net_id]
                n_rx = #rx_un_array

                -- the filter of all receivers with this network_id
                -- filter = get_rx_filter(get_proxy(rx_un_array[1]), tier)
                filter = get_rx_filter(get_proxy(next(rx_un_array)), tier)

                if filter then
                    -- all transmitter unit numbers with this network_id
                    tx_un_array = tx.net_id_and_un[net_id]
                    n_tx = #tx_un_array

                    -- Count the total number of items in all transmitters' inventories.
                    n_count_tx = 0
                    count_tx = {}
                    -- for _, un in ipairs(tx_un_array) do
                    for un, _ in pairs(tx_un_array) do
                        count = get_item_count(tx.un[un], filter)
                        count_tx[un] = count
                        n_count_tx = n_count_tx + count
                    end

                    -- Try to move `rate` many items unless there are not enough items in all transmitters combined.
                    n_items_to_move = math.min(rates[tier], n_count_tx)

                    if n_items_to_move > 0 then
                        -- Sort the transmitters ascendingly by their item count.
                        tx_un_array_sorted_by_count = keys_sorted_by_value(count_tx)

                        -- On average, insert this many items into every receiver.
                        n_items_per_rx = n_items_to_move / n_rx

                        item_dividend = math.floor(n_items_per_rx)
                        item_remainder = n_items_to_move % n_rx
                        i = -1

                        n_items_inserted = 0
                        -- Try to give every receiver the necessary amount of items ...
                        for un, _ in pairs_by_descending_value(rx_priority_array) do
                            i = i + 1
                            n_insert = item_dividend
                            if i < item_remainder then
                                n_insert = item_dividend + 1
                            end

                            rx_inventory = get_inventory_rx(rx.un[un])
                            if rx_inventory then
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

                            tx_inventory = get_inventory(tx.un[un])
                            if tx_inventory then
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
end

---------------------------------------------------------------------------
local function initialize(global)
    active_nets = global.active_nets
    cable_connection_update_data = global.cable_connection_update_data
    cable_connection_update_scheduled = global.cable_connection_update_scheduled
    network_update_data = global.network_update_data
    network_update_scheduled = global.network_update_scheduled
    proxies = global.proxies
    rates = global.rates
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
    n_tiers = n_tiers
}
