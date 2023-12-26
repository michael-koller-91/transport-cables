local prefix = "transport-cables:"

data:extend({ {
    type = "technology",
    name = prefix .. "t1",
    icon_size = 64,
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
} })
