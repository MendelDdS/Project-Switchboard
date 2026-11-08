# Project Switchboard — memória do projeto

Jogo em Godot 4.6 (GDScript, renderer GL Compatibility), a caminho da versão definitiva. O jogador é o operador
noturno da central telefônica de São Sotero (18:00–00:00; a última noite vai até as 6h): atende e transfere ligações
numa mesa comutadora com cabos físicos; a história é o roteiro de Maria (`PLANO_ROTEIRO.md`).

Este arquivo é o **mapa e as regras**. O resto:
- `README.md`: o jogo para quem joga ou edita conteúdo (regras, tabelas de advertências, conceito do turno).
- `scripts/ui/CLAUDE.md`: o cenário (`Background`) e a mesa comutadora (`Switchboard`), lido ao mexer em `scripts/ui/`.
- `LESSONS.md`: lições aprendidas; leia antes de mudanças grandes.
- `HISTORICO.md`: cada pedido do usuário e o porquê (muita coisa foi testada e **saiu a pedido**). Não leia inteiro:
  `awk -v t='camera|janela|saiu' '/^[0-9]+\. /{p = $0 ~ "#(" t ")( |$)"} p' HISTORICO.md` (as chaves ficam no alto).
  Consulte antes de refazer ou desfazer algo visual ou de mecânica e acrescente ali cada pedido novo.
- `docs/mapa-detalhado.md` e `docs/mapa-ui-detalhado.md`: as versões longas destes mapas (até 20/10/2026), com o
  detalhe e o histórico de cada sistema. **Não leia inteiras**: `grep -n "<nome>" docs/mapa-*.md`.

**Economia de contexto**: este arquivo vai em toda mensagem. Mantenha-o curto: regra e nome do código aqui, o
detalhe no comentário do código, o porquê no `HISTORICO.md`. Atualize os `CLAUDE.md` no fim da tarefa, de uma vez
(editá-los no meio da sessão faz o arquivo inteiro ser reenviado). Não anexe arquivos grandes com `@`.

## Convenções
- Tudo em português: interface, falas, comentários (`##` para doc de função) e mensagens ao usuário.
- Comentário `ponytail:` marca um atalho deliberado; código enxuto e no estilo do arquivo.
- **Antes de criar arquivo, função, cena ou recurso: procure o que já existe** (`graphify query "<componente>"`, o
  grafo em `graphify-out/`; confira com `grep`, o grafo envelhece; atualize com `python -m graphify update <projeto>`,
  conferindo que as ligações dos documentos não sumiram). Reaproveitar > criar.
- Git: branch principal `develop`; commits `tipo(#0000): descrição`. `.godot/` fora do git. Só faça commit quando
  o usuário pedir, e **antes rode a skill `revisar-mudancas`** (só então). Convenção nova que der para conferir por
  padrão no texto entra no `check.sh` dela.
- **Interface em cenas** (`scenes/`), com Containers; scripts de interface em `scripts/ui/`, lógica em `scripts/`.
  Estilo no tema global `themes/main_theme.tres` por variações de tipo (`GreenButton`, `InkButton`, `HudPanel`,
  `PaperPanel`, `MemoPanel`, `TapedNote`, `InkLabel`, `InkBoldLabel`, `InkText`, `TypedText`/`HandText`...): prefira variação de
  tema a override por nó. Papéis escritos: efeito de RichTextLabel (`scripts/ui/paper_ink.gd`, `[typed]` e `[hand]`).
- Tela inicial (`scenes/title_screen.tscn`, posta pelo `GameView` antes do jogo, `GameView.playing`; a pausa volta a
  ela, `%ToMenu`): a mesa de perto (`title_board.gd`, linha chamando, `ringing`) e o menu (`TitleButton`, setas e Enter). Telas fora do turno são papéis: o bilhete do supervisor na abertura (`Intro` com o `SupervisorNote`, o papel timbrado do memorando, na metade direita; embaixo, o relógio de ponto, `time_clock.gd`, que o botão Começar turno, o Enter ou o clique batem, e o papel do que a noite traz de novo, `Main._tonight`; a interface do turno aparece com o ponto batido e o bilhete vai para o quadro de avisos, onde é relido no turno, `Intro.reread`), pausa e configurações num papel com
  fita, o relatório num memorando (`ReportView`: timbre, serviços prestados, advertências com o carimbo da gravidade,
  parecer à mão, rubrica e o carimbo redondo do conceito, `_grade_stamp`, girado pixel a pixel e em lugar sorteado).
