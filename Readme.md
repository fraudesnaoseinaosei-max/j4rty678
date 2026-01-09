# 🎮 DreeZy-HUB - Script Multifuncional para Roblox

Um HUD completo e moderno para Roblox com múltiplas funcionalidades integradas, incluindo sistema de respawn, aimbot e ESP de cabeças.

## 🚀 Instalação Rápida

Execute este script no Roblox Executor de sua preferência:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/fraudesnaoseinaosei-max/j4rty678/refs/heads/main/RespawnHUD.lua"))()
```

## ✨ Funcionalidades

### 🔄 Respawn na Posição de Morte
- Salva automaticamente a posição onde você morreu
- Ao renascer, você volta exatamente para onde morreu
- Toggle simples no HUD para ativar/desativar
- Atalho de teclado: `Ctrl + R`

### 🎯 Aimbot
- Mira automaticamente no jogador mais próximo visível
- Ativa com o botão direito do mouse (quando o toggle estiver ativo)
- Suavização configurável do movimento da câmera
- Opção de verificação de time (ignorar aliados)

### 👁️ Head ESP
- Destaca as cabeças dos outros jogadores
- Aumenta o tamanho das cabeças para melhor visibilidade
- Campo de texto para ajustar o tamanho em tempo real
- Efeitos visuais: Transparência, cor vermelha, material Neon

## 📋 Requisitos

- Roblox Executor (Synapse X, Script-Ware, Krnl, etc.)
- Acesso ao jogo no Roblox

## 🎨 Interface

O HUD possui uma interface moderna e intuitiva com:
- **Design arrastável**: Clique e arraste pela barra superior
- **Minimizar/Maximizar**: Botão para economizar espaço na tela
- **Toggles visuais**: Indicadores visuais claros para cada funcionalidade
- **Notificações**: Feedback visual para todas as ações
- **Cores personalizadas**: Tema azul moderno

## 📖 Como Usar

### 1. Respawn na Posição de Morte
1. Execute o script
2. Ative o toggle "Respawn na Posição de Morte" no HUD
3. Quando você morrer, sua posição será salva automaticamente
4. Ao renascer, você voltará para a posição de morte

**Atalho:** `Ctrl + R`

### 2. Aimbot
1. Ative o toggle "Aimbot (Botão Direito)" no HUD
2. Pressione e segure o botão direito do mouse
3. A câmera moverá automaticamente para o jogador mais próximo visível

**Nota:** O aimbot só funciona quando o toggle estiver ativo no HUD.

### 3. Head ESP
1. Ative o toggle "Head ESP" no HUD
2. Digite um número no campo de texto ao lado (ex: 7)
3. Pressione Enter ou clique fora do campo
4. As cabeças dos jogadores serão redimensionadas automaticamente

**Valor padrão:** 5

## ⚙️ Configurações Avançadas

### Aimbot
Você pode personalizar o aimbot editando as variáveis globais antes de executar:

```lua
getgenv().AimbotInput = "RightClick"  -- "RightClick", "LeftClick" ou nome da tecla
getgenv().AimbotEasing = 1            -- Suavidade (0-1, onde 1 é instantâneo)
getgenv().TeamCheck = false           -- true para ignorar aliados
```

### Head ESP
O tamanho da cabeça pode ser ajustado diretamente no HUD através do campo de texto, ou programaticamente:

```lua
_G.HeadSize = 7  -- Tamanho da cabeça (padrão: 5)
```

## 📁 Estrutura do Projeto

```
Scrpt.lua-mult/
├── RespawnHUD.lua      # Interface principal (HUD)
├── RespawnCore.lua     # Lógica de respawn
├── AimbotCore.lua      # Lógica de aimbot
└── HeadESP.lua         # Lógica de ESP de cabeças
```

## 🔧 Módulos

O HUD carrega automaticamente os módulos necessários do GitHub:
- `RespawnCore.lua` - Sistema de respawn
- `AimbotCore.lua` - Sistema de aimbot
- `HeadESP.lua` - Sistema de ESP

Todos os módulos são carregados via HTTP do repositório GitHub.

## ⚠️ Avisos

- Este script é para fins educacionais
- Use com responsabilidade e respeite os termos de serviço do Roblox
- Alguns jogos podem ter detecção anti-cheat
- O uso de scripts pode resultar em banimento da conta

## 🐛 Solução de Problemas

### HUD não aparece
- Verifique se o script foi executado corretamente
- Certifique-se de que está usando um executor compatível
- Verifique a conexão com a internet (para carregar os módulos)

### Módulos não carregam
- Verifique se as URLs no código estão corretas
- Certifique-se de que os arquivos estão no repositório GitHub
- Verifique se o repositório é público

### Aimbot não funciona
- Certifique-se de que o toggle está ativo no HUD
- Verifique se há jogadores visíveis na tela
- O aimbot só funciona quando o botão configurado está pressionado

## 📝 Changelog

### Versão Atual
- ✅ Sistema de respawn na posição de morte
- ✅ Aimbot configurável
- ✅ Head ESP com ajuste de tamanho
- ✅ Interface moderna e arrastável
- ✅ Sistema de notificações
- ✅ Múltiplos toggles independentes

## 👤 Autor

**DreeZy**

## 📄 Licença

Este projeto é de código aberto e está disponível para uso livre.

## 🔗 Links

- [Repositório GitHub](https://github.com/dreezy074-rgb/Scrpt.lua-mult)

---

**⭐ Se este projeto foi útil, considere dar uma estrela no repositório!**
