local SimpleAIConfig = {
		-- ความเร็ว
	WalkSpeed = 8,
	
	-- ช่วงเวลา
	WalkDuration = 5,
	IdleDuration = 3,
	
	-- พื้นที่เดิน
	WanderRadius = 30,
	MinWanderDistance = 10,
	
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