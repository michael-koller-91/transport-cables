local prefix = "transport-cables-"

local commands = {
    combinator_selectale = prefix .. "combinator-selectable",
    print_off = prefix .. "print-off",
    print_on = prefix .. "print-on",
    print_connect_proxies = prefix .. "print-connect-proxies",
    print_create_container = prefix .. "print-create-container",
    print_net_id = prefix .. "print-net-id",
    print_gui = prefix .. "print-gui",
    print_on_research_finished = prefix .. "print-on-research-finished",
    print_set_rx_filter = prefix .. "print-set-rx-filter",
    print_update_receiver_filters = prefix .. "print-update-receiver-filters",
    research_all_technologies = prefix .. "research-all-technologies",
    set_rate = prefix .. "set-rate"
}

local flags = {
    add_debug_commands = true,
    combinator_selectale = false,
    print_connect_proxies = true,
    print_create_container = true,
    print_net_id = true,
    print_gui = true,
    print_on_research_finished = true,
    print_set_rx_filter = true,
    print_update_receiver_filters = true
}

local function print_block(t, newline)
    if newline then
        print()
    end
    print(serpent.block(t))
end

local function print_to_console(s, newline)
    if newline then
        print()
    end
    print(s)
end

return {
    block = print_block,
    commands = commands,
    flags = flags,
    print = print_to_console,
}
