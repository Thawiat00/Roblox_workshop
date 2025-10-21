-- =========================================
-- 📄 DragDetector_Properties.lua
-- ตัวอย่างการตั้งค่า Property ของ DragDetector
-- =========================================

local part = workspace:WaitForChild("DraggablePart")
local dragDetector = Instance.new("DragDetector")
dragDetector.Parent = part

-- เปิดให้ใช้งาน
dragDetector.Enabled = true

-- ใช้การเคลื่อนแบบเส้นตรง (เช่น ลากเปิดประตู)
dragDetector.DragStyle = Enum.DragDetectorDragStyle.TranslateLine
dragDetector.Axis = Vector3.new(1, 0, 0) -- เคลื่อนตามแกน X

-- ตอบสนองแบบฟิสิกส์ (ใช้แรง)
dragDetector.ResponseStyle = Enum.DragDetectorResponseStyle.Physical
dragDetector.Responsiveness = 20
dragDetector.MaxForce = 4000
dragDetector.MaxTorque = 2000

-- จำกัดการเคลื่อนที่
dragDetector.MinDragTranslation = Vector3.new(-5, 0, 0)
dragDetector.MaxDragTranslation = Vector3.new(5, 0, 0)
