require("util")

local debug_lamp = false
local debug_print = true

---------------------------------------------------------------------------
local tiers = 3
local wire = defines.wire_type.red
local mod_state = {}
local rate_increment = 15
local rate_increment_factor = 1.1

local item_transport_active = {}
local net_id_update_scheduled = {}
for tier = 1, tiers do
    item_transport_active[tier] = false
    net_id_update_scheduled[tier] = false
end

local lamps = {} -- all lamps
local provs = {} -- all providers
local requs = {} -- all requesters
local same_net_id = {}

local prefix = "transport-cables:"
local names = {}
for tier = 1, tiers do
    names[tier] = {
        lamp = prefix .. "lamp-t" .. tostring(tier),
        node = prefix .. "node-t" .. tostring(tier),
        provider = prefix .. "provider-t" .. tostring(tier),
        requester_container = prefix .. "requester-container-t" .. tostring(tier),
        requester = prefix .. "requester-t" .. tostring(tier),
        cable = prefix .. "cable-t" .. tostring(tier),
        underground_cable = prefix .. "underground-cable-t" .. tostring(tier),
    }
end

local command_debug_lamp = "transport-cables-debug-lamp"
local command_debug_print = "transport-cables-debug-print"

---------------------------------------------------------------------------
local debugprint = function(str)
    for _, player in pairs(game.players) do
        player.print(str)
    end
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
-- Store every requester's signal in order to be able to detect a change
-- when the on_gui_closed event fires.
local update_requester_signals = function(tier)
    for unit_number, entity in pairs(requs[tier].un) do
        requs[tier].signal[unit_number] = entity.get_control_behavior().get_signal(1)
    end

    if debug_print then
        debugprint("update_requester_signals(): tier = " .. tostring(tier))
    end
end

---------------------------------------------------------------------------
-- All requesters with the same network_id as `entity` get the signal of
-- `entity`.
local set_requester_signals_in_same_network_as = function(entity, tier)
    local net_id = requs[tier].net_id[entity.unit_number]
    if net_id and net_id > 0 then
        local unit_number_array = requs[tier].net_id_and_un[net_id]
        if unit_number_array then
            local signal = entity.get_control_behavior().get_signal(1)
            for _, unit_number in ipairs(requs[tier].net_id_and_un[net_id]) do
                if signal.signal then
                    requs[tier].un[unit_number].get_control_behavior().set_signal(1, signal)
                else
                    requs[tier].un[unit_number].get_control_behavior().set_signal(1, nil)
                end
            end
        end
        update_requester_signals(tier)
    end
end

---------------------------------------------------------------------------
-- Store the circuit network id of all providers and requesters. Also, find
-- providers and requesters with the same circuit network id.
local update_net_id = function(tier)
    local circuit_network
    local net_id

    item_transport_active[tier] = false

    same_net_id[tier] = {}
    provs[tier].net_id_and_un = {}
    requs[tier].net_id_and_un = {}

    -- store network_id of all providers
    for unit_number, entity in pairs(provs[tier].un) do
        circuit_network = entity.get_circuit_network(wire)
        if circuit_network then
            net_id = circuit_network.network_id

            provs[tier].net_id[unit_number] = net_id
            rendering.set_text(provs[tier].text_id[unit_number], "ID: " .. tostring(net_id))

            -- collect all providers with the same network_id
            provs[tier].net_id_and_un[net_id] = provs[tier].net_id_and_un[net_id] or {}
            table.insert(provs[tier].net_id_and_un[net_id], unit_number)
        end
    end

    -- store network_id of all requesters
    for unit_number, entity in pairs(requs[tier].un) do
        circuit_network = entity.get_circuit_network(wire)
        if circuit_network then
            net_id = circuit_network.network_id

            requs[tier].net_id[unit_number] = net_id
            rendering.set_text(requs[tier].text_id[unit_number], "ID: " .. tostring(net_id))

            -- collect all requesters with the same network_id
            requs[tier].net_id_and_un[net_id] = requs[tier].net_id_and_un[net_id] or {}
            table.insert(requs[tier].net_id_and_un[net_id], unit_number)
        end
    end

    -- find providers and requesters with the same network_id
    for net_id, _ in pairs(requs[tier].net_id_and_un) do
        if provs[tier].net_id_and_un[net_id] then
            table.insert(same_net_id[tier], net_id)
            item_transport_active[tier] = true
        end
    end

    if debug_print then
        debugprint("update_net_id(): item_transport_active[" ..
            tostring(tier) .. "] = " .. tostring(item_transport_active[tier]))
    end
