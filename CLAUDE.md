# Project Switchboard — memória do projeto

Jogo em Godot 4.6 (GDScript, renderer GL Compatibility), a caminho da versão definitiva. O jogador é o operador
noturno da central telefônica de São Sotero, cidade pequena (18:00–00:00). Mecânica: atender e transferir ligações numa
mesa comutadora com cabos físicos; ao fundo, uma ligação misteriosa de número desconhecido (terror leve), por uma entrada sorteada.
O README.md descreve o jogo para quem joga/edita conteúdo; este arquivo é o mapa para quem mexe no código.
Leia também [LESSONS.md](LESSONS.md) antes de mudanças grandes.

## Convenções
- Tudo em português: textos da interface, falas, comentários (`##` para doc de função) e mensagens ao usuário.
- **Interface em cenas** (`scenes/`), com Containers; scripts de interface em `scripts/ui/`. Lógica em `scripts/`.
  Estilo visual no tema global `themes/main_theme.tres` (variações de tipo: `GreenButton`, `AmberButton`,
  `RedButton`, `InkButton`, `DarkButton`, `ChoiceButton`, `HudPanel`, `GreenKey`, `AmberKey`, `IvoryKey`, `RedKey` (teclas do console:
  `KeyCapStyle`, um StyleBox em script, `scripts/ui/key_cap_style.gd`), `PaperToggle`, `PaperInk`, `LetterButton`,
  `DarkPanel`, `PaperPanel`, `NotePanel`, `FormPanel`, `SlipPanel`, `InkLabel`, `InkSoftLabel`, `InkBoldLabel` (11 em negrito: a sombra de 1 px ao lado), `DimLabel`, `AmberLabel`,
  `MonoLabel`, `InkMonoLabel`, `TapedNote`/`TapedLabel`: papel preso com fita, `TapedPaperStyle`). Prefira variação de tema a override por nó.
- Nomes de pessoas e lugares na ordem natural, "Nome Sobrenome" (nunca "Sobrenome, Nome"); a lista telefônica
  ordena pelo nome como aparece, sem acento (`PhoneBook._entries`, `_plain`). **Uma letra por página dupla**: a aba de
  índice na borda direita (`_index`, `_tab_rect`; a da letra aberta fica destacada) abre só os contatos daquela letra
  (`pages()`: começam na esquerda e seguem na direita); Voltar e Virar passam de letra em letra e, depois da última,
  vem a página de anotações. Contato: nome, pontilhado até o número e, embaixo, observação · endereço · bairro
  (`_addr`, espaços que não quebram no bairro e em "rua, número"). A observação (`DirectoryEntry.note`) só diz **quem
  atende quando o nome não diz** ("Pe. Anselmo", "recepção", "secretaria", "use o despacho"); nada de horário ou
  "residência". Todo número da lista serve para alguma coisa: não existe lugar sempre fechado.
- **Conteúdo em Resources** (`data/content.tres` + um `.tres` por contato da lista em `data/directory/`, com os motivos e as conversas dele, + um `.tres` por roteiro em `data/calls/`, um por mudança da sala em `data/room/` + um por noite em
  `data/nights/`). Nada de falas no código, exceto as do operador.
- **Endereço por lugar do mapa**: em `GameData.LANDMARK_CHANCE` das emergências de molde, quem liga diz a rua e um lugar
  do mapa em vez do número ("Rua do Sol, perto do posto" / "na frente da escola, na Rua do Sol";
  `GameContent.address_landmark`, lacunas {street} e {landmark} = `MAP_*_OF`). Só lugares cujo quarteirão encosta num
  único trecho daquela rua (`MapGrid.landmark_spots`), para haver um trecho certo; rádio e caderno usam a forma "perto".
  `MapGrid` (`scripts/map_grid.gd`) guarda a grade e os lugares (`LM`) sem depender da interface (o `CityMap` usa e
  desenha); lugar novo no mapa precisa de `MAP_X` e `MAP_X_OF` e fica num quarteirão que bata com o endereço da lista.
- **Moldes** (`data/templates/`, listas `transfer_templates`/`emergency_templates` no content): `TransferCall`/
  `EmergencyCall` com lacunas **em inglês** (`{place}`, `{reason}`, `{street}`, `{house}`...), preenchidas por
  `GameData.template_transfer()`/`template_emergency()`. Motivos em `DirectoryEntry.motives` (`Motive`: o pedido e a conversa que vem depois). `TEMPLATE_CHANCE`
  (`Schedule`) mistura moldes e roteiros escritos (híbrido: treinamento, trotes e roteiro da noite sempre escritos).
- Todo o áudio é sintetizado ao iniciar por `SfxSynth.build()` (`scripts/sfx_synth.gd`: as receitas, 258 sons, 6,5 MB;
  sem cache; em pedaços, `PARTS` e uma voz por pedaço, montados ao mesmo tempo nos núcleos, `WorkerThreadPool` em alta
  prioridade (a de baixa usa só ~30% deles): ~0,4 s num Mac recente pelo editor, ~0,9 s um depois do outro; cada
  pedaço numa instância com o seu sorteio, `_rng`, porque o `randf` global não é seguro entre linhas de execução); **nada de chamar função a cada amostra** num laço de som (do
  próprio script ou de objeto, como `_rng.randf_range`): as linhas de execução travam umas nas outras, e 8 carros ao
  mesmo tempo levavam 10 vezes o tempo de um; a curva vai numa lista e o ruído num sorteio escrito no laço (`_build_car`) e tocado pelo autoload `Sfx` (`scripts/sfx.gd`: tocar, mixar, ambiente), inclusive as "vozes" por sílaba
  (`Sfx.speak_char`: entonação da frase em `_tone`, altura da pessoa pelo nome em `pitch_of`; vogal nasal em `_nasal` e ataque da consoante em `_onset`, tocado junto com a vogal; na emergência, o nervoso pelo estágio da barra e o temperamento sorteado, `agitation`; as de quem liga tocam
  no barramento Phone, a banda do telefone, que vai para o Voices; desconhecida e rádio levam o filtro na sílaba). Ao fechar, o `Sfx` para os sons e espera um instante (`_exit_tree`): fechando com som tocando,
  as gravações vazavam ("ObjectDB instances leaked"). O aviso pequeno que ainda sai fechando no meio de uma conversa
  (um `GDScript`, um `SceneTreeTimer`, "N resources still in use") é do Godot: um `await` de `create_timer` pendente
  ao fechar sempre vaza (reproduzido num projeto mínimo; retomar as esperas na saída rodaria o jogo). Barramentos em `default_bus_layout.tres`: Ambience, Voices, Effects (e Rub, o atrito do fio: vai direto para o Master, com uma reverberação mais seca que a do Effects, e segue o volume dele, `Settings.FOLLOWS`).
  Ambience tem um compressor com sidechain em Voices (o ambiente baixa enquanto alguém fala); Effects, uma
  reverberação leve de sala. `Sfx.play_at(id, screen_x)` toca um som vindo de um lugar da tela (`screen_x` em fração da largura, de 0 a 1;
  de px, converta, como `Main._across`) (pool de
  `AudioStreamPlayer2D`, `PAN`); a mesa usa para os sons dela (`Switchboard._sfx`, `screen_x`) e o rádio para a voz,
  o chiado e os bipes (`Radio.screen_x()`; `speak_char`, `syllable` e `static_burst` aceitam `at`). O toque da mesa
  (bipes suaves, `BEEP`; `ring_start(bells)`: linha -> lugar da tomada) reveza entre as linhas chamando, cada uma no seu tom (`BELL_STEP`).
- Cursores próprios no autoload `Cursors` (`scripts/cursors.gd`): pixel art 16×16 em texto, uma por forma
  `Control.CURSOR_*` (seta, dedo, mão aberta = `MOVE`, mão fechada = `DRAG`, proibido, I-beam). Botões e sliders
  ganham o dedo sozinhos (`node_added`, troca adiada em `_point` para não esbarrar em nó fora da árvore); quem quer outra forma define `mouse_default_cursor_shape` (a mesa troca a
  dela a cada quadro). **Na ampliação do jogo**: o `GameView` passa a dele (`Cursors.zoom`) e o cursor é montado com o mesmo filtro (`_image`), para o pixel dele ser o do jogo (sempre 2×, ficava grosso em 1080p). Passe `Image`, não textura, ao `Input` (textura vaza ao fechar).
- **Volume de som muda só por `Sfx.fade`/`Sfx._tween`: uma mudança nova cancela a anterior do mesmo volume.** Com
  duas ao mesmo tempo, a mais longa terminava por último e ganhava: o cenário avisa a hora (`set_late`) desde a
  introdução, e a mistura do clima padrão (chuva, em 8 s) terminava depois da da noite (em 2 s), trocando os grilos
  de uma noite limpa pela chuva. `Sfx.weather` começa vazio e a mistura não mexe em nada antes da noite.
- Clima (`Main.weather`: "rain", "fog", "clear", sorteado; `-- --weather=X` força): `Sfx.start_ambience(w)`/
  `set_weather`/`hush_nature`/`stop_ambience`; a chuva é em estéreo, cada lado com o seu chiado (`_build_rain`: o ronco grave igual nos dois lados, o lençol de gotas
  sem os agudos, como ouvido pela janela fechada, e o grão miúdo das gotas, por igual; em mono era um chiado de rádio),
  mais do lado da janela (`SfxSynth.RAIN_LEFT`: o lado esquerdo mais baixo), e cresce e diminui em ondas lentas
  (`RAIN_WAVES`, sobre `_rain_db`). **Nada de gota solta na chuva**: batidas, bolhas de poça, gotas no vidro e o pingo da
  calha soavam como "tic" e saíram a pedido; das
  22h à meia-noite os grilos sobem e a brisa baixa (`Sfx.set_late`, `LATE_*`); o zumbido elétrico de 60 Hz da sala fica baixo (`Sfx.HUM_DB`; a -29 e a -37 dB cansava, sobretudo em fone; antes da
  ligação desconhecida baixa para `HUM_HUSHED` e, depois dela, some); a luminária zumbe bem baixo, seguindo a
  luz dela (`lamp_buzz`, `Sfx.lamp`, `LAMP_BUZZ`), e estala quando pisca (`lamp_tick`); `Background.weather` desenha a janela, `Conversation.topics()` junta os
  assuntos gerais com os do clima (`ChatTopic.weather`).
