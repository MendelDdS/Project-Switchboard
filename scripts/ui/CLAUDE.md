# scripts/ui — o cenário e a mesa comutadora

Complemento do `CLAUDE.md` da raiz, lido ao mexer nos arquivos desta pasta.

## O cenário (`Background`, a sala e a vista da janela)
- A vista da janela muda com a noite: cada janela acesa da cidade apaga numa hora sorteada,
  sempre a mesma (`SLEEP`; algumas ficam acesas); a igreja não tem luz (a porta e o relógio da torre acesos saíram, a
  pedido). **Luz e vinheta lisas, sem camadas** (em degraus pareciam artificiais, a pedido do usuário): o brilho
  (`%Glow`) e a vinheta são degradês contínuos com filtro linear; o arco na parede e a poça na mesa são desenhados com
  a cor variando ponto a ponto (`Background._light_fan`), não em polígonos empilhados; **Clima noir**: fora da luz da luminária a sala fica fria e
  escura (`NOIR`, num shader na camada `_noir`, logo abaixo da `_over`, `room_noir.gdshader`, `_noir_params`: a luminária
  piscando ou esquentando só muda um parâmetro, sem redesenhar; liso, crescendo da poça de luz na mesa para fora numa elipse larga, `GLOOM_IN`/
  `GLOOM_R`, sem borda marcada, a pedido: a mesa toda, com o relógio, fica na luz e a parede do fundo mais escura; o
  vidro da janela abaixo da persiana fica de fora, `_glass`), a luminária é mais forte no centro (arco, poça e `%Glow`) e
  da janela vem um brilho azul bem fraco (`_draw_window_glow`, `WINDOW_GLOW`; as faixas de luz da persiana na parede
  foram testadas e saíram a pedido). **Lá fora acontece coisa** (`Background._events`, tempos sorteados, sons vindo
  da janela): um carro passa na rua da vista com os faróis (`CAR_*`, som `car`; a luz deles varrendo a sala
  saiu a pedido, não parecia luz; na
  chuva, `car_wet`, o pneu no molhado pela janela fechada, `SfxSynth._wet_tires`: chiado liso que escurece
  ao passar, `WET_SWEEP`, sem agudos, `WET_TOP`, o chapinhar grave e respingos de poças, `WET_SPLASHES`; chega devagar e
  some rápido, `_passes`, `CAR_PEAK`; o chiado que pulsava 6 vezes por segundo soava como motor e saiu; o da mão de
  cá, `car_near`/`car_wet_near`, mais claro, com mais Doppler e a passagem mais concentrada, `WET_NEAR`,
  `CAR_NEAR_SHARP`; cada um em `CAR_TAKES` versões, `id~1`..., sorteadas ao tocar, `Sfx._take`); gente passa a pé pela calçada de lá, várias ao mesmo tempo e às vezes
  em dupla (`_walkers`, `_walker`: cada um com o seu passo, altura e distância das fachadas; a roupa: vestido ou calça,
  casaco curto ou comprido, bolsa ou pasta, nas cores apagadas da noite, `Pal.WALK_COATS`...; guarda-chuva na chuva e, sem ela,
  chapéu, boina, lenço ou nada; na escala nova, pedido 257, os braços balançando com o passo, a mão, os sapatos, a barra e a
  gola do casaco e o cabelo, uma peça de 1 px cada; o homem do mistério continua preto), contra as luzes (`WALK_*`, `WALK_STEPS`, `_draw_walker`; perto de um poste,
  a luz dele acende a beira de cima e o lado virado para ele, `RIM`, só o lado nas peças finas; na chuva, eles se
  espelham na calçada molhada, apagados e sumindo para baixo; de vez em quando alguém sai do bar: a porta ao lado da
  vitrine abre, a luz do salão sai pela calçada e a pessoa segue junto das fachadas, `BAR_*`, `_bar_t`, `_draw_bar_door`;
  de vez em quando alguém fuma na varanda do apartamento, na frente da janela da TV, com a brasa acendendo a cada
  tragada, `SMOKE_*`, `_smoke_t`, `_draw_smoker`, e a fumaça (`_draw_smoke`): o fio da brasa com o cigarro na mão e o
  sopro da tragada, uma nuvenzinha de grãos que sobe até a parede escura acima da janela (na frente da janela acesa
  ela sumia), abre e vai com o vento (`GUST`), pegando a luz quente do poste da esquina perto dele (`SMOKE_LIT`); em metade das noites, sorteadas pela noite, um gato sentado na
  marquise do hotel ou no gradil da varanda, piscando os olhos, `CAT_NIGHTS`, `_draw_cat`, uns pixels a mais que o
  tamanho de verdade; bicicletas junto do meio-fio de lá, às vezes com a campainha, `BIKE_*`, `_draw_bike`, nos
  `_walkers` com "bike"; o ônibus da linha passa nos horários dele, `BUS_TIMES`, pela mão de lá, um modelo de
  `CAR_KINDS` nunca sorteado e mais lento, `sec`; duas vezes por noite, nas horas sorteadas pela noite, antes das 22h (`TAXI_STOPS`,
  `_taxi_times`), um táxi da mão de lá freia e para um pouco antes da porta do hotel (`_taxi_x`, `_taxi_mid`, `TAXI_STOP`), o passageiro desce do lado da calçada e vai com a mala até a
  porta acesa, sumindo nela (`_draw_guest`, `GUEST`), a porta do carro bate (som `car_door`) e ele sai acelerando; de
  vez em quando um vira-lata caramelo trota pela calçada de lá (sem chuva e só até as 22h, como os pedestres; `STRAY_*`, `_draw_stray`, nos `_walkers`
  com "dog": escuro, sumia na calçada); nas noites limpas, mariposas em volta das cabeças acesas dos postes, pontos de
  1 px em voltas tortas (`MOTHS`, `_draw_moths`); **a vista mostra os telefones da lista** que se veem dela,
  `CALLED`: transferida a ligação para o Hotel Estrela ou o Bar do Zé, alguém vai até o telefone enquanto ele toca
  (num lugar fechado ninguém vem, `Main._quiet`) e fica com o fone na orelha enquanto a conversa dura, no saguão,
  pela porta, e atrás da vitrine do bar, `phones`, `Main._phone_state`, `_draw_phones`; a ligação não sabe o número de
  quem liga, então só o lado de quem atende aparece; sem som: os
  passos, de dentro do prédio, não se ouviriam, e saíram a pedido), cada vez menos das 18h às 22h (`WALK_FROM`/`WALK_UNTIL`) e, daí em diante,
  ninguém; **o homem do mistério chega andando** pela calçada (`MAN_FROM`), fica parado embaixo do poste da esquina
  15 min de jogo (de `Main.SHADOW_LEAD` a `SHADOW_LEAVE` antes da ligação desconhecida: sai para ir ligar;
  `Background.stranger`, na hora do dia) e volta andando por onde veio (`_man_x`, `MAN_WALK`; sai da
  hora do jogo, então pausa e pulo do relógio valem para ele); das 22h à meia-noite os carros ficam cada vez mais
  raros (`LATE_FROM`/`LATE_TO`, `LATE_EVERY`); gente, carros e o vaivém do bar seguem o dia da semana da noite
  (`BUSY`, `weekday`: mais na sexta e no sábado, menos no domingo; pedido 281); o sino da
  igreja bate as horas de longe, logo depois do gongo da mesa (`toll`, `BELL_AFTER`, `BELL_GAP`, som `bell`); das 21h em diante,
  cachorros latem bem longe, de vez em quando, e às vezes outro responde (`DOG_*`, sons `dog` e `dog_low`, abafados e com
  o eco dos morros; calados antes da ligação desconhecida, `Sfx.hushed`); na
  chuva, o relâmpago clareia o céu e a vista em pulsos (`BOLT_*`, `_flash`) e acende na sala só o que a janela alcança,
  numa camada somada por cima de tudo (`_bolt_layer`, `_bolt_build`; a força é o `modulate`, o desenho fica): quase
  branco (`BOLT_LIGHT`; era um véu azul na tela inteira, até na frente da mesa comutadora), na parede do fundo, mais
  forte perto da quina, com a sombra do armário à esquerda dele (a caixa dele levada até a parede, `BOLT_DIR`), na
  frente do armário, na lateral da mesa comutadora e no tampo, a janela desenhada nítida com a cruz do caixilho
  (`BOLT_STEEP`); o que fica na frente (a mesa comutadora, os objetos da mesa: `_occ`, `_occ_board`; o tampo) sai do
  clarão (`_cut`). E o trovão vem depois
  (`THUNDER_AFTER`, mais fraco quanto mais longe, som `thunder`; perto, o vidro e a persiana chocalham, `RATTLE_NEAR`,
  som `rattle`); e um letreiro de neon do Hotel Serena (o nome e a palavra são os mesmos nos
  três idiomas) na vista, de bandeira, no estilo dos letreiros de neon antigos (pedido 287, pela referência do
  usuário): pendurado por três suportes na lateral do prédio do hotel, na rua do cruzamento, antes da primeira coluna
  de janelas (`SIGN_Z`, `SIGN_GAP`), e de frente para a central; na face de frente, um plano de z constante, ele sai
  reto sem trapaça. Peças em `_sign_layout` (`Neon`; feito uma vez, em px a partir da parede, `_sign_parts`, e posto
  na vista por `_sign_cells`): a bandeira de metal cinza-escuro (`Pal.SIGN_BOX`; vermelho-escura parecia vinho, pedido 289) com SERENA de cima para baixo, em 5 × 6
  (`SIGN_GLYPHS`; nas de 5 × 8, as da fonte de 11, ficava grande demais, pedido 288), a caixa mais larga em cima com HOTEL deitado, na fonte miúda da mesa
  (`PixelArt.TINY`), e a lua crescente em cima dela (`SIGN_MOON`); cada letra com o tubo quase branco (`Pal.SIGN_HOT`)
  e o brilho em volta, num vermelho mais escuro (`Pal.SIGN_GLOW`: no da luz, a caixa toda parecia vermelha), a um
  pixel da beira da caixa (o friso de neon na beira saiu, pedido 290, e o letreiro ficou menor), e, à direita, a
  grossura na sombra; apagados, os tubos ficam no tom deles, sem a luz (`SIGN_HOT_OFF`, `SIGN_MOON_OFF`). Antes ele ficou
  na fachada, virado para a rua do cruzamento (pedidos 283 a 286): visto quase de lado, era uma faixa estreita de beira
  inclinada; reto, sem perspectiva, não agradou. O halo do `Bloom` tem a forma dele (`_sign_shapes`: as caixas, em
  T, num halo só, `Bloom.light` com `parts`, e a lua num halo amarelo, redondo; num retângulo, ficava quadrado,
  pedido 289); o resto da luz dele sai do retângulo das peças (`_sign_box`), e a lateral do prédio, onde ele está
  pendurado, fica vermelha em volta dele (`_draw_sign_wash`, `SIGN_WASH`); no vidro, só os tubos se refletem. Falha de vez em quando (`_sign_on`; uma letra, o R, falha sozinha, `SIGN_BUZZ`, `_sign_buzz_on`; sem som: o estalo dele saiu a pedido), com o
  halo sem miolo para as letras aparecerem (`_light(..., core = false)`), o reflexo na rua molhada (embaixo das letras, não da beira da caixa) e a luz
  vermelha dele no vão, no peitoril e na persiana, com a dos postes de lá acesos (`_window_lights`, num shader,
  `window_lights.gdshader`, até 8 luzes, `SIGN_LIGHT`, `POST_LIGHT`: entre a persiana e os objetos da mesa, que ficam na
  frente; o vidro de fora; só os parâmetros mudam, `_window_light_list`, sem redesenhar a sala). Na mesma camada, as
  lâmpadas acesas dos objetos da mesa (a ocorrência e o cartão na unidade de despacho, a do calculógrafo) iluminam o
  tampo em volta (`_light` com `spill`, `_spills`, `DESK_SPILL`, `DESK_LIGHT`). Os dois primeiros
  entram no `_state`. No vidro da janela, o fantasma
  dele: as letras de novo, fracas e 1 px deslocadas (`_draw_neon_glass`, `NEON_GHOST`, `NEON_SHIFT`; com 5 px, nas
  letras da fonte de 11, caíam em cima das de verdade e o letreiro parecia escrito duas vezes), com a letra que falha junto,
  e, na chuva, as gotas perto dele vermelhas (`NEON_BEADS`); desenhados na vista, que já se redesenha. O prédio de tijolos da esquina é
  de apartamentos: no 3º andar, uma varanda (`APT`; porta, vasos, laje vista de baixo e gradil) com a janela da sala,
  onde a TV pisca azul (`_draw_balcony_back`/`_front`; a luz da sala apaga em `APT_DARK` e a TV em `TV_OFF`). Janelas que já
  apagaram acendem de novo de madrugada, uns minutos (`WAKE`, `b["wake"]`). O térreo das lojas de lá (fora do bar e da marquise do hotel) tem o batente, a tábua da placa
  com as letras só em traços (`Pal.SHOP_BOARD`), o toldo de lona com a franja numa em cada duas (`Pal.AWNINGS`) e, fechada,
  a grade na frente do vidro (`_draw_shop_trim`). No de tijolos, mais janelas acesas até depois das 22h
  (`BRICK_LIT`, num sorteio à parte), vasos no peitoril e uma gaiola numa acesa, alguém passando atrás de uma delas de vez em
  quando (`_indoor`, `BEHIND_EVERY`, `BEHIND_SEC`, `_draw_behind`, na frente da vista) e as acesas no `Bloom`, fracas e sem
  miolo (`_flats`, medidas pela sala no vidro, que se redesenha uma vez quando a cidade é montada, `_city_for` no `_state`;
  na camada de cima, com as acesas no estado dela). `_win_lit`/`_win_rect` dizem se uma janela de lá está acesa e onde. Na chuva, a força muda durante a noite
  (`rain_level`, `RAIN_*`: garoa a forte, em ondas lentas): o som (`Sfx.set_rain`), a quantidade de pingos no vidro, o
  vento no arbusto e os relâmpagos (só acima de `BOLT_RAIN`); as poças crescem com a noite (`_soaked`). O arbusto
  balança em rajadas (`GUST`). Na noite limpa, a lua sobe (`_draw_moon`, `_moon_at`, `MOON_RISE`, `MOON_PATH`, `MOON_DRIFT`):
  nasce às 18h atrás da igreja, grande e alaranjada no horizonte (a ilusão da lua no horizonte, `MOON_BIG`,
  `Pal.MOON_LOW`), volta ao tamanho dela ao subir (`MOON_SHRINK`) pelo vão entre os prédios da esquina e some atrás da
  persiana (alta, `BLIND`) às 22h15; desenhada antes da cidade, que a cobre. Nuvens passam por ela (`CLOUDS`), e
  coberta ou já sumida ela apaga junto o brilho azul da janela na sala (`_moon_light`, `_moon_glow`, `MOON_DIM`). Na
  névoa ela também sobe, mas difusa: o disco quase apagado e um clarão largo e liso por cima do véu da névoa
  (`_fog_moon`, desenhado em `_draw_fog`; `FOG_MOON`). Na chuva, o céu é nublado (`_draw_overcast`): um fundo de nuvem
  clareando para o horizonte pela luz da cidade (`Pal.OVERCAST_DECK`, `Pal.OVERCAST_LIT`), nuvens grandes e vãos escuros
  (`Pal.OVERCAST_DARK`) passando com o vento (`OVERCAST_SPEED`, `_overcast_x`, no `_back_state`), acesas pelo relâmpago. A fase é a do calendário de verdade na data do jogo (`_moon_age`, `SYNODIC`, `NEW_MOON`:
  crescente quase cheia na noite 1, cheia no dia 11, minguante até a noite 15), com a luz do lado do hemisfério sul
  (`_moon_art`, guardada por idade); o brilho da janela na sala segue o quanto ela está acesa (`_moon_lit`). O vidro embaça nos cantos e no pé, liso
  (`_draw_mist`, `MIST`, na camada de cima; menos na chuva forte). Na chuva, as gotas do vidro fazem sombra na luz
  da rua na mesa, só manchinhas sem borda, porque a luz é fraca (`_draw_drop_shadows`, `DROP_SHADOW`, na camada da poeira). No começo do turno a
  luminária esquenta (`warm_up`, `WARM`): acende fraca, a sala mais escura (`WARM_DARK`) e o brilho alaranjado
  (`Main.WARM_TINT`), e chega à luz inteira em 4 s. O painel da mesa comutadora escurece frio nos cantos
  (`ROOM_DARK`); interface, papéis e painel de baixo não escurecem (precisam ser lidos); o céu da vista clareia liso
  para o horizonte e a luz do poste atrás da silhueta também é lisa. **O vidro da janela reflete a sala**
  (`_draw_reflection`, por cima da cidade e da silhueta, antes da chuva): a sala espelhada no plano do vidro e vista
  pela mesma câmera (`_proj` com x espelhado); de lado como ele está, só aparecem o canto da parede do fundo perto da
  quina, com o fim do arco de luz, e o armário se cair ali (`_cab_x0`); a luminária e a mesa ficam fora. Liso e
  acompanhando a luminária. A vista passa da borda de cima da tela e só aparece do horizonte (58%
  dela) para baixo: o que for desenhado nela tem que ficar ali. **Traços dos objetos em pixel art** (`_pixel_line`:
  um pixel por passo, com a espessura empilhada em cores, desenhado na tela e não na perspectiva torta do tampo): o
  lápis do caderno, o rio do mapa, as fendas do relógio e os filetes das listas. **Poeira no feixe da luminária**
  (`_motes`, `DUST`; desenhada a 30 quadros por segundo sem redesenhar a sala): grãos de um pixel em toda a área que a
  luminária ilumina (a do brilho `%Glow`, um círculo largo a partir do alto do meio da tela, que passa por cima da
  mesa comutadora; o arco na parede é estreito no alto e deixava sem poeira a parede acima dela), mais claros perto
  dela. Ficam na camada `%Dust` do Main (`Background.dust`, z 1, depois do
  `Layout`): acima da mesa comutadora (no cenário, ela cobria a poeira que passa na frente dela), fora do papel das
  ferramentas e nunca abaixo do fundo do tampo (o painel de baixo fica fora da sala). **O feixe da luminária no ar**
  (`_beam`, `_draw_beam`, `LAMP_BEAM`, `LAMP_BEAM_CORE`): uma faixa lisa, somada (blend ADD), descendo da boca dela,
  mais densa no meio e sumindo para os lados e até o fundo do tampo, onde a poeira mora; na sala, atrás da mesa
  comutadora, que fica na frente dele. Desenhado com a sala; piscar, esquentar e sumir com o dia (como a luz dela na parede, pedido 279) só no `modulate` (com `_show`). **Pingos** na chuva (`_drops`, `RAIN`): riscos de 1 px inclinados pelo vento (`RAIN_SLANT`)
  que cruzam o vidro em meio segundo (`RAIN_FALL`; o risco é o rastro do quadro, `RAIN_STREAK`), mais longos e claros os
  de perto e acesos perto dos postes (eram traços de 2 px que levavam 5 s para cair, como neve). **Gotas no vidro** na chuva (`_beads`, `BEADS`): paradas, de vez
  em quando pesam e escorrem com um rastro; o brilho delas é quente perto do poste. Só na parte do vidro que aparece
  (`_glass_from`: abaixo da persiana e da borda de cima da tela). **O painel de baixo fica fora da luz da sala**: é um
  menu, não parte do cenário; a vinheta (`Vignette`) termina onde ele começa (`offset_bottom`), e o brilho da luz de
  teto já fica só na tela do cenário. Não troque a base para 1920×1080 (tudo fica 2/3 do tamanho).
  **Disposição (cena + painel)**: a tela é uma mesa de trabalho. No alto da esquerda, o horário do turno num
  papel colado com fita na parede (`ShiftPlate`, variação `TapedNote`, com o horário e o botão Encerrar turno; era uma
  plaqueta de latão; a faixa dele, `TopLeft`, tem no mínimo 42 px, a altura do bilhete com o botão, e cresce com a altura que a mesa comutadora não usa: a parede acima dela, com o bilhete no alto; era 52, e os 16 px que saíram dela e da margem de cima foram para a prateleira) e, à direita dele, na parede acima da mesa
  comutadora, a placa esmaltada da companhia telefônica (`Background._draw_company_sign`, `SIGN_COMPANY`). O relógio da sala é um **relógio de flip na mesa** (`Background._draw_flip_clock`, o único da tela):
  caixa de baquelite creme numa base escura, reta, com a frente paralela à tela (`CLOCK`; `CLOCK_TURN` gira para os
  olhos uma fração do ângulo até eles, `_yaw`; foi 0,5: certo na conta, mas a frente descia uns 5° entre as horizontais
  da sala e o lado sumia, e parecia um relógio inclinado numa mesa plana; `_clock_box` desenha as faces viradas para os olhos, `_clock_xz`/
  `_clock_pt` giram os pontos), com fendas e botão niquelado do alarme no tampo, a
  rodinha de acertar no lado e duas plaquetas (horas e minutos, algarismos de 9×19 desenhados à mão, hastes de 2 px e barras de 1, numa folha de
  fonte, `DIGITS`) que viram quando a hora muda
  (`Background.minutes`, o Main atualiza; `_flip_step`, `FLIP_SEC`). A frente é montada reta numa imagem
  (`_clock_face`, `_flip_card`, `_card`) e posta coluna a coluna na perspectiva exata: cada coluna da tela é um raio
  dos olhos que acerta a frente num ponto e numa distância, e a coluna vai da altura de cima à de baixo ali (torta por
  transformação, os algarismos quebravam; um paralelogramo não batia com a caixa). Ao ouvido: o "tic" de cada plaqueta que vira, quando ela bate (`tick`, `Main._minute`, `FLIP_SEC` depois de
  começar a virar; era um tique-taque a cada segundo real, do relógio de ponteiros, e não batia com as plaquetas, que
  viram a cada 1,33 s), e a badalada de gongo a cada hora cheia (`chime`, `Main._hour`) vêm do relógio
  (`Background.clock_x`) e a campainha de latão quando o turno pode ser encerrado (`shift_bell`), da plaqueta; embaixo
  dela a mesa comutadora (492×304; era 588×362, e com as tomadas na medida dos plugs ficava espaçada e tomava a mesa da sala), a faixa da prateleira (`Shelf`, 32 px; era 16: o painel foi recuado para a parede, a pedido, para os cabos terem respiro; o encaixe do FONE, `%FoneSocket`, e os
  buracos dos cabos, `%CordTray`, com os plugs guardados em pé neles, na frente do painel, como numa mesa telefônica
  de verdade; cada fio repousa na fileira do buraco dele, `floor_y`) e a faixa da frente do console (`%Desk`), com a
  **miniatura do painel de baixo** no meio (`%Mini`, `ConsoleMini`: a tela da conversa, as teclas e o rádio na
  disposição e proporção de verdade dos blocos do `PhonePanel`, copiando o estado: tela acesa com as falas em traços,
  teclas ativas acesas; o rádio peça por peça no lugar das do rádio de verdade, `Radio.parts`, com as mesmas linhas da tela quebradas na largura dela, o histórico apagado em cima e a mensagem de agora embaixo, `Radio.lines`, `_wrap`; o painel de baixo é a vista de perto dela). Ela não tem `z_index`
  próprio: a mesa (z 1) desenha o plug e o fio puxados para baixo por cima dela, como faz com o painel de baixo (com z
  1, eles passavam por trás da miniatura, a pedido saiu). A coluna da
  direita (cresce com a largura) tem a dica do manual no alto, **escondida** (`HintSlot` com `visible = false`, pedido 249:
  ocupava o alto da parede e da janela e quase ninguém olhava; o `Main.hint()` continua escrevendo nela, e as dicas do
  treinamento e da primeira vez não aparecem até decidir onde elas vão) (`%Hint`, um papel datilografado colado com fita na parede, `TapedLabel`, com "MANUAL" carimbado em vermelho; sem dica, o papel some mas o lugar fica; o lugar, `HintSlot`, tem a altura de duas linhas e a dica mais comprida desce por cima das ferramentas, `z_index` 1, sem empurrar nada; no pé, ela ficava em
  cima dos objetos da mesa) e as ferramentas (`Tools`: no `%Body`, o papel da ferramenta aberta; guardadas, a
  janela aparece; sem abas, a pedido: repetiam os objetos da mesa e tomavam 40 px de altura do papel). O papel sai do objeto da ferramenta na mesa (`Tools.origin` = `Background.prop_rect`: pequeno, em
  cima dele, e cresce até o lugar; ao guardar, volta), tem a forma e o material do objeto (`PaperDeco`, a moldura em pixel art guardada por
  tamanho, `_cover`: a capa de papelão mostarda da lista com o grão e o friso, como a da mesa; o caderno é o bloco de fichas de ocorrência (a fita de pano da colagem no alto, `Pal.PAD_TAPE`, a beira das folhas de baixo e o papelão, `Pal.PAD_BACK`), com as
  tiras dos registros pendentes saindo de cima, `pending`; a tábua da prancheta com o prendedor niquelado, `_clip`, e o cabeçalho
  datilografado com o fio vermelho, `HEAD_Y`/`CallLog.HEAD`; o vinco do jornal; no despacho, nada: a moldura de metal da unidade em volta do vidro
  do mapa e a base das máquinas são do `CardMachines`, por baixo do cartão), o papel na cor do objeto (`Tools.PAPER`) e a luz
  da luminária por cima, lisa, mais clara perto dela e escurecendo quando ela pisca (`PaperDeco.light`, `LIGHT_*`; o Main
  passa `Tools.light`); as abas de índice da lista são tiras de papel como as que marcam páginas nas listas da mesa
  (creme; a aberta, vermelha) e o caderno tem a pauta e a margem do caderno da mesa. Aberto, o cenário atrás escurece e ganha a sombra dele (a mesa comutadora e o painel não). Embaixo de tudo, na
  largura toda, o painel do operador (`PhonePanel`, 150 px: a tela da conversa, as teclas e o rádio, nessa ordem), um console embutido na frente da mesa (a madeira de borda a borda logo abaixo
  do tampo, `PhonePanel._draw`; os blocos `HudPanel` são telas e chapas encaixadas; a tela da conversa tem vidro e
  apaga sem ligação, `ScreenGlass`, mas fica esperando como um terminal antigo: "Aguardando chamada" bem apagado
  e o cursor piscando, `idle`, `CONSOLE_IDLE`; o rádio mostra acima da mensagem de agora as anteriores, cada uma mais
  apagada, `Radio.HISTORY`, `_archive`, as que couberem; cada uma com a hora em que chegou na frente, `Radio.minutes`, posto pelo Main). A altura útil é 706 px: as colunas pedem 546 (a da esquerda, exata) e o
  painel 150; passando, a tela inteira sobe e a plaqueta sai por cima. O `Background` (cenário em camadas, em pixels de 1x1 como a interface: as contas em unidades de 2 px e os detalhes finos em `PX`/`_p`; desenhado no `SceneView`, uma tela própria na resolução da janela, que repassa o mouse a ele, `pointer`/`prop_at`/`leave`, e desenha por cima a etiqueta com o nome do objeto sob o mouse, `draw_hover`: uma tira de fita crepe reta, `TapedLabel`, acima dele; era uma caixa preta com o contorno amarelo, e torta saiu a pedido. **O objeto sob o mouse se ergue** 2 px, `LIFT_PX`, no tempo do `Lift`, com a sombra ficando na mesa e se afastando, e, quando o mouse sai, assenta com a batidinha do material, `SET_SOUND`, `set_paper`/`set_metal`; a prancheta pendurada sai 2 px da lateral para a frente. Ele vai para uma camada só dele, `_lifted` (`_lift_step`, `_draw_lifted`), que anda sem redesenhar a sala: a sala o tira quando ele sobe e o devolve quando assenta (`_up_id`, `_here`), guardando o lugar dele para o mouse e o relâmpago (`_mark`), e a camada se redesenha a cada pixel e quando a sala muda; por isso o desenho dos objetos vai sempre para `_ci`) estica
  parede e mesa até a borda, como o canto de uma sala visto de quem está sentado à mesa. **Uma câmera só**, em
  perspectiva de um ponto: o ponto de fuga (`_vp`) fica em `VP_AT` do espaço da mesa, da mesa comutadora à
  quina (perto dos objetos: a inclinação deles cresce com a distância a ele; preso à largura da tela, numa janela
  larga ele fugia dos objetos e as listas apareciam bem de lado; no meio exato das fileiras, a parede da janela
  entrava pela mesa e espremia os objetos). **A sala se distribui na largura que tiver**: entre a mesa comutadora e a
  quina, o armário (`CAB_W`; `CAB_AT` da parede livre antes dele, com o conduíte no meio desse vão) e, depois dele, a
  folhinha com o lugar do cartaz em cima (`POSTER_W`), no meio do vão até a quina; na quina, a mancha de umidade,
  que cresce com as noites de chuva (`damp`, de `Progress.rains`; uma marca de água clara por noite na beira, até 4;
  chovendo, o meio molhado e com brilhos; `_draw_damp`, `_damp_art`); os objetos da mesa em duas
  fileiras de ponta a ponta entre a lateral da mesa comutadora e a parede da direita (`_row`, `WALL_PAD`; a da frente
  para na beira da tela, `EDGE_PX`, porque perto a parede já passou dela e o jornal saía cortado), com a mesma folga entre eles e antes do primeiro
  (encostados na mesa comutadora, pareciam apertados); na da frente, o calculógrafo fica no meio da unidade de despacho,
  alinhado com ela, e o bloco de fichas e o jornal se distribuem do fim dele até a parede. Os lugares do cartaz e do jornal ficam guardados mesmo sem eles, para nada mudar entre as noites.
  (Presos a uma ponta só, sobrava mesa vazia numa janela larga; presos a pontas diferentes, o relógio caía em cima do
  jornal em 1280 e o armário entrava atrás da mesa comutadora.) e `EYE` acima do fundo do tampo, dentro da tela, na altura da janela (era logo acima
  da tela: a mesa vista mais de cima, mas a parede da janela ficava a 44 cm da cabeça e a janela descia uns 40°; com
  os olhos mais baixos, o que fica longe do ponto entorta mais: a inclinação de um lado que foge é a distância ao
  ponto na horizontal dividida pela distância na vertical, e só depende da tela); `_proj`/`_p3` levam um ponto da sala (x, y a
  partir dos olhos, z a distância) para a tela. **A parede do fundo fica a `Z0` × `WALL_K`** (1,4; pedido 249): o que está
  nela encolhe em volta do ponto de fuga (o armário; folhinha, conduíte e marcas, em pixel art, ficam do tamanho deles) e
  a quina na tela (`_qx`) anda para perto dele; o plano da parede da direita continua em `_cx` (onde ele estaria em
  `Z0`), e com ele a mesa, os objetos e a janela: afastar a parede só alarga a parede da direita na tela. **A parede da direita fica em ângulo** (pedido 252): ela tem
  o ponto de fuga dela, `SIDE_VP` px à esquerda do da sala (`_svp`, `_sx`; `_side_pt` e as listras e o friso dela), e
  vai para fora vindo para a frente a partir da quina, que não muda; assim o peitoril e o alto da janela ficam mais
  retos (no ponto de fuga da sala, o peitoril descia 0,54 px por px; agora 0,31). Numa sala retangular não dava: toda
  linha da parede passa pelo ponto de fuga, então só subindo o peitoril (e o canto de longe dele junto). As contas em
  3D da luz que entra pela janela (relâmpago, sol, luz da rua) pegam a parede no meio do vão (`_wall_x`). **A câmera são os olhos do operador
  sentado**: `SEAT_EYE` (45 cm acima do tampo) e `SEAT_BACK` (110 cm até o fundo do tampo; a frente do tampo fica sob o
  console) dão a distância focal, `Z0 = EYE × SEAT_BACK / SEAT_EYE` (a tela já fixa o ponto de fuga e o fundo do tampo;
  só a focal estava livre). Com o antigo 330 a mesa era vista de cima como por alguém em pé (~38° para baixo; sentado,
  ~22–29°), e toda profundidade absoluta saía exagerada (o relógio torto, a lateral da mesa comutadora larga). Os
  objetos chatos têm a profundidade em fração do tampo (`_deep`) e não mudam na tela; com a focal certa, as medidas
  deles na sala ficaram as de verdade (a prancheta mais funda que larga). Na sala: a parede do fundo (sem rodapé nem
  linha escura embaixo: com elas parecia um chão), com um conduíte de ferro levando os fios do alto do painel da mesa comutadora
  para o teto, com a caixa de passagem (`_draw_conduit`, no vão entre ela e o armário), e, no vão depois do armário, o uso de anos: no lugar do cartaz, a marca de um quadro tirado (a tinta mais limpa,
  o encardido em volta) com o prego, e, embaixo da folhinha, uma tomada de baquelite com o plugue e o fio caindo para
  trás do tampo, com o encardido da mão em volta, a faixa encardida rente ao tampo de ponta a ponta e uma rachadura
  fina descendo do friso entre a folhinha e a quina (`_draw_wall_marks`, `OUTLET_UP`, `WALL_GRIME`, `WALL_CRACK`); a parede inteira com manchas leves no reboco (`_stain_art`: o ruído
  em cinza posto no tom da tinta, `STAIN`, guardado por tamanho; a 0,75 pareciam sujeira, a pedido ficaram em 0,35).
  **A tinta num tom só** (`Pal.WALL_PAINT`): a luz da luminária nela é lisa, a do shader e o leque de `_draw_wall_light`
  (no plano hi-bit ela ia em faixas em volta da boca do cone, mais fria longe e mais quente perto, e a beira da de fora
  fazia um arco duro ao lado do armário, que ficava chapado no amanhecer, com a sala clara: saiu, pedido 275). A
  parede e o leque ficam em camadas embaixo da sala (`_wall_layer`, `_wall_glow`, `show_behind_parent`), para o que
  está na frente da parede ficar por cima e o leque sumir com o dia no `modulate`, como as sombras da luminária no
  tampo (`LAMP_SHADE`; desenhado na sala, ele ficava aceso às 6h, pedido 279). O conduíte e o armário ficam cada um
  num degrau só da luz no meio dele (`_wall_step`; o conduíte, em trechos, um por faixa, tinha um degrau no cano,
  pedido 279), com as sombras e as luzes do aço na rampa `Pal.STEEL_TONES` (era o aço escurecido
  e clareado). E um armário
  de aço de chão (`_draw_steel_cabinet`, `CAB_*`; com o guarda-chuva do operador pendurado pelo cabo no puxador,
  `_draw_umbrella`, molhado na chuva, com a água escorrendo na camada da poeira, `_draw_drips`; clicado, a porta da
  direita abre e fecha, `CABINET_ID`, `cab_open`, ao contrário do que o roteiro deixou, e o guarda-chuva vai com ela,
  pendurado do lado de fora; um casaco não cabe na
  escala da sala: tem a largura do armário; a mesa esconde a base; ~1,5 m, o alto acima dos olhos, então o tampo
  não aparece; venezianas em cima e embaixo, o puxador no meio da altura, um amassado e riscos perto do pé; entreaberto, o vão tem fundo, a parede de dentro virada para quem olha, prateleiras até a mesa, as de
  cima mostrando o lado de baixo e as de baixo o tampo, e pastas em pé, e a porta aberta mostra o painel de dentro e a espessura); a parede da direita, entrando para o fundo
  a partir da quina (`_qx`; o plano dela em `CORNER` da área das ferramentas, `Background.window`), mais clara (virada para a luminária),
  com a janela vista de lado (`_draw_side_wall`, `_side_pt`: guarnição, caixilho e persiana na perspectiva da parede;
  **a persiana fecha e abre com um clique** (`toggle_blind`, `BLIND_ID`, a etiqueta diz "Fechar/Abrir a persiana"),
  descendo lâmina a lâmina até o peitoril em `BLIND_SEC`, com o barulho das lâminas, som `blind`; ela fica numa
  camada só dela, `_blind_layer`, `_draw_blind`, com os objetos da mesa na camada de cima dela (`_props_layer`;
  antes as lâminas passavam por cima da borda da caneca), e a cada lâmina (`_blind_shape`) a camada de cima se redesenha: o
  vidro que aparece, `_glass`, encolhe, o brilho azul da janela some e as luzes de lá atrás dela não brilham,
  `_behind_blind`; a sala, só em quatro passos, para a luz da rua na mesa e o relâmpago, `_state`; fechada, o
  relâmpago entra 85% mais fraco;
  sem montante nem travessa no caixilho (saíram, a pedido: o vidro é um só); a janela começa logo depois da quina,
  `SIDE_T`, vai até perto da borda da tela e do alto da tela (`WIN_TOP`) ao peitoril (`WIN_SILL`), que fica à vista
  acima do relógio e da caneca;
  o vão tem a espessura dela, `WALL_D`: sair da parede é andar na horizontal da tela, então aparecem o lado de dentro
  do batente de longe e o fundo do vão (a tábua do peitoril indo até o trilho de baixo do caixilho; escuro, parecia
  um buraco; o que passa do batente de perto é cortado; fora do vidro, o escuro da sala deixava o peitoril e a
  guarnição de perto quase pretos, então a luz de fora os clareia, `_sill_lit`, desenhada na sala antes dos objetos da mesa e mais forte na
  medida do escuro que cai por cima dela depois (`_draw_sill_light`, `_gloom`): pintada por cima do escuro, ela
  atravessava a caneca e o relógio, e recortada pelo contorno deles ficava com o vão da alça escuro; a ponta de perto da
  tábua tem a face dela; o vaso que ficava nela saiu, a pedido), o vidro fica do lado de fora e o batente de perto esconde uma tira dele; o
  peitoril de dentro é uma tábua saindo para a sala, `SILL_D`; o peitoril fica `WIN_SILL` cm abaixo dos
  olhos e o alto `WIN_TOP` acima deles (baixa o bastante para a persiana aparecer abaixo do bilhete do manual); a janela e o armário são medidos
  em cm a partir dos olhos, `_cm`, e acompanham a câmera quando ela muda; a vista da cidade é desenhada de frente num vidro fora da tela, `_vport`, e só recortada
  pelo vidro: está longe e não entorta com a janela; o horizonte dela fica `OUT_DROP` cm abaixo dos olhos, para os prédios ficarem no meio do vidro, abaixo da persiana); a mesa, afastada da
  parede (`DESK_T`), com o fundo do tampo atrás da mesa comutadora (`BOARD_SINK`; ele não sai do lugar quando o painel recua: o painel se aproxima da parede, e a sala e o ponto de fuga ficam onde estão), a borda da frente logo abaixo da
  faixa de mesa (`Background.desk`) e a ponta na parede da direita, numa
  linha que foge para o ponto de fuga. A luz vem de cima, do meio da tela, de uma luminária que não aparece (o
  desenho dela foi tirado a pedido do usuário: `_lamp_x` no meio, `LAMP_Y` acima da tela); ela dobra na quina: na
  parede é o arco do cone (`_draw_wall_light`, `WALL_GAP`), na mesa a poça; o que está na frente da parede faz sombra nela, ampliada
  a partir da luminária (`_cast`); a luz da rua entra pela janela e cai na mesa (`_draw_street_light`): o vão abaixo da
  persiana projetado no tampo, descendo para dentro da sala (`STREET_LIGHT`; mais inclinada, era um quadrado pequeno
  para a janela grande), um pouco longe da parede (o peitoril faz sombra) e só onde há mesa; grande, bem lisa e
  espalhada além da janela, desenhada antes dos objetos da mesa (depois deles, a mancha do tampo passava por
  cima dos que ficam em pé e a caneca parecia transparente; o bloco e o jornal ficam fora do alcance dela). **Os
  objetos da mesa ficam numa camada só deles** (`_props_layer`, `_draw_props_layer`): por cima da sala e da persiana,
  por baixo da camada de cima (o escuro); redesenhada sempre logo depois da sala (ligada ao `draw` dela), porque usa o
  que ela mede, e é ela que monta o que o relâmpago acende (`_bolt_build`, que precisa do contorno deles: o relâmpago,
  somado por cima de tudo, continua recortado por eles, `_behind`, inclusive no peitoril e na janela no tampo). Na mesa, ao alcance do
  operador, os objetos que abrem as ferramentas (`prop_clicked(id)` → `Tools.set_tab`; `_props`, `_has_point`: o
  clique só vale sobre eles e não com papel por cima): listas telefônicas (1: três volumes desencontrados, a lombada com os filetes dourados e a etiqueta do volume,
  o miolo com as folhas em linhas finas, posto pixel a pixel como a capa, `_art_pages`, mais sujo junto das capas, e tiras
  de papel marcando páginas; a capa de cima com o título dourado em
  baixo-relevo, o fone da companhia, a etiqueta com o ano, a marca de uma caneca e a ponta dobrada, `_art_book_cover`), a unidade de despacho (2: `_draw_dispatch_unit`, `UNIT*`: um móvel de metal no
  material das máquinas da ficha, como um terminal antigo; embaixo, a base com as três máquinas no tampo, na disposição
  da ficha aberta, `_art_deck`, e na frente a plaqueta e as luzes; em cima, o painel inclinado com o mapa de papel sob
  o vidro, `_art_glass`: o mapa aberto em miniatura, `_art_map`, com as mesmas folhas, as dos bairros atendidos, na
  proporção delas: quarteirões no tom do bairro, casas e árvores, lugares de telhado de barro, praça, zona rural,
  divisas e o selo; sem nomes, que nesse tamanho seriam ruído; papel sob a luz da sala, não tela acesa, a pedido),
  bloco de fichas de ocorrência (3, `_art_pad`, `PAD_W`: a ficha da noite, que vai para o supervisor; era um caderno
  aberto de 46, que tomava a fileira da frente: a folha de cima com a fita da colagem, `_pad_tape`, o impresso, a pauta,
  a margem, a letra de mão, as tiras e o lápis, `_pad_marks`, que muda de lugar a cada ficha registrada, `written`, `PENCIL`) e
  o calculógrafo (4, `_draw_calculograph`, `CALC`: a ferramenta aberta em miniatura, a máquina das máquinas do despacho
  atrás, sem relógio (o de flip fica ao lado), com os contadores, `counting`, e a fenda embaixo, de onde a ponta do bilhete desce
  numa camada própria da sala enquanto ele é impresso, `_tip`, `Background._draw_tip`; na frente, a mesinha dela com o
  que está na da ferramenta, `toll_desk`: almofada, bilhetes, caixinha, `TOLL_BOX_H`, e o carimbo em pé, `STAMP_ART`, que a camada da ponta desenha de novo por cima dela, `_tip_cover`; a almofada e a caixinha afastadas dos cantos na mesma medida, `Toll.INSET`: nos cantos, perto, elas passavam dos lados da máquina e ele parecia torto; uns 18 cm de largura, a máquina na proporção da aberta: com 14, carimbo e bilhetes ficavam menores que um plug, e com 22 × 2,6 cm ela saía larga e baixa demais; para caber, o jornal fica dobrado estreito, `NEWS_W`, e a unidade de despacho, recuada), mais a caneca, postos por fração da profundidade do tampo (`_at`, `_deep`: ficam no
  tampo seja qual for a câmera) e, na largura, a partir da lateral da mesa comutadora (`_side_x`), em duas fileiras
  com folga entre eles: atrás, o que é alto: a unidade de despacho, as listas e o relógio de flip com a caneca na
  frente dele; na frente, o que é baixo: calculógrafo, caderno e jornal (as listas na frente tampavam o caderno inteiro;
  o calculógrafo ficou no lugar da prancheta do registro, que agora fica pendurada num prego na lateral do painel da
  mesa comutadora, rente a ela e na perspectiva dela, `Background._draw_hung_clipboard`, `HUNG` na sala, mais funda que
  o painel, com o mesmo desenho de antes e o prendedor em perspectiva; de frente, na parede, destoava da sala) (numa tela mais larga, a folga sobra perto da janela). **Cada um fica num lugar da sala e passa pela câmera** (`_draw_desk_props`:
  tamanho, escorço e o lado que aparece saem da conta; `_box` dá os cantos; nos objetos chatos (caderno,
  prancheta, jornal e a capa da lista de cima), `_flat` desenha o tampo de frente numa imagem do tamanho que ele tem na
  tela, `_top_xf`, e `_project` o põe na perspectiva pixel a pixel pela homografia, `_homography`, como a frente do
  relógio, guardado até o desenho mudar; torto por transformação, o desenho esticava e entortava os pixels, uma linha
  de 1 px virava 0 ou 2, e destoava do resto do jogo; o que não pode entortar, como o lápis, o alfinete e as tiras do
  caderno, vai por cima já na tela, `_tex_pt`; **risco fino também vai na tela**: texto, pauta, colunas e vincos do
  jornal, da prancheta e do caderno (`_newspaper_print`, `_clipboard_print`, `_pad_marks`) com `_ink` (um risco
  em pixel art) nas alturas de `_rows` (a cada N px da tela, não do papel): no papel, linhas de 1 px a cada 2 viravam
  moiré e zigue-zague na perspectiva; área cheia, como a foto do jornal, pode ficar no desenho; papel tem 1 px de beira
  e a prancheta, 2 (com mais, pareciam tábuas); os desenhos são `_art_*`), **cada um girado uns graus, como largado na mesa**
  (`_turned` gira os cantos em volta do meio, `_faces` dá as faces de pé viradas para os olhos; o `yaw` de cada um em
  `_flat` e nas listas, cada volume para um lado: todos retos e em fileira, a mesa parecia montada), desenhados em 1x1 (sem contorno preto: torto pela perspectiva, serrilhava; as faces se separam pela luz, `_poly`; sombra apontando para longe da luminária, em degraus: penumbra, sombra e o contato escuro colado na base, `_desk_shadow`; a de quem está no tampo vai para a camada dela, `Background._shade_layer`, que o dia apaga; e cada um escurece ponto a ponto quanto mais longe da poça de luz (para a frente da mesa, a luz vai `FRONT_LIGHT` vezes mais longe, no escuro de cada objeto e no da sala, `_noir`: a fileira da frente ficava escura demais), liso dentro do próprio objeto (os cantos de cada face pela distância deles, `_shade`, `_shaded`, `_pool`, `SHADE_MAX`; com um tom só por objeto, a troca entre eles era brusca); **os papéis** (as listas, o bloco de fichas, o jornal, a prancheta pendurada, os bilhetes na mesinha do calculógrafo) não escurecem por cima: cada pixel troca de tom pela luz parada no lugar dele (`_still`, `_hom_light`, `_lit_at`, em `_project`: até três degraus de sombra mais frios e um de luz mais quente, `_paper_step`, na rampa do papel, `Pal.lit`, ou, nas tintas e capas, numa conta que escurece esfriando), a troca de degrau andando de uma linha do papel para outra (`PAPER_RAG`), e o que vai por cima na tela (as linhas, o lápis, as tiras) pega o degrau do lugar onde cai (`_tone`); a luminária piscando ou esquentando não entra no desenho: escurece a sala toda no shader do escuro, `_noir`, `FLICK_DARK`, sem redesenhar), do fundo para a frente; a legenda sob o mouse é do `SceneView`, na resolução da interface. **A mesa comutadora é um móvel só** (`_draw_switchboard`,
  como uma mesa telefônica de verdade): embaixo, o console, cuja frente é a faixa da miniatura do painel (a
  madeira em volta dela, com a plaqueta de latão de um lado, os botões de volume e sintonia do outro e os parafusos;
  a prateleira tem veios e o friso de latão na beira) e cujo alto é a prateleira, com o FONE e os cabos em pé nos buracos (a mesa desenha); no fundo dela, num rodapé e com a sombra
  de contato, o painel (`Background.board`). Painel e console têm a mesma largura na sala, então o console, mais
  perto, sai mais largo na tela (a esquerda passa da borda): é o que os alinha na câmera. A lateral em L (o console
  até o fundo do móvel e o painel em cima) foge para o ponto de fuga; o móvel fica um pouco atrás da borda do tampo
  (`DESK_LIP`: aparece o tampo na frente do console, entre a faixa de mesa e a borda) e vai quase até o fundo dele
  (`BOARD_GAP`, um vão pequeno atrás; raso, com o painel de ~6 cm, `BOARD_D`, sobrava tampo vazio atrás dele, e a
  pedido o móvel recuou e ficou fundo); com os olhos acima do painel, o
  tampo dele aparece. (Antes eram caixas soltas na frente do painel, com
  tampos enormes que cobriam o pé dele: parecia fora da mesa e desalinhado.) O tampo (`_draw_desk`): `PLANKS` tábuas
  da mesma largura espaçadas pela câmera, sem juntas (com juntas parecia assoalho), a borda da frente com a
  espessura dele (as faixas em `Pal.DESK_EDGE_ROWS`) e a madeira escolhendo o tom pela luz de cada lugar (`Pal.desk`,
  `Pal.desk_edge`, pela conta de `_shade`): em faixas em volta da poça (`_bands`, desenhadas linha a linha,
  `_desk_row`), quente embaixo da luminária e fria longe dela, com os veios e a beira de cada tábua um tom acima e a
  emenda dois abaixo; a borda de cada faixa anda um pouco de uma linha para outra (`DESK_RAG`), como um veio pegando a
  luz (numa curva lisa, parecia o contorno de uma luz em degraus). Por cima, a poça de luz da luminária, um círculo de `POOL_R` no tampo embaixo dela (com o miolo mais quente,
  `POOL_HOT`: só o meio clareia, para o olho cair nos objetos) desenhada sempre
  com a luminária acesa, como o arco na parede e a luz no armário (o piscar e o esquentar ficam nos shaders, `_noir` e
  o do `SceneView`; os postes de lá, que apagam no piscar, acendem no brilho pela camada de cima, `_posts`). **O estado do jogo nos objetos**, para ler de relance: uma
  tira de papel saindo do caderno por registro pendente (`pending`) e uma folha nova na
  prancheta quando uma conversa termina com o registro guardado (`unread`; `CallLog.filed`/`unread_changed`, o Main
  chama `filed` em `end_call`); na unidade de despacho, a luz vermelha com uma emergência em andamento (`alert`) e,
  com um cartão perfurado na mesa, a luz âmbar e o cartão saindo da fenda da impressora (`card_out`; o Main atualiza
  os dois a cada quadro). (O alfinete do mapa dobrado, que piscava com emergência, saiu com ele.) **Jornal da manhã** (da segunda noite em diante): o jornal dobrado na mesa (`news`,
  `Main.set_news`; depois de aberto, volta dobrado mais uma vez, os classificados para cima e girado para o outro
  lado, `news_read`, `_classifieds`) abre a primeira página na área das ferramentas (`NewsView`, `Tools.news`, id "jornal", sem aba) com
  as manchetes da noite anterior; `ShiftReport.news()` sorteia a manchete de cada emergência uma vez (o relatório do
  fim da noite não as repete: o jornal já vem na mesa; `headline` traduz na hora) e o `Progress` a guarda (`news`). A página é a do jornal da mesa de perto
  (o papel-jornal, o fio duplo, as colunas de letra miúda, `_greek`, e a foto da cidade em retícula, `_photo`); cada noite
  pode trazer a foto, a legenda e as matérias das colunas dela (`Night.news_photo`, `news_caption`, `news_stories`: uma por
  coluna, a primeira linha é o título), e o que ela não trouxer sai como sempre. **A sala muda ao
  longo das noites**: `GameContent.room` (`RoomChange`, `data/room/`: `detail`, `requires`, `from_night`) liga
  detalhes do cenário (`Background.details`, `DETAILS`: cartaz da quermesse, número anotado colado no armário, armário
  entreaberto com as pastas) pelos marcadores do roteiro, já no meio da noite (`Main._update_room`, refeito a cada
  `flags.changed`; o setter de `Main.flags` religa); a folhinha na parede, entre o armário e a quina, é a data do jogo (`GameData.date_of`/`date_text`: a noite 1 é segunda-feira, 8 de outubro de
  1973, e cada noite um dia depois; o dia da semana sai da data, não da `Night`): a folhinha de outubro com a semana
  começando na segunda, domingos em vermelho, os dias passados riscados e o de hoje circulado; sob o mouse, a data por
  extenso (`Background.CALENDAR`, sem abrir ferramenta nem trocar o cursor); presa só pelo prego, a ponta de baixo do
  lado da janela dobra em orelha nas rajadas da brisa que se ouve (`_draw_curl`, `CURL_PX`, na camada da poeira; a
  rajada é `Sfx.gust`, a mesma onda gravada no som, lida pela posição em que ele toca). A mesma data vai na introdução, no jornal
  (`NEWS_EDITION`) e no caderno ("Noite de 8 para 9", `Notebook.night`). Na
  primeira vez que cada sinal da mesa aparece (tiras, folha nova), uma dica do manual explica, uma vez no
  jogo todo (`Main._teach`: o "já viu" fica nos marcadores salvos; espera o treinamento acabar). Sob o
  mouse: contorno, o nome da ferramenta e o dedo. **O cenário só se redesenha quando algo que ele mostra
  muda**, e o que muda sozinho fica fora do desenho da sala (redesenhá-la custava ~20 ms e ela se redesenhava 3 a 4
  vezes por segundo parada; ver a história 84): a sala (`Background._state`: o lugar das peças da interface, a
  luminária, o estado nos objetos, o clima; parado, fica o desenho guardado); por cima dela, a camada `_over`
  (`_draw_over`, com o estado dela no `_process`: o escuro da sala, o que entra pela janela, o neon, o
  escuro e a sombra atrás do papel e as luzes da sala no `Bloom`, que a sala junta em `_glows` e a camada acende
  cortadas onde o papel está, quadro a quadro, `_paper`, `_light`); a do relâmpago (`_bolt_layer`: o que ele acende é
  medido com a sala e só a força muda, no `modulate`); a frente do relógio, uma textura trocada no lugar
  (`_clock_face`: a sala desenhada com ela mostra a hora nova sem se redesenhar); e a vista da janela, a 30 quadros por
  segundo no vidro (`_vport`, `UPDATE_ONCE` a cada quadro dela), em duas partes: a de trás só quando muda (`_back_state`: a hora, a luminária, o neon, o
  relâmpago, as estrelas piscando), em camadas, o céu (`_sky`), o chão e a cidade de longe (`_back`,
  `_draw_view_back`), a luz do sol no chão (`_street_mul`, que multiplica, e `_street_add`, somada, `_draw_sun_strip`)
  e o que fica em pé (`_upright`, `_draw_city_upright`: postes da rua do cruzamento, paredes, fachadas, e o que fica
  nos telhados, caixas d'água na casa da escada ou de cimento-amianto num cavalete e antenas de TV de espinha de peixe,
  `ROOF`, `_roof_items`, `_draw_roof`, desenhados antes das paredes, que cobrem o que o parapeito tapa vendo de baixo;
  em pixels inteiros, contra o céu, com a beira acesa pelo sol como a cornija; pedido 281), e a da frente (`_draw_city_front`: o letreiro, quem passa, os postes, o homem, o
  carro, a névoa; depois o arbusto, o reflexo e a chuva) a cada quadro. A tela do cenário (o `View` do `SceneView`) só
  é desenhada quando algo nela muda (`Background._show`) ou de tamanho (`SceneView._fit`). Quem acrescentar ao desenho
  algo que muda precisa pôr isso no estado da camada certa (e, na sala, no `_state`). Lá fora (`_draw_city`): céu do clima, morros, casas
  sorteadas sempre iguais (`_build_city`, semente fixa),
  a igreja com o relógio aceso, a rua com o poste (a silhueta do mistério fica contra a luz dele) e o chão molhado na
  chuva. **A vista: uma cena 3D simples projetada no vidro** (pedido do usuário: pensar a cena antes,
  nunca a perspectiva elemento por elemento; `OUT_*`): uma câmera dentro do prédio, na altura de quem está na janela
  (`OUT_EYE` m acima da rua; o horizonte passa ali; não é vista aérea), olhando de frente para uma rua que passa ao
  lado do prédio e continua para os dois lados, perto o bastante para quem passa ter ~18 px (`OUT_F` 48, pedidos 252 e 254; com 64 e 54, perto demais, e a calçada de lá a 7,6–9,4 m, `STREET`; o que
  é desenhado em px fixos, a igreja, o sol, a lua, o letreiro e o voo das mariposas, cresce por `OUT_K`, e quem passa
  anda só um pouco além das beiras do vidro, `WALK_SPAN` 12 m, `MAN_FROM`; o horizonte `OUT_DROP` 10 cm abaixo dos olhos:
  neles, a rua enchia o vidro e o alto dos prédios saía por cima; com 38, ~13 px; com 32 e a rua de 14 m, era um palito de 8 px; com 45 e a rua larga, o vidro mostrava pouco; `OUT_EYE` 3,8 m: a 4,5, o carro da mão de cá, perto, virava o teto, uma laje cortada pelo peitoril; os lugares ao longo da rua, `CROSSING`, `HOTEL_X`, `MAN_X`, `APT`, `FAR_LAMPS`, encolheram junto, para caberem). Um
  ponto de fuga só, no horizonte, no meio do vidro, do batente de longe ao de perto (`OUT_AT`, `_out_x`): para ele fogem só as linhas
  que vão para longe (a rua do cruzamento e as paredes dela); a rua, os meios-fios e as fachadas de frente ficam na
  horizontal e as paredes na vertical, com a base apoiada na calçada. A diagonal da janela é só do primeiro plano (a árvore nova da nossa calçada também, pedido 256, antes um
  arbusto: a copa larga e baixa, em tufos maiores, `CLUMP_R`, sobe do peitoril posta pela parede da sala, `_side_pt`, não
  pela câmera da vista, `SHRUB`, `_draw_shrub`, sem passar da nossa calçada para não esconder o outro lado da rua, a
  pedido; os galhos do tronco ao meio de alguns tufos, `BRANCHES`, `Pal.TREE_BARK`; com a cerca viva embaixo, até o
  batente de perto, `HEDGE`: sem ela sobrava a rua vazia entre a copa e o peitoril) e não
  entra na conta, e nada da vista encosta no nosso prédio: a nossa calçada, o nosso meio-fio e uma faixa de pedestres
