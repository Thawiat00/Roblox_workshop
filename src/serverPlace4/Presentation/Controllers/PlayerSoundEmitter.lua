-- ==========================================
-- Presentation/Controllers/PlayerSoundEmitter.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการการสร้างเสียงของ Player
-- ใช้เมื่อผู้เล่นเดิน/วิ่ง/กระโดด/ยิงปืน
-- ==========================================

local SoundHelper = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.SoundHelper)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local PlayerSoundEmitter = {}
PlayerSoundEmitter.__index = PlayerSoundEmitter

-- ==========================================
-- Constructor
-- ==========================================
function PlayerSoundEmitter.new(player, activeControllers)
    local self = setmetatable({}, PlayerSoundEmitter)
    
    self.Player = player
    self.Character = player.Character or player.CharacterAdded:Wait()
    self.Humanoid = self.Character:WaitForChild("Humanoid")
    self.RootPart = self.Character:WaitForChild("HumanoidRootPart")
    self.ActiveControllers = activeControllers
    
    self.IsActive = true
    self.LastSoundTime = 0
    self.SoundCooldown = 0.5  -- ป้องกันเสียงซ้ำบ่อยเกินไป
    
    return self
end

-- ==========================================
-- ✨ เริ่มตรวจจับการเดิน/วิ่ง
-- ==========================================
function PlayerSoundEmitter:StartMovementDetection()
    if not self.IsActive then return end
    
    -- ตรวจจับการเคลื่อนที่
    local lastPosition = self.RootPart.Position
    
    task.spawn(function()
        while self.IsActive and self.Humanoid.Health > 0 do
            
            local currentPosition = self.RootPart.Position
            local moved = (currentPosition - lastPosition).Magnitude
            
            -- ถ้าเคลื่อนที่มากกว่า 2 studs = กำลังเดิน/วิ่ง
            if moved > 2 then
                local currentTime = tick()
                
                -- ตรวจสอบ cooldown
                if currentTime - self.LastSoundTime >= self.SoundCooldown then
                    -- สร้างเสียง
                    self:EmitSound(currentPosition, "Movement")
                    self.LastSoundTime = currentTime
                end
            end
            
            lastPosition = currentPosition
            task.wait(0.3) -- เช็คทุก 0.3 วินาที
        end
    end)
    
    print("[PlayerSoundEmitter] Movement detection started for:", self.Player.Name)
end

-- ==========================================

-- ✨ สร้างเสียง

-- ==========================================
function PlayerSoundEmitter:EmitSound(position, soundType)
    if not self.IsActive then return end
    
    local radius = SimpleAIConfig.SoundRadius
    local duration = SimpleAIConfig.SoundDuration
    
    print("[PlayerSoundEmitter]", self.Player.Name, "emitted", soundType, "sound at:", position)
    
    -- สร้างวงเสียง และแจ้ง Enemies
    SoundHelper.EmitSoundWave(
        self.RootPart,
        radius,
        duration,
        function(enemyInfo, soundOrigin, playerCharacter)
            self:NotifyEnemy(enemyInfo, soundOrigin)
        end
    )
end

-- ==========================================
-- ✨ แจ้ง Enemy ที่ได้ยินเสียง
-- ==========================================
function PlayerSoundEmitter:NotifyEnemy(enemyInfo, soundPosition)
    -- หา Controller ของ Enemy
    for _, controller in ipairs(self.ActiveControllers) do
        if controller.Model == enemyInfo.Model then
            -- เรียก Callback
            controller:OnHearSound(soundPosition, self.Character)
            break
        end
    end
end

-- ==========================================

-- ✨ สร้างเสียงด้วยตนเอง (เช่น ยิงปืน)

-- ==========================================
function PlayerSoundEmitter:ManualEmitSound(soundType, customRadius)
    local currentTime = tick()
    
    -- ตรวจสอบ cooldown
    if currentTime - self.LastSoundTime < 0.1 then
        return -- เสียงบ่อยเกินไป
    end
    
    self.LastSoundTime = currentTime
    self:EmitSound(self.RootPart.Position, soundType)
end

-- ==========================================
-- ✨ หยุดการทำงาน
-- ==========================================
function PlayerSoundEmitter:Stop()
    self.IsActive = false
    print("[PlayerSoundEmitter] Stopped for:", self.Player.Name)
end

return PlayerSoundEmitter