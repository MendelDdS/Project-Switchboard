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
  companhia; embaixo, a mesa comutadora (441×238: o painel das tomadas, `SIZE`, e a coluna do lado, `SIDE_W`) com a prateleira (`Shelf`) e a frente do console (`%Desk`, com a
  miniatura do painel, `ConsoleMini`); à direita a sala e as ferramentas (`Tools`, o papel sai do objeto dele na mesa,
  `Tools.origin` = `Background.prop_rect`; sem abas); embaixo de tudo, o painel do operador (`PhonePanel`, 150 px, fora
  da luz da sala). A dica do manual (`HintSlot`) está escondida, a pedido.
- **A sala se distribui na largura que tiver**: armário (`CAB_W`, `CAB_AT`), conduíte, folhinha e cartaz; os objetos
  da mesa em duas fileiras (`_row`, `WALL_PAD`, `EDGE_PX`): atrás, o que é alto (unidade de despacho, listas, relógio
  com a caneca na frente); na frente, o que é baixo (calculógrafo, bloco de fichas, jornal). A prancheta fica
  pendurada na lateral da mesa comutadora (`_draw_hung_clipboard`). `test_layout` confere que nada se sobrepõe.
- Fios da unidade de despacho e do calculógrafo: saem da traseira delas e vão, rentes ao console, para o fundo da mesa
  (`_draw_cable`, imagem guardada em `_cable_art` por `_cable_at`, que monta também os fios da caixa na parede), desenhados antes das máquinas; sem plugues (a pedido). A mesa é
  afastada da parede: o fio passa da beira de trás e cai no vão, cortado nela. Objetos da
  mesa na paleta da mesa (relógio em `SHELL` com base oliva, caneca e lista do meio em azul-petróleo); os papéis com o
  selo `Switchboard.badge`.

### Camadas e redesenho
- **Só redesenha o que mudou** (redesenhar a sala custava ~20 ms): a sala (`_state`), a camada de cima `_over` (escuro,
  janela, neon, sombra do papel, luzes no `Bloom`), a do relâmpago (`_bolt_layer`, força no `modulate`), a frente do
  relógio (`_clock_face`, textura trocada no lugar), os objetos da mesa (`_props_layer`, redesenhada logo depois da
  sala), a persiana (`_blind_layer`), o objeto erguido sob o mouse (`_lifted`), a ponta do bilhete (`_tip`), o sol
  (`_sun_layer`), as sombras da luminária (`_shade_layer`), a parede (`_wall_layer`, `_wall_glow`) e a poeira
  (`%Dust`, 30 quadros por segundo). Algo novo que muda entra no estado da camada certa.
