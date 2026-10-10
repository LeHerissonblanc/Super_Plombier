local love = require("love")

local Box = {}
Box.items = {}

function Box.add(text, opts)
    opts = opts or {}
    local id = opts.id or tostring(#Box.items + 1)

    Box.items[id] = {
        id = id,
        text = text or "",
        x = opts.x or 0,
        y = opts.y or 0,
        align = opts.align or { "left", "top" },
        padding = opts.padding or 8,
        margin = opts.margin or 5,
        cornerRadius = opts.cornerRadius or 8,
        color = opts.color or { 1, 1, 1, 1 }, -- couleur du contour
        textColor = opts.textColor or { 1, 1, 1, 1 },
        maxWidth = opts.maxWidth or 300,
    }

    return id
end

function Box.update(id, text)
    if Box.items[id] then
        Box.items[id].text = text or ""
    end
end

function Box.remove(id)
    Box.items[id] = nil
end

local function wrapText(text, font, maxWidth)
    local lines = {}
    text = tostring(text or "")

    for paragraph in text:gmatch("([^\n]*)\n?") do
        if paragraph ~= "" then
            local current = ""
            for word in paragraph:gmatch("%S+") do
                local test = (current == "" and word) or (current .. " " .. word)
                if font:getWidth(test) <= maxWidth then
                    current = test
                else
                    if current ~= "" then
                        table.insert(lines, current)
                    end
                    current = word
                end
            end
            if current ~= "" then
                table.insert(lines, current)
            end
        else
            table.insert(lines, "")
        end
    end

    if #lines == 0 then
        lines = { "" }
    end

    return lines
end

local function getBoxSize(box, font)
    local lines = wrapText(box.text, font, box.maxWidth)
    local lineHeight = font:getHeight() * font:getLineHeight()

    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, font:getWidth(line))
    end

    local height = #lines * lineHeight

    return width + box.padding * 2, height + box.padding * 2, lines, lineHeight
end

local function getAnchorPosition(box, boxW, boxH)
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local x, y = box.x, box.y

    if box.align[1] == "right" then
        x = sw - boxW - box.x
    elseif box.align[1] == "center" then
        x = (sw - boxW) / 2 + box.x
    end

    if box.align[2] == "bottom" then
        y = sh - boxH - box.y
    elseif box.align[2] == "center" then
        y = (sh - boxH) / 2 + box.y
    end

    return x, y
end

function Box.draw()
    local font = love.graphics.getFont()
    local drawn = {}

    local items = {}
    for _, box in pairs(Box.items) do
        table.insert(items, box)
    end
    table.sort(items, function(a, b)
        return a.id < b.id
    end)

    for _, box in ipairs(items) do
        local boxW, boxH, lines = getBoxSize(box, font)
        local x, y = getAnchorPosition(box, boxW, boxH)

        for _, other in ipairs(drawn) do
            if box.align[1] == other.alignX and box.align[2] == other.alignY then
                local overlapX = x < other.x + other.w and x + boxW > other.x
                local overlapY = y < other.y + other.h and y + boxH > other.y

                if overlapX and overlapY then
                    if box.align[2] == "top" then
                        y = other.y + other.h + box.margin
                    elseif box.align[2] == "bottom" then
                        y = other.y - boxH - box.margin
                    end
                end
            end
        end

        love.graphics.setColor(box.color)
        love.graphics.rectangle("line", x, y, boxW, boxH, box.cornerRadius, box.cornerRadius)

        love.graphics.setColor(box.textColor)
        love.graphics.printf(table.concat(lines, "\n"), x + box.padding, y + box.padding, boxW - box.padding * 2, "left")

        table.insert(drawn, {
            x = x,
            y = y,
            w = boxW,
            h = boxH,
            alignX = box.align[1],
            alignY = box.align[2]
        })
    end
end

return Box