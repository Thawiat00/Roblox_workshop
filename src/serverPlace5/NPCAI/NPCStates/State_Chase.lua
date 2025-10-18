-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Chase.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)
local PathfindingHelper = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.PathfindingHelper)

return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = Config.States.Chase.Speed
        print("🏃", npc.model.Name, "→ Chase")
    end,
    
    Update = function(npc, target, distance)
        if not target then 
            return "Idle" 
        end
        
        -- หายไกลเกินไป
        if distance > Config.Detection.LoseRange then
            return "Idle"
        end
        
        -- ใกล้มาก → โจมตี
        if distance <= Config.States.Chase.MinDistance then
            return "Attack"
        end
        
        -- ไกลพอ และพร้อม Charge → พุ่ง
        if distance >= Config.States.Charge.TriggerDistance and npc.canCharge then
            return "Charge"
        end
        
        -- Pathfinding
        npc.pathTimer = npc.pathTimer + npc.deltaTime
        if npc.pathTimer >= Config.Pathfinding.UpdateInterval then
            npc.pathTimer = 0
            npc.waypoints = PathfindingHelper.CreatePath(npc, target.Position)
            npc.waypointIndex = 1
        end
        
        -- เดินตาม waypoint
        if npc.waypoints and npc.waypoints[npc.waypointIndex] then
            local wp = npc.waypoints[npc.waypointIndex]
            npc.humanoid:MoveTo(wp.Position)
            
            if wp.Action == Enum.PathWaypointAction.Jump then
                npc.humanoid.Jump = true
            end
            
            if (npc.root.Position - wp.Position).Magnitude < Config.Pathfinding.StopDistance then
                npc.waypointIndex = npc.waypointIndex + 1
            end
        else
            -- fallback
            npc.humanoid:MoveTo(target.Position)
        end
        
        return "Chase"
    end,
    
    Exit = function(npc)
    end
}