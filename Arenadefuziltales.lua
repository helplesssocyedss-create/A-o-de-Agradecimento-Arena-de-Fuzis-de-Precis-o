--[[
    TALES MOD MENU - IA ASSIST
    Feito por Tales
    LocalScript para uso no proprio jogo, no Roblox Studio.

    ATUALIZACOES:
    - ESP PLAYER azul + nome.
    - ESP BOT/NPC amarelo + nome BOT.
    - Deteccao de personagens sem exigir Head.
    - Recuperacao automatica de ESP apos respawn.
    - Assistencia de mira com CABECA/PEITO.
    - Suavidade de 0% a 100%.
    - Selecao de players por checkbox.
    - Quando a selecao estiver ativa, somente os players
      marcados serao considerados pelo rastreamento.
    - FOV, perseguicao e IA Assist.
    - Indicador verde quando existe linha de visao livre.
    - Categoria exclusiva de TIRO AUTOMATICO.
    - Sensor AutoFire independente da perseguicao e do Aimbot.
    - AutoFire procura jogadores diretamente dentro do seu sensor.
    - Sensor arrastavel, redimensionavel e travavel.
    - Sensor verde somente quando as condicoes locais
      de prontidao forem atendidas.
    - Painel principal reduzido.
    - Botao minimizado pequeno e arrastavel.

    OBSERVACAO:
    Tool:Activate() solicita a ativacao da ferramenta.
    Isso nao garante que o servidor registrou um disparo.
    O sensor e visual e nao clica no botao do HUD.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local BLUE = Color3.fromRGB(0, 170, 255)
local BLUE_OUTLINE = Color3.fromRGB(0, 200, 255)
local YELLOW = Color3.fromRGB(255, 220, 0)
local YELLOW_OUTLINE = Color3.fromRGB(255, 235, 80)

local PANEL = Color3.fromRGB(20, 22, 30)
local PANEL_INNER = Color3.fromRGB(29, 32, 43)
local RED = Color3.fromRGB(220, 65, 45)
local GREEN = Color3.fromRGB(20, 190, 85)
local AMBER = Color3.fromRGB(220, 150, 35)

local old = PlayerGui:FindFirstChild("TalesModMenu")
if old then
    old:Destroy()
end

local Settings = {
    Aimbot = false,
    Target = nil,
    AimSmoothness = 0.20,
    SmoothStep = 5,

    PlayerSelectionEnabled = false,
    SelectedPlayers = {},

    ESPPlayers = false,
    ESPBots = false,

    AutoFire = false,
    AutoFireSensorSize = 65,
    AutoFireSensorPosition = UDim2.new(0.5, 0, 0.75, 0),
    AutoFireSensorLocked = true,

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
    local teamName = Player.Team and string.lower(Player.Team.Name) or ""

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
    return model and Players:GetPlayerFromCharacter(model) ~= nil
end

local function RefreshNPCs()
    local found = {}

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") then
            local humanoid = object:FindFirstChildOfClass("Humanoid")

            if humanoid
                and humanoid.Health > 0
                and object ~= Player.Character
                and not IsPlayerCharacter(object) then

                if GetCharacterAnchor(object) then
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
-- GUI PRINCIPAL REDUZIDA
--==================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "TalesModMenu"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 50
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(390, 430)
Main.Position = UDim2.new(0.5, -195, 0.5, -215)
Main.BackgroundColor3 = PANEL
Main.BorderSizePixel = 0
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -55, 0, 42)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "TALES | MOD MENU"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(32, 28)
Minimize.Position = UDim2.new(1, -39, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 21
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = Main

Instance.new("UICorner", Minimize)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 105, 1, -75)
Sidebar.Position = UDim2.fromOffset(8, 45)
Sidebar.BackgroundColor3 = PANEL_INNER
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

Instance.new("UICorner", Sidebar)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -125, 1, -75)
Content.Position = UDim2.fromOffset(118, 45)
Content.BackgroundColor3 = PANEL_INNER
Content.BorderSizePixel = 0
Content.Parent = Main

Instance.new("UICorner", Content)

local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 0, 18)
Credits.Position = UDim2.new(0, 0, 1, -20)
Credits.BackgroundTransparency = 1
Credits.Text = "Feito por Tales"
Credits.TextColor3 = Color3.fromRGB(130, 140, 160)
Credits.TextSize = 11
Credits.Font = Enum.Font.Gotham
Credits.Parent = Main

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "TalesMiniButton"
MiniButton.Size = UDim2.fromOffset(48, 48)
MiniButton.Position = UDim2.new(0.82, 0, 0.72, 0)
MiniButton.BackgroundColor3 = Color3.fromRGB(15, 115, 185)
MiniButton.Text = "T"
MiniButton.TextColor3 = Color3.new(1, 1, 1)
MiniButton.TextSize = 23
MiniButton.Font = Enum.Font.GothamBlack
MiniButton.Visible = false
MiniButton.Active = true
MiniButton.Parent = GUI
MiniButton.ZIndex = 100

Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(0, 15)

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
    button.Size = UDim2.new(1, -8, 0, 34)
    button.Position = UDim2.fromOffset(4, ((index - 1) * 39) + 5)
    button.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.TextSize = 9
    button.TextWrapped = true
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
    button.Size = UDim2.new(1, -16, 0, 34)
    button.Position = UDim2.fromOffset(8, y)
    button.BackgroundColor3 = Color3.fromRGB(75, 78, 90)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 11
    button.TextWrapped = true
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
    button.Size = UDim2.new(1, -16, 0, 32)
    button.Position = UDim2.fromOffset(8, y)
    button.BackgroundColor3 = Color3.fromRGB(45, 95, 150)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.TextSize = 10
    button.TextWrapped = true
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    Instance.new("UICorner", button)
    button.MouseButton1Click:Connect(callback)

    return button
