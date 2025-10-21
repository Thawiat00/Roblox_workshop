-- =========================================
-- 📄 DragDetector_Events.lua
-- ตัวอย่างการใช้งาน Event ของ DragDetector
-- =========================================

local dragDetector = workspace.DraggablePart:WaitForChild("DragDetector")

dragDetector.DragStart:Connect(function(player, cursorRay, viewFrame, hitFrame, clickedPart)
	print(player.Name .. " started dragging " .. clickedPart.Name)
end)

dragDetector.DragContinue:Connect(function(player, cursorRay, viewFrame)
	print(player.Name .. " is dragging...")
end)

dragDetector.DragEnd:Connect(function(player)
	print(player.Name .. " stopped dragging.")
end)
