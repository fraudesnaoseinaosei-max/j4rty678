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
if not getgenv().UnlockMouseKey then getgenv().UnlockMouseKey = Enum.KeyCode.P end

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
                if getgenv().LegitMode then
                    activeTargetPart = getRandomPart(currentTarget.Character)
                else
                    activeTargetPart = "Head"
                end
            end

            if currentTarget.Character then
                -- Fallback if the specific part is missing (e.g. lost limb)
                local targetInst = currentTarget.Character:FindFirstChild(activeTargetPart)
                if not targetInst then 
                    targetInst = currentTarget.Character:FindFirstChild("Head") 
                end

                if targetInst then
                    local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                         local currentCFrame = camera.CFrame
                         local easing = getgenv().AimbotEasing or 1
                         camera.CFrame = currentCFrame:Lerp(CFrame.new(currentCFrame.Position, targetInst.Position), easing)
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

-- [5] BOT CORE (AI)
local BotCore = (function()
    local BotCore = {}
    local Players = game:GetService("Players")
    local PathfindingService = game:GetService("PathfindingService")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    -- State Flags
    local isFollowEnabled = false
    local isFlingEnabled = false
    local isDefenseEnabled = false -- New Defense Mode
    local isMeleeEnabled = false -- New Melee Mode
    local isRangedEnabled = false -- New Ranged Mode

    

    -- Missile/Fling State Machine
    local FlingState = {
        IDLE = "IDLE",
        APPROACH = "APPROACH",
        FLINGING = "FLINGING",
        RETURNING = "RETURNING",
        RANGED = "RANGED"
    }
    local currentFlingState = FlingState.IDLE
    local activeFlingTarget = nil
    local flingStartTime = 0
    local lastTargetPos = Vector3.zero
    
    local loopConnection = nil
    local lastPathTime = 0
    local currentWaypoints = nil
    local currentWaypointIndex = 0
    local lastPosition = Vector3.new(0,0,0)
    local noCollisionConstraintParts = {} -- Store multiple constraints
    
    local DefenseConfig = {
        TeamCheck = false,
        IgnoreList = {}
    }
    local stationaryStartTime = 0


    -- Configuration
    local Config = {
        MinDistance = 10,
        MaxDistance = 20,
        TeleportDistance = 120,
        PathUpdateInterval = 0.5,
        RaycastDistance = 5,
        StuckThreshold = 2,
        JumpPower = 50,
        VisionRadius = 50, -- Vision Radius
        DefenseRadius = 50, -- Radius to trigger defense on Master
        FlingSafeDistance = 3, -- Distance from Master to disable Fling (Safety)
        DefenseSafeZone = 0, -- Disabled by default as requested
        RangedDistance = 100, -- Max distance for Ranged Mode
        MeleeTriggerDistance = 20, -- Distance to switch/force Melee
        SelfDefenseRadius = 15, -- Radius to trigger defense on SELF
        UseVirtualClick = false -- Virtual Click for Prison Life etc
    }
    
    local FlingTargets = {} -- List of targets to attack
    local ActiveTargetNPCs = {
        ["Noob"] = true, -- Default for testing
        ["Dummy"] = true
    }
    local WeaponPriority = {}
    BotCore.ActiveTargetNPCs = ActiveTargetNPCs -- Expose
    BotCore.WeaponPriority = WeaponPriority -- Expose

    local function getRoot(char)
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function getHumanoid(char)
        return char and char:FindFirstChild("Humanoid")
    end

    -- Raycast Obstacle Detection
    local function CheckObstacle(rootPart)
        local checkDir = rootPart.CFrame.LookVector
        local rayOrigin = rootPart.Position
        local rayDirection = checkDir * Config.RaycastDistance
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if result then
            return true, result
        end
        return false, nil
    end

    local function MoveTo(position)
        local char = LocalPlayer.Character
        local hum = getHumanoid(char)
        if hum then
            hum:MoveTo(position)
        end
    end

    local lastDebugPrint = 0
    local wanderingTarget = nil
    local wanderWaitTime = 0
    local lastWanderTime = 0

    function BotCore:SetTarget(name)
        if currentTargetName ~= name then
            warn("[BotDebug] New Target: " .. tostring(name))
            currentTargetName = name
            currentWaypoints = nil
            currentWaypointIndex = 0
            wanderingTarget = nil -- Reset wander
        end
    end

    -- 3-Ray Obstacle Avoidance (Steering)
    local function GetObstacleAvoidanceVector(rootPart)
        local fwd = rootPart.CFrame.LookVector
        local right = rootPart.CFrame.RightVector
        local origin = rootPart.Position

        -- Rays: Center, Left (45), Right (45)
        local rays = {
            center = fwd,
            left = (fwd - right).Unit,
            right = (fwd + right).Unit
        }

        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local hits = {}
        for dir, vec in pairs(rays) do
            local result = workspace:Raycast(origin, vec * Config.RaycastDistance, rayParams)
            if result then hits[dir] = true end
        end

        -- Logic: If center blocked, steer to clear side
        if hits.center then
            if not hits.left and not hits.right then
                -- Both sides clear, random choice or bias right
                return rays.right * 0.5 -- Steer right
            elseif not hits.left then
                return rays.left * 0.8 -- Steer left hard
            elseif not hits.right then
                return rays.right * 0.8 -- Steer right hard
            else
                -- All blocked: Jump!
                return "JUMP"
            end
        end
        
        return nil -- No correction needed
    end

    local function GetRandomWanderPoint(center)
        local rad = math.random(5, 15)
        local angle = math.rad(math.random(0, 360))
        local offX = math.cos(angle) * rad
        local offZ = math.sin(angle) * rad
        return center + Vector3.new(offX, 0, offZ)
    end

    local function TeleportReturn()
         local targetPlr = Players:FindFirstChild(currentTargetName)
         local ownerRoot = nil
         if targetPlr and targetPlr.Character then ownerRoot = getRoot(targetPlr.Character) end
         
         if ownerRoot then
             local myChar = LocalPlayer.Character
             if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                 myChar.HumanoidRootPart.CFrame = ownerRoot.CFrame * CFrame.new(0, 0, 5)
                 myChar.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                 myChar.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
             end
         end
         
         currentFlingState = FlingState.IDLE
         activeFlingTarget = nil
         
         -- Reset Physics
         local myChar = LocalPlayer.Character
         if myChar then
             local hum = getHumanoid(myChar)
             if hum then 
                 hum.PlatformStand = false 
                 hum.AutoRotate = true 
             end
             for _, p in pairs(myChar:GetChildren()) do
                 if p:IsA("BasePart") then p.CanCollide = true end
             end
         end
    end

    -- [HELPER: MOVEMENT]
    local function SmartAutoJump(hum, root)
        if not hum or not root then return end
        if hum.MoveDirection.Magnitude > 0.1 then
            -- Raycast Forward (Waist/Leg height)
            local origin = root.Position - Vector3.new(0, 1.5, 0) -- Lower body
            local dir = hum.MoveDirection * 2 -- 2 studs forward
            
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            
            local result = workspace:Raycast(origin, dir, params)
            if result then
                -- Obstacle hit!
                -- Check if it's low enough to jump (raycast higher)
                local higherOrigin = root.Position + Vector3.new(0, 0, 0) -- Hips/Navel
                local higherResult = workspace:Raycast(higherOrigin, dir, params)
                
                if not higherResult then
                     -- Low obstacle, JUMP!
                     hum.Jump = true
                end
            end
        end
    end

    -- [HELPER: THREAT SCANNER]
    -- [HELPER: THREAT SCANNER]
    function BotCore:ScanForThreats(masterRoot)
        -- Identify closest threat to Master OR Self
        local nearestEnemy = nil
        local nearestDist = isRangedEnabled and Config.RangedDistance or Config.DefenseRadius
        
        local myRoot = nil
        if LocalPlayer.Character then myRoot = getRoot(LocalPlayer.Character) end

        -- Gather Targets
        local allTargets = {}
        for _, p in pairs(Players:GetPlayers()) do table.insert(allTargets, p) end
        for name, _ in pairs(ActiveTargetNPCs) do
            for _, v in pairs(workspace:GetChildren()) do
                 if v.Name == name and v:IsA("Model") and v:FindFirstChild("Humanoid") then
                     table.insert(allTargets, v)
                 end
            end
        end

        for _, enemy in pairs(allTargets) do
            local isPlayer = enemy:IsA("Player")
            if enemy ~= LocalPlayer and (not isPlayer or enemy.Name ~= currentTargetName) then
                local allow = true
                if isPlayer and DefenseConfig.IgnoreList[enemy.Name] then allow = false end
                
                -- Team Check
                if isPlayer and DefenseConfig.TeamCheck then
                     local master = Players:FindFirstChild(currentTargetName)
                     if master and master.Team and enemy.Team and master.Team == enemy.Team then allow = false end
                end

                local char = isPlayer and enemy.Character or enemy
                local eRoot = getRoot(char)
                local eHum = getHumanoid(char)

                if allow and char and eRoot and eHum and eHum.Health > 0 then
                     local dMaster = masterRoot and (eRoot.Position - masterRoot.Position).Magnitude or 9999
                     local dSelf = myRoot and (eRoot.Position - myRoot.Position).Magnitude or 9999
                     
                     -- Safe Zone Check
                     if dMaster < Config.DefenseSafeZone then
                          -- Ignore target in Safe Zone
                     else
                          -- Score: Lower is better (closer)
                          -- Prioritize Close to Self (Self Defense)
                          local score = dMaster
                          if dSelf < Config.SelfDefenseRadius then
                              score = dSelf - 100 -- Massive priority boost
                          end
                          
                          if score < nearestDist then
                              nearestDist = score
                              nearestEnemy = {Object = enemy, Character = char, Name = enemy.Name}
                          end
                     end
                end
            end
        end
        return nearestEnemy
    end

    local function UpdateBot()
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myRoot = getRoot(myChar)
        local myHum = getHumanoid(myChar)
        if not myRoot or not myHum then return end
        
        -- [AUTO JUMP]
        SmartAutoJump(myHum, myRoot)
        
        -- Safe Helper to Reset Physics
        local function ResetPhysics()
             if myRoot.AssemblyAngularVelocity.Magnitude > 100 then
                 myRoot.AssemblyAngularVelocity = Vector3.zero
                 myRoot.AssemblyLinearVelocity = Vector3.zero
             end
             for _, p in pairs(myChar:GetChildren()) do
                 if p:IsA("BasePart") then p.CanCollide = true end
             end
             -- Fix PlatformStand being stuck
             if myHum.PlatformStand then myHum.PlatformStand = false end
             if not myHum.AutoRotate then myHum.AutoRotate = true end
        end

        local function UpdateCollision(targetChar)
             -- Disable collision with Master (Ghost Mode)
             if not targetChar then 
                 for _, c in pairs(noCollisionConstraintParts) do pcall(function() c:Destroy() end) end
                 noCollisionConstraintParts = {}
                 return 
             end
             
             local myChar = LocalPlayer.Character
             if not myChar then return end
             
             -- Iterate ALL parts of both characters for total safety
             -- Use GetDescendants to catch Accessories, Handles, etc.
             for _, myPart in pairs(myChar:GetDescendants()) do
                 if myPart:IsA("BasePart") then
                     for _, tPart in pairs(targetChar:GetDescendants()) do
                         if tPart:IsA("BasePart") then
                             local key = myPart.Name .. "_" .. tPart.Name
                             if not noCollisionConstraintParts[key] or not noCollisionConstraintParts[key].Parent then
                                 local ncc = Instance.new("NoCollisionConstraint")
                                 ncc.Name = "AntiFriend_"..key
                                 ncc.Part0 = myPart
                                 ncc.Part1 = tPart
                                 ncc.Parent = myPart
                                 noCollisionConstraintParts[key] = ncc
                                 
                                 -- Double safety: If we can, sets group? No, script is client-side usually.
                                 -- This Constraint should be enough.
                             end
                         end
                     end
                 end
             end
        end

        ------------------------------------------------------------------------
        -- STATE MACHINE
        ------------------------------------------------------------------------
        
        -- Handle Collision with Master (Always run if following)
        if currentTargetName then
             local targetPlr = Players:FindFirstChild(currentTargetName)
             if targetPlr and targetPlr.Character then
                 UpdateCollision(targetPlr.Character)
             else
                 UpdateCollision(nil)
             end
        else
             UpdateCollision(nil)
        end
        
        -- [STATE: IDLE] Guarding / Scanning
        if currentFlingState == FlingState.IDLE then
                -- Holster Logic
                if myHum then myHum:UnequipTools() end


            
            -- DEFENSE / AUTO-MELEE / RANGED MODE LOGIC
            -- Triggers if Defense OR Melee OR Ranged is enabled.
            if (isDefenseEnabled or isMeleeEnabled or isRangedEnabled) and currentTargetName and currentTargetName ~= "Nenhum" then
                local master = Players:FindFirstChild(currentTargetName)
                if master and master.Character then
                    local mRoot = getRoot(master.Character)
                    if mRoot then
                        -- Check for enemies near Master
                        local nearestEnemy = BotCore:ScanForThreats(mRoot)
                        
                        if nearestEnemy then
                            activeFlingTarget = nearestEnemy.Object
                            
                            -- DECIDE ATTACK MODE
                            -- Priority: Melee (< 20) | Ranged (> 20 & < RangedDist) | Fling (Fallback)
                            local distToTarget = (nearestEnemy.Character.HumanoidRootPart.Position - mRoot.Position).Magnitude
                            
                            local mode = "FLING"
                            
                            -- Logic:
                            -- 1. If Melee is ON and target is close (<TriggerDist), force MELEE.
                            -- 2. If Ranged is ON and target is within range (and > TriggerDist or Melee OFF), force RANGED.
                            -- 3. Else fallback to Fling if Defense ON.

                            if isMeleeEnabled and distToTarget < Config.MeleeTriggerDistance then
                                mode = "MELEE"
                            elseif isRangedEnabled and distToTarget <= Config.RangedDistance then
                                mode = "RANGED"
                            elseif isMeleeEnabled then
                                -- Target too far for Melee preference, but maybe chase? 
                                -- User said "Priority based on distance".
                                -- If only Melee is on, chase.
                                mode = "MELEE"
                            elseif isDefenseEnabled then
                                mode = "APPROACH" -- Fling
                            end
                            
                            if mode == "MELEE" then
                                currentFlingState = "MELEE"
                                warn("[BotCombat] Melee Engaging: " .. nearestEnemy.Name)
                            elseif mode == "RANGED" then
                                currentFlingState = "RANGED"
                                warn("[BotCombat] Ranged Engaging: " .. nearestEnemy.Name)
                            else
                                currentFlingState = FlingState.APPROACH
                                warn("[BotDefense] Flinging Target: " .. nearestEnemy.Name)
                            end
                            
                            flingStartTime = tick()
                            return
                        end
                    end
                end
            end
            
            -- NORMAL GUARD BEHAVIOR (Follow Logic)
            ResetPhysics()
            
            if not currentTargetName or currentTargetName == "Nenhum" then return end
            local targetPlr = Players:FindFirstChild(currentTargetName)
            if not targetPlr or not targetPlr.Character then return end
            local targetRoot = getRoot(targetPlr.Character)
            if not targetRoot then return end

            local dist = (myRoot.Position - targetRoot.Position).Magnitude

            -- Seat Safety
            if myHum.Sit then
                if dist > Config.MaxDistance or dist > Config.TeleportDistance then myHum.Sit = false; myHum.Jump = true return end
            end

            -- Teleport Fallback
            if dist > Config.TeleportDistance then
                if myRoot:FindFirstChild("SeatWeld") then myRoot.SeatWeld:Destroy() end
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
                wanderingTarget = nil; currentWaypoints = nil
                return
            end

            -- Wander vs Chase
            if dist > Config.MaxDistance then
                 -- Chase Logic
                 wanderingTarget = nil
                 local goalPos = targetRoot.Position
                 if tick() - lastPathTime > Config.PathUpdateInterval then
                     lastPathTime = tick()
                     local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
                     pcall(function() path:ComputeAsync(myRoot.Position, goalPos) end)
                     if path.Status == Enum.PathStatus.Success then
                         currentWaypoints = path:GetWaypoints()
                         currentWaypointIndex = 2
                     else
                         currentWaypoints = nil; MoveTo(goalPos)
                     end
                 end
                 
                 if currentWaypoints and currentWaypointIndex <= #currentWaypoints then
                     local wp = currentWaypoints[currentWaypointIndex]
                     local avoidance = GetObstacleAvoidanceVector(myRoot)
                     if avoidance == "JUMP" then myHum.Jump = true; myHum:MoveTo(wp.Position)
                     elseif avoidance then
                         local desiredDir = (wp.Position - myRoot.Position).Unit
                         local finalDir = (desiredDir + avoidance).Unit
                         myHum:MoveTo(myRoot.Position + finalDir * 5)
                     else
                         if wp.Action == Enum.PathWaypointAction.Jump then myHum.Jump = true end
                         myHum:MoveTo(wp.Position)
                     end
                     if (myRoot.Position - wp.Position).Magnitude < 5 then currentWaypointIndex = currentWaypointIndex + 1 end
                 else
                     MoveTo(goalPos)
                 end
                 
            elseif dist < Config.MinDistance then
                -- Wander Logic
                if tick() < wanderWaitTime then myHum:MoveTo(myRoot.Position) return end
                if not wanderingTarget or (myRoot.Position - wanderingTarget).Magnitude < 4 then
                    wanderingTarget = GetRandomWanderPoint(targetRoot.Position)
                    wanderWaitTime = tick() + math.random(1, 3)
                end
                local avoidance = GetObstacleAvoidanceVector(myRoot)
                if avoidance == "JUMP" then myHum.Jump = true end
                myHum:MoveTo(wanderingTarget)
            end

    -- [STATE: APPROACH] Flying to Target
        elseif currentFlingState == FlingState.APPROACH then
             if not activeFlingTarget or not activeFlingTarget.Character then
                 currentFlingState = FlingState.RETURNING
                 return
             end
             local tRoot = getRoot(activeFlingTarget.Character)
             if not tRoot then currentFlingState = FlingState.RETURNING return end
             
             -- Noclip & Float
             if myHum.Sit then myHum.Sit = false end
             for _, p in pairs(myChar:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
             myHum.PlatformStand = true
             
             local dist = (myRoot.Position - tRoot.Position).Magnitude
             
             if dist < 5 then
                 -- Arrived!
                 currentFlingState = FlingState.FLINGING
                 lastTargetPos = tRoot.Position
                 flingStartTime = tick()
                 flingStartHeight = myRoot.Position.Y -- CAPTURE START HEIGHT
             else
                 -- Fly towards
                 local dir = (tRoot.Position - myRoot.Position).Unit
                 myRoot.AssemblyLinearVelocity = dir * 80 -- Controlled speed
                 myRoot.CFrame = CFrame.new(myRoot.Position, tRoot.Position)
             end

     -- [STATE: FLINGING] Spin & Neutralize
        elseif currentFlingState == FlingState.FLINGING then
             -- [v2 FIX] FORCE PLATFORMSTAND FALSE so MoveTo works and we don't trip!
             if myHum.PlatformStand then myHum.PlatformStand = false end
             -- Also force Physics state to be safe
             -- myHum:ChangeState(Enum.HumanoidStateType.Physics) -- sometimes helpful
             
             local targetChar = nil
             if activeFlingTarget then
                 if activeFlingTarget:IsA("Player") then targetChar = activeFlingTarget.Character
                 elseif activeFlingTarget:IsA("Model") then targetChar = activeFlingTarget end -- NPC Support
             end

             if not targetChar then
                 currentFlingState = FlingState.RETURNING
                 return
             end
             local tRoot = getRoot(targetChar)
             local tHum = getHumanoid(targetChar)
             if not tRoot then currentFlingState = FlingState.RETURNING return end
             
             -- [DYNAMIC SAFE ZONE ABORT]
             -- Check if enemy ran back to the Master. If so, ABORT to protect Master.
             if isDefenseEnabled and currentTargetName and currentTargetName ~= "Nenhum" then
                local master = Players:FindFirstChild(currentTargetName)
                if master and master.Character then
                     local mRoot = getRoot(master.Character)
                     if mRoot then
                         local distEnemyToMaster = (tRoot.Position - mRoot.Position).Magnitude
                         if distEnemyToMaster < Config.DefenseSafeZone then
                              warn("[BotDefense] Enemy entered Safe Zone! Aborting attack.")
                              activeFlingTarget = nil
                              currentFlingState = FlingState.RETURNING
                              return 
                         end
                     end
                end
             end

             -- [!] ENABLE COLLISIONS FOR FLING TO WORK
             for _, p in pairs(myChar:GetChildren()) do
                 if p:IsA("BasePart") then p.CanCollide = true end
             end
             
             -- [!] FORCE SIMULATION RADIUS (Network Ownership)
             pcall(function()
                 settings().Physics.AllowSleep = false
                 sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                 sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
             end)
             
             -- [!] ENABLE COLLISIONS
             for _, p in pairs(myChar:GetChildren()) do
                 if p:IsA("BasePart") then p.CanCollide = true end
             end
             
             -- --- CATCH & RELEASE MECH ---
             local targetVelocity = tRoot.AssemblyLinearVelocity.Magnitude
             local targetMovedDist = (tRoot.Position - lastTargetPos).Magnitude
             local distFromMe = (tRoot.Position - myRoot.Position).Magnitude
             
             -- [PHASE 1: RELEASE & WATCH]
             -- If they are moving fast (>300), let go and watch them fly.
             if targetVelocity > 300 then
                 -- Hover in place
                 myRoot.AssemblyLinearVelocity = Vector3.zero
                 myRoot.AssemblyAngularVelocity = Vector3.zero
                 -- Don't lock CFrame. Just wait.
                 
                 -- [SUCCESS CHECK]
                 -- If they are far away (>100) AND moving fast (or gone), we win.
                 if targetMovedDist > 100 or distFromMe > 80 then
                      warn("[BotAttack] Fling Successful! (Yeeted " .. math.floor(targetMovedDist) .. " studs)")
                      TeleportReturn()
                      return
                 end
                 
             end
             
             -- [SAFE DISTANCE CHECK]
             -- If Master is too close to me while I am flinging, STOP SPINNING to avoid hitting Master.
             if currentTargetName and currentTargetName ~= "Nenhum" then
                 local master = Players:FindFirstChild(currentTargetName)
                 if master and master.Character then
                      local mRoot = getRoot(master.Character)
                      if mRoot then
                          local distToMaster = (mRoot.Position - myRoot.Position).Magnitude
                          if distToMaster < Config.FlingSafeDistance then
                               -- SAFETY STOP
                               myRoot.AssemblyAngularVelocity = Vector3.zero
                               myRoot.AssemblyLinearVelocity = Vector3.zero
                               -- We can still move towards enemy, but no dangerous spin
                               myHum:MoveTo(tRoot.Position)
                               return
                          end
                      end
                 end
             end
             
             -- [PHASE 2: WALKFLING SPIN]
             -- "Pipoco" Fix: Do NOT Skyrocket. Stay grounded.
             -- Move INTO the target to force physics collision overlap.
             
             -- High Angular Velocity for Spin
             myRoot.AssemblyAngularVelocity = Vector3.new(0, 10000, 0)
             
             -- Reset Linear Velocity to avoid flying away (keep it normal physics)
             -- myRoot.AssemblyLinearVelocity = Vector3.zero 
             -- Actually, we want to PUSH them.
             
             -- Position: Walk INTO them CONSTANTLY
             -- Force movement even if close
             -- Position: Walk INTO them CONSTANTLY
             -- Force movement even if close
             -- [AGGRESSIVE MOVEMENT FIX]
             
             -- [FEATURE: MASTER SAFETY CHECK (STRICT)]
             -- If Master is within 8 studs (panic distance), ZERO ALL.
             if currentTargetName and currentTargetName ~= "Nenhum" then
                  local master = Players:FindFirstChild(currentTargetName)
                  if master and master.Character then
                      local mRoot = getRoot(master.Character)
                      if mRoot and (mRoot.Position - myRoot.Position).Magnitude < 8 then
                           myRoot.AssemblyLinearVelocity = Vector3.zero
                           myRoot.AssemblyAngularVelocity = Vector3.zero
                           -- Just follow safely, no spin.
                           myHum:MoveTo(tRoot.Position)
                           return
                      end
                  end
             end
             
             local targetVelocity = tRoot.AssemblyLinearVelocity
             local horizSpeed = Vector3.new(targetVelocity.X, 0, targetVelocity.Z).Magnitude
             
             -- [FEATURE: PREDICTIVE INTERCEPTION]
             -- If target is moving fast (>10) AND running away (dist > 6)
             -- TP in FRONT of them to cut them off.
             local distToTarget = (myRoot.Position - tRoot.Position).Magnitude
             
             if horizSpeed > 8 and distToTarget > 6 then
                  -- Calculate "Front" 4 studs ahead
                  local moveDir = (targetVelocity * Vector3.new(1,0,1)).Unit
                  if moveDir.X == moveDir.X then -- NaN check
                       local interceptPos = tRoot.Position + (moveDir * 5) -- 5 studs ahead
                       
                       -- TP there, looking AT them
                       myRoot.CFrame = CFrame.new(interceptPos, tRoot.Position)
                       
                       -- Push BACK into them (Opposite to their movement)
                       -- This forces a head-on collision
                       myHum:MoveTo(tRoot.Position)
                       
                       -- Reset statonary timer
                       stationaryStartTime = 0
                  end
             elseif horizSpeed < 2 then
                  -- [FEATURE: STATIONARY FLING]
                  if not stationaryStartTime or stationaryStartTime == 0 then
                      stationaryStartTime = tick()
                  elseif tick() - stationaryStartTime > 1.5 then -- Faster trigger (1.5s)
                       -- TP Inside + Tremble
                       myRoot.CFrame = tRoot.CFrame
                       local tremble = Vector3.new(math.random()-0.5, 0, math.random()-0.5) * 2
                       myHum:MoveTo(tRoot.Position + tremble)
                  end
             else
                  -- Standard Chase/Push
                  stationaryStartTime = 0
                  local pushDir = (tRoot.Position - myRoot.Position).Unit
                  if pushDir.X ~= pushDir.X then pushDir = myRoot.CFrame.LookVector end
                  myHum:MoveTo(tRoot.Position + pushDir * 10)
             end
             
             if distFromMe > 5 then
                  myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2)
             end

        -- [STATE: MELEE COMBAT]
        elseif currentFlingState == "MELEE" then
             local targetChar = nil
             if activeFlingTarget then
                 if activeFlingTarget:IsA("Player") then targetChar = activeFlingTarget.Character
                 elseif activeFlingTarget:IsA("Model") then targetChar = activeFlingTarget end
             end
             
             if not targetChar then
                 currentFlingState = FlingState.RETURNING
                 return
             end
             
             local tRoot = getRoot(targetChar)
             local tHum = getHumanoid(targetChar)
             if not tRoot or not tHum or tHum.Health <= 0 then
                 currentFlingState = FlingState.RETURNING
                 return
             end
             
             -- 1. Equip Weapon (First Tool)
             -- 1. Equip Weapon (Priority)
             local tool = BotCore:GetPriorityWeapon(myChar)
             if tool and tool.Parent ~= myChar then
                 myHum:EquipTool(tool)
             end
             
             -- 2. Master Safety Logic (LOS)
             local safeToAttack = true
             if currentTargetName and currentTargetName ~= "Nenhum" then
                 local master = Players:FindFirstChild(currentTargetName)
                 if master and master.Character then
                      local mRoot = getRoot(master.Character)
                      if mRoot then
                          -- Check 1: Distance Limit relative to Master (Don't chase too far)
                          if (tRoot.Position - mRoot.Position).Magnitude > (Config.DefenseRadius * 2) then
                               warn("[BotCombat] Target too far. Returning.")
                               currentFlingState = FlingState.RETURNING
                               return
                          end
                          
                          -- Check 2: Target Switching (Is someone closer?)
                          local bestThreat = BotCore:ScanForThreats(mRoot)
                          if bestThreat and bestThreat.Object ~= activeFlingTarget and bestThreat.Character then
                               local dNew = (bestThreat.Character:FindFirstChild("HumanoidRootPart").Position - mRoot.Position).Magnitude
                               local dCurr = (tRoot.Position - mRoot.Position).Magnitude
                               
                               if dNew < (dCurr - 5) then -- 5 Stud Hysteresis
                                    warn("[BotCombat] Switching to closer threat: " .. bestThreat.Name)
                                    activeFlingTarget = bestThreat.Object
                                    -- Should we reset state? Usually just changing target is enough for loop to catch up next frame.
                                    -- But let's reset to approach if needed? No, MELEE handles it.
                                    return 
                               end
                          end

                          -- Check 3: Friendly Fire LOS (Is Master in front of me?)
                          local toTarget = (tRoot.Position - myRoot.Position).Unit
                          local toMaster = (mRoot.Position - myRoot.Position).Unit
                          local distToMaster = (mRoot.Position - myRoot.Position).Magnitude
                          local distToTarget = (tRoot.Position - myRoot.Position).Magnitude
                          
                          if distToMaster < distToTarget then
                               local dot = toTarget:Dot(toMaster)
                               if dot > 0.5 then -- Cone check
                                   safeToAttack = false
                                   myHum:MoveTo(myRoot.Position + myRoot.CFrame.RightVector * 5)
                               end
                          end
                      end
                 end
             end
             
             -- 3. Chase & Attack
             -- 3. Chase & Attack
             if tool and safeToAttack then
                  if Config.UseVirtualClick then
                      pcall(function()
                          local VirtualUser = game:GetService("VirtualUser")
                          VirtualUser:Button1Down(Vector2.new(0,0))
                          task.delay(0.1, function() VirtualUser:Button1Up(Vector2.new(0,0)) end)
                      end)
                  else
                      tool:Activate()
                  end
             end
             
             -- Aim & Move
             if safeToAttack then
                 -- FREEZE ROTATION CONTROL
                 myHum.AutoRotate = false
                 
                 -- Look at Target (Horizontal Only)
                 local lookPos = Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
                 myRoot.CFrame = CFrame.lookAt(myRoot.Position, lookPos)
                 
                 myHum:MoveTo(tRoot.Position)
             else
                 myHum.AutoRotate = true 
             end

             -- --- SAFETY CHECK ---
             local flingDuration = tick() - flingStartTime
             
             if flingDuration > 0.5 then
                 -- Void Check (Relative)
                 local currentY = myRoot.Position.Y
                 local fallenDist = (flingStartHeight or currentY) - currentY
                 
                 if fallenDist > 50 then
                     warn("[BotSafety] Void/Fall Detected! Returning.")
                     TeleportReturn()
                     return
                 end

                 -- Death Check
                 if tHum and tHum.Health <= 0 then
                     warn("[BotAttack] Target Eliminated. Returning.")
                     TeleportReturn()
                     return
                 end
             end
             
             -- [TIMEOUT]
             if flingDuration > 8 then -- Give it more time (8s) to land a hit
                 warn("[BotAttack] Timeout (8s). Returning.")
                 TeleportReturn()
             end
             
             -- lastTargetPos is NOT updated here, to measure from START of fling.

             -- [FEATURE: DYNAMIC DEFENSE SWITCHING]
             -- (Removed: Now handled by Check 2 inside the main logic above)

             -- [FEATURE: MASTER SAFETY TP]
             -- If I get too close to Master while flinging, TP BEHIND Master (4 studs)
             if currentTargetName and currentTargetName ~= "Nenhum" then
                  local master = Players:FindFirstChild(currentTargetName)
                  if master and master.Character then
                       local mRoot = getRoot(master.Character)
                       if mRoot then
                           local distToMaster = (mRoot.Position - myRoot.Position).Magnitude
                           -- "Segurança de 2 studs" -> trigger. Actually using FlingSafeDistance config or hardcoded 3
                           local safeDist = Config.FlingSafeDistance or 2
                           if distToMaster < safeDist then
                                warn("[BotSafety] Too close to Master! Teleporting behind.")
                                -- TP 4 studs behind Master
                                myRoot.CFrame = mRoot.CFrame * CFrame.new(0, 0, 4)
                                myRoot.AssemblyLinearVelocity = Vector3.zero
                                myRoot.AssemblyAngularVelocity = Vector3.zero
                                -- Reset state slightly to re-orient
                                return
                           end
                       end
                  end
             end

             -- [FEATURE: STATIONARY FLING]
             -- If target is stationary > 2s, TP Inside + Random Push
             local targetSpeed = tRoot.AssemblyLinearVelocity.Magnitude
             if targetSpeed < 2 then
                  if not stationaryStartTime or stationaryStartTime == 0 then
                      stationaryStartTime = tick()
                  elseif tick() - stationaryStartTime > 2 then
                       -- TRIGGER STATIC FLING
                       -- 1. TP Inside
                       myRoot.CFrame = tRoot.CFrame -- Exact overlap
                       
                       -- 2. Random Push/Touch (Oscillate)
                       local randomOffset = Vector3.new(math.random()-0.5, 0, math.random()-0.5) * 1.5
                       myHum:MoveTo(tRoot.Position + randomOffset)
                  end
             else
                  stationaryStartTime = 0
             end

        -- [STATE: RANGED COMBAT]
        elseif currentFlingState == "RANGED" then
             local targetChar = nil
             if activeFlingTarget then
                 if activeFlingTarget:IsA("Player") then targetChar = activeFlingTarget.Character
                 elseif activeFlingTarget:IsA("Model") then targetChar = activeFlingTarget end
             end
             
             if not targetChar then
                 currentFlingState = FlingState.RETURNING
                 return
             end
             
             local tRoot = getRoot(targetChar)
             local tHum = getHumanoid(targetChar)
             if not tRoot or not tHum or tHum.Health <= 0 then
                 currentFlingState = FlingState.RETURNING
                 return
             end
             
             -- 1. Equip Weapon
             -- 1. Equip Weapon (Priority)
             local tool = BotCore:GetPriorityWeapon(myChar)
             if tool and tool.Parent ~= myChar then
                 myHum:EquipTool(tool)
             end
             
             -- 2. Movement: Stay near Master (Orbit/Follow)
             -- Unlike Melee, we do NOT chase the target. We flank the Master.
             if currentTargetName and currentTargetName ~= "Nenhum" then
                 local master = Players:FindFirstChild(currentTargetName)
                 if master and master.Character then
                     local mRoot = getRoot(master.Character)
                     if mRoot then
                         -- CHECK SWITCHING
                          local bestThreat = BotCore:ScanForThreats(mRoot)
                          if bestThreat and bestThreat.Object ~= activeFlingTarget and bestThreat.Character then
                               local dNew = (bestThreat.Character:FindFirstChild("HumanoidRootPart").Position - mRoot.Position).Magnitude
                               local dCurr = (tRoot.Position - mRoot.Position).Magnitude
                               
                               if dNew < (dCurr - 5) then -- 5 Stud Hysteresis
                                    warn("[BotRanged] Switching to closer threat: " .. bestThreat.Name)
                                    activeFlingTarget = bestThreat.Object
                                    return 
                               end
                          end

                         -- Move to Master + Offset
                         local distToMaster = (mRoot.Position - myRoot.Position).Magnitude
                         if distToMaster > 10 then
                             myHum:MoveTo(mRoot.Position)
                         elseif distToMaster < 4 then
                              myHum:MoveTo(myRoot.Position + (myRoot.Position - mRoot.Position).Unit * 2)
                         end
                     end
                 end
             end
             
             -- 3. Aim & Attack
             -- Force Look at Target
             myHum.AutoRotate = false
             local lookPos = Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
             myRoot.CFrame = CFrame.lookAt(myRoot.Position, lookPos)
             
             -- Master Safety (LOS Check)
             local safeToShoot = true
             if currentTargetName and currentTargetName ~= "Nenhum" then
                 local master = Players:FindFirstChild(currentTargetName)
                 if master and master.Character then
                      local mRoot = getRoot(master.Character)
                      if mRoot then
                           -- Check if Master is in front of us
                           local toMaster = (mRoot.Position - myRoot.Position).Unit
                           local lookDir = myRoot.CFrame.LookVector
                           local dot = lookDir:Dot(toMaster)
                           
                           local distM = (mRoot.Position - myRoot.Position).Magnitude
                           local distE = (tRoot.Position - myRoot.Position).Magnitude
                           
                           -- If Master is in front (cone > 0.5 ~ 60deg) AND closer than enemy
                           if dot > 0.5 and distM < distE then
                               safeToShoot = false
                               safeToAttack = false
                           end
                      end
                 end
             end
             
             if safeToAttack and tool then
                  if Config.UseVirtualClick then
                      pcall(function()
                          local VirtualUser = game:GetService("VirtualUser")
                          VirtualUser:Button1Down(Vector2.new(0,0))
                          task.delay(0.1, function() VirtualUser:Button1Up(Vector2.new(0,0)) end)
                      end)
                  else
                      tool:Activate()
                  end
             end

        -- [STATE: RETURNING] Fly back (Fallback / Deprecated by TP)
        elseif currentFlingState == FlingState.RETURNING then
             -- Re-enable AutoRotate
             myHum.AutoRotate = true
             -- We can keep this as a failsafe, or just TP. Let's TP for consistency.
             local targetPlr = Players:FindFirstChild(currentTargetName)
             local ownerRoot = nil
             if targetPlr and targetPlr.Character then ownerRoot = getRoot(targetPlr.Character) end
             
             if ownerRoot then
                 myRoot.CFrame = ownerRoot.CFrame * CFrame.new(0, 0, 5)
             end
             
             currentFlingState = FlingState.IDLE
             ResetPhysics()
             currentFlingState = FlingState.IDLE
             ResetPhysics()
             myHum.PlatformStand = false
             myHum:UnequipTools() -- Holster on Return
        end
    end



    function BotCore:SetVisionRadius(rad)
        Config.VisionRadius = rad
        warn("[BotConfig] Vision Radius: " .. rad)
    end
    
    function BotCore:AddFlingTarget(name)
        FlingTargets[name] = true
        warn("[BotFling] Added Target: " .. name)
    end
    
    function BotCore:RemoveFlingTarget(name)
        FlingTargets[name] = nil
        warn("[BotFling] Removed Target: " .. name)
    end

    function BotCore:GetFlingTargets() return FlingTargets end

    function BotCore:SetDistances(min, max)
        Config.MinDistance = min
        Config.MaxDistance = max
        warn("[BotConfig] Distances updated: Min="..min.." Max="..max)
    end

    function BotCore:SetTeleportDistance(dist)
        Config.TeleportDistance = dist
        warn("[BotConfig] Teleport distance set to: " .. dist)
    end
    
    function BotCore:GetDistances()
        return Config.MinDistance, Config.MaxDistance
    end

    function BotCore:SetTarget(name)
        if currentTargetName ~= name then
            warn("[BotDebug] New Target: " .. tostring(name))
            currentTargetName = name
            currentWaypoints = nil
            currentWaypointIndex = 0
            wanderingTarget = nil -- Reset wander
        end
    end

    local function CheckLoop()
        if isFollowEnabled or isFlingEnabled then
            if not loopConnection then
                warn("[BotDebug] Starting loop...")
                loopConnection = RunService.Heartbeat:Connect(UpdateBot)
            end
        else
            if loopConnection then
                warn("[BotDebug] Stopping loop...")
                loopConnection:Disconnect()
                loopConnection = nil
            end
            local char = LocalPlayer.Character
            if char and getHumanoid(char) then
                 getHumanoid(char):MoveTo(char.HumanoidRootPart.Position)
            end
        end
    end

    function BotCore:AddTargetNPC(name)
        if name and name ~= "" then ActiveTargetNPCs[name] = true; warn("NPC Added: "..name) end
    end
    
    function BotCore:RemoveTargetNPC(name)
        if name then ActiveTargetNPCs[name] = nil; warn("NPC Removed: "..name) end
    end
    
    function BotCore:GetNPCList()
        local list = {}
        for name, _ in pairs(ActiveTargetNPCs) do table.insert(list, name) end
        return list
    end

    function BotCore:SetFollowEnabled(state)
        warn("[BotDebug] Follow Enabled: " .. tostring(state))
        isFollowEnabled = state
        CheckLoop()
    end

    function BotCore:SetFlingEnabled(state)
        warn("[BotDebug] Fling Enabled: " .. tostring(state))
        isFlingEnabled = state
        isFlingEnabled = state
        CheckLoop()
    end

    function BotCore:SetDefenseEnabled(state)
        warn("[BotDebug] Defense Enabled: " .. tostring(state))
        isDefenseEnabled = state
        CheckLoop()
    end
    
    function BotCore:SetMeleeEnabled(state)
        warn("[BotDebug] Melee Enabled: " .. tostring(state))
        isMeleeEnabled = state
        CheckLoop()
    end
    
    function BotCore:SetRangedEnabled(state)
        warn("[BotDebug] Ranged Enabled: " .. tostring(state))
        isRangedEnabled = state
        CheckLoop()
    end
    
    function BotCore:SetRangedDistance(dist)
        Config.RangedDistance = dist
        warn("[BotConfig] Ranged Distance: " .. dist)
    end
    
    function BotCore:SetDefenseTeamCheck(state)
        DefenseConfig.TeamCheck = state
        warn("[BotConfig] Defense TeamCheck: " .. tostring(state))
    end
    
    function BotCore:AddDefenseIgnore(name)
        DefenseConfig.IgnoreList[name] = true
        warn("[BotConfig] Defense Ignore Added: " .. name)
    end
    
    function BotCore:RemoveDefenseIgnore(name)
        DefenseConfig.IgnoreList[name] = nil
        warn("[BotConfig] Defense Ignore Removed: " .. name)
    end

    function BotCore:SetFlingSafeDistance(dist)
        Config.FlingSafeDistance = dist
        warn("[BotConfig] Fling Safe Distance: " .. dist)
    end
    
    function BotCore:SetDefenseRadius(dist)
        Config.DefenseRadius = dist
        warn("[BotConfig] Defense Radius: " .. dist)
    end
    
    function BotCore:SetMeleeTriggerDistance(dist)
        Config.MeleeTriggerDistance = dist
        warn("[BotConfig] Melee Trigger Dist: " .. dist)
    end
    
    function BotCore:SetDefenseSafeZone(dist)
        Config.DefenseSafeZone = dist
        warn("[BotConfig] Defense Safe Zone: " .. dist)
    end

    function BotCore:SetEnabled(state)
        -- Redirect legacy calls to Follow logic
        -- This ensures "Seguir Player" behavior is preserved if called via old methods
        self:SetFollowEnabled(state)
    end

    -- [HELPER: WEAPON & CLICK]
    function BotCore:GetPriorityWeapon(char)
        if not char then return nil end
        local inv = LocalPlayer.Backpack:GetChildren()
        local equipped = char:FindFirstChildOfClass("Tool")
        
        -- Merge inventory for search
        local candidates = {}
        if equipped then table.insert(candidates, equipped) end
        for _, t in pairs(inv) do if t:IsA("Tool") then table.insert(candidates, t) end end
        
        -- Order Check
        for _, name in pairs(WeaponPriority) do
            for _, t in pairs(candidates) do
                if t.Name == name then return t end
            end
        end
        
        -- Fallback: Equipped or First in bag
        return equipped or candidates[1]
    end
    
    function BotCore:AddWeaponPriority(name)
        -- check dupe
        for _, v in pairs(WeaponPriority) do if v == name then return end end
        table.insert(WeaponPriority, name)
        warn("[BotConfig] Added Weapon Priority: " .. name)
    end
    
    function BotCore:RemoveWeaponPriority(name)
        for i, v in pairs(WeaponPriority) do 
            if v == name then 
                table.remove(WeaponPriority, i) 
                warn("[BotConfig] Removed Weapon Priority: " .. name)
                return
            end 
        end
    end
    
    function BotCore:GetWeaponStartList()
        return WeaponPriority
    end
    
    function BotCore:SetVirtualClick(state)
        Config.UseVirtualClick = state
        warn("[BotConfig] Virtual Click: " .. tostring(state))
    end



    return BotCore
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
    end

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
local Combat = Win:Tab("Combate")


local AimbotGroup = Combat:Group("Aimbot Principal")
local aimbotDependents = {} -- Store dependent frames

local aimbotToggle = AimbotGroup:Toggle("Ativar Aimbot", AimbotCore:IsEnabled(), function(v)
    AimbotCore:SetEnabled(v)
    -- Toggle visibility of dependents
    if v then
        task.wait(0.3) -- Wait for expansion animation
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

local function GetTeamsList()
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

local ignoreTeamList = AimbotGroup:InteractiveList("Ignorar Time", GetTeamsList, function(name)
    AimbotCore:IgnoreTeam(name)
end, function(name)
    AimbotCore:UnignoreTeam(name)
end)
table.insert(aimbotDependents, ignoreTeamList)

local fovS = AimbotGroup:Slider("Campo de Visão (FOV)", 20, 500, AimbotCore:GetFOV(), function(v)
    AimbotCore:SetFOV(v)
end)
table.insert(aimbotDependents, fovS)

local easingS = AimbotGroup:Slider("Suavização (Easing)", 1, 10, math.floor(getgenv().AimbotEasing * 10), function(v)
    getgenv().AimbotEasing = v / 10 
end)
table.insert(aimbotDependents, easingS)

-- Initialize visibility based on default state
local isAimbotEnabled = AimbotCore:IsEnabled()
for _, frame in pairs(aimbotDependents) do
    frame.Visible = isAimbotEnabled
end

local KillAuraGroup = Combat:Group("Kill Aura")
local killAuraToggle = KillAuraGroup:Toggle("Kill Player(s)", KillAuraCore:IsEnabled(), function(v)
    KillAuraCore:SetEnabled(v)
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
    KillAuraCore:SetTargetMode(val)
end)

-- Auto Update Dropdown
task.spawn(function()
    while task.wait(5) do
        -- Only refresh if menu is visible? Optimization.
        -- But user might verify while opening.
        TargetDrop:Refresh(GetPlayersList())
    end
end)
game:GetService("Players").PlayerAdded:Connect(function() TargetDrop:Refresh(GetPlayersList()) end)
game:GetService("Players").PlayerRemoving:Connect(function() TargetDrop:Refresh(GetPlayersList()) end)

local function GetTeamsList()
    local list = {"Nada"}
    for _, t in pairs(game:GetService("Teams"):GetTeams()) do
        table.insert(list, t.Name)
    end
    return list
end

local TeamDrop = KillAuraGroup:Dropdown("Time Kill", GetTeamsList(), "Nada", function(val)
    KillAuraCore:SetTeamTarget(val)
end)

game:GetService("Teams").ChildAdded:Connect(function() TeamDrop:Refresh(GetTeamsList()) end)
game:GetService("Teams").ChildRemoved:Connect(function() TeamDrop:Refresh(GetTeamsList()) end)

-- >>> TAB: VISUAL
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

local nameToggle = ESPGroup:Toggle("Mostrar Nomes", getgenv().ESPNames, function(v)
    getgenv().ESPNames = v
end)
table.insert(espDependents, nameToggle.Frame)

local healthToggle = ESPGroup:Toggle("Barra de Vida", getgenv().ESPHealth, function(v)
    getgenv().ESPHealth = v
end)
table.insert(espDependents, healthToggle.Frame)

local tracerToggle = ESPGroup:Toggle("Linhas (Tracers)", getgenv().ESPTracers, function(v)
    getgenv().ESPTracers = v
end)
table.insert(espDependents, tracerToggle.Frame)

-- Initialize visibility based on default state
local isESPEnabled = ESPCore:IsEnabled()
for _, frame in pairs(espDependents) do
    frame.Visible = isESPEnabled
end

local HeadGroup = Visual:Group("Cabeças (Headshot)")
local headToggle = HeadGroup:Toggle("Expandir Cabeças", HeadESP:IsEnabled(), function(v)
    HeadESP:SetEnabled(v)
end)
HeadGroup:Slider("Tamanho", 1, 20, HeadESP:GetHeadSize(), function(v)
    HeadESP:SetHeadSize(v)
end)

-- >>> TAB: LOCAL PLAYER
local Local = Win:Tab("Local")
local CharGroup = Local:Group("Personagem")
local respawnToggle = CharGroup:Toggle("Respawn Onde Morreu", RespawnCore:IsEnabled(), function(v)
    RespawnCore:SetEnabled(v)
end)

local UtilityGroup = Local:Group("Utilidades")
UtilityGroup:Bind("Tecla Soltar Cursor", getgenv().UnlockMouseKey, function(key)
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
local startTime = os.time() -- Track when script started (or when AFK enabled? User asked "since script executed")
-- Actually user said "since when you executed the script". So startTime is static global.
-- Let's define it global if not present, or just use this local one which is effectively global for this module scope.

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

-- >>> TAB: PRE-CONFIGS (BotMe)
local BotMe = Win:Tab("BotMe")

-- 1. GROUP: GERENCIAMENTO (First)
local BotGroup = BotMe:Group("Gerenciamento de Bot")

local function GetPlayersList()
    local list = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            table.insert(list, v.Name)
        end
    end
    return list
end

local botTargetDropdown = BotGroup:Dropdown("Alvo (Seguir)", {"Nenhum"}, "Nenhum", function(v)
    warn("[UI] Dropdown selected: " .. tostring(v))
    BotCore:SetTarget(v)
end)

-- Auto-update Dropdown
task.spawn(function()
    while task.wait(5) do
        botTargetDropdown:Refresh(GetPlayersList())
    end
end)

BotGroup:Toggle("Ativar Seguir", false, function(v)
    BotCore:SetFollowEnabled(v)
end)

BotGroup:Slider("Distância (Min/Max)", 1, 20, 10, function(v)
    BotCore:SetDistances(v, v+5)
end, function(v) return v .. "/" .. (v+5) end)

BotGroup:Slider("Teleporte (Max Dist)", 30, 500, 120, function(v)
    BotCore:SetTeleportDistance(v)
end)

    BotCore:SetVisionRadius(v)
end)

BotGroup:Slider("Raio de Ataque (Defesa)", 10, 150, 40, function(v)
    BotCore:SetDefenseRadius(v)
end)

BotGroup:Slider("Distância Segura (Fling)", 1, 50, 3, function(v)
    BotCore:SetFlingSafeDistance(v)
end)

BotGroup:Slider("Zona Segura (Mestre)", 1, 50, 20, function(v)
    BotCore:SetDefenseSafeZone(v)
end)

BotGroup:Toggle("Modo Defesa (Auto)", false, function(v)
    BotCore:SetDefenseEnabled(v)
end)

BotGroup:Toggle("Ignorar Aliados (Defesa do Bot)", false, function(v)
    BotCore:SetDefenseTeamCheck(v)
end)

BotGroup:InteractiveList("Ignorar Players (Defesa)", GetPlayersList, function(name)
    BotCore:AddDefenseIgnore(name)
end, function(name)
    BotCore:RemoveDefenseIgnore(name)
end)

BotGroup:InteractiveList("Alvo(s) Fling", GetPlayersList, function(name)
    BotCore:AddFlingTarget(name)
end, function(name)
    BotCore:RemoveFlingTarget(name)
end)

-- 1.5 GROUP: COMBATE (New)
local CombatGroup = BotMe:Group("Modo Combate (Melee)")

CombatGroup:Toggle("Ativar Combate (Auto)", false, function(v)
    BotCore:SetMeleeEnabled(v)
end)

local npcInputName = ""
CombatGroup:Input("Nome do NPC (Workspace)", function(text)
    npcInputName = text
end)

CombatGroup:Button("Adicionar NPC", function()
    BotCore:AddTargetNPC(npcInputName)
end)

CombatGroup:Button("Remover NPC", function()
    BotCore:RemoveTargetNPC(npcInputName)
end)

local function GetNPCListFunc()
   return BotCore:GetNPCList()
end

CombatGroup:InteractiveList("NPCs Alvos Ativos", GetNPCListFunc, function(name)
   -- On Click (maybe remove?)
   BotCore:RemoveTargetNPC(name)
end, function(name)
   BotCore:RemoveTargetNPC(name)
end)

-- 1.6 GROUP: RANGED COMBAT (New)
local RangedGroup = BotMe:Group("Modo Combate (Ranged)")

RangedGroup:Toggle("Ativar Longa Distância", false, function(v)
    BotCore:SetRangedEnabled(v)
end)

RangedGroup:Slider("Distância de Tiro", 20, 300, 100, function(v)
    BotCore:SetRangedDistance(v)
end)

CombatGroup:Slider("Distância Gatilho Melee", 5, 50, 20, function(v)
    BotCore:SetMeleeTriggerDistance(v)
end)

-- 1.7 GROUP: ARMAS E PRIORIDADE (New)
local WeaponGroup = BotMe:Group("Armas e Prioridade")

WeaponGroup:Input("Nome da Arma", function(text)
    BotCore:AddWeaponPriority(text)
end)

WeaponGroup:InteractiveList("Lista Prioridade", function() return BotCore:GetWeaponStartList() end, function(name)
    BotCore:AddWeaponPriority(name) -- Usually redundant but keeps list flow
end, function(name)
    BotCore:RemoveWeaponPriority(name)
end)

WeaponGroup:Toggle("Ativar Clique Virtual", false, function(v)
    BotCore:SetVirtualClick(v)
end)



-- 2. GROUP: BOTS (Second)
local BotsGroup = BotMe:Group("Bots")

BotsGroup:Toggle("Seguir Player", false, function(v)
    BotCore:SetFollowEnabled(v)
end)

BotsGroup:Toggle("Missel player(fling)", false, function(v)
    BotCore:SetFlingEnabled(v)
end)


-- >>> TAB: CONFIGURAÇÕES
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
            -- Update Controls (Visual + Logic)
            aimbotToggle.Set(config.aimbot)
            tCheckToggle.Set(config.teamCheck)
            legitToggle.Set(config.legitMode or false)
            killAuraToggle.Set(config.killAura or false)
            
            espToggle.Set(config.esp)
            nameToggle.Set(config.espNames or false)
            tracerToggle.Set(config.espTracers or false)
            healthToggle.Set(config.espHealth or false)
            
            headToggle.Set(config.headEsp)
            
            respawnToggle.Set(config.respawn)
            
            AimbotCore:SetFOV(config.fov)
            HeadESP:SetHeadSize(config.headSize)
            
            if config.unlockKey then getgenv().UnlockMouseKey = Enum.KeyCode[config.unlockKey] end
            Notify("Configurações carregadas!")
        end
    else
        Notify("Nenhum save encontrado")
    end
end)

local InfoGroup = Settings:Group("Informações")
InfoGroup:Button("Criado por DreeZy", function() setclipboard("DreeZy") end)

Notify("DreeZy Voidware V2 Carregado!")
Notify("Use [Right Shift] para abrir/fechar o Menu!")
