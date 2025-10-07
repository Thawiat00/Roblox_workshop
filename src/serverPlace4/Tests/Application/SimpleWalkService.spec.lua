return function()
    local AIState = require(game.ServerScriptService.ServerLocal.Core.Enums.AIState)
    local SimpleEnemyData = require(game.ServerScriptService.ServerLocal.Core.Entities.SimpleEnemyData)
    local SimpleWalkService = require(game.ServerScriptService.ServerLocal.Application.Services.SimpleWalkService)

    describe("SimpleWalkService Logic", function()
        local enemy, service

        beforeEach(function()
            -- สร้าง Enemy ใหม่และ Service ใหม่ในทุก test case
            enemy = SimpleEnemyData.new()
            service = SimpleWalkService.new(enemy)
        end)

        -- เริ่มด้วย PauseWalk
        it("PauseWalk ควรตั้งสถานะเป็น STOP และความเร็วเป็น 0", function()
            service:StartWalking() -- เริ่มเดินก่อน
            service:PauseWalk()
            expect(enemy.CurrentState).to.equal(AIState.Stop)  -- ต้องตรงกับ enum
            expect(enemy.CurrentSpeed).to.equal(0)
        end)

        it("Reset ควรกลับเป็น IDLE และความเร็ว 0", function()
            service:StartWalking() -- เริ่มเดินก่อน
            service:Reset()
            expect(enemy.CurrentState).to.equal(AIState.Idle)
            expect(enemy.CurrentSpeed).to.equal(0)
        end)

        it("StartWalking ควรตั้งสถานะเป็น WALK และมีความเร็ว > 0", function()
            service:StartWalking()
            expect(enemy.CurrentState).to.equal(AIState.Walk)
            expect(enemy.CurrentSpeed).to.equal(enemy.WalkSpeed)
        end)

        it("StopWalk ควรตั้งสถานะเป็น IDLE และความเร็วเป็น 0", function()
            service:StartWalking() -- เริ่มเดินก่อน
            service:StopWalk()
            expect(enemy.CurrentState).to.equal(AIState.Idle)
            expect(enemy.CurrentSpeed).to.equal(0)
        end)
    end)
end
