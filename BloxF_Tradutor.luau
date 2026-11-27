--========================================================
-- BLOXF TRANSLATOR 2.0
-- Tradutor de interfaces Roblox - LuaU
--========================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

if not Player then
    warn("[BloxF Translator] Jogador não encontrado.")
    return
end

--========================================================
-- CONFIGURAÇÕES
--========================================================

local CONFIG = {
    MonitorarIntervalo = 2,
    MostrarStatus = true,
    TraduzirPlayerGui = true,
    TraduzirCoreGui = true,
    TraduzirGetHui = true
}

--========================================================
-- DICIONÁRIO
--========================================================

local Traducoes = {
    ["Settings"] = "Configurações",
    ["Setting"] = "Configuração",
    ["Main"] = "Principal",
    ["Home"] = "Início",
    ["Combat"] = "Combate",
    ["Player"] = "Jogador",
    ["Players"] = "Jogadores",
    ["Misc"] = "Diversos",
    ["Visual"] = "Visual",
    ["Visuals"] = "Visuais",
    ["Movement"] = "Movimento",
    ["Teleport"] = "Teletransporte",
    ["Teleports"] = "Teletransportes",
    ["Farming"] = "Farm",
    ["Auto Farm"] = "Farm Automático",
    ["AutoFarm"] = "Farm Automático",
    ["Shop"] = "Loja",
    ["Inventory"] = "Inventário",
    ["Quest"] = "Missão",
    ["Quests"] = "Missões",
    ["Stats"] = "Atributos",
    ["Skills"] = "Habilidades",
    ["Abilities"] = "Poderes",
    ["Weapons"] = "Armas",
    ["Esp"] = "ESP",
    ["Aimbot"] = "Mira Automática",
    ["Aim"] = "Mira",
    ["Target"] = "Alvo",
    ["Targets"] = "Alvos",
    ["Select"] = "Selecionar",
    ["Selected"] = "Selecionado",
    ["Enable"] = "Ativar",
    ["Enabled"] = "Ativado",
    ["Disable"] = "Desativar",
    ["Disabled"] = "Desativado",
    ["On"] = "Ligado",
    ["Off"] = "Desligado",
    ["Start"] = "Iniciar",
    ["Stop"] = "Parar",
    ["Close"] = "Fechar",
    ["Open"] = "Abrir",
    ["Save"] = "Salvar",
    ["Load"] = "Carregar",
    ["Reset"] = "Redefinir",
    ["Search"] = "Pesquisar",
    ["Search..."] = "Pesquisar...",
    ["Speed"] = "Velocidade",
    ["Distance"] = "Distância",
    ["Range"] = "Alcance",
    ["Height"] = "Altura",
    ["Width"] = "Largura",
    ["Size"] = "Tamanho",
    ["Position"] = "Posição",
    ["Mode"] = "Modo",
    ["Normal"] = "Normal",
    ["Fast"] = "Rápido",
    ["Slow"] = "Lento",
    ["Low"] = "Baixo",
    ["Medium"] = "Médio",
    ["High"] = "Alto",
    ["Very High"] = "Muito Alto",
    ["Custom"] = "Personalizado",
    ["Random"] = "Aleatório",
    ["Automatic"] = "Automático",
    ["Manual"] = "Manual",
    ["Refresh"] = "Atualizar",
    ["Update"] = "Atualização",
    ["Information"] = "Informações",
    ["Info"] = "Informações",
    ["Credits"] = "Créditos",
    ["Support"] = "Suporte",
    ["Language"] = "Idioma",
    ["English"] = "Inglês",
    ["Portuguese"] = "Português",
    ["Loading..."] = "Carregando...",
    ["Please wait..."] = "Aguarde...",
    ["Coming Soon"] = "Em breve",
    ["Not Available"] = "Indisponível",
    ["Success"] = "Sucesso",
    ["Failed"] = "Falhou",
    ["Error"] = "Erro",
    ["Warning"] = "Aviso",
    ["Yes"] = "Sim",
    ["No"] = "Não",
    ["Confirm"] = "Confirmar",
    ["Cancel"] = "Cancelar",
    ["Apply"] = "Aplicar",
    ["Back"] = "Voltar",
    ["Next"] = "Próximo",
    ["Previous"] = "Anterior",
    ["Admin"] = "Administrador",
    ["Premium"] = "Premium",
    ["Free"] = "Gratuito",
    ["Auto"] = "Automático",
    ["Farm"] = "Farm",
    ["Enabled"] = "Ativado",
    ["Disabled"] = "Desativado",
    ["Hide"] = "Ocultar",
    ["Show"] = "Mostrar",
    ["Minimize"] = "Minimizar",
    ["Maximize"] = "Maximizar",
    ["Theme"] = "Tema",
    ["Color"] = "Cor",
    ["Transparency"] = "Transparência",
    ["Opacity"] = "Opacidade",
    ["Account"] = "Conta",
    ["Profile"] = "Perfil",
    ["Version"] = "Versão",
    ["Exit"] = "Sair",
}

--========================================================
-- PREPARAÇÃO DO DICIONÁRIO
--========================================================

local ListaTraducoes = {}

for ingles, portugues in pairs(Traducoes) do
    table.insert(ListaTraducoes, {
        Original = ingles,
        Traduzido = portugues
    })
end

table.sort(ListaTraducoes, function(a, b)
    return #a.Original > #b.Original
end)

