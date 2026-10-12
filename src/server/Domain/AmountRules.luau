--!strict

local AmountRules = {}

function AmountRules.IsValid(amount: number, integerOnly: boolean): boolean
    if not (amount > 0 and amount < math.huge) then
        return false
    end
    return (not integerOnly) or amount == math.floor(amount)
end

return AmountRules