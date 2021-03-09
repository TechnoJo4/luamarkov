-- luajit batch.lua ./data.txt amount ./out.txt

local args = { ... }

math.randomseed(os.time())

local chain = require("init")
local c = chain(args[1])

local input = {}
for i=4,#args do input[i-4] = args[i] end

local file = io.open(args[3], "wb")
for i=1,tonumber(args[2]) do
    file:write(c.generate(input), "\r\n")
end
file:write()
