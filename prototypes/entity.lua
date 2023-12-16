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

--------------------------------------------------
local entity_name = "transport-cables:cable"
local entity = table.deepcopy(data.raw["transport-belt"]["transport-belt"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.speed = speed
entity.animation_speed_coefficient = animation_speed_coefficient
entity.related_underground_belt = "transport-cables:underground-cable"
entity.belt_animation_set = belt_animation_set

data:extend({ entity })

--------------------------------------------------
local entity_name = "transport-cables:underground-cable"
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

--------------------------------------------------
local entity_name = "transport-cables:splitter"
local entity = table.deepcopy(data.raw["splitter"]["splitter"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.speed = speed
entity.animation_speed_coefficient = animation_speed_coefficient
entity.belt_animation_set = belt_animation_set
entity.structure = {
    north = {
        filename = "__base__/graphics/entity/splitter/splitter-north.png",
        frame_count = 32,
        line_length = 8,
        priority = "extra-high",
        width = 82,
        height = 36,
        tint = tint,
        shift = util.by_pixel(6, 0),
        hr_version = {
            filename = "__base__/graphics/entity/splitter/hr-splitter-north.png",
            frame_count = 32,
            line_length = 8,
            priority = "extra-high",
            width = 160,
            height = 70,
            tint = tint,
            shift = util.by_pixel(7, 0),
            scale = 0.5
        }
    },
    east = {
        filename = "__base__/graphics/entity/splitter/splitter-east.png",
        frame_count = 32,
        line_length = 8,
        priority = "extra-high",
        width = 46,
        height = 44,
        tint = tint,
        shift = util.by_pixel(4, 12),
        hr_version = {
            filename = "__base__/graphics/entity/splitter/hr-splitter-east.png",
            frame_count = 32,
            line_length = 8,
            priority = "extra-high",
            width = 90,
            height = 84,
            tint = tint,
            shift = util.by_pixel(4, 13),
            scale = 0.5
        }
    },
    south = {
        filename = "__base__/graphics/entity/splitter/splitter-south.png",
        frame_count = 32,
        line_length = 8,
        priority = "extra-high",
        width = 82,
        height = 32,
        tint = tint,
        shift = util.by_pixel(4, 0),
        hr_version = {
            filename = "__base__/graphics/entity/splitter/hr-splitter-south.png",
            frame_count = 32,
            line_length = 8,
            priority = "extra-high",
            width = 164,
            height = 64,
            tint = tint,
            shift = util.by_pixel(4, 0),
            scale = 0.5
        }
    },
    west = {
        filename = "__base__/graphics/entity/splitter/splitter-west.png",
        frame_count = 32,
        line_length = 8,
        priority = "extra-high",
        width = 46,
        height = 44,
        tint = tint,
        shift = util.by_pixel(6, 12),
        hr_version = {
            filename = "__base__/graphics/entity/splitter/hr-splitter-west.png",
            frame_count = 32,
            line_length = 8,
            priority = "extra-high",
            width = 90,
            height = 86,
            tint = tint,
            shift = util.by_pixel(6, 12),
            scale = 0.5
        }
    }
}
entity.structure_patch = {
    north = util.empty_sprite(),
    east = {
        filename = "__base__/graphics/entity/splitter/splitter-east-top_patch.png",
        frame_count = 32,
        line_length = 8,
        priority = "extra-high",
        width = 46,
        height = 52,
        tint = tint,
        shift = util.by_pixel(4, -20),
        hr_version = {
            filename = "__base__/graphics/entity/splitter/hr-splitter-east-top_patch.png",
            frame_count = 32,
            line_length = 8,
            priority = "extra-high",
            width = 90,
            height = 104,
            tint = tint,
            shift = util.by_pixel(4, -20),
            scale = 0.5
        }
    },
    south = util.empty_sprite(),
    west = {
        filename = "__base__/graphics/entity/splitter/splitter-west-top_patch.png",
        frame_count = 32,
        line_length = 8,
        priority = "extra-high",
        width = 46,
        height = 48,
        tint = tint,
        shift = util.by_pixel(6, -18),
        hr_version = {
            filename = "__base__/graphics/entity/splitter/hr-splitter-west-top_patch.png",
            frame_count = 32,
            line_length = 8,
            priority = "extra-high",
            width = 90,
            height = 96,
            tint = tint,
            shift = util.by_pixel(6, -18),
            scale = 0.5
        }
    }
}

data:extend({ entity })

--------------------------------------------------
local entity_name = "transport-cables:requester-connector"
local entity = table.deepcopy(data.raw["loader"]["loader"])
local tint_blue = {
    r = 0,
    g = 0,
    b = 1,
    a = 0.7
}
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.speed = speed
entity.animation_speed_coefficient = animation_speed_coefficient
entity.belt_animation_set = belt_animation_set
entity.flags = nil
entity.structure = {
    direction_in = {
        sheet = {
            filename = "__base__/graphics/entity/loader/loader-structure.png",
            priority = "extra-high",
            width = 64,
            height = 64,
            tint = tint_blue
        }
    },
    direction_out = {
        sheet = {
            filename = "__base__/graphics/entity/loader/loader-structure.png",
            priority = "extra-high",
            width = 64,
            height = 64,
            tint = tint_blue,
            y = 64
        }
    }
}
data:extend({ entity })

--------------------------------------------------
local entity_name = "transport-cables:provider-connector"
local entity = table.deepcopy(data.raw["loader"]["loader"])
local tint_red = {
    r = 1,
    g = 0,
    b = 0,
    a = 0.7
}
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.speed = speed
entity.animation_speed_coefficient = animation_speed_coefficient
entity.belt_animation_set = belt_animation_set
entity.flags = nil
entity.structure = {
    direction_in = {
        sheet = {
            filename = "__base__/graphics/entity/loader/loader-structure.png",
            priority = "extra-high",
            width = 64,
            height = 64,
            tint = tint_red
        }
    },
    direction_out = {
        sheet = {
            filename = "__base__/graphics/entity/loader/loader-structure.png",
            priority = "extra-high",
            width = 64,
            height = 64,
            tint = tint_red,
            y = 64
        }
    }
}
data:extend({ entity })

--------------------------------------------------
local entity_name = "transport-cables:provider"
local entity = table.deepcopy(data.raw["container"]["iron-chest"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}

data:extend({ entity })

--------------------------------------------------
local entity_name = "transport-cables:requester"
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = entity_name
entity.minable = {
    mining_time = 0.01,
    result = entity_name
}
entity.item_slot_count = 1

data:extend({ entity })

--------------------------------------------------
local entity_name = "transport-cables:requester-container"
local entity = table.deepcopy(data.raw["container"]["iron-chest"])
entity.name = entity_name
entity.minable = nil

data:extend({ entity })

--------------------------------------------------
local entity_name = "transport-cables:lamp"
local entity = table.deepcopy(data.raw["lamp"]["small-lamp"])
entity.name = entity_name
entity.minable = nil
entity.flags = { "placeable-neutral" }

data:extend({ entity })
