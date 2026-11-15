local BASE = "https://raw.githubusercontent.com/RamalhoVr/bfhub/main/"

local function loadModule(path)
    local url = BASE .. path
    local ok, src = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or not src then
        error("[BFHub] Falha ao baixar: " .. path)
    end
    local fn, err = loadstring(src)
    if not fn then error("[BFHub] Sintaxe em " .. path .. ": " .. err) end
    local ok2, mod = pcall(fn)
    if not ok2 then error("[BFHub] Erro em " .. path .. ": " .. mod) end
    return mod
end

-- Cole abaixo o restante do conteúdo do seu Init.lua substituindo safeLoad por loadModule