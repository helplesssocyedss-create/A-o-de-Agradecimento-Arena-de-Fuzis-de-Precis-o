local Players = game:GetService("Players")

local UIS = game:GetService("UserInputService")

local RunService = game:GetService("RunService")

local TweenService = game:GetService("TweenService")

local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("BloxFTales")

if old then old:Destroy() end

local THEMES = {

Azul = {

bg = Color3.fromRGB(4, 9, 20),

bgTop = Color3.fromRGB(10, 24, 48),

panel = Color3.fromRGB(8, 17, 34),

card = Color3.fromRGB(12, 26, 50),

row = Color3.fromRGB(15, 33, 62),

accent = Color3.fromRGB(0, 170, 255),

accentGlow = Color3.fromRGB(90, 210, 255),

line = Color3.fromRGB(28, 95, 165),

header = Color3.fromRGB(6, 20, 42)

},

Violeta = {

bg = Color3.fromRGB(10, 6, 22),

bgTop = Color3.fromRGB(24, 14, 52),

panel = Color3.fromRGB(16, 10, 34),

card = Color3.fromRGB(24, 15, 48),

row = Color3.fromRGB(30, 19, 60),

accent = Color3.fromRGB(165, 85, 255),

accentGlow = Color3.fromRGB(205, 150, 255),

line = Color3.fromRGB(95, 48, 165),

header = Color3.fromRGB(14, 8, 30)

},

Vermelha = {

bg = Color3.fromRGB(20, 5, 8),

bgTop = Color3.fromRGB(46, 12, 18),

panel = Color3.fromRGB(30, 8, 13),

card = Color3.fromRGB(42, 12, 19),

row = Color3.fromRGB(54, 16, 25),

accent = Color3.fromRGB(245, 55, 75),

accentGlow = Color3.fromRGB(255, 125, 140),

line = Color3.fromRGB(155, 35, 50),

header = Color3.fromRGB(26, 7, 11)

},

Ciano = {

bg = Color3.fromRGB(4, 16, 20),

bgTop = Color3.fromRGB(10, 42, 50),

panel = Color3.fromRGB(7, 26, 32),

card = Color3.fromRGB(11, 38, 46),

row = Color3.fromRGB(15, 48, 58),

accent = Color3.fromRGB(0, 230, 235),

accentGlow = Color3.fromRGB(120, 250, 255),

line = Color3.fromRGB(24, 135, 145),

header = Color3.fromRGB(6, 22, 28)

},

Verde = {

bg = Color3.fromRGB(4, 18, 12),

bgTop = Color3.fromRGB(10, 44, 30),

panel = Color3.fromRGB(7, 28, 19),

card = Color3.fromRGB(11, 40, 28),

row = Color3.fromRGB(15, 52, 36),

accent = Color3.fromRGB(25, 225, 135),

accentGlow = Color3.fromRGB(120, 255, 190),

line = Color3.fromRGB(24, 135, 85),

header = Color3.fromRGB(6, 24, 16)

}

}

local COLORS = {

bg = THEMES.Azul.bg,

bgTop = THEMES.Azul.bgTop,

panel = THEMES.Azul.panel,

row = THEMES.Azul.row,

purple = THEMES.Azul.accent,

accentGlow = THEMES.Azul.accentGlow,

green = Color3.fromRGB(28, 210, 125),

gray = Color3.fromRGB(48, 66, 92),

white = Color3.fromRGB(242, 248, 255),

red = Color3.fromRGB(235, 62, 78),

muted = Color3.fromRGB(145, 170, 202),

line = THEMES.Azul.line,

header = THEMES.Azul.header,

card = THEMES.Azul.card

}

local currentThemeName = "Azul"

local themeUpdaters = {}

local function registerThemeUpdater(fn)

table.insert(themeUpdaters, fn)

end

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

local flySpeed = 65

local globalSpeed = 0

local function getGlobalSpeedMultiplier()

return 1 + (globalSpeed / 100)

end

local function getAdjustedWalkSpeed()

return walkSpeed * getGlobalSpeedMultiplier()

end

local function getAdjustedFlySpeed()

return flySpeed * getGlobalSpeedMultiplier()

end

local function getAdjustedTeleportSpeed()

return playerTeleportSpeed * getGlobalSpeedMultiplier()

end

local playerTeleportSpeed = 100

local playerTeleportSequence = 0

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

FOVCircle.ZIndex = 20

FOVCircle.Parent = Screen

local FOVCorner = Instance.new("UICorner")

FOVCorner.CornerRadius = UDim.new(1, 0)

FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")

FOVStroke.Color = COLORS.purple

FOVStroke.Thickness = 2

FOVStroke.Transparency = 0.15

FOVStroke.Parent = FOVCircle

local MainShadow = Instance.new("Frame")

MainShadow.Name = "MainShadow"

MainShadow.Size = UDim2.fromOffset(772, 522)

MainShadow.Position = UDim2.new(0.5, -386, 0.5, -261)

MainShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

MainShadow.BackgroundTransparency = 0.45

MainShadow.BorderSizePixel = 0

MainShadow.ZIndex = 1

MainShadow.Parent = Screen

Instance.new("UICorner", MainShadow).CornerRadius = UDim.new(0, 18)

local shadowStroke = Instance.new("UIStroke", MainShadow)

shadowStroke.Color = COLORS.purple

shadowStroke.Thickness = 4

shadowStroke.Transparency = 0.78

local Main = Instance.new("Frame")

Main.Name = "Main"

Main.Size = UDim2.fromOffset(760, 510)

Main.Position = UDim2.new(0.5, -380, 0.5, -255)

Main.BackgroundColor3 = COLORS.bg

Main.BorderSizePixel = 0

Main.ClipsDescendants = true

Main.ZIndex = 2

Main.Parent = Screen

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", Main)

stroke.Color = COLORS.purple

stroke.Thickness = 2.2

stroke.Transparency = 0.05

local strokeGradient = Instance.new("UIGradient")

strokeGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.accentGlow),

ColorSequenceKeypoint.new(0.5, COLORS.purple),

ColorSequenceKeypoint.new(1, COLORS.line)

})

strokeGradient.Rotation = 45

strokeGradient.Parent = stroke

local mainGradient = Instance.new("UIGradient")

mainGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.bgTop),

ColorSequenceKeypoint.new(0.45, COLORS.bg),

ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 5, 12))

})

mainGradient.Rotation = 115

mainGradient.Parent = Main

local TopHighlight = Instance.new("Frame")

TopHighlight.Size = UDim2.new(1, -24, 0, 1)

