-- ==========================================
-- Presentation/Controllers/SimpleWalkController.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: ควบคุม Enemy จริงใน Roblox (ใช้ Roblox API)
-- เขียนทีหลังเพราะ: ต้องใช้ทุก Layer ที่เตรียมไว้แล้ว
-- หน้าที่: เชื่อมต่อ Business Logic กับ Roblox Instances
-- ==========================================


-- ==========================================
-- Presentation/Controllers/SimpleWalkController.lua (ModuleScript)
-- ==========================================
-- Phase 3: เพิ่ม Spear Dash & Knockback System
-- ==========================================


local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
local SimpleEnemyRepository = require(game.ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
local SimpleWalkService = require(game.ServerScriptService.ServerLocal.Application.Services.SimpleWalkService)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)


-- ✨ Phase 2 Services
local DetectionService = require(game.ServerScriptService.ServerLocal.Application.Services.DetectionService)
local ChaseService = require(game.ServerScriptService.ServerLocal.Application.Services.ChaseService)
local PathfindingLogicService = require(game.ServerScriptService.ServerLocal.Application.Services.PathfindingLogicService)

-- ✨ Phase 3 Service
local SpearDashService = require(game.ServerScriptService.ServerLocal.Application.Services.SpearDashService)





-- ✨ Phase 2 Helpers
local PathfindingHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.PathfindingHelper)
local DetectionHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.DetectionHelper)


-- ✨ Phase 3 Helper
local DashHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.DashHelper)



-- ✨ Phase 4 Helper
local ImpactHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.ImpactHelper)




-- Roblox Services
local PathfindingService = game:GetService("PathfindingService")



-- ✨ Phase 5: Sound Detection Service
local SoundDetectionService = require(game.ServerScriptService.ServerLocal.Application.Services.SoundDetectionService)



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
	

    -- ✨ เพิ่ม RootPart ให้ EnemyData (สำหรับ Phase 4)
    self.EnemyData.RootPart = self.RootPart



	-- ==========================================
	-- สร้าง Service (Business Logic)
	-- ==========================================
	self.WalkService = SimpleWalkService.new(self.EnemyData)
	
	self.DetectionService = DetectionService.new(self.EnemyData) -- ✨ ใหม่
    self.ChaseService = ChaseService.new(self.EnemyData)         -- ✨ ใหม่
    self.PathfindingLogic = PathfindingLogicService.new()        -- ✨ ใหม่

    -- ✨ Phase 3: Spear Dash Service
    self.DashService = SpearDashService.new(self.EnemyData)



    -- ✨ Phase 5: Sound Detection Service
    self.SoundDetectionService = SoundDetectionService.new(self.EnemyData, self.EnemyData.SoundData)



	-- ==========================================
	-- โหลด Config
	-- ==========================================
	self.WalkDuration = SimpleAIConfig.WalkDuration      -- เดินนาน 5 วินาที
	self.IdleDuration = SimpleAIConfig.IdleDuration      -- หยุด 3 วินาที
	self.WanderRadius = SimpleAIConfig.WanderRadius      -- รัศมี 30 Studs
	self.MinWanderDistance = SimpleAIConfig.MinWanderDistance or 10
	
	self.DetectionRange = SimpleAIConfig.DetectionRange          -- ✨ ใหม่



    -- ✨ Phase 5: Sound Config
    self.SoundRadius = SimpleAIConfig.SoundRadius
    self.SoundDuration = SimpleAIConfig.SoundDuration
    self.SoundHearingRange = SimpleAIConfig.SoundHearingRange
    self.SoundAlertDuration = SimpleAIConfig.SoundAlertDuration
    self.SoundReachThreshold = SimpleAIConfig.SoundReachThreshold
    self.SoundCheckInterval = SimpleAIConfig.SoundCheckInterval
    self.SoundVisualEffect = SimpleAIConfig.SoundVisualEffect





        -- ✨ ใหม่: config สำหรับหยุดไล่
    self.ChaseStopRange = SimpleAIConfig.ChaseStopRange
    self.ChaseStopDelay = SimpleAIConfig.ChaseStopDelay


    -- ✨ Phase 3: Dash Config
    self.DashMinDistance = SimpleAIConfig.DashMinDistance
    self.DashMaxDistance = SimpleAIConfig.DashMaxDistance
    self.DashCheckInterval = SimpleAIConfig.DashCheckInterval
    self.RecoverDuration = SimpleAIConfig.RecoverDuration


    -- ✨ Phase 4 Config
    self.ImpactForceMagnitude = SimpleAIConfig.ImpactForceMagnitude
    self.ImpactDuration = SimpleAIConfig.ImpactDuration
    self.ImpactDamage = SimpleAIConfig.ImpactDamage
    self.ImpactVisualEffect = SimpleAIConfig.ImpactVisualEffect


    -- State tracking
    self.OutOfRangeStartTime = nil
    self.OverlapParams = DetectionHelper.CreateOverlapParams(model)


    -- ✨ Phase 5: Sound State
    self.IsInvestigatingSound = false           -- กำลังตรวจสอบเสียงหรือไม่
    self.SoundInvestigationTarget = nil         -- ตำแหน่งเสียงที่กำลังไปตรวจสอบ




	-- ==========================================
	-- สร้าง Pathfinding (สำหรับหาเส้นทาง)
	-- ==========================================
	self.Path = PathfindingService:CreatePath({
		AgentRadius = SimpleAIConfig.AgentRadius,
		AgentHeight = SimpleAIConfig.AgentHeight,
		AgentCanJump = SimpleAIConfig.AgentCanJump
	})
	

    -- ✨ Phase 3: Setup Touched Connection สำหรับ Knockback
   --self:SetupKnockbackDetection()
    
    -- ✨ Phase 4: Setup Impact Detection
    self:SetupImpactDetection()



	-- เริ่มระบบ
	self:Initialize()
	
	return self
