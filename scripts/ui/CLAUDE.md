# scripts/ui — o cenário e a mesa comutadora

Complemento do `CLAUDE.md` da raiz, lido ao mexer nesta pasta. Aqui ficam as regras e os nomes; o detalhe de cada
peça (medidas, cores, o que foi tentado e saiu) está em `docs/mapa-ui-detalhado.md` (**não leia inteiro**:
`grep -n "<nome>" docs/mapa-ui-detalhado.md`) e o porquê, no `HISTORICO.md` (pelas chaves `#sala`, `#vista`,
`#janela`, `#luz`, `#objetos`, `#cabos`, `#mesa-comutadora`, `#saiu`...).

## O cenário (`Background`)

### Câmera e disposição
- **Uma câmera só**, em perspectiva de um ponto: os olhos do operador sentado (`SEAT_EYE`, `SEAT_BACK` dão a focal,
  `Z0`); ponto de fuga `_vp` em `VP_AT` do espaço da mesa; `_proj`/`_p3` levam um ponto da sala (cm a partir dos
  olhos, `_cm`) para a tela. A parede do fundo fica a `Z0 × WALL_K`; a parede da direita tem o ponto de fuga dela
  (`SIDE_VP`, `_svp`, `_side_pt`) e as contas de luz pela janela pegam o meio do vão (`_wall_x`). Nunca acerte a
  perspectiva elemento por elemento: pense a cena e passe pela câmera.
- A tela é uma mesa de trabalho: no alto da esquerda o horário num papel com fita (`ShiftPlate`) e a placa da
  companhia; embaixo, a mesa comutadora (492×304) com a prateleira (`Shelf`) e a frente do console (`%Desk`, com a
  miniatura do painel, `ConsoleMini`); à direita a sala e as ferramentas (`Tools`, o papel sai do objeto dele na mesa,
  `Tools.origin` = `Background.prop_rect`; sem abas); embaixo de tudo, o painel do operador (`PhonePanel`, 150 px, fora
  da luz da sala). A dica do manual (`HintSlot`) está escondida, a pedido.
- **A sala se distribui na largura que tiver**: armário (`CAB_W`, `CAB_AT`), conduíte, folhinha e cartaz; os objetos
  da mesa em duas fileiras (`_row`, `WALL_PAD`, `EDGE_PX`): atrás, o que é alto (unidade de despacho, listas, relógio
  com a caneca na frente); na frente, o que é baixo (calculógrafo, bloco de fichas, jornal). A prancheta fica
  pendurada na lateral da mesa comutadora (`_draw_hung_clipboard`). `test_layout` confere que nada se sobrepõe.

### Camadas e redesenho
- **Só redesenha o que mudou** (redesenhar a sala custava ~20 ms): a sala (`_state`), a camada de cima `_over` (escuro,
  janela, neon, sombra do papel, luzes no `Bloom`), a do relâmpago (`_bolt_layer`, força no `modulate`), a frente do
  relógio (`_clock_face`, textura trocada no lugar), os objetos da mesa (`_props_layer`, redesenhada logo depois da
  sala), a persiana (`_blind_layer`), o objeto erguido sob o mouse (`_lifted`), a ponta do bilhete (`_tip`), o sol
  (`_sun_layer`), as sombras da luminária (`_shade_layer`), a parede (`_wall_layer`, `_wall_glow`) e a poeira
  (`%Dust`, 30 quadros por segundo). Algo novo que muda entra no estado da camada certa.
- A vista da janela tem tela própria (`_vport`, `UPDATE_ONCE` a cada quadro dela, 30 por segundo), em partes: o céu
  (`_sky`), a de trás (`_back`, só quando muda, `_back_state`), a luz do sol no chão (`_street_mul` multiplica,
  `_street_add` soma), o que fica em pé (`_upright`) e a da frente (`_draw_city_front`, a cada quadro). O `SceneView`
  só desenha quando algo muda (`Background._show`).
- Sem tela (`_headless`), a vista não é desenhada.

### Desenho dos objetos
- Pixel art em 1x1, sem contorno preto (a beira é o tom da própria peça na luz ou na sombra). Peças redondas por
  `PixelArt.disc` (`Background._sprite`), **nunca `draw_circle`**.
- Objetos chatos: o tampo desenhado de frente numa imagem (`_flat`) e posto na perspectiva pixel a pixel pela
  homografia (`_project`, `_homography`), guardado até mudar; **risco fino vai na tela** (`_ink` nas alturas de
  `_rows`), não no papel (virava moiré). Cada objeto girado uns graus (`_turned`, `_faces`). Sombra em degraus
  (`_desk_shadow`).
