-- 📂 ServerScriptService/RunSystem.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local sprintEvent = ReplicatedStorage:FindFirstChild("Common"):FindFirstChild("SprintEvent")
--local sprintEvent = Instance.new("RemoteEvent")
--sprintEvent.Name = "SprintEvent"
--sprintEvent.Parent = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
--sprintEvent.Parent.Name = "RemoteEvents"

local NORMAL_SPEED = 16
local SPRINT_SPEED = 32

sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		if isSprinting then
			humanoid.WalkSpeed = SPRINT_SPEED
            print("Player Run now speed :",humanoid.WalkSpeed)
		else
			humanoid.WalkSpeed = NORMAL_SPEED
             print("Player walk now speed :",humanoid.WalkSpeed)
		end
	end
end)
