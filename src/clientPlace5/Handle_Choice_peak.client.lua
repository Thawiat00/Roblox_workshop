local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui")
local scrollingFrame = screenGui:WaitForChild("Peak_Choice"):WaitForChild("Side_Peak_inventory"):WaitForChild("holder"):WaitForChild("ScrollingFrame")


-- เชื่อมต่อกับ RemoteEvent
local Handle_choice_peak = ReplicatedStorage:WaitForChild("Common"):WaitForChild("Handle_choice_peak")


local PeakConfirm = playerGui:WaitForChild("ScreenGui")
	:WaitForChild("Peak_Choice")
	:WaitForChild("Side_Peak_Confirm")

local PeakSlots = {
	PeakConfirm:WaitForChild("hold_1"),
	PeakConfirm:WaitForChild("hold_2"),
	PeakConfirm:WaitForChild("hold_3"),
}



-- ✅ ฟังก์ชันหาช่องว่าง
-- ✅ ฟังก์ชันหาช่องว่าง (เพิ่ม log)
-- ✅ ฟังก์ชันหาช่องว่าง (รองรับทั้ง 2 แบบ)
local function FindEmptySlot()
	print("🧩 [FindEmptySlot] เริ่มตรวจสอบช่องทั้งหมด...")

	for i, slot in ipairs(PeakSlots) do
		print("🔹 ตรวจ:", slot.Name, "ประเภท:", slot.ClassName)

		local label

		-- ถ้า slot เองเป็น TextButton ใช้มันเลย
		if slot:IsA("TextButton") then
			label = slot
		else
			-- หา TextLabel/TextButton ภายใน (ทุกชั้น)
			label = slot:FindFirstChildWhichIsA("TextButton", true) or slot:FindFirstChildWhichIsA("TextLabel", true)
		end

		if not label then
			warn("⚠️ ไม่มี TextButton/TextLabel ใน", slot.Name)
		else
			print("🔸 เจอ Label:", label.Name, "ค่า Text =", label.Text)
		end

		if label and label.Text == "" then
			print("✅ เจอช่องว่าง:", slot.Name)
			return label
		end
	end

	warn("❌ ไม่มีช่องว่างเหลือแล้ว (ทุกช่องเต็มหรือไม่มี label ที่ Text ว่าง)")
	return nil
end



-- ✅ ฟังก์ชันเพิ่มชื่อ Peak
local function AddPeakToSlot(peakName)
	print("🧩 [AddPeakToSlot] พยายามเพิ่ม:", peakName)

	local label = FindEmptySlot()
	if not label then
		warn("❌ เพิ่มไม่ได้ เพราะไม่มีช่องว่างเหลือแล้ว")
		return false
	end

	print("✍️ กำลังใส่ชื่อใน:", label.Name, "ของ", label.Parent.Name)
	label.Text = peakName
	print("✅ เพิ่ม Peak:", peakName, "ลงใน", label.Parent.Name)
	return true
end



-- วนหาปุ่มทั้งหมดใน ScrollingFrame
-- วนหาปุ่มทั้งหมดใน ScrollingFrame
for _, button in pairs(scrollingFrame:GetChildren()) do
    if button:IsA("TextButton") or button:IsA("ImageButton") then
        
        -- เมื่อคลิก - ส่งข้อมูลไปยัง Server
        button.MouseButton1Click:Connect(function()
            print("คลิกปุ่ม:", button.Name)
            
           -- print("object",button)
            
	         -- ✅ ใส่ชื่อปุ่มลงในช่องว่าง (Client ทำเอง)
	        local success = AddPeakToSlot(button.Name)
	         if not success then return end



            -- ส่งข้อมูลไปยัง Server ผ่าน RemoteEvent
            Handle_choice_peak:FireServer(button.Name)


              -- ซ่อน UI แทนการทำลาย
            -- ✅ ซ่อนปุ่มที่ถูกคลิก
            button.Visible = false

           -- screenGui:WaitForChild("Peak_Choice"):WaitForChild("Side_Peak_inventory"):WaitForChild("holder"):WaitForChild("ScrollingFrame"):WaitForChild("button.Name")
        end)
        
        -- เมื่อเมาส์เข้า
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end)
        
        -- เมื่อเมาส์ออก
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end
end