-- ========================================
-- 📄 ServerScriptService/PerkSystem/PerkManager.lua
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local Players = game:GetService("Players")

local PerkConfig = require(ReplicatedStorage.Config.PerkConfig)
local PlayerConfig = require(ReplicatedStorage.Config.PlayerConfig)


local NPCConfig = require(ReplicatedStorage.Config.NPCConfig)
local EventBus = require(ReplicatedStorage.Core.EventBus)

local PerkEffectApplier = require(game.ServerScriptService.ServerLocal.PerkSystem.PerkEffectApplier)



local PerkManager = {}

-- ========================================
-- 📊 เก็บข้อมูล Perk ของผู้เล่น
-- ========================================
local playerPerks = {} -- {[Player] = {Perk1, Perk2, Perk3}}

local playerRunes = {} -- {[Player] = {Rune1, Rune2}} -- 🔮 เพิ่มในอนาคต

local perkUsageData = {} -- {[Player] = {PerkName = {uses, cooldowns}}}

local playerStats = {} -- {[Player] = CalculatedStats}

-- ========================================
-- 🎯 ฟังก์ชันหลัก: กำหนด Perks ให้ผู้เล่น
-- ========================================
function PerkManager.AssignPerks(player, perkNames , runes)
    if not player or not perkNames then
        warn("⚠️ PerkManager.AssignPerks: Invalid player or perkNames")
        return false
    end
    
    -- ตรวจสอบจำนวน Perks
    if #perkNames > PerkConfig.MaxPerksPerPlayer then
        warn("⚠️ Player", player.Name, "tried to equip more than", PerkConfig.MaxPerksPerPlayer, "perks")
        return false
    end
    
    -- ตรวจสอบว่า Perks ที่เลือกมีอยู่จริง
    local validPerks = {}
    for _, perkName in ipairs(perkNames) do
        if PerkConfig.Perks[perkName] then
            table.insert(validPerks, perkName)
        else
            warn("⚠️ Invalid perk:", perkName)
        end
    end


    
    -- บันทึก Perks
    playerPerks[player] = validPerks

    playerRunes[player] = runes or {}

    perkUsageData[player] = {}
   
    
    -- เริ่มต้นข้อมูล usage
    -- เริ่มต้นข้อมูล usage สำหรับ Perks ที่ใช้งานได้จำกัด
    for _, perkName in ipairs(validPerks) do
        local perkData = PerkConfig.Perks[perkName]
        if perkData.UsesPerMatch then
            perkUsageData[player][perkName] = {
                usesLeft = perkData.UsesPerMatch,
                lastUsed = 0,
            }
        end
    end
    
    -- Apply Perks
    --PerkManager.ApplyAllPerks(player)

      -- คำนวณและ Apply
    PerkManager.RecalculatePlayerStats(player)


    print("✅ Assigned perks to", player.Name, ":", table.concat(validPerks, ", "))
    EventBus:Emit("PerksAssigned", player, validPerks)
    
    return true

end

-- ========================================
-- 🔄 Recalculate Stats (เรียกได้ตลอดเวลา)
-- ========================================
function PerkManager.RecalculatePlayerStats(player)
    local perks = playerPerks[player] or {}
    local runes = playerRunes[player] or {}
    
    -- คำนวณ Stats
    local stats = PerkEffectApplier.CalculatePlayerStats(player, perks, runes)
    playerStats[player] = stats
    
    -- Apply ให้ Character
    PerkEffectApplier.ApplyStatsToCharacter(player, stats)
    
    -- Apply แต่ละ Perk Effect
    for _, perkName in ipairs(perks) do
        PerkManager.ApplyPerkEffect(player, perkName)
    end
    
    print("🔄 Recalculated stats for", player.Name)
    EventBus:Emit("PlayerStatsRecalculated", player, stats)
end



-- ========================================
-- ⚡ Apply Perk Effect เดี่ยว
-- ========================================
function PerkManager.ApplyPerkEffect(player, perkName)
    local perkData = PerkConfig.Perks[perkName]
    if not perkData then return end
    
    local effectScript = script.Parent.PerkEffects:FindFirstChild("Effect_" .. perkName)
    if effectScript then
        local effectModule = require(effectScript)
        if effectModule.Apply then
            effectModule.Apply(player, perkData)
        end
    end
