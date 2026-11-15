-- UIController.lua
-- Controlador central da interface. Cria a ScreenGui principal e gerencia páginas.

local UIController = {}
UIController.__index = UIController

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")

-- Referências globais de deps
local SM, EM, Cfg, PM_mon, STM, Log

-- Paleta de cores premium dark
local THEME = {
    bg          = Color3.fromRGB(10,  10,  15),
    panel       = Color3.fromRGB(18,  18,  26),
    card        = Color3.fromRGB(24,  24,  36),
    accent      = Color3.fromRGB(99,  102, 241), -- indigo
    accentHover = Color3.fromRGB(129, 140, 248),
    success     = Color3.fromRGB(34,  197, 94),
    warning     = Color3.fromRGB(234, 179, 8),
    danger      = Color3.fromRGB(239, 68,  68),
    text        = Color3.fromRGB(240, 240, 255),
    textMuted   = Color3.fromRGB(120, 120, 150),
    border      = Color3.fromRGB(40,  40,  60),
    sidebar     = Color3.fromRGB(14,  14,  22),
    topbar      = Color3.fromRGB(14,  14,  22),
}

-- Fonte
local FONT       = Enum.Font.GothamBold
local FONT_LIGHT = Enum.Font.Gotham

local _gui = nil
local _pages = {}
local _currentPage = nil
local _dragging = false
local _dragOffset = Vector2.new(0,0)

