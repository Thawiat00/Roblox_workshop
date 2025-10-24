local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- สร้าง RemoteEvent
local equipBookEvent = Instance.new("RemoteEvent")
equipBookEvent.Name = "EquipBook"
equipBookEvent.Parent = ReplicatedStorage

local bookPart = workspace:WaitForChild("Book")

equipBookEvent.OnServerEvent:Connect(function(player)
    
    
    local character = player.Character
    if not character then return end
    
    -- ตรวจสอบระยะห่าง (ป้องกัน exploit)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local distance = (humanoidRootPart.Position - bookPart.Position).Magnitude
    if distance > 15 then return end -- ต้องอยู่ใกล้พอ
    
    -- สร้างสมุด (Tool)
    local book = Instance.new("Tool")
    book.Name = "Book"
    book.RequiresHandle = true
    book.CanBeDropped = false -- ไม่สามารถทิ้งได้
    
    -- สร้าง Handle (ส่วนที่จับ)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1.5, 0.2)
    handle.BrickColor = BrickColor.new("Brown")
    handle.Parent = book
    
    -- ใส่สมุดให้ผู้เล่น
    book.Parent = player.Backpack
    
    -- ลบสมุดในโลก
    if bookPart then
        bookPart:Destroy()
    end
end)