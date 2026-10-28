# Project Switchboard — memória do projeto

Jogo em Godot 4.6 (GDScript, renderer GL Compatibility), a caminho da versão definitiva. O jogador é o operador
noturno da central telefônica de São Sotero (18:00–00:00; a última noite vai até as 6h): atende e transfere ligações
numa mesa comutadora com cabos físicos; ao fundo, uma ligação misteriosa de número desconhecido (terror leve).

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
  `PaperPanel`, `MemoPanel`, `TapedNote`, `InkLabel`, `InkBoldLabel`, `TypedText`/`HandText`...): prefira variação de
  tema a override por nó. Papéis escritos: efeito de RichTextLabel (`scripts/ui/paper_ink.gd`, `[typed]` e `[hand]`).
- Telas fora do turno são papéis: o bilhete do supervisor na abertura (`Intro`), pausa e configurações num papel com
  fita, o relatório num memorando (`ReportView`: timbre, serviços prestados, advertências com o carimbo da gravidade,
  parecer à mão, rubrica e o carimbo redondo do conceito, `_grade_stamp`, girado pixel a pixel e em lugar sorteado).
- Botão de resposta (`ChoiceButton`): fala curta do operador (`CHOICE_*`; a frase inteira, `OP_*`, vai para a
  conversa); ação do jogador entre colchetes ("[Oferecer outro lugar]").
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
- **Fonte**: uma só, Departure Mono (`Pal.ui`/`Pal.mono`), **só em múltiplos de 11**. Em objeto da sala, nada acima
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
  `RandomNumberGenerator` por pedaço; **nada de chamar função a cada amostra** num laço de som). Tocado pelo autoload
  `Sfx`; `Sfx.play_at(id, screen_x)` para som com lugar na tela. **Volume só por `Sfx.fade`/`Sfx._tween`** (uma
  mudança nova cancela a anterior). Barramentos em `default_bus_layout.tres` (Ambience com sidechain em Voices,
  Voices, Effects, Rub, Phone).
- **Tempo e pausa**: todo `create_timer` com `false` no 2º argumento. Recomeçar é sempre `Main.restart()`, nunca
  `reload_current_scene()`. Pausa: `PauseMenu` (`get_tree().paused`); o `Box` do `GameView` processa sempre.
- **Sorteio**: use o global (`randf`, que segue a semente `--seed`, aplicada no `Main._enter_tree`, antes dos filhos);
  `randomize()` anula a semente (o `check.sh` acusa). Em threads, um `RandomNumberGenerator` cada. O som sorteia no
  `Sfx._rng` e o cenário no `Background._rng` (`_pick`), nunca no global (andam pelo relógio real). Animação do desenho pelo `PixelArt.ms()`, não
  `Time.get_ticks_msec()` (para nas capturas com `--still`).
- Cursores próprios no autoload `Cursors` (pixel art; passe `Image`, não textura, ao `Input`).
- Configurações no autoload `Settings` (`user://settings.cfg`: `locale`, `volumes`, `fullscreen`); `set_*` vale na
  hora, `save()` grava, `restore(snapshot)` desfaz. Testes não leem nem gravam o arquivo.
- Entrada (Input Map): `cancel_plug` (Esc, botão direito), `pause` (Esc, P), `answer_call` (Espaço),
  `transfer_call` (Tab), `listen_call` (Z), `hang_up` (X), tratadas em `PhonePanel._input` antes da interface;
  ferramentas 1–4 (`Main.TAB_KEYS`, `Tools.toggle`); ids das ferramentas sempre pelas constantes `Tools.DIRECTORY`,
  `DISPATCH`, `LOGBOOK`, `CALL_LOG`, `NEWS`, `TOLL`.

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
    do `.po`, número da lista que não é destino de nada; rode depois de mexer em `data/`), `test_flow` (cenários), `test_keys` (teclas e mouse pelo `GameView`), `test_layout` (objetos da mesa sem
    sobreposição; rode ao mexer na disposição), `test_penalties` (consequências, relatório, conta do conceito),
    `test_bureaucracy` (núcleo e B1–B4 com as ligações de teste dos `.tres`), `test_training`, `test_shift` (o robô joga o turno inteiro e imprime métricas e a eficiência; `--human` mede o
    ritmo de uma pessoa, `--eager` não espera o fim da ligação, `--clumsy`, `--nosy`, `--careless`, `--night=N`, `--lang=`; falha se o atento ficar abaixo
    de Regular). Rode depois de mudar agenda, fim de ligação, mesa ou cabos.
- Opções do jogo: `-- --seed=N`, `--night=N` (sem ler nem gravar o save), `--weather=X`, `--lang=X`, `--pace=N`, `--flags=a,b`.
- **Painel de debug** (F1, `DebugPanel`, só em build de debug): toca ligações, mexe no relógio, clima, luz, noites,
  viaturas e advertências, mostra a eficiência ao vivo, cronometra os passos de cada ligação no log; mesa de som (`Sfx.vol`) e aba de vozes. O que mexe no Main fica
  em funções públicas dele (`ring`, `drop`, `drop_all`, `set_weather`, `start_ending`...).
