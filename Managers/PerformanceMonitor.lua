-- PerformanceMonitor.lua
local PerformanceMonitor = {}
PerformanceMonitor.__index = PerformanceMonitor

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local _fps = 0
local _mem = 0
local _ping = 0
local _frames = 0
local _elapsed = 0
local _conn = nil
local _timings = {}

function PerformanceMonitor:Init(_deps)
    _conn = RunService.Heartbeat:Connect(function(dt)
        _frames  = _frames + 1
        _elapsed = _elapsed + dt
        if _elapsed >= 1.0 then
            _fps     = math.floor(_frames / _elapsed)
            _frames  = 0
            _elapsed = 0
            _mem     = math.floor(collectgarbage("count"))
            pcall(function()
                _ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
        end
    end)
end

function PerformanceMonitor:TrackStart(name)
    _timings[name] = { start = os.clock(), samples = {} }
end

function PerformanceMonitor:TrackEnd(name)
    local t = _timings[name]
    if not t then return end
    local ms = (os.clock() - t.start) * 1000
    table.insert(t.samples, ms)
    if #t.samples > 50 then table.remove(t.samples, 1) end
    local sum = 0
    for _, v in ipairs(t.samples) do sum = sum + v end
    t.avg = sum / #t.samples
end

function PerformanceMonitor:Get()
    return { fps=_fps, memory=_mem, ping=_ping, timings=_timings }
end

function PerformanceMonitor:Shutdown()
    if _conn then _conn:Disconnect() end
end

return PerformanceMonitor
