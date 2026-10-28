# Relatório da simulação — 27/10/2026

Branch `feature/0000-b4-fitas` (commit `e4bf311`), Godot 4.6.2.

## O que foi rodado

- **Suíte inteira** (`tests/run.sh`): 20 testes, **1 falhou** (`test_training`, ver Bugs).
- **75 turnos do robô** (`test_shift`), com noites forçadas de 1 a 15:
  - atento, 3 sementes por noite (45 turnos);
  - `--human`, 5 s por ação (15 turnos);
  - `--eager` (15 turnos);
  - `--clumsy`, `--human --nosy` e `--human --clumsy` nas noites 3, 6, 10 e 14.
- **Desempenho com tela** (`medir.gd` da skill `revisar-mudancas`): 12 cenários.
- **2 capturas** (`build/sim/a.png`: 21:30, chuva, emergência; `build/sim/b.png`: despacho com a ficha perfurada).
- **Leitura do código**: `main.gd`, `background.gd` (`_process`), `tapes.gd`, `intro.gd`, `shift_report.gd`, `pace.gd`, `progress.gd`, além de uma busca de código morto.

Limite: o robô não lê e não erra o mapa como uma pessoa. O `--human` só põe um tempo fixo por ação. Os números
mostram o ritmo e a pressão do turno, não a dificuldade de entender o jogo.

---

## 1. Balanceamento

### Números por perfil

| Perfil | Conceito | Eficiência | Advertências típicas |
|---|---|---|---|
| Atento (45 turnos, noites 1–15) | Ótimo em **todos** | 100% em **todos** | nenhuma |
| `--eager` (15) | Ótimo em todos | 100% | nenhuma |
| `--human` (15) | Bom (Ótimo só na 15) | 77–93% | **só `emergency_worse`, em todas as noites** |
| `--human --nosy` (4) | Bom/Regular | 73–76% | `emergency_worse` ×2 |
| `--clumsy` (4) | Insuficiente/Regular | 57–68% | `missed` ×2–4 |
| `--human --clumsy` (4) | Insuficiente | 39–53% | `missed` ×4–5 |

| Noite (atento) | Ligações | Emergências | 2+ juntas | Sem cabo | Maior silêncio | Mesa vazia |
|---|---|---|---|---|---|---|
| 1 | 10 | 1 | 0% | 0% | 53–56 min | 42–50 min |
| 2–4 | 9–13 | 1–2 | 0–3% | 0% | 37–52 min | 30–48 min |
| 5–14 | 10–13 | 1–2 | 0–4% | 0% | 33–52 min | 26–37 min |
| 15 (até 6h) | 22–24 | 2 | 0–1% | 0% | 37–40 min | 29–32 min |

(minutos de jogo; 1 min de jogo ≈ 1,3 s reais)

### Achados

1. **A emergência concentra toda a pressão, e no ritmo humano ela piora sempre.** O robô a 5 s por ação leva 40–48 s
   do atendimento até o envio do cartão: relato, protocolo, impressão (dois cliques), perfuração e transmissor. O
   estágio inicial dá 35–40 s. Assim, toda emergência vira `emergency_worse`, inclusive na noite 1. Sugestão: no
   nível 1–2 do `Pace`, um `stage_sec.x` maior (~50 s), ou contar o estágio só a partir do relato completo.

   ✅ **Feito em 28/10.**
   - A barra para enquanto uma máquina do despacho trabalha (imprimindo, transmitindo ou triturando:
     `CardMachines.working`).
   - Só isso não bastou: a de 35 s ainda piorava sempre e, na noite 3, foi perdida duas vezes.
   - Por isso o estágio inicial de todas as emergências subiu 10 s: 45/50/55 s.
   - Resultado em 20 turnos do robô `--human` nas noites 1, 3, 7, 10 e 12: **nenhuma emergência piorou**. Ele
     envia aos ~38 s.
2. **O jogador atento nunca sente pressão.** Ficou com 100% nas 45 noites. A mesa raramente tem duas ligações ao mesmo
   tempo (0–4% do turno) e o limite de cabos **não pesou em nenhum dos 75 turnos** (`sem_cabo=0%`).
