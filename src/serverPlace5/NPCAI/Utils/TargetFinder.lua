-- ========================================
-- 📄 ServerScriptService/NPCAI/Utils/TargetFinder.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

local TargetFinder = {}

function TargetFinder.FindNearestPlayer(npc)
    local nearest = nil
    local nearestDist = math.huge
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - npc.root.Position).Magnitude
            
            if dist <= Config.Detection.Range and dist < nearestDist then
                nearestDist = dist
                nearest = player.Character.HumanoidRootPart
            end
        end
    end
    
    return nearest, nearestDist
end

return TargetFinder