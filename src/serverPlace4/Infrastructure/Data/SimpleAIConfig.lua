local SimpleAIConfig = {
		-- ความเร็ว
	WalkSpeed = 8,
	  RunSpeed = 15,  -- ✨ ใหม่: ความเร็วตอนไล่
	
	-- ช่วงเวลา
	WalkDuration = 5,
	IdleDuration = 3,
	
	-- พื้นที่เดิน
	WanderRadius = 30,
	MinWanderDistance = 10,


	-- ✨ ใหม่: Detection Config
    DetectionRange = 20,      -- ระยะตรวจจับ player (studs)
    DetectionCheckInterval = 0.1, -- ตรวจทุก 0.1 วินาที
	
	    -- ✨ ใหม่: ระยะหยุดไล่
    ChaseStopRange = 40,           -- ถ้า player ห่างเกิน 40 studs = หยุดไล่
    ChaseStopDelay = 2,            -- รอ 2 วินาทีหลังหลุดระยะก่อนหยุด (ป้องกันกระพริบ)


	-- ✨ ใหม่: Chase Config
    ChaseUpdateInterval = 0.1,  -- อัปเดต path ทุก 0.1 วินาที
    WaypointSpacing = 32,       -- ระยะห่าง waypoint

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