local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui")
local scrollingFrame = screenGui:WaitForChild("Peak_Choice"):WaitForChild("Side_Peak_inventory"):WaitForChild("holder"):WaitForChild("ScrollingFrame")


-- เชื่อมต่อกับ RemoteEvent
local Handle_choice_peak = ReplicatedStorage:WaitForChild("Common"):WaitForChild("Handle_choice_peak")


-- วนหาปุ่มทั้งหมดใน ScrollingFrame
-- วนหาปุ่มทั้งหมดใน ScrollingFrame
for _, button in pairs(scrollingFrame:GetChildren()) do
    if button:IsA("TextButton") or button:IsA("ImageButton") then
        
        -- เมื่อคลิก - ส่งข้อมูลไปยัง Server
        button.MouseButton1Click:Connect(function()
            print("คลิกปุ่ม:", button.Name)
            
            -- ส่งข้อมูลไปยัง Server ผ่าน RemoteEvent
            Handle_choice_peak:FireServer(button.Name)
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