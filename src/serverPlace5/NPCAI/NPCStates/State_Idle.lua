-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCStates/State_Idle.lua
-- ========================================

-- ✅ เพิ่มระบบสแกนรอยเท้า และตรวจจับผู้เล่น


local Config = require(game.ServerScriptService.ServerLocal.Config.NPCConfig)

local FootprintScanner = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.FootprintScanner)


return {
    -- เมื่อเข้า State Idle
    Enter = function(npc)
        npc.humanoid.WalkSpeed = Config.States.Idle.Speed


        -- ⭐ เพิ่มตัวแปรจับเวลา (สำหรับสแกนรอยเท้า)
        npc.footprintScanTimer = npc.footprintScanTimer or 0

        npc.idleWaitTimer = 0  -- ⭐ เพิ่ม: นับเวลารอก่อนเข้า Patrol

        print("😴", npc.model.Name, "→ Idle")




    end,
    
    Update = function(npc, target,distance)
        -- 🧠 ต้องมีค่า deltaTime จากระบบหลักส่งเข้ามา (npc.deltaTime)
        -- เช่น npc.deltaTime = tick() - npc.lastUpdateTime

          -- ======== 1. ตรวจจับผู้เล่นก่อน (Priority สูงสุด) ========
        if target and distance <= Config.Detection.Range then
            print("  ➜ เจอผู้เล่น! เปลี่ยนเป็น Chase")
            return "Chase"
        end

        -- ======== 2. นับเวลารอก่อนเข้า Patrol ========
        -- ======== 2. สแกนหารอยเท้า (ทุก 2 วินาที) ========
        npc.idleWaitTimer = npc.idleWaitTimer + (npc.deltaTime or 0)



        -- ======== 3. สแกนหารอยเท้า (ทุก 2 วินาที) ========
       -- npc.footprintScanTimer += npc.deltaTime or 0
        npc.footprintScanTimer = npc.footprintScanTimer + (npc.deltaTime or 0)


    
        if npc.footprintScanTimer >= 2 then
            npc.footprintScanTimer = 0

            -- 🔍 สแกนหารอยเท้าในรัศมีที่กำหนด
            local footprints = FootprintScanner.ScanFootprints(
                npc.root.Position,
                Config.States.FollowFootprint.ScanRadius,
                Config.States.FollowFootprint.FootprintTag
            )

            if footprints and #footprints > 0 then
                print("  ➜ เจอรอยเท้า", #footprints, "รอย! → เปลี่ยนเป็น FollowFootprint")
                return "FollowFootprint"
            end
        end



        -- ======== 4. รอครบเวลาแล้ว → เข้า Patrol ========    
        if npc.idleWaitTimer >= Config.States.Idle.WaitTime then
            print("  ➜ รอนานพอแล้ว ไม่เจอรอยเท้า → เข้าโหมด Patrol(เดินสุ่ม)")
            return "Patrol"
        end



        -- ยังอยู่ Idle        
        -- สามารถเพิ่มพฤติกรรมสุ่มเดิน, หมุนตัว, หรือ idle animation ได้ที่นี่
        return "Idle"
    end,
    

    
    -- เมื่อออกจาก State Idle
    Exit = function(npc)
        npc.footprintScanTimer = 0
        npc.idleWaitTimer = 0
    end


    
}