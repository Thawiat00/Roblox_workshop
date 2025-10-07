return function()
    -- relative path: จาก AIState.spec.lua ไป AIState.lua

    local ServerScriptService = game:GetService("ServerScriptService")
	local AIState = require(ServerScriptService.ServerLocal.Core.Enums.AIState)

    describe("AIState Enum", function()
        it("ควรมีค่าพื้นฐานครบถ้วน", function()
            expect(AIState.Idle).to.equal("Idle")
            expect(AIState.Walk).to.equal("Walk")
            expect(AIState.Stop).to.equal("Stop")
        end)
    end)
end
