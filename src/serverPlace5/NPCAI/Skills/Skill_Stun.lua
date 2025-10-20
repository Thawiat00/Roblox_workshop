-- ========================================
-- 📄 ServerScriptService/NPCAI/Skills/Skill_Stun.lua
-- รวมระบบตะโกน + ผลัก + แช่แข็ง
-- ========================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local SkillConfig = require(game.ServerScriptService.ServerLocal.Config.SkillConfig)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

local TweenService = game:GetService("TweenService")


local Skill_Stun = {}

------------------------------------------------------------
-- 🔹 เอฟเฟกต์วงคลื่นตะโกน
------------------------------------------------------------
local function CreateExpandingRing(originPos, initialRadius, finalRadius, pieces, duration)
	pieces = pieces or 30
	initialRadius = initialRadius or 2
	finalRadius = finalRadius or 15
	duration = duration or 1

	local parts = {}

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

	-- Tween ขยายรัศมี
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
		tween:Play()
		tween.Completed:Connect(function()
			info.part:Destroy()
		end)
	end
end





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
-- 🔹 แช่แข็งผู้เล่น (หยุดเคลื่อนไหว)
------------------------------------------------------------
local function FreezeCharacter(character, duration)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local originalSpeed = humanoid.WalkSpeed
	local originalJump = humanoid.JumpPower

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	EventBus:Emit("PlayerStunned", {
		target = character.Name,
		duration = duration
	})

	print("❄️", character.Name, "frozen for", duration, "sec")

	task.delay(duration, function()
		if humanoid then
			humanoid.WalkSpeed = originalSpeed
			humanoid.JumpPower = originalJump
			print("🔥", character.Name, "movement restored")
		end
	end)
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
	--CreateRingEffect(npcRoot.Position)

    --CreateRingEffect(npcRoot.Position)
   -- CreateRingAroundNPC(npcRoot.Position)
    --CreateExpandingRing(npcRoot.Position)
    CreateExpandingRing(npcRoot.Position, 1, 30, 30, 5)

   -- CreateRingAroundNPC(npcRoot.Position,20, 30)

	-- 2️⃣ ตรวจว่าผู้เล่นอยู่ในระยะ
	local targetCharacter = target.Parent
	if targetCharacter then
		local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
		if targetHumanoid then
			-- ผลักผู้เล่นออกไป
			PushCharacter(targetCharacter, npcRoot.CFrame)
			-- แช่แข็งผู้เล่นตามเวลาที่ตั้งใน config
			FreezeCharacter(targetCharacter, config.StunDuration)
		end
	end

	return true
end

return Skill_Stun
