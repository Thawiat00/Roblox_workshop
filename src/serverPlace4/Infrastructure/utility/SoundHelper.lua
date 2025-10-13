-- ==========================================
-- Infrastructure/utility/SoundHelper.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: Helper functions สำหรับตรวจจับเสียง
-- มี Roblox API: ใช้ OverlapParams, GetPartBoundsInRadius
-- ==========================================


local SoundHelper = {}
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- ✅ โหลด Config หนึ่งครั้ง (ไม่ต้องแก้ parameter)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)


local SoundHelper = {}

-- ==========================================
-- ✨ สร้าง Sound Wave (วงกลมเสียง)
-- ==========================================
function SoundHelper.CreateSoundWave(position, radius, duration)
    -- ตรวจสอบ config ก่อนสร้าง visual
    if not SimpleAIConfig.SoundVisualEffect then
        return nil
    end

    local soundWave = Instance.new("Part")
    soundWave.Name = "SoundWave"
    soundWave.Anchored = true
    soundWave.CanCollide = false
    soundWave.Shape = Enum.PartType.Cylinder
    soundWave.Size = Vector3.new(0.5, radius * 2, radius * 2)
    soundWave.Position = position
    soundWave.Orientation = Vector3.new(0, 0, 90)
    soundWave.Material = Enum.Material.Neon
    soundWave.Color = Color3.fromRGB(255, 200, 100)
    soundWave.Transparency = 0.7
    soundWave.Parent = workspace

    -- Tween ขยายออก
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goal = {
        Size = Vector3.new(0.5, radius * 2, radius * 2),
        Transparency = 1
    }

    local tween = TweenService:Create(soundWave, tweenInfo, goal)
    tween:Play()

    -- ลบหลังจบ
    Debris:AddItem(soundWave, duration or 0.5)

    return soundWave
end





-- ==========================================
-- ✨ หา Enemies ในรัศมีเสียง
-- ==========================================
function SoundHelper.FindEnemiesInSoundRange(position, radius, overlapParams)
    local detectedEnemies = {}
    
    -- ใช้ GetPartBoundsInRadius หา parts ในระยะ
    local parts = workspace:GetPartBoundsInRadius(position, radius, overlapParams)
    
    -- กรอง Enemy models
    for _, part in ipairs(parts) do
        if part.Name == "HumanoidRootPart" and part.Parent then
            local model = part.Parent
            
            -- ตรวจสอบว่าเป็น Enemy (มี tag หรือ folder)
            if model:IsDescendantOf(workspace.Enemies) then
                local humanoid = model:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    table.insert(detectedEnemies, {
                        Model = model,
                        RootPart = part,
                        Humanoid = humanoid,
                        Distance = (part.Position - position).Magnitude
                    })
                end
            end
        end
    end
    
    return detectedEnemies
end

-- ==========================================
-- ✨ สร้าง OverlapParams สำหรับตรวจจับเสียง
-- ==========================================
function SoundHelper.CreateSoundOverlapParams()
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    
    -- รวมเฉพาะ Enemies folder
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        params.FilterDescendantsInstances = {enemiesFolder}
    end
    
    return params
end

-- ==========================================
-- ✨ ตรวจสอบระยะห่าง
-- ==========================================
function SoundHelper.GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

-- ==========================================
-- ✨ ตรวจสอบว่าถึงตำแหน่งแล้วหรือยัง
-- ==========================================
function SoundHelper.IsNearPosition(currentPos, targetPos, threshold)
    threshold = threshold or 5
    return SoundHelper.GetDistance(currentPos, targetPos) <= threshold
end

-- ==========================================
-- ✨ Emit Sound Wave และแจ้ง Enemies
-- ==========================================
function SoundHelper.EmitSoundWave(playerRoot, radius, duration, callback)
    if not playerRoot or not playerRoot:IsA("BasePart") then
        warn("[SoundHelper] Invalid player root")
        return {}
    end
    
    local soundOrigin = playerRoot.Position
    
    -- สร้างวงเสียง (Visual)
    SoundHelper.CreateSoundWave(soundOrigin, radius, duration)
    
    -- หา Enemies ในระยะ
    local params = SoundHelper.CreateSoundOverlapParams()
    local detectedEnemies = SoundHelper.FindEnemiesInSoundRange(soundOrigin, radius, params)
    
    -- เรียก Callback สำหรับแต่ละ Enemy
    if callback then
        for _, enemyInfo in ipairs(detectedEnemies) do
            callback(enemyInfo, soundOrigin, playerRoot.Parent)
        end
    end
    
    print("[SoundHelper] Emitted sound wave - Detected", #detectedEnemies, "enemies")
    
    return detectedEnemies
end

-- ==========================================
-- ✨ ตรวจสอบ Line of Sight (Optional)
-- ==========================================
function SoundHelper.HasLineOfSight(fromPos, toPos, ignoreList)
    local direction = (toPos - fromPos)
    local distance = direction.Magnitude
    direction = direction.Unit
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = ignoreList or {}
    
    local result = workspace:Raycast(fromPos, direction * distance, raycastParams)
    
    -- ถ้าไม่มีสิ่งกีดขวาง = มี line of sight
    return result == nil
end

return SoundHelper