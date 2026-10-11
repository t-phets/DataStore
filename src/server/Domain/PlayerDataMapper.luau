--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)

type PlayerData = PlayerDataTypes.PlayerData
type PublicPlayerData = PlayerDataTypes.PublicPlayerData
type InventoryEntry = PlayerDataTypes.InventoryEntry

export type PlayerDataMapperTypes = {
    ToPublic: (data: PlayerData) -> PublicPlayerData,
}

local PlayerDataMapper = {} :: PlayerDataMapperTypes

function PlayerDataMapper.ToPublic(data: PlayerData): PublicPlayerData
    local inventoryCopy: {InventoryEntry} = {}
    
    for _, entry: InventoryEntry in data.inventory do
        table.insert(inventoryCopy, {
            itemId = entry.itemId,
            quantity = entry.quantity,
        })
    end

    return {
        coins = data.coins,
        inventory = inventoryCopy
    }
end