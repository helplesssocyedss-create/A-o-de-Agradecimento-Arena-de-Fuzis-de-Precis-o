--========================================================
-- BLOX F' - TALES | VERSAO 5.3
-- Fly suavizado e combate coordenado com Anti-Ataque sem esquivas por simples proximidade.
-- Defesa baseada em sinais observaveis; nao presume cooldown fixo de todas as habilidades.
-- Versao focada em controles locais e combate somente contra NPCs.
-- Acoes de inventario, missao, evento e recompensa exigem integracao oficial no servidor.
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
local selectedAttackTargets = {}
local connections = {}
local playerHighlights = {}
local fruitHighlights = {}
local chestHighlights = {}
local bossHighlights = {}

local infiniteJump = false
local noclip = false
local showNames = false
local showDistances = false
local espPlayers = false
local bossESP = false
local fruitFinder = false
local chestFinder = false
local destroyed = false
local collisionCache = {}

local walkSpeed = 16
local jumpPower = 50
local flyEnabled = false
local antiAttackEnabled = false
local antiAttackDodgeUntil = 0
local antiAttackDodgeDirection = Vector3.zero
local antiAttackDodgeSpeed = 0
local antiAttackLastTrigger = 0
local antiAttackSide = 1
local antiAttackLastHealth = nil
local antiAttackLastPlayerThreat = nil
local antiAttackThreatMemory = {}
-- O limite do controle de Fly foi ampliado; o servidor ainda pode limitar a física.
local flySpeed = 350
flySpeed = math.clamp(flySpeed, 50, 1400)

local function getAdjustedWalkSpeed()
    return walkSpeed
end

local function getAdjustedFlySpeed()
    return flySpeed
end

-- NOVO: velocidade da aproximação até o jogador.
local playerTeleportSpeed = 100

local function getAdjustedTeleportSpeed()
    return playerTeleportSpeed
end
local playerTeleportSequence = 0

local aimAssistEnabled = false
local aimFovEnabled = false
local aimFovRadius = 140
local autoAttackEnabled = false
local autoHakiEnabled = false
local autoSkillsEnabled = false
local autoFarmEnabled = false
local autoBossFarmEnabled = false
local selectedCombatToolName = nil
local autoChestEnabled = false
local autoFruitEnabled = false
local autoMissionEnabled = false
local autoEvolutionEnabled = false
local autoRewardsEnabled = false

-- Parametros configuraveis de combate contra NPCs.
local combatAttackRange = 24
local combatSkillRange = 180
local combatFollowDistance = 9
local combatStopDistance = 11

local selectedAimTarget = "NPCs"
local attackDropdownOpen = false
local targetTypeDropdownOpen = false

local selectedFruitName = nil
local pendingFruitName = nil
local fruitDropdownOpen = false

local fruitCatalog = {
    "Rocket", "Spin", "Blade", "Spring", "Bomb", "Smoke",
    "Spike", "Flame", "Falcon", "Ice", "Sand", "Dark",
    "Diamond", "Light", "Rubber", "Barrier", "Ghost", "Magma",
    "Quake", "Buddha", "Love", "Spider", "Sound", "Phoenix",
    "Portal", "Rumble", "Pain", "Blizzard", "Gravity", "Mammoth",
    "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit",
    "Dragon", "Leopard", "Kitsune", "Gas", "Yeti"
}

local combatFollowTarget = nil
local lastFollowJump = 0
local followJumpCooldown = 0.85
local followFlyActive = false

-- Um unico controlador de velocidade e compartilhado pelo Fly e pelo Anti-Ataque.
-- Isso evita que dois loops escrevam propriedades fisicas diferentes no mesmo frame.
local managedVelocityRoot = nil
local managedVelocityAttachment = nil
local managedLinearVelocity = nil
local antiAttackWasDriving = false
local combatLastMoveGoal = nil
local combatLastMoveAt = 0
local combatWasInRange = false

-- Filtro de velocidade para reduzir trancos ao mudar de direcao ou seguir alvo.
local flyCurrentVelocity = Vector3.zero
local flyVelocityRoot = nil
local flyLastHeartbeatAt = os.clock()
local FLY_ACCELERATION_RESPONSE = 13.5

local function getSmoothedFlyVelocity(root, desiredVelocity, deltaTime)
    if flyVelocityRoot ~= root then
        flyVelocityRoot = root
        flyCurrentVelocity = root.AssemblyLinearVelocity
    end
    local dt = math.clamp(deltaTime or (1 / 60), 1 / 240, 0.08)
    local alpha = 1 - math.exp(-FLY_ACCELERATION_RESPONSE * dt)
    flyCurrentVelocity = flyCurrentVelocity:Lerp(desiredVelocity, alpha)
    local maximum = 1400
    if flyCurrentVelocity.Magnitude > maximum then
        flyCurrentVelocity = flyCurrentVelocity.Unit * maximum
    end
    return flyCurrentVelocity
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "BloxFTales"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = PlayerGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "AimFOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(aimFovRadius * 2, aimFovRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.ZIndex = 100
FOVCircle.Parent = Screen

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = COLORS.purple
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.15
FOVStroke.Parent = FOVCircle
FOVCircle.Active = false

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
Title.Text = "Blox F' - Tales  |  5.3"
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

local Sidebar, Content
local minimized = false
local expandedSize = UDim2.fromOffset(620, 430)
local expandedPosition = Main.Position

local function tween(object, props, duration)
    TweenService:Create(
        object,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props
    ):Play()
end

local StatusLabel

local function setStatus(message)
    if StatusLabel and StatusLabel.Parent then
        StatusLabel.Text = "Status: " .. tostring(message)
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
        tween(Main, {Size = UDim2.fromOffset(60, 60)}, 0.22)
        tween(Header, {Size = UDim2.fromOffset(60, 60)}, 0.22)
    else
        tween(Main, {Size = expandedSize}, 0.22)
        tween(Header, {Size = UDim2.new(1, 0, 0, 48)}, 0.22)
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

Sidebar = Instance.new("ScrollingFrame")
Sidebar.ScrollBarThickness = 3
Sidebar.ScrollBarImageColor3 = COLORS.purple
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
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

tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 12)
end)

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

local activeContainer = Content

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 8)
contentPadding.PaddingBottom = UDim.new(0, 8)
contentPadding.PaddingLeft = UDim.new(0, 8)
contentPadding.PaddingRight = UDim.new(0, 8)
contentPadding.Parent = Content

StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "PersistentStatus"
StatusLabel.LayoutOrder = -100
StatusLabel.Size = UDim2.new(1, -4, 0, 26)
StatusLabel.BackgroundColor3 = COLORS.row
StatusLabel.BorderSizePixel = 0
StatusLabel.Text = "Status: pronto"
StatusLabel.TextColor3 = COLORS.white
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Content
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 18)
end)

local function clearContent()
    activeContainer = Content
    for _, child in ipairs(Content:GetChildren()) do
        if child ~= contentLayout and child ~= contentPadding and child ~= StatusLabel then
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
    label.Parent = activeContainer
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
    button.Parent = activeContainer
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    button.Activated:Connect(function()
        if callback then callback() end
    end)

    return button
end

local function makeInput(labelText, placeholder, defaultValue, callback)
    makeLabel(labelText, 25)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -4, 0, 36)
    box.BackgroundColor3 = COLORS.row
    box.TextColor3 = COLORS.white
    box.PlaceholderText = placeholder or "Digite um valor"
    box.Text = tostring(defaultValue or "")
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Parent = activeContainer
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)

    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)

    return box
end

local function makeToggle(name, callback, initial)
    if states[name] == nil then
        states[name] = initial or false
    end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 40)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = activeContainer
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

    switch.Activated:Connect(function()
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

local function beginSection(title, initiallyOpen)
    if initiallyOpen == nil then initiallyOpen = true end

    local header = Instance.new("TextButton")
    header.Name = "SectionHeader"
    header.Size = UDim2.new(1, -4, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(48, 35, 68)
    header.TextColor3 = COLORS.white
    header.TextSize = 13
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = (initiallyOpen and "▼  " or "▶  ") .. title
    header.AutoButtonColor = true
    header.Parent = Content
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 7)

    local body = Instance.new("Frame")
    body.Name = "SectionBody"
    body.Size = UDim2.new(1, -4, 0, 0)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.AutomaticSize = initiallyOpen and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
    body.Visible = initiallyOpen
    body.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = body

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 2)
    padding.PaddingTop = UDim.new(0, 3)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = body

    header.Activated:Connect(function()
        local open = not body.Visible
        body.Visible = open
        body.AutomaticSize = open and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
        body.Size = UDim2.new(1, -4, 0, 0)
        header.Text = (open and "▼  " or "▶  ") .. title
    end)

    activeContainer = body
    return body
end

local function endSection()
    activeContainer = Content
end

local function makeOption(labelText, isSelected, callback)
    local button = Instance.new("TextButton")
    button.Name = "SelectionOption"
    button.Size = UDim2.new(1, -4, 0, 38)
    button.BackgroundColor3 = isSelected and COLORS.green or COLORS.row
    button.BorderSizePixel = 0
    button.Text = (isSelected and "✓   " or "○   ") .. labelText
    button.TextColor3 = COLORS.white
    button.TextSize = 12
    button.Font = Enum.Font.Gotham
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.Parent = activeContainer
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    button.Activated:Connect(function()
        if callback then callback() end
    end)

    return button
end

local function makeSlider(labelText, minValue, maxValue, initialValue, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -4, 0, 64)
    holder.BackgroundColor3 = COLORS.row
    holder.BorderSizePixel = 0
    holder.Parent = activeContainer
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 7)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.fromOffset(10, 2)
    title.BackgroundTransparency = 1
    title.TextColor3 = COLORS.white
    title.Font = Enum.Font.Gotham
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = labelText .. ": " .. tostring(initialValue)
    title.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -24, 0, 8)
    bar.Position = UDim2.fromOffset(12, 39)
    bar.BackgroundColor3 = COLORS.gray
    bar.BorderSizePixel = 0
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initialValue - minValue) / (maxValue - minValue), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.purple
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = COLORS.white
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    local value = initialValue

    local function setValueFromX(x)
        local percent = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor(minValue + (maxValue - minValue) * percent + 0.5)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, 0, 0.5, 0)
        title.Text = labelText .. ": " .. tostring(value)
        if callback then callback(value) end
    end

    local function beginDrag(input)
        draggingSlider = true
        setValueFromX(input.Position.X)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    local moveConnection = UIS.InputChanged:Connect(function(input)
        if draggingSlider and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            setValueFromX(input.Position.X)
        end
    end)

    local endConnection = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    table.insert(connections, moveConnection)
    table.insert(connections, endConnection)

    return holder
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function clearManagedVelocity()
    if managedLinearVelocity then
        pcall(function() managedLinearVelocity:Destroy() end)
    end
    if managedVelocityAttachment then
        pcall(function() managedVelocityAttachment:Destroy() end)
    end
    managedLinearVelocity = nil
    managedVelocityAttachment = nil
    managedVelocityRoot = nil
end

local function setManagedVelocity(root, velocity)
    if not root or not root.Parent then return false end

    if managedVelocityRoot ~= root
        or not managedLinearVelocity or not managedLinearVelocity.Parent then
        clearManagedVelocity()
        managedVelocityRoot = root

        local attachment = Instance.new("Attachment")
        attachment.Name = "BloxFTales_MovementAttachment"
        attachment.Parent = root

        local linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Name = "BloxFTales_MovementController"
        linearVelocity.Attachment0 = attachment
        linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        linearVelocity.ForceLimitsEnabled = false
        linearVelocity.VectorVelocity = Vector3.zero
        linearVelocity.Parent = root

        managedVelocityAttachment = attachment
        managedLinearVelocity = linearVelocity
    end

    managedLinearVelocity.VectorVelocity = velocity
    return true
end

--========================================================
-- TELETRANSPORTE GRADUAL PARA ILHAS E COORDENADAS
--========================================================

local teleportSequence = 0

local function teleportLocal(destination)
    local character = getCharacter()
    local root = getRoot(character)

    if not root then
        setStatus("Personagem ainda não carregou.")
        return false
    end

    local targetCFrame

    if typeof(destination) == "CFrame" then
        targetCFrame = destination
    elseif typeof(destination) == "Vector3" then
        targetCFrame = CFrame.new(destination + Vector3.new(0, 4, 0))
    else
        return false
    end

    teleportSequence += 1
    local thisSequence = teleportSequence

    task.spawn(function()
        local currentCharacter = getCharacter()
        local currentRoot = getRoot(currentCharacter)
        local currentHumanoid = currentCharacter
            and currentCharacter:FindFirstChildOfClass("Humanoid")

        if not currentRoot or not currentHumanoid then return end

        local startPosition = currentRoot.Position
        local destinationPosition = targetCFrame.Position
        local distance = (destinationPosition - startPosition).Magnitude
        local steps = math.clamp(math.ceil(distance / 35), 1, 45)

        for step = 1, steps do
            if not Screen.Parent or thisSequence ~= teleportSequence then
                return
            end

            currentCharacter = getCharacter()
            currentRoot = getRoot(currentCharacter)
            currentHumanoid = currentCharacter
                and currentCharacter:FindFirstChildOfClass("Humanoid")

            if not currentRoot or not currentHumanoid then return end

            local alpha = step / steps
            local nextPosition = startPosition:Lerp(destinationPosition, alpha)

            currentHumanoid:MoveTo(nextPosition)

            pcall(function()
                currentCharacter:PivotTo(
                    CFrame.new(nextPosition) * targetCFrame.Rotation
                )
            end)

            task.wait(0.045)
        end

        if not Screen.Parent or thisSequence ~= teleportSequence then
            return
        end

        currentCharacter = getCharacter()
        currentRoot = getRoot(currentCharacter)

        if not currentCharacter or not currentRoot then return end

        for attempt = 1, 8 do
            if not Screen.Parent or thisSequence ~= teleportSequence then
                return
            end

            currentRoot = getRoot(getCharacter())
            currentCharacter = getCharacter()

            if not currentRoot or not currentCharacter then break end

            if (currentRoot.Position - targetCFrame.Position).Magnitude <= 6 then
                break
            end

            pcall(function()
                currentCharacter:PivotTo(targetCFrame)
            end)

            task.wait(0.12)
        end

        local finalRoot = getRoot(getCharacter())

        if finalRoot then
            local remaining = (finalRoot.Position - targetCFrame.Position).Magnitude

            if remaining <= 12 then
                setStatus("Chegou próximo ao destino.")
            else
                setStatus("O servidor pode corrigir a posição.")
            end
        end
    end)

    return true
end

--========================================================
-- TELETRANSPORTE PLAYER COM SPEED AJUSTÁVEL
--========================================================