end

-- ==========================================
-- ✨ Phase 4: Setup Impact Detection
-- ==========================================
function SimpleWalkController:SetupImpactDetection()
    -- เชื่อม Touched event กับ RootPart
    self.TouchConnection = self.RootPart.Touched:Connect(function(hit)
        -- ตรวจสอบว่ากำลัง Dash อยู่หรือไม่
        if not self.DashService:IsDashing() then
            return
        end
        
        -- ตรวจสอบว่าเป็น Player หรือไม่
        local isPlayer, player = ImpactHelper.IsPlayerCharacter(hit)
        if not isPlayer then
            return
        end
        
        -- ดึง HumanoidRootPart ของ Player
        local playerRoot = ImpactHelper.GetPlayerRootPart(hit.Parent)
        if not playerRoot then
            return
        end
        
        -- ✨ เรียก OnDashHit พร้อม Impact Callback
        self.DashService:OnDashHit(hit.Parent, function(target, player, playerRoot)
            return self:HandlePlayerImpact(target, player, playerRoot)
        end)
    end)
    
    print("[Controller] ✅ Impact detection setup complete")
end


-- ==========================================
-- ✨ Phase 4: จัดการการกระแทก Player
-- ==========================================
function SimpleWalkController:HandlePlayerImpact(target, player, playerRoot)
    if not playerRoot or not self.RootPart then
        warn("[Controller] Cannot handle impact: missing root parts")
        return false
    end
    
    -- คำนวณแรงกระแทก
    local forceVector = ImpactHelper.CalculateImpactForce(
        self.RootPart,
        playerRoot,
        self.ImpactForceMagnitude
    )
    
    if not forceVector then
        warn("[Controller] Failed to calculate impact force")
        return false
    end
    
    -- ✨ Apply VectorForce ให้ Player
    local success = ImpactHelper.ApplyImpactForce(
        playerRoot,
        forceVector,
        self.ImpactDuration,
        SimpleAIConfig.ImpactGravityCompensation
    )
    
    if success then
        print("[Controller] 💥 Impact applied to:", player.Name)
        
        -- ✨ สร้าง Visual Effect (ถ้าเปิดใช้)
        if self.ImpactVisualEffect then
            ImpactHelper.CreateImpactEffect(playerRoot.Position)
        end
        
        return true
    else
        warn("[Controller] Failed to apply impact force")
        return false
    end
end







