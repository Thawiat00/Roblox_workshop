-- ==========================================
-- Core/Entities/ImpactData.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: เก็บข้อมูลการกระแทกของ Player
-- Pure Data Structure: ทดสอบได้นอกเกม
-- ==========================================

local ImpactState = require(game.ServerScriptService.ServerLocal.Core.Enums.ImpactState)

local ImpactData = {}
ImpactData.__index = ImpactData

-- ==========================================
-- Constructor
-- ==========================================
function ImpactData.new()
    local self = setmetatable({}, ImpactData)
    
    -- สถานะการกระแทก
    self.ImpactState = ImpactState.None
    
    -- ข้อมูลแรงกระแทก
    self.ImpactForce = 0              -- ความแรง (magnitude)
    self.ImpactDirection = nil        -- ทิศทาง (Unit Vector3)
    self.ImpactDuration = 0.2         -- ระยะเวลาที่แรงส่งผล (วินาที)
    
    -- ข้อมูลการควบคุม
    self.ForceMagnitude = 1500        -- แรงพื้นฐาน
    self.MassMultiplier = 1           -- คูณแรงตามน้ำหนัก
    self.GravityCompensation = true   -- ชดเชยแรงโน้มถ่วง
    
    -- เวลา
    self.ImpactStartTime = nil        -- เวลาที่เริ่มโดนกระแทก
    
    return self
end

-- ==========================================
-- Setters
-- ==========================================
function ImpactData:SetImpactState(newState)
    local validState = false
    for _, state in pairs(ImpactState) do
        if state == newState then
            validState = true
            break
        end
    end
    
    if not validState then
        warn(("[ImpactData] Invalid state '%s'"):format(tostring(newState)))
        return
    end
    
    self.ImpactState = newState
end

function ImpactData:SetImpactForce(magnitude, direction)
    self.ImpactForce = magnitude
    self.ImpactDirection = direction
end

function ImpactData:StartImpact(currentTime)
    self.ImpactStartTime = currentTime or tick()
    self.ImpactState = ImpactState.Pushed
end

function ImpactData:StopImpact()
    self.ImpactState = ImpactState.None
    self.ImpactStartTime = nil
    self.ImpactForce = 0
    self.ImpactDirection = nil
end

function ImpactData:StartRecovery()
    self.ImpactState = ImpactState.Recovering
end

-- ==========================================
-- Getters
-- ==========================================
function ImpactData:IsPushed()
    return self.ImpactState == ImpactState.Pushed
end

function ImpactData:IsRecovering()
    return self.ImpactState == ImpactState.Recovering
end

function ImpactData:IsImpacting()
    return self.ImpactState ~= ImpactState.None
end

function ImpactData:GetImpactElapsedTime(currentTime)
    if not self.ImpactStartTime then return 0 end
    return (currentTime or tick()) - self.ImpactStartTime
end

function ImpactData:IsImpactComplete(currentTime)
    return self:GetImpactElapsedTime(currentTime) >= self.ImpactDuration
end

return ImpactData