-- luajit batch.lua ./data.json amount ./out.txt

local args = { ... }

math.randomseed(os.time())

local markov = require("chain")
local chain = markov.load(args[1])

local file = args[3] and io.open(args[3], "wb") or io.stdout
for i=1,tonumber(args[2]) do
    file:write(markov.generate(chain), "\r\n")
end
file:write()
file:close()
