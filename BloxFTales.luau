--========================================================
-- BLOX F' - TALES | VERSAO 3.2
-- Interface, recursos locais e pontos de integração
-- Para uso em uma experiência Roblox que você controla.
--========================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("BloxFTales")
if old then old:Destroy() end

local COLORS = {
    bg = Color3.fromRGB(15, 15, 23),
    panel = Color3.fromRGB(25, 25, 37),
    row = Color3.fromRGB(34, 34, 48),
    purple = Color3.fromRGB(135, 65, 220),
    green = Color3.fromRGB(40, 190, 105),
    gray = Color3.fromRGB(75, 75, 85),
    white = Color3.fromRGB(255, 255, 255),
    red = Color3.fromRGB(190, 55, 65)
}

local states = {}
local connections = {}
local playerHighlights = {}
local objectHighlights = {}

local selectedPlayer
local infiniteJump = false
local noclip = false
local flying = false
local espPlayers = false
local espEnemies = false
local showNames = false
local showDistances = false
local fruitFinder = false
local chestFinder = false
local destroyed = false

local walkSpeed = 16
local jumpPower = 50
local flySpeed = 60
local flyConnection
local bodyVelocity
local bodyGyro
local collisionCache = {}

local Screen = Instance.new("ScreenGui")
Screen.Name = "BloxFTales"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(620, 430)
Main.Position = UDim2.new(0.5, -310, 0.5, -215)
Main.BackgroundColor3 = COLORS.bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Screen
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = COLORS.purple
stroke.Thickness = 2

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Color3.fromRGB(38, 25, 58)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -105, 1, 0)
Title.Position = UDim2.fromOffset(14, 0)
Title.BackgroundTransparency = 1
Title.Text = "Blox F' - Tales  |  3.2"
Title.TextColor3 = COLORS.white
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Min = Instance.new("TextButton")
Min.Size = UDim2.fromOffset(32, 32)
Min.Position = UDim2.new(1, -78, 0, 8)
Min.BackgroundColor3 = COLORS.purple
Min.Text = "–"
Min.TextColor3 = COLORS.white
Min.Font = Enum.Font.GothamBold
Min.TextSize = 20
Min.Parent = Header
Instance.new("UICorner", Min).CornerRadius = UDim.new(0, 8)

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32, 32)
Close.Position = UDim2.new(1, -40, 0, 8)
Close.BackgroundColor3 = COLORS.red
Close.Text = "X"
Close.TextColor3 = COLORS.white
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14
Close.Parent = Header
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 145, 1, -60)
Sidebar.Position = UDim2.fromOffset(8, 54)
Sidebar.BackgroundColor3 = COLORS.panel
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 9)

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 6)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = Sidebar

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -166, 1, -60)
Content.Position = UDim2.fromOffset(158, 54)
Content.BackgroundColor3 = COLORS.panel
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = COLORS.purple
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 9)

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 7)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = Content

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = Content

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 18)
end)

local function setStatus(message)
    local label = _G.BloxFTalesStatus
    if label and label.Parent then
        label.Text = "Status: " .. tostring(message)
    end
end

local function tween(object, properties, duration)
    TweenService:Create(
        object,
        TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    ):Play()
end

local function clearContent()
    for _, child in ipairs(Content:GetChildren()) do
        if child ~= contentLayout and child ~= padding then
            child:Destroy()
        end
    end
end

local function makeLabel(text, height)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, height or 34)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.white
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Content
    return label
end

local function makeButton(text, callback, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 38)
    button.BackgroundColor3 = color or COLORS.row
    button.Text = text
    button.TextColor3 = COLORS.white
    button.TextSize = 13
    button.Font = Enum.Font.GothamSemibold
    button.TextWrapped = true
    button.Parent = Content
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    button.MouseButton1Click:Connect(function()
        if callback then
            local ok, err = pcall(callback)
            if not ok then setStatus("Erro: " .. tostring(err)) end
        end
    end)
    return button
end

