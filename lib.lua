local dbg = require("debuglib")
require("util")

---------------------------------------------------------------------------
-- globals
local active_nets = {}
local lamps = {} -- all lamps
local rx = {}    -- all receivers
local tx = {}    -- all transmitters
local force      -- the force of the receiver
local mod_state = {}

---------------------------------------------------------------------------
local tiers = 3
local wire = defines.wire_type.red
local rate_increment = 15       -- whenever a research is finished, the item transport rate is increased by this amount
local rate_increment_factor = 2 -- whenever the infinite research is finished, multiply the item transport rate by this amount

local prefix = "transport-cables:"
local names = {}
for tier = 1, tiers do
    names[tier] = {
        lamp = prefix .. "lamp-t" .. tostring(tier),
        node = prefix .. "node-t" .. tostring(tier),
        transmitter = prefix .. "transmitter-t" .. tostring(tier),
        receiver = prefix .. "receiver-t" .. tostring(tier),
        cable = prefix .. "cable-t" .. tostring(tier),
        underground_cable = prefix .. "underground-cable-t" .. tostring(tier),
    }
end

local net_id_update_scheduled = {} -- is an update of the network ids necessary?

local item_transport_active = {}   -- are there any rx/tx pairs between which items need to be transported?
for tier = 1, tiers do
    item_transport_active[tier] = false
end

---------------------------------------------------------------------------
-- Move `distance` from `position` in `direction`, yielding a position vector.
local moveposition = function(position, direction, distance)
    distance = distance or 1

    if direction == defines.direction.north then
        return {
            x = position.x,
            y = position.y - distance
        }
    end

    if direction == defines.direction.south then
        return {
            x = position.x,
            y = position.y + distance
        }
    end

    if direction == defines.direction.east then
        return {
            x = position.x + distance,
            y = position.y
        }
    end

    if direction == defines.direction.west then
        return {
            x = position.x - distance,
            y = position.y
        }
    end
end

---------------------------------------------------------------------------
-- Store every receiver's filter in order to be able to detect a change
-- when the on_gui_closed event fires.
local update_receiver_filters = function(tier)
    for unit_number, entity in pairs(rx[tier].un) do
        rx[tier].filter[unit_number] = entity.get_filter(1)
    end

    if dbg.flags.print_update_receiver_filters then
        dbg.print("update_receiver_filters(): tier = " .. tostring(tier))
    end
end

---------------------------------------------------------------------------
-- get the lamp associated with `entity`
local get_lamp = function(entity, tier)
    return lamps[tier][entity.unit_number]
end

-- connect the two lamps associated with `source_entity` and `target_entity`
local connect_lamps = function(source_entity, target_entity, tier)
    if source_entity.type ~= "entity-ghost" and target_entity.type ~= "entity-ghost" then
        get_lamp(source_entity, tier).connect_neighbour {
            wire = wire,
            target_entity = get_lamp(target_entity, tier)
        }

        if dbg.flags.print_connect_lamps then
            dbg.print("connect_lamps(): " .. source_entity.name .. " < == > " .. target_entity.name)
        end
    end
end

-- create a lamp and associated it with `entity`
local create_lamp = function(entity, tier)
    lamps[tier][entity.unit_number] = game.surfaces[1].create_entity {
        name = names[tier].lamp,
        position = entity.position,
        force = 'player'
    }
end

-- disconnect the circuit connections associated with `entity`'s lamp
local disconnect_lamps = function(entity, tier)
    get_lamp(entity, tier).disconnect_neighbour(wire)

    if dbg.flags.print_connect_lamps then
        dbg.print("disconnect_lamps(): " .. entity.name)
    end
end

-- destroy the lamp associated with `entity`
local destroy_lamp = function(entity, tier)
    local destroyed = lamps[tier][entity.unit_number].destroy()
    lamps[tier][entity.unit_number] = nil
    return destroyed
end

---------------------------------------------------------------------------
-- All receivers with the same network_id as `entity` get the filter of
-- `entity`.
local set_receiver_filter_in_same_network_as = function(entity, tier)
    local net_id = rx[tier].net_id[entity.unit_number]
    if net_id and net_id > 0 then
        if rx[tier].net_id_and_un[net_id] then
            local filter = entity.get_filter(1)
            for _, unit_number in ipairs(rx[tier].net_id_and_un[net_id]) do
                rx[tier].un[unit_number].set_filter(1, filter)
            end
        end
        update_receiver_filters(tier)
    end
