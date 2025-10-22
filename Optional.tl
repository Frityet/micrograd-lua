local record optional
    interface Base
    end

    record Some<T> is Base where self.value
        value: T
    end

    record None is Base where not self.value
        value: nil
    end

    type Optional<T> = Some<T> | None
end

function optional.some<T>(x: T): optional.Some<T>
    return { value = x }
end

function optional.none(): optional.None
    return {}
end

function optional.from_nilable<T>(x: T | nil): optional.Optional<T>
    return x is nil and optional.None or optional.some(x)
end

function optional.unwrap<T>(x: optional.Optional<T>): T
    if x is optional.None then error("Attempt to unwrap None") else return x.value end
end

function optional.unwrap_or<T>(x: optional.Optional<T>, other: T | function(): T): T
    if x is optional.None then
        if other is function(): T then return other() else return other end
    else
        return x.value
    end
end

function optional.map<T, U>(x: optional.Optional<T>, f: function(T): optional.Optional<U>): optional.Optional<U>
    if x is optional.None then return optional.None else return f(x.value) end
end

function optional.fn_from_nillable<T, TRet>(f: function(T): TRet | nil): function(T): optional.Optional<TRet>
    return function(x: T): optional.Optional<TRet> return optional.from_nilable(f(x)) end
end

local x: optional.Optional<string> = arg[1] == "hi" and optional.None or optional.some("43")

local res = x |> optional.map(optional.fn_from_nillable(tonumber))
print(not res is optional.None and res.value)

