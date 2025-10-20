-- ========================================
-- 📄 ReplicatedStorage/Modules/CameraShake.lua
-- ระบบกล้องสั่น (Debug version)
-- ========================================

local CameraShake = {}
CameraShake.__index = CameraShake

-- ตั้งค่าเบื้องต้น
local RunService = game:GetService("RunService")

-- 🎚️ ปรับค่าความแรงและระยะเวลา
local SHAKE_INTENSITY = 1
local SHAKE_DURATION = 0.5

-- ฟังก์ชันเริ่มต้นการสั่น
function CameraShake:Shake(intensity, duration)
	intensity = intensity or SHAKE_INTENSITY
	duration = duration or SHAKE_DURATION

	local camera = workspace.CurrentCamera
	if not camera then
		warn("Camera not found!")
		return
	end

	print("[CameraShake] Start shaking! Intensity:", intensity, "Duration:", duration)

	local startTime = tick()
	local connection

	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			print("[CameraShake] End shaking.")
			connection:Disconnect()
			camera.CFrame = camera.CFrame -- reset
			return
		end

		-- คำนวณการสั่นแบบสุ่ม
		local offsetX = (math.random() - 0.5) * 2 * intensity
		local offsetY = (math.random() - 0.5) * 2 * intensity
		local offsetZ = (math.random() - 0.5) * 2 * intensity

		camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, offsetZ)
	end)
end

return CameraShake
