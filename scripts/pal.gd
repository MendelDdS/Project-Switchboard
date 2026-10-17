class_name Pal
extends RefCounted
## Paleta e fontes compartilhadas.

const VOID := Color("050607")
const ROOM := Color("131a1d")
const PANEL := Color("2f2a21")
const PANEL_HI := Color("4b4332")
const PANEL_LO := Color("18150f")
const EDGE := Color("0b0a07")
const BRASS := Color("b8924e")
const PAPER := Color("d8caa3")
const PAPER_2 := Color("c2b288")
const PAPER_LINE := Color("b3a37a")
const INK := Color("2a2319")
const INK_SOFT := Color("5a4d3a")
const INK_RED := Color("6e1a12")
const PEN := Color("2b3f78")       ## a caneta azul do supervisor: o parecer do relatório e o bilhete da noite (`PaperInk`, `[hand]`)
const AMBER := Color("f3a83c")
const GREEN := Color("8dbb6c")
const RED := Color("d4553f")
const GHOST := Color("cfe6d2")
const TEXT := Color("e6dbbd")
const DIM := Color("9a917a")
const GLOW := Color("ffd183")

## Os materiais dos objetos da mesa, os mesmos no objeto (`Background._art_*`) e no papel aberto dele (`PaperDeco` e as
## ferramentas): o que muda numa ponta muda na outra.
const BOOK := Color("b48c1c")   ## a capa da lista telefônica de cima (mostarda; as outras duas, vermelha e azul)
const GOLD := Color("e0c07a")   ## o dourado das letras e dos filetes das listas
const BOOK_BLUE := Color("2a4a7c")     ## a capa azul da lista do meio
const BOOK_LEAVES := Color("c6b994")   ## o miolo das listas visto de lado, na mesa...
const BOOK_PAGE := Color("e3d6b2")     ## ...e a página da lista aberta (`PhoneBook`)
const BOOK_TAG: Array[Color] = [Color("e2d7b6"), Color("4a4038"), Color("d8cba6")]   ## na capa da lista de cima: a etiqueta colada, o ano nela e a folha à mostra na ponta dobrada
const PAD_BACK: Array[Color] = [Color("8a7f6c"), Color("6c6253"), Color("463f35")]   ## o papelão de trás do bloco de fichas: a beira na luz, o papelão, a beira na sombra
const PAD_TAPE: Array[Color] = [Color("7c3a2c"), Color("5c2a20"), Color("3c1a14")]   ## a fita de pano da colagem, no alto do bloco
const NOTE_PAGE := Color("d2c5a0")     ## a ficha de ocorrências (o bloco de fichas)...
const NOTE_RULE := Color("bfb38e")     ## ...a pauta...
const NOTE_MARGIN := Color("b07060")   ## ...e a margem vermelha
const NOTE_HAND := Color("6a6474")     ## a letra a lápis nas fichas do bloco, na mesa
## O lápis do bloco de fichas: o corpo amarelo gasto, a madeira apontada e a borracha (luz, meio, sombra), e o grafite.
const PENCIL_BODY: Array[Color] = [Color("c4a042"), Color("957622"), Color("67521a")]
const PENCIL_WOOD: Array[Color] = [Color("c8aa80"), Color("b0926a"), Color("8a7050")]
const PENCIL_ERASER: Array[Color] = [Color("c08a80"), Color("a86a62"), Color("7a4a44")]
const PENCIL_LEAD := Color("2a2620")
## Os carimbos do caderno (`Notebook.STAMPS`): Comum (tinta azul), Emergência (vermelho), Trote (sépia) e a não atendida
## (grafite: registrada sozinha).
const LOG_STAMPS: Array[Color] = [Color("3a4f7a"), Color("8a2a1c"), Color("7a5214"), Color("5c5a55")]
const PENDING: Array[Color] = [Color("d4c084"), Color("cdbda4")]   ## as tiras dos registros pendentes saindo do bloco de fichas
const BOARD: Array[Color] = [Color("8a5e3a"), Color("6e4a2c"), Color("4a3018"), Color("7e5634")]   ## a tábua da prancheta: a beira de cima, na luz, a tábua, a beira na sombra e a da esquerda
const SHEET := Color("cdc09c")       ## a folha da prancheta (a nova, ainda não lida: SHEET_NEW)
const SHEET_NEW := Color("e0d5b4")
const SHEET_INK: Array[Color] = [Color("5a5448"), Color("6a6458")]   ## a letra das folhas da prancheta: o título e as linhas
const FORM_RED := Color("a8564a")    ## o fio vermelho do cabeçalho da folha, a marca das tiras e as tiras vermelhas das listas
const STRIP := Color("e0d4b0")       ## as tiras de papel creme marcando páginas nas listas
const NEWSPRINT := Color("d3c69f")   ## o papel-jornal
const NEWS_INK := Color("776c51")    ## a letra miúda das colunas do jornal
const NEWS_TYPE: Array[Color] = [Color("2a2620"), Color("3a3630"), Color("8a8068")]   ## a tinta do jornal da mesa: o nome dele, as manchetes (e o título dos classificados) e a data
const NEWS_FOLD: Array[Color] = [Color("e2d6b2"), Color("a89c78"), Color("dccfa8")]   ## a beira do jornal: a de cima, na luz, a de baixo e dos lados, na sombra (e o fundo do vinco), e o claro do vinco
const NEWS_PHOTO: Array[Color] = [Color("3e382e"), Color("938767"), Color("675f4c")]   ## a foto do jornal: a moldura e a tinta dela, o céu e o chão (na mesa e no jornal aberto)
const TICKET := Color("e4dcc0")        ## o bilhete de tarifação (`TollTicket`)...
const TICKET_EDGE := Color("a89c78")   ## ...a beira dele...
const TICKET_FORM := Color("34507e")   ## ...e o formulário, impresso em azul (o cartão do despacho, em vermelho)
const TOLL_INK := Color("b03a2e")      ## a tinta do carimbo do calculógrafo: a marca no bilhete, o feltro da almofada
const MAP_PAPER := Color("ddd1ad")   ## o papel do mapa, e as ruas são ele à mostra
const MAP_TINTS := {3: Color("c9b88a"), 1: Color("c2ab8c"), 2: Color("b6b38c")}   ## os quarteirões de cada bairro (setor): ocre, sépia, oliva
const MAP_PLAZA := Color("8a9168")   ## a praça
const MAP_TREE := Color("5f7445")    ## as árvores
const MAP_LANDMARK := Color("b4866a")   ## os lugares que têm nome no mapa: um prédio de telhado de barro
const MAP_INK := Color("3a3226")     ## o traço do mapa: as letras, a beira dos lugares, o coreto
const MAP_BANDSTAND := Color("e6dab8")   ## o coreto da praça
const MAP_FIELDS: Array[Color] = [Color("a9b37d"), Color("bfae7c")]    ## as roças da zona rural: verde e palha...
const MAP_FURROWS: Array[Color] = [Color("8f9a63"), Color("a8956a")]   ## ...e os sulcos de cada uma
const MAP_DIRT := Color("b49d72")    ## as estradas de terra
const MAP_RIVER := Color("6f8fa0")   ## o rio
const SEAL := Color("8e2a22")        ## o vermelho do selo do mapa (e da capa da lista de baixo)
const MAP_MARK := Color("8e2a17")    ## o local marcado no mapa: o trecho tracejado e o quadradinho no meio dele
const MAP_TAG := Color("f4ecd2")     ## a etiqueta de papel com o nome do trecho sob o mouse
## O cartão perfurado do despacho (`PunchCard`; a ponta dele saindo da impressora, na unidade da mesa).
const CARD := Color("e9dcb4")
const CARD_EDGE := Color("a8966b")   ## a beira dele (e a espessura, mais escura)
const CARD_FORM := LOG_STAMPS[1]     ## o formulário, impresso na tinta vermelha das emergências (o carimbo do caderno)
const CARD_RULE := Color(0.35, 0.43, 0.55, 0.3)   ## a pauta, como a do caderno
const CARD_HOLE := Color("17110b")   ## o furo
const CARD_BUSY := Color("8a3a14")   ## a unidade ocupada: o nome e o estado dela
const HAZARD := Color("d9a521")      ## as faixas de perigo da trituradora, no despacho aberto e na unidade da mesa
const NICKEL: Array[Color] = [Color("f4f0e6"), Color("d6d1c3"), Color("8e897c"), Color("45413a")]   ## o níquel (brilho, luz, meio, sombra): o prendedor da prancheta, o aro das lâmpadas

