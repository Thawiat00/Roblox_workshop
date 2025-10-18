-- ============================================
-- 📄 CollisionSetup.lua (รันครั้งเดียวใน server)
-- ============================================
local PhysicsService = game:GetService("PhysicsService")

local groups = {"Player", "EnemyCharge"}

-- สร้าง Collision Group ถ้ายังไม่มี
local function safeCreateGroup(name)
	if not pcall(function() PhysicsService:CreateCollisionGroup(name) end) then
		print("✅ Collision group exists:", name)
	end
end

safeCreateGroup("Player")
safeCreateGroup("EnemyCharge")
safeCreateGroup("Enemy")

-- ตั้งค่าว่าใครชนใคร
PhysicsService:CollisionGroupSetCollidable("Player", "EnemyCharge", false)
PhysicsService:CollisionGroupSetCollidable("EnemyCharge", "Player", false)
PhysicsService:CollisionGroupSetCollidable("EnemyCharge", "EnemyCharge", false)

-- optional: เพื่อความชัวร์
PhysicsService:CollisionGroupSetCollidable("Enemy", "EnemyCharge", false)

print("✅ Collision groups configured successfully.")