end

---------------------------------------------------------------------------
-- Store the circuit network id of all transmitters and receivers. Also, find
-- transmitters and receivers with the same circuit network id.
local update_net_id = function(tier)
    local circuit_network
    local net_id

    item_transport_active[tier] = false

    active_nets[tier] = {}
    tx[tier].net_id_and_un = {}
    rx[tier].net_id_and_un = {}

    -- store network_id of all transmitters
    for unit_number, entity in pairs(tx[tier].un) do
        circuit_network = get_lamp(entity, tier).get_circuit_network(wire)
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
        circuit_network = get_lamp(entity, tier).get_circuit_network(wire)
        if circuit_network then
            net_id = circuit_network.network_id

            rx[tier].net_id[unit_number] = net_id
            rendering.set_text(rx[tier].text_id[unit_number], "ID: " .. tostring(net_id))

            -- collect all receivers with the same network_id
            rx[tier].net_id_and_un[net_id] = rx[tier].net_id_and_un[net_id] or {}
            table.insert(rx[tier].net_id_and_un[net_id], unit_number)
        end
    end

    -- find transmitters and receivers with the same network_id
    for net_id, _ in pairs(rx[tier].net_id_and_un) do
        if tx[tier].net_id_and_un[net_id] then
            table.insert(active_nets[tier], net_id)
            item_transport_active[tier] = true
        end
    end

    if dbg.flags.print_update_net_id then
        dbg.print("update_net_id(): item_transport_active[" ..
            tostring(tier) .. "] = " .. tostring(item_transport_active[tier]))
    end
end

---------------------------------------------------------------------------
-- Connect a cable to suitable neighbors.
local cable_connect_to_neighbors = function(entity, tier)
    -- connect to neighboring cables
    for _, val in pairs(entity.belt_neighbours) do
        for _, neighbor in ipairs(val) do
            if neighbor.name == names[tier].cable then
                if entity.direction == neighbor.direction then
                    connect_lamps(entity, neighbor, tier)
                end
                -- the neighbor is a curved cable not facing in the opposite direction
                if neighbor.belt_shape ~= "straight" and entity.direction ~= util.oppositedirection(neighbor.direction) then
                    connect_lamps(entity, neighbor, tier)
                end
            elseif neighbor.name == names[tier].underground_cable then
                if entity.direction == neighbor.direction then
                    connect_lamps(entity, neighbor, tier)
                end
            end
        end
    end

    -- connect to receiver north of cable
    local position = moveposition(entity.position, entity.direction, 1)
    local receiver = game.surfaces[1].find_entity(names[tier].receiver, position)
    if receiver then
        connect_lamps(entity, receiver, tier)
    end

    -- connect to transmitter south of cable
    position = moveposition(entity.position, entity.direction, -1)
    local transmitter = game.surfaces[1].find_entity(names[tier].transmitter, position)
    if transmitter then
        connect_lamps(entity, transmitter, tier)
    end

    -- connect to node north of cable
    position = moveposition(entity.position, entity.direction, 1)
    local entity_node = game.surfaces[1].find_entity(names[tier].node, position)
    if entity_node then
        connect_lamps(entity, entity_node, tier)
    end

    -- connect to node south of cable
    position = moveposition(entity.position, entity.direction, -1)
    entity_node = game.surfaces[1].find_entity(names[tier].node, position)
    if entity_node then
        connect_lamps(entity, entity_node, tier)
    end
end

