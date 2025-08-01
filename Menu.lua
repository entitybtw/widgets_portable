require("MenuList")
require("Fonts")


local menuItems = {
    { name = "Display info", action = function() dofile("./display.lua") end },
    {
        name = "Settings",
        submenu = {
            { name = "Toggle RAM display", action = function() print("Option 1") end },
            { name = "Toggle CPU display", action = function() print("Option 2") end },
            { name = "Toggle GPU display", action = function() print("Option 3") end },
            { name = "Toggle kb-layout display", action = function() print("Option 4") end },
            { name = "Toggle time display", action = function() print("Option 5") end },
            { name = "Back" }
        }
    },
    { name = "Exit", action = function() os.exit() end }
}

local menuStack = {}
table.insert(menuStack, { list = menuItems, currentIdx = 1, animProgress = 1, direction = 1 })

local function processInput(dt)
    local top = menuStack[#menuStack]
    if top.closing then return end

    local list, idx = top.list, top.currentIdx
    if buttons.pressed(buttons.up) then
        sound.playEasy("assets/sounds/option.wav", sound.WAV_1)
        idx = (idx - 2) % #list + 1
    elseif buttons.pressed(buttons.down) then
        sound.playEasy("assets/sounds/option.wav", sound.WAV_1)
        idx = idx % #list + 1
    end
    top.currentIdx = idx

    if buttons.pressed(buttons.cross) then
        sound.playEasy("assets/sounds/option.wav", sound.WAV_1)
        local selected = list[idx]
        if selected.submenu then
            table.insert(menuStack, { list = selected.submenu, currentIdx = 1, animProgress = 0, direction = 1 })
        elseif selected.action then
            selected.action()
        elseif selected.name == "Back" and #menuStack > 1 then
            top.closing = true
            top.direction = -1
        end
    end

    if buttons.pressed(buttons.circle) then
        sound.playEasy("assets/sounds/cancel.wav", sound.WAV_1)
        if #menuStack > 1 then
            top.closing = true
            top.direction = -1
        else
            os.exit()
        end
    end
end

local function updateAnimation(dt)
    local top = menuStack[#menuStack]
    if top.closing then
        top.animProgress = math.max(0, top.animProgress - dt * 5)
        if top.animProgress == 0 then
            table.remove(menuStack)
        end
    elseif top.animProgress < 1 then
        top.animProgress = math.min(1, top.animProgress + dt * 5)
    end
end

local function drawMenu(x, y, width)
    local baseY = y + 30

    for i, menu in ipairs(menuStack) do
        local prog = menu.animProgress
        local dir = menu.direction or 1
        local offsetX = (i - #menuStack) * width * (1 - prog) * dir
        local alpha = math.floor(255 * prog)

        screen.filledRect(x + offsetX - 10, 0, width + 20, 272, Color.new(0, 0, 0, math.floor(alpha * 0.8)))

        for j, item in ipairs(menu.list) do
            local isSelected = (j == menu.currentIdx)
            local targetSize = isSelected and 1.2 or 1
            local targetAlpha = isSelected and 255 or alpha * 0.7

            menu[j] = menu[j] or {}
            local entry = menu[j]
            entry.size = entry.size or 1
            entry.alpha = entry.alpha or 0

            entry.size = entry.size + (targetSize - entry.size) * 0.2
            entry.alpha = entry.alpha + (targetAlpha - entry.alpha) * 0.2

            local col = Color.new(255, 255, 255, math.floor(entry.alpha))
            intraFont.print(x + offsetX, baseY + (j - 1) * 22, item.name, col, FontRegular, entry.size)
        end
    end
end

while true do
    buttons.read()
    local dt = 1 / 60

    processInput(dt)
    updateAnimation(dt)

    screen.clear()
    drawMenu(120, 70, 200)
    intraFont.print(120, 70, "widgets_portable 0.1", White, FontRegular, 1)
    screen.flip()
end