TopHighlight.Position = UDim2.fromOffset(12, 1)

TopHighlight.BackgroundColor3 = COLORS.accentGlow

TopHighlight.BackgroundTransparency = 0.35

TopHighlight.BorderSizePixel = 0

TopHighlight.ZIndex = 5

TopHighlight.Parent = Main

local Header = Instance.new("Frame")

Header.Size = UDim2.new(1, 0, 0, 64)

Header.BackgroundColor3 = COLORS.header

Header.BorderSizePixel = 0

Header.ZIndex = 3

Header.Parent = Main

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local headerGradient = Instance.new("UIGradient")

headerGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.card),

ColorSequenceKeypoint.new(1, COLORS.header)

})

headerGradient.Rotation = 90

headerGradient.Parent = Header

local HeaderDivider = Instance.new("Frame")

HeaderDivider.Size = UDim2.new(1, 0, 0, 1)

HeaderDivider.Position = UDim2.new(0, 0, 1, -1)

HeaderDivider.BackgroundColor3 = COLORS.line

HeaderDivider.BackgroundTransparency = 0.35

HeaderDivider.BorderSizePixel = 0

HeaderDivider.Parent = Header

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1, -260, 0, 32)

Title.Position = UDim2.fromOffset(76, 8)

Title.BackgroundTransparency = 1

Title.Text = "BloxF Tales  |  4.2"

Title.TextColor3 = COLORS.white

Title.Font = Enum.Font.GothamBlack

Title.TextSize = 23

Title.TextXAlignment = Enum.TextXAlignment.Left

Title.Parent = Header

local BrandMark = Instance.new("Frame")

BrandMark.Size = UDim2.fromOffset(48, 48)

BrandMark.Position = UDim2.fromOffset(14, 8)

BrandMark.BackgroundColor3 = COLORS.card

BrandMark.BorderSizePixel = 0

BrandMark.Parent = Header

Instance.new("UICorner", BrandMark).CornerRadius = UDim.new(0, 14)

local brandGradient = Instance.new("UIGradient")

brandGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.purple),

ColorSequenceKeypoint.new(1, COLORS.header)

})

brandGradient.Rotation = 45

brandGradient.Parent = BrandMark

local brandStroke = Instance.new("UIStroke", BrandMark)

brandStroke.Color = COLORS.accentGlow

brandStroke.Thickness = 1.8

local BrandGlyph = Instance.new("TextLabel")

BrandGlyph.Size = UDim2.fromScale(1, 1)

BrandGlyph.BackgroundTransparency = 1

BrandGlyph.Text = "B"

BrandGlyph.TextColor3 = COLORS.white

BrandGlyph.Font = Enum.Font.GothamBlack

BrandGlyph.TextSize = 28

BrandGlyph.Parent = BrandMark

local BrandSubtitle = Instance.new("TextLabel")

BrandSubtitle.Size = UDim2.new(1, -270, 0, 18)

BrandSubtitle.Position = UDim2.fromOffset(78, 39)

BrandSubtitle.BackgroundTransparency = 1

BrandSubtitle.Text = "ULTRA HD  •  PAINEL DE CONTROLE"

BrandSubtitle.TextColor3 = COLORS.accentGlow

BrandSubtitle.Font = Enum.Font.GothamBold

BrandSubtitle.TextSize = 10

BrandSubtitle.TextXAlignment = Enum.TextXAlignment.Left

BrandSubtitle.Parent = Header

local ActivePill = Instance.new("Frame")

ActivePill.Size = UDim2.fromOffset(108, 28)

ActivePill.Position = UDim2.new(1, -194, 0, 18)

ActivePill.BackgroundColor3 = Color3.fromRGB(10, 44, 38)

ActivePill.BorderSizePixel = 0

ActivePill.Parent = Header

Instance.new("UICorner", ActivePill).CornerRadius = UDim.new(1, 0)

local activePillStroke = Instance.new("UIStroke", ActivePill)

activePillStroke.Color = COLORS.green

activePillStroke.Thickness = 1

activePillStroke.Transparency = 0.4

local ActiveDot = Instance.new("Frame")

ActiveDot.Size = UDim2.fromOffset(8, 8)

ActiveDot.Position = UDim2.fromOffset(10, 10)

ActiveDot.BackgroundColor3 = Color3.fromRGB(45, 245, 145)

ActiveDot.BorderSizePixel = 0

ActiveDot.Parent = ActivePill

Instance.new("UICorner", ActiveDot).CornerRadius = UDim.new(1, 0)

local ActiveText = Instance.new("TextLabel")

ActiveText.Size = UDim2.new(1, -25, 1, 0)

ActiveText.Position = UDim2.fromOffset(23, 0)

ActiveText.BackgroundTransparency = 1

ActiveText.Text = "Script Ativo"

ActiveText.TextColor3 = COLORS.white

ActiveText.Font = Enum.Font.GothamBold

ActiveText.TextSize = 10

ActiveText.Parent = ActivePill

local Min = Instance.new("TextButton")

Min.Size = UDim2.fromOffset(32, 32)

Min.Position = UDim2.new(1, -78, 0, 16)

Min.BackgroundColor3 = COLORS.purple

Min.Text = "–"

Min.TextColor3 = COLORS.white

Min.Font = Enum.Font.GothamBold

Min.TextSize = 20

Min.Parent = Header

Instance.new("UICorner", Min).CornerRadius = UDim.new(0, 9)

local minStroke = Instance.new("UIStroke", Min)

minStroke.Color = COLORS.accentGlow

minStroke.Transparency = 0.45

local Close = Instance.new("TextButton")

Close.Size = UDim2.fromOffset(32, 32)

Close.Position = UDim2.new(1, -40, 0, 16)

Close.BackgroundColor3 = COLORS.red

Close.Text = "X"

Close.TextColor3 = COLORS.white

Close.Font = Enum.Font.GothamBold

Close.TextSize = 14

Close.Parent = Header

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 9)

local closeStroke = Instance.new("UIStroke", Close)

closeStroke.Color = Color3.fromRGB(255, 140, 150)

closeStroke.Transparency = 0.45

local Sidebar, Content

local minimized = false

local expandedSize = UDim2.fromOffset(760, 510)

local expandedPosition = Main.Position

local function tween(object, props, duration)

TweenService:Create(

object,

TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),

props

):Play()

end

local function syncShadow()

if minimized then

MainShadow.Size = UDim2.fromOffset(68, 68)

MainShadow.Position = UDim2.new(

Main.Position.X.Scale,

Main.Position.X.Offset - 4,

Main.Position.Y.Scale,

Main.Position.Y.Offset - 4

)

