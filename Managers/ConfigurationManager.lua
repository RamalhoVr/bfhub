-- ConfigurationManager.lua
local ConfigurationManager = {}
ConfigurationManager.__index = ConfigurationManager

local CONFIG_FILE = "bfhub_config.json"
local _config = {}

local DEFAULTS = {
    AutoFarm    = { Enabled=false, UseSkills=true, SkillDelay=0.5, ReturnOnDeath=true, TargetLevel=0 },
    AutoBoss    = { Enabled=false, BossName="", AutoRespawn=true },
    AutoRaid    = { Enabled=false, RaidName="" },
    SeaEvents   = { Enabled=false, Priority={"Terrorshark","Sea Beast","Rumble Ship"} },
    MasteryFarm = { Enabled=false, TargetFruit="", TargetSword="", TargetGun="", StopAtMax=true },
    Teleport    = { DefaultSea="FirstSea" },
    FruitManager= { AutoEat=false, AutoStore=true, Blacklist={}, Priority={} },
    QuestManager= { Enabled=false, AutoAccept=true, AutoTurnIn=true },
    System      = { LogLevel="INFO", PauseOnDeath=true, Notify=true },
    TaskPriority= { "AutoBoss","AutoRaid","SeaEvents","MasteryFarm","AutoFarm","QuestManager" },
}

function ConfigurationManager:Init(_deps)
    self:Load()
end

function ConfigurationManager:Load()
    _config = self:_deepCopy(DEFAULTS)
    local ok, data = pcall(function()
        if readfile then
            local raw = readfile(CONFIG_FILE)
            return game:GetService("HttpService"):JSONDecode(raw)
        end
    end)
    if ok and type(data) == "table" then
        self:_merge(_config, data)
    end
end

function ConfigurationManager:Save()
    if not writefile then return end
    pcall(function()
        writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(_config))
    end)
end

function ConfigurationManager:Get(path)
    local parts = string.split(path, ".")
    local node = _config
    for _, key in ipairs(parts) do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

function ConfigurationManager:Set(path, value)
    local parts = string.split(path, ".")
    local node = _config
    for i = 1, #parts - 1 do
        local key = parts[i]
        if type(node[key]) ~= "table" then node[key] = {} end
        node = node[key]
    end
    node[parts[#parts]] = value
    self:Save()
end

function ConfigurationManager:GetSection(section)
    return _config[section]
end

function ConfigurationManager:Reset(section)
    if section then _config[section] = self:_deepCopy(DEFAULTS[section])
    else _config = self:_deepCopy(DEFAULTS) end
    self:Save()
end

function ConfigurationManager:_deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = self:_deepCopy(v) end
    return c
end

function ConfigurationManager:_merge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            self:_merge(target[k], v)
        else target[k] = v end
    end
end

return ConfigurationManager
