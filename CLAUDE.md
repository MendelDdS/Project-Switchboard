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
  `DarkPanel`, `PaperPanel`, `NotePanel`, `FormPanel`, `InkLabel`, `InkSoftLabel`, `DimLabel`, `AmberLabel`,
  `MonoLabel`, `InkMonoLabel`). Prefira variação de tema a override por nó.
- Nomes de pessoas e lugares na ordem natural, "Nome Sobrenome" (nunca "Sobrenome, Nome"); a lista telefônica
  ordena pelo nome como aparece (`PhoneBook._entries`).
- **Conteúdo em Resources** (`data/content.tres` + um `.tres` por roteiro em `data/calls/` + um por noite em
  `data/nights/`). Nada de falas no código, exceto as do operador.
- **Moldes** (`data/templates/`, listas `transfer_templates`/`emergency_templates` no content): `TransferCall`/
  `EmergencyCall` com lacunas **em inglês** (`{place}`, `{reason}`, `{street}`, `{house}`...), preenchidas por
  `GameData.template_transfer()`/`template_emergency()`. Motivos em `DirectoryEntry.reasons`. `TEMPLATE_CHANCE`
  (main.gd) mistura moldes e roteiros escritos (híbrido: tutorial, trotes e roteiro da noite sempre escritos).
- Todo o áudio é sintetizado no autoload `Sfx` (`scripts/sfx.gd`), inclusive as "vozes" por sílaba
  (`Sfx.speak_char`). Barramentos em `default_bus_layout.tres`: Ambience, Voices, Effects (e Rub, que envia para Effects).
  Ambience tem um compressor com sidechain em Voices (o ambiente baixa enquanto alguém fala); Effects, uma
  reverberação leve de sala. `Sfx.play_at(id, screen_x)` toca um som vindo de um lugar da tela (pool de
  `AudioStreamPlayer2D`, `PAN`); a mesa usa para os sons dela (`Switchboard._sfx`, `screen_x`). A campainha
  (`ring_start(bells)`: linha -> lugar da tomada) reveza entre as linhas chamando, cada uma no seu tom (`BELL_STEP`).
- Cursores próprios no autoload `Cursors` (`scripts/cursors.gd`): pixel art 16×16 em texto (×`SCALE`), uma por forma
  `Control.CURSOR_*` (seta, dedo, mão aberta = `MOVE`, mão fechada = `DRAG`, proibido, I-beam). Botões e sliders
  ganham o dedo sozinhos (`node_added`); quem quer outra forma define `mouse_default_cursor_shape` (a mesa troca a
  dela a cada quadro). Passe `Image`, não textura, ao `Input` (textura vaza ao fechar).
- Clima (`Main.weather`: "rain", "fog", "clear", sorteado; `-- --weather=X` força): `Sfx.start_ambience(w)`/
  `set_weather`/`hush_nature`/`stop_ambience`, `Background.weather` desenha a janela, `Main.smalltalk()` junta as
  falas gerais com as do clima.
- Pixel art desenhada em `_draw()`; cores e fontes em `pal.gd` (`Pal.*`). **Fontes de pixel**: importadas sem
  suavização nem sub-pixel e usadas só nos tamanhos em que ficam nítidas: `Pal.ui` (Pixelify Sans) 14, 16, 18, 22
  (piso de 14; 12 só onde não cabe: teclas dos botões, selo da aba, estado das linhas e numeração do mapa); `Pal.mono` (VT323, números) 20, 21, 25, 30, 35 (abaixo de 20 fica fina). Texto em desenho com escala (mapa)
  sai fora da escala (`CityMap._t`). O 2 e o 5 da Pixelify foram redesenhados (pareciam S e Z) e ela foi fixada no peso
  Regular (era variável); se trocar o arquivo da fonte, refaça isso.
