# Plano: a rua sob a ditadura

O pedido: mais cenas na rua da janela, como o policial da noite 3 (`scripts/ui/beating.gd`) e a viatura no hotel da
noite 7 (`PATROL_*`), no clima de uma cidade sob a ditadura. Uma cena por vez: cada uma é implementada, capturada,
aprovada pelo usuário e só então a próxima começa. Marque aqui o andamento (`[x]`) e registre o pedido no
`HISTORICO.md`.

## 1. Qualidade: detalhe e animação (vale para todas)

Estas cenas são o que o jogador vê de mais vivo na janela; **nenhuma entra só com o esboço do movimento**. Cada uma
precisa ter:

- **Animação fluida.** Poses-chave com suavização (`smoothstep`/curvas), interpoladas a cada quadro, como as do
  `Beating` (`_build`, `_at`); nada de pular de uma pose para outra. Quem anda usa a passada (`_gait`, `STRIDE`) ou o
  rig (`_draw_rig`), com o passo casado com o deslocamento (sem patinar). Quem para, desacelera; quem sai, acelera.
- **Movimento orgânico.** Peso e reação: o corpo se inclina ao correr, olha para o que acontece, recua; os carros
  freiam e arrancam (`_taxi_x`); um objeto que cai quica e assenta. Os pedestres em volta reagem (`_watch`, recuo,
  pressa), cada um com o seu atraso, nunca todos juntos.
- **Detalhe em pixel art.** Roupa e acessórios que contam quem é cada um (o terno, o macacão, a farda, o quepe,
  o balde, o rolo, o saco, o megafone), as peças do veículo (frisos, lona, alto-falante, placa), tudo nas rampas do
  `Pal`, com a luz do poste no contorno (`_rig_pixels`, a borda acesa), a sombra no chão e, na chuva, o reflexo no
  molhado. Desenho na escala certa da distância (`_o`, `OUT_F / z`), nos pixels inteiros, sem sobrepor outro asset sem
  necessidade.
- **Som em camadas** quando a cena tem som (motor, freada, porta, passos, papel, spray, alto-falante abafado pelo
  vidro): sintetizado no `SfxSynth`, tocado por `Sfx.play_at` com o x da tela.
- **Marca que fica.** O que a cena deixa (papel no chão, a tinta nova, a banca fechada) continua desenhado depois,
  pelo tempo combinado, como o sangue da noite 3 (`_draw_blood`).
- **Conferência visual.** Capturas da cena em vários instantes (`tools/shot.gd`, uma opção por cena, como
  `--beating=t0,passo,n`), ampliadas e comparadas com a versão anterior; um GIF da sequência para o usuário quando o
  movimento for o ponto. Nos dois sentidos quando alguém anda (o erro de 1 px da perna só aparecia num deles). Com
  chuva, névoa e céu limpo.
- **Desempenho.** A vista já se redesenha 30 vezes por segundo; nada de imagem nova por quadro; medir com o `medir.gd`
  da skill `revisar-mudancas` ao fechar cada cena.

## 2. Passo 0: várias cenas por noite

Hoje cada noite tem uma cena só (`Night.street_scene`, `street_scene_at`, lidos em `Main._load_night`). A noite 9 terá
o toque de recolher e o vigia, e as marcas atravessam noites (a pichação fica até ser apagada). Então:

- [x] Resource `StreetEvent` (`scripts/data/street_event.gd`, sem `class_name`: a `Night` o carrega por `preload`):
  `kind` (enum com as cenas), `at` (minutos depois do início do turno) e `every` (minutos entre repetições; 0 = uma
  vez). `Night.street_events` no lugar de `street_scene`/`street_scene_at`; as noites 3, 7 e 9 convertidas. Cena nova:
  um valor no enum do `kind`.
- [x] O `Main` desdobra as repetições até o fim do turno e entrega cada hora ao `Background.schedule(kind, at)`; o
  `Background` dispara cada uma na hora (`_events`), com `start_<cena>()` público para o painel de debug (F1).
- [x] Marcas entre noites (a pichação, a tinta nova, a banca fechada) calculadas pelas noites anteriores da lista
  (`GameContent.nights` até a atual), sem save: funciona com `--night=N`. Fica para a cena B, a primeira que precisa.