-- ───────────────────────────────────────────────
-- Utilitários de criação de UI
-- ───────────────────────────────────────────────

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, thickness)
    make("UIStroke", {
        Color = color or THEME.border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- Botão com hover
local function makeButton(text, parent, size, pos, style)
    style = style or {}
    local bg = style.bg or THEME.accent
    local bgHover = style.bgHover or THEME.accentHover

    local btn = make("TextButton", {
        Text = text,
        Size = size or UDim2.new(1, 0, 0, 36),
        Position = pos or UDim2.new(0,0,0,0),
        BackgroundColor3 = bg,
        TextColor3 = THEME.text,
        Font = FONT,
        TextSize = 13,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, parent)
    corner(btn, 6)

    btn.MouseEnter:Connect(function()   tween(btn, { BackgroundColor3 = bgHover }) end)
    btn.MouseLeave:Connect(function()   tween(btn, { BackgroundColor3 = bg })      end)
    btn.MouseButton1Down:Connect(function() tween(btn, { BackgroundColor3 = Color3.fromRGB(79,82,221) }) end)
    btn.MouseButton1Up:Connect(function()   tween(btn, { BackgroundColor3 = bgHover }) end)

    return btn
end

-- Toggle
local function makeToggle(label, parent, yPos, default, onChange)
    local row = make("Frame", {
        Size = UDim2.new(1, -20, 0, 36),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundTransparency = 1,
    }, parent)

    make("TextLabel", {
        Text = label,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = THEME.text,
        Font = FONT_LIGHT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local track = make("Frame", {
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(1, -44, 0.5, -12),
        BackgroundColor3 = default and THEME.success or THEME.border,
    }, row)
    corner(track, 12)

    local knob = make("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = default and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = THEME.text,
    }, track)
    corner(knob, 9)

    local state = default or false

    local btn = make("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    }, track)

    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(knob, { Position = state and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) })
        tween(track, { BackgroundColor3 = state and THEME.success or THEME.border })
        if onChange then onChange(state) end
    end)

    return row, function() return state end, function(v)
        state = v
        knob.Position = v and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9)
        track.BackgroundColor3 = v and THEME.success or THEME.border
    end
end

-- Label de seção
local function sectionLabel(text, parent, yPos)
    make("TextLabel", {
        Text = text:upper(),
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundTransparency = 1,
        TextColor3 = THEME.textMuted,
        Font = FONT,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LetterSpacing = 2,
    }, parent)
end

-- Separador
local function divider(parent, yPos)
    make("Frame", {
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = THEME.border,
        BorderSizePixel = 0,
    }, parent)
end

-- Indicador de status com cor
local function statusDot(parent, state)
    local colors = {
        IDLE      = THEME.textMuted,
        RUNNING   = THEME.success,
        PAUSED    = THEME.warning,
        ERROR     = THEME.danger,
        SEARCHING = THEME.accentHover,
        NAVIGATING= THEME.accent,
        COMBAT    = THEME.danger,
        RECOVERING= THEME.warning,
        SHUTDOWN  = THEME.danger,
    }
    local dot = make("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = colors[state] or THEME.textMuted,
    }, parent)
    corner(dot, 4)
    return dot
end

-- ───────────────────────────────────────────────
-- Construção da GUI principal
-- ───────────────────────────────────────────────

function UIController:Init(deps)
    SM     = deps.StateManager
    EM     = deps.EventManager
    Cfg    = deps.ConfigurationManager
    PM_mon = deps.PerformanceMonitor
    STM    = deps.SmartTaskManager
    Log    = deps.LoggingManager

    self:_build()
    self:_setupKeybind()
    self:_startUpdater()
end

function UIController:_build()
    local player = Players.LocalPlayer
    local pGui   = player:WaitForChild("PlayerGui")

    -- Remove gui anterior se existir
    local existing = pGui:FindFirstChild("BFHub")
    if existing then existing:Destroy() end

    _gui = make("ScreenGui", {
        Name = "BFHub",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    }, pGui)

    -- ── JANELA PRINCIPAL ──
    local win = make("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 780, 0, 520),
        Position = UDim2.new(0.5, -390, 0.5, -260),
        BackgroundColor3 = THEME.bg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, _gui)
    corner(win, 12)
    stroke(win, THEME.border, 1)

    -- Topbar
    local topbar = make("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = THEME.topbar,
        BorderSizePixel = 0,
    }, win)

    make("TextLabel", {
        Text = "⚡ BF HUB",
        Size = UDim2.new(0, 160, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = THEME.text,
        Font = FONT,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, topbar)

    -- Versão
    make("TextLabel", {
        Text = "v1.0.0",
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(0, 170, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = THEME.textMuted,
        Font = FONT_LIGHT,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, topbar)

    -- Métricas no topbar
    local metricsLabel = make("TextLabel", {
        Name = "Metrics",
        Text = "FPS: -- | Ping: --ms",
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.new(0.5, -110, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = THEME.textMuted,
        Font = FONT_LIGHT,
        TextSize = 11,
    }, topbar)

    -- Botão fechar
    local closeBtn = makeButton("✕", topbar,
        UDim2.new(0, 32, 0, 28),
        UDim2.new(1, -40, 0.5, -14),
        { bg = Color3.fromRGB(50,20,20), bgHover = THEME.danger })
    closeBtn.MouseButton1Click:Connect(function()
        tween(win, { Size = UDim2.new(0, 780, 0, 0) }, 0.2)
        task.wait(0.22)
        win.Visible = false
        win.Size = UDim2.new(0, 780, 0, 520)
    end)

    -- Drag
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            _dragging = true
            _dragOffset = Vector2.new(
                input.Position.X - win.AbsolutePosition.X,
                input.Position.Y - win.AbsolutePosition.Y)
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if _dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            win.Position = UDim2.new(0,
                input.Position.X - _dragOffset.X, 0,
                input.Position.Y - _dragOffset.Y)
        end
    end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            _dragging = false
        end
    end)

    -- ── SIDEBAR ──
    local sidebar = make("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 180, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = THEME.sidebar,
        BorderSizePixel = 0,
    }, win)

    -- Linha separadora sidebar
    make("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = THEME.border,
        BorderSizePixel = 0,
    }, sidebar)

    -- ── CONTENT AREA ──
    local content = make("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -180, 1, -44),
        Position = UDim2.new(0, 180, 0, 44),
        BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, win)

    -- Guarda refs
    _gui._win = win
    _gui._sidebar = sidebar
    _gui._content = content
    _gui._metrics = metricsLabel

    -- Constrói nav + páginas
    self:_buildNav(sidebar)
    self:_buildPages(content, deps)

    -- Abre página padrão
    self:_showPage("Dashboard")
end

-- ───────────────────────────────────────────────
-- Navegação lateral
-- ───────────────────────────────────────────────

local NAV_ITEMS = {
    { label = "Dashboard",   icon = "🏠" },
    { label = "Auto Farm",   icon = "⚔️"  },
    { label = "Boss Farm",   icon = "👹" },
    { label = "Raids",       icon = "🌊" },
    { label = "Sea Events",  icon = "🦈" },
    { label = "Mastery",     icon = "✨" },
    { label = "Teleport",    icon = "🗺️"  },
    { label = "Fruits",      icon = "🍎" },
    { label = "Quests",      icon = "📋" },
    { label = "Settings",    icon = "⚙️"  },
    { label = "Logs",        icon = "📄" },
}

local _navBtns = {}

function UIController:_buildNav(sidebar)
    local listLayout = make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, sidebar)

    make("UIPadding", {
        PaddingTop    = UDim.new(0, 10),
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10),
    }, sidebar)

    for i, item in ipairs(NAV_ITEMS) do
        local btn = make("TextButton", {
            Text = item.icon .. "  " .. item.label,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = THEME.card,
            BackgroundTransparency = 1,
            TextColor3 = THEME.textMuted,
            Font = FONT_LIGHT,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = i,
            BorderSizePixel = 0,
        }, sidebar)
        corner(btn, 6)

        make("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
        }, btn)

        btn.MouseEnter:Connect(function()
            if _currentPage ~= item.label then
                tween(btn, { BackgroundTransparency = 0, BackgroundColor3 = THEME.card, TextColor3 = THEME.text })
            end
        end)
        btn.MouseLeave:Connect(function()
            if _currentPage ~= item.label then
                tween(btn, { BackgroundTransparency = 1, TextColor3 = THEME.textMuted })
            end
        end)
        btn.MouseButton1Click:Connect(function()
            self:_showPage(item.label)
        end)

        _navBtns[item.label] = btn
    end
