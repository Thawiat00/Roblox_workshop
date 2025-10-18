-- ==========================================
-- Presentation/Controllers/Behaviors/ChaseBehavior.lua
-- ==========================================
-- วัตถุประสงค์: จัดการพฤติกรรมการไล่ตาม Player
-- ==========================================

local PathfindingHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.PathfindingHelper)
local DetectionHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.DetectionHelper)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local PathfindingService = game:GetService("PathfindingService")

local RunService = game:GetService("RunService")

local ChaseBehavior = {}
ChaseBehavior.__index = ChaseBehavior

-- ==========================================
-- Constructor
-- ==========================================
function ChaseBehavior.new(controller)
    local self = setmetatable({}, ChaseBehavior)
    
    self.Controller = controller
    self.EnemyData = controller.EnemyData
    self.Humanoid = controller.Humanoid
    self.RootPart = controller.RootPart
    self.Path = controller.Path
    
    self.DetectionRange = controller.DetectionRange
    self.ChaseStopRange = controller.ChaseStopRange
    self.ChaseStopDelay = controller.ChaseStopDelay
    
    self.OverlapParams = DetectionHelper.CreateOverlapParams(controller.Model)
    self.OutOfRangeStartTime = nil
    
    return self
end

-- ==========================================
-- ✨ เริ่ม Detection Loop
-- ==========================================
function ChaseBehavior:StartDetectionLoop()
    task.spawn(function()
        while self.Controller.IsActive and self.Humanoid.Health > 0 do
            
            if self.Controller.IsChasing and self.Controller.CurrentTarget then
                -- ตรวจสอบว่า target ยังมีชีวิต
                if not DetectionHelper.IsTargetValid(self.Controller.CurrentTarget) then
                    print("[ChaseBehavior] Target invalid, stopping chase")
                    self:StopChasing()
                    task.wait(SimpleAIConfig.DetectionCheckInterval)
                    continue
                end
                
                -- ตรวจสอบระยะห่าง
                local isOutOfRange = DetectionHelper.IsTargetOutOfRange(
                    self.RootPart.Position,
                    self.Controller.CurrentTarget,
                    self.ChaseStopRange
                )
                
                if isOutOfRange then
                    if not self.OutOfRangeStartTime then
                        self.OutOfRangeStartTime = tick()
                        print("[ChaseBehavior] Target out of range, waiting...")
                    else
                        local outOfRangeTime = tick() - self.OutOfRangeStartTime
                        if outOfRangeTime >= self.ChaseStopDelay then
                            print("[ChaseBehavior] Target too far, stopping")
                            self:StopChasing()
                        end
                    end
                else
                    self.OutOfRangeStartTime = nil
                end
                
            else
                -- ค้นหา Player ใหม่
                local players = DetectionHelper.FindPlayersInRange(
                    self.RootPart.Position,
                    self.DetectionRange,
                    self.OverlapParams
                )
                
                if #players > 0 then
                    local nearestPlayer = DetectionHelper.FindNearestValidPlayer(
                        self.RootPart.Position,
                        players,
                        PathfindingHelper
                    )
                    
                    if nearestPlayer then
                        self:StartChasing(nearestPlayer)
                    end
                end
            end
            
            task.wait(SimpleAIConfig.DetectionCheckInterval)
        end
    end)
end

-- ==========================================
-- ✨ เริ่มไล่
-- ==========================================
function ChaseBehavior:StartChasing(targetPart)
    if self.Controller.IsChasing then
        self.Controller.CurrentTarget = targetPart
        return
    end
    
    self.Controller.IsChasing = true
    self.Controller.CurrentTarget = targetPart
    self.OutOfRangeStartTime = nil
    
    -- อัปเดต Services
    self.Controller.DetectionService:StartDetection(targetPart)
    self.Controller.ChaseService:StartChase(targetPart)
    
    -- เพิ่มความเร็ว
    self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
    
    print("[ChaseBehavior] Started chasing:", targetPart.Parent.Name)
    
    task.spawn(function()
        self:ChaseLoop(targetPart)
    end)
end



local function createPath(npc, targetPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = SimpleAIConfig.AgentRadius,
        AgentHeight = SimpleAIConfig.AgentHeight,
        AgentCanJump = SimpleAIConfig.AgentCanJump,
        WaypointSpacing = SimpleAIConfig.WaypointSpacing
    })
    path:ComputeAsync(npc.PrimaryPart.Position, targetPos)
    if path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    else
        return nil
    end
end



