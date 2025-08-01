function sound.playEasy(path, channel, loop, loadToRAM)
    if type(path) ~= "string" then return end

    if type(loadToRAM) ~= "boolean" then
        loadToRAM = false
    end

    if type(loop) ~= "boolean" then
        loop = false
    end

    sound.cloud(path, channel, loadToRAM)
    sound.play(channel, loop)
end