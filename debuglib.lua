local prefix = "transport-cables-"

local commands = {
    print_off = prefix .. "print-off",
    print_on = prefix .. "print-on",
    print_connect_lamps = prefix .. "print-connect-lamps",
    print_on_research_finished = prefix .. "print-on-research-finished",
    print_update_net_id = prefix .. "print-update-net-id",
    print_update_receiver_signals = prefix .. "print-update-receiver-signals"
}

local flags = {
    add_debug_commands = true,
    print_connect_lamps = true,
    print_on_research_finished = true,
    print_update_net_id = true,
    print_update_receiver_signals = true
}

local print_to_players = function(str)
    for _, player in pairs(game.players) do
        player.print(str)
    end
end

return {
    commands = commands,
    flags = flags,
    print = print_to_players,
}
