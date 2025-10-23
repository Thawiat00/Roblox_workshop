
-- ========================================
-- 📄 ReplicatedStorage/Config/NPCConfig.lua
-- ========================================

return {
    Detection = {
        Range = 50,
        LoseRange = 70
    },
    
    States = {
        Idle = {
            Speed = 0
        },
        
        Chase = {
            Speed = 18,
            MinDistance = 9  -- ใกล้กว่านี้ → Attack
        },
        
        Attack = {
            Damage = 15,
            Range = 10,
            Cooldown = 2.5,
            Range_Skill = 80
        },
        
            -- ⭐ เพิ่มส่วนนี้
        Hit = {
            StunTime = 1.0,        -- ชะงักกี่วินาที
            KnockbackPower = 40,  -- ⭐ ปรับค่านี้,   -- แรงกระเด้ง
        },

        Charge = {
            Speed = 30,
            Duration = 5,
            Cooldown = 2,
            TriggerDistance = 30,  -- ไกลกว่านี้ → Charge
            Enabled = false  -- ⬅️ เพิ่มบรรทัดเดียว!
        },

                -- ✅ เพิ่ม State ใหม่
        UseSkill = {
            Range = 80,  -- ระยะสูงสุดที่สามารถใช้สกิลได้
            UseSkill = 1, -- 🧭 ระยะขั้นต่ำก่อนใช้สกิล (ถ้าอยู่ใกล้กว่านี้จะไม่ใช้)
        },
    },
    
    Pathfinding = {
        UpdateInterval = 0.3,
        AgentRadius = 2,
        AgentHeight = 5,
        WaypointSpacing = 2,
        StopDistance = 3
    },


    



}