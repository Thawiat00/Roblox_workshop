-- ========================================
-- 📄 StarterPlayerScripts/CameraShakeClient.client.lua
-- ========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CameraShakeEvent = ReplicatedStorage:WaitForChild("Common"):WaitForChild("CameraShakeEvent")

-- 🎥 ฟังก์ชันสั่นกล้อง
local function ShakeCamera(intensity, duration)
    -- ⚠️ แปลงเป็นตัวเลขก่อน (ป้องกัน string เข้ามา)
    intensity = tonumber(intensity) or 1
    duration = tonumber(duration) or 0.5
    
    local camera = workspace.CurrentCamera
    if not camera then
        warn("[CameraShake] No CurrentCamera found!")
        return
    end
    
    print(string.format("[CameraShake] 🔔 Started! Intensity: %.2f | Duration: %.2f", intensity, duration))
    
    local startTime = tick()
    local connection
    
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        
        if elapsed >= duration then
            print("[CameraShake] ✅ Finished!")
            connection:Disconnect()
            return
        end
        
        -- 💥 คำนวณการสั่นแบบสุ่ม + fade out
        local progress = elapsed / duration
        local fadeOut = 1 - progress -- ลดความแรงตามเวลา
        
        local offsetX = (math.random() - 0.5) * 2 * intensity * fadeOut
        local offsetY = (math.random() - 0.5) * 2 * intensity * fadeOut
        local offsetZ = (math.random() - 0.5) * 2 * intensity * fadeOut
        
        camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, offsetZ)
    end)
end

-- 📡 รอรับสัญญาณจาก Server
CameraShakeEvent.OnClientEvent:Connect(function(intensity, duration)
    print("[CameraShake] 📥 Received:", "intensity =", intensity, "duration =", duration)
    ShakeCamera(intensity, duration)
end)

print("[CameraShakeClient] ✅ Ready to receive shake events.")