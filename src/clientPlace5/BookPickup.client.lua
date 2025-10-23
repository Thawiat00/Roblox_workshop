local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- สร้าง RemoteEvent ใน ReplicatedStorage ชื่อ "EquipBook"

local equipBookEvent = ReplicatedStorage:WaitForChild("Common"):WaitForChild("EquipBook")


local bookPart = workspace:WaitForChild("Book") -- สมุดที่วางไว้ในโลก




local isNearBook = false
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ตรวจจับระยะห่างกับสมุด
local function checkDistance()
    while true do
        wait(0.5)
        if character and character:FindFirstChild("HumanoidRootPart") and bookPart then
            local distance = (character.HumanoidRootPart.Position - bookPart.Position).Magnitude
            isNearBook = distance <= 10 -- ถ้าอยู่ในระยะ 10 studs
        end
    end
end

spawn(checkDistance)

-- ตรวจจับการกด E
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E and isNearBook then
        equipBookEvent:FireServer() -- ส่งสัญญาณไปยัง Server
    end
end)