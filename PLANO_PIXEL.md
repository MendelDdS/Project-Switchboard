# Plano: dithering e degraus irregulares (jaggies)

Pedido de 25/10/2026 (`HISTORICO.md`, 392). Objetivo: a tela inteira com cara de pixel art feita à mão, com a luz
em degraus de paleta (dithering só onde a transição é grande) e beiras de degraus regulares.

As imagens do diagnóstico ficam em `build/pixel/` (fora do git): `mapa/anotado_*.png` (os problemas numerados),
`mapa/detalhes.png` (cada um ampliado) e `mapa/<captura>.png` (o mapa automático: laranja = degradê contínuo, blocos
de 8×8 com 28 cores ou mais e vizinhos quase iguais); `ref/`, o conjunto de partida medido pelo `tools/pixel_map.gd`;
e só a captura da última etapa feita (`etapa3/`), o "antes" da próxima. Os mapas (`<pasta>_mapa/`) se refazem.

## 1. Diagnóstico

### Degradês contínuos (D): onde entra o dithering

Números de partida (`tools/pixel_map.gd` sobre `tools/hibit_shots.sh build/pixel/ref`, 25/10/2026; noite 2):

| Captura | Cores distintas | Blocos de degradê (8×8) |
|---|---|---|
| Sala, 21:00, céu limpo (`sala_2100_clear`) | 33.528 | 527 |
| Sala, 18:30, neblina (`sala_1830_fog`) | 33.052 | 469 |
| Sala, 23:30, chuva (`sala_2330_rain`) | 31.303 | 377 |
| Mesa comutadora com cabos (`mesa_comutadora`) | 34.416 | 534 |
| Amanhecer da noite 15, 04:30 / 05:30 / 06:00 | 34.421 / 45.368 / 51.937 | 542 / 595 / 697 |
| Despacho aberto (`despacho`) | 12.194 | 28 |
| Calculógrafo aberto (`calculografo`) | 12.327 | 26 |

Pixel art de verdade fica na casa das centenas a poucos milhares. O excesso vem dos shaders de luz, que somam e
multiplicam a cor com `smoothstep` contínuo, sem degraus: `lamp_light.gdshader`, `room_noir.gdshader`,
`window_lights.gdshader`, `board_glow.gdshader` e a gradação `grade.gdshader`. O mapa automático acusa:

- **D1** a poça da luminária, na parede e no tampo;
- **D2** a vista da janela e o reflexo do vidro, sobretudo com neblina;
- **D3** o céu do amanhecer;
- **D4** o sol na parede e no tampo (`Background.daylight`);
- **D5** a rua ao sol.

Hoje não há dithering em lugar nenhum: o `Bloom.DITHER` foi desligado a pedido, porque pontos escuros salpicavam o
halo das lâmpadas (`HISTORICO.md` 58, `docs/mapa-detalhado.md`). Só o jornal usa pontilhado ordenado, de propósito
(a retícula da foto, `news_view.gd`).

### Degraus irregulares (J)

| | Onde | O que se vê | De onde vem |
|---|---|---|---|
| J1 | lateral da mesa comutadora (a face creme) | degraus 1-2-1-3 numa diagonal reta | `_side_faces`/`_fill`: vértices fracionários de `_p3`, rasterizados pela GPU |
| J2 | cabos de conexão da mesa | contorno escuro e faixas de cor que engrossam e afinam | `Switchboard._draw_rope` (traço por trechos) |
| J3 | tampas das teclas no console | diagonais dobradas (duas linhas paralelas pisando em lugares diferentes) | `switchboard_panel._draw_cover` |
| J4 | listas telefônicas | o brilho da lombada vira pontilhado, as quinas pisam irregular | `_draw_books`: linhas dentro da textura projetada (`_project`) |
| J5 | bloco de notas | beira esquerda, margem vermelha e pautas quebradas no meio | `_pad_marks` na textura projetada |
| J6 | relógio | as quinas do tampo, em degraus 2-1-2-1 | `_clock_box` (vértices fracionários) |
| J7 | peitoril da janela | degraus longos de comprimentos desiguais (10, 12, 9...) | o peitoril em `background.gd` (`_draw_sill_light` e a face) |
| J8 | verga da janela (em cima) | a textura de traços vira moiré | a textura da verga na perspectiva |
| J9 | fios saindo da caixa na parede | diagonais paralelas grudadas, em moiré | `_draw_conduit` |
| J10 | beirais e telhados da vista | escada irregular na diagonal | `background_view.gd` (prédios) |
| J11 | carimbo do conceito no relatório (fica, a pedido) | letras quebradas | `ReportView._stamp_image`: o desgaste sorteado (10% dos pixels) mais o giro pixel a pixel |

