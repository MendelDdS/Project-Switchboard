# Central de Vila Serena — protótipo (Godot 4.6)

Abra a pasta no Godot 4.6 (Importar → `project.godot`) e aperte F5.

## Estrutura

- `main.tscn` — cena única; toda a interface é montada por código em `scripts/main.gd`.
- `scripts/main.gd` — fluxo do turno: relógio, as 5 ligações, conexões na mesa, despacho, rádio, caderno e final.
- `scripts/game_data.gd` — conteúdo: lista telefônica, variações de cada ligação, ruas do mapa.
  Para criar novas conversas, acrescente dicionários às listas `T1`, `T2`, `FILL`, `EM` e `TR`
  (ou entradas em `INFO_NUM`, `ASK_NUM`, `ASK_TIME`, `SMALLTALK`…).
- `scripts/switchboard.gd` — mesa comutadora (entradas, destinos, pares de cabos, chaves FALAR e TOCAR).
- `scripts/phone_book.gd` — lista telefônica paginada.
- `scripts/city_map.gd` — mapa clicável e unidades em deslocamento.
- `scripts/sfx.gd` — todos os sons, sintetizados ao iniciar. Troque as entradas de `streams` por arquivos reais quando tiver áudio gravado.
- `scripts/background.gd` — parede, janela com chuva e luminária em pixel art (640x360 ampliado 2x).
- `scripts/scrawl.gd` — a anotação que aparece no caderno.
- `fonts/` — Pixelify Sans e VT323 (SIL Open Font License).

## Ritmo do turno

O relógio nunca para: 1 minuto de jogo por segundo real (22:00 → 06:00 em cerca de 8 minutos).
Ajuste em `main.gd` → `GAME_MIN_PER_SEC`.

- **4 ligações principais** (transferência, transferência com nomes parecidos, emergência, trote)
  nos horários de `GameData.CALL_AT`, cada uma sorteada entre várias variações.
- **Linha 07** (a ligação desconhecida): toca num horário sorteado entre 02:00 e 05:30 (`MYST_FROM`/`MYST_TO`).
- **5 a 7 ligações extras** em horários aleatórios pelo turno todo, antes e depois da linha 07 (`_fillers`):
  transferências de `T1`/`T2`/`FILL` que não saíram como principais, ou pedidos de informação
  (número de alguém na lista, ou as horas). Ficam a pelo menos `FILLER_GAP` (25) minutos de jogo das outras ligações.
- **Pico** (`PEAK_CHANCE`, 35% dos turnos): uma extra logo depois de uma principal, e duas linhas tocam juntas;
  em 40% desses picos vem mais uma, e três tocam juntas.
- As ligações tocam no horário mesmo com o operador ocupado. Quem ninguém atende desiste
  (`GIVE_UP_SEC`: 60 s para extras, 90 s para principais; a do tutorial e a linha 07 não desistem).
- A linha 07 espera a mesa ficar em silêncio, por no máximo 30 minutos de jogo.
- Alguns números não atendem à noite (`GameData.CLOSED`). Pedidos com `alt` deixam o operador sugerir outro lugar.
- Conexões completadas duram 45–90 minutos de jogo (`TALK_LEN` em `main.gd`); depois as lâmpadas ficam vermelhas
  até o operador desmontar. Conversas mais longas prendem os cabos de conexão por mais tempo: em turnos
  movimentados, às vezes é preciso esperar uma conversa acabar (ou cortá-la) para ter um cabo livre.
- O caderno guarda as ocorrências numa fila: dá para registrar depois, sem travar o turno.
- O turno termina às 06:00 (depois de a linha 07 ter tocado e caído): a anotação aparece no caderno,
  se ainda não tiver aparecido, e em seguida vem a tela final.

## Vozes

Cada grupo de vogais do texto dispara uma sílaba sintetizada (pulso glotal + formantes da vogal + filtro abafado).
Timbres por personagem em `Sfx.VOICE`: `f0` (altura), `breath` (sopro), `muffle` (quanto menor, mais abafado).

## Controles

Arraste o plug até a tomada (ou clique no plug da base e depois na tomada). **Clicar num plug encaixado**
faz ele voltar sozinho para a base, numa animação em arco (`RETURN_SEC` em `switchboard.gd`): o FONE volta
ao telefone; no cabo de conexão, cada clique devolve uma ponta, e o cabo só se enrola na base com as duas.
Arrastar um plug encaixado para outra tomada o move. Soltar fora de uma tomada, clicar fora ou apertar Esc
também devolve o plug à base. Cada tipo de plug só encaixa nas tomadas compatíveis: a tomada sob o plug
acende em amarelo se aceita, em vermelho se não.

## A mesa

- **Entradas (01–10):** onde as chamadas chegam. A lâmpada pisca e o telefone toca.
- **Saídas:** uma tomada logo abaixo de cada entrada, para o cabo de conexão.
- **Destinos:** um plug por número da lista (menos polícia, bombeiros e hospital, que vão pelo despacho).
- **FONE** (cabo vermelho): sai do encaixe no canto do telefone e só entra nas entradas.
  A ligação da entrada onde o FONE está é a que aparece no telefone.
- **Cabos de conexão** (ocre): `PATCHES = 3` em `switchboard.gd`, independentes, com um plug em cada ponta:
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

Depois da linha 07, FONE na entrada 07 tenta ligar de volta.

## Cabos

Os cabos são cordas simuladas (Verlet) em `switchboard.gd`: balançam ao arrastar o plug e
ao passar o mouse por cima. Ajuste `SLACK` (folga), `DAMPING` (quanto demora para parar),
`GRAVITY` e `STIFF_ITER` (rigidez) no topo do arquivo.

## Linha 07

A ligação desconhecida toca pela linha 07 como qualquer outra (lâmpada piscando, cabo + Atender).
Quando cai, a linha volta a ficar livre e a ocorrência vai para o caderno; clicar na linha 07
mostra o registro da última chamada.
