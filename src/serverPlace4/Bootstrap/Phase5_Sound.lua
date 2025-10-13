-- ==========================================
-- ServerLocal/Bootstrap/Phase5_Sound.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการระบบการตรวจจับเสียงและการตอบสนองของ AI
-- Phase 5: Sound Detection & Enemy Response System
-- ==========================================

local Phase5 = {}

-- ==========================================
-- Initialize: เตรียมระบบ Sound Detection
-- ==========================================
function Phase5.Initialize(repo, config)
    print("===========================================")
    print("[AI Phase 5] 🔊 Initializing Sound Detection System...")
    print("[AI Phase 5] • Sound Radius:", config.SoundRadius or "N/A", "studs")
    print("[AI Phase 5] • Sound Duration:", config.SoundDuration or "N/A", "seconds")
    print("[AI Phase 5] • Hearing Range:", config.SoundHearingRange or "N/A", "studs")
    print("[AI Phase 5] • Alert Duration:", config.SoundAlertDuration or "N/A", "seconds")
    print("[AI Phase 5] • Investigation Timeout:", config.SoundInvestigationTimeout or "N/A", "seconds")
    print("[AI Phase 5] • Reach Threshold:", config.SoundReachThreshold or "N/A", "studs")
    print("[AI Phase 5] • Check Interval:", config.SoundCheckInterval or "N/A", "seconds")
    print("[AI Phase 5] • Visual Effect:", config.SoundVisualEffect and "✅ ON" or "❌ OFF")
    print("[AI Phase 5] • Require Line of Sight:", config.SoundRequireLineOfSight and "✅ ON" or "❌ OFF")
    print("[AI Phase 5] ✅ Sound Detection System Ready")
    print("===========================================")
end

