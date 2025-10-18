-- ========================================
-- 📄 StarterPlayer/StarterCharacterScripts/PlayerHealth.lua
-- ========================================
--local PlayerConfig = require(game.ReplicatedStorage.Config.PlayerConfig)
local PlayerConfig = require(game.ServerScriptService.ServerLocal.Config.PlayerConfig)

--local PlayerState = require(game.ReplicatedStorage.State.PlayerState)
local PlayerState = require(game.ServerScriptService.ServerLocal.State.PlayerState)

--local EventBus = require(game.ReplicatedStorage.Core.EventBus)
local EventBus = require (game.ServerScriptService.ServerLocal.Core.EventBus)

local player = game.Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Start
humanoid.MaxHealth = PlayerConfig.MaxHP
humanoid.Health = PlayerConfig.StartHP
humanoid.WalkSpeed = PlayerConfig.WalkSpeed

PlayerState.CurrentHP = PlayerConfig.StartHP
PlayerState.MaxHP = PlayerConfig.MaxHP
PlayerState.IsAlive = true

print("✅ PlayerHealth: Ready")

-- OnHealthChanged
humanoid.HealthChanged:Connect(function(health)
    PlayerState.CurrentHP = health
    PlayerState.IsDamaged = health < humanoid.MaxHealth
    PlayerState.LastDamageTime = tick()
    
    EventBus:Emit("PlayerDamaged", {
        currentHP = health,
        maxHP = humanoid.MaxHealth
    })
    
    if health <= 0 and PlayerState.IsAlive then
        PlayerState.IsAlive = false
        EventBus:Emit("PlayerDied", player.Name)
    end
end)