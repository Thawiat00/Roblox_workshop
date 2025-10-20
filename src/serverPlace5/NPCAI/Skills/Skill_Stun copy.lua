-- ========================================
-- 📁 ServerScriptService/NPCAI/Skills/Skill_Stun.lua (ไฟล์ใหม่)
-- ========================================
local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)




local Skill_Stun = {}

function Skill_Stun.Execute(npc, target)
    local config = SkillConfig.Skills.Stun
    local distance = (target.Position - npc.root.Position).Magnitude
    
    if distance > config.Range then return false end
    


    print("⚡", npc.model.Name, "used Stun!")
    
    local targetHumanoid = target.Parent:FindFirstChild("Humanoid")
    if targetHumanoid then
        -- Stun = หยุดเคลื่อนไหว
        local originalSpeed = targetHumanoid.WalkSpeed
        targetHumanoid.WalkSpeed = 0
        targetHumanoid.JumpPower = 0
        
        EventBus:Emit("PlayerStunned", {
            target = target.Parent.Name,
            duration = config.StunDuration
        })
        
        -- คืนค่าหลังจาก Stun หมด
        task.delay(config.StunDuration, function()
            if targetHumanoid then
                targetHumanoid.WalkSpeed = originalSpeed
                targetHumanoid.JumpPower = 50
            end
        end)
    end
    
    return true
end

return Skill_Stun


