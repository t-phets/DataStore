--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")

export type SessionState = "Loaded" | "Closing"
export type SessionFailure = "ProfileNotLoaded" | "PlayerClosing"

export type ProfileSession = {
    data: PlayerDataTypes.PlayerData,
    state: SessionState,
}

export type SessionProvider = (userId: number) -> ProfileSession?

export type SessionLookup =
    { ok: true, session: ProfileSession }
    | { ok: false, reason: SessionFailure }

return {}