local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Handle_choice_peak = ReplicatedStorage:WaitForChild("Common"):WaitForChild("Handle_choice_peak")

-- เก็บข้อมูล peak ของผู้เล่นแต่ละคน
local playerPeaks = {}  -- ตัวอย่าง: playerPeaks[player] = { "Blood Link", "Thunder Core" }

Handle_choice_peak.OnServerEvent:Connect(function(player, peakName)
	print("🛰️ Server รับข้อมูลจาก:", player.Name, "| ปุ่มที่คลิก:", peakName)

	-- ถ้าเพิ่งเข้ามาครั้งแรก ให้สร้างตารางเก็บข้อมูลก่อน
	if not playerPeaks[player] then
		playerPeaks[player] = {}
	end

	local peaks = playerPeaks[player]

	-- ฟังก์ชันหาว่าผู้เล่นมี peak นี้อยู่ไหม
	local function HasPeak(name)
		for _, n in ipairs(peaks) do
			if n == name then return true end
		end
		return false
	end

	-- ฟังก์ชันเพิ่ม/ลบ
	if HasPeak(peakName) then
		-- 🔹 ถ้ามีแล้ว → ลบออก
		for i, n in ipairs(peaks) do
			if n == peakName then
				table.remove(peaks, i)
				break
			end
		end
		print("🧹 ลบ Peak:", peakName)
	else
		-- 🔹 ถ้ายังไม่มี → เพิ่มเข้าไป (สูงสุด 3 ช่อง)
		if #peaks >= 3 then
			print("❌ ไม่มีช่องว่างเหลือแล้ว")
			return
		end
		table.insert(peaks, peakName)
		print("✅ เพิ่ม Peak:", peakName)
	end

	-- 🔍 Debug
	print("🎒 Peak ปัจจุบันของ", player.Name .. ":", table.concat(peaks, ", "))

	-- (ถ้าต้องการให้ Client อัปเดต UI ด้วย ก็ Fire กลับไป Client ได้)
	-- Handle_choice_peak:FireClient(player, peaks)
end)

-- เมื่อผู้เล่นออกจากเกม ลบข้อมูลออก
game.Players.PlayerRemoving:Connect(function(player)
	playerPeaks[player] = nil
end)
