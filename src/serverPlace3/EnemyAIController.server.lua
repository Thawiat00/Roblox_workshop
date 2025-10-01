local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


local enemiesFolder = workspace:WaitForChild("EnemiesFolder")
local waypointFolder = workspace:WaitForChild("WaypointsFolder")
local patrolPoints = waypointFolder:GetChildren()

local DETECT_DISTANCE = 15  -- ระยะตรวจจับผู้เล่น

local ATTACK_DISTANCE = 20  -- ระยะที่ enemy จะฆ่าผู้เล่นทันที

local function attackPlayer(player)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local humanoid = player.Character.Humanoid
		humanoid.Health = 0  -- ฆ่าทันที
	end
end


local function createAI(enemy)

    	-- ✅ ตั้ง PrimaryPart สำหรับ R15
	local humanoid = enemy:WaitForChild("Humanoid")
	local rootPart = enemy:WaitForChild("HumanoidRootPart")
	if not enemy.PrimaryPart then
		enemy.PrimaryPart = rootPart
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4
	})

	local waypoints
	local nextWaypointIndex
	local blockedConnection
	local reachedConnection

	local function disconnectConnections()
		if blockedConnection then
			blockedConnection:Disconnect()
			blockedConnection = nil
		end
		if reachedConnection then
			reachedConnection:Disconnect()
			reachedConnection = nil
		end
	end



	local function findNearestPlayer()
		local nearest
		local shortest = math.huge
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
				if dist < shortest then
					shortest = dist
					nearest = player
				end
			end
		end
		if shortest <= DETECT_DISTANCE then
			return nearest
		else
			return nil
		end
	end

local function followPath(destination)
		disconnectConnections()

		local success, errorMessage = pcall(function()
			path:ComputeAsync(rootPart.Position, destination)
		end)

		if success and path.Status == Enum.PathStatus.Success then
			waypoints = path:GetWaypoints()
			nextWaypointIndex = 2

			blockedConnection = path.Blocked:Connect(function(blockedIndex)
				if blockedIndex >= nextWaypointIndex then
					followPath(destination)
				end
			end)

			reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex <= #waypoints then
					nextWaypointIndex += 1
					if waypoints[nextWaypointIndex] and waypoints[nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then
						humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
					if waypoints[nextWaypointIndex] then
						humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
					end
				end
			end)

			if waypoints[2] then
				humanoid:MoveTo(waypoints[2].Position)
			end
		else
			warn(enemy.Name .. " failed to compute path:", errorMessage)
		end
	end

		-- 👣 Patrol Loop (เดินตาม Part ที่กำหนด)
	local function patrol()
		for _, point in ipairs(patrolPoints) do
			if not enemy.Parent then return end

			-- ถ้ามีผู้เล่นโผล่มากลางทาง → ขัดจังหวะ patrol ทันที
			local target = findNearestPlayer()
			if target then
				return
			end

			humanoid:MoveTo(point.Position)
			local reached = humanoid.MoveToFinished:Wait()

			-- เผื่อจังหวะ enemy ถูกลบระหว่างรอ
			if not reached or not enemy.Parent then
				return
			end
		end
	end

	task.spawn(function()
	while enemy.Parent do
		local target = findNearestPlayer()
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			-- ไล่ผู้เล่น
			followPath(target.Character.HumanoidRootPart.Position)

			-- ✅ เช็คถ้าเข้าใกล้พอ ให้โจมตี/ฆ่าทันที
			local distance = (target.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
			if distance <= ATTACK_DISTANCE then
				attackPlayer(target)
			end

			task.wait(0.2)
		else
			-- ไม่มีผู้เล่นใกล้ → เดิน Patrol
			patrol()
		end
	end

	-- ล้าง connection เมื่อศัตรูถูกลบ
	disconnectConnections()
	end)
end

-- 🧍 สร้าง AI ให้ Enemy ที่มีอยู่แล้ว
for _, enemy in pairs(enemiesFolder:GetChildren()) do
	if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
		createAI(enemy)
	end
end


-- 🧠 Enemy ที่ spawn ใหม่
enemiesFolder.ChildAdded:Connect(function(enemy)
	task.wait(0.1)
	if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
		createAI(enemy)
	end
end)
