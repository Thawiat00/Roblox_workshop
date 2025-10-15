-- ==========================================
-- Presentation/Controllers/Behaviors/DashBehavior.lua
-- ==========================================
-- วัตถุประสงค์: จัดการพฤติกรรมการพุ่ง (Dash & Recover)
-- ==========================================

local DashHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.DashHelper)
local ImpactHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.ImpactHelper)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local DashBehavior = {}
DashBehavior.__index = DashBehavior

-- ==========================================
-- Constructor
-- ==========================================
function DashBehavior.new(controller)
    local self = setmetatable({}, DashBehavior)
    
    self.Controller = controller
    self.EnemyData = controller.EnemyData
    self.Humanoid = controller.Humanoid
    self.RootPart = controller.RootPart
    
    self.DashMinDistance = controller.DashMinDistance
    self.DashMaxDistance = controller.DashMaxDistance
    self.DashCheckInterval = controller.DashCheckInterval
    self.RecoverDuration = controller.RecoverDuration
    
    -- Setup Impact Detection
    self:SetupImpactDetection()
    
    return self
end

-- ==========================================
-- ✨ Setup Impact Detection
-- ==========================================
function DashBehavior:SetupImpactDetection()
    self.TouchConnection = self.RootPart.Touched:Connect(function(hit)
        if not self.Controller.DashService:IsDashing() then
            return
        end
        
        local isPlayer, player = ImpactHelper.IsPlayerCharacter(hit)
        if not isPlayer then return end
        
        local playerRoot = ImpactHelper.GetPlayerRootPart(hit.Parent)
        if not playerRoot then return end
        
        -- เรียก Impact Callback
        self.Controller.DashService:OnDashHit(hit.Parent, function(target, player, playerRoot)
            return self:HandlePlayerImpact(target, player, playerRoot)
        end)
    end)
    
    print("[DashBehavior] ✅ Impact detection setup complete")
end

-- ==========================================
-- ✨ จัดการการกระแทก Player
-- ==========================================
function DashBehavior:HandlePlayerImpact(target, player, playerRoot)
    if not playerRoot or not self.RootPart then
        warn("[DashBehavior] Cannot handle impact: missing root parts")
        return false
    end
    
    -- คำนวณแรงกระแทก
    local forceVector = ImpactHelper.CalculateImpactForce(
        self.RootPart,
        playerRoot,
        self.Controller.ImpactForceMagnitude
    )
    
    if not forceVector then
        warn("[DashBehavior] Failed to calculate impact force")
        return false
    end
    
    -- Apply VectorForce
    local success = ImpactHelper.ApplyImpactForce(
        playerRoot,
        forceVector,
        self.Controller.ImpactDuration,
        SimpleAIConfig.ImpactGravityCompensation
    )
    
    if success then
        print("[DashBehavior] 💥 Impact applied to:", player.Name)
        
        if self.Controller.ImpactVisualEffect then
            ImpactHelper.CreateImpactEffect(playerRoot.Position)
        end
        
        return true
    else
        warn("[DashBehavior] Failed to apply impact force")
        return false
    end
end

-- ==========================================
-- ✨ เริ่ม Dash Check Loop
-- ==========================================
function DashBehavior:StartDashCheckLoop()
    task.spawn(function()
        while self.Controller.IsActive and self.Humanoid.Health > 0 do
            
            if self.Controller.IsChasing and self.Controller.CurrentTarget then
                
                -- STEP 1: ตรวจสอบ cooldown
                local canDash = self.Controller.DashService:CanDash()
                if not canDash then
                    task.wait(self.DashCheckInterval)
                    continue
                end
                
                -- STEP 2: ตรวจสอบว่า target มี Position ไหม
                if not (self.RootPart and self.Controller.CurrentTarget and self.Controller.CurrentTarget.Position) then
                    task.wait(self.DashCheckInterval)
                    continue
                end
                
                -- STEP 3: คำนวณระยะ
                local distance = DashHelper.GetDistance(
                    self.RootPart.Position,
                    self.Controller.CurrentTarget.Position
                )
                
                -- STEP 4: ตรวจสอบว่าอยู่ในช่วง
                local inRange = DashHelper.IsInDashRange(distance)
                if not inRange then
                    task.wait(self.DashCheckInterval)
                    continue
                end
                
                -- STEP 5: ตรวจสอบว่า ShouldDash
                local shouldDash = DashHelper.ShouldDash()
                if not shouldDash then
                    task.wait(self.DashCheckInterval)
                    continue
                end
                
                -- STEP 6: เตรียมพุ่ง
                print("[DashBehavior] ✅ All dash conditions met | Distance:", distance)
                self:StartDashing()
            end
            
            task.wait(self.DashCheckInterval)
        end
    end)