- Luz nos objetos: cada um escurece pela distância à poça (`_shade`, `_pool`, `FRONT_LIGHT`); **os papéis trocam de tom
  na rampa** (`_still`, `_paper_step`, `Pal.lit`, `PAPER_RAMPS`), não escurecem por cima; o metal pequeno fica num
  degrau só (`_lit_image`). A luminária piscando ou esquentando não redesenha: é o shader (`_noir`, `FLICK_DARK`).
- Objetos que abrem ferramentas: `prop_clicked(id)` → `Tools.set_tab`, **ao soltar o botão** (ao apertar, o papel
  surgia sob o mouse e a soltura se perdia: a cena ficava com o mouse); sob o mouse o objeto sobe 2 px (`LIFT_PX`) e a
  etiqueta é uma fita crepe (`draw_hover`). O estado do jogo aparece nos objetos (`pending`, `unread`, `alert`,
  `card_out`, `counting`, `tickets`, `toll_desk`, `news`, `written`, `sips`).
- A sala muda pelas noites (`GameContent.room`, `RoomChange`, `Background.details`); a folhinha é a data do jogo
  (`GameData.date_of`).

### A sala
- Parede num tom só (`Pal.WALL_PAINT`) com manchas leves (`_stain_art`) e marcas de uso (`_draw_wall_marks`); armário
  de aço que abre (`CABINET_ID`, `cab_open`), conduíte, mancha de umidade (`damp`, de `Progress.rains`).
- Janela na parede da direita (`_draw_side_wall`): persiana que fecha e abre (`toggle_blind`, `BLIND_ID`, `_blind_shape`),
  peitoril (`_sill_lit`), vão com espessura (`WALL_D`), sem montante nem travessa. O vidro reflete a sala
  (`_draw_reflection`) e embaça (`_draw_mist`).
- A luminária não aparece (`_lamp_x`, `LAMP_Y`): na parede, o arco (`_draw_wall_light`); na mesa, a poça (`POOL_R`); no
  ar, o feixe (`_beam`) e a poeira (`_motes`). Luz e vinheta lisas, sem degraus. Clima noir (`_noir`, `GLOOM_*`).
- Relógio de flip na mesa (`_draw_flip_clock`, `DIGITS`, `_flip_step`), caneca esmaltada (`_mug_art`, vapor, goles).

### A vista (uma cena 3D simples no vidro)
- Câmera dentro do prédio a `OUT_EYE` m da rua, focal `OUT_F`, um ponto de fuga no horizonte (`OUT_AT`); tudo em
  metros (`_o(g, x, z, h)`, `_patch`). De perto para longe: nossa calçada some na sombra do prédio, a rua (`STREET`)
  com as duas mãos de carros (`_cars`, `CAR_KINDS`, `_draw_car`), a calçada de lá com postes (`FAR_LAMPS`), as
  fachadas (`_houses`: o prédio de tijolos com a varanda `APT`, o hotel com o letreiro de neon `_sign_layout`, o bar),
  a rua do cruzamento entre paredes (`CROSSING`, `_canyon`) até a igreja (`CHURCH_*`) e a cidade atrás (`CITY_BACK`).
- O que é desenhado em px fixos (igreja, sol, lua, letreiro) cresce por `OUT_K`. A árvore e a cerca viva do primeiro
  plano são postas pela parede da sala (`_side_pt`), não pela câmera da vista.
- **Lá fora acontece coisa** (`_events`): carros, gente a pé (`_walkers`, `_draw_walker`), quem sai do bar, quem fuma
  na varanda, gato, bicicleta, ônibus, táxi no hotel, vira-lata, mariposas; os telefones da lista vistos dela
  (`CALLED`, `phones`); **o homem do mistério** chega e fica embaixo do poste (`stranger`, `MAN_*`). Gente e carros
  seguem a hora e o dia da semana (`BUSY`, `LATE_*`).
- Clima: chuva (`rain_level`, pingos `_drops`, gotas `_beads`, relâmpago `BOLT_*` e trovão), névoa (`_draw_fog`),
  noite limpa com a lua de verdade (`_moon_age`, `_draw_moon`).
