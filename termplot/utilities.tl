local record utilities end

function utilities.map<T1, T2>(tbl1: {T1}, fn: function(T1): T2): {T2}
    local tbl2: {T2} = {}
    for i, v in ipairs(tbl1) do
        tbl2[i] = fn(v)
    end
    return tbl2
end

function utilities.clamp(x: number, min: number, max: number): number
    if x < min then
        return min
    elseif x > max then
        return max
    else
        return x
    end
end

function utilities.linear_interpolate(y0: number, y1: number, t: number): number
    return (1 - t) * y0 + t * y1
end

function utilities.linear_interpolate_colour(c0: {integer, integer, integer}, c1: {integer, integer, integer}, t: number): {integer, integer, integer}
    return {
        utilities.linear_interpolate(c0[1], c1[1], t) as integer,
        utilities.linear_interpolate(c0[2], c1[2], t) as integer,
        utilities.linear_interpolate(c0[3], c1[3], t) as integer,
    }
end

function utilities.step(raw: number, round?: boolean): number
    local exp = math.floor(math.log(raw)/math.log(10))
    local f = raw / 10^exp
    local nf: number
    if round then
        if f < 1.5 then nf = 1
        elseif f < 3 then nf = 2
        elseif f < 7 then nf = 5
        else nf = 10 end
    else
        if f <= 1 then nf = 1
        elseif f <= 2 then nf = 2
        elseif f <= 5 then nf = 5
        else nf = 10 end
    end
    return nf * 10^exp
end

function utilities.ticks(minv: number, maxv: number, nticks: number): {number}
    if minv == maxv then
        if minv == 0 then minv, maxv = -1, 1 else minv, maxv = minv*0.9, maxv*1.1 end
    end
    if minv > maxv then minv, maxv = maxv, minv end
    nticks = nticks or 5
    local range = utilities.step(maxv - minv, false)
    local step  = utilities.step(range/(nticks-1), true)
    local lo = math.floor(minv/step)*step
    local hi = math.ceil(maxv/step)*step
    local res: {number} = {}
    local v = lo
    local n = 0
    while v <= hi + 1e-12 and n < 1000 do
        res[#res+1] = v
        v = v + step
        n = n + 1
    end
    return res
end


return utilities
