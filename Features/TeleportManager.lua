-- TeleportManager.lua
local TeleportManager = {}
TeleportManager.__index = TeleportManager

local Players = game:GetService("Players")

local DestDB, Nav, SM, Cfg, Log, EM

function TeleportManager:Init(deps)
    DestDB = deps.DestinationDatabase
    Nav    = deps.NavigationManager
    SM     = deps.StateManager
    Cfg    = deps.ConfigurationManager
    Log    = deps.LoggingManager
    EM     = deps.EventManager
end

-- Teleporta para destino pelo nome
function TeleportManager:GoTo(destName)
    local dest = DestDB:GetByName(destName)
    if not dest then
        Log:Log("[Teleport] Destino não encontrado: "..destName, "WARNING")
        return false
    end

    Log:Log("[Teleport] Indo para: "..destName, "INFO")
    local ok = Nav:TeleportTo(dest.position, Vector3.new(0, 5, 0))
    if ok then
        EM:Fire("Teleport_Done", { destination = destName })
    end
    return ok
end

-- Teleporta para posição direta
function TeleportManager:GoToPosition(pos)
    return Nav:TeleportTo(pos, Vector3.new(0, 5, 0))
end

-- Retorna lista de destinos por mar
function TeleportManager:GetDestinations(sea)
    if sea then return DestDB:GetBySea(sea) end
    return DestDB:GetAll()
end

-- Start não faz loop — é chamado manualmente via UI
function TeleportManager:Start(task_obj)
    -- TeleportManager não tem loop automático
    -- chamado pela UI diretamente via GoTo()
    task.wait(0.1)
end

return TeleportManager
