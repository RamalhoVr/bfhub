-- LoggingManager.lua
local LoggingManager = {}
LoggingManager.__index = LoggingManager

local _logs = {}
local MAX = 500
local LEVELS = { INFO=true, WARNING=true, ERROR=true, CRITICAL=true }

function LoggingManager:Init(_deps) end

function LoggingManager:Log(message, level)
    level = (level and LEVELS[level]) and level or "INFO"
    local entry = {
        message = message, level = level,
        timestamp = os.clock(),
        time = tostring(math.floor(os.clock())),
    }
    table.insert(_logs, entry)
    if #_logs > MAX then table.remove(_logs, 1) end
end

function LoggingManager:Get(level)
    if not level then return _logs end
    local out = {}
    for _, e in ipairs(_logs) do
        if e.level == level then table.insert(out, e) end
    end
    return out
end

function LoggingManager:Clear() _logs = {} end
function LoggingManager:GetAll() return _logs end

return LoggingManager
