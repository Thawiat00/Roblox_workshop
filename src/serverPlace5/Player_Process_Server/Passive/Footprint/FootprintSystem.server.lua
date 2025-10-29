-- FootprintServer.lua
-- วางไฟล์นี้ใน ServerScriptService
-- จัดการสร้างรอยเท้าฝั่ง Server

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local CollectionService = game:GetService("CollectionService") -- ⭐ เพิ่ม

-- ===== การตั้งค่า =====
local Config = {
	CHECK_RADIUS = 3.0,           -- ระยะตรวจสอบรอยเท้าซ้ำ
	LIFETIME = 30, -- ⭐ เพิ่มอายุเป็น 30 วินาที (ให้ AI มีเวลาตามได้)

	FOOTPRINT_SIZE = Vector3.new(1, 0.1, 1.5),
	FOOTPRINT_COLOR = BrickColor.new("Dark stone grey"),
	TRANSPARENCY = 0,
	MATERIAL = Enum.Material.SmoothPlastic,
	MAIN_FOLDER_NAME = "PlayerFootprints",
	PLAYER_FOLDER_PREFIX = "folderfoot",
	FOOTPRINT_PREFIX = "footplayer",
	DEBUG_MODE = true,            -- เปิด debug เพื่อดู log
	MAX_REQUESTS_PER_SECOND = 10  -- จำกัดการสร้างรอยเท้า
}

-- ===== ตัวแปรเก็บข้อมูล =====
local PlayerFolders = {}
local PlayerCounters = {}
local RequestCooldowns = {} -- ป้องกัน spam

-- ===== สร้าง RemoteEvent =====
--local remoteEvent = ReplicatedStorage:FindFirstChild("PlaceFootprint")
local remoteEvent = ReplicatedStorage:WaitForChild("Common"):WaitForChild("PlaceFootprint")

---------------

--local remoteEvent = ReplicatedStorage:WaitForChild("Common"):WaitForChild("PlaceFootprint")


--------------

if not remoteEvent then
	remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = "PlaceFootprint"
	remoteEvent.Parent = ReplicatedStorage
end

-- ===== ฟังก์ชันหลัก =====

-- สร้าง Main Folder
local function CreateMainFolder()
	local mainFolder = workspace:FindFirstChild(Config.MAIN_FOLDER_NAME)
	
	if not mainFolder then
		mainFolder = Instance.new("Folder")
		mainFolder.Name = Config.MAIN_FOLDER_NAME
		mainFolder.Parent = workspace
		
		if Config.DEBUG_MODE then
			print("[Server] สร้าง Main Folder:", mainFolder.Name)
		end
	end
	
	return mainFolder
end

-- สร้าง Folder สำหรับ player
local function CreatePlayerFolder(player)
	local mainFolder = CreateMainFolder()
	
	local folderName = Config.PLAYER_FOLDER_PREFIX .. player.Name
	
	local playerFolder = Instance.new("Folder")
	playerFolder.Name = folderName
	playerFolder.Parent = mainFolder
	
	PlayerFolders[player.UserId] = playerFolder
	PlayerCounters[player.UserId] = 0
	RequestCooldowns[player.UserId] = {
		requests = 0,
		lastReset = tick()
	}
	
	if Config.DEBUG_MODE then
		print("[Server] สร้าง Player Folder:", folderName)
	end
	
	return playerFolder
end

-- ตรวจสอบ rate limit
local function CheckRateLimit(player)
	local cooldown = RequestCooldowns[player.UserId]
	if not cooldown then
		return false
	end
	
	local now = tick()
	
	-- รีเซ็ตตัวนับทุกวินาที
	if now - cooldown.lastReset >= 1 then
		cooldown.requests = 0
		cooldown.lastReset = now
	end
	
	cooldown.requests = cooldown.requests + 1
	
	if cooldown.requests > Config.MAX_REQUESTS_PER_SECOND then
		warn("[Server] Rate limit exceeded for:", player.Name)
		return false
	end
	
	return true
