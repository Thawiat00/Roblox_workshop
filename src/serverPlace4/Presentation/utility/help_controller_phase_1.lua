-- ServerScriptService/ServerLocal/Infrastructure/utility/help_controller_phase_1.lua

local HelpController = {}

function HelpController.CreateMockEnemyData()
    local enemyData = {
        CurrentSpeed = 5,
        IsWalking = function() return false end,
        SetState = function(self, state) end,
    }
    return enemyData
end

function HelpController.CreateMockWalkService()
    return {
        StartWalking = function() end,
        PauseWalk = function() end,
    }
end

return HelpController
