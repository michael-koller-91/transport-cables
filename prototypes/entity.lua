require("util")

local prefix = "transport-cables:"
local tiers = 3
local debug_mode = true

local inventory_size = { provider = {}, requester_container = {} }
inventory_size.provider[1] = 16
inventory_size.provider[2] = 32
inventory_size.provider[3] = 64
inventory_size.requester_container[1] = 16
inventory_size.requester_container[2] = 32
inventory_size.requester_container[3] = 64

local max_distance = {}
max_distance[1] = 5
max_distance[2] = 7
max_distance[3] = 9

local mining_time = { cable = {}, node = {}, provider = {}, requester = {}, underground_cable = {} }
mining_time.cable[1] = 0.01
mining_time.cable[2] = 0.01
mining_time.cable[3] = 0.01
mining_time.node[1] = 0.01
mining_time.node[2] = 0.01
mining_time.node[3] = 0.01
mining_time.provider[1] = 0.01
mining_time.provider[2] = 0.01
mining_time.provider[3] = 0.01
mining_time.requester[1] = 0.01
mining_time.requester[2] = 0.01
mining_time.requester[3] = 0.01
mining_time.underground_cable[1] = 0.01
mining_time.underground_cable[2] = 0.01
mining_time.underground_cable[3] = 0.01

local speed = 1e-8                     -- this makes the belt speed tooltip say 0.0 items / s
local animation_speed_coefficient = {} -- cable animation speed (depends on `speed`)
animation_speed_coefficient[1] = 4e7
animation_speed_coefficient[2] = 8e7
animation_speed_coefficient[3] = 12e7

--
-- helper functions
--

---------------------------------------------------------------------------
local get_belt_animation_set = function(tier)
    return {
        animation_set = {
            filename = "__transport-cables__/sprites/entities/lr-cable-t" .. tostring(tier) .. ".png",
            priority = "extra-high",
            width = 64,
            height = 64,
            frame_count = 16,
            direction_count = 20,
            hr_version = {
                filename = "__transport-cables__/sprites/entities/hr-cable-t" .. tostring(tier) .. ".png",
                priority = "extra-high",
                width = 128,
                height = 128,
                scale = 0.5,
                frame_count = 16,
                direction_count = 20,
            }
        }
    }
end

---------------------------------------------------------------------------
local get_belt_frame_connector_template_frame_main = function(tier)
    return {
        sheet =
        {
            filename = "__transport-cables__/sprites/entities/hr-cable-circuit-frame-main-t" .. tostring(tier) .. ".png",
            frame_count = 4,
            height = 94,
            line_length = 4,
            priority = "low",
            scale = 0.5,
            shift = util.by_pixel(3.5, -5),
            variation_count = 7,
            width = 80
        }
    }
end
local get_belt_frame_connector_template_back_patch = function(tier)
    return {
        sheet =
        {
            filename = "__transport-cables__/sprites/entities/hr-cable-circuit-patch-back-t" .. tostring(tier) .. ".png",
            frame_count = 1,
            height = 72,
            line_length = 3,
            priority = "low",
            scale = 0.5,
            shift = util.by_pixel(0, -2),
            variation_count = 3,
            width = 66
        }
    }
end
local get_belt_frame_connector_template_frame_shadow = function(tier)
    return
    {
        sheet =
        {
            draw_as_shadow = true,
            filename = "__transport-cables__/sprites/entities/hr-cable-circuit-frame-main-t" ..
                tostring(tier) .. "-shadow.png",
            frame_count = 4,
            height = 112,
            line_length = 4,
            priority = "low",
            scale = 0.5,
            shift = util.by_pixel(2, 3),
            variation_count = 7,
            width = 160
        }
    }
end
local get_belt_frame_connector_template_frame_main_scanner = function(tier)
    return util.draw_as_glow
        {
            filename = "__transport-cables__/sprites/entities/hr-cable-circuit-frame-main-scanner-t" .. tostring(tier) .. ".png",
            frame_count = 8,
            height = 64,
            line_length = 8,
            priority = "low",
            scale = 0.5,
            shift = util.by_pixel(0, 0.5),
            width = 22
        }