---------------------------------------------------------------------------
-- Connect an underground cable to suitable neighbors.
local underground_cable_connect_to_neighbors = function(entity, tier)
    -- connect to neighboring underground_cable
    if entity.neighbours then
        connect_lamps(entity, entity.neighbours, tier)
    end

    -- connect to underground_cable north of underground_cable if it is facing in the same direction
    local position = moveposition(entity.position, entity.direction, 1)
    local entity_cable = game.surfaces[1].find_entity(names[tier].underground_cable, position)
    if entity_cable then
        if entity_cable.direction == entity.direction then
            connect_lamps(entity, entity_cable, tier)
        end
    end

    -- connect to underground_cable south of underground_cable if it is facing in the same direction
    position = moveposition(entity.position, entity.direction, -1)
    entity_cable = game.surfaces[1].find_entity(names[tier].underground_cable, position)
    if entity_cable then
        if entity_cable.direction == entity.direction then
            connect_lamps(entity, entity_cable, tier)
        end
    end

    -- connect to cable north of underground_cable if it is not facing towards
    -- the underground_cable
    position = moveposition(entity.position, entity.direction, 1)
    entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
    if entity_cable then
        if entity_cable.direction ~= util.oppositedirection(entity.direction) then
            connect_lamps(entity, entity_cable, tier)
        end
    end

    -- connect to cable south of underground_cable if it is facing in the
    -- same direction
    position = moveposition(entity.position, entity.direction, -1)
    entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
    if entity_cable then
        if entity_cable.direction == entity.direction then
            connect_lamps(entity, entity_cable, tier)
        end
    end
end

---------------------------------------------------------------------------
local on_built_entity = function(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    for tier = 1, tiers do
        if entity.name == names[tier].transmitter then
            create_lamp(entity, tier)

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

            -- connect to cable north, east, south, west of transmitter if it is facing away from the transmitter
            local position
            local direction
            local entity_cable
            for i = 0, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = moveposition(entity.position, direction, 1)
                entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
                if entity_cable then
                    if entity_cable.direction == direction then
                        connect_lamps(entity, entity_cable, tier)
                    end
                end
            end

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].receiver then
            entity.force = force

            create_lamp(entity, tier)

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

            -- connect to cable north, east, south, west of receiver if it is facing towards the receiver
            local direction
            local entity_cable
            for i = 0, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = moveposition(entity.position, direction, 1)
                entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
                if entity_cable then
                    if entity_cable.direction == util.oppositedirection(direction) then
                        connect_lamps(entity, entity_cable, tier)
                    end
                end
            end

            update_receiver_filters(tier)

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].node then
            create_lamp(entity, tier)

            -- connect to neighboring cables if they are facing towards or away
            -- from the node
            local position
            local direction
            local entity_cable
            for i = 0, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = moveposition(entity.position, direction, 1)
                entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
                if entity_cable then
                    if (entity_cable.direction == direction) or (entity_cable.direction == util.oppositedirection(direction)) then
                        connect_lamps(entity, entity_cable, tier)
                    end
                end
            end

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].cable then
            create_lamp(entity, tier)
            cable_connect_to_neighbors(entity, tier)

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].underground_cable then
            create_lamp(entity, tier)
            underground_cable_connect_to_neighbors(entity, tier)

            net_id_update_scheduled[tier] = true
            return
        end
    end
end

---------------------------------------------------------------------------
local on_built_filter = {}
for tier = 1, tiers do
    table.insert(on_built_filter, { filter = "name", name = names[tier].cable })
    table.insert(on_built_filter, { filter = "name", name = names[tier].node })
    table.insert(on_built_filter, { filter = "name", name = names[tier].transmitter })
    table.insert(on_built_filter, { filter = "name", name = names[tier].receiver })
    table.insert(on_built_filter, { filter = "name", name = names[tier].underground_cable })
end

---------------------------------------------------------------------------
local on_console_command = function(command)
    if command.name == dbg.commands.print_off then
        dbg.flags.print_connect_lamps = false
        dbg.flags.print_update_net_id = false
        dbg.flags.print_update_receiver_filter = false
        dbg.print("set all print flags false")
    elseif command.name == dbg.commands.print_on then
        dbg.flags.print_connect_lamps = true
        dbg.flags.print_update_net_id = true
        dbg.flags.print_update_receiver_filter = true
        dbg.print("set all print flags true")
    elseif command.name == dbg.commands.print_connect_lamps then
        dbg.flags.print_connect_lamps = not dbg.flags.print_connect_lamps
        dbg.print("print_connect_lamps = " .. tostring(dbg.flags.print_connect_lamps))
    elseif command.name == dbg.commands.print_on_research_finished then
        dbg.flags.print_on_research_finished = not dbg.flags.print_on_research_finished
        dbg.print("print_on_research_finished = " .. tostring(dbg.flags.print_on_research_finished))
    elseif command.name == dbg.commands.print_update_net_id then
        dbg.flags.print_update_net_id = not dbg.flags.print_update_net_id
        dbg.print("print_update_net_id = " .. tostring(dbg.flags.print_update_net_id))
    elseif command.name == dbg.commands.print_update_receiver_filter then
        dbg.flags.print_update_receiver_filter = not dbg.flags.print_update_receiver_filter
        dbg.print("print_update_receiver_filter = " .. tostring(dbg.flags.print_update_receiver_filter))
    end
