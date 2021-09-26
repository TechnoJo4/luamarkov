local fs = require("fs")
local markov = require("chain")
local discordia = require("discordia")

local discord = discordia.Client()

local chains = {}
local chains_info = {}

local commands = {
    info = function(m)
        m:reply({ embed = {
            title = "Available markov chains",
            fields = chains_info
        } })
    end,

    load = function(m, arg)
        if m.author ~= m.client.owner then return end

        local f = "./bot/"..arg..".json"
        if fs.existsSync(f) then
            local chain = markov.load(f)

            -- kinda just fucking around with numbers
            local words, nwords, nuses = {}, 0, 0
            local diversity, nnodes = 0,0

            local function count(t, n)
                if n == 0 then
                    local node_words = {}
                    local node_nwords = 0

                    for _,v in ipairs(t) do
                        if not words[v] then
                            words[v] = true
                            nwords = nwords + 1
                        end
                        if not node_words[v] then
                            node_words[v] = true
                            node_nwords = node_nwords + 1
                        end
                        nuses = nuses + 1
                    end

                    nnodes = nnodes + 1
                    diversity = diversity + node_nwords
                else
                    n = n - 1
                    for _,v in pairs(t) do
                        count(v, n)
                    end
                end
            end

            count(chain.data, chain.meta.N)

            chains[arg] = chain
            chains_info[#chains_info+1] = {
                name = arg,
                value = ("Vocabulary: %d words\nPredictions: %d\nDiversity: %.2f")
                        :format(nwords, nuses, diversity / nnodes),
                inline = true
            }

            m:reply("Success")
        else
            m:reply("Chain `%s` does not exist", arg)
        end
    end,

    kill = function(m, arg)
        if m.author ~= m.client.owner then return end

        if chains[arg] then
            chains[arg] = nil

            local len = #chains_info
            for i=1,len do
                if chains_info[i].name == arg then
                    for j=i+1,len do
                        chains_info[j-1] = chains_info[j]
                    end
                    chains_info[len] = nil
                    break
                end
            end

            m:reply("Success")
        else
            m:reply("Chain `%s` is not loaded", arg)
        end
    end
}

local PREFIX = "amkorv!"

discord:on("messageCreate", function(m)
    local arg
    local cmd = m.content
    if cmd:sub(1,#PREFIX) ~= PREFIX then
        return
    end
    cmd = cmd:sub(#PREFIX+1)

    local e, s = cmd:match("(). ()")
    if e then
        arg = cmd:sub(s)
        cmd = cmd:sub(1, e)
    end

    if commands[cmd] then
        commands[cmd](m, arg)
    elseif chains[cmd] then
        m:reply(markov.generate(chains[cmd], arg))
    end
end)

discord:run("Bot "..os.getenv("token"))