end

function UIController:_showPage(name)
    -- esconde página atual
    if _currentPage and _pages[_currentPage] then
        _pages[_currentPage].Visible = false
        local prevBtn = _navBtns[_currentPage]
        if prevBtn then
            tween(prevBtn, { BackgroundTransparency = 1, BackgroundColor3 = THEME.card, TextColor3 = THEME.textMuted })
        end
    end

    _currentPage = name

    -- mostra nova página
    if _pages[name] then
        _pages[name].Visible = true
        _pages[name].BackgroundTransparency = 1
        tween(_pages[name], { BackgroundTransparency = 0 }, 0.1)
    end

    local btn = _navBtns[name]
    if btn then
        tween(btn, { BackgroundTransparency = 0, BackgroundColor3 = THEME.accent, TextColor3 = THEME.text })
    end
end

-- ───────────────────────────────────────────────
-- Páginas
-- ───────────────────────────────────────────────

function UIController:_buildPages(content, deps)
    -- Cria todas as páginas
    local pages = require(script.Parent.Pages)
    -- Como estamos em executor (sem módulos aninhados complexos),
    -- construímos cada página inline aqui

    self:_pageDashboard(content, deps)
    self:_pageAutoFarm(content, deps)
    self:_pageBossFarm(content, deps)
    self:_pageRaids(content, deps)
    self:_pageSeaEvents(content, deps)
    self:_pageMastery(content, deps)
    self:_pageTeleport(content, deps)
    self:_pageFruits(content, deps)
    self:_pageQuests(content, deps)
    self:_pageSettings(content, deps)
    self:_pageLogs(content, deps)
end

local function newPage(name, content)
    local p = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(18, 18, 26),
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(99, 102, 241),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ClipsDescendants = true,
    }, content)

    make("UIPadding", {
        PaddingTop    = UDim.new(0, 16),
        PaddingLeft   = UDim.new(0, 16),
        PaddingRight  = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
    }, p)

    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    }, p)

    return p
