--====================================================
-- BLOXF TRANSLATOR 1.0
-- Tradutor de interfaces Roblox
--====================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

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
    ["Discord"] = "Discord",
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
}

local function Traduzir(texto)
    if typeof(texto) ~= "string" then
        return texto
    end

    local original = texto
    local resultado = texto

    -- Primeiro tenta traduzir a frase inteira.
    if Traducoes[resultado] then
        return Traducoes[resultado]
    end

    -- Depois tenta traduzir palavras conhecidas.
    for ingles, portugues in pairs(Traducoes) do
        if not ingles:find("%s") then
            local padrao = "%f[%w]" .. ingles .. "%f[%W]"

            resultado = resultado:gsub(
                padrao,
                function()
                    return portugues
                end
            )
        end
    end

    return resultado
end

local elementosTraduzidos = setmetatable({}, {
    __mode = "k"
})

local function ProcessarElemento(objeto)
    if not objeto:IsA("TextLabel")
    and not objeto:IsA("TextButton")
    and not objeto:IsA("TextBox") then
        return
    end

    local texto = objeto.Text

    if texto == "" then
        return
    end

    if elementosTraduzidos[objeto] == texto then
        return
    end

    local novoTexto = Traduzir(texto)

    if novoTexto ~= texto then
        objeto.Text = novoTexto
        elementosTraduzidos[objeto] = novoTexto
    else
        elementosTraduzidos[objeto] = texto
    end
end

local function Examinar(container)
    for _, objeto in ipairs(container:GetDescendants()) do
        ProcessarElemento(objeto)
    end

    container.DescendantAdded:Connect(function(objeto)
        task.wait(0.1)
        ProcessarElemento(objeto)
    end)
end

-- Interface do jogador.
local function Iniciar()
    local PlayerGui = Player:WaitForChild("PlayerGui")

    Examinar(PlayerGui)
    Examinar(CoreGui)

    -- Tenta localizar a interface do executor.
    if typeof(gethui) == "function" then
        local sucesso, interface = pcall(gethui)

        if sucesso and interface then
            Examinar(interface)
        end
    end

    -- Verifica periodicamente novos textos.
    task.spawn(function()
        while true do
            task.wait(1.5)

            pcall(function()
                for _, objeto in ipairs(PlayerGui:GetDescendants()) do
                    ProcessarElemento(objeto)
                end

                for _, objeto in ipairs(CoreGui:GetDescendants()) do
                    ProcessarElemento(objeto)
                end

                if typeof(gethui) == "function" then
                    local interface = gethui()

                    if interface then
                        for _, objeto in ipairs(interface:GetDescendants()) do
                            ProcessarElemento(objeto)
                        end
                    end
                end
            end)
        end
    end)
end

local sucesso, erro = pcall(Iniciar)

if sucesso then
    print("[BloxF Translator] Tradutor iniciado!")
else
    warn("[BloxF Translator] Erro: " .. tostring(erro))
end
