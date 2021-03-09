-- luajit jsonfeedmix.lua ./archive.json

local args = { ... }
local json = require("json")
local file do
    local f = io.open(args[1], "rb")
    file = f:read("*a")
    f:close()
    f = nil
end
file = json.decode(file)

local people = {
    ["TechnoJo4"]=true
}

local chain = require("init")
local c = chain("./mix.txt")

local last, str = nil, ""
for _,v in ipairs(file.messages) do
    local author = v.author.name
    if people[author] then
        if v.content and v.content ~= "" then
            c.feed(v.content, last_a == author and last)
            last_a = author
            last = v.content
        end
    end
end
c.save(true)
