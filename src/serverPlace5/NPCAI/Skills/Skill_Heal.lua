-- ========================================
-- 📄 Skill_Charge.lua
-- สร้างจุด (Point) ข้างหลัง Target
-- ========================================

local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)

local Skill_Charge = {}

function Skill_Charge.Execute(npc, target)
    local config = SkillConfig.Skills.Charge
    if not npc or not target then
        warn("❌ ไม่มี npc หรือ target")
        return false
    end

    local root = npc.root or (npc.model and npc.model:FindFirstChild("HumanoidRootPart"))
    if not root then
        warn("❌ ไม่พบ HumanoidRootPart ของ npc")
        return false
    end

    local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
    if not targetRoot then
        warn("❌ ไม่พบ HumanoidRootPart ของ target")
        return false
    end

    print("⚡", npc.model.Name, "กำลังคำนวณจุด Charge ข้างหลัง", target.Name)

    -- 🧭 คำนวณตำแหน่งข้างหลัง Target
    local direction = -targetRoot.CFrame.LookVector
    local distanceBehind = config.DistanceBehind or 25
    local pointPosition = targetRoot.Position + (direction * distanceBehind)

    -- 🟦 แสดงผลด้วย Part (ไว้ดูตำแหน่ง)
    local pointPart = Instance.new("Part")
    pointPart.Name = "ChargePoint"
    pointPart.Size = Vector3.new(3, 3, 3)
    pointPart.Anchored = true
    pointPart.CanCollide = false
    pointPart.Color = Color3.fromRGB(0, 170, 255)
    pointPart.Material = Enum.Material.Neon
    pointPart.Position = pointPosition
    pointPart.Parent = workspace

    print("📍 สร้างจุด Charge ที่:", pointPosition)

    -- ลบ Part หลังจากเวลาที่กำหนด (กันรก)
    game:GetService("Debris"):AddItem(pointPart, 3)

    return true
end

return Skill_Charge
