-- ==========================================
-- Infrastructure/utility/DashHelper.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: Helper functions สำหรับระบบ Spear Dash
-- มี Roblox API: ใช้ ApplyImpulse, Vector3
-- ==========================================

local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local DashHelper = {}

-- ==========================================
-- คำนวณทิศทางการพุ่ง
-- ==========================================
function DashHelper.CalculateDashDirection(fromPosition, toPosition)
    local direction = (toPosition - fromPosition).Unit
    return direction
end

-- ==========================================
-- ตรวจสอบว่าอยู่ในระยะที่เหมาะจะพุ่งหรือไม่
-- ==========================================
function DashHelper.IsInDashRange(distance)
    return distance >= SimpleAIConfig.DashMinDistance 
       and distance <= SimpleAIConfig.DashMaxDistance
end

-- ==========================================
-- สุ่มว่าจะพุ่งหรือไม่ (ตาม DashChance)
-- ==========================================
function DashHelper.ShouldDash()
    return math.random() <= SimpleAIConfig.DashChance
end

-- ==========================================
-- สุ่มระยะเวลาการพุ่ง
-- ==========================================
function DashHelper.GetRandomDashDuration()
    return math.random() * 
           (SimpleAIConfig.DashDurationMax - SimpleAIConfig.DashDurationMin) 
           + SimpleAIConfig.DashDurationMin
end

-- ==========================================
-- ✨ Apply Knockback ให้ player
-- ==========================================
function DashHelper.ApplyKnockback(playerHumanoidRootPart, dashDirection)
    if not playerHumanoidRootPart or not playerHumanoidRootPart:IsA("BasePart") then
        warn("[DashHelper] Invalid player part for knockback")
        return false
    end
    
    -- ตรวจสอบว่ามี AssemblyLinearVelocity (สำหรับ physics)
    if not playerHumanoidRootPart.AssemblyLinearVelocity then
        warn("[DashHelper] Player part has no physics properties")
        return false
    end
    
    -- คำนวณแรงกระเด็น
    local horizontalForce = dashDirection * SimpleAIConfig.KnockbackForce
    
    -- เพิ่มแรงขึ้นเล็กน้อย (ให้กระเด็นขึ้นด้วย)
    local upwardForce = Vector3.new(
        0, 
        SimpleAIConfig.KnockbackForce * SimpleAIConfig.KnockbackUpwardMultiplier, 
        0
    )
    
    local totalForce = horizontalForce + upwardForce
    
    -- ใช้ ApplyImpulse
    local success = pcall(function()
        playerHumanoidRootPart:ApplyImpulse(totalForce)
    end)
    
    if success then
        print("[DashHelper] Knockback applied:", totalForce)
        return true
    else
        warn("[DashHelper] Failed to apply knockback")
        return false
    end
end

-- ==========================================
-- ตรวจสอบว่าเป็น Player หรือไม่
-- ==========================================
function DashHelper.IsPlayerPart(part)
    if not part or not part.Parent then return false end
    
    -- ตรวจสอบว่ามี Humanoid
    local humanoid = part.Parent:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    -- ตรวจสอบว่าเป็น player จริง
    local player = game.Players:GetPlayerFromCharacter(part.Parent)
    return player ~= nil
end

-- ==========================================
-- ดึง HumanoidRootPart จาก part ที่ชน
-- ==========================================
function DashHelper.GetPlayerRootPart(touchedPart)
    if not touchedPart or not touchedPart.Parent then
        return nil
    end
    
    return touchedPart.Parent:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- คำนวณระยะห่างระหว่าง 2 ตำแหน่ง
-- ==========================================
function DashHelper.GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

return DashHelper