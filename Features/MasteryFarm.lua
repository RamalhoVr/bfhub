-- MasteryFarm.lua
local MasteryFarm = {}
MasteryFarm.__index = MasteryFarm

local Players = game:GetService("Players")

local TM, Nav, Combat, SM, Cfg, Log, EM

function MasteryFarm:Init(deps)
    TM     = deps.TargetManager
    Nav    = deps.NavigationManager
    Combat = deps.CombatManager
    SM     = deps.StateManager
    Cfg    = deps.ConfigurationManager
    Log    = deps.LoggingManager
    EM     = deps.EventManager
end

-- Lê maestria atual via gethiddenproperty ou property do char
function MasteryFarm:_getMastery(type_)
    local char = Players.LocalPlayer.Character
    if not char then return 0 end

    -- tenta via gethiddenproperty (executores)
    if gethiddenproperty then
        local ok, val = pcall(gethiddenproperty, Players.LocalPlayer, type_.."Mastery")
        if ok then return val or 0 end
    end

    -- fallback: procura GUI de mastery
    local gui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return 0 end

    return 0 -- sem acesso direto, retorna 0
end

function MasteryFarm:Start(task_obj)
    Log:Log("[MasteryFarm] Iniciado", "INFO")
    SM:Set("MasteryFarm", SM.States.RUNNING)

    local kills = 0

    while not task_obj.cancelled do
        if not Combat:IsAlive() then
            Combat:WaitForRespawn(30)
            task.wait(3)
        end

        -- verifica se maestria atingiu alvo
        local stopAtMax = Cfg:Get("MasteryFarm.StopAtMax")
        if stopAtMax then
            local fruitM = self:_getMastery("Fruit")
            if fruitM >= 600 then
                Log:Log("[MasteryFarm] Fruit mastery máxima atingida!", "INFO")
                EM:Fire("MasteryFarm_Max", { type = "Fruit" })
                break
            end
        end

        SM:Set("MasteryFarm", SM.States.SEARCHING)
        local enemy = TM:GetNearest(300)

        if not enemy then
            task.wait(2)
            goto continue
        end

        TM:SetTarget(enemy)
        SM:Set("MasteryFarm", SM.States.NAVIGATING)
        Nav:ApproachTarget(enemy, 20, task_obj)

        if task_obj.cancelled then break end

        SM:Set("MasteryFarm", SM.States.COMBAT)

        -- usa skills para ganhar maestria
        Combat:FightTarget(enemy, task_obj, true)

        kills = kills + 1
        if kills % 10 == 0 then
            EM:Fire("MasteryFarm_Progress", { kills = kills })
            Log:Log("[MasteryFarm] "..kills.." kills para maestria", "INFO")
        end

        TM:ClearTarget()

        ::continue::
        task.wait(0.2)
    end

    SM:Set("MasteryFarm", SM.States.IDLE)
    Log:Log("[MasteryFarm] Parado. Kills: "..tostring(0), "INFO")
end

return MasteryFarm