- **Resolução: tudo em 1x1 sobre 960×540, ampliado só em múltiplos inteiros (pixels perfeitos).** A cena principal é
  `scenes/app.tscn` (`GameView`, `scripts/ui/game_view.gd`): o `main.tscn` dentro de um `SubViewport` de 960×540 (o
  `View`, "nearest"; o padrão do `SubViewport` é linear e não herda o do projeto), ampliado para a janela pelo `Box`
  (`SubViewportContainer`, "nearest") no maior múltiplo inteiro que cabe (`GameView._fit`): 2× em 1080p, 4× em 4K; o
  que sobra é borda escura (1× com borda em 720p e 1600×900, 2× com borda em 1440p). Menor que 960×540, reduz. (Antes,
  em 1280×720, a 1080p era 1,5×, com o filtro "sharp bilinear": uniforme, mas um pouco macio; a pedido, a base virou
  960×540 e a ampliação quebrada saiu, com a escolha "suave/pixel perfeito" das Configurações. Tudo foi reduzido a 75%,
  menos o texto, que continua em 11: o que é feito de texto, como o cartão do despacho, o bilhete e o caderno, ocupa
  mais da tela que antes.) O jogo é sempre 960×540: numa janela de outra proporção (monitor largo), o que sobra é borda escura (antes ganhava
  largura até 21:9 e a sala se esticava, a pedido saiu). A sala ainda se arruma na largura que tiver (abaixo), para o
  `main.tscn` sozinho numa janela larga. O
  projeto continua em `canvas_items` 960×540 para o `main.tscn` sozinho e os testes; o `GameView` desliga isso na janela
  (`content_scale_mode`) e aplica a tela das Configurações (`Settings.fullscreen`: cheia ou janela; padrão: cheia; na janela, o maior múltiplo inteiro que cabe na área livre da tela, `GameView._size_window`). Na pausa, o `Box` continua processando
  (`process_mode` ALWAYS; o `View` é PAUSABLE): parado, ele não repassava as teclas e o Esc não despausava
  (`tests/test_keys.gd`). O cenário tem a tela própria dele (`SceneView`, `scripts/ui/scene_view.gd`: um `TextureRect`
  com o `SubViewport` `View` na resolução da tela onde ele está: a janela, com o `main.tscn` sozinho, ou 1:1 dentro do
  `GameView`). (Testados e descartados: o cenário em 2x2 numa tela de metade da resolução; o jogo todo em 2x2 com a fonte
  Tiny5, branch `improve/0000-pixel-2x`; o jogo todo ampliado como imagem com "nearest", que deixava o texto feio a 1,5×;
  e um filtro de 2x2 por cima do cenário, com média, que borrava.) Sem linhas de
  varredura.
- **O cenário (`Background`) e a mesa comutadora (`Switchboard`) estão descritos em `scripts/ui/CLAUDE.md`** (lido
  ao mexer em `scripts/ui/`). Regras gerais deles: **o cenário e a mesa só se redesenham quando o que mostram muda**
  (estado comparado no `_process`: `Background._state`, a camada `_over`, o `_back_state` da vista, o `_look` de cada
  camada da mesa: painel, lâmpadas, tomadas com a luz da sala e fios);
  quem acrescentar ao desenho algo que muda precisa pôr isso no estado da camada certa. Sem tela, a vista da janela
  não é desenhada (`Background._headless`).
- **Bloom das luzes** (`Bloom`, `scripts/ui/bloom.gd`, nó `Bloom` do Main, z 2: acima da mesa e dos painéis, abaixo dos
  menus), no estilo do glow de cinema e em pixel art: halo somado à tela (blend ADD) em duas camadas (curta e forte,
  longa e fraca), desenhado em blocos de `BLOCK` px (1, como o resto) com poucos degraus lisos (`DITHER` liga o pontilhado ordenado entre eles; desligado, a pedido, porque salpicava
  pontos escuros em volta das lâmpadas) (`_halo_for`, guardado por
  tamanho); por cima, a própria luz nítida com o centro indo, em degraus, para um branco tingido pela cor dela (`HOT`,
  `HOT_TINT`; sem isso o halo parecia uma fumaça). Só brilha o que se declara luz, porque pela cor não dá (o plug
  vermelho tem o tom da lâmpada vermelha; um bloom de tela por cor foi testado e descartado): quem desenha luzes chama
  `Bloom.clear(self)` no começo do `_draw` e `Bloom.light(self, rect, cor, halo, core, round)` por luz acesa (lâmpadas
  redondas da mesa, `Switchboard._draw_lamp`, com aro niquelado, `BEZEL`; aro da tomada de destino, sem miolo;
  luzes das máquinas do cartão; barra de agravamento; janelas acesas do `Background`, que desenha em 2×). ColorRect e
  Label no grupo "bloom" brilham na cor deles (luzes do rádio). Luz
  sem miolo tem o halo fraco por dentro (`HOLLOW`); luz de quem recorta o conteúdo (`clip_contents`) é recortada também.
  O que fica na frente das luzes de quem desenha (os plugs encaixados da mesa) entra com `Bloom.occlude(self, polígono)`:
  os blocos do halo cobertos por ele somem (`_cut`, guardado; plug parado não refaz). A máscara só vale para as luzes
  do mesmo dono: na mesa, a camada das lâmpadas registra as duas.
- Pixel art desenhada em `_draw()`; cores e fontes em `pal.gd` (`Pal.*`). **Área cheia em `draw_primitive`, não em
  `draw_polygon`**: cada `draw_polygon`/`draw_colored_polygon` é uma chamada de desenho (e cria um polígono a cada
  redesenho); `draw_primitive` (até 4 pontos) seguidos viram uma só. O cenário tem `Background._fill`/`_poly` (o
  quadrilátero inteiro; o resto, em triângulos); a sala passava de 2000 chamadas por quadro. **Os materiais dos objetos da mesa** (capa da lista,
  fita e papelão do bloco de fichas, tábua e folhas da prancheta, papel-jornal, papel e tons do mapa, níquel, o vermelho do formulário, o grão e a borda do tampo) são
  constantes do `Pal`, usadas pelo objeto (`Background._art_*`) e pelo papel aberto dele: o que muda numa ponta muda na outra. **Uma fonte só, de pixel: Departure Mono**
  (`Pal.ui` e `Pal.mono` são a mesma; continuam separadas pelo papel), **só em múltiplos de 11** (o que é gravado no painel da mesa não usa
  ela: é uma fonte de pixel própria, maiúsculas de 3×5, `PixelArt.TINY`/`TINY_ACCENTS`/`tiny`, com os acentos dos três
  idiomas; o estado escrito de cada linha em cima das lâmpadas saiu, a pedido: a lâmpada já diz): 11 (texto, números da lista), 22
  (títulos, visor, bilhete), 33 (títulos de tela). **Em objeto da sala, nada de fonte acima de 11**: em 22/33/44 cada pixel dela vira um bloco de 2/3/4 px ao lado dos de 1 px ("pixels duplos"); use 11 em negrito (a sombra de 1 px ao lado, como a manchete do jornal), a fonte ampliada pelo Scale2x em relevo ou vazada (`PixelArt.big`, `relief`: o nome do jornal) ou letra desenhada à mão (as chapas da mesa, `PLATE_LETTERS`; os algarismos do relógio, `DIGITS`, com barras de 1 px). Importada com suavização (a janela
  menor que 960×540 não apaga os traços), sem hinting e sem sub-pixel. Texto em
  desenho com escala (mapa) sai fora da escala (`CityMap._t`).
- **Idiomas** pt_BR (padrão), en, es. Interface/código: **enum `T.Key`** (`scripts/t.gd`, GERADO) +
  `translations/ui.csv` (`chave,pt_BR,en,es`); use `T.text(T.Key.X)` (com valores: `T.text(T.Key.X) % n`), nunca
  `tr("texto")` com literal. Cenas: o `text` do Label/Button é a chave (auto-tradução do Godot). Falas dos roteiros
  (`data/`): português no Resource, `tr()` na hora de mostrar, traduções em `translations/content.{en,es}.po`
  (nomes próprios repetem o original). Depois de mexer em textos: `Godot --headless --path . -s
  tools/update_translations.gd` (gera o enum e mescla os .po; campos fora da extração em `SKIP`). `Settings.set_locale`
  troca o idioma (o jogador escolhe em Configurações; padrão pt_BR; `-- --lang=en` força). Em funções estáticas, traduza com `TranslationServer.translate()`.
  Lacunas dos moldes também se traduzem: `tr(spoken)`, `tr("d" + spoken)`, `tr("pr" + spoken)` têm entradas próprias
  no .po. Texto que já chega traduzido num Button/Label dinâmico: `auto_translate_mode = DISABLED`. Revisão em
  planilha: `-- --review` grava `build/traducoes.csv` (arquivo, pt_BR, en, es) e `-- --apply=<csv>` devolve en e es
  aos .po (`_fixes`).
- Entrada: ação `cancel_plug` no Input Map (Esc e botão direito) devolve o plug que está na mão; ação `pause` (Esc, P)
  pausa o turno quando não há plug na mão (`Main._unhandled_input`). Atalhos do telefone: ações `answer_call`
  (Espaço), `transfer_call` (Tab), `listen_call` (Z, a tecla Escutar/Soltar), `hang_up` (X), tratadas em `PhonePanel._input` **antes da interface** (Espaço e
  Tab também apertam o botão em foco e passam o foco; por isso não dá para usar `Button.shortcut`). Só com o botão
  ativo; na pausa não valem; com um campo de texto em foco a tecla fica com ele. As quatro teclas ficam numa grade de 2 × 2 (`Keys`, um `GridContainer`: em fila, tomavam a largura da tela da conversa, e numa emergência as respostas não cabiam e o painel crescia, empurrando a sala para cima). Cada tecla é uma chapa de metal
  parafusada com a etiqueta de latão no alto, onde fica o atalho (Label `Key`; "Espaço" traduzido, `KEY_SPACE`), e a
  tecla baixa, em relevo, num poço no meio do espaço embaixo dela (`KeyCapStyle`, `WELL_H`; as margens de conteúdo põem
  o nome no tampo). Ferramentas: ações `tab_directory`/`tab_dispatch`/`tab_logbook`/`tab_call_log` (1 a 4),
  tratadas em `Main._unhandled_input` só durante o turno (`Main.TAB_KEYS`, `Tools.toggle`: a tecla da ferramenta aberta a
  guarda; Esc também guarda, antes de pausar). No código, `Tools.set_tab(id)` abre; os ids são as constantes `Tools.DIRECTORY`, `DISPATCH`, `LOGBOOK`,
  `CALL_LOG`, `NEWS` e `TOLL` (nunca o texto: o `check.sh` acusa).