end

-- ==========================================
-- ✨ เริ่มพุ่ง
-- ==========================================
function DashBehavior:StartDashing()
    if not self.Controller.CurrentTarget then
        warn("[DashBehavior] Cannot dash: no target")
        return
    end
    
    -- ตรวจสอบว่า target เป็น Player
    local player = game.Players:GetPlayerFromCharacter(self.Controller.CurrentTarget.Parent)
    if not player then
        warn("[DashBehavior] Cannot dash: target is not a player")
        return
    end
    
    -- คำนวณทิศทาง
    local dashDirection = DashHelper.CalculateDashDirection(
        self.RootPart.Position,
        self.Controller.CurrentTarget.Position
    )
    
    local dashDuration = DashHelper.GetRandomDashDuration()
    
    -- เรียก Service
    local success = self.Controller.DashService:StartDash(
        self.Controller.CurrentTarget,
        dashDirection,
        dashDuration
    )
    
    if success then
        self.Humanoid.WalkSpeed = self.EnemyData.SpearSpeed
        print("[DashBehavior] 🚀 Started dashing at speed:", self.EnemyData.SpearSpeed)
        
        task.spawn(function()
            self:DashLoop()
        end)
    end
end

-- ==========================================
-- ✨ Dash Loop
-- ==========================================
function DashBehavior:DashLoop()
    while self.Controller.IsActive and self.Humanoid.Health > 0 and self.Controller.DashService:IsDashing() do
        
        if not self.Controller.CurrentTarget or not self.Controller.CurrentTarget.Parent then
            print("[DashBehavior] ❌ Target lost during dash")
            self.Controller.DashService:StopDash()
            break
        end
        
        local player = game.Players:GetPlayerFromCharacter(self.Controller.CurrentTarget.Parent)
        if not player then
            print("[DashBehavior] ❌ Target is not a player, stopping dash")
            self.Controller.DashService:StopDash()
            break
        end
        
        -- เคลื่อนที่ตรงไปยัง target
        self.Humanoid:MoveTo(self.Controller.CurrentTarget.Position)
        
        -- ตรวจสอบว่าครบเวลา
        if self.Controller.DashService:IsDashComplete() then
            print("[DashBehavior] ⏱️ Dash completed!")
            self:StartRecovering()
            break
        end
        
        task.wait(0.05)
    end
end

-- ==========================================
-- ✨ เข้าสู่สถานะ Recover
-- ==========================================
function DashBehavior:StartRecovering()
    self.Controller.DashService:StartRecover()
    self.Humanoid.WalkSpeed = 0
    
    print("[DashBehavior] 😮‍💨 Recovering...")
    
    task.wait(self.RecoverDuration)
    
    self.Controller.DashService:ResumeChase()
    self.Humanoid.WalkSpeed = self.EnemyData.RunSpeed
    
    print("[DashBehavior] ✅ Recovery complete, resuming chase")
end

-- ==========================================
-- ✨ Cleanup
-- ==========================================
function DashBehavior:Destroy()
    if self.TouchConnection then
        self.TouchConnection:Disconnect()
        self.TouchConnection = nil
    end
end

return DashBehavior