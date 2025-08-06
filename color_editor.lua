local stat = _CURRENT_EDIT_COLOR
if not stat then error("No stat provided") end

local path = string.format("assets/cfg/%s_color.txt", stat)
local r, g, b = 255, 255, 255

local f = io.open(path, "r")
if f then
    r = tonumber(f:read("*n")) or 255
    g = tonumber(f:read("*n")) or 255
    b = tonumber(f:read("*n")) or 255
    f:close()
end

local component = 1
local comps = { r, g, b }

while true do
    buttons.read()
    screen.clear()

    intraFont.print(20, 10, "Editing: " .. stat:upper(), White, FontRegular, 1)

    for i = 1, 3 do
        local value = comps[i]
        local name = (i == 1 and "R") or (i == 2 and "G") or "B"
        local prefix = (i == component) and "-> " or "   "
        intraFont.print(20, 30 + (i - 1) * 20, prefix .. name .. ": " .. value, White, FontRegular, 1)
    end

    local colorPreview = Color.new(comps[1], comps[2], comps[3], 255)
    screen.filledRect(180, 30, 60, 60, colorPreview)

    intraFont.print(20, 100, "Sample Text", colorPreview, FontRegular, 1)

    intraFont.print(20, 130, "X/O: Save & Exit", White, FontRegular, 1)
    screen.flip()

    if buttons.pressed(buttons.up) then
        component = (component - 2) % 3 + 1
    elseif buttons.pressed(buttons.down) then
        component = (component % 3) + 1
    elseif buttons.held(buttons.left) then
        comps[component] = math.max(0, comps[component] - 5)
    elseif buttons.held(buttons.right) then
        comps[component] = math.min(255, comps[component] + 5)
    elseif buttons.pressed(buttons.cross) then
        local fw = io.open(path, "w")
        fw:write(table.concat(comps, " "))
        fw:close()
        break
    elseif buttons.pressed(buttons.circle) then
        local fw = io.open(path, "w")
        fw:write(table.concat(comps, " "))
        fw:close()
        break
    end

    LUA.sleep(20)
end
