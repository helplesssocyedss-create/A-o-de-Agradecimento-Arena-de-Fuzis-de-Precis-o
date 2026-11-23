--[[
    TALES MOD MENU
    Feito por Tales
    LocalScript - Roblox Studio

    PERSEGUIÇÃO:
    - Só acompanha enquanto o jogador estiver mirando.
    - PC: botão direito do mouse.
    - Controle: L2.
    - Celular: botão MIRA na interface.

    IMPORTANTE:
    O script ajusta a câmera e publica o alvo selecionado.
    O sistema de armas precisa consultar TalesCurrentTarget
    e validar os disparos no servidor.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BLUE = Color3.fromRGB(0, 170, 255)
local OUTLINE = Color3.fromRGB(0, 220, 255)

local Old = PlayerGui:FindFirstChild("TalesModMenu")
if Old then Old:Destroy() end

local Settings = {
    ESP = false,
    Aimbot = false,
    Target = nil,

    Pursuit = false,
    AimHeld = false,

    AssistIA = false,
    FOV = false,
    FOVSize = 150,

    Smoothness = 0.22
}

local CurrentTarget = nil
local ESPObjects = {}
local PlayerConnections = {}
local Camera = workspace.CurrentCamera

--==================================================
-- INTERFACE
--==================================================

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
    button.Position = UDim2.fromOffset(5, #Tabs * 43 + 5)
    button.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = Sidebar
    Instance.new("UICorner", button)

    button.MouseButton1Click:Connect(function()
        for _, tab in ipairs(Tabs) do
            tab.Visible = false
        end

        for _, b in ipairs(TabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(45, 49, 65)
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

--==================================================
-- VALORES DE INTEGRAÇÃO COM O JOGO
--==================================================

local TargetValue = Instance.new("ObjectValue")
TargetValue.Name = "TalesCurrentTarget"
TargetValue.Parent = GUI

local TargetPartValue = Instance.new("StringValue")
TargetPartValue.Name = "TalesTargetPart"
TargetPartValue.Parent = GUI

local AimHeldValue = Instance.new("BoolValue")
AimHeldValue.Name = "TalesAimHeld"
AimHeldValue.Parent = GUI

--==================================================
-- AIMBOT E PERSEGUIÇÃO
--==================================================

local AimTab = CreateTab("AIMBOT")

local AimPrompt = Instance.new("TextLabel")
AimPrompt.Size = UDim2.new(1, -20, 0, 30)
AimPrompt.Position = UDim2.fromOffset(10, 105)
AimPrompt.BackgroundTransparency = 1
AimPrompt.Text = "Escolha Cabeça ou Peito"
AimPrompt.TextColor3 = Color3.new(1, 1, 1)
AimPrompt.TextSize = 13
AimPrompt.Font = Enum.Font.GothamBold
AimPrompt.Visible = false
AimPrompt.Parent = AimTab

local HeadOption
local ChestOption

local function SelectAimPart(part)
    Settings.Target = part
    AimPrompt.Text = "Selecionado: " .. part

    HeadOption.Visible = false
    ChestOption.Visible = false
end

CreateToggle(AimTab, "AIMBOT", function(state)
    Settings.Aimbot = state
    CurrentTarget = nil

    if state then
        Settings.Target = nil
        AimPrompt.Text = "Escolha Cabeça ou Peito"
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

HeadOption = CreateOption(AimTab, "AIMBOT CABEÇA", 145, function()
    SelectAimPart("Cabeça")
end)

ChestOption = CreateOption(AimTab, "AIMBOT PEITO", 190, function()
    SelectAimPart("Peito")
end)

HeadOption.Visible = false
ChestOption.Visible = false

CreateToggle(AimTab, "PERSEGUIÇÃO", function(state)
    Settings.Pursuit = state

    if not state then
        CurrentTarget = nil
    end
end, 55)

CreateToggle(AimTab, "ASSISTENTE IA", function(state)
    Settings.AssistIA = state

    -- Quanto menor o valor, mais rápida a correção.
    Settings.Smoothness = state and 0.38 or 0.22
end, 95)

-- Botão de mira para celular
local MobileAim = Instance.new("TextButton")
MobileAim.Size = UDim2.fromOffset(105, 42)
MobileAim.Position = UDim2.new(1, -120, 0.72, 0)
MobileAim.BackgroundColor3 = Color3.fromRGB(35, 95, 155)
MobileAim.Text = "MIRA: OFF"
MobileAim.TextColor3 = Color3.new(1, 1, 1)
MobileAim.TextSize = 14
MobileAim.Font = Enum.Font.GothamBold
MobileAim.Visible = UserInputService.TouchEnabled
MobileAim.Parent = GUI
Instance.new("UICorner", MobileAim)

MobileAim.MouseButton1Down:Connect(function()
    Settings.AimHeld = true
    MobileAim.Text = "MIRA: ON"
end)

MobileAim.MouseButton1Up:Connect(function()
    Settings.AimHeld = false
    MobileAim.Text = "MIRA: OFF"
end)

MobileAim.MouseLeave:Connect(function()
    Settings.AimHeld = false
    MobileAim.Text = "MIRA: OFF"
end)

-- Comandos de mira para PC e controle
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton2
        or input.KeyCode == Enum.KeyCode.ButtonL2 then

        Settings.AimHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2
        or input.KeyCode == Enum.KeyCode.ButtonL2 then

        Settings.AimHeld = false
    end
end)

--==================================================
-- ESP PLAYER
--==================================================

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
    if humanoid.Health <= 0 then return end

    local old = ESPObjects[target]

    if old and old.Character == character
        and old.Highlight and old.Highlight.Parent
        and old.Billboard and old.Billboard.Parent then
        return
    end

    RemoveESP(target)

    local highlight = Instance.new("Highlight")
    highlight.Name = "TalesESP"
    highlight.Adornee = character
    highlight.FillColor = BLUE
    highlight.OutlineColor = OUTLINE
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
    label.TextColor3 = OUTLINE
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
    if target == Player or PlayerConnections[target] then
        return
    end

    local connections = {}
    PlayerConnections[target] = connections

    local function WatchCharacter(character)
        RemoveESP(target)

        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 15)
            local head = character:WaitForChild("Head", 15)

            if humanoid and head and Settings.ESP
                and target.Parent == Players
                and target.Character == character then

                AddESP(target)
            end
        end)
    end

    table.insert(connections,
        target.CharacterAdded:Connect(WatchCharacter)
    )

    table.insert(connections,
        target.CharacterRemoving:Connect(function()
            RemoveESP(target)
        end)
    )

    if target.Character then
        WatchCharacter(target.Character)
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
    end

    PlayerConnections[target] = nil
end)

--==================================================
-- AIM FOV
--==================================================

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
CircleStroke.Color = OUTLINE
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

CreateOption(FovTab, "AUMENTAR +", 105, function()
    ChangeFOV(20)
end)

CreateOption(FovTab, "DIMINUIR -", 150, function()
    ChangeFOV(-20)
end)

--==================================================
-- SELEÇÃO DO ALVO
--==================================================

local function GetTargetPart(character)
    if Settings.Target == "Cabeça" then
        return character:FindFirstChild("Head")

    elseif Settings.Target == "Peito" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end

    return nil
end

local function GetClosestTarget()
    Camera = workspace.CurrentCamera

    if not Camera or not Settings.Target then
        return nil
    end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    local maxDistance = Settings.FOV
        and Settings.FOVSize
        or 250

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

--==================================================
-- ATUALIZAÇÃO PRINCIPAL
--==================================================

local espTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    Camera = workspace.CurrentCamera

    if not Camera then return end

    local viewport = Camera.ViewportSize

    FOVCircle.Position = UDim2.fromOffset(
        viewport.X / 2,
        viewport.Y / 2
    )

    -- ESP: reconciliação periódica para recuperar personagens
    -- que carregaram atrasados ou tiveram peças substituídas.
    espTimer += deltaTime

    if Settings.ESP and espTimer >= 0.5 then
        espTimer = 0
        UpdateESP()
    end

    -- Seleciona o alvo apenas com os recursos necessários ligados.
    if Settings.Aimbot
        and Settings.Pursuit
        and Settings.Target then

        CurrentTarget = GetClosestTarget()
    else
        CurrentTarget = nil
    end

    -- Publica o alvo para o sistema de armas do jogo.
    TargetValue.Value = CurrentTarget
        and CurrentTarget.Character
        or nil

    TargetPartValue.Value = Settings.Target or ""
    AimHeldValue.Value = Settings.AimHeld

    -- Perseguição só acontece enquanto estiver mirando.
    if Settings.Pursuit
        and Settings.Aimbot
        and Settings.AimHeld
        and CurrentTarget then

        local character = CurrentTarget.Character
        local part = character and GetTargetPart(character)

        if part then
            local cameraPosition = Camera.CFrame.Position

            local desired = CFrame.lookAt(
                cameraPosition,
                part.Position
            )

            local strength = Settings.Smoothness

            if Settings.AssistIA then
                strength = 0.38
            end

            local alpha = 1 - math.pow(
                1 - strength,
                deltaTime * 60
            )

            Camera.CFrame = Camera.CFrame:Lerp(
                desired,
                math.clamp(alpha, 0, 1)
            )
        end
    end
end)

--==================================================
-- MINIMIZAR
--==================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized

    Sidebar.Visible = not minimized
    Content.Visible = not minimized

    if minimized then
        Main.Size = UDim2.fromOffset(230, 42)
        Title.TextSize = 15
        Title.Size = UDim2.new(1, -45, 0, 42)
        Title.Text = "TALES"
        Minimize.Text = "+"
    else
        Main.Size = UDim2.fromOffset(460, 320)
        Title.TextSize = 19
        Title.Size = UDim2.new(1, -55, 0, 45)
        Title.Text = "TALES | MOD MENU"
        Minimize.Text = "-"
    end
end)

--==================================================
-- CRÉDITOS
--==================================================

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