- **Pausa e configurações**: `PauseMenu` (`scenes/ui/pause_menu.tscn`, z 4, `process_mode` ALWAYS) usa
  `get_tree().paused`. **Todo `create_timer` do jogo leva `false` no 2º argumento** (senão continua contando na pausa);
  o `Sfx` roda sempre (ambiente segue, abafado: `Sfx.muffle`, um passa-baixa e um ganho no Master, `MUFFLE`; nas
  Configurações volta ao normal para o volume se ajustar ouvindo; `Main.pause()` cala a campainha e `_update_bell` a devolve). Configurações no
  autoload `Settings` (`user://settings.cfg`): `locale`, `volumes` por barramento e `fullscreen` (a
  tela, que o `GameView` aplica; a velocidade do texto saiu, a pedido: o ritmo das falas faz parte do jogo, como o da
  escuta); sinal `changed`. `set_*` vale na hora (prévia) mas só
  `save()` grava (botão Aplicar); Voltar/Esc faz `restore(snapshot)` do estado de quando a tela abriu. Testes (`-- --test=x` ou `-s`) não leem nem gravam o arquivo.
  Textos montados uma vez (botões do despacho, itens do caderno, telas desenhadas) se refazem em
  `NOTIFICATION_TRANSLATION_CHANGED`.
- Git: branch principal `development`; commits no padrão `tipo(#0000): descrição`. `.godot/` fica fora do git.
  Só faça commit quando o usuário pedir (na reestruturação ele autorizou um commit por etapa em `refactor/definitive`).
- Comentário `ponytail:` marca um atalho deliberado; mantenha o código enxuto e no estilo do arquivo.
- **Quando o usuário pedir commit, rode antes a skill `revisar-mudancas`** (`.claude/skills/revisar-mudancas/`; só
  então, não depois de cada mudança): uma passada rápida de boas práticas e desempenho só no código alterado.
  - O `check.sh` acha o óbvio nas linhas acrescentadas do `git diff`.
  - O resto é a lista de revisão dela, tirada deste arquivo e do `LESSONS.md`.
  - Mexeu em desenho ou em algo por quadro: o `medir.gd` compara com os números de referência.
  - Convenção nova que der para conferir por padrão no texto entra no `check.sh`.

## Rodar e testar
- Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (não está no PATH). Cena principal: `scenes/app.tscn` (o `GameView` com o `main.tscn` dentro).
- Checar se tudo compila: `Godot --headless --path . --quit-after 60`.
- **Com o editor aberto, nada de `--import`** (o `run.sh` pula sozinho): os dois gravam `.godot/uid_cache.bin` e o
  corrompem (entradas depois da contagem do cabeçalho; o jogo diz "Unrecognized UID" e perde o layout dos barramentos
  de áudio). Para consertar: fechar o editor, apagar o `uid_cache.bin` e reimportar (ou abrir o editor).
- **Testes: `tests/run.sh`** (roda tudo em headless; ~2 min no total; `tests/run.sh flow penalties` roda só esses). Um
  `SCRIPT ERROR` não encerra o Godot: o `run.sh` lê o log enquanto o teste roda e o encerra no primeiro erro (sem isso,
  cada teste quebrado ficava parado até o `LIMIT` de 120 s e a bateria passava de 10 min).
  Roda com **`--fixed-fps 60`**: cada quadro avança 1/60 s de jogo e o motor não espera o relógio real (simulação
  determinística, turno do robô em ~9 s). Para rodar um teste à mão, use a mesma opção:
  `Godot --headless --fixed-fps 60 --path . tests/runner.tscn -- --test=x --seed=1`. **Os testes rodam como cena**
  (`tests/runner.tscn`/`runner.gd` carrega `tests/test_<x>.gd`, que estende `test_base.gd`, um `Node`, e começa em
  `_initialize`): os autoloads já existem, então `Main`, `Switchboard`, `CardMachines` têm tipo nos testes; o `SceneTree`
  é `get_tree()`. Com `--fixed-fps`, tempo de teste se mede em
  quadros/delta, nunca em `Time.get_ticks_msec()` (o robô soma `get_process_delta_time()` em `sim`).
  `Engine.time_scale`: 8 nos cenários, 2 no robô (acima disso as falas, letra a letra, ficam presas ao quadro e
  alongam as conversas; a 48× as métricas mudavam muito).
  - `tests/test_base.gd`: base (`ok()` em vez de `assert`, que trava o headless; `wait_until`, `load_main`, `finish`).
  - `tests/test_flow.gd`: cenários dirigidos (transferência, espera, desistência, caderno, destino que não atende, ligar de volta ao desconhecido, cliques, clima do som).
  - `tests/test_keys.gd`: as teclas (1, Espaço, Tab, X, Esc e despausar) entrando pela janela, pelo `GameView`.
  - `tests/test_layout.gd`: em 960, 1125 e 1281 px de largura, nenhum objeto da mesa por cima de outro na tela (o
    contorno de cada um como o cenário o desenhou, `Background._occ`/`occ_ids`; a caneca na frente do relógio é de propósito).
    Mexeu na disposição da mesa: rode este.
  - `tests/test_penalties.gd`: consequências (perdida e retorno, número errado, registro, despacho errado,
    emergência sem despacho, espera longa, informação errada) e o relatório. Relógio parado; retornos tocados à mão.
  - `run.sh` começa com `--import`: **`class_name` novo só existe depois de reimportar** (sem isso, parse error).
  - `tests/test_shift.gd`: robô que joga o turno inteiro e imprime métricas (máx. simultâneas, % com 2+/3+,
    % sem cabo livre, perdidas, maior silêncio); `run.sh` roda com `--seed=1..3`, um turno `--clumsy` (deixa de atender 1 em 3),
    a noite 2 (`--night=2`) e um turno `--human` (5 s de jogo por ação, como uma pessoa: **é este que mede se o ritmo
    cabe**; o robô normal é rápido demais). No `--human` o despacho passa pelo cartão (`_card_step`: pensar, marcar,
    esperar imprimir, perfurar, levar ao transmissor e esperar a leitura), e o estágio anotado é o da hora do envio.
    Com a mesa livre, ele registra no caderno e carimba e guarda os bilhetes (uma ação cada; imprime quantos guardou).
    `--nosy` (no `run.sh`, com `--human`): com a mesa livre, ele escuta as conversas conectadas, solta no silêncio
    deles (`HUSH`) e volta quando a suspeita baixa (`NOSY_BACK`); imprime quanto ouviu e falha se for denunciado.
    Medido: ~17–20 s ouvidos por conversa (de 45–90 s), nenhuma denúncia e o mesmo ritmo de ligações. Imprime também,
    por desconfiança do lugar (`DirectoryEntry.wary`), os segundos por entrada na linha: ~14–17 s no normal (com
    `LISTEN_SEC` 25 eram ~8, e a conversa passava antes de dar para ler), menos na pensão (1,6) e mais no bilhar e no
    bar (0,6 e 0,5), como na conta (de `NOSY_BACK` a `HUSH` em `LISTEN_SEC`, ÷ a desconfiança). Com `--careless`
    também (no `run.sh`), ele não solta no silêncio: imprime em quantos segundos ouvindo eles ficaram sabendo, por
    desconfiança do lugar (~23 s no hotel, 1,0), e falha se ninguém o denunciar.
  - Rode depois de qualquer mudança em agenda, fim de ligação, mesa ou cabos. `run.sh` também joga um turno em
    `--lang=en` e outro em `--lang=es`; o teste de fluxo confere chaves, lacunas e cenas (`_check_translations`).
- Semente fixa: `Godot --path . -- --seed=123` repete a agenda do turno (sem `--seed`, é aleatória).
- **Painel de debug** (F1, ação `debug`; `DebugPanel`, `scenes/ui/debug_panel.tscn`, nó `%Debug` do Main, z 5): só em
  build de debug (editor ou export de debug; no release ele se apaga). Toca ligações na hora (qualquer tipo; emergência
  escolhida, com o caso sorteado; interurbano num tronco que nenhuma ligação da mesa usa), imprime só um bilhete de tarifação,
  sem ligação (de 1 a 12 minutos até agora, numa entrada sem contador; `Main.print_ticket`), pula estágio ou congela a barra (`Urgency.frozen`), mostra o que a emergência
  exige (contado e real), mostra a suspeita de cada conversa conectada e força o silêncio delas (`Eavesdrop.force_hush`; o
  Limpar é o `calm`, que também apaga as denúncias), velocidade 1–8×, pula o relógio, troca o clima na hora (`Main.set_weather`), encerra o turno, troca de noite (`_go_night`: troca o Main por um novo na noite anterior/seguinte, no mesmo pai, dentro da tela do `GameView`; posto na raiz, saía na resolução da janela e quebrava o layout; sem ler nem
  gravar o progresso, para testar a entrega dos setores), libera viaturas (`Dispatch.reset`; `_gen` cancela
  as viagens em andamento), registra pendências, limpa advertências e apaga o progresso. Mesa de som: toca cada som de `Sfx.VOL` com
  um controle de volume que vale na hora (`Sfx.vol`, a cópia em uso) e "Copiar VOL" põe a constante ajustada na área de
  transferência, para colar em `sfx.gd`. A aba Vozes (o painel tem duas abas, Jogo e Vozes) fala cada letra pelo nome
  dela ("bê", "efe") ou um texto digitado, na voz escolhida (`_voices`, `_speak`). Cada seção tem "Limpar" e o
  topo tem "Restaurar tudo" (`Main.drop` tira uma ligação sem caderno, advertência nem retorno; `Main.drop_all` tira
  todas e zera a mesa antes de tirar os cabos, para nada contar como conversa cortada; `Main.drop_emergency` apaga as
  emergências em andamento; tocar uma terceira emergência é recusado; `Notebook.reset`). Textos fixos em português (ferramenta, não interface). O que mexe no
  estado do Main fica em funções públicas dele (`free_line`, `ring`, `print_ticket`, `set_weather`, `start_ending`, `drop`, `drop_all`,
  `drop_emergency`); dos campos, o painel só lê agenda e ligações para o texto de estado e adianta o relógio (`minutes`), para não quebrar quando o Main mudar.
- **Captura de tela** (`tools/shot.tscn`, COM tela): `Godot --path . tools/shot.tscn -- --hour=22:30 --weather=rain
  --tool=despacho --card --emergency --news --toll --width=1125 --zoom=x,y,w,h --out=build/shot.png` grava a tela inteira e o
  recorte ampliado 4× (`_zoom.png`); `--hover=id` põe o mouse num objeto da mesa (contorno e nome); `--debug=N` abre o painel de debug na aba N; as opções do jogo (`--night`, `--seed`, `--lang`) também valem. Para conferir
  mudança visual medindo, não só olhando a captura.
- **Sem tela, a vista da janela não é desenhada** (`Background._headless`): com `--fixed-fps` e o tempo acelerado,
  ela era redesenhada a cada quadro e virou 2/3 do tempo de um turno do robô (27 s em vez de 9). Quem acrescentar
  desenho pesado que roda a cada quadro, meça um turno (`--test=shift --seed=1`).

