-- AutoFarm.lua
local AutoFarm = {}
AutoFarm.__index = AutoFarm

local Players = game:GetService("Players")

local TM, Nav, Combat, SM, Cfg, Log, EM

function AutoFarm:Init(deps)
    TM     = deps.TargetManager
    Nav    = deps.NavigationManager
    Combat = deps.CombatManager
    SM     = deps.StateManager
    Cfg    = deps.ConfigurationManager
    Log    = deps.LoggingManager
    EM     = deps.EventManager
end

function AutoFarm:Start(task_obj)
    Log:Log("[AutoFarm] Iniciado", "INFO")
    SM:Set("AutoFarm", SM.States.RUNNING)

    local kills = 0
    local deathCount = 0

    while not task_obj.cancelled do
        -- checa vida
        if not Combat:IsAlive() then
            SM:Set("AutoFarm", SM.States.RECOVERING)
            Log:Log("[AutoFarm] Morreu — aguardando respawn", "WARNING")
            deathCount = deathCount + 1
            EM:Fire("AutoFarm_Death", { count = deathCount })

            local respawned = Combat:WaitForRespawn(30)
            if not respawned then
                Log:Log("[AutoFarm] Timeout de respawn", "ERROR")
                break
            end

            if Cfg:Get("System.PauseOnDeath") then
                task.wait(3)
            end
        end

        SM:Set("AutoFarm", SM.States.SEARCHING)

        -- busca alvo
        local enemy = TM:GetNearest(300)
        if not enemy then
            Log:Log("[AutoFarm] Nenhum inimigo encontrado, aguardando...", "INFO")
            task.wait(2)
            goto continue
        end

        TM:SetTarget(enemy)
        SM:Set("AutoFarm", SM.States.NAVIGATING)

        -- aproxima
        Nav:ApproachTarget(enemy, 20, task_obj)
        if task_obj.cancelled then break end

        SM:Set("AutoFarm", SM.States.COMBAT)

        -- combate
        local useSkills = Cfg:Get("AutoFarm.UseSkills")
        local killed = Combat:FightTarget(enemy, task_obj, useSkills)

        if killed then
            kills = kills + 1
            EM:Fire("AutoFarm_Kill", { count = kills })
            if kills % 10 == 0 then
                Log:Log("[AutoFarm] "..kills.." kills", "INFO")
            end
        end

        TM:ClearTarget()
        task.wait(Cfg:Get("AutoFarm.SkillDelay") or 0.3)

        ::continue::
    end

    SM:Set("AutoFarm", SM.States.IDLE)
    Log:Log("[AutoFarm] Parado. Kills: "..tostring(kills), "INFO")
end

return AutoFarm
