--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")
local ProfileSessionTypes = require("../Types/ProfileSessionTypes")

type PlayerData = PlayerDataTypes.PlayerData
type ProfileSession = ProfileSessionTypes.ProfileSession

export type PlayerDataServiceTypes = {
    CreateSession: (userId: number, data: PlayerData) -> ProfileSession,
    GetSession: (userId: number) -> ProfileSession?,
    RemoveSession: (userId: number) -> (),
}

local PlayerDataService = {} :: PlayerDataServiceTypes
local sessions: { [number]: ProfileSession } = {}

function PlayerDataService.CreateSession(userId: number, data: PlayerData): ProfileSession
    assert(sessions[userId] == nil, "session already exists for this userId")
    local session: ProfileSession = { data = data, state = "Loaded" }
    sessions[userId] = session
    return session
end

function PlayerDataService.GetSession(userId: number): ProfileSession?
    return sessions[userId]
end

function PlayerDataService.RemoveSession(userId: number)
    sessions[userId] = nil
end

return PlayerDataService
