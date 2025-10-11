-- ==========================================
-- Bootstrap/InitializeAI.server.lua (Script)
-- ==========================================
-- วัตถุประสงค์: เริ่มระบบ AI ทั้ง Phase 1 และ Phase 2
-- วาง Script นี้ใน ServerScriptService
-- ==========================================

-- ==========================================
-- ⚙️ CONFIGURATION - เลือก Phase ที่ต้องการใช้
-- ==========================================
local CONFIG = {
    -- เปิด/ปิด Phase ต่างๆ
    EnablePhase1 = true,  -- true = เดินสำรวจอย่างเดียว (ไม่ไล่ player)
    EnablePhase2 = true,  -- true = เพิ่มการไล่ player (ต้องเปิด Phase1 ด้วย)
    EnablePhase3 = true,  -- ✨ พุ่งใส่ player + knockback

    -- Debug Options
    ShowDetailedLogs = true,  -- แสดง log ละเอียด
    ShowConfig = true,        -- แสดง config ตอนเริ่ม
    
    -- Startup Options
    AutoStart = true,         -- เริ่ม AI อัตโนมัติเลย
    StartDelay = 1,           -- รอกี่วินาทีก่อนเริ่ม (ให้ระบบโหลดก่อน)
}

-- ตรวจสอบ Dependencies
if CONFIG.EnablePhase3 and not CONFIG.EnablePhase2 then
    warn("[AI System] ⚠️ Phase 3 requires Phase 2 to be enabled!")
    CONFIG.EnablePhase2 = true
end


-- ตรวจสอบ Config
if CONFIG.EnablePhase2 and not CONFIG.EnablePhase1 then
    warn("[AI System] ⚠️ Phase 2 requires Phase 1 to be enabled!")
    CONFIG.EnablePhase1 = true
end

-- ==========================================
-- แสดงหัวข้อ
-- ==========================================
print("===========================================")
if CONFIG.EnablePhase1 and CONFIG.EnablePhase2 and CONFIG.EnablePhase3 then
    print("[AI System] 🎮 Starting AI System (Phase 1 + 2 + 3)")
    print("[AI System] ✅ Walk + Chase + Spear Dash Enabled")
elseif CONFIG.EnablePhase1 and CONFIG.EnablePhase2 then
    print("[AI System] 🎮 Starting AI System (Phase 1 + 2)")
    print("[AI System] ✅ Walk + Chase Enabled")
elseif CONFIG.EnablePhase1 then
    print("[AI System] 🎮 Starting AI System (Phase 1)")
    print("[AI System] ✅ Walk Only Enabled")
else
    warn("[AI System] ❌ No phases enabled!")
    return
end
print("===========================================")

-- ==========================================
-- รอให้ระบบพร้อม
-- ==========================================
if CONFIG.StartDelay > 0 then
    print("[AI System] ⏳ Waiting", CONFIG.StartDelay, "seconds for system initialization...")
    wait(CONFIG.StartDelay)
end

-- ==========================================
-- โหลด Dependencies
-- ==========================================
local SimpleWalkController, SimpleEnemyRepository, SimpleAIConfig

local success, err = pcall(function()
    SimpleWalkController = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.SimpleWalkController)
    SimpleEnemyRepository = require(game.ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
    SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)
end)

if not success then
    warn("[AI System] ❌ Failed to load dependencies!")
    warn("[AI System] Error:", err)
    warn("[AI System] 💡 Check if these files exist:")
    warn("  • ServerScriptService/ServerLocal/Presentation/Controllers/SimpleWalkController")
    warn("  • ServerScriptService/ServerLocal/Infrastructure/Repositories/SimpleEnemyRepository")
    warn("  • ServerScriptService/ServerLocal/Infrastructure/Data/SimpleAIConfig")
    return
end

print("[AI System] ✅ Dependencies loaded successfully")

