local record Value is {Value}
    enum Operator
        "+"
        "-"
        "*"
        "/"
        "^"
        "unm"
    end

    data: number
    operator: Operator | nil
    label: string | nil
    gradient: number
    __index: self
    __name: string

    metamethod __add: function(self, number | Value): Value
    metamethod __sub: function(self, number | Value): Value
    metamethod __mul: function(self, number | Value): Value
    metamethod __div: function(self, number | Value): Value
    metamethod __pow: function(self, number | Value): Value
    metamethod __unm: function(self): Value
    metamethod __tostring: function(self): string

end
Value.__index = Value
Value.__name = "Value"

function Value:create(data: number, label?: string, children?: Value, op?: Value.Operator): Value
    children = children or {};
    children.data = data
    children.label = label
    children.operator = op
    children.gradient = 0
    return setmetatable(children, self as metatable<Value>)
end

local function get_num(v: number | Value): number return v is number and v or v.data end
local function get_val(v: number | Value): Value return v is number and Value:create(v) or v as Value end

function Value:__add(other: number | Value): Value
    return Value:create(self.data + get_num(other), nil, { self, get_val(other) }, '+')
end

function Value:__sub(other: number | Value): Value
    return Value:create(self.data - get_num(other), nil, { self, get_val(other) }, '-')
end

function Value:__mul(other: number | Value): Value
    return Value:create(self.data * get_num(other), nil, { self, get_val(other) }, '*')
end

function Value:__div(other: number | Value): Value
    return Value:create(self.data / get_num(other), nil, { self, get_val(other) }, '/')
end

function Value:__pow(other: number | Value): Value
    return Value:create(self.data ^ get_num(other), nil, { self, get_val(other) }, '^')
end

function Value:__unm(): Value
    return Value:create(-self.data, nil, { self }, 'unm')
end

function Value:__tostring(): string
    local s = "{ "
    for i, v in ipairs(self) do
        s = s..tostring(v)
        if i < #self then s = s..", " end
    end
    s = s.." }"

    return string.format("<%s: data=%.2f, gradient=%.2f operator=%s, %s>", self.__name, self.data, self.gradient, self.operator, s)
end

function Value:tree(): string
    local function fmt(n: number): string
        local s = string.format("%.6f", n)
        s = s:gsub("(%..-)0+$", "%1")
        s = s:gsub("%.$", "")
        return s
    end

    local function op_to_str(op: Value.Operator): string
        return (op == "unm") and "-" or op
    end

    local function infix(v: Value): string
        if v.operator == nil then
            return v.label ~= nil and v.label or fmt(v.data)
        end

        if v.operator == "unm" then
            return "-("..infix(v[1])..")"
        end

        local left = infix(v[1])
        local right = infix(v[2])
        return "("..left.." "..op_to_str(v.operator).." "..right..")"
    end

    local function node_label(v: Value, is_root: boolean): string
        if is_root then
            return fmt(v.data)
        end

        local base: string
        if v.operator ~= nil then
            base = op_to_str(v.operator).." = "..fmt(v.data)
        else
            base = fmt(v.data)
        end

        if v.label ~= nil and v.label ~= "" then
            return v.label..": "..base
        end
        return base
    end

    local function build_tree(v: Value, prefix: string, is_last: boolean, is_root: boolean): string
        local line = prefix..(is_last and "└── " or "├── ")..node_label(v, is_root).."\n"

        local result = line
        local new_prefix = prefix..(is_last and "    " or "│   ")
        for i = 1, #v do
            local child_is_last = (i == #v)
            result = result..build_tree(v[i], new_prefix, child_is_last, false)
        end
        return result
    end

    local tree = build_tree(self, "", true, true)
    return tree
end

function Value:graphviz(): string
    local function fmt(n: number): string
        local s = string.format("%.6f", n)
        s = s:gsub("(%..-)0+$", "%1")
        s = s:gsub("%.$", "")
        return s
    end

    local function op_to_str(op: Value.Operator): string
        return (op == "unm") and "-" or op
    end

    local function esc(s: string): string
        -- Escape for DOT labels
        s = s:gsub("\\", "\\\\")
        s = s:gsub("\"", "\\\"")
        s = s:gsub("\n", "\\n")
        return s
    end

    local lines = {
        "digraph ComputationGraph {",
        "  rankdir=LR;",
        "  nodesep=0.4;",
        "  node [shape=record, height=0.28, fontname=\"Helvetica\"];",
        "  edge [arrowsize=0.7];"
    }

    -- Unique ids for Value tables
    local ids: {Value:string} = {}
    local counter = 0
    local function id_for(v: Value): string
        local id = ids[v]
        if id == nil then
            counter = counter + 1
            id = "v" .. tostring(counter)
            ids[v] = id
        end
        return id
    end

    local have_value_node = {}
    local have_op_node = {}
    local have_edge = {}

    local function value_label(v: Value): string
        local parts = {}
        if v.label ~= nil and v.label ~= "" then
            table.insert(parts, esc(v.label))
        end
        table.insert(parts, "data=" .. fmt(v.data))
        table.insert(parts, "grad=" .. fmt(v.gradient))
        -- record label (Graphviz): { field | field | ... }
        return "{ " .. table.concat(parts, " | ") .. " }"
    end

    local function ensure_value_node(v: Value): string
        local vid = id_for(v)
        if not have_value_node[vid] then
            table.insert(lines, string.format('  %s [label="%s"];', vid, value_label(v)))
            have_value_node[vid] = true
        end
        return vid
    end

    local function ensure_op_node(v: Value): string
        local opid = id_for(v) .. "_op"
        if not have_op_node[opid] then
            local op = op_to_str((v.operator as Value.Operator))
            table.insert(lines, string.format('  %s [label="%s", shape=circle, width=0.35, height=0.35, fixedsize=true];', opid, esc(op)))
            have_op_node[opid] = true
        end
        return opid
    end

    local function add_edge(a: string, b: string)
        local key = a .. "->" .. b
        if not have_edge[key] then
            table.insert(lines, string.format("  %s -> %s;", a, b))
            have_edge[key] = true
        end
    end

    local seen = {}

    local function walk(v: Value)
        ensure_value_node(v)

        if v.operator ~= nil then
            local opid = ensure_op_node(v)
            local vid = id_for(v)
            -- op node produces this value
            add_edge(opid, vid)

            -- children feed into the op node
            for i = 1, #v do
                local c = (v[i] as Value)
                local cid = ensure_value_node(c)
                add_edge(cid, opid)
                if not seen[c] then
                    seen[c] = true
                    walk(c)
                end
            end
        end
    end

    seen[self] = true
    walk(self)

    table.insert(lines, "}")
    return table.concat(lines, "\n")
end


return Value