## Exportar
- Builds e versões: skill `exportar-build` (`.claude/skills/exportar-build/`).

## Arquivos
- `scripts/model/exchange.gd` (`Exchange`) é o **dono único** do estado das linhas e destinos (enums `Line`, `Dest`);
  o Main só avisa o que aconteceu ao `Supervisor` (consequências).
- **`Background` e `Switchboard` em camadas por herança** (`extends "res://..."`, sem `class_name` nas de baixo;
  cada camada só usa as de baixo, e cada constante ou variável fica na mais baixa que a usa; `Background.X` e
  `Switchboard.X` continuam valendo para tudo): `background_base.gd` (estado em comum, câmera, `_fill`/`_poly`/`_p`,
  clima) → `background_view.gd` (a vista da janela) → `background_props.gd` (o tampo e os objetos da mesa) →
  `background.gd` (a sala, as camadas, o mouse); `switchboard_base.gd` (geometria e ligações) →
  `switchboard_panel.gd` (o móvel, lâmpadas, tomadas, chapas, prateleira) → `switchboard_plugs.gd` (plugs e fios) →
  `switchboard.gd` (entrada, física, sons e o `_draw`). Função nova vai na camada do que ela desenha; se uma de baixo
  precisar dela, ela desce.

## Modelo das ligações
- `live`: ligações tocando ou em andamento (várias ao mesmo tempo). O painel mostra `phone.shown()`.
- **Foco** = a ligação da entrada onde está o FONE (`Main._focus()`); Main mantém `c.on_line`. Quem não está em
  foco fica "em espera" e **não fala**: `say()`/`op()` aguardam `_until_on_line(c)`. Exceção: ligação já resolvida
  (`c.closing`: informação respondida, emergência despachada) não entra em espera; a pessoa termina de falar sozinha
  e desliga, sem som e sem texto na transcrição (só o que for dito com o FONE na linha aparece).
- Destino que não atende: pedido com alternativa (`TransferCall.alt_target`) sorteia ao ser criado se o lugar pedido
  atende (`PhoneCall.away`, `AWAY_CHANCE`); se não, toca sem resposta e o operador pode sugerir a
  alternativa (`alt_ask`, `Conversation._transfer_alt`), que sempre atende. **A alternativa é do mesmo ramo**
  (`DirectoryEntry.category`: farmácia, igreja, mercearia, hospedagem, oficina; o teste confere; a
  Vila Serena tem hospedagem e oficina, então a mecânica aparece desde a noite 1): os moldes a escolhem sozinhos
  (`GameData.alternative`, fala `OP_TRY_OTHER`, resposta em `alt_accepted`); os roteiros escritos têm a deles. Só
  ganha ramo quem pode ser trocado por outro para qualquer motivo dos `reasons` (bar não: "recado pro amigo que tá lá").
- Transferência: FONE na entrada → Atender → pedido → cabo de conexão saída→destino → **Transferir** (`transfer()`)
  → `_ring_dest` → destino atende (com o FONE na linha, quem ligou agradece) → `_try_complete` na hora, com ou sem o
  FONE na entrada (o operador não ouve a conversa dos dois) → linha e destino CONN por `TALK_LEN`
  → DONE (vermelho) até o jogador tirar as pontas. `_dgen` invalida toques de destino quando o cabo sai.
- **Escuta** (`Eavesdrop`, `scripts/eavesdrop.gd`, nó filho do Main): cada linha tem uma chave de escuta na mesa,
  entre a entrada e a saída (`Exchange.key`/`set_key`; só sobe com a linha CONN e desce sozinha quando ela sai de
  CONN). A alavanca sobe com o destino tocando e desce quando ele atende (`Switchboard.lever_up`); com o FONE na linha
  conectada, a tecla Escutar (Z, `Main.listen`; levantada, ela diz Soltar, `PhonePanel.set_listen`) ou o clique na
  alavanca (`Main._on_lever`; sem o FONE, `WARN_LISTEN_FONE`) a sobe e desce. Ouvindo (`Eavesdrop.listening`), a tela
  mostra o que se ouve numa PhoneCall só dela (`Talk.ear`, fora do Registro; cada conversa conectada é um
  `Eavesdrop.Talk` em `talks`, por linha, com a ligação, o que se ouve, `knows` e `written`, limpo num lugar só): quem atende fala primeiro (o lugar com o
  nome dele, `DirectoryEntry.hello`; a pessoa, um "alô" de `C.overheard_hello`), depois as falas escritas
  (`TransferCall.overheard`, começando por quem ligou, que cumprimenta, e alternando; sem elas, o cumprimento de
  `C.overheard_greet` se atendeu uma pessoa) e depois o murmúrio das vozes sem texto (assuntos da conversa fiada,
  `MURMUR_DB`). **Nos moldes, a conversa vem do motivo** (`Motive`, `scripts/data/motive.gd`: `DirectoryEntry.motives`,
  cada um com o `text` que vira o {reason} e as `talks`, uma sorteada, que vira o `overheard`), para nunca sair do
  assunto do pedido. Lacunas sorteadas por conversa (`TalkFill`, `GameContent.talk_fills`: {hour}, {wait},
  {nights}...; {street} e {house} do mapa; `GameData.talk_vars`, preenchidas no `Eavesdrop._talk`) mudam o que se
  ouve. Quem atende tem a voz do contato (`DirectoryEntry.voice`; sem ela, uma pelo nome, `GameData.voice_of`).
  Depois da última fala escrita, os dois se despedem (`C.overheard_bye`/`overheard_bye_back`) e desligam
  (`Main.talk_over`). Regras de escrita conferidas no teste de fluxo (`_check_talks`): sem o tipo do lugar num
  lugar com ramo (a alternativa pode atender; `KIND_WORDS`), só lacunas que existem, cada fala até `TALK_MAX` letras
  nos três idiomas. Todo motivo tem duas conversas e toda transferência escrita tem a sua (`overheard`; o teste
  confere); só os roteiros da noite (`story`) ainda murmuram. **A conversa anda ouvindo ou não**: o que ele não ouviu, perdeu (entrando
  no meio, a fala começa com "…"), mas com falas escritas ela não acaba antes da última (`Eavesdrop.speaking`, no
  `Main._update_line_timers`). Cada escrita ouvida (`HEARD_SHARE` dela) liga o marcador dela
  (`TransferCall.overheard_flags`, na mesma ordem: o roteiro sabe se ele pegou o nome, a hora); ouvidas todas, os da
  ligação (`overheard_sets`). **Palavras-chave** (`Clue`, `scripts/model/clue.gd`): nas falas escritas, marcadas
  `[tipo:texto]` (tipos em `Clue.KINDS`: person, street, place, phone, time...; podem envolver uma lacuna,
  `[time:{hour}]`); a marca some da tela e da voz (`Clue.parse`, no `Eavesdrop._say`), e a palavra ouvida com todas
  as letras (nenhuma perdida com a chave abaixada) entra em `Eavesdrop.clues` (palavra, tipo, noite, hora, quem ligou
  e para que número; uma vez por conversa) com o sinal `clue_heard`: o lápis risca (`pencil`) e ela fica sublinhada
  na transcrição (`PhoneCall.underline`, as `marks` da fala, `[u]` no `PhonePanel._render_transcript`). Ficam as de
  todas as noites: salvas no `Progress.clues` (em dicionário, `Clue.to_dict`/`from_dict`) no fim do turno e lidas no
  `Eavesdrop._ready`. Aparecem nas anotações da lista telefônica (`PhoneBook.clues`, a mesma lista; `_draw_clues`),
  uma linha por palavra (`clue_groups`: a ouvida de novo junta-se à anotada, "×2", e herda a marca dela no
  `Eavesdrop._clue`), a mais nova em cima e as riscadas no fim, seguindo nas páginas duplas depois da primeira
  (`notes_spreads`, `notes_changed` a cada palavra nova). O clique passa de normal a marcada para repassar
  (`Clue.chosen`) a riscada (`Clue.struck`) e de volta, na palavra inteira; as duas marcas ficam salvas (o repasse
  ainda não existe). Captura: `tools/shot.tscn -- --clues`. A fala da
  escuta anda letra a letra sem um timer por letra (`Eavesdrop._wait`: espera quadros, desconta o que passou a mais e
  para na pausa), mais devagar que a fala com o operador (`PACE`, e `GAP` entre uma fala e outra), para dar tempo de
  ler ouvindo; a suspeita (`LISTEN_SEC`) acompanha esse ritmo: mudou um, confira o outro. O teste confere os tipos, as marcas
  fechadas e que a tradução mantém os tipos (`_holes`). **A
  suspeita** (`PhoneCall.suspicion`, 0 a 1 em `LISTEN_SEC` ouvindo; cada entrada na linha, pela chave subindo ou pelo
  FONE encaixando com ela em cima, soma `CLICK`; tudo vezes a desconfiança deles, a de quem ligou, `TransferCall.wary`,
  e a do lugar que atendeu, `DirectoryEntry.wary`, também nos moldes e na alternativa; sem ninguém
  ouvindo, baixa em `COOL_SEC`) só aparece na conversa:
  passando de `HUSH` com ele ouvindo, a conversa normal para e **o resto anda no tempo, não pela suspeita**
  (`Eavesdrop._react`): terminada a fala, calam-se `HUSH_SEC` (`SYS_LINE_SILENT`; soltando a chave aí, a conversa
  segue: a melhor hora; com a desconfiança dos dois, `Eavesdrop._wary`, de `SKEPTIC` para cima, não se calam e
  perguntam depois de `ASK_PAUSE`), um pergunta ao outro (`C.overheard_ask`) e, com ele ainda ouvindo no fim da
  pergunta, o outro responde (depois do `GAP`) e eles sabem (`C.overheard_sure`, a resposta da mesma pergunta;
  `Talk.knows`; sem ninguém ouvindo, desconversam e a suspeita fica `SHRUG` abaixo de `HUSH`). **Sabendo, a
  denúncia é certa** (`_denounce`, na hora da resposta; soltar a chave depois não a desfaz); com ele ouvindo, mais
  `HUSH_SEC` calados e a reclamação (`C.overheard_caught`, `_caught`), e os dois desligam (`talk_over`); soltando
  antes, a conversa segue e eles reclamam da próxima vez que se calarem com ele ouvindo. Do silêncio à reclamação, ~12 s em qualquer lugar; a
  desconfiança do lugar só muda quando o silêncio começa. No silêncio (`_silence`), a linha "(Silêncio na linha.)" ganha um ponto por segundo
  (`PhoneCall.set_line_text`) e o chiado da linha sobe (`Eavesdrop.silent`,
  `SILENT_HISS_DB`, por `Main.refresh_hiss`, que também dá o de sempre da linha do FONE). O lugar que denunciou fica
  mais desconfiado nas noites seguintes (`Eavesdrop.grudges`, `GRUDGE` somado ao `wary` dele por denúncia; salvo no
  `Progress.grudges`). (Antes cada estágio esperava a suspeita subir até o
  seguinte: ficavam 6–20 s calados, e antes disso a conversa escrita seguia e acabava antes da pergunta.) O jeito de atender de cada lugar dá a pista da desconfiança dele (`hello`: seco na
  pensão, solto no bar). **A denúncia chega no relatório da noite seguinte**
  (`Supervisor.fault_later` → `ShiftReport.later` → `Progress.later`; lá, a advertência grave `eavesdrop` com a hora
  "ontem, 21:30", `REPORT_YESTERDAY`); sem noite seguinte (a última, noite forçada) entra no de hoje, e a do
  treinamento não vai; as ligações do treinamento não se escutam (`Main._can_listen`). Marcadores `escutou_N` e `denunciado_N` para o roteiro (pedidos de escuta de gente autoritária
  virão com a história). Captura: `tools/shot.tscn -- --listen`.
