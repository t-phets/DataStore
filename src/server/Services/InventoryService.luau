--!strict

local ProfileSessionTypes = require("../Types/ProfileSessionTypes")
local InventoryTypes = require("../Types/InventoryTypes")
local SessionAccess = require("./SessionAccess")
local AmountRules = require("../Domain/AmountRules")

type ItemDefinition = InventoryTypes.ItemDefinition
type InventoryConfig = InventoryTypes.InventoryConfig
type AddItemResult = InventoryTypes.AddItemResult
type RemoveItemResult = InventoryTypes.RemoveItemResult

export type InventoryServiceApi = {
    AddItem: (userId: number, itemId: string, quantity: number) -> AddItemResult,
    RemoveItem: (userId: number, itemId: string, quantity: number) -> RemoveItemResult,
}

local InventoryService = {}

local function isPositiveInteger(n: number): boolean
    return n >= 1 and n < math.huge and n == math.floor(n)
end

local function indexItems(config: InventoryConfig): { [string]: ItemDefinition }
    assert(isPositiveInteger(config.maxItemTypes), "maxItemTypes must be a positive integer")
    local byId: { [string]: ItemDefinition } = {}
    for _, item in config.items do
        assert(byId[item.id] == nil, "duplicate item id: " .. item.id)
        assert(isPositiveInteger(item.maxStack), "maxStack must be a positive integer: " .. item.id)
        byId[item.id] = item
    end
    return byId
end

local function countItemTypes(inventory: { [string]: number }): number
    local count = 0
    for _ in inventory do
        count += 1
    end
    return count
end

function InventoryService.new(
    getSession: ProfileSessionTypes.SessionProvider,
    config: InventoryConfig
): InventoryServiceApi
    local byId = indexItems(config)

    local function addItem(userId: number, itemId: string, quantity: number): AddItemResult
        local definition: ItemDefinition? = byId[itemId]
        if definition == nil then
            return { success = false, reason = "UnknownItem" }
        end
        if not AmountRules.IsValid(quantity, true) then
            return { success = false, reason = "InvalidAmount" }
        end

        local lookup = SessionAccess.FindWritable(getSession, userId)
        if not lookup.ok then
            return { success = false, reason = lookup.reason }
        end

        local inventory = lookup.session.data.inventory
        local current: number = inventory[itemId] or 0
        if current + quantity > definition.maxStack then
            return { success = false, reason = "ExceedsStack" }
        end
        if current == 0 and countItemTypes(inventory) >= config.maxItemTypes then
            return { success = false, reason = "InventoryFull" }
        end

        local newQuantity = current + quantity
        inventory[itemId] = newQuantity
        return { success = true, newQuantity = newQuantity }
    end

    local function removeItem(userId: number, itemId: string, quantity: number): RemoveItemResult
        if byId[itemId] == nil then
            return { success = false, reason = "UnknownItem" }
        end
        if not AmountRules.IsValid(quantity, true) then
            return { success = false, reason = "InvalidAmount" }
        end

        local lookup = SessionAccess.FindWritable(getSession, userId)
        if not lookup.ok then
            return { success = false, reason = lookup.reason }
        end

        local inventory = lookup.session.data.inventory
        local current: number = inventory[itemId] or 0
        if current < quantity then
            return { success = false, reason = "NotEnough" }
        end

        local remaining = current - quantity
        if remaining == 0 then
            inventory[itemId] = nil
        else
            inventory[itemId] = remaining
        end
        return { success = true, newQuantity = remaining }
    end

    return { AddItem = addItem, RemoveItem = removeItem }
end

return InventoryService