-- ========================================
-- 📄 ServerScriptService/PerkSystem/PerkEffects/Effect_SilentStep.lua
-- ========================================
local PlayerConfig = require(game.ReplicatedStorage.Config.PlayerConfig)

return {
    Apply = function(player, perkData)
        local character = player.Character
        if not character then return end
        
        -- ลดเสียงเท้า (ต้องมีระบบเสียงเท้าก่อน)
        local soundReduction = perkData.WalkSoundReduction
        
        -- ตั้งค่า Attribute สำหรับระบบอื่นอ่าน
        character:SetAttribute("SoundReduction", soundReduction)
        character:SetAttribute("SprintPenalty", perkData.SprintDurationPenalty)
        
        print("🔇", player.Name, "has Silent Step active")
    end,
}
