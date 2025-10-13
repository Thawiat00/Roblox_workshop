-- ==========================================
-- Application/Services/SoundDetectionService.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Logic การได้ยินเสียงและการตอบสนอง
-- ไม่มี Roblox API: Logic บริสุทธิ์
-- ==========================================

local SoundState = require(game.ServerScriptService.ServerLocal.Core.Enums.SoundState)

local SoundDetectionService = {}
SoundDetectionService.__index = SoundDetectionService

-- ==========================================
-- Constructor
-- ==========================================
function SoundDetectionService.new(enemyData, soundData)
    local self = setmetatable({}, SoundDetectionService)
    
    self.EnemyData = enemyData
    self.SoundData = soundData
    
    return self
end

-- ==========================================
-- ✨ ได้ยินเสียง
-- ==========================================
function SoundDetectionService:OnHearSound(soundPosition, soundSource)
    if not soundPosition then
        warn("[SoundDetectionService] Cannot hear sound: position is nil")
        return false
    end
    
    -- บันทึกข้อมูลเสียง
    self.SoundData:HearSound(soundPosition, soundSource, tick())
    
    print("[SoundDetectionService] Enemy heard sound at:", soundPosition)
    return true
end

-- ==========================================
-- ✨ เริ่มตรวจสอบเสียง
-- ==========================================
function SoundDetectionService:StartInvestigation()
    if not self.SoundData:HasHeardSound() then
        warn("[SoundDetectionService] Cannot investigate: no sound heard")
        return false
    end
    
    self.SoundData:StartInvestigation(tick())
    
    print("[SoundDetectionService] Started investigating")
    return true
end

-- ==========================================
-- ✨ ถึงตำแหน่งเสียงแล้ว
-- ==========================================
function SoundDetectionService:ReachedSoundLocation()
    self.SoundData:ReachSoundLocation()
    print("[SoundDetectionService] Reached sound location")
end

-- ==========================================
-- ✨ ตรวจสอบว่า Alert หมดเวลาหรือยัง
-- ==========================================
function SoundDetectionService:CheckAlertExpiry()
    if self.SoundData:IsAlerted() and self.SoundData:IsAlertExpired(tick()) then
        print("[SoundDetectionService] Alert expired, calming down")
        self:CalmDown()
        return true
    end
    return false
end

-- ==========================================
-- ✨ กลับสู่สภาวะปกติ
-- ==========================================
function SoundDetectionService:CalmDown()
    self.SoundData:ClearSound()
    print("[SoundDetectionService] Calmed down")
end

-- ==========================================
-- ✨ ตรวจสอบว่าอยู่ในระยะได้ยินหรือไม่
-- ==========================================
function SoundDetectionService:IsWithinHearingRange(enemyPosition, soundPosition)
    return self.SoundData:IsWithinHearingRange(enemyPosition, soundPosition)
end

-- ==========================================
-- ✨ ตั้งค่าระยะได้ยิน
-- ==========================================
function SoundDetectionService:SetHearingRange(range)
    self.SoundData:SetHearingRange(range)
    print("[SoundDetectionService] Hearing range set to:", range)
end

function SoundDetectionService:SetAlertDuration(duration)
    self.SoundData:SetAlertDuration(duration)
    print("[SoundDetectionService] Alert duration set to:", duration)
end

-- ==========================================
-- Getters
-- ==========================================
function SoundDetectionService:IsAlerted()
    return self.SoundData:IsAlerted()
end

function SoundDetectionService:IsInvestigating()
    return self.SoundData:IsInvestigatingState()
end

function SoundDetectionService:HasHeardSound()
    return self.SoundData:HasHeardSound()
end

function SoundDetectionService:GetLastHeardPosition()
    return self.SoundData.LastHeardPosition
end

function SoundDetectionService:GetSoundSource()
    return self.SoundData.SoundSource
end

function SoundDetectionService:IsSilent()
    return self.SoundData:IsSilent()
end

-- ==========================================
-- ✨ ตรวจสอบว่าควรหยุดตรวจสอบหรือไม่
-- ==========================================
function SoundDetectionService:ShouldStopInvestigating()
    -- ถ้าถึงตำแหน่งแล้ว และ Alert หมดเวลา
    if self.SoundData.ReachedSoundLocation and self.SoundData:IsAlertExpired(tick()) then
        return true
    end
    
    -- ถ้าตรวจสอบนานเกินไป (เช่น 10 วินาที)
    if self.SoundData:GetTimeSinceInvestigationStart(tick()) > 10 then
        return true
    end
    
    return false
end

return SoundDetectionService