-- ==========================================
-- แสดง Configuration
-- ==========================================
if CONFIG.ShowConfig then
    print("[AI System] 📋 Configuration:")
    print("  • Walk Speed:", SimpleAIConfig.WalkSpeed)
    
    if CONFIG.EnablePhase2 then
        print("  • Run Speed:", SimpleAIConfig.RunSpeed)
        print("  • Detection Range:", SimpleAIConfig.DetectionRange, "studs")
        print("  • Detection Interval:", SimpleAIConfig.DetectionCheckInterval, "seconds")
        print("  • Chase Update:", SimpleAIConfig.ChaseUpdateInterval, "seconds")
    end


    if CONFIG.EnablePhase3 then
        print("  • Spear Speed:", SimpleAIConfig.SpearSpeed)
        print("  • Dash Min Distance:", SimpleAIConfig.DashMinDistance, "studs")
        print("  • Dash Max Distance:", SimpleAIConfig.DashMaxDistance, "studs")
        print("  • Dash Chance:", SimpleAIConfig.DashChance * 100, "%")
        print("  • Dash Duration:", SimpleAIConfig.DashDurationMin, "-", SimpleAIConfig.DashDurationMax, "seconds")
        print("  • Knockback Force:", SimpleAIConfig.KnockbackForce)
        print("  • Recover Duration:", SimpleAIConfig.RecoverDuration, "seconds")
    end
    
    print("  • Wander Radius:", SimpleAIConfig.WanderRadius)
    print("  • Walk Duration:", SimpleAIConfig.WalkDuration, "seconds")
    print("  • Idle Duration:", SimpleAIConfig.IdleDuration, "seconds")
    print("===========================================")
end

-- ==========================================
-- Repository (Singleton)
-- ==========================================
local repo = SimpleEnemyRepository.GetInstance()

-- ==========================================
-- หา Enemies Folder
-- ==========================================
local enemiesFolder = workspace:FindFirstChild("Enemies")

if not enemiesFolder then
    warn("[AI System] ❌ No 'Enemies' folder found in workspace!")
    warn("[AI System] 💡 Creating 'Enemies' folder...")
    
    enemiesFolder = Instance.new("Folder")
    enemiesFolder.Name = "Enemies"
    enemiesFolder.Parent = workspace
    
    warn("[AI System] 📝 Please add enemy models to the 'Enemies' folder")
    warn("[AI System] 📝 Enemy models must have: Humanoid + HumanoidRootPart")
    return
end

-- ตรวจสอบว่ามี enemy หรือไม่
local enemyCount = 0
for _, child in ipairs(enemiesFolder:GetChildren()) do
    if child:IsA("Model") then
        enemyCount = enemyCount + 1
    end
end

if enemyCount == 0 then
    warn("[AI System] ⚠️ 'Enemies' folder is empty!")
    warn("[AI System] 💡 Add enemy models (with Humanoid) to start AI")
    return
end

print("[AI System] 🎯 Found", enemyCount, "enemy models")

-- ==========================================
-- เริ่ม AI สำหรับทุกตัว
-- ==========================================
local activeControllers = {}
local successCount = 0
local failCount = 0
local startedCount = 0

for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
    if enemyModel:IsA("Model") and enemyModel:FindFirstChild("Humanoid") then
        
        local success, controllerOrError = pcall(function()
            -- ตรวจสอบ HumanoidRootPart
            if not enemyModel:FindFirstChild("HumanoidRootPart") then
                error("Missing HumanoidRootPart")
            end
            
            -- ตรวจสอบ Humanoid Health
            local humanoid = enemyModel:FindFirstChild("Humanoid")
            if humanoid.Health <= 0 then
                humanoid.Health = humanoid.MaxHealth
            end
            
            -- สร้าง enemy data
            if CONFIG.ShowDetailedLogs then
                print("[AI System] 🔄 Creating enemy data for:", enemyModel.Name)
            end
            
            local enemyData = repo:CreateSimpleEnemy(enemyModel)
            if not enemyData then
                error("Failed to create enemyData")
            end

            -- สร้าง Controller
            if CONFIG.ShowDetailedLogs then
                print("[AI System] 🤖 Creating controller for:", enemyModel.Name)
            end
            
            local controller = SimpleWalkController.new(enemyModel)
            if not controller then
                error("Failed to create controller")
            end

            return controller
        end)
        
        if success then
            local controller = controllerOrError
            table.insert(activeControllers, controller)
            successCount = successCount + 1
            
            -- ⭐ เริ่มให้ AI ทำงาน
            if CONFIG.AutoStart then
                local startSuccess, startError = pcall(function()
                    -- ลองหาฟังก์ชันเริ่มทำงาน
                    if controller.Start then
                        controller:Start()
                        startedCount = startedCount + 1
                    elseif controller.StartWalking then
                        controller:StartWalking()
                        startedCount = startedCount + 1
                    elseif controller.Initialize then
                        controller:Initialize()
                        startedCount = startedCount + 1
                    else
                        warn("[AI System] ⚠️", enemyModel.Name, "- No Start method found")
                    end
                end)
                
                if not startSuccess then
                    warn("[AI System] ⚠️", enemyModel.Name, "- Failed to start:", startError)
                end
            end
            
            -- แสดงข้อความตาม Phase ที่เปิดใช้งาน
            local features = {}
            if CONFIG.EnablePhase1 then table.insert(features, "Walk") end
            if CONFIG.EnablePhase2 then table.insert(features, "Chase") end
            if CONFIG.EnablePhase3 then table.insert(features, "Dash") end

            
            local statusIcon = (CONFIG.AutoStart and startedCount == successCount) and "✅" or "⚠️"
            print("[AI System]", statusIcon, enemyModel.Name, "- AI Controller Created (" .. table.concat(features, " + ") .. ")")
        else
            failCount = failCount + 1
            warn("[AI System] ❌", enemyModel.Name, "- Failed:", controllerOrError)
        end
    else
        if enemyModel:IsA("Model") then
            warn("[AI System] ⚠️", enemyModel.Name, "- Invalid model (no Humanoid)")
        end
    end
