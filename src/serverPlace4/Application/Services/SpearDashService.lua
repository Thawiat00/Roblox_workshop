-- ==========================================
-- Application/Services/SpearDashService.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Business Logic การพุ่งใส่ player
-- ไม่มี Roblox API: Logic บริสุทธิ์
-- ==========================================

local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)

local SpearDashService = {}
SpearDashService.__index = SpearDashService

-- ==========================================
-- Constructor
-- ==========================================
function SpearDashService.new(enemyData)
    local self = setmetatable({}, SpearDashService)
    self.EnemyData = enemyData
    return self
end

-- ==========================================
-- ✨ เริ่มพุ่ง (Start Dash)
-- ==========================================
function SpearDashService:StartDash(target, direction, duration)
    if not target then
        warn("[SpearDashService] Cannot start dash: target is nil")
        return false
    end
    
    if not direction then
        warn("[SpearDashService] Cannot start dash: direction is nil")
        return false
    end
    
    -- ตั้งค่า target และทิศทาง
    self.EnemyData:SetTarget(target)
    
    -- ตั้งค่าการพุ่ง
    local dashDuration = duration or self.EnemyData.DashDuration
    self.EnemyData:SetDashDuration(dashDuration)
    self.EnemyData:StartDash(direction, tick())
    
    -- เปลี่ยนความเร็วเป็น SpearSpeed
    self.EnemyData:SetSpeed(self.EnemyData.SpearSpeed)
    
    -- เปลี่ยน state เป็น SpearDash
    self.EnemyData:SetState(AIState.SpearDash)
    
    print("[SpearDashService] Started dash - Speed:", self.EnemyData.SpearSpeed, "Duration:", dashDuration)
    return true
end

-- ==========================================
-- ✨ หยุดพุ่ง (Stop Dash)
-- ==========================================
function SpearDashService:StopDash()
    -- ล้างข้อมูลการพุ่ง
    self.EnemyData:StopDash()
    
    -- หยุดเคลื่อนที่
    self.EnemyData:SetSpeed(0)
    
    print("[SpearDashService] Stopped dash")
end

-- ==========================================
-- ✨ เข้าสู่สถานะ Recover (พักหลังพุ่ง)
-- ==========================================
function SpearDashService:StartRecover()
    self.EnemyData:StopDash()
    self.EnemyData:SetSpeed(0)
    self.EnemyData:SetState(AIState.Recover)
    
    print("[SpearDashService] Entering recovery state")
end

-- ==========================================
-- ✨ กลับไปสถานะ Chase หลัง Recover
-- ==========================================
function SpearDashService:ResumeChase()
    if self.EnemyData:HasTarget() then
        self.EnemyData:SetSpeed(self.EnemyData.RunSpeed)
        self.EnemyData:SetState(AIState.Chase)
        print("[SpearDashService] Resumed chasing after recovery")
    else
        self.EnemyData:SetSpeed(0)
        self.EnemyData:SetState(AIState.Idle)
        print("[SpearDashService] No target, returning to idle")
    end
end



-- ==========================================
-- ✨ ตรวจการชนระหว่าง Dash (Knockback)
-- ==========================================
function SpearDashService:OnDashHit(target)
    if not target then return end

    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local rootPart = target:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    -- ✅ ให้กระเด็นเฉพาะ Player เท่านั้น
    local player = game.Players:GetPlayerFromCharacter(target)
    if not player then
        print("[SpearDashService] Target is not a player, skipping knockback")
        return
    end
    
    -- คำนวณทิศทางการกระเด็น
    local enemyRoot = self.EnemyData.RootPart
    if not enemyRoot or not enemyRoot:IsA("BasePart") then return end
    
    local direction = (rootPart.Position - enemyRoot.Position).Unit
    local knockbackDirection = Vector3.new(direction.X, 0.5, direction.Z).Unit
    
    -- กำหนดแรงกระเด็น
    local knockbackPower = 2000
    local upwardForce = 500
    
    local knockbackVector = Vector3.new(
        knockbackDirection.X * knockbackPower,
        upwardForce,
        knockbackDirection.Z * knockbackPower
    )
    
    -- 🔹 ส่งไปให้ Client ทำการกระเด็นเอง (เพราะ Client มี Network Ownership)
    local remoteEvent = game.ReplicatedStorage:FindFirstChild("ApplyKnockback")
    if remoteEvent then
        remoteEvent:FireClient(player, knockbackVector)
        print("[SpearDashService] 💥 Sent knockback to player:", player.Name)
    else
        warn("[SpearDashService] ApplyKnockback RemoteEvent not found!")
    end
    
    -- ทำ damage
    if humanoid and humanoid.Health > 0 then
        local damage = self.EnemyData.DashDamage or 10
        humanoid:TakeDamage(damage)
    end
end


-- ==========================================
-- Getters
-- ==========================================
function SpearDashService:IsDashing()
    return self.EnemyData:IsDashingState()
end

function SpearDashService:IsRecovering()
    return self.EnemyData:IsRecovering()
end

function SpearDashService:CanDash()
    return self.EnemyData:CanDash(tick())
end

function SpearDashService:IsDashComplete()
    return self.EnemyData:IsDashComplete(tick())
end

function SpearDashService:GetDashDirection()
    return self.EnemyData.DashDirection
end

function SpearDashService:GetDashElapsedTime()
    return self.EnemyData:GetDashElapsedTime(tick())
end

return SpearDashService