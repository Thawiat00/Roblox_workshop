-- ==========================================
-- ServerLocal/Bootstrap/InitializeAI.server.lua (Script)
-- ==========================================
-- Orchestrator - เปิดไฟล์และให้ทำงาน
-- ✨ อัปเดตสำหรับ Phase 5

-- ==========================================

local ServerScriptService = game:GetService("ServerScriptService")

print("===========================================")
print("[AI System] 🚀 Starting AI System...")
print("===========================================")

-- ==========================================
-- ⚙️ CONFIG
-- ==========================================
local CONFIG = {
    EnablePhase1 = true,
    EnablePhase2 = true,
    EnablePhase3 = true,
    EnablePhase4 = true,

    EnablePhase5 = true,  -- ✨ เพิ่ม Phase 5

    AutoStart = true,

    AutoStartPlayerSoundEmitters = true,  -- ✨ เปิด Sound Emitter อัตโนมัติ


   --  SoundVisualEffect = false,  -- 👈 ปิด visual วงกลมเสียง ตั้งแต่เริ่ม ถ้าจะเปิด ก็ true

}

-- ==========================================
-- โหลด Phase Modules
-- ==========================================
local Phase1 = CONFIG.EnablePhase1 and require(ServerScriptService.ServerLocal.Bootstrap.Phase1_Walk)
local Phase2 = CONFIG.EnablePhase2 and require(ServerScriptService.ServerLocal.Bootstrap.Phase2_Chase)
local Phase3 = CONFIG.EnablePhase3 and require(ServerScriptService.ServerLocal.Bootstrap.Phase3_Dash)
local Phase4 = CONFIG.EnablePhase4 and require(ServerScriptService.ServerLocal.Bootstrap.Phase4_Impact)

local Phase5 = CONFIG.EnablePhase5 and require(ServerScriptService.ServerLocal.Bootstrap.Phase5_Sound)  -- ✨ Phase 5


print("[AI System] ✅ Phase Modules Loaded")