else

MainShadow.Size = UDim2.fromOffset(expandedSize.X.Offset + 12, expandedSize.Y.Offset + 12)

MainShadow.Position = UDim2.new(

Main.Position.X.Scale,

Main.Position.X.Offset - 6,

Main.Position.Y.Scale,

Main.Position.Y.Offset - 6

)

end

end

local StatusLabel

local function setStatus(message)

if StatusLabel and StatusLabel.Parent then

StatusLabel.Text = "  ●  STATUS  •  " .. tostring(message)

end

end

local function MinimizePanel()

minimized = not minimized

if minimized then

expandedPosition = Main.Position

Sidebar.Visible = false

Content.Visible = false

Title.Visible = false

BrandMark.Visible = false

BrandSubtitle.Visible = false

ActivePill.Visible = false

Close.Visible = false

HeaderDivider.Visible = false

Min.Position = UDim2.fromOffset(13, 13)

Min.Size = UDim2.fromOffset(34, 34)

Min.Text = "↗"

tween(Main, {Size = UDim2.fromOffset(60, 60)}, 0.22)

tween(Header, {Size = UDim2.fromOffset(60, 60)}, 0.22)

tween(MainShadow, {

Size = UDim2.fromOffset(68, 68),

Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset - 4, Main.Position.Y.Scale, Main.Position.Y.Offset - 4)

}, 0.22)

else

tween(Main, {Size = expandedSize}, 0.22)

tween(Header, {Size = UDim2.new(1, 0, 0, 64)}, 0.22)

Main.Position = expandedPosition

tween(MainShadow, {

Size = UDim2.fromOffset(expandedSize.X.Offset + 12, expandedSize.Y.Offset + 12),

Position = UDim2.new(expandedPosition.X.Scale, expandedPosition.X.Offset - 6, expandedPosition.Y.Scale, expandedPosition.Y.Offset - 6)

}, 0.22)

Min.Position = UDim2.new(1, -78, 0, 16)

Min.Size = UDim2.fromOffset(32, 32)

Min.Text = "–"

Sidebar.Visible = true

Content.Visible = true

Title.Visible = true

BrandMark.Visible = true

BrandSubtitle.Visible = true

ActivePill.Visible = true

Close.Visible = true

HeaderDivider.Visible = true

end

end

Sidebar = Instance.new("ScrollingFrame")

Sidebar.ScrollBarThickness = 3

Sidebar.ScrollBarImageColor3 = COLORS.purple

Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)

Sidebar.Size = UDim2.new(0, 176, 1, -86)

Sidebar.Position = UDim2.fromOffset(10, 74)

Sidebar.BackgroundColor3 = COLORS.panel

Sidebar.BorderSizePixel = 0

Sidebar.Parent = Main

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local sidebarStroke = Instance.new("UIStroke", Sidebar)

sidebarStroke.Color = COLORS.line

sidebarStroke.Transparency = 0.35

sidebarStroke.Thickness = 1.2

local sidebarPadding = Instance.new("UIPadding")

sidebarPadding.PaddingTop = UDim.new(0, 6)

sidebarPadding.PaddingBottom = UDim.new(0, 6)

sidebarPadding.Parent = Sidebar

local tabLayout = Instance.new("UIListLayout")

tabLayout.Padding = UDim.new(0, 6)

tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

tabLayout.Parent = Sidebar

tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()

Sidebar.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 14)

end)

Content = Instance.new("ScrollingFrame")

Content.Size = UDim2.new(1, -200, 1, -86)

Content.Position = UDim2.fromOffset(192, 74)

Content.BackgroundColor3 = COLORS.panel

Content.BorderSizePixel = 0

Content.ScrollBarThickness = 4

Content.ScrollBarImageColor3 = COLORS.purple

Content.CanvasSize = UDim2.new(0, 0, 0, 0)

Content.Parent = Main

Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 12)

local contentStroke = Instance.new("UIStroke", Content)

contentStroke.Color = COLORS.line

contentStroke.Transparency = 0.35

contentStroke.Thickness = 1.2

local contentLayout = Instance.new("UIListLayout")

contentLayout.Padding = UDim.new(0, 8)

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

StatusLabel.Size = UDim2.new(1, -4, 0, 32)

StatusLabel.BackgroundColor3 = COLORS.card

StatusLabel.BorderSizePixel = 0

StatusLabel.Text = "  ●  STATUS  •  pronto"

StatusLabel.TextColor3 = COLORS.white

StatusLabel.TextSize = 11

StatusLabel.Font = Enum.Font.GothamBold

StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

StatusLabel.Parent = Content

Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 9)

local statusStroke = Instance.new("UIStroke", StatusLabel)

statusStroke.Color = COLORS.line

statusStroke.Transparency = 0.3

statusStroke.Thickness = 1.2

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

label.TextColor3 = COLORS.muted

label.TextSize = 13

label.Font = Enum.Font.Gotham

label.TextWrapped = true

label.TextXAlignment = Enum.TextXAlignment.Left

label.Parent = activeContainer

return label

end

local function makeButton(text, callback, color)

local isCustomColor = color ~= nil

local baseColor = color or COLORS.row

local button = Instance.new("TextButton")

button.Size = UDim2.new(1, -4, 0, 40)

button.BackgroundColor3 = baseColor

button.Text = text

button.TextColor3 = COLORS.white

button.TextSize = 13

button.Font = Enum.Font.GothamBold

button.TextWrapped = true

button.AutoButtonColor = false

button.Parent = activeContainer

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

local btnGrad = Instance.new("UIGradient")

btnGrad.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),

ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 205, 225))

})

btnGrad.Rotation = 90

btnGrad.Parent = button

local buttonStroke = Instance.new("UIStroke", button)

buttonStroke.Color = isCustomColor and COLORS.white or COLORS.line

buttonStroke.Transparency = 0.4

buttonStroke.Thickness = 1.2

if not isCustomColor then

registerThemeUpdater(function()

if button and button.Parent then

button.BackgroundColor3 = COLORS.row

buttonStroke.Color = COLORS.line

end

end)

end

button.MouseEnter:Connect(function()

tween(buttonStroke, {Transparency = 0.05}, 0.15)

if not isCustomColor then

tween(button, {BackgroundColor3 = COLORS.card}, 0.15)

end

end)

button.MouseLeave:Connect(function()

tween(buttonStroke, {Transparency = 0.4}, 0.15)

if not isCustomColor then

tween(button, {BackgroundColor3 = COLORS.row}, 0.15)

end

end)

