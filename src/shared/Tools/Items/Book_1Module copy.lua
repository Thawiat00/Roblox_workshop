-- 🔹 ReplicatedStorage/Tools/ArmorModule
local ArmorModule = {}

ArmorModule.Name = "Armor"
ArmorModule.DefenseBoost = 15

function ArmorModule:Equip(player)
    if player and player:FindFirstChild("Defense") then
        player.Defense.Value = player.Defense.Value + self.DefenseBoost
        print(self.Name .. " เพิ่ม Defense ให้ " .. self.DefenseBoost)
    end
end



function ArmorModule:Unequip(player)
    if player and player:FindFirstChild("Defense") then
        player.Defense.Value = player.Defense.Value - self.DefenseBoost
        print(self.Name .. " ลด Defense " .. self.DefenseBoost)
    end
end



return ArmorModule
