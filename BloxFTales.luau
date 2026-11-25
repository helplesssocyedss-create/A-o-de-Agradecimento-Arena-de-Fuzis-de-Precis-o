--========================================================
-- BLOX F' - TALES | VERSAO 3.0
-- Interface responsiva e recursos locais genéricos.
-- Compatível com LocalScript em uma experiência sua.
--========================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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
local selectedPlayer = nil
local selectedIsland = nil
local connections = {}
local playerHighlights = {}
local objectHighlights = {}
local infiniteJump = false
local noclip = false
local showNames = false
local showDistances = false
local espPlayers = false
local fruitFinder = false
local chestFinder = false
local destroyed = false
local collisionCache = {}
local walkSpeed = 16
local jumpPower = 50

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
Title.Text = "Blox F' - Tales  |  3.0"
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

-- Declaracoes antecipadas para a minimizacao.
local Sidebar, Content
local minimized = false
local expandedSize = UDim2.fromOffset(620, 430)
local expandedPosition = Main.Position

local function tween(object, props, duration)
    TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        props
    ):Play()
end

local function setStatus(message)
    local statusObject = _G.BloxFTalesStatus

    if statusObject and statusObject.Parent then
        statusObject.Text = "Status: " .. tostring(message)
    end
end

local function MinimizePanel()
    minimized = not minimized

    if minimized then
        expandedPosition = Main.Position

        Sidebar.Visible = false
        Content.Visible = false
        Title.Visible = false
        Close.Visible = false

        Min.Position = UDim2.fromOffset(13, 13)
        Min.Size = UDim2.fromOffset(34, 34)
        Min.Text = "↗"

        tween(Main, {
            Size = UDim2.fromOffset(60, 60)
        }, 0.22)

        tween(Header, {
            Size = UDim2.fromOffset(60, 60)
        }, 0.22)
    else
        tween(Main, {
            Size = expandedSize
        }, 0.22)

        tween(Header, {
            Size = UDim2.new(1, 0, 0, 48)
        }, 0.22)

        Main.Position = expandedPosition

        Min.Position = UDim2.new(1, -78, 0, 8)
        Min.Size = UDim2.fromOffset(32, 32)
        Min.Text = "–"

        Sidebar.Visible = true
        Content.Visible = true
        Title.Visible = true
        Close.Visible = true
    end
end

Sidebar = Instance.new("Frame")
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

Content = Instance.new("ScrollingFrame")
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

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 8)
contentPadding.PaddingBottom = UDim.new(0, 8)
contentPadding.PaddingLeft = UDim.new(0, 8)
contentPadding.PaddingRight = UDim.new(0, 8)
contentPadding.Parent = Content

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(
        0,
        0,
        0,
        contentLayout.AbsoluteContentSize.Y + 18
    )
end)

local function clearContent()
    for _, child in ipairs(Content:GetChildren()) do
        if child ~= contentLayout and child ~= contentPadding then
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
    button.AutoButtonColor = true
    button.Parent = Content

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return button
end

local function makeToggle(name, callback, initial)
    if states[name] == nil then
        states[name] = initial or false
    end

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
            Position = states[name]
                and UDim2.fromOffset(26, 3)
                or UDim2.fromOffset(3, 3)
        }, 0.15)
    end

    update()

    switch.MouseButton1Click:Connect(function()
        states[name] = not states[name]
        update()

        if callback then
            local ok, err = pcall(callback, states[name])

            if not ok then
                setStatus("Erro em " .. name .. ": " .. tostring(err))
            end
        end
    end)

    return row
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleportLocal(destination)
    local character = getCharacter()
    local root = getRoot(character)

    if not root then
        setStatus("Personagem ainda não carregou.")
        return false
    end

    if typeof(destination) == "CFrame" then
        character:PivotTo(destination)
        return true
    elseif typeof(destination) == "Vector3" then
        character:PivotTo(CFrame.new(destination + Vector3.new(0, 4, 0)))
        return true
    end

    return false
end

local function findNamedWorldObject(names)
    for _, item in ipairs(Workspace:GetDescendants()) do
        local lower = string.lower(item.Name)

        for _, name in ipairs(names) do
            if string.find(lower, string.lower(name), 1, true) then
                if item:IsA("BasePart") then
                    return item
                end

                if item:IsA("Model") then
                    local part = item.PrimaryPart
                        or item:FindFirstChildWhichIsA("BasePart", true)

                    if part then
                        return part
                    end
                end
            end
        end
    end

    return nil
