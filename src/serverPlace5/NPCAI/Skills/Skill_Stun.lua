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
-- 🔹 ผลักผู้เล่นเมื่อโดนคลื่น (ใช้ BodyVelocity)
------------------------------------------------------------
local function PushCharacter(character, fromPosition)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- คำนวณทิศทางผลัก (จากศูนย์กลางออกไป)
    local direction = (root.Position - fromPosition).Unit
    local knockbackForce = Random.new():NextNumber(60, 80) -- ระยะผลัก 20-30 หน่วย
    
    -- สร้าง BodyVelocity เพื่อผลัก
    local bodyVelocity = Instance.new("BodyVelocity")
   -- bodyVelocity.MaxForce = Vector3.new(100000, 1000, 100000) -- ไม่ผลักแกน Y
   -- bodyVelocity.Velocity = direction * knockbackForce
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000) -- ✅ เปลี่ยน Y เป็น 100000 เพื่อให้ผลักขึ้นได้
    bodyVelocity.Velocity = (direction * knockbackForce) + Vector3.new(0, 30, 0) -- ✅ เพิ่มแรงขึ้นแกน Y
    bodyVelocity.Parent = root
    
--⚙️ ปรับระดับการกระเด็น:

--Vector3.new(0, 20, 0) = กระเด็นขึ้นเล็กน้อย
--Vector3.new(0, 30, 0) = กระเด็นขึ้นปานกลาง ⭐ แนะนำ
--Vector3.new(0, 50, 0) = กระเด็นขึ้นสูงมาก
--Vector3.new(0, 80, 0) = บินขึ้นฟ้า 🚀

--ลองปรับค่าตามความต้องการได้เลยครับ! 🎊

    -- ลบ BodyVelocity หลังจาก 0.3 วินาที
    task.delay(0.3, function()
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
        end
    end)
    
    print("💨 Pushed:", character.Name, "with force", knockbackForce)
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

    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    frozenCharacters[character] = {
        humanoid = humanoid,
        remaining = duration,
        originalSpeed = originalSpeed,
        originalJump = originalJump,
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
                        -- ✅ ผลักผู้เล่นออกไป 20-30 หน่วย
                        PushCharacter(player.Character, originPos)
                        
                        -- ✅ แช่แข็งผู้เล่น
                        -- ปรับระยะเวลาสตัน ตรงนี้
                        FreezeCharacter(player.Character, SkillConfig.Skills.Stun.StunDuration)
                        
                        -- ✅ ทำครั้งเดียวต่อผู้เล่น
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

    -- สร้างเอฟเฟกต์คลื่นที่จะผลักและแช่แข็งผู้เล่นอัตโนมัติ
    CreateExpandingRing(npcRoot.Position, 1, 30, 30, 5)

    return true
end

return Skill_Stun