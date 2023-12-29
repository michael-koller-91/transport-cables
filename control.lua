require("lib")

---------------------------------------------------------------------------
commands.add_command(lib.command_debug_lamp, nil, lib.on_console_command)
commands.add_command(lib.command_debug_print, nil, lib.on_console_command)

---------------------------------------------------------------------------
script.on_event(defines.events.on_built_entity, lib.on_built_entity, lib.on_built_filter)
script.on_event(defines.events.on_robot_built_entity, lib.on_built_entity, lib.on_built_filter)
script.on_event(defines.events.script_raised_built, lib.on_built_entity)
script.on_event(defines.events.script_raised_revive, lib.on_built_entity)

---------------------------------------------------------------------------
script.on_event(defines.events.on_entity_settings_pasted, lib.on_entity_settings_pasted)

---------------------------------------------------------------------------
script.on_event(defines.events.on_gui_closed, lib.on_gui_closed)

---------------------------------------------------------------------------
script.on_event(defines.events.on_player_created, lib.on_player_created)

---------------------------------------------------------------------------
script.on_event(defines.events.on_player_mined_entity, lib.on_mined_entity, lib.on_mined_filter)
script.on_event(defines.events.on_robot_mined_entity, lib.on_mined_entity, lib.on_mined_filter)
script.on_event(defines.events.script_raised_destroy, lib.on_mined_entity)

---------------------------------------------------------------------------
script.on_event(defines.events.on_player_rotated_entity, lib.on_rotated_entity)

---------------------------------------------------------------------------
script.on_event(defines.events.on_research_finished, lib.on_research_finished)

---------------------------------------------------------------------------
script.on_event(defines.events.on_tick, lib.on_tick)

---------------------------------------------------------------------------
-- Every provider/requester has a unit number `un` and is associated with a
-- circuit network id `net_id`. Further, it has a map position `pos`. The
-- variable `text_id` holds the id of the text which displays the `net_id`.

-- net_id: unit number -> circuit network id
-- net_id_and_un: circuit network id -> (unit number -> entity)
-- pos: map position -> entity
-- signal: unit number -> circuit network signal
-- un: unit number -> entity

local provider_table = {
    net_id = {},
    net_id_and_un = {},
    pos = {},
    text_id = {},
    un = {}
}

-- The container entity assiciated with a requester is stored in `container`
-- and `signal` is the requester's state, i.e., the signal which it is
-- requesting.
local requester_table = {
    container = {},
    net_id = {},
    net_id_and_un = {},
    pos = {},
    signal = {},
    text_id = {},
    un = {}
}

---------------------------------------------------------------------------
script.on_init(function()
    global.lamps = {}
    global.provider = {}
    global.requester = {}
    global.same_net_id = {}
    global.mod_state = {}

    for tier = 1, lib.tiers do
        global.lamps[tier] = {}
        global.provider[tier] = table.deepcopy(provider_table)
        global.requester[tier] = table.deepcopy(requester_table)
        global.same_net_id[tier] = {}
        global.mod_state[tier] = { rate = 0 }
    end

    -- `rate` is by one `rate_increment` smaller than what the first research grants
    global.mod_state[2].rate = 30
    global.mod_state[3].rate = 75

    lib.initialize(global)
end)

---------------------------------------------------------------------------
script.on_load(function()
    lib.initialize(global)
end)

---------------------------------------------------------------------------
script.on_nth_tick(60, lib.on_nth_tick)
