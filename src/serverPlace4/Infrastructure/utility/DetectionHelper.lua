-- ==========================================
-- Infrastructure/utility/DetectionHelper.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: Helper functions สำหรับตรวจจับ player
-- มี Roblox API: ใช้ OverlapParams, GetPartBoundsInRadius
-- ==========================================

local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local DetectionHelper = {}

-- สร้าง OverlapParams สำหรับตรวจจับ (ไม่รวม enemy ตัวเอง)
function DetectionHelper.CreateOverlapParams(enemyModel)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {enemyModel}
    return params
end

-- หา players ทั้งหมดในระยะ
function DetectionHelper.FindPlayersInRange(position, range, overlapParams)
    local detectedPlayers = {}
    
    -- ใช้ GetPartBoundsInRadius หา parts ทั้งหมดในระยะ
    local parts = workspace:GetPartBoundsInRadius(
        position, 
        range or SimpleAIConfig.DetectionRange, 
        overlapParams
    )
    
    -- กรอง HumanoidRootPart ของ player เท่านั้น
    for _, part in ipairs(parts) do
        if part.Name == "HumanoidRootPart" and part.Parent then
            local humanoid = part.Parent:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(detectedPlayers, part)
            end
        end
    end
    
    return detectedPlayers
end

-- หา player ที่ใกล้ที่สุด + ตรวจสอบว่า path ไปถึงได้หรือไม่
function DetectionHelper.FindNearestValidPlayer(enemyPosition, players, pathfindingHelper)
    local nearestPlayer = nil
    local shortestDistance = math.huge
    
    for _, playerPart in ipairs(players) do
        local distance = (playerPart.Position - enemyPosition).Magnitude
        
        if distance < shortestDistance then
            -- ทดสอบว่า path ไปถึงได้หรือไม่
            local path = pathfindingHelper.CreatePath()
            local success, waypoints = pathfindingHelper.ComputePath(
                path, 
                enemyPosition, 
                playerPart.Position
            )
            
            if success and #waypoints > 0 then
                nearestPlayer = playerPart
                shortestDistance = distance
            end
        end
    end
    
    return nearestPlayer, shortestDistance
end

-- คำนวณระยะห่าง
function DetectionHelper.GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end


-- ✨ ใหม่: ตรวจสอบว่า target อยู่นอกระยะไล่หรือไม่
function DetectionHelper.IsTargetOutOfRange(enemyPosition, targetPart, maxRange)
    if not targetPart or not targetPart.Parent then
        return true -- target หายไปแล้ว
    end
    
    local distance = DetectionHelper.GetDistance(enemyPosition, targetPart.Position)
    return distance > maxRange
end


-- ✨ ใหม่: ตรวจสอบว่า target ยังมีชีวิตอยู่หรือไม่
function DetectionHelper.IsTargetValid(targetPart)
    if not targetPart or not targetPart.Parent then
        return false
    end
    
    local humanoid = targetPart.Parent:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    return true
end



return DetectionHelper