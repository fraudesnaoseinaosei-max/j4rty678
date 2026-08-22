-- RespawnHUD.lua
-- Interface Moderna "Voidware Style" (Roxo/Dark)
-- Universal Hub

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Compatibility for Executors without getgenv
local getgenv = getgenv or function() return _G end

local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

-- ==========================================
-- SECURITY: EXECUTION GUARD
-- ==========================================
if getgenv().DreeZyHubLoaded then
    warn("DreeZy-HUB já está carregado!")
    return
end
getgenv().DreeZyHubLoaded = true

-- Limpar flag ao destruir
CoreGui.ChildRemoved:Connect(function(child)
    if child.Name == "DreeZyVoidware" then
        getgenv().DreeZyHubLoaded = false
    end
end)

-- ==========================================
-- GLOBAL CONFIG INITIALIZATION
-- ==========================================
if not getgenv().AimbotInput then getgenv().AimbotInput = "RightClick" end
if not getgenv().AimbotFOV then getgenv().AimbotFOV = 100 end
if not getgenv().AimbotEasing then getgenv().AimbotEasing = 1 end
if getgenv().TeamCheck == nil then getgenv().TeamCheck = false end
if getgenv().LegitMode == nil then getgenv().LegitMode = false end -- New Legit Mode
if getgenv().KillAuraEnabled == nil then getgenv().KillAuraEnabled = false end -- Kill Aura
if getgenv().ESPHealth == nil then getgenv().ESPHealth = false end
if getgenv().ESPEnabled == nil then getgenv().ESPEnabled = false end
if getgenv().ESPNames == nil then getgenv().ESPNames = false end
if getgenv().ESPTracers == nil then getgenv().ESPTracers = false end
if getgenv().HighAlertEnabled == nil then getgenv().HighAlertEnabled = false end
if getgenv().HighAlertTeamCheck == nil then getgenv().HighAlertTeamCheck = true end
if not getgenv().HighAlertThickness then getgenv().HighAlertThickness = 18 end
if getgenv().HighAlertArrowEnabled == nil then getgenv().HighAlertArrowEnabled = false end
if not getgenv().HighAlertArrowRadius then getgenv().HighAlertArrowRadius = 90 end
if not getgenv().HighAlertArrowSize then getgenv().HighAlertArrowSize = 22 end
if not getgenv().UnlockMouseKey then getgenv().UnlockMouseKey = Enum.KeyCode.P end

if getgenv().MinimapEnabled == nil then getgenv().MinimapEnabled = false end
if not getgenv().MinimapSize then getgenv().MinimapSize = 150 end
if getgenv().MinimapRound == nil then getgenv().MinimapRound = true end
if not getgenv().MinimapZoom then getgenv().MinimapZoom = 250 end

-- ==========================================
-- BUNDLED MODULES (LÓGICA PRESERVADA)
-- ==========================================

-- [0] MOUSE UNLOCKER CORE (Aggressive Modal Fix)
local MouseUnlocker = (function()
    local MouseUnlocker = {}
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    
    -- "Modal Trick" Button setup
    local modalButton = Instance.new("TextButton")
    modalButton.Name = "MouseForceModal"
    modalButton.Text = ""
    modalButton.BackgroundTransparency = 1
    modalButton.Modal = true 
    modalButton.Visible = false
    
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
    if playerGui then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MouseUnlockGui"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 999999 
        screenGui.Parent = game:GetService("CoreGui")
        modalButton.Parent = screenGui
    end

    local isUnlocked = false
    local connection = nil
    
    function MouseUnlocker:SetUnlocked(unlocked)
        isUnlocked = unlocked
        if unlocked then
            if not connection then
                RunService:BindToRenderStep("DreeZyMouseUnlock", Enum.RenderPriority.Camera.Value + 10000, function()
                    local rightClick = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                    if not rightClick then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                        UserInputService.MouseIconEnabled = true 
                        if modalButton then modalButton.Visible = true end
                    else
                         if modalButton then modalButton.Visible = false end
                    end
                end)
            end
            connection = true 
        else
            if connection then
                RunService:UnbindFromRenderStep("DreeZyMouseUnlock")
                connection = nil
            end
            if modalButton then modalButton.Visible = false end
            -- UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter -- Fix: Removido para evitar conflito com ShiftLock (deixa o Roblox gerenciar)
        end
    end
    function MouseUnlocker:IsUnlocked() return isUnlocked end
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local binding = getgenv().IsBindingKey
        if (input.KeyCode == getgenv().UnlockMouseKey) and (not binding) then
             MouseUnlocker:SetUnlocked(not isUnlocked)
        end
    end)
    return MouseUnlocker
end)()

-- [1] RESPAWN CORE
local RespawnCore = (function()
    local Players = game:GetService("Players")
    local RespawnCore = {}
    local player = Players.LocalPlayer
    local isEnabled = false
    local lastCFrame = nil

    function RespawnCore:SetEnabled(enabled)
        isEnabled = enabled
        if not enabled then lastCFrame = nil end
    end
    function RespawnCore:IsEnabled() return isEnabled end
    function RespawnCore:GetLastPosition() return lastCFrame end

    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        local root = character:WaitForChild("HumanoidRootPart")

        if lastCFrame and isEnabled then
            task.spawn(function()
                task.wait(0.2)
                local startTime = os.clock()
                while os.clock() - startTime < 1.5 do
                    if root and root.Parent and humanoid.Health > 0 then
                        root.CFrame = lastCFrame
                        root.Velocity = Vector3.new(0,0,0)
                        root.RotVelocity = Vector3.new(0,0,0)
                    else
                        break
                    end
                    task.wait(0.05)
                end
                lastCFrame = nil
                if RespawnCore.OnRespawned then RespawnCore.OnRespawned:Fire() end
            end)
        end

        humanoid.Died:Connect(function()
            if root and isEnabled then
                lastCFrame = root.CFrame
                if RespawnCore.OnDeath then RespawnCore.OnDeath:Fire() end
            end
        end)
    end

    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then onCharacterAdded(player.Character) end

    RespawnCore.OnDeath = Instance.new("BindableEvent")
    RespawnCore.OnRespawned = Instance.new("BindableEvent")
    return RespawnCore
end)()

-- ============================================
-- [1.5] GLOBAL DYNAMIC TEAM & FFA MANAGER
-- ============================================
local TeamManager = (function()
    local Players = game:GetService("Players")
    local Teams = game:GetService("Teams")
    local LocalPlayer = Players.LocalPlayer

    -- Valida se o time do jogador é uma instância real e ativa dentro do serviço Teams
    local function GetValidTeam(p)
        if not p then return nil end
        if p.Neutral then return nil end
        local t = p.Team
        if t and typeof(t) == "Instance" and t:IsA("Team") and t.Parent == Teams then
            return t
        end
        return nil
    end

    -- Detecta se o jogo está em modo FFA / Todos contra Todos (pasta Teams vazia ou com <= 1 time)
    local function IsFFAMode()
        local success, allTeams = pcall(function() return Teams:GetTeams() end)
        if not success or not allTeams or #allTeams <= 1 then
            return true
        end

        local activeTeamsCount = 0
        for _, t in ipairs(allTeams) do
            if t.Parent == Teams then
                activeTeamsCount = activeTeamsCount + 1
            end
        end

        return activeTeamsCount <= 1
    end

    local function IsAlly(targetPlayer)
        if not targetPlayer or targetPlayer == LocalPlayer then return true end
        
        -- Se a pasta Teams foi deletada ou só tem 1 time: é FFA (ninguém é aliado exceto você!)
        if IsFFAMode() then
            return false
        end

        local myTeam = GetValidTeam(LocalPlayer)
        local targetTeam = GetValidTeam(targetPlayer)

        -- Se ambos têm times ativos e válidos dentro de Teams
        if myTeam and targetTeam then
            return myTeam == targetTeam
        end

        -- Se algum jogador não tem time dentro de Teams, é neutro/inimigo
        return false
    end

    local function GetPlayerColor(targetPlayer)
        if not targetPlayer then return Color3.fromRGB(255, 255, 255) end

        -- 1. Se estiver em modo Solo / FFA (pasta Teams vazia/deletada):
        -- Ignora cores antigas residuais que ficaram na memória e aplica cor limpa padrão para todos
        if IsFFAMode() then
            return Color3.fromRGB(255, 255, 255)
        end

        -- 2. Se estiver em modo de Times (Teams possui 2 ou mais times):
        local validTeam = GetValidTeam(targetPlayer)
        if validTeam then
            if validTeam.TeamColor and validTeam.TeamColor.Color then
                return validTeam.TeamColor.Color
            end
            if targetPlayer.TeamColor and targetPlayer.TeamColor.Color then
                return targetPlayer.TeamColor.Color
            end
        end

        -- 3. Fallback para jogadores sem time ativo
        return Color3.fromRGB(255, 255, 255)
    end

    return {
        GetValidTeam = GetValidTeam,
        IsFFAMode = IsFFAMode,
        IsAlly = IsAlly,
        IsEnemy = function(p) return not IsAlly(p) end,
        GetPlayerColor = GetPlayerColor
    }
end)()

-- [2] AIMBOT CORE
local AimbotCore = (function()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Teams = game:GetService("Teams")
    local RunService = game:GetService("RunService")

    local AimbotCore = {}
    local player = Players.LocalPlayer
    local mouse = player:GetMouse()
    local camera = workspace.CurrentCamera

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        camera = workspace.CurrentCamera
    end)

    if not getgenv().AimbotFOV then getgenv().AimbotFOV = 100 end

    local isEnabled = false
    local isActive = false
    local useCursorAim = false
    local fovCircle = nil
    local isDrawingApiAvailable = false

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

    local ignoredPlayers = {} -- List of ignored player names
    local ignoredTeams = {} -- List of ignored team names

    local function isTargetVisible(targetPart, character)
        if not targetPart or not character then return false end
        local cameraPos = camera.CFrame.Position
        local _, onscreen = camera:WorldToViewportPoint(targetPart.Position)
        if not onscreen then return false end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local ignoreList = {player.Character}
        if camera then table.insert(ignoreList, camera) end
        rayParams.FilterDescendantsInstances = ignoreList
        rayParams.IgnoreWater = true

        local result = workspace:Raycast(cameraPos, targetPart.Position - cameraPos, rayParams)
        if result and result.Instance and result.Instance:IsDescendantOf(character) then
            return true
        end
        return false
    end

    local function getAnyVisiblePart(char)
        if not char then return nil end
        local head = char:FindFirstChild("Head")
        if head and isTargetVisible(head, char) then return head end
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
        if torso and isTargetVisible(torso, char) then return torso end
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") and isTargetVisible(part, char) then
                return part
            end
        end
        return nil
    end

    local function isSameTeam(targetPlayer)
        if not getgenv().TeamCheck then return false end
        return TeamManager.IsAlly(targetPlayer)
    end

    local function isTargetInFOV(targetPart)
        local viewportPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then return false end
        local viewportSize = camera.ViewportSize
        local screenCenter = nil
        if useCursorAim then
             screenCenter = UserInputService:GetMouseLocation()
        else
             screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        end
        local targetPos = Vector2.new(viewportPoint.X, viewportPoint.Y)
        local distance = (targetPos - screenCenter).Magnitude
        local fov = getgenv().AimbotFOV or 100
        return distance <= fov
    end

    local function updateFOVCircle()
        if not fovCircle or not isDrawingApiAvailable then return end
        local viewportSize = camera.ViewportSize
        local fov = getgenv().AimbotFOV or 100
        fovCircle.Visible = isEnabled
        if useCursorAim then
             fovCircle.Position = UserInputService:GetMouseLocation()
        else
             fovCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        end
        fovCircle.Radius = fov
    end

    local function findNearestTarget()
        local nearestTarget = nil
        local nearestDistance = math.huge
        local viewportSize = camera.ViewportSize
        local screenOrigin = useCursorAim and UserInputService:GetMouseLocation() or Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        local maxFov = getgenv().AimbotFOV or 100

        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                pcall(function()
                    local shouldTarget = true
                    if isSameTeam(targetPlayer) then shouldTarget = false end

                    -- Checar se é Amigo ignorado
                    if ignoredPlayers["Amigos"] and player:IsFriendsWith(targetPlayer.UserId) then
                        shouldTarget = false
                    end

                    -- Checar se Jogador está na lista de exceção
                    if ignoredPlayers[targetPlayer.Name] or (targetPlayer.DisplayName and ignoredPlayers[targetPlayer.DisplayName]) then
                        shouldTarget = false
                    end

                    -- Checar se Time está na lista de exceção
                    if targetPlayer.Team and ignoredTeams[targetPlayer.Team.Name] then
                        shouldTarget = false
                    end
                    if targetPlayer.TeamColor and ignoredTeams[tostring(targetPlayer.TeamColor)] then
                        shouldTarget = false
                    end

                    if shouldTarget and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") and targetPlayer.Character:FindFirstChild("Humanoid") then
                        local head = targetPlayer.Character.Head
                        local humanoid = targetPlayer.Character.Humanoid
                        if humanoid.Health > 0 and isTargetVisible(head, targetPlayer.Character) then
                            local viewportPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                            if onScreen then
                                local target2D = Vector2.new(viewportPoint.X, viewportPoint.Y)
                                local dist2D = (target2D - screenOrigin).Magnitude
                                if dist2D <= maxFov and dist2D < nearestDistance then
                                    nearestTarget = targetPlayer
                                    nearestDistance = dist2D
                                end
                            end
                        end
                    end
                end)
            end
        end
        return nearestTarget
    end

    local aimKey = Enum.UserInputType.MouseButton2 -- Padrão oficial: Botão Direito (M2)

    local ContextActionService = game:GetService("ContextActionService")
    local function BlockCameraRightClick()
        return Enum.ContextActionResult.Sink
    end

    function AimbotCore:SetEnabled(enabled)
        isEnabled = enabled
        if not enabled then 
            isActive = false 
            currentTarget = nil
            lastLockedTarget = nil
            ContextActionService:UnbindAction("DreezyBlockCamDrag")
        end
        updateFOVCircle()
    end
    function AimbotCore:SetTriggerKey(k)
        aimKey = k or Enum.UserInputType.MouseButton2
        if typeof(k) == "EnumItem" then
            getgenv().AimbotInput = k.Name
        elseif typeof(k) == "string" then
            getgenv().AimbotInput = k
        end
    end
    function AimbotCore:GetTriggerKey()
        return aimKey or Enum.UserInputType.MouseButton2
    end
    function AimbotCore:SetCursorAim(enabled)
        useCursorAim = enabled
        if getgenv then getgenv().CursorAim = enabled end
        if not enabled then
            UnfreezeCamera()
            ContextActionService:UnbindAction("DreezyBlockCamDrag")
        end
        updateFOVCircle()
    end
    function AimbotCore:IsCursorAim() return useCursorAim end
    function AimbotCore:SetFOV(fov)
        getgenv().AimbotFOV = math.clamp(fov, 20, 500)
        updateFOVCircle()
    end
    function AimbotCore:IgnorePlayer(name) ignoredPlayers[name] = true end
    function AimbotCore:UnignorePlayer(name) ignoredPlayers[name] = nil end
    function AimbotCore:IgnoreTeam(name) ignoredTeams[name] = true end
    function AimbotCore:UnignoreTeam(name) ignoredTeams[name] = nil end
    function AimbotCore:GetFOV() return getgenv().AimbotFOV or 100 end
    function AimbotCore:IsEnabled() return isEnabled end

    local hasIsKeyDown = (typeof(iskeydown) == "function") or (typeof(iskeypressed) == "function")
    local checkKeyFunc = iskeydown or iskeypressed

    local function IsInputMatch(input, targetKey)
        if typeof(targetKey) == "EnumItem" then
            if targetKey.EnumType == Enum.UserInputType then
                return input.UserInputType == targetKey
            elseif targetKey.EnumType == Enum.KeyCode then
                return input.KeyCode == targetKey
            end
        elseif typeof(targetKey) == "string" then
            local strKey = targetKey:lower()
            if strKey == "rightclick" or strKey == "mousebutton2" or strKey == "m2" then
                return input.UserInputType == Enum.UserInputType.MouseButton2
            elseif strKey == "leftclick" or strKey == "mousebutton1" or strKey == "m1" then
                return input.UserInputType == Enum.UserInputType.MouseButton1
            elseif strKey == "middleclick" or strKey == "mousebutton3" or strKey == "m3" then
                return input.UserInputType == Enum.UserInputType.MouseButton3
            else
                if input.KeyCode and input.KeyCode.Name then
                    return input.KeyCode.Name:lower() == strKey
                end
            end
        end
        return false
    end

    local function HandleAimStart(input, gpe)
        if not isEnabled then return end
        if IsInputMatch(input, aimKey) then
            isActive = true
            if useCursorAim and IsInputMatch(input, Enum.UserInputType.MouseButton2) then
                ContextActionService:BindActionAtPriority("DreezyBlockCamDrag", BlockCameraRightClick, false, Enum.ContextActionPriority.High.Value + 1000, Enum.UserInputType.MouseButton2)
            end
        end
    end

    local function HandleAimEnd(input)
        if IsInputMatch(input, aimKey) then
            isActive = false
            ContextActionService:UnbindAction("DreezyBlockCamDrag")
        end
    end

    UserInputService.InputBegan:Connect(HandleAimStart)
    UserInputService.InputEnded:Connect(HandleAimEnd)

    local function CheckAimbotTriggerActive()
        if not isEnabled then return false end
        if typeof(aimKey) == "string" and hasIsKeyDown then
            local strKey = aimKey:lower()
            if strKey == "m4" or strKey == "mousebutton4" or strKey == "side1" then
                return checkKeyFunc(0x05)
            elseif strKey == "m5" or strKey == "mousebutton5" or strKey == "side2" then
                return checkKeyFunc(0x06)
            elseif strKey == "m3" or strKey == "mousebutton3" then
                return checkKeyFunc(0x04)
            end
        end
        return isActive
    end

    local currentTarget = nil
    local lastLockedTarget = nil
    local activeTargetPart = "Head"

    local function isTargetValid(targetPlayer)
        if not targetPlayer or not targetPlayer.Parent then return false end
        local char = targetPlayer.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if isSameTeam(targetPlayer) then return false end
        if ignoredPlayers["Amigos"] and player:IsFriendsWith(targetPlayer.UserId) then return false end
        if ignoredPlayers[targetPlayer.Name] or (targetPlayer.DisplayName and ignoredPlayers[targetPlayer.DisplayName]) then return false end
        if targetPlayer.Team and ignoredTeams[targetPlayer.Team.Name] then return false end
        if targetPlayer.TeamColor and ignoredTeams[tostring(targetPlayer.TeamColor)] then return false end
        
        local checkPartName = (typeof(activeTargetPart) == "string" and activeTargetPart) or "Head"
        local visPart = char:FindFirstChild(checkPartName) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not visPart or not isTargetVisible(visPart, char) then
            local altPart = getAnyVisiblePart(char)
            if not altPart then
                return false
            end
        end

        return true
    end

    -- Logic for Legit Mode & Random Parts Target Selection (Suporte R6 e R15)
    local candidateParts = {
        "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart",
        "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
        "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"
    }

    local function getRandomPart(char)
        if not char then return "Head" end
        
        -- Se Random Parts e Modo Legit não estiverem ativos, foca na Cabeça
        if not getgenv().RandomParts and not getgenv().LegitMode then
            return "Head"
        end

        local visibleList = {}
        for _, name in ipairs(candidateParts) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") and isTargetVisible(p, char) then
                table.insert(visibleList, name)
            end
        end

        if #visibleList > 0 then
            -- 35% de chance para Head se visível, senão sorteia entre os membros visíveis
            if char:FindFirstChild("Head") and isTargetVisible(char.Head, char) and math.random() <= 0.35 then
                return "Head"
            end
            return visibleList[math.random(1, #visibleList)]
        end

        return "Head"
    end

    RunService.RenderStepped:Connect(function()
        local currentlyActive = CheckAimbotTriggerActive()
        if isEnabled and currentlyActive then
            -- Se não tiver alvo válido ou se o alvo atual foi para trás de uma parede / perdeu a visão, busca outro visível
            if not isTargetValid(currentTarget) then
                currentTarget = findNearestTarget()
            end

            if currentTarget and currentTarget.Character and isTargetValid(currentTarget) then
                -- Ao selecionar ou travar novo alvo, sorteia a parte inicial
                if currentTarget ~= lastLockedTarget or not activeTargetPart then
                    lastLockedTarget = currentTarget
                    activeTargetPart = getRandomPart(currentTarget.Character)
                end
                
                -- Humanização / Random Parts: Troca periodicamente a parte do corpo mirada (Funciona no Cursor Aim e Camera Aim!)
                if (getgenv().RandomParts or getgenv().LegitMode) and currentTarget and currentTarget.Character then
                    if not getgenv().LastLegitSwitch then getgenv().LastLegitSwitch = 0 end
                    if tick() - getgenv().LastLegitSwitch > (math.random() * 0.25 + 0.15) then
                        activeTargetPart = getRandomPart(currentTarget.Character)
                        getgenv().LastLegitSwitch = tick()
                    end
                end

                local targetPartName = (typeof(activeTargetPart) == "string" and activeTargetPart) or "Head"
                local targetInst = currentTarget.Character:FindFirstChild(targetPartName) or currentTarget.Character:FindFirstChild("Head") or currentTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetInst and isTargetVisible(targetInst, currentTarget.Character) then
                    -- SMOOTHNESS / AIM ASSIST LOGIC (Aplica em ambos os modos)
                    local smoothing = 1
                    if getgenv().AimAssistMode then
                        local smoothVal = getgenv().AimbotSmoothness or 10
                        smoothing = 1 / math.max(1, smoothVal)
                    else
                        smoothing = getgenv().AimbotEasing or 1
                    end
                    
                    if useCursorAim then
                        -- CURSOR AIM: Aplica TODAS as configurações (Random Parts, Smoothness, Assist) diretamente no Cursor do Mouse!
                        local viewportPoint, onScreen = camera:WorldToViewportPoint(targetInst.Position)
                        if onScreen then
                            local mousePos = UserInputService:GetMouseLocation()
                            local target2D = Vector2.new(viewportPoint.X, viewportPoint.Y)
                            local delta = target2D - mousePos

                            local moveX = delta.X * smoothing
                            local moveY = delta.Y * smoothing

                            if mousemoverel then
                                mousemoverel(moveX, moveY)
                            elseif mousemoveabs then
                                mousemoveabs(mousePos.X + moveX, mousePos.Y + moveY)
                            elseif VirtualInputManager then
                                VirtualInputManager:SendMouseMoveEvent(mousePos.X + moveX, mousePos.Y + moveY, game)
                            end
                        end
                    else
                        -- CAMERA AIM: Move a câmera suavemente para a parte do corpo selecionada
                        local currentCFrame = camera.CFrame
                        local lookCFrame = CFrame.lookAt(currentCFrame.Position, targetInst.Position)
                        camera.CFrame = currentCFrame:Lerp(lookCFrame, smoothing)
                    end
                else
                    -- Se a parte do corpo não está visível, tenta pegar outra parte visível no char
                    local fallbackPart = getAnyVisiblePart(currentTarget.Character)
                    if fallbackPart then
                        activeTargetPart = fallbackPart.Name
                    else
                        currentTarget = nil
                        lastLockedTarget = nil
                    end
                end
            else
                currentTarget = nil
                lastLockedTarget = nil
            end
        else
            -- Destrava quando soltar o botão
            currentTarget = nil
            lastLockedTarget = nil
            ContextActionService:UnbindAction("DreezyBlockCamDrag")
        end
    end)

    RunService.RenderStepped:Connect(function()
        if isEnabled then updateFOVCircle() elseif fovCircle and isDrawingApiAvailable then fovCircle.Visible = false end
    end)

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
    updateFOVCircle()
    return AimbotCore
end)()

-- [2.5] KILL AURA CORE
local KillAuraCore = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local KillAura = {}
    local player = Players.LocalPlayer
    local isEnabled = false
    local targetMode = "Todos" -- "Todos", "Amigos", "PlayerName"
    local teamTargetMode = "Nada" -- "Nada" or TeamName
    local tpPositionMode = "Em Cima" -- "Em Cima" (padrão), "Atrás", "Dentro"

    local function getCFrameOffset()
        if tpPositionMode == "Atrás" then
            return CFrame.new(0, 0, 4)
        elseif tpPositionMode == "Dentro" then
            return CFrame.new(0, 0, 0)
        else -- "Em Cima" (Padrão)
            return CFrame.new(0, 4.5, 0)
        end
    end

    local function isSameTeam(targetPlayer)
        if targetMode ~= "Todos" then return false end
        if not getgenv().TeamCheck then return false end
        return TeamManager.IsAlly(targetPlayer)
    end

    local function isTeamMatch(targetPlayer)
        if teamTargetMode == "Nada" then return true end
        if targetPlayer.Team and targetPlayer.Team.Name == teamTargetMode then return true end
        -- Fallback for TeamColor if needed, but usually Team Name is enough
        return false
    end

    local function findNearestTarget()
        local nearestTarget = nil
        local nearestDistance = math.huge
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end

        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                local shouldCheck = false
                
                -- FILTERING LOGIC
                if targetMode == "Todos" then
                    if not isSameTeam(targetPlayer) and isTeamMatch(targetPlayer) then shouldCheck = true end
                elseif targetMode == "Amigos" then
                    if player:IsFriendsWith(targetPlayer.UserId) and isTeamMatch(targetPlayer) then shouldCheck = true end
                else
                    -- Specific Player (modified: MUST MATCH TEAM if one is selected)
                    if (targetPlayer.Name == targetMode or targetPlayer.DisplayName == targetMode) and isTeamMatch(targetPlayer) then
                        shouldCheck = true 
                    end
                end

                if shouldCheck then
                    local char = targetPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        local dist = (char.HumanoidRootPart.Position - myRoot.Position).Magnitude
                        -- For specific player, distance doesn't matter (we always want them), but used for nearest if multiple match (unlikely)
                        if dist < nearestDistance then
                            nearestDistance = dist
                            nearestTarget = targetPlayer
                        end
                    end
                end
            end
        end
        return nearestTarget
    end

    local currentTarget = nil

    RunService.Heartbeat:Connect(function()
        if not isEnabled then 
            currentTarget = nil
            return 
        end

        -- Check if current target is still valid
        if currentTarget then
            local char = currentTarget.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                currentTarget = nil
            end
            -- Validte Team in Real-Time (e.g. Prison Life arrest)
            if currentTarget and not isTeamMatch(currentTarget) then
                currentTarget = nil
            end
        end

        -- Find new target if we don't have one
        if not currentTarget then
            currentTarget = findNearestTarget()
        end

        -- Teleport execution
        if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = currentTarget.Character.HumanoidRootPart
                local newCFrame = targetRoot.CFrame * getCFrameOffset()
                player.Character.HumanoidRootPart.CFrame = newCFrame
            end
        end
    end)

    -- Noclip Logic
    RunService.Stepped:Connect(function()
        if isEnabled and player.Character then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    function KillAura:TeleportOnce()
        local target = findNearestTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = target.Character.HumanoidRootPart
                local newCFrame = targetRoot.CFrame * getCFrameOffset()
                player.Character.HumanoidRootPart.CFrame = newCFrame
                return target
            end
        end
        return nil
    end

    function KillAura:SetEnabled(enabled)
        isEnabled = enabled
        if getgenv then getgenv().KillAuraEnabled = enabled end
    end
    function KillAura:SetTargetMode(mode)
        targetMode = mode or "Todos"
        currentTarget = nil -- Reset target logic to force rescanning
    end
    function KillAura:SetTeamTarget(teamName)
        teamTargetMode = teamName or "Nada"
        currentTarget = nil
    end
    function KillAura:SetPositionMode(posMode)
        tpPositionMode = posMode or "Em Cima"
    end
    function KillAura:GetPositionMode()
        return tpPositionMode
    end
    function KillAura:IsEnabled() return isEnabled end
    if getgenv then isEnabled = getgenv().KillAuraEnabled or false else isEnabled = false end

    return KillAura
end)()

-- [3] HITBOX EXPAND
local HitboxExpand = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local HitboxExpand = {}
    local player = Players.LocalPlayer

    local Config = { Size = 10, Disabled = true }
    local selectedParts = {} -- Ex: { ["Cabeça"] = true, ["HumanoidRootPart"] = true }
    local originalProperties = {}

    -- Mapeamento amigável de partes do corpo para os nomes padrão em R6 e R15
    local PartMappings = {
        ["Cabeça"] = {"Head"},
        ["Tronco"] = {"Torso", "UpperTorso", "LowerTorso"},
        ["Braço Esquerdo"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
        ["Braço Direito"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
        ["Perna Esquerda"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
        ["Perna Direita"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
    }

    function HitboxExpand:RestoreParts()
        for part, props in pairs(originalProperties) do
            if part and part.Parent then
                pcall(function()
                    part.Size = props.Size
                    part.Transparency = props.Transparency
                    part.CanCollide = props.CanCollide
                    part.Massless = props.Massless
                end)
            end
        end
        originalProperties = {}
    end

    function HitboxExpand:SetEnabled(enabled)
        Config.Disabled = not enabled
        if not enabled then self:RestoreParts() end
    end
    function HitboxExpand:IsEnabled() return not Config.Disabled end

    function HitboxExpand:SetSize(size) Config.Size = size end
    function HitboxExpand:GetSize() return Config.Size end

    function HitboxExpand:AddPart(friendlyName)
        selectedParts[friendlyName] = true
    end

    function HitboxExpand:RemovePart(friendlyName)
        selectedParts[friendlyName] = nil
        self:RestoreParts()
    end

    function HitboxExpand:GetSelectedParts()
        return selectedParts
    end

    RunService.RenderStepped:Connect(function()
        if not Config.Disabled then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v.Character then
                    pcall(function()
                        local char = v.Character
                        -- Se nenhuma parte específica for escolhida na lista, expande por padrão a Cabeça
                        local activeMappings = selectedParts
                        if next(activeMappings) == nil then
                            activeMappings = { ["Cabeça"] = true }
                        end

                        for friendlyName, _ in pairs(activeMappings) do
                            local realPartNames = PartMappings[friendlyName]
                            if realPartNames then
                                for _, partName in ipairs(realPartNames) do
                                    local part = char:FindFirstChild(partName)
                                    if part and part:IsA("BasePart") then
                                        if not originalProperties[part] then
                                            originalProperties[part] = {
                                                Size = part.Size,
                                                Transparency = part.Transparency,
                                                CanCollide = part.CanCollide,
                                                Massless = part.Massless
                                            }
                                        end
                                        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
                                        part.Transparency = 0.7 -- Sutil e indetectável
                                        part.CanCollide = false
                                        part.Massless = true
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)
    return HitboxExpand
end)()

-- [3.5] AUTO SHOT CORE (TRIGGERBOT & AUTO-CLICKER)
local AutoShotCore = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

    local AutoShot = {}
    local player = Players.LocalPlayer
    local camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    local mouse = player:GetMouse()

    local isEnabled = false
    local ignoredPlayers = {}
    local ignoredTeams = {}

    local isHoldingMouse = false
    local lastClickTime = 0
    local clickInterval = 0.05 -- 50ms por padrão (20 Clicks por segundo)

    local function SendMousePress()
        if VirtualInputManager then
            local mousePos = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
        elseif mouse1press then
            mouse1press()
        end
    end

    local function SendMouseRelease()
        if VirtualInputManager then
            local mousePos = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
        elseif mouse1release then
            mouse1release()
        end
    end

    local function PerformSpamClick()
        if VirtualInputManager then
            local mousePos = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
        elseif mouse1click then
            mouse1click()
        elseif mouse1press and mouse1release then
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end
    end

    -- Checagem rigorosa de visibilidade por Raycast (Garante que o jogador não está atrás de paredes)
    local function IsTargetVisible(targetPart, targetCharacter)
        cam = Workspace.CurrentCamera or camera
        if not cam or not targetPart or not targetCharacter then return false end

        local origin = cam.CFrame.Position
        local targetPos = targetPart.Position
        local direction = targetPos - origin

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local ignoreList = {}
        if player.Character then table.insert(ignoreList, player.Character) end
        if cam then table.insert(ignoreList, cam) end

        raycastParams.FilterDescendantsInstances = ignoreList
        raycastParams.IgnoreWater = true

        local result = Workspace:Raycast(origin, direction, raycastParams)
        if result then
            return result.Instance:IsDescendantOf(targetCharacter)
        end
        return false
    end

    local function IsPlayerTarget(targetPart)
        if not targetPart or not targetPart.Parent then return nil end
        local char = targetPart.Parent

        -- Subir na hierarquia caso o cursor esteja em acessórios, ferramentas ou partes filhas
        if not char:FindFirstChildOfClass("Humanoid") then
            if char.Parent and char.Parent:FindFirstChildOfClass("Humanoid") then
                char = char.Parent
            end
        end

        local targetPlayer = Players:GetPlayerFromCharacter(char)
        if not targetPlayer or targetPlayer == player then return nil end

        -- Verificar se o jogador está vivo
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return nil end

        -- Verificar filtro de Exceção de Jogadores (Nome exato ou DisplayName)
        if ignoredPlayers[targetPlayer.Name] or ignoredPlayers[targetPlayer.DisplayName] then
            return nil
        end

        -- Verificar filtro de Exceção de Times (Nome do time ou TeamColor)
        if targetPlayer.Team and ignoredTeams[targetPlayer.Team.Name] then
            return nil
        end
        if targetPlayer.TeamColor and ignoredTeams[tostring(targetPlayer.TeamColor)] then
            return nil
        end

        -- Checar se o inimigo está realmente visível (não atrás de objetos/paredes)
        if not IsTargetVisible(targetPart, char) then
            return nil
        end

        return targetPlayer
    end

    RunService.RenderStepped:Connect(function()
        if not isEnabled then
            if isHoldingMouse then
                isHoldingMouse = false
                task.spawn(SendMouseRelease)
            end
            return
        end

        local targetPart = mouse.Target
        local validTarget = IsPlayerTarget(targetPart)

        if validTarget then
            -- Se acabou de mirar em um inimigo válido, pressiona e segura o botão do mouse!
            if not isHoldingMouse then
                isHoldingMouse = true
                task.spawn(SendMousePress)
            end

            -- Ao mesmo tempo, spama cliques no intervalo em milissegundos configurado pelo usuário!
            local now = os.clock()
            if now - lastClickTime >= clickInterval then
                lastClickTime = now
                task.spawn(PerformSpamClick)
            end
        else
            -- Se o cursor saiu do inimigo, solta o botão do mouse imediatamente
            if isHoldingMouse then
                isHoldingMouse = false
                task.spawn(SendMouseRelease)
            end
        end
    end)

    function AutoShot:SetEnabled(enabled)
        isEnabled = enabled
        if not enabled and isHoldingMouse then
            isHoldingMouse = false
            task.spawn(SendMouseRelease)
        end
        if getgenv then getgenv().AutoShotEnabled = enabled end
    end

    function AutoShot:IsEnabled()
        return isEnabled
    end

    function AutoShot:SetIntervalMS(ms)
        local num = tonumber(ms) or 50
        clickInterval = math.max(0.001, num / 1000) -- Mínimo seguro de 1ms
    end

    function AutoShot:GetIntervalMS()
        return math.floor(clickInterval * 1000 + 0.5)
    end

    function AutoShot:IgnorePlayer(name) ignoredPlayers[name] = true end
    function AutoShot:UnignorePlayer(name) ignoredPlayers[name] = nil end
    function AutoShot:IgnoreTeam(name) ignoredTeams[name] = true end
    function AutoShot:UnignoreTeam(name) ignoredTeams[name] = nil end

    return AutoShot
end)()

-- [3.6] AUTO CLICKER CORE (AUTO-CLICKER LOCAL COM DUPLA CAMADA E TECLADO/MOUSE INTERATIVOS)
local AutoClickerCore = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

    local AutoClicker = {}
    local player = Players.LocalPlayer

    local mainEnabled = false    -- Camada 1: Interruptor principal do soquete
    local keybindActive = false  -- Camada 2: Ativação por tecla/gatilho
    local triggerKey = Enum.KeyCode.E

    local clickTarget = "MouseButton1" -- "MouseButton1", "MouseButton2", "MouseButton3" ou "E", "Q", "Space", etc.
    local clickInterval = 0.05 -- 50ms por padrão (20 clicks p/s)
    local lastClickTime = 0

    local function PerformClick()
        local mousePos = UserInputService:GetMouseLocation()

        if clickTarget == "MouseButton1" then
            if VirtualInputManager then
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
            elseif mouse1click then
                mouse1click()
            end
        elseif clickTarget == "MouseButton2" then
            if VirtualInputManager then
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 1, true, game, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 1, false, game, 0)
            elseif mouse2click then
                mouse2click()
            end
        elseif clickTarget == "MouseButton3" then
            if VirtualInputManager then
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 2, true, game, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 2, false, game, 0)
            end
        else
            -- Tecla do Teclado (ex: "E", "Q", "Space", "1", "2", etc.)
            local keyEnum = Enum.KeyCode[clickTarget]
            if keyEnum and VirtualInputManager then
                VirtualInputManager:SendKeyEvent(true, keyEnum, false, game)
                task.wait(0.01)
                VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
            end
        end
    end

    -- Listener da Tecla de Ativação da Camada 2 (SÓ FUNCIONA SE A CAMADA 1 ESTIVER LIGADA!)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not mainEnabled then return end -- SEM O INTERRUPTOR LIGADO, APERTAR A TECLA NÃO FAZ NADA!

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == triggerKey then
            keybindActive = not keybindActive
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not mainEnabled or not keybindActive then return end

        local now = os.clock()
        if now - lastClickTime >= clickInterval then
            lastClickTime = now
            task.spawn(PerformClick)
        end
    end)

    function AutoClicker:SetMainEnabled(v)
        mainEnabled = v
        if not v then keybindActive = false end
    end
    function AutoClicker:IsMainEnabled() return mainEnabled end

    function AutoClicker:SetTriggerKey(key) triggerKey = key end
    function AutoClicker:GetTriggerKey() return triggerKey end

    function AutoClicker:SetClickTarget(target) clickTarget = target end
    function AutoClicker:GetClickTarget() return clickTarget end

    function AutoClicker:SetIntervalMS(ms)
        local num = tonumber(ms) or 50
        clickInterval = math.max(0.001, num / 1000)
    end
    function AutoClicker:GetIntervalMS() return math.floor(clickInterval * 1000 + 0.5) end

    return AutoClicker
end)()

