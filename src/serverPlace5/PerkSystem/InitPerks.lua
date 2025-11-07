-- ========================================
-- 📄 ServerScriptService/PerkSystem/InitPerks.server.lua
-- ========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PerkManager = require(script.Parent.PerkManager)
local EventBus = require(ReplicatedStorage.Core.EventBus)

local PerkConfig = require(ReplicatedStorage.Config.PerkConfig)



--print("🎮 Initializing Perk System...")
print("🎮 Initializing Perk System V2...")



-- ========================================
-- 🔌 เชื่อมต่อกับ EventBus
-- ========================================

-- ฟังเมื่อผู้เล่นเข้าเกม
Players.PlayerAdded:Connect(function(player)
    print("👤 Player joined:", player.Name)

    
    -- รอให้ Character โหลด
    player.CharacterAdded:Connect(function(character)

        -- ตั้งค่า Perks เริ่มต้น (จำลอง)
        -- ในเกมจริง คุณจะดึงจาก DataStore หรือ GUI
        local selectedPerks = {"SilentStep", "SecondWind", "LoneWolf"}
    
        local selectedRunes = {} -- เพิ่ม Rune ในอนาคต

        PerkManager.AssignPerks(player, selectedPerks , selectedRunes)

        -- ตั้งค่า Attributes เริ่มต้น
        character:SetAttribute("IsBeingChased", false)


    end)
end)



-- ฟังเมื่อผู้เล่นออกเกม
Players.PlayerRemoving:Connect(function(player)
    PerkManager.RemovePerks(player)
    print("👋 Player left:", player.Name)
end)




-- ========================================
-- 🎯 Event Handlers
-- ========================================


-- เมื่อผู้เล่นควรจะตาย → เช็ค Second Wind
EventBus:On("PlayerDying", function(player)
    if PerkManager.HasPerk(player, "SecondWind") then
        local effectScript = script.Parent.PerkEffects.Effect_SecondWind
        local effect = require(effectScript)
        
        local perkData = require(ReplicatedStorage.Config.PerkConfig).Perks.SecondWind
        
        local saved = effect.OnPlayerDown(player, perkData)
        if saved then
            print("💨 Second Wind saved", player.Name)
        end
    end
end)



-- เมื่อผู้เล่นหลบ → เช็ค Shadow Dodge
EventBus:On("PlayerDodged", function(player)
    if PerkManager.HasPerk(player, "ShadowDodge") then
        local effectScript = script.Parent.PerkEffects.Effect_ShadowDodge
        local effect = require(effectScript)
        
        local perkData = require(ReplicatedStorage.Config.PerkConfig).Perks.ShadowDodge
        
        effect.OnDodge(player, perkData)
    end
end)


-- เมื่อผู้เล่นถูกจับ → เช็ค Escape Artist
EventBus:On("PlayerCaptured", function(player, npc)
    if PerkManager.HasPerk(player, "EscapeArtist") then
        local effectScript = script.Parent.PerkEffects.Effect_EscapeArtist
        local effect = require(effectScript)
        
        local perkData = require(ReplicatedStorage.Config.PerkConfig).Perks.EscapeArtist
        
        effect.OnCaptured(player, npc, perkData)
    end
end)



-- เมื่อผู้เล่นหายตัว → ปรับ NPC Detection
EventBus:On("PlayerInvisible", function(player, duration)
    local character = player.Character
    if not character then return end
    
    -- ลด Detection Range ของ NPC
    local NPCAIController = require(game.ServerScriptService.NPCAI.NPCAIController)
    local allNPCs = NPCAIController.GetAllNPCs()
    
    for _, npc in ipairs(allNPCs) do
        -- บันทึก Detection Range เดิม
        if not npc._originalDetectionRange then
            npc._originalDetectionRange = npc.detectionRange or 50
        end
        
        -- ลดการตรวจจับ (ทำให้ไม่เห็นผู้เล่น)
        npc.detectionRange = 0
    end
    
   -- Recalculate Stats เพื่อปรับ Detection
    PerkManager.RecalculatePlayerStats(player)

    print("👻 NPCs can't detect", player.Name, "for", duration, "seconds")
end)

EventBus:On("PlayerVisible", function(player)
    local NPCAIController = require(game.ServerScriptService.NPCAI.NPCAIController)
    local allNPCs = NPCAIController.GetAllNPCs()
    
    for _, npc in ipairs(allNPCs) do
        -- คืนค่า Detection Range
        if npc._originalDetectionRange then
            npc.detectionRange = npc._originalDetectionRange
        end
    end


    -- Recalculate Stats
    PerkManager.RecalculatePlayerStats(player)
    
    print("👤 NPCs can detect", player.Name, "again")
end)

