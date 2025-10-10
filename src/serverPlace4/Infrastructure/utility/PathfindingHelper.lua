-- ==========================================
-- Infrastructure/utility/PathfindingHelper.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: Helper functions สำหรับ Pathfinding
-- มี Roblox API: ใช้ PathfindingService, OverlapParams
-- ==========================================

local PathfindingService = game:GetService("PathfindingService")
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local PathfindingHelper = {}

-- สร้าง Path object
function PathfindingHelper.CreatePath()
    return PathfindingService:CreatePath({
        WaypointSpacing = SimpleAIConfig.WaypointSpacing,
        AgentRadius = SimpleAIConfig.AgentRadius,
        AgentHeight = SimpleAIConfig.AgentHeight,
        AgentCanJump = SimpleAIConfig.AgentCanJump
    })
end

-- คำนวณ path จาก start ไป target
function PathfindingHelper.ComputePath(path, startPos, targetPos)
    local success = pcall(function()
        path:ComputeAsync(startPos, targetPos)
    end)
    
    if not success then
        warn("[PathfindingHelper] Failed to compute path")
        return false, {}
    end
    
    if path.Status ~= Enum.PathStatus.Success then
        warn("[PathfindingHelper] Path status:", path.Status)
        return false, {}
    end
    
    return true, path:GetWaypoints()
end

-- ตรวจสอบว่า waypoint ต้องกระโดดหรือไม่
function PathfindingHelper.ShouldJump(waypoint)
    return waypoint.Action == Enum.PathWaypointAction.Jump
end

return PathfindingHelper