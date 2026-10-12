--!strict

local InventoryService = require("../Services/InventoryService")
local ProfileSessionTypes = require("../Types/ProfileSessionTypes")
local InventoryTypes = require("../Types/InventoryTypes")

type ProfileSession = ProfileSessionTypes.ProfileSession

local config: InventoryTypes.InventoryConfig = {
    maxItemTypes = 2,
    items = {
        { id = "Potion", maxStack = 10 },
        { id = "Sword",  maxStack = 1 },
        { id = "Gem",    maxStack = 5 },
    },
}

local function makeSession(
    inventory: { [string]: number },
    state: ProfileSessionTypes.SessionState
): ProfileSession
    return {
        data = { schemaVersion = 1, stats = {}, inventory = inventory },
        state = state,
    }
end

local function check(
    name: string,
    op: "Add" | "Remove",
    session: ProfileSession?,
    itemId: string,
    quantity: number,
    expectedReason: string?,
    expectedStored: number?   -- nil = ใน inventory ต้องไม่มี key นี้
)
    local service = InventoryService.new(function(_userId: number): ProfileSession?
        return session
    end, config)

    local result = if op == "Add"
        then service.AddItem(1, itemId, quantity)
        else service.RemoveItem(1, itemId, quantity)

    local ok: boolean
    if expectedReason == nil then
        ok = result.success and result.newQuantity == (expectedStored or 0)
    else
        ok = (not result.success) and result.reason == expectedReason
    end
    if session ~= nil and session.data.inventory[itemId] ~= expectedStored then
        ok = false
    end

    print((ok and "PASS " or "FAIL ") .. name)
    if not ok then
        local actual = if result.success
            then ("success, newQuantity=" .. tostring(result.newQuantity))
            else ("failure, reason=" .. result.reason)
        print("    expected: reason=" .. tostring(expectedReason) .. ", stored=" .. tostring(expectedStored))
        print("    actual:   " .. actual .. ", stored=" .. tostring(session and session.data.inventory[itemId]))
    end
end

local function loaded(inv: { [string]: number }): ProfileSession
    return makeSession(inv, "Loaded")
end

-- เพิ่ม
check("add new item",              "Add", loaded({}),                    "Potion", 3, nil,            3)
check("add to existing stack",     "Add", loaded({ Potion = 3 }),        "Potion", 4, nil,            7)
check("add exactly to max stack",  "Add", loaded({ Potion = 8 }),        "Potion", 2, nil,            10)
check("add exceeds stack",         "Add", loaded({ Potion = 8 }),        "Potion", 3, "ExceedsStack", 8)
check("new type when full",        "Add", loaded({ Potion = 1, Sword = 1 }), "Gem", 1, "InventoryFull", nil)
check("existing type when full",   "Add", loaded({ Potion = 1, Sword = 1 }), "Potion", 1, nil,         2)
-- ลบ
check("remove partial",            "Remove", loaded({ Potion = 5 }),     "Potion", 2, nil,            3)
check("remove all deletes key",    "Remove", loaded({ Potion = 5 }),     "Potion", 5, nil,            nil)
check("remove more than owned",   "Remove", loaded({ Potion = 5 }),     "Potion", 6, "NotEnough",    5)
check("remove item not owned",     "Remove", loaded({}),                 "Potion", 1, "NotEnough",    nil)
-- input
check("unknown item (add)",        "Add",    loaded({}),                 "Axe",    1, "UnknownItem",  nil)
check("unknown item (remove)",     "Remove", loaded({}),                 "Axe",    1, "UnknownItem",  nil)
check("zero amount",               "Add", loaded({}),                    "Potion", 0, "InvalidAmount", nil)
check("negative amount",           "Add", loaded({}),                    "Potion", -1, "InvalidAmount", nil)
check("NaN amount",                "Add", loaded({}),                    "Potion", 0 / 0, "InvalidAmount", nil)
check("fractional amount",         "Add", loaded({}),                    "Potion", 1.5, "InvalidAmount", nil)
-- session
check("not loaded",                "Add", nil,                           "Potion", 1, "ProfileNotLoaded", nil)
check("closing",                   "Add", makeSession({}, "Closing"),    "Potion", 1, "PlayerClosing", nil)
-- ลำดับด่าน
check("unknown + not loaded",      "Add", nil,                           "Axe",    1, "UnknownItem",  nil)
check("invalid + closing",         "Add", makeSession({}, "Closing"),    "Potion", -1, "InvalidAmount", nil)
check("stack + full: stack first", "Add", loaded({ Potion = 1, Sword = 1 }), "Gem", 6, "ExceedsStack", nil)

return {}