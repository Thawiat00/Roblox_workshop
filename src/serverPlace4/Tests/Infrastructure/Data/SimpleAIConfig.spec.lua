-- ==========================================
-- Tests/SimpleAIConfig.spec.lua
-- ==========================================

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local SimpleAIConfig = require(ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

	describe("SimpleAIConfig", function()
		it("ควรมีค่าคอนฟิกพื้นฐานครบถ้วน", function()
			expect(SimpleAIConfig.WalkSpeed).to.be.ok()
			expect(SimpleAIConfig.WalkDuration).to.be.ok()
			expect(SimpleAIConfig.IdleDuration).to.be.ok()
			expect(SimpleAIConfig.WanderRadius).to.be.ok()
			expect(SimpleAIConfig.MinWanderDistance).to.be.ok()
			expect(SimpleAIConfig.AgentRadius).to.be.ok()
			expect(SimpleAIConfig.AgentHeight).to.be.ok()
			expect(SimpleAIConfig.AgentCanJump).to.be.ok()
		end)

		it("ควรมีค่า default ที่ถูกต้อง", function()
			expect(SimpleAIConfig.WalkSpeed).to.equal(8)
			expect(SimpleAIConfig.WalkDuration).to.equal(5)
			expect(SimpleAIConfig.IdleDuration).to.equal(3)
			expect(SimpleAIConfig.WanderRadius).to.equal(30)
			expect(SimpleAIConfig.MinWanderDistance).to.equal(10)
			expect(SimpleAIConfig.AgentRadius).to.equal(2)
			expect(SimpleAIConfig.AgentHeight).to.equal(5)
			expect(SimpleAIConfig.AgentCanJump).to.equal(true)
		end)

		it("ควรเป็น table", function()
			expect(typeof(SimpleAIConfig)).to.equal("table")
		end)
	end)
end