end





-- ========================================
-- 🔄 Apply ทุก Perks ของผู้เล่น
-- ========================================
function PerkManager.ApplyAllPerks(player)
    local perks = playerPerks[player]
    if not perks then return end
    
    for _, perkName in ipairs(perks) do
        PerkManager.ApplyPerk(player, perkName)
    end
end

-- ========================================
-- ⚡ Apply Perk เดี่ยว
-- ========================================
function PerkManager.ApplyPerk(player, perkName)
    local perkData = PerkConfig.Perks[perkName]
    if not perkData then
        warn("⚠️ Perk not found:", perkName)
        return
    end
    
    print("⚡ Applying perk:", perkName, "to", player.Name)
    
    -- ดึง Effects Script
    local effectScript = script.Parent.PerkEffects:FindFirstChild("Effect_" .. perkName)
    if effectScript then
        local effectModule = require(effectScript)
        if effectModule.Apply then
            effectModule.Apply(player, perkData)
        end
    else
        warn("⚠️ Effect script not found for:", perkName)
    end
    
    EventBus:Emit("PerkApplied", player, perkName)
end

-- ========================================
-- 🎯 เช็คว่าผู้เล่นมี Perk นี้หรือไม่
-- ========================================
function PerkManager.HasPerk(player, perkName)


    local perks = playerPerks[player]
    if not perks then return false end
    
    for _, name in ipairs(perks) do
        if name == perkName then
            return true
        end
    end
    return false

end


-- ========================================
-- 🔍 ดึงข้อมูล Perks ของผู้เล่น
-- ========================================
function PerkManager.GetPlayerPerks(player)
    return playerPerks[player] or {}
end


-- ========================================
-- 🤖 ดึงค่า Detection Range ที่ถูกแก้ไขโดย Perks
-- ========================================
function PerkManager.GetModifiedDetectionRange(npc, player)
    return PerkEffectApplier.ModifyNPCDetection(npc, player)
end


-- ========================================
-- 🔊 ดึงค่า Sound Volume ที่ถูกแก้ไขโดย Perks
-- ========================================
function PerkManager.GetModifiedSoundVolume(player, baseVolume)
    return PerkEffectApplier.ModifySoundDetection(player, baseVolume)
end



-- ========================================
-- 🔄 ใช้งาน Perk (สำหรับ Perks ที่มีจำกัดครั้ง)
-- ========================================
function PerkManager.UsePerk(player, perkName)
    if not PerkManager.HasPerk(player, perkName) then
        return false, "Perk not equipped"
    end
    
    local usage = perkUsageData[player][perkName]
    if not usage then
        return false, "Perk has no usage limit"
    end
    
    if usage.usesLeft <= 0 then
        return false, "No uses left"
    end
    

    local perkData = PerkConfig.Perks[perkName]
    local currentTime = tick()
    


    -- ตรวจสอบ Cooldown
    if perkData.InvisibilityCooldown then
        local timeSinceLastUse = currentTime - usage.lastUsed
        if timeSinceLastUse < perkData.InvisibilityCooldown then
            return false, "Cooldown: " .. math.ceil(perkData.InvisibilityCooldown - timeSinceLastUse) .. "s"
        end
    end

    


    -- ใช้ Perk
    usage.usesLeft = usage.usesLeft - 1
    usage.lastUsed = currentTime
    


    print("✅", player.Name, "used", perkName, "| Uses left:", usage.usesLeft)
    EventBus:Emit("PerkUsed", player, perkName, usage.usesLeft)
    
    return true, usage.usesLeft
end




-- ========================================
-- 📊 ดึงข้อมูล Usage
-- ========================================
function PerkManager.GetPerkUsage(player, perkName)
    if not perkUsageData[player] then return nil end
    return perkUsageData[player][perkName]
end

-- ========================================
-- 🧹 ลบ Perks เมื่อผู้เล่นออก
-- ========================================
function PerkManager.RemovePerks(player)

    playerPerks[player] = nil

    playerRunes[player] = nil

    perkUsageData[player] = nil

    playerStats[player] = nil

    print("🧹 Removed perks for", player.Name)
end

