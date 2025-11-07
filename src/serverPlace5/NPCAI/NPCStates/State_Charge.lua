-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Chase.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

return {
    Enter = function(npc)
        if not Config.States.Charge.Enabled then
            return "Chase"
        end

        
        npc.humanoid.WalkSpeed = Config.States.Charge.Speed
        npc.canCharge = true
        npc.chargeStartTime = tick()
        print("⚡", npc.model.Name, "→ Charge!")
    end,
    
    Update = function(npc, target)
        if not target then 
            return "Idle"
        end



        local distance = (npc.root.Position - target.Position).Magnitude

        -- ✅ เช็คว่าเปิดใช้งาน Charge หรือไม่
        local chargeCfg = Config.States.Charge
        if chargeCfg.Enabled and npc.canCharge and distance > chargeCfg.TriggerDistance then
            npc.canCharge = false
            return "Charge"
        end
        
        -- อยู่ใกล้ → โจมตี
        if distance <= Config.States.Attack.Range then
            return "Attack"
        end
        
        npc.humanoid:MoveTo(target.Position)
        return "Chase"
    end,
    
    Exit = function(npc)
        -- ออก state
    end
}





