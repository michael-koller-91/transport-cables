local util = require("util")

local debug_fly = false
local debug_print = false
local wire = defines.wire_type.green

local network = {
    connector_lamp = {},
    provider = {},
    requester = {},
    requester_container = {},
    requester_lamp = {}
}

local lamp_name = 'transport-cables:lamp'
local provider_connector_name = 'transport-cables:provider-connector'
local provider_name = 'transport-cables:provider'
local requester_connector_name = 'transport-cables:requester-connector'
local requester_container_name = 'transport-cables:requester-container'
local requester_name = 'transport-cables:requester'
local splitter_name = 'transport-cables:splitter'
local cable_name = 'transport-cables:cable'
local underground_cable_name = 'transport-cables:underground-cable'

local lib = {}
-- add = function(entity)
--    game.print("adding entity with unit_number = " .. tostring(entity.unit_number))
--    unload_chests.entities[entity.unit_number] = entity
-- end
--
lib.print = function(t, s)
    local entity_string = ""
    for k, v in pairs(t) do
        entity_string = tostring(k) .. ", " .. entity_string
    end
    game.print("All " .. s .. " UNs: " .. entity_string)
end

lib.pos_to_str = function(position)
    return "[" .. position.x .. ", " .. position.y .. "]"
end

--debug_fly = true
--lib.connect_to_lamp = function(entity, position, player)
--    local entity_requester = network.requester.pos[position] connector_lamp[position]
--    if entity_lamp then
--        entity.connect_neighbor {
--            wire = wire,
--            target_entity = entity_lamp
--        }
--        game.print("found lamp")
--        if debug_fly then
--            player.create_local_flying_text {
--                text = "connected " .. entity.name .. " to " .. entity_lamp.name,
--                position = position
--            }
--        end
--    end
--end

lib.moveposition = function(position, direction, distance)
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

debug_fly = true
debug_print = true
lib.on_built_entity = function(event)
    local entity = event.created_entity

    if entity.name == requester_name then
        network.requester.un[entity.unit_number] = entity
        network.requester.pos[entity.position] = entity

        -- in addition, place a lamp
        local position = lib.moveposition(entity.position, entity.direction)
        network.requester_lamp[entity.unit_number] = game.surfaces[1].create_entity {
            name = lamp_name,
            position = position
        }

        -- and also a container
        position = lib.moveposition(entity.position, entity.direction, 2)
        local entity_container = game.surfaces[1].create_entity {
            name = requester_container_name,
            position = position
        }
        network.requester_container[entity.unit_number] = entity_container

        -- possibly connect to connector's lamp
        -- lib.connect_to_lamp(entity, lib.moveposition(entity.position, entity.direction, -1.5),
        -- game.players[event.player_index])

        if debug_print then
            game.print("new requester with UN " .. tostring(entity.unit_number) .. " at position " ..
                lib.pos_to_str(entity.position))
            lib.print(network.requester.un, "requester")
        end
    elseif entity.name == provider_name then
        network.provider.un[entity.unit_number] = entity
        network.provider.pos[entity.position] = entity

        if debug_print then
            game.print("new provider with UN " .. tostring(entity.unit_number) .. " at position " ..
                lib.pos_to_str(entity.position))
            lib.print(network.provider.un, "provider")
        end
    elseif entity.name == cable_name then
        -- connect neighboring cables with circuit wire
        for key, val in pairs(entity.belt_neighbours) do
            for _, neighbor in ipairs(val) do
                -- connect to requester_connector's lamp
                if neighbor.name == requester_connector_name then
                    entity.connect_neighbour {
                        wire = wire,
                        target_entity = network.connector_lamp[neighbor.unit_number]
                    }

                    -- connect to provider_connector's lamp
                elseif neighbor.name == provider_connector_name then
                    entity.connect_neighbour {
                        wire = wire,
                        target_entity = network.connector_lamp[neighbor.unit_number]
                    }

                    -- connect to cable
                else
                    entity.connect_neighbour {
                        wire = wire,
                        target_entity = neighbor
                    }
                end
            end
        end
        local position = lib.moveposition(entity.position, entity.direction, 1)
        if network.requester.pos[position] then
            entity.connect_neighbour {
                wire = wire,
                target_entity = network.requester.pos[position]
            }
        end
        position = lib.moveposition(entity.position, entity.direction, -1)
        if network.provider.pos[position] then
            entity.connect_neighbour {
                wire = wire,
                target_entity = network.provider.pos[position]
            }
        end
    elseif entity.name == requester_connector_name then
        entity.direction = util.oppositedirection(entity.direction)
        entity.rotate()

        local entity_connector_lamp = game.surfaces[1].create_entity {
            name = lamp_name,
            position = entity.position
        }
        network.connector_lamp[entity.unit_number] = entity_connector_lamp

        local player = game.players[event.player_index]

        -- if a requester is in front of the connector
        local position = lib.moveposition(entity.position, entity.direction, 1.5)
        local entity_requestor = network.requester.pos[position]
        if entity_requestor then
            -- connect the connector's lamp to the requester
            entity_requestor.connect_neighbour {
                wire = wire,
                target_entity = entity_connector_lamp
            }
            player.create_local_flying_text {
                text = "connector connected to requester which is at " .. lib.pos_to_str(position),
                position = position
            }
        end
    elseif entity.name == provider_connector_name then
        entity.direction = util.oppositedirection(entity.direction)

        local entity_connector_lamp = game.surfaces[1].create_entity {
            name = lamp_name,
            position = entity.position
        }
        network.connector_lamp[entity.unit_number] = entity_connector_lamp

        local player = game.players[event.player_index]

        -- if a provider is behind the connector
        local position = lib.moveposition(entity.position, entity.direction, -1.5)
        local entity_provider = network.provider.pos[position]
        if entity_provider then
            -- connect the connector's lamp to the provider
            entity_provider.connect_neighbour {
                wire = wire,
                target_entity = entity_connector_lamp
            }
            player.create_local_flying_text {
                text = "connector connected to provider which is at " .. lib.pos_to_str(position),
                position = position
            }
        end
    end
