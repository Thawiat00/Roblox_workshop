-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Attack.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)
local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = 0
        
        -- ✅ เพิ่มตัวนับจำนวนการโจมตีปกติ (ถ้ายังไม่มี)
        if not npc.normalAttackCount then
            npc.normalAttackCount = 0
        end
        
        print("⚔️", npc.model.Name, "→ Attack")
    end,
    
    Update = function(npc, target, distance)
        if not target then 
            return "Chase"
        end

        local attackCfg = Config.States.Attack
        local skillChance = SkillConfig.UseSkillChance or 0.25
        local range = attackCfg.Range
        local rangeSkill = attackCfg.Range_Skill
        
        -- 🎯 กำหนดจำนวนการโจมตีขั้นต่ำก่อนใช้สกิล (2-3 ครั้ง)
        local minAttacksBeforeSkill = math.random(2, 3)

        -- 🟡 เช็คระยะห่าง - ถ้าไกลเกินระยะโจมตีปกติ → กลับไปไล่
        if distance > range then
            -- ถ้าห่างเกินระยะโจมตีปกติแต่ยังอยู่ในระยะสกิล → ลองใช้สกิล
            if distance <= rangeSkill then
                local shouldTrySkill = npc.normalAttackCount >= minAttacksBeforeSkill
                if shouldTrySkill and math.random() <= skillChance then
                    print("💥 อยู่ในระยะสกิล! (โจมตีปกติไปแล้ว", npc.normalAttackCount, "ครั้ง)")
                    npc.normalAttackCount = 0
                    
                    -- 🔔 ส่ง Event ก่อนใช้สกิล
                    EventBus.Emit("OnNPCUseSkill", npc, target)
                    
                    return "UseSkill"
                end
            end
            -- ถ้าห่างเกินระยะสกิล หรือไม่ได้ใช้สกิล → กลับไปไล่
            print("🏃 ห่างเกินไป (", math.floor(distance), "studs) → Chase")
            return "Chase"
        end

        -- 🗡️ โจมตีปกติ (ต้องอยู่ในระยะ range)
        npc.attackTimer = npc.attackTimer + npc.deltaTime
        if npc.attackTimer >= attackCfg.Cooldown then
            npc.attackTimer = 0
            
            local targetHumanoid = target.Parent:FindFirstChild("Humanoid")
            if targetHumanoid then
                targetHumanoid:TakeDamage(attackCfg.Damage)
                npc.normalAttackCount = npc.normalAttackCount + 1
                
                -- 🔔 ส่ง Event เมื่อโจมตีปกติ
                EventBus.Emit("OnNPCAttack", npc, target, attackCfg.Damage)
                
                print("🗡️ โจมตีปกติครั้งที่", npc.normalAttackCount)
            end
        end
        
        return "Attack"
    end,
    
    Exit = function(npc)
        -- เมื่อออกจาก State Attack ให้รีเซ็ตตัวนับ (ถ้าต้องการ)
        -- npc.normalAttackCount = 0
    end
}