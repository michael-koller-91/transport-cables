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
                recipe = prefix .. "provider-t1"
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "requester-t1",
            },
            {
                type = "unlock-recipe",
                recipe = prefix .. "underground-cable-t1",
            }
        },
        unit =
        {
            count = 50,
            ingredients = { { "automation-science-pack", 1 } },
            time = 15
        },
        order = "a-f-a"
    },
    {
        type = "technology",
        name = prefix .. "t1-speed1",
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
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 }
            },
            time = 30
        },
        upgrade = true,
        order = "c-m-b"
    }
})
