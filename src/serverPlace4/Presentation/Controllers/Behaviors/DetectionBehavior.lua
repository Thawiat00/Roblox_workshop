-- ==========================================
-- Presentation/Controllers/Behaviors/DetectionBehavior.lua
-- ==========================================
-- วัตถุประสงค์: จัดการการตรวจจับ Player (Detection System)
-- รวบรวม Detection Logic ทั้งหมดไว้ที่นี่
-- ==========================================

local DetectionHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.DetectionHelper)
local PathfindingHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.PathfindingHelper)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local DetectionBehavior = {}
DetectionBehavior.__index = DetectionBehavior

-- ==========================================
-- Constructor
-- ==========================================
function DetectionBehavior.new(controller)
    local self = setmetatable({}, DetectionBehavior)
    
    self.Controller = controller
    self.EnemyData = controller.EnemyData
    self.Humanoid = controller.Humanoid
    self.RootPart = controller.RootPart
    
    self.DetectionRange = controller.DetectionRange
    self.ChaseStopRange = controller.ChaseStopRange
    self.ChaseStopDelay = controller.ChaseStopDelay
    
    -- สร้าง OverlapParams สำหรับ Detection
    self.OverlapParams = DetectionHelper.CreateOverlapParams(controller.Model)
    self.OutOfRangeStartTime = nil
    
    return self
end

-- ==========================================
-- ✨ เริ่ม Detection Loop (Main Detection System)
-- ==========================================
function DetectionBehavior:StartDetectionLoop()
    task.spawn(function()
        while self.Controller.IsActive and self.Humanoid.Health > 0 do
            
            -- ถ้ากำลังไล่อยู่ - ตรวจสอบ target
            if self.Controller.IsChasing and self.Controller.CurrentTarget then
                self:CheckCurrentTarget()
            else
                -- ถ้าไม่ได้ไล่ - มองหา player ใหม่
                self:SearchForNewTarget()
            end
            
            task.wait(SimpleAIConfig.DetectionCheckInterval or 0.1)
        end
        
        print("[DetectionBehavior] Detection loop ended")
    end)
end

-- ==========================================
-- ✨ ตรวจสอบ Target ปัจจุบัน (เมื่อกำลังไล่อยู่)
-- ==========================================
function DetectionBehavior:CheckCurrentTarget()
    local target = self.Controller.CurrentTarget
    
    -- ✅ เช็คว่า target ยังมีชีวิตอยู่หรือไม่
    if not DetectionHelper.IsTargetValid(target) then
        print("[DetectionBehavior] Target invalid, stopping chase")
        self.Controller.ChaseBehavior:StopChasing()
        return
    end
    
    -- ✅ เช็คระยะห่าง
    local isOutOfRange = DetectionHelper.IsTargetOutOfRange(
        self.RootPart.Position,
        target,
        self.ChaseStopRange
    )
    
    if isOutOfRange then
        -- ถ้าเพิ่งหลุดระยะ - เริ่มนับเวลา
        if not self.OutOfRangeStartTime then
            self.OutOfRangeStartTime = tick()
            print("[DetectionBehavior] Target out of range, waiting before stop...")
        else
            -- เช็คว่าหลุดระยะนานพอหรือยัง
            local outOfRangeTime = tick() - self.OutOfRangeStartTime
            if outOfRangeTime >= self.ChaseStopDelay then
                print("[DetectionBehavior] Target out of range too long, stopping chase")
                self.Controller.ChaseBehavior:StopChasing()
            end
        end
    else
        -- ยังอยู่ในระยะ - รีเซ็ตตัวนับเวลา
        self.OutOfRangeStartTime = nil
    end
end

-- ==========================================
-- ✨ ค้นหา Target ใหม่ (เมื่อไม่ได้ไล่)
-- ==========================================
function DetectionBehavior:SearchForNewTarget()
    -- ค้นหา Players ในรัศมี
    local players = DetectionHelper.FindPlayersInRange(
        self.RootPart.Position,
        self.DetectionRange,
        self.OverlapParams
    )
    
    if #players > 0 then
        -- หา Player ที่ใกล้ที่สุด
        local nearestPlayer = DetectionHelper.FindNearestValidPlayer(
            self.RootPart.Position,
            players,
            PathfindingHelper
        )
        
        if nearestPlayer then
            print("[DetectionBehavior] Found new target:", nearestPlayer.Parent.Name)
            self.Controller.ChaseBehavior:StartChasing(nearestPlayer)
        end
    end
end

-- ==========================================
-- ✨ ตรวจสอบว่ามี Target อยู่หรือไม่
-- ==========================================
function DetectionBehavior:HasTarget()
    return self.Controller.CurrentTarget ~= nil
end

-- ==========================================
-- ✨ ดึง Target ปัจจุบัน
-- ==========================================
function DetectionBehavior:GetCurrentTarget()
    return self.Controller.CurrentTarget
end

-- ==========================================
-- ✨ ล้างข้อมูล Target
-- ==========================================
function DetectionBehavior:ClearTarget()
    self.Controller.CurrentTarget = nil
    self.OutOfRangeStartTime = nil
end

-- ==========================================
-- ✨ อัปเดต Target (เปลี่ยน Target ระหว่างไล่)
-- ==========================================
function DetectionBehavior:UpdateTarget(newTargetPart)
    if self.Controller.IsChasing then
        self.Controller.CurrentTarget = newTargetPart
        self.OutOfRangeStartTime = nil
        
        -- อัปเดต Services
        self.Controller.ChaseService:StartChase(newTargetPart)
        self.Controller.DetectionService:StartDetection(newTargetPart)
        
        print("[DetectionBehavior] Target updated to:", newTargetPart.Parent.Name)
    end
end

-- ==========================================
-- ✨ ตรวจสอบว่ากำลังตรวจจับอยู่หรือไม่
-- ==========================================
function DetectionBehavior:IsDetecting()
    return self.Controller.DetectionService:IsDetecting()
end

-- ==========================================
-- ✨ รีเซ็ต Detection State
-- ==========================================
function DetectionBehavior:Reset()
    self:ClearTarget()
    self.Controller.DetectionService:ResetDetection()
end

return DetectionBehavior