
-- ========================================
-- 📄 ReplicatedStorage/Config/NPCConfig.lua
-- ========================================

return {
    Detection = {
        Range = 15,
        LoseRange = 20
    },
    
    States = {
        Idle = {
            Speed = 0,
            WaitTime = 3,  -- ⭐ เพิ่ม: รอกี่วินาทีก่อนเริ่ม Patrol
        },

                -- ⭐ เพิ่ม State ใหม่: Patrol (เดินสำรวจแบบสุ่ม)
        Patrol = {
            Speed = 8,                    -- ความเร็วเดิน (ช้ากว่า Chase)
            WanderRadius = 40,            -- รัศมีการเดินสำรวจจากจุดเริ่มต้น
            MinWaitTime = 2,              -- เวลารอขั้นต่ำที่แต่ละจุด (วินาที)
            MaxWaitTime = 5,              -- เวลารอสูงสุดที่แต่ละจุด (วินาที)
            StopDistance = 3,             -- ระยะห่างที่ถือว่าถึงจุดหมาย
            FootprintScanInterval = 2,    -- สแกนรอยเท้าทุกกี่วินาที
            PlayerDetectRange = 20,       -- ระยะตรวจจับผู้เล่นระหว่าง Patrol
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


        -- ⭐ เพิ่ม State ใหม่สำหรับเดินตามรอยเท้า
        FollowFootprint = {
            Speed = 12,                    -- ความเร็วเดิน (ช้ากว่า Chase)
            ScanRadius = 30,               -- รัศมีสแกนรอยเท้า
            ScanInterval = 2,              -- สแกนใหม่ทุก 2 วินาที
            StopDistance = 3,              -- ใกล้แค่ไหนถือว่าถึงรอยเท้า
            MaxLostTime = 10,              -- หาไม่เจอรอยเท้ากี่วินาทีให้กลับ Idle
            PlayerDetectRange = 10,        -- ระยะตรวจจับผู้เล่นระหว่างเดินตาม
            FootprintTag = "PlayerFootprint" -- Tag สำหรับรอยเท้า
        },

       -- Research = {
       --     Speed = 8,             -- ความเร็วการเดินสำรวจ
       --     WanderRadius = 30,     -- รัศมีสุ่มเดินจากตำแหน่งปัจจุบัน
       --     WaitTime = 2,          -- เวลาหยุดพักก่อนสุ่มจุดใหม่
       --     ChangeTargetInterval = 5 -- เปลี่ยนจุดสำรวจทุก 5 วิ
       -- },


    },
    
    Pathfinding = {
        UpdateInterval = 0.3,
        AgentRadius = 2,
        AgentHeight = 5,
        WaypointSpacing = 2,
        StopDistance = 3
    },


    



}