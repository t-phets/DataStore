--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")
local StatTypes = require("../Types/StatTypes")
local InventoryTypes = require("../Types/InventoryTypes")
local SchemaTypes = require("../Types/SchemaTypes")

type PlayerData = PlayerDataTypes.PlayerData
type StatDefinition = StatTypes.StatDefinition
type ItemDefinition = InventoryTypes.ItemDefinition
type DecodeResult = SchemaTypes.DecodeResult
type DecodeFailure = SchemaTypes.DecodeFailure

type Record = { [string]: unknown }
type Migration = (record: Record) -> (Record?, string?)

export type PlayerDataSchemaApi = {
    Decode: (raw: unknown) -> DecodeResult,
}

local CURRENT_VERSION = 2

local PlayerDataSchema = {}
PlayerDataSchema.CURRENT_VERSION = CURRENT_VERSION

local function isFinite(n: number): boolean
    return n == n and n > -math.huge and n < math.huge
end

local function asRecord(value: unknown): Record?
    if type(value) ~= "table" then
        return nil
    end
    -- จุดเดียวที่ cast: ตรวจแล้วว่าเป็น table แต่ยังไม่รู้ชนิดข้างใน
    -- จึงถือทุกค่าข้างในเป็น unknown และตรวจทีละตัวต่อไป
    return value :: Record
end

local function fail(reason: DecodeFailure, detail: string): DecodeResult
    return { ok = false, reason = reason, detail = detail }
end

-- v1 คือรูปแบบของ Milestone A เดิม:
-- { schemaVersion = 1, coins = number, inventory = { { itemId, quantity } } }
local function migrateV1ToV2(record: Record): (Record?, string?)
    local coins = record.coins
    if type(coins) ~= "number" then
        return nil, "v1: coins is not a number"
    end

    local legacyInventory = record.inventory
    if type(legacyInventory) ~= "table" then
        return nil, "v1: inventory is not a table"
    end

    local inventory: { [string]: number } = {}
    for _, entry in legacyInventory :: { unknown } do
        local e = asRecord(entry)
        if e == nil then
            return nil, "v1: inventory entry is not a table"
        end
        local itemId = e.itemId
        local quantity = e.quantity
        if type(itemId) ~= "string" or type(quantity) ~= "number" then
            return nil, "v1: malformed inventory entry"
        end
        -- รูปแบบเก่าซ้ำชื่อได้ จึงรวมจำนวน
        inventory[itemId] = (inventory[itemId] or 0) + quantity
    end

    return {
        schemaVersion = 2,
        stats = { Coins = coins },
        inventory = inventory,
    }, nil
end

-- key คือ "เวอร์ชันต้นทาง" ของแต่ละ migration
local migrations: { [number]: Migration } = {
    [1] = migrateV1ToV2,
}

function PlayerDataSchema.new(
    statDefinitions: { StatDefinition },
    itemDefinitions: { ItemDefinition }
): PlayerDataSchemaApi
    local statsById: { [string]: StatDefinition } = {}
    for _, def in statDefinitions do
        statsById[def.id] = def
    end
    local itemsById: { [string]: ItemDefinition } = {}
    for _, item in itemDefinitions do
        itemsById[item.id] = item
    end

    local function decodeStats(raw: unknown): ({ [string]: number }?, string?)
        local statsRaw = asRecord(raw)
        if statsRaw == nil then
            return nil, "stats is not a table"
        end

        local stats: { [string]: number } = {}
        for key, value in statsRaw do
            -- cast ข้างบนไม่ได้รับประกันชนิดของ key จึงตรวจจริง ณ runtime
            if type(key) ~= "string" then
                return nil, "stats has a non-string key"
            end
            if type(value) ~= "number" or not isFinite(value) then
                return nil, "stat is not a finite number: " .. key
            end
            local def = statsById[key]
            if def ~= nil then
                if value < def.min or value > def.max then
                    return nil, "stat out of range: " .. key
                end
                if def.integerOnly and value ~= math.floor(value) then
                    return nil, "stat must be an integer: " .. key
                end
            end
            stats[key] = value
        end

        -- เติมเฉพาะ stat ที่ยังไม่มี (เช่น เพิ่งเพิ่มใน config) ไม่แตะค่าที่มีอยู่แล้ว
        for _, def in statDefinitions do
            if stats[def.id] == nil then
                stats[def.id] = def.initial
            end
        end
        return stats, nil
    end

    local function decodeInventory(raw: unknown): ({ [string]: number }?, string?)
        local inventoryRaw = asRecord(raw)
        if inventoryRaw == nil then
            return nil, "inventory is not a table"
        end

        local inventory: { [string]: number } = {}
        for key, value in inventoryRaw do
            if type(key) ~= "string" then
                return nil, "inventory has a non-string key"
            end
            if
                type(value) ~= "number"
                or not isFinite(value)
                or value < 1
                or value ~= math.floor(value)
            then
                return nil, "inventory quantity must be a positive integer: " .. key
            end
            local item = itemsById[key]
            if item ~= nil and value > item.maxStack then
                return nil, "inventory quantity above maxStack: " .. key
            end
            inventory[key] = value
        end
        return inventory, nil
    end

        -- Decode
        local function decode(raw: unknown): DecodeResult
        local record = asRecord(raw)
        if record == nil then
            return fail("InvalidData", "profile is not a table")
        end

        local rawVersion = record.schemaVersion
        if type(rawVersion) ~= "number" or rawVersion ~= math.floor(rawVersion) or rawVersion < 1 then
            return fail("InvalidData", "schemaVersion is missing or invalid")
        end
        if rawVersion > CURRENT_VERSION then
            return fail("UnsupportedVersion", "written by a newer version: " .. tostring(rawVersion))
        end

        local version: number = rawVersion
        local current: Record = record
        local migratedFrom: number? = nil
        while version < CURRENT_VERSION do
            local migrate = migrations[version]
            if migrate == nil then
                return fail("InvalidData", "no migration from version " .. tostring(version))
            end
            local migrated, errorMessage = migrate(current)
            if migrated == nil then
                return fail("InvalidData", errorMessage or "migration failed")
            end
            current = migrated
            if migratedFrom == nil then
                migratedFrom = version
            end
            version += 1
        end

        local stats, statsError = decodeStats(current.stats)
        if stats == nil then
            return fail("InvalidData", statsError or "invalid stats")
        end
        local inventory, inventoryError = decodeInventory(current.inventory)
        if inventory == nil then
            return fail("InvalidData", inventoryError or "invalid inventory")
        end

        return {
            ok = true,
            data = { schemaVersion = CURRENT_VERSION, stats = stats, inventory = inventory },
            migratedFrom = migratedFrom,
        }
    end

    return { Decode = decode }
end

return PlayerDataSchema