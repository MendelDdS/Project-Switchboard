# Versões das builds

Cada build nova (os executáveis em `build/`) ganha a versão seguinte e entra no fim deste arquivo, com a data, o
commit de onde saiu (marcado no git com a tag da versão), os sistemas e o que mudou desde a anterior.

**Formato: `0.MENOR.CORREÇÃO-fase`.**
- **MENOR** sobe quando a build traz coisa nova (mecânica, conteúdo, visual, som); a CORREÇÃO volta a 0.
- **CORREÇÃO** sobe quando ela só conserta problemas.
- **Fase**: `alpha` enquanto entram mecânicas e conteúdo (hoje: as noites 3 a 15 sem roteiro e o mistério sem
  fim); `beta` quando tudo estiver no jogo e só restar ajuste e correção; `rc` antes do lançamento; a 1.0 sai sem fase.
- O número fica em `application/config/version` e a fase em `application/config/stage` (`project.godot`); a
  exportação do macOS e a tela inicial e a pausa (`Settings.version_text`) leem dali.

## v0.4.0-alpha — 08/10/2026

Commit `4e515f9` · macOS e Windows

### Novidades
- Cachorros latindo bem longe, das 21h em diante.
- Ambiente melancólico e noir: a luminária esquenta no começo do turno, a pausa abafa o som, o prédio da esquina
  virou apartamentos com varanda e a TV piscando na janela, janelas acendem de madrugada, a chuva muda de força
  durante a noite, nuvens passam pela lua, o arbusto balança em rajadas, o vidro embaça nos cantos e as gotas do
  vidro fazem manchinhas de sombra na mesa.
- Unidade de despacho na mesa no lugar do mapa dobrado: o mapa de papel sob o vidro e as três máquinas na base
  (transmissor, impressora e triturador), com as luzes de emergência e de cartão.
- O despacho aberto é a unidade de perto: a base fixa com as máquinas lado a lado, o cartão menor e livre até a borda
  de baixo, e a ficha não abre nem fecha mais.
- As abas das ferramentas saíram: elas abrem pelos objetos da mesa ou pelas teclas 1 a 4.

### Correções
- O cartão impresso, solto logo abaixo da impressora, caía na trituradora.
- O relógio da mesa ficava por cima da pilha de listas.
