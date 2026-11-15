-- SmartTaskManager.lua
local SmartTaskManager = {}
SmartTaskManager.__index = SmartTaskManager

local RunService = game:GetService("RunService")

local SM, TM_task, PM, Cfg, EM, EH
local _features = {}
local _current = nil
local _conn = nil
local _tick = 0
local RATE = 1.0

function SmartTaskManager:Init(deps)
    SM  = deps.StateManager
    TM_task = deps.TaskManager
    PM  = deps.PriorityManager
    Cfg = deps.ConfigurationManager
    EM  = deps.EventManager
    EH  = deps.ErrorHandler

    EM:On("CorePause",    function() self:_pause() end)
    EM:On("CoreResume",   function() self:_resume() end)
    EM:On("CoreShutdown", function() self:_shutdown() end)

    self:_startLoop()
end

function SmartTaskManager:Register(name, module, condition)
    table.insert(_features, {
        name = name,
        module = module,
        condition = condition or function() return true end,
    })
end

function SmartTaskManager:_startLoop()
    _conn = RunService.Heartbeat:Connect(function(dt)
        _tick = _tick + dt
        if _tick < RATE then return end
        _tick = 0
        local cs = SM:Get("Core")
        if cs == SM.States.PAUSED or cs == SM.States.SHUTDOWN then return end
        self:_evaluate()
    end)
end

function SmartTaskManager:_evaluate()
    local candidates = {}
    for _, feat in ipairs(_features) do
        local enabled = Cfg:Get(feat.name..".Enabled")
        if enabled then
            local ok, cond = pcall(feat.condition)
            if ok and cond then table.insert(candidates, feat.name) end
        end
    end

    if #candidates == 0 then
        if _current then self:_stopCurrent() end
        return
    end

    PM:Sort(candidates)
    local best = candidates[1]

    if _current == best and TM_task:IsRunning(best) then return end
    if _current and _current ~= best then self:_stopCurrent() end
    self:_start(best)
end

function SmartTaskManager:_start(name)
    local feat
    for _, f in ipairs(_features) do
        if f.name == name then feat = f; break end
    end
    if not feat then return end

    _current = name
    SM:Set(name, SM.States.RUNNING)
    EM:Fire("FeatureStarted", { name = name })

    TM_task:Run(name, function(task_obj)
        feat.module:Start(task_obj)
    end, {
        onDone = function()
            SM:Set(name, SM.States.IDLE)
            if _current == name then _current = nil end
        end,
        onError = function(err)
            SM:Set(name, SM.States.ERROR)
            if _current == name then _current = nil end
            EH:Report(name, tostring(err))
        end,
    })
end

function SmartTaskManager:_stopCurrent()
    if not _current then return end
    TM_task:CancelByName(_current)
    SM:Set(_current, SM.States.IDLE)
    EM:Fire("FeatureStopped", { name = _current })
    _current = nil
end

function SmartTaskManager:_pause()
    if _current then SM:Set(_current, SM.States.PAUSED) end
end

function SmartTaskManager:_resume()
    if _current then SM:Set(_current, SM.States.RUNNING) end
end

function SmartTaskManager:_shutdown()
    if _conn then _conn:Disconnect(); _conn = nil end
    self:_stopCurrent()
end

function SmartTaskManager:ForceStart(name)
    if _current and _current ~= name then self:_stopCurrent() end
    self:_start(name)
end

function SmartTaskManager:ForceStop(name)
    if _current == name then self:_stopCurrent() end
end

function SmartTaskManager:GetCurrent() return _current end

return SmartTaskManager
