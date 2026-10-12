--!strict

local PlayerDataService = require("./Services/PlayerDataService")
local StatService = require("./Services/StatService")
local PlayerLifeCycleController = require("./Controllers/PlayerLifeCycleController")
local PlayerDataDefault = require("./Domain/PlayerDataDefaults")
local StatDefinitions = require("./Config/StatDefinitions")
local InventoryService = require(script.Parent.Services.InventoryService)
local InventoryConfig = require(script.Parent.Config.InventoryConfig)

local inventory = InventoryService.new(PlayerDataService.GetSession, InventoryConfig)

local stats: StatService.StatServiceApi = StatService.new(PlayerDataService.GetSession, StatDefinitions)

PlayerLifeCycleController.Start(function()
    return PlayerDataDefault.NewDefault(StatDefinitions)
end)