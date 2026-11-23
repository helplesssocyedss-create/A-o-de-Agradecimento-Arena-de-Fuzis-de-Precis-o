--[[
    TALES MOD MENU - IA ASSIST
    Feito por Tales
    LocalScript para uso no proprio jogo, no Roblox Studio.

    ATUALIZACOES:
    - ESP PLAYER + ESP NAME.
    - ESP BOT/NPC + NOME.
    - Deteccao sem exigir a peca Head.
    - Recuperacao automatica de ESP apos respawn.
    - Aimbot procura jogadores e NPCs independentemente da ESP.
    - Mantida a assistencia original de camera.
    - Suavidade de 0% a 100%, passos de 5% ou 10%.
    - Selecao estavel de alvo.
    - FOV, perseguicao, IA Assist e minimizacao.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BLUE = Color3.fromRGB(0, 170, 255)
local BLUE_OUTLINE = Color3.fromRGB(0, 200, 255)
local PANEL = Color3.fromRGB(20, 22, 30)
local PANEL_INNER = Color3.fromRGB(29, 32, 43)

local old = PlayerGui:FindFirstChild("TalesModMenu")
if old then
    old:Destroy()
end

local Settings = {
    Aimbot = false,
    Target = nil,
    AimSmoothness = 0.20,
    SmoothStep = 5,

    ESPPlayers = false,
    ESPBots = false,

    FOV = false,
    FOVSize = 120,

    Pursuit = false,
    PursuitActive = false,
    SensorLocked = true,
    SensorSize = 65,
    SensorPosition = UDim2.new(0.5, 0, 0.75, 0),

    SmartRecovery = true,
    CivilProtection = true,
}

local CurrentTarget = nil
local ESPObjects = {}
local PlayerConnections = {}
local CachedNPCs = {}

local Camera = workspace.CurrentCamera
local IsCivil = false
local LastAIStatus = "AGUARDANDO"
local AIEventStatus = nil

local minimized = false
local draggingPanel = false

local function SetAIEvent(message)
    if AIEventStatus then
        AIEventStatus.Text = "Ultima deteccao: " .. tostring(message)
    end
end

local function IsAlive(character)
    if not character or not character.Parent then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    return humanoid ~= nil and humanoid.Health > 0
end

local function IsLocalPlayerCivil()
    local teamName = Player.Team
        and string.lower(Player.Team.Name)
        or ""

    local role = Player:GetAttribute("Role")
        or Player:GetAttribute("Class")
        or Player:GetAttribute("Job")
        or Player:GetAttribute("TeamRole")

    role = string.lower(tostring(role or ""))

    local combined = teamName .. " " .. role

    return string.find(combined, "civil") ~= nil
        or string.find(combined, "cidada") ~= nil
        or string.find(combined, "cidadão") ~= nil
end

local function CombatAllowed()
    return not (Settings.CivilProtection and IsCivil)
end

--==================================================
-- IDENTIFICACAO DE PERSONAGENS E NPCS
--==================================================

local function GetCharacter(target)
    if not target then
        return nil
    end

    if target:IsA("Player") then
        return target.Character
    end

    if target:IsA("Model") then
        return target
    end

    return nil
end

local function GetTargetName(target)
    if not target then
        return "nenhum"
    end

    if target:IsA("Player") then
        return target.DisplayName
    end

    if target:IsA("Model") then
        return target.Name
    end

    return "alvo"
end

local function GetCharacterAnchor(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character.PrimaryPart
        or character:FindFirstChildWhichIsA("BasePart", true)
end

local function IsPlayerCharacter(model)
    if not model then
        return false
    end

    return Players:GetPlayerFromCharacter(model) ~= nil
end

-- Atualiza a lista de NPCs/bots encontrados no Workspace.
local function RefreshNPCs()
    local found = {}

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") then
            local humanoid = object:FindFirstChildOfClass("Humanoid")

            if humanoid
                and humanoid.Health > 0
                and object ~= Player.Character
                and not IsPlayerCharacter(object) then

                local anchor = GetCharacterAnchor(object)

                if anchor then
                    found[object] = true
                end
            end
        end
    end

    local newList = {}

    for model in pairs(found) do
        table.insert(newList, model)
    end

    CachedNPCs = newList

    return newList
end

--==================================================
-- GUI PRINCIPAL
--==================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "TalesModMenu"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 50
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(460, 420)
Main.Position = UDim2.new(0.5, -230, 0.5, -210)
Main.BackgroundColor3 = PANEL
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
Sidebar.BackgroundColor3 = PANEL_INNER
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

Instance.new("UICorner", Sidebar)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -150, 1, -85)
Content.Position = UDim2.fromOffset(140, 50)
Content.BackgroundColor3 = PANEL_INNER
Content.BorderSizePixel = 0
Content.Parent = Main

Instance.new("UICorner", Content)

local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 0, 20)
Credits.Position = UDim2.new(0, 0, 1, -23)
Credits.BackgroundTransparency = 1
Credits.Text = "Feito por Tales"
Credits.TextColor3 = Color3.fromRGB(130, 140, 160)
Credits.TextSize = 12
Credits.Font = Enum.Font.Gotham
Credits.Parent = Main

-- Botao minimizado.

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "TalesMiniButton"
MiniButton.Size = UDim2.fromOffset(58, 58)
MiniButton.Position = UDim2.new(0.82, 0, 0.72, 0)
MiniButton.BackgroundColor3 = Color3.fromRGB(15, 115, 185)
MiniButton.Text = "T"
MiniButton.TextColor3 = Color3.new(1, 1, 1)
MiniButton.TextSize = 25
MiniButton.Font = Enum.Font.GothamBlack
MiniButton.Visible = false
MiniButton.Active = true
MiniButton.Parent = GUI
MiniButton.ZIndex = 100

Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(0, 17)

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = BLUE_OUTLINE
miniStroke.Thickness = 2
miniStroke.Parent = MiniButton

--==================================================
-- ELEMENTOS DA INTERFACE
--==================================================

local function CreateTab(name, index)
    local page = Instance.new("Frame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Content

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 38)
    button.Position = UDim2.fromOffset(5, ((index - 1) * 43) + 5)
    button.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = Sidebar

    Instance.new("UICorner", button)

    button.MouseButton1Click:Connect(function()
        for _, child in ipairs(Content:GetChildren()) do
            if child:IsA("Frame") then
                child.Visible = false
            end
        end

        for _, item in ipairs(Sidebar:GetChildren()) do
            if item:IsA("TextButton") then
                item.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
            end
        end

        page.Visible = true
        button.BackgroundColor3 = Color3.fromRGB(25, 125, 75)
    end)

    if index == 1 then
        page.Visible = true
        button.BackgroundColor3 = Color3.fromRGB(25, 125, 75)
    end

    return page
end

local function CreateToggle(parent, name, callback, y, initial)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 38)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(75, 78, 90)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    Instance.new("UICorner", button)

    local enabled = initial == true

    local function paint()
        button.Text = name .. (enabled and " : ON" or " : OFF")

        button.BackgroundColor3 = enabled
            and Color3.fromRGB(20, 150, 85)
            or Color3.fromRGB(75, 78, 90)
    end

    paint()

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        paint()
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
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    Instance.new("UICorner", button)

    button.MouseButton1Click:Connect(callback)

    return button
