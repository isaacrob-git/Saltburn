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
        
    }
    
    map = sti("maps/room1.lua")

    verticalMultiplier = 1
    horizontalMultiplier = 0.7
    wallBounceForce = 120
    walkSpeed = 120
    gravity = 2000
    maxChargeTime = 1


    roomWidth = 800
    roomHeight = 600

    maxRooms = 3
    currentRoom = 1

    rooms = {

        [1] = {
            {x = 0, y = 550, width = 800, height = 50},
            {x = 150, y = 450, width = 120, height = 20}
        },

        [2] = {
            {x = 200, y = 550, width = 400, height = 50},
            {x = 100, y = 350, width = 120, height = 20}
        }

    }

end

function love.update(dt)


    player.previousX = player.x
    player.previousY = player.y

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

    local currentPlatforms = rooms[currentRoom] or {}

    for _, platform in ipairs(currentPlatforms) do

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

    if player.y + player.height < 0 then

        if currentRoom > 1 then
            currentRoom = currentRoom - 1
        end

        player.y = roomHeight - player.height - 10

    end

    if player.y > roomHeight then

        if currentRoom < maxRooms then
            currentRoom = currentRoom + 1
        end

        player.y = 0

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

    map:draw()

    love.graphics.print("Vertical Edge", 10, 10)



    love.graphics.rectangle(
        "fill",
        player.x,
        player.y,
        player.width,
        player.height
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

    for _, platform in ipairs(rooms[currentRoom]) do

        love.graphics.rectangle(
            "fill",
            platform.x,
            platform.y,
            platform.width,
            platform.height
        )

    end

    love.graphics.print(
        "Room: " .. tostring(currentRoom),
        10,
        190
    )

end