## Os metais e a baquelite da mesa comutadora, do escuro ao claro.
## A quina do níquel descendo até o painel (`Switchboard.NICKEL_EDGE`): na luz, no meio e na sombra.
const NICKEL_EDGE: Array[Color] = [Color("6e675a"), Color("514b40"), Color("3a352d")]
## O latão das plaquetas, dos aros dos buracos da prateleira e do friso na beira dela, e das etiquetas das teclas: a
## beira funda, a beira, a sombra, o friso, o meio, a luz e o brilho.
const BRASS_PLATE: Array[Color] = [Color("140d06"), Color("3a2a12"), Color("7a6230"), Color("8a6a2e"), Color("b0904c"),
	Color("c4a35a"), Color("e6cf8e")]
## O latão dos plugs (a aba e a ponta): da beira escura ao brilho, com o de sempre (`BRASS`) e o dourado (`GOLD`).
const BRASS_PLUG: Array[Color] = [Color("3a2810"), Color("5a4218"), Color("7a5a24"), BRASS, GOLD, Color("ecd29a")]
const PLUG_INSULATOR: Array[Color] = [Color("141210"), Color("2a2622")]   ## os isolantes pretos da ponta do plug
## A baquelite preta dos botões do console: a beira, a sombra e o meio da saia, e a sombra, o meio e a luz do tampo.
const BAKELITE: Array[Color] = [Color("120e0a"), Color("1a1612"), Color("2a2420"), Color("3a332c"), Color("4a4038"),
	Color("5a5048")]
const SCREW: Array[Color] = [Color("1a0f08"), Color("2a1a0f"), Color("4a3a24"), Color("8e7a5a")]   ## os parafusos do console: sombra, meio, luz e a fenda
## Os cabos (`Switchboard.CORD_COLORS`): o pano de cada um e o brilho dele; o corpo do plug na mesma cor.
const CORDS := [
	[Color("3d6e34"), Color("6c9e58")],
	[Color("8e2a22"), Color("c4493b")],
	[Color("2a4a7c"), Color("4f7bb6")],
	[Color("b48c1c"), Color("e6c24c")],
	[Color("b8b2a2"), Color("e4dfd0")],   # branco de pano velho, puxado para o creme
	[Color("2a2723"), Color("57524a")],   # preto: o brilho mais claro, senão o trançado some
]
## O aro das tomadas (`Switchboard.JACK_METAL`), do claro ao escuro, cada pixel no tom da luz dele: a face e a parede
## da bucha; e o furo.
const JACK_METAL := {"face": [Color("fff2d8"), Color("e4c9a0"), Color("c3a37c"), Color("98785a"), Color("6a503a")],
	"wall": [Color("ddd2b6"), Color("a69072"), Color("735e47"), Color("4a3b2d"), Color("2e251c")]}
