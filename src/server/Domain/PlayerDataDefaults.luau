--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")

type PlayerData = PlayerDataTypes.PlayerData

local CURRENT_SCHEMA_VERSION = 1

export type PlayerDataDefaultTypes = {
    NewDefault: () -> PlayerData,
}

local PlayerDataDefaults = {} :: PlayerDataDefaultTypes

function PlayerDataDefaults.NewDefault(): PlayerData
    return {
        schemaVersion = CURRENT_SCHEMA_VERSION,
        coins = 0,
        inventory = {},
    }
end

return PlayerDataDefaults