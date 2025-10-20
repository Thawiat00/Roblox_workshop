-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Attack.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)
local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)
local SkillManager = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.SkillManager)

return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = 0
        npc.attackTimer = 0
        npc.normalAttackCount = npc.normalAttackCount or 0
        npc.skillUsed = false
        npc.skillAnimationTime = 0

        print("⚔️", npc.model.Name, "→ เข้าสู่โหมดโจมตี")
    end,

    Update = function(npc, target, distance)
        if not target then 
            return "Chase" 
        end

        local attackCfg = Config.States.Attack
        local skillChance = SkillConfig.UseSkillChance or 0.25
        local range = attackCfg.Range
        local rangeSkill = attackCfg.Range_Skill

        -- 🎯 กำหนดจำนวนการโจมตีขั้นต่ำก่อนใช้สกิล (3 ครั้ง)
        --local minAttacksBeforeSkill = math.Random(2,4)
        local minAttacksBeforeSkill = Random.new(tick()):NextNumber(2,4) 



        -- 🟡 เช็คระยะห่างสำหรับโจมตีปกติ
        if distance > range then
            -- ถ้าห่างเกินระยะโจมตีปกติ แต่ยังอยู่ในระยะสกิล → ลองใช้สกิล
            if distance <= rangeSkill and npc.normalAttackCount >= minAttacksBeforeSkill and not npc.skillUsed then
              --  local success = SkillManager.UseSkill(npc, "Charge", target)
              local success = SkillManager.UseSkill(npc, "Stun", target)
                if success then
                    npc.skillUsed = true
                    npc.skillAnimationTime = tick()
                   -- print("💥 ใช้สกิล Charge การันตี!")
                   print("💥 ใช้สกิล Stun การันตี!")
                    return "UseSkill"
                end
            end
            return "Chase"
        end

        -- 🗡️ โจมตีปกติ
        npc.attackTimer = npc.attackTimer + npc.deltaTime
        if npc.attackTimer >= attackCfg.Cooldown and npc.normalAttackCount < minAttacksBeforeSkill then
            npc.attackTimer = 0
            local targetHumanoid = target.Parent:FindFirstChild("Humanoid")
            if targetHumanoid then
                targetHumanoid:TakeDamage(attackCfg.Damage)
                npc.normalAttackCount = npc.normalAttackCount + 1
                EventBus.Emit("OnNPCAttack", npc, target, attackCfg.Damage)
                print("🗡️ โจมตีปกติครั้งที่", npc.normalAttackCount)
            end
        end

        -- 🌀 ถ้าครบ 2 ครั้งแล้ว แต่ยังไม่ได้ใช้สกิล → ใช้ Charge
        -- 🌀 ถ้าครบ 2 ครั้งแล้ว แต่ยังไม่ได้ใช้สกิล → ใช้ Stun
        if npc.normalAttackCount >= minAttacksBeforeSkill and not npc.skillUsed then
          --  local success = SkillManager.UseSkill(npc, "Charge", target)
            local success = SkillManager.UseSkill(npc, "Stun", target)
            if success then
                npc.skillUsed = true
                npc.skillAnimationTime = tick()
              --  print("💥 ใช้สกิล Charge การันตี!")
              print("💥 ใช้สกิล Stun การันตี!")
                return "UseSkill"
            end
        end

        -- รอ Animation สกิลเสร็จ
        if npc.skillUsed then
          --  local skillData = SkillConfig.Skills["Charge"]
          local skillData = SkillConfig.Skills["Stun"]
            if tick() - npc.skillAnimationTime >= skillData.Duration then
                return "Chase"
            end
            return "UseSkill"
        end

        return "Attack"
    end,

    Exit = function(npc)
        npc.attackTimer = 0
        npc.normalAttackCount = 0
        npc.skillUsed = false
        npc.skillAnimationTime = 0
    end,
}
