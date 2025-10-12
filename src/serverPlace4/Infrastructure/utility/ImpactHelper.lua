-- ==========================================
-- Infrastructure/utility/ImpactHelper.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการ Physics การกระแทก Player
-- มี Roblox API: ใช้ VectorForce, Attachment
-- ==========================================

local ImpactHelper = {}

-- ==========================================
-- ✨ Apply VectorForce ให้ Player (Replicated Physics)
-- ==========================================
function ImpactHelper.ApplyImpactForce(playerRoot, forceVector, duration, compensateGravity)
    if not playerRoot or not playerRoot:IsA("BasePart") then
        warn("[ImpactHelper] Invalid player root part")
        return false
    end
    
    -- ตรวจสอบว่ามี AssemblyMass
    if not playerRoot.AssemblyMass then
        warn("[ImpactHelper] Player root has no physics properties")
        return false
    end
    
    -- ดึง RootAttachment (หรือสร้างถ้ายังไม่มี)
    local attachment = playerRoot:FindFirstChild("RootAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "RootAttachment"
        attachment.Parent = playerRoot
        print("[ImpactHelper] Created RootAttachment")
    end
    
    -- คำนวณแรงจริง (คูณด้วย Mass)
    local mass = playerRoot.AssemblyMass
    local totalForce = forceVector * mass
    
    -- ✨ ชดเชยแรงโน้มถ่วงถ้าต้องการ (ให้แรงผลักมีผลชัดเจนขึ้น)
    if compensateGravity then
        local gravityCompensation = Vector3.new(0, workspace.Gravity * mass, 0)
        totalForce = totalForce + gravityCompensation
    end
    
    -- สร้าง VectorForce (Replicated Physics)
    local vectorForce = Instance.new("VectorForce")
    vectorForce.Name = "ImpactForce"
    vectorForce.ApplyAtCenterOfMass = true
    vectorForce.Attachment0 = attachment
    vectorForce.Force = totalForce
    vectorForce.Parent = playerRoot
    
    print("[ImpactHelper] ✅ Applied force:", totalForce, "Duration:", duration)
    
    -- ลบ VectorForce หลังครบเวลา
    task.spawn(function()
        task.wait(duration or 0.2)
        if vectorForce and vectorForce.Parent then
            vectorForce:Destroy()
            print("[ImpactHelper] 🗑️ Removed impact force")
        end
    end)
    
    return true
end

-- ==========================================
-- ✨ คำนวณแรงกระแทกที่จะส่งไปยัง Player
-- ==========================================
function ImpactHelper.CalculateImpactForce(enemyRoot, playerRoot, baseMagnitude)
    if not enemyRoot or not playerRoot then
        warn("[ImpactHelper] Cannot calculate force: missing roots")
        return nil
    end
    
    -- คำนวณทิศทาง (จาก Enemy → Player)
    local direction = (playerRoot.Position - enemyRoot.Position).Unit
    
    -- สร้าง Vector แรง
    local forceVector = direction * (baseMagnitude or 1500)
    
    return forceVector
end

-- ==========================================
-- ✨ ตรวจสอบว่า Part เป็นของ Player หรือไม่
-- ==========================================
function ImpactHelper.IsPlayerCharacter(part)
    if not part or not part.Parent then return false, nil end
    
    -- ตรวจสอบว่ามี Humanoid
    local humanoid = part.Parent:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false, nil
    end
    
    -- ตรวจสอบว่าเป็น Player จริง
    local player = game.Players:GetPlayerFromCharacter(part.Parent)
    if not player then
        return false, nil
    end
    
    return true, player
end

-- ==========================================
-- ✨ ดึง HumanoidRootPart จาก Character
-- ==========================================
function ImpactHelper.GetPlayerRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- ✨ ทำ Damage ให้ Player (ถ้าต้องการ)
-- ==========================================
function ImpactHelper.ApplyDamage(character, damage)
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    humanoid:TakeDamage(damage or 10)
    print("[ImpactHelper] 💔 Applied damage:", damage, "to", character.Name)
    return true
end

-- ==========================================
-- ✨ ตรวจสอบว่า Player มี Network Ownership หรือไม่
-- ==========================================
function ImpactHelper.CheckNetworkOwnership(playerRoot)
    if not playerRoot then return false end
    
    -- VectorForce จะทำงานได้ถูกต้องเพราะเป็น Replicated Physics
    -- แต่เราสามารถตรวจสอบ Network Owner ได้
    local success, owner = pcall(function()
        return playerRoot:GetNetworkOwner()
    end)
    
    if success then
        print("[ImpactHelper] 🌐 Network Owner:", owner and owner.Name or "Server")
        return true
    end
    
    return false
end

-- ==========================================
-- ✨ สร้าง Visual Effect (ถ้าต้องการ)
-- ==========================================
function ImpactHelper.CreateImpactEffect(position)
    -- สร้างเอฟเฟกต์เล็กๆ ที่ตำแหน่งกระแทก
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Size = Vector3.new(1, 1, 1)
    part.Position = position
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new("Bright red")
    part.Transparency = 0.5
    part.Parent = workspace
    
    -- ลบหลัง 0.3 วินาที
    game:GetService("Debris"):AddItem(part, 0.3)
    
    print("[ImpactHelper] 💥 Created impact effect at:", position)
end

return ImpactHelper