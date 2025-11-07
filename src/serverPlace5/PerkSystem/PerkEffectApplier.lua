-- ========================================
-- 📄 ServerScriptService/PerkSystem/PerkEffectApplier.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerConfig = require(ReplicatedStorage.Config.PlayerConfig)
local NPCConfig = require(ReplicatedStorage.Config.NPCConfig)
local PerkConfig = require(ReplicatedStorage.Config.PerkConfig)
local EventBus = require(ReplicatedStorage.Core.EventBus)

local PerkEffectApplier = {}

-- ========================================
-- 🎯 คำนวณค่า Player Stats จาก Perks ทั้งหมด
-- ========================================
function PerkEffectApplier.CalculatePlayerStats(player, perks, runes)
    local stats = {
        -- Movement
        WalkSpeed = PlayerConfig.Movement.WalkSpeed,
        RunSpeed = PlayerConfig.Movement.RunSpeed,
        
        -- Sound
        SoundReduction = 0,
        
        -- Detection
        IsInvisible = false,
        DetectionMultiplier = 1.0, -- ยิ่งต่ำยิ่งตรวจจับยาก
        
        -- Abilities
        CanThrowDistraction = false,
        HasSecondWind = false,
        HasEscapeArtist = false,
        
        -- Puzzle
        PuzzleSpeedBonus = 0,
        PuzzleDifficultyReduction = 0,
        
        -- Healing
        HealSpeedBonus = 0,
        
        -- Stamina
        StaminaRegenBonus = 0,
        
        -- UI Effects
        DisableCameraShake = false,
        NoTitanProximityWarning = false,
        
        -- Special
        IsAlone = false, -- จะคำนวณแยก
    }
    
    -- วนลูป Perks ทั้งหมด
    for _, perkName in ipairs(perks) do
        local perkData = PerkConfig.Perks[perkName]
        if not perkData then continue end
        
        -- 🔇 Silent Step
        if perkName == "SilentStep" then
            stats.SoundReduction = stats.SoundReduction + (perkData.WalkSoundReduction or 0)
            stats.DetectionMultiplier = stats.DetectionMultiplier * (1 - perkData.WalkSoundReduction)
        end
        
        -- 🧠 Fast Learner
        if perkName == "FastLearner" then
            stats.PuzzleSpeedBonus = stats.PuzzleSpeedBonus + (perkData.PuzzleSpeedBonus or 0)
        end
        
        -- 💨 Second Wind
        if perkName == "SecondWind" then
            stats.HasSecondWind = true
        end
        
        -- 🏥 Medic Instinct
        if perkName == "MedicInstinct" then
            stats.HealSpeedBonus = stats.HealSpeedBonus + (perkData.HealSpeedBonus or 0)
        end
        
        -- 🛡️ Iron Nerves
        if perkName == "IronNerves" then
            stats.DisableCameraShake = true
            stats.NoTitanProximityWarning = true
        end
        
        -- 🐺 Lone Wolf (คำนวณแยก)
        if perkName == "LoneWolf" then
            -- จะเช็คใน Update Loop
        end
        
        -- 🎭 Escape Artist
        if perkName == "EscapeArtist" then
            stats.HasEscapeArtist = true
        end
        
        -- 🎯 Distraction
        if perkName == "Distraction" then
            stats.CanThrowDistraction = true
        end
        
        -- 🤲 Steady Hands
        if perkName == "SteadyHands" then
            stats.PuzzleDifficultyReduction = stats.PuzzleDifficultyReduction + (perkData.PuzzleDifficultyReduction or 0)
        end
        
        -- 🔗 Blood Link
        if perkName == "BloodLink" then
            -- จะเช็คใน Event
        end
        
        -- 👂 Keen Hearing
        if perkName == "KeenHearing" then
            stats.TitanSoundBonus = perkData.TitanSoundBonus or 0
        end
        
        -- 🏃 Self Focus
        if perkName == "SelfFocus" then
            stats.StaminaRegenBonus = stats.StaminaRegenBonus + (perkData.StaminaRegenBonus or 0)
        end
    end
    
    -- 🔮 Apply Rune Bonuses (ถ้ามี)
    if runes then
        for _, runeName in ipairs(runes) do
            -- ตัวอย่าง: ShadowRune เพิ่ม SoundReduction
            if runeName == "ShadowRune" then
                stats.SoundReduction = stats.SoundReduction + 0.2
                stats.DetectionMultiplier = stats.DetectionMultiplier * 0.8
            end
        end
    end
    
    return stats
