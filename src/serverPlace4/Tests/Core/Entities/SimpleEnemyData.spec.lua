

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local SimpleEnemyData = require(ServerScriptService.ServerLocal.Core.Entities.SimpleEnemyData)
	local AIState = require(ServerScriptService.ServerLocal.Core.Enums.AIState)


	describe("SimpleEnemyData Entity", function()
		it("ควรสร้าง object เริ่มต้นได้", function()
    		local enemy = SimpleEnemyData.new()
    		expect(enemy.CurrentState).to.equal(AIState.Idle)  -- ✅ ใช้ enum
    		expect(enemy.CurrentSpeed).to.equal(0)
		end)

		


		it("ควรเปลี่ยนสถานะได้", function()
    		local enemy = SimpleEnemyData.new()
			enemy:SetState(AIState.Walk)
			expect(enemy:IsWalking()).to.equal(true)
			expect(enemy:IsIdle()).to.equal(false)
		end)


		it("ควรสร้าง object เริ่มต้นได้แม้ model เป็น nil", function()
            local enemy = SimpleEnemyData.new(nil)
            expect(enemy.CurrentState).to.equal(AIState.Idle)  -- ✅ enum
            expect(enemy.CurrentSpeed).to.equal(0)
            expect(enemy.Model).to.equal(nil)
        end)



		-- เปลี่ยนกรณีมี model ให้ชื่อไม่ซ้ำ
		it("ควรสร้าง object เริ่มต้นได้เมื่อมี model", function()
    		local DummyModel = {}  -- สร้าง dummy table แทน Model จริง
    		local enemyWithModel = SimpleEnemyData.new(DummyModel)
    		expect(enemyWithModel.CurrentState).to.equal(AIState.Idle)
    		expect(enemyWithModel.CurrentSpeed).to.equal(0)
   		 expect(enemyWithModel.Model).to.equal(DummyModel)
		end)


	end)
end
