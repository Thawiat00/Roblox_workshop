-- ==========================================
-- Core/Entities/SoundData.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: เก็บข้อมูลการรับรู้เสียงของ Enemy
-- Pure Data Structure: ทดสอบได้นอกเกม
-- ==========================================

local SoundState = require(game.ServerScriptService.ServerLocal.Core.Enums.SoundState)

local SoundData = {}
SoundData.__index = SoundData

-- ==========================================
-- Constructor
-- ==========================================
function SoundData.new()
    local self = setmetatable({}, SoundData)
    
    -- สถานะการรับรู้เสียง
    self.CurrentState = SoundState.Silent
    
    -- ข้อมูลเสียงที่ได้ยิน
    self.LastHeardPosition = nil        -- ตำแหน่งเสียงล่าสุด
    self.LastHeardTime = 0              -- เวลาที่ได้ยินเสียงล่าสุด
    self.SoundSource = nil              -- แหล่งที่มาของเสียง (Player/Object)
    
    -- การตั้งค่า
    self.HearingRange = 60              -- ระยะได้ยิน (studs)
    self.AlertDuration = 2.0            -- ระยะเวลา Alert (วินาที)
    self.AlertStartTime = nil           -- เวลาที่เริ่ม Alert
    
    -- การติดตาม
    self.IsInvestigating = false        -- กำลังตรวจสอบเสียงหรือไม่
    self.InvestigationStartTime = nil   -- เวลาที่เริ่มตรวจสอบ
    self.ReachedSoundLocation = false   -- ถึงตำแหน่งเสียงแล้วหรือยัง
    
    return self
end

-- ==========================================
-- Setters: Sound Detection
-- ==========================================
function SoundData:HearSound(position, source, currentTime)
    self.LastHeardPosition = position
    self.LastHeardTime = currentTime or tick()
    self.SoundSource = source
    self.CurrentState = SoundState.Alerted
    self.AlertStartTime = currentTime or tick()
    self.IsInvestigating = false
    self.InvestigationStartTime = nil
    self.ReachedSoundLocation = false
    
    print("[SoundData] Heard sound from:", source and source.Name or "Unknown")
end

function SoundData:StartInvestigation(currentTime)
    self.IsInvestigating = true
    self.InvestigationStartTime = currentTime or tick()
    self.CurrentState = SoundState.Investigating
    
    print("[SoundData] Started investigating sound")
end

function SoundData:ReachSoundLocation()
    self.ReachedSoundLocation = true
    print("[SoundData] Reached sound location")
end

function SoundData:ClearSound()
    self.LastHeardPosition = nil
    self.SoundSource = nil
    self.CurrentState = SoundState.Silent
    self.AlertStartTime = nil
    self.IsInvestigating = false
    self.InvestigationStartTime = nil
    self.ReachedSoundLocation = false
    
    print("[SoundData] Sound cleared")
end

function SoundData:SetHearingRange(range)
    self.HearingRange = range
end

function SoundData:SetAlertDuration(duration)
    self.AlertDuration = duration
end

-- ==========================================
-- Getters: Sound State
-- ==========================================
function SoundData:IsSilent()
    return self.CurrentState == SoundState.Silent
end

function SoundData:IsAlerted()
    return self.CurrentState == SoundState.Alerted
end

function SoundData:IsInvestigatingState()
    return self.CurrentState == SoundState.Investigating
end

function SoundData:HasHeardSound()
    return self.LastHeardPosition ~= nil
end

function SoundData:GetTimeSinceHeard(currentTime)
    if not self.LastHeardTime then return math.huge end
    return (currentTime or tick()) - self.LastHeardTime
end

function SoundData:GetTimeSinceAlert(currentTime)
    if not self.AlertStartTime then return math.huge end
    return (currentTime or tick()) - self.AlertStartTime
end

function SoundData:IsAlertExpired(currentTime)
    return self:GetTimeSinceAlert(currentTime) >= self.AlertDuration
end

function SoundData:GetTimeSinceInvestigationStart(currentTime)
    if not self.InvestigationStartTime then return 0 end
    return (currentTime or tick()) - self.InvestigationStartTime
end

-- ==========================================
-- Utility: Distance Check
-- ==========================================
function SoundData:IsWithinHearingRange(enemyPosition, soundPosition)
    if not enemyPosition or not soundPosition then return false end
    local distance = (enemyPosition - soundPosition).Magnitude
    return distance <= self.HearingRange
end

return SoundData