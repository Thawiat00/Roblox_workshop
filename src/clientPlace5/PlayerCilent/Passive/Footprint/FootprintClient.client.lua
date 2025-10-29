-- FootprintClient.lua
-- วางไฟล์นี้ใน StarterPlayer > StarterCharacterScripts
-- ตรวจสอบการเดินและส่งข้อมูลไป Server

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- รอ LocalPlayer
local player = Players.LocalPlayer

-- รอ Character
local character = player.Character or player.CharacterAdded:Wait()
print("[Client] Character loaded:", character.Name)

-- รอ HumanoidRootPart และ Humanoid
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
local humanoid = character:WaitForChild("Humanoid", 10)

if not humanoidRootPart or not humanoid then
	warn("[Client] ไม่พบ HumanoidRootPart หรือ Humanoid - ระบบรอยเท้าไม่ทำงาน")
	return
end

-- ===== การตั้งค่า =====
local Config = {
	SPAWN_DISTANCE = 2.5,  -- ระยะทางที่ต้องเดินก่อนสร้างรอยเท้า
	DEBUG_MODE = true      -- เปิด debug เพื่อดู log
}

-- ===== รอ RemoteEvent =====
local remoteEvent = ReplicatedStorage:WaitForChild("Common"):WaitForChild("PlaceFootprint")

--local remoteEvent = ReplicatedStorage:WaitForChild("PlaceFootprint", 10)

if not remoteEvent then
	warn("[Client] ❌ ไม่พบ RemoteEvent: PlaceFootprint")
	warn("[Client] ⚠️ ตรวจสอบว่า FootprintServer.lua ทำงานอยู่หรือไม่")
	return
end

print("[Client] ✅ เชื่อมต่อ RemoteEvent สำเร็จ:", remoteEvent:GetFullName())

-- ===== ตัวแปร =====
local lastPosition = humanoidRootPart.Position
local isRunning = true

-- ===== ฟังก์ชัน =====

-- สร้างรอยเท้า
local function SpawnFootprint()
	-- หาตำแหน่งพื้น
	local rayOrigin = humanoidRootPart.Position
	local rayDirection = Vector3.new(0, -10, 0)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}
	
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		-- ตำแหน่งที่จะวางรอยเท้า (บนพื้นนิดหนึ่ง)
		local footprintPosition = raycastResult.Position + Vector3.new(0, 0.05, 0)
		
		-- หาทิศทางการหมุน (ตาม CFrame ของตัวละคร)
		local lookVector = humanoidRootPart.CFrame.LookVector
		local rotation = CFrame.new(Vector3.new(), lookVector * Vector3.new(1, 0, 1))
		
		-- ส่งข้อมูลไป Server
		remoteEvent:FireServer(footprintPosition, rotation)
		
		if Config.DEBUG_MODE then
			print("[Client] ส่งคำขอสร้างรอยเท้าที่:", footprintPosition)
		end
	end
end

-- อัพเดทตำแหน่งและตรวจสอบว่าควรสร้างรอยเท้า
local function UpdateFootprint(deltaTime)
	if not isRunning then
		return
	end
	
	-- ตรวจสอบว่า character ยังอยู่
	if not character or not character.Parent then
		isRunning = false
		return
	end
	
	if not humanoidRootPart or not humanoidRootPart.Parent then
		return
	end
	
	local currentPosition = humanoidRootPart.Position
	local distance = (currentPosition - lastPosition).Magnitude
	
	-- ตรวจสอบว่าเดินไปไกลพอแล้วหรือยัง
	if distance >= Config.SPAWN_DISTANCE then
		-- ตรวจสอบว่ากำลังเดินอยู่หรือไม่
		if humanoid.MoveDirection.Magnitude > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
			-- สร้างรอยเท้า
			SpawnFootprint()
			
			-- อัพเดทตำแหน่งล่าสุด
			lastPosition = currentPosition
		end
	end
end

-- ===== เริ่มต้นระบบ =====
local connection = RunService.Heartbeat:Connect(UpdateFootprint)

-- ทำความสะอาดเมื่อ character ถูกลบ
character.AncestryChanged:Connect(function(_, parent)
	if not parent then
		isRunning = false
		if connection then
			connection:Disconnect()
		end
		
		if Config.DEBUG_MODE then
			print("[Client] หยุดระบบรอยเท้า")
		end
	end
end)

-- ทำความสะอาดเมื่อ humanoid ตาย
humanoid.Died:Connect(function()
	isRunning = false
	if connection then
		connection:Disconnect()
	end
	
	if Config.DEBUG_MODE then
		print("[Client] Character ตาย - หยุดระบบรอยเท้า")
	end
end)

if Config.DEBUG_MODE then
	print("[Client] 🦶 ระบบรอยเท้าเริ่มทำงานสำหรับ:", player.Name)
	print("[Client] Character:", character.Name)
	print("[Client] HumanoidRootPart:", humanoidRootPart:GetFullName())
end

print("✅ 🦶 Footprint System (Client) - Ready!")