-- ========================================
-- 📄 ServerScriptService/NPCAI/Skills/Skill_Stun.lua
-- รวมระบบตะโกน + ผลัก + แช่แข็ง
-- ปรับปรุงให้ไม่ค้างหลัง stun
-- ========================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

local Skill_Stun = {}
local frozenCharacters = {} -- เก็บสถานะ frozen

------------------------------------------------------------
-- 🔹 ผลักผู้เล่นเมื่อโดนคลื่น
------------------------------------------------------------
local function PushCharacter(character, fromCFrame)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local PUSH_FORCE = 100
    local UP_FORCE = 20
    local mass = root.AssemblyMass
    local direction = (root.Position - fromCFrame.Position).Unit
    local impulse = (direction * PUSH_FORCE * mass) + Vector3.new(0, UP_FORCE * mass, 0)

    root:ApplyImpulse(impulse)
    print("💨 Pushed:", character.Name)
end

------------------------------------------------------------
-- 🔹 แช่แข็งผู้เล่น (หยุดเคลื่อนไหว + กระโดด)
------------------------------------------------------------
local function FreezeCharacter(character, duration)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if frozenCharacters[character] then
        -- ถ้า frozen อยู่แล้ว เพิ่มเวลา
        frozenCharacters[character].remaining = duration
        return
    end

    local originalSpeed = humanoid.WalkSpeed
    local originalJump = humanoid.JumpPower
    local originalPlatformStand = humanoid.PlatformStand

    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
   -- humanoid.PlatformStand = true

    frozenCharacters[character] = {
        humanoid = humanoid,
        remaining = duration,
        originalSpeed = originalSpeed,
        originalJump = originalJump,
     --   originalPlatformStand = originalPlatformStand
    }

    EventBus:Emit("PlayerStunned", {
        target = character.Name,
        duration = duration
    })

    print("❄️", character.Name, "frozen for", duration, "sec")

    task.spawn(function()
        local elapsed = 0
        while elapsed < duration do
            task.wait(0.1)
            elapsed = elapsed + 0.1
        end

        if humanoid and frozenCharacters[character] then
            humanoid.WalkSpeed = frozenCharacters[character].originalSpeed
            humanoid.JumpPower = frozenCharacters[character].originalJump
         --   humanoid.PlatformStand = frozenCharacters[character].originalPlatformStand
            frozenCharacters[character] = nil
            print("🔥", character.Name, "movement restored")
        end
    end)
end

------------------------------------------------------------
-- 🔹 เอฟเฟกต์วงคลื่นตะโกน
------------------------------------------------------------
local function CreateExpandingRing(originPos, initialRadius, finalRadius, pieces, duration)
    pieces = pieces or 30
    initialRadius = initialRadius or 2
    finalRadius = finalRadius or 15
    duration = duration or 1

    local parts = {}
    local hitPlayers = {} -- ป้องกันผลัก/แช่แข็งซ้ำ

    for i = 1, pieces do
        local angle = (i / pieces) * math.pi * 2
        local x = originPos.X + math.cos(angle) * initialRadius
        local z = originPos.Z + math.sin(angle) * initialRadius

        local part = Instance.new("Part")
        part.Size = Vector3.new(1, 0.5, 1)
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(0, 200, 255)
        part.Position = Vector3.new(x, originPos.Y, z)
        part.Parent = workspace

        table.insert(parts, {part = part, angle = angle})
    end

    for _, info in pairs(parts) do
        local targetPos = Vector3.new(
            originPos.X + math.cos(info.angle) * finalRadius,
            originPos.Y,
            originPos.Z + math.sin(info.angle) * finalRadius
        )

        local tween = TweenService:Create(
            info.part,
            TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {Position = targetPos, Transparency = 1}
        )

        -- เช็คทุก frame ว่าผู้เล่นชน part หรือยัง
        local connection
        connection = RunService.Heartbeat:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not hitPlayers[player] then
                    local rootPos = player.Character.HumanoidRootPart.Position
                    if (rootPos - info.part.Position).Magnitude <= 2 then
                        PushCharacter(player.Character, info.part.CFrame)
                        FreezeCharacter(player.Character, 2)
                        hitPlayers[player] = true
                    end
                end
            end
        end)

        tween:Play()
        tween.Completed:Connect(function()
            info.part:Destroy()
            if connection then
                connection:Disconnect()
            end
        end)
    end
end

------------------------------------------------------------
-- 🔹 ฟังก์ชันหลักของสกิล
------------------------------------------------------------
function Skill_Stun.Execute(npc, target)
    local config = SkillConfig.Skills.Stun
    local npcRoot = npc.root or npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot or not target then return false end

    local distance = (target.Position - npcRoot.Position).Magnitude
    if distance > config.Range then return false end

    print("⚡", npc.model.Name, "used Stun!")

    -- 1️⃣ สร้างเอฟเฟกต์คลื่น
    CreateExpandingRing(npcRoot.Position, 1, 30, 30, 5)

    -- 2️⃣ ตรวจว่าผู้เล่นอยู่ในระยะตรงหน้า
    local targetCharacter = target.Parent
    if targetCharacter then
        local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        if targetHumanoid then
            PushCharacter(targetCharacter, npcRoot.CFrame)
            FreezeCharacter(targetCharacter, config.StunDuration)
        end
    end

    return true
end

return Skill_Stun
