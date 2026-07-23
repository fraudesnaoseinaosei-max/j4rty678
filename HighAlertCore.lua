-- HighAlertCore.lua
-- Sistema de Alerta Direcional nas Bordas + Seta Centro (Estilo COD Warzone "High Alert" Perk)
-- Pulsa bordas da tela quando um inimigo está olhando para você com linha de visão
-- Seta direcional no centro da tela que aponta para o inimigo
-- Cor por distância: Verde (longe) > Amarelo (médio) > Vermelho (perto)
-- Direção real: mostra em qual borda/seta da tela o inimigo está
-- Compatível com Velocity, Synapse, Script-Ware, Krnl, etc.

assert(Drawing, 'Drawing API required')

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HighAlertCore = {}
local isEnabled = false
local teamCheckEnabled = true

-- ============================================
-- CONFIG
-- ============================================
local DIST_CLOSE = 50       -- Vermelho: < 50 studs
local DIST_MEDIUM = 100     -- Amarelo: 50-100 studs
-- Verde: > 100 studs
local LOOK_THRESHOLD = 0.82 -- cos(~35°) - cone de visão do inimigo
local BORDER_THICKNESS = 18 -- Espessura da borda pulsante (pixels) - Ajustável
local PULSE_SPEED = 4       -- Velocidade do pulso
local MAX_ALPHA = 0.85      -- Transparência máxima do pulso
local MIN_ALPHA = 0.15      -- Transparência mínima do pulso

-- Cores por distância
local COLOR_CLOSE  = Color3.fromRGB(255, 50, 50)    -- Vermelho
local COLOR_MEDIUM = Color3.fromRGB(255, 200, 0)     -- Amarelo
local COLOR_FAR    = Color3.fromRGB(50, 255, 100)    -- Verde

-- ============================================
-- DRAWING OBJECTS (4 bordas)
-- ============================================
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
local arrowEnabled = false
local ARROW_RADIUS = 90   -- Distância do centro da tela
local ARROW_SIZE = 22      -- Tamanho do chevron
local MAX_ARROWS = 10

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

    if not result then return true end

    local hitDist = (result.Position - fromPos).Magnitude
    local totalDist = direction.Magnitude

    if totalDist - hitDist < 5 then return true end

    return false
end

local function GetThreatBorder(myRoot, myCF, enemyPos)
    local toEnemy = (enemyPos - myRoot.Position)
    local localDir = myCF:VectorToObjectSpace(toEnemy).Unit

    local absX = math.abs(localDir.X)
    local absZ = math.abs(localDir.Z)

    local activeBorders = {}

    if absX > 0.3 then
        if localDir.X > 0 then
            table.insert(activeBorders, "Right")
        else
            table.insert(activeBorders, "Left")
        end
    end

    if absZ > 0.3 then
        if localDir.Z > 0 then
            table.insert(activeBorders, "Bottom")
        else
            table.insert(activeBorders, "Top")
        end
    end

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

    -- Reset
    for _, name in ipairs(borderNames) do
        borderState[name].active = false
        borderState[name].distance = 9999
    end
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

        local enemyLookVector = enemyCF.LookVector
        local enemyToMe = (myPos - enemyPos).Unit
        local lookDot = enemyLookVector:Dot(enemyToMe)

        if lookDot < LOOK_THRESHOLD then continue end

        local ignoreList = {character}
        if myChar then table.insert(ignoreList, myChar) end

        local eyePos = enemyHead and (enemyHead.Position + Vector3.new(0, 0.5, 0)) or enemyPos
        if not HasLineOfSight(eyePos, myPos, ignoreList) then continue end

        -- Bordas
        if isEnabled then
            local activeBorders = GetThreatBorder(myRoot, myCF, enemyPos)
            local color = GetColorByDistance(distance)
            for _, borderName in ipairs(activeBorders) do
                local state = borderState[borderName]
                state.active = true
                if distance < state.distance then
                    state.distance = distance
                    state.color = color
                end
            end
        end

        -- Setas
        if arrowEnabled and #detectedThreats < MAX_ARROWS then
            local toEnemy = (enemyPos - myPos)
            local localDir = myCF:VectorToObjectSpace(toEnemy).Unit
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
    local pulseFactor = (math.sin(pulseTime) + 1) / 2
    local currentAlpha = MIN_ALPHA + (MAX_ALPHA - MIN_ALPHA) * pulseFactor

    for _, name in ipairs(borderNames) do
        local state = borderState[name]
        local rect = borders[name]

        if state.active then
            rect.Visible = true
            rect.Color = state.color
            rect.Transparency = currentAlpha

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
            local screenAngle = threat.angle

            local cx = screenCenter.X + math.sin(screenAngle) * ARROW_RADIUS
            local cy = screenCenter.Y + math.cos(screenAngle) * ARROW_RADIUS

            local halfSize = ARROW_SIZE / 2

            local outDirX = math.sin(screenAngle)
            local outDirY = math.cos(screenAngle)

            local tipX = cx + outDirX * halfSize * 0.5
            local tipY = cy + outDirY * halfSize * 0.5

            local perpX = -outDirY
            local perpY = outDirX

            local backX = cx - outDirX * halfSize * 0.5
            local backY = cy - outDirY * halfSize * 0.5

            local arm1EndX = backX + perpX * halfSize * 0.6
            local arm1EndY = backY + perpY * halfSize * 0.6

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
function HighAlertCore:SetEnabled(enabled)
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

function HighAlertCore:IsEnabled()
    return isEnabled
end

function HighAlertCore:SetArrowEnabled(enabled)
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

function HighAlertCore:IsArrowEnabled()
    return arrowEnabled
end

function HighAlertCore:SetArrowRadius(value)
    ARROW_RADIUS = math.clamp(value, 30, 300)
    if getgenv then getgenv().HighAlertArrowRadius = ARROW_RADIUS end
end

function HighAlertCore:GetArrowRadius()
    return ARROW_RADIUS
end

function HighAlertCore:SetArrowSize(value)
    ARROW_SIZE = math.clamp(value, 8, 50)
    if getgenv then getgenv().HighAlertArrowSize = ARROW_SIZE end
end

function HighAlertCore:GetArrowSize()
    return ARROW_SIZE
end

function HighAlertCore:SetTeamCheck(enabled)
    teamCheckEnabled = enabled
    if getgenv then getgenv().HighAlertTeamCheck = enabled end
end

function HighAlertCore:IsTeamCheck()
    return teamCheckEnabled
end

function HighAlertCore:SetBorderThickness(value)
    BORDER_THICKNESS = math.clamp(value, 3, 50)
    if getgenv then getgenv().HighAlertThickness = BORDER_THICKNESS end
end

function HighAlertCore:GetBorderThickness()
    return BORDER_THICKNESS
end

function HighAlertCore:Destroy()
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
    arrowEnabled = getgenv().HighAlertArrowEnabled or false
    ARROW_RADIUS = getgenv().HighAlertArrowRadius or 90
    ARROW_SIZE = getgenv().HighAlertArrowSize or 22
else
    isEnabled = false
    teamCheckEnabled = true
    arrowEnabled = false
end

RunService.RenderStepped:Connect(function(dt)
    UpdateHighAlert(dt)
end)

return HighAlertCore
