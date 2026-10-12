--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataTypes = require("@game/ReplicatedStorage/Shared/Types/PlayerDataTypes")

export type DecodeFailure = "InvalidData" | "UnsupportedVersion"

export type DecodeResult =
    { ok: true, data: PlayerDataTypes.PlayerData, migratedFrom: number? }
    | { ok: false, reason: DecodeFailure, detail: string }

return {}