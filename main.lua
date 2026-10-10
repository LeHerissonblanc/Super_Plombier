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

--inputs
function love.keypressed(key)
    if showIntro and key == "space" then
        showIntro = false
        if intro_sound:isPlaying() then intro_sound:stop() end
        bg_music:play()
    end

    if key == "escape" then
        love.event.quit()
    end
end

local function playable(obj)
    return obj == "player"
end

local function move(obj, dt)
    if playable("player") then
        if love.keyboard.isDown("d") then
            obj.velocity.x = obj.velocity.x + obj.speed * dt
        end
        if love.keyboard.isDown("q") then
            obj.velocity.x = obj.velocity.x - obj.speed * dt
        end
    end

    obj.velocity.y = obj.velocity.y + (world.gravity * obj.weight)

    obj.x = obj.x + obj.velocity.x * dt
    obj.y = obj.y + obj.velocity.y * dt

    obj.velocity.x = obj.velocity.x * world.friction
    obj.velocity.y = obj.velocity.y * (world.friction / obj.weight)
end

-- main
function love.load()
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
        friction = 0.9
    }

    --player
    player = {
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        velocity = { x = 0, y = 0 },
        speed = 200,
        texture = love.graphics.newImage("assets/player.png"),
        hitbox = {},
        weight = 1.0
    }

    player.hitbox.radius = player.texture:getWidth() / 5
    player.hitbox.offsetX = player.texture:getWidth() / 2
    player.hitbox.offsetY = player.texture:getHeight() - player.hitbox.radius

    --boxes
    Box.add("Window width = " .. love.graphics.getWidth() ..
        "\nWindow height = " .. love.graphics.getHeight(), {
            id = "window",
            align = { "left", "top" },
            padding = 10,
            margin = 5,
            cornerRadius = 10,
            maxWidth = 300
        })

    Box.add("Time: " .. os.date("%H:%M:%S"), {
        id = "clock",
        align = { "right", "top" },
        padding = 10,
        margin = 5,
        cornerRadius = 10,
        maxWidth = 200
    })

    Box.add("x: " .. math.floor(player.x) .. "\ny: " .. math.floor(player.y), {
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

    Box.update("window", "Window width = " .. love.graphics.getWidth() ..
        "\nWindow height = " .. love.graphics.getHeight())

    Box.update("coord", "x: " .. math.floor(player.x) .. "\ny: " .. math.floor(player.y))

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

    -- player
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
