local sti = require("libraries.sti")

function checkCollision(a, b)

    return (
        a.x < b.x + b.width and
        a.x + a.width > b.x and
        a.y < b.y + b.height and
        a.y + a.height > b.y
    )

end

function formatTime(seconds)

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = math.floor(seconds % 60)

    return string.format(
        "%02d:%02d:%02d",
        hours,
        minutes,
        remainingSeconds
    )

end

function showNotification(text, duration)

    notificationText = text
    notificationTimer = duration

end

function tableToString(tbl)

    local result = "{"

    for key, value in pairs(tbl) do

        result = result ..
            "[" .. string.format("%q", key) .. "]="

        if type(value) == "table" then

            result =
                result ..
                tableToString(value)

        elseif type(value) == "string" then

            result =
                result ..
                string.format("%q", value)

        else

            result =
                result ..
                tostring(value)

        end

        result = result .. ","

    end

    return result .. "}"

end

--Guardar partida
function saveGame(slot)

    local saveData = {

        room = currentRoom,

        player = {
            x = player.x,
            y = player.y,
            facing = player.facing
        },

        statistics = {
            playTime = gameTime,
            jumps = jumpCount
        }

    }

    local serialized =
        "return " .. tableToString(saveData)

   
    local success = love.filesystem.write(
        "save" .. slot .. ".lua",
        serialized
    )

    if success then

        showNotification(
            "Partida guardada",
            3
        )

    else

        showNotification(
            "Error al guardar",
            3
        )

    end

end

--Cargar partida
function loadGame(slot)

    if not love.filesystem.getInfo("save" .. slot .. ".lua") then

        showNotification(
            "No existe una partida guardada.",
            3
        )

        return false

    end

    local chunk =
        love.filesystem.load(
            "save" .. slot .. ".lua"
        )

    local saveData = chunk()

    currentRoom = saveData.room
    loadRoom(currentRoom)

    player.x = saveData.player.x
    player.y = saveData.player.y
    player.facing = saveData.player.facing

    player.velocityX = 0
    player.velocityY = 0

    player.isGrounded = false
    player.isCharging = false
    player.chargeTime = 0
    setState("idle")
    Audio.playMusic("game")


    gameTime = saveData.statistics.playTime
    jumpCount = saveData.statistics.jumps

    showNotification(
        "Partida cargada correctamente.",
        3
    )

    return true

end

--Seleccionar partida
function newGame()

    currentRoom = 1
    loadRoom(currentRoom)

    player.x = 380
    player.y = 280

    player.velocityX = 0
    player.velocityY = 0

    player.isGrounded = false
    player.isCharging = false
    player.chargeTime = 0

    player.facing = 1

    gameTime = 0
    jumpCount = 0

    setState("idle")

    gameState = "playing"
    Audio.playMusic("game")

end

function saveExists(slot)

    return love.filesystem.getInfo(
        "save" .. slot .. ".lua"
    ) ~= nil

end

