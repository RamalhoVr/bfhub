-- AutoBoss.lua
local AutoBoss = {}
AutoBoss.__index = AutoBoss

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BossDB, TM, Nav, Combat, SM, Cfg, Log, EM

function AutoBoss:Init(deps)
    BossDB = deps.BossDatabase
    TM     = deps.TargetManager
    Nav    = deps.NavigationManager
    Combat = deps.CombatManager
    SM     = deps.StateManager
    Cfg    = deps.ConfigurationManager
    Log    = deps.LoggingManager
    EM     = deps.EventManager
end

-- Localiza o boss no workspace pelo nome
function AutoBoss:_findBoss(bossName)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(bossName) then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and hrp then
                return { model=obj, humanoid=h, root=hrp }
            end
        end
    end
    return nil
end

function AutoBoss:Start(task_obj)
    Log:Log("[AutoBoss] Iniciado", "INFO")
    SM:Set("AutoBoss", SM.States.RUNNING)

    local kills = 0

    while not task_obj.cancelled do
        if not Combat:IsAlive() then
            Combat:WaitForRespawn(30)
            task.wait(3)
        end

        local bossName = Cfg:Get("AutoBoss.BossName")
        if not bossName or bossName == "" then
            Log:Log("[AutoBoss] Nenhum boss configurado", "WARNING")
            task.wait(5)
            goto continue
        end

        local bossData = BossDB:GetByName(bossName)

        SM:Set("AutoBoss", SM.States.NAVIGATING)

        -- teleporta para posição do boss se tiver no banco
        if bossData then
            Nav:TeleportTo(bossData.position, Vector3.new(0, 5, 10))
            task.wait(1)
        end

        -- procura o boss no workspace
        SM:Set("AutoBoss", SM.States.SEARCHING)
        local boss = self:_findBoss(bossName)

        if not boss then
            Log:Log("[AutoBoss] Boss '"..bossName.."' não encontrado, aguardando spawn...", "INFO")
            -- aguarda respawn
            local waited = 0
            while not boss and waited < 120 and not task_obj.cancelled do
                task.wait(2)
                waited = waited + 2
                boss = self:_findBoss(bossName)
            end
        end

        if not boss then goto continue end

        TM:SetTarget(boss)
        SM:Set("AutoBoss", SM.States.NAVIGATING)
        Nav:ApproachTarget(boss, 25, task_obj)

        if task_obj.cancelled then break end

        SM:Set("AutoBoss", SM.States.COMBAT)
        Log:Log("[AutoBoss] Combatendo: "..bossName, "INFO")

        local useSkills = Cfg:Get("AutoFarm.UseSkills")
        Combat:FightTarget(boss, task_obj, useSkills)

        kills = kills + 1
        EM:Fire("AutoBoss_Kill", { name = bossName, count = kills })
        Log:Log("[AutoBoss] "..bossName.." derrotado! Total: "..kills, "INFO")

        TM:ClearTarget()

        -- aguarda respawn do boss se AutoRespawn ativo
        if Cfg:Get("AutoBoss.AutoRespawn") then
            local respawn = bossData and bossData.respawnTime or 300
            Log:Log("[AutoBoss] Aguardando respawn: "..respawn.."s", "INFO")
            local waited = 0
            while waited < respawn and not task_obj.cancelled do
                task.wait(5)
                waited = waited + 5
            end
        end

        ::continue::
        task.wait(0.5)
    end

    SM:Set("AutoBoss", SM.States.IDLE)
    Log:Log("[AutoBoss] Parado. Total kills: "..tostring(0), "INFO")
end

return AutoBoss
