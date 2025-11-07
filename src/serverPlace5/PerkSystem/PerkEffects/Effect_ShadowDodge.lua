-- ========================================
-- 📄 ServerScriptService/PerkSystem/PerkEffects/Effect_ShadowDodge.lua
-- ========================================
local EventBus = require(game.ReplicatedStorage.Core.EventBus)
local NPCConfig = require(game.ReplicatedStorage.Config.NPCConfig)

return {
    Apply = function(player, perkData)
        local character = player.Character
        if not character then return end
        
        character:SetAttribute("ShadowDodgeCooldown", 0)
        
        print("👤", player.Name, "has Shadow Dodge ready")
    end,
    
    -- เรียกเมื่อผู้เล่นหลบ (Dodge)
    OnDodge = function(player, perkData)
        local character = player.Character
        if not character then return false end
        
        local currentTime = tick()
        local lastUsed = character:GetAttribute("ShadowDodgeCooldown") or 0
        
        -- เช็ค Cooldown
        if currentTime - lastUsed < perkData.InvisibilityCooldown then
            return false
        end
        
        -- ทำให้หายตัว
        character:SetAttribute("Invisible", true)
        character:SetAttribute("ShadowDodgeCooldown", currentTime)
        
        print("👻", player.Name, "is invisible for", perkData.InvisibilityDuration, "seconds")
        
        -- ลดการตรวจจับของ NPC
        EventBus:Emit("PlayerInvisible", player, perkData.InvisibilityDuration)
        
        -- หมดเวลา
        task.delay(perkData.InvisibilityDuration, function()
            if character.Parent then
                character:SetAttribute("Invisible", false)
                print("👤", player.Name, "is visible again")
                EventBus:Emit("PlayerVisible", player)
            end
        end)
        
        return true
    end,
}