-- [4] ESP CORE
local ESPCore = (function()
    if not Drawing then return {} end
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ESPCore = {}
    local isEnabled = false

    local drawingPool = {Boxes = {}, NameTags = {}, HealthBars = {}, Tracers = {}}
    local playerDrawings = {}

    local function GetDrawingFromPool(type)
        local pool
        if type == "Square" then pool = drawingPool.Boxes
        elseif type == "Text" then pool = drawingPool.NameTags
        elseif type == "HealthBar" then pool = drawingPool.HealthBars
        elseif type == "Line" then pool = drawingPool.Tracers end
        
        if pool and #pool > 0 then return table.remove(pool) end
        
        local drawType = (type == "HealthBar") and "Square" or type
        local drawing = Drawing.new(drawType)
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
        elseif type == "HealthBar" then
            drawing.Filled = true
            drawing.Thickness = 0 -- No outline for the bar itself
            drawing.Transparency = 0.6
        elseif type == "Line" then
            drawing.Thickness = 1.5
            drawing.Transparency = 1
        end
        return drawing
    end

    local function ReturnDrawingToPool(type, drawing)
        if not drawing then return end
        drawing.Visible = false
        local pool
        if type == "Square" then pool = drawingPool.Boxes
        elseif type == "Text" then pool = drawingPool.NameTags
        elseif type == "HealthBar" then pool = drawingPool.HealthBars
        elseif type == "Line" then pool = drawingPool.Tracers end
        
        if pool then table.insert(pool, drawing) end
    end

    local function GetTeamColor(player)
        return TeamManager.GetPlayerColor(player)
    end

    local function CreateDrawings(playerName)
        if playerDrawings[playerName] then return playerDrawings[playerName] end
        local invSlots = {}
        local invTexts = {}
        for i = 1, 9 do
            local sq = Drawing.new("Square")
            sq.Visible = false
            sq.Thickness = 1
            sq.Filled = true
            table.insert(invSlots, sq)

            local txt = Drawing.new("Text")
            txt.Visible = false
            txt.Center = true
            txt.Outline = true
            txt.OutlineColor = Color3.new(0, 0, 0)
            txt.Size = 10
            table.insert(invTexts, txt)
        end

        local drawings = {
            Box = GetDrawingFromPool("Square"), 
            NameTag = GetDrawingFromPool("Text"),
            HealthBg = GetDrawingFromPool("HealthBar"),
            HealthFg = GetDrawingFromPool("HealthBar"),
            Tracer = GetDrawingFromPool("Line"),
            InvSlots = invSlots,
            InvTexts = invTexts
        }
        playerDrawings[playerName] = drawings
        return drawings
    end

    local function RemoveDrawings(playerName)
        local drawings = playerDrawings[playerName]
        if drawings then
            if drawings.Box then ReturnDrawingToPool("Square", drawings.Box) end
            if drawings.NameTag then ReturnDrawingToPool("Text", drawings.NameTag) end
            if drawings.HealthBg then ReturnDrawingToPool("HealthBar", drawings.HealthBg) end
            if drawings.HealthFg then ReturnDrawingToPool("HealthBar", drawings.HealthFg) end
            if drawings.Tracer then ReturnDrawingToPool("Line", drawings.Tracer) end
            if drawings.InvSlots then
                for _, s in ipairs(drawings.InvSlots) do pcall(function() s:Remove() end) end
            end
            if drawings.InvTexts then
                for _, t in ipairs(drawings.InvTexts) do pcall(function() t:Remove() end) end
            end
            playerDrawings[playerName] = nil
        end
    end

    local function UpdateESP()
        if not isEnabled then
            for _, drawings in pairs(playerDrawings) do 
                drawings.Box.Visible = false
                drawings.NameTag.Visible = false
                drawings.HealthBg.Visible = false
                drawings.HealthFg.Visible = false
                drawings.Tracer.Visible = false
                if drawings.InvSlots then
                    for i = 1, 9 do
                        drawings.InvSlots[i].Visible = false
                        drawings.InvTexts[i].Visible = false
                    end
                end
            end
            return
        end
        local camera = workspace.CurrentCamera
        if not camera then return end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local drawings = playerDrawings[player.Name]
                if character then
                    local root = character:FindFirstChild("HumanoidRootPart")
                    local head = character:FindFirstChild("Head")
                    local humanoid = character:FindFirstChild("Humanoid")
                    if root and head and (not humanoid or humanoid.Health > 0) then
                        if not drawings then drawings = CreateDrawings(player.Name) end
                        local rootPos, rootVis = camera:WorldToViewportPoint(root.Position)
                        if rootVis then
                            local headPos, _ = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local legPos, _ = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                            local boxHeight = math.abs(headPos.Y - legPos.Y)
                            local boxWidth = boxHeight * 0.6
                            local boxPos = Vector2.new(rootPos.X - boxWidth/2, headPos.Y)
                            local color = GetTeamColor(player)
                            
                            drawings.Box.Visible = true; drawings.Box.Color = color; drawings.Box.Size = Vector2.new(boxWidth, boxHeight); drawings.Box.Position = boxPos
                            if getgenv().ESPNames then
                                local nameFontSize = math.clamp(tonumber(getgenv().ESPNameSize) or 12, 6, 26)
                                drawings.NameTag.Visible = true
                                drawings.NameTag.Text = player.Name
                                drawings.NameTag.Size = nameFontSize
                                drawings.NameTag.Color = color
                                drawings.NameTag.Position = Vector2.new(rootPos.X, headPos.Y - (nameFontSize + 3))
                            else
                                drawings.NameTag.Visible = false
                            end
                            
                            if getgenv().ESPHealth then
                                local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                                local barWidth = 3
                                local barOffset = 4
                                local barFullHeight = boxHeight
                                local barHeight = barFullHeight * healthPercent
                                local barLostHeight = barFullHeight - barHeight
                                
                                drawings.HealthBg.Visible = barLostHeight > 1 -- Only show if there is significant lost health
                                drawings.HealthBg.Color = Color3.fromRGB(255, 0, 0)
                                drawings.HealthBg.Size = Vector2.new(barWidth, barLostHeight)
                                drawings.HealthBg.Position = Vector2.new(boxPos.X + boxWidth + barOffset, boxPos.Y)
                                
                                drawings.HealthFg.Visible = barHeight > 1 -- Only show if there is health
                                drawings.HealthFg.Color = Color3.fromRGB(0, 255, 0)
                                drawings.HealthFg.Size = Vector2.new(barWidth, barHeight)
                                -- Grow from bottom
                                drawings.HealthFg.Position = Vector2.new(boxPos.X + boxWidth + barOffset, (boxPos.Y + boxHeight) - barHeight)
                            else
                                drawings.HealthBg.Visible = false
                                drawings.HealthFg.Visible = false
                            end

                            -- HAKI DA OBSERVAÇÃO V2 / ESP INVENTÁRIO (BLOXI FRUITS STYLE)
                            if getgenv().ESPInventory then
                                local items = {}
                                pcall(function()
                                    -- 1. Item na mão (Tool equipada)
                                    for _, child in pairs(character:GetChildren()) do
                                        if child:IsA("Tool") then
                                            table.insert(items, {Name = child.Name, Equipped = true})
                                        end
                                    end
                                    -- 2. Itens no Backpack (Mochila / Barra rápida)
                                    local backpack = player:FindFirstChild("Backpack")
                                    if backpack then
                                        for _, item in pairs(backpack:GetChildren()) do
                                            if item:IsA("Tool") and #items < 9 then
                                                table.insert(items, {Name = item.Name, Equipped = false})
                                            end
                                        end
                                    end
                                end)

                                local slotSize = 22
                                local slotSpacing = 4
                                local totalWidth = (#items * slotSize) + (math.max(0, #items - 1) * slotSpacing)
                                local startX = rootPos.X - (totalWidth / 2)
                                local startY = (boxPos.Y + boxHeight) + 8 -- Abaixo do pé do jogador

                                for i = 1, 9 do
                                    local slotBox = drawings.InvSlots[i]
                                    local slotText = drawings.InvTexts[i]

                                    if i <= #items then
                                        local itemData = items[i]
                                        local posX = startX + (i - 1) * (slotSize + slotSpacing)

                                        slotBox.Visible = true
                                        slotBox.Size = Vector2.new(slotSize, slotSize)
                                        slotBox.Position = Vector2.new(posX, startY)
                                        slotBox.Color = itemData.Equipped and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(35, 35, 45)
                                        slotBox.Transparency = 0.85
                                        slotBox.Filled = true

                                        slotText.Visible = true
                                        slotText.Text = string.sub(itemData.Name, 1, 3) -- 3 primeiras letras do item (ex: M9, Tas, Col)
                                        slotText.Size = 10
                                        slotText.Color = itemData.Equipped and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
                                        slotText.Position = Vector2.new(posX + (slotSize / 2), startY + 5)
                                    else
                                        slotBox.Visible = false
                                        slotText.Visible = false
                                    end
                                end
                            else
                                for i = 1, 9 do
                                    drawings.InvSlots[i].Visible = false
                                    drawings.InvTexts[i].Visible = false
                                end
                            end

                            if getgenv().ESPTracers then
                                drawings.Tracer.Visible = true
                                drawings.Tracer.Color = color
                                drawings.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y) -- Bottom Center
                                drawings.Tracer.To = Vector2.new(rootPos.X, rootPos.Y) -- To RootPart
                            else
                                drawings.Tracer.Visible = false
                            end

                        else
                            if drawings then 
                                drawings.Box.Visible = false; drawings.NameTag.Visible = false 
                                drawings.HealthBg.Visible = false; drawings.HealthFg.Visible = false
                                drawings.Tracer.Visible = false
                                for i = 1, 9 do drawings.InvSlots[i].Visible = false; drawings.InvTexts[i].Visible = false end
                            end
                        end
                    else
                        if drawings then 
                            drawings.Box.Visible = false; drawings.NameTag.Visible = false 
                            drawings.HealthBg.Visible = false; drawings.HealthFg.Visible = false
                            drawings.Tracer.Visible = false
                            for i = 1, 9 do drawings.InvSlots[i].Visible = false; drawings.InvTexts[i].Visible = false end
                        end
                    end
                else
                    if drawings then 
                        drawings.Box.Visible = false; drawings.NameTag.Visible = false 
                        drawings.HealthBg.Visible = false; drawings.HealthFg.Visible = false
                        drawings.Tracer.Visible = false
                        for i = 1, 9 do drawings.InvSlots[i].Visible = false; drawings.InvTexts[i].Visible = false end
                    end
                end
            end
        end
    end

    function ESPCore:SetEnabled(enabled)
        isEnabled = enabled
        if getgenv then getgenv().ESPEnabled = enabled end
        if not enabled then for player, _ in pairs(playerDrawings) do RemoveDrawings(player) end end
    end
    function ESPCore:IsEnabled() return isEnabled end
    if getgenv then isEnabled = getgenv().ESPEnabled or false else isEnabled = false end
    Players.PlayerRemoving:Connect(function(player) RemoveDrawings(player.Name) end)
    RunService.RenderStepped:Connect(UpdateESP)
    return ESPCore
end)()

-- [5] HIGH ALERT CORE (Directional Threat Pulse - Estilo COD Warzone)
local HighAlertCore = (function()
    if not Drawing then return {
        SetEnabled = function() end,
        IsEnabled = function() return false end,
        SetTeamCheck = function() end,
        IsTeamCheck = function() return true end,
        Destroy = function() end
    } end

    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local HighAlert = {}
    local isEnabled = false
    local teamCheckEnabled = true

    -- ============================================
    -- CONFIG
    -- ============================================
    local DIST_CLOSE = 50       -- Vermelho: < 50 studs
    local DIST_MEDIUM = 100     -- Amarelo: 50-100 studs
    -- Verde: > 100 studs
    local LOOK_THRESHOLD = 0.82 -- cos(~35°) - cone de visão do inimigo
    local BORDER_THICKNESS = getgenv().HighAlertThickness or 18  -- Espessura da borda pulsante (pixels)
    local PULSE_SPEED = 4       -- Velocidade do pulso
    local MAX_ALPHA = 0.85      -- Transparência máxima do pulso
    local MIN_ALPHA = 0.15      -- Transparência mínima do pulso

    -- Cores por distância
    local COLOR_CLOSE  = Color3.fromRGB(255, 50, 50)    -- Vermelho
    local COLOR_MEDIUM = Color3.fromRGB(255, 200, 0)     -- Amarelo
    local COLOR_FAR    = Color3.fromRGB(50, 255, 100)    -- Verde

    -- ============================================
    -- DRAWING OBJECTS (4 bordas + 4 cantos)
    -- ============================================
    -- Bordas: Top, Bottom, Left, Right
    -- Cada borda é um retângulo fino na extremidade da tela
    local borders = {}
    local borderNames = {"Top", "Bottom", "Left", "Right"}
    for _, name in ipairs(borderNames) do
        local rect = Drawing.new("Square")
        rect.Filled = true
        rect.Visible = false
        rect.Transparency = 0
        rect.Color = COLOR_CLOSE
        rect.Thickness = 0
        borders[name] = rect
    end

    -- Estado por borda: {active, color, distance, alpha}
    local borderState = {}
    for _, name in ipairs(borderNames) do
        borderState[name] = {
            active = false,
            color = COLOR_FAR,
            distance = 9999,
            alpha = 0
        }
    end

    -- ============================================
    -- ARROW/CHEVRON SYSTEM (Seta Direcional Centro)
    -- ============================================
    local arrowEnabled = getgenv().HighAlertArrowEnabled or false
    local ARROW_RADIUS = getgenv().HighAlertArrowRadius or 90   -- Distância do centro da tela
    local ARROW_SIZE = getgenv().HighAlertArrowSize or 22       -- Tamanho do chevron
    local MAX_ARROWS = 10 -- Pool máximo de setas simultâneas

    -- Cada seta é feita de 2 linhas (chevron ">")
    local arrowPool = {}
    for i = 1, MAX_ARROWS do
        local line1 = Drawing.new("Line")
        line1.Visible = false
        line1.Thickness = 3
        line1.Transparency = 1
        line1.Color = COLOR_CLOSE

        local line2 = Drawing.new("Line")
        line2.Visible = false
        line2.Thickness = 3
        line2.Transparency = 1
        line2.Color = COLOR_CLOSE

        arrowPool[i] = {
            line1 = line1,
            line2 = line2,
            active = false
        }
    end

    -- Lista de ameaças detectadas no frame (para setas)
    local detectedThreats = {}

    -- ============================================
    -- HELPER FUNCTIONS
    -- ============================================

    local function IsAlly(targetPlayer)
        if not teamCheckEnabled then return false end
        return TeamManager.IsAlly(targetPlayer)
    end

    local function GetColorByDistance(dist)
        if dist < DIST_CLOSE then
            return COLOR_CLOSE
        elseif dist < DIST_MEDIUM then
            return COLOR_MEDIUM
        else
            return COLOR_FAR
        end
    end

    local function HasLineOfSight(fromPos, toPos, ignoreList)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = ignoreList
        rayParams.IgnoreWater = true

        local direction = (toPos - fromPos)
        local result = workspace:Raycast(fromPos, direction, rayParams)

        -- Se não acertou nada, tem visão direta
        if not result then return true end

        -- Se acertou algo, verificar se é parte do character alvo
        -- (o raycast vai bater no character antes do destino)
        -- Precisamos verificar se a distância do hit é >= ~distância real
        local hitDist = (result.Position - fromPos).Magnitude
        local totalDist = direction.Magnitude

        -- Se o hit está muito perto do destino (dentro de 5 studs), conta como visão
        if totalDist - hitDist < 5 then return true end

        return false
    end

    -- Determina qual borda(s) da tela o inimigo está em relação ao player
    -- Retorna a borda dominante baseado na direção relativa
    local function GetThreatBorder(myRoot, myCF, enemyPos)
        -- Vetor do player para o inimigo em espaço local do player
        local toEnemy = (enemyPos - myRoot.Position)
        local localDir = myCF:VectorToObjectSpace(toEnemy).Unit

        -- localDir.X: positivo = direita, negativo = esquerda
        -- localDir.Z: positivo = costas (atrás), negativo = frente
        -- localDir.Y: cima/baixo (menos relevante)

        local absX = math.abs(localDir.X)
        local absZ = math.abs(localDir.Z)

        -- Determinar borda(s) ativas
        local activeBorders = {}

        -- Componente lateral (Left/Right)
        if absX > 0.3 then
            if localDir.X > 0 then
                table.insert(activeBorders, "Right")
            else
                table.insert(activeBorders, "Left")
            end
        end

        -- Componente frontal/traseiro (Top = frente visual, Bottom = costas)
        -- No Warzone, Bottom = atrás de você
        if absZ > 0.3 then
            if localDir.Z > 0 then
                table.insert(activeBorders, "Bottom") -- Atrás = borda de baixo
            else
                table.insert(activeBorders, "Top")    -- Frente = borda de cima
            end
        end

        -- Se nenhuma borda foi selecionada (improvável), usar a dominante
        if #activeBorders == 0 then
            if absX > absZ then
                table.insert(activeBorders, localDir.X > 0 and "Right" or "Left")
            else
                table.insert(activeBorders, localDir.Z > 0 and "Bottom" or "Top")
            end
        end

        return activeBorders
    end

    -- ============================================
    -- MAIN UPDATE LOOP
    -- ============================================
    local pulseTime = 0
    local renderConnection = nil

    local function UpdateHighAlert(dt)
        if not isEnabled and not arrowEnabled then
            for _, name in ipairs(borderNames) do
                borders[name].Visible = false
                borderState[name].active = false
                borderState[name].alpha = 0
            end
            for _, arrow in ipairs(arrowPool) do
                arrow.line1.Visible = false
                arrow.line2.Visible = false
                arrow.active = false
            end
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewportSize = camera.ViewportSize

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHumanoid = myChar and myChar:FindFirstChild("Humanoid")
        if not myRoot or not myHumanoid or myHumanoid.Health <= 0 then
            for _, name in ipairs(borderNames) do
                borders[name].Visible = false
                borderState[name].active = false
            end
            for _, arrow in ipairs(arrowPool) do
                arrow.line1.Visible = false
                arrow.line2.Visible = false
                arrow.active = false
            end
            return
        end

        local myCF = myRoot.CFrame
        local myPos = myRoot.Position

        -- Reset border states
        for _, name in ipairs(borderNames) do
            borderState[name].active = false
            borderState[name].distance = 9999
        end

        -- Reset threat list para setas
        detectedThreats = {}

        -- Checar todos os jogadores
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if IsAlly(player) then continue end

            local character = player.Character
            if not character then continue end

            local enemyRoot = character:FindFirstChild("HumanoidRootPart")
            local enemyHead = character:FindFirstChild("Head")
            local enemyHumanoid = character:FindFirstChild("Humanoid")

            if not enemyRoot or not enemyHumanoid or enemyHumanoid.Health <= 0 then continue end

            local enemyCF = enemyRoot.CFrame
            local enemyPos = enemyRoot.Position
            local distance = (enemyPos - myPos).Magnitude

            -- 1. Verificar se o inimigo está olhando na nossa direção
            local enemyLookVector = enemyCF.LookVector
            local enemyToMe = (myPos - enemyPos).Unit
            local lookDot = enemyLookVector:Dot(enemyToMe)

            -- Se o dot product for alto, o inimigo está olhando para nós
            if lookDot < LOOK_THRESHOLD then continue end

            -- 2. Verificar linha de visão (Raycast)
            -- Ignorar character do inimigo e nosso character
            local ignoreList = {character}
            if myChar then table.insert(ignoreList, myChar) end

            -- Raycast da cabeça do inimigo até nosso torso
            local eyePos = enemyHead and (enemyHead.Position + Vector3.new(0, 0.5, 0)) or enemyPos
            if not HasLineOfSight(eyePos, myPos, ignoreList) then continue end

            -- 3. Determinar bordas ativas (modo borda)
            if isEnabled then
                local activeBorders = GetThreatBorder(myRoot, myCF, enemyPos)
                local color = GetColorByDistance(distance)

                for _, borderName in ipairs(activeBorders) do
                    local state = borderState[borderName]
                    state.active = true
                    -- Manter o inimigo mais próximo por borda
                    if distance < state.distance then
                        state.distance = distance
                        state.color = color
                    end
                end
            end

            -- 4. Registrar ameaça para seta direcional (modo arrow)
            if arrowEnabled and #detectedThreats < MAX_ARROWS then
                local toEnemy = (enemyPos - myPos)
                local localDir = myCF:VectorToObjectSpace(toEnemy).Unit
                -- Calcular ângulo 2D no plano XZ local (ao redor do player)
                -- atan2(X, Z) onde Z+ = atrás, X+ = direita
                local angle = math.atan2(localDir.X, localDir.Z)
                table.insert(detectedThreats, {
                    angle = angle,
                    distance = distance,
                    color = GetColorByDistance(distance)
                })
            end
        end

        -- ============================================
        -- RENDER BORDERS WITH PULSE
        -- ============================================
        pulseTime = pulseTime + dt * PULSE_SPEED
        local pulseFactor = (math.sin(pulseTime) + 1) / 2 -- 0 a 1 suave
        local currentAlpha = MIN_ALPHA + (MAX_ALPHA - MIN_ALPHA) * pulseFactor

        for _, name in ipairs(borderNames) do
            local state = borderState[name]
            local rect = borders[name]

            if state.active then
                rect.Visible = true
                rect.Color = state.color
                rect.Transparency = currentAlpha

                -- Posicionar retângulo na borda correta
                if name == "Top" then
                    rect.Position = Vector2.new(0, 0)
                    rect.Size = Vector2.new(viewportSize.X, BORDER_THICKNESS)
                elseif name == "Bottom" then
                    rect.Position = Vector2.new(0, viewportSize.Y - BORDER_THICKNESS)
                    rect.Size = Vector2.new(viewportSize.X, BORDER_THICKNESS)
                elseif name == "Left" then
                    rect.Position = Vector2.new(0, 0)
                    rect.Size = Vector2.new(BORDER_THICKNESS, viewportSize.Y)
                elseif name == "Right" then
                    rect.Position = Vector2.new(viewportSize.X - BORDER_THICKNESS, 0)
                    rect.Size = Vector2.new(BORDER_THICKNESS, viewportSize.Y)
                end
            else
                -- Fade out suave
                if rect.Visible then
                    state.alpha = state.alpha - dt * 3
                    if state.alpha <= 0 then
                        state.alpha = 0
                        rect.Visible = false
                    else
                        rect.Transparency = state.alpha
                    end
                end
            end
        end

        -- ============================================
        -- RENDER ARROWS (Setas Direcionais no Centro)
        -- ============================================
        local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

        for i, arrow in ipairs(arrowPool) do
            local threat = detectedThreats[i]
            if threat and arrowEnabled then
                arrow.active = true
                -- Ângulo: 0 = atrás (baixo da tela), PI = frente (cima)
                -- Converter para ângulo de tela: 0 = cima, rotaciona horário
                -- Na tela: Y- = cima, Y+ = baixo, X+ = direita
                -- angle do atan2: 0 = atrás(Z+), PI/2 = direita(X+), PI = frente(Z-), -PI/2 = esquerda(X-)
                -- Para tela: atrás = baixo, frente = cima
                local screenAngle = threat.angle -- Já está correto: 0=baixo, PI=cima

                -- Posição do centro do chevron no círculo ao redor do centro da tela
                local cx = screenCenter.X + math.sin(screenAngle) * ARROW_RADIUS
                local cy = screenCenter.Y + math.cos(screenAngle) * ARROW_RADIUS

                -- Desenhar chevron ">": duas linhas formando um V apontando para fora
                -- O chevron aponta na direção do inimigo (para fora do centro)
                local halfSize = ARROW_SIZE / 2
                local chevronAngle = math.rad(35) -- Abertura do chevron

                -- Direção para fora (do centro para o ponto)
                local outDirX = math.sin(screenAngle)
                local outDirY = math.cos(screenAngle)

                -- Ponta do chevron (mais longe do centro)
                local tipX = cx + outDirX * halfSize * 0.5
                local tipY = cy + outDirY * halfSize * 0.5

                -- Perpendicular para os braços do chevron
                local perpX = -outDirY
                local perpY = outDirX

                -- Ponto traseiro do chevron (mais perto do centro)
                local backX = cx - outDirX * halfSize * 0.5
                local backY = cy - outDirY * halfSize * 0.5

                -- Braço 1: da ponta até canto esquerdo traseiro
                local arm1EndX = backX + perpX * halfSize * 0.6
                local arm1EndY = backY + perpY * halfSize * 0.6

                -- Braço 2: da ponta até canto direito traseiro
                local arm2EndX = backX - perpX * halfSize * 0.6
                local arm2EndY = backY - perpY * halfSize * 0.6

                arrow.line1.From = Vector2.new(tipX, tipY)
                arrow.line1.To = Vector2.new(arm1EndX, arm1EndY)
                arrow.line1.Color = threat.color
                arrow.line1.Transparency = currentAlpha
                arrow.line1.Visible = true

                arrow.line2.From = Vector2.new(tipX, tipY)
                arrow.line2.To = Vector2.new(arm2EndX, arm2EndY)
                arrow.line2.Color = threat.color
                arrow.line2.Transparency = currentAlpha
                arrow.line2.Visible = true
            else
                arrow.line1.Visible = false
                arrow.line2.Visible = false
                arrow.active = false
            end
        end
    end

    -- ============================================
    -- PUBLIC API
    -- ============================================
    function HighAlert:SetEnabled(enabled)
        isEnabled = enabled
        if getgenv then getgenv().HighAlertEnabled = enabled end
        if not enabled then
            for _, name in ipairs(borderNames) do
                borders[name].Visible = false
                borderState[name].active = false
                borderState[name].alpha = 0
            end
        end
    end

    function HighAlert:IsEnabled()
        return isEnabled
    end

    function HighAlert:SetArrowEnabled(enabled)
        arrowEnabled = enabled
        if getgenv then getgenv().HighAlertArrowEnabled = enabled end
        if not enabled then
            for _, arrow in ipairs(arrowPool) do
                arrow.line1.Visible = false
                arrow.line2.Visible = false
                arrow.active = false
            end
        end
    end

    function HighAlert:IsArrowEnabled()
        return arrowEnabled
    end

    function HighAlert:SetArrowRadius(value)
        ARROW_RADIUS = math.clamp(value, 30, 300)
        if getgenv then getgenv().HighAlertArrowRadius = ARROW_RADIUS end
    end

    function HighAlert:GetArrowRadius()
        return ARROW_RADIUS
    end

    function HighAlert:SetArrowSize(value)
        ARROW_SIZE = math.clamp(value, 8, 50)
        if getgenv then getgenv().HighAlertArrowSize = ARROW_SIZE end
    end

    function HighAlert:GetArrowSize()
        return ARROW_SIZE
    end

    function HighAlert:SetTeamCheck(enabled)
        teamCheckEnabled = enabled
        if getgenv then getgenv().HighAlertTeamCheck = enabled end
    end

    function HighAlert:IsTeamCheck()
        return teamCheckEnabled
    end

    function HighAlert:SetBorderThickness(value)
        BORDER_THICKNESS = math.clamp(value, 3, 50)
        if getgenv then getgenv().HighAlertThickness = BORDER_THICKNESS end
    end

    function HighAlert:GetBorderThickness()
        return BORDER_THICKNESS
    end

    function HighAlert:Destroy()
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        for _, name in ipairs(borderNames) do
            if borders[name] then
                borders[name]:Remove()
            end
        end
        for _, arrow in ipairs(arrowPool) do
            if arrow.line1 then arrow.line1:Remove() end
            if arrow.line2 then arrow.line2:Remove() end
        end
    end

    -- Init
    if getgenv then
        isEnabled = getgenv().HighAlertEnabled or false
        teamCheckEnabled = (getgenv().HighAlertTeamCheck == nil) and true or getgenv().HighAlertTeamCheck
    end

    renderConnection = RunService.RenderStepped:Connect(function(dt)
        UpdateHighAlert(dt)
    end)

    return HighAlert
end)()

