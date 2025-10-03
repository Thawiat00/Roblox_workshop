-- 📦 ModuleScript: PlayerDetectionModule
-- วางใน: ServerScriptService > PlayerDetectionModule
-- หน้าที่: ค้นหาผู้เล่นใกล้ที่สุด และจัดการการโจมตี

local PlayerDetectionModule = {}

local Players = game:GetService("Players")

-- 🔹 หาผู้เล่นที่ใกล้ที่สุดภายในระยะที่กำหนด
function PlayerDetectionModule.findNearestPlayer(npc, detectDistance)
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	
	local nearest = nil
	local shortest = math.huge
	
	for _, player in ipairs(Players:GetPlayers()) do
		-- ตรวจสอบว่า player มี character และยังมีชีวิตอยู่
		if player.Character then
			local playerHrp = player.Character:FindFirstChild("HumanoidRootPart")
			local playerHumanoid = player.Character:FindFirstChild("Humanoid")
			
			if playerHrp and playerHumanoid and playerHumanoid.Health > 0 then
				local dist = (playerHrp.Position - hrp.Position).Magnitude
				
				if dist < shortest and dist <= detectDistance then
					shortest = dist
					nearest = player
				end
			end
		end
	end
	
	-- แสดงข้อมูล debug
	if nearest then
		print("🔍 " .. npc.Name .. " เจอ " .. nearest.Name .. " ห่าง " .. math.floor(shortest) .. " studs")
	end
	
	return nearest
end

-- 🔹 โจมตีผู้เล่น (ตั้งค่า Health = 0)
function PlayerDetectionModule.attackPlayer(player)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local humanoid = player.Character.Humanoid
		
		if humanoid.Health > 0 then
			humanoid.Health = 0
			print("💀 " .. player.Name .. " ถูกโจมตี!")
			return true
		end
	end
	
	return false
end

-- 🔹 คำนวณระยะห่างระหว่าง NPC กับผู้เล่น
function PlayerDetectionModule.getDistanceToPlayer(npc, player)
	local npcHrp = npc:FindFirstChild("HumanoidRootPart")
	
	if not player or not player.Character then
		return math.huge
	end
	
	local playerHrp = player.Character:FindFirstChild("HumanoidRootPart")
	
	if npcHrp and playerHrp then
		return (playerHrp.Position - npcHrp.Position).Magnitude
	end
	
	return math.huge
end

-- 🔹 ตรวจสอบว่าผู้เล่นยังมีชีวิตอยู่หรือไม่
function PlayerDetectionModule.isPlayerAlive(player)
	if not player or not player.Character then
		return false
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	
	if humanoid and humanoid.Health > 0 then
		return true
	end
	
	return false
end

return PlayerDetectionModule