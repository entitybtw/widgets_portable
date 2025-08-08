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
    for i, name in ipairs(statusNames) do
        local f = io.open(cfgPath .. name .. ".txt", "r")
        if f then
            visible = f:read("*l") or "off"
            local x = tonumber(f:read("*l")) or 20
            local y = tonumber(f:read("*l")) or 20
            local scaleX = tonumber(f:read("*l")) or 1
            local scaleY = tonumber(f:read("*l")) or 1
            positions[name] = { x = x, y = y, scale = math.max(scaleX, scaleY) }
            f:close()
        else
            positions[name] = { x = 20, y = 20 + (i - 1) * 20, scale = 1 }
        end     
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
        if isEnabled(name) then
            local pos = positions[name]
            local col = colors[name]
            local color = Color.new(col[1], col[2], col[3], 255)
            local scale = pos.scale or 1

            if name == "time" then
                local t = System.getTime()
                local timeStr = string.format("Time: %02d:%02d:%02d %02d/%02d/%04d", t.hour, t.minutes, t.seconds, t.day, t.month, t.year)
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
                        if img then
                            imageCache[filename] = img
                        end
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
