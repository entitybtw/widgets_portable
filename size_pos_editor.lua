local stat = _CURRENT_EDIT_POS
if not stat then error("No stat provided") end

local cfgPath = "assets/cfg/"
local imgPath = "assets/imgs/"
local cfgFile = string.format("%s%s.txt", cfgPath, stat)

local visible = "off"
local x, y = 20, 20
local scale = 1.0

local displayName = stat:gsub("_img$", ""):upper()
local rawName = stat:lower():gsub("_img$", "")

local f = io.open(cfgFile, "r")
if f then
    visible = f:read("*l") or "off"
    x = tonumber(f:read("*l")) or 20
    y = tonumber(f:read("*l")) or 20
    scale = tonumber(f:read("*l")) or 1.0
    f:close()
end

local imgFile = imgPath .. rawName .. ".png"
local img = nil
local hasImage = false

local check = io.open(imgFile, "rb")
if check then
    check:close()
    img = Image.load(imgFile)
    hasImage = img ~= nil
end

local done = false
local step = 4
local scaleStep = 0.05

while not done do
    buttons.read()
    screen.clear()

    local header = hasImage and "Editing image: " or "Editing object: "
    intraFont.print(20, 10, header .. displayName, White, FontRegular, 1)

    intraFont.print(20, 40, "Visible: " .. visible, White, FontRegular, 1)
    intraFont.print(20, 60, "X: " .. x, White, FontRegular, 1)
    intraFont.print(20, 80, "Y: " .. y, White, FontRegular, 1)
    intraFont.print(20, 100, "Scale: " .. string.format("%.2f", scale), White, FontRegular, 1)
    intraFont.print(20, 130, "D-pad: Move | L/R: Scale | X/O: Save & Exit |\n\nTriangle: Toggle Visible", White, FontRegular, 0.85)

    if visible == "on" then
        if hasImage then
            local w = math.floor(Image.W(img) * scale)
            local h = math.floor(Image.H(img) * scale)
            Image.draw(img, x, y, w, h)
        else
            intraFont.print(x, y, displayName, Red, FontRegular, scale)
        end
    end

    screen.flip()

    if buttons.held(buttons.left) then x = x - step end
    if buttons.held(buttons.right) then x = x + step end
    if buttons.held(buttons.up) then y = y - step end
    if buttons.held(buttons.down) then y = y + step end

    if buttons.held(buttons.l) then scale = math.max(0.1, scale - scaleStep) end
    if buttons.held(buttons.r) then scale = scale + scaleStep end

    if buttons.pressed(buttons.triangle) then
        visible = (visible == "on") and "off" or "on"
    end

    if buttons.pressed(buttons.cross) or buttons.pressed(buttons.circle) then
        local fw = io.open(cfgFile, "w")
        if fw then
            fw:write(visible .. "\n")
            fw:write(x .. "\n")
            fw:write(y .. "\n")
            fw:write(string.format("%.2f\n", scale))
            fw:close()
        end
        done = true
    end

    LUA.sleep(20)
end