-- [6] MINIMAP CORE (Radar Arrastável Otimizado & Elevação Multi-Andar)
local MinimapCore = (function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local CoreGui = game:GetService("CoreGui")

    local Minimap = {}
    local isEnabled = false
    local isRound = true
    local isLocked = false
    local isTerrainEnabled = false
    local mapSize = 150
    local mapZoom = 250
    local mapRender = 500 -- Raio de renderização de estruturas (chunks)

    local container = nil
    local mapFrame = nil
    local mapCorner = nil
    local centerBlip = nil
    local blips = {} -- { [Player] = Frame com TextLabel ElevIndicator }
    -- Arquitetura Zero-Flicker: Cache de Sólidos e Object Pool de Frames
    local cachedMapParts = {} -- Array de estruturas {part, pos, size, right}
    local framePool = {} -- Array de UI Frames reutilizáveis
    local activeFrameCount = 0
    local isScanningMap = false
    local lastScanTime = 0
    local lastScanPos = Vector3.new(0, 0, 0) -- Posição da última varredura

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    -- Obter UI Frame do Object Pool sem instanciar/destruir (0% GC Leak / Zero Lag)
    local function getPooledFrame()
        activeFrameCount = activeFrameCount + 1
        local frame = framePool[activeFrameCount]
        if not frame then
            frame = Instance.new("Frame")
            frame.BackgroundColor3 = Color3.fromRGB(90, 90, 95)
            frame.BackgroundTransparency = 0.5
            frame.BorderSizePixel = 1
            frame.BorderColor3 = Color3.fromRGB(40, 40, 45)
            frame.ZIndex = 1
            frame.Parent = mapFrame
            table.insert(framePool, frame)
        end
        return frame
    end

    -- Esconder frames excedentes no pool ao final do frame
    local function cleanUnusedFrames()
        for i = activeFrameCount + 1, #framePool do
            framePool[i].Visible = false
        end
    end

    -- Classificação inteligente de estrutura vs. decoração
    -- Retorna true apenas para partes que são paredes, chão, teto, obstáculos grandes
    local IGNORE_CLASSNAMES = {
        MeshPart = true, -- Geralmente modelos detalhados (roupas, objetos 3D)
        UnionOperation = true, -- CSG unions (decoração complexa, não confiável como estrutura)
    }
    local STRUCTURE_NAMES = {
        wall = true, parede = true, floor = true, chao = true, piso = true,
        ceiling = true, teto = true, roof = true, telhado = true,
        base = true, ground = true, platform = true, plataforma = true,
        barrier = true, barreira = true, door = true, porta = true,
        stair = true, escada = true, ramp = true, rampa = true,
    }

    local function isStructuralPart(part)
        -- Ignorar personagens, ferramentas, acessórios, hats
        local parent = part.Parent
        if not parent then return false end
        if parent:FindFirstChild("Humanoid") then return false end
        if parent:IsA("Accessory") or parent:IsA("Tool") or parent:IsA("Hat") then return false end
        -- Ignorar partes dentro de modelos de personagens (checagem 2 níveis)
        local grandparent = parent.Parent
        if grandparent then
            if grandparent:FindFirstChild("Humanoid") then return false end
            if grandparent:IsA("Accessory") or grandparent:IsA("Tool") or grandparent:IsA("Hat") then return false end
        end

        -- Invisíveis intangíveis
        if part.Transparency >= 1 and not part.CanCollide then return false end

        -- Tamanho mínimo: pelo menos 2 studs em X ou Z, e 0.5 de altura
        local sx, sy, sz = part.Size.X, part.Size.Y, part.Size.Z
        if (sx < 2 and sz < 2) then return false end
        if sy < 0.5 then return false end
        -- Tamanho máximo: evitar terreno gigante
        if sx > 2048 or sz > 2048 then return false end

        -- MeshParts geralmente são modelos detalhados EXCETO se forem grandes (paredes modulares)
        -- Peças pequenas de MeshPart/Union são quase sempre decoração
        if IGNORE_CLASSNAMES[part.ClassName] then
            local footprint = sx * sz
            -- Só aceita MeshParts/Unions grandes (>= 16 studs² de footprint = parede real)
            if footprint < 16 then return false end
        end

        -- Nome heurístico: se o nome parece estrutural, aceitar sempre
        local lowerName = string.lower(part.Name)
        for keyword, _ in pairs(STRUCTURE_NAMES) do
            if string.find(lowerName, keyword) then return true end
        end

        -- Peça ancorada com colisão e tamanho razoável = provavelmente estrutura
        if part.CanCollide then return true end

        -- Peça ancorada sem colisão mas grande = provavelmente chão/plataforma visual
        if sx >= 4 or sz >= 4 then return true end

        return false
    end

    -- Varredura de Sólidos do Mapa baseada em Render Distance (estilo Chunks)
    -- Só cacheia parts dentro do raio de render ao redor do jogador
    local function ScanMapTerrain(forcePos)
        if not isTerrainEnabled or isScanningMap then return end
        isScanningMap = true

        local myChar = LocalPlayer.Character
        local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head"))
        local scanCenter = forcePos or (myRoot and myRoot.Position) or Vector3.new(0, 0, 0)

        local renderDist = mapRender
        local renderDistSq = renderDist * renderDist

        local newCache = {}
        local count = 0

        for _, v in pairs(workspace:GetDescendants()) do
            count = count + 1
            if count % 500 == 0 then task.wait() end

            if v:IsA("BasePart") and v.Anchored then
                -- Filtro de distância (Render Chunks): só parts dentro do raio
                local pos = v.Position
                local dx = pos.X - scanCenter.X
                local dz = pos.Z - scanCenter.Z
                local distSq = dx * dx + dz * dz
                if distSq > renderDistSq then continue end

                -- Filtro inteligente de estrutura
                if not isStructuralPart(v) then continue end

                table.insert(newCache, {
                    part = v,
                    pos = pos,
                    size = v.Size,
                    right = v.CFrame.RightVector
                })
            end
        end

        -- Troca atômica do cache em memória sem apagar a tela
        cachedMapParts = newCache
        lastScanTime = tick()
        lastScanPos = scanCenter
        isScanningMap = false
    end

    -- Inicializa a GUI
    local function initUI()
        if container then return end

        local targetGui = CoreGui:FindFirstChild("DreeZyVoidware") or CoreGui:FindFirstChild("RobloxGui")
        if not targetGui then return end

        container = Instance.new("Frame")
        container.Name = "DreeZyMinimap"
        container.Size = UDim2.new(0, mapSize, 0, mapSize)
        container.Position = UDim2.new(1, -mapSize - 20, 0, 20)
        container.BackgroundTransparency = 1
        container.Active = true
        container.Parent = targetGui

        local successCanvas = pcall(function()
            mapFrame = Instance.new("CanvasGroup")
        end)
        if not successCanvas or not mapFrame then
            mapFrame = Instance.new("Frame")
        end
        mapFrame.Size = UDim2.new(1, 0, 1, 0)
        mapFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        mapFrame.BackgroundTransparency = 0.3
        mapFrame.BorderSizePixel = 2
        mapFrame.BorderColor3 = Color3.fromRGB(150, 150, 150)
        mapFrame.ClipsDescendants = true
        mapFrame.Parent = container

        mapCorner = Instance.new("UICorner")
        mapCorner.CornerRadius = UDim.new(1, 0)
        mapCorner.Parent = mapFrame

        centerBlip = Instance.new("Frame")
        centerBlip.Size = UDim2.new(0, 6, 0, 6)
        centerBlip.Position = UDim2.new(0.5, -3, 0.5, -3)
        centerBlip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        centerBlip.ZIndex = 5
        centerBlip.Parent = mapFrame

        local centerCorner = Instance.new("UICorner")
        centerCorner.CornerRadius = UDim.new(1, 0)
        centerCorner.Parent = centerBlip
        
        -- Campo de visão "cone" simulado
        local dirLine = Instance.new("Frame")
        dirLine.Size = UDim2.new(0, 2, 0, 15)
        dirLine.Position = UDim2.new(0.5, -1, 0.5, -15)
        dirLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dirLine.BackgroundTransparency = 0.5
        dirLine.BorderSizePixel = 0
        dirLine.ZIndex = 4
        dirLine.Parent = mapFrame

        -- Drag Logic
        container.InputBegan:Connect(function(input)
            if isLocked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = container.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        container.InputChanged:Connect(function(input)
            if isLocked then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        -- Listener global para drag suave
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and not isLocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                dragInput = input
            end
        end)
    end

    local function updateDrag()
        if isLocked then dragging = false return end
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            container.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end

    local function getTeamColor(player)
        if player.TeamColor then return player.TeamColor.Color end
        if player.Team and player.Team.TeamColor then return player.Team.TeamColor.Color end
        
        if player ~= LocalPlayer then
             if LocalPlayer.Team then
                 return Color3.fromRGB(255, 50, 50)
             end
        end
        return Color3.fromRGB(255, 50, 50) 
    end

    local function createBlip(player)
        if blips[player] then return blips[player] end

        local blip = Instance.new("Frame")
        blip.Size = UDim2.new(0, 6, 0, 6)
        blip.BackgroundColor3 = getTeamColor(player)
        blip.BorderSizePixel = 1
        blip.BorderColor3 = Color3.fromRGB(0, 0, 0)
        blip.ZIndex = 3
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = blip

        -- Indicador de Elevação Multi-Andar (Opção B: ▲ / ▼)
        local elevLabel = Instance.new("TextLabel")
        elevLabel.Name = "ElevIndicator"
        elevLabel.Size = UDim2.new(1, 0, 1, 0)
        elevLabel.Position = UDim2.new(0, 0, 0, 0)
        elevLabel.BackgroundTransparency = 1
        elevLabel.Font = Enum.Font.GothamBold
        elevLabel.TextSize = 9
        elevLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        elevLabel.Text = ""
        elevLabel.ZIndex = 4
        elevLabel.Parent = blip

        blip.Parent = mapFrame
        blips[player] = blip
        return blip
    end

    local function removeBlip(player)
        if blips[player] then
            blips[player]:Destroy()
            blips[player] = nil
        end
    end

    local function updateMap()
        if not isEnabled or not mapFrame then return end
        
        updateDrag()

        local myChar = LocalPlayer.Character
        local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head"))
        if not myRoot then
            for _, blip in pairs(blips) do blip.Visible = false end
            cleanUnusedFrames()
            return
        end

        local myPos = myRoot.Position
        local camera = workspace.CurrentCamera
        local camLook = camera.CFrame.LookVector
        local camLookFlat = Vector3.new(camLook.X, 0, camLook.Z)
        if camLookFlat.Magnitude > 0.001 then
            camLookFlat = camLookFlat.Unit
        else
            camLookFlat = Vector3.new(0, 0, -1)
        end
        local camRight = Vector3.new(-camLookFlat.Z, 0, camLookFlat.X)
        local mapScale = (mapSize / 2) / mapZoom

        -- Re-scan inteligente baseado em render distance:
        -- 1) Cache vazio -> scan imediato
        -- 2) Jogador andou mais de 30% do render -> re-scan incremental
        -- 3) Timeout de 60 segundos como fallback
        if isTerrainEnabled then
            local needsScan = false
            if #cachedMapParts == 0 then
                needsScan = true
            elseif (tick() - lastScanTime) > 60 then
                needsScan = true
            else
                local moveDist = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(lastScanPos.X, 0, lastScanPos.Z)).Magnitude
                if moveDist > mapRender * 0.3 then
                    needsScan = true
                end
            end
            if needsScan then
                task.spawn(ScanMapTerrain)
            end
        end

        -- Renderizar Terreno Instantâneo com Object Pool (ZERO FLICKERING / ZERO APAGÕES)
        activeFrameCount = 0
        if isTerrainEnabled and #cachedMapParts > 0 then
            local maxRadius = mapZoom * 1.15

            for _, data in ipairs(cachedMapParts) do
                local part = data.part
                if not part or not part.Parent then continue end

                -- FILTRO 1: Altura do mesmo andar! Apenas o andar do jogador (±7.5 studs)
                local yDiff = math.abs(data.pos.Y - myPos.Y)
                if yDiff > 7.5 then continue end

                -- FILTRO 2: Distância no raio do Zoom atual do minimapa
                local offset = data.pos - myPos
                local relX = offset:Dot(camRight)
                local relZ = offset:Dot(camLookFlat)

                if math.abs(relX) <= maxRadius and math.abs(relZ) <= maxRadius then
                    local frame = getPooledFrame()
                    local uiX = relX * mapScale
                    local uiY = -relZ * mapScale

                    local sx = math.max(2, data.size.X * mapScale)
                    local sy = math.max(2, data.size.Z * mapScale)

                    frame.Size = UDim2.new(0, sx, 0, sy)
                    frame.Position = UDim2.new(0.5, uiX - (sx/2), 0.5, uiY - (sy/2))

                    -- Rotação exata projetada via RightVector da peça
                    local rx = data.right:Dot(camRight)
                    local rz = data.right:Dot(camLookFlat)
                    frame.Rotation = math.deg(math.atan2(-rz, rx))
                    frame.Visible = true
                end
            end
        end
        cleanUnusedFrames()

        -- Renderizar TODOS os Jogadores até a distância total de Zoom
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end

            local character = player.Character
            local enemyRoot = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head"))
            local humanoid = character and character:FindFirstChild("Humanoid")

            if not enemyRoot or not humanoid or humanoid.Health <= 0 then
                if blips[player] then blips[player].Visible = false end
                continue
            end

            local enemyPos = enemyRoot.Position
            local dist = (Vector3.new(enemyPos.X, 0, enemyPos.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude

            local blip = createBlip(player)
            blip.BackgroundColor3 = getTeamColor(player)

            if dist > mapZoom then
                blip.Visible = false
            else
                blip.Visible = true
                
                local offset = enemyPos - myPos
                local relX = offset:Dot(camRight)
                local relZ = offset:Dot(camLookFlat)

                local uiX = relX * mapScale
                local uiY = -relZ * mapScale

                -- Sistema de Elevação Multi-Andar em Blips (Opção B)
                local yDiff = enemyPos.Y - myPos.Y
                local absY = math.abs(yDiff)
                local elevLabel = blip:FindFirstChild("ElevIndicator")

                -- Deadzone de 8 studs (muro/degrau = mesmo nível)
                if absY <= 8 then
                    blip.Size = UDim2.new(0, 6, 0, 6)
                    blip.Position = UDim2.new(0.5, uiX - 3, 0.5, uiY - 3)
                    if elevLabel then elevLabel.Text = "" end
                else
                    blip.Size = UDim2.new(0, 10, 0, 10)
                    blip.Position = UDim2.new(0.5, uiX - 5, 0.5, uiY - 5)

                    if elevLabel then
                        if yDiff > 8 then
                            if absY > 22 then
                                elevLabel.Text = "▲▲"
                                elevLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
                            else
                                elevLabel.Text = "▲"
                                elevLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            end
                        else
                            if absY > 22 then
                                elevLabel.Text = "▼▼"
                                elevLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
                            else
                                elevLabel.Text = "▼"
                                elevLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                            end
                        end
                    end
                end
            end
        end
        
        -- Limpar blips de jogadores que saíram
        local toRemoveBlips = {}
        for p, blip in pairs(blips) do
            if not p.Parent then
                table.insert(toRemoveBlips, p)
            end
        end
        for _, p in ipairs(toRemoveBlips) do
            removeBlip(p)
        end
    end

    local renderConnection = nil

    function Minimap:SetEnabled(enabled)
        isEnabled = enabled
        if getgenv then getgenv().MinimapEnabled = enabled end
        
        if enabled then
            initUI()
            if container then container.Visible = true end
            if #cachedMapParts == 0 then
                task.spawn(ScanMapTerrain)
            end
            if not renderConnection then
                renderConnection = RunService.RenderStepped:Connect(updateMap)
            end
        else
            if container then container.Visible = false end
            if renderConnection then
                renderConnection:Disconnect()
                renderConnection = nil
            end
        end
    end

    function Minimap:IsEnabled()
        return isEnabled
    end

    function Minimap:SetSize(size)
        mapSize = size
        if getgenv then getgenv().MinimapSize = size end
        if container then
            container.Size = UDim2.new(0, size, 0, size)
        end
    end

    function Minimap:GetSize()
        return mapSize
    end

    function Minimap:SetRound(round)
        isRound = round
        if getgenv then getgenv().MinimapRound = round end
        if mapCorner then
            mapCorner.CornerRadius = round and UDim.new(1, 0) or UDim.new(0, 0)
        end
    end

    function Minimap:IsRound()
        return isRound
    end
    
    function Minimap:SetLocked(locked)
        isLocked = locked
        if getgenv then getgenv().MinimapLocked = locked end
    end
    
    function Minimap:IsLocked()
        return isLocked
    end
    
    function Minimap:SetTerrain(enabled)
        isTerrainEnabled = enabled
        if getgenv then getgenv().MinimapTerrain = enabled end
        if enabled then
            if #cachedMapParts == 0 then
                task.spawn(ScanMapTerrain)
            end
        else
            cleanUnusedFrames()
        end
    end
    
    function Minimap:IsTerrain()
        return isTerrainEnabled
    end
    
    function Minimap:SetZoom(zoom)
        mapZoom = zoom
        if getgenv then getgenv().MinimapZoom = zoom end
    end
    
    function Minimap:GetZoom()
        return mapZoom
    end

    function Minimap:SetRender(render)
        mapRender = render
        if getgenv then getgenv().MinimapRender = render end
        -- Re-scan imediato ao alterar render distance
        if isEnabled and isTerrainEnabled then
            task.spawn(ScanMapTerrain)
        end
    end

    function Minimap:GetRender()
        return mapRender
    end

    function Minimap:Destroy()
        if renderConnection then
            renderConnection:Disconnect()
        end
        if container then
            container:Destroy()
        end
    end

    Players.PlayerRemoving:Connect(removeBlip)

    -- Init
    if getgenv then
        mapSize = getgenv().MinimapSize or 150
        isRound = (getgenv().MinimapRound == nil) and true or getgenv().MinimapRound
        isLocked = (getgenv().MinimapLocked == nil) and false or getgenv().MinimapLocked
        isTerrainEnabled = (getgenv().MinimapTerrain == nil) and false or getgenv().MinimapTerrain
        mapZoom = getgenv().MinimapZoom or 250
        mapRender = getgenv().MinimapRender or 500
        
        if getgenv().MinimapEnabled then
            Minimap:SetEnabled(true)
        end
    end

    return Minimap
end)()

-- [2.14] FREE SHIFT LOCK CORE (DESBLOQUEIO DE CORPO NO SHIFTLOCK)
local FreeShiftLockCore = (function()
    local isEnabled = false
    local connection = nil
    local crosshairDot = nil
    local triggerKey = Enum.KeyCode.LeftAlt
    local showCrosshair = true
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local function getCrosshair()
        if not crosshairDot or not crosshairDot.Parent then
            local sg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")
            local gui = Instance.new("ScreenGui")
            gui.Name = "DreezyFreeShiftLockGui"
            gui.ResetOnSpawn = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

            local dot = Instance.new("ImageLabel")
            dot.Name = "Crosshair"
            dot.Size = UDim2.new(0, 16, 0, 16)
            dot.Position = UDim2.new(0.5, -8, 0.5, -8)
            dot.BackgroundTransparency = 1
            dot.Image = "rbxasset://textures/MouseLockedCursor.png"
            dot.ImageColor3 = Color3.fromRGB(255, 255, 255)
            dot.Visible = false
            dot.Parent = gui

            pcall(function()
                if syn and syn.protect_gui then syn.protect_gui(gui) end
                gui.Parent = sg
            end)
            crosshairDot = dot
        end
        return crosshairDot
    end

    local function EnableFreeShiftLock()
        if connection then connection:Disconnect() end
        local dot = getCrosshair()
        dot.Visible = showCrosshair

        connection = RunService.RenderStepped:Connect(function()
            if not isEnabled then return end
            
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    -- Aplica o deslocamento de ombro (Offset padrão 1.75 ou personalizado)
                    local offsetVal = getgenv().FreeShiftLockOffset or 1.75
                    hum.CameraOffset = Vector3.new(offsetVal, 0.25, 0)
                    -- DESBLOQUEIO TOTAL DE CORPO: Força AutoRotate = true para o player virar e correr em 360° livremente
                    hum.AutoRotate = true
                end
            end

            -- Trava o mouse no centro da tela para movimentar a câmera diretamente com o mouse
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end)
    end

    local function DisableFreeShiftLock()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if crosshairDot then
            crosshairDot.Visible = false
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.CameraOffset = Vector3.new(0, 0, 0)
                hum.AutoRotate = true
            end
        end
    end

    -- Listener de tecla rápida para ativar/desativar em jogo
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or getgenv().IsBindingKey then return end
        if triggerKey and input.KeyCode == triggerKey then
            if getgenv().ToggleFreeShiftLockUI then
                getgenv().ToggleFreeShiftLockUI()
            else
                FreeShiftLockCore:SetEnabled(not isEnabled)
            end
        end
    end)

    local Core = {}
    function Core:SetEnabled(state)
        isEnabled = state
        if getgenv then getgenv().FreeShiftLockEnabled = state end
        if state then
            EnableFreeShiftLock()
        else
            DisableFreeShiftLock()
        end
    end
    function Core:IsEnabled()
        return isEnabled
    end
    function Core:SetTriggerKey(key)
        triggerKey = key
    end
    function Core:GetTriggerKey()
        return triggerKey or Enum.KeyCode.LeftAlt
    end
    function Core:SetShowCrosshair(state)
        showCrosshair = state
        if crosshairDot and isEnabled then
            crosshairDot.Visible = state
        end
    end
    function Core:GetShowCrosshair()
        return showCrosshair
    end

    return Core
end)()

-- ==========================================
-- VOIDWARE UI LIBRARY
-- ==========================================
local VoidLib = {}
local function Notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title="DreeZy HUB", Text=tostring(msg), Duration=3})
    end)
end

local Themes = {
    Background = Color3.fromRGB(17, 17, 20),
    Sidebar = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromHex("#B507E0"),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 160),
    Element = Color3.fromRGB(35, 35, 40),
    GroupDB = Color3.fromRGB(25, 25, 30)
}

local HttpService = game:GetService("HttpService")
local FOLDER_NAME = "DreeZyHub"
local FILE_PATH = FOLDER_NAME .. "/Config.json"

local function EnsureFolder()
    if isfolder and makefolder then
        pcall(function()
            if not isfolder(FOLDER_NAME) then
                makefolder(FOLDER_NAME)
            end
        end)
    end
end

