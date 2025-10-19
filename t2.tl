local plot = require("termplot.init")
local colour = require("termplot.colour")

local function plot_f(f: (function(number): number), opts: plot.Figure, n?: integer, start?: integer)
    n = n or 100
    start = start or 0
    local x, y: {number}, {number} = {}, {}

    for i = start, start + n do
        local xv = i
        local yv = f(xv)
        x[#x+1] = xv
        y[#y+1] = yv
    end

    return plot.plot(x, y, opts)
end

local function parabola(x: integer): integer return x * x end
local function cubic(x: integer): integer return x * x * x end
local function sine_wave(x: integer): integer return math.floor(10 * math.sin(x / 10)) end

math.randomseed(os.time())

plot_f(cubic, {
    title = "y = x^3",
    x_label = "x",
    y_label = "x^3",

    x_min = -10,
    x_max = 10,
    y_min = -1000,
    y_max = 1000,

    axis_colour = colour.random(),
}, 20, -10)
