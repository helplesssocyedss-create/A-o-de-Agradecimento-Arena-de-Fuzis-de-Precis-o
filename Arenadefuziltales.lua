-- TALES MOD MENU
-- Feito por Tales

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local BLUE = Color3.fromRGB(0, 170, 255)

local Settings = {
    ESP = false,
    Aimbot = false,
    Target = nil,
    FOV = false,
    FOVSize = 120
}

local CurrentTarget = nil
local ESPObjects = {}

-- LIMPAR MENU ANTIGO
local Old = PlayerGui:FindFirstChild("TalesModMenu")
if Old then
    Old:Destroy()
end

-- INTERFACE
local GUI = Instance.new("ScreenGui")
GUI.Name = "TalesModMenu"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(460, 320)
Main.Position = UDim2.new(0.5, -230, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Main.BorderSizePixel = 0
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "TALES | MOD MENU"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 30)
Minimize.Position = UDim2.new(1, -42, 0, 7)
Minimize.Text = "-"
Minimize.Parent = Main

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 125, 1, -85)
Sidebar.Position = UDim2.fromOffset(10, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(29, 32, 43)
Sidebar.Parent = Main

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -150, 1, -85)
Content.Position = UDim2.fromOffset(140, 50)
Content.BackgroundColor3 = Color3.fromRGB(29, 32, 43)
Content.Parent = Main

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
    Button.Position = UDim2.fromOffset(5, #Tabs * 43 + 5)
    Button.Text = Name
    Button.Parent = Sidebar

    Button.MouseButton1Click:Connect(function()
        for _, Tab in ipairs(Tabs) do
            Tab.Visible = false
        end

        for _, B in ipairs(TabButtons) do
            B.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
        end

        Page.Visible = true
        Button.BackgroundColor3 = Color3.fromRGB(25, 125, 75)
    end)

    table.insert(Tabs, Page)
    table.insert(TabButtons, Button)

    if #Tabs == 1 then
        Page.Visible = true
    end

    return Page
end

local function CreateButton(Parent, Text, Y, Callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 38)
    Button.Position = UDim2.fromOffset(10, Y)
    Button.Text = Text
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.BackgroundColor3 = Color3.fromRGB(65, 70, 85)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 13
    Button.Parent = Parent

    Instance.new("UICorner", Button)

    Button.MouseButton1Click:Connect(Callback)

    return Button
end

local function CreateToggle(Parent, Name, Y, Callback)
    local Enabled = false

    local Button = CreateButton(
        Parent,
        Name .. " : OFF",
        Y,
        function()
            Enabled = not Enabled

            Button.Text = Name .. (Enabled and " : ON" or " : OFF")

            Button.BackgroundColor3 = Enabled
                and Color3.fromRGB(20, 170, 85)
                or Color3.fromRGB(65, 70, 85)

            Callback(Enabled)
        end
    )

    return Button
end

-- AIMBOT
local AimTab = CreateTab("AIMBOT")

local Prompt = Instance.new("TextLabel")
Prompt.Size = UDim2.new(1, -20, 0, 30)
Prompt.Position = UDim2.fromOffset(10, 60)
Prompt.BackgroundTransparency = 1
Prompt.TextColor3 = Color3.new(1, 1, 1)
Prompt.Text = "Selecione a opção desejada:"
Prompt.Visible = false
Prompt.Parent = AimTab

local HeadButton
local ChestButton

local function SelectTarget(Name)
    Settings.Target = Name

    Prompt.Text = "Selecionado: " .. Name

    HeadButton.Visible = false
    ChestButton.Visible = false
end

CreateToggle(AimTab, "AIMBOT", 15, function(State)
    Settings.Aimbot = State

    if State then
        Settings.Target = nil
        Prompt.Text = "Selecione a opção desejada:"
        Prompt.Visible = true
        HeadButton.Visible = true
        ChestButton.Visible = true
    else
        Settings.Target = nil
        Prompt.Visible = false
        HeadButton.Visible = false
        ChestButton.Visible = false
    end
end)

HeadButton = CreateButton(
    AimTab,
    "AIMBOT CABEÇA",
    100,
    function()
        SelectTarget("Cabeça")
    end
)

ChestButton = CreateButton(
    AimTab,
    "AIMBOT PEITO",
    145,
    function()
        SelectTarget("Peito")
    end
)

HeadButton.Visible = false
ChestButton.Visible = false

-- ESP
local EspTab = CreateTab("ESP")

local function RemoveESP(Target)
    local Objects = ESPObjects[Target]

    if Objects then
        if Objects.Highlight then
            Objects.Highlight:Destroy()
        end

        if Objects.Billboard then
            Objects.Billboard:Destroy()
        end

        ESPObjects[Target] = nil
    end
end

local function AddESP(Target)
    if Target == Player then return end

    local Character = Target.Character
    if not Character then return end

    local Head = Character:FindFirstChild("Head")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if not Head or not Humanoid then return end

    local Existing = ESPObjects[Target]

    if Existing and Existing.Character == Character then
        return
    end

    RemoveESP(Target)

    local Highlight = Instance.new("Highlight")
    Highlight.Adornee = Character
    Highlight.FillColor = BLUE
    Highlight.OutlineColor = BLUE
    Highlight.FillTransparency = 0.82
    Highlight.OutlineTransparency = 0
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Parent = workspace

    local Billboard = Instance.new("BillboardGui")
    Billboard.Adornee = Head
    Billboard.Size = UDim2.fromOffset(180, 30)
    Billboard.StudsOffset = Vector3.new(0, 2.7, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = PlayerGui

    local Name = Instance.new("TextLabel")
    Name.Size = UDim2.fromScale(1, 1)
    Name.BackgroundTransparency = 1
    Name.Text = Target.DisplayName
    Name.TextColor3 = BLUE
    Name.TextStrokeTransparency = 0.1
    Name.TextSize = 13
    Name.Font = Enum.Font.GothamBold
    Name.Parent = Billboard

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

    for Target in pairs(ESPObjects) do
        if Target.Parent ~= Players then
            RemoveESP(Target)
        end
    end
end

CreateToggle(EspTab, "ESP PLAYER", 15, function(State)
    Settings.ESP = State

    if not State then
        for Target in pairs(ESPObjects) do
            RemoveESP(Target)
        end
    else
        UpdateESP()
    end
end)

Players.PlayerAdded:Connect(function(Target)
    Target.CharacterAdded:Connect(function()
        task.wait(1)

        if Settings.ESP then
            AddESP(Target)
        end
    end)
end)

Players.PlayerRemoving:Connect(RemoveESP)

-- AIM FOV
local FovTab = CreateTab("AIM FOV")

local Circle = Instance.new("Frame")
Circle.Name = "TalesFOV"
Circle.AnchorPoint = Vector2.new(0.5, 0.5)
Circle.Size = UDim2.fromOffset(240, 240)
Circle.BackgroundTransparency = 1
Circle.Visible = false
Circle.Parent = GUI

Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

local Stroke = Instance.new("UIStroke")
Stroke.Color = BLUE
Stroke.Thickness = 1.5
Stroke.Parent = Circle

CreateToggle(FovTab, "AIM FOV", 15, function(State)
    Settings.FOV = State
    Circle.Visible = State
end)

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, -20, 0, 30)
SizeLabel.Position = UDim2.fromOffset(10, 65)
SizeLabel.BackgroundTransparency = 1
SizeLabel.TextColor3 = Color3.new(1, 1, 1)
SizeLabel.Text = "Tamanho: 120"
SizeLabel.Parent = FovTab

CreateButton(FovTab, "AUMENTAR +", 105, function()
    Settings.FOVSize = math.clamp(Settings.FOVSize + 20, 40, 300)

    Circle.Size = UDim2.fromOffset(
        Settings.FOVSize * 2,
        Settings.FOVSize * 2
    )

    SizeLabel.Text = "Tamanho: " .. Settings.FOVSize
end)

CreateButton(FovTab, "DIMINUIR -", 150, function()
    Settings.FOVSize = math.clamp(Settings.FOVSize - 20, 40, 300)

    Circle.Size = UDim2.fromOffset(
        Settings.FOVSize * 2,
        Settings.FOVSize * 2
    )

    SizeLabel.Text = "Tamanho: " .. Settings.FOVSize
end)

local function GetTargetPart(Character)
    if Settings.Target == "Cabeça" then
        return Character:FindFirstChild("Head")
    end

    if Settings.Target == "Peito" then
        return Character:FindFirstChild("UpperTorso")
            or Character:FindFirstChild("Torso")
            or Character:FindFirstChild("HumanoidRootPart")
    end
end

local function GetClosestTarget()
    Camera = workspace.CurrentCamera

    if not Camera or not Settings.Target then
        return nil
    end

    local Viewport = Camera.ViewportSize

    local Center = Vector2.new(
        Viewport.X / 2,
        Viewport.Y / 2
    )

    local BestTarget = nil
    local BestDistance = Settings.FOVSize

    for _, Target in ipairs(Players:GetPlayers()) do
        if Target ~= Player then
            local Character = Target.Character

            if Character then
                local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                local Part = GetTargetPart(Character)

                if Humanoid and Humanoid.Health > 0 and Part then
                    local Position, OnScreen =
                        Camera:WorldToViewportPoint(Part.Position)

                    if OnScreen and Position.Z > 0 then
                        local Distance = (
                            Vector2.new(Position.X, Position.Y) - Center
                        ).Magnitude

                        if Distance <= BestDistance then
                            BestDistance = Distance
                            BestTarget = Target
                        end
                    end
                end
            end
        end
    end

    return BestTarget
end

local TargetValue = Instance.new("ObjectValue")
TargetValue.Name = "TalesCurrentTarget"
TargetValue.Parent = GUI

local TargetPartValue = Instance.new("StringValue")
TargetPartValue.Name = "TalesTargetPart"
TargetPartValue.Parent = GUI

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera

    if Camera then
        local Viewport = Camera.ViewportSize

        Circle.Position = UDim2.fromOffset(
            Viewport.X / 2,
            Viewport.Y / 2
        )
    end

    if Settings.ESP then
        UpdateESP()
    end

    if Settings.Aimbot and Settings.FOV and Settings.Target then
        CurrentTarget = GetClosestTarget()
    else
        CurrentTarget = nil
    end

    TargetValue.Value = CurrentTarget
        and CurrentTarget.Character
        or nil

    TargetPartValue.Value = Settings.Target or ""
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
Credits.Parent = Main

print("Tales Mod Menu carregado com sucesso!")