end

local function removeHighlights(bucket)
    for instance, adornment in pairs(bucket) do
        if adornment and adornment.Parent then
            adornment:Destroy()
        end

        bucket[instance] = nil
    end
end

local function applyPlayerVisuals()
    removeHighlights(playerHighlights)

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= LocalPlayer and target.Character then
            local character = target.Character

            if espPlayers then
                local h = Instance.new("Highlight")
                h.FillColor = COLORS.purple
                h.OutlineColor = COLORS.white
                h.FillTransparency = 0.72
                h.Adornee = character
                h.Parent = Screen

                playerHighlights[character] = h
            end

            if showNames or showDistances then
                local head = character:FindFirstChild("Head")

                if head then
                    local bill = Instance.new("BillboardGui")
                    bill.Name = "BloxFTalesTag"
                    bill.Size = UDim2.fromOffset(180, 28)
                    bill.StudsOffset = Vector3.new(0, 2.5, 0)
                    bill.AlwaysOnTop = true
                    bill.Adornee = head
                    bill.Parent = Screen

                    local txt = Instance.new("TextLabel")
                    txt.Size = UDim2.fromScale(1, 1)
                    txt.BackgroundTransparency = 1
                    txt.TextColor3 = COLORS.white
                    txt.TextStrokeTransparency = 0.25
                    txt.Font = Enum.Font.GothamBold
                    txt.TextSize = 12
                    txt.Parent = bill

                    local myRoot = getRoot(getCharacter())
                    local theirRoot = getRoot(character)

                    local distance = (myRoot and theirRoot)
                        and math.floor((myRoot.Position - theirRoot.Position).Magnitude)
                        or 0

                    txt.Text = (showNames and target.DisplayName or "")
                        .. ((showNames and showDistances) and "  |  " or "")
                        .. (showDistances and (tostring(distance) .. " studs") or "")

                    playerHighlights[bill] = bill
                end
            end
        end
    end
end

local function refreshObjectHighlights(kind, enabled)
    for object, adornment in pairs(objectHighlights) do
        if adornment and adornment.Parent then
            adornment:Destroy()
        end

        objectHighlights[object] = nil
    end

    if not enabled then
        return
    end

    local key = string.lower(kind)

    for _, item in ipairs(Workspace:GetDescendants()) do
        local n = string.lower(item.Name)

        local matches =
            (key == "fruit" and string.find(n, "fruit", 1, true))
            or (key == "chest" and string.find(n, "chest", 1, true))
            or (key == "chest" and string.find(n, "baú", 1, true))

        if matches and (item:IsA("BasePart") or item:IsA("Model")) then
            local h = Instance.new("Highlight")
            h.FillColor = key == "fruit" and COLORS.green or COLORS.purple
            h.OutlineColor = COLORS.white
            h.FillTransparency = 0.65
            h.Adornee = item
            h.Parent = Screen

            objectHighlights[item] = h
        end
    end
end