-- ==========================================
-- โหลด Dependencies
-- ==========================================
local SimpleWalkController = require(ServerScriptService.ServerLocal.Presentation.Controllers.SimpleWalkController)
local SimpleEnemyRepository = require(ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
local SimpleAIConfig = require(ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

print("[AI System] ✅ Dependencies Loaded")

-- ==========================================
-- Setup
-- ==========================================
local repo = SimpleEnemyRepository.GetInstance()
local enemiesFolder = workspace:FindFirstChild("Enemies") or Instance.new("Folder", workspace)
enemiesFolder.Name = "Enemies"

local activeControllers = {}

local playerSoundEmitters = {}  -- ✨ เก็บ Sound Emitters


-- ==========================================
-- สร้าง Controllers
-- ==========================================
print("[AI System] 🤖 Creating Controllers...")

for _, model in ipairs(enemiesFolder:GetChildren()) do
    if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        local success, controller = pcall(function()
            local enemyData = repo:CreateSimpleEnemy(model)
            return SimpleWalkController.new(model)
        end)
        
        if success then
            table.insert(activeControllers, controller)
            print("[AI System] ✅", model.Name)
        end
    end
end

print("[AI System] 📊 Created", #activeControllers, "controllers")

-- ==========================================
-- Initialize Phases
-- ==========================================
if #activeControllers > 0 then
    print("[AI System] ⚙️ Initializing Phases...")
    
    if Phase1 then Phase1.Initialize(repo, SimpleAIConfig) end
    if Phase2 then Phase2.Initialize(repo, SimpleAIConfig) end
    if Phase3 then Phase3.Initialize(repo, SimpleAIConfig) end
    if Phase4 then Phase4.Initialize(repo, SimpleAIConfig) end
    if Phase5 then Phase5.Initialize(repo, SimpleAIConfig) end  -- ✨ Phase 5

end

-- ==========================================
-- Start Systems
-- ==========================================
if CONFIG.AutoStart and #activeControllers > 0 then
    print("[AI System] 🚀 Starting Systems...")
    
    if Phase1 then Phase1.Start(activeControllers) end
    if Phase2 then Phase2.Start(activeControllers) end
    if Phase3 then Phase3.Start(activeControllers) end
    if Phase4 then Phase4.Start(activeControllers) end
    if Phase5 then Phase5.Start(activeControllers) end  -- ✨ Phase 5


        -- ✨ เริ่ม Player Sound Emitters
    if CONFIG.AutoStartPlayerSoundEmitters and Phase5 then
        playerSoundEmitters = Phase5.StartPlayerSoundEmitters(activeControllers)
    end

end

-- ==========================================
-- Global API
-- ==========================================
_G.AISystem = {
    Config = CONFIG,
    SimpleAIConfig = SimpleAIConfig,
    Controllers = activeControllers,

    PlayerSoundEmitters = playerSoundEmitters,  -- ✨ Phase 5


    Phase1 = Phase1,
    Phase2 = Phase2,
    Phase3 = Phase3,
    Phase4 = Phase4,

    Phase5 = Phase5,  -- ✨ Phase 5

    
    -- General
    GetActiveCount = function() return #activeControllers end,
    ShowAllStats = function()
        if Phase1 then Phase1.ShowStats(activeControllers) end
        if Phase2 then Phase2.ShowStats(activeControllers) end
        if Phase3 then Phase3.ShowStats(activeControllers) end
        if Phase4 then Phase4.ShowStats(activeControllers, SimpleAIConfig) end

        if Phase5 then Phase5.ShowStats(activeControllers, SimpleAIConfig) end  -- ✨ Phase 5

    end,
    
    -- Phase 1
    StartWalk = function() return Phase1 and Phase1.Start(activeControllers) or 0 end,
    StopWalk = function() return Phase1 and Phase1.Stop(activeControllers) or 0 end,
    ShowWalkStats = function() if Phase1 then Phase1.ShowStats(activeControllers) end end,
    
    -- Phase 2
    StopAllChase = function() return Phase2 and Phase2.StopAll(activeControllers) or 0 end,
    ForceChaseNearestPlayer = function() return Phase2 and Phase2.ForceChaseNearestPlayer(activeControllers) or 0 end,
    SetDetectionRange = function(range) return Phase2 and Phase2.SetDetectionRange(activeControllers, range) or 0 end,
    ShowChaseStats = function() if Phase2 then Phase2.ShowStats(activeControllers) end end,
    
    -- Phase 3
    ForceDashNearestPlayer = function() return Phase3 and Phase3.ForceDashNearestPlayer(activeControllers) or 0 end,
    SetDashChance = function(chance) return Phase3 and Phase3.SetDashChance(SimpleAIConfig, chance) or false end,
    SetKnockbackForce = function(force) return Phase3 and Phase3.SetKnockbackForce(SimpleAIConfig, force) or false end,
    SetDashRange = function(min, max) return Phase3 and Phase3.SetDashRange(SimpleAIConfig, min, max) or false end,
    ShowDashStats = function() if Phase3 then Phase3.ShowStats(activeControllers) end end,
    
    -- Phase 4
    TestImpact = function() return Phase4 and Phase4.TestImpact(activeControllers, SimpleAIConfig) or 0 end,
    SimulateImpact = function(name) return Phase4 and Phase4.SimulateImpact(activeControllers, name, SimpleAIConfig) or 0 end,
    SetImpactForce = function(force) return Phase4 and Phase4.SetImpactForce(SimpleAIConfig, activeControllers, force) or 0 end,
    SetImpactDuration = function(duration) return Phase4 and Phase4.SetImpactDuration(SimpleAIConfig, activeControllers, duration) or 0 end,
    SetImpactDamage = function(damage) return Phase4 and Phase4.SetImpactDamage(SimpleAIConfig, activeControllers, damage) or 0 end,
    ToggleGravityCompensation = function(enabled) return Phase4 and Phase4.ToggleGravityCompensation(SimpleAIConfig, enabled) or false end,
    ToggleVisualEffect = function(enabled) return Phase4 and Phase4.ToggleVisualEffect(SimpleAIConfig, activeControllers, enabled) or 0 end,
    ShowImpactStats = function() if Phase4 then Phase4.ShowStats(activeControllers, SimpleAIConfig) end end,
    ClearImpactRecords = function() return Phase4 and Phase4.ClearAllImpactRecords(activeControllers) or 0 end,
    ListImpactedPlayers = function() if Phase4 then Phase4.ListImpactedPlayers(activeControllers) end end,


    -- ✨ Phase 5: Sound Detection
    TestSoundEmission = function() return Phase5 and Phase5.TestSoundEmission(activeControllers, SimpleAIConfig) or 0 end,
    ForceInvestigateNearestSound = function() return Phase5 and Phase5.ForceInvestigateNearestSound(activeControllers) or 0 end,
    SetHearingRange = function(range) return Phase5 and Phase5.SetHearingRange(activeControllers, range) or 0 end,
    SetAlertDuration = function(duration) return Phase5 and Phase5.SetAlertDuration(activeControllers, duration) or 0 end,
    SetSoundRadius = function(radius) return Phase5 and Phase5.SetSoundRadius(SimpleAIConfig, radius) or false end,

    ToggleSoundVisual = function(enabled) return Phase5 and Phase5.ToggleVisualEffect(SimpleAIConfig, enabled) or false end,
   -- ToggleSoundVisual = function(enabled) return Phase5 and Phase5.ToggleVisualEffect(SimpleAIConfig, false) or false end,
    StopAllInvestigations = function() return Phase5 and Phase5.StopAllInvestigations(activeControllers) or 0 end,
    StartPlayerSoundEmitters = function() 
        if Phase5 then 
            playerSoundEmitters = Phase5.StartPlayerSoundEmitters(activeControllers)
            return playerSoundEmitters
        end
        return {}
    end,
    ShowSoundStats = function() if Phase5 then Phase5.ShowStats(activeControllers, SimpleAIConfig) end end,
    ListInvestigatingEnemies = function() if Phase5 then Phase5.ListInvestigatingEnemies(activeControllers) end end,
    ShowSoundHelp = function() if Phase5 then Phase5.ShowHelp() end end,


}

-- ==========================================
-- Auto-detect new enemies
-- ==========================================
enemiesFolder.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child:FindFirstChild("Humanoid") then
        task.wait(0.5)
        local success, controller = pcall(function()
            local enemyData = repo:CreateSimpleEnemy(child)
            local newController = SimpleWalkController.new(child)
            if Phase1 and CONFIG.AutoStart then Phase1.Start({newController}) end
            return newController
        end)
        if success then
            table.insert(activeControllers, controller)
            print("[AI System] ✅ New enemy:", child.Name)
        end
    end
end)

-- ==========================================
-- Ready
-- ==========================================
print("===========================================")
print("[AI System] ✅ System Ready!")
print("[AI System] 🤖 Active Controllers:", #activeControllers)
print("[AI System] 🔊 Player Sound Emitters:", #game.Players:GetPlayers())

print("[AI System] 💡 Use: _G.AISystem.ShowAllStats()")

print("[AI System] 💡 Use: _G.AISystem.ShowSoundHelp() for Phase 5 commands")


print("===========================================")