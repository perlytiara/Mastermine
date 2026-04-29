-- Hub helper: rebuild disk files, then update/reboot all known turtles.

local function open_rednet()
    for _, side in pairs({"back", "top", "left", "right", "front", "bottom"}) do
        if peripheral.getType(side) == "modem" and not rednet.isOpen(side) then
            rednet.open(side)
        end
    end
end

local function load_config()
    if config and config.locations then
        return true
    end
    if fs.exists("/apis/config") then
        os.loadAPI("/apis/config")
        return true
    end
    if fs.exists("/config.lua") then
        os.loadAPI("/config.lua")
        return true
    end
    return false
end

local function get_turtle_ids()
    if not load_config() or (not config.locations) or (not config.locations.mine_enter) then
        return {}
    end
    local mine_dir = string.format(
        "/mine/%d,%d/turtles/",
        config.locations.mine_enter.x,
        config.locations.mine_enter.z
    )
    if not fs.exists(mine_dir) then
        return {}
    end
    local ids = {}
    for _, name in pairs(fs.list(mine_dir)) do
        local id = tonumber(name)
        if id then
            table.insert(ids, id)
        end
    end
    return ids
end

print("Building disk files...")
if not shell.run("mastermine", "disk") then
    error("Failed running 'mastermine disk'")
end

open_rednet()

local turtle_ids = get_turtle_ids()
if #turtle_ids == 0 then
    print("No known turtles found in /mine/.../turtles/")
    return
end

print("Sending update to " .. #turtle_ids .. " turtles...")
for _, id in pairs(turtle_ids) do
    rednet.send(id, {action = "update"}, "mastermine")
end

sleep(3)

print("Sending reboot to " .. #turtle_ids .. " turtles...")
for _, id in pairs(turtle_ids) do
    rednet.send(id, {action = "reboot"}, "mastermine")
end

print("Done.")