button.MouseButton1Click:Connect(function()

if callback then callback() end

end)

return button

end

local function makeToggle(name, callback, initial)

if states[name] == nil then

states[name] = initial or false

end

local row = Instance.new("Frame")

row.Size = UDim2.new(1, -4, 0, 52)

row.BackgroundColor3 = COLORS.card

row.BorderSizePixel = 0

row.Parent = activeContainer

Instance.new("UICorner", row).CornerRadius = UDim.new(0, 11)

local rowGrad = Instance.new("UIGradient")

rowGrad.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),

ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 220, 235))

})

rowGrad.Rotation = 90

rowGrad.Parent = row

local rowStroke = Instance.new("UIStroke", row)

rowStroke.Color = states[name] and COLORS.purple or COLORS.line

rowStroke.Transparency = states[name] and 0.15 or 0.55

rowStroke.Thickness = 1.2

local label = Instance.new("TextLabel")

label.Size = UDim2.new(1, -78, 1, 0)

label.Position = UDim2.fromOffset(12, 0)

label.BackgroundTransparency = 1

label.Text = name

label.TextColor3 = COLORS.white

label.TextSize = 13

label.Font = Enum.Font.GothamSemibold

label.TextXAlignment = Enum.TextXAlignment.Left

label.Parent = row

local switch = Instance.new("TextButton")

switch.Size = UDim2.fromOffset(50, 26)

switch.Position = UDim2.new(1, -60, 0.5, -13)

switch.Text = ""

switch.AutoButtonColor = false

switch.Parent = row

Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

local switchStroke = Instance.new("UIStroke", switch)

switchStroke.Color = COLORS.white

switchStroke.Transparency = 0.75

local dot = Instance.new("Frame")

dot.Size = UDim2.fromOffset(20, 20)

dot.Position = UDim2.fromOffset(3, 3)

dot.BackgroundColor3 = COLORS.white

dot.Parent = switch

Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local function update()

tween(switch, {

BackgroundColor3 = states[name] and COLORS.green or COLORS.gray

}, 0.16)

tween(dot, {

Position = states[name] and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3)

}, 0.16)

tween(rowStroke, {

Color = states[name] and COLORS.purple or COLORS.line,

Transparency = states[name] and 0.15 or 0.55

}, 0.16)

end

registerThemeUpdater(function()

if row and row.Parent then

row.BackgroundColor3 = COLORS.card

rowStroke.Color = states[name] and COLORS.purple or COLORS.line

end

end)

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

header.Size = UDim2.new(1, -4, 0, 42)

header.BackgroundColor3 = COLORS.header

header.TextColor3 = COLORS.white

header.TextSize = 13

header.Font = Enum.Font.GothamBold

header.TextXAlignment = Enum.TextXAlignment.Left

header.Text = (initiallyOpen and "  ▼  " or "  ▶  ") .. title

header.AutoButtonColor = false

header.Parent = Content

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local sectionStroke = Instance.new("UIStroke", header)

sectionStroke.Color = COLORS.line

sectionStroke.Transparency = 0.25

sectionStroke.Thickness = 1.2

registerThemeUpdater(function()

if header and header.Parent then

header.BackgroundColor3 = COLORS.header

sectionStroke.Color = COLORS.line

end

end)

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

padding.PaddingTop = UDim.new(0, 4)

padding.PaddingBottom = UDim.new(0, 6)

padding.Parent = body

header.MouseButton1Click:Connect(function()

local open = not body.Visible

body.Visible = open

body.AutomaticSize = open and Enum.AutomaticSize.Y or Enum.AutomaticSize.None

body.Size = UDim2.new(1, -4, 0, 0)

header.Text = (open and "  ▼  " or "  ▶  ") .. title

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

button.Text = (isSelected and "  ✓   " or "  ○   ") .. labelText

button.TextColor3 = COLORS.white

button.TextSize = 12

button.Font = Enum.Font.GothamSemibold

button.TextXAlignment = Enum.TextXAlignment.Left

button.TextTruncate = Enum.TextTruncate.AtEnd

button.Parent = activeContainer

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local optStroke = Instance.new("UIStroke", button)

optStroke.Color = isSelected and COLORS.white or COLORS.line

optStroke.Transparency = 0.55

button.MouseButton1Click:Connect(function()

if callback then callback() end

end)

return button

end

local function makeSlider(labelText, minValue, maxValue, initialValue, callback)

local holder = Instance.new("Frame")

holder.Size = UDim2.new(1, -4, 0, 64)

holder.BackgroundColor3 = COLORS.card

holder.BorderSizePixel = 0

holder.Parent = activeContainer

Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 10)

local holderStroke = Instance.new("UIStroke", holder)

holderStroke.Color = COLORS.line

holderStroke.Transparency = 0.5

local title = Instance.new("TextLabel")

title.Size = UDim2.new(1, -24, 0, 24)

title.Position = UDim2.fromOffset(12, 4)

title.BackgroundTransparency = 1

title.TextColor3 = COLORS.white

title.Font = Enum.Font.GothamSemibold

title.TextSize = 12

title.TextXAlignment = Enum.TextXAlignment.Left

title.Text = labelText .. ": " .. tostring(initialValue)

title.Parent = holder

local bar = Instance.new("Frame")

bar.Size = UDim2.new(1, -24, 0, 8)

bar.Position = UDim2.fromOffset(12, 40)

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

knob.Size = UDim2.fromOffset(18, 18)

knob.AnchorPoint = Vector2.new(0.5, 0.5)

knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)

knob.BackgroundColor3 = COLORS.white

knob.Parent = bar

Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local knobStroke = Instance.new("UIStroke", knob)

knobStroke.Color = COLORS.purple

knobStroke.Thickness = 2

registerThemeUpdater(function()

if holder and holder.Parent then

holder.BackgroundColor3 = COLORS.card

holderStroke.Color = COLORS.line

fill.BackgroundColor3 = COLORS.purple

knobStroke.Color = COLORS.purple

end

end)

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

button.Text = (chosen and "  ✓   " or "  ○   ")

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

dialog.Size = UDim2.fromOffset(290, 126)

dialog.AnchorPoint = Vector2.new(0.5, 0.5)

dialog.Position = UDim2.fromScale(0.5, 0.5)

dialog.BackgroundColor3 = COLORS.panel

dialog.ZIndex = 30

dialog.Parent = Screen

Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 12)

local dStroke = Instance.new("UIStroke", dialog)

dStroke.Color = COLORS.purple

dStroke.Thickness = 2

local msg = Instance.new("TextLabel")