function ChaseBehavior:findNearestPlayer(npc, distance)
    local nearest = nil
    local nearestDist = math.huge
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (npc.PrimaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if dist < distance and dist < nearestDist then
                nearest = player
                nearestDist = dist
            end
        end
    end
    return nearest
end



function ChaseBehavior:ChaseLoop(npc)

    while self.Controller.IsChasing and self.Humanoid.Health > 0 do
    
    local humanoid = npc:WaitForChild("Humanoid")
    local hrp = npc:WaitForChild("HumanoidRootPart")
    if not npc.PrimaryPart then npc.PrimaryPart = hrp end

                -- หยุด Chase ถ้ากำลัง Dash/Recover
        if self.Controller.DashService:IsDashing() or self.Controller.DashService:IsRecovering() then
            task.wait(0.1)
            continue
        end
        
        if not self.Controller.CurrentTarget or not self.Controller.CurrentTarget.Parent then
            self:StopChasing()
            break
        end


  --  local patrolIndex = 1
    local targetPlayer = nil
    local waypoints = {}
    local wpIndex = 1
    local pathTimer = 0

        RunService.Heartbeat:Connect(function(deltaTime)
        if not npc.Parent or humanoid.Health <= 0 then return end

        -- หา player ใกล้ที่สุด
        local DETECT_DISTANCE = SimpleAIConfig.DetectionRange

        targetPlayer = self.findNearestPlayer(npc, DETECT_DISTANCE)
        local targetPos = nil
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPos = targetPlayer.Character.HumanoidRootPart.Position
     --   elseif #patrolPoints > 0 then
     --       targetPos = patrolPoints[patrolIndex]
        else
            return
        end

        pathTimer = pathTimer + deltaTime

        local PATH_UPDATE_INTERVAL = SimpleAIConfig.PathUpdateInterval
        -- รีคำนวณ path ทุก PATH_UPDATE_INTERVAL
        if pathTimer >= PATH_UPDATE_INTERVAL then
            pathTimer = 0
            local newWaypoints = createPath(npc, targetPos)
            if newWaypoints then
                waypoints = newWaypoints
                wpIndex = 1
            else
                -- fallback เดินตรงไป target
                humanoid:MoveTo(targetPos)
            end
        end

        -- เดินไป waypoint ปัจจุบัน
        if waypoints[wpIndex] then
            local wp = waypoints[wpIndex]
            humanoid:MoveTo(wp.Position)
            if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            if (hrp.Position - wp.Position).Magnitude < 3 then
                wpIndex = wpIndex + 1
            end
        end

        -- ถ้าใกล้ player → โจมตี
       -- if targetPlayer and (hrp.Position - targetPos).Magnitude <= ATTACK_DISTANCE then
       --     attackPlayer(targetPlayer)
       -- end

        -- Patrol mode
      --  if not targetPlayer and #patrolPoints > 0 and (hrp.Position - patrolPoints[patrolIndex]).Magnitude < 2 then
      --      patrolIndex = patrolIndex % #patrolPoints + 1
      --  end
        end)

    end
end

-- ==========================================
-- ✨ Chase Loop
-- ==========================================
function ChaseBehavior:ChaseLoop_1(targetPart)
    while self.Controller.IsChasing and self.Humanoid.Health > 0 do
        
        -- หยุด Chase ถ้ากำลัง Dash/Recover
        if self.Controller.DashService:IsDashing() or self.Controller.DashService:IsRecovering() then
            task.wait(0.1)
            continue
        end
        
        if not self.Controller.CurrentTarget or not self.Controller.CurrentTarget.Parent then
            self:StopChasing()
            break
        end
        
        -- คำนวณเส้นทาง
        local success, waypoints = PathfindingHelper.ComputePath(
            self.Path,
            self.RootPart.Position,
            self.Controller.CurrentTarget.Position
        )
        
        if success and #waypoints > 1 then
            local nextWaypoint = waypoints[2]
            
            if PathfindingHelper.ShouldJump(nextWaypoint) then
                self.Controller.ChaseService:SetJumping()
                self.Humanoid.Jump = true
                task.wait(0.3)
                self.Controller.ChaseService:ResumeChase()
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
            until moveFinished or not self.Controller.IsChasing or self.Controller.DashService:IsDashing()
            
            moveConnection:Disconnect()
        else
            warn("[ChaseBehavior] Path failed, moving directly")
            self.Humanoid:MoveTo(self.Controller.CurrentTarget.Position)
            task.wait(0.5)
        end
        
        task.wait(SimpleAIConfig.ChaseUpdateInterval)
    end
end

-- ==========================================
-- ✨ หยุดไล่
-- ==========================================
function ChaseBehavior:StopChasing()
    if not self.Controller.IsChasing then return end
    
    self.Controller.IsChasing = false
    self.Controller.CurrentTarget = nil
    self.OutOfRangeStartTime = nil
    
    -- หยุด Dash
    if self.Controller.DashService:IsDashing() then
        self.Controller.DashService:StopDash()
    end
    
    -- ล้างรายชื่อ Impact
    self.Controller.DashService:ClearImpactRecords()
    
    -- หยุด Services
    self.Controller.ChaseService:StopChase()
    self.Controller.DetectionService:StopDetection()
    
    self.Humanoid.WalkSpeed = 0
    
    print("[ChaseBehavior] Stopped chasing")
end

return ChaseBehavior