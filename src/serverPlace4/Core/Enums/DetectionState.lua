-- ==========================================
-- Core/Enums/DetectionState.lua (ModuleScript)
-- ==========================================
-- ✨ ใหม่ Phase 2: สถานะการตรวจจับ player
-- ==========================================

local DetectionState = {
    Default = "Default",           -- ไม่ได้ค้นหา
    Start_Detect = "Start_Detect", -- กำลังค้นหา/เจอ player
    Stop_Detect = "Stop_Detect"    -- หยุดค้นหา
}

return DetectionState