-- ==========================================
-- ✨ Phase 3: Setup Knockback Detection
-- ==========================================
function SimpleWalkController:SetupKnockbackDetection()
    -- เชื่อม Touched event กับ RootPart
    self.TouchConnection = self.RootPart.Touched:Connect(function(hit)
        -- ตรวจสอบว่ากำลัง Dash อยู่หรือไม่
        if not self.DashService:IsDashing() then
            return
        end
        
        -- ตรวจสอบว่าเป็น Player หรือไม่
        if not DashHelper.IsPlayerPart(hit) then
            return
        end
        
        -- ดึง HumanoidRootPart ของ Player
        local playerRootPart = DashHelper.GetPlayerRootPart(hit)
        if not playerRootPart then
            return
        end
        
        -- Apply Knockback
        local dashDirection = self.DashService:GetDashDirection()
        if dashDirection then
            local success = DashHelper.ApplyKnockback(playerRootPart, dashDirection)
            if success then
                print("[Controller] 💥 Knockback applied to:", hit.Parent.Name)
            end
        end
    end)
    
    print("[Controller] ✅ Knockback detection setup complete")
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

     -- ✨ Phase 3: Dash Check Loop
    task.spawn(function()
        self:DashCheckLoop()
    end)


       -- ✨ Phase 5: Sound Investigation Loop
    task.spawn(function()
        self:SoundInvestigationLoop()
    end)


	print("[Controller] Initialized:", self.Model.Name)
end


-- ==========================================
-- เพิ่มใน SimpleWalkController
-- ==========================================

-- ✨ Phase 5: Behavior Priority System
-- ความสำคัญ (สูง → ต่ำ):
-- 1. Dash/Recover
-- 2. Chase (มี target ชัดเจน)
-- 3. Sound Investigation (ได้ยินเสียง)
-- 4. Detection (กำลังตรวจจับ)
-- 5. Walk (เดินสำรวจปกติ)



function SimpleWalkController:GetCurrentBehaviorPriority()
    -- Priority 1: Dash/Recover (สูงสุด)
    if self.DashService:IsDashing() or self.DashService:IsRecovering() then
        return 1, "Dash/Recover"
    end
    
    -- Priority 2: Chase (มี target)
    if self.IsChasing and self.CurrentTarget then
        return 2, "Chase"
    end
    
    -- Priority 3: Sound Investigation
    if self.IsInvestigatingSound then
        return 3, "Sound Investigation"
    end
    
    -- Priority 4: Detection (กำลังตรวจจับแต่ยังไม่ได้ไล่)
    if self.DetectionService:IsDetecting() then
        return 4, "Detection"
    end
    
    -- Priority 5: Walk (ต่ำสุด)
    return 5, "Walk"
end


-- ==========================================
-- ✨ ตรวจสอบว่าสามารถเปลี่ยนพฤติกรรมได้หรือไม่
-- ==========================================
function SimpleWalkController:CanInterruptForBehavior(newPriority)
    local currentPriority, currentBehavior = self:GetCurrentBehaviorPriority()
    
    -- ถ้า priority ใหม่สูงกว่า = ขัดจังหวะได้
    if newPriority < currentPriority then
        print("[Controller] Interrupting", currentBehavior, "for new behavior (priority:", newPriority, ")")
        return true
    end
    
    return false
end



-- ==========================================
-- ✨ อัปเดต OnHearSound ให้ใช้ Priority
-- ==========================================
function SimpleWalkController:OnHearSound(soundPosition, soundSource)
    -- ตรวจสอบว่าอยู่ในระยะได้ยินหรือไม่
    if not self.SoundDetectionService:IsWithinHearingRange(self.RootPart.Position, soundPosition) then
        return false
    end
    
    -- ✅ ใช้ Priority System
    local soundInvestigationPriority = 3
    
    if not self:CanInterruptForBehavior(soundInvestigationPriority) then
        print("[Controller] Cannot interrupt current behavior for sound")
        return false
    end
    
    -- บันทึกเสียง
    local success = self.SoundDetectionService:OnHearSound(soundPosition, soundSource)
    
    if success then
        print("[Controller]", self.Model.Name, "heard sound from:", soundSource and soundSource.Name or "Unknown")
    end
    
    return success
