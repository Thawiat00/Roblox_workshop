-- ==========================================
-- Presentation/Controllers/SimpleWalkController.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: Main Controller - รวมทุก Behavior เข้าด้วยกัน
-- ใช้ Composition Pattern แทน God Object
-- ==========================================

local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
local SimpleEnemyRepository = require(game.ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
local SimpleWalkService = require(game.ServerScriptService.ServerLocal.Application.Services.SimpleWalkService)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

-- ==========================================
-- Services (Application Layer)
-- ==========================================
local DetectionService = require(game.ServerScriptService.ServerLocal.Application.Services.DetectionService)
local ChaseService = require(game.ServerScriptService.ServerLocal.Application.Services.ChaseService)
local PathfindingLogicService = require(game.ServerScriptService.ServerLocal.Application.Services.PathfindingLogicService)
local SpearDashService = require(game.ServerScriptService.ServerLocal.Application.Services.SpearDashService)
local SoundDetectionService = require(game.ServerScriptService.ServerLocal.Application.Services.SoundDetectionService)

-- ==========================================
-- Behaviors (Presentation Layer - ✨ ใหม่!)
-- ==========================================
local WalkBehavior = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Behaviors.WalkBehavior)
local ChaseBehavior = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Behaviors.ChaseBehavior)
local DashBehavior = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Behaviors.DashBehavior)
local SoundInvestigationBehavior = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Behaviors.SoundInvestigationBehavior)
local DetectionBehavior = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Behaviors.DetectionBehavior)

-- ==========================================
-- Handlers (Presentation Layer - ✨ ใหม่!)
-- ==========================================
local PriorityHandler = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Handlers.PriorityHandler)
local ImpactHandler = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Handlers.ImpactHandler)
local StateHandler = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.Handlers.StateHandler)

-- ==========================================
-- Roblox Services
-- ==========================================
local PathfindingService = game:GetService("PathfindingService")

local SimpleWalkController = {}
SimpleWalkController.__index = SimpleWalkController

-- ==========================================
-- Constructor: สร้าง Controller สำหรับ Enemy 1 ตัว
-- ==========================================
function SimpleWalkController.new(model)
    local self = setmetatable({}, SimpleWalkController)
    
    -- ==========================================
    -- ROBLOX INSTANCES
    -- ==========================================
    self.Model = model
    self.Humanoid = model:WaitForChild("Humanoid")
    self.RootPart = model:WaitForChild("HumanoidRootPart")
    
    -- ==========================================
    -- สร้าง Repository และ Entity
    -- ==========================================
    local repository = SimpleEnemyRepository.new()
    self.EnemyData = repository:CreateSimpleEnemy(model)
    self.EnemyData.RootPart = self.RootPart
    
    -- ==========================================
    -- สร้าง Services (Business Logic)
    -- ==========================================
    self.WalkService = SimpleWalkService.new(self.EnemyData)
    self.DetectionService = DetectionService.new(self.EnemyData)
    self.ChaseService = ChaseService.new(self.EnemyData)
    self.PathfindingLogic = PathfindingLogicService.new()
    self.DashService = SpearDashService.new(self.EnemyData)
    self.SoundDetectionService = SoundDetectionService.new(self.EnemyData, self.EnemyData.SoundData)
    
    -- ==========================================
    -- โหลด Config
    -- ==========================================
    self.WalkDuration = SimpleAIConfig.WalkDuration
    self.IdleDuration = SimpleAIConfig.IdleDuration
    self.WanderRadius = SimpleAIConfig.WanderRadius
    self.MinWanderDistance = SimpleAIConfig.MinWanderDistance or 10
    self.DetectionRange = SimpleAIConfig.DetectionRange
    self.ChaseStopRange = SimpleAIConfig.ChaseStopRange
    self.ChaseStopDelay = SimpleAIConfig.ChaseStopDelay
    
    -- Dash Config
    self.DashMinDistance = SimpleAIConfig.DashMinDistance
    self.DashMaxDistance = SimpleAIConfig.DashMaxDistance
    self.DashCheckInterval = SimpleAIConfig.DashCheckInterval
    self.RecoverDuration = SimpleAIConfig.RecoverDuration
    
    -- Impact Config
    self.ImpactForceMagnitude = SimpleAIConfig.ImpactForceMagnitude
    self.ImpactDuration = SimpleAIConfig.ImpactDuration
    self.ImpactDamage = SimpleAIConfig.ImpactDamage
    self.ImpactVisualEffect = SimpleAIConfig.ImpactVisualEffect
    
    -- Sound Config
    self.SoundRadius = SimpleAIConfig.SoundRadius
    self.SoundDuration = SimpleAIConfig.SoundDuration
    self.SoundHearingRange = SimpleAIConfig.SoundHearingRange
    self.SoundAlertDuration = SimpleAIConfig.SoundAlertDuration
    self.SoundReachThreshold = SimpleAIConfig.SoundReachThreshold
    self.SoundCheckInterval = SimpleAIConfig.SoundCheckInterval
    self.SoundVisualEffect = SimpleAIConfig.SoundVisualEffect
    
    -- ==========================================
    -- State Tracking
    -- ==========================================
    self.IsActive = true
    self.IsChasing = false
    self.IsInvestigatingSound = false
    self.CurrentTarget = nil
    self.SoundInvestigationTarget = nil
    self.OutOfRangeStartTime = nil
    
    -- ==========================================
    -- สร้าง Pathfinding
    -- ==========================================
    self.Path = PathfindingService:CreatePath({
        AgentRadius = SimpleAIConfig.AgentRadius,
        AgentHeight = SimpleAIConfig.AgentHeight,
        AgentCanJump = SimpleAIConfig.AgentCanJump
    })
    
    -- ==========================================
    -- ✨ สร้าง Behaviors (Composition Pattern)
    -- ==========================================
    self.WalkBehavior = WalkBehavior.new(self)
    self.ChaseBehavior = ChaseBehavior.new(self)
    self.DashBehavior = DashBehavior.new(self)
    self.SoundInvestigationBehavior = SoundInvestigationBehavior.new(self)
    self.DetectionBehavior = DetectionBehavior.new(self)
    
    -- ==========================================
    -- ✨ สร้าง Handlers
    -- ==========================================
    self.PriorityHandler = PriorityHandler.new(self)
    self.ImpactHandler = ImpactHandler.new(self)
    self.StateHandler = StateHandler.new(self)
    
    -- เริ่มระบบ
    self:Initialize()
    
    return self
