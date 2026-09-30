# Central de Vila Serena — memória do projeto

Jogo em Godot 4.6 (GDScript, renderer GL Compatibility), a caminho da versão definitiva. O jogador é o operador
noturno de uma central telefônica de cidade pequena (18:00–00:00). Mecânica: atender e transferir ligações numa
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
- **Conteúdo em Resources** (`data/content.tres` + um `.tres` por roteiro em `data/calls/`). Nada de falas no código,
  exceto as do operador e as da ligação desconhecida (roteiro fixo em `conversation.gd`).
- **Moldes** (`data/templates/`, listas `transfer_templates`/`emergency_templates` no content): `TransferCall`/
  `EmergencyCall` com lacunas **em inglês** (`{place}`, `{reason}`, `{street}`, `{house}`...), preenchidas por
  `GameData.template_transfer()`/`template_emergency()`. Motivos em `DirectoryEntry.reasons`. `TEMPLATE_CHANCE`
  (main.gd) mistura moldes e roteiros escritos (híbrido: principais de transferência e trotes sempre escritos).
- Todo o áudio é sintetizado no autoload `Sfx` (`scripts/sfx.gd`), inclusive as "vozes" por sílaba
  (`Sfx.speak_char`). Barramentos em `default_bus_layout.tres`: Ambience, Voices, Effects.
  O filtro de caixa oca (`_box`) é **só para sons de aparelhos** (campainha, chamando), nunca para o ambiente.
- Clima (`Main.weather`: "rain", "fog", "clear", sorteado; `-- --weather=X` força): `Sfx.start_ambience(w)`/
  `set_weather`/`hush_nature`/`stop_ambience`, `Background.weather` desenha a janela, `Main.smalltalk()` junta as
  falas gerais com as do clima.
- Pixel art desenhada em `_draw()`; cores e fontes em `pal.gd` (`Pal.*`).
- Textos visíveis passam por `tr()` (texto em português é a própria chave). Label/Button com texto fixo em cena
  traduzem sozinhos. `internationalization/locale/translations_pot_files` já lista os arquivos para gerar o .pot.
- Entrada: ação `cancel_plug` no Input Map (Esc e botão direito) devolve o plug que está na mão.
- Git: branch principal `development`; commits no padrão `tipo(#0000): descrição`. `.godot/` fica fora do git.
  Só faça commit quando o usuário pedir (na reestruturação ele autorizou um commit por etapa em `refactor/definitive`).
- Comentário `ponytail:` marca um atalho deliberado; mantenha o código enxuto e no estilo do arquivo.

## Rodar e testar
- Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (não está no PATH). Cena principal: `scenes/main.tscn`.
- Checar se tudo compila: `Godot --headless --path . --quit-after 60`.
- **Testes: `tests/run.sh`** (roda tudo em headless, com limite de tempo, e falha em `SCRIPT ERROR`).
  - `tests/test_base.gd`: base (`ok()` em vez de `assert`, que trava o headless; `wait_until`, `load_main`, `finish`).
  - `tests/test_flow.gd`: cenários dirigidos (transferência, espera, desistência, caderno, lugar fechado, ligar de volta ao desconhecido, cliques).
  - `tests/test_penalties.gd`: consequências (perdida e retorno, número errado, registro, despacho errado,
    emergência sem despacho, espera longa, informação errada) e o relatório. Relógio parado; retornos tocados à mão.
  - `run.sh` começa com `--import`: **`class_name` novo só existe depois de reimportar** (sem isso, parse error).
  - `tests/test_shift.gd`: robô que joga o turno inteiro e imprime métricas (máx. simultâneas, % com 2+/3+,
    % sem cabo livre, perdidas); `run.sh` roda com `--seed=1..3` e um turno `--clumsy` (deixa de atender 1 em 3).
  - Nos testes, `Main`/`Switchboard` ficam **sem tipo** (dependem do autoload `Sfx`, que não existe na hora em que
    o Godot compila um script `-s`). `PhoneCall`, `Exchange` e os Resources podem ser tipados.
  - Rode depois de qualquer mudança em agenda, fim de ligação, mesa ou cabos.
- Semente fixa: `Godot --path . -- --seed=123` repete a agenda do turno (sem `--seed`, é aleatória).
- Captura de tela: rodar SEM `--headless` e salvar `root.get_texture().get_image()`.

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
- `ends[]`: tomada de cada ponta (-1 = na base). **Ponta 0 = FONE** (cabo vermelho, encaixe `FoneSocket` no painel
  do telefone, só entra em entradas). **Pontas 1..2*PATCHES = cabos de conexão** (ocre, independentes; `mate(e)`
  dá a outra ponta; uma ponta na saída, a outra no destino). `PATCHES = 3`.
- `setup(exchange, socket)` liga a mesa ao estado e ao encaixe. `dest_of_output(n)` segue o cabo da saída n.
- `refuse(e, j)` decide compatibilidade (e o destaque amarelo/vermelho). `_has_point` estende o clique ao encaixe
  do FONE; por isso o telefone e seus containers acima do encaixe têm `mouse_filter = IGNORE`, e a mesa tem
  `z_index = 1` (desenha plug e fio por cima do telefone). Overlays têm z 2, intro/final z 3.
- Clique num plug encaixado → volta à base com animação (`_anim`, `RETURN_SEC`); arrastar move; clicar num plug da
  base deixa-o na mão até o próximo clique.