end


-- ==========================================
-- ✨ Debug: แสดงสถานะปัจจุบัน
-- ==========================================
function SimpleWalkController:PrintCurrentStatus()
    local priority, behavior = self:GetCurrentBehaviorPriority()
    
    print("===========================================")
    print("[Controller Status]", self.Model.Name)
    print("  • Current Behavior:", behavior)
    print("  • Priority:", priority)
    print("  • IsChasing:", self.IsChasing)
    print("  • IsInvestigatingSound:", self.IsInvestigatingSound)
    print("  • IsDashing:", self.DashService:IsDashing())
    print("  • CurrentSpeed:", self.Humanoid.WalkSpeed)
    
    if self.CurrentTarget then
        print("  • Chase Target:", self.CurrentTarget.Parent and self.CurrentTarget.Parent.Name or "Unknown")
    end
    
    if self.SoundInvestigationTarget then
        print("  • Sound Target:", self.SoundInvestigationTarget)
    end
    
    print("===========================================")
end



-- ==========================================
-- ✨ Phase 5: SOUND INVESTIGATION LOOP
-- ตรวจสอบและตอบสนองต่อเสียงที่ได้ยิน
-- ==========================================
function SimpleWalkController:SoundInvestigationLoop()
    while self.IsActive and self.Humanoid.Health > 0 do
        
        -- ตรวจสอบว่ามีเสียงที่ต้องตรวจสอบหรือไม่
        if self.SoundDetectionService:IsAlerted() and not self.IsInvestigatingSound then
            -- เริ่มตรวจสอบเสียง
            self:StartSoundInvestigation()
        end
        
        -- ถ้ากำลังตรวจสอบเสียงอยู่
        if self.IsInvestigatingSound then
            -- ตรวจสอบว่า Alert หมดเวลาหรือยัง
            if self.SoundDetectionService:CheckAlertExpiry() then
                print("[Controller] Alert expired during investigation")
                self:StopSoundInvestigation()
            
            -- ตรวจสอบว่าควรหยุดตรวจสอบหรือไม่
            elseif self.SoundDetectionService:ShouldStopInvestigating() then
                print("[Controller] Investigation timeout or completed")
                self:StopSoundInvestigation()
            
            -- ตรวจสอบว่าถึงตำแหน่งเสียงแล้วหรือยัง
            elseif self.SoundInvestigationTarget then
                local SoundHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.SoundHelper)
                local distance = SoundHelper.GetDistance(
                    self.RootPart.Position,
                    self.SoundInvestigationTarget
                )
                
                if distance <= self.SoundReachThreshold then
                    print("[Controller] Reached sound location!")
                    self.SoundDetectionService:ReachedSoundLocation()
                    
                    -- รอสักครู่แล้วหยุด
                    task.wait(1.0)
                    self:StopSoundInvestigation()
                end
            end
        end
        
        task.wait(self.SoundCheckInterval or 0.2)
    end
end



-- ==========================================
-- ✨ Phase 5: เริ่มตรวจสอบเสียง
-- ==========================================
function SimpleWalkController:StartSoundInvestigation()
    if self.IsInvestigatingSound then
        return -- กำลังตรวจสอบอยู่แล้ว
    end
    
    -- ดึงตำแหน่งเสียง
    local soundPosition = self.SoundDetectionService:GetLastHeardPosition()
    if not soundPosition then
        warn("[Controller] Cannot investigate: no sound position")
        return
    end
    
    -- ตั้งค่าสถานะ
    self.IsInvestigatingSound = true
    self.SoundInvestigationTarget = soundPosition
    
    -- เรียก Service
    self.SoundDetectionService:StartInvestigation()
    
    -- ✅ หยุด Chase ถ้ากำลังไล่อยู่
    if self.IsChasing then
        print("[Controller] Stopping chase to investigate sound")
        self:StopChasing()
    end
    
    -- ตั้งความเร็ว
    self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
    
    print("[Controller] Started investigating sound at:", soundPosition)
    
    -- เริ่ม Investigation Movement Loop
    task.spawn(function()
        self:SoundInvestigationMovementLoop()
    end)
