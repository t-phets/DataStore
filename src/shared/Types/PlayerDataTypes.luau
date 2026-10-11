--!strict

export type InventoryEntry = {
    itemId: number,
    quantity: number,
}

export type PlayerData = {
    schemaVersion: number,
    stats: { [string]: number },
    inventory: { InventoryEntry },
}

export type PublicPlayerData = {
    stats: { [ string ]: number },
    inventory: { InventoryEntry },
}

return {}