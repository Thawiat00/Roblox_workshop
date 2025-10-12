-- ==========================================
-- Application/Services/ChaseService.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Logic การไล่ player
-- ไม่มี Roblox API: Logic บริสุทธิ์
-- ==========================================

local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)

local ChaseService = {}
ChaseService.__index = ChaseService

function ChaseService.new(enemyData)
    local self = setmetatable({}, ChaseService)
    self.EnemyData = enemyData
    return self
end

-- เริ่มไล่ target
function ChaseService:StartChase(target)
    if not target then
        warn("[ChaseService] Cannot start chase: target is nil")
        return false
    end
    
    -- ตั้งค่า target
    self.EnemyData:SetTarget(target)
    
    -- เปลี่ยนเป็นความเร็ววิ่ง
    self.EnemyData:SetSpeed(self.EnemyData.RunSpeed)
    

    

    -- เปลี่ยน state เป็น Chase
    self.EnemyData:SetState(AIState.Chase)
    
    print("[ChaseService] Started chasing target at speed:", self.EnemyData.RunSpeed)
    return true
end

-- หยุดไล่
function ChaseService:StopChase()
    -- ล้าง target
    self.EnemyData:SetTarget(nil)
    
    -- หยุดเคลื่อนที่
    self.EnemyData:SetSpeed(0)
    
    -- กลับสู่ Idle
    self.EnemyData:SetState(AIState.Idle)
    
    print("[ChaseService] Stopped chasing")
end

-- เปลี่ยนเป็นการกระโดด
function ChaseService:SetJumping()
    self.EnemyData:SetState(AIState.Jumping)
    print("[ChaseService] Enemy is jumping")
end

-- กลับจากกระโดดไปยัง Chase
function ChaseService:ResumeChase()
    if self.EnemyData:HasTarget() then
        self.EnemyData:SetState(AIState.Chase)
        print("[ChaseService] Resumed chasing")
    end
end

-- ตรวจสอบว่ากำลังไล่อยู่หรือไม่
function ChaseService:IsChasing()
    return self.EnemyData:IsChasing()
end

-- ดึง target ปัจจุบัน
function ChaseService:GetCurrentTarget()
    return self.EnemyData.CurrentTarget
end

-- ตรวจสอบว่ามี target หรือไม่
function ChaseService:HasTarget()
    return self.EnemyData:HasTarget()
end

return ChaseService