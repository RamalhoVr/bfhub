-- CombatManager.lua
local CombatManager = {}
CombatManager.__index = CombatManager

local Players    = game:GetService("Players")
local UserInput  = game:GetService("UserInputService")

local _skillCooldowns = {}
local Cfg, TM, Nav

function CombatManager:Init(deps)
    Cfg = deps.ConfigurationManager
    TM  = deps.TargetManager
    Nav = deps.NavigationManager
end

-- Clica com o mouse no alvo (simula clique via firetouchinterest ou click detector)
function CombatManager:ClickTarget(target)
    if not target or not target.root then return end
    -- tenta fireclickdetector se disponível
    local cd = target.model:FindFirstChildOfClass("ClickDetector")
    if cd and fireclickdetector then
        fireclickdetector(cd)
        return
    end
    -- simula M1 via click no HumanoidRootPart
    if firetouchinterest then
        local myChar = Players.LocalPlayer.Character
        local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHrp then
            firetouchinterest(myHrp, target.root, 0)
            task.wait(0.05)
            firetouchinterest(myHrp, target.root, 1)
        end
    end
end

-- Usa habilidade via KeyCode (Z, X, C, V = skills padrão BF)
function CombatManager:UseSkill(keycode)
    local now = os.clock()
    if _skillCooldowns[keycode] and now < _skillCooldowns[keycode] then return false end
    _skillCooldowns[keycode] = now + 2.0 -- cooldown padrão 2s
    -- simula keypress via VirtualUser ou keypress executor
    if keypress then
        keypress(keycode)
        task.wait(0.05)
        keyrelease(keycode)
        return true
    end
    -- fallback: UserInputService simulado
    local vus = game:GetService("VirtualUser")
    if vus then
        vus:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.05)
        vus:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        return true
    end
    return false
end

-- Usa todas as skills disponíveis com delay entre elas
function CombatManager:UseAllSkills(delay)
    delay = delay or 0.3
    -- Keys Z X C V F para skills de Blox Fruits
    local keys = {0x5A, 0x58, 0x43, 0x56, 0x46} -- Z X C V F
    for _, k in ipairs(keys) do
        self:UseSkill(k)
        task.wait(delay)
    end
end

-- Loop de combate principal — retorna quando alvo morreu ou task cancelada
function CombatManager:FightTarget(target, task_obj, useSkills)
    if not target then return false end
    local range = 20

    while TM:IsTargetValid() do
        if task_obj and task_obj.cancelled then return false end

        -- aproxima
        Nav:ApproachTarget(target, range, task_obj)

        -- ataca
        self:ClickTarget(target)

        if useSkills then
            self:UseAllSkills(0.2)
        end

        task.wait(0.1)
    end
    return true -- alvo morreu
end

-- Verifica se player está vivo
function CombatManager:IsAlive()
    local char = Players.LocalPlayer.Character
    if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 or false
end

-- Aguarda respawn
function CombatManager:WaitForRespawn(timeout)
    timeout = timeout or 30
    local elapsed = 0
    while elapsed < timeout do
        if self:IsAlive() then return true end
        elapsed = elapsed + 0.5
        task.wait(0.5)
    end
    return false
end

return CombatManager