end

-- ==========================================
-- สรุปผล
-- ==========================================
print("===========================================")
print("[AI System] 📊 Summary:")
print("[AI System] ✅ Controllers Created:", successCount)
if CONFIG.AutoStart then
    print("[AI System] 🚀 AIs Started:", startedCount)
end

if failCount > 0 then
    warn("[AI System] ❌ Failed:", failCount)
end

if startedCount < successCount then
    warn("[AI System] ⚠️ Some AIs didn't start automatically")
    warn("[AI System] 💡 Use _G.AISystem.StartAll() to start them manually")
end

print("[AI System] 🎯 System Ready!")

if CONFIG.EnablePhase2 then
    print("[AI System] 🔍 Enemies will detect players within", SimpleAIConfig.DetectionRange, "studs")
    print("[AI System] 🏃 Enemies will chase at speed", SimpleAIConfig.RunSpeed)
end


if CONFIG.EnablePhase3 then
    print("[AI System] 🚀 Enemies can dash at speed", SimpleAIConfig.SpearSpeed, "when player is", SimpleAIConfig.DashMinDistance, "-", SimpleAIConfig.DashMaxDistance, "studs away")
    print("[AI System] 💥 Knockback force:", SimpleAIConfig.KnockbackForce)
    print("[AI System] 🎲 Dash chance:", SimpleAIConfig.DashChance * 100, "%")
end


print("===========================================")

