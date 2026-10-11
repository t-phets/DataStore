--!strict

local ProfileSession = require("../Types/ProfileSessionTypes")

export type CoinFailure = ProfileSession.SessionFailure | "InvalidAmount"

export type RemoveCoinsFailure = CoinFailure | "InsufficientFunds"
export type RemoveCoinsResult = 
    { success: true, newBalance: number }
    | { success: false, reason: RemoveCoinsFailure }

export type AddCoinsFailure = CoinFailure | "ExceedsCap"
export type AddCoinsResult = 
    { success: true, newBalance: number }
    | { success: false, reason:  AddCoinsFailure}

export type CurrencyConfig = {
    maxCoins: number,
}

return {}