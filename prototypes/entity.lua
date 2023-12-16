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
                filename = "__transport-cables__/sprites/box.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                shift = util.by_pixel(-0.5, -0.5),
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
                filename = "__transport-cables__/sprites/box-shadow.png",
                priority = "extra-high",
                width = 128,
                height = 69,
                shift = util.by_pixel(10.5, 6),
                draw_as_shadow = true,
                scale = 0.5
            }
        }
    }
}
--entity.picture =
--{
--    layers =
--    {
--        {
--            filename = "__base__/graphics/entity/iron-chest/iron-chest.png",
--            priority = "extra-high",
--            width = 34,
--            height = 38,
--            tint = tint,
--            shift = util.by_pixel(0, -0.5)
--        },
--        {
--            filename = "__base__/graphics/entity/iron-chest/iron-chest.png",
--            priority = "extra-high",
--            width = 10,
--            height = 33,
--            x = 18,
--            tint = tint,
--            shift = util.by_pixel(0, -0.5),
--            apply_runtime_tint = true
--        }
--    }
--}

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