end

---------------------------------------------------------------------------
local on_entity_settings_pasted = function(event)
    for tier = 1, tiers do
        if event.source.name == names[tier].receiver and event.destination.name == names[tier].receiver then
            set_receiver_filter_in_same_network_as(event.destination, tier)
            return
        end
    end
end

---------------------------------------------------------------------------
local on_gui_closed = function(event)
    if event.entity and event.entity.valid then
        for tier = 1, tiers do
            if event.entity.name == names[tier].receiver then
                set_receiver_filter_in_same_network_as(event.entity, tier)
                return
            end
        end
    end
end

---------------------------------------------------------------------------
local on_mined_entity = function(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    for tier = 1, tiers do
        if entity.name == names[tier].transmitter then
            destroy_lamp(entity, tier)

            tx[tier].un[entity.unit_number] = nil

            -- also destroy the displayed text
            rendering.destroy(tx[tier].text_id[entity.unit_number])
            tx[tier].text_id[entity.unit_number] = nil

            -- and the ID
            tx[tier].net_id[entity.unit_number] = nil

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].node then
            destroy_lamp(entity, tier)

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].receiver then
            destroy_lamp(entity, tier)

            rx[tier].un[entity.unit_number] = nil

            -- and the displayed text
            rendering.destroy(rx[tier].text_id[entity.unit_number])
            rx[tier].text_id[entity.unit_number] = nil

            -- and the ID
            rx[tier].net_id[entity.unit_number] = nil

            -- and the filter
            rx[tier].filter[entity.unit_number] = nil

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].cable then
            destroy_lamp(entity, tier)

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].underground_cable then
            destroy_lamp(entity, tier)

            net_id_update_scheduled[tier] = true
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
for tier = 1, tiers do
    table.insert(on_mined_filter, { filter = "name", name = names[tier].cable })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].node })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].transmitter })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].receiver })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].underground_cable })
end

---------------------------------------------------------------------------
-- Initialize the GUI elements.
local on_player_created = function(event)
    local player = game.players[event.player_index]

    -- make friends with receiver
    force.set_cease_fire(player.force, true)
    force.set_friend(player.force, true)

    for tier = 1, tiers do
        net_id_update_scheduled[tier] = true
    end

    if mod_state[1].rate > 0 then
        player.gui.top.add { type = "label", name = "t1", caption = "Tier 1: " .. tostring(mod_state[1].rate) .. " items / s." }
    else
        player.gui.top.add { type = "label", name = "t1", caption = "" }
    end
    if mod_state[2].rate > 30 then
        player.gui.top.add { type = "label", name = "t2", caption = "| Tier 2: " .. tostring(mod_state[2].rate) .. " items / s." }
    else
        player.gui.top.add { type = "label", name = "t2", caption = "" }
    end
    if mod_state[3].rate > 75 then
        player.gui.top.add { type = "label", name = "t3", caption = "| Tier 3: " .. tostring(mod_state[3].rate) .. " items / s." }
    else
        player.gui.top.add { type = "label", name = "t3", caption = "" }
    end
end

---------------------------------------------------------------------------
-- Whenever a technology is researched, increment the item rate and display the
-- updated value.
local on_research_finished = function(event)
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

    for _, player in pairs(game.players) do
        if research.name == prefix .. "t1"
            or research.name == prefix .. "t1-speed"
        then
            player.gui.top["t1"].caption = "Tier 1: " .. tostring(mod_state[1].rate) .. " items / s."
        end
        if research.name == prefix .. "t2"
            or research.name == prefix .. "t2-speed1"
            or research.name == prefix .. "t2-speed2"
        then
            player.gui.top["t2"].caption = "| Tier 2: " .. tostring(mod_state[2].rate) .. " items / s."
        end
        if research.name == prefix .. "t3"
            or research.name == prefix .. "t3-speed1"
            or research.name == prefix .. "t3-speed2"
            or research.name == prefix .. "t3-speed3"
            or research.name == prefix .. "t3-infinite-speed"
        then
            player.gui.top["t3"].caption = "| Tier 3: " .. tostring(mod_state[3].rate) .. " items / s."
        end
    end
