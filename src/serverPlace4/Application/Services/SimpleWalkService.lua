-- ==========================================
-- Application/Services/SimpleWalkService.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Business Logic การเดิน/หยุด
-- เขียนตอนนี้เพราะ: มี Core Layer และ Config พร้อมแล้ว
-- ไม่มี Roblox API: Logic บริสุทธิ์ ทดสอบได้แยก
-- ==========================================

local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)

local SimpleWalkService = {}
SimpleWalkService.__index = SimpleWalkService

-- ==========================================
-- Constructor: สร้าง Service สำหรับ Enemy 1 ตัว
-- ==========================================
function SimpleWalkService.new(enemyData)
	local self = setmetatable({}, SimpleWalkService)
	
	-- เก็บ Reference ของ Enemy Data ที่จะจัดการ
	self.EnemyData = enemyData
	
	return self
end

-- ==========================================
-- 1. หยุดเดิน (enemy_stop_walk)
-- ใช้เมื่อ: ต้องการให้หยุดสนิท กลับสู่สถานะพักผ่อน
-- ==========================================
function SimpleWalkService:StopWalk()
	self.EnemyData:SetSpeed(0)
	self.EnemyData:SetState(AIState.Idle) -- ตรวจสอบตรงกับ enum
end

-- ==========================================
-- 2. เริ่มเดิน (enemy_walking)
-- ใช้เมื่อ: ต้องการให้เริ่มเดินสำรวจ
-- ==========================================
function SimpleWalkService:StartWalking()
	-- ตั้งความเร็วตามที่กำหนด
	self.EnemyData:SetSpeed(self.EnemyData.WalkSpeed)
	
	-- เปลี่ยนเป็นสถานะ WALK (กำลังเดิน)
	self.EnemyData:SetState(AIState.Walk)
	
	print("[WalkService] Enemy walking - State: WALK, Speed:", self.EnemyData.WalkSpeed)
end

-- ==========================================
-- 3. หยุดชั่วคราว (enemy_stopwalk)
-- ใช้เมื่อ: หยุดพัก แต่จะกลับมาเดินต่อ (แตกต่างจาก StopWalk)
-- ==========================================
function SimpleWalkService:PauseWalk()
	-- ความเร็วเป็น 0 เหมือนกัน
	self.EnemyData:SetSpeed(0)
	
	-- แต่สถานะเป็น STOP (บอกว่าจะเดินต่อ)
	self.EnemyData:SetState(AIState.Stop)
	
	print("[WalkService] Enemy paused - State: STOP, Speed: 0")
end

-- ==========================================
-- 4. รีเซ็ต (enemy_reset)
-- ใช้เมื่อ: ต้องการเริ่มต้นใหม่ทั้งหมด
-- ==========================================
function SimpleWalkService:Reset()
	-- กลับไปสถานะเริ่มต้น
	self.EnemyData:SetSpeed(0)
	self.EnemyData:SetState(AIState.Idle)
	
	print("[WalkService] Enemy reset - State: IDLE, Speed: 0")
end

-- ==========================================
-- UTILITY: ตรวจสอบว่าควรเปลี่ยนพฤติกรรมหรือไม่
-- (สำหรับขยายในอนาคต - Phase 2, 3)
-- ==========================================
function SimpleWalkService:ShouldChangeState()
	-- ตอนนี้ใช้สุ่ม 50/50
	-- ในอนาคตอาจเช็คเงื่อนไขอื่น เช่น เจอผู้เล่น, เหนื่อย, ฯลฯ
	return math.random() > 0.5
end

-- ==========================================
-- GETTER: ดูสถานะปัจจุบัน
-- ==========================================
function SimpleWalkService:GetCurrentState()
	return self.EnemyData.CurrentState
end

function SimpleWalkService:GetCurrentSpeed()
	return self.EnemyData.CurrentSpeed
end

return SimpleWalkService