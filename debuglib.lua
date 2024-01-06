local prefix = "transport-cables-"

local commands = {
    print_off = prefix .. "print-off",
    print_on = prefix .. "print-on",
    print_connect_lamps = prefix .. "print-connect-lamps",
    print_on_research_finished = prefix .. "print-on-research-finished",
    print_set_rx_filter = prefix .. "print-set-rx-filter",
    print_update_net_id = prefix .. "print-update-net-id",
    print_update_receiver_filters = prefix .. "print-update-receiver-filters",
    research_all_technologies = prefix .. "research-all-technologies"
}

local flags = {
    add_debug_commands = false,
    print_connect_lamps = true,
    print_on_research_finished = true,
    print_set_rx_filter = true,
    print_update_net_id = true,
    print_update_receiver_filters = true
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
