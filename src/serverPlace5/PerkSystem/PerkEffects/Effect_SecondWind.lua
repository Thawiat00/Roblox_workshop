-- ========================================
-- 📄 ServerScriptService/PerkSystem/PerkEffects/Effect_SecondWind.lua
-- ========================================
local EventBus = require(game.ReplicatedStorage.Core.EventBus)

return {
    Apply = function(player, perkData)
        local character = player.Character
        if not character then return end
        
        -- ตั้งค่า Flag
        character:SetAttribute("HasSecondWind", true)
        character:SetAttribute("SecondWindUsed", false)
        
        print("💨", player.Name, "has Second Wind ready")
    end,
    
    
    -- ฟังก์ชันเรียกเมื่อผู้เล่นควรจะตาย
    OnPlayerDown = function(player, perkData)
        local character = player.Character
        if not character then return false end
        
        local used = character:GetAttribute("SecondWindUsed")
        if used then return false end
        
        -- ฟื้นขึ้นมา
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = humanoid.MaxHealth * (perkData.ReviveHP / 100)
            character:SetAttribute("SecondWindUsed", true)
            
            print("💨", player.Name, "triggered Second Wind!")
            EventBus:Emit("SecondWindActivated", player)
            return true
        end
        
        return false
    end,
}