-- ==========================================
-- Application/Services/PathfindingLogicService.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Logic การคำนวณเส้นทาง
-- ไม่มี Roblox API โดยตรง: แค่เก็บ waypoints
-- ==========================================

local PathfindingLogicService = {}
PathfindingLogicService.__index = PathfindingLogicService

function PathfindingLogicService.new()
    local self = setmetatable({}, PathfindingLogicService)
    self.Waypoints = {}
    self.CurrentWaypointIndex = 1
    return self
end

-- เก็บ waypoints ที่คำนวณได้
function PathfindingLogicService:SetWaypoints(waypoints)
    self.Waypoints = waypoints or {}
    self.CurrentWaypointIndex = 1
    
    print("[PathfindingLogic] Set", #self.Waypoints, "waypoints")
end

-- ดึง waypoint ถัดไป
function PathfindingLogicService:GetNextWaypoint()
    if self.CurrentWaypointIndex > #self.Waypoints then
        return nil
    end
    
    local waypoint = self.Waypoints[self.CurrentWaypointIndex]
    self.CurrentWaypointIndex = self.CurrentWaypointIndex + 1
    
    return waypoint
end

-- ตรวจสอบว่ามี waypoint เหลืออยู่หรือไม่
function PathfindingLogicService:HasWaypoints()
    return self.CurrentWaypointIndex <= #self.Waypoints
end

-- รีเซ็ต waypoints
function PathfindingLogicService:Reset()
    self.Waypoints = {}
    self.CurrentWaypointIndex = 1
end

-- นับจำนวน waypoints
function PathfindingLogicService:GetWaypointCount()
    return #self.Waypoints
end

return PathfindingLogicService