-- RespawnCore.lua
-- Módulo de lógica de respawn (sem HUD)
-- Use: local RespawnCore = loadstring(game:HttpGet('URL'))()

local Players = game:GetService("Players")

local RespawnCore = {}
local player = Players.LocalPlayer
local isEnabled = false
local lastCFrame = nil

-- Função para ativar/desativar
function RespawnCore:SetEnabled(enabled)
    isEnabled = enabled
    if not enabled then
        lastCFrame = nil
    end
end

-- Função para verificar se está ativado
function RespawnCore:IsEnabled()
    return isEnabled
end

-- Função para obter última posição
function RespawnCore:GetLastPosition()
    return lastCFrame
end

-- Função quando o personagem é adicionado
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")

    -- Se tiver posição salva e estiver ativado, volta pra ela
    -- Se tiver posição salva e estiver ativado, volta pra ela
    if lastCFrame and isEnabled then
        -- Lógica Anti-Spawn-Fight: Loop de Força Bruta
        -- Teleporta repetidamente para garantir que vença o script de spawn do jogo
        task.spawn(function()
            -- Delay inicial breve
            task.wait(0.2)
            
            local startTime = os.clock()
            -- Forçar posição por ~1.5 segundos
            while os.clock() - startTime < 1.5 do
                if root and root.Parent and humanoid.Health > 0 then
                    root.CFrame = lastCFrame
                    -- Zerar velocidade física para evitar bugs
                    root.Velocity = Vector3.new(0,0,0)
                    root.RotVelocity = Vector3.new(0,0,0)
                else
                    break
                end
                task.wait(0.05)
            end
            
            print("Reposicionado na posição de morte (Anti-Revert Ativo)!")
            lastCFrame = nil -- Limpar após completar o ciclo
            
            -- Disparar evento de respawn
            if RespawnCore.OnRespawned then
                RespawnCore.OnRespawned:Fire()
            end
        end)
    end

    -- Quando morrer, salvar posição (só se estiver ativado)
    humanoid.Died:Connect(function()
        if root and isEnabled then
            lastCFrame = root.CFrame
            print("Posição de morte salva!")
            
            -- Disparar evento de morte
            if RespawnCore.OnDeath then
                RespawnCore.OnDeath:Fire()
            end
        end
    end)
end

-- Conectar quando o personagem spawnar
player.CharacterAdded:Connect(onCharacterAdded)

-- Caso o personagem já exista
if player.Character then
    onCharacterAdded(player.Character)
end

-- Eventos para comunicação
RespawnCore.OnDeath = Instance.new("BindableEvent")
RespawnCore.OnRespawned = Instance.new("BindableEvent")

return RespawnCore
