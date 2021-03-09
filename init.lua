local config = require("config")
local data = require("dataformat")

-- really simple markov chain implementation
-- but configurable

return function(filename)
    local state, N = data.from_file(filename)

    local function save(dispose)
        data.to_file(state, N, filename)
        if dispose then state = nil end
    end

    local function feed_internal(arr, word)
        local t = state
        for i,v in ipairs(arr) do
            if config.LOWER then
                v = v:lower()
            end
            if not t[v] then t[v] = {} end
            t = t[v]
        end
        t[#t+1] = word
    end

    local function feed(str, cont)
        local wordsc = {}
        if cont then
            local last = 1
            for word, idx in cont:gmatch(config.WORD) do
                -- revert to NONE padding if the previous message has blacklisted words
                for _,b in pairs(config.BLACKLIST) do
                    if b == word then
                        for i=1,N do
                            wordsc[i] = config.NONE
                        end
                        break
                    end
                end

                last = idx
                if word ~= "" then
                    wordsc[#wordsc+1] = word
                end
            end
            if last < #cont then
                wordsc[#wordsc+1] = cont:match(config.WORD_LAST, last)
            end
        else
            for i=1,N do
                wordsc[i] = config.NONE
            end
        end

        -- get words in str
        local last = 1
        local words = {}
        for word, idx in str:gmatch(config.WORD) do
            -- do not feed if message has a blacklisted word
            for _,b in pairs(config.BLACKLIST) do
                if b == word then
                    return
                end
            end

            last = idx
            if word ~= "" then
                words[#words+1] = word
            end
        end
        if last < #str then
            words[#words+1] = str:match(config.WORD_LAST, last)
        end

        if #words < config.MINWORDS then return end

        -- pad with NONEs
        local len = #words
        local padded = {}
        for i=1,N do
            padded[i] = wordsc[#wordsc - N + i] or config.NONE
        end
        for i,v in ipairs(words) do
            padded[N+i] = v
        end
        for i=1,N do
            padded[len+N+i] = config.NONE
        end
        words = nil
        wordsc = nil

        -- slide across padded words and feed to the state
        for i=1,len+N-1 do
            local arr = {}
            for j=1,N do
                arr[j] = padded[i + j - 1]
            end
            feed_internal(arr, padded[i + N])
        end

        -- also feed start of message padded with NONE
        -- might cause some duplicates but shouldn't be that
        -- much of a problem, since we only feed N sequences
        if cont then
            for i=1,N do
                padded[i] = config.NONE
            end
            for i=1,N do
                local arr = {}
                for j=1,N do
                    arr[j] = padded[i + j - 1]
                end
                feed_internal(arr, padded[i + N])
            end
        end

        return true
    end

    local function rand(arr)
        return arr[math.random(1, #arr)]
    end

    local function gen_internal(arr)
        local t = state
        for i=1,N do
            t = t[config.LOWER and arr[i]:lower() or arr[i]]
            if not t then
                return NONE
            end
        end

        local v = rand(t)
        for i=1,config.RETRY do
            if v == config.NONE then
                v = rand(t)
            end
        end
        return v
    end

    local function generate(words)
        -- make words the correct length 
        local from = {}
        if #words < N then
            -- pad start with NONEs
            for i=1,N-#words do
                from[i] = config.NONE
            end
            for i=1,#words do
                from[N - #words + i] = words[i]
            end
        elseif #words > N then
            -- drop words at the start
            for i=1,N do
                from[i] = words[#words - config.N + i]
            end
        else
            from = words
        end

        -- generate continuation string
        local word = gen_internal(from)
        if word == config.NONE then
            return "[NOTHING]"
        end

        local str = word
        while #str < config.MAXCHARS do
            -- rotate from
            for i=2,N do
                from[i-1] = from[i]
            end
            from[N] = word

            word = gen_internal(from)
            if word == config.NONE then
                return str
            end
            str = str .. " " .. word
        end

        return str.." [MAXCHARS]"
    end

    return {
        save=save,
        feed=feed,
        generate=generate
    }
end