3. **A curva de dificuldade fica plana da noite 6 em diante.** Pelo `Pace.next` e pelo `Pace.expected`, o nível 5
   chega na noite 6 e vale até a 15. Com a mesma semente, as noites 6–8 e as 9–14 saíram idênticas, ligação por
   ligação. Só o setor 2 (noite 9) acrescenta algo. São 10 das 15 noites sem nenhum degrau. Sugestões:
   - subir um nível a cada duas noites;
   - ou usar as burocracias (B1–B4, prontas mas só no F1) como os degraus das noites 6–15.

   ✅ **Itens 2 e 3 feitos em 28/10 (picos nas noites finais), exceto o cabo.**
   - Os níveis de ritmo 6–9 valem nas noites 7–15 (7: nível 6; 8–9: 7; 10: 8; 11–15: 9).
   - Eles trazem tantas ligações quanto o nível 5 (`Pace.mean_gap`), só que mais juntas: picos de 12% a 30%, com a
     mesa mais calma entre eles.
   - Medido no robô `--human`, 6 sementes por nível, na noite 12:

     | Nível | 2+ juntas | 3+ juntas | Perdidas por noite (máx) | Eficiência |
     |---|---|---|---|---|
     | 5 (antes, até a 15) | 10% | 0,5% | 0 | 81% |
     | 6 | 15% | 0% | 0 | 82% |
     | 7 | 22% | 3% | 0,7 (3 numa semente) | 82% |
     | 8 | 24% | 7% | 0,7 (1) | 82% |
     | 9 | 23% | 8% | 0,7 (1) | 82% |

   - ⏳ **Falta: o cabo ainda não falta.**
     - Em 28/10 as conversas ficaram mais longas nos níveis altos (`Pace.talk_len`: de 45–85 min no nível 6 a
       95–165 min no 9; antes, 34–68 em todos), como pedido em vez de diminuir os cabos.
     - Mesmo assim, o robô humano chegou a usar só **2 de 5 cabos** ao mesmo tempo, porque só transferências e
       interurbanos usam cabo (~6 por noite).
     - ✅ Em 28/10 a proporção de pedidos de informação caiu em todas as noites:
       - o `TRANSFER_SHARE` passou de 65% para 85%;
       - a informação não ocupa mais um número da noite;
       - a ligação a mais da mesa vazia virou transferência (`Schedule.filler`).

       Resultado: de 2,9 para 1,5 informações por noite, e de até 5 para no máximo 2 seguidas. Os cabos em uso
       continuaram baixos (2 de 3–5; uma vez, 4 de 5).
     - ✅ Em 28/10 a noite 1 ganhou um pouco mais de movimento: o nível 1 passou de 45–60 para 40–52 min entre
       ligações. O robô humano descuidado (`--careless`) e o apressado (`--eager`) seguiram com Ótimo nas 6 sementes.
       O desastrado (`--clumsy`) ficou em Insuficiente/Regular, mas ele deixa de atender 1 em cada 3 de propósito.
       Falta acompanhar com uma pessoa novata de verdade.
   - O nível 9 ficou quase igual ao 8: com mais picos, o humano passava a perder 2 ligações por noite.
4. **A noite 1 é lenta.** São 10 ligações, a mesa fica vazia de 42 a 50 min e o maior silêncio chega a 56 min (~75 s
   reais), logo depois do treinamento. Isso pode cansar quem acabou de aprender. Encurtar o `call_gap` do nível 1
   (45–60 hoje) para ~35–50 resolveria.

   ✅ **Em parte em 28/10**: o intervalo foi para 40–52 min (ver item 3).
