local record libbit
    rol: function(x: integer, n: integer): integer
    rshift: function(x: integer, n: integer): integer
    ror: function(x: integer, n: integer): integer
    bswap: function(x: integer): integer
    bxor: function(a: integer, b: integer): integer
    bor: function(a: integer, b: integer): integer
    arshift: function(x: integer, n: integer): integer
    bnot: function(x: integer): integer
    tobit: function(x: integer): integer
    lshift: function(x: integer, n: integer): integer
    tohex: function(x: integer, n?: integer): string
    band: function(a: integer, b: integer): integer
end

return libbit
