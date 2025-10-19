local colour = require("termplot.colour")
local bit = require("bit")

local record Canvas
    __index: self
    __name: string

    character_width: integer
    character_height: integer

    pixel_height: integer
    pixel_width: integer

    bits: {{ integer }}

    foreground: {{ colour.Colour | nil }}

    BRAILLE_BASE: integer
    DOT_MASK: {{integer}}
end
Canvas.__index = Canvas
Canvas.__name = "Canvas"

Canvas.BRAILLE_BASE = 0x2800 --base code point for braille characters

Canvas.DOT_MASK = {
  [0] = { [0] = 1, [1] = 2, [2] = 4, [3] = 64 },
  [1] = { [0] = 8, [1] = 16, [2] = 32, [3] = 128 },
}

function Canvas:create(character_width: integer, character_height: integer): Canvas
    local obj: self = setmetatable({
        character_width = character_width,
        character_height = character_height,
        pixel_width = character_width * 2,
        pixel_height = character_height * 4,
        bits = {},
        foreground = {},
    }, self as metatable<self>)

    for row = 1, obj.character_height do
        obj.bits[row] = {}
        obj.foreground[row] = {}

        for col = 1, obj.character_width do
            obj.bits[row][col] = 0
            obj.foreground[row][col] = nil
        end
    end

    return obj
end

function Canvas:set_pixel(x: integer, y: integer, fg?: colour.Colour)
    if x < 0 or y < 0 or x >= self.pixel_width or y >= self.pixel_height then return end
    local col = math.floor(x / 2) + 1
    local row_from_top = math.floor((self.pixel_height - 1 - y) / 4) + 1
    local lx = x % 2
    local ly_top = 3 - (y % 4)
    local mask = Canvas.DOT_MASK[lx][ly_top]
    local old = self.bits[row_from_top][col]
    self.bits[row_from_top][col] = bit.bor(old, mask)
    if fg then self.foreground[row_from_top][col] = fg end
end

function Canvas:line(from_x: integer, from_y: integer, to_x: integer, to_y: integer, fg?: colour.Colour)
    local dx = math.abs(to_x - from_x)
    local dy = math.abs(to_y - from_y)
    local sx = (from_x < to_x) and 1 or -1
    local sy = (from_y < to_y) and 1 or -1
    local err = dx - dy

    local x, y = from_x, from_y
    while true do
        self:set_pixel(x, y, fg)
        if x == to_x and y == to_y then break end
        local err2 = err * 2
        if err2 > -dy then
            err = err - dy
            x = x + sx
        end
        if err2 < dx then
            err = err + dx
            y = y + sy
        end
    end
end

function Canvas:rectangle(x0: integer, y0: integer, x1: integer, y1: integer, fg?: colour.Colour | nil, fill?: boolean)
    if fill then
        if x0 > x1 then x0,x1 = x1,x0 end
        if y0 > y1 then y0,y1 = y1,y0 end
        for y = y0, y1 do
            for x = x0, x1 do
                self:set_pixel(x, y, fg)
            end
        end
    else
        self:line(x0, y0, x1, y0, fg)
        self:line(x1, y0, x1, y1, fg)
        self:line(x1, y1, x0, y1, fg)
        self:line(x0, y1, x0, y0, fg)
    end
end

function Canvas:render_rows(): {string}
    local rows: {string} = {}
    for r = 1, self.character_height do
        local buf: {string} = {}
        local current_colour: colour.Colour | nil = nil
        for c = 1, self.character_width do
            local bits = self.bits[r][c]
            local ch = (bits == 0) and " " or utf8.char(Canvas.BRAILLE_BASE + bits)
            local fg = self.foreground[r][c]
            if fg ~= current_colour then
                if fg then
                    buf[#buf+1] = colour.colour_to_foreground(fg)
                elseif current_colour then
                    buf[#buf+1] = colour.RESET
                end
                current_colour = fg
            end
            buf[#buf+1] = ch
        end
        if current_colour then
            buf[#buf+1] = colour.RESET
        end
        rows[#rows+1] = table.concat(buf)
    end
    return rows
end

return Canvas
