-- 📦 ModuleScript: NPCAIModule
-- วางใน: ServerScriptService > NPCAIModule
-- หน้าที่: ควบคุม AI ของ NPC (ไล่ล่า/ลาดตระเวน)

local NPCAIModule = {}

-- โหลด Module อื่นๆ
local PathfindingModule = require(script.Parent.PathfindingModule)
local PlayerDetectionModule = require(script.Parent.PlayerDetectionModule)

-- ⚙️ ตั้งค่าคงที่
local DETECT_DISTANCE = 50  -- เพิ่มระยะตรวจจับให้มากขึ้น
local ATTACK_DISTANCE = 5   -- ระยะโจมตี
local CHASE_UPDATE_RATE = 0.1  -- อัพเดท Path ทุก 0.3 วินาที (ตอบสนองเร็วขึ้น)

-- 🔹 สร้าง AI Loop สำหรับ NPC แต่ละตัว
function NPCAIModule.createAI(npc, patrolPoints)
	local humanoid = npc:WaitForChild("Humanoid")
	local hrp = npc:WaitForChild("HumanoidRootPart")
	
	-- ตั้งค่า PrimaryPart
	if not npc.PrimaryPart then
		npc.PrimaryPart = hrp
	end
	
	-- ตัวแปรสำหรับติดตาม state
	local isChasing = false
	
	-- เริ่ม AI Loop ใน Thread แยก
	task.spawn(function()
		local patrolIndex = 1
		
		while npc.Parent and humanoid.Health > 0 do
			-- 🔍 ตรวจสอบว่ามีผู้เล่นใกล้หรือไม่
			local targetPlayer = PlayerDetectionModule.findNearestPlayer(npc, DETECT_DISTANCE)
			
			if targetPlayer and targetPlayer.Character then
				-- 🏃 โหมดไล่ล่าผู้เล่น
				isChasing = true
				print("🎯 " .. npc.Name .. " กำลังไล่ " .. targetPlayer.Name)
				
				local chaseStartTime = tick()
				local maxChaseTime = 30  -- ไล่สูงสุด 30 วินาที
				
				while targetPlayer 
					and targetPlayer.Character 
					and targetPlayer.Character:FindFirstChild("HumanoidRootPart") 
					and npc.Parent 
					and humanoid.Health > 0
					and (tick() - chaseStartTime) < maxChaseTime do
					
					local playerHrp = targetPlayer.Character.HumanoidRootPart
					local distance = (playerHrp.Position - hrp.Position).Magnitude
					
					-- ถ้าผู้เล่นไกลเกินไป หยุดไล่
					if distance > DETECT_DISTANCE * 1.5 then
						print("❌ " .. npc.Name .. " เลิกไล่ (ไกลเกินไป)")
						break
					end
					
					-- ถ้าใกล้พอ โจมตีเลย
					if distance <= ATTACK_DISTANCE then
						PlayerDetectionModule.attackPlayer(targetPlayer)
						print("💀 " .. npc.Name .. " โจมตี " .. targetPlayer.Name)
						task.wait(2)  -- รอก่อนหาเป้าหมายใหม่
						break
					end
					
					-- สร้าง Path ไปหาผู้เล่น
					local path = PathfindingModule.createPath(npc, playerHrp.Position)
					
					if path then
						-- เริ่มเดินตาม Path แบบไม่รอให้ถึง
						local waypoints = path:GetWaypoints()
						
						for i, wp in ipairs(waypoints) do
							-- ตรวจสอบว่ายังอยู่ในระยะหรือไม่
							if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
								break
							end
							
							local currentDistance = (targetPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
							
							-- ถ้าใกล้พอแล้ว หยุดเดินและโจมตี
							if currentDistance <= ATTACK_DISTANCE then
								PlayerDetectionModule.attackPlayer(targetPlayer)
								print("💀 " .. npc.Name .. " โจมตี " .. targetPlayer.Name)
								break
							end
							
							-- ถ้าไกลเกินไป หยุดเดิน
							if currentDistance > DETECT_DISTANCE * 1.5 then
								break
							end
							
							if wp.Action == Enum.PathWaypointAction.Jump then
								humanoid:MoveTo(wp.Position)
								humanoid.Jump = true
							else
								humanoid:MoveTo(wp.Position)
							end
							
							-- รอแค่ระยะสั้นๆ หรือจนกว่าจะถึง waypoint
							local timeout = 2
							local moveStart = tick()
							while (tick() - moveStart) < timeout do
								if (hrp.Position - wp.Position).Magnitude < 5 then
									break
								end
								task.wait(0.1)
							end
							
							-- ทุก 2-3 waypoints สร้าง path ใหม่
							if i % 2 == 0 then
								break  -- ออกจาก loop เพื่อสร้าง path ใหม่
							end
						end
					else
						-- ถ้าสร้าง path ไม่ได้ เดินตรงไป
						humanoid:MoveTo(playerHrp.Position)
						task.wait(0.5)
					end
					
					task.wait(CHASE_UPDATE_RATE)
					
					-- อัพเดทเป้าหมาย
					targetPlayer = PlayerDetectionModule.findNearestPlayer(npc, DETECT_DISTANCE)
				end
				
				isChasing = false
				print("🛑 " .. npc.Name .. " หยุดไล่")
				
			else
				-- 🚶 โหมดลาดตระเวน (Patrol)
				if #patrolPoints > 0 then
					local point = patrolPoints[patrolIndex]
					
					if point then
						-- ตรวจสอบระยะห่างจากจุดเป้าหมาย
						if (hrp.Position - point).Magnitude > 5 then
							local path = PathfindingModule.createPath(npc, point)
							
							if path then
								PathfindingModule.moveAlongPath(npc, path)
							else
								-- ถ้าสร้าง path ไม่ได้ เดินตรงไป
								humanoid:MoveTo(point)
								task.wait(2)
							end
						end
						
						-- เปลี่ยนไปจุดถัดไป
						patrolIndex = patrolIndex % #patrolPoints + 1
					end
				end
				
				task.wait(1)  -- รอนานหน่อยในโหมด patrol
			end
		end
		
		print("🛑 AI Loop สำหรับ " .. npc.Name .. " หยุดทำงาน")
	end)
end

return NPCAIModule