local dbg = require("debuglib")
local lib = require("lib")

---------------------------------------------------------------------------
if dbg.flags.add_debug_commands then
    commands.add_command(dbg.commands.combinator_selectale, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_off, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_on, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_connect_proxies, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_create_container, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_net_id, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_gui, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_on_research_finished, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_set_rx_filter, nil, lib.on_console_command)
    commands.add_command(dbg.commands.print_update_receiver_filters, nil, lib.on_console_command)
    commands.add_command(dbg.commands.research_all_technologies, nil, lib.on_console_command)
    commands.add_command(dbg.commands.set_rate, nil, lib.on_console_command)
end

---------------------------------------------------------------------------
script.on_event(defines.events.on_built_entity, lib.on_built_entity, lib.on_built_filter)
script.on_event(defines.events.on_robot_built_entity, lib.on_built_entity, lib.on_built_filter)
script.on_event(defines.events.script_raised_built, lib.on_built_entity)
script.on_event(defines.events.script_raised_revive, lib.on_built_entity)

---------------------------------------------------------------------------
script.on_event(defines.events.on_entity_settings_pasted, lib.on_entity_settings_pasted)

---------------------------------------------------------------------------
script.on_event(defines.events.on_gui_closed, lib.on_gui_closed)
script.on_event(defines.events.on_gui_elem_changed, lib.on_gui_elem_changed)
script.on_event(defines.events.on_gui_opened, lib.on_gui_opened)

---------------------------------------------------------------------------
script.on_event(defines.events.on_marked_for_deconstruction, lib.on_marked_for_deconstruction)

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
    global.active_nets = {}
    global.cable_connection_update_data = {}
    global.cable_connection_update_scheduled = false
    global.network_update_data = {}
    global.network_update_scheduled = false
    global.proxies = {}
    global.rates = {}

    -- Every transmitter/receiver has a unit number `un` and is associated with a
    -- circuit network id `net_id`.
    -- The variable `text_id` holds the id of the text which displays the `net_id`.
    global.receiver = {
        net_id = {},              -- unit number -> circuit network id
        net_id_and_un = {},       -- circuit network id -> array(unit number)
        net_id_and_priority = {}, -- unit_number -> item distribution priority
        text_id = {},             -- unit number -> text id
        un = {}                   -- unit number -> entity
    }
    global.transmitter = {
        net_id = {},        -- unit number -> circuit network id
        net_id_and_un = {}, -- circuit network id -> array(unit number)
        text_id = {},       -- unit number -> text id
        un = {}             -- unit number -> entity
    }

    for tier = 1, lib.n_tiers do
        global.active_nets[tier] = {}
    end

    -- `rate` is by one `rate_increment` smaller than what the first research grants
    global.rates[1] = 4
    global.rates[2] = 30
    global.rates[3] = 75

    lib.initialize(global)
end)

---------------------------------------------------------------------------
script.on_load(function()
    lib.initialize(global)
end)

---------------------------------------------------------------------------
script.on_nth_tick(60, lib.on_nth_tick)