end

-- ตรวจสอบว่ามีรอยเท้าอยู่ใกล้ๆ หรือไม่
local function HasNearbyFootprint(player, position)
	local playerFolder = PlayerFolders[player.UserId]
	
	if not playerFolder then
		return false
	end
	
	for _, footprint in ipairs(playerFolder:GetChildren()) do
		if footprint:IsA("BasePart") then
			local distance = (footprint.Position - position).Magnitude
			
			if distance < Config.CHECK_RADIUS then
				return true
			end
		end
	end
	
	return false
end

-- เพิ่มตัวนับและสร้างชื่อรอยเท้าใหม่
local function GetNextFootprintName(player)
	if not PlayerCounters[player.UserId] then
		PlayerCounters[player.UserId] = 0
	end
	
	PlayerCounters[player.UserId] = PlayerCounters[player.UserId] + 1
	
	return Config.FOOTPRINT_PREFIX .. PlayerCounters[player.UserId]
end

-- สร้างรอยเท้า
local function CreateFootprint(player, position, rotation)
	-- ตรวจสอบว่า player ยังอยู่ในเกมหรือไม่
	if not Players:FindFirstChild(player.Name) then
		return
	end
	
	local playerFolder = PlayerFolders[player.UserId]
	
	if not playerFolder then
		warn("[Server] ไม่พบ folder ของ player:", player.Name)
		return
	end
	
	-- ตรวจสอบว่ามีรอยเท้าอยู่ใกล้ๆ หรือไม่
	if HasNearbyFootprint(player, position) then
		if Config.DEBUG_MODE then
			print("[Server] มีรอยเท้าอยู่ใกล้แล้ว - ไม่สร้าง")
		end
		return
	end
	
	-- สร้าง part รอยเท้า
	local footprint = Instance.new("Part")
	footprint.Name = GetNextFootprintName(player)
	footprint.Size = Config.FOOTPRINT_SIZE
	footprint.BrickColor = Config.FOOTPRINT_COLOR
	footprint.Material = Config.MATERIAL
	footprint.Transparency = Config.TRANSPARENCY
	footprint.Anchored = true
	footprint.CanCollide = false
	footprint.CFrame = CFrame.new(position) * rotation

	-- ⭐ เพิ่ม CollectionService Tag
	CollectionService:AddTag(footprint, "PlayerFootprint")	


	-- ⭐ เพิ่ม Timestamp
	local timestamp = Instance.new("NumberValue")
	timestamp.Name = "Timestamp"
	timestamp.Value = tick() -- เก็บเวลาปัจจุบัน
	timestamp.Parent = footprint



	-- ⭐ เพิ่ม OwnerName (สำหรับ debug)
	local ownerName = Instance.new("StringValue")
	ownerName.Name = "OwnerName"
	ownerName.Value = player.Name
	ownerName.Parent = footprint



	footprint.Parent = playerFolder

	
	-- เพิ่มเข้า Debris เพื่อให้หายไปตามเวลา
	Debris:AddItem(footprint, Config.LIFETIME)
	



	if Config.DEBUG_MODE then
		print("[Server] สร้างรอยเท้า:", footprint.Name, "| ที่ตำแหน่ง", position , "| Time:", timestamp.Value)
	end
	


	return footprint

end



-- ลบ folder ของ player
local function RemovePlayerFolder(player)
	local playerFolder = PlayerFolders[player.UserId]
	
	if playerFolder then
		playerFolder:Destroy()
		PlayerFolders[player.UserId] = nil
		PlayerCounters[player.UserId] = nil
		RequestCooldowns[player.UserId] = nil
		
		if Config.DEBUG_MODE then
			print("[Server] ลบ Player Folder:", player.Name)
		end
	end
end

-- ===== Event Handlers =====