- [x] `test_content`: toda cena com hora dentro do turno; a que precisa de gente na calçada antes de `WALK_UNTIL`.

## 3. As cenas

Ordem sugerida: das que reaproveitam mais (o rig, a viatura, a passada) para as que pedem mais desenho novo.

### H. O vigia no terraço do hotel (noite 9)
- [x] Feito (`LOOKOUT_*`, `_draw_lookout`, captura `--lookout=t` ou `t0,passo,n`, botão "Vigia no terraço" no F1).
  O vigia fica encostado na platibanda, num degrau: vista de baixo, cada palmo para trás esconde mais dele. A ~9 px
  por metro, ele é desenhado pixel a pixel (`_draw_pixels`, como o rig da noite 3), com mangas de 2 px: a primeira
  versão, em silhueta de 1 px por braço e de chapéu, parecia uma aranha e foi recusada.
- De hora em hora (19h, 20h, 21h, 22h, 23h), um homem aparece no terraço do hotel, por trás da platibanda,
  e observa a rua por alguns minutos: anda até a beira, para, vira a cabeça devagar de um lado ao outro, às vezes
  se debruça, e volta para trás da caixa d'água ou da casa de máquinas. Só a silhueta contra o céu, sem luz; de
  chapéu e capa, recortado no céu (no limpo, nas estrelas; na chuva, mais apagado).

### A. O toque de recolher (noites 9 a 14)
- [x] Feito (`CURFEW_*`, `_sweep_at`, `_hurry`, `_take_cover`, captura `--curfew=t0,passo,n`, botão no F1). A
  viatura é a da noite 7 passando a ~5 km/h, com o ronco grave no meio; cada um nota quando ela está a 5 m (a beira
  da vista), no seu tempo, para de perfil olhando para ela, dá meia-volta se ia na direção dela e sai apressado para
  a esquina ou a porta do hotel mais à frente (entra recortado por ela). O holofote: um shader que clareia o que está embaixo, por baixo dos carros e
  de quem passa (`_spot_add`), o círculo com a beira definida dobrando da fachada para a calçada (e partido na quina
  da rua do cruzamento), quem ele pega aceso de frente e com a sombra projetada na parede, e ele procurando aos
  trancos e acompanhando quem pega (`_aim`); `--spot` na captura o deixa parado num ponto. Sem som de passos: a rua não tem nenhum.
- Às 21h, uma viatura passa devagar (o modelo da noite 7, com a sirene) varrendo as calçadas com o holofote da
  coluna: um facho que corre pelas fachadas e pelo chão, iluminando quem pega. Os pedestres apressam o passo (a
  passada mais curta e rápida), olham para trás e somem nas esquinas e nas portas; nenhum novo depois disso. A rua
  fica vazia pelo resto da noite (o `WALK_UNTIL` daquela noite vira as 21h).

### F. O carro de som (noite 5)
- Feito (`SPEAKER_*`, `_draw_speaker_car`, `_build_speaker`, `_listen`; `--scene=speaker`). Cartaz com brasão redondo, sem bandeira (a pedido).
- [x] Um carro passa devagar com dois alto-falantes cornetas no teto, amarrados num bagageiro, e um cartaz na
  porta. O som chega abafado pelo vidro, sobe quando ele passa na frente e some (uma voz de anúncio sintetizada, sem
  palavras distinguíveis, com eco da rua). Os pedestres param na calçada e esperam ele passar, olhando; depois seguem.

### G. A corrida (noite 8)
- Feito (`scripts/ui/chase.gd`; `--chase=t0,passo,n`).
- [x] Um jovem atravessa a rua correndo (a passada de corrida: inclinado, braços dobrados, os dois pés fora do chão
  em parte do ciclo), olha para trás e entra numa porta. Segundos depois dois homens de terno passam correndo atrás,
  param no meio da rua, olham em volta (a cabeça virando, um aponta), e voltam andando devagar.

### C. Os panfletos (noite 6)
- Feito (`scripts/ui/flyers.gd`; `--flyers=`). Quatro maços ao longo da rua; três varredores limpam a calçada; os da rua ficam até o fim da noite.
- [x] Um carro passa e, pela janela de trás, jogam um maço de panfletos: os papéis voam, giram e planam até o chão
  (cada um com a sua queda, brancos, alguns pousando na rua, outros na calçada), e ficam espalhados. Os pedestres
  desviam sem pegar. Um tempo depois, um policial vem a pé e recolhe um por um num saco, abaixando-se a cada papel;
  os que ele não pega ficam até o fim da noite.