local function teleportToPlayer(target)
    if not target or not target.Parent then
        setStatus("Jogador indisponível.")
        return
    end

    if not getRoot(target.Character) then
        setStatus("O personagem do jogador não está disponível.")
        return
    end

    playerTeleportSequence += 1
    local thisSequence = playerTeleportSequence

    task.spawn(function()
        local character = getCharacter()
        local root = getRoot(character)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not root or not humanoid then
            setStatus("Personagem ainda não carregou.")
            return
        end

        local originalSpeed = humanoid.WalkSpeed
        local finished = false
        local startTime = os.clock()

        humanoid.WalkSpeed = getAdjustedTeleportSpeed()

        setStatus("Correndo até " .. target.DisplayName .. "...")

        while Screen.Parent
            and thisSequence == playerTeleportSequence
            and target.Parent
            and os.clock() - startTime < 60 do

            character = getCharacter()
            root = getRoot(character)
            humanoid = character and character:FindFirstChildOfClass("Humanoid")

            local targetCharacter = target.Character
            local targetRoot = getRoot(targetCharacter)

            if not root or not humanoid or humanoid.Health <= 0 or not targetRoot then
                break
            end

            humanoid.WalkSpeed = getAdjustedTeleportSpeed()

            local offset = targetRoot.Position - root.Position
            local distance = offset.Magnitude

            if distance <= 6 then
                finished = true
                break
            end

            local approachPosition = targetRoot.Position
                - targetRoot.CFrame.LookVector * 4

            humanoid:MoveTo(approachPosition)

            local verticalDifference = targetRoot.Position.Y - root.Position.Y
            local horizontalDifference = Vector3.new(
                offset.X,
                0,
                offset.Z
            ).Magnitude

            if verticalDifference > 3.2 and horizontalDifference < 45 then
                humanoid.Jump = true
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end

            task.wait(0.12)
        end

        character = getCharacter()
        humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.WalkSpeed = originalSpeed
        end

        if thisSequence ~= playerTeleportSequence then
            return
        end

        if finished then
            setStatus("Você chegou próximo de " .. target.DisplayName .. ".")
        elseif not target.Parent then
            setStatus("O jogador saiu do servidor.")
        else
            setStatus("Aproximação encerrada. O servidor pode limitar a velocidade.")
        end
    end)
end

local function normalizeName(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s_%-]", "")
    return value
end

local function findNamedWorldObject(names)
    local aliases = {}
    for _, name in ipairs(names) do
        aliases[normalizeName(name)] = true
    end

    local bestObject, bestScore = nil, -1

    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("Model") or item:IsA("BasePart") then
            local candidate = normalizeName(item.Name)

            for alias in pairs(aliases) do
                local score = -1
                if candidate == alias then
                    score = 3
                elseif #alias >= 5 and string.find(candidate, alias, 1, true) then
                    score = 2
                elseif #candidate >= 5 and string.find(alias, candidate, 1, true) then
                    score = 1
                end

                if score > bestScore then
                    bestObject, bestScore = item, score
                end
            end
        end
    end

    if not bestObject or bestScore < 1 then return nil end

    if bestObject:IsA("Model") then
        local ok, pivot = pcall(function()
            return bestObject:GetPivot()
        end)
        if ok then return pivot end
    elseif bestObject:IsA("BasePart") then
        return bestObject.CFrame
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
    local bucket = kind == "fruit" and fruitHighlights or chestHighlights
    removeHighlights(bucket)

    if not enabled then return end

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
            bucket[item] = h
        end
    end
end

local function refreshBossESP(enabled)
    removeHighlights(bossHighlights)
    if not enabled then return end

    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") then
            local name = string.lower(item.Name)

            if string.find(name, "boss", 1, true)
                or string.find(name, "raid", 1, true) then

                local h = Instance.new("Highlight")
                h.FillColor = COLORS.red
                h.OutlineColor = COLORS.white
                h.FillTransparency = 0.55
                h.Adornee = item
                h.Parent = Screen
                bossHighlights[item] = h
            end
        end
    end
end

local function makePlayerSelection()
    makeLabel("Selecione um jogador e use o botão de confirmação abaixo.", 38)
    local selectionLabel = makeLabel("Selecionado: nenhum", 25)
    local confirmButton
    local optionButtons = {}

    local function updateSelection()
        selectionLabel.Text = "Selecionado: " .. (selectedPlayer and selectedPlayer.DisplayName or "nenhum")

        for player, button in pairs(optionButtons) do
            if button and button.Parent then
                local chosen = player == selectedPlayer
                button.BackgroundColor3 = chosen and COLORS.green or COLORS.row
                button.Text = (chosen and "✓   " or "○   ")
                    .. player.DisplayName .. "  (@" .. player.Name .. ")"
            end
        end

        if confirmButton then
            confirmButton.Visible = selectedPlayer ~= nil
        end
    end

    local targets = Players:GetPlayers()
    table.sort(targets, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    local found = false

    for _, target in ipairs(targets) do
        if target ~= LocalPlayer then
            found = true

            local button = makeOption(
                target.DisplayName .. "  (@" .. target.Name .. ")",
                selectedPlayer == target,
                function()
                    selectedPlayer = selectedPlayer == target and nil or target
                    updateSelection()
                end
            )

            optionButtons[target] = button
        end
    end

    if not found then
        makeLabel("Nenhum outro jogador está no servidor.", 32)
    end

    confirmButton = makeButton("CONFIRMAR IDA ATÉ O JOGADOR", function()
        local target = selectedPlayer

        if not target or not target.Parent then
            setStatus("Selecione um jogador que ainda esteja no servidor.")
            return
        end

        if not getRoot(target.Character) then
            setStatus("O personagem do jogador não está disponível.")
            return
        end

        local dialog = Instance.new("Frame")
        dialog.Size = UDim2.fromOffset(280, 118)
        dialog.AnchorPoint = Vector2.new(0.5, 0.5)
        dialog.Position = UDim2.fromScale(0.5, 0.5)
        dialog.BackgroundColor3 = COLORS.panel
        dialog.ZIndex = 30
        dialog.Parent = Screen
        Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 10)

        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -16, 0, 54)
        msg.Position = UDim2.fromOffset(8, 4)
        msg.BackgroundTransparency = 1
        msg.Text = "Confirmar ida até " .. target.DisplayName .. "?"
        msg.TextColor3 = COLORS.white
        msg.TextWrapped = true
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 13
        msg.ZIndex = 31
        msg.Parent = dialog

        local yes = Instance.new("TextButton")
        yes.Size = UDim2.new(0.45, 0, 0, 34)
        yes.Position = UDim2.new(0.03, 0, 1, -42)
        yes.Text = "Confirmar"
        yes.BackgroundColor3 = COLORS.green
        yes.TextColor3 = COLORS.white
        yes.ZIndex = 31
        yes.Parent = dialog

        local no = Instance.new("TextButton")
        no.Size = UDim2.new(0.45, 0, 0, 34)
        no.Position = UDim2.new(0.52, 0, 1, -42)
        no.Text = "Cancelar"
        no.BackgroundColor3 = COLORS.red
        no.TextColor3 = COLORS.white
        no.ZIndex = 31
        no.Parent = dialog

        yes.Activated:Connect(function()
            teleportToPlayer(target)
            dialog:Destroy()
        end)

        no.Activated:Connect(function()
            dialog:Destroy()
        end)
    end, COLORS.purple)

    confirmButton.Visible = selectedPlayer ~= nil
    updateSelection()
end

local function makeSpeedControl()
    makeSlider("Velocidade de caminhada", 0, 100, walkSpeed, function(value)
        walkSpeed = value
        local character = getCharacter()
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = getAdjustedWalkSpeed() end
        setStatus("Velocidade de caminhada: " .. walkSpeed)
    end)

    makeSlider("Força do pulo", 0, 150, jumpPower, function(value)
        jumpPower = value
        local character = getCharacter()
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = jumpPower
        end
        setStatus("Pulo local: " .. jumpPower)
    end)
end

local function getPlayerFromModel(model)
    if not model then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character == model then
            return player
        end
    end

    return nil
end

local function isValidAimType(model)
    -- Mira e combate automaticos ficam restritos a NPCs da experiencia.
    return model ~= nil
        and model ~= getCharacter()
        and getPlayerFromModel(model) == nil
end

local function getAttackableTargets()
    local targets = {}
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("Model") and item ~= getCharacter()
            and not getPlayerFromModel(item) then
            local hum = item:FindFirstChildOfClass("Humanoid")
            local root = getRoot(item)
            if hum and hum.Health > 0 and root then
                table.insert(targets, {
                    model = item,
                    humanoid = hum,
                    root = root,
                    name = item.Name
                })
            end
        end
    end
    return targets
end