-- เมื่อ Round เริ่มใหม่ → Reset Perks
EventBus:On("RoundStarted", function()
    for _, player in ipairs(Players:GetPlayers()) do
        PerkManager.ResetPerks(player)
    end
    print("🔄 All perks reset for new round")
end)


-- เมื่อผู้เล่นทำ Puzzle
EventBus:On("PlayerStartPuzzle", function(player)
    local stats = PerkManager.GetPlayerStats(player)
    if stats then
        local speedBonus = stats.PuzzleSpeedBonus or 0
        local difficultyReduction = stats.PuzzleDifficultyReduction or 0
        
        print("🧩", player.Name, "starting puzzle | Speed:", speedBonus * 100, "% | Difficulty:", difficultyReduction * 100, "%")
        
        -- ส่งค่าให้ระบบ Puzzle
        EventBus:Emit("ApplyPuzzleModifiers", player, speedBonus, difficultyReduction)
    end
end)



-- เมื่อผู้เล่นช่วยเพื่อน
EventBus:On("PlayerStartHealing", function(player, target)
    local stats = PerkManager.GetPlayerStats(player)
    if stats then
        local healSpeedBonus = stats.HealSpeedBonus or 0
        
        print("🏥", player.Name, "healing", target.Name, "| Speed:", healSpeedBonus * 100, "%")
        
        -- ส่งค่าให้ระบบ Healing
        EventBus:Emit("ApplyHealingModifiers", player, target, healSpeedBonus)
    end
end)


-- ========================================
-- 🎯 Event Handlers: AI Detection
-- ========================================

-- เมื่อ NPC เริ่มไล่ผู้เล่น
EventBus:On("NPCStartChasing", function(npc, player)
    local character = player.Character
    if character then
        character:SetAttribute("IsBeingChased", true)
        print("🏃 NPC started chasing", player.Name)
    end
end)

-- เมื่อ NPC หยุดไล่
EventBus:On("NPCStopChasing", function(npc, player)
    local character = player.Character
    if character then
        character:SetAttribute("IsBeingChased", false)
        print("✋ NPC stopped chasing", player.Name)
    end
end)



-- ========================================
-- 🎯 Remote Events (สำหรับ Client)
-- ========================================

local RE_RequestRecalculate = Instance.new("RemoteEvent")
RE_RequestRecalculate.Name = "RE_RequestRecalculate"
RE_RequestRecalculate.Parent = ReplicatedStorage.Common

-- Client สามารถขอให้ Recalculate Stats (เช่นเมื่อเปลี่ยน Rune)
RE_RequestRecalculate.OnServerEvent:Connect(function(player)
    print("🔄 Recalculate request from", player.Name)
    PerkManager.RecalculatePlayerStats(player)
end)


-- ========================================
-- 🎯 Dynamic Updates (Lone Wolf, Blood Link)
-- ========================================

PerkManager.StartDynamicUpdates()


-- ========================================
-- 🧪 Testing Commands (ลบออกในเกมจริง)
-- ========================================
EventBus:On("TestPerk", function(player, perkName)
    if PerkManager.HasPerk(player, perkName) then
        print("✅", player.Name, "has", perkName)
    else
        print("❌", player.Name, "does NOT have", perkName)
    end
end)


-- คำสั่งแสดง Stats
EventBus:On("ShowPlayerStats", function(player)
    local stats = PerkManager.GetPlayerStats(player)
    if stats then
        print("========== STATS:", player.Name, "==========")
        for key, value in pairs(stats) do
            print("  ", key, ":", value)
        end
        print("========================================")
    end
end)


-- คำสั่ง Force Recalculate ทุกคน
EventBus:On("RecalculateAll", function()
    for _, player in ipairs(Players:GetPlayers()) do
        PerkManager.RecalculatePlayerStats(player)
    end
    print("🔄 Recalculated all players")
end)




-- แสดงข้อมูล Debug
task.spawn(function()
    while true do
        task.wait(60)
        PerkManager.DebugPrintAllPerks()
    end
end)

print("✅ Perk System V2 Ready!")
print("🔗 Connected with AI Detection System")
print("🎮 Dynamic Perks Active (Lone Wolf, Blood Link)")


