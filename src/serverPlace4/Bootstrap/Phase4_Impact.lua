-- ==========================================
-- ServerLocal/Bootstrap/Phase4_Impact.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการระบบการกระแทกและผลัก Player
-- Phase 4: Impact System - Player Impact & Force Reaction
-- ==========================================

local Phase4 = {}

-- ==========================================
-- Initialize: เตรียมระบบ Impact
-- ==========================================
function Phase4.Initialize(repo, config)
    print("===========================================")
    print("[AI Phase 4] 💥 Initializing Impact System...")
    print("[AI Phase 4] • Impact Force Magnitude:", config.ImpactForceMagnitude or "N/A")
    print("[AI Phase 4] • Impact Duration:", config.ImpactDuration or "N/A", "seconds")
    print("[AI Phase 4] • Impact Damage:", config.ImpactDamage or "N/A")
    print("[AI Phase 4] • Impact Mass Multiplier:", config.ImpactMassMultiplier or "N/A")
    print("[AI Phase 4] • Gravity Compensation:", config.ImpactGravityCompensation and "✅ Enabled" or "❌ Disabled")
    print("[AI Phase 4] • Visual Effect:", config.ImpactVisualEffect and "✅ Enabled" or "❌ Disabled")
    print("[AI Phase 4] • Prevent Double Hit:", config.ImpactPreventDoubleHit and "✅ Enabled" or "❌ Disabled")
    print("[AI Phase 4] • Impact Recovery Time:", config.ImpactRecoveryTime or "N/A", "seconds")
    print("[AI Phase 4] ✅ Impact System Ready")
    print("[AI Phase 4] 💡 Players will receive replicated physics force via VectorForce")
    print("===========================================")
end

