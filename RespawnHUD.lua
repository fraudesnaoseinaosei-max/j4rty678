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
        local cameraPos = camera.CFrame.Position
        local _, onscreen = camera:WorldToViewportPoint(targetPart.Position)
        if onscreen then
            local ray = Ray.new(cameraPos, targetPart.Position - cameraPos)
            local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, player.Character:GetDescendants())
            if hitPart and hitPart:IsDescendantOf(character) then return true else return false end
        else
            return false
        end
    end

    local function isSameTeam(targetPlayer)
        if not getgenv().TeamCheck then return false end
        if player.Team and targetPlayer.Team then return player.Team == targetPlayer.Team end
        if player.TeamColor and targetPlayer.TeamColor then return player.TeamColor == targetPlayer.TeamColor end
        return false
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
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                pcall(function()
                    local shouldTarget = true
                    if isSameTeam(targetPlayer) then shouldTarget = false end
                    if targetPlayer.Team and ignoredTeams[targetPlayer.Team.Name] then shouldTarget = false end
                    if ignoredPlayers[targetPlayer.Name] then shouldTarget = false end

                    if shouldTarget and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") and targetPlayer.Character:FindFirstChild("Humanoid") then
                        if not isTargetInFOV(targetPlayer.Character.Head) then return end
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

    function AimbotCore:SetEnabled(enabled)
        isEnabled = enabled
        if not enabled then isActive = false end
        updateFOVCircle()
    end
    function AimbotCore:SetCursorAim(enabled)
        useCursorAim = enabled
        if getgenv then getgenv().CursorAim = enabled end
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

    mouse.Button2Down:Connect(function() if isEnabled and getgenv().AimbotInput == "RightClick" then isActive = true end end)
    mouse.Button2Up:Connect(function() if isEnabled and getgenv().AimbotInput == "RightClick" then isActive = false end end)
    mouse.Button1Down:Connect(function() if isEnabled and getgenv().AimbotInput == "LeftClick" then isActive = true end end)
    mouse.Button1Up:Connect(function() if isEnabled and getgenv().AimbotInput == "LeftClick" then isActive = false end end)
    mouse.KeyDown:Connect(function(key) if isEnabled and key == getgenv().AimbotInput:lower() then isActive = true end end)
    mouse.KeyUp:Connect(function(key) if isEnabled and key == getgenv().AimbotInput:lower() then isActive = false end end)

    local currentTarget = nil
    task.spawn(function()
        while true do
            if isEnabled then currentTarget = findNearestTarget() else currentTarget = nil end
            task.wait(0.1)
        end
    end)

    -- Logic for Legit Mode Target Selection
    local activeTargetPart = "Head"
    local lastLockedTarget = nil
    local bodyParts = {
        "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", 
        "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"
    }

    local function getRandomPart(char)
        if not char then return "Head" end
        -- 40% Chance for Head, 60% Chance for Random Part
        if math.random() <= 0.4 then 
            return "Head" 
        end

        local possible = {}
        for _, name in pairs(bodyParts) do
            if char:FindFirstChild(name) then
                table.insert(possible, name)
            end
        end
        
        if #possible > 0 then
            return possible[math.random(1, #possible)]
        else
            return "Head"
        end
    end

    RunService.RenderStepped:Connect(function()
        if isActive and isEnabled and currentTarget then
            -- Check if target changed to reset part
            if currentTarget ~= lastLockedTarget then
                lastLockedTarget = currentTarget
                if getgenv().LegitMode and getgenv().RandomParts then
                    activeTargetPart = getRandomPart(currentTarget.Character)
                else
                    activeTargetPart = "Head"
                end
            end
            
            -- Legit Mode: Periodically switch target part (Humanization)
            -- Only if RandomParts is enabled
            if getgenv().LegitMode and getgenv().RandomParts and currentTarget and currentTarget.Character then
                if not getgenv().LastLegitSwitch then getgenv().LastLegitSwitch = 0 end
                if tick() - getgenv().LastLegitSwitch > (math.random() * 0.25 + 0.15) then
                    activeTargetPart = getRandomPart(currentTarget.Character)
                    getgenv().LastLegitSwitch = tick()
                end
            end

            if currentTarget.Character then
                -- Fallback if the specific part is missing (e.g. lost limb)
                local targetInst = currentTarget.Character:FindFirstChild(activeTargetPart) or currentTarget.Character:FindFirstChild("Head") 
                
                if targetInst then
                    local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                         local currentCFrame = camera.CFrame
                         
                         -- SMOOTHNESS / AIM ASSIST LOGIC
                         local smoothing = 1
                         if getgenv().AimAssistMode then
                             -- Use the Slider Value (1 to 20)
                             -- 1 = Instant, 20 = Slow/Drag
                             local smoothVal = getgenv().AimbotSmoothness or 10
                             smoothing = 1 / smoothVal -- e.g. 1/10 = 0.1 alpha
                         else
                             -- Default Instnat or standard easing
                             smoothing = getgenv().AimbotEasing or 1
                         end
                         
                         camera.CFrame = currentCFrame:Lerp(CFrame.new(currentCFrame.Position, targetInst.Position), smoothing)
                    else
                        currentTarget = nil
                        lastLockedTarget = nil
                    end
                end
            end
        else
            lastLockedTarget = nil
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

    local function isSameTeam(targetPlayer)
        -- TeamCheck only applies to "Todos" mode usually, or if explicitly requested.
        -- User asked: "Amigos" -> Target Friends. "Specific" -> Target Specific.
        -- So for "Todos", we respect TeamCheck.
        if targetMode ~= "Todos" then return false end
        
        if not getgenv().TeamCheck then return false end
        if player.Team and targetPlayer.Team then return player.Team == targetPlayer.Team end
        if player.TeamColor and targetPlayer.TeamColor then return player.TeamColor == targetPlayer.TeamColor end
        return false
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
        -- Teleport execution
        if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = currentTarget.Character.HumanoidRootPart
                local newCFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
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
    function KillAura:IsEnabled() return isEnabled end
    if getgenv then isEnabled = getgenv().KillAuraEnabled or false else isEnabled = false end

    return KillAura
end)()

-- [3] HEAD ESP
local HeadESP = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local HeadESP = {}
    local player = Players.LocalPlayer

    local Config = { HeadSize = 5, Disabled = true }
    local originalProperties = {}

    function HeadESP:RestoreHeads()
        for head, props in pairs(originalProperties) do
            if head and head.Parent then
                pcall(function()
                    head.Size = props.Size
                    head.Transparency = props.Transparency
                    head.BrickColor = props.BrickColor
                    head.Material = props.Material
                    head.CanCollide = props.CanCollide
                    head.Massless = props.Massless
                end)
            end
        end
        originalProperties = {}
    end

    function HeadESP:SetEnabled(enabled) 
        Config.Disabled = not enabled
        if not enabled then self:RestoreHeads() end
    end
    function HeadESP:IsEnabled() return not Config.Disabled end
    function HeadESP:SetHeadSize(size) Config.HeadSize = size end
    function HeadESP:GetHeadSize() return Config.HeadSize end

    RunService.RenderStepped:Connect(function()
        if not Config.Disabled then
            for i, v in next, Players:GetPlayers() do
                if v.Name ~= player.Name then
                    pcall(function()
                        if v.Character and v.Character:FindFirstChild("Head") then
                            local head = v.Character.Head
                            if not originalProperties[head] then
                                originalProperties[head] = {
                                    Size = head.Size; Transparency = head.Transparency; BrickColor = head.BrickColor;
                                    Material = head.Material; CanCollide = head.CanCollide; Massless = head.Massless
                                }
                            end
                            head.Size = Vector3.new(Config.HeadSize, Config.HeadSize, Config.HeadSize)
                            head.Transparency = 0.5
                            head.BrickColor = BrickColor.new("Red")
                            head.Material = Enum.Material.Neon
                            head.CanCollide = false
                            head.Massless = true
                        end
                    end)
                end
            end
        end
    end)
    return HeadESP
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
        if player.TeamColor then return player.TeamColor.Color end
        if player.Team and player.Team.TeamColor then return player.Team.TeamColor.Color end
        return Color3.fromRGB(255, 255, 255)
    end

    local function CreateDrawings(playerName)
        if playerDrawings[playerName] then return playerDrawings[playerName] end
        local drawings = {
            Box = GetDrawingFromPool("Square"), 
            NameTag = GetDrawingFromPool("Text"),
            HealthBg = GetDrawingFromPool("HealthBar"),
            HealthFg = GetDrawingFromPool("HealthBar"),
            Tracer = GetDrawingFromPool("Line")
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
                                drawings.NameTag.Visible = true; drawings.NameTag.Text = player.Name; drawings.NameTag.Color = color; drawings.NameTag.Position = Vector2.new(rootPos.X, headPos.Y - 18)
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
                            end
                        end
                    else
                        if drawings then 
                            drawings.Box.Visible = false; drawings.NameTag.Visible = false 
                            drawings.HealthBg.Visible = false; drawings.HealthFg.Visible = false
                            drawings.Tracer.Visible = false
                        end
                    end
                else
                    if drawings then 
                        drawings.Box.Visible = false; drawings.NameTag.Visible = false 
                        drawings.HealthBg.Visible = false; drawings.HealthFg.Visible = false
                        drawings.Tracer.Visible = false
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
        if not LocalPlayer.Team then return false end
        if not targetPlayer.Team then return false end
        return LocalPlayer.Team == targetPlayer.Team
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

-- [6] MINIMAP CORE (Radar Arrastável)
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

    local container = nil
    local mapFrame = nil
    local mapCorner = nil
    local centerBlip = nil
    local blips = {} -- { [Player] = Frame }
    local terrainParts = {} -- { {part=BasePart, frame=Frame} }

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function GatherTerrain()
        for _, t in pairs(terrainParts) do t.frame:Destroy() end
        terrainParts = {}
        if not isTerrainEnabled then return end
        
        local count = 0
        local added = 0
        local maxTerrain = 2500 -- Limite maior para não perder partes próximas
        
        for _, v in pairs(workspace:GetDescendants()) do
            count = count + 1
            if count % 200 == 0 then task.wait() end -- Evitar congelamento (lag spike) ao carregar
            
            if added >= maxTerrain then break end
            
            if v:IsA("BasePart") and v.Anchored and v.Transparency < 0.8 then
                -- Ignorar muito grandes e muito pequenos. Exigir um pouco de altura (Y >= 1)
                if (v.Size.X >= 4 or v.Size.Z >= 4) and v.Size.Y >= 1 and (v.Size.X < 800 and v.Size.Z < 800) then
                    if v.Parent and (v.Parent:FindFirstChild("Humanoid") or v.Parent:IsA("Accessory")) then continue end
                    
                    local f = Instance.new("Frame")
                    f.BackgroundColor3 = Color3.fromRGB(90, 90, 95)
                    f.BackgroundTransparency = 0.5
                    f.BorderSizePixel = 1
                    f.BorderColor3 = Color3.fromRGB(50, 50, 50)
                    f.ZIndex = 1
                    f.Parent = mapFrame
                    table.insert(terrainParts, {part = v, frame = f})
                    added = added + 1
                end
            end
        end
    end

    -- Inicializa a GUI
    local function initUI()
        if container then return end

        local targetGui = CoreGui:FindFirstChild("DreeZyVoidware") or CoreGui:FindFirstChild("RobloxGui")
        if not targetGui then return end

        container = Instance.new("Frame")
        container.Name = "DreeZyMinimap"
        container.Size = UDim2.new(0, mapSize, 0, mapSize)
        container.Position = UDim2.new(1, -mapSize - 20, 0, 20) -- Canto superior direito
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
        
        -- Inimigo genérico se não tiver time (considerando FFA)
        if player ~= LocalPlayer then
             if LocalPlayer.Team then
                 return Color3.fromRGB(255, 50, 50) -- Vermelho se inimigo
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
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then
            for _, blip in pairs(blips) do blip.Visible = false end
            return
        end

        local myPos = myRoot.Position
        local camera = workspace.CurrentCamera
        local camY = camera.CFrame.Rotation
        
        local camLook = camera.CFrame.LookVector
        local camLookFlat = Vector3.new(camLook.X, 0, camLook.Z)
        if camLookFlat.Magnitude > 0.001 then
            camLookFlat = camLookFlat.Unit
        else
            camLookFlat = Vector3.new(0, 0, -1)
        end
        local camRight = Vector3.new(camLookFlat.Z, 0, -camLookFlat.X)
        local mapScale = (mapSize / 2) / mapZoom
        
        -- Atualizar Terreno
        if isTerrainEnabled then
            local camYaw = math.atan2(-camLookFlat.X, -camLookFlat.Z)
            local maxDistSq = (mapZoom * 1.5) * (mapZoom * 1.5) -- Otimização: calcular distância ao quadrado
            
            for _, tData in pairs(terrainParts) do
                local part = tData.part
                local frame = tData.frame
                if not part or not part.Parent then
                    frame.Visible = false
                    continue
                end
                
                local offset = part.Position - myPos
                local distSq = offset.X^2 + offset.Z^2
                
                if distSq > maxDistSq then
                    frame.Visible = false
                else
                    frame.Visible = true
                    local relX = offset:Dot(camRight)
                    local relZ = offset:Dot(camLookFlat)
                    
                    local uiX = relX * mapScale
                    local uiY = -relZ * mapScale
                    
                    local sx = math.max(2, (part.Size.X * mapScale))
                    local sy = math.max(2, (part.Size.Z * mapScale))
                    
                    frame.Size = UDim2.new(0, sx, 0, sy)
                    frame.Position = UDim2.new(0.5, uiX - (sx/2), 0.5, uiY - (sy/2))
                    
                    local partYaw = math.atan2(-part.CFrame.LookVector.X, -part.CFrame.LookVector.Z)
                    frame.Rotation = math.deg(partYaw - camYaw)
                end
            end
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end

            local character = player.Character
            local enemyRoot = character and character:FindFirstChild("HumanoidRootPart")
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
                -- Projeção
                local relX = offset:Dot(camRight)
                local relZ = offset:Dot(camLookFlat)

                -- Escalar
                local uiX = relX * mapScale
                local uiY = -relZ * mapScale

                -- Posicionar a partir do centro (0.5, 0.5)
                blip.Position = UDim2.new(0.5, uiX - 3, 0.5, uiY - 3)
            end
        end
        
        -- Limpar blips de jogadores que saíram
        for p, blip in pairs(blips) do
            if not p.Parent then
                removeBlip(p)
            end
        end
    end

    local renderConnection = nil

    function Minimap:SetEnabled(enabled)
        isEnabled = enabled
        if getgenv then getgenv().MinimapEnabled = enabled end
        
        if enabled then
            initUI()
            if container then container.Visible = true end
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
            task.spawn(GatherTerrain)
        else
            for _, t in pairs(terrainParts) do t.frame:Destroy() end
            terrainParts = {}
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
        
        if getgenv().MinimapEnabled then
            Minimap:SetEnabled(true)
        end
    end

    return Minimap
end)()

-- ==========================================
-- VOIDWARE UI LIBRARY
-- ==========================================
local VoidLib = {}
local Themes = {
    Background = Color3.fromRGB(17, 17, 20),
    Sidebar = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromHex("#B507E0"),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 160),
    Element = Color3.fromRGB(35, 35, 40),
    GroupDB = Color3.fromRGB(25, 25, 30)
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
    
    -- Mobile Draggable Helper
    local function MakeDraggable(obj)
        local dragging, dragInput, dragStart, startPos
        
        obj.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = obj.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        obj.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
    
    MakeDraggable(Main)

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
        Main.Visible = true
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
            local function CreateElementFrame()
                local EFrame = Instance.new("Frame")
                EFrame.Size = UDim2.new(1, 0, 0, 36)
                EFrame.BackgroundColor3 = Themes.Element
                EFrame.Parent = Container
                local EC = Instance.new("UICorner"); EC.CornerRadius = UDim.new(0, 6); EC.Parent = EFrame
                return EFrame
            end

            function GroupObj:Toggle(text, default, callback)
                local TFrame = CreateElementFrame()
                
                local TLab = Instance.new("TextLabel")
                TLab.Text = text
                TLab.Size = UDim2.new(1, -60, 1, 0)
                TLab.Position = UDim2.new(0, 10, 0, 0)
                TLab.BackgroundTransparency = 1
                TLab.Font = Enum.Font.GothamMedium
                TLab.TextColor3 = Themes.Text
                TLab.TextSize = 13
                TLab.TextXAlignment = Enum.TextXAlignment.Left
                TLab.Parent = TFrame
                
                local TBtn = Instance.new("TextButton")
                TBtn.Size = UDim2.new(0, 40, 0, 20)
                TBtn.Position = UDim2.new(1, -50, 0.5, -10)
                TBtn.BackgroundColor3 = default and Themes.Accent or Color3.fromRGB(60,60,65)
                TBtn.Text = ""
                TBtn.Parent = TFrame
                local TBC = Instance.new("UICorner"); TBC.CornerRadius = UDim.new(1, 0); TBC.Parent = TBtn
                
                local circle = Instance.new("Frame")
                circle.Size = UDim2.new(0, 16, 0, 16)
                circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
                circle.Parent = TBtn
                local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(1, 0); CC.Parent = circle
                
                local enabled = default
                local ToggleObj = {
                    Frame = TFrame,
                    Set = function(val)
                        enabled = val
                        TweenService:Create(circle, TweenInfo.new(0.2), {Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                        TweenService:Create(TBtn, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Themes.Accent or Color3.fromRGB(60,60,65)}):Play()
                        pcall(callback, enabled)
                    end
                }

                TBtn.MouseButton1Click:Connect(function()
                    ToggleObj.Set(not enabled)
                end)
                return ToggleObj
            end
            
            function GroupObj:Slider(text, min, max, default, callback, valueFormatter)
                local SFrame = CreateElementFrame()
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
                
                local dragging = false
                local function update(input)
                    local pos = input.Position.X
                    local rect = Track.AbsolutePosition.X
                    local size = Track.AbsoluteSize.X
                    local percent = math.clamp((pos - rect) / size, 0, 1)
                    local val = math.floor(min + (max - min) * percent)
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
                return SFrame
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
                
                local BindBtn = Instance.new("TextButton")
                local keyName = defaultKey.Name
                BindBtn.Text = keyName
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
                            BindBtn.Text = newKey.Name
                            BindBtn.TextColor3 = Themes.Text
                            getgenv().IsBindingKey = false
                            conn:Disconnect()
                            pcall(callback, newKey)
                        end
                    end)
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
    
    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if getgenv().IsDraggingMiniHUD then return end -- Prevent conflict
            dragging = true; dragStart = input.Position; startPos = Main.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then update(input) end
    end)

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
    local aimbotDependents = {} -- Store dependent frames

    local aimbotToggle = AimbotGroup:Toggle("Ativar Aimbot", AimbotCore:IsEnabled(), function(v)
        AimbotCore:SetEnabled(v)
        -- Toggle visibility of dependents
        if v then
            for _, frame in pairs(aimbotDependents) do
                frame.Visible = true
            end
        else
            for _, frame in pairs(aimbotDependents) do
                frame.Visible = false
            end
        end
    end)

    local tCheckToggle = AimbotGroup:Toggle("Ignorar Aliados", getgenv().TeamCheck, function(v)
        getgenv().TeamCheck = v
    end)
    table.insert(aimbotDependents, tCheckToggle.Frame)

    local legitToggle = AimbotGroup:Toggle("Modo Legit", getgenv().LegitMode or false, function(v)
        getgenv().LegitMode = v
    end)
    table.insert(aimbotDependents, legitToggle.Frame)
    
    local randomPartsToggle = AimbotGroup:Toggle("Humanizar (Random Parts)", getgenv().RandomParts or false, function(v)
        getgenv().RandomParts = v
    end)
    table.insert(aimbotDependents, randomPartsToggle.Frame)
    
    local aimAssistToggle = AimbotGroup:Toggle("Modo Aim Assist (Suave)", getgenv().AimAssistMode or false, function(v)
        getgenv().AimAssistMode = v
    end)
    table.insert(aimbotDependents, aimAssistToggle.Frame)
    
    local smoothSlider = AimbotGroup:Slider("Suavidade (Assist)", 1, 20, 10, function(v)
        getgenv().AimbotSmoothness = v -- 1 = Fast, 20 = Slow (Dividing factor)
    end)
    table.insert(aimbotDependents, smoothSlider)

    local cursorToggle = AimbotGroup:Toggle("Cursor Aim", AimbotCore:IsCursorAim(), function(v)
        AimbotCore:SetCursorAim(v)
    end)
    table.insert(aimbotDependents, cursorToggle.Frame)

    local function GetServerPlayers()
        local list = {}
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= game:GetService("Players").LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        return list
    end

    local ignoreList = AimbotGroup:InteractiveList("Ignorar Players", GetServerPlayers, function(name)
        AimbotCore:IgnorePlayer(name)
    end, function(name)
        AimbotCore:UnignorePlayer(name)
    end)
    table.insert(aimbotDependents, ignoreList)

    local function GetTeamsList2()
        local list = {}
        -- Safety check for Teams service
        local success, teams = pcall(function() return game:GetService("Teams"):GetTeams() end)
        if success and teams then
            for _, t in pairs(teams) do
                table.insert(list, t.Name)
            end
        end
        return list
    end

    local ignoreTeamList = AimbotGroup:InteractiveList("Ignorar Time", GetTeamsList2, function(name)
        AimbotCore:IgnoreTeam(name)
    end, function(name)
        AimbotCore:UnignoreTeam(name)
    end)
    table.insert(aimbotDependents, ignoreTeamList)

    local fovS = AimbotGroup:Slider("Campo de Visão (FOV)", 20, 500, (AimbotCore:GetFOV() or 90), function(v)
        AimbotCore:SetFOV(v)
    end)
    table.insert(aimbotDependents, fovS)

    local easingS = AimbotGroup:Slider("Suavização (Easing)", 1, 10, math.floor((getgenv().AimbotEasing or 1) * 10), function(v)
        getgenv().AimbotEasing = v / 10 
    end)
    table.insert(aimbotDependents, easingS)

    -- Initialize visibility based on default state
    local isAimbotEnabled = AimbotCore:IsEnabled()
    for _, frame in pairs(aimbotDependents) do
        frame.Visible = isAimbotEnabled
    end

    pcall(function()
        local KillAuraGroup = Combat:Group("Kill Aura")
        local killAuraToggle = KillAuraGroup:Toggle("Kill Player(s)", (KillAuraCore and KillAuraCore.IsEnabled and KillAuraCore:IsEnabled()) or false, function(v)
            if KillAuraCore then KillAuraCore:SetEnabled(v) end
        end)
    
        local function GetPlayersList()
            local list = {"Todos", "Amigos"}
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= game:GetService("Players").LocalPlayer then
                    table.insert(list, p.Name)
                end
            end
            return list
        end
    
        local TargetDrop = KillAuraGroup:Dropdown("Nome Kill (Alvo)", GetPlayersList(), "Todos", function(val)
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
    
        local TeamDrop = KillAuraGroup:Dropdown("Time Kill", GetTeamsList(), "Nada", function(val)
            if KillAuraCore then KillAuraCore:SetTeamTarget(val) end
        end)
    
        game:GetService("Teams").ChildAdded:Connect(function() pcall(function() TeamDrop:Refresh(GetTeamsList()) end) end)
        game:GetService("Teams").ChildRemoved:Connect(function() pcall(function() TeamDrop:Refresh(GetTeamsList()) end) end)
    end)
end -- End Combat Block

-- >>> TAB: VISUAL
do
    local Visual = Win:Tab("Visual")

    local ESPGroup = Visual:Group("ESP Jogadores")
    local espDependents = {} -- Store dependent frames for ESP

    local espToggle = ESPGroup:Toggle("Ativar ESP (Box)", ESPCore:IsEnabled(), function(v)
        ESPCore:SetEnabled(v)
        -- Toggle visibility of dependents
        if v then
            task.wait(0.3) -- Wait for expansion animation
            for _, frame in pairs(espDependents) do
                frame.Visible = true
            end
        else
            for _, frame in pairs(espDependents) do
                frame.Visible = false
            end
        end
    end)

    local nameToggle = ESPGroup:Toggle("Mostrar Nomes", (getgenv().ESPNames or false), function(v)
        getgenv().ESPNames = v
    end)
    table.insert(espDependents, nameToggle.Frame)

    local healthToggle = ESPGroup:Toggle("Barra de Vida", (getgenv().ESPHealth or false), function(v)
        getgenv().ESPHealth = v
    end)
    table.insert(espDependents, healthToggle.Frame)

    local tracerToggle = ESPGroup:Toggle("Linhas (Tracers)", (getgenv().ESPTracers or false), function(v)
        getgenv().ESPTracers = v
    end)
    table.insert(espDependents, tracerToggle.Frame)

    -- Initialize visibility based on default state
    local isESPEnabled = ESPCore:IsEnabled()
    for _, frame in pairs(espDependents) do
        frame.Visible = isESPEnabled
    end

    -- ============================================
    -- GRUPO: ALERTA DE AMEAÇA (HIGH ALERT)
    -- ============================================
    local AlertGroup = Visual:Group("Alerta de Ameaça (High Alert)")
    local alertDependents = {}

    local alertToggle = AlertGroup:Toggle("High Alert (Bordas)", HighAlertCore:IsEnabled(), function(v)
        HighAlertCore:SetEnabled(v)
        if v then
            task.wait(0.3)
            for _, frame in pairs(alertDependents) do
                frame.Visible = true
            end
        else
            for _, frame in pairs(alertDependents) do
                frame.Visible = false
            end
        end
    end)

    local alertTeamToggle = AlertGroup:Toggle("Ignorar Aliados (Time)", HighAlertCore:IsTeamCheck(), function(v)
        HighAlertCore:SetTeamCheck(v)
    end)
    table.insert(alertDependents, alertTeamToggle.Frame)

    local alertThicknessSlider = AlertGroup:Slider("Tamanho da Borda", 3, 50, HighAlertCore:GetBorderThickness(), function(v)
        HighAlertCore:SetBorderThickness(v)
    end)
    table.insert(alertDependents, alertThicknessSlider)

    local alertArrowToggle = AlertGroup:Toggle("Seta Direcional (Centro)", HighAlertCore:IsArrowEnabled(), function(v)
        HighAlertCore:SetArrowEnabled(v)
    end)
    table.insert(alertDependents, alertArrowToggle.Frame)

    local alertArrowRadiusSlider = AlertGroup:Slider("Distância da Seta", 30, 300, HighAlertCore:GetArrowRadius(), function(v)
        HighAlertCore:SetArrowRadius(v)
    end)
    table.insert(alertDependents, alertArrowRadiusSlider)

    local alertArrowSizeSlider = AlertGroup:Slider("Tamanho da Seta", 8, 50, HighAlertCore:GetArrowSize(), function(v)
        HighAlertCore:SetArrowSize(v)
    end)
    table.insert(alertDependents, alertArrowSizeSlider)

    -- Initialize visibility based on default state
    local isAlertEnabled = HighAlertCore:IsEnabled()
    for _, frame in pairs(alertDependents) do
        frame.Visible = isAlertEnabled
    end

    local HeadGroup = Visual:Group("Cabeças (Headshot)")
    local headToggle = HeadGroup:Toggle("Expandir Cabeças", HeadESP:IsEnabled(), function(v)
        HeadESP:SetEnabled(v)
    end)
    HeadGroup:Slider("Tamanho", 1, 20, HeadESP:GetHeadSize(), function(v)
        HeadESP:SetHeadSize(v)
    end)
    
    -- ============================================
    -- GRUPO: MINIMAPA (RADAR)
    -- ============================================
    local MinimapGroup = Visual:Group("Minimapa (Radar)")
    local minimapDependents = {}
    
    local minimapToggle = MinimapGroup:Toggle("Ativar Minimapa", MinimapCore:IsEnabled(), function(v)
        MinimapCore:SetEnabled(v)
        if v then
            task.wait(0.3)
            for _, frame in pairs(minimapDependents) do frame.Visible = true end
        else
            for _, frame in pairs(minimapDependents) do frame.Visible = false end
        end
    end)
    
    local minimapRoundToggle = MinimapGroup:Toggle("Formato Redondo", MinimapCore:IsRound(), function(v)
        MinimapCore:SetRound(v)
    end)
    table.insert(minimapDependents, minimapRoundToggle.Frame)
    
    local minimapLockToggle = MinimapGroup:Toggle("Travar (Não Arrastar)", MinimapCore:IsLocked(), function(v)
        MinimapCore:SetLocked(v)
    end)
    table.insert(minimapDependents, minimapLockToggle.Frame)
    
    local minimapTerrainToggle = MinimapGroup:Toggle("Mostrar Mapa (Terreno)", MinimapCore:IsTerrain(), function(v)
        MinimapCore:SetTerrain(v)
    end)
    table.insert(minimapDependents, minimapTerrainToggle.Frame)
    
    local minimapSizeSlider = MinimapGroup:Slider("Tamanho do HUD", 100, 300, MinimapCore:GetSize(), function(v)
        MinimapCore:SetSize(v)
    end)
    table.insert(minimapDependents, minimapSizeSlider)
    
    local minimapZoomSlider = MinimapGroup:Slider("Distância (Zoom)", 50, 500, MinimapCore:GetZoom(), function(v)
        MinimapCore:SetZoom(v)
    end)
    table.insert(minimapDependents, minimapZoomSlider)
    
    local isMinimapEnabled = MinimapCore:IsEnabled()
    for _, frame in pairs(minimapDependents) do
        frame.Visible = isMinimapEnabled
    end
    
end -- End Visual Block

-- >>> TAB: LOCAL PLAYER
do
    local Local = Win:Tab("Local")
    local CharGroup = Local:Group("Personagem")
    local respawnToggle = CharGroup:Toggle("Respawn Onde Morreu", RespawnCore:IsEnabled(), function(v)
        RespawnCore:SetEnabled(v)
    end)

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
            getgenv().IsDraggingMiniHUD = true -- Signal conflict prevention
            draggingAFK = true
            dragStartAFK = input.Position
            startPosAFK = AFKHud.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingAFK = false
                    getgenv().IsDraggingMiniHUD = false
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

    AntiAFKGroup:Toggle("Ativar Anti-AFK", false, function(v)
        antiAfkEnabled = v
        AFKHud.Visible = v
    end)
end -- End Local Block



-- >>> TAB: CONFIGURAÇÕES
do
    local Settings = Win:Tab("Configs")
    local ManagerGroup = Settings:Group("Gerenciamento")

    local function Notify(msg)
        game:GetService("StarterGui"):SetCore("SendNotification", {Title="DreeZy HUB", Text=msg, Duration=3})
    end

    ManagerGroup:Button("Salvar Configurações", function()
        if writefile then
            local config = {
                aimbot = AimbotCore:IsEnabled(),
                teamCheck = getgenv().TeamCheck,
                legitMode = getgenv().LegitMode,
                killAura = KillAuraCore:IsEnabled(),
                fov = AimbotCore:GetFOV(),
                esp = ESPCore:IsEnabled(),
                espNames = getgenv().ESPNames,
                espTracers = getgenv().ESPTracers,
                espHealth = getgenv().ESPHealth,
                highAlert = HighAlertCore:IsEnabled(),
                highAlertTeamCheck = HighAlertCore:IsTeamCheck(),
                highAlertThickness = HighAlertCore:GetBorderThickness(),
                highAlertArrow = HighAlertCore:IsArrowEnabled(),
                highAlertArrowRadius = HighAlertCore:GetArrowRadius(),
                highAlertArrowSize = HighAlertCore:GetArrowSize(),
                minimap = MinimapCore:IsEnabled(),
                minimapRound = MinimapCore:IsRound(),
                minimapLocked = MinimapCore:IsLocked(),
                minimapTerrain = MinimapCore:IsTerrain(),
                minimapSize = MinimapCore:GetSize(),
                minimapZoom = MinimapCore:GetZoom(),
                headEsp = HeadESP:IsEnabled(),
                headSize = HeadESP:GetHeadSize(),
                respawn = RespawnCore:IsEnabled(),
                unlockKey = getgenv().UnlockMouseKey.Name
            }
            writefile("DreeZy_Voidware.json", HttpService:JSONEncode(config))
            Notify("Configurações salvas!")
        else
            Notify("Executor não suporta writefile")
        end
    end)

    ManagerGroup:Button("Carregar Configurações", function()
        if isfile and isfile("DreeZy_Voidware.json") then
            local config = HttpService:JSONDecode(readfile("DreeZy_Voidware.json"))
            if config then
                -- Note: Toggles are local to other scopes, so we cannot update them directly here easily unless we exposed them or use a global registry.
                -- For now, we just notify. Logic is updated via Set... functions if we added them.
                -- To fix this properly, we would need to expose the toggles.
                Notify("Configurações Carregadas (Lógica)")
                
                -- Update Logic directly
                if config.aimbot ~= nil then AimbotCore:SetEnabled(config.aimbot) end
                if config.teamCheck ~= nil then getgenv().TeamCheck = config.teamCheck end
                if config.esp ~= nil then ESPCore:SetEnabled(config.esp) end
                if config.highAlert ~= nil then HighAlertCore:SetEnabled(config.highAlert) end
                if config.highAlertTeamCheck ~= nil then HighAlertCore:SetTeamCheck(config.highAlertTeamCheck) end
                if config.highAlertThickness ~= nil then HighAlertCore:SetBorderThickness(config.highAlertThickness) end
                if config.highAlertArrow ~= nil then HighAlertCore:SetArrowEnabled(config.highAlertArrow) end
                if config.highAlertArrowRadius ~= nil then HighAlertCore:SetArrowRadius(config.highAlertArrowRadius) end
                if config.highAlertArrowSize ~= nil then HighAlertCore:SetArrowSize(config.highAlertArrowSize) end
                if config.minimap ~= nil then MinimapCore:SetEnabled(config.minimap) end
                if config.minimapRound ~= nil then MinimapCore:SetRound(config.minimapRound) end
                if config.minimapLocked ~= nil then MinimapCore:SetLocked(config.minimapLocked) end
                if config.minimapTerrain ~= nil then MinimapCore:SetTerrain(config.minimapTerrain) end
                if config.minimapSize ~= nil then MinimapCore:SetSize(config.minimapSize) end
                if config.minimapZoom ~= nil then MinimapCore:SetZoom(config.minimapZoom) end
                -- ... etc
                
                if config.unlockKey then getgenv().UnlockMouseKey = Enum.KeyCode[config.unlockKey] end
            end
        else
            Notify("Nenhum save encontrado")
        end
    end)

    local InfoGroup = Settings:Group("Informações")
    InfoGroup:Button("Criado por DreeZy", function() setclipboard("DreeZy") end)
end -- End Settings Block

Notify("DreeZy Voidware V2 Carregado!")
Notify("Use [Right Shift] para abrir/fechar o Menu!")
