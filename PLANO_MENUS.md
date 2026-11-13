# Plano: a interface dos menus

Origem: "não estou gostando muito do que tem hoje" (11/11/2026, `HISTORICO.md` 574 e 575). Capturas de antes, a
960×540: `build/menus/title.png`, `pause.png`, `settings.png`, `report.png`.

**Estado (12/11/2026):** decididos a direção (metal do console), a assinatura e a pergunta antes de perder a noite;
**feitas** a assinatura (seção 3.4) e a pergunta (3.1, ainda no papel de hoje). A tela inicial também já está decidida (3.3).

## 1. O que há hoje

| Tela | Hoje | O que incomoda |
|---|---|---|
| Inicial (`title_screen.tscn`) | à direita, a mesa de perto, rica; à esquerda, preto chapado com o nome em letra fina e quatro opções com uma bolinha | os dois lados não conversam: o menu parece texto solto ao lado de um quadro; o nome do jogo não tem peso |
| Pausa (`pause_menu.tscn`) | papel creme com fita, cinco barras: uma âmbar, quatro pretas | os botões são blocos genéricos, não coisa do mundo; nada diz qual noite nem que hora é |
| Configurações (mesmo papel) | formulário numa coluna: listas, réguas e as quatro teclas | listas e réguas do Godot (o puxador branco redondo destoa do pixel art); volume sem número; tudo junto, sem grupos |
| Relatório e abertura | papéis (memorando, bilhete) | o botão de fechar era um bloco solto (resolvido: a assinatura) |

Comum: quatro estilos de botão (`AmberButton`, `DarkButton`, `TitleButton`, `InkButton`); setas e Enter só na tela
inicial.

## 2. A direção (decidida): o metal do console

O que é **controle** vira peça do console da mesa; o que é **documento** continua papel (o bilhete, o relatório, o
diário).
- Opção = uma tecla do console (`KeyCapStyle`, a do painel do telefone e do discador de perto): a etiqueta creme no
  alto com o nome, a tecla em relevo que afunda ao apertar, com o tec da tecla (`Sfx` "key"). A principal em verde
  (`Pal.CALL_CAP`), a que perde algo em vermelho (`REC_CAP`), as outras na cor de sempre.
- A tela é uma chapa oliva de cantos quebrados, como o painel da mesa (`Pal.BOARD_METAL`/`BOARD_FACE`), com o título
  gravado numa faixa escura (`_draw_header` da mesa; `PixelArt.big`/`relief`).
- Escolha entre valores (idioma, tela, cores) = uma chave rotativa ou de alavanca com as posições gravadas em volta,
  que estala a cada posição ("knob_tick").
- Volume = um botão giratório (o dos volumes da frente do console) com a escala gravada de 0 a 10.
- Tecla trocável = a própria tecla, com o atalho na etiqueta (como no painel do telefone).
- Foco do teclado = a lâmpada ao lado da tecla acesa (a lâmpada âmbar do menu inicial), igual para o mouse.

## 3. Por tela

### 3.1 Pausa
- A chapa com "PAUSA" gravado e, numa plaquinha creme, a noite, a data e a hora do turno.
- Uma coluna de teclas: Continuar (verde), Configurações, Recomeçar a noite e Voltar ao menu (vermelhas), Sair do
  jogo.
- **Feito (no papel de hoje):** Recomeçar a noite e Voltar ao menu perguntam antes ("Tudo o que foi feito nela se
  perde"), com Sim e Não; o Não vem escolhido e o Esc volta ao menu da pausa (`PauseMenu._ask`, `%Ask`).

### 3.2 Configurações
- A mesma chapa, em três blocos com o nome gravado: **Som** (três botões giratórios), **Tela** (chave de tela cheia
  ou janela, chave de cores) e **Telefone** (chave de idioma e as quatro teclas).
- Aplicar (verde) e Voltar (tecla comum); Voltar sem aplicar desfaz, como hoje (`Settings.restore`).

### 3.3 Tela inicial (decisão 2)
- **Decidida (12/11/2026): a sala antes do turno.** A tela inteira é a própria sala do jogo (`main.tscn` sem o
  turno), às 17:55, com a luminária apagada e só a luz da rua e da janela. O nome do jogo vem em letras douradas no
  vidro da janela, como nas repartições, e as opções são as quatro teclas do painel do operador embaixo
  (`KeyCapStyle`, com a etiqueta), renomeadas: Continuar (verde), Novo jogo, Configurações e Sair (vermelha). Escolher
  afunda a tecla com o tec; as setas e o Enter andam por elas. Reaproveita a sala e as teclas; a mesa de perto de hoje
  (`title_board.gd`) sai.
- Recusadas: as duas abaixo (A e B) e também a central vista da rua e o console de perto.
- **A:** mantém a composição de hoje (a mesa de perto à direita) e troca o preto da esquerda por uma chapa do console:
  o nome do jogo gravado no alto e as opções como teclas, uma embaixo da outra.
- **B:** as opções vão para o próprio painel da direita: as plaquinhas das entradas 01–04 viram CARREGAR, NOVO,
  AJUSTES, SAIR, a lâmpada da escolhida acende e escolher leva o FONE para aquela tomada. A metade esquerda fica só
  com o nome do jogo.

### 3.4 Relatório e abertura (feito)
- O "Ciente" de Maria no pé do papel (`scenes/ui/sign_field.tscn`, `sign_field.gd`): a linha com o "×" a lápis e
  embaixo "Assine para começar o turno" (no bilhete) ou "Assine para encerrar" (no relatório). Sob o mouse, a linha
  escurece e o nome aparece de leve; o clique (ou o Enter, na abertura) escreve "Maria" letra a letra a lápis e, assinado, o
  turno começa ou o relatório sai. Relido no turno, o bilhete já vem assinado. Esperando, um lápis pequeno bate no começo da linha e
  o "×" e o texto pulsam (HISTORICO 576). Saíram o botão Começar turno e o
  Assinar e sair.

## 4. O que vale para todas
- Um componente só: a tecla do console num `Button` com a variação de tema (`KeyCapStyle` já é um `StyleBox`), nos
  estados normal, sob o mouse, com foco, apertada e desabilitada. Substitui `DarkButton` e `AmberButton` nos menus.
- Teclado em todas as telas: setas, Enter e Esc, como na inicial.
- As regras de sempre: fonte em 11 ou 22, pixel perfeito, nada de luz pontilhada.

## 5. Etapas (uma de cada vez, com captura antes e depois)
1. A tecla de menu e a **pausa**.
2. As chaves e os botões giratórios e as **configurações**.
3. A **tela inicial**, pela decisão 2.

Em cada etapa: `tests/run.sh keys rua`, as capturas do `shot.gd` (`--screen=pause|settings`, `--ask`) e o `HISTORICO`.
