-- luajit jsonfeed.lua ./archive.json

local args = { ... }
local json = require("json")
local file do
    local f = io.open(args[1], "rb")
    file = f:read("*a")
    f:close()
    f = nil
end
file = json.decode(file)

local people = {}
local chain = require("chain")

for _,v in ipairs(file.messages) do
    local author = v.author.name
    if not people[author] then
        people[author] = chain.load("./jsonfed/"..author:gsub("/", "")..".json")
    end
    author = people[author]

    if v.content and v.content ~= "" then
        chain.feed(author, v.content)
    end
end

for _,v in pairs(people) do
    chain.save(v, true)
end