5. **Perder ligações demite rápido.** Com uma em cada três ligações perdida, o turno cai para Insuficiente; duas
   noites assim demitem. É coerente com a regra, mas o `missed` (média, 15 pontos) contra ~70–90 pontos positivos
   por noite deixa pouca margem nas noites 1–3. Os primeiros turnos já seguram o ritmo (`CONFIDENCE_NIGHTS`), mas
   não seguram o conceito.

   ✅ **Feito em 28/10: o rigor do supervisor cresce com as noites** (`ShiftReport.RIGOR`, `rigor(n)`). As
   advertências pesam 0,6 na noite 1, 1,0 na noite 9 e 1,3 na 15, em linha reta. A emergência perdida continua
   Insuficiente em qualquer noite. Simulado sobre 90 turnos do robô (noites 1–15, atento e desastrado, 3 sementes):

   | Perfil (mediana) | Noites 1–2 | 3–8 | 9–11 | 12–15 |
   |---|---|---|---|---|
   | Desastrado (1 em 3 sem atender) | Regular (antes Insuficiente na 1) | Regular | Regular | Insuficiente |
   | Novato (1 perdida, 2 registros esquecidos) | Bom | Bom | Bom | Bom |
   | Mediano (2 perdidas, 3 leves) | Regular | Regular/Bom | Regular | Regular |
   | Um erro grave, um médio e um leve | Regular (antes Insuficiente) | Regular | Regular | Regular |

   Também comparadas: 0,5→1,0 parando na noite 8 (nunca fica mais rigoroso que hoje), 0,5→1,5 (reprova o desastrado
   já na noite 9) e 0,5→1,0 até a 6 e daí 1,3 (reprova na 8).
6. **Escuta:** o curioso em ritmo humano não foi denunciado em nenhuma noite. A cobrança vem na noite seguinte
   (`fault_later`), e o robô joga uma noite só, então a simulação não mede o peso real dela (grave, 30 pontos).

## 2. Melhorias gráficas

1. **A ficha de despacho cobre o mapa no trecho marcado** (`build/sim/b.png`): ela corta a etiqueta da rua ("Rua d…")
   e a faixa de numeração ("…00-299"), justo onde o jogador acabou de clicar. Isso fere a regra de não sobrepor
   objetos. Sugestão: a ficha sair do lado oposto ao trecho marcado, ou o mapa deslizar para manter o marcador à vista.

   ❌ **Descartado em 28/10.** Depois de marcar o local e imprimir, não há mais nada a fazer no mapa, então a ficha
   por cima não atrapalha.
2. **O painel do rádio fica quase vazio** (`build/sim/a.png`): uma mensagem no rodapé e ~70% do quadro em branco. Dá
   para mostrar as últimas 3–4 mensagens esmaecendo, ou reduzir o painel e dar o espaço à conversa.

   ❌ **Já era assim** (`radio.gd`, `HISTORY := 4`): o rádio mostra as 4 últimas mensagens. A captura foi tirada
   cedo no turno, com uma só.
3. **Nas noites 1–8, os painéis "SETOR NÃO ATENDIDO" (A e B) ocupam um bloco grande da mesa sem uso.** Uma tampa
   aparafusada ou uma etiqueta "reservado" deixaria a mesa com cara de equipamento real e daria mais peso à
   entrega do setor.

   ❌ **Mantido (28/10)**: o usuário viu as capturas (`build/sim/setores.png` e `setores_zoom.png`) e não viu
   problema.

O resto das capturas está coerente: luz, chuva, cabos e contraste.

## 3. Melhorias na jogabilidade

1. **O despacho tem passos demais para o tempo da barra** (ver Balanceamento 1). Nas primeiras noites, o clique no
   mapa já poderia imprimir (sem o rascunho do primeiro clique), ou a barra poderia parar enquanto a ficha é
   perfurada.

   ✅ **Feito em 28/10** com a barra parada enquanto as máquinas trabalham (ver Balanceamento 1). O rascunho do
   primeiro clique fica como está.
2. **Os tempos ociosos são longos** (26–50 min de mesa vazia por noite) e o jogo não oferece nada a fazer neles além
   da escuta. Tarefas curtas e mecânicas cabem aí: conferir bilhetes, arrumar a mesa, tirar as pontas que sobraram.

   ❌ **Já existe** (28/10): na mesa vazia há o caderno, os bilhetes do interurbano para carimbar e guardar, as pontas
   dos cabos para tirar e a escuta.
3. **As burocracias estão prontas e escondidas no F1.** Se a ideia é que façam parte do jogo, uma tabela de "a partir
   de que noite cada uma vale" (no `Night` ou no `Pace`) já resolve os itens 2 e 3 do Balanceamento.

   ⏳ **Em espera (28/10)**: ficam no F1 até o roteiro ficar pronto.
