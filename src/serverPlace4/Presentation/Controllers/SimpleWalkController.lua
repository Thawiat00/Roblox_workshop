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


-- ✨ Phase 2 Services
local DetectionService = require(game.ServerScriptService.ServerLocal.Application.Services.DetectionService)
local ChaseService = require(game.ServerScriptService.ServerLocal.Application.Services.ChaseService)
local PathfindingLogicService = require(game.ServerScriptService.ServerLocal.Application.Services.PathfindingLogicService)

-- ✨ Phase 2 Helpers
local PathfindingHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.PathfindingHelper)
local DetectionHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.DetectionHelper)


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
	
	self.DetectionService = DetectionService.new(self.EnemyData) -- ✨ ใหม่
    self.ChaseService = ChaseService.new(self.EnemyData)         -- ✨ ใหม่
    self.PathfindingLogic = PathfindingLogicService.new()        -- ✨ ใหม่

	-- ==========================================
	-- โหลด Config
	-- ==========================================
	self.WalkDuration = SimpleAIConfig.WalkDuration      -- เดินนาน 5 วินาที
	self.IdleDuration = SimpleAIConfig.IdleDuration      -- หยุด 3 วินาที
	self.WanderRadius = SimpleAIConfig.WanderRadius      -- รัศมี 30 Studs
	self.MinWanderDistance = SimpleAIConfig.MinWanderDistance or 10
	
	self.DetectionRange = SimpleAIConfig.DetectionRange          -- ✨ ใหม่

        -- ✨ ใหม่: config สำหรับหยุดไล่
    self.ChaseStopRange = SimpleAIConfig.ChaseStopRange
    self.ChaseStopDelay = SimpleAIConfig.ChaseStopDelay


        -- ✨ ใหม่: ติดตามเวลาที่ player อยู่นอกระยะ
    self.OutOfRangeStartTime = nil



	-- ==========================================
	-- สร้าง Pathfinding (สำหรับหาเส้นทาง)
	-- ==========================================
	self.Path = PathfindingService:CreatePath({
		AgentRadius = SimpleAIConfig.AgentRadius,
		AgentHeight = SimpleAIConfig.AgentHeight,
		AgentCanJump = SimpleAIConfig.AgentCanJump
	})
	

        -- ✨ สร้าง OverlapParams
    self.OverlapParams = DetectionHelper.CreateOverlapParams(model)


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
	self.IsActive = true  -- ✅ ต้องเปิดให้ Loop ทำงาน
    self.IsChasing = false  -- ✅ ตั้งค่าเริ่มต้นเป็น false


	-- เริ่ม Loop หลัก (ทำงานแบบ Async ไม่ Block)
	--task.spawn(function()
	--	self:RandomWalkLoop()
	--end)


	  -- เริ่ม Main Loop (เดิน/หยุด)
    task.spawn(function()
        self:MainBehaviorLoop()
    end)


-- 🔹 เริ่มตรวจจับ player (Phase 2)
    task.spawn(function()
        self:DetectionLoop()
    end)
	
	print("[Controller] Initialized:", self.Model.Name)
end


-- ==========================================
-- ✨ DETECTION LOOP: ตรวจจับ player ทุก 0.1 วินาที
-- ==========================================
function SimpleWalkController:DetectionLoop()
    while self.IsActive and self.Humanoid.Health > 0 do
        
        -- ถ้ากำลังไล่อยู่ - เช็คว่า target ยังอยู่ในระยะหรือไม่
        if self.IsChasing and self.CurrentTarget then
            
            -- ✅ เช็คว่า target ยังมีชีวิตอยู่หรือไม่
            if not DetectionHelper.IsTargetValid(self.CurrentTarget) then
                print("[Controller] Target invalid, stopping chase")
                self:StopChasing()
                task.wait(SimpleAIConfig.DetectionCheckInterval)
                continue
            end
            
            -- ✅ เช็คระยะห่าง
            local isOutOfRange = DetectionHelper.IsTargetOutOfRange(
                self.RootPart.Position,
                self.CurrentTarget,
                self.ChaseStopRange
            )
            
            if isOutOfRange then
                -- ถ้าเพิ่งหลุดระยะ - เริ่มนับเวลา
                if not self.OutOfRangeStartTime then
                    self.OutOfRangeStartTime = tick()
                    print("[Controller] Target out of range, waiting before stop...")
                else
                    -- เช็คว่าหลุดระยะนานพอหรือยัง
                    local outOfRangeTime = tick() - self.OutOfRangeStartTime
                    if outOfRangeTime >= self.ChaseStopDelay then
                        print("[Controller] Target out of range too long, stopping chase")
                        self:StopChasing()
                    end
                end
            else
                -- ยังอยู่ในระยะ - รีเซ็ตตัวนับเวลา
                self.OutOfRangeStartTime = nil
            end
            
        -- ถ้าไม่ได้ไล่ - มองหา player ใหม่
        else
            local players = DetectionHelper.FindPlayersInRange(
                self.RootPart.Position,
                self.DetectionRange,
                self.OverlapParams
            )
            
            if #players > 0 then
                local nearestPlayer = DetectionHelper.FindNearestValidPlayer(
                    self.RootPart.Position,
                    players,
                    PathfindingHelper
                )
                
                if nearestPlayer then
                    self:StartChasing(nearestPlayer)
                end
            end
        end
        
        task.wait(SimpleAIConfig.DetectionCheckInterval)
    end
end