local function EncodeData(str)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return ((str:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#str % 3 + 1])
end

local function DecodeData(data)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = string.gsub(data, '[^'..b64..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,b='',b64:find(x)-1
        for i=6,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local ConfigManager = {
    Controls = {},
    Register = function(self, key, controlObj)
        if controlObj then
            self.Controls[key] = controlObj
        end
    end,
    Save = function(self)
        EnsureFolder()
        local data = {}
        for key, control in pairs(self.Controls) do
            if control and control.Get then
                pcall(function()
                    data[key] = control.Get()
                end)
            end
        end
        data["unlockKey"] = getgenv().UnlockMouseKey and getgenv().UnlockMouseKey.Name or "RightControl"

        local successJson, jsonStr = pcall(function()
            return HttpService:JSONEncode(data)
        end)

        if successJson and jsonStr and writefile then
            local success, err = pcall(writefile, FILE_PATH, jsonStr)
            return success
        end
        return false
    end,
    Load = function(self)
        EnsureFolder()
        if isfile and isfile(FILE_PATH) then
            local success, content = pcall(readfile, FILE_PATH)
            if success and content and #content > 0 then
                local decodedData = nil
                -- Tentar decodificar JSON direto
                pcall(function()
                    decodedData = HttpService:JSONDecode(content)
                end)
                -- Fallback se for base64 legado
                if not decodedData then
                    pcall(function()
                        decodedData = HttpService:JSONDecode(DecodeData(content))
                    end)
                end

                if decodedData and type(decodedData) == "table" then
                    for key, val in pairs(decodedData) do
                        local control = self.Controls[key]
                        if control and control.Set then
                            pcall(function() control.Set(val) end)
                        end
                    end
                    if decodedData["unlockKey"] and Enum.KeyCode[decodedData["unlockKey"]] then
                        getgenv().UnlockMouseKey = Enum.KeyCode[decodedData["unlockKey"]]
                    end
                    return true
                end
            end
        end
        return false
    end
}

function VoidLib:CreateWindow()
    if game:GetService("CoreGui"):FindFirstChild("DreeZyVoidware") then game:GetService("CoreGui").DreeZyVoidware:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DreeZyVoidware"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.ResetOnSpawn = false
    
    local UIS = game:GetService("UserInputService")
    local isMobile = UIS.TouchEnabled

    -- >>> PURE ASCII TEXT INTRO ANIMATION (HIGH DETAIL 15 FPS)
    task.spawn(function()
        local Overlay = Instance.new("Frame")
        Overlay.Name = "TransparentOverlay"
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.Position = UDim2.new(0, 0, 0, 0)
        Overlay.BackgroundTransparency = 1 -- 100% TRANSPARENTE!
        Overlay.ZIndex = 10000000
        Overlay.Parent = ScreenGui

        local AsciiTextLabel = Instance.new("TextLabel")
        AsciiTextLabel.Name = "AsciiCatText"
        AsciiTextLabel.Size = UDim2.new(0, 800, 0, 800)
        AsciiTextLabel.Position = UDim2.new(0.5, -400, 0.5, -400)
        AsciiTextLabel.BackgroundTransparency = 1
        AsciiTextLabel.RichText = true
        AsciiTextLabel.Font = Enum.Font.Code -- Fonte monospaçada nativa do Roblox
        AsciiTextLabel.TextColor3 = Color3.fromHex("#D842FF") -- Roxo Neon DreeZy HUB!
        AsciiTextLabel.TextSize = 16 -- Tamanho grande e destacado!
        AsciiTextLabel.TextXAlignment = Enum.TextXAlignment.Center
        AsciiTextLabel.TextYAlignment = Enum.TextYAlignment.Center
        AsciiTextLabel.ZIndex = 10000001
        AsciiTextLabel.Parent = Overlay

        -- Carregar tabela de animação via GitHub Raw
        local url = "https://raw.githubusercontent.com/fraudesnaoseinaosei-max/j4rty678/main/AsciiFramesExact.lua"
        local success, frameData = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)

        local AsciiFrames = success and frameData or {}
        local totalFrames = #AsciiFrames
        local frameDelay = 0.067 -- 15 FPS
        local isSkipped = false

        local conn
        conn = Overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isSkipped = true
            end
        end)

        if totalFrames > 0 then
            for i = 1, totalFrames do
                if isSkipped or not Overlay or not Overlay.Parent then break end
                AsciiTextLabel.Text = AsciiFrames[i]
                task.wait(frameDelay)
            end
        end

        if conn then conn:Disconnect() end

        if Overlay and Overlay.Parent then
            local t = TweenService:Create(AsciiTextLabel, TweenInfo.new(0.4), {TextTransparency = 1})
            t:Play()
            t.Completed:Connect(function()
                if Overlay and Overlay.Parent then Overlay:Destroy() end
            end)
        end
    end)
    
    -- Mobile & Desktop Draggable Helper com Trava Única de Arraste por Header/Barra
    local function MakeDraggable(dragHandle, targetFrame)
        targetFrame = targetFrame or dragHandle
        local dragging, dragInput, dragStart, startPos
        
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if getgenv().CurrentlyDraggingObj == nil or getgenv().CurrentlyDraggingObj == targetFrame then
                    getgenv().CurrentlyDraggingObj = targetFrame
                    dragging = true
                    dragStart = input.Position
                    startPos = targetFrame.Position
                    
                    local conn
                    conn = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            if getgenv().CurrentlyDraggingObj == targetFrame then
                                getgenv().CurrentlyDraggingObj = nil
                            end
                            if conn then conn:Disconnect() end
                        end
                    end)
                end
            end
        end)
        
        dragHandle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging and getgenv().CurrentlyDraggingObj == targetFrame then
                local delta = input.Position - dragStart
                targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if getgenv().CurrentlyDraggingObj == targetFrame then
                    dragging = false
                    getgenv().CurrentlyDraggingObj = nil
                end
            end
        end)
    end

    -- Mobile Toggle Button
    if isMobile then
        local ToggleBtn = Instance.new("ImageButton")
        ToggleBtn.Name = "MobileToggle"
        ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
        ToggleBtn.Position = UDim2.new(1, -70, 0.5, -25) -- Right Center
        ToggleBtn.BackgroundColor3 = Themes.Background
        ToggleBtn.Image = "rbxassetid://6031091004" -- Menu Icon
        ToggleBtn.Parent = ScreenGui
        local TC = Instance.new("UICorner"); TC.CornerRadius = UDim.new(1, 0); TC.Parent = ToggleBtn
        local TS = Instance.new("UIStroke"); TS.Color = Themes.Accent; TS.Thickness = 2; TS.Parent = ToggleBtn
        
        ToggleBtn.MouseButton1Click:Connect(function()
            local MainFrame = ScreenGui:FindFirstChild("Main")
            if MainFrame then MainFrame.Visible = not MainFrame.Visible end
        end)
        
        MakeDraggable(ToggleBtn) -- Make it draggable!
    end

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    if isMobile then
        Main.Size = UDim2.new(0.7, 0, 0.7, 0) -- Responsive for mobile
        Main.Position = UDim2.new(0.15, 0, 0.15, 0)
    else
        Main.Size = UDim2.new(0, 650, 0, 480)
        Main.Position = UDim2.new(0.5, -325, 0.5, -240)
    end
    Main.BackgroundColor3 = Themes.Background
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Themes.Accent
    MainStroke.Transparency = 0.5
    MainStroke.Thickness = 1
    MainStroke.Parent = Main
    
    -- Barra de Arraste Superior Exclusiva do Main HUB (Sem botões X/Minimizar)
    local MainTopDragBar = Instance.new("Frame")
    MainTopDragBar.Name = "MainTopDragBar"
    MainTopDragBar.Size = UDim2.new(1, 0, 0, 32)
    MainTopDragBar.Position = UDim2.new(0, 0, 0, 0)
    MainTopDragBar.BackgroundTransparency = 1
    MainTopDragBar.ZIndex = 95
    MainTopDragBar.Parent = Main

    MakeDraggable(MainTopDragBar, Main)

    -- Snowfall Effect (Enhanced)
    local SnowContainer = Instance.new("Frame")
    SnowContainer.Name = "SnowContainer"
    SnowContainer.Size = UDim2.new(1, 0, 1, 0)
    SnowContainer.BackgroundTransparency = 1
    SnowContainer.ClipsDescendants = true
    SnowContainer.Parent = Main
    
    local function CreateSnow()
        local Snow = Instance.new("Frame")
        local size = math.random(2, 5)
        Snow.Size = UDim2.new(0, size, 0, size)
        Snow.Position = UDim2.new(math.random(), 0, -0.1, 0)
        Snow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Snow.BackgroundTransparency = math.random(0.4, 0.8)
        Snow.BorderSizePixel = 0
        Snow.Parent = SnowContainer
        local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(1,0); Corner.Parent = Snow
        
        local duration = math.random(4, 9)
        local drift = math.random(-30, 30) / 100 -- More drift
        local endPos = UDim2.new(Snow.Position.X.Scale + drift, 0, 1.1, 0)
        
        local Tween = TweenService:Create(Snow, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = endPos})
        Tween:Play()
        Tween.Completed:Connect(function() Snow:Destroy() end)
    end
    task.spawn(function()
        while Main.Parent do
            if math.random() > 0.4 then CreateSnow() end
            task.wait(0.05)
        end
    end)

    -- >>> STARTUP ANIMATION STATE
    Main.Size = UDim2.new(0, 650 * 0.8, 0, 480 * 0.8)
    Main.BackgroundTransparency = 1
    Main.Visible = false
    MainStroke.Transparency = 1
    -- Sidebar elements will also need to fade in, handled by parenting or individual tweens if needed.
    -- For simplicity, we animate Main and its descendants transparency follows if inherited, but for UI it doesn't usually.
    -- We will animate Main Size/Transparency and a "Cover" if needed, but let's just pop it in.

    -- >>> WELCOME MODAL
    local ModalOverlay = Instance.new("Frame")
    ModalOverlay.Name = "WelcomeOverlay"
    ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
    ModalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ModalOverlay.BackgroundTransparency = 0.3
    ModalOverlay.ZIndex = 100
    ModalOverlay.Parent = ScreenGui
    
    local ModalFrame = Instance.new("Frame")
    ModalFrame.Size = UDim2.new(0, 400, 0, 220)
    ModalFrame.Position = UDim2.new(0.5, -200, 0.5, -110)
    ModalFrame.BackgroundColor3 = Themes.Background
    ModalFrame.BorderSizePixel = 0
    ModalFrame.Parent = ModalOverlay
    local MCorner = Instance.new("UICorner"); MCorner.CornerRadius = UDim.new(0, 12); MCorner.Parent = ModalFrame
    local MStroke = Instance.new("UIStroke"); MStroke.Color = Themes.Accent; MStroke.Thickness = 1; MStroke.Parent = ModalFrame

    local MTitle = Instance.new("TextLabel")
    MTitle.Text = "Bem-vindo ao DreeZy HUB"
    MTitle.Font = Enum.Font.GothamBold
    MTitle.TextSize = 20
    MTitle.TextColor3 = Themes.Accent
    MTitle.Size = UDim2.new(1, 0, 0, 50)
    MTitle.BackgroundTransparency = 1
    MTitle.Parent = ModalFrame

    local MDesc = Instance.new("TextLabel")
    MDesc.Text = "Este script possui funcionalidades avançadas de PvP e Visual.\n\n⚠️ IMPORTANTE ⚠️\nUse a tecla [RIGHT SHIFT] para Minimizar ou Maximizar o menu a qualquer momento."
    MDesc.Font = Enum.Font.Gotham
    MDesc.TextSize = 14
    MDesc.TextColor3 = Themes.Text
    MDesc.Size = UDim2.new(1, -40, 0, 100)
    MDesc.Position = UDim2.new(0, 20, 0, 50)
    MDesc.BackgroundTransparency = 1
    MDesc.TextWrapped = true
    MDesc.Parent = ModalFrame

    local MBtn = Instance.new("TextButton")
    MBtn.Text = "ENTENDI"
    MBtn.Font = Enum.Font.GothamBold
    MBtn.TextSize = 14
    MBtn.TextColor3 = Themes.Text
    MBtn.BackgroundColor3 = Themes.Accent
    MBtn.Size = UDim2.new(0, 120, 0, 35)
    MBtn.Position = UDim2.new(0.5, -60, 1, -50)
    MBtn.Parent = ModalFrame
    local MBtnCorner = Instance.new("UICorner"); MBtnCorner.CornerRadius = UDim.new(0, 6); MBtnCorner.Parent = MBtn

    MBtn.MouseButton1Click:Connect(function()
        -- Close Modal
        local closeTween = TweenService:Create(ModalOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        
        -- Manual Fade Out since CanvasGroup/GroupTransparency is failing on this executor
        for _, v in pairs(ModalFrame:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                TweenService:Create(v, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            elseif v:IsA("UIStroke") then
                TweenService:Create(v, TweenInfo.new(0.3), {Transparency = 1}):Play()
            end
        end
        
        TweenService:Create(ModalFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -200, 0.5, -130), BackgroundTransparency = 1}):Play() -- Float up
        closeTween:Play()
        closeTween.Completed:Connect(function() ModalOverlay:Destroy() end)

        -- Startup Animation for Main
        -- Startup Animation for Main
        Main.Visible = true
        if isMobile then
             TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.7, 0, 0.7, 0)}):Play()
        else
             TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 650, 0, 480)}):Play()
        end
        TweenService:Create(Main, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
        TweenService:Create(MainStroke, TweenInfo.new(0.5), {Transparency = 0.5}):Play()
    end)

    -- Sidebar (restored)
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 170, 1, 0)
    Sidebar.BackgroundColor3 = Themes.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Main
    local SidebarCorner = Instance.new("UICorner"); SidebarCorner.CornerRadius = UDim.new(0, 10); SidebarCorner.Parent = Sidebar
    local SidebarFix = Instance.new("Frame"); SidebarFix.Size = UDim2.new(0,10,1,0); SidebarFix.Position = UDim2.new(1,-10,0,0); SidebarFix.BackgroundColor3 = Themes.Sidebar; SidebarFix.BorderSizePixel = 0; SidebarFix.Parent = Sidebar

    local Title = Instance.new("TextLabel")
    Title.Text = "  DreeZy HUB"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
    Title.TextColor3 = Themes.Accent
    Title.Size = UDim2.new(1, 0, 0, 60)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Sidebar
    
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, 0, 1, -120)
    TabContainer.Position = UDim2.new(0, 0, 0, 60)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar
    local TabList = Instance.new("UIListLayout"); TabList.Padding = UDim.new(0, 5); TabList.SortOrder = Enum.SortOrder.LayoutOrder; TabList.Parent = TabContainer

    -- Profile Section
    local Profile = Instance.new("Frame")
    Profile.Size = UDim2.new(1, -20, 0, 50)
    Profile.Position = UDim2.new(0, 10, 1, -60)
    Profile.BackgroundColor3 = Color3.fromRGB(30,30,35)
    Profile.BorderSizePixel = 0
    Profile.ClipsDescendants = true
    Profile.Parent = Sidebar
    local ProfCorner = Instance.new("UICorner"); ProfCorner.CornerRadius = UDim.new(0, 8); ProfCorner.Parent = Profile
    
    local ProfImg = Instance.new("ImageLabel")
    ProfImg.Size = UDim2.new(0, 36, 0, 36)
    ProfImg.Position = UDim2.new(0, 7, 0.5, -18)
    ProfImg.BackgroundColor3 = Color3.fromRGB(50,50,50)
    ProfImg.Parent = Profile
    local ImgCorner = Instance.new("UICorner"); ImgCorner.CornerRadius = UDim.new(1, 0); ImgCorner.Parent = ProfImg
    task.spawn(function()
        local content = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        ProfImg.Image = content
    end)
    
    local ProfName = Instance.new("TextLabel")
    ProfName.Text = player.DisplayName
    ProfName.Size = UDim2.new(1, -55, 0.5, 0)
    ProfName.Position = UDim2.new(0, 50, 0, 5)
    ProfName.BackgroundTransparency = 1
    ProfName.Font = Enum.Font.GothamBold
    ProfName.TextSize = 12
    ProfName.TextColor3 = Themes.Text
    ProfName.TextXAlignment = Enum.TextXAlignment.Left
    ProfName.TextTruncate = Enum.TextTruncate.AtEnd
    ProfName.Parent = Profile
    
    local ProfSub = Instance.new("TextLabel")
    ProfSub.Text = "@" .. player.Name
    ProfSub.Size = UDim2.new(1, -55, 0.5, 0)
    ProfSub.Position = UDim2.new(0, 50, 0.5, -2)
    ProfSub.BackgroundTransparency = 1
    ProfSub.Font = Enum.Font.Gotham
    ProfSub.TextSize = 10
    ProfSub.TextColor3 = Themes.TextDim
    ProfSub.TextXAlignment = Enum.TextXAlignment.Left
    ProfSub.TextTruncate = Enum.TextTruncate.AtEnd
    ProfSub.Parent = Profile

    -- Content Area
    local Pages = Instance.new("Frame")
    Pages.Size = UDim2.new(1, -170, 1, -20)
    Pages.Position = UDim2.new(0, 170, 0, 20)
    Pages.BackgroundTransparency = 1
    Pages.Parent = Main

    local Window = {Tabs = {}}

    -- Persistência de Favoritos e Ordem Personalizada (DreeZyHub/Favorites.json)
    getgenv().FavoritedMods = getgenv().FavoritedMods or {}
    getgenv().FavoritedOrder = getgenv().FavoritedOrder or {}

    local function EnsureFavoritedOrder()
        getgenv().FavoritedOrder = getgenv().FavoritedOrder or {}
        for modName, isFav in pairs(getgenv().FavoritedMods) do
            if isFav and not table.find(getgenv().FavoritedOrder, modName) then
                table.insert(getgenv().FavoritedOrder, modName)
            end
        end
        for i = #getgenv().FavoritedOrder, 1, -1 do
            local mName = getgenv().FavoritedOrder[i]
            if not getgenv().FavoritedMods[mName] then
                table.remove(getgenv().FavoritedOrder, i)
            end
        end
    end

    local function SaveFavoritesToFile()
        pcall(function()
            if writefile then
                if isfolder and makefolder and not isfolder("DreeZyHub") then
                    makefolder("DreeZyHub")
                end
                EnsureFavoritedOrder()
                local payload = {
                    Mods = getgenv().FavoritedMods or {},
                    Order = getgenv().FavoritedOrder or {}
                }
                local dataStr = game:GetService("HttpService"):JSONEncode(payload)
                writefile("DreeZyHub/Favorites.json", dataStr)
            end
        end)
    end

    local function LoadFavoritesFromFile()
        pcall(function()
            if isfile and readfile and isfile("DreeZyHub/Favorites.json") then
                local dataStr = readfile("DreeZyHub/Favorites.json")
                local decoded = game:GetService("HttpService"):JSONDecode(dataStr)
                if type(decoded) == "table" then
                    if decoded.Order and type(decoded.Order) == "table" then
                        getgenv().FavoritedOrder = decoded.Order
                        getgenv().FavoritedMods = decoded.Mods or {}
                    else
                        getgenv().FavoritedMods = decoded
                        getgenv().FavoritedOrder = {}
                        for k, v in pairs(decoded) do
                            if v then table.insert(getgenv().FavoritedOrder, k) end
                        end
                    end
                end
            end
        end)
    end

    LoadFavoritesFromFile()

    -- HUD Flutuante Redimensionável dos Mods Favoritos
    local FavHUDFrame = Instance.new("Frame")
    FavHUDFrame.Name = "DreeZyFavHUD"
    FavHUDFrame.Size = UDim2.new(0, 320, 0, 240)
    FavHUDFrame.Position = UDim2.new(0.5, -160, 0.4, -120)
    FavHUDFrame.BackgroundColor3 = Themes.Background
    FavHUDFrame.BorderSizePixel = 0
    FavHUDFrame.ZIndex = 888880
    FavHUDFrame.Visible = false
    FavHUDFrame.Parent = ScreenGui

    local FavCorner = Instance.new("UICorner"); FavCorner.CornerRadius = UDim.new(0, 10); FavCorner.Parent = FavHUDFrame
    local FavStroke = Instance.new("UIStroke"); FavStroke.Color = Themes.Accent; FavStroke.Thickness = 1; FavStroke.Transparency = 0.4; FavStroke.Parent = FavHUDFrame

    -- Header do HUD
    local FavHeader = Instance.new("Frame")
    FavHeader.Size = UDim2.new(1, 0, 0, 36)
    FavHeader.BackgroundColor3 = Themes.Sidebar
    FavHeader.BorderSizePixel = 0
    FavHeader.ZIndex = 888881
    FavHeader.Parent = FavHUDFrame
    local FHC = Instance.new("UICorner"); FHC.CornerRadius = UDim.new(0, 10); FHC.Parent = FavHeader
    local FHF = Instance.new("Frame"); FHF.Size = UDim2.new(1, 0, 0, 10); FHF.Position = UDim2.new(0, 0, 1, -10); FHF.BackgroundColor3 = Themes.Sidebar; FHF.BorderSizePixel = 0; FHF.ZIndex = 888881; FHF.Parent = FavHeader

    MakeDraggable(FavHeader, FavHUDFrame)

    local FavTitle = Instance.new("TextLabel")
    FavTitle.Text = "★ Acesso Rápido (Favoritos)"
    FavTitle.Font = Enum.Font.GothamBold
    FavTitle.TextSize = 13
    FavTitle.TextColor3 = Themes.Accent
    FavTitle.Size = UDim2.new(1, -50, 1, 0)
    FavTitle.Position = UDim2.new(0, 12, 0, 0)
    FavTitle.BackgroundTransparency = 1
    FavTitle.TextXAlignment = Enum.TextXAlignment.Left
    FavTitle.ZIndex = 888882
    FavTitle.Parent = FavHeader

    -- Botão X de Fechar
    local FavCloseBtn = Instance.new("TextButton")
    FavCloseBtn.Text = "X"
    FavCloseBtn.Font = Enum.Font.GothamBold
    FavCloseBtn.TextSize = 12
    FavCloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    FavCloseBtn.BackgroundColor3 = Color3.fromRGB(55, 25, 30)
    FavCloseBtn.Size = UDim2.new(0, 22, 0, 22)
    FavCloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
    FavCloseBtn.ZIndex = 888883
    FavCloseBtn.Parent = FavHeader
    local FCC = Instance.new("UICorner"); FCC.CornerRadius = UDim.new(0, 6); FCC.Parent = FavCloseBtn
    FavCloseBtn.MouseButton1Click:Connect(function() FavHUDFrame.Visible = false end)

    -- Container de Rolagem dos Elementos Favoritados
    local FavContent = Instance.new("ScrollingFrame")
    FavContent.Size = UDim2.new(1, -16, 1, -48)
    FavContent.Position = UDim2.new(0, 8, 0, 40)
    FavContent.BackgroundTransparency = 1
    FavContent.BorderSizePixel = 0
    FavContent.ScrollBarThickness = 2
    FavContent.ScrollBarImageColor3 = Themes.Accent
    FavContent.ZIndex = 888881
    FavContent.Parent = FavHUDFrame

    local FavLayout = Instance.new("UIListLayout"); FavLayout.Padding = UDim.new(0, 6); FavLayout.SortOrder = Enum.SortOrder.LayoutOrder; FavLayout.Parent = FavContent
    local FavPad = Instance.new("UIPadding"); FavPad.PaddingTop = UDim.new(0, 4); FavPad.PaddingBottom = UDim.new(0, 8); FavPad.PaddingLeft = UDim.new(0, 4); FavPad.PaddingRight = UDim.new(0, 8); FavPad.Parent = FavContent

    FavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        FavContent.CanvasSize = UDim2.new(0, 0, 0, FavLayout.AbsoluteContentSize.Y + 12)
    end)

    -- 2 Rabiscos // no canto inferior direito para redimensionar
    local ResizeGrip = Instance.new("TextButton")
    ResizeGrip.Text = "//"
    ResizeGrip.Font = Enum.Font.GothamBold
    ResizeGrip.TextSize = 12
    ResizeGrip.TextColor3 = Themes.Accent
    ResizeGrip.Size = UDim2.new(0, 20, 0, 20)
    ResizeGrip.Position = UDim2.new(1, -20, 1, -20)
    ResizeGrip.BackgroundTransparency = 1
    ResizeGrip.ZIndex = 888885
    ResizeGrip.Parent = FavHUDFrame

    -- Lógica de Redimensionamento ao arrastar os 2 rabiscos (ResizeGrip)
    local isResizing = false
    local startMousePos, startSize

    ResizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isResizing = true
            startMousePos = UserInputService:GetMouseLocation()
            startSize = FavHUDFrame.AbsoluteSize
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local currentMouse = UserInputService:GetMouseLocation()
            local deltaX = currentMouse.X - startMousePos.X
            local deltaY = currentMouse.Y - startMousePos.Y

            local newW = math.max(220, startSize.X + deltaX)
            local newH = math.max(140, startSize.Y + deltaY)

            FavHUDFrame.Size = UDim2.new(0, newW, 0, newH)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isResizing = false
        end
    end)

    getgenv().RegisteredSockets = getgenv().RegisteredSockets or {}

    -- Função para atualizar a lista do HUD Acesso Rápido (Favoritos) com suporte a Drag & Drop Reorder
    local function RefreshFavHUD()
        for _, c in pairs(FavContent:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end

        EnsureFavoritedOrder()

        local count = 0
        for idx, modName in ipairs(getgenv().FavoritedOrder or {}) do
            if getgenv().FavoritedMods[modName] then
                count = count + 1
                local desc = getgenv().RegisteredSockets[modName]

                local ItemFrame = Instance.new("Frame")
                ItemFrame.Name = "FavItem_" .. modName:gsub("%s+", "")
                ItemFrame.Size = UDim2.new(1, 0, 0, 36)
                ItemFrame.BackgroundColor3 = Themes.Element
                ItemFrame.ClipsDescendants = true
                ItemFrame.LayoutOrder = idx
                ItemFrame.ZIndex = 888882
                ItemFrame.Parent = FavContent
                local IFC = Instance.new("UICorner"); IFC.CornerRadius = UDim.new(0, 6); IFC.Parent = ItemFrame

                local ModNameVal = Instance.new("StringValue")
                ModNameVal.Name = "ModNameVal"
                ModNameVal.Value = modName
                ModNameVal.Parent = ItemFrame

                -- Gatilho de Drag-to-Reorder na área de texto/título
                local DragHandle = Instance.new("TextButton")
                DragHandle.Size = UDim2.new(1, -120, 1, 0)
                DragHandle.Position = UDim2.new(0, 0, 0, 0)
                DragHandle.BackgroundTransparency = 1
                DragHandle.Text = ""
                DragHandle.ZIndex = 888883
                DragHandle.Parent = ItemFrame

                local isReordering = false
                local dragConn

                DragHandle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isReordering = true
                        ItemFrame.ZIndex = 888890
                        local stroke = Instance.new("UIStroke"); stroke.Name = "DragStroke"; stroke.Color = Themes.Accent; stroke.Thickness = 1.5; stroke.Parent = ItemFrame
                        
                        dragConn = UserInputService.InputChanged:Connect(function(mInput)
                            if isReordering and (mInput.UserInputType == Enum.UserInputType.MouseMovement or mInput.UserInputType == Enum.UserInputType.Touch) then
                                local mouseY = mInput.Position.Y
                                local allFrames = {}
                                for _, child in ipairs(FavContent:GetChildren()) do
                                    if child:IsA("Frame") and child:FindFirstChild("ModNameVal") then
                                        table.insert(allFrames, child)
                                    end
                                end
                                table.sort(allFrames, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

                                for currentPos, childFrame in ipairs(allFrames) do
                                    local topY = childFrame.AbsolutePosition.Y
                                    local meY = childFrame.AbsoluteSize.Y
                                    if mouseY >= topY and mouseY <= (topY + meY) then
                                        local oldPos = ItemFrame.LayoutOrder
                                        if oldPos ~= currentPos then
                                            local movedMod = table.remove(getgenv().FavoritedOrder, oldPos)
                                            table.insert(getgenv().FavoritedOrder, currentPos, movedMod)

                                            for newIdx, nameInOrd in ipairs(getgenv().FavoritedOrder) do
                                                for _, f in ipairs(allFrames) do
                                                    if f.ModNameVal.Value == nameInOrd then
                                                        f.LayoutOrder = newIdx
                                                    end
                                                end
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if isReordering then
                            isReordering = false
                            ItemFrame.ZIndex = 888882
                            if ItemFrame:FindFirstChild("DragStroke") then ItemFrame.DragStroke:Destroy() end
                            if dragConn then dragConn:Disconnect(); dragConn = nil end
                            SaveFavoritesToFile()
                        end
                    end
                end)

                if desc and desc.type == "Toggle" then
                    local hasExtra = desc.extraBtnText and type(desc.extraBtnCallback) == "function"
                    local hasExtra2 = desc.extraBtn2Text and type(desc.extraBtn2Callback) == "function"

                    local rightWidth = 46
                    if hasExtra then rightWidth = rightWidth + 66 end
                    if hasExtra2 then rightWidth = rightWidth + 76 end

                    local ItemLab = Instance.new("TextLabel")
                    ItemLab.Text = modName
                    ItemLab.Size = UDim2.new(1, -(rightWidth + 10), 1, 0)
                    ItemLab.Position = UDim2.new(0, 10, 0, 0)
                    ItemLab.BackgroundTransparency = 1
                    ItemLab.Font = Enum.Font.GothamMedium
                    ItemLab.TextColor3 = Themes.Text
                    ItemLab.TextSize = 12
                    ItemLab.TextXAlignment = Enum.TextXAlignment.Left
                    ItemLab.TextTruncate = Enum.TextTruncate.AtEnd
                    ItemLab.ZIndex = 888883
                    ItemLab.Parent = ItemFrame

                    local currOffset = 44

                    -- Toggle Switch Principal
                    local TBtn = Instance.new("TextButton")
                    TBtn.Size = UDim2.new(0, 36, 0, 18)
                    TBtn.Position = UDim2.new(1, -currOffset, 0.5, -9)
                    local isCurrentlyOn = desc.get()
                    TBtn.BackgroundColor3 = isCurrentlyOn and Themes.Accent or Color3.fromRGB(60,60,65)
                    TBtn.Text = ""
                    TBtn.ZIndex = 888884
                    TBtn.Parent = ItemFrame
                    local TBC = Instance.new("UICorner"); TBC.CornerRadius = UDim.new(1, 0); TBC.Parent = TBtn

                    local circle = Instance.new("Frame")
                    circle.Size = UDim2.new(0, 14, 0, 14)
                    circle.Position = isCurrentlyOn and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    circle.ZIndex = 888885
                    circle.Parent = TBtn
                    local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(1, 0); CC.Parent = circle

                    TBtn.MouseButton1Click:Connect(function()
                        local newState = not desc.get()
                        desc.set(newState)
                        TweenService:Create(circle, TweenInfo.new(0.2), {Position = newState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
                        TweenService:Create(TBtn, TweenInfo.new(0.2), {BackgroundColor3 = newState and Themes.Accent or Color3.fromRGB(60,60,65)}):Play()
                    end)

                    currOffset = currOffset + 10

                    if hasExtra then
                        currOffset = currOffset + 60
                        local ExtraBtn = Instance.new("TextButton")
                        ExtraBtn.Size = UDim2.new(0, 56, 0, 20)
                        ExtraBtn.Position = UDim2.new(1, -currOffset, 0.5, -10)
                        ExtraBtn.BackgroundColor3 = Themes.Accent
                        ExtraBtn.Text = desc.extraBtnText
                        ExtraBtn.Font = Enum.Font.GothamBold
                        ExtraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        ExtraBtn.TextSize = 10
                        ExtraBtn.ZIndex = 888884
                        ExtraBtn.Parent = ItemFrame
                        local EBC = Instance.new("UICorner"); EBC.CornerRadius = UDim.new(0, 5); EBC.Parent = ExtraBtn

                        ExtraBtn.MouseButton1Click:Connect(function()
                            pcall(desc.extraBtnCallback)
                        end)
                        currOffset = currOffset + 6
                    end

                    if hasExtra2 then
                        currOffset = currOffset + 70
                        local ExtraBtn2 = Instance.new("TextButton")
                        ExtraBtn2.Size = UDim2.new(0, 66, 0, 20)
                        ExtraBtn2.Position = UDim2.new(1, -currOffset, 0.5, -10)
                        ExtraBtn2.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                        ExtraBtn2.Text = desc.extraBtn2Text
                        ExtraBtn2.Font = Enum.Font.GothamBold
                        ExtraBtn2.TextColor3 = Themes.Accent
                        ExtraBtn2.TextSize = 10
                        ExtraBtn2.ZIndex = 888884
                        ExtraBtn2.Parent = ItemFrame
                        local EBC2 = Instance.new("UICorner"); EBC2.CornerRadius = UDim.new(0, 5); EBC2.Parent = ExtraBtn2
                        local EBS2 = Instance.new("UIStroke"); EBS2.Color = Themes.Accent; EBS2.Thickness = 1; EBS2.Transparency = 0.6; EBS2.Parent = ExtraBtn2

                        ExtraBtn2.MouseButton1Click:Connect(function()
                            pcall(desc.extraBtn2Callback, ExtraBtn2)
                        end)
                    end
                else
                    -- Fallback genérico para soquetes simples
                    local ItemLab = Instance.new("TextLabel")
                    ItemLab.Text = modName
                    ItemLab.Size = UDim2.new(1, -20, 1, 0)
                    ItemLab.Position = UDim2.new(0, 10, 0, 0)
                    ItemLab.BackgroundTransparency = 1
                    ItemLab.Font = Enum.Font.GothamMedium
                    ItemLab.TextColor3 = Themes.Text
                    ItemLab.TextSize = 12
                    ItemLab.TextXAlignment = Enum.TextXAlignment.Left
                    ItemLab.ZIndex = 888883
                    ItemLab.Parent = ItemFrame
                end
            end
        end

        if count == 0 then
            local EmptyLab = Instance.new("TextLabel")
            EmptyLab.Text = "Nenhum mod favoritado ainda!\n(Clique com o Botão Direito em qualquer mod para favoritar)"
            EmptyLab.Size = UDim2.new(1, 0, 0, 80)
            EmptyLab.BackgroundTransparency = 1
            EmptyLab.Font = Enum.Font.Gotham
            EmptyLab.TextColor3 = Themes.TextDim
            EmptyLab.TextSize = 12
            EmptyLab.TextWrapped = true
            EmptyLab.ZIndex = 888882
            EmptyLab.Parent = FavContent
        end
    end

    function Window:ToggleFavHUD()
        FavHUDFrame.Visible = not FavHUDFrame.Visible
        if FavHUDFrame.Visible then
            RefreshFavHUD()
        end
    end
    getgenv().ToggleFavHUD = function() Window:ToggleFavHUD() end

    -- Menu de Contexto de Botão Direito (Favoritar)
    local ContextMenuFrame = Instance.new("Frame")
    ContextMenuFrame.Name = "DreeZyContextMenu"
    ContextMenuFrame.Size = UDim2.new(0, 160, 0, 42)
    ContextMenuFrame.BackgroundColor3 = Color3.fromRGB(26, 24, 34)
    ContextMenuFrame.BorderSizePixel = 0
    ContextMenuFrame.ZIndex = 999990
    ContextMenuFrame.Visible = false
    ContextMenuFrame.Parent = ScreenGui

    local ContextCorner = Instance.new("UICorner"); ContextCorner.CornerRadius = UDim.new(0, 8); ContextCorner.Parent = ContextMenuFrame
    local ContextStroke = Instance.new("UIStroke"); ContextStroke.Color = Themes.Accent; ContextStroke.Thickness = 1; ContextStroke.Transparency = 0.4; ContextStroke.Parent = ContextMenuFrame

    local ContextLab = Instance.new("TextLabel")
    ContextLab.Text = "Favoritar"
    ContextLab.Size = UDim2.new(0, 95, 1, 0)
    ContextLab.Position = UDim2.new(0, 12, 0, 0)
    ContextLab.BackgroundTransparency = 1
    ContextLab.Font = Enum.Font.GothamBold
    ContextLab.TextColor3 = Themes.Text
    ContextLab.TextSize = 13
    ContextLab.TextXAlignment = Enum.TextXAlignment.Left
    ContextLab.ZIndex = 999991
    ContextLab.Parent = ContextMenuFrame

    local StarBtn = Instance.new("TextButton")
    StarBtn.Size = UDim2.new(0, 26, 0, 26)
    StarBtn.Position = UDim2.new(1, -34, 0.5, -13)
    StarBtn.BackgroundTransparency = 1
    StarBtn.Text = "★"
    StarBtn.Font = Enum.Font.GothamBold
    StarBtn.TextSize = 18
    StarBtn.TextColor3 = Color3.fromRGB(140, 140, 150) -- Estrelinha cinza por padrão!
    StarBtn.ZIndex = 999991
    StarBtn.Parent = ContextMenuFrame

    local currentSocketModName = nil
    local isHoveringMenu = false

    ContextMenuFrame.MouseEnter:Connect(function()
        isHoveringMenu = true
    end)

    ContextMenuFrame.MouseLeave:Connect(function()
        isHoveringMenu = false
    end)

    StarBtn.MouseButton1Click:Connect(function()
        if currentSocketModName then
            local isFav = not (getgenv().FavoritedMods[currentSocketModName] or false)
            getgenv().FavoritedMods[currentSocketModName] = isFav
            
            StarBtn.TextColor3 = isFav and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(140, 140, 150)
            SaveFavoritesToFile()
            if FavHUDFrame.Visible then RefreshFavHUD() end

            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "DreeZy HUB",
                Text = isFav and ("★ " .. currentSocketModName .. " favoritado!") or ("☆ " .. currentSocketModName .. " removido dos favoritos!"),
                Duration = 2
            })
        end
    end)

    -- Fechar o menu de contexto APENAS se o usuário clicar FORA da aba (seja dentro do HUB ou na tela do jogo)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if ContextMenuFrame.Visible then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
                if not isHoveringMenu then
                    ContextMenuFrame.Visible = false
                end
            end
        end
    end)

    local function AttachSocketInteractions(EFrame, modName)
        local SocketTrigger = Instance.new("TextButton")
        SocketTrigger.Size = UDim2.new(1, 0, 1, 0)
        SocketTrigger.BackgroundTransparency = 1
        SocketTrigger.Text = ""
        SocketTrigger.ZIndex = 81
        SocketTrigger.Parent = EFrame

        SocketTrigger.MouseEnter:Connect(function()
            pcall(function()
                game:GetService("Players").LocalPlayer:GetMouse().Icon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png"
            end)
        end)

        SocketTrigger.MouseLeave:Connect(function()
            pcall(function()
                game:GetService("Players").LocalPlayer:GetMouse().Icon = ""
            end)
        end)

        SocketTrigger.MouseButton2Click:Connect(function()
            currentSocketModName = modName or "Mod"
            local isFav = getgenv().FavoritedMods[currentSocketModName] or false
            StarBtn.TextColor3 = isFav and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(140, 140, 150)

            local mousePos = UserInputService:GetMouseLocation()
            ContextMenuFrame.Position = UDim2.new(0, mousePos.X + 5, 0, mousePos.Y - 20)
            ContextMenuFrame.Visible = true
        end)
    end

    function Window:Tab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -20, 0, 35)
        TabBtn.Position = UDim2.new(0, 10, 0, 0)
        TabBtn.BackgroundColor3 = Themes.Sidebar
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "    " .. name
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 14
        TabBtn.TextColor3 = Themes.TextDim
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer
        local TabCorner = Instance.new("UICorner"); TabCorner.CornerRadius = UDim.new(0, 6); TabCorner.Parent = TabBtn

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, -10, 1, -10) -- Margin Right and Bottom fixed
        TabPage.Position = UDim2.new(0, 5, 0, 0) -- Margin Left
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 2
        TabPage.ScrollBarImageColor3 = Themes.Accent
        TabPage.Visible = false
        TabPage.Parent = Pages
        
        -- Fix Scrolling & Padding
        local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 8); layout.Parent = TabPage; layout.SortOrder = Enum.SortOrder.LayoutOrder
        local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, 2); padding.PaddingBottom = UDim.new(0, 10); padding.PaddingLeft = UDim.new(0, 2); padding.PaddingRight = UDim.new(0, 10); padding.Parent = TabPage

        -- Automatic Canvas Size
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)

        local TabObj = {Active = false}
        
        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                if t.Page.Visible then
                    t.Page.Visible = false
                end
                t.Btn.TextColor3 = Themes.TextDim
                t.Btn.BackgroundTransparency = 1
            end
            
            TabPage.Visible = true
            -- Fade In Animation
            TabPage.CanvasPosition = Vector2.new(0,0) -- Reset scroll? Optional.
            -- Start transparent/offset?
            -- Since Roblox UI doesn't have "CanvasTransparency", we simulate by animating children or just slide in?
            -- Let's do a simple fade in effect if possible, but scrollingframes are tricky.
            -- Simplest valid animation: Update Button style instantly, pop page in.
            
            TabBtn.TextColor3 = Themes.Text
            TabBtn.BackgroundTransparency = 0
            TabBtn.BackgroundColor3 = Themes.Accent
            
            -- Slide/Pop Effect for Button
            TabBtn.Size = UDim2.new(1, -25, 0, 35)
            TweenService:Create(TabBtn, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {Size = UDim2.new(1, -20, 0, 35)}):Play()
        end)
        
        if #Window.Tabs == 0 then
            TabPage.Visible = true
            TabBtn.TextColor3 = Themes.Text
            TabBtn.BackgroundTransparency = 0
            TabBtn.BackgroundColor3 = Themes.Accent
        end
        table.insert(Window.Tabs, {Btn = TabBtn, Page = TabPage})
        
        -- Group Logic
        function TabObj:Group(text)
            local GroupFrame = Instance.new("Frame")
            GroupFrame.Size = UDim2.new(1, 0, 0, 0) -- Auto Size
            GroupFrame.BackgroundColor3 = Themes.GroupDB
            GroupFrame.BorderSizePixel = 0
            GroupFrame.ClipsDescendants = true -- Fix animation overflow
            GroupFrame.Parent = TabPage
            local GC = Instance.new("UICorner"); GC.CornerRadius = UDim.new(0, 8); GC.Parent = GroupFrame
            local GStroke = Instance.new("UIStroke"); GStroke.Color = Color3.fromRGB(50,50,55); GStroke.Thickness = 1; GStroke.Transparency = 0.5; GStroke.Parent = GroupFrame
            
            local GTitle = Instance.new("TextLabel")
            GTitle.Text = text
            GTitle.Size = UDim2.new(1, -20, 0, 30)
            GTitle.Position = UDim2.new(0, 10, 0, 0)
            GTitle.BackgroundTransparency = 1
            GTitle.Font = Enum.Font.GothamBold
            GTitle.TextSize = 12
            GTitle.TextColor3 = Themes.TextDim
            GTitle.TextXAlignment = Enum.TextXAlignment.Left
            GTitle.Parent = GroupFrame
            
            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, -10, 0, 0)
            Container.Position = UDim2.new(0, 5, 0, 30)
            Container.BackgroundTransparency = 1
            Container.Parent = GroupFrame
            
            local GLayout = Instance.new("UIListLayout"); GLayout.Padding = UDim.new(0, 5); GLayout.Parent = Container; GLayout.SortOrder = Enum.SortOrder.LayoutOrder
            
            GLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local newHeight = GLayout.AbsoluteContentSize.Y
                Container.Size = UDim2.new(1, -10, 0, newHeight + 5)
                TweenService:Create(GroupFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, newHeight + 40)}):Play()
            end)
            
            local GroupObj = {}

            -- Helper for Element Backgrounds
            local function CreateElementFrame(modName)
                local EFrame = Instance.new("Frame")
                EFrame.Size = UDim2.new(1, 0, 0, 36)
                EFrame.BackgroundColor3 = Themes.Element
                EFrame.Parent = Container
                local EC = Instance.new("UICorner"); EC.CornerRadius = UDim.new(0, 6); EC.Parent = EFrame
                if modName then
                    AttachSocketInteractions(EFrame, modName)
                end
                return EFrame
            end

            -- Criador de Hubs Secundários (Sub-Windows/Modais Arrastáveis com Engrenagem)
            local function CreateSubWindow(titleText)
                local SubWindowFrame = Instance.new("Frame")
                SubWindowFrame.Name = "SubHub_" .. titleText:gsub("%s+", "")
                SubWindowFrame.Size = UDim2.new(0, 360, 0, 260)
                SubWindowFrame.Position = UDim2.new(0.5, -180, 0.5, -130)
                SubWindowFrame.BackgroundColor3 = Themes.Background
                SubWindowFrame.BorderSizePixel = 0
                SubWindowFrame.ZIndex = 80
                SubWindowFrame.Visible = false
                SubWindowFrame.Parent = ScreenGui

                local SubCorner = Instance.new("UICorner"); SubCorner.CornerRadius = UDim.new(0, 10); SubCorner.Parent = SubWindowFrame
                local SubStroke = Instance.new("UIStroke"); SubStroke.Color = Themes.Accent; SubStroke.Transparency = 0.4; SubStroke.Thickness = 1; SubStroke.Parent = SubWindowFrame

                -- Header do Hub Secundário
                local Header = Instance.new("Frame")
                Header.Size = UDim2.new(1, 0, 0, 40)
                Header.BackgroundColor3 = Themes.Sidebar
                Header.BorderSizePixel = 0
                Header.ZIndex = 81
                Header.Parent = SubWindowFrame

                MakeDraggable(Header, SubWindowFrame)
                local HeaderCorner = Instance.new("UICorner"); HeaderCorner.CornerRadius = UDim.new(0, 10); HeaderCorner.Parent = Header
                local HeaderFix = Instance.new("Frame"); HeaderFix.Size = UDim2.new(1, 0, 0, 10); HeaderFix.Position = UDim2.new(0, 0, 1, -10); HeaderFix.BackgroundColor3 = Themes.Sidebar; HeaderFix.BorderSizePixel = 0; HeaderFix.ZIndex = 81; HeaderFix.Parent = Header

                local GearIconHeader = Instance.new("ImageLabel")
                GearIconHeader.Size = UDim2.new(0, 18, 0, 18)
                GearIconHeader.Position = UDim2.new(0, 12, 0.5, -9)
                GearIconHeader.BackgroundTransparency = 1
                GearIconHeader.Image = "rbxassetid://6031280882"
                GearIconHeader.ImageColor3 = Themes.Accent
                GearIconHeader.ZIndex = 82
                GearIconHeader.Parent = Header

                local SubTitle = Instance.new("TextLabel")
                SubTitle.Text = titleText
                SubTitle.Font = Enum.Font.GothamBold
                SubTitle.TextSize = 13
                SubTitle.TextColor3 = Themes.Text
                SubTitle.Size = UDim2.new(1, -75, 1, 0)
                SubTitle.Position = UDim2.new(0, 36, 0, 0)
                SubTitle.BackgroundTransparency = 1
                SubTitle.TextXAlignment = Enum.TextXAlignment.Left
                SubTitle.ZIndex = 82
                SubTitle.Parent = Header

                -- Botão X Vermelho de Fechar
                local CloseBtn = Instance.new("TextButton")
                CloseBtn.Text = "X"
                CloseBtn.Font = Enum.Font.GothamBold
                CloseBtn.TextSize = 12
                CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
                CloseBtn.BackgroundColor3 = Color3.fromRGB(55, 25, 30)
                CloseBtn.Size = UDim2.new(0, 24, 0, 24)
                CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
                CloseBtn.ZIndex = 83
                CloseBtn.Parent = Header
                local CBCorner = Instance.new("UICorner"); CBCorner.CornerRadius = UDim.new(0, 6); CBCorner.Parent = CloseBtn

                CloseBtn.MouseButton1Click:Connect(function()
                    local closeTween = TweenService:Create(SubWindowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 360, 0, 0), BackgroundTransparency = 1})
                    closeTween:Play()
                    closeTween.Completed:Connect(function()
                        SubWindowFrame.Visible = false
                        SubWindowFrame.Size = UDim2.new(0, 360, 0, 260)
                        SubWindowFrame.BackgroundTransparency = 0
                    end)
                end)

                -- Container de Rolagem dos elementos
                local SubContent = Instance.new("ScrollingFrame")
                SubContent.Size = UDim2.new(1, -16, 1, -50)
                SubContent.Position = UDim2.new(0, 8, 0, 44)
                SubContent.BackgroundTransparency = 1
                SubContent.BorderSizePixel = 0
                SubContent.ScrollBarThickness = 2
                SubContent.ScrollBarImageColor3 = Themes.Accent
                SubContent.ZIndex = 81
                SubContent.Parent = SubWindowFrame

                local SubLayout = Instance.new("UIListLayout"); SubLayout.Padding = UDim.new(0, 6); SubLayout.SortOrder = Enum.SortOrder.LayoutOrder; SubLayout.Parent = SubContent
                local SubPad = Instance.new("UIPadding"); SubPad.PaddingTop = UDim.new(0, 4); SubPad.PaddingBottom = UDim.new(0, 8); SubPad.PaddingLeft = UDim.new(0, 4); SubPad.PaddingRight = UDim.new(0, 8); SubPad.Parent = SubContent

                SubLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SubContent.CanvasSize = UDim2.new(0, 0, 0, SubLayout.AbsoluteContentSize.Y + 16)
                end)

                -- Construtor de Elementos do Sub-Hub
                local SubGroupObj = {}
                local function CreateSubElementFrame()
                    local SEFrame = Instance.new("Frame")
                    SEFrame.Size = UDim2.new(1, 0, 0, 36)
                    SEFrame.BackgroundColor3 = Themes.Element
                    SEFrame.ZIndex = 82
                    SEFrame.Parent = SubContent
                    local SEC = Instance.new("UICorner"); SEC.CornerRadius = UDim.new(0, 6); SEC.Parent = SEFrame
                    return SEFrame
                end

                function SubGroupObj:ShapeSelector(stext, defaultIsRound, scallback)
                    local SFrame = CreateSubElementFrame()
                    local SLab = Instance.new("TextLabel")
                    SLab.Text = stext
                    SLab.Size = UDim2.new(1, -70, 1, 0)
                    SLab.Position = UDim2.new(0, 10, 0, 0)
                    SLab.BackgroundTransparency = 1
                    SLab.Font = Enum.Font.GothamMedium
                    SLab.TextColor3 = Themes.Text
                    SLab.TextSize = 13
                    SLab.TextXAlignment = Enum.TextXAlignment.Left
                    SLab.ZIndex = 83
                    SLab.Parent = SFrame

                    local ButtonsFrame = Instance.new("Frame")
                    ButtonsFrame.Size = UDim2.new(0, 54, 0, 24)
                    ButtonsFrame.Position = UDim2.new(1, -64, 0.5, -12)
                    ButtonsFrame.BackgroundTransparency = 1
                    ButtonsFrame.ZIndex = 83
                    ButtonsFrame.Parent = SFrame

                    -- Botão Círculo
                    local CircleBtn = Instance.new("TextButton")
                    CircleBtn.Size = UDim2.new(0, 22, 0, 22)
                    CircleBtn.Position = UDim2.new(0, 0, 0.5, -11)
                    CircleBtn.Text = ""
                    CircleBtn.ZIndex = 84
                    CircleBtn.Parent = ButtonsFrame
                    local CircleCorner = Instance.new("UICorner"); CircleCorner.CornerRadius = UDim.new(1, 0); CircleCorner.Parent = CircleBtn
                    local CircleStroke = Instance.new("UIStroke"); CircleStroke.Thickness = 1.5; CircleStroke.Parent = CircleBtn

                    local CircleInner = Instance.new("Frame")
                    CircleInner.Size = UDim2.new(0, 8, 0, 8)
                    CircleInner.Position = UDim2.new(0.5, -4, 0.5, -4)
                    CircleInner.ZIndex = 85
                    CircleInner.Parent = CircleBtn
                    local InnerCorner = Instance.new("UICorner"); InnerCorner.CornerRadius = UDim.new(1, 0); InnerCorner.Parent = CircleInner

                    -- Botão Quadrado
                    local SquareBtn = Instance.new("TextButton")
                    SquareBtn.Size = UDim2.new(0, 22, 0, 22)
                    SquareBtn.Position = UDim2.new(0, 28, 0.5, -11)
                    SquareBtn.Text = ""
                    SquareBtn.ZIndex = 84
                    SquareBtn.Parent = ButtonsFrame
                    local SquareCorner = Instance.new("UICorner"); SquareCorner.CornerRadius = UDim.new(0, 4); SquareCorner.Parent = SquareBtn
                    local SquareStroke = Instance.new("UIStroke"); SquareStroke.Thickness = 1.5; SquareStroke.Parent = SquareBtn

                    local SquareInner = Instance.new("Frame")
                    SquareInner.Size = UDim2.new(0, 8, 0, 8)
                    SquareInner.Position = UDim2.new(0.5, -4, 0.5, -4)
                    SquareInner.ZIndex = 85
                    SquareInner.Parent = SquareBtn
                    local SInnerCorner = Instance.new("UICorner"); SInnerCorner.CornerRadius = UDim.new(0, 2); SInnerCorner.Parent = SquareInner

                    local isRoundState = defaultIsRound

                    local function updateSelection(roundVal)
                        isRoundState = roundVal
                        if isRoundState then
                            TweenService:Create(CircleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes.Accent}):Play()
                            CircleStroke.Color = Themes.Accent
                            CircleInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

                            TweenService:Create(SquareBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                            SquareStroke.Color = Color3.fromRGB(70, 70, 75)
                            SquareInner.BackgroundColor3 = Color3.fromRGB(100, 100, 105)
                        else
                            TweenService:Create(SquareBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes.Accent}):Play()
                            SquareStroke.Color = Themes.Accent
                            SquareInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

                            TweenService:Create(CircleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                            CircleStroke.Color = Color3.fromRGB(70, 70, 75)
                            CircleInner.BackgroundColor3 = Color3.fromRGB(100, 100, 105)
                        end
                        pcall(scallback, isRoundState)
                    end

                    CircleBtn.MouseButton1Click:Connect(function()
                        if not isRoundState then updateSelection(true) end
                    end)

                    SquareBtn.MouseButton1Click:Connect(function()
                        if isRoundState then updateSelection(false) end
                    end)

                    updateSelection(defaultIsRound)

                    local SShapeObj = {
                        Frame = SFrame,
                        Get = function() return isRoundState end,
                        Set = function(val) updateSelection(val) end
                    }
                    return SShapeObj
                end

                function SubGroupObj:Toggle(stext, sdefault, scallback)
                    local STFrame = CreateSubElementFrame()
                    local STLab = Instance.new("TextLabel")
                    STLab.Text = stext
                    STLab.Size = UDim2.new(1, -60, 1, 0)
                    STLab.Position = UDim2.new(0, 10, 0, 0)
                    STLab.BackgroundTransparency = 1
                    STLab.Font = Enum.Font.GothamMedium
                    STLab.TextColor3 = Themes.Text
                    STLab.TextSize = 13
                    STLab.TextXAlignment = Enum.TextXAlignment.Left
                    STLab.ZIndex = 83
                    STLab.Parent = STFrame

                    local STBtn = Instance.new("TextButton")
                    STBtn.Size = UDim2.new(0, 40, 0, 20)
                    STBtn.Position = UDim2.new(1, -50, 0.5, -10)
                    STBtn.BackgroundColor3 = sdefault and Themes.Accent or Color3.fromRGB(60,60,65)
                    STBtn.Text = ""
                    STBtn.ZIndex = 83
                    STBtn.Parent = STFrame
                    local STBC = Instance.new("UICorner"); STBC.CornerRadius = UDim.new(1, 0); STBC.Parent = STBtn

                    local scircle = Instance.new("Frame")
                    scircle.Size = UDim2.new(0, 16, 0, 16)
                    scircle.Position = sdefault and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    scircle.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    scircle.ZIndex = 84
                    scircle.Parent = STBtn
                    local SCC = Instance.new("UICorner"); SCC.CornerRadius = UDim.new(1, 0); SCC.Parent = scircle

                    local senabled = sdefault
                    local SToggleObj = {
                        Frame = STFrame,
                        Get = function() return senabled end,
                        Set = function(val)
                            senabled = val
                            TweenService:Create(scircle, TweenInfo.new(0.2), {Position = senabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                            TweenService:Create(STBtn, TweenInfo.new(0.2), {BackgroundColor3 = senabled and Themes.Accent or Color3.fromRGB(60,60,65)}):Play()
                            pcall(scallback, senabled)
                        end
                    }
                    STBtn.MouseButton1Click:Connect(function() SToggleObj.Set(not senabled) end)
                    return SToggleObj
                end

                function SubGroupObj:ToggleSlider(stext, smin, smax, sdefaultVal, sdefaultState, scallbackToggle, scallbackSlider)
                    local STFrame = CreateSubElementFrame()
                    
                    local STLab = Instance.new("TextLabel")
                    STLab.Text = stext
                    STLab.Size = UDim2.new(0, 95, 1, 0)
                    STLab.Position = UDim2.new(0, 10, 0, 0)
                    STLab.BackgroundTransparency = 1
                    STLab.Font = Enum.Font.GothamMedium
                    STLab.TextColor3 = Themes.Text
                    STLab.TextSize = 13
                    STLab.TextXAlignment = Enum.TextXAlignment.Left
                    STLab.ZIndex = 83
                    STLab.Parent = STFrame

                    -- Barra de linha rosa/magenta com círculo preto articulado no meio
                    local BarTrack = Instance.new("TextButton")
                    BarTrack.Text = ""
                    BarTrack.AutoButtonColor = false
                    BarTrack.Size = UDim2.new(1, -165, 0, 6)
                    BarTrack.Position = UDim2.new(0, 108, 0.5, -3)
                    BarTrack.BackgroundColor3 = Color3.fromRGB(50, 25, 55)
                    BarTrack.BorderSizePixel = 0
                    BarTrack.ZIndex = 83
                    BarTrack.Parent = STFrame
                    local BTC = Instance.new("UICorner"); BTC.CornerRadius = UDim.new(1, 0); BTC.Parent = BarTrack

                    local initialVal = math.clamp(sdefaultVal or smin, smin, smax)
                    local initialProgress = (initialVal - smin) / (smax - smin)

                    local FillBar = Instance.new("Frame")
                    FillBar.Size = UDim2.new(initialProgress, 0, 1, 0)
                    FillBar.BackgroundColor3 = Themes.Accent
                    FillBar.BorderSizePixel = 0
                    FillBar.ZIndex = 84
                    FillBar.Parent = BarTrack
                    local FBC = Instance.new("UICorner"); FBC.CornerRadius = UDim.new(1, 0); FBC.Parent = FillBar

                    -- Círculo / Bola preta articulada na linha
                    local KnobCircle = Instance.new("Frame")
                    KnobCircle.Size = UDim2.new(0, 16, 0, 16)
                    KnobCircle.Position = UDim2.new(initialProgress, -8, 0.5, -8)
                    KnobCircle.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Bola preta estilo desenho!
                    KnobCircle.ZIndex = 85
                    KnobCircle.Parent = BarTrack
                    local KC = Instance.new("UICorner"); KC.CornerRadius = UDim.new(1, 0); KC.Parent = KnobCircle
                    local KS = Instance.new("UIStroke"); KS.Color = Themes.Accent; KS.Thickness = 2; KS.Parent = KnobCircle

                    -- Lógica de arrasto do círculo na linha
                    local isDragging = false
                    local function UpdateBar(inputPos)
                        local trackAbsPos = BarTrack.AbsolutePosition.X
                        local trackAbsSize = BarTrack.AbsoluteSize.X
                        if trackAbsSize <= 0 then return end
                        
                        local relX = math.clamp(inputPos.X - trackAbsPos, 0, trackAbsSize)
                        local alpha = relX / trackAbsSize
                        local val = math.floor(smin + alpha * (smax - smin) + 0.5)
                        val = math.clamp(val, smin, smax)
                        
                        local progress = (val - smin) / (smax - smin)
                        FillBar.Size = UDim2.new(progress, 0, 1, 0)
                        KnobCircle.Position = UDim2.new(progress, -8, 0.5, -8)
                        pcall(scallbackSlider, val)
                    end

                    BarTrack.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            isDragging = true
                            UpdateBar(input.Position)
                        end
                    end)

                    UIS.InputChanged:Connect(function(input)
                        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            UpdateBar(input.Position)
                        end
                    end)

                    UIS.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            isDragging = false
                        end
                    end)

                    -- Toggle Switch no canto direito
                    local STBtn = Instance.new("TextButton")
                    STBtn.Size = UDim2.new(0, 40, 0, 20)
                    STBtn.Position = UDim2.new(1, -50, 0.5, -10)
                    STBtn.BackgroundColor3 = sdefaultState and Themes.Accent or Color3.fromRGB(60,60,65)
                    STBtn.Text = ""
                    STBtn.ZIndex = 83
                    STBtn.Parent = STFrame
                    local STBC = Instance.new("UICorner"); STBC.CornerRadius = UDim.new(1, 0); STBC.Parent = STBtn

                    local scircle = Instance.new("Frame")
                    scircle.Size = UDim2.new(0, 16, 0, 16)
                    scircle.Position = sdefaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    scircle.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    scircle.ZIndex = 84
                    scircle.Parent = STBtn
                    local SCC = Instance.new("UICorner"); SCC.CornerRadius = UDim.new(1, 0); SCC.Parent = scircle

                    local senabled = sdefaultState
                    local SToggleSliderObj = {
                        Frame = STFrame,
                        Get = function() return senabled end,
                        Set = function(val)
                            senabled = val
                            TweenService:Create(scircle, TweenInfo.new(0.2), {Position = senabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                            TweenService:Create(STBtn, TweenInfo.new(0.2), {BackgroundColor3 = senabled and Themes.Accent or Color3.fromRGB(60,60,65)}):Play()
                            pcall(scallbackToggle, senabled)
                        end
                    }
                    STBtn.MouseButton1Click:Connect(function() SToggleSliderObj.Set(not senabled) end)
                    return SToggleSliderObj
                end

                function SubGroupObj:Input(stext, sdefaultVal, sminVal, smaxVal, scallback, sunitText)
                    local SIFrame = CreateSubElementFrame()
                    SIFrame.Size = UDim2.new(1, 0, 0, 36)

                    local SILab = Instance.new("TextLabel")
                    SILab.Text = stext
                    SILab.Position = UDim2.new(0, 10, 0, 0)
                    SILab.Size = UDim2.new(1, -110, 1, 0)
                    SILab.BackgroundTransparency = 1
                    SILab.Font = Enum.Font.GothamMedium
                    SILab.TextColor3 = Themes.Text
                    SILab.TextSize = 13
                    SILab.TextXAlignment = Enum.TextXAlignment.Left
                    SILab.ZIndex = 83
                    SILab.Parent = SIFrame

                    local STBox = Instance.new("TextBox")
                    STBox.Size = UDim2.new(0, 90, 0, 24)
                    STBox.Position = UDim2.new(1, -100, 0.5, -12)
                    STBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
                    STBox.Text = tostring(sdefaultVal or 50) .. (sunitText and (" " .. sunitText) or "")
                    STBox.Font = Enum.Font.GothamBold
                    STBox.TextColor3 = Themes.Accent
                    STBox.TextSize = 12
                    STBox.ClearTextOnFocus = false
                    STBox.ZIndex = 86
                    STBox.Parent = SIFrame
                    local STBC = Instance.new("UICorner"); STBC.CornerRadius = UDim.new(0, 6); STBC.Parent = STBox
                    local STBS = Instance.new("UIStroke"); STBS.Color = Themes.Accent; STBS.Thickness = 1; STBS.Transparency = 0.5; STBS.Parent = STBox

                    local scurrentValue = tonumber(sdefaultVal) or 50

                    local function applyValue()
                        local cleanStr = STBox.Text:gsub("[^%d%.]", "")
                        local num = tonumber(cleanStr)
                        if num then
                            if sminVal then num = math.max(sminVal, num) end
                            if smaxVal then num = math.min(smaxVal, num) end
                            scurrentValue = num
                        end
                        STBox.Text = tostring(scurrentValue) .. (sunitText and (" " .. sunitText) or "")
                        pcall(scallback, scurrentValue)
                    end

                    STBox.FocusLost:Connect(function(enterPressed)
                        applyValue()
                    end)

                    local SInputObj = {
                        Frame = SIFrame,
                        Get = function() return scurrentValue end,
                        Set = function(val)
                            local num = tonumber(val) or scurrentValue
                            if sminVal then num = math.max(sminVal, num) end
                            if smaxVal then num = math.min(smaxVal, num) end
                            scurrentValue = num
                            STBox.Text = tostring(scurrentValue) .. (sunitText and (" " .. sunitText) or "")
                            pcall(scallback, scurrentValue)
                        end
                    }
                    return SInputObj
                end

                function SubGroupObj:KeyboardMouseDisplay(initialTarget, onSelect)
                    local DisplayFrame = CreateSubElementFrame()
                    DisplayFrame.Size = UDim2.new(1, 0, 0, 240)
                    DisplayFrame.ClipsDescendants = true
                    DisplayFrame.ZIndex = 83

                    local StatusLab = Instance.new("TextLabel")
                    StatusLab.Text = "Alvo de Auto Click: " .. (initialTarget == "MouseButton1" and "[ Mouse Esq (M1) ]" or (initialTarget == "MouseButton2" and "[ Mouse Dir (M2) ]" or (initialTarget == "MouseButton3" and "[ Mouse Meio (M3) ]" or ("[ Tecla '" .. tostring(initialTarget) .. "' ]"))))
                    StatusLab.Size = UDim2.new(1, -20, 0, 20)
                    StatusLab.Position = UDim2.new(0, 10, 0, 4)
                    StatusLab.BackgroundTransparency = 1
                    StatusLab.Font = Enum.Font.GothamBold
                    StatusLab.TextColor3 = Themes.Accent
                    StatusLab.TextSize = 12
                    StatusLab.TextXAlignment = Enum.TextXAlignment.Left
                    StatusLab.ZIndex = 84
                    StatusLab.Parent = DisplayFrame

                    local Container = Instance.new("Frame")
                    Container.Size = UDim2.new(1, -20, 0, 205)
                    Container.Position = UDim2.new(0, 10, 0, 28)
                    Container.BackgroundTransparency = 1
                    Container.ZIndex = 84
                    Container.Parent = DisplayFrame

                    -- MOUSE INTERATIVO (Inspirado no visual roxo enviado pelo usuário)
                    local MouseFrame = Instance.new("Frame")
                    MouseFrame.Size = UDim2.new(0, 80, 0, 130)
                    MouseFrame.Position = UDim2.new(0, 0, 0, 10)
                    MouseFrame.BackgroundColor3 = Color3.fromRGB(180, 160, 240)
                    MouseFrame.ZIndex = 84
                    MouseFrame.Parent = Container
                    local MFC = Instance.new("UICorner"); MFC.CornerRadius = UDim.new(0, 24); MFC.Parent = MouseFrame
                    local MFS = Instance.new("UIStroke"); MFS.Color = Themes.Accent; MFS.Thickness = 1.5; MFS.Parent = MouseFrame

                    -- Botão Mouse Esquerdo (M1)
                    local M1Btn = Instance.new("TextButton")
                    M1Btn.Size = UDim2.new(0.48, 0, 0.45, 0)
                    M1Btn.Position = UDim2.new(0, 0, 0, 0)
                    M1Btn.BackgroundColor3 = Color3.fromRGB(150, 130, 220)
                    M1Btn.Text = "M1\n(Esq)"
                    M1Btn.Font = Enum.Font.GothamBold
                    M1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    M1Btn.TextSize = 10
                    M1Btn.ZIndex = 85
                    M1Btn.Parent = MouseFrame
                    local M1C = Instance.new("UICorner"); M1C.CornerRadius = UDim.new(0, 16); M1C.Parent = M1Btn

                    -- Botão Mouse Direito (M2)
                    local M2Btn = Instance.new("TextButton")
                    M2Btn.Size = UDim2.new(0.48, 0, 0.45, 0)
                    M2Btn.Position = UDim2.new(0.52, 0, 0, 0)
                    M2Btn.BackgroundColor3 = Color3.fromRGB(150, 130, 220)
                    M2Btn.Text = "M2\n(Dir)"
                    M2Btn.Font = Enum.Font.GothamBold
                    M2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    M2Btn.TextSize = 10
                    M2Btn.ZIndex = 85
                    M2Btn.Parent = MouseFrame
                    local M2C = Instance.new("UICorner"); M2C.CornerRadius = UDim.new(0, 16); M2C.Parent = M2Btn

                    -- Scroll / M3 (Meio)
                    local M3Btn = Instance.new("TextButton")
                    M3Btn.Size = UDim2.new(0, 16, 0, 26)
                    M3Btn.Position = UDim2.new(0.5, -8, 0.12, 0)
                    M3Btn.BackgroundColor3 = Color3.fromRGB(50, 45, 60)
                    M3Btn.Text = "M3"
                    M3Btn.Font = Enum.Font.GothamBold
                    M3Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    M3Btn.TextSize = 8
                    M3Btn.ZIndex = 86
                    M3Btn.Parent = MouseFrame
                    local M3C = Instance.new("UICorner"); M3C.CornerRadius = UDim.new(0, 4); M3C.Parent = M3Btn

                    -- TECLADO INTERATIVO (Inspirado nas imagens enviadas pelo usuário)
                    local KBFrame = Instance.new("Frame")
                    KBFrame.Size = UDim2.new(1, -95, 1, 0)
                    KBFrame.Position = UDim2.new(0, 95, 0, 0)
                    KBFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
                    KBFrame.ZIndex = 84
                    KBFrame.Parent = Container
                    local KBC = Instance.new("UICorner"); KBC.CornerRadius = UDim.new(0, 8); KBC.Parent = KBFrame
                    local KBS = Instance.new("UIStroke"); KBS.Color = Color3.fromRGB(50, 50, 60); KBS.Thickness = 1; KBS.Parent = KBFrame

                    local rows = {
                        {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"},
                        {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
                        {"A", "S", "D", "F", "G", "H", "J", "K", "L"},
                        {"Z", "X", "C", "V", "B", "N", "M"},
                        {"Space"}
                    }

                    local function updateSelection(tgtName, displayLabelText)
                        StatusLab.Text = "Alvo de Auto Click: " .. displayLabelText
                        pcall(onSelect, tgtName)
                    end

                    M1Btn.MouseButton1Click:Connect(function() updateSelection("MouseButton1", "[ Mouse Esq (M1) ]") end)
                    M2Btn.MouseButton1Click:Connect(function() updateSelection("MouseButton2", "[ Mouse Dir (M2) ]") end)
                    M3Btn.MouseButton1Click:Connect(function() updateSelection("MouseButton3", "[ Mouse Meio (M3) ]") end)

                    local posY = 8
                    for _, rowKeys in ipairs(rows) do
                        local keyHeight = 22

                        local RowContainer = Instance.new("Frame")
                        RowContainer.Size = UDim2.new(1, -12, 0, keyHeight)
                        RowContainer.Position = UDim2.new(0, 6, 0, posY)
                        RowContainer.BackgroundTransparency = 1
                        RowContainer.ZIndex = 85
                        RowContainer.Parent = KBFrame

                        local UILL = Instance.new("UIListLayout")
                        UILL.FillDirection = Enum.FillDirection.Horizontal
                        UILL.HorizontalAlignment = Enum.HorizontalAlignment.Center
                        UILL.Padding = UDim.new(0, 3)
                        UILL.Parent = RowContainer

                        for _, kName in ipairs(rowKeys) do
                            local KBtn = Instance.new("TextButton")
                            KBtn.Size = UDim2.new(0, (kName == "Space" and 120 or 20), 0, keyHeight)
                            KBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                            KBtn.Text = kName
                            KBtn.Font = Enum.Font.GothamBold
                            KBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
                            KBtn.TextSize = 10
                            KBtn.ZIndex = 86
                            KBtn.Parent = RowContainer
                            local KC = Instance.new("UICorner"); KC.CornerRadius = UDim.new(0, 4); KC.Parent = KBtn

                            KBtn.MouseButton1Click:Connect(function()
                                updateSelection(kName, "[ Tecla '" .. kName .. "' ]")
                            end)
                        end

                        posY = posY + keyHeight + 4
                    end

                    return DisplayFrame
                end

                function SubGroupObj:Slider(stext, smin, smax, sdefault, scallback, sformatter)
                    local SSFrame = CreateSubElementFrame()
                    SSFrame.Size = UDim2.new(1, 0, 0, 50)
                    
                    local SSLab = Instance.new("TextLabel")
                    SSLab.Text = stext
                    SSLab.Size = UDim2.new(1, -10, 0, 20)
                    SSLab.Position = UDim2.new(0, 10, 0, 5)
                    SSLab.BackgroundTransparency = 1
                    SSLab.Font = Enum.Font.GothamMedium
                    SSLab.TextColor3 = Themes.Text
                    SSLab.TextSize = 13
                    SSLab.TextXAlignment = Enum.TextXAlignment.Left
                    SSLab.ZIndex = 83
                    SSLab.Parent = SSFrame

                    local fmt = sformatter or function(v) return tostring(v) end
                    local SValLab = Instance.new("TextLabel")
                    SValLab.Text = fmt(sdefault)
                    SValLab.Size = UDim2.new(0, 60, 0, 20)
                    SValLab.Position = UDim2.new(1, -70, 0, 5)
                    SValLab.BackgroundTransparency = 1
                    SValLab.Font = Enum.Font.Gotham
                    SValLab.TextColor3 = Themes.TextDim
                    SValLab.TextSize = 12
                    SValLab.TextXAlignment = Enum.TextXAlignment.Right
                    SValLab.ZIndex = 83
                    SValLab.Parent = SSFrame

                    local STrack = Instance.new("TextButton")
                    STrack.Text = ""
                    STrack.Size = UDim2.new(1, -20, 0, 4)
                    STrack.Position = UDim2.new(0, 10, 0, 35)
                    STrack.BackgroundColor3 = Color3.fromRGB(50,50,55)
                    STrack.ZIndex = 83
                    STrack.Parent = SSFrame
                    local STrC = Instance.new("UICorner"); STrC.CornerRadius = UDim.new(1, 0); STrC.Parent = STrack

                    local SFill = Instance.new("Frame")
                    SFill.Size = UDim2.new((sdefault - smin)/(smax - smin), 0, 1, 0)
                    SFill.BackgroundColor3 = Themes.Accent
                    SFill.ZIndex = 84
                    SFill.Parent = STrack
                    local SFC = Instance.new("UICorner"); SFC.CornerRadius = UDim.new(1, 0); SFC.Parent = SFill

                    local sCurrentVal = sdefault
                    local sdragging = false
                    local function supdate(input)
                        local pos = input.Position.X
                        local rect = STrack.AbsolutePosition.X
                        local size = STrack.AbsoluteSize.X
                        local percent = math.clamp((pos - rect) / size, 0, 1)
                        local val = math.floor(smin + (smax - smin) * percent)
                        sCurrentVal = val
                        SValLab.Text = fmt(val)
                        SFill.Size = UDim2.new(percent, 0, 1, 0)
                        pcall(scallback, val)
                    end
                    STrack.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sdragging = true; supdate(input) end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if sdragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then supdate(input) end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sdragging = false end
                    end)

                    local SSliderObj = {
                        Frame = SSFrame,
                        Get = function() return sCurrentVal end,
                        Set = function(val)
                            val = math.clamp(val, smin, smax)
                            sCurrentVal = val
                            local percent = (val - smin) / (smax - smin)
                            SValLab.Text = fmt(val)
                            SFill.Size = UDim2.new(percent, 0, 1, 0)
                            pcall(scallback, val)
                        end
                    }
                    return SSliderObj
                end

                function SubGroupObj:Dropdown(stext, soptions, sdefault, scallback)
                    local SDFrame = CreateSubElementFrame()
                    SDFrame.Size = UDim2.new(1, 0, 0, 50)
                    SDFrame.ClipsDescendants = true
                    SDFrame.ZIndex = 83

                    local SDLab = Instance.new("TextLabel")
                    SDLab.Text = stext
                    SDLab.Size = UDim2.new(1, -10, 0, 20)
                    SDLab.Position = UDim2.new(0, 10, 0, 5)
                    SDLab.BackgroundTransparency = 1
                    SDLab.Font = Enum.Font.GothamMedium
                    SDLab.TextColor3 = Themes.Text
                    SDLab.TextSize = 13
                    SDLab.TextXAlignment = Enum.TextXAlignment.Left
                    SDLab.ZIndex = 84
                    SDLab.Parent = SDFrame

                    local scurrentOption = sdefault or soptions[1] or "..."

                    local SDropBtn = Instance.new("TextButton")
                    SDropBtn.Size = UDim2.new(1, -20, 0, 20)
                    SDropBtn.Position = UDim2.new(0, 10, 0, 25)
                    SDropBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                    SDropBtn.Text = "   " .. tostring(scurrentOption)
                    SDropBtn.Font = Enum.Font.Gotham
                    SDropBtn.TextSize = 12
                    SDropBtn.TextColor3 = Themes.TextDim
                    SDropBtn.TextXAlignment = Enum.TextXAlignment.Left
                    SDropBtn.ZIndex = 84
                    SDropBtn.Parent = SDFrame
                    local SDC = Instance.new("UICorner"); SDC.CornerRadius = UDim.new(0, 4); SDC.Parent = SDropBtn

                    local SArrow = Instance.new("TextLabel")
                    SArrow.Text = "v"
                    SArrow.Size = UDim2.new(0, 20, 1, 0)
                    SArrow.Position = UDim2.new(1, -20, 0, 0)
                    SArrow.BackgroundTransparency = 1
                    SArrow.TextColor3 = Themes.TextDim
                    SArrow.Font = Enum.Font.GothamBold
                    SArrow.ZIndex = 85
                    SArrow.Parent = SDropBtn

                    local SListFrame = Instance.new("ScrollingFrame")
                    SListFrame.Size = UDim2.new(1, -20, 0, 100)
                    SListFrame.Position = UDim2.new(0, 10, 0, 55)
                    SListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                    SListFrame.BorderSizePixel = 0
                    SListFrame.ScrollBarThickness = 2
                    SListFrame.Visible = false
                    SListFrame.ZIndex = 86
                    SListFrame.Parent = SDFrame
                    local SLC = Instance.new("UICorner"); SLC.CornerRadius = UDim.new(0, 4); SLC.Parent = SListFrame
                    local SLPad = Instance.new("UIPadding"); SLPad.PaddingTop = UDim.new(0, 5); SLPad.PaddingLeft = UDim.new(0, 5); SLPad.Parent = SListFrame
                    local SLLayout = Instance.new("UIListLayout"); SLLayout.Padding = UDim.new(0, 2); SLLayout.SortOrder = Enum.SortOrder.LayoutOrder; SLLayout.Parent = SListFrame

                    local sIsOpen = false
                    local SubDropdownObj = {}

                    function SubDropdownObj:Refresh(snewOptions)
                        soptions = snewOptions
                        for _, child in pairs(SListFrame:GetChildren()) do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        for _, opt in pairs(soptions) do
                            local OptBtn = Instance.new("TextButton")
                            OptBtn.Size = UDim2.new(1, -10, 0, 20)
                            OptBtn.BackgroundTransparency = 1
                            OptBtn.Text = tostring(opt)
                            OptBtn.TextColor3 = Themes.TextDim
                            OptBtn.Font = Enum.Font.Gotham
                            OptBtn.TextSize = 12
                            OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                            OptBtn.ZIndex = 87
                            OptBtn.Parent = SListFrame

                            OptBtn.MouseButton1Click:Connect(function()
                                scurrentOption = opt
                                SDropBtn.Text = "   " .. tostring(opt)
                                pcall(scallback, opt)
                                sIsOpen = false
                                SListFrame.Visible = false
                                TweenService:Create(SArrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                                TweenService:Create(SDFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 50)}):Play()
                            end)
                        end
                        SListFrame.CanvasSize = UDim2.new(0, 0, 0, SLLayout.AbsoluteContentSize.Y + 10)
                    end

                    SDropBtn.MouseButton1Click:Connect(function()
                        sIsOpen = not sIsOpen
                        if sIsOpen then
                            SListFrame.Visible = true
                            TweenService:Create(SArrow, TweenInfo.new(0.2), {Rotation = 180}):Play()
                            TweenService:Create(SDFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 160)}):Play()
                        else
                            SListFrame.Visible = false
                            TweenService:Create(SArrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                            TweenService:Create(SDFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 50)}):Play()
                        end
                    end)

                    SubDropdownObj.Get = function() return scurrentOption end
                    SubDropdownObj.Set = function(val)
                        scurrentOption = val
                        SDropBtn.Text = "   " .. tostring(val)
                        pcall(scallback, val)
                    end

                    SubDropdownObj:Refresh(soptions)
                    return SubDropdownObj
                end

                function SubGroupObj:InteractiveList(stext, getOptionsFunc, onAdd, onRemove)
                    local SIFrame = CreateSubElementFrame()
                    SIFrame.Size = UDim2.new(1, 0, 0, 80)
                    SIFrame.ClipsDescendants = true
                    SIFrame.ZIndex = 83

                    local SILab = Instance.new("TextLabel")
                    SILab.Text = stext
                    SILab.Size = UDim2.new(1, -10, 0, 20)
                    SILab.Position = UDim2.new(0, 10, 0, 5)
                    SILab.BackgroundTransparency = 1
                    SILab.Font = Enum.Font.GothamMedium
                    SILab.TextColor3 = Themes.Text
                    SILab.TextSize = 13
                    SILab.TextXAlignment = Enum.TextXAlignment.Left
                    SILab.ZIndex = 84
                    SILab.Parent = SIFrame

                    local sSelectedPlayer = "Selecionar..."
                    local SDropBtn = Instance.new("TextButton")
                    SDropBtn.Size = UDim2.new(0.65, 0, 0, 25)
                    SDropBtn.Position = UDim2.new(0, 10, 0, 25)
                    SDropBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
                    SDropBtn.Text = "   " .. sSelectedPlayer
                    SDropBtn.Font = Enum.Font.Gotham
                    SDropBtn.TextSize = 12
                    SDropBtn.TextColor3 = Themes.TextDim
                    SDropBtn.TextXAlignment = Enum.TextXAlignment.Left
                    SDropBtn.ZIndex = 84
                    SDropBtn.Parent = SIFrame
                    local SDC = Instance.new("UICorner"); SDC.CornerRadius = UDim.new(0, 4); SDC.Parent = SDropBtn

                    local SDropArrow = Instance.new("TextLabel")
                    SDropArrow.Text = "v"
                    SDropArrow.Size = UDim2.new(0, 20, 1, 0)
                    SDropArrow.Position = UDim2.new(1, -20, 0, 0)
                    SDropArrow.BackgroundTransparency = 1
                    SDropArrow.TextColor3 = Themes.TextDim
                    SDropArrow.Font = Enum.Font.GothamBold
                    SDropArrow.ZIndex = 85
                    SDropArrow.Parent = SDropBtn

                    local SAddBtn = Instance.new("TextButton")
                    SAddBtn.Size = UDim2.new(0.25, 0, 0, 25)
                    SAddBtn.Position = UDim2.new(0.7, 5, 0, 25)
                    SAddBtn.BackgroundColor3 = Themes.Accent
                    SAddBtn.Text = "Add +"
                    SAddBtn.Font = Enum.Font.GothamBold
                    SAddBtn.TextSize = 12
                    SAddBtn.TextColor3 = Themes.Text
                    SAddBtn.ZIndex = 84
                    SAddBtn.Parent = SIFrame
                    local SAC = Instance.new("UICorner"); SAC.CornerRadius = UDim.new(0, 4); SAC.Parent = SAddBtn

                    local SAddedList = Instance.new("ScrollingFrame")
                    SAddedList.Size = UDim2.new(1, -20, 0, 0)
                    SAddedList.Position = UDim2.new(0, 10, 0, 60)
                    SAddedList.BackgroundTransparency = 1
                    SAddedList.BorderSizePixel = 0
                    SAddedList.ScrollBarThickness = 2
                    SAddedList.ZIndex = 84
                    SAddedList.Parent = SIFrame
                    local SALL = Instance.new("UIListLayout"); SALL.Padding = UDim.new(0, 5); SALL.Parent = SAddedList; SALL.SortOrder = Enum.SortOrder.LayoutOrder

                    local SDList = Instance.new("ScrollingFrame")
                    SDList.Size = UDim2.new(0.65, 0, 0, 120)
                    SDList.Position = UDim2.new(0, 10, 0, 55)
                    SDList.BackgroundColor3 = Color3.fromRGB(40,40,45)
                    SDList.Visible = false
                    SDList.ZIndex = 90
                    SDList.BorderSizePixel = 0
                    SDList.Parent = SIFrame
                    local SDLC = Instance.new("UICorner"); SDLC.CornerRadius = UDim.new(0, 4); SDLC.Parent = SDList
                    local SDLL = Instance.new("UIListLayout"); SDLL.Parent = SDList; SDLL.SortOrder = Enum.SortOrder.LayoutOrder; SDLL.Padding = UDim.new(0, 2)
                    local SDP = Instance.new("UIPadding"); SDP.PaddingLeft = UDim.new(0, 5); SDP.PaddingTop = UDim.new(0, 5); SDP.Parent = SDList

                    local sAddedItems = {}
                    local sIsDropdownOpen = false

                    local function SUpdateSize()
                        local listHeight = SALL.AbsoluteContentSize.Y
                        SAddedList.CanvasSize = UDim2.new(0, 0, 0, listHeight)
                        local displayListHeight = math.min(listHeight, 150)
                        SAddedList.Size = UDim2.new(1, -20, 0, displayListHeight)
                        
                        local baseHeight = 60 + displayListHeight + 10
                        if displayListHeight == 0 then baseHeight = 60 end
                        
                        if sIsDropdownOpen then
                            local totalWithDropdown = 55 + 120 + 10
                            if totalWithDropdown > baseHeight then
                                baseHeight = totalWithDropdown
                            end
                        end
                        TweenService:Create(SIFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, baseHeight)}):Play()
                    end

                    local function SRefreshAddedList()
                        for _, c in pairs(SAddedList:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
                        if #sAddedItems == 0 then
                            local Hint = Instance.new("TextLabel")
                            Hint.Text = "Nenhum ignorado"
                            Hint.Size = UDim2.new(1,0,0,20)
                            Hint.BackgroundTransparency = 1
                            Hint.TextColor3 = Themes.TextDim
                            Hint.TextTransparency = 0.5
                            Hint.Font = Enum.Font.Gotham
                            Hint.TextSize = 12
                            Hint.ZIndex = 85
                            Hint.Parent = SAddedList
                        else
                            for _, item in pairs(sAddedItems) do
                                local ItemFrame = Instance.new("Frame")
                                ItemFrame.Size = UDim2.new(1, 0, 0, 24)
                                ItemFrame.BackgroundColor3 = Color3.fromRGB(35,35,40)
                                ItemFrame.ZIndex = 85
                                ItemFrame.Parent = SAddedList
                                local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(0, 4); IC.Parent = ItemFrame

                                local ItemLab = Instance.new("TextLabel")
                                ItemLab.Text = "  " .. item
                                ItemLab.Size = UDim2.new(0.8, 0, 1, 0)
                                ItemLab.BackgroundTransparency = 1
                                ItemLab.TextColor3 = Themes.TextDim
                                ItemLab.Font = Enum.Font.Gotham
                                ItemLab.TextSize = 12
                                ItemLab.TextXAlignment = Enum.TextXAlignment.Left
                                ItemLab.ZIndex = 86
                                ItemLab.Parent = ItemFrame

                                local DelBtn = Instance.new("TextButton")
                                DelBtn.Text = "x"
                                DelBtn.Size = UDim2.new(0, 24, 0, 24)
                                DelBtn.Position = UDim2.new(1, -24, 0, 0)
                                DelBtn.BackgroundTransparency = 1
                                DelBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
                                DelBtn.Font = Enum.Font.GothamBold
                                DelBtn.TextSize = 14
                                DelBtn.ZIndex = 86
                                DelBtn.Parent = ItemFrame

                                DelBtn.MouseButton1Click:Connect(function()
                                    table.remove(sAddedItems, table.find(sAddedItems, item))
                                    pcall(onRemove, item)
                                    SRefreshAddedList()
                                end)
                            end
                        end
                        SUpdateSize()
                    end

                    SDropBtn.MouseButton1Click:Connect(function()
                        sIsDropdownOpen = not sIsDropdownOpen
                        if sIsDropdownOpen then
                            SDList.Visible = true
                            SDropArrow.Rotation = 180
                            for _, c in pairs(SDList:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
                            local opts = getOptionsFunc()
                            for _, opt in pairs(opts) do
                                local B = Instance.new("TextButton")
                                B.Size = UDim2.new(1, -10, 0, 20)
                                B.Text = opt
                                B.BackgroundTransparency = 1
                                B.TextColor3 = Themes.TextDim
                                B.Font = Enum.Font.Gotham
                                B.TextSize = 12
                                B.TextXAlignment = Enum.TextXAlignment.Left
                                B.ZIndex = 91
                                B.Parent = SDList

                                B.MouseButton1Click:Connect(function()
                                    sSelectedPlayer = opt
                                    SDropBtn.Text = "   " .. opt
                                    sIsDropdownOpen = false
                                    SDList.Visible = false
                                    SDropArrow.Rotation = 0
                                    SUpdateSize()
                                end)
                            end
                            SDList.CanvasSize = UDim2.new(0, 0, 0, SDLL.AbsoluteContentSize.Y + 10)
                        else
                            SDList.Visible = false
                            SDropArrow.Rotation = 0
                        end
                        SUpdateSize()
                    end)

                    SAddBtn.MouseButton1Click:Connect(function()
                        if sSelectedPlayer ~= "Selecionar..." and not table.find(sAddedItems, sSelectedPlayer) then
                            table.insert(sAddedItems, sSelectedPlayer)
                            pcall(onAdd, sSelectedPlayer)
                            sSelectedPlayer = "Selecionar..."
                            SDropBtn.Text = "   " .. sSelectedPlayer
                            SRefreshAddedList()
                        end
                    end)

                    SRefreshAddedList()
                    return SIFrame
                end

                return SubWindowFrame, SubGroupObj
            end

            function GroupObj:Toggle(text, default, callback, subConfigCallback, extraBtnText, extraBtnCallback, extraBtn2Text, extraBtn2Callback)
                local TFrame = CreateElementFrame(text)
                local hasSub = type(subConfigCallback) == "function"
                local hasExtra = extraBtnText and type(extraBtnCallback) == "function"
                local hasExtra2 = extraBtn2Text and type(extraBtn2Callback) == "function"
                
                local rightOffset = 50
                if hasSub then rightOffset = 78 end

                local TLab = Instance.new("TextLabel")
                TLab.Text = text
                TLab.Position = UDim2.new(0, 10, 0, 0)
                TLab.BackgroundTransparency = 1
                TLab.Font = Enum.Font.GothamMedium
                TLab.TextColor3 = Themes.Text
                TLab.TextSize = 13
                TLab.TextXAlignment = Enum.TextXAlignment.Left
                TLab.Parent = TFrame
                
                local totalExtraWidth = 0

                if hasExtra then
                    local ExtraBtn = Instance.new("TextButton")
                    ExtraBtn.Size = UDim2.new(0, 70, 0, 24)
                    ExtraBtn.Position = UDim2.new(1, -(rightOffset + 74), 0.5, -12)
                    ExtraBtn.BackgroundColor3 = Themes.Accent
                    ExtraBtn.Text = extraBtnText
                    ExtraBtn.Font = Enum.Font.GothamBold
                    ExtraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    ExtraBtn.TextSize = 11
                    ExtraBtn.ZIndex = 86
                    ExtraBtn.Parent = TFrame
                    local EBC = Instance.new("UICorner"); EBC.CornerRadius = UDim.new(0, 6); EBC.Parent = ExtraBtn
                    local EBS = Instance.new("UIStroke"); EBS.Color = Color3.fromRGB(255, 255, 255); EBS.Thickness = 1; EBS.Transparency = 0.8; EBS.Parent = ExtraBtn

                    ExtraBtn.MouseButton1Click:Connect(function()
                        pcall(extraBtnCallback)
                    end)
                    totalExtraWidth = 78
                end

                if hasExtra2 then
                    local ExtraBtn2 = Instance.new("TextButton")
                    ExtraBtn2.Size = UDim2.new(0, 84, 0, 24)
                    ExtraBtn2.Position = UDim2.new(1, -(rightOffset + totalExtraWidth + 88), 0.5, -12)
                    ExtraBtn2.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                    ExtraBtn2.Text = extraBtn2Text
                    ExtraBtn2.Font = Enum.Font.GothamBold
                    ExtraBtn2.TextColor3 = Themes.Accent
                    ExtraBtn2.TextSize = 11
                    ExtraBtn2.ZIndex = 86
                    ExtraBtn2.Parent = TFrame
                    local EBC2 = Instance.new("UICorner"); EBC2.CornerRadius = UDim.new(0, 6); EBC2.Parent = ExtraBtn2
                    local EBS2 = Instance.new("UIStroke"); EBS2.Color = Themes.Accent; EBS2.Thickness = 1; EBS2.Transparency = 0.6; EBS2.Parent = ExtraBtn2

                    ExtraBtn2.MouseButton1Click:Connect(function()
                        pcall(extraBtn2Callback, ExtraBtn2)
                    end)
                    totalExtraWidth = totalExtraWidth + 92
                end

                TLab.Size = UDim2.new(1, -(rightOffset + totalExtraWidth + 10), 1, 0)
                
                local TBtn = Instance.new("TextButton")
                TBtn.Size = UDim2.new(0, 40, 0, 20)
                TBtn.Position = UDim2.new(1, -50, 0.5, -10)
                TBtn.BackgroundColor3 = default and Themes.Accent or Color3.fromRGB(60,60,65)
                TBtn.Text = ""
                TBtn.ZIndex = 86
                TBtn.Parent = TFrame
                local TBC = Instance.new("UICorner"); TBC.CornerRadius = UDim.new(1, 0); TBC.Parent = TBtn
                
                local circle = Instance.new("Frame")
                circle.Size = UDim2.new(0, 16, 0, 16)
                circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
                circle.ZIndex = 87
                circle.Parent = TBtn
                local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(1, 0); CC.Parent = circle

                local enabled = default
                local GearBtn = nil
                local subWindowFrame = nil

                if hasSub then
                    GearBtn = Instance.new("ImageButton")
                    GearBtn.Size = UDim2.new(0, 20, 0, 20)
                    GearBtn.Position = UDim2.new(1, -78, 0.5, -10)
                    GearBtn.BackgroundTransparency = 1
                    GearBtn.ZIndex = 86
                    GearBtn.Image = "rbxassetid://6031280882" -- Ícone de engrenagem
                    GearBtn.ImageColor3 = enabled and Themes.Accent or Color3.fromRGB(150, 150, 160)
                    GearBtn.ImageTransparency = enabled and 0 or 0.3
                    GearBtn.Parent = TFrame

                    -- Criar o Hub Secundário (Sub-Hub)
                    local subFrame, subGroupObj = CreateSubWindow("Configurações - " .. text)
                    subWindowFrame = subFrame

                    -- Executar callback para popular o Sub-Hub
                    pcall(subConfigCallback, subGroupObj)

                    -- Evento de clique na Engrenagem (Sempre acessível!)
                    GearBtn.MouseButton1Click:Connect(function()
                        subWindowFrame.Visible = not subWindowFrame.Visible
                        if subWindowFrame.Visible then
                            subWindowFrame.Size = UDim2.new(0, 360, 0, 0)
                            subWindowFrame.BackgroundTransparency = 1
                            TweenService:Create(subWindowFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, 260), BackgroundTransparency = 0}):Play()
                        end
                    end)
                end
                
                local ToggleObj = {
                    Frame = TFrame,
                    Get = function() return enabled end,
                    Set = function(val)
                        enabled = val
                        TweenService:Create(circle, TweenInfo.new(0.2), {Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                        TweenService:Create(TBtn, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Themes.Accent or Color3.fromRGB(60,60,65)}):Play()
                        
                        if GearBtn then
                            TweenService:Create(GearBtn, TweenInfo.new(0.2), {
                                ImageColor3 = enabled and Themes.Accent or Color3.fromRGB(150, 150, 160),
                                ImageTransparency = enabled and 0 or 0.3
                            }):Play()
                        end
                        pcall(callback, enabled)
                    end
                }

                TBtn.MouseButton1Click:Connect(function()
                    ToggleObj.Set(not enabled)
                end)

                getgenv().RegisteredSockets = getgenv().RegisteredSockets or {}
                getgenv().RegisteredSockets[text] = {
                    type = "Toggle",
                    text = text,
                    get = function() return ToggleObj.Get() end,
                    set = function(v) ToggleObj.Set(v) end,
                    extraBtnText = extraBtnText,
                    extraBtnCallback = extraBtnCallback,
                    extraBtn2Text = extraBtn2Text,
                    extraBtn2Callback = extraBtn2Callback
                }

                return ToggleObj
            end

            function GroupObj:ToggleKeybind(text, defaultState, defaultKey, toggleCallback, keybindCallback, subConfigCallback)
                local TFrame = CreateElementFrame(text)
                local hasSub = type(subConfigCallback) == "function"
                
                local rightOffset = hasSub and 125 or 95
                local TLab = Instance.new("TextLabel")
                TLab.Text = text
                TLab.Position = UDim2.new(0, 10, 0, 0)
                TLab.Size = UDim2.new(1, -(rightOffset + 45), 1, 0)
                TLab.BackgroundTransparency = 1
                TLab.Font = Enum.Font.GothamMedium
                TLab.TextColor3 = Themes.Text
                TLab.TextSize = 13
                TLab.TextXAlignment = Enum.TextXAlignment.Left
                TLab.Parent = TFrame
                
                local function FormatKeyName(key)
                    if typeof(key) == "EnumItem" then
                        if key.EnumType == Enum.KeyCode then
                            return key.Name
                        elseif key.EnumType == Enum.UserInputType then
                            if key == Enum.UserInputType.MouseButton1 then
                                return "M1"
                            elseif key == Enum.UserInputType.MouseButton2 then
                                return "M2"
                            elseif key == Enum.UserInputType.MouseButton3 then
                                return "M3"
                            else
                                return key.Name
                            end
                        end
                    elseif typeof(key) == "string" then
                        local strKey = key:lower()
                        if strKey == "rightclick" or strKey == "mousebutton2" or strKey == "m2" then return "M2" end
                        if strKey == "leftclick" or strKey == "mousebutton1" or strKey == "m1" then return "M1" end
                        if strKey == "middleclick" or strKey == "mousebutton3" or strKey == "m3" then return "M3" end
                        if strKey == "mousebutton4" or strKey == "m4" or strKey == "side1" then return "M4" end
                        if strKey == "mousebutton5" or strKey == "m5" or strKey == "side2" then return "M5" end
                        return key
                    end
                    return "M2"
                end

                local KeyBtn = Instance.new("TextButton")
                KeyBtn.Size = UDim2.new(0, 42, 0, 22)
                KeyBtn.Position = UDim2.new(1, -(hasSub and 125 or 95), 0.5, -11)
                KeyBtn.BackgroundColor3 = Themes.Element
                local currentKey = defaultKey or Enum.KeyCode.E
                KeyBtn.Text = FormatKeyName(currentKey)
                KeyBtn.Font = Enum.Font.GothamBold
                KeyBtn.TextColor3 = Themes.Text
                KeyBtn.TextSize = 11
                KeyBtn.ZIndex = 86
                KeyBtn.Parent = TFrame
                local KBC = Instance.new("UICorner"); KBC.CornerRadius = UDim.new(0, 6); KBC.Parent = KeyBtn
                local KBS = Instance.new("UIStroke"); KBS.Color = Themes.Accent; KBS.Thickness = 1; KBS.Transparency = 0.5; KBS.Parent = KeyBtn

                local listening = false
                KeyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    KeyBtn.Text = "..."
                    KeyBtn.TextColor3 = Themes.Accent
                    
                    local conn
                    conn = game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local pressedKey = input.KeyCode
                            if pressedKey ~= Enum.KeyCode.Escape then
                                currentKey = pressedKey
                                KeyBtn.Text = FormatKeyName(currentKey)
                                pcall(keybindCallback, currentKey)
                            else
                                KeyBtn.Text = FormatKeyName(currentKey)
                            end
                            listening = false
                            KeyBtn.TextColor3 = Themes.Text
                            conn:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 
                            or input.UserInputType == Enum.UserInputType.MouseButton2 
                            or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            currentKey = input.UserInputType
                            KeyBtn.Text = FormatKeyName(currentKey)
                            pcall(keybindCallback, currentKey)
                            listening = false
                            KeyBtn.TextColor3 = Themes.Text
                            conn:Disconnect()
                        end
                    end)

                    local hasKeyCheck = (typeof(iskeydown) == "function") or (typeof(iskeypressed) == "function")
                    local keyCheckFunc = iskeydown or iskeypressed
                    if hasKeyCheck then
                        task.spawn(function()
                            while listening do
                                if keyCheckFunc(0x05) then
                                    currentKey = "M4"
                                    KeyBtn.Text = "M4"
                                    pcall(keybindCallback, "M4")
                                    listening = false
                                    KeyBtn.TextColor3 = Themes.Text
                                    if conn then conn:Disconnect() end
                                    break
                                elseif keyCheckFunc(0x06) then
                                    currentKey = "M5"
                                    KeyBtn.Text = "M5"
                                    pcall(keybindCallback, "M5")
                                    listening = false
                                    KeyBtn.TextColor3 = Themes.Text
                                    if conn then conn:Disconnect() end
                                    break
                                end
                                task.wait(0.03)
                            end
                        end)
                    end
                end)
                
                local TBtn = Instance.new("TextButton")
                TBtn.Size = UDim2.new(0, 40, 0, 20)
                TBtn.Position = UDim2.new(1, -50, 0.5, -10)
                TBtn.BackgroundColor3 = defaultState and Themes.Accent or Color3.fromRGB(60,60,65)
                TBtn.Text = ""
                TBtn.ZIndex = 86
                TBtn.Parent = TFrame
                local TBC = Instance.new("UICorner"); TBC.CornerRadius = UDim.new(1, 0); TBC.Parent = TBtn
                
                local circle = Instance.new("Frame")
                circle.Size = UDim2.new(0, 16, 0, 16)
                circle.Position = defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
                circle.ZIndex = 87
                circle.Parent = TBtn
                local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(1, 0); CC.Parent = circle

                local enabled = defaultState
                local GearBtn = nil
                local subWindowFrame = nil

                if hasSub then
                    GearBtn = Instance.new("ImageButton")
                    GearBtn.Size = UDim2.new(0, 20, 0, 20)
                    GearBtn.Position = UDim2.new(1, -78, 0.5, -10)
                    GearBtn.BackgroundTransparency = 1
                    GearBtn.ZIndex = 86
                    GearBtn.Image = "rbxassetid://6031280882" -- Ícone de engrenagem
                    GearBtn.ImageColor3 = enabled and Themes.Accent or Color3.fromRGB(150, 150, 160)
                    GearBtn.ImageTransparency = enabled and 0 or 0.3
                    GearBtn.Parent = TFrame

                    local subFrame, subGroupObj = CreateSubWindow("Configurações - " .. text)
                    subWindowFrame = subFrame

                    GearBtn.MouseButton1Click:Connect(function()
                        subWindowFrame.Visible = not subWindowFrame.Visible
                        if subWindowFrame.Visible then
                            subWindowFrame.Size = UDim2.new(0, 360, 0, 0)
                            subWindowFrame.BackgroundTransparency = 1
                            TweenService:Create(subWindowFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, 320), BackgroundTransparency = 0}):Play()
                        end
                    end)

                    pcall(subConfigCallback, subGroupObj)
                end

                local ToggleObj = {
                    Frame = TFrame,
                    Get = function() return enabled end,
                    GetKey = function() return currentKey end,
                    Set = function(val)
                        enabled = val
                        TweenService:Create(circle, TweenInfo.new(0.2), {Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                        TweenService:Create(TBtn, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Themes.Accent or Color3.fromRGB(60,60,65)}):Play()
                        if GearBtn then
                            TweenService:Create(GearBtn, TweenInfo.new(0.2), {
                                ImageColor3 = enabled and Themes.Accent or Color3.fromRGB(150, 150, 160),
                                ImageTransparency = enabled and 0 or 0.3
                            }):Play()
                        end
                        pcall(toggleCallback, enabled)
                    end,
                    SetKey = function(key)
                        currentKey = key
                        KeyBtn.Text = FormatKeyName(currentKey)
                        pcall(keybindCallback, currentKey)
                    end
                }

                TBtn.MouseButton1Click:Connect(function()
                    ToggleObj.Set(not enabled)
                end)

                getgenv().RegisteredSockets = getgenv().RegisteredSockets or {}
                getgenv().RegisteredSockets[text] = {
                    type = "Toggle",
                    text = text,
                    get = function() return ToggleObj.Get() end,
                    set = function(v) ToggleObj.Set(v) end
                }

                return ToggleObj
            end
            
            function GroupObj:Slider(text, min, max, default, callback, valueFormatter)
                local SFrame = CreateElementFrame(text)
                SFrame.Size = UDim2.new(1, 0, 0, 50)
                
                local SLab = Instance.new("TextLabel")
                SLab.Text = text
                SLab.Size = UDim2.new(1, -10, 0, 20)
                SLab.Position = UDim2.new(0, 10, 0, 5)
                SLab.BackgroundTransparency = 1
                SLab.Font = Enum.Font.GothamMedium
                SLab.TextColor3 = Themes.Text
                SLab.TextSize = 13
                SLab.TextXAlignment = Enum.TextXAlignment.Left
                SLab.Parent = SFrame
                
                local formatter = valueFormatter or function(v) return tostring(v) end

                local ValLab = Instance.new("TextLabel")
                ValLab.Text = formatter(default)
                ValLab.Size = UDim2.new(0, 60, 0, 20) -- Maintained size increase for dual values
                ValLab.Position = UDim2.new(1, -70, 0, 5)
                ValLab.BackgroundTransparency = 1
                ValLab.Font = Enum.Font.Gotham
                ValLab.TextColor3 = Themes.TextDim
                ValLab.TextSize = 12
                ValLab.TextXAlignment = Enum.TextXAlignment.Right
                ValLab.Parent = SFrame
                
                local Track = Instance.new("TextButton")
                Track.Text = ""
                Track.Size = UDim2.new(1, -20, 0, 4)
                Track.Position = UDim2.new(0, 10, 0, 35)
                Track.BackgroundColor3 = Color3.fromRGB(50,50,55)
                Track.Parent = SFrame
                local TrC = Instance.new("UICorner"); TrC.CornerRadius = UDim.new(1, 0); TrC.Parent = Track
                
                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
                Fill.BackgroundColor3 = Themes.Accent
                Fill.Parent = Track
                local FC = Instance.new("UICorner"); FC.CornerRadius = UDim.new(1, 0); FC.Parent = Fill
                
                local currentVal = default
                local dragging = false
                local function update(input)
                    local pos = input.Position.X
                    local rect = Track.AbsolutePosition.X
                    local size = Track.AbsoluteSize.X
                    local percent = math.clamp((pos - rect) / size, 0, 1)
                    local val = math.floor(min + (max - min) * percent)
                    currentVal = val
                    ValLab.Text = formatter(val)
                    Fill.Size = UDim2.new(percent, 0, 1, 0)
                    pcall(callback, val)
                end
                
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                        dragging = true
                        update(input) 
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                        update(input) 
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                        dragging = false 
                    end
                end)

                local SliderObj = {
                    Frame = SFrame,
                    Get = function() return currentVal end,
                    Set = function(val)
                        val = math.clamp(val, min, max)
                        currentVal = val
                        local percent = (val - min) / (max - min)
                        ValLab.Text = formatter(val)
                        Fill.Size = UDim2.new(percent, 0, 1, 0)
                        pcall(callback, val)
                    end
                }
                return SliderObj
            end

            function GroupObj:Input(text, defaultVal, minVal, maxVal, callback, unitText)
                local IFrame = CreateElementFrame(text)
                IFrame.Size = UDim2.new(1, 0, 0, 36)

                local ILab = Instance.new("TextLabel")
                ILab.Text = text
                ILab.Position = UDim2.new(0, 10, 0, 0)
                ILab.Size = UDim2.new(1, -110, 1, 0)
                ILab.BackgroundTransparency = 1
                ILab.Font = Enum.Font.GothamMedium
                ILab.TextColor3 = Themes.Text
                ILab.TextSize = 13
                ILab.TextXAlignment = Enum.TextXAlignment.Left
                ILab.Parent = IFrame

                local TBox = Instance.new("TextBox")
                TBox.Size = UDim2.new(0, 90, 0, 24)
                TBox.Position = UDim2.new(1, -100, 0.5, -12)
                TBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
                TBox.Text = tostring(defaultVal or 50) .. (unitText and (" " .. unitText) or "")
                TBox.Font = Enum.Font.GothamBold
                TBox.TextColor3 = Themes.Accent
                TBox.TextSize = 12
                TBox.ClearTextOnFocus = false
                TBox.ZIndex = 86
                TBox.Parent = IFrame
                local TBC = Instance.new("UICorner"); TBC.CornerRadius = UDim.new(0, 6); TBC.Parent = TBox
                local TBS = Instance.new("UIStroke"); TBS.Color = Themes.Accent; TBS.Thickness = 1; TBS.Transparency = 0.5; TBS.Parent = TBox

                local currentValue = tonumber(defaultVal) or 50

                local function applyValue()
                    local cleanStr = TBox.Text:gsub("[^%d%.]", "")
                    local num = tonumber(cleanStr)
                    if num then
                        if minVal then num = math.max(minVal, num) end
                        if maxVal then num = math.min(maxVal, num) end
                        currentValue = num
                    end
                    TBox.Text = tostring(currentValue) .. (unitText and (" " .. unitText) or "")
                    pcall(callback, currentValue)
                end

                TBox.FocusLost:Connect(function(enterPressed)
                    applyValue()
                end)

                local InputObj = {
                    Frame = IFrame,
                    Get = function() return currentValue end,
                    Set = function(val)
                        local num = tonumber(val) or currentValue
                        if minVal then num = math.max(minVal, num) end
                        if maxVal then num = math.min(maxVal, num) end
                        currentValue = num
                        TBox.Text = tostring(currentValue) .. (unitText and (" " .. unitText) or "")
                        pcall(callback, currentValue)
                    end
                }
                return InputObj
            end
            
            function GroupObj:Button(text, callback)
                local BFrame = CreateElementFrame()
                local Btn = Instance.new("TextButton")
                Btn.Text = text
                Btn.Size = UDim2.new(1, 0, 1, 0)
                Btn.BackgroundTransparency = 1
                Btn.Font = Enum.Font.GothamBold
                Btn.TextColor3 = Themes.Text
                Btn.TextSize = 13
                Btn.Parent = BFrame
                Btn.MouseButton1Click:Connect(callback)
                return BFrame
            end

            function GroupObj:ActionButton(text, btnText, callback, canFavorite, subConfigCallback)
                local AFrame = (canFavorite == false) and CreateElementFrame(nil) or CreateElementFrame(text)
                local hasSub = type(subConfigCallback) == "function"
                
                local rightOffset = 85
                if hasSub then rightOffset = 110 end

                local TLab = Instance.new("TextLabel")
                TLab.Text = text
                TLab.Position = UDim2.new(0, 10, 0, 0)
                TLab.Size = UDim2.new(1, -(rightOffset + 10), 1, 0)
                TLab.BackgroundTransparency = 1
                TLab.Font = Enum.Font.GothamMedium
                TLab.TextColor3 = Themes.Text
                TLab.TextSize = 13
                TLab.TextXAlignment = Enum.TextXAlignment.Left
                TLab.Parent = AFrame
                
                local ActionBtn = Instance.new("TextButton")
                ActionBtn.Size = UDim2.new(0, 75, 0, 24)
                ActionBtn.Position = UDim2.new(1, -(hasSub and 110 or 85), 0.5, -12)
                ActionBtn.BackgroundColor3 = Themes.Accent
                ActionBtn.Text = btnText or "Abrir"
                ActionBtn.Font = Enum.Font.GothamBold
                ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                ActionBtn.TextSize = 12
                ActionBtn.ZIndex = 86
                ActionBtn.Parent = AFrame
                local ABC = Instance.new("UICorner"); ABC.CornerRadius = UDim.new(0, 6); ABC.Parent = ActionBtn
                local ABS = Instance.new("UIStroke"); ABS.Color = Color3.fromRGB(255, 255, 255); ABS.Thickness = 1; ABS.Transparency = 0.8; ABS.Parent = ActionBtn

                ActionBtn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)

                if hasSub then
                    local GearBtn = Instance.new("ImageButton")
                    GearBtn.Size = UDim2.new(0, 20, 0, 20)
                    GearBtn.Position = UDim2.new(1, -30, 0.5, -10)
                    GearBtn.BackgroundTransparency = 1
                    GearBtn.ZIndex = 86
                    GearBtn.Image = "rbxassetid://6031280882" -- Ícone de engrenagem
                    GearBtn.ImageColor3 = Themes.Accent
                    GearBtn.ImageTransparency = 0
                    GearBtn.Parent = AFrame

                    local subFrame, subGroupObj = CreateSubWindow("Configurações - " .. text)
                    GearBtn.MouseButton1Click:Connect(function()
                        subFrame.Visible = not subFrame.Visible
                        if subFrame.Visible then
                            subFrame.Size = UDim2.new(0, 360, 0, 0)
                            subFrame.BackgroundTransparency = 1
                            TweenService:Create(subFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, 260), BackgroundTransparency = 0}):Play()
                        end
                    end)

                    pcall(subConfigCallback, subGroupObj)
                end
                
                return AFrame
            end

            function GroupObj:Bind(text, defaultKey, callback)
                local BFrame = CreateElementFrame()
                
                local TLab = Instance.new("TextLabel")
                TLab.Text = text
                TLab.Size = UDim2.new(1, -100, 1, 0)
                TLab.Position = UDim2.new(0, 10, 0, 0)
                TLab.BackgroundTransparency = 1
                TLab.Font = Enum.Font.GothamMedium
                TLab.TextColor3 = Themes.Text
                TLab.TextSize = 13
                TLab.TextXAlignment = Enum.TextXAlignment.Left
                TLab.Parent = BFrame

                local function FormatKeyName(key)
                    if typeof(key) == "EnumItem" then
                        if key.EnumType == Enum.KeyCode then
                            return key.Name
                        elseif key.EnumType == Enum.UserInputType then
                            if key == Enum.UserInputType.MouseButton1 then return "M1"
                            elseif key == Enum.UserInputType.MouseButton2 then return "M2"
                            elseif key == Enum.UserInputType.MouseButton3 then return "M3"
                            else return key.Name end
                        end
                    elseif typeof(key) == "string" then
                        local strKey = key:lower()
                        if strKey == "rightclick" or strKey == "mousebutton2" or strKey == "m2" then return "M2" end
                        if strKey == "leftclick" or strKey == "mousebutton1" or strKey == "m1" then return "M1" end
                        if strKey == "middleclick" or strKey == "mousebutton3" or strKey == "m3" then return "M3" end
                        if strKey == "mousebutton4" or strKey == "m4" or strKey == "side1" then return "M4" end
                        if strKey == "mousebutton5" or strKey == "m5" or strKey == "side2" then return "M5" end
                        return key
                    end
                    return "E"
                end
                
                local BindBtn = Instance.new("TextButton")
                local currentKey = defaultKey or Enum.KeyCode.E
                BindBtn.Text = FormatKeyName(currentKey)
                BindBtn.Size = UDim2.new(0, 80, 0, 20)
                BindBtn.Position = UDim2.new(1, -90, 0.5, -10)
                BindBtn.BackgroundColor3 = Color3.fromRGB(50,50,55)
                BindBtn.Font = Enum.Font.GothamBold
                BindBtn.TextColor3 = Themes.Text
                BindBtn.TextSize = 12
                BindBtn.Parent = BFrame
                local BBC = Instance.new("UICorner"); BBC.CornerRadius = UDim.new(0, 4); BBC.Parent = BindBtn
                
                BindBtn.MouseButton1Click:Connect(function()
                    if getgenv().IsBindingKey then return end
                    getgenv().IsBindingKey = true
                    BindBtn.Text = "..."
                    BindBtn.TextColor3 = Themes.Accent
                    
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode
                            if newKey ~= Enum.KeyCode.Escape then
                                currentKey = newKey
                                BindBtn.Text = FormatKeyName(currentKey)
                                pcall(callback, currentKey)
                            else
                                BindBtn.Text = FormatKeyName(currentKey)
                            end
                            BindBtn.TextColor3 = Themes.Text
                            getgenv().IsBindingKey = false
                            conn:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 
                            or input.UserInputType == Enum.UserInputType.MouseButton2 
                            or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            currentKey = input.UserInputType
                            BindBtn.Text = FormatKeyName(currentKey)
                            BindBtn.TextColor3 = Themes.Text
                            getgenv().IsBindingKey = false
                            conn:Disconnect()
                            pcall(callback, currentKey)
                        end
                    end)

                    local hasKeyCheck = (typeof(iskeydown) == "function") or (typeof(iskeypressed) == "function")
                    local keyCheckFunc = iskeydown or iskeypressed
                    if hasKeyCheck then
                        task.spawn(function()
                            while getgenv().IsBindingKey do
                                if keyCheckFunc(0x05) then
                                    currentKey = "M4"
                                    BindBtn.Text = "M4"
                                    BindBtn.TextColor3 = Themes.Text
                                    getgenv().IsBindingKey = false
                                    if conn then conn:Disconnect() end
                                    pcall(callback, "M4")
                                    break
                                elseif keyCheckFunc(0x06) then
                                    currentKey = "M5"
                                    BindBtn.Text = "M5"
                                    BindBtn.TextColor3 = Themes.Text
                                    getgenv().IsBindingKey = false
                                    if conn then conn:Disconnect() end
                                    pcall(callback, "M5")
                                    break
                                end
                                task.wait(0.03)
                            end
                        end)
                    end
                end)
                return BFrame
            end
            
            function GroupObj:Dropdown(text, options, default, callback)
                local DFrame = CreateElementFrame()
                DFrame.Size = UDim2.new(1, 0, 0, 50) -- Default height closed
                DFrame.ClipsDescendants = true
                DFrame.ZIndex = 5 -- Higher ZIndex for dropdown

                local DLab = Instance.new("TextLabel")
                DLab.Text = text
                DLab.Size = UDim2.new(1, -10, 0, 20)
                DLab.Position = UDim2.new(0, 10, 0, 5)
                DLab.BackgroundTransparency = 1
                DLab.Font = Enum.Font.GothamMedium
                DLab.TextColor3 = Themes.Text
                DLab.TextSize = 13
                DLab.TextXAlignment = Enum.TextXAlignment.Left
                DLab.Parent = DFrame
                
                local currentOption = default or options[1] or "..."
                
                local DropBtn = Instance.new("TextButton")
                DropBtn.Size = UDim2.new(1, -20, 0, 20)
                DropBtn.Position = UDim2.new(0, 10, 0, 25)
                DropBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
                DropBtn.Text = "   " .. tostring(currentOption)
                DropBtn.Font = Enum.Font.Gotham
                DropBtn.TextSize = 12
                DropBtn.TextColor3 = Themes.TextDim
                DropBtn.TextXAlignment = Enum.TextXAlignment.Left
                DropBtn.Parent = DFrame
                local DC = Instance.new("UICorner"); DC.CornerRadius = UDim.new(0, 4); DC.Parent = DropBtn
                
                local Arrow = Instance.new("TextLabel")
                Arrow.Text = "v"
                Arrow.Size = UDim2.new(0, 20, 1, 0)
                Arrow.Position = UDim2.new(1, -20, 0, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.TextColor3 = Themes.TextDim
                Arrow.Font = Enum.Font.GothamBold
                Arrow.Parent = DropBtn

                -- Container for list
                local ListFrame = Instance.new("ScrollingFrame")
                ListFrame.Size = UDim2.new(1, -20, 0, 100)
                ListFrame.Position = UDim2.new(0, 10, 0, 55) -- Under the button
                ListFrame.BackgroundColor3 = Color3.fromRGB(40,40,45)
                ListFrame.BorderSizePixel = 0
                ListFrame.ScrollBarThickness = 2
                ListFrame.Visible = false
                ListFrame.ZIndex = 10
                ListFrame.Parent = DFrame
                local LC = Instance.new("UICorner"); LC.CornerRadius = UDim.new(0, 4); LC.Parent = ListFrame
                local LPad = Instance.new("UIPadding"); LPad.PaddingTop = UDim.new(0,5); LPad.PaddingLeft = UDim.new(0,5); LPad.Parent = ListFrame
                local LLayout = Instance.new("UIListLayout"); LLayout.Padding = UDim.new(0, 2); LLayout.SortOrder = Enum.SortOrder.LayoutOrder; LLayout.Parent = ListFrame

                local isOpen = false
                
                local DropdownObj = {}

                -- Function to refresh the list elements
                function DropdownObj:Refresh(newOptions)
                    options = newOptions
                    -- Clear existing
                    for _, child in pairs(ListFrame:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    
                    -- Rebuild
                    for i, opt in pairs(options) do
                        local OptBtn = Instance.new("TextButton")
                        OptBtn.Size = UDim2.new(1, -10, 0, 20)
                        OptBtn.BackgroundTransparency = 1
                        OptBtn.Text = tostring(opt)
                        OptBtn.TextColor3 = Themes.TextDim
                        OptBtn.Font = Enum.Font.Gotham
                        OptBtn.TextSize = 12
                        OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                        OptBtn.ZIndex = 11
                        OptBtn.Parent = ListFrame
                        
                        OptBtn.MouseButton1Click:Connect(function()
                            currentOption = opt
                            DropBtn.Text = "   " .. tostring(opt)
                            pcall(callback, opt)
                            -- Close
                            isOpen = false
                            ListFrame.Visible = false
                            TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                            TweenService:Create(DFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 50)}):Play()
                            
                            -- Notify Group Layout Update
                            task.delay(0.3, function() 
                                if Container then 
                                    -- Trigger resize of container if needed, tricky with nested layouts
                                    -- Usually just changing DFrame size handles it if Layout is listening
                                end
                            end)
                        end)
                    end
                    ListFrame.CanvasSize = UDim2.new(0, 0, 0, LLayout.AbsoluteContentSize.Y + 10)
                end

                DropBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        ListFrame.Visible = true
                        TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 180}):Play()
                        TweenService:Create(DFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 160)}):Play() -- Expand
                    else
                        ListFrame.Visible = false
                        TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                        TweenService:Create(DFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 50)}):Play() -- Collapse
                    end
                end)
                
                -- Init
                DropdownObj:Refresh(options)
                
                -- Keep selection valid if not in new options?
                -- For 'Todos' logic, we assume it's always there.
                
                return DropdownObj
            end

            function GroupObj:InteractiveList(text, getOptionsFunc, onAdd, onRemove)
                local IFrame = CreateElementFrame()
                IFrame.Size = UDim2.new(1, 0, 0, 80) -- Initial size
                IFrame.ClipsDescendants = true
                IFrame.ZIndex = 4

                local ILab = Instance.new("TextLabel")
                ILab.Text = text
                ILab.Size = UDim2.new(1, -10, 0, 20)
                ILab.Position = UDim2.new(0, 10, 0, 5)
                ILab.BackgroundTransparency = 1
                ILab.Font = Enum.Font.GothamMedium
                ILab.TextColor3 = Themes.Text
                ILab.TextSize = 13
                ILab.TextXAlignment = Enum.TextXAlignment.Left
                ILab.Parent = IFrame

                -- Dropdown for selection
                local selectedPlayer = "Selecionar..."
                local DropBtn = Instance.new("TextButton")
                DropBtn.Size = UDim2.new(0.65, 0, 0, 25)
                DropBtn.Position = UDim2.new(0, 10, 0, 25)
                DropBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
                DropBtn.Text = "   " .. selectedPlayer
                DropBtn.Font = Enum.Font.Gotham
                DropBtn.TextSize = 12
                DropBtn.TextColor3 = Themes.TextDim
                DropBtn.TextXAlignment = Enum.TextXAlignment.Left
                DropBtn.Parent = IFrame
                local DC = Instance.new("UICorner"); DC.CornerRadius = UDim.new(0, 4); DC.Parent = DropBtn
                
                local DropArrow = Instance.new("TextLabel")
                DropArrow.Text = "v"
                DropArrow.Size = UDim2.new(0, 20, 1, 0)
                DropArrow.Position = UDim2.new(1, -20, 0, 0)
                DropArrow.BackgroundTransparency = 1
                DropArrow.TextColor3 = Themes.TextDim
                DropArrow.Font = Enum.Font.GothamBold
                DropArrow.Parent = DropBtn

                -- Add Button
                local AddBtn = Instance.new("TextButton")
                AddBtn.Size = UDim2.new(0.25, 0, 0, 25)
                AddBtn.Position = UDim2.new(0, 0, 0, 25)
                AddBtn.AnchorPoint = Vector2.new(0,0)
                -- Position logic: 10px (left) + 0.65 width + 10px spacing?
                -- Using anchor point relative to frame right might be easier but let's stick to UDim2 math
                AddBtn.Position = UDim2.new(0.7, 5, 0, 25)
                AddBtn.BackgroundColor3 = Themes.Accent
                AddBtn.Text = "Add +"
                AddBtn.Font = Enum.Font.GothamBold
                AddBtn.TextSize = 12
                AddBtn.TextColor3 = Themes.Text
                AddBtn.Parent = IFrame
                local AC = Instance.new("UICorner"); AC.CornerRadius = UDim.new(0, 4); AC.Parent = AddBtn

                -- Added Items List Container
                local AddedList = Instance.new("ScrollingFrame")
                AddedList.Size = UDim2.new(1, -20, 0, 0) -- Height dynamic
                AddedList.Position = UDim2.new(0, 10, 0, 60)
                AddedList.BackgroundTransparency = 1
                AddedList.BorderSizePixel = 0
                AddedList.ScrollBarThickness = 2
                AddedList.Parent = IFrame
                local ALL = Instance.new("UIListLayout"); ALL.Padding = UDim.new(0, 5); ALL.Parent = AddedList; ALL.SortOrder = Enum.SortOrder.LayoutOrder

                -- Dropdown List (Options)
                local DList = Instance.new("ScrollingFrame")
                DList.Size = UDim2.new(0.65, 0, 0, 120)
                DList.Position = UDim2.new(0, 10, 0, 55)
                DList.BackgroundColor3 = Color3.fromRGB(40,40,45)
                DList.Visible = false
                DList.ZIndex = 20
                DList.BorderSizePixel = 0
                DList.Parent = IFrame
                local DLC = Instance.new("UICorner"); DLC.CornerRadius = UDim.new(0, 4); DLC.Parent = DList
                local DLL = Instance.new("UIListLayout"); DLL.Parent = DList; DLL.SortOrder = Enum.SortOrder.LayoutOrder; DLL.Padding = UDim.new(0, 2)
                local DP = Instance.new("UIPadding"); DP.PaddingLeft = UDim.new(0, 5); DP.PaddingTop = UDim.new(0, 5); DP.Parent = DList

                local addedItems = {}
                local isDropdownOpen = false
                
                local function UpdateSize()
                    local listHeight = ALL.AbsoluteContentSize.Y
                    AddedList.CanvasSize = UDim2.new(0, 0, 0, listHeight)
                    -- Determine required height for the Added List (limit it to avoid massive UI)
                    local displayListHeight = math.min(listHeight, 150)
                    AddedList.Size = UDim2.new(1, -20, 0, displayListHeight)
                    
                    local baseHeight = 60 + displayListHeight + 10 
                    if displayListHeight == 0 then baseHeight = 60 end -- Minimal height if empty
                    
                    if isDropdownOpen then
                        local totalWithDropdown = 55 + 120 + 10
                        if totalWithDropdown > baseHeight then
                            baseHeight = totalWithDropdown
                        end
                    end
                    
                    TweenService:Create(IFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, baseHeight)}):Play()
                    
                     -- Force Layout Update for Group
                     task.delay(0.35, function() 
                        if IFrame.Parent and IFrame.Parent:IsA("UIListLayout") then
                            IFrame.Parent:ApplyLayout()
                        end
                         -- Hacky fix: Force the Group (parent of container) to resize
                         local container = IFrame.Parent.Parent
                         if container and container:FindFirstChild("UIListLayout") then
                             -- Usually container.Parent is the Group Frame
                             -- We need to check if VoidLib has a mechanism for this.
                             -- Assuming standard AutoLayout or manual resize from Lib
                         end
                    end)
                end

                local function RefreshAddedList()
                    -- clear
                    for _, c in pairs(AddedList:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
                    
                    if #addedItems == 0 then
                         local Hint = Instance.new("TextLabel")
                         Hint.Text = "Nenhum ignorado"
                         Hint.Size = UDim2.new(1,0,0,20)
                         Hint.BackgroundTransparency = 1
                         Hint.TextColor3 = Themes.TextDim
                         Hint.TextTransparency = 0.5
                         Hint.Font = Enum.Font.Gotham
                         Hint.TextSize = 12
                         Hint.Parent = AddedList
                    else
                        for i, item in pairs(addedItems) do
                            local ItemFrame = Instance.new("Frame")
                            ItemFrame.Size = UDim2.new(1, 0, 0, 24)
                            ItemFrame.BackgroundColor3 = Color3.fromRGB(35,35,40)
                            ItemFrame.Parent = AddedList
                            local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(0, 4); IC.Parent = ItemFrame
                            
                            local ItemLab = Instance.new("TextLabel")
                            ItemLab.Text = "  " .. item
                            ItemLab.Size = UDim2.new(0.8, 0, 1, 0)
                            ItemLab.BackgroundTransparency = 1
                            ItemLab.TextColor3 = Themes.TextDim
                            ItemLab.Font = Enum.Font.Gotham
                            ItemLab.TextSize = 12
                            ItemLab.TextXAlignment = Enum.TextXAlignment.Left
                            ItemLab.Parent = ItemFrame
                            
                            local DelBtn = Instance.new("TextButton")
                            DelBtn.Text = "x"
                            DelBtn.Size = UDim2.new(0, 24, 0, 24)
                            DelBtn.Position = UDim2.new(1, -24, 0, 0)
                            DelBtn.BackgroundTransparency = 1
                            DelBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
                            DelBtn.Font = Enum.Font.GothamBold
                            DelBtn.TextSize = 14
                            DelBtn.Parent = ItemFrame
                            
                            DelBtn.MouseButton1Click:Connect(function()
                                table.remove(addedItems, table.find(addedItems, item))
                                pcall(onRemove, item)
                                RefreshAddedList()
                            end)
                        end
                    end
                    UpdateSize()
                end

                DropBtn.MouseButton1Click:Connect(function()
                    isDropdownOpen = not isDropdownOpen
                    
                    if isDropdownOpen then
                        DList.Visible = true
                        DropArrow.Rotation = 180
                         -- Refresh Options
                         for _, c in pairs(DList:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
                         local opts = getOptionsFunc()
                         
                         local count = 0
                         for _, opt in pairs(opts) do
                             local B = Instance.new("TextButton")
                             B.Size = UDim2.new(1, -10, 0, 20)
                             B.Text = opt
                             B.BackgroundTransparency = 1
                             B.TextColor3 = Themes.TextDim
                             B.Font = Enum.Font.Gotham
                             B.TextSize = 12
                             B.TextXAlignment = Enum.TextXAlignment.Left
                             B.Parent = DList
                             B.MouseButton1Click:Connect(function()
                                selectedPlayer = opt
                                DropBtn.Text = "   " .. selectedPlayer
                                isDropdownOpen = false
                                DList.Visible = false
                                DropArrow.Rotation = 0
                                UpdateSize()
                             end)
                             count = count + 1
                         end

                         if count == 0 then
                             local B = Instance.new("TextLabel")
                             B.Size = UDim2.new(1, -10, 0, 20)
                             B.Text = "Nenhum player"
                             B.BackgroundTransparency = 1
                             B.TextColor3 = Themes.TextDim
                             B.Font = Enum.Font.Gotham
                             B.TextSize = 12
                             B.Parent = DList
                         end
                         
                         DList.CanvasSize = UDim2.new(0,0,0, DLL.AbsoluteContentSize.Y + 10)
                    else
                        DList.Visible = false
                        DropArrow.Rotation = 0
                    end
                    UpdateSize()
                end)

                AddBtn.MouseButton1Click:Connect(function()
                    if selectedPlayer ~= "Selecionar..." and not table.find(addedItems, selectedPlayer) then
                        table.insert(addedItems, selectedPlayer)
                        pcall(onAdd, selectedPlayer)
                        RefreshAddedList()
                    end
                end)
                
                -- Init
                RefreshAddedList()
                
                return IFrame
            end

            function GroupObj:Input(text, callback)
                local IFrame = CreateElementFrame()
                IFrame.Size = UDim2.new(1, 0, 0, 60)
                
                local ILab = Instance.new("TextLabel")
                ILab.Text = text
                ILab.Size = UDim2.new(1, -10, 0, 20)
                ILab.Position = UDim2.new(0, 10, 0, 5)
                ILab.BackgroundTransparency = 1
                ILab.Font = Enum.Font.GothamMedium
                ILab.TextColor3 = Themes.Text
                ILab.TextSize = 13
                ILab.TextXAlignment = Enum.TextXAlignment.Left
                ILab.Parent = IFrame
                
                local Box = Instance.new("TextBox")
                Box.Size = UDim2.new(1, -20, 0, 25)
                Box.Position = UDim2.new(0, 10, 0, 30)
                Box.BackgroundColor3 = Color3.fromRGB(45,45,50)
                Box.Text = ""
                Box.PlaceholderText = "..."
                Box.Font = Enum.Font.Gotham
                Box.TextSize = 12
                Box.TextColor3 = Themes.Text
                Box.PlaceholderColor3 = Themes.TextDim
                Box.TextXAlignment = Enum.TextXAlignment.Left
                Box.Parent = IFrame
                local BC = Instance.new("UICorner"); BC.CornerRadius = UDim.new(0, 4); BC.Parent = Box
                
                Box.FocusLost:Connect(function()
                    pcall(callback, Box.Text)
                end)
                
                return IFrame
            end

            return GroupObj
        end

        return TabObj
    end
    
    -- Drag do Main é gerenciado por MakeDraggable(Main) na inicialização

    -- Toggle Logic (Right Shift)
    local uiOpen = true
    Main.ClipsDescendants = true -- Required for size animation
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.RightShift then
            uiOpen = not uiOpen
            if uiOpen then
                Main.Visible = true
                Main.ClipsDescendants = true
                TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 650, 0, 480), BackgroundTransparency = 0}):Play()
                 if Main:FindFirstChild("UIStroke") then
                    TweenService:Create(Main.UIStroke, TweenInfo.new(0.5), {Transparency = 0.5}):Play()
                end
            else
                local tween = TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 650, 0, 0), BackgroundTransparency = 1})
                if Main:FindFirstChild("UIStroke") then
                    TweenService:Create(Main.UIStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
                end
                tween:Play()
                tween.Completed:Connect(function()
                    if not uiOpen then Main.Visible = false end
                end)
            end
        end
    end)

    return Window, ScreenGui
