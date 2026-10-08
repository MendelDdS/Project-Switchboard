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
  `RedButton`, `InkButton`, `DarkButton`, `ChoiceButton`, `HudPanel`, `GreenKey`, `AmberKey`, `RedKey` (teclas do console:
  `KeyCapStyle`, um StyleBox em script, `scripts/ui/key_cap_style.gd`), `TabButton`, `PaperToggle`, `PaperInk`, `LetterButton`,
  `DarkPanel`, `PaperPanel`, `NotePanel`, `FormPanel`, `SlipPanel`, `InkLabel`, `InkSoftLabel`, `DimLabel`, `AmberLabel`,
  `MonoLabel`, `InkMonoLabel`, `TapedNote`/`TapedLabel`: papel preso com fita, `TapedPaperStyle`). Prefira variação de tema a override por nó.
- Nomes de pessoas e lugares na ordem natural, "Nome Sobrenome" (nunca "Sobrenome, Nome"); a lista telefônica
  ordena pelo nome como aparece, sem acento (`PhoneBook._entries`, `_plain`). **Uma letra por página dupla**: a aba de
  índice na borda direita (`_index`, `_tab_rect`; a da letra aberta fica destacada) abre só os contatos daquela letra
  (`pages()`: começam na esquerda e seguem na direita); Voltar e Virar passam de letra em letra e, depois da última,
  vem a página de anotações. Contato: nome, pontilhado até o número e, embaixo, observação · endereço · bairro
  (`_addr`, espaços que não quebram no bairro e em "rua, número"). A observação (`DirectoryEntry.note`) só diz **quem
  atende quando o nome não diz** ("Pe. Anselmo", "recepção", "secretaria", "use o despacho"); nada de horário ou
  "residência". Todo número da lista serve para alguma coisa: não existe lugar sempre fechado.
- **Conteúdo em Resources** (`data/content.tres` + um `.tres` por roteiro em `data/calls/`, um por mudança da sala em `data/room/` + um por noite em
  `data/nights/`). Nada de falas no código, exceto as do operador.
- **Endereço por lugar do mapa**: em `GameData.LANDMARK_CHANCE` das emergências de molde, quem liga diz a rua e um lugar
  do mapa em vez do número ("Rua do Sol, perto do posto" / "na frente da escola, na Rua do Sol";
  `GameContent.address_landmark`, lacunas {street} e {landmark} = `MAP_*_OF`). Só lugares cujo quarteirão encosta num
  único trecho daquela rua (`MapGrid.landmark_spots`), para haver um trecho certo; rádio e caderno usam a forma "perto".
  `MapGrid` (`scripts/map_grid.gd`) guarda a grade e os lugares (`LM`) sem depender da interface (o `CityMap` usa e
  desenha); lugar novo no mapa precisa de `MAP_X` e `MAP_X_OF` e fica num quarteirão que bata com o endereço da lista.
- **Moldes** (`data/templates/`, listas `transfer_templates`/`emergency_templates` no content): `TransferCall`/
  `EmergencyCall` com lacunas **em inglês** (`{place}`, `{reason}`, `{street}`, `{house}`...), preenchidas por
  `GameData.template_transfer()`/`template_emergency()`. Motivos em `DirectoryEntry.reasons`. `TEMPLATE_CHANCE`
  (`Schedule`) mistura moldes e roteiros escritos (híbrido: tutorial, trotes e roteiro da noite sempre escritos).
- Todo o áudio é sintetizado ao iniciar por `SfxSynth.build()` (`scripts/sfx_synth.gd`: as receitas, 138 sons, 3,7 MB;
  sem cache; em pedaços, `PARTS` e uma voz por pedaço, montados ao mesmo tempo nos núcleos, `WorkerThreadPool` em alta
  prioridade (a de baixa usa só ~30% deles): ~0,35 s num Mac recente pelo editor, ~0,9 s um depois do outro; cada
  pedaço numa instância com o seu sorteio, `_rng`, porque o `randf` global não é seguro entre linhas de execução) e tocado pelo autoload `Sfx` (`scripts/sfx.gd`: tocar, mixar, ambiente), inclusive as "vozes" por sílaba
  (`Sfx.speak_char`). Barramentos em `default_bus_layout.tres`: Ambience, Voices, Effects (e Rub, o atrito do fio: vai direto para o Master, com uma reverberação mais seca que a do Effects, e segue o volume dele, `Settings.FOLLOWS`).
  Ambience tem um compressor com sidechain em Voices (o ambiente baixa enquanto alguém fala); Effects, uma
  reverberação leve de sala. `Sfx.play_at(id, screen_x)` toca um som vindo de um lugar da tela (pool de
  `AudioStreamPlayer2D`, `PAN`); a mesa usa para os sons dela (`Switchboard._sfx`, `screen_x`) e o rádio para a voz,
  o chiado e os bipes (`Radio.screen_x()`; `speak_char`, `syllable` e `static_burst` aceitam `at`). O toque da mesa
  (bipes suaves, `BEEP`; `ring_start(bells)`: linha -> lugar da tomada) reveza entre as linhas chamando, cada uma no seu tom (`BELL_STEP`).
- Cursores próprios no autoload `Cursors` (`scripts/cursors.gd`): pixel art 16×16 em texto (×`SCALE`), uma por forma
  `Control.CURSOR_*` (seta, dedo, mão aberta = `MOVE`, mão fechada = `DRAG`, proibido, I-beam). Botões e sliders
  ganham o dedo sozinhos (`node_added`, troca adiada em `_point` para não esbarrar em nó fora da árvore); quem quer outra forma define `mouse_default_cursor_shape` (a mesa troca a
  dela a cada quadro). Passe `Image`, não textura, ao `Input` (textura vaza ao fechar).
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
  22h à meia-noite os grilos sobem e a brisa baixa (`Sfx.set_late`, `LATE_*`); a luminária zumbe bem baixo, seguindo a
  luz dela (`lamp_buzz`, `Sfx.lamp`, `LAMP_BUZZ`), e estala quando pisca (`lamp_tick`); `Background.weather` desenha a janela, `Conversation.topics()` junta os
  assuntos gerais com os do clima (`ChatTopic.weather`).