-- ========================================
-- 🔄 Reset Perks (สำหรับ Round ใหม่)
-- ========================================
function PerkManager.ResetPerks(player)

    local perks = playerPerks[player]
    if not perks then return end
   
    

    -- Reset usage counts
    for perkName, usage in pairs(perkUsageData[player] or {}) do

        local perkData = PerkConfig.Perks[perkName]
        if perkData.UsesPerMatch then
            usage.usesLeft = perkData.UsesPerMatch
            usage.lastUsed = 0
        end

    end
    

    -- Reset Attributes
    local character = player.Character
    if character then
        character:SetAttribute("SecondWindUsed", false)
        character:SetAttribute("EscapeArtistUsed", false)
    end


    -- Recalculate
    PerkManager.RecalculatePlayerStats(player)


    print("🔄 Reset perks for", player.Name)
    EventBus:Emit("PerksReset", player)

end

-- ========================================
-- 🔄 Update Loop สำหรับ Dynamic Perks
-- ========================================
function PerkManager.StartDynamicUpdates()
    RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if not playerPerks[player] then continue end
            
            local character = player.Character
            if not character then continue end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then continue end
            
            -- 🐺 Lone Wolf - เช็คว่าอยู่คนเดียวไหม
            if PerkManager.HasPerk(player, "LoneWolf") then
                local perkData = PerkConfig.Perks.LoneWolf
                local isAlone = PerkEffectApplier.CheckLoneWolf(player, perkData.SoloDetectionRange or 30)
                
                if isAlone then
                    local baseSpeed = PlayerConfig.Movement.WalkSpeed
                    humanoid.WalkSpeed = baseSpeed * (1 + perkData.SoloSpeedBonus)
                else
                    humanoid.WalkSpeed = PlayerConfig.Movement.WalkSpeed
                end
            end
            
            -- 🔗 Blood Link - เช็คว่าเพื่อนใกล้ถูกไล่ไหม
            if PerkManager.HasPerk(player, "BloodLink") then
                local perkData = PerkConfig.Perks.BloodLink
                local shouldActivate = PerkEffectApplier.CheckBloodLink(player, perkData.TriggerRange or 20)
                
                if shouldActivate then
                    local lastActivated = character:GetAttribute("BloodLinkLastActivated") or 0
                    local currentTime = tick()
                    
                    if currentTime - lastActivated >= perkData.SprintCooldown then
                        character:SetAttribute("BloodLinkActive", true)
                        character:SetAttribute("BloodLinkLastActivated", currentTime)
                        humanoid.WalkSpeed = PlayerConfig.Movement.RunSpeed
                        
                        print("🔗", player.Name, "Blood Link activated!")
                        EventBus:Emit("BloodLinkActivated", player)
                        
                        -- หมดเวลา
                        task.delay(perkData.SprintDuration or 2, function()
                            if character.Parent then
                                character:SetAttribute("BloodLinkActive", false)
                                humanoid.WalkSpeed = PlayerConfig.Movement.WalkSpeed
                            end
                        end)
                    end
                end
            end
        end
    end)
end




-- ========================================
-- 🎯 ตัวอย่าง: Modify Player Speed (สำหรับ LoneWolf)
-- ========================================
function PerkManager.ModifyPlayerSpeed(player, multiplier)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local baseSpeed = PlayerConfig.Movement.WalkSpeed
        humanoid.WalkSpeed = baseSpeed * multiplier
        print("🏃", player.Name, "speed modified to", humanoid.WalkSpeed)
    end
end

-- ========================================
-- 🎯 ตัวอย่าง: Check if player is alone (สำหรับ LoneWolf)
-- ========================================
function PerkManager.IsPlayerAlone(player, range)
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
-- 🔍 Debug: แสดง Perks ทั้งหมด
-- ========================================
function PerkManager.DebugPrintAllPerks()
    print("========== PLAYER PERKS ==========")

    for player, perks in pairs(playerPerks) do
        print(player.Name, ":", table.concat(perks, ", "))
        if playerStats[player] then
            print("  DetectionMultiplier:", playerStats[player].DetectionMultiplier)
            print("  SoundReduction:", playerStats[player].SoundReduction)
        end
    end

    print("==================================")
end


return PerkManager