local function refreshAttackTargetList(container, statusLabel)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextButton") and child.Name == "AttackTargetOption" then
            child:Destroy()
        elseif child:IsA("TextLabel") and child.Name == "AttackTargetOption" then
            child:Destroy()
        end
    end

    local targets = getAttackableTargets()

    table.sort(targets, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    if #targets == 0 then
        local empty = Instance.new("TextLabel")
        empty.Name = "AttackTargetOption"
        empty.Size = UDim2.new(1, -4, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "Nenhum alvo encontrado."
        empty.TextColor3 = COLORS.white
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.Parent = container
        return
    end

    for _, target in ipairs(targets) do
        local selected = selectedAttackTargets[target.model] == true

        local option = Instance.new("TextButton")
        option.Name = "AttackTargetOption"
        option.Size = UDim2.new(1, -4, 0, 34)
        option.BackgroundColor3 = selected and COLORS.green or COLORS.row
        option.TextColor3 = COLORS.white
        option.TextSize = 12
        option.Font = Enum.Font.Gotham
        option.TextXAlignment = Enum.TextXAlignment.Left
        option.Text = (selected and "✓   " or "○   ") .. target.name
        option.Parent = container
        Instance.new("UICorner", option).CornerRadius = UDim.new(0, 6)

        option.Activated:Connect(function()
            selectedAttackTargets[target.model] = not selectedAttackTargets[target.model]

            option.BackgroundColor3 =
                selectedAttackTargets[target.model] and COLORS.green or COLORS.row

            option.Text = (selectedAttackTargets[target.model] and "✓   " or "○   ")
                .. target.name

            local count = 0
            for model in pairs(selectedAttackTargets) do
                if model and model.Parent and isValidAimType(model) then
                    count += 1
                end
            end

            statusLabel.Text = "Alvos selecionados: " .. count
        end)
    end
end

--========================================================
-- COMBATE AUTOMÁTICO
--========================================================

local attackLoopRunning = false
local lastToolUse = 0
local lastDodge = 0
local dodgeSide = 1

local function getCombatTools(character)
    local tools = {}
    local seen = {}

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    local function addTools(container)
        if not container then return end

        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and not seen[item] then
                seen[item] = true
                table.insert(tools, item)
            end
        end
    end

    addTools(character)
    addTools(backpack)

    return tools
end

local function equipCombatTool(character, humanoid)
    local tools = getCombatTools(character)
    local equipped = nil

    if selectedCombatToolName then
        local wanted = normalizeName(selectedCombatToolName)
        for _, tool in ipairs(tools) do
            if normalizeName(tool.Name) == wanted then
                equipped = tool
                break
            end
        end
    end

    if not equipped then
        for _, tool in ipairs(tools) do
            if tool.Parent == character then
                equipped = tool
                break
            end
        end
    end

    if equipped and equipped.Parent ~= character then
        pcall(function() humanoid:EquipTool(equipped) end)
    end

    if not equipped then
        for _, tool in ipairs(tools) do
            if tool:IsA("Tool") then
                pcall(function() humanoid:EquipTool(tool) end)
                equipped = tool
                break
            end
        end
    end
    return equipped
end

local function getEquippedFruitTool(character)
    if not selectedFruitName then
        return nil
    end

    local selectedKey = normalizeName(selectedFruitName)
    local tools = getCombatTools(character)

    for _, tool in ipairs(tools) do
        local toolName = normalizeName(tool.Name)

        if toolName == selectedKey
            or string.find(toolName, selectedKey, 1, true)
            or string.find(selectedKey, toolName, 1, true) then
            return tool
        end
    end

    return nil
end

local skillKeys = {
    Enum.KeyCode.Z,
    Enum.KeyCode.X,
    Enum.KeyCode.C,
    Enum.KeyCode.V,
    Enum.KeyCode.F
}

local skillKeyIndex = 0
local lastSkillUse = 0
local lastSkillUseByFruit = {}
local lastSkillKeyUsed = nil
local combatDodgeUntil = 0
local combatDodgeVector = Vector3.zero
local lastObservedHealth = nil
local virtualInputManager

-- Tempos publicados para algumas frutas/movimentos. Para frutas sem dado confiável,
-- usa-se um intervalo conservador por tecla; o servidor continua sendo a autoridade.
local fruitSkillCooldowns = {
    Sound = {Z = 10, X = 12, C = 15, V = 25, F = 4},
    Portal = {Z = 7.5, X = 18.75, C = 16.5, V = 18, F = 7.5},
    Blizzard = {Z = 8.25, X = 12.75, C = 16.5, V = 27, F = 6},
    Ice = {Z = 9, X = 14},
    Spike = {Z = 6, X = 10.5}
}

local fallbackSkillCooldowns = {Z = 10, X = 12, C = 15, V = 20, F = 8}

local function getSkillCooldown(fruitName, keyName)
    local fruitData = fruitSkillCooldowns[fruitName]
    if fruitData and fruitData[keyName] then
        return fruitData[keyName]
    end
    return fallbackSkillCooldowns[keyName] or 12
end

pcall(function()
    virtualInputManager = game:GetService("VirtualInputManager")
end)

local function sendSkillKey(keyCode)
    if not virtualInputManager then
        return false
    end

    local sent = false

    local ok = pcall(function()
        virtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.08)
        virtualInputManager:SendKeyEvent(false, keyCode, false, game)
        sent = true
    end)

    return ok and sent
end

local function activateFruitSkills(character)
    if not autoSkillsEnabled then return false end

    if not selectedFruitName then
        setStatus("Selecione e confirme sua fruta na aba Combate.")
        return false
    end

    local fruitTool = getEquippedFruitTool(character)
    if not fruitTool then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and fruitTool.Parent ~= character then
        pcall(function() humanoid:EquipTool(fruitTool) end)
        return false
    end
    if fruitTool.Parent ~= character then return false end

    local now = os.clock()
    local fruitHistory = lastSkillUseByFruit[selectedFruitName]
    if not fruitHistory then
        fruitHistory = {}
        lastSkillUseByFruit[selectedFruitName] = fruitHistory
    end

    -- Procura a próxima tecla cuja recarga individual já terminou.
    for offset = 1, #skillKeys do
        local index = ((skillKeyIndex + offset - 1) % #skillKeys) + 1
        local keyCode = skillKeys[index]
        local keyName = keyCode.Name
        local cooldown = getSkillCooldown(selectedFruitName, keyName)
        local previousUse = fruitHistory[keyName] or 0

        if now - previousUse >= cooldown then
            skillKeyIndex = index
            lastSkillUse = now
            lastSkillKeyUsed = keyName
            fruitHistory[keyName] = now

            local sent = sendSkillKey(keyCode)
            if not sent then
                pcall(function() fruitTool:Activate() end)
            end

            -- Após tentar uma habilidade, abre uma janela curta para sair da linha de ataque.
            combatDodgeUntil = math.max(combatDodgeUntil, now + 0.85)
            setStatus("Habilidade " .. selectedFruitName .. " / " .. keyName .. " (recarga individual)")
            return true
        end
    end

    return false
end

local function activateCombatTools(character, humanoid)
    local now = os.clock()
    local tool = nil

    -- A fruta confirmada no painel tem prioridade; nao troca para uma Tool aleatoria.
    if selectedFruitName then
        tool = getEquippedFruitTool(character)
        if tool and tool.Parent ~= character then
            pcall(function() humanoid:EquipTool(tool) end)
            return false
        end
    end

    if autoSkillsEnabled and tool and tool.Parent == character then
        activateFruitSkills(character)
    end

    if now - lastToolUse < 0.55 then return false end
    lastToolUse = now

    if not tool or tool.Parent ~= character then
        tool = equipCombatTool(character, humanoid)
    end
    if tool and tool.Parent == character then
        pcall(function() tool:Activate() end)
        return true
    end
    return false
end

local nearestNpcInfo, nearestBossInfo

local function getCurrentSelectedTarget()
    local validTargets = {}

    for model in pairs(selectedAttackTargets) do
        if model and model.Parent then
            local targetHum = model:FindFirstChildOfClass("Humanoid")
            local targetRoot = getRoot(model)

            if targetHum and targetHum.Health > 0 and targetRoot
                and isValidAimType(model) then

                table.insert(validTargets, {
                    model = model,
                    humanoid = targetHum,
                    root = targetRoot
                })
            else
                selectedAttackTargets[model] = nil
            end
        else
            selectedAttackTargets[model] = nil
        end
    end

    if #validTargets == 0 then
        local fallbackModel = nil
        if autoBossFarmEnabled then
            fallbackModel = nearestBossInfo()
        elseif autoFarmEnabled then
            fallbackModel = nearestNpcInfo()
        end
        if fallbackModel and fallbackModel.Parent then
            local fallbackHum = fallbackModel:FindFirstChildOfClass("Humanoid")
            local fallbackRoot = getRoot(fallbackModel)
            if fallbackHum and fallbackHum.Health > 0 and fallbackRoot then
                return {model = fallbackModel, humanoid = fallbackHum, root = fallbackRoot}
            end
        end
        return nil
    end

    local myRoot = getRoot(getCharacter())
    if not myRoot then return validTargets[1] end

    local nearest, nearestDistance = nil, math.huge

    for _, target in ipairs(validTargets) do
        local distance = (myRoot.Position - target.root.Position).Magnitude

        if distance < nearestDistance then
            nearest = target
            nearestDistance = distance
        end
    end

    return nearest
end

local function performCombatDodge(humanoid, root, targetRoot, force)
    -- Com o Anti-Ataque ativo, somente ele decide quando desviar.
    -- Isso evita que a esquiva periódica do combate empurre o personagem
    -- repetidamente para longe e interrompa a perseguição do alvo.
    if antiAttackEnabled then return false end
    if not humanoid or not root or not targetRoot then return false end

    local now = os.clock()
    local interval = force and 0.45 or 1.15
    if now - lastDodge < interval then return false end
    lastDodge = now

    dodgeSide = -dodgeSide

    local away = root.Position - targetRoot.Position
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.01 then
        away = Vector3.new(-targetRoot.CFrame.LookVector.X, 0, -targetRoot.CFrame.LookVector.Z)
    end
    if away.Magnitude < 0.01 then away = Vector3.new(0, 0, 1) end
    away = away.Unit

    local right = Vector3.new(-away.Z, 0, away.X)
    combatDodgeVector = (away * 0.82 + right * (dodgeSide * 0.95)).Unit
    combatDodgeUntil = now + (force and 1.0 or 0.7)

    local distance = force and 15 or 10
    humanoid:MoveTo(root.Position + combatDodgeVector * distance)
    return true
end

local function handleFollowJump(humanoid, root, targetRoot)
    if not humanoid or not root or not targetRoot then return end

    local now = os.clock()
    if now - lastFollowJump < followJumpCooldown then return end

    local verticalDifference = targetRoot.Position.Y - root.Position.Y
    local horizontalDistance = Vector3.new(
        targetRoot.Position.X - root.Position.X,
        0,
        targetRoot.Position.Z - root.Position.Z
    ).Magnitude

    local state = humanoid:GetState()
    local grounded =
        state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.RunningNoPhysics
        or state == Enum.HumanoidStateType.Landed

    if verticalDifference > 3.2 and horizontalDistance < 45 then
        lastFollowJump = now
        humanoid.Jump = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    elseif grounded and verticalDifference > 1.8 and horizontalDistance < 16 then
        lastFollowJump = now
        humanoid.Jump = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function startAttackLoop()
    if attackLoopRunning then return end
    attackLoopRunning = true

    task.spawn(function()
        while (autoAttackEnabled or autoHakiEnabled or autoSkillsEnabled or autoFarmEnabled or autoBossFarmEnabled)
            and Screen.Parent do

            local character = getCharacter()
            local root = getRoot(character)
            local hum = character and character:FindFirstChildOfClass("Humanoid")

            if not root or not hum or hum.Health <= 0 then
                combatFollowTarget = nil
                lastObservedHealth = nil
                task.wait(0.35)
                continue
            end

            hum.WalkSpeed = getAdjustedWalkSpeed()

            if lastObservedHealth and hum.Health < lastObservedHealth then
                local damagedTarget = getCurrentSelectedTarget()
                if damagedTarget then
                    performCombatDodge(hum, root, damagedTarget.root, true)
                end
            end
            lastObservedHealth = hum.Health

            local selectedTarget = getCurrentSelectedTarget()
            if selectedTarget then
                local targetRoot = selectedTarget.root
                combatFollowTarget = selectedTarget
                local distance = (root.Position - targetRoot.Position).Magnitude

                handleFollowJump(hum, root, targetRoot)

                -- Habilidades podem ser tentadas antes do alcance corpo a corpo.
                -- Ataque basico permanece limitado a uma distancia util do alvo.
                if distance <= combatSkillRange and autoSkillsEnabled then
                    activateCombatTools(character, hum)
                elseif distance <= combatAttackRange and (autoAttackEnabled or autoFarmEnabled or autoBossFarmEnabled) then
                    activateCombatTools(character, hum)
                end

                local skillRecovery = false
                local fruitHistory = selectedFruitName and lastSkillUseByFruit[selectedFruitName]
                if fruitHistory then
                    for _, keyCode in ipairs(skillKeys) do
                        local usedAt = fruitHistory[keyCode.Name]
                        if usedAt and (os.clock() - usedAt) < getSkillCooldown(selectedFruitName, keyCode.Name) then
                            skillRecovery = true
                            break
                        end
                    end
                end

                -- Arbitragem de movimento:
                -- 1) A janela de esquiva do Anti-Ataque tem prioridade absoluta.
                -- 2) Enquanto desvia, o combate continua atualizando o alvo e usando
                --    ataques/habilidades, mas não envia MoveTo concorrente.
                -- 3) Assim que a esquiva termina, a perseguição é retomada do ponto atual.
                local now = os.clock()
                local antiAttackDodging = antiAttackEnabled and now < antiAttackDodgeUntil

                if antiAttackDodging then
                    -- Nao enviar MoveTo nem Move durante a esquiva: o controlador fisico
                    -- compartilhado e o unico dono do movimento nessa janela.
                    -- Invalida o destino antigo; a perseguicao sera recalculada ao terminar.
                    combatLastMoveGoal = nil
                    combatLastMoveAt = 0
                    combatWasInRange = false
                elseif antiAttackEnabled then
                    -- O Anti-Ataque nao bloqueia o combate fora da janela de esquiva.
                    -- A perseguicao atualiza o destino apenas quando necessario.
                    if not flyEnabled then
                        if distance > combatStopDistance then
                            local desiredRange = distance > combatAttackRange and combatFollowDistance or math.max(4, combatFollowDistance - 2)
                            local goal = targetRoot.Position - targetRoot.CFrame.LookVector * desiredRange
                            if not combatLastMoveGoal
                                or (goal - combatLastMoveGoal).Magnitude > 4.5
                                or now - combatLastMoveAt > 0.65 then
                                hum:MoveTo(goal)
                                combatLastMoveGoal = goal
                                combatLastMoveAt = now
                            end
                            combatWasInRange = false
                        elseif not combatWasInRange then
                            -- Cancela uma perseguicao antiga apenas uma vez ao entrar no alcance.
                            hum:MoveTo(root.Position)
                            combatLastMoveGoal = root.Position
                            combatLastMoveAt = now
                            combatWasInRange = true
                        end
                    end
                elseif now < combatDodgeUntil then
                    if now - lastDodge >= 0.45 then
                        performCombatDodge(hum, root, targetRoot, true)
                    end
                elseif distance <= 16 and skillRecovery and now - lastDodge >= 1.15 then
                    performCombatDodge(hum, root, targetRoot, false)
                elseif distance <= 9 and now - lastDodge >= 1.15 then
                    performCombatDodge(hum, root, targetRoot, false)
                elseif distance > combatStopDistance and not flyEnabled then
                    local desiredRange = distance > combatAttackRange and combatFollowDistance or math.max(4, combatFollowDistance - 2)
                    local approachPosition = targetRoot.Position - targetRoot.CFrame.LookVector * desiredRange
                    if not combatLastMoveGoal
                        or (approachPosition - combatLastMoveGoal).Magnitude > 4.5
                        or now - combatLastMoveAt > 0.65 then
                        hum:MoveTo(approachPosition)
                        combatLastMoveGoal = approachPosition
                        combatLastMoveAt = now
                    end
                    combatWasInRange = false
                elseif distance <= combatStopDistance and not flyEnabled then
                    if not combatWasInRange then
                        hum:MoveTo(root.Position)
                        combatLastMoveGoal = root.Position
                        combatLastMoveAt = now
                        combatWasInRange = true
                    end
                elseif distance > 16 and flyEnabled then
                    -- O Heartbeat do Fly faz a perseguicao suavizada.
                end
            else
                combatFollowTarget = nil
                combatLastMoveGoal = nil
                combatLastMoveAt = 0
                combatWasInRange = false
                if not flyEnabled and not (antiAttackEnabled and os.clock() < antiAttackDodgeUntil) then
                    hum:MoveTo(root.Position)
                end
            end

            task.wait(0.08)
        end

        combatFollowTarget = nil
        lastObservedHealth = nil
        attackLoopRunning = false
    end)
end


local function makeToolSelector(title, terms)
    makeLabel(title .. ": escolha uma ferramenta que esteja no Backpack ou equipada.", 42)
    local selectedLabel = makeLabel("Ferramenta selecionada: " .. (selectedCombatToolName or "automática"), 26)
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -4, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BackgroundTransparency = 1
    list.Parent = activeContainer
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = list

    makeButton("ATUALIZAR FERRAMENTAS", function()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
        end
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        local found, seen = {}, {}
        local function scan(container)
            if not container then return end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local lower = string.lower(item.Name)
                    local match = #terms == 0
                    for _, term in ipairs(terms) do
                        if string.find(lower, term, 1, true) then match = true break end
                    end
                    if match and not seen[item.Name] then
                        seen[item.Name] = true
                        table.insert(found, item.Name)
                    end
                end
            end
        end
        scan(backpack)
        scan(getCharacter())
        table.sort(found)
        if #found == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, -4, 0, 32)
            empty.BackgroundTransparency = 1
            empty.Text = "Nenhuma ferramenta correspondente no inventário local."
            empty.TextColor3 = COLORS.white
            empty.TextSize = 11
            empty.Parent = list
        end
        for _, toolName in ipairs(found) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, -4, 0, 38)
            option.BackgroundColor3 = selectedCombatToolName == toolName and COLORS.green or COLORS.row
            option.Text = (selectedCombatToolName == toolName and "✓  " or "○  ") .. toolName
            option.TextColor3 = COLORS.white
            option.TextSize = 12
            option.Font = Enum.Font.Gotham
            option.Parent = list
            Instance.new("UICorner", option).CornerRadius = UDim.new(0, 7)
            option.Activated:Connect(function()
                selectedCombatToolName = toolName
                selectedLabel.Text = "Ferramenta selecionada: " .. toolName
                for _, sibling in ipairs(list:GetChildren()) do
                    if sibling:IsA("TextButton") then
                        sibling.BackgroundColor3 = sibling.Text:find(toolName, 1, true) and COLORS.green or COLORS.row
                    end
                end
                setStatus("Ferramenta selecionada: " .. toolName)
            end)
        end
        setStatus(#found .. " ferramenta(s) encontrada(s).")
    end, COLORS.purple)

    makeButton("USAR FERRAMENTA AUTOMÁTICA", function()
        selectedCombatToolName = nil
        selectedLabel.Text = "Ferramenta selecionada: automática"
        setStatus("Seleção manual removida; será usada a ferramenta equipada/disponível.")
    end)
end

