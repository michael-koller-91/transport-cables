data:extend({ {
    type = "item-subgroup",
    name = "transport-cables",
    group = "logistics",
    order = "j"
} })
-- The hidden entities are in their own group to effectively deactivate fast_replaceable_group
-- while still making the next_upgrade possible.
-- Fast replacement is deactivated because it leads to circuit network update detection problems when an entity
-- is mined and built on the same tile in the same tick.
data:extend({ {
    type = "item-subgroup",
    name = "transport-cables-hidden",
    group = "logistics",
    order = "j"
} })