end

local function CreateInfo(parent, text, y, height)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, height or 34)
    label.Position = UDim2.fromOffset(10, y)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 12
    label.TextWrapped = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    return label
end

--==================================================
-- AIMBOT / ASSISTENCIA ORIGINAL
--==================================================

local AimTab = CreateTab("AIMBOT", 1)

local AimPrompt = CreateInfo(
    AimTab,
    "Ative a assistencia e escolha a parte do corpo.",
    58,
    35
)

local HeadOption
local ChestOption

local function SelectAimPart(partName)
    Settings.Target = partName
    AimPrompt.Text = "Parte selecionada: " .. partName

    HeadOption.Visible = false
    ChestOption.Visible = false
end

CreateToggle(AimTab, "ASSISTENCIA DE MIRA", function(state)
    Settings.Aimbot = state
    CurrentTarget = nil

    if state then
        Settings.Target = nil
        AimPrompt.Text = "Escolha CABECA ou PEITO:"
        HeadOption.Visible = true
        ChestOption.Visible = true
    else
        Settings.Target = nil
        AimPrompt.Text = "Assistencia desativada."
        HeadOption.Visible = false
        ChestOption.Visible = false
    end
end, 12)

HeadOption = CreateOption(AimTab, "MIRAR NA CABECA", 105, function()
    SelectAimPart("Cabeca")
end)

