-- ========================================
-- 📄 ReplicatedStorage/Core/StateManager.lua
-- ========================================
local StateManager = {}
StateManager.__index = StateManager

function StateManager.new(states)
    local self = setmetatable({}, StateManager)
    self.states = states
    self.current = nil
    self.data = {}
    return self
end

function StateManager:Change(stateName)
    if self.current and self.states[self.current].Exit then
        self.states[self.current].Exit(self.data)
    end
    
    self.current = stateName
    
    if self.states[stateName] and self.states[stateName].Enter then
        self.states[stateName].Enter(self.data)
    end
end

function StateManager:Update(...)
    if self.current and self.states[self.current].Update then
        local nextState = self.states[self.current].Update(self.data, ...)
        if nextState and nextState ~= self.current then
            self:Change(nextState)
        end
    end
end

return StateManager