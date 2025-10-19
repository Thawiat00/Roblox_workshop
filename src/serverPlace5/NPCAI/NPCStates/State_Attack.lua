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

        -- ✅ เริ่มนับใหม่เมื่อเข้าสู่ State นี้
        npc.attackTimer = 0
        npc.normalAttackCount = npc.normalAttackCount or 0
        npc.timeSinceLastHit = 0
        npc.maxTimeWithoutHit = math.random(20, 30) / 10  -- 2–3 วินาที

        print("⚔️", npc.model.Name, "→ เข้าสู่โหมดโจมตี (timeout:", npc.maxTimeWithoutHit, "s)")
    end,

 Update = function(npc, target)
    if not target then 
        return "Chase" 
    end

    -- ใช้ Charge โดยตรง (การันตี)
    if not npc.skillUsed then
        local success = SkillManager.UseSkill(npc, "Charge", target)

        if success then
            npc.skillUsed = true
            npc.skillAnimationTime = tick()
        else
            -- fallback ถ้าใช้ไม่ได้
            return "Attack"
        end
    end

    -- รอ Animation เสร็จ
    local skillData = SkillConfig.Skills["Charge"]
    if tick() - npc.skillAnimationTime >= skillData.Duration then
        return "Chase"
    end

    return "UseSkill"
end,


    Exit = function(npc)
        npc.timeSinceLastHit = 0
        npc.attackTimer = 0
    end,
}