- Botão de resposta (`ChoiceButton`): fala curta do operador (`CHOICE_*`; a frase inteira, `OP_*`, vai para a
  conversa); ação do jogador entre colchetes ("[Oferecer outro lugar]").
- A telefonista é Maria: quem fala com ela usa o feminino ("a senhora", "moça", "minha filha"), também no en e no es.
- Nomes de pessoas e lugares na ordem natural ("Nome Sobrenome"). Quem liga tem nome e sobrenome sem apelido nem
  tratamento (`TransferCall.caller_name`; nos moldes, `GameContent.caller_names`; o `test_content` cobra). Lista telefônica: uma letra por página dupla, aba
  de índice; a observação (`DirectoryEntry.note`) só diz quem atende quando o nome não diz. Todo número serve para
  alguma coisa.
- **Conteúdo em Resources** (`data/content.tres`; `data/directory/` um por contato, com os motivos e as conversas;
  `data/calls/` um por roteiro; `data/room/`; `data/nights/`; `data/templates/`). Nada de falas no código, exceto as do
  operador. Moldes (`TransferCall`/`EmergencyCall`) com lacunas em inglês (`{place}`, `{street}`...), preenchidas por
  `GameData.template_transfer()`/`template_emergency()`; `TEMPLATE_CHANCE` mistura moldes e roteiros escritos.
  Endereço por lugar do mapa: `GameData.LANDMARK_CHANCE`, `MapGrid.landmark_spots` (lugar novo precisa de `MAP_X` e
  `MAP_X_OF` e de um quarteirão que bata com o endereço da lista).
- **Idiomas** pt_BR (padrão), en, es. Interface: enum `T.Key` (`scripts/t.gd`, GERADO) + `translations/ui.csv`; use
  `T.text(T.Key.X)`, nunca `tr("literal")`. Cenas: o `text` é a chave. Falas de `data/`: português no Resource,
  `tr()` ao mostrar, traduções em `translations/content.{en,es}.po`. Depois de mexer em textos:
  `Godot --headless --path . -s tools/update_translations.gd`. Em funções estáticas, `TranslationServer.translate()`.
  Texto já traduzido em Label dinâmico: `auto_translate_mode = DISABLED`. Textos montados uma vez se refazem em
  `NOTIFICATION_TRANSLATION_CHANGED`. Revisão em planilha: `-- --review` / `-- --apply=<csv>`.

## Regras técnicas (as que mais quebram)
- **Pixels perfeitos**: tudo em 1x1 sobre 960×540 (`scenes/app.tscn`, `GameView`: o `main.tscn` num `SubViewport`
  "nearest", ampliado só em múltiplos inteiros, `_fit`; o que sobra é borda escura). Nada de girar ou esticar pixel
  art pela transformação do desenho: gire pixel a pixel (`PixelArt.turned`, RotSprite) ou desenhe na tela. Gradação de
  cor no `Box` (`grade.gdshader`, `GameView.GRADES` por clima).
- **Fonte**: uma só, Departure Mono (`Pal.ui`/`Pal.mono`), **só em múltiplos de 11**; a única exceção é a letra de mão
  (`Pal.hand`, desenhada em `hand_font.gd`, posta no tema `HandText` pelo `Settings`), só no 11, em tudo o que é escrito à mão. Em objeto da sala, nada acima
  de 11: use 11 em negrito (sombra de 1 px), `PixelArt.big`/`relief` ou letra desenhada à mão. Gravado no painel:
  `PixelArt.tiny` (maiúsculas 3×5 com acentos).
- **Cores e materiais no `Pal`** (rampas `Array[Color]` escolhidas por `Pal.ramp`/`Pal.lit`), usados pelo objeto da
  sala e pelo papel aberto dele: o que muda numa ponta muda na outra.
- **Desenho**: área cheia em `draw_primitive` (até 4 pontos, seguidos com o mesmo número de pontos), não
  `draw_polygon`; no cenário, `Background._fill`/`_poly` (na mesa e no tampo, em px da tela, com os pontos no pixel inteiro: `_snap`; beira longa à vista em inclinação limpa: `clean_slope`, nos cantos de trás dos objetos `exact_slope`). **Só redesenhe quando o que é mostrado muda** (estado
  comparado no `_process`: `Background._state`, a camada `_over`, `_back_state`, o `_look` de cada camada da mesa);
  algo novo que muda entra no estado da camada certa. Imagem montada pixel a pixel fica guardada; caches com limite.
  Cor que muda a cada quadro vai no `modulate`, nunca nas cores de `PixelArt.disc`/`art`.
