-- CONTINUOUSLY RECIEVE REDNET MESSAGES
while true do
    local sender, message, protocol = rednet.receive()
    if protocol == 'hub_report' then
        -- Hub broadcasts this continuously; use it as connectivity heartbeat.
        state.last_ping = os.clock()
    elseif protocol == 'mastermine' then
        state.last_ping = os.clock()
        if message.action == 'shutdown' then
            os.shutdown()
        elseif message.action == 'reboot' then
            os.reboot()
        elseif message.action == 'update' then
            os.run({}, '/update')
        else
            table.insert(state.requests, {sender, message, protocol})
        end
    end
end