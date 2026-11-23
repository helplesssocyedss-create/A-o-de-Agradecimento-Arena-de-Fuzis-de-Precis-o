--[[
    TALES MOD MENU
    Feito por Tales
    LocalScript para uso no proprio jogo no Roblox Studio.

    AIMBOT: selecao de Cabeca/Peito.
    ESP: nomes e contorno para os jogadores.
    AIM FOV: circulo e selecao por distancia na tela.
    PERSEGUICAO: sensor de toque configuravel para o botao de mira.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BLUE = Color3.fromRGB(0, 170, 255)
local BLUE_OUTLINE = Color3.fromRGB(0, 200, 255)

local old = PlayerGui:FindFirstChild("TalesModMenu")
if old then old:Destroy() end

local Settings = {
    Aimbot = false,
    Target = nil,
    ESP = false,
    FOV = false,
    FOVSize = 120,

    Pursuit = false,
    PursuitActive = false,
    SensorLocked = true,
    SensorSize = 65,
    SensorPosition = UDim2.new(0.5, 0, 0.75, 0)
}

local CurrentTarget = nil
local ESPObjects = {}
local PlayerConnections = {}
local Camera = workspace.CurrentCamera

-- GUI PRINCIPAL

local GUI = Instance.new("ScreenGui")
GUI.Name = "TalesModMenu"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(460, 320)
Main.Position = UDim2.new(0.5, -230, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Main.BorderSizePixel = 0
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -55, 0, 45)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "TALES | MOD MENU"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 30)
Minimize.Position = UDim2.new(1, -42, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 22
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = Main
Instance.new("UICorner", Minimize)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 125, 1, -85)
Sidebar.Position = UDim2.fromOffset(10, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(29, 32, 43)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -150, 1, -85)
Content.Position = UDim2.fromOffset(140, 50)
Content.BackgroundColor3 = Color3.fromRGB(29, 32, 43)
Content.BorderSizePixel = 0
Content.Parent = Main
Instance.new("UICorner", Content)

local Tabs = {}
local TabButtons = {}

local function CreateTab(name)
    local page = Instance.new("Frame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Content

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 38)
    button.Position = UDim2.fromOffset(5, (#Tabs * 43) + 5)
    button.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = Sidebar
    Instance.new("UICorner", button)

    button.MouseButton1Click:Connect(function()
        for _, tab in ipairs(Tabs) do
            tab.Visible = false
        end

        for _, tabButton in ipairs(TabButtons) do
            tabButton.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
        end

        page.Visible = true
        button.BackgroundColor3 = Color3.fromRGB(25, 125, 75)
    end)

    table.insert(Tabs, page)
    table.insert(TabButtons, button)

    if #Tabs == 1 then
        page.Visible = true
        button.BackgroundColor3 = Color3.fromRGB(25, 125, 75)
    end

    return page
end

local function CreateToggle(parent, name, callback, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 38)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(75, 78, 90)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.Text = name .. " : OFF"
    button.Parent = parent
    Instance.new("UICorner", button)

    local enabled = false

    button.MouseButton1Click:Connect(function()
        enabled = not enabled

        button.Text = name .. (enabled and " : ON" or " : OFF")
        button.BackgroundColor3 = enabled
            and Color3.fromRGB(20, 170, 85)
            or Color3.fromRGB(75, 78, 90)

        callback(enabled)
    end)

    return button
end

local function CreateOption(parent, name, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(45, 95, 150)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    Instance.new("UICorner", button)

    button.MouseButton1Click:Connect(callback)

    return button
end

-- AIMBOT

local AimTab = CreateTab("AIMBOT")

local AimPrompt = Instance.new("TextLabel")
AimPrompt.Size = UDim2.new(1, -20, 0, 30)
AimPrompt.Position = UDim2.fromOffset(10, 62)
AimPrompt.BackgroundTransparency = 1
AimPrompt.Text = "Selecione a opcao desejada:"
AimPrompt.TextColor3 = Color3.new(1, 1, 1)
AimPrompt.TextSize = 13
AimPrompt.Font = Enum.Font.GothamBold
AimPrompt.Visible = false
AimPrompt.Parent = AimTab

local HeadOption
local ChestOption

local function SelectAimPart(partName)
    Settings.Target = partName
    AimPrompt.Text = "Selecionado: " .. partName
    HeadOption.Visible = false
    ChestOption.Visible = false
end

CreateToggle(AimTab, "AIMBOT", function(state)
    Settings.Aimbot = state
    CurrentTarget = nil

    if state then
        Settings.Target = nil
        AimPrompt.Text = "Selecione a opcao desejada:"
        AimPrompt.Visible = true
        HeadOption.Visible = true
        ChestOption.Visible = true
    else
        Settings.Target = nil
        AimPrompt.Visible = false
        HeadOption.Visible = false
        ChestOption.Visible = false
    end
end, 15)

HeadOption = CreateOption(AimTab, "AIMBOT CABECA", 100, function()
    SelectAimPart("Cabeca")
end)

ChestOption = CreateOption(AimTab, "AIMBOT PEITO", 145, function()
    SelectAimPart("Peito")
end)

HeadOption.Visible = false
ChestOption.Visible = false

-- ESP

local EspTab = CreateTab("ESP")

local function RemoveESP(target)
    local objects = ESPObjects[target]
    if not objects then return end

    if objects.Highlight then
        objects.Highlight:Destroy()
    end

    if objects.Billboard then
        objects.Billboard:Destroy()
    end

    ESPObjects[target] = nil
end

local function AddESP(target)
    if target == Player then return end

    local character = target.Character
    if not character or not character.Parent then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")

    if not humanoid or not head then return end

    local oldObjects = ESPObjects[target]

    if oldObjects
        and oldObjects.Character == character
        and oldObjects.Highlight
        and oldObjects.Highlight.Parent
        and oldObjects.Billboard
        and oldObjects.Billboard.Parent then
        return
    end

    RemoveESP(target)

    local highlight = Instance.new("Highlight")
    highlight.Name = "TalesESP"
    highlight.Adornee = character
    highlight.FillColor = BLUE
    highlight.OutlineColor = BLUE_OUTLINE
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TalesESPName"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(180, 30)
    billboard.StudsOffset = Vector3.new(0, 2.7, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = PlayerGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = target.DisplayName
    label.TextColor3 = BLUE_OUTLINE
    label.TextStrokeColor3 = Color3.fromRGB(0, 35, 90)
    label.TextStrokeTransparency = 0.15
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    ESPObjects[target] = {
        Character = character,
        Highlight = highlight,
        Billboard = billboard
    }
end

local function UpdateESP()
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            if Settings.ESP then
                AddESP(target)
            else
                RemoveESP(target)
            end
        end
    end

    for target in pairs(ESPObjects) do
        if target.Parent ~= Players then
            RemoveESP(target)
        end
    end
end

CreateToggle(EspTab, "ESP PLAYER", function(state)
    Settings.ESP = state

    if state then
        UpdateESP()
    else
        for target in pairs(ESPObjects) do
            RemoveESP(target)
        end
    end
end, 15)

local function TrackPlayer(target)
    if target == Player or PlayerConnections[target] then return end

    PlayerConnections[target] = target.CharacterAdded:Connect(function(character)
        if Settings.ESP then
            task.spawn(function()
                character:WaitForChild("Humanoid", 10)
                character:WaitForChild("Head", 10)

                if Settings.ESP and target.Parent == Players then
                    AddESP(target)
                end
            end)
        end
    end)

    if Settings.ESP then
        AddESP(target)
    end
end

for _, target in ipairs(Players:GetPlayers()) do
    TrackPlayer(target)
end

Players.PlayerAdded:Connect(TrackPlayer)

Players.PlayerRemoving:Connect(function(target)
    RemoveESP(target)

    if PlayerConnections[target] then
        PlayerConnections[target]:Disconnect()
        PlayerConnections[target] = nil
    end
end)

-- AIM FOV

local FovTab = CreateTab("AIM FOV")

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "TalesFOV"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(
    Settings.FOVSize * 2,
    Settings.FOVSize * 2
)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.Parent = GUI

Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 1.5
CircleStroke.Color = BLUE_OUTLINE
CircleStroke.Parent = FOVCircle

CreateToggle(FovTab, "AIM FOV", function(state)
    Settings.FOV = state
    FOVCircle.Visible = state

    if not state then
        CurrentTarget = nil
    end
end, 15)

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, -20, 0, 30)
SizeLabel.Position = UDim2.fromOffset(10, 65)
SizeLabel.BackgroundTransparency = 1
SizeLabel.TextColor3 = Color3.new(1, 1, 1)
SizeLabel.Text = "Tamanho: " .. Settings.FOVSize
SizeLabel.TextSize = 14
SizeLabel.Font = Enum.Font.GothamBold
SizeLabel.Parent = FovTab

local function ChangeFOV(amount)
    Settings.FOVSize = math.clamp(Settings.FOVSize + amount, 40, 300)

    FOVCircle.Size = UDim2.fromOffset(
        Settings.FOVSize * 2,
        Settings.FOVSize * 2
    )

    SizeLabel.Text = "Tamanho: " .. Settings.FOVSize
end

CreateOption(FovTab, "AUMENTAR +", 105, function()
    ChangeFOV(20)
end)

CreateOption(FovTab, "DIMINUIR -", 150, function()
    ChangeFOV(-20)
end)

-- PERSEGUICAO / SENSOR

local PursuitTab = CreateTab("PERSEGUICAO")

local Sensor = Instance.new("Frame")
Sensor.Name = "TalesAimSensor"
Sensor.AnchorPoint = Vector2.new(0.5, 0.5)
Sensor.Size = UDim2.fromOffset(
    Settings.SensorSize,
    Settings.SensorSize
)
Sensor.Position = Settings.SensorPosition
Sensor.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Sensor.BackgroundTransparency = 0.35
Sensor.BorderSizePixel = 0
Sensor.Active = false
Sensor.Visible = false
Sensor.ZIndex = 20
Sensor.Parent = GUI

Instance.new("UICorner", Sensor).CornerRadius = UDim.new(1, 0)

local SensorStroke = Instance.new("UIStroke")
SensorStroke.Color = Color3.new(1, 1, 1)
SensorStroke.Thickness = 2
SensorStroke.Parent = Sensor

local SensorText = Instance.new("TextLabel")
SensorText.Size = UDim2.fromScale(1, 1)
SensorText.BackgroundTransparency = 1
SensorText.Text = "MIRA"
SensorText.TextColor3 = Color3.new(1, 1, 1)
SensorText.TextSize = 12
SensorText.Font = Enum.Font.GothamBold
SensorText.ZIndex = 21
SensorText.Parent = Sensor

local PursuitStatus = Instance.new("TextLabel")
PursuitStatus.Size = UDim2.new(1, -20, 0, 35)
PursuitStatus.Position = UDim2.fromOffset(10, 62)
PursuitStatus.BackgroundTransparency = 1
PursuitStatus.Text = "Perseguicao: DESATIVADA"
PursuitStatus.TextColor3 = Color3.new(1, 1, 1)
PursuitStatus.TextSize = 13
PursuitStatus.Font = Enum.Font.GothamBold
PursuitStatus.Parent = PursuitTab

local SensorStatus = Instance.new("TextLabel")
SensorStatus.Size = UDim2.new(1, -20, 0, 30)
SensorStatus.Position = UDim2.fromOffset(10, 95)
SensorStatus.BackgroundTransparency = 1
SensorStatus.Text = "Sensor: TRAVADO"
SensorStatus.TextColor3 = Color3.new(1, 1, 1)
SensorStatus.TextSize = 12
SensorStatus.Font = Enum.Font.Gotham
SensorStatus.Parent = PursuitTab

local function UpdateSensor()
    Sensor.Size = UDim2.fromOffset(
        Settings.SensorSize,
        Settings.SensorSize
    )

    Sensor.Position = Settings.SensorPosition

    Sensor.Visible = Settings.Pursuit

    SensorText.Text = Settings.PursuitActive and "ON" or "MIRA"

    Sensor.BackgroundColor3 = Settings.PursuitActive
        and Color3.fromRGB(20, 190, 90)
        or Color3.fromRGB(0, 170, 255)

    PursuitStatus.Text = Settings.PursuitActive
        and "Perseguicao: ATIVA"
        or "Perseguicao: DESATIVADA"

    SensorStatus.Text = Settings.SensorLocked
        and "Sensor: TRAVADO"
        or "Sensor: DESTRAVADO"
end

CreateToggle(PursuitTab, "PERSEGUICAO", function(state)
    Settings.Pursuit = state

    if not state then
        Settings.PursuitActive = false
    end

    UpdateSensor()
end, 15)

CreateOption(PursuitTab, "TRAVAR / DESTRAVAR", 140, function()
    Settings.SensorLocked = not Settings.SensorLocked
    UpdateSensor()
end)

CreateOption(PursuitTab, "AUMENTAR BOLINHA +", 180, function()
    Settings.SensorSize = math.clamp(
        Settings.SensorSize + 10,
        35,
        150
    )
    UpdateSensor()
end)

CreateOption(PursuitTab, "DIMINUIR BOLINHA -", 220, function()
    Settings.SensorSize = math.clamp(
        Settings.SensorSize - 10,
        35,
        150
    )
    UpdateSensor()
end)

-- Sensor acompanha toques e cliques sem ser um botao ativo.
-- Com o sensor travado, toque dentro dele alterna a perseguicao.
-- Destravado, o toque permite arrastar a bolinha.

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil
local dragMoved = false

local function GetInputPosition(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

local function IsInsideSensor(position)
    local center = Sensor.AbsolutePosition + (Sensor.AbsoluteSize / 2)
    local half = Sensor.AbsoluteSize / 2

    return math.abs(position.X - center.X) <= half.X
        and math.abs(position.Y - center.Y) <= half.Y
end

local function SetSensorFromScreen(position)
    local viewport = workspace.CurrentCamera
        and workspace.CurrentCamera.ViewportSize

    if not viewport then return end

    local x = math.clamp(position.X / viewport.X, 0.03, 0.97)
    local y = math.clamp(position.Y / viewport.Y, 0.05, 0.95)

    Settings.SensorPosition = UDim2.new(x, 0, y, 0)
    Sensor.Position = Settings.SensorPosition
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not Settings.Pursuit then return end

    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    local isClick = input.UserInputType == Enum.UserInputType.MouseButton1

    if not isTouch and not isClick then return end

    local position = GetInputPosition(input)

    if not IsInsideSensor(position) then return end

    if Settings.SensorLocked then
        Settings.PursuitActive = not Settings.PursuitActive
        UpdateSensor()
    else
        dragging = true
        dragInput = input
        dragStart = position
        startPosition = Sensor.AbsolutePosition + (Sensor.AbsoluteSize / 2)
        dragMoved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    local isMouseMove =
        input.UserInputType == Enum.UserInputType.MouseMovement

    local isSameTouch = input == dragInput

    if not isMouseMove and not isSameTouch then return end

    local position = GetInputPosition(input)
    local delta = position - dragStart

    if delta.Magnitude > 5 then
        dragMoved = true
    end

    if dragMoved then
        SetSensorFromScreen(startPosition + delta)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == dragInput
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        dragInput = nil
        dragStart = nil
        startPosition = nil
    end
end)

-- SELECAO DE ALVO

local function GetTargetPart(character)
    if Settings.Target == "Cabeca" then
        return character:FindFirstChild("Head")
    elseif Settings.Target == "Peito" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestTarget()
    Camera = workspace.CurrentCamera

    if not Camera then return nil end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(
        viewport.X * 0.5,
        viewport.Y * 0.5
    )

    local maxDistance = Settings.FOV and Settings.FOVSize or 300
    local bestPlayer = nil
    local bestDistance = maxDistance

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            local character = target.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")

            local part = character and GetTargetPart(character)

            if humanoid and humanoid.Health > 0 and part then
                local point, onScreen =
                    Camera:WorldToViewportPoint(part.Position)

                if onScreen and point.Z > 0 then
                    local distance = (
                        Vector2.new(point.X, point.Y) - center
                    ).Magnitude

                    if distance <= bestDistance then
                        bestDistance = distance
                        bestPlayer = target
                    end
                end
            end
        end
    end

    return bestPlayer
end

-- VALORES PARA INTEGRACAO COM O SISTEMA DE ARMAS

local TargetValue = Instance.new("ObjectValue")
TargetValue.Name = "TalesCurrentTarget"
TargetValue.Parent = GUI

local TargetPartValue = Instance.new("StringValue")
TargetPartValue.Name = "TalesTargetPart"
TargetPartValue.Value = ""
TargetPartValue.Parent = GUI

local PursuitValue = Instance.new("BoolValue")
PursuitValue.Name = "TalesPursuitActive"
PursuitValue.Value = false
PursuitValue.Parent = GUI

-- ATUALIZACAO

local espTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    Camera = workspace.CurrentCamera

    if Camera then
        local viewport = Camera.ViewportSize

        FOVCircle.Position = UDim2.fromOffset(
            viewport.X * 0.5,
            viewport.Y * 0.5
        )
    end

    espTimer = espTimer + deltaTime

    if Settings.ESP and espTimer >= 0.5 then
        espTimer = 0
        UpdateESP()
    end

    local shouldSelectTarget =
        (Settings.Aimbot and Settings.FOV and Settings.Target ~= nil)
        or (Settings.Pursuit and Settings.PursuitActive)

    if shouldSelectTarget then
        CurrentTarget = GetClosestTarget()
    else
        CurrentTarget = nil
    end

    TargetValue.Value =
        CurrentTarget and CurrentTarget.Character or nil

    TargetPartValue.Value = Settings.Target or ""

    PursuitValue.Value =
        Settings.Pursuit and Settings.PursuitActive
end)

-- MINIMIZAR

local minimized = false

Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized

    Sidebar.Visible = not minimized
    Content.Visible = not minimized

    Main.Size = minimized
        and UDim2.fromOffset(460, 45)
        or UDim2.fromOffset(460, 320)

    Minimize.Text = minimized and "+" or "-"
end)

-- CREDITOS

local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 0, 20)
Credits.Position = UDim2.new(0, 0, 1, -23)
Credits.BackgroundTransparency = 1
Credits.Text = "Feito por Tales"
Credits.TextColor3 = Color3.fromRGB(130, 140, 160)
Credits.TextSize = 12
Credits.Font = Enum.Font.Gotham
Credits.Parent = Main

print("Tales Mod Menu carregado com sucesso!")