end

local function CreateInfo(parent, text, y, height)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, height or 30)
    label.Position = UDim2.fromOffset(8, y)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 10
    label.TextWrapped = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

--==================================================
-- AIMBOT E SELECAO DE PLAYERS
--==================================================

local AimTab = CreateTab("AIMBOT", 1)

local AimPrompt = CreateInfo(
    AimTab,
    "Ative a assistencia e escolha a parte do corpo.",
    48,
    32
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
end, 8)

HeadOption = CreateOption(AimTab, "MIRAR NA CABECA", 84, function()
    SelectAimPart("Cabeca")
end)

ChestOption = CreateOption(AimTab, "MIRAR NO PEITO", 120, function()
    SelectAimPart("Peito")
end)

HeadOption.Visible = false
ChestOption.Visible = false

local SmoothLabel = CreateInfo(AimTab, "Suavidade: 20%", 157, 22)

local StepOption

StepOption = CreateOption(
    AimTab,
    "PASSO: 5% (TOQUE PARA 10%)",
    181,
    function()
        Settings.SmoothStep = Settings.SmoothStep == 5 and 10 or 5
        StepOption.Text = "PASSO: "
            .. Settings.SmoothStep
            .. "% (TOQUE PARA ALTERNAR)"
    end
)

local function ChangeSmoothness(direction)
    local current = math.floor(Settings.AimSmoothness * 100 + 0.5)

    current = math.clamp(
        current + direction * Settings.SmoothStep,
        0,
        100
    )

    Settings.AimSmoothness = current / 100
    SmoothLabel.Text = "Suavidade: " .. current .. "%"
end

CreateOption(AimTab, "AUMENTAR SUAVIDADE +", 217, function()
    ChangeSmoothness(1)
end)

CreateOption(AimTab, "DIMINUIR SUAVIDADE -", 253, function()
    ChangeSmoothness(-1)
end)

local PlayerSelectionButton = CreateToggle(
    AimTab,
    "SELECAO DE PLAYER",
    function(state)
        Settings.PlayerSelectionEnabled = state
        CurrentTarget = nil

        if state then
            SetAIEvent("selecao de players ativada")
        else
            SetAIEvent("selecao de players desativada")
        end
    end,
    289
)

local SelectionInfo = CreateInfo(
    AimTab,
    "Marque os jogadores que poderao ser acompanhados.",
    326,
    30
)

-- Janela compacta de selecao, separada do painel principal.

local SelectionPanel = Instance.new("Frame")
SelectionPanel.Name = "PlayerSelectionPanel"
SelectionPanel.Size = UDim2.fromOffset(235, 300)
SelectionPanel.Position = UDim2.new(0.5, -117, 0.5, -150)
SelectionPanel.BackgroundColor3 = PANEL
SelectionPanel.BorderSizePixel = 0
SelectionPanel.Visible = false
SelectionPanel.ZIndex = 150
SelectionPanel.Parent = GUI

Instance.new("UICorner", SelectionPanel).CornerRadius = UDim.new(0, 10)

local SelectionTitle = Instance.new("TextLabel")
SelectionTitle.Size = UDim2.new(1, -42, 0, 34)
SelectionTitle.Position = UDim2.fromOffset(8, 0)
SelectionTitle.BackgroundTransparency = 1
SelectionTitle.Text = "SELECIONAR PLAYERS"
SelectionTitle.TextColor3 = Color3.new(1, 1, 1)
SelectionTitle.TextSize = 12
SelectionTitle.Font = Enum.Font.GothamBold
SelectionTitle.TextXAlignment = Enum.TextXAlignment.Left
SelectionTitle.ZIndex = 151
SelectionTitle.Parent = SelectionPanel

local SelectionClose = Instance.new("TextButton")
SelectionClose.Size = UDim2.fromOffset(28, 26)
SelectionClose.Position = UDim2.new(1, -33, 0, 4)
SelectionClose.BackgroundColor3 = RED
SelectionClose.Text = "X"
SelectionClose.TextColor3 = Color3.new(1, 1, 1)
SelectionClose.TextSize = 13
SelectionClose.Font = Enum.Font.GothamBold
SelectionClose.ZIndex = 151
SelectionClose.Parent = SelectionPanel

Instance.new("UICorner", SelectionClose)

local SelectionRefresh = Instance.new("TextButton")
SelectionRefresh.Size = UDim2.new(1, -16, 0, 27)
SelectionRefresh.Position = UDim2.fromOffset(8, 36)
SelectionRefresh.BackgroundColor3 = Color3.fromRGB(45, 95, 150)
SelectionRefresh.Text = "ATUALIZAR LISTA"
SelectionRefresh.TextColor3 = Color3.new(1, 1, 1)
SelectionRefresh.TextSize = 10
SelectionRefresh.Font = Enum.Font.GothamBold
SelectionRefresh.ZIndex = 151
SelectionRefresh.Parent = SelectionPanel

Instance.new("UICorner", SelectionRefresh)

local SelectionScroll = Instance.new("ScrollingFrame")
SelectionScroll.Size = UDim2.new(1, -16, 1, -105)
SelectionScroll.Position = UDim2.fromOffset(8, 68)
SelectionScroll.BackgroundColor3 = PANEL_INNER
SelectionScroll.BorderSizePixel = 0
SelectionScroll.ScrollBarThickness = 4
SelectionScroll.CanvasSize = UDim2.new()
SelectionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SelectionScroll.ZIndex = 151
SelectionScroll.Parent = SelectionPanel