end



-- ==========================================
-- ✨ Phase 5: SOUND INVESTIGATION MOVEMENT LOOP
-- เคลื่อนที่ไปยังตำแหน่งเสียง
-- ==========================================
function SimpleWalkController:SoundInvestigationMovementLoop()
    local PathfindingHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.PathfindingHelper)
    
    while self.IsInvestigatingSound and self.IsActive and self.Humanoid.Health > 0 do
        
        -- ตรวจสอบว่ายังมีตำแหน่งเป้าหมายหรือไม่
        if not self.SoundInvestigationTarget then
            break
        end
        
        -- คำนวณ path ไปยังตำแหน่งเสียง
        local success, waypoints = PathfindingHelper.ComputePath(
            self.Path,
            self.RootPart.Position,
            self.SoundInvestigationTarget
        )
        
        if success and #waypoints > 1 then
            local nextWaypoint = waypoints[2]
            
            -- ตรวจสอบว่าต้องกระโดดหรือไม่
            if PathfindingHelper.ShouldJump(nextWaypoint) then
                self.Humanoid.Jump = true
                task.wait(0.3)
            end
            
            -- เคลื่อนที่ไปยัง waypoint
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
            until moveFinished or not self.IsInvestigatingSound
            
            moveConnection:Disconnect()
        else
            -- ถ้า pathfinding ล้มเหลว เดินตรงไป
            warn("[Controller] Path to sound failed, moving directly")
            self.Humanoid:MoveTo(self.SoundInvestigationTarget)
            task.wait(0.5)
        end
        
        task.wait(0.1) -- อัปเดตบ่อยเพื่อความแม่นยำ
    end
    
    print("[Controller] Sound investigation movement loop ended")
end


-- ==========================================
-- ✨ Phase 5: หยุดตรวจสอบเสียง
-- ==========================================
function SimpleWalkController:StopSoundInvestigation()
    if not self.IsInvestigatingSound then
        return
    end
    
    self.IsInvestigatingSound = false
    self.SoundInvestigationTarget = nil
    
    -- เรียก Service
    self.SoundDetectionService:CalmDown()
    
    -- หยุดเคลื่อนที่
    self.Humanoid.WalkSpeed = 0
    
    print("[Controller] Stopped sound investigation")
    
    -- กลับสู่พฤติกรรมปกติ (Idle)
    task.wait(0.5)
    self.Humanoid.WalkSpeed = self.EnemyData.WalkSpeed
end


-- ==========================================
-- ✨ Phase 5: Callback เมื่อได้ยินเสียง
-- ==========================================
function SimpleWalkController:OnHearSound(soundPosition, soundSource)
    -- ตรวจสอบว่าอยู่ในระยะได้ยินหรือไม่
    if not self.SoundDetectionService:IsWithinHearingRange(self.RootPart.Position, soundPosition) then
        return false
    end
    
    -- ✅ ถ้ากำลัง Chase อยู่ = ไม่สนใจเสียง (มี priority ต่ำกว่า)
    if self.IsChasing then
        print("[Controller] Ignoring sound, currently chasing")
        return false
    end
    
    -- ✅ ถ้ากำลัง Dash หรือ Recover = ไม่สนใจเสียง
    if self.DashService:IsDashing() or self.DashService:IsRecovering() then
        print("[Controller] Ignoring sound, currently dashing/recovering")
        return false
    end
    
    -- บันทึกเสียง
    local success = self.SoundDetectionService:OnHearSound(soundPosition, soundSource)
    
    if success then
        print("[Controller]", self.Model.Name, "heard sound from:", soundSource and soundSource.Name or "Unknown")
        
        -- เสียง Alert (optional)
        -- เล่นเสียงแจ้งเตือน
        -- PlayAlertSound(self.Model)
    end
    
    return success
end





