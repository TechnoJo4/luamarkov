local json = require("json")
local config = require("config")

local mod = {}

local NONE = "\n"

function mod.new()
    return { meta = config.new, data = {} }
end

function mod.load(file)
    local f = io.open(file, "r")
    if not f then
        local chain = mod.new()
        chain.file = file
        return chain
    end

    local content = f:read("*a")
    f:close()

    local chain = json.decode(content)
    chain.file = file
    return chain
end

function mod.save(chain, dispose)
    local file = chain.file
    chain.file = nil

    local f = io.open(file, "w")
    f:write(json.encode(chain))
    f:close()

    if dispose then
        chain.meta = nil
        chain.data = nil
    else
        chain.file = file
    end

    return chain
end

local function split(str)
    local pat = config.SPLIT_PATTERN

    local tbl = {}

    -- trim start
    local last = 1
    if str:match("()"..pat) == 1 then
        last = str:match(pat.."()")
    end

    -- trim end
    local len = str:match("()"..pat.."$")
    len = len and len-1 or #str

    -- get words
    while last < len do
        local e, s = str:match("()"..pat.."()", last)
        if not e or not s then
            break
        end

        tbl[#tbl+1] = str:sub(last, e-1)

        last = s
    end

    if last < len then
        tbl[#tbl+1] = str:sub(last, -1)
    end

    return tbl
end

function mod.feed(chain, sentence)
    sentence = split(sentence)

    -- check length
    if #sentence < config.MINWORDS then
        return
    end

    -- check blacklist
    for _,v in ipairs(sentence) do
        for _,w in ipairs(config.BLACKLIST) do
            if v == w then
                return
            end
        end
    end

    local idx = 1
    local N = chain.meta.N

    -- create window
    local window = {}
    for i=1,N do
        window[i] = NONE
    end
    window[N+1] = NONE

    sentence[#sentence+1] = NONE

    -- iterate through the sentence
    local len = #sentence
    while idx < len do
        -- rotate window
        for i=2,N+1 do
            window[i-1] = window[i]
        end

        local word = sentence[idx]
        window[N+1] = config.LOWER and word:lower() or word

        -- traverse chain
        local t = chain.data
        for i=1,N do
            local w = window[i]
            if not t[w] then
                t[w] = {}
            end
            t = t[w]
        end

        -- add word
        t[#t+1] = word

        idx = idx + 1
    end
end

function mod.generate(chain, init)
    if type(init) == "string" then
        init = split(init)
    elseif not init then
        init = {}
    end

    local N = chain.meta.N

    local lb = {}
    local s = #init-N
    for i=1,N do
        lb[i] = init[i+s] or NONE
        if config.LOWER then
            lb[i] = lb[i]:lower()
        end
    end

    local len = -1
    local words = init

    while true do
        -- traverse chain
        local t = chain.data
        for i=1,N do
            t = t[lb[i]]
            if not t then
                -- cannot break two levels, so same return as outside loop
                return table.concat(words, " ")
            end
        end

        -- get word
        local word = t[math.random(1, #t)]
        if word == NONE then
            break
        end

        -- check length
        len = len + 1 + #word
        if len >= config.MAXCHARS then
            words[#words+1] = "[MAXCHARS]"
            break
        end

        -- add to list
        words[#words+1] = word

        -- rotate window
        for i=2,N do
            lb[i-1] = lb[i]
        end
        lb[N] = config.LOWER and word:lower() or word
    end

    return table.concat(words, " ")
end

return mod
