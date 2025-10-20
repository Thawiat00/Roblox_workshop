-- ========================================
-- 📄 PushPart Script
-- ผลักผู้เล่นตามทิศทางที่ Part หันหน้าอยู่
-- ========================================

local pushPart = script.Parent        -- ตัว Part ที่จะผลัก
local PUSH_FORCE = 100                -- แรงผลัก (ค่ามาก = ผลักแรง)
local UP_FORCE = 20                   -- แรงยกขึ้น (0 = ไม่ลอย)
local COOLDOWN = 1                    -- เวลาระหว่างผลักต่อผู้เล่นแต่ละคน (วินาที)

local debounce = {}                   -- ป้องกันการโดนผลักซ้ำ

pushPart.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if humanoid then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and not debounce[character] then
			
			-- ✅ เปิดระบบ debounce
			debounce[character] = true
			task.delay(COOLDOWN, function()
				debounce[character] = nil
			end)
			
			-- ✅ คำนวณแรงผลัก
			local mass = root.AssemblyMass
			local direction = pushPart.CFrame.LookVector -- ทิศทางที่ Part หันหน้าอยู่
			local impulse = (direction * PUSH_FORCE * mass) + Vector3.new(0, UP_FORCE * mass, 0)
			
			-- ✅ ใช้แรงผลัก
			root:ApplyImpulse(impulse)
			
			-- ✅ debug log
			print("💨 Pushed player:", character.Name)
		end
	end
end)
