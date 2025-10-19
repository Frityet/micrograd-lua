local Figure = require("termplot.Figure")
local Canvas = require("termplot.Canvas")
local colour = require("termplot.colour")
local record termplot
    Figure: Figure
    Canvas: Canvas
    type Colour = colour.Colour
end
termplot.Figure = Figure
termplot.Canvas = Canvas

function termplot.plot(x: {number}, y: {number}, opts?: Figure)
    local fig = Figure:create(opts)
    fig:line(x, y, {
        label = opts and opts.title or nil,
        colour = opts and opts.axis_colour or nil,

    })
    return fig:show()
end

function termplot.scatter(x: {number}, y: {number}, opts?: Figure)
    local fig = Figure:create(opts)
    fig:scatter(x, y, {
        label = opts and opts.title or nil,
        colour = opts and opts.axis_colour or nil,
    })
    return fig:show()
end

function termplot.bar(x: {string}, y: {number}, opts?: Figure)
    local fig = Figure:create(opts)
    fig:bar(x, y, {
        label = opts and opts.title or nil,
        colour = opts and opts.axis_colour or nil,
    })
    return fig:show()
end

function termplot.histogram(data: {number}, opts?: Figure)
    local fig = Figure:create(opts)
    fig:histogram(data, {
        label = opts and opts.title or nil,
        colour = opts and opts.axis_colour or nil,
    })
    return fig:show()
end

function termplot.heatmap(Z: {{number}}, opts?: Figure)
    local fig = Figure:create(opts)
    fig:heatmap(Z, {
        label = opts and opts.title or nil,
        colour = opts and opts.axis_colour or nil,
    })
    return fig:show()
end

return termplot