function love.load()

    
    Audio = require("audioManager")


    --sonido
    audioVolume = {
        master = 0.7,
        music = 0.8,
        sfx = 0.5
    }
    
    Audio.load()

    love.graphics.setDefaultFilter(
        "nearest",
        "nearest"
    )

    player = {
        x = 380,
        y = 280,
        width = 32,
        height = 48,
        speed = 500,
        velocityY = 0,
        velocityX = 0,
        jumpPower = 0,
        isGrounded = false,
        isCharging = false,
        chargeTime = 0,
        facing = 1,
        spriteOffsetX = 13,
        spriteOffsetY = -70,
        wasGrounded = false
        
        
    }
    --Canvas
    virtualWidth = 800
    virtualHeight = 600
    --Canvas

    menuBackgrounds =
    loadBackground("menu")

    gameState = "menu"
    Audio.playMusic("menu")

    --menu
    menuOptions = {
        "Nueva Partida",
        "Continuar",
        "Opciones",
        "Salir"
    }

    selectedOption = 1

    --pausa
    pauseOptions = {
        "Continuar",
        "Guardar Partida",
        --"Cargar Partida",
        "Opciones",
        "Salir al Menu"
    }

    selectedPauseOption = 1

    


    player.animations = {}

    player.animations.idle = {
        image = love.graphics.newImage("assets/player/idle.png"),
        frames = {},
        currentFrame = 1,
        timer = 0,
        speed = 0.15
    }

    player.animations.charge = {
        image = love.graphics.newImage("assets/player/idle.png"),
        frames = {},
        currentFrame = 1,
        timer = 0,
        speed = 0.15
    }

    player.animations.run = {
        image = love.graphics.newImage("assets/player/run.png"),
        frames = {},
        currentFrame = 1,
        timer = 0,
        speed = 0.06
    }

    player.animations.jump = {
        image = love.graphics.newImage("assets/player/jump.png"),
        frames = {},
        currentFrame = 1,
        timer = 0,
        speed = 0.2
    }

    player.animations.turnaround = {
        image = love.graphics.newImage("assets/player/run-turnaround.png"),
        frames = {},
        currentFrame = 1,
        timer = 0,
        speed = 0.06
    }


    local function generateFrames(animation, frameCount)

        for i = 0, frameCount - 1 do

                table.insert(
                    animation.frames,

                    love.graphics.newQuad(
                        i * 80,
                        0,
                        80,
                        80,
                        animation.image:getDimensions()
                    )
                )

         end

    end

    

    generateFrames(player.animations.idle, 18)
    generateFrames(player.animations.charge, 18)
    generateFrames(player.animations.run, 24)
    generateFrames(player.animations.jump, 17)
    generateFrames(player.animations.turnaround, 5)

    setState("idle")
    setState("run")
    setState("jump")


    rooms = {
        "maps/room1.lua",
        "maps/room2.lua",
        "maps/room3.lua",
        "maps/room4.lua",
        "maps/room5.lua",
        "maps/room6.lua",
        "maps/room7.lua"
        
    }

        roomBackgrounds = {
        [1] = "forest",
        [2] = "forest2",
        [3] = "forest2",
        [4] = "forest2",
        [5] = "forest2",
        [6] = "forest2",
        [7] = "forest2"
    }

    currentRoom = 1

    platforms = {}
    
    function loadRoom(index)

        map = sti(rooms[index])

        -- Importante: el canvas interno de STI debe coincidir con el
        -- tamaño REAL de la ventana (no con la resolución virtual),
        -- si no, en pantalla completa el mapa se dibuja chiquito en
        -- la esquina superior izquierda.
        map:resize(
            love.graphics.getWidth(),
            love.graphics.getHeight()
        )

        for name, layer in pairs(map.layers) do
            print("CAPA:", name)
            print("TIPO:", layer.type)
        end

        platforms = {}

        local layer = map.layers["Collisions"]

        if layer then
            for _, obj in ipairs(layer.objects) do
                table.insert(platforms, {
                    x = obj.x,
                    y = obj.y,
                    width = obj.width,
                    height = obj.height
                })
            end
        end

        roomHeight = map.height * map.tileheight

        gameBackgrounds =
            loadBackground(
                roomBackgrounds[index]
            )


            portals = {}

            local layer = map.layers["portal"]

            if layer then
                for _, obj in ipairs(layer.objects) do
                    table.insert(portals, {
                        x = obj.x,
                        y = obj.y,
                        width = obj.width,
                        height = obj.height
                    })
                end
            end
    end

    loadRoom(currentRoom)

    verticalMultiplier = 1
    horizontalMultiplier = 0.7
    wallBounceForce = 120
    walkSpeed = 120
    gravity = 2000
    maxChargeTime = 1

    runTimer = 0
    endingTimer = 0
    -- Estadísticas de la partida
    gameTime = 0
    jumpCount = 0

    titleFont = love.graphics.newFont(
        "assets/fonts/font.ttf",
        48
    )

    menuFont = love.graphics.newFont(
        "assets/fonts/font.ttf",
        24
    )

    smallFont = love.graphics.newFont(
        "assets/fonts/font.ttf",
        14
    )

     verysmallFont = love.graphics.newFont(14)

     -- Boton tester
     debugFly = false
    

    --NOTIFICACIONES
    notificationText = ""
    notificationTimer = 0

    --opciones
        optionsMenu = {

        {
            name = "Pantalla completa",
            value = false
        },

        {
            name = "Volumen General",
            value = 70
        },

        {
            name = "Musica",
            value = 80
        },

        {
            name = "Efectos",
            value = 50
        },

        {
            name = "Volver"
        }

    }

    selectedOptionItem = 1

    optionsReturnState = "menu"
    --opciones

    applyAudioSettings()
    Audio.updateVolume(audioVolume)


