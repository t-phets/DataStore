--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")
local InventoryTypes = require("../Types/InventoryTypes")
local StatTypes = require("../Types/StatTypes")

type PlayerData = PlayerDataTypes.PlayerData
type PublicPlayerData = PlayerDataTypes.PublicPlayerData
type ItemDefinition = InventoryTypes.ItemDefinition

type StatDefinition = StatTypes.StatDefinition

export type PlayerDataMapper = {
    ToPublic: (data: PlayerData, definitions: { StatDefinition }) -> PublicPlayerData,
}

local PlayerDataMapper = {}

function PlayerDataMapper.ToPublic(
    data: PlayerData,
    stats: { StatDefinition },
    items: { ItemDefinition }
): PublicPlayerData
    local publicStats: { [string]: number } = {}
    for _, definition: StatDefinition in stats do
        if definition.replicated then
            local value: number? = data.stats[definition.id]
            if value ~= nil then
                publicStats[definition.id] = value
            end
        end
    end

    local publicInventory: { [string]: number } = {}
    for _, item in items do
        local quantity: number? = data.inventory[item.id]
        if quantity ~= nil then
            publicInventory[item.id] = quantity
        end
    end

    return { stats = publicStats, inventory = publicInventory }
end

return PlayerDataMapper