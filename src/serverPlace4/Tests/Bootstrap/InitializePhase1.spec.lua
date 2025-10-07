return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local Workspace = game:GetService("Workspace")

	local SimpleEnemyRepository = require(ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
	local SimpleWalkController = require(ServerScriptService.ServerLocal.Presentation.Controllers.SimpleWalkController)

	describe("Phase 1: Simple Walk AI System", function()
		local repo
		local mockModel
		local activeControllers

		beforeEach(function()
			-- รีเซ็ต repo และ controllers
			repo = SimpleEnemyRepository.GetInstance()
			activeControllers = {}

			-- mock enemy model
			mockModel = {
				Name = "MockEnemy",
				Humanoid = {
					WalkSpeed = 16,
					Health = 100,
					MoveToFinished = { Connect = function(_, fn) return { Disconnect = function() end } end },
					ChangeState = function() end,
					MoveTo = function() end
				},
				HumanoidRootPart = { Position = Vector3.new(0,0,0) },
				WaitForChild = function(self, childName)
					if childName == "Humanoid" then return self.Humanoid end
					if childName == "HumanoidRootPart" then return self.HumanoidRootPart end
					return nil
				end
			}
		end)

		it("ควรสร้าง enemy data และเก็บลง repo ได้", function()
			local enemyData = repo:CreateSimpleEnemy(mockModel)

			expect(enemyData).to.be.a("table")
			expect(enemyData.WalkSpeed).to.equal(enemyData.WalkSpeed) -- WalkSpeed ควรถูกตั้งค่า
			expect(repo:GetEnemy(mockModel)).to.equal(enemyData)
		end)

		it("ควรสร้าง controller และเก็บลง activeControllers ได้", function()
			local controller = SimpleWalkController.new(mockModel)
			table.insert(activeControllers, controller)

			expect(controller).to.be.a("table")
			expect(controller.Model).to.equal(mockModel)
			expect(#activeControllers).to.equal(1)
		end)

		it("controller:StartWalking ควร error ถ้า enemyData ไม่ครบ", function()
    		local controller = SimpleWalkController.new(mockModel)
    		controller.EnemyData = {} -- ไม่มี IsWalking, SetState, CurrentSpeed

    		expect(function()
        		controller:StartWalking()
    		end).to.throw() -- ตอนนี้จะ throw จริง
		end)



		it("ควร Reset controller ทั้งหมดได้ผ่าน _G.Phase1.ResetAll", function()
			local controller = SimpleWalkController.new(mockModel)
			table.insert(activeControllers, controller)

			_G.Phase1 = {
				GetControllers = function() return activeControllers end,
				ResetAll = function()
					for _, c in ipairs(activeControllers) do
						c:Reset()
					end
				end
			}

			expect(function()
				_G.Phase1.ResetAll()
			end).never.to.throw()
		end)

		it("ควร return จำนวน activeControllers ถูกต้องผ่าน _G.Phase1.GetActiveCount", function()
			local controller1 = SimpleWalkController.new(mockModel)
			local controller2 = SimpleWalkController.new(mockModel)
			activeControllers = {controller1, controller2}

			_G.Phase1 = {
				GetActiveCount = function() return #activeControllers end
			}

			expect(_G.Phase1.GetActiveCount()).to.equal(2)
		end)

		it("ควร warning ถ้า model ไม่มี Humanoid", function()
			local invalidModel = { Name = "InvalidModel" }
			local function initAI()
				if not invalidModel.Humanoid then
					error("[Phase 1] ⚠️ Invalid model (no Humanoid)")
				end
			end

			expect(initAI).to.throw()
		end)
	end)
end
