-- PriorityManager.lua
local PriorityManager = {}
PriorityManager.__index = PriorityManager

local Cfg
local _map = {}

function PriorityManager:Init(deps)
    Cfg = deps.ConfigurationManager
    self:_build()
end

function PriorityManager:_build()
    local order = Cfg:Get("TaskPriority")
    _map = {}
    if type(order) == "table" then
        for i, name in ipairs(order) do _map[name] = i end
    end
end

function PriorityManager:Score(name, boost)
    return (_map[name] or 999) - (boost or 0)
end

function PriorityManager:Sort(names)
    table.sort(names, function(a, b) return self:Score(a) < self:Score(b) end)
    return names
end

function PriorityManager:SetOrder(newOrder)
    Cfg:Set("TaskPriority", newOrder)
    self:_build()
end

return PriorityManager