end

local function card(title, parent, order)
    local c = make("Frame", {
        Name = title,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(24, 24, 36),
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
    }, parent)
    corner(c, 8)
    stroke(c, Color3.fromRGB(40, 40, 60))

    make("UIPadding", {
        PaddingTop    = UDim.new(0, 12),
        PaddingLeft   = UDim.new(0, 14),
        PaddingRight  = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 12),
    }, c)

    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    }, c)

    if title ~= "" then
        make("TextLabel", {
            Text = title,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            TextColor3 = THEME.text,
            Font = FONT,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
        }, c)
        make("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = THEME.border,
            BorderSizePixel = 0,
            LayoutOrder = 1,
        }, c)
    end
    return c
end

-- ── DASHBOARD ──
function UIController:_pageDashboard(content, deps)
    local p = newPage("Dashboard", content)
    _pages["Dashboard"] = p

    -- Header
    make("TextLabel", {
        Text = "Dashboard",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        TextColor3 = THEME.text,
        Font = FONT,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0,
    }, p)

    -- Cards de status de features
    local statusCard = card("Status das Features", p, 1)

    local features = { "AutoFarm","AutoBoss","AutoRaid","SeaEvents","MasteryFarm","QuestManager" }
    local statusLabels = {}
    local statusDots_ = {}

    for i, name in ipairs(features) do
        local row = make("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder = i + 1,
        }, statusCard)

        local dot = make("Frame", {
            Size = UDim2.new(0, 8, 0, 8),
            Position = UDim2.new(0, 0, 0.5, -4),
            BackgroundColor3 = THEME.textMuted,
        }, row)
        corner(dot, 4)
        statusDots_[name] = dot

        make("TextLabel", {
            Text = name,
            Size = UDim2.new(0.5, -16, 1, 0),
            Position = UDim2.new(0, 16, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = THEME.text,
            Font = FONT_LIGHT,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)

        local stLbl = make("TextLabel", {
            Text = "IDLE",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = THEME.textMuted,
            Font = FONT,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, row)
        statusLabels[name] = stLbl
    end

    -- Performance card
    local perfCard = card("Performance", p, 2)
    local fpsLabel  = make("TextLabel", { Text="FPS: --",   Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, perfCard)
    local memLabel  = make("TextLabel", { Text="Memória: --", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=3 }, perfCard)
    local pingLabel = make("TextLabel", { Text="Ping: --",   Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=4 }, perfCard)

    -- Tarefa atual
    local taskCard = card("Tarefa Atual", p, 3)
    local taskLabel = make("TextLabel", { Text="Nenhuma", Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, TextColor3=THEME.accentHover, Font=FONT, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, taskCard)

    -- Atualiza em tempo real
    local stateColors = {
        IDLE="textMuted", RUNNING="success", PAUSED="warning",
        ERROR="danger", SEARCHING="accentHover", NAVIGATING="accent",
        COMBAT="danger", RECOVERING="warning", SHUTDOWN="danger",
    }

    RunService.Heartbeat:Connect(function()
        -- estados
        for _, name in ipairs(features) do
            local st = SM:Get(name)
            local dot = statusDots_[name]
            local lbl = statusLabels[name]
            local colorKey = stateColors[st] or "textMuted"
            if dot then dot.BackgroundColor3 = THEME[colorKey] end
            if lbl then lbl.Text = st; lbl.TextColor3 = THEME[colorKey] end
        end

        -- perf
        if PM_mon then
            local m = PM_mon:Get()
            fpsLabel.Text  = "FPS: "..tostring(m.fps)
            memLabel.Text  = "Memória: "..tostring(m.memory).." KB"
            pingLabel.Text = "Ping: "..tostring(math.floor(m.ping)).."ms"
            if _gui._metrics then
                _gui._metrics.Text = "FPS: "..m.fps.." | Ping: "..math.floor(m.ping).."ms"
            end
        end

        -- tarefa atual
        if STM then
            local cur = STM:GetCurrent()
            taskLabel.Text = cur or "Nenhuma"
            taskLabel.TextColor3 = cur and THEME.success or THEME.textMuted
        end
    end)
end

-- ── AUTO FARM ──
function UIController:_pageAutoFarm(content, deps)
    local p = newPage("Auto Farm", content)
    _pages["Auto Farm"] = p

    make("TextLabel", { Text="Auto Farm", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Configuração", p, 1)

    local _, getEnabled, setEnabled = makeToggle("Ativar Auto Farm", c, 0,
        Cfg:Get("AutoFarm.Enabled") or false,
        function(v)
            Cfg:Set("AutoFarm.Enabled", v)
            if v then
                deps.SmartTaskManager:ForceStart("AutoFarm")
            else
                deps.SmartTaskManager:ForceStop("AutoFarm")
            end
        end)

    local _, getSkills, setSkills = makeToggle("Usar Habilidades", c, 0,
        Cfg:Get("AutoFarm.UseSkills") or true,
        function(v) Cfg:Set("AutoFarm.UseSkills", v) end)

    local _, getPause, setPause = makeToggle("Pausar ao Morrer", c, 0,
        Cfg:Get("System.PauseOnDeath") or true,
        function(v) Cfg:Set("System.PauseOnDeath", v) end)

    local c2 = card("Estatísticas", p, 2)
    local killsLabel = make("TextLabel", { Text="Kills: 0", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c2)
    local stateLabel = make("TextLabel", { Text="Estado: IDLE", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.textMuted, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=3 }, c2)

    local kills = 0
    deps.EventManager:On("AutoFarm_Kill", function(d)
        kills = d.count
        killsLabel.Text = "Kills: "..kills
    end)

    RunService.Heartbeat:Connect(function()
        local st = SM:Get("AutoFarm")
        stateLabel.Text = "Estado: "..st
        stateLabel.TextColor3 = THEME[({ IDLE="textMuted",RUNNING="success",COMBAT="danger",SEARCHING="accentHover",NAVIGATING="accent",RECOVERING="warning",ERROR="danger" })[st] or "textMuted"]
    end)
end

-- ── BOSS FARM ──
function UIController:_pageBossFarm(content, deps)
    local p = newPage("Boss Farm", content)
    _pages["Boss Farm"] = p

    make("TextLabel", { Text="Boss Farm", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Configuração", p, 1)

    local _, getEnabled, _ = makeToggle("Ativar Auto Boss", c, 0,
        Cfg:Get("AutoBoss.Enabled") or false,
        function(v)
            Cfg:Set("AutoBoss.Enabled", v)
            if v then deps.SmartTaskManager:ForceStart("AutoBoss")
            else deps.SmartTaskManager:ForceStop("AutoBoss") end
        end)

    local _, getAutoRespawn, _ = makeToggle("Aguardar Respawn", c, 0,
        Cfg:Get("AutoBoss.AutoRespawn") or true,
        function(v) Cfg:Set("AutoBoss.AutoRespawn", v) end)

    -- Seletor de boss
    local c2 = card("Selecionar Boss", p, 2)

    make("TextLabel", { Text="Boss:", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.textMuted, Font=FONT_LIGHT, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c2)

    local bosses = deps.BossDatabase:GetAll()
    for i, boss in ipairs(bosses) do
        local btn = makeButton(boss.name.." (Lv "..boss.level..")", c2,
            UDim2.new(1, 0, 0, 32), nil,
            { bg=Color3.fromRGB(24,24,36), bgHover=THEME.accent })
        btn.LayoutOrder = i + 2
        btn.MouseButton1Click:Connect(function()
            Cfg:Set("AutoBoss.BossName", boss.name)
            -- feedback visual
            tween(btn, { BackgroundColor3 = THEME.success }, 0.1)
            task.wait(0.3)
            tween(btn, { BackgroundColor3 = Color3.fromRGB(24,24,36) }, 0.1)
        end)
    end

    -- stats
    local c3 = card("Estatísticas", p, 3)
    local bossKillLabel = make("TextLabel", { Text="Kills: 0", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c3)
    local bossSelected  = make("TextLabel", { Text="Boss: "..tostring(Cfg:Get("AutoBoss.BossName") or "Nenhum"), Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.accentHover, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=3 }, c3)

    local bkills = 0
    deps.EventManager:On("AutoBoss_Kill", function(d)
        bkills = d.count
        bossKillLabel.Text = "Kills: "..bkills
        bossSelected.Text  = "Boss: "..tostring(d.name)
    end)
end

-- ── RAIDS ──
function UIController:_pageRaids(content, deps)
    local p = newPage("Raids", content)
    _pages["Raids"] = p

    make("TextLabel", { Text="Auto Raid", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Configuração", p, 1)
    local _, _, _ = makeToggle("Ativar Auto Raid", c, 0,
        Cfg:Get("AutoRaid.Enabled") or false,
        function(v)
            Cfg:Set("AutoRaid.Enabled", v)
            if v then deps.SmartTaskManager:ForceStart("AutoRaid")
            else deps.SmartTaskManager:ForceStop("AutoRaid") end
        end)

    local c2 = card("Estatísticas", p, 2)
    local raidLabel = make("TextLabel", { Text="Raids: 0", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c2)

    deps.EventManager:On("AutoRaid_Complete", function(d)
        raidLabel.Text = "Raids concluídas: "..d.count
    end)
end

-- ── SEA EVENTS ──
function UIController:_pageSeaEvents(content, deps)
    local p = newPage("Sea Events", content)
    _pages["Sea Events"] = p

    make("TextLabel", { Text="Sea Events", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Configuração", p, 1)
    makeToggle("Ativar Sea Events", c, 0,
        Cfg:Get("SeaEvents.Enabled") or false,
        function(v)
            Cfg:Set("SeaEvents.Enabled", v)
            if v then deps.SmartTaskManager:ForceStart("SeaEvents")
            else deps.SmartTaskManager:ForceStop("SeaEvents") end
        end)

    local c2 = card("Eventos Detectados", p, 2)
    local evLabel = make("TextLabel", { Text="Nenhum evento ativo", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.textMuted, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c2)
    local evKills = make("TextLabel", { Text="Kills: 0", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=3 }, c2)

    local sk = 0
    deps.EventManager:On("SeaEvent_Found", function(d) evLabel.Text = "Evento: "..d.name; evLabel.TextColor3 = THEME.success end)
    deps.EventManager:On("SeaEvent_Kill",  function(d) sk = d.count; evKills.Text = "Kills: "..sk end)
end

-- ── MASTERY ──
function UIController:_pageMastery(content, deps)
    local p = newPage("Mastery", content)
    _pages["Mastery"] = p

    make("TextLabel", { Text="Mastery Farm", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Configuração", p, 1)
    makeToggle("Ativar Mastery Farm", c, 0,
        Cfg:Get("MasteryFarm.Enabled") or false,
        function(v)
            Cfg:Set("MasteryFarm.Enabled", v)
            if v then deps.SmartTaskManager:ForceStart("MasteryFarm")
            else deps.SmartTaskManager:ForceStop("MasteryFarm") end
        end)

    makeToggle("Parar ao Atingir Máximo", c, 0,
        Cfg:Get("MasteryFarm.StopAtMax") or true,
        function(v) Cfg:Set("MasteryFarm.StopAtMax", v) end)

    local c2 = card("Progresso", p, 2)
    local mkills = make("TextLabel", { Text="Kills para maestria: 0", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c2)

    deps.EventManager:On("MasteryFarm_Progress", function(d)
        mkills.Text = "Kills para maestria: "..d.kills
    end)
    deps.EventManager:On("MasteryFarm_Max", function(d)
        mkills.Text = d.type.." mastery MÁXIMA!"
        mkills.TextColor3 = THEME.success
    end)
end

-- ── TELEPORT ──
function UIController:_pageTeleport(content, deps)
    local p = newPage("Teleport", content)
    _pages["Teleport"] = p

    make("TextLabel", { Text="Teleport", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local seas = { "FirstSea", "SecondSea", "ThirdSea" }
    for si, sea in ipairs(seas) do
        local c = card(sea, p, si)
        local dests = deps.TeleportManager:GetDestinations(sea)
        local columns = make("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, c)

        make("UIGridLayout", {
            CellSize = UDim2.new(0.5, -4, 0, 32),
            CellPaddingX = UDim.new(0, 8),
            CellPaddingY = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, columns)

        for i, dest in ipairs(dests) do
            local btn = makeButton(dest.name, columns,
                UDim2.new(0.5, -4, 0, 32), nil,
                { bg=Color3.fromRGB(24,24,36), bgHover=THEME.accent })
            btn.LayoutOrder = i
            btn.TextSize = 11
            btn.MouseButton1Click:Connect(function()
                deps.TeleportManager:GoTo(dest.name)
                tween(btn, { BackgroundColor3 = THEME.success }, 0.1)
                task.wait(0.5)
                tween(btn, { BackgroundColor3 = Color3.fromRGB(24,24,36) }, 0.3)
            end)
        end
    end
end

-- ── FRUITS ──
function UIController:_pageFruits(content, deps)
    local p = newPage("Fruits", content)
    _pages["Fruits"] = p

    make("TextLabel", { Text="Fruit Manager", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Configuração", p, 1)
    makeToggle("Auto Comer Frutas", c, 0,
        Cfg:Get("FruitManager.AutoEat") or false,
        function(v) Cfg:Set("FruitManager.AutoEat", v) end)
    makeToggle("Auto Guardar Frutas", c, 0,
        Cfg:Get("FruitManager.AutoStore") or true,
        function(v) Cfg:Set("FruitManager.AutoStore", v) end)

    local c2 = card("Frutas por Raridade", p, 2)
    local rarities = { "Common","Uncommon","Rare","Legendary","Mythical" }
    local rarColors = {
        Common=THEME.textMuted, Uncommon=THEME.success, Rare=THEME.accent,
        Legendary=Color3.fromRGB(234,179,8), Mythical=Color3.fromRGB(217,70,239),
    }

    for i, rar in ipairs(rarities) do
        local fruits = deps.FruitDatabase:GetByRarity(rar)
        local lbl = make("TextLabel", {
            Text = rar.." ("..#fruits..")",
            Size = UDim2.new(1,0,0,20),
            BackgroundTransparency = 1,
            TextColor3 = rarColors[rar] or THEME.text,
            Font = FONT,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i + 1,
        }, c2)
    end

    local c3 = card("Histórico", p, 3)
    local histLabel = make("TextLabel", { Text="Nenhuma fruta coletada", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.textMuted, Font=FONT_LIGHT, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c3)

    deps.EventManager:On("Fruit_Eaten", function(d)
        histLabel.Text = "Última: "..d.name
        histLabel.TextColor3 = THEME.success
    end)
end

-- ── QUESTS ──
function UIController:_pageQuests(content, deps)
    local p = newPage("Quests", content)
    _pages["Quests"] = p

    make("TextLabel", { Text="Quest Manager", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Configuração", p, 1)
    makeToggle("Ativar Auto Quest", c, 0,
        Cfg:Get("QuestManager.Enabled") or false,
        function(v)
            Cfg:Set("QuestManager.Enabled", v)
            if v then deps.SmartTaskManager:ForceStart("QuestManager")
            else deps.SmartTaskManager:ForceStop("QuestManager") end
        end)
    makeToggle("Auto Aceitar Quests", c, 0,
        Cfg:Get("QuestManager.AutoAccept") or true,
        function(v) Cfg:Set("QuestManager.AutoAccept", v) end)
    makeToggle("Auto Entregar Quests", c, 0,
        Cfg:Get("QuestManager.AutoTurnIn") or true,
        function(v) Cfg:Set("QuestManager.AutoTurnIn", v) end)

    local c2 = card("Estatísticas", p, 2)
    local qdone = make("TextLabel", { Text="Quests concluídas: 0", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c2)
    local qcur  = make("TextLabel", { Text="Quest atual: --", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.accentHover, Font=FONT_LIGHT, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=3 }, c2)

    deps.EventManager:On("Quest_Done", function(d)
        qdone.Text = "Quests concluídas: "..d.count
        qcur.Text  = "Última: "..d.name
    end)
end

-- ── SETTINGS ──
function UIController:_pageSettings(content, deps)
    local p = newPage("Settings", content)
    _pages["Settings"] = p

    make("TextLabel", { Text="Configurações", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("Sistema", p, 1)
    makeToggle("Notificações", c, 0,
        Cfg:Get("System.Notify") or true,
        function(v) Cfg:Set("System.Notify", v) end)
    makeToggle("Pausar ao Morrer", c, 0,
        Cfg:Get("System.PauseOnDeath") or true,
        function(v) Cfg:Set("System.PauseOnDeath", v) end)

    -- Prioridade
    local c2 = card("Prioridade de Tarefas", p, 2)
    make("TextLabel", { Text="Arraste para reordenar (edite Config para alterar)", Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=THEME.textMuted, Font=FONT_LIGHT, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2 }, c2)

    local order = Cfg:Get("TaskPriority") or {}
    for i, name in ipairs(order) do
        make("TextLabel", {
            Text = i..". "..name,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            TextColor3 = THEME.text,
            Font = FONT_LIGHT,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i + 2,
        }, c2)
    end

    -- Reset
    local c3 = card("Reset", p, 3)
    local resetBtn = makeButton("⚠️  Resetar Configurações", c3,
        UDim2.new(1, 0, 0, 36), nil,
        { bg=Color3.fromRGB(50,20,20), bgHover=THEME.danger })
    resetBtn.LayoutOrder = 2
    resetBtn.MouseButton1Click:Connect(function()
        Cfg:Reset()
        tween(resetBtn, { BackgroundColor3 = THEME.danger }, 0.1)
        task.wait(0.4)
        tween(resetBtn, { BackgroundColor3 = Color3.fromRGB(50,20,20) }, 0.3)
    end)
end

-- ── LOGS ──
function UIController:_pageLogs(content, deps)
    local p = newPage("Logs", content)
    _pages["Logs"] = p

    make("TextLabel", { Text="Logs", Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, TextColor3=THEME.text, Font=FONT, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0 }, p)

    local c = card("", p, 1)

    -- Botão limpar
    local clearBtn = makeButton("Limpar Logs", c,
        UDim2.new(0, 120, 0, 28), nil,
        { bg=Color3.fromRGB(30,30,45), bgHover=THEME.accent })
    clearBtn.LayoutOrder = 0
    clearBtn.MouseButton1Click:Connect(function()
        deps.LoggingManager:Clear()
    end)

    local logFrame = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, c)

    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, logFrame)

    local levelColors = {
        INFO=THEME.text, WARNING=THEME.warning,
        ERROR=THEME.danger, CRITICAL=Color3.fromRGB(217,70,239),
    }

    local lastCount = 0
    RunService.Heartbeat:Connect(function()
        local logs = deps.LoggingManager:GetAll()
        if #logs == lastCount then return end
        lastCount = #logs

        -- limpa labels antigas
        for _, child in ipairs(logFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end

        -- mostra últimas 50
        local start = math.max(1, #logs - 49)
        for i = start, #logs do
            local entry = logs[i]
            make("TextLabel", {
                Text = "["..entry.level.."] "..entry.message,
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                TextColor3 = levelColors[entry.level] or THEME.text,
                Font = Enum.Font.RobotoMono,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                LayoutOrder = i,
            }, logFrame)
        end
    end)
end

-- ───────────────────────────────────────────────
-- Keybind (RightShift toggle)
-- ───────────────────────────────────────────────

function UIController:_setupKeybind()
    UserInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            local win = _gui and _gui._win
            if win then
                win.Visible = not win.Visible
            end
        end
    end)
end

function UIController:_startUpdater() end -- heartbeats já conectados inline

return UIController
