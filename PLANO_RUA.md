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
- [ ] Marcas entre noites (a pichação, a tinta nova, a banca fechada) calculadas pelas noites anteriores da lista
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
- [ ] Às 21h, uma viatura passa devagar (o modelo da noite 7, com a sirene) varrendo as calçadas com o holofote da
  coluna: um facho que corre pelas fachadas e pelo chão, iluminando quem pega. Os pedestres apressam o passo (a
  passada mais curta e rápida), olham para trás e somem nas esquinas e nas portas; nenhum novo depois disso. A rua
  fica vazia pelo resto da noite (o `WALK_UNTIL` daquela noite vira as 21h).

### F. O carro de som (noite 5)
- [ ] Um carro passa devagar com dois alto-falantes cornetas no teto, amarrados num bagageiro, e um cartaz na
  porta. O som chega abafado pelo vidro, sobe quando ele passa na frente e some (uma voz de anúncio sintetizada, sem
  palavras distinguíveis, com eco da rua). Os pedestres param na calçada e esperam ele passar, olhando; depois seguem.

### G. A corrida (noite 8)
- [ ] Um jovem atravessa a rua correndo (a passada de corrida: inclinado, braços dobrados, os dois pés fora do chão
  em parte do ciclo), olha para trás e entra numa porta. Segundos depois dois homens de terno passam correndo atrás,
  param no meio da rua, olham em volta (a cabeça virando, um aponta), e voltam andando devagar.

### C. Os panfletos (noite 6)
- [ ] Um carro passa e, pela janela de trás, jogam um maço de panfletos: os papéis voam, giram e planam até o chão
  (cada um com a sua queda, brancos, alguns pousando na rua, outros na calçada), e ficam espalhados. Os pedestres
  desviam sem pegar. Um tempo depois, um policial vem a pé e recolhe um por um num saco, abaixando-se a cada papel;
  os que ele não pega ficam até o fim da noite.

### B. A pichação e a tinta nova (noite 4, apagada na noite 7)
- [ ] Noite 4: de madrugada, alguém de capuz para num muro da calçada de lá, olha para os lados, picha uma frase
  com spray (o braço indo e voltando, a tinta aparecendo letra por letra, o chiado do spray) e foge correndo. A
  pichação fica nas noites 4, 5 e 6.
- [ ] Noite 7: um homem de macacão chega com balde e rolo, pinta por cima com a tinta de outra cor (o rolo subindo e
  descendo, a tinta cobrindo a pichação em faixas) e vai embora. A mancha de tinta nova, retangular e de outro tom,
  fica dali até o fim do jogo.

### E. A banca de jornal fechada (noite 12)
- [ ] Dois homens de terno chegam num carro escuro, falam com o jornaleiro (gestos, o jornaleiro recua), recolhem os
  jornais da banca em pilhas para o porta-malas, baixam a porta de ferro da banca e vão embora. O jornaleiro fica
  um pouco parado na calçada e sai. A banca fica fechada (a porta de aço baixada, com cadeado) até o fim do jogo.

### D. O desfile (noite 10)
- [ ] Um caminhão do exército (verde-oliva, lona sobre a carroceria, os soldados sentados de capacete nos bancos
  dos dois lados, os fuzis em pé) passa devagar. Os vidros da sala tremem: o reflexo e as gotas da janela vibram, e a
  xícara e os papéis da mesa estremecem um pouco, com o ronco grave do motor em camadas.

## 4. Fechando cada cena
- [ ] Opção na captura (`tools/shot.gd`) e botão no F1.
- [ ] `test_content` cobre a hora e a noite; `tests/run.sh` inteiro.
- [ ] Item no `HISTORICO.md`, a linha da cena no `scripts/ui/CLAUDE.md` e, se mudar a regra, no `CLAUDE.md`.
- [ ] Aprovação do usuário antes da próxima cena.

## 5. Decisões em aberto
- A banca fecha até o fim do jogo ou reabre noites depois?
- A frase da pichação: legível (e traduzida) ou só rabiscos de letras?
