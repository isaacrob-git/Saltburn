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

function love.load()

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
        spriteOffsetY = -70
        
        
    }

    menuBackgrounds =
    loadBackground("menu")

    gameState = "menu"

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
        "Cargar Partida",
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
        speed = 0.08
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

    end

    loadRoom(currentRoom)

    verticalMultiplier = 1
    horizontalMultiplier = 0.7
    wallBounceForce = 120
    walkSpeed = 120
    gravity = 2000
    maxChargeTime = 1

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
            love.graphics.getWidth() /
            backgroundSet[i]:getWidth()

        local scaleY =
            love.graphics.getHeight() /
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

    love.graphics.printf(
        notificationText,
        220,
        550,
        500,
        "center"
    )

    love.graphics.setColor(1,1,1)

end

--funcion notificacion

function love.update(dt)

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

        if love.keyboard.isDown("a") then

            player.x = player.x -
                    walkSpeed * dt

            player.facing = -1

        end

        if love.keyboard.isDown("d") then

            player.x = player.x +
                    walkSpeed * dt

            player.facing = 1

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

    if love.keyboard.isDown("up") then
        player.spriteOffsetY = player.spriteOffsetY - 1
    end

    if love.keyboard.isDown("down") then
        player.spriteOffsetY = player.spriteOffsetY + 1
    end

    if love.keyboard.isDown("left") then
        player.spriteOffsetX = player.spriteOffsetX - 1
    end

    if love.keyboard.isDown("right") then
        player.spriteOffsetX = player.spriteOffsetX + 1
    end

end


--nuevo
function love.keypressed(key)
    
    if gameState == "menu" then

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


            if key == "return" then

                if selectedOption == 1 then

                    gameState = "playing"

                elseif selectedOption == 2 then

                    gameState = "playing"

                elseif selectedOption == 3 then

                    gameState = "options"

                elseif selectedOption == 4 then

                    love.event.quit()

                end

            end

            return

        end

        if key == "space" and player.isGrounded then

            player.isCharging = true

            player.chargeTime = 0

        end

            -- Modo Tester
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


        if key == "escape" then

            if gameState == "playing" then

                selectedPauseOption = 1
                gameState = "paused"
                return

            elseif gameState == "paused" then

                gameState = "playing"
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

            -- funciones pausa
            if key == "return" or key == "kpenter" then

                if selectedPauseOption == 1 then

                    gameState = "playing"

                elseif selectedPauseOption == 2 then

                   saveGame(1)

                elseif selectedPauseOption == 3 then

                    -- Cargar Partida
                    -- Lo implementaremos en la ETAPA 21

                elseif selectedPauseOption == 4 then

                    -- Opciones
                    -- Lo implementaremos más adelante

                elseif selectedPauseOption == 5 then

                    selectedOption = 1
                    selectedPauseOption = 1
                    
                    gameState = "menu"

                    return

                end

            end
            --funisones pausa
        end
        --pausa
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

    end

end


function love.draw()


    if gameState == "menu" then

        drawBackground(menuBackgrounds)
        love.graphics.setFont(titleFont)

        love.graphics.printf(
            "SALTBURN",
            0,
            80,
            800,
            "center"
        )

        love.graphics.setFont(menuFont)

        for i, option in ipairs(menuOptions) do

            local prefix = "  "

            if i == selectedOption then
                prefix = "> "
            end

            love.graphics.printf(
                prefix .. option,
                0,
                200 + (i * 40),
                800,
                "center"
            )

        end

        love.graphics.setFont(smallFont)
        
        love.graphics.printf(
            "Version 0.1 Alpha",
            0,
            570,
            800,
            "left"
        )

        drawNotification()
        
        return

    end    

    love.graphics.setColor(1, 1, 1, 1)
    --pausa
    if gameState == "paused" then

        drawBackground(gameBackgrounds)

        map:draw()

        local anim =
            player.animations[player.state]

        local scale = 2

        love.graphics.draw(
            anim.image,
            anim.frames[anim.currentFrame],
            player.x + player.spriteOffsetX,
            player.y + player.spriteOffsetY,
            0,
            player.facing * scale,
            scale,
            30,
            0
        )

        --background del pausa
        love.graphics.setColor(0, 0, 0, 0.55)

        love.graphics.rectangle(
            "fill",
            0,
            0,
            love.graphics.getWidth(),
            love.graphics.getHeight()
        )
        --background del pausa

        love.graphics.setColor(1, 1, 1, 1)
        
        love.graphics.setFont(titleFont)

        love.graphics.printf(
            "PAUSA",
            0,
            80,
            800,
            "center"
        )
        

        love.graphics.setFont(menuFont)

        for i, option in ipairs(pauseOptions) do

            local prefix = "  "

            if i == selectedPauseOption then
                prefix = "> "
            end

            love.graphics.printf(
                prefix .. option,
                0,
                220 + i * 40,
                800,
                "center"
            )

        end

        drawNotification()
        
        return

    end
    --pausa

    drawBackground(gameBackgrounds)

    map:draw()

    love.graphics.setFont(verysmallFont)

    love.graphics.print("SALTBURN", 10, 10)


    local anim =
        player.animations[player.state]

    local scale = 2

    love.graphics.draw(
        anim.image,
        anim.frames[anim.currentFrame],
        player.x + player.spriteOffsetX,
        player.y + player.spriteOffsetY,
        0,
        player.facing * scale,
        scale,
        30,
        0
    )
    

    love.graphics.print(
        "En suelo: " .. tostring(player.isGrounded),
        10,
        30
    )

    love.graphics.print(
         "Velocidad Y: " ..
         math.floor(player.velocityY),
        10,
        50
    )   
    
    love.graphics.print(
        "Carga: " ..
        string.format("%.2f", player.chargeTime),
        10,
        70
    )

    local direction = "Derecha"

    if player.facing == -1 then
        direction = "Izquierda"
    end

    love.graphics.print(
        "Direccion: " .. direction,
        10,
        90
    )

    love.graphics.print(
        "Potencia: " ..
        math.floor(player.jumpPower),
        10,
        110
    )

    --love.graphics.setColor(1,0,0)
    --    for _, p in ipairs(platforms) do
    --        love.graphics.rectangle("line", p.x, p.y, p.width, p.height)
    --    end
    --    love.graphics.setColor(1,1,1)


    love.graphics.print(
        "Estado: " .. player.state,
        10,
        130
    )

        --[love.graphics.setColor(0,1,0)
        --love.graphics.rectangle(
           -- "line",
           -- player.x,
           -- player.y,
           -- player.width,
           -- player.height
        --)
        --love.graphics.setColor(1,1,1)

        love.graphics.print(
            "Offset X: "..player.spriteOffsetX,
            10,
            150
        )

        love.graphics.print(
            "Offset Y: "..player.spriteOffsetY,
            10,
            170
        )

        love.graphics.print(
            "Facing: " .. player.facing,
            10,
            190
        )

        if debugFly then
        love.graphics.print(
            "DEBUG FLY",
            10,
            250
        )
        end
        love.graphics.print(
            "Room: " .. currentRoom,
            10,
            270
        )

        love.graphics.print(
            "Tiempo: " .. formatTime(gameTime),
            10,
            210
        )

        love.graphics.print(
            "Saltos: " .. jumpCount,
            10,
            230
        )
    
end