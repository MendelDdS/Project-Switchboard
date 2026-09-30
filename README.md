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
- `scripts/main.gd` — conduz o turno (relógio, agenda, mesa, fim de ligação, final).
- `scripts/conversation.gd` — como cada tipo de ligação se desenrola (falas, escolhas do operador).
- `scripts/model/` — `PhoneCall` (uma ligação) e `Exchange` (estado das linhas e destinos).
- `scripts/data/` — classes dos Resources de conteúdo.
- `scripts/ui/` — scripts das cenas e dos elementos desenhados (mesa comutadora, mapa, lista, fundo).
- `scripts/sfx.gd` — autoload `Sfx`: todos os sons, sintetizados ao iniciar, nos barramentos Ambience, Voices e
  Effects (`default_bus_layout.tres`). Troque as entradas de `streams` por arquivos reais quando tiver áudio gravado.
- `tests/` — testes automatizados (`tests/run.sh`).
- `fonts/` — Pixelify Sans e VT323 (SIL Open Font License).

## Testes

`tests/run.sh` roda, em modo headless, os cenários dirigidos (`test_flow.gd`) e três turnos completos jogados
por um robô (`test_shift.gd`, com `--seed=1..3`). Para jogar uma agenda específica: `godot --path . -- --seed=123`.

## Tradução

Os textos visíveis passam por `tr()`, com o português como chave. Para traduzir: gere o `.pot` em
Projeto → Configurações → Localização → Geração de POT, crie o `.po` do idioma e adicione em Traduções.
As falas que ficam nos Resources (`data/`) também passam por `tr()` quando aparecem na tela.

## Ritmo do turno

O relógio nunca para: 1 minuto de jogo por segundo real (22:00 → 06:00 em cerca de 8 minutos).
Ajuste em `main.gd` → `GAME_MIN_PER_SEC`.

- **4 ligações principais** (transferência, transferência com nomes parecidos, emergência, trote)
  nos horários de `main_call_at` (em `data/content.tres`), cada uma sorteada entre várias variações.
- **Ligação desconhecida**: toca por uma entrada livre qualquer, num horário sorteado entre 02:00 e 05:30
  (`MYST_FROM`/`MYST_TO`).
- **5 a 7 ligações extras** em horários aleatórios pelo turno todo, antes e depois da ligação desconhecida (`_fillers`):
  transferências (`data/calls/transfer_*.tres`) que não saíram como principais, ou pedidos de informação
  (número de alguém na lista, ou as horas). Ficam a pelo menos `FILLER_GAP` (25) minutos de jogo das outras ligações.
- **Pico** (`PEAK_CHANCE`, 35% dos turnos): uma extra logo depois de uma principal, e duas linhas tocam juntas;
  em 40% desses picos vem mais uma, e três tocam juntas.
- As ligações tocam no horário mesmo com o operador ocupado. Quem ninguém atende desiste
  (`GIVE_UP_SEC`: 60 s para extras, 90 s para principais; a do tutorial e a desconhecida não desistem).
- A ligação desconhecida espera a mesa ficar em silêncio, por no máximo 30 minutos de jogo.
- Alguns números não atendem à noite (`closed_at_night` no contato). Roteiros com `alt_target` deixam o operador
  sugerir outro lugar.
- Conexões completadas duram 45–90 minutos de jogo (`TALK_LEN` em `main.gd`); depois as lâmpadas ficam vermelhas
  até o operador desmontar. Conversas mais longas prendem os cabos de conexão por mais tempo: em turnos
  movimentados, às vezes é preciso esperar uma conversa acabar (ou cortá-la) para ter um cabo livre.
- O caderno guarda as ocorrências numa fila: dá para registrar depois, sem travar o turno.
- O turno termina às 06:00 (depois de a ligação desconhecida ter tocado e caído) e vem a tela final.

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
