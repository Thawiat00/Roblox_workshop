-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Idle.lua
-- ========================================

-- ✅ เพิ่มระบบสแกนรอยเท้า และตรวจจับผู้เล่น


local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

local FootprintScanner = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.FootprintScanner)


return {
    -- เมื่อเข้า State Idle
    Enter = function(npc)
        npc.humanoid.WalkSpeed = Config.States.Idle.Speed


        -- ⭐ เพิ่มตัวแปรจับเวลา (สำหรับสแกนรอยเท้า)
        npc.footprintScanTimer = npc.footprintScanTimer or 0

        print("😴", npc.model.Name, "→ Idle")




    end,
    
    Update = function(npc, target)
        -- 🧠 ต้องมีค่า deltaTime จากระบบหลักส่งเข้ามา (npc.deltaTime)
        -- เช่น npc.deltaTime = tick() - npc.lastUpdateTime

    -- ======== 1. ตรวจจับผู้เล่นก่อน (Priority สูงสุด) ========
    
        if target then
            return "Chase"
        end
        return "Idle"
    end,
    
    Exit = function(npc)
    end
}