saindo deles diziam para que lado a nossa parede vai, contra a sala (a parede parecia torta); perto, a rua some na
sombra do nosso prédio, lisa. Tudo em metros e no tamanho de verdade (`_o(g, x, z, h)`: `x` ao longo da rua, `z` a distância dos
  olhos, `h` a altura; `_patch` um retângulo no chão). De perto para longe (`STREET`): o
  asfalto (manchas, desgaste dos pneus, grão, poças espelhando o céu e a faixa tracejada), o meio-fio de lá (com a face virada para nós), a calçada de lá com os postes (`FAR_LAMPS`, a luz deles
  no chão) e o homem embaixo do da esquina (`MAN_X`, `_draw_stranger`: 1,8 m, chapéu e casaco; chega e sai andando), em silhueta contra a
  vitrine acesa de um bar (`_draw_shopfront`; quem bebe no balcão, em pé, de costas para a vitrine, quantos pelo dia da
  semana, `BAR_PATRONS`, indo embora das 22h à meia-noite, `BAR_EMPTIES`), os prédios de frente
  (`_houses`, `_draw_far_house`: o de tijolos na esquina, à direita do cruzamento, `CROSSING`; o hotel com o letreiro e a marquise acesa
  sobre a porta, `HOTEL_X`, `_draw_marquee`, do outro lado; janelas fundas, com a sombra da verga e o peitoril, e a
  luz dos postes lavando as fachadas), a rua do cruzamento indo embora entre paredes (`CROSSING`, 10 m, pedidos 253 e 254: com 4,9, era um corredor, e com 8, estreita; o hotel
  foi um pouco para a esquerda e o lado da direita andou junto, do prédio de tijolos ao bar, à varanda, ao homem e ao poste
  dele; `_canyon`, `_draw_canyon_wall`: janelas em andares e colunas, `CANYON_WIN`, e a
  laje de cada andar; mais finas que um pixel, só as acesas (e, com o sol, as da esquerda), com 1 px vazio entre elas, senão viravam um borrão; a
  lateral do prédio da esquina na tinta da fachada dele, a de tijolos nas fiadas, sem as lajes, com as venezianas verdes
  de madeira (`_draw_side_window`, `Pal.SHUTTER`: abertas, encostadas na parede dos dois lados, ou fechadas, com as
  lâminas), vasos em alguns peitoris e uma varanda no lugar de uma janela (`SIDE_BALCONY`, `_draw_side_balcony`: a
  porta acesa até as 23h, a laje vista de baixo, os vasos e o gradil, barra por barra do lado de cá; pedido 280); o cano de descida na
  divisa; o térreo, desenhado de longe para perto, com portas de madeira e lojas, abertas até a hora delas ou com a
  porta de enrolar e a caixa dela, até `SHOP_Z`: cada loja com a tábua da placa e o toldo de lona saindo da parede, com
  a franja e a aba de cá, numa em quatro a placa de bandeira de frente para cá, com as letras em traços (`_strokes`, as
  mesmas das lojas de lá), e, até `SHOP_DETAIL`, a mureta e a mercadoria na vitrine, as listras do toldo
  (`Pal.SHOP_PAINT`), as almofadas da porta, o degrau de pedra e, numa em duas, a laje de concreto por cima dela, na
  pedra da calçada (pedido 277); os postes
  dela, desenhados depois das paredes, que antes os cobriam, diminuindo; um carro estacionado de traseira, `PARKED`,
  `_draw_parked`; a banca de jornal de chapa verde encostada na lateral do prédio de tijolos, na ponta de cá
  (`NEWSSTAND`, `_draw_newsstand`, sem as lojas atrás dela: fechada das 19h às 5h10, `NEWSSTAND_SHUT`, com os vincos
  das portas arriadas; aberta, as portas de cima levantadas, as revistas penduradas, `Pal.MAGAZINES`, e os jornais no
  balcão; pedido 281); quem vira a esquina por ela, `WALK_CORNER`, `TURN_Z`, `_walk_at`, do lado da banca por fora
  dela, `WALK_RIGHT`; e a névoa clareando para o fundo) até a igreja no fim (`_church_pos`, `CHURCH_K`; a cruz e o relógio aceso em pixels do tamanho da torre, e o brilho do relógio também) e, bem longe, a cidade em duas fileiras na
  névoa. Na chuva, o asfalto molhado espelha as luzes em riscos verticais (`_draw_wet`), na frente da vista, tapados
  pelos carros (`_car_cuts`, `_uncovered`). Na névoa (`_draw_fog`, por cima da rua e do
  outro lado, atrás do arbusto): um véu liso mais grosso rente ao chão (`FOG_VEIL`, `FOG_GROUND`), fiapos largos e lisos
  atravessando a rua com o vento (`FOG_WISPS`) e as luzes espalhando nela (halo e cone de laterais lisas em cada poste, o
  vermelho do neon); as faixas retangulares que havia no vidro pareciam defeito. Os carros (`_draw_car`, um por
  vez em cada mão; modelos de 1973 sorteados pelo quanto passam, `CAR_KINDS`: Fusca, sedã, perua, Kombi em duas cores e
  picape com caçamba, cada um com o seu tom de motor, `pitch`, e uma cor escura da noite, em rampa, `Pal.CAR_TONES`, com o arco da roda, o fundo da caçamba, a frente e a traseira na sombra fria dela e a beira do para-lama na luz quente; `_car_kind`; o teto e o capô mais escuros que o
  lado, com um pouco do céu, `Pal.CAR_SKY`, e os vidros também, senão sumiam no asfalto e o carro parecia baixo; o teto mais claro que os vidros; vidros e chapas inclinadas só saem virados para os olhos (`faces`: por trás, o para-brisa saía por cima do teto); capô, teto, vidros e chapas de um lado ao outro do carro (com 10 cm para dentro, ficavam frestas); a profundidade do carro encolhida no recuo para o ponto de fuga (`CAR_DEPTH`, `_car_z` no `_o`: a vista é grande-angular e, longe do meio, ele parecia ter metade da largura do comprimento); rodas redondas em pixel art nos arcos dos para-lamas; a luz dos postes correndo
  pela beira do teto e pelos frisos quando ele passa embaixo deles, `_sheen`, `CAR_SHEEN`; faróis e lanternas acesos, com halo (o par
  deles com a frente ou a traseira virada para nós) e espelhados na rua molhada; Brasília e caminhão de baú entre os
  modelos, o Fusca com os para-lamas saltados e os faróis neles, a caçamba da picape com a parede de dentro; táxis
  (`TAXI`, `TAXI_KINDS`, placa acesa no teto); na chuva, a lataria mais brilhante (`CAR_WET`) e o borrifo dos pneus
  (`_spray`) (as silhuetas de quem vai dentro
  foram testadas e saíram a pedido), cada mão no seu sorteio, `_cars`) passam pelas duas mãos (`CAR_LANES`, `_car_x`): pela de lá, da
  direita para a esquerda; pela de cá, voltando, da esquerda para a direita, mais perto da faixa do meio que do nosso
  meio-fio (rente a ele, ficava tão perto e de cima que virava uma mancha escura cortada pelo peitoril), apoiados no
  asfalto: sombra de contato, facho dos faróis no chão (sumindo em `BEAM`; inteiro, era uma laje cinza que fazia o carro parecer largo), lado,
  teto e capô vistos um pouco de cima, a frente ou a traseira virada para nós. O brilho da luz de cima (`%Glow`, centrado no alto, liso) fica dentro da tela do cenário, logo depois do
  `Background`: ilumina a sala, não a interface; acompanha o tremor dela. **A luz da luminária num shader** (plano hi-bit; o quadro de
  todas as luzes está no `CLAUDE.md` da raiz, "A luz"): o `SceneView` mostra o cenário por `lamp_light.gdshader`, que soma a poça quente, lisa, em volta do meio
  do escuro da sala (`_gloom_center`), com o vidro de fora (`_glass`) e a luz do dia (`daylight`, só no amanhecer da última noite); o
  `Background.light` passa os parâmetros a cada quadro, sem redesenhar a sala; `SceneView.lamp_light` (a chave do
  painel de debug, `--lamp=0` na captura) desliga. O escuro da sala também é shader, mas numa camada no meio do
  cenário (`_noir`), para o que entra pela janela e o relâmpago continuarem por cima dele; o vidro dos dois shaders
  vem de `glass.gdshaderinc`. **Para trocar por PNG**: `wall_art`, `window_art` e `desk_art` entram no lugar do desenho daquela camada
  (o clima continua por cima da janela). As ferramentas não têm abas: abrem pelos objetos da mesa ou pelas teclas 1 a 4. O caderno da mesa mostra o selo dos registros pendentes (`Background.pending`). Nos testes, o clique num objeto da
  mesa é `background.pointer(evento)`.