const JACK_HOLE := Color("070605")
const NUT_HOLE := Color("1c130b")      ## o fundo do furo da porca da chave de escuta: marrom quase preto
const BANK_PLATE := Color("4d483d")    ## a chapa sobre o banco que ainda não está em uso
const LAMP_GLASS := Color("6b6556")    ## o vidro leitoso da lâmpada apagada (escuro, parecia o furo de uma tomada)
const ENGRAVED := Color("1d1a14")      ## o número gravado nas plaquinhas das linhas
const NUMBER_PAINT := Color("d8c9a2")  ## os números pintados em cima dos destinos livres
const STENCIL := Color("c9b98f")       ## o aviso pintado com estêncil na chapa do banco
const BALLOON := Color("0e0c08")       ## o fundo do balão com a informação de uma tomada
const KEY_WELL := Color("0b0907")      ## o poço das teclas do console, embaixo da tecla
const SHELF_WOOD: Array[Color] = [Color("4e321d"), Color("5a3a22")]   ## a prateleira do console, na sala: o veio e a tábua
## A sala (`Background`): a parede, o vão da janela e a persiana, o armário de aço, o conduíte e o que fica na parede.
const WALL_PAINT := Color("172023")   ## a tinta da parede do fundo...
const WALL_LINES: Array[Color] = [Color("141c1f"), Color("1b2629"), Color("1a2427"), Color("1e2a2d")]   ## ...e nela a listra larga, o fio de luz dela, a listra fina e o friso
const SIDE_WALL: Array[Color] = [Color("202d30"), Color("1b2629"), Color("24323a"), Color("26353a")]   ## a parede da direita, virada para a luminária: a tinta, a listra, o fio de luz e o friso
const REVEAL: Array[Color] = [Color("0d1315"), Color("223033"), Color("3a5263")]   ## o vão da janela: a verga e as faces de dentro, longe e perto da rua
const BLIND: Array[Color] = [Color("30343a"), Color("6b5f4c"), Color("8a8070"), Color("a89e8a")]   ## a persiana: a sombra embaixo da lâmina, o puxador, a lâmina (e o cordão) e a beira na luz
const SIGN_ENAMEL := Color("1f3b35")   ## a placa da companhia telefônica: o esmalte verde-escuro...
const SIGN_INK := Color("d8cfae")      ## ...e o creme das letras e do filete
const NAIL: Array[Color] = [Color("5a534a"), Color("e0d6c4")]   ## o prego do quadro tirado: o ferro e a cabeça na luz
const OUTLET: Array[Color] = [Color("6e6450"), Color("b3a689"), Color("cfc3a2")]   ## a tomada de baquelite creme: a beira e o parafuso, o espelho e a beira de cima na luz
const OUTLET_PLUG: Array[Color] = [Color("1a1612"), Color("3a342c"), Color("3a3028")]   ## o plugue nela: a baquelite preta, a luz no alto dele e a do fio
const CALENDAR_PAPER := Color("e3d6b2")   ## a folhinha: o papel...
const CALENDAR_HEAD: Array[Color] = [Color("8e2a22"), Color("b04a3e")]   ## ...o cabeçalho vermelho e a beira de cima dele...
const CALENDAR_INK: Array[Color] = [Color("4e4636"), Color("a8382c")]   ## ...os dias e os domingos...
const CALENDAR_NAIL := Color("3a3a3a")    ## ...e o prego
const RED_PEN := Color("b03a2e")   ## a caneta vermelha: os dias riscados da folhinha e o sublinhado do bilhete no armário
## O ferro do conduíte e da caixa de passagem, uma rampa (`Background._draw_conduit`): a sombra do cano e das
## braçadeiras, frias; o cano e a caixa (o 2), a tampa, a beira das braçadeiras e da caixa, os parafusos e o lado do
## cano virado para a luminária, quentes.
const CONDUIT: Array[Color] = [Color("282f37"), Color("313940"), Color("4a5256"), Color("545c60"), Color("6f7672"),
	Color("7e8380"), Color("8e8e84")]
const CONDUIT_CABLES: Array[Color] = [Color("4a3a2c"), Color("5a3428"), Color("37403f"), Color("524430")]   ## os cabos de pano do painel até ela
const STEEL := Color("566052")   ## o aço pintado do armário...
## ...e a rampa dele (`STEEL_TONES[3]` é o `STEEL`): as faces e as beiras na sombra mais frias, as que pegam a luz mais
## quentes, no lugar dele escurecido e clareado.
const STEEL_TONES: Array[Color] = [Color("2a3433"), Color("394341"), Color("464f48"), STEEL, Color("6a705e"),
	Color("7f836c"), Color("939379")]
