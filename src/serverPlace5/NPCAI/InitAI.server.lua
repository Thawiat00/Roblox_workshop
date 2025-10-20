-- ========================================
-- 📄 ServerScriptService/NPCAI/InitAI.lua
-- ========================================
local NPCAIController = require(game.ServerScriptService.ServerLocal.NPCAI.NPCAIController)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local EventBus = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("EventBus"))



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


-- ========================================
-- 🎯 รับ Event เมื่อ NPC โจมตีปกติ
-- ========================================
EventBus.On("OnNPCAttack", function(npc, target, damage)
    print("⚔️", npc.model.Name, "attacked", target.Name, "for", damage, "damage")
end)

-- ========================================
-- 💥 รับ Event เมื่อ NPC ใช้สกิล
-- ========================================
EventBus.On("OnNPCUseSkill", function(npc, target)
    print("💥", npc.model.Name, "is using skill on", target.Name)
    
    -- ตัวอย่างการใช้งาน:
    -- เล่นแอนิเมชัน
    -- local animator = npc.humanoid:FindFirstChild("Animator")
    -- if animator then
    --     local track = animator:LoadAnimation(npc.skillAnimation)
    --     track:Play()
    -- end
    
    -- แสดง Effect พิเศษ
    -- local skillEffect = game.ReplicatedStorage.Effects.SkillEffect:Clone()
    -- skillEffect.Parent = npc.model
end)


EventBus:On("NPCAttacked", function(data)
    print("⚔️", data.npc, "attacked", data.target, "for", data.damage, "damage")
end)

-- 🔹 ฟังเหตุการณ์เมื่อผู้เล่นถูกสตัน
EventBus:On("PlayerStunned", function(data)
	print("⚡ Player stunned event received!")
	print("🧊 Target:", data.target)
	print("⏱ Duration:", data.duration, "seconds")
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

-- 🧩 รองรับการสั่นจาก EventBus (ใช้ตอน debug หรือสั่งใน client)
--EventBus:On("ShakeCamera", function(intensity, duration)
--	print("[CameraShakeClient] 🔔 EventBus Trigger Received intensity : ",intensity,"duration",duration)
	--ShakeCamera(intensity, duration)
--end)



print("✅ NPC AI System Ready")