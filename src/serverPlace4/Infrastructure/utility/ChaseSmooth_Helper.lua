-- ==========================================
-- Infrastructure / Helpers / ChaseSmooth_Helper.lua
-- ==========================================
-- วัตถุประสงค์: รวมฟังก์ชันช่วยเหลือสำหรับ New_PathfindingLogicService.lua
-- ไม่มี Roblox API (pure logic)
-- ==========================================




local SimpleAIConfig = require(game.ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)
local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
local New_PathfindingLogicService = require(game.ServerScriptService.ServerLocal.Application.Services.New_PathfindingLogicService)


local ChaseSmooth_Helper = {}

--function ChaseSmooth_Helper.new()
--	local instance = New_PathfindingLogicService.new()
--	return instance
--end


-- create path บน layer 3
function ChaseSmooth_Helper.CreatePath(npc, targetPos)

  return  New_PathfindingLogicService.createPath(npc,targetPos)
  -- New_PathfindingLogicService.createPath(npc,targetPos)

end


-- create path บน layer 3
function ChaseSmooth_Helper.findNearestPlayer(npc, distance)

  return  New_PathfindingLogicService.findNearestPlayer(npc,distance)
  -- New_PathfindingLogicService.createPath(npc,targetPos)

end





return ChaseSmooth_Helper