local function addWorkspaceScanner(title, terms, maxItems)
    makeLabel(title .. " — leitura local dos objetos replicados no mapa.", 42)
    makeButton("ATUALIZAR LISTA", function()
        local matches, seen = {}, {}
        for _, item in ipairs(Workspace:GetDescendants()) do
            local lower = string.lower(item.Name)
            local match = false
            for _, term in ipairs(terms) do
                if string.find(lower, term, 1, true) then
                    match = true
                    break
                end
            end
            if match and (item:IsA("Model") or item:IsA("BasePart") or item:IsA("Tool")) then
                local fullName = item:GetFullName()
                if not seen[fullName] then
                    seen[fullName] = true
                    table.insert(matches, fullName)
                end
            end
        end
        table.sort(matches)
        local shown = math.min(#matches, maxItems or 30)
        setStatus(tostring(#matches) .. " resultado(s); exibindo " .. tostring(shown))
        local output = {}
        for index = 1, shown do
            table.insert(output, matches[index])
        end
        if #output == 0 then
            table.insert(output, "Nenhum objeto correspondente foi encontrado no Workspace.")
        end
        makeLabel(table.concat(output, "\n"), math.clamp(#output * 20, 42, 360))
    end, COLORS.purple)
end

--========================================================
-- CAMADA DE MONITORAMENTO LOCAL 5.1
-- Descoberta e destaque de objetos já replicados ao cliente.
-- Não dispara RemoteEvents desconhecidos nem altera dados do servidor.
--========================================================
local monitorJobs = {}
local monitorHighlights = {}
local monitorSnapshots = {}
local sessionEvents = {}
local objectiveSelection = nil

local function logSession(message)
    table.insert(sessionEvents, 1, os.date("%H:%M:%S") .. " | " .. tostring(message))
    while #sessionEvents > 100 do table.remove(sessionEvents) end
end

local function objectPosition(object)
    if not object or not object.Parent then return nil end
    if object:IsA("BasePart") then return object.Position end
    if object:IsA("Model") then
        local root = object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChildWhichIsA("BasePart", true)
        return root and root.Position or nil
    end
    return nil
end

local function scanReplicatedObjects(terms, limit, includeStorage, humanoidOnly)
    local roots = {Workspace}
    if includeStorage then table.insert(roots, game:GetService("ReplicatedStorage")) end
    local character = getCharacter()
    if character then table.insert(roots, character) end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then table.insert(roots, backpack) end
    local needles = {}
    for _, term in ipairs(terms or {}) do needles[#needles + 1] = string.lower(tostring(term)) end
    local found, seen = {}, {}
    for _, root in ipairs(roots) do
        local ok, descendants = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, item in ipairs(descendants) do
                local kind = item:IsA("Model") or item:IsA("BasePart") or item:IsA("Tool")
                local hasHumanoid = item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") ~= nil
                if kind and (not humanoidOnly or hasHumanoid) then
                    local name, matches = string.lower(item.Name), #needles == 0
                    for _, needle in ipairs(needles) do
                        if needle ~= "" and string.find(name, needle, 1, true) then matches = true break end
                    end
                    local path = item:GetFullName()
                    if matches and not seen[path] then
                        seen[path] = true
                        found[#found + 1] = item
                        if #found >= (limit or 100) then break end
                    end
                end
            end
        end
        if #found >= (limit or 100) then break end
    end
    table.sort(found, function(a,b) return a:GetFullName() < b:GetFullName() end)
    return found
end

local function clearMonitorHighlights(key)
    for _, highlight in pairs(monitorHighlights[key] or {}) do
        pcall(function() highlight:Destroy() end)
    end
    monitorHighlights[key] = nil
end

local function highlightMonitoredObject(key, object, color)
    if not object or not object.Parent then return end
    local adornee = object
    if object:IsA("Tool") then adornee = object:FindFirstAncestorOfClass("Model") or object:FindFirstChild("Handle") end
    if not adornee or not (adornee:IsA("Model") or adornee:IsA("BasePart")) then return end
    monitorHighlights[key] = monitorHighlights[key] or {}
    if monitorHighlights[key][object] then return end
    local h = Instance.new("Highlight")
    h.Name = "BloxFTales_" .. key
    h.Adornee = adornee
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor = color or COLORS.purple
    h.OutlineColor = COLORS.white
    h.FillTransparency = 0.78
    h.OutlineTransparency = 0.1
    h.Parent = Screen
    monitorHighlights[key][object] = h
end

local function stopMonitor(key)
    monitorJobs[key] = nil
    clearMonitorHighlights(key)
    monitorSnapshots[key] = nil
end

local function startMonitor(key, terms, color, interval, humanoidOnly)
    stopMonitor(key)
    local token = {}
    monitorJobs[key], monitorSnapshots[key], monitorHighlights[key] = token, {}, {}
    logSession("Monitor iniciado: " .. key)
    task.spawn(function()
        while Screen.Parent and monitorJobs[key] == token do
            local current = {}
            local items = scanReplicatedObjects(terms, 150, true, humanoidOnly)
            local added = 0
            for _, object in ipairs(items) do
                current[object] = true
                if not monitorSnapshots[key][object] then
                    added += 1
                    highlightMonitoredObject(key, object, color)
                end
            end
            for object in pairs(monitorSnapshots[key]) do
                if not current[object] then
                    local h = monitorHighlights[key] and monitorHighlights[key][object]
                    if h then pcall(function() h:Destroy() end) end
                    if monitorHighlights[key] then monitorHighlights[key][object] = nil end
                end
            end
            monitorSnapshots[key] = current
            if added > 0 then logSession(key .. ": " .. added .. " novo(s) objeto(s)") end
            task.wait(math.clamp(interval or 2, 0.5, 15))
        end
        if monitorJobs[key] == token then stopMonitor(key) end
    end)
end

local function stopAllMonitors()
    local keys = {}
    for key in pairs(monitorJobs) do keys[#keys + 1] = key end
    for _, key in ipairs(keys) do stopMonitor(key) end
end

local function localInventory()
    local names, seen = {}, {}
    for _, container in ipairs({LocalPlayer:FindFirstChildOfClass("Backpack"), getCharacter()}) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and not seen[item.Name] then seen[item.Name] = true names[#names + 1] = item.Name end
            end
        end
    end
    table.sort(names)
    return names
end

local function localStatsText()
    local lines, stats = {}, LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        for _, value in ipairs(stats:GetChildren()) do
            if value:IsA("ValueBase") then lines[#lines + 1] = value.Name .. ": " .. tostring(value.Value) end
        end
    end
    for _, key in ipairs({"Level", "Beli", "Money", "Fragments", "Race", "Awakening"}) do
        local value = LocalPlayer:GetAttribute(key)
        if value ~= nil then lines[#lines + 1] = key .. ": " .. tostring(value) end
    end
    if #lines == 0 then lines[1] = "Nenhum leaderstats ou atributo conhecido foi replicado." end
    return table.concat(lines, "\n")
end

nearestNpcInfo = function()
    local root = getRoot(getCharacter())
    if not root then return nil, math.huge end
    local nearest, distance = nil, math.huge
    for _, model in ipairs(scanReplicatedObjects({}, 500, false, true)) do
        if model ~= getCharacter() and not getPlayerFromModel(model) then
            local hum, pos = model:FindFirstChildOfClass("Humanoid"), objectPosition(model)
            if hum and hum.Health > 0 and pos then
                local d = (pos - root.Position).Magnitude
                if d < distance then nearest, distance = model, d end
            end
        end
    end
    return nearest, distance
end

nearestBossInfo = function()
    local root = getRoot(getCharacter())
    if not root then return nil, math.huge end
    local terms = {"boss", "leviathan", "leviata", "raid", "chefe"}
    local nearest, distance = nil, math.huge
    for _, model in ipairs(scanReplicatedObjects(terms, 500, false, true)) do
        if model:IsA("Model") and model ~= getCharacter() and not getPlayerFromModel(model) then
            local hum, pos = model:FindFirstChildOfClass("Humanoid"), objectPosition(model)
            if hum and hum.Health > 0 and pos then
                local d = (pos - root.Position).Magnitude
                if d < distance then nearest, distance = model, d end
            end
        end
    end
    return nearest, distance
end

local function listObjectPaths(items, cap)
    local rows, root = {}, getRoot(getCharacter())
    for i, object in ipairs(items) do
        if i > (cap or 35) then break end
        local suffix, pos = "", objectPosition(object)
        if root and pos then suffix = " | " .. math.floor((pos - root.Position).Magnitude) .. " studs" end
        rows[#rows + 1] = object:GetFullName() .. suffix
    end
    return #rows > 0 and table.concat(rows, "\n") or "Nenhum objeto correspondente encontrado."
end

--========================================================
-- AUTOMACOES DE INTERACAO DO MAPA (CLIENTE)
-- Usa apenas movimento normal e ProximityPrompt existente.
-- O servidor continua validando coleta, missao, evento e recompensa.
--========================================================
local worldAutomationJobs = {}
local worldAutomationStats = {}

local function normalizedSearchText(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s_%-]", "")
    return value
end

local function getSearchableObjectText(object)
    local parts, current, depth = {}, object, 0
    while current and current ~= Workspace and depth < 5 do
        parts[#parts + 1] = normalizedSearchText(current.Name)
        current = current.Parent
        depth += 1
    end
    return table.concat(parts, " ")
end

local function getPromptForObject(object)
    if not object then return nil end
    if object:IsA("ProximityPrompt") then return object end
    local ok, prompt = pcall(function()
        return object:FindFirstChildWhichIsA("ProximityPrompt", true)
    end)
    if ok then return prompt end
    return nil
end

local function getAutomationPosition(object)
    if not object or not object.Parent then return nil end
    if object:IsA("BasePart") then return object.Position end
    if object:IsA("Model") then
        local part = object.PrimaryPart
            or object:FindFirstChild("HumanoidRootPart")
            or object:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end
    if object:IsA("Tool") then
        local handle = object:FindFirstChild("Handle")
        return handle and handle.Position or nil
    end
    return nil
end

local function findWorldAutomationTarget(terms, requirePrompt, exactFruit)
    local root = getRoot(getCharacter())
    if not root then return nil end
    local best, bestDistance, bestPrompt = nil, math.huge, nil
    local needles = {}
    for _, term in ipairs(terms or {}) do
        local clean = normalizedSearchText(term)
        if clean ~= "" then needles[#needles + 1] = clean end
    end
    local descendants = Workspace:GetDescendants()
    local inspected = 0
    for _, object in ipairs(descendants) do
        inspected += 1
        if inspected > 18000 then break end
        if object:IsA("Model") or object:IsA("BasePart") or object:IsA("Tool") then
            local textName = getSearchableObjectText(object)
            local matches = #needles == 0
            for _, needle in ipairs(needles) do
                if string.find(textName, needle, 1, true) then
                    matches = true
                    break
                end
            end
            if matches and exactFruit and selectedFruitName then
                matches = string.find(textName, normalizedSearchText(selectedFruitName), 1, true) ~= nil
            end
            local ancestorModel = object:IsA("Model") and object or object:FindFirstAncestorOfClass("Model")
            local belongsToPlayer = ancestorModel ~= nil and getPlayerFromModel(ancestorModel) ~= nil
            local belongsToLocalCharacter = ancestorModel ~= nil and ancestorModel == getCharacter()
            if matches and not belongsToPlayer and not belongsToLocalCharacter then
                local prompt = getPromptForObject(object)
                local canCollectTool = object:IsA("Tool") and object.Parent == Workspace
                if (not requirePrompt or prompt or canCollectTool) then
                    local position = getAutomationPosition(object)
                    if position then
                        local distance = (position - root.Position).Magnitude
                        if distance < bestDistance then
                            best, bestDistance, bestPrompt = object, distance, prompt
                        end
                    end
                end
            end
        end
    end
    return best, bestDistance, bestPrompt
end

local function approachWorldObject(object, prompt)
    local character = getCharacter()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = getRoot(character)
    local position = getAutomationPosition(object)
    if not humanoid or not root or not position then return false end
    local activationDistance = prompt and math.max(4, prompt.MaxActivationDistance - 1) or 4
    if (root.Position - position).Magnitude > activationDistance then
        humanoid:MoveTo(position)
        local deadline = os.clock() + 8
        repeat
            task.wait(0.15)
            character = getCharacter()
            humanoid = character and character:FindFirstChildOfClass("Humanoid")
            root = getRoot(character)
            position = getAutomationPosition(object)
            if not root or not humanoid or not position or not object.Parent then
                return false
            end
        until (root.Position - position).Magnitude <= activationDistance or os.clock() >= deadline
    end
    if prompt and prompt.Parent and prompt.Enabled then
        local currentRoot = getRoot(getCharacter())
        local promptPart = prompt.Parent:IsA("BasePart") and prompt.Parent
            or prompt.Parent:FindFirstAncestorWhichIsA("BasePart")
        if currentRoot and promptPart
            and (currentRoot.Position - promptPart.Position).Magnitude <= prompt.MaxActivationDistance + 1 then
            local ok = pcall(function()
                prompt:InputHoldBegin()
                task.wait(math.clamp(prompt.HoldDuration, 0, 4) + 0.12)
                prompt:InputHoldEnd()
            end)
            return ok
        end
    end
    return object:IsA("Tool") and object.Parent == Workspace
end

local function stopWorldAutomation(key)
    worldAutomationJobs[key] = nil
end

local function startWorldAutomation(key, terms, options)
    options = options or {}
    stopWorldAutomation(key)
    local token = {}
    worldAutomationJobs[key] = token
    worldAutomationStats[key] = {attempts = 0, lastTarget = "nenhum", lastResult = "iniciando"}
    logSession("Automacao de interacao iniciada: " .. key)
    task.spawn(function()
        while Screen.Parent and worldAutomationJobs[key] == token do
            local target, distance, prompt = findWorldAutomationTarget(
                terms,
                options.requirePrompt == true,
                options.exactFruit == true
            )
            if target then
                local stats = worldAutomationStats[key]
                stats.lastTarget = target:GetFullName()
                stats.attempts += 1
                stats.lastResult = "aproximando"
                setStatus(options.statusPrefix or "Interagindo")
                local approached = approachWorldObject(target, prompt)
                if approached then
                    stats.lastResult = prompt and "interacao solicitada ao prompt" or "aproximacao de ferramenta"
                    if prompt then
                        logSession(key .. ": prompt acionado em " .. target.Name)
                    end
                else
                    stats.lastResult = "alvo inacessivel ou sem prompt"
                end
                task.wait(options.interval or 1.1)
            else
                worldAutomationStats[key].lastTarget = "nenhum objeto correspondente"
                worldAutomationStats[key].lastResult = options.requirePrompt
                    and "aguardando objeto com ProximityPrompt" or "aguardando objeto"
                task.wait(options.scanInterval or 1.5)
            end
        end
    end)
end

local function stopAllWorldAutomations()
    for key in pairs(worldAutomationJobs) do
        stopWorldAutomation(key)
    end
end

local function addAutomationStatus(key, title)
    makeButton("VER STATUS — " .. title, function()
        local stats = worldAutomationStats[key]
        if not stats then
            setStatus(title .. ": automacao ainda nao foi iniciada")
            return
        end
        setStatus(title .. ": " .. stats.lastResult .. " | alvo: " .. stats.lastTarget)
    end)
end

local function showCategory(category)
    activeContainer = Content
    clearContent()
    Content.CanvasPosition = Vector2.new(0, 0)

    if category == "Início" then
        beginSection("Painel e status")
        makeLabel("BLOX F' - TALES 5.3", 36)
        makeLabel("Interface organizada por seções. Toque na seta para abrir ou recolher os controles.", 52)
        setStatus("Pronto.")

        local coords = makeLabel("Coordenadas: aguardando personagem...", 28)

        task.spawn(function()
            while Screen.Parent and coords.Parent do
                local root = getRoot(getCharacter())
                coords.Text = root
                    and ("Coordenadas: " .. math.floor(root.Position.X) .. ", " .. math.floor(root.Position.Y) .. ", " .. math.floor(root.Position.Z))
                    or "Coordenadas: personagem indisponível"
                task.wait(0.25)
            end
        end)

        endSection()

        beginSection("Informações")
        makeLabel("Farm de NPCs e chefes atua somente em NPCs. Coleta e interações usam movimento normal e prompts existentes; o servidor valida inventário, missões, eventos, evolução e recompensas.", 76)
        endSection()

    elseif category == "Jogador" then
        beginSection("Movimentação")

        makeSpeedControl()

        makeToggle("Pulo infinito", function(on)
            infiniteJump = on
            setStatus(on and "Pulo infinito ligado" or "Pulo infinito desligado")
        end)

        makeToggle("Fly / Voar", function(on)
            flyEnabled = on
            if not on then
                followFlyActive = false
                if not antiAttackEnabled then
                    clearManagedVelocity()
                    local character = getCharacter()
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
            end
            setStatus(on and "Fly ligado" or "Fly desligado")
        end)

        makeSlider("Velocidade do Fly", 50, 1400, math.min(flySpeed, 1400), function(value)
            flySpeed = value
            setStatus("Velocidade do Fly: " .. flySpeed)
        end)

        makeLabel("Fly omnidirecional: limite até 1400 em todas as direções, com aceleração suavizada para reduzir trancos. O servidor ainda pode limitar a velocidade real.", 52)
        makeLabel("O Fly acompanha a direção da câmera. Quando o ataque automático está perseguindo um alvo selecionado, o Fly também acompanha esse alvo.", 62)
        endSection()

        beginSection("Colisão")
        makeToggle("Atravessar paredes (local)", function(on)
            noclip = on
            setStatus(on and "Noclip local ligado" or "Noclip local desligado")
        end)

        makeLabel("O noclip altera colisões no cliente; o servidor pode corrigir sua posição.", 48)
        endSection()

    elseif category == "Teletransporte" then
        local islandWorlds = {
            {world="Mundo 1", islands={
                {"Ilha Inicial dos Piratas (Pirate Starter Island)", {"PirateStarter", "Pirate Starter Island", "StarterIsland", "Starter Island"}},
                {"Ilha Inicial da Marinha (Marine Starter Island)", {"MarineStarter", "Marine Starter Island"}},
                {"Selva (Jungle)", {"Jungle", "Jungle Island"}},
                {"Vila dos Piratas (Pirate Village)", {"PirateVillage", "Pirate Village"}},
                {"Deserto (Desert)", {"Desert", "Desert Island"}},
                {"Vila Congelada (Frozen Village)", {"FrozenVillage", "Frozen Village"}},
                {"Fortaleza da Marinha (Marine Fortress)", {"MarineFortress", "Marine Fortress"}},
                {"Ilhas do Céu (Skylands)", {"Skylands", "Sky Island"}},
                {"Céu Superior (Upper Skylands)", {"UpperSkylands", "Upper Skylands"}},
                {"Céu Inferior (Lower Skylands)", {"LowerSkylands", "Lower Skylands"}},
                {"Cidade Central (Middle Town)", {"MiddleTown", "Middle Town"}},
                {"Prisão (Prison)", {"Prison"}},
                {"Coliseu (Colosseum)", {"Colosseum", "Colosseum Island"}},
                {"Vila Magma (Magma Village)", {"MagmaVillage", "Magma Village"}},
                {"Cidade Subaquática (Underwater City)", {"UnderwaterCity", "Underwater City"}},
                {"Cidade da Fonte (Fountain City)", {"FountainCity", "Fountain City"}}
            }},
            {world="Mundo 2", islands={
                {"Reino das Rosas (Kingdom of Rose)", {"KingdomofRose", "Kingdom of Rose"}},
                {"Café (Cafe)", {"Cafe"}},
                {"Zona Verde (Green Zone)", {"GreenZone", "Green Zone"}},
                {"Cemitério (Graveyard)", {"Graveyard"}},
                {"Montanha Nevada (Snow Mountain)", {"SnowMountain", "Snow Mountain"}},
                {"Quente e Frio (Hot and Cold)", {"HotandCold", "Hot and Cold"}},
                {"Navio Amaldiçoado (Cursed Ship)", {"CursedShip", "Cursed Ship"}},
                {"Castelo de Gelo (Ice Castle)", {"IceCastle", "Ice Castle"}},
                {"Ilha Esquecida (Forgotten Island)", {"ForgottenIsland", "Forgotten Island"}},
                {"Arena Sombria (Dark Arena)", {"DarkArena", "Dark Arena"}}
            }},
            {world="Mundo 3", islands={
                {"Cidade Portuária (Port Town)", {"PortTown", "Port Town"}},
                {"Ilha da Hidra (Hydra Island)", {"HydraIsland", "Hydra Island"}},
                {"Grande Árvore (Great Tree)", {"GreatTree", "Great Tree"}},
                {"Tartaruga Flutuante (Floating Turtle)", {"FloatingTurtle", "Floating Turtle"}},
                {"Castelo no Mar (Castle on the Sea)", {"CastleontheSea", "Castle on the Sea"}},
                {"Castelo Assombrado (Haunted Castle)", {"HauntedCastle", "Haunted Castle"}},
                {"Mar de Doces (Sea of Treats)", {"SeaofTreats", "Sea of Treats"}},
                {"Terra do Chocolate (Chocolate Land)", {"ChocolateLand", "Chocolate Land"}},
                {"Terra do Biscoito (Candy Cane Land)", {"CandyCaneLand", "Candy Cane Land"}},
                {"Terra do Sorvete (Ice Cream Land)", {"IceCreamLand", "Ice Cream Land"}},
                {"Terra do Amendoim (Peanut Land)", {"PeanutLand", "Peanut Land"}},
                {"Terra do Bolo (Cake Land)", {"CakeLand", "Cake Land"}},
                {"Posto Tiki (Tiki Outpost)", {"TikiOutpost", "Tiki Outpost"}}
            }}
        }

        makeLabel("Escolha o mundo, marque uma ilha e depois confirme no botão separado.", 42)
        local selectedLabel = makeLabel("Destino selecionado: nenhum", 28)
        local optionButtons = {}

        for _, worldData in ipairs(islandWorlds) do
            beginSection(worldData.world, false)

            for _, islandData in ipairs(worldData.islands) do
                local islandName, aliases = islandData[1], islandData[2]

                local button = makeOption(islandName, selectedIsland == islandName, function()
                    selectedIsland = selectedIsland == islandName and nil or islandName
                    selectedLabel.Text = "Destino selecionado: " .. (selectedIsland or "nenhum")

                    for name, option in pairs(optionButtons) do
                        if option and option.Parent then
                            local chosen = name == selectedIsland
                            option.BackgroundColor3 = chosen and COLORS.green or COLORS.row
                            option.Text = (chosen and "✓   " or "○   ") .. name
                        end
                    end
                end)

                optionButtons[islandName] = button
            end

            endSection()
        end

        beginSection("Confirmar destino", false)

        makeButton("CONFIRMAR TELETRANSPORTE PARA A ILHA", function()
            if not selectedIsland then
                setStatus("Selecione uma ilha antes de confirmar.")
                return
            end

            local aliases

            for _, worldData in ipairs(islandWorlds) do
                for _, islandData in ipairs(worldData.islands) do
                    if islandData[1] == selectedIsland then
                        aliases = islandData[2]
                        break
                    end
                end
                if aliases then break end
            end

            local destination = aliases and findNamedWorldObject(aliases)

            if destination then
                local ok = teleportLocal(destination * CFrame.new(0, 5, 0))
                setStatus(ok and ("Tentando ir para " .. selectedIsland) or "Não foi possível mover o personagem.")
            else
                setStatus("Não encontrei " .. selectedIsland .. " no mapa carregado. O nome interno pode ser diferente.")
            end
        end, COLORS.green)

        endSection()

        beginSection("Teletransporte por coordenadas", false)

        local coordinateBoxes = {}

        for _, axis in ipairs({"X", "Y", "Z"}) do
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -4, 0, 36)
            box.BackgroundColor3 = COLORS.row
            box.TextColor3 = COLORS.white
            box.PlaceholderText = "Coordenada " .. axis
            box.Text = ""
            box.ClearTextOnFocus = false
            box.Font = Enum.Font.Gotham
            box.TextSize = 13
            box.Parent = activeContainer
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
            coordinateBoxes[axis] = box
        end

        makeButton("CONFIRMAR COORDENADAS", function()
            local x = tonumber(coordinateBoxes.X.Text)
            local y = tonumber(coordinateBoxes.Y.Text)
            local z = tonumber(coordinateBoxes.Z.Text)

            if not x or not y or not z then
                setStatus("Informe valores numéricos para X, Y e Z.")
                return
            end

            local ok = teleportLocal(Vector3.new(
                math.clamp(x, -100000, 100000),
                math.clamp(y, -100000, 100000),
                math.clamp(z, -100000, 100000)
            ))

            setStatus(ok and "Movimento para as coordenadas solicitado." or "Não foi possível teletransportar.")
        end, COLORS.purple)

        endSection()

        beginSection("Teletransporte para jogador", false)

        makeLabel("Ajuste a velocidade local de aproximação até o jogador.", 36)

        makeSlider("Speed", 16, 500, playerTeleportSpeed, function(value)
            playerTeleportSpeed = value
            setStatus("Speed do teletransporte player: " .. value)
        end)

        makePlayerSelection()
        endSection()

    elseif category == "Visualização" then
        beginSection("Jogadores", false)

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

        endSection()

        beginSection("Chefes / Boss ESP", false)

        makeToggle("Destacar bosses", function(on)
            bossESP = on
            refreshBossESP(on)
            setStatus(on and "Boss ESP ligado" or "Boss ESP desligado")
        end)

        endSection()

        beginSection("Localizadores", false)

        makeToggle("Localizador de frutas", function(on)
            fruitFinder = on
            refreshObjectHighlights("fruit", on)
        end)

        makeToggle("Localizador de baús", function(on)
            chestFinder = on
            refreshObjectHighlights("chest", on)
        end)

        makeLabel("Os localizadores destacam objetos que a experiência já replicou ao cliente. Coleta e recompensas dependem das regras oficiais do servidor.", 54)
        endSection()

    elseif category == "Anti-Ataque" then
        beginSection("Protecao automatica")
        makeToggle("ANTI-ATAQUE", function(on)
            antiAttackEnabled = on
            if not on then
                antiAttackDodgeUntil = 0
                antiAttackDodgeDirection = Vector3.zero
                antiAttackThreatMemory = {}
            end
            setStatus(on and "Anti-Ataque defensivo ativo" or "Anti-Ataque desligado")
        end)
        makeLabel("Monitora sinais de ameacas e tenta desviar defensivamente. Não seleciona jogadores para ataque.", 60)
        makeLabel("Durante a esquiva, controla temporariamente o movimento e pode usar velocidade elevada sem ligar Fly ou Pulo infinito na interface.", 66)
        makeLabel("A deteccao depende dos projeteis, movimentos e sinais replicados pelo jogo. Golpes calculados apenas no servidor ou sem sinais antecipados podem nao ser detectados.", 72)
        endSection()

    elseif category == "Combate" then
        beginSection("Mira e seleção de alvos", false)

        makeToggle("Aim Assist", function(on)
            aimAssistEnabled = on
            setStatus(on and "Aim Assist de NPCs ativado" or "Aim Assist desativado")
        end)

        makeToggle("Mostrar FOV", function(on)
            aimFovEnabled = on
            FOVCircle.Visible = on
            setStatus(on and "FOV ativado" or "FOV desativado")
        end)

        makeSlider("Raio do FOV", 30, 500, aimFovRadius, function(value)
            aimFovRadius = value
            FOVCircle.Size = UDim2.fromOffset(value * 2, value * 2)
            setStatus("Raio do FOV: " .. aimFovRadius)
        end)

        local attackButton, attackList, attackStatus

        local typeButton, targetTypeDropdown

        typeButton = makeButton("▼  Tipo de alvo: " .. selectedAimTarget, function()
            targetTypeDropdownOpen = not targetTypeDropdownOpen
            targetTypeDropdown.Visible = targetTypeDropdownOpen
            typeButton.Text = (targetTypeDropdownOpen and "▼  " or "▶  ")
                .. "Tipo de alvo: " .. selectedAimTarget
        end)

        targetTypeDropdown = Instance.new("Frame")
        targetTypeDropdown.Size = UDim2.new(1, -4, 0, 114)
        targetTypeDropdown.BackgroundColor3 = COLORS.panel
        targetTypeDropdown.Visible = false
        targetTypeDropdown.Parent = activeContainer

        local typeLayout = Instance.new("UIListLayout")
        typeLayout.Padding = UDim.new(0, 4)
        typeLayout.Parent = targetTypeDropdown

        for _, targetType in ipairs({"NPCs"}) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, 0, 0, 34)
            option.BackgroundColor3 = selectedAimTarget == targetType and COLORS.green or COLORS.row
            option.Text = targetType
            option.TextColor3 = COLORS.white
            option.Font = Enum.Font.Gotham
            option.TextSize = 12
            option.Parent = targetTypeDropdown
            Instance.new("UICorner", option).CornerRadius = UDim.new(0, 6)

            option.Activated:Connect(function()
                selectedAimTarget = targetType
                typeButton.Text = "▶  Tipo de alvo: " .. targetType
                targetTypeDropdownOpen = false
                targetTypeDropdown.Visible = false

                for _, sibling in ipairs(targetTypeDropdown:GetChildren()) do
                    if sibling:IsA("TextButton") then
                        sibling.BackgroundColor3 =
                            sibling.Text == targetType and COLORS.green or COLORS.row
                    end
                end

                if attackList and attackList.Parent then
                    refreshAttackTargetList(attackList, attackStatus)
                end

                setStatus("Mira configurada para NPCs")
            end)
        end

        endSection()

        beginSection("Ataque, habilidades e Haki", false)

        makeSlider("Alcance do ataque básico (studs)", 8, 80, combatAttackRange, function(value)
            combatAttackRange = value
            setStatus("Alcance do ataque: " .. value .. " studs")
        end)
        makeSlider("Alcance para tentar habilidades (studs)", 20, 300, combatSkillRange, function(value)
            combatSkillRange = value
            setStatus("Alcance das habilidades: " .. value .. " studs")
        end)
        makeSlider("Distância de aproximação do NPC (studs)", 4, 24, combatFollowDistance, function(value)
            combatFollowDistance = value
            setStatus("Aproximação configurada: " .. value .. " studs")
        end)
        makeSlider("Distância para parar junto ao NPC (studs)", 4, 30, combatStopDistance, function(value)
            combatStopDistance = value
            setStatus("Distância de parada: " .. value .. " studs")
        end)

        attackButton = makeButton("▼  Selecionar alvos para ataque", function()
            attackDropdownOpen = not attackDropdownOpen
            attackList.Visible = attackDropdownOpen
            attackButton.Text = (attackDropdownOpen and "▼  " or "▶  ")
                .. "Selecionar alvos para ataque"
        end)

        attackStatus = makeLabel("Alvos selecionados: 0", 25)

        attackList = Instance.new("ScrollingFrame")
        attackList.Name = "AttackTargetList"
        attackList.Size = UDim2.new(1, -4, 0, 170)
        attackList.BackgroundColor3 = COLORS.panel
        attackList.BorderSizePixel = 0
        attackList.ScrollBarThickness = 4
        attackList.ScrollBarImageColor3 = COLORS.purple
        attackList.CanvasSize = UDim2.new(0, 0, 0, 0)
        attackList.Visible = false
        attackList.Parent = activeContainer
        Instance.new("UICorner", attackList).CornerRadius = UDim.new(0, 7)

        local attackListLayout = Instance.new("UIListLayout")
        attackListLayout.Padding = UDim.new(0, 4)
        attackListLayout.Parent = attackList

        attackListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            attackList.CanvasSize = UDim2.new(0, 0, 0, attackListLayout.AbsoluteContentSize.Y + 8)
        end)

        makeButton("ATUALIZAR LISTA DE ALVOS", function()
            refreshAttackTargetList(attackList, attackStatus)

            local count = 0
            for model in pairs(selectedAttackTargets) do
                if model and model.Parent and isValidAimType(model) then
                    count += 1
                end
            end

            attackStatus.Text = "Alvos selecionados: " .. count
        end, COLORS.purple)

        refreshAttackTargetList(attackList, attackStatus)

        makeLabel("Selecione a fruta que você está equipado.", 30)

        local fruitSelectionLabel = makeLabel(
            "Fruta confirmada: " .. (selectedFruitName or "nenhuma"),
            28
        )

        local fruitDropdownButton
        local fruitList

        fruitDropdownButton = makeButton("▼  Selecione a fruta que você está equipado", function()
            fruitDropdownOpen = not fruitDropdownOpen
            fruitList.Visible = fruitDropdownOpen
            fruitDropdownButton.Text = (fruitDropdownOpen and "▼  " or "▶  ")
                .. "Selecione a fruta que você está equipado"
        end)

        fruitList = Instance.new("ScrollingFrame")
        fruitList.Name = "FruitSelectionList"
        fruitList.Size = UDim2.new(1, -4, 0, 150)
        fruitList.BackgroundColor3 = COLORS.panel
        fruitList.BorderSizePixel = 0
        fruitList.ScrollBarThickness = 4
        fruitList.ScrollBarImageColor3 = COLORS.purple
        fruitList.CanvasSize = UDim2.new(0, 0, 0, 0)
        fruitList.Visible = false
        fruitList.Parent = activeContainer
        Instance.new("UICorner", fruitList).CornerRadius = UDim.new(0, 7)

        local fruitListLayout = Instance.new("UIListLayout")
        fruitListLayout.Padding = UDim.new(0, 4)
        fruitListLayout.Parent = fruitList

        fruitListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            fruitList.CanvasSize = UDim2.new(
                0,
                0,
                0,
                fruitListLayout.AbsoluteContentSize.Y + 8
            )
        end)

        local fruitOptionButtons = {}

        local function updateFruitOptions()
            for fruitName, option in pairs(fruitOptionButtons) do
                if option and option.Parent then
                    local chosen = pendingFruitName == fruitName
                    option.BackgroundColor3 = chosen and COLORS.green or COLORS.row
                    option.Text = (chosen and "✓   " or "○   ") .. fruitName
                end
            end
        end

        for _, fruitName in ipairs(fruitCatalog) do
            local option = Instance.new("TextButton")
            option.Name = "FruitOption"
            option.Size = UDim2.new(1, -4, 0, 32)
            option.BackgroundColor3 = pendingFruitName == fruitName and COLORS.green or COLORS.row
            option.Text = (pendingFruitName == fruitName and "✓   " or "○   ") .. fruitName
            option.TextColor3 = COLORS.white
            option.TextSize = 12
            option.Font = Enum.Font.Gotham
            option.TextXAlignment = Enum.TextXAlignment.Left
            option.Parent = fruitList
            Instance.new("UICorner", option).CornerRadius = UDim.new(0, 6)

            fruitOptionButtons[fruitName] = option

            option.Activated:Connect(function()
                pendingFruitName = fruitName
                updateFruitOptions()
                setStatus("Fruta selecionada: " .. fruitName .. ". Confirme para salvar.")
            end)
        end

        makeButton("CONFIRMAR FRUTA", function()
            if not pendingFruitName then
                setStatus("Escolha uma fruta antes de confirmar.")
                return
            end

            selectedFruitName = pendingFruitName
            fruitSelectionLabel.Text = "Fruta confirmada: " .. selectedFruitName
            setStatus("Fruta configurada: " .. selectedFruitName)
        end, COLORS.green)

        makeToggle("Ataque automático", function(on)
            autoAttackEnabled = on
            autoSkillsEnabled = on
            if on then
                startAttackLoop()
            end
            setStatus(on and "Ataque + habilidades + esquiva ligados" or "Ataque automático desligado")
        end)

        makeToggle("Haki automático", function(on)
            autoHakiEnabled = on
            if on and not attackLoopRunning then
                startAttackLoop()
            end
            setStatus(on and "Haki automático ligado" or "Haki automático desligado")
        end)

        makeToggle("Uso automático de habilidades", function(on)
            autoSkillsEnabled = on
            if on and not attackLoopRunning then
                startAttackLoop()
            end
            setStatus(on and "Habilidades automáticas ligadas" or "Habilidades automáticas desligadas")
        end)

        makeButton("LIMPAR ALVOS SELECIONADOS", function()
            table.clear(selectedAttackTargets)
            refreshAttackTargetList(attackList, attackStatus)
            attackStatus.Text = "Alvos selecionados: 0"
            setStatus("Seleção de alvos limpa.")
        end, COLORS.red)

        endSection()

    elseif category == "Frutas" then
        beginSection("Fruta desejada", false)
        local fruitInput = makeInput("Nome da fruta para procurar", "Ex.: Dragon, Kitsune, Buddha", selectedFruitName or "", nil)
        local fruitStatus = makeLabel("Fruta configurada: " .. (selectedFruitName or "nenhuma"), 28)
        makeButton("CONFIRMAR FRUTA DESEJADA", function()
            local requested = string.gsub(tostring(fruitInput.Text or ""), "^%s*(.-)%s*$", "%1")
            if requested == "" then
                setStatus("Digite o nome de uma fruta antes de confirmar.")
                return
            end
            selectedFruitName = requested
            pendingFruitName = requested
            fruitStatus.Text = "Fruta configurada: " .. requested
            setStatus("Busca configurada para: " .. requested)
        end, COLORS.green)
        makeLabel("A busca compara o nome da fruta com os objetos replicados no mapa. A coleta só ocorre se houver Tool coletável ou ProximityPrompt válido.", 58)
        endSection()

        beginSection("Localização e coleta", false)
        makeToggle("Detector visual de frutas", function(on)
            fruitFinder = on
            refreshObjectHighlights("fruit", on)
            setStatus(on and "Detector visual de frutas ligado" or "Detector visual de frutas desligado")
        end)
        makeToggle("Auto coletar fruta desejada", function(on)
            autoFruitEnabled = on
            if on then
                if not selectedFruitName or selectedFruitName == "" then
                    autoFruitEnabled = false
                    setStatus("Configure a fruta desejada antes de ativar a coleta.")
                    return
                end
                startWorldAutomation("fruit_collect", {"fruit", "fruta", "devilfruit", "bloxfruit", selectedFruitName}, {
                    exactFruit = true, requirePrompt = false, interval = 1.2,
                    statusPrefix = "Procurando fruta " .. selectedFruitName
                })
            else
                stopWorldAutomation("fruit_collect")
                setStatus("Auto coleta de frutas desligada")
            end
        end)
        addAutomationStatus("fruit_collect", "frutas")
        makeLabel("Se a fruta aparecer como Tool no Workspace, o personagem se aproxima para recolhê-la. Se usar prompt, o prompt é acionado normalmente; sem esses mecanismos, a coleta fica sob controle do servidor.", 74)
        endSection()

    elseif category == "Coleta e evolução" then
        beginSection("Coleta automática", false)

        makeToggle("Auto Farm de NPCs", function(on)
            autoFarmEnabled = on
            if on then
                autoBossFarmEnabled = false
                startAttackLoop()
                local npc, distance = nearestNpcInfo()
                setStatus(npc and ("Auto Farm ativo; alvo NPC: " .. npc.Name .. " (" .. math.floor(distance) .. " studs)") or "Auto Farm ativo; aguardando NPC")
            else
                setStatus("Auto Farm de NPCs desligado")
            end
        end)
        makeLabel("Persegue NPCs com Humanoid e usa a ferramenta selecionada dentro do alcance configurado. Jogadores reais ficam fora da seleção e do ataque automático.", 54)

        makeToggle("Auto Chest — aproximar e abrir", function(on)
            autoChestEnabled = on
            if on then
                startWorldAutomation("chests", {"chest", "bau", "treasure", "coffer"}, {
                    requirePrompt = true, interval = 1.4, statusPrefix = "Procurando baus"
                })
            else
                stopWorldAutomation("chests")
                setStatus("Auto Chest desligado")
            end
        end)
        addAutomationStatus("chests", "baus")

        makeToggle("Auto Fruit — coleta configurada", function(on)
            autoFruitEnabled = on
            if on then
                if not selectedFruitName or selectedFruitName == "" then
                    autoFruitEnabled = false
                    setStatus("Configure a fruta na aba Frutas antes de ativar.")
                    return
                end
                startWorldAutomation("farm_fruit", {"fruit", "fruta", "devilfruit", "bloxfruit", selectedFruitName}, {
                    exactFruit = true, requirePrompt = false, interval = 1.2,
                    statusPrefix = "Procurando " .. selectedFruitName
                })
            else
                stopWorldAutomation("farm_fruit")
                setStatus("Auto Fruit desligado")
            end
        end)

        makeToggle("Auto Mission — interagir com indicadores", function(on)
            autoMissionEnabled = on
            if on then
                startWorldAutomation("missions", {"quest", "mission", "trial", "objective", "questgiver"}, {
                    requirePrompt = true, interval = 1.5, statusPrefix = "Procurando interacao de missao"
                })
            else
                stopWorldAutomation("missions")
                setStatus("Auto Mission desligado")
            end
        end)
        addAutomationStatus("missions", "missoes")

        endSection()

        beginSection("Evolução e recompensas", false)

        makeToggle("Auto Evolution — localizar interação", function(on)
            autoEvolutionEnabled = on
            if on then
                startWorldAutomation("evolution", {"evolution", "awakening", "evolve", "upgrade", "despertar"}, {
                    requirePrompt = true, interval = 2, statusPrefix = "Localizando evolucao"
                })
            else
                stopWorldAutomation("evolution")
                setStatus("Localizador de evolução desligado")
            end
        end)
        addAutomationStatus("evolution", "evolucao")
        makeLabel("O script pode aproximar e acionar um ProximityPrompt existente. O servidor decide se os requisitos foram cumpridos e se a evolução será aplicada.", 58)

        makeToggle("Auto Rewards — localizar resgate", function(on)
            autoRewardsEnabled = on
            if on then
                startWorldAutomation("rewards", {"reward", "prize", "claim", "daily", "recompensa", "premio"}, {
                    requirePrompt = true, interval = 2, statusPrefix = "Localizando resgate"
                })
            else
                stopWorldAutomation("rewards")
                setStatus("Localizador de recompensas desligado")
            end
        end)
        addAutomationStatus("rewards", "recompensas")
        makeLabel("O resgate só é concluído quando o servidor aceitar a interação e validar as condições da experiência.", 50)

        endSection()

    elseif category == "Espadas" then
        beginSection("Equipamento", false)
        makeToolSelector("Selecionar espada", {"sword", "katana", "blade", "sabre", "espada"})
        makeLabel("A seleção equipa a ferramenta local escolhida quando o combate contra NPCs estiver ativo.", 46)
        endSection()
        beginSection("Catálogo e rastreamento", false)
        addWorkspaceScanner("Espadas e lâminas", {"sword", "katana", "blade", "sabre", "espada"}, 35)
        endSection()

    elseif category == "Armas" then
        beginSection("Equipamento", false)
        makeToolSelector("Selecionar arma/ferramenta", {"weapon", "gun", "rifle", "pistol", "bow", "arma", "musket"})
        makeLabel("A seleção define qual ferramenta local será priorizada no combate contra NPCs.", 46)
        endSection()
        beginSection("Catálogo e rastreamento", false)
        addWorkspaceScanner("Armas e ferramentas", {"weapon", "gun", "rifle", "pistol", "bow", "arma", "musket"}, 35)
        endSection()

    elseif category == "Chefes" then
        beginSection("Farm de chefes NPC", false)
        makeToggle("Auto Farm de chefes", function(on)
            autoBossFarmEnabled = on
            if on then
                autoFarmEnabled = false
                startAttackLoop()
                local boss, distance = nearestBossInfo()
                setStatus(boss and ("Farm de chefe ativo: " .. boss.Name .. " (" .. math.floor(distance) .. " studs)") or "Farm ativo; aguardando chefe reconhecido")
            else
                setStatus("Farm de chefes desligado")
            end
        end)
        makeLabel("Procura NPCs cujo nome contenha Boss, Leviathan, Leviatã, Raid ou Chefe. A experiência precisa permitir que o cliente equipe e ative ferramentas.", 62)
        endSection()
        beginSection("Chefes e NPCs", false)
        addWorkspaceScanner("Modelos de chefes", {"boss", "raid", "chief", "chefe", "leviathan", "leviata"}, 40)
        makeButton("LISTAR MODELOS COM HUMANOID", function()
            local rows = {}
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") then
                    table.insert(rows, item:GetFullName())
                    if #rows >= 35 then break end
                end
            end
            setStatus(#rows .. " modelo(s) com Humanoid")
            makeLabel(#rows > 0 and table.concat(rows, "\n") or "Nenhum NPC encontrado.", math.clamp(#rows * 19, 40, 360))
        end)
        endSection()

    elseif category == "Eventos Marítimos" then
        beginSection("Interações de eventos marítimos", false)
        makeToggle("Auto interagir com eventos", function(on)
            if on then
                startWorldAutomation("sea_events", {"seaevent", "leviathan", "leviata", "sea beast", "ship", "barco", "event"}, {
                    requirePrompt = true, interval = 1.5, statusPrefix = "Procurando interacao de evento"
                })
            else
                stopWorldAutomation("sea_events")
                setStatus("Interação automática de eventos desligada")
            end
        end)
        addAutomationStatus("sea_events", "eventos maritimos")
        makeLabel("Aproxima e aciona prompts já existentes. O início, combate, conclusão e recompensa do evento continuam dependendo das regras oficiais do servidor.", 68)
        endSection()
        beginSection("Monitor de eventos", false)
        addWorkspaceScanner("Eventos e criaturas marítimas", {"sea", "leviathan", "leviata", "sea beast", "beast", "ship", "barco"}, 40)
        endSection()

    elseif category == "Factory" then
        beginSection("Factory — interação", false)
        makeToggle("Auto Factory — aproximar e interagir", function(on)
            if on then
                startWorldAutomation("factory", {"factory", "fabrica", "core", "factorydoor"}, {
                    requirePrompt = true, interval = 1.4, statusPrefix = "Procurando interacao da Factory"
                })
            else
                stopWorldAutomation("factory")
                setStatus("Automacao de interacao da Factory desligada")
            end
        end)
        addAutomationStatus("factory", "Factory")
        makeLabel("A automação procura objetos da Factory que tenham ProximityPrompt, aproxima o personagem e solicita a interação normal. Não inicia evento nem cria recompensas se o servidor não oferecer essa interação.", 78)
        endSection()
        beginSection("Objetos encontrados", false)
        addWorkspaceScanner("Objetos relacionados à Factory", {"factory", "fabrica", "core", "factory door"}, 35)
        endSection()

    elseif category == "Materiais" then
        beginSection("Coleta de materiais", false)
        makeToggle("Auto coletar materiais com prompt", function(on)
            if on then
                startWorldAutomation("materials", {"material", "fragment", "scrap", "ore", "essence", "scale", "mat"}, {
                    requirePrompt = true, interval = 1.2, statusPrefix = "Procurando material"
                })
            else
                stopWorldAutomation("materials")
                setStatus("Coleta automática de materiais desligada")
            end
        end)
        addAutomationStatus("materials", "materiais")
        makeLabel("Aproxima e aciona somente prompts já existentes em objetos com nomes relacionados a materiais. Quantidades e recompensas são confirmadas pelo inventário do servidor.", 68)
        endSection()
        beginSection("Catálogo e localização", false)
        addWorkspaceScanner("Materiais e drops", {"material", "fragment", "scrap", "ore", "essence", "scale", "mat"}, 45)
        endSection()

    elseif category == "Objetivos" then
        beginSection("Acompanhamento de objetivo", false)
        makeLabel("Digite uma palavra do nome do item, NPC ou local que você quer localizar no mapa.", 48)
        local queryBox = makeInput("Pesquisar objetivo", "Ex.: Dragon, Factory, Leviathan", "", nil)
        makeButton("LOCALIZAR OBJETIVO", function()
            local query = string.lower(queryBox.Text or "")
            if query == "" then
                setStatus("Digite um nome para pesquisar.")
                return
            end
            local matches = scanReplicatedObjects({query}, 80, true, false)
            objectiveSelection = matches[1]
            setStatus(#matches .. " correspondência(s) para: " .. query)
            makeLabel(listObjectPaths(matches, 35), math.clamp(math.min(#matches, 35) * 19, 42, 420))
            if objectiveSelection then
                clearMonitorHighlights("objective")
                highlightMonitoredObject("objective", objectiveSelection, COLORS.green)
            end
        end, COLORS.purple)
        makeButton("IR ATÉ O OBJETIVO LOCALIZADO", function()
            if not objectiveSelection or not objectiveSelection.Parent then
                setStatus("Localize um objetivo antes de solicitar o teletransporte.")
                return
            end
            local destination
            if objectiveSelection:IsA("BasePart") then
                destination = objectiveSelection.CFrame + Vector3.new(0, 5, 0)
            elseif objectiveSelection:IsA("Model") then
                local ok, pivot = pcall(function() return objectiveSelection:GetPivot() end)
                if ok then destination = pivot + Vector3.new(0, 5, 0) end
            end
            if destination then
                teleportLocal(destination)
            else
                setStatus("O objetivo localizado não possui posição utilizável.")
            end
        end, COLORS.green)
        endSection()

    elseif category == "Missões e Trials" then
        beginSection("Interação com missões e Trials", false)
        makeToggle("Auto interagir com NPCs de missão", function(on)
            if on then
                startWorldAutomation("quest_givers", {"quest", "mission", "missiongiver", "questgiver", "trial", "prova"}, {
                    requirePrompt = true, interval = 1.5, statusPrefix = "Procurando NPC ou prompt de missao"
                })
            else
                stopWorldAutomation("quest_givers")
                setStatus("Interação automática com missões desligada")
            end
        end)
        addAutomationStatus("quest_givers", "missoes e Trials")
        makeLabel("O personagem se aproxima de NPCs e objetos com ProximityPrompt. Aceitar, avançar ou concluir uma missão depende da resposta oficial do servidor.", 64)
        endSection()
        beginSection("Indicadores encontrados", false)
        addWorkspaceScanner("Indicadores de missão e Trial", {"quest", "mission", "trial", "missiongiver", "questgiver", "prova"}, 40)
        endSection()

    elseif category == "Administração" then
        beginSection("Ferramentas administrativas locais", false)
        makeLabel("UserId local: " .. tostring(LocalPlayer.UserId), 28)
        makeLabel("Esta aba não concede permissões. Comandos administrativos reais precisam validar UserId e permissões no servidor.", 62)
        makeButton("RECARREGAR PERSONAGEM", function()
            local ok = pcall(function() LocalPlayer:LoadCharacter() end)
            setStatus(ok and "Solicitação de respawn enviada." or "Respawn não disponível neste contexto.")
        end)
        makeButton("LER STATUS E ATRIBUTOS", function()
            local text = localStatsText()
            makeLabel(text, math.clamp(select(2, text:gsub("\n", "")) * 22, 42, 320))
        end, COLORS.purple)
        makeButton("LISTAR FERRAMENTAS DO JOGADOR", function()
            local items = localInventory()
            makeLabel(#items > 0 and table.concat(items, "\n") or "Nenhuma Tool no Backpack ou personagem.", math.clamp(#items * 22, 42, 320))
            setStatus("Ferramentas locais encontradas: " .. #items)
        end)
        endSection()

    elseif category == "Extras" then
        beginSection("Diagnóstico", false)
        makeButton("CONTAR MODELOS E PARTES", function()
            local models, parts, tools = 0, 0, 0
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("Model") then models += 1
                elseif item:IsA("BasePart") then parts += 1
                elseif item:IsA("Tool") then tools += 1 end
            end
            setStatus("Modelos: " .. models .. " | Partes: " .. parts .. " | Tools: " .. tools)
        end)
        makeButton("RECENTRALIZAR PAINEL", function()
            Main.Position = UDim2.new(0.5, -Main.AbsoluteSize.X / 2, 0.5, -Main.AbsoluteSize.Y / 2)
            setStatus("Painel recentralizado.")
        end)
        makeButton("LISTAR INVENTÁRIO LOCAL", function()
            local items = localInventory()
            makeLabel(#items > 0 and table.concat(items, "\n") or "Nenhuma Tool no Backpack ou personagem.", math.clamp(#items * 22, 42, 360))
        end, COLORS.purple)
        makeButton("MOSTRAR HISTÓRICO DA SESSÃO", function()
            makeLabel(#sessionEvents > 0 and table.concat(sessionEvents, "\n") or "Ainda não há eventos nesta sessão.", math.clamp(math.min(#sessionEvents, 30) * 20, 42, 600))
        end)
        makeButton("LIMPAR HISTÓRICO DA SESSÃO", function()
            table.clear(sessionEvents)
            logSession("Histórico reiniciado")
            setStatus("Histórico local reiniciado.")
        end, COLORS.red)
        makeButton("PARAR TODAS AS AUTOMACOES", function()
            stopAllMonitors()
            stopAllWorldAutomations()
            autoFarmEnabled, autoBossFarmEnabled, autoChestEnabled, autoFruitEnabled = false, false, false, false
            autoAttackEnabled, autoHakiEnabled, autoSkillsEnabled = false, false, false
            autoMissionEnabled, autoEvolutionEnabled, autoRewardsEnabled = false, false, false
            setStatus("Todos os monitores locais foram encerrados.")
        end, COLORS.red)
        makeLabel("Versão 5.3 — automações de interação local ampliadas. Recompensas, inventário e missões continuam sob autoridade do servidor.", 56)
        endSection()

    elseif category == "Configurações" then
        beginSection("Interface", false)

        makeButton("Recentralizar painel", function()
            Main.Position = UDim2.new(
                0.5,
                -Main.AbsoluteSize.X / 2,
                0.5,
                -Main.AbsoluteSize.Y / 2
            )
            setStatus("Painel recentralizado.")
        end)

        endSection()

        beginSection("Personagem", false)

        makeButton("Reaplicar velocidade e pulo", function()
            local character = getCharacter()
            local hum = character and character:FindFirstChildOfClass("Humanoid")

            if hum then
                hum.WalkSpeed = getAdjustedWalkSpeed()
                hum.UseJumpPower = true
                hum.JumpPower = jumpPower
                setStatus("Configurações locais reaplicadas.")
            else
                setStatus("Personagem ainda não carregou.")
            end
        end)

        endSection()

        beginSection("Limpeza", false)

        makeButton("Limpar destaques visuais", function()
            espPlayers, showNames, showDistances, fruitFinder, chestFinder, bossESP =
                false, false, false, false, false, false

            removeHighlights(playerHighlights)
            removeHighlights(fruitHighlights)
            removeHighlights(chestHighlights)
            removeHighlights(bossHighlights)
            setStatus("Destaques removidos.")
        end)

        endSection()
    end
end

local categories = {
    "Início",
    "Jogador",
    "Teletransporte",
    "Frutas",
    "Espadas",
    "Armas",
    "Chefes",
    "Eventos Marítimos",
    "Factory",
    "Materiais",
    "Objetivos",
    "Missões e Trials",
    "Combate",
    "Anti-Ataque",
    "Visualização",
    "Coleta e evolução",
    "Administração",
    "Configurações",
    "Extras"
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

    tab.Activated:Connect(function()
        for _, sibling in ipairs(Sidebar:GetChildren()) do
            if sibling:IsA("TextButton") then
                sibling.BackgroundColor3 = COLORS.row
            end
        end

        tab.BackgroundColor3 = COLORS.purple
        showCategory(category)
    end)
end

Min.Activated:Connect(MinimizePanel)

Close.Activated:Connect(function()
    destroyed = true
    stopAllWorldAutomations()
    autoAttackEnabled = false
    autoHakiEnabled = false
    autoSkillsEnabled = false
    autoFarmEnabled = false
    autoBossFarmEnabled = false
    antiAttackEnabled = false
    antiAttackDodgeUntil = 0
    flyEnabled = false
    combatFollowTarget = nil
    clearManagedVelocity()
    teleportSequence += 1
    playerTeleportSequence += 1

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    stopAllMonitors()
    clearMonitorHighlights("objective")
    removeHighlights(playerHighlights)
    removeHighlights(fruitHighlights)
    removeHighlights(chestHighlights)
    removeHighlights(bossHighlights)
    Screen:Destroy()
end)

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

local camera = Workspace.CurrentCamera

local function fitToScreen()
    camera = Workspace.CurrentCamera
    if not camera or minimized then return end

    local viewport = camera.ViewportSize
    local width = math.max(300, math.min(620, viewport.X - 24))
    local height = math.max(280, math.min(430, viewport.Y - 40))

    expandedSize = UDim2.fromOffset(width, height)
    Main.Size = expandedSize
    Main.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    expandedPosition = Main.Position

    Sidebar.Size = UDim2.new(0, math.min(145, width * 0.27), 1, -60)
    Content.Position = UDim2.fromOffset(math.min(153, width * 0.29), 54)
    Content.Size = UDim2.new(1, -math.min(166, width * 0.31), 1, -60)
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
        local character = getCharacter()
        local hum = character and character:FindFirstChildOfClass("Humanoid")

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

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)

    local hum = character:FindFirstChildOfClass("Humanoid")

    if hum then
        hum.WalkSpeed = getAdjustedWalkSpeed()
        hum.UseJumpPower = true
        hum.JumpPower = jumpPower
    end

    combatFollowTarget = nil

    for part in pairs(collisionCache) do
        collisionCache[part] = nil
    end
end))

task.spawn(function()
    while Screen.Parent do
        task.wait(1.25)
        if not Screen.Parent then break end

        if espPlayers or showNames or showDistances then
            applyPlayerVisuals()
        end

        if bossESP then
            refreshBossESP(true)
        end
    end
end)

table.insert(connections, Players.PlayerAdded:Connect(function()
    if espPlayers or showNames or showDistances then
        task.delay(0.5, applyPlayerVisuals)
    end
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        selectedAttackTargets[player.Character] = nil
    end

    if selectedPlayer == player then
        selectedPlayer = nil
    end

    if espPlayers or showNames or showDistances then
        task.delay(0.2, applyPlayerVisuals)
    end
end))

--========================================================
-- FLY
--========================================================

table.insert(connections, RunService.Heartbeat:Connect(function(deltaTime)
    local nowHeartbeat = os.clock()
    local frameDelta = math.clamp(nowHeartbeat - flyLastHeartbeatAt, 1 / 240, 0.08)
    flyLastHeartbeatAt = nowHeartbeat
    if not flyEnabled then
        followFlyActive = false
        if not antiAttackWasDriving then
            flyCurrentVelocity = Vector3.zero
            flyVelocityRoot = nil
        end
        return
    end

    local character = getCharacter()
    local root = getRoot(character)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local currentCamera = Workspace.CurrentCamera

    if not root or not hum or not currentCamera then return end

    local adjustedFlySpeed = getAdjustedFlySpeed()
    local target = nil

    if autoAttackEnabled or autoHakiEnabled or autoSkillsEnabled then
        target = combatFollowTarget
    end

    if target and target.root and target.root.Parent
        and target.humanoid and target.humanoid.Health > 0 then

        followFlyActive = true

        local targetRoot = target.root
        local now = os.clock()
        local followPosition

        if antiAttackEnabled and now < antiAttackDodgeUntil then
            -- O Anti-Ataque e dono do movimento durante a esquiva.
            -- Sincroniza o filtro para o Fly retomar sem tranco ao terminar.
            followFlyActive = true
            flyCurrentVelocity = root.AssemblyLinearVelocity
            flyVelocityRoot = root
            return
        end

        if not antiAttackEnabled and now < combatDodgeUntil then
            followPosition = root.Position + combatDodgeVector * 16 + Vector3.new(0, 3, 0)
        else
            followPosition = targetRoot.Position
                - targetRoot.CFrame.LookVector * 9
                + targetRoot.CFrame.RightVector * (dodgeSide * 3)
                + Vector3.new(0, 3, 0)
        end

        local offset = followPosition - root.Position
        local distance = offset.Magnitude

        local desiredVelocity = Vector3.zero
        if distance > 2.5 then
            local direction = offset.Unit
            -- Controle proporcional reduz ultrapassagens e oscilacoes ao orbitar o alvo.
            local speed = math.min(adjustedFlySpeed, distance * 2.15)
            desiredVelocity = direction * speed
        end
        setManagedVelocity(root, getSmoothedFlyVelocity(root, desiredVelocity, frameDelta))

        root.AssemblyAngularVelocity = Vector3.zero
        hum:ChangeState(Enum.HumanoidStateType.Physics)

        handleFollowJump(hum, root, targetRoot)
        return
    end

    followFlyActive = false

    local cameraCFrame = currentCamera.CFrame
    local look = cameraCFrame.LookVector
    local right = cameraCFrame.RightVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    local flatRight = Vector3.new(right.X, 0, right.Z)
    if flatLook.Magnitude < 0.001 then flatLook = Vector3.new(0, 0, -1) end
    if flatRight.Magnitude < 0.001 then flatRight = Vector3.new(1, 0, 0) end
    flatLook = flatLook.Unit
    flatRight = flatRight.Unit

    local forwardInput = 0
    local sideInput = 0
    local verticalInput = 0

    if UIS.TouchEnabled then
        -- O direcional do celular controla apenas o plano horizontal.
        -- Subida/descida fica separada para a inclinacao da camera nao roubar velocidade.
        local moveDirection = hum.MoveDirection
        forwardInput = moveDirection:Dot(flatLook)
        sideInput = moveDirection:Dot(flatRight)
        if hum.Jump then verticalInput = 1 end
    else
        if UIS:IsKeyDown(Enum.KeyCode.W) then forwardInput += 1 end
        if UIS:IsKeyDown(Enum.KeyCode.S) then forwardInput -= 1 end
        if UIS:IsKeyDown(Enum.KeyCode.D) then sideInput += 1 end
        if UIS:IsKeyDown(Enum.KeyCode.A) then sideInput -= 1 end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then verticalInput += 1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then verticalInput -= 1 end
    end

    -- No celular, inclinar a camera para cima/baixo permite voar nessa direcao
    -- usando o direcional. No PC, W/S ficam no plano horizontal e E/Q controlam altura.
    local forwardVector = UIS.TouchEnabled and look.Unit or flatLook

    -- LinearVelocity sustenta o vetor completo contra a gravidade: subir, descer,
    -- andar para os lados e diagonais recebem a mesma velocidade configurada.
    local direction = (forwardVector * forwardInput)
        + (flatRight * sideInput)
        + Vector3.new(0, verticalInput, 0)
    if direction.Magnitude > 1 then direction = direction.Unit end

    local desiredVelocity = direction * adjustedFlySpeed
    root.AssemblyAngularVelocity = Vector3.zero
    setManagedVelocity(root, getSmoothedFlyVelocity(root, desiredVelocity, frameDelta))
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end))

--========================================================
-- ANTI-ATAQUE (MODULO INDEPENDENTE)
-- Prioridade PvP: jogadores reais primeiro; depois projeteis e NPCs.
-- A deteccao depende dos sinais que a experiencia replica ao cliente.
--========================================================

local function getAttackerModelFromPart(part)
    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and current ~= getCharacter()
            and current:FindFirstChildOfClass("Humanoid")
            and getRoot(current) then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function beginAntiAttackDodge(root, threatPosition, longRange)
    local now = os.clock()
    -- Evita reiniciar a mesma esquiva a cada ciclo de deteccao.
    if now < antiAttackDodgeUntil then return false end
    if now - antiAttackLastTrigger < 0.38 then return false end
    antiAttackLastTrigger = now
    antiAttackSide = -antiAttackSide

    local away = root.Position - threatPosition
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.05 then
        local camera = Workspace.CurrentCamera
        away = camera and Vector3.new(-camera.CFrame.LookVector.X, 0, -camera.CFrame.LookVector.Z)
            or Vector3.new(0, 0, 1)
    end
    if away.Magnitude < 0.05 then away = Vector3.new(0, 0, 1) end
    away = away.Unit
    local side = Vector3.new(-away.Z, 0, away.X) * antiAttackSide
    local direction = (away * (longRange and 0.82 or 0.62) + side * (longRange and 0.75 or 1.0)).Unit

    antiAttackDodgeDirection = direction
    antiAttackDodgeUntil = now + (longRange and 0.72 or 0.48)
    -- Usa a velocidade do Fly como teto de referencia, sem ligar o Fly na interface.
    antiAttackDodgeSpeed = math.clamp(math.max(flySpeed, 120), 120, 1400)
    return true
end

local function findIncomingProjectile(root, character)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.MaxParts = 260

    local ok, nearbyParts = pcall(function()
        return Workspace:GetPartBoundsInRadius(root.Position, 260, params)
    end)
    if not ok then return nil end

    local playerVelocity = root.AssemblyLinearVelocity
    local bestThreat, bestScore = nil, math.huge
    for _, part in ipairs(nearbyParts) do
        if part:IsA("BasePart") and part.Parent and not part:IsDescendantOf(character) then
            local velocity = part.AssemblyLinearVelocity
            local speed = velocity.Magnitude
            local relativePosition = part.Position - root.Position
            local distanceNow = relativePosition.Magnitude
            local lowerName = string.lower(part.Name)
            local looksLikeAttackEffect = string.find(lowerName, "hitbox", 1, true)
                or string.find(lowerName, "projectile", 1, true)
                or string.find(lowerName, "bullet", 1, true)
                or string.find(lowerName, "missile", 1, true)
                or string.find(lowerName, "explosion", 1, true)
                or string.find(lowerName, "blast", 1, true)
                or string.find(lowerName, "damage", 1, true)
            local largeNearbyHitbox = part.Size.Magnitude >= 22 and distanceNow <= 42
                and (not part.Anchored or looksLikeAttackEffect)
            if looksLikeAttackEffect and distanceNow <= 65 then
                return part.Position
            end
            if largeNearbyHitbox then
                return part.Position
            end
            if speed >= 16 then
                local relativeVelocity = velocity - playerVelocity
                local velocitySquared = relativeVelocity:Dot(relativeVelocity)
                if velocitySquared > 1 then
                    local timeToClosest = math.clamp(-relativePosition:Dot(relativeVelocity) / velocitySquared, 0, 2.4)
                    local closest = relativePosition + relativeVelocity * timeToClosest
                    local missDistance = closest.Magnitude
                    local closing = relativePosition:Dot(relativeVelocity) < 0
                    if closing and missDistance <= 18 and timeToClosest > 0.01 then
                        local score = timeToClosest + missDistance / 30
                        if score < bestScore then
                            bestScore = score
                            bestThreat = part.Position + velocity * timeToClosest
                        end
                    end
                end
            end
        end
    end
    return bestThreat
end

local knownFruitNames = {
    "rocket", "spin", "blade", "spring", "bomb", "smoke", "spike", "flame", "ice",
    "sand", "dark", "eagle", "diamond", "light", "rubber", "ghost", "magma", "quake",
    "buddha", "love", "creation", "spider", "sound", "phoenix", "portal", "rumble",
    "pain", "gravity", "mammoth", "trex", "t-rex", "dough", "shadow", "venom",
    "control", "spirit", "dragon", "leopard", "kitsune", "tiger", "yeti", "gas", "lightning"
}

local function getEquippedThreatClass(model)
    local equippedTool = model and model:FindFirstChildOfClass("Tool")
    if not equippedTool then return "unknown", nil end

    local name = string.lower(equippedTool.Name)
    local class = "unknown"
    local normalized = string.gsub(name, "[^%w%-]", "")
    local isFruit = false
    for _, fruitName in ipairs(knownFruitNames) do
        if string.find(normalized, fruitName, 1, true) then
            isFruit = true
            break
        end
    end

    if isFruit then
        class = "fruit"
    elseif string.find(name, "gun", 1, true) or string.find(name, "rifle", 1, true)
        or string.find(name, "pistol", 1, true) or string.find(name, "bow", 1, true)
        or string.find(name, "musket", 1, true) or string.find(name, "flintlock", 1, true)
        or string.find(name, "kabucha", 1, true) or string.find(name, "bazooka", 1, true)
        or string.find(name, "cannon", 1, true) then
        class = "ranged"
    elseif string.find(name, "sword", 1, true) or string.find(name, "katana", 1, true)
        or string.find(name, "blade", 1, true) or string.find(name, "scythe", 1, true)
        or string.find(name, "trident", 1, true) or string.find(name, "hook", 1, true) then
        class = "melee"
    else
        -- Frutas e estilos de luta também são Tools; nomes não padronizados ficam
        -- como unknown e são avaliados pela animação, direção e movimento.
        class = "ability"
    end
    return class, equippedTool
end

local function hasActionAnimation(humanoid)
    if not humanoid then return false end
    local found = false
    pcall(function()
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            if track.IsPlaying and track.Priority.Value >= Enum.AnimationPriority.Action.Value then
                local length = track.Length
                local position = track.TimePosition
                -- Prioriza o inicio do movimento ou animacoes curtas de golpe.
                if position <= 0.42 or (length > 0 and length <= 0.7) then
                    found = true
                    break
                end
            end
        end
    end)
    return found
end

-- Players reais são avaliados primeiro. A leitura usa apenas sinais que o cliente
-- consegue observar: ferramenta equipada, animação replicada, orientação e velocidade.
local function findIncomingPlayerThreat(root, character)
    local bestThreat, bestScore, bestLongRange = nil, math.huge, false
    local now = os.clock()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local model = player.Character
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            local attackerRoot = getRoot(model)
            if model and humanoid and humanoid.Health > 0 and attackerRoot then
                local offset = root.Position - attackerRoot.Position
                local distance = offset.Magnitude
                if distance > 0.1 and distance <= 260 then
                    local towardPlayer = offset.Unit
                    local facing = attackerRoot.CFrame.LookVector:Dot(towardPlayer)
                    local relativeVelocity = attackerRoot.AssemblyLinearVelocity - root.AssemblyLinearVelocity
                    local closingSpeed = relativeVelocity:Dot(towardPlayer)
                    local toolClass, equippedTool = getEquippedThreatClass(model)
                    local actionAnimation = hasActionAnimation(humanoid)
                    local genuinelyClosing = closingSpeed > 6
                    local closeMeleeApproach = distance <= 18 and genuinelyClosing
                    local hasAttackEvidence

                    if toolClass == "ranged" or toolClass == "fruit" or toolClass == "ability" then
                        -- Para ataques de longa distancia, exige animacao de ataque
                        -- direcionada; a Tool equipada sozinha nao provoca esquiva.
                        hasAttackEvidence = actionAnimation and facing > 0.48
                    elseif toolClass == "melee" then
                        hasAttackEvidence = actionAnimation or closeMeleeApproach
                    else
                        hasAttackEvidence = actionAnimation
                            or (distance <= 14 and genuinelyClosing and facing > 0.62)
                    end

                    local previousThreatAt = antiAttackThreatMemory[player] or 0
                    local playerReady = (now - previousThreatAt) >= 0.85
                    local directionalEvidence = (actionAnimation and facing > 0.25)
                        or (closeMeleeApproach and facing > 0.55)

                    if hasAttackEvidence and directionalEvidence and playerReady then
                        local ranged = toolClass == "ranged" or toolClass == "fruit" or toolClass == "ability"
                        local rangeWeight = ranged and 0.0018 or 0.014
                        local score = (actionAnimation and 0 or 0.4)
                            + distance * rangeWeight
                            - math.clamp(closingSpeed, 0, 45) * 0.02
                            - (toolClass ~= "unknown" and 0.1 or 0)
                        if score < bestScore then
                            bestScore = score
                            bestThreat = attackerRoot.Position
                            bestLongRange = ranged or distance > 28
                            antiAttackLastPlayerThreat = {
                                player = player,
                                tool = equippedTool and equippedTool.Name or "unknown",
                                class = toolClass,
                                distance = distance,
                                seenAt = now
                            }
                            antiAttackThreatMemory[player] = now
                        end
                    end
                end
            end
        end
    end
    return bestThreat, bestLongRange
end

-- NPCs continuam suportados, mas so sao consultados depois dos jogadores reais.
local function findIncomingNpcThreat(root, character)
    local bestPosition, bestDistance = nil, math.huge
    local checked = {}

    local function inspectModel(model)
        if not model or model == character or checked[model] then return end
        checked[model] = true
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local attackerRoot = getRoot(model)
        if not humanoid or humanoid.Health <= 0 or not attackerRoot then return end

        local offset = root.Position - attackerRoot.Position
        local distance = offset.Magnitude
        if distance <= 0.1 or distance > 55 then return end
        local towardPlayer = offset.Unit
        local facing = attackerRoot.CFrame.LookVector:Dot(towardPlayer)
        local velocityToward = attackerRoot.AssemblyLinearVelocity:Dot(towardPlayer)
        local actionAnimation = hasActionAnimation(humanoid)
        if (actionAnimation or velocityToward > 4 or (distance <= 14 and facing > 0.72))
            and distance < bestDistance then
            bestDistance = distance
            bestPosition = attackerRoot.Position
        end
    end

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local model = descendant.Parent
            if model and model:IsA("Model") then
                local isPlayerCharacter = false
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character == model then isPlayerCharacter = true break end
                end
                if not isPlayerCharacter then inspectModel(model) end
            end
        end
    end
    return bestPosition
end

task.spawn(function()
    while Screen.Parent do
        if antiAttackEnabled then
            local character = getCharacter()
            local root = getRoot(character)
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local currentHealth = humanoid.Health
                local tookDamage = antiAttackLastHealth ~= nil and currentHealth < antiAttackLastHealth - 0.5
                antiAttackLastHealth = currentHealth

                -- Ordem PvP: primeiro sinais de ataque dos jogadores reais, depois
                -- projeteis replicados (incluindo habilidades de fruta/armas), e por
                -- ultimo NPCs. Isso evita que a varredura de NPC roube prioridade.
                local playerThreat, playerLongRange = findIncomingPlayerThreat(root, character)
                local projectileThreat = findIncomingProjectile(root, character)
                local npcThreat = nil

                if playerThreat then
                    beginAntiAttackDodge(root, playerThreat, playerLongRange)
                elseif projectileThreat then
                    beginAntiAttackDodge(root, projectileThreat, true)
                else
                    npcThreat = findIncomingNpcThreat(root, character)
                    if npcThreat then
                        beginAntiAttackDodge(root, npcThreat, false)
                    elseif tookDamage then
                        -- Fallback reativo para AoE/ataques que o servidor nao replica
                        -- como projeteis ou animacoes observaveis.
                        local camera = Workspace.CurrentCamera
                        local fallbackThreat = camera
                            and (root.Position - camera.CFrame.LookVector * 12)
                            or (root.Position - Vector3.new(0, 0, 12))
                        beginAntiAttackDodge(root, fallbackThreat, true)
                    end
                end
            else
                antiAttackLastHealth = nil
            end
            task.wait(0.08)
        else
            task.wait(0.15)
        end
    end
end)

-- Controle temporario de movimento do Anti-Ataque. Nao altera os toggles
-- de Fly/Pulo infinito e so assume o movimento durante a janela de esquiva.
table.insert(connections, RunService.Heartbeat:Connect(function()
    local now = os.clock()
    local dodging = antiAttackEnabled and now < antiAttackDodgeUntil
    if not dodging then
        if antiAttackWasDriving then
            antiAttackWasDriving = false
            -- Se o Fly estiver ligado, o loop dele retoma o controlador no mesmo ciclo.
            if not flyEnabled then
                clearManagedVelocity()
                local character = getCharacter()
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
            -- Forca o combate a publicar um novo destino calculado da posicao atual.
            combatLastMoveGoal = nil
            combatLastMoveAt = 0
            combatWasInRange = false
        end
        return
    end

    local character = getCharacter()
    local root = getRoot(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end

    local direction = antiAttackDodgeDirection
    if direction.Magnitude < 0.05 then return end
    antiAttackWasDriving = true
    local speed = math.clamp(antiAttackDodgeSpeed, 120, 1400)
    local vertical = (antiAttackDodgeUntil - now > 0.35) and 12 or 0
    setManagedVelocity(root, direction.Unit * speed + Vector3.new(0, vertical, 0))
    root.AssemblyAngularVelocity = Vector3.zero
    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
end))

--========================================================
-- AIM ASSIST
--========================================================

local function getAimCandidates()
    local candidates = {}
    local selectedCount = 0

    for model in pairs(selectedAttackTargets) do
        if model and model.Parent and isValidAimType(model) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = getRoot(model)

            if hum and hum.Health > 0 and root then
                selectedCount += 1
            end
        end
    end

    local function addCandidate(model)
        if not model or model == getCharacter() then return end
        if not isValidAimType(model) then return end

        if selectedCount > 0 and selectedAttackTargets[model] ~= true then
            return
        end

        local hum = model:FindFirstChildOfClass("Humanoid")
        local head = model:FindFirstChild("Head")
        local root = getRoot(model)
        local part = head or root

        if not hum or hum.Health <= 0 or not part or not root then
            return
        end

        table.insert(candidates, {
            model = model,
            humanoid = hum,
            root = root,
            part = part
        })
    end

    if selectedAimTarget == "NPCs" then
        for _, item in ipairs(Workspace:GetDescendants()) do
            if item:IsA("Model")
                and item ~= getCharacter()
                and not getPlayerFromModel(item)
                and item:FindFirstChildOfClass("Humanoid") then

                addCandidate(item)
            end
        end
    end

    return candidates, selectedCount
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    local currentCamera = Workspace.CurrentCamera

    if currentCamera then
        local viewport = currentCamera.ViewportSize
        FOVCircle.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)
        FOVCircle.Size = UDim2.fromOffset(aimFovRadius * 2, aimFovRadius * 2)
        FOVCircle.Visible = aimFovEnabled
    end

    if not aimAssistEnabled then return end

    local myRoot = getRoot(getCharacter())
    if not currentCamera or not myRoot then return end

    local candidates = getAimCandidates()
    local bestPart = nil
    local bestScreenDistance = math.huge

    local center = Vector2.new(
        currentCamera.ViewportSize.X / 2,
        currentCamera.ViewportSize.Y / 2
    )

    local maxRadius = aimFovEnabled and aimFovRadius or 500

    for _, candidate in ipairs(candidates) do
        local part = candidate.part

        if part and part.Parent then
            local worldDistance = (part.Position - myRoot.Position).Magnitude

            if worldDistance <= 600 then
                local point, visible = currentCamera:WorldToViewportPoint(part.Position)

                if visible and point.Z > 0 then
                    local screenDistance = (
                        Vector2.new(point.X, point.Y) - center
                    ).Magnitude

                    if screenDistance <= maxRadius
                        and screenDistance < bestScreenDistance then

                        bestPart = part
                        bestScreenDistance = screenDistance
                    end
                end
            end
        end
    end

    if bestPart then
        currentCamera.CFrame = CFrame.new(
            currentCamera.CFrame.Position,
            bestPart.Position
        )
    end
end))

task.spawn(function()
    while Screen.Parent do
        task.wait(2)

        if not Screen.Parent then break end

        for model in pairs(selectedAttackTargets) do
            if not model or not model.Parent then
                selectedAttackTargets[model] = nil
            end
        end
    end
end)

showCategory("Início")

print("Blox F' - Tales 5.3 carregado.")
