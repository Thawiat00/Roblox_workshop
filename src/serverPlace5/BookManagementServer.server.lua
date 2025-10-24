-- ========================================
-- 🖥️ SERVER SCRIPT: BookManagementServer
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Players = game:GetService("Players")



-- โหลด Config
--local Config = ReplicatedStorage:WaitForChild("Config")

--local ItemConfig = require(Config:WaitForChild("ItemConfig"))
--local ItemConfig = require(game.ServerScriptService.ServerLocal.Core.ite)

local ItemConfig = require(game.ServerScriptService.ServerLocal.Config.ItemConfig)



-- สร้าง/รับ Remote Events

local Common = ReplicatedStorage:WaitForChild("Common")
local equipBookEvent = Common:WaitForChild("EquipBook")

-- สร้าง PlaceBook RemoteEvent
local placeBookEvent = Instance.new("RemoteEvent")
placeBookEvent.Name = "PlaceBook"
placeBookEvent.Parent = Common

print("✅ [Server] Remote Events created")

-- ฟังก์ชันหยิบสมุด
equipBookEvent.OnServerEvent:Connect(function(player, bookObject)
    print("📥 [Server] Received pickup request from", player.Name)
    
    local character = player.Character
    if not character then 
        warn("⚠️ [Server] No character found")
        return 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        warn("⚠️ [Server] No HumanoidRootPart")
        return 
    end
    
    -- ตรวจสอบว่า bookObject ยังมีอยู่
    if not bookObject or not bookObject.Parent then
        warn("⚠️ [Server] Book object is nil or destroyed")
        return
    end
    
    -- ตรวจสอบระยะห่าง
    local bookPos
    if bookObject:IsA("Model") then
        local primaryPart = bookObject.PrimaryPart or bookObject:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            bookPos = primaryPart.Position
        end
    else
        bookPos = bookObject.Position
    end


    
    if not bookPos then
        warn("⚠️ [Server] Cannot get book position")
        return
    end
    
    local distance = (humanoidRootPart.Position - bookPos).Magnitude
    if distance > 15 then 
        warn("⚠️ [Server] Player too far from book:", distance)
        return 
    end
    
    -- ดึง Attribute ItemBook
    local bookId = bookObject:GetAttribute("ItemBook")
    if not bookId then
        warn("⚠️ [Server] Book has no ItemBook attribute")
        return
    end
    
    print("📖 [Server] Picking up Book_" .. bookId)
    
    -- สร้าง Tool สมุด
    local book = Instance.new("Tool")
    book.Name = "Book_" .. bookId
    book.RequiresHandle = true
    book.CanBeDropped = false
    
    -- เก็บข้อมูล bookId ใน Tool
    book:SetAttribute("BookId", bookId)
    
    -- สร้าง Handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1.5, 0.2)
    handle.BrickColor = BrickColor.new("Brown")
    handle.CanCollide = false
    handle.Parent = book
    
    -- ใส่สมุดให้ผู้เล่น
    book.Parent = player.Backpack
    
    -- ซ่อนสมุดในโลก (ไม่ลบเพื่อให้วางกลับได้)
    bookObject.Parent = ReplicatedStorage
    
    print("✅ [Server] " .. player.Name .. " picked up Book_" .. bookId)
end)