- **Resolução: tudo em 1x1 sobre 1280×720, ampliado para qualquer tela sem quebrar os pixels.** A cena principal é
  `scenes/app.tscn` (`GameView`, `scripts/ui/game_view.gd`): o `main.tscn` dentro de um `SubViewport` de 1280×720 (o
  `View`, "nearest"; o padrão do `SubViewport` é linear e não herda o do projeto), ampliado para a janela pelo `Box`
  (`SubViewportContainer`) com o filtro de pixel art (`SHARP`, "sharp bilinear"): cada pixel do jogo vira um bloco do
  mesmo tamanho e só a divisa entre dois blocos, um pixel da tela, mistura as cores. Ampliação inteira (1× em 720p, 2×
  em 1440p, 3× em 4K) sai perfeita; quebrada (1,5× em 1080p, 1,25× em 1600×900), uniforme e um pouco mais macia. Antes,
  com o `canvas_items` direto, 1,5× fazia um pixel virar ora 1, ora 2 da tela: linhas, letras e círculos desiguais.
  Janela mais larga que 16:9 dá largura ao jogo (até `MAX_W`, 21:9), nunca altura; o que sobra é borda escura (a barra de título do Mac já deixa a janela um pouco mais larga). A sala se arruma na largura que tiver (abaixo). O
  projeto continua em `canvas_items` 1280×720 para o `main.tscn` sozinho e os testes; o `GameView` desliga isso na janela
  (`content_scale_mode`) e aplica a tela das Configurações (`Settings.fullscreen`: cheia ou janela;
  `Settings.pixel_perfect`: só ampliação inteira, com borda, sem o filtro; padrão: tela cheia e suave). Na pausa, o `Box` continua processando
  (`process_mode` ALWAYS; o `View` é PAUSABLE): parado, ele não repassava as teclas e o Esc não despausava
  (`tests/test_keys.gd`). O cenário tem a tela própria dele (`SceneView`, `scripts/ui/scene_view.gd`: um `TextureRect`
  com o `SubViewport` `View` na resolução da tela onde ele está: a janela, com o `main.tscn` sozinho, ou 1:1 dentro do
  `GameView`). (Testados e descartados: o cenário em 2x2 numa tela de metade da resolução; o jogo todo em 2x2 com a fonte
  Tiny5, branch `improve/0000-pixel-2x`; o jogo todo ampliado como imagem com "nearest", que deixava o texto feio a 1,5×;
  e um filtro de 2x2 por cima do cenário, com média, que borrava.) Sem linhas de
  varredura. A vista da janela muda com a noite: cada janela acesa da cidade apaga numa hora sorteada,
  sempre a mesma (`SLEEP`; algumas ficam acesas), e a porta da igreja apaga às 22h (`CHURCH_DARK`; o relógio da torre
  fica aceso). **Luz e vinheta lisas, sem camadas** (em degraus pareciam artificiais, a pedido do usuário): o brilho
  (`%Glow`) e a vinheta são degradês contínuos com filtro linear; o arco na parede e a poça na mesa são desenhados com
  a cor variando ponto a ponto (`Background._light_fan`), não em polígonos empilhados; **Clima noir**: fora da luz da luminária a sala fica fria e
  escura (`_draw_gloom`, `NOIR`: liso, crescendo da poça de luz na mesa para fora numa elipse larga, `GLOOM_IN`/
  `GLOOM_R`, sem borda marcada, a pedido: a mesa toda, com o relógio, fica na luz e a parede do fundo mais escura; o
  vidro da janela abaixo da persiana fica de fora, `_glass`), a luminária é mais forte no centro (arco, poça e `%Glow`) e
  da janela vem um brilho azul bem fraco (`_draw_window_glow`, `WINDOW_GLOW`; as faixas de luz da persiana na parede
  foram testadas e saíram a pedido). **Lá fora acontece coisa** (`Background._events`, tempos sorteados, sons vindo
  da janela): um carro passa na rua da vista com os faróis (`CAR_*`, som `car`; a luz deles varrendo a sala
  saiu a pedido, não parecia luz; na
  chuva, `car_wet`, com o chiado da água); gente passa a pé pela calçada de lá, várias ao mesmo tempo e às vezes
  em dupla (`_walkers`, `_walker`: cada um com o seu passo, altura e distância das fachadas; guarda-chuva na chuva e,
  sem ela, de chapéu ou não), em silhueta contra as luzes (`WALK_*`, `WALK_STEPS`, `_draw_walker`; sem som: os
  passos, de dentro do prédio, não se ouviriam, e saíram a pedido), cada vez menos das 18h às 22h (`WALK_FROM`/`WALK_UNTIL`) e, daí em diante,
  ninguém; **o homem do mistério chega andando** pela calçada (`MAN_FROM`), fica parado embaixo do poste da esquina
  15 min de jogo (de `Main.SHADOW_LEAD` a `SHADOW_LEAVE` antes da ligação desconhecida: sai para ir ligar;
  `Background.stranger`, na hora do dia) e volta andando por onde veio (`_man_x`, `MAN_WALK`; sai da
  hora do jogo, então pausa e pulo do relógio valem para ele); das 22h à meia-noite os carros ficam cada vez mais
  raros (`LATE_FROM`/`LATE_TO`, `LATE_EVERY`); o sino da
  igreja bate as horas de longe, logo depois do gongo da mesa (`toll`, `BELL_AFTER`, `BELL_GAP`, som `bell`); na
  chuva, o relâmpago clareia o céu e a vista em pulsos (`BOLT_*`, `_flash`) e acende na sala só o que a janela alcança,
  numa camada somada por cima de tudo (`_bolt_layer`, `_bolt_build`; a força é o `modulate`, o desenho fica): quase
  branco (`BOLT_LIGHT`; era um véu azul na tela inteira, até na frente da mesa comutadora), na parede do fundo, mais
  forte perto da quina, com a sombra do armário à esquerda dele (a caixa dele levada até a parede, `BOLT_DIR`), na
  frente do armário, na lateral da mesa comutadora e no tampo, a janela desenhada nítida com a cruz do caixilho
  (`BOLT_STEEP`); o que fica na frente (a mesa comutadora, os objetos da mesa: `_occ`, `_occ_board`; o tampo) sai do
  clarão (`_cut`). E o trovão vem depois
  (`THUNDER_AFTER`, mais fraco quanto mais longe, som `thunder`; perto, o vidro e a persiana chocalham, `RATTLE_NEAR`,
  som `rattle`); e um letreiro de neon HOTEL (a palavra é a mesma nos
  três idiomas) na vista, na fonte gravada da mesa, que falha de vez em quando (`_sign_on`; o T falha sozinho; ao falhar, estala baixinho, som `neon`, abafado pela
  distância e com o eco das fachadas), com o
  halo sem miolo para as letras aparecerem (`_light(..., core = false)`), o reflexo na rua molhada e um reflexo
  vermelho fraco na parede perto da janela (`SIGN_GLOW`). Os três entram no `_state`. O painel da mesa comutadora escurece frio nos cantos
  (`ROOM_DARK`); interface, papéis e painel de baixo não escurecem (precisam ser lidos); o céu da vista clareia liso
  para o horizonte e a luz do poste atrás da silhueta também é lisa. **O vidro da janela reflete a sala**
  (`_draw_reflection`, por cima da cidade e da silhueta, antes da chuva): a sala espelhada no plano do vidro e vista
  pela mesma câmera (`_proj` com x espelhado); de lado como ele está, só aparecem o canto da parede do fundo perto da
  quina, com o fim do arco de luz, e o armário se cair ali (`_cab_x0`); a luminária e a mesa ficam fora. Liso e
  acompanhando a luminária. A vista passa da borda de cima da tela e só aparece do horizonte (58%
  dela) para baixo: o que for desenhado nela tem que ficar ali. **Traços dos objetos em pixel art** (`_pixel_line`:
  um pixel por passo, com a espessura empilhada em cores, desenhado na tela e não na perspectiva torta do tampo): o
  lápis do caderno, o rio do mapa, as fendas do relógio e os filetes das listas. **Poeira no feixe da luminária**
  (`_motes`, `DUST`; desenhada a 30 quadros por segundo sem redesenhar a sala): grãos de um pixel em toda a área que a
  luminária ilumina (a do brilho `%Glow`, um círculo largo a partir do alto do meio da tela, que passa por cima da
  mesa comutadora; o arco na parede é estreito no alto e deixava sem poeira a parede acima dela), mais claros perto
  dela. Ficam na camada `%Dust` do Main (`Background.dust`, z 1, depois do
  `Layout`): acima da mesa comutadora (no cenário, ela cobria a poeira que passa na frente dela), fora do papel das
  ferramentas e nunca abaixo do fundo do tampo (o painel de baixo fica fora da sala). **Pingos** na chuva (`_drops`, `RAIN`): riscos de 1 px inclinados pelo vento (`RAIN_SLANT`)
  que cruzam o vidro em meio segundo (`RAIN_FALL`; o risco é o rastro do quadro, `RAIN_STREAK`), mais longos e claros os
  de perto e acesos perto dos postes (eram traços de 2 px que levavam 5 s para cair, como neve). **Gotas no vidro** na chuva (`_beads`, `BEADS`): paradas, de vez
  em quando pesam e escorrem com um rastro; o brilho delas é quente perto do poste. Só na parte do vidro que aparece
  (`_glass_from`: abaixo da persiana e da borda de cima da tela). **O painel de baixo fica fora da luz da sala**: é um
  menu, não parte do cenário; a vinheta (`Vignette`) termina onde ele começa (`offset_bottom`), e o brilho da luz de
  teto já fica só na tela do cenário. Não troque a base para 1920×1080 (tudo fica 2/3 do tamanho).
  **Disposição (cena + painel)**: a tela é uma mesa de trabalho. No alto da esquerda, o horário do turno num
  papel colado com fita na parede (`ShiftPlate`, variação `TapedNote`, com o horário e o botão Encerrar turno; era uma
  plaqueta de latão; a faixa dele, `TopLeft`, tem 52 px fixos) e, à direita dele, na parede acima da mesa
  comutadora, a placa esmaltada da companhia telefônica (`Background._draw_company_sign`, `SIGN_COMPANY`). O relógio da sala é um **relógio de flip na mesa** (`Background._draw_flip_clock`, o único da tela):
  caixa de baquelite creme numa base escura, reta, com a frente paralela à tela (`CLOCK`; `CLOCK_TURN` gira para os
  olhos uma fração do ângulo até eles, `_yaw`; foi 0,5: certo na conta, mas a frente descia uns 5° entre as horizontais
  da sala e o lado sumia, e parecia um relógio inclinado numa mesa plana; `_clock_box` desenha as faces viradas para os olhos, `_clock_xz`/
  `_clock_pt` giram os pontos), com fendas e botão niquelado do alarme no tampo, a
  rodinha de acertar no lado e duas plaquetas (horas e minutos, algarismos de 9×19 desenhados à mão numa folha de
  fonte, `DIGITS`) que viram quando a hora muda
  (`Background.minutes`, o Main atualiza; `_flip_step`, `FLIP_SEC`). A frente é montada reta numa imagem
  (`_clock_face`, `_flip_card`, `_card`) e posta coluna a coluna na perspectiva exata: cada coluna da tela é um raio
  dos olhos que acerta a frente num ponto e numa distância, e a coluna vai da altura de cima à de baixo ali (torta por
  transformação, os algarismos quebravam; um paralelogramo não batia com a caixa). Ao ouvido: a badalada de gongo a cada hora cheia (`chime`, `Main._hour`) vem do relógio
  (`Background.clock_x`) e a campainha de latão quando o turno pode ser encerrado (`shift_bell`), da plaqueta; embaixo
  dela a mesa comutadora (588×362), a faixa da prateleira (`Shelf`, 16 px: o encaixe do FONE, `%FoneSocket`, e os
  buracos dos cabos, `%CordTray`, com os plugs guardados em pé neles, na frente do painel, como numa mesa telefônica
  de verdade; os fios repousam na linha dos buracos, `Switchboard._floor`) e a faixa da frente do console (`%Desk`), com a
  **miniatura do painel de baixo** no meio (`%Mini`, `ConsoleMini`: a tela da conversa, as teclas e o rádio na
  disposição e proporção de verdade dos blocos do `PhonePanel`, copiando o estado: tela acesa com as falas em traços,
  teclas ativas acesas; o rádio peça por peça no lugar das do rádio de verdade, `Radio.parts`, com as mesmas linhas da tela quebradas na largura dela, o histórico apagado em cima e a mensagem de agora embaixo, `Radio.lines`, `_wrap`; o painel de baixo é a vista de perto dela). Ela não tem `z_index`
  próprio: a mesa (z 1) desenha o plug e o fio puxados para baixo por cima dela, como faz com o painel de baixo (com z
  1, eles passavam por trás da miniatura, a pedido saiu). A coluna da
  direita (cresce com a largura) tem a dica do manual no alto (`%Hint`, um papel datilografado colado com fita na parede, `TapedLabel`, com "MANUAL" carimbado em vermelho; sem dica, o papel some mas o lugar fica; no pé, ela ficava em
  cima dos objetos da mesa) e as ferramentas (`Tools`: abas em cima e, no `%Body`, o papel da ferramenta aberta; guardadas, a
  janela aparece). O papel sai do objeto da ferramenta na mesa (`Tools.origin` = `Background.prop_rect`: pequeno, em
  cima dele, e cresce até o lugar; ao guardar, volta), tem a forma e o material do objeto (`PaperDeco`, a moldura em pixel art guardada por
  tamanho, `_cover`: a capa de papelão mostarda da lista com o grão e o friso, como a da mesa; a capa de couro do caderno, com as
  tiras dos registros pendentes saindo de cima, `pending`; a tábua da prancheta com o prendedor niquelado, `_clip`, e o cabeçalho
  datilografado com o fio vermelho, `HEAD_Y`/`CallLog.HEAD`; o vinco do jornal; a sanfona e os vincos do mapa são do próprio
  `CityMap`, para ficarem abaixo da ficha de despacho), o papel na cor do objeto (`Tools.PAPER`, a aba aberta junto) e a luz
  da luminária por cima, lisa, mais clara perto dela e escurecendo quando ela pisca (`PaperDeco.light`, `LIGHT_*`; o Main
  passa `Tools.light`); as abas de índice da lista são tiras de papel como as que marcam páginas nas listas da mesa
  (creme; a aberta, vermelha) e o caderno tem a pauta e a margem do caderno da mesa. Aberto, o cenário atrás escurece e ganha a sombra dele (a mesa comutadora e o painel não). Embaixo de tudo, na
  largura toda, o painel do operador (`PhonePanel`, 150 px: a tela da conversa, as teclas e o rádio, nessa ordem), um console embutido na frente da mesa (a madeira de borda a borda logo abaixo
  do tampo, `PhonePanel._draw`; os blocos `HudPanel` são telas e chapas encaixadas; a tela da conversa tem vidro e
  apaga sem ligação, `ScreenGlass`, mas fica esperando como um terminal antigo: "Aguardando chamada" bem apagado
  e o cursor piscando, `idle`, `CONSOLE_IDLE`; o rádio mostra acima da mensagem de agora as anteriores, cada uma mais
  apagada, `Radio.HISTORY`, `_archive`, as que couberem). A altura útil é 700 px: as colunas pedem 540 (a da esquerda, exata) e o
  painel 150; passando, a tela inteira sobe e a plaqueta sai por cima. O `Background` (cenário em camadas, em pixels de 1x1 como a interface: as contas em unidades de 2 px e os detalhes finos em `PX`/`_p`; desenhado no `SceneView`, uma tela própria na resolução da janela, que repassa o mouse a ele, `pointer`/`prop_at`/`leave`, e desenha por cima o contorno e o nome do objeto sob o mouse, `draw_hover`) estica
  parede e mesa até a borda, como o canto de uma sala visto de quem está sentado à mesa. **Uma câmera só**, em
  perspectiva de um ponto: o ponto de fuga (`_vp`) fica em `VP_AT` do espaço da mesa, da mesa comutadora à
  quina (perto dos objetos: a inclinação deles cresce com a distância a ele; preso à largura da tela, numa janela
  larga ele fugia dos objetos e as listas apareciam bem de lado; no meio exato das fileiras, a parede da janela
  entrava pela mesa e espremia os objetos). **A sala se distribui na largura que tiver**: entre a mesa comutadora e a
  quina, o armário (`CAB_W`) e o lugar do cartaz (`POSTER_W`) com a mesma folga entre eles; os objetos da mesa em duas
  fileiras de ponta a ponta entre a lateral da mesa comutadora e a parede da direita (`_row`, `WALL_PAD`), com a mesma
  folga entre eles. Os lugares do cartaz e do jornal ficam guardados mesmo sem eles, para nada mudar entre as noites.
  (Presos a uma ponta só, sobrava mesa vazia numa janela larga; presos a pontas diferentes, o relógio caía em cima do
  jornal em 1280 e o armário entrava atrás da mesa comutadora.) e `EYE` acima do fundo do tampo, dentro da tela, na altura da janela (era logo acima
  da tela: a mesa vista mais de cima, mas a parede da janela ficava a 44 cm da cabeça e a janela descia uns 40°; com
  os olhos mais baixos, o que fica longe do ponto entorta mais: a inclinação de um lado que foge é a distância ao
  ponto na horizontal dividida pela distância na vertical, e só depende da tela); `_proj`/`_p3` levam um ponto da sala (x, y a
  partir dos olhos, z a distância; a parede do fundo a `Z0`) para a tela. **A câmera são os olhos do operador
  sentado**: `SEAT_EYE` (45 cm acima do tampo) e `SEAT_BACK` (110 cm até o fundo do tampo; a frente do tampo fica sob o
  console) dão a distância focal, `Z0 = EYE × SEAT_BACK / SEAT_EYE` (a tela já fixa o ponto de fuga e o fundo do tampo;
  só a focal estava livre). Com o antigo 330 a mesa era vista de cima como por alguém em pé (~38° para baixo; sentado,
  ~22–29°), e toda profundidade absoluta saía exagerada (o relógio torto, a lateral da mesa comutadora larga). Os
  objetos chatos têm a profundidade em fração do tampo (`_deep`) e não mudam na tela; com a focal certa, as medidas
  deles na sala ficaram as de verdade (a prancheta mais funda que larga). Na sala: a parede do fundo (sem rodapé nem
  linha escura embaixo: com elas parecia um chão), com um conduíte de ferro levando os fios do alto do painel da mesa comutadora
  para o teto, com a caixa de passagem (`_draw_conduit`, no vão entre ela e o armário), e um armário
  de aço de chão (`_draw_steel_cabinet`, `CAB_*`; a mesa esconde a base; ~1,5 m, o alto acima dos olhos, então o tampo
  não aparece; venezianas em cima e embaixo, o puxador no meio da altura, um amassado e riscos perto do pé; entreaberto, o vão tem fundo, a parede de dentro virada para quem olha, prateleiras até a mesa, as de
  cima mostrando o lado de baixo e as de baixo o tampo, e pastas em pé, e a porta aberta mostra o painel de dentro e a espessura); a parede da direita, entrando para o fundo
  a partir da quina (`CORNER` da área das ferramentas, `Background.window`), mais clara (virada para a luminária),
  com a janela vista de lado (`_draw_side_wall`, `_side_pt`: guarnição, caixilho e persiana na perspectiva da parede;
  o vão tem a espessura dela, `WALL_D`: sair da parede é andar na horizontal da tela, então aparecem o lado de dentro
  do batente de longe e o fundo do vão (a tábua do peitoril indo até o trilho de baixo do caixilho; escuro, parecia
  um buraco; o que passa do batente de perto é cortado; fora do vidro, o escuro da sala deixava o peitoril e a
  guarnição de perto quase pretos, então a luz de fora os clareia por cima do escuro, `_sill_lit`; a ponta de perto da
  tábua tem a face dela; o vaso que ficava nela saiu, a pedido), o vidro fica do lado de fora e o batente de perto esconde uma tira dele; o
  peitoril de dentro é uma tábua saindo para a sala, `SILL_D`; o peitoril fica `WIN_SILL` cm abaixo dos
  olhos e o alto `WIN_TOP` acima deles, e a travessa do caixilho quase na altura deles; a janela e o armário são medidos
  em cm a partir dos olhos, `_cm`, e acompanham a câmera quando ela muda; a vista da cidade é desenhada de frente num vidro fora da tela, `_vport`, e só recortada
  pelo vidro: está longe e não entorta com a janela; o horizonte dela fica na altura dos olhos); a mesa, afastada da
  parede (`DESK_T`), com o fundo do tampo atrás da mesa comutadora (`BOARD_SINK`), a borda da frente logo abaixo da
  faixa de mesa (`Background.desk`) e a ponta na parede da direita, numa
  linha que foge para o ponto de fuga. A luz vem de cima, do meio da tela, de uma luminária que não aparece (o
  desenho dela foi tirado a pedido do usuário: `_lamp_x` no meio, `LAMP_Y` acima da tela); ela dobra na quina: na
  parede é o arco do cone (`_draw_wall_light`, `WALL_GAP`), na mesa a poça; o que está na frente da parede faz sombra nela, ampliada
  a partir da luminária (`_cast`); a luz da rua entra pela janela e cai na mesa (`_draw_street_light`): o vão abaixo da
  persiana projetado no tampo, descendo para dentro da sala (`STREET_LIGHT`; mais inclinada, era um quadrado pequeno
  para a janela grande), um pouco longe da parede (o peitoril faz sombra) e só onde há mesa; grande, bem lisa e
  espalhada além da janela, e por cima dos objetos (eles ficam na luz também). Na mesa, ao alcance do
  operador, os objetos que abrem as ferramentas (`prop_clicked(id)` → `Tools.set_tab`; `_props`, `_has_point`: o
  clique só vale sobre eles e não com papel por cima): listas telefônicas (1: três volumes desencontrados, a lombada com os filetes dourados e a etiqueta do volume,
  o miolo com as folhas em linhas finas, posto pixel a pixel como a capa, `_art_pages`, mais sujo junto das capas, e tiras
  de papel marcando páginas; a capa de cima com o título dourado em
  baixo-relevo, o fone da companhia, a etiqueta com o ano, a marca de uma caneca e a ponta dobrada, `_art_book_cover`), mapa dobrado em sanfona (2: o mapa aberto em miniatura, `_art_map`, com as mesmas
  folhas, as dos bairros atendidos, e o papel na proporção delas: quarteirões no tom do bairro, casas e árvores, lugares
  de telhado de barro, praça, zona rural, divisas, o selo e as dobras em luz e sombra; sem nomes, que nesse tamanho
  seriam ruído), caderno aberto (3) e
  prancheta do registro (4), mais a caneca, postos por fração da profundidade do tampo (`_at`, `_deep`: ficam no
  tampo seja qual for a câmera) e, na largura, a partir da lateral da mesa comutadora (`_side_x`), em duas fileiras
  com folga entre eles: atrás, listas, caderno e o relógio de flip com a caneca na frente dele; na frente,
  mapa, prancheta e jornal (numa tela mais larga, a folga sobra perto da janela). **Cada um fica num lugar da sala e passa pela câmera** (`_draw_desk_props`:
  tamanho, escorço e o lado que aparece saem da conta; `_box` dá os cantos; nos objetos chatos (caderno, mapa,
  prancheta, jornal e a capa da lista de cima), `_flat` desenha o tampo de frente numa imagem do tamanho que ele tem na
  tela, `_top_xf`, e `_project` o põe na perspectiva pixel a pixel pela homografia, `_homography`, como a frente do
  relógio, guardado até o desenho mudar; torto por transformação, o desenho esticava e entortava os pixels, uma linha
  de 1 px virava 0 ou 2, e destoava do resto do jogo; o que não pode entortar, como o lápis, o alfinete e as tiras do
  caderno, vai por cima já na tela, `_tex_pt`; **risco fino também vai na tela**: texto, pauta, colunas e vincos do
  jornal, da prancheta e do caderno (`_newspaper_print`, `_clipboard_print`, `_notebook_marks`) com `_ink` (um risco
  em pixel art) nas alturas de `_rows` (a cada N px da tela, não do papel): no papel, linhas de 1 px a cada 2 viravam
  moiré e zigue-zague na perspectiva; área cheia, como a foto do jornal, pode ficar no desenho; papel tem 1 px de beira
  e a prancheta, 2 (com mais, pareciam tábuas); os desenhos são `_art_*`), **cada um girado uns graus, como largado na mesa**
  (`_turned` gira os cantos em volta do meio, `_faces` dá as faces de pé viradas para os olhos; o `yaw` de cada um em
  `_flat` e nas listas, cada volume para um lado: todos retos e em fileira, a mesa parecia montada), desenhados em 1x1 (sem contorno preto: torto pela perspectiva, serrilhava; as faces se separam pela luz, `_poly`; sombra apontando para longe da luminária, em degraus: penumbra, sombra e o contato escuro colado na base, `_desk_shadow`; e cada um escurece ponto a ponto quanto mais longe da poça de luz, liso dentro do próprio objeto (os cantos de cada face pela distância deles, `_shade`, `_dim`, `_shaded`, `_pool`, `SHADE_MAX`; com um tom só por objeto, a troca entre eles era brusca), também quando a luminária pisca), do fundo para a frente; a legenda sob o mouse é do `SceneView`, na resolução da interface. **A mesa comutadora é um móvel só** (`_draw_switchboard`,
  como uma mesa telefônica de verdade): embaixo, o console, cuja frente é a faixa da miniatura do painel (a
  madeira em volta dela, com a plaqueta de latão de um lado, os botões de volume e sintonia do outro e os parafusos;
  a prateleira tem veios e o friso de latão na beira) e cujo alto é a prateleira, com o FONE e os cabos em pé nos buracos (a mesa desenha); no fundo dela, num rodapé e com a sombra
  de contato, o painel (`Background.board`). Painel e console têm a mesma largura na sala, então o console, mais
  perto, sai mais largo na tela (a esquerda passa da borda): é o que os alinha na câmera. A lateral em L (o console
  até o fundo do móvel e o painel em cima, raso como nas mesas de verdade, `BOARD_D`: fundo, ele mostrava uma lateral
  e um tampo grandes demais para quem senta logo na frente) foge para o ponto de fuga; com os olhos acima do painel, o
  tampo dele aparece. (Antes eram caixas soltas na frente do painel, com
  tampos enormes que cobriam o pé dele: parecia fora da mesa e desalinhado.) O tampo (`_draw_desk`): `PLANKS` tábuas
  da mesma largura espaçadas pela câmera, sem juntas (com juntas parecia assoalho), a borda da frente com a
  espessura dele e a poça de luz da luminária, um círculo de `POOL_R` no tampo embaixo dela que treme com ela
  (`lamp_level`, como o arco na parede e a luz no armário). **O estado do jogo nos objetos**, para ler de relance: uma
  tira de papel saindo do caderno por registro pendente (`pending`) e uma folha nova na
  prancheta quando uma conversa termina com o registro guardado (`unread`; `CallLog.filed`/`unread_changed`, o Main
  chama `filed` em `end_call`). (O alfinete do mapa piscava e brilhava com uma emergência em andamento; saiu a pedido:
  um alfinete não acende. Ele fica parado no mapa, e a emergência é avisada pelo rádio.) **Jornal da manhã** (da segunda noite em diante): o jornal dobrado na mesa (`news`,
  `Main.set_news`) abre a primeira página na área das ferramentas (`NewsView`, `Tools.news`, id "jornal", sem aba) com
  as manchetes da noite anterior; `ShiftReport.news()` sorteia a manchete de cada emergência uma vez (o relatório do
  fim da noite e o jornal dizem a mesma; `headline` traduz na hora) e o `Progress` a guarda (`news`). A página é a do jornal da mesa de perto
  (o papel-jornal, o fio duplo, as colunas de letra miúda, `_greek`, e a foto da cidade em retícula, `_photo`); cada noite
  pode trazer a foto, a legenda e as matérias das colunas dela (`Night.news_photo`, `news_caption`, `news_stories`: uma por
  coluna, a primeira linha é o título), e o que ela não trouxer sai como sempre. **A sala muda ao
  longo das noites**: `GameContent.room` (`RoomChange`, `data/room/`: `detail`, `requires`, `from_night`) liga
  detalhes do cenário (`Background.details`, `DETAILS`: cartaz da quermesse, número anotado colado no armário, armário
  entreaberto com as pastas) pelos marcadores do roteiro, já no meio da noite (`Main._update_room`, refeito a cada
  `flags.changed`; o setter de `Main.flags` religa); o calendário do armário risca um dia por noite (`night`). Na
  primeira vez que cada sinal da mesa aparece (tiras, folha nova), uma dica do manual explica, uma vez no
  jogo todo (`Main._teach`: o "já viu" fica nos marcadores salvos; espera o tutorial acabar). Sob o
  mouse: contorno, o nome da ferramenta e o dedo. **O cenário só se redesenha quando algo que ele mostra
  muda**, e o que muda sozinho fica fora do desenho da sala (redesenhá-la custava ~20 ms e ela se redesenhava 3 a 4
  vezes por segundo parada; ver a história 84): a sala (`Background._state`: o lugar das peças da interface, a
  luminária, o estado nos objetos, o clima; parado, fica o desenho guardado); por cima dela, a camada `_over`
  (`_draw_over`, com o estado dela no `_process`: o escuro da sala, o que entra pela janela, o neon, o
  escuro e a sombra atrás do papel e as luzes da sala no `Bloom`, que a sala junta em `_glows` e a camada acende
  cortadas onde o papel está, quadro a quadro, `_paper`, `_light`); a do relâmpago (`_bolt_layer`: o que ele acende é
  medido com a sala e só a força muda, no `modulate`); a frente do relógio, uma textura trocada no lugar
  (`_clock_face`: a sala desenhada com ela mostra a hora nova sem se redesenhar); e a vista da janela, a 30 quadros por
  segundo no vidro (`_vport`, `UPDATE_ONCE` a cada quadro dela), em duas camadas: a de trás (`_back`,
  `_draw_view_back`: céu, cidade, rua, fachadas) só quando muda (`_back_state`: a hora, a luminária, o neon, o
  relâmpago, as estrelas piscando) e a da frente (`_draw_city_front`: o letreiro, quem passa, os postes, o homem, o
  carro, a névoa; depois o arbusto, o reflexo e a chuva) a cada quadro. A tela do cenário (o `View` do `SceneView`) só
  é desenhada quando algo nela muda (`Background._show`) ou de tamanho (`SceneView._fit`). Quem acrescentar ao desenho
  algo que muda precisa pôr isso no estado da camada certa (e, na sala, no `_state`). Lá fora (`_draw_city`): céu do clima, morros, casas
  sorteadas sempre iguais (`_build_city`, semente fixa),
  a igreja com o relógio aceso, a rua com o poste (a silhueta do mistério fica contra a luz dele) e o chão molhado na
  chuva. **A vista: uma cena 3D simples projetada no vidro** (pedido do usuário: pensar a cena antes,
  nunca a perspectiva elemento por elemento; `OUT_*`): uma câmera dentro do prédio, na altura de quem está na janela
  (`OUT_EYE` m acima da rua; o horizonte passa ali; não é vista aérea), olhando de frente para uma rua que passa ao
  lado do prédio e continua para os dois lados. Um ponto de fuga só, no meio do horizonte: para ele fogem só as linhas
  que vão para longe (a rua do cruzamento e as paredes dela); a rua, os meios-fios e as fachadas de frente ficam na
  horizontal e as paredes na vertical, com a base apoiada na calçada. A diagonal da janela é só do primeiro plano (o arbusto plantado junto da nossa parede também: a copa sobe do
  peitoril posta pela parede da sala, `_side_pt`, não pela câmera da vista, `SHRUB`, `_draw_shrub`) e não
  entra na conta, e nada da vista encosta no nosso prédio: a nossa calçada, o nosso meio-fio e uma faixa de pedestres
