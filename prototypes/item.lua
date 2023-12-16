local tint = {
    r = 1,
    g = 0,
    b = 1,
    a = 0.5
}

--------------------------------------------------
local entity_name = "transport-cables:cable"
local item = table.deepcopy(data.raw["item"]["transport-belt"])
item.name = entity_name
item.icons = { {
    icon = "__base__/graphics/icons/transport-belt.png",
    tint = tint
} }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name

data:extend({ item })

--------------------------------------------------
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

data:extend({ item })

--------------------------------------------------
local entity_name = "transport-cables:splitter"
local item = table.deepcopy(data.raw["item"]["splitter"])
item.name = entity_name
item.icons = { {
    icon = "__base__/graphics/icons/splitter.png",
    tint = tint
} }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name

data:extend({ item })

--------------------------------------------------
local entity_name = "transport-cables:requester-connector"
local item = table.deepcopy(data.raw["item"]["loader"])
item.name = entity_name
item.icons = { {
    icon = "__base__/graphics/icons/loader.png",
    tint = {
        r = 0,
        g = 0,
        b = 1,
        a = 0.5
    }
} }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name

data:extend({ item })

--------------------------------------------------
local entity_name = "transport-cables:provider-connector"
local item = table.deepcopy(data.raw["item"]["loader"])
item.name = entity_name
item.icons = { {
    icon = "__base__/graphics/icons/loader.png",
    tint = {
        r = 1,
        g = 0,
        b = 0,
        a = 0.5
    }
} }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name

data:extend({ item })

--------------------------------------------------
local entity_name = "transport-cables:provider"
local item = table.deepcopy(data.raw["item"]["iron-chest"])
item.name = entity_name
item.icons = { {
    icon = "__base__/graphics/icons/iron-chest.png",
    tint = {
        r = 1,
        g = 0,
        b = 0,
        a = 0.8
    }
} }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name

data:extend({ item })

--------------------------------------------------
local entity_name = "transport-cables:requester"
local item = table.deepcopy(data.raw["item"]["wooden-chest"])
item.name = entity_name
item.icons = { {
    icon = "__base__/graphics/icons/wooden-chest.png",
    tint = {
        r = 0,
        g = 0,
        b = 1,
        a = 0.8
    }
} }
item.icon_size = 64
item.icon_mipmaps = 4
item.place_result = entity_name

data:extend({ item })