local function makeToggle(name, callback, initial)
    if states[name] == nil then states[name] = initial or false end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 40)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -78, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = COLORS.white
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.fromOffset(46, 23)
    switch.Position = UDim2.new(1, -56, 0.5, -11)
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = row
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(17, 17)
    dot.Position = UDim2.fromOffset(3, 3)
    dot.BackgroundColor3 = COLORS.white
    dot.Parent = switch
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local function update()
        tween(switch, {
            BackgroundColor3 = states[name] and COLORS.green or COLORS.gray
        }, 0.15)
        tween(dot, {
            Position = states[name] and UDim2.fromOffset(26, 3) or UDim2.fromOffset(3, 3)
        }, 0.15)
    end

    update()
    switch.MouseButton1Click:Connect(function()
        states[name] = not states[name]
        update()
        if callback then
            local ok, err = pcall(callback, states[name])
            if not ok then setStatus("Erro em " .. name .. ": " .. tostring(err)) end
        end
    end)
    return row
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleportLocal(destination)
    local character = getCharacter()
    if not getRoot(character) then
        setStatus("Personagem ainda não carregou.")
        return false
    end
    if typeof(destination) == "Vector3" then
        destination = CFrame.new(destination + Vector3.new(0, 4, 0))
    end
    if typeof(destination) ~= "CFrame" then return false end
    character:PivotTo(destination)
    return true
end

local function findNamedWorldObject(names)
    for _, item in ipairs(Workspace:GetDescendants()) do
        local lower = string.lower(item.Name)
        for _, name in ipairs(names) do
            if string.find(lower, string.lower(name), 1, true) then
                if item:IsA("BasePart") then return item end
                if item:IsA("Model") then
                    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
                    if part then return part end
                end
            end
        end
    end
end

local function removeBucket(bucket)
    for object, adornment in pairs(bucket) do
        if adornment and adornment.Parent then adornment:Destroy() end
        bucket[object] = nil
    end
end

local function makeHighlight(object, color, bucket)
    if bucket[object] or not object or not object.Parent then return end
    local h = Instance.new("Highlight")
    h.FillColor = color
    h.OutlineColor = COLORS.white
    h.FillTransparency = 0.65
    h.Adornee = object
    h.Parent = Screen
    bucket[object] = h
end

local function isEnemyModel(model)
    if not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then return false end
    if not getHumanoid(model) or not getRoot(model) then return false end
    local name = string.lower(model.Name)
    return string.find(name, "enemy", 1, true)
        or string.find(name, "bandit", 1, true)
        or string.find(name, "boss", 1, true)
        or string.find(name, "npc", 1, true)
end

local function refreshVisuals()
    removeBucket(playerHighlights)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            if espPlayers then
                makeHighlight(character, COLORS.purple, playerHighlights)
            end

            if showNames or showDistances then
                local head = character:FindFirstChild("Head")
                if head then
                    local oldTag = head:FindFirstChild("BloxFTalesTag")
                    if oldTag then oldTag:Destroy() end

                    local tag = Instance.new("BillboardGui")
                    tag.Name = "BloxFTalesTag"
                    tag.Size = UDim2.fromOffset(190, 28)
                    tag.StudsOffset = Vector3.new(0, 2.5, 0)
                    tag.AlwaysOnTop = true
                    tag.Adornee = head
                    tag.Parent = head

                    local text = Instance.new("TextLabel")
                    text.Size = UDim2.fromScale(1, 1)
                    text.BackgroundTransparency = 1
                    text.TextColor3 = COLORS.white
                    text.TextStrokeTransparency = 0.2
                    text.Font = Enum.Font.GothamBold
                    text.TextSize = 12
                    text.Parent = tag

                    local a = getRoot(getCharacter())
                    local b = getRoot(character)
                    local distance = (a and b) and math.floor((a.Position - b.Position).Magnitude) or 0

                    text.Text = (showNames and player.DisplayName or "")
                        .. ((showNames and showDistances) and " | " or "")
                        .. (showDistances and (distance .. " studs") or "")
                    playerHighlights[tag] = tag
                end
            end
        end
    end
end