- **Idiomas** pt_BR (padrão), en, es. Interface/código: **enum `T.Key`** (`scripts/t.gd`, GERADO) +
  `translations/ui.csv` (`chave,pt_BR,en,es`); use `T.text(T.Key.X)` (com valores: `T.text(T.Key.X) % n`), nunca
  `tr("texto")` com literal. Cenas: o `text` do Label/Button é a chave (auto-tradução do Godot). Falas dos roteiros
  (`data/`): português no Resource, `tr()` na hora de mostrar, traduções em `translations/content.{en,es}.po`
  (nomes próprios repetem o original). Depois de mexer em textos: `Godot --headless --path . -s
  tools/update_translations.gd` (gera o enum e mescla os .po; campos fora da extração em `SKIP`). `Settings.set_locale`
  troca o idioma (o jogador escolhe em Configurações; padrão pt_BR; `-- --lang=en` força). `GameData.tr_text()` traduz em funções estáticas.
  Lacunas dos moldes também se traduzem: `tr(spoken)`, `tr("d" + spoken)`, `tr("pr" + spoken)` têm entradas próprias
  no .po. Texto que já chega traduzido num Button/Label dinâmico: `auto_translate_mode = DISABLED`.
- Entrada: ação `cancel_plug` no Input Map (Esc e botão direito) devolve o plug que está na mão; ação `pause` (Esc, P)
  pausa o turno quando não há plug na mão (`Main._unhandled_input`). Atalhos do telefone: ações `answer_call`
  (Espaço), `transfer_call` (Tab), `hang_up` (X), tratadas em `PhonePanel._input` **antes da interface** (Espaço e
  Tab também apertam o botão em foco e passam o foco; por isso não dá para usar `Button.shortcut`). Só com o botão
  ativo; na pausa não valem; com um campo de texto em foco a tecla fica com ele. A tecla aparece no canto do botão
  (Label `Key`; "Espaço" traduzido, `KEY_SPACE`).
- **Pausa e configurações**: `PauseMenu` (`scenes/ui/pause_menu.tscn`, z 4, `process_mode` ALWAYS) usa
  `get_tree().paused`. **Todo `create_timer` do jogo leva `false` no 2º argumento** (senão continua contando na pausa);
  o `Sfx` roda sempre (ambiente segue, `Main.pause()` cala a campainha e `_update_bell` a devolve). Configurações no
  autoload `Settings` (`user://settings.cfg`): `locale`, `volumes` por barramento, `text_speed` (`char_delay()`
  multiplica o tempo por letra na conversa e no rádio); sinal `changed`. `set_*` vale na hora (prévia) mas só
  `save()` grava (botão Aplicar); Voltar/Esc faz `restore(snapshot)` do estado de quando a tela abriu. Testes (`-s`) não leem nem gravam o arquivo.
  Textos montados uma vez (botões do despacho, itens do caderno, telas desenhadas) se refazem em
  `NOTIFICATION_TRANSLATION_CHANGED`.
- Git: branch principal `development`; commits no padrão `tipo(#0000): descrição`. `.godot/` fica fora do git.
  Só faça commit quando o usuário pedir (na reestruturação ele autorizou um commit por etapa em `refactor/definitive`).
- Comentário `ponytail:` marca um atalho deliberado; mantenha o código enxuto e no estilo do arquivo.

