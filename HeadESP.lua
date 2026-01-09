-- HeadESP.lua
-- Módulo de ESP de cabeças (aumenta e destaca cabeças dos jogadores)
-- Use: local HeadESP = loadstring(game:HttpGet('URL'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HeadESP = {}
local player = Players.LocalPlayer

-- Inicializar variáveis globais se não existirem
if not _G.HeadSize then
    _G.HeadSize = 5
end
if _G.Disabled == nil then
    _G.Disabled = true
end

-- Função para ativar/desativar o ESP
function HeadESP:SetEnabled(enabled)
    _G.Disabled = not enabled
end

-- Função para verificar se está ativado
function HeadESP:IsEnabled()
    return not _G.Disabled
end

-- Função para definir o tamanho da cabeça
function HeadESP:SetHeadSize(size)
    _G.HeadSize = size
end

-- Função para obter o tamanho da cabeça
function HeadESP:GetHeadSize()
    return _G.HeadSize
end

-- Loop principal do ESP
RunService.RenderStepped:Connect(function()
    if not _G.Disabled then
        for i, v in next, Players:GetPlayers() do
            if v.Name ~= player.Name then
                pcall(function()
                    if v.Character and v.Character:FindFirstChild("Head") then
                        local head = v.Character.Head
                        head.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                        head.Transparency = 1
                        head.BrickColor = BrickColor.new("Red")
                        head.Material = "Neon"
                        head.CanCollide = false
                        head.Massless = true
                    end
                end)
            end
        end
    end
end)

return HeadESP
