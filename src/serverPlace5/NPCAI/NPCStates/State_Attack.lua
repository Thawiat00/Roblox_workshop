-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Attack.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)


local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = 0
        print("⚔️", npc.model.Name, "→ Attack")
    end,
    
    Update = function(npc, target, distance)
        if not target then 
            return "Chase" 
        end
        
        -- ห่างเกินไป → ไล่ต่อ
        if distance > Config.States.Attack.Range + 2 then
            return "Chase"
        end
        
        -- โจมตี (ถ้าพร้อม)
        npc.attackTimer = npc.attackTimer + npc.deltaTime
        
        if npc.attackTimer >= Config.States.Attack.Cooldown then
            npc.attackTimer = 0
            

            -- ✅ สุ่มว่าจะใช้สกิลหรือโจมตีปกติ
            if math.random() <= SkillConfig.UseSkillChance then
                return "UseSkill"  -- ใช้สกิลแทน!
            end

            local targetHumanoid = target.Parent:FindFirstChild("Humanoid")
            if targetHumanoid then
                targetHumanoid:TakeDamage(Config.States.Attack.Damage)
                
                EventBus:Emit("NPCAttacked", {
                    npc = npc.model.Name,
                    target = target.Parent.Name,
                    damage = Config.States.Attack.Damage
                })
            end
        end
        
        return "Attack"
    end,
    
    Exit = function(npc)
    end
}