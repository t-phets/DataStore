--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")

type PlayerData = PlayerDataTypes.PlayerData

export type SessionState = "Loaded" | "Closing"

export type ProfileSession = {
    data: PlayerData,
    state: SessionState,
}

export type SessionFailure = "ProfileNotLoaded" | "PlayerClosing"

return {}