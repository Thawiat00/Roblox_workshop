-- 📦 ModuleScript: NPCAIModule
-- วางใน: ServerScriptService > NPCAIModule
-- หน้าที่: AI NPC ไล่ล่า / Patrol / Attack แบบ Smooth

local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local NPCAIModule = {}

local DETECT_DISTANCE = 50
local ATTACK_DISTANCE = 5
local PATH_UPDATE_INTERVAL = 0.3  -- รีคำนวณ path ทุก 0.3 วินาที

-- 👀 โฟลเดอร์ศัตรู
local enemyFolder = workspace:WaitForChild("puppet_enemy")

-- ฟังก์ชันสร้าง path layer 2 and push to layer 3
local function createPath(npc, targetPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 2
    })
    path:ComputeAsync(npc.PrimaryPart.Position, targetPos)
    if path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    else
        return nil
    end
end

-- ฟังก์ชัน attack (ตัวอย่าง)
-- ฟังก์ชันสร้าง layer 2 and push to layer 3
local function attackPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("Humanoid") then
        print("💀 Attack:", player.Name)
        player.Character.Humanoid:TakeDamage(10) -- ปรับตามต้องการ
    end
end

-- ฟังก์ชันหา player ใกล้ NPC
-- ฟังก์ชันสร้าง layer 2 and push to layer 3
local function findNearestPlayer(npc, distance)
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

-- ฟังก์ชันสร้าง AI  for layer 4
function NPCAIModule.createAI(npc, patrolPoints)
    local humanoid = npc:WaitForChild("Humanoid")
    local hrp = npc:WaitForChild("HumanoidRootPart")
    if not npc.PrimaryPart then npc.PrimaryPart = hrp end

    local patrolIndex = 1
    local targetPlayer = nil
    local waypoints = {}
    local wpIndex = 1
    local pathTimer = 0

    RunService.Heartbeat:Connect(function(deltaTime)
        if not npc.Parent or humanoid.Health <= 0 then return end

        -- หา player ใกล้ที่สุด
        targetPlayer = findNearestPlayer(npc, DETECT_DISTANCE)
        local targetPos = nil
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPos = targetPlayer.Character.HumanoidRootPart.Position
        elseif #patrolPoints > 0 then
            targetPos = patrolPoints[patrolIndex]
        else
            return
        end

        pathTimer = pathTimer + deltaTime

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
        if targetPlayer and (hrp.Position - targetPos).Magnitude <= ATTACK_DISTANCE then
            attackPlayer(targetPlayer)
        end

        -- Patrol mode
        if not targetPlayer and #patrolPoints > 0 and (hrp.Position - patrolPoints[patrolIndex]).Magnitude < 2 then
            patrolIndex = patrolIndex % #patrolPoints + 1
        end
    end)
end



-- 🟢 เริ่ม AI สำหรับทุก NPC ใน puppet_enemy
-- ทำงาน บน layer 5 
for _, npc in pairs(enemyFolder:GetChildren()) do
    NPCAIModule.createAI(npc, {}) -- ใส่ patrolPoints ถ้ามี
end

-- 🔔 ถ้ามี NPC ใหม่เพิ่มเข้ามา
-- ทำงาน บน layer 5 
enemyFolder.ChildAdded:Connect(function(child)
    task.wait(1)
    NPCAIModule.createAI(child, {})
end)

return NPCAIModule
