--[[
    ╔══════════════════════════════════════════════════════╗
    ║           BLOX FRUITS HUB  –  v1.0.0                ║
    ║   RightShift → Abrir/Fechar menu                     ║
    ║   Desenvolvido com arquitetura modular LuaU          ║
    ╚══════════════════════════════════════════════════════╝

    Como executar:
      1. Abra Roblox com Blox Fruits em execução.
      2. Injete o seu executor favorito (Synapse X, Fluxus,
         KRNL, Hydrogen, etc.).
      3. Paste este arquivo Init.lua no executor e execute.
      4. Use RightShift para abrir/fechar o menu.
--]]

-- ─── Utilitário de carregamento ───────────────────────────
-- Em executors modernos, loadstring + readfile funcionam diretamente.
-- Esta função tenta readfile (string no disco) e, se falhar,
-- usa require() convencional (caso rode dentro do Roblox Studio).

local BASE_PATH = ""  -- se necessário, altere para o caminho base dos arquivos

local function safeLoad(path)
    local fullPath = BASE_PATH .. path
    local ok, result

    -- Tenta via readfile (executor)
    if readfile then
        ok, result = pcall(readfile, fullPath)
        if ok and result and result ~= "" then
            local fn, err = loadstring(result)
            if fn then
                local ok2, mod = pcall(fn)
                if ok2 then return mod end
                error("[Init] Erro ao executar "..path..": "..tostring(mod))
            else
                error("[Init] Erro de sintaxe em "..path..": "..tostring(err))
            end
        end
    end

    -- Fallback: require (Studio / LocalScript)
    ok, result = pcall(require, script.Parent[path:gsub("/",".")])
    if ok then return result end

    -- Fallback simples: loadstring via game assets
    error("[Init] Não foi possível carregar: "..path)
end

-- ─── Carrega módulos ──────────────────────────────────────
print("[BFHub] Iniciando carregamento de módulos...")

-- Core
local EventManager      = safeLoad("Core/EventManager.lua")
local StateManager      = safeLoad("Core/StateManager.lua")
local ErrorHandler      = safeLoad("Core/ErrorHandler.lua")
local TaskManager       = safeLoad("Core/TaskManager.lua")

-- Managers
local LoggingManager      = safeLoad("Managers/LoggingManager.lua")
local ConfigurationManager= safeLoad("Managers/ConfigurationManager.lua")
local PriorityManager     = safeLoad("Managers/PriorityManager.lua")
local TargetManager       = safeLoad("Managers/TargetManager.lua")
local NavigationManager   = safeLoad("Managers/NavigationManager.lua")
local CombatManager       = safeLoad("Managers/CombatManager.lua")
local PerformanceMonitor  = safeLoad("Managers/PerformanceMonitor.lua")

-- Data
local BossDatabase        = safeLoad("Data/BossDatabase.lua")
local FruitDatabase       = safeLoad("Data/FruitDatabase.lua")
local DestinationDatabase = safeLoad("Data/DestinationDatabase.lua")
local QuestDatabase       = safeLoad("Data/QuestDatabase.lua")

-- Features
local AutoFarm      = safeLoad("Features/AutoFarm.lua")
local AutoBoss      = safeLoad("Features/AutoBoss.lua")
local AutoRaid      = safeLoad("Features/AutoRaid.lua")
local SeaEvents     = safeLoad("Features/SeaEvents.lua")
local MasteryFarm   = safeLoad("Features/MasteryFarm.lua")
local TeleportMgr   = safeLoad("Features/TeleportManager.lua")
local FruitMgr      = safeLoad("Features/FruitManager.lua")
local QuestMgr      = safeLoad("Features/QuestManager.lua")

-- SmartTaskManager
local SmartTaskManager = safeLoad("SmartTaskManager.lua")

-- UI
local UIController = safeLoad("UI/UIController.lua")

print("[BFHub] Módulos carregados. Inicializando...")

