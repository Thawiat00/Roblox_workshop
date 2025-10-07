-- ==========================================
-- Presentation/Controllers/SimpleWalkController.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: ควบคุม Enemy จริงใน Roblox (ใช้ Roblox API)
-- เขียนทีหลังเพราะ: ต้องใช้ทุก Layer ที่เตรียมไว้แล้ว
-- หน้าที่: เชื่อมต่อ Business Logic กับ Roblox Instances
-- ==========================================

local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
local SimpleEnemyRepository = require(game.ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
local SimpleWalkService = require(game.ServerScriptService.ServerLocal.Application.Services.SimpleWalkService)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

-- Roblox Services
local PathfindingService = game:GetService("PathfindingService")

local SimpleWalkController = {}
SimpleWalkController.__index = SimpleWalkController

-- ==========================================
-- Constructor: สร้าง Controller สำหรับ Enemy 1 ตัว
-- ==========================================
function SimpleWalkController.new(model)
	local self = setmetatable({}, SimpleWalkController)
	
	-- ==========================================
	-- ROBLOX INSTANCES (Layer นี้เท่านั้นที่เข้าถึงได้)
	-- ==========================================
	self.Model = model
	self.Humanoid = model:WaitForChild("Humanoid")
	self.RootPart = model:WaitForChild("HumanoidRootPart")
	
	-- ==========================================
	-- สร้าง Repository และ Entity
	-- ==========================================
	local repository = SimpleEnemyRepository.new()
	self.EnemyData = repository:CreateSimpleEnemy(model)
	
	-- ==========================================
	-- สร้าง Service (Business Logic)
	-- ==========================================
	self.WalkService = SimpleWalkService.new(self.EnemyData)
	
	-- ==========================================
	-- โหลด Config
	-- ==========================================
	self.WalkDuration = SimpleAIConfig.WalkDuration      -- เดินนาน 5 วินาที
	self.IdleDuration = SimpleAIConfig.IdleDuration      -- หยุด 3 วินาที
	self.WanderRadius = SimpleAIConfig.WanderRadius      -- รัศมี 30 Studs
	self.MinWanderDistance = SimpleAIConfig.MinWanderDistance or 10
	
	-- ==========================================
	-- สร้าง Pathfinding (สำหรับหาเส้นทาง)
	-- ==========================================
	self.Path = PathfindingService:CreatePath({
		AgentRadius = SimpleAIConfig.AgentRadius,
		AgentHeight = SimpleAIConfig.AgentHeight,
		AgentCanJump = SimpleAIConfig.AgentCanJump
	})
	
	-- เริ่มระบบ
	self:Initialize()
	
	return self
end

-- ==========================================
-- Initialize: ตั้งค่าเริ่มต้นและเริ่ม Loop
-- ==========================================
function SimpleWalkController:Initialize()
	-- ตั้งความเร็วเริ่มต้นเป็น 0 (หยุดก่อน)
	self.Humanoid.WalkSpeed = 0
	
	-- เริ่ม Loop หลัก (ทำงานแบบ Async ไม่ Block)
	task.spawn(function()
		self:RandomWalkLoop()
	end)
	
	print("[Controller] Initialized:", self.Model.Name)
end

-- ==========================================
-- MAIN LOOP: วนซ้ำเดิน → หยุด → เดิน
-- ==========================================
function SimpleWalkController:RandomWalkLoop()
	-- วนไปเรื่อยๆ จนกว่าจะตาย
	while self.Humanoid.Health > 0 do
		
		-- ==========================================
		-- Phase 1: เริ่มเดิน
		-- ==========================================
		self:StartWalking()
		
		-- เดินต่อเนื่อง (ตาม WalkDuration)
		task.wait(self.WalkDuration)
		
		-- ==========================================
		-- Phase 2: หยุดพัก
		-- ==========================================
		self:PauseWalking()
		
		-- หยุดพัก (ตาม IdleDuration)
		task.wait(self.IdleDuration)
		
		-- วนซ้ำไปเรื่อยๆ
	end
	
	-- ถ้าตายแล้ว ทำความสะอาด
	print("[Controller]", self.Model.Name, "died. Stopping AI.")
end

-- ==========================================
-- เริ่มเดิน: เรียก Service + อัปเดต Roblox
-- ==========================================

local function tableKeysToString(t)
    if type(t) ~= "table" then return tostring(t) end
    local keys = {}
    for k,_ in pairs(t) do table.insert(keys, tostring(k)) end
    return "[" .. table.concat(keys, ", ") .. "]"
end



function SimpleWalkController:StartWalking()

    if not self.EnemyData then
        error("[Controller] EnemyData is nil or missing required fields!")
    end

    if type(self.EnemyData.SetState) ~= "function" then
        error(("[Controller] EnemyData.SetState missing or not a function. EnemyData keys: %s")
              :format(tableKeysToString(self.EnemyData)))
    end

    if not self.WalkService or type(self.WalkService.StartWalking) ~= "function" then
        error("[Controller] WalkService is nil or missing required fields!")
    end

    self.WalkService:StartWalking()

    self.EnemyData:SetState("Walk")
    self.EnemyData.CurrentSpeed = self.WalkService.CurrentSpeed or self.EnemyData.WalkSpeed
    self.Humanoid.WalkSpeed = self.EnemyData.CurrentSpeed

    local randomPosition = self:GetRandomPosition()
    self:MoveToPosition(randomPosition)
end



-- ==========================================
-- หยุดเดิน: เรียก Service + อัปเดต Roblox
-- ==========================================
function SimpleWalkController:PauseWalking()
    -- ✅ ป้องกัน error กรณี WalkService ยังไม่ถูก inject
    if self.WalkService then
        self.WalkService:PauseWalk()
    else
        warn("[SimpleWalkController] WalkService is nil when trying to pause walking")
    end

if self.EnemyData then
    if self.EnemyData.SetState then
        self.EnemyData:SetState("Idle")
    else
        -- ถ้าไม่มี method SetState ก็ fallback ตั้งค่า state ตรง ๆ
        self.EnemyData.CurrentState = "Idle"
    end

    self.EnemyData.CurrentSpeed = 0
end


    if self.Humanoid then
        self.Humanoid.WalkSpeed = 0
    else
        warn("[SimpleWalkController] Humanoid is nil when trying to pause walking")
    end
end

-- ==========================================
-- รีเซ็ต: กลับสู่สภาพเริ่มต้น
-- ==========================================
function SimpleWalkController:Reset()
	self.WalkService:Reset()
	self.Humanoid.WalkSpeed = 0
end

-- ==========================================
-- สุ่มตำแหน่งใหม่: ภายในรัศมีที่กำหนด
-- ==========================================
function SimpleWalkController:GetRandomPosition()
	local currentPos = self.RootPart.Position
	
	-- สุ่มมุม (0-360 องศา)
	local randomAngle = math.random() * math.pi * 2
	
	-- สุ่มระยะทาง (ระหว่าง Min ถึง Max)
	local randomDistance = math.random(
		self.MinWanderDistance,
		self.WanderRadius
	)
	
	-- คำนวณตำแหน่งใหม่ (วงกลมรอบตัว)
	local offsetX = math.cos(randomAngle) * randomDistance
	local offsetZ = math.sin(randomAngle) * randomDistance
	
	return Vector3.new(
		currentPos.X + offsetX,
		currentPos.Y,  -- Y เท่าเดิม (ไม่บินขึ้นลง)
		currentPos.Z + offsetZ
	)
end

-- ==========================================
-- เดินไปยังตำแหน่ง: ใช้ Pathfinding
-- ==========================================
function SimpleWalkController:MoveToPosition(targetPos)
    if not self.EnemyData then
        warn("[Controller] EnemyData missing")
        return
    end

    -- fallback ถ้าไม่มีฟังก์ชัน IsWalking ให้สร้าง
    if type(self.EnemyData.IsWalking) ~= "function" then
        self.EnemyData.IsWalking = function(self) 
            return (self.CurrentSpeed or 0) > 0
        end
    end

    local success = pcall(function()
        self.Path:ComputeAsync(self.RootPart.Position, targetPos)
    end)

    if success and self.Path.Status == Enum.PathStatus.Success then
        local waypoints = self.Path:GetWaypoints()
        for i, waypoint in ipairs(waypoints) do
            -- ตรวจสอบอีกครั้งเผื่อเป็น nil
            if self.EnemyData and self.EnemyData.IsWalking and self.EnemyData:IsWalking() then
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                self.Humanoid:MoveTo(waypoint.Position)
                local finished = false
                local moveConnection = self.Humanoid.MoveToFinished:Connect(function()
                    finished = true
                end)
                local timeoutConnection = task.delay(3, function()
                    finished = true
                end)
                repeat task.wait(0.1) until finished
                moveConnection:Disconnect()
                task.cancel(timeoutConnection)
            else
                break
            end
        end
    else
        warn("[Controller] Pathfinding failed, walking directly")
        self.Humanoid:MoveTo(targetPos)
        task.wait(2)
    end
end




-- ==========================================
-- Cleanup: ทำความสะอาดเมื่อไม่ใช้แล้ว
-- ==========================================
function SimpleWalkController:Destroy()
	-- ในอนาคตถ้ามี Connections จะ Disconnect ที่นี่
	self.WalkService = nil
	self.EnemyData = nil
	print("[Controller] Destroyed:", self.Model.Name)
end

return SimpleWalkController