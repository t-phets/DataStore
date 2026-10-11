--!strict

local StatTypes = require("../Types/StatTypes")

local definitions: { StatTypes.StatDefinition } = {
    {
        id = "Coins",
        min = 0,
        max = 1_000_000,
        integerOnly = true,
        canDecrease = true,
        initial = 0,
        replicated = true,
    },

    {
        id = "Level",
        min = 1,
        max = 100,
        integerOnly = true,
        canDecrease = false,
        initial = 0,
        replicated = true,
    },

    {
        id = "Kills",
        min = 0,
        max = 10_000_000,
        integerOnly = true,
        canDecrease = true,
        initial = 0,
        replicated = true,
    }
}

return definitions