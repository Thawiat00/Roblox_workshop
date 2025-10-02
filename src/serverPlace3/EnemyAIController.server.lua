-- Services
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local enemiesFolder = workspace:WaitForChild("EnemiesFolder")
local waypointFolder = workspace:WaitForChild("WaypointsFolder")

local meshMaze = workspace:FindFirstChild("mesh_maze")

if meshMaze and meshMaze:IsA("MeshPart") then
    print("MeshPart Name:", meshMaze.Name)
    print("Material:", meshMaze.Material)
    print("CanCollide:", meshMaze.CanCollide)
else
    warn("ไม่พบ MeshPart ชื่อ mesh_maze")
end


-- เก็บตำแหน่ง Vector3 ของ waypoint
local patrolPoints = {}
for _, part in ipairs(waypointFolder:GetChildren()) do
    table.insert(patrolPoints, part.Position)
    part:Destroy() -- ลบ Part หลังเก็บตำแหน่ง
end

local DETECT_DISTANCE = 30
local ATTACK_DISTANCE = 5

local function attackPlayer(player)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.Health = 0
	end
end

-- 🔹 ฟังก์ชันตั้งค่า Agent อัตโนมัติ R6/R15
local function getAgentParams(humanoid)
	local agentRadius, agentHeight = 2, 5
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		agentRadius, agentHeight = 2.5, 6
	end
	return agentRadius, agentHeight
end

-- 🔹 สร้าง Path
local function createPath(npc, destination)
	local humanoid = npc:FindFirstChild("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return nil end

	local agentRadius, agentHeight = getAgentParams(humanoid)

	local path = PathfindingService:CreatePath({
		AgentRadius = agentRadius,
		AgentHeight = agentHeight,
		AgentCanJump = true,
		AgentCanClimb = false,
		WaypointSpacing = 4,
		Costs = { Ice = math.huge, Wood = 5 }
	})

	local success, err = pcall(function()
		path:ComputeAsync(hrp.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		return path
	else
		warn("Path cannot be computed for "..npc.Name..": "..tostring(err))
		return nil
	end
end

-- 🔹 เดินตาม Path
local function moveAlongPath(npc, path)
	local humanoid = npc:FindFirstChild("Humanoid")
	if not humanoid then return false end
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local waypoints = path:GetWaypoints()
	for i, wp in ipairs(waypoints) do
		if wp.Action == Enum.PathWaypointAction.Jump then
			humanoid:MoveTo(wp.Position)
			humanoid.Jump = true
		else
			humanoid:MoveTo(wp.Position)
		end
		local success = humanoid.MoveToFinished:Wait()
		if not success then return false end
	end
	return true
end

-- 🔹 หาผู้เล่นใกล้ที่สุด
local function findNearestPlayer(npc, detectDistance)
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local nearest, shortest = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist < shortest and dist <= detectDistance then
				shortest = dist
				nearest = player
			end
		end
	end
	return nearest
end

-- 🔹 AI Loop สำหรับ NPC
local function createAI(npc)
	local humanoid = npc:WaitForChild("Humanoid")
	local hrp = npc:WaitForChild("HumanoidRootPart")
	if not npc.PrimaryPart then npc.PrimaryPart = hrp end

	task.spawn(function()
		local patrolIndex = 1
		while npc.Parent do
			local targetPlayer = findNearestPlayer(npc, DETECT_DISTANCE)

			if targetPlayer then
				-- Chase player
				while targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and (targetPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude <= DETECT_DISTANCE and npc.Parent do
					local path = createPath(npc, targetPlayer.Character.HumanoidRootPart.Position)
					if path then
						moveAlongPath(npc, path)
					end
					if (targetPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude <= ATTACK_DISTANCE then
						attackPlayer(targetPlayer)
						break
					end
					task.wait(0.5)
					targetPlayer = findNearestPlayer(npc, DETECT_DISTANCE)
				end
			else
				-- Patrol
				local point = patrolPoints[patrolIndex]
				if point then
					local path = createPath(npc, point)
					if path then
						moveAlongPath(npc, path)
					end
					patrolIndex = patrolIndex % #patrolPoints + 1
				end
				task.wait(0.1)
			end
		end
	end)
end

-- 🔹 เริ่ม AI สำหรับ NPC เดิม
for _, enemy in pairs(enemiesFolder:GetChildren()) do
	if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
		createAI(enemy)
	end
end

-- 🔹 AI สำหรับ NPC ใหม่
enemiesFolder.ChildAdded:Connect(function(enemy)
	task.wait(0.1)
	if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
		createAI(enemy)
	end
end)
