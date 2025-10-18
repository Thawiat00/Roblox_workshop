-- ========================================
-- 📄 ServerScriptService/NPCAI/InitAI.lua
-- ========================================
local NPCAIController = require(game.ServerScriptService.ServerLocal.NPCAI.NPCAIController)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

local enemyFolder = workspace:WaitForChild("puppet_enemy")

print("🤖 Initializing NPC AI System...")

-- สร้าง AI ให้ NPC ทั้งหมด
for _, model in pairs(enemyFolder:GetChildren()) do
    if model:IsA("Model") and model:FindFirstChild("Humanoid") then
        local npc, stateMachine = NPCAIController.Create(model)
        NPCAIController.Update(npc, stateMachine)
    end
end

-- ถ้ามี NPC ใหม่
enemyFolder.ChildAdded:Connect(function(child)
    task.wait(0.5)
    if child:IsA("Model") and child:FindFirstChild("Humanoid") then
        local npc, stateMachine = NPCAIController.Create(child)
        NPCAIController.Update(npc, stateMachine)
    end
end)

-- ฟัง Events
EventBus:On("NPCSpawned", function(npcName)
    print("🟢 NPC Spawned:", npcName)
end)

EventBus:On("NPCAttacked", function(data)
    print("⚔️", data.npc, "attacked", data.target, "for", data.damage, "damage")
end)

EventBus:On("NPCDied", function(npcName)
    print("💀 NPC Died:", npcName)
end)

EventBus:On("PlayerDamaged", function(data)
    print("❤️ Player HP:", data.currentHP)
end)

EventBus:On("PlayerDied", function(playerName)
    print("💀 Player Died:", playerName)
end)

-- ✅ ฟัง Event ใหม่
EventBus:On("NPCUsedSkill", function(data)
    print("✨", data.npc, "used", data.skill, "on", data.target)
end)

EventBus:On("PlayerHitBySkill", function(data)
    print("💥", data.target, "hit by", data.skill, "for", data.damage, "damage")
end)

EventBus:On("PlayerStunned", function(data)
    print("⚡", data.target, "stunned for", data.duration, "seconds")
end)




print("✅ NPC AI System Ready")