- **Luz**: nada de `PointLight2D` (o `check.sh` acusa). Luzes que mudam entram por parâmetros de shader:
  `lamp_light.gdshader` (luminária, no `SceneView`), `room_noir.gdshader` (`_noir`), `window_lights.gdshader` (até 8,
  `_window_light_list`), `board_glow.gdshader` (painel, até 16, via `Bloom.lights_of`), `Background.daylight`. Ponto
  aceso brilhando: `Bloom.clear(self)` no começo do `_draw` e `Bloom.light(...)` por luz; o que tapa, `Bloom.occlude`.
  Luz com forma: camada somada (ADD) com a força no `modulate`. Parâmetro de shader entra no estado comparado.
- **Som**: tudo sintetizado ao iniciar (`SfxSynth.build()`, em pedaços no `WorkerThreadPool` em alta prioridade, um
  `RandomNumberGenerator` por pedaço; **nada de chamar função a cada amostra** num laço de som), menos o ambiente gravado (chuva, tempestade, vento, grilos, trovão: gravações CC0 do Freesound em
  `audio/ambience/`, preparadas por `tools/ambiente/preparar.py`, `Sfx.RECORDED`). Tocado pelo autoload
  `Sfx`; `Sfx.play_at(id, screen_x)` para som com lugar na tela. **Volume só por `Sfx.fade`/`Sfx._tween`** (uma
  mudança nova cancela a anterior). Barramentos em `default_bus_layout.tres` (Ambience com sidechain em Voices,
  Voices, Effects, Rub, Phone, Wind: o vento, que mede a rajada da folhinha, `Sfx.gust`).
- **Tempo e pausa**: todo `create_timer` com `false` no 2º argumento. Recomeçar é sempre `Main.restart()`, nunca
  `reload_current_scene()`. Pausa: `PauseMenu` (`get_tree().paused`); o `Box` do `GameView` processa sempre.
- **Sorteio**: use o global (`randf`, que segue a semente `--seed`, aplicada no `Main._enter_tree`, antes dos filhos);
  `randomize()` anula a semente (o `check.sh` acusa). Em threads, um `RandomNumberGenerator` cada. O som sorteia no
  `Sfx._rng` e o cenário no `Background._rng` (`_pick`), nunca no global (andam pelo relógio real). Animação do desenho pelo `PixelArt.ms()`, não
  `Time.get_ticks_msec()` (para nas capturas com `--still`).
- Cursores próprios no autoload `Cursors` (pixel art; passe `Image`, não textura, ao `Input`).
- Configurações no autoload `Settings` (`user://settings.cfg`: `locale`, `volumes`, `fullscreen`, `colorblind`,
  `keys`); `set_*` vale na hora, `save()` grava, `restore(snapshot)` desfaz. Testes não leem nem gravam o arquivo.
  Daltonismo: o verde de "em conversa" e "tudo certo" vira azul (`Pal.ok()`, `Pal.colorblind`; use-o em vez de
  `Pal.GREEN` onde a cor quer dizer isso). Teclas de atender, transferir, escutar e desligar trocáveis
  (`Settings.KEY_ACTIONS`, `set_key` troca com a que já usava a tecla; a etiqueta dos botões segue `key_name`).
- Entrada (Input Map): `cancel_plug` (Esc, botão direito), `pause` (Esc, P), `answer_call` (Espaço),
  `transfer_call` (Tab), `listen_call` (Z), `hang_up` (X), tratadas em `PhonePanel._input` antes da interface;
  ferramentas 1–5 (`Main.TAB_KEYS`, `Tools.toggle`); ids das ferramentas sempre pelas constantes `Tools.DIRECTORY`,
  `DISPATCH`, `LOGBOOK`, `CALL_LOG`, `DIARY`, `NEWS`, `TOLL`.

## Rodar e testar
- Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (fora do PATH). Compilar: `Godot --headless --path . --quit-after 60`.
- **Hooks** (`.claude/settings.json`, `.claude/hooks/conferir.sh`): cada Edit/Write num `.gd`/`.tscn`/`.tres` roda o
  `check.sh` nesse arquivo e compila o projeto; o Stop recompila se algo mudou por fora do Edit. Erro apontado: corrija.
- **Com o editor aberto, nada de `--import`** (corrompe `.godot/uid_cache.bin`; o `run.sh` pula sozinho). `class_name`
  novo e traduções novas (`ui.csv`, `.po`) só valem depois de reimportar: peça ao usuário para dar foco ao editor.