A causa comum: uma reta qualquer, rasterizada a partir de pontos fracionários, sai com degraus de comprimento
variado. A beira e o brilho dela, calculados cada um a partir do 3D, pisam em lugares diferentes, e as linhas
desenhadas dentro de uma textura que depois é projetada se partem.

## 2. Regras para a versão definitiva

- **Degraus regulares.** Numa beira reta, os degraus têm o mesmo comprimento ou alternam de forma simétrica
  (3-3-3, 2-3-2-3). Nas beiras longas e à vista, inclinações limpas: 1:1, 1:2, 2:1, 1:3, 3:1, 1:4.
- **Vértice em pixel inteiro.** Os pontos de um polígono são arredondados antes de desenhar; a beira e o brilho dela
  saem da mesma reta, deslocada em pixels inteiros (não recalculada no 3D).
- **Linha na tela, não na textura.** Linhas finas sobre uma superfície em perspectiva (pauta, margem, lombada)
  são desenhadas depois da projeção, com `_tex_pt` e uma reta de degraus regulares.
- **Luz em degraus.** A força da luz é quantizada em poucos degraus por superfície. O dithering ordenado 4×4
  (Bayer), preso ao pixel da tela, só entra numa faixa estreita entre dois degraus, e só em transições grandes:
  poça da luminária, céu e sol. Nunca em halo pequeno (lâmpadas, LEDs), texto, papel aberto ou objeto pequeno.

## 3. Etapas

Feitas aos poucos, uma por vez: marque `[x]` ao terminar cada item. Cada etapa termina com captura antes e depois
mandada ao usuário, `tools/visual.sh`, a medida do `medir.gd` e uma entrada no `HISTORICO.md`.

### Etapa 0: medida
- [x] `tools/pixel_map.gd`: o mapa de degradês e a contagem de cores das capturas de referência, para comparar etapa
  por etapa (`-- build/pixel/ref build/pixel/<etapa>`; os mapas vão para `<pasta>_mapa/`). O `tools/hibit_shots.sh`
  passou a esperar 3500 quadros (com 1500, só 4 das capturas saíam).
- [x] Guardar os números de partida na tabela da seção 1 (`build/pixel/ref`: 21 medidas; as 6 `_zoom`, ampliadas, ficam de fora).

### Etapa 1: vértices no pixel e paralelas juntas (J1, J3, J6, quinas de J4)
- [x] Arredondar os pontos no `_fill`/`_poly`: só na mesa comutadora e nos objetos do tampo (`_snap`, onde se desenha
  em px da tela; no resto da sala, em escala 2, o arredondamento cairia de 2 em 2 px). As faces e tampos com textura
  (`_faces`, `_flat`, as listas, o relógio) já saem arredondados, para a textura e a face pisarem juntas.
- [x] O brilho das beiras como deslocamento inteiro da beira: a quina da lateral da mesa e as do relógio são a coluna
  rente à beira (`_pixel_line`); nas tampas do console, a fresta e a quina contam da beira arredondada de cada linha.
  O que sobra nas diagonais (degraus 1-2-1-3 da lateral e das tampas) é inclinação: etapa 2.

### Etapa 2: inclinações limpas nas beiras longas (J1, J7, J10, a beira de J5)
- [x] `Background.clean_slope(a, b, free)`: a menos de 12% (`CLEAN_TOL`) de uma razão limpa (n ou n + ½), o ponto de
  longe vai até ela, só nos eixos de `free` e o mínimo possível; sem razão exata nesses eixos, a quase exata. Os casos
  ficam no `test_layout`.
