# Project Switchboard — memória do projeto

Jogo em Godot 4.6 (GDScript, renderer GL Compatibility), a caminho da versão definitiva. O jogador é o operador
noturno da central telefônica de São Sotero, cidade pequena (18:00–00:00; a última noite vai até as 6h). Mecânica: atender e transferir ligações numa
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
  `MonoLabel`, `InkMonoLabel`, `TapedNote`/`TapedLabel`: papel preso com fita, `TapedPaperStyle`, `MemoPanel`: o papel do
  memorando do supervisor, com a sombra na mesa, `LetterheadLabel`: o nome da companhia no timbre, `TypedText`/`HandText`:
  a tinta do datilografado e a caneta azul dos papéis escritos). Prefira variação de tema a override por nó. **Papéis escritos**: a
  tinta das letras é um efeito de RichTextLabel (`scripts/ui/paper_ink.gd`, sem `class_name`: `preload` e
  `install_effect`, um por `bbcode`): `[typed]`, datilografado (a fita mais fraca ou mais forte em cada letra, uma ou
  outra um pixel mais baixa), e `[hand]`, à mão (a linha subindo e descendo devagar, na caneta azul, `Pal.PEN`). Telas
  fora do turno no papel: a abertura da noite é o recado do supervisor num bilhete com fita preso no painel da mesa
  comutadora (`Intro`, `over`; a sala escurecida atrás e, ao começar, o bilhete some e ela clareia, `FADE_SEC`; como se
  joga, num papel de MANUAL como o da dica da parede, hoje escondida: `scripts/ui/CLAUDE.md`), a pausa e as configurações num papel com fita (rótulos em
  `InkLabel`) e o relatório é um memorando (`ReportView`: timbre com o fone e o nome da companhia, fio duplo, dobras em
  três, texto datilografado, cada advertência com o carimbo da gravidade, `SEVERITY_COLORS`, a borracha falhando, o
  parecer à mão e a rubrica do supervisor; a sala fica à vista, escura, atrás dele, `Ending.REPORT_DIM`).
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
- Todo o áudio é sintetizado ao iniciar por `SfxSynth.build()` (`scripts/sfx_synth.gd`: as receitas, 268 sons, 7,1 MB;
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
  22h à meia-noite os grilos sobem e a brisa baixa (`Sfx.set_late`, `LATE_*`); no amanhecer da última noite os grilos
  param (`Sfx.set_dawn`, `Background.CRICKETS_QUIET`), o sabiá-laranjeira canta ainda no escuro (`sabia`, frases de
  flauta, `SABIA_TAKES` versões, `SABIA_FROM`; o galo saiu, a pedido), passa o primeiro
  caminhão (`FIRST_TRUCK`) e o sino que bate as 6h fecha o turno (segue por baixo do relatório); o zumbido elétrico de 60 Hz da sala fica baixo (`Sfx.HUM_DB`; a -29 e a -37 dB cansava, sobretudo em fone; antes da
  ligação desconhecida baixa para `HUM_HUSHED` e, depois dela, some); a luminária zumbe bem baixo, seguindo a
  luz dela (`lamp_buzz`, `Sfx.lamp`, `LAMP_BUZZ`), e estala quando pisca (`lamp_tick`); `Background.weather` desenha a janela, `Conversation.topics()` junta os
  assuntos gerais com os do clima (`ChatTopic.weather`).
- **Resolução: tudo em 1x1 sobre 960×540, ampliado só em múltiplos inteiros (pixels perfeitos).** A cena principal é
  `scenes/app.tscn` (`GameView`, `scripts/ui/game_view.gd`): o `main.tscn` dentro de um `SubViewport` de 960×540 (o
  `View`, "nearest"; o padrão do `SubViewport` é linear e não herda o do projeto), ampliado para a janela pelo `Box`
  (`SubViewportContainer`, "nearest") no maior múltiplo inteiro que cabe (`GameView._fit`): 2× em 1080p, 4× em 4K; o
  que sobra é borda escura (1× com borda em 720p e 1600×900, 2× com borda em 1440p). Menor que 960×540, reduz. A `View` prende transformações e vértices aos pixels (`snap_2d_*`: o que anda, como o cartão na mão a meio pixel do mouse a 2×, não cai entre dois pixels; só nela, porque a opção do projeto vale para a tela raiz, e não no cenário, parado e em perspectiva). A fonte continua com suavização: medido, sem ela o texto sai igual, porque já cai inteiro nos pixels. (Antes,
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
  varredura. **Gradação de cor** (plano hi-bit): o `Box` mostra o jogo por um shader (`scripts/ui/grade.gdshader`,
  `GameView.grade_material`) que passa cada pixel por uma conta de cor (as sombras puxando para o azul da noite, sem
  clarear, os tons médios na luz, a madeira e as lâmpadas, para o quente, `warm`, e um pouco mais de contraste;
  parâmetros no shader, em vez de uma tabela numa textura), ponto a ponto no pixel já ampliado: o pixel perfect
  continua. Os tons claros ficam como são (`spare`): aquecidos, o papel das ferramentas e do relatório amarelava.
  Cada clima tem a sua (`GameView.GRADES`: a noite limpa com mais contraste, a chuva mais fria, a névoa mais lavada),
  posta pelo Main quando o clima é definido e trocada aos poucos quando ele muda (`GameView.grade_weather`). A captura passa por ela também (`tools/shot.gd`; `--grade=0`
  sem); o painel de debug liga e desliga na hora (seção Clima, `GameView.set_grade`); o `main.tscn` sozinho e os
  testes ficam sem.
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
  `Bloom.clear(self)` no começo do `_draw` e `Bloom.light(self, rect, cor, halo, core, round)` por luz acesa (`parts`:
  a luz é a junção de vários retângulos e o halo, um só, segue a forma dela, como o letreiro do hotel, em T) (lâmpadas
  redondas da mesa, `Switchboard._draw_lamp`, com aro niquelado, `BEZEL`; aro da tomada de destino, sem miolo;
  luzes das máquinas do cartão; barra de agravamento; janelas acesas do `Background`, que desenha em 2×). ColorRect e
  Label no grupo "bloom" brilham na cor deles (luzes do rádio). Luz
  sem miolo tem o halo fraco por dentro (`HOLLOW`); luz de quem recorta o conteúdo (`clip_contents`) é recortada também.
  O que fica na frente das luzes de quem desenha (os plugs encaixados da mesa) entra com `Bloom.occlude(self, polígono)`:
  os blocos do halo cobertos por ele somem (`_cut`, guardado; plug parado não refaz). A máscara só vale para as luzes
  do mesmo dono: na mesa, a camada das lâmpadas registra as duas.
- **A luz** (plano hi-bit): **nada de `PointLight2D`** (dentro do `SceneView` ela obrigaria a
  redesenhar a sala a cada mudança da luz; o `check.sh` acusa). O cenário é desenhado sem as luzes que mudam, e elas
  entram depois, por parâmetros: a luminária no shader do `SceneView` (`lamp_light.gdshader`, a poça somada;
  `Background.light` passa os parâmetros a cada quadro), o escuro da sala numa camada no meio dele (`_noir`,
  `room_noir.gdshader`, `_noir_params`), as luzes de fora e as lâmpadas dos objetos no tampo (`_window_lights`,
  `window_lights.gdshader`, até 8, `_window_light_list`), as lâmpadas da mesa comutadora no painel (`_glow`,
  `board_glow.gdshader`, até 16, pelo `Bloom.lights_of`), a luz do dia nos shaders da sala (`Background.daylight`) e a
  gradação do jogo inteiro no `GameView`; na vista, a luz do sol no chão em duas camadas, uma que multiplica e uma
  somada, entre o chão e o que fica em pé (`_draw_sun_strip`, `_lit`). Luz com forma (o relâmpago, `_bolt_layer`; o sol, `_sun_layer`) é uma
  camada somada (ADD), com a força no `modulate` e o desenho refeito só quando a geometria muda. **Para acrescentar uma
  luz**: só o ponto aceso brilhando, `Bloom.light` no `_draw` de quem a desenha; acendendo em volta no cenário, uma
  entrada em `_window_light_list` (lugar, alcance e força, cor; as de dentro primeiro, até 8); no painel da mesa
  comutadora, declarada ao `Bloom` na camada das lâmpadas (o `_glow` pega); com forma (uma abertura projetada), uma
  camada somada como a do sol. Todo parâmetro que o shader lê entra no estado comparado (senão ele fica com o valor
  velho), e a cor dela vai no `Pal`.
- Pixel art desenhada em `_draw()`; cores e fontes em `pal.gd` (`Pal.*`). **Área cheia em `draw_primitive`, não em
  `draw_polygon`**: cada `draw_polygon`/`draw_colored_polygon` é uma chamada de desenho (e cria um polígono a cada
  redesenho); `draw_primitive` (até 4 pontos) seguidos **com o mesmo número de pontos** viram uma só (triângulo e quadrilátero
  alternados quebram o lote a cada um: os fiapos de nuvem do amanhecer davam 2900 chamadas; `_light_fan` desenha os
  triângulos todos e depois os quadriláteros). O cenário tem `Background._fill`/`_poly` (o
  quadrilátero inteiro; o resto, em triângulos); a sala passava de 2000 chamadas por quadro. **Os materiais dos objetos da mesa** (capas, miolo, página e etiqueta da lista,
  fita e papelão do bloco de fichas, a letra a lápis e o lápis dele, os carimbos do caderno, tábua, folhas e letra da prancheta, papel-jornal com a tinta, a beira e a foto, o bilhete de tarifação com o formulário e a tinta do carimbo, papel e tons do mapa, o cartão do despacho, níquel, latão (o das plaquetas e o dos plugs), a baquelite, os cabos, o vermelho do formulário, a madeira e a borda do tampo, o relógio de flip e o café da caneca; e os da sala: a parede, o vão da janela, a persiana, o armário de aço com o cromado, o conduíte, a folhinha e o cartaz; e os da vista: o céu, a lua e as nuvens, a cidade de longe, as fachadas, a rua com os postes, o bar, o hotel, a varanda, a igreja, o arbusto, os carros, quem passa, os bichos e o letreiro) são
  constantes do `Pal`, usadas pelo objeto (`Background._art_*`) e pelo papel aberto dele: o que muda numa ponta muda na outra. **Rampas de material** (plano hi-bit): `Array[Color]` no `Pal`, do escuro ao claro, a sombra
  puxando para o frio e a luz para o quente; o desenho escolhe o tom pelo nível de luz com `Pal.ramp(tons, luz)`, em
  degraus, no lugar de escurecer por cima (por ora, a caneca, o aro das tomadas, `JACK_METAL`, a madeira do tampo,
  `Pal.desk`, o móvel da mesa comutadora, `Pal.cabinet` e `Pal.panel_metal`, os papéis da mesa e a unidade de
  despacho dela, `Pal.lit`, que leva um tom degraus acima ou abaixo na rampa em que ele está, a de um papel,
  `PAPER_RAMPS`, ou a do metal, `PANEL_METAL`; a unidade de despacho, pequena e de metal, fica toda no degrau da luz
  no meio dela, `Background._lit_image`, porque a troca de degrau andando de uma linha para outra, a dos papéis,
  listrava o metal como escovado; nas máquinas abertas, a beira das chapas em dois tons dela de cada lado,
  `CardMachines.bevel`; as peças de metal paradas do painel da mesa comutadora, num degrau da luz da sala no meio
  delas, `Pal.panel_step`, o mesmo do relevo; a máquina do calculógrafo da mesa, a mesinha, o carimbo e a caixinha
  num degrau só, `_clock_box` com `tone`; os plugs e os fios, que andam, continuam na luz multiplicada, `_lit_by`,
  porque uma paleta por degrau, por ângulo e por cabo encheria o cache do `PixelArt`; a parede do fundo, o conduíte e o
  armário pela luz da luminária na parede, só na cor, `CONDUIT`, `STEEL_TONES` (a parede, num tom só: em faixas, a
  beira delas fazia um arco duro ao lado do armário, pedido 275; o conduíte e o armário, num degrau só cada um, pedido 279), porque o escuro
  pela distância já é o da sala, `_noir`, e dobraria; na vista, as fachadas e as paredes da rua do cruzamento,
  `Pal.FACADE_TONES` e `BRICK_TONES`, o asfalto e a calçada, `ASPHALT_TONES` e `SIDEWALK_TONES`, e a quina do
  meio-fio, acesa embaixo de cada poste, `CURB_LIT`, a lataria dos carros e o baú, `CAR_TONES` e `TRUCK_BOX`, e a
  beira do letreiro, tingida pelo neon, `SIGN_BOX`; `step` pega o tom acima ou
  abaixo, para veios e beiras). **Uma fonte só, de pixel: Departure Mono**
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
  - `tests/test_flow.gd`: cenários dirigidos (transferência, espera, desistência, caderno, destino que não atende, ligar de volta ao desconhecido, cliques, clima do som, a altura do painel de baixo numa emergência com aviso e quatro fileiras de respostas).
  - `tests/test_keys.gd`: as teclas (1, Espaço, Tab, X, Esc e despausar) entrando pela janela, pelo `GameView`.
  - `tests/test_layout.gd`: em 960, 1125 e 1281 px de largura, nenhum objeto da mesa por cima de outro na tela (o
    contorno de cada um como o cenário o desenhou, `Background._occ`/`occ_ids`; a caneca na frente do relógio é de propósito).
    Mexeu na disposição da mesa: rode este.
  - `tests/test_penalties.gd`: consequências (perdida e retorno, número errado, registro, despacho errado,
    emergência sem despacho, espera longa, informação errada) e o relatório. Relógio parado; retornos tocados à mão.
  - `run.sh` começa com `--import`: **`class_name` novo só existe depois de reimportar** (sem isso, parse error).
  - `tests/test_shift.gd`: robô que joga o turno inteiro e imprime métricas (máx. simultâneas, % com 2+/3+,
    % sem cabo livre, perdidas, maior silêncio); `run.sh` roda com `--seed=1..3`, um turno `--clumsy` (deixa de atender 1 em 3),
    a noite 2 (`--night=2`), a 15 (`--night=15`, até as 6h) e um turno `--human` (5 s de jogo por ação, como uma pessoa: **é este que mede se o ritmo
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
  Limpar é o `calm`, que também apaga as denúncias), velocidade 1–8×, pula o relógio, troca o clima na hora (`Main.set_weather`), liga e desliga a gradação de cor (`GameView.set_grade`), a luz da luminária no shader do cenário (`SceneView.lamp_light`) e a luminária piscando (`Main.flick`), faz passar um carro lá fora, na mão de lá ou na de cá e do modelo escolhido (`Background.pass_car`), encerra o turno, troca de noite (`_go_night`: troca o Main por um novo na noite anterior/seguinte, no mesmo pai, dentro da tela do `GameView`; posto na raiz, saía na resolução da janela e quebrava o layout; sem ler nem
  gravar o progresso, para testar a entrega dos setores; o "Amanhecer" abre a última noite já às 4h, com o relógio
  no `minutes` do Main novo e a agenda de antes dela descartada no `_ready`), libera viaturas (`Dispatch.reset`; `_gen` cancela
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
  recorte ampliado 4× (`_zoom.png`); `--hover=id` põe o mouse num objeto da mesa (ele erguido e a etiqueta com o nome); `--debug=N` abre o painel de debug na aba N; `--punch`, com `--card`, perfura o cartão, põe uma unidade fora e a etiqueta de um trecho no mapa, e `--card=closed` guarda o despacho com o cartão na mesa; `--car=fusca,sedan` põe um carro de cada modelo parado na rua da vista, o de lá e o de cá (`-` deixa a mão vazia; `--car_t=0.45` onde, de 0 a 1; `--rack` com o bagageiro); `--walk=2,-4` gente parada na calçada de lá nesses x (m) e `--walk_z=20,45` na da rua do cruzamento, a essas distâncias; `--bar` a porta do bar aberta; `--blind=1` a persiana descida (0 a 1); `--bolt` um relâmpago caindo na hora da captura; `--smoke[=s]`, `--cat`, `--bike=x` (`--papers`: o menino do jornal), `--damp=N`, `--phones=2,1`, `--sips=N`, `--cabinet`, `--written=N`, `--read`, `--taxi=s`, `--dog=x`, `--patch=312,4` (quem fuma na varanda, `s` segundos depois de sair, o gato, a bicicleta, a mancha de umidade, os telefones da vista, os goles da caneca, o armário aberto, o lugar do lápis no bloco, o jornal já lido, o táxi parando no hotel a `s` segundos de aparecer, o vira-lata, um cabo de conexão da saída da linha 4 encaixado no destino, com o aro aceso); `--lines=2:ring,4:conn` as lâmpadas dessas linhas nesse estado, sem ligação; `--screen=intro|pause|settings|report` as telas fora do turno; `--grade=0` sem a gradação de cor; `--lamp=0` sem a luz da luminária no shader do cenário; `--dim=0.2` a luminária presa nesse nível, como no meio de uma piscada; `--still` sem a poeira do feixe, que muda a cada captura (para comparar pixel a pixel: `tools/diff_shots.gd` compara duas pastas de capturas, imagem por imagem, ignorando os retângulos dados, como a vista da janela e a fala na miniatura do painel, que também mudam sozinhas); as opções do jogo (`--night`, `--seed`, `--lang`) também valem. Para conferir
  mudança visual medindo, não só olhando a captura. `tools/hibit_shots.sh build/hibit/<pasta>` grava o conjunto de
  capturas do plano hi-bit (sala nos três climas em três horas, a caneca, a mesa comutadora, o tampo, as ferramentas
  e o amanhecer da noite 15), para comparar com `tools/diff_shots.gd`; a pasta tem que ser relativa ao projeto.
- **A vista no amanhecer desenha ~17 mil itens por quadro** (a fachada tijolo a tijolo, o chão da rua do cruzamento):
  acima do buffer do renderizador de compatibilidade (`rendering/gl_compatibility/item_buffer_size`, 16384 no padrão),
  o Godot 4.6 às vezes trava (`_render_batch`, "Index p_index = 1 is out of bounds", conforme o comando que cai na
  virada). O `project.godot` o põe em 32768 e o `test_layout` confere (o editor aberto pode regravar o arquivo sem a
  linha). Quem acrescentar muito desenho à vista, meça os itens (`Viewport.get_render_info`, `RENDER_INFO_OBJECTS_IN_FRAME`).
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
  borda da frente da mesa da sala, no tom de embaixo da luminária (`Pal.desk(1.0)`, `Pal.desk_edge(1.0)`; o papel
  dela é `Pal.DESK`). A almofada tem a tampa aberta atrás e o brilho
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
  para a ficha do caderno ("Bilhete nº 0002", `PhoneCall.Record.ticket`). Bilhete esquecido na mesa: no fim do turno ele
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
  vermelha das emergências (`Pal.CARD_FORM`, a do carimbo do caderno: faixa com o número, rótulos, posições de furo, fio duplo,
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
- No fim do turno (`Main.shift_end`), `start_ending` (`Supervisor.shift_over`) soma o que ficou sem registro e passa o relatório para `Ending.play(report)`, que mostra
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
  `last_call - MYSTERY_MARGIN` (23:30): o botão Encerrar turno só aparece depois dela.
- **Ligação do roteiro toca sozinha** (`Main._scripted`: `story` ou a desconhecida): espera a mesa em silêncio por até
  `Schedule.STORY_WAIT` (30 min, `latest`) e, enquanto ela está na mesa, nenhuma outra toca (o robô confere).
- **Mesa parada demais**: vazia por `QUIET_SHARE` do maior `Pace.call_gap`, toca um pedido de informação a mais
  (`Main._fill_quiet`; não com uma do roteiro a menos de `STORY_GAP`, nem depois de `last_call`). O robô mede a maior
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
- Turno das 18:00 (`SHIFT_START_HOUR`) até o fim da noite (`Night.shift_end`, minutos depois do início, no
  `Main.shift_end`: 360, a meia-noite; a última noite, a 15, vai até as 6h, 720, para o dia nascer); fim **depois** da
  ligação desconhecida ter caído (`start_ending`). A plaqueta do turno, o relatório e o painel de debug leem o fim
  dela; os horários passam da meia-noite pelo `Main.fmt`. A hora do dia no cenário (`Background.minutes`) passa de
  1440 depois da meia-noite: o que compara com ela continua valendo. **O clima que abre** (`Night.clears_at`, a 15 à
  meia-noite): a chuva afina até a garoa e o véu da névoa some nos `CLEAR_SPAN` min antes (`Background._clearing`) e,
  na hora, a noite fica limpa (`Main.set_weather` em `CLEAR_SEC`). **O amanhecer**, pelas
  horas de verdade de 22/10/1973 a ~22° S (`Background.DAWN`, `SUNRISE`, `STREET_OFF`, `MORNING`): o céu, numa camada
  própria embaixo da cidade (`_sky`, `_draw_sky`; o vidro, `_pane`, por cima: o reflexo some com o dia), é um
  degradê de quatro tons do alto à vista até o horizonte (`Pal.DAWN_SKY`, quadros de 4 cores, e `DAWN_STOPS`;
  `_sky_stops`, `_sky_tones`): do azul-escuro ao azul-esverdeado no alto, rosa, laranja e amarelo embaixo enquanto o
  sol nasce, e às 6h o azul do dia no alto e só o horizonte num dourado claro (o quadro das 6h, pedido 273: laranja até
  o fim parecia o sol ainda nascendo; e `DAY_SKY`, `_day_sky`, o quanto as nuvens, o clarão e o halo já são de dia: de
  dia, branco e azul até embaixo, o sol sumia no horizonte claro, pedido 267); as nuvens tingem junto. As estrelas somem até 4h30, a lua
  empalidece e o sol nasce às 5h25 **atrás da igreja**, no fundo da rua do cruzamento (a janela olha para o leste; `_sun_at`,
  `_draw_dawn`: o disco, pequeno, `SUN_DISC` raios (pedido 256), quase todo miolo branco, `Pal.SUN_CORE`, o amarelo, sem beira, e
  por cima o brilho branco saindo dele e esmaecendo, `SUN_GLOW`, e o halo amarelo, sem laranja, que encolhe e branqueia com o dia, como o clarão do horizonte some, para o azul não ficar cinza; desenhado por cima das nuvens: um banco passando o apagava), e sobe devagar ao lado da torre, meio atrás dela e ainda baixo às 6h, como na referência
  do usuário (`SUN_LOW`; os prédios altos do fundo abrem um vão ali; a torre fina, `CHURCH_TOWER`, mais baixa a pedido, 267, com
  o campanário vazado, o céu atrás do arco e o sino, `_sky_at`, e a escadaria no pé da igreja). Os raios
  crepusculares saem dele num leque liso, por cima das nuvens (`_draw_crepuscular`: `RAYS` fatias, a cor em cada beira, a força variando
  devagar com o ângulo; fatias finas de força sorteada riscavam o céu), e onde a igreja tapa o sol a sombra dela,
  quase preta, vira um feixe escuro (`_church_cover`, `_church_parts`, os polígonos que `_draw_church` desenha; `RAY_SHADOW`).
  Na frente da cidade, numa camada somada (`_rays`, `_draw_rays`), com o sol à vista (`_sun_seen`):
  os reflexos na linha do sol ao meio da vista (`FLARES`, `Pal.FLARE`, somindo perto do sol, onde pareciam um segundo
  sol; o risco horizontal da lente, cortando o sol, saiu, a pedido). A igreja fica escura contra o sol, arroxeada (`Pal.CHURCH_DAWN`), e nada de luz na frente dela (a beira acesa em volta, o brilho do sol somado por cima e o clarão e a neblina dourada na boca da rua saíram, a pedido: a luz parecia atravessá-la). Com o
  sol (`_sunlit`; a referência é uma imagem do usuário), a parede da direita da rua do cruzamento, de costas para
  ele, fica na sombra, só com a cornija acesa, e a da esquerda, virada para ele, pega a luz de raspão, fraca, porque o sol está quase no eixo da
  rua (`WALL_LIT` 0,2, ~1/4 da do chão), inteira e sempre que o chão pega, das 5h15 às 6h: a sombra da parede da frente
  no chão nunca chega até ela (pedido 264: as duas na sombra, pedido 258, deixavam o chão aceso e as paredes não;
  pedido 266: uma sombra subindo por ela, pela conta do sol, a escurecia até as 5h30 com o chão ainda aceso), e as duas somem no ar dourado no fundo.
  Os vidros dela espelham o dia (`_sun_glass`, pedido 279): o céu na altura de cada janela (a reflexão numa parede de
  pé não muda a altura do raio), tanto mais quanto mais de raspão (o Fresnel, `WIN_SKY`; a do primeiro andar espelha
  a parede da frente, na sombra, e fica escura), e o sol, somado, de onde ele volta para cá (`_glint_z`: vem do fundo
  da rua e chega mais perto com ele indo para a direita do eixo, `WALL_GLINT`) e das folhas abertas, cada uma na sua
  hora (`WIN_OPEN`; o sorteio de cada janela por `rand_from_seed`: o `hash` dela sozinho seguia a altura e só o
  primeiro andar brilhava); as de perto que brilham mais ganham um halo na `_rays` (`_glints`, `GLINT_HALO`; o das de
  longe, juntos, faziam um clarão no fim da rua, como um segundo sol). Os prédios de lá, de costas para o sol, ficam todos na
  luz fria do céu (`Pal.DAWN_SHADE`), com a cornija acesa (a luz quente e uma sombra descendo nas fachadas da direita
  saíram, a pedido: não tinham de onde vir); o alto delas clareia na luz do céu (`SKY_TOP`) e, junto da boca do
  cruzamento, embaixo, pega o rebatido quente da faixa de sol (`BOUNCE`). **Textura com forma, não grão** (pedido
  244; pontos soltos pareciam sujeira): em todas as noites, as fachadas de lá têm o uso de anos (`_draw_facade_wear`:
  tijolo a tijolo, `BRICK_VARY`, com as juntas de pé num `draw_multiline` só, e a tela andando por igual na fachada,
  sem `_o` a cada peça, porque o fundo da vista redesenha ~11 vezes por segundo; frisos, pilastras, molduras e
  remendos no reboco, rodapé de pedra, encardido, cano de descida, escorridos embaixo dos peitoris) e as paredes da
  rua do cruzamento as fiadas e os remendos translúcidos por cima do degradê da luz (`CANYON_GRAIN`). O resto da rua fica na sombra dos
  prédios de lá (`STREET_SHADE`, em `Pal.DAWN_SHADOW`, azul-violeta) e a faixa de sol entra pela rua do cruzamento e atravessa a nossa (`STRIP_A`, numa
  cor só, alaranjada, `Pal.SUN_STREET`, a mesma da luz do sol nos prédios, na parede de raspão, nas cornijas e no
  rebatido; com `SUN_RIM` saía amarela, pedido 265; com o sol subindo, toda essa luz clareia para a do dia,
  `Pal.SUN_HIGH`, `_sun_tint`, `SUN_PALE`, e a faixa e a sombra da rua se apagam, `SUN_FADE`: laranja e forte até as
  6h, pedido 273; reta, a `STRIP_EDGE` das paredes, e as beiras esmaecendo da sombra à luz sem degrau, a da sombra da parede
  mais larga quanto mais comprida ela é, `STRIP_SOFT`, pedido 261; antes, dois degraus com os tons misturados e, antes
  deles, direto do violeta ao laranja, as cores não se misturavam; mais vermelha para cá, `STRIP_NEAR`,
  `Pal.SUN_DEEP`: amarela no fundo, por cima do violeta, ficava cáqui; e mais clara e dourada na boca do cruzamento,
  mais cheia ali, `STRIP_MOUTH`; com o sol à direita do eixo da rua, `SUN_LOW`, a parede da direita deixa a sombra
  dela no lado direito da faixa, prédio por prédio da rua do cruzamento, cada um na altura dele, `_wall_ratio`: quase toda logo depois de ele nascer, rente ao horizonte, e só encolhendo com ele
  subindo, o lado do sol fixo no das 6h (ia e voltava, pedido 271); pedido 260; e nela o sol espelhado no asfalto úmido, embaixo dele na tela, nas marcas dos pneus, lisas e
  úmidas, em fios quebrados onde o asfalto secou, e no resto do asfalto só de leve, `_draw_glints`, `GLINT*`: sem ele a
  faixa parecia um vidro amarelo, pedido 262; em brilhos curtos sorteados, saía um confete branco, e numa coluna
  quebrada em faixas, manchas ovais; pedido 263). As marcas dos pneus ficam em todas as noites, ao longo da nossa rua
  e indo embora pela do cruzamento (`TRACKS_NEAR`, `TRACKS_FAR`, no `_draw_street`); o chão da rua do cruzamento tem o detalhe do da nossa, até
  `CROSS_DETAIL`: manchas, remendos, a tampa do bueiro, rachaduras, a mancha de óleo do carro estacionado, a sarjeta, a
  face dos meios-fios, a da esquerda acesa pelo sol, e as juntas das calçadas, `_draw_crossing_ground`, pedido 264). A sombra da rua não é por igual
  (pedido 263): mais escura perto e mais clara no longe (`SHADE_DEPTH`), quente junto da faixa, a luz rebatida dela
  (`BOUNCE_SHADE`), e mais escura junto dos meios-fios (`SHADE_CORNER`). **A sombra e a faixa são luz, não tinta** (`_draw_sun_strip`): a vista
  de trás é desenhada em três camadas, o chão (`_back`), a luz nele e o que fica em pé (`_upright`, `_draw_city_upright`:
  os postes da rua do cruzamento, a sombra do nosso prédio, as paredes e as fachadas); a sombra multiplica o chão
  (`_street_mul`, `BLEND_MODE_MUL`, sem a luz do dia) e a faixa soma (`_street_add`, com ela), as cores escritas como
  a pintura ajustada à vista e passadas a luz por `_lit` (no tom do asfalto dá a mesma cor, e as manchas, o grão e as
  rachaduras continuam embaixo); pintadas por cima, cobriam a textura (a faixa ficava chapada, só com as rachaduras
  riscando) e cada superfície acesa pedia um remendo; luz nova no chão da vista entra nessas camadas; e só nela quem passa, os carros e os postes de lá deixam as sombras
  compridas, encurtando com o sol subindo (`_sun_shadow`, `_shadow_k`), só dentro da faixa de sol (`_strip_end`; a
  sombra da parede da direita pela altura dela, `_wall_shade`); a dos postes some a `POST_UMBRA` m (inteiras, emendavam
  numa listra). As manchas do asfalto têm a beira torta (`_blot`, em quadriláteros, `_convex`: em triângulos quebravam o
  lote, de 380 para 870 chamadas; retas, a faixa de sol virava uma colcha). O teto e os vidros dos carros pegam o sol, e a copa da
  árvore acende de verde-amarelo, mais no alto e na beira de cima de cada tufo (`Pal.LEAF_SUN`); o asfalto úmido do sereno espelha de leve os faróis e as lanternas (`DAMP`) e, mais, a vitrine
  do bar, a porta do hotel e as vitrines acesas do térreo (`_mirror`, `MIRROR_A`, retas embaixo delas, como na chuva; na frente da vista e
  cortadas pelo chão dos carros, `_car_ground`, como os riscos dos postes e do letreiro, `_car_cuts`: no chão,
  apareciam numa listra de luz pela sombra do táxi parado no hotel, pedido 276),
  e as poças da chuva da noite espelham o céu (`_draw_puddles`, `PUDDLES`); de manhã mais gente vira a esquina, vindo
  de mais longe pela rua do cruzamento (`WALK_CORNER_DAWN`, `TURN_FAR`), e lá, contra o sol, quase em silhueta
  (`Pal.BACKLIT`), com a beira acesa só na faixa de sol e de perto; o porteiro fica na porta do hotel; de manhã
  mais carros vêm com o bagageiro (`RACK`), passa o menino do jornal de bicicleta (`PAPERBOY`) e às 5h30 o dono abre o
  bar e fica no vão da porta (`BAR_OPENS`; pela vitrine, a prateleira com as garrafas e o balcão; ela e a porta do
  hotel no `_sunny`, sem a luz do dia por cima, que as estourava); na sala, a poeira dourada no feixe do sol (`SUN_DUST`, `_sunbeam`); com os postes apagados, as vitrines acesas deixam a luz na calçada (`SHOP_POOL`). A neblina
  baixa no fundo da rua some com o sol nascendo (`_draw_dawn_mist`), as nuvens se acendem por baixo (`Pal.DAWN_CLOUD_TOP` no
  alto), fiapos de nuvem cobrem o céu (`_draw_cirrus`, `CIRRUS`) e bancos de nuvem em faixas largas, de beira nítida, com a beira de baixo acesa
  rosa e, com o sol, laranja, descem até o vão da rua do cruzamento (`_draw_banks`, `BANKS`; pedido 259, como na referência) (os passarinhos, bandos em V e os pombos saindo da
  torre, saíram, a pedido). A cidade clareia pelo `modulate` da `_back` e da `_view` (`DAY_GAIN`, `DAY_WARM`; a cor das luzes do sol na
  cidade sai dele, `_sunny`, senão o laranja estourava no amarelo-cáqui; atrás da igreja, prédios altos num terceiro
  plano no ar dourado, `FAR_ROWS`; um
  shader nelas desfazia o lote das chamadas de desenho), postes e neon apagam às 5h15 (`_posts_on`, `_sign_on`),
  janelas acendem de madrugada e ficam (`WAKE_DAWN`) e a rua volta a ter gente e carro das 5h às 6h (`morning`). Na sala, a luz do dia entra pela janela só por
  parâmetros (`Background.daylight`: a cor do céu, fria, e com o sol a dele, quente, `Pal.DAYLIGHT_*`; a força em
  `DAY_ROOM`, em degraus de 1%, menor com a persiana descida): o escuro da sala recua a partir da janela
  (`room_noir.gdshader`), a luz dela clareia o que está perto e a luminária perde metade da força
  (`lamp_light.gdshader`, `window_at`, `reach`), o sol baixo entra direto (`_sun_layer`, `_draw_sun`, somado,
  embaixo dos objetos da mesa, a força no `modulate`): o fundo do vão e o tampo do peitoril acesos, com a sombra
  do batente de longe atravessando-os na direção do raio e a beira delas em degraus de 1 px
  (`_draw_sun_sill`; as quinas do peitoril e do vão ficam nítidas), e a janela desenhada
  no tampo, nítida, um retângulo só, saindo da parede em ângulo (`_wall_x`; com um x só, a beira da luz não acompanhava o peitoril, pedido 271) (a conta do relâmpago com o raio mais baixo, `SUN_STEEP`, que mal muda até as 6h e por igual, `_sun_steep`: encolhendo
  até a parede, parecia o sol já a pino; logo depois de nascer ela é fraca e de beira espalhada, `SUN_FAINT`,
  `SUN_SOFT`, cortada no fundo da mesa reto na tela como a nítida, `_below`: com o canto preso nele, a beira dela
  atravessava a sombra do relógio e parecia uma segunda sombra, pedido 274, e fica forte e nítida com o sol subindo, `_sun_up`), e nela a sombra
  comprida da caneca e do relógio (`SUN_CAST`, pelos contornos `_occ` da última vez; uma mancha redonda de luz parecia
  lâmpada), com a da luminária, que continua acesa, sumindo: ela fica numa camada embaixo do sol (`_shade_layer`,
  `_lamp_shades`, do `_desk_shadow`), apagada pelo dia no `modulate` (`LAMP_SHADE`; às 6h o relógio tinha duas
  sombras, pedido 273); o raio, a janela no tampo e as sombras vão todos na mesma direção na tela, para a esquerda e para baixo,
  na linha que o usuário traçou da quina de baixo da janela à frente da mesa (`SUN_SHIFT`, `_sun_ray`, pela altura na
  tela, pedido 272: em perspectiva, com o sol quase de frente, saíam em leque e cada uma ia para um lado; antes, reto
  para a esquerda, a sombra não batia com a luz), a beira da luz de longe passa pela quina do batente no vidro, e a de
  perto é a sombra da parede depois da janela, e a beira da caneca e do relógio
  virada para ele acende, quente, numa camada somada por cima deles (`_sun_edge`, `_draw_sun_edge`, `SUN_EDGE_A`:
  tirada do desenho de cada um, `_mug_rim`, `_clock_rim`, só se o raio pelo alto deles cai na janela do tampo), a mesa comutadora clareia de leve (`Switchboard.dim`,
  `DAY_LIFT`), o brilho da luminária e o halo do `Bloom` enfraquecem (`Main.DAY_DIM`) e a gradação vai para a do dia
  (`GameView.DAY_GRADE`, `grade_day`: mais contraste e saturação, `saturation` no `grade.gdshader`), e a luz do sol
  nascendo acende a moldura, o peitoril e o arbusto (`SUN_LIGHT`, a primeira de `_window_light_list`). Nada disso redesenha a sala.
- **Fim do turno**: nada novo toca depois de `last_call` (`LAST_CALL_BEFORE` antes do fim, 23:40; sorteadas param ali e `_run_schedule` descarta
  retornos e atrasadas; a desconhecida tem regra própria). A partir daí, com a desconhecida já passada, o botão
  **Encerrar turno** (`%EndShift`, no lugar do texto do turno ao lado do relógio) fecha a noite: quem está na linha ou
  tocando termina com `End.SHIFT_OVER` (advertência média `shift_hung_up`; emergência sem despacho vira
  `emergency_dropped`; já resolvida, `closing`, não conta; o registro dela não conta como sem registro). No fim
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
