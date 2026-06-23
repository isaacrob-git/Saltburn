local sti = require("libraries.sti")

function checkCollision(a, b)

    return (
        a.x < b.x + b.width and
        a.x + a.width > b.x and
        a.y < b.y + b.height and
        a.y + a.height > b.y
    )

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
        "maps/room3.lua"
    }

        roomBackgrounds = {
        [1] = "forest",
        [2] = "forest",
        [3] = "forest"
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

    
end

function loadBackground(backgroundName)

    backgrounds = {}

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

function love.update(dt)


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

function love.keypressed(key)

    if key == "space" and player.isGrounded then

        player.isCharging = true

        player.chargeTime = 0

    end

end

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


    end

end


function love.draw()

   for i = 1, 6 do

        love.graphics.draw(
            backgrounds[i],
            0,
            0
        )

    end

    map:draw()

    love.graphics.print("Vertical Edge", 10, 10)


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

    love.graphics.setColor(1,0,0)
        for _, p in ipairs(platforms) do
            love.graphics.rectangle("line", p.x, p.y, p.width, p.height)
        end
        love.graphics.setColor(1,1,1)


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
        love.graphics.setColor(1,1,1)

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
    
end
