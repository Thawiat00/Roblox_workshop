-- ========================================
-- 🪵 Wood Drag & Throw System (Fixed)
-- คลิกซ้ายลาก + คลิกขวาขว้าง (บังคับยกเลิก Drag)
-- ========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local woodFolder = workspace:WaitForChild("wood")


local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- 🔗 RemoteEvent สำหรับแจ้ง Server
local RE_OnWoodThrown = ReplicatedStorage:WaitForChild("Common"):WaitForChild("RE_OnWoodThrown")


-- ⚙️ การตั้งค่า
local CAMERA_DISTANCE = 10 -- ระยะห่างจากกล้อง (studs)
local THROW_FORCE = 100 -- แรงขว้าง

-- ตารางเก็บข้อมูลกิ่งไม้ที่กำลังถูกลาก
local draggingWood = {}
local currentHolding = nil -- กิ่งไม้ที่กำลังถืออยู่
local currentDragDetector = nil -- DragDetector ที่กำลังใช้งานอยู่

-- ฟังก์ชันบังคับยกเลิก Drag
local function forceCancelDrag(woodPart)
	if not woodPart then return end
	
	-- ลบออกจากตาราง drag
	draggingWood[woodPart] = nil
	
	-- ปิด DragDetector ชั่วคราว
	local dragDetector = woodPart:FindFirstChildOfClass("DragDetector")
	if dragDetector then
		dragDetector.Enabled = false
		task.wait(0.05) -- รอให้ระบบปล่อย
		dragDetector.Enabled = true
	end
end

-- ฟังก์ชันขว้างกิ่งไม้
local function throwWood(woodPart)
	if not woodPart or not woodPart.Parent then return end
	
	--print(player.Name .. " ขว้างกิ่งไม้!")
	print("[Client] 🪵 " .. player.Name .. " ขว้างกิ่งไม้: " .. woodPart.Name)
	

	-- บังคับยกเลิก Drag ก่อน
	forceCancelDrag(woodPart)
	
	-- ปลดล็อค physics
	woodPart.Anchored = false
	woodPart.CanCollide = true
	
	-- คำนวณทิศทางการขว้าง
	--local camera = workspace.CurrentCamera
	--local direction = camera.CFrame.LookVector
	
	-- คำนวณทิศทางการขว้าง
	local camera = workspace.CurrentCamera
	local direction = camera.CFrame.LookVector
	local velocity = direction * THROW_FORCE


	-- ใช้ AssemblyLinearVelocity เพื่อขว้าง
	--woodPart.AssemblyLinearVelocity = direction * THROW_FORCE
	--woodPart.AssemblyAngularVelocity = Vector3.new(
	--	math.random(-5, 5),
	--	math.random(-5, 5),
	--	math.random(-5, 5)
	--)

	-- ใช้ AssemblyLinearVelocity เพื่อขว้าง
	woodPart.AssemblyLinearVelocity = velocity
	woodPart.AssemblyAngularVelocity = Vector3.new(
		math.random(-5, 5),
		math.random(-5, 5),
		math.random(-5, 5)
	)

	
	-- ตั้งค่า physics
	woodPart.CustomPhysicalProperties = PhysicalProperties.new(
		0.7, -- Density
		0.3, -- Friction
		0.2, -- Elasticity (ขว้างแล้วกระเด้งนิดหน่อย)
		1, -- FrictionWeight
		1 -- ElasticityWeight
	)

	-- 🔥 ส่ง RemoteEvent ไป Server พร้อม velocity
	print("[Client] 📤 ส่ง RE_OnWoodThrown ไป Server:", woodPart.Name, "Velocity:", velocity)
	RE_OnWoodThrown:FireServer(woodPart.Name, velocity)

	
	-- ล้างค่า
	currentHolding = nil
	currentDragDetector = nil
end

