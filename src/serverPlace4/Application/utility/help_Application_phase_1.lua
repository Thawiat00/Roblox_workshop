-- help_Application_phase_1.lua
-- Utility สำหรับช่วยสร้าง Enemy Mock หรือ Service Mock

local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)

local Utility = {}

-- สร้าง SimpleEnemyData แบบ Mock
function Utility.CreateEnemyMock()
    local enemy = {}
    enemy.CurrentState = AIState.Idle
    enemy.CurrentSpeed = 0
    enemy.WalkSpeed = 10 -- กำหนดค่า WalkSpeed เริ่มต้น

    function enemy:SetSpeed(speed)
        self.CurrentSpeed = speed
    end

    function enemy:SetState(state)
        self.CurrentState = state
    end

    return enemy
end

return Utility