4. **O limite de cabos nunca aparece** (ver item 3 da seção 7).
5. **Resposta para quando todos os cabos estão em uso** (pedido em 28/10). Com todos os cabos de conexão encaixados, a
   ligação que pede transferência ganha o botão **[Todas as linhas ocupadas]**. O operador diz algo como "Neste
   momento todas as linhas estão ocupadas, deseja aguardar?", e quem ligou responde "Vou aguardar" (fica em espera
   até um cabo soltar) ou "Ligarei outra hora" (desliga, sem advertência). Assim, a falta de cabo vira uma decisão do
   jogador, e não um beco sem saída.

   ✅ **Feito em 28/10.**
   - O botão aparece sem nenhum cabo livre e some quando um cabo solta (`Main.no_cords`, `_busy_choices`).
   - Quem liga espera em 60% das vezes (`Conversation.busy_wait_chance`). Esperando, aguenta 40 s a mais de silêncio
     e o dobro do tempo em espera.
   - Nas outras 40%, desliga sem advertência, o caderno anota "Linhas ocupadas; vai ligar mais tarde" e ela liga de
     novo depois (`PhoneCall.Retry.BUSY`, com falas próprias).
   - Captura: `tools/shot.gd --busy`.

## 4. Bugs e possíveis bugs

### Confirmados

1. **CRÍTICO: o treinamento (noite 0) quebra na abertura.** `Tapes.note` (`scripts/bureaucracy/tapes.gd:79-82`):
   - Com `last` vazio e `n == 0`, o guarda `last.get("night", -1) != n - 1` compara `-1 != -1`, deixa passar, e
     `last["used"]` dá erro.
   - O erro interrompe o `Main._ready` na linha 179 (`_intro.setup`). Por isso o FONE não é plugado na entrada 1
     (`board.plugged(0, 1)`) e o `_refresh_panel` não roda.
   - Atinge **todo jogo novo**. O `test_training` falha por isso; entrou no commit `63d30bf`.
   - Conserto de uma linha: `if last.is_empty() or last.get("night", -1) != n - 1: return ""`.
   - ✅ **Corrigido em 28/10**: o guarda agora confere `last.is_empty()` antes. O `test_training` passa.
2. **A semente (`--seed`) não reproduz um turno com o FPS variando.** No `Background._process`
   (`scripts/ui/background.gd:520-545`), as gotas da chuva, as gotas no vidro e a poeira sorteiam no `randf` global, a
   30 Hz do relógio real. Elas consomem a mesma sequência que a agenda e as falas (`_nag` usa `randf`), então
   reproduzir um bug com `--seed` só funciona com `--fixed-fps`. É provavelmente também o motivo de o `visual.sh` não
   conseguir comparar a chuva. Conserto: um `RandomNumberGenerator` próprio do cenário, como o `Sfx._rng`.
   ✅ **Corrigido em 28/10.**
   - O cenário sorteia no gerador dele (`_rng`, nas três camadas do `Background`, semeado no `_ready` por um número
     do global).
   - O tremor da trituradora também saiu do global (`CardMachines._shake_rng`).

### Possíveis

3. **Vazamentos ao sair:** todas as execuções acusam `ObjectDB instances leaked` e `3–13 resources still in use at
   exit`. Ao sair, isso é inofensivo. Mas com o `Main.restart()` (recomeçar sem fechar o jogo), objetos presos podem
   se acumular entre as noites. Vale rodar uma vez com `--verbose` para ver o que fica.

   ✅ **Corrigido em 28/10.** As ligações em andamento ficavam presas na memória depois do `restart` por dois
   caminhos: a espera de desistir do `Main.ring` (um `await` de 60 s, agora um temporizador ligado a `_give_up`, que
   cai junto com o Main) e as opções de fala, presas à própria ligação pelo `bind` (o Main as solta ao sair,
   `NOTIFICATION_PREDELETE`). O `test_flow` (seção 19) confere. O que ainda aparece ao fechar o jogo são esperas
   curtas em andamento e os sons, que o motor solta só depois do aviso: inofensivo.
4. **`Sfx.later` usa `create_timer(t)` sem o `false`**: o som tocaria durante a pausa. Hoje não tem chamador (ver
   seção 7).

   ✅ **Resolvido em 28/10**: a função saiu junto com o código morto.
5. **O save não tem versão** (`scripts/model/progress.gd`). Um save de um build antigo com outro formato de
   `bureaucracy`/`clues` é lido sem conferência. Isso importa a partir do momento em que houver jogadores com
   saves de versões anteriores.

   ⏳ **Explicado em 28/10; fica para antes da primeira versão pública.**
