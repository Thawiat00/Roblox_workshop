-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Chase.lua
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)
local PathfindingHelper = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.PathfindingHelper)

local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)


-- 🔥 เพิ่มการเชื่อม PerkManager
local PerkManager = require(game.ServerScriptService.ServerLocal.PerkSystem.PerkManager)




return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = Config.States.Chase.Speed

        npc.pathTimer = 0


        print("🏃", npc.model.Name, "→ Chase")


      -- 🔥 แจ้ง EventBus ว่าเริ่มไล่ (เพิ่มเฉพาะนี้)
        if npc.lastTarget then
            local player = game.Players:GetPlayerFromCharacter(npc.lastTarget.Parent)
            if player then
                EventBus:Emit("NPCStartChasing", npc, player)
            end
        end

    end,
    
    Update = function(npc, target, distance)
        if not target then 

     -- 🔥 แจ้ง EventBus ว่าหยุดไล่ (เพิ่มเฉพาะนี้)
            if npc.lastTarget then
                local player = game.Players:GetPlayerFromCharacter(npc.lastTarget.Parent)
                if player then
                    EventBus:Emit("NPCStopChasing", npc, player)
                end
            end



            return "Idle" 
        end
        
  -- 🔥 เก็บ Target ล่าสุด (เพิ่ม 1 บรรทัด)
        npc.lastTarget = target


               -- 🔥 เช็คว่าผู้เล่นหายตัวหรือไม่ (เพิ่มแค่นี้)
        local player = game.Players:GetPlayerFromCharacter(target.Parent)
        if player and player.Character then
            local isInvisible = player.Character:GetAttribute("IsInvisible")
            if isInvisible then
                print("👻", npc.model.Name, "lost target (invisible)")
                EventBus:Emit("NPCStopChasing", npc, player)
                return "Idle"
            end
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

        -- 🔥 แจ้ง EventBus ว่าออกจาก Chase (เพิ่มเฉพาะนี้)
        if npc.lastTarget then
            local player = game.Players:GetPlayerFromCharacter(npc.lastTarget.Parent)
            if player then
                EventBus:Emit("NPCStopChasing", npc, player)
            end
        end
    end
}