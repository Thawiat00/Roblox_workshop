
-- ==========================================
-- Core/Enums/SoundState.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: กำหนดสถานะการรับรู้เสียงของ AI
-- Pure Enum: ไม่พึ่งพา Roblox API
-- ==========================================

local SoundState = {
    Silent = "Silent",              -- ไม่ได้ยินเสียง (สถานะปกติ)
    Alerted = "Alerted",            -- ได้ยินเสียง กำลัง Alert
    Investigating = "Investigating" -- กำลังเดินทางไปตรวจสอบเสียง
}

return SoundState