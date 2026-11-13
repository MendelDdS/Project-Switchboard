# Project Switchboard (Godot 4.6)

Abra a pasta no Godot 4.6 (Importar → `project.godot`) e aperte F5.

## Estrutura

- `scenes/main.tscn` — cena principal (layout em containers); `scenes/ui/` — telefone, rádio, abas de ferramentas
  (lista telefônica, mapa e despacho, ficha de ocorrências), tela inicial e final. Edite a interface no editor do Godot.
- `themes/main_theme.tres` — tema global (cores, fontes e variações de botão/painel/rótulo).
- `data/content.tres` — **todo o conteúdo**: ruas, falas avulsas, pedidos de informação e as listas de roteiros
  e de contatos.
- `data/directory/` — **um contato da lista telefônica por arquivo** (`<número>_<nome>.tres`; nomes como se fala,
  "Rosa Lima", "Corpo de Bombeiros"; a lista se ordena sozinha), com os motivos de quem liga para ele e as conversas
  que se ouvem na escuta. Contato novo: duplique um arquivo e arraste para `directory` no `content.tres`. Cada roteiro de ligação é um arquivo em `data/calls/` (transferências, emergências, trotes).
  Para criar uma ligação nova: duplique um `.tres` em `data/calls/`, edite no inspetor e arraste para a lista certa
  no `content.tres`.
- `data/nights/` — **uma noite por arquivo** (ordem em `nights` no `content.tres`): dia da semana, bilhete da tela
  inicial, clima, agenda, ligações do roteiro (`story`: um roteiro de `data/calls/` num horário fixo). Para criar uma noite: duplique um `.tres`, edite no
  inspetor e acrescente na lista `nights`. O progresso fica salvo em `user://progress.cfg`, com a versão
  do formato (`Progress.VERSION`): mudou o tipo ou o sentido de um campo, suba a versão e converta o save antigo no
  `load_saved`. Um save de versão mais nova ou corrompido fica guardado ao lado (`progress.v2-<hora>.cfg`,
  `progress.corrompido-<hora>.cfg`), a tela inicial avisa e o jogo começa do zero.
- **Escolhas que mudam as noites seguintes (marcadores)**: um marcador é um nome (ex.: `prometeu_quermesse`).
  - Num passo de operador (`OPERATOR`), `sets` diz o que cada opção faz, na ordem de `options`: `"nome"` liga,
    `"!nome"` desliga, vazio não faz nada.
  - Qualquer passo e qualquer ligação do roteiro (`story`) tem `requires`: só acontece se todos os nomes estiverem
    ligados (com `!` na frente, desligados). A ligação do roteiro confere na hora de tocar, então uma escolha às
    19:00 já vale para uma ligação das 21:00.
  - O jogo liga sozinho `sinalizador_N` (o sinalizador da rua acendeu no céu, a
    noite 15 às 21h) e `ligou_<número>_N` (o operador ligou pelo discador e o lugar atendeu).
  - Para testar um ramo: `godot --path . -- --night=2 --flags=prometeu_quermesse`.
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
- `fonts/` — Departure Mono (SIL Open Font License, `OFL-DepartureMono.txt`).

## Consequências e relatório do supervisor

À meia-noite, antes da tela final, o supervisor confere o turno (`ShiftReport` em `scripts/model/shift_report.gd`,
tela em `scenes/ui/report_view.tscn`): conta os serviços prestados (ligações completadas, informações, emergências
atendidas...), lista as advertências (leve, média, grave, gravíssima) e dá um **conceito** carimbado (Ótimo, Bom,
Regular, Insuficiente) com o parecer à mão (`verdicts` no content, um por conceito). O jornal da manhã, com o desfecho
de cada emergência, vem na mesa na noite seguinte. As ligações do treinamento e os trotes não contam.