## Modelo da mesa (scripts/ui/switchboard.gd)
- **Chave de escuta** de cada linha entre a entrada e a saída (`ROW_Y["key"]`, `lever_rect`): a porca niquelada e a
  alavanca de bastão de haste de metal com o pino de baquelite preta na ponta, no preto dos cabos (`CORD_COLORS`, que desceu para a camada do painel; `LEVER_ART`/`LEVER_UP`, `_draw_levers`, em passadas: as sombras, as porcas e as alavancas, uma chamada de desenho cada, na camada das lâmpadas), para cima com a chave
  levantada ou o destino tocando (`lever_up`); ao virar, passa de frente e bate um pixel além (`_flip_levers`,
  `LEVER_SEC`, estalo vindo dela); clique emite `lever_pressed`. O nome das saídas foi para baixo delas, na fonte de 11, como "ENTRADAS · FONE", no meio do vão até os bancos: a faixa de numeração de cada banco atendido ("100-199") saiu da faixa gravada e foi para a moldura de cima dele, à esquerda e miúda, como o nome do INTERURBANO (`_draw_top`; o banco sob a chapa fica sem); os bancos desceram (`DEST_TOP` 188, a moldura rente aos números) e o interurbano fica 6 px abaixo do banco C.
- Tomadas por id inteiro: **1–10 entradas**, **11–20 saídas** (linha + 10), **destinos = o próprio número** (101–399,
  exceto 190/192/193, que vão pelo despacho). Destinos em três bancos de fábrica, A | B | C, rotulados pela faixa de
  numeração (100–199 | 200–299 | 300–399, `SECTOR_ORDER`, duas fileiras cada, `_layout_dests`/`_slots`; a mesa não
  fala em setor). O banco de um setor que ainda não é do operador fica sob uma chapa com a letra dele (`_draw_plate`:
  A e B; o C, do setor 3, nunca é tampado; chapa lisa (o escovado saiu a pedido), a letra estampada em relevo, desenhada à mão em `PLATE_LETTERS` com luz e sombra de 1 px, `PixelArt.relief` (na fonte em 33 os pixels viravam blocos de 3), o aviso `BOARD_PLATE_NOTICE`
  pintado com estêncil e riscos de chave de fenda em volta dos parafusos) e as tomadas dele não existem para o clique.
