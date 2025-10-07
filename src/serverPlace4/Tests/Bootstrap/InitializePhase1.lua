-- ServerScriptService/ServerLocal/Tests/Bootstrap/InitializePhase1.lua

local SimpleWalkController = require(game.ServerScriptService.ServerLocal.Presentation.Controllers.SimpleWalkController)

return function()
    -- สร้าง global API _G.Phase1
    _G.Phase1 = _G.Phase1 or {}
    local controllers = {}

    -- Folder สำหรับศัตรู
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return end

    for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
        -- สร้าง controller สำหรับแต่ละ enemy
        local ok, controller = pcall(function()
            return SimpleWalkController.new(enemyModel)
        end)

        if ok and controller then
            table.insert(controllers, controller)
        else
            warn("[InitializePhase1] Failed to create controller for:", enemyModel.Name, controller)
        end
    end

    -- ฟังก์ชัน API
    _G.Phase1.GetActiveCount = function()
        local count = 0
        for _, c in ipairs(controllers) do
            if c.Humanoid and c.Humanoid.Health > 0 then
                count = count + 1
            end
        end
        return count
    end

    _G.Phase1.GetControllers = function()
        return controllers
    end

    _G.Phase1.ResetAll = function()
        for _, c in ipairs(controllers) do
            if c.Reset then
                c:Reset()
            end
        end
    end
end
