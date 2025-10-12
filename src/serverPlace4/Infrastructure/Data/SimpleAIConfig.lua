local SimpleAIConfig = {
		-- ความเร็ว
	WalkSpeed = 8,
	RunSpeed = 30,  -- ✨ ใหม่: ความเร็วตอนไล่


	-- ✨ Phase 3: Spear Dash Speed
    SpearSpeed = 60,                    -- ความเร็วตอนพุ่ง (เร็วกว่า RunSpeed 2 เท่า)
	
	-- ช่วงเวลา
	WalkDuration = 5,
	IdleDuration = 3,
	
	-- พื้นที่เดิน
	WanderRadius = 30,
	MinWanderDistance = 10,


	-- ✨ ใหม่: Detection Config
    DetectionRange = 60,      -- ระยะตรวจจับ player (studs)
    DetectionCheckInterval = 0.1, -- ตรวจทุก 0.1 วินาที
	


	    -- ✨ ใหม่: ระยะหยุดไล่
    ChaseStopRange = 40,           -- ถ้า player ห่างเกิน 40 studs = หยุดไล่
    ChaseStopDelay = 2,            -- รอ 2 วินาทีหลังหลุดระยะก่อนหยุด (ป้องกันกระพริบ)


	-- ✨ ใหม่: Chase Config
    ChaseUpdateInterval = 0.1,  -- อัปเดต path ทุก 0.1 วินาที
    WaypointSpacing = 32,       -- ระยะห่าง waypoint


	-- ✨ Phase 3: Spear Dash Config
  --  DashMinDistance = 60,               -- ระยะขั้นต่ำที่จะพุ่ง (studs)
  --  DashMaxDistance = 100,              -- ระยะสูงสุดที่จะพุ่ง (studs)
	DashMinDistance = 2,
	DashMaxDistance = 25,



    DashDurationMin = 3,                -- ระยะเวลาพุ่งขั้นต่ำ (วินาที)
    DashDurationMax = 4,                -- ระยะเวลาพุ่งสูงสุด (วินาที)
    DashCooldown = 8,                   -- คูลดาวน์ระหว่างการพุ่ง (วินาที)
    DashChance = 0.3,                   -- โอกาสที่จะพุ่ง (30%)
    DashCheckInterval = 0.5,            -- เช็คโอกาสพุ่งทุก 0.5 วินาที


	-- ✨ Phase 3: Knockback Config
    KnockbackForce = 1500,              -- แรงกระเด็น (Base value)
    KnockbackUpwardMultiplier = 0.3,    -- แรงกระเด็นขึ้น (30% ของแรงหลัก)
    
    -- ✨ Phase 3: Recovery Config
    RecoverDuration = 1.5,              -- ระยะเวลาพักหลังพุ่ง (วินาที)
    


	-- ✨ Phase 4: Impact System Config
    ImpactForceMagnitude = 1500,        -- แรงกระแทกพื้นฐาน
    ImpactDuration = 0.2,               -- ระยะเวลาที่แรงส่งผล (วินาที)
    ImpactMassMultiplier = 1.2,         -- คูณแรงด้วยน้ำหนัก Player
    ImpactGravityCompensation = true,   -- ชดเชยแรงโน้มถ่วง
    ImpactDamage = 15,                  -- ความเสียหายเมื่อชน
    ImpactRecoveryTime = 0.5,           -- เวลา recovery หลังโดนชน
    ImpactVisualEffect = true,          -- แสดงเอฟเฟกต์เมื่อชน
    ImpactPreventDoubleHit = true,      -- ป้องกันชนซ้ำในรอบ Dash เดียวกัน



	-- Pathfinding
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,

	-- Default properties สำหรับ enemyData
	DefaultState = "Idle",
	DefaultIsWalking = false,
	DefaultCurrentSpeed = 0,


    
}

return SimpleAIConfig