## Rodar e testar
- Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (não está no PATH). Cena principal: `scenes/main.tscn`.
- Checar se tudo compila: `Godot --headless --path . --quit-after 60`.
- **Testes: `tests/run.sh`** (roda tudo em headless, com limite de tempo, e falha em `SCRIPT ERROR`; ~1 min no total).
  Roda com **`--fixed-fps 60`**: cada quadro avança 1/60 s de jogo e o motor não espera o relógio real (simulação
  determinística, turno do robô em ~6 s). Para rodar um teste à mão, use a mesma opção:
  `Godot --headless --fixed-fps 60 --path . -s tests/test_x.gd -- --seed=1`. Com `--fixed-fps`, tempo de teste se mede em
  quadros/delta, nunca em `Time.get_ticks_msec()` (o robô soma `get_process_delta_time()` em `sim`).
  `Engine.time_scale`: 8 nos cenários, 2 no robô (acima disso as falas, letra a letra, ficam presas ao quadro e
  alongam as conversas; a 48× as métricas mudavam muito).
  - `tests/test_base.gd`: base (`ok()` em vez de `assert`, que trava o headless; `wait_until`, `load_main`, `finish`).
  - `tests/test_flow.gd`: cenários dirigidos (transferência, espera, desistência, caderno, lugar fechado, ligar de volta ao desconhecido, cliques).
  - `tests/test_penalties.gd`: consequências (perdida e retorno, número errado, registro, despacho errado,
    emergência sem despacho, espera longa, informação errada) e o relatório. Relógio parado; retornos tocados à mão.
  - `run.sh` começa com `--import`: **`class_name` novo só existe depois de reimportar** (sem isso, parse error).
  - `tests/test_shift.gd`: robô que joga o turno inteiro e imprime métricas (máx. simultâneas, % com 2+/3+,
    % sem cabo livre, perdidas, maior silêncio); `run.sh` roda com `--seed=1..3`, um turno `--clumsy` (deixa de atender 1 em 3),
    a noite 2 (`--night=2`) e um turno `--human` (5 s de jogo por ação, como uma pessoa: **é este que mede se o ritmo
    cabe**; o robô normal é rápido demais).
  - Nos testes, `Main`/`Switchboard` ficam **sem tipo** (dependem do autoload `Sfx`, que não existe na hora em que
    o Godot compila um script `-s`). `PhoneCall`, `Exchange` e os Resources podem ser tipados.
  - Rode depois de qualquer mudança em agenda, fim de ligação, mesa ou cabos. `run.sh` também joga um turno em
    `--lang=en` e outro em `--lang=es`; o teste de fluxo confere chaves, lacunas e cenas (`_check_translations`).
- Semente fixa: `Godot --path . -- --seed=123` repete a agenda do turno (sem `--seed`, é aleatória).
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
- `scenes/main.tscn` + `scripts/main.gd` (`Main`) — orquestra o turno: relógio, agenda, o que cada plug significa
  para as ligações, fim de ligação, ligação desconhecida e final. Constantes de ritmo no topo.
- `scripts/conversation.gd` (`Conversation`, nó filho de Main) — como cada tipo de ligação se desenrola:
  `say`/`op`/`choose`/`wait` e os roteiros de transferência, informação, emergência, trote e ligação desconhecida.
- `scripts/model/phone_call.gd` (`PhoneCall`) — uma ligação: roteiro (`data`) + estado; emite sinais que o telefone
  escuta. `scripts/model/exchange.gd` (`Exchange`) — **dono único** do estado das linhas e destinos (enums `Line`, `Dest`).
- `scripts/data/*.gd` — classes de Resource do conteúdo; `scripts/game_data.gd` (`GameData`) — acesso ao
  `content.tres` (`CONTENT`, `entry()`, `street()`, `transfers()`, `pick()`...).
- `scenes/ui/*.tscn` + `scripts/ui/*.gd` — telefone (`PhonePanel`, `FoneSocket`), rádio, abas (`Tools`) com lista
  (`PhoneBook`), mapa (`MapView` + `CityMap`), despacho (`Dispatch`, dono das unidades e da ocorrência) e caderno
  (`Notebook`, fila de ocorrências); `Intro`, `Ending`; widgets desenhados (`Switchboard`,
  `Background`, `Bevel`, scanlines).

## Modelo da mesa (scripts/ui/switchboard.gd)
- Tomadas por id inteiro: **1–10 entradas**, **11–20 saídas** (linha + 10), **destinos = o próprio número** (101–399,
  exceto 190/192/193, que vão pelo despacho).
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
- Plug (`_draw_plug`): corpo na cor do cabo, anel de latão e ponta de metal; encaixado (`PLUG_SEAT`), a ponta some
  dentro da tomada e o anel assenta no buraco. `_plug_rect(seated)` é o contorno (clique, destaque e sombra).
  Sombras (`SHADOW`): fios deslocados `ROPE_SHADOW`; plug mais longe quanto mais sai do painel (solto, na mão).

