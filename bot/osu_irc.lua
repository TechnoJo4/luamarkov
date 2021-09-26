local uv = require("uv")
local IRC = require("irc")
local markov = require("chain")
local discordia = require("discordia")

local chain = markov.load("./bot/osu_irc.json")

math.randomseed(os.time())

-- IRC bot
local irc = IRC:new("irc.ppy.sh", os.getenv("ircuser"), {
    password = os.getenv("ircpass"),
    auto_join = { "#osu" }
})

-- log connection events
irc:on("connecting", function(nick, server, username, real_name)
    print(("Connecting to %s as %s"):format(server, nick))
end)
irc:on("connect", function(welcomemsg, server, nick)
    print(("Connected to %s as %s"):format(server, nick))
end)
irc:on("disconnect", function(reason)
    print(("Disconnected: %s"):format(reason))
end)

-- feed messages to the chain
irc:on("message", function(from, to, msg)
    msg = msg:sub(1, msg:match("()\n") or -1)
    chain.meta.counter = (chain.meta.counter or 0) + 1
    markov.feed(chain, msg)
end)

-- login
irc:connect()

-- handle SIGINT
uv.signal_start(uv.new_signal(), "sigint", function()
    irc:disconnect()
    markov.save(chain, true)
    os.exit()
end)

-- discord bot commands
local PREFIX = "amkorv!"
local commands = {
    [PREFIX .. "generate"] = function(m, arg)
        m:reply(markov.generate(chain, arg))
    end,
    [PREFIX .. "info"] = function(m)
        m:reply({ embed = {
            title = "#osu markov thing",
            fields = { {
                    name = "message count",
                    value = tostring(chain.meta.counter),
                    inline = false
                }, {
                    name = "source code",
                    value = "https://github.com/TechnoJo4/luamarkov",
                    inline = false
                },
            }
        } })
    end
}


local discord = discordia.Client()

discord:on("messageCreate", function(m)
    local arg
    local cmd = m.content
    local e, s = cmd:match("(). ()")
    if e then
        arg = cmd:sub(s)
        cmd = cmd:sub(1, e)
    end

    if commands[cmd] then
        commands[cmd](m, arg)
    end
end)

discord:run("Bot "..os.getenv("token"))
