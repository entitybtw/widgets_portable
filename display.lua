local cfgPath = "assets/cfg/"
local statusPath = "assets/statuses/"
local imageCache = {}

local function isEnabled(name)
    local f = io.open(cfgPath .. name .. ".txt", "r")
    if f then
        local status = f:read("*l")
        f:close()
        return status == "on"
    end
    return false
end

local function readStatus(name)
    local f = io.open(statusPath .. name .. ".txt", "r")
    if f then
        local line = f:read("*l")
        f:close()
        return line or "unknown"
    end
    return nil
end

local statusNames = { "cpu", "ram", "gpu", "kblayout", "time" }
local positions = {}
local colors = {}

local function loadPositions()
    local step = 14
    for i, name in ipairs(statusNames) do
        local f = io.open(cfgPath .. name .. ".txt", "r")
        if f then
            local enabled = f:read("*l") or "off"
            local x = tonumber(f:read("*l"))
            local y = tonumber(f:read("*l"))
            local scaleX = tonumber(f:read("*l"))
            local scaleY = tonumber(f:read("*l"))
            f:close()

            if not x then x = 20 end
            if not y then y = 20 + (i - 1) * step end
            if not scaleX then scaleX = 1 end
            if not scaleY then scaleY = 1 end

            positions[name] = { x = x, y = y, scale = (scaleX + scaleY) / 2 }
        else
            positions[name] = { x = 20, y = 20 + (i - 1) * step, scale = 1 }
        end
    end

    local f = io.open(cfgPath .. "kbflag_img.txt", "r")
    if f then
        f:read("*l")
        local x = tonumber(f:read("*l")) or 20
        local y = tonumber(f:read("*l")) or (20 + #statusNames * step)
        local scaleX = tonumber(f:read("*l")) or 1
        local scaleY = tonumber(f:read("*l")) or 1
        positions["kbflag"] = { x = x, y = y, scale = math.max(scaleX, scaleY) }
        f:close()
    else
        positions["kbflag"] = { x = 20, y = 20 + #statusNames * step, scale = 1 }
    end
end



local function loadColors()
    for _, name in ipairs(statusNames) do
        local f = io.open(cfgPath .. name .. "_color.txt", "r")
        if f then
            local r = tonumber(f:read("*n")) or 255
            local g = tonumber(f:read("*n")) or 255
            local b = tonumber(f:read("*n")) or 255
            colors[name] = { r, g, b }
            f:close()
        else
            colors[name] = { 255, 255, 255 }
        end
    end
end

local function drawStatus()
    for _, name in ipairs(statusNames) do
        if name == "kblayout" and isEnabled("kbflag") then
            if fileExists("assets/statuses/kblayout.txt") == false then 
            local kbfw = io.open("assets/statuses/kblayout.txt", "w")
            kbfw:write("us")
            kbfw:close()
            end
            local layoutCode = readStatus("kblayout")
            local pos = positions["kbflag"]
            local scale = pos.scale or 1
            local flagPath = string.format("assets/flags/%s.png", layoutCode)
            if fileExists(flagPath) then
                local img = imageCache[flagPath]
                if not img then
                    img = Image.load(flagPath)
                    if img then imageCache[flagPath] = img end
                end
                if img then
                    local w = math.floor(Image.W(img) * scale)
                    local h = math.floor(Image.H(img) * scale)
                    Image.draw(img, pos.x, pos.y, w, h)
                end
            end
        elseif isEnabled(name) then
            local pos = positions[name]
            local col = colors[name]
            local color = Color.new(col[1], col[2], col[3], 255)
            local scale = pos.scale or 1
            if name == "time" then
                local t = System.getTime()
            
                t.hour = tonumber(t.hour) or 0
                t.minutes = tonumber(t.minutes) or 0
                t.seconds = tonumber(t.seconds) or 0

                local timeFormats = {
                    [1] = "%02d:%02d",           -- HH:MM (24h)
                    [2] = "%02d:%02d:%02d",      -- HH:MM:SS (24h)
                    [3] = "%02d:%02d %s",        -- HH:MM AM/PM (12h)
                    [4] = "%02d:%02d:%02d %s"    -- HH:MM:SS AM/PM (12h)
                }
            
                local formatIndex = 1
                local fmtFile = io.open(cfgPath .. "time_format.txt", "r")
                if fmtFile then
                    local num = tonumber(fmtFile:read("*l"))
                    fmtFile:close()
                    if type(num) == "number" and timeFormats[num] then
                        formatIndex = num
                    end
                end
            
                local timeStr
                if formatIndex <= 2 then
                    if formatIndex == 1 then
                        timeStr = string.format(timeFormats[1], t.hour, t.minutes)
                    else
                        timeStr = string.format(timeFormats[2], t.hour, t.minutes, t.seconds)
                    end
                else
                    local hour12 = t.hour % 12
                    if hour12 == 0 then hour12 = 12 end
                    local ampm = (t.hour < 12) and "AM" or "PM"
                    if formatIndex == 3 then
                        timeStr = string.format(timeFormats[3], hour12, t.minutes, ampm)
                    else
                        timeStr = string.format(timeFormats[4], hour12, t.minutes, t.seconds, ampm)
                    end
                end
            
                intraFont.print(pos.x, pos.y, timeStr, color, FontRegular, scale)
            else
                local st = readStatus(name)
                intraFont.print(pos.x, pos.y, name:upper() .. ": " .. (st or "unknown"), color, FontRegular, scale)
            end
        end
    end
end

local function drawImages()
    local files = System.listDir("assets/imgs")
    for _, file in ipairs(files) do
        local filename = file.name
        local name = filename:match("(.+)%..+$")
        if name then
            local cfg = cfgPath .. name .. "_img.txt"
            local f = io.open(cfg, "r")
            if f then
                local visible = f:read("*l")
                local x = tonumber(f:read("*l")) or 20
                local y = tonumber(f:read("*l")) or 20
                local scaleX = tonumber(f:read("*l")) or 1.0
                local scaleY = tonumber(f:read("*l")) or 1.0
                f:close()
                if visible == "on" then
                    if not imageCache[filename] then
                        local img = Image.load("assets/imgs/" .. filename)
                        if img then imageCache[filename] = img end
                    end
                    local img = imageCache[filename]
                    if img then
                        local w = math.floor(Image.W(img) * scaleX)
                        local h = math.floor(Image.H(img) * scaleY)
                        Image.draw(img, x, y, w, h)
                    end
                end
            end
        end
    end
end

loadPositions()
loadColors()

while true do
    buttons.read()
    if buttons.pressed(buttons.circle) then
        for _, img in pairs(imageCache) do
            Image.unload(img)
        end
        imageCache = {}
        break
    end
    screen.clear()
    drawStatus()
    drawImages()
    screen.flip()
    LUA.sleep(100)
end
