-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Charge.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = Config.States.Charge.Speed
        npc.canCharge = false
        npc.chargeStartTime = tick()
        print("⚡", npc.model.Name, "→ Charge!")
    end,
    
    Update = function(npc, target)
        if not target then 
            return "Chase" 
        end
        
        local elapsed = tick() - npc.chargeStartTime
        
        -- พุ่งไปหา Target
        npc.humanoid:MoveTo(target.Position)
        
        -- หมดเวลา → กลับ Chase
        if elapsed >= Config.States.Charge.Duration then
            -- เริ่ม Cooldown
            task.delay(Config.States.Charge.Cooldown, function()
                npc.canCharge = true
            end)
            return "Chase"
        end
        
        return "Charge"
    end,
    
    Exit = function(npc)
        npc.chargeStartTime = nil
    end
}