- **Testes: `tests/run.sh`** (~2 min; `tests/run.sh flow penalties` roda só esses), com `--fixed-fps 60`. À mão:
  `Godot --headless --fixed-fps 60 --path . tests/runner.tscn -- --test=x --seed=1`. Testes são cenas
  (`tests/test_<x>.gd` estende `test_base.gd`: `ok()`, `wait_until`, `load_main`, `finish`); tempo em quadros, nunca
  `Time.get_ticks_msec()`.
  - `test_content` (o conteúdo de `data/` sem a cena, ~2 s: referências, lacunas, traduções, marcadores, falas fora
    do `.po`, número da lista que não é destino de nada; rode depois de mexer em `data/`), `test_flow` (cenários), `test_keys` (teclas e mouse pelo `GameView`, e a troca de teclas), `test_layout` (objetos da mesa sem
    sobreposição; rode ao mexer na disposição), `test_rua` (cada cena da rua com a vista desenhada, a pausa, a tela inicial e o fim da presa), `test_penalties` (consequências, relatório, conta do conceito),
    `test_bureaucracy` (núcleo e B1–B4 com as ligações de teste dos `.tres`), `test_training`, `test_dial` (o discador), `test_shift` (o robô joga o turno inteiro e imprime métricas e a eficiência; `--human` mede o
    ritmo de uma pessoa, `--eager` não espera o fim da ligação, `--clumsy`, `--nosy`, `--careless`, `--night=N`, `--lang=`; falha se o atento ficar abaixo
    de Regular; `--path=sucesso|amarga|presa|fracasso` joga um caminho da história, e `tools/caminhos.sh` as 15 noites
    de cada um em sequência conferindo o final e listando as ligações do roteiro de cada noite em `build/caminhos/`, ~5 min:
    rode só quando mudar a estrutura do roteiro, `requires`, marcadores, ligações da noite, horários; fala só de texto, o `test_content`). Rode depois de mudar agenda, fim de ligação, mesa ou cabos.
- Opções do jogo: `-- --seed=N`, `--night=N` (sem ler nem gravar o save), `--weather=X`, `--lang=X`, `--pace=N`, `--flags=a,b`.
- **Painel de debug** (F1, `DebugPanel`, só em build de debug): toca ligações, mexe no relógio, clima, luz, noites,
  viaturas e advertências, mostra a eficiência ao vivo, cronometra os passos de cada ligação no log; mesa de som (`Sfx.vol`) e aba de vozes. O que mexe no Main fica
  em funções públicas dele (`ring`, `drop`, `drop_all`, `set_weather`, `start_ending`...).
- **Captura** (`tools/shot.tscn`, com tela, **uma de cada vez, janela pequena no canto**):
  `Godot --resolution 160x90 --position 0,0 --quit-after 1500 --path . tools/shot.tscn -- --hour=22:30 --weather=rain --out=build/x.png`.
  As opções estão no comentário do topo de `tools/shot.gd` (`--tool`, `--card`, `--hover`, `--screen=intro|pause|settings|report`,
  `--rating`, `--warned`, `--zoom`, `--still`...). Compare capturas com `tools/diff_shots.gd`; conjunto do plano
  hi-bit: `tools/hibit_shots.sh build/hibit/<pasta>`; cores e degradês das capturas: `tools/pixel_map.gd`. Degraus de uma beira: `tools/edge_steps.gd` (as consertadas, com os degraus aprovados, em `tools/beiras.txt`, que o `visual.sh` confere). **Regressão visual**: `tools/visual.sh [commit]` (~2 min, 12
  capturas do commit contra o disco, a tela inteira; sem a chuva, que ainda varia). Rode em mudança que
  não deveria mudar a tela (refatoração, desempenho) e confira que só mudou o esperado nas que deveriam.
- Desempenho: sem tela, a vista da janela não é desenhada (`Background._headless`); a vista no amanhecer desenha ~17 mil
  itens (o `project.godot` põe `item_buffer_size` em 32768; o editor pode apagar a linha, o `test_layout` confere).
  Mexeu em desenho ou em algo por quadro: meça com o `medir.gd` da skill `revisar-mudancas`.
- Exportar: skill `exportar-build`. CI: `.github/workflows/testes.yml` (`tests/run.sh` em todo push e PR; `check.sh` no PR).
- Revisão de continuidade do roteiro, só quando o usuário pede: skill `revisar-roteiro` (aponta, nunca escreve falas);
  auditoria narrativa (estrutura, personagens, escolhas, ritmo), só quando pede: skill `auditar-roteiro`.