- **Interurbano** (`GameData.TRUNKS`, 901–906: uma tomada por cidade no banco INTERURBANO da mesa, destinos do
  `Exchange` fora da lista e de todos os setores; `GameData.entry` devolve a telefonista de lá, `TRUNK_OPERATOR`):
  transferência cujo `target` é um tronco e `TransferCall.far_number` o número na outra cidade, montada por molde
  (`GameData.trunk_transfer`, `trunk_templates`, lacunas {to_city} = `trunk_to` e {far}; `Schedule.TRUNK_SHARE` das
  transferências, nunca no treinamento; um tronco por noite, como os destinos). Saída no tronco → Transferir → toca →
  a telefonista de lá atende (`trunk_hello`), o operador passa o número (`OP_TRUNK_NUMBER`), ela chama (`trunk_wait`,
  mais toques) e só então conecta (`Main._trunk`; ela só fala com o FONE na linha). No tronco errado o número não é de
  lá (`trunk_unknown`, dest livre de novo, conta como número errado; na segunda, quem ligou desiste). Dica da primeira
  vez: `HINT_TRUNK` (`SAW_TRUNK`). Ponytail: sem tronco ocupado na outra ponta nem ligação a cobrar.
- **Bilhete de tarifação** (o calculógrafo, `Toll`, `scripts/ui/toll.gd`, a ferramenta `Tools.TOLL`, só pelo objeto da
  mesa, no lugar onde ficava a prancheta, que agora fica pendurada na lateral do painel da mesa comutadora): começa a contar sozinho
  quando a telefonista de lá completa (`Main._try_complete` → `Toll.start`) e, quando a linha sai de conectada (acabou,
  cortada ou fim do turno; `Main._update_line_timers` → `_print_ticket`), imprime o bilhete (`TollTicket`,
  `scripts/ui/toll_ticket.gd`: entrada, cidade e número de lá, horário e minutos, o começado conta inteiro; papel com
  fibras, a beira de baixo serrilhada e, embaixo dos dados, o campo tracejado do carimbo, `FIELD`), que cai na
  mesa embaixo da fenda (à direita da almofada, para não cobrir o carimbo) (`%Desk`, com a almofada de tinta e a caixinha). A máquina mostra os minutos em contadores de
  tambor, um por entrada (`Toll._counter`: a plaquinha, a lâmpada e os tambores com os algarismos de `DIGITS`, que rolam
  no começo de cada minuto começado, `ROLL`; o visor só se redesenha a cada quadro enquanto um rola, `_rolling`) e fica
  apoiada na mesa pelos pés. O tampo é desenhado pelo próprio `Toll` (`_draw`), até a beira do papel, com o grão e a
  borda da frente da mesa da sala (`Pal.DESK_GRAIN`, `Pal.DESK_EDGE`). A almofada tem a tampa aberta atrás e o brilho
  da tinta no feltro, que some quando ela é carimbada e volta (`_wet`, `WET_SEC`); na caixinha, a beira de cada bilhete
  guardado mostra a faixa do formulário e, nos carimbados, a ponta da marca (`_filed`). **Bilhetes e carimbo são soltos**: o
  jogador pega qualquer um, leva para onde quiser e ele fica onde foi solto (`Toll._on_desk_input`, um arrastar próprio
  como o do cartão do despacho, não o do Godot; o de cima é o pego, `_piece_at`; na mão sobem e, soltos, caem, como o
  cartão, `Lift`; guardar a ferramenta com um deles na mão o deixa onde estava). O carimbo é visto de cima, inclinado, como
  da cadeira, no modelo do numerador automático de escritório (a referência do usuário, em pixel art), fino (88 px):
  o cabo de baquelite preta em cogumelo (o preto dos cabos), com o tampo oval e o brilho, a haste cromada e o anel,
  fatias redondas deitadas uma por cima da outra (`_knob`, `_knob_r`, `_knob_tone`, `SQUASH`; o desenho em texto de
  28 px saía achatado), com o medalhão de latão do fabricante (inventado, `BRAND`) no tampo e o reflexo quente da
  luminária do lado da luz (`GLINT`); o corpo de níquel com o tampo à vista e a plaqueta "TARIFADO"; embaixo, o eixo
  com as pontas e as rodas de algarismos de latão, da largura da janela, com os tipos na cor da tinta; e a armação
  parada, as pernas com o rasgo do eixo e os parafusos de latão, descendo até o fundo da sapata, o seletor de latão
  com riscos gravados e a alavanca serrilhada (`SELECTOR`; sem letras nem números: "0 1 2 D", o modo de repetição dos
  numeradores de verdade, ninguém entendia; molas de retorno à vista também saíram, a pedido), e a sapata entre elas, vista de cima, com a janela (`WINDOW`, do tamanho da marca,
  `TollTicket.MARK_SIZE`, 64×34: a moldura grossa de cantos redondos com um fio fino por dentro, a data da noite,
  miúda, `PixelArt.tiny`, entre dois traços, "TARIFADO" na fonte de 11 em negrito e "SÃO SOTERO" miúdo,
  `CityMap.CITY`, entre estrelinhas; a tinta falha nos fios, cada bilhete do seu jeito, mais de um lado e mais com a
  borracha secando; a data pela noite, `TollTicket.night`, que o Main passa ao `Toll`), por onde se vê onde ele vai
  carimbar (`Toll.STAMP`, `_draw_stamp`). A sombra da armação tem duas camadas, a curta e escura de quem encosta na
  mesa (`SHADOW_NEAR`, some na mão) e a longa e fraca, como a do corpo e do cabo; a longa da armação não passa onde
  cai a do corpo (`_minus`): sombras translúcidas somadas escurecem o dobro (o `modulate` vale por desenho); só a armação
  fica dentro da mesa (`FOOT`, `_inside`): o resto passa por cima da máquina para alcançar o bilhete embaixo da
  fenda, e o mouse ali chega pelo próprio carimbo (`mouse_filter` PASS). Levar e soltar não carimba: **posto em cima do
  bilhete, um clique nele** (apertar e soltar sem andar `CardMachines.DRAG_START` px) o aperta (`_stamp_down`): o
  corpo desce pelas pernas acelerando, até as rodas de latão encostarem no fundo da janela, tampando-a toda (`PRESS`;
  parando no meio dela, o papel à vista embaixo das rodas, parecia não encostar), fica no papel um instante e volta
  freando (`_press_k`, `PRESS_DOWN`, `PRESS_HOLD`, `PRESS_SEC`), e a sombra do que desce encurta perto do papel; na
  batida (`_touch`: o baque e o estalo do metal, `thump` e `punch`) a mesa sacode, o que está nela pula e assenta
  (`SHAKE_SEC`, `SHAKE_PX`, a posição do `%Desk` volta a `_desk_at`), e ele carimba o bilhete de
  cima que estiver embaixo da janela, nem que só a beira (`_ticket_under`; um que já tem marca que vale não recebe
  outra): **a marca sai onde a janela estava** (o meio em `RUBBER_MID`, `stamp`), recortada no papel (`TollTicket._inked`,
  `clip_contents`; antes era empurrada para dentro e saía longe de onde bateu); com menos da metade no papel é borrão e
  não vale (`MARK_VALID`), e as que não valem continuam no papel (`_marks`) quando ele é carimbado de novo; a borracha seca a cada batida (`Toll.INK`: a primeira cheia, a outra mais fraca e, depois, só o vulto, que
  não vale como carimbo, `TollTicket.ink`) e volta a ter tinta apertado na almofada (a borracha muda de cor). Com a
  ferramenta aberta, o bilhete impresso sai da fenda da máquina no tempo do som da impressora, a beira de baixo na
  frente, e cai na mesa (`_emerge`: `TollTicket.top` sobe o desenho; saindo, não se pega); impresso com ela fechada
  (o comum), espera na fenda (`_fresh`; na sala, a ponta de pé) e sai dela quando a ferramenta abre, mais depressa
  (`OUT_SEC`, um depois do outro; `_arrange`, chamado também quando ela fica visível). O bilhete solto com o mouse na caixinha vai para ela (`file`; conta na hora) e desce para dentro,
  sumindo atrás da frente dela (`_sink`: a altura dele encolhe até a boca, `BOX_MOUTH`, com `clip_contents`; por isso o
  `TollTicket` desenha sempre em `SIZE`); sem o carimbo, ela aceita e vem a advertência leve
  `toll_unstamped` (`Toll.unstamped`). O número do bilhete é reservado quando começa a contar (`Toll.ticket_of`) e vai
  para a ficha do caderno ("Bilhete nº 0002", `PhoneCall.Record.ticket`). Bilhete esquecido na mesa: à meia-noite o turno
  espera guardar, como o registro (`Main._unregistered`), e no fim é advertência leve `toll_forgotten`
  (`Supervisor.shift_over`). **Na mesa da sala, o calculógrafo é a ferramenta aberta em miniatura** (antes era uma
  caixa com a fenda no tampo e um visor, e não batia com ela): a máquina atrás, na proporção da aberta (`CALC`), sem
  relógio, nem nela nem na aberta (o de flip, ao lado, já dá a hora), os dez contadores (o da entrada
  contando acende, `Toll.counters` → `Background.counting`), a plaqueta com a luz e a fenda embaixo, de onde a ponta do
  bilhete esperando (`Toll.in_slot` → `Background.tickets`) desce para a mesinha no tempo do som da impressora
  (`Background._draw_tip`, camada própria, `TIP_SEC`); na frente dela, a mesinha na proporção da mesa aberta
  (`Toll.NOMINAL`, a de 960 × 540), com a almofada e a caixinha afastadas dos cantos na mesma medida (`Toll.INSET`), os bilhetes soltos com as marcas, a caixinha com os guardados e o
  carimbo em pé onde o jogador os deixou (`Toll.layout` → `Background.toll_desk`, passado só com a ferramenta fechada:
  aberta, levar um bilhete redesenharia a sala a cada quadro). Dica da
  primeira vez: `HINT_TOLL` (`SAW_TOLL`). Ponytail: não há tecla, e o interurbano ainda contando no fim do turno não
  imprime.
