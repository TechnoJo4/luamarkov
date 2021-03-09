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
local chain = require("init")

local last_a, last = nil, ""
for _,v in ipairs(file.messages) do
    local author = v.author.name
    if not people[author] then
        people[author] = chain("./jsonfed/"..author:gsub("/", "")..".txt")
    end
    author = people[author]

    if v.content and v.content ~= "" then
        author.feed(v.content, last_a == author and last)
        last_a = author
        last = v.content
    end
end

for _,v in pairs(people) do
    v.save(true)
end