msg.Size = UDim2.new(1, -20, 0, 58)

msg.Position = UDim2.fromOffset(10, 6)

msg.BackgroundTransparency = 1

msg.Text = "Confirmar ida até " .. target.DisplayName .. "?"

msg.TextColor3 = COLORS.white

msg.TextWrapped = true

msg.Font = Enum.Font.GothamSemibold

msg.TextSize = 13

msg.ZIndex = 31

msg.Parent = dialog

local yes = Instance.new("TextButton")

yes.Size = UDim2.new(0.44, 0, 0, 36)

yes.Position = UDim2.new(0.04, 0, 1, -46)

yes.Text = "Confirmar"

yes.BackgroundColor3 = COLORS.green

yes.TextColor3 = COLORS.white

yes.Font = Enum.Font.GothamBold

yes.TextSize = 12

yes.ZIndex = 31

yes.Parent = dialog

Instance.new("UICorner", yes).CornerRadius = UDim.new(0, 8)

local no = Instance.new("TextButton")

no.Size = UDim2.new(0.44, 0, 0, 36)

no.Position = UDim2.new(0.52, 0, 1, -46)

no.Text = "Cancelar"

no.BackgroundColor3 = COLORS.red

no.TextColor3 = COLORS.white

no.Font = Enum.Font.GothamBold

no.TextSize = 12

no.ZIndex = 31

no.Parent = dialog

Instance.new("UICorner", no).CornerRadius = UDim.new(0, 8)

yes.MouseButton1Click:Connect(function()

teleportToPlayer(target)

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

local player = getPlayerFromModel(model)

if selectedAimTarget == "NPCs" then

return player == nil

elseif selectedAimTarget == "Jogadores" then

return player ~= nil

elseif selectedAimTarget == "Todos" then

return true

end

return false

end

local function getAttackableTargets()

local targets = {}

if selectedAimTarget == "Jogadores" or selectedAimTarget == "Todos" then

for _, player in ipairs(Players:GetPlayers()) do

if player ~= LocalPlayer and player.Character then

local hum = player.Character:FindFirstChildOfClass("Humanoid")

local root = getRoot(player.Character)

if hum and hum.Health > 0 and root then

table.insert(targets, {

model = player.Character,

humanoid = hum,

root = root,

name = player.DisplayName

})

end

end

end

end

if selectedAimTarget == "NPCs" or selectedAimTarget == "Todos" then

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

option.Text = (selected and "  ✓   " or "  ○   ") .. target.name

option.Parent = container

Instance.new("UICorner", option).CornerRadius = UDim.new(0, 7)

option.MouseButton1Click:Connect(function()

selectedAttackTargets[target.model] = not selectedAttackTargets[target.model]

option.BackgroundColor3 =

selectedAttackTargets[target.model] and COLORS.green or COLORS.row

option.Text = (selectedAttackTargets[target.model] and "  ✓   " or "  ○   ")

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

for _, tool in ipairs(tools) do

if tool.Parent == character then

equipped = tool

break

end

end

if not equipped then

local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

if backpack then

for _, tool in ipairs(backpack:GetChildren()) do

if tool:IsA("Tool") then

pcall(function()

humanoid:EquipTool(tool)

end)

equipped = tool

break

end

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

local skillCooldown = 1.35

local virtualInputManager

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

if not autoSkillsEnabled then return end

if not selectedFruitName then

setStatus("Selecione e confirme sua fruta na aba Combate.")

return

end

local now = os.clock()

if now - lastSkillUse < skillCooldown then return end

local fruitTool = getEquippedFruitTool(character)

if not fruitTool then

return

end

local humanoid = character:FindFirstChildOfClass("Humanoid")

if humanoid and fruitTool.Parent ~= character then

pcall(function()

humanoid:EquipTool(fruitTool)

end)

return

end

if fruitTool.Parent ~= character then

return

end

skillKeyIndex += 1

if skillKeyIndex > #skillKeys then

skillKeyIndex = 1

end

local keyCode = skillKeys[skillKeyIndex]

lastSkillUse = now

if sendSkillKey(keyCode) then

setStatus("Tentando habilidade de " .. selectedFruitName .. ": " .. keyCode.Name)

else

pcall(function()

fruitTool:Activate()

end)

setStatus("Ativação direta da fruta tentada.")

end

end

local function activateCombatTools(character, humanoid)

local now = os.clock()

if autoSkillsEnabled then

activateFruitSkills(character)

end

if now - lastToolUse < 0.45 then return end

lastToolUse = now

local tool = equipCombatTool(character, humanoid)

if tool and tool.Parent == character then

pcall(function()

tool:Activate()

end)

end

end

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

local function isSkillRecoveryActive()

-- O cliente não recebe o cooldown real de cada habilidade.
-- Este intervalo acompanha o tempo de recarga usado pelo próprio painel.
return autoSkillsEnabled
and lastSkillUse > 0
and (os.clock() - lastSkillUse) < skillCooldown

end

local function performCombatDodge(humanoid, root, targetRoot, forceDodge)

if not humanoid or not root or not targetRoot then return end

local now = os.clock()

local dodgeInterval = forceDodge and 0.72 or 1.05

if now - lastDodge < dodgeInterval then return end

lastDodge = now

dodgeSide = -dodgeSide

local away = root.Position - targetRoot.Position

if away.Magnitude < 0.01 then
away = -targetRoot.CFrame.LookVector
else
away = away.Unit
end

local right = targetRoot.CFrame.RightVector

-- Recuo diagonal: sai da linha frontal do alvo e evita permanecer colado.
local dodgeDistance = forceDodge and 12 or 8
local sideDistance = forceDodge and 9 or 6

local dodgePosition = root.Position
+ away * dodgeDistance
+ right * (dodgeSide * sideDistance)

-- Mantém a altura atual para não provocar saltos verticais desnecessários.
dodgePosition = Vector3.new(
dodgePosition.X,
root.Position.Y,
dodgePosition.Z
)

humanoid:MoveTo(dodgePosition)

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

while (autoAttackEnabled or autoHakiEnabled or autoSkillsEnabled)

and Screen.Parent do

local character = getCharacter()

local root = getRoot(character)

local hum = character and character:FindFirstChildOfClass("Humanoid")

if not root or not hum or hum.Health <= 0 then

combatFollowTarget = nil

task.wait(0.5)

continue

end

hum.WalkSpeed = getAdjustedWalkSpeed()

local selectedTarget = getCurrentSelectedTarget()

if selectedTarget then

local targetRoot = selectedTarget.root

combatFollowTarget = selectedTarget

local distance = (root.Position - targetRoot.Position).Magnitude

handleFollowJump(hum, root, targetRoot)

-- Mantém o ataque básico ativo mesmo enquanto a fruta está em recarga.
if distance <= 16 and (autoAttackEnabled or autoHakiEnabled or autoSkillsEnabled) then
activateCombatTools(character, hum)
end

local recovering = isSkillRecoveryActive()

-- Faixa de combate: aproxima, ataca à distância curta e recua durante a recarga.
if recovering and distance < 18 then

if not flyEnabled then
performCombatDodge(hum, root, targetRoot, true)
end

elseif distance > 13 then

local approachPosition = targetRoot.Position
- targetRoot.CFrame.LookVector * 9

if not flyEnabled then
hum:MoveTo(approachPosition)
end

else

if distance < 7 then

if not flyEnabled then
performCombatDodge(hum, root, targetRoot, false)
end

elseif distance > 11 and not flyEnabled then

hum:MoveTo(targetRoot.Position - targetRoot.CFrame.LookVector * 9)

end

end

else

combatFollowTarget = nil

if not flyEnabled then

hum:MoveTo(root.Position)

end

end

task.wait(0.12)

end

combatFollowTarget = nil

attackLoopRunning = false

end)

end

local navButtons = {}

local function applyPalette(name)

local theme = THEMES[name]

if not theme then return end

currentThemeName = name

COLORS.bg = theme.bg

COLORS.bgTop = theme.bgTop

COLORS.panel = theme.panel

COLORS.card = theme.card

COLORS.row = theme.row

COLORS.purple = theme.accent

COLORS.accentGlow = theme.accentGlow

COLORS.line = theme.line

COLORS.header = theme.header

Main.BackgroundColor3 = COLORS.bg

mainGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.bgTop),