| Falha | Gravidade | O que acontece no turno |
|---|---|---|
| Não atender (transferência, emergência, informação) | média | a pessoa liga de novo 15–30 min depois, reclamando e com menos paciência |
| Deixar em espera mais de `HOLD_GIVE_UP` (120 min de jogo) | média | a pessoa desliga e liga de novo depois |
| Conectar o número errado | média | com o FONE na linha: quem atende reclama e o solicitante pede o certo (na segunda vez, desiste); com o FONE fora: foi engano, os dois desligam e o solicitante liga de novo pedindo o número certo |
| Cortar uma conversa em andamento | média | — |
| Encerrar o turno com alguém na linha ou tocando | média | — (emergência sem despacho conta como emergência sem despacho) |
| Dar a informação errada | leve | a pessoa liga de novo reclamando |
| Registrar com o tipo errado / deixar sem registro no fim do turno | leve | — |
| Guardar o bilhete de tarifação do interurbano na caixinha sem o carimbo | leve | — |
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
atraso"); nos outros, já é tarde (no jornal: "ninguém foi atender"). Cada pessoa liga de novo no máximo uma vez por motivo, sempre antes do fim do turno (vale também para as
ligações do treinamento, que só não geram advertência).
### O conceito do turno e a demissão

Por trás do conceito há uma conta que o jogador não vê (só o painel de debug mostra): a **eficiência**, a parte certa
de tudo o que o supervisor anotou, `acertos ÷ (acertos + advertências)`, em pontos (`ShiftReport.CREDITS` e `POINTS`).
Só as decisões dão ponto: transferência completada (10), interurbano (12), informação certa (5), emergência socorrida
no estágio inicial (20) ou agravando (10; na crítica, nada), tipo de ocorrência certo (3), trote reconhecido (5).
Registrar a ficha e guardar o bilhete não: já têm a advertência quando faltam. Cada advertência tira 3 (leve), 15
(média), 30 (grave) ou 60 (gravíssima): a média pesa mais que um acerto, porque a não atendida liga de novo e o
crédito do retorno a apagaria.

O supervisor fica mais rigoroso a cada noite (`ShiftReport.RIGOR`): as advertências pesam 0,6 do valor na noite 1,
o valor cheio na 9 e 1,3 na 15, em linha reta. Nas primeiras noites ele releva quem ainda está aprendendo. A
emergência perdida é Insuficiente em qualquer noite.

| Conceito | Eficiência |
|---|---|
| Ótimo | 90% ou mais |
| Bom | 75% a 89% |
| Regular (o mínimo) | 60% a 74% |
| Insuficiente | abaixo de 60%, ou qualquer emergência perdida |

**Duas noites seguidas em Insuficiente é demissão** (`ShiftReport.LOW_LIMIT`; uma Regular ou melhor zera a conta), e
o jogo volta para o treinamento. Depois de uma Insuficiente, o bilhete da noite seguinte lembra que ela decide. A
denúncia da escuta conta na noite em que chega ao relatório. O treinamento não tem conceito. Calibrado com o robô
do `test_shift`, cinco sementes em cinco noites: o atento fica entre 67% e 100% e o que deixa tocar 1 em 3, entre 47%
e 77%.

### Os broches

Recompensas que o operador ganha pelas noites, espetadas numa almofada de feltro na prateleira da mesa comutadora (à
direita do tampo dos equipamentos). Sob o mouse, o broche mostra o nome; o clique abre um papel com a descrição e a
noite em que veio. Ficam no save (`Progress.badges` e as contas em `tally`) e somem com ele, na demissão e depois da
última noite. Conferidos no fim de cada noite (`scripts/model/badges.gd`, `award`); o treinamento não conta.

