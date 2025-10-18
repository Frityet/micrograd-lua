local ffi = require("ffi")


local record Path is {string}
    is_absolute: boolean
    
    metamethod __div: function(self, string | Path): Path

    __index: self
    __name: string
    separator: string
end
Path.__index = Path
Path.__name = "Path"
Path.separator = package.config:sub(1, 1)

ffi.cdef [[
    char *getcwd(char *buf, size_t size);
]]

local sz = 0xFFFF
local cwd_buf = ffi.new("char[?]", sz)
function Path.current_directory(): string
    return ffi.string(assert(ffi.C.getcwd(cwd_buf, sz), "Could not get current working directory"))
end

function Path:create(p: string | {string}, is_absolute?: boolean): self
    local parts: self = p is string and {} or p
    if p is string then
        if p:sub(1,1) == self.separator then
            self.is_absolute = is_absolute or true
            p = p:sub(2)
        else
            self.is_absolute = is_absolute or false
        end

        for part in p:gmatch("[^"..self.separator.."]+") do
            table.insert(parts, part)
        end
    else
        self.is_absolute = not not is_absolute
    end

    return setmetatable(parts, self as metatable<self>)
end

function Path:__tostring(): string
    return (self.is_absolute and self.separator or "")..table.concat(self, self.separator)
end

function Path:__div(p: string | Path): Path
    local other = p is string and Path:create(p) or p as Path
    local new_parts: {string} = {}
    for _, part in ipairs(self) do table.insert(new_parts, part) end
    for _, part in ipairs(other) do table.insert(new_parts, part) end
    return Path:create(new_parts, self.is_absolute)
end

function Path:parent(): Path
    local new_parts: {string} = {}
    for i = 1, #self - 1 do table.insert(new_parts, self[i]) end
    return Path:create(new_parts, self.is_absolute)
end

function Path:extension(): string | nil
    local last = self[#self]
    local dot_idx = last:match(".*()%.") or 0
    if dot_idx > 0 then
        return last:sub(dot_idx)
    end
    return nil
end

function Path:basename(): string
    return self[#self]
end

function Path:filename(): string
    local last = self[#self]
    local dot_idx = last:match(".*()%.") or (#last + 1)
    return last:sub(1, dot_idx - 1)
end

function Path:is_directory(): boolean
    return self:extension() == nil
end

function Path:exists(): boolean
    local f = io.open(tostring(self), "r")
    if f then
        f:close()
        return true
    end
    return false
end

return Path
