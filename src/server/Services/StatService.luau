--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local AmountRules = require(ServerScriptService.Server.Domain.AmountRules)
local ProfileSessionTypes = require("../Types/ProfileSessionTypes")
local SessionAccess = require("./SessionAccess")
local StatTypes = require("../Types/StatTypes")

type ProfileSession = ProfileSessionTypes.ProfileSession
type SessionFailure = ProfileSessionTypes.SessionFailure
type SessionProvider = ProfileSessionTypes.SessionProvider
type SessionLookup = ProfileSessionTypes.SessionLookup
type StatDefinition = StatTypes.StatDefinition
type IncreaseResult = StatTypes.IncreaseResult
type DecreaseResult = StatTypes.DecreaseResult

export type StatService = {
    new: (getSession: SessionProvider, definition: { StatDefinition }) -> StatServiceApi,
}

export type StatServiceApi = {
    Increase: (userId: number, statId: string, amount: number) -> IncreaseResult,
    Decrease: (userId: number, statId: string, amount: number) -> DecreaseResult,
}

local StatService = {} :: StatService

local function indexDefinitions(definitions: { StatDefinition }): { [string]: StatDefinition }
	local byId: { [string]: StatDefinition } = {}
	
	for _, def: StatDefinition in definitions do
		if byId[def.id] ~= nil then
			error(`duplicate stat id: {def.id}`)
		end
		
		if def.min <= -math.huge or def.max >= math.huge then
			error(`bounds must be finite: {def.id}`)
		end
		
		if def.initial < def.min or def.initial > def.max then
			error(`initial out of range: {def.id}`)
		end
		
		if def.integerOnly and def.initial ~= math.floor(def.initial) then
			error(`initial must be an integer: {def.id}`)
		end
		
		byId[def.id] = def
	end
	
	return byId
end

function StatService.new(getSession: SessionProvider, definitions: { StatDefinition }): StatServiceApi
    local byId: { [string]: StatDefinition } = indexDefinitions(definitions)

    local function readCurrent(session: ProfileSession, statId: string): number
        local current: number? = session.data.stats[statId]
        if current == nil then
            error(`stat missing from loaded profile: {statId}`)
        end
        return current
    end

    local function increase(userId: number, statId: string, amount: number): IncreaseResult
        local definition: StatDefinition? = byId[statId]
        if definition == nil then
            return { success = false, reason = "UnknownStat" }
        end
        if not AmountRules.IsValid(amount, definition.integerOnly) then
            return { success = false, reason = "InvalidAmount"}
        end

        local lookup: SessionLookup = SessionAccess.FindWritable(getSession, userId)
        if not lookup.ok then
            return { success = false, reason = lookup.reason }
        end

        local current: number = readCurrent(lookup.session, statId)
        if current + amount > definition.max then
            return { success = false, reason = "ExceedsMax" }
        end

        local newValue: number = current + amount
        lookup.session.data.stats[statId] = newValue
        return { success = true, newValue = newValue }
    end

    local function decrease(userId: number, statId: string, amount: number): DecreaseResult
        local definition: StatDefinition? = byId[statId]
        if definition == nil then
            return { success = false, reason = "UnknownStat" }
        end

        if not AmountRules.IsValid(amount, definition.integerOnly) then
            return { success = false, reason = "InvalidAmount" }
        end

        if not definition.canDecrease then
            return { success = false, reason = "DecreaseNotAllowed" }
        end

        local lookup: SessionLookup = SessionAccess.FindWritable(getSession, userId)
        if not lookup.ok then
            return { success = false, reason = lookup.reason }
        end

        local current: number = readCurrent(lookup.session, statId)
        if current - amount < definition.min then
            return { success = false, reason = "BelowMin" }
        end

        local newValue: number = current - amount
        lookup.session.data.stats[statId] = newValue
        return { success = true, newValue = newValue }
    end

    return { Increase = increase, Decrease =  decrease}
end

return StatService