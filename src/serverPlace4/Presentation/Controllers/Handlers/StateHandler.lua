-- ==========================================
-- Presentation/Controllers/Handlers/StateHandler.lua
-- ==========================================
-- วัตถุประสงค์: จัดการ State Transitions (Idle/Walk/Chase/Dash/Recover)
-- รวบรวม State Logic ทั้งหมดไว้ที่นี่
-- ==========================================

local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)

local StateHandler = {}
StateHandler.__index = StateHandler

-- ==========================================
-- Constructor
-- ==========================================
function StateHandler.new(controller)
    local self = setmetatable({}, StateHandler)
    
    self.Controller = controller
    self.EnemyData = controller.EnemyData
    self.Humanoid = controller.Humanoid
    
    -- เก็บ State History (สำหรับ Debug)
    self.StateHistory = {}
    self.MaxHistorySize = 10
    
    return self
end

-- ==========================================
-- ✨ เปลี่ยน State (Main Method)
-- ==========================================
function StateHandler:ChangeState(newState, reason)
    local oldState = self:GetCurrentState()
    
    -- ตรวจสอบว่าเปลี่ยน State จริงหรือไม่
    if oldState == newState then
        return -- ไม่ต้องเปลี่ยน
    end
    
    -- ตรวจสอบว่า Transition นี้ถูกต้องหรือไม่
    if not self:IsValidTransition(oldState, newState) then
        warn("[StateHandler] Invalid transition:", oldState, "->", newState)
        return
    end
    
    -- บันทึก State History
    self:RecordStateChange(oldState, newState, reason)
    
    -- เรียก Exit Handler ของ State เก่า
    self:OnExitState(oldState)
    
    -- อัปเดต State
    self.EnemyData:SetState(newState)
    
    -- เรียก Enter Handler ของ State ใหม่
    self:OnEnterState(newState)
    
    print("[StateHandler] State changed:", oldState, "->", newState, "|", reason or "")
end

-- ==========================================
-- ✨ ตรวจสอบว่า State Transition ถูกต้องหรือไม่
-- ==========================================
function StateHandler:IsValidTransition(fromState, toState)
    -- กำหนด Valid Transitions
    local validTransitions = {
        [AIState.Idle] = {AIState.Walk, AIState.Chase, AIState.Investigating},
        [AIState.Walk] = {AIState.Idle, AIState.Chase, AIState.Investigating},
        [AIState.Chase] = {AIState.Idle, AIState.Walk, AIState.Dashing, AIState.Investigating},
        [AIState.Dashing] = {AIState.Recovering, AIState.Chase, AIState.Idle},
        [AIState.Recovering] = {AIState.Chase, AIState.Idle},
        [AIState.Investigating] = {AIState.Idle, AIState.Walk, AIState.Chase},
    }
    
    local allowedStates = validTransitions[fromState]
    if not allowedStates then
        return false
    end
    
    for _, state in ipairs(allowedStates) do
        if state == toState then
            return true
        end
    end
    
    return false
end

-- ==========================================
-- ✨ Enter Handler: เมื่อเข้าสู่ State ใหม่
-- ==========================================
function StateHandler:OnEnterState(state)
    if state == AIState.Idle then
        self.Humanoid.WalkSpeed = 0
        
    elseif state == AIState.Walk then
        self.Humanoid.WalkSpeed = self.EnemyData.WalkSpeed
        
    elseif state == AIState.Chase then
        self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
        
    elseif state == AIState.Dashing then
        self.Humanoid.WalkSpeed = self.EnemyData.SpearSpeed
        
    elseif state == AIState.Recovering then
        self.Humanoid.WalkSpeed = 0
        
    elseif state == AIState.Investigating then
        self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
    end
    
    print("[StateHandler] Entered state:", state, "| Speed:", self.Humanoid.WalkSpeed)
end

-- ==========================================
-- ✨ Exit Handler: เมื่อออกจาก State เก่า
-- ==========================================
function StateHandler:OnExitState(state)
    -- Cleanup Logic สำหรับแต่ละ State
    if state == AIState.Dashing then
        -- ล้างรายชื่อ Player ที่ชนแล้ว
        if self.Controller.ImpactHandler then
            self.Controller.ImpactHandler:ClearImpactRecords()
        end
        
    elseif state == AIState.Chase then
        -- รีเซ็ต Out of Range Timer
        self.Controller.OutOfRangeStartTime = nil
    end
    
    print("[StateHandler] Exited state:", state)
end

-- ==========================================
-- ✨ ดึง Current State
-- ==========================================
function StateHandler:GetCurrentState()
    return self.EnemyData.CurrentState or AIState.Idle
end

-- ==========================================
-- ✨ ตรวจสอบว่าอยู่ใน State นี้หรือไม่
-- ==========================================
function StateHandler:IsInState(state)
    return self:GetCurrentState() == state
end

-- ==========================================
-- ✨ บันทึก State History
-- ==========================================
function StateHandler:RecordStateChange(fromState, toState, reason)
    local record = {
        timestamp = tick(),
        from = fromState,
        to = toState,
        reason = reason or "Unknown"
    }
    
    table.insert(self.StateHistory, record)
    
    -- จำกัดขนาด History
    if #self.StateHistory > self.MaxHistorySize then
        table.remove(self.StateHistory, 1)
    end
end

-- ==========================================
-- ✨ แสดง State History (Debug)
-- ==========================================
function StateHandler:PrintStateHistory()
    print("===========================================")
    print("[StateHandler] State History:")
    
    for i, record in ipairs(self.StateHistory) do
        print(string.format(
            "  %d. %.2fs | %s -> %s | %s",
            i,
            record.timestamp,
            record.from,
            record.to,
            record.reason
        ))
    end
    
    print("===========================================")
end

-- ==========================================
-- ✨ ล้าง State History
-- ==========================================
function StateHandler:ClearHistory()
    self.StateHistory = {}
end

-- ==========================================
-- ✨ รีเซ็ต State
-- ==========================================
function StateHandler:Reset()
    self:ChangeState(AIState.Idle, "Reset")
    self:ClearHistory()
end

return StateHandler