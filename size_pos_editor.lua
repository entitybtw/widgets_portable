local stat = _CURRENT_EDIT_POS
if not stat then error("No stat provided") end

local cfgPath = "assets/cfg/"
local statusPath = "assets/statuses/"
local imgPath = "assets/imgs/"
local cfgFile = string.format("%s%s.txt", cfgPath, stat)

local visible = "on"
local step = 14
local x, y, scaleX, scaleY = 20, 20, 1.0, 1.0

local displayName = stat:gsub("_img$", ""):upper()
local rawName = stat:lower():gsub("_img$", "")

local f = io.open(cfgFile, "r")
if f then
    visible = f:read("*l") or "off"
    x = tonumber(f:read("*l")) or 20
    y = tonumber(f:read("*l")) or 20
    scaleX = tonumber(f:read("*l")) or 1.0
    scaleY = tonumber(f:read("*l")) or 1.0
    f:close()
else
    local statusNames = { "cpu", "ram", "gpu", "kblayout", "time" }
    for i, name in ipairs(statusNames) do
        if rawName == name then
            y = 20 + (i - 1) * step
            break
        end
    end
    if rawName == "kbflag" then
        y = 20 + #statusNames * step
    end
end

local colorPath = string.format("%s%s_color.txt", cfgPath, rawName)
local textColor = Color.new(255, 255, 255, 255)
local cf = io.open(colorPath, "r")
if cf then
    local r = tonumber(cf:read("*n")) or 255
    local g = tonumber(cf:read("*n")) or 255
    local b = tonumber(cf:read("*n")) or 255
    textColor = Color.new(r, g, b, 255)
    cf:close()
end

local imgFile
if rawName == "kbflag" then
    local ff = io.open(statusPath .. "kblayout.txt", "r")
    local code = ff and ff:read("*l") or "us"
    if ff then ff:close() end
    imgFile = string.format("assets/flags/%s.png", code)
else
    imgFile = imgPath .. rawName .. ".png"
end

local img = nil
local hasImage = false
local check = io.open(imgFile, "rb")
if check then
    check:close()
    img = Image.load(imgFile)
    hasImage = img ~= nil
end

local done = false
local moveStep = 4
local scaleStep = 0.05
local preciseMode = false
local editingXScale = true

while not done do
    buttons.read()
    screen.clear()
    local header = hasImage and "Editing image: " or "Editing object: "
    intraFont.print(20, 10, header .. displayName, Color.new(255, 255, 255, 255), FontRegular, 1)
    intraFont.print(20, 40, "Visible: " .. visible, Color.new(255, 255, 255, 255), FontRegular, 1)
    intraFont.print(20, 60, "X: " .. x, Color.new(255, 255, 255, 255), FontRegular, 1)
    intraFont.print(20, 80, "Y: " .. y, Color.new(255, 255, 255, 255), FontRegular, 1)
    intraFont.print(20, 100, "Scale X: " .. string.format("%.2f", scaleX), Color.new(255, 255, 255, 255), FontRegular, 1)
    intraFont.print(20, 120, "Scale Y: " .. string.format("%.2f", scaleY), Color.new(255, 255, 255, 255), FontRegular, 1)
    intraFont.print(20, 150, "D-pad: Move | L/R: Scale | X: Precise mode (" .. (preciseMode and "ON" or "OFF") .. ")\n\nTriangle: Visible | Circle: Save & Exit", Color.new(255, 255, 255, 255), FontRegular, 0.85)
    
    if preciseMode then
        intraFont.print(20, 140, "Editing: " .. (editingXScale and "Scale X" or "Scale Y"), Color.new(255, 255, 0, 255), FontRegular, 1)
    end
    
    if visible == "on" then
        if hasImage then
            local renderScaleX = (rawName == "kbflag" or stat:match("_img$")) and scaleX or scaleX
            local renderScaleY = (rawName == "kbflag" or stat:match("_img$")) and scaleY or scaleY
            local w = math.floor(Image.W(img) * renderScaleX)
            local h = math.floor(Image.H(img) * renderScaleY)
            Image.draw(img, x, y, w, h)            
        else
            intraFont.print(x, y, displayName, textColor, FontRegular, (scaleX + scaleY) / 2)
        end
    end
    
    screen.flip()
    if buttons.held(buttons.left) then x = x - moveStep end
    if buttons.held(buttons.right) then x = x + moveStep end
    if buttons.held(buttons.up) then y = y - moveStep end
    if buttons.held(buttons.down) then y = y + moveStep end
    
    if preciseMode then
        if editingXScale then
            if buttons.held(buttons.l) then scaleX = math.max(0.1, scaleX - scaleStep) end
            if buttons.held(buttons.r) then scaleX = scaleX + scaleStep end
        else
            if buttons.held(buttons.l) then scaleY = math.max(0.1, scaleY - scaleStep) end
            if buttons.held(buttons.r) then scaleY = scaleY + scaleStep end
        end
        
        if buttons.pressed(buttons.up) and buttons.held(buttons.cross) then
            editingXScale = true
        end
        if buttons.pressed(buttons.down) and buttons.held(buttons.cross) then
            editingXScale = false
        end
    else
        if buttons.held(buttons.l) then
            scaleX = math.max(0.1, scaleX - scaleStep)
            scaleY = math.max(0.1, scaleY - scaleStep)
        end
        if buttons.held(buttons.r) then
            scaleX = scaleX + scaleStep
            scaleY = scaleY + scaleStep
        end
    end
    
    if buttons.pressed(buttons.triangle) then
        visible = (visible == "on") and "off" or "on"
    end
    
    if buttons.pressed(buttons.cross) and not buttons.held(buttons.up) and not buttons.held(buttons.down) then
        preciseMode = not preciseMode
    end
    
    if buttons.pressed(buttons.circle) then
        local fw = io.open(cfgFile, "w")
        if fw then
            fw:write(visible .. "\n")
            fw:write(x .. "\n")
            fw:write(y .. "\n")
            fw:write(string.format("%.2f\n", scaleX))
            fw:write(string.format("%.2f\n", scaleY))
            fw:close()
        end
        done = true
    end
    LUA.sleep(20)
end