local dbg = require("debuglib")
local lib = require("lib")

---------------------------------------------------------------------------
-- Debugging.
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
-- Building.
script.on_event(defines.events.on_built_entity, lib.on_built_entity, lib.on_built_filter)
script.on_event(defines.events.on_robot_built_entity, lib.on_built_entity, lib.on_built_filter)
script.on_event(defines.events.script_raised_built, lib.on_built_entity)
script.on_event(defines.events.script_raised_revive, lib.on_built_entity)

---------------------------------------------------------------------------
-- Pasting.
script.on_event(defines.events.on_entity_settings_pasted, lib.on_entity_settings_pasted)

---------------------------------------------------------------------------
-- GUI.
script.on_event(defines.events.on_gui_closed, lib.on_gui_closed)
script.on_event(defines.events.on_gui_elem_changed, lib.on_gui_elem_changed)
script.on_event(defines.events.on_gui_opened, lib.on_gui_opened)

---------------------------------------------------------------------------
-- Mining.
script.on_event(defines.events.on_player_mined_entity, lib.on_mined_entity, lib.on_mined_filter)
script.on_event(defines.events.on_robot_mined_entity, lib.on_mined_entity, lib.on_mined_filter)
script.on_event(defines.events.script_raised_destroy, lib.on_mined_entity)

---------------------------------------------------------------------------
-- Rotating.
script.on_event(defines.events.on_player_rotated_entity, lib.on_rotated_entity)

---------------------------------------------------------------------------
-- Technology.
script.on_event(defines.events.on_research_finished, lib.on_research_finished)

---------------------------------------------------------------------------
-- Initialization.
script.on_init(function()
    -- Tracks the circuit network IDs of receivers and transmitters which are
    -- connected, thus forming receiver-transmitter-pairs between which items
    -- need to be transported.
    global.active_nets = {} -- table[circuit network ID -> true]

    -- See the comments in lib.lua
    global.cable_connection_update_data = {}
    global.cable_connection_update_scheduled = false
    global.network_update_data = {}
    global.network_update_scheduled = false

    -- All hidden mod entities.
    global.proxies = {} -- table[unit number -> LuaEntity]

    -- One rate per tier. Every rate is by one `rate_increment` smaller than
    -- what the first research grants.
    global.rates = {
        [1] = 0,
        [2] = 30,
        [3] = 75
    }

    -- Every transmitter/receiver has a unit number `un` and a circuit network
    -- ID `net_id`. The variable `text_id` holds the ID of the text which
    -- displays the `net_id`.
    global.receiver = {
        net_id = {},              -- table[unit number -> circuit network ID]
        net_id_and_un = {},       -- table[circuit network ID -> table[unit number -> true]]
        net_id_and_priority = {}, -- table[circuit network ID -> table[unit number -> item distribution priority]]
        text_id = {},             -- table[unit number -> text ID]
        un = {}                   -- table[unit number -> LuaEntity]
    }
    global.transmitter = {
        net_id = {},        -- table[unit number -> circuit network ID]
        net_id_and_un = {}, -- table[circuit network ID -> table[unit number -> true]]
        text_id = {},       -- table[unit number -> text ID]
        un = {}             -- table[unit number -> LuaEntity]
    }

    lib.initialize(global)
end)

script.on_load(function()
    lib.initialize(global)
end)

---------------------------------------------------------------------------
-- Updates for which no event exists.
script.on_event(defines.events.on_tick, lib.on_tick)

-- The main algorithm runs here.
script.on_nth_tick(60, lib.on_nth_tick)
