--!strict

local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")
local ProfileSessionTypes = require("../Types/ProfileSessionTypes")

type PlayerData = PlayerDataTypes.PlayerData
type ProfileSession = ProfileSessionTypes.ProfileSession

export type PlayerDataService = {
    CreateSession: (userId: number, data: PlayerData) -> ProfileSession,
    GetSession: (userId: number) -> ProfileSession?,
    RemoveSession: (userId: number) -> (),
}

local PlayerDataService = {} :: PlayerDataService
local sessions: { [number]: ProfileSession }

function PlayerDataService.CreateSession(userId: number, data: PlayerData): ProfileSession
    if sessions[userId] ~= nil then
        error(`session already exists for this userId: {userId}`)
    end
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