- A vista da janela tem tela própria (`_vport`, `UPDATE_ONCE` a cada quadro dela, 30 por segundo), em partes: o céu
  (`_sky`), a de trás (`_back`, só quando muda, `_back_state`), a luz do sol no chão (`_street_mul` multiplica,
  `_street_add` soma), o que fica em pé (`_upright`), a rua molhada (`_wet`, na chuva e no sereno da manhã, a cada
  quadro: `wet_street.gdshader` espelha o que está aceso embaixo dela, virado no pé das fachadas, cortado por quebras
  horizontais de 1 px (nada de manchas: lê como mancha), com poças, anéis e respingos pela força da chuva, o meio-fio e o relâmpago; o letreiro e as luzes da frente por cima, `_wet_sign`,
  `_wet_streak`; o reflexo de quem passa tapa o espelho, `_wet_shade`, um quadro depois; `_draw_wet_street`)
  e a da frente (`_draw_city_front`, a cada quadro). O `SceneView`
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
  `card_out`, `counting`, `tickets`, `toll_desk`, `news`, `letter`, `written`, `sips`).
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
- **Lá fora acontece coisa** (`_events`): carros, gente a pé (`_walkers`, `_draw_walker`; a passada de perfil, `_gait`, `STRIDE`, também a do homem e a das silhuetas, `_body`; quem está lá dentro contra a luz, o recepcionista, o porteiro, quem está no bar e quem passa atrás da janela, no corpo da rua escurecido, `_draw_backlit`; a cena da rua da noite 3, `Beating`, `_draw_rig`, com o sangue que fica, `_draw_blood`, e quem assiste, `_watch`; a viatura da noite 7 no hotel, `PATROL_*`, `_draw_patrol`; o vigia da noite 9 no terraço, `LOOKOUT_*`, `_draw_lookout`; o toque de recolher das noites 9 a 14, `CURFEW_*`, a viatura varrendo as calçadas com o holofote, `_aim` (procura aos trancos e acompanha quem pega), a luz na camada `_spot_add`, clareando o que está embaixo (`spot_light.gdshader`, `_draw_sweep_light`, por baixo dos carros e de quem passa), a sombra de quem ele pega na fachada (`_draw_beam_shadows`) e a pessoa acesa de frente (`_beam_at`), e quem foge para a esquina ou para a porta do hotel, `_hurry`, `_take_cover`; o carro de som da 5, `SPEAKER_*`, e quem para para ouvir, `_listen`; os panfletos da 6 e os três varredores, `Flyers`; a corrida da 8, `Chase`; a pichação da 4 e a tinta da 7, `Graffiti`; o desfile da 10, `_draw_army_truck`; a banca lacrada da 12, `Newsstand`, com o porta-malas abrindo, `"lid"`, e quem carrega por cima do carro, `_draw_loaders`; a batida no hotel da 13, `Raid`: o camburão (`"camburao"`, `_draw_camburao`, as portas do cofre abrindo, quem sobe some para lá da beira dele) e a viatura atrás, as portas das cabines do lado de cá (`_draw_cab_door`), quem está na rua desenhado com os carros (`_draw_raid`, `_raid_clip`) e os andares do hotel acendendo (`Raid.floors`); as sirenes paradas iluminam a rua, a fachada, quem o facho pega, o molhado e a sala (`_beacons`, `_draw_beacon`, `_draw_beacon_light`, `_beacon_at`, `BEACON_*`); a fuga da família da 14, `Moving`, com a varanda (`_draw_packer`, `_apt_gone`) e a Kombi encostando no meio-fio (`"park"`, o z mudando enquanto freia); a pedra da 14 às 23h, `Stone`, subindo da rua, trincando a parte esquerda do vidro, quicando e caindo (`_crack`, por cima da vista, `_crack_box`; o som `glass_hit`; o trincado fica na 15); o sinalizador da 15, `Flare`, na camada `_flare` entre o céu e a `_back` com a fumaça em bolotas (`Flare.smoke`, `puff`) e o halo liso somado (`_flare_add`, `_flare_halo`, maior no ar molhado, `FLARE_WET`), a barriga das nuvens perto dele (no halo, `_cloud_shapes`), a beira da igreja e dos prédios de longe virada para ele e, na chuva, o reflexo dele no asfalto (`_flare_rim`), as cornijas, a parede e o chão da rua do cruzamento na camada do holofote (`_draw_flare_light`), o tom vermelho no `modulate` da cidade fora do `_day`, a janela dele na sala pela camada do sol (`_flare_steep`) e quem olha para o céu, só quem está na luz dele, `_flare_reach`, `_skyward`; ao acender, `flare_lit` e o marcador `sinalizador_N`; a bandeira da 15 à meia-noite, só com o golpe vencido, `Banner`
(a luz do apartamento vazio acendendo, `_banner_on`, quem a estende pelo rig com o rolo, `"roll"`, `_draw_banner_man`,
o pano em colunas com as pregas no vento e a luz do poste, desenrolando, quicando e assentando, `_draw_banner`; os
sons `latch` e `unfurl`); o homem de sobretudo das noites 13 e 14, das 22h às 22h50, embaixo do poste da esquina do
prédio de tijolos (`stranger`, `MAN_*`, `_draw_stranger`, fumando); o fim da presa, `Arrest` (o homem atravessando
para a central, `_draw_arrest` em duas vezes, antes e depois dos carros, `_arrest_rig` recortado atrás do arbusto, e a
viatura parando na mão de cá, `_arrest_car`, com dois policiais), posto pelo `Main.start_ending`: cada uma num script sem estado, pelo relógio `_scene_t`, posta por `scene_at`/`_start_scene`, e as que deixam marca seguem nas noites seguintes, `left_behind`; figuras pelo `_scene_figs`, as mais perto que os postes de lá desenhadas depois deles; quem anda até um lugar, `Beating.walk`), quem sai do bar, quem fuma
  na varanda (as portas abrem para quem passa: a do bar, `_bar_t`; a do hotel, `_draw_hotel_door`, por quem chega a
  ela no `_door_clip`; a da varanda, `_draw_balcony_door`; `_swing`), gato, bicicleta, ônibus, táxi no hotel, vira-lata, mariposas; os telefones da lista vistos dela
  (`CALLED`, `phones`); **o homem do poste** chega e fica embaixo dele (`stranger`, `MAN_*`; nenhuma noite o chama até o passo 8 do roteiro). Gente e carros
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
- **Equipamentos das burocracias**: cada um é uma cena de `scenes/ui/equipment/` posta por `set_equipment`, na
  prateleira embaixo do bloco interurbano (`bay_rect`, tampada até o primeiro chegar, `_draw_cover`, `shelf_used`; até
  46 px de altura, o vão do pé do painel até o interurbano) ou, com `metadata/side` na cena (0 no alto, 1 embaixo), na
  coluna à direita das tomadas, depois do friso (`side_rect`, 65×222, sob uma tampa lisa até chegar o primeiro,
  `side_used`, `_draw_plate` sem letra; o painel, a faixa do alto e as abas ficam em `SIZE`). Os da B4 (`scripts/ui/equipment/`, desenhados com `cassette.gd`, a fita em pé de lado, 12×100, na escala dos
  plugs): o gravador vertical no alto (a lombada na fenda com o nome e a hora escritos de lado; vazia, a fenda tem a tampinha de mola dos toca-fitas de carro, `_flap`; VU, contador,
  lâmpada e a tecla REC vermelha que trava, `Tapes.rec`, também pela tecla R, e solta sozinha no fim da conversa gravada;
  com a fita cheia, `Tapes.full`, a lâmpada pisca devagar, `_blink`; gravando conversa não pedida, a faixa da etiqueta
  sai riscada, `Cassette.standing(wrong)`, também deitada na pilha;
  sob o mouse, a fita mostra uma etiqueta de fita crepe à esquerda da coluna, `_draw_tip`; clicada, a gravada sai para a mesa e a virgem
  volta ao compartimento, `Fly.BACK`, `Tapes.put_back`) e o compartimento embaixo (`tape_rack.gd`,
  antes do gravador na árvore: a fita voa por cima), uma caixa funda de plástico branco com três fitas em pé, a beira
  da frente tapando o pé delas; os lugares são os do modelo (`Tapes.slots`; cada fita tirada, uma `Tape`, sabe o
  dele) e o clique tira a apontada (`Tapes.insert(i)`: ela sobe
  dentro do vão desenhada pelo compartimento, `RISE_SEC`, e o gravador a puxa para a frente, `FRONT_SEC`, e segue); a
  devolvida volta ao lugar reservado (`hold`) e afunda (`land`). O voo para a mesa é do gravador (`tape_recorder.gd`, `_fly`): tomba de lado no meio do caminho e encolhe até
  a pilha entre a mesinha do calculógrafo e o bloco de fichas (`Background.tapes_out`, o destino de cada uma, `tape_spot`,
  `_draw_tapes`; embrulhada, o pacote no `_art_tape`). A pilha é objeto de clicar (`TAPES_ID`, `tapes_clicked`): abre de
  perto, acima dela (`tape_pile.gd`, cena `pilha_fitas.tscn` no Main), as fitas deitadas (`Cassette.lying`) num papel
  (`NotePanel`) com Dar a Sebastião, Dar às autoridades (viram o pacote, `Cassette.parcel`: branco de carta ou amarelo
  com risco azul, `Pal.PARCEL_*`) e Descartar (`InkButton`): a descartada cai para fora da tela, sem som. A mesa não sabe o que cada um faz.