end

-- Se llama automáticamente cuando la ventana cambia de tamaño
-- (incluye activar/desactivar pantalla completa). Sin esto, el
-- canvas interno de STI se queda con el tamaño viejo y el mapa
-- se ve chiquito y desplazado.
function love.resize(w, h)

    if map then
        map:resize(w, h)
    end

end

function getScreenScale()

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    local scale = math.min(
        sw / virtualWidth,
        sh / virtualHeight
    )

    local offsetX = (sw - virtualWidth * scale) / 2
    local offsetY = (sh - virtualHeight * scale) / 2

    return scale, offsetX, offsetY

end

function loadBackground(backgroundName)

    local backgrounds = {}

    for i = 1, 6 do

        backgrounds[i] =
            love.graphics.newImage(
                "assets/backgrounds/" ..
                backgroundName ..
                "/background" ..
                i ..
                ".png"
            )

    end

    return backgrounds

end

function drawBackground(backgroundSet)

    for i = 1, #backgroundSet do

        local scaleX =
            virtualWidth /
            backgroundSet[i]:getWidth()

        local scaleY =
            virtualHeight /
            backgroundSet[i]:getHeight()

        love.graphics.draw(
            backgroundSet[i],
            0,
            0,
            0,
            scaleX,
            scaleY
        )

    end

end

function updateAnimation(dt)

    local anim = player.animations[player.state]

    if #anim.frames <= 1 then
        return
    end

    anim.timer = anim.timer + dt

    if anim.timer >= anim.speed then

        anim.timer = anim.timer - anim.speed  -- ✅ FIX

        anim.currentFrame = anim.currentFrame + 1

        if anim.currentFrame > #anim.frames then
            anim.currentFrame = 1
        end

        --[[sonido correr
        if player.state == "run" then
            if anim.currentFrame == 2 or anim.currentFrame == 13 then
                Audio.playRandomRun()
            end
        end
        --]]
    end
end

function setState(newState)

    if player.state ~= newState then

        player.state = newState

        local anim = player.animations[newState]

        anim.currentFrame = 1
        anim.timer = 0

        print("Estado:", newState)

    end

end

--funcion notificacion
function drawNotification()

    if notificationTimer <= 0 then
        return
    end

    love.graphics.setFont(smallFont)

    love.graphics.setColor(1,1,1)

    local boxWidth = 360
    local boxHeight = 40

    local boxX = (800 - boxWidth) / 2
    local boxY = 540

    love.graphics.printf(
        notificationText,
        boxX,
        boxY + 10,
        boxWidth,
        "center"
)

    love.graphics.setColor(1,1,1)

end

--funcion sonido
function applyAudioSettings()

    audioVolume.master = optionsMenu[2].value / 100
    audioVolume.music  = optionsMenu[3].value / 100
    audioVolume.sfx    = optionsMenu[4].value / 100

    Audio.updateVolume(audioVolume)

end

