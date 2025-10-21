-- =========================================
-- 📄 DragDetector_Methods.lua
-- รวมตัวอย่างการใช้ Method ของ DragDetector
-- =========================================

local dragDetector = workspace.DraggablePart:WaitForChild("DragDetector")

-- 🔹 เพิ่ม Constraint (เช่น จำกัดระยะการเคลื่อน)
dragDetector:AddConstraintFunction(1, function(proposedCFrame)
	local position = proposedCFrame.Position
	position = Vector3.new(math.clamp(position.X, -10, 10), position.Y, position.Z)
	return CFrame.new(position)
end)

-- 🔹 เรียกใช้งาน GetReferenceFrame
local referenceFrame = dragDetector:GetReferenceFrame()
print("Reference Frame:", referenceFrame)

-- 🔹 เปลี่ยน DragStyle ระหว่างเกม
dragDetector.DragStyle = Enum.DragDetectorDragStyle.RotateAxis
dragDetector:RestartDrag()