end

lib.on_mined_entity = function(event)
    local entity = event.entity

    if entity.name == requester_name then
        network.requester.un[entity.unit_number] = nil
        network.requester.pos[entity.position] = nil

        -- also destroy the container
        network.requester_container[entity.unit_number].destroy()
        network.requester_container[entity.unit_number] = nil

        -- and the lamp
        network.requester_lamp[entity.unit_number].destroy()
        network.requester_lamp[entity.unit_number] = nil

        if debug_print then
            game.print("removed requester with UN " .. tostring(entity.unit_number))
            lib.print(network.requester.un, "requester")
        end
    elseif entity.name == provider_name then
        network.provider.un[entity.unit_number] = nil
        network.provider.pos[entity.position] = nil

        if debug_print then
            game.print("removed provider with UN " .. tostring(entity.unit_number))
            lib.print(network.provider.un, "provider")
        end
    elseif entity.name == requester_connector_name then
        -- also destroy the lamp
        network.connector_lamp[entity.unit_number].destroy()
        network.connector_lamp[entity.unit_number] = nil
    elseif entity.name == provider_connector_name then
        -- also destroy the lamp
        network.connector_lamp[entity.unit_number].destroy()
        network.connector_lamp[entity.unit_number] = nil
    end
end

lib.on_tick = function(event)
    if event.tick % 600 == 0 then
        game.print("ten seconds have passed, tick = " .. tostring(event.tick))
    end
end

lib.init = function(global)
    network.connector_lamp = global.connector_lamp
    network.provider = global.provider
    network.requester = global.requester
    network.requester_container = global.requester_container
    network.requester_lamp = global.requester_lamp

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

    setmetatable(network.provider.pos, mt_position)
    setmetatable(network.requester.pos, mt_position)
end

script.on_event(defines.events.on_built_entity, lib.on_built_entity, { {
    filter = "name",
    name = provider_name
}, {
    filter = "name",
    name = provider_connector_name
}, {
    filter = "name",
    name = requester_name
}, {
    filter = "name",
    name = requester_connector_name
}, {
    filter = "name",
    name = cable_name
} })

script.on_event(defines.events.on_player_mined_entity, lib.on_mined_entity, { {
    filter = "name",
    name = provider_name
}, {
    filter = "name",
    name = provider_connector_name
}, {
    filter = "name",
    name = requester_name
}, {
    filter = "name",
    name = requester_connector_name
} })

script.on_event(defines.events.on_player_rotated_entity, function(event)
    local entity = event.entity
    if entity.name == requester_name then
        -- move the lamp in front of the requester again
        local entity_lamp = network.requester_lamp[entity.unit_number]
        local position = lib.moveposition(entity.position, entity.direction)
        entity_lamp.teleport(position)

        -- and the container as well
        local entity_container = network.requester_container[entity.unit_number]
        position = lib.moveposition(entity.position, entity.direction, 2)
        entity_container.teleport(position)
    end
end)

script.on_event(defines.events.on_tick, lib.on_tick)

script.on_init(function()
    global.connector_lamp = {}
    --     un = {},
    --     pos = {}
    -- }
    global.provider = {
        un = {},
        pos = {}
    }
    global.requester = {
        un = {},
        pos = {}
    }
    global.requester_container = {}
    global.requester_lamp = {}

    lib.init(global)
end)

script.on_load(function()
    lib.init(global)
end)
