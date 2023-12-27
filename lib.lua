require("util")

---------------------------------------------------------------------------
local wire = defines.wire_type.red
local rate = {}
local rate_increment = 15

local net_id_update_scheduled = false
local item_transport_active = false

local provs = {} -- all providers
local requs = {} -- all requesters
local same_net_id = {}

local prefix = "transport-cables:"
local names = {
    lamp = prefix .. "lamp",
    node = prefix .. "node-t1",
    provider = prefix .. "provider-t1",
    requester_container = prefix .. "requester-container-t1",
    requester = prefix .. "requester-t1",
    cable = prefix .. "cable-t1",
    underground_cable = prefix .. "underground-cable-t1",
}

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
local update_requester_signals = function()
    for unit_number, entity in pairs(requs.un) do
        requs.signal[unit_number] = entity.get_control_behavior().get_signal(1)
    end
end

---------------------------------------------------------------------------
-- All requesters with the same network_id as `entity` get the signal of
-- `entity`.
local set_requester_signals_in_same_network_as = function(entity)
    local net_id = requs.net_id[entity.unit_number]

    if net_id > 0 then
        local unit_number_array = requs.net_id_and_un[net_id]
        if unit_number_array then
            local signal = entity.get_control_behavior().get_signal(1)
            for _, unit_number in ipairs(requs.net_id_and_un[net_id]) do
                if signal.signal then
                    requs.un[unit_number].get_control_behavior().set_signal(1, signal)
                else
                    requs.un[unit_number].get_control_behavior().set_signal(1, nil)
                end
            end
        end
        update_requester_signals()
    end
end

---------------------------------------------------------------------------
-- Store network_id of all providers and requesters. Also, find providers and
-- requesters with the same network_id.
local update_net_id = function()
    local circuit_network
    local net_id
    same_net_id = {}
    provs.net_id_and_un = {}
    requs.net_id_and_un = {}

    -- store network_id of all providers
    for unit_number, entity in pairs(provs.un) do
        circuit_network = entity.get_circuit_network(wire)
        if circuit_network then
            net_id = circuit_network.network_id

            provs.net_id[unit_number] = net_id
            rendering.set_text(provs.text_id[unit_number], "ID: " .. tostring(net_id))

            -- collect all providers with the same network_id
            provs.net_id_and_un[net_id] = provs.net_id_and_un[net_id] or {}
            table.insert(provs.net_id_and_un[net_id], unit_number)
        end
    end

    -- store network_id of all requesters
    for unit_number, entity in pairs(requs.un) do
        circuit_network = entity.get_circuit_network(wire)
        if circuit_network then
            net_id = circuit_network.network_id

            requs.net_id[unit_number] = net_id
            rendering.set_text(requs.text_id[unit_number], "ID: " .. tostring(net_id))

            -- collect all requesters with the same network_id
            requs.net_id_and_un[net_id] = requs.net_id_and_un[net_id] or {}
            table.insert(requs.net_id_and_un[net_id], unit_number)
        end
    end

    -- find providers and requesters with the same network_id
    item_transport_active = false
    for net_id, _ in pairs(requs.net_id_and_un) do
        if provs.net_id_and_un[net_id] then
            table.insert(same_net_id, net_id)
            item_transport_active = true
        end
    end
end

