-- 📦 ModuleScript: NPCCollisionModule
-- วางใน: ServerScriptService > NPCCollisionModule
-- หน้าที่: จัดการ Collision Group ของ NPC เพื่อไม่ให้ชนกัน

local NPCCollisionModule = {}

local PhysicsService = game:GetService("PhysicsService")

-- 🔹 ฟังก์ชันสร้าง CollisionGroup สำหรับ NPC
function NPCCollisionModule.initialize()
	local success, err = pcall(function()
		PhysicsService:RegisterCollisionGroup("NPCs")
	end)
	
	if not success then
		warn("⚠️ CollisionGroup 'NPCs' อาจมีอยู่แล้ว:", err)
	end
	
	-- ตั้งค่าให้ NPC ไม่ชนกัน
	PhysicsService:CollisionGroupSetCollidable("NPCs", "NPCs", false)
	print("✅ NPCCollisionModule: Initialized")
end

-- 🔹 ตั้งค่า CollisionGroup ให้กับ NPC ทั้งตัว
function NPCCollisionModule.setNPCCollisionGroup(npc)
	for _, part in pairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "NPCs"
		end
	end
end

return NPCCollisionModule