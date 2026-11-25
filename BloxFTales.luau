--========================================
--           BLOX F' - TALES
--              VERSION 2.0
--========================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local C = {
    Background = Color3.fromRGB(15,15,23),
    Panel = Color3.fromRGB(25,25,37),
    Purple = Color3.fromRGB(135,65,220),
    Green = Color3.fromRGB(40,210,110),
    Gray = Color3.fromRGB(75,75,85),
    White = Color3.fromRGB(255,255,255)
}

local Screen = Instance.new("ScreenGui")
Screen.Name = "BloxFTales"
Screen.ResetOnSpawn = false
Screen.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(650,440)
Main.Position = UDim2.new(.5,-325,.5,-220)
Main.BackgroundColor3 = C.Background
Main.BorderSizePixel = 0
Main.Parent = Screen

Instance.new("UICorner",Main).CornerRadius =
    UDim.new(0,12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = C.Purple
Stroke.Thickness = 2
Stroke.Parent = Main

-- CABEÇALHO

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,55)
Header.BackgroundColor3 = Color3.fromRGB(38,25,58)
Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new("UICorner",Header).CornerRadius =
    UDim.new(0,12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-100,1,0)
Title.Position = UDim2.fromOffset(15,0)
Title.BackgroundTransparency = 1
Title.Text = "Blox F’ - Tales"
Title.TextColor3 = C.White
Title.TextSize = 23
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- FECHAR

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(35,35)
Close.Position = UDim2.new(1,-45,0,10)
Close.BackgroundColor3 = Color3.fromRGB(190,50,65)
Close.Text = "X"
Close.TextColor3 = C.White
Close.Font = Enum.Font.GothamBold
Close.Parent = Header

Instance.new("UICorner",Close).CornerRadius =
    UDim.new(0,8)

Close.MouseButton1Click:Connect(function()
    Screen:Destroy()
end)

-- MINIMIZAR

local Min = Instance.new("TextButton")
Min.Size = UDim2.fromOffset(35,35)
Min.Position = UDim2.new(1,-85,0,10)
Min.BackgroundColor3 = C.Purple
Min.Text = "-"
Min.TextColor3 = C.White
Min.Font = Enum.Font.GothamBold
Min.Parent = Header

Instance.new("UICorner",Min).CornerRadius =
    UDim.new(0,8)

local minimized = false

Min.MouseButton1Click:Connect(function()
    minimized = not minimized

    Main:TweenSize(
        minimized and UDim2.fromOffset(650,55)
        or UDim2.fromOffset(650,440),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        .25,
        true
    )
end)

-- ARRASTAR JANELA

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- MENU LATERAL

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,155,1,-70)
Sidebar.Position = UDim2.fromOffset(10,65)
Sidebar.BackgroundColor3 = C.Panel
Sidebar.Parent = Main

Instance.new("UICorner",Sidebar).CornerRadius =
    UDim.new(0,10)

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0,7)
TabLayout.HorizontalAlignment =
    Enum.HorizontalAlignment.Center
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = Sidebar

-- CONTEÚDO

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1,-185,1,-75)
Content.Position = UDim2.fromOffset(175,65)
Content.BackgroundColor3 = C.Panel
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = C.Purple
Content.CanvasSize = UDim2.new(0,0,0,0)
Content.Parent = Main

Instance.new("UICorner",Content).CornerRadius =
    UDim.new(0,10)

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0,9)
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Content

List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(
        0,0,0,List.AbsoluteContentSize.Y+15
    )
end)

-- ESTADOS

local States = {}

-- BOTÕES DESLIZANTES

local function Toggle(name,callback)

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1,-18,0,45)
    Row.BackgroundColor3 = C.Background
    Row.Parent = Content

    Instance.new("UICorner",Row).CornerRadius =
        UDim.new(0,8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1,-85,1,0)
    Label.Position = UDim2.fromOffset(12,0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = C.White
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.fromOffset(48,24)
    Switch.Position = UDim2.new(1,-60,.5,-12)
    Switch.BackgroundColor3 = C.Gray
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = Row

    Instance.new("UICorner",Switch).CornerRadius =
        UDim.new(1,0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.fromOffset(18,18)
    Circle.Position = UDim2.fromOffset(3,3)
    Circle.BackgroundColor3 = C.White
    Circle.Parent = Switch

    Instance.new("UICorner",Circle).CornerRadius =
        UDim.new(1,0)

    States[name] = false

    Switch.MouseButton1Click:Connect(function()

        States[name] = not States[name]

        local active = States[name]

        TweenService:Create(
            Switch,
            TweenInfo.new(.2),
            {
                BackgroundColor3 =
                    active and C.Green or C.Gray
            }
        ):Play()

        TweenService:Create(
            Circle,
            TweenInfo.new(.2),
            {
                Position = active
                    and UDim2.fromOffset(27,3)
                    or UDim2.fromOffset(3,3)
            }
        ):Play()

        if callback then
            callback(active)
        end
    end)

    return Row
end

-- SELEÇÃO DE JOGADORES

local function PlayerSelector()

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1,-18,0,35)
    Label.BackgroundTransparency = 1
    Label.Text = "Selecionar jogador:"
    Label.TextColor3 = C.White
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    Label.Parent = Content

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player then

            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1,-18,0,38)
            Button.BackgroundColor3 = C.Background
            Button.Text = target.DisplayName ..
                " (@" .. target.Name .. ")"
            Button.TextColor3 = C.White
            Button.Font = Enum.Font.Gotham
            Button.TextSize = 13
            Button.Parent = Content

            Instance.new("UICorner",Button).CornerRadius =
                UDim.new(0,8)

            Button.MouseButton1Click:Connect(function()
                print("Jogador selecionado:",target.Name)
            end)
        end
    end
