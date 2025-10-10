local SimpleEnemyData = require(game.ServerScriptService.ServerLocal.Core.Entities.SimpleEnemyData)
local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

local HelpInfra = require(game.ServerScriptService.ServerLocal.Infrastructure.utility.help_infra_phase_1)



local SimpleEnemyRepository = {}
SimpleEnemyRepository.__index = SimpleEnemyRepository

local instance = nil

function SimpleEnemyRepository.new()
	if instance then return instance end
	local self = setmetatable({}, SimpleEnemyRepository)
	self.Enemies = {} -- table เก็บ enemy data
	instance = self
	return self
end

function SimpleEnemyRepository.GetInstance()
	if not instance then
		instance = SimpleEnemyRepository.new()
	end
	return instance
end

-- CREATE
function SimpleEnemyRepository:CreateSimpleEnemy(model)
    assert(model, "[Repository] Cannot create enemy: model is nil")

    local enemyData = SimpleEnemyData.new(model)

    -- ตั้งค่า properties ผ่าน helper
    HelpInfra.SetEnemyProperty(enemyData, "CurrentSpeed", SimpleAIConfig.DefaultCurrentSpeed)
    HelpInfra.SetEnemyProperty(enemyData, "WalkSpeed", SimpleAIConfig.WalkSpeed)
    
    HelpInfra.SetEnemyProperty(enemyData, "RunSpeed", SimpleAIConfig.RunSpeed) -- ✨ ใหม่



    -- ใช้ ForceBoolean สำหรับ IsWalking ให้เป็น boolean จริง
    HelpInfra.ForceBoolean(enemyData, "IsWalking", SimpleAIConfig.DefaultIsWalking)

    -- ตั้งค่า State
    if enemyData.SetState then
        local validState = HelpInfra.ValidateState(enemyData.CurrentState)
        enemyData:SetState(validState)
    else
        enemyData.CurrentState = HelpInfra.ValidateState(enemyData.CurrentState)
    end

    -- เพิ่ม fallback properties
    enemyData.Model = model
    enemyData.Name = model.Name or "Unknown"

    self.Enemies[model] = enemyData
    return enemyData
end


-- READ
function SimpleEnemyRepository:GetEnemy(model)
	return self.Enemies[model]
end

-- DELETE
function SimpleEnemyRepository:RemoveEnemy(model)
	self.Enemies[model] = nil
end

-- UTILITY
function SimpleEnemyRepository:GetEnemyCount()
	local count = 0
	for _ in pairs(self.Enemies) do
		count = count + 1
	end
	return count
end


function SimpleEnemyRepository:Reset()
    self.Enemies = {}
end


return SimpleEnemyRepository
