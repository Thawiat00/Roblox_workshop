-- ========================================
-- 📄 ServerScriptService/NPCAI/Utils/TargetFinder.lua
-- ⚡ Perk-Aware Version
-- ========================================

local Players = game:GetService("Players")
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

-- 🔥 เพิ่มการเชื่อม PerkManager
local PerkManager = require(game.ServerScriptService.ServerLocal.PerkSystem.PerkManager)

local TargetFinder = {}

-- ========================================
-- 🎯 หาผู้เล่นที่ใกล้ที่สุด (ปรับตาม Perks)
-- ========================================
function TargetFinder.FindNearestPlayer(npc)
    local closestPlayer = nil
    local closestDistance = math.huge
    local npcPosition = npc.root.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            
            -- เช็คว่าผู้เล่นยังมีชีวิตอยู่
            if humanoid and humanoid.Health > 0 then
                local targetRoot = character.HumanoidRootPart
                local distance = (npcPosition - targetRoot.Position).Magnitude
                
                -- 🔥 ดึงค่า Detection Range ที่ถูกแก้ไขโดย Perks
                local modifiedRange = PerkManager.GetModifiedDetectionRange(npc, player)
                
                -- 👻 เช็คว่าผู้เล่นหายตัวอยู่ไหม
                local isInvisible = character:GetAttribute("IsInvisible") or false
                if isInvisible then
                    -- ถ้าหายตัว → ตรวจจับไม่เห็น
                    continue
                end
                
                -- เช็คว่าอยู่ในระยะตรวจจับ (ปรับตาม Perk)
                if distance <= modifiedRange then
                    if distance < closestDistance then
                        closestPlayer = targetRoot
                        closestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer, closestDistance
end

-- ========================================
-- 🔊 หาผู้เล่นจากเสียง (ปรับตาม Perks)
-- ========================================
function TargetFinder.FindPlayerBySound(npc, soundRadius)
    local npcPosition = npc.root.Position
    


    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local targetRoot = character.HumanoidRootPart
                local distance = (npcPosition - targetRoot.Position).Magnitude
                
                -- 🔥 ดึงค่า Sound Reduction จาก Perks
                local soundReduction = character:GetAttribute("SoundReduction") or 0
                local modifiedRadius = soundRadius * (1 - soundReduction)
                
                -- เช็คว่ากำลังวิ่งอยู่ไหม (วิ่งเสียงดังกว่า)
                local isRunning = humanoid.WalkSpeed > 20
                if isRunning then
                    modifiedRadius = modifiedRadius * 1.3
                end
                
                -- เช็คระยะ
                if distance <= modifiedRadius then
                    print("🔊 NPC heard", player.Name, "at distance", math.floor(distance), "(Modified radius:", math.floor(modifiedRadius), ")")
                    return targetRoot, distance
                end
            end
        end
    end
    
    return nil, nil
end

-- ========================================
-- 👁️ เช็คว่าผู้เล่นอยู่ในสายตา (Line of Sight)
-- ========================================
function TargetFinder.HasLineOfSight(npc, target)
    if not target then return false end
    
    local origin = npc.root.Position + Vector3.new(0, 2, 0) -- ตาของ NPC
    local direction = (target.Position - origin).Unit
    local distance = (target.Position - origin).Magnitude
    
    -- Raycast
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {npc.model, target.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(origin, direction * distance, rayParams)
    
    -- ถ้าไม่มีสิ่งกีดขวาง = เห็น


    return result == nil    

end

-- ========================================
-- 🎯 หา Target พร้อมเช็ค Line of Sight
-- ========================================
function TargetFinder.FindVisiblePlayer(npc)
    local target, distance = TargetFinder.FindNearestPlayer(npc)
    
    if target then
        if TargetFinder.HasLineOfSight(npc, target) then
            return target, distance
        end
    end
    
    return nil, nil
end

-- ========================================
-- 🦶 หารอยเท้าผู้เล่นที่ใกล้ที่สุด
-- ========================================
function TargetFinder.FindNearestFootprint(npc, searchRadius)
    local npcPosition = npc.root.Position
    local closestFootprint = nil
    local closestDistance = math.huge
    
    -- หารอยเท้าใน Workspace
    local footprintFolder = workspace:FindFirstChild("Footprints")
    if not footprintFolder then return nil, nil end
    
    for _, footprint in ipairs(footprintFolder:GetChildren()) do
        if footprint:HasTag("PlayerFootprint") then
            local distance = (npcPosition - footprint.Position).Magnitude
            
            if distance <= searchRadius and distance < closestDistance then
                -- 🔥 เช็คว่ารอยเท้านี้มีเสียงที่ลดหรือไม่
                local ownerUserId = footprint:GetAttribute("OwnerUserId")
                if ownerUserId then
                    local owner = Players:GetPlayerByUserId(ownerUserId)
                    if owner and owner.Character then
                        local soundReduction = owner.Character:GetAttribute("SoundReduction") or 0
                        
                        -- ถ้า SoundReduction สูง → รอยเท้าหาได้ยากขึ้น
                        local detectionChance = 1 - (soundReduction * 0.5)
                        if math.random() > detectionChance then
                            continue -- ไม่เจอรอยเท้านี้
                        end
                    end
                end
                
                closestFootprint = footprint
                closestDistance = distance
            end
        end
    end

    

    return closestFootprint, closestDistance
end


return TargetFinder

