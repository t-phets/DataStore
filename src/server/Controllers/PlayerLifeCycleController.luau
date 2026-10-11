--!strict

local Players = game:GetService("Players")

local PlayerDataService = require("../Services/PlayerDataService")
local PlayerDataDefaults = require("../Domain/PlayerDataDefaults")
local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")

type PlayerData = PlayerDataTypes.PlayerData

export type PlayerLifeCycleController = {
    Start: (createInitialData: () -> PlayerData) -> (),
}

local PlayerLifeCycleController = {} :: PlayerLifeCycleController

function PlayerLifeCycleController.Start(createInitialData: () -> PlayerData)
    local function OnPlayerAdded(player: Player)
        PlayerDataService.CreateSession(player.UserId, createInitialData())
    end

    local function OnPlayerRemoving(player: Player)
        PlayerDataService.RemoveSession(player.UserId)
    end

    Players.PlayerAdded:Connect(OnPlayerAdded)
    Players.PlayerRemoving:Connect(OnPlayerRemoving)

    for _, player: Player in Players:GetPlayers() do
        task.spawn(OnPlayerAdded, player)
    end
end

return PlayerLifeCycleController