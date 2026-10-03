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
  `RedButton`, `InkButton`, `DarkButton`, `ChoiceButton`, `TabButton`, `PaperToggle`, `PaperInk`, `LetterButton`,
  `DarkPanel`, `PaperPanel`, `NotePanel`, `FormPanel`, `SlipPanel`, `InkLabel`, `InkSoftLabel`, `DimLabel`, `AmberLabel`,
  `MonoLabel`, `InkMonoLabel`). Prefira variação de tema a override por nó.
- Nomes de pessoas e lugares na ordem natural, "Nome Sobrenome" (nunca "Sobrenome, Nome"); a lista telefônica
  ordena pelo nome como aparece, sem acento (`PhoneBook._entries`, `_plain`). **Uma letra por página dupla**: a aba de
  índice na borda direita (`_index`, `_tab_rect`; a da letra aberta fica destacada) abre só os contatos daquela letra
  (`pages()`: começam na esquerda e seguem na direita); Voltar e Virar passam de letra em letra e, depois da última,
  vem a página de anotações. Contato: nome, pontilhado até o número e, embaixo, observação · endereço · bairro
  (`_addr`, espaços que não quebram no bairro e em "rua, número"). A observação (`DirectoryEntry.note`) só diz **quem
  atende quando o nome não diz** ("Pe. Anselmo", "recepção", "secretaria", "use o despacho"); nada de horário ou
  "residência". Todo número da lista serve para alguma coisa: não existe lugar sempre fechado.
