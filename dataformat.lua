local config = require("config")

-- state serialization/deserialization
-- i really hope this code is simple enough to understand without comments
-- because i forgot to comment it and i don't wanna do it now

local function split(line, delim)
    local arr = {}
    local last = 1
    for e, s in line:gmatch("()"..delim.."()") do
        arr[#arr+1] = line:sub(last, e - 1)
        last = s
    end
    arr[#arr+1] = line:sub(last, -1)
    return arr
end

local function split1(line, delim)
    local e, s = line:match("()"..delim.."()")
    if not e then error("split1: delim not found in line:\n\t"..line) end
    return line:sub(1, e - 1), line:sub(s, -1)
end

local function parse_line(state, str)
    local a, b = split1(str, "|")
    local t = state
    a = split(a, " ")
    local last = a[#a]
    a[#a] = nil
    for _,v in ipairs(a) do
        if not t[v] then t[v] = {} end
        t = t[v]
    end
    t[last] = split(b, " ")
end

local function parse(str)
    local state = {}
    local N, i = str:match("^(%d-)\n()")
    N = tonumber(N) or config.N
    for line in str:sub(i):gmatch("(.-)\n") do
        parse_line(state, line)
    end
    return state, N
end

local function encode_r(t, N)
    if N == 0 then
        return { "|"..table.concat(t, " ") }
    end

    local flat = {}
    for k,v in pairs(t) do
        if N ~= 1 then
            k = k .. " "
        end
        for _,v2 in ipairs(encode_r(v, N - 1)) do
            flat[#flat+1] = k .. v2
        end
    end

    return flat
end

local function encode(state, N)
    return tostring(N).."\n"..table.concat(encode_r(state, N), "\n").."\n"
end

local function from_file(filename)
    local state = {}
    local file = io.open(filename, "r")
    if not file then return {}, config.N end
    local content = file:read("*a")
    file:close()
    return parse(content)
end

local function to_file(state, N, filename)
    local file = io.open(filename, "wb")
    if not file then print(filename) end
    file:write(encode(state, N))
    file:close()
end

return {
    parse=parse, encode=encode,
    from_file=from_file, to_file=to_file,
}
