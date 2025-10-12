-- ==========================================
-- Application/Services/ImpactService.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Logic การกระแทก Player
-- ไม่มี Roblox API: Logic บริสุทธิ์
-- ==========================================

local ImpactState = require(game.ServerScriptService.ServerLocal.Core.Enums.ImpactState)

local ImpactService = {}
ImpactService.__index = ImpactService

-- ==========================================
-- Constructor
-- ==========================================
function ImpactService.new(impactData)
    local self = setmetatable({}, ImpactService)
    self.ImpactData = impactData
    return self
end

-- ==========================================
-- คำนวณทิศทางและแรงกระแทก
-- ==========================================
function ImpactService:ComputeImpactForce(enemyPosition, playerPosition, enemyMass)
    if not enemyPosition or not playerPosition then
        warn("[ImpactService] Cannot compute force: invalid positions")
        return nil
    end
    
    -- คำนวณทิศทาง (จาก Enemy → Player)
    local direction = (playerPosition - enemyPosition).Unit
    
    -- คำนวณแรง (ใช้ Base Force + Mass)
    local baseMagnitude = self.ImpactData.ForceMagnitude
    local massMultiplier = enemyMass or 1
    
    local totalMagnitude = baseMagnitude * massMultiplier * self.ImpactData.MassMultiplier
    
    return {
        Direction = direction,
        Magnitude = totalMagnitude,
        Force = direction * totalMagnitude
    }
end

-- ==========================================
-- เริ่มการกระแทก
-- ==========================================
function ImpactService:StartImpact(enemyPosition, playerPosition, enemyMass)
    -- คำนวณแรงกระแทก
    local impactForce = self:ComputeImpactForce(enemyPosition, playerPosition, enemyMass)
    
    if not impactForce then
        warn("[ImpactService] Failed to start impact")
        return false
    end
    
    -- ตั้งค่าข้อมูลกระแทก
    self.ImpactData:SetImpactForce(impactForce.Magnitude, impactForce.Direction)
    self.ImpactData:StartImpact(tick())
    
    print("[ImpactService] Impact started - Force:", impactForce.Magnitude, "Direction:", impactForce.Direction)
    return true
end

-- ==========================================
-- หยุดการกระแทก
-- ==========================================
function ImpactService:StopImpact()
    self.ImpactData:StopImpact()
    print("[ImpactService] Impact stopped")
end

-- ==========================================
-- เข้าสู่สถานะ Recovery
-- ==========================================
function ImpactService:StartRecovery()
    self.ImpactData:StartRecovery()
    print("[ImpactService] Recovery started")
end

-- ==========================================
-- กลับสู่สภาวะปกติ
-- ==========================================
function ImpactService:CompleteRecovery()
    self.ImpactData:StopImpact()
    print("[ImpactService] Recovery completed")
end

-- ==========================================
-- ตรวจสอบว่าครบเวลากระแทกหรือยัง
-- ==========================================
function ImpactService:CheckImpactComplete(currentTime)
    return self.ImpactData:IsImpactComplete(currentTime or tick())
end

-- ==========================================
-- ดึงข้อมูลแรงกระแทกสำหรับส่งไปยัง Infrastructure
-- ==========================================
function ImpactService:GetImpactForceData()
    if not self.ImpactData:IsPushed() then
        return nil
    end
    
    return {
        Direction = self.ImpactData.ImpactDirection,
        Magnitude = self.ImpactData.ImpactForce,
        Duration = self.ImpactData.ImpactDuration,
        CompensateGravity = self.ImpactData.GravityCompensation
    }
end

-- ==========================================
-- Getters
-- ==========================================
function ImpactService:IsPushed()
    return self.ImpactData:IsPushed()
end

function ImpactService:IsRecovering()
    return self.ImpactData:IsRecovering()
end

function ImpactService:IsImpacting()
    return self.ImpactData:IsImpacting()
end

function ImpactService:GetElapsedTime()
    return self.ImpactData:GetImpactElapsedTime(tick())
end

-- ==========================================
-- Configuration
-- ==========================================
function ImpactService:SetForceMagnitude(magnitude)
    self.ImpactData.ForceMagnitude = magnitude
end

function ImpactService:SetImpactDuration(duration)
    self.ImpactData.ImpactDuration = duration
end

function ImpactService:SetMassMultiplier(multiplier)
    self.ImpactData.MassMultiplier = multiplier
end

function ImpactService:SetGravityCompensation(enabled)
    self.ImpactData.GravityCompensation = enabled
end

return ImpactService