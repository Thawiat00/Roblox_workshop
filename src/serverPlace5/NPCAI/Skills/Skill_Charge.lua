-- ========================================
-- 📄 Skill_Charge.lua
-- สร้างจุดข้างหลัง target แล้วให้ npc พุ่งไปยังจุดนั้น
-- ========================================

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)


local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)


local PhysicsService = game:GetService("PhysicsService")


-- ===============================
-- 3️⃣ Skill_Charge Function
-- ===============================

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
   -- local direction = -targetRoot.CFrame.LookVector
   -- local distanceBehind = config.DistanceBehind or 25
   -- local pointPosition = targetRoot.Position + (direction * distanceBehind)

   -- 🧭 คำนวณทิศทางจาก npc → target แล้วพุ่งทะลุหลังไปอีก
local direction = (targetRoot.Position - root.Position).Unit
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

-- 🚫 ปิดการชนกับผู้เล่นระหว่างพุ่ง
--for _, descendant in ipairs(npc.model:GetDescendants()) do
--	if descendant:IsA("BasePart") then
--		descendant.CanCollide = false
--	end
--end


-- 🧠 ตั้ง CollisionGroup ให้ NPC ทั้งหมดเป็น EnemyCharge
for _, part in ipairs(npc.model:GetDescendants()) do
	if part:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(part, "EnemyCharge")
	end
end


    tween:Play()


    -- 🌪️ ตรวจจับการชนระหว่างพุ่ง
-- 🌪️ ตรวจจับการชนระหว่างพุ่ง
local connection
connection = root.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if humanoid and hrp and character ~= npc.model then
		print("💥", npc.model.Name, "ชนกับ", character.Name)


        
	--	local knockback = Instance.new("BodyVelocity")
	--	knockback.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	--	local knockbackStrength = math.clamp(distance * 2, 30, 80)
	--	knockback.Velocity = direction * knockbackStrength
	--	knockback.Parent = hrp
	--	game.Debris:AddItem(knockback, 0.2)

    local knockback = Instance.new("BodyVelocity")
    knockback.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    local knockbackStrength = math.clamp(distance * 2, 50, 100) -- เพิ่มแรงหน่อย
    knockback.Velocity = direction * knockbackStrength + Vector3.new(0,30,60) -- เพิ่มแรงขึ้นบน
    knockback.P = 1e4 -- เพิ่มคุณภาพฟิสิกส์
    knockback.Parent = hrp
    game.Debris:AddItem(knockback, 0.5) -- ให้แรงนานขึ้น


        --กล้องสั่น

            -- 🔹 แก้ไขตรงนี้: ส่ง Character แทน Humanoid
           -- local targetCharacter = targetHumanoid.Parent
           -- EventBus:Emit("ShakeCamera", targetCharacter, 0.7, 0.5)


            EventBus:Emit("ShakeCamera", character, 0.45, 1.0)


            --EventBus:Emit("ShakeCamera", player.Character, 2, 1.0)


		--humanoid:TakeDamage(config.Damage or 15)
	end
end)


    tween.Completed:Wait(6)



print("⏸ NPC หยุดนิ่ง 5 วินาที")

--task.delay(5)
--task.wait(5)             -- หยุดนิ่ง 5 วิ ก่อนทำงานต่อ

-- ✅ รีเซ็ต CollisionGroup ก่อน
for _, part in ipairs(npc.model:GetDescendants()) do
	if part:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(part, "Default")
	end
end

if connection then connection:Disconnect() end

-- ✅ รอให้ NPC พ้นจากผู้เล่นก่อนค่อยเปิดการชนกลับ
task.delay(0.5, function()
	for _, descendant in ipairs(npc.model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = true
		end
	end
end)





-- 🚫 ยกเลิกการตรวจจับเมื่อพุ่งเสร็จ
--if connection then
--	connection:Disconnect()
--end

    npc.IsCharging = false



    
    print("✅", npc.model.Name, "ถึงจุด Charge แล้ว")


    return true


    
end

return Skill_Charge