-- ==========================================
-- Global API สำหรับ Debug
-- ==========================================
_G.AISystem = {
    -- ข้อมูลระบบ
    Config = CONFIG,
    Phase1Enabled = CONFIG.EnablePhase1,
    Phase2Enabled = CONFIG.EnablePhase2,
    Phase3Enabled = CONFIG.EnablePhase3,
    
    -- นับจำนวน AI
    GetActiveCount = function()
        return #activeControllers
    end,
    
    -- ดึง Controllers ทั้งหมด
    GetControllers = function()
        return activeControllers
    end,
    
    -- เริ่ม AI ทั้งหมด (ถ้ายังไม่ได้เริ่ม)
    StartAll = function()
        local count = 0
        for _, controller in ipairs(activeControllers) do
            local success = pcall(function()
                if controller.Start then
                    controller:Start()
                    count = count + 1
                elseif controller.StartWalking then
                    controller:StartWalking()
                    count = count + 1
                end
            end)
        end
        print("[AI System] Started", count, "AIs")
    end,
    
    -- หยุด AI ทั้งหมด
    StopAll = function()
        local count = 0
        for _, controller in ipairs(activeControllers) do
            local success = pcall(function()
                if controller.Stop then
                    controller:Stop()
                    count = count + 1
                elseif controller.StopWalking then
                    controller:StopWalking()
                    count = count + 1
                end
            end)
        end
        print("[AI System] Stopped", count, "AIs")
    end,
    
    -- รีเซ็ต AI ทั้งหมด
    ResetAll = function()
        for _, controller in ipairs(activeControllers) do
            if controller.Reset then
                controller:Reset()
            end
        end
        print("[AI System] All AIs reset")
    end,
    
    -- ดูสถานะ AI ตัวแรก
    DebugFirstEnemy = function()
        if #activeControllers > 0 then
            local controller = activeControllers[1]
            print("===========================================")
            print("[Debug] Enemy:", controller.Model.Name)
            
            if controller.EnemyData then
                print("[Debug] Has EnemyData:", true)
                print("[Debug] State:", controller.EnemyData.CurrentState or "N/A")
                print("[Debug] Speed:", controller.EnemyData.CurrentSpeed or "N/A")
                
                if CONFIG.EnablePhase2 then
                    print("[Debug] Is Chasing:", controller.IsChasing or false)
                    if controller.EnemyData.HasTarget then
                        print("[Debug] Has Target:", controller.EnemyData:HasTarget())
                        if controller.EnemyData:HasTarget() and controller.EnemyData.CurrentTarget then
                            print("[Debug] Target:", controller.EnemyData.CurrentTarget.Parent.Name)
                        end
                    end
                    print("[Debug] Detection State:", controller.EnemyData.DetectionState or "N/A")
                end


                 if CONFIG.EnablePhase3 then
                    print("[Debug] 🚀 Is Dashing:", controller.EnemyData.IsDashing or false)
                    print("[Debug] 😮‍💨 Is Recovering:", controller.EnemyData:IsRecovering())
                    print("[Debug] ⏳ Can Dash:", controller.EnemyData:CanDash(tick()))
                    if controller.DashService then
                        print("[Debug] 🎯 Dash Direction:", controller.DashService:GetDashDirection())
                    end
                end

            else
                print("[Debug] Has EnemyData:", false)
            end
            
            -- ตรวจสอบฟังก์ชันที่มี
            print("[Debug] Available Methods:")
            if controller.Start then print("  • Start()") end
            if controller.Stop then print("  • Stop()") end
            if controller.StartWalking then print("  • StartWalking()") end
            if controller.StopWalking then print("  • StopWalking()") end
            if controller.StartChasing then print("  • StartChasing()") end
            if controller.StopChasing then print("  • StopChasing()") end

            if controller.StartDashing then print("  • StartDashing()") end

            
            print("===========================================")
        else
            warn("[Debug] No active enemies")
        end
    end,
    
    -- แสดงสถานะทุกตัว
    ShowAllStatus = function()
        print("===========================================")
        print("[AI System] All Enemies Status:")
        for i, controller in ipairs(activeControllers) do
            local status = string.format(
                "%d. %s",
                i,
                controller.Model.Name
            )
            
            if controller.EnemyData then
                status = status .. string.format(
                    " | State: %s | Speed: %.1f",
                    controller.EnemyData.CurrentState or "N/A",
                    controller.EnemyData.CurrentSpeed or 0
                )
                
                if CONFIG.EnablePhase2 then
                    status = status .. string.format(" | Chasing: %s", tostring(controller.IsChasing or false))
                end


                if CONFIG.EnablePhase3 then
                    status = status .. string.format(" | Dashing: %s", tostring(controller.EnemyData.IsDashing or false))
                end

            else
                status = status .. " | No EnemyData"
            end
            
            print(status)
        end
        print("[AI System] Total:", #activeControllers, "enemies")
        print("===========================================")
    end,
    
    -- แสดง Config
    ShowConfig = function()
        print("===========================================")
        print("[AI System] Current Configuration:")
        print("  • Phase 1 (Walk):", CONFIG.EnablePhase1)
        print("  • Phase 2 (Chase):", CONFIG.EnablePhase2)

        print("  • Phase 3 (Dash):", CONFIG.EnablePhase3)


        print("  • Auto Start:", CONFIG.AutoStart)
        print("  • Walk Speed:", SimpleAIConfig.WalkSpeed)
        
        if CONFIG.EnablePhase2 then
            print("  • Run Speed:", SimpleAIConfig.RunSpeed)
            print("  • Detection Range:", SimpleAIConfig.DetectionRange)
            print("  • Detection Interval:", SimpleAIConfig.DetectionCheckInterval)
            print("  • Chase Update:", SimpleAIConfig.ChaseUpdateInterval)
        end
        

        if CONFIG.EnablePhase3 then
            print("  • Spear Speed:", SimpleAIConfig.SpearSpeed)
            print("  • Dash Range:", SimpleAIConfig.DashMinDistance, "-", SimpleAIConfig.DashMaxDistance)
            print("  • Knockback Force:", SimpleAIConfig.KnockbackForce)
        end

        print("  • Wander Radius:", SimpleAIConfig.WanderRadius)
        print("  • Walk Duration:", SimpleAIConfig.WalkDuration)
        print("  • Idle Duration:", SimpleAIConfig.IdleDuration)
        print("===========================================")
    end,
    
    -- ทดสอบว่า AI ตัวแรกเดินได้ไหม
    TestFirstEnemy = function()
        if #activeControllers > 0 then
            local controller = activeControllers[1]
            print("[AI System] 🧪 Testing", controller.Model.Name)
            
            -- ลองเริ่ม
            if controller.Start then
                controller:Start()
                print("[AI System] ✅ Called Start()")
            elseif controller.StartWalking then
                controller:StartWalking()
                print("[AI System] ✅ Called StartWalking()")
            else
                warn("[AI System] ❌ No start method found")
            end
            
            wait(2)
            _G.AISystem.DebugFirstEnemy()
        else
            warn("[AI System] No enemies to test")
        end
    end,
}

-- ==========================================
-- Phase 2 Specific Commands
-- ==========================================
if CONFIG.EnablePhase2 then
    -- หยุดไล่ทั้งหมด
    _G.AISystem.StopAllChase = function()
        local count = 0
        for _, controller in ipairs(activeControllers) do
            if controller.StopChasing then
                controller:StopChasing()
                count = count + 1
            end
        end
        print("[AI System] Stopped", count, "chase behaviors")
    end
    
    -- เปลี่ยนระยะตรวจจับ
    _G.AISystem.SetDetectionRange = function(newRange)
        local count = 0
        for _, controller in ipairs(activeControllers) do
            if controller.DetectionRange then
                controller.DetectionRange = newRange
                count = count + 1
            end
        end
        print("[AI System] Detection range changed to:", newRange, "for", count, "enemies")
    end
    
    -- บังคับให้ไล่ player ใกล้ที่สุด
    _G.AISystem.ForceChaseNearestPlayer = function()
        local players = game.Players:GetPlayers()
        if #players == 0 then
            warn("[AI System] No players in game")
            return
        end
        
        local chaseCount = 0
        for _, controller in ipairs(activeControllers) do
            local nearestPlayer = nil
            local shortestDistance = math.huge
            
            for _, player in ipairs(players) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (controller.RootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        nearestPlayer = player.Character.HumanoidRootPart
                        shortestDistance = distance
                    end
                end
            end
            
            if nearestPlayer and controller.StartChasing then
                controller:StartChasing(nearestPlayer)
                chaseCount = chaseCount + 1
            end
        end
        
        print("[AI System]", chaseCount, "enemies forced to chase nearest player")
    end
end



-- ==========================================
-- ✨ Phase 3 Commands
-- ==========================================
if CONFIG.EnablePhase3 then
    -- บังคับให้พุ่งใส่ player ใกล้ที่สุด
    _G.AISystem.ForceDashNearestPlayer = function()
        local players = game.Players:GetPlayers()
        if #players == 0 then
            warn("[AI System] No players in game")
            return
        end
        
        local dashCount = 0
        for _, controller in ipairs(activeControllers) do
            -- หา player ใกล้ที่สุด
            local nearestPlayer = nil
            local shortestDistance = math.huge
            
            for _, player in ipairs(players) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (controller.RootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        nearestPlayer = player.Character.HumanoidRootPart
                        shortestDistance = distance
                    end
                end
            end
            
            -- บังคับพุ่ง
            if nearestPlayer and controller.StartDashing then
                -- ตั้ง target ก่อน
                controller.CurrentTarget = nearestPlayer
                controller.IsChasing = true
                
                controller:StartDashing()
                dashCount = dashCount + 1
            end
        end
        
        print("[AI System] 🚀", dashCount, "enemies forced to dash at nearest player")
    end
    
    -- เปลี่ยนโอกาสพุ่ง
    _G.AISystem.SetDashChance = function(newChance)
        if newChance < 0 or newChance > 1 then
            warn("[AI System] Dash chance must be between 0 and 1")
            return
        end
        
        SimpleAIConfig.DashChance = newChance
        print("[AI System] 🎲 Dash chance changed to:", newChance * 100, "%")
    end
    
    -- เปลี่ยนแรง Knockback
    _G.AISystem.SetKnockbackForce = function(newForce)
        SimpleAIConfig.KnockbackForce = newForce
        print("[AI System] 💥 Knockback force changed to:", newForce)
    end
    
    -- เปลี่ยนระยะ Dash
    _G.AISystem.SetDashRange = function(minDistance, maxDistance)
        SimpleAIConfig.DashMinDistance = minDistance
        SimpleAIConfig.DashMaxDistance = maxDistance
        print("[AI System] 🎯 Dash range changed to:", minDistance, "-", maxDistance, "studs")
    end
    
    -- แสดงสถิติ Dash
    _G.AISystem.ShowDashStats = function()
        print("===========================================")
        print("[AI System] 🚀 Dash Statistics:")
        local dashingCount = 0
        local recoveringCount = 0
        local canDashCount = 0
        
        for _, controller in ipairs(activeControllers) do
            if controller.DashService then
                if controller.DashService:IsDashing() then
                    dashingCount = dashingCount + 1
                end
                if controller.DashService:IsRecovering() then
                    recoveringCount = recoveringCount + 1
                end
                if controller.DashService:CanDash() then
                    canDashCount = canDashCount + 1
                end
            end
        end
        
        print("  • Currently Dashing:", dashingCount)
        print("  • Currently Recovering:", recoveringCount)
        print("  • Ready to Dash:", canDashCount)
        print("  • Total Enemies:", #activeControllers)
        print("===========================================")
    end
end


-- ==========================================
-- แสดงคำแนะนำ
-- ==========================================
print("\n[AI System] 💡 Debug Commands:")
print("  _G.AISystem.GetActiveCount()      -- นับจำนวน AI")
print("  _G.AISystem.StartAll()            -- เริ่ม AI ทั้งหมด")
print("  _G.AISystem.StopAll()             -- หยุด AI ทั้งหมด")
print("  _G.AISystem.DebugFirstEnemy()     -- ดูสถานะ AI ตัวแรก")
print("  _G.AISystem.ShowAllStatus()       -- ดูสถานะทุกตัว")
print("  _G.AISystem.TestFirstEnemy()      -- ทดสอบ AI ตัวแรก")
print("  _G.AISystem.ResetAll()            -- รีเซ็ต AI ทั้งหมด")
print("  _G.AISystem.ShowConfig()          -- แสดง Config")

if CONFIG.EnablePhase2 then
    print("\n[AI System] 🏃 Phase 2 Commands:")
    print("  _G.AISystem.StopAllChase()        -- หยุดไล่ทั้งหมด")
    print("  _G.AISystem.SetDetectionRange(500) -- เปลี่ยนระยะตรวจจับ")
    print("  _G.AISystem.ForceChaseNearestPlayer() -- บังคับไล่ player ใกล้ที่สุด")
end



if CONFIG.EnablePhase3 then
    print("\n[AI System] 🚀 Phase 3 Commands:")
    print("  _G.AISystem.ForceDashNearestPlayer() -- บังคับพุ่งใส่ player ใกล้ที่สุด")
    print("  _G.AISystem.SetDashChance(0.5)      -- เปลี่ยนโอกาสพุ่ง (0-1)")
    print("  _G.AISystem.SetKnockbackForce(2000) -- เปลี่ยนแรงกระเด็น")
    print("  _G.AISystem.SetDashRange(50, 120)   -- เปลี่ยนระยะพุ่ง (min, max)")
    print("  _G.AISystem.ShowDashStats()         -- ดูสถิติการพุ่ง")
end



print("")

-- ==========================================
-- เฝ้าดู Player (Phase 2)
-- ==========================================
if CONFIG.EnablePhase2 then
    game.Players.PlayerAdded:Connect(function(player)
        print("[AI System] 👤 Player joined:", player.Name, "- AIs will detect them!")
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        print("[AI System] 👋 Player left:", player.Name)
    end)
end

-- ==========================================
-- เฝ้าดู Enemy ใหม่ที่เพิ่มเข้ามา
-- ==========================================
enemiesFolder.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child:FindFirstChild("Humanoid") then
        wait(0.5) -- รอให้โมเดลโหลดเสร็จ
        
        print("[AI System] 🆕 New enemy detected:", child.Name)
        
        local success, controller = pcall(function()
            local enemyData = repo:CreateSimpleEnemy(child)
            local newController = SimpleWalkController.new(child)
            
            if CONFIG.AutoStart then
                if newController.Start then
                    newController:Start()
                elseif newController.StartWalking then
                    newController:StartWalking()
                end
            end
            
            return newController
        end)
        
        if success then
            table.insert(activeControllers, controller)

             local features = {}
            if CONFIG.EnablePhase1 then table.insert(features, "Walk") end
            if CONFIG.EnablePhase2 then table.insert(features, "Chase") end
            if CONFIG.EnablePhase3 then table.insert(features, "Dash") end

            print("[AI System] ✅", child.Name, "- AI Started (" .. table.concat(features, " + ") .. ")")

            --print("[AI System] ✅", child.Name, "- AI Started")
        else
            warn("[AI System] ❌", child.Name, "- Failed to initialize")
        end
    end
end)

print("[AI System] 👀 Watching for new enemies...")