-- ==========================================
-- ✨ Phase 3: DASH CHECK LOOP
-- ตรวจสอบโอกาสพุ่งเมื่อ Chase และอยู่ในระยะที่เหมาะสม
-- ==========================================
function SimpleWalkController:DashCheckLoop()
    while self.IsActive and self.Humanoid.Health > 0 do
        
        if self.IsChasing and self.CurrentTarget then
            print("[Debug] 🟢 DashCheckLoop active | Target:", self.CurrentTarget.Name)

            -- STEP 1: ตรวจสอบ cooldown
            local canDash = self.DashService:CanDash()
            print("[Debug] Step 1 | CanDash:", canDash)
            if not canDash then
                task.wait(self.DashCheckInterval)
                continue
            end

            -- STEP 2: ตรวจสอบว่า target มี Position ไหม
            if not (self.RootPart and self.CurrentTarget and self.CurrentTarget.Position) then
                warn("[Debug] Step 2 | Missing position data")
                task.wait(self.DashCheckInterval)
                continue
            end

            -- STEP 3: คำนวณระยะ
            local distance = DashHelper.GetDistance(
                self.RootPart.Position,
                self.CurrentTarget.Position
            )
            print("[Debug] Step 3 | Distance to target:", distance)

            -- STEP 4: ตรวจสอบว่าระยะอยู่ในช่วงหรือไม่
            local inRange = DashHelper.IsInDashRange(distance)
            if not inRange then
                task.wait(self.DashCheckInterval)
                continue
            end
          --  local inRange = DashHelper.IsInDashRange(distance)
          --  print("[Debug] Step 4 | InDashRange:", inRange, 
          --      "(Min:", self.DashMinDistance, 
          --      "Max:", self.DashMaxDistance, ")")
          --  if not inRange then
           --     task.wait(self.DashCheckInterval)
           --     continue
           -- end

            -- STEP 5: ตรวจสอบว่า ShouldDash ผ่านไหม
            local shouldDash = DashHelper.ShouldDash()
            print("[Debug] Step 5 | ShouldDash:", shouldDash)
            if not shouldDash then
                task.wait(self.DashCheckInterval)
                continue
            end

            -- STEP 6: ผ่านทุกเงื่อนไข เตรียมพุ่ง
            print("[Debug] ✅ All dash conditions met | Distance:", distance)
            self:StartDashing()
        end

        task.wait(self.DashCheckInterval)
    end
end



-- ==========================================
-- ✨ Phase 3: เริ่มพุ่ง
-- ==========================================
function SimpleWalkController:StartDashing()
    if not self.CurrentTarget then
        warn("[Controller] Cannot dash: no target")
        return
    end
    
     -- 🔹 เพิ่มการเช็คว่า target เป็น Player หรือไม่
    local player = game.Players:GetPlayerFromCharacter(self.CurrentTarget.Parent)
    if not player then
        warn("[Controller] Cannot dash: target is not a player")
        return
    end

       -- คำนวณทิศทางการพุ่ง
    local dashDirection = DashHelper.CalculateDashDirection(
        self.RootPart.Position,
        self.CurrentTarget.Position
    )


  --      -- สุ่มระยะเวลาการพุ่ง
  --  local dashDuration = DashHelper.GetRandomDashDuration()


   

    -- คำนวณทิศทางการพุ่ง
  --  local dashDirection = DashHelper.CalculateDashDirection(
  --      self.RootPart.Position,
  --      self.CurrentTarget.Position
  --  )
    
    -- สุ่มระยะเวลาการพุ่ง
    local dashDuration = DashHelper.GetRandomDashDuration()
    
    -- เรียก Service
    local success = self.DashService:StartDash(
        self.CurrentTarget,
        dashDirection,
        dashDuration
    )
    
    if success then
        -- อัปเดตความเร็ว Humanoid
        self.Humanoid.WalkSpeed = self.EnemyData.SpearSpeed
        
        print("[Controller] 🚀 Started dashing at speed:", self.EnemyData.SpearSpeed)
        
        -- เริ่ม Dash Loop
        task.spawn(function()
            self:DashLoop()
        end)
    end
end