## Arquivos e arquitetura
- `Exchange` (`scripts/model/exchange.gd`) é o **dono único** do estado das linhas e destinos (`Line`, `Dest`); o Main
  só avisa o `Supervisor` (consequências).
- `Background` e `Switchboard` em camadas por herança (`extends "res://..."`, sem `class_name` nas de baixo):
  `background_base` → `background_view` (a vista) → `background_props` (tampo e objetos) → `background` (sala,
  camadas, mouse); `switchboard_base` → `switchboard_panel` → `switchboard_plugs` → `switchboard`. Função nova vai na
  camada do que ela desenha.
- `PixelArt` (`scripts/ui/pixel_art.gd`): texturas em código (`art`, `disc`, `tiny`, `big`, `turned`); sem arquivos de
  imagem. `Pal` (`scripts/ui/pal.gd`): cores, rampas e fontes.

## Modelo das ligações
- `Main.live`: ligações tocando ou em andamento. **Foco** = a ligação da entrada onde está o FONE (`Main._focus()`);
  quem não está em foco fica em espera e não fala (`_until_on_line`), salvo a já resolvida (`c.closing`).
- Transferência: FONE na entrada → Atender → pedido → cabo saída→destino → Transferir (`transfer()`) → `_ring_dest` →
  `_try_complete` → linha e destino CONN por `Pace.talk_len` → DONE até tirar as pontas. Ligação do roteiro
  tocando para um destino em conversa encurta a de lá (`Main._free_dest_for`). Destino que não atende: a
  alternativa do mesmo ramo (`TransferCall.alt_target`, `DirectoryEntry.category`, `GameData.alternative`).
- **Escuta** (`Eavesdrop`): chave de escuta por linha (`Exchange.key`); a conversa ouvida vem do motivo (`Motive`) ou
  das falas escritas (`TransferCall.overheard`); palavras-chave `[tipo:texto]` (`Clue`) vão para as anotações da
  lista (`Progress.clues`); a suspeita (`PhoneCall.suspicion`, `LISTEN_SEC`, `HUSH`, desconfiança `wary`) leva ao
  silêncio, à pergunta e à denúncia (`_denounce`), cobrada no relatório da noite seguinte (`Supervisor.fault_later`; `nights` adia mais).
  O ritmo da fala (`PACE`) e a suspeita andam juntos: mudou um, confira o outro.
- **Interurbano**: troncos 901–906 (`GameData.TRUNKS`), a telefonista de lá (`Main._trunk`), o número de lá
  (`TransferCall.far_number`). **Calculógrafo** (`Toll`, `TollTicket`): conta a ligação interurbana, imprime o bilhete,
  o jogador carimba e guarda na caixinha; esquecido ou sem carimbo é advertência leve. Pendências chamam atenção
  no próprio papel, pulsando (`Background._nag_layer`): a tira por registrar e o bilhete fora da caixinha; nunca numa
  lâmpada de máquina, que não saberia (`LESSONS.md`).
- Telefonistas das centrais (`GameContent.operators`: 001 Morgana até a 4, 002 Cecília até a 7; setor entregue é central fechada; 003 é a própria, `GameData.OWN`): só
  pelo discador, números no rodapé da lista (`PhoneBook._footer`); `DirectoryEntry.answers_until`/`gone_from`.
- **Discador** (`Dialing`, nó do Main; `PhoneCall.Kind.OUTGOING`, `Conversation._outgoing`): o operador liga pelo
  próprio fone (sem o FONE); na prateleira (`Dialer`, `dialer.gd`) e de perto num pop-up em cima dele (`DialView`), só clique.
  Enquanto dura, é o foco (a linha do FONE em HOLD) e a do lugar fica ocupada (`Exchange`, `seized`); fora do caderno. Atende a do
  roteiro (`DialCall`, `Night.dial`/`GameContent.dial`, passos de `PrankStep`; a senha do Dia 4 ao hotel 305, das 20:30 às 21h) ou o atendimento do lugar
  (`DirectoryEntry.answers`, `ChatTopic`, `closes`; todo número da cidade, menos os do despacho; palavras-chave nas respostas, `Eavesdrop.note`); a do roteiro atende também fora dos setores. Marcador `ligou_<número>_<noite>`. `PLANO_DISCADOR.md`.