- **Broches** (`badges.gd`, `%Badges`): almofada de feltro deitada na prateleira, logo depois do tampo dos equipamentos (`pad_x`, `edges`, `_spot`;
  o `test_layout` confere a folga), com etiqueta e papel numa camada por cima (`_pop`). O tampo dos equipamentos antes
  dela é curto (`BAY_W`, a pedido: vazio, não servia para nada).
- **Discador** (`dialer.gd`, `%Dialer`): deitado à direita da almofada, no meio do vão até o fim da prateleira (`Switchboard.dialer_x`, `DIALER_W`), linha a linha na
  inclinação dela como a almofada (`_flat`, `_slant`): caixa creme, placa oliva, visor com o número (`PixelArt.tiny`),
  lâmpada de linha e teclado (Discar `Pal.CALL_CAP`, Encerrar `REC_CAP`); o clique abre o de perto num pop-up em cima dele (`dial_view.gd`, `Dialer.view`): o visor em sete segmentos na tela do console, a lâmpada e as teclas do console (`DigitKey`,
  `CallKey`, `RedKey`, `KeyCapStyle`), as letras na etiqueta.
- **Fios** são cordas de Verlet, uma por ponta (`Cord`, `scripts/ui/cord.gd`, sem tela nem som, testada sozinha):
  presas no buraco (`hole(e)`) e na traseira do plug; o contrapeso puxa a folga para dentro (`WEIGHT_TAKE`); todos com
  o mesmo comprimento (`Cord.MAX`); a prateleira e a beira dela são quinas (`hang_step`, `lip_y`, `route`); os plugs
  encaixados das outras pontas são pinos (`Cord.pegs`, `Switchboard._pegs`, `Cord.clear`: o fio encaixado contorna ou
  se apoia, nunca atravessa, agarrado neles, `PEG_GRIP`; na mão, só a metade do lado do buraco, `HELD_LIE`; solto, não; o plug encaixado numa tomada tapada por um fio
  levanta o fio, que corre por cima dele sem esbarrar e é desenhado depois, `_draped`; um plug só apoia o fio por cima:
  enganchado por baixo dele, o fio escorrega pela frente e passa a correr por cima, `Cord.hook`, `HOOK`); fio parado dorme (`SLEEP_STEPS`). Ordem do desenho: fileira por
  fileira, de trás para a frente, os encaixados que saem dela e os guardados nela (o fio passa atrás dos da fileira dele e dos da frente, na frente dos de trás), depois os da mão e os soltos. No desenho: dobras do pano (`_kinked`), trançado (`BRAID`, uma chamada,
  `draw_multiline_colors`), curva Catmull-Rom (`_smooth`); dormindo, imagem pixel a pixel guardada (`_rope_image`);
  a sombra no fio de baixo onde se cruzam (`_cross_shade`, `CROSS_SHADE`, em polígonos do `Geometry2D`).
