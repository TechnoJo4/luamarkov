-- luajit jsonfeedall.lua ./archive.json

local args = { ... }
local json = require("json")
local file do
    local f = io.open(args[1], "rb")
    file = f:read("*a")
    f:close()
    f = nil
end
file = json.decode(file)

local blacklist = {
}

local markov = require("chain")
local chain = markov.load("./all.json")

for _,v in ipairs(file.messages) do
    local author = v.author.name
    if not blacklist[author] then
        if v.content and v.content ~= "" then
            markov.feed(chain, v.content)
        end
    end
end
markov.save(chain, true)
