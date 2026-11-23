--[[
    TALES MOD MENU
    Feito por Tales
    Roblox Studio - LuaU
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- LIMPAR VERSÃO ANTERIOR
local OldGUI = PlayerGui:FindFirstChild("TalesModMenu")
if OldGUI then
    OldGUI:Destroy()
end

-- CONFIGURAÇÕES
local Settings = {
    Aimbot = false,
    Target = "Cabeça",
    ESP = false,
    FOV = false,
    FOVSize = 120
}

local CurrentTarget = nil
local ESPObjects = {}

-- GUI PRINCIPAL
local GUI = Instance.new("ScreenGui")
GUI.Name = "TalesModMenu"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(460, 320)
Main.Position = UDim2.new(0.5, -230, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Main.BorderSizePixel = 0
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- TÍTULO
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -55, 0, 45)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "TALES | MOD MENU"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

-- MINIMIZAR
local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 30)
Minimize.Position = UDim2.new(1, -42, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 22
Minimize.Parent = Main

Instance.new("UICorner", Minimize)

-- MENU LATERAL
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 125, 1, -85)
Sidebar.Position = UDim2.fromOffset(10, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(29, 32, 43)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

Instance.new("UICorner", Sidebar)

-- ÁREA DAS CATEGORIAS
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -150, 1, -85)
Content.Position = UDim2.fromOffset(140, 50)
Content.BackgroundColor3 = Color3.fromRGB(29, 32, 43)
Content.BorderSizePixel = 0
Content.Parent = Main

Instance.new("UICorner", Content)

-- SISTEMA DE ABAS
local Tabs = {}
local TabButtons = {}

local function CreateTab(Name)
    local Page = Instance.new("Frame")
    Page.Name = Name
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = Content

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 38)
    Button.Position = UDim2.fromOffset(5, (#Tabs * 43) + 5)
    Button.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Text = Name
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Sidebar

    Instance.new("UICorner", Button)

    Button.MouseButton1Click:Connect(function()
        for _, Tab in ipairs(Tabs) do
            Tab.Visible = false
        end

        for _, TabButton in ipairs(TabButtons) do
            TabButton.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
        end

        Page.Visible = true
        Button.BackgroundColor3 = Color3.fromRGB(25, 125, 75)
    end)

    table.insert(Tabs, Page)
    table.insert(TabButtons, Button)

    if #Tabs == 1 then
        Page.Visible = true
        Button.BackgroundColor3 = Color3.fromRGB(25, 125, 75)
    end

    return Page
end

-- SISTEMA ON/OFF
local function CreateToggle(Parent, Name, Callback, Y)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 38)
    Button.Position = UDim2.fromOffset(10, Y)
    Button.BackgroundColor3 = Color3.fromRGB(75, 78, 90)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.Text = Name .. " : OFF"
    Button.Parent = Parent

    Instance.new("UICorner", Button)

    local Enabled = false

    Button.MouseButton1Click:Connect(function()
        Enabled = not Enabled

        Button.Text = Name .. (Enabled and " : ON" or " : OFF")

        Button.BackgroundColor3 = Enabled
            and Color3.fromRGB(20, 170, 85)
            or Color3.fromRGB(75, 78, 90)

        Callback(Enabled)
    end)

    return Button
end

-- BOTÕES DE OPÇÃO
local function CreateOption(Parent, Name, Y, Callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 35)
    Button.Position = UDim2.fromOffset(10, Y)
    Button.BackgroundColor3 = Color3.fromRGB(45, 95, 150)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Text = Name
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Parent

    Instance.new("UICorner", Button)
    Button.MouseButton1Click:Connect(Callback)

    return Button
end

-- AIMBOT
local AimTab = CreateTab("AIMBOT")

CreateToggle(AimTab, "AIMBOT", function(State)
    Settings.Aimbot = State
    if not State then
        CurrentTarget = nil
    end
end, 15)

local HeadOption = CreateOption(AimTab, "ALVO: CABEÇA", 65, function()
    Settings.Target = "Cabeça"
end)

local ChestOption = CreateOption(AimTab, "ALVO: PEITO", 110, function()
    Settings.Target = "Peito"
end)

-- ESP
local EspTab = CreateTab("ESP")

local function RemoveESP(Target)
    local Object = ESPObjects[Target]

    if Object then
        if Object.Highlight then
            Object.Highlight:Destroy()
        end

        if Object.Billboard then
            Object.Billboard:Destroy()
        end

        ESPObjects[Target] = nil
    end
end

local function AddESP(Target)
    if Target == Player then
        return
    end

    local Character = Target.Character
    if not Character then
        return
    end

    local Head = Character:FindFirstChild("Head")
    if not Head then
        return
    end

    -- Não recriar se já estiver aplicado no personagem atual
    if ESPObjects[Target]
        and ESPObjects[Target].Character == Character then
        return
    end

    RemoveESP(Target)

    -- CONTORNO HOLOGRÁFICO
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "TalesESP"
    Highlight.Adornee = Character
    Highlight.FillColor = Color3.fromRGB(0, 100, 255)
    Highlight.OutlineColor = Color3.fromRGB(0, 200, 255)
    Highlight.FillTransparency = 0.85
    Highlight.OutlineTransparency = 0
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    -- O Highlight fica no Workspace para ser renderizado corretamente
    Highlight.Parent = workspace

    -- NOME DO JOGADOR
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "TalesESPName"
    Billboard.Adornee = Head
    Billboard.Size = UDim2.fromOffset(150, 30)
    Billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = PlayerGui

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.fromScale(1, 1)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = Target.DisplayName
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextStrokeTransparency = 0
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.Parent = Billboard

    ESPObjects[Target] = {
        Character = Character,
        Highlight = Highlight,
        Billboard = Billboard
    }
end

local function UpdateESP()
    for _, Target in ipairs(Players:GetPlayers()) do
        if Target ~= Player then
            if Settings.ESP then
                AddESP(Target)
            else
                RemoveESP(Target)
            end
        end
    end
end

CreateToggle(EspTab, "ESP PLAYER", function(State)
    Settings.ESP = State

    if State then
        UpdateESP()
    else
        for Target in pairs(ESPObjects) do
            RemoveESP(Target)
        end
    end
end, 15)

-- JOGADORES EXISTENTES E NOVOS
local function SetupPlayer(Target)
    if Target == Player then
        return
    end

    Target.CharacterAdded:Connect(function()
        task.wait(0.5)

        if Settings.ESP then
            AddESP(Target)
        end
    end)

    if Settings.ESP then
        AddESP(Target)
    end
end

for _, Target in ipairs(Players:GetPlayers()) do
    SetupPlayer(Target)
end

Players.PlayerAdded:Connect(SetupPlayer)

Players.PlayerRemoving:Connect(function(Target)
    RemoveESP(Target)
end)

-- AIM FOV
local FovTab = CreateTab("AIM FOV")

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "TalesFOV"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(240, 240)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.Parent = GUI

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 1.5
CircleStroke.Color = Color3.fromRGB(0, 200, 255)
CircleStroke.Parent = FOVCircle

CreateToggle(FovTab, "AIM FOV", function(State)
    Settings.FOV = State
    FOVCircle.Visible = State

    if not State then
        CurrentTarget = nil
    end
end, 15)

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, -20, 0, 30)
SizeLabel.Position = UDim2.fromOffset(10, 65)
SizeLabel.BackgroundTransparency = 1
SizeLabel.TextColor3 = Color3.new(1, 1, 1)
SizeLabel.Text = "Tamanho: 120"
SizeLabel.TextSize = 14
SizeLabel.Font = Enum.Font.GothamBold
SizeLabel.Parent = FovTab