end

---------------------------------------------------------------------------
local on_built_entity = function(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    for tier = 1, tiers do
        if entity.name == names[tier].provider then
            provs[tier].un[entity.unit_number] = entity
            provs[tier].pos[entity.position] = entity

            -- default ID
            provs[tier].net_id[entity.unit_number] = -1

            -- display ID
            provs[tier].text_id[entity.unit_number] = rendering.draw_text {
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

            -- connect to cable north, east, south, west of provider if it is
            -- facing away from the provider
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
                        entity.connect_neighbour {
                            wire = wire,
                            target_entity = entity_cable
                        }
                    end
                end
            end

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].requester then
            requs[tier].un[entity.unit_number] = entity
            requs[tier].pos[entity.position] = entity

            -- in addition, place a container
            local position = moveposition(entity.position, entity.direction)
            requs[tier].container[entity.unit_number] = game.surfaces[1].create_entity {
                name = names[tier].requester_container,
                position = position,
                force = "player"
            }

            -- default ID
            requs[tier].net_id[entity.unit_number] = -1

            -- display ID
            requs[tier].text_id[entity.unit_number] = rendering.draw_text {
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

            -- connect to cable east, south, west of requester if it is facing
            -- towards the requester
            local direction
            local entity_cable
            for i = 2, 6, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = moveposition(entity.position, direction, 1)
                entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
                if entity_cable then
                    if entity_cable.direction == util.oppositedirection(direction) then
                        entity.connect_neighbour {
                            wire = wire,
                            target_entity = entity_cable
                        }
                    end
                end
            end

            update_requester_signals(tier)

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].node then
            -- connect to neighboring cables if they are facing towards or away
            -- from the node
            local position
            local direction
            local entity_cable
            for i = 0, 8, 2 do
                -- rotate direction by i / 2 * 90°
                direction = (entity.direction + i) % 8
                position = moveposition(entity.position, direction, 1)
                entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
                if entity_cable then
                    if (entity_cable.direction == direction) or (entity_cable.direction == util.oppositedirection(direction)) then
                        entity.connect_neighbour {
                            wire = wire,
                            target_entity = entity_cable
                        }
                    end
                end
            end

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].cable then
            -- connect to neighboring cables
            for _, val in pairs(entity.belt_neighbours) do
                for _, neighbor in ipairs(val) do
                    -- if the neighbor is an underground_cable, connect to the corresponding lamp
                    if neighbor.name == names[tier].underground_cable then
                        local lamp = game.surfaces[1].find_entity(names[tier].lamp, neighbor.position)
                        if (entity.direction ~= util.oppositedirection(neighbor.direction)) then
                            entity.connect_neighbour {
                                wire = wire,
                                target_entity = lamp
                            }
                        end
                    else
                        entity.connect_neighbour {
                            wire = wire,
                            target_entity = neighbor
                        }
                        entity.get_control_behavior().enable_disable = false
                        neighbor.get_control_behavior().enable_disable = false
                    end
                end
            end

            -- connect to requester north of cable
            position = moveposition(entity.position, entity.direction, 1)
            if requs[tier].pos[position] then
                entity.connect_neighbour {
                    wire = wire,
                    target_entity = requs[tier].pos[position]
                }
            end

            -- connect to provider south of cable
            position = moveposition(entity.position, entity.direction, -1)
            if provs[tier].pos[position] then
                entity.connect_neighbour {
                    wire = wire,
                    target_entity = provs[tier].pos[position]
                }
            end

            -- connect to node north of cable
            position = moveposition(entity.position, entity.direction, 1)
            local entity_node = game.surfaces[1].find_entity(names[tier].node, position)
            if entity_node then
                entity.connect_neighbour {
                    wire = wire,
                    target_entity = entity_node
                }
            end

            -- connect to node south of cable
            position = moveposition(entity.position, entity.direction, -1)
            entity_node = game.surfaces[1].find_entity(names[tier].node, position)
            if entity_node then
                entity.connect_neighbour {
                    wire = wire,
                    target_entity = entity_node
                }
            end

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].underground_cable then
            -- also place a lamp
            local lamp = game.surfaces[1].create_entity {
                name = names[tier].lamp,
                position = entity.position,
                force = 'player'
            }
            lamps[tier][entity.position] = lamp

            -- connect to neighboring underground_cable's lamp
            if entity.neighbours then
                local lamp_neighbor = game.surfaces[1].find_entity(names[tier].lamp, entity.neighbours.position)
                lamp.connect_neighbour {
                    wire = wire,
                    target_entity = lamp_neighbor
                }
            end

            -- connect to cable north of underground_cable if it is not facing towards
            -- the underground_cable
            local position = moveposition(entity.position, entity.direction, 1)
            local entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
            if entity_cable then
                if entity_cable.direction ~= util.oppositedirection(entity.direction) then
                    lamp.connect_neighbour {
                        wire = wire,
                        target_entity = entity_cable
                    }
                end
            end

            -- connect to cable south of underground_cable if it is facing in the
            -- same direction
            position = moveposition(entity.position, entity.direction, -1)
            entity_cable = game.surfaces[1].find_entity(names[tier].cable, position)
            if entity_cable then
                if entity_cable.direction == entity.direction then
                    lamp.connect_neighbour {
                        wire = wire,
                        target_entity = entity_cable
                    }
                end
            end

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
    table.insert(on_built_filter, { filter = "name", name = names[tier].provider })
    table.insert(on_built_filter, { filter = "name", name = names[tier].requester })
    table.insert(on_built_filter, { filter = "name", name = names[tier].underground_cable })
