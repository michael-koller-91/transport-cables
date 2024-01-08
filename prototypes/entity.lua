require("util")

local prefix = "transport-cables:"
local tiers = 3
local debug_mode = false

local inventory_size = { transmitter = {}, receiver = {} }
inventory_size.transmitter[1] = 16
inventory_size.transmitter[2] = 32
inventory_size.transmitter[3] = 64
inventory_size.receiver[1] = 16
inventory_size.receiver[2] = 32
inventory_size.receiver[3] = 64

local max_distance = {}
max_distance[1] = 5
max_distance[2] = 7
max_distance[3] = 9

local mining_time = { cable = {}, node = {}, transmitter = {}, receiver = {}, underground_cable = {} }
mining_time.cable[1] = 0.01
mining_time.cable[2] = 0.01
mining_time.cable[3] = 0.01
mining_time.node[1] = 0.01
mining_time.node[2] = 0.01
mining_time.node[3] = 0.01
mining_time.transmitter[1] = 0.01
mining_time.transmitter[2] = 0.01
mining_time.transmitter[3] = 0.01
mining_time.receiver[1] = 0.01
mining_time.receiver[2] = 0.01
mining_time.receiver[3] = 0.01
mining_time.underground_cable[1] = 0.01
mining_time.underground_cable[2] = 0.01
mining_time.underground_cable[3] = 0.01

local speed = 1e-8                     -- this makes the belt speed tooltip say 0.0 items / s
local animation_speed_coefficient = {} -- cable animation speed (depends on `speed`)
animation_speed_coefficient[1] = 4e7
animation_speed_coefficient[2] = 8e7
animation_speed_coefficient[3] = 12e7

-- make sure the lamp reaches at least as far as underground cables
local lamp_circuit_wire_max_distance = 0
for _, v in ipairs(max_distance) do
    if v > lamp_circuit_wire_max_distance then
        lamp_circuit_wire_max_distance = v
    end
end

