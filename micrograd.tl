local function deriv(f: (function(number): number), h?: number): function(number): number
    h = h or 1.0e-14
    return function(x: number): number return (f(x+h) - f(x))/h end
end

local function f(x: number): number return 3*x^2 - 4*x + 5 end

local slp = deriv(f)

local xs, ys, slps, rel: {number}, {number}, {number}, {number:number} = {}, {}, {}, {}

for i = -5, 5, 0.25 do
    table.insert(xs, i)
    local v = f(i)
    table.insert(ys, v)
    table.insert(slps, slp(i))
    rel[i] = v
end

print(xs[1], ys[1], slps[1])
