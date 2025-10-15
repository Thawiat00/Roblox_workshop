-- ==========================================
-- Presentation/Controllers/Behaviors/WalkBehavior.lua
-- ==========================================
-- วัตถุประสงค์: จัดการพฤติกรรมการเดิน (Walk & Idle)
-- ==========================================

local PathfindingService = game:GetService("PathfindingService")
local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
local PathfindingHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.PathfindingHelper)

local WalkBehavior = {}
WalkBehavior.__index = WalkBehavior

-- ==========================================
-- Constructor
-- ==========================================
function WalkBehavior.new(controller)
    local self = setmetatable({}, WalkBehavior)
    
    self.Controller = controller
    self.EnemyData = controller.EnemyData
    self.Humanoid = controller.Humanoid
    self.RootPart = controller.RootPart
    
    self.WalkDuration = controller.WalkDuration
    self.IdleDuration = controller.IdleDuration
    self.WanderRadius = controller.WanderRadius
    self.MinWanderDistance = controller.MinWanderDistance
    
    -- สร้าง Path
    self.Path = PathfindingService:CreatePath({
        AgentRadius = controller.EnemyData.AgentRadius or 2,
        AgentHeight = controller.EnemyData.AgentHeight or 5,
        AgentCanJump = controller.EnemyData.AgentCanJump or true
    })
    
    return self
end

-- ==========================================
-- ✨ เริ่ม Walk Loop
-- ==========================================
function WalkBehavior:StartWalkLoop()
    task.spawn(function()
        while self.Controller.IsActive and self.Humanoid.Health > 0 do
            
            -- ถ้ากำลังไล่อยู่ ข้ามไป
            if not self.Controller.IsChasing then
                
                -- Phase 1: เดิน
                self:StartWalking()
                task.wait(self.WalkDuration)
                
                -- Phase 2: หยุด
                if not self.Controller.IsChasing then
                    self:PauseWalking()
                    task.wait(self.IdleDuration)
                end
            else
                task.wait(0.5)
            end
        end
        
        print("[WalkBehavior]", self.EnemyData.Model.Name, "died. Stopping.")
    end)
end

-- ==========================================
-- ✨ เริ่มเดิน
-- ==========================================
function WalkBehavior:StartWalking()
    if self.Controller.IsChasing then return end
    
    -- อัปเดต State
    self.Controller.WalkService:StartWalking()
    self.EnemyData:SetState(AIState.Walk)
    self.EnemyData.CurrentSpeed = self.EnemyData.WalkSpeed
    self.Humanoid.WalkSpeed = self.EnemyData.CurrentSpeed
    
    -- สุ่มตำแหน่งและเดินไป
    local randomPosition = self:GetRandomPosition()
    self:MoveToPosition(randomPosition)
end

-- ==========================================
-- ✨ หยุดเดิน
-- ==========================================
function WalkBehavior:PauseWalking()
    if self.Controller.WalkService then
        self.Controller.WalkService:PauseWalk()
    end
    
    if self.EnemyData then
        if self.EnemyData.SetState then
            self.EnemyData:SetState("Idle")
        else
            self.EnemyData.CurrentState = "Idle"
        end
        self.EnemyData.CurrentSpeed = 0
    end
    
    if self.Humanoid then
        self.Humanoid.WalkSpeed = 0
    end
end

-- ==========================================
-- ✨ สุ่มตำแหน่งใหม่
-- ==========================================
function WalkBehavior:GetRandomPosition()
    local currentPos = self.RootPart.Position
    
    local randomAngle = math.random() * math.pi * 2
    local randomDistance = math.random(
        self.MinWanderDistance,
        self.WanderRadius
    )
    
    local offsetX = math.cos(randomAngle) * randomDistance
    local offsetZ = math.sin(randomAngle) * randomDistance
    
    return Vector3.new(
        currentPos.X + offsetX,
        currentPos.Y,
        currentPos.Z + offsetZ
    )
end

-- ==========================================
-- ✨ เดินไปยังตำแหน่ง (ใช้ Pathfinding)
-- ==========================================
function WalkBehavior:MoveToPosition(targetPos)
    if not self.EnemyData or self.Controller.IsChasing then
        return
    end
    
    local success = pcall(function()
        self.Path:ComputeAsync(self.RootPart.Position, targetPos)
    end)
    
    if success and self.Path.Status == Enum.PathStatus.Success then
        local waypoints = self.Path:GetWaypoints()
        
        for i, waypoint in ipairs(waypoints) do
            if self.EnemyData and self.EnemyData:IsWalking() and not self.Controller.IsChasing then
                
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                
                self.Humanoid:MoveTo(waypoint.Position)
                
                local finished = false
                local moveConnection = self.Humanoid.MoveToFinished:Connect(function()
                    finished = true
                end)
                
                local timeoutStart = tick()
                repeat 
                    task.wait(0.1)
                    if self.Controller.IsChasing then break end
                until finished or (tick() - timeoutStart > 3)
                
                moveConnection:Disconnect()
            else
                break
            end
        end
    else
        -- Fallback: เดินตรงไป
        self.Humanoid:MoveTo(targetPos)
        task.wait(2)
    end
end

return WalkBehavior