- **O amanhecer da noite 15** (`DAWN`, `SUNRISE`, `MORNING`): céu em degradê (`Pal.DAWN_SKY`, `_sky_stops`), sol
  nascendo atrás da igreja (`_sun_at`, `_draw_dawn`, `SUN_LOW`), raios crepusculares (`_draw_crepuscular`), faixa de
  sol na rua como luz e não tinta (`_draw_sun_strip`), sombras compridas (`_sun_shadow`), vidros espelhando
  (`_sun_glass`), postes e neon apagando, e na sala a luz do dia por parâmetros (`daylight`, `_sun_layer`). É a área
  com mais pedidos no `HISTORICO.md`: consulte as chaves `#vista` e `#luz` antes de mexer.
- Bloom das janelas e do letreiro: `Bloom.light` com `parts`; luzes de fora na sala: `_window_light_list`.

## A mesa comutadora (`Switchboard`)
- **Tomadas por id**: 1–10 entradas, 11–20 saídas (linha + 10), destinos = o próprio número (101–399; 901–906 os
  troncos interurbanos). Bancos A | B | C (100–199 | 200–299 | 300–399); o banco de um setor que não é do operador
  fica sob uma chapa (`_draw_plate`) e não aceita clique.
- `ends[]`: tomada de cada ponta (-1 = no buraco). **Ponta 0 = FONE** (só em entradas); pontas 1..2×`patches` = os
  cabos de conexão (`mate(e)` dá a outra ponta). Um par de cabos por setor entregue (`SHELF_SLOTS` lugares, os vagos
  sob um tampo, `_draw_cover`). `dest_of_output(n)` segue o cabo da saída. `refuse(e, j)` decide compatibilidade.
- **Chave de escuta** de cada linha (`lever_rect`, `lever_up`, `lever_pressed`).
- **Fios** são cordas de Verlet, uma por ponta (`Cord`, `scripts/ui/cord.gd`, sem tela nem som, testada sozinha):
  presas no buraco (`hole(e)`) e na traseira do plug; o contrapeso puxa a folga para dentro (`WEIGHT_TAKE`); todos com
  o mesmo comprimento (`Cord.MAX`); a prateleira e a beira dela são quinas (`hang_step`, `lip_y`, `route`); fio parado
  dorme (`SLEEP_STEPS`). No desenho: dobras do pano (`_kinked`), trançado (`BRAID`, uma chamada,
  `draw_multiline_colors`), curva Catmull-Rom (`_smooth`).
- **Plugs**: pixel art de um P10 (`PLUG_ART`), girados pelo RotSprite em passos de 5° (`PixelArt.turned`); encaixados,
  vistos de frente montados com discos (`_draw_plug_face`), com paralaxe para os olhos (`_tilt`); na mão balançam
  como pêndulo (`_swing_step`); soltos voltam ao buraco e assentam (`_seat`). Clique (apertar e soltar parado, em
  `CLICK_SEC`, sem andar `CLICK_PX`) desencaixa; plug só se move arrastando.
- **Sons da mesa** pelo lugar na tela (`_sfx`): o atrito do fio (`Sfx.cord_rub`, barramento Rub, pela velocidade do
  fio entrando ou saindo), `drop`, `thump`, `cord_stop`, `cord_snag`, `cord_snap`, `cord_tap`.
- **Quatro camadas, cada uma só redesenha quando o `_look` dela muda**: o painel (`_draw`), as lâmpadas (`_lamps`,
  que registram as luzes e os plugs que as cobrem no `Bloom`), as tomadas dos destinos com a luz da sala (`_top`) e os
  plugs com os fios (`_cords`, a cada quadro só com algo se mexendo). Desenhe em `_ci`.
- Lâmpadas de vidro leitoso que acendem rápido e apagam devagar (`_fade`, `LAMP_ON_SEC`/`LAMP_OFF_SEC`); encaixes de
  pixel art (`_jack_tex`, `JACK_METAL`); luz da luminária no painel (`_draw_room_light`) e escurecendo junto com a da sala
  pelo `modulate` (`Switchboard.dim`); a luz das lâmpadas no painel pelo `_glow`.
- Moldura de madeira pixel a pixel (`_wood_frame`), faixas gravadas na fonte miúda (`_draw_rule`, `RULES`), uso de
  anos (`_draw_wear`), banco interurbano (`_draw_trunks`). Mexendo na altura, confira que a coluna da esquerda cabe
  (até 540).
- Folha de prévia de toda a pixel art: `Godot --headless --path . -s tools/sprite_sheet.gd` → `build/sprites.png`.
