# Project Switchboard (Godot 4.6)

Abra a pasta no Godot 4.6 (Importar → `project.godot`) e aperte F5.

## Estrutura

- `scenes/main.tscn` — cena principal (layout em containers); `scenes/ui/` — telefone, rádio, abas de ferramentas
  (lista telefônica, mapa e despacho, caderno), tela inicial e final. Edite a interface no editor do Godot.
- `themes/main_theme.tres` — tema global (cores, fontes e variações de botão/painel/rótulo).
- `data/content.tres` — **todo o conteúdo**: lista telefônica (nomes como se fala, "Rosa Lima", "Corpo de
  Bombeiros"; a lista se ordena sozinha), ruas, falas avulsas, pedidos de informação e as
  listas de roteiros. Cada roteiro de ligação é um arquivo em `data/calls/` (transferências, emergências, trotes).
  Para criar uma ligação nova: duplique um `.tres` em `data/calls/`, edite no inspetor e arraste para a lista certa
  no `content.tres`.
- `data/nights/` — **uma noite por arquivo** (ordem em `nights` no `content.tres`): dia da semana, bilhete da tela
  inicial, clima, agenda, ligações do roteiro (`story`: um roteiro de `data/calls/` num horário fixo) e o que se diz
  na ligação desconhecida (`mystery`, passos como os dos trotes). Para criar uma noite: duplique um `.tres`, edite no
  inspetor e acrescente na lista `nights`. O progresso fica salvo em `user://progress.cfg`.
- **Escolhas que mudam as noites seguintes (marcadores)**: um marcador é um nome (ex.: `respondeu_a_luz`).
  - Num passo de operador (`OPERATOR`), `sets` diz o que cada opção faz, na ordem de `options`: `"nome"` liga,
    `"!nome"` desliga, vazio não faz nada.
  - Qualquer passo e qualquer ligação do roteiro (`story`) tem `requires`: só acontece se todos os nomes estiverem
    ligados (com `!` na frente, desligados). A ligação do roteiro confere na hora de tocar, então uma escolha às
    19:00 já vale para uma ligação das 21:00.
  - O jogo liga sozinho `ligou_de_volta_N` (tentou ligar de volta para a ligação desconhecida da noite N) e
    `desligou_desconhecida_N` (desligou na cara dela).
  - Para testar um ramo: `godot --path . -- --night=2 --flags=respondeu_a_luz`.
- `data/templates/` — **moldes**: roteiros com lacunas em inglês, preenchidas na hora (veja abaixo).
- `scripts/main.gd` — conduz o turno (relógio, quando cada ligação toca, mesa, fim de ligação, final).
- `scripts/schedule.gd` — monta a agenda da noite (quem liga e quando).
- `scripts/supervisor.gd` — consequências: advertências, quem liga de novo, quem desiste de esperar.
- `scripts/conversation.gd` — como cada tipo de ligação se desenrola (falas, escolhas do operador).
- `scripts/model/` — `PhoneCall` (uma ligação) e `Exchange` (estado das linhas e destinos).
- `scripts/data/` — classes dos Resources de conteúdo.
- `scripts/ui/` — scripts das cenas e dos elementos desenhados (mesa comutadora, mapa, lista, fundo).
- `scripts/sfx.gd` — autoload `Sfx`: todos os sons, sintetizados ao iniciar, nos barramentos Ambience, Voices e
  Effects (`default_bus_layout.tres`). Troque as entradas de `streams` por arquivos reais quando tiver áudio gravado.
- `tests/` — testes automatizados (`tests/run.sh`).
- `fonts/` — Pixelify Sans e VT323 (SIL Open Font License).

## Consequências e relatório do supervisor

À meia-noite, antes da tela final, o supervisor confere o turno (`ShiftReport` em `scripts/model/shift_report.gd`,
tela em `scenes/ui/report_view.tscn`): lista as advertências (leve, média, grave, gravíssima), traz o **jornal da manhã** com o
desfecho de cada emergência e dá um parecer (`verdicts` no content). A ligação do tutorial, os trotes e a
ligação desconhecida não contam.

| Falha | Gravidade | O que acontece no turno |
|---|---|---|
| Não atender (transferência, emergência, informação) | média | a pessoa liga de novo 15–30 min depois, reclamando e com menos paciência |
| Deixar em espera mais de `HOLD_GIVE_UP` (120 min de jogo) | média | a pessoa desliga e liga de novo depois |
| Conectar o número errado | média | com o FONE na linha: quem atende reclama e o solicitante pede o certo (na segunda vez, desiste); com o FONE fora: foi engano, os dois desligam e o solicitante liga de novo pedindo o número certo |
| Cortar uma conversa em andamento | média | — |
| Dar a informação errada | leve | a pessoa liga de novo reclamando |
| Registrar com o tipo errado / deixar sem registro no fim do turno | leve | — |
| Despachar no endereço errado | grave | o rádio avisa que não há nada no local e as unidades voltam; a pessoa agradece, mas liga de novo dizendo que piorou |
| Encerrar uma emergência sem despachar | grave | a pessoa liga de novo dizendo que piorou |
| Despachar com a situação agravando (2º estágio da barra) | média | — |
| Despachar com a situação agravada (3º estágio) | grave | no jornal: "com atraso" |
| Deixar a barra acabar (situação perdida) | gravíssima | a pessoa reclama; ainda dá para despachar, mas no jornal sai "ninguém foi atender" |
| Faltar unidade no despacho | média | o rádio pede a unidade que falta |
| Enviar unidades sem emergência | média | — |
| Enviar unidade a mais (no local certo) | leve | o rádio diz que ela não era necessária, e ela volta logo |
| Marcar o tipo de ocorrência errado no despacho | leve | — (Enviar só acende com local, tipo e unidade) |

Quem liga de novo espera a mesa esvaziar (no máximo `RETRY_WAIT`, 20 min de jogo), para não empilhar ligações
sobre quem já está sobrecarregado. Quando a emergência liga de novo, em `REDISPATCH_CHANCE` (60%) dos casos ainda dá para despachar (no jornal: "com
atraso"); nos outros, já é tarde (no jornal: "ninguém foi atender"). Cada pessoa liga de novo no máximo uma vez por motivo, sempre antes do fim do turno (vale também para a
ligação do tutorial, que só não gera advertência).
As advertências graves se somam entre as noites: `ShiftReport.SEVERE_LIMIT` (3) graves acumuladas é demissão, e o
jogo volta para a primeira noite. Uma gravíssima conta como `CRITICAL_WEIGHT` (2) graves.

### Barra de agravamento da emergência

Na base da caixa da conversa, durante uma emergência, uma barra mostra a situação no local piorando: **inicial**
(verde), **agravando** (âmbar), **agravada** (vermelho); quando acaba, a situação está **perdida** e a barra some.
Ela corre desde que o operador atende e **para enquanto o operador pergunta e a pessoa responde** (e na pausa do
jogo). Só para de vez quando **o socorro completo sai para o lugar certo**: despacho incompleto ou no endereço
errado não para (chutar uma unidade e completar depois não adianta), nem a pessoa ter desligado; aí quem avisa que
piorou é o rádio. A barra só aparece com o operador na linha da emergência; fora dela, **o rádio inteiro acende**: moldura pulsando
na cor do estágio (mais rápido quanto pior) e, na tela, "OCORRÊNCIA EM ANDAMENTO · Linha 09 em espera · Situação
agravando" (ou o endereço, se a pessoa já desligou) entre uma mensagem e outra. A luz **Ocorrência** do rádio fica
acesa enquanto a barra corre (pisca ao mudar de estágio e no vermelho). A cada troca de estágio o rádio dá um chiado
curto e dois bipes (mais agudos quanto pior), para quem está olhando o mapa ou outra ligação. A reclamação genérica
de demora ("Vão mandar alguém?") só vem no estágio inicial; depois, a fala de cada estágio já cobra. Vale uma advertência por emergência, pelo estágio em
que o socorro completo saiu (veja a tabela); a perdida pune na hora. Uma emergência nova espera a anterior.

A cada estágio a pessoa conta o que mudou (`worsening`, `critical`, `lost` no `EmergencyCall`), e isso pode exigir
unidades novas (`worsening_units`, `critical_units`, somadas às do caso): a fumaça fechou a rua → polícia; um vizinho
desmaiou na fumaça → ambulância. A unidade nova só passa a contar **depois que alguém conta o que mudou**: a pessoa,
quando o operador volta à linha, ou o rádio, se ela já desligou ("Central, a situação está piorando na Rua do Moinho,
40. Mandem ambulância."). Ninguém é cobrado pelo que não tinha como saber. Vale o que era preciso no momento do
despacho. Depois de contar, a pessoa pode
ser perguntada sobre o que mudou (`worsening_question`/`critical_question` e as respostas). Na situação perdida,
as perguntas que sobraram saem (menos o endereço) e fica "Tem alguém ferido?": `lost_answer` diz o estado agora e
`lost_units` o que isso passa a exigir (quase sempre ambulância). A duração de cada estágio é
`stage_sec` (segundos reais): 45/22/22 nas ocorrências mais lentas, 40/20/20 nas médias e 35/18/18 em fogo e AVC.
O robô em ritmo humano (5 s por ação, lendo cada resposta até o fim, 15 s no protocolo e no mapa) despacha com
~40 s de barra corrida: a tempo nas lentas e médias, já agravando em fogo e AVC.

## Moldes (conversas geradas)

Metade das transferências e das emergências do turno (`TEMPLATE_CHANCE` em `schedule.gd`) vem de um molde; a outra metade,
dos roteiros escritos em `data/calls/`. Os trotes, o tutorial, as ligações do roteiro da noite e a ligação
desconhecida são sempre escritos à mão.

- **Transferência** (`transfer_templates`): o molde é um `TransferCall` com lacunas em `opening` e `repeat`.
  O contato é sorteado entre os que têm `spoken` e `reasons` na lista e atendem à noite; quem liga sai de `callers`.
  Lacunas: `{place}` "o Hotel Estrela", `{of_place}` "do Hotel Estrela", `{to_place}` "pro Hotel Estrela",
  `{street}` rua do contato, `{number}` "305", `{digits}` "três, zero, cinco", `{reason}` um dos motivos do contato.
- **Emergência** (`emergency_templates`): o molde é um `EmergencyCall`; valem ocorrência, unidades e as falas.
  `cases` (`EmergencyCase`, também nos roteiros escritos, que quase todos têm) são variações sorteadas: cada caso troca algumas
  respostas ("" mantém a do roteiro) e diz as unidades dele. Assim o mesmo incêndio pede só bombeiros ou também
  ambulância, e o jogador precisa perguntar.
  Rua e número são sorteados; o trecho do mapa sai do número. Lacunas: `{street}`, `{house}`, `{address}`.
- **Para ter mais variedade:** acrescente motivos (`reasons`) aos contatos, ou um `spoken` + motivos a um contato
  novo. Um molde novo vale para todos os contatos. Escreva motivos que sirvam para quem liga, homem ou mulher.
- A primeira letra de cada fala vira maiúscula depois de preenchida (`GameData.fill`).

## Testes

`tests/run.sh` reimporta o projeto e roda, em modo headless, os cenários dirigidos (`test_flow.gd`), as consequências
(`test_penalties.gd`) e três turnos completos jogados
por um robô (`test_shift.gd`, com `--seed=1..3`), mais um turno com o robô "desastrado" (`--clumsy`, deixa de
atender 1 em cada 3 ligações), que mede a bola de neve dos retornos. Para jogar uma agenda específica: `godot --path . -- --seed=123`; uma noite específica (sem mexer no progresso
salvo): `-- --night=2`.

## Tradução

Três idiomas: português (padrão), inglês e espanhol. O jogador escolhe em **Configurações** (no menu de pausa, com
Esc, ou na tela inicial), junto com o volume de ambiente, vozes e efeitos e a velocidade do texto; tudo fica salvo em
`user://settings.cfg`. Para testar um idioma: `godot --path . -- --lang=en` (ou `es`).

- **Interface** (botões, dicas, rádio, relatório, falas fixas do operador): planilha `translations/ui.csv`, uma linha
  por texto: `chave,pt_BR,en,es`. No código, cada chave é um ENUM: `T.text(T.Key.START_SHIFT)`. Nas cenas, o texto
  do Label/Button é a própria chave (ex.: `START_SHIFT`), e o Godot troca pelo idioma atual (no editor aparece a chave).
- **Falas dos roteiros** (`data/`): continuam escritas em português no inspetor; as traduções ficam em
  `translations/content.en.po` e `content.es.po` (o português é a chave). Nomes de pessoas, ruas e estabelecimentos
  não se traduzem (a tradução repete o original).
- **Depois de mexer em textos**, rode `godot --headless --path . -s tools/update_translations.gd`. Ela gera o ENUM a
  partir da planilha e atualiza os `.po` com as falas novas (vazias, mostram o português até serem traduzidas) sem
  perder o que já foi traduzido. O teste de fluxo avisa quantas falas faltam e falha se uma tradução perder uma
  lacuna (`%s`, `{place}`...).

## Ritmo do turno

O relógio nunca para: 0,75 minuto de jogo por segundo real (18:00 → 00:00 em cerca de 8 minutos).
Ajuste em `main.gd` → `GAME_MIN_PER_SEC`.

- **Nada é fixo, exceto o roteiro da noite** (`story` e `mystery` em `data/nights/`). O resto é sorteado (`Schedule._random_calls`):
  entre uma ligação e a próxima passam `call_gap` minutos de jogo (o máximo é o maior silêncio possível). Em
  `peak_chance` dos intervalos a próxima vem logo em seguida (2–6 min) e duas linhas tocam juntas; com `max_live`
  ligações pedindo atenção (tocando ou ainda não conectadas), a próxima espera. **A primeira noite é calma e o ritmo
  sobe aos poucos**: noite 1 com 45–60 min, 1 emergência, 0–1 trote, sem picos e no máximo 2 (7–9 ligações); noite 2
  com 34–46 min e 1–2 emergências (10–12). Os padrões do `Night` (28–42, 5%, 3) são o ritmo das noites mais cheias.
  Ajuste medindo com o robô em ritmo humano: `tests/test_shift.gd -- --human`.
- **Tipo sorteado**: `emergencies` emergências (1–2, a pelo menos `EMERGENCY_GAP` = 60 min uma da outra, porque o
  despacho cuida de uma por vez), `pranks` trotes (0–2) e o resto transferências (65%) ou pedidos de informação
  (o número de alguém na lista). Um destino não se repete na mesma noite. Na primeira noite, a primeira
  ligação é uma transferência guiada (tutorial).
- **Ligação desconhecida**: toca por uma entrada livre qualquer, num horário sorteado entre `mystery_from` e
  `mystery_to` da noite (22:00–23:30).
- As ligações tocam no horário mesmo com o operador ocupado; uma emergência espera a anterior desligar e as unidades
  chegarem. Quem ninguém atende desiste (`GIVE_UP_SEC`: 60 s; as do roteiro aguentam 90 s, os retornos 45 s; a do
  tutorial e a desconhecida não desistem).
- A ligação desconhecida espera a mesa ficar em silêncio, por no máximo 30 minutos de jogo.
- Alguns números não atendem à noite (`closed_at_night` no contato). Roteiros com `alt_target` deixam o operador
  sugerir outro lugar.
- Conexões completadas duram 34–68 minutos de jogo, cerca de 45–90 s reais (`TALK_LEN` em `main.gd`); depois as lâmpadas ficam vermelhas
  até o operador desmontar. Conversas mais longas prendem os cabos de conexão por mais tempo: em turnos
  movimentados, às vezes é preciso esperar uma conversa acabar (ou cortá-la) para ter um cabo livre.
- O caderno guarda as ocorrências numa fila: dá para registrar depois, sem travar o turno. A aba mostra quantas
  faltam; registrar é um clique no tipo (ligação comum, emergência ou trote), o resto o caderno já anotou.
- O turno termina à meia-noite (depois de a ligação desconhecida ter tocado e caído) e vem a tela final.

## Clima e sons

Cada turno sorteia o clima (`WEATHERS` em `main.gd`; para forçar: `godot --path . -- --weather=fog`):

| Clima | Som | Janela | Conversa fiada |
|---|---|---|---|
| `rain` | chuva | gotas no vidro | assuntos sem clima + `weather = rain` |
| `fog` | grilos | névoa passando, luzes difusas | assuntos sem clima + `weather = fog` |
| `clear` | brisa leve e grilos | estrelas e lua | assuntos sem clima + `weather = clear` |

A conversa fiada aparece quando o operador demora para transferir: depois de uns 10 s em silêncio, às vezes a pessoa
puxa assunto; se a demora continuar, ela reclama (`waiting`). Cada assunto é um `ChatTopic` na lista `smalltalk` do
content: a fala (`line`), o clima em que faz sentido (`weather`, vazio = qualquer), se ela só serve quando a pessoa puxa conversa sozinha (`unprompted_only`: não cabe como resposta a "E aí, como vai
a noite?", como "Desculpe ligar tão tarde."), as vozes que podem dizê-la
(`voices`, vazio = qualquer; use quando a fala tem gênero, como "Meu marido..." → `f`), os marcadores que
precisam bater (`requires`) e as respostas do operador (`replies`, cada uma um `ChatReply`): o texto (`text`), como a pessoa
continua (`follow`), o tom (`tone`) e os marcadores que ela altera (`sets`). O operador pode responder (as respostas
aparecem como opções e ele escolhe uma) para ganhar tempo, e também puxar conversa ("E aí, como vai a noite?": a pessoa responde primeiro com uma das falas de `chat_bridge`,
como "Vai indo, moço.", e depois puxa o assunto); escreva
respostas que caibam naquele assunto. Todo assunto tem uma resposta **simpática** (`WARM`: a pessoa espera mais antes de
reclamar e pode puxar outro assunto) e uma **seca** (`CURT`: ela entende o recado e para de puxar conversa).
As novidades de uma noite ficam em `smalltalk` no arquivo da noite (`data/nights/`) e vêm antes dos assuntos gerais,
uma vez por noite; o mesmo vale para assuntos com `requires`. Exemplo: na noite 1, prometer ir à quermesse liga
`prometeu_quermesse`, e na noite 2 alguém cobra a visita (sem a promessa, outra pessoa só conta como foi). Escreva só assuntos do cotidiano da cidade; o que lembra
o mistério (luzes, barulhos na linha, vultos) fica para as falas do roteiro.

Volumes de cada
clima em `Sfx.WEATHER_MIX`. 15 minutos antes da ligação desconhecida (`SHADOW_LEAD`) aparece a silhueta de alguém
do lado de fora da janela; 10 minutos antes (`SHADOW_LEAVE`) ela sai, e então a ligação toca. Antes da ligação desconhecida a noite se cala (grilos param, chuva e brisa
baixam) e volta aos poucos depois.

Todos os sons são sintetizados em `sfx.gd`: a campainha ("trrrim-trrrim" de martelinho em duas campânulas), o
"tuuuu" de chamando (425 Hz, com o corte de frequências da linha) e os sons de ambiente (com o abafamento da distância).

## Vozes

Cada grupo de vogais do texto dispara uma sílaba sintetizada (pulso glotal + formantes da vogal + filtro abafado).
Timbres por personagem em `Sfx.VOICE`: `f0` (altura), `breath` (sopro), `muffle` (quanto menor, mais abafado).

## Controles

Arraste o plug até a tomada (clicar e segurar; um clique só não pega o plug). O cursor mostra o que dá para fazer:
mão aberta sobre um plug que pode ser pego (que também ganha um contorno claro), mão fechada segurando, proibido
sobre uma tomada que não aceita aquele plug, dedo no que se clica. **Clicar num plug encaixado**
solta o plug: ele cai e o fio o puxa de volta para o buraco de onde sai (solto acima do buraco, a qualquer altura, vai direto para ele). Solto em movimento, sai com o embalo da
mão; dá para pegá-lo de volta no ar (`FALL_SEC`, `PULL_SPEED` em
`scripts/ui/switchboard.gd`). O fio do FONE sai do encaixe no telefone; cada cabo de conexão tem dois buracos na
base, um por ponta, e cada clique devolve uma ponta.
Arrastar um plug encaixado para outra tomada o move. Soltar fora de uma tomada, apertar Esc ou o botão direito (ação `cancel_plug` no Input Map)
também devolve o plug à base. Cada tipo de plug só encaixa nas tomadas compatíveis: a tomada sob o plug
acende em amarelo se aceita, em vermelho se não.

Atalhos do telefone: **Espaço** atende, **Tab** transfere, **X** desliga (a tecla aparece no canto de cada botão).
Com um campo de texto em foco, as teclas vão para o campo. **1**, **2** e **3** abrem a lista, o despacho e o caderno.

**F1** abre o painel de debug (só rodando pelo editor ou num export de debug; não existe no jogo final):

| Seção | O que faz | Limpar |
|---|---|---|
| Ligações e mesa | toca transferência (roteiro ou molde), informação, trote, ligação desconhecida e qualquer emergência (escritas e moldes, com o caso sorteado) | encerra todas as ligações, zera a mesa (cabos na base) e tira os retornos da agenda |
| Barra de agravamento | mostra estágio, tempo e as unidades exigidas (o que já foi contado e o real); pula para o próximo estágio; encerra a emergência; congela a barra | descongela e encerra a emergência |
| Tempo | velocidade 1×, 2×, 4×, 8×; +30 min; ir para 23:50; encerrar o turno (relatório e final) | volta a 1× |
| Viaturas e caderno | viaturas livres na hora (as que estavam a caminho não chegam mais); registra as pendências com o tipo certo; limpa as advertências; apaga o progresso salvo | viaturas livres, caderno em branco, relatório zerado |

**Restaurar tudo**, no topo, faz todas as limpezas (o relógio fica onde está). Limpar nunca gera advertência nem retorno.

Para começar num ponto específico, combine com as opções de linha de comando: `-- --night=2`, `--seed=123`,
`--weather=fog`, `--flags=a,b`, `--lang=en`.

## A mesa

- **Entradas (01–10):** onde as chamadas chegam. A lâmpada pisca e o telefone toca.
- **Saídas:** uma tomada logo abaixo de cada entrada, para o cabo de conexão.
- **Destinos:** um plug por número da lista (menos polícia, bombeiros e hospital, que vão pelo despacho).
- **FONE** (cabo verde): sai do encaixe no canto do telefone e só entra nas entradas.
  A ligação da entrada onde o FONE está é a que aparece no telefone.
- **Cabos de conexão** (vermelho, azul e amarelo, `CORD_COLORS`): `PATCHES = 3` em `scripts/ui/switchboard.gd`, independentes, com um plug em cada ponta:
  uma ponta na SAÍDA da linha, a outra no destino.

Transferência: FONE na entrada que pisca → **Atender** → o solicitante pede → cabo de conexão da SAÍDA da linha
até o número de destino → **Transferir** → destino atende → tirar o FONE da entrada (a ligação segue pelo cabo de
conexão) → quando desligarem (lâmpadas vermelhas), tirar as duas pontas do cabo de conexão.
Se o FONE sair antes do destino atender, o solicitante fica em espera; quando o destino atende, a ligação se completa sozinha.
Tirar uma ponta do cabo de conexão corta a conversa. Emergências, trotes e pedidos de informação usam só o FONE;
o botão **Desligar** encerra a ligação, e a linha fica "desligou" até o FONE sair dela.

**Várias ligações:** levar o FONE para outra entrada que está chamando deixa a ligação anterior em espera
(a pessoa para de falar até você voltar). Para voltar, leve o FONE de volta à entrada dela.
"Outras linhas" no telefone lista quem está tocando ou em espera.

Depois da ligação desconhecida, FONE na entrada por onde ela veio tenta ligar de volta.

**Emergência:** na aba **Mapa e despacho**, clique no trecho da rua (passar o mouse mostra a faixa de números, ex.:
"Rua do Sol, 1–99"), escolha o tipo, marque as unidades e **Enviar**, que só acende com local, tipo e unidade marcados. O tipo
não marca unidades: **quem decide é a conversa**, pelo protocolo (cartão na aba):

| Unidade | Quando |
|---|---|
| Polícia | crime, briga, arma, rua bloqueada |
| Bombeiros | fogo, fumaça, fio elétrico ou gás, alguém preso (ferragens, escombros) |
| Ambulância | alguém ferido, passando mal ou preso (batida leve sem feridos, não) |

Incêndio sem vítima é só bombeiro; com alguém queimado, bombeiros e ambulância; batida com gente presa nas ferragens
e a rua fechada, os três; o vigilante preso no galpão em chamas, bombeiros e ambulância. Ao escrever uma emergência, as respostas precisam revelar cada unidade sem ambiguidade
("acho que não" não serve). Unidade a mais é advertência leve; a que falta, o rádio pede. Depois do envio o despacho fica limpo
para a próxima.

## Cabos

Os cabos são cordas simuladas (Verlet) em `scripts/ui/switchboard.gd`: balançam ao arrastar o plug e
ao passar o mouse por cima. Ajuste `SLACK` (folga), `DAMPING` (quanto demora para parar),
`GRAVITY` e `STIFF_ITER` (rigidez) no topo do arquivo.

## Ligação desconhecida

Toca por uma entrada livre sorteada, como qualquer outra (lâmpada piscando, cabo + Atender).
Quando cai, a linha volta a ficar livre e a ocorrência vai para o caderno; clicar nessa linha
mostra o registro da última chamada.
