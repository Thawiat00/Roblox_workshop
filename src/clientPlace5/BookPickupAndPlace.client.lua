-- ========================================
-- 📋 CLIENT SCRIPT: BookPickupAndPlace
-- ========================================

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()




-- รอ Remote Events
local Common = ReplicatedStorage:WaitForChild("Common", 10)
if not Common then
    warn("❌ [Client] Cannot find Common folder!")
    return
end

local equipBookEvent = Common:WaitForChild("EquipBook", 10)
local placeBookEvent = Common:WaitForChild("PlaceBook", 10)

if not equipBookEvent or not placeBookEvent then
    warn("❌ [Client] Cannot find Remote Events!")
    return
end

local isNearBook = false
local isNearShelf = false
local currentBook = nil
local nearbyShelf = nil

-- ฟังก์ชันตรวจสอบระยะห่างกับสมุด
local function checkBookDistance()
    while true do
        task.wait(0.5)
        
        -- อัปเดต character reference
        if not character or not character.Parent then
            character = player.Character
            if not character then
                continue
            end
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bookFolder = workspace:FindFirstChild("Book_item")
            if bookFolder then
                isNearBook = false
                currentBook = nil
                
                for _, book in pairs(bookFolder:GetChildren()) do
                    if book:IsA("BasePart") or book:IsA("Model") then
                        local bookPos
                        
                        if book:IsA("Model") then
                            local primaryPart = book.PrimaryPart or book:FindFirstChildWhichIsA("BasePart")
                            if primaryPart then
                                bookPos = primaryPart.Position
                            end
                        else
                            bookPos = book.Position
                        end
                        
                        if bookPos then
                            local distance = (hrp.Position - bookPos).Magnitude
                            if distance <= 10 then
                                isNearBook = true
                                currentBook = book
                                print("📖 [Client] Near book:", book.Name)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ฟังก์ชันตรวจสอบระยะห่างกับชั้นวางสมุด
local function checkShelfDistance()
    while true do
        task.wait(0.5)
        
        if not character or not character.Parent then
            character = player.Character
            if not character then
                continue
            end
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local shelfFolder = workspace:FindFirstChild("table_shelf_for_book")
            if shelfFolder then
                isNearShelf = false
                nearbyShelf = nil
                
                for _, shelf in pairs(shelfFolder:GetChildren()) do
                    if shelf:IsA("BasePart") or shelf:IsA("Model") then
                        local shelfPos
                        
                        if shelf:IsA("Model") then
                            local primaryPart = shelf.PrimaryPart or shelf:FindFirstChildWhichIsA("BasePart")
                            if primaryPart then
                                shelfPos = primaryPart.Position
                            end
                        else
                            shelfPos = shelf.Position
                        end
                        
                        if shelfPos then
                            local distance = (hrp.Position - shelfPos).Magnitude
                            if distance <= 10 then
                                isNearShelf = true
                                nearbyShelf = shelf
                                print("📚 [Client] Near shelf:", shelf.Name)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

-- เริ่มตรวจสอบระยะห่าง
task.spawn(checkBookDistance)
task.spawn(checkShelfDistance)

-- อัปเดต character เมื่อ respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    print("🔄 [Client] Character respawned")
end)

-- ตรวจจับการกด E
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        -- ตรวจสอบ character ยังมีอยู่หรือไม่
        if not character or not character.Parent then
            return
        end
        
        -- ถ้ามีสมุดในมือและอยู่ใกล้ชั้น = วางสมุด
        local equippedTool = character:FindFirstChildOfClass("Tool")
        
        if equippedTool and equippedTool.Name:match("Book") and isNearShelf and nearbyShelf then
            print("🔵 [Client] Attempting to place book at shelf")
            local success, err = pcall(function()
                placeBookEvent:FireServer(equippedTool, nearbyShelf)
            end)
            if not success then
                warn("❌ [Client] Error placing book:", err)
            end
            
        -- ถ้าไม่มีสมุดในมือและอยู่ใกล้สมุด = หยิบสมุด
        elseif not equippedTool and isNearBook and currentBook then
            print("🔵 [Client] Attempting to pick up book:", currentBook.Name)
            local success, err = pcall(function()
                equipBookEvent:FireServer(currentBook)
            end)
            if not success then
                warn("❌ [Client] Error picking up book:", err)
            end
        else
            -- Debug info
            print("ℹ️ [Client] Cannot interact:")
            print("  - Has tool?", equippedTool ~= nil)
            print("  - Near book?", isNearBook)
            print("  - Near shelf?", isNearShelf)
        end
    end
end)

print("✅ [Client] BookPickupAndPlace loaded successfully")