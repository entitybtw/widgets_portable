System.USB.activate()

local cfgPath = "assets/cfg/"

local function isEnabled(name)
    local filePath = cfgPath .. name .. ".txt"
    local file = io.open(filePath, "r")
    if file then
        local status = file:read("*l")
        file:close()
        return (status == "on")
    end
    return false
end

local statusPath = "assets/statuses/"

local function readStatus(name)
    local filePath = statusPath .. name .. ".txt"
    local file = io.open(filePath, "r")
    if file then
        local status = file:read("*l")
        file:close()
        return status or "unknown"
    end
    return nil
end

local statusNames = { "cpu", "ram", "gpu", "kblayout", "time" }

local function drawStatus()
    screen.clear()
    local y = 20

    for _, name in ipairs(statusNames) do
        if isEnabled(name) then
            if name == "time" then
                local t = System.getTime()
                local timeStr = string.format("Time: %02d:%02d:%02d %02d/%02d/%04d",
                    t.hour, t.minutes, t.seconds, t.day, t.month, t.year)
                intraFont.print(20, y, timeStr, White, FontRegular, 1)
                y = y + 16
            else
                local st = readStatus(name)
                if not st or st == "" then
                    st = "unknown"
                end
                intraFont.print(20, y, string.format("%s: %s", name:upper(), st), White, FontRegular, 1)
                y = y + 16
            end
        end
    end

    screen.flip()
end

while true do
    buttons.read()
    if buttons.pressed(buttons.circle) then
        System.USB.deactivate() 
        break
    end

    drawStatus()
    LUA.sleep(1000)
end