---------------------------------------------------------------------------
local on_built_entity = function(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == names.provider then
        provs.un[entity.unit_number] = entity
        provs.pos[entity.position] = entity

        -- default ID
        provs.net_id[entity.unit_number] = -1

        -- display ID
        provs.text_id[entity.unit_number] = rendering.draw_text {
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
            entity_cable = game.surfaces[1].find_entity(names.cable, position)
            if entity_cable then
                if entity_cable.direction == direction then
                    entity.connect_neighbour {
                        wire = wire,
                        target_entity = entity_cable
                    }
                end
            end
        end

        net_id_update_scheduled = true
    elseif entity.name == names.requester then
        requs.un[entity.unit_number] = entity
        requs.pos[entity.position] = entity

        -- in addition, place a container
        local position = moveposition(entity.position, entity.direction)
        requs.container[entity.unit_number] = game.surfaces[1].create_entity {
            name = names.requester_container,
            position = position,
            force = "player"
        }

        -- default ID
        requs.net_id[entity.unit_number] = -1

        -- display ID
        requs.text_id[entity.unit_number] = rendering.draw_text {
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
            entity_cable = game.surfaces[1].find_entity(names.cable, position)
            if entity_cable then
                if entity_cable.direction == util.oppositedirection(direction) then
                    entity.connect_neighbour {
                        wire = wire,
                        target_entity = entity_cable
                    }
                end
            end
        end

        update_requester_signals()

        net_id_update_scheduled = true
    elseif entity.name == names.node then
        -- connect to neighboring cables if they are facing towards or away
        -- from the node
        local position
        local direction
        local entity_cable
        for i = 0, 8, 2 do
            -- rotate direction by i / 2 * 90°
            direction = (entity.direction + i) % 8
            position = moveposition(entity.position, direction, 1)
            entity_cable = game.surfaces[1].find_entity(names.cable, position)
            if entity_cable then
                if (entity_cable.direction == direction) or (entity_cable.direction == util.oppositedirection(direction)) then
                    entity.connect_neighbour {
                        wire = wire,
                        target_entity = entity_cable
                    }
                end
            end
        end

        net_id_update_scheduled = true
    elseif entity.name == names.cable then
        -- connect to neighboring cables
        for _, val in pairs(entity.belt_neighbours) do
            for _, neighbor in ipairs(val) do
                -- if the neighbor is an underground_cable, connect to the corresponding lamp
                if neighbor.name == names.underground_cable then
                    local lamp = game.surfaces[1].find_entity(names.lamp, neighbor.position)
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
        if requs.pos[position] then
            entity.connect_neighbour {
                wire = wire,
                target_entity = requs.pos[position]
            }
        end

        -- connect to provider south of cable
        position = moveposition(entity.position, entity.direction, -1)
        if provs.pos[position] then
            entity.connect_neighbour {
                wire = wire,
                target_entity = provs.pos[position]
            }
        end

        -- connect to node north of cable
        position = moveposition(entity.position, entity.direction, 1)
        local entity_node = game.surfaces[1].find_entity(names.node, position)
        if entity_node then
            entity.connect_neighbour {
                wire = wire,
                target_entity = entity_node
            }
        end

        -- connect to node south of cable
        position = moveposition(entity.position, entity.direction, -1)
        entity_node = game.surfaces[1].find_entity(names.node, position)
        if entity_node then
            entity.connect_neighbour {
                wire = wire,
                target_entity = entity_node
            }
        end

        net_id_update_scheduled = true
    elseif entity.name == names.underground_cable then
        -- also place a lamp
        local lamp = game.surfaces[1].create_entity {
            name = names.lamp,
            position = entity.position,
            force = 'player'
        }

        -- connect to neighboring underground_cable's lamp
        if entity.neighbours then
            local lamp_neighbor = game.surfaces[1].find_entity(names.lamp, entity.neighbours.position)
            lamp.connect_neighbour {
                wire = wire,
                target_entity = lamp_neighbor
            }
        end

        -- connect to cable north of underground_cable if it is not facing towards
        -- the underground_cable
        local position = moveposition(entity.position, entity.direction, 1)
        local entity_cable = game.surfaces[1].find_entity(names.cable, position)
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
        entity_cable = game.surfaces[1].find_entity(names.cable, position)
        if entity_cable then
            if entity_cable.direction == entity.direction then
                lamp.connect_neighbour {
                    wire = wire,
                    target_entity = entity_cable
                }
            end
        end

        net_id_update_scheduled = true
    end
end

---------------------------------------------------------------------------
local on_built_filter = {
    {
        filter = "name",
        name = names.node
    },
    {
        filter = "name",
        name = names.provider
    },
    {
        filter = "name",
        name = names.requester
    },
    {
        filter = "name",
        name = names.cable
    },
    {
        filter = "name",
        name = names.underground_cable
    }
}

---------------------------------------------------------------------------
local on_entity_settings_pasted = function(event)
    if event.source.name == names.requester and event.destination.name == names.requester then
        set_requester_signals_in_same_network_as(event.destination)
    end
end

---------------------------------------------------------------------------
local on_gui_closed = function(event)
    if event.entity and event.entity.valid then
        if event.entity.name == names.requester then
            set_requester_signals_in_same_network_as(event.entity)
        end
    end
end

---------------------------------------------------------------------------
local on_mined_entity = function(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == names.provider then
        provs.un[entity.unit_number] = nil
        provs.pos[entity.position] = nil

        -- also destroy the displayed text
        rendering.destroy(provs.text_id[entity.unit_number])
        provs.text_id[entity.unit_number] = nil

        -- and the ID
        provs.net_id[entity.unit_number] = nil

        net_id_update_scheduled = true
    elseif entity.name == names.node then
        net_id_update_scheduled = true
    elseif entity.name == names.requester then
        requs.un[entity.unit_number] = nil
        requs.pos[entity.position] = nil

        -- also destroy the container
        requs.container[entity.unit_number].destroy()
        requs.container[entity.unit_number] = nil

        -- and the displayed text
        rendering.destroy(requs.text_id[entity.unit_number])
        requs.text_id[entity.unit_number] = nil

        -- and the ID
        requs.net_id[entity.unit_number] = nil

        -- and the signal
        requs.signal[entity.unit_number] = nil

        net_id_update_scheduled = true
    elseif entity.name == names.cable then
        net_id_update_scheduled = true
    elseif entity.name == names.underground_cable then
        -- destroy the associated lamp
        game.surfaces[1].find_entity(names.lamp, entity.position).destroy()

        net_id_update_scheduled = true
    end

    -- Note:
    -- After `entity` is destroyed, the circuit network is updated. At this
    -- point, we want to call update_net_id. That's why the update is only
    -- scheduled here.
end

---------------------------------------------------------------------------
local on_mined_filter = {
    {
        filter = "name",
        name = names.node
    },
    {
        filter = "name",
        name = names.provider
    },
    {
        filter = "name",
        name = names.requester
    },
    {
        filter = "name",
        name = names.cable
    },
    {
        filter = "name",
        name = names.underground_cable
    }
}

local on_player_created = function(event)
    local player = game.players[event.player_index]

    if rate.t1 == 0 then
        player.gui.top.add { type = "label", name = "t1", caption = "" }
    else
        player.gui.top.add { type = "label", name = "t1", caption = "Tier 1: " .. tostring(rate.t1) .. " items / s." }
    end
    if rate.t2 == 0 then
        player.gui.top.add { type = "label", name = "t2", caption = "" }
    else
        player.gui.top.add { type = "label", name = "t2", caption = "Tier 2: " .. tostring(rate.t2) .. " items / s." }
    end
    if rate.t3 == 0 then
        player.gui.top.add { type = "label", name = "t3", caption = "" }
    else
        player.gui.top.add { type = "label", name = "t3", caption = "Tier 3: " .. tostring(rate.t3) .. " items / s." }
    end
end

local on_research_finished = function(event)
    local research = event.research

    if research.name == prefix .. "t1" or research.name == prefix .. "t1-speed" then
        rate.t1 = rate.t1 + rate_increment
    end
    if research.name == prefix .. "t2" or research.name == prefix .. "t2-speed" then
        rate.t2 = rate.t2 + rate_increment
    end
    if research.name == prefix .. "t3" or research.name == prefix .. "t3-speed" then
        rate.t3 = rate.t3 + rate_increment
    end

    for _, player in pairs(game.players) do
        if research.name == prefix .. "t1" or research.name == prefix .. "t1-speed" then
            player.gui.top["t1"].caption = "Tier 1: " .. tostring(rate.t1) .. " items / s."
        end
        if research.name == prefix .. "t2" or research.name == prefix .. "t2-speed" then
            player.gui.top["t2"].caption = "Tier 2: " .. tostring(rate.t2) .. " items / s."
        end
        if research.name == prefix .. "t3" or research.name == prefix .. "t3-speed" then
            player.gui.top["t3"].caption = "Tier 3: " .. tostring(rate.t3) .. " items / s."
        end
    end
end

---------------------------------------------------------------------------
local on_rotated_entity = function(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == names.requester then
        -- move the container in front of the requester again
        local e_cont = requs.container[entity.unit_number]
        local position = moveposition(entity.position, entity.direction)
        e_cont.teleport(position)
    end
end

local keys_sorted_by_value = function(t)
    local keys = {}
    for key in pairs(t) do
        table.insert(keys, key)
    end

    table.sort(keys)

    return keys
end

local on_tick = function(event)
    if net_id_update_scheduled then
        net_id_update_scheduled = false
        update_net_id()
    end
end

local count
local e_cont
local e_prov
-- local entity_requester
local inve_prov
local inve_requ
local inventory
local keys_prov
local keys_requ
local n_empty_inve_requ
local n
local n_inve_prov
local n_items_per_prov
local n_items_per_requ
local n_item_inse    -- The number of items that has already been inserted into requesters.
local n_item_remo    -- The number of items that has already been removed from providers.
local n_item_rema    -- The number of items that still needs to be removed from providers.
local n_item_to_move -- The number of items that needs to be moved in this network.
local n_prov
local n_prov_visi    -- The number of providers from which items have already been removed.
local n_requ
local n_requ_visi    -- The number of requesters into which items have already been inserted.
local provider_un_array
local requester_un_array
local signal_name
local signal
-- local stack_size
local unit_number
local on_nth_tick = function(event)
    if not item_transport_active then
        return
    end

    -- move items between provider-requester-pairs
    for _, net_id in ipairs(same_net_id) do
        -- all provider unit numbers with this network_id
        provider_un_array = provs.net_id_and_un[net_id]
        n_prov = #provider_un_array

        -- all requester unit numbers with this network_id
        requester_un_array = requs.net_id_and_un[net_id]
        n_requ = #requester_un_array

        -- the signal of all requesters with this network_id
        unit_number = requester_un_array[1]
        signal = requs.signal[unit_number]

        if signal and signal.signal then
            signal_name = signal.signal.name

            -- count items in providers' inventories
            n_inve_prov = 0
            inve_prov = {}
            for _, un in ipairs(provider_un_array) do
                e_prov = provs.un[un]
                count = e_prov.get_inventory(defines.inventory.item_main).get_item_count(signal_name)
                inve_prov[un] = count
                n_inve_prov = n_inve_prov + count
            end
            keys_prov = keys_sorted_by_value(inve_prov)

            -- count how many items fit in requesters' inventories
            n_empty_inve_requ = 0
            inve_requ = {}
            for _, un in ipairs(requester_un_array) do
                e_cont = requs.container[un]
                count = e_cont.get_inventory(defines.inventory.item_main).get_insertable_count(signal_name)
                inve_requ[un] = count
                n_empty_inve_requ = n_empty_inve_requ + count
            end
            keys_requ = keys_sorted_by_value(inve_requ)

            n_item_to_move = math.min(rate.t1, n_inve_prov, n_empty_inve_requ)
            if n_item_to_move > 0 then
                n_items_per_prov = math.floor(n_item_to_move / n_prov)
                n_items_per_requ = math.floor(n_item_to_move / n_requ)

                -- remove items from providers
                n_prov_visi = 0
                n_item_remo = 0
                for _, k_un in ipairs(keys_prov) do
                    n_prov_visi = n_prov_visi + 1
                    n = inve_prov[k_un]
                    e_prov = provs.un[k_un]
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
                    e_cont = requs.container[k_un]
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

---------------------------------------------------------------------------
local initialize = function(global)
    provs = global.provider
    requs = global.requester
    same_net_id = global.same_net_id
    rate = global.mod_state.rate

    -- use a MapPosition as index
    mt_position = {
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
        end
    }

    setmetatable(provs.pos, mt_position)
    setmetatable(requs.pos, mt_position)

    net_id_update_scheduled = true
end

---------------------------------------------------------------------------
lib = {
    initialize = initialize,
    on_built_entity = on_built_entity,
    on_built_filter = on_built_filter,
    on_entity_settings_pasted = on_entity_settings_pasted,
    on_gui_closed = on_gui_closed,
    on_mined_entity = on_mined_entity,
    on_mined_filter = on_mined_filter,
    on_nth_tick = on_nth_tick,
    on_player_created = on_player_created,
    on_research_finished = on_research_finished,
    on_rotated_entity = on_rotated_entity,
    on_tick = on_tick
}