## A tinta da parede do fundo pela luz da luminária nela (`Background._wall_runs`): longe, mais fria; no meio, a de
## sempre; perto da boca do cone, mais quente. O brilho quase não muda: o escuro é o da sala (`_noir_params`), por cima.
const WALL_TONES: Array[Color] = [Color("12202c"), WALL_PAINT, Color("2a2a20")]
## O escuro do armário, do mais fundo ao menos: o vão aberto, o fundo dele, o lado de baixo das prateleiras, a parede
## de dentro, as frestas, as fendas das venezianas e o tampo das prateleiras.
const STEEL_DARK: Array[Color] = [Color("0d110d"), Color("151a14"), Color("1c211b"), Color("1d241c"), Color("23281f"),
	Color("2e342b"), Color("3a4236")]
## O cromado do armário, do relógio e do guarda-chuva (o puxador, as dobradiças, o porta-etiqueta, a rodinha, a haste),
## da sombra ao brilho.
const CHROME: Array[Color] = [Color("3a3d33"), Color("4a4840"), Color("5a574e"), Color("8e897c"), Color("b8b2a2"),
	Color("c9c4b5"), Color("ece7da")]
const FOLDERS: Array[Color] = [Color("6e5a3a"), Color("8a7a5a"), Color("4a5a6a"), Color("7a3a2a")]   ## as pastas nas prateleiras do armário
const LABEL_PAPER := Color("e3d6b2")   ## o cartão do porta-etiqueta do armário e as etiquetas das pastas...
const LABEL_INK := Color("4a4438")     ## ...e a letra datilografada no cartão
const NOTE_PAPER := Color("efe6cc")  ## o bilhete com o número anotado, colado no armário...
const NOTE_INK := Color("2a2a4a")    ## ...e a caneta dele
const UMBRELLA_WOOD: Array[Color] = [Color("6b4529"), Color("4a2c18"), Color("2a1a0f")]   ## o cabo do guarda-chuva: luz, meio, sombra...
const UMBRELLA_CLOTH := Color("1b1d24")   ## ...e o pano
const POSTER := Color("e8dcc0")      ## o cartaz da quermesse: o papel...
const POSTER_INK := Color("5a4d3a")  ## ...o barbante e as linhas do convite...
const POSTER_FLAGS: Array[Color] = [Color("b03a2e"), Color("e0b040"), Color("3a6aa0"), Color("4a8a4a")]   ## ...as bandeirinhas...
const POSTER_FIRE: Array[Color] = [Color("e07a2a"), Color("f0c040"), Color("6b4529"), Color("4a2f1c"), Color("8a5a36")]   ## ...a fogueira: o fogo, a chama de dentro, as toras e a luz nelas...
const POSTER_TACK: Array[Color] = [Color("e07060"), Color("b03a2e"), Color("7a2418")]   ## ...e a tachinha
## A vista da janela (`Background`, `background_view.gd`): o céu, a cidade de longe, os prédios de lá, a rua e o arbusto.
const SKY := {"rain": Color("0b141c"), "fog": Color("1b252b"), "clear": Color("0a1422")}   ## o céu de cada clima
const FLASH := Color("a2acbc")   ## o céu e as nuvens clareados pelo relâmpago
const STARS: Array[Color] = [Color("56606c"), Color("c9d2dc")]   ## as estrelas: piscando e acesas
const MOON := Color("d8d0a8")       ## a lua no alto...
const MOON_LOW := Color("e0a868")   ## ...e perto do horizonte (o ar mais grosso avermelha)
const CLOUD_RIM := Color("8a8f8a")  ## a beira das nuvens na frente da lua
## O amanhecer da última noite (`Background.dawn`: 0 às 4h05, 1 às 6h): [quando, os quatro tons do céu do alto ao
## horizonte, em `DAWN_STOPS`], da noite limpa ao dia: o azul-escuro, o violeta, o rosa e o laranja forte com o sol
## nascendo e, passado o crepúsculo, o azul no alto clareando liso até o horizonte.
const DAWN_SKY := [[0.0, [Color("0a1422"), Color("0c1626"), Color("151e2e"), Color("27303c")]],
	[0.22, [Color("0e1832"), Color("18213f"), Color("2c2a4c"), Color("4c3552")]],
	[0.48, [Color("1c3260"), Color("5a4a80"), Color("c0607a"), Color("f08c5a")]],
	[0.68, [Color("3a6898"), Color("d07088"), Color("f89858"), Color("ffcc60")]],
	[0.84, [Color("4a88bc"), Color("e0988c"), Color("ffb868"), Color("ffe090")]],
	[1.0, [Color("2460b4"), Color("4a86cc"), Color("9cc0e0"), Color("e8ecdc")]]]
