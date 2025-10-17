--file New_PathfindingLogicService.lua


local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local NPCAIModule = {}

local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local DETECT_DISTANCE = SimpleAIConfig.DetectionRange
local ATTACK_DISTANCE = SimpleAIConfig.AttackDistance
local PATH_UPDATE_INTERVAL = SimpleAIConfig.PathUpdateInterval  -- รีคำนวณ path ทุก 0.3 วินาที

local TargetDetectionService = require(game.ServerScriptService.ServerLocal.Application.Services.TargetDetectionService)


local New_PathfindingLogicService = {}
New_PathfindingLogicService.__index = New_PathfindingLogicService


-- ฟังก์ชันสร้าง new
function New_PathfindingLogicService.new()
    local self = setmetatable({}, New_PathfindingLogicService)
    self.AgentRadius = SimpleAIConfig.AgentRadius  or 2
    self.AgentHeight = SimpleAIConfig.AgentHeight or 5
    self.AgentCanJump = SimpleAIConfig.AgentCanJump ~= false
    self.WaypointSpacing = SimpleAIConfig.WaypointSpacing or 2


    return self
end



-- ฟังก์ชันสร้าง createPath
function New_PathfindingLogicService:createPath(npc, targetPos)

    local path = PathfindingService:CreatePath({
        AgentRadius = SimpleAIConfig.AgentRadius,
        AgentHeight = SimpleAIConfig.AgentHeight,

        SimpleAIConfig.AgentCanJump == true,
        AgentCanJump =SimpleAIConfig.AgentCanJump,

        WaypointSpacing = SimpleAIConfig.WaypointSpacing

    })
    path:ComputeAsync(npc.PrimaryPart.Position, targetPos)
    if path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    else
        return nil
    end
end

    

-- ฟังก์ชันหา player ใกล้ NPC
 function New_PathfindingLogicService:findNearestPlayer(npc, distance)
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



-- ฟังก์ชันสร้าง AI
-- Layer 4: Presentation / Controller
function New_PathfindingLogicService:createAI(enemyData)
    local npc = enemyData.Model
    local humanoid = npc:WaitForChild("Humanoid")
    local hrp = npc:WaitForChild("HumanoidRootPart")

    RunService.Heartbeat:Connect(function(deltaTime)
        if not npc.Parent or humanoid.Health <= 0 then return end

        -- ใช้ค่าจาก Core (enemyData) แทน local variables
        local targetPlayer = enemyData.TargetPlayer
        local patrolIndex = enemyData.PatrolIndex
        local patrolPoints = enemyData.PatrolPoints
        local waypoints = enemyData.Waypoints
        local wpIndex = enemyData.WaypointIndex
        local pathTimer = enemyData.PathTimer

        -- คำนวณ path
        pathTimer = pathTimer + deltaTime
        if pathTimer >= enemyData.PathUpdateInterval then
            pathTimer = 0
            local targetPos = targetPlayer and targetPlayer.Character.HumanoidRootPart.Position or patrolPoints[patrolIndex]
            local newWaypoints = self.Create(npc, targetPos)
            if newWaypoints then
                enemyData.Waypoints = newWaypoints
                enemyData.WaypointIndex = 1
            else
                humanoid:MoveTo(targetPos)
            end
        end

        -- อัปเดต Core data
        enemyData.PathTimer = pathTimer
    end)
end




return  New_PathfindingLogicService