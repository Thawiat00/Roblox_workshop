-- =========================================
-- 📄 ServerScriptService/CreateRingEffect.lua
-- =========================================

local function createRingEffect(originPos)
	-- 🔹 สร้าง Part
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(0, 200, 255)
	ring.Size = Vector3.new(1, 0.5, 1) -- เริ่มต้นเล็ก
	ring.CFrame = CFrame.new(originPos) * CFrame.Angles(math.rad(90), 0, 0)
	ring.Parent = workspace

	-- 🔹 เอฟเฟกต์ขยาย + จาง
	local maxSize = 30
	local expandTime = 1.2
	local fadeTime = 0.6

	-- TweenService สำหรับอนิเมชัน
	local TweenService = game:GetService("TweenService")

	-- 🔹 Tween ขยายวง
	local growTween = TweenService:Create(
		ring,
		TweenInfo.new(expandTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Size = Vector3.new(maxSize, 0.5, maxSize)}
	)

	-- 🔹 Tween จางหาย
	local fadeTween = TweenService:Create(
		ring,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{Transparency = 1}
	)

	-- 🔹 เล่นทีละช่วง
	growTween:Play()
	growTween.Completed:Connect(function()
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			ring:Destroy()
		end)
	end)
end

-- 🧪 ตัวอย่างการใช้งาน
local player = game.Players.PlayerAdded:Wait()
player.CharacterAdded:Connect(function(char)
	wait(3) -- รอโหลด
	createRingEffect(char.HumanoidRootPart.Position)
end)
