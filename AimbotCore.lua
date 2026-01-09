-- AimbotCore.lua
-- Módulo de lógica de aimbot
-- Use: local AimbotCore = loadstring(game:HttpGet('URL'))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local AimbotCore = {}
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Atualizar câmera quando mudar
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = workspace.CurrentCamera
end)

-- Inicializar FOV se não existir
if not getgenv().AimbotFOV then
    getgenv().AimbotFOV = 100
end

-- Configurações
local isEnabled = false
local isActive = false

-- Círculo visual do FOV
local fovCircle = nil
local isDrawingApiAvailable = false

-- Tentar criar círculo usando Drawing API
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Thickness = 2
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 0.5
        fovCircle.Filled = false
        isDrawingApiAvailable = true
    end
end)

-- Função para verificar se o alvo está visível
local function isTargetVisible(targetPart, character)
    local cameraPos = camera.CFrame.Position
    local _, onscreen = camera:WorldToViewportPoint(targetPart.Position)
    
    if onscreen then
        local ray = Ray.new(cameraPos, targetPart.Position - cameraPos)
        local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, player.Character:GetDescendants())
        
        if hitPart and hitPart:IsDescendantOf(character) then
            return true
        else
            return false
        end
    else
        return false
    end
end

-- Função para verificar se são do mesmo time
local function isSameTeam(targetPlayer)
    if not getgenv().TeamCheck then
        return false -- Se TeamCheck desativado, não filtra
    end
    
    -- Verificar se ambos têm Team definido
    if player.Team and targetPlayer.Team then
        return player.Team == targetPlayer.Team
    end
    
    -- Fallback para TeamColor
    if player.TeamColor and targetPlayer.TeamColor then
        return player.TeamColor == targetPlayer.TeamColor
    end
    
    -- Se não tem time definido, não são do mesmo time
    return false
end

-- Função para verificar se o alvo está dentro do FOV
local function isTargetInFOV(targetPart)
    local viewportPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then
        return false
    end
    
    local viewportSize = camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local targetPos = Vector2.new(viewportPoint.X, viewportPoint.Y)
    local distance = (targetPos - screenCenter).Magnitude
    
    local fov = getgenv().AimbotFOV or 100
    return distance <= fov
end

-- Função para atualizar o círculo visual do FOV
local function updateFOVCircle()
    if not fovCircle or not isDrawingApiAvailable then
        return
    end
    
    local viewportSize = camera.ViewportSize
    local fov = getgenv().AimbotFOV or 100
    
    fovCircle.Visible = isEnabled
    fovCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    fovCircle.Radius = fov
end

-- Função para encontrar o alvo mais próximo
local function findNearestTarget()
    local nearestTarget = nil
    local nearestDistance = math.huge
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            pcall(function()
                local shouldTarget = true
                
                -- Verificar time (se necessário)
                if isSameTeam(targetPlayer) then
                    shouldTarget = false
                end
                
                if shouldTarget and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") and targetPlayer.Character:FindFirstChild("Humanoid") then
                    -- Verificar se está dentro do FOV
                    if not isTargetInFOV(targetPlayer.Character.Head) then
                        return -- Pular se estiver fora do FOV
                    end
                    
                    local distance = (mouse.Hit.Position - targetPlayer.Character.PrimaryPart.Position).magnitude
                    
                    if distance < nearestDistance then
                        if isTargetVisible(targetPlayer.Character.Head, targetPlayer.Character) and targetPlayer.Character.Humanoid.Health > 0 then
                            nearestTarget = targetPlayer
                            nearestDistance = distance
                        end
                    end
                end
            end)
        end
    end
    
    return nearestTarget
end

-- Função para ativar/desativar o aimbot
function AimbotCore:SetEnabled(enabled)
    isEnabled = enabled
    if not enabled then
        isActive = false
    end
    updateFOVCircle()
end

-- Função para definir o FOV
function AimbotCore:SetFOV(fov)
    getgenv().AimbotFOV = math.clamp(fov, 50, 500)
    updateFOVCircle()
end

-- Função para obter o FOV
function AimbotCore:GetFOV()
    return getgenv().AimbotFOV or 100
end

-- Função para verificar se está ativado
function AimbotCore:IsEnabled()
    return isEnabled
end

-- Sistema de input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and isEnabled then
        if getgenv().AimbotInput == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            isActive = true
        elseif getgenv().AimbotInput == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            isActive = true
        elseif input.KeyCode.Name == getgenv().AimbotInput then
            isActive = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if getgenv().AimbotInput == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            isActive = false
        elseif getgenv().AimbotInput == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            isActive = false
        elseif input.KeyCode.Name == getgenv().AimbotInput then
            isActive = false
        end
    end
end)

-- Variável para armazenar o alvo atual (Cache)
local currentTarget = nil
local isScanning = false

-- Loop de busca de alvo (Executa com menos frequência para performance)
task.spawn(function()
    while true do
        if isEnabled then
            isScanning = true
            -- Busca o alvo e atualiza o cache
            currentTarget = findNearestTarget()
            isScanning = false
        else
            currentTarget = nil
        end
        -- Espera 0.1s entre scans (10Hz) em vez de rodar a cada frame (60Hz+)
        -- Isso reduz drasticamente o uso de CPU em servidores cheios
        task.wait(0.1) 
    end
end)

-- Loop principal do aimbot (Apenas move a câmera)
RunService.RenderStepped:Connect(function()
    -- RenderStepped é mais suave para câmera do que while wait()
    if isActive and isEnabled and currentTarget then
        if currentTarget.Character and currentTarget.Character:FindFirstChild("Head") then
            -- Verificação adicional de visibilidade/saúde a cada frame para garantir que não estamos mirando em morto
            local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                 local currentCFrame = camera.CFrame
                 local easing = getgenv().AimbotEasing or 1
                 -- Interpolação suave
                 camera.CFrame = currentCFrame:Lerp(CFrame.new(currentCFrame.Position, currentTarget.Character.Head.Position), easing)
            else
                currentTarget = nil -- Limpa alvo se morreu
            end
        end
    end
end)

-- Remover o loop antigo task.spawn com while task.wait() 
-- O código acima substitui o bloco das linhas 202-214 original

-- Atualizar círculo FOV em tempo real
RunService.RenderStepped:Connect(function()
    if isEnabled then
        updateFOVCircle()
    elseif fovCircle and isDrawingApiAvailable then
        fovCircle.Visible = false
    end
end)

-- Atualizar FOV quando mudar
if getgenv then
    local lastFOV = getgenv().AimbotFOV or 100
    task.spawn(function()
        while task.wait(0.1) do
            local currentFOV = getgenv().AimbotFOV or 100
            if currentFOV ~= lastFOV then
                lastFOV = currentFOV
                updateFOVCircle()
            end
        end
    end)
end

-- Inicializar círculo
updateFOVCircle()

return AimbotCore