- Fim de ligação: `end_call(c, PhoneCall.End.*)` gera `c.record` (um `PhoneCall.Record`, nulo antes; no livro, `stamped` com o carimbo) e manda para `Notebook.add()` (fila; não trava o turno; não atendida vai
  direto para o livro com o carimbo `TYPE_MISSED`, sem escolher tipo).
  O caderno registra com **um clique no tipo** (`register(T.Key.TYPE_*)`: Comum, Emergência, Trote; o resto da linha
  vem do `record`), mostra a pendente numa ficha só de leitura e desenha o livro como página pautada (`_draw_page`,
  carimbo colorido por tipo, `STAMPS`). As tiras do caderno (na mesa e no aberto) mostram quantas faltam
  (`pending_changed(count)` → `Background.pending`, `Tools.set_pending`); o jogo não troca de ferramenta sozinho.
- Despacho: **a unidade de despacho da mesa vista de perto** (`Dispatch`, `scenes/ui/dispatch.tscn`; mapa e despacho
  numa ferramenta só): em cima, o `CityMap` (`%City`) sob o vidro, dentro da moldura de metal (`CardMachines._draw_bezel`;
  na cena, `CardMachines.BEZEL` dentro da beira do papel e acima da base); clicar no trecho já marca
  o local (`segment_selected` → `set_location`); passar o mouse mostra uma etiqueta com a faixa de números do trecho
  (`CityMap._tag`, "Rua do Sol, 1–99"). Embaixo, a **base com as três máquinas**, sempre à vista (`%Slip`, `CardMachines`,
  `Dispatch.machines`, cobre o papel todo com fundo transparente: o clique fora da base e do cartão vai para o mapa,
  `_has_point`; `BASE_H`), lado a lado como na base da miniatura (`Background._art_deck`), cada uma numa caixa de metal
  (`_box`: sombra, parafusos, placa de latão, luz e saída de ar), com a fenda da largura do cartão (`_mouth_x`): o
  transmissor à esquerda, a impressora no meio e a trituradora à direita, afastadas (com a impressora logo acima da
  trituradora, o cartão solto ali mesmo era triturado; antes, a ficha abria e fechava por cima do mapa, com as máquinas
  entrando pelas bordas, o × e o botão de reabrir: saíram com a base fixa). O cartão tem `PunchCard.W` = 132 px (as três fendas lado a lado
  cabem na unidade; espaçamentos justos, `ROW`, `TOP`, `FOOT`, `TEXT_X`) e **todo o texto dele, e o da tira e dos avisos
  das máquinas, na fonte miúda do painel** (`PunchCard.small`, `PixelArt.tiny`; protocolo quebrado em `lines_of`): na de
  11 o local não cabia; as placas das máquinas continuam em 11 (`PunchCard.write`) e as fendas são rasgos finos (`_mouth`). Marcar o local faz a impressora datilografar (`typing`, o local aparece na tira de papel saindo da fenda) e imprimir
  (`printer`, saindo sem parar) um **cartão perfurado** com local, bairro e setor, que sobe pela fenda dela para cima do
  vidro e fica em pé nela (`_rest`); ele anda livre pela unidade toda, por cima da moldura e das máquinas, até a
  borda de baixo (`_clamp`). O cartão é um formulário: impresso na tinta
  vermelha das emergências (`FORM`, a do carimbo do caderno: faixa com o número, rótulos, posições de furo, fio duplo,
  rodapé com o nome da central, marcas de coluna na borda) com os dados datilografados em preto sobre linhas
  pontilhadas, pauta como a do caderno, fibras no papel e sombra na mesa (na mão ele sobe: cresce em volta de onde foi pego e a sombra se afasta; solto, cai acelerando; parado, escala 1 exata para o texto ficar nítido; `Lift`, `scripts/ui/lift.gd`, o mesmo do bilhete e do carimbo do calculógrafo). O jogador perfura
  o tipo de ocorrência (um só) e as unidades (protocolo impresso embaixo de cada uma, `DISPATCH_WHY_*`; ocupada sai
  riscada) em posições fixas (`punch`, picote caindo; clicar em qualquer ponto da linha perfura o quadradinho dela, e a
  linha sob o mouse fica realçada se der para perfurar). Furo não se desfaz. **Um cartão por vez, de qualquer tipo**
  (`CardMachines.can_print`, regra genérica para tipos de cartão futuros): com um cartão na mesa, marcar outro local faz
  a impressora recusar (luz vermelha, `CARD_ONE_AT_A_TIME`, som `deny`) e o mapa volta a marcar o local do cartão;
  é preciso enviar ou triturar antes. O número do cartão enviado (`CardMachines.serial`, no sinal `Dispatch.sent`) vai
  para o registro da emergência (`record["card"]`) e aparece no caderno ("Ficha nº 0003"). O cartão anda livre dentro do mapa e fica onde é solto (arrasta-se de qualquer ponto dele:
  apertar e andar `DRAG_START` px é arraste e não perfura; soltar antes disso é clique e perfura a linha); solto na fenda do transmissor, é puxado (`feed`
  e o leitor, `read`, "tec tec"), fica `READ_SEC` sendo lido já dentro e só então é enviado (`inserted` →
  `Dispatch._send`); na da trituradora, é destruído sem enviar nem punir (`shred`, a
  máquina treme, `discarded` → `Dispatch._discard`; a ficha fica aberta esperando outro local). O transmissor aceita
  cartão **incompleto**: sem
  unidade ninguém sai (`blank_card`, advertência média `dispatch_blank`, rádio `RADIO_BLANK_CARD`); sem tipo, as
  unidades vão e a chegada dá `dispatch_type` ("sem tipo perfurado"). Parado, o cartão não se redesenha: só o que anima redesenha a cada quadro, e quem muda o que ele mostra chama
  `CardMachines.refresh()` (o `Dispatch._refresh` chama). **Cartão e máquinas separados**: o cartão é o `PunchCard`
  (`scripts/ui/punch_card.gd`: formulário, posições de furo em `cells` como {box, part (`PunchCard.Part`), id, row}, `fill`, desenho), nó filho das máquinas (`card`), que só
  usam dele `size`, `held`, `click(p)` (perfura; o som `punch` é das máquinas), `point(p)` (realce) e `cursor(p)`: um
  segundo tipo de cartão responde o mesmo. Ele fica numa janela
  que recorta (`_window`): saindo da impressora ou entrando numa máquina, só aparece acima da fenda (`_into`, `CardMachines.Machine`). Os
  furos são a vista dos dados do `Dispatch` (`_location`, `_occurrence`, `_picked`; `set_occurrence`, `punch_unit`),
  que os testes e o robô usam direto. `CityMap.blocked`: onde há algo por cima
  (`%Fleet`), sem nomes de rua. `%Fleet` (canto de cima à esquerda, só com viatura fora) mostra o estado delas
  (`%Report`). O tipo **não** marca unidades: a conversa decide, pelo protocolo (regras em `EmergencyCall.units`).
  `EmergencyCall.cases` (`EmergencyCase`): variações sorteadas por `GameData.with_case()` (respostas + unidades).
  Depois de enviar, local, tipo e unidades voltam limpos (`city.clear_selection`). Abrir a aba toca o papel
  desenrolando (`unroll`). **O desenho do mapa** é o do mapa sob o vidro da unidade de despacho, de perto: as ruas são o papel entre os
  quarteirões (`Pal.MAP_PAPER`; sem contorno), cada bairro no seu tom (`Pal.MAP_TINTS`), as casas em volta das quadras, de
  frente para as ruas e com o telhado de duas águas, e os quintais com árvores no meio (`_houses`, `_tree`), os lugares
  num prédio de telhado de barro (`Pal.MAP_LANDMARK`), a praça verde com caminhos, árvores e o coreto (`_draw_square`) e o selo vermelho com a rosa dos ventos e o nome da cidade (`CITY`, `Pal.SEAL`).
  O mapa da unidade de despacho (`Background._art_map`) é este em miniatura (os dois sem dobras: aberto sob o vidro) e usa as mesmas peças (`frame_of`, `block_rect`, `lots`,
  `square_paths`/`square_trees`, `field_rect`, `RIVER`, `ROADS_*`, `BORDERS` e as cores `Pal.MAP_*`): mudou uma, mudam as duas.
  **Cidade em folhas** (`CityMap.SHEETS`, 600×440 cada: Vila Serena (setor 3) | Centro (1)
  em cima, Alto da Serra (2) | zona rural (do 2) embaixo), todas com a mesma grade. **Rua que continua tem o mesmo nome
  e a numeração seguindo** (`Street.continues`: trechos 0–2 na folha dela, 3–5 na vizinha, `block_sector(b)`,
  `Street.block_label`): Flores, Brasil e Acácias seguem no Centro (300–599); Comércio, Estação, Sol e Moinho, no Alto
  da Serra. O Centro só tem as verticais próprias (Matriz, Sete de Setembro, Tiradentes, Mercado) e o Alto da Serra as
  horizontais (Palmeiras, Bela Vista, Cruzeiro); elas viram estradas de terra na zona rural. Só aparecem as folhas dos
  setores atendidos (`shown`), e o mapa as enquadra (`_frame`); roda do mouse aproxima (até `MAX_K`), arrastar move,
  clique sem arrastar marca o trecho. **Nomes sem sobreposição** (`_label`, `_boxes`): só desenha o que cabe inteiro
  na vista e não encosta em outro, na ordem bairro (rodapé da folha) > rua > lugar (`_places`, em uma ou duas linhas)
  > numeração (só com `NUMBERS_K`); nome da rua ao longo dela (as verticais em pé), no meio do primeiro trecho à vista entre
  cruzamentos (`_street_name`: inteiro, abreviado "R. do Sol"/"Av. Brasil" se não couber, e afastado o abreviado pode
  passar do cruzamento);
  a numeração delas fica na beira da quadra, fora da rua. Abaixo
  de `NAMES_K`, só os bairros, no meio da folha. Delegacia, bombeiros e hospital
  no Centro (`STATION`); a viagem dura pela distância (`trip` devolve os segundos, `UNIT_SPEED`, `MIN_TRIP`; anda no tempo do jogo,
  `CityMap.Trip`, `trips[i].t`, parando na pausa) e o despacho espera a mais demorada. Depois de um tempo no local (`Dispatch._return`,
  `STAY`), a viatura volta para a base pelo mesmo caminho (`CityMap.go_home`), e só fica disponível quando chega. As viaturas
  não aparecem em nenhum dos mapas (testado e saiu, a pedido: num mapa de papel sob o vidro, um pontinho andando dava
  impressão de monitor); a viagem só conta o tempo (`trips`), e quem está fora aparece na faixa `%Fleet`.
  Quem não era necessária (a mais, endereço errado ou nada lá) volta logo depois de o rádio dizer isso (`Radio.said`,
  `QUICK_STAY`), ou no máximo `QUICK_WAIT` s depois de chegar se o rádio ainda estiver ocupado. Emergências escritas e moldes só nas ruas dos setores atendidos.
  **Regras das viaturas no `Fleet`** (`scripts/model/fleet.gd`, `Dispatch.fleet`; sem tela nem tempo, testado direto no
  teste de fluxo): estado de cada uma (`Fleet.Unit`, `IDS`, `NAMES`, `STATUS`), as emergências em andamento (`incidents`, cada uma um `Fleet.Incident`;
  `incident_of`, `required(e)`, `require(e, …)`, `close`), de qual é o cartão (`target_of`: a do lugar marcado; fora de
  todas, a da linha do FONE, `Dispatch.attending`; sem ela, a primeira sem socorro) e a ordem `send` (devolve se o socorro ficou completo) → `arrive` (um `Fleet.Arrival`: `Fleet.Result` OK, MISSING,
  WRONG_PLACE, IDLE; o que falta, o que sobrou, quem volta logo) → `leave` → `home`; `gen` invalida viagens depois do
  `reset`. O `Dispatch` fica com cartão, ficha, mapa, rádio e a espera entre os passos. `Dispatch.set_incident()` quando a emergência toca; `Dispatch.sent` (com a emergência do cartão) → `Main._on_dispatched` →
  `Conversation.emergency_dispatched`. Na chegada,
  `Dispatch.arrived(e, result, occurrence, extra)` (`Fleet.Result`; tipo marcado; unidades
  que não eram necessárias) → `Supervisor.on_arrived`.