saindo deles diziam para que lado a nossa parede vai, contra a sala (a parede parecia torta); perto, a rua some na
sombra do nosso prédio, lisa. Tudo em metros e no tamanho de verdade (`_o(g, x, z, h)`: `x` ao longo da rua, `z` a distância dos
  olhos, `h` a altura; `_patch` um retângulo no chão). De perto para longe (`STREET`): o
  asfalto (manchas, desgaste dos pneus, grão, poças espelhando o céu e a faixa tracejada), o meio-fio de lá (com a face virada para nós), a calçada de lá com os postes (`FAR_LAMPS`, a luz deles
  no chão) e o homem embaixo do da esquina (`MAN_X`, `_draw_stranger`: 1,8 m, chapéu e casaco; chega e sai andando), em silhueta contra a
  vitrine acesa de um bar (`_draw_shopfront`), os prédios de frente
  (`_houses`, `_draw_far_house`: o de tijolos na esquina, à direita do cruzamento, `CROSSING`; o hotel com o letreiro e a marquise acesa
  sobre a porta, `HOTEL_X`, `_draw_marquee`, do outro lado; janelas fundas, com a sombra da verga e o peitoril, e a
  luz dos postes lavando as fachadas), a rua do cruzamento indo embora entre paredes (`_canyon`, `_draw_canyon_wall`, com os
  postes dela diminuindo e a névoa clareando para o fundo) até a igreja no fim (`_church_pos`, `CHURCH_K`) e, bem longe, a cidade em duas fileiras na
  névoa. Na chuva, o asfalto molhado espelha as luzes em riscos verticais (`_draw_wet`). Na névoa (`_draw_fog`, por cima da rua e do
  outro lado, atrás do arbusto): um véu liso mais grosso rente ao chão (`FOG_VEIL`, `FOG_GROUND`), fiapos largos e lisos
  atravessando a rua com o vento (`FOG_WISPS`) e as luzes espalhando nela (halo e cone de laterais lisas em cada poste, o
  vermelho do neon); as faixas retangulares que havia no vidro pareciam defeito. O carro (`_draw_car`, um só)
  passa pela mão de lá (`CAR_Z`, `_car_x`), apoiado no asfalto: sombra de contato, facho dos faróis no chão, lado,
  teto e capô vistos um pouco de cima, a frente ou a traseira virada para nós. O brilho da luz de cima (`%Glow`, centrado no alto, liso) fica dentro da tela do cenário, logo depois do
  `Background`: ilumina a sala, não a interface; acompanha o tremor dela. **Para trocar por PNG**: `wall_art`, `window_art` e `desk_art` entram no lugar do desenho daquela camada
  (o clima continua por cima da janela). Guardadas, as abas das ferramentas somem (os objetos da mesa já dizem o
  mesmo; o espaço delas fica, para nada pular); com uma aberta, as abas de papel (`TabButton`) aparecem junto com o
  papel, para trocar de ferramenta. O caderno da mesa mostra o selo dos registros pendentes (`Background.pending`). Nos testes, o clique num objeto da
  mesa é `background.pointer(evento)`.
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
  os blocos do halo cobertos por ele somem (`_cut`, guardado; plug parado não refaz).
- Pixel art desenhada em `_draw()`; cores e fontes em `pal.gd` (`Pal.*`). **Área cheia em `draw_primitive`, não em
  `draw_polygon`**: cada `draw_polygon`/`draw_colored_polygon` é uma chamada de desenho (e cria um polígono a cada
  redesenho); `draw_primitive` (até 4 pontos) seguidos viram uma só. O cenário tem `Background._fill`/`_poly` (o
  quadrilátero inteiro; o resto, em triângulos); a sala passava de 2000 chamadas por quadro. **Os materiais dos objetos da mesa** (capa da lista,
  couro do caderno, tábua e folhas da prancheta, papel-jornal, papel e tons do mapa, níquel, o vermelho do formulário) são
  constantes do `Pal`, usadas pelo objeto (`Background._art_*`) e pelo papel aberto dele: o que muda numa ponta muda na outra. **Uma fonte só, de pixel: Departure Mono**
  (`Pal.ui` e `Pal.mono` são a mesma; continuam separadas pelo papel), **só em múltiplos de 11** (o estado de cada linha na mesa não usa
  ela: em 11, "conectada" não cabe na coluna, e em 8, fora da grade, borrava; é uma fonte de pixel própria, maiúsculas
  de 3×5 gravadas no painel, `PixelArt.TINY`/`TINY_ACCENTS`/`tiny`, com os acentos dos três idiomas): 11 (texto, números da lista), 22
  (títulos, visor, bilhete), 33 (títulos de tela), 44 (relógio). Importada com suavização (a janela
  menor que 1280×720 não apaga os traços; sem ela, a 1,5× as letras saíam irregulares), sem hinting e sem sub-pixel. Texto em
  desenho com escala (mapa) sai fora da escala (`CityMap._t`).
- **Idiomas** pt_BR (padrão), en, es. Interface/código: **enum `T.Key`** (`scripts/t.gd`, GERADO) +
  `translations/ui.csv` (`chave,pt_BR,en,es`); use `T.text(T.Key.X)` (com valores: `T.text(T.Key.X) % n`), nunca
  `tr("texto")` com literal. Cenas: o `text` do Label/Button é a chave (auto-tradução do Godot). Falas dos roteiros
  (`data/`): português no Resource, `tr()` na hora de mostrar, traduções em `translations/content.{en,es}.po`
  (nomes próprios repetem o original). Depois de mexer em textos: `Godot --headless --path . -s
  tools/update_translations.gd` (gera o enum e mescla os .po; campos fora da extração em `SKIP`). `Settings.set_locale`
  troca o idioma (o jogador escolhe em Configurações; padrão pt_BR; `-- --lang=en` força). Em funções estáticas, traduza com `TranslationServer.translate()`.
  Lacunas dos moldes também se traduzem: `tr(spoken)`, `tr("d" + spoken)`, `tr("pr" + spoken)` têm entradas próprias
  no .po. Texto que já chega traduzido num Button/Label dinâmico: `auto_translate_mode = DISABLED`.
- Entrada: ação `cancel_plug` no Input Map (Esc e botão direito) devolve o plug que está na mão; ação `pause` (Esc, P)
  pausa o turno quando não há plug na mão (`Main._unhandled_input`). Atalhos do telefone: ações `answer_call`
  (Espaço), `transfer_call` (Tab), `hang_up` (X), tratadas em `PhonePanel._input` **antes da interface** (Espaço e
  Tab também apertam o botão em foco e passam o foco; por isso não dá para usar `Button.shortcut`). Só com o botão
  ativo; na pausa não valem; com um campo de texto em foco a tecla fica com ele. Cada tecla é uma chapa de metal
  parafusada com a etiqueta de latão no alto, onde fica o atalho (Label `Key`; "Espaço" traduzido, `KEY_SPACE`), e a
  tecla baixa, em relevo, num poço no meio do espaço embaixo dela (`KeyCapStyle`, `WELL_H`; as margens de conteúdo põem
  o nome no tampo). Ferramentas: ações `tab_directory`/`tab_dispatch`/`tab_logbook`/`tab_call_log` (1 a 4),
  tratadas em `Main._unhandled_input` só durante o turno (`Main.TAB_KEYS`, `Tools.toggle`: a tecla da ferramenta aberta a
  guarda; Esc também guarda, antes de pausar); o número fica no canto da aba. No código, `Tools.set_tab(id)` abre.
