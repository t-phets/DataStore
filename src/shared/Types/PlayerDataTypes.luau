--!strict

export type InventoryEntry = {
    itemId: number,
    quantity: number,
}

export type PlayerData = {
    schemaVersion: number,
    coins: number,
    inventory: { InventoryEntry }
}

export type PublicPlayerData = {
    coins: number,
    inventory: { InventoryEntry }
}

return {}