## Consequências (relatório do supervisor)
- `ShiftReport` (`scripts/model/shift_report.gd`): `FAULTS` (id → gravidade, descrição), `add()`, desfecho das
  emergências (`trouble`/`resolved`/`failed` → OK, LATE, BAD) e `verdict()`. Gravidades: leve, média, grave,
  gravíssima (`CRITICAL`, pesa `CRITICAL_WEIGHT` graves). Entre noites só as graves somam
  (`severe_before`, salvas no `Progress`; `SEVERE_LIMIT` = demissão).
- **Barra de agravamento** (nó `Urgency`, `scripts/urgency.gd`: `tick` a cada quadro do turno; estado em `PhoneCall.stage`/`urgency`/`asking`/`secured`, regra em
  `PhoneCall.urgent()`, desenho em `UrgencyBar` na tela da conversa do painel de baixo, embaixo das opções, só com o operador na linha; fora dela, o rádio
  inteiro acende: `Radio.alert(stage, away)`, moldura pulsando e aviso na tela; a luz "Ocorrência" acende sempre;
  a cada troca de estágio, `Radio.chirp` toca `radio_alert` vindo do rádio, mais agudo quanto pior): corre desde o atendimento, também em espera e depois de a pessoa desligar; para durante
  pergunta e resposta (`Conversation._em_ask`) e na pausa; para de vez só quando o socorro completo sai para o lugar
  certo (`Dispatch.sent(..., complete)`, conta envios anteriores em `Fleet.Incident.going`). Estágios por
  `EmergencyCall.stage_sec`; cada um chama `Conversation.emergency_worse` (fala `worsening`/`critical`/`lost`; com a
  pessoa já desligada, `RADIO_WORSE`/`RADIO_LOST`; depois de dita, `Urgency.told` atualiza `PhoneCall.told`, e só então `Fleet.require(e.required(told))`
  passa a exigir as unidades do estágio; com a pessoa já desligada ou se despedindo, o rádio diz também o que mandar,
  `RADIO_SEND_MORE`. `told` também libera a pergunta do estágio:
  `Conversation._qa`, índices depois das do roteiro; perdida = só o endereço e `OP_ANYONE_HURT` → `lost_answer`). Advertência pelo estágio
  quando o socorro completo sai (`_on_dispatched` → `Supervisor.secured`: `emergency_worse` média, `emergency_critical` grave + jornal LATE);
  perdida = `emergency_lost` gravíssima na hora (`Supervisor.lost`) + jornal BAD (sem `emergency_dropped` nem retorno). Retornos não têm
  barra (herdam `stage` e `told`: as unidades e as perguntas de quando a ligação caiu). **Até duas emergências ao mesmo tempo**
  (`Main.MAX_EMERGENCIES`, `Main.emergencies`, `in_progress()`: tocando, na linha ou com a barra correndo; `emergency_of(e)`):
  cada uma com a sua barra; o painel mostra a da linha do FONE, e o rádio acende na pior e avisa da que está fora da linha.
  A terceira espera uma delas desligar e ter o socorro. **Viaturas**: cada tipo tem duas (`Fleet.units`: "pol" e a
  de reserva "pol2", `Fleet.SPARE`, `Fleet.kind`); a de reserva só sai com duas emergências em andamento (`Fleet.spare`,
  posto pelo `Urgency` via `Dispatch.set_spare`; `Fleet.vehicle`/`crew` escolhem quem sai). Com uma, quem errou espera
  a viatura voltar. O cartão perfura o tipo; o `Incident` conta tipos; viagens, `leave` e `home` são por viatura.
- O Main chama `supervisor.fault()` onde a falha acontece (cabo cortado, número errado); `Supervisor.call_ended()`
  (chamado em `end_call`) decide advertência e retorno; `call_again()` agenda a mesma pessoa de novo (`PhoneCall.retry`; uma vez por motivo, `retried`;
  nunca depois do fim do turno; `too_late` sorteado com
  `REDISPATCH_CHANCE`). `check_hold()` encerra quem passou de `HOLD_GIVE_UP` em espera (`End.GAVE_UP`).
- Treinamento (`PhoneCall.lesson`), trotes e ligação desconhecida não geram advertência. Falas de retorno, manchetes e pareceres
  ficam no content (grupo "Supervisor e consequências").
- À meia-noite, `start_ending` (`Supervisor.shift_over`) soma o que ficou sem registro e passa o relatório para `Ending.play(report)`, que mostra
  `ReportView` antes do título final.

## Setores (a cidade em três partes)
- O setor de um número é o primeiro dígito (3xx, 1xx, 2xx; 12 em cada, 36 na mesa). O operador começa com o setor 3
  e recebe o 1 na noite 5 e o 2 na noite 9 (`GameData.SECTOR_NIGHTS`; o bilhete das noites 5 e 9 avisa).
  `GameData.sectors` (definido em `Main._load_night`, chamado no `_enter_tree` para valer antes do `_ready` dos filhos)
  filtra a mesa (`board_numbers`), a lista (`PhoneBook`), as transferências (`serves`, `transfers`, `template_transfer`,
  que devolve nulo quando acabam os lugares e a agenda troca por pedido de informação) e os pedidos de informação.
  Polícia, bombeiros e hospital (despacho) valem para a cidade toda. Testes de cenário usam `load_main([1, 2, 3])`.
- Bairros: setor 1 **Centro**, setor 2 **Alto da Serra** (com a zona rural), setor 3 **Vila Serena** (`MAP_DISTRICT_*`,
  nome no rodapé de cada folha do mapa). Cada um tem dez emergências escritas (Vila Serena: 01–10; Centro: 11–13 e 17–23; Alto da Serra: 14–16 e 24–30, a 14
  na casa do Benedito Souza, endereço dele na lista). Na noite da entrega: a primeira transferência para o banco novo
  mostra `HINT_NEW_BANK` (`Main._new_sector`), e na primeira vez que o mapa aparece ele sai do enquadramento antigo e
  se abre para o bairro novo (`CityMap.pending_reveal`, `REVEAL_SEC`; o bairro novo aparece aos poucos).

## Noites (roteiro fixo)
- 15 noites; as 3–15 ainda são genéricas (dia da semana e bilhete, sem roteiro nem ligação desconhecida).
- `GameContent.nights` (ordem) → `Night` (`scripts/data/night.gd`, `data/nights/night_NN.tres`): dia da semana, bilhete
  da intro, clima fixo (vazio = sorteado), a primeira página do jornal (`news_*`, opcional), `story` (`StoryCall`: roteiro escrito + horário fixo) e `mystery` (passos `PrankStep`; vazio = sem
  ligação desconhecida naquela noite). **Só `story` e `mystery` são fixos; não existem ligações "principais".**
- **Noite 0, o treinamento** (`GameContent.training`, `data/nights/night_00.tres`, fora de `nights`): sexta-feira, 5 de
  outubro (`GameData.TRAINING_DAYS` antes da noite 1), setor 3, nível 1. `Main.night_no` 0 = treinamento e -1 = a
  salva; o jogo novo começa nela (`Progress.night` 0), e a tela inicial tem **Pular o treinamento** (`Intro.skip_pressed`
  → `Main._skip_training`: grava a noite 1 e recarrega). Ela não leva graves para a noite 1 e o `Pace.next` dela dá
  sempre o nível 1 ("é o treinamento" = `Main.is_training()`: a noite tem lição). Começa com o FONE já na entrada 1 (`Switchboard.plugged`). A telefonista veterana (`Night.teacher`,
  a Cecília, do Alto da Serra) liga e ensina como colega, pelos passos `Night.lesson` (`LessonStep`: RING por uma entrada
  certa, com ou sem pedido de transferência, `call`; SAY; OPERATOR; WAIT por `until`, com a dica do manual, `hint`, as
  falas de demora, `nudges` a cada `seconds`, e a do erro, `wrong`, com %d = a tomada errada; PAUSE; HANG_UP),
  conduzidos pelo nó `Training` (`scripts/training.gd`). Ela fala devagar, uma frase curta por SAY
  (`Training.SPEECH` no `PhoneCall.speech`): rápida, o texto se acumulava na tela. Erro e demora: ela comenta só se estiver na linha e calada;
  senão, fica a dica. Enquanto ela ensina (`Training.active`) o relógio fica parado e nada da agenda toca; depois,
  segue o turno calmo. As ligações dela são transferências com `PhoneCall.lesson` (o `Conversation` não as roda; o
  Main não deixa desligar nelas nem transferir para o número errado, `Training.wrong_number`; a conversa dela com o
  destino acaba em `Training.TALK_SEC`, `Main.talk_over`). Atender pisca enquanto ela chama com o FONE na entrada
  (`PhonePanel.blink_answer`). Na última ligação ela ensina o caderno (as tiras, registrar as duas dela como
  Comum; outro tipo, ela comenta, `Training._on_registered`), a prancheta e, só de boca, o calculógrafo (carimbar e
  guardar o bilhete); abrir os dois primeiros liga o "já viu" das dicas de
  primeira vez (`Main.SAW_SLIPS`/`SAW_SHEET`). Depois ela liga pela entrada 3 fingindo uma emergência de treino
  (`LessonStep.emergency`, `Training.drill`, posta no `Dispatch.set_incident`): marcar o local, triturar o cartão
  quando ela corrige o endereço, marcar de novo, perfurar, transmitir e ouvir o rádio (passos "dispatch", "card",
  "shred", "punched", "sent", "arrived"; `Dispatch.location()`). A chegada dela não vai para o relatório nem para o
  jornal (`Supervisor.on_arrived`; só a chegada ao lugar certo cumpre "arrived"), e o `Supervisor.fault` não anota
  nada durante o treinamento. As esperas dela não contam na pausa; com o FONE fora da linha dela, o manual diz para
  voltar (`HINT_TRAINING_BACK`). As fichas dela dizem "Treinamento" (`OBS_TRAINING`; a da emergência, `drill_call`,
  leva o local e o cartão). A noite 0 nunca demite (`ShiftReport.fired`) e fecha com "Fim do treinamento". Por fim, a espera
  (o jogador tira o FONE da entrada dela e volta: "hold", "resume") e, só de boca, o fim do turno (23:40, Encerrar
  turno, registrar antes, meia-noite). Teste: `tests/test_training.gd`.
