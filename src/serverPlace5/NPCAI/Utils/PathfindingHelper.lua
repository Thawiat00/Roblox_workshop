-- ========================================
-- 📄 ServerScriptService/NPCAI/Utils/PathfindingHelper.lua
-- ========================================
local PathfindingService = game:GetService("PathfindingService")
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

local PathfindingHelper = {}

function PathfindingHelper.CreatePath(npc, targetPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = Config.Pathfinding.AgentRadius,
        AgentHeight = Config.Pathfinding.AgentHeight,
        AgentCanJump = true,
        WaypointSpacing = Config.Pathfinding.WaypointSpacing
    })
    
    path:ComputeAsync(npc.root.Position, targetPos)
    
    if path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    else
        return nil
    end
end

return PathfindingHelper