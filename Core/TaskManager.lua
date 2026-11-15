-- TaskManager.lua
local TaskManager = {}
TaskManager.__index = TaskManager

local StateManager, ErrorHandler, EventManager
local _tasks = {}
local _counter = 0

function TaskManager:Init(deps)
    StateManager = deps.StateManager
    ErrorHandler = deps.ErrorHandler
    EventManager = deps.EventManager
end

function TaskManager:Run(name, fn, options)
    options = options or {}
    _counter = _counter + 1
    local id = _counter
    local task_obj = {
        id = id, name = name,
        cancelled = false,
        startedAt = os.clock(),
        onDone = options.onDone,
        onError = options.onError,
    }
    _tasks[id] = task_obj

    task_obj.thread = coroutine.create(function()
        local ok, err = pcall(fn, task_obj)
        _tasks[id] = nil
        if not ok then
            if task_obj.onError then pcall(task_obj.onError, err) end
            if ErrorHandler then ErrorHandler:Report(name, tostring(err)) end
            if EventManager then EventManager:Fire("TaskError", { id=id, name=name, error=err }) end
        else
            if task_obj.onDone then pcall(task_obj.onDone) end
            if EventManager then EventManager:Fire("TaskDone", { id=id, name=name }) end
        end
    end)

    local ok, err = coroutine.resume(task_obj.thread)
    if not ok then
        if ErrorHandler then ErrorHandler:Report(name..":spawn", tostring(err)) end
        _tasks[id] = nil
    end
    return id
end

function TaskManager:Cancel(id)
    if _tasks[id] then
        _tasks[id].cancelled = true
        if EventManager then EventManager:Fire("TaskCancelled", { id=id, name=_tasks[id].name }) end
    end
end

function TaskManager:CancelByName(name)
    for _, t in pairs(_tasks) do
        if t.name == name then t.cancelled = true end
    end
end

function TaskManager:IsRunning(name)
    for _, t in pairs(_tasks) do
        if t.name == name and not t.cancelled then return true end
    end
    return false
end

function TaskManager:ActiveList()
    local list = {}
    for _, t in pairs(_tasks) do
        table.insert(list, { id=t.id, name=t.name, since=os.clock()-t.startedAt })
    end
    return list
end

return TaskManager
