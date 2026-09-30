# Central de Vila Serena — memória do projeto

Jogo em Godot 4.6 (GDScript, renderer GL Compatibility), a caminho da versão definitiva. O jogador é o operador
noturno de uma central telefônica de cidade pequena (22:00–06:00). Mecânica: atender e transferir ligações numa
mesa comutadora com cabos físicos; ao fundo, uma ligação misteriosa pela linha 07 (terror leve).
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
  exceto as do operador e as da linha 07 (roteiro fixo em `conversation.gd`).
- Todo o áudio é sintetizado no autoload `Sfx` (`scripts/sfx.gd`), inclusive as "vozes" por sílaba
  (`Sfx.speak_char`). Barramentos em `default_bus_layout.tres`: Ambience, Voices, Effects.
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
  - `tests/test_flow.gd`: cenários dirigidos (transferência, espera, desistência, caderno, lugar fechado, 07, cliques).
  - `tests/test_shift.gd`: robô que joga o turno inteiro e imprime métricas (máx. simultâneas, % com 2+/3+,
    % sem cabo livre, perdidas); `run.sh` roda com `--seed=1..3`.
  - Nos testes, `Main`/`Switchboard` ficam **sem tipo** (dependem do autoload `Sfx`, que não existe na hora em que
    o Godot compila um script `-s`). `PhoneCall`, `Exchange` e os Resources podem ser tipados.
  - Rode depois de qualquer mudança em agenda, fim de ligação, mesa ou cabos.
- Semente fixa: `Godot --path . -- --seed=123` repete a agenda do turno (sem `--seed`, é aleatória).
- Captura de tela: rodar SEM `--headless` e salvar `root.get_texture().get_image()`.

## Arquivos
- `scenes/main.tscn` + `scripts/main.gd` (`Main`) — orquestra o turno: relógio, agenda, o que cada plug significa
  para as ligações, fim de ligação, linha 07 e final. Constantes de ritmo no topo.
- `scripts/conversation.gd` (`Conversation`, nó filho de Main) — como cada tipo de ligação se desenrola:
  `say`/`op`/`choose`/`wait` e os roteiros de transferência, informação, emergência, trote e linha 07.
- `scripts/model/phone_call.gd` (`PhoneCall`) — uma ligação: roteiro (`data`) + estado; emite sinais que o telefone
  escuta. `scripts/model/exchange.gd` (`Exchange`) — **dono único** do estado das linhas e destinos (enums `Line`, `Dest`).
- `scripts/data/*.gd` — classes de Resource do conteúdo; `scripts/game_data.gd` (`GameData`) — acesso ao
  `content.tres` (`CONTENT`, `entry()`, `street()`, `transfers()`, `pick()`...).
- `scenes/ui/*.tscn` + `scripts/ui/*.gd` — telefone (`PhonePanel`, `FoneSocket`), rádio, abas (`Tools`) com lista
  (`PhoneBook`), mapa (`MapView` + `CityMap`), despacho (`Dispatch`, dono das unidades e da ocorrência) e caderno
  (`Notebook`, fila de ocorrências e anotação da 07); `Intro`, `Ending`; widgets desenhados (`Switchboard`,
  `Background`, `Scrawl`, `Bevel`, scanlines).

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
  `Conversation.emergency_dispatched`.

## Agenda e ritmo (constantes no topo de main.gd)
- Principais em `GameContent.main_call_at` (4); linha 07 sorteada entre `MYST_FROM` e `MYST_TO` (02:00–05:30), só
  toca com a mesa em silêncio, por no máximo 30 min de jogo (`latest`).
- Extras: `_fillers` (5–7 pelo turno todo, `FILLER_GAP` 25 min entre ligações; pico com `PEAK_CHANCE`).
- `GIVE_UP_SEC`: extras desistem em 60 s, principais em 90 s; tutorial (`tut`) e linha 07 nunca desistem.
- Conversas transferidas duram `TALK_LEN` (45–90 min de jogo).
- Fim do turno: às 06:00 **depois** da linha 07 ter caído (`_close_shift` → anotação → `_start_ending`).
- Relógio: 1 min de jogo por segundo real (`GAME_MIN_PER_SEC`).

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

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
- Quer o protótipo preparado para virar versão definitiva (boas práticas do Godot).