const DAWN_STOPS := [0.0, 0.32, 0.62, 1.0]   ## onde fica cada tom, do alto do céu à vista (0) ao horizonte (1)
const DAWN_GLOW := Color("ffb070")    ## o clarão do lado onde o sol nasce
const DAWN_CLOUD := Color("f0a890")   ## as nuvens pegando a luz do sol por baixo...
const DAY_CLOUD := Color("eef0f0")    ## ...e já de dia
const DAWN_CLOUD_TOP := Color("6c6894")   ## o alto delas, ainda na sombra, enquanto a beira de baixo pega o sol
const DAWN_MIST := Color("b8b0c4")   ## a neblina baixa da madrugada no fundo da rua (dourada perto do sol)
const DAWN_SHADE := Color("3c4c80")  ## a luz fria do céu nas faces de costas para o sol (as fachadas de lá)
const SUN_CORE := Color("fffcf0")     ## o sol: o miolo quase branco...
const SUN := Color("ffe68c")          ## ...o disco...
const SUN_RIM := Color("ffb050")      ## ...a beira dele e o halo
const DAYLIGHT_DAWN := Color("7a88b8")   ## a luz do dia entrando pela janela na sala: a do céu antes do sol, fria...
const DAYLIGHT_SUN := Color("f0d8b8")    ## ...e a do sol, quente (`Background.daylight`)...
const SUN_ROOM := Color("ffc070")        ## ...e o sol entrando direto, a janela desenhada no peitoril e no tampo: dourado claro (`_draw_sun`)
const SUN_LOW := Color("c8501c")      ## ...e a luz dele, baixo, nas fachadas viradas para ele (forte: a luz do dia por cima a desbota)
const SUN_RAY := Color("fff0c8")      ## os raios crepusculares...
const RAY_SHADOW := Color("1a1620")   ## ...e a sombra da igreja no meio deles
const FLARE: Array[Color] = [Color("ff9a50"), Color("70c8c0"), Color("ffe080"), Color("b080d0")]   ## os reflexos da lente
const OVERCAST_LIT := Color("3e3733")    ## a nuvem da chuva clareada por baixo pelas luzes da cidade (perto do horizonte)
const OVERCAST_DARK := Color("0d1216")   ## os vãos mais escuros entre elas
const OVERCAST_DECK := Color("1b1e23")   ## o fundo de nuvem no alto (no horizonte, `OVERCAST_LIT`)
const CITY_FAR: Array[Color] = [Color("070b10"), Color("141c22")]   ## a cidade no fim da rua e a igreja: na noite e na névoa
const CITY_LIT: Array[Color] = [Color("d59a3d"), Color("b38a3c"), Color("e2b25a")]   ## as janelas acesas da cidade
const WINDOW_DARK := Color("080b0e")   ## o vidro das janelas apagadas
## As fachadas de lá e as paredes da rua do cruzamento, uma rampa por tinta (o tom dela em `FACADE_MID`): a quina, o
## vão e a verga descem para o azul da noite, a cornija e o peitoril sobem para o quente dos postes...
const FACADE_TONES := [
	[Color("080b11"), Color("090b0e"), Color("0c0c0d"), Color("100e0e"), Color("1c1714"), Color("2c241d"), Color("403529"), Color("554635")],
	[Color("070b12"), Color("070b10"), Color("090c10"), Color("0b0e12"), Color("13171b"), Color("242424"), Color("39352f"), Color("4e463b")],
	[Color("080b10"), Color("090b0e"), Color("0c0b0c"), Color("0f0d0c"), Color("1a1512"), Color("2a221c"), Color("3f3328"), Color("534434")],
	[Color("070c12"), Color("080c11"), Color("0a0d11"), Color("0e1013"), Color("171a1d"), Color("272726"), Color("3c3731"), Color("51483c")]]
## ...e o prédio de tijolos da esquina
const BRICK_TONES: Array[Color] = [Color("0d0d12"), Color("110e10"), Color("18100f"), Color("211410"), Color("3a2219"),
	Color("482e22"), Color("5a3e2e"), Color("6b4e39")]
const FACADE_MID := 4
## O asfalto, na noite e na névoa, em rampa (o tom dele em `STREET_MID`): as manchas, os remendos e o grão...
const ASPHALT_TONES := [[Color("05080c"), Color("06080c"), Color("090c10"), Color("101214"), Color("1a1a1a")],
	[Color("090d11"), Color("0c1114"), Color("141a1f"), Color("1b2023"), Color("242728")]]
## ...e a calçada de lá, com as juntas das lajotas
const SIDEWALK_TONES := [[Color("0b1014"), Color("101418"), Color("1b2227")], [Color("0e1318"), Color("141a1e"), Color("232b31")]]
const STREET_MID := 2
const CURB: Array[Color] = [Color("2a3237"), Color("4a555c"), Color("606463")]   ## o meio-fio de lá: a face, a quina e a quina embaixo de um poste
const LAMP_POST := Color("1d262c")    ## os postes (e o braço do letreiro do hotel)...
const STREET_LAMP := Color("ffd88a")  ## ...e a luz deles (também nos pingos e nas gotas do vidro perto deles)
const BAR_JAMB := Color("1a0f0a")   ## o bar: o batente da vitrine e da porta...
const BAR_LIGHT: Array[Color] = [Color("c98a3e"), Color("f0c070")]   ## ...o salão aceso, no alto e embaixo...
const BAR_WOOD := Color("3a2414")   ## ...o caixilho e a folha da porta...
const BAR_GLASS := Color("8a5a2a")  ## ...o vidro dela, com a luz de dentro...
const BAR_LETTERING := Color("7a3a1a")   ## ...e o letreiro pintado na vitrine
const HOTEL_DOOR: Array[Color] = [BAR_GLASS, Color("e0a858")]   ## a porta aberta do hotel, com a luz do saguão: no alto e embaixo
const MARQUEE: Array[Color] = [Color("2a1c16"), Color("6a1e18")]   ## a marquise dele: o alto e a beira vermelha
const BALCONY_POT := Color("4a2a1c")   ## a varanda do apartamento: os vasos...
const BALCONY_PLANT: Array[Color] = [Color("142219"), Color("1c2e22")]   ## ...as plantas...
const BALCONY_ROOM := Color("0b1018")   ## ...a sala escura atrás do vidro, com a luz da TV...
const BALCONY_IRON := Color("15191c")   ## ...o gradil de ferro...
const BALCONY_SLAB := Color("2a1a14")   ## ...e a beira da laje
const CHURCH_CLOCK: Array[Color] = [Color("2a2016"), Color("e2b25a")]   ## o relógio da torre: os ponteiros e o mostrador aceso
const SHRUB: Array[Color] = [Color("08120c"), Color("0f2016"), Color("193323"), Color("2a4a33")]   ## as folhas do arbusto, do escuro ao claro...
const SHRUB_FLASH := Color("5a7090")   ## ...e acesas pelo relâmpago
const RAIN_BEAD: Array[Color] = [Color("1c2a32"), Color("7f98a8")]   ## as gotas paradas no vidro: a gota e o brilho
## Quem passa na vista (`background_view.gd`): o vira-lata caramelo, apagado pela noite...
const STRAY_COAT := Color("4e3218")
## ...as roupas de quem passa na calçada de lá (`_walker` sorteia), em cores apagadas pela noite, como o pelo do
## vira-lata: aparecem contra a calçada e acendem embaixo dos postes. Casacos e paletós; vestidos e saias; calças;
## a pele; os guarda-chuvas...
const WALK_COATS: Array[Color] = [Color("4a3020"), Color("2c3448"), Color("444232"), Color("4e2426"), Color("5e5440"),
	Color("38383c"), Color("1c1c20"), Color("3e2c3a")]
