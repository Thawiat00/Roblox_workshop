-- ========================================
-- 📄 STEP 3: สร้าง SkillManager
-- 📁 ServerScriptService/NPCAI/Utils/SkillManager.lua (ไฟล์ใหม่)
-- ========================================
local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

local SkillManager = {}

-- โหลดสกิลทั้งหมด
local Skills = {

      Charge = require(game.ServerScriptService.ServerLocal.NPCAI.Skills.Skill_Charge),
     -- Stun = require(game.ServerScriptService.ServerLocal.NPCAI.Skills.Skill_Stun),
}

-- สุ่มสกิลที่พร้อมใช้
function SkillManager.GetRandomSkill(npc)
    local availableSkills = {}
    
    for skillName, skillData in pairs(SkillConfig.Skills) do
        -- เช็ค Cooldown
        if not npc.skillCooldowns[skillName] or 
           tick() - npc.skillCooldowns[skillName] >= skillData.Cooldown then
            
            -- สุ่มตาม Chance
            if math.random() <= skillData.Chance then
                table.insert(availableSkills, skillName)
            end
        end
    end
    
    if #availableSkills > 0 then
        return availableSkills[math.random(1, #availableSkills)]
    end
    
    return nil
end

-- ใช้สกิล
function SkillManager.UseSkill(npc, skillName, target)
    if not Skills[skillName] then return false end
    
    local skill = Skills[skillName]
    local success = skill.Execute(npc, target)
    
    if success then
        -- บันทึก Cooldown
        npc.skillCooldowns[skillName] = tick()
        
        -- ยิง Event
        EventBus:Emit("NPCUsedSkill", {
            npc = npc.model.Name,
            skill = skillName,
            target = target.Parent.Name
        })
        
        return true
    end
    
    return false
end

return SkillManager