ColorSequenceKeypoint.new(0.45, COLORS.bg),

ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 5, 12))

})

stroke.Color = COLORS.purple

strokeGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.accentGlow),

ColorSequenceKeypoint.new(0.5, COLORS.purple),

ColorSequenceKeypoint.new(1, COLORS.line)

})

shadowStroke.Color = COLORS.purple

TopHighlight.BackgroundColor3 = COLORS.accentGlow

Header.BackgroundColor3 = COLORS.header

headerGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.card),

ColorSequenceKeypoint.new(1, COLORS.header)

})

HeaderDivider.BackgroundColor3 = COLORS.line

BrandMark.BackgroundColor3 = COLORS.card

brandGradient.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, COLORS.purple),

ColorSequenceKeypoint.new(1, COLORS.header)

})

brandStroke.Color = COLORS.accentGlow

BrandSubtitle.TextColor3 = COLORS.accentGlow

Min.BackgroundColor3 = COLORS.purple

minStroke.Color = COLORS.accentGlow

Sidebar.BackgroundColor3 = COLORS.panel

Sidebar.ScrollBarImageColor3 = COLORS.purple

sidebarStroke.Color = COLORS.line

Content.BackgroundColor3 = COLORS.panel

Content.ScrollBarImageColor3 = COLORS.purple

contentStroke.Color = COLORS.line

StatusLabel.BackgroundColor3 = COLORS.card

statusStroke.Color = COLORS.line

FOVStroke.Color = COLORS.purple

for _, entry in pairs(navButtons) do

if entry.isSelected then

entry.button.BackgroundColor3 = COLORS.purple

entry.stroke.Color = COLORS.accentGlow

entry.icon.TextColor3 = COLORS.white

else

entry.button.BackgroundColor3 = COLORS.row

entry.stroke.Color = COLORS.line

entry.icon.TextColor3 = COLORS.muted

end

end

for _, updater in ipairs(themeUpdaters) do

pcall(updater)

end

setStatus("Tema " .. name .. " aplicado com sucesso.")

end

local function showCategory(category)

activeContainer = Content

table.clear(themeUpdaters)

clearContent()

Content.CanvasPosition = Vector2.new(0, 0)

if category == "Início" then

beginSection("Painel e status")

makeLabel("BLOX F' - TALES 4.2", 36)

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

makeLabel("Os recursos locais atuam no cliente. Ações internas do jogo dependem dos sistemas oficiais da experiência.", 58)

endSection()

elseif category == "Jogador" then

beginSection("Movimentação")

makeSpeedControl()

makeSlider("Speed geral", 0, 500, globalSpeed, function(value)

globalSpeed = value

local character = getCharacter()

local hum = character and character:FindFirstChildOfClass("Humanoid")

if hum then

hum.WalkSpeed = getAdjustedWalkSpeed()

end

setStatus("Speed geral: " .. value .. "%")

end)

makeToggle("Pulo infinito", function(on)

infiniteJump = on

setStatus(on and "Pulo infinito ligado" or "Pulo infinito desligado")

end)

makeToggle("Fly / Voar", function(on)

flyEnabled = on

if not on then

followFlyActive = false

end

setStatus(on and "Fly ligado" or "Fly desligado")

end)

makeSlider("Velocidade do Fly", 10, 200, flySpeed, function(value)

flySpeed = value

setStatus("Velocidade do Fly: " .. flySpeed)

end)

makeLabel("O Speed geral também multiplica a velocidade do Fly. Quando estiver em zero, o Fly usa somente a velocidade configurada acima.", 54)

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

option.Text = (chosen and "  ✓   " or "  ○   ") .. name

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

box.Size = UDim2.new(1, -4, 0, 38)

box.BackgroundColor3 = COLORS.card

box.TextColor3 = COLORS.white

box.PlaceholderText = "Coordenada " .. axis

box.Text = ""

box.ClearTextOnFocus = false

box.Font = Enum.Font.GothamSemibold

box.TextSize = 13

box.Parent = activeContainer

Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local boxStroke = Instance.new("UIStroke", box)

boxStroke.Color = COLORS.line

boxStroke.Transparency = 0.5

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

makeLabel("Ajuste a velocidade com que seu personagem vai correr até o jogador. O Speed geral também multiplica esse valor.", 48)

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

makeLabel("Os localizadores procuram objetos replicados no Workspace com nomes relacionados a frutas e baús.", 48)

endSection()

elseif category == "Combate" then

beginSection("Mira e seleção de alvos", false)

