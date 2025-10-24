-- 📂 StarterPlayerScripts/RunSystem.client.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
--local sprintEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SprintEvent")
local sprintEvent = ReplicatedStorage:FindFirstChild("Common"):FindFirstChild("SprintEvent")



local normalSpeed = 16
local sprintSpeed = 32
local isSprinting = false

local function getHumanoid()
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("Humanoid")
end

local humanoid = getHumanoid()

-- กด Shift เพื่อวิ่ง
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		humanoid.WalkSpeed = sprintSpeed
		sprintEvent:FireServer(true)
	end
end)

-- ปล่อย Shift เพื่อหยุดวิ่ง
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		humanoid.WalkSpeed = normalSpeed
		sprintEvent:FireServer(false)
	end
end)

player.CharacterAdded:Connect(function(character)
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = normalSpeed
end)
