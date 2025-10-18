-- ========================================
-- 📄 Skill_Charge.lua
-- สร้างจุดข้างหลัง target แล้วให้ npc พุ่งไปยังจุดนั้น
-- ========================================

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)

local Skill_Charge = {}

function Skill_Charge.Execute(npc, target)
    local config = SkillConfig.Skills.Charge
    if not npc or not target then
        warn("❌ ไม่มี npc หรือ target")
        return false
    end

    -- 🧍‍♂️ หา HumanoidRootPart ของ npc
    local root = npc.root or (npc.model and npc.model:FindFirstChild("HumanoidRootPart"))
    if not root then
        warn("❌ ไม่พบ HumanoidRootPart ของ npc")
        return false
    end

    -- 🎯 รองรับทั้ง Model และ Part เป็น target
    local targetRoot
    if target:IsA("Model") then
        targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
    elseif target:IsA("BasePart") then
        targetRoot = target
    end

    if not targetRoot then
        warn("❌ ไม่พบตำแหน่งของ target:", target.Name)
        return false
    end

    print("⚡", npc.model.Name, "ใช้สกิล Charge ใส่", target.Name)

    -- 🧭 คำนวณจุดข้างหลัง target
    local direction = -targetRoot.CFrame.LookVector
    local distanceBehind = config.DistanceBehind or 25
    local pointPosition = targetRoot.Position + (direction * distanceBehind)

    -- 💠 สร้างจุดที่มองเห็นได้ (ไว้ดู)
    local pointPart = Instance.new("Part")
    pointPart.Name = "ChargePoint"
    pointPart.Size = Vector3.new(3, 3, 3)
    pointPart.Anchored = true
    pointPart.CanCollide = false
    pointPart.Color = Color3.fromRGB(0, 170, 255)
    pointPart.Material = Enum.Material.Neon
    pointPart.Position = pointPosition
    pointPart.Parent = workspace
    Debris:AddItem(pointPart, 4) -- ลบใน 4 วิ

    print("📍 จุด Charge ถูกสร้างที่:", pointPosition)

    -- 🚀 เริ่มพุ่งไปยังจุดนั้น (ใช้ Tween)
    local distance = (pointPosition - root.Position).Magnitude
    local speed = config.Speed or 80
    local duration = distance / speed

    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(root, tweenInfo, {
        CFrame = CFrame.new(pointPosition, pointPosition + direction)
    })

    print("🚀", npc.model.Name, "พุ่งไปยังจุด Charge ใช้เวลา", string.format("%.2f", duration), "วินาที")

    npc.IsCharging = true
    tween:Play()
    tween.Completed:Wait()
    npc.IsCharging = false

    print("✅", npc.model.Name, "ถึงจุด Charge แล้ว")

    return true
end

return Skill_Charge