ChestOption = CreateOption(AimTab, "MIRAR NO PEITO", 145, function()
    SelectAimPart("Peito")
end)

HeadOption.Visible = false
ChestOption.Visible = false

local SmoothLabel = CreateInfo(
    AimTab,
    "Suavidade: 20%",
    190,
    25
)

local StepOption

StepOption = CreateOption(
    AimTab,
    "PASSO: 5% (TOQUE PARA 10%)",
    218,
    function()
        Settings.SmoothStep = Settings.SmoothStep == 5 and 10 or 5

        StepOption.Text = "PASSO: "
            .. Settings.SmoothStep
            .. "% (TOQUE PARA ALTERNAR)"
    end
)

local function ChangeSmoothness(direction)
    local current = math.floor(
        Settings.AimSmoothness * 100 + 0.5
    )

    current = math.clamp(
        current + direction * Settings.SmoothStep,
        0,
        100
    )

    Settings.AimSmoothness = current / 100
    SmoothLabel.Text = "Suavidade: " .. current .. "%"
end

CreateOption(AimTab, "AUMENTAR SUAVIDADE +", 255, function()
    ChangeSmoothness(1)
end)

CreateOption(AimTab, "DIMINUIR SUAVIDADE -", 295, function()
    ChangeSmoothness(-1)
end)

--==================================================
-- ESP PLAYER + ESP BOT
--==================================================

local EspTab = CreateTab("ESP", 2)

local function RemoveESP(target)
    local objects = ESPObjects[target]

    if not objects then
        return
    end

    if objects.Highlight then
        objects.Highlight:Destroy()
    end

    if objects.Billboard then
        objects.Billboard:Destroy()
    end

    ESPObjects[target] = nil
end

-- Cria ESP para qualquer Model com Humanoid.
-- Nao exige Head: usa outra BasePart se necessario.