function love.update(dt)


    player.wasGrounded = player.isGrounded
    map:update(dt)


    --notificanciones
    if notificationTimer > 0 then

        notificationTimer =
            notificationTimer - dt

        if notificationTimer < 0 then
            notificationTimer = 0
        end

    end
    --notificanciones

    --ending (tiene que actualizarse aunque gameState ya no sea "playing")
    if gameState == "ending" then

        endingTimer = endingTimer + dt
        print("ENDING:", endingTimer)

        if endingTimer > 5 then
            gameState = "menu"
            currentRoom = 1
            loadRoom(currentRoom)
            endingTimer = nil
        end

        return
    end
    --ending

    if gameState ~= "playing" then
        return
    end

    if gameState == "playing" then
        gameTime = gameTime + dt
    end

    if gameState == "paused" then
        return
    end


    if gameState == "menu" then

        for _, layer in ipairs(parallax) do

            layer.x =
                layer.x - layer.speed * dt

            if layer.x <=
                -layer.image:getWidth() then

                layer.x = 0

            end

        end

        return

    end


    --modo tester
    if debugFly then

        local flySpeed = 300

        if love.keyboard.isDown("i") then
            player.y = player.y - flySpeed * dt
        end

        if love.keyboard.isDown("k") then
            player.y = player.y + flySpeed * dt
        end

        if love.keyboard.isDown("j") then
            player.x = player.x - flySpeed * dt
        end

        if love.keyboard.isDown("l") then
            player.x = player.x + flySpeed * dt
        end

        return

    end
    --modo tester


    updateAnimation(dt)
    player.previousX = player.x
    player.previousY = player.y


    if player.isCharging then

            setState("charge")

        elseif not player.isGrounded then

            setState("jump")

        elseif love.keyboard.isDown("a")
            or love.keyboard.isDown("d") then

            setState("run")

        else

            setState("idle")

    end

    if player.isGrounded 
        and not player.isCharging then

        local isMoving = false

        if love.keyboard.isDown("a") then

            player.x = player.x - walkSpeed * dt
            player.facing = -1
            isMoving = true

        end

        if love.keyboard.isDown("d") then

            player.x = player.x + walkSpeed * dt
            player.facing = 1
            isMoving = true

        end



    end


    player.x =
        player.x + player.velocityX * dt
    
    
    if player.x < 0 then

        player.x = 0

        if not player.isGrounded then

            player.velocityX =
            math.abs(player.velocityX) * 0.7
            
        end
    end

    if player.x + player.width > 800 then

        player.x = 800 - player.width

        if not player.isGrounded then

             player.velocityX =
                -math.abs(player.velocityX) * 0.7

        end

    end

    player.isGrounded = false
    player.velocityY = player.velocityY + gravity * dt
    player.y = player.y + player.velocityY * dt

    for _, platform in ipairs(platforms) do

        if checkCollision(player, platform) then

            local fromTop =
                player.previousY + player.height <= platform.y

            local fromBottom =
                player.previousY >= platform.y + platform.height

            local fromLeft =
                player.previousX + player.width <= platform.x

            local fromRight =
                player.previousX >= platform.x + platform.width

            if fromTop then

                player.y =
                    platform.y - player.height

                player.velocityY = 0
                player.velocityX = 0
                player.isGrounded = true

            end

            if fromBottom then

                player.y =
                    platform.y + platform.height

                player.velocityY = 0

            end

            if fromLeft then

                player.x =
                    platform.x - player.width - 2

                player.velocityX =
                    -wallBounceForce

            end

            if fromRight then

                player.x =
                    platform.x + platform.width + 2

                player.velocityX =
                    wallBounceForce

            end

        end

    end

    if player.isGrounded and not player.wasGrounded then
        Audio.playRandomLand()
    end

    if player.isCharging then
        player.chargeTime =
            player.chargeTime + dt
    end

    if player.chargeTime > maxChargeTime then
        player.chargeTime = maxChargeTime
    end



    -- subir de room
    if player.y + player.height < 0 then

        if currentRoom < #rooms then

            currentRoom = currentRoom + 1

            loadRoom(currentRoom)

            player.y = 600 - player.height - 10

        else

            player.y = 0

        end

    end

    -- bajar de room
    if player.y > 600 then

        if currentRoom > 1 then

            currentRoom = currentRoom - 1

            loadRoom(currentRoom)

            player.y = 10

        else

            player.y = 600 - player.height

        end

    end

    --portal
    for _, p in ipairs(portals) do
        if checkCollision(player, p) then

            gameState = "ending"
            endingTimer = 0

            return -- el timer del ending se maneja al inicio de love.update

        end
    end

    --volumen
    Audio.updateVolume(audioVolume)