- `ends[]`: tomada de cada ponta (-1 = na base). **Ponta 0 = FONE** (cabo verde, encaixe `FoneSocket` na prateleira, só
  entra em entradas). **Pontas 1..2*patches = cabos de conexão** (vermelho, azul, amarelo, branco e preto em `CORD_COLORS`; independentes; `mate(e)`
  dá a outra ponta; uma ponta na saída, a outra no destino). `SHELF_SLOTS = 5` lugares na prateleira; cada setor
  entregue ao operador traz um par (`patches`, contado no `_ready` pelos `GameData.sectors`: 3 cabos no setor 3, 4
  da noite 5, 5 da noite 9), e o lugar de cada setor que ainda não é dele fica sob um tampo (`_draw_cover`).
- `setup(exchange, socket, tray)` liga a mesa ao estado, ao encaixe do FONE e à faixa dos buracos dos cabos (lugares
  na prateleira, fora do retângulo dela: `socket_rect`, `tray_rect`; o clique vale neles, `_has_point`). Os buracos
  ficam na prateleira em duas fileiras (`hole`, `SHELF_HOLE_Y` atrás, `SHELF_FRONT_Y` na frente, `FONE_HOLE_X`, perto da beira para o nome gravado caber antes da ponta do primeiro cabo, que conta de `CORDS_X`; aro
  de latão achatado pela perspectiva, em pixel art, `HOLE_ART`, `draw_grommet`): o FONE sozinho atrás e as duas pontas de
  cada cabo juntas, como um par, a da frente `PAIR_SHIFT` à esquerda da de trás (`front_of`; sempre o mesmo: pela
  perspectiva exata o desencontro variava a cada coluna e parecia bagunça; alternadas uma a uma, não se via qual ponta
  era de qual cabo); os `SHELF_SLOTS` lugares a um passo igual do FONE até `TRUNK_GAP` antes do banco interurbano
  (`patch_x`, `_pitch`, `trunks`). Os lugares vagos ficam sob um tampo de metal parafusado deitado na prateleira, na
  inclinação dos pares, linha a linha de pixels (`_draw_cover`, `COVER_W`; na perspectiva exata ficava inclinado demais
  ao lado dos pares). Os plugs guardados em pé neles (`home_pos`; os da fileira de trás são desenhados antes, a da frente
  passa na frente; cada fio repousa na fileira do buraco dele, `floor_y`, senão o da frente travava antes de entrar) e
  o nome do FONE numa plaquinha de latão reta na fileira da frente, centrada embaixo do buraco dele, na largura par do
  plug (`_draw_fone_tag`; inclinada pela perspectiva ficou torta demais; gravado embaixo do buraco, a beira da frente
  dele cobria o alto das letras; os "CABO 1/2/3" saíram a pedido: a cor diz qual é o cabo); o buraco é mais largo que o plug, que entra nele (`PLUG_SINK`: abaixo
  de `HOLE_LIP` o plug não é desenhado, `_cut`/`_pr`, e a beira da frente do buraco passa por cima dele e dos fios
  que saem dali, `draw_lip`), sem contorno preto; fio e plug escurecem em degraus ao entrar nele (`HOLE_SHADE`,
  `_along`), senão pareciam flutuar. As pontas dos plugs em pé passam na frente do pé do painel, logo abaixo da
  legenda. `dest_of_output(n)` segue o cabo da saída n.