- **Pausa e configurações**: `PauseMenu` (`scenes/ui/pause_menu.tscn`, z 4, `process_mode` ALWAYS) usa
  `get_tree().paused`. **Todo `create_timer` do jogo leva `false` no 2º argumento** (senão continua contando na pausa);
  o `Sfx` roda sempre (ambiente segue, `Main.pause()` cala a campainha e `_update_bell` a devolve). Configurações no
  autoload `Settings` (`user://settings.cfg`): `locale`, `volumes` por barramento, `fullscreen` e `pixel_perfect` (a
  tela, que o `GameView` aplica), `text_speed` (`char_delay()`
  multiplica o tempo por letra na conversa e no rádio); sinal `changed`. `set_*` vale na hora (prévia) mas só
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
  - `tests/test_penalties.gd`: consequências (perdida e retorno, número errado, registro, despacho errado,
    emergência sem despacho, espera longa, informação errada) e o relatório. Relógio parado; retornos tocados à mão.
  - `run.sh` começa com `--import`: **`class_name` novo só existe depois de reimportar** (sem isso, parse error).
  - `tests/test_shift.gd`: robô que joga o turno inteiro e imprime métricas (máx. simultâneas, % com 2+/3+,
    % sem cabo livre, perdidas, maior silêncio); `run.sh` roda com `--seed=1..3`, um turno `--clumsy` (deixa de atender 1 em 3),
    a noite 2 (`--night=2`) e um turno `--human` (5 s de jogo por ação, como uma pessoa: **é este que mede se o ritmo
    cabe**; o robô normal é rápido demais). No `--human` o despacho passa pelo cartão (`_card_step`: pensar, marcar,
    esperar imprimir, perfurar, levar ao transmissor e esperar a leitura), e o estágio anotado é o da hora do envio.
  - Rode depois de qualquer mudança em agenda, fim de ligação, mesa ou cabos. `run.sh` também joga um turno em
    `--lang=en` e outro em `--lang=es`; o teste de fluxo confere chaves, lacunas e cenas (`_check_translations`).
- Semente fixa: `Godot --path . -- --seed=123` repete a agenda do turno (sem `--seed`, é aleatória).
- **Painel de debug** (F1, ação `debug`; `DebugPanel`, `scenes/ui/debug_panel.tscn`, nó `%Debug` do Main, z 5): só em
  build de debug (editor ou export de debug; no release ele se apaga). Toca ligações na hora (qualquer tipo; emergência
  escolhida, com o caso sorteado), pula estágio ou congela a barra (`Urgency.frozen`), mostra o que a emergência
  exige (contado e real), velocidade 1–8×, pula o relógio, troca o clima na hora (`Main.set_weather`), encerra o turno, troca de noite (`_go_night`: troca o Main por um novo na noite anterior/seguinte, no mesmo pai, dentro da tela do `GameView`; posto na raiz, saía na resolução da janela e quebrava o layout; sem ler nem
  gravar o progresso, para testar a entrega dos setores), libera viaturas (`Dispatch.reset`; `_gen` cancela
  as viagens em andamento), registra pendências, limpa advertências e apaga o progresso. Mesa de som: toca cada som de `Sfx.VOL` com
  um controle de volume que vale na hora (`Sfx.vol`, a cópia em uso) e "Copiar VOL" põe a constante ajustada na área de
  transferência, para colar em `sfx.gd`. Cada seção tem "Limpar" e o
  topo tem "Restaurar tudo" (`Main.drop` tira uma ligação sem caderno, advertência nem retorno; a mesa é zerada antes de
  tirar os cabos para nada contar como conversa cortada; `Notebook.reset`). Textos fixos em português (ferramenta, não interface). Ele só usa funções públicas do Main (`free_line`, `set_weather`,
  `start_ending`, `cancel_dest_ring`, `drop`) e do relatório (`ShiftReport.forget`), para não quebrar quando o Main mudar.
- Captura de tela: rodar SEM `--headless` e salvar `root.get_texture().get_image()`.
- **Sem tela, a vista da janela não é desenhada** (`Background._headless`): com `--fixed-fps` e o tempo acelerado,
  ela era redesenhada a cada quadro e virou 2/3 do tempo de um turno do robô (27 s em vez de 9). Quem acrescentar
  desenho pesado que roda a cada quadro, meça um turno (`--test=shift --seed=1`).

## Exportar (executáveis para testar fora do editor)
- Presets em `export_presets.cfg`: Windows, macOS (universal, assinatura ad-hoc, sem notarização) e Linux; saída em
  `build/` (fora do git). Templates do Godot 4.6.2 ficam em `~/Library/Application Support/Godot/export_templates/`.
- `Godot --headless --path . --import` e depois `Godot --headless --path . --export-release "Windows" build/windows/ProjectSwitchboard.exe`
  (idem "macOS" → `build/macos/ProjectSwitchboard.zip`, "Linux" → `build/linux/ProjectSwitchboard.x86_64`).
- **`editor/export/convert_text_resources_to_binary=false`**: a conversão para binário esvaziava todo `PackedStringArray`
  do conteúdo (falas, motivos, quem liga) e o jogo exportado quebrava ao montar a agenda. Não religue sem testar.
- Teste o exportado: `Godot --headless --path . --export-pack "macOS" x.pck` e `Godot --headless --main-pack x.pck --quit-after 600`
  (zero `ERROR` no log). Os testes normais rodam pelo projeto e não pegam problema de exportação.

## Arquivos
- `scenes/main.tscn` + `scripts/main.gd` (`Main`) — orquestra o turno: relógio, quando cada ligação da agenda toca
  (`_run_schedule`), o que cada plug significa para as ligações, fim de ligação, ligação desconhecida e final.
  Constantes de ritmo no topo.
- `scripts/schedule.gd` (`Schedule`, RefCounted, sem cena) — monta a agenda da noite (`Schedule.build(night, LAST_CALL)`:
  roteiro, desconhecida e sorteadas; `info_call()`); o teste de fluxo confere a montagem sem jogar o turno.
- `scripts/urgency.gd` (`Urgency`, nó filho de Main) — a barra de agravamento da emergência em andamento (`tick`, `told`).
- `scripts/supervisor.gd` (`Supervisor`, nó filho de Main) — consequências: advertências no `Main.report`, retornos,
  desistência em espera, conferência do despacho e do caderno. O Main só avisa o que aconteceu.
- `scripts/conversation.gd` (`Conversation`, nó filho de Main) — como cada tipo de ligação se desenrola:
  `say`/`op`/`choose`/`wait` e os roteiros de transferência, informação, emergência, trote e ligação desconhecida.
- `scripts/model/fleet.gd` (`Fleet`) — viaturas e emergência em andamento (regras do despacho, sem tela).
- `scripts/model/phone_call.gd` (`PhoneCall`) — uma ligação: roteiro (`data`) + estado; emite sinais que o telefone
  escuta. `scripts/model/exchange.gd` (`Exchange`) — **dono único** do estado das linhas e destinos (enums `Line`, `Dest`).
- `scripts/data/*.gd` — classes de Resource do conteúdo; `scripts/game_data.gd` (`GameData`) — acesso ao
  `content.tres` (`CONTENT`, `entry()`, `street()`, `transfers()`, `pick()`...).
- `scenes/ui/*.tscn` + `scripts/ui/*.gd` — painel do operador (`PhonePanel`, blocos `HudPanel`: a tela da conversa,
  com as últimas falas que couberem, `_fit`, `shown_lines`, o aviso, `%Warn`, que também recebe o que ia no visor,
  `flash`, as opções e a barra de agravamento; as teclas; e o rádio, `PhonePanel.radio`. O bloco da ligação em foco
  com o visor e o do destino e das outras linhas saíram a pedido: a mesa já mostra), `FoneSocket`, registro das conversas
  (`CallLog`, ferramenta 4: tudo o que foi dito com o FONE na linha, por ligação; o Main chama `track` quando ela toca), rádio, abas (`Tools`) com lista
  (`PhoneBook`), mapa e despacho (`Dispatch` + `CityMap`, dono das unidades e da ocorrência) e caderno
  (`Notebook`, fila de ocorrências); `Intro`, `Ending`; widgets desenhados (`Switchboard`,
  `Background`, `Bevel`).

## Modelo da mesa (scripts/ui/switchboard.gd)
- Tomadas por id inteiro: **1–10 entradas**, **11–20 saídas** (linha + 10), **destinos = o próprio número** (101–399,
  exceto 190/192/193, que vão pelo despacho). Destinos em três bancos de fábrica, A | B | C, rotulados pela faixa de
  numeração (100–199 | 200–299 | 300–399, `SECTOR_ORDER`, duas fileiras cada, `_layout_dests`/`_slots`; a mesa não
  fala em setor). O banco de um setor que ainda não é do operador fica sob uma chapa com a letra dele (`_draw_plate`:
  A e B; o C, do setor 3, nunca é tampado; chapa lisa (o escovado saiu a pedido), a letra estampada em relevo, o aviso `BOARD_PLATE_NOTICE`
  pintado com estêncil e riscos de chave de fenda em volta dos parafusos) e as tomadas dele não existem para o clique.
- `ends[]`: tomada de cada ponta (-1 = na base). **Ponta 0 = FONE** (cabo verde, encaixe `FoneSocket` na prateleira, só
  entra em entradas). **Pontas 1..2*PATCHES = cabos de conexão** (vermelho, azul, amarelo em `CORD_COLORS`; independentes; `mate(e)`
  dá a outra ponta; uma ponta na saída, a outra no destino). `PATCHES = 3`.
- `setup(exchange, socket, tray)` liga a mesa ao estado, ao encaixe do FONE e à faixa dos buracos dos cabos (lugares
  na prateleira, fora do retângulo dela: `socket_rect`, `tray_rect`; o clique vale neles, `_has_point`). Os buracos
  ficam no alto da prateleira (`hole`, `SHELF_HOLE_Y`, `FONE_HOLE_X`; aro de latão achatado pela perspectiva,
  em pixel art, `HOLE_ART`, `draw_grommet`; dois por cabo, a 30 px um do outro), os plugs guardados em pé neles (`home_pos`) e, só embaixo do encaixe do FONE, o nome
  gravado na madeira (`engrave`, `FoneSocket`; os "CABO 1/2/3" saíram a pedido: a cor diz qual é o cabo); o buraco é mais largo que o plug, que entra nele (`PLUG_SINK`: abaixo
  de `HOLE_LIP` o plug não é desenhado, `_cut`/`_pr`, e a beira da frente do buraco passa por cima dele e dos fios
  que saem dali, `draw_lip`), sem contorno preto; fio e plug escurecem em degraus ao entrar nele (`HOLE_SHADE`,
  `_along`), senão pareciam flutuar. As pontas dos plugs em pé passam na frente do pé do painel, logo abaixo da
  legenda. `dest_of_output(n)` segue o cabo da saída n.
- `refuse(e, j)` decide compatibilidade (e o destaque amarelo/vermelho). `_has_point` estende o clique ao encaixe
  do FONE; por isso o telefone e seus containers acima do encaixe têm `mouse_filter = IGNORE`, e a mesa tem
  `z_index = 1` (desenha plug e fio por cima do telefone). Overlays têm z 2, intro/final z 3.
- Clique num plug encaixado → solta o plug (`go_home`, `_loose`): ele vira a última conta da corda e cai (`FALL_SEC`)
  e o fio encolhe (`PULL_SPEED`); solto acima do buraco, a qualquer altura (`NEAR_HOLE` na horizontal), não cai: vem reto, fio esticado e sem gravidade. Com o fio todo
  recolhido e a traseira do plug na boca do buraco (`SEAT_LEN`, `SEAT_NEAR`), ele assenta (`_seat`, `_seat_pose`): o
  fio some (já entrou), o plug gira até ficar em pé com a traseira presa na boca (`SEAT_TURN`, macio; vindo de cima,
  já em pé, não gira) e afunda puxado pelo fio, acelerando (`SEAT_ACCEL`; vindo de cima, no embalo dele), e quica ao
  bater no fundo (`SEAT_BOB`, com o `thump`). O corte do buraco só vale com ele em pé (`_in_hole`). (Antes, ele pulava
  em 0,1 s de deitado para dentro do buraco, e o fio ficava desenhado por cima da prateleira.) Com o fio curto, as
  dobras do desenho encolhem com os trechos (`_kinked`), senão viravam um rabisco na boca do buraco; solto, ele gira com o fio
  (`_plug_angle`), sai com o embalo da mão (`_mouse_vel`, `MAX_FLING`) e dá para pegá-lo no ar (`_plug_hit`). Sons:
  `drop` (bate na mesa, `DROP_SPEED`), `thump` (assentou) e o atrito contínuo do fio no buraco: a mesa soma
  quanto fio entrou ou saiu (`_rubbed`, variação do comprimento) e passa a velocidade a `Sfx.cord_rub` a cada quadro
  (volume e tom entre `RUB_MIN` e `RUB_FULL`; sem chamada, cala). Três loops com o mesmo ganho: o fio (agarra e solta
  + corpo), em dois, `rub_slow` com os estalos esparsos e `rub` com eles juntos, cruzados pela velocidade
  (`RUB_DENSE`; o tom sobe pouco, `RUB_PITCH`: subindo só o tom, soava como fita acelerada), e `rub_hi` (o agudo:
  fibras + rangido), mudo devagar (`RUB_HI_FROM`), normal no médio (`RUB_HI_NORMAL`) e `RUB_HI_BOOST` dB a mais
  rápido. Todos passam
  pelo barramento `Rub` (direto para o Master, quase seco; passa-baixa que abre de `RUB_LP.x` a `RUB_LP.y` com a velocidade, e
  panorama). A mesa também informa onde fica o buraco na tela (o som vem daquele lado, `RUB_PAN`), quanto do fio está
  saindo ou entrando (`_count_rub`; entrando é mais liso, `RUB_IN`) e quanto é o do FONE (mais macio, `RUB_FONE`; a diferença some
  quase toda puxando rápido, `fast`), quanto é de plug solto (sem mão puxando: frouxo, grave e quase sem agudo,
  `RUB_LOOSE`) e o tom médio dos cabos (cada um levemente diferente, `Switchboard.CORD_TONE`);
  Por baixo do atrito, a madeira do móvel soando a cada agarra e solta (`_build_rub`, `WOOD`); cada `cord_tap`
  abaixa o atrito um instante (`Sfx.RUB_DUCK`).
  `cord_stop` ("tec") quando o fio termina de entrar; no plug na mão, pela velocidade da mão para longe do buraco
  (`_pull_edges`), `cord_snag` (o tranco do fio parado que sai rápido, `SNAG_*`) e `cord_snap` (o "tsk" do puxão
  rápido que para de repente, `SNAP_*`; parando devagar, não toca); `cord_tap` quando o fio bate na mesa (`TAP_SPEED`,
  no máximo um a cada `TAP_GAP` por fio). Sons mecânicos repetidos (`Sfx.VARIED`) saem com tom e volume levemente
  sorteados. Plug só se move arrastando
  (clicar e segurar); clique sem arrastar só serve para desplugar. Clique é apertar e soltar em menos de `CLICK_SEC`
  sem a mão se afastar `CLICK_PX` de onde apertou (`_dragged`, tempo real), não só soltar perto dele: segurado parado,
  ou tirado da tomada e devolvido a ela no mesmo arraste, o plug encaixa de novo (antes, caía). Enquanto ainda é
  clique, a tomada sob o plug não ganha o destaque (soltar ali desencaixa).