### B. A pichação e a tinta nova (noite 4, apagada na noite 7)
- Feito (`scripts/ui/graffiti.gd`; `--graffiti=`, `--paint=`). Decisão: três letras inventadas e um risco, sem frase (nada a traduzir).
- [x] Noite 4: de madrugada, alguém de capuz para num muro da calçada de lá, olha para os lados, picha uma frase
  com spray (o braço indo e voltando, a tinta aparecendo letra por letra, o chiado do spray) e foge correndo. A
  pichação fica nas noites 4, 5 e 6.
- [x] Noite 7: um homem de macacão chega com balde e rolo, pinta por cima com a tinta de outra cor (o rolo subindo e
  descendo, a tinta cobrindo a pichação em faixas) e vai embora. A mancha de tinta nova, retangular e de outro tom,
  fica dali até o fim do jogo.

### E. A banca de jornal fechada (noite 12)
- Feito (`scripts/ui/newsstand.gd`; `--newsstand=` ou `--scene=newsstand`). Decisão: fechada e lacrada até o fim do jogo, também no amanhecer.
- [x] Dois homens de terno chegam num carro escuro, falam com o jornaleiro (gestos, o jornaleiro recua), recolhem os
  jornais da banca em pilhas para o porta-malas, baixam a porta de ferro da banca e vão embora. O jornaleiro fica
  um pouco parado na calçada e sai. A banca fica fechada (a porta de aço baixada, com cadeado) até o fim do jogo.

### F. A fuga da família (noite 14)
- Feito (`scripts/ui/moving.gd`; `--scene=moving`, F1). Às 20h, antes do toque de recolher (o turno acaba à meia-noite).
  Saiu a pedido: o motorista descendo e o colchão no bagageiro (é uma fuga, não uma mudança).
- [x] A Kombi encosta no meio-fio na frente do hotel, o motorista não desce; na varanda, a roupa recolhida peça por
  peça, a luz e a TV apagam; a família desce a rua do cruzamento às pressas (malas, o filho, o pai olhando para trás),
  atravessa a boca da rua e entra pela porta da calçada; a Kombi sai. O apartamento fica vazio até o fim do jogo.

### D. O desfile (noite 10)
- Feito (`_draw_army_truck`, `ARMY_*`, `_build_army`; `--scene=parade`). Sem tremor no vidro (saiu a pedido).
- [x] Um caminhão do exército (verde-oliva, lona sobre a carroceria, os soldados sentados de capacete nos bancos
  dos dois lados, os fuzis em pé) passa devagar. Os vidros da sala tremem: o reflexo e as gotas da janela vibram, e a
  xícara e os papéis da mesa estremecem um pouco, com o ronco grave do motor em camadas.

### I. O sinalizador (noite 15)
- Feito (`scripts/ui/flare.gd`; `--flare=t` ou `--scene=flare`, F1). Às 21h, atirado de longe atrás da cidade, sobe,
  acende vermelho e desce de paraquedas até apagar. A distância está certa (decidido: não chegar mais perto).
- [x] Halo liso somado (`_flare_add`, `_flare_halo`; o `Bloom` fazia um disco), miolo de 3×3 estourando no branco com
  raios em cruz, estouro ao acender e cintilação com falhas (`Flare.glow`), a cidade puxando para o vermelho
  (`FLARE_TINT`) e a janela vermelha projetada na sala pela camada do sol (`_flare_steep`).
- [x] A luz vindo de um lado na cidade: uma beira vermelha nos telhados, na igreja e nas paredes viradas para ele,
  andando enquanto ele desce e balança; as fachadas da rua do cruzamento mais acesas no alto que embaixo (reaproveitar
  o `spot_light.gdshader`, que clareia o que está embaixo); o tom por igual (`FLARE_TINT`) fica só de fundo.
  Feito: a beira da igreja e do alto dos prédios de longe numa camada somada logo acima da `_back` (`_flare_rim`,
  `_draw_flare_rim`, `_far_tops`; as paredes da rua do cruzamento a tapam), mais forte no lado virado para ele; a
  cornija das fachadas de lá e das paredes e a parede da esquerda da rua do cruzamento, de raspão, mais no alto, na
  camada do holofote (`_draw_flare_light`, `FLARE_RIM`).
