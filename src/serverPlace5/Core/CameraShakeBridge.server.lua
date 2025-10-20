-- ========================================
-- 📄 ServerScriptService/Core/CameraShakeBridge.lua
-- ========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)
local CameraShakeEvent = ReplicatedStorage:WaitForChild("Common"):WaitForChild("CameraShakeEvent")
local Players = game:GetService("Players")

-- 🎯 ฟัง EventBus จาก server-side scripts อื่น ๆ
EventBus:On("ShakeCamera", function(targetCharacter, intensity, duration)
    print("🔔 [Bridge] Received ShakeCamera event")
    print("   Character:", targetCharacter)
    print("   Intensity:", intensity, type(intensity))
    print("   Duration:", duration, type(duration))
    
    -- ตรวจสอบว่า targetCharacter เป็น Character จริงหรือเปล่า
    if not targetCharacter or not targetCharacter:IsA("Model") then
        warn("❌ [Bridge] Invalid character:", targetCharacter)
        return
    end
    
    local player = Players:GetPlayerFromCharacter(targetCharacter)
    if player then
        -- ⚠️ แปลงค่าเป็นตัวเลขก่อนส่ง
        local finalIntensity = tonumber(intensity) or 1.5
        local finalDuration = tonumber(duration) or 0.7
        
        print("✅ [Bridge] Sending to:", player.Name, "| Intensity:", finalIntensity, "| Duration:", finalDuration)
        CameraShakeEvent:FireClient(player, finalIntensity, finalDuration)
    else
        warn("❌ [Bridge] Player not found for character:", targetCharacter.Name)
    end
end)

--EventBus:On("ShakeCamera", function(targetCharacter, intensity, duration)

print("[CameraShakeBridge] ✅ Ready to relay ShakeCamera events")