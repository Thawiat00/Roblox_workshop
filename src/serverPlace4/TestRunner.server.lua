local TestEZ = require(game.ReplicatedStorage.Common.TestEZ)
local ServerScriptService = game:GetService("ServerScriptService")
local TestsFolder = ServerScriptService.ServerLocal.Tests

print("===================================")
print("[TestRunner] 🧪 เริ่มรัน Unit Tests...")
print("===================================")

--local results = TestEZ.TestBootstrap:run({ TestsFolder })

print("===================================")
print("[TestRunner] ✅ เทสเสร็จสิ้น")
print("===================================")

--print("Passed:", results.passed)
--print("Failed:", results.failed)