local function makePlayerSelection()
    makeLabel(
        "Escolha um jogador. Depois toque em confirmar para ir até ele.",
        42
    )

    local selectionLabel = makeLabel("Selecionado: nenhum", 28)
    local confirmButton

    local function updateSelection()
        selectionLabel.Text = "Selecionado: "
            .. (selectedPlayer and selectedPlayer.Name or "nenhum")

        if confirmButton then
            confirmButton.Visible = selectedPlayer ~= nil
        end
    end

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 38)
            row.BackgroundColor3 = COLORS.row
            row.Parent = Content

            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

            local check = Instance.new("TextButton")
            check.Size = UDim2.fromOffset(28, 28)
            check.Position = UDim2.new(1, -34, 0.5, -14)
            check.BackgroundColor3 = selectedPlayer == target
                and COLORS.green or COLORS.gray
            check.Text = selectedPlayer == target and "✓" or ""
            check.TextColor3 = COLORS.white
            check.Parent = row

            Instance.new("UICorner", check).CornerRadius = UDim.new(0, 6)

            local name = Instance.new("TextButton")
            name.Size = UDim2.new(1, -42, 1, 0)
            name.Position = UDim2.fromOffset(8, 0)
            name.BackgroundTransparency = 1
            name.Text = target.DisplayName .. "  (@" .. target.Name .. ")"
            name.TextColor3 = COLORS.white
            name.TextSize = 12
            name.Font = Enum.Font.Gotham
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Parent = row

            local function choose()
                selectedPlayer = target

                for _, child in ipairs(Content:GetChildren()) do
                    if child:IsA("Frame") then
                        for _, b in ipairs(child:GetChildren()) do
                            if b:IsA("TextButton")
                                and b.Size == UDim2.fromOffset(28, 28) then

                                b.BackgroundColor3 = COLORS.gray
                                b.Text = ""
                            end
                        end
                    end
                end

                check.BackgroundColor3 = COLORS.green
                check.Text = "✓"
                updateSelection()
            end

            name.MouseButton1Click:Connect(choose)
            check.MouseButton1Click:Connect(choose)
        end
    end

    confirmButton = makeButton(
        "CONFIRMAR: IR ATÉ O JOGADOR",
        function()
            if not selectedPlayer or not selectedPlayer.Parent then
                setStatus("Esse jogador não está mais no servidor.")
                return
            end

            local targetRoot = getRoot(selectedPlayer.Character)

            if not targetRoot then
                setStatus("O personagem do jogador não está disponível.")
                return
            end

            local confirm = Instance.new("Frame")
            confirm.Size = UDim2.fromOffset(270, 118)
            confirm.Position = UDim2.new(0.5, -135, 0.5, -59)
            confirm.BackgroundColor3 = COLORS.panel
            confirm.ZIndex = 20
            confirm.Parent = Screen

            Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 10)

            local msg = Instance.new("TextLabel")
            msg.Size = UDim2.new(1, -16, 0, 55)
            msg.Position = UDim2.fromOffset(8, 4)
            msg.BackgroundTransparency = 1
            msg.Text = "Ir até " .. selectedPlayer.DisplayName
                .. "?\nA ação move apenas seu personagem."
            msg.TextColor3 = COLORS.white
            msg.TextWrapped = true
            msg.Font = Enum.Font.Gotham
            msg.TextSize = 12
            msg.ZIndex = 21
            msg.Parent = confirm

            local yes = Instance.new("TextButton")
            yes.Size = UDim2.new(0.46, 0, 0, 34)
            yes.Position = UDim2.new(0.03, 0, 1, -42)
            yes.Text = "Confirmar"
            yes.BackgroundColor3 = COLORS.green
            yes.TextColor3 = COLORS.white
            yes.ZIndex = 21
            yes.Parent = confirm

            local no = Instance.new("TextButton")
            no.Size = UDim2.new(0.46, 0, 0, 34)
            no.Position = UDim2.new(0.51, 0, 1, -42)
            no.Text = "Cancelar"
            no.BackgroundColor3 = COLORS.red
            no.TextColor3 = COLORS.white
            no.ZIndex = 21
            no.Parent = confirm

            yes.MouseButton1Click:Connect(function()
                local latestRoot = getRoot(
                    selectedPlayer and selectedPlayer.Character
                )

                if latestRoot then
                    teleportLocal(latestRoot.CFrame * CFrame.new(0, 0, 4))
                    setStatus("Teletransporte local solicitado.")
                end

                confirm:Destroy()
            end)

            no.MouseButton1Click:Connect(function()
                confirm:Destroy()
            end)
        end,
        COLORS.purple
    )

    confirmButton.Visible = selectedPlayer ~= nil
    updateSelection()
end

local function makeSpeedControl()
    makeLabel("Velocidade de caminhada (aplicada localmente):", 28)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -4, 0, 38)
    box.BackgroundColor3 = COLORS.row
    box.TextColor3 = COLORS.white
    box.PlaceholderText = "Velocidade entre 0 e 100"
    box.Text = tostring(walkSpeed)
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Parent = Content

    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)

    box.FocusLost:Connect(function()
        local value = tonumber(box.Text)

        if not value then
            box.Text = tostring(walkSpeed)
            return
        end

        walkSpeed = math.clamp(value, 0, 100)

        local hum = getCharacter()
            and getCharacter():FindFirstChildOfClass("Humanoid")

        if hum then
            hum.WalkSpeed = walkSpeed
        end

        box.Text = tostring(walkSpeed)
        setStatus("Velocidade local: " .. walkSpeed)
    end)

    makeLabel("Força do pulo:", 25)

    local jumpBox = Instance.new("TextBox")
    jumpBox.Size = UDim2.new(1, -4, 0, 38)
    jumpBox.BackgroundColor3 = COLORS.row
    jumpBox.TextColor3 = COLORS.white
    jumpBox.Text = tostring(jumpPower)
    jumpBox.ClearTextOnFocus = false
    jumpBox.Font = Enum.Font.Gotham
    jumpBox.TextSize = 13
    jumpBox.Parent = Content

    Instance.new("UICorner", jumpBox).CornerRadius = UDim.new(0, 7)

    jumpBox.FocusLost:Connect(function()
        local value = tonumber(jumpBox.Text)

        if not value then
            jumpBox.Text = tostring(jumpPower)
            return
        end

        jumpPower = math.clamp(value, 0, 150)

        local hum = getCharacter()
            and getCharacter():FindFirstChildOfClass("Humanoid")

        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = jumpPower
        end

        jumpBox.Text = tostring(jumpPower)
        setStatus("Pulo local: " .. jumpPower)
    end)
