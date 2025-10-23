-- ========================================
-- 📄 ServerScriptService/NPCAI/NPCAIController.lua
-- ========================================
local RunService = game:GetService("RunService")
local StateManager = require(game.ServerScriptService.ServerLocal.Core.StateManager)
local EventBus = require(game.ServerScriptService.ServerLocal.Core.EventBus)
local TargetFinder = require(game.ServerScriptService.ServerLocal.NPCAI.Utils.TargetFinder)

-- โหลด States
local State_Idle = require(game.ServerScriptService.ServerLocal.NPCAI.NPCStates.State_Idle)
local State_Chase = require(game.ServerScriptService.ServerLocal.NPCAI.NPCStates.State_Chase)
local State_Attack = require(game.ServerScriptService.ServerLocal.NPCAI.NPCStates.State_Attack)
local State_Charge = require(game.ServerScriptService.ServerLocal.NPCAI.NPCStates.State_Charge)

local State_UseSkill = require(game.ServerScriptService.ServerLocal.NPCAI.NPCStates.State_UseSkill)  -- ✅ เพิ่ม


local State_Hit = require(game.ServerScriptService.ServerLocal.NPCAI.NPCStates.State_Hit) -- ✅ เพิ่ม



local NPCAIController = {}

-- ========================================
-- 🗂️ ตารางเก็บ NPC ทั้งหมด
-- ========================================
local allNPCs = {}


function NPCAIController.Create(model)
    -- สร้าง NPC Data
    local npc = {
        model = model,
        humanoid = model:WaitForChild("Humanoid"),
        root = model:WaitForChild("HumanoidRootPart"),
        
        -- Pathfinding
        waypoints = nil,
        waypointIndex = 1,
        pathTimer = 0,
        
        -- Combat
        attackTimer = 0,
        canCharge = true,
        chargeStartTime = nil,
        

        -- ✅ เพิ่มสำหรับสกิล
        skillCooldowns = {},
        isUsingSkill = false,
        selectedSkill = nil,
        skillUsed = false,
        skillAnimationTime = nil,



        -- ✅ เพิ่มสำหรับ Hit State
        isHit = false,
        lastHitTime = 0,



        -- Update
        deltaTime = 0,

        -- ⭐⭐⭐ เพิ่มบรรทัดนี้ ⭐⭐⭐
        stateMachine = nil,  -- จะกำหนดค่าทีหลัง

    }
    
    if not model.PrimaryPart then 
        model.PrimaryPart = npc.root 
    end
    
    -- สร้าง State Machine
    local stateMachine = StateManager.new({
        Idle = State_Idle,
        Chase = State_Chase,
        Attack = State_Attack,
        Charge = State_Charge,

        UseSkill = State_UseSkill,  -- ✅ เพิ่ม

        Hit = State_Hit,  -- ✅ เพิ่ม
    })
    
    stateMachine.data = npc
    
    -- ⭐⭐⭐ เก็บ stateMachine ไว้ใน npc ⭐⭐⭐
    npc.stateMachine = stateMachine
    
    stateMachine:Change("Idle")
    

    -- ✅ เพิ่ม NPC เข้าตาราง
    table.insert(allNPCs, npc)
    print("✅ NPC Created:", model.Name, "| Total NPCs:", #allNPCs)


    EventBus:Emit("NPCSpawned", model.Name)
    print("✅ NPC Created:", model.Name)
    
    return npc, stateMachine
end



-- ========================================
-- 🔄 Update NPC
-- ========================================
function NPCAIController.Update(npc, stateMachine)
    RunService.Heartbeat:Connect(function(deltaTime)
        if not npc.model.Parent or npc.humanoid.Health <= 0 then
           

            -- ลบ NPC ออกจากตาราง
            for i, n in ipairs(allNPCs) do
                if n == npc then
                    table.remove(allNPCs, i)
                    print("💀 NPC Removed:", npc.model.Name, "| Total NPCs:", #allNPCs)
                    break
                end
            end
            
            
            EventBus:Emit("NPCDied", npc.model.Name)
            return
        end
        
        npc.deltaTime = deltaTime
        
        -- หา Target
        local target, distance = TargetFinder.FindNearestPlayer(npc)
        
        -- Update State Machine
        stateMachine:Update(target, distance)

    end)
end


-- ========================================
-- 📋 ดึงรายชื่อ NPC ทั้งหมด
-- ========================================
function NPCAIController.GetAllNPCs()
    return allNPCs
end




-- ========================================
-- 🎯 เปลี่ยน State ของ NPC
-- ========================================
function NPCAIController.SetState(npc, stateName, data)
    if not npc or not npc.stateMachine then
        warn("⚠️ NPCAIController.SetState: NPC ไม่มี stateMachine")
        return
    end
    
    print("🔄 Changing NPC state to:", stateName)
    npc.stateMachine:Change(stateName, data)
end



return NPCAIController