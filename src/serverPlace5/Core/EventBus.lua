-- ========================================
-- 📄 ReplicatedStorage/Core/EventBus.lua
-- ========================================
local EventBus = {}
local events = {}

function EventBus:On(eventName, callback)
    if not events[eventName] then
        events[eventName] = {}
    end
    table.insert(events[eventName], callback)
end

function EventBus:Emit(eventName, ...)
    if events[eventName] then
        for _, callback in ipairs(events[eventName]) do
            task.spawn(callback, ...)
        end
    end
end

return EventBus