end

-- ==========================================
-- UI SETUP & LOGIC WIRING
-- ==========================================
local Win, SG = VoidLib:CreateWindow()

-- >>> TAB: COMBATE
do
    local Combat = Win:Tab("Combate")


    local AimbotGroup = Combat:Group("Aimbot Principal")

    local function GetServerPlayers()
        local list = {}
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= game:GetService("Players").LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        return list
    end

    local function GetTeamsList2()
        local list = {}
        local success, teams = pcall(function() return game:GetService("Teams"):GetTeams() end)
        if success and teams then
            for _, t in pairs(teams) do
                table.insert(list, t.Name)
            end
        end
        return list
    end

    local aimbotToggle
    aimbotToggle = AimbotGroup:ToggleKeybind("Ativar Aimbot", AimbotCore:IsEnabled(), Enum.UserInputType.MouseButton2, function(v)
        AimbotCore:SetEnabled(v)
    end, function(k)
        AimbotCore:SetTriggerKey(k)
    end, function(sub)
        local keyOptions = {
            "M2 (Botão Direito)",
            "M1 (Botão Esquerdo)",
            "M3 (Scroll / Meio)",
            "M4 (Lateral Voltar)",
            "M5 (Lateral Avançar)",
            "E", "Q", "F", "C", "V", "X", "Z", "LeftShift", "LeftControl", "LeftAlt"
        }
        local keyMap = {
            ["M2 (Botão Direito)"] = Enum.UserInputType.MouseButton2,
            ["M1 (Botão Esquerdo)"] = Enum.UserInputType.MouseButton1,
            ["M3 (Scroll / Meio)"] = Enum.UserInputType.MouseButton3,
            ["M4 (Lateral Voltar)"] = "M4",
            ["M5 (Lateral Avançar)"] = "M5",
            ["E"] = Enum.KeyCode.E,
            ["Q"] = Enum.KeyCode.Q,
            ["F"] = Enum.KeyCode.F,
            ["C"] = Enum.KeyCode.C,
            ["V"] = Enum.KeyCode.V,
            ["X"] = Enum.KeyCode.X,
            ["Z"] = Enum.KeyCode.Z,
            ["LeftShift"] = Enum.KeyCode.LeftShift,
            ["LeftControl"] = Enum.KeyCode.LeftControl,
            ["LeftAlt"] = Enum.KeyCode.LeftAlt,
        }

        sub:Dropdown("Tecla de Disparo", keyOptions, "M2 (Botão Direito)", function(selected)
            local targetKey = keyMap[selected] or Enum.UserInputType.MouseButton2
            AimbotCore:SetTriggerKey(targetKey)
            if aimbotToggle and aimbotToggle.SetKey then
                aimbotToggle.SetKey(targetKey)
            end
        end)

        local teamCheckToggle = sub:Toggle("Ignorar Aliados", getgenv().TeamCheck, function(v)
            getgenv().TeamCheck = v
        end)
        ConfigManager:Register("aimbotTeamCheck", teamCheckToggle)

        local legitToggle = sub:Toggle("Modo Legit", getgenv().LegitMode or false, function(v)
            getgenv().LegitMode = v
        end)
        ConfigManager:Register("aimbotLegit", legitToggle)

        local randomPartsToggle = sub:Toggle("Humanizar (Random Parts)", getgenv().RandomParts or false, function(v)
            getgenv().RandomParts = v
        end)
        ConfigManager:Register("aimbotRandomParts", randomPartsToggle)

        local aimAssistToggle = sub:Toggle("Modo Aim Assist (Suave)", getgenv().AimAssistMode or false, function(v)
            getgenv().AimAssistMode = v
        end)
        ConfigManager:Register("aimbotAimAssist", aimAssistToggle)

        local smoothnessSlider = sub:Slider("Suavidade (Assist)", 1, 20, 10, function(v)
            getgenv().AimbotSmoothness = v
        end)
        ConfigManager:Register("aimbotSmoothness", smoothnessSlider)

        local cursorAimToggle = sub:Toggle("Cursor Aim", AimbotCore:IsCursorAim(), function(v)
            AimbotCore:SetCursorAim(v)
        end)
        ConfigManager:Register("aimbotCursorAim", cursorAimToggle)

        local fovSlider = sub:Slider("Campo de Visão (FOV)", 20, 500, (AimbotCore:GetFOV() or 90), function(v)
            AimbotCore:SetFOV(v)
        end)
        ConfigManager:Register("aimbotFOV", fovSlider)

        local easingSlider = sub:Slider("Suavização (Easing)", 1, 10, math.floor((getgenv().AimbotEasing or 1) * 10), function(v)
            getgenv().AimbotEasing = v / 10 
        end)
        ConfigManager:Register("aimbotEasing", easingSlider)
    end)
    ConfigManager:Register("aimbotEnabled", aimbotToggle)

    local function GetExPlayersListMain()
        local list = {"Amigos"}
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= game:GetService("Players").LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        return list
    end

    local function GetExTeamsListMain()
        local list = {}
        pcall(function()
            for _, t in pairs(game:GetService("Teams"):GetTeams()) do
                table.insert(list, t.Name)
            end
        end)
        return list
    end

    AimbotGroup:InteractiveList("Exceção Jogadores", GetExPlayersListMain, function(itemName)
        AimbotCore:IgnorePlayer(itemName)
    end, function(itemName)
        AimbotCore:UnignorePlayer(itemName)
    end)

    AimbotGroup:InteractiveList("Exceção Times", GetExTeamsListMain, function(itemName)
        AimbotCore:IgnoreTeam(itemName)
    end, function(itemName)
        AimbotCore:UnignoreTeam(itemName)
    end)

    local HitboxGroup = Combat:Group("Hitbox")
    local hitboxToggle = HitboxGroup:Toggle("Expandir Hitbox", HitboxExpand:IsEnabled(), function(v)
        HitboxExpand:SetEnabled(v)
    end, function(sub)
        local hitboxSizeSlider = sub:Slider("Tamanho", 1, 30, HitboxExpand:GetSize(), function(v)
            HitboxExpand:SetSize(v)
        end)
        ConfigManager:Register("hitboxSize", hitboxSizeSlider)
    end)
    ConfigManager:Register("hitboxEnabled", hitboxToggle)

    local function GetBodyPartsList()
        return {
            "Cabeça",
            "Tronco",
            "Braço Esquerdo",
            "Braço Direito",
            "Perna Esquerda",
            "Perna Direita"
        }
    end

    HitboxGroup:InteractiveList("Partes do Corpo", GetBodyPartsList, function(partName)
        HitboxExpand:AddPart(partName)
    end, function(partName)
        HitboxExpand:RemovePart(partName)
    end)

    -- >>> CATEGORIA: AUTO SHOT
    local AutoShotGroup = Combat:Group("AutoShot")
    local autoShotToggle = AutoShotGroup:Toggle("Ativar AutoShot", AutoShotCore:IsEnabled(), function(v)
        AutoShotCore:SetEnabled(v)
    end, function(sub)
        local intervalInput = sub:Input("Intervalo de Clique", AutoShotCore:GetIntervalMS(), 1, 10000, function(v)
            AutoShotCore:SetIntervalMS(v)
        end, "ms")
        ConfigManager:Register("autoShotInterval", intervalInput)
    end)
    ConfigManager:Register("autoShotEnabled", autoShotToggle)

    AutoShotGroup:InteractiveList("Exceção Jogadores", GetExPlayersListMain, function(itemName)
        AutoShotCore:IgnorePlayer(itemName)
    end, function(itemName)
        AutoShotCore:UnignorePlayer(itemName)
    end)

    AutoShotGroup:InteractiveList("Exceção Times", GetExTeamsListMain, function(itemName)
        AutoShotCore:IgnoreTeam(itemName)
    end, function(itemName)
        AutoShotCore:UnignoreTeam(itemName)
    end)

