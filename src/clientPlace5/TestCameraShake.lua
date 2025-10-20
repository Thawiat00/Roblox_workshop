-- ========================================
-- 📄 StarterPlayerScripts/TestCameraShake.lua
-- ทดสอบระบบกล้องสั่น
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local CameraShake = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CameraShake"))
local CameraShake = require(ReplicatedStorage:WaitForChild("Common"):WaitForChild("CameraShake"))

local UserInputService = game:GetService("UserInputService")

print("[CameraShake Debug] Press 'F' to test shake!")

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then
		CameraShake:Shake(1.5, 0.7)
	end
end)
