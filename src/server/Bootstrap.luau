--!strict

local PlayerDataService = require("./Services/PlayerDataService")
local StatService = require("./Services/StatService")
local PlayerLifeCycleController = require("./Controllers/PlayerLifeCycleController")
local PlayerDataDefault = require("./Domain/PlayerDataDefaults")
local StatDefinitions = require("./Config/StatDefinitions")

local stats: StatService.StatServiceApi = StatService.new(PlayerDataService.GetSession, StatDefinitions)

PlayerLifeCycleController.Start(function()
    return PlayerDataDefault.NewDefault(StatDefinitions)
end)