| Broche | Como se ganha |
|---|---|
| Noites primorosas | 3 noites sem nenhuma advertência (não precisam ser seguidas) |
| Anjo da guarda | 10 emergências socorridas no estágio inicial |
| Linha direta | 5 noites seguidas sem deixar ninguém tocando até desistir |
| Longa distância | 15 interurbanos completados |
| Faro de trote | 5 trotes reconhecidos |
| Contas em dia | uma noite com interurbano, sem bilhete esquecido ou sem carimbo e sem ficha errada ou faltando |
| Hora do rush | Bom ou melhor no ritmo mais alto (o último nível) |
| Veterano | a noite 10 trabalhada |

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
`stage_sec` (segundos reais): 55/22/22 nas ocorrências mais lentas, 50/20/20 nas médias e 45/18/18 em fogo e AVC. A barra para durante pergunta e resposta e enquanto uma máquina do despacho trabalha (imprimindo, transmitindo ou triturando).
O robô em ritmo humano (5 s por ação, lendo cada resposta até o fim, 15 s no protocolo e no mapa) despacha com
~40 s de barra corrida: a tempo nas lentas e médias, já agravando em fogo e AVC.

## O discador (ligações que o operador faz)

O operador liga pelo discador da prateleira (clicado, ele abre de perto): digita o número, Discar, e o lugar atende
(Discar com o visor vazio liga de novo para o último). Quem estava com o FONE fica em espera enquanto isso.
- **O atendimento de cada lugar** fica no contato dele em `data/directory/` (`answers`): cada um é um assunto de
  conversa fiada (`ChatTopic`), com a fala de atendimento (`line`) e as perguntas do operador (`replies`: `text` a
  pergunta, `follow` a resposta, `sets` os marcadores). Pode ter `requires` (só depois de um marcador), `weather` e as noites em que vale (`from_night`, `to_night`).
  Sorteia um entre os que valem, e o da ocasião (com marcador ou noite) vem no lugar dos de todo dia; o operador vê até duas perguntas e [Encerrar ligação]. `bye` é a despedida (vazio:
  uma de `dial_byes`, no `content.tres`). Sem atendimento, ninguém atende. Todo número da cidade atende, menos os do despacho (o `test_content` cobra).
  `closes`: a hora em que o lugar fecha (minutos depois das 18h) e ninguém mais atende. As respostas podem ter
  palavras-chave (`[person:Benedito Souza]`, como na escuta), que vão para as anotações da lista.
- **Ligação do roteiro**: um `.tres` com o script `scripts/data/dial_call.gd` (`DialCall`) em `Night.dial` (só naquela
  noite) ou `GameContent.dial` (qualquer uma): o número (pode nem estar na lista), `requires`, o horário (`from`/`to`),
  quem atende e os passos (`PrankStep`, como os trotes). Feita até o fim, liga `sets` e, com `once`, o marcador
  `discou_<nome do arquivo>`. Para o lugar ligar de volta: uma `StoryCall` com `requires = ["ligou_<número>_N"]`.
- No F1, o campo "Número para discar".

## Moldes (conversas geradas)

Metade das transferências e das emergências do turno (`TEMPLATE_CHANCE` em `schedule.gd`) vem de um molde; a outra metade,
dos roteiros escritos em `data/calls/`. Os trotes, o treinamento, e as ligações do roteiro da noite são sempre
escritos à mão.

- **Transferência** (`transfer_templates`): o molde é um `TransferCall` com lacunas em `opening` e `repeat`.
  O contato é sorteado entre os que têm `spoken` e `motives` na lista e atendem à noite; quem liga sai de `callers`.
  Lacunas: `{place}` "o Hotel Estrela", `{of_place}` "do Hotel Estrela", `{to_place}` "pro Hotel Estrela",
  `{street}` rua do contato, `{number}` "305", `{digits}` "três, zero, cinco", `{reason}` um dos motivos do contato.
- **Interurbano** (`trunk_templates`): um `TransferCall` com lacunas em `opening` e `repeat`, para um tronco sorteado
  (a tomada da cidade no banco INTERURBANO). Lacunas: `{to_city}` "pra Capital" (uma por tronco em `trunk_to`, na ordem
  das tomadas) e `{far}` o número na outra cidade, que o operador passa à telefonista de lá (`trunk_hello`,
  `trunk_wait`, `trunk_unknown`).
