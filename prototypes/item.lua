local tiers = 1

for tier = 1, tiers do
    --
    -- cables
    --
    ---------------------------------------------------------------------------
    local entity_name = "transport-cables:cable-t" .. tostring(tier)
    local item = table.deepcopy(data.raw["item"]["transport-belt"])
    item.name = entity_name
    item.icons = { { icon = "__transport-cables__/sprites/icons/cable-t" .. tostring(tier) .. ".png" } }
    item.icon_size = 64
    item.icon_mipmaps = 4
    item.place_result = entity_name
    item.group = "logistics"
    item.subgroup = "transport-cables"
    item.order = "a-t" .. tostring(tier)

    data:extend({ item })

    --
    -- nodes
    --
    ---------------------------------------------------------------------------
    local entity_name = "transport-cables:node-t" .. tostring(tier)
    local item = table.deepcopy(data.raw["item"]["splitter"])
    item.name = entity_name
    item.icons = { { icon = "__transport-cables__/sprites/icons/node-t" .. tostring(tier) .. ".png" } }
    item.icon_size = 64
    item.icon_mipmaps = 4
    item.place_result = entity_name
    item.group = "logistics"
    item.subgroup = "transport-cables"
    item.order = "c-t" .. tostring(tier)

    data:extend({ item })

    --
    -- providers
    --
    ---------------------------------------------------------------------------
    local entity_name = "transport-cables:provider-t" .. tostring(tier)
    local item = table.deepcopy(data.raw["item"]["iron-chest"])
    item.name = entity_name
    item.icons = { { icon = "__transport-cables__/sprites/icons/provider-t" .. tostring(tier) .. ".png" } }
    item.icon_size = 64
    item.icon_mipmaps = 4
    item.place_result = entity_name
    item.group = "logistics"
    item.subgroup = "transport-cables"
    item.order = "d-t" .. tostring(tier)

    data:extend({ item })

    --
    -- requesters
    --
    ---------------------------------------------------------------------------
    local entity_name = "transport-cables:requester-t" .. tostring(tier)
    local item = table.deepcopy(data.raw["item"]["wooden-chest"])
    item.name = entity_name
    item.icons = { { icon = "__transport-cables__/sprites/icons/requester-t" .. tostring(tier) .. ".png" } }
    item.icon_size = 64
    item.icon_mipmaps = 4
    item.place_result = entity_name
    item.group = "logistics"
    item.subgroup = "transport-cables"
    item.order = "e-t" .. tostring(tier)

    data:extend({ item })

    --
    -- underground cables
    --
    ---------------------------------------------------------------------------
    local entity_name = "transport-cables:underground-cable-t" .. tostring(tier)
    local item = table.deepcopy(data.raw["item"]["underground-belt"])
    item.name = entity_name
    item.icons = { { icon = "__transport-cables__/sprites/icons/underground-cable-t" .. tostring(tier) .. ".png" } }
    item.icon_size = 64
    item.icon_mipmaps = 4
    item.place_result = entity_name
    item.group = "logistics"
    item.subgroup = "transport-cables"
    item.order = "b-t" .. tostring(tier)

    data:extend({ item })
end
