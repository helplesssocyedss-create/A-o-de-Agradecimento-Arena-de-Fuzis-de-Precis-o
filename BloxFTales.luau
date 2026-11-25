--========================================================
-- BLOX F' - TALES | VERSAO 3.3
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
local fruitHighlights = {}
local chestHighlights = {}
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
local flyEnabled = false
local flySpeed = 65
local aimAssistEnabled = false
local aimFovEnabled = false
local aimFovRadius = 140
local autoAttackEnabled = false
local autoHakiEnabled = false
local autoSkillsEnabled = false
local autoFarmEnabled = false
local autoChestEnabled = false
local autoFruitEnabled = false
local autoMissionEnabled = false
local autoEvolutionEnabled = false
local autoRewardsEnabled = false
local selectedAimTarget = "NPCs"

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
Title.Text = "Blox F' - Tales  |  3.3"
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
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
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

    button.MouseButton1Click:Connect(function()
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
    header.Text = title
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

    header.MouseButton1Click:Connect(function()
        local open = not body.Visible
        body.Visible = open
        body.AutomaticSize = open and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
        body.Size = UDim2.new(1, -4, 0, 0)
        header.Text = title
    end)

    activeContainer = body
    return body
end

local function endSection()
    activeContainer = Content
end

local function makeOption(labelText, isSelected, callback)
    local row = Instance.new("Frame")
    row.Name = "SelectionOption"
    row.Size = UDim2.new(1, -4, 0, 38)
    row.BackgroundColor3 = COLORS.row
    row.BorderSizePixel = 0
    row.Parent = activeContainer
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextButton")
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Position = UDim2.fromOffset(9, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.white
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = row

    local check = Instance.new("TextButton")
    check.Name = "SelectBox"
    check.Size = UDim2.fromOffset(25, 25)
    check.Position = UDim2.new(1, -33, 0.5, -12)
    check.BackgroundColor3 = isSelected and COLORS.green or COLORS.gray
    check.Text = isSelected and "✓" or ""
    check.TextColor3 = COLORS.white
    check.TextSize = 15
    check.Font = Enum.Font.GothamBold
    check.AutoButtonColor = false
    check.Parent = row
    Instance.new("UICorner", check).CornerRadius = UDim.new(0, 6)

    local function choose()
        if callback then callback() end
    end

    label.MouseButton1Click:Connect(choose)
    check.MouseButton1Click:Connect(choose)
    return row, check
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

    for object, adornment in pairs(bucket) do
        if adornment and adornment.Parent then
            adornment:Destroy()
        end
        bucket[object] = nil
    end

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

local function makePlayerSelection()
    makeLabel("Selecione um jogador e use o botão de confirmação abaixo.", 38)
    local selectionLabel = makeLabel("Selecionado: nenhum", 25)
    local confirmButton
    local optionChecks = {}

    local function updateSelection()
        selectionLabel.Text = "Selecionado: " .. (selectedPlayer and selectedPlayer.DisplayName or "nenhum")

        for player, check in pairs(optionChecks) do
            local chosen = player == selectedPlayer
            if check and check.Parent then
                check.BackgroundColor3 = chosen and COLORS.green or COLORS.gray
                check.Text = chosen and "✓" or ""
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

            local _, check = makeOption(
                target.DisplayName .. "  (@" .. target.Name .. ")",
                selectedPlayer == target,
                function()
                    selectedPlayer = target
                    updateSelection()
                end
            )

            optionChecks[target] = check
        end
    end

    if not found then
        makeLabel("Nenhum outro jogador está no servidor.", 32)
    end

    confirmButton = makeButton("CONFIRMAR TELETRANSPORTE PARA O JOGADOR", function()
        local target = selectedPlayer

        if not target or not target.Parent then
            setStatus("Selecione um jogador que ainda esteja no servidor.")
            return
        end

        local targetRoot = getRoot(target.Character)
        if not targetRoot then
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

        yes.MouseButton1Click:Connect(function()
            local latestRoot = getRoot(target.Character)

            if latestRoot then
                teleportLocal(latestRoot.CFrame * CFrame.new(0, 0, 4))
                setStatus("Teletransporte local solicitado.")
            else
                setStatus("O jogador não está mais disponível.")
            end

            dialog:Destroy()
        end)

        no.MouseButton1Click:Connect(function()
            dialog:Destroy()
        end)
    end, COLORS.purple)

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
    box.Parent = activeContainer
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

        if hum then hum.WalkSpeed = walkSpeed end

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
    jumpBox.Parent = activeContainer
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
    activeContainer = Content
    clearContent()
    Content.CanvasPosition = Vector2.new(0, 0)

    if category == "Início" then
        beginSection("Painel e status")
        makeLabel("BLOX F' - TALES 3.2", 36)
        makeLabel("Interface organizada por seções. Toque no título de cada seção para abrir ou recolher os controles.", 52)
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
        makeLabel("Os recursos locais atuam no cliente. Ações internas do jogo precisam dos sistemas oficiais do servidor.", 58)
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
            setStatus(on and "Fly ligado" or "Fly desligado")
        end)

        makeInput("Velocidade do Fly", "Velocidade (10 a 200)", flySpeed, function(value)
            local n = tonumber(value)
            if n then flySpeed = math.clamp(n, 10, 200) end
            setStatus("Velocidade do Fly: " .. tostring(flySpeed))
        end)

        endSection()

        beginSection("Colisão")
        makeToggle("Atravessar paredes (local)", function(on)
            noclip = on
            setStatus(on and "Noclip local ligado" or "Noclip local desligado")
        end)

        makeLabel("O noclip altera colisões apenas no seu cliente; o servidor pode corrigir sua posição.", 48)
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
        local optionChecks = {}

        for _, worldData in ipairs(islandWorlds) do
            beginSection(worldData.world, true)

            for _, islandData in ipairs(worldData.islands) do
                local islandName, aliases = islandData[1], islandData[2]

                local _, check = makeOption(islandName, selectedIsland == islandName, function()
                    selectedIsland = islandName
                    selectedLabel.Text = "Destino selecionado: " .. islandName

                    for name, button in pairs(optionChecks) do
                        if button and button.Parent then
                            local chosen = name == selectedIsland
                            button.BackgroundColor3 = chosen and COLORS.green or COLORS.gray
                            button.Text = chosen and "✓" or ""
                        end
                    end
                end)

                optionChecks[islandName] = check
            end

            endSection()
        end

        beginSection("Confirmar destino")

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
                setStatus(ok and ("Indo para " .. selectedIsland) or "Não foi possível mover o personagem.")
            else
                setStatus("Não encontrei " .. selectedIsland .. " no mapa carregado. O nome interno do mapa pode ser diferente.")
            end
        end, COLORS.green)

        endSection()

        beginSection("Teletransporte por coordenadas")

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

            setStatus(ok and "Teleporte local solicitado." or "Não foi possível teletransportar.")
        end, COLORS.purple)

        endSection()

        beginSection("Teletransporte para jogador")
        makePlayerSelection()
        endSection()

    elseif category == "Visualização" then
        beginSection("Jogadores")

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

        beginSection("Localizadores")

        makeToggle("Localizador de frutas", function(on)
            fruitFinder = on
            refreshObjectHighlights("fruit", on)
        end)

        makeToggle("Localizador de baús", function(on)
            chestFinder = on
            refreshObjectHighlights("chest", on)
        end)

        makeLabel("Os localizadores procuram objetos replicados no Workspace com nomes relacionados a frutas e baús.", 48)
        endSection()

    elseif category == "Combate" then
        beginSection("Mira e seleção de alvos")

        makeToggle("Aim Assist", function(on)
            aimAssistEnabled = on
            setStatus(on and "Aim Assist ativado" or "Aim Assist desativado")
        end)

        makeToggle("Mostrar FOV", function(on)
            aimFovEnabled = on
            setStatus(on and "FOV ativado" or "FOV desativado")
        end)

        makeInput("Raio do FOV", "Raio em pixels", aimFovRadius, function(value)
            local n = tonumber(value)
            if n then aimFovRadius = math.clamp(n, 30, 500) end
            setStatus("Raio do FOV: " .. tostring(aimFovRadius))
        end)

        makeOption("Alvos: NPCs", selectedAimTarget == "NPCs", function()
            selectedAimTarget = "NPCs"
            setStatus("Alvo selecionado: NPCs")
        end)

        makeOption("Alvos: Jogadores", selectedAimTarget == "Jogadores", function()
            selectedAimTarget = "Jogadores"
            setStatus("Alvo selecionado: Jogadores")
        end)

        makeOption("Alvos: Todos", selectedAimTarget == "Todos", function()
            selectedAimTarget = "Todos"
            setStatus("Alvo selecionado: todos")
        end)

        endSection()

        beginSection("Ataque, habilidades e Haki")

        makeToggle("Ataque automático", function(on)
            autoAttackEnabled = on
            setStatus(on and "Ataque automático ligado" or "Ataque automático desligado")
        end)

        makeToggle("Haki automático", function(on)
            autoHakiEnabled = on
            setStatus(on and "Haki automático ligado" or "Haki automático desligado")
        end)

        makeToggle("Uso automático de habilidades", function(on)
            autoSkillsEnabled = on
            setStatus(on and "Habilidades automáticas ligadas" or "Habilidades automáticas desligadas")
        end)

        endSection()

    elseif category == "Frutas" then
        beginSection("Catálogo e localização")

        makeToggle("Detector de frutas", function(on)
            fruitFinder = on
            refreshObjectHighlights("fruit", on)
            setStatus(on and "Detector de frutas ligado" or "Detector de frutas desligado")
        end)

        makeToggle("Coletar frutas automaticamente", function(on)
            autoFruitEnabled = on
            setStatus(on and "Coleta automática de frutas ligada" or "Coleta automática de frutas desligada")
        end)

        makeLabel("Catálogo de frutas: Rocket, Spin, Chop, Spring, Bomb, Smoke, Spike, Flame, Falcon, Ice, Sand, Dark, Diamond, Light, Rubber, Barrier, Ghost, Magma, Quake, Buddha, Love, Spider, Sound, Phoenix, Portal, Rumble, Pain, Blizzard, Gravity, Mammoth, T-Rex, Dough, Shadow, Venom, Control, Spirit, Dragon e Leopard.", 100)

        endSection()

    elseif category == "Coleta e evolução" then
        beginSection("Coleta automática")

        makeToggle("Auto Farm", function(on)
            autoFarmEnabled = on
            setStatus(on and "Auto Farm ativado" or "Auto Farm desativado")
        end)

        makeToggle("Auto Chest", function(on)
            autoChestEnabled = on
            setStatus(on and "Auto Chest ativado" or "Auto Chest desativado")
        end)

        makeToggle("Auto Fruit", function(on)
            autoFruitEnabled = on
            setStatus(on and "Auto Fruit ativado" or "Auto Fruit desativado")
        end)

        makeToggle("Auto Mission", function(on)
            autoMissionEnabled = on
            setStatus(on and "Auto Mission ativado" or "Auto Mission desativado")
        end)

        endSection()

        beginSection("Evolução e recompensas")

        makeToggle("Auto Evolution", function(on)
            autoEvolutionEnabled = on
            setStatus(on and "Auto Evolution ativado" or "Auto Evolution desativado")
        end)

        makeToggle("Auto Rewards", function(on)
            autoRewardsEnabled = on
            setStatus(on and "Auto Rewards ativado" or "Auto Rewards desativado")
        end)

        endSection()

    elseif category == "Configurações" then
        beginSection("Interface")

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

        beginSection("Personagem")

        makeButton("Reaplicar velocidade e pulo", function()
            local character = getCharacter()
            local hum = character and character:FindFirstChildOfClass("Humanoid")

            if hum then
                hum.WalkSpeed = walkSpeed
                hum.UseJumpPower = true
                hum.JumpPower = jumpPower
                setStatus("Configurações locais reaplicadas.")
            else
                setStatus("Personagem ainda não carregou.")
            end
        end)

        endSection()

        beginSection("Limpeza")

        makeButton("Limpar destaques visuais", function()
            espPlayers, showNames, showDistances, fruitFinder, chestFinder = false, false, false, false, false
            removeHighlights(playerHighlights)
            removeHighlights(fruitHighlights)
            removeHighlights(chestHighlights)
            setStatus("Destaques removidos.")
        end)

        endSection()
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
    removeHighlights(fruitHighlights)
    removeHighlights(chestHighlights)
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

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)

    local hum = character:FindFirstChildOfClass("Humanoid")

    if hum then
        hum.WalkSpeed = walkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = jumpPower
    end

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
    end