- `refuse(e, j)` decide compatibilidade (e o destaque amarelo/vermelho). `_has_point` estende o clique ao encaixe
  do FONE; por isso o telefone e seus containers acima do encaixe têm `mouse_filter = IGNORE`, e a mesa tem
  `z_index = 1` (desenha plug e fio por cima do telefone). Overlays têm z 2, intro/final z 3.
- Clique num plug encaixado → solta o plug (`go_home`, `_loose`): ele vira a última conta da corda e o contrapeso
  o puxa de volta na hora, o fio acelerando (`WEIGHT_ACCEL`) até `PULL_SPEED` (antes ele caía 0,35 s sem nada puxar e o
  fio recolhia sempre na mesma marcha); solto acima do buraco, a qualquer altura (`NEAR_HOLE` na horizontal), não cai: vem reto, fio esticado e sem gravidade. Com o fio todo
  recolhido e a traseira do plug na boca do buraco (`SEAT_LEN`, `SEAT_NEAR`), ele assenta (`_seat`, `_seat_pose`): o
  fio some (já entrou), o plug gira até ficar em pé com a traseira presa na boca (`SEAT_TURN`, macio; vindo de cima,
  já em pé, não gira) e afunda puxado pelo fio, acelerando (`SEAT_ACCEL`; vindo de cima, no embalo dele), e quica ao
  bater no fundo (`SEAT_BOB`, com o `thump`). O corte do buraco só vale com ele em pé (`_in_hole`). (Antes, ele pulava
  em 0,1 s de deitado para dentro do buraco, e o fio ficava desenhado por cima da prateleira.) Com o fio curto, as
  dobras do desenho encolhem com os trechos (`_kinked`), senão viravam um rabisco na boca do buraco; solto, ele gira com o fio
  (`_plug_angle`), sai com o embalo da mão (`_mouse_vel`, `MAX_FLING`) e dá para pegá-lo no ar (`_plug_hit`). Sons:
  `drop` (bate na mesa, `DROP_SPEED`), `thump` (assentou) e o atrito contínuo do fio no buraco: a mesa soma
  quanto fio entrou ou saiu (`_rubbed`, variação do comprimento) e passa a velocidade a `Sfx.cord_rub` a cada quadro
  (volume e tom entre `RUB_MIN` e `RUB_FULL`; sem chamada, cala). Três loops com o mesmo ganho: o fio (agarra e solta
  + corpo), em dois, `rub_slow` com os estalos esparsos e `rub` com eles juntos, cruzados pela velocidade
  (`RUB_DENSE`; o tom sobe pouco, `RUB_PITCH`: subindo só o tom, soava como fita acelerada), e `rub_hi` (o agudo:
  fibras + rangido), mudo devagar (`RUB_HI_FROM`), normal no médio (`RUB_HI_NORMAL`) e `RUB_HI_BOOST` dB a mais
  rápido. Todos passam
  pelo barramento `Rub` (direto para o Master, quase seco; passa-baixa que abre de `RUB_LP.x` a `RUB_LP.y` com a velocidade, e
  panorama). A mesa também informa onde fica o buraco na tela (o som vem daquele lado, `RUB_PAN`), quanto do fio está
  saindo ou entrando (`_count_rub`; entrando é mais liso, `RUB_IN`) e quanto é o do FONE (mais macio, `RUB_FONE`; a diferença some
  quase toda puxando rápido, `fast`), quanto é de plug solto (sem mão puxando: frouxo, grave e quase sem agudo,
  `RUB_LOOSE`) e o tom médio dos cabos (cada um levemente diferente, `Switchboard.CORD_TONE`);
  Por baixo do atrito, a madeira do móvel soando a cada agarra e solta (`_build_rub`, `WOOD`); cada `cord_tap`
  abaixa o atrito um instante (`Sfx.RUB_DUCK`).
  `cord_stop` ("tec") quando o fio termina de entrar; no plug na mão, pela velocidade da mão para longe do buraco
  (`_pull_edges`), `cord_snag` (o tranco do fio parado que sai rápido, `SNAG_*`) e `cord_snap` (o "tsk" do puxão
  rápido que para de repente, `SNAP_*`; parando devagar, não toca); `cord_tap` quando o fio bate na mesa (`TAP_SPEED`,
  no máximo um a cada `TAP_GAP` por fio). Sons mecânicos repetidos (`Sfx.VARIED`) saem com tom e volume levemente
  sorteados. Plug só se move arrastando
  (clicar e segurar); clique sem arrastar só serve para desplugar. Clique é apertar e soltar em menos de `CLICK_SEC`
  sem a mão se afastar `CLICK_PX` de onde apertou (`_dragged`, tempo real), não só soltar perto dele: segurado parado,
  ou tirado da tomada e devolvido a ela no mesmo arraste, o plug encaixa de novo (antes, caía). Enquanto ainda é
  clique, a tomada sob o plug não ganha o destaque (soltar ali desencaixa).
