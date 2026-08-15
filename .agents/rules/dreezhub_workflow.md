# DreezHub Workflow & Auto-Push Guidelines

Sempre que o usuário solicitar alterações, adições de novos mods ou correções no repositório DreezHub:

1. **Edição e Integridade**:
   - Faça as alterações necessárias com precisão nos arquivos do projeto (como `RespawnHUD.lua`, `AimbotCore.lua`, etc.).
   - Execute testes de integridade e sintaxe do código antes de concluir.

2. **Auto-Push Obrigatório para GitHub**:
   - Após finalizar as modificações e validações locais, execute automaticamente os comandos Git:
     ```bash
     git add <arquivos-alterados>
     git commit -m "<descrição concisa da alteração>"
     git push origin main
     ```
   - Garanta que o push foi concluído com sucesso no repositório remoto `fraudesnaoseinaosei-max/j4rty678`.

3. **Instruções de Teste**:
   - Sempre forneça o comando de execução no Roblox com a chave anti-cache:
     ```lua
     loadstring(game:HttpGet("https://raw.githubusercontent.com/fraudesnaoseinaosei-max/j4rty678/main/RespawnHUD.lua?v=" .. tick()))()
     ```
