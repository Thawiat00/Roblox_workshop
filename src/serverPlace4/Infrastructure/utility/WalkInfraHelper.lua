-- ==========================================
-- Infrastructure / Helpers / WalkInfraHelper.lua
-- ==========================================
-- วัตถุประสงค์: รวมฟังก์ชันช่วยเหลือสำหรับ WalkService
-- ไม่มี Roblox API (pure logic)
-- ==========================================

local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)
local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)

local WalkInfraHelper = {}

-- ตรวจสอบว่า state ที่ส่งเข้ามา valid หรือไม่
function WalkInfraHelper.ValidateState(state)
	local validStates = {
		[AIState.Idle] = true,
		[AIState.Walk] = true,
		[AIState.Stop] = true,
	}

	if validStates[state] then
		return state
	else
		warn("[WalkInfraHelper] Invalid state:", state, "-> fallback to Idle")
		return AIState.Idle
	end
end

-- ตั้งค่าความเร็วให้ EnemyData โดยอิงจาก Config
function WalkInfraHelper.ApplyWalkSpeed(enemyData)
	if not enemyData then
		warn("[WalkInfraHelper] EnemyData is nil")
		return
	end
	
	if enemyData.SetSpeed then
		enemyData:SetSpeed(SimpleAIConfig.WalkSpeed)
	else
		enemyData.CurrentSpeed = SimpleAIConfig.WalkSpeed
	end
end

-- เปลี่ยนสถานะให้เป็น WALK (หลังตรวจสอบ valid)
function WalkInfraHelper.ApplyWalkState(enemyData)
	if not enemyData then return end

	local newState = WalkInfraHelper.ValidateState(AIState.Walk)
	enemyData:SetState(newState)
end

return WalkInfraHelper