-- ==========================================
-- Start: เริ่มระบบ Impact
-- ==========================================
function Phase4.Start(activeControllers)
    print("[AI Phase 4] 🎯 Impact System Active")
    print("[AI Phase 4] 💡 Impact detection is handled via Touched events")
    print("[AI Phase 4] 💡 Players will be pushed when hit by dashing enemies")
    
    -- ตรวจสอบว่า controllers มี Impact Detection setup แล้วหรือยัง
    local hasImpactHandler = 0
    local hasTouchedConnection = 0
    local missingControllers = {}
    
    for _, controller in ipairs(activeControllers) do
        local hasHandler = false
        local hasConnection = false
        
        if controller.HandlePlayerImpact then
            hasImpactHandler = hasImpactHandler + 1
            hasHandler = true
        end
        
        if controller.TouchConnection then
            hasTouchedConnection = hasTouchedConnection + 1
            hasConnection = true
        end
        
        -- บันทึก enemy ที่ยังไม่พร้อม
        if not hasHandler or not hasConnection then
            if controller.Model then
                table.insert(missingControllers, controller.Model.Name)
            end
        end
    end
    
    print("[AI Phase 4] ✅", hasImpactHandler, "/", #activeControllers, "enemies have impact handlers")
    print("[AI Phase 4] ✅", hasTouchedConnection, "/", #activeControllers, "enemies have active touch connections")
    
    if #missingControllers > 0 then
        warn("[AI Phase 4] ⚠️ Enemies missing impact system:", table.concat(missingControllers, ", "))
        warn("[AI Phase 4] 💡 These enemies won't be able to push players on impact")
    end
    
    return hasImpactHandler
end

-- ==========================================
-- TestImpact: ทดสอบระบบ Impact กับ player ใกล้ที่สุด
-- ==========================================
function Phase4.TestImpact(activeControllers, config)
    local players = game.Players:GetPlayers()
    if #players == 0 then
        warn("[AI Phase 4] ⚠️ No players in game to test")
        return 0
    end
    
    print("===========================================")
    print("[AI Phase 4] 🧪 Testing Impact System...")
    
    -- หา enemy ตัวแรกที่มี Impact system
    local testEnemy = nil
    for _, controller in ipairs(activeControllers) do
        if controller.HandlePlayerImpact and controller.RootPart then
            testEnemy = controller
            break
        end
    end
    
    if not testEnemy then
        warn("[AI Phase 4] ⚠️ No enemy with impact system found")
        warn("[AI Phase 4] 💡 Make sure enemies have HandlePlayerImpact method")
        return 0
    end
    
    print("[AI Phase 4] 🤖 Test Enemy:", testEnemy.Model.Name)
    
    -- หา player ใกล้ที่สุด
    local nearestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in ipairs(players) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (testEnemy.RootPart.Position - hrp.Position).Magnitude
            
            if distance < shortestDistance then
                nearestPlayer = player
                shortestDistance = distance
            end
        end
    end
    
    if not nearestPlayer or not nearestPlayer.Character then
        warn("[AI Phase 4] ⚠️ No valid player character found")
        return 0
    end
    
    local playerRoot = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then
        warn("[AI Phase 4] ⚠️ Player has no HumanoidRootPart")
        return 0
    end
    
    -- แสดงข้อมูลการทดสอบ
    print("[AI Phase 4] 🎯 Target Player:", nearestPlayer.Name)
    print("[AI Phase 4] 📏 Distance:", math.floor(shortestDistance), "studs")
    print("[AI Phase 4] 💪 Force:", config.ImpactForceMagnitude)
    print("[AI Phase 4] ⏱️ Duration:", config.ImpactDuration, "seconds")
    print("[AI Phase 4] 💥 Applying test impact...")
    
    -- ทดสอบ Impact
    local success, err = pcall(function()
        testEnemy:HandlePlayerImpact(
            nearestPlayer.Character,
            nearestPlayer,
            playerRoot
        )
    end)
    
    if success then
        print("[AI Phase 4] ✅ Impact test completed successfully!")
        print("[AI Phase 4] 💡 Check if player was pushed")
        print("[AI Phase 4] 💡 Player should receive force in direction away from enemy")
        print("===========================================")
        return 1
    else
        warn("[AI Phase 4] ❌ Impact test failed:", err)
        warn("[AI Phase 4] 💡 Check if ImpactHelper is properly configured")
        print("===========================================")
        return 0
    end
end

-- ==========================================
-- SetImpactForce: เปลี่ยนแรงกระแทก
-- ==========================================
function Phase4.SetImpactForce(config, activeControllers, newForce)
    if newForce < 0 then
        warn("[AI Phase 4] ⚠️ Impact force must be positive")
        return 0
    end
    
    -- อัปเดต config
    local oldForce = config.ImpactForceMagnitude
    config.ImpactForceMagnitude = newForce
    
    -- อัปเดตใน controllers
    local count = 0
    for _, controller in ipairs(activeControllers) do
        if controller.ImpactForceMagnitude ~= nil then
            controller.ImpactForceMagnitude = newForce
            count = count + 1
        end
    end
    
    print("[AI Phase 4] 💥 Impact force changed from", oldForce, "to", newForce)
    print("[AI Phase 4] 📝 Updated", count, "/", #activeControllers, "enemies")
    return count
end

-- ==========================================
-- SetImpactDuration: เปลี่ยนระยะเวลากระแทก
-- ==========================================
function Phase4.SetImpactDuration(config, activeControllers, newDuration)
    if newDuration <= 0 then
        warn("[AI Phase 4] ⚠️ Impact duration must be positive")
        return 0
    end
    
    local oldDuration = config.ImpactDuration
    config.ImpactDuration = newDuration
    
    local count = 0
    for _, controller in ipairs(activeControllers) do
        if controller.ImpactDuration ~= nil then
            controller.ImpactDuration = newDuration
            count = count + 1
        end
    end
    
    print("[AI Phase 4] ⏱️ Impact duration changed from", oldDuration, "to", newDuration, "seconds")
    print("[AI Phase 4] 📝 Updated", count, "/", #activeControllers, "enemies")
    return count
end

-- ==========================================
-- SetImpactDamage: เปลี่ยนความเสียหายจากกระแทก
-- ==========================================
function Phase4.SetImpactDamage(config, activeControllers, newDamage)
    if newDamage < 0 then
        warn("[AI Phase 4] ⚠️ Impact damage cannot be negative")
        return 0
    end
    
    local oldDamage = config.ImpactDamage
    config.ImpactDamage = newDamage
    
    local count = 0
    for _, controller in ipairs(activeControllers) do
        if controller.ImpactDamage ~= nil then
            controller.ImpactDamage = newDamage
            count = count + 1
        end
    end
    
    print("[AI Phase 4] 💔 Impact damage changed from", oldDamage, "to", newDamage)
    print("[AI Phase 4] 📝 Updated", count, "/", #activeControllers, "enemies")
    return count
end

-- ==========================================
-- SetMassMultiplier: เปลี่ยนตัวคูณน้ำหนัก
-- ==========================================
function Phase4.SetMassMultiplier(config, activeControllers, newMultiplier)
    if newMultiplier <= 0 then
        warn("[AI Phase 4] ⚠️ Mass multiplier must be positive")
        return 0
    end
    
    local oldMultiplier = config.ImpactMassMultiplier
    config.ImpactMassMultiplier = newMultiplier
    
    print("[AI Phase 4] ⚖️ Mass multiplier changed from", oldMultiplier, "to", newMultiplier)
    print("[AI Phase 4] 💡 Higher values = stronger push for heavier players")
    return #activeControllers
end

-- ==========================================
-- ToggleGravityCompensation: เปิด/ปิดการชดเชยแรงโน้มถ่วง
-- ==========================================
function Phase4.ToggleGravityCompensation(config, enabled)
    local oldValue = config.ImpactGravityCompensation
    config.ImpactGravityCompensation = enabled
    
    print("[AI Phase 4] 🌍 Gravity compensation:", enabled and "✅ Enabled" or "❌ Disabled")
    
    if enabled then
        print("[AI Phase 4] 💡 Push force will compensate for gravity (players fly more)")
    else
        print("[AI Phase 4] 💡 Push force without gravity compensation (more grounded)")
    end
    
    return enabled
end

-- ==========================================
-- ToggleVisualEffect: เปิด/ปิดเอฟเฟกต์
-- ==========================================
function Phase4.ToggleVisualEffect(config, activeControllers, enabled)
    local oldValue = config.ImpactVisualEffect
    config.ImpactVisualEffect = enabled
    
    local count = 0
    for _, controller in ipairs(activeControllers) do
        if controller.ImpactVisualEffect ~= nil then
            controller.ImpactVisualEffect = enabled
            count = count + 1
        end
    end
    
    print("[AI Phase 4] ✨ Visual effect:", enabled and "✅ Enabled" or "❌ Disabled")
    print("[AI Phase 4] 📝 Updated", count, "/", #activeControllers, "enemies")
    
    if enabled then
        print("[AI Phase 4] 💡 Red particles will appear on impact")
    end
    
    return count
end

-- ==========================================
-- GetStatus: ดูสถานะระบบ Impact
-- ==========================================
function Phase4.GetStatus(activeControllers, config)
    local hasImpactSystem = 0
    local hasTouchedConnection = 0
    local hasImpactHandler = 0
    local hasImpactService = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.HandlePlayerImpact then
            hasImpactSystem = hasImpactSystem + 1
        end
        if controller.TouchConnection then
            hasTouchedConnection = hasTouchedConnection + 1
        end
        if controller.ImpactForceMagnitude then
            hasImpactHandler = hasImpactHandler + 1
        end
        if controller.EnemyData and controller.EnemyData.RootPart then
            hasImpactService = hasImpactService + 1
        end
    end
    
    return {
        HasImpactSystem = hasImpactSystem,
        HasTouchedConnection = hasTouchedConnection,
        HasImpactHandler = hasImpactHandler,
        HasImpactService = hasImpactService,
        Total = #activeControllers,
        CurrentForce = config.ImpactForceMagnitude,
        CurrentDuration = config.ImpactDuration,
        CurrentDamage = config.ImpactDamage,
        MassMultiplier = config.ImpactMassMultiplier,
        GravityCompensation = config.ImpactGravityCompensation,
        VisualEffect = config.ImpactVisualEffect,
        PreventDoubleHit = config.ImpactPreventDoubleHit
    }
end

-- ==========================================
-- ShowStats: แสดงสถิติ Impact
-- ==========================================
function Phase4.ShowStats(activeControllers, config)
    local status = Phase4.GetStatus(activeControllers, config)
    
    print("===========================================")
    print("[AI Phase 4] 💥 Impact System Statistics:")
    print("===========================================")
    print("📊 System Status:")
    print("  • Enemies with Impact System:", status.HasImpactSystem, "/", status.Total)
    print("  • Active Touch Connections:", status.HasTouchedConnection, "/", status.Total)
    print("  • Enemies with Impact Config:", status.HasImpactHandler, "/", status.Total)
    print("  • Enemies with RootPart:", status.HasImpactService, "/", status.Total)
    print("")
    print("⚙️ Current Configuration:")
    print("  • Force Magnitude:", status.CurrentForce)
    print("  • Duration:", status.CurrentDuration, "seconds")
    print("  • Damage:", status.CurrentDamage)
    print("  • Mass Multiplier:", status.MassMultiplier)
    print("  • Gravity Compensation:", status.GravityCompensation and "✅ ON" or "❌ OFF")
    print("  • Visual Effect:", status.VisualEffect and "✅ ON" or "❌ OFF")
    print("  • Prevent Double Hit:", status.PreventDoubleHit and "✅ ON" or "❌ OFF")
    print("")
    
    -- คำนวณแรงจริงที่ player จะได้รับ (สมมติ player หนัก 50)
    local sampleMass = 50
    local estimatedForce = status.CurrentForce * status.MassMultiplier * sampleMass
    print("💡 Estimated Force (for 50 mass player):", math.floor(estimatedForce))
    
    print("===========================================")
end

-- ==========================================
-- ClearAllImpactRecords: ล้างรายชื่อ Player ที่ชนแล้วทั้งหมด
-- ==========================================
function Phase4.ClearAllImpactRecords(activeControllers)
    local count = 0
    local failedCount = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.DashService and controller.DashService.ClearImpactRecords then
            local success = pcall(function()
                controller.DashService:ClearImpactRecords()
                count = count + 1
            end)
            
            if not success then
                failedCount = failedCount + 1
                if controller.Model then
                    warn("[AI Phase 4] ⚠️ Failed to clear records for:", controller.Model.Name)
                end
            end
        end
    end
    
    print("[AI Phase 4] 🗑️ Cleared impact records for", count, "/", #activeControllers, "enemies")
    if failedCount > 0 then
        warn("[AI Phase 4] ⚠️ Failed to clear", failedCount, "records")
    end
    return count
end

-- ==========================================
-- ListImpactedPlayers: แสดงรายชื่อ Player ที่ถูกกระแทกโดยแต่ละ Enemy
-- ==========================================
function Phase4.ListImpactedPlayers(activeControllers)
    print("===========================================")
    print("[AI Phase 4] 📋 Impacted Players List:")
    print("===========================================")
    
    local totalImpacts = 0
    local enemiesWithImpacts = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.EnemyData and controller.EnemyData.ImpactedPlayers then
            local impactedCount = 0
            local impactedNames = {}
            
            for player, _ in pairs(controller.EnemyData.ImpactedPlayers) do
                if player and player.Name then
                    table.insert(impactedNames, player.Name)
                    impactedCount = impactedCount + 1
                end
            end
            
            if impactedCount > 0 then
                local enemyName = controller.Model and controller.Model.Name or "Unknown"
                print("  • " .. enemyName .. " - Hit " .. impactedCount .. " player(s):", table.concat(impactedNames, ", "))
                totalImpacts = totalImpacts + impactedCount
                enemiesWithImpacts = enemiesWithImpacts + 1
            end
        end
    end
    
    print("===========================================")
    if totalImpacts == 0 then
        print("📊 Summary: No impacts recorded")
        print("💡 Impacts are tracked when enemies dash into players")
    else
        print("📊 Summary:")
        print("  • Total Impacts:", totalImpacts)
        print("  • Enemies with Impacts:", enemiesWithImpacts, "/", #activeControllers)
    end
    print("===========================================")
end

-- ==========================================
-- GetImpactHistory: ดึงประวัติการกระแทกทั้งหมด
-- ==========================================
function Phase4.GetImpactHistory(activeControllers)
    local history = {}
    
    for _, controller in ipairs(activeControllers) do
        if controller.EnemyData and controller.EnemyData.ImpactedPlayers then
            local enemyName = controller.Model and controller.Model.Name or "Unknown"
            local impactedPlayers = {}
            
            for player, _ in pairs(controller.EnemyData.ImpactedPlayers) do
                if player and player.Name then
                    table.insert(impactedPlayers, player.Name)
                end
            end
            
            if #impactedPlayers > 0 then
                table.insert(history, {
                    EnemyName = enemyName,
                    PlayerCount = #impactedPlayers,
                    Players = impactedPlayers
                })
            end
        end
    end
    
    return history
end

-- ==========================================
-- SimulateImpact: จำลองการกระแทกโดยไม่ต้องให้ enemy พุ่งจริง
-- ==========================================
function Phase4.SimulateImpact(activeControllers, playerName, config)
    -- หา player ที่ระบุ
    local targetPlayer = game.Players:FindFirstChild(playerName)
    if not targetPlayer or not targetPlayer.Character then
        warn("[AI Phase 4] ⚠️ Player not found or has no character:", playerName)
        return 0
    end
    
    local playerRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then
        warn("[AI Phase 4] ⚠️ Player has no HumanoidRootPart")
        return 0
    end
    
    -- หา enemy ใกล้ที่สุด
    local nearestEnemy = nil
    local shortestDistance = math.huge
    
    for _, controller in ipairs(activeControllers) do
        if controller.RootPart and controller.HandlePlayerImpact then
            local distance = (controller.RootPart.Position - playerRoot.Position).Magnitude
            if distance < shortestDistance then
                nearestEnemy = controller
                shortestDistance = distance
            end
        end
    end
    
    if not nearestEnemy then
        warn("[AI Phase 4] ⚠️ No enemy with impact system found")
        return 0
    end
    
    print("[AI Phase 4] 🧪 Simulating impact:")
    print("  • Enemy:", nearestEnemy.Model.Name)
    print("  • Target:", playerName)
    print("  • Distance:", math.floor(shortestDistance), "studs")
    
    -- จำลองการกระแทก
    local success = pcall(function()
        nearestEnemy:HandlePlayerImpact(
            targetPlayer.Character,
            targetPlayer,
            playerRoot
        )
    end)
    
    if success then
        print("[AI Phase 4] ✅ Simulation completed!")
        return 1
    else
        warn("[AI Phase 4] ❌ Simulation failed")
        return 0
    end
end

-- ==========================================
-- ResetAllImpacts: รีเซ็ตระบบ Impact ทั้งหมด
-- ==========================================
function Phase4.ResetAllImpacts(activeControllers, config)
    print("[AI Phase 4] 🔄 Resetting all impact systems...")
    
    -- ล้างรายชื่อผู้เล่นที่ชน
    local clearedCount = Phase4.ClearAllImpactRecords(activeControllers)
    
    -- รีเซ็ต config กลับเป็นค่าเริ่มต้น
    config.ImpactForceMagnitude = 1500
    config.ImpactDuration = 0.2
    config.ImpactDamage = 15
    config.ImpactMassMultiplier = 1.2
    config.ImpactGravityCompensation = true
    config.ImpactVisualEffect = true
    
    print("[AI Phase 4] ✅ Reset complete!")
    print("  • Cleared records:", clearedCount)
    print("  • Force reset to: 1500")
    print("  • Duration reset to: 0.2 seconds")
    print("  • Damage reset to: 15")
end

-- ==========================================
-- ShowHelp: แสดงคำแนะนำการใช้งาน Phase 4
-- ==========================================
function Phase4.ShowHelp()
    print("===========================================")
    print("[AI Phase 4] 💥 Impact System Help")
    print("===========================================")
    print("\n📖 Available Commands:")
    print("\n🧪 Testing:")
    print("  _G.AISystem.TestImpact()")
    print("  _G.AISystem.SimulateImpact('PlayerName')")
    print("\n⚙️ Configuration:")
    print("  _G.AISystem.SetImpactForce(2000)")
    print("  _G.AISystem.SetImpactDuration(0.3)")
    print("  _G.AISystem.SetImpactDamage(20)")
    print("  _G.AISystem.SetMassMultiplier(1.5)")
    print("  _G.AISystem.ToggleGravityCompensation(true)")
    print("  _G.AISystem.ToggleVisualEffect(true)")
    print("\n📊 Information:")
    print("  _G.AISystem.ShowImpactStats()")
    print("  _G.AISystem.ListImpactedPlayers()")
    print("  _G.AISystem.GetImpactHistory()")
    print("\n🗑️ Maintenance:")
    print("  _G.AISystem.ClearImpactRecords()")
    print("  _G.AISystem.ResetAllImpacts()")
    print("\n💡 Tips:")
    print("  • Higher force = stronger push")
    print("  • Gravity compensation makes players fly more")
    print("  • Visual effects help see impacts clearly")
    print("  • Double hit prevention stops spam damage")
    print("===========================================")
end

return Phase4