# Central de Vila Serena (Godot 4.6)

Abra a pasta no Godot 4.6 (Importar → `project.godot`) e aperte F5.

## Estrutura

- `scenes/main.tscn` — cena principal (layout em containers); `scenes/ui/` — telefone, rádio, abas de ferramentas
  (lista, mapa, despacho, caderno), tela inicial e final. Edite a interface no editor do Godot.
- `themes/main_theme.tres` — tema global (cores, fontes e variações de botão/painel/rótulo).
- `data/content.tres` — **todo o conteúdo**: lista telefônica, ruas, falas avulsas, pedidos de informação e as
  listas de roteiros. Cada roteiro de ligação é um arquivo em `data/calls/` (transferências, emergências, trotes).
  Para criar uma ligação nova: duplique um `.tres` em `data/calls/`, edite no inspetor e arraste para a lista certa
  no `content.tres`.
- `data/templates/` — **moldes**: roteiros com lacunas em inglês, preenchidas na hora (veja abaixo).
- `scripts/main.gd` — conduz o turno (relógio, agenda, mesa, fim de ligação, final).
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
tela em `scenes/ui/report_view.tscn`): lista as advertências (leve, média, grave), traz o **jornal da manhã** com o
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
| Faltar unidade no despacho | média | o rádio pede a unidade que falta |
| Enviar unidades sem emergência | média | — |
| Enviar unidade a mais (no local certo) | leve | o rádio diz que ela não era necessária, e ela volta logo |
| Marcar o tipo de ocorrência errado no despacho | leve | — (o tipo é obrigatório para enviar) |

Quem liga de novo espera a mesa esvaziar (no máximo `RETRY_WAIT`, 20 min de jogo), para não empilhar ligações
sobre quem já está sobrecarregado. Quando a emergência liga de novo, em `REDISPATCH_CHANCE` (60%) dos casos ainda dá para despachar (no jornal: "com
atraso"); nos outros, já é tarde (no jornal: "ninguém foi atender"). Cada pessoa liga de novo no máximo uma vez por motivo, sempre antes do fim do turno (vale também para a
ligação do tutorial, que só não gera advertência).
`ShiftReport.SEVERE_LIMIT` (3 graves) está pronto para somar entre noites, quando houver mais de uma.

## Moldes (conversas geradas)

Metade das ligações extras e da emergência do turno (`TEMPLATE_CHANCE` em `main.gd`) vem de um molde; a outra metade,
dos roteiros escritos em `data/calls/`. As ligações principais de transferência, os trotes, o tutorial e a ligação
desconhecida são sempre escritos à mão.

- **Transferência** (`transfer_templates`): o molde é um `TransferCall` com lacunas em `opening` e `repeat`.
  O contato é sorteado entre os que têm `spoken` e `reasons` na lista e atendem à noite; quem liga sai de `callers`.
  Lacunas: `{place}` "o Hotel Estrela", `{of_place}` "do Hotel Estrela", `{to_place}` "pro Hotel Estrela",
  `{street}` rua do contato, `{number}` "305", `{digits}` "três, zero, cinco", `{reason}` um dos motivos do contato.
- **Emergência** (`emergency_templates`): o molde é um `EmergencyCall`; valem ocorrência, unidades e as falas.
  Rua e número são sorteados; o trecho do mapa sai do número. Lacunas: `{street}`, `{house}`, `{address}`.
- **Para ter mais variedade:** acrescente motivos (`reasons`) aos contatos, ou um `spoken` + motivos a um contato
  novo. Um molde novo vale para todos os contatos. Escreva motivos que sirvam para quem liga, homem ou mulher.
- A primeira letra de cada fala vira maiúscula depois de preenchida (`GameData.fill`).

## Testes

`tests/run.sh` reimporta o projeto e roda, em modo headless, os cenários dirigidos (`test_flow.gd`), as consequências
(`test_penalties.gd`) e três turnos completos jogados
por um robô (`test_shift.gd`, com `--seed=1..3`), mais um turno com o robô "desastrado" (`--clumsy`, deixa de
atender 1 em cada 3 ligações), que mede a bola de neve dos retornos. Para jogar uma agenda específica: `godot --path . -- --seed=123`.

## Tradução

Os textos visíveis passam por `tr()`, com o português como chave. Para traduzir: gere o `.pot` em
Projeto → Configurações → Localização → Geração de POT, crie o `.po` do idioma e adicione em Traduções.
As falas que ficam nos Resources (`data/`) também passam por `tr()` quando aparecem na tela.

## Ritmo do turno

O relógio nunca para: 0,75 minuto de jogo por segundo real (18:00 → 00:00 em cerca de 8 minutos).
Ajuste em `main.gd` → `GAME_MIN_PER_SEC`.

- **4 ligações principais** (transferência, transferência com nomes parecidos, emergência, trote)
  nos horários de `main_call_at` (em `data/content.tres`), cada uma sorteada entre várias variações.
- **Ligação desconhecida**: toca por uma entrada livre qualquer, num horário sorteado entre 22:00 e 23:30
  (`MYST_FROM`/`MYST_TO`).
