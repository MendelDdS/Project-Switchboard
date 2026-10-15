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
const NICKEL: Array[Color] = [Color("f4f0e6"), Color("d6d1c3"), Color("8e897c"), Color("45413a")]   ## o níquel (brilho, luz, meio, sombra): o prendedor da prancheta, o aro das lâmpadas

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
## papel e um degrau de luz, mais quente (embaixo da luminária). O papel aberto das ferramentas fica no tom de sempre.
const NEWSPRINT_TONES: Array[Color] = [Color("959489"), Color("aaa490"), Color("beb598"), NEWSPRINT, Color("deca99")]
const NOTE_PAGE_TONES: Array[Color] = [Color("94938a"), Color("a9a491"), Color("bdb499"), NOTE_PAGE, Color("dcc99a")]
const SHEET_TONES: Array[Color] = [Color("918f86"), Color("a59f8d"), Color("b9b095"), SHEET, Color("d7c496")]
const SHEET_NEW_TONES: Array[Color] = [Color("9e9f9b"), Color("b4b1a3"), Color("cac3ac"), SHEET_NEW, Color("ebd9ad")]
const BOOK_LEAVES_TONES: Array[Color] = [Color("8c8a7f"), Color("9f9a86"), Color("b3a98d"), BOOK_LEAVES, Color("d0bd8e")]
const TICKET_TONES: Array[Color] = [Color("a1a4a5"), Color("b7b7ae"), Color("cec9b7"), TICKET, Color("efe0b8")]
const PAPER_RAMPS := [NEWSPRINT_TONES, NOTE_PAGE_TONES, SHEET_TONES, SHEET_NEW_TONES, BOOK_LEAVES_TONES, TICKET_TONES]
const LIT_BASE := 3   ## onde fica o tom de sempre nas rampas dos papéis
static var _lit_of := {}   ## o tom de sempre de cada rampa dos papéis (rgba32) -> a rampa (`lit`)


## O tom `c` `step` degraus acima (na luz da luminária) ou abaixo (na sombra): na rampa do papel, se ele for o tom de
## sempre de uma (`PAPER_RAMPS`); senão (as tintas, as capas, o lápis), mais escuro e frio na sombra (o vermelho caindo
## mais que o azul) e mais claro e quente na luz, na medida dos degraus das rampas.
static func lit(c: Color, step: int) -> Color:
	if step == 0:
		return c
	if _lit_of.is_empty():
		for r: Array in PAPER_RAMPS:
			_lit_of[(r[LIT_BASE] as Color).to_rgba32()] = r
	var r: Array = _lit_of.get(c.to_rgba32(), [])
	if not r.is_empty():
		return r[clampi(LIT_BASE + step, 0, r.size() - 1)]
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
	return ramp(PANEL_METAL, 0.25 + lit * 0.6, step)

## Uma fonte só, de pixel: Departure Mono (SIL OFL). Fica nítida só em múltiplos de 11 (11, 22, 33, 44); fora deles os
## pixels saem desiguais. Importada com suavização (para a janela menor que 1280×720 não apagar os traços), sem
## hinting e sem sub-pixel (para os pixels caírem inteiros na tela). `ui` e `mono` continuam separadas pelo papel.
static var ui: Font = preload("res://fonts/DepartureMono-Regular.otf")
static var mono: Font = ui
