-- =========================================
-- 🪵 Wood Drag System
-- ระบบลากกิ่งไม้ให้ลอยตามกล้อง (ไม่ลากพื้นเลย!)
-- =========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local woodFolder = workspace:WaitForChild("wood")

-- ⚙️ การตั้งค่า
local CAMERA_DISTANCE = 10  -- ระยะห่างจากกล้อง (studs)

-- ตารางเก็บข้อมูลกิ่งไม้ที่กำลังถูกลาก
local draggingWood = {}

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
		-- คำนวณตำแหน่งตรงหน้ากล้อง
		local targetPos = cursorRay.Origin + (cursorRay.Direction.Unit * CAMERA_DISTANCE)
		
		-- คืนค่า CFrame ของกิ่งไม้ (รักษามุมเดิม)
		return CFrame.new(targetPos) * (woodPart.CFrame - woodPart.Position)
	end)
	
	-- 🎈 ตั้งค่าเริ่มต้น
	woodPart.Anchored = false
	
	-- 📡 Events
	dragDetector.DragStart:Connect(function(player, cursorRay, viewFrame, hitFrame, clickedPart)
		print(player.Name .. " เริ่มลาก " .. clickedPart.Name)
		
		-- 🚀 เตรียมกิ่งไม้สำหรับการลาก
		woodPart.CanCollide = false
		woodPart.Anchored = true  -- Anchor เพื่อไม่ให้มีแรงโน้มถ่วง
		
		-- บันทึกข้อมูลกิ่งไม้ที่กำลังถูกลาก
		draggingWood[woodPart] = {
			player = player,
			lastCursorRay = cursorRay
		}
		
		-- วาร์ปไปที่ตำแหน่งกล้องทันที!
		local targetPos = cursorRay.Origin + (cursorRay.Direction.Unit * CAMERA_DISTANCE)
		woodPart.CFrame = CFrame.new(targetPos) * (woodPart.CFrame - woodPart.Position)
	end)
	
	dragDetector.DragContinue:Connect(function(player, cursorRay, viewFrame)
		-- อัพเดทตำแหน่งล่าสุด
		if draggingWood[woodPart] then
			draggingWood[woodPart].lastCursorRay = cursorRay
		end
	end)
	
	dragDetector.DragEnd:Connect(function(player)
		print(player.Name .. " ปล่อยกิ่งไม้")
		
		-- ลบออกจากตาราง
		draggingWood[woodPart] = nil
		
		-- 🪶 ปล่อยให้ตกแบบธรรมดา (ไม่กระเด้ง)
		woodPart.Anchored = false
		woodPart.CanCollide = true
		
		-- ตั้งค่าให้ไม่กระเด้ง
		woodPart.CustomPhysicalProperties = PhysicalProperties.new(
			0.7,  -- Density
			0.3,  -- Friction (ความเสียดทาน)
			0,    -- Elasticity (ความยืดหยุ่น = 0 = ไม่กระเด้ง!)
			1,    -- FrictionWeight
			1     -- ElasticityWeight
		)
		
		-- รีเซ็ต Velocity ให้เป็น 0 (ไม่มีความเร็วตกค้าง)
		woodPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		woodPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end)
end

-- 🔄 อัพเดทตำแหน่งกิ่งไม้ทุกเฟรม
RunService.Heartbeat:Connect(function()
	for woodPart, data in pairs(draggingWood) do
		if woodPart.Parent and data.lastCursorRay then
			local cursorRay = data.lastCursorRay
			local targetPos = cursorRay.Origin + (cursorRay.Direction.Unit * CAMERA_DISTANCE)
			
			-- อัพเดทตำแหน่งโดยตรง (ไม่มีแรงโน้มถ่วง!)
			woodPart.CFrame = CFrame.new(targetPos) * (woodPart.CFrame - woodPart.Position)
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

print("✅ Wood Drag System พร้อมใช้งาน!")