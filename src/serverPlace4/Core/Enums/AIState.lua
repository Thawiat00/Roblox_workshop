-- ==========================================
-- Core/Enums/AIState.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: กำหนดสถานะทั้งหมดที่ AI สามารถมีได้
-- เขียนก่อนเพราะ: เป็นค่าคงที่ที่ทุก Layer จะใช้อ้างอิง
-- ไม่พึ่งพา: ไฟล์อื่นเลย (Pure Enum)
-- ==========================================


local AIState = {
    Idle = "Idle",
    Walk = "Walk",
    Stop = "Stop",




    Chase = "Chase",      -- ✨ ใหม่: วิ่งไล่ player
    Jumping = "Jumping" ,  -- ✨ ใหม่: กระโดด


    -- ✨ Phase 3: Spear Dash System
    SpearDash = "SpearDash",  -- กำลังพุ่งใส่ player
    Recover = "Recover",        -- พักหลังพุ่งเสร็จ

    ChaseSmooth = "ChaseSmooth", -- ไล่ผู้เล่นแบบลื่นไหล (Phase 6)

    Attack_ = "Attack",

    Patrol = "Patrol",

}
return AIState