end


--nuevo
function love.keypressed(key)
    
    applyAudioSettings()
    Audio.updateVolume(audioVolume)

    if gameState == "menu" then

            local prev = selectedOption

            if key == "up" or key == "w" then

                selectedOption =
                    selectedOption - 1

                if selectedOption < 1 then
                    selectedOption = #menuOptions
                end


            end

            if key == "down" or key == "s" then

                selectedOption =
                    selectedOption + 1

                if selectedOption > #menuOptions then
                    selectedOption = 1
                end

            end

            if selectedOption ~= prev then
                Audio.playSound("menuMove")
            end

            if key == "return" then

                if selectedOption == 1 then

                    newGame()
                    Audio.playMusic("game")

                elseif selectedOption == 2 then

                        if loadGame(1) then
                            gameState = "playing"
                        end

                elseif selectedOption == 3 then

                    optionsReturnState = "menu"

                    selectedOptionItem = 1

                    gameState = "options"

                elseif selectedOption == 4 then

                    love.event.quit()

                end

            end

            return

        end

        --confirmacion de nueva partida
        if gameState == "confirmOverwrite" then

            if key == "left" or key == "right" then
                confirmOption = (confirmOption == 1) and 2 or 1
            end

            if key == "return" then

                if confirmOption == 1 then
                    startNewGame()
                else
                    gameState = "menu"
                end

            end

            if key == "escape" then
                gameState = "menu"
            end

        end
        --confirmacion de nueva partida

        if key == "space" and player.isGrounded then

            player.isCharging = true

            player.chargeTime = 0

        end

            --Modo Tester
        if key == "t" then
            debugFly = not debugFly
        end

        -- modo tester
        if debugFly and key == "e" then

            if currentRoom < #rooms then

                currentRoom = currentRoom + 1
                loadRoom(currentRoom)
                    player.x = 100
                    player.y = 100


            end

        end

        if debugFly and key == "q" then

            if currentRoom > 1 then

                currentRoom = currentRoom - 1
                loadRoom(currentRoom)
                    player.x = 100
                    player.y = 100

            end

        end
        -- modo tester

    

        --pausa
        if key == "escape" then

            if gameState == "playing" then

                selectedPauseOption = 1
                gameState = "paused"
                Audio.pauseMusic()
                return

            elseif gameState == "paused" then

                gameState = "playing"
                Audio.resumeMusic()
                return

            end

        end

        --pausa
        if gameState == "paused" then

            if key == "w" or key == "up" then

                selectedPauseOption =
                    selectedPauseOption - 1

                if selectedPauseOption < 1 then
                    selectedPauseOption =
                        #pauseOptions
                end

                
            end

            if key == "s" or key == "down" then

                selectedPauseOption =
                    selectedPauseOption + 1

                if selectedPauseOption > #pauseOptions then
                    selectedPauseOption = 1
                end
                
                

            end

            if selectedOption ~= prev then
                Audio.playSound("menuMove")
            end
            -- funciones pausa
            if key == "return" or key == "kpenter" then

                if selectedPauseOption == 1 then

                    gameState = "playing"
                    Audio.resumeMusic()

                elseif selectedPauseOption == 2 then

                    saveGame(1)

                --[[elseif selectedPauseOption == 3 then

                    if loadGame(1) then

                        gameState = "playing"

                    end--]]

                elseif selectedPauseOption == 3 then

                    optionsReturnState = "paused"

                    selectedOptionItem = 1

                    gameState = "options"

                elseif selectedPauseOption == 4 then

                    selectedOption = 1
                    selectedPauseOption = 1
                    
                    gameState = "menu"
                    Audio.playMusic("menu")

                    return

                end

            end
            --funisones pausa
        end
        --pausa
        
        --opciones
        if gameState == "options" then

            if key == "w" or key == "up" then

                selectedOptionItem =
                    selectedOptionItem - 1

                if selectedOptionItem < 1 then
                    selectedOptionItem = #optionsMenu
                end

            end

            if key == "s" or key == "down" then

                selectedOptionItem =
                    selectedOptionItem + 1

                if selectedOptionItem > #optionsMenu then
                    selectedOptionItem = 1
                end

            end

            if selectedOptionItem ~= prev then
                Audio.playSound("menuMove")
            end

            --volver
            if key == "return" or key == "kpenter" then

                if selectedOptionItem == #optionsMenu then

                    gameState = optionsReturnState

                end

            end

            --menu de opciones

            local opt = optionsMenu[selectedOptionItem]

            if key == "left" or key == "right" or key == "a" or key == "d" then

                if opt.name == "Pantalla completa" then

                    opt.value = not opt.value
                    love.window.setFullscreen(opt.value)

                    -- Respaldo extra: por si love.resize no se
                    -- dispara de inmediato en alguna plataforma
                    if map then
                        map:resize(
                            love.graphics.getWidth(),
                            love.graphics.getHeight()
                        )
                    end

                elseif opt.name == "Volumen General"
                    or opt.name == "Musica"
                    or opt.name == "Efectos" then

                    local step = (key == "right" or key == "d") and 10 or -10

                    opt.value = opt.value + step

                    if opt.value > 100 then opt.value = 100 end
                    if opt.value < 0 then opt.value = 0 end

                    applyAudioSettings()
                    Audio.updateVolume(audioVolume)

                end

            end
        
        end
        --opciones


    end