end

-- ==========================================
-- Initialize: ตั้งค่าเริ่มต้นและเริ่ม Loop
-- ==========================================
function SimpleWalkController:Initialize()
    -- ตั้งความเร็วเริ่มต้นเป็น 0
    self.Humanoid.WalkSpeed = 0
    
    print("[Controller] ✅ Initialized:", self.Model.Name)
    
    -- ==========================================
    -- เริ่ม Loops ทั้งหมด
    -- ==========================================
    
    -- 1. Walk Loop (เดิน/หยุด)
    self.WalkBehavior:StartWalkLoop()
    
    -- 2. Detection Loop (ตรวจจับ Player)
    self.DetectionBehavior:StartDetectionLoop()
    
    -- 3. Chase Loop (เริ่มอัตโนมัติเมื่อ StartChasing ถูกเรียก)
    -- (ไม่ต้องเริ่มตรงนี้ เพราะ ChaseBehavior จะเริ่มเอง)
    
    -- 4. Dash Check Loop (ตรวจสอบโอกาสพุ่ง)
    self.DashBehavior:StartDashCheckLoop()
    
    -- 5. Sound Investigation Loop (ตรวจสอบเสียง)
    self.SoundInvestigationBehavior:StartInvestigationLoop()
    
    -- 6. Setup Impact Detection (ตั้งค่าการชน)
    self.ImpactHandler:SetupImpactDetection()
    
    print("[Controller] ✅ All systems started")
end

-- ==========================================
-- ✨ PUBLIC API: Callback เมื่อได้ยินเสียง
-- ==========================================
function SimpleWalkController:OnHearSound(soundPosition, soundSource)
    return self.SoundInvestigationBehavior:OnHearSound(soundPosition, soundSource)
end

-- ==========================================
-- ✨ PUBLIC API: เริ่มไล่ Target (Manual)
-- ==========================================
function SimpleWalkController:StartChasing(targetPart)
    self.ChaseBehavior:StartChasing(targetPart)
end

-- ==========================================
-- ✨ PUBLIC API: หยุดไล่
-- ==========================================
function SimpleWalkController:StopChasing()
    self.ChaseBehavior:StopChasing()
end

