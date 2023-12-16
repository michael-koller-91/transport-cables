local prefix = "transport-cables:"
local speed = 1e-10
local animation_speed_coefficient = 1e10
local tint = {
    r = 1,
    g = 0,
    b = 1,
    a = 0.7
}
local belt_animation_set = {
    animation_set = {
        filename = "__base__/graphics/entity/transport-belt/transport-belt.png",
        priority = "extra-high",
        width = 64,
        height = 64,
        frame_count = 16,
        direction_count = 20,
        tint = tint,
        hr_version = {
            filename = "__base__/graphics/entity/transport-belt/hr-transport-belt.png",
            priority = "extra-high",
            width = 128,
            height = 128,
            scale = 0.5,
            frame_count = 16,
            direction_count = 20,
            tint = tint
        }
    }
}

---------------------------------------------------------------------------
local entity_name = prefix .. "lamp"
local entity = table.deepcopy(data.raw["lamp"]["small-lamp"])
entity.name = entity_name
entity.destructible = false
entity.minable = nil
entity.operable = false
entity.energy_source = {
    type = "void"
}
entity.selection_box = { { 0.0, 0.0 }, { 0.0, 0.0 } }

data:extend({ entity })

---------------------------------------------------------------------------
local entity_name = prefix .. "provider"
local entity = table.deepcopy(data.raw["container"]["iron-chest"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.picture =
{
    layers =
    {
        {
            filename = "__base__/graphics/entity/iron-chest/iron-chest.png",
            priority = "extra-high",
            width = 34,
            height = 38,
            tint = tint,
            shift = util.by_pixel(0, -0.5),
            hr_version =
            {
                filename = "__transport-cables__/sprites/provider-t1.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                shift = util.by_pixel(0, 0),
                scale = 0.5
            }
        },
        {
            filename = "__base__/graphics/entity/iron-chest/iron-chest-shadow.png",
            priority = "extra-high",
            width = 56,
            height = 26,
            tint = tint,
            shift = util.by_pixel(10, 6.5),
            draw_as_shadow = true,
            hr_version =
            {
                filename = "__transport-cables__/sprites/provider-t1-shadow.png",
                priority = "extra-high",
                width = 70,
                height = 70,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true,
                scale = 0.5
            }
        }
    }
}

data:extend({ entity })

---------------------------------------------------------------------------
local entity_name = prefix .. "requester"
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.circuit_wire_max_distance = 1
entity.item_slot_count = 1
entity.sprites = make_4way_animation_from_spritesheet({
    layers =
    {
        {
            filename = "__base__/graphics/entity/combinator/constant-combinator.png",
            width = 58,
            height = 52,
            frame_count = 1,
            shift = util.by_pixel(0, 0),
            hr_version =
            {
                scale = 0.5,
                filename = "__transport-cables__/sprites/requester-t1.png",
                width = 64,
                height = 64,
                frame_count = 1,
                shift = util.by_pixel(0, 0)
            }
        },
        {
            filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
            width = 50,
            height = 34,
            frame_count = 1,
            shift = util.by_pixel(9, 6),
            draw_as_shadow = true,
            hr_version =
            {
                scale = 0.5,
                filename = "__transport-cables__/sprites/requester-t1-shadow.png",
                width = 70,
                height = 70,
                frame_count = 1,
                shift = util.by_pixel(0, 0),
                draw_as_shadow = true
            }
        }
    }
})



data:extend({ entity })

---------------------------------------------------------------------------
local entity_name = prefix .. "requester-container"
local entity = table.deepcopy(data.raw["container"]["iron-chest"])
entity.name = entity_name
entity.minable = nil
entity.destructible = false

data:extend({ entity })

---------------------------------------------------------------------------
local entity_name = prefix .. "node"
local entity = table.deepcopy(data.raw["lamp"]["small-lamp"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.energy_source = {
    type = "void"
}
entity.picture_off = {
    layers = { {
        filename = "__base__/graphics/entity/small-lamp/lamp.png",
        priority = "high",
        width = 42,
        height = 36,
        frame_count = 1,
        axially_symmetrical = false,
        direction_count = 1,
        shift = util.by_pixel(0, 3),
        tint = tint,
        hr_version = {
            filename = "__base__/graphics/entity/small-lamp/hr-lamp.png",
            priority = "high",
            width = 83,
            height = 70,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0.25, 3),
            tint = tint,
            scale = 0.5
        }
    }, {
        filename = "__base__/graphics/entity/small-lamp/lamp-shadow.png",
        priority = "high",
        width = 38,
        height = 24,
        frame_count = 1,
        axially_symmetrical = false,
        direction_count = 1,
        shift = util.by_pixel(4, 5),
        tint = tint,
        draw_as_shadow = true,
        hr_version = {
            filename = "__base__/graphics/entity/small-lamp/hr-lamp-shadow.png",
            priority = "high",
            width = 76,
            height = 47,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(4, 4.75),
            tint = tint,
            draw_as_shadow = true,
            scale = 0.5
        }
    } }
}

data:extend({ entity })

---------------------------------------------------------------------------
local entity_name = prefix .. "cable"
local entity = table.deepcopy(data.raw["transport-belt"]["transport-belt"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.speed = speed
entity.animation_speed_coefficient = animation_speed_coefficient
entity.related_underground_belt = prefix .. "underground-cable"
entity.belt_animation_set = belt_animation_set

data:extend({ entity })

---------------------------------------------------------------------------
local entity_name = prefix .. "underground-cable"
local entity = table.deepcopy(data.raw["underground-belt"]["underground-belt"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.speed = speed
entity.animation_speed_coefficient = animation_speed_coefficient
entity.belt_animation_set = belt_animation_set
entity.structure = {
    direction_in = {
        sheet = {
            filename = "__base__/graphics/entity/underground-belt/underground-belt-structure.png",
            priority = "extra-high",
            width = 96,
            height = 96,
            y = 96,
            tint = tint,
            hr_version = {
                filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure.png",
                priority = "extra-high",
                width = 192,
                height = 192,
                y = 192,
                tint = tint,
                scale = 0.5
            }
        }
    },
    direction_out = {
        sheet = {
            filename = "__base__/graphics/entity/underground-belt/underground-belt-structure.png",
            priority = "extra-high",
            width = 96,
            height = 96,
            tint = tint,
            hr_version = {
                filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure.png",
                priority = "extra-high",
                width = 192,
                height = 192,
                tint = tint,
                scale = 0.5
            }

        }

    },
    direction_in_side_loading = {
        sheet = {
            filename = "__base__/graphics/entity/underground-belt/underground-belt-structure.png",
            priority = "extra-high",
            width = 96,
            height = 96,
            y = 96 * 3,
            tint = tint,
            hr_version = {
                filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure.png",
                priority = "extra-high",
                width = 192,
                height = 192,
                y = 192 * 3,
                tint = tint,
                scale = 0.5
            }
        }
    },
    direction_out_side_loading = {
        sheet = {
            filename = "__base__/graphics/entity/underground-belt/underground-belt-structure.png",
            priority = "extra-high",
            width = 96,
            height = 96,
            y = 96 * 2,
            tint = tint,
            hr_version = {
                filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure.png",
                priority = "extra-high",
                width = 192,
                height = 192,
                y = 192 * 2,
                tint = tint,
                scale = 0.5
            }

        }

    },
    back_patch = {
        sheet = {
            filename = "__base__/graphics/entity/underground-belt/underground-belt-structure-back-patch.png",
            priority = "extra-high",
            width = 96,
            height = 96,
            tint = tint,
            hr_version = {
                filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure-back-patch.png",
                priority = "extra-high",
                width = 192,
                height = 192,
                tint = tint,
                scale = 0.5
            }

        }
    },
    front_patch = {
        sheet = {
            filename = "__base__/graphics/entity/underground-belt/underground-belt-structure-front-patch.png",
            priority = "extra-high",
            width = 96,
            height = 96,
            tint = tint,
            hr_version = {
                filename = "__base__/graphics/entity/underground-belt/hr-underground-belt-structure-front-patch.png",
                priority = "extra-high",
                width = 192,
                height = 192,
                tint = tint,
                scale = 0.5
            }

        }
    }
}

data:extend({ entity })


---------------------------------------------------------------------------
--
-- this function is from __base__/prototypes/entity/entities.lua
--
function make_4way_animation_from_spritesheet(animation)
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