end -- End Combat Block

-- >>> TAB: USER
do
    local User = Win:Tab("User")

    -- >>> SUB-TAB: TP
    local TP = User:Group("TP")

    pcall(function()
        -- >>> CLICK TP PL (Teleporte ao clicar no contorno do jogador na tela)
        local ClickTPPLActive = false
        local ClickTPPLOverlay = nil
        local ClickTPPLConnections = {}
        local ClickTPPLButtonRef = nil

        local function DisableClickTPPL()
            ClickTPPLActive = false
            if ClickTPPLOverlay and ClickTPPLOverlay.Parent then
                ClickTPPLOverlay:Destroy()
                ClickTPPLOverlay = nil
            end
            for _, conn in pairs(ClickTPPLConnections) do
                pcall(function() conn:Disconnect() end)
            end
            ClickTPPLConnections = {}
            
            -- Limpar destaques de contorno (Highlight) e nomes
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p.Character then
                    local hl = p.Character:FindFirstChild("ClickTPPLHighlight")
                    if hl then hl:Destroy() end
                    local nb = p.Character:FindFirstChild("ClickTPPLName")
                    if nb then nb:Destroy() end
                end
            end
            
            if ClickTPPLButtonRef then
                ClickTPPLButtonRef.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                ClickTPPLButtonRef.TextColor3 = Themes.Accent
            end
        end

        local function GetPlayerFromHitTarget(target)
            if not target then return nil end
            local current = target
            while current and current ~= workspace do
                local p = game:GetService("Players"):GetPlayerFromCharacter(current)
                if p and p ~= game:GetService("Players").LocalPlayer then
                    return p
                end
                current = current.Parent
            end
            return nil
        end

        local function EnableClickTPPL(btnRef)
            ClickTPPLButtonRef = btnRef
            ClickTPPLActive = true
            
            if btnRef then
                btnRef.BackgroundColor3 = Themes.Accent
                btnRef.TextColor3 = Color3.fromRGB(255, 255, 255)
            end

            -- 1. Fundo escuro na tela
            local CoreGui = game:GetService("CoreGui")
            local overlayGui = Instance.new("ScreenGui")
            overlayGui.Name = "ClickTPPLScreenOverlay"
            overlayGui.DisplayOrder = 1 -- ZIndex baixo para ficar atrás do ESP e da UI
            overlayGui.ResetOnSpawn = false
            
            local darkFrame = Instance.new("Frame")
            darkFrame.Size = UDim2.new(1, 0, 1, 0)
            darkFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            darkFrame.BackgroundTransparency = 0.45 -- Tela escura ativada!
            darkFrame.ZIndex = 1
            darkFrame.Parent = overlayGui
            
            overlayGui.Parent = CoreGui
            ClickTPPLOverlay = overlayGui

            -- 2. Ativar contorno (Highlight) brilhante visível através de paredes (AlwaysOnTop)
            local function ApplyPlayerESP(p)
                if p == game:GetService("Players").LocalPlayer then return end
                if not p.Character then return end

                local teamColor = TeamManager.GetPlayerColor(p)

                if not p.Character:FindFirstChild("ClickTPPLHighlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ClickTPPLHighlight"
                    hl.Adornee = p.Character
                    hl.FillColor = teamColor
                    hl.FillTransparency = 0.3 -- Mais forte e brilhante!
                    hl.OutlineColor = teamColor
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Funciona ATRAVÉS DAS PAREDES!
                    hl.Parent = p.Character
                end

                -- Se o ESP de nomes nativo já estiver ligado, NÃO exibe o nome do Click TP PL para não duplicar!
                local isMainESPNamesOn = (getgenv().ESPEnabled or (ESPCore and ESPCore:IsEnabled())) and getgenv().ESPNames

                if not isMainESPNamesOn then
                    if not p.Character:FindFirstChild("ClickTPPLName") then
                        local head = p.Character:FindFirstChild("Head") or p.Character.PrimaryPart
                        if head then
                            local bGui = Instance.new("BillboardGui")
                            bGui.Name = "ClickTPPLName"
                            bGui.Adornee = head
                            bGui.Size = UDim2.new(0, 180, 0, 30)
                            bGui.StudsOffset = Vector3.new(0, 2.8, 0)
                            bGui.AlwaysOnTop = true -- Visível através das paredes!
                            
                            local text = Instance.new("TextLabel")
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.Font = Enum.Font.GothamBold
                            text.TextSize = 14
                            text.TextColor3 = teamColor
                            text.TextStrokeTransparency = 0
                            text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            text.Text = (p.DisplayName or p.Name)
                            text.Parent = bGui
                            bGui.Parent = p.Character
                        end
                    end
                else
                    -- Se o ESP principal de nomes estiver ligado, remove qualquer nome do Click TP PL para não ter nomes duplicados
                    local existingName = p.Character:FindFirstChild("ClickTPPLName")
                    if existingName then existingName:Destroy() end
                end
            end

            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                pcall(function() ApplyPlayerESP(p) end)
            end

            local connAdded = game:GetService("Players").PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    if ClickTPPLActive then pcall(function() ApplyPlayerESP(p) end) end
                end)
            end)
            table.insert(ClickTPPLConnections, connAdded)

            -- 3. Ao clicar em um jogador (mesmo ATRÁS DE PAREDES), dá TP e respeita a Posição configurada (Em Cima, Atrás, Dentro)!
            local UIS = game:GetService("UserInputService")
            local LocalPlayer = game:GetService("Players").LocalPlayer

            local connClick = UIS.InputBegan:Connect(function(input, gpe)
                if not ClickTPPLActive then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mousePos = UIS:GetMouseLocation()
                    local camera = workspace.CurrentCamera
                    if not camera then return end

                    -- Raycast da câmera ou busca em 2D na tela pelo jogador sob o cursor
                    local targetPlayer = nil
                    local closestScreenDist = 50 -- Raio de tolerância em pixels no clique da tela

                    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                            local head = p.Character:FindFirstChild("Head")
                            if hrp and head then
                                local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                                if onScreen then
                                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                                    if dist2D < closestScreenDist then
                                        closestScreenDist = dist2D
                                        targetPlayer = p
                                    end
                                end
                            end
                        end
                    end

                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local myChar = LocalPlayer.Character
                        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                            local targetHRP = targetPlayer.Character.HumanoidRootPart
                            
                            -- Respeitar a configuração de posição do TP ("Em Cima", "Atrás", "Dentro")
                            local posMode = (KillAuraCore and KillAuraCore.GetPositionMode and KillAuraCore:GetPositionMode()) or "Em Cima"
                            local targetCFrame = targetHRP.CFrame

                            if posMode == "Atrás" then
                                targetCFrame = targetHRP.CFrame * CFrame.new(0, 0, 4)
                            elseif posMode == "Dentro" then
                                targetCFrame = targetHRP.CFrame
                            else -- "Em Cima" (Padrão)
                                targetCFrame = targetHRP.CFrame * CFrame.new(0, 4.5, 0)
                            end

                            myChar:SetPrimaryPartCFrame(targetCFrame)
                            
                            game:GetService("StarterGui"):SetCore("SendNotification", {
                                Title = "DreeZy HUB",
                                Text = "Teleportado para: " .. (targetPlayer.DisplayName or targetPlayer.Name) .. " (" .. posMode .. ")",
                                Duration = 2.5
                            })

                            -- Auto desativa o sistema e restaura a tela!
                            DisableClickTPPL()
                        end
                    end
                end
            end)
            table.insert(ClickTPPLConnections, connClick)
        end

        local function ToggleClickTPPL(btnRef)
            if ClickTPPLActive then
                DisableClickTPPL()
            else
                EnableClickTPPL(btnRef)
            end
        end

        -- Kill Aura dentro da aba TP com Engrenagem (Sub-Hub), botão Click TP e botão Click TP PL
        local killAuraToggle = TP:Toggle("Tp player", (KillAuraCore and KillAuraCore.IsEnabled and KillAuraCore:IsEnabled()) or false, function(v)
            if KillAuraCore then KillAuraCore:SetEnabled(v) end
        end, function(sub)
            local posDrop = sub:Dropdown("Posição do TP", {"Em Cima", "Atrás", "Dentro"}, (KillAuraCore and KillAuraCore:GetPositionMode()) or "Em Cima", function(val)
                if KillAuraCore then KillAuraCore:SetPositionMode(val) end
            end)
            ConfigManager:Register("tpPositionMode", posDrop)
        end, "Click TP", function()
            if KillAuraCore and KillAuraCore.TeleportOnce then
                local res = KillAuraCore:TeleportOnce()
                if res then
                    game:GetService("StarterGui"):SetCore("SendNotification", {Title="DreeZy HUB", Text="Teleportado para: " .. (res.DisplayName or res.Name), Duration=2})
                else
                    game:GetService("StarterGui"):SetCore("SendNotification", {Title="DreeZy HUB", Text="Nenhum alvo encontrado para TP!", Duration=2})
                end
            end
        end, "Click TP PL", ToggleClickTPPL)
        ConfigManager:Register("killAuraEnabled", killAuraToggle)
    
        local function GetPlayersList()
            local list = {"Todos", "Amigos"}
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= game:GetService("Players").LocalPlayer then
                    table.insert(list, p.Name)
                end
            end
            return list
        end
    
        local TargetDrop = TP:Dropdown("Alvo", GetPlayersList(), "Todos", function(val)
            if KillAuraCore then KillAuraCore:SetTargetMode(val) end
        end)
    
        -- Auto Update Dropdown
        task.spawn(function()
            while task.wait(5) do
               pcall(function() TargetDrop:Refresh(GetPlayersList()) end)
            end
        end)
        game:GetService("Players").PlayerAdded:Connect(function() pcall(function() TargetDrop:Refresh(GetPlayersList()) end) end)
        game:GetService("Players").PlayerRemoving:Connect(function() pcall(function() TargetDrop:Refresh(GetPlayersList()) end) end)
    
        local function GetTeamsList()
            local list = {"Nada"}
            pcall(function()
                for _, t in pairs(game:GetService("Teams"):GetTeams()) do
                    table.insert(list, t.Name)
                end
            end)
            return list
        end
    
        local TeamDrop = TP:Dropdown("TP Time", GetTeamsList(), "Nada", function(val)
            if KillAuraCore then KillAuraCore:SetTeamTarget(val) end
        end)
    
        game:GetService("Teams").ChildAdded:Connect(function() pcall(function() TeamDrop:Refresh(GetTeamsList()) end) end)
        game:GetService("Teams").ChildRemoved:Connect(function() pcall(function() TeamDrop:Refresh(GetTeamsList()) end) end)

        -- >>> TP CLICK MOD (Teleporte ao Segurar Tecla + Clique M1)
        local tpClickEnabled = false
        local tpClickKey = Enum.KeyCode.E

        local tpClickToggle = TP:ToggleKeybind("TP Click", false, Enum.KeyCode.E, function(v)
            tpClickEnabled = v
        end, function(k)
            tpClickKey = k
        end)
        ConfigManager:Register("tpClickEnabled", tpClickToggle)

        local UIS = game:GetService("UserInputService")
        local Players = game:GetService("Players")

        UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not tpClickEnabled then return end

            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if UIS:IsKeyDown(tpClickKey) then
                    local player = Players.LocalPlayer
                    if player and player.Character then
                        local mouse = player:GetMouse()
                        if mouse and mouse.Hit then
                            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local targetPos = mouse.Hit.Position + Vector3.new(0, 3.5, 0)
                                player.Character:SetPrimaryPartCFrame(CFrame.new(targetPos))
                            end
                        end
                    end
                end
            end
        end)
    end)