end

-- VELOCIDADE LOCAL

local function SpeedControl()

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1,-18,0,40)
    Box.BackgroundColor3 = C.Background
    Box.PlaceholderText = "Digite a velocidade (16 padrão)"
    Box.Text = ""
    Box.TextColor3 = C.White
    Box.PlaceholderColor3 = C.Gray
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 13
    Box.Parent = Content

    Instance.new("UICorner",Box).CornerRadius =
        UDim.new(0,8)

    Box.FocusLost:Connect(function()

        local value = tonumber(Box.Text)

        local character = Player.Character
        local humanoid = character and
            character:FindFirstChildOfClass("Humanoid")

        if value and humanoid then
            humanoid.WalkSpeed = math.clamp(value,0,100)
        end
    end)
end

-- CATEGORIAS

local Categories = {
    "Início",
    "Combate",
    "Frutas",
    "Jogador",
    "Teletransporte",
    "Coleta e evolução",
    "Visualização",
    "Configurações"
}

local Options = {

    ["Combate"] = {
        "Mira assistida",
        "Área de acerto visual",
        "Haki automático",
        "Habilidades automáticas",
        "Ataque automático"
    },

    ["Frutas"] = {
        "Localizador de frutas",
        "Detector de frutas"
    },

    ["Jogador"] = {
        "Voar",
        "Pulo infinito",
        "Atravessar paredes"
    },

    ["Teletransporte"] = {
        "Teletransporte para ilhas",
        "Teletransporte para personagens",
        "Teletransporte para jogadores",
        "Mostrar coordenadas"
    },

    ["Coleta e evolução"] = {
        "Coleta automática",
        "Missões automáticas",
        "Evolução automática",
        "Coleta de recompensas"
    },

    ["Visualização"] = {
        "Destacar jogadores",
        "Destacar inimigos",
        "Destacar frutas",
        "Destacar baús",
        "Mostrar nomes",
        "Mostrar distâncias"
    },

    ["Configurações"] = {
        "Animações",
        "Tema personalizado",
        "Transparência",
        "Salvar configurações"
    }
}

-- ABRIR CATEGORIA

local function ShowCategory(category)

    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA("Frame")
        or child:IsA("TextLabel")
        or child:IsA("TextButton")
        or child:IsA("TextBox") then
            child:Destroy()
        end
    end

    if category == "Início" then

        local Welcome = Instance.new("TextLabel")
        Welcome.Size = UDim2.new(1,-18,0,60)
        Welcome.BackgroundTransparency = 1
        Welcome.Text = "Bem-vindo ao Blox F’ - Tales!\nJogador: " ..
            Player.Name
        Welcome.TextColor3 = C.White
        Welcome.TextSize = 16
        Welcome.Font = Enum.Font.GothamBold
        Welcome.Parent = Content

    elseif category == "Combate" then

        PlayerSelector()

        for _, option in ipairs(Options[category]) do
            Toggle(option,function(state)
                print(option,state)
            end)
        end

    elseif category == "Jogador" then

        SpeedControl()

        for _, option in ipairs(Options[category]) do
            Toggle(option,function(state)
                print(option,state)
            end)
        end

    else

        for _, option in ipairs(Options[category] or {}) do
            Toggle(option,function(state)
                print(option,state)
            end)
        end
    end
end

-- CRIAR ABAS

for _, category in ipairs(Categories) do

    local Tab = Instance.new("TextButton")
    Tab.Size = UDim2.new(1,-12,0,39)
    Tab.BackgroundColor3 = C.Background
    Tab.Text = category
    Tab.TextColor3 = C.White
    Tab.TextSize = 12
    Tab.Font = Enum.Font.GothamBold
    Tab.Parent = Sidebar

    Instance.new("UICorner",Tab).CornerRadius =
        UDim.new(0,7)

    Tab.MouseButton1Click:Connect(function()

        ShowCategory(category)

    end)
end

ShowCategory("Início")

print("Blox F’ - Tales carregado com sucesso!")
