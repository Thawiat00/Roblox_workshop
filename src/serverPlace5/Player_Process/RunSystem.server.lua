-- 📂 ServerScriptService/RunSystem.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


--local sprintEvent = ReplicatedStorage:FindFirstChild("Common"):FindFirstChild("SprintEvent")
local sprintEvent = ReplicatedStorage:WaitForChild("Common"):WaitForChild("SprintEvent")


--local sprintEvent = Instance.new("RemoteEvent")
--sprintEvent.Name = "SprintEvent"
--sprintEvent.Parent = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
--sprintEvent.Parent.Name = "RemoteEvents"

-- ✅ โหลด config
local PlayerConfig = require(game.ServerScriptService.ServerLocal.Config.PlayerConfig)


--local NORMAL_SPEED = 16
--local SPRINT_SPEED = 25

local NORMAL_SPEED = PlayerConfig.Movement.WalkSpeed
local SPRINT_SPEED = PlayerConfig.Movement.RunSpeed



-- เมื่อ Client แจ้งว่าเริ่ม/หยุดวิ่ง
sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	


	if isSprinting then
		humanoid.WalkSpeed = SPRINT_SPEED
		print("[SERVER] 🏃 "..player.Name.." Running Speed:", humanoid.WalkSpeed)
	else
		humanoid.WalkSpeed = NORMAL_SPEED
		print("[SERVER] 🚶 "..player.Name.." Walking Speed:", humanoid.WalkSpeed)
	end

	
	-- ✅ ส่งค่ากลับให้ Client เพื่อ sync ความเร็ว (Client จะไม่รู้ค่าโดยตรง)
	sprintEvent:FireClient(player, humanoid.WalkSpeed)

end)