- **Captura** (`tools/shot.tscn`, com tela, **uma de cada vez, janela pequena no canto**):
  `Godot --resolution 160x90 --position 0,0 --quit-after 1500 --path . tools/shot.tscn -- --hour=22:30 --weather=rain --out=build/x.png`.
  As opções estão no comentário do topo de `tools/shot.gd` (`--tool`, `--card`, `--hover`, `--screen=intro|pause|settings|report`,
  `--rating`, `--warned`, `--zoom`, `--still`...). Compare capturas com `tools/diff_shots.gd`; conjunto do plano
  hi-bit: `tools/hibit_shots.sh build/hibit/<pasta>`; cores e degradês das capturas (`PLANO_PIXEL.md`): `tools/pixel_map.gd`. Degraus de uma beira: `tools/edge_steps.gd` (as consertadas, com os degraus aprovados, em `tools/beiras.txt`, que o `visual.sh` confere). **Regressão visual**: `tools/visual.sh [commit]` (~2 min, 12
  capturas do commit contra o disco, a tela inteira; sem a chuva, que ainda varia). Rode em mudança que
  não deveria mudar a tela (refatoração, desempenho) e confira que só mudou o esperado nas que deveriam.
- Desempenho: sem tela, a vista da janela não é desenhada (`Background._headless`); a vista no amanhecer desenha ~17 mil
  itens (o `project.godot` põe `item_buffer_size` em 32768; o editor pode apagar a linha, o `test_layout` confere).
  Mexeu em desenho ou em algo por quadro: meça com o `medir.gd` da skill `revisar-mudancas`.
- Exportar: skill `exportar-build`. CI: `.github/workflows/testes.yml` (`tests/run.sh` em todo push e PR; `check.sh` no PR).
- Revisão de continuidade do roteiro, só quando o usuário pede: skill `revisar-roteiro` (aponta, nunca escreve falas).

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
  `_try_complete` → linha e destino CONN por `Pace.talk_len` → DONE até tirar as pontas. Destino que não atende: a
  alternativa do mesmo ramo (`TransferCall.alt_target`, `DirectoryEntry.category`, `GameData.alternative`).
- **Escuta** (`Eavesdrop`): chave de escuta por linha (`Exchange.key`); a conversa ouvida vem do motivo (`Motive`) ou
  das falas escritas (`TransferCall.overheard`); palavras-chave `[tipo:texto]` (`Clue`) vão para as anotações da
  lista (`Progress.clues`); a suspeita (`PhoneCall.suspicion`, `LISTEN_SEC`, `HUSH`, desconfiança `wary`) leva ao
  silêncio, à pergunta e à denúncia (`_denounce`), cobrada no relatório da noite seguinte (`Supervisor.fault_later`; `nights` adia mais).
  O ritmo da fala (`PACE`) e a suspeita andam juntos: mudou um, confira o outro.
- **Interurbano**: troncos 901–906 (`GameData.TRUNKS`), a telefonista de lá (`Main._trunk`), o número de lá
  (`TransferCall.far_number`). **Calculógrafo** (`Toll`, `TollTicket`): conta a ligação interurbana, imprime o bilhete,
  o jogador carimba e guarda na caixinha; esquecido ou sem carimbo é advertência leve.
- Fim de ligação: `end_call(c, PhoneCall.End.*)` → `c.record` → `Notebook.add()`; o caderno registra com um clique no
  tipo (`register(T.Key.TYPE_*)`).
- **Despacho** (`Dispatch`, `CityMap`, `CardMachines`, `PunchCard`): marcar o trecho no mapa imprime o cartão (dois cliques: o primeiro só datilografa, `CardMachines.draft`; o anel da moldura aproxima, `_knob`);
  perfurar tipo e unidades; levar ao transmissor (envia) ou à trituradora; um cartão por vez. Regras das viaturas no
  `Fleet` (`scripts/model/fleet.gd`: `send` → `arrive` → `leave` → `home`, `Fleet.Result`). Cidade em folhas
  (`CityMap.SHEETS`), só as dos setores atendidos.

## Consequências e conceito
- `ShiftReport`: advertências (`FAULTS`; gravidades leve, média, grave, gravíssima), acertos (`credit`, `CREDITS`, só
  decisões, marcados pelo `Supervisor.credit`, nunca no treinamento), eficiência interna
  (`positives ÷ (positives + negatives × rigor da noite)`, `POINTS`, `RIGOR`), **conceito** (`grade()`: Ótimo, Bom, Regular, Insuficiente;
  `GRADE_MIN`; emergência perdida = Insuficiente). Duas noites seguidas abaixo de Regular demitem (`low_nights`,
  `LOW_LIMIT`, `fired()`). Mudou um peso: recalibre com várias sementes (`tools/calibrar.sh [tabela anterior]`, ~4 min;
  `PLANO_EFICIENCIA.md`, seção 6).