-- nuevo
function love.keyreleased(key)


    if key == "space"
       and player.isCharging then

        player.isCharging = false

        player.jumpPower =
            300 + (player.chargeTime * 500)


        local jumpDirection = 0
        if love.keyboard.isDown("a") then
            jumpDirection = -1
        end

        if love.keyboard.isDown("d") then
            jumpDirection = 1
        end

        player.velocityY =
            -(player.jumpPower * verticalMultiplier)

        player.velocityX =
            (player.jumpPower * horizontalMultiplier)
            * jumpDirection

        jumpCount = jumpCount + 1

        Audio.playRandomJumpPre()
        
    end

end


function love.draw()

    local scaleFactor, offsetX, offsetY = getScreenScale()
    
    love.graphics.push()
    love.graphics.origin()

    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scaleFactor, scaleFactor)

    love.graphics.translate(0, 0)

    if gameState == "menu" then
        drawMenu()

    elseif gameState == "paused" then
        drawPaused()

    elseif gameState == "options" then
        drawOptions()

    elseif gameState == "ending" then
        drawEnding()
    
    else
        drawGame()
    end

    love.graphics.pop()

    drawLetterbox()

end

function drawMenu()
    drawBackground(menuBackgrounds)

    love.graphics.setFont(titleFont)
    love.graphics.printf("SALTBURN", 0, 80, 800, "center")

    love.graphics.setFont(menuFont)

    for i, option in ipairs(menuOptions) do

        local prefix = (i == selectedOption) and "> " or "  "

        love.graphics.printf(
            prefix .. option,
            0,
            200 + (i * 40),
            800,
            "center"
        )
    end

    love.graphics.setFont(smallFont)
    love.graphics.printf("Version DEMO 0.6", 0, 570, 800, "left")

    drawNotification()
end

