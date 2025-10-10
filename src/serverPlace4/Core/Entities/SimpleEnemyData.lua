-- ==========================================
-- Core/Entities/SimpleEnemyData.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: เก็บข้อมูลพื้นฐานของศัตรู 1 ตัว
-- เขียนหลัง AIState เพราะ: ใช้ AIState ในการตรวจสอบสถานะ
-- ไม่มี Roblox API: เป็น Pure Data Structure ทดสอบได้นอกเกม
-- ==========================================
local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
local DetectionState = require(game.ServerScriptService.ServerLocal.Core.Enums.DetectionState)


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

        -- ✨ ข้อมูลใหม่ Phase 2
    self.RunSpeed = 15                          -- ความเร็วไล่
    self.CurrentTarget = nil                    -- ผู้เล่นที่กำลังไล่
    self.DetectionState = DetectionState.Default -- สถานะการตรวจจับ
    self.DetectedObject = nil                   -- object ที่ตรวจเจอ


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


-- ✨ ใหม่: ตั้ง Target
function SimpleEnemyData:SetTarget(target)
    self.CurrentTarget = target
end



-- ✨ ใหม่: ตั้งสถานะ Detection
function SimpleEnemyData:SetDetectionState(newState)
    local validState = false
    for _, state in pairs(DetectionState) do
        if state == newState then
            validState = true
            break
        end
    end

    if not validState then
        warn(("[SimpleEnemyData] Invalid Detection state '%s'"):format(tostring(newState)))
        return
    end

    self.DetectionState = newState
end



-- ✨ ใหม่: ตั้ง Detected Object
function SimpleEnemyData:SetDetectedObject(obj)
    self.DetectedObject = obj
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


-- ✨ ใหม่
function SimpleEnemyData:IsChasing()
    return self.CurrentState == AIState.Chase
end



return SimpleEnemyData