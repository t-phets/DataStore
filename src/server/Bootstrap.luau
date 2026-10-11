--!strict

local PlayerDataService = require("./Services/PlayerDataService")
local CurrencyService = require("./Services/CurrencyService")
local PlayerLifeCycleController = require("./Controllers/PlayerLifeCycleController")

local currency = CurrencyService.new(PlayerDataService.GetSession, { maxCoins = 1_000_000 })

PlayerLifeCycleController.Start()