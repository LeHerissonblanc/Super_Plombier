local love             = require("love")
local Box              = require("box")

local background_color = { 0.1, 0.1, 0.1 }
local font
local showIntro        = true
local splash_image
local intro_sound
local bg_music
local player
local world
local accumulator      = 0
local zoom             = 2 -- cam zoom
local camera           = { x = 0, y = 0, speed = 9 }

-- functions
local function checkCollision(a, b)
    return a.x < b.x + b.hitbox.width and
        a.x + a.hitbox.width > b.x and
        a.y < b.y + b.height and
        a.y + a.height > b.y
end

local function isOnFloor(obj)
    return obj.y + obj.texture:getHeight() >= world.floorY
end

--inputs
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end
    if showIntro then
        if key == "space" then
            showIntro = false
            if intro_sound:isPlaying() then intro_sound:stop() end
            bg_music:play()
        end
    end
end

local function move(obj, dt)
    if obj == player then
        if love.keyboard.isDown("d") then
            obj.velocity.x = obj.velocity.x + obj.speed * dt
        end
        if love.keyboard.isDown("q") then
            obj.velocity.x = obj.velocity.x - obj.speed * dt
        end
        if love.keyboard.isDown("space") and isOnFloor(obj) then
            player.velocity.y = -player.jumpForce
        end
    end

    -- gravity
    if not isOnFloor(obj) then
        obj.velocity.y = obj.velocity.y + (world.gravity * obj.weight)
    end

    obj.x = obj.x + obj.velocity.x
    obj.y = obj.y + obj.velocity.y

    -- replace obj
    local h = obj.texture:getHeight()
    if obj.y + h > world.floorY then
        obj.y = world.floorY - h
        obj.velocity.y = 0
    end

    -- friction
    obj.velocity.x = obj.velocity.x * world.friction
    obj.velocity.y = obj.velocity.y * world.friction -- no longer divided by weight

    -- snap tiny velocities to 0 so the object really stops
    if math.abs(obj.velocity.x) < 0.001 then obj.velocity.x = 0 end
    if math.abs(obj.velocity.y) < 0.001 then obj.velocity.y = 0 end
end

-- main
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- load assets
    font = love.graphics.newFont("fonts/JetBrainsMono-Regular.ttf", 12)
    love.graphics.setFont(font)
    splash_image = love.graphics.newImage("assets/splash_screen.png")
    intro_sound  = love.audio.newSource("assets/sound_effects/intro.mp3", "static")
    bg_music     = love.audio.newSource("assets/music/time_for_adventure.mp3", "static")

    --settings
    bg_music:setLooping(true)
    love.graphics.setLineStyle("smooth")
    love.graphics.setBackgroundColor(0, 0, 0)

    intro_sound:play()

    --Load objects
    world = {
        gravity = 1, --per frame
        friction = 0.9,
        floorY = love.graphics.getHeight() * 0.75
    }

    --player
    local texture = love.graphics.newImage("assets/player.png")
    player = {
        x = love.graphics.getWidth() / 2,
        y = world.floorY - texture:getHeight(), -- start on floor
        velocity = { x = 0, y = 0 },
        speed = 50,
        jumpForce = 10,
        texture = texture,
        -- hitbox = {},
        weight = 0.16 -- effective gravity = world.gravity * weight
    }

    -- player.hitbox.width = player.texture:getWidth() / 5
    -- player.hitbox.offsetX = player.texture:getWidth() / 2
    -- player.hitbox.offsetY = player.texture:getHeight() - player.hitbox.width

    camera.x = player.x + player.texture:getWidth() / 2
    camera.y = player.y + player.texture:getHeight() / 2

    --boxes
    Box.add("Window", {
        id = "window",
        align = { "left", "top" },
        padding = 10,
        margin = 5,
        cornerRadius = 10,
        maxWidth = 300
    })

    Box.add("Clock", {
        id = "clock",
        align = { "right", "top" },
        padding = 10,
        margin = 5,
        cornerRadius = 10,
        maxWidth = 200
    })

    Box.add("Data", {
        id = "coord",
        align = { "left", "bottom" },
        padding = 10,
        margin = 5,
        cornerRadius = 10,
        maxWidth = 200
    })
end

function love.update(dt)
    --update clock
    accumulator = accumulator + dt
    if accumulator >= 1 then -- one‑second interval
        accumulator = accumulator - 1
        Box.update("clock", "Time: " .. os.date("%H:%M:%S"))
    end

    Box.update("window",
        "Window width = " .. love.graphics.getWidth() ..
        "\nWindow height = " .. love.graphics.getHeight())

    Box.update("coord",
        "x: " .. math.floor(player.x) ..
        "\ny: " .. math.floor(player.y) ..
        "\nvelocity x: " .. string.format("%.1f", player.velocity.x) ..
        "\nvelocity y: " .. string.format("%.1f", player.velocity.y))

    if not showIntro then
        move(player, dt)

        -- Smooth cam
        local targetX = player.x + player.texture:getWidth() / 2
        local targetY = player.y + player.texture:getHeight() / 2
        local t = 1 - math.exp(-camera.speed * dt)
        camera.x = camera.x + (targetX - camera.x) * t
        camera.y = camera.y + (targetY - camera.y) * t
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.clear(background_color)

    if showIntro then
        local x = (love.graphics.getWidth() - splash_image:getWidth()) / 2
        local y = (love.graphics.getHeight() - splash_image:getHeight()) / 2
        love.graphics.draw(splash_image, x, y)
        love.graphics.print("Space to skip", 20, love.graphics.getHeight() - 40)
        return
    end

    -- WORLD
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    local cx = math.floor(camera.x * zoom + 0.5) / zoom
    local cy = math.floor(camera.y * zoom + 0.5) / zoom

    love.graphics.push()
    love.graphics.translate(sw / 2, sh / 2)
    love.graphics.scale(zoom)
    love.graphics.translate(-cx, -cy)

    -- floor
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1 / zoom) -- 1 screen pixel thick line
    love.graphics.line(player.x - sw, world.floorY, player.x + sw, world.floorY)
    love.graphics.setLineWidth(1)

    -- player
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(player.texture, player.x, player.y)

    -- --player's hitbox
    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.circle(
    --     "line",
    --     player.x + player.hitbox.offsetX,
    --     player.y + player.hitbox.offsetY,
    --     player.hitbox.width
    -- )

    love.graphics.pop()

    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    Box.draw()
end