makeToggle("Aim Assist", function(on)

aimAssistEnabled = on

setStatus(on and "Aim Assist ativado" or "Aim Assist desativado")

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

typeButton = makeButton("  ▶  Tipo de alvo: " .. selectedAimTarget, function()

targetTypeDropdownOpen = not targetTypeDropdownOpen

targetTypeDropdown.Visible = targetTypeDropdownOpen

typeButton.Text = (targetTypeDropdownOpen and "  ▼  " or "  ▶  ")

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

for _, targetType in ipairs({"NPCs", "Jogadores", "Todos"}) do

local option = Instance.new("TextButton")

option.Size = UDim2.new(1, 0, 0, 34)

option.BackgroundColor3 = selectedAimTarget == targetType and COLORS.green or COLORS.row

option.Text = targetType

option.TextColor3 = COLORS.white

option.Font = Enum.Font.GothamSemibold

option.TextSize = 12

option.Parent = targetTypeDropdown

Instance.new("UICorner", option).CornerRadius = UDim.new(0, 8)

option.MouseButton1Click:Connect(function()

selectedAimTarget = targetType

typeButton.Text = "  ▶  Tipo de alvo: " .. targetType

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

setStatus("Mira configurada para: " .. targetType)

end)

end

endSection()

beginSection("Ataque, habilidades e Haki", false)

attackButton = makeButton("  ▶  Selecionar alvos para ataque", function()

attackDropdownOpen = not attackDropdownOpen

attackList.Visible = attackDropdownOpen

attackButton.Text = (attackDropdownOpen and "  ▼  " or "  ▶  ")

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

Instance.new("UICorner", attackList).CornerRadius = UDim.new(0, 8)

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

fruitDropdownButton = makeButton("  ▶  Selecione a fruta que você está equipado", function()

fruitDropdownOpen = not fruitDropdownOpen

fruitList.Visible = fruitDropdownOpen

fruitDropdownButton.Text = (fruitDropdownOpen and "  ▼  " or "  ▶  ")

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

Instance.new("UICorner", fruitList).CornerRadius = UDim.new(0, 8)

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

option.Text = (chosen and "  ✓   " or "  ○   ") .. fruitName

end

end

end

for _, fruitName in ipairs(fruitCatalog) do

local option = Instance.new("TextButton")

option.Name = "FruitOption"

option.Size = UDim2.new(1, -4, 0, 32)

option.BackgroundColor3 = pendingFruitName == fruitName and COLORS.green or COLORS.row

option.Text = (pendingFruitName == fruitName and "  ✓   " or "  ○   ") .. fruitName

option.TextColor3 = COLORS.white

option.TextSize = 12

option.Font = Enum.Font.Gotham

option.TextXAlignment = Enum.TextXAlignment.Left

option.Parent = fruitList

Instance.new("UICorner", option).CornerRadius = UDim.new(0, 7)

fruitOptionButtons[fruitName] = option

option.MouseButton1Click:Connect(function()

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

-- O ataque automático também gerencia as habilidades da fruta e a esquiva.
autoSkillsEnabled = on

if on then

startAttackLoop()

end

setStatus(on and "Ataque automático + habilidades + esquiva ligados" or "Ataque automático desligado")

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

beginSection("Catálogo e localização", false)

makeToggle("Detector de frutas", function(on)

fruitFinder = on

refreshObjectHighlights("fruit", on)

setStatus(on and "Detector de frutas ligado" or "Detector de frutas desligado")

end)

makeToggle("Coletar frutas automaticamente", function(on)

autoFruitEnabled = on

setStatus(on and "Coleta automática de frutas ligada" or "Coleta automática de frutas desligada")

end)

makeLabel("Catálogo de frutas: Rocket, Spin, Blade, Spring, Bomb, Smoke, Spike, Flame, Falcon, Ice, Sand, Dark, Diamond, Light, Rubber, Barrier, Ghost, Magma, Quake, Buddha, Love, Spider, Sound, Phoenix, Portal, Rumble, Pain, Blizzard, Gravity, Mammoth, T-Rex, Dough, Shadow, Venom, Control, Spirit, Dragon, Leopard, Kitsune, Gas e Yeti.", 110)

endSection()

elseif category == "Coleta e evolução" then

beginSection("Coleta automática", false)

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

beginSection("Evolução e recompensas", false)

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

beginSection("Personalização e Tema", true)

makeLabel("Escolha a paleta de cores completa do painel:", 26)

local themeOrder = {"Azul", "Violeta", "Vermelha", "Ciano", "Verde"}

local themeButtons = {}

local function refreshThemeButtons()

for tName, btn in pairs(themeButtons) do

if btn and btn.Parent then

local isSelected = (tName == currentThemeName)

btn.Text = (isSelected and "  ✓   Tema " or "  ○   Tema ") .. tName

end

end

end

for _, paletteName in ipairs(themeOrder) do

local themeData = THEMES[paletteName]

local btn = makeButton("  ○   Tema " .. paletteName, function()

applyPalette(paletteName)

refreshThemeButtons()

end, themeData.accent)

btn.TextXAlignment = Enum.TextXAlignment.Left

themeButtons[paletteName] = btn

end

refreshThemeButtons()

makeButton("Recentralizar painel", function()

Main.Position = UDim2.new(

0.5,

-Main.AbsoluteSize.X / 2,

0.5,

-Main.AbsoluteSize.Y / 2

)

syncShadow()

setStatus("Painel recentralizado.")

end)

makeLabel("Ajuste a escala de exibição do painel.", 26)

makeSlider("Tamanho do painel (%)", 80, 115, 100, function(value)

local width = math.floor(760 * value / 100)

local height = math.floor(510 * value / 100)

expandedSize = UDim2.fromOffset(width, height)

if not minimized then

Main.Size = expandedSize

Main.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)

expandedPosition = Main.Position

syncShadow()

end

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

{name = "Início", icon = "⌂"},

{name = "Combate", icon = "⚔"},

{name = "Frutas", icon = "✿"},

{name = "Jogador", icon = "◉"},

{name = "Teletransporte", icon = "⌖"},

{name = "Coleta e evolução", icon = "✧"},

{name = "Visualização", icon = "▣"},

{name = "Configurações", icon = "⚙"}

}

for index, item in ipairs(categories) do

local category = item.name

local isInitial = (category == "Início")

local tab = Instance.new("TextButton")

tab.Name = "Nav_" .. tostring(index)

tab.Size = UDim2.new(1, -14, 0, 44)

tab.LayoutOrder = index

tab.BackgroundColor3 = isInitial and COLORS.purple or COLORS.row

tab.Text = ""

tab.AutoButtonColor = false

tab.Parent = Sidebar

Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 10)

local tabGrad = Instance.new("UIGradient")

tabGrad.Color = ColorSequence.new({

ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),

ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 218, 235))

})

