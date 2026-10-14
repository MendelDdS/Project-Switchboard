---
name: exportar-build
description: Exportar executáveis do jogo (Windows, macOS, Linux) para testar fora do editor, subir a versão, registrar no VERSOES.md e criar a tag. Use quando o usuário pedir build, exportação ou versão nova.
---

# Exportar (executáveis para testar fora do editor)
- **Toda build nova incrementa a versão** (`0.MENOR.CORREÇÃO-fase`, regras no `VERSOES.md`): antes de exportar, sobe
  `application/config/version` (e, ao mudar de fase, `application/config/stage`) no `project.godot`; depois, uma
  entrada no fim do `VERSOES.md` (versão, data, commit, sistemas, Novidades e Correções) e a tag `v<versão>-<fase>` no
  commit de onde a build saiu. A versão aparece no canto da tela inicial e da pausa (`Settings.version_text`). Os
  campos de versão do preset do macOS ficam vazios (ele usa a do projeto); o `.exe` do Windows mostra a do motor
  (`modify_resources=false`, sem o rcedit).
- Presets em `export_presets.cfg`: Windows, macOS (universal, assinatura ad-hoc, sem notarização) e Linux; saída em
  `build/` (fora do git). Templates do Godot 4.6.2 ficam em `~/Library/Application Support/Godot/export_templates/`.
- `Godot --headless --path . --import` e depois `Godot --headless --path . --export-release "Windows" build/windows/ProjectSwitchboard.exe`
  (idem "macOS" → `build/macos/ProjectSwitchboard.zip`, "Linux" → `build/linux/ProjectSwitchboard.x86_64`).
- **`editor/export/convert_text_resources_to_binary=false`**: a conversão para binário esvaziava todo `PackedStringArray`
  do conteúdo (falas, motivos, quem liga) e o jogo exportado quebrava ao montar a agenda. Não religue sem testar.
- Teste o exportado: `Godot --headless --path . --export-pack "macOS" x.pck` e `Godot --headless --main-pack x.pck --quit-after 600`
  (zero `ERROR` no log). Os testes normais rodam pelo projeto e não pegam problema de exportação.
