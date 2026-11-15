-- FruitManager.lua
local FruitManager = {}
FruitManager.__index = FruitManager

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FruitDB, SM, Cfg, Log, EM
local _history = {}

function FruitManager:Init(deps)
    FruitDB = deps.FruitDatabase
    SM      = deps.StateManager
    Cfg     = deps.ConfigurationManager
    Log     = deps.LoggingManager
    EM      = deps.EventManager
end

-- Detecta frutas no chão do workspace
function FruitManager:_findGroundFruits()
    local fruits = {}
    local char = Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return fruits end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            -- frutas no BF costumam ter "Fruit" no nome ou ter BillboardGui com nome
            local billboard = obj:FindFirstChildOfClass("BillboardGui")
            if billboard then
                local label = billboard:FindFirstChildOfClass("TextLabel")
                if label and FruitDB:GetByName(label.Text) then
                    local pos = obj:IsA("Model")
                        and (obj.PrimaryPart and obj.PrimaryPart.Position or Vector3.new(0,0,0))
                        or obj.Position
                    local dist = (hrp.Position - pos).Magnitude
                    table.insert(fruits, {
                        object = obj,
                        name   = label.Text,
                        data   = FruitDB:GetByName(label.Text),
                        position = pos,
                        distance = dist,
                    })
                end
            end
        end
    end

    table.sort(fruits, function(a,b) return a.distance < b.distance end)
    return fruits
end

-- Verifica se fruta está na blacklist
function FruitManager:_isBlacklisted(fruitName)
    local bl = Cfg:Get("FruitManager.Blacklist") or {}
    for _, n in ipairs(bl) do
        if n:lower() == fruitName:lower() then return true end
    end
    return false
end

-- Come a fruta (via ProximityPrompt ou click)
function FruitManager:_eatFruit(fruitObj)
    local pp = fruitObj:FindFirstChildOfClass("ProximityPrompt")
        or (fruitObj:IsA("Model") and fruitObj:FindFirstDescendant and
            fruitObj:FindFirstChild("ProximityPrompt", true))

    if pp and fireproximityprompt then
        fireproximityprompt(pp)
        return true
    end

    -- fallback: teleporta até a fruta e tenta interagir
    local char = Players.LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local pos = fruitObj:IsA("Model")
            and (fruitObj.PrimaryPart and fruitObj.PrimaryPart.Position or Vector3.new(0,0,0))
            or fruitObj.Position
        hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,3))
        task.wait(0.5)
        if pp and fireproximityprompt then
            fireproximityprompt(pp)
            return true
        end
    end

    return false
end

function FruitManager:Start(task_obj)
    Log:Log("[FruitManager] Monitorando frutas no chão", "INFO")

    while not task_obj.cancelled do
        local autoEat   = Cfg:Get("FruitManager.AutoEat")
        local autoStore = Cfg:Get("FruitManager.AutoStore")

        if autoEat or autoStore then
            local fruits = self:_findGroundFruits()
            for _, f in ipairs(fruits) do
                if task_obj.cancelled then break end
                if not self:_isBlacklisted(f.name) then
                    if autoEat then
                        Log:Log("[FruitManager] Comendo: "..f.name, "INFO")
                        self:_eatFruit(f.object)
                        table.insert(_history, { name=f.name, action="eat", t=os.clock() })
                        EM:Fire("Fruit_Eaten", { name=f.name })
                        task.wait(1)
                    end
                end
            end
        end

        task.wait(3)
    end
end

function FruitManager:GetHistory() return _history end

return FruitManager