end

local function showCategory(category)
    clearContent()
    Content.CanvasPosition = Vector2.new(0, 0)

    if category == "Início" then
        makeLabel("BLOX F' - TALES 3.0", 36)

        makeLabel(
            "Interface responsiva. Arraste pelo cabeçalho. Use o botão – para recolher e ↗ para restaurar.",
            52
        )

        local status = makeLabel("Status: pronto", 28)
        _G.BloxFTalesStatus = status

        local coords = makeLabel(
            "Coordenadas: aguardando personagem...",
            28
        )

        task.spawn(function()
            while Screen.Parent and coords.Parent do
                local root = getRoot(getCharacter())

                coords.Text = root
                    and (
                        "Coordenadas: "
                        .. math.floor(root.Position.X)
                        .. ", "
                        .. math.floor(root.Position.Y)
                        .. ", "
                        .. math.floor(root.Position.Z)
                    )
                    or "Coordenadas: personagem indisponível"

                task.wait(0.25)
            end
        end)

        makeLabel(
            "Aviso: recursos locais dependem do que o cliente consegue controlar. Ações internas do jogo exigem suporte do servidor.",
            64
        )

    elseif category == "Jogador" then
        makeSpeedControl()

        makeToggle("Pulo infinito", function(on)
            infiniteJump = on
            setStatus(on and "Pulo infinito ligado" or "Pulo infinito desligado")
        end)

        makeToggle("Atravessar paredes (local)", function(on)
            noclip = on
            setStatus(on and "Noclip local ligado" or "Noclip local desligado")
        end)

        makeLabel(
            "O noclip altera colisões apenas no seu cliente; o servidor pode corrigir sua posição.",
            48
        )

    elseif category == "Teletransporte" then
        makeLabel(
            "Teletransportes para ilhas: procura objetos no mapa com os nomes indicados. Os nomes variam entre jogos.",
            48
        )

        local islands = {
            {"Ilha 1", {"Island1", "Ilha1", "Island 1", "Ilha 1"}},
            {"Ilha 2", {"Island2", "Ilha2", "Island 2", "Ilha 2"}},
            {"Ilha 3", {"Island3", "Ilha3", "Island 3", "Ilha 3"}}
        }

        for _, data in ipairs(islands) do
            makeButton(
                "TELETRANSPORTE " .. string.upper(data[1]),
                function()
                    local target = findNamedWorldObject(data[2])

                    if target then
                        teleportLocal(target.CFrame)
                        setStatus("Indo para " .. data[1])
                    else
                        setStatus(
                            data[1] .. " não encontrado pelo nome no mapa."
                        )
                    end
                end
            )
        end

        makeLabel("Ir até um jogador:", 28)
        makePlayerSelection()

    elseif category == "Visualização" then
        makeToggle("Destacar jogadores", function(on)
            espPlayers = on
            applyPlayerVisuals()
        end)

        makeToggle("Mostrar nomes", function(on)
            showNames = on
            applyPlayerVisuals()
        end)

        makeToggle("Mostrar distâncias", function(on)
            showDistances = on
            applyPlayerVisuals()
        end)

        makeToggle("Localizador de frutas", function(on)
            fruitFinder = on
            refreshObjectHighlights("fruit", on)
        end)

        makeToggle("Localizador de baús", function(on)
            chestFinder = on
            refreshObjectHighlights("chest", on)
        end)

        makeLabel(
            "Os localizadores procuram objetos cujo nome contenha 'fruit', 'chest' ou 'baú'.",
            48
        )

    elseif category == "Combate" then
        makeLabel(
            "Funções de combate automático, mira assistida, Haki e uso automático de habilidades não podem ser implementadas genericamente por este LocalScript.",
            80
        )

        makeLabel(
            "Elas dependem dos sistemas e eventos internos do jogo. Não vou colocar botões falsos que apenas mudam de cor.",
            65
        )

    elseif category == "Frutas" then
        makeToggle("Detector de frutas", function(on)
            fruitFinder = on
            refreshObjectHighlights("fruit", on)
        end)

        makeLabel(
            "O detector destaca objetos encontrados no Workspace com 'fruit' no nome. Não revela frutas que o servidor não replicou ao cliente.",
            65
        )

    elseif category == "Coleta e evolução" then
        makeLabel(
            "Coleta automática, missões, evolução e recompensas dependem dos sistemas internos do jogo e de validação do servidor.",
            75
        )

        makeLabel(
            "Para implementar essas ações corretamente, é necessário ter acesso ao código da experiência e aos RemoteEvents oficiais dela.",
            65
        )

    elseif category == "Configurações" then
        makeButton("Recentralizar painel", function()
            Main.Position = UDim2.new(0.5, -310, 0.5, -215)
            setStatus("Painel recentralizado.")
        end)

        makeButton("Reaplicar velocidade e pulo", function()
            local hum = getCharacter()
                and getCharacter():FindFirstChildOfClass("Humanoid")

            if hum then
                hum.WalkSpeed = walkSpeed
                hum.UseJumpPower = true
                hum.JumpPower = jumpPower
                setStatus("Configurações locais reaplicadas.")
            end
        end)

        makeButton("Limpar destaques visuais", function()
            espPlayers, showNames, showDistances, fruitFinder, chestFinder =
                false, false, false, false, false

            removeHighlights(playerHighlights)
            removeHighlights(objectHighlights)

            setStatus("Destaques removidos.")
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
    tab.BackgroundColor3 = category == "Início"
        and COLORS.purple or COLORS.row
    tab.Text = category
    tab.TextColor3 = COLORS.white
    tab.TextSize = 11
    tab.Font = Enum.Font.GothamBold
    tab.TextWrapped = true
    tab.Parent = Sidebar

    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 7)

    tab.MouseButton1Click:Connect(function()
        for _, sibling in ipairs(Sidebar:GetChildren()) do
            if sibling:IsA("TextButton") then
                sibling.BackgroundColor3 = COLORS.row
            end
        end

        tab.BackgroundColor3 = COLORS.purple
        showCategory(category)
    end)