const WALK_DRESSES: Array[Color] = [Color("5e2a34"), Color("2a4452"), Color("6a5c30"), Color("365032"), Color("4c3050"), Color("5a4a44")]
const WALK_LEGS: Array[Color] = [Color("18181c"), Color("26221c"), Color("262a34"), Color("3a342a")]
const WALK_SKIN: Array[Color] = [Color("b08868"), Color("8a5e40"), Color("62422c"), Color("44302a")]
const WALK_UMBRELLAS: Array[Color] = [Color("121318"), Color("121318"), Color("4e1a1e"), Color("1c2640"), Color("2a3426")]
const BRIEFCASE := Color("2a1a10")   ## ...a pasta na mão...
const SILHOUETTE := Color("07090c")  ## ...quem fica em silhueta (o homem do mistério, o passageiro do táxi, quem fuma na varanda, o ciclista)...
const CLERK := Color("120a06")       ## ...o recepcionista no telefone do hotel, contra a porta acesa...
const CAT := Color("0b0c0f")         ## ...e o gato preto
## Os carros: uma rampa por cor de lataria, de noite (escurecida; o tom dela em `CAR_MID`): a sombra fria embaixo e
## dentro (o arco da roda, o fundo da caçamba, a frente e a traseira), a luz quente na beira do para-lama...
const CAR_TONES := [
	[Color("080e15"), Color("090f15"), Color("0c1218"), Color("10161d"), Color("1b2530"), Color("2b3137"), Color("3f4141"), Color("54504a")],   # azul
	[Color("0b0c11"), Color("0e0b0f"), Color("130c0e"), Color("1a0f0f"), Color("2e1816"), Color("3d251f"), Color("4f362b"), Color("624637")],   # vinho
	[Color("0c1014"), Color("101214"), Color("161616"), Color("1e1d1a"), Color("35312a"), Color("433c32"), Color("554b3c"), Color("685946")],   # bege
	[Color("070e12"), Color("080f11"), Color("0b1211"), Color("0e1713"), Color("18261d"), Color("283226"), Color("3d4231"), Color("52513c")],   # verde
	[Color("0d1218"), Color("111519"), Color("191c1e"), Color("222526"), Color("3c403f"), Color("4a4a45"), Color("5b574e"), Color("6d6456")],   # branco
	[Color("090d14"), Color("0b0e13"), Color("0f1015"), Color("141419"), Color("222228"), Color("312e30"), Color("453e3a"), Color("594e44")],   # cinza
	[Color("0c0f11"), Color("10100f"), Color("16140e"), Color("1f1a0f"), Color("362b16"), Color("44371f"), Color("56462b"), Color("685537")],   # mostarda
]
const CAR_MID := 4
const CAR_UPPER := Color("4a4c48")   ## ...a parte de cima da Kombi, clara...
const TRUCK_BOX: Array[Color] = [Color("0d1115"), Color("121415"), Color("1a1a18"), Color("23221d"), Color("3e3a30"), Color("4c4537"), Color("5d5241"), Color("6e604a")]   ## ...o baú do caminhão...
const CAR_SKY := Color("2a3440")     ## ...o céu refletido no teto e no capô (de noite, a luz que vem de cima)...
const CAR_GLASS := Color("0b1218")   ## ...os vidros (com o céu refletido) e o reflexo neles...
const CAR_GLINT := Color("3a4a58")
const CAR_CHROME := Color("5a6670")  ## ...o cromado...
const CAR_HUBCAP: Array[Color] = [Color("22292e"), Color("3a444b"), Color("4a545b")]   ## ...a calota, da sombra à luz...
const CAR_TYRE: Array[Color] = [Color("030506"), Color("0a0d0f"), Color("14181b")]     ## ...e o pneu
const CAR_HEAD := Color("fff1c8")   ## os faróis...
const CAR_TAIL := Color("8a1e14")   ## ...as lanternas...
const TAXI_SIGN := Color("f0d88a")  ## ...e a placa acesa do táxi
const SMOKE := Color(0.7, 0.72, 0.76)   ## a fumaça do cigarro na varanda, no escuro (`Background._draw_smoke`; perto do poste, esquenta)
const SIGN_RED := Color("ff4a3a")   ## o letreiro de neon do hotel: aceso...
const SIGN_OFF := Color("3a1512")   ## ...apagado...
const SIGN_BOX: Array[Color] = [Color("0a0d10"), Color("361818")]   ## ...e a caixa dele, com a beira tingida pelo neon aceso (o braço é o dos postes, `LAMP_POST`)
const DESK_UNDER := Color("0a0705")   ## embaixo da borda da frente do tampo
## O relógio de flip da mesa, de baquelite creme numa base escura: a base (o lado, a frente e o tampo)...
const CLOCK_BASE: Array[Color] = [Color("2a1d13"), Color("3a2a1c"), Color("4e3a28")]
## ...a caixa (o lado e o rebaixo da janela, as fendas, a frente, o tampo e a beira de cima da frente)...
const CLOCK_CASE: Array[Color] = [Color("998a66"), Color("a89a76"), Color("c9bb92"), Color("dccfa8"), Color("e4d8b4")]
const CLOCK_WINDOW := Color("0e0c0a")   ## ...a janela...
const FLIP_CARD: Array[Color] = [Color("060505"), Color("1e1b17"), Color("3a352e"), Color("efe4c4")]   ## ...e as plaquetas: a divisa, a plaqueta, a beira e os algarismos
const COFFEE: Array[Color] = [Color("2e1c10"), Color("3a2618"), Color("4a301c")]   ## o café da caneca: o fundo, a superfície e a luz da luminária refletida
const COFFEE_GLINT := Color("c8a47a")   ## a luz da luminária tremendo no café (`Background._draw_glint`)
const LAMP_BEAM := Color(1.0, 0.86, 0.62)   ## o feixe da luminária no ar (`Background._draw_beam`), somado à sala
const LAMP_POOL := Color(1.0, 0.78, 0.5)   ## a luz da luminária somada à sala no shader do `SceneView` (`Background.light`)
const MUG_CHIP: Array[Color] = [Color("2a2620"), Color("4a443c")]   ## as lascas no esmalte da caneca: o ferro e a beira

