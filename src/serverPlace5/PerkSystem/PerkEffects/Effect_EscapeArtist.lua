-- ========================================
-- 📄 ServerScriptService/PerkSystem/PerkEffects/Effect_EscapeArtist.lua
-- ========================================
local EventBus = require(game.ReplicatedStorage.Core.EventBus)

return {
    Apply = function(player, perkData)
        local character = player.Character
        if not character then return end
        
        character:SetAttribute("EscapeArtistUsed", false)
        
        print("🎭", player.Name, "has Escape Artist ready")
    end,
    
    -- เรียกเมื่อถูก Titan จับ
    OnCaptured = function(player, npc, perkData)
        local character = player.Character
        if not character then return false end
        
        local used = character:GetAttribute("EscapeArtistUsed")
        if used then return false end
        
        -- สุ่มโอกาส
        local roll = math.random()
        if roll > perkData.EscapeChance then
            return false -- ไม่สำเร็จ
        end
        
        -- หนีสำเร็จ!
        character:SetAttribute("EscapeArtistUsed", true)
        
        -- ทำให้ NPC สตัน
        if npc and npc.stateMachine then
            local hitData = {
                Type = "EscapeArtist",
                Duration = perkData.EscapeStunDuration,
            }
            npc.stateMachine:Change_extra("Hit", hitData)
        end
        
        -- ปล่อยผู้เล่น
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
        
        print("🎭✨", player.Name, "escaped from Titan!")
        EventBus:Emit("PlayerEscaped", player, npc)
        
        return true
    end,
}