end)

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

-- Fly local: usa MoveDirection do Humanoid e teclas de subida/descida.
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not flyEnabled then return end

    local character = getCharacter()
    local root = getRoot(character)
    local hum = character and character:FindFirstChildOfClass("Humanoid")

    if not root or not hum then return end

    local direction = hum.MoveDirection
    local vertical = 0

    if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then
        vertical += 1
    end

    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then
        vertical -= 1
    end

    local velocity = direction * flySpeed + Vector3.new(0, vertical * flySpeed, 0)
    root.AssemblyLinearVelocity = velocity
end))

-- Aim Assist local: acompanha o alvo mais próximo dentro do raio configurado.
table.insert(connections, RunService.RenderStepped:Connect(function()
    if not aimAssistEnabled then return end

    local camera = Workspace.CurrentCamera
    local myRoot = getRoot(getCharacter())

    if not camera or not myRoot then return end

    local bestPart, bestDistance = nil, math.huge

    local function consider(model)
        if not model or model == getCharacter() then return end

        local hum = model:FindFirstChildOfClass("Humanoid")
        local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")

        if not hum or hum.Health <= 0 or not part then return end

        local worldDistance = (part.Position - myRoot.Position).Magnitude
        if worldDistance > 600 then return end

        local point, visible = camera:WorldToViewportPoint(part.Position)
        if not visible then return end

        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local screenDistance = (Vector2.new(point.X, point.Y) - center).Magnitude
        local maxRadius = aimFovEnabled and aimFovRadius or 500

        if screenDistance <= maxRadius and screenDistance < bestDistance then
            bestPart, bestDistance = part, screenDistance
        end
    end

    if selectedAimTarget == "NPCs" or selectedAimTarget == "Todos" then
        for _, item in ipairs(Workspace:GetDescendants()) do
            if item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") then
                consider(item)
            end
        end
    end

    if selectedAimTarget == "Jogadores" or selectedAimTarget == "Todos" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                consider(player.Character)
            end
        end
    end

    if bestPart then
        camera.CFrame = CFrame.new(camera.CFrame.Position, bestPart.Position)
    end
end))

showCategory("Início")

print("Blox F' - Tales 3.3 carregado.")