- Fios são cordas de Verlet, **uma por ponta**, com um ponto a cada `Cord.SEG` px de fio para fora (`count`, `_resize`: com
  22 pontos fixos, o fio longo tinha trechos de 30 px e virava uma linha quebrada), a rigidez do pano como regra (o ponto
  dois adiante a pelo menos `BEND_MIN` de dois trechos) e as regras resolvidas indo e voltando (`STIFF_ITER`), cada uma um `Cord` (`scripts/ui/cord.gd`, `Switchboard.Cord`, sem
  `class_name`: só a física, sem tela nem som, testada sozinha no teste de fluxo; a mesa, em `_step_rope`, diz onde
  ficam o buraco e o plug, quanto fio está para fora e a prateleira, e lê do passo os sons e o plug solto), presas no buraco (`hole(e)`: o do FONE no encaixe, dois
  por cabo de conexão) e na traseira do plug (`_plug_base`); só existem com o fio para fora. No desenho, o fio de pano
  velho guarda dobras (`_kinked`, `KINK`: cada ponto da corda um pouco para um lado, sempre o mesmo, nada nas pontas; a
  física segue lisa) e o brilho vem em pedaços, como trançado (`BRAID`), 1 px para o lado virado para a luz da mesa
  (`LIGHT`). Desenhado numa curva pelos pontos da corda (`_smooth`, Catmull-Rom em
  trechos de `SMOOTH_PX`; ligados por retas, o fio longo virava uma linha quebrada).
  **O contrapeso** (numa roldana embaixo da prateleira, como nas mesas de verdade) puxa cada fio para dentro do buraco
  o tempo todo: encaixado ou na mão, a folga volta mais depressa do que sai (`WEIGHT_TAKE`, contra `HAND_FEED`) e o fio
  fica esticado, entrando no buraco na própria linha, só com a barriga do peso dele, que cresce com o cubo do vão
  (`SAG`), nunca menos que `BEND_SLACK` (a curva saindo da ponteira), poucos px: a barriga cresce com a raiz da folga
  vezes o vão (com 10 px, o fio parecia solto, encaixado e na mão); no ar, na frente do console, `CORD_SLACK`. Esticado, as dobras do pano ficam em
  `KINK_PULLED` (inteiras, num fio reto viravam degraus). (Antes, uma folga fixa, maior no FONE, até 52 px: o fio ficava
  mole, deitava na prateleira e passava por cima dos plugs guardados. Uma saída do buraco forçada para cima saiu a
  pedido: o pedaço preso ficava duro e fazia uma barriga logo acima do buraco.) Fio parado por `Cord.SLEEP_STEPS` passos "dorme" (`Cord.sleep` =
  área onde o mouse o acorda) e deixa de ser simulado até a ponta, o buraco ou o mouse mexerem nele.