- **Diário de Maria** (`Diary`, nó do Main; `diary_view.gd`, `Tools.DIARY`, tecla 5; na frente da mesa, onde ficava o
  jornal, que foi pregado no quadro de avisos): as tarefas da noite, só lidas do jogo, sem pontos (os pedidos do roteiro
  em `Night.tasks`, `DiaryTask`, pelos marcadores, `done`, `until`, `at_close`, `letter`; normas pelo
  `BureaucracyRule.task_text`, riscadas no turno encerrado sem advertência delas; rotina com quanto falta) e, à direita,
  as anotações dela (`Night.diary`, `DiaryLine`: no fim da ligação do roteiro `call` com o desfecho, `Main.story_ends`;
  pelos marcadores; o balanço `at_close`), tudo por demanda (nada antes de alguém avisar); a carta lida fica guardada
  nele (o clique abre); o presente da Cecília no treinamento; a página de cada noite no save (`Progress.diary`, `Diary.page`), folheadas
  pelas dobras nos cantos de baixo; no fim do turno abre sozinho antes do memorando (`Main.DIARY_WAIT`; no fim do jogo, a última página antes do "Fim", uma linha por final); tarefa nova
  põe o lápis em cima dele (`Background.diary_new`). O plano em etapas: `HISTORICO` 564.
- Fim de ligação: `end_call(c, PhoneCall.End.*)` → `c.record` → `Notebook.add()`; o caderno registra com um clique no
  tipo (`register(T.Key.TYPE_*)`). A conversa do roteiro (`PrankCall` com `beat`) é ligação comum no caderno (com `prank`, trote). `TransferCall.busy_line`: o destino dá ocupado na primeira tentativa.
- **Despacho** (`Dispatch`, `CityMap`, `CardMachines`, `PunchCard`): marcar o trecho no mapa imprime o cartão (dois cliques: o primeiro só datilografa, `CardMachines.draft`; o anel da moldura aproxima, `_knob`);
  perfurar tipo e unidades; levar ao transmissor (envia) ou à trituradora; um cartão por vez. Regras das viaturas no
  `Fleet` (`scripts/model/fleet.gd`: `send` → `arrive` → `leave` → `home`, `Fleet.Result`). Cidade em folhas
  (`CityMap.SHEETS`), só as dos setores atendidos.

## Consequências e conceito
- `ShiftReport`: advertências (`FAULTS`; gravidades leve, média, grave, gravíssima), acertos (`credit`, `CREDITS`, só
  decisões, marcados pelo `Supervisor.credit`, nunca no treinamento), eficiência interna
  (`positives ÷ (positives + negatives × rigor da noite)`, `POINTS`, `RIGOR`), **conceito** (`grade()`: Ótimo, Bom, Regular, Insuficiente;
  `GRADE_MIN`; emergência perdida = Insuficiente). Duas noites seguidas abaixo de Regular demitem (`low_nights`,
  `LOW_LIMIT`, `fired()`). Mudou um peso: recalibre com várias sementes (`tools/calibrar.sh [tabela anterior]`, ~4 min).
- O Main chama `supervisor.fault()` onde a falha acontece; `Supervisor.call_ended()` decide advertência e retorno
  (`call_again`, uma vez por motivo). Treinamento e trotes não geram advertência.
- **Barra de agravamento** (`Urgency`, `PhoneCall.stage`): corre desde o atendimento, para em pergunta e resposta, com máquina do despacho trabalhando (`CardMachines.working`) e de
  vez com o socorro completo no lugar certo; cada estágio exige mais unidades (`Fleet.require`). Até duas emergências
  ao mesmo tempo (`Main.MAX_EMERGENCIES`); viatura de reserva só com duas (`Fleet.spare`).
- Fim do turno: `Main.start_ending` → `Supervisor.shift_over` → `Ending.play(report, more, text, memo)` → `ReportView`.
  **Finais** (`Rebellion.final`, no veredito da 15, `final_*`): três, sucesso, fracasso, presa (o golpe
  falhou e ela cortou mais pedidos das autoridades do que atendeu; a cena `Arrest` na rua e o fim); texto do fim por
  final em `Night.endings`. A vitória amarga é variação do sucesso no epílogo (`custou_gente`, `Rebellion.costly`). O fim do jogo (epílogo ou presa) não tem relatório: o fecho, "Fim", os créditos e o menu.
  **Epílogo**: a noite 16, `GameContent.epilogue`, fora de `nights` (a "última noite" continua a 15).
- **Broches** (recompensas, `scripts/model/badges.gd`, `Badges.award` no fim da noite; `Progress.badges`/`tally`, somem
  com o save): numa almofada na prateleira da mesa (`scripts/ui/badges.gd`, `%Badges`, filho do `Board`; o mouse que
  não pega broche segue para a mesa). Broche novo: id em `Badges.ALL`, cores em `Pal.BADGE_ENAMEL`, desenho em `ICONS`.

