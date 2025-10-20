-- =========================================
-- 📄 FreezeMovement.lua
-- หยุดการเคลื่อนไหวของผู้เล่นแบบง่าย
-- =========================================

-- ✅ ดึง Player และ Humanoid
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- =========================================
-- 🧊 ฟังก์ชันหยุดการเคลื่อนไหว
-- =========================================
local function FreezePlayer()
	print("❄️ Player movement frozen")
	humanoid.WalkSpeed = 0
end

-- =========================================
-- 🔄 ฟังก์ชันคืนค่าความเร็วปกติ
-- =========================================
local function UnfreezePlayer()
	print("🔥 Player movement restored")
	humanoid.WalkSpeed = 16 -- ค่าปกติของ Roblox
end

-- =========================================
-- 🧩 ตัวอย่างการใช้งาน
-- =========================================
-- หยุดหลังจาก 2 วินาที
task.wait(2)
FreezePlayer()

-- คืนค่าหลังจากอีก 3 วินาที
task.wait(3)
UnfreezePlayer()
