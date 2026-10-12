--!strict

local ProfileSessionTypes = require("./ProfileSessionTypes")

export type ItemDefinition = {
    id: string,
    maxStack: number,
}

export type InventoryConfig = {
    maxItemTypes: number,
    items: { ItemDefinition },
}

export type InventoryBaseFailure =
    ProfileSessionTypes.SessionFailure | "InvalidAmount" | "UnknownItem"

export type AddItemFailure = InventoryBaseFailure | "ExceedsStack" | "InventoryFull"
export type RemoveItemFailure = InventoryBaseFailure | "NotEnough"

export type AddItemResult =
    { success: true, newQuantity: number }
    | { success: false, reason: AddItemFailure }

export type RemoveItemResult =
    { success: true, newQuantity: number }
    | { success: false, reason: RemoveItemFailure }

return {}