-- ==========================================
-- ServerLocal/Bootstrap/Phase1_Walk.lua (ModuleScript)
-- ==========================================
-- วัตถุประสงค์: จัดการระบบการเดินสำรวจของ AI
-- Phase 1: Walk System
-- ==========================================

local Phase1 = {}

-- ==========================================
-- Initialize: เตรียมระบบ Walk
-- ==========================================
function Phase1.Initialize(repo, config)
    print("===========================================")
    print("[AI Phase 1] 🚶 Initializing Walk System...")
    print("[AI Phase 1] • Walk Speed:", config.WalkSpeed or "N/A")
    print("[AI Phase 1] • Walk Duration:", config.WalkDuration or "N/A", "seconds")
    print("[AI Phase 1] • Idle Duration:", config.IdleDuration or "N/A", "seconds")
    print("[AI Phase 1] • Wander Radius:", config.WanderRadius or "N/A", "studs")
    print("[AI Phase 1] • Min Wander Distance:", config.MinWanderDistance or "N/A", "studs")
    print("[AI Phase 1] ✅ Walk System Ready")
    print("===========================================")
end

-- ==========================================
-- Start: เริ่มระบบ Walk สำหรับ AI ทั้งหมด
-- ==========================================
function Phase1.Start(activeControllers)
    if #activeControllers == 0 then
        warn("[AI Phase 1] ⚠️ No controllers to start")
        return 0
    end
    
    print("[AI Phase 1] 🚀 Starting Walk System...")
    local successCount = 0
    
    for _, controller in ipairs(activeControllers) do
        local success, err = pcall(function()
            -- ลองเรียก method ต่างๆ ตามลำดับความเหมาะสม
            if controller.StartWalking then
                controller:StartWalking()
                successCount = successCount + 1
                print("[AI Phase 1] ✅", controller.Model.Name, "- Walking started")
            elseif controller.Start then
                controller:Start()
                successCount = successCount + 1
                print("[AI Phase 1] ✅", controller.Model.Name, "- Started")
            elseif controller.Initialize then
                controller:Initialize()
                successCount = successCount + 1
                print("[AI Phase 1] ✅", controller.Model.Name, "- Initialized")
            else
                warn("[AI Phase 1] ⚠️", controller.Model.Name, "- No start method found")
            end
        end)
        
        if not success then
            warn("[AI Phase 1] ❌", controller.Model and controller.Model.Name or "Unknown", "- Error:", err)
        end
    end
    
    print("[AI Phase 1] 📊 Started", successCount, "/", #activeControllers, "enemies")
    return successCount
end

-- ==========================================
-- Stop: หยุดระบบ Walk
-- ==========================================
function Phase1.Stop(activeControllers)
    local count = 0
    print("[AI Phase 1] 🛑 Stopping Walk System...")
    
    for _, controller in ipairs(activeControllers) do
        pcall(function()
            if controller.PauseWalking then
                controller:PauseWalking()
                count = count + 1
            elseif controller.Stop then
                controller:Stop()
                count = count + 1
            end
        end)
    end
    
    print("[AI Phase 1] 🛑 Stopped", count, "/", #activeControllers, "enemies")
    return count
end

-- ==========================================
-- Reset: รีเซ็ตระบบ Walk
-- ==========================================
function Phase1.Reset(activeControllers)
    local count = 0
    print("[AI Phase 1] 🔄 Resetting Walk System...")
    
    for _, controller in ipairs(activeControllers) do
        pcall(function()
            if controller.Reset then
                controller:Reset()
                count = count + 1
            end
        end)
    end
    
    print("[AI Phase 1] 🔄 Reset", count, "enemies")
    return count
end

-- ==========================================
-- GetStatus: ดูสถานะระบบ Walk
-- ==========================================
function Phase1.GetStatus(activeControllers)
    local walking = 0
    local idle = 0
    local stopped = 0
    local unknown = 0
    
    for _, controller in ipairs(activeControllers) do
        if controller.EnemyData then
            if controller.EnemyData:IsWalking() then
                walking = walking + 1
            elseif controller.EnemyData:IsIdle() then
                idle = idle + 1
            elseif controller.EnemyData:IsStopped() then
                stopped = stopped + 1
            else
                unknown = unknown + 1
            end
        else
            unknown = unknown + 1
        end
    end
    
    return {
        Walking = walking,
        Idle = idle,
        Stopped = stopped,
        Unknown = unknown,
        Total = #activeControllers
    }
end

-- ==========================================
-- ShowStats: แสดงสถิติ Walk
-- ==========================================
function Phase1.ShowStats(activeControllers)
    local status = Phase1.GetStatus(activeControllers)
    
    print("===========================================")
    print("[AI Phase 1] 🚶 Walk System Statistics:")
    print("  • Walking:", status.Walking)
    print("  • Idle:", status.Idle)
    print("  • Stopped:", status.Stopped)
    if status.Unknown > 0 then
        print("  • Unknown State:", status.Unknown)
    end
    print("  • Total Enemies:", status.Total)
    print("===========================================")
end

return Phase1