local prefix = "transport-cables:"

local energy_required = {
    cable = {
        t1 = 0.5,
        t2 = 0.5,
        t3 = 0.5
    },
    node = {
        t1 = 0.5,
        t2 = 0.5,
        t3 = 0.5
    },
    transmitter = {
        t1 = 0.5,
        t2 = 0.5,
        t3 = 0.5
    },
    receiver = {
        t1 = 0.5,
        t2 = 0.5,
        t3 = 0.5
    },
    underground_cable = {
        t1 = 0.5,
        t2 = 0.5,
        t3 = 0.5
    }
}

local entity_name = ""

--
-- cables
--
---------------------------------------------------------------------------
entity_name = prefix .. "cable-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.cable.t1,
    ingredients =
    {
        { "iron-plate",     1 },
        { "copper-plate",   1 },
        { "transport-belt", 1 }
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "cable-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.cable.t2,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "copper-cable",       5 },
        { prefix .. "cable-t1", 1 }
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "cable-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.cable.t3,
    ingredients =
    {
        { "advanced-circuit",   10 },
        { "red-wire",           10 },
        { prefix .. "cable-t2", 1 }
    },
    result = entity_name,
    result_count = 1
} })

--
-- nodes
--
---------------------------------------------------------------------------
entity_name = prefix .. "node-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.node.t1,
    ingredients =
    {
        { "iron-plate",         1 },
        { "copper-plate",       1 },
        { prefix .. "cable-t1", 4 },
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "node-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.node.t2,
    ingredients =
    {
        { "electronic-circuit", 5 },
        { "copper-cable",       5 },
        { prefix .. "cable-t2", 4 },
        { prefix .. "node-t1",  1 }
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "node-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.node.t3,
    ingredients =
    {
        { "advanced-circuit",   10 },
        { "red-wire",           10 },
        { prefix .. "cable-t3", 4 },
        { prefix .. "node-t2",  1 }
    },
    result = entity_name,
    result_count = 1
} })

--
-- transmitters
--
---------------------------------------------------------------------------
entity_name = prefix .. "transmitter-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.transmitter.t1,
    ingredients =
    {
        { "copper-plate",      1 },
        { "iron-plate",        1 },
        { prefix .. "node-t1", 1 }
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "transmitter-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.transmitter.t2,
    ingredients =
    {
        { "iron-chest",         1 },
        { prefix .. "cable-t2", 4 },
        { prefix .. "node-t2",  1 }
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "transmitter-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.transmitter.t3,
    ingredients =
    {
        { "steel-chest",        1 },
        { prefix .. "cable-t3", 4 },
        { prefix .. "node-t3",  1 }
    },
    result = entity_name,
    result_count = 1
} })

--
-- receivers
--
---------------------------------------------------------------------------
entity_name = prefix .. "receiver-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.receiver.t1,
    ingredients =
    {
        { "copper-plate",      1 },
        { "iron-plate",        1 },
        { prefix .. "node-t1", 1 }
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "receiver-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.receiver.t2,
    ingredients =
    {
        { "iron-chest",          1 },
        { prefix .. "cable-t2",  3 },
        { prefix .. "node-t2",   1 },
        { "constant-combinator", 1 }
    },
    result = entity_name,
    result_count = 1
} })

entity_name = prefix .. "receiver-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.receiver.t3,
    ingredients =
    {
        { "steel-chest",         1 },
        { prefix .. "cable-t3",  3 },
        { prefix .. "node-t3",   1 },
        { "constant-combinator", 1 }
    },
    result = entity_name,
    result_count = 1
} })

--
-- underground cables
--
---------------------------------------------------------------------------
entity_name = prefix .. "underground-cable-t1"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.underground_cable.t1,
    ingredients =
    {
        { "iron-plate",         5 },
        { "copper-plate",       5 },
        { prefix .. "cable-t1", 5 }
    },
    result = entity_name,
    result_count = 2
} })

entity_name = prefix .. "underground-cable-t2"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.underground_cable.t2,
    ingredients =
    {
        { "electronic-circuit",             5 },
        { "copper-cable",                   5 },
        { prefix .. "underground-cable-t1", 2 },
    },
    result = entity_name,
    result_count = 2
} })

entity_name = prefix .. "underground-cable-t3"
data:extend({ {
    type = "recipe",
    name = entity_name,
    enabled = false,
    energy_required = energy_required.underground_cable.t3,
    ingredients =
    {
        { "advanced-circuit",               10 },
        { "red-wire",                       10 },
        { prefix .. "underground-cable-t2", 2 },
    },
    result = entity_name,
    result_count = 2
} })