## Burocracias
- Normas que o jogador pode descumprir (registra e penaliza, nunca bloqueia): uma regra por `.tres` em
  `data/bureaucracy/` com um script `extends BureaucracyRule` (`scripts/bureaucracy/`); o gerente `Bureaucracy` (nó
  do Main) chama os ganchos (síncronos: `await` num Resource devolvia o estado da corrotina), aplica a maior advertência
  da tentativa e registra as decisões (`decisions`, no `Progress.bureaucracy`). Cada uma vale nas noites do `.tres` (`active`,
  `from_night`/`to_night`: B1 da 3, B2 o bar 327 na 5 e na 6 e a rádio e a TV na 14 e na 15 (`b2_radio_tv`), B4 da 7; B3 da 10 na delegacia 184, no Hospital São Lucas 213 e na Alta Cúpula 296, o código no bilhete); chave geral
  `Bureaucracy.enabled` ligada no jogo (o debug e os testes desligam; regra que passa a valer no meio do turno começa
  na hora, `sync`). Pedido das autoridades (`StoryCall.authority`) passa sem advertência; na última noite nenhuma
  advertência conta (`Supervisor.fault`). Serviços: `codes`, `messages`, `agreements`, `tapes` (a fita da mesa vai a Sebastião, só na noite em que ele pediu, `Tapes.ASKED`, ou às autoridades, `Tapes.give`; a conversa das próprias autoridades entregue a elas é gravíssima, e sem fita não é cobrada; o turno espera as sem destino, `Main._tapes_open`; noite com ligação para o bar sem fita às autoridades, advertência leve, `bar_number`). A ativação vai para o save (`state`, `_restore`). Equipamentos da mesa:
  `unlock_equipment` (marcador `equipamento_<id>`), cena `scenes/ui/equipment/<id>.tscn` na prateleira embaixo do
  Interurbano (`Switchboard.set_equipment`, `bay_rect`) ou, com `metadata/side`, na coluna à direita do painel
  (`side_rect`; os da B4). Como criar uma: `BUREAUCRACY_RULES.md`; aba Burocracias no F1.

## Noites, setores e agenda
- 15 noites (`GameContent.nights`, `Night`, `data/nights/`); a noite 0 é o treinamento (`Training`, `LessonStep`, a
  Cecília). Só `story` é fixo (a ligação desconhecida saiu). Todas, até o epílogo, têm o roteiro de Maria.
- Setores: o primeiro dígito do número (3 Vila Serena, 1 Centro, 2 Alto da Serra); o operador recebe o 1 na noite 5 e
  o 2 na 10, nunca em noite de evento do golpe (`GameData.SECTOR_NIGHTS`; `GameData.sectors` definido em `Main._load_night`). Testes de cenário usam
  `load_main([1, 2, 3])`.
- Ritmo por nível (`Pace`, 9 níveis; `Pace.next` pelo conceito; o último é o limite; do 6 ao 9 o mesmo `mean_gap` do 5, com mais picos).
- Cenas na rua da vista: `Night.street_events` (`StreetEvent`: `kind`, `at`, `every`; o Main chama
  `Background.schedule`). A 3: o policial (`scripts/ui/beating.gd`); a 7: a viatura estacionada no hotel (`PATROL_*`);
  a 9: o vigia no terraço (`LOOKOUT_*`); 9 a 14: o toque de recolher às 21h, `CURFEW_*`, `_hurry`; 4 a 12: pichação,
  carro de som, panfletos, tinta, corrida, desfile e banca; 13: a batida no hotel às 20h, só com uma fita do hotel na polícia (`Raid`: camburão, viatura,
  cinco presos); 13 e 14: o homem de sobretudo embaixo do poste das 22h às 22h50 (`stranger`); 14: a fuga da família às 20h (`Moving`) e a pedra que trinca a janela às 23h, só sem chances altas (`Stone`, camada
  `_crack` na vista, o trincado fica para a 15); cena com `StreetEvent.requires` conferida na hora (`Main._street_check`,
  liga `rua_<kind>_<noite>`); 14: o hotel lacrado, as janelas apagadas a noite toda (`closed`); 15: o letreiro do hotel apagado (aceso meia hora depois do veredito vencido, `sign_from`, `SIGN_AFTER`), o
  sinalizador vermelho às 21h (`Flare`, camada `_flare` entre o céu e a cidade), o incêndio e o combate longe, atrás da igreja, das 21:20 às 4h (`Battle`, camadas `_battle`/`_battle_add`; os estrondos e as rajadas chegam depois do clarão) e a bandeira na varanda às 4h, só
  com `golpe_venceu` (`Banner`; o `_coup_verdict` roda antes do `_street_check`); um script por cena em
  `scripts/ui/`, relógio `_scene_t`; pichação, tinta, banca e o apartamento vazio ficam nas noites seguintes, `left_behind`). Regra de qualidade: `PLANO_RUA.md`.
