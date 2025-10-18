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

local NPCAIController = {}

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
        
        -- Update
        deltaTime = 0
    }
    
    if not model.PrimaryPart then 
        model.PrimaryPart = npc.root 
    end
    
    -- สร้าง State Machine
    local stateMachine = StateManager.new({
        Idle = State_Idle,
        Chase = State_Chase,
        Attack = State_Attack,
        Charge = State_Charge
    })
    
    stateMachine.data = npc
    stateMachine:Change("Idle")
    
    EventBus:Emit("NPCSpawned", model.Name)
    print("✅ NPC Created:", model.Name)
    
    return npc, stateMachine
end

function NPCAIController.Update(npc, stateMachine)
    RunService.Heartbeat:Connect(function(deltaTime)
        if not npc.model.Parent or npc.humanoid.Health <= 0 then
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

return NPCAIController