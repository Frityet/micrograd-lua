local record colour
    type Colour = { integer, integer, integer }

    RESET: string
    enum ColourMap
        "viridis"
        "plasma"
        "magma"
        "gray"
    end
    COLOUR_MAPS: { ColourMap : {{ number, Colour }} }
    SERIES_PALETTE: {colour.Colour}
end

local utilities = require("termplot.utilities")

function colour.compare_colour(c1: colour.Colour, c2: colour.Colour): integer, integer, integer
    return c1[1] - c2[1], c1[2] - c2[2], c1[3] - c2[3]
end

function colour.foreground(r: integer, g: integer, b: integer): string
    r, g, b = utilities.clamp(r, 0, 255) as integer, utilities.clamp(g, 0, 255) as integer, utilities.clamp(b, 0, 255) as integer
    return string.format("\27[38;2;%d;%d;%dm", r, g, b)
end

function colour.background(r: integer, g: integer, b: integer): string
    r, g, b = utilities.clamp(r, 0, 255) as integer, utilities.clamp(g, 0, 255) as integer, utilities.clamp(b, 0, 255) as integer
    return string.format("\27[48;2;%d;%d;%dm", r, g, b)
end

function colour.colour_to_foreground(c: colour.Colour): string
    return colour.foreground(c[1], c[2], c[3])
end

function colour.colour_to_background(c: colour.Colour): string
    return colour.background(c[1], c[2], c[3])
end

colour.RESET = "\27[0m"

colour.COLOUR_MAPS = {
  viridis = {
    { 0.00, { 68, 1, 84 } },
    { 0.25, { 59, 82, 139 } },
    { 0.50, { 33, 145, 140 } },
    { 0.75, { 94, 201, 97 } },
    { 1.00, { 253, 231, 36 } }
  },
  plasma = {
    { 0.00, { 13, 8, 135 } },
    { 0.25, { 126, 3, 168 } },
    { 0.50, { 203, 71, 119 } },
    { 0.75, { 248, 149, 64 } },
    { 1.00, { 239, 248, 33 } }
  },
  magma = {
    { 0.00, { 0, 0, 3 } },
    { 0.25, { 87, 15, 109 } },
    { 0.50, { 187, 55, 84 } },
    { 0.75, { 249, 142, 7 } },
    { 1.00, { 252, 253, 191 } }
  },
  gray = {
    { 0.00, { 0, 0, 0 } },
    { 1.00, { 255, 255, 255 } }
  },
}

function colour.colourmap_colour(name: colour.ColourMap, t: number): colour.Colour | nil, string | nil
    local m = colour.COLOUR_MAPS[name]
    if not m then return nil, "unknown colour map: " .. name end

    t = utilities.clamp(t, 0.0, 1.0)

    for i = 1, #m - 1 do
        local a, b = m[i], m[i+1]
        if t >= a[1] and t <= b[1] then
            local tt = (t - a[1]) / (b[1] - a[1])
            return utilities.linear_interpolate_colour(a[2], b[2], tt)
        end
    end

    return (t < m[1][1]) and m[1][2] or m[#m][2]
end

function colour.random(): colour.Colour
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    return { r, g, b }
end

colour.SERIES_PALETTE = {
  { 239, 71, 111 },  { 17, 138, 178 }, { 6, 214, 160 }, { 255, 209, 102 }, { 7, 59, 76 },
  { 255, 146, 54 },  { 147, 51, 234 }, { 5, 150, 105 }, { 245, 158, 11 },  { 220, 38, 38 },
}

return colour
