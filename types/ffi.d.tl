
local record libffi
    -- type CData = integer | number | string | { string | integer : CData }
    -- type CType = string | CData
    -- type CFunction = function(...: any): CData
    -- type CNamespace = { string : CFunction | CData }

    -- load:       function(string): { string : CFunction | CData }
    -- load:       function<T>(string): T
    -- cdef:       function(string)
    -- new:        function(ct: CType, nelem?: integer, ...: any): CData
    -- typeof:     function(CType, ...: any): CType
    -- cast:       function(CType, ...: any): CType
    -- metatype:   function(CType, metatable): CType
    -- gc:         function(CData, function(CData)): CData
    -- sizeof:     function(ct: CType, nelem?: integer): integer | nil
    -- alignof:    function(CType): integer
    -- offsetof:   function(CType, string): integer, integer | nil, integer | nil
    -- istype:     function(CType, any): boolean
    -- errno:      function(newerr?: integer): integer
    -- string:     function(ptr: CData, len?: integer): string
    -- copy:       function(CData, CData, integer)
    -- copy:       function(CData, string)
    -- fill:       function(CData, integer, CData)
    -- abi:        function(string): boolean
    -- os:         string
    -- arch:       string
    interface CType where type(self) == "ctype"
        metamethod __tostring: function(self): string
    end

    interface CData where type(self) == "cdata"
        metamethod __index: function(self, string | integer): any
        metamethod __call: function<T>(...: any): T
        metamethod __tostring: function(self): string
    end

    enum OperatingSystem
        "Windows"
        "Linux"
        "OSX"
        "BSD"
        "POSIX"
        "Solaris"
        "Android"
        "iOS"
        "PS3"
        "PSP"
        "Other"
    end

    enum Architecture
        "x86"
        "x64"
        "arm"
        "arm64"
        "ppc"
        "ppcspe"
        "mips"
        "mipsel"
        "mips64"
        "mips64el"
        "s390x"
        "sparc"
        "other"
    end

    type CNamespace = { string : CData }

    cdef: function(string)
    typeof: function(string | CType | CData): CType
    load: function(string): CNamespace
    new: function(ct: CType | string, ...: any): CData
    cast: function(ct: CType | string, ...: any): CData
    metatype: function(ct: CType | string, metatable: metatable): CType
    gc: function(v: CData, f: function(CData)): CData
    sizeof: function(ct: CType | string | CData, nelem?: integer): integer | nil
    alignof: function(ct: CType | string | CData): integer
    offsetof: function(ct: CType | string | CData, field: string): integer, integer | nil, integer | nil
    istype: function(ct: CType | string | CData, v: any): boolean
    errno: function(newerr?: integer): integer
    string: function(ptr: CData, len?: integer): string
    copy: function(dest: CData, src: CData | string, size: integer)
    fill: function(dest: CData, size: integer, value: CData)
    abi: function(what: string): boolean
    
    C: CNamespace
    arch: Architecture
    os: OperatingSystem
end

return libffi