end

Min.MouseButton1Click:Connect(MinimizePanel)

Close.MouseButton1Click:Connect(function()
    destroyed = true

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    removeHighlights(playerHighlights)
    removeHighlights(objectHighlights)
    Screen:Destroy()
end)

-- Arrastar pelo cabeçalho, inclusive em tela touch.
local dragging = false
local dragInput, dragStart, startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
        dragInput = input
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        dragInput = input
    end
end)

table.insert(connections, UIS.InputChanged:Connect(function(input)
    if dragging and (
        input == dragInput
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

-- Ajuste automático para telas pequenas.
local camera = Workspace.CurrentCamera

local function fitToScreen()
    if not camera or minimized then
        return
    end

    local viewport = camera.ViewportSize
    local width = math.max(300, math.min(620, viewport.X - 24))
    local height = math.max(280, math.min(430, viewport.Y - 40))

    expandedSize = UDim2.fromOffset(width, height)
    Main.Size = expandedSize
    Main.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)

    Sidebar.Size = UDim2.new(
        0,
        math.min(145, width * 0.27),
        1,
        -60
    )

    Content.Position = UDim2.fromOffset(
        math.min(153, width * 0.29),
        54
    )

    Content.Size = UDim2.new(
        1,
        -math.min(166, width * 0.31),
        1,
        -60
    )
end

fitToScreen()

if camera then
    table.insert(
        connections,
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)
    )
end

table.insert(connections, UIS.JumpRequest:Connect(function()
    if infiniteJump then
        local hum = getCharacter()
            and getCharacter():FindFirstChildOfClass("Humanoid")

        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

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
        for part, originalValue in pairs(collisionCache) do
            if part and part.Parent then
                part.CanCollide = originalValue
            end

            collisionCache[part] = nil
        end
    end
end))

table.insert(connections, Players.PlayerAdded:Connect(function()
    if espPlayers or showNames or showDistances then
        task.delay(0.5, applyPlayerVisuals)
    end
end))

table.insert(connections, Players.PlayerRemoving:Connect(function()
    if espPlayers or showNames or showDistances then
        task.delay(0.2, applyPlayerVisuals)
    end
end))

showCategory("Início")

print("Blox F' - Tales 3.0 carregado.")
