# Central de Vila Serena — protótipo (Godot 4.6)

Abra a pasta no Godot 4.6 (Importar → `project.godot`) e aperte F5.

## Estrutura

- `main.tscn` — cena única; toda a interface é montada por código em `scripts/main.gd`.
- `scripts/main.gd` — fluxo do turno: relógio, as 5 ligações, discagem, despacho, rádio, caderno e final.
- `scripts/game_data.gd` — conteúdo: lista telefônica, variações de cada ligação, ruas do mapa.
  Para criar novas conversas, acrescente dicionários às listas `T1`, `T2`, `EM` e `TR`.
- `scripts/switchboard.gd` — mesa comutadora (lâmpadas, tomadas, plugues FONE e SWITCH, cabos).
- `scripts/phone_book.gd` — lista telefônica paginada.
- `scripts/city_map.gd` — mapa clicável e unidades em deslocamento.
- `scripts/sfx.gd` — todos os sons, sintetizados ao iniciar. Troque as entradas de `streams` por arquivos reais quando tiver áudio gravado.
- `scripts/background.gd` — parede, janela com chuva e luminária em pixel art (640x360 ampliado 2x).
- `scripts/scrawl.gd` — a anotação que aparece no caderno.
- `fonts/` — Pixelify Sans e VT323 (SIL Open Font License).

## Ritmo do turno

O relógio nunca para: 1 minuto de jogo por segundo real (22:00 → 06:00 em cerca de 8 minutos).
Ajuste em `main.gd` → `GAME_MIN_PER_SEC`. Os horários previstos das ligações ficam em `GameData.CALL_AT`;
se o operador ainda estiver ocupado, a próxima ligação toca alguns minutos depois.
Linhas transferidas ficam ocupadas por 14–40 minutos de jogo (`talk_len` em `do_dial`).

## Vozes

Cada grupo de vogais do texto dispara uma sílaba sintetizada (pulso glotal + formantes da vogal + filtro abafado).
Timbres por personagem em `Sfx.VOICE`: `f0` (altura), `breath` (sopro), `muffle` (quanto menor, mais abafado).

## Controles

Clique no plug e depois na tomada (ou arraste). Esc devolve o plug à base.
Números, Backspace e Enter funcionam pelo teclado.

## Cabos

Os cabos são cordas simuladas (Verlet) em `switchboard.gd`: balançam ao arrastar o plug e
ao passar o mouse por cima. Ajuste `SLACK` (folga), `DAMPING` (quanto demora para parar),
`GRAVITY` e `STIFF_ITER` (rigidez) no topo do arquivo.

## Linha 07

A ligação desconhecida toca pela linha 07 como qualquer outra (lâmpada piscando, FONE + Atender).
Quando cai, a linha volta a ficar livre e a ocorrência vai para o caderno; clicar na linha 07
mostra o registro da última chamada.