function drawPaused()
    drawBackground(gameBackgrounds)

    local scale, offsetX, offsetY = getScreenScale()
    map:draw(offsetX / scale, offsetY / scale, scale, scale)

    drawPlayer()

    love.graphics.setColor(0,0,0,0.55)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1,1,1)

    love.graphics.setFont(titleFont)
    love.graphics.printf("PAUSA", 0, 80, 800, "center")

    love.graphics.setFont(smallFont)
    love.graphics.print("Tiempo: " .. formatTime(gameTime), 10, 500)
    love.graphics.print("Saltos: " .. jumpCount, 10, 530)

    love.graphics.setFont(menuFont)

    for i, option in ipairs(pauseOptions) do
        local prefix = (i == selectedPauseOption) and "> " or "  "

        love.graphics.printf(prefix .. option, 0, 220 + i*40, 800, "center")
    end

    drawNotification()
end

function drawGame()
    drawBackground(gameBackgrounds)

    local scale, offsetX, offsetY = getScreenScale()
    map:draw(offsetX / scale, offsetY / scale, scale, scale)

    drawPlayer()

    drawHUD()
end

function drawPlayer()
    local anim = player.animations[player.state]

    local drawScale = 2

    love.graphics.draw(
        anim.image,
        anim.frames[anim.currentFrame],
        player.x + player.spriteOffsetX,
        player.y + player.spriteOffsetY,
        0,
        player.facing * drawScale,
        drawScale,
        30,
        0
    )
end

function drawHUD()

    --love.graphics.setFont(smallFont)

    --love.graphics.print("SALTBURN", 10, 10)

    --love.graphics.print("Tiempo: " .. formatTime(gameTime), 10, 210)
    --love.graphics.print("Saltos: " .. jumpCount, 10, 230)
    --love.graphics.print("Room: " .. currentRoom, 10, 270)
end

function drawLetterbox()

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    local scale, offsetX, offsetY = getScreenScale()

    love.graphics.setColor(0,0,0)

    love.graphics.rectangle("fill", 0, 0, offsetX, sh)
    love.graphics.rectangle("fill", sw-offsetX, 0, offsetX, sh)
    love.graphics.rectangle("fill", 0, 0, sw, offsetY)
    love.graphics.rectangle("fill", 0, sh-offsetY, sw, offsetY)

    love.graphics.setColor(1,1,1)
end


function drawGameBehindPause()

    local scale, offsetX, offsetY = getScreenScale()

    map:draw(offsetX / scale, offsetY / scale, scale, scale)

    drawPlayer()

    love.graphics.setColor(0,0,0,0.55)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1,1,1)

end


function drawOptions()

    if optionsReturnState == "menu" then
        drawBackground(menuBackgrounds)
    else
        drawBackground(gameBackgrounds)
        drawGameBehindPause()
    end

    love.graphics.setFont(titleFont)

    love.graphics.printf(
        "OPCIONES",
        0,
        80,
        800,
        "center"
    )

    love.graphics.setFont(menuFont)

    for i, option in ipairs(optionsMenu) do

        local prefix = "  "

        if i == selectedOptionItem then
            prefix = "> "
        end

        local text = prefix .. option.name

        if option.value ~= nil then

            if type(option.value) == "boolean" then
                text = text .. "   " .. (option.value and "ON" or "OFF")
            else
                text = text .. "   " .. tostring(option.value) .. "%"
            end
        end

        love.graphics.printf(
            text,
            0,
            180 + i * 45,
            800,
            "center"
        )

    end

end

function drawEnding()

    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1,1,1)

    love.graphics.setFont(titleFont)
    love.graphics.printf("Gracias por Jugar", 0, 100, 800, "center")

    love.graphics.setFont(menuFont)
    love.graphics.printf("Desarrollado por Isaac", 0, 200, 800, "center")

    love.graphics.printf("Estadisticas:", 0, 300, 800, "center")

    love.graphics.printf(
        "Tiempo: " .. formatTime(gameTime),
        0,
        360,
        800,
        "center"
    )

    love.graphics.printf(
        "Saltos: " .. jumpCount,
        0,
        400,
        800,
        "center"
    )

    love.graphics.printf("Volviendo al menu...", 0, 500, 800, "center")

end

function love.conf(t)

    t.window.width = 800
    t.window.height = 600

    t.window.resizable = true

    t.window.highdpi = false

end