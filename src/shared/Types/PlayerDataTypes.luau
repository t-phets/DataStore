--!strict

export type PlayerData = {
    schemaVersion: number,
    stats: { [string]: number },
    inventory: { [string]: number },
}

export type PublicPlayerData = {
    stats: { [string]: number },
    inventory: { [string]: number },
}

return {}