6. **Atalho conhecido do debug** (`debug_panel.gd:225`): com duas emergências, o cartão pode ir para a errada.

   ✅ **Corrigido em 28/10**: o cronômetro do F1 segue a regra do envio de verdade (`Fleet.target_of`: a emergência
   do local marcado ou, sem local, a da linha do FONE).

## 5. Melhorias de desempenho

Medido com tela. Está bom no geral: média de 1,6–2,6 ms por quadro e **nenhum quadro acima de 16 ms**.

| Cenário | Média | Pior 1% | Chamadas de desenho |
|---|---|---|---|
| Parado (céu limpo, névoa ou chuva) | 1,6 ms | 5–8 ms | 262 |
| Guardando o despacho | 2,6 ms | 9,1 ms | **623** |
| Amanhecer, 5:40 | 3,0 ms | **14,3 ms** | **622** |
| Amanhecer, sol 8× | 6,6 ms | **14,0 ms** | **955** |

1. **O amanhecer é o ponto crítico**: o pior 1% chega a 14 ms, perto dos 16,7 ms de 60 Hz, e isso numa máquina boa.
   Num notebook com GPU integrada (renderer GL Compatibility), a noite 15 deve perder quadros. Sugestão: guardar
   numa textura as partes da vista que não mudam no amanhecer (a cidade parada) e redesenhar só o céu e a luz.
2. **A vista se redesenha 29 vezes por segundo em todos os cenários**, inclusive parada e com céu limpo. Vale
   conferir se o céu limpo precisa disso (as pessoas e os carros andando provavelmente sim; o resto pode ir para
   uma camada estática).
3. **Guardar o despacho chega a 623 chamadas de desenho.** O papel deslizando provavelmente redesenha o mapa
   inteiro a cada quadro. Uma textura do mapa enquanto ele anda resolveria.
4. **Alocações por quadro**, menores:
   - `Main._process` monta `Background.CALLED.map(_phone_state)` e `toll.layout()` a cada quadro;
   - `Background._process` monta ~8 arrays para comparar estados a cada quadro.

   Não aparecem na medição, mas somam lixo no coletor. Só vale mexer se algum dia o pior 1% subir.

❌ **Medido de novo em 28/10, nada a corrigir agora**: média de 1,6–3,1 ms, pior 1% até 14,5 ms (o amanhecer),
nenhum quadro acima de 16 ms, tudo dentro da referência da skill `revisar-mudancas`. Os itens 1–3 só valem se um
computador mais fraco perder quadros na noite 15 (conferir quando houver build para testar fora deste Mac).

## 6. Incrementos que deixariam o jogo mais divertido

(Só mecânica, sem conteúdo de história.)

1. **Picos de movimento ("hora do rush")**: 2–3 momentos por noite com 3–4 ligações quase juntas. É o que faz o
   limite de cabos, a espera e a escolha de quem atender primeiro existirem de verdade (hoje 2+ juntas é 0–4% do
   turno).

   ✅ **Feito em 28/10** com os níveis de ritmo 6–9 (ver Balanceamento 3).
2. **Imprevistos da mesa** nas noites 6–15, para criar variedade sem roteiro, sorteados por noite:
   - uma linha com defeito (lâmpada que não acende, chiado);
   - um tronco interurbano ocupado;
   - a chuva derrubando um poste e deixando um quarteirão sem linha.
3. **Ligação encadeada**: quem foi bem atendido liga de novo pedindo outra coisa (já existe o retorno por falha; o
   mesmo mecanismo serviria para o acerto).
4. **Marcas pessoais no relatório**: o melhor tempo de despacho, a sequência de noites sem advertência, o número de
   ligações. Isso dá ao jogador atento (100% sempre) algo para buscar além do conceito.