end
local get_transport_belt_connector_frame_sprites = function(tier)
    return {
        frame_main = get_belt_frame_connector_template_frame_main(tier),
        frame_shadow = get_belt_frame_connector_template_frame_shadow(tier),
        frame_back_patch = get_belt_frame_connector_template_back_patch(tier),
        frame_main_scanner = get_belt_frame_connector_template_frame_main_scanner(tier),

        -- this is from __core__/lualib/circuit-connector-generated-definitions.lua
        -- local belt_ccm = ...
        frame_main_scanner_movement_speed = 0.032258064516129,

        frame_main_scanner_horizontal_start_shift = { -0.25, -0.125 + 1 / 32 },
        frame_main_scanner_horizontal_end_shift = { 0.25, -0.125 + 1 / 32 },
        frame_main_scanner_horizontal_y_scale = 0.70,
        frame_main_scanner_horizontal_rotation = 0,

        frame_main_scanner_vertical_start_shift = { 0, -0.3125 },
        frame_main_scanner_vertical_end_shift = { 0, 0.1875 },
        frame_main_scanner_vertical_y_scale = 0.75,
        frame_main_scanner_vertical_rotation = 0.25,

        frame_main_scanner_cross_horizontal_start_shift = { -0.3125, -0.0625 },
        frame_main_scanner_cross_horizontal_end_shift = { 0.3125, -0.0625 },
        frame_main_scanner_cross_horizontal_y_scale = 0.60,
        frame_main_scanner_cross_horizontal_rotation = 0,

        frame_main_scanner_cross_vertical_start_shift = { 0, -0.3125 },
        frame_main_scanner_cross_vertical_end_shift = { 0, 0.1875 },
        frame_main_scanner_cross_vertical_y_scale = 0.75,
        frame_main_scanner_cross_vertical_rotation = 0.25,

        frame_main_scanner_nw_ne =
        {
            filename =
            "__base__/graphics/entity/transport-belt/connector/transport-belt-connector-frame-main-scanner-nw-ne.png",
            priority = "low",
            blend_mode = "additive",
            draw_as_glow = true,
            line_length = 8,
            width = 28,
            height = 24,
            frame_count = 32,
            shift = { -0.03125, -0.0625 }
        },
        frame_main_scanner_sw_se =
        {
            filename =
            "__base__/graphics/entity/transport-belt/connector/transport-belt-connector-frame-main-scanner-sw-se.png",
            priority = "low",
            blend_mode = "additive",
            draw_as_glow = true,
            line_length = 8,
            width = 29,
            height = 28,
            frame_count = 32,
            shift = { 0.015625, -0.09375 }
        }
    }
end