- **Emergência** (`emergency_templates`): o molde é um `EmergencyCall`; valem ocorrência, unidades e as falas.
  `cases` (`EmergencyCase`, também nos roteiros escritos, que quase todos têm) são variações sorteadas: cada caso troca algumas
  respostas ("" mantém a do roteiro) e diz as unidades dele. Assim o mesmo incêndio pede só bombeiros ou também
  ambulância, e o jogador precisa perguntar.
  Rua e número são sorteados; o trecho do mapa sai do número. Lacunas: `{street}`, `{house}`, `{address}`.
- **Para ter mais variedade:** acrescente motivos (`motives`) aos contatos, ou um `spoken` + motivos a um contato
  novo. Um molde novo vale para todos os contatos. Escreva motivos que sirvam para quem liga, homem ou mulher.
- **Cada motivo (`Motive`) traz as conversas que vêm depois** (`talks`, duas ou mais; uma é sorteada por ligação), o
  que o operador ouve se escutar a linha: quem
  pede remédio fala de remédio com a farmácia, quem pede quarto reserva noites no hotel. O lugar atende primeiro, com a
  fala `hello` do contato ("Hotel Estrela, boa noite."; as pessoas, com um "alô" sorteado de `overheard_hello`), e a
  conversa começa por quem ligou, cumprimentando, e alterna. De 4 a 6 falas, com o que importa no meio. Num lugar com
  ramo (`category`), não diga o tipo do lugar: se ele não atender, quem atende é outro do mesmo ramo. Cada fala com até
  90 letras, também traduzida. Sem `talks`, só se ouve o murmúrio. Depois da última fala, os dois se despedem e
  desligam.
- **Lacunas das conversas** (`talk_fills` no content, cada uma um `TalkFill` com `key` e `values`): `{hour}` (sete a
  onze), `{dawn}` (quatro a seis), `{wait}` (vinte minutos, meia hora...), `{nights}`, `{color}`, `{score}`, `{film}`,
  e `{street}`/`{house}`, uma rua e um número dos setores atendidos. O valor é sorteado uma vez por conversa (o mesmo em
  todas as falas dela), então a hora ou o tempo que se ouve muda de uma ligação para outra. Lacuna nova: um `TalkFill`
  novo; o valor precisa servir em todas as falas que usam a lacuna.
- **Palavras-chave das conversas escutadas:** nas falas escritas, o que o jogador deve pegar escutando (nomes, ruas,
  telefones, horários) vai marcado como `[tipo:texto]`: "Ficou pras [time:oito], na casa do [person:Benedito Souza]."
  Tipos: `person` (pessoa), `street` (rua ou endereço), `place` (lugar), `phone` (telefone), `time` (hora), `date`
  (data), `number` (outro número), `other`. A marca não aparece na tela nem na voz, e pode envolver uma lacuna
  (`[time:{hour}]`). O jogador só pega a palavra se ouvir todas as letras dela: o lápis risca, ela fica sublinhada
  na tela e vai para as anotações da lista telefônica (depois da letra final, seguindo nas páginas seguintes se não
  couberem), uma linha por palavra (ouvida de novo, "×2"). Um clique a marca para repassar, outro a risca (vai para
  o fim) e outro a volta ao normal. **Varie onde a palavra-chave aparece**: às vezes no cumprimento ("Oi, [person:Benedito]!"), às
  vezes no meio, às vezes só na despedida ("Então até as [time:oito]"). Sempre no meio, o jogador aprende uma receita
  (entrar depois do alô, ouvir duas falas, sair); variando, ele decide a hora de entrar: cedo pega mais, mas a suspeita
  sobe mais. Na tradução, mantenha a marca e o tipo e traduza só o texto ("[time:eight]"); nomes próprios ficam iguais.
