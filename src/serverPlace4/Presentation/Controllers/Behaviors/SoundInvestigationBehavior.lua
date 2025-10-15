-- ==========================================
-- Presentation/Controllers/Behaviors/SoundInvestigationBehavior.lua
-- ==========================================
-- วัตถุประสงค์: จัดการการตรวจสอบเสียงที่ได้ยิน
-- ==========================================

local PathfindingHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.PathfindingHelper)
local SoundHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.SoundHelper)

local SoundInvestigationBehavior = {}
SoundInvestigationBehavior.__index = SoundInvestigationBehavior

-- ==========================================
-- Constructor
-- ==========================================
function SoundInvestigationBehavior.new(controller)
    local self = setmetatable({}, SoundInvestigationBehavior)
    
    self.Controller = controller
    self.EnemyData = controller.EnemyData
    self.Humanoid = controller.Humanoid
    self.RootPart = controller.RootPart
    self.Path = controller.Path
    
    self.SoundReachThreshold = controller.SoundReachThreshold
    self.SoundCheckInterval = controller.SoundCheckInterval
    
    self.IsInvestigating = false
    self.InvestigationTarget = nil
    
    return self
end

-- ==========================================
-- ✨ เริ่ม Sound Investigation Loop
-- ==========================================
function SoundInvestigationBehavior:StartInvestigationLoop()
    task.spawn(function()
        while self.Controller.IsActive and self.Humanoid.Health > 0 do
            
            -- ถ้ามีเสียงที่ต้องตรวจสอบ
            if self.Controller.SoundDetectionService:IsAlerted() and not self.IsInvestigating then
                self:StartInvestigation()
            end
            
            -- ถ้ากำลังตรวจสอบอยู่
            if self.IsInvestigating then
                -- ตรวจสอบว่า Alert หมดเวลาหรือยัง
                if self.Controller.SoundDetectionService:CheckAlertExpiry() then
                    print("[SoundInvestigation] Alert expired")
                    self:StopInvestigation()
                    
                elseif self.Controller.SoundDetectionService:ShouldStopInvestigating() then
                    print("[SoundInvestigation] Investigation timeout")
                    self:StopInvestigation()
                    
                elseif self.InvestigationTarget then
                    local distance = SoundHelper.GetDistance(
                        self.RootPart.Position,
                        self.InvestigationTarget
                    )
                    
                    if distance <= self.SoundReachThreshold then
                        print("[SoundInvestigation] Reached sound location!")
                        self.Controller.SoundDetectionService:ReachedSoundLocation()
                        task.wait(1.0)
                        self:StopInvestigation()
                    end
                end
            end
            
            task.wait(self.SoundCheckInterval or 0.2)
        end
    end)
end

-- ==========================================
-- ✨ เริ่มตรวจสอบเสียง
-- ==========================================
function SoundInvestigationBehavior:StartInvestigation()
    if self.IsInvestigating then return end
    
    -- ดึงตำแหน่งเสียง
    local soundPosition = self.Controller.SoundDetectionService:GetLastHeardPosition()
    if not soundPosition then
        warn("[SoundInvestigation] Cannot investigate: no sound position")
        return
    end
    
    -- ตั้งค่าสถานะ
    self.IsInvestigating = true
    self.InvestigationTarget = soundPosition
    self.Controller.IsInvestigatingSound = true
    self.Controller.SoundInvestigationTarget = soundPosition
    
    -- เรียก Service
    self.Controller.SoundDetectionService:StartInvestigation()
    
    -- หยุด Chase ถ้ากำลังไล่อยู่
    if self.Controller.IsChasing then
        print("[SoundInvestigation] Stopping chase to investigate sound")
        self.Controller.ChaseBehavior:StopChasing()
    end
    
    -- ตั้งความเร็ว
    self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
    
    print("[SoundInvestigation] Started investigating sound at:", soundPosition)
    
    -- เริ่ม Movement Loop
    task.spawn(function()
        self:InvestigationMovementLoop()
    end)
end

-- ==========================================
-- ✨ SOUND INVESTIGATION MOVEMENT LOOP
-- ==========================================
function SoundInvestigationBehavior:InvestigationMovementLoop()
    while self.IsInvestigating and self.Controller.IsActive and self.Humanoid.Health > 0 do
        
        if not self.InvestigationTarget then
            break
        end
        
        -- คำนวณ path
        local success, waypoints = PathfindingHelper.ComputePath(
            self.Path,
            self.RootPart.Position,
            self.InvestigationTarget
        )
        
        if success and #waypoints > 1 then
            local nextWaypoint = waypoints[2]
            
            if PathfindingHelper.ShouldJump(nextWaypoint) then
                self.Humanoid.Jump = true
                task.wait(0.3)
            end
            
            self.Humanoid:MoveTo(nextWaypoint.Position)
            
            local moveFinished = false
            local moveConnection = self.Humanoid.MoveToFinished:Connect(function()
                moveFinished = true
            end)
            
            local startTime = tick()
            repeat 
                task.wait(0.05)
                if tick() - startTime > 2 then break end
            until moveFinished or not self.IsInvestigating
            
            moveConnection:Disconnect()
        else
            warn("[SoundInvestigation] Path failed, moving directly")
            self.Humanoid:MoveTo(self.InvestigationTarget)
            task.wait(0.5)
        end
        
        task.wait(0.1)
    end
    
    print("[SoundInvestigation] Movement loop ended")
end

-- ==========================================
-- ✨ หยุดตรวจสอบเสียง
-- ==========================================
function SoundInvestigationBehavior:StopInvestigation()
    if not self.IsInvestigating then return end
    
    self.IsInvestigating = false
    self.InvestigationTarget = nil
    self.Controller.IsInvestigatingSound = false
    self.Controller.SoundInvestigationTarget = nil
    
    -- เรียก Service
    self.Controller.SoundDetectionService:CalmDown()
    
    -- หยุดเคลื่อนที่
    self.Humanoid.WalkSpeed = 0
    
    print("[SoundInvestigation] Stopped investigation")
    
    -- กลับสู่พฤติกรรมปกติ (Idle)
    task.wait(0.5)
    self.Humanoid.WalkSpeed = self.EnemyData.WalkSpeed
end

-- ==========================================
-- ✨ Callback เมื่อได้ยินเสียง
-- ==========================================
function SoundInvestigationBehavior:OnHearSound(soundPosition, soundSource)
    -- ตรวจสอบว่าอยู่ในระยะได้ยินหรือไม่
    if not self.Controller.SoundDetectionService:IsWithinHearingRange(self.RootPart.Position, soundPosition) then
        return false
    end
    
    -- ✅ ใช้ Priority System
    local soundInvestigationPriority = 3
    
    if not self.Controller.PriorityHandler:CanInterruptForBehavior(soundInvestigationPriority) then
        print("[SoundInvestigation] Cannot interrupt current behavior for sound")
        return false
    end
    
    -- บันทึกเสียง
    local success = self.Controller.SoundDetectionService:OnHearSound(soundPosition, soundSource)
    
    if success then
        print("[SoundInvestigation]", self.Controller.Model.Name, "heard sound from:", soundSource and soundSource.Name or "Unknown")
    end
    
    return success
end

return SoundInvestigationBehavior