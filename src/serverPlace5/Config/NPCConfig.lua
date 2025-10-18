
-- ========================================
-- 📄 ReplicatedStorage/Config/NPCConfig.lua
-- ========================================

return {
    Detection = {
        Range = 50,
        LoseRange = 70
    },
    
    States = {
        Idle = {
            Speed = 0
        },
        
        Chase = {
            Speed = 18,
            MinDistance = 5  -- ใกล้กว่านี้ → Attack
        },
        
        Attack = {
            Damage = 15,
            Range = 5,
            Cooldown = 1.5
        },
        
        Charge = {
            Speed = 30,
            Duration = 2,
            Cooldown = 5,
            TriggerDistance = 20  -- ไกลกว่านี้ → Charge
        }
    },
    
    Pathfinding = {
        UpdateInterval = 0.3,
        AgentRadius = 2,
        AgentHeight = 5,
        WaypointSpacing = 2,
        StopDistance = 3
    }
}