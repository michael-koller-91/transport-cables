local prefix = "transport-cables:"

--
-- cables
--
---------------------------------------------------------------------------
local entity_name = prefix .. "cable-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = true,
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

-- TODO
local entity_name = prefix .. "cable-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = true,
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

-- TODO
local entity_name = prefix .. "cable-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = true,
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

--
-- nodes
--
---------------------------------------------------------------------------
local entity_name = prefix .. "node-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 4 },
        { "iron-plate",         4 },
        { "splitter",           1 },
    },
    result = entity_name,
    result_count = 1
} })

-- TODO
local entity_name = prefix .. "node-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 4 },
        { "iron-plate",         4 },
        { "splitter",           1 },
    },
    result = entity_name,
    result_count = 1
} })

-- TODO
local entity_name = prefix .. "node-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 4 },
        { "iron-plate",         4 },
        { "splitter",           1 },
    },
    result = entity_name,
    result_count = 1
} })

--
-- providers
--
---------------------------------------------------------------------------
local entity_name = prefix .. "provider-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
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

-- TODO
local entity_name = prefix .. "provider-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
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

-- TODO
local entity_name = prefix .. "provider-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
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

--
-- requesters
--
---------------------------------------------------------------------------
local entity_name = prefix .. "requester-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "iron-chest",         1 },
        { prefix .. "node-t1",  1 }
    },
    result = entity_name,
    result_count = 1
} })

-- TODO
local entity_name = prefix .. "requester-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "iron-chest",         1 },
        { prefix .. "node-t1",  1 }
    },
    result = entity_name,
    result_count = 1
} })

-- TODO
local entity_name = prefix .. "requester-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "iron-chest",         1 },
        { prefix .. "node-t1",  1 }
    },
    result = entity_name,
    result_count = 1
} })

--
-- underground cables
--
---------------------------------------------------------------------------
local entity_name = prefix .. "underground-cable-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "underground-belt",   1 },
        { prefix .. "cable-t1", 5 }
    },
    result = entity_name,
    result_count = 2
} })

-- TODO
local entity_name = prefix .. "underground-cable-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "underground-belt",   1 },
        { prefix .. "cable-t1", 5 }
    },
    result = entity_name,
    result_count = 2
} })

-- TODO
local entity_name = prefix .. "underground-cable-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = 1,
    ingredients =
    {
        { "underground-belt",   1 },
        { prefix .. "cable-t1", 5 }
    },
    result = entity_name,
    result_count = 2
} })