local function scanWorld()
    for _, item in ipairs(Workspace:GetDescendants()) do
        local name = string.lower(item.Name)

        if fruitFinder and (string.find(name, "fruit", 1, true) or string.find(name, "fruta", 1, true)) then
            if item:IsA("Model") or item:IsA("BasePart") then
                makeHighlight(item, COLORS.green, objectHighlights)
            end
        end

        if chestFinder and (string.find(name, "chest", 1, true) or string.find(name, "baú", 1, true)) then
            if item:IsA("Model") or item:IsA("BasePart") then
                makeHighlight(item, COLORS.purple, objectHighlights)
            end
        end

        if espEnemies and isEnemyModel(item) then
            makeHighlight(item, COLORS.red, objectHighlights)
        end
    end

    for object, adornment in pairs(objectHighlights) do
        if not object.Parent then
            if adornment then adornment:Destroy() end
            objectHighlights[object] = nil
        end
    end
end

local function makeSpeedControl()
    makeLabel("Velocidade de caminhada:", 26)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -4, 0, 38)
    box.BackgroundColor3 = COLORS.row
    box.TextColor3 = COLORS.white
    box.Text = tostring(walkSpeed)
    box.ClearTextOnFocus = false
    box.Parent = Content
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)

    box.FocusLost:Connect(function()
        local value = tonumber(box.Text)
        if not value then box.Text = tostring(walkSpeed) return end
        walkSpeed = math.clamp(value, 0, 100)
        local hum = getHumanoid(getCharacter())
        if hum then hum.WalkSpeed = walkSpeed end
        box.Text = tostring(walkSpeed)
        setStatus("Velocidade definida: " .. walkSpeed)
    end)

    makeLabel("Força do pulo:", 26)
    local jumpBox = Instance.new("TextBox")
    jumpBox.Size = UDim2.new(1, -4, 0, 38)
    jumpBox.BackgroundColor3 = COLORS.row
    jumpBox.TextColor3 = COLORS.white
    jumpBox.Text = tostring(jumpPower)
    jumpBox.ClearTextOnFocus = false
    jumpBox.Parent = Content
    Instance.new("UICorner", jumpBox).CornerRadius = UDim.new(0, 7)

    jumpBox.FocusLost:Connect(function()
        local value = tonumber(jumpBox.Text)
        if not value then jumpBox.Text = tostring(jumpPower) return end
        jumpPower = math.clamp(value, 0, 150)
        local hum = getHumanoid(getCharacter())
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = jumpPower
        end
        jumpBox.Text = tostring(jumpPower)
        setStatus("Pulo definido: " .. jumpPower)
    end)
end

local function stopFlight()
    flying = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end

    local root = getRoot(getCharacter())
    if root then
        local bv = root:FindFirstChild("BloxFTalesVelocity")
        local bg = root:FindFirstChild("BloxFTalesGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    bodyVelocity = nil
    bodyGyro = nil
    setStatus("Voo desligado.")
end

local function startFlight()
    local character = getCharacter()
    local root = getRoot(character)
    local hum = getHumanoid(character)

    if not root or not hum then
        setStatus("Personagem indisponível para voar.")
        return
    end

    stopFlight()
    flying = true
    hum.PlatformStand = false

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "BloxFTalesVelocity"
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "BloxFTalesGyro"
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.P = 1e4
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not root.Parent then
            stopFlight()
            return
        end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        local direction = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end

        bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame = camera.CFrame
    end)

    setStatus("Voo ligado: WASD, espaço sobe, Ctrl desce.")
end

local function makePlayerSelection()
    makeLabel("Selecione um jogador:", 28)
    local selectedLabel = makeLabel("Selecionado: nenhum", 28)

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= LocalPlayer then
            makeButton(target.DisplayName .. " (@" .. target.Name .. ")", function()
                selectedPlayer = target
                selectedLabel.Text = "Selecionado: " .. target.Name
                setStatus("Jogador selecionado.")
            end)
        end
    end

    makeButton("CONFIRMAR: IR ATÉ O JOGADOR", function()
        if not selectedPlayer or not selectedPlayer.Parent then
            setStatus("Selecione um jogador válido.")
            return
        end
        local root = getRoot(selectedPlayer.Character)
        if not root then setStatus("Personagem do jogador indisponível.") return end
        teleportLocal(root.CFrame * CFrame.new(0, 0, 5))
        setStatus("Teleporte local solicitado.")
    end, COLORS.purple)
end