end -- End User Block

-- >>> TAB: VISUAL
do
    local Visual = Win:Tab("Visual")

    local ESPGroup = Visual:Group("ESP Jogadores")
    local espToggle = ESPGroup:Toggle("Ativar ESP (Box)", ESPCore:IsEnabled(), function(v)
        ESPCore:SetEnabled(v)
    end, function(sub)
        local espNamesToggle = sub:ToggleSlider("Mostrar Nomes", 8, 24, (getgenv().ESPNameSize or 12), (getgenv().ESPNames or false), function(v)
            getgenv().ESPNames = v
        end, function(v)
            getgenv().ESPNameSize = v
        end)
        ConfigManager:Register("espNames", espNamesToggle)

        local espHealthToggle = sub:Toggle("Barra de Vida", (getgenv().ESPHealth or false), function(v)
            getgenv().ESPHealth = v
        end)
        ConfigManager:Register("espHealth", espHealthToggle)

        local espTracersToggle = sub:Toggle("Linhas (Tracers)", (getgenv().ESPTracers or false), function(v)
            getgenv().ESPTracers = v
        end)
        ConfigManager:Register("espTracers", espTracersToggle)

        local espInventoryToggle = sub:Toggle("Mostrar Inventário (Barra)", (getgenv().ESPInventory or false), function(v)
            getgenv().ESPInventory = v
        end)
        ConfigManager:Register("espInventory", espInventoryToggle)
    end)
    ConfigManager:Register("espEnabled", espToggle)

    -- ============================================
    -- GRUPO: ALERTA DE AMEAÇA (HIGH ALERT)
    -- ============================================
    local AlertGroup = Visual:Group("Alerta de Ameaça (High Alert)")
    local alertToggle = AlertGroup:Toggle("High Alert (Bordas)", HighAlertCore:IsEnabled(), function(v)
        HighAlertCore:SetEnabled(v)
    end, function(sub)
        local alertTeamToggle = sub:Toggle("Ignorar Aliados (Time)", HighAlertCore:IsTeamCheck(), function(v)
            HighAlertCore:SetTeamCheck(v)
        end)
        ConfigManager:Register("highAlertTeamCheck", alertTeamToggle)

        local alertArrowToggle = sub:Toggle("Seta Direcional (Centro)", HighAlertCore:IsArrowEnabled(), function(v)
            HighAlertCore:SetArrowEnabled(v)
        end)
        ConfigManager:Register("highAlertArrow", alertArrowToggle)

        local alertThicknessSlider = sub:Slider("Tamanho da Borda", 3, 50, HighAlertCore:GetBorderThickness(), function(v)
            HighAlertCore:SetBorderThickness(v)
        end)
        ConfigManager:Register("highAlertThickness", alertThicknessSlider)

        local alertRadiusSlider = sub:Slider("Distância da Seta", 30, 300, HighAlertCore:GetArrowRadius(), function(v)
            HighAlertCore:SetArrowRadius(v)
        end)
        ConfigManager:Register("highAlertArrowRadius", alertRadiusSlider)

        local alertSizeSlider = sub:Slider("Tamanho da Seta", 8, 50, HighAlertCore:GetArrowSize(), function(v)
            HighAlertCore:SetArrowSize(v)
        end)
        ConfigManager:Register("highAlertArrowSize", alertSizeSlider)
    end)
    ConfigManager:Register("highAlertEnabled", alertToggle)
    
    -- ============================================
    -- GRUPO: MINIMAPA (RADAR)
    -- ============================================
    local MinimapGroup = Visual:Group("Minimapa (Radar)")
    local minimapToggle = MinimapGroup:Toggle("Ativar Minimapa", MinimapCore:IsEnabled(), function(v)
        MinimapCore:SetEnabled(v)
    end, function(sub)
        local shapeSel = sub:ShapeSelector("Formato", MinimapCore:IsRound(), function(isRound)
            MinimapCore:SetRound(isRound)
        end)
        ConfigManager:Register("minimapRound", shapeSel)

        local lockToggle = sub:Toggle("Travar (Não Arrastar)", MinimapCore:IsLocked(), function(v)
            MinimapCore:SetLocked(v)
        end)
        ConfigManager:Register("minimapLocked", lockToggle)

        local terrainToggle = sub:Toggle("Mostrar Mapa (Terreno)", MinimapCore:IsTerrain(), function(v)
            MinimapCore:SetTerrain(v)
        end)
        ConfigManager:Register("minimapTerrain", terrainToggle)

        local sizeSlider = sub:Slider("Tamanho do HUD", 100, 300, MinimapCore:GetSize(), function(v)
            MinimapCore:SetSize(v)
        end)
        ConfigManager:Register("minimapSize", sizeSlider)

        local zoomSlider = sub:Slider("Distância (Zoom)", 50, 500, MinimapCore:GetZoom(), function(v)
            MinimapCore:SetZoom(v)
        end)
        ConfigManager:Register("minimapZoom", zoomSlider)

        local renderSlider = sub:Slider("Render", 100, 2000, MinimapCore:GetRender(), function(v)
            MinimapCore:SetRender(v)
        end)
        ConfigManager:Register("minimapRender", renderSlider)
    end)
    ConfigManager:Register("minimapEnabled", minimapToggle)
    
