-- NavigationManager.lua
local NavigationManager = {}
NavigationManager.__index = NavigationManager

local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")

local TM -- TargetManager

function NavigationManager:Init(deps)
    TM = deps.TargetManager
end

-- Teleport direto via CFrame (método seguro para executores)
function NavigationManager:TeleportTo(position, offset)
    local char = Players.LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    offset = offset or Vector3.new(0, 3, 0)
    hrp.CFrame = CFrame.new(position + offset)
    return true
end

-- Move em direção a posição usando Humanoid:MoveTo
function NavigationManager:WalkTo(position, task_obj)
    local char = Players.LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end

    hum:MoveTo(position)

    -- aguarda chegar ou cancelar
    local timeout = 10
    local elapsed = 0
    while elapsed < timeout do
        if task_obj and task_obj.cancelled then return false end
        local dist = (hrp.Position - position).Magnitude
        if dist < 8 then return true end
        elapsed = elapsed + 0.1
        task.wait(0.1)
    end
    return false
end

-- Aproxima do alvo atual mantendo distância de combate
function NavigationManager:ApproachTarget(target, combatRange, task_obj)
    combatRange = combatRange or 15
    local hrp = target and target.root
    if not hrp then return false end

    local myChar = Players.LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end

    local dist = (myHrp.Position - hrp.Position).Magnitude
    if dist <= combatRange then return true end

    -- teleport próximo ao alvo
    return self:TeleportTo(hrp.Position, Vector3.new(0, 3, 5))
end

-- Checa se posição está acessível
function NavigationManager:CanReach(position)
    local char = Players.LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    -- distância simples — pathfinding completo causaria lag
    local dist = (hrp.Position - position).Magnitude
    return dist < 2000
end

return NavigationManager