local function makeCoordinateControls()
    makeLabel("Digite as coordenadas de destino:", 30)
    local boxes = {}

    for _, axis in ipairs({"X", "Y", "Z"}) do
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -4, 0, 36)
        box.BackgroundColor3 = COLORS.row
        box.TextColor3 = COLORS.white
        box.PlaceholderText = axis
        box.ClearTextOnFocus = false
        box.Parent = Content
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
        boxes[axis] = box
    end

    makeButton("IR PARA AS COORDENADAS", function()
        local x, y, z = tonumber(boxes.X.Text), tonumber(boxes.Y.Text), tonumber(boxes.Z.Text)
        if not x or not y or not z then
            setStatus("Preencha X, Y e Z com números.")
            return
        end
        local ok = teleportLocal(Vector3.new(
            math.clamp(x, -100000, 100000),
            math.clamp(y, -100000, 100000),
            math.clamp(z, -100000, 100000)
        ))
        setStatus(ok and "Teleporte solicitado." or "Falha no teleporte.")
    end, COLORS.purple)
end

-- Integração opcional para a experiência que você controla:
-- ReplicatedStorage/BloxFTalesRemotes/<NomeDaAcao>
-- Cada RemoteEvent deve ser criado e validado pelo servidor.
local function requestOwnedGameFeature(featureName, enabled)
    local folder = ReplicatedStorage:FindFirstChild("BloxFTalesRemotes")
    if not folder then
        setStatus(featureName .. ": integração do servidor não encontrada.")
        return
    end

    local remote = folder:FindFirstChild(featureName)
    if not remote or not remote:IsA("RemoteEvent") then
        setStatus(featureName .. ": RemoteEvent não configurado.")
        return
    end

    remote:FireServer(enabled)
    setStatus(featureName .. ": solicitação enviada ao servidor.")
end