- **Conteúdo em Resources** (`data/content.tres` + um `.tres` por roteiro em `data/calls/` + um por noite em
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
- Todo o áudio é sintetizado ao iniciar por `SfxSynth.build()` (`scripts/sfx_synth.gd`: as receitas, ~0,6 s num Mac
  recente, 125 sons, 2,4 MB; sem cache) e tocado pelo autoload `Sfx` (`scripts/sfx.gd`: tocar, mixar, ambiente), inclusive as "vozes" por sílaba
  (`Sfx.speak_char`). Barramentos em `default_bus_layout.tres`: Ambience, Voices, Effects (e Rub, que envia para Effects).
  Ambience tem um compressor com sidechain em Voices (o ambiente baixa enquanto alguém fala); Effects, uma
  reverberação leve de sala. `Sfx.play_at(id, screen_x)` toca um som vindo de um lugar da tela (pool de
  `AudioStreamPlayer2D`, `PAN`); a mesa usa para os sons dela (`Switchboard._sfx`, `screen_x`) e o rádio para a voz,
  o chiado e os bipes (`Radio.screen_x()`; `speak_char`, `syllable` e `static_burst` aceitam `at`). O toque da mesa
  (bipes suaves, `BEEP`; `ring_start(bells)`: linha -> lugar da tomada) reveza entre as linhas chamando, cada uma no seu tom (`BELL_STEP`).
- Cursores próprios no autoload `Cursors` (`scripts/cursors.gd`): pixel art 16×16 em texto (×`SCALE`), uma por forma
  `Control.CURSOR_*` (seta, dedo, mão aberta = `MOVE`, mão fechada = `DRAG`, proibido, I-beam). Botões e sliders
  ganham o dedo sozinhos (`node_added`, troca adiada em `_point` para não esbarrar em nó fora da árvore); quem quer outra forma define `mouse_default_cursor_shape` (a mesa troca a
  dela a cada quadro). Passe `Image`, não textura, ao `Input` (textura vaza ao fechar).
- Clima (`Main.weather`: "rain", "fog", "clear", sorteado; `-- --weather=X` força): `Sfx.start_ambience(w)`/
  `set_weather`/`hush_nature`/`stop_ambience`, `Background.weather` desenha a janela, `Conversation.topics()` junta os
  assuntos gerais com os do clima (`ChatTopic.weather`).
- **Resolução**: a base é 1280×720 (`canvas_items`, `aspect="expand"`); o Godot amplia para a tela, e a proporção
  diferente de 16:9 vira espaço a mais, não tarja. Não troque a base para 1920×1080 (tudo fica 2/3 do tamanho).
  O layout absorve o espaço a mais: a coluna da esquerda (mesa e telefone) tem largura fixa e a da direita cresce;
  o telefone ocupa o resto da altura até `Main.PHONE_MAX_H` (medido pela altura do Main, não da coluna: medido pela coluna,
  um aviso que quebrava linha a fazia transbordar e o telefone ficava esticado, empurrando a tela para fora); o brilho da luminária (`%Glow`) tem 1280×720, preso à direita;
  as abas crescem na altura; a lista telefônica, o mapa e o caderno acompanham o tamanho da aba (`PhoneBook.book`,
  `NOTIFICATION_RESIZED`); o `Background` estica parede e mesa até a borda (luminária presa à direita).
- **Bloom das luzes** (`Bloom`, `scripts/ui/bloom.gd`, nó `Bloom` do Main, z 2: acima da mesa e dos painéis, abaixo dos
  menus), no estilo do glow de cinema e em pixel art: halo somado à tela (blend ADD) em duas camadas (curta e forte,
  longa e fraca), desenhado em blocos de `BLOCK` px com poucos degraus e pontilhado ordenado (`_halo_for`, guardado por
  tamanho); por cima, a própria luz nítida com o centro indo, em degraus, para um branco tingido pela cor dela (`HOT`,
  `HOT_TINT`; sem isso o halo parecia uma fumaça). Só brilha o que se declara luz, porque pela cor não dá (o plug
  vermelho tem o tom da lâmpada vermelha; um bloom de tela por cor foi testado e descartado): quem desenha luzes chama
  `Bloom.clear(self)` no começo do `_draw` e `Bloom.light(self, rect, cor, halo, core, round)` por luz acesa (lâmpadas
  redondas da mesa, `Switchboard._draw_lamp`, com aro niquelado, `BEZEL`; aro da tomada de destino, sem miolo;
  luzes das máquinas do cartão; barra de agravamento; janelas acesas do `Background`, que desenha em 2×). ColorRect e
  Label no grupo "bloom" brilham na cor deles (luzes do rádio; o relógio, só halo, atenuado pela meta "bloom"). Luz
  sem miolo tem o halo fraco por dentro (`HOLLOW`); luz de quem recorta o conteúdo (`clip_contents`) é recortada também.
- Pixel art desenhada em `_draw()`; cores e fontes em `pal.gd` (`Pal.*`). **Uma fonte só, de pixel: Departure Mono**
  (`Pal.ui` e `Pal.mono` são a mesma; continuam separadas pelo papel), **só em múltiplos de 11** (exceção: o estado de cada linha na mesa, `Switchboard.STATE_FONT` = 8, porque "conectada" em 11
  não cabe na coluna; a letra fica um pouco irregular): 11 (texto, números da lista), 22
  (títulos, visor, bilhete), 33 (títulos de tela), 44 (relógio). Importada com suavização (a janela
  menor que 1280×720 não apaga os traços, mas o texto de 11 fica borrado), sem hinting e sem sub-pixel. Texto em
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
  ativo; na pausa não valem; com um campo de texto em foco a tecla fica com ele. A tecla aparece no canto do botão
  (Label `Key`; "Espaço" traduzido, `KEY_SPACE`). Abas: ações `tab_directory`/`tab_dispatch`/`tab_logbook` (1, 2, 3),
  tratadas em `Main._unhandled_input` só durante o turno (`Main.TAB_KEYS`); o número fica no canto da aba.
- **Pausa e configurações**: `PauseMenu` (`scenes/ui/pause_menu.tscn`, z 4, `process_mode` ALWAYS) usa
  `get_tree().paused`. **Todo `create_timer` do jogo leva `false` no 2º argumento** (senão continua contando na pausa);
  o `Sfx` roda sempre (ambiente segue, `Main.pause()` cala a campainha e `_update_bell` a devolve). Configurações no
  autoload `Settings` (`user://settings.cfg`): `locale`, `volumes` por barramento, `text_speed` (`char_delay()`
  multiplica o tempo por letra na conversa e no rádio); sinal `changed`. `set_*` vale na hora (prévia) mas só
  `save()` grava (botão Aplicar); Voltar/Esc faz `restore(snapshot)` do estado de quando a tela abriu. Testes (`-- --test=x` ou `-s`) não leem nem gravam o arquivo.
  Textos montados uma vez (botões do despacho, itens do caderno, telas desenhadas) se refazem em
  `NOTIFICATION_TRANSLATION_CHANGED`.
- Git: branch principal `development`; commits no padrão `tipo(#0000): descrição`. `.godot/` fica fora do git.
  Só faça commit quando o usuário pedir (na reestruturação ele autorizou um commit por etapa em `refactor/definitive`).
- Comentário `ponytail:` marca um atalho deliberado; mantenha o código enxuto e no estilo do arquivo.

## Rodar e testar
- Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (não está no PATH). Cena principal: `scenes/main.tscn`.
- Checar se tudo compila: `Godot --headless --path . --quit-after 60`.
- **Testes: `tests/run.sh`** (roda tudo em headless; ~1 min no total; `tests/run.sh flow penalties` roda só esses). Um
  `SCRIPT ERROR` não encerra o Godot: o `run.sh` lê o log enquanto o teste roda e o encerra no primeiro erro (sem isso,
  cada teste quebrado ficava parado até o `LIMIT` de 120 s e a bateria passava de 10 min).
  Roda com **`--fixed-fps 60`**: cada quadro avança 1/60 s de jogo e o motor não espera o relógio real (simulação
  determinística, turno do robô em ~6 s). Para rodar um teste à mão, use a mesma opção:
  `Godot --headless --fixed-fps 60 --path . tests/runner.tscn -- --test=x --seed=1`. **Os testes rodam como cena**
  (`tests/runner.tscn`/`runner.gd` carrega `tests/test_<x>.gd`, que estende `test_base.gd`, um `Node`, e começa em
  `_initialize`): os autoloads já existem, então `Main`, `Switchboard`, `CardMachines` têm tipo nos testes; o `SceneTree`
  é `get_tree()`. Com `--fixed-fps`, tempo de teste se mede em
  quadros/delta, nunca em `Time.get_ticks_msec()` (o robô soma `get_process_delta_time()` em `sim`).
  `Engine.time_scale`: 8 nos cenários, 2 no robô (acima disso as falas, letra a letra, ficam presas ao quadro e
  alongam as conversas; a 48× as métricas mudavam muito).
  - `tests/test_base.gd`: base (`ok()` em vez de `assert`, que trava o headless; `wait_until`, `load_main`, `finish`).
  - `tests/test_flow.gd`: cenários dirigidos (transferência, espera, desistência, caderno, destino que não atende, ligar de volta ao desconhecido, cliques).
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
  exige (contado e real), velocidade 1–8×, pula o relógio, encerra o turno, troca de noite (`_go_night`: recarrega a cena na noite anterior/seguinte, sem ler nem
  gravar o progresso, para testar a entrega dos setores), libera viaturas (`Dispatch.reset`; `_gen` cancela
  as viagens em andamento), registra pendências, limpa advertências e apaga o progresso. Mesa de som: toca cada som de `Sfx.VOL` com
  um controle de volume que vale na hora (`Sfx.vol`, a cópia em uso) e "Copiar VOL" põe a constante ajustada na área de
  transferência, para colar em `sfx.gd`. Cada seção tem "Limpar" e o
  topo tem "Restaurar tudo" (`Main.drop` tira uma ligação sem caderno, advertência nem retorno; a mesa é zerada antes de
  tirar os cabos para nada contar como conversa cortada; `Notebook.reset`). Textos fixos em português (ferramenta, não interface). Ele só usa funções públicas do Main (`free_line`,
  `start_ending`, `cancel_dest_ring`, `drop`) e do relatório (`ShiftReport.forget`), para não quebrar quando o Main mudar.
- Captura de tela: rodar SEM `--headless` e salvar `root.get_texture().get_image()`.

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
- `scenes/ui/*.tscn` + `scripts/ui/*.gd` — telefone (`PhonePanel`, `FoneSocket`), rádio, abas (`Tools`) com lista
  (`PhoneBook`), mapa e despacho (`Dispatch` + `CityMap`, dono das unidades e da ocorrência) e caderno
  (`Notebook`, fila de ocorrências); `Intro`, `Ending`; widgets desenhados (`Switchboard`,
  `Background`, `Bevel`, scanlines).

## Modelo da mesa (scripts/ui/switchboard.gd)
- Tomadas por id inteiro: **1–10 entradas**, **11–20 saídas** (linha + 10), **destinos = o próprio número** (101–399,
  exceto 190/192/193, que vão pelo despacho). Destinos em três bancos de fábrica, A | B | C, rotulados pela faixa de
  numeração (100–199 | 200–299 | 300–399, `SECTOR_ORDER`, duas fileiras cada, `_layout_dests`/`_slots`; a mesa não
  fala em setor). O banco de um setor que ainda não é do operador fica sob uma chapa com a letra dele (`_draw_plate`:
  A e B; o C, do setor 3, nunca é tampado) e as tomadas dele não existem para o clique.
- `ends[]`: tomada de cada ponta (-1 = na base). **Ponta 0 = FONE** (cabo verde, encaixe `FoneSocket` no painel
  do telefone, só entra em entradas). **Pontas 1..2*PATCHES = cabos de conexão** (vermelho, azul, amarelo em `CORD_COLORS`; independentes; `mate(e)`
  dá a outra ponta; uma ponta na saída, a outra no destino). `PATCHES = 3`.
- `setup(exchange, socket)` liga a mesa ao estado e ao encaixe. `dest_of_output(n)` segue o cabo da saída n.
- `refuse(e, j)` decide compatibilidade (e o destaque amarelo/vermelho). `_has_point` estende o clique ao encaixe
  do FONE; por isso o telefone e seus containers acima do encaixe têm `mouse_filter = IGNORE`, e a mesa tem
  `z_index = 1` (desenha plug e fio por cima do telefone). Overlays têm z 2, intro/final z 3.
- Clique num plug encaixado → solta o plug (`go_home`, `_loose`): ele vira a última conta da corda e cai (`FALL_SEC`)
  e o fio encolhe (`PULL_SPEED`); solto acima do buraco, a qualquer altura (`NEAR_HOLE` na horizontal), não cai: vem reto, fio esticado e sem gravidade até `SEAT_LEN` e o plug assenta no lugar (`SEAT_SEC`); solto, ele gira com o fio
  (`_plug_angle`), sai com o embalo da mão (`_mouse_vel`, `MAX_FLING`) e dá para pegá-lo no ar (`_plug_hit`). Sons:
  `drop` (bate na mesa, `DROP_SPEED`), `thump` (assentou) e o atrito contínuo do fio no buraco: a mesa soma
  quanto fio entrou ou saiu (`_rubbed`, variação do comprimento) e passa a velocidade a `Sfx.cord_rub` a cada quadro
  (volume e tom entre `RUB_MIN` e `RUB_FULL`; sem chamada, cala). Dois loops com o mesmo ganho: `rub` (o fio:
  agarra e solta + corpo) e `rub_hi` (o agudo: fibras + rangido), mudo devagar (`RUB_HI_FROM`), normal no médio
  (`RUB_HI_NORMAL`) e `RUB_HI_BOOST` dB a mais rápido. Os dois passam
  pelo barramento `Rub` (envia para Effects; passa-baixa que abre de `RUB_LP.x` a `RUB_LP.y` com a velocidade, e
  panorama). A mesa também informa onde fica o buraco na tela (o som vem daquele lado, `RUB_PAN`), quanto do fio está
  saindo ou entrando (`_count_rub`; entrando é mais liso, `RUB_IN`) e quanto é o do FONE (mais macio, `RUB_FONE`; a diferença some
  quase toda puxando rápido, `fast`);
  `cord_stop` ("tec") quando o fio termina de entrar; `cord_tap` quando o fio bate na mesa (`TAP_SPEED`,
  no máximo um a cada `TAP_GAP` por fio). Sons mecânicos repetidos (`Sfx.VARIED`) saem com tom e volume levemente
  sorteados. Plug só se move arrastando
  (clicar e segurar); clique sem arrastar só serve para desplugar.
- Fios são cordas de Verlet (`_step_rope`), **uma por ponta**, presas no buraco (`hole(e)`: o do FONE no alto do
  encaixe, dois por cabo de conexão na base) e na traseira do plug (`_plug_base`); só existem com o fio para fora.
  Folga: `SLACK` (FONE), `CORD_SLACK` (conexão). Fio parado por `SLEEP_STEPS` passos "dorme" (`ropes[e]["sleep"]` =
  área onde o mouse o acorda) e deixa de ser simulado até a ponta, o buraco ou o mouse mexerem nele.
- Sob o mouse: `_plug_under` (plug que dá para pegar → `_hover`, desenhado com contorno claro) e `_cursor_shape`
  (mão aberta, mão fechada segurando, proibido sobre tomada que recusa, dedo em tomada/plaqueta que informa).
  Desenho na ordem `_order`: a ponta pega ou encaixada por último (`_raise`) fica por cima (e é a primeira no clique);
  cada ponta desenha fio e plug juntos, para o fio mais recente passar por cima dos plugs das outras.
- Layout da mesa (`SIZE` 588×334, também em `main.tscn`): coluna de cada linha em `ROW_Y` (plaquinha de metal com o número
  gravado, `_draw_number_plate`; estado; lâmpada; entrada; saída), todos os encaixes com `JACK` px, bancos de destino em
  `DEST_TOP`/`DEST_ROW`, cabos e legenda embaixo. Mexendo na altura, confira com uma ligação atendida e duas fileiras de
  opções que a coluna da esquerda ainda cabe em 720.
- Chapas de metal niquelado (`_draw_metal`: chanfro e rebites) nas plaquinhas dos números e na base dos cabos, cujos
  furos são buchas redondas (`_draw_jack` pequeno); o encaixe do FONE (`FoneSocket`) é uma chapa com berço de latão.
- Encaixes redondos como os originais (`_draw_jack`: bucha de metal com aba chanfrada, parede de dentro rebaixada e o
  furo); lâmpadas redondas com aro niquelado (`_draw_lamp`, `BEZEL`) que acendem rápido e apagam devagar, como
  filamento (`_lamp`/`_dest_lamp` dizem cor e nível desejado, `_fade` chega lá em `LAMP_ON_SEC`/`LAMP_OFF_SEC`, estado em
  `_lit`; a linha tocando pulsa). A luz acesa tinge o aro dela e a aba do encaixe logo abaixo (`_reflect`).
- Plug (`_draw_plug`): de pé (solto, na mão, na base; `_draw_plug_body`) é cabo de baquelite na cor do cabo
  (sombreado de cilindro, sulcos de pegada, ponteira de onde sai o fio), colar niquelado (`BEZEL`) e a ponta de três
  partes dos plugues de mesa (bico e anel niquelados, luva de latão, isolantes pretos); gira com o fio em passos de
  `ROT_STEP` (15°: pixel art girado torto serrilha). Encaixado, é visto de frente como nas mesas de verdade
  (`_draw_plug_face`: aro niquelado e o tampo do cabo, `PLUG_FACE_R`), com o fio saindo do meio do encaixe, por cima
  (`_plug_base` = centro do encaixe; o plug encaixado é desenhado antes do fio, que passa por cima do tampo e chega à
  ponteira no centro, `_draw_plug_cap`, desenhada depois). O aro pega a luz da lâmpada (`_plug_reflect`: na entrada, a
  da linha, no alto do aro; no destino, a do aro aceso, em volta). Ao encaixar, o corpo em pé entra no encaixe enquanto a
  vista de frente cresce, e ao sair a vista de frente some no encaixe (`MORPH_SEC`, `_pulled`, `_unseat`); ao encaixar, o tampo encolhe `PUSH_PX`
  e volta em `PUSH_SEC` (`_pushed`, `_push`). Destaque e sombra seguem a silhueta (`_plug_outline`: as partes unidas
  num polígono, guardado; o destaque é ele alargado); `_plug_rect(seated)` é o retângulo do clique.
  Sombras (`SHADOW`): fios deslocados `ROPE_SHADOW`; plug mais longe quanto mais sai do painel (solto, na mão).

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
  pontilhadas, pauta como a do caderno, fibras no papel e sombra na mesa (maior na mão, como o plug). O jogador perfura
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
  desenrolando (`unroll`). **Cidade em folhas** (`CityMap.SHEETS`, 600×440 cada: Vila Serena (setor 3) | Centro (1)
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
  `PhoneCall.urgent()`, desenho em `UrgencyBar` dentro da caixa do chat, só com o operador na linha; fora dela, o rádio
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
  da intro, clima fixo (vazio = sorteado), `tutorial` (só a 1ª), `story` (`StoryCall`: roteiro escrito + horário fixo) e `mystery` (passos `PrankStep`; vazio = sem
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

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
