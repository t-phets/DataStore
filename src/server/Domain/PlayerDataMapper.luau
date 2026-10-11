--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")
local StatTypes = require("../Types/StatTypes")

type PlayerData = PlayerDataTypes.PlayerData
type PublicPlayerData = PlayerDataTypes.PublicPlayerData
type InventoryEntry = PlayerDataTypes.InventoryEntry

type StatDefinition = StatTypes.StatDefinition

export type PlayerDataMapper = {
    ToPublic: (data: PlayerData, definitions: { StatDefinition }) -> PublicPlayerData,
}

local PlayerDataMapper = {}

function PlayerDataMapper.ToPublic(data: PlayerData, definitions: { StatDefinition }): PublicPlayerData
    local stats: { [string]: number } = {}
    for _, definition: StatDefinition in definitions do
        if definition.replicated then
            local value: number? = data.stats[definition.id]
            if value ~= nil then
                stats[definition.id] = value
            end
        end
    end

    local inventoryCopy: { InventoryEntry } = {}
    for _, entry: InventoryEntry in data.inventory do
        table.insert(inventoryCopy, {
            itemId = entry.itemId,
            quantity = entry.quantity,
        })
    end

    return { stats = stats, inventory = inventoryCopy }
end

return PlayerDataMapper