Instance.new("UICorner", SelectionScroll)

local SelectionLayout = Instance.new("UIListLayout")
SelectionLayout.Padding = UDim.new(0, 4)
SelectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
SelectionLayout.Parent = SelectionScroll

local SelectionCount = Instance.new("TextLabel")
SelectionCount.Size = UDim2.new(1, -16, 0, 27)
SelectionCount.Position = UDim2.new(0, 8, 1, -32)
SelectionCount.BackgroundTransparency = 1
SelectionCount.Text = "Selecionados: 0"
SelectionCount.TextColor3 = Color3.new(1, 1, 1)
SelectionCount.TextSize = 10
SelectionCount.Font = Enum.Font.GothamBold
SelectionCount.ZIndex = 151
SelectionCount.Parent = SelectionPanel

local function CountSelectedPlayers()
    local count = 0

    for userId, selected in pairs(Settings.SelectedPlayers) do
        if selected then
            local target = Players:GetPlayerByUserId(userId)

            if target and target ~= Player then
                count += 1
            else
                Settings.SelectedPlayers[userId] = nil
            end
        end
    end

    return count
end

local function UpdateSelectionCount()
    SelectionCount.Text = "Selecionados: "
        .. tostring(CountSelectedPlayers())
end

local function RefreshPlayerSelectionList()
    for _, child in ipairs(SelectionScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local targets = {}

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            table.insert(targets, target)
        end
    end

    table.sort(targets, function(a, b)
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    if #targets == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -8, 0, 35)
        empty.BackgroundTransparency = 1
        empty.Text = "Nenhum outro player na partida."
        empty.TextColor3 = Color3.new(1, 1, 1)
        empty.TextSize = 10
        empty.Font = Enum.Font.Gotham
        empty.ZIndex = 152
        empty.Parent = SelectionScroll
    end

    for index, target in ipairs(targets) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, -8, 0, 31)
        row.BackgroundColor3 = Color3.fromRGB(55, 60, 75)
        row.TextColor3 = Color3.new(1, 1, 1)
        row.TextSize = 10
        row.Font = Enum.Font.GothamBold
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.ZIndex = 152
        row.LayoutOrder = index
        row.Parent = SelectionScroll

        Instance.new("UICorner", row)

        local function PaintRow()
            local selected = Settings.SelectedPlayers[target.UserId] == true

            row.Text = selected
                and "  [X] " .. target.DisplayName
                or "  [ ] " .. target.DisplayName

            row.BackgroundColor3 = selected
                and Color3.fromRGB(20, 125, 75)
                or Color3.fromRGB(55, 60, 75)
        end

        PaintRow()

        row.MouseButton1Click:Connect(function()
            Settings.SelectedPlayers[target.UserId] =
                not Settings.SelectedPlayers[target.UserId]

            PaintRow()
            UpdateSelectionCount()
            CurrentTarget = nil
        end)
    end

    UpdateSelectionCount()
end

CreateOption(AimTab, "ABRIR LISTA DE PLAYERS", 326, function()
    RefreshPlayerSelectionList()
    SelectionPanel.Visible = true
end)

SelectionClose.MouseButton1Click:Connect(function()
    SelectionPanel.Visible = false
end)

SelectionRefresh.MouseButton1Click:Connect(RefreshPlayerSelectionList)

Players.PlayerAdded:Connect(function()
    if SelectionPanel.Visible then
        RefreshPlayerSelectionList()
    end
end)

Players.PlayerRemoving:Connect(function(target)
    Settings.SelectedPlayers[target.UserId] = nil

    if SelectionPanel.Visible then
        RefreshPlayerSelectionList()
    end

    UpdateSelectionCount()
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

    if objects.HeadHighlight then
        objects.HeadHighlight:Destroy()
    end

    ESPObjects[target] = nil
end

local function HasClearHeadLineOfSight(character, head)
    Camera = workspace.CurrentCamera

    if not Camera or not character or not head then
        return false
    end

    local origin = Camera.CFrame.Position
    local direction = head.Position - origin

    if direction.Magnitude <= 0 then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { Player.Character }
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)

    return result ~= nil
        and result.Instance ~= nil
        and result.Instance:IsDescendantOf(character)
end

local function UpdatePlayerHeadHighlight(target, character)
    local objects = ESPObjects[target]

    if not objects or not character then
        return false
    end

    local head = character:FindFirstChild("Head")

    if not head or not head:IsA("BasePart") then
        if objects.HeadHighlight then
            objects.HeadHighlight:Destroy()
            objects.HeadHighlight = nil
        end

        return false
    end

    if not objects.HeadHighlight
        or not objects.HeadHighlight.Parent
        or objects.HeadHighlight.Adornee ~= head then

        if objects.HeadHighlight then
            objects.HeadHighlight:Destroy()
        end

        local headHighlight = Instance.new("Highlight")
        headHighlight.Name = "TalesHeadVisibility"
        headHighlight.Adornee = head
        headHighlight.FillTransparency = 0.18
        headHighlight.OutlineTransparency = 0
        headHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
        headHighlight.Parent = workspace

        objects.HeadHighlight = headHighlight
    end

    local visible = HasClearHeadLineOfSight(character, head)

    local visibilityColor = visible
        and Color3.fromRGB(0, 255, 70)
        or BLUE

    objects.HeadHighlight.FillColor = visibilityColor
    objects.HeadHighlight.OutlineColor = visible
        and Color3.fromRGB(0, 255, 70)
        or BLUE_OUTLINE

    local billboard = objects.Billboard
    local nameLabel = billboard and billboard:FindFirstChild("NameLabel")

    if nameLabel then
        nameLabel.TextColor3 = visibilityColor
        nameLabel.TextStrokeColor3 = visible
            and Color3.fromRGB(0, 90, 25)
            or Color3.fromRGB(0, 35, 90)
    end

    objects.HeadVisible = visible
    return visible
end

local function AddESP(target, character, displayName)
    if not character
        or not character:IsA("Model")
        or not character.Parent
        or not IsAlive(character) then
        return
    end

    local anchor = GetCharacterAnchor(character)
    if not anchor then
        return
    end

    local isBot = target:IsA("Model")
    local espColor = isBot and YELLOW or BLUE
    local outlineColor = isBot and YELLOW_OUTLINE or BLUE_OUTLINE
    local finalName = isBot and "BOT" or tostring(displayName or character.Name)

    local oldObjects = ESPObjects[target]

    if oldObjects
        and oldObjects.Character == character
        and oldObjects.Highlight
        and oldObjects.Highlight.Parent
        and oldObjects.Billboard
        and oldObjects.Billboard.Parent
        and oldObjects.Billboard.Adornee == anchor then

        oldObjects.Highlight.FillColor = espColor
        oldObjects.Highlight.OutlineColor = outlineColor

        local existingLabel = oldObjects.Billboard:FindFirstChild("NameLabel")

        if existingLabel then
            existingLabel.Text = finalName
            existingLabel.TextColor3 = outlineColor
            existingLabel.TextStrokeColor3 = isBot
                and Color3.fromRGB(100, 65, 0)
                or Color3.fromRGB(0, 35, 90)
        end

        if not isBot then
            UpdatePlayerHeadHighlight(target, character)
        end

        return
    end

    RemoveESP(target)

    local highlight = Instance.new("Highlight")
    highlight.Name = "TalesESP"
    highlight.Adornee = character
    highlight.FillColor = espColor
    highlight.OutlineColor = outlineColor
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
    label.Text = finalName
    label.TextColor3 = outlineColor
    label.TextStrokeColor3 = isBot
        and Color3.fromRGB(100, 65, 0)
        or Color3.fromRGB(0, 35, 90)
    label.TextStrokeTransparency = 0.15
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    ESPObjects[target] = {
        Character = character,
        Highlight = highlight,
        Billboard = billboard,
        HeadHighlight = nil,
        Anchor = anchor,
    }

    if not isBot then
        UpdatePlayerHeadHighlight(target, character)
    end

    SetAIEvent("ESP criado: " .. finalName)
end

local function UpdateESP()
    local activeObjects = {}

    if Settings.ESPPlayers then
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= Player then
                local character = target.Character

                if character and IsAlive(character) then
                    activeObjects[target] = true
                    AddESP(target, character, target.DisplayName)
                end
            end
        end
    end

    if Settings.ESPBots then
        for _, model in ipairs(CachedNPCs) do
            if model
                and model.Parent
                and IsAlive(model)
                and not IsPlayerCharacter(model) then

                activeObjects[model] = true
                AddESP(model, model, "BOT")
            end
        end
    end

    for target in pairs(ESPObjects) do
        if not activeObjects[target] then
            RemoveESP(target)
        end
    end
end

local function UpdateAllPlayerHeadHighlights()
    if not Settings.ESPPlayers then
        return
    end

    for target, objects in pairs(ESPObjects) do
        if target:IsA("Player")
            and objects.Character
            and objects.Character.Parent then

            UpdatePlayerHeadHighlight(target, objects.Character)
        end
    end
end

CreateToggle(EspTab, "ESP PLAYER + ESP NAME", function(state)
    Settings.ESPPlayers = state
    UpdateESP()

    SetAIEvent(state and "ESP de jogadores ativado"
        or "ESP de jogadores desativado")
end, 15)

CreateToggle(EspTab, "ESP BOT + NOME", function(state)
    Settings.ESPBots = state

    if state then
        RefreshNPCs()
    end

    UpdateESP()

    SetAIEvent(state and "busca de bots/NPCs ativada"
        or "busca de bots/NPCs desativada")
end, 55)

CreateToggle(EspTab, "RECUPERACAO AUTOMATICA", function(state)
    Settings.SmartRecovery = state

    SetAIEvent(state and "recuperacao automatica ativada"
        or "recuperacao automatica desativada")
end, 95, true)

local ESPInfo = CreateInfo(
    EspTab,
    "Player e NPC possuem deteccao separada. O nome aparece junto com o ESP.",
    140,
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

    table.insert(connections, target.CharacterAdded:Connect(function(character)
        task.spawn(function()
            character:WaitForChild("Humanoid", 12)
            task.wait(0.2)

            if Settings.ESPPlayers
                and target.Parent == Players
                and character.Parent then

                AddESP(target, character, target.DisplayName)
                SetAIEvent("respawn detectado: " .. target.DisplayName)
            end
        end)
    end))

    table.insert(connections, target.CharacterRemoving:Connect(function()
        RemoveESP(target)
    end))

    if Settings.ESPPlayers and target.Character then
        task.spawn(function()
            target.Character:WaitForChild("Humanoid", 8)

            if target.Character and Settings.ESPPlayers then
                AddESP(target, target.Character, target.DisplayName)
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
FOVCircle.Size = UDim2.fromOffset(Settings.FOVSize * 2, Settings.FOVSize * 2)
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

local SizeLabel = CreateInfo(FovTab, "Tamanho: " .. Settings.FOVSize, 58, 25)

local function ChangeFOV(amount)
    Settings.FOVSize = math.clamp(Settings.FOVSize + amount, 40, 300)

    FOVCircle.Size = UDim2.fromOffset(
        Settings.FOVSize * 2,
        Settings.FOVSize * 2
    )

    SizeLabel.Text = "Tamanho: " .. Settings.FOVSize
end

CreateOption(FovTab, "AUMENTAR +", 88, function()
    ChangeFOV(20)
end)

CreateOption(FovTab, "DIMINUIR -", 124, function()
    ChangeFOV(-20)
end)

--==================================================
-- PERSEGUICAO
--==================================================

local PursuitTab = CreateTab("PERSEGUICAO", 4)

local Sensor = Instance.new("Frame")
Sensor.Name = "TalesAimSensor"
Sensor.AnchorPoint = Vector2.new(0.5, 0.5)
Sensor.Size = UDim2.fromOffset(Settings.SensorSize, Settings.SensorSize)
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

local PursuitStatus = CreateInfo(PursuitTab, "Perseguicao: DESATIVADA", 50, 25)
local SensorStatus = CreateInfo(PursuitTab, "Sensor: TRAVADO", 78, 22)

local function UpdateSensor()
    Sensor.Size = UDim2.fromOffset(Settings.SensorSize, Settings.SensorSize)
    Sensor.Position = Settings.SensorPosition
    Sensor.Visible = Settings.Pursuit

    SensorText.Text = Settings.PursuitActive and "ON" or "MIRA"
    Sensor.BackgroundColor3 = Settings.PursuitActive and GREEN or BLUE

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
end, 12)

CreateOption(PursuitTab, "TRAVAR / DESTRAVAR", 90, function()
    Settings.SensorLocked = not Settings.SensorLocked
    UpdateSensor()
end)

CreateOption(PursuitTab, "AUMENTAR BOLINHA +", 126, function()
    Settings.SensorSize = math.clamp(Settings.SensorSize + 10, 35, 150)
    UpdateSensor()
end)

CreateOption(PursuitTab, "DIMINUIR BOLINHA -", 162, function()
    Settings.SensorSize = math.clamp(Settings.SensorSize - 10, 35, 150)
    UpdateSensor()
end)

--==================================================
-- TIRO AUTOMATICO
--==================================================

local AutoFireTab = CreateTab("TIRO AUTOMATICO", 6)

local AutoFireSensor = Instance.new("Frame")
AutoFireSensor.Name = "TalesAutoFireSensor"
AutoFireSensor.AnchorPoint = Vector2.new(0.5, 0.5)
AutoFireSensor.Size = UDim2.fromOffset(
    Settings.AutoFireSensorSize,
    Settings.AutoFireSensorSize
)
AutoFireSensor.Position = Settings.AutoFireSensorPosition
AutoFireSensor.BackgroundColor3 = RED
AutoFireSensor.BackgroundTransparency = 0.30
AutoFireSensor.BorderSizePixel = 0
AutoFireSensor.Active = false
AutoFireSensor.Visible = false
AutoFireSensor.ZIndex = 30
AutoFireSensor.Parent = GUI

Instance.new("UICorner", AutoFireSensor).CornerRadius = UDim.new(1, 0)

local AutoFireSensorStroke = Instance.new("UIStroke")
AutoFireSensorStroke.Color = Color3.new(1, 1, 1)
AutoFireSensorStroke.Thickness = 2
AutoFireSensorStroke.Parent = AutoFireSensor

local AutoFireSensorText = Instance.new("TextLabel")
AutoFireSensorText.Size = UDim2.fromScale(1, 1)
AutoFireSensorText.BackgroundTransparency = 1
AutoFireSensorText.Text = "BUSCA"
AutoFireSensorText.TextColor3 = Color3.new(1, 1, 1)
AutoFireSensorText.TextSize = 11
AutoFireSensorText.Font = Enum.Font.GothamBold
AutoFireSensorText.ZIndex = 31
AutoFireSensorText.Parent = AutoFireSensor

local AutoFireStatus = CreateInfo(
    AutoFireTab,
    "Tiro automatico: DESATIVADO",
    12,
    24
)

local AutoFireSensorStatus = CreateInfo(
    AutoFireTab,
    "Sensor: TRAVADO",
    38,
    22
)

local AutoFireTargetStatus = CreateInfo(
    AutoFireTab,
    "Alvo: aguardando",
    62,
    30
)

local function SetAutoFireSensorState(state, message)
    if state == "READY" then
        AutoFireSensor.BackgroundColor3 = GREEN
        AutoFireSensorText.Text = "PRONTO"
    elseif state == "SEARCH" then
        AutoFireSensor.BackgroundColor3 = AMBER
        AutoFireSensorText.Text = "BUSCA"
    else
        AutoFireSensor.BackgroundColor3 = RED
        AutoFireSensorText.Text = "OFF"
    end

    if message then
        AutoFireTargetStatus.Text = message
    end
end

local function UpdateAutoFireSensor()
    AutoFireSensor.Size = UDim2.fromOffset(
        Settings.AutoFireSensorSize,
        Settings.AutoFireSensorSize
    )

    AutoFireSensor.Position = Settings.AutoFireSensorPosition
    AutoFireSensor.Visible = Settings.AutoFire

    if not Settings.AutoFire then
        SetAutoFireSensorState("OFF", "Alvo: aguardando")
    else
        SetAutoFireSensorState("SEARCH", "Alvo: procurando dentro do sensor")
    end

    AutoFireStatus.Text = Settings.AutoFire
        and "Tiro automatico: ATIVADO"
        or "Tiro automatico: DESATIVADO"

    AutoFireSensorStatus.Text = Settings.AutoFireSensorLocked
        and "Sensor: TRAVADO"
        or "Sensor: DESTRAVADO"
end

CreateToggle(AutoFireTab, "TIRO AUTOMATICO", function(state)
    Settings.AutoFire = state

    if not state then
        AutoFireTargetStatus.Text = "Alvo: aguardando"
    end

    UpdateAutoFireSensor()

    SetAIEvent(state and "tiro automatico ativado"
        or "tiro automatico desativado")
end, 100)

CreateOption(AutoFireTab, "TRAVAR / DESTRAVAR SENSOR", 138, function()
    Settings.AutoFireSensorLocked = not Settings.AutoFireSensorLocked
    UpdateAutoFireSensor()
end)

CreateOption(AutoFireTab, "AUMENTAR SENSOR +", 174, function()
    Settings.AutoFireSensorSize = math.clamp(
        Settings.AutoFireSensorSize + 10,
        35,
        150
    )

    UpdateAutoFireSensor()
end)

CreateOption(AutoFireTab, "DIMINUIR SENSOR -", 210, function()
    Settings.AutoFireSensorSize = math.clamp(
        Settings.AutoFireSensorSize - 10,
        35,
        150
    )

    UpdateAutoFireSensor()
end)

CreateInfo(
    AutoFireTab,
    "O sensor e visual. Arraste para posicionar e trave. A ativacao depende da ferramenta equipada e das regras do jogo.",
    250,
    55
)

--==================================================
-- CONTROLE DE TOQUE E ARRASTO DOS SENSORES
--==================================================

local function InputPosition(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

local function InsideFrame(frame, position)
    local center = frame.AbsolutePosition + frame.AbsoluteSize / 2
    local half = frame.AbsoluteSize / 2

    return math.abs(position.X - center.X) <= half.X
        and math.abs(position.Y - center.Y) <= half.Y
end

local function SetFramePosition(frame, position, settingName)
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local newPosition = UDim2.new(
        math.clamp(position.X / viewport.X, 0.03, 0.97),
        0,
        math.clamp(position.Y / viewport.Y, 0.05, 0.95),
        0
    )

    if settingName == "Pursuit" then
        Settings.SensorPosition = newPosition
    elseif settingName == "AutoFire" then
        Settings.AutoFireSensorPosition = newPosition
    end

    frame.Position = newPosition
end

local function ConnectDraggableSensor(frame, isEnabled, isLocked, settingName)
    local dragging = false
    local activeInput
    local startPosition
    local origin

    UserInputService.InputBegan:Connect(function(input)
        if not isEnabled() then
            return
        end

        local touch = input.UserInputType == Enum.UserInputType.Touch
        local click = input.UserInputType == Enum.UserInputType.MouseButton1

        if not touch and not click then
            return
        end

        if not InsideFrame(frame, InputPosition(input)) then
            return
        end

        if isLocked() then
            if settingName == "Pursuit" then
                Settings.PursuitActive = not Settings.PursuitActive
                UpdateSensor()
            end
            return
        end

        dragging = true
        activeInput = input
        startPosition = InputPosition(input)
        origin = frame.AbsolutePosition + frame.AbsoluteSize / 2
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement

        if not isMouse and input ~= activeInput then
            return
        end

        local delta = InputPosition(input) - startPosition

        if delta.Magnitude > 3 then
            SetFramePosition(frame, origin + delta, settingName)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == activeInput
            or input.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging = false
            activeInput = nil
            startPosition = nil
            origin = nil
        end
    end)
end

ConnectDraggableSensor(
    Sensor,
    function() return Settings.Pursuit end,
    function() return Settings.SensorLocked end,
    "Pursuit"
)

ConnectDraggableSensor(
    AutoFireSensor,
    function() return Settings.AutoFire end,
    function() return Settings.AutoFireSensorLocked end,
    "AutoFire"
)

--==================================================
-- IA ASSIST
--==================================================

local AITab = CreateTab("IA ASSIST", 5)

local AIStatus = CreateInfo(AITab, "IA: INICIANDO...", 12, 30)
local TargetStatus = CreateInfo(AITab, "Alvo: nenhum", 44, 24)
local CivilStatus = CreateInfo(AITab, "Funcao: verificando", 70, 24)

AIEventStatus = CreateInfo(
    AITab,
    "Ultima deteccao: aguardando atividade",
    98,
    48
)

local NPCStatus = CreateInfo(AITab, "Bots detectados: 0", 148, 22)

CreateToggle(AITab, "RECUPERACAO INTELIGENTE", function(state)
    Settings.SmartRecovery = state

    SetAIEvent(state and "recuperacao inteligente ativada"
        or "recuperacao inteligente desativada")
end, 180, true)

CreateToggle(AITab, "PROTECAO AO VIRAR CIVIL", function(state)
    Settings.CivilProtection = state

    if state and IsCivil then
        Settings.PursuitActive = false
        Settings.Aimbot = false
        Settings.AutoFire = false
        CurrentTarget = nil

        UpdateSensor()
        UpdateAutoFireSensor()

        SetAIEvent("protecao ativada: funcao civil detectada")
    else
        SetAIEvent(state and "protecao civil ativada"
            or "protecao civil desativada")
    end
end, 220, true)

CreateInfo(
    AITab,
    "A IA monitora alvos, ESP, bots e protecao. Nao altera dano nem cargo.",
    260,
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

local AutoFireValue = Instance.new("BoolValue")
AutoFireValue.Name = "TalesAutoFireActive"
AutoFireValue.Value = false
AutoFireValue.Parent = GUI

--==================================================
-- SELECAO E DETECCAO DE ALVOS
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

local function IsPlayerSelected(target)
    if not Settings.PlayerSelectionEnabled then
        return true
    end

    if not target or not target:IsA("Player") then
        return false
    end

    return Settings.SelectedPlayers[target.UserId] == true
end

local function GetTargetScreenDistance(target)
    Camera = workspace.CurrentCamera

    if not Camera or not target or target == Player then
        return nil
    end

    if target:IsA("Player")
        and Settings.PlayerSelectionEnabled
        and not IsPlayerSelected(target) then
        return nil
    end

    if target:IsA("Model") and Settings.PlayerSelectionEnabled then
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
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)

    return (Vector2.new(point.X, point.Y) - center).Magnitude
end

local function IsTargetInRange(target)
    local distance = GetTargetScreenDistance(target)

    if not distance then
        return false
    end

    local limit = Settings.FOV and Settings.FOVSize or 300
    return distance <= limit
end

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

        if Settings.PlayerSelectionEnabled then
            if not target:IsA("Player") or not IsPlayerSelected(target) then
                return
            end
        end

        local distance = GetTargetScreenDistance(target)

        if distance and distance <= limit and distance < bestDistance then
            bestDistance = distance
            bestTarget = target
        end
    end

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then
            CheckTarget(target)
        end
    end

    if not Settings.PlayerSelectionEnabled then
        for _, model in ipairs(CachedNPCs) do
            if model and model.Parent and not IsPlayerCharacter(model) then
                CheckTarget(model)
            end
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
        SetAIEvent("troca estavel de alvo: " .. GetTargetName(bestTarget))
        return bestTarget
    end

    return CurrentTarget
end

--==================================================
-- DETECCAO INDEPENDENTE DO SENSOR AUTOFIRE
--==================================================

local function GetAutoFireCandidate()
    Camera = workspace.CurrentCamera

    if not Camera
        or not Settings.AutoFire
        or not AutoFireSensor.Visible
        or not CombatAllowed() then
        return nil
    end

    local center = AutoFireSensor.AbsolutePosition
        + AutoFireSensor.AbsoluteSize / 2

    local radius = math.min(
        AutoFireSensor.AbsoluteSize.X,
        AutoFireSensor.AbsoluteSize.Y
    ) / 2

    local bestTarget = nil
    local bestCharacter = nil
    local bestHead = nil
    local bestDistance = math.huge

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player and IsPlayerSelected(target) then
            local character = target.Character
            local head = character and character:FindFirstChild("Head")

            if character
                and IsAlive(character)
                and head
                and head:IsA("BasePart") then

                local point, onScreen = Camera:WorldToViewportPoint(head.Position)

                if onScreen and point.Z > 0 then
                    local screenPoint = Vector2.new(point.X, point.Y)
                    local distance = (screenPoint - center).Magnitude

                    if distance <= radius
                        and distance < bestDistance
                        and HasClearHeadLineOfSight(character, head) then

                        bestDistance = distance
                        bestTarget = target
                        bestCharacter = character
                        bestHead = head
                    end
                end
            end
        end
    end

    return bestTarget, bestCharacter, bestHead
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
            AutoFireValue.Value = false

            UpdateSensor()
            UpdateAutoFireSensor()
        end)
    end
end

Player.CharacterAdded:Connect(BindLocalCharacter)

Player.CharacterRemoving:Connect(function()
    Settings.PursuitActive = false
    CurrentTarget = nil

    TargetValue.Value = nil
    PursuitValue.Value = false
    AutoFireValue.Value = false

    UpdateSensor()
    UpdateAutoFireSensor()
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
        SetAIEvent(IsCivil and "funcao civil detectada"
            or "funcao civil nao detectada")
    end

    if IsCivil and Settings.CivilProtection then
        Settings.PursuitActive = false
        Settings.Aimbot = false
        Settings.AutoFire = false
        CurrentTarget = nil

        UpdateSensor()
        UpdateAutoFireSensor()
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
local headVisibilityTimer = 0
local autoFireTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    Camera = workspace.CurrentCamera

    if Camera then
        local viewport = Camera.ViewportSize

        FOVCircle.Position = UDim2.fromOffset(
            viewport.X * 0.5,
            viewport.Y * 0.5
        )
    end

    npcTimer += deltaTime

    if npcTimer >= 0.60 then
        npcTimer = 0
        RefreshNPCs()

        if Settings.ESPBots or Settings.ESPPlayers then
            UpdateESP()
        end
    end

    espTimer += deltaTime

    if Settings.SmartRecovery and espTimer >= 0.40 then
        espTimer = 0

        if Settings.ESPPlayers or Settings.ESPBots then
            UpdateESP()
        end
    end

    headVisibilityTimer += deltaTime

    if headVisibilityTimer >= 0.10 then
        headVisibilityTimer = 0
        UpdateAllPlayerHeadHighlights()
    end

    IsCivil = IsLocalPlayerCivil()
    CivilValue.Value = IsCivil

    local wantsAim = Settings.Aimbot
        and Settings.Target ~= nil
        and CombatAllowed()

    local wantsPursuit = Settings.Pursuit
        and Settings.PursuitActive
        and CombatAllowed()

    local wantsAutoFire = Settings.AutoFire
        and CombatAllowed()

    -- O alvo compartilhado continua sendo usado pelo Aimbot
    -- e pela perseguicao. O AutoFire faz sua propria busca.

    if wantsAim or wantsPursuit then
        local previousTarget = CurrentTarget
        CurrentTarget = GetStableTarget()

        if CurrentTarget and CurrentTarget ~= previousTarget then
            SetAIEvent("alvo localizado: " .. GetTargetName(CurrentTarget))
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
    local targetPart = targetCharacter and GetTargetPart(targetCharacter)

    if not targetPart or not IsAlive(targetCharacter) then
        CurrentTarget = nil
        targetCharacter = nil
        targetPart = nil
    end

    --==================================================
    -- TIRO AUTOMATICO INDEPENDENTE DO AIMBOT
    --==================================================

    autoFireTimer += deltaTime

    local autoFireReady = false
    local autoFireTarget = nil
    local autoFireCharacter = nil
    local autoFireHead = nil
    local equippedTool = nil

    if not Settings.AutoFire then
        autoFireTimer = 0
        SetAutoFireSensorState("OFF", "Tiro automatico desligado")

    elseif not CombatAllowed() then
        autoFireTimer = 0
        SetAutoFireSensorState("OFF", "Protecao civil ativa")

    else
        autoFireTarget, autoFireCharacter, autoFireHead =
            GetAutoFireCandidate()

        if not autoFireTarget then
            autoFireTimer = 0
            SetAutoFireSensorState(
                "SEARCH",
                "BUSCANDO: coloque um player dentro do sensor"
            )
        else
            local localCharacter = Player.Character

            if localCharacter then
                equippedTool = localCharacter:FindFirstChildOfClass("Tool")
            end

            local toolIsReady = equippedTool ~= nil
                and equippedTool.Parent == localCharacter
                and equippedTool.Enabled == true

            if not toolIsReady then
                autoFireTimer = 0
                SetAutoFireSensorState(
                    "SEARCH",
                    "ALVO VISIVEL: equipe uma ferramenta"
                )

            elseif not IsAlive(autoFireCharacter) then
                autoFireTimer = 0
                SetAutoFireSensorState(
                    "SEARCH",
                    "Alvo eliminado ou indisponivel"
                )

            elseif not autoFireHead
                or not HasClearHeadLineOfSight(
                    autoFireCharacter,
                    autoFireHead
                ) then

                autoFireTimer = 0
                SetAutoFireSensorState(
                    "SEARCH",
                    "Alvo sem linha de visao"
                )

            else
                autoFireReady = true

                SetAutoFireSensorState(
                    "READY",
                    "ALVO VISIVEL: " .. GetTargetName(autoFireTarget)
                )

                if autoFireTimer >= 0.18 then
                    autoFireTimer = 0

                    local activated, activationError = pcall(function()
                        equippedTool:Activate()
                    end)

                    if activated then
                        SetAIEvent(
                            "Ativacao solicitada: "
                            .. GetTargetName(autoFireTarget)
                        )
                    else
                        autoFireReady = false

                        SetAutoFireSensorState(
                            "OFF",
                            "Erro na ferramenta: "
                                .. tostring(activationError)
                        )

                        SetAIEvent("Falha na ativacao da ferramenta")
                    end
                end
            end
        end
    end

    AutoFireValue.Value = autoFireReady

    --==================================================
    -- ASSISTENCIA ORIGINAL DE CAMERA
    --==================================================

    if wantsAim and targetPart and Camera then
        local cameraPosition = Camera.CFrame.Position

        local desired = CFrame.lookAt(
            cameraPosition,
            targetPart.Position
        )

        local smooth = math.clamp(Settings.AimSmoothness, 0, 1)

        local alpha = smooth <= 0 and 0
            or (
                smooth >= 1 and 1
                or 1 - math.pow(
                    1 - smooth,
                    math.max(deltaTime * 60, 0.01)
                )
            )

        if alpha > 0 then
            Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
        end
    end

    TargetValue.Value = targetCharacter
    TargetPartValue.Value = Settings.Target or ""
    PursuitValue.Value = wantsPursuit

    --==================================================
    -- IA ASSIST
    --==================================================

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
        elseif wantsAim or wantsPursuit or wantsAutoFire then
            LastAIStatus = "PROCURANDO ALVO"
        elseif Settings.ESPPlayers or Settings.ESPBots then
            LastAIStatus = "MONITORANDO ESP"
        else
            LastAIStatus = "MONITORANDO SISTEMAS"
        end

        AIStatus.Text = "IA: " .. LastAIStatus
        TargetStatus.Text = "Alvo: " .. GetTargetName(CurrentTarget)

        CivilStatus.Text = IsCivil
            and "Funcao: CIVIL detectado"
            or "Funcao: nao identificada como civil"

        NPCStatus.Text = "Bots detectados: " .. tostring(#CachedNPCs)

        ESPInfo.Text = "Players: "
            .. tostring(#Players:GetPlayers() - 1)
            .. " | Bots: "
            .. tostring(#CachedNPCs)
            .. " | Recuperacao: "
            .. (Settings.SmartRecovery and "ON" or "OFF")

        SelectionInfo.Text = Settings.PlayerSelectionEnabled
            and ("Selecao ativa: "
                .. tostring(CountSelectedPlayers())
                .. " player(s)")
            or "Selecao desativada: todos os alvos elegiveis"
    end
end)

--==================================================
-- INICIALIZACAO
--==================================================

RefreshNPCs()
RefreshPlayerSelectionList()
UpdateSensor()
UpdateAutoFireSensor()
UpdateCivilStatus()

print("Tales Mod Menu IA Assist carregado.")
print("ESP Player azul + Name: pronto.")
print("ESP Bot amarelo com nome BOT: pronto.")
print("Selecao de players por checkbox: pronta.")
print("Busca de alvos do Aimbot e perseguicao: pronta.")
print("Busca independente do sensor AutoFire: pronta.")
print("Sensor AutoFire com estado de prontidao: pronto.")
print("Painel reduzido e minimizacao: pronto.")
