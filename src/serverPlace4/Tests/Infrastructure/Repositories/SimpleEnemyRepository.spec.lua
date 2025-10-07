return function()
	local ServerScriptService = game:GetService("ServerScriptService")

	local SimpleEnemyRepository = require(ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
	local SimpleAIConfig = require(ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)


	

	describe("SimpleEnemyRepository", function()
		local repo
		local mockModel

		beforeEach(function()
			-- สร้าง Repository ใหม่ทุกครั้ง
			 -- สร้าง Repository ใหม่ทุกครั้ง
    		repo = SimpleEnemyRepository.new()

			    -- รีเซ็ต enemy เก่าที่อาจอยู่ใน singleton
    			repo:Reset()

    			-- mock model (เพราะใน Roblox เราแค่ต้องการ object ที่มี property .Name)
    			mockModel = { Name = "MockEnemyModel" }
		end)

		it("ควรสร้าง enemy entity ใหม่และเก็บลง repo ได้", function()
			local enemyData = repo:CreateSimpleEnemy(mockModel)

			expect(enemyData).to.be.a("table")
			expect(enemyData.WalkSpeed).to.equal(SimpleAIConfig.WalkSpeed)
			expect(enemyData.IsWalking).to.equal(SimpleAIConfig.DefaultIsWalking)
			expect(enemyData.CurrentSpeed).to.equal(SimpleAIConfig.DefaultCurrentSpeed)
			expect(enemyData.CurrentState).to.equal(SimpleAIConfig.DefaultState)

			local stored = repo:GetEnemy(mockModel)
			expect(stored).to.equal(enemyData)
		end)

		it("ควรคืนค่า enemy ที่สร้างไว้เมื่อเรียก GetEnemy()", function()
			local created = repo:CreateSimpleEnemy(mockModel)
			local fetched = repo:GetEnemy(mockModel)
			expect(fetched).to.equal(created)
		end)

		it("ควรลบ enemy ออกจาก repo ได้เมื่อเรียก RemoveEnemy()", function()
			repo:CreateSimpleEnemy(mockModel)
			repo:RemoveEnemy(mockModel)

			local result = repo:GetEnemy(mockModel)
			expect(result).to.never.be.ok()
		end)

		it("ควรนับจำนวน enemy ทั้งหมดได้ถูกต้อง", function()
			local model1 = { Name = "Enemy1" }
			local model2 = { Name = "Enemy2" }

			-- สร้าง enemy
			repo:CreateSimpleEnemy(model1)
			repo:CreateSimpleEnemy(model2)

			expect(repo:GetEnemyCount()).to.equal(2)

			repo:RemoveEnemy(model1)
			expect(repo:GetEnemyCount()).to.equal(1)

			repo:RemoveEnemy(model2)
			expect(repo:GetEnemyCount()).to.equal(0)
		end)
	end)
end