- **Ritmo por nível, não por noite** (`Pace`, `scripts/data/pace.gd`; `GameContent.paces`, 5 níveis; `Main.pace`):
  `call_gap`, `peak_chance`, `max_live`, `emergencies`, `pranks`. Noite 1 = nível 1; `Pace.next` decide o da próxima
  (salvo em `Progress.pace`): até a noite `CONFIDENCE_NIGHTS` (3) só sobe se a noite anterior não foi ruim
  (`verdict()` 2); na noite de entrega de um setor (5, 9) não sobe; depois sobe sempre, até o último nível, que é o limite para todas as noites seguintes (o 6 que foi
  medido perdia ~1,3 ligação por noite com `--human`). Noite forçada (`--night=N`) usa `Pace.expected(N)` (sem
  tropeços); `--pace=N` força.
- `PrankStep` é o roteiro falado de trotes e da ligação desconhecida (`Conversation.play_steps`); `EFFECT` =
  "static", "static_loud", "flick". `PhoneCall.from_script()` aceita Transfer/Emergency/PrankCall.
- **Marcadores** (`StoryFlags`, `scripts/model/story_flags.gd`; `Main.flags`): nomes ligados por escolhas ou pelo jogo,
  salvos entre noites (`Progress.flags`). Genérico: qualquer sistema consulta `flags.allows(requires)` e altera
  `flags.apply("nome" | "!nome")`; sinal `changed`. Condição `requires: PackedStringArray` (todos ligados; "!" =
  desligado) em `StoryCall` (conferida **na hora de tocar**, via `PhoneCall.requires`) e `PrankStep` (passo pulado);
  `PrankStep.sets` = efeito de cada opção do OPERATOR; `ChatReply.sets`/`ChatTopic.requires` na conversa fiada. Automáticos: `ligou_de_volta_N`, `desligou_desconhecida_N`.
  Para um recurso novo usar marcadores: exporte `requires`/`sets` e chame `allows`/`apply`. Testar um ramo:
  `-- --night=2 --flags=a,b`.
- `Progress` (`scripts/model/progress.gd`, `user://progress.cfg`): próxima noite e graves acumuladas
  (`ShiftReport.severe_before`/`severe_total()`/`fired()`), marcadores e as palavras-chave ouvidas (`clues`). Main salva em `start_ending` (última
  noite ou demissão limpa o save). `-- --night=N` força uma noite **sem ler nem gravar** o save; `test_base.load_main` força a noite 1.

## Agenda e ritmo (constantes no topo de main.gd e schedule.gd; por noite em `Night`)
- Ligação desconhecida (`MYSTERY`, entrada livre sorteada, guardada em `myst_line`) entre `Night.mystery_from` e `mystery_to` (22:00–23:30), só
  toca com a mesa em silêncio, por no máximo 30 min de jogo (`latest`, `Schedule.MYSTERY_WAIT`), e nunca depois de
  `LAST_CALL - MYSTERY_MARGIN` (23:30): o botão Encerrar turno só aparece depois dela.
- **Ligação do roteiro toca sozinha** (`Main._scripted`: `story` ou a desconhecida): espera a mesa em silêncio por até
  `Schedule.STORY_WAIT` (30 min, `latest`) e, enquanto ela está na mesa, nenhuma outra toca (o robô confere).
- **Mesa parada demais**: vazia por `QUIET_SHARE` do maior `Pace.call_gap`, toca um pedido de informação a mais
  (`Main._fill_quiet`; não com uma do roteiro a menos de `STORY_GAP`, nem depois de `LAST_CALL`). O robô mede a maior
  mesa vazia (`mesa_vazia`, além do `maior_silêncio` entre toques).
- Sorteadas: `Schedule._random_calls` — intervalo `Pace.call_gap` (nível 1: 45–60 … nível 5: 28–38; medido com `--human`) entre uma e a
  próxima, `Pace.peak_chance` de vir logo em seguida, no máximo `Pace.max_live` pedindo atenção (`_run_schedule`), a `STORY_GAP` das fixas. Tipos: `Pace.emergencies` (a `EMERGENCY_GAP` uma da outra; no laço, com
  `MAX_EMERGENCIES` em andamento a próxima espera), `Pace.pranks`, resto transferência/informação.
  Um destino (e `alt_target`) por noite: dois pedidos do mesmo número travavam um ao outro.
- `GIVE_UP_SEC` 60 s (`story` 1,5x, retornos 0,75x); treinamento e desconhecida nunca desistem.
- Espera na linha (`Main._nag`, silêncio medido em `talk_clock`, que para na pausa): transferência pedida e o
  operador parado → depois de `SMALLTALK_AFTER` (10 s; o destino chamando não conta: sem resposta, o silêncio
  recomeça, `Main._ring_dest`, para a conversa fiada não vir junto da opção da alternativa), com `SMALLTALK_CHANCE` (60%, uma vez por ligação), conversa
  fiada do cotidiano (`Conversation.smalltalk`). **Cada assunto é um `ChatTopic`** (`scripts/data/chat_topic.gd`,
  `GameContent.smalltalk`): `line`, `weather` (vazio = qualquer), `voices` (quem pode dizer: "Meu marido..." só em voz
  de mulher; `Conversation.topics(voice)`), `requires` (marcadores) e `replies` (`ChatReply`: `text`, `follow`, `tone`, `sets`),
  para nenhuma resposta cair fora do assunto; todo assunto tem uma resposta simpática e uma seca (o teste confere).
  O operador pode responder (as `replies` viram as últimas opções, `PhoneCall.chat`; ele escolhe uma): ela diz a `follow`
  dela e o silêncio recomeça. **Tom**: `WARM` dá `Conversation.CHAT_WARM_PATIENCE` s a mais antes de reclamar e ela pode puxar outro
  assunto (sem repetir, `PhoneCall.chats`, até `Conversation.SMALLTALK_MAX`); `CURT` encerra o papo (ela não puxa mais e a opção de
  puxar conversa some). `sets` altera marcadores (a quermesse prometida na noite 1 volta na noite 2). **Novidades**
  (`Conversation.is_news`): assuntos da noite (`Night.smalltalk`) ou com `requires` vêm antes dos gerais e só uma vez por noite
  (`Conversation.heard`). O operador também puxa assunto, uma vez por ligação (ela responde primeiro com `chat_bridge` e só puxa
  assunto sem `unprompted_only`, que é para os que não cabem como resposta; `OP_SMALLTALK`,
  `Conversation._ask_chat`, `PhoneCall.chat_asked`; escondida enquanto um assunto corre, `PhoneCall.chatting`); com `NAG_AFTER` (22 s) sem falar, reclama (`waiting`) e a resposta some. Emergência:
  `EMERGENCY_NAG_AFTER`, só no estágio inicial da barra (depois, a fala de cada estágio já cobra a demora). A conversa fiada não vem mais logo depois do pedido. Conversa fiada só do cotidiano (nada
  que lembre o mistério: luzes piscando, carros parados, chiado na linha).
- Conversas transferidas duram `TALK_LEN` (34–68 min de jogo ≈ 45–90 s reais).
- Turno das 18:00 (`SHIFT_START_HOUR`) às 00:00 (`SHIFT_END` = 360 min); fim **depois** da ligação desconhecida ter caído (`start_ending`).
- **Fim do turno**: nada novo toca depois de `LAST_CALL` (23:40; sorteadas param ali e `_run_schedule` descarta
  retornos e atrasadas; a desconhecida tem regra própria). A partir daí, com a desconhecida já passada, o botão
  **Encerrar turno** (`%EndShift`, no lugar do texto do turno ao lado do relógio) fecha a noite: quem está na linha ou
  tocando termina com `End.SHIFT_OVER` (advertência média `shift_hung_up`; emergência sem despacho vira
  `emergency_dropped`; já resolvida, `closing`, não conta; o registro dela não conta como sem registro). À meia-noite
  ninguém é cortado: com alguém na linha o relógio continua até ela acabar; com a mesa vazia ele para, e o turno fecha
  sozinho quando não falta registrar nada nem bilhete na mesa (senão, `HINT_MIDNIGHT` e espera registrar e guardar ou
  o botão).
- Relógio: 0,75 min de jogo por segundo real (`GAME_MIN_PER_SEC`): 6 h de turno ≈ 8 min reais.

## Histórico das decisões de design
- O que o usuário pediu, em ordem, e por quê, fica em [HISTORICO.md](HISTORICO.md): consulte antes de refazer ou
  desfazer algo visual ou de mecânica (muita coisa foi testada e saiu a pedido) e acrescente ali cada pedido novo do
  usuário, com as chaves do assunto. **Não leia tudo**: cada item tem chaves (`#camera`, `#cabos`, `#saiu`..., a lista
  fica no alto do arquivo) e só os itens com as chaves do pedido interessam:
  `awk -v t='camera|janela|saiu' '/^[0-9]+\. /{p = $0 ~ "#(" t ")( |$)"} p' HISTORICO.md`.

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