end -- End Visual Block

-- >>> TAB: LOCAL PLAYER
do
    local Local = Win:Tab("Local")
    local CharGroup = Local:Group("Personagem")
    local respawnToggle = CharGroup:Toggle("Respawn Onde Morreu", RespawnCore:IsEnabled(), function(v)
        RespawnCore:SetEnabled(v)
    end)
    ConfigManager:Register("respawnEnabled", respawnToggle)

    local UtilityGroup = Local:Group("Utilidades")
    UtilityGroup:Bind("Tecla Soltar Cursor", (getgenv().UnlockMouseKey or Enum.KeyCode.RightControl), function(key)
        getgenv().UnlockMouseKey = key
    end)
    UtilityGroup:Button("Resetar Cursor (Emergência)", function()
        MouseUnlocker:SetUnlocked(true)
        task.wait(0.1)
        MouseUnlocker:SetUnlocked(false)
    end)

    local AntiAFKGroup = Local:Group("Anti-AFK")

    -- Mini-HUD Creation
    local AFKHud = Instance.new("Frame")
    AFKHud.Name = "AFKHud"
    AFKHud.Size = UDim2.new(0, 220, 0, 100)
    AFKHud.Position = UDim2.new(0.5, -110, 0.05, 0) -- Top Center-ish
    AFKHud.BackgroundColor3 = Themes.Background
    AFKHud.BorderSizePixel = 0
    AFKHud.Visible = false
    AFKHud.Parent = SG
    AFKHud.Active = true
    -- AFKHud.Draggable = true (Deprecated and causes conflicts)
    AFKHud.ZIndex = 100 -- Ensure it's above Main

    -- Custom Dragging for Mini-HUD
    local draggingAFK, dragInputAFK, dragStartAFK, startPosAFK
    AFKHud.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingAFK = true
            dragStartAFK = input.Position
            startPosAFK = AFKHud.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingAFK = false
                end
            end)
        end
    end)

    AFKHud.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and draggingAFK then
            local delta = input.Position - dragStartAFK
            AFKHud.Position = UDim2.new(startPosAFK.X.Scale, startPosAFK.X.Offset + delta.X, startPosAFK.Y.Scale, startPosAFK.Y.Offset + delta.Y)
        end
    end) 

    local AFKCorner = Instance.new("UICorner"); AFKCorner.CornerRadius = UDim.new(0, 8); AFKCorner.Parent = AFKHud
    local AFKStroke = Instance.new("UIStroke"); AFKStroke.Color = Themes.Accent; AFKStroke.Thickness = 1; AFKStroke.Parent = AFKHud

    -- Title
    local TitleLab = Instance.new("TextLabel")
    TitleLab.Text = "Anti Afk"
    TitleLab.Size = UDim2.new(1, 0, 0, 30)
    TitleLab.Position = UDim2.new(0, 0, 0, 5)
    TitleLab.BackgroundTransparency = 1
    TitleLab.Font = Enum.Font.GothamBold
    TitleLab.TextSize = 18
    TitleLab.TextColor3 = Themes.Accent
    TitleLab.Parent = AFKHud

    -- Divider
    local Div = Instance.new("Frame")
    Div.Size = UDim2.new(1, -20, 0, 1)
    Div.Position = UDim2.new(0, 10, 0, 35)
    Div.BackgroundColor3 = Color3.fromRGB(50,50,55)
    Div.BorderSizePixel = 0
    Div.Parent = AFKHud

    -- Status
    local StatusLab = Instance.new("TextLabel")
    StatusLab.Text = "Status: Active"
    StatusLab.Size = UDim2.new(1, 0, 0, 25)
    StatusLab.Position = UDim2.new(0, 0, 0, 40)
    StatusLab.BackgroundTransparency = 1
    StatusLab.Font = Enum.Font.GothamBold
    StatusLab.TextSize = 16
    StatusLab.TextColor3 = Themes.Text
    StatusLab.Parent = AFKHud

    -- Time
    local TimeLab = Instance.new("TextLabel")
    TimeLab.Text = "Time: 00:00:00"
    TimeLab.Size = UDim2.new(1, 0, 0, 25)
    TimeLab.Position = UDim2.new(0, 0, 0, 65)
    TimeLab.BackgroundTransparency = 1
    TimeLab.Font = Enum.Font.Gotham
    TimeLab.TextSize = 16
    TimeLab.TextColor3 = Themes.Text
    TimeLab.Parent = AFKHud

    -- Logic
    local antiAfkEnabled = false
    local startTime = os.time() 

    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        if antiAfkEnabled then
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end)

    local function UpdateTimer()
        if not AFKHud.Visible then return end
        local diff = os.time() - startTime
        local h = math.floor(diff / 3600)
        local m = math.floor((diff % 3600) / 60)
        local s = diff % 60
        TimeLab.Text = string.format("Time: %02d:%02d:%02d", h, m, s)
    end

    task.spawn(function()
        while true do
            UpdateTimer()
            task.wait(1)
        end
    end)

    local antiAfkToggle = AntiAFKGroup:Toggle("Ativar Anti-AFK", false, function(v)
        antiAfkEnabled = v
        AFKHud.Visible = v
    end)
    ConfigManager:Register("antiAfkEnabled", antiAfkToggle)

    -- >>> CATEGORIA: AUTO CLICK
    local AutoClickGroup = Local:Group("Auto Click")
    local autoClickToggle = AutoClickGroup:ToggleKeybind("Selecionar/Ativar Auto Click", AutoClickerCore:IsMainEnabled(), AutoClickerCore:GetTriggerKey(), function(v)
        AutoClickerCore:SetMainEnabled(v)
    end, function(k)
        AutoClickerCore:SetTriggerKey(k)
    end, function(sub)
        local intervalInput = sub:Input("Intervalo de Clique", AutoClickerCore:GetIntervalMS(), 1, 10000, function(v)
            AutoClickerCore:SetIntervalMS(v)
        end, "ms")
        ConfigManager:Register("autoClickInterval", intervalInput)

        sub:KeyboardMouseDisplay(AutoClickerCore:GetClickTarget(), function(selectedTarget)
            AutoClickerCore:SetClickTarget(selectedTarget)
        end)
    end)
    ConfigManager:Register("autoClickEnabled", autoClickToggle)
end -- End Local Block



-- >>> TAB: CONFIGURAÇÕES
do
    local Settings = Win:Tab("Configs")

    local AccessGroup = Settings:Group("Acessibilidade")
    AccessGroup:ActionButton("Acesso Rápido (Favoritos)", "Abrir", function()
        if Win and Win.ToggleFavHUD then
            Win:ToggleFavHUD()
        elseif getgenv().ToggleFavHUD then
            getgenv().ToggleFavHUD()
        end
    end, false)

    local autoReexecuteReload = false

    local ServerGroup = Settings:Group("Servidores")
    ServerGroup:ActionButton("Reload no Server", "Reload", function()
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if autoReexecuteReload then
            local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport or (fluxus and fluxus.queue_on_teleport)
            if queueTeleport then
                pcall(function()
                    queueTeleport([[
                        repeat task.wait() until game:IsLoaded()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/fraudesnaoseinaosei-max/j4rty678/main/RespawnHUD.lua?v=" .. tick()))()
                    ]])
                end)
            end
        end

        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DreeZy HUB",
            Text = autoReexecuteReload and "Reconectando e reexecutando o script..." or "Reconectando ao mesmo servidor...",
            Duration = 3
        })

        pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
    end, false, function(sub)
        local autoToggle = sub:Toggle("Auto-Executar Script ao Reconectar", false, function(v)
            autoReexecuteReload = v
        end)
        ConfigManager:Register("autoReexecuteReload", autoToggle)
    end)

    -- >>> CATEGORIA: CÂMERA & SHIFT LOCK
    local CameraGroup = Settings:Group("Câmera & Shift Lock")
    local freeShiftLockToggle
    freeShiftLockToggle = CameraGroup:ToggleKeybind("Shift Lock Livre (Corpo Desbloqueado)", FreeShiftLockCore:IsEnabled(), FreeShiftLockCore:GetTriggerKey(), function(v)
        FreeShiftLockCore:SetEnabled(v)
    end, function(k)
        FreeShiftLockCore:SetTriggerKey(k)
    end, function(sub)
        local shoulderOffsetSlider = sub:Slider("Deslocamento de Ombro", 0, 40, math.floor((getgenv().FreeShiftLockOffset or 1.75) * 10), function(v)
            getgenv().FreeShiftLockOffset = v / 10
        end, function(v)
            return string.format("%.1f", v / 10)
        end)
        ConfigManager:Register("freeShiftLockOffset", shoulderOffsetSlider)

        local crosshairToggle = sub:Toggle("Mira Central (Crosshair)", FreeShiftLockCore:GetShowCrosshair(), function(v)
            FreeShiftLockCore:SetShowCrosshair(v)
        end)
        ConfigManager:Register("freeShiftLockCrosshair", crosshairToggle)
    end)
    ConfigManager:Register("freeShiftLockEnabled", freeShiftLockToggle)
    
    getgenv().ToggleFreeShiftLockUI = function()
        if freeShiftLockToggle and freeShiftLockToggle.Set and freeShiftLockToggle.Get then
            freeShiftLockToggle.Set(not freeShiftLockToggle.Get())
        else
            FreeShiftLockCore:SetEnabled(not FreeShiftLockCore:IsEnabled())
        end
    end

    local ManagerGroup = Settings:Group("Gerenciamento")

    local function Notify(msg)
        game:GetService("StarterGui"):SetCore("SendNotification", {Title="DreeZy HUB", Text=msg, Duration=3})
    end

    ManagerGroup:Button("Salvar Configurações", function()
        if writefile then
            local success = ConfigManager:Save()
            if success then
                Notify("Configurações salvas em DreeZyHub/Config.json!")
            else
                Notify("Erro ao salvar configurações!")
            end
        else
            Notify("Executor não suporta writefile")
        end
    end)

    ManagerGroup:Button("Carregar Configurações", function()
        if isfile then
            local success = ConfigManager:Load()
            if success then
                Notify("Configurações carregadas com sucesso!")
            else
                Notify("Nenhum save encontrado em DreeZyHub/Config.json")
            end
        else
            Notify("Executor não suporta isfile")
        end
    end)

    local InfoGroup = Settings:Group("Informações")
    InfoGroup:Button("Criado por DreeZy", function() setclipboard("DreeZy") end)
end -- End Settings Block

Notify("DreeZy Voidware V2 Carregado!")
Notify("Use [Right Shift] para abrir/fechar o Menu!")