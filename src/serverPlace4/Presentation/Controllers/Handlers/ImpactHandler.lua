-- ==========================================
-- Presentation/Controllers/Handlers/ImpactHandler.lua
-- ==========================================
-- วัตถุประสงค์: จัดการการชน Player (Impact & Knockback System)
-- รวบรวม Impact Logic ทั้งหมดไว้ที่นี่
-- ==========================================

local ImpactHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.ImpactHelper)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local ImpactHandler = {}
ImpactHandler.__index = ImpactHandler

-- ==========================================
-- Constructor
-- ==========================================
function ImpactHandler.new(controller)
    local self = setmetatable({}, ImpactHandler)
    
    self.Controller = controller
    self.EnemyData = controller.EnemyData
    self.RootPart = controller.RootPart
    
    self.ImpactForceMagnitude = controller.ImpactForceMagnitude
    self.ImpactDuration = controller.ImpactDuration
    self.ImpactDamage = controller.ImpactDamage
    self.ImpactVisualEffect = controller.ImpactVisualEffect
    
    -- เก็บรายชื่อ Player ที่ชนแล้ว (ป้องกันชนซ้ำ)
    self.ImpactedPlayers = {}
    
    -- Setup Touch Connection
    self.TouchConnection = nil
    
    return self
end

-- ==========================================
-- ✨ Setup Impact Detection (Touched Event)
-- ==========================================
function ImpactHandler:SetupImpactDetection()
    -- เชื่อม Touched event กับ RootPart
    self.TouchConnection = self.RootPart.Touched:Connect(function(hit)
        self:OnTouched(hit)
    end)
    
    print("[ImpactHandler] ✅ Impact detection setup complete")
end

-- ==========================================
-- ✨ Callback: เมื่อ RootPart ชนอะไรบางอย่าง
-- ==========================================
function ImpactHandler:OnTouched(hit)
    -- ตรวจสอบว่ากำลัง Dash อยู่หรือไม่
    if not self.Controller.DashService:IsDashing() then
        return
    end
    
    -- ตรวจสอบว่าเป็น Player หรือไม่
    local isPlayer, player = ImpactHelper.IsPlayerCharacter(hit)
    if not isPlayer then
        return
    end
    
    -- ตรวจสอบว่าเคยชน Player นี้แล้วหรือยัง
    if self:HasImpactedPlayer(player) then
        return -- เคยชนแล้ว ไม่ต้องชนซ้ำ
    end
    
    -- ดึง HumanoidRootPart ของ Player
    local playerRoot = ImpactHelper.GetPlayerRootPart(hit.Parent)
    if not playerRoot then
        return
    end
    
    -- ✅ เรียก Impact Callback
    self.Controller.DashService:OnDashHit(hit.Parent, function(target, player, playerRoot)
        return self:HandlePlayerImpact(target, player, playerRoot)
    end)
end

-- ==========================================
-- ✨ จัดการการกระแทก Player
-- ==========================================
function ImpactHandler:HandlePlayerImpact(target, player, playerRoot)
    if not playerRoot or not self.RootPart then
        warn("[ImpactHandler] Cannot handle impact: missing root parts")
        return false
    end
    
    -- คำนวณแรงกระแทก
    local forceVector = ImpactHelper.CalculateImpactForce(
        self.RootPart,
        playerRoot,
        self.ImpactForceMagnitude
    )
    
    if not forceVector then
        warn("[ImpactHandler] Failed to calculate impact force")
        return false
    end
    
    -- ✅ Apply VectorForce ให้ Player
    local success = ImpactHelper.ApplyImpactForce(
        playerRoot,
        forceVector,
        self.ImpactDuration,
        SimpleAIConfig.ImpactGravityCompensation
    )
    
    if success then
        print("[ImpactHandler] 💥 Impact applied to:", player.Name)
        
        -- บันทึกว่าชน Player นี้แล้ว
        self:RecordImpact(player)
        
        -- ✅ สร้าง Visual Effect (ถ้าเปิดใช้)
        if self.ImpactVisualEffect then
            ImpactHelper.CreateImpactEffect(playerRoot.Position)
        end
        
        -- ✅ Apply Damage (ถ้ามี)
        if self.ImpactDamage and self.ImpactDamage > 0 then
            self:ApplyDamage(target, self.ImpactDamage)
        end
        
        return true
    else
        warn("[ImpactHandler] Failed to apply impact force")
        return false
    end
end

-- ==========================================
-- ✨ Apply Damage ให้ Player
-- ==========================================
function ImpactHandler:ApplyDamage(target, damage)
    local humanoid = target:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:TakeDamage(damage)
        print("[ImpactHandler] ⚔️ Applied", damage, "damage to:", target.Name)
    end
end

-- ==========================================
-- ✨ บันทึกว่าชน Player แล้ว
-- ==========================================
function ImpactHandler:RecordImpact(player)
    self.ImpactedPlayers[player] = true
end

-- ==========================================
-- ✨ ตรวจสอบว่าเคยชน Player นี้แล้วหรือยัง
-- ==========================================
function ImpactHandler:HasImpactedPlayer(player)
    return self.ImpactedPlayers[player] == true
end

-- ==========================================
-- ✨ ล้างรายชื่อ Player ที่ชนแล้ว
-- ==========================================
function ImpactHandler:ClearImpactRecords()
    self.ImpactedPlayers = {}
    print("[ImpactHandler] 🧹 Impact records cleared")
end

-- ==========================================
-- ✨ ดึงจำนวน Player ที่ชนแล้ว
-- ==========================================
function ImpactHandler:GetImpactCount()
    local count = 0
    for _ in pairs(self.ImpactedPlayers) do
        count = count + 1
    end
    return count
end

-- ==========================================
-- ✨ Cleanup
-- ==========================================
function ImpactHandler:Destroy()
    if self.TouchConnection then
        self.TouchConnection:Disconnect()
        self.TouchConnection = nil
        print("[ImpactHandler] Touch connection disconnected")
    end
    
    self:ClearImpactRecords()
end

return ImpactHandler