- [x] A fumaça acesa: uma coluna mais grossa logo acima dele, rosada por baixo, e o rastro da subida mais comprido,
  desfazendo-se com o vento (`Flare.smoke`, `_draw_flare`). Feito: bolotas pixel a pixel (`Flare.puff`), o rastro
  da subida fino e o da queda grosso, abrindo com o tempo, ondulando (`CURL`), entortado pelo vento mais forte no
  alto (`SHEAR`), partindo-se com a idade e à vista por 30 s; acesa até `FLARE_SMOKE_LIT`, mais por baixo.
- [x] Quem passa pela boca da rua do cruzamento (só dali se vê o céu atrás dos prédios) para um tempo, vira para ele
  e olha para o céu; o primeiro aponta (`_skyward`, `FLARE_REACT`, `FLARE_GAZE`; captura `--walk=... --sky`). Quem vê
  é quem está na luz dele (`_flare_reach`), também quem sobe a rua do cruzamento; na luz, a beira vermelha do lado
  dele nas pessoas e o brilho vermelho no alto dos carros. Teste em `test_flow` (16b).
- [x] O sinal do roteiro: ao acender, o marcador `sinalizador_N` (`Background.flare_lit`, ligado no Main).
- [x] As nuvens perto dele com a barriga vermelha (as da noite limpa, `_draw_moon`, e as da chuva, `_draw_overcast`);
  hoje só o halo somado as clareia. Feito: somada com o halo (`_draw_flare_glow`, `_cloud_shapes`, `FLARE_CLOUD`), o
  lado de cada mancha virado para ele, mais forte quanto mais perto.
- [x] O chão da rua do cruzamento aceso por ele, menos a sombra da parede do lado dele, e mais na chuva; e na chuva o
  reflexo dele no asfalto molhado, um risco vermelho quebrado e tremendo, tapado pelas paredes, fachadas e carros
  (`_draw_flare_light`, `_draw_flare_rim`, `FLARE_GROUND`).
- [x] Conferir na chuva e na névoa, e medir o desempenho (`medir.gd` da `revisar-mudancas`). No ar molhado o halo
  é maior e mais forte (`FLARE_WET`) e as gotas do vidro e os pingos perto dele pegam o vermelho (`FLARE_BEADS`).
  Medido: aceso, +0,5 ms por quadro (~2,5 ms) e ~360 chamadas a mais, nenhum quadro acima de 16 ms.

### K. A batida no hotel (noite 13)
- Feito (`scripts/ui/raid.gd`; `--raid=t0,passo,n` ou `--scene=raid`, F1). Às 22h, depois do toque de recolher, com a
  rua vazia.
- [x] Um camburão (cabine preta, o cofre de chapa branca com "POLÍCIA", a janelinha gradeada e a sirene) encosta logo
  depois da porta do hotel, que fica à vista, e uma viatura logo atrás. O motorista do camburão desce pela porta do
  lado de cá e fica de guarda; os outros três entram no hotel, e os andares acendem um a um. Saem em fila: um policial,
  os cinco presos algemados (as mãos juntas nas costas, o brilho do aço, a cabeça baixa), um policial no meio e outro
  no fim, pela rua na frente do camburão; o da guarda abre as portas do cofre (a de cá dobra rente ao lado, a de lá
  fica para trás) e ajuda cada um a subir o degrau; fecha as duas (batendo), cada um volta ao seu carro pela porta
  dele, e saem. As sirenes iluminam a rua, a fachada, quem o facho pega, o asfalto molhado e a sala.

## 4. Fechando cada cena
- [ ] Opção na captura (`tools/shot.gd`) e botão no F1.
- [ ] `test_content` cobre a hora e a noite; `tests/run.sh` inteiro.
- [ ] Item no `HISTORICO.md`, a linha da cena no `scripts/ui/CLAUDE.md` e, se mudar a regra, no `CLAUDE.md`.
- [ ] Aprovação do usuário antes da próxima cena.

## 5. Decisões em aberto
- (decidido: a banca fica fechada até o fim do jogo; a pichação é de letras inventadas, sem texto)
