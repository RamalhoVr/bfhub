-- CoreController.lua
local CoreController = {}
CoreController.__index = CoreController

local _deps = {}

function CoreController:Init(deps)
    _deps = deps
    local order = {
        "LoggingManager","ErrorHandler","EventManager","StateManager",
        "ConfigurationManager","TaskManager","PriorityManager","PerformanceMonitor",
        "TargetManager","NavigationManager","CombatManager","SmartTaskManager",
        "AutoFarm","AutoBoss","AutoRaid","SeaEvents",
        "MasteryFarm","TeleportManager","FruitManager","QuestManager",
        "UIController",
    }
    for _, name in ipairs(order) do
        local mod = deps[name]
        if mod and type(mod.Init) == "function" then
            local ok, err = pcall(function() mod:Init(deps) end)
            if not ok then
                warn("[CoreController] Falha: "..name.." → "..tostring(err))
            end
        end
    end
    if deps.EventManager then deps.EventManager:Fire("CoreReady", {}) end
    if deps.LoggingManager then deps.LoggingManager:Log("[CoreController] Sistema iniciado.", "INFO") end
end

function CoreController:Stop()
    _deps.EventManager:Fire("CoreShutdown", {})
    _deps.StateManager:Set("Core", _deps.StateManager.States.SHUTDOWN)
end

function CoreController:Pause()
    _deps.EventManager:Fire("CorePause", {})
    _deps.StateManager:Set("Core", _deps.StateManager.States.PAUSED)
end

function CoreController:Resume()
    _deps.EventManager:Fire("CoreResume", {})
    _deps.StateManager:Set("Core", _deps.StateManager.States.RUNNING)
end

return CoreController
