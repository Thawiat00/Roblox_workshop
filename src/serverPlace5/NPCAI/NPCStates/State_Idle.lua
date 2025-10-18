-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Idle.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = Config.States.Idle.Speed
        print("😴", npc.model.Name, "→ Idle")
    end,
    
    Update = function(npc, target)
        if target then
            return "Chase"
        end
        return "Idle"
    end,
    
    Exit = function(npc)
    end
}