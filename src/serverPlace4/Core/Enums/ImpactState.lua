-- ==========================================
-- Core/Enums/ImpactState.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: กำหนดสถานะการถูกกระแทก
-- Pure Enum: ไม่พึ่งพาไฟล์อื่น
-- ==========================================

local ImpactState = {
    None = "None",           -- ไม่โดนกระแทก
    Pushed = "Pushed",       -- กำลังถูกผลัก
    Recovering = "Recovering" -- กำลัง recovery
}

return ImpactState