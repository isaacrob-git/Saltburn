Audio = {}

Audio.sfx = {}
Audio.music = {}
Audio.currentMusic = nil

function Audio.load()

    Audio.music.menu =
        love.audio.newSource("assets/sounds/menu.ogg", "stream")

    Audio.music.menu:setLooping(true)
    
    Audio.music.game =
        love.audio.newSource("assets/sounds/game.mp3", "stream")

    Audio.music.menu:setLooping(true)

    Audio.sfx.menuMove =
    love.audio.newSource("assets/sounds/select.wav", "static")

    --Run
    Audio.sfx.run1 = love.audio.newSource("assets/sounds/run1.wav", "static")
    Audio.sfx.run2 = love.audio.newSource("assets/sounds/run2.wav", "static")
    Audio.sfx.run3 = love.audio.newSource("assets/sounds/run3.wav", "static")
    Audio.sfx.run4 = love.audio.newSource("assets/sounds/run4.wav", "static")
    Audio.sfx.run5 = love.audio.newSource("assets/sounds/run5.wav", "static")

    --Salida
    Audio.sfx.jumpPre1 = love.audio.newSource("assets/sounds/jump_pre1.wav", "static")
    Audio.sfx.jumpPre2 = love.audio.newSource("assets/sounds/jump_pre2.wav", "static")
    Audio.sfx.jumpPre3 = love.audio.newSource("assets/sounds/jump_pre3.wav", "static")
    Audio.sfx.jumpPre4 = love.audio.newSource("assets/sounds/jump_pre4.wav", "static")
    Audio.sfx.jumpPre5 = love.audio.newSource("assets/sounds/jump_pre5.wav", "static")
end


function Audio.playSound(name)

    local sound = Audio.sfx[name]

    if sound then
        sound:stop()
        sound:play()
    end

end


function Audio.playMusic(name)

    if Audio.currentMusic == name then
        return
    end

    if Audio.currentSource then
        Audio.currentSource:stop()
    end

    local music = Audio.music[name]

    if music then

        Audio.currentSource = music
        Audio.currentMusic = name

        music:play()

    end
end

function Audio.pauseMusic()

    if Audio.currentSource then
        Audio.currentSource:pause()
    end

end

function Audio.resumeMusic()

    if Audio.currentSource then
        Audio.currentSource:play()
    end

end

function Audio.playRandomRun()

    local index = math.random(1, 5)
    local sound = Audio.sfx["run" .. index]

    if sound then
        sound:stop()
        sound:play()
    end

end

function Audio.playRandomJumpPre()

    local random = math.random(1, 5)

    Audio.playSound("jumpPre" .. random)

end


return Audio