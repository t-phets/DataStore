--!strict

local InventoryTypes = require("../Types/InventoryTypes")

local config: InventoryTypes.InventoryConfig = {
    maxItemTypes = 30,
    items = {
        { id = "Potion", maxStack = 99 },
        { id = "Sword",  maxStack = 1 },
        { id = "Wood",   maxStack = 999 },
    },
}

return config