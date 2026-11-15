-- AutoRaid.lua
local AutoRaid = {}
AutoRaid.__index = AutoRaid

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TM, Nav, Combat, SM, Cfg, Log, EM

function AutoRaid:Init(deps)
    TM     = deps.TargetManager
    Nav    = deps.NavigationManager
    Combat = deps.CombatManager
    SM     = deps.StateManager
    Cfg    = deps.ConfigurationManager
    Log    = deps.LoggingManager
    EM     = deps.EventManager
end

-- Tenta usar o chip/entrada de raid via ProximityPrompt
function AutoRaid:_enterRaid(raidName)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent and (parent.Name:lower():find("raid") or parent.Name:lower():find(raidName:lower())) then
                if fireproximityprompt then
                    fireproximityprompt(obj)
                    return true
                end
            end
        end
    end
    return false
end

function AutoRaid:_countWaveEnemies()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then count = count + 1 end
        end
    end
    return count
end

function AutoRaid:Start(task_obj)
    Log:Log("[AutoRaid] Iniciado", "INFO")
    SM:Set("AutoRaid", SM.States.RUNNING)

    local raidsCompleted = 0

    while not task_obj.cancelled do
        if not Combat:IsAlive() then
            Combat:WaitForRespawn(30)
            task.wait(3)
        end

        local raidName = Cfg:Get("AutoRaid.RaidName") or ""

        -- entra na raid
        Log:Log("[AutoRaid] Entrando na raid: "..raidName, "INFO")
        self:_enterRaid(raidName)
        task.wait(3)

        -- loop de ondas
        local wave = 1
        local maxWaves = 10
        local waveTimeout = 120

        while wave <= maxWaves and not task_obj.cancelled do
            Log:Log("[AutoRaid] Onda "..wave, "INFO")
            SM:Set("AutoRaid", SM.States.SEARCHING)

            local elapsed = 0
            while elapsed < waveTimeout and not task_obj.cancelled do
                local enemies = TM:FindEnemies(400)
                if #enemies == 0 then
                    -- onda limpa
                    break
                end

                local enemy = enemies[1]
                TM:SetTarget(enemy)
                SM:Set("AutoRaid", SM.States.COMBAT)
                Nav:ApproachTarget(enemy, 20, task_obj)
                Combat:FightTarget(enemy, task_obj, true)
                TM:ClearTarget()

                elapsed = elapsed + 0.5
                task.wait(0.1)
            end

            wave = wave + 1
            task.wait(1)
        end

        raidsCompleted = raidsCompleted + 1
        EM:Fire("AutoRaid_Complete", { count = raidsCompleted })
        Log:Log("[AutoRaid] Raid concluída! Total: "..raidsCompleted, "INFO")
        task.wait(5)
    end

    SM:Set("AutoRaid", SM.States.IDLE)
    Log:Log("[AutoRaid] Parado.", "INFO")
end

return AutoRaid
