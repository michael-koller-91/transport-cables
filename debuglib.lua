local prefix = "transport-cables-"

local commands = {
    print_off = prefix .. "print-off",
    print_on = prefix .. "print-on",
    print_connect_proxies = prefix .. "print-connect-proxies",
    print_gui = prefix .. "print-gui",
    print_on_research_finished = prefix .. "print-on-research-finished",
    print_set_rx_filter = prefix .. "print-set-rx-filter",
    print_update_net_id = prefix .. "print-update-net-id",
    print_update_receiver_filters = prefix .. "print-update-receiver-filters",
    research_all_technologies = prefix .. "research-all-technologies"
}

local flags = {
    add_debug_commands = true,
    print_connect_proxies = true,
    print_gui = true,
    print_on_research_finished = true,
    print_set_rx_filter = true,
    print_update_net_id = true,
    print_update_receiver_filters = true
}

local function print_to_players(str)
    for _, player in pairs(game.players) do
        player.print(str)
    end
end

return {
    commands = commands,
    flags = flags,
    print = print_to_players,
}