- **Desconfiança de cada lugar** (`wary` no contato, em `data/directory/`): multiplica a velocidade com que a suspeita
  sobe quando o operador escuta uma conversa com quem atende ali (1 é o normal; a Pensão Dona Cota, 1,6, percebe logo;
  o Bar do Zé, 0,5, quase não nota). Vale junto com a de quem ligou (`wary` do roteiro escrito). O jeito de atender
  (`hello`) dá a pista: seco e desconfiado nos que percebem logo ("Pensão. Quem é que fala?"), solto nos que não
  ligam ("Bar do Zé! Fala aí, meu chapa!"). A suspeita aparece na conversa: quando eles percebem algo (mais cedo nos
  lugares desconfiados), a conversa para e eles se calam uns 3 s (a melhor hora de baixar a chave, e aí a conversa
  segue), um pergunta ao outro (`overheard_ask` no `content.tres`) e, se o operador continuar ouvindo, o outro responde
  e os dois ficam sabendo (`overheard_sure`, na mesma ordem: cada resposta é a da sua pergunta) e denunciam a
  telefonista, solte ele a chave ou não; com ele ainda ouvindo, calados mais uns 3 s, reclamam e desligam. Muito
  desconfiados (1,5 ou mais) não se calam: vão direto à pergunta. No silêncio, o chiado da linha aberta sobe, para
  notar de ouvido, e a tela marca um ponto por segundo. Cada denúncia soma 0,3 à desconfiança do lugar nas noites
  seguintes.
- **A voz de quem atende** é a `voice` do contato (`f`, `m`, `w`, `k`); sem ela, uma tirada do nome, sempre a mesma.
- A primeira letra de cada fala vira maiúscula depois de preenchida (`GameData.fill`).

## Testes

`tests/run.sh` reimporta o projeto e roda, em modo headless, os cenários dirigidos (`test_flow.gd`), as consequências
(`test_penalties.gd`) e três turnos completos jogados
por um robô (`test_shift.gd`, com `--seed=1..3`), mais um turno com o robô "desastrado" (`--clumsy`, deixa de
atender 1 em cada 3 ligações), que mede a bola de neve dos retornos. Para jogar uma agenda específica: `godot --path . -- --seed=123`; uma noite específica (sem mexer no progresso
salvo): `-- --night=2`.

## Tradução

Três idiomas: português (padrão), inglês e espanhol. O jogador escolhe em **Configurações** (no menu de pausa, com
Esc, ou na tela inicial), junto com o volume de ambiente, vozes e efeitos; tudo fica salvo em
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
- **Revisar as traduções numa planilha:** `godot --headless --path . -s tools/update_translations.gd -- --review`
  grava `build/traducoes.csv` (arquivo, pt_BR, en, es; uma fala por linha). Corrija as colunas en e es e devolva com
  `-- --apply=build/traducoes.csv` (o pt_BR não volta: ele se corrige no Resource; célula vazia não apaga nada).

## Ritmo do turno

O relógio nunca para: 0,75 minuto de jogo por segundo real (18:00 → 00:00 em cerca de 8 minutos).
Ajuste em `main.gd` → `GAME_MIN_PER_SEC`.

- **Setores**: a cidade tem três setores (bairros), e o de um número é o primeiro dígito: 1 Centro (praça,
  delegacia, bombeiros, hospital), 2 Alto da Serra (escola, clínica e a zona rural) e 3 Vila Serena (o bairro do
  começo). No mapa, cada setor é uma folha com a mesma grade de ruas e o nome no rodapé; as ruas da Vila Serena continuam,
  com o mesmo nome e a numeração seguindo (300–599), no Centro (a leste) e no Alto da Serra (ao sul); o mapa mostra só os setores
  do operador e, na noite em que um setor é entregue, se abre para ele na primeira vez que aparece. A primeira
  ligação para o banco novo da mesa vem com uma dica de onde ele fica. Roda do
  mouse aproxima, arrastar move. As viaturas saem do Centro e demoram pela distância. O operador começa só com o setor 3
  (10 números na mesa e na lista), recebe o setor 1 (o Centro, +12) na noite 5 e o setor 2 (+12) na noite 10
  (`SECTOR_NIGHTS` em `game_data.gd`). As ligações só pedem números dos setores dele. O jogo tem 15 noites; da 3 em
  diante, por enquanto, são genéricas (só o dia e o bilhete).
