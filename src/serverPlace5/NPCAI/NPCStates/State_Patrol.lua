-- ========================================
-- 📄 State_Patrol.lua (เวอร์ชัน Debug)
-- ========================================
local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)
local FootprintScanner = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.FootprintScanner)
local PathfindingHelper = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.PathfindingHelper)

local function GetRandomPatrolPoint(centerPosition, radius)
    local angle = math.random() * math.pi * 2
    local distance = math.random() * radius
    
    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance
    
    local point = Vector3.new(
        centerPosition.X + offsetX,
        centerPosition.Y,
        centerPosition.Z + offsetZ
    )
    
    print("🎲 สุ่มตำแหน่งใหม่:", point, "ห่างจากจุดกลาง", distance, "studs")
    return point
end

return {
    Enter = function(npc)
        print("=" .. string.rep("=", 50))
        print("🚶 ENTER PATROL STATE")
        print("=" .. string.rep("=", 50))
        
        npc.humanoid.WalkSpeed = Config.States.Patrol.Speed
        print("⚡ WalkSpeed:", npc.humanoid.WalkSpeed)
        
        -- บันทึกตำแหน่งเริ่มต้น
        if not npc.spawnPosition then
            npc.spawnPosition = npc.root.Position
            print("📍 Spawn Position:", npc.spawnPosition)
        end
        
        -- ตรวจสอบ Root
        print("🔍 Root Anchored?", npc.root.Anchored)
        if npc.root.Anchored then
            warn("⚠️ Root is Anchored! ปลด Anchor...")
            npc.root.Anchored = false
        end
        
        -- ตั้งค่าตัวแปร
        npc.patrolTarget = nil
        npc.patrolWaitTimer = 0
        npc.patrolWaitDuration = math.random(
            Config.States.Patrol.MinWaitTime,
            Config.States.Patrol.MaxWaitTime
        )
        npc.isWaitingAtPoint = false
        npc.footprintScanTimer = 0
        npc.pathTimer = 0
        npc.waypoints = nil
        npc.waypointIndex = 1
        
        print("⏱️ จะรอที่จุดหมายเป็นเวลา:", npc.patrolWaitDuration, "วินาที")
        
        -- สุ่มตำแหน่งแรก
        npc.patrolTarget = GetRandomPatrolPoint(
            npc.spawnPosition,
            Config.States.Patrol.WanderRadius
        )
        
        print("=" .. string.rep("=", 50))
    end,
    
    Update = function(npc, target, distance)
        -- ======== 1. ตรวจจับผู้เล่น ========
        if target and distance <= Config.States.Patrol.PlayerDetectRange then
            print("👁️ เจอผู้เล่น! → Chase")
            return "Chase"
        end
        
        -- ======== 2. สแกนหารอยเท้า ========
        npc.footprintScanTimer = npc.footprintScanTimer + (npc.deltaTime or 0)
        
        if npc.footprintScanTimer >= Config.States.Patrol.FootprintScanInterval then
            npc.footprintScanTimer = 0
            
            local footprints = FootprintScanner.ScanFootprints(
                npc.root.Position,
                Config.States.FollowFootprint.ScanRadius,
                Config.States.FollowFootprint.FootprintTag
            )
            
            if footprints and #footprints > 0 then
                print("🦶 เจอรอยเท้า! → FollowFootprint")
                return "FollowFootprint"
            end
        end
        
        -- ======== 3. ถ้ากำลังรอ ========
        if npc.isWaitingAtPoint then
            npc.patrolWaitTimer = npc.patrolWaitTimer + (npc.deltaTime or 0)
            npc.humanoid:MoveTo(npc.root.Position)
            
            -- แสดง progress bar
            local progress = math.floor((npc.patrolWaitTimer / npc.patrolWaitDuration) * 100)
            if progress % 20 == 0 then
                print("⏳ รออยู่...", progress .. "%")
            end
            
            if npc.patrolWaitTimer >= npc.patrolWaitDuration then
                print("✅ รอครบแล้ว! สุ่มจุดใหม่")
                
                npc.isWaitingAtPoint = false
                npc.patrolWaitTimer = 0
                npc.patrolWaitDuration = math.random(
                    Config.States.Patrol.MinWaitTime,
                    Config.States.Patrol.MaxWaitTime
                )
                
                npc.patrolTarget = GetRandomPatrolPoint(
                    npc.spawnPosition,
                    Config.States.Patrol.WanderRadius
                )
                
                npc.waypoints = nil
                npc.waypointIndex = 1
            end
            
            return "Patrol"
        end
        
        -- ======== 4. เดินไปยังจุดเป้าหมาย ========
        if npc.patrolTarget then
            local distanceToTarget = (npc.root.Position - npc.patrolTarget).Magnitude
            
            -- Debug: แสดงระยะห่างทุก 1 วินาที
            if not npc.lastDistancePrint then
                npc.lastDistancePrint = 0
            end
            npc.lastDistancePrint = npc.lastDistancePrint + (npc.deltaTime or 0)
            
            if npc.lastDistancePrint >= 1 then
                print("📏 ระยะห่างจากเป้าหมาย:", math.floor(distanceToTarget), "studs")
                npc.lastDistancePrint = 0
            end
            
            -- ถึงจุดเป้าหมายแล้ว
            if distanceToTarget <= Config.States.Patrol.StopDistance then
                print("🎯 ถึงจุดหมายแล้ว! เริ่มรอ", npc.patrolWaitDuration, "วินาที")
                npc.isWaitingAtPoint = true
                npc.patrolWaitTimer = 0
                return "Patrol"
            end
            
            -- Pathfinding
            npc.pathTimer = npc.pathTimer + (npc.deltaTime or 0)
            
            if npc.pathTimer >= Config.Pathfinding.UpdateInterval then
                npc.pathTimer = 0
                
                print("🗺️ คำนวณ Path ใหม่...")
                npc.waypoints = PathfindingHelper.CreatePath(npc, npc.patrolTarget)
                npc.waypointIndex = 1
                
                if not npc.waypoints or #npc.waypoints == 0 then
                    warn("⚠️ Pathfinding ล้มเหลว! ไม่มี waypoints")
                    print("🔄 ลองเดินตรงไปแทน...")
                    npc.humanoid:MoveTo(npc.patrolTarget)
                else
                    print("✅ Pathfinding สำเร็จ:", #npc.waypoints, "waypoints")
                end
            end
            
            -- เดินตาม waypoints
            if npc.waypoints and npc.waypoints[npc.waypointIndex] then
                local wp = npc.waypoints[npc.waypointIndex]
                npc.humanoid:MoveTo(wp.Position)
                
                if wp.Action == Enum.PathWaypointAction.Jump then
                    npc.humanoid.Jump = true
                    print("🦘 กระโดด!")
                end
                
                if (npc.root.Position - wp.Position).Magnitude < Config.Pathfinding.StopDistance then
                    npc.waypointIndex = npc.waypointIndex + 1
                    print("➡️ ไปยัง waypoint ถัดไป:", npc.waypointIndex)
                end
            else
                -- Fallback
                npc.humanoid:MoveTo(npc.patrolTarget)
            end
        end
        
        return "Patrol"
    end,
    
    Exit = function(npc)
        print("🚪 ออกจาก Patrol")
        npc.patrolTarget = nil
        npc.patrolWaitTimer = 0
        npc.isWaitingAtPoint = false
        npc.footprintScanTimer = 0
        npc.waypoints = nil
        npc.lastDistancePrint = nil
    end
}