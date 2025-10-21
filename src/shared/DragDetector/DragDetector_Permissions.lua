-- =========================================
-- 📄 DragDetector_Permissions.lua
-- ตัวอย่างการใช้ Permission แบบ Scriptable
-- =========================================

local dragDetector = workspace.DraggablePart:WaitForChild("DragDetector")
dragDetector.PermissionPolicy = Enum.DragDetectorPermissionPolicy.Scriptable

dragDetector:SetPermissionPolicyFunction(function(player, part)
	if player:GetAttribute("IsVIP") then
		return true
	elseif part.Name == "LockedDrawer" then
		return false
	else
		return true
	end
end)
