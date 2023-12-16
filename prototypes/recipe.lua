local entity_name = "transport-cables:cable"
local recipe = table.deepcopy(data.raw["recipe"]["transport-belt"])
recipe.enabled = true
recipe.name = entity_name
recipe.result = entity_name
recipe.result_count = 50

data:extend({ recipe })

--------------------------------------------------
local entity_name = "transport-cables:underground-cable"
local recipe = table.deepcopy(data.raw["recipe"]["underground-belt"])
recipe.enabled = true
recipe.name = entity_name
recipe.result = entity_name
recipe.result_count = 50

data:extend({ recipe })

--------------------------------------------------
local entity_name = "transport-cables:splitter"
local recipe = table.deepcopy(data.raw["recipe"]["splitter"])
recipe.enabled = true
recipe.name = entity_name
recipe.result = entity_name
recipe.result_count = 50

data:extend({ recipe })

--------------------------------------------------
local entity_name = "transport-cables:provider-connector"
local recipe = table.deepcopy(data.raw["recipe"]["loader"])
recipe.enabled = true
recipe.name = entity_name
recipe.result = entity_name
recipe.result_count = 50

data:extend({ recipe })

--------------------------------------------------
local entity_name = "transport-cables:requester-connector"
local recipe = table.deepcopy(data.raw["recipe"]["loader"])
recipe.enabled = true
recipe.name = entity_name
recipe.result = entity_name
recipe.result_count = 50

data:extend({ recipe })

--------------------------------------------------
local entity_name = "transport-cables:provider"
local recipe = table.deepcopy(data.raw["recipe"]["iron-chest"])
recipe.enabled = true
recipe.name = entity_name
recipe.result = entity_name
recipe.result_count = 10

data:extend({ recipe })

--------------------------------------------------
local entity_name = "transport-cables:requester"
local recipe = table.deepcopy(data.raw["recipe"]["wooden-chest"])
recipe.enabled = true
recipe.name = entity_name
recipe.ingredients = { { "wood", 1 } }
recipe.result = entity_name
recipe.result_count = 10

data:extend({ recipe })
