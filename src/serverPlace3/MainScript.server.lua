-- 📄 Script: MainScript
-- วางใน: ServerScriptService > MainScript
-- หน้าที่: เชื่อมต่อทุก Module และควบคุมการทำงานหลัก

local Workspace = game:GetService("Workspace")

-- 📦 โหลด ModuleScripts ทั้งหมด
local NPCCollisionModule = require(script.Parent.NPCCollisionModule)
local NPCAIModule = require(script.Parent.NPCAIModule)

-- 🎯 ตัวแปรหลัก
local enemiesFolder = workspace:WaitForChild("EnemiesFolder")
local waypointFolder = workspace:WaitForChild("WaypointsFolder")

print("🚀 MainScript: เริ่มต้นระบบ NPC AI")

-- ⚙️ 1. ตั้งค่า Collision System
NPCCollisionModule.initialize()

-- ตั้งค่า Collision สำหรับ NPC ที่มีอยู่แล้ว
for _, npc in pairs(enemiesFolder:GetChildren()) do
	NPCCollisionModule.setNPCCollisionGroup(npc)
end

-- ตั้งค่า Collision สำหรับ NPC ที่เกิดใหม่
enemiesFolder.ChildAdded:Connect(function(npc)
	task.wait(0.1)
	NPCCollisionModule.setNPCCollisionGroup(npc)
	print("✅ ตั้งค่า Collision สำหรับ: " .. npc.Name)
end)

-- 🗺️ 2. ตรวจสอบ Maze (ถ้ามี)
local meshMaze = workspace:FindFirstChild("mesh_maze")
if meshMaze and meshMaze:IsA("MeshPart") then
	print("📍 พบ MeshPart: " .. meshMaze.Name)
	print("   - Material: " .. tostring(meshMaze.Material))
	print("   - CanCollide: " .. tostring(meshMaze.CanCollide))
else
	warn("⚠️ ไม่พบ MeshPart ชื่อ 'mesh_maze'")
end

-- 🚩 3. เก็บตำแหน่ง Patrol Points
local patrolPoints = {}
for _, part in ipairs(waypointFolder:GetChildren()) do
	table.insert(patrolPoints, part.Position)
	part:Destroy()  -- ลบ Part หลังเก็บตำแหน่งแล้ว
end

print("📍 โหลด Patrol Points: " .. #patrolPoints .. " จุด")

-- 🤖 4. เริ่มต้น AI สำหรับ NPC ที่มีอยู่แล้ว
for _, enemy in pairs(enemiesFolder:GetChildren()) do
	if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
		NPCAIModule.createAI(enemy, patrolPoints)
		print("🤖 เริ่ม AI: " .. enemy.Name)
	end
end

-- 🆕 5. เริ่มต้น AI สำหรับ NPC ที่เกิดใหม่
enemiesFolder.ChildAdded:Connect(function(enemy)
	task.wait(0.1)
	if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
		NPCAIModule.createAI(enemy, patrolPoints)
		print("🤖 เริ่ม AI สำหรับ NPC ใหม่: " .. enemy.Name)
	end
end)

print("✅ MainScript: ระบบพร้อมทำงาน!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📊 สถิติ:")
print("   - NPC ทั้งหมด: " .. #enemiesFolder:GetChildren())
print("   - Patrol Points: " .. #patrolPoints)
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")