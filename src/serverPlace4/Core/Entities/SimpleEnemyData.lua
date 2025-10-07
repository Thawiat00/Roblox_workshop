-- ==========================================
-- Core/Entities/SimpleEnemyData.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: เก็บข้อมูลพื้นฐานของศัตรู 1 ตัว
-- เขียนหลัง AIState เพราะ: ใช้ AIState ในการตรวจสอบสถานะ
-- ไม่มี Roblox API: เป็น Pure Data Structure ทดสอบได้นอกเกม
-- ==========================================
local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)


local SimpleEnemyData = {}
SimpleEnemyData.__index = SimpleEnemyData

-- ==========================================
-- Constructor: สร้าง Enemy Data ใหม่
-- ==========================================
function SimpleEnemyData.new(model, suppressWarning)
    local self = setmetatable({}, SimpleEnemyData)

    if not model and not suppressWarning then
        warn("[SimpleEnemyData] Model is nil — created as data-only enemy")
    end

    self.Model = model
    self.WalkSpeed = 8
    self.CurrentSpeed = 0
    self.CurrentState = AIState.Idle

    return self
end

-- ==========================================
-- Setters: เปลี่ยนค่าข้อมูล
-- ==========================================

-- เปลี่ยนสถานะ AI
function SimpleEnemyData:SetState(newState)
    -- (Optional) ตรวจสอบว่า state ที่ส่งมาเป็นค่าใน AIState
    local validState = false
    for _, state in pairs(AIState) do
        if state == newState then
            validState = true
            break
        end
    end

    if not validState then
        warn(("[SimpleEnemyData] Invalid state '%s'"):format(tostring(newState)))
        return
    end

    self.CurrentState = newState
end

-- ตั้งค่าความเร็วปัจจุบัน
function SimpleEnemyData:SetSpeed(speed)
	self.CurrentSpeed = speed
end



-- ==========================================
-- Getters: ตรวจสอบสถานะ (ใช้บ่อยใน Logic)
-- ==========================================

-- Getters
function SimpleEnemyData:IsIdle()
    return self.CurrentState == AIState.Idle
end

function SimpleEnemyData:IsWalking()
     return self.CurrentState == AIState.Walk
end

function SimpleEnemyData:IsStopped()
     return self.CurrentState == AIState.Stop
end

return SimpleEnemyData