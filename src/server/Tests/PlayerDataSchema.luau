--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")
local PlayerDataSchema = require("../Domain/PlayerDataSchema")
local SchemaTypes = require("../Types/SchemaTypes")

type PlayerData = PlayerDataTypes.PlayerData

local schema = PlayerDataSchema.new({
    { id = "Coins", min = 0, max = 1000, integerOnly = true, canDecrease = true,  initial = 0, replicated = true },
    { id = "Level", min = 1, max = 100,  integerOnly = true, canDecrease = false, initial = 1, replicated = true },
    { id = "Kills", min = 0, max = 10000, integerOnly = true, canDecrease = false, initial = 0, replicated = false },
}, {
    { id = "Potion", maxStack = 10 },
    { id = "Sword",  maxStack = 1 },
})

local function expectOk(name: string, raw: unknown, verify: (PlayerData, number?) -> boolean)
    local result = schema.Decode(raw)
    local ok = result.ok and verify(result.data, result.migratedFrom)
    print((ok and "PASS " or "FAIL ") .. name)
    if not ok then
        print("    actual: " .. (if result.ok then "ok but verify failed" else (result.reason .. " - " .. result.detail)))
    end
end

local function expectFail(name: string, raw: unknown, expectedReason: SchemaTypes.DecodeFailure)
    local result = schema.Decode(raw)
    local ok = (not result.ok) and result.reason == expectedReason
    print((ok and "PASS " or "FAIL ") .. name)
    if not ok then
        print("    actual: " .. (if result.ok then "ok (expected failure)" else (result.reason .. " - " .. result.detail)))
    end
end

local function v2(stats: unknown, inventory: unknown): unknown
    return { schemaVersion = 2, stats = stats, inventory = inventory }
end

-- ผ่าน
expectOk("valid v2", v2({ Coins = 50, Level = 3, Kills = 7 }, { Potion = 2 }), function(d, from)
    return d.stats.Coins == 50 and d.stats.Level == 3 and d.inventory.Potion == 2 and from == nil
end)
expectOk("missing stats filled with initial", v2({ Coins = 50 }, {}), function(d, _)
    return d.stats.Coins == 50 and d.stats.Level == 1 and d.stats.Kills == 0
end)
expectOk("unknown stat preserved", v2({ Coins = 1, Gems = 7 }, {}), function(d, _)
    return d.stats.Gems == 7
end)
expectOk("unknown item preserved", v2({ Coins = 1 }, { Banana = 3 }), function(d, _)
    return d.inventory.Banana == 3
end)
expectOk("v1 migrates", {
    schemaVersion = 1,
    coins = 120,
    inventory = {
        { itemId = "Potion", quantity = 2 },
        { itemId = "Potion", quantity = 3 },
        { itemId = "Sword", quantity = 1 },
    },
}, function(d, from)
    return d.stats.Coins == 120 and d.stats.Level == 1 and d.inventory.Potion == 5
        and d.inventory.Sword == 1 and d.schemaVersion == 2 and from == 1
end)

-- ล้มเหลว: โครงสร้าง/เวอร์ชัน
expectFail("not a table (number)", 42, "InvalidData")
expectFail("not a table (string)", "hello", "InvalidData")
expectFail("missing version", { stats = {}, inventory = {} }, "InvalidData")
expectFail("version zero", { schemaVersion = 0, stats = {}, inventory = {} }, "InvalidData")
expectFail("newer version", { schemaVersion = 3, stats = { Coins = 1 }, inventory = {} }, "UnsupportedVersion")
expectFail("v1 bad coins", { schemaVersion = 1, coins = "lots", inventory = {} }, "InvalidData")
expectFail("v1 malformed entry", { schemaVersion = 1, coins = 1, inventory = { { itemId = "Potion" } } }, "InvalidData")
expectFail("v1 merged quantity exceeds maxStack", {
    schemaVersion = 1,
    coins = 1,
    inventory = { { itemId = "Potion", quantity = 6 }, { itemId = "Potion", quantity = 6 } },
}, "InvalidData")

-- ล้มเหลว: stats
expectFail("NaN stat", v2({ Coins = 0 / 0 }, {}), "InvalidData")
expectFail("infinite stat", v2({ Coins = math.huge }, {}), "InvalidData")
expectFail("stat above max", v2({ Coins = 1001 }, {}), "InvalidData")
expectFail("stat below min", v2({ Coins = -1 }, {}), "InvalidData")
expectFail("fractional integer stat", v2({ Coins = 1.5 }, {}), "InvalidData")
expectFail("stats is an array", v2({ 1, 2, 3 }, {}), "InvalidData")

-- ล้มเหลว: inventory
expectFail("inventory missing", { schemaVersion = 2, stats = { Coins = 1 } }, "InvalidData")
expectFail("inventory zero quantity", v2({ Coins = 1 }, { Potion = 0 }), "InvalidData")
expectFail("inventory fractional", v2({ Coins = 1 }, { Potion = 1.5 }), "InvalidData")
expectFail("inventory above maxStack", v2({ Coins = 1 }, { Potion = 11 }), "InvalidData")

-- ไม่แก้ข้อมูลดิบ
local legacy = { schemaVersion = 1, coins = 120, inventory = { { itemId = "Potion", quantity = 2 } } }
schema.Decode(legacy)
local untouched = legacy.schemaVersion == 1 and legacy.coins == 120 and #legacy.inventory == 1
print((untouched and "PASS " or "FAIL ") .. "decode does not mutate input")

return {}