--========================================================
-- FUNÇÃO DE TRADUÇÃO
--========================================================

local function EscaparPadrao(texto)
    return texto:gsub("([^%w])", "%%%1")
end

local function Traduzir(texto)

    if typeof(texto) ~= "string" then
        return texto
    end

    if texto == "" then
        return texto
    end

    -- Tradução exata.
    if Traducoes[texto] then
        return Traducoes[texto]
    end

    local resultado = texto

    -- Tradução de frases e palavras.
    for _, item in ipairs(ListaTraducoes) do

        local original = item.Original
        local portugues = item.Traduzido

        local padrao = EscaparPadrao(original)

        if original:match("^%w+$") then
            padrao = "%f[%w]" .. padrao .. "%f[%W]"
        end

        resultado = resultado:gsub(
            padrao,
            function()
                return portugues
            end
        )
    end

    return resultado
end

--========================================================
-- CONTROLE DOS ELEMENTOS
--========================================================

local ElementosMonitorados = setmetatable({}, {
    __mode = "k"
})

local Traduzindo = setmetatable({}, {
    __mode = "k"
})

local function ProcessarElemento(objeto)

    if not objeto or not objeto.Parent then
        return
    end

    if not (
        objeto:IsA("TextLabel")
        or objeto:IsA("TextButton")
        or objeto:IsA("TextBox")
    ) then
        return
    end

    if Traduzindo[objeto] then
        return
    end

    local textoOriginal = objeto.Text
    local novoTexto = Traduzir(textoOriginal)

    if novoTexto ~= textoOriginal then

        Traduzindo[objeto] = true

        local sucesso = pcall(function()
            objeto.Text = novoTexto
        end)

        Traduzindo[objeto] = nil

        if sucesso then
            print(
                "[BloxF Translator] " ..
                textoOriginal .. " -> " .. novoTexto
            )
        end
    end

    -- Monitora alterações futuras.
    if not ElementosMonitorados[objeto] then

        ElementosMonitorados[objeto] = true

        objeto:GetPropertyChangedSignal("Text"):Connect(function()

            if Traduzindo[objeto] then
                return
            end

            task.defer(function()
                if objeto.Parent then
                    ProcessarElemento(objeto)
                end
            end)

        end)
    end
end

--========================================================
-- MONITORAMENTO DAS INTERFACES
--========================================================

local ContainersMonitorados = setmetatable({}, {
    __mode = "k"
})

local function MonitorarContainer(container)

    if not container then
        return
    end

    if ContainersMonitorados[container] then
        return
    end

    ContainersMonitorados[container] = true

    -- Elementos existentes.
    for _, objeto in ipairs(container:GetDescendants()) do
        ProcessarElemento(objeto)
    end

    -- Elementos adicionados posteriormente.
    container.DescendantAdded:Connect(function(objeto)

        task.defer(function()
            if objeto and objeto.Parent then
                ProcessarElemento(objeto)
            end
        end)

    end)

end

--========================================================
-- INDICADOR VISUAL
--========================================================

local function CriarIndicador()

    if not CONFIG.MostrarStatus then
        return
    end

    local PlayerGui = Player:WaitForChild("PlayerGui")

    local antigo = PlayerGui:FindFirstChild("BloxFTranslatorStatus")

    if antigo then
        antigo:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")

    ScreenGui.Name = "BloxFTranslatorStatus"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = PlayerGui

    local Frame = Instance.new("Frame")

    Frame.Size = UDim2.fromOffset(190, 42)
    Frame.Position = UDim2.new(1, -205, 0, 15)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")

    Label.Size = UDim2.fromScale(1, 1)
    Label.BackgroundTransparency = 1
    Label.Text = "BloxF Translator: ATIVO"
    Label.TextColor3 = Color3.fromRGB(100, 255, 130)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Frame

    return ScreenGui
end

--========================================================
-- INICIALIZAÇÃO
--========================================================

local function Iniciar()

    local PlayerGui = Player:WaitForChild("PlayerGui")

    if CONFIG.TraduzirPlayerGui then
        MonitorarContainer(PlayerGui)
    end

    if CONFIG.TraduzirCoreGui then
        pcall(function()
            MonitorarContainer(CoreGui)
        end)
    end

    if CONFIG.TraduzirGetHui and typeof(gethui) == "function" then

        pcall(function()
            local interface = gethui()

            if interface then
                MonitorarContainer(interface)
            end
        end)

    end

    CriarIndicador()

    -- Verificação periódica.
    task.spawn(function()

        while task.wait(CONFIG.MonitorarIntervalo) do

            pcall(function()

                if CONFIG.TraduzirPlayerGui then
                    MonitorarContainer(PlayerGui)
                end

                if CONFIG.TraduzirCoreGui then
                    MonitorarContainer(CoreGui)
                end

                if CONFIG.TraduzirGetHui
                and typeof(gethui) == "function" then

                    local interface = gethui()

                    if interface then
                        MonitorarContainer(interface)
                    end

                end

            end)

        end

    end)

    print("====================================")
    print("[BloxF Translator] Inicializado!")
    print("[BloxF Translator] Idioma: Português")
    print("[BloxF Translator] Monitoramento ativo")
    print("====================================")

end

--========================================================
-- EXECUÇÃO
--========================================================

local sucesso, erro = pcall(Iniciar)

if not sucesso then
    warn("[BloxF Translator] Falha: " .. tostring(erro))
end
