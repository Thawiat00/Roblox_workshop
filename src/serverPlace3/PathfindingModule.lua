-- 📦 ModuleScript: PathfindingModule
-- วางใน: ServerScriptService > PathfindingModule
-- หน้าที่: สร้าง Path และควบคุมการเดินของ NPC

local PathfindingModule = {}

local PathfindingService = game:GetService("PathfindingService")

-- 🔹 คำนวณขนาด Agent ตามประเภท Rig (R6/R15)
function PathfindingModule.getAgentParams(humanoid)
	local agentRadius, agentHeight = 2, 5
	
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		agentRadius, agentHeight = 2.5, 6
	end
	
	return agentRadius, agentHeight
end

-- 🔹 สร้าง Path จากตำแหน่ง NPC ไปยังจุดหมาย
function PathfindingModule.createPath(npc, destination)
	local humanoid = npc:FindFirstChild("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not hrp then
		return nil
	end
	
	-- ตรวจสอบว่า destination ไม่ใช่ nil
	if not destination then
		warn("⚠️ Destination is nil for " .. npc.Name)
		return nil
	end
	
	local agentRadius, agentHeight = PathfindingModule.getAgentParams(humanoid)
	
	local path = PathfindingService:CreatePath({
		AgentRadius = agentRadius,
		AgentHeight = agentHeight,
		AgentCanJump = true,
		AgentCanClimb = false,
		WaypointSpacing = 3,  -- ลดระยะห่างระหว่าง waypoint
		Costs = {
			Water = math.huge,  -- หลีกเลี่ยงน้ำ
			Ice = math.huge,    -- หลีกเลี่ยงน้ำแข็ง
		}
	})
	
	local success, err = pcall(function()
		path:ComputeAsync(hrp.Position, destination)
	end)
	
	if success and path.Status == Enum.PathStatus.Success then
		return path
	else
		-- ไม่แสดง warning เพราะอาจเกิดบ่อยตอนไล่
		return nil
	end
end

-- 🔹 เดินตาม Waypoints ของ Path
function PathfindingModule.moveAlongPath(npc, path)
	local humanoid = npc:FindFirstChild("Humanoid")
	if not humanoid then return false end
	
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	
	local waypoints = path:GetWaypoints()
	
	for i, wp in ipairs(waypoints) do
		-- ข้าม waypoint แรก (ตำแหน่งปัจจุบัน)
		if i == 1 then
			continue
		end
		
		-- ถ้า Waypoint ต้องกระโดด
		if wp.Action == Enum.PathWaypointAction.Jump then
			humanoid:MoveTo(wp.Position)
			humanoid.Jump = true
		else
			humanoid:MoveTo(wp.Position)
		end
		
		-- รอให้ถึง waypoint หรือ timeout
		local timeout = 3  -- รอสูงสุด 3 วินาที
		local startTime = tick()
		
		while (tick() - startTime) < timeout do
			if not npc.Parent or humanoid.Health <= 0 then
				return false
			end
			
			-- ตรวจสอบว่าถึง waypoint แล้วหรือยัง
			local distance = (hrp.Position - wp.Position).Magnitude
			if distance < 4 then
				break
			end
			
			task.wait(0.1)
		end
		
		-- ถ้า timeout ให้ข้ามไป waypoint ถัดไป
	end
	
	return true
end

-- 🔹 ฟังก์ชันเดินตรงไปยังเป้าหมาย (ใช้เมื่อ Path ไม่ทำงาน)
function PathfindingModule.moveDirectly(npc, destination)
	local humanoid = npc:FindFirstChild("Humanoid")
	if not humanoid then return false end
	
	humanoid:MoveTo(destination)
	
	local timeout = 5
	local startTime = tick()
	
	while (tick() - startTime) < timeout do
		if not npc.Parent then return false end
		
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - destination).Magnitude < 5 then
			return true
		end
		
		task.wait(0.1)
	end
	
	return false
end

return PathfindingModule