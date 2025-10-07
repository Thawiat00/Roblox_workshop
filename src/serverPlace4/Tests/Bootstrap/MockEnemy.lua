-- Tests/Mocks/MockEnemy.lua
local MockEnemy = {}

function MockEnemy.new(name)
    local humanoid = {
        WalkSpeed = 0,
        Health = 100,
        MoveToFinished = { 
            Connect = function(_, fn) 
                return { Disconnect = function() end } 
            end 
        },
        ChangeState = function() end,
        MoveTo = function() end
    }

    local rootPart = { Position = Vector3.new(0,0,0) }

    local model = {
        Name = name,
        Humanoid = humanoid,
        HumanoidRootPart = rootPart,
        Parent = nil,
        IsA = function(_, className) return className == "Model" end,
        FindFirstChild = function(self, childName)
            if childName == "Humanoid" then return humanoid end
            if childName == "HumanoidRootPart" then return rootPart end
            return nil
        end,
        WaitForChild = function(self, childName)
            return self:FindFirstChild(childName)
        end
    }

    return model
end

return MockEnemy