-- จัดการ request จาก client
remoteEvent.OnServerEvent:Connect(function(player, position, rotation)
	-- ตรวจสอบ rate limit
	if not CheckRateLimit(player) then
		return
	end
	
	-- ตรวจสอบว่า position และ rotation ถูกต้อง
	if typeof(position) ~= "Vector3" or typeof(rotation) ~= "CFrame" then
		warn("[Server] Invalid data from client:", player.Name)
		return
	end
	


	-- ตรวจสอบว่า player มี character อยู่ในเกม
	local character = player.Character
	if not character then
		return
	end
	


	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	



	-- ตรวจสอบว่าตำแหน่งไม่ห่างจาก character มากเกินไป (anti-exploit)
	local distance = (position - humanoidRootPart.Position).Magnitude
	if distance > 20 then
		warn("[Server] Position too far from character:", player.Name)
		return
	end
	
	
	
	
	-- สร้างรอยเท้า
	CreateFootprint(player, position, rotation)
end)




-- Setup player เมื่อเข้าเกม
Players.PlayerAdded:Connect(function(player)
	CreatePlayerFolder(player)
	
	if Config.DEBUG_MODE then
		print("[Server] Player joined:", player.Name)
	end
end)





-- ลบข้อมูล player เมื่อออกจากเกม
Players.PlayerRemoving:Connect(function(player)
	RemovePlayerFolder(player)
	
	if Config.DEBUG_MODE then
		print("[Server] Player left:", player.Name)
	end
end)





-- Setup players ที่อยู่ในเกมแล้ว
for _, player in ipairs(Players:GetPlayers()) do
	CreatePlayerFolder(player)
end





-- สร้าง Main Folder
CreateMainFolder()

-- ===== คำสั่งแชทสำหรับ Admin =====
local ADMIN_USER_IDS = {
	-- ใส่ UserId ของ Admin ที่นี่
	-- 123456789,
}




local function isAdmin(player)
	for _, adminId in ipairs(ADMIN_USER_IDS) do
		if player.UserId == adminId then
			return true
		end
	end
	return false
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if not isAdmin(player) then
			return
		end
		
		local lowerMsg = message:lower()
		
		if lowerMsg == "!clearfootprints" then
			local folder = PlayerFolders[player.UserId]
			if folder then
				folder:ClearAllChildren()
				PlayerCounters[player.UserId] = 0
				print("🧹 ล้างรอยเท้าของ", player.Name)
			end
			
		elseif lowerMsg == "!clearall" then
			for _, plr in ipairs(Players:GetPlayers()) do
				local folder = PlayerFolders[plr.UserId]
				if folder then
					folder:ClearAllChildren()
					PlayerCounters[plr.UserId] = 0
				end
			end
			print("🧹 ล้างรอยเท้าทั้งหมด")
			
		elseif lowerMsg == "!stats" then
			local folder = PlayerFolders[player.UserId]
			local counter = PlayerCounters[player.UserId] or 0
			local current = folder and #folder:GetChildren() or 0
			
			print("=== สถิติรอยเท้าของ", player.Name, "===")
			print("รอยเท้าที่สร้างทั้งหมด:", counter)
			print("รอยเท้าที่เหลืออยู่:", current)
			print("=====================================")
			
		elseif lowerMsg == "!debug on" then
			Config.DEBUG_MODE = true
			print("🔧 เปิด Debug Mode")
			
		elseif lowerMsg == "!debug off" then
			Config.DEBUG_MODE = false
			print("🔧 ปิด Debug Mode")
		end
	end)
end)

print("==============================================")
print("✅ 🦶 Footprint System (Server) - Ready!")
print("⭐ CollectionService Tag: PlayerFootprint")
print("⭐ Timestamp Support: Enabled")
print("==============================================")
print("📡 RemoteEvent:", remoteEvent:GetFullName())
print("📁 Main Folder: workspace." .. Config.MAIN_FOLDER_NAME)
print("🔧 Debug Mode:", Config.DEBUG_MODE and "ON" or "OFF")
print("==============================================")