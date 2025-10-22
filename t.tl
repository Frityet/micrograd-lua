local Value = require("Value")
local utilities = require("utilities")
local Path = require("Path")

local val: {string:function(number): Value} = setmetatable({}, {
    __index = function(_: self, k: string): function(number): Value
        return function(n: number): Value return Value:create(n, k) end
    end
})

local h = 1.0e-10

local function f(): Value, Value, Value
    local a = val.a(2.0)
    local b = val.b(-3.0)
    local c = val.c(10.0)
    local e = a * b; e.label = 'e'
    local d = e + c; d.label = 'd'
    local f = val.f(-2.0)
    d.gradient = f.data
    f.gradient = d.data
    local L = d * f; L.label = 'L1'
    L.gradient = 1

    c.gradient = d.gradient * L.gradient
    e.gradient = d.gradient * L.gradient

    a.gradient = e.gradient * (b.data)
    b.gradient = e.gradient * (a.data)
    local L1 = L:clone()

    a = val.a(2.0)
    b = val.b(-3.0)
    c = val.c(10.0)
    e = a * b; e.label = 'e'
    d = e + c; d.label = 'd'
    ---d = d + h
    f = val.f(-2.0)
    L = d * f; L.label = 'L2'
    L = L + h
    local L2 = L:clone()
    return (L2 - L1)/h, L1, L2
end

local res, L1, L2 = f()
print(L1:equation())
print(L1.data, L2.data, res.data)
utilities.graph.dot(L1:graphviz(), Path:create("L1.png"))
utilities.graph.dot(res:graphviz(), Path:create("full.png"))