-- ==========================================
-- Start: เริ่มระบบ Sound Detection
-- ==========================================
function Phase5.Start(activeControllers)
    print("[AI Phase 5] 🎯 Sound Detection System Active")
    print("[AI Phase 5] 💡 Sound investigation loops are running in controllers")
    print("[AI Phase 5] 💡 AIs will investigate sounds when detected")
    
    -- ตรวจสอบว่า controllers มี Sound Detection System หรือไม่
    local hasSound = 0
    local hasSoundData = 0
    local hasSoundService = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.SoundDetectionService then
            hasSound = hasSound + 1
        end
        if controller.EnemyData and controller.EnemyData.SoundData then
            hasSoundData = hasSoundData + 1
        end
        if controller.OnHearSound then
            hasSoundService = hasSoundService + 1
        end
    end
    
    print("[AI Phase 5] ✅", hasSound, "/", #activeControllers, "enemies have sound detection service")
    print("[AI Phase 5] ✅", hasSoundData, "/", #activeControllers, "enemies have sound data")
    print("[AI Phase 5] ✅", hasSoundService, "/", #activeControllers, "enemies can hear sounds")
    
    return hasSound
end

-- ==========================================
-- StartPlayerSoundEmitters: เริ่ม Sound Emitter สำหรับ Players
-- ==========================================
function Phase5.StartPlayerSoundEmitters(activeControllers)
    local Players = game:GetService("Players")
    local PlayerSoundEmitter = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.PlayerSoundEmitter)
    
    local emitters = {}
    
    -- สร้าง Emitter สำหรับ Players ที่มีอยู่
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local emitter = PlayerSoundEmitter.new(player, activeControllers)
            emitter:StartMovementDetection()
            emitters[player] = emitter
            print("[AI Phase 5] ✅ Started sound emitter for:", player.Name)
        end
    end
    
    -- ตรวจจับ Players ใหม่
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(1) -- รอให้ character โหลดเสร็จ
            local emitter = PlayerSoundEmitter.new(player, activeControllers)
            emitter:StartMovementDetection()
            emitters[player] = emitter
            print("[AI Phase 5] ✅ Started sound emitter for new player:", player.Name)
        end)
    end)
    
    -- ลบ Emitter เมื่อ Player ออก
    Players.PlayerRemoving:Connect(function(player)
        if emitters[player] then
            emitters[player]:Stop()
            emitters[player] = nil
            print("[AI Phase 5] 🗑️ Removed sound emitter for:", player.Name)
        end
    end)
    
    print("[AI Phase 5] 🔊 Player sound emitters initialized:", #emitters)
    
    return emitters
end

-- ==========================================
-- TestSoundEmission: ทดสอบการสร้างเสียง
-- ==========================================
function Phase5.TestSoundEmission(activeControllers, config)
    local Players = game:GetService("Players")
    local SoundHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.SoundHelper)
    
    -- หา Player คนแรก
    local testPlayer = Players:GetPlayers()[1]
    if not testPlayer or not testPlayer.Character then
        warn("[AI Phase 5] ⚠️ No player found for testing")
        return 0
    end
    
    local playerRoot = testPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then
        warn("[AI Phase 5] ⚠️ Player has no HumanoidRootPart")
        return 0
    end
    
    print("===========================================")
    print("[AI Phase 5] 🧪 Testing Sound Emission...")
    print("[AI Phase 5] 🎯 Test Player:", testPlayer.Name)
    print("[AI Phase 5] 📍 Position:", playerRoot.Position)
    print("[AI Phase 5] 🔊 Emitting test sound...")
    
    -- สร้างเสียงทดสอบ
    local detectedEnemies = SoundHelper.EmitSoundWave(
        playerRoot,
        config.SoundRadius,
        config.SoundDuration,
        function(enemyInfo, soundOrigin, playerCharacter)
            -- หา Controller และแจ้งว่าได้ยินเสียง
            for _, controller in ipairs(activeControllers) do
                if controller.Model == enemyInfo.Model then
                    controller:OnHearSound(soundOrigin, playerCharacter)
                    print("[AI Phase 5] ✅", controller.Model.Name, "heard the test sound!")
                    break
                end
            end
        end
    )
    
    print("[AI Phase 5] 📊 Test Results:")
    print("  • Enemies detected:", #detectedEnemies)
    
    for i, enemyInfo in ipairs(detectedEnemies) do
        print("  • Enemy", i, ":", enemyInfo.Model.Name, "- Distance:", math.floor(enemyInfo.Distance), "studs")
    end
    
    print("===========================================")
    
    return #detectedEnemies
end

-- ==========================================
-- ForceInvestigateNearestSound: บังคับให้ตรวจสอบเสียงใกล้ที่สุด
-- ==========================================
function Phase5.ForceInvestigateNearestSound(activeControllers)
    local Players = game:GetService("Players")
    
    if #Players:GetPlayers() == 0 then
        warn("[AI Phase 5] ⚠️ No players in game")
        return 0
    end
    
    print("[AI Phase 5] 🎯 Forcing enemies to investigate nearest player sound...")
    local investigateCount = 0
    
    for _, controller in ipairs(activeControllers) do
        if not controller.RootPart or not controller.OnHearSound then continue end
        
        -- หา player ใกล้ที่สุด
        local nearestPlayer = nil
        local shortestDistance = math.huge
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local distance = (controller.RootPart.Position - hrp.Position).Magnitude
                
                if distance < shortestDistance and distance <= controller.SoundHearingRange then
                    nearestPlayer = player
                    shortestDistance = distance
                end
            end
        end
        
        -- บังคับให้ได้ยินเสียง
        if nearestPlayer then
            local success = pcall(function()
                local soundPos = nearestPlayer.Character.HumanoidRootPart.Position
                controller:OnHearSound(soundPos, nearestPlayer.Character)
                investigateCount = investigateCount + 1
            end)
            
            if success and controller.Model then
                print("[AI Phase 5] ✅", controller.Model.Name, "- Investigating", nearestPlayer.Name, "(Distance:", math.floor(shortestDistance), "studs)")
            end
        end
    end
    
    print("[AI Phase 5] 🎯 Forced", investigateCount, "/", #activeControllers, "enemies to investigate")
    return investigateCount
end

-- ==========================================
-- SetHearingRange: เปลี่ยนระยะได้ยิน
-- ==========================================
function Phase5.SetHearingRange(activeControllers, newRange)
    if newRange <= 0 then
        warn("[AI Phase 5] ⚠️ Hearing range must be positive")
        return 0
    end
    
    local count = 0
    for _, controller in ipairs(activeControllers) do
        if controller.SoundDetectionService then
            controller.SoundDetectionService:SetHearingRange(newRange)
            controller.SoundHearingRange = newRange
            count = count + 1
        end
    end
    
    print("[AI Phase 5] 🔊 Hearing range changed to:", newRange, "studs for", count, "enemies")
    return count
end

-- ==========================================
-- SetAlertDuration: เปลี่ยนระยะเวลา Alert
-- ==========================================
function Phase5.SetAlertDuration(activeControllers, newDuration)
    if newDuration <= 0 then
        warn("[AI Phase 5] ⚠️ Alert duration must be positive")
        return 0
    end
    
    local count = 0
    for _, controller in ipairs(activeControllers) do
        if controller.SoundDetectionService then
            controller.SoundDetectionService:SetAlertDuration(newDuration)
            controller.SoundAlertDuration = newDuration
            count = count + 1
        end
    end
    
    print("[AI Phase 5] ⏱️ Alert duration changed to:", newDuration, "seconds for", count, "enemies")
    return count
end

-- ==========================================
-- SetSoundRadius: เปลี่ยนรัศมีเสียง
-- ==========================================
function Phase5.SetSoundRadius(config, newRadius)
    if newRadius <= 0 then
        warn("[AI Phase 5] ⚠️ Sound radius must be positive")
        return false
    end
    
    config.SoundRadius = newRadius
    print("[AI Phase 5] 🔊 Sound radius changed to:", newRadius, "studs")
    return true
end

-- ==========================================
-- ToggleVisualEffect: เปิด/ปิดวงเสียง
-- ==========================================
function Phase5.ToggleVisualEffect(config, enabled)
    --config.SoundVisualEffect = enabled
    config.SoundVisualEffect = enabled
    print("[AI Phase 5] ✨ Visual effect:", enabled and "✅ ON" or "❌ OFF")
    return enabled
end

-- ==========================================
-- StopAllInvestigations: หยุดการตรวจสอบทั้งหมด
-- ==========================================
function Phase5.StopAllInvestigations(activeControllers)
    local count = 0
    print("[AI Phase 5] 🛑 Stopping all sound investigations...")
    
    for _, controller in ipairs(activeControllers) do
        local success = pcall(function()
            if controller.IsInvestigatingSound and controller.StopSoundInvestigation then
                controller:StopSoundInvestigation()
                count = count + 1
            end
        end)
        
        if not success and controller.Model then
            warn("[AI Phase 5] ⚠️ Failed to stop investigation for:", controller.Model.Name)
        end
    end
    
    print("[AI Phase 5] 🛑 Stopped", count, "investigations")
    return count
end

-- ==========================================
-- GetStatus: ดูสถานะระบบ Sound
-- ==========================================
function Phase5.GetStatus(activeControllers, config)
    local investigating = 0
    local alerted = 0
    local hasHeardSound = 0
    local silent = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.IsInvestigatingSound then
            investigating = investigating + 1
        end
        
        if controller.SoundDetectionService then
            if controller.SoundDetectionService:IsAlerted() then
                alerted = alerted + 1
            end
            if controller.SoundDetectionService:HasHeardSound() then
                hasHeardSound = hasHeardSound + 1
            end
            if controller.SoundDetectionService:IsSilent() then
                silent = silent + 1
            end
        end
    end
    
    return {
        Investigating = investigating,
        Alerted = alerted,
        HeardSound = hasHeardSound,
        Silent = silent,
        Total = #activeControllers,
        SoundRadius = config.SoundRadius,
        HearingRange = config.SoundHearingRange,
        AlertDuration = config.SoundAlertDuration,
        VisualEffect = config.SoundVisualEffect
    }
end

-- ==========================================
-- ShowStats: แสดงสถิติ Sound
-- ==========================================
function Phase5.ShowStats(activeControllers, config)
    local status = Phase5.GetStatus(activeControllers, config)
    
    print("===========================================")
    print("[AI Phase 5] 🔊 Sound Detection System Statistics:")
    print("===========================================")
    print("📊 Behavior Status:")
    print("  • Currently Investigating:", status.Investigating)
    print("  • Currently Alerted:", status.Alerted)
    print("  • Has Heard Sound:", status.HeardSound)
    print("  • Silent (Normal):", status.Silent)
    print("  • Total Enemies:", status.Total)
    print("")
    print("⚙️ Current Configuration:")
    print("  • Sound Radius:", status.SoundRadius, "studs")
    print("  • Hearing Range:", status.HearingRange, "studs")
    print("  • Alert Duration:", status.AlertDuration, "seconds")
    print("  • Visual Effect:", status.VisualEffect and "✅ ON" or "❌ OFF")
    print("")
    
    -- แสดงรายละเอียด Enemies ที่กำลังตรวจสอบ
    if status.Investigating > 0 then
        print("🔍 Currently Investigating:")
        for _, controller in ipairs(activeControllers) do
            if controller.IsInvestigatingSound then
                local enemyName = controller.Model and controller.Model.Name or "Unknown"
                local target = controller.SoundInvestigationTarget
                print("  •", enemyName, "- Target:", target)
            end
        end
    end
    
    print("===========================================")
end

-- ==========================================
-- ListInvestigatingEnemies: แสดงรายชื่อ Enemy ที่กำลังตรวจสอบ
-- ==========================================
function Phase5.ListInvestigatingEnemies(activeControllers)
    print("===========================================")
    print("[AI Phase 5] 🔍 Investigating Enemies List:")
    print("===========================================")
    
    local investigatingList = {}
    
    for _, controller in ipairs(activeControllers) do
        if controller.IsInvestigatingSound then
            local enemyName = controller.Model and controller.Model.Name or "Unknown"
            local soundSource = controller.SoundDetectionService:GetSoundSource()
            local soundSourceName = soundSource and soundSource.Name or "Unknown"
            local target = controller.SoundInvestigationTarget
            local distance = controller.RootPart and target and 
                           (controller.RootPart.Position - target).Magnitude or "N/A"
            
            table.insert(investigatingList, {
                Enemy = enemyName,
                Source = soundSourceName,
                Distance = distance
            })
        end
    end
    
    if #investigatingList == 0 then
        print("📊 No enemies are currently investigating sounds")
    else
        for i, info in ipairs(investigatingList) do
            print("  •", info.Enemy, "- Investigating sound from", info.Source)
            if type(info.Distance) == "number" then
                print("    Distance to target:", math.floor(info.Distance), "studs")
            end
        end
        print("")
        print("📊 Total investigating:", #investigatingList)
    end
    
    print("===========================================")
end

-- ==========================================
-- ShowHelp: แสดงคำแนะนำการใช้งาน Phase 5
-- ==========================================
function Phase5.ShowHelp()
    print("===========================================")
    print("[AI Phase 5] 🔊 Sound Detection System Help")
    print("===========================================")
    print("\n📖 Available Commands:")
    print("\n🧪 Testing:")
    print("  _G.AISystem.TestSoundEmission()")
    print("  _G.AISystem.ForceInvestigateNearestSound()")
    print("\n⚙️ Configuration:")
    print("  _G.AISystem.SetHearingRange(80)")
    print("  _G.AISystem.SetAlertDuration(3.0)")
    print("  _G.AISystem.SetSoundRadius(70)")
    print("  _G.AISystem.ToggleSoundVisual(true)")
    print("\n🛑 Control:")
    print("  _G.AISystem.StopAllInvestigations()")
    print("  _G.AISystem.StartPlayerSoundEmitters()")
    print("\n📊 Information:")
    print("  _G.AISystem.ShowSoundStats()")
    print("  _G.AISystem.ListInvestigatingEnemies()")
    print("\n💡 Tips:")
    print("  • Higher hearing range = enemies detect sounds from farther away")
    print("  • Longer alert duration = enemies stay alert longer")
    print("  • Visual effects help see sound waves")
    print("  • Sound priority: Dash > Chase > Sound > Walk")
    print("===========================================")
end

return Phase5