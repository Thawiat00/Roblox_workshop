-- ========================================
-- 📄 STEP 1: เพิ่ม Config
-- 📁 ReplicatedStorage/Config/SkillConfig.lua (ไฟล์ใหม่)
-- ========================================
return {
    -- สกิลที่ NPC ใช้ได้
    Skills = {
        Fireball = {
            Name = "Fireball",
            Damage = 25,
            Range = 30,
            Cooldown = 5,
            Chance = 0.3,  -- 30% โอกาส
            Duration = 0.5
        },
        
        Heal = {
            Name = "Heal",
            HealAmount = 20,
            Cooldown = 8,
            Chance = 0.2,  -- 20% โอกาส
            Duration = 1
        },
        
        Stun = {
            Name = "Stun",
            Range = 10,
            StunDuration = 2,
            Cooldown = 10,
            Chance = 0.15  -- 15% โอกาส
        },

                -- 🌀 สกิลใหม่: พุ่งชาร์จเข้าโจมตีผู้เล่น
        Charge = {
            Name = "Charge",
            Damage = 15,           -- ความเสียหายเมื่อชน
            Range = 20,            -- ระยะตรวจจับก่อนพุ่ง
            SpeedMultiplier = 3, -- ความเร็วระหว่างพุ่ง (เท่ากับความเร็วปกติ * 2.5)

            DistanceBehind = 25,     -- จุดที่ NPC จะพุ่งเลยหลังเป้าหมาย
        KnockbackForce = 150, -- ✅ เพิ่มแรงผลัก


            Cooldown = 7,          -- คูลดาวน์ก่อนใช้ซ้ำได้
            Duration = 4,        -- ระยะเวลาที่อยู่ในสถานะพุ่ง
            Chance = 0.25          -- โอกาส 25% ที่จะใช้สกิลนี้แทนการโจมตีปกติ
        }
    },
    
    -- โอกาสที่จะใช้สกิล (แทนที่จะโจมตีปกติ)
    UseSkillChance = 0.8  -- 50%
}