-- ==========================================
-- Core/Entities/SimpleEnemyData.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: เก็บข้อมูลพื้นฐานของศัตรู 1 ตัว
-- เขียนหลัง AIState เพราะ: ใช้ AIState ในการตรวจสอบสถานะ
-- ไม่มี Roblox API: เป็น Pure Data Structure ทดสอบได้นอกเกม
-- ==========================================
local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
local DetectionState = require(game.ServerScriptService.ServerLocal.Core.Enums.DetectionState)

    -- ✨ Phase 5: Sound Detection Data
local SoundData = require(game.ServerScriptService.ServerLocal.Core.Entities.SoundData)



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


       -- ✨ Phase 3: Spear Dash data
    self.SpearSpeed = 30                    -- ความเร็วตอนพุ่ง
    self.IsDashing = false                  -- กำลังพุ่งอยู่หรือไม่
    self.DashStartTime = nil                -- เวลาที่เริ่มพุ่ง
    self.DashDuration = 3.5                 -- ระยะเวลาพุ่ง (3-4 วินาที)
    self.DashDirection = nil                -- ทิศทางการพุ่ง
    self.LastDashTime = 0                   -- เวลาครั้งล่าสุดที่พุ่ง
    self.DashCooldown = 8                   -- คูลดาวน์ระหว่างการพุ่ง (วินาที)



    -- ✨ Phase 4: Impact tracking
    self.LastImpactedPlayer = nil     -- Player ที่โดนชนล่าสุด
    self.ImpactedPlayers = {}         -- เก็บรายชื่อ Player ที่โดนชนในรอบ Dash นี้
    self.DashDamage = 10              -- ความเสียหายเมื่อชน


    -- ✨ Phase 5: Sound Detection Data
    self.SoundData = SoundData.new()  -- เก็บข้อมูลการรับรู้เสียง


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
-- ✨ Phase 3: Dash Setters
-- ==========================================
function SimpleEnemyData:StartDash(direction, currentTime)
    self.IsDashing = true
    self.DashStartTime = currentTime or tick()
    self.DashDirection = direction
    self.LastDashTime = currentTime or tick()


        -- ✨ Phase 4: รีเซ็ตรายชื่อผู้เล่นที่โดนชนเมื่อเริ่ม Dash ใหม่
    self.ImpactedPlayers = {}

end

function SimpleEnemyData:StopDash()
    self.IsDashing = false
    self.DashStartTime = nil
    self.DashDirection = nil


    -- ✨ Phase 4: ล้างรายชื่อผู้เล่นที่โดนชนเมื่อหยุด Dash
    self.ImpactedPlayers = {}

end

function SimpleEnemyData:SetDashDuration(duration)
    self.DashDuration = duration
end


-- ==========================================
-- ✨ Phase 4: Impact Setters
-- ==========================================
function SimpleEnemyData:RecordPlayerImpact(player)
    if not player then return end
    
    self.LastImpactedPlayer = player
    self.ImpactedPlayers[player] = true
    
    print("[SimpleEnemyData] Recorded impact on player:", player.Name)
end


function SimpleEnemyData:HasImpactedPlayer(player)
    return self.ImpactedPlayers[player] == true
end

function SimpleEnemyData:ClearImpactRecords()
    self.ImpactedPlayers = {}
    self.LastImpactedPlayer = nil
end

function SimpleEnemyData:SetDashDamage(damage)
    self.DashDamage = damage
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


-- ✨ Phase 3: Dash Getters
function SimpleEnemyData:IsDashingState()
    return self.CurrentState == AIState.SpearDash
end


function SimpleEnemyData:IsRecovering()
    return self.CurrentState == AIState.Recover
end

function SimpleEnemyData:CanDash(currentTime)
    local timeSinceLastDash = (currentTime or tick()) - self.LastDashTime
    return timeSinceLastDash >= self.DashCooldown
end

function SimpleEnemyData:GetDashElapsedTime(currentTime)
    if not self.DashStartTime then return 0 end
    return (currentTime or tick()) - self.DashStartTime
end

function SimpleEnemyData:IsDashComplete(currentTime)
    return self:GetDashElapsedTime(currentTime) >= self.DashDuration
end


-- ==========================================
-- Phase 2: Detection
-- ==========================================
function SimpleEnemyData:IsDetecting()
    return self.DetectionState == DetectionState.Start_Detect
end

function SimpleEnemyData:HasTarget()
    return self.CurrentTarget ~= nil
end



-- ==========================================
-- ✨ Phase 5: Sound Detection Getters
-- ==========================================
function SimpleEnemyData:IsAlertedBySound()
    return self.SoundData and self.SoundData:IsAlerted()
end

function SimpleEnemyData:IsInvestigatingSound()
    return self.SoundData and self.SoundData:IsInvestigatingState()
end

function SimpleEnemyData:HasHeardSound()
    return self.SoundData and self.SoundData:HasHeardSound()
end



return SimpleEnemyData