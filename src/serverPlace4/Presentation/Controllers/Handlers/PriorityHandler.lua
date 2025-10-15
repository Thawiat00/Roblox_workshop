-- ==========================================
-- Presentation/Controllers/Handlers/PriorityHandler.lua
-- ==========================================
-- วัตถุประสงค์: จัดการ Behavior Priority System
-- ความสำคัญ (สูง → ต่ำ):
-- 1. Dash/Recover
-- 2. Chase (มี target ชัดเจน)
-- 3. Sound Investigation (ได้ยินเสียง)
-- 4. Detection (กำลังตรวจจับ)
-- 5. Walk (เดินสำรวจปกติ)
-- ==========================================

local PriorityHandler = {}
PriorityHandler.__index = PriorityHandler

-- ==========================================
-- Constructor
-- ==========================================
function PriorityHandler.new(controller)
    local self = setmetatable({}, PriorityHandler)
    
    self.Controller = controller
    
    return self
end

-- ==========================================
-- ✨ ดึง Current Behavior Priority
-- ==========================================
function PriorityHandler:GetCurrentBehaviorPriority()
    -- Priority 1: Dash/Recover (สูงสุด)
    if self.Controller.DashService:IsDashing() or self.Controller.DashService:IsRecovering() then
        return 1, "Dash/Recover"
    end
    
    -- Priority 2: Chase (มี target)
    if self.Controller.IsChasing and self.Controller.CurrentTarget then
        return 2, "Chase"
    end
    
    -- Priority 3: Sound Investigation
    if self.Controller.IsInvestigatingSound then
        return 3, "Sound Investigation"
    end
    
    -- Priority 4: Detection (กำลังตรวจจับแต่ยังไม่ได้ไล่)
    if self.Controller.DetectionService:IsDetecting() then
        return 4, "Detection"
    end
    
    -- Priority 5: Walk (ต่ำสุด)
    return 5, "Walk"
end

-- ==========================================
-- ✨ ตรวจสอบว่าสามารถเปลี่ยนพฤติกรรมได้หรือไม่
-- ==========================================
function PriorityHandler:CanInterruptForBehavior(newPriority)
    local currentPriority, currentBehavior = self:GetCurrentBehaviorPriority()
    
    -- ถ้า priority ใหม่สูงกว่า = ขัดจังหวะได้
    if newPriority < currentPriority then
        print("[PriorityHandler] Interrupting", currentBehavior, "for new behavior (priority:", newPriority, ")")
        return true
    end
    
    return false
end

-- ==========================================
-- ✨ Debug: แสดงสถานะปัจจุบัน
-- ==========================================
function PriorityHandler:PrintCurrentStatus()
    local priority, behavior = self:GetCurrentBehaviorPriority()
    
    print("===========================================")
    print("[PriorityHandler Status]", self.Controller.Model.Name)
    print("  • Current Behavior:", behavior)
    print("  • Priority:", priority)
    print("  • IsChasing:", self.Controller.IsChasing)
    print("  • IsInvestigatingSound:", self.Controller.IsInvestigatingSound)
    print("  • IsDashing:", self.Controller.DashService:IsDashing())
    print("  • CurrentSpeed:", self.Controller.Humanoid.WalkSpeed)
    
    if self.Controller.CurrentTarget then
        print("  • Chase Target:", self.Controller.CurrentTarget.Parent and self.Controller.CurrentTarget.Parent.Name or "Unknown")
    end
    
    if self.Controller.SoundInvestigationTarget then
        print("  • Sound Target:", self.Controller.SoundInvestigationTarget)
    end
    
    print("===========================================")
end

return PriorityHandler