local function AddESP(target, character, displayName)
    if not character or not character:IsA("Model") then
        return
    end

    if not character.Parent or not IsAlive(character) then
        return
    end

    local anchor = GetCharacterAnchor(character)

    if not anchor then
        return
    end

    local oldObjects = ESPObjects[target]

    if oldObjects
        and oldObjects.Character == character
        and oldObjects.Highlight
        and oldObjects.Highlight.Parent
        and oldObjects.Billboard
        and oldObjects.Billboard.Parent
        and oldObjects.Billboard.Adornee == anchor then

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
    billboard.Adornee = anchor
    billboard.Size = UDim2.fromOffset(180, 30)
    billboard.StudsOffset = Vector3.new(0, 2.7, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = PlayerGui

    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = tostring(displayName or character.Name)
    label.TextColor3 = BLUE_OUTLINE
    label.TextStrokeColor3 = Color3.fromRGB(0, 35, 90)
    label.TextStrokeTransparency = 0.15
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    ESPObjects[target] = {
        Character = character,
        Highlight = highlight,
        Billboard = billboard,
        Anchor = anchor,
    }

    SetAIEvent("ESP criado: " .. tostring(displayName or character.Name))
end

local function UpdateESP()
    local activeObjects = {}

    -- Jogadores.
    if Settings.ESPPlayers then
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= Player then
                local character = target.Character

                if character and IsAlive(character) then
                    activeObjects[target] = true

                    AddESP(
                        target,
                        character,
                        target.DisplayName
                    )
                end
            end
        end
    end

    -- Bots/NPCs.
    if Settings.ESPBots then
        for _, model in ipairs(CachedNPCs) do
            if model
                and model.Parent
                and IsAlive(model)
                and not IsPlayerCharacter(model) then

                activeObjects[model] = true

                AddESP(
                    model,
                    model,
                    model.Name
                )
            end
        end
    end

    -- Remove objetos que nao devem mais aparecer.
    for target in pairs(ESPObjects) do
        if not activeObjects[target] then
            RemoveESP(target)
        end
    end
end

CreateToggle(EspTab, "ESP PLAYER + ESP NAME", function(state)
    Settings.ESPPlayers = state

    UpdateESP()

    SetAIEvent(
        state and "ESP de jogadores ativado"
        or "ESP de jogadores desativado"
    )
end, 15)

CreateToggle(EspTab, "ESP BOT + NOME", function(state)
    Settings.ESPBots = state

    if state then
        RefreshNPCs()
    end

    UpdateESP()

    SetAIEvent(
        state and "busca de bots/NPCs ativada"
        or "busca de bots/NPCs desativada"
    )
end, 65)

CreateToggle(EspTab, "RECUPERACAO AUTOMATICA", function(state)
    Settings.SmartRecovery = state

    SetAIEvent(
        state and "recuperacao automatica ativada"
        or "recuperacao automatica desativada"
    )
end, 115, true)

local ESPInfo = CreateInfo(
    EspTab,
    "Player e NPC possuem deteccao separada. O nome aparece junto com o ESP.",
    165,
    55
)

--==================================================
-- EVENTOS DE JOGADORES E RESPAWN
--==================================================

local function TrackPlayer(target)
    if target == Player or PlayerConnections[target] then
        return
    end

    local connections = {}
    PlayerConnections[target] = connections

    table.insert(
        connections,
        target.CharacterAdded:Connect(function(character)
            task.spawn(function()
                character:WaitForChild("Humanoid", 12)
                task.wait(0.2)

                if Settings.ESPPlayers
                    and target.Parent == Players
                    and character.Parent then

                    AddESP(
                        target,
                        character,
                        target.DisplayName
                    )

                    SetAIEvent(
                        "respawn detectado: " .. target.DisplayName
                    )
                end
            end)
        end)
    )

    table.insert(
        connections,
        target.CharacterRemoving:Connect(function()
            RemoveESP(target)
        end)
    )

    if Settings.ESPPlayers and target.Character then
        task.spawn(function()
            target.Character:WaitForChild("Humanoid", 8)

            if target.Character and Settings.ESPPlayers then
                AddESP(
                    target,
                    target.Character,
                    target.DisplayName
                )
            end
        end)
    end
end

for _, target in ipairs(Players:GetPlayers()) do
    TrackPlayer(target)
end

Players.PlayerAdded:Connect(TrackPlayer)

Players.PlayerRemoving:Connect(function(target)
    RemoveESP(target)

    local connections = PlayerConnections[target]

    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        PlayerConnections[target] = nil
    end
end)

--==================================================
-- AIM FOV
--==================================================

local FovTab = CreateTab("AIM FOV", 3)

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

local SizeLabel = CreateInfo(
    FovTab,
    "Tamanho: " .. Settings.FOVSize,
    65,
    28
)

local function ChangeFOV(amount)
    Settings.FOVSize = math.clamp(
        Settings.FOVSize + amount,
        40,
        300
    )

    FOVCircle.Size = UDim2.fromOffset(
        Settings.FOVSize * 2,
        Settings.FOVSize * 2
    )

    SizeLabel.Text = "Tamanho: " .. Settings.FOVSize
end

CreateOption(FovTab, "AUMENTAR +", 100, function()
    ChangeFOV(20)
end)

CreateOption(FovTab, "DIMINUIR -", 140, function()
    ChangeFOV(-20)
end)

--==================================================
-- PERSEGUICAO
--==================================================

local PursuitTab = CreateTab("PERSEGUICAO", 4)

local Sensor = Instance.new("Frame")
Sensor.Name = "TalesAimSensor"
Sensor.AnchorPoint = Vector2.new(0.5, 0.5)
Sensor.Size = UDim2.fromOffset(
    Settings.SensorSize,
    Settings.SensorSize
)
Sensor.Position = Settings.SensorPosition
Sensor.BackgroundColor3 = BLUE
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

local PursuitStatus = CreateInfo(
    PursuitTab,
    "Perseguicao: DESATIVADA",
    60,
    30
)

local SensorStatus = CreateInfo(
    PursuitTab,
    "Sensor: TRAVADO",
    90,
    25
)

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
        or BLUE

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

CreateOption(PursuitTab, "TRAVAR / DESTRAVAR", 130, function()
    Settings.SensorLocked = not Settings.SensorLocked
    UpdateSensor()
end)

CreateOption(PursuitTab, "AUMENTAR BOLINHA +", 170, function()
    Settings.SensorSize = math.clamp(
        Settings.SensorSize + 10,
        35,
        150
    )

    UpdateSensor()
end)

CreateOption(PursuitTab, "DIMINUIR BOLINHA -", 210, function()
    Settings.SensorSize = math.clamp(
        Settings.SensorSize - 10,
        35,
        150
    )

    UpdateSensor()
end)

local sensorDragging = false
local sensorInput = nil
local sensorStart = nil
local sensorOrigin = nil
local sensorMoved = false

local function InputPosition(input)
    return Vector2.new(
        input.Position.X,
        input.Position.Y
    )
end

local function InsideSensor(position)
    local center = Sensor.AbsolutePosition
        + Sensor.AbsoluteSize / 2

    local half = Sensor.AbsoluteSize / 2

    return math.abs(position.X - center.X) <= half.X
        and math.abs(position.Y - center.Y) <= half.Y
end

local function SetSensorPosition(position)
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    Settings.SensorPosition = UDim2.new(
        math.clamp(position.X / viewport.X, 0.03, 0.97),
        0,
        math.clamp(position.Y / viewport.Y, 0.05, 0.95),
        0
    )

    Sensor.Position = Settings.SensorPosition
end

UserInputService.InputBegan:Connect(function(input)
    if not Settings.Pursuit then
        return
    end

    local touch = input.UserInputType == Enum.UserInputType.Touch
    local click = input.UserInputType == Enum.UserInputType.MouseButton1

    if not touch and not click then
        return
    end

    local pos = InputPosition(input)

    if not InsideSensor(pos) then
        return
    end

    if Settings.SensorLocked then
        Settings.PursuitActive = not Settings.PursuitActive
        UpdateSensor()
    else
        sensorDragging = true
        sensorInput = input
        sensorStart = pos
        sensorOrigin = Sensor.AbsolutePosition + Sensor.AbsoluteSize / 2
        sensorMoved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not sensorDragging then
        return
    end

    local move = input.UserInputType == Enum.UserInputType.MouseMovement

    if not move and input ~= sensorInput then
        return
    end

    local delta = InputPosition(input) - sensorStart

    if delta.Magnitude > 5 then
        sensorMoved = true
    end

    if sensorMoved then
        SetSensorPosition(sensorOrigin + delta)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == sensorInput
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        sensorDragging = false
        sensorInput = nil
        sensorStart = nil
        sensorOrigin = nil
    end
end)

--==================================================
-- IA ASSIST
--==================================================

local AITab = CreateTab("IA ASSIST", 5)

local AIStatus = CreateInfo(
    AITab,
    "IA: INICIANDO...",
    15,
    35
)

local TargetStatus = CreateInfo(
    AITab,
    "Alvo: nenhum",
    52,
    27
)

local CivilStatus = CreateInfo(
    AITab,
    "Funcao: verificando",
    80,
    27
)

AIEventStatus = CreateInfo(
    AITab,
    "Ultima deteccao: aguardando atividade",
    110,
    55
)

local NPCStatus = CreateInfo(
    AITab,
    "Bots detectados: 0",
    145,
    25
)

CreateToggle(AITab, "RECUPERACAO INTELIGENTE", function(state)
    Settings.SmartRecovery = state

    SetAIEvent(
        state and "recuperacao inteligente ativada"
        or "recuperacao inteligente desativada"
    )
end, 180, true)

CreateToggle(AITab, "PROTECAO AO VIRAR CIVIL", function(state)
    Settings.CivilProtection = state

    if state and IsCivil then
        Settings.PursuitActive = false
        Settings.Aimbot = false
        CurrentTarget = nil
        UpdateSensor()

        SetAIEvent("protecao ativada: funcao civil detectada")
    else
        SetAIEvent(
            state and "protecao civil ativada"
            or "protecao civil desativada"
        )
    end
end, 225, true)

CreateInfo(
    AITab,
    "A IA monitora alvos, ESP, bots e protecao. Nao altera dano nem cargo.",
    270,
    45
)

--==================================================
-- VALORES PUBLICOS
--==================================================

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

local CivilValue = Instance.new("BoolValue")
CivilValue.Name = "TalesIsCivil"
CivilValue.Value = false
CivilValue.Parent = GUI

--==================================================
-- SELECAO DE ALVOS
--==================================================

local function GetTargetPart(character)
    if not character then
        return nil
    end

    if Settings.Target == "Cabeca" then
        return character:FindFirstChild("Head")
            or GetCharacterAnchor(character)

    elseif Settings.Target == "Peito" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
            or GetCharacterAnchor(character)
    end

    return GetCharacterAnchor(character)
end

local function GetTargetScreenDistance(target)
    Camera = workspace.CurrentCamera

    if not Camera or not target or target == Player then
        return nil
    end

    local character = GetCharacter(target)
    local part = character and GetTargetPart(character)

    if not part or not IsAlive(character) then
        return nil
    end

    local point, onScreen = Camera:WorldToViewportPoint(part.Position)

    if not onScreen or point.Z <= 0 then
        return nil
    end

    local viewport = Camera.ViewportSize

    local center = Vector2.new(
        viewport.X * 0.5,
        viewport.Y * 0.5
    )

    return (
        Vector2.new(point.X, point.Y) - center
    ).Magnitude
end

local function IsTargetInRange(target)
    local distance = GetTargetScreenDistance(target)

    if not distance then
        return false
    end

    local limit = Settings.FOV and Settings.FOVSize or 300

    return distance <= limit
end

-- Busca jogadores e NPCs.
-- A lista de alvos nao depende de ESP estar ligado.

local function GetClosestTarget()
    Camera = workspace.CurrentCamera

    if not Camera then
        return nil
    end

    local bestDistance = math.huge
    local bestTarget = nil

    local limit = Settings.FOV and Settings.FOVSize or 300

    local function CheckTarget(target)
        if not target or target == Player then
            return
        end

        local distance = GetTargetScreenDistance(target)

        if distance
            and distance <= limit
            and distance < bestDistance then

            bestDistance = distance
            bestTarget = target
        end
    end

    -- Jogadores.
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            CheckTarget(target)
        end
    end

    -- Bots/NPCs.
    for _, model in ipairs(CachedNPCs) do
        if model and model.Parent and not IsPlayerCharacter(model) then
            CheckTarget(model)
        end
    end

    return bestTarget, bestDistance
end

local function GetStableTarget()
    local bestTarget, bestDistance = GetClosestTarget()

    local currentDistance = CurrentTarget
        and IsTargetInRange(CurrentTarget)
        and GetTargetScreenDistance(CurrentTarget)
        or nil

    if not currentDistance then
        return bestTarget
    end

    if not bestTarget or bestTarget == CurrentTarget then
        return CurrentTarget
    end

    if bestDistance and bestDistance < currentDistance * 0.80 then
        SetAIEvent(
            "troca estavel de alvo: "
            .. GetTargetName(bestTarget)
        )

        return bestTarget
    end

    return CurrentTarget
end

--==================================================
-- ARRASTAR JANELA PRINCIPAL
--==================================================

do
    local dragStart
    local startPos
    local activeInput

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingPanel = true
            dragStart = InputPosition(input)
            startPos = Main.Position
            activeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not draggingPanel then
            return
        end

        if input ~= activeInput
            and input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = InputPosition(input) - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == activeInput
            or input.UserInputType == Enum.UserInputType.MouseButton1 then

            draggingPanel = false
            activeInput = nil
        end
    end)