-- ==========================================
-- ✨ PUBLIC API: อัปเดต Target
-- ==========================================
function SimpleWalkController:UpdateChaseTarget(newTargetPart)
    self.DetectionBehavior:UpdateTarget(newTargetPart)
end

-- ==========================================
-- ✨ PUBLIC API: เปลี่ยน State
-- ==========================================
function SimpleWalkController:ChangeState(newState, reason)
    self.StateHandler:ChangeState(newState, reason)
end

-- ==========================================
-- ✨ PUBLIC API: ดึง Current State
-- ==========================================
function SimpleWalkController:GetCurrentState()
    return self.StateHandler:GetCurrentState()
end

-- ==========================================
-- ✨ PUBLIC API: Debug แสดงสถานะปัจจุบัน
-- ==========================================
function SimpleWalkController:PrintCurrentStatus()
    self.PriorityHandler:PrintCurrentStatus()
    self.StateHandler:PrintStateHistory()
end

-- ==========================================
-- ✨ PUBLIC API: Debug แสดง Impact Count
-- ==========================================
function SimpleWalkController:GetImpactCount()
    return self.ImpactHandler:GetImpactCount()
end

-- ==========================================
-- Reset: กลับสู่สภาพเริ่มต้น
-- ==========================================
function SimpleWalkController:Reset()
    print("[Controller] 🔄 Resetting...")
    
    -- รีเซ็ต Services
    self.WalkService:Reset()
    self.ChaseService:StopChase()
    self.DetectionService:ResetDetection()
    self.DashService:StopDash()
    self.DashService:ClearImpactRecords()
    
    -- รีเซ็ต Behaviors
    if self.IsInvestigatingSound then
        self.SoundInvestigationBehavior:StopInvestigation()
    end
    self.SoundDetectionService:CalmDown()
    self.DetectionBehavior:Reset()
    
    -- รีเซ็ต Handlers
    self.ImpactHandler:ClearImpactRecords()
    self.StateHandler:Reset()
    
    -- รีเซ็ต State Variables
    self.Humanoid.WalkSpeed = 0
    self.IsChasing = false
    self.IsInvestigatingSound = false
    self.CurrentTarget = nil
    self.SoundInvestigationTarget = nil
    self.OutOfRangeStartTime = nil
    
    print("[Controller] ✅ Reset complete")
end

-- ==========================================
-- Cleanup: ทำความสะอาดเมื่อไม่ใช้แล้ว
-- ==========================================
function SimpleWalkController:Destroy()
    print("[Controller] 🗑️ Destroying:", self.Model.Name)
    
    -- หยุดการทำงาน
    self.IsActive = false
    self.IsChasing = false
    
    -- Cleanup Behaviors
    if self.DashBehavior then
        self.DashBehavior:Destroy()
    end
    
    if self.IsInvestigatingSound then
        self.SoundInvestigationBehavior:StopInvestigation()
    end
    
    -- Cleanup Handlers
    if self.ImpactHandler then
        self.ImpactHandler:Destroy()
    end
    
    -- Cleanup Services
    self.WalkService = nil
    self.ChaseService = nil
    self.DetectionService = nil
    self.DashService = nil
    self.SoundDetectionService = nil
    
    -- Cleanup Behaviors
    self.WalkBehavior = nil
    self.ChaseBehavior = nil
    self.DashBehavior = nil
    self.SoundInvestigationBehavior = nil
    self.DetectionBehavior = nil
    
    -- Cleanup Handlers
    self.PriorityHandler = nil
    self.ImpactHandler = nil
    self.StateHandler = nil
    
    self.EnemyData = nil
    
    print("[Controller] ✅ Destroyed successfully")
end

-- ==========================================
-- ✨ BACKWARD COMPATIBILITY (เพื่อไม่ให้โค้ดเดิมเสีย)
-- ==========================================

-- เก็บ API เก่าไว้เพื่อความ Compatible
function SimpleWalkController:StartWalking()
    self.WalkBehavior:StartWalking()
end

function SimpleWalkController:PauseWalking()
    self.WalkBehavior:PauseWalking()
end

function SimpleWalkController:GetRandomPosition()
    return self.WalkBehavior:GetRandomPosition()
end

function SimpleWalkController:MoveToPosition(targetPos)
    self.WalkBehavior:MoveToPosition(targetPos)
end

return SimpleWalkController