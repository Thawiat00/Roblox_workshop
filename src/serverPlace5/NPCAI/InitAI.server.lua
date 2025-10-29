-- ========================================
-- 📄 ServerScriptService/NPCAI/InitAI.lua
-- ========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local NPCAIController = require(game.ServerScriptService.ServerLocal.NPCAI.NPCAIController)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)

--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local EventBus = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("EventBus"))

local RE_OnWoodThrown = ReplicatedStorage:WaitForChild("Common"):WaitForChild("RE_OnWoodThrown")


local enemyFolder = workspace:WaitForChild("puppet_enemy")

print("🤖 Initializing NPC AI System...")


-- ตารางเก็บ stateMachine ของแต่ละ NPC
local npcStateMachines = {}

-- สร้าง AI ให้ NPC ทั้งหมด
for _, model in pairs(enemyFolder:GetChildren()) do
    if model:IsA("Model") and model:FindFirstChild("Humanoid") then
        local npc, stateMachine = NPCAIController.Create(model)


		npcStateMachines[npc] = stateMachine
		NPCAIController.Update(npc, stateMachine)

      --  NPCAIController.Update(npc, stateMachine)
    end
end




-- ถ้ามี NPC ใหม่
enemyFolder.ChildAdded:Connect(function(child)
    task.wait(0.5)
    if child:IsA("Model") and child:FindFirstChild("Humanoid") then
        local npc, stateMachine = NPCAIController.Create(child)

		npcStateMachines[npc] = stateMachine

        NPCAIController.Update(npc, stateMachine)
    end
end)


-- ========================================
-- 🔥 รับ RemoteEvent จาก Client
-- ========================================
RE_OnWoodThrown.OnServerEvent:Connect(function(player, woodName, clientVelocity)
	print("[Server] 📥 รับ RE_OnWoodThrown จาก:", player.Name, "ไม้:", woodName)
	
	local woodPart = workspace:WaitForChild("wood"):FindFirstChild(woodName)
	if not woodPart then
		warn("[Server] ⚠️ ไม่เจอไม้ชื่อ:", woodName)
		return
	end
	
	-- ตรวจสอบว่า player ถือไม้ชิ้นนี้จริง (ถ้าคุณมีระบบ HeldBy)
	-- if woodPart:GetAttribute("HeldBy") ~= player.UserId then
	-- 	warn("[Server] ⚠️ Player ไม่ได้ถือไม้นี้")
	-- 	return
	-- end
	
	-- ใช้ velocity จาก client (ที่คำนวณจาก LookVector แล้ว)
	local velocity = clientVelocity
	
	print("[Server] ⚡ ใช้ Velocity จาก Client:", velocity)
	
	-- ปลดล็อค physics ของไม้
	woodPart.Anchored = false
	woodPart.CanCollide = true
	woodPart.AssemblyLinearVelocity = velocity
	
	-- 🔥 Emit ผ่าน EventBus เพื่อตรวจสอบ NPC
	print("[Server] 📢 Emit EventBus: OnWoodThrown")
	EventBus:Emit("OnWoodThrown", player, woodPart, velocity)
end)


-- ========================================
-- 🎯 ฟัง EventBus → Trigger state Hit ของ NPC
-- ========================================
EventBus:On("OnWoodThrown", function(player, wood, woodVelocity)
    print("[Server] 🔔 EventBus.OnWoodThrown ถูกเรียก! ไม้:", wood.Name)
    print("[Server] 👤 Player:", player.Name)
    
    local npcList = NPCAIController.GetAllNPCs()
    print("[Server] 🔍 จำนวน NPC ทั้งหมด:", #npcList)
    
    for i, npc in ipairs(npcList) do
        local npcPos = npc.model.PrimaryPart.Position
        local woodPos = wood.Position  -- ✅ ตอนนี้ wood คือ Part แล้ว
        local distance = (npcPos - woodPos).Magnitude
        
        print("[Server] 📏 NPC #" .. i .. " (" .. npc.model.Name .. ") - Distance:", 
              string.format("%.2f", distance), "studs")
        
        if distance < 10 then
            print("[Server] 💥 NPC โดนไม้! กำลังเปลี่ยนเป็น State Hit")
            
            local hitData = {
                Type = "ThrownObject",
                Direction = woodVelocity.Unit,
                Wood = wood,
                Velocity = woodVelocity,
            }
            
           -- npc.stateMachine:Change("Hit", hitData)
            -- ⭐⭐⭐ ใช้ Change_extra แทน Change ⭐⭐⭐
            npc.stateMachine:Change_extra("Hit", hitData)


        end
    end
end)


---

--ลองแก้แล้ว run ใหม่ดูนะครับ ต้องเห็น log:

--✅ เรียก KnockbackNPC!
--💨 Knocked back: R15 Dummy with power 50




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
	
	-- ลบ stateMachine ออกจากตาราง
	for npc, _ in pairs(npcStateMachines) do
		if npc.model.Name == npcName then
			npcStateMachines[npc] = nil
			break
		end
	end
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

