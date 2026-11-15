-- ErrorHandler.lua
local ErrorHandler = {}
ErrorHandler.__index = ErrorHandler

ErrorHandler.Level = { WARNING = "WARNING", ERROR = "ERROR", CRITICAL = "CRITICAL" }

local _history = {}
local MAX = 200
local Log

function ErrorHandler:Init(deps)
    Log = deps.LoggingManager
end

function ErrorHandler:Report(source, msg, level)
    level = level or "ERROR"
    local entry = { source = source, message = msg, level = level, t = os.clock() }
    table.insert(_history, entry)
    if #_history > MAX then table.remove(_history, 1) end
    local line = string.format("[%s][%s] %s", level, source, msg)
    warn(line)
    if Log then Log:Log(line, level) end
end

function ErrorHandler:Try(source, fn, ...)
    local ok, r = pcall(fn, ...)
    if not ok then self:Report(source, tostring(r)); return nil end
    return r
end

function ErrorHandler:History() return _history end

return ErrorHandler
