local prefix = "transport-cables:"

---------------------------------------------------------------------------
local entity_name = prefix .. "cable-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    energy_required = 0.5,
    ingredients =
    {
        { "iron-plate",      1 },
        { "iron-gear-wheel", 1 },
        { "transport-belt",  1 }
    },
    result = entity_name,
    result_count = 2
} })

---------------------------------------------------------------------------
local entity_name = prefix .. "node-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "iron-plate",         5 },
        { prefix .. "cable-t1", 4 }
    },
    result = entity_name,
    result_count = 1
} })

---------------------------------------------------------------------------
local entity_name = prefix .. "provider-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "iron-plate",         5 },
        { prefix .. "node-t1",  1 }
    },
    result = entity_name,
    result_count = 1
} })

---------------------------------------------------------------------------
local entity_name = prefix .. "requester-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "iron-plate",         5 },
        { prefix .. "node-t1",  1 },
        { "iron-chest",         1 }
    },
    result = entity_name,
    result_count = 1
} })

---------------------------------------------------------------------------
local entity_name = prefix .. "underground-cable-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    energy_required = 1,
    ingredients =
    {
        { "iron-plate",         10 },
        { prefix .. "cable-t1", 5 }
    },
    result = entity_name,
    result_count = 2
} })