- Fios são cordas de Verlet (`_step_rope`), **uma por ponta**, presas no buraco (`hole(e)`: o do FONE no encaixe, dois
  por cabo de conexão) e na traseira do plug (`_plug_base`); só existem com o fio para fora. No desenho, o fio de pano
  velho guarda dobras (`_kinked`, `KINK`: cada ponto da corda um pouco para um lado, sempre o mesmo, nada nas pontas; a
  física segue lisa) e o brilho vem em pedaços, como trançado (`BRAID`).
  Folga: `CORD_SLACK` (conexão); a do FONE cresce com a distância na horizontal (`SLACK_PER_PX`, até `SLACK`: fixa, o
  fio de uma entrada logo acima do buraco deitava na prateleira e fazia um "Z"). Fio parado por `SLEEP_STEPS` passos "dorme" (`ropes[e]["sleep"]` =
  área onde o mouse o acorda) e deixa de ser simulado até a ponta, o buraco ou o mouse mexerem nele.
- Sob o mouse: `_plug_under` (plug que dá para pegar → `_hover`, desenhado com contorno claro) e `_cursor_shape`
  (mão aberta, mão fechada segurando, proibido sobre tomada que recusa, dedo em tomada/plaqueta que informa).
  Desenho na ordem `_order`: a ponta pega ou encaixada por último (`_raise`) fica por cima (e é a primeira no clique);
  cada ponta desenha fio e plug juntos, para o fio mais recente passar por cima dos plugs das outras.
- A luz da luminária do teto também cai no painel (`_draw_room_light`, `ROOM_LIT`/`ROOM_DARK`, `LAMP_ABOVE`): liso,
  mais claro e quente no alto à direita, mais escuro nos cantos de baixo; por cima de tudo que é do painel e por
  baixo dos plugs e fios.
- **A mesa só se redesenha quando algo que ela mostra muda** (`_look`: lâmpadas, estados das linhas e destinos,
  pontas, plug sob o mouse, balão, setores) ou com algo se mexendo (plug na mão, solto, encaixando ou saindo, fio
  acordado), e mais uma vez no quadro em que tudo para (o lugar final; sem isso, o plug que assentava ficava desenhado torto, meio fora do buraco); parada, fica o desenho guardado (o `Bloom` guarda as luzes de quem desenha). Quem acrescentar ao desenho
  algo que muda precisa pôr isso no `_look`.
- Layout da mesa (`SIZE` 588×362, também em `main.tscn`): móvel com moldura de madeira (`_draw_cabinet`, `FRAME`,
  `WOOD`) e faixas gravadas com o nome de cada seção (`_draw_rule`, `RULES`: entradas, saídas, destinos); coluna de cada linha em `ROW_Y` (plaquinha de metal com o número
  gravado, `_draw_number_plate`; estado; lâmpada; entrada; saída), todos os encaixes com `JACK` px, bancos de destino em
  `DEST_TOP`/`DEST_ROW` (cada banco com o mesmo vão, 8 px, entre a moldura e os números e entre as tomadas de baixo e a moldura, `_blocks`) e a legenda das lâmpadas na faixa das entradas, à direita, na fonte gravada do painel (`_draw_legend`, `tiny`; no pé do painel, os plugs guardados passavam na frente dela). Mexendo na altura, confira que a coluna da esquerda ainda cabe (até 540).
- Chapas de metal niquelado (`_draw_metal`: chanfro e rebites) nas plaquinhas dos números. (A "queda" das mesas antigas, a plaquinha que cai quando a
  linha chama, foi testada e saiu a pedido: lâmpada, texto e som já avisam demais.)
- Moldura de madeira pixel a pixel e guardada (`_wood_frame`): trilhos em meia-esquadria com emenda na diagonal,
  veios ondulando ao longo de cada um, quinas gastas mais claras; o brilho da luminária na quina de cima, mais forte
  do lado dela (`_draw_cabinet`).
- Cada linha tem uma faixa rebaixada e discreta da plaquinha à saída (`_draw_strips`, `STRIP_W`; sem ela a saída
  parecia solta); as faixas gravadas passam por baixo e o nome delas por cima (`_draw_rule(y, nome, false)`).
- Uso de anos (`_draw_wear`, sempre o mesmo): o painel clareado em volta das tomadas (`WEAR`, pelo quanto cada uma é
  usada, `_use`: entradas mais, das primeiras linhas para as últimas) e riscos finos de plug que errou o furo.
- Plaqueta de latão do fabricante no pé do painel, no vão entre os dois primeiros pares de buracos da prateleira (ali
  nenhum plug guardado fica na frente; `_draw_maker_plate`: `BOARD_MAKER` na fonte gravada e "SÃO SOTERO").
- **Pixel art em código, sem arquivos de imagem** (decisão do usuário): `PixelArt` (`scripts/ui/pixel_art.gd`, só
  funções estáticas, usadas pela mesa, pelo cenário, pelo painel e pelo bloom) monta e guarda as texturas: mapas de
  texto (`art`), peças redondas (`disc`), a fonte gravada do painel (`tiny`) e `sprite`, que desenha uma delas centrada
  e presa aos pixels. **Folha de prévia**: `Godot --headless --path . -s tools/sprite_sheet.gd` grava
  `build/sprites.png` com tudo ampliado 8× (os mapas com nome; depois o que a mesa e o cenário montaram na noite 1).
- **Peças redondas pixel a pixel** (`PixelArt.disc`: imagem guardada por diâmetro e camadas, com luz, meio-tom e sombra vindos de
  `LIGHT`, alto à esquerda, e camadas côncavas; `PixelArt.sprite` desenha presa aos pixels; desenhadas como círculo saíam
  embolotadas): lâmpadas, aro aceso do destino, lâmpadas da legenda e parafusos das chapas. **Cor que muda a cada
  quadro vai no `modulate` do desenho, nunca nas cores de um `disc`/`art`** (o cache guarda uma textura por cor e não
  esvazia: o vidro da lâmpada pulsando com a cor no `disc` criava ~38 texturas por segundo; a lâmpada desenha o vidro
  apagado e o aceso por cima com `level` na transparência). **Nenhuma peça redonda
  com `draw_circle`**: o cenário usa o mesmo `disc` (`Background._sprite`, fora da escala e da perspectiva: botões do
  rádio, parafusos do console, alfinete do mapa, emblemas, rebites, tachinha, fechadura); a caneca é uma caneca esmaltada montada pixel a pixel numa imagem (`_mug_art`: o
  cilindro em tons fixos pela luz do alto à esquerda, a borda azul-marinho, a boca e o pé em elipses pela câmera, o
  café com a luz refletida, a alça em C do lado da sombra e lascas no esmalte), com o vapor subindo na camada da poeira
  (`_draw_steam`), que some com as horas porque o café esfria (`STEAM_FOR`); o painel do operador nos parafusos e o `Bloom` no miolo das luzes redondas. Beira das peças e do
  móvel em `EDGE_DARK` (marrom quase preto), não preto. Os plugs também são pixel art, no acabamento do relógio
  da mesa (abaixo). **O encaixe é um mapa de pixels** (`JACK_ART`, 16×16, menor que o `JACK`, com o furo preto de 8 px, a largura da luva do plug: com 20, a tomada ficava grande demais para a ponta de metal; com 24, passava das linhas do banco; `art`: um caractere por pixel e a
  paleta, `_jack_pal`; o mesmo da branch 2×2, pela referência do usuário, com mais tons): aro niquelado fino (2 a 3
  pixels; mais grosso, destoava da referência; os raios dão as larguras de linha de um círculo de pixel art, senão
  saía octogonal) com a beira
  escura em volta do furo preto e largo, a luz na face do aro no alto à esquerda (com um fio de brilho) e na parede do
  furo embaixo à direita; as saídas no níquel mais escuro (`dim`). Largura par e o meio num pixel inteiro (`jack_rect`
  arredonda o dos destinos), para ficar no eixo da plaquinha e da lâmpada. (Uma versão em `_disc` com a bucha de latão
  saiu com o furo maior e foi rejeitada.)
- Encaixes redondos (`_draw_jack`: o aro niquelado e o furo, com a sombra no painel); lâmpadas de vidro leitoso abaulado num aro
  fino de níquel, sem furo (`_draw_lamp`, `BEZEL`, `LAMP_OFF`: com o assento preto pareciam mais uma tomada) que acendem rápido e apagam devagar, como
  filamento (`_lamp`/`_dest_lamp` dizem cor e nível desejado, `_fade` chega lá em `LAMP_ON_SEC`/`LAMP_OFF_SEC`, estado em
  `_lit`; a linha tocando pulsa). A luz acesa tinge o aro dela e o alto do aro do encaixe logo abaixo (`_reflect`).
- Plug (`_draw_plug`): de pé (comprido, `PLUG_LEN` do fio à aba; guardado, afunda `PLUG_SINK` = 22 px no buraco: a capa
  de borracha some nele e o corpo fica à mostra, sem esconder metade do plug) (solto, na mão, na bandeja; `_draw_plug_body`) é um mapa de pixels (`PLUG_ART`, 20×93, cores
  por cabo em `_plug_pal`; sombreado de cilindro com o brilho numa coluna só e a beira escura à direita, cantos
  arredondados; contido como o relógio: brilho largo e colar claro destoavam), no jeito de um plugue P10 (referência
  do usuário): a capa de borracha em gomos afinando até o fio (termina em 10 px, a largura do fio, `ROPE_W`), o corpo na cor do cabo (identifica o cabo) com anel em
  cima, serrilhado em listras finas e anel no meio, a aba dourada e a ponta de metal dourado (luva, isolante preto,
  anel, outro isolante e o bico em ponta com a bolinha); comprido e fino como o P10 e **na escala das tomadas** (18 ×
  93 px, `PLUG_H`, `PLUG_LEN` até a aba: o corpo enche o buraco da prateleira, `HOLE_ART` 28 × 14, e a luva de 8 entra
  no furo de 8 da tomada; o encaixado na mesma proporção, `PLUG_FACE_R`, 18 px de corpo com a beira, cobrindo a tomada); para o plug não ficar maior que o
  relógio e o caderno (um P10 tem uns 10 cm), **os objetos da mesa crescem na mesma proporção** (`Background.PROP_K` =
  93/66, a caneca na frente do relógio para caberem em 1280); a área de clique do plug guardado sai da altura dele
  (`home_rect`); gira com o fio em passos de
  `ROT_STEP` (5°), cada passo montado pixel a pixel como no RotSprite (`PixelArt.turned`: o mapa ampliado 8× pelo
  Scale2x e lido de volta girado, guardado por ângulo e servindo a qualquer cabo; girado pela transformação do
  desenho, serrilhava, e o passo era de 15°). Na mão, ele balança com o movimento como um pêndulo preso onde a mão
  pega (`_swing_step`, `SWING_*`; a traseira com o fio fica para trás) e, solto, sai com esse ângulo; caindo, quica
  na mesa (`BOUNCE`, `BOUNCE_MIN`; o `drop` mais alto quanto mais forte a batida, até `DROP_FULL`). O brilho do mapa fica
  do lado esquerdo, virado para a luz (`PixelArt.LIGHT`); girado a ponto de esse lado ficar de costas para ela, vale o
  mapa espelhado (`_plug_art`). Ao encaixar, a passagem para de frente gira a partir do ângulo que ele tinha na mão
  (`_pushed_ang`). O fio e os plugs em pé pegam a luz da sala do painel em `CORD_LIT` da força (`_lit_by`,
  `_room_tone`: mais escuros e frios longe da luminária). **Todos os fios têm o mesmo comprimento**, `CORD_MAX` (660 px: o do FONE, puxado do
  encaixe, chega ao meio das listas telefônicas da mesa em 1280 × 720; a tomada mais longe de um buraco fica a 564):
  na mão, o plug para no fim do fio (`_reach`, com um tranco, `cord_snag`) e a mão segue; a velocidade usada no balanço
  e no embalo é a do plug, não a do mouse. **A prateleira acaba** na lateral do console (`Switchboard.shelf` =
  `Background.shelf`: o x do canto da frente do console e o y do tampo ao pé dele; sem cenário, nos testes, não acaba):
  além dela o plug solto cai até o tampo (`_surface`) e quem vem de fora bate na lateral, sem subir na prateleira.
  Recolhendo, pendurado ao lado do console, a quina é uma roldana (`_hang_step`): o fio vai reto do buraco à quina e
  dela ao plug, que balança preso nela, sobe pendurado (ponta para baixo, `HANG_TURN`) e, na quina, volta para cima
  da prateleira e para a corda de sempre (com a corda solta contra a quina, ele ficava preso, laçava ou era
  arremessado). O ângulo do plug solto segue o do fio aos poucos (`LOOSE_TURN`). Esticado, o fio de pano alisa: pela distância do buraco à ponta
  (no pendurado, o caminho pela quina) a partir de `TAUT_FROM` do `CORD_MAX`, as dobras somem aos poucos, o trançado se
  espaça (`TAUT_BRAID`) e, da metade em diante, ele e a sombra afinam 1 px (`_tension`, `ropes[e]["taut"]`, suavizada
  em `TAUT_EASE`); frouxo, volta com as dobras inteiras. (Pela folga não dava: os cabos de conexão têm sempre ~14 px
  dela, perto ou longe.) Esticado, o fio também fica reto no desenho (vai para a reta do buraco à ponta; a física
  deixava uma barriga, porque a gravidade puxa o meio a cada passo; pendurado na quina, `ropes[e]["hang"]`, não). Puxando
  além do fim do fio, o plug na mão se inclina para o lado do puxão, inteiro a `LEAN_PX` além (a mesma mola do
  balanço), com a traseira virada para o buraco; o limite vale para a traseira girada (`_reach`). (Em pé, com o fio
  chegando de lado, a junção dobrava e o fio passava por cima dele.) Encaixado, sai do painel em direção à câmera, vista de cima e da
  direita (`_draw_plug_face`: o próprio `PLUG_ART` visto de frente, com os mesmos detalhes: aba dourada, anel e friso claro em cima,
  serrilhado, `_knurled`, anel do meio e capa em gomos afinando até o fio; montado com discos de pixel art, `disc`, um
  por pixel ao longo do eixo, cada um com a largura e os tons da linha do plug em pé que cai ali, `_face_row`: dela vale
  a que mais se destaca, senão os detalhes sumiam no escorço; primeiro a beira de todos, depois o miolo sombreado; com cápsulas e círculos, saía embolotado); com paralaxe: a ponta se desloca do encaixe mais quanto mais longe de `PLUG_EYE` (`_tilt(j)`,
  `PLUG_DEPTH`). O fio sai da ponteira (`_plug_base` = encaixe + `_tilt`; o plug encaixado é desenhado antes do fio,
  e o miolo da ponteira, `_draw_plug_cap`, depois). Encaixado, o fio sai no eixo do plug por `CORD_STUB` px e faz a curva
  aos poucos (o penúltimo ponto da corda fica preso, `pin` em `_step_rope`; os seguintes tendem a continuar a direção,
  `CORD_BEND`, uma vez por passo: por iteração endurecia o fio), a sombra vai do encaixe até `PLUG_SHADE` com uma
  sombra de contato em volta do colar (a do fio sai do fim da do plug e chega a `ROPE_SHADOW` no buraco, `_lift`), a
  luz bate no contorno do plug encaixado (`_plug_light`, `_face_rim`: a silhueta dos discos juntos; na entrada, a
  lâmpada da linha acende só a beira de cima; no destino, o aro aceso acende a beira toda; clareada na cor da luz. Um
  anel solto por cima flutuava sobre a capa, e uma beira por disco listrava o plug), o corpo em pé entra girando para o
  eixo do encaixado, sem a ponta de metal (`_draw_plug_body(col, false)`). Ao encaixar, o corpo em pé entra no encaixe enquanto a
  vista de frente cresce, e ao sair a vista de frente some no encaixe (`MORPH_SEC`, `_pulled`, `_unseat`); ao encaixar, o tampo encolhe `PUSH_PX`
  e volta em `PUSH_SEC` (`_pushed`, `_push`). Destaque e sombra seguem a silhueta (`_plug_outline`: as partes unidas
  num polígono, guardado; o destaque é ele alargado); `_plug_rect(seated)` é o retângulo do clique.
  No plug em pé (na mão, solto, guardado), o fio entra `TAIL_IN` px na traseira dele, no eixo, e uma junta redonda
  fecha a dobra (`_draw_tail`): chegando de lado, ele terminava num corte reto no meio da ponta e deixava um vão.
  O fio tem `ROPE_W` (9 px com a beira; o miolo, 3 a menos; era 8, engrossou para o esticado, 1 px mais fino, se ler).
  Sombras (`SHADOW`): fios deslocados `ROPE_SHADOW`; plug mais longe quanto mais sai do painel (solto, na mão).
  Sem contorno preto em plug e fio: a beira é a cor da própria peça escurecida (`EDGE`; o metal, `BEZEL[2]`), como no
  cenário. Encaixado, o colar (`PLUG_FACE_R`) é menor que a bucha: a aba de latão fica à vista em volta.

