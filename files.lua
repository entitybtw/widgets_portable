function fileExists(filePath)
    local file = io.open(filePath, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end