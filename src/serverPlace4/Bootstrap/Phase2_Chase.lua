-- ==========================================
-- ServerLocal/Bootstrap/Phase2_Chase.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการระบบการไล่ผู้เล่นของ AI
-- Phase 2: Chase System
-- ==========================================

local Phase2 = {}

-- ==========================================
-- Initialize: เตรียมระบบ Chase
-- ==========================================
function Phase2.Initialize(repo, config)
    print("===========================================")
    print("[AI Phase 2] 🏃 Initializing Chase System...")
    print("[AI Phase 2] • Run Speed:", config.RunSpeed or "N/A")
    print("[AI Phase 2] • Detection Range:", config.DetectionRange or "N/A", "studs")
    print("[AI Phase 2] • Detection Check Interval:", config.DetectionCheckInterval or "N/A", "seconds")
    print("[AI Phase 2] • Chase Update Interval:", config.ChaseUpdateInterval or "N/A", "seconds")
    print("[AI Phase 2] • Chase Stop Range:", config.ChaseStopRange or "N/A", "studs")
    print("[AI Phase 2] • Chase Stop Delay:", config.ChaseStopDelay or "N/A", "seconds")
    print("[AI Phase 2] • Waypoint Spacing:", config.WaypointSpacing or "N/A", "studs")
    print("[AI Phase 2] ✅ Chase System Ready")
    print("===========================================")
end

-- ==========================================
-- Start: เริ่มระบบ Chase
-- ==========================================
function Phase2.Start(activeControllers)
    print("[AI Phase 2] 🔍 Chase System Active")
    print("[AI Phase 2] 💡 Detection loops are already running in controllers")
    print("[AI Phase 2] 💡 AIs will automatically chase players when detected")
    
    -- ตรวจสอบว่ามี Detection Service หรือไม่
    local hasDetection = 0
    for _, controller in ipairs(activeControllers) do
        if controller.DetectionService then
            hasDetection = hasDetection + 1
        end
    end
    
    print("[AI Phase 2] ✅", hasDetection, "/", #activeControllers, "enemies have detection system")
    return hasDetection
end

-- ==========================================
-- StopAll: หยุดการไล่ทั้งหมด
-- ==========================================
function Phase2.StopAll(activeControllers)
    local count = 0
    print("[AI Phase 2] 🛑 Stopping all chase behaviors...")
    
    for _, controller in ipairs(activeControllers) do
        local success = pcall(function()
            if controller.StopChasing then
                controller:StopChasing()
                count = count + 1
            end
        end)
        
        if not success and controller.Model then
            warn("[AI Phase 2] ⚠️ Failed to stop chase for:", controller.Model.Name)
        end
    end
    
    print("[AI Phase 2] 🛑 Stopped", count, "/", #activeControllers, "chase behaviors")
    return count
end

-- ==========================================
-- ForceChaseNearestPlayer: บังคับให้ไล่ player ใกล้ที่สุด
-- ==========================================
function Phase2.ForceChaseNearestPlayer(activeControllers)
    local players = game.Players:GetPlayers()
    if #players == 0 then
        warn("[AI Phase 2] ⚠️ No players in game")
        return 0
    end
    
    print("[AI Phase 2] 🎯 Forcing enemies to chase nearest player...")
    local chaseCount = 0
    
    for _, controller in ipairs(activeControllers) do
        if not controller.RootPart then continue end
        
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
        
        -- สั่งให้ไล่
        if nearestPlayer and controller.StartChasing then
            local success = pcall(function()
                controller:StartChasing(nearestPlayer)
                chaseCount = chaseCount + 1
            end)
            
            if success and controller.Model then
                print("[AI Phase 2] ✅", controller.Model.Name, "- Chasing", nearestPlayer.Parent.Name, "(Distance:", math.floor(shortestDistance), "studs)")
            end
        end
    end
    
    print("[AI Phase 2] 🎯 Forced", chaseCount, "/", #activeControllers, "enemies to chase")
    return chaseCount
end

-- ==========================================
-- SetDetectionRange: เปลี่ยนระยะตรวจจับ
-- ==========================================
function Phase2.SetDetectionRange(activeControllers, newRange)
    local count = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.DetectionRange then
            controller.DetectionRange = newRange
            count = count + 1
        end
    end
    
    print("[AI Phase 2] 📏 Detection range changed to:", newRange, "studs for", count, "enemies")
    return count
end

-- ==========================================
-- GetStatus: ดูสถานะระบบ Chase
-- ==========================================
function Phase2.GetStatus(activeControllers)
    local chasing = 0
    local hasTarget = 0
    local detecting = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.IsChasing then
            chasing = chasing + 1
        end
        if controller.CurrentTarget then
            hasTarget = hasTarget + 1
        end
        if controller.EnemyData and controller.EnemyData:IsDetecting() then
            detecting = detecting + 1
        end
    end
    
    return {
        Chasing = chasing,
        HasTarget = hasTarget,
        Detecting = detecting,
        Total = #activeControllers
    }
end

-- ==========================================
-- ShowStats: แสดงสถิติ Chase
-- ==========================================
function Phase2.ShowStats(activeControllers)
    local status = Phase2.GetStatus(activeControllers)
    
    print("===========================================")
    print("[AI Phase 2] 🏃 Chase System Statistics:")
    print("  • Currently Chasing:", status.Chasing)
    print("  • Has Target:", status.HasTarget)
    print("  • Detecting:", status.Detecting)
    print("  • Total Enemies:", status.Total)
    print("===========================================")
end

return Phase2