## Modelo das ligações
- `live`: ligações tocando ou em andamento (várias ao mesmo tempo). O painel mostra `phone.shown()`.
- **Foco** = a ligação da entrada onde está o FONE (`Main._focus()`); Main mantém `c.on_line`. Quem não está em
  foco fica "em espera" e **não fala**: `say()`/`op()` aguardam `_until_on_line(c)`. Exceção: ligação já resolvida
  (`c.closing`: informação respondida, emergência despachada) não entra em espera; a pessoa termina de falar sozinha
  e desliga, sem som e sem texto na transcrição (só o que for dito com o FONE na linha aparece).
- Destino que não atende: pedido com alternativa (`TransferCall.alt_target`) sorteia ao ser criado se o lugar pedido
  atende (`PhoneCall.away`, `AWAY_CHANCE`; nunca no tutorial); se não, toca sem resposta e o operador pode sugerir a
  alternativa (`alt_ask`, `Conversation._transfer_alt`), que sempre atende. **A alternativa é do mesmo ramo**
  (`DirectoryEntry.category`: farmácia, igreja, mercearia, hospedagem, oficina; o teste confere; a
  Vila Serena tem hospedagem e oficina, então a mecânica aparece desde a noite 1): os moldes a escolhem sozinhos
  (`GameData.alternative`, fala `OP_TRY_OTHER`, resposta em `alt_accepted`); os roteiros escritos têm a deles. Só
  ganha ramo quem pode ser trocado por outro para qualquer motivo dos `reasons` (bar não: "recado pro amigo que tá lá").
- Transferência: FONE na entrada → Atender → pedido → cabo de conexão saída→destino → **Transferir** (`transfer()`)
  → `_ring_dest` → destino atende (com o FONE na linha, quem ligou agradece) → `_try_complete` na hora, com ou sem o
  FONE na entrada (o operador não ouve a conversa dos dois) → linha e destino CONN por `TALK_LEN`
  → DONE (vermelho) até o jogador tirar as pontas. `_dgen` invalida toques de destino quando o cabo sai.
- Fim de ligação: `end_call(c, PhoneCall.End.*)` gera `c.record` e manda para `Notebook.add()` (fila; não trava o turno; não atendida vai
  direto para o livro com o carimbo `TYPE_MISSED`, sem escolher tipo).
  O caderno registra com **um clique no tipo** (`register(T.Key.TYPE_*)`: Comum, Emergência, Trote; o resto da linha
  vem do `record`), mostra a pendente numa ficha só de leitura e desenha o livro como página pautada (`_draw_page`,
  carimbo colorido por tipo, `STAMPS`). A aba mostra quantas faltam (`pending_changed(count)` → `Tools.set_count`,
  selo `BadgeLabel`); o jogo não troca de aba sozinho.
- Despacho: **mapa e despacho numa aba só** (`Dispatch`, `scenes/ui/dispatch.tscn`; não existe mais aba Mapa nem
  `MapView`): o `CityMap` (`%City`) ocupa a aba inteira (passa por baixo da margem do papel); clicar no trecho já marca
  o local (`segment_selected` → `set_location`); passar o mouse mostra uma etiqueta com a faixa de números do trecho
  (`CityMap._tag`, "Rua do Sol, 1–99"). Por cima, a **ficha de despacho** como objeto (`%Slip`, `CardMachines`, `Dispatch.machines`, cobre o mapa com fundo
  transparente: o clique fora da máquina e do cartão vai para o mapa, `_has_point`; abrir ou fechar não mexe no mapa):
  três máquinas de metal (`_box`: sombra, parafusos, saídas de ar): a impressora (canto de cima, à direita;
  desce quando a ficha abre e sobe quando fecha, com o × junto; o × só aparece sem cartão: com um, a ficha sai
  enviando ou triturando), a
  trituradora (embaixo dela, na borda de baixo) e o transmissor (canto de baixo à esquerda); as duas de baixo sobem
  quando o cartão sai impresso e descem quando não há cartão. Fechar a
  ficha espera as máquinas se recolherem (`set_open`, `closed` → `Dispatch._hide_slip`). Marcar o local faz a impressora datilografar (`typing`, o local aparece na tira de papel) e imprimir
  (`printer`, saindo sem parar) um **cartão perfurado** com local, bairro e setor, que sai pela fenda. O cartão é um formulário: impresso na tinta
  vermelha das emergências (`FORM`, a do carimbo do caderno: faixa com o número, rótulos, posições de furo, fio duplo,
  rodapé com o nome da central, marcas de coluna na borda) com os dados datilografados em preto sobre linhas
  pontilhadas, pauta como a do caderno, fibras no papel e sombra na mesa (na mão ele sobe: cresce `HELD_SCALE` em volta de onde foi pego e a sombra se afasta; solto, cai acelerando, `DROP_SEC`; parado, escala 1 exata para o texto ficar nítido). O jogador perfura
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
  que recorta (`_window`): saindo, só aparece abaixo da fenda da impressora; entrando, só acima da fenda da máquina (`_into`, `CardMachines.Machine`). Os
  furos são a vista dos dados do `Dispatch` (`_location`, `_occurrence`, `_picked`; `set_occurrence`, `punch_unit`),
  que os testes e o robô usam direto. A ficha abre ao marcar um local ou quando chega uma emergência (`open_slip`), se
  recolhe depois do envio e o × a fecha; fechada, o botão `%Open` a reabre. `CityMap.blocked`: onde há botões por cima
  (abrir ficha, `%Fleet`), sem nomes de rua. `%Fleet` (canto de cima à esquerda, só com viatura fora) mostra o estado delas
  (`%Report`). O tipo **não** marca unidades: a conversa decide, pelo protocolo (regras em `EmergencyCall.units`).
  `EmergencyCall.cases` (`EmergencyCase`): variações sorteadas por `GameData.with_case()` (respostas + unidades).
  Depois de enviar, local, tipo e unidades voltam limpos (`city.clear_selection`). Abrir a aba toca o papel
  desenrolando (`unroll`). **O desenho do mapa** é o do mapa dobrado da mesa, de perto: as ruas são o papel entre os
  quarteirões (`Pal.MAP_PAPER`; sem contorno), cada bairro no seu tom (`Pal.MAP_TINTS`), as casas em volta das quadras, de
  frente para as ruas e com o telhado de duas águas, e os quintais com árvores no meio (`_houses`, `_tree`), os lugares
  num prédio de telhado de barro (`Pal.MAP_LANDMARK`), a praça verde com caminhos, árvores e o coreto (`_draw_square`), a
  sanfona em quatro painéis com os vincos e o selo vermelho com a rosa dos ventos e o nome da cidade (`CITY`, `Pal.SEAL`).
  O mapa da mesa (`Background._art_map`) é este em miniatura e usa as mesmas peças (`frame_of`, `block_rect`, `lots`,
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
  `trips[i]["t"]`, parando na pausa) e o despacho espera a mais demorada. Depois de um tempo no local (`Dispatch._return`,
  `STAY`), a viatura volta para a base pelo mesmo caminho, sem a luz (`CityMap.go_home`), e só fica disponível quando chega.
  Quem não era necessária (a mais, endereço errado ou nada lá) volta logo depois de o rádio dizer isso (`Radio.said`,
  `QUICK_STAY`), ou no máximo `QUICK_WAIT` s depois de chegar se o rádio ainda estiver ocupado. Emergências escritas e moldes só nas ruas dos setores atendidos.
  **Regras das viaturas no `Fleet`** (`scripts/model/fleet.gd`, `Dispatch.fleet`; sem tela nem tempo, testado direto no
  teste de fluxo): estado de cada uma (`Fleet.Unit`, `IDS`, `NAMES`, `STATUS`), a emergência em andamento (`incident`,
  `required`, `require`) e a ordem `send` (devolve se o socorro ficou completo) → `arrive` (`Fleet.Result` OK, MISSING,
  WRONG_PLACE, IDLE; o que falta, o que sobrou, quem volta logo) → `leave` → `home`; `gen` invalida viagens depois do
  `reset`. O `Dispatch` fica com cartão, ficha, mapa, rádio e a espera entre os passos. `Dispatch.set_incident()` quando a emergência toca; `Dispatch.sent` → `Main._on_dispatched` →
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
  certo (`Dispatch.sent(..., complete)`, conta envios anteriores em `Fleet.incident["going"]`). Estágios por
  `EmergencyCall.stage_sec`; cada um chama `Conversation.emergency_worse` (fala `worsening`/`critical`/`lost`; com a
  pessoa já desligada, `RADIO_WORSE`/`RADIO_LOST`; depois de dita, `Urgency.told` atualiza `PhoneCall.told`, e só então `Fleet.require(e.required(told))`
  passa a exigir as unidades do estágio; com a pessoa já desligada ou se despedindo, o rádio diz também o que mandar,
  `RADIO_SEND_MORE`. `told` também libera a pergunta do estágio:
  `Conversation._qa`, índices depois das do roteiro; perdida = só o endereço e `OP_ANYONE_HURT` → `lost_answer`). Advertência pelo estágio
  quando o socorro completo sai (`_on_dispatched` → `Supervisor.secured`: `emergency_worse` média, `emergency_critical` grave + jornal LATE);
  perdida = `emergency_lost` gravíssima na hora (`Supervisor.lost`) + jornal BAD (sem `emergency_dropped` nem retorno). Retornos não têm
  barra (herdam `stage` e `told`: as unidades e as perguntas de quando a ligação caiu). A próxima emergência espera a barra da anterior parar.
- O Main chama `supervisor.fault()` onde a falha acontece (cabo cortado, número errado); `Supervisor.call_ended()`
  (chamado em `end_call`) decide advertência e retorno; `call_again()` agenda a mesma pessoa de novo (`PhoneCall.retry`; uma vez por motivo, `retried`;
  também no tutorial; nunca depois do fim do turno; `too_late` sorteado com
  `REDISPATCH_CHANCE`). `check_hold()` encerra quem passou de `HOLD_GIVE_UP` em espera (`End.GAVE_UP`).
- Tutorial (`tut`), trotes e ligação desconhecida não geram advertência. Falas de retorno, manchetes e pareceres
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
  nome no rodapé de cada folha do mapa). Cada um tem emergências escritas (Centro: 11–13; Alto da Serra: 14–16, a 14
  na casa do Benedito Souza, endereço dele na lista). Na noite da entrega: a primeira transferência para o banco novo
  mostra `HINT_NEW_BANK` (`Main._new_sector`), e na primeira vez que o mapa aparece ele sai do enquadramento antigo e
  se abre para o bairro novo (`CityMap.pending_reveal`, `REVEAL_SEC`; o bairro novo aparece aos poucos).

## Noites (roteiro fixo)
- 15 noites; as 3–15 ainda são genéricas (dia da semana e bilhete, sem roteiro nem ligação desconhecida).
- `GameContent.nights` (ordem) → `Night` (`scripts/data/night.gd`, `data/nights/night_NN.tres`): dia da semana, bilhete
  da intro, clima fixo (vazio = sorteado), `tutorial` (só a 1ª), a primeira página do jornal (`news_*`, opcional), `story` (`StoryCall`: roteiro escrito + horário fixo) e `mystery` (passos `PrankStep`; vazio = sem
  ligação desconhecida naquela noite). **Só `story` e `mystery` são fixos; não existem ligações "principais".**
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
  (`ShiftReport.severe_before`/`severe_total()`/`fired()`) e marcadores. Main salva em `start_ending` (última
  noite ou demissão limpa o save). `-- --night=N` força uma noite **sem ler nem gravar** o save; `test_base.load_main` força a noite 1.

## Agenda e ritmo (constantes no topo de main.gd e schedule.gd; por noite em `Night`)
- Ligação desconhecida (`MYSTERY`, entrada livre sorteada, guardada em `myst_line`) entre `Night.mystery_from` e `mystery_to` (22:00–23:30), só
  toca com a mesa em silêncio, por no máximo 30 min de jogo (`latest`, `Schedule.MYSTERY_WAIT`), e nunca depois de
  `LAST_CALL - MYSTERY_MARGIN` (23:30): o botão Encerrar turno só aparece depois dela.
- Sorteadas: `Schedule._random_calls` — intervalo `Pace.call_gap` (nível 1: 45–60 … nível 5: 28–38; medido com `--human`) entre uma e a
  próxima, `Pace.peak_chance` de vir logo em seguida, no máximo `Pace.max_live` pedindo atenção (`_run_schedule`), a `STORY_GAP` das fixas. Tipos: `Pace.emergencies` (a `EMERGENCY_GAP` uma da outra; no laço, a
  emergência espera a anterior acabar e `Fleet.en_route()`), `Pace.pranks`, resto transferência/informação.
  Um destino (e `alt_target`) por noite: dois pedidos do mesmo número travavam um ao outro.