- O Main chama `supervisor.fault()` onde a falha acontece; `Supervisor.call_ended()` decide advertência e retorno
  (`call_again`, uma vez por motivo). Treinamento, trotes e a desconhecida não geram advertência.
- **Barra de agravamento** (`Urgency`, `PhoneCall.stage`): corre desde o atendimento, para em pergunta e resposta, com máquina do despacho trabalhando (`CardMachines.working`) e de
  vez com o socorro completo no lugar certo; cada estágio exige mais unidades (`Fleet.require`). Até duas emergências
  ao mesmo tempo (`Main.MAX_EMERGENCIES`); viatura de reserva só com duas (`Fleet.spare`).
- Fim do turno: `Main.start_ending` → `Supervisor.shift_over` → `Ending.play(report)` → `ReportView`.
- **Broches** (recompensas, `scripts/model/badges.gd`, `Badges.award` no fim da noite; `Progress.badges`/`tally`, somem
  com o save): numa almofada na prateleira da mesa (`scripts/ui/badges.gd`, `%Badges`, filho do `Board`; o mouse que
  não pega broche segue para a mesa). Broche novo: id em `Badges.ALL`, cores em `Pal.BADGE_ENAMEL`, desenho em `ICONS`.

## Burocracias (só pelo debug, por enquanto)
- Normas que o jogador pode descumprir (registra e penaliza, nunca bloqueia): uma regra por `.tres` em
  `data/bureaucracy/` com um script `extends BureaucracyRule` (`scripts/bureaucracy/`); o gerente `Bureaucracy` (nó
  do Main) chama os ganchos (síncronos: `await` num Resource devolvia o estado da corrotina), aplica a maior advertência
  da tentativa e registra as decisões (`decisions`, no `Progress.bureaucracy`). Chave geral `Bureaucracy.enabled` (ligue por `enable`;
  regra que passa a valer no meio do turno começa na hora, `sync`) desligada = o jogo de sempre. Serviços: `codes`, `messages`, `agreements`, `tapes`. A ativação vai para o save (`state`, `_restore`). Equipamentos da mesa:
  `unlock_equipment` (marcador `equipamento_<id>`), cena `scenes/ui/equipment/<id>.tscn` na prateleira embaixo do
  Interurbano (`Switchboard.set_equipment`, `bay_rect`) ou, com `metadata/side`, na coluna à direita do painel
  (`side_rect`; os da B4). Como criar uma: `BUREAUCRACY_RULES.md`; aba Burocracias no F1.

## Noites, setores e agenda
- 15 noites (`GameContent.nights`, `Night`, `data/nights/`); a noite 0 é o treinamento (`Training`, `LessonStep`, a
  Cecília). Só `story` e `mystery` são fixos. As noites 3–15 ainda são genéricas.
- Setores: o primeiro dígito do número (3 Vila Serena, 1 Centro, 2 Alto da Serra); o operador recebe o 1 na noite 5 e
  o 2 na 9 (`GameData.SECTOR_NIGHTS`; `GameData.sectors` definido em `Main._load_night`). Testes de cenário usam
  `load_main([1, 2, 3])`.
- Ritmo por nível (`Pace`, 9 níveis; `Pace.next` pelo conceito; o último é o limite; do 6 ao 9 o mesmo `mean_gap` do 5, com mais picos).
- Cena na rua da vista por noite: `Night.street_scene` (a 3: o policial, `scripts/ui/beating.gd`).
- Marcadores do roteiro: `StoryFlags` (`flags.allows(requires)`, `flags.apply("nome" | "!nome")`), salvos no `Progress`.
- `Progress` (`user://progress.cfg`): próxima noite, ritmo, `low_nights`, marcadores, jornal, palavras-chave,
  denúncias, chuvas. A última noite ou a demissão limpa o save. Formato com versão (`Progress.VERSION`): mudou o tipo
  ou o sentido de um campo, suba e converta no `load_saved`; o que não dá para ler fica ao lado (`aside`).
- Agenda (`Schedule`, constantes no topo de `main.gd` e `schedule.gd`): a desconhecida entre `mystery_from` e
  `mystery_to`, com a mesa em silêncio; a ligação do roteiro espera a mesa em silêncio (`STORY_WAIT`); intervalo
  `Pace.call_gap`; nada novo depois de `last_call` (23:40) e, depois, o botão Encerrar turno; `GIVE_UP_SEC` 60 s;
  conversa fiada (`ChatTopic`, `Conversation.smalltalk`) só do cotidiano. Relógio: 0,75 min de jogo por segundo.
- O amanhecer da noite 15 (céu, sol atrás da igreja, luz do dia na sala): `scripts/ui/CLAUDE.md` e
  `docs/mapa-detalhado.md`.

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