- [x] Aplicado à beira de baixo da lateral da mesa (J1: só o y, a quina de trás fica em pé; de 1-2-1-3 para 3-4-3-4),
  às beiras do lado do bloco de fichas e do jornal (J5: só o x, a beira do fundo e as pautas ficam) e à cornija das
  paredes da rua que foge para o fundo (J10, a luz dela pixel a pixel). O peitoril (J7) ficou só com os pontos inteiros
  e a luz pixel a pixel (degraus que variam de 1 no máximo): a ponta de longe é presa ao canto da janela, e levada à
  inclinação limpa ela subia ~5 px e descolava do batente. As tampas do console seguem a inclinação dos pares de plugs
  (12 a cada 14 linhas, fora da tolerância) e ficam.
- [x] Retoque (26/10/2026): nos objetos chatos a tolerância é `FLAT_TOL` (16%; com 12%, o lado esquerdo do bloco ficava
  em 2-2-1), a sombra de contato é o pé deslocado 1 px em pixels inteiros (risca de 1 px, não 1 e 2) e o `_project`
  desempata o pixel cuja beira passa pelo centro (`EDGE_EPS`; a beira da direita do bloco tinha dentes).
- [x] Auditoria (26/10/2026): relógio, calculógrafo e caixinha (`_clock_corners`, `exact_slope`), livros (`BOOK_TOL`,
  a capa sem o tom liso por baixo) e a lateral da mesa comutadora (`_bent_edge`). Conferir beira:
  `tools/edge_steps.gd` (degraus de uma reta numa captura); nas beiras com textura dentro, imprimir os cantos e conferir
  a razão.

### Etapa 3: linhas desenhadas na tela (J4, J5, J8)
- [x] Uma reta de degraus regulares: o `_pixel_line` leva as pontas ao pixel delas e distribui os degraus por igual
  entre elas (antes, pontas quebradas davam 1-2-1-3 numa reta só).
- [x] Lombadas das listas (J4) e pautas e margem do bloco (J5): já eram desenhadas na tela (`_pixel_line`, `_ink`);
  com a reta nova, os degraus ficaram iguais. O miolo das listas fica na textura projetada (desenhado na tela, ele já
  tinha virado degraus quebrados e faixas, ver `_draw_books`).
- [x] A "verga" (J8) era a persiana recolhida: lâminas mais altas (`Background.SLAT`, 3 em vez de 2) e a beira de cada
  uma numa reta de pixel na tela; o fundo, de uma vez. Sem moiré, aberta ou fechada; o `medir.gd` deu o mesmo tempo.

### Etapa 4: luz em degraus com pontilhado (D1–D5): descartada
Testada na poça da luminária (26/10/2026: 8, 6 e 4 degraus pontilhados e 6 secos, capturas em `build/pixel/e4/`) e
recusada pelo usuário: "os pontilhados deixam muito ruído e a poça em camadas fica sem profundidade". A luz continua
lisa nos shaders; o número de cores da sala fica como está (a meta de ~3 mil saiu).

### Etapa 5: cabos de conexão (J2)
- [x] Pela distância à linha do meio, como os fios da mesa, guardado enquanto o fio dorme (`_rope_image`,
  `_rope_arts`); mexendo, o traçado de antes (`_draw_rope_line`). As cores e o trançado ficaram os mesmos.
- [x] Medido (26/10/2026): o `medir.gd` deu igual com e sem; montar a imagem custa 2 a 10 ms, uma vez por fio parado.

### Etapa 6: retoques
- [x] Fios da caixa na parede (J9): as mesmas curvas caídas, montadas pixel a pixel (`_cable_at`), de 2 px, saindo de dentro
  da caixa (26/10/2026: retos, a 45°, ficaram feios e saíram).
- [x] Carimbo do relatório (J11): o desgaste fica como está (decisão do usuário, 25/10/2026).

Ordem: 0 → 1 → 2 → 3 (barato e muda muito) → ~~4~~ (descartada) → 5 → 6 (os fios da parede com a curva de antes, pixel a pixel). Concluído em 26/10/2026.

## 4. Decisões do usuário (25/10/2026)

- **Pontilhado:** testar na poça da luminária, no céu e no sol e mostrar antes de aprovar (etapa 4).
- **Degraus de luz:** testar e mostrar antes de aprovar; preferência pela versão mais suave (6–8 degraus).
- **Carimbo:** manter o desgaste.
- **Etapa 4 (26/10/2026):** sem pontilhado e sem luz em degraus: ruído demais e a poça sem profundidade.
- **Fios da caixa na parede (26/10/2026):** a curva caída fica, montada pixel a pixel; retos ficaram feios.
