-- Script ใส่ใน Part แต่ละชิ้น
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tools = ReplicatedStorage:WaitForChild("Tools")

local part = script.Parent
local ClickDetector = part:WaitForChild("ClickDetector")

ClickDetector.MouseClick:Connect(function(player)
    local backpack = player:WaitForChild("Backpack")
    
    local toolName
    if part.Name == "SwordPart_Part" then
        toolName = "Sword"
    elseif part.Name == "ArmorPart_Part" then
        toolName = "Armor"
    elseif part.Name == "BookPart_Part" then
        toolName = "Book"
    elseif part.Name == "PetPart_Part" then
        toolName = "Pet"
    elseif part.Name == "ComputerPart" then
        toolName = "Computer"


    end

    
    if toolName and not backpack:FindFirstChild(toolName) then

        local toolClone = Tools:FindFirstChild(toolName):Clone()
        toolClone.Parent = backpack
        print(player.Name .. " ได้รับไอเท็ม: " .. toolName)

    else
        print(player.Name .. " มีไอเท็มนี้แล้ว")
    end


end)