end

---------------------------------------------------------------------------
local on_console_command = function(command)
    if command.name == command_debug_lamp then
        if not command.parameters then
            debug_lamp = not debug_lamp
        else
            debug_lamp = true
        end

        game.get_player(command.player_index).print("debug_lamp = " .. tostring(debug_lamp))

        local comparator = "!="
        if debug_lamp then
            comparator = "="
        end

        local control_behavior
        local counter
        for tier = 1, tiers do
            counter = 0
            for pos, lamp in pairs(lamps[tier]) do
                counter = counter + 1
                if lamp.valid then
                    control_behavior = lamp.get_control_behavior()
                    control_behavior.circuit_condition = {
                        condition =
                        {
                            comparator = comparator,
                            first_signal = { type = "virtual", name = "signal-0" },
                            second_signal = { type = "virtual", name = "signal-0" }
                        }
                    }
                end
            end
            if debug_lamp then
                game.get_player(
                    command.player_index).print("tier " ..
                    tostring(tier) .. ": found " .. tostring(counter) .. " lamps"
                )
            end
        end
    elseif command.name == command_debug_print then
        debug_print = not debug_print
        game.get_player(command.player_index).print("debug_print = " .. tostring(debug_print))
    end
end

---------------------------------------------------------------------------
local on_entity_settings_pasted = function(event)
    for tier = 1, tiers do
        if event.source.name == names[tier].requester and event.destination.name == names[tier].requester then
            set_requester_signals_in_same_network_as(event.destination, tier)
            return
        end
    end
end

---------------------------------------------------------------------------
local on_gui_closed = function(event)
    for tier = 1, tiers do
        if event.entity and event.entity.valid then
            if event.entity.name == names[tier].requester then
                set_requester_signals_in_same_network_as(event.entity, tier)
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
        if entity.name == names[tier].provider then
            provs[tier].un[entity.unit_number] = nil
            provs[tier].pos[entity.position] = nil

            -- also destroy the displayed text
            rendering.destroy(provs[tier].text_id[entity.unit_number])
            provs[tier].text_id[entity.unit_number] = nil

            -- and the ID
            provs[tier].net_id[entity.unit_number] = nil

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].node then
            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].requester then
            requs[tier].un[entity.unit_number] = nil
            requs[tier].pos[entity.position] = nil

            -- also destroy the container
            requs[tier].container[entity.unit_number].destroy()
            requs[tier].container[entity.unit_number] = nil

            -- and the displayed text
            rendering.destroy(requs[tier].text_id[entity.unit_number])
            requs[tier].text_id[entity.unit_number] = nil

            -- and the ID
            requs[tier].net_id[entity.unit_number] = nil

            -- and the signal
            requs[tier].signal[entity.unit_number] = nil

            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].cable then
            net_id_update_scheduled[tier] = true
            return
        elseif entity.name == names[tier].underground_cable then
            -- destroy the associated lamp
            game.surfaces[1].find_entity(names[tier].lamp, entity.position).destroy()

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
    table.insert(on_mined_filter, { filter = "name", name = names[tier].provider })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].requester })
    table.insert(on_mined_filter, { filter = "name", name = names[tier].underground_cable })
