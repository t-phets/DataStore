--!strict

local Players = game:GetService("Players")

local PlayerDataService = require("../Services/PlayerDataService")
local PlayerDataDefaults = require("../Domain/PlayerDataDefaults")

export type PlayerLifeCycleControllersTypes = {
    Start: () -> (),
}

local PlayerLifeCycleController = {} :: PlayerLifeCycleControllersTypes

function PlayerLifeCycleController.Start()
    local function OnPlayerAdded(player: Player)
        PlayerDataService.CreateSession(player.UserId, PlayerDataDefaults.NewDefault())
    end

    local function onPlayerRemoving(player: Player)
        PlayerDataService.RemoveSession(player.UserId)
    end

    Players.PlayerAdded:Connect(OnPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    for _, player in Players:GetPlayer() do
        task.spawn(OnPlayerAdded, player)
    end
end

return PlayerLifeCycleController