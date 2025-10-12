-- ==========================================
-- ServerLocal/Bootstrap/Phase3_Dash.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการระบบการพุ่งใส่ผู้เล่นของ AI
-- Phase 3: Dash System
-- ==========================================

local Phase3 = {}

-- ==========================================
-- Initialize: เตรียมระบบ Dash
-- ==========================================
function Phase3.Initialize(repo, config)
    print("===========================================")
    print("[AI Phase 3] 🚀 Initializing Dash System...")
    print("[AI Phase 3] • Spear Speed:", config.SpearSpeed or "N/A")
    print("[AI Phase 3] • Dash Min Distance:", config.DashMinDistance or "N/A", "studs")
    print("[AI Phase 3] • Dash Max Distance:", config.DashMaxDistance or "N/A", "studs")
    print("[AI Phase 3] • Dash Chance:", ((config.DashChance or 0) * 100), "%")
    print("[AI Phase 3] • Dash Duration:", (config.DashDurationMin or "N/A"), "-", (config.DashDurationMax or "N/A"), "seconds")
    print("[AI Phase 3] • Dash Cooldown:", config.DashCooldown or "N/A", "seconds")
    print("[AI Phase 3] • Dash Check Interval:", config.DashCheckInterval or "N/A", "seconds")
    print("[AI Phase 3] • Knockback Force:", config.KnockbackForce or "N/A")
    print("[AI Phase 3] • Knockback Upward Multiplier:", config.KnockbackUpwardMultiplier or "N/A")
    print("[AI Phase 3] • Recover Duration:", config.RecoverDuration or "N/A", "seconds")
    print("[AI Phase 3] ✅ Dash System Ready")
    print("===========================================")
end

-- ==========================================
-- Start: เริ่มระบบ Dash
-- ==========================================
function Phase3.Start(activeControllers)
    print("[AI Phase 3] 💨 Dash System Active")
    print("[AI Phase 3] 💡 Dash check loops are already running in controllers")
    print("[AI Phase 3] 💡 AIs will automatically dash when conditions are met")
    
    -- ตรวจสอบว่ามี Dash Service หรือไม่
    local hasDash = 0
    for _, controller in ipairs(activeControllers) do
        if controller.DashService then
            hasDash = hasDash + 1
        end
    end
    
    print("[AI Phase 3] ✅", hasDash, "/", #activeControllers, "enemies have dash system")
    return hasDash
end

-- ==========================================
-- ForceDashNearestPlayer: บังคับให้พุ่งใส่ player ใกล้ที่สุด
-- ==========================================
function Phase3.ForceDashNearestPlayer(activeControllers)
    local players = game.Players:GetPlayers()
    if #players == 0 then
        warn("[AI Phase 3] ⚠️ No players in game")
        return 0
    end
    
    print("[AI Phase 3] 🚀 Forcing enemies to dash at nearest player...")
    local dashCount = 0
    
    for _, controller in ipairs(activeControllers) do
        if not controller.RootPart or not controller.StartDashing then continue end
        
        -- ตรวจสอบว่าสามารถ dash ได้หรือไม่
        if controller.DashService and not controller.DashService:CanDash() then
            if controller.Model then
                print("[AI Phase 3] ⏳", controller.Model.Name, "- On cooldown, skipping")
            end
            continue
        end
        
        local nearestPlayer = nil
        local shortestDistance = math.huge
        
        -- หา player ใกล้ที่สุด
        for _, player in ipairs(players) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local distance = (controller.RootPart.Position - hrp.Position).Magnitude
                
                if distance < shortestDistance then
                    nearestPlayer = hrp
                    shortestDistance = distance
                end
            end
        end
        
        -- บังคับพุ่ง
        if nearestPlayer then
            local success = pcall(function()
                -- ตั้ง target และสถานะ
                controller.CurrentTarget = nearestPlayer
                controller.IsChasing = true
                
                controller:StartDashing()
                dashCount = dashCount + 1
            end)
            
            if success and controller.Model then
                print("[AI Phase 3] ✅", controller.Model.Name, "- Dashing at", nearestPlayer.Parent.Name, "(Distance:", math.floor(shortestDistance), "studs)")
            end
        end
    end
    
    print("[AI Phase 3] 🚀 Forced", dashCount, "/", #activeControllers, "enemies to dash")
    return dashCount
end

-- ==========================================
-- SetDashChance: เปลี่ยนโอกาสพุ่ง
-- ==========================================
function Phase3.SetDashChance(config, newChance)
    if newChance < 0 or newChance > 1 then
        warn("[AI Phase 3] ⚠️ Dash chance must be between 0 and 1")
        return false
    end
    
    config.DashChance = newChance
    print("[AI Phase 3] 🎲 Dash chance changed to:", newChance * 100, "%")
    return true
end

-- ==========================================
-- SetKnockbackForce: เปลี่ยนแรง Knockback
-- ==========================================
function Phase3.SetKnockbackForce(config, newForce)
    if newForce < 0 then
        warn("[AI Phase 3] ⚠️ Knockback force must be positive")
        return false
    end
    
    config.KnockbackForce = newForce
    print("[AI Phase 3] 💥 Knockback force changed to:", newForce)
    return true
end

-- ==========================================
-- SetDashRange: เปลี่ยนระยะ Dash
-- ==========================================
function Phase3.SetDashRange(config, minDistance, maxDistance)
    if minDistance < 0 or maxDistance < minDistance then
        warn("[AI Phase 3] ⚠️ Invalid dash range (min must be < max)")
        return false
    end
    
    config.DashMinDistance = minDistance
    config.DashMaxDistance = maxDistance
    print("[AI Phase 3] 🎯 Dash range changed to:", minDistance, "-", maxDistance, "studs")
    return true
end

-- ==========================================
-- GetStatus: ดูสถานะระบบ Dash
-- ==========================================
function Phase3.GetStatus(activeControllers)
    local dashing = 0
    local recovering = 0
    local canDash = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.DashService then
            if controller.DashService:IsDashing() then
                dashing = dashing + 1
            end
            if controller.DashService:IsRecovering() then
                recovering = recovering + 1
            end
            if controller.DashService:CanDash() then
                canDash = canDash + 1
            end
        end
    end
    
    return {
        Dashing = dashing,
        Recovering = recovering,
        CanDash = canDash,
        OnCooldown = #activeControllers - canDash,
        Total = #activeControllers
    }
end

-- ==========================================
-- ShowStats: แสดงสถิติ Dash
-- ==========================================
function Phase3.ShowStats(activeControllers)
    local status = Phase3.GetStatus(activeControllers)
    
    print("===========================================")
    print("[AI Phase 3] 🚀 Dash System Statistics:")
    print("  • Currently Dashing:", status.Dashing)
    print("  • Currently Recovering:", status.Recovering)
    print("  • Ready to Dash:", status.CanDash)
    print("  • On Cooldown:", status.OnCooldown)
    print("  • Total Enemies:", status.Total)
    print("===========================================")
end

return Phase3