- **Nada é fixo, exceto o roteiro da noite** (`story` em `data/nights/`). O resto é sorteado (`Schedule._random_calls`):
  o ritmo vem de um **nível** (`paces` no content, um `Pace` cada), não da noite. Entre uma ligação e a próxima passam
  `call_gap` minutos de jogo (o máximo é o maior silêncio possível); em `peak_chance` dos intervalos a próxima vem logo
  em seguida (2–6 min); com `max_live` ligações pedindo atenção (tocando ou ainda não conectadas), a próxima espera.

  | Nível | Intervalo | Picos | Máx. juntas | Emergências | Trotes |
  |---|---|---|---|---|---|
  | 1 | 40–52 | — | 2 | 1 | 0–1 |
  | 2 | 34–46 | 3% | 2 | 1 | 0–2 |
  | 3 | 32–42 | 3% | 2 | 1–2 | 0–2 |
  | 4 | 30–40 | 4% | 3 | 1–2 | 1–2 |
  | 5 | 28–38 | 5% | 3 | 2 | 1–2 |
  | 6 | 30–40 | 12% | 3 | 2 | 1–2 |
  | 7 | 33–44 | 20% | 3 | 2 | 1–2 |
  | 8 | 37–48 | 28% | 3 | 2 | 1–2 |
  | 9 (limite) | 38–49 | 30% | 3 | 2 | 1–2 |

  A primeira noite usa o nível 1. **Nas 3 primeiras noites, o nível só sobe se a noite anterior não foi Insuficiente**
  (repete o ritmo, para não sobrecarregar quem ainda não pegou confiança).
  Na noite em que um bairro novo é entregue (5 e 9), o nível não sobe, para o operador aprender o bairro antes.
  Da noite 4 em diante sobe sempre, até o nível 9 (noites 11–15). Do 1 ao 5 as ligações vêm cada vez mais seguidas;
  do 6 ao 9 vêm tantas quanto no 5 (`Pace.mean_gap`), só que **mais juntas**: picos mais frequentes, com a mesa mais
  calma entre eles (encurtar o intervalo do 5 fazia o robô em ritmo humano perder ligações toda noite). Para medir um
  nível: `tests/test_shift.gd -- --human --pace=N`.
- **Tipo sorteado**: `emergencies` emergências (a pelo menos `EMERGENCY_GAP` = 60 min uma da outra; atrasos e
  retornos podem juntar duas, nunca mais de duas em andamento), `pranks` trotes e o resto transferências (85%) ou pedidos de informação
  (o número de alguém na lista). Um destino não se repete na mesma noite (o pedido de informação não ocupa o número).
  Com a mesa vazia por muito tempo, toca uma a mais: uma transferência para um número livre (`Schedule.filler`). O treinamento (noite 0) é a Cecília,
  veterana do Alto da Serra, ligando e ensinando o serviço (`data/nights/night_00.tres`, passos `LessonStep`).
- As ligações tocam no horário mesmo com o operador ocupado; uma emergência espera a anterior desligar e as unidades
  chegarem. Quem ninguém atende desiste (`GIVE_UP_SEC`: 60 s; as do roteiro aguentam 90 s, os retornos 45 s; as do
  treinamento não desistem). As do roteiro esperam a mesa ficar em silêncio, por no máximo 30 minutos de jogo.
