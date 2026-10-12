--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")
local PlayerDataSchema = require("./PlayerDataSchema")
local StatTypes = require("../Types/StatTypes")

type PlayerData = PlayerDataTypes.PlayerData
type StatDefinition = StatTypes.StatDefinition

export type PlayerDataDefaults = {
    NewDefault: (definitions: StatDefinition) -> PlayerData,
}

local PlayerDataDefaults = {}

function PlayerDataDefaults.NewDefault(definitions: { StatDefinition }): PlayerData
    local stats: { [string]: number } = {}
    for _, definition: StatDefinition in definitions do
        stats[definition.id] = definition.initial
    end
    return {
        schemaVersion = PlayerDataSchema.CURRENT_VERSION,
        stats = stats,
        inventory = {},
    }
end

return PlayerDataDefaults