- `GIVE_UP_SEC` 60 s (`story` 1,5x, retornos 0,75x); tutorial (`tut`) e desconhecida nunca desistem.
- Espera na linha (`Main._nag`, silêncio medido em `talk_clock`, que para na pausa): transferência pedida e o
  operador parado → depois de `SMALLTALK_AFTER` (10 s), com `SMALLTALK_CHANCE` (60%, uma vez por ligação), conversa
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
  sozinho quando não falta registrar nada (senão, `HINT_MIDNIGHT` e espera registrar ou o botão).
- Relógio: 0,75 min de jogo por segundo real (`GAME_MIN_PER_SEC`): 6 h de turno ≈ 8 min reais.

## Histórico das decisões de design (o que o usuário pediu, em ordem)
1. Mesa com entradas + destinos; cabos limitados; desmontar conexões encerradas.
2. Teclado de discagem removido; ligações simultâneas; caderno em fila; mais variedade de conversas.
3. Menos simultaneidade (extras espaçadas, pico raro).
4. Conversas conectadas mais longas (45–90 min de jogo).
5. Modelo de cabos refeito: pares com chaves FALAR/TOCAR foram **substituídos** por FONE + saídas + cabos de
   conexão + botão Transferir (o usuário considera o vermelho "o cabo do fone"; depois o FONE passou a branco, depois a verde, e os
   cabos de conexão a vermelho/azul/amarelo).
6. Ligações continuam depois da linha 07; linha 07 em horário aleatório após 02:00; final às 06:00;
   clique devolve o plug à base com animação.
7. Reestruturação para a versão definitiva (branch `refactor/definitive`): testes no projeto, semente fixa,
   conteúdo em Resources, `PhoneCall`/`Exchange` tipados, interface em cenas com Containers e tema, autoload
   `Sfx` com barramentos, Input Map e `tr()`.
8. Anotação "NÃO ATENDER NOVAMENTE" removida (o mistério será roteirizado depois); a ligação desconhecida vem
   de qualquer entrada, não só da 07.
9. Mais roteiros escritos e conversas híbridas: moldes com lacunas (nomes em inglês) para extras e emergência.
10. Consequências + relatório do supervisor no fim do turno, pensado para as próximas noites. Despacho errado: a pessoa
    agradece na hora, o rádio diz que não havia nada e as unidades voltam; ela liga de novo dizendo que piorou e,
    em alguns casos, dá para despachar de novo (a advertência fica).
11. Turno passou a ser 18:00–00:00 (desconhecida entre 22:00 e 23:30; extras 4–6). Número errado com o FONE fora:
    não completa; foi engano, os dois desligam e o solicitante liga de novo pedindo o certo. Clique que mexe
    uns pixels conta como clique.
12. Sons: campainha antiga (martelinho + ressonadores de metal; depois trocada por bipes suaves, jogadores acharam irritante) e "tuuuu" (o filtro de caixa oca foi testado e removido a pedido do usuário), chuva e grilos (chirps + trilos) refeitos. Clima sorteado por
    noite: chuva (só chuva), névoa (grilos), limpo (brisa e grilos). A coruja que havia foi removida a pedido do usuário.
13. Rádio mais largo e alto (3 linhas); abas 24 px mais baixas (mapa se ajusta à altura). Silhueta na janela
    `SHADOW_LEAD` (15 min) antes da ligação desconhecida (`Background.shadow`), sai `SHADOW_LEAVE` (10 min) antes
    (foi ligar); segue o horário sorteado (`myst_plan`), mesmo que a ligação atrase.
14. Ligações demais ao mesmo tempo depois do turno de 6 h: relógio a 0,75 min/s (turno volta a ~8 min reais) e
    retornos esperam a mesa esvaziar (`RETRY_WAIT`). Medido com o robô desastrado (`--clumsy`).
15. Várias noites com roteiro fixo por noite (`Night`), progresso salvo e demissão com 3 graves acumuladas.
16. **Nada fixo além do roteiro**: as 4 "principais" com horário fixo foram removidas; tudo é sorteado com intervalo
    máximo (`call_gap`), o que também acabou com silêncios de ~1 h. O primeiro valor (12–32 min) era rápido demais
    para uma pessoa; passou a 28–42 (noite 2: 26–40), medido com o robô `--human`. Silhueta sai 10 min antes de ligar, preta e
    contra a luz de um poste.
17. Três idiomas (pt_BR, en, es): enum `T.Key` + CSV para a interface, .po para as falas.
18. Menu de pausa (Esc) com Configurações (idioma, volumes, velocidade do texto), também na tela inicial.
19. Fios saem de buracos (dois por cabo de conexão, um por ponta; o do FONE no encaixe); plug solto cai e o fio o
    recolhe para o buraco (substituiu a volta em arco e o cabo enrolado na base). Plug só se move arrastando
    (o modo "clique no plug e depois na tomada" foi removido); clique sem arrastar desconecta.
20. Cursores próprios (botões de cena também: `node_added` ligado em `_enter_tree`) (seta, dedo, mão aberta/fechada, proibido, I-beam), plug sob o mouse com destaque, fio mexido
    por último por cima e fios parados sem simulação. Plug com ponta de metal maior, que entra na tomada; sombras.
21. Caderno: registro com um clique no tipo ("Outro" e os campos editáveis saíram), contador na aba no lugar do
    ponto e da troca automática de aba, livro redesenhado como página pautada com carimbos.
22. Menos burocracia no despacho: mapa e despacho numa aba só (sem "Abrir mapa"/"Usar no despacho"), o tipo marca as
    unidades de costume, conferência sempre à vista com Enviar só quando pronto, limpa depois de enviar, etiqueta com
    a faixa de números ao passar o mouse, som de papel desenrolando ao abrir. Marcar o mapa sozinho pelo endereço
    dito na ligação ficou de fora de propósito (tira o desafio; no máximo, um modo fácil).
23. Turno caótico: noite 1 calma (7–9 ligações, máx. 2 pedindo atenção, sem picos) e ritmo subindo noite a noite.
    O tipo da ocorrência deixou de marcar unidades: a conversa revela os fatos e o protocolo (polícia: crime, briga,
    arma, rua bloqueada; bombeiros: fogo, fumaça, fio/gás, alguém preso; ambulância: ferido, passando mal ou preso) diz
    o que mandar. Cartão do protocolo na aba, respostas decisivas sem ambiguidade, moldes e roteiros com casos sorteados.
24. Barra de agravamento da emergência (abaixo do chat, dentro da caixa): inicial → agravando (média) → agravada
    (grave, jornal com atraso) → perdida (gravíssima, nova gravidade). Para enquanto o operador pergunta e a pessoa
    responde; corre em espera. Cada estágio tem fala própria e pode exigir unidades novas. Depois: a barra só para
    com o socorro completo no lugar certo (chutar e completar não adianta), ficou mais rápida (45/40/35 s no 1º
    estágio) e some fora da linha; aí o rádio inteiro acende (moldura pulsando e aviso na tela) na cor do estágio.
    Cada estágio libera uma pergunta sobre o que mudou; na perdida, só "Tem alguém ferido?" (e o endereço). A unidade
    nova só conta depois de alguém contar (a pessoa ou o rádio). O telefone passou a ocupar o que sobra da tela e o
    chat encolhe quando as opções ganham fileiras (antes, o painel passava até 13 px da tela e cortava os botões).
25. Ritmo separado das noites (`Pace`, níveis 1–5): segunda emergência só a partir do nível 3; nas 3 primeiras noites o
    ritmo só sobe se a noite anterior não foi ruim; depois sobe sempre, até o nível 5 (limite medido com `--human`).
    Última ligação às 23:40 e botão Encerrar turno; à meia-noite ninguém é cortado.
26. Setores: a cidade em três bairros (Vila Serena, Centro, Alto da Serra), entregues nas noites 5 e 9 (15 noites).
    Mesa com bancos A/B/C (faixas 100–199…), tampados por chapa até a entrega; mapa só com os bairros atendidos, ruas
    que continuam com o mesmo nome e a numeração seguindo, nomes sem sobreposição; revelação do bairro novo no mapa,
    dica do banco novo e ritmo que não sobe na noite da entrega. Lista telefônica refeita: uma letra por página dupla, abas de
    índice na borda em vez da barra de letras, ordem sem acento e bairro no endereço.
27. Ligação não atendida entra sozinha no caderno (carimbo "Não atendida", sem escolher tipo). Uma fala por vez em cada
    ligação (`Conversation.say` espera a anterior; o assunto não atropela mais o "Obrigado, Central") e nada de conversa
    fiada com o destino tocando. Fontes trocadas por IBM Plex e, a pedido do usuário, por Departure
    Mono em tudo (nítida em 1280×720; o texto de 11 px borra em janela bem menor).
28. Aba do despacho refeita: mapa na aba inteira e a ficha de despacho por cima, à direita (abre ao marcar o local
    ou com emergência, recolhe depois do envio), com o protocolo junto de cada unidade; viaturas num canto do mapa.
29. Ficha de despacho como cartão perfurado: marcar o local imprime o cartão (digitação e impressora antiga), o
    jogador perfura tipo e unidades em posições fixas e leva o cartão ao transmissor (canto de baixo à esquerda), que o puxa e
    envia, mesmo incompleto (o supervisor pune); a trituradora, embaixo da impressora, descarta o cartão.
30. Plug encaixado em perspectiva (visto de cima e da direita, com paralaxe por encaixe), com as peças do plug em pé,
    sombra pela profundidade, fio saindo no eixo e furos vazios com a mesma paralaxe. Janela maior, ao lado do rádio,
    no alto da direita (abas mais baixas), preparando mais detalhes na janela e na mesa.
31. Telefone como console em cunha (tela embutida na carcaça, fenda da barra de agravamento, teclas de verdade no deck)
    e rádio ao lado do relógio; a janela ocupa todo o alto da direita e as abas (o mapa) ficaram mais altas. O título
    "Central de São Sotero · Operador noturno" saiu da tela (a introdução da noite já mostra).
32. A tela vira uma mesa de trabalho (referência visual do usuário): mesa comutadora à esquerda, de pé sobre a mesa,
    com o FONE e o rádio na frente dela; ferramentas guardadas, que deslizam sobre a janela quando abertas (como um
    papel posto na mesa); painel do operador embaixo, na largura toda, com só as últimas 3 falas, e o registro inteiro
    das conversas numa quarta ferramenta. O cenário segue desenhado em código, mas pode virar PNG por camada depois.
33. Mesa comutadora refeita: móvel de madeira, seções com faixas gravadas, mais espaço entre as fileiras e legenda no
    pé; a base dos cabos virou uma bandeja na mesa, à frente do painel, de onde os fios sobem; relógio mais compacto.
34. Cenário: a janela deixou de ocupar a área das ferramentas inteira (parecia uma aba a mais) e virou um objeto na
    parede, com persiana, peitoril, vaso e a cidade lá fora (igreja com relógio, casas, poste, chão molhado); relógio de
    parede com a hora do jogo, papéis presos, tábuas na mesa, listas e caneca. Cada camada aceita um PNG depois.
35. Objetos da cena abrem as ferramentas: ficam na mesa, ao alcance do operador (na parede só ficaria o que parecesse
    perto dele), desenhados no mesmo detalhe da mesa comutadora. A legenda do rádio ficou de fora: o rádio já tem tela.
36. Mesa de madeira: a dica do manual subiu para o alto da direita (liberou a mesa), objetos maiores e em fileiras,
    tábuas em perspectiva com a borda da frente, luz da luminária e da janela na mesa e sombras saindo da luminária.
37. A mesa parecia o piso: a mesa comutadora passou a ficar de pé no tampo (o fundo dele atrás dela), sem rodapé na
    parede nem juntas de assoalho nas tábuas, com a borda da frente mais grossa. As abas das ferramentas somem quando
    estão guardadas (eram informação duplicada dos objetos da mesa); o selo do caderno foi para o caderno da mesa.
38. Ainda parecia chão (as duas linhas escuras da quina): perspectiva de um ponto, com o ponto de fuga na altura dos
    olhos; luz da luminária dobrando na quina (arco na parede, poça na mesa), sombras projetadas na parede, janela
    embutida com a espessura da parede e objetos da mesa com lado e espessura no rumo do ponto de fuga.
39. Canto da sala: a janela foi para a parede da direita, vista de lado (a vista da cidade fica reta, só recortada
    pelo vidro: entortada com a janela parecia um quadro), e no lugar dela, na parede do fundo, um armário de aço de
    chão atrás da mesa. Uma câmera só para a sala inteira, com os objetos da mesa postos nela em 3D (antes misturavam
    vista de frente e de cima, sem escorço) e o ponto de fuga perto deles.
40. Rádio, encaixe do FONE e bandeja dos cabos como caixas na câmera (tampo, lado e sombra); tábuas e poça de luz
    calculadas pela câmera, e a luz da luminária na mesa e no armário tremendo com ela.
41. Game design na mesa: os objetos mostram o estado do jogo (tiras no caderno, alfinete piscando, folha nova na
    prancheta); o jornal da manhã com as consequências da noite anterior fica na mesa; a sala muda pelos marcadores
    do roteiro (o mistério e as escolhas também moram no cenário).
42. Ferramentas como objetos (o papel sai do objeto na mesa, com a forma dele, e o cenário escurece atrás); um relógio
    só, analógico, na parede acima da mesa comutadora (o painel digital destoava e repetia a hora do relógio de
    parede), com o turno numa plaqueta de latão; o painel do operador virou um console embutido na frente da mesa.
43. Dicas da primeira vez para os sinais da mesa; a lateral da mesa comutadora na câmera; o relógio bate as horas e
    uma campainha avisa quando o turno pode ser encerrado.
44. Desempenho do cenário: ele só se redesenha quando algo que mostra muda; a vista da janela anda sozinha no vidro.
45. A mesa comutadora parecia fora da mesa e desalinhada com as peças de baixo, e a perspectiva estava exagerada para
    quem senta perto da mesa: a mesa comutadora virou um móvel só (painel na prateleira de um console, com a faixa de
    mesa embutida na frente dele) e os olhos subiram (ponto de fuga logo acima da tela), entortando bem menos.
46. O FONE e os cabos foram para a prateleira, na frente do painel e acima do rádio, como numa mesa telefônica de
    verdade: os plugs ficam em pé em buracos no tampo e os fios sobem deles até as tomadas; nomes gravados na madeira.
47. Acabamentos: os objetos da mesa reorganizados a partir da mesa comutadora (sem encostar uns nos outros), o
    interior do armário com profundidade, detalhes no console, relógio mais legível e, a pedido do usuário, a
    luminária saiu da tela: só a luz, vinda de cima e do meio.
48. Uma densidade de pixel só: o cenário passou a ter os detalhes em 1x1, como a interface (a mistura com 2x2
    incomodava; as contas da câmera seguem em unidades de 2 px), e os objetos perderam o contorno preto (serrilhava).