end

---------------------------------------------------------------------------
-- Initialize the GUI elements.
local on_player_created = function(event)
    local player = game.players[event.player_index]

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

    if debug_print then
        debugprint("on_research_finished(): research.name = " .. research.name)
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
        if entity.name == names[tier].requester then
            -- move the container in front of the requester again
            local e_cont = requs[tier].container[entity.unit_number]
            local position = moveposition(entity.position, entity.direction)
            e_cont.teleport(position)
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
local count             -- counts items
local e_cont            -- a requester container entity
local e_prov            -- a provider entity
local inve_prov         -- unit number -> number of items in a provider
local inve_requ         -- unit number -> number of items that can be inserted into a requester
local inventory         -- an entity's inventory
local keys_prov         -- provider inventory keys
local keys_requ         -- requester inventory keys
local n_empty_inve_requ -- total number of empty slots in requesters
local n                 -- an element of `inve_prov`
local n_inve_prov       -- total number of items in providers
local n_items_per_prov  -- the average number of items to be moved per provider
local n_items_per_requ  -- the average number of items to be moved per requester
local n_item_inse       -- the number of items that has already been inserted into requesters
local n_item_remo       -- the number of items that has already been removed from providers
local n_item_rema       -- the number of items that still needs to be removed from providers
local n_item_to_move    -- the number of items that needs to be moved in this network
local n_prov            -- the number of providers with the current network id
local n_prov_visi       -- the number of providers from which items have already been removed
local n_requ            -- the number of requesters with the current network id
local n_requ_visi       -- the number of requesters into which items have already been inserted
local provider_un_array
local requester_un_array
local signal_name
local signal
local unit_number
local on_nth_tick = function(event)
    -- move items between provider-requester-pairs
    for tier = 1, tiers do
        if item_transport_active[tier] then
            for _, net_id in ipairs(same_net_id[tier]) do
                -- all provider unit numbers with this network_id
                provider_un_array = provs[tier].net_id_and_un[net_id]
                n_prov = #provider_un_array

                -- all requester unit numbers with this network_id
                requester_un_array = requs[tier].net_id_and_un[net_id]
                n_requ = #requester_un_array

                -- the signal of all requesters with this network_id
                unit_number = requester_un_array[1]
                signal = requs[tier].signal[unit_number]

                if signal and signal.signal then
                    signal_name = signal.signal.name

                    -- count items in providers' inventories
                    n_inve_prov = 0
                    inve_prov = {}
                    for _, un in ipairs(provider_un_array) do
                        e_prov = provs[tier].un[un]
                        count = e_prov.get_inventory(defines.inventory.item_main).get_item_count(signal_name)
                        inve_prov[un] = count
                        n_inve_prov = n_inve_prov + count
                    end
                    keys_prov = keys_sorted_by_value(inve_prov)

                    -- count how many items fit in requesters' inventories
                    n_empty_inve_requ = 0
                    inve_requ = {}
                    for _, un in ipairs(requester_un_array) do
                        e_cont = requs[tier].container[un]
                        count = e_cont.get_inventory(defines.inventory.item_main).get_insertable_count(signal_name)
                        inve_requ[un] = count
                        n_empty_inve_requ = n_empty_inve_requ + count
                    end
                    keys_requ = keys_sorted_by_value(inve_requ)

                    n_item_to_move = math.min(mod_state[tier].rate, n_inve_prov, n_empty_inve_requ)
                    if n_item_to_move > 0 then
                        n_items_per_prov = math.floor(n_item_to_move / n_prov)
                        n_items_per_requ = math.floor(n_item_to_move / n_requ)

                        -- remove items from providers
                        n_prov_visi = 0
                        n_item_remo = 0
                        for _, k_un in ipairs(keys_prov) do
                            n_prov_visi = n_prov_visi + 1
                            n = inve_prov[k_un]
                            e_prov = provs[tier].un[k_un]
                            inventory = e_prov.get_inventory(defines.inventory.item_main)
                            if n >= n_items_per_prov then
                                -- if there are enough items to remove, remove them
                                if n_items_per_prov > 0 then
                                    inventory.remove({ name = signal_name, count = n_items_per_prov })
                                end
                                n_item_remo = n_item_remo + n_items_per_prov
                            else
                                -- otherwise remove as much as possible and update the remaining
                                -- number of items that need to be removed

                                if n_prov == n_prov_visi then
                                    -- this is the last provider
                                    -- try to remove as much as possible to achieve the move goal
                                    n_item_rema = n_item_to_move - n_item_remo
                                    if n >= n_item_rema then
                                        if n_item_rema then
                                            inventory.remove({ name = signal_name, count = n_item_rema })
                                        end
                                    else
                                        if n > 0 then
                                            inventory.remove({ name = signal_name, count = n })
                                        end
                                    end
                                else
                                    -- Remove all items
                                    if n > 0 then
                                        inventory.remove({ name = signal_name, count = n })
                                    end
                                    n_item_remo = n_item_remo + n
                                    -- and update the number of items that need to be removed from the remaining providers.
                                    n_items_per_prov = math.floor((n_item_to_move - n_item_remo) / (n_prov - n_prov_visi))
                                end
                            end
                        end

                        -- insert items into requesters
                        n_requ_visi = 0
                        n_item_inse = 0
                        for _, k_un in ipairs(keys_requ) do
                            n_requ_visi = n_requ_visi + 1
                            n = inve_requ[k_un]
                            e_cont = requs[tier].container[k_un]
                            inventory = e_cont.get_inventory(defines.inventory.item_main)
                            if n >= n_items_per_requ then
                                -- if enough items can be inserted, insert them
                                if n_items_per_requ > 0 then
                                    inventory.insert({ name = signal_name, count = n_items_per_requ })
                                end
                                n_item_inse = n_item_inse + n_items_per_requ
                            else
                                -- otherwise insert as much as possible and update the remaining
                                -- number of items that need to be inserted

                                if n_requ == n_requ_visi then
                                    -- this is the last requester
                                    -- try to insert as much as possible to achieve the move goal
                                    n_item_rema = n_item_to_move - n_item_inse
                                    if n >= n_item_rema then
                                        if n_item_rema > 0 then
                                            inventory.insert({ name = signal_name, count = n_item_rema })
                                        end
                                    else
                                        if n > 0 then
                                            inventory.insert({ name = signal_name, count = n })
                                        end
                                    end
                                else
                                    -- Fill requester
                                    if n > 0 then
                                        inventory.insert({ name = signal_name, count = n })
                                    end
                                    n_item_inse = n_item_inse + n
                                    -- and update the number of items that need to be inserted into the remaining requesters.
                                    n_items_per_requ = math.floor((n_item_to_move - n_item_inse) / (n_requ - n_requ_visi))
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
-- a stateful iterator for mt_position.__pairs
local _iterator = function(tt, key)
    local kx -- the current x-coordinate
    local v, vv

    kx, v = next(tt.t, tt.kx_prev)
    if v ~= nil and next(v, key.y) == nil then      -- if there are no more y-coordinates for the current x-coordinate, ...
        tt.kx_prev = kx                -- ... then remember the current x-coordinate, ...
        kx, v = next(tt.t, tt.kx_prev) -- ... go to the next x-coordinate, ...
        key.y = nil                    -- ... and start with the first y-coordinate again
    end

    if v == nil then
        return nil
    else
        key.y, vv = next(v, key.y) -- the next y-coordinate
        return { x = kx, y = key.y }, vv
    end
end

local initialize = function(global)
    lamps = global.lamps
    provs = global.provider
    requs = global.requester
    same_net_id = global.same_net_id
    mod_state = global.mod_state

    -- use a MapPosition as index
    local mt = {
        __index = function(table, key)
            if rawget(table, key.x) then
                return rawget(table, key.x)[key.y]
            else
                return nil
            end
        end,
        __newindex = function(table, key, value)
            rawset(table, key.x, rawget(table, key.x) or {})
            rawget(table, key.x)[key.y] = value
        end,
        __pairs = function(table)
            local tt = { t = table, kx_prev = nil }
            return _iterator, tt, { x = nil, y = nil }
        end
    }

    for tier = 1, tiers do
        setmetatable(lamps[tier], mt)
        setmetatable(provs[tier].pos, mt)
        setmetatable(requs[tier].pos, mt)
    end

    for tier = 1, tiers do
        net_id_update_scheduled[tier] = true
    end
end

---------------------------------------------------------------------------
lib = {
    command_debug_lamp = command_debug_lamp,
    command_debug_print = command_debug_print,
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
    tiers = tiers
}
