-- TargetManager.lua
local TargetManager = {}
TargetManager.__index = TargetManager

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")

local _currentTarget = nil
local _blacklist = {}
local Cfg, Log

function TargetManager:Init(deps)
    Cfg = deps.ConfigurationManager
    Log = deps.LoggingManager
end

-- Retorna o personagem local
function TargetManager:GetLocalChar()
    local p = Players.LocalPlayer
    return p and p.Character
end

function TargetManager:GetLocalRoot()
    local c = self:GetLocalChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

function TargetManager:GetLocalHp()
    local c = self:GetLocalChar()
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health or 0
end

-- Busca inimigos na pasta Enemies do workspace
function TargetManager:FindEnemies(maxDist)
    maxDist = maxDist or 300
    local root = self:GetLocalRoot()
    if not root then return {} end

    local enemies = {}
    local folder = Workspace:FindFirstChild("Enemies")
        or Workspace:FindFirstChild("NPC")
        or Workspace:FindFirstChild("Mobs")

    if not folder then
        -- fallback: scan workspace para modelos com Humanoid
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= Players.LocalPlayer.Character then
                local h = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if h and h.Health > 0 and hrp and not _blacklist[obj] then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist <= maxDist then
                        table.insert(enemies, { model=obj, humanoid=h, root=hrp, distance=dist })
                    end
                end
            end
        end
    else
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") then
                local h = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if h and h.Health > 0 and hrp and not _blacklist[obj] then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist <= maxDist then
                        table.insert(enemies, { model=obj, humanoid=h, root=hrp, distance=dist })
                    end
                end
            end
        end
    end

    -- ordena por distância
    table.sort(enemies, function(a, b) return a.distance < b.distance end)
    return enemies
end

-- Pega o alvo mais próximo
function TargetManager:GetNearest(maxDist)
    local list = self:FindEnemies(maxDist)
    return list[1]
end

-- Define alvo atual
function TargetManager:SetTarget(enemy)
    _currentTarget = enemy
end

function TargetManager:GetTarget()
    return _currentTarget
end

function TargetManager:ClearTarget()
    _currentTarget = nil
end

-- Verifica se alvo ainda é válido
function TargetManager:IsTargetValid()
    if not _currentTarget then return false end
    local h = _currentTarget.humanoid
    if not h or not h.Parent then return false end
    if h.Health <= 0 then return false end
    return true
end

function TargetManager:Blacklist(model)
    _blacklist[model] = true
end

function TargetManager:ClearBlacklist()
    _blacklist = {}
end

return TargetManager
