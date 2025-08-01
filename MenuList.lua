local floor = math.floor

local black = Black

---@type ColorInstance[]
local fontColors = {}
for i = 0, 255 do
    fontColors[i] = Color.new(255, 255, 255, i)
end

MenuList = {
    ---@param list string[]
    ---@param onOpened? fun(opened: string)
    ---@param onClosed? fun()
    ---@return { Render:fun(x:number, y:number, textAlpha?:number), GoBack:fun() }
    Create = function(list, onOpened, onClosed)
        local currentIdx = 1
        local currentIdxDraw = 1
        local opened = nil
        local holdDelayCounter = 0


        local drawInfo = {}
        for i, name in pairs(list) do
            drawInfo[i] = { fontSize = 0.75, colorNum = 128 }
        end

        local function processButtons()
            if opened then return end
            local heldUp, heldDown = buttons.held(buttons.up), buttons.held(buttons.down)
            local pressUp, pressDown = heldUp and holdDelayCounter == 1, heldDown and holdDelayCounter == 1

            if (pressUp or (heldUp and holdDelayCounter > 30)) and currentIdx > 1 then
                currentIdx = currentIdx - 1
            end
            if (pressDown or (heldDown and holdDelayCounter > 30)) and currentIdx < #list then
                currentIdx = currentIdx + 1
            end

            if heldUp or heldDown then
                holdDelayCounter = holdDelayCounter + 1
            else
                holdDelayCounter = 0
            end

            if holdDelayCounter > 31 then
                holdDelayCounter = 29
            end

            if buttons.held(buttons.cross) and onOpened then
                opened = list[currentIdx]
                onOpened(opened)
            end
            if buttons.held(buttons.circle) and onClosed then
                onClosed()
            end
        end

        return {
            Render = function(x, y, textAlpha)
                textAlpha = textAlpha or 255
                processButtons()
                currentIdxDraw = currentIdxDraw + (currentIdx - currentIdxDraw) * 0.2

                for i, name in pairs(list) do
                    local info = drawInfo[i]

                    if i == currentIdx and not opened then
                        info.fontSize = info.fontSize + 0.05
                        if info.fontSize > 1.2 then info.fontSize = 1.2 end
                        info.colorNum = info.colorNum + 8
                        if info.colorNum > 255 then info.colorNum = 255 end
                    else
                        info.fontSize = info.fontSize - 0.05
                        if info.fontSize < 0.75 then info.fontSize = 0.75 end
                        info.colorNum = info.colorNum - 8
                        if info.colorNum < 128 then info.colorNum = 128 end
                    end

                    local alpha = math.floor(info.colorNum - (255 - textAlpha))
                    if alpha > 255 then alpha = 255 end
                    if alpha > 0 then
                        local col = Color.new(255, 255, 255, alpha)
                        intraFont.print(x, y + 20 * (i - currentIdxDraw) - 2, name, col, FontRegular, info.fontSize)
                    end
                end

            end,

            GoBack = function()
                opened = nil
            end
        }
    end
}