-- ==========================================
-- ✨ เริ่มไล่ player
-- ==========================================
function SimpleWalkController:StartChasing(targetPart)
    if self.IsChasing then
        -- ถ้ากำลังไล่อยู่แล้ว แค่เปลี่ยน target
        self.CurrentTarget = targetPart
        return
    end
    
    self.IsChasing = true
    self.CurrentTarget = targetPart
    self.OutOfRangeStartTime = nil  -- รีเซ็ตตัวนับเวลา
    
    self.DetectionService:StartDetection(targetPart)
    self.ChaseService:StartChase(targetPart)
    
    self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
    
    print("[Controller] Started chasing:", targetPart.Parent.Name)
    
    task.spawn(function()
        self:ChaseLoop(targetPart)
    end)
end



-- ==========================================
-- ✨ CHASE LOOP: ไล่ player ตาม waypoints
-- ==========================================
function SimpleWalkController:ChaseLoop(targetPart)
    while self.IsChasing and self.Humanoid.Health > 0 do
        
        if not self.CurrentTarget or not self.CurrentTarget.Parent then
            self:StopChasing()
            break
        end
        
        -- ใช้ target ปัจจุบัน (อาจเปลี่ยนได้ใน DetectionLoop)
        local success, waypoints = PathfindingHelper.ComputePath(
            self.Path,
            self.RootPart.Position,
            self.CurrentTarget.Position
        )
        
        if success and #waypoints > 1 then
            local nextWaypoint = waypoints[2]
            
            if PathfindingHelper.ShouldJump(nextWaypoint) then
                self.ChaseService:SetJumping()
                self.Humanoid.Jump = true
                task.wait(0.3)
                self.ChaseService:ResumeChase()
            end
            
            self.Humanoid:MoveTo(nextWaypoint.Position)
            
            local moveFinished = false
            local moveConnection = self.Humanoid.MoveToFinished:Connect(function()
                moveFinished = true
            end)
            
            local startTime = tick()
            repeat 
                task.wait(0.05)
                if tick() - startTime > 2 then
                    break
                end
            until moveFinished or not self.IsChasing
            
            moveConnection:Disconnect()
        else
            warn("[Controller] Path failed, moving directly")
            self.Humanoid:MoveTo(self.CurrentTarget.Position)
            task.wait(0.5)
        end
        
        task.wait(SimpleAIConfig.ChaseUpdateInterval)
    end
end


-- ==========================================
-- ✨ อัปเดต target ขณะไล่
-- ==========================================
function SimpleWalkController:UpdateChaseTarget(newTargetPart)
    if self.ChaseService:HasTarget() then
        self.ChaseService:StartChase(newTargetPart)
    end
end




-- ==========================================
-- ✨ หยุดไล่
-- ==========================================
function SimpleWalkController:StopChasing()

    if not self.IsChasing then
        return  -- ถ้าไม่ได้ไล่อยู่ ไม่ต้องทำอะไร
    end

        self.IsChasing = false
    self.CurrentTarget = nil
    self.OutOfRangeStartTime = nil
    
    -- เรียก Services
    self.ChaseService:StopChase()
    self.DetectionService:StopDetection()
    
    -- รีเซ็ตความเร็ว
    self.Humanoid.WalkSpeed = 0
    
    print("[Controller] Stopped chasing")
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
-- MAIN BEHAVIOR LOOP: เดิน/หยุด (ทำงานเมื่อไม่ได้ไล่)
-- ==========================================
function SimpleWalkController:MainBehaviorLoop()
    while self.IsActive and self.Humanoid.Health > 0 do
        
        -- ถ้ากำลังไล่อยู่ ข้ามไป
        if not self.IsChasing then
            
            -- Phase 1: เดิน
            self:StartWalking()
            task.wait(self.WalkDuration)
            
            -- Phase 2: หยุด
            if not self.IsChasing then
                self:PauseWalking()
                task.wait(self.IdleDuration)
            end
        else
            -- ถ้ากำลังไล่ รอ
            task.wait(0.5)
        end
    end
    
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

    if self.IsChasing then return end
    
    if not self.EnemyData then
        error("[Controller] EnemyData is nil!")
    end

    self.WalkService:StartWalking()
    self.EnemyData:SetState(AIState.Walk)
    self.EnemyData.CurrentSpeed = self.EnemyData.WalkSpeed
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
    self.ChaseService:StopChase()
    self.DetectionService:ResetDetection()
    self.Humanoid.WalkSpeed = 0
    self.IsChasing = false

    self.CurrentTarget = nil --ใหม่
    self.OutOfRangeStartTime = nil -- ใหม่
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
    if not self.EnemyData or self.IsChasing then
        return
    end

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
            if self.EnemyData and self.EnemyData.IsWalking and self.EnemyData:IsWalking() and not self.IsChasing then
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                self.Humanoid:MoveTo(waypoint.Position)
                
                local finished = false
                local moveConnection = self.Humanoid.MoveToFinished:Connect(function()
                    finished = true
                end)
                
                local timeoutStart = tick()
                repeat 
                    task.wait(0.1)
                    if self.IsChasing then break end
                until finished or (tick() - timeoutStart > 3)
                
                moveConnection:Disconnect()
            else
                break
            end
        end
    else
        self.Humanoid:MoveTo(targetPos)
        task.wait(2)
    end
end




-- ==========================================
-- Cleanup: ทำความสะอาดเมื่อไม่ใช้แล้ว
-- ==========================================
function SimpleWalkController:Destroy()
	-- ในอนาคตถ้ามี Connections จะ Disconnect ที่นี่
    self.IsActive = false
    self.IsChasing = false
    self.WalkService = nil
    self.ChaseService = nil
    self.DetectionService = nil
    self.EnemyData = nil
    print("[Controller] Destroyed:", self.Model.Name)
end

return SimpleWalkController