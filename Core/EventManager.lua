-- EventManager.lua
-- Bus de eventos interno. Módulos se comunicam via Fire/On sem dependência direta.

local EventManager = {}
EventManager.__index = EventManager

local _handlers = {}

function EventManager:Init(_deps) end

function EventManager:On(event, callback)
    if not _handlers[event] then _handlers[event] = {} end
    local id = #_handlers[event] + 1
    _handlers[event][id] = callback
    return function()
        if _handlers[event] then _handlers[event][id] = nil end
    end
end

function EventManager:Fire(event, data)
    if not _handlers[event] then return end
    for _, cb in pairs(_handlers[event]) do
        if cb then pcall(cb, data) end
    end
end

function EventManager:Clear(event)
    _handlers[event] = nil
end

return EventManager