for tier = 1, tiers do
    --
    -- cable
    --
    local entity_name = prefix .. "cable-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["transport-belt"]["transport-belt"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.cable[tier],
        result = entity_name
    }
    entity.speed = speed
    entity.animation_speed_coefficient = animation_speed_coefficient[tier]
    entity.related_underground_belt = prefix .. "underground-cable-t" .. tostring(tier)
    entity.belt_animation_set = get_belt_animation_set(tier)
    entity.connector_frame_sprites = get_transport_belt_connector_frame_sprites(tier)
    entity.operable = false

    data:extend({ entity })

    --
    -- node
    --
    local entity_name = prefix .. "node-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["lamp"]["small-lamp"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.node[tier],
        result = entity_name
    }
    entity.energy_source = { type = "void" }
    entity.picture_off = {
        layers = {
            {
                filename = "__transport-cables__/sprites/entities/lr-node-t" .. tostring(tier) .. ".png",
                priority = "high",
                width = 64,
                height = 64,
                frame_count = 1,
                axially_symmetrical = false,
                direction_count = 1,
                shift = util.by_pixel(0, 0),
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-node-t" .. tostring(tier) .. ".png",
                    priority = "high",
                    width = 64,
                    height = 64,
                    frame_count = 1,
                    axially_symmetrical = false,
                    direction_count = 1,
                    shift = util.by_pixel(0, 0),
                    scale = 0.5
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-node-t" .. tostring(tier) .. "-shadow.png",
                priority = "high",
                width = 32,
                height = 32,
                frame_count = 1,
                axially_symmetrical = false,
                direction_count = 1,
                shift = util.by_pixel(4, 5),
                draw_as_shadow = true,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-node-t" .. tostring(tier) .. "-shadow.png",
                    priority = "high",
                    width = 76,
                    height = 47,
                    frame_count = 1,
                    axially_symmetrical = false,
                    direction_count = 1,
                    shift = util.by_pixel(4, 4.75),
                    draw_as_shadow = true,
                    scale = 0.5
                }
            }
        }
    }

    data:extend({ entity })

    --
    -- provider
    --
    local entity_name = prefix .. "provider-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["container"]["iron-chest"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.provider[tier],
        result = entity_name
    }
    entity.inventory_size = inventory_size.provider[tier]
    entity.picture = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-provider-t" .. tostring(tier) .. ".png",
                priority = "extra-high",
                width = 64,
                height = 64,
                shift = util.by_pixel(0, -0.5),
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-provider-t" .. tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    shift = util.by_pixel(0, 0),
                    scale = 0.5
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-provider-t" .. tostring(tier) .. "-shadow.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-provider-t" .. tostring(tier) .. "-shadow.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    shift = util.by_pixel(0, 0),
                    draw_as_shadow = true,
                    scale = 0.5
                }
            }
        }
    }

    data:extend({ entity })

    --
    -- requester
    --
    local entity_name = prefix .. "requester-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.requester[tier],
        result = entity_name
    }
    entity.circuit_wire_max_distance = 1
    entity.item_slot_count = 1
    entity.sprites = { north = {}, east = {}, south = {}, west = {} }
    entity.sprites.north = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-with-container-north-t" ..
                    tostring(tier) .. ".png",
                width = 64,
                height = 128,
                frame_count = 1,
                shift = util.by_pixel(0, -16),
                hr_version =
                {
                    scale = 0.5,
                    filename = "__transport-cables__/sprites/entities/hr-requester-with-container-north-t" ..
                        tostring(tier) .. ".png",
                    width = 64,
                    height = 128,
                    frame_count = 1,
                    shift = util.by_pixel(0, -16)
                }
            }
        }
    }
    entity.sprites.south = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-with-container-south-t" ..
                    tostring(tier) .. ".png",
                width = 64,
                height = 128,
                frame_count = 1,
                shift = util.by_pixel(0, 16),
                hr_version =
                {
                    scale = 0.5,
                    filename = "__transport-cables__/sprites/entities/hr-requester-with-container-south-t" ..
                        tostring(tier) .. ".png",
                    width = 64,
                    height = 128,
                    frame_count = 1,
                    shift = util.by_pixel(0, 16)
                }
            }
        }
    }
    entity.sprites.east = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-with-container-east-t" ..
                    tostring(tier) .. ".png",
                width = 128,
                height = 64,
                frame_count = 1,
                shift = util.by_pixel(16, 0),
                hr_version =
                {
                    scale = 0.5,
                    filename = "__transport-cables__/sprites/entities/hr-requester-with-container-east-t" ..
                        tostring(tier) .. ".png",
                    width = 128,
                    height = 64,
                    frame_count = 1,
                    shift = util.by_pixel(16, 0)
                }
            }
        }
    }
    entity.sprites.west = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-with-container-west-t" ..
                    tostring(tier) .. ".png",
                width = 128,
                height = 64,
                frame_count = 1,
                shift = util.by_pixel(-16, 0),
                hr_version =
                {
                    scale = 0.5,
                    filename = "__transport-cables__/sprites/entities/hr-requester-with-container-west-t" ..
                        tostring(tier) .. ".png",
                    width = 128,
                    height = 64,
                    frame_count = 1,
                    shift = util.by_pixel(-16, 0)
                }
            }
        }
    }

    data:extend({ entity })

    --
    -- requester container
    --
    local entity_name = prefix .. "requester-container-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["container"]["iron-chest"])
    entity.name = entity_name
    entity.minable = nil
    entity.inventory_size = inventory_size.requester_container[tier]
    entity.destructible = false
    entity.picture = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-empty-t" .. tostring(tier) .. ".png",
                priority = "extra-high",
                width = 8,
                height = 8,
                shift = util.by_pixel(0, 0),
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-empty-t" .. tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 8,
                    height = 8,
                    shift = util.by_pixel(0, 0),
                    scale = 0.5
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-empty-t" ..
                    tostring(tier) .. "-shadow.png",
                priority = "extra-high",
                width = 8,
                height = 8,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-empty-t" .. tostring(tier) .. "-shadow.png",
                    priority = "extra-high",
                    width = 8,
                    height = 8,
                    shift = util.by_pixel(0, 0),
                    draw_as_shadow = true,
                    scale = 0.5
                }
            }
        }
    }

    data:extend({ entity })

    --
    -- underground cable
    --
    local entity_name = prefix .. "underground-cable-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["underground-belt"]["underground-belt"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.underground_cable[tier],
        result = entity_name
    }
    entity.speed = speed
    entity.animation_speed_coefficient = animation_speed_coefficient[tier]
    entity.belt_animation_set = get_belt_animation_set(1)
    entity.max_distance = max_distance[tier]
    entity.structure = {
        direction_in = {
            sheet = {
                filename = "__transport-cables__/sprites/entities/lr-underground-cable-structure-t" ..
                    tostring(tier) .. ".png",
                priority = "extra-high",
                width = 96,
                height = 96,
                y = 96,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-underground-cable-structure-t" ..
                        tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 192,
                    height = 192,
                    y = 192,
                    scale = 0.5
                }
            }
        },
        direction_out = {
            sheet = {
                filename = "__transport-cables__/sprites/entities/lr-underground-cable-structure-t" ..
                    tostring(tier) .. ".png",
                priority = "extra-high",
                width = 96,
                height = 96,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-underground-cable-structure-t" ..
                        tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 192,
                    height = 192,
                    scale = 0.5
                }
            }
        },
        direction_in_side_loading = {
            sheet = {
                filename = "__transport-cables__/sprites/entities/lr-underground-cable-structure-t" ..
                    tostring(tier) .. ".png",
                priority = "extra-high",
                width = 96,
                height = 96,
                y = 96 * 3,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-underground-cable-structure-t" ..
                        tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 192,
                    height = 192,
                    y = 192 * 3,
                    scale = 0.5
                }
            }
        },
        direction_out_side_loading = {
            sheet = {
                filename = "__transport-cables__/sprites/entities/lr-underground-cable-structure-t" ..
                    tostring(tier) .. ".png",
                priority = "extra-high",
                width = 96,
                height = 96,
                y = 96 * 2,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-underground-cable-structure-t" ..
                        tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 192,
                    height = 192,
                    y = 192 * 2,
                    scale = 0.5
                }
            }
        },
        back_patch = {
            sheet = {
                filename = "__transport-cables__/sprites/entities/lr-underground-cable-back-patch-t" ..
                    tostring(tier) .. ".png",
                priority = "extra-high",
                width = 96,
                height = 96,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-underground-cable-back-patch-t" ..
                        tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 192,
                    height = 192,
                    scale = 0.5
                }
            }
        },
        front_patch = {
            sheet = {
                filename = "__transport-cables__/sprites/entities/lr-underground-cable-front-patch-t" ..
                    tostring(tier) .. ".png",
                priority = "extra-high",
                width = 96,
                height = 96,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-underground-cable-front-patch-t" ..
                        tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 192,
                    height = 192,
                    scale = 0.5
                }
            }
        }
    }

    data:extend({ entity })

    --
    -- helper entity
    --
    ---------------------------------------------------------------------------
    local entity_name = prefix .. "lamp-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["lamp"]["small-lamp"])
    entity.name = entity_name
    entity.destructible = false
    entity.minable = nil
    entity.operable = false
    entity.energy_source = { type = "void" }
    if debug_mode then
        entity.selection_box = { { 0.0, 0.0 }, { 2.0, 2.0 } }
    else
        entity.selection_box = { { 0.0, 0.0 }, { 0.0, 0.0 } }
    end
    entity.picture_off =
    {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-lamp-off-t" .. tostring(tier) .. ".png",
                priority = "high",
                width = 8,
                height = 8,
                frame_count = 1,
                axially_symmetrical = false,
                direction_count = 1,
                shift = util.by_pixel(0, 0),
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-lamp-off-t" .. tostring(tier) .. ".png",
                    priority = "high",
                    width = 8,
                    height = 8,
                    frame_count = 1,
                    axially_symmetrical = false,
                    direction_count = 1,
                    shift = util.by_pixel(0, 0),
                    scale = 0.5
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-lamp-off-t" .. tostring(tier) .. "-shadow.png",
                priority = "high",
                width = 8,
                height = 8,
                frame_count = 1,
                axially_symmetrical = false,
                direction_count = 1,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-lamp-off-t" .. tostring(tier) .. "-shadow.png",
                    priority = "high",
                    width = 8,
                    height = 8,
                    frame_count = 1,
                    axially_symmetrical = false,
                    direction_count = 1,
                    shift = util.by_pixel(0, 0),
                    draw_as_shadow = true,
                    scale = 0.5
                }
            }
        }
    }

    data:extend({ entity })
end