## Modelo das ligações
- `live`: ligações tocando ou em andamento (várias ao mesmo tempo). O painel mostra `phone.shown()`.
- **Foco** = a ligação da entrada onde está o FONE (`Main._focus()`); Main mantém `c.on_line`. Quem não está em
  foco fica "em espera" e **não fala**: `say()`/`op()` aguardam `_until_on_line(c)`. Exceção: ligação já resolvida
  (`c.closing`: informação respondida, emergência despachada) não entra em espera; a pessoa termina de falar sozinha
  e desliga, sem som e sem texto na transcrição (só o que for dito com o FONE na linha aparece).
- Transferência: FONE na entrada → Atender → pedido → cabo de conexão saída→destino → **Transferir** (`transfer()`)
  → `_ring_dest` → destino atende → tirar o FONE → `_try_complete` → linha e destino CONN por `TALK_LEN`
  → DONE (vermelho) até o jogador tirar as pontas. `_dgen` invalida toques de destino quando o cabo sai.
- Fim de ligação: `end_call(c, PhoneCall.End.*)` gera `c.record` e manda para `Notebook.add()` (fila; não trava o turno).
  O caderno registra com **um clique no tipo** (`register(T.Key.TYPE_*)`: Comum, Emergência, Trote; o resto da linha
  vem do `record`), mostra a pendente numa ficha só de leitura e desenha o livro como página pautada (`_draw_page`,
  carimbo colorido por tipo, `STAMPS`). A aba mostra quantas faltam (`pending_changed(count)` → `Tools.set_count`,
  selo `BadgeLabel`); o jogo não troca de aba sozinho.
- Despacho: `Dispatch.set_incident()` quando a emergência toca; `Dispatch.sent` → `Main._on_dispatched` →
  `Conversation.emergency_dispatched`. O tipo de ocorrência é obrigatório para enviar. Na chegada,
  `Dispatch.arrived(e, result, occurrence, extra)` ("ok", "missing", "wrong_place", "idle"; tipo marcado; unidades
  que não eram necessárias) → `Main._on_arrived`.

## Consequências (relatório do supervisor)
- `ShiftReport` (`scripts/model/shift_report.gd`): `FAULTS` (id → gravidade, descrição), `add()`, desfecho das
  emergências (`trouble`/`resolved`/`failed` → OK, LATE, BAD) e `verdict()`. Entre noites só as graves somam
  (`severe_before`, salvas no `Progress`; `SEVERE_LIMIT` = demissão).
- Main registra com `_fault()` onde a falha acontece; `_consequences()` (chamado em `end_call`) decide advertência e
  retorno; `_call_again()` agenda a mesma pessoa de novo (`PhoneCall.retry`; uma vez por motivo, `retried`;
  também no tutorial; nunca depois do fim do turno; `too_late` sorteado com
  `REDISPATCH_CHANCE`). `_check_hold()` encerra quem passou de `HOLD_GIVE_UP` em espera (`End.GAVE_UP`).
- Tutorial (`tut`), trotes e ligação desconhecida não geram advertência. Falas de retorno, manchetes e pareceres
  ficam no content (grupo "Supervisor e consequências").
- À meia-noite, `_start_ending` soma o que ficou sem registro e passa o relatório para `Ending.play(report)`, que mostra
  `ReportView` antes do título final.

## Noites (roteiro fixo)
- `GameContent.nights` (ordem) → `Night` (`scripts/data/night.gd`, `data/nights/night_NN.tres`): dia da semana, bilhete
  da intro, clima fixo (vazio = sorteado), `tutorial` (só a 1ª), ritmo das sorteadas (`call_gap`, `emergencies`,
  `pranks`), `story` (`StoryCall`: roteiro escrito + horário fixo) e `mystery` (passos `PrankStep`; vazio = sem
  ligação desconhecida naquela noite). **Só `story` e `mystery` são fixos; não existem ligações "principais".**
