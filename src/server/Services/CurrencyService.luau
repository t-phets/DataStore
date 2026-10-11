--!strict

local ProfileSessionTypes = require("../Types/ProfileSessionTypes")
local CurrencyTypes = require("../Types/CurrencyTypes")
local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")

type ProfileSession = ProfileSessionTypes.ProfileSession
type SessionFailure = ProfileSessionTypes.SessionFailure
type PlayerData = PlayerDataTypes.PlayerData
type RemoveCoinsResult = CurrencyTypes.RemoveCoinsResult
type AddCoinsResult = CurrencyTypes.AddCoinsResult
type CurrencyConfig = CurrencyTypes.CurrencyConfig

export type SessionProvider = (userId: number) -> ProfileSession?

export type CurrencyServiceTypes = {
    new: (getSession: SessionProvider, config: CurrencyConfig) -> CurrencyServiceApi,
}

export type CurrencyServiceApi = {
    RemoveCoins: (userId: number, amount: number) -> RemoveCoinsResult,
    AddCoins: (userId: number, amount: number) -> AddCoinsResult,
}

export type SessionLookup = 
    { ok: true, session: ProfileSession }
    | { ok: false, reason: SessionFailure }

local CurrencyService = {} :: CurrencyServiceTypes

function isValidAmount(amount: number): boolean
    return amount > 0 and amount < math.huge and amount == math.floor(amount)
end

function CurrencyService.new(getSession: SessionProvider, config: CurrencyConfig): CurrencyServiceApi
    local function findWriteableSession(userId: number): SessionLookup
        local session: ProfileSession? = getSession(userId)
        if session == nil then
            return { ok = false, reason = "ProfileNotLoaded" }
        end
        if session.state == "Closing" then
            return { ok = false, reason = "PlayerClosing" }
        end
        return { ok = true, session = session }
    end

    local function removeCoins(userId: number, amount: number): RemoveCoinsResult
        if not isValidAmount(amount) then
            return { success = false, reason = "InvalidAmount" }
        end
        
        local lookup: SessionLookup = findWriteableSession(userId)
        if not lookup.ok then
            return { success = false, reason = lookup.reason }
        end

        local data: PlayerData = lookup.session.data
        if data.coins < amount then
            return { success = false, reason = "InsufficientFunds" }
        end

        data.coins -= amount
        return { success = true, newBalance = data.coins }
    end

    local function addCoins(userId: number, amount: number): AddCoinsResult
        if not isValidAmount(amount) then
            return { success = false, reason = "InvalidAmount" }
        end

        local lookup: SessionLookup = findWriteableSession(userId)
        if not lookup.ok then
            return { success = false, reason = lookup.reason }
        end
        
        local data: PlayerData = lookup.session.data
        if (data.coins + amount) > config.maxCoins then
            return { success = false, reason = "ExceedsCap" }
        end

        data.coins += amount
        return { success = true, newBalance = data.coins }
    end

    return { RemoveCoins = removeCoins, AddCoins = addCoins }
end

return CurrencyService