local function showCategory(category)
    clearContent()
    Content.CanvasPosition = Vector2.zero

    if category == "Início" then
        makeLabel("BLOX F' - TALES 3.2", 36)
        makeLabel("Painel atualizado. Arraste pelo cabeçalho; use – para minimizar.", 48)
        local status = makeLabel("Status: pronto", 28)
        _G.BloxFTalesStatus = status

        local coords = makeLabel("Coordenadas: aguardando personagem...", 28)
        task.spawn(function()
            while Screen.Parent and coords.Parent do
                local root = getRoot(getCharacter())
                coords.Text = root
                    and ("Coordenadas: " .. math.floor(root.Position.X) .. ", "
                    .. math.floor(root.Position.Y) .. ", " .. math.floor(root.Position.Z))
                    or "Coordenadas: personagem indisponível"
                task.wait(0.25)
            end
        end)

        makeLabel("Recursos que dependem do servidor precisam da integração oficial da sua experiência.", 55)

    elseif category == "Combate" then
        makeLabel("Opções de combate. As ações de servidor precisam dos RemoteEvents configurados na sua experiência.", 55)

        makeToggle("Mira assistida", function(on)
            requestOwnedGameFeature("MiraAssistida", on)
        end)

        makeToggle("Área de acerto visual", function(on)
            setStatus(on and "Área visual ligada." or "Área visual desligada.")
        end)

        makeToggle("Haki automático", function(on)
            requestOwnedGameFeature("HakiAutomatico", on)
        end)

        makeToggle("Habilidades automáticas", function(on)
            requestOwnedGameFeature("HabilidadesAutomaticas", on)
        end)

        makeToggle("Ataque automático", function(on)
            requestOwnedGameFeature("AtaqueAutomatico", on)
        end)

    elseif category == "Frutas" then
        makeToggle("Localizador de frutas", function(on)
            fruitFinder = on
            if not on then removeBucket(objectHighlights) end
            setStatus(on and "Procurando frutas replicadas no mapa." or "Localizador desligado.")
        end)

        makeToggle("Detector de frutas", function(on)
            fruitFinder = on
            setStatus(on and "Detector ligado." or "Detector desligado.")
        end)

        makeLabel("O detector procura objetos replicados com 'fruit' ou 'fruta' no nome.", 48)

    elseif category == "Jogador" then
        makeSpeedControl()

        makeToggle("Voar", function(on)
            if on then startFlight() else stopFlight() end
        end)

        makeToggle("Pulo infinito", function(on)
            infiniteJump = on
            setStatus(on and "Pulo infinito ligado." or "Pulo infinito desligado.")
        end)

        makeToggle("Atravessar paredes", function(on)
            noclip = on
            setStatus(on and "Noclip local ligado." or "Noclip local desligado.")
        end)

        makeLabel("Voo: use WASD, espaço para subir e Ctrl para descer.", 45)

    elseif category == "Teletransporte" then
        makeLabel("Teletransporte por nomes de objetos encontrados no Workspace:", 45)

        local islands = {
            {"Ilha 1", {"Island1", "Ilha1", "Island 1", "Ilha 1"}},
            {"Ilha 2", {"Island2", "Ilha2", "Island 2", "Ilha 2"}},
            {"Ilha 3", {"Island3", "Ilha3", "Island 3", "Ilha 3"}}
        }

        for _, data in ipairs(islands) do
            makeButton("TELETRANSPORTE " .. string.upper(data[1]), function()
                local target = findNamedWorldObject(data[2])
                if target then
                    teleportLocal(target.CFrame * CFrame.new(0, 5, 0))
                    setStatus("Indo para " .. data[1] .. ".")
                else
                    setStatus(data[1] .. " não encontrada pelo nome.")
                end
            end)
        end

        makeLabel("Teletransporte por coordenadas:", 28)
        makeCoordinateControls()
        makeLabel("Teletransporte até jogador:", 28)
        makePlayerSelection()

    elseif category == "Coleta e evolução" then
        makeLabel("Ações de coleta e progressão via integração oficial do servidor.", 48)

        makeToggle("Coleta automática", function(on)
            requestOwnedGameFeature("ColetaAutomatica", on)
        end)

        makeToggle("Missões automáticas", function(on)
            requestOwnedGameFeature("MissoesAutomaticas", on)
        end)

        makeToggle("Evolução automática", function(on)
            requestOwnedGameFeature("EvolucaoAutomatica", on)
        end)

        makeToggle("Coleta de recompensas", function(on)
            requestOwnedGameFeature("ColetaRecompensas", on)
        end)

    elseif category == "Visualização" then
        makeToggle("Destacar jogadores", function(on)
            espPlayers = on
            refreshVisuals()
        end)

        makeToggle("Destacar inimigos", function(on)
            espEnemies = on
            if not on then removeBucket(objectHighlights) end
            scanWorld()
        end)

        makeToggle("Destacar frutas", function(on)
            fruitFinder = on
            if not on then removeBucket(objectHighlights) end
            scanWorld()
        end)

        makeToggle("Destacar baús", function(on)
            chestFinder = on
            if not on then removeBucket(objectHighlights) end
            scanWorld()
        end)

        makeToggle("Mostrar nomes", function(on)
            showNames = on
            refreshVisuals()
        end)

        makeToggle("Mostrar distâncias", function(on)
            showDistances = on
            refreshVisuals()
        end)

    elseif category == "Configurações" then
        makeButton("Recentralizar painel", function()
            Main.Position = UDim2.new(0.5, -310, 0.5, -215)
            setStatus("Painel recentralizado.")
        end)

        makeButton("Reaplicar velocidade e pulo", function()
            local hum = getHumanoid(getCharacter())
            if hum then
                hum.WalkSpeed = walkSpeed
                hum.UseJumpPower = true
                hum.JumpPower = jumpPower
                setStatus("Velocidade e pulo reaplicados.")
            end
        end)

        makeButton("Limpar destaques visuais", function()
            espPlayers = false
            espEnemies = false
            showNames = false
            showDistances = false
            fruitFinder = false
            chestFinder = false
            removeBucket(playerHighlights)
            removeBucket(objectHighlights)
            setStatus("Destaques removidos.")
        end)

        makeToggle("Animações da interface", function(on)
            setStatus(on and "Animações ativadas." or "Animações desativadas.")
        end)

        makeToggle("Tema personalizado", function(on)
            Main.BackgroundColor3 = on and Color3.fromRGB(20, 15, 32) or COLORS.bg
            setStatus("Tema atualizado.")
        end)

        makeToggle("Transparência", function(on)
            Main.BackgroundTransparency = on and 0.12 or 0
            setStatus("Transparência atualizada.")
        end)

        makeButton("Salvar configurações desta sessão", function()
            setStatus("Configurações mantidas enquanto o painel estiver aberto.")
        end)
    end