- **Plugs**: limpos, de plástico cinza com a ponta prateada, uma faixa na cor do cabo e a capa flexível afunilando
  até o fio (`PLUG_ART`, `_plug_pal`; a cor do par fica no fio e na faixa), girados pelo RotSprite em passos de 5° (`PixelArt.turned`); encaixados, de cotovelo
  (um tubo em 3D pelo eixo, `_elbow`: a ponta de metal na boca, o corpo duro com a faixa do cabo em anel,
  `ELBOW_BAND`, a curva de borracha e a capa de frisos; largura igual de qualquer lado), com paralaxe na curva
  (`_tilt`, `ELBOW_Z`) e a capa articulada na física
  do fio (`Cord.pivot`: o peso dela e o contrapeso; balança com ele; `_elbow_pose`, `_elbow`, `_draw_elbow`,
  `_elbow_pegs`); na mão balançam
  como pêndulo (`_swing_step`); soltos voltam ao buraco e assentam (`_seat`). Clique (apertar e soltar parado, em
  `CLICK_SEC`, sem andar `CLICK_PX`) desencaixa; plug só se move arrastando.
- **Sons da mesa** pelo lugar na tela (`_sfx`): o atrito do fio (`Sfx.cord_rub`, barramento Rub, pela velocidade do
  fio entrando ou saindo), `drop`, `thump`, `cord_stop`, `cord_snag`, `cord_snap`, `cord_tap`, `cord_knock` (o fio
  caindo num plug encaixado, `Cord.knock`, `KNOCK_SPEED`; o plug afunda um instante, `_knocked`, `KNOCK_PX`).
- **Quatro camadas, cada uma só redesenha quando o `_look` dela muda**: o painel (`_draw`), as lâmpadas (`_lamps`,
  que registram as luzes e os plugs que as cobrem no `Bloom`), as tomadas dos destinos com a luz da sala (`_top`) e os
  plugs com os fios (`_cords`, a cada quadro só com algo se mexendo). Desenhe em `_ci`.
- Lâmpadas de vidro leitoso que acendem rápido e apagam devagar (`_fade`, `LAMP_ON_SEC`/`LAMP_OFF_SEC`); encaixes de
  pixel art, cromados (`_jack_tex`, `JACK_METAL`); luz da luminária no painel (`_draw_room_light`) e escurecendo junto com a da sala
  pelo `modulate` (`Switchboard.dim`); a luz das lâmpadas no painel pelo `_glow`.
- Visual retrofuturista (série Ruptura): móvel de plástico branco-creme de cantos redondos, pixel a pixel
  (`_shell_frame`, `Pal.SHELL`, `Pal.cabinet`; a lateral segue o arco, `Background._round_edge`), painel verde-oliva
  (`Pal.BOARD_METAL`/`BOARD_FACE`), chaves de escuta como teclas ciano (`_draw_levers`, `KEY_CAP`), faixa escura no alto
  (`_draw_header`) e abas das seções (`_draw_rule`, `RULES`), trilhos finos nas colunas (`_draw_strips`), plaquinhas
  creme (`BOARD_TAG`), bancos, interurbano e tampas rebaixados, escuros e de cantos redondos (`_draw_inset`,
  `round_rect`, `ROUND`), emblema oval da companhia ao lado do interurbano (`_draw_badge`), letras em creme
  (`BOARD_INK`), lâmpadas de plástico fosco num aro creme (`_draw_lamp`), tampas da prateleira de plástico creme
  (`_cover_px`), etiqueta do fabricante impressa (`draw_maker_plate`); limpo, sem desgaste nem parafusos. O gravador
  da B4 segue a mesa (branco, frente oliva, teclas ciano). O console no cenário é a
  bandeja do teclado: plástico branco com uma placa oliva rebaixada (`Background.SHELL`, `BOARD_SIDE`). Banco
  interurbano (`_draw_trunks`). Mexendo na altura, confira que a coluna da esquerda cabe (até 540).
- Folha de prévia de toda a pixel art: `Godot --headless --path . -s tools/sprite_sheet.gd` → `build/sprites.png`.
