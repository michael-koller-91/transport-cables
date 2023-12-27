require("lib")

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
script.on_init(function()
    global.provider = {
        net_id = {},
        net_id_and_un = {},
        pos = {},
        text_id = {},
        un = {}
    }
    global.requester = {
        container = {},
        net_id = {},
        net_id_and_un = {},
        pos = {},
        signal = {},
        text_id = {},
        un = {}
    }
    global.same_net_id = {}
    global.mod_state = {
        rate = {
            t1 = 15,
            t2 = 45,
            t3 = 90
        }
    }

    lib.initialize(global)
end)

---------------------------------------------------------------------------
script.on_load(function()
    lib.initialize(global)
end)

---------------------------------------------------------------------------
script.on_nth_tick(60, lib.on_nth_tick)