- **4 a 6 ligações extras** (`FILLERS`) em horários aleatórios pelo turno todo, antes e depois da ligação desconhecida (`_fillers`):
  transferências (`data/calls/transfer_*.tres`) que não saíram como principais, ou pedidos de informação
  (número de alguém na lista, ou as horas). Ficam a pelo menos `FILLER_GAP` (25) minutos de jogo das outras ligações.
- **Pico** (`PEAK_CHANCE`, 35% dos turnos): uma extra logo depois de uma principal, e duas linhas tocam juntas;
  em 40% desses picos vem mais uma, e três tocam juntas.
- As ligações tocam no horário mesmo com o operador ocupado. Quem ninguém atende desiste
  (`GIVE_UP_SEC`: 60 s para extras, 90 s para principais; a do tutorial e a desconhecida não desistem).
- A ligação desconhecida espera a mesa ficar em silêncio, por no máximo 30 minutos de jogo.
- Alguns números não atendem à noite (`closed_at_night` no contato). Roteiros com `alt_target` deixam o operador
  sugerir outro lugar.
- Conexões completadas duram 34–68 minutos de jogo, cerca de 45–90 s reais (`TALK_LEN` em `main.gd`); depois as lâmpadas ficam vermelhas
  até o operador desmontar. Conversas mais longas prendem os cabos de conexão por mais tempo: em turnos
  movimentados, às vezes é preciso esperar uma conversa acabar (ou cortá-la) para ter um cabo livre.
- O caderno guarda as ocorrências numa fila: dá para registrar depois, sem travar o turno.
- O turno termina à meia-noite (depois de a ligação desconhecida ter tocado e caído) e vem a tela final.

## Clima e sons

Cada turno sorteia o clima (`WEATHERS` em `main.gd`; para forçar: `godot --path . -- --weather=fog`):

| Clima | Som | Janela | Conversa fiada |
|---|---|---|---|
| `rain` | chuva | gotas no vidro | `smalltalk` + `smalltalk_rain` |
| `fog` | grilos e coruja | névoa passando, luzes difusas | `smalltalk` + `smalltalk_fog` |
| `clear` | brisa leve, grilos e coruja | estrelas e lua | `smalltalk` + `smalltalk_clear` |

A coruja aparece por 30–60 s, piando a cada 7–14 s, e some por 45–110 s (`OWL_*` em `sfx.gd`). Volumes de cada
clima em `Sfx.WEATHER_MIX`. 15 minutos antes da ligação desconhecida (`SHADOW_LEAD`) aparece a silhueta de alguém
do lado de fora da janela; ela some quando a ligação cai. Antes da ligação desconhecida a noite se cala (grilos e coruja param, chuva e brisa
baixam) e volta aos poucos depois.

Todos os sons são sintetizados em `sfx.gd`. A campainha ("trrrim-trrrim" de martelinho em duas campânulas) e o
"tuuuu" de chamando (425 Hz) passam pelo filtro de caixa oca (`_box`), só usado nos sons dos aparelhos; os sons de
ambiente só levam o abafamento da distância.

## Vozes

Cada grupo de vogais do texto dispara uma sílaba sintetizada (pulso glotal + formantes da vogal + filtro abafado).
Timbres por personagem em `Sfx.VOICE`: `f0` (altura), `breath` (sopro), `muffle` (quanto menor, mais abafado).

## Controles

Arraste o plug até a tomada (ou clique no plug da base e depois na tomada). **Clicar num plug encaixado**
faz ele voltar sozinho para a base, numa animação em arco (`RETURN_SEC` em `scripts/ui/switchboard.gd`): o FONE volta
ao telefone; no cabo de conexão, cada clique devolve uma ponta, e o cabo só se enrola na base com as duas.
Arrastar um plug encaixado para outra tomada o move. Soltar fora de uma tomada, clicar fora, apertar Esc ou o botão direito (ação `cancel_plug` no Input Map)
também devolve o plug à base. Cada tipo de plug só encaixa nas tomadas compatíveis: a tomada sob o plug
acende em amarelo se aceita, em vermelho se não.

## A mesa

- **Entradas (01–10):** onde as chamadas chegam. A lâmpada pisca e o telefone toca.
- **Saídas:** uma tomada logo abaixo de cada entrada, para o cabo de conexão.
- **Destinos:** um plug por número da lista (menos polícia, bombeiros e hospital, que vão pelo despacho).
- **FONE** (cabo vermelho): sai do encaixe no canto do telefone e só entra nas entradas.
  A ligação da entrada onde o FONE está é a que aparece no telefone.
- **Cabos de conexão** (ocre): `PATCHES = 3` em `scripts/ui/switchboard.gd`, independentes, com um plug em cada ponta:
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

## Cabos

Os cabos são cordas simuladas (Verlet) em `scripts/ui/switchboard.gd`: balançam ao arrastar o plug e
ao passar o mouse por cima. Ajuste `SLACK` (folga), `DAMPING` (quanto demora para parar),
`GRAVITY` e `STIFF_ITER` (rigidez) no topo do arquivo.

## Ligação desconhecida

Toca por uma entrada livre sorteada, como qualquer outra (lâmpada piscando, cabo + Atender).
Quando cai, a linha volta a ficar livre e a ocorrência vai para o caderno; clicar nessa linha
mostra o registro da última chamada.
