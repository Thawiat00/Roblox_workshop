-- State_FollowFootprint.lua
-- วางไฟล์นี้ใน ServerScriptService/ServerLocal/NPCAI/NPCStates/

local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)
local FootprintScanner = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.FootprintScanner)

return {
    Enter = function(npc)
        npc.humanoid.WalkSpeed = Config.States.FollowFootprint.Speed
        
        -- ตั้งค่าตัวแปรสำหรับ State นี้
        npc.footprintList = {} -- รายการรอยเท้า
        npc.currentFootprintIndex = 1 -- กำลังเดินไปที่รอยเท้าตัวไหน
        npc.scanTimer = 0 -- เวลาถัดไปที่จะสแกนหารอยเท้าใหม่
        npc.lostTrailTimer = 0 -- นับเวลาที่หาไม่เจอรอยเท้าต่อ
        
        print("🦶", npc.model.Name, "→ FollowFootprint")
        
        -- สแกนหารอยเท้าทันที
        local footprints = FootprintScanner.ScanFootprints(
            npc.root.Position,
            Config.States.FollowFootprint.ScanRadius,
            Config.States.FollowFootprint.FootprintTag
        )
        
        if #footprints > 0 then
            npc.footprintList = FootprintScanner.SortByTimestamp(footprints)
            print("  ➜ เจอรอยเท้า", #npc.footprintList, "รอย")
        end
    end,
    
    Update = function(npc, target, distance)
        -- ======== 1. ตรวจจับผู้เล่น (มีความสำคัญสูงสุด) ========
        if target and distance <= Config.States.FollowFootprint.PlayerDetectRange then
            print("  ➜ เจอผู้เล่น! เปลี่ยนเป็น Chase")
            return "Chase"
        end
        
        -- ======== 2. อัพเดท Timer ========
        npc.scanTimer = npc.scanTimer + (npc.deltaTime or 0)
        
        -- ======== 3. สแกนหารอยเท้าใหม่ (ทุกๆ ScanInterval วินาที) ========
        if npc.scanTimer >= Config.States.FollowFootprint.ScanInterval then
            npc.scanTimer = 0
            
            local footprints = FootprintScanner.ScanFootprints(
                npc.root.Position,
                Config.States.FollowFootprint.ScanRadius,
                Config.States.FollowFootprint.FootprintTag
            )
            
            if #footprints > 0 then
                npc.footprintList = FootprintScanner.SortByTimestamp(footprints)
                npc.currentFootprintIndex = 1 -- รีเซ็ตเริ่มใหม่
                npc.lostTrailTimer = 0 -- รีเซ็ตตัวนับหาย
                
                print("  ➜ สแกนใหม่: เจอ", #npc.footprintList, "รอย")
            else
                -- ไม่เจอรอยเท้า
                npc.lostTrailTimer = npc.lostTrailTimer + Config.States.FollowFootprint.ScanInterval
                
                print("  ➜ ไม่เจอรอยเท้า | Lost Time:", npc.lostTrailTimer)
                
                -- หาไม่เจอนานเกินไป → กลับ Idle
                --if npc.lostTrailTimer >= Config.States.FollowFootprint.MaxLostTime then
                --    print("  ➜ หาไม่เจอนานเกินไป! กลับ Idle")
                --    return "Idle"
                --end


                -- หาไม่เจอนาน → กลับ Patrol (แทน Idle)
                if npc.lostTrailTimer >= Config.States.FollowFootprint.MaxLostTime then
                    print("  ➜ หาไม่เจอนานเกินไป! กลับ Patrol")
                    return "Patrol"
                end
            end
        end
        
        -- ======== 4. เดินตามรอยเท้า ========
        if #npc.footprintList > 0 and npc.currentFootprintIndex <= #npc.footprintList then
            local footprint = npc.footprintList[npc.currentFootprintIndex]
            
            -- ตรวจสอบว่ารอยเท้ายังอยู่หรือถูกลบแล้ว
            if not FootprintScanner.IsFootprintValid(footprint) then
                print("  ➜ รอยเท้าถูกลบแล้ว ข้ามไปรอยถัดไป")
                npc.currentFootprintIndex = npc.currentFootprintIndex + 1
                return "FollowFootprint"
            end
            
            -- คำนวณระยะห่าง
            local distanceToFootprint = (npc.root.Position - footprint.Position).Magnitude
            
            -- ถ้าถึงรอยเท้าแล้ว → ไปรอยถัดไป
            if distanceToFootprint <= Config.States.FollowFootprint.StopDistance then
                print("  ➜ ถึงรอยเท้าที่", npc.currentFootprintIndex)
                npc.currentFootprintIndex = npc.currentFootprintIndex + 1
                
                -- ถ้าหมดรอยเท้าแล้ว → สแกนใหม่
                if npc.currentFootprintIndex > #npc.footprintList then
                    print("  ➜ หมดรอยเท้าแล้ว รอสแกนใหม่")
                    npc.footprintList = {}
                end
                
                return "FollowFootprint"
            end
            
            -- เดินไปที่รอยเท้า
            npc.humanoid:MoveTo(footprint.Position)
            
        else
            -- ไม่มีรอยเท้าในลิสต์ → ยืนรอสแกนใหม่
            npc.humanoid:MoveTo(npc.root.Position) -- หยุดเดิน
        end
        
        return "FollowFootprint"
    end,
    
    Exit = function(npc)
        -- ล้างข้อมูลรอยเท้า
        npc.footprintList = {}
        npc.currentFootprintIndex = 1
        npc.scanTimer = 0
        npc.lostTrailTimer = 0
        
        print("  ➜ ออกจาก FollowFootprint")
    end
}