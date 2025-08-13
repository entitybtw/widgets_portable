require("MenuList")
require("Fonts")

local toggleStates = {
    ram = false,
    cpu = false,
    gpu = false,
    kblayout = false,
    kbflag = false,
    time = false,
}

local imageStates = {}

local function loadToggleStates()
    for name, _ in pairs(toggleStates) do
        local filePath = string.format("assets/cfg/%s.txt", name)
        local f = io.open(filePath, "r")
        if f then
            local status = f:read("*l")
            f:close()
            toggleStates[name] = (status == "on")
        else
            toggleStates[name] = false
        end
    end
end

local function loadImageStates()
    imageStates = {}
    local files = System.listDir("assets/imgs")
    for _, file in ipairs(files) do
        local filename = file.name
        local name = filename:match("(.+)%..+$")
        if name then
            local cfg = "assets/cfg/" .. name .. "_img.txt"
            local visible = false
            local f = io.open(cfg, "r")
            if f then
                local status = f:read("*l")
                visible = (status == "on")
                f:close()
            end
            imageStates[name] = visible
        end
    end
end

local function toggleOption(name)
    toggleStates[name] = not toggleStates[name]
    local namefw = io.open("assets/cfg/" .. name .. ".txt", "w")
    if toggleStates[name] then
        namefw:write("on")
        namefw:close()
    else
        System.removeFile("assets/cfg/" .. name .. ".txt")
    end
end

local function toggleImage(name)
    local cfg = "assets/cfg/" .. name .. "_img.txt"
    local visible = not imageStates[name]
    imageStates[name] = visible
    local x, y, scale = 20, 20, 1.0
    local f = io.open(cfg, "r")
    if f then
        f:read("*l")
        x = tonumber(f:read("*l")) or 20
        y = tonumber(f:read("*l")) or 20
        scale = tonumber(f:read("*l")) or 1.0
        f:close()
    end
    local fw = io.open(cfg, "w")
    fw:write((visible and "on" or "off") .. "\n")
    fw:write(x .. "\n" .. y .. "\n" .. scale .. "\n")
    fw:close()
end

loadToggleStates()
loadImageStates()

local menuItems = {
    { name = "Display info", action = function() dofile("./display.lua") end },
    {
        name = "Settings",
        submenu = {
            {
                name = function() return "RAM display [" .. (toggleStates.ram and "ON" or "OFF") .. "]" end,
                action = function() toggleOption("ram") end
            },
            {
                name = function() return "CPU display [" .. (toggleStates.cpu and "ON" or "OFF") .. "]" end,
                action = function() toggleOption("cpu") end
            },
            {
                name = function() return "GPU display [" .. (toggleStates.gpu and "ON" or "OFF") .. "]" end,
                action = function() toggleOption("gpu") end
            },
            {
                name = function() return "Kb-layout display [" .. (toggleStates.kblayout and "ON" or "OFF") .. "]" end,
                action = function() toggleOption("kblayout") end
            },
            {
                name = function() return "Kb-layout flag [" .. (toggleStates.kbflag and "ON" or "OFF") .. "]" end,
                action = function() toggleOption("kbflag") end
            },
            {
                name = function() return "Time display [" .. (toggleStates.time and "ON" or "OFF") .. "]" end,
                action = function() toggleOption("time") end
            },
            {
                name = "Images",
                submenu = (function()
                    local list = {}
                    for name, _ in pairs(imageStates) do
                        table.insert(list, {
                            rawName = name,
                            name = function()
                                return string.format("%s [%s]", name, imageStates[name] and "ON" or "OFF")
                            end,
                            action = function()
                                toggleImage(name)
                            end
                        })
                    end
                    table.insert(list, { name = "Back" })
                    return list
                end)()
            },
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
    if buttons.pressed(buttons.triangle) then
        local selected = list[idx]
        if type(selected.name) == "function" then
            local nameStr = selected.name()
            for stat, _ in pairs(toggleStates) do
                if nameStr:lower():gsub("-", ""):find(stat) then
                    _CURRENT_EDIT_COLOR = stat
                    dofile("color_editor.lua")
                    return
                end
            end
        end
    end
    if buttons.pressed(buttons.select) then
        local selected = list[idx]
        if type(selected.name) == "function" then
            local nameStr = selected.name()
            if nameStr:lower():gsub("-", ""):find("time") then
                dofile("time_editor.lua")
                return
            end
        end
    end    
    if buttons.pressed(buttons.square) then
        local selected = list[idx]
        if type(selected.name) == "function" then
            local nameStr = selected.name()
            for stat, _ in pairs(toggleStates) do
                if nameStr:lower():gsub("-", ""):find(stat) then
                    if stat == "kblayout" then
                        if toggleStates.kbflag then
                            _CURRENT_EDIT_POS = "kbflag_img"
                        else
                            _CURRENT_EDIT_POS = "kblayout"
                        end
                    else
                        _CURRENT_EDIT_POS = stat
                    end
                    dofile("size_pos_editor.lua")
                    return
                end
            end                     
            for imgName, _ in pairs(imageStates) do
                if nameStr:lower():find(imgName) then
                    _CURRENT_EDIT_POS = imgName .. "_img"
                    dofile("size_pos_editor.lua")
                    return
                end
            end
            if selected.rawName and imageStates[selected.rawName] ~= nil then
                _CURRENT_EDIT_POS = selected.rawName .. "_img"
                dofile("size_pos_editor.lua")
                return
            end
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
        screen.filledRect(x + offsetX - 10, 0, 272, 480, Color.new(0, 0, 0, math.floor(alpha * 0.8)))
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
            local text = item.name
            if type(text) == "function" then
                text = text()
            end
            intraFont.print(x + offsetX, baseY + (j - 1) * 22, text, col, FontRegular, entry.size)
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