- `PrankStep` é o roteiro falado de trotes e da ligação desconhecida (`Conversation.play_steps`); `EFFECT` =
  "static", "static_loud", "flick". `PhoneCall.from_script()` aceita Transfer/Emergency/PrankCall.
- **Marcadores** (`StoryFlags`, `scripts/model/story_flags.gd`; `Main.flags`): nomes ligados por escolhas ou pelo jogo,
  salvos entre noites (`Progress.flags`). Genérico: qualquer sistema consulta `flags.allows(requires)` e altera
  `flags.apply("nome" | "!nome")`; sinal `changed`. Condição `requires: PackedStringArray` (todos ligados; "!" =
  desligado) em `StoryCall` (conferida **na hora de tocar**, via `PhoneCall.requires`) e `PrankStep` (passo pulado);
  `PrankStep.sets` = efeito de cada opção do OPERATOR. Automáticos: `ligou_de_volta_N`, `desligou_desconhecida_N`.
  Para um recurso novo usar marcadores: exporte `requires`/`sets` e chame `allows`/`apply`. Testar um ramo:
  `-- --night=2 --flags=a,b`.
- `Progress` (`scripts/model/progress.gd`, `user://progress.cfg`): próxima noite e graves acumuladas
  (`ShiftReport.severe_before`/`severe_total()`/`fired()`) e marcadores. Main salva em `_start_ending` (última
  noite ou demissão limpa o save). `-- --night=N` força uma noite **sem ler nem gravar** o save; `test_base.load_main` força a noite 1.

## Agenda e ritmo (constantes no topo de main.gd; por noite em `Night`)
- Ligação desconhecida (`MYSTERY`, entrada livre sorteada, guardada em `myst_line`) entre `Night.mystery_from` e `mystery_to` (22:00–23:30), só
  toca com a mesa em silêncio, por no máximo 30 min de jogo (`latest`).
- Sorteadas: `_random_calls` — intervalo `Night.call_gap` (28–42 min ≈ 37–56 s reais; medido com `--human`) entre uma e a próxima, `PEAK_CHANCE` de vir
  logo em seguida, a `STORY_GAP` das fixas. Tipos: `Night.emergencies` (a `EMERGENCY_GAP` uma da outra; no laço, a
  emergência espera a anterior acabar e `Dispatch.en_route()`), `Night.pranks`, resto transferência/informação.
  Um destino (e `alt_target`) por noite: dois pedidos do mesmo número travavam um ao outro.
- `GIVE_UP_SEC` 60 s (`story` 1,5x, retornos 0,75x); tutorial (`tut`) e desconhecida nunca desistem.
- Espera na linha (`Main._nag`, silêncio medido em `talk_clock`, que para na pausa): transferência pedida e o
  operador parado → depois de `SMALLTALK_AFTER` (10 s), com `SMALLTALK_CHANCE` (60%, uma vez por ligação), conversa
  fiada do cotidiano (`smalltalk` + a do clima); com `NAG_AFTER` (22 s) sem falar, reclama (`waiting`). Emergência:
  `EMERGENCY_NAG_AFTER`. A conversa fiada não vem mais logo depois do pedido. Conversa fiada só do cotidiano (nada
  que lembre o mistério: luzes piscando, carros parados, chiado na linha).
- Conversas transferidas duram `TALK_LEN` (34–68 min de jogo ≈ 45–90 s reais).
- Turno das 18:00 (`SHIFT_START_HOUR`) às 00:00 (`SHIFT_END` = 360 min); fim **depois** da ligação desconhecida ter caído (`_start_ending`).
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
12. Sons: campainha antiga (martelinho + ressonadores de metal) e "tuuuu" (o filtro de caixa oca foi testado e removido a pedido do usuário), chuva e grilos (chirps + trilos) refeitos. Clima sorteado por
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

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