end

--==================================================
-- BOTAO MINIMIZADO MOVEL
--==================================================

local miniDragging = false
local miniInput = nil
local miniStart = nil
local miniMoved = false

MiniButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        miniDragging = true
        miniInput = input
        miniStart = InputPosition(input)
        miniMoved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not miniDragging then
        return
    end

    local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement

    if not isMouse and input ~= miniInput then
        return
    end

    local delta = InputPosition(input) - miniStart

    if delta.Magnitude > 7 then
        miniMoved = true
    end

    if miniMoved then
        local viewport = workspace.CurrentCamera
            and workspace.CurrentCamera.ViewportSize

        if viewport then
            local x = math.clamp(
                (MiniButton.AbsolutePosition.X + delta.X) / viewport.X,
                0,
                0.94
            )

            local y = math.clamp(
                (MiniButton.AbsolutePosition.Y + delta.Y) / viewport.Y,
                0,
                0.92
            )

            MiniButton.Position = UDim2.new(x, 0, y, 0)
            miniStart = InputPosition(input)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not miniDragging then
        return
    end

    if input == miniInput
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        miniDragging = false

        if not miniMoved then
            minimized = false
            Main.Visible = true
            MiniButton.Visible = false
        end

        miniInput = nil
    end
end)

Minimize.MouseButton1Click:Connect(function()
    minimized = true
    Main.Visible = false
    MiniButton.Visible = true
end)

