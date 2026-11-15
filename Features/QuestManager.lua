-- QuestManager.lua
local QuestManager = {}
QuestManager.__index = QuestManager

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local QuestDB, TM, Nav, Combat, SM, Cfg, Log, EM

function QuestManager:Init(deps)
    QuestDB = deps.QuestDatabase
    TM      = deps.TargetManager
    Nav     = deps.NavigationManager
    Combat  = deps.CombatManager
    SM      = deps.StateManager
    Cfg     = deps.ConfigurationManager
    Log     = deps.LoggingManager
    EM      = deps.EventManager
end

-- Pega nível do player
function QuestManager:_getLevel()
    local char = Players.LocalPlayer.Character
    if not char then return 0 end
    -- tenta via leaderstats
    local stats = Players.LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        local lvl = stats:FindFirstChild("Level") or stats:FindFirstChild("Lv")
        if lvl then return lvl.Value end
    end
    return 0
end

-- Aceita quest via ProximityPrompt no NPC
function QuestManager:_acceptQuest(quest)
    local npcPos = quest.npcPos
    local char = Players.LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- teleporta até o NPC
    hrp.CFrame = CFrame.new(npcPos + Vector3.new(0, 3, 4))
    task.wait(0.8)

    -- procura ProximityPrompt perto
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local pp_pos = obj.Parent and obj.Parent:FindFirstChild("HumanoidRootPart")
            if pp_pos then
                local dist = (hrp.Position - pp_pos.Position).Magnitude
                if dist < 15 and fireproximityprompt then
                    fireproximityprompt(obj)
                    task.wait(0.5)
                    return true
                end
            end
        end
    end
    return false
end

function QuestManager:Start(task_obj)
    Log:Log("[QuestManager] Iniciado", "INFO")
    SM:Set("QuestManager", SM.States.RUNNING)

    local questsDone = 0

    while not task_obj.cancelled do
        if not Combat:IsAlive() then
            Combat:WaitForRespawn(30)
            task.wait(3)
        end

        local level = self:_getLevel()
        local quest = QuestDB:GetByLevel(level)

        if not quest then
            Log:Log("[QuestManager] Nenhuma quest disponível para nível "..level, "WARNING")
            task.wait(10)
            goto continue
        end

        -- aceita quest
        if Cfg:Get("QuestManager.AutoAccept") then
            Log:Log("[QuestManager] Aceitando: "..quest.name, "INFO")
            self:_acceptQuest(quest)
            task.wait(1)
        end

        -- mata os inimigos da quest
        local killed = 0
        while killed < quest.count and not task_obj.cancelled do
            if not Combat:IsAlive() then
                Combat:WaitForRespawn(30)
                task.wait(3)
            end

            SM:Set("QuestManager", SM.States.SEARCHING)
            local enemies = TM:FindEnemies(400)

            -- filtra por nome do target da quest
            local target = nil
            for _, e in ipairs(enemies) do
                if e.model.Name:find(quest.target) then
                    target = e
                    break
                end
            end

            if not target then
                target = enemies[1] -- fallback: mata qualquer um
            end

            if not target then
                task.wait(2)
                goto inner_continue
            end

            TM:SetTarget(target)
            SM:Set("QuestManager", SM.States.NAVIGATING)
            Nav:ApproachTarget(target, 20, task_obj)

            if task_obj.cancelled then break end

            SM:Set("QuestManager", SM.States.COMBAT)
            local ok = Combat:FightTarget(target, task_obj, true)
            if ok then killed = killed + 1 end
            TM:ClearTarget()

            ::inner_continue::
            task.wait(0.2)
        end

        -- entrega quest
        if Cfg:Get("QuestManager.AutoTurnIn") and killed >= quest.count then
            Log:Log("[QuestManager] Entregando quest: "..quest.name, "INFO")
            self:_acceptQuest(quest) -- mesmo NPC serve para entregar
            questsDone = questsDone + 1
            EM:Fire("Quest_Done", { name=quest.name, count=questsDone })
        end

        ::continue::
        task.wait(0.5)
    end

    SM:Set("QuestManager", SM.States.IDLE)
    Log:Log("[QuestManager] Parado. Quests: "..tostring(0), "INFO")
end

return QuestManager
