-- luajit repl.lua ./data.txt

local args = { ... }

math.randomseed(os.time())

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

local chain = require("init")
local c = chain(args[1])
while true do
    io.write("> ")
    local input = io.read("*l")
    if input == "" then
        print(c.generate({}))
    else
        print(c.generate(split(input, " ")))
    end
end