end

local categories = {
    "Início",
    "Combate",
    "Frutas",
    "Jogador",
    "Teletransporte",
    "Coleta e evolução",
    "Visualização",
    "Configurações"
}

for index, category in ipairs(categories) do
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(1, -10, 0, 37)
    tab.LayoutOrder = index
    tab.BackgroundColor3 = category == "Início" and COLORS.purple or COLORS.row
    tab.Text = category
    tab.TextColor3 = COLORS.white
    tab.TextSize = 11
    tab.Font = Enum.Font.GothamBold
    tab.TextWrapped = true
    tab.Parent = Sidebar
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 7)

    tab.MouseButton1Click:Connect(function()
        for _, sibling in ipairs(Sidebar:GetChildren()) do
            if sibling:IsA("TextButton") then sibling.BackgroundColor3 = COLORS.row end
        end
        tab.BackgroundColor3 = COLORS.purple
        showCategory(category)
    end)
end

-- Minimizar e restaurar
local minimized = false
local expandedSize = Main.Size
local expandedPosition = Main.Position

Min.MouseButton1Click:Connect(function()
    minimized = not minimized

    if minimized then
        expandedPosition = Main.Position
        Sidebar.Visible = false
        Content.Visible = false
        Title.Visible = false
        Close.Visible = false
        Min.Position = UDim2.fromOffset(13, 13)
        Min.Text = "↗"
        tween(Main, {Size = UDim2.fromOffset(60, 60)}, 0.2)
        tween(Header, {Size = UDim2.fromOffset(60, 60)}, 0.2)
    else
        tween(Main, {Size = expandedSize}, 0.2)
        tween(Header, {Size = UDim2.new(1, 0, 0, 48)}, 0.2)
        Main.Position = expandedPosition
        Min.Position = UDim2.new(1, -78, 0, 8)
        Min.Text = "–"
        Sidebar.Visible = true
        Content.Visible = true
        Title.Visible = true
        Close.Visible = true
    end
end)

-- Arrastar painel com mouse ou toque
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

table.insert(connections, UIS.InputChanged:Connect(function(input)
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
end))

table.insert(connections, UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

-- Pulo infinito
table.insert(connections, UIS.JumpRequest:Connect(function()
    if infiniteJump then
        local hum = getHumanoid(getCharacter())
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- Noclip local com restauração das colisões
table.insert(connections, RunService.Stepped:Connect(function()
    local character = getCharacter()

    if noclip and character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisionCache[part] == nil then
                    collisionCache[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    elseif not noclip and next(collisionCache) then
        for part, original in pairs(collisionCache) do
            if part and part.Parent then part.CanCollide = original end
            collisionCache[part] = nil
        end
    end
end))

-- Atualização contínua dos localizadores e ESP
table.insert(connections, RunService.Heartbeat:Connect(function()
    if fruitFinder or chestFinder or espEnemies then
        scanWorld()
    end
end))

-- Atualização periódica dos jogadores
task.spawn(function()
    while Screen.Parent do
        if espPlayers or showNames or showDistances then
            refreshVisuals()
        end
        task.wait(1.5)
    end
end)

table.insert(connections, Players.PlayerAdded:Connect(function()
    task.delay(0.5, refreshVisuals)
end))

table.insert(connections, Players.PlayerRemoving:Connect(function()
    task.delay(0.2, refreshVisuals)
end))

-- Respawn: reaplica velocidade e pulo
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    local hum = getHumanoid(character)
    if hum then
        hum.WalkSpeed = walkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = jumpPower
    end
end))

Close.MouseButton1Click:Connect(function()
    destroyed = true
    stopFlight()
    noclip = false

    for part, original in pairs(collisionCache) do
        if part and part.Parent then part.CanCollide = original end
        collisionCache[part] = nil
    end

    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end

    removeBucket(playerHighlights)
    removeBucket(objectHighlights)
    Screen:Destroy()
end)

showCategory("Início")
print("Blox F' - Tales 3.2 carregado.")
