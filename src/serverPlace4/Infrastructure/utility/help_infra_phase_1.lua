local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local HelpInfra = {}

-- ตรวจสอบว่า state เป็นค่าที่ valid, ถ้า nil หรือไม่ถูกต้อง ให้ return default
function HelpInfra.ValidateState(state)
    local validStates = { "Idle", "Walking", "Attacking", "Dead" }
    for _, v in ipairs(validStates) do
        if v == state then
            return state
        end
    end
    return SimpleAIConfig.DefaultState
end

-- Set property ให้ enemyData โดยตรวจสอบว่าเป็น function (setter) หรือ field
function HelpInfra.SetEnemyProperty(enemyData, key, value)
    if enemyData[key] ~= nil and type(enemyData[key]) == "function" then
        enemyData[key](enemyData, value) -- เรียก setter method
    else
        enemyData[key] = value -- fallback เป็น field
    end
end


-- บังคับ property ให้เป็น boolean สำหรับ test
function HelpInfra.ForceBoolean(enemyData, key, defaultValue)
    -- ถ้า property เป็น function (getter/setter) หรือ nil ให้ override เป็น value
    if type(enemyData[key]) == "function" or enemyData[key] == nil then
        enemyData[key] = defaultValue
    end
end



return HelpInfra
