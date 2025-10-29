-- FootprintScanner.lua
-- วางไฟล์นี้ใน ServerScriptService/ServerLocal/NPCAI/Utils/

local CollectionService = game:GetService("CollectionService")

local FootprintScanner = {}

-- สแกนหารอยเท้าในรัศมี
function FootprintScanner.ScanFootprints(position, radius, tag)
	tag = tag or "PlayerFootprint"
	
	local allFootprints = CollectionService:GetTagged(tag)
	local nearbyFootprints = {}
	
	-- กรองเฉพาะรอยเท้าที่อยู่ในรัศมี
	for _, footprint in ipairs(allFootprints) do
		if footprint and footprint.Parent then -- ตรวจสอบว่ายังไม่ถูกลบ
			local distance = (footprint.Position - position).Magnitude
			if distance <= radius then
				table.insert(nearbyFootprints, footprint)
			end
		end
	end
	
	return nearbyFootprints
end

-- เรียงลำดับรอยเท้าตาม Timestamp (จากใหม่ไปเก่า)
function FootprintScanner.SortByTimestamp(footprints)
	local sortedFootprints = {}
	
	-- คัดลอกและตรวจสอบว่ามี Timestamp
	for _, footprint in ipairs(footprints) do
		local timestamp = footprint:FindFirstChild("Timestamp")
		if timestamp and timestamp:IsA("NumberValue") then
			table.insert(sortedFootprints, {
				part = footprint,
				time = timestamp.Value
			})
		end
	end
	
	-- เรียงจากมากไปน้อย (ใหม่ไปเก่า)
	table.sort(sortedFootprints, function(a, b)
		return a.time > b.time
	end)
	
	-- คืนค่าเฉพาะ part
	local result = {}
	for _, data in ipairs(sortedFootprints) do
		table.insert(result, data.part)
	end
	
	return result
end

-- ค้นหารอยเท้าที่ใหม่ที่สุดในรัศมี
function FootprintScanner.FindNewestFootprint(position, radius, tag)
	local footprints = FootprintScanner.ScanFootprints(position, radius, tag)
	
	if #footprints == 0 then
		return nil
	end
	
	local sorted = FootprintScanner.SortByTimestamp(footprints)
	
	return sorted[1] -- รอยเท้าใหม่ที่สุด
end

-- ดึงรอยเท้าทั้งหมดของผู้เล่นคนเดียว (จาก OwnerName)
function FootprintScanner.GetPlayerFootprints(playerName, tag)
	tag = tag or "PlayerFootprint"
	
	local allFootprints = CollectionService:GetTagged(tag)
	local playerFootprints = {}
	
	for _, footprint in ipairs(allFootprints) do
		if footprint and footprint.Parent then
			local owner = footprint:FindFirstChild("OwnerName")
			if owner and owner.Value == playerName then
				table.insert(playerFootprints, footprint)
			end
		end
	end
	
	return playerFootprints
end

-- สร้าง Path จากรอยเท้าที่เรียงแล้ว
function FootprintScanner.CreateFootprintPath(footprints, maxFootprints)
	maxFootprints = maxFootprints or 10 -- จำกัดไม่ให้เยอะเกินไป
	
	local path = {}
	local count = math.min(#footprints, maxFootprints)
	
	for i = 1, count do
		if footprints[i] and footprints[i].Parent then
			table.insert(path, footprints[i].Position)
		end
	end
	
	return path
end

-- ตรวจสอบว่ารอยเท้ายังอยู่หรือถูกลบแล้ว
function FootprintScanner.IsFootprintValid(footprint)
	return footprint and footprint.Parent ~= nil
end

-- นับจำนวนรอยเท้าในรัศมี
function FootprintScanner.CountFootprints(position, radius, tag)
	local footprints = FootprintScanner.ScanFootprints(position, radius, tag)
	return #footprints
end

-- ค้นหารอยเท้าที่ใกล้ที่สุด
function FootprintScanner.FindNearestFootprint(position, radius, tag)
	local footprints = FootprintScanner.ScanFootprints(position, radius, tag)
	
	if #footprints == 0 then
		return nil, math.huge
	end
	
	local nearest = nil
	local nearestDistance = math.huge
	
	for _, footprint in ipairs(footprints) do
		local distance = (footprint.Position - position).Magnitude
		if distance < nearestDistance then
			nearest = footprint
			nearestDistance = distance
		end
	end
	
	return nearest, nearestDistance
end

return FootprintScanner