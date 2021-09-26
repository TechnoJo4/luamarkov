-- luajit batch.lua ./data.json amount ./out.txt

local args = { ... }

math.randomseed(os.time())

local chain = require("chain")
local c = chain.load(args[1])

--local input = {}
--for i=4,#args do input[i-4] = args[i] end

local file = args[3] and io.open(args[3], "wb") or io.stdout
for i=1,tonumber(args[2]) do
    file:write(chain.generate(c), "\r\n")
end
file:write()
file:close()