5. **Recompensa visível pelo conceito**: um objeto novo na mesa, um elogio preso no painel, uma caneca diferente.
   Tudo isso cabe no `Progress` e nos objetos de `data/room/`.

   ✅ **Feito em 28/10: os broches.** Oito recompensas que vão sendo destravadas, espetadas numa almofada de feltro
   na prateleira da mesa comutadora (nome sob o mouse, descrição no clique), presas ao save (ver o README, "Os
   broches").

## 7. O que pode ser removido

1. **Código morto** (sem nenhum chamador):
   - `Sfx.dial` e `Sfx.later` (`scripts/sfx.gd:266` e `:475`), sobras do teclado de discagem que saiu (HISTORICO 2);
   - `_pr` (`scripts/ui/switchboard_plugs.gd:523`);
   - `_sheets_of` (`scripts/ui/city_map.gd:480`).

   ✅ **Removidos em 28/10.** Saíram também o `Sfx.ringback` e o som `pulse`, que só a discagem usava.
2. **O limite de cabos, como está, não interfere em nada**: em 75 turnos, nunca faltou cabo. Ou ele passa a pesar
   (com os picos da seção 6), ou o painel de saídas pode ficar mais simples. Confira antes o HISTORICO 5 e 187: os
   cabos são a mecânica central, e o problema é o ritmo, não o cabo.
3. **O primeiro clique de rascunho no mapa** (`CardMachines.draft`) nas primeiras noites: é um passo a mais na corrida
   contra a barra (ver Balanceamento 1). Pode virar opcional ou sair até o jogador pegar o jeito.

   ❌ **Mantido (28/10)**: não faz sentido tirar só em algumas noites.

## 8. Melhorias para o processo de desenvolvimento

1. **Rodar os testes antes de cada commit.** O `test_training` quebrado entrou em `63d30bf` e seguiu em `e4bf311`. A
   skill `revisar-mudancas` roda o `check.sh`, mas não os testes. Basta incluir `tests/run.sh content training flow`
   (~30 s) nela, ou num hook de pre-commit.

   ✅ **Feito em 28/10**: a skill roda `tests/run.sh content training flow` antes de qualquer commit.
2. **O CI não roda nesta branch.** O `.github/workflows/testes.yml` dispara só em push na `development` e em PR. A
   `origin/HEAD` é a `refactor/definitive`, existem `develop` e `development` ao mesmo tempo, e a branch atual está
   240 commits à frente da `origin/HEAD`. Sugestões:
   - escolher uma branch principal e atualizar o `CLAUDE.md` (que diz `development`) e o workflow;
   - fazer push e abrir PRs com mais frequência.

   ✅ **Em parte em 28/10**: o CI agora roda em todo push, em qualquer branch.
   - ✅ A branch principal é a `develop`, já a padrão no GitHub; o `CLAUDE.md` foi corrigido.
3. **Há mais de 25 branches locais e remotas**, muitas já mescladas. Apagar as mescladas reduz a confusão sobre
   qual é a atual.

   ✅ **Em 28/10**: apagadas as 14 branches locais já mescladas na `develop`.
   - ⏳ Restam 6 locais não mescladas: `add-story-scripts`, `lower-shelf`, `player-pace`, `retro-switchboard`,
     `switchboard-fuses` e `pixel-2x`.
   - ⏳ Restam 2 remotas: `origin/master` (mesclada) e `origin/feature/0000-retro-switchboard`.
4. **Commits enormes**, com um parágrafo inteiro no assunto (`e4bf311`, `63d30bf`). O detalhe já vai para o
   HISTORICO. Um assunto curto e o corpo opcional tornam o `git log` e o `git bisect` úteis.
5. **Uma matriz de balanceamento versionada.** O script desta simulação (noites 1–15 × perfis, uma linha por turno)
   poderia virar `tools/matriz.sh`, rodando em paralelo (~10 min com 4 processos) e gravando um CSV, para comparar
   antes e depois de mexer no `Pace` ou nos pesos. O `tools/calibrar.sh` cobre só os pesos.
6. **`tests/run.sh` em paralelo**: os 16 turnos do robô rodam um depois do outro. Rodar 3–4 ao mesmo tempo reduziria
   os ~2 min da suíte.
7. **Limpar os vazamentos ao sair** (Bugs 3), para que um vazamento novo apareça em vez de se perder no meio dos de
   sempre.

   ✅ **Feito em 28/10** (ver Bugs 3).
8. **Arquivos muito grandes**:
   - `background_view.gd` tem 3683 linhas, `background.gd` 2899 e `background_props.gd` 1979;
   - a vista poderia ser dividida por assunto (céu e amanhecer, prédios, rua e gente), seguindo a mesma ideia das
     camadas por herança.
9. **Versão no save** (Bugs 5), antes da primeira versão pública.