--==================================================
-- MORTE E RENASCIMENTO LOCAL
--==================================================

local characterConnection

local function BindLocalCharacter(character)
    if characterConnection then
        characterConnection:Disconnect()
    end

    local humanoid = character:WaitForChild("Humanoid", 10)

    if humanoid then
        characterConnection = humanoid.Died:Connect(function()
            Settings.PursuitActive = false
            CurrentTarget = nil

            TargetValue.Value = nil
            PursuitValue.Value = false

            UpdateSensor()
        end)
    end
end

Player.CharacterAdded:Connect(BindLocalCharacter)

Player.CharacterRemoving:Connect(function()
    Settings.PursuitActive = false
    CurrentTarget = nil

    TargetValue.Value = nil
    PursuitValue.Value = false

    UpdateSensor()
end)

if Player.Character then
    task.spawn(BindLocalCharacter, Player.Character)
end

--==================================================
-- DETECCAO DE EQUIPE CIVIL
--==================================================

local function UpdateCivilStatus()
    local wasCivil = IsCivil

    IsCivil = IsLocalPlayerCivil()

    if IsCivil ~= wasCivil then
        SetAIEvent(
            IsCivil and "funcao civil detectada"
            or "funcao civil nao detectada"
        )
    end

    if IsCivil and Settings.CivilProtection then
        Settings.PursuitActive = false
        Settings.Aimbot = false
        CurrentTarget = nil

        UpdateSensor()
    end
