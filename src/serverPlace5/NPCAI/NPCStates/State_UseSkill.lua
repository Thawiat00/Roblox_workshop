-- ========================================
-- 📄 STEP 5: เพิ่ม State_UseSkill
-- 📁 ServerScriptService/NPCAI/NPCStates/State_UseSkill.lua (ไฟล์ใหม่)
-- ========================================
--local Config = require(game.ReplicatedStorage.Config.NPCConfig)
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

--local SkillConfig = require(game.ReplicatedStorage.Config.SkillConfig)
local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)

--local SkillManager = require(script.Parent.Parent.Utils.SkillManager)
local SkillManager = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.SkillManager)


return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = 0
        npc.isUsingSkill = true
        print("✨", npc.model.Name, "→ UseSkill")
    end,
    
    Update = function(npc, target)
        if not target then 
            return "Chase" 
        end
        
        -- สุ่มสกิล
        if not npc.selectedSkill then
            npc.selectedSkill = SkillManager.GetRandomSkill(npc)
            
            if not npc.selectedSkill then
                -- ไม่มีสกิลพร้อมใช้ → โจมตีปกติ
                return "Attack"
            end
        end
        
        -- ใช้สกิล
        if not npc.skillUsed then
            local success = SkillManager.UseSkill(npc, npc.selectedSkill, target)
            
            if success then
                npc.skillUsed = true
                npc.skillAnimationTime = tick()
            else
                -- ใช้ไม่ได้ → โจมตีปกติ
                return "Attack"
            end
        end
        
        -- รอ Animation เสร็จ
        local skillData = SkillConfig.Skills[npc.selectedSkill]
        if tick() - npc.skillAnimationTime >= skillData.Duration then
            return "Chase"
        end
        
        return "UseSkill"
    end,
    
    Exit = function(npc)
        npc.isUsingSkill = false
        npc.selectedSkill = nil
        npc.skillUsed = false
        npc.skillAnimationTime = nil
    end
}