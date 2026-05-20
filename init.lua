--- Nar.Base.Tests native implementations (Lua).
--- Same as Nar.Base (test suite uses identical natives).
local rt = require("lunar.runtime")
local Object = rt.Object

-- Helper: compare two values according to Nar semantics
local function cmpList(la, lb)
    if #la < #lb then
        return -1
    elseif #la > #lb then
        return 1
    else
        for i = 1, #la do
            local n = cmp(la[i], lb[i])
            if n ~= 0 then
                return n
            end
        end
        return 0
    end
end

local function cmp(a, b)
    local ka, kb = rt:objectKind(a), rt:objectKind(b)
    if ka ~= kb then
        error("types are not equal")
    end

    local OK = Object.ObjectKind
    if ka == OK.INT or ka == OK.FLOAT or ka == OK.CHAR or ka == OK.STRING then
        local va, vb = a.value, b.value
        if va < vb then return -1 elseif va > vb then return 1 else return 0 end
    elseif ka == OK.LIST or ka == OK.TUPLE then
        local la, lb = rt:toList(a), rt:toList(b)
        return cmpList(la, lb)
    elseif ka == OK.UNIT then
        return 0
    elseif ka == OK.RECORD then
        local ra, rb = rt:toRecord(a), rt:toRecord(b)
        local ka_keys, kb_keys = {}, {}
        for k, _ in pairs(ra) do ka_keys[#ka_keys + 1] = k end
        for k, _ in pairs(rb) do kb_keys[#kb_keys + 1] = k end
        table.sort(ka_keys)
        table.sort(kb_keys)
        if #ka_keys < #kb_keys then
            return -1
        elseif #ka_keys > #kb_keys then
            return 1
        else
            for i = 1, #ka_keys do
                if ka_keys[i] ~= kb_keys[i] then
                    return ka_keys[i] < kb_keys[i] and -1 or 1
                end
            end
            for i = 1, #ka_keys do
                local c = cmp(ra[ka_keys[i]], rb[kb_keys[i]])
                if c ~= 0 then return c end
            end
            return 0
        end
    elseif ka == OK.FUNC then
        local ia, ib = a.index or 0, b.index or 0
        if ia < ib then return -1 elseif ia > ib then return 1 else return 0 end
    else
        error("unsupported kind for comparison")
    end
end

-- === Nar.Base.Basics ===
rt:registerDef("Nar.Base.Basics", "eq", function(rt, a, b)
    return rt:makeBool(cmp(a, b) == 0)
end, 2)

rt:registerDef("Nar.Base.Basics", "neq", function(rt, a, b)
    return rt:makeBool(cmp(a, b) ~= 0)
end, 2)

rt:registerDef("Nar.Base.Basics", "lt", function(rt, a, b)
    return rt:makeBool(cmp(a, b) < 0)
end, 2)

rt:registerDef("Nar.Base.Basics", "gt", function(rt, a, b)
    return rt:makeBool(cmp(a, b) > 0)
end, 2)

rt:registerDef("Nar.Base.Basics", "le", function(rt, a, b)
    return rt:makeBool(cmp(a, b) <= 0)
end, 2)

rt:registerDef("Nar.Base.Basics", "ge", function(rt, a, b)
    return rt:makeBool(cmp(a, b) >= 0)
end, 2)

rt:registerDef("Nar.Base.Basics", "not", function(rt, x)
    return rt:makeBool(not rt:toBool(x))
end, 1)

rt:registerDef("Nar.Base.Basics", "and", function(rt, x, y)
    return rt:makeBool(rt:toBool(x) and rt:toBool(y))
end, 2)

rt:registerDef("Nar.Base.Basics", "or", function(rt, x, y)
    return rt:makeBool(rt:toBool(x) or rt:toBool(y))
end, 2)

rt:registerDef("Nar.Base.Basics", "xor", function(rt, x, y)
    local a, b = rt:toBool(x), rt:toBool(y)
    return rt:makeBool((a and not b) or (not a and b))
end, 2)

-- === Nar.Base.Math ===
rt:registerDef("Nar.Base.Math", "add", function(rt, x, y)
    local OK = Object.ObjectKind
    if rt:objectKind(x) ~= rt:objectKind(y) then error("types are not equal") end
    local kind = rt:objectKind(x)
    local v = x.value + y.value
    if kind == OK.INT then return rt:makeInt(v)
    elseif kind == OK.FLOAT then return rt:makeFloat(v)
    else error("unsupported kind") end
end, 2)

rt:registerDef("Nar.Base.Math", "sub", function(rt, x, y)
    local OK = Object.ObjectKind
    if rt:objectKind(x) ~= rt:objectKind(y) then error("types are not equal") end
    local kind = rt:objectKind(x)
    local v = x.value - y.value
    if kind == OK.INT then return rt:makeInt(v)
    elseif kind == OK.FLOAT then return rt:makeFloat(v)
    else error("unsupported kind") end
end, 2)

rt:registerDef("Nar.Base.Math", "mul", function(rt, x, y)
    local OK = Object.ObjectKind
    if rt:objectKind(x) ~= rt:objectKind(y) then error("types are not equal") end
    local kind = rt:objectKind(x)
    local v = x.value * y.value
    if kind == OK.INT then return rt:makeInt(v)
    elseif kind == OK.FLOAT then return rt:makeFloat(v)
    else error("unsupported kind") end
end, 2)

rt:registerDef("Nar.Base.Math", "div", function(rt, x, y)
    local OK = Object.ObjectKind
    if rt:objectKind(x) ~= rt:objectKind(y) then error("types are not equal") end
    if rt:objectKind(x) == OK.INT then
        if y.value == 0 then return rt:makeInt(0) end
        return rt:makeInt(math.floor(x.value / y.value))
    else
        return rt:makeFloat(x.value / y.value)
    end
end, 2)

rt:registerDef("Nar.Base.Math", "neg", function(rt, x)
    if rt:objectKind(x) == Object.ObjectKind.INT then
        return rt:makeInt(-x.value)
    else
        return rt:makeFloat(-x.value)
    end
end, 1)

rt:registerDef("Nar.Base.Math", "abs", function(rt, x)
    if x.value >= 0 then return x
    else
        if rt:objectKind(x) == Object.ObjectKind.INT then
            return rt:makeInt(-x.value)
        else
            return rt:makeFloat(-x.value)
        end
    end
end, 1)

rt:registerDef("Nar.Base.Math", "toPower", function(rt, pow, num)
    if rt:objectKind(pow) ~= rt:objectKind(num) then error("types are not equal") end
    local kind = rt:objectKind(num)
    local v = num.value ^ pow.value
    if kind == Object.ObjectKind.INT then return rt:makeInt(v)
    else return rt:makeFloat(v) end
end, 2)

rt:registerDef("Nar.Base.Math", "isNan", function(rt, n)
    return rt:makeBool(n.value ~= n.value)
end, 1)

rt:registerDef("Nar.Base.Math", "isInf", function(rt, n)
    local v = n.value
    return rt:makeBool(v == math.huge or v == -math.huge)
end, 1)

rt:registerDef("Nar.Base.Math", "toFloat", function(rt, n)
    return rt:makeFloat(tonumber(n.value) or 0)
end, 1)

rt:registerDef("Nar.Base.Math", "round", function(rt, n)
    return rt:makeInt(math.floor(n.value + 0.5))
end, 1)

rt:registerDef("Nar.Base.Math", "floor", function(rt, n)
    return rt:makeInt(math.floor(n.value))
end, 1)

rt:registerDef("Nar.Base.Math", "ceil", function(rt, n)
    return rt:makeInt(math.ceil(n.value))
end, 1)

rt:registerDef("Nar.Base.Math", "trunc", function(rt, n)
    return rt:makeInt(math.floor(n.value > 0 and n.value or -n.value) * (n.value > 0 and 1 or -1))
end, 1)

rt:registerDef("Nar.Base.Math", "sqrt", function(rt, n)
    return rt:makeFloat(math.sqrt(n.value))
end, 1)

rt:registerDef("Nar.Base.Math", "remainderBy", function(rt, n, x)
    return rt:makeInt(x.value % n.value)
end, 2)

rt:registerDef("Nar.Base.Math", "modBy", function(rt, modulus, x)
    if modulus.value == 0 then return rt:makeInt(0) end
    local answer = x.value % modulus.value
    if (answer > 0 and modulus.value < 0) or (answer < 0 and modulus.value > 0) then
        return rt:makeInt(answer + modulus.value)
    else
        return rt:makeInt(answer)
    end
end, 2)

rt:registerDef("Nar.Base.Math", "logBase", function(rt, base, n)
    return rt:makeFloat(math.log(n.value) / math.log(base.value))
end, 2)

-- === Nar.Base.Bitwise ===
rt:registerDef("Nar.Base.Bitwise", "and", function(rt, x, y)
    return rt:makeInt(bit32.band(x.value, y.value))
end, 2)

rt:registerDef("Nar.Base.Bitwise", "or", function(rt, x, y)
    return rt:makeInt(bit32.bor(x.value, y.value))
end, 2)

rt:registerDef("Nar.Base.Bitwise", "xor", function(rt, x, y)
    return rt:makeInt(bit32.bxor(x.value, y.value))
end, 2)

rt:registerDef("Nar.Base.Bitwise", "complement", function(rt, x)
    return rt:makeInt(bit32.bnot(x.value))
end, 1)

rt:registerDef("Nar.Base.Bitwise", "shiftLeftBy", function(rt, x, y)
    return rt:makeInt(bit32.lshift(y.value, x.value))
end, 2)

rt:registerDef("Nar.Base.Bitwise", "shiftRightBy", function(rt, x, y)
    return rt:makeInt(bit32.arshift(y.value, x.value))
end, 2)

rt:registerDef("Nar.Base.Bitwise", "shiftRightZfBy", function(rt, x, y)
    return rt:makeInt(bit32.rshift(y.value, x.value))
end, 2)

-- === Nar.Base.Char ===
rt:registerDef("Nar.Base.Char", "toUpper", function(rt, char)
    return rt:makeChar(string.byte(string.upper(string.char(char.value))))
end, 1)

rt:registerDef("Nar.Base.Char", "toLower", function(rt, char)
    return rt:makeChar(string.byte(string.lower(string.char(char.value))))
end, 1)

rt:registerDef("Nar.Base.Char", "toCode", function(rt, char)
    return rt:makeInt(char.value)
end, 1)

rt:registerDef("Nar.Base.Char", "fromCode", function(rt, code)
    return rt:makeChar(code.value)
end, 1)

-- === Nar.Base.Debug ===
local function valueToString(x)
    local OK = Object.ObjectKind
    local kind = Object.getKind(x)
    if kind == OK.CHAR then
        return string.format("'%c'", x.value)
    elseif kind == OK.STRING then
        return string.format('"%s"', x.value:gsub('"', '\\"'))
    elseif kind == OK.INT or kind == OK.FLOAT then
        return tostring(x.value)
    else
        return "{...}"
    end
end

rt:registerDef("Nar.Base.Debug", "toString", function(rt, x)
    return rt:makeString(valueToString(x))
end, 1)

rt:registerDef("Nar.Base.Debug", "log", function(rt, msg, a)
    io.write(rt:toString(msg) .. valueToString(a) .. "\n")
    return a
end, 2)

rt:registerDef("Nar.Base.Debug", "todo", function(rt, msg)
    io.stderr:write(rt:toString(msg) .. "\n")
    return rt:makeUnit()
end, 1)

-- === Nar.Base.String ===
rt:registerDef("Nar.Base.String", "length", function(rt, s)
    return rt:makeInt(#rt:toString(s))
end, 1)

rt:registerDef("Nar.Base.String", "reverse", function(rt, s)
    return rt:makeString(string.reverse(rt:toString(s)))
end, 1)

rt:registerDef("Nar.Base.String", "append", function(rt, a, b)
    return rt:makeString(rt:toString(a) .. rt:toString(b))
end, 2)

rt:registerDef("Nar.Base.String", "split", function(rt, sep, string)
    local str = rt:toString(string)
    local pattern = rt:toString(sep)
    local result = {}
    for part in str:gmatch("([^" .. pattern .. "]+)") do
        table.insert(result, rt:makeString(part))
    end
    return rt:makeList(result)
end, 2)

rt:registerDef("Nar.Base.String", "join", function(rt, sep, strings)
    local str_list = rt:toList(strings)
    local parts = {}
    for _, s in ipairs(str_list) do
        table.insert(parts, rt:toString(s))
    end
    return rt:makeString(table.concat(parts, rt:toString(sep)))
end, 2)

rt:registerDef("Nar.Base.String", "words", function(rt, string)
    local str = rt:toString(string):match("^%s*(.-)%s*$")
    local result = {}
    for word in str:gmatch("%S+") do
        table.insert(result, rt:makeString(word))
    end
    return rt:makeList(result)
end, 1)

rt:registerDef("Nar.Base.String", "lines", function(rt, string)
    local str = rt:toString(string):match("^%s*(.-)%s*$")
    local result = {}
    for line in str:gmatch("[^\n\r]+") do
        table.insert(result, rt:makeString(line))
    end
    return rt:makeList(result)
end, 1)

rt:registerDef("Nar.Base.String", "slice", function(rt, begin, end_, s)
    local str = rt:toString(s)
    local b = rt:toInt(begin) + 1  -- Lua is 1-indexed
    local e = rt:toInt(end_)
    return rt:makeString(str:sub(b, e))
end, 3)

rt:registerDef("Nar.Base.String", "contains", function(rt, sub, string)
    return rt:makeBool(rt:toString(string):find(rt:toString(sub), 1, true) ~= nil)
end, 2)

rt:registerDef("Nar.Base.String", "startsWith", function(rt, sub, string)
    return rt:makeBool(rt:toString(string):sub(1, #rt:toString(sub)) == rt:toString(sub))
end, 2)

rt:registerDef("Nar.Base.String", "endsWith", function(rt, sub, string)
    local s = rt:toString(string)
    local u = rt:toString(sub)
    return rt:makeBool(s:sub(-#u) == u)
end, 2)

rt:registerDef("Nar.Base.String", "toUpper", function(rt, s)
    return rt:makeString(string.upper(rt:toString(s)))
end, 1)

rt:registerDef("Nar.Base.String", "toLower", function(rt, s)
    return rt:makeString(string.lower(rt:toString(s)))
end, 1)

rt:registerDef("Nar.Base.String", "trim", function(rt, s)
    return rt:makeString(rt:toString(s):match("^%s*(.-)%s*$"))
end, 1)

rt:registerDef("Nar.Base.String", "trimLeft", function(rt, s)
    return rt:makeString(rt:toString(s):match("^%s*(.*)"))
end, 1)

rt:registerDef("Nar.Base.String", "trimRight", function(rt, s)
    return rt:makeString(rt:toString(s):match("(.-)%s*$"))
end, 1)