- Às vezes o destino não atende (sorteado, `PhoneCall.away`); roteiros com `alt_target` deixam o operador sugerir
  outro lugar do mesmo ramo. No discador, o lugar fechado não atende (`closes`, `answers_until`, `gone_from` no contato).
- Conexões completadas duram 34–68 minutos de jogo, cerca de 45–90 s reais (`talk_len` do nível de ritmo; mais longas do nível 6 em diante); depois as lâmpadas ficam vermelhas
  até o operador desmontar. Conversas mais longas prendem os cabos de conexão por mais tempo: em turnos
  movimentados, às vezes é preciso esperar uma conversa acabar (ou cortá-la) para ter um cabo livre. Sem cabo livre,
  a transferência ganha **[Todas as linhas ocupadas]**: quem liga espera (com mais paciência) ou diz que liga outra
  hora (desliga sem advertência e liga de novo mais tarde).
- A ficha de ocorrências (o bloco de fichas na mesa; a da noite vai para o supervisor) guarda as ocorrências numa fila: dá para registrar depois, sem travar o turno. A aba mostra quantas
  faltam; registrar é um clique no tipo (ligação comum, emergência ou trote), o resto a ficha já anotou.
- A última ligação nova toca às 23:40 (`LAST_CALL`); a partir daí aparece o botão **Encerrar turno** ao lado do relógio.
  Encerrar com alguém na linha conta como desligar na cara dela (advertência média).
- À meia-noite ninguém é cortado: quem está na linha é atendido até o fim (o relógio continua). O turno termina quando a
  mesa esvazia e não falta nada na ficha (ou pelo botão) e vem a tela final.

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
clima em `Sfx.WEATHER_MIX`.

Todos os sons são sintetizados em `sfx.gd`: a campainha ("trrrim-trrrim" de martelinho em duas campânulas), o
"tuuuu" de chamando (425 Hz, com o corte de frequências da linha) e os sons de ambiente (com o abafamento da distância).

## Vozes

Cada grupo de vogais do texto dispara uma sílaba sintetizada (pulso glotal + formantes da vogal; nasal em "ão", "também",
"central"), com o ataque da consoante antes dela (estalo em p/t/b/d, chiado em s/f/ch/j, zumbido em m/n), a entonação
da frase (a voz cai até o fim, a tônica de cada palavra sobe, a pergunta sobe nas últimas sílabas, a exclamação sai mais aguda, alta e enfática; `Sfx._tone`); na emergência, quem liga se agita com a barra de
agravamento, conforme o temperamento sorteado (`Sfx.agitation`, `PhoneCall.temper`) e a altura de cada
pessoa, tirada do nome (`Sfx.pitch_of`). Timbres em `SfxSynth.VOICE`: `f0` (altura), `breath` (sopro), `bus` e, fora
do telefone, `muffle` (quanto menor, mais abafado). As vozes de quem liga passam pelo barramento Phone, com a banda da
linha (distorção, 300–3400 Hz e pico em 2 kHz; ajustável no editor, em `default_bus_layout.tres`).

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
Com um campo de texto em foco, as teclas vão para o campo. **1**, **2** e **3** abrem a lista, o despacho e a ficha de ocorrências.

**F1** abre o painel de debug (só rodando pelo editor ou num export de debug; não existe no jogo final):

| Seção | O que faz | Limpar |
|---|---|---|
| Ligações e mesa | toca transferência (roteiro ou molde), informação, trote e qualquer emergência (escritas e moldes, com o caso sorteado) | encerra todas as ligações, zera a mesa (cabos na base) e tira os retornos da agenda |
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
- **Cabos de conexão** (vermelho, azul e amarelo; branco quando chega o Centro, na noite 5, e preto com o Alto da Serra, na noite 10;
  `CORD_COLORS`, `patches` em `scripts/ui/switchboard_base.gd`), independentes, com um plug em cada ponta:
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
