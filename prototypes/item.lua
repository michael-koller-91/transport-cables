local prefix = "transport-cables:"
local entity_name = ""
local tiers = 3

for tier = 1, tiers do
    --
    -- cable
    --
    entity_name = prefix .. "cable-t" .. tostring(tier)
    data:extend({ {
        type = "item",
        name = entity_name,
        icon = "__transport-cables__/sprites/icons/cable-t" .. tostring(tier) .. ".png",
        icon_size = 64,
        icon_mipmaps = 4,
        place_result = entity_name,
        group = "logistics",
        subgroup = "transport-cables",
        order = "a-t" .. tostring(tier),
        stack_size = 100
    } })

    --
    -- node
    --
    entity_name = prefix .. "node-t" .. tostring(tier)
    data:extend({ {
        type = "item",
        name = entity_name,
        icon = "__transport-cables__/sprites/icons/node-t" .. tostring(tier) .. ".png",
        icon_size = 64,
        icon_mipmaps = 4,
        place_result = entity_name,
        group = "logistics",
        subgroup = "transport-cables",
        order = "c-t" .. tostring(tier),
        stack_size = 50,
    } })

    --
    -- receiver
    --
    entity_name = prefix .. "receiver-t" .. tostring(tier)
    data:extend({ {
        type = "item",
        name = entity_name,
        icon = "__transport-cables__/sprites/icons/receiver-t" .. tostring(tier) .. ".png",
        icon_size = 64,
        icon_mipmaps = 4,
        place_result = entity_name,
        group = "logistics",
        subgroup = "transport-cables",
        order = "e-t" .. tostring(tier),
        stack_size = 50
    } })

    --
    -- transmitter
    --
    entity_name = prefix .. "transmitter-t" .. tostring(tier)
    data:extend({ {
        type = "item",
        name = entity_name,
        icon = "__transport-cables__/sprites/icons/transmitter-t" .. tostring(tier) .. ".png",
        icon_size = 64,
        icon_mipmaps = 4,
        place_result = entity_name,
        group = "logistics",
        subgroup = "transport-cables",
        order = "d-t" .. tostring(tier),
        stack_size = 50
    } })

    --
    -- underground cable
    --
    entity_name = prefix .. "underground-cable-t" .. tostring(tier)
    data:extend({ {
        type = "item",
        name = entity_name,
        icon = "__transport-cables__/sprites/icons/underground-cable-t" .. tostring(tier) .. ".png",
        icon_size = 64,
        icon_mipmaps = 4,
        place_result = entity_name,
        group = "logistics",
        subgroup = "transport-cables",
        order = "b-t" .. tostring(tier),
        stack_size = 50,
    } })
end
