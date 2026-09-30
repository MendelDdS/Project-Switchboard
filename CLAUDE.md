# Central de Vila Serena — memória do projeto

Protótipo em Godot 4.6 (GDScript, renderer GL Compatibility). O jogador é o operador noturno de uma
central telefônica de cidade pequena (22:00–06:00). Mecânica: atender e transferir ligações numa mesa
comutadora com cabos físicos; ao fundo, uma ligação misteriosa pela linha 07 (terror leve).
O README.md descreve o jogo para quem joga/edita conteúdo; este arquivo é o mapa para quem mexe no código.
Leia também [LESSONS.md](LESSONS.md) antes de mudanças grandes.

## Convenções
- Tudo em português: textos da interface, falas, comentários (`##` para doc de função) e mensagens ao usuário.
- A interface inteira é montada por código em `main.gd` (a cena `main.tscn` é só a raiz). Nada de .tscn extras.
- Todo o áudio é sintetizado em `sfx.gd` (inclusive as "vozes" por sílaba). Não há arquivos de som.
- Pixel art desenhada em `_draw()`; cores e fontes em `pal.gd` (`Pal.*`).
- Git: branch principal `development`; commits no padrão `tipo(#0000): descrição`. `.godot/` fica fora do git.
  Só faça commit quando o usuário pedir (na reestruturação ele autorizou um commit por etapa em `refactor/definitive`).
- Comentário `ponytail:` marca um atalho deliberado; mantenha o código enxuto e no estilo do arquivo.

## Rodar e testar
- Godot: `/Applications/Godot.app/Contents/MacOS/Godot` (não está no PATH).
- Checar se tudo compila: `Godot --headless --path . --quit-after 60`.
- **Testes: `tests/run.sh`** (roda tudo em headless, com limite de tempo, e falha em `SCRIPT ERROR`).
  - `tests/test_base.gd`: base (`ok()` em vez de `assert`, que trava o headless; `wait_until`, `load_main`, `finish`).
  - `tests/test_flow.gd`: cenários dirigidos (transferência, espera, desistência, caderno, lugar fechado, 07, cliques).
  - `tests/test_shift.gd`: robô que joga o turno inteiro e imprime métricas (máx. simultâneas, % com 2+/3+,
    % sem cabo livre, perdidas); `run.sh` roda com `--seed=1..3`.
  - Rode depois de qualquer mudança em agenda, fim de ligação, mesa ou cabos.
- Semente fixa: `Godot --path . -- --seed=123` repete a agenda do turno (sem `--seed`, é aleatória).
- Captura de tela: rodar SEM `--headless` e salvar `root.get_texture().get_image()`.

## Arquivos
- `scripts/main.gd` — tudo do fluxo: montagem da interface, relógio, agenda, ligações, mesa (lógica), painel do
  telefone, despacho, rádio, caderno, final. É o arquivo grande (~2000 linhas).
- `scripts/switchboard.gd` — a mesa (desenho, entrada do mouse, física dos cabos, compatibilidade de tomadas).
  Não conhece ligações: emite `end_changed(end, jack, prev)` e o Main decide o que acontece.
- `scripts/game_data.gd` — conteúdo: lista telefônica `DIR`, `CLOSED`, falas (`T1`, `T2`, `FILL`, `EM`, `TR`,
  `INFO_*`, `SMALLTALK`, `WAITING`…), ruas do mapa, rótulos de estado.
- `city_map.gd`, `phone_book.gd`, `scrawl.gd`, `background.gd`, `sfx.gd`, `bevel.gd`, `pal.gd` — periféricos.

## Modelo da mesa (switchboard.gd)
- Tomadas por id inteiro: **1–10 entradas**, **11–20 saídas** (linha + 10), **destinos = o próprio número** (101–399,
  exceto 190/192/193, que vão pelo despacho).
- `ends[]`: tomada de cada ponta (-1 = na base). **Ponta 0 = FONE** (cabo vermelho, encaixe no painel do telefone,
  só entra em entradas). **Pontas 1..2*PATCHES = cabos de conexão** (ocre, independentes; `mate(e)` dá a outra
  ponta; uma ponta na saída, a outra no destino). `PATCHES = 3`.
- `refuse(e, j)` decide compatibilidade (e o destaque amarelo/vermelho). `_has_point` estende o clique ao encaixe
  do FONE, que fica fora do retângulo da mesa.
- Clique num plug encaixado → volta à base com animação (`_anim`, `RETURN_SEC`); arrastar move; clicar num plug da
  base deixa-o na mão até o próximo clique.
- Cabos são cordas de Verlet (`_step_rope`), uma por cabo (0 = FONE, k = conexão k).

## Modelo das ligações (main.gd)
- Cada ligação é um `Dictionary` (`c`): `kind` (transfer / emergency / prank / info / mystery), `line`, `ringing`,
  `active`, `ended`, `phase` ("await", "emerg", "info"), `t_lines` (transcrição própria), `opts` (botões próprios),
  `talking`, `main` (índice 0–3 das principais) ou `filler`, `time`, `rec` (registro do caderno).
- `live`: ligações tocando ou em andamento (várias ao mesmo tempo). `shown`: a exibida no painel.
- **Foco** = a ligação da entrada onde está o FONE (`_focus()`). Quem não está em foco fica "em espera" e
  **não fala**: `say()`/`op()` aguardam `_until_focused(c)`. Compare ligações com `is_same()`, nunca `==`.
- Transferência: FONE na entrada → Atender → pedido → cabo de conexão saída→destino → **Transferir** (`transfer()`)
  → `_ring_dest` → destino atende → tirar o FONE → `_try_complete` → linha e destino "conn" por `TALK_LEN`
  → "done" (vermelho) até o jogador tirar as pontas. `_dest_of_line(n)` segue o cabo da saída n até o destino.
- Estados: `lines[]` (free / ring / talk / hold / conn / done / ghost) e `dests{}` (free / ring / conn / done).
  `_dgen` invalida toques de destino em andamento quando o cabo sai.
- Fim de ligação: `end_call(c, reason)` (op / caller / missed / connected / mystery) gera registro na fila do
  caderno (`pending` + `pending_q`), que não trava o turno.

## Agenda e ritmo (constantes no topo de main.gd)
- Principais em `GameData.CALL_AT` (4); linha 07 sorteada entre `MYST_FROM` e `MYST_TO` (02:00–05:30), só toca com
  a mesa em silêncio, por no máximo 30 min de jogo (`latest`).
- Extras: `_fillers` (5–7 pelo turno todo, `FILLER_GAP` 25 min entre ligações; pico com `PEAK_CHANCE`).
- `GIVE_UP_SEC`: extras desistem em 60 s, principais em 90 s; tutorial (`tut`) e linha 07 nunca desistem.
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

## Sobre o usuário
- Escreve em português do Brasil e pede ajustes de design iterativos, em listas curtas.
- Gosta de respostas resumidas; confirma quando algo está "errado" pelo modelo mental físico da mesa telefônica.
