-- ESPCore.lua
-- ESP Universal Otimizado - Funciona em todos os jogos
-- Aura/Contorno nos jogadores

assert(Drawing, 'Drawing API required')

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESPCore = {}
local isEnabled = false

-- ============================================
-- OBJECT POOLING SYSTEM
-- ============================================
-- Cache de desenhos ativos e inativos para reuso
local drawingPool = {
    Boxes = {},     -- Objetos Square livres
    NameTags = {}   -- Objetos Text livres
}
local playerDrawings = {} -- Mapa: PlayerName -> {Box = obj, NameTag = obj}

-- Função para pegar um objeto do pool ou criar novo
local function GetDrawingFromPool(type)
    local pool = (type == "Square") and drawingPool.Boxes or drawingPool.NameTags
    
    if #pool > 0 then
        -- Retorna o último objeto do pool (pop)
        return table.remove(pool)
    end
    
    -- Se não houver no pool, cria um novo
    local drawing = Drawing.new(type)
    drawing.Visible = false
    drawing.Transparency = 1
    
    if type == "Square" then
        drawing.Color = Color3.new(1, 1, 1)
        drawing.Thickness = 2
        drawing.Filled = false
    elseif type == "Text" then
        drawing.Center = true
        drawing.Outline = true
        drawing.OutlineColor = Color3.new(0, 0, 0)
        drawing.Size = 14
    end
    
    return drawing
end

-- Função para devolver objeto ao pool
local function ReturnDrawingToPool(type, drawing)
    if not drawing then return end
    
    drawing.Visible = false -- Garante que suma da tela
    
    local pool = (type == "Square") and drawingPool.Boxes or drawingPool.NameTags
    table.insert(pool, drawing)
end

-- ============================================
-- LOGIC
-- ============================================

-- Função para obter cor do time (Robust Team Color)
local function GetTeamColor(player)
    -- 1. Tentar pegar diretamente do TeamColor da instância Player
    if player.TeamColor then
        return player.TeamColor.Color
    end

    -- 2. Tentar via Serviço Teams (Padrão Roblox)
    if player.Team then
        if player.Team.TeamColor then
             return player.Team.TeamColor.Color
        end
    end

    -- 3. Tentar inferir via SpawnLocation (Opcional, mas pesado) ou Atributos
    -- Fallback: Cor única baseada no nome (Hash) para jogos FFA sem times definidos
    -- Isso garante que cada jogador tenha uma cor consistente, mas diferente
    -- local hash = 0
    -- for i = 1, #player.Name do hash = hash + string.byte(player.Name, i) end
    -- return Color3.fromHSV((hash % 100)/100, 0.8, 1) -- Cor aleatória consistente
    
    -- Por enquanto, retornamos Branco se não tiver time, ou Vermelho se for inimigo (FFA)
    return Color3.fromRGB(255, 255, 255)
end

-- Função auxiliar para verificar inimigo
local function IsEnemy(targetPlayer)
    -- Se FFA (Free For All) ou sem time, todos são inimigos
    if not LocalPlayer.Team then return true end
    if not targetPlayer.Team then return true end
    
    -- Se times forem diferentes, é inimigo
    return LocalPlayer.Team ~= targetPlayer.Team
end

local function CreateDrawings(playerName)
    if playerDrawings[playerName] then
        return playerDrawings[playerName]
    end
    
    local box = GetDrawingFromPool("Square")
    local nameTag = GetDrawingFromPool("Text")
    
    local drawings = {
        Box = box,
        NameTag = nameTag
    }
    
    playerDrawings[playerName] = drawings
    return drawings
end

local function RemoveDrawings(playerName)
    local drawings = playerDrawings[playerName]
    if drawings then
        if drawings.Box then
            ReturnDrawingToPool("Square", drawings.Box)
        end
        if drawings.NameTag then
            ReturnDrawingToPool("Text", drawings.NameTag)
        end
        playerDrawings[playerName] = nil
    end
end

local function UpdateESP()
    -- Se desativado, esconder tudo
    if not isEnabled then
        for _, drawings in pairs(playerDrawings) do
            drawings.Box.Visible = false
            drawings.NameTag.Visible = false
        end
        return
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewportSize = camera.ViewportSize
    
    -- Otimização: Cachear referência do LocalPlayer.Character
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            goto next_iter
        end
        
        local character = player.Character
        local drawings = playerDrawings[player.Name]
        
        -- Condições de falha (Jogador sem char, morto, etc)
        if not character then
            if drawings then
                drawings.Box.Visible = false
                drawings.NameTag.Visible = false
            end
            goto next_iter
        end
        
        -- Busca rápida de partes (sem WaitForChild no render loop)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChild("Humanoid")
        
        if not rootPart or not head or (humanoid and humanoid.Health <= 0) then
            if drawings then
                drawings.Box.Visible = false
                drawings.NameTag.Visible = false
            end
            goto next_iter
        end
        
        -- Garante que desenhos existam
        if not drawings then
            drawings = CreateDrawings(player.Name)
        end
        
        -- Cálculos de Projeção 3D -> 2D
        -- Usamos Position direto para performance, assumindo CFrame atualizado
        local rootPos, rootVis = camera:WorldToViewportPoint(rootPart.Position)
        
        if not rootVis then
            drawings.Box.Visible = false
            drawings.NameTag.Visible = false
            goto next_iter
        end
        
        -- Calcular posição da cabeça para altura
        local headPos, _ = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos, _ = camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
        
        local boxHeight = math.abs(headPos.Y - legPos.Y)
        local boxWidth = boxHeight * 0.6 -- Proporção padrão
        
        local boxPos = Vector2.new(rootPos.X - boxWidth/2, headPos.Y)
        local boxSize = Vector2.new(boxWidth, boxHeight)
        
        local color = GetTeamColor(player)
        
        -- Atualizar Box
        local box = drawings.Box
        box.Visible = true
        box.Color = color
        box.Size = boxSize
        box.Position = boxPos
        
        -- Atualizar Texto
        local tag = drawings.NameTag
        tag.Visible = true
        tag.Text = player.Name
        tag.Color = color
        tag.Position = Vector2.new(rootPos.X, headPos.Y - 18)
        
        ::next_iter::
    end
    
    -- Limpeza de jogadores invalidos (Opcional: Fazer isso em outro loop se pesar)
end

function ESPCore:SetEnabled(enabled)
    isEnabled = enabled
    if getgenv then getgenv().ESPEnabled = enabled end
    
    if not enabled then
        for player, _ in pairs(playerDrawings) do
            RemoveDrawings(player) -- Devolve pro pool e esconde
        end
    end
end

function ESPCore:IsEnabled()
    return isEnabled
end

-- Inicialização
if getgenv then
    isEnabled = getgenv().ESPEnabled or false
else
    isEnabled = false
end

-- Limpeza automatica
Players.PlayerRemoving:Connect(function(player)
    RemoveDrawings(player.Name)
end)

RunService.RenderStepped:Connect(UpdateESP)

return ESPCore
