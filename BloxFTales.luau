--============================================================
-- BLOX F' - TALES 3.5
-- SCRIPT ÚNICO — INTERFACE E RECURSOS LOCAIS
--============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not Player then
	warn("BLOX F' - TALES: execute em ambiente de jogador.")
	return
end

local Character, Humanoid, Root

local function UpdateCharacter()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	Root = Character:WaitForChild("HumanoidRootPart")
end

UpdateCharacter()

Player.CharacterAdded:Connect(function()
	task.wait(0.5)
	UpdateCharacter()
end)

--============================================================
-- CONFIGURAÇÕES
--============================================================

local Config = {
	WalkSpeed = 16,
	JumpPower = 50,
	FlySpeed = 65,

	AimAssist = false,
	AimDistance = 500,
	AimFOVLimit = true,
	AimTarget = nil,

	FOVEnabled = true,
	FOVSize = 150,

	CombatDistance = 300,
	AutoAttack = false,
	AutoHaki = false,
	AutoSkills = false,

	Fly = false,
	Noclip = false,
	InfiniteJump = false,

	ESPPlayers = false,
	ESPNPCs = false,
	ESPBosses = false,
	ESPFruits = false,
	ESPChests = false,

	AutoFarm = false,
	AutoChest = false,
	AutoFruit = false,
	AutoMission = false,
	AutoEvolution = false,
	AutoRewards = false,

	SelectedFruit = nil,
	SelectedEnemy = nil,
	SelectedMission = nil,
	SelectedPlayer = nil,
	SelectedIsland = nil,
}

--============================================================
-- REMOTES DO JOGO
--============================================================

local Remotes = ReplicatedStorage:FindFirstChild("BloxFTalesRemotes")

local function ServerAction(action, data)
	if not Remotes then
		return false
	end

	local remote = Remotes:FindFirstChild("Action")

	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer(action, data or {})
		return true
	end

	return false
end

--============================================================
-- INTERFACE
--============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "BLOX_F_TALES_35"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(570, 430)
Main.Position = UDim2.new(0.5, -285, 0.5, -215)
Main.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(145, 65, 255)
Stroke.Thickness = 2
Stroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Color3.fromRGB(43, 20, 75)
Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLOX F' - TALES 3.5"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(34, 28)
Minimize.Position = UDim2.new(1, -78, 0, 7)
Minimize.Text = "—"
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 18
Minimize.BackgroundColor3 = Color3.fromRGB(95, 50, 150)
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(34, 28)
Close.Position = UDim2.new(1, -39, 0, 7)
Close.Text = "X"
Close.Font = Enum.Font.GothamBold
Close.TextSize = 15
Close.BackgroundColor3 = Color3.fromRGB(150, 35, 65)
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Parent = Header

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(0, 135, 1, -52)
Tabs.Position = UDim2.fromOffset(8, 48)
Tabs.BackgroundColor3 = Color3.fromRGB(27, 18, 42)
Tabs.BorderSizePixel = 0
Tabs.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = Tabs

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 7)
TabPadding.PaddingLeft = UDim.new(0, 5)
TabPadding.PaddingRight = UDim.new(0, 5)
TabPadding.Parent = Tabs

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -160, 1, -58)
Content.Position = UDim2.fromOffset(150, 50)
Content.BackgroundColor3 = Color3.fromRGB(24, 16, 37)
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 5
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new()
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 7)
ContentLayout.Parent = Content

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 8)
Padding.PaddingLeft = UDim.new(0, 8)
Padding.PaddingRight = UDim.new(0, 8)
Padding.PaddingBottom = UDim.new(0, 8)
Padding.Parent = Content

--============================================================
-- COMPONENTES
--============================================================

local function Label(text)
	local obj = Instance.new("TextLabel")
	obj.Size = UDim2.new(1, -8, 0, 27)
	obj.BackgroundTransparency = 1
	obj.Text = text
	obj.TextColor3 = Color3.fromRGB(210, 190, 240)
	obj.Font = Enum.Font.GothamBold
	obj.TextSize = 13
	obj.TextXAlignment = Enum.TextXAlignment.Left
	obj.Parent = Content
	return obj
end