-- ==========================================
-- ✨ Phase 3: DASH LOOP - พุ่งตรงไปยัง target
-- ==========================================
function SimpleWalkController:DashLoop()

 --   local hitPlayers = {} -- เก็บ Player ที่โดนแล้วเพื่อไม่กระเด็นซ้ำ

    while self.IsActive and self.Humanoid.Health > 0 and self.DashService:IsDashing() do
        
         -- ตรวจสอบว่า target ยังมีอยู่หรือไม่
        if not self.CurrentTarget or not self.CurrentTarget.Parent then
            print("[Controller] ❌ Target lost during dash")
            self.DashService:StopDash()
            break
        end
        
        -- 🔹 เพิ่มบรรทัดนี้: ตรวจ collision กับ player
        --self.DashService:OnDashHit(self.CurrentTarget.Parent)
        -- 🔹 ตรวจสอบเฉพาะ Player เท่านั้น
        local player = game.Players:GetPlayerFromCharacter(self.CurrentTarget.Parent)
        if not player then
            print("[Controller] ❌ Target is not a player, stopping dash")
            self.DashService:StopDash()
            break
        end


        -- เคลื่อนที่ตรงไปยัง target (ไม่ใช้ pathfinding)
        self.Humanoid:MoveTo(self.CurrentTarget.Position)


            -- 🔹 ตรวจสอบการชนกับ Player (ไม่ชนซ้ำ)
     --   if not hitPlayers[player] then
    --        self.DashService:OnDashHit(self.CurrentTarget.Parent)
     --       hitPlayers[player] = true -- mark ว่าโดนแล้ว
     --       print("[Controller] 💥 Hit player:", player.Name)
     --   end


        -- ตรวจสอบว่าครบเวลาพุ่งหรือยัง
        if self.DashService:IsDashComplete() then
            print("[Controller] ⏱️ Dash completed!")
            self:StartRecovering()
            break
        end
        
        task.wait(0.05) -- อัปเดตบ่อยเพื่อความแม่นยำ
    end
end


-- ==========================================
-- ✨ Phase 3: เข้าสู่สถานะ Recover
-- ==========================================
function SimpleWalkController:StartRecovering()
    self.DashService:StartRecover()
    self.Humanoid.WalkSpeed = 0
    
    print("[Controller] 😮‍💨 Recovering...")
    
    -- รอจนครบเวลา Recover
    task.wait(self.RecoverDuration)
    
    -- กลับไป Chase
    self.DashService:ResumeChase()
    self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
    
    print("[Controller] ✅ Recovery complete, resuming chase")
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
-- CHASE LOOP (Phase 2 - ปรับให้หยุดเมื่อ Dash)

-- ==========================================
function SimpleWalkController:ChaseLoop(targetPart)
    while self.IsChasing and self.Humanoid.Health > 0 do
        
        -- ✨ หยุด Chase ถ้ากำลัง Dash หรือ Recover
        if self.DashService:IsDashing() or self.DashService:IsRecovering() then
            task.wait(0.1)
            continue
        end
        


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
            until moveFinished or not self.IsChasing or self.DashService:IsDashing()
            
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
    
    -- ✨ หยุด Dash ด้วย (ถ้ากำลัง Dash อยู่)
    if self.DashService:IsDashing() then
        self.DashService:StopDash()
    end

    -- ✨ Phase 4: ล้างรายชื่อ Player ที่ชนแล้ว
    self.DashService:ClearImpactRecords()

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



       -- ✨ รีเซ็ต Dash
    self.DashService:StopDash()


     -- ✨ Phase 4: ล้างรายชื่อ Player ที่ชนแล้ว
    self.DashService:ClearImpactRecords()


    -- ✨ Phase 5: รีเซ็ต Sound Investigation
    if self.IsInvestigatingSound then
        self:StopSoundInvestigation()
    end
    self.SoundDetectionService:CalmDown()



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


       -- ✨ Disconnect Touch Connection
    if self.TouchConnection then
        self.TouchConnection:Disconnect()
        self.TouchConnection = nil
    end


     -- ✨ Phase 5: หยุด Sound Investigation
    if self.IsInvestigatingSound then
        self:StopSoundInvestigation()
    end


    self.WalkService = nil
    self.ChaseService = nil
    self.DetectionService = nil

    self.DashService = nil
    self.SoundDetectionService = nil  -- ✨ Phase 5

    self.EnemyData = nil
    print("[Controller] Destroyed:", self.Model.Name)
end

return SimpleWalkController