- Sob o mouse: `_plug_under` (plug que dá para pegar → `_hover`, desenhado com contorno claro) e `_cursor_shape`
  (mão aberta, mão fechada segurando, proibido sobre tomada que recusa, dedo em tomada/plaqueta que informa).
  Desenho na ordem `_order`: a ponta pega ou encaixada por último (`_raise`) fica por cima (e é a primeira no clique);
  cada ponta desenha fio e plug juntos, para o fio mais recente passar por cima dos plugs das outras.
- A luz da luminária do teto também cai no painel (`_draw_room_light`, `ROOM_LIT`/`ROOM_DARK`, `LAMP_ABOVE`): liso,
  mais claro e quente no alto à direita, mais escuro nos cantos de baixo; por cima de tudo que é do painel e por
  baixo dos plugs e fios. Ela pisca e esquenta com a da sala no `modulate` da mesa (`Switchboard.dim`, com o
  `Background.lamp_dark` posto pelo Main): escurece tudo o que a mesa desenha, onde estiver, sem redesenhar. Por cima dela e por baixo dos fios, a luz das
  lâmpadas acesas no painel em volta (`_glow`, `board_glow.gdshader`, até 16): um brilho fraco da cor de cada uma,
  que começa onde o halo do `Bloom` acaba; as luzes são as que a camada das lâmpadas declara ao `Bloom`
  (`Bloom.lights_of`), passadas como parâmetros no fim do desenho dela (`_glow_params`). A mesma luz (`_room_lit`) escolhe o tom do relevo do painel na rampa do metal
  (`Pal.panel_metal`, `_lit_rect`: os filetes gravados das faixas, a beira rebaixada e a das faixas de cada linha,
  trecho a trecho) e o da moldura na da madeira (`Pal.cabinet`); as peças de metal paradas (as plaquinhas de níquel, o aro das lâmpadas, as porcas e as alavancas, as chapas dos bancos) ficam num degrau dessa luz no meio delas (`_step_at`, `Pal.panel_step`, `_nickel`, `Pal.lit`); o campo do painel fica liso, em `Pal.PANEL` (em
  faixas, pareceria luz em degraus ou metal escovado, que saíram a pedido, e as legendas o tampam com essa cor).
- **A mesa é desenhada em quatro camadas, e cada uma só se redesenha quando o que ela mostra muda** (`_layers`; `_look`
  devolve o estado de cada uma, comparado no `_process`): o painel parado (a própria mesa, `_draw`: móvel, faixas,
  plaquinhas, tomadas das linhas, estados e numeração; muda com os estados e os setores), as lâmpadas (`_lamps`,
  `_draw_lamps`: lâmpadas, o reflexo delas na entrada e o aro aceso dos destinos; registra no `Bloom` as luzes e os
  plugs encaixados que as cobrem, porque as máscaras do `Bloom` só valem para as luzes de quem as registrou), as
  tomadas dos destinos com as chapas e a luz da sala (`_top`, `_draw_top`: por cima do aro aceso e das lâmpadas) e os
  plugs com os fios e o balão (`_cords`, `_draw_cords`; também a cada quadro com algo se mexendo: plug na mão, solto,
  encaixando ou saindo, fio acordado; e mais uma vez no quadro em que tudo para, o lugar final: sem isso, o plug que
  assentava ficava desenhado torto, meio fora do buraco). Antes, a lâmpada piscando redesenhava a mesa inteira
  (~1 ms por quadro só nela, ~3 ms com cabos); agora, só as lâmpadas (~0,1 ms). As funções de desenho do
  `switchboard_panel.gd` e do `switchboard_plugs.gd` desenham em `_ci` (a mesa, ou a camada que a está desenhando,
  como o `_ci` do `Background`). Quem acrescentar ao desenho algo que muda precisa pôr isso no estado da camada certa
  do `_look`. O trançado do fio é uma chamada de desenho só (`draw_multiline_colors`; um `draw_polyline` por pedaço
  eram dezenas por fio).
- Layout da mesa (`SIZE` 492×304, também em `main.tscn`; o passo das colunas, 44 px, `col_x`, é o do estado mais longo, e o dos destinos, `DEST_PITCH` 24, o dos números em cima deles): móvel com moldura de madeira (`_draw_cabinet`, `FRAME`,
  `WOOD`) e faixas gravadas com o nome de cada seção na fonte gravada do painel (`_draw_rule`, `RULES`: entradas, saídas, destinos; `tiny`: em 11 o nome enchia a faixa das entradas e encostava nas plaquinhas, e a faixa fica no meio entre a moldura e elas); coluna de cada linha em `ROW_Y` (plaquinha de metal com o número
  gravado na fonte miúda, `_draw_number_plate`; estado; lâmpada; entrada; saída), todos os encaixes com `JACK` px, bancos de destino em
  `DEST_TOP`/`DEST_ROW` (cada banco com o mesmo vão, 8 px, entre a moldura e os números e entre as tomadas de baixo e a moldura, `_blocks`) e a legenda das lâmpadas na faixa das entradas, à direita, na fonte gravada do painel (`_draw_legend`, `tiny`; no pé do painel, os plugs guardados passavam na frente dela). Mexendo na altura, confira que a coluna da esquerda ainda cabe (até 540).
- Chapas de metal niquelado (`_draw_metal`: chanfro e rebites) nas plaquinhas dos números. (A "queda" das mesas antigas, a plaquinha que cai quando a
  linha chama, foi testada e saiu a pedido: lâmpada, texto e som já avisam demais.)
- Moldura de madeira pixel a pixel e guardada (`_wood_frame`): trilhos em meia-esquadria com emenda na diagonal,
  veios ondulando ao longo de cada um, quinas gastas mais claras, cada pixel no tom da madeira pela luz da sala ali
  (`Pal.cabinet`; a troca de tom anda de um veio para outro, `CABINET_RAG`), guardada por tamanho e lugar da luminária;
  o brilho da luminária na quina de cima, mais forte do lado dela (`_draw_cabinet`).
- Cada linha tem uma faixa rebaixada e discreta da plaquinha à saída (`_draw_strips`, `STRIP_W`; sem ela a saída
  parecia solta); as faixas gravadas passam por baixo e o nome delas por cima (`_draw_rule(y, nome, false)`).
- Uso de anos (`_draw_wear`, sempre o mesmo): o painel clareado em volta das tomadas (`WEAR`, pelo quanto cada uma é
  usada, `_use`: entradas mais, das primeiras linhas para as últimas) e riscos finos de plug que errou o furo.
- Plaqueta de latão do fabricante na frente do console, à esquerda da miniatura (`Switchboard.draw_maker_plate`,
  estática, desenhada pelo `Background`: `BOARD_MAKER` na fonte gravada e "SÃO SOTERO"; ficava no pé do painel e saiu
  de lá quando os cabos se juntaram).
- Troncos interurbanos (`_draw_trunks`): um banco de seis tomadas no canto de baixo à direita do painel, embaixo do
  banco C e alinhado à direita dele (`TRUNK_PITCH`: o nome mais longo da cidade cabe em cima de cada tomada), com "INTERURBANO" gravado na moldura e a cidade em cima de cada tomada
  (`BOARD_TRUNK_1..6`, nomes provisórios). As tomadas são destinos como os outros (`GameData.TRUNKS`, 901–906, de
  todos os setores; posição em `_layout_dests`, desenho, aro aceso e clique no laço dos destinos, sem o número em cima).
- **Pixel art em código, sem arquivos de imagem** (decisão do usuário): `PixelArt` (`scripts/ui/pixel_art.gd`, só
  funções estáticas, usadas pela mesa, pelo cenário, pelo painel e pelo bloom) monta e guarda as texturas: mapas de
  texto (`art`), peças redondas (`disc`), a fonte gravada do painel (`tiny`) e `sprite`, que desenha uma delas centrada
  e presa aos pixels. **Folha de prévia**: `Godot --headless --path . -s tools/sprite_sheet.gd` grava
  `build/sprites.png` com tudo ampliado 8× (os mapas com nome; depois o que a mesa e o cenário montaram na noite 1).
- **Peças redondas pixel a pixel** (`PixelArt.disc`: imagem guardada por diâmetro e camadas, com luz, meio-tom e sombra vindos de
  `light`, por padrão `LIGHT`, alto à esquerda, e camadas côncavas; as da mesa comutadora, por `Switchboard._disc`, na
  luz dela, `Switchboard.LIGHT`, alto à direita, de onde vem a luminária, com as sombras caindo embaixo à esquerda; `PixelArt.sprite` desenha presa aos pixels; desenhadas como círculo saíam
  embolotadas): lâmpadas, aro aceso do destino, lâmpadas da legenda e parafusos das chapas. **Cor que muda a cada
  quadro vai no `modulate` do desenho, nunca nas cores de um `disc`/`art`** (o cache guarda uma textura por cor e não
  esvazia: o vidro da lâmpada pulsando com a cor no `disc` criava ~38 texturas por segundo; a lâmpada desenha o vidro
  apagado e o aceso por cima com `level` na transparência). **Nenhuma peça redonda
  com `draw_circle`**: o cenário usa o mesmo `disc` (`Background._sprite`, fora da escala e da perspectiva: botões do
  rádio, parafusos do console, alfinete do mapa, emblemas, rebites, tachinha, fechadura); a caneca é uma caneca esmaltada montada pixel a pixel numa imagem (`_mug_art`: o
  cilindro pela luz do alto à esquerda, cada tom tirado das rampas do esmalte e da borda, `Pal.MUG_ENAMEL`/`MUG_RIM`,
  pela luz dele vezes a do lugar, `1 - _shade`: longe da poça, mais escura e mais fria; guardada por essa luz, em
  degraus de 0,05, a borda azul-marinho, a boca e o pé em elipses pela câmera, o
  café com a luz refletida, a alça em C do lado da sombra e lascas no esmalte), com a luz da luminária tremendo no café (dois pontos
  correndo pelo risco de luz da imagem, `_mug_glint`, `_draw_glint`, `Pal.COFFEE_GLINT`) e o vapor subindo na camada da poeira
  (`_draw_steam`), que some com as horas porque o café esfria (`STEAM_FOR`); sob o mouse ela se ergue como os objetos
  das ferramentas e, clicada, é um gole (`Background.sip`, som `gulp`): o café baixa (`sips`, `MUG_SIPS`) e, acabado,
  fica a borra no fundo e o vapor some; o painel do operador nos parafusos e o `Bloom` no miolo das luzes redondas. **Sem contorno preto em
  nenhuma peça**: a beira é o tom da própria peça, na luz em cima e à esquerda e na sombra embaixo e à direita
  (`Switchboard.rim`; o níquel em `NICKEL_EDGE`; num rebaixo, ao contrário); escuro só o que é buraco, rebaixo ou
  material preto (`EDGE_DARK` ficou só no furo da porca da chave). Os plugs também são pixel art, no acabamento do relógio
  da mesa (abaixo). **O encaixe** (`_jack_tex`, 12×12, pixel a pixel e guardado, pela referência do usuário): um aro de metal abaulado
  em volta de um furo preto largo, de 6 px (`JACK_RINGS`: o furo, a parede da bucha, côncava, com a luz embaixo à
  esquerda, a face, clara no alto à direita, virada para a luminária, e a descida dela até o painel, dois tons mais
  escura); cada pixel do aro escolhe o tom pela luz numa rampa de cinco (`JACK_METAL`, metal quente); por cima da luz
  da sala, um pixel de brilho (`_draw_glints`, `JACK_GLINT`; a luz da sala o apagava). (Antes: furo de 4 px, a largura
  da luva, e o aro de níquel cinza em três tons por anel, chato e estranho; com a face indo do claro ao escuro, ou com
  a quina toda mais escura que ela, parecia uma cúpula saltando do painel; com uma beira escura em volta, como na
  referência, o aro ficava fino demais nesse tamanho.) As saídas no metal mais escuro (`dim`). Largura par e o meio num pixel inteiro (`jack_rect`
  arredonda o dos destinos), para ficar no eixo da plaquinha e da lâmpada. (Uma versão em `_disc` com a bucha de latão
  saiu com o furo maior e foi rejeitada.)