- Cabos são cordas de Verlet (`_step_rope`), uma por cabo (0 = FONE, k = conexão k).

## Modelo das ligações
- `live`: ligações tocando ou em andamento (várias ao mesmo tempo). O painel mostra `phone.shown()`.
- **Foco** = a ligação da entrada onde está o FONE (`Main._focus()`); Main mantém `c.on_line`. Quem não está em
  foco fica "em espera" e **não fala**: `say()`/`op()` aguardam `_until_on_line(c)`.
- Transferência: FONE na entrada → Atender → pedido → cabo de conexão saída→destino → **Transferir** (`transfer()`)
  → `_ring_dest` → destino atende → tirar o FONE → `_try_complete` → linha e destino CONN por `TALK_LEN`
  → DONE (vermelho) até o jogador tirar as pontas. `_dgen` invalida toques de destino quando o cabo sai.
- Fim de ligação: `end_call(c, PhoneCall.End.*)` gera `c.record` e manda para `Notebook.add()` (fila; não trava o turno).
- Despacho: `Dispatch.set_incident()` quando a emergência toca; `Dispatch.sent` → `Main._on_dispatched` →
  `Conversation.emergency_dispatched`. O tipo de ocorrência é obrigatório para enviar. Na chegada,
  `Dispatch.arrived(e, result, occurrence, extra)` ("ok", "missing", "wrong_place", "idle"; tipo marcado; unidades
  que não eram necessárias) → `Main._on_arrived`.

## Consequências (relatório do supervisor)
- `ShiftReport` (`scripts/model/shift_report.gd`): `FAULTS` (id → gravidade, descrição), `add()`, desfecho das
  emergências (`trouble`/`resolved`/`failed` → OK, LATE, BAD) e `verdict()`. Pensado para várias noites (`night`,
  `SEVERE_LIMIT`); ainda não é salvo.
- Main registra com `_fault()` onde a falha acontece; `_consequences()` (chamado em `end_call`) decide advertência e
  retorno; `_call_again()` agenda a mesma pessoa de novo (`PhoneCall.retry`; uma vez por motivo, `retried`;
  também no tutorial; nunca depois do fim do turno; `too_late` sorteado com
  `REDISPATCH_CHANCE`). `_check_hold()` encerra quem passou de `HOLD_GIVE_UP` em espera (`End.GAVE_UP`).
- Tutorial (`tut`), trotes e ligação desconhecida não geram advertência. Falas de retorno, manchetes e pareceres
  ficam no content (grupo "Supervisor e consequências").
- À meia-noite, `_start_ending` soma o que ficou sem registro e passa o relatório para `Ending.play(report)`, que mostra
  `ReportView` antes do título final.

## Agenda e ritmo (constantes no topo de main.gd)
- Principais em `GameContent.main_call_at` (4); ligação desconhecida (`MYSTERY`, entrada livre sorteada, guardada em `myst_line`) entre `MYST_FROM` e `MYST_TO` (22:00–23:30), só
  toca com a mesa em silêncio, por no máximo 30 min de jogo (`latest`).
- Extras: `_fillers` (`FILLERS` 4–6 pelo turno todo, `FILLER_GAP` 25 min entre ligações; pico com `PEAK_CHANCE`).
- `GIVE_UP_SEC`: extras desistem em 60 s, principais em 90 s; tutorial (`tut`) e desconhecida nunca desistem.
- Conversas transferidas duram `TALK_LEN` (34–68 min de jogo ≈ 45–90 s reais).
- Turno das 18:00 (`SHIFT_START_HOUR`) às 00:00 (`SHIFT_END` = 360 min); fim **depois** da ligação desconhecida ter caído (`_start_ending`).
- Relógio: 0,75 min de jogo por segundo real (`GAME_MIN_PER_SEC`): 6 h de turno ≈ 8 min reais.

## Histórico das decisões de design (o que o usuário pediu, em ordem)
1. Mesa com entradas + destinos; cabos limitados; desmontar conexões encerradas.
2. Teclado de discagem removido; ligações simultâneas; caderno em fila; mais variedade de conversas.
3. Menos simultaneidade (extras espaçadas, pico raro).
4. Conversas conectadas mais longas (45–90 min de jogo).
5. Modelo de cabos refeito: pares com chaves FALAR/TOCAR foram **substituídos** por FONE + saídas + cabos de
   conexão + botão Transferir (o usuário considera o vermelho "o cabo do fone").
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
    não completa; foi engano, os dois desligam e o solicitante liga de novo pedindo o certo. Clique rápido num
    plug da base (mesmo mexendo uns pixels) conta como clique (`CLICK_MS`).
12. Sons: campainha antiga e "tuuuu" abafados (caixa oca só nos aparelhos), chuva refeita. Clima sorteado por
    noite: chuva (só chuva), névoa (grilos e coruja), limpo (brisa, grilos e coruja); coruja intercalada.
13. Rádio mais largo e alto (3 linhas); abas 24 px mais baixas (mapa se ajusta à altura). Silhueta na janela
    `SHADOW_LEAD` (15 min) antes da ligação desconhecida (`Background.shadow`), some quando ela cai.
14. Ligações demais ao mesmo tempo depois do turno de 6 h: relógio a 0,75 min/s (turno volta a ~8 min reais) e
    retornos esperam a mesa esvaziar (`RETRY_WAIT`). Medido com o robô desastrado (`--clumsy`).

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
