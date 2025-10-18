local Value = require("Value")
local utilities = require("utilities")

local a = Value:create(2.0, 'a')
local b = Value:create(3.0, 'b')

local c = a * b + a + b + 1
c.label = 'c'

print(c:tree())
print(c)

utilities.render_graphviz(c:graphviz(), "out.png")