## O carimbo do calculógrafo: o reflexo quente da luminária no cromado e na baquelite, do lado da luz, e a borracha
## sem tinta; e o fundo da caixinha dos bilhetes.
const GLINT := Color("d9a35f")
const RUBBER_DRY := Color("3a302a")
const TOLL_BOX_MOUTH := Color("140e09")

## Rampas de material: do mais escuro ao mais claro, a sombra puxando para o frio (o azul da noite na sala) e a luz para
## o quente (a da luminária), não só mais escuro e mais claro. O desenho escolhe o tom pelo nível de luz (`ramp`).
const MUG_ENAMEL: Array[Color] = [Color("34363f"), Color("47494f"), Color("5e5e60"), Color("787670"), Color("938f84"),
	Color("aea797"), Color("c7bea9"), Color("ddd2b8")]   ## o esmalte branco-gelo da caneca (o mais claro, um tom abaixo do branco)
const MUG_RIM: Array[Color] = [Color("141626"), Color("1d2640"), Color("293858"), Color("3b4d72"), Color("56678a")]   ## a borda azul-marinho dela
## A madeira escura do tampo, no cenário e no calculógrafo aberto (`desk`): o tom de cada lugar, e os veios e a beira
## de cada tábua um acima dele, as emendas dois abaixo...
const DESK_WOOD: Array[Color] = [Color("100e11"), Color("161216"), Color("1d1715"), Color("221915"), Color("2b1f15"),
	Color("332417"), Color("3c2a19"), Color("47311c")]
const DESK_LIT := 0.86   ## onde a luz toda cai na rampa da madeira: um tom abaixo do último, para os veios clarearem nela
const DESK := Color("3c2a19")   ## o tampo embaixo da luminária (`desk(1.0)`): o papel do calculógrafo aberto
## ...e a borda da frente (`desk_edge`), com as faixas dela de cima para baixo, [de, altura, tons acima do da luz dela]:
## a quina arredondada pegando a luz (três), a espessura, o friso nela e a sombra embaixo.
const DESK_EDGE: Array[Color] = [Color("1d1614"), Color("2b1f18"), Color("3a2616"), Color("442c1a"), Color("5a4030"),
	Color("6b4529"), Color("7a5434"), Color("8d6239")]
const DESK_EDGE_ROWS := [[0, 1, 2], [1, 1, 4], [2, 2, 3], [4, 8, 0], [6, 1, 1], [12, 2, -2]]
## A madeira do móvel da mesa comutadora, a moldura em volta do painel (`cabinet`); no meio, os tons de sempre dela
## (a sombra, o meio e a luz, que a sala e o console repetem no `WOOD` deles).
const CABINET_WOOD: Array[Color] = [Color("151215"), Color("201813"), Color("2a1a0f"), Color("3a2516"), Color("4a2f1c"),
	Color("5b3a22"), Color("6b4529"), Color("845733")]
## O metal escuro do painel da mesa comutadora, para o relevo dele (`panel_metal`: os filetes gravados, a beira
## rebaixada, as faixas das linhas); o campo liso fica em `PANEL`, o tom do meio, com a luz da sala por cima.
const PANEL_METAL: Array[Color] = [Color("101013"), Color("18150f"), Color("221f1b"), Color("2f2a21"), Color("3c3529"),
	Color("4b4332"), Color("5e533c"), Color("756646")]


