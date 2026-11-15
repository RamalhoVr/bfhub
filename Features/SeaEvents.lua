-- SeaEvents.lua
local SeaEvents = {}
SeaEvents.__index = SeaEvents

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TM, Nav, Combat, SM, Cfg, Log, EM

-- Eventos conhecidos do Blox Fruits
local EVENT_PATTERNS = {
    "Terrorshark", "Sea Beast", "Rumble Ship", "Ship of Fools",
    "Giant Shark", "Sea Monster", "Pirate Raid", "Marine Raid",
}

function SeaEvents:Init(deps)
    TM     = deps.TargetManager
    Nav    = deps.NavigationManager
    Combat = deps.CombatManager
    SM     = deps.StateManager
    Cfg    = deps.ConfigurationManager
    Log    = deps.LoggingManager
    EM     = deps.EventManager
end

-- Detecta eventos ativos no workspace
function SeaEvents:_detectEvents()
    local found = {}
    for _, pattern in ipairs(EVENT_PATTERNS) do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find(pattern) then
                local h = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if h and h.Health > 0 and hrp then
                    table.insert(found, {
                        name = pattern,
                        model = obj,
                        humanoid = h,
                        root = hrp,
                    })
                    break
                end
            end
        end
    end
    return found
end

-- Prioriza eventos conforme config
function SeaEvents:_getBestEvent(events)
    local priority = Cfg:Get("SeaEvents.Priority") or {}
    for _, pName in ipairs(priority) do
        for _, ev in ipairs(events) do
            if ev.name == pName then return ev end
        end
    end
    return events[1]
end

function SeaEvents:Start(task_obj)
    Log:Log("[SeaEvents] Iniciado — monitorando eventos", "INFO")
    SM:Set("SeaEvents", SM.States.RUNNING)

    local kills = 0

    while not task_obj.cancelled do
        if not Combat:IsAlive() then
            Combat:WaitForRespawn(30)
            task.wait(3)
        end

        SM:Set("SeaEvents", SM.States.SEARCHING)
        local events = self:_detectEvents()

        if #events == 0 then
            task.wait(5)
            goto continue
        end

        local ev = self:_getBestEvent(events)
        Log:Log("[SeaEvents] Evento detectado: "..ev.name, "INFO")
        EM:Fire("SeaEvent_Found", { name = ev.name })

        TM:SetTarget(ev)
        SM:Set("SeaEvents", SM.States.NAVIGATING)
        Nav:ApproachTarget(ev, 30, task_obj)

        if task_obj.cancelled then break end

        SM:Set("SeaEvents", SM.States.COMBAT)
        Combat:FightTarget(ev, task_obj, true)

        kills = kills + 1
        EM:Fire("SeaEvent_Kill", { name = ev.name, count = kills })
        Log:Log("[SeaEvents] "..ev.name.." derrotado!", "INFO")
        TM:ClearTarget()

        ::continue::
        task.wait(2)
    end

    SM:Set("SeaEvents", SM.States.IDLE)
    Log:Log("[SeaEvents] Parado.", "INFO")
end

return SeaEvents
