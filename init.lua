local config = require("config")
local data = require("dataformat")

-- really simple markov chain implementation
-- but configurable

-- there's plenty of room for even simple optimizations,
-- but i feel it's fast enough with luajit and the
-- relatively small amount of data i give it

return function(filename)
    local chain, N = data.from_file(filename)

    local function save(dispose)
        data.to_file(chain, N, filename)
        if dispose then chain = nil end
    end

    -- add a word to the chain. arr should be N-sized.
    local function feed_internal(arr, word)
        local t = chain

        -- naviguate the chain
        for i,v in ipairs(arr) do
            if config.LOWER then
                v = v:lower()
            end

            -- create table if missing
            if not t[v] then t[v] = {} end
            t = t[v]
        end

        -- add word to the array (either created above or already existing)
        t[#t+1] = word
    end

    local function feed(str, cont)
        local wordsc = {}

        -- if `cont` is present, `str` is considered a continuation of another message,
        -- and the chain will be fed the start of the message (until the first to Nth words) twice:
        -- once padded with the last N words of `cont`, the other padded with NONE
        if cont then
            local last = 1
            for word, idx in cont:gmatch(config.WORD) do
                -- revert to NONE padding if the previous message has blacklisted words
                for _,b in pairs(config.BLACKLIST) do
                    if b == word then
                        for i=1,N do
                            wordsc[i] = config.NONE
                        end
                        cont = nil
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
            -- do not feed the message if it contains a blacklisted word
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

        local len = #words
        local padded = {}

        -- pad with wordsc (cont or NONEs)
        for i=1,N do
            padded[i] = wordsc[#wordsc - N + i] or config.NONE
        end

        -- fill with words
        for i,v in ipairs(words) do
            padded[N+i] = v
        end

        -- end with a NONE
        padded[len+N+1] = config.NONE

        -- dispose of old arrays
        words = nil
        wordsc = nil

        -- slide across padded words and feed to the chain
        for i=1,len+N-1 do
            local arr = {}
            for j=1,N do -- rotate window
                arr[j] = padded[i + j - 1]
            end
            feed_internal(arr, padded[i + N])
        end

        -- if cont, also feed start of message padded with NONE
        -- might cause some duplicates (not sure) but shouldn't be
        -- that much of a problem, since we only feed N sequences
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
        local t = chain

        -- naviguate the chain
        for i=1,N do
            t = t[config.LOWER and arr[i]:lower() or arr[i]]
            if not t then
                return NONE
            end
        end

        -- choose random next word
        local v = rand(t)
        for i=1,config.RETRY do
            if v == config.NONE then
                v = rand(t)
            end
        end
        return v
    end

    local function generate(words)
        -- make words an array of length N
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
            -- drop words until len - N
            for i=1,N do
                from[i] = words[#words - config.N + i]
            end
        else
            from = words
        end
        words = nil

        -- generate first prediction
        local word = gen_internal(from)

        -- should only happen if you try to predict
        -- based on words not present in the chain
        if word == config.NONE then
            return "[NO PREDICTION]"
        end

        local str = word
        -- predict words until hitting MAXCHARS
        while #str < config.MAXCHARS do
            -- rotate the `from` array, dropping the first
            for i=2,N do
                from[i-1] = from[i]
            end
            -- add the last word we predicted
            from[N] = word

            -- predict another word
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
