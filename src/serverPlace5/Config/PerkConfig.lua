-- ========================================
-- 📄 ReplicatedStorage/Config/PerkConfig.lua
-- ========================================

return {
    -- ========================================
    -- 🎮 Perk Definitions (20 Perks)
    -- ========================================
    Perks = {
        SilentStep = {
            ID = 1,
            Name = "Silent Step",
            Description = "ลดเสียงการเดิน/วิ่ง 40%",
            Icon = "rbxassetid://123456789", -- ใส่ Asset ID ของไอคอน
            
            -- Positive Effects
            WalkSoundReduction = 0.4,
            RunSoundReduction = 0.4,
            
            -- Negative Effects (จุดอ่อน)
            SprintDurationPenalty = 1, -- ลด Sprint 1 วินาที
            
            -- Config References
            AffectsPlayerConfig = true,
            ModifiesMovement = true,
        },
        
        FastLearner = {
            ID = 2,
            Name = "Fast Learner",
            Description = "แก้ปริศนาเร็วขึ้น 25%",
            Icon = "rbxassetid://123456790",
            
            PuzzleSpeedBonus = 0.25,
            
            -- จุดอ่อน
            NoisyPuzzleChance = 0.15, -- โอกาส 15% ทำเสียงดัง
            
            AffectsGameplay = true,
        },
        
        SecondWind = {
            ID = 3,
            Name = "Second Wind",
            Description = "ล้มครั้งแรกไม่ตายทันที (ใช้ได้ครั้งเดียว)",
            Icon = "rbxassetid://123456791",
            
            ReviveOnFirstDown = true,
            UsesPerMatch = 1,
            ReviveHP = 30, -- ฟื้นมาด้วย HP 30%
            
            AffectsPlayerConfig = true,
        },
        
        ShadowDodge = {
            ID = 4,
            Name = "Shadow Dodge",
            Description = "หายตัวสั้นๆ 1 วินาทีหลังหลบ Titan",
            Icon = "rbxassetid://123456792",
            
            InvisibilityDuration = 1.0,
            InvisibilityCooldown = 30,
            TriggerOnDodge = true,
            
            AffectsNPCDetection = true,
        },
        
        MedicInstinct = {
            ID = 5,
            Name = "Medic Instinct",
            Description = "ช่วยเพื่อนได้เร็วขึ้น",
            Icon = "rbxassetid://123456793",
            
            HealSpeedBonus = 0.35, -- เร็วขึ้น 35%
            
            -- จุดอ่อน
            BlindWhileHealing = true, -- มองไม่เห็นเพื่อนตอนช่วย
            
            AffectsGameplay = true,
        },
        
        IronNerves = {
            ID = 6,
            Name = "Iron Nerves",
            Description = "เมื่อใกล้ Titan หน้าจอไม่สั่น",
            Icon = "rbxassetid://123456794",
            
            DisableCameraShake = true,
            
            -- จุดอ่อน
            NoTitanProximityWarning = true, -- ไม่มีแจ้งเตือน
            
            AffectsUI = true,
        },
        
        LoneWolf = {
            ID = 7,
            Name = "Lone Wolf",
            Description = "อยู่คนเดียวแล้วเดินเร็วขึ้น",
            Icon = "rbxassetid://123456795",
            
            SoloSpeedBonus = 0.20, -- เร็วขึ้น 20%
            SoloDetectionRange = 30, -- ถ้าไม่มีเพื่อนใน 30 studs
            
            -- จุดอ่อน
            HideTeammateIndicators = true, -- มองไม่เห็นเพื่อน
            
            AffectsPlayerConfig = true,
            AffectsUI = true,
        },
        
        LockerMaster = {
            ID = 8,
            Name = "Locker Master",
            Description = "เข้าออกตู้ไว + เงียบ",
            Icon = "rbxassetid://123456796",
            
            LockerSpeedBonus = 0.50, -- เร็วขึ้น 50%
            LockerSoundReduction = 0.80, -- เสียงลด 80%
            
            -- จุดอ่อน
            LockerJamChance = 0.05, -- โอกาส 5% ติดขัด
            
            AffectsGameplay = true,
        },
        
        NightWatcher = {
            ID = 9,
            Name = "Night Watcher",
            Description = "เห็นในที่มืดชัดขึ้น",
            Icon = "rbxassetid://123456797",
            
            DarkVisionBonus = 0.40,
            
            -- จุดอ่อน
            BrightAreaBlur = true, -- ในที่สว่างจะเบลอ
            
            AffectsGraphics = true,
        },
        
        FootWhisper = {
            ID = 10,
            Name = "Foot Whisper",
            Description = "เห็นรอยเท้าเพื่อนใน 10 วิล่าสุด",
            Icon = "rbxassetid://123456798",
            
            SeeTeammateFootprints = true,
            FootprintDuration = 10,
            
            -- จุดอ่อน
            HideOwnFootprints = true, -- ไม่แสดงรอยเท้าตัวเอง
            
            AffectsGameplay = true,
        },
        
        EscapeArtist = {
            ID = 11,
            Name = "Escape Artist",
            Description = "มีโอกาสหนีจาก Titan ได้เมื่อถูกจับ",
            Icon = "rbxassetid://123456799",
            
            EscapeChance = 0.35, -- โอกาส 35%
            UsesPerMatch = 1,
            EscapeStunDuration = 2, -- NPC สตัน 2 วิ
            
            AffectsNPCConfig = true,
        },
        
        GhostTouch = {
            ID = 12,
            Name = "Ghost Touch",
            Description = "เก็บของแล้วไม่เกิดเสียง แต่ใช้ของได้ช้าลง",
            Icon = "rbxassetid://123456800",
            
            SilentItemPickup = true,
            
            -- จุดอ่อน
            ItemUsePenalty = 0.20, -- ช้าลง 20%
            
            AffectsGameplay = true,
        },
        
        Shortcut = {
            ID = 13,
            Name = "Shortcut",
            Description = "เข้าทางลับได้เร็วขึ้น",
            Icon = "rbxassetid://123456801",
            
            ShortcutSpeedBonus = 0.40,
            
            -- จุดอ่อน
            TitanKnowsShortcut = true, -- Titan รู้ตำแหน่ง
            
            AffectsNPCConfig = true,
        },
        
        Distraction = {
            ID = 14,
            Name = "Distraction",
            Description = "ขว้างของหลอกได้",
            Icon = "rbxassetid://123456802",
            
            CanThrowDistraction = true,
            DistractionDuration = 5,
            DistractionCooldown = 30,
            
            -- จุดอ่อน
            ShortTitanAlert = true, -- มีเสียงเตือน Titan สั้นๆ
            
            AffectsNPCConfig = true,
        },
        
        SteadyHands = {
            ID = 15,
            Name = "Steady Hands",
            Description = "Puzzle mini-game ช้าลงเล็กน้อย ง่ายขึ้น",
            Icon = "rbxassetid://123456803",
            
            PuzzleDifficultyReduction = 0.30,
            
            -- จุดอ่อน
            PuzzleTimePenalty = 0.15, -- เสียเวลารวมมากขึ้น 15%
            
            AffectsGameplay = true,
        },
        
        BloodLink = {
            ID = 16,
            Name = "Blood Link",
            Description = "ถ้าเพื่อนใกล้ถูกไล่ จะ Sprint ได้ 2 วิ",
            Icon = "rbxassetid://123456804",
            
            SprintOnTeammateChase = true,
            SprintDuration = 2,
            SprintCooldown = 60,
            TriggerRange = 20,
            
            AffectsPlayerConfig = true,
        },
        
        KeenHearing = {
            ID = 17,
            Name = "Keen Hearing",
            Description = "ได้ยิน Titan ชัดขึ้น",
            Icon = "rbxassetid://123456805",
            
            TitanSoundBonus = 0.50, -- ได้ยินชัดขึ้น 50%
            
            -- จุดอ่อน
            OtherSoundReduction = 0.30, -- เสียงอื่นเบาลง 30%
            
            AffectsAudio = true,
        },
        
        EchoTrace = {
            ID = 18,
            Name = "Echo Trace",
            Description = "มองเห็น 'เงาอดีต' Titan เดินผ่าน",
            Icon = "rbxassetid://123456806",
            
            ShowTitanGhostPath = true,
            GhostPathDuration = 15, -- แสดงรอย 15 วิที่ผ่านมา
            
            -- จุดอ่อน
            GhostPathAccuracy = 0.85, -- มีโอกาส 15% แสดงผิด
            
            AffectsUI = true,
        },
        
        Fearless = {
            ID = 19,
            Name = "Fearless",
            Description = "ไม่ติดสถานะกลัว",
            Icon = "rbxassetid://123456807",
            
            ImmuneFear = true,
            
            -- จุดอ่อน
            NoHeartbeatWarning = true, -- ไม่ได้ยินเสียงหัวใจ Titan
            
            AffectsGameplay = true,
            AffectsAudio = true,
        },
        
        SelfFocus = {
            ID = 20,
            Name = "Self Focus",
            Description = "ฟื้น stamina เร็วขึ้น 20%",
            Icon = "rbxassetid://123456808",
            
            StaminaRegenBonus = 0.20,
            
            -- จุดอ่อน
            HPDrainOnCaptureMultiplier = 1.30, -- HP ลดเร็วขึ้น 30% เมื่อโดนจับ
            
            AffectsPlayerConfig = true,
        },
    },
    
    -- ========================================
    -- ⚙️ System Settings
    -- ========================================
    MaxPerksPerPlayer = 3, -- ผู้เล่นเลือกได้สูงสุด 3 Perks
    PerkSlots = 3,



    
    -- Default Perk (ถ้าไม่เลือก)
    DefaultPerk = "SilentStep",
}