-- ─── Monta pacote de dependências ────────────────────────
local deps = {
    -- Core
    EventManager       = EventManager,
    StateManager       = StateManager,
    ErrorHandler       = ErrorHandler,
    TaskManager        = TaskManager,
    -- Managers
    LoggingManager      = LoggingManager,
    ConfigurationManager= ConfigurationManager,
    PriorityManager     = PriorityManager,
    TargetManager       = TargetManager,
    NavigationManager   = NavigationManager,
    CombatManager       = CombatManager,
    PerformanceMonitor  = PerformanceMonitor,
    -- Data
    BossDatabase        = BossDatabase,
    FruitDatabase       = FruitDatabase,
    DestinationDatabase = DestinationDatabase,
    QuestDatabase       = QuestDatabase,
    -- Features
    AutoFarm      = AutoFarm,
    AutoBoss      = AutoBoss,
    AutoRaid      = AutoRaid,
    SeaEvents     = SeaEvents,
    MasteryFarm   = MasteryFarm,
    TeleportManager = TeleportMgr,
    FruitManager  = FruitMgr,
    QuestManager  = QuestMgr,
    -- Smart
    SmartTaskManager = SmartTaskManager,
    -- UI
    UIController  = UIController,
}

-- ─── Ordem de inicialização ──────────────────────────────
-- Sempre: infra → dados → features → smart → UI

local initOrder = {
    -- Infra
    "EventManager",
    "StateManager",
    "ErrorHandler",
    "TaskManager",
    -- Managers
    "LoggingManager",
    "ConfigurationManager",
    "PriorityManager",
    "PerformanceMonitor",
    "TargetManager",
    "NavigationManager",
    "CombatManager",
    -- Data (sem Init)
    -- Features
    "AutoFarm",
    "AutoBoss",
    "AutoRaid",
    "SeaEvents",
    "MasteryFarm",
    "TeleportManager",
    "FruitManager",
    "QuestManager",
    -- Smart
    "SmartTaskManager",
    -- UI
    "UIController",
}

-- Módulos sem Init (puro dado / tabela)
local noInit = {
    BossDatabase=true, FruitDatabase=true,
    DestinationDatabase=true, QuestDatabase=true,
}

for _, name in ipairs(initOrder) do
    local mod = deps[name]
    if mod and mod.Init and not noInit[name] then
        local ok, err = pcall(function()
            mod:Init(deps)
        end)
        if not ok then
            warn("[BFHub] Falha ao inicializar "..name..": "..tostring(err))
        else
            print("[BFHub] ✓ "..name)
        end
    end
end

-- ─── Inicia SmartTaskManager ─────────────────────────────
SmartTaskManager:StartLoop()

-- ─── Registra features no SmartTaskManager ───────────────
SmartTaskManager:Register("AutoFarm", {
    priority  = 1,
    condition = function() return deps.ConfigurationManager:Get("AutoFarm.Enabled") end,
    start     = function(t) AutoFarm:Start(t) end,
})

SmartTaskManager:Register("AutoBoss", {
    priority  = 2,
    condition = function() return deps.ConfigurationManager:Get("AutoBoss.Enabled") end,
    start     = function(t) AutoBoss:Start(t) end,
})

SmartTaskManager:Register("AutoRaid", {
    priority  = 3,
    condition = function() return deps.ConfigurationManager:Get("AutoRaid.Enabled") end,
    start     = function(t) AutoRaid:Start(t) end,
})

SmartTaskManager:Register("SeaEvents", {
    priority  = 2,
    condition = function() return deps.ConfigurationManager:Get("SeaEvents.Enabled") end,
    start     = function(t) SeaEvents:Start(t) end,
})

SmartTaskManager:Register("MasteryFarm", {
    priority  = 4,
    condition = function() return deps.ConfigurationManager:Get("MasteryFarm.Enabled") end,
    start     = function(t) MasteryFarm:Start(t) end,
})

SmartTaskManager:Register("QuestManager", {
    priority  = 3,
    condition = function() return deps.ConfigurationManager:Get("QuestManager.Enabled") end,
    start     = function(t) QuestMgr:Start(t) end,
})

SmartTaskManager:Register("FruitManager", {
    priority  = 5,
    condition = function()
        local cfg = deps.ConfigurationManager
        return cfg:Get("FruitManager.AutoEat") or cfg:Get("FruitManager.AutoStore")
    end,
    start = function(t) FruitMgr:Start(t) end,
})

-- ─── Finalizado ──────────────────────────────────────────
print("╔══════════════════════════════════╗")
print("║  BF Hub v1.0.0 ativo!            ║")
print("║  RightShift → Abrir/Fechar menu  ║")
print("╚══════════════════════════════════╝")

EventManager:Fire("HubReady", { version = "1.0.0" })