-- ฟังก์ชันสร้าง DragDetector สำหรับกิ่งไม้แต่ละชิ้น
local function setupWoodDragDetector(woodPart)
	-- ตรวจสอบว่ามี DragDetector อยู่แล้วหรือไม่
	local dragDetector = woodPart:FindFirstChildOfClass("DragDetector")
	if not dragDetector then
		dragDetector = Instance.new("DragDetector")
		dragDetector.Parent = woodPart
	end
	
	-- ตั้งค่า DragDetector
	dragDetector.Enabled = true
	dragDetector.DragStyle = Enum.DragDetectorDragStyle.Scriptable
	dragDetector.ResponseStyle = Enum.DragDetectorResponseStyle.Custom
	dragDetector.MaxActivationDistance = 20
	
	-- 🎯 ฟังก์ชันคำนวณตำแหน่งของกิ่งไม้ตามกล้อง
	dragDetector:SetDragStyleFunction(function(cursorRay)
		local targetPos = cursorRay.Origin + (cursorRay.Direction.Unit * CAMERA_DISTANCE)
		return CFrame.new(targetPos) * (woodPart.CFrame - woodPart.Position)
	end)
	


	-- 🎈 ตั้งค่าเริ่มต้น
	woodPart.Anchored = false
	
	-- 📡 Events
	dragDetector.DragStart:Connect(function(playerWhoClicked, cursorRay, viewFrame, hitFrame, clickedPart)
		print(playerWhoClicked.Name .. " เริ่มลาก " .. clickedPart.Name)
		
		-- 🚀 เตรียมกิ่งไม้สำหรับการลาก
		woodPart.CanCollide = false
		woodPart.Anchored = true
		
		-- บันทึกข้อมูลกิ่งไม้ที่กำลังถูกลาก
		draggingWood[woodPart] = {
			player = playerWhoClicked,
			lastCursorRay = cursorRay
		}
		
		-- เก็บ reference ของกิ่งไม้ที่กำลังถือ
		currentHolding = woodPart
		currentDragDetector = dragDetector
		
		-- วาร์ปไปที่ตำแหน่งกล้องทันที
		local targetPos = cursorRay.Origin + (cursorRay.Direction.Unit * CAMERA_DISTANCE)
		woodPart.CFrame = CFrame.new(targetPos) * (woodPart.CFrame - woodPart.Position)
	end)

	
	
	dragDetector.DragContinue:Connect(function(playerWhoClicked, cursorRay, viewFrame)
		-- อัพเดทตำแหน่งล่าสุด
		if draggingWood[woodPart] then
			draggingWood[woodPart].lastCursorRay = cursorRay
		end
	end)
	
	dragDetector.DragEnd:Connect(function(playerWhoClicked)
		print(playerWhoClicked.Name .. " ปล่อยกิ่งไม้")
		
		-- ตรวจสอบว่าไม่ใช่การขว้าง (ถ้าขว้างจะถูกล้างไปแล้ว)
		if currentHolding == woodPart then
			-- ลบออกจากตาราง
			draggingWood[woodPart] = nil
			currentHolding = nil
			currentDragDetector = nil
			
			-- 🪶 ปล่อยให้ตกแบบธรรมดา
			woodPart.Anchored = false
			woodPart.CanCollide = true
			
			-- ตั้งค่าให้ไม่กระเด้ง
			woodPart.CustomPhysicalProperties = PhysicalProperties.new(
				0.7, -- Density
				0.3, -- Friction
				0, -- Elasticity (ไม่กระเด้ง)
				1, -- FrictionWeight
				1 -- ElasticityWeight
			)
			
			-- รีเซ็ต Velocity
			woodPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			woodPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end)
end

-- 🔄 อัพเดทตำแหน่งกิ่งไม้ทุกเฟรม
RunService.Heartbeat:Connect(function()
	for woodPart, data in pairs(draggingWood) do
		if woodPart.Parent and data.lastCursorRay then
			local cursorRay = data.lastCursorRay
			local targetPos = cursorRay.Origin + (cursorRay.Direction.Unit * CAMERA_DISTANCE)
			
			-- อัพเดทตำแหน่งโดยตรง
			woodPart.CFrame = CFrame.new(targetPos) * (woodPart.CFrame - woodPart.Position)
		end
	end
end)

-- 🎯 คลิกขวาเพื่อขว้าง (บังคับยกเลิก Drag ก่อน)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- ไม่สนใจว่า gameProcessed จะเป็น true หรือไม่
	-- เพราะเราต้องการให้ทำงานแม้ตอน Drag
	
	-- ตรวจสอบว่าคลิกขวา (Mouse Button 2)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if currentHolding and currentHolding.Parent then
			print("Debug: คลิกขวา! กำลังบังคับยกเลิก Drag และขว้าง", currentHolding.Name)
			throwWood(currentHolding)
		else
			print("Debug: คลิกขวา แต่ไม่ได้ถืออะไร")
		end
	end
end)

-- 🔄 ตั้งค่า DragDetector สำหรับกิ่งไม้ทั้งหมดใน folder
for _, wood in ipairs(woodFolder:GetChildren()) do
	if wood:IsA("BasePart") then
		setupWoodDragDetector(wood)
	end
end

-- 👀 เฝ้าดูกิ่งไม้ใหม่ที่เพิ่มเข้ามา
woodFolder.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") then
		task.wait(0.1)
		setupWoodDragDetector(child)
	end
end)

print("✅ Wood Drag & Throw System (Fixed) พร้อมใช้งาน!")
print("📌 คลิกซ้าย = ลากกิ่งไม้")
print("📌 คลิกขวา (ขณะลาก) = บังคับยกเลิก Drag และขว้างกิ่งไม้ทันที!")