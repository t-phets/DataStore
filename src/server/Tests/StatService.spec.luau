--!strict

local StatService = require("../Services/StatService")
local ProfileSessionTypes = require("../Types/ProfileSessionTypes")
local StatTypes = require("../Types/StatTypes")

type ProfileSession = ProfileSessionTypes.ProfileSession
type StatDefinition = StatTypes.StatDefinition

local definitions: { StatDefinition } = {
    { id = "Coins", min = 0, max = 1000, integerOnly = true, canDecrease = true,  initial = 0, replicated = true },
    { id = "Level", min = 1, max = 100,  integerOnly = true, canDecrease = false, initial = 1, replicated = true },
}

local function makeSession(
    coins: number,
    level: number,
    state: ProfileSessionTypes.SessionState
): ProfileSession
    return {
        data = { schemaVersion = 1, stats = { Coins = coins, Level = level }, inventory = {} },
        state = state,
    }
end

local function check(
    name: string,
    op: "Increase" | "Decrease",
    session: ProfileSession?,
    statId: string,
    amount: number,
    expectedReason: string?,
    expectedValue: number?
)
    local service = StatService.new(function(_userId: number): ProfileSession?
        return session
    end, definitions)

    local result = if op == "Increase"
        then service.Increase(1, statId, amount)
        else service.Decrease(1, statId, amount)

    local ok: boolean
    if expectedReason == nil then
        ok = result.success and result.newValue == expectedValue
    else
        ok = (not result.success) and result.reason == expectedReason
    end
    if session ~= nil and session.data.stats[statId] ~= expectedValue then
        ok = false
    end

    print((ok and "PASS " or "FAIL ") .. name)

    if not ok then
        local actual = if result.success
            then ("success, newValue=" .. tostring(result.newValue))
            else ("failure, reason=" .. result.reason)
        print("    expected: reason=" .. tostring(expectedReason) .. ", value=" .. tostring(expectedValue))
        print("    actual:   " .. actual .. ", stored value=" .. tostring(session and session.data.stats[statId]))
    end
end

local loaded = function(coins: number, level: number) return makeSession(coins, level, "Loaded") end

check("increase ok",                "Increase", loaded(100, 5), "Coins", 50,       nil,                  150)
check("increase to exactly max",    "Increase", loaded(990, 5), "Coins", 10,       nil,                  1000)
check("increase exceeds max",       "Increase", loaded(990, 5), "Coins", 11,       "ExceedsMax",         990)
check("decrease ok",                "Decrease", loaded(100, 5), "Coins", 30,       nil,                  70)
check("decrease to exactly min",    "Decrease", loaded(100, 5), "Coins", 100,      nil,                  0)
check("decrease below min",         "Decrease", loaded(100, 5), "Coins", 101,      "BelowMin",           100)
check("level cannot decrease",      "Decrease", loaded(100, 5), "Level", 1,        "DecreaseNotAllowed", 5)
check("unknown stat",               "Increase", loaded(100, 5), "Coinz", 1,        "UnknownStat",        nil)
check("negative amount",            "Increase", loaded(100, 5), "Coins", -100,     "InvalidAmount",      100)
check("NaN amount",                 "Increase", loaded(100, 5), "Coins", 0 / 0,    "InvalidAmount",      100)
check("infinite amount",            "Increase", loaded(100, 5), "Coins", math.huge,"InvalidAmount",      100)
check("fraction on integer stat",   "Increase", loaded(100, 5), "Coins", 1.5,      "InvalidAmount",      100)
check("not loaded",                 "Increase", nil,            "Coins", 10,       "ProfileNotLoaded",   nil)
check("closing",                    "Increase", makeSession(100, 5, "Closing"), "Coins", 10, "PlayerClosing", 100)
-- ลำดับด่าน
check("unknown stat + not loaded",  "Increase", nil,            "Coinz", 10,       "UnknownStat",        nil)
check("bad amount + closing",       "Increase", makeSession(100, 5, "Closing"), "Coins", -5, "InvalidAmount", 100)
check("no-decrease + closing",      "Decrease", makeSession(100, 5, "Closing"), "Level", 1, "DecreaseNotAllowed", 5)

return {}