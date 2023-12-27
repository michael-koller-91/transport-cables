require("util")

local prefix = "transport-cables:"
local tiers = 3

local inventory_size = {
    provider = {
        t1 = 16,
        t2 = 32,
        t3 = 64
    },
    requester_container = {
        t1 = 16,
        t2 = 32,
        t3 = 64
    }
}
local mining_time = {
    cable = {
        t1 = 0.01,
        t2 = 0.01,
        t3 = 0.01
    },
    node = {
        t1 = 0.01,
        t2 = 0.01,
        t3 = 0.01
    },
    provider = {
        t1 = 0.01,
        t2 = 0.01,
        t3 = 0.01
    },
    requester = {
        t1 = 0.01,
        t2 = 0.01,
        t3 = 0.01
    },
    underground_cable = {
        t1 = 0.01,
        t2 = 0.01,
        t3 = 0.01
    }
}

--
-- helper functions and parameters
--
local speed = 1e-8                      -- this makes the belt speed tooltip say 0.0 items / s
local animation_speed_coefficient = 5e7 -- cable animation speed

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

---------------------------------------------------------------------------
-- this is from __base__/prototypes/entity/entities.lua
local make_4way_animation_from_spritesheet = function(animation)
    local function make_animation_layer(idx, anim)
        local start_frame = (anim.frame_count or 1) * idx
        local x = 0
        local y = 0
        if anim.line_length then
            y = anim.height * math.floor(start_frame / (anim.line_length or 1))
        else
            x = idx * anim.width
        end
        return
        {
            filename = anim.filename,
            priority = anim.priority or "high",
            flags = anim.flags,
            x = x,
            y = y,
            width = anim.width,
            height = anim.height,
            frame_count = anim.frame_count or 1,
            line_length = anim.line_length,
            repeat_count = anim.repeat_count,
            shift = anim.shift,
            draw_as_shadow = anim.draw_as_shadow,
            draw_as_glow = anim.draw_as_glow,
            draw_as_light = anim.draw_as_light,
            force_hr_shadow = anim.force_hr_shadow,
            apply_runtime_tint = anim.apply_runtime_tint,
            animation_speed = anim.animation_speed,
            scale = anim.scale or 1,
            tint = anim.tint,
            blend_mode = anim.blend_mode,
            load_in_minimal_mode = anim.load_in_minimal_mode,
            premul_alpha = anim.premul_alpha,
            generate_sdf = anim.generate_sdf
        }
    end

    local function make_animation_layer_with_hr_version(idx, anim)
        local anim_parameters = make_animation_layer(idx, anim)
        if anim.hr_version and anim.hr_version.filename then
            anim_parameters.hr_version = make_animation_layer(idx, anim.hr_version)
        end
        return anim_parameters
    end

    local function make_animation(idx)
        if animation.layers then
            local tab = { layers = {} }
            for k, v in ipairs(animation.layers) do
                table.insert(tab.layers, make_animation_layer_with_hr_version(idx, v))
            end
            return tab
        else
            return make_animation_layer_with_hr_version(idx, animation)
        end
    end

    return
    {
        north = make_animation(0),
        east = make_animation(1),
        south = make_animation(2),
        west = make_animation(3)
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
        mining_time = mining_time.cable["t" .. tostring(tier)],
        result = entity_name
    }
    entity.speed = speed
    entity.animation_speed_coefficient = animation_speed_coefficient
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
        mining_time = mining_time.node["t" .. tostring(tier)],
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
        mining_time = mining_time.provider["t" .. tostring(tier)],
        result = entity_name
    }
    entity.inventory_size = inventory_size.provider["t" .. tostring(tier)]
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
        mining_time = mining_time.requester["t" .. tostring(tier)],
        result = entity_name
    }
    entity.circuit_wire_max_distance = 1
    entity.item_slot_count = 1
    entity.sprites = make_4way_animation_from_spritesheet({
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-t" .. tostring(tier) .. ".png",
                width = 128,
                height = 128,
                frame_count = 1,
                shift = util.by_pixel(0, 0),
                hr_version =
                {
                    scale = 0.5,
                    filename = "__transport-cables__/sprites/entities/hr-requester-t" .. tostring(tier) .. ".png",
                    width = 128,
                    height = 128,
                    frame_count = 1,
                    shift = util.by_pixel(0, 0)
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-t" .. tostring(tier) .. "-shadow.png",
                width = 128,
                height = 128,
                frame_count = 1,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                hr_version =
                {
                    scale = 0.5,
                    filename = "__transport-cables__/sprites/entities/hr-requester-t" .. tostring(tier) .. "-shadow.png",
                    width = 128,
                    height = 128,
                    frame_count = 1,
                    shift = util.by_pixel(0, 0),
                    draw_as_shadow = true
                }
            }
        }
    })

    data:extend({ entity })

    --
    -- requester container
    --
    local entity_name = prefix .. "requester-container-t" .. tostring(tier)
    local entity = table.deepcopy(data.raw["container"]["iron-chest"])
    entity.name = entity_name
    entity.minable = nil
    entity.inventory_size = inventory_size.requester_container["t" .. tostring(tier)]
    entity.destructible = false
    entity.picture = {
        layers =
        {
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-container-t" .. tostring(tier) .. ".png",
                priority = "extra-high",
                width = 64,
                height = 64,
                shift = util.by_pixel(0, 0),
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-requester-container-t" ..
                        tostring(tier) .. ".png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    shift = util.by_pixel(0, 0),
                    scale = 0.5
                }
            },
            {
                filename = "__transport-cables__/sprites/entities/lr-requester-container-t" ..
                    tostring(tier) .. "-shadow.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                hr_version =
                {
                    filename = "__transport-cables__/sprites/entities/hr-requester-container-t" ..
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
    local entity = table.deepcopy(data.raw["underground-belt"]["underground-belt"])
    entity.name = entity_name
    entity.minable = {
        mining_time = mining_time.underground_cable["t" .. tostring(tier)],
        result = entity_name
    }
    entity.speed = speed
    entity.animation_speed_coefficient = animation_speed_coefficient
    entity.belt_animation_set = get_belt_animation_set(1)
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
end

--
-- helper entity
--
---------------------------------------------------------------------------
local entity_name = prefix .. "lamp"
local entity = table.deepcopy(data.raw["lamp"]["small-lamp"])
entity.name = entity_name
entity.destructible = false
entity.minable = nil
entity.operable = false
entity.energy_source = { type = "void" }
entity.selection_box = { { 0.0, 0.0 }, { 0.0, 0.0 } }
entity.picture_off =
{
    layers =
    {
        {
            filename = "__transport-cables__/sprites/entities/lr-lamp.png",
            priority = "high",
            width = 32,
            height = 32,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0, 3),
            hr_version =
            {
                filename = "__transport-cables__/sprites/entities/hr-lamp.png",
                priority = "high",
                width = 32,
                height = 32,
                frame_count = 1,
                axially_symmetrical = false,
                direction_count = 1,
                shift = util.by_pixel(0.25, 3),
                scale = 0.5
            }
        },
        {
            filename = "__transport-cables__/sprites/entities/lr-lamp-shadow.png",
            priority = "high",
            width = 32,
            height = 32,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(4, 5),
            draw_as_shadow = true,
            hr_version =
            {
                filename = "__transport-cables__/sprites/entities/hr-lamp-shadow.png",
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
entity.picture_on =
{
    filename = "__transport-cables__/sprites/entities/lr-lamp-light.png",
    priority = "high",
    width = 32,
    height = 32,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 1,
    shift = util.by_pixel(0, -7),
    hr_version =
    {
        filename = "__transport-cables__/sprites/entities/hr-lamp-light.png",
        priority = "high",
        width = 32,
        height = 32,
        frame_count = 1,
        axially_symmetrical = false,
        direction_count = 1,
        shift = util.by_pixel(0, -7),
        scale = 0.5
    }
}

data:extend({ entity })
