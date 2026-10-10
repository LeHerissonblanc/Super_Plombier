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

-- functions
local function checkCollision(a, b)
    return a.x < b.x + b.width and
        a.x + a.width > b.x and
        a.y < b.y + b.height and
        a.y + a.height > b.y
end

-- vrai si les pieds du joueur touchent (ou dépassent) le sol
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

    obj.velocity.x = math.floor((obj.velocity.x * world.friction) * 1000) / 1000
    obj.velocity.y = math.floor((obj.velocity.y * (world.friction / obj.weight)) * 1000) / 1000
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
        gravity = 1,                              --per frame
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
        jumpForce = 15,
        texture = texture,
        hitbox = {},
        weight = 1.0
    }

    player.hitbox.radius = player.texture:getWidth() / 5
    player.hitbox.offsetX = player.texture:getWidth() / 2
    player.hitbox.offsetY = player.texture:getHeight() - player.hitbox.radius

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

    love.graphics.setFont(font)
    Box.draw()

    -- floor
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(0, world.floorY, love.graphics.getWidth(), world.floorY)

    -- player
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(player.texture, player.x, player.y)

    --player's hitbox
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle(
        "line",
        player.x + player.hitbox.offsetX,
        player.y + player.hitbox.offsetY,
        player.hitbox.radius
    )
end