local function ChangeFOV(Value)
    Settings.FOVSize = math.clamp(
        Settings.FOVSize + Value,
        40,
        300
    )

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

-- SELEÇÃO DO ALVO DENTRO DO FOV
local function GetTargetPart(Character)
    if Settings.Target == "Cabeça" then
        return Character:FindFirstChild("Head")
    end

    return Character:FindFirstChild("UpperTorso")
        or Character:FindFirstChild("Torso")
end

local function GetClosestTarget()
    if not Camera then
        return nil
    end

    local Viewport = Camera.ViewportSize
    local ScreenCenter = Vector2.new(
        Viewport.X / 2,
        Viewport.Y / 2
    )

    local ClosestPlayer = nil
    local ClosestDistance = Settings.FOVSize

    for _, Target in ipairs(Players:GetPlayers()) do
        if Target ~= Player then
            local Character = Target.Character
            local Humanoid = Character
                and Character:FindFirstChildOfClass("Humanoid")

            local Part = Character and GetTargetPart(Character)

            if Humanoid and Humanoid.Health > 0 and Part then
                local ScreenPosition, OnScreen =
                    Camera:WorldToViewportPoint(Part.Position)

                if OnScreen and ScreenPosition.Z > 0 then
                    local Distance = (
                        Vector2.new(ScreenPosition.X, ScreenPosition.Y)
                        - ScreenCenter
                    ).Magnitude

                    if Distance <= ClosestDistance then
                        ClosestDistance = Distance
                        ClosestPlayer = Target
                    end
                end
            end
        end
    end

    return ClosestPlayer
end

-- ATUALIZAÇÃO
RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera

    -- Atualizar posição do círculo no centro da tela
    if Camera then
        FOVCircle.Position = UDim2.fromOffset(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )
    end

    -- Atualizar seleção de alvo
    if Settings.Aimbot and Settings.FOV then
        CurrentTarget = GetClosestTarget()
    else
        CurrentTarget = nil
    end

    -- Atualizar ESP
    if Settings.ESP then
        UpdateESP()
    end
end)

-- MINIMIZAR
local Minimized = false

Minimize.MouseButton1Click:Connect(function()
    Minimized = not Minimized

    Sidebar.Visible = not Minimized
    Content.Visible = not Minimized

    Main.Size = Minimized
        and UDim2.fromOffset(460, 45)
        or UDim2.fromOffset(460, 320)

    Minimize.Text = Minimized and "+" or "-"
end)

-- CRÉDITOS
local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 0, 20)
Credits.Position = UDim2.new(0, 0, 1, -23)
Credits.BackgroundTransparency = 1
Credits.Text = "Feito por Tales"
Credits.TextColor3 = Color3.fromRGB(130, 140, 160)
Credits.TextSize = 12
Credits.Font = Enum.Font.Gotham
Credits.Parent = Main

-- REFERÊNCIA PARA INTEGRAÇÃO COM A ARMA
-- Outros LocalScripts do seu jogo podem consultar o alvo selecionado
local TargetValue = Instance.new("ObjectValue")
TargetValue.Name = "TalesCurrentTarget"
TargetValue.Parent = GUI

RunService.RenderStepped:Connect(function()
    if CurrentTarget then
        TargetValue.Value = CurrentTarget.Character
    else
        TargetValue.Value = nil
    end
end)

print("Tales Mod Menu carregado com sucesso!")
