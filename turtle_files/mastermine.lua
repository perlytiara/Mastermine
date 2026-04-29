function parse_requests()
    -- PROCESS ALL REDNET REQUESTS
    while #state.requests > 0 do
        local request = table.remove(state.requests, 1)
        sender, message, protocol = request[1], request[2], request[3]
        if message.action == 'shutdown' then
            os.shutdown()
        elseif message.action == 'reboot' then
            os.reboot()
        elseif message.action == 'update' then
            os.run({}, '/update')
        elseif message.request_id == -1 or message.request_id == state.request_id then -- MAKE SURE REQUEST IS CURRENT
            if state.initialized or message.action == 'initialize' then
                print('Directive: ' .. message.action)
                state.busy = true
                state.success = actions[message.action](unpack(message.data)) -- EXECUTE DESIRED FUNCTION WITH DESIRED ARGUMENTS
                state.busy = false
                if not state.success then
                    sleep(1)
                end
                state.request_id = state.request_id + 1
            end
        end
    end
end


function failsafe_return_if_link_lost()
    if not state.initialized then
        return
    end
    if state.busy or #state.requests > 0 then
        return
    end
    if not state.location then
        return
    end
    if state.location.y >= config.locations.mine_enter.y then
        return
    end
    local timeout = config.turtle_link_loss_timeout or 20
    local now = os.clock()
    if now - (state.last_ping or now) < timeout then
        return
    end
    print('Link timeout underground: local failsafe return')
    state.busy = true
    local ok = actions.go_to_mine_exit(state.strip)
    if ok then
        ok = actions.go_to_home()
    end
    state.success = ok
    state.busy = false
    -- Prevent rapid retry spam if path is blocked.
    state.last_ping = now
end


function main()
    state.last_ping = os.clock()
    while true do
        parse_requests()
        failsafe_return_if_link_lost()
        sleep(0.3)
    end
end


main()