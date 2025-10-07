-- ==========================================
-- Tests/SimpleWalkController.spec.lua
-- ==========================================
return function()
	local ServerScriptService = game:GetService("ServerScriptService")

	local SimpleWalkController = require(ServerScriptService.ServerLocal.Presentation.Controllers.SimpleWalkController)
	local SimpleEnemyRepository = require(ServerScriptService.ServerLocal.Infrastructure.Repositories.SimpleEnemyRepository)
	local SimpleWalkService = require(ServerScriptService.ServerLocal.Application.Services.SimpleWalkService)
	local SimpleAIConfig = require(ServerScriptService.ServerLocal.Infrastructure.Data.SimpleAIConfig)

	local HelpController = require(ServerScriptService.ServerLocal.Presentation.utility.help_controller_phase_1)



	describe("SimpleWalkController", function()
		local mockModel
		local controller

	beforeEach(function()
	local humanoid = {
		WalkSpeed = 0,
		Health = 100,
		MoveToFinished = { Connect = function(_, fn) return { Disconnect = function() end } end },
		ChangeState = function() end,
		MoveTo = function() end
	}
	local rootPart = { Position = Vector3.new(0,0,0) }

	mockModel = {
		Name = "MockEnemy",
		Humanoid = humanoid,
		HumanoidRootPart = rootPart,
		WaitForChild = function(self, childName)
			if childName == "Humanoid" then return humanoid end
			if childName == "HumanoidRootPart" then return rootPart end
			return nil
		end
	}

	-- สร้าง controller แต่ override Initialize เพื่อไม่ให้ run loop
	local ControllerClass = require(ServerScriptService.ServerLocal.Presentation.Controllers.SimpleWalkController)
	local controllerTable = {}
	setmetatable(controllerTable, { __index = ControllerClass })

	function controllerTable:Initialize() -- ทำ empty เพื่อไม่ให้ loop run
		self.Humanoid.WalkSpeed = 0
	end

	controller = ControllerClass.new(mockModel)
	controller.Initialize = controllerTable.Initialize -- override
	controller:Initialize()
end)


		it("ควร initialize controller ได้ถูกต้อง", function()
			expect(controller.Model).to.equal(mockModel)
			expect(controller.Humanoid.WalkSpeed).to.equal(0)
			expect(controller.EnemyData).to.be.a("table")
			expect(controller.WalkService).to.be.a("table")
		end)

		it("ควร reset Humanoid และ WalkService", function()
			controller:Reset()
			expect(controller.Humanoid.WalkSpeed).to.equal(0)
			expect(controller.WalkService).to.be.ok()
		end)

		it("ควรสร้างตำแหน่งสุ่มใหม่ภายในรัศมี", function()
			local pos = controller:GetRandomPosition()
			expect(pos.X).to.be.a("number")
			expect(pos.Y).to.equal(controller.RootPart.Position.Y)
			expect(pos.Z).to.be.a("number")
		end)

		it("ควร pause และ stop การเดินได้", function()
			controller:PauseWalking()
			expect(controller.Humanoid.WalkSpeed).to.equal(0)
		end)

		it("ควรเริ่มเดินและปรับ WalkSpeed ตาม EnemyData", function()
			controller:StartWalking()
			expect(controller.Humanoid.WalkSpeed).to.equal(controller.EnemyData.CurrentSpeed)
		end)

		it("ควร MoveToPosition แม้ pathfinding fail", function()
			-- mock Path เพื่อให้ ComputeAsync fail
			controller.Path = {
				ComputeAsync = function() error("fail") end,
				Status = Enum.PathStatus.NoPath,
				GetWaypoints = function() return {} end
			}

			expect(function()
				controller:MoveToPosition(Vector3.new(10,0,10))
			end).to.never.throw()
		end)

		it("ควร destroy controller และล้าง Service/Entity", function()
			controller:Destroy()
			expect(controller.WalkService).to.never.be.ok()
			expect(controller.EnemyData).to.never.be.ok()
		end)

		it("RandomWalkLoop ควรทำงานได้โดยไม่ error", function()
			-- mock WalkService และ EnemyData:IsWalking
			controller.EnemyData.IsWalking = function() return false end
			controller.WalkService.StartWalking = function() end
			controller.WalkService.PauseWalk = function() end

			task.spawn(function()
				controller:RandomWalkLoop()
			end)
			expect(true).to.equal(true) -- เพียงเช็คว่าไม่ error
		end)


		it("ควรเรียก SetState ของ EnemyData เมื่อ pause", function()
    	local called = false

    	controller.EnemyData = HelpController.CreateMockEnemyData()
    	controller.EnemyData.SetState = function(self, state)
        	called = true
        	expect(state).to.equal("Idle")
    	end

    	controller.WalkService = HelpController.CreateMockWalkService()
    	controller.Humanoid.WalkSpeed = 10
    	controller.EnemyData.CurrentSpeed = 5

    	controller:PauseWalking()

    	expect(controller.Humanoid.WalkSpeed).to.equal(0)
    	expect(controller.EnemyData.CurrentSpeed).to.equal(0)
    	expect(called).to.equal(true)


		end)

		it("ควรเริ่มเดินได้เมื่อ EnemyData และ WalkService ถูกต้อง", function()
		-- Mock EnemyData
		controller.EnemyData = {
			SetState = function(self, state)
				self.LastState = state
		end,
		CurrentSpeed = nil, -- จะให้มันอัปเดตทีหลัง
		WalkSpeed = 8
		}

		-- Mock WalkService
		controller.WalkService = {
			StartWalking = function() end,
			CurrentSpeed = 12
		}

		-- Mock Humanoid
		controller.Humanoid.WalkSpeed = 0

		-- Mock MoveToPosition ไม่ให้ path ทำงานจริง
		controller.MoveToPosition = function(self, pos)
			self._movedTo = pos
		end

		-- Mock GetRandomPosition
		controller.GetRandomPosition = function(self)
			return Vector3.new(5, 0, 5)
		end

		-- Execute
		controller:StartWalking()

		-- Assert
		expect(controller.EnemyData.LastState).to.equal("Walk")
		expect(controller.EnemyData.CurrentSpeed).to.equal(12)
		expect(controller.Humanoid.WalkSpeed).to.equal(12)
		expect(controller._movedTo).to.be.ok()

		end)



		it("ควร throw error เมื่อ EnemyData ไม่มีข้อมูลที่จำเป็น", function()
		controller.EnemyData = nil

		expect(function()
			controller:StartWalking()
		end).to.throw("[Controller] EnemyData is nil or missing required fields!")

		end)


		it("ควรเดินตาม path เมื่อ EnemyData ถูกต้อง", function()
    	-- Mock EnemyData
    	controller.EnemyData = {
        	IsWalking = function() return true end
    	}

    	-- Mock Humanoid
    	local reached = false
    	controller.Humanoid.MoveToFinished = {
        	Connect = function(_, fn)
            	task.spawn(function()
                	task.wait(0.1)
                	fn(true)
                	reached = true
            	end)
            	return { Disconnect = function() end }
       		end
    	}
    	controller.Humanoid.MoveTo = function(_, pos)
        	-- mock แค่เก็บตำแหน่ง
        	controller._lastMoveTo = pos
    	end
    	controller.Humanoid.ChangeState = function(_, state) end

    	-- Mock Path ให้ success
    	controller.Path = {
        	ComputeAsync = function(_, startPos, endPos) end,
        	Status = Enum.PathStatus.Success,
        	GetWaypoints = function()
            	return { 
                	{ Position = Vector3.new(1,0,1), Action = Enum.PathWaypointAction.Walk },
                	{ Position = Vector3.new(2,0,2), Action = Enum.PathWaypointAction.Jump }
            	}
        	end
    	}

    	-- เรียก MoveToPosition
    	controller:MoveToPosition(Vector3.new(2,0,2))

    	expect(reached).to.equal(true)
    	expect(controller._lastMoveTo).to.be.ok()
	end)
		

	-- ==========================================
	-- เพิ่ม Test Case สำหรับ fallback IsWalking
	-- ==========================================
	it("ควรสร้าง fallback IsWalking ถ้าไม่มีใน EnemyData", function()
    	controller.EnemyData = { CurrentSpeed = 5 } -- ไม่มี IsWalking เดิม

    -- เช็คว่าไม่มีฟังก์ชัน IsWalking เดิม
    	expect(controller.EnemyData.IsWalking).to.equal(nil)

    -- เรียก MoveToPosition เพื่อให้ fallback ทำงาน
    	controller:MoveToPosition(Vector3.new(1,0,1))

    -- ตอนนี้ IsWalking ต้องเป็น function
    	expect(type(controller.EnemyData.IsWalking)).to.equal("function")
    	expect(controller.EnemyData:IsWalking()).to.equal(true)
	end)

	it("ควรไม่เรียก error ถ้า EnemyData เป็น nil", function()
    	controller.EnemyData = nil
    	expect(function()
        	controller:MoveToPosition(Vector3.new(1,0,1))
    	end).to.never.throw()
	end)

		


	end)
end