- Encaixes redondos (`_draw_jack`: o aro niquelado e o furo, com a sombra no painel); lâmpadas de vidro leitoso abaulado num aro
  fino de níquel, do tamanho das tomadas (14 px), sem furo (`_draw_lamp`, `BEZEL`, `LAMP_OFF`: com o assento preto pareciam mais uma tomada) que acendem rápido e apagam devagar, como
  filamento (`_lamp`/`_dest_lamp` dizem cor e nível desejado, `_fade` chega lá em `LAMP_ON_SEC`/`LAMP_OFF_SEC`, estado em
  `_lit`; a linha tocando pulsa). A luz acesa tinge o aro dela e o chanfro de cima do encaixe logo abaixo (`_reflect`).
- Plug (`_draw_plug`): de pé (comprido, `PLUG_LEN` do fio à aba; guardado, afunda `PLUG_SINK` = 14 px no buraco: a capa
  de borracha some nele e o corpo fica à mostra, sem esconder metade do plug) (solto, na mão, na bandeja; `_draw_plug_body`) é um mapa de pixels (`PLUG_ART`, 16×66, cores
  por cabo em `_plug_pal`; sombreado de cilindro com o brilho numa coluna só e a beira escura à direita, cantos
  arredondados; contido como o relógio: brilho largo e colar claro destoavam), no jeito de um plugue P10 (referência
  do usuário): a capa de borracha em gomos afinando até o fio (termina em 8 px, a largura do fio, `ROPE_W`), o corpo na cor do cabo (identifica o cabo) com anel em
  cima, serrilhado em listras finas e anel no meio, a aba dourada e a ponta de metal dourado (luva, isolante preto,
  anel, outro isolante e o bico em ponta com a bolinha); comprido e fino como o P10 e **na escala da sala** (14 ×
  66 px, uns 2 × 9 cm, `PLUG_W`, `PLUG_H`, `PLUG_LEN` até a aba: o corpo enche o buraco da prateleira, `HOLE_ART` 20 × 10, e a luva de 6 entra
  no furo de 8 da tomada; o encaixado, `PLUG_FACE_R`, 14 px de corpo com a beira, cobrindo o furo e quase todo o aro):
  menor que o relógio, as listas e o carimbo do calculógrafo (com 18 × 93, na escala das tomadas, e os objetos da mesa
  crescidos na mesma proporção, `Background.PROP_K`, ele ficava maior que todos eles e saiu a pedido); a área de clique do plug guardado sai da altura dele
  (`home_rect`); gira com o fio em passos de
  `ROT_STEP` (5°), cada passo montado pixel a pixel como no RotSprite (`PixelArt.turned`: o mapa ampliado 8× pelo
  Scale2x e lido de volta girado, guardado por ângulo e servindo a qualquer cabo; girado pela transformação do
  desenho, serrilhava, e o passo era de 15°). Na mão, ele balança com o movimento como um pêndulo preso onde a mão
  pega (`_swing_step`, `SWING_*`; a traseira com o fio fica para trás) e, solto, sai com esse ângulo; caindo, quica
  na mesa (`Cord.BOUNCE`, `BOUNCE_MIN`; o `drop` mais alto quanto mais forte a batida, até `DROP_FULL`). O brilho do mapa fica
  do lado esquerdo; com esse lado de costas para a luz (`Switchboard.LIGHT`, alto à direita: em pé, por exemplo), vale o
  mapa espelhado (`_plug_art`). Ao encaixar, a passagem para de frente gira a partir do ângulo que ele tinha na mão
  (`_pushed_ang`). O fio e os plugs em pé pegam a luz da sala do painel em `CORD_LIT` da força (`_lit_by`,
  `_room_tone`: mais escuros e frios longe da luminária). **Todos os fios têm o mesmo comprimento**, `Cord.MAX` (495 px: o do FONE, puxado do
  encaixe, chega ao meio das listas telefônicas da mesa em 960 × 540; a tomada mais longe de um buraco fica a 423):
  na mão, o plug para no fim do fio (`_reach`, com um tranco, `cord_snag`) e a mão segue; a velocidade usada no balanço
  e no embalo é a do plug, não a do mouse. **A prateleira acaba** na lateral do console (`Switchboard.shelf` =
  `Background.shelf`: o x do canto da frente do console e o y do tampo ao pé dele; sem cenário, nos testes, não acaba):
  além dela o plug solto cai até o tampo (`_surface`) e quem vem de fora bate na lateral, sem subir na prateleira.
  Recolhendo, pendurado ao lado do console, a quina é uma roldana (`Cord.hang_step`): o fio vai reto do buraco à quina e
  dela ao plug, que balança preso nela, sobe pendurado (ponta para baixo, `HANG_TURN`) e, na quina, volta para cima
  da prateleira e para a corda de sempre (com a corda solta contra a quina, ele ficava preso, laçava ou era
  arremessado). **A beira da frente da prateleira também é uma quina** (`Cord.lip_y` = fim do `tray_rect`; além da
  lateral, a borda do tampo): com o plug abaixo dela, na frente do console, o fio vai pela prateleira, passa por cima
  dela (`Cord.air`, o primeiro ponto no ar; `cross`, onde passa) e fica no ar, pendendo com a gravidade (os últimos
  `LIP_PTS` pontos antes dela deitam no tampo da prateleira até ela), com a sombra afastada (`AIR_LIFT`) e o atrito
  vindo dali (`over`, `over_at`). Antes, tudo abaixo da prateleira era um bloco: o fio dava um nó nela e atravessava o
  console. Vale com o plug na mão (erguido, o fio sai sempre pela beira: a mesma mão dá o mesmo fio subindo ou
  descendo, e o limite da mão, `_reach`, é reto do buraco, sem saltar) ou solto no ar; solto e deitado no tampo além
  do console, o fio vem pela prateleira e, esticado, passa pela quina dela (`Cord.route`, também a reta do fio
  esticado no desenho). Conta da beira da prateleira também na frente do tampo (deitado nele até a borda, fazia um
  "Z"); o que estava no ar volta para cima aos poucos (`RISE`). Solto ali, o plug pende da beira como da quina (`hang_step`, `edge_x`) e, içado até ela, volta para a
  prateleira com o fio reto do buraco; o fio esticado pela mão solta parado (`go_home`, sem estilingue). O ângulo do plug solto segue o do fio aos poucos (`LOOSE_TURN`). Esticado, o fio de pano alisa: pela distância do buraco à ponta
  (no pendurado, o caminho pela quina) a partir de `Cord.TAUT_FROM` do `Cord.MAX`, as dobras somem aos poucos, o trançado se
  espaça (`TAUT_BRAID`) e, da metade em diante, ele e a sombra afinam 1 px (`Cord.taut`, suavizada
  em `Cord.TAUT_EASE`); frouxo, volta com as dobras inteiras. (Pela folga não dava: os cabos de conexão têm sempre ~14 px
  dela, perto ou longe.) Esticado, o fio também fica reto no desenho (vai para a reta do buraco à ponta; a física
  deixava uma barriga, porque a gravidade puxa o meio a cada passo; pendurado na quina, `Cord.hang`, não). Puxando
  além do fim do fio, o plug na mão se inclina para o lado do puxão, inteiro a `LEAN_PX` além (a mesma mola do
  balanço), com a traseira virada para o buraco; o limite vale para a traseira girada (`_reach`). (Em pé, com o fio
  chegando de lado, a junção dobrava e o fio passava por cima dele.) Encaixado, sai do painel em direção à câmera, a mesma do cenário (a ponta se afasta dos olhos do operador, o ponto
  de fuga da sala, `Background.eye` → `Switchboard.eye`; à direita da mesa, na altura das plaquinhas das entradas:
  as entradas saem quase só para a esquerda, as de baixo também para baixo; era um ponto 600 px acima do painel, e
  todos pareciam vistos de cima) (`_draw_plug_face`: o próprio `PLUG_ART` visto de frente, com os mesmos detalhes: anel e friso claro em cima,
  serrilhado, `_knurled` (as listras verticais; tirado, o plug ficava pobre), anel do meio e capa em gomos afinando até
  o fio (a luva de latão fica toda dentro da tomada: à mostra, numa beira dourada entre ela e o corpo, ninguém sabia o que era); o corpo sai com a beira de todos os
  discos antes dos miolos (só o contorno), mas a capa, por cima, disco a disco com a beira de cada um
  (`PLUG_CAPA_ROW`): a beira de cada gomo fica à mostra em volta do seguinte, menor, e os sulcos aparecem em anéis em
  volta da saída do fio (antes, liso, o plug parecia uma bola); pega a luz da sala como o fio que sai
  dele (`_lit_by`, também a ponteira, `_draw_plug_cap`, na largura do miolo do fio); montado com discos de pixel art, `disc`, um
  por pixel ao longo do eixo, cada um com a largura e os tons da linha do plug em pé que cai ali, `_face_row`: dela vale
  a que mais se destaca, senão os detalhes sumiam no escorço; primeiro a beira de todos, depois o miolo sombreado; com cápsulas e círculos, saía embolotado); com paralaxe: a ponta se desloca do encaixe mais quanto mais longe dos olhos (`_tilt(j)`, `_eye`, no `_look`;
  `PLUG_EYE` sem cenário; `PLUG_DEPTH` estilizado, a conta daria ~3× mais). O fio sai da ponteira (`_plug_base` = encaixe + `_tilt`; o plug encaixado é desenhado antes do fio,
  e o miolo da ponteira, `_draw_plug_cap`, depois). Encaixado, o fio sai entre o eixo do plug e a vertical (`Cord.stub`, já caindo) por `Cord.STUB` px e faz a curva
  aos poucos (o penúltimo ponto da corda fica preso, `pin` em `Cord.step`; a curva sai da rigidez do pano, a mesma no
  fio todo: `Cord.BEND_MIN`; um empurrão nos pontos perto do plug deixava o fio longo duro e o curto com um calombo), a sombra vai do encaixe até `PLUG_SHADE` com uma
  sombra de contato em volta do colar (a do fio sai do fim da do plug e chega a `ROPE_SHADOW` no buraco, `_lift`), a
  luz bate no plug encaixado (`_plug_light`, `_face_rim`: a silhueta dos discos juntos, cada pixel aceso pela
  distância à beira virada para a luz, em degraus, `RIM_FALL`; na entrada, a lâmpada da linha acende a partir da beira
  de cima; no destino, o aro aceso, a partir da beira toda; clareada na cor da luz. Com só a beira acesa, a luz tomava
  o plug de uma vez; mais funda, a luz verde do aro sujava o plug vermelho. Um anel solto por cima flutuava sobre a
  capa, e uma beira por disco listrava o plug), o corpo em pé entra girando para o
  eixo do encaixado, sem a ponta de metal (`_draw_plug_body(col, false)`). Ao encaixar, o corpo em pé entra no encaixe enquanto a
  vista de frente cresce, e ao sair a vista de frente some no encaixe (`MORPH_SEC`, `_pulled`, `_unseat`); ao encaixar, o tampo encolhe `PUSH_PX`
  e volta em `PUSH_SEC` (`_pushed`, `_push`). Destaque e sombra seguem a silhueta (`_plug_outline`: as partes unidas
  num polígono, guardado; o destaque é ele alargado); `_plug_rect(seated)` é o retângulo do clique.
  No plug em pé (na mão, solto, guardado), o fio entra `TAIL_IN` px na traseira dele, no eixo, e uma junta redonda
  fecha a dobra (`_draw_tail`): chegando de lado, ele terminava num corte reto no meio da ponta e deixava um vão.
  O fio tem `ROPE_W` (7 px com a beira; o miolo, 3 a menos; era 9, com o plug maior).
  Sombras (`SHADOW`): fios deslocados `ROPE_SHADOW`; plug mais longe quanto mais sai do painel (solto, na mão).
  Sem contorno preto em plug e fio: a beira é a cor da própria peça escurecida (`EDGE`; o metal, `BEZEL[2]`), como no
  cenário. Encaixado, o corpo (`PLUG_FACE_R`) cobre a tomada e a aba de latão; a aba só aparece na sombra de contato.

