local prefix = "transport-cables:"

--
-- tier 1
--
---------------------------------------------------------------------------
data:extend({
    {
        type = "technology",
        name = prefix .. "t1",
        icon_size = 256,
        icon_mipmaps = 4,
        icon = "__transport-cables__/sprites/technologies/t1.png",
        effects =
        {
            {
                type = "unlock-recipe",
                recipe = prefix .. "cable-t1"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "node-t1"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "transmitter-t1"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "receiver-t1",
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "underground-cable-t1",
            }
        },
        prerequisites = { "logistics" },
        unit =
        {
            count = 50,
            ingredients = { { "automation-science-pack", 1 } },
            time = 15
        },
        order = "a-a-a"
    },
    {
        type = "technology",
        name = prefix .. "t1-speed",
        icons = util.technology_icon_constant_movement_speed("__transport-cables__/sprites/technologies/t1.png"),
        effects =
        {
            {
                type = "nothing",
                effect_description = "+ 15 items / s"
            }
        },
        prerequisites = { prefix .. "t1" },
        unit =
        {
            count = 250,
            ingredients =
            {
                { "automation-science-pack", 1 }
            },
            time = 30
        },
        upgrade = true,
        order = "a-a-a"
    }
})

--
-- tier 2
--
---------------------------------------------------------------------------
data:extend({
    {
        type = "technology",
        name = prefix .. "t2",
        icon_size = 256,
        icon_mipmaps = 4,
        icon = "__transport-cables__/sprites/technologies/t2.png",
        effects =
        {
            {
                type = "unlock-recipe",
                recipe = prefix .. "cable-t2"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "node-t2"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "transmitter-t2"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "receiver-t2",
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "underground-cable-t2",
            }
        },
        prerequisites = { prefix .. "t1-speed", "logistics-2" },
        unit =
        {
            count = 50,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 }
            },
            time = 15
        },
        order = "a-a-a"
    },
    {
        type = "technology",
        name = prefix .. "t2-speed1",
        icons = util.technology_icon_constant_movement_speed("__transport-cables__/sprites/technologies/t2.png"),
        effects =
        {
            {
                type = "nothing",
                effect_description = "+ 15 items / s"
            }
        },
        prerequisites = { prefix .. "t2" },
        unit =
        {
            count = 250,
            ingredients =
            {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 }
            },
            time = 30
        },
        upgrade = true,
        order = "a-a-a"
    },
    {
        type = "technology",
        name = prefix .. "t2-speed2",
        icons = util.technology_icon_constant_movement_speed("__transport-cables__/sprites/technologies/t2.png"),
        effects =
        {
            {
                type = "nothing",
                effect_description = "+ 15 items / s"
            }
        },
        prerequisites = { prefix .. "t2-speed1", "military-science-pack" },
        unit =
        {
            count = 250,
            ingredients =
            {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "military-science-pack",   1 }
            },
            time = 30
        },
        upgrade = true,
        order = "a-a-a"
    }
})

--
-- tier 3
--
---------------------------------------------------------------------------
data:extend({
    {
        type = "technology",
        name = prefix .. "t3",
        icon_size = 256,
        icon_mipmaps = 4,
        icon = "__transport-cables__/sprites/technologies/t3.png",
        effects =
        {
            {
                type = "unlock-recipe",
                recipe = prefix .. "cable-t3"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "node-t3"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "transmitter-t3"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "receiver-t3",
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "underground-cable-t3",
            }
        },
        prerequisites = { prefix .. "t2-speed2", "logistics-3", "chemical-science-pack", "production-science-pack" },
        unit =
        {
            count = 50,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 }
            },
            time = 15
        },
        order = "a-a-a"
    },
    {
        type = "technology",
        name = prefix .. "t3-speed1",
        icons = util.technology_icon_constant_movement_speed("__transport-cables__/sprites/technologies/t3.png"),
        effects =
        {
            {
                type = "nothing",
                effect_description = "+ 15 items / s"
            }
        },
        prerequisites = { prefix .. "t3" },
        unit =
        {
            count = 250,
            ingredients =
            {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 }
            },
            time = 30
        },
        upgrade = true,
        order = "a-a-a"
    },
    {
        type = "technology",
        name = prefix .. "t3-speed2",
        icons = util.technology_icon_constant_movement_speed("__transport-cables__/sprites/technologies/t2.png"),
        effects =
        {
            {
                type = "nothing",
                effect_description = "+ 15 items / s"
            }
        },
        prerequisites = { prefix .. "t3-speed1" },
        unit =
        {
            count = 250,
            ingredients =
            {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "military-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 }
            },
            time = 30
        },
        upgrade = true,
        order = "a-a-a"
    },
    {
        type = "technology",
        name = prefix .. "t3-speed3",
        icons = util.technology_icon_constant_movement_speed("__transport-cables__/sprites/technologies/t3.png"),
        effects =
        {
            {
                type = "nothing",
                effect_description = "+ 15 items / s"
            }
        },
        prerequisites = { prefix .. "t3-speed2", "utility-science-pack" },
        unit =
        {
            count = 250,
            ingredients =
            {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "military-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 },
                { "utility-science-pack",    1 }
            },
            time = 30
        },
        upgrade = true,
        order = "a-a-a"
    },
    {
        type = "technology",
        name = prefix .. "t3-infinite-speed",
        icons = util.technology_icon_constant_movement_speed("__transport-cables__/sprites/technologies/t3.png"),
        effects =
        {
            {
                type = "nothing",
                effect_description = "+ 10 percent items / s"
            }
        },
        prerequisites = { prefix .. "t3-speed3", "space-science-pack" },
        unit =
        {
            count_formula = "2^(L-6)*1000",
            ingredients =
            {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 },
                { "utility-science-pack",    1 },
                { "space-science-pack",      1 }
            },
            time = 60
        },
        upgrade = true,
        order = "a-a-a",
        max_level = "infinite"
    }
})