end

Player:GetPropertyChangedSignal("Team"):Connect(UpdateCivilStatus)

Player:GetAttributeChangedSignal("Role"):Connect(UpdateCivilStatus)
Player:GetAttributeChangedSignal("Class"):Connect(UpdateCivilStatus)
Player:GetAttributeChangedSignal("Job"):Connect(UpdateCivilStatus)
Player:GetAttributeChangedSignal("TeamRole"):Connect(UpdateCivilStatus)

--==================================================
-- MONITOR PRINCIPAL
--==================================================

local espTimer = 0
local npcTimer = 0
local aiTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    Camera = workspace.CurrentCamera

    if Camera then
        local viewport = Camera.ViewportSize

        FOVCircle.Position = UDim2.fromOffset(
            viewport.X * 0.5,
            viewport.Y * 0.5
        )
    end

    -- Atualiza a lista de NPCs mesmo quando a ESP esta desligada,
    -- pois o aimbot tambem pode procurar esses personagens.

    npcTimer += deltaTime

    if npcTimer >= 0.60 then
        npcTimer = 0

        RefreshNPCs()

        if Settings.ESPBots or Settings.ESPPlayers then
            UpdateESP()
        end
    end

    -- Recuperacao periodica da ESP.
    espTimer += deltaTime

    if Settings.SmartRecovery and espTimer >= 0.40 then
        espTimer = 0

        if Settings.ESPPlayers or Settings.ESPBots then
            UpdateESP()
        end
    end

    IsCivil = IsLocalPlayerCivil()
    CivilValue.Value = IsCivil

    local wantsAim = Settings.Aimbot
        and Settings.Target ~= nil
        and CombatAllowed()

    local wantsPursuit = Settings.Pursuit
        and Settings.PursuitActive
        and CombatAllowed()

    if wantsAim or wantsPursuit then
        local previousTarget = CurrentTarget

        CurrentTarget = GetStableTarget()

        if CurrentTarget and CurrentTarget ~= previousTarget then
            SetAIEvent(
                "alvo localizado: "
                .. GetTargetName(CurrentTarget)
            )

        elseif not CurrentTarget then
            SetAIEvent("nenhum alvo dentro do limite atual")
        end
    else
        if CurrentTarget then
            SetAIEvent("rastreamento pausado")
        end

        CurrentTarget = nil
    end

    local targetCharacter = GetCharacter(CurrentTarget)

    local targetPart = targetCharacter
        and GetTargetPart(targetCharacter)

    if not targetPart or not IsAlive(targetCharacter) then
        CurrentTarget = nil
        targetCharacter = nil
        targetPart = nil
    end

    -- Assistencia original de camera.
    -- 0% = sem movimento.
    -- 100% = acompanhamento imediato.

    if wantsAim and targetPart and Camera then
        local cameraPosition = Camera.CFrame.Position

        local desired = CFrame.lookAt(
            cameraPosition,
            targetPart.Position
        )

        local smooth = math.clamp(
            Settings.AimSmoothness,
            0,
            1
        )

        local alpha = smooth <= 0 and 0
            or (
                smooth >= 1 and 1
                or 1 - math.pow(
                    1 - smooth,
                    math.max(deltaTime * 60, 0.01)
                )
            )

        if alpha > 0 then
            Camera.CFrame = Camera.CFrame:Lerp(
                desired,
                alpha
            )
        end
    end

    -- Publica o personagem, seja jogador ou NPC.
    TargetValue.Value = targetCharacter
    TargetPartValue.Value = Settings.Target or ""
    PursuitValue.Value = wantsPursuit

    -- IA Assist.
    aiTimer += deltaTime

    if aiTimer >= 0.25 then
        aiTimer = 0

        if IsCivil then
            LastAIStatus = "CIVIL DETECTADO - COMBATE BLOQUEADO"

        elseif not CombatAllowed() then
            LastAIStatus = "PROTECAO ATIVA"

        elseif CurrentTarget then
            LastAIStatus = "ALVO ACOMPANHADO - "
                .. GetTargetName(CurrentTarget)

        elseif wantsAim or wantsPursuit then
            LastAIStatus = "PROCURANDO ALVO NO FOV"

        elseif Settings.ESPPlayers or Settings.ESPBots then
            LastAIStatus = "MONITORANDO ESP"

        else
            LastAIStatus = "MONITORANDO SISTEMAS"
        end

        AIStatus.Text = "IA: " .. LastAIStatus

        TargetStatus.Text = "Alvo: "
            .. GetTargetName(CurrentTarget)

        CivilStatus.Text = IsCivil
            and "Funcao: CIVIL detectado"
            or "Funcao: nao identificada como civil"

        NPCStatus.Text = "Bots detectados: "
            .. tostring(#CachedNPCs)

        ESPInfo.Text = "Players: "
            .. tostring(#Players:GetPlayers() - 1)
            .. " | Bots: "
            .. tostring(#CachedNPCs)
            .. " | Recuperacao: "
            .. (Settings.SmartRecovery and "ON" or "OFF")
    end
end)

--==================================================
-- INICIALIZACAO
--==================================================

RefreshNPCs()
UpdateSensor()
UpdateCivilStatus()

print("Tales Mod Menu IA Assist carregado.")
print("ESP Player + Name: pronto.")
print("ESP Bot/NPC: pronto.")
print("Busca de alvos independente da ESP: pronta.")
