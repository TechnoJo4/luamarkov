return {
    new = { -- metadata for new chains
        N = 2
    },

    SPLIT_PATTERN = "[ \".,:;?!/+\\|*~_`\n()]+",

    LOWER = true,

    MINWORDS = 3,

    MAXCHARS = 500,

    BLACKLIST = {"http", "https", "[https"},
}