- Marcadores do roteiro: `StoryFlags` (`flags.allows(requires)`, `flags.apply("nome" | "!nome")`), salvos no `Progress`.
  O desfecho de uma ligação do roteiro liga os dela (`StoryCall.if_connected`/`if_elsewhere`/`if_dropped`/`if_missed`/`if_hung_up`,
  `Main._story_outcome`; marcador `advertencia_*` ligado é advertência, `StoryFlags.FAULT`; a conectada só no fim da conversa, cortada antes vale `if_dropped`, `_story_talk_over`; `again` desligado: sem retorno automático; `if_delivered`, a fita entregue). O roteiro de Maria:
  `PLANO_ROTEIRO.md`. **Fator sucesso** (`scripts/model/rebellion.gd`, só dos marcadores e da noite; `test_story`): TV,
  rádio, pontos, nível (`chance_alta/media/baixa`, ligados por `Rebellion.sync`, que liga também `tomada_caiu`, a rádio já perdida na hora, para as falas da 9; ordens de Sebastião da noite 15 não cumpridas
  são vacilos, `Rebellion.ORDERS`); às 4h da 15 (`Main.VERDICT`; da meia-noite em diante, antes, quando já não há chance,
  `Rebellion.hopeless`), `golpe_venceu` ou `golpe_falhou` (o turno acaba ali e as missões que faltavam saem,
  `Main._coup_verdict`); a madrugada (contra-ataque, feridos, reforço à Capital, a armadilha do Sebastião): `PLANO_ROTEIRO.md`, item 13; depois do veredito, nenhuma sorteada (`Night.quiet_from`). Bilhete e jornal com versões por marcador (`Night.notes`,
  `news_if`, `StoryText`); a primeira matéria do jornal é a manchete do dia (toda noite uma; as emergências descem); a foto e a legenda seguem a manchete (`Night.photo_for`, desenhadas em `NewsView._tone`). Carta da noite (`Night.letters`, `letter_for`): envelope lacrado em cima do diário desde o
  começo (`Background.letter`, `_art_envelope`; aberta, sem o lacre, `letter_read`), aberta quando o jogador quiser
  (`Tools.LETTER`, `letter_view.gd`); a dica do começo avisa (`HINT_LETTER`).
- `Progress` (`user://progress.cfg`): próxima noite, ritmo, `low_nights`, marcadores, jornal, palavras-chave,
  denúncias, chuvas. A última noite ou a demissão limpa o save. Formato com versão (`Progress.VERSION`): mudou o tipo
  ou o sentido de um campo, suba e converta no `load_saved`; o que não dá para ler fica ao lado (`aside`).
- Agenda (`Schedule`, constantes no topo de `main.gd` e `schedule.gd`; emergência do roteiro conta no espaçamento das sorteadas): a ligação do roteiro espera a mesa em silêncio (`STORY_WAIT`); numa missão do roteiro (a ligação dele na mesa, a conversa dele escutada, a do discador) nada novo toca (`Main.on_mission`); intervalo
  `Pace.call_gap`; nada novo depois de `last_call` (23:40; a do roteiro marcada depois toca, `_story_late`) e, depois, o botão Encerrar turno; `GIVE_UP_SEC` 60 s;
  conversa fiada (`ChatTopic`, `Conversation.smalltalk`) só do cotidiano, nunca na ligação do roteiro (`PhoneCall.story`).
  Ligações escritas da noite (`Night.calls`: quem comenta a manchete, quem procura um parente preso) entram no
  sorteio em vagas de transferência (`Schedule._random_calls`), com `requires` conferido na hora de tocar; não são missão. A que vira
  emergência com a transferência demorando, no lugar da conversa fiada (`TransferCall.turns`, `Main.turn_emergency`), termina no despacho; quem volta a ligar
  (`StoryCall.callback`, `Main._call_back`) escolhe a versão pelo desfecho da primeira. Relógio: 0,75 min de jogo por segundo.
- O amanhecer da noite 15 (céu, sol atrás da igreja, luz do dia na sala): `scripts/ui/CLAUDE.md` e
  `docs/mapa-detalhado.md`.

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
