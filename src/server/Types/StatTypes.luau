--!strict

local ProfileSessionTypes = require("./ProfileSessionTypes")

export type StatDefinition = {
    id: string,
    min: number,
    max: number,
    integerOnly: boolean,
    canDecrease: boolean,
    initial: number,
    replicated: boolean,
}

export type StatFailure = 
    ProfileSessionTypes.SessionFailure | "InvalidAmount" | "UnknownStat"

export type IncreaseFailure = StatFailure | "ExceedsMax"
export type DecreaseFailure = StatFailure | "DecreaseNotAllowed" | "BelowMin"

export type IncreaseResult =
    { success: true, newValue: number }
    | { success: false, reason: IncreaseFailure }
export type DecreaseResult =
    {  success: true, newValue: number }
    | { success: false, reason: DecreaseFailure }

return {}