end

-- ========================================
-- 🎯 Apply Stats ให้ Character
-- ========================================
function PerkEffectApplier.ApplyStatsToCharacter(player, stats)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Apply Movement Speed
    humanoid.WalkSpeed = stats.WalkSpeed
    
    -- Set Attributes สำหรับระบบอื่นอ่าน
    character:SetAttribute("SoundReduction", stats.SoundReduction)
    character:SetAttribute("DetectionMultiplier", stats.DetectionMultiplier)
    character:SetAttribute("IsInvisible", stats.IsInvisible)
    character:SetAttribute("PuzzleSpeedBonus", stats.PuzzleSpeedBonus)
    character:SetAttribute("HealSpeedBonus", stats.HealSpeedBonus)
    character:SetAttribute("StaminaRegenBonus", stats.StaminaRegenBonus)
    character:SetAttribute("DisableCameraShake", stats.DisableCameraShake)
    character:SetAttribute("NoTitanWarning", stats.NoTitanProximityWarning)
    
    print("⚡ Applied stats to", player.Name)
end

-- ========================================
-- 🤖 คำนวณผลต่อ NPC Detection
-- ========================================
function PerkEffectApplier.ModifyNPCDetection(npc, player)
    local character = player.Character
    if not character then return end
    
    -- ดึงค่า Detection Multiplier จาก Player
    local detectionMultiplier = character:GetAttribute("DetectionMultiplier") or 1.0
    local isInvisible = character:GetAttribute("IsInvisible") or false
    local soundReduction = character:GetAttribute("SoundReduction") or 0
    
    -- ถ้าหายตัว → Detection Range = 0
    if isInvisible then
        return 0
    end
    
    -- คำนวณ Detection Range ใหม่
    local baseRange = NPCConfig.Detection.Range
    local modifiedRange = baseRange * detectionMultiplier
    
    -- ลดเพิ่มจากเสียง
    modifiedRange = modifiedRange * (1 - soundReduction * 0.5)
    
    return math.max(modifiedRange, 2) -- ขั้นต่ำ 2 studs
end

-- ========================================
-- 🔊 คำนวณผลต่อ Sound Detection
-- ========================================
function PerkEffectApplier.ModifySoundDetection(player, baseVolume)
    local character = player.Character
    if not character then return baseVolume end
    
    local soundReduction = character:GetAttribute("SoundReduction") or 0
    
    return baseVolume * (1 - soundReduction)
end

-- ========================================
-- 👥 เช็คว่าผู้เล่นอยู่คนเดียวไหม (สำหรับ Lone Wolf)
-- ========================================
function PerkEffectApplier.CheckLoneWolf(player, range)
    local Players = game:GetService("Players")
    local character = player.Character
    if not character or not character.PrimaryPart then return false end
    
    local position = character.PrimaryPart.Position
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local distance = (position - otherRoot.Position).Magnitude
                if distance <= range then
                    return false -- มีคนอยู่ใกล้
                end
            end
        end
    end
    
    return true -- อยู่คนเดียว
end

-- ========================================
-- 🎯 เช็คว่าเพื่อนใกล้ถูกไล่ไหม (สำหรับ Blood Link)
-- ========================================
function PerkEffectApplier.CheckBloodLink(player, range)
    local Players = game:GetService("Players")
    local character = player.Character
    if not character or not character.PrimaryPart then return false end
    
    local position = character.PrimaryPart.Position
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local distance = (position - otherRoot.Position).Magnitude
                if distance <= range then
                    -- เช็คว่าถูกไล่อยู่ไหม
                    local isBeingChased = otherPlayer.Character:GetAttribute("IsBeingChased")
                    if isBeingChased then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

return PerkEffectApplier


--