tabGrad.Rotation = 90

tabGrad.Parent = tab

local tabStroke = Instance.new("UIStroke", tab)

tabStroke.Color = isInitial and COLORS.accentGlow or COLORS.line

tabStroke.Transparency = isInitial and 0.1 or 0.75

tabStroke.Thickness = 1.2

local icon = Instance.new("TextLabel")

icon.Size = UDim2.fromOffset(30, 44)

icon.Position = UDim2.fromOffset(8, 0)

icon.BackgroundTransparency = 1

icon.Text = item.icon

icon.TextColor3 = isInitial and COLORS.white or COLORS.muted

icon.Font = Enum.Font.GothamBold

icon.TextSize = 18

icon.Parent = tab

local caption = Instance.new("TextLabel")

caption.Size = UDim2.new(1, -45, 1, 0)

caption.Position = UDim2.fromOffset(40, 0)

caption.BackgroundTransparency = 1

caption.Text = category

caption.TextColor3 = COLORS.white

caption.Font = Enum.Font.GothamBold

caption.TextSize = 11

caption.TextXAlignment = Enum.TextXAlignment.Left

caption.TextTruncate = Enum.TextTruncate.AtEnd

caption.Parent = tab

navButtons[category] = {

button = tab,

stroke = tabStroke,

icon = icon,

isSelected = isInitial

}

tab.MouseEnter:Connect(function()

if not navButtons[category].isSelected then

tween(tab, {BackgroundColor3 = COLORS.card}, 0.14)

tween(tabStroke, {Transparency = 0.35}, 0.14)

end

end)

tab.MouseLeave:Connect(function()

if not navButtons[category].isSelected then

tween(tab, {BackgroundColor3 = COLORS.row}, 0.14)

tween(tabStroke, {Transparency = 0.75}, 0.14)

end

end)

tab.MouseButton1Click:Connect(function()

for name, entry in pairs(navButtons) do

local selected = (name == category)

entry.isSelected = selected

tween(entry.button, {

BackgroundColor3 = selected and COLORS.purple or COLORS.row

}, 0.16)

tween(entry.stroke, {

Color = selected and COLORS.accentGlow or COLORS.line,

Transparency = selected and 0.1 or 0.75

}, 0.16)

entry.icon.TextColor3 = selected and COLORS.white or COLORS.muted

end

showCategory(category)

end)

end

Min.MouseButton1Click:Connect(MinimizePanel)

Close.MouseButton1Click:Connect(function()

destroyed = true

autoAttackEnabled = false

autoHakiEnabled = false

autoSkillsEnabled = false

flyEnabled = false

combatFollowTarget = nil

teleportSequence += 1

playerTeleportSequence += 1

for _, connection in ipairs(connections) do

pcall(function()

connection:Disconnect()

end)

end

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

syncShadow()

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

local width = math.max(520, math.min(760, viewport.X - 24))

local height = math.max(390, math.min(510, viewport.Y - 40))

local sideWidth = math.min(176, math.max(145, width * 0.235))

local contentLeft = sideWidth + 16

expandedSize = UDim2.fromOffset(width, height)

Main.Size = expandedSize

Main.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)

expandedPosition = Main.Position

syncShadow()

Sidebar.Size = UDim2.new(0, sideWidth, 1, -86)

Sidebar.Position = UDim2.fromOffset(10, 74)

Content.Position = UDim2.fromOffset(contentLeft, 74)

Content.Size = UDim2.new(1, -(contentLeft + 12), 1, -86)

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

table.insert(connections, RunService.Heartbeat:Connect(function()

if not flyEnabled then

followFlyActive = false

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

local flyCombatGap = isSkillRecoveryActive() and 15 or 10

local followPosition = targetRoot.Position
- targetRoot.CFrame.LookVector * flyCombatGap
+ targetRoot.CFrame.RightVector * (dodgeSide * 3)
+ Vector3.new(0, 2.5, 0)

local offset = followPosition - root.Position

local distance = offset.Magnitude

if distance > 2 then

local direction = offset.Unit

local speed = math.clamp(

distance * 2.2,

adjustedFlySpeed * 0.65,

adjustedFlySpeed * 1.8

)

if distance < 7 then

speed = math.min(speed, adjustedFlySpeed * 0.55)

end

root.AssemblyLinearVelocity = direction * speed

else

root.AssemblyLinearVelocity = Vector3.zero

end

root.AssemblyAngularVelocity = Vector3.zero

hum:ChangeState(Enum.HumanoidStateType.Physics)

handleFollowJump(hum, root, targetRoot)

return

end

followFlyActive = false

local cameraCFrame = currentCamera.CFrame

local look = cameraCFrame.LookVector

local right = cameraCFrame.RightVector

local forwardInput = 0

local sideInput = 0

if UIS.TouchEnabled then

local moveDirection = hum.MoveDirection

local flatLook = Vector3.new(look.X, 0, look.Z)

local flatRight = Vector3.new(right.X, 0, right.Z)

if flatLook.Magnitude > 0.001 then

flatLook = flatLook.Unit

forwardInput = moveDirection:Dot(flatLook)

end

if flatRight.Magnitude > 0.001 then

flatRight = flatRight.Unit

sideInput = moveDirection:Dot(flatRight)

end

else

if UIS:IsKeyDown(Enum.KeyCode.W) then forwardInput += 1 end

if UIS:IsKeyDown(Enum.KeyCode.S) then forwardInput -= 1 end

if UIS:IsKeyDown(Enum.KeyCode.D) then sideInput += 1 end

if UIS:IsKeyDown(Enum.KeyCode.A) then sideInput -= 1 end

end

local direction = look * forwardInput + right * sideInput

if direction.Magnitude > 1 then

direction = direction.Unit

end

root.AssemblyAngularVelocity = Vector3.zero

root.AssemblyLinearVelocity = direction * adjustedFlySpeed

hum:ChangeState(Enum.HumanoidStateType.Physics)

end))

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

if selectedAimTarget == "NPCs" or selectedAimTarget == "Todos" then

for _, item in ipairs(Workspace:GetDescendants()) do

if item:IsA("Model")

and item ~= getCharacter()

and not getPlayerFromModel(item)

and item:FindFirstChildOfClass("Humanoid") then

addCandidate(item)

end

end

end

if selectedAimTarget == "Jogadores" or selectedAimTarget == "Todos" then

for _, player in ipairs(Players:GetPlayers()) do

if player ~= LocalPlayer and player.Character then

addCandidate(player.Character)

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

print("Blox F' - Tales 4.2 carregado.")
