-- ==========================================
-- Application/Services/DetectionService.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Logic การตรวจจับ player
-- ไม่มี Roblox API: Logic บริสุทธิ์
-- ==========================================

local DetectionState = require(game.ServerScriptService.ServerLocal.Core.Enums.DetectionState)

local DetectionService = {}
DetectionService.__index = DetectionService

function DetectionService.new(enemyData)
    local self = setmetatable({}, DetectionService)
    self.EnemyData = enemyData
    return self
end

-- เริ่มตรวจจับ
function DetectionService:StartDetection(detectedObject)
    if not detectedObject then
        warn("[DetectionService] Cannot start detection: object is nil")
        return false
    end
    
    self.EnemyData:SetDetectedObject(detectedObject)
    self.EnemyData:SetDetectionState(DetectionState.Start_Detect)
    
    print("[DetectionService] Started detecting:", detectedObject)
    return true
end

-- หยุดตรวจจับ
function DetectionService:StopDetection()
    self.EnemyData:SetDetectedObject(nil)
    self.EnemyData:SetDetectionState(DetectionState.Stop_Detect)
    
    print("[DetectionService] Stopped detection")
end

-- รีเซ็ต
function DetectionService:ResetDetection()
    self.EnemyData:SetDetectedObject(nil)
    self.EnemyData:SetDetectionState(DetectionState.Default)
end

-- ตรวจสอบว่ากำลัง detect อยู่หรือไม่
function DetectionService:IsDetecting()
    return self.EnemyData:IsDetecting()
end

-- ดึง object ที่ detect ได้
function DetectionService:GetDetectedObject()
    return self.EnemyData.DetectedObject
end

return DetectionService