## As rampas dos papéis da mesa (`lit`): três degraus de sombra, cada vez mais escuros e frios, o tom de sempre do
## papel (o 4º) e um degrau de luz, mais quente (embaixo da luminária). O papel aberto das ferramentas fica no tom de
## sempre.
const NEWSPRINT_TONES: Array[Color] = [Color("959489"), Color("aaa490"), Color("beb598"), NEWSPRINT, Color("deca99")]
const NOTE_PAGE_TONES: Array[Color] = [Color("94938a"), Color("a9a491"), Color("bdb499"), NOTE_PAGE, Color("dcc99a")]
const SHEET_TONES: Array[Color] = [Color("918f86"), Color("a59f8d"), Color("b9b095"), SHEET, Color("d7c496")]
const SHEET_NEW_TONES: Array[Color] = [Color("9e9f9b"), Color("b4b1a3"), Color("cac3ac"), SHEET_NEW, Color("ebd9ad")]
const BOOK_LEAVES_TONES: Array[Color] = [Color("8c8a7f"), Color("9f9a86"), Color("b3a98d"), BOOK_LEAVES, Color("d0bd8e")]
const TICKET_TONES: Array[Color] = [Color("a1a4a5"), Color("b7b7ae"), Color("cec9b7"), TICKET, Color("efe0b8")]
const CARD_TONES: Array[Color] = [Color("a4a49b"), Color("bbb7a3"), Color("d2c8ab"), CARD, Color("f5e0ad")]
const PAPER_RAMPS := [NEWSPRINT_TONES, NOTE_PAGE_TONES, SHEET_TONES, SHEET_NEW_TONES, BOOK_LEAVES_TONES, TICKET_TONES, CARD_TONES]
static var _lit_of := {}   ## cada tom das rampas que `lit` percorre (rgba32) -> [a rampa, o lugar dele nela]


## O tom `c` `step` degraus acima (na luz da luminária) ou abaixo (na sombra): na rampa dele, se for um tom de uma
## (`PAPER_RAMPS`; `PANEL_METAL`, o metal das máquinas e do painel); senão (as tintas, as capas, o lápis), mais escuro e
## frio na sombra (o vermelho caindo mais que o azul) e mais claro e quente na luz, na medida dos degraus das rampas.
static func lit(c: Color, step: int) -> Color:
	if step == 0:
		return c
	if _lit_of.is_empty():
		for r: Array in PAPER_RAMPS + [PANEL_METAL]:
			for i in r.size():
				_lit_of[(r[i] as Color).to_rgba32()] = [r, i]
	var at: Array = _lit_of.get(c.to_rgba32(), [])
	if not at.is_empty():
		return at[0][clampi(at[1] + step, 0, at[0].size() - 1)]
	if step > 0:
		return Color(minf(c.r * 1.05, 1.0), minf(c.g * 1.02, 1.0), c.b * 0.96, c.a)
	var k := 0.085 * mini(-step, 3)
	return Color(c.r * (1.0 - 1.15 * k), c.g * (1.0 - k), c.b * (1.0 - 0.55 * k), c.a)


## O tom da rampa `tones` (de `Pal`, do escuro ao claro) para o nível de luz `lit` (0 a 1), em degraus, sem pontilhado;
## `step` tons acima (ou abaixo) dele.
static func ramp(tones: Array[Color], lit: float, step := 0) -> Color:
	return tones[clampi(int(lit * tones.size()) + step, 0, tones.size() - 1)]


## A madeira do tampo na luz `lit` (0 a 1: 1 embaixo da luminária acesa), `step` tons acima ou abaixo.
static func desk(lit: float, step := 0) -> Color:
	return ramp(DESK_WOOD, lit * DESK_LIT, step)


## A borda da frente do tampo na luz `lit`: longe da luminária, os tons de antes da rampa; embaixo dela, um acima.
static func desk_edge(lit: float, step := 0) -> Color:
	return ramp(DESK_EDGE, 0.25 + (lit - 0.5) * 0.45, step)


## A madeira do móvel da mesa comutadora na luz da sala `lit` (`Switchboard._room_lit`: de 0 longe da luminária a ~0,6
## perto dela), `step` tons acima ou abaixo: no meio do painel, o tom de sempre (`CABINET_WOOD[4]`).
static func cabinet(lit: float, step := 0) -> Color:
	return ramp(CABINET_WOOD, 0.33 + lit * 0.84, step)


## O metal do painel da mesa comutadora na luz da sala `lit` (como em `cabinet`): no meio do painel, `PANEL`.
static func panel_metal(lit: float, step := 0) -> Color:
	return PANEL_METAL[clampi(3 + panel_step(lit) + step, 0, PANEL_METAL.size() - 1)]


## O degrau da luz da sala `lit` no painel da mesa comutadora (`Switchboard._room_lit`): -1 longe da luminária, 0 no
## meio do painel e +1 perto dela. O relevo do painel (`panel_metal`) e as peças de metal paradas nele (pelo `lit`)
## escolhem o tom por ele.
static func panel_step(lit: float) -> int:
	return int((0.25 + lit * 0.6) * PANEL_METAL.size()) - 3

## Uma fonte só, de pixel: Departure Mono (SIL OFL). Fica nítida só em múltiplos de 11 (11, 22, 33, 44); fora deles os
## pixels saem desiguais. Importada com suavização (para a janela menor que 1280×720 não apagar os traços), sem
## hinting e sem sub-pixel (para os pixels caírem inteiros na tela). `ui` e `mono` continuam separadas pelo papel.
static var ui: Font = preload("res://fonts/DepartureMono-Regular.otf")
static var mono: Font = ui
