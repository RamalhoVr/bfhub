-- StateManager.lua
local StateManager = {}
StateManager.__index = StateManager

StateManager.States = {
    IDLE = "IDLE", RUNNING = "RUNNING", PAUSED = "PAUSED",
    ERROR = "ERROR", SHUTDOWN = "SHUTDOWN",
    SEARCHING = "SEARCHING", NAVIGATING = "NAVIGATING",
    COMBAT = "COMBAT", RECOVERING = "RECOVERING",
}

local _states = {}
local _listeners = {}
local EventManager

function StateManager:Init(deps)
    EventManager = deps.EventManager
end

function StateManager:Get(feature)
    return _states[feature] or StateManager.States.IDLE
end

function StateManager:Set(feature, newState)
    local prev = _states[feature]
    if prev == newState then return end
    _states[feature] = newState
    if _listeners[feature] then
        for _, cb in ipairs(_listeners[feature]) do pcall(cb, newState, prev) end
    end
    if EventManager then
        EventManager:Fire("StateChanged", { feature = feature, state = newState, prev = prev })
    end
end

function StateManager:OnChange(feature, callback)
    if not _listeners[feature] then _listeners[feature] = {} end
    table.insert(_listeners[feature], callback)
end

function StateManager:Snapshot()
    local snap = {}
    for k, v in pairs(_states) do snap[k] = v end
    return snap
end

return StateManager
