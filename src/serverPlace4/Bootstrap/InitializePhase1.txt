print("===========================================")
print("[Phase 1] 🎮 Starting Simple Walk AI System")
print("===========================================")

-- ==========================================
-- โหลด Controller (ชั้นบนสุด)
-- ==========================================
local SimpleWalkController = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.SimpleWalkController)

-- ==========================================
-- โหลด Repository (Singleton)
-- ==========================================
local SimpleEnemyRepository = require(game.ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
local repo = SimpleEnemyRepository.GetInstance()  -- ✅ ใช้ singleton instance

-- ==========================================
-- หา Enemies Folder ใน Workspace
-- ==========================================
local enemiesFolder = workspace:FindFirstChild("Enemies")

if not enemiesFolder then
	warn("[Phase 1] ❌ No 'Enemies' folder found in workspace!")
	warn("[Phase 1] 💡 Please create a folder named 'Enemies' and add enemy models")
	return
end

-- ==========================================
-- เริ่ม AI สำหรับทุกตัวใน Folder
-- ==========================================
local activeControllers = {}
local successCount = 0
local failCount = 0

for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
	if enemyModel:IsA("Model") and enemyModel:FindFirstChild("Humanoid") then
		
		local success, controllerOrError = pcall(function()
			-- ===== สร้าง enemy data ผ่าน repository =====
			print("[Debug] Creating enemy data for:", enemyModel.Name)
			local enemyData = repo:CreateSimpleEnemy(enemyModel)
			assert(enemyData, "[Phase 1] ❌ Failed to create enemyData for: "..enemyModel.Name)

			-- ===== สร้าง Controller =====
			print("[Debug] Creating controller for:", enemyModel.Name)
			local controller = SimpleWalkController.new(enemyModel)
			assert(controller, "[Phase 1] ❌ Failed to create controller for: "..enemyModel.Name)

			return controller
		end)
		
		if success then
			table.insert(activeControllers, controllerOrError)
			successCount = successCount + 1
			print("[Phase 1] ✅", enemyModel.Name, "- Random Walk AI Started")
		else
			failCount = failCount + 1
			warn("[Phase 1] ❌", enemyModel.Name, "- Failed:", controllerOrError)
		end
	else
		warn("[Phase 1] ⚠️", enemyModel.Name, "- Invalid model (no Humanoid)")
	end
end

-- ==========================================
-- สรุปผล
-- ==========================================
print("===========================================")
print("[Phase 1] 📊 Summary:")
print("[Phase 1] ✅ Active AIs:", successCount)
if failCount > 0 then
	warn("[Phase 1] ❌ Failed:", failCount)
end
print("[Phase 1] 🎯 System Ready!")
print("===========================================")

-- ==========================================
-- สร้าง Global API (สำหรับ Debug/ทดสอบ)
-- ==========================================
_G.Phase1 = {
	GetActiveCount = function()
		return #activeControllers
	end,
	GetControllers = function()
		return activeControllers
	end,
	ResetAll = function()
		for _, controller in ipairs(activeControllers) do
			controller:Reset()
		end
		print("[Phase 1] All AIs reset")
	end
}