-- ฟังก์ชันวางสมุด
placeBookEvent.OnServerEvent:Connect(function(player, toolObject, shelfObject)
    print("📥 [Server] Received place request from", player.Name)
    
    local character = player.Character
    if not character then 
        warn("⚠️ [Server] No character")
        return 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        warn("⚠️ [Server] No HumanoidRootPart")
        return 
    end
    
    -- ตรวจสอบว่า objects ยังมีอยู่
    if not toolObject or not toolObject.Parent then
        warn("⚠️ [Server] Tool is nil or destroyed")
        return
    end
    
    if not shelfObject or not shelfObject.Parent then
        warn("⚠️ [Server] Shelf is nil or destroyed")
        return
    end
    
    -- ตรวจสอบระยะห่างกับชั้น
    local shelfPos
    if shelfObject:IsA("Model") then
        local primaryPart = shelfObject.PrimaryPart or shelfObject:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            shelfPos = primaryPart.Position
        end
    else
        shelfPos = shelfObject.Position
    end
    
    if not shelfPos then
        warn("⚠️ [Server] Cannot get shelf position")
        return
    end
    
    local distance = (humanoidRootPart.Position - shelfPos).Magnitude
    if distance > 15 then
        warn("⚠️ [Server] Player too far from shelf:", distance)
        return
    end
    
    -- ดึงข้อมูลสมุด
    local bookId = toolObject:GetAttribute("BookId")
    if not bookId then
        warn("⚠️ [Server] Tool has no BookId attribute")
        return
    end
    
    -- ดึงข้อมูลชั้น
    local shelfId = shelfObject:GetAttribute("table_shelf_for_book")
    if not shelfId then
        warn("⚠️ [Server] Shelf has no table_shelf_for_book attribute")
        return
    end
    
    print("📚 [Server] Checking placement: Book " .. bookId .. " → Shelf " .. shelfId)
    
    -- ตรวจสอบจาก Config
    local configKey = "ItemBook_" .. bookId
    local bookConfig = ItemConfig[configKey]
    
    if not bookConfig then
        warn("⚠️ [Server] No config found for " .. configKey)
        return
    end
    
    local correctShelfId = bookConfig.table_shelf_for_book

    --local correct_
   
    
    --local unuse_book =  "ItemBook_999"


-- ✅ Logic พิเศษสำหรับ ItemBook_999
if correctShelfId == 999 then
    print("⚠️ [Server] Book_999 used at shelf " .. shelfId .. " → Always fail but usable.")

    -- แจ้งเตือนบอทหรือระบบเตือน
    if bookConfig.alert_bot then
        print("🤖 [Server Alert] Book_999 triggered alert_bot for player:", player.Name)
        -- ที่นี่สามารถเรียกฟังก์ชันแจ้งเตือนบอทได้ เช่น
        -- AlertBot:Fire(player, shelfId)
    end

    -- ทำลายสมุดหลังใช้งาน
    toolObject:Destroy()

    -- เพิ่มเอฟเฟกต์หรือเสียงว่า "ไม่สำเร็จ"
    print("💥 [Server] Book_999 destroyed after failed placement")

    return
end


   -- if shelfId ~= unuse_book then
   --     warn("❌ [Server]  Book  999" .. bookId .. " should go to shelf " .. correctShelfId .. " but tried " .. shelfId)
   --     -- TODO: ส่ง feedback ไป client
   --     return
   -- end


    -- ✅ ปกติ: ตรวจสอบความถูกต้องของการวาง
    if shelfId ~= correctShelfId then
        warn("❌ [Server] Wrong shelf! Book " .. bookId .. " should go to shelf " .. correctShelfId .. " but tried " .. shelfId)
        -- TODO: ส่ง feedback ไป client
        return
    end

  
    
    -- ✅ วางถูกที่!
    print("✅ [Server] Correct placement! Book " .. bookId .. " placed at shelf " .. shelfId)
    
    -- ลบ Tool จากผู้เล่น
    toolObject:Destroy()
    
    -- นำสมุดกลับมาแสดงในโลก (ถ้าต้องการ)
    local bookFolder = workspace:FindFirstChild("Book_item")
    if bookFolder then
        local originalBook = ReplicatedStorage:FindFirstChild(toolObject.Name)
        if originalBook then
            originalBook.Parent = bookFolder
            print("📖 [Server] Restored book to world")
        end
    end
    
    -- TODO: เพิ่ม effects, sounds, rewards
end)

print("✅ [Server] BookManagementServer loaded")