--
-- helper functions
--
---------------------------------------------------------------------------
local function get_belt_animation_set(tier)
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
local function get_belt_frame_connector_template_frame_main(tier)
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
local function get_belt_frame_connector_template_back_patch(tier)
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
local function get_belt_frame_connector_template_frame_shadow(tier)
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
local function get_belt_frame_connector_template_frame_main_scanner(tier)
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
local function get_transport_belt_connector_frame_sprites(tier)
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
    local entity = table.deepcopy(data.raw["transport-belt"]["express-transport-belt"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.cable[tier],
        result = entity_name
    }
    entity.speed = speed
    entity.animation_speed_coefficient = animation_speed_coefficient[tier]
    entity.fast_replaceable_group = "transport-cables"
    entity.related_underground_belt = prefix .. "underground-cable-t" .. tostring(tier)
    if tier < tiers then
        entity.next_upgrade = prefix .. "cable-t" .. tostring(tier + 1)
    end
    entity.icon = "__transport-cables__/sprites/icons/cable-t" .. tostring(tier) .. ".png"
    entity.icon_size = 64
    entity.icon_mipmaps = 4
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
    entity.circuit_wire_max_distance = lamp_circuit_wire_max_distance + 1
    entity.rotatable = false
    entity.fast_replaceable_group = "transport-cables"
    if tier < tiers then
        entity.next_upgrade = prefix .. "node-t" .. tostring(tier + 1)
    end
    entity.collision_box = { { -0.10, -0.10 }, { 0.10, 0.10 } }
    entity.icon = "__transport-cables__/sprites/icons/node-t" .. tostring(tier) .. ".png"
    entity.icon_size = 64
    entity.icon_mipmaps = 4
    entity.picture_off = {
        layers = {
            {
                filename = "__transport-cables__/sprites/entities/lr-node-t" .. tostring(tier) .. ".png",
                priority = "high",
                width = 32,
                height = 32,
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
                width = 16,
                height = 16,
                frame_count = 1,
                axially_symmetrical = false,
                direction_count = 1,
                shift = util.by_pixel(4, 5),
                draw_as_shadow = true,
                hr_version = {
                    filename = "__transport-cables__/sprites/entities/hr-node-t" .. tostring(tier) .. "-shadow.png",
                    priority = "high",
                    width = 32,
                    height = 32,
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
    entity.picture_on = table.deepcopy(entity.picture_off)

    data:extend({ entity })

    --
    -- receiver
    --
    local entity_name = prefix .. "receiver-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["container"]["iron-chest"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.receiver[tier],
        result = entity_name
    }
    entity.name = entity_name
    entity.inventory_size = inventory_size.receiver[tier]
    entity.rotatable = false
    entity.fast_replaceable_group = "transport-cables"
    if tier < tiers then
        entity.next_upgrade = prefix .. "receiver-t" .. tostring(tier + 1)
    end
    entity.icon = "__transport-cables__/sprites/icons/receiver-t" .. tostring(tier) .. ".png"
    entity.icon_size = 64
    entity.icon_mipmaps = 4
    entity.picture =
    {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-receiver-t" .. tostring(tier) .. ".png",
                priority = "extra-high",
                width = 32,
                height = 32,
                shift = util.by_pixel(0, 0),
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-receiver-t" .. tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    shift = util.by_pixel(0, 0),
                    scale = 0.5
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-receiver-t" .. tostring(tier) .. "-shadow.png",
                priority = "extra-high",
                width = 32,
                height = 32,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-receiver-t" .. tostring(tier) .. "-shadow.png",
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
    -- transmitter
    --
    local entity_name = prefix .. "transmitter-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["container"]["iron-chest"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.transmitter[tier],
        result = entity_name
    }
    entity.inventory_size = inventory_size.transmitter[tier]
    entity.rotatable = false
    entity.fast_replaceable_group = "transport-cables"
    if tier < tiers then
        entity.next_upgrade = prefix .. "transmitter-t" .. tostring(tier + 1)
    end
    entity.icon = "__transport-cables__/sprites/icons/transmitter-t" .. tostring(tier) .. ".png"
    entity.icon_size = 64
    entity.icon_mipmaps = 4
    entity.picture = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-transmitter-t" .. tostring(tier) .. ".png",
                priority = "extra-high",
                width = 32,
                height = 32,
                shift = util.by_pixel(0, -0.5),
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-transmitter-t" .. tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    shift = util.by_pixel(0, 0),
                    scale = 0.5
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-transmitter-t" .. tostring(tier) .. "-shadow.png",
                priority = "extra-high",
                width = 32,
                height = 32,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-transmitter-t" ..
                        tostring(tier) .. "-shadow.png",
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
    -- underground cable
    --
    local entity_name = prefix .. "underground-cable-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["underground-belt"]["express-underground-belt"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.underground_cable[tier],
        result = entity_name
    }
    entity.speed = speed
    entity.animation_speed_coefficient = animation_speed_coefficient[tier]
    entity.belt_animation_set = get_belt_animation_set(1)
    entity.max_distance = max_distance[tier]
    entity.fast_replaceable_group = "transport-cables"
    if tier < tiers then
        entity.next_upgrade = prefix .. "underground-cable-t" .. tostring(tier + 1)
    end
    entity.icon = "__transport-cables__/sprites/icons/underground-cable-t" .. tostring(tier) .. ".png"
    entity.icon_size = 64
    entity.icon_mipmaps = 4
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
    entity.fast_replaceable_group = "transport-cables"
    entity.energy_source = { type = "void" }
    entity.picture_off =
    {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-lamp-off-t" .. tostring(tier) .. ".png",
                priority = "high",
                width = 4,
                height = 4,
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
                width = 4,
                height = 4,
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
    entity.circuit_wire_connection_point = nil
    entity.circuit_connector_sprites = nil
    entity.draw_circuit_wires = true
    if debug_mode then
        entity.selection_box = { { 0.0, 0.0 }, { 2.0, 2.0 } }
        entity.always_on = true
        entity.glow_size = 2
        entity.light = { intensity = 0.5, size = 20, color = { r = 1.0, g = 1.0, b = 0.75 } }
    else
        entity.selection_box = { { 0.0, 0.0 }, { 0.0, 0.0 } }
        entity.always_on = false
        entity.picture_on = table.deepcopy(entity.picture_off)
        entity.glow_size = 0
        entity.glow_color_intensity = 0
        entity.light = { intensity = 0.0, size = 0, color = { r = 0.0, g = 0.0, b = 0.0 } }
        entity.darkness_for_all_lamps_off = 0
    end

    data:extend({ entity })
end
