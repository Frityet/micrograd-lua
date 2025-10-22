local plot = require("termplot.init")
local colour = require("termplot.colour")
local Value = require("Value")
local Path  = require("Path")

local utilities = require("utilities")

local function plot_f(f: (function(number): number), opts: plot.Figure, n?: integer, start?: integer, step?: number)
    n = n or 100
    start = start or 0
    local x, y: {number}, {number} = {}, {}

    for i = start, start + n, step or 1 do
        local xv = i
        local yv = f(xv)
        x[#x+1] = xv
        y[#y+1] = yv
    end

    return plot.plot(x, y, opts)
end

math.randomseed(os.time())

plot_f(utilities.tanh, {
    title = "y = tanh(x)",
    x_label = "x",
    y_label = "tanh(x)",

    x_min = -5,
    x_max = 5,
    y_min = -1.25,
    y_max = 1.25,

    axis_colour = colour.random(),
}, 10, -5, 0.2)

local e = Value:create(math.exp(1), 'e'); e.gradient = 1

local x1, x2 = Value:create(2, 'x1'), Value:create(0, 'x2')
local w1, w2 = Value:create(-3, 'w1'), Value:create(1.0, 'w2')
local b = Value:create(6.88137, 'b')

local x1w1 = x1 * w1
local x2w2 = x2 * w2

local x1w1_x2w2 = x1w1 + x2w2

local n = x1w1_x2w2 + b; n.label = 'n'

local o = (e^(n*2)-1)/(e^(n*2)+1); o.label = 'o'

o.gradient = 1
o:fill_gradients()
-- n.gradient = 1 - utilities.tanh(n.data)^2
-- x1w1_x2w2.gradient = n.gradient
-- b.gradient = n.gradient

-- x1w1.gradient = x1w1_x2w2.gradient
-- x2w2.gradient = x1w1_x2w2.gradient

-- x1.gradient = w1.data * x1w1.gradient
-- w1.gradient = x1.data * x1w1.gradient

-- x2.gradient = w2.data * x2w2.gradient
-- w2.gradient = x2.data * x2w2.gradient

local p = Path:create("out2.png")
utilities.graph.dot(o:graphviz(), p)

print(o)
