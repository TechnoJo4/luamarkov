return {
    -- messages containing any of these words will not be added to the chain
    BLACKLIST = {"http", "https"},

    -- lowercase lookbehind words during feeding/generation.
    -- note: only lookbehind words are affected, output should converse casing.
    LOWER = true,

    -- maximum amount of characters in the output
    MAXCHARS = 500,

    -- minimum amount of words in a message to feed it to the chain
    MINWORDS = 6,

    -- amount of lookbehind words to use when creating new chains
    N = 2,

    -- the string that represents no word, added at the start and end of messages
    -- should probably be kept at the default
    NONE = "\0",

    -- if > 0, the generator will choose again up to RETRY times when it encounters NONE
    RETRY = 3,

    -- lua patterns for words. must contain a single capture group for the word.
    -- WORD must end with a "()" position capture
    WORD = "[ \"\\_~*`<>()]*(.-)[ \".,:;?!/+\\|*~_`\n()]+()",
    WORD_LAST = "[ \"\\_~*`<>]*(.+)[ \".,:;?!/+\\|*~_`\n]*",
}