49. O 1x1 ficou "pixels pequenos e definidos demais", e um filtro de 2x2 com média borrou tudo: o cenário inteiro
    passou a 2x2 de verdade (arte na grade de 2 px e filtro que pega um pixel por bloco), ainda em prova (caderno e
    prancheta redesenhados; listas, mapa, jornal e caneca não). Para acabar com os borrões, como no Papers, Please: o
    jogo é ampliado como imagem (`viewport`, "nearest"), a fonte sem suavização, sem linhas de varredura e com vinheta
    e brilho em degraus.
50. O jogo todo ampliado como imagem deixou o texto feio a 1,5× (1080p): híbrido. A interface volta a ser desenhada na
    resolução da tela, com a fonte suavizada; só o cenário vai numa tela de metade da resolução ampliada com "nearest"
    (`SceneView`), que dá pixels quadrados e inteiros nas telas comuns. O filtro de 2x2 saiu.
51. Os objetos da mesa todos na grade de 2 px (listas, mapa, jornal e caneca redesenhados em blocos), o brilho da luz
    só na sala (antes passava em anéis por cima da mesa comutadora e dos textos) e os halos do bloom na mesma grade.
52. O brilho das lâmpadas e dos aros não passa mais por cima do plug encaixado; plug em pé mais comprido, com a ponta
    de metal mais longa; buracos da prateleira maiores, sem contorno preto, com o plug guardado entrando neles (antes
    parecia equilibrado em cima do buraco); os fios também saem de dentro do buraco, e o do FONE não deita mais na
    prateleira. Perto do buraco, fio e plug escurecem (a sombra de dentro dele).
53. Plugs e fios sem contorno preto (a beira na cor da peça, mais escura), como o cenário; o plug encaixado mais fino,
    deixando a aba da tomada à vista (dá para ver que entrou nela).
54. Prova de tudo em 2x2 com a fonte Tiny5 (branch `improve/0000-pixel-2x`, em espera): o texto ficava pior. A pedido
    do usuário, o jogo todo ficou em 1x1: o cenário voltou aos detalhes de 1 px (da história 48), numa tela na
    resolução da janela, o bloom em blocos de 1 px, e da prova vieram as peças redondas da mesa comutadora pixel a pixel
    (lâmpadas com aro, vidro e centro aceso). Os encaixes e o plug encaixado ficaram como estavam (o usuário os preferia).
55. O encaixe redesenhado pela referência do usuário (a mesma da branch 2×2), em 1x1: aro niquelado fino e furo preto
    largo, em pixel art.
56. Em telas maiores que 1280×720 os pixels "quebravam" (1,5× em 1080p): o jogo passou a ser desenhado sempre em
    1280×720 e ampliado com um filtro de pixel art (`GameView`, "sharp bilinear"), que deixa todos os pixels do mesmo
    tamanho em qualquer resolução (perfeitos nas ampliações inteiras).
57. Os plugs em pé na escala das tomadas novas (a ponta de metal da largura do furo, o cabo quase do tamanho do aro),
    os buracos da prateleira em pixel art (elipse com a beira de trás na sombra, a da frente na luz e a parede de
    dentro) e a tela em Configurações (cheia ou janela; ampliação suave ou pixels perfeitos com borda).
58. O relógio de parede analógico virou um relógio de flip na mesa, meio virado para o operador (depois com
    algarismos grandes desenhados à mão, base, rodinha, alarme e um creme menos claro); as outras peças
    redondas (botões do rádio, caneca, alfinete, parafusos) em pixel art como as tomadas; halo das luzes em degraus
    lisos, sem o pontilhado.
59. A perspectiva estava errada (o relógio torto): a câmera passou a sair de um operador sentado (altura dos olhos e
    distância ao tampo dão a distância focal), o relógio gira para os olhos por um cálculo e a frente dele é projetada
    de verdade.
60. Tomadas menores, com o furo da largura da ponta do plug, e o plug encaixado na proporção do em pé, com os mesmos
    detalhes. Mesa comutadora: lâmpadas de vidro leitoso (não pareciam mais tomadas), faixa ligando a coluna de cada
    linha, plaqueta de latão do fabricante no pé do painel, desgaste em volta das tomadas, chapas A/B com a letra
    estampada e o aviso pintado, fios de pano com dobras e trançado e a moldura com veios de verdade (a plaquinha que
    cai quando a linha chama foi testada e saiu: informação demais). O cartão de despacho sobe na mão e cai ao soltar.
61. Painel de baixo enxuto: saíram o bloco da ligação em foco e o do destino e das outras linhas (inúteis: a mesa já
    mostra); ficaram a tela da conversa (com a barra de agravamento e os avisos do visor), as teclas e o rádio,
    reestilizado como uma tela do console. Onde ficava o rádio, na frente da mesa comutadora, uma miniatura desse
    painel: o de baixo é a vista de perto dela. A conversa mostra as últimas falas que couberem, não só 3. O rádio
    guarda as mensagens anteriores na tela, a tela da conversa espera com o cursor piscando e a mesa comutadora só se
    redesenha quando algo muda.
62. A sala viva: a cidade vai apagando as luzes com a noite, a luz da luminária cai no painel da mesa comutadora, as
    teclas do console viraram teclas de verdade (chapa de metal, etiqueta de latão com o atalho, tecla baixa em
    relevo), a dica do manual e o horário do turno são papéis colados com fita (a plaqueta do turno saiu; na parede, a
    placa esmaltada da companhia telefônica) e o rádio ganhou um alto-falante perfurado na altura toda.
63. Clima noir: a sala fria e escura fora da luz da luminária (borda lisa, sem recorte), a luz dela mais forte e
    concentrada na mesa (o relógio ficava no escuro) e um brilho azul fraco vindo da janela (as faixas da persiana saíram).
64. A noite lá fora: carros passando com a luz dos faróis atravessando a sala, relâmpago e trovão na chuva e um
    letreiro de neon de hotel falhando, com o reflexo vermelho na parede.
65. A vista da janela pela referência do usuário: a telefonia no alto do morro, a rua dela com os carros passando e a
    esquina, a calçada, a mureta de tijolos com a escada descendo para a rua da cidade (no lugar do arbusto). Depois,
    profundidade: a cidade em camadas na névoa, a avenida fugindo para o horizonte e a luz e as sombras no chão; a
    esquina foi para a direita e, no lugar da escada, prédios de perto com o poste e o homem na frente; volume e
    escala nas coisas de perto; o homem e o carro na proporção da porta e dos andares dos prédios. Por fim, a vista
    passou a ter uma câmera de verdade (a sala no segundo andar, tudo em metros e na distância), e o carro é visto de cima.
66. A vista virou uma rua de verdade passando ao lado do prédio (referência do usuário). Primeiro com a câmera de lado
    e o ponto de fuga à esquerda (a rua parecia uma rampa vista de cima e os prédios, tortos); depois, a pedido, como
    uma cena 3D pensada antes: câmera na altura de quem está na janela, de frente para a rua, que passa na horizontal e
    continua para os dois lados, prédios verticais apoiados na calçada de lá, o cruzamento indo embora para o único
    ponto de fuga com a igreja no fim, o homem embaixo do poste da esquina, um carro passando e o arbusto plantado na
    nossa calçada. A mureta saiu. Depois, a nossa calçada, o nosso meio-fio e a faixa de pedestres saíram da vista (diziam
    que a nossa parede ia de frente, contra a diagonal da sala) e o arbusto passou para o primeiro plano, com a janela.
67. A janela parecia vista de cima: pela câmera, a parede dela fica a uns 44 cm da cabeça do operador, e o peitoril
    estava 38 cm abaixo dos olhos. O peitoril subiu (menos inclinado, a persiana subiu junto) e o vão ganhou a espessura
    da parede (o lado de dentro do batente, o fundo do vão, o vidro recuado com o caixilho de verdade) e um peitoril de
    dentro com o vaso.
68. Os olhos desceram para dentro da tela (`EYE`), na altura da janela: ela ficou reta, com a travessa no horizonte,
    o peitoril descendo pouco e a parede dela mais longe da cabeça. A vista da janela passou a usar o horizonte da sala
    (uma câmera só para o cenário inteiro). Em janela larga, os objetos da ponta entortam mais. Depois os olhos desceram
    mais (a janela e a vista juntas) e o armário cresceu para ~1,5 m, com prateleiras até a mesa.
69. Acabamentos da câmera nova: o ponto de fuga foi para o meio dos objetos da mesa (entortavam), o armário alto ganhou
    venezianas embaixo, puxador no meio e desgaste, um conduíte com a caixa de passagem leva os fios da mesa comutadora
    para o teto, o reflexo no vidro passou a ser a sala espelhada pela câmera e a vista ficou mais noir (asfalto escuro
    com as poças de luz dos postes, a vitrine do bar atrás do homem, a marquise do hotel, janelas fundas e névoa no
    fundo). O aquecedor embaixo da janela ficou de fora: com o peitoril a 24 cm do tampo, ele ficaria atrás da mesa.
70. A luz da rua na mesa passou a sair da janela de verdade (o vão projetado no tampo); um pedestre passa de vez em
    quando pela calçada de lá; o carro na chuva chia na água e o neon do hotel estala quando falha (abafado, de longe).
    A luz dos faróis varrendo a sala saiu; o peitoril e a guarnição de perto, que pareciam um buraco escuro, ficaram na
    luz de fora; a vitrine do bar ficou com duas divisões, longe da porta.
71. Sons da noite: o sino da igreja bate as horas de longe, a chuva cresce e diminui em ondas com as gotas no vidro e
    a calha pingando, a cidade se cala depois das 22h (menos carros e pedestres, grilos mais presentes), a luminária
    zumbe e estala quando pisca, a janela chocalha no trovão perto e os passos de quem passa soam de longe.
72. Os objetos da mesa girados uns graus, como largados (a pilha de listas desencontrada) em vez de retos e em
    fileira, e o mapa redesenhado como mapa de verdade (lia como papel quadriculado com um gráfico).
73. Os objetos da mesa redesenhados na identidade do jogo: o tampo dos objetos chatos posto pixel a pixel na
    perspectiva (torto por transformação, os pixels esticavam), cores de papel envelhecido em vez de branco, menos
    ruído (letra de mão espaçada, miolo das listas liso), a capa da lista com o título em baixo-relevo; menores, menos
    girados e com mais folga (estavam apertados e se encostando). Os testes voltaram ao tempo de antes (a vista da
    janela não é mais desenhada sem tela).
74. O relógio de flip ficou reto: meio virado para o operador, estava certo na perspectiva, mas parecia inclinado
    numa mesa plana (a única caixa alta girada entre as horizontais da sala).
75. A caneca redesenhada (parecia um balde): esmaltada de época, branco-gelo com a borda azul-marinho, alça em C e
    lascas, e o vapor do café subindo, que some com as horas porque o café esfria.
76. O alfinete do mapa parou de piscar e brilhar com emergência (um alfinete não acende; a dica dele saiu) e as listas
    telefônicas ganharam detalhes: na capa, o título dourado, o fone, a etiqueta do ano, a marca de caneca e a ponta
    dobrada; nas lombadas, a etiqueta do volume; no miolo, as folhas em linhas finas (numa imagem posta pixel a pixel:
    desenhadas tortas na tela, viravam degraus e faixas), as beiras sujas e tiras marcando páginas.
77. O vaso da janela foi refeito (um vaso de barro no tamanho dele na sala, posto pela câmera, com uma
    espada-de-são-jorge) e depois saiu, a pedido, com a planta: o peitoril fica vazio.
78. Os objetos da mesa na identidade da mesa comutadora (referência do usuário): o risco fino (texto, pauta, colunas)
    desenhado na tela em pixel art, não no papel em perspectiva (virava moiré); papel com 1 px de beira; os mais claros
    da tela (caneca, miolo das listas, capa) um tom abaixo; a capa das listas com o grão do papelão e o friso; o
    prendedor da prancheta em mapa de pixels niquelado, de pé (`CLIP_ART`), e a folha nova girada com a ponta dobrada
    (`SHEET_TURN`); a alça da caneca mais grossa; o lápis e as tiras do caderno com luz e sombra; o mapa e o jornal na
    paleta de papel envelhecido. Uma plaqueta de latão gravada no relógio foi testada e saiu (não combinava).
79. A chuva mais realista: o som em estéreo, com corpo grave (era um chiado agudo e parado) e vindo mais da janela, à
    direita; os pingos na janela caindo rápido, em riscos, e em maior quantidade. Gotas soltas (batidas, bolhas de poça,
    gotas no vidro, o pingo da calha) foram testadas e saíram: soavam como "tic".
80. A névoa de verdade: um véu liso que esconde o longe e engrossa rente ao chão, fiapos passando pela rua e as luzes dos
    postes e do neon espalhando nela (eram faixas retangulares no vidro, com a rua tão nítida quanto numa noite limpa).
81. A cidade mais viva: mais gente na calçada, às vezes em dupla, rareando até as 22h, quando ninguém mais passa; o
    homem do mistério chega andando, fica 15 min embaixo do poste e volta andando antes de ligar (antes, aparecia e
    sumia parado, por 5 min). Os passos de quem passa saíram: de dentro do prédio não se ouviriam.
82. As ferramentas abertas no material dos objetos da mesa (as cores em comum no `Pal`): a lista com a capa de papelão
    e as abas em tiras de papel, o caderno em couro (no lugar do pano verde, para se diferenciar das listas coloridas)
    com as tiras dos pendentes, o registro na tábua com o prendedor niquelado e o cabeçalho com o fio vermelho, o jornal
    no papel-jornal com a foto e as colunas (e aberto para ter arte e textos por noite) e a luz da luminária no papel.
    O mapa aberto deixou de parecer um diagrama: ruas de papel, bairros nos tons do mapa da mesa, casas e quintais,
    lugares de telhado de barro, a praça, a sanfona e o selo.
83. O mapa da mesa virou a miniatura fiel do mapa aberto (as mesmas folhas, quarteirões, casas, lugares, praça, zona
    rural e selo; o papel na proporção dos bairros atendidos). Antes, era uma cidade inventada, com rio e trem que o
    mapa aberto não tem.
84. Desempenho (medido com tela e sem vsync): a sala parada engasgava 3 a 4 vezes por segundo (o relógio virando e o
    neon a redesenhavam inteira, ~20 ms cada vez), e a cada quadro com a luminária piscando, no relâmpago e com o papel
    de uma ferramenta deslizando; eram ~2200 chamadas de desenho por quadro, mil delas do escuro da sala. Polígonos
    viraram primitivos, o que muda sozinho saiu da sala (a camada de cima, a textura do relógio, as duas camadas da
    vista), a tela do cenário só se desenha quando muda e os sons são sintetizados nos núcleos todos: na chuva, de 7,6
    para 2,0 ms por quadro, sem nenhum acima de 8 ms, e a abertura 0,6 s mais rápida.
85. A luz da rua na mesa maior e mais suave (era um quadrado pequeno perto da parede) e o relâmpago só no que a janela
    alcança, quase branco e nítido: a parede do fundo com a sombra do armário, a frente do armário, a lateral da mesa
    comutadora e a janela com a cruz do caixilho no tampo (era um véu azul e liso na tela inteira, até na frente da
    mesa comutadora).

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