end

---------------------------------------------------------------------------
local on_rotated_entity = function(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    for tier = 1, tiers do
        if entity.name == names[tier].cable then
            disconnect_lamps(entity, tier)
            cable_connect_to_neighbors(entity, tier)

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].underground_cable then
            disconnect_lamps(entity, tier)
            underground_cable_connect_to_neighbors(entity, tier)

            -- also make the neighboring underground cable react
            if entity.neighbours then
                disconnect_lamps(entity.neighbours, tier)
                underground_cable_connect_to_neighbors(entity.neighbours, tier)
            end

            net_id_update_scheduled[tier] = true
            return
        end
    end
end

---------------------------------------------------------------------------
local keys_sorted_by_value = function(t)
    local keys = {}
    for key in pairs(t) do
        table.insert(keys, key)
    end

    table.sort(keys)

    return keys
end

---------------------------------------------------------------------------
local on_tick = function(event)
    for tier = 1, tiers do
        if net_id_update_scheduled[tier] then
            net_id_update_scheduled[tier] = false
            update_net_id(tier)
        end
    end
end

---------------------------------------------------------------------------
local count           -- counts items
local e_cont          -- a receiver container entity
local e_prov          -- a transmitter entity
local inve_tx         -- unit number -> number of items in a transmitter
local inve_rx         -- unit number -> number of items that can be inserted into a receiver
local inventory       -- an entity's inventory
local keys_prov       -- transmitter inventory keys
local keys_requ       -- receiver inventory keys
local n_empty_inve_rx -- total number of empty slots in receivers
local n               -- an element of `inve_tx`
local n_inve_tx       -- total number of items in transmitters
local n_items_per_tx  -- the average number of items to be moved per transmitter
local n_items_per_rx  -- the average number of items to be moved per receiver
local n_item_inse     -- the number of items that has already been inserted into receivers
local n_item_remo     -- the number of items that has already been removed from transmitters
local n_item_rema     -- the number of items that still needs to be removed from transmitters
local n_item_to_move  -- the number of items that needs to be moved in this network
local n_tx            -- the number of transmitters with the current network id
local n_tx_visi       -- the number of transmitters from which items have already been removed
local n_rx            -- the number of receivers with the current network id
local n_rx_visi       -- the number of receivers into which items have already been inserted
local transmitter_un_array
local receiver_un_array
local filter
local unit_number
local on_nth_tick = function(event)
    -- move items between transmitter-receiver-pairs
    for tier = 1, tiers do
        if item_transport_active[tier] then
            for _, net_id in ipairs(active_nets[tier]) do
                -- all transmitter unit numbers with this network_id
                transmitter_un_array = tx[tier].net_id_and_un[net_id]
                n_tx = #transmitter_un_array

                -- all receiver unit numbers with this network_id
                receiver_un_array = rx[tier].net_id_and_un[net_id]
                n_rx = #receiver_un_array

                -- the filter of all receivers with this network_id
                unit_number = receiver_un_array[1]
                filter = rx[tier].filter[unit_number]

                if filter then
                    -- count items in transmitters' inventories
                    n_inve_tx = 0
                    inve_tx = {}
                    for _, un in ipairs(transmitter_un_array) do
                        e_prov = tx[tier].un[un]
                        count = e_prov.get_inventory(defines.inventory.item_main).get_item_count(filter)
                        inve_tx[un] = count
                        n_inve_tx = n_inve_tx + count
                    end
                    keys_prov = keys_sorted_by_value(inve_tx)

                    -- count how many items fit in receivers' inventories
                    n_empty_inve_rx = 0
                    inve_rx = {}
                    for _, un in ipairs(receiver_un_array) do
                        e_cont = rx[tier].un[un]
                        count = e_cont.get_inventory(defines.inventory.item_main).get_insertable_count(filter)
                        inve_rx[un] = count
                        n_empty_inve_rx = n_empty_inve_rx + count
                    end
                    keys_requ = keys_sorted_by_value(inve_rx)

                    n_item_to_move = math.min(mod_state[tier].rate, n_inve_tx, n_empty_inve_rx)
                    if n_item_to_move > 0 then
                        n_items_per_tx = math.floor(n_item_to_move / n_tx)
                        n_items_per_rx = math.floor(n_item_to_move / n_rx)

                        -- remove items from transmitters
                        n_tx_visi = 0
                        n_item_remo = 0
                        for _, k_un in ipairs(keys_prov) do
                            n_tx_visi = n_tx_visi + 1
                            n = inve_tx[k_un]
                            e_prov = tx[tier].un[k_un]
                            inventory = e_prov.get_inventory(defines.inventory.item_main)
                            if n >= n_items_per_tx then
                                -- if there are enough items to remove, remove them
                                if n_items_per_tx > 0 then
                                    inventory.remove({ name = filter, count = n_items_per_tx })
                                end
                                n_item_remo = n_item_remo + n_items_per_tx
                            else
                                -- otherwise remove as much as possible and update the remaining
                                -- number of items that need to be removed

                                if n_tx == n_tx_visi then
                                    -- this is the last transmitter
                                    -- try to remove as much as possible to achieve the move goal
                                    n_item_rema = n_item_to_move - n_item_remo
                                    if n >= n_item_rema then
                                        if n_item_rema then
                                            inventory.remove({ name = filter, count = n_item_rema })
                                        end
                                    else
                                        if n > 0 then
                                            inventory.remove({ name = filter, count = n })
                                        end
                                    end
                                else
                                    -- Remove all items
                                    if n > 0 then
                                        inventory.remove({ name = filter, count = n })
                                    end
                                    n_item_remo = n_item_remo + n
                                    -- and update the number of items that need to be removed from the remaining transmitters.
                                    n_items_per_tx = math.floor((n_item_to_move - n_item_remo) / (n_tx - n_tx_visi))
                                end
                            end
                        end

                        -- insert items into receivers
                        n_rx_visi = 0
                        n_item_inse = 0
                        for _, k_un in ipairs(keys_requ) do
                            n_rx_visi = n_rx_visi + 1
                            n = inve_rx[k_un]
                            e_cont = rx[tier].un[k_un]
                            inventory = e_cont.get_inventory(defines.inventory.item_main)
                            if n >= n_items_per_rx then
                                -- if enough items can be inserted, insert them
                                if n_items_per_rx > 0 then
                                    inventory.insert({ name = filter, count = n_items_per_rx })
                                end
                                n_item_inse = n_item_inse + n_items_per_rx
                            else
                                -- otherwise insert as much as possible and update the remaining
                                -- number of items that need to be inserted

                                if n_rx == n_rx_visi then
                                    -- this is the last receiver
                                    -- try to insert as much as possible to achieve the move goal
                                    n_item_rema = n_item_to_move - n_item_inse
                                    if n >= n_item_rema then
                                        if n_item_rema > 0 then
                                            inventory.insert({ name = filter, count = n_item_rema })
                                        end
                                    else
                                        if n > 0 then
                                            inventory.insert({ name = filter, count = n })
                                        end
                                    end
                                else
                                    -- Fill receiver
                                    if n > 0 then
                                        inventory.insert({ name = filter, count = n })
                                    end
                                    n_item_inse = n_item_inse + n
                                    -- and update the number of items that need to be inserted into the remaining receivers.
                                    n_items_per_rx = math.floor((n_item_to_move - n_item_inse) / (n_rx - n_rx_visi))
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
local initialize = function(global)
    active_nets = global.active_nets
    mod_state = global.mod_state
    net_id_update_scheduled = global.net_id_update_scheduled
    lamps = global.lamps
    rx = global.receiver
    tx = global.transmitter
    force = global.force
end

---------------------------------------------------------------------------
return {
    initialize = initialize,
    on_built_entity = on_built_entity,
    on_built_filter = on_built_filter,
    on_console_command = on_console_command,
    on_entity_settings_pasted = on_entity_settings_pasted,
    on_gui_closed = on_gui_closed,
    on_mined_entity = on_mined_entity,
    on_mined_filter = on_mined_filter,
    on_nth_tick = on_nth_tick,
    on_player_created = on_player_created,
    on_research_finished = on_research_finished,
    on_rotated_entity = on_rotated_entity,
    on_tick = on_tick,
    prefix = prefix,
    tiers = tiers
}
