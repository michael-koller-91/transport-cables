local tint = {
    r = 1,
    g = 0,
    b = 1,
    a = 0.5
}

--
-- cables
--
---------------------------------------------------------------------------
local entity_name = "transport-cables:cable"
local item = table.deepcopy(data.raw["item"]["transport-belt"])
item.name = entity_name
item.icons = { { icon = "__transport-cables__/sprites/icons/cable-t1.png" } }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name
item.group = "transport-cables"
item.order = "z"

data:extend({ item })

--
-- nodes
--
---------------------------------------------------------------------------
local entity_name = "transport-cables:node"
local item = table.deepcopy(data.raw["item"]["splitter"])
item.name = entity_name
item.icons = { { icon = "__transport-cables__/sprites/icons/node-t1.png" } }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name
item.order = "z-e1"

data:extend({ item })

--
-- providers
--
---------------------------------------------------------------------------
local entity_name = "transport-cables:provider"
local item = table.deepcopy(data.raw["item"]["iron-chest"])
item.name = entity_name
item.icons = { { icon = "__transport-cables__/sprites/icons/provider-t1.png" } }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name
item.order = "z-a1"

data:extend({ item })

--
-- requesters
--
---------------------------------------------------------------------------
local entity_name = "transport-cables:requester"
local item = table.deepcopy(data.raw["item"]["wooden-chest"])
item.name = entity_name
item.icons = { { icon = "__transport-cables__/sprites/icons/requester-t1.png" } }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name
item.order = "z-b1"

data:extend({ item })

--
-- underground cables
--
---------------------------------------------------------------------------
local entity_name = "transport-cables:underground-cable"
local item = table.deepcopy(data.raw["item"]["underground-belt"])
item.name = entity_name
item.icons = { {
    icon = "__base__/graphics/icons/underground-belt.png",
    tint = tint
} }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name
item.group = "transport-cables"
item.order = "z-d1"

data:extend({ item })