local function Button(text, callback, parent)
	local obj = Instance.new("TextButton")
	obj.Size = UDim2.new(1, -8, 0, 32)
	obj.BackgroundColor3 = Color3.fromRGB(65, 35, 105)
	obj.TextColor3 = Color3.new(1, 1, 1)
	obj.Text = text
	obj.Font = Enum.Font.Gotham
	obj.TextSize = 12
	obj.Parent = parent or Content

	Instance.new("UICorner", obj).CornerRadius = UDim.new(0, 6)

	obj.MouseButton1Click:Connect(callback)
	return obj
end

local function Toggle(text, initial, callback)
	local enabled = initial == true
	local obj

	obj = Button(text .. ": " .. (enabled and "ATIVADO" or "DESATIVADO"), function()
		enabled = not enabled
		obj.Text = text .. ": " .. (enabled and "ATIVADO" or "DESATIVADO")
		obj.BackgroundColor3 = enabled
			and Color3.fromRGB(105, 50, 170)
			or Color3.fromRGB(65, 35, 105)

		callback(enabled)
	end)

	return obj
end

local function Slider(text, minValue, maxValue, initial, callback)
	Label(text)

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -8, 0, 42)
	holder.BackgroundTransparency = 1
	holder.Parent = Content

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 0, 18)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = Color3.new(1, 1, 1)
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.Parent = holder

	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1, 0, 0, 12)
	bar.Position = UDim2.fromOffset(0, 24)
	bar.Text = ""
	bar.BackgroundColor3 = Color3.fromRGB(55, 40, 75)
	bar.Parent = holder

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(155, 75, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local dragging = false
	local value = initial

	local function SetValue(newValue)
		value = math.clamp(math.floor(newValue), minValue, maxValue)
		local percent = (value - minValue) / (maxValue - minValue)
		fill.Size = UDim2.new(percent, 0, 1, 0)
		valueLabel.Text = text .. ": " .. value
		callback(value)
	end

	local function Update(input)
		local percent = math.clamp(
			(input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
			0,
			1
		)
		SetValue(minValue + (maxValue - minValue) * percent)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Update(input)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			Update(input)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	SetValue(initial)
end

local function ClearContent()
	for _, child in ipairs(Content:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function Catalog(title, items, callback)
	Label(title)

	local expanded = true
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -8, 0, 0)
	container.BackgroundTransparency = 1
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Parent = Content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = container

	local toggleButton = Button("Ocultar catálogo", function()
		expanded = not expanded
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("TextButton") and child ~= toggleButton then
				child.Visible = expanded
			end
		end
		toggleButton.Text = expanded and "Ocultar catálogo" or "Mostrar catálogo"
	end, container)

	local buttons = {}

	for _, item in ipairs(items) do
		local selected = false

		local obj = Button("□  " .. item, function()
			selected = not selected
			obj.Text = (selected and "☑  " or "□  ") .. item
			obj.BackgroundColor3 = selected
				and Color3.fromRGB(105, 55, 165)
				or Color3.fromRGB(65, 35, 105)

			if selected then
				callback(item)
			elseif not selected then
				callback(nil)
			end
		end, container)

		table.insert(buttons, obj)
	end

	return container
end

--============================================================
-- CATÁLOGOS DE FRUTAS
--============================================================

local Fruits = {
	"Foguete (Rocket)", "Giro (Spin)", "Lâmina (Blade)",
	"Mola (Spring)", "Bomba (Bomb)", "Fumaça (Smoke)",
	"Espinho (Spike)", "Chama (Flame)", "Falcão (Falcon)",
	"Gelo (Ice)", "Areia (Sand)", "Escuridão (Dark)",
	"Diamante (Diamond)", "Luz (Light)", "Amor (Love)",
	"Borracha (Rubber)", "Barreira (Barrier)", "Porta (Door)",
	"Terremoto (Quake)", "Buda (Buddha)", "Fio (String)",
	"Som (Sound)", "Fênix (Phoenix)", "Portal (Portal)",
	"Rumble (Rumble)", "Pata (Pain)", "Gravidade (Gravity)",
	"Mamute (Mammoth)", "T-Rex (T-Rex)", "Dragão (Dragon)",
	"Leopardo (Leopard)", "Espírito (Spirit)", "Controle (Control)",
	"Veneno (Venom)", "Sombra (Shadow)", "Alma (Soul)",
	"Kitsune (Kitsune)", "Yeti (Yeti)", "Gás (Gas)",
}

local Islands = {
	"Ilha 1", "Ilha 2", "Ilha 3", "Ilha 4", "Ilha 5",
	"Ilha 6", "Ilha 7", "Ilha 8", "Ilha 9", "Ilha 10",
	"Ilha 11", "Ilha 12", "Mundo 1", "Mundo 2", "Mundo 3",
}

local function GetPlayers()
	local result = {}
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= Player then
			table.insert(result, target.Name)
		end
	end
	return result
end

local function GetNPCs()
	local result = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model")
			and obj:FindFirstChildOfClass("Humanoid")
			and not Players:GetPlayerFromCharacter(obj) then
			table.insert(result, obj.Name)
		end
	end
	return result
end

--============================================================
-- FOV
--============================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(Config.FOVSize * 2, Config.FOVSize * 2)
FOVCircle.Parent = Gui

Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(175, 90, 255)
FOVStroke.Thickness = 2
FOVStroke.Parent = FOVCircle

RunService.RenderStepped:Connect(function()
	if not Camera then return end

	FOVCircle.Position = UDim2.fromOffset(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	FOVCircle.Size = UDim2.fromOffset(
		Config.FOVSize * 2,
		Config.FOVSize * 2
	)

	FOVCircle.Visible = Config.FOVEnabled
end)

--============================================================
-- AIM ASSIST
--============================================================

local function GetAimTarget()
	if Config.AimTarget then
		local selected = Players:FindFirstChild(Config.AimTarget)

		if selected and selected.Character then
			local targetRoot = selected.Character:FindFirstChild("HumanoidRootPart")
			local targetHumanoid = selected.Character:FindFirstChildOfClass("Humanoid")

			if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
				return targetRoot
			end
		end
	end

	local bestTarget
	local bestDistance = Config.AimDistance

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= Player and target.Character then
			local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
			local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")

			if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and Root then
				local distance = (Root.Position - targetRoot.Position).Magnitude
				local screenPoint, visible = Camera:WorldToViewportPoint(targetRoot.Position)

				local center = Vector2.new(
					Camera.ViewportSize.X / 2,
					Camera.ViewportSize.Y / 2
				)

				local screenDistance = (
					Vector2.new(screenPoint.X, screenPoint.Y) - center
				).Magnitude

				local withinFOV = not Config.AimFOVLimit
					or screenDistance <= Config.FOVSize

				if visible and withinFOV and distance < bestDistance then
					bestDistance = distance
					bestTarget = targetRoot
				end
			end
		end
	end

	return bestTarget
end

RunService.RenderStepped:Connect(function()
	if not Config.AimAssist or not Root then return end

	local target = GetAimTarget()

	if target then
		Camera.CFrame = CFrame.new(
			Camera.CFrame.Position,
			target.Position
		)
	end
end)

--============================================================
-- FLY — TECLADO E ANALÓGICO
--============================================================

local FlyVelocity
local FlyGyro
local FlyConnection

local function StopFly()
	Config.Fly = false

	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end

	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity = nil
	end

	if FlyGyro then
		FlyGyro:Destroy()
		FlyGyro = nil
	end

	if Humanoid then
		Humanoid.PlatformStand = false
	end
end

local function StartFly()
	if not Root or not Humanoid then return end

	StopFly()
	Config.Fly = true
	Humanoid.PlatformStand = true

	FlyVelocity = Instance.new("BodyVelocity")
	FlyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	FlyVelocity.Velocity = Vector3.zero
	FlyVelocity.Parent = Root

	FlyGyro = Instance.new("BodyGyro")
	FlyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	FlyGyro.P = 10000
	FlyGyro.CFrame = Camera.CFrame
	FlyGyro.Parent = Root

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not Config.Fly or not Root then return end

		local direction = Humanoid.MoveDirection

		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.new(0, 1, 0)
		end

		if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
			or UIS:IsKeyDown(Enum.KeyCode.C) then
			direction -= Vector3.new(0, 1, 0)
		end

		FlyVelocity.Velocity = direction * Config.FlySpeed
		FlyGyro.CFrame = Camera.CFrame
	end)
end

--============================================================
-- NOCLIP
--============================================================

local NoclipConnection

local function SetNoclip(enabled)
	Config.Noclip = enabled

	if NoclipConnection then
		NoclipConnection:Disconnect()
		NoclipConnection = nil
	end

	if enabled then
		NoclipConnection = RunService.Stepped:Connect(function()
			if not Character then return end

			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
	else
		if Character then
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end

--============================================================
-- INFINITE JUMP
--============================================================

UIS.JumpRequest:Connect(function()
	if Config.InfiniteJump and Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

--============================================================
-- ESP
--============================================================

local ESPObjects = {}

local function ClearESP()
	for _, highlight in pairs(ESPObjects) do
		if highlight then
			highlight:Destroy()
		end
	end

	table.clear(ESPObjects)
end

local function AddESP(obj, color)
	if not obj or ESPObjects[obj] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "BloxFTalesESP"
	highlight.Adornee = obj
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.8
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = Gui

	ESPObjects[obj] = highlight
end

local function RefreshESP()
	ClearESP()

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= Player and target.Character and Config.ESPPlayers then
			AddESP(target.Character, Color3.fromRGB(80, 170, 255))
		end
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if not obj:IsA("Model") then continue end

		local isPlayer = Players:GetPlayerFromCharacter(obj)
		local humanoid = obj:FindFirstChildOfClass("Humanoid")
		local name = string.lower(obj.Name)

		if humanoid and not isPlayer then
			if Config.ESPBosses and string.find(name, "boss") then
				AddESP(obj, Color3.fromRGB(255, 50, 50))
			elseif Config.ESPNPCs then
				AddESP(obj, Color3.fromRGB(255, 190, 70))
			end
		end

		if Config.ESPFruits and string.find(name, "fruit") then
			AddESP(obj, Color3.fromRGB(80, 255, 130))
		end

		if Config.ESPChests and string.find(name, "chest") then
			AddESP(obj, Color3.fromRGB(255, 220, 70))
		end
	end
end

task.spawn(function()
	while Gui.Parent do
		RefreshESP()
		task.wait(2)
	end
end)

--============================================================
-- LOCALIZADOR
--============================================================

local function FindObjects(keyword)
	local found = {}

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if string.find(string.lower(obj.Name), string.lower(keyword)) then
			local part = obj:IsA("BasePart") and obj
				or obj:FindFirstChildWhichIsA("BasePart", true)

			if part then
				table.insert(found, {
					Name = obj.Name,
					Position = part.Position,
					Object = obj,
				})
			end
		end
	end

	return found
end

--============================================================
-- AUTOMAÇÕES
--============================================================

local AutoConnection

local function RunAutomation()
	if AutoConnection then
		AutoConnection:Disconnect()
		AutoConnection = nil
	end

	AutoConnection = RunService.Heartbeat:Connect(function()
		if Config.AutoAttack then
			ServerAction("AutoAttack", {
				Enabled = true,
				Distance = Config.CombatDistance,
			})
		end

		if Config.AutoHaki then
			ServerAction("AutoHaki", {Enabled = true})
		end

		if Config.AutoSkills then
			ServerAction("AutoSkills", {Enabled = true})
		end

		if Config.AutoFarm then
			ServerAction("AutoFarm", {
				Enabled = true,
				Enemy = Config.SelectedEnemy,
				Distance = Config.CombatDistance,
			})
		end

		if Config.AutoChest then
			ServerAction("AutoChest", {Enabled = true})
		end

		if Config.AutoFruit then
			ServerAction("AutoFruit", {
				Enabled = true,
				Fruit = Config.SelectedFruit,
			})
		end

		if Config.AutoMission then
			ServerAction("AutoMission", {
				Enabled = true,
				Mission = Config.SelectedMission,
			})
		end

		if Config.AutoEvolution then
			ServerAction("AutoEvolution", {Enabled = true})
		end

		if Config.AutoRewards then
			ServerAction("AutoRewards", {Enabled = true})
		end
	end)
end

--============================================================
-- ABAS
--============================================================

local TabNames = {
	"Início",
	"Combate",
	"Frutas",
	"Jogador",
	"Teletransporte",
	"Coleta e evolução",
	"Visualização",
	"Configurações",
}

local function BuildTab(name)
	ClearContent()

	if name == "Início" then
		Label("BLOX F' - TALES 3.5")
		Label("Painel de controle")
		Button("Atualizar personagem", UpdateCharacter)

		Button("Mostrar coordenadas X / Y / Z", function()
			if Root then
				local p = Root.Position
				print(string.format(
					"X: %.2f | Y: %.2f | Z: %.2f",
					p.X, p.Y, p.Z
				))
			end
		end)

	elseif name == "Combate" then
		Toggle("Mira assistida (Aim Assist)", Config.AimAssist, function(v)
			Config.AimAssist = v
		end)

		Catalog("Selecionar alvo da mira", GetPlayers(), function(item)
			Config.AimTarget = item
		end)

		Slider("Distância da mira", 50, 2000, Config.AimDistance, function(v)
			Config.AimDistance = v
		end)

		Toggle("Área de acerto visual (FOV)", Config.FOVEnabled, function(v)
			Config.FOVEnabled = v
		end)

		Slider("Tamanho do FOV", 30, 600, Config.FOVSize, function(v)
			Config.FOVSize = v
		end)

		Toggle("Usar FOV como limite da mira", Config.AimFOVLimit, function(v)
			Config.AimFOVLimit = v
		end)

		Slider("Distância de combate", 30, 1500, Config.CombatDistance, function(v)
			Config.CombatDistance = v
		end)

		Toggle("Ataque automático", Config.AutoAttack, function(v)
			Config.AutoAttack = v
			ServerAction("AutoAttack", {Enabled = v})
			RunAutomation()
		end)

		Toggle("Haki automático", Config.AutoHaki, function(v)
			Config.AutoHaki = v
			ServerAction("AutoHaki", {Enabled = v})
			RunAutomation()
		end)

		Toggle("Habilidades automáticas", Config.AutoSkills, function(v)
			Config.AutoSkills = v
			ServerAction("AutoSkills", {Enabled = v})
			RunAutomation()
		end)

	elseif name == "Frutas" then
		Toggle("Localizador de frutas", Config.ESPFruits, function(v)
			Config.ESPFruits = v
		end)

		Catalog("Selecionar fruta para busca automática", Fruits, function(item)
			Config.SelectedFruit = item
		end)

		Toggle("Busca automática da fruta selecionada", Config.AutoFruit, function(v)
			Config.AutoFruit = v
			ServerAction("AutoFruit", {
				Enabled = v,
				Fruit = Config.SelectedFruit,
			})
			RunAutomation()
		end)

		Button("Procurar frutas no mapa", function()
			for _, item in ipairs(FindObjects("fruit")) do
				print(item.Name, item.Position)
			end
		end)

	elseif name == "Jogador" then
		Slider("Velocidade (WalkSpeed)", 16, 500, Config.WalkSpeed, function(v)
			Config.WalkSpeed = v
			if Humanoid then Humanoid.WalkSpeed = v end
		end)

		Slider("Força do pulo", 50, 500, Config.JumpPower, function(v)
			Config.JumpPower = v
			if Humanoid then Humanoid.JumpPower = v end
		end)

		Toggle("Fly", Config.Fly, function(v)
			if v then StartFly() else StopFly() end
		end)

		Slider("Velocidade do Fly", 10, 300, Config.FlySpeed, function(v)
			Config.FlySpeed = v
		end)

		Toggle("Pulo infinito", Config.InfiniteJump, function(v)
			Config.InfiniteJump = v
		end)

		Toggle("Noclip", Config.Noclip, SetNoclip)

	elseif name == "Teletransporte" then
		Label("Teleporte para jogador")

		Catalog("Selecionar jogador", GetPlayers(), function(item)
			Config.SelectedPlayer = item
		end)

		Button("CONFIRMAR TELEPORTE PARA JOGADOR", function()
			if Config.SelectedPlayer then
				ServerAction("TeleportPlayer", {
					PlayerName = Config.SelectedPlayer,
				})
			end
		end)

		Label("Teleporte para ilha, cidade ou mundo")

		Catalog("Selecionar destino", Islands, function(item)
			Config.SelectedIsland = item
		end)

		Button("CONFIRMAR TELEPORTE", function()
			if Config.SelectedIsland then
				ServerAction("TeleportIsland", {
					Island = Config.SelectedIsland,
				})
			end
		end)

		Button("Teletransportar para coordenadas salvas", function()
			ServerAction("TeleportCoordinates", {})
		end)

	elseif name == "Coleta e evolução" then
		Catalog("Selecionar inimigo", GetNPCs(), function(item)
			Config.SelectedEnemy = item
		end)

		Toggle("Coleta automática / Auto Farm", Config.AutoFarm, function(v)
			Config.AutoFarm = v
			ServerAction("AutoFarm", {
				Enabled = v,
				Enemy = Config.SelectedEnemy,
			})
			RunAutomation()
		end)

		Toggle("Coletar baús automaticamente", Config.AutoChest, function(v)
			Config.AutoChest = v
			ServerAction("AutoChest", {Enabled = v})
			RunAutomation()
		end)

		Catalog("Selecionar missão", {
			"Missão 1", "Missão 2", "Missão 3",
			"Missão 4", "Missão 5",
		}, function(item)
			Config.SelectedMission = item
		end)

		Toggle("Missões automáticas", Config.AutoMission, function(v)
			Config.AutoMission = v
			ServerAction("AutoMission", {
				Enabled = v,
				Mission = Config.SelectedMission,
			})
			RunAutomation()
		end)

		Toggle("Evolução automática", Config.AutoEvolution, function(v)
			Config.AutoEvolution = v
			ServerAction("AutoEvolution", {Enabled = v})
			RunAutomation()
		end)

		Toggle("Recompensas automáticas", Config.AutoRewards, function(v)
			Config.AutoRewards = v
			ServerAction("AutoRewards", {Enabled = v})
			RunAutomation()
		end)

	elseif name == "Visualização" then
		Toggle("ESP de jogadores", Config.ESPPlayers, function(v)
			Config.ESPPlayers = v
		end)

		Toggle("ESP de NPCs", Config.ESPNPCs, function(v)
			Config.ESPNPCs = v
		end)

		Toggle("ESP de Bosses", Config.ESPBosses, function(v)
			Config.ESPBosses = v
		end)

		Toggle("ESP de frutas", Config.ESPFruits, function(v)
			Config.ESPFruits = v
		end)

		Toggle("ESP de baús", Config.ESPChests, function(v)
			Config.ESPChests = v
		end)

		Button("Atualizar ESP agora", RefreshESP)

	elseif name == "Configurações" then
		Button("Parar todas as automações", function()
			Config.AutoAttack = false
			Config.AutoHaki = false
			Config.AutoSkills = false
			Config.AutoFarm = false
			Config.AutoChest = false
			Config.AutoFruit = false
			Config.AutoMission = false
			Config.AutoEvolution = false
			Config.AutoRewards = false

			ServerAction("StopAll", {})

			if AutoConnection then
				AutoConnection:Disconnect()
				AutoConnection = nil
			end
		end)

		Button("Desativar ESP", function()
			Config.ESPPlayers = false
			Config.ESPNPCs = false
			Config.ESPBosses = false
			Config.ESPFruits = false
			Config.ESPChests = false
			ClearESP()
		end)

		Button("Restaurar velocidade e pulo", function()
			Config.WalkSpeed = 16
			Config.JumpPower = 50

			if Humanoid then
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
			end
		end)

		Button("Desativar Fly e Noclip", function()
			StopFly()
			SetNoclip(false)
		end)

		Button("Fechar painel", function()
			Gui.Enabled = false
		end)
	end
end

--============================================================
-- CRIAÇÃO DAS ABAS
--============================================================

for _, tabName in ipairs(TabNames) do
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(1, 0, 0, 34)
	tab.BackgroundColor3 = Color3.fromRGB(55, 30, 85)
	tab.TextColor3 = Color3.new(1, 1, 1)
	tab.Text = tabName
	tab.Font = Enum.Font.Gotham
	tab.TextSize = 11
	tab.Parent = Tabs

	tab.MouseButton1Click:Connect(function()
		BuildTab(tabName)
	end)
end

BuildTab("Início")

--============================================================
-- ARRASTAR JANELA
--============================================================

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

--============================================================
-- MINIMIZAR / FECHAR
--============================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	Tabs.Visible = not minimized
	Content.Visible = not minimized

	Main.Size = minimized
		and UDim2.fromOffset(570, 42)
		or UDim2.fromOffset(570, 430)
end)

Close.MouseButton1Click:Connect(function()
	StopFly()
	SetNoclip(false)

	if AutoConnection then
		AutoConnection:Disconnect()
	end

	ClearESP()
	Gui:Destroy()
end)

print("[BLOX F' - TALES 3.5] Carregado.")
