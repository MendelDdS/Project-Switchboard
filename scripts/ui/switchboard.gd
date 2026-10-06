class_name Switchboard
extends Control
## Mesa comutadora.
## - ENTRADAS 01–10: onde as chamadas chegam. O FONE (cabo verde, que sai do telefone) entra aqui para atender.
## - SAÍDAS: uma tomada logo abaixo de cada entrada. Uma ponta do cabo de conexão entra aqui...
## - DESTINOS: ...e a outra ponta no número pedido.
## Os cabos de conexão são poucos (PATCHES): desmontar as conexões encerradas libera cabos.
## Cada ponta tem o próprio fio, que sai de um buraco (dois por cabo de conexão na bandeja, na mesa à frente do painel;
## o do FONE no encaixe).
## Arraste o plug até a tomada (clicar e segurar). Clicar num plug encaixado (sem arrastar),
## ou soltá-lo fora de uma tomada, solta o plug: ele cai e o fio o recolhe para o buraco.
## A mesa não conhece ligações: lê as lâmpadas de `exchange` e avisa por `end_changed` quando um plug muda.
## Desenha por cima dos vizinhos (z_index na cena), porque o encaixe do FONE e a bandeja dos cabos ficam na mesa, fora
## do retângulo do painel (lugares reservados na cena, `setup`).

signal end_changed(end: int, jack: int, prev: int)
signal info_requested(jack: int)
signal warned(text: String)

const PATCHES := 3
## [cor, brilho] de cada cabo: 0 = FONE (verde), 1..PATCHES = cabos de conexão (vermelho, azul, amarelo).
## Mais cabos de conexão pedem mais cores aqui.
const CORD_COLORS := [
	[Color("3d6e34"), Color("6c9e58")],
	[Color("8e2a22"), Color("c4493b")],
	[Color("2a4a7c"), Color("4f7bb6")],
	[Color("b48c1c"), Color("e6c24c")],
]
## Destinos em três bancos de tomadas, A, B e C, cada um com uma faixa de numeração (100–199, 200–299, 300–399), em
## duas fileiras. A mesa saiu de fábrica assim; a faixa coincide com o setor da cidade (o primeiro dígito), e o banco
## de um setor que ainda não é do operador fica tampado por uma chapa com a letra dele (`GameData.sectors`).
const SECTOR_ORDER := [1, 2, 3]
const DEST_PITCH := 29.0     # px entre duas tomadas de destino vizinhas
const BLOCK_GAP := 12.0      # px entre dois blocos
const DEST_TOP := 211.0      # topo das tomadas da primeira fileira (a segunda fica DEST_ROW px abaixo)
const DEST_ROW := 46.0
const SIZE := Vector2(588, 362)
const FRAME := 7.0           # a moldura de madeira do móvel, em volta do painel
## Faixas gravadas no painel que separam as seções (altura da linha; o nome fica sobre ela, à esquerda).
const RULES := {"in": 22.0, "out": 131.0, "dest": 181.0}
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]   # madeira do móvel e da bandeja: luz, meio, sombra
const FONE_HOLE_X := 50.0   # o buraco do FONE, a partir da esquerda do encaixe (no meio dele)
const SHELF_HOLE_Y := 3.0   # os buracos da prateleira, no alto da faixa dela (o nome fica gravado embaixo)
## O buraco da prateleira (28×14, achatado pela perspectiva; o vão, 22 de largura, mais largo que o plug, que entra
## nele): b, a beira de trás do aro (na sombra); f e F, a da frente (na luz, com o brilho); w, a parede de dentro do lado
## de trás; h, o vão. As linhas são de elipses de pixel art (`draw_grommet`).
const HOLE_ART := [
	".........bbbbbbbbbb.........",
	"......bbbbbbbbbbbbbbbb......",
	"...bbbbbwwwwwwwwwwwwbbbbb...",
	"..bbbbwwwwwwhhhhwwwwwwbbbb..",
	".bbbwwwhhhhhhhhhhhhhhwwwbbb.",
	"bbbwwhhhhhhhhhhhhhhhhhhwwbbb",
	"bbbwhhhhhhhhhhhhhhhhhhhhwbbb",
	"fffhhhhhhhhhhhhhhhhhhhhhhfff",
	"fffhhhhhhhhhhhhhhhhhhhhhhfff",
	".fffhhhhhhhhhhhhhhhhhhhhfff.",
	"..ffffhhhhhhhhhhhhhhhhffff..",
	"...fffffhhhhhhhhhhhhfffff...",
	"......ffFffffffffffFff......",
	".........FFFFFFFFFF.........",
]
const HOLE_PAL := {"b": Color("7a6230"), "f": Color("c4a35a"), "F": Color("e6cf8e"), "w": Color("3a2a12"), "h": Color("140d06")}
const PLUG_SINK := 22.0  # guardado, o plug entra tanto no buraco (px abaixo dele: a capa de borracha some nele, o corpo fica à mostra)...
const HOLE_LIP := 3.0    # ...e some abaixo disto (px abaixo do buraco), atrás da beira da frente dele
const HOLE_SHADE := [[0.0, 5.0, 0.65], [5.0, 10.0, 0.4], [10.0, 16.0, 0.2]]   # o fio entrando no buraco escurece: [de, até (px a partir do buraco), escuro]

var _pushed := {}   ## ponta -> segundos desde que encaixou (a assentada, `PUSH_SEC`, e a passagem para de frente)
var _pulled := {}   ## ponta -> [segundos desde que saiu do encaixe, onde ele estava]: o plug de frente sumindo
var _silhouette := {}   ## inclinação do plug encaixado (em pé: false) -> polígono do contorno (destaque e sombra)
var _lit := {}   ## lâmpada ("l3" linha, "d312" destino) -> [cor, quanto está acesa 0..1]; a cor fica enquanto apaga
var exchange: Exchange
var fone_socket: Control       # encaixe do FONE, na prateleira à frente do painel
var tray: Control              # os buracos dos cabos de conexão, na prateleira à frente do painel
var dest_nums: Array = []      # destinos em serviço (dos setores atendidos)
var _slots := {}               # número -> centro da tomada (de todos os setores, atendidos ou não)
var _blocks := {}              # setor -> retângulo do bloco
var ends: Array = []           # tomada de cada ponta (-1 = na base). 0 = FONE; 1..2*PATCHES = pontas dos cabos de conexão
var held := -1
var cursor := Vector2.ZERO
var _hover := -1               # ponta cujo plug está sob o mouse (pode ser pega); desenhada com destaque
var _cut := INF   # desenhando o plug em pé: abaixo disto (y dele) está dentro do buraco da prateleira
var _order: Array = []         # ordem de desenho das pontas: a mexida por último fica por cima
var info_lines: PackedStringArray = []
var info_ghost := false
var info_line := -1
var info_until := 0
var _press_pos := Vector2.ZERO
var _loose := {}               # ponta solta voltando para o buraco -> {"t": s caindo/recolhendo, "seat": -1 ou 0..1 assentando, "direct", "from", "ang"}
const FALL_SEC := 0.35         # o plug solto cai livre antes de o fio começar a recolher
const NEAR_HOLE := 45.0        # solto acima do buraco (a qualquer altura) e com essa distância na horizontal, o fio puxa o plug direto (sem cair)
const PULL_SPEED := 480.0      # px/s de fio que entra no buraco
const SEAT_LEN := 12.0         # com o fio curto assim, o plug assenta no lugar
const SEAT_SEC := 0.1
const MAX_FLING := 1800.0      # px/s: o plug solto em movimento sai com o embalo da mão, até esse limite
const DROP_SPEED := 120.0      # px/s: batendo na mesa mais rápido que isso, faz barulho
const TAP_SPEED := Vector2(150.0, 600.0)   # px/s: o fio batendo na mesa faz "tap" a partir de x; em y, no volume máximo
const TAP_GAP := 0.12          # s: intervalo mínimo entre dois "taps" do mesmo fio
const PLUG_BASE := Vector2(0, 36)   # do ponto de referência do plug (topo do corpo) até onde o fio entra nele
const PLUG_LEN := 59.0   # em pé: do fio até o alto da aba (a ponta de metal passa disso)
## Encaixado, de onde fica a tomada até onde o fio entra: a ponta de metal some dentro dela e o anel assenta no buraco.
const PLUG_FACE_R := 8.0   # encaixado: o raio do corpo (18 px com a beira, como o em pé; ele cobre a tomada, e a aba aparece de lado)
const EDGE := 0.65          # a beira do plug e do fio: a cor da peça escurecida assim (contorno preto destoava do cenário)
## Encaixado, o plug sai do painel na direção da câmera: visto de cima e da direita, a ponta dele fica deslocada do
## encaixe para baixo e para a esquerda, e mais quanto mais longe do ponto que a câmera olha reto (paralaxe, `_tilt`).
const PLUG_EYE := Vector2(SIZE.x + 300, -600)   # o ponto da mesa que a câmera olha reto (fora dela, no alto à direita)
const PLUG_DEPTH := 0.012   # px de deslocamento da ponta por px de distância do encaixe até PLUG_EYE
const PLUG_SHADE := Vector2(7, 9)   # encaixado, a sombra vai do encaixe até aqui (luz no alto à esquerda)
const CORD_STUB := 6.0   # encaixado, o fio sai da ponteira no eixo do plug por esses px antes de cair...
const CORD_BEND := [0.15, 0.06]   # ...e os pontos seguintes tendem a continuar a direção dos anteriores (curva suave)
## O encaixe, pixel a pixel (16×16, menor que o `JACK`; par, para o meio dele cair entre dois pixels, como o das
## plaquinhas e das lâmpadas), na medida da ponta do plug: o furo preto tem 8 px, a largura da luva (com 20, a tomada
## ficava grande demais para ela). Um aro niquelado fino (2 a 3 pixels) com a beira escura por fora, em volta do furo.
## A luz (alto à esquerda) bate na face do aro desse lado, com um fio de brilho no meio dele, e, por dentro, na parede
## do furo do lado oposto (embaixo à direita). Os dois círculos (16 e 10 pixels) têm as larguras de linha das
## circunferências de pixel art (6, 10, 12, 14...): com outros raios saíam com lados retos, como um octógono; a beira e
## o chanfro têm sempre 1 pixel. As cores vêm de `_jack_pal`.
const JACK_ART := [
	".....eeeeee.....",
	"...eeLLLMMMee...",
	"..eLlllLLMMDDe..",
	".eLllLddddMMDDe.",
	".eLlldhhhhkMDDe.",
	"eLlldhhhhhhkMDDe",
	"eLldhhhhhhhhkMDe",
	"eLldhhhhhhhhWMDe",
	"eMLdhhhhhhhhWDDe",
	"eMLkhhhhhhhkWDDe",
	"eMMDkhhhhhkWDDde",
	".eDMDkkkkWWdDde.",
	".eDMMDdkWWdddde.",
	"..eDDDDDDdddde..",
	"...eeDDDDddee...",
	".....eeeeee.....",
]
const JACK_PX := 16   # o lado do `JACK_ART`, em pixels
const LIGHT := Vector2(-0.7071, -0.7071)   # de onde vem a luz das peças redondas (alto à esquerda)
const EDGE_DARK := Color("1c130b")   # a beira das peças: marrom quase preto, não preto puro
const PLUG_ART := [   ## o plug em pé, de 20 × 93 px (y de -93 a -1; o fio sai de y = 0): `_plug_pal` dá as cores
	".........bE.........",
	"........yYbE........",
	".......yYbbBE.......",
	".......yYbbBE.......",
	".......byBBCE.......",
	"........BbCE........",
	"........BbCE........",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"....YYYYYyyybbBE....",
	"....bybbbBBBCCCE....",
	"....bybbbBBBCCCE....",
	"..3233334444555556..",
	".212222233333444556.",
	".434444455555555556.",
	".212222233333444556.",
	".212222233333444556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".212222233333444556.",
	".212222233333444556.",
	".434444455555555556.",
	".434444455555555556.",
	".111111122222333446.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	"..3233334444555556..",
	"...32333344455556...",
	"...32333344455556...",
	"...32333344455556...",
	"....545555555556....",
	"....323334445556....",
	"....323334445556....",
	".....5455555556.....",
	"....323334445556....",
	"....323334445556....",
	"......54555556......",
	".....3233445556.....",
	".....3233445556.....",
	"......54555556......",
	"......32344556......",
	"......32344556......",
	".......545556.......",
	"......32344556......",
	"......32344556......",
	"........5456........",
	".......324456.......",
	".......324456.......",
]
const PLUG_H := 93.0   # a altura do `PLUG_ART`: do bico até onde sai o fio
## Onde o corpo do plug encaixado termina e a capa começa, como fração do comprimento a partir do painel (das
## `PLUG_LEN` linhas do `PLUG_ART` da aba até o fio, 3 de aba e 37 de corpo): a luz da lâmpada bate ali.
const PLUG_BODY_END := 40.0 / 59.0
const PLUG_ABA_D := 12   # a aba dourada, com a beira (a largura dela no `PLUG_ART`): a luz e a sombra de contato do encaixado
const MORPH_SEC := 0.08   # encaixando ou saindo, o plug passa de em pé para de frente (e volta) nesse tempo
const PUSH_PX := 1.5     # ao encaixar, o plug afunda (o tampo encolhe tanto, px) e volta...
const ROT_STEP := deg_to_rad(15.0)   # solto ou na mão, o plug gira em passos assim (pixel art girado torto serrilha)
const PUSH_SEC := 0.14   # ...nesse tempo, como se fosse empurrado para dentro
const SHADOW := Color(0, 0, 0, 0.35)
const PLATE := Color("4d483d")   # chapa sobre o banco que ainda não está em uso
const LAMP_R := 4.5         # raio do vidro da lâmpada de cada linha (o aro de metal fica em volta)
const JACK := 22.0          # diâmetro de todos os encaixes (entradas, saídas e destinos)
## A coluna de cada linha, de cima para baixo: plaquinha com o número (topo e altura), estado (linha de base do texto),
## lâmpada, entrada e saída (centros). O estado fica acima da lâmpada: embaixo da entrada, o plug encaixado o cobria.
const ROW_Y := {"plate": 32.0, "plate_h": 17.0, "state": 61.0, "lamp": 76.0, "in": 104.0, "out": 156.0}
## A fonte do estado de cada linha, como letras gravadas no painel: maiúsculas de 3 × 5 px, desenhadas pixel a pixel
## (`tiny`). Na fonte da tela, em 11, "conectada" não cabe na coluna; em 8, fora da grade dela, a letra borrava.
const TINY := {"A": "###/#.#/###/#.#/#.#", "B": "##./#.#/##./#.#/##.", "C": ".##/#../#../#../.##", "D": "##./#.#/#.#/#.#/##.",
	"E": "###/#../##./#../###", "F": "###/#../##./#../#..", "G": ".##/#../#.#/#.#/.##", "H": "#.#/#.#/###/#.#/#.#",
	"I": "###/.#./.#./.#./###", "J": "..#/..#/..#/#.#/.#.", "K": "#.#/#.#/##./#.#/#.#", "L": "#../#../#../#../###",
	"M": "#.#/###/###/#.#/#.#", "N": "##./#.#/#.#/#.#/#.#", "O": ".#./#.#/#.#/#.#/.#.", "P": "##./#.#/##./#../#..",
	"Q": ".#./#.#/#.#/##./.##", "R": "##./#.#/##./#.#/#.#", "S": ".##/#../.#./..#/##.", "T": "###/.#./.#./.#./.#.",
	"U": "#.#/#.#/#.#/#.#/###", "V": "#.#/#.#/#.#/#.#/.#.", "W": "#.#/#.#/###/###/#.#", "X": "#.#/#.#/.#./#.#/#.#",
	"Y": "#.#/#.#/.#./.#./.#.", "Z": "###/..#/.#./#../###", "0": "###/#.#/#.#/#.#/###", "1": ".#./##./.#./.#./###",
	"2": "##./..#/.#./#../###", "3": "##./..#/.#./..#/##.", "4": "#.#/#.#/###/..#/..#", "5": "###/#../##./..#/##.",
	"6": ".##/#../###/#.#/###", "7": "###/..#/.#./.#./.#.", "8": "###/#.#/###/#.#/###", "9": "###/#.#/###/..#/##.",
	".": ".../.../.../.../.#.", "-": ".../.../###/.../...", ":": ".../.#./.../.#./...", "/": "..#/..#/.#./#../#..",
	"(": ".#./#../#../#../.#.", ")": ".#./..#/..#/..#/.#."}
const TINY_MARKS := {"´": "..#/.#.", "`": "#../.#.", "^": ".#./#.#", "~": ".##/##.", "¨": "#.#/...", ",": ".#./##."}   ## acentos (2 linhas acima da letra; a cedilha, abaixo)
const TINY_ACCENTS := {"Á": "A´", "À": "A`", "Â": "A^", "Ã": "A~", "Ä": "A¨", "É": "E´", "È": "E`", "Ê": "E^", "Ë": "E¨",
	"Í": "I´", "Ì": "I`", "Î": "I^", "Ï": "I¨", "Ó": "O´", "Ò": "O`", "Ô": "O^", "Õ": "O~", "Ö": "O¨", "Ú": "U´", "Ù": "U`",
	"Û": "U^", "Ü": "U¨", "Ñ": "N~", "Ç": "C,"}
const BEZEL := [Color("d6d1c3"), Color("8e897c"), Color("45413a")]   # aro niquelado: luz, meio, sombra
const LAMP_OFF := Color("6b6556")   # o vidro leitoso da lâmpada apagada (escuro, parecia o furo de uma tomada)
const STRIP_W := 30.0   # a faixa rebaixada de cada linha, da plaquinha à saída
const WEAR := [0.5, 0.3, 0.15]   # o painel gasto em volta das tomadas: do perto ao longe (o quanto clareia)
const KINK := 1.5   # px: as dobras que o fio de pano guarda, no máximo
const BRAID := 6.0   # px: o trançado do fio (o brilho dele vem em pedaços desse comprimento)
const LAMP_ON_SEC := 0.06    # a lâmpada (de filamento) acende quase na hora...
const LAMP_OFF_SEC := 0.18   # ...e apaga mais devagar, o filamento esfriando: a linha tocando pulsa em vez de piscar seco
const ROPE_SHADOW := Vector2(3, 4)  # deslocamento da sombra dos fios junto ao buraco; até o plug, cresce como a dele (`_lift`)
var _jacks: Array = []

# ---- física dos cabos (corda de Verlet) ----
const ROPE_N := 22                 # pontos por cabo
const GRAVITY := Vector2(0, 1600)  # px/s²
const DAMPING := 0.985             # 1 = sem atrito com o ar
const STIFF_ITER := 14             # iterações de restrição (maior = cabo menos elástico)
const SLACK := 70.0                # folga extra além da distância reta (fio do FONE), no máximo...
const SLACK_PER_PX := 0.15         # ...e esta por px de distância na horizontal (logo acima do buraco, sobrava fio deitado na prateleira)
const CORD_SLACK := 14.0           # idem, fios dos cabos de conexão
const STEP := 1.0 / 90.0
var ropes := {}                    # ponta -> corda (só enquanto o fio está para fora do buraco)
const SLEEP_STEPS := 30            # passos quase parado até o fio "dormir" (deixa de ser simulado até algo mexer nele)
const SLEEP_MOVE := 0.05           # px por passo: menos que isso conta como parado
var _acc := 0.0
var _last_mouse := Vector2.ZERO   # mouse no último passo da física
var _mouse_vel := Vector2.ZERO    # px/s, para o embalo do plug solto
# fio que passou pelos buracos neste quadro, para o som de atrito (px): saindo, entrando, e somas pesadas por px
# do lugar do buraco na tela (0..1) e do que era o fio do FONE
var _rub_out := 0.0
var _rub_in := 0.0
var _rub_x := 0.0
var _rub_fone := 0.0


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 1 + PATCHES * 2:
		ends.append(-1)
		_order.append(i)


func setup(ex: Exchange, socket: Control, cord_tray: Control) -> void:
	exchange = ex
	fone_socket = socket
	tray = cord_tray
	dest_nums = ex.dest_numbers()
	_jacks = range(1, 21) + dest_nums
	_layout_dests()


## Posição de cada tomada de destino: blocos lado a lado, centralizados na mesa.
func _layout_dests() -> void:
	var by_sector := {}
	for e in GameData.CONTENT.directory:
		if not e.dispatch_only:
			var s := int(e.number.left(1))
			if not by_sector.has(s):
				by_sector[s] = []
			by_sector[s].append(int(e.number))
	var cols := SECTOR_ORDER.map(func(s): return ceili(by_sector.get(s, []).size() / 2.0))
	var total: float = cols.reduce(func(a, c): return a + c, 0) * DEST_PITCH + BLOCK_GAP * (SECTOR_ORDER.size() - 1)
	var x := (SIZE.x - total) / 2.0
	for k in SECTOR_ORDER.size():
		var s: int = SECTOR_ORDER[k]
		var nums: Array = by_sector.get(s, [])
		nums.sort()
		for i in nums.size():
			_slots[nums[i]] = Vector2(x + (i % cols[k]) * DEST_PITCH + DEST_PITCH / 2.0, DEST_TOP + 11.0 + int(i / cols[k]) * DEST_ROW)
		# o mesmo vão (8 px) entre a moldura e os números, em cima, e entre a moldura e as tomadas de baixo
		_blocks[s] = Rect2(x - 3, DEST_TOP - 21, cols[k] * DEST_PITCH + 6, DEST_ROW + 50)
		x += cols[k] * DEST_PITCH + BLOCK_GAP


## Encaixe do FONE em coordenadas da mesa (na prateleira à frente do painel, fora do retângulo dela).
func socket_rect() -> Rect2:
	if fone_socket == null:
		return Rect2(0, 370, 100, 16)
	return Rect2(fone_socket.global_position - global_position, fone_socket.size)


## A faixa dos buracos dos cabos na prateleira, em coordenadas da mesa (também fora do retângulo dela).
func tray_rect() -> Rect2:
	if tray == null:
		return Rect2(112, 370, 476, 16)
	return Rect2(tray.global_position - global_position, tray.size)


## Os fios repousam na prateleira, na linha dos buracos (os nomes gravados ficam na frente, livres).
func _floor() -> float:
	return tray_rect().position.y + SHELF_HOLE_Y


func _has_point(p: Vector2) -> bool:   # o painel até a prateleira, com o vão entre eles (os plugs guardados passam por ele)
	return Rect2(Vector2.ZERO, size).merge(socket_rect()).merge(tray_rect()).has_point(p)


# ------------------------------------------------------------------ geometria
# Tomadas: 1–10 entradas, 11–20 saídas (linha + 10), destinos pelo próprio número (101–399).

func col_x(i: int) -> float:
	return 42.0 + i * 56.0


func jack_rect(j: int) -> Rect2:
	var c: Vector2
	if j <= 10:
		c = Vector2(col_x(j - 1), ROW_Y["in"])
	elif j <= 20:
		c = Vector2(col_x(j - 11), ROW_Y["out"])
	else:
		c = _slots.get(j, Vector2.ZERO).round()   # num pixel inteiro: o desenho do encaixe é pixel a pixel
	return Rect2(c - Vector2(JACK, JACK) / 2.0, Vector2(JACK, JACK))


func jack_at(pos: Vector2) -> int:
	for j in _jacks:
		if jack_rect(j).grow(4).has_point(pos):
			return j
	return -1


func top_rect(i: int) -> Rect2:
	return Rect2(col_x(i) - 20, ROW_Y["plate"] - 2, 40, ROW_Y["lamp"] - ROW_Y["plate"] + 8)


## Centro do lugar do cabo de conexão k na prateleira (as duas pontas ficam lado a lado).
func patch_x(k: int) -> float:
	var t := tray_rect()
	return t.position.x + t.size.x * (k + 0.5) / PATCHES


## Onde fica o plug guardado, de pé no buraco dele na prateleira, como nas mesas de verdade (o fio desce por ele).
func home_pos(e: int) -> Vector2:
	return hole(e) - PLUG_BASE + Vector2(0, PLUG_SINK)


## Buraco de onde sai o fio da ponta e, na prateleira (o do FONE no encaixe dele; os de conexão aos pares).
func hole(e: int) -> Vector2:
	if e == 0:
		return socket_rect().position + Vector2(FONE_HOLE_X, SHELF_HOLE_Y)
	return Vector2(patch_x((e - 1) / 2) + (-15.0 if e % 2 == 1 else 15.0), tray_rect().position.y + SHELF_HOLE_Y)


func home_rect(e: int) -> Rect2:
	var h := home_pos(e)
	return Rect2(h.x - 12, h.y + PLUG_BASE.y - PLUG_H, 24, PLUG_H - 2.0)   # do bico até a beira do buraco


## A outra ponta do mesmo cabo de conexão (-1 para o FONE).
func mate(e: int) -> int:
	if e == 0:
		return -1
	return e + 1 if e % 2 == 1 else e - 1


func cable_of(e: int) -> int:
	return 0 if e == 0 else (e + 1) / 2


func cord_at(j: int) -> int:
	return -1 if j == -1 else ends.find(j)


func end_jack(e: int) -> int:
	return ends[e] if e >= 0 else -1


## Destino ligado à SAÍDA da linha n pelo cabo de conexão (-1 se não houver).
func dest_of_output(n: int) -> int:
	var e := cord_at(n + 10)
	if e == -1:
		return -1
	var j: int = ends[mate(e)]
	return j if j > 20 else -1


func fone_line() -> int:
	var j: int = ends[0]
	return j if j >= 1 and j <= 10 else -1


func free_patches() -> int:
	var n := 0
	for k in PATCHES:
		var a := 1 + k * 2
		if ends[a] == -1 and ends[a + 1] == -1 and held != a and held != a + 1:
			n += 1
	return n


## Por que a ponta e não entra na tomada j ("" = entra).
func refuse(e: int, j: int) -> String:
	if cord_at(j) != -1:
		return T.text(T.Key.WARN_JACK_TAKEN)
	if e == 0:
		return "" if j <= 10 else T.text(T.Key.WARN_FONE_INPUTS)
	if j <= 10:
		return T.text(T.Key.WARN_CORD_WHERE)
	var other: int = ends[mate(e)]
	if other != -1 and (other <= 20) == (j <= 20):
		return T.text(T.Key.WARN_CORD_ENDS)
	return ""


# ------------------------------------------------------------------ ações

func place(e: int, j: int) -> bool:
	var why := refuse(e, j)
	if why != "":
		warned.emit(why)
		_sfx("click", jack_rect(j).get_center())
		return false
	ends[e] = j
	held = -1
	_loose.erase(e)
	_raise(e)
	_pushed[e] = 0.0
	_sfx("plug_in", jack_rect(j).get_center())
	end_changed.emit(e, j, -1)
	return true


## A ponta e passa a ser desenhada por cima das outras.
func _raise(e: int) -> void:
	_order.erase(e)
	_order.append(e)


func pick_up(e: int) -> void:
	_sfx("plug_out", _plug_base(e))
	var prev: int = ends[e]
	_unseat(e)
	ends[e] = -1
	held = e
	_raise(e)
	if prev != -1:
		end_changed.emit(e, -1, prev)


## O plug encaixado vai sair: a vista de frente some aos poucos no encaixe (`_pulled`).
func _unseat(e: int) -> void:
	if ends[e] != -1:
		_pulled[e] = [0.0, jack_rect(int(ends[e])).get_center(), _tilt(int(ends[e]))]
	_pushed.erase(e)


## Solta o plug: ele cai e o fio o puxa de volta para o buraco (o FONE volta ao telefone).
func go_home(e: int) -> void:
	var from := _plug_base(e)
	var fling := _mouse_vel.limit_length(MAX_FLING) if held == e else Vector2.ZERO
	var prev: int = ends[e]
	_unseat(e)
	ends[e] = -1
	if held == e:
		held = -1
	if from.distance_to(_rest(e)) > 2.0:
		if not ropes.has(e):
			_new_rope(e, from)
		# acima do buraco o fio já puxa, esticado, e o plug vai direto para ele (sem cair no chão antes);
		# fora disso ele cai, com o embalo da mão, antes de o fio recolher
		var direct := from.y < hole(e).y and absf(from.x - hole(e).x) < NEAR_HOLE
		_loose[e] = {"t": FALL_SEC if direct else 0.0, "seat": -1.0, "direct": direct}
		var r: Dictionary = ropes[e]
		if direct:
			r["len"] = minf(r["len"], from.distance_to(hole(e)))
		else:
			r["old"][ROPE_N - 1] = from - fling * STEP
	else:
		_sfx("thump", from, -14.0)
	if prev != -1:
		end_changed.emit(e, -1, prev)


func show_info(text_lines: PackedStringArray, ghost: bool, line: int) -> void:
	info_lines = text_lines
	info_ghost = ghost
	info_line = line
	info_until = Time.get_ticks_msec() + (7000 if ghost else 2600)


# ------------------------------------------------------------------ entrada

func _gui_input(e: InputEvent) -> void:
	if e.is_action_pressed("cancel_plug") and held != -1:
		go_home(held)
		accept_event()
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press(e.position)
		else:
			_release(e.position)
		accept_event()


func _press(pos: Vector2) -> void:
	cursor = pos
	_press_pos = pos
	var e := _plug_under(pos)
	if e != -1:
		_loose.erase(e)
		pick_up(e)
		return
	var j := jack_at(pos)
	if j == -1:
		j = _top_at(pos)
	if j != -1:
		info_requested.emit(j)   # tomada vazia ou plaqueta da linha: mostra o que é


## A ponta cujo plug está em p (-1 = nenhuma), o de cima primeiro: guardado, solto voltando ou encaixado.
func _plug_under(p: Vector2) -> int:
	for i in range(_order.size() - 1, -1, -1):
		var e: int = _order[i]
		if e != held and _plug_hit(e, p):
			return e
	return cord_at(jack_at(p))


## A linha (1–10) cuja plaqueta está em p, ou -1.
func _top_at(p: Vector2) -> int:
	for i in 10:
		if top_rect(i).has_point(p):
			return i + 1
	return -1


## Cursor conforme o que está sob o mouse: mão aberta num plug que pode ser pego, fechada segurando
## (proibido sobre uma tomada que não o aceita), dedo no que mostra informação ao clicar.
func _cursor_shape(p: Vector2) -> CursorShape:
	if held != -1:
		var j := jack_at(p)
		return CURSOR_FORBIDDEN if j != -1 and refuse(held, j) != "" else CURSOR_DRAG
	if _hover != -1:
		return CURSOR_MOVE
	if jack_at(p) != -1 or _top_at(p) != -1:
		return CURSOR_POINTING_HAND
	return CURSOR_ARROW


## Arrastar e soltar encaixa na tomada; soltar fora dela, ou clicar sem arrastar (desplugar), solta o plug.
## Mexer uns pixels (mouse tremendo, toque no trackpad) ainda conta como clique.
func _release(pos: Vector2) -> void:
	if held == -1:
		return
	var j := jack_at(pos)
	if pos.distance_to(_press_pos) < 6.0 or j == -1 or not place(held, j):
		go_home(held)


func _process(delta: float) -> void:
	for e in _pushed.keys():   # a assentada anda antes dos fios: a ponta deles acompanha o plug no mesmo quadro
		_pushed[e] += delta
		if _pushed[e] >= maxf(PUSH_SEC, MORPH_SEC):
			_pushed.erase(e)
	for e in _pulled.keys():
		_pulled[e][0] += delta
		if _pulled[e][0] >= MORPH_SEC:
			_pulled.erase(e)
	var mouse := get_local_mouse_position()
	if held != -1:
		cursor = mouse
	if delta > 0.0:
		_mouse_vel = _mouse_vel.lerp((mouse - _last_mouse) / delta, 0.5)
	_hover = -1 if held != -1 else _plug_under(mouse)
	mouse_default_cursor_shape = _cursor_shape(mouse)
	_acc = minf(_acc + delta, STEP * 6)
	while _acc >= STEP:
		_acc -= STEP
		for e in ends.size():
			_step_rope(e, STEP)
		_last_mouse = get_local_mouse_position()
	var moved := _rub_out + _rub_in
	if delta > 0.0 and moved > 0.0:
		Sfx.cord_rub(moved / delta, _rub_x / moved, _rub_out / moved, _rub_fone / moved)
	else:
		Sfx.cord_rub(0.0)
	_rub_out = 0.0
	_rub_in = 0.0
	_rub_x = 0.0
	_rub_fone = 0.0
	if exchange != null:
		var ms := Time.get_ticks_msec()
		for n in range(1, 11):
			_fade("l%d" % n, _lamp(exchange.line(n), ms, fone_line() == n), delta)
		for d in dest_nums:
			_fade("d%d" % d, _dest_lamp(exchange.dest(d), ms), delta)
	queue_redraw()


## Onde o fio entra no plug.
func _plug_base(e: int) -> Vector2:
	if held == e:
		return cursor + PLUG_BASE
	if ends[e] != -1:
		return jack_rect(int(ends[e])).get_center() + _tilt(int(ends[e]))   # encaixado: o fio sai da ponteira
	if _loose.has(e):
		var an: Dictionary = _loose[e]
		if an["seat"] >= 0.0:
			return (an["from"] as Vector2).lerp(_rest(e), an["seat"])
		return ropes[e]["pts"][ROPE_N - 1]
	return _rest(e)


## O plug da ponta e está no ponto p (guardado, vale a base inteira; fora dela, o desenho do plug).
func _plug_hit(e: int, p: Vector2) -> bool:
	if ends[e] == -1 and not _loose.has(e):
		return home_rect(e).has_point(p)
	var q := (p - _plug_base(e)).rotated(-_plug_angle(e))
	return _plug_rect(e).grow(2.0).has_point(q)


## Contorno do plug a partir de onde o fio entra nele: em pé (solto, na mão, na base) ou, encaixado, visto de frente.
func _plug_rect(e: int) -> Rect2:
	if ends[e] != -1:   # do encaixe (atrás) até a ponteira (aqui)
		var r := PLUG_FACE_R + 1.0
		return Rect2(-_tilt(int(ends[e])) - Vector2(r, r), Vector2(r, r) * 2.0).merge(Rect2(-r, -r, r * 2.0, r * 2.0))
	return Rect2(-10, -PLUG_H, 20, PLUG_H)


## Quanto o plug recém-encaixado está afundado (px, a assentada).
func _push(e: int) -> float:
	return PUSH_PX * sin(PI * minf(float(_pushed[e]) / PUSH_SEC, 1.0)) if _pushed.has(e) else 0.0


## Onde o fio entra no plug guardado.
func _rest(e: int) -> Vector2:
	return home_pos(e) + PLUG_BASE


## Inclinação do plug: em pé, menos quando solto (segue o fio, que sai da traseira dele).
func _plug_angle(e: int) -> float:
	if not _loose.has(e):
		return 0.0
	var an: Dictionary = _loose[e]
	if an["seat"] >= 0.0:
		return snappedf(lerp_angle(an["ang"], 0.0, an["seat"]), ROT_STEP)
	return snappedf(_cord_angle(e), ROT_STEP)


func _cord_angle(e: int) -> float:
	var pts: PackedVector2Array = ropes[e]["pts"]
	var d := pts[ROPE_N - 1] - pts[ROPE_N - 4]
	return 0.0 if d.length_squared() < 1.0 else d.angle() + PI / 2


func _new_rope(e: int, to: Vector2) -> void:
	var a := hole(e)
	var init := PackedVector2Array()
	for i in ROPE_N:
		init.append(a.lerp(to, float(i) / (ROPE_N - 1)))
	ropes[e] = {"pts": init, "old": init.duplicate(), "len": a.distance_to(to)}


## Onde fica o ponto p da mesa na tela, de 0 (borda esquerda) a 1 (direita): os sons vêm daquele lado.
func screen_x(p: Vector2) -> float:
	return (get_global_transform_with_canvas() * p).x / get_viewport_rect().size.x


## Som da mesa vindo do ponto p.
func _sfx(id: String, p: Vector2, db: float = 0.0) -> void:
	Sfx.play_at(id, screen_x(p), db)


## `d` px do fio da ponta e passaram pelo buraco (positivo: saindo; negativo: entrando), para o som de atrito.
func _count_rub(e: int, d: float) -> void:
	if d > 0.0:
		_rub_out += d
	else:
		_rub_in -= d
	_rub_x += absf(d) * screen_x(hole(e))
	if e == 0:
		_rub_fone += absf(d)


## Simula o fio da ponta e como uma corda presa no buraco: os pontos têm inércia e gravidade e a distância
## entre eles é mantida. A outra ponta segue o plug; solto, o plug é a última conta da corda (cai) e o
## comprimento encolhe até ele assentar no buraco.
func _step_rope(e: int, dt: float) -> void:
	if held != e and ends[e] == -1 and not _loose.has(e):
		ropes.erase(e)   # o fio está todo dentro do buraco
		return
	var a := hole(e)
	if not ropes.has(e):
		_new_rope(e, _plug_base(e))
	var r: Dictionary = ropes[e]
	var pts: PackedVector2Array = r["pts"]
	var old: PackedVector2Array = r["old"]
	var last := ROPE_N - 1
	var length: float = r["len"]
	var an: Dictionary = _loose.get(e, {})
	var free: bool = not an.is_empty() and an["seat"] < 0.0
	if free:
		an["t"] += dt
		if an["t"] > FALL_SEC:
			length = maxf(length - PULL_SPEED * dt, 0.0)
	elif not an.is_empty():
		an["seat"] += dt / SEAT_SEC
		if an["seat"] >= 1.0:
			_loose.erase(e)
			ropes.erase(e)
			_sfx("thump", a, -14.0)
			return
		length = a.distance_to(_plug_base(e))
	else:
		var b := _plug_base(e)
		var slack := clampf(absf(b.x - a.x) * SLACK_PER_PX, CORD_SLACK, SLACK) if e == 0 else CORD_SLACK
		length = lerpf(length, a.distance_to(b) + slack, 0.08)
	var mouse := get_local_mouse_position()
	var mv := mouse - _last_mouse
	var settled := held != e and an.is_empty()
	if r.has("sleep"):
		# dormindo: só volta a simular se a ponta ou o buraco saírem do lugar, ou se o mouse passar mexendo no fio
		var poked: bool = mv.length_squared() > 0.5 and (r["sleep"] as Rect2).has_point(mouse)
		if settled and pts[0] == a and pts[last] == _plug_base(e) and not poked:
			return
		r.erase("sleep")
	var seg := length / last
	var floor_y := _floor()
	# inércia + gravidade
	var moving := last + 1 if free else last
	var tap := 0.0   # a batida mais forte de um ponto do fio na mesa, neste passo (px/passo), e onde
	var tap_at := Vector2.ZERO
	var direct: bool = free and an["direct"]
	for i in range(1, moving):
		var v := (pts[i] - old[i]) * DAMPING
		old[i] = pts[i]
		if direct:
			pts[i] += v * 0.5   # puxado direto: fio esticado, sem gravidade e quase sem embalo (o plug não pendula)
			continue
		pts[i] += v + GRAVITY * dt * dt
		if pts[i].y > floor_y:
			if i == last:
				if v.y > DROP_SPEED * dt:
					_sfx("drop", pts[i])   # o plug solto bate na mesa
			elif v.y > tap:
				tap = v.y
				tap_at = pts[i]
		# passar o mouse por cima do fio empurra o fio
		if held != e and mv.length_squared() > 0.5 and pts[i].distance_to(mouse) < 16.0:
			pts[i] += mv * 0.35
	pts[0] = a
	var pin := last   # daqui até o plug, o fio não se mexe
	if not free:
		pts[last] = _plug_base(e)
		old[last] = pts[last]
	if ends[e] != -1:   # encaixado, o fio sai da ponteira no eixo do plug antes de cair
		pin = last - 1
		pts[pin] = pts[last] + _tilt(int(ends[e])).normalized() * minf(seg, CORD_STUB)
		old[pin] = pts[pin]
	# restrições de comprimento
	if pin < last:   # encaixado: o fio sai da ponteira e faz a curva aos poucos, como um fio de verdade
		for b in CORD_BEND.size():
			var i := pin - 1 - b
			var want := pts[i + 1] + (pts[i + 1] - pts[i + 2]).normalized() * seg
			pts[i] = pts[i].lerp(want, CORD_BEND[b])
	for _it in STIFF_ITER:
		for i in pin:
			var d := pts[i + 1] - pts[i]
			var l := d.length()
			if l < 0.0001:
				continue
			var corr := d * ((l - seg) / l)
			if i == 0:
				pts[i + 1] -= corr
			elif i + 1 == pin and not free:
				pts[i] += corr
			else:
				pts[i] += corr * 0.5
				pts[i + 1] -= corr * 0.5
		for i in range(1, moving):
			if pts[i].y > floor_y:   # repousa na mesa, à frente do painel
				pts[i].y = floor_y
				old[i].x = lerpf(old[i].x, pts[i].x, 0.3)   # atrito com a mesa
	r["pts"] = pts
	r["old"] = old
	_count_rub(e, length - float(r["len"]))
	r["tap"] = maxf(float(r.get("tap", 0.0)) - dt, 0.0)
	if tap > TAP_SPEED.x * dt and r["tap"] == 0.0:   # o fio caiu ou chicoteou na mesa
		var k := clampf((tap / dt - TAP_SPEED.x) / (TAP_SPEED.y - TAP_SPEED.x), 0.0, 1.0)
		_sfx("cord_tap", tap_at, lerpf(-12.0, 0.0, k))
		r["tap"] = TAP_GAP
	r["len"] = length
	var moved := 0.0
	for i in range(1, last):
		moved = maxf(moved, pts[i].distance_squared_to(old[i]))
	r["calm"] = r.get("calm", 0) + 1 if settled and moved < SLEEP_MOVE * SLEEP_MOVE else 0
	if r["calm"] > SLEEP_STEPS:
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		r["sleep"] = box.grow(16.0)   # área onde o mouse acorda o fio
	if free and length <= SEAT_LEN:
		_sfx("cord_stop", a)   # o fio terminou de entrar
		an["seat"] = 0.0
		an["from"] = pts[last]
		an["ang"] = _cord_angle(e)


# ------------------------------------------------------------------ desenho

## Cor da lâmpada de uma linha (Exchange.Line) e quanto ela quer estar acesa (0..1); `_fade` chega lá aos poucos.
func _lamp(st: int, ms: int, steady: bool) -> Array:
	match st:
		Exchange.Line.RING:
			return [Pal.AMBER, 1.0 if steady or (ms / 250) % 2 == 0 else 0.0]
		Exchange.Line.TALK:
			return [Pal.AMBER, 1.0]
		Exchange.Line.HOLD:
			return [Pal.AMBER, 1.0 if (ms / 800) % 2 == 0 else 0.45]
		Exchange.Line.CONN:
			return [Pal.GREEN, 1.0]
		Exchange.Line.DONE:
			return [Pal.RED, 1.0]
	return [LAMP_OFF, 0.0]


## Os estados de destino (Exchange.Dest) acendem como os de linha equivalentes.
func _dest_lamp(st: int, ms: int) -> Array:
	match st:
		Exchange.Dest.RING:
			return _lamp(Exchange.Line.RING, ms, false)
		Exchange.Dest.CONN:
			return [Pal.GREEN, 1.0]
		Exchange.Dest.DONE:
			return [Pal.RED, 1.0]
	return [LAMP_OFF, 0.0]


## A lâmpada `key` vai para `want` ([cor, nível]): acende em `LAMP_ON_SEC`, apaga em `LAMP_OFF_SEC`, mantendo a cor.
func _fade(key: String, want: Array, delta: float) -> void:
	var cur: Array = _lit.get(key, [want[0], 0.0])
	if want[1] > 0.0:
		cur[0] = want[0]
	var lv: float = cur[1]
	cur[1] = move_toward(lv, want[1], delta / (LAMP_ON_SEC if want[1] > lv else LAMP_OFF_SEC))
	_lit[key] = cur


## Lâmpada de mesa antiga: uma tampa de vidro leitoso, abaulada, num aro fino de níquel, sem furo (com o assento
## preto, ela parecia mais uma tomada). Apagada, o vidro fica leitoso (`LAMP_OFF`); acesa, toma a cor da linha, o aro
## pega a cor dela e o centro estoura para o branco (o halo é do `Bloom`). A luz da sala brilha no alto do vidro.
func _draw_lamp(c: Vector2, col: Color, level: float) -> void:
	_sprite(disc(16, [[7.0, BEZEL[0], BEZEL[1], BEZEL[2]], [8.0, EDGE_DARK]]), c)   # o aro
	if level > 0.02:
		_sprite(disc(16, [[6.0, Color.TRANSPARENT], [7.0, Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT]]), c, Color(col, 0.35 * level))   # a luz no aro
	var glass := LAMP_OFF.lerp(col, level)
	_sprite(disc(12, [[6.0, glass.lightened(0.3), glass, glass.darkened(0.4)]]), c)   # o vidro abaulado: luz no alto à esquerda
	if level > 0.02:   # acesa: o centro estoura para o branco (o halo é do Bloom; o miolo nítido, daqui)
		_sprite(disc(6, [[2.8, Color.WHITE]]), c, Color(Color.WHITE.lerp(col, Bloom.HOT_TINT), level))
		Bloom.light(self, Rect2(c - Vector2(LAMP_R, LAMP_R), Vector2(LAMP_R, LAMP_R) * 2.0), Color(col, level), 1.0, false, true)
	draw_rect(Rect2(c + Vector2(-3, -4), Vector2(2, 1)), Color(1, 1, 1, 0.5))   # o brilho da sala no vidro
	draw_rect(Rect2(c + Vector2(-4, -3), Vector2(1, 1)), Color(1, 1, 1, 0.25))


## Encaixe redondo como os das mesas antigas, pixel a pixel (`JACK_ART`), com a sombra no painel. `dim`: o metal mais
## escuro (`_jack_pal`).
func _draw_jack(jr: Rect2, dim := 0.0) -> void:
	var r := _jack_px(jr)
	draw_texture_rect(art(JACK_ART, {"*": Color(0, 0, 0, 0.35)}), Rect2(r.position + Vector2(1, 2), r.size), false)
	draw_texture_rect(art(JACK_ART, _jack_pal(dim)), r, false)


## Onde o desenho do encaixe `jr` fica (`JACK_PX` em volta do meio dele).
func _jack_px(jr: Rect2) -> Rect2:
	return Rect2(jr.get_center() - Vector2(JACK_PX, JACK_PX) / 2.0, Vector2(JACK_PX, JACK_PX))


## As cores do encaixe: níquel (`dim` escurece o metal: as saídas, para não se confundirem com as entradas).
func _jack_pal(dim: float) -> Dictionary:
	var pal := {"l": Color("f3eee0"), "L": Color("cfc3a9"), "M": Color("8e8272"), "D": Color("4f4840"),
		"d": Color("35302a"), "W": Color("e0d6c0")}
	for k in pal:
		pal[k] = (pal[k] as Color).darkened(dim)
	pal.merge({"e": Color("0b0907"), "h": Color("050403"), "k": Color("1e1b17")})
	return pal


## A luz de uma lâmpada batendo no aro do encaixe logo abaixo dela (o lado de cima, virado para a luz).
func _reflect(jr: Rect2, col: Color, level: float) -> void:
	if level > 0.02:
		draw_texture_rect(art(JACK_ART, {"l": Color.WHITE, "L": Color.WHITE}), _jack_px(jr), false, Color(col, 0.55 * level))


func _draw() -> void:
	Bloom.clear(self)
	var w := size.x
	var h := size.y
	var ms := Time.get_ticks_msec()
	_draw_cabinet(Rect2(Vector2.ZERO, size))
	_draw_tray(tray_rect())
	for y in RULES.values():
		_draw_rule(y, "")
	if exchange == null:
		return
	_draw_strips()
	_draw_rule(RULES["in"], T.text(T.Key.BOARD_INPUTS), false)   # os nomes por cima das faixas
	_draw_rule(RULES["out"], T.text(T.Key.BOARD_OUTPUTS), false)
	_draw_wear()
	_draw_maker_plate()

	# entradas e saídas
	for i in 10:
		var n := i + 1
		var st := exchange.line(n)
		var cx := col_x(i)
		_draw_number_plate(Rect2(cx - 18, ROW_Y["plate"], 36, ROW_Y["plate_h"]), "%02d" % n)
		var lt: Array = _lit.get("l%d" % n, [LAMP_OFF, 0.0])
		_draw_lamp(Vector2(cx, ROW_Y["lamp"]), lt[0], lt[1])
		_draw_jack(jack_rect(n))
		_reflect(jack_rect(n), lt[0], lt[1])
		var sc := Pal.DIM
		if st in [Exchange.Line.RING, Exchange.Line.TALK, Exchange.Line.HOLD]:
			sc = Pal.AMBER
		elif st == Exchange.Line.DONE:
			sc = Pal.RED
		var label := tiny(exchange.line_label(n))   # as letras vão de 3 a 7 na imagem: o pé delas logo acima de ROW_Y
		draw_texture(label, Vector2(roundf(cx - label.get_width() / 2.0), ROW_Y["state"] - 8.0), sc)
		_draw_jack(jack_rect(n + 10), 0.25)

	# destinos: a faixa de numeração de cada banco fica sobre a faixa gravada, como rótulo da seção
	for s in _blocks:
		var br: Rect2 = _blocks[s]
		var cap := "%d–%d" % [s * 100, s * 100 + 99]
		draw_rect(Rect2(br.position.x, RULES["dest"] - 7, Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 8, 15), Pal.PANEL)
		draw_string(Pal.ui, Vector2(br.position.x + 4, RULES["dest"] + 5), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.DIM)
		draw_rect(br, Pal.PANEL_LO, false, 1.0)
	for d in dest_nums:
		var jr := jack_rect(d)
		var cx := jr.get_center().x
		var st := exchange.dest(d)
		draw_string(Pal.mono, Vector2(cx - 16, jr.position.y - 5), str(d), HORIZONTAL_ALIGNMENT_CENTER, 32, 11, Color("d8c9a2") if st == Exchange.Dest.FREE else Pal.TEXT)
		var dl: Array = _lit.get("d%d" % d, [LAMP_OFF, 0.0])
		if dl[1] > 0.02:   # o aro em volta da tomada acende
			_sprite(disc(JACK_PX + 8, [[JACK_PX / 2.0 + 4.0, Color.WHITE]]), jr.get_center(), Color(dl[0], dl[1]))
			Bloom.light(self, jr.grow((JACK_PX - JACK) / 2.0 + 3.0), Color(dl[0], dl[1]), 1.0, false, true)
		_draw_jack(jr)
	for s in _blocks:
		if not s in GameData.sectors:
			_draw_plate(_blocks[s], "ABC"[SECTOR_ORDER.find(s)])

	# legenda das lâmpadas, numa linha no pé do painel
	_draw_legend()

	# destaque da tomada sob o plug
	if held != -1:
		var hj := jack_at(get_local_mouse_position())
		if hj != -1:
			var ok := refuse(held, hj) == ""
			var hr := jack_rect(hj)
			draw_arc(hr.get_center(), hr.size.x / 2.0 + 4.0, 0.0, TAU, 32, Pal.GLOW if ok else Pal.RED, 2.0)
			if ok:
				var gc := Pal.GLOW
				gc.a = 0.2
				draw_rect(hr, gc)

	# cada ponta (fio e plug) na ordem em que foi mexida: o fio da mais recente passa por cima dos plugs das
	# outras (o da mão inclusive); as sombras antes, por baixo de tudo
	for e in _order:
		_draw_rope(e, true)
		_draw_plug(e, true)
	for e in _pulled:   # plugs que acabaram de sair: a vista de frente sumindo no encaixe
		var k: float = _pulled[e][0] / MORPH_SEC
		draw_set_transform(_pulled[e][1], 0.0, Vector2.ONE * lerpf(1.0, 0.4, k))
		_draw_plug_face(_cable_col(e), _pulled[e][2], 0.0, 1.0 - k)
		draw_set_transform(Vector2.ZERO)
	for e in _order:
		if ends[e] != -1:   # encaixado, visto de frente: o fio sai do meio dele (da ponteira), por cima do tampo
			_draw_plug(e, false)
			Bloom.occlude(self, Transform2D(0.0, jack_rect(int(ends[e])).get_center().round()) * _plug_outline(e, 1.0))
			_draw_rope(e, false)
			_draw_plug_cap(e)
		else:
			_draw_rope(e, false)
			_draw_plug(e, false)
		if ropes.has(e) and not _in_hole(e):   # o fio sai de dentro do buraco: a beira da frente passa por cima dele
			draw_lip(self, hole(e))

	# balão de informação
	if ms < info_until and info_line > 0:
		var jr := jack_rect(info_line)
		var bw := 200.0
		var bh := 12.0 + info_lines.size() * 19.0
		var bx := clampf(jr.get_center().x - bw / 2, 8, w - bw - 8)
		var by := minf(jr.end.y + 8, h - bh - 8)
		var bc := Pal.GHOST if info_ghost else Pal.BRASS
		draw_rect(Rect2(bx, by, bw, bh), bc)
		draw_rect(Rect2(bx + 2, by + 2, bw - 4, bh - 4), Color("0e0c08"))
		for k in info_lines.size():
			draw_string(Pal.mono, Vector2(bx + 10, by + 22 + k * 19), info_lines[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.GHOST if info_ghost else Pal.TEXT)


## O móvel da mesa: a moldura de madeira (`_wood_frame`), com o brilho da luminária do teto na quina de cima, mais
## forte do lado dela (no meio da tela, à direita da mesa), e o painel de metal escuro dentro, rebaixado.
func _draw_cabinet(r: Rect2) -> void:
	draw_texture(_wood_frame(r.size), r.position)
	var lamp := get_viewport_rect().size.x / 2.0 - global_position.x
	var glint := func(x: float) -> Color:
		return Color(WOOD[0].lightened(0.45), 0.6 * clampf(1.0 - absf(x - lamp) / 700.0, 0.0, 1.0))
	var top := r.position.y + 1.0
	draw_polygon(PackedVector2Array([Vector2(r.position.x + 1, top), Vector2(r.end.x - 1, top), Vector2(r.end.x - 1, top + 1), Vector2(r.position.x + 1, top + 1)]),
		PackedColorArray([glint.call(r.position.x), glint.call(r.end.x), glint.call(r.end.x), glint.call(r.position.x)]))
	var p := r.grow(-FRAME)
	draw_rect(p.grow(1), EDGE_DARK)
	draw_rect(p, Pal.PANEL)
	draw_rect(Rect2(p.position, Vector2(p.size.x, 2)), Pal.PANEL_LO)   # rebaixado: a sombra fica em cima à esquerda
	draw_rect(Rect2(p.position, Vector2(2, p.size.y)), Pal.PANEL_LO)
	draw_rect(Rect2(p.position.x, p.end.y - 1, p.size.x, 1), Pal.PANEL_HI)


## A faixa de cada linha: um rebaixo estreito do painel que liga a plaquinha, a lâmpada, a entrada e a saída da mesma
## coluna (sem ela, a saída parecia solta). As faixas gravadas passam por baixo; o nome delas, por cima.
func _draw_strips() -> void:
	for i in 10:
		var r := Rect2(col_x(i) - STRIP_W / 2.0, ROW_Y["plate"] + 4.0, STRIP_W, ROW_Y["out"] + 11.0 - ROW_Y["plate"])
		draw_rect(r, Pal.PANEL.darkened(0.05))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(Pal.PANEL_LO, 0.6))   # rebaixada: a sombra em cima e à esquerda
		draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color(Pal.PANEL_LO, 0.6))
		draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), Color(Pal.PANEL_HI, 0.5))
		draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), Color(Pal.PANEL_HI, 0.5))


## O uso de anos: o painel gasto em volta das tomadas (claro liso, mais nas entradas, onde o FONE entra a noite toda,
## e nas primeiras linhas) e riscos finos onde a ponta do plug escorregou errando o furo. Sempre os mesmos.
func _draw_wear() -> void:
	for j in _jacks:
		var use := _use(j)
		_sprite(disc(28, [[10.0, Color(Pal.PANEL_HI, WEAR[0])], [12.0, Color(Pal.PANEL_HI, WEAR[1])], [14.0, Color(Pal.PANEL_HI, WEAR[2])]]),
			jack_rect(j).get_center(), Color(1, 1, 1, use))
		var rng := RandomNumberGenerator.new()
		rng.seed = j
		for k in roundi(use * 2.0):
			var a := rng.randf() * TAU
			var from := jack_rect(j).get_center() + Vector2.from_angle(a) * rng.randf_range(9.0, 11.0)
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * rng.randf_range(3.0, 6.0)
			draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), Color(Pal.PANEL_HI, 0.45), 1.0)


## O quanto a tomada `j` é usada (0..1): as entradas mais, das primeiras linhas para as últimas; depois as saídas; os
## destinos, menos.
func _use(j: int) -> float:
	if j <= 10:
		return 1.0 - (j - 1) * 0.05
	if j <= 20:
		return 0.6 - (j - 11) * 0.03
	return 0.35


## A plaqueta de latão do fabricante, no pé do painel (ali ficava vazio), no vão entre os dois primeiros pares de
## buracos da prateleira, onde nenhum plug guardado fica na frente: o nome da central gravado (escuro, com o brilho
## embaixo) e um parafuso em cada ponta.
func _draw_maker_plate() -> void:
	var cx := roundf((hole(2).x + hole(3).x) / 2.0)
	var bottom := DEST_TOP - 21.0 + DEST_ROW + 50.0   # o pé dos bancos de destino
	var r := Rect2(cx - 48.0, roundf((bottom + SIZE.y - FRAME) / 2.0 - 13.0), 96.0, 26.0)
	var pal := HOLE_PAL
	draw_rect(Rect2(r.position + Vector2(1, 2), r.size), SHADOW)
	draw_rect(r.grow(1), EDGE_DARK)
	draw_rect(r, Color("b0904c"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), pal["F"])
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), pal["f"])
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), pal["b"])
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), pal["b"])
	draw_rect(r.grow(-3), pal["b"], false, 1.0)   # o friso gravado em volta
	for x in [r.position.x + 7.0, r.end.x - 7.0]:
		_sprite(disc(5, [[1.5, pal["F"], pal["f"], pal["b"]], [2.5, pal["w"]]]), Vector2(x, r.get_center().y))
		draw_rect(Rect2(x - 1.0, r.get_center().y, 3, 1), pal["w"])   # a fenda
	var maker := tiny(T.text(T.Key.BOARD_MAKER))
	var at := Vector2(roundf(cx - maker.get_width() / 2.0), r.position.y + 2.0)
	draw_texture(maker, at + Vector2(0, 1), pal["F"])
	draw_texture(maker, at, pal["w"])
	var town := "SÃO SOTERO"
	var nw := Pal.mono.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var np := Vector2(roundf(cx - nw / 2.0), r.end.y - 6.0)
	draw_string(Pal.mono, np + Vector2(0, 1), town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["F"])
	draw_string(Pal.mono, np, town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["w"])


## A moldura de madeira do móvel, pixel a pixel e guardada: quatro trilhos com os cantos em meia-esquadria (uma
## emenda escura na diagonal), cada um com os veios ao longo dele, ondulando (os de cima e de baixo deitados, os dos
## lados em pé); a beira escura por fora, a luz em cima e à esquerda, a sombra embaixo e à direita, e as quinas gastas,
## mais claras, de anos de mãos.
static var _woods := {}
func _wood_frame(sz: Vector2) -> ImageTexture:
	if not _woods.has(sz):
		var w := int(sz.x)
		var h := int(sz.y)
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var f := int(FRAME)
		for y in h:
			for x in w:
				var ex := mini(x, w - 1 - x)   # distância à beira de fora, na horizontal e na vertical
				var ey := mini(y, h - 1 - y)
				if ex >= f and ey >= f:
					continue   # o painel
				var upright := ex < ey   # nos cantos, a emenda em diagonal decide o trilho
				var rail := (0 if x < w / 2 else 1) if upright else (2 if y < h / 2 else 3)
				var along := float(y if upright else x)
				var across := float(ex if upright else ey)
				var g := fposmod(across + 1.4 * sin(along * 0.035 + rail * 2.1) + 0.7 * sin(along * 0.11 + rail * 4.3), 3.0)
				var c: Color = WOOD[1]
				if g < 0.55:
					c = WOOD[2].lightened(0.12)   # o veio escuro
				elif g > 1.6 and g < 1.9:
					c = WOOD[1].lightened(0.08)   # o claro entre os veios
				if ex == ey and ex < f:
					c = WOOD[2]   # a emenda do canto
				var corner := Vector2(mini(x, w - 1 - x), mini(y, h - 1 - y)).length()
				c = c.lerp(WOOD[0].lightened(0.15), 0.45 * clampf(1.0 - corner / 10.0, 0.0, 1.0))   # quina gasta
				if ex == 0 or ey == 0:
					c = EDGE_DARK
				elif (x == 1 or y == 1) and x < w - 2 and y < h - 2:
					c = WOOD[0]   # a luz em cima e à esquerda
				elif x == w - 2 or y == h - 2:
					c = WOOD[2]
				img.set_pixel(x, y, c)
		_woods[sz] = ImageTexture.create_from_image(img)
	return _woods[sz]


## Faixa gravada que separa as seções do painel, com o nome dela em cima, à esquerda (sem nome, só a faixa; sem
## `line`, só o nome).
## A legenda das lâmpadas, na faixa das entradas, alinhada à direita e logo acima das lâmpadas que ela explica, na
## fonte gravada do painel (`tiny`; em 11 não cabia ali). No pé do painel, os plugs guardados passavam na frente dela.
func _draw_legend() -> void:
	var leg := [[Pal.AMBER, T.Key.LEGEND_RING], [Pal.GREEN, T.Key.LEGEND_CONN], [Pal.RED, T.Key.LEGEND_DONE], [LAMP_OFF, T.Key.LEGEND_FREE]]
	var texts := []
	var width := -10.0
	for item in leg:
		var t := tiny(T.text(item[1]))
		texts.append(t)
		width += 9.0 + 4.0 + t.get_width() + 10.0
	var y := RULES["in"] + 1.0
	var x := floorf(size.x - FRAME - 18.0 - width)
	draw_rect(Rect2(x - 5, y - 8, width + 10, 15), Pal.PANEL)   # tampa a faixa, como o nome dela
	for k in leg.size():
		_sprite(disc(9, [[3.0, Color.WHITE], [4.5, EDGE_DARK]]), Vector2(x + 4.5, y), leg[k][0])   # lâmpadas redondas, como as da mesa
		_sprite(disc(9, [[3.0, Color.TRANSPARENT], [4.5, EDGE_DARK]]), Vector2(x + 4.5, y))
		draw_texture(texts[k], Vector2(x + 13.0, y - 5.0), Pal.DIM)
		x += 9.0 + 4.0 + (texts[k] as Texture2D).get_width() + 10.0


func _draw_rule(y: float, caption: String, line := true) -> void:
	if line:
		draw_rect(Rect2(FRAME + 6, y, size.x - FRAME * 2 - 12, 1), Pal.PANEL_LO)
		draw_rect(Rect2(FRAME + 6, y + 1, size.x - FRAME * 2 - 12, 1), Pal.PANEL_HI)
	if caption != "":
		var cw := Pal.ui.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_rect(Rect2(FRAME + 14, y - 7, cw + 8, 15), Pal.PANEL)
		draw_string(Pal.ui, Vector2(FRAME + 18, y + 5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.BRASS)


## A prateleira à frente do painel, onde os cabos de conexão ficam guardados de pé: os buracos de onde saem os fios
## (a cor de cada cabo já diz qual é; o nome gravado embaixo saiu, a pedido).
func _draw_tray(_r: Rect2) -> void:
	for k in PATCHES:
		for e in [1 + k * 2, 2 + k * 2]:
			draw_grommet(self, hole(e))


## Um nome gravado na madeira da prateleira, centrado em `at.x` com a base em `at.y`: o sulco escuro e o latão.
static func engrave(ci: CanvasItem, at: Vector2, text: String) -> void:
	var f: Font = Pal.mono if Pal.mono != null else ThemeDB.fallback_font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var p := Vector2(roundf(at.x - w / 2.0), at.y)
	ci.draw_string(f, p + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0, 0, 0, 0.6))
	ci.draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.BRASS)


## Buraco da prateleira visto de cima (achatado pela perspectiva), pixel a pixel (`HOLE_ART`): o aro de latão, com a
## beira de trás na sombra e a da frente pegando a luz, a parede de dentro do lado de trás (olhando de cima, é a que
## aparece) e o vão escuro. Sem contorno preto (destoava do cenário).
static func draw_grommet(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_texture_rect(art(HOLE_ART, HOLE_PAL), _hole_px(c), false)


## A beira da frente do buraco (`draw_grommet`), por cima do plug guardado nele: o plug entra no buraco.
static func draw_lip(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_texture_rect(art(HOLE_ART, {"f": HOLE_PAL["f"], "F": HOLE_PAL["F"]}), _hole_px(c), false)


static func _hole_px(c: Vector2) -> Rect2:
	var size := Vector2((HOLE_ART[0] as String).length(), HOLE_ART.size())
	return Rect2((c - size / 2.0).round(), size)


## Chapa de metal niquelado: chanfro claro em cima e escuro embaixo, e um rebite em cada ponta.
func _draw_metal(r: Rect2) -> void:
	draw_rect(r.grow(1), EDGE_DARK)
	draw_rect(r, BEZEL[1])
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), BEZEL[0])
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), BEZEL[0].darkened(0.1))
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), BEZEL[2])
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), BEZEL[2].lightened(0.1))
	for x in [r.position.x + 2.0, r.end.x - 5.0]:   # rebites: um pixel claro no alto de um escuro
		var rv := Vector2(x, floorf(r.get_center().y - 1.5))
		draw_rect(Rect2(rv, Vector2(3, 3)), BEZEL[2])
		draw_rect(Rect2(rv, Vector2(1, 1)), BEZEL[0])


## Plaquinha de metal com o número da linha gravado (escuro, com o brilho embaixo de quem foi rebaixado), centrado
## pela medida da fonte.
func _draw_number_plate(r: Rect2, text: String) -> void:
	_draw_metal(r)
	var size := Pal.mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	var at := Vector2(roundf(r.get_center().x - size.x / 2.0), roundf(r.get_center().y + (Pal.mono.get_ascent(11) - Pal.mono.get_descent(11)) / 2.0))
	draw_string(Pal.mono, at + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BEZEL[0])   # o brilho do rebaixo
	draw_string(Pal.mono, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("1d1a14"))


## Chapa de metal parafusada sobre um banco que ainda não está em uso (lisa: o escovado saiu, a pedido): a letra do
## banco estampada em relevo (luz em cima à esquerda, sombra embaixo à direita), o aviso
## pintado com estêncil embaixo e, em volta dos parafusos, os riscos da chave de fenda que escorregou. Sempre os mesmos.
func _draw_plate(r: Rect2, letter: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(letter)
	draw_rect(r.grow(1), EDGE_DARK)
	draw_rect(r, PLATE)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), PLATE.lightened(0.18))
	draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), PLATE.darkened(0.35))
	for c in [r.position + Vector2(7, 7), Vector2(r.end.x - 7, r.position.y + 7), Vector2(r.position.x + 7, r.end.y - 7), r.end - Vector2(7, 7)]:
		for k in 2:   # a chave de fenda escorregou, sempre para dentro da chapa (para fora, o risco passava da borda)
			var a: float = (r.get_center() - c).angle() + rng.randf_range(-0.6, 0.6)
			var from: Vector2 = c + Vector2.from_angle(a) * 4.0
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.3, 0.3)) * rng.randf_range(2.0, 5.0)
			draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), PLATE.lightened(0.3), 1.0)
		_sprite(disc(7, [[2.5, PLATE.lightened(0.35), PLATE.lightened(0.15), PLATE.darkened(0.2)], [3.5, PLATE.darkened(0.5)]]), c)
		draw_rect(Rect2((c - Vector2(2, 1)).floor(), Vector2(3, 1)), PLATE.darkened(0.5))   # fenda do parafuso
	var at := Vector2(r.position.x, r.get_center().y + 8.0)   # a letra estampada
	draw_string(Pal.mono, at + Vector2(1, 1), letter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 33, PLATE.darkened(0.45))
	draw_string(Pal.mono, at - Vector2(0, 1), letter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 33, PLATE.lightened(0.35))
	draw_string(Pal.mono, at, letter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 33, PLATE.lightened(0.15))
	var notice := tiny(T.text(T.Key.BOARD_PLATE_NOTICE))   # pintado com estêncil, já gasto
	draw_texture(notice, Vector2(roundf(r.get_center().x - notice.get_width() / 2.0), r.get_center().y + 13.0), Color("c9b98f", 0.6))


## [cor, brilho] do cabo da ponta e.
func _cable_col(e: int) -> Array:
	return CORD_COLORS[cable_of(e)]


func _draw_rope(e: int, shadow: bool) -> void:
	if not ropes.has(e):
		return
	var pts: PackedVector2Array = ropes[e]["pts"]
	if shadow:
		var sh := PackedVector2Array()   # o fio desce do plug até o buraco: a sombra vai da do plug até a de rente ao painel
		var lift := _lift(e)
		for i in pts.size():
			var k := float(i) / (pts.size() - 1)
			sh.append(pts[i] + ROPE_SHADOW.lerp(lift, k * k))
		draw_polyline(sh, SHADOW, 7.0)
		return
	var col: Array = _cable_col(e)
	pts = _kinked(e, pts)
	draw_polyline(pts, (col[0] as Color).darkened(EDGE), 8.0)
	draw_polyline(pts, col[0], 5.0)
	var pts2 := PackedVector2Array()
	var length := 0.0
	for i in pts.size():
		pts2.append(pts[i] + Vector2(-1, -1))
		if i > 0:
			length += pts[i].distance_to(pts[i - 1])
	var at := 0.0
	while at < length:   # o trançado do pano: o brilho em pedaços
		var part := _along(pts2, at, minf(at + BRAID - 2.0, length))
		if part.size() >= 2:
			draw_polyline(part, col[1], 1.5)
		at += BRAID
	for band in HOLE_SHADE:   # perto do buraco, a sombra de dentro dele, em degraus
		var part := _along(pts, band[0], band[1])
		if part.size() >= 2:
			draw_polyline(part, Color(0, 0, 0, band[2]), 5.0)


## As dobras que um fio de pano velho guarda: cada ponto da corda sai um pouco para um lado, sempre o mesmo para cada
## ponto (a dobra anda com o fio), menos perto das pontas. Só no desenho: a física continua com a corda lisa.
func _kinked(e: int, pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	var n := pts.size()
	for i in range(1, n - 1):
		var side := fposmod(sin(i * 12.9898 + e * 78.233) * 43758.5453, 1.0) * 2.0 - 1.0
		out[i] += (pts[i + 1] - pts[i - 1]).normalized().orthogonal() * KINK * side * sin(PI * i / (n - 1))
	return out


## O trecho da linha `pts` entre `from` e `to` px a partir do começo dela.
func _along(pts: PackedVector2Array, from: float, to: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var run := 0.0
	for i in pts.size() - 1:
		var d := pts[i].distance_to(pts[i + 1])
		if d > 0.0 and run + d > from:
			out.append(pts[i].lerp(pts[i + 1], clampf((maxf(from, run) - run) / d, 0.0, 1.0)))
			if run + d >= to:
				out.append(pts[i].lerp(pts[i + 1], (to - run) / d))
				return out
		run += d
	if not out.is_empty():
		out.append(pts[pts.size() - 1])
	return out


## Plug em pé, a partir de onde o fio entra nele: corpo na cor do cabo, anel de latão e ponta de metal (com o
## risco que separa ponta e anel, como num plug de mesa telefônica). Encaixado, a ponta está dentro da tomada.
## Girado quando solto. A sombra é o contorno, mais longe quanto mais o plug sai do painel (na mão, mais).
func _draw_plug(e: int, shadow: bool) -> void:
	var seated: bool = ends[e] != -1
	var tilt := _tilt(int(ends[e])) if seated else Vector2.ZERO
	var at := _plug_base(e) - tilt   # encaixado, desenha a partir do encaixe
	if shadow and not seated:
		at += _lift(e)
	draw_set_transform(at.round(), _plug_angle(e))
	_cut = hole(e).y + HOLE_LIP - at.round().y if _in_hole(e) else INF
	if shadow and seated:   # do encaixe até onde a luz joga a ponta, no painel
		draw_colored_polygon(Geometry2D.convex_hull(_circle(Vector2.ZERO, PLUG_FACE_R + 1.0) + _circle(PLUG_SHADE, PLUG_FACE_R)), SHADOW)
		_sprite(disc(PLUG_ABA_D + 2, [[PLUG_ABA_D / 2.0 + 1.0, Color.WHITE]]), Vector2.ZERO, SHADOW)   # sombra de contato: a aba presa no encaixe
	elif shadow:
		_draw_cut(_plug_outline(e, 0.0), SHADOW)
	else:
		if e == _hover:   # contorno claro, na forma do plug: dá para pegar
			_draw_cut(_plug_outline(e, 2.0), Pal.GLOW)
		if seated:
			var k := minf(float(_pushed.get(e, MORPH_SEC)) / MORPH_SEC, 1.0)
			if k < 1.0:   # acabou de encaixar: a vista de frente cresce enquanto o corpo em pé entra no encaixe
				draw_set_transform(at.round(), 0.0, Vector2.ONE * lerpf(0.4, 1.0, k))
			_draw_plug_face(_cable_col(e), tilt, _push(e), 1.0, int(ends[e]))
			if k < 1.0:   # o corpo em pé gira para o eixo do encaixado e encurta até o tamanho dele, entrando no encaixe
				var axis := Transform2D(lerpf(0.0, tilt.angle() - PI / 2.0, k), Vector2(1.0, lerpf(1.0, tilt.length() / PLUG_LEN, k)), 0.0, at.round())
				draw_set_transform_matrix(axis * Transform2D(0.0, Vector2(0, PLUG_LEN)))
				_draw_plug_body(_cable_col(e), false)
		else:
			_draw_plug_body(_cable_col(e))
	draw_set_transform(Vector2.ZERO)
	if _cut < INF and not shadow:
		draw_lip(self, hole(e))
	_cut = INF


## O plug em pé está entrando no buraco dele (guardado ou assentando): a parte de baixo some no buraco.
func _in_hole(e: int) -> bool:
	return ends[e] == -1 and held != e and (not _loose.has(e) or float(_loose[e]["seat"]) >= 0.0)


## Desenha o polígono `shape` do plug em pé só até `_cut` (sombra e destaque).
func _draw_cut(shape: PackedVector2Array, col: Color) -> void:
	if _cut < INF:
		var cut := Geometry2D.intersect_polygons(shape, PackedVector2Array([Vector2(-30, -90), Vector2(30, -90), Vector2(30, _cut), Vector2(-30, _cut)]))
		shape = cut[0] if not cut.is_empty() else PackedVector2Array()
	if shape.size() >= 3:
		draw_colored_polygon(shape, col)


## Desenha `r` no plug em pé só até `_cut` (o resto está dentro do buraco da prateleira).
func _pr(r: Rect2, col: Color) -> void:
	r.size.y = minf(r.end.y, _cut) - r.position.y
	if r.size.y > 0.0:
		draw_rect(r, col)


## Quanto a sombra se desloca de onde o fio entra no plug: mais quanto mais o plug sai do painel (na mão, mais).
## Encaixado, a sombra da ponteira fica no fim da do plug (`PLUG_SHADE`, contada do encaixe).
func _lift(e: int) -> Vector2:
	if ends[e] != -1:
		return PLUG_SHADE - _tilt(int(ends[e]))
	return Vector2(8, 10) if held == e else Vector2(4, 5) if _loose.has(e) else Vector2(2, 2)


## A silhueta do plug (as mesmas partes de `_draw_plug_body`, juntas num polígono só: a sombra não escurece duas
## vezes onde elas se sobrepõem), alargada `grow` px para o destaque.
func _plug_outline(e: int, grow: float) -> PackedVector2Array:
	var seated: bool = ends[e] != -1
	var key: Variant = _tilt(int(ends[e])) if seated else false
	if not _silhouette.has(key):
		var box := func(r: Rect2) -> PackedVector2Array:
			return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		var parts := [Geometry2D.convex_hull(_circle(Vector2.ZERO, PLUG_FACE_R + 1.0) + _circle(key, PLUG_FACE_R + 1.0))] if seated else [box.call(Rect2(-9, -56, 18, 36)),
			box.call(Rect2(-8, -20, 16, 20)), box.call(Rect2(-6, -59, 12, 3)), box.call(Rect2(-4, -86, 8, 27)), box.call(Rect2(-3, -91, 6, 5)),
			box.call(Rect2(-1, -93, 2, 2))]
		var shape: PackedVector2Array = parts[0]
		for part in parts.slice(1):
			shape = Geometry2D.merge_polygons(shape, part)[0]
		_silhouette[key] = shape
	if grow == 0.0:
		return _silhouette[key]
	return Geometry2D.offset_polygon(_silhouette[key], grow, Geometry2D.JOIN_ROUND)[0]


func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(c + Vector2.from_angle(TAU * i / 16.0) * r)
	return pts


## Quanto a ponta do plug encaixado em `j` fica deslocada do encaixe: ele sai do painel na direção da câmera, que o
## vê mais de lado quanto mais longe do ponto que ela olha reto (`PLUG_EYE`).
func _tilt(j: int) -> Vector2:
	return _tilt_at(jack_rect(j).get_center()).round()


## A paralaxe num ponto `p` da mesa: o que sai do painel ali se desloca assim (e o que entra, para o lado oposto).
func _tilt_at(p: Vector2) -> Vector2:
	return (p - PLUG_EYE) * PLUG_DEPTH


## O plug encaixado, a partir do encaixe, saindo do painel até `tilt`: o próprio plug em pé (`PLUG_ART`, da aba ao
## fio) visto de frente, em pixel art como as peças redondas: um disco (`disc`) por pixel ao longo do eixo, do painel
## para a frente, cada um com a largura, a beira e os tons da linha do plug em pé que cai ali (`_face_row`): a aba
## dourada, o corpo na cor do cabo com o anel e o friso claro em cima, o serrilhado (discos riscados, `_knurled`) e o
## anel do meio, e a capa de borracha em gomos afinando até o fio. Primeiro a beira de todos (só o contorno fica à
## mostra) e depois o miolo sombreado (luz no alto à esquerda). (Antes eram cápsulas e círculos vetoriais: embolotados.)
## O fio sai do meio da capa, por cima (desenhado depois). `push`: a assentada, o plug afunda tantos px. `j`: o
## encaixe, para a luz que bate no plug (`_plug_light`): no fim, o contorno do plug inteiro acende (`_face_rim`), só
## em cima (a lâmpada logo acima) ou em volta toda (o aro aceso do destino). (Um anel solto por cima, antes, flutuava
## sobre a capa e a luz vinha do lado; uma beira acesa por disco listrava o plug todo.)
func _draw_plug_face(col: Array, tilt: Vector2, push: float, alpha: float, j := -1) -> void:
	var pal := _plug_pal(col)
	var t := tilt - tilt.normalized() * push
	var n := maxi(1, ceili(t.length()))
	var mod := Color(1, 1, 1, alpha)
	var light := _plug_light(j)
	for k in n + 1:
		var r := _face_row(n, k)
		_sprite(disc(r[0], [[r[0] / 2.0, pal[r[1]]]]), t * float(k) / n, mod)
	for k in n + 1:
		var r := _face_row(n, k)
		var d: int = r[0] - 2
		var tones := [pal[r[2]], pal[r[3]], pal[r[4]]]
		_sprite(_knurled(d, tones) if r[5] else disc(d, [[d / 2.0, tones[0], tones[1], tones[2]]]), t * float(k) / n, mod)
	if light[1] > 0.02:
		var rim: Array = _face_rim(t, n, light[2])
		draw_texture(rim[0], rim[1], Color((light[0] as Color).lightened(0.35), light[1] * 0.8 * alpha))


## A linha do `PLUG_ART` que aparece no passo `k` de `n` do plug encaixado, como [diâmetro com a beira, beira, luz,
## meio, sombra, serrilhado] (caracteres da paleta, `_plug_pal`). Encaixado, ele tem poucos px de comprido: das linhas
## que caem no passo, da mesma peça que a primeira, vale a que mais se destaca (um anel, o friso claro; o serrilhado no
## empate), senão os detalhes sumiam entre um passo e outro; na capa, gomo escuro e claro se revezam. Guardada.
static var _face_rows := {}
func _face_row(n: int, k: int) -> Array:
	var key := Vector2i(n, k)
	if not _face_rows.has(key):
		var top := int(PLUG_H - PLUG_LEN)
		var a := top + floori(PLUG_LEN * k / (n + 1.0))
		var b := maxi(a + 1, top + floori(PLUG_LEN * (k + 1) / (n + 1.0)))
		var best := []
		var score := -1.0
		for i in range(a, mini(b, int(PLUG_H))):
			var row: String = PLUG_ART[i]
			var l := row.length() - row.lstrip(".").length()
			var r := row.rstrip(".").length() - 1
			if not best.is_empty() and row[r] != best[1]:
				continue   # outra peça
			var mid := row[(l + r) / 2]
			var knurl := "2323" in row or "3434" in row
			var sc := absf(float(mid) - 3.5) if mid.is_valid_int() else 0.0
			if r - l + 1 < PLUG_ABA_D + 4 and row[r] == "6":   # na capa, um gomo escuro sim, outro não (só os escuros a deixavam preta)
				sc = 1.0 if (mid == "5") == (k % 2 == 1) else 0.0
			if sc > score or (sc == score and knurl):
				best = [r - l + 1, row[r], row[l + 2], mid, row[r - 2], knurl]
				score = sc
		_face_rows[key] = best
	return _face_rows[key]


## Um disco do corpo serrilhado: o disco de `d` px nos tons `tones`, riscado em fatias; enfileirados no plug
## encaixado, os riscos viram as listras ao longo dele, como as do plug em pé. Guardado.
static var _knurls := {}
func _knurled(d: int, tones: Array) -> ImageTexture:
	var key := str(d, tones)
	if not _knurls.has(key):
		var img := disc(d, [[d / 2.0, tones[0], tones[1], tones[2]]]).get_image()
		for y in d:
			for x in d:
				var c := img.get_pixel(x, y)
				if c.a > 0.0 and posmod(floori(Vector2(x + 0.5 - d / 2.0, y + 0.5 - d / 2.0).angle() / TAU * 28.0), 2) == 1:
					img.set_pixel(x, y, c.darkened(0.2))
		_knurls[key] = ImageTexture.create_from_image(img)
	return _knurls[key]


## Por cima do fio, no meio do plug encaixado: a ponteira de onde o fio sai. O fio passa por cima do tampo e chega
## até ela, no centro.
func _draw_plug_cap(e: int) -> void:
	if float(_pushed.get(e, MORPH_SEC)) < MORPH_SEC:
		return   # ainda entrando: o corpo em pé está por cima
	var col: Array = _cable_col(e)
	_sprite(disc(5, [[1.0, col[1]], [2.5, col[0]]]), _plug_base(e).round())   # na cor e na largura do fio, sem contorno: o fio continua nela


## A luz que bate no plug encaixado em `j`, como [cor, nível, de todos os lados]: na entrada, a lâmpada da linha,
## logo acima (acende a beira de cima); no destino, o aro aceso em volta da tomada (a beira toda, mais fraco). A saída
## não tem lâmpada.
func _plug_light(j: int) -> Array:
	if j >= 1 and j <= 10:
		var lt: Array = _lit.get("l%d" % j, [LAMP_OFF, 0.0])
		return [lt[0], lt[1], false]
	if j > 20:
		var dl: Array = _lit.get("d%d" % j, [LAMP_OFF, 0.0])
		return [dl[0], 0.6 * dl[1], true]
	return [LAMP_OFF, 0.0, false]


## O contorno aceso do plug encaixado que sai até `t` em `n` passos: a silhueta dos discos juntos (os mesmos lugares
## de `_sprite`), e dela só os pixels da beira de cima, com o de baixo deles mais fraco, ou a beira toda (`around`).
## Devolve [textura, onde desenhar]. Guardado.
static var _face_rims := {}
func _face_rim(t: Vector2, n: int, around: bool) -> Array:
	var key := [t, around]
	if not _face_rims.has(key):
		var spots := []   # [posição do canto, máscara]
		var lo := Vector2(INF, INF)
		var hi := -lo
		for k in n + 1:
			var d: int = _face_row(n, k)[0]
			var p := (t * float(k) / n - Vector2(d, d) / 2.0).floor()
			spots.append([p, disc(d, [[d / 2.0, Color.WHITE]]).get_image()])
			lo = lo.min(p)
			hi = hi.max(p + Vector2(d, d))
		var size := Vector2i(hi - lo) + Vector2i(2, 2)
		var mask := Image.create(size.x, size.y, false, Image.FORMAT_LA8)
		for sp in spots:
			var src: Image = sp[1]
			var at := Vector2i((sp[0] as Vector2) - lo) + Vector2i.ONE
			for y in src.get_height():
				for x in src.get_width():
					if src.get_pixel(x, y).a > 0.5:
						mask.set_pixel(at.x + x, at.y + y, Color.WHITE)
		var inside := func(x: int, y: int) -> bool:
			return x >= 0 and y >= 0 and x < size.x and y < size.y and mask.get_pixel(x, y).a > 0.5
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		for y in size.y:
			for x in size.x:
				if not inside.call(x, y):
					continue
				if around:
					if not (inside.call(x - 1, y) and inside.call(x + 1, y) and inside.call(x, y - 1) and inside.call(x, y + 1)):
						img.set_pixel(x, y, Color.WHITE)
				elif not inside.call(x, y - 1):
					img.set_pixel(x, y, Color.WHITE)
				elif not inside.call(x, y - 2):
					img.set_pixel(x, y, Color(1, 1, 1, 0.35))
		_face_rims[key] = [ImageTexture.create_from_image(img), lo - Vector2.ONE]
	return _face_rims[key]


## O plug de pé, com o fio saindo de baixo (y = 0), no formato de um P10 e na escala das tomadas (18 × 93 px: o corpo
## enche o buraco da prateleira e a luva de 8 entra no furo de 11 da tomada; os objetos da mesa crescem na mesma
## proporção, `Background.PROP_K`, para o plug não ficar maior que eles), em pixel art (`PLUG_ART`, no acabamento do relógio da mesa: sombreado de cilindro com o brilho
## numa coluna só e a beira escura à direita, cantos arredondados), no jeito de um plugue P10 (a referência do
## usuário): a capa de borracha em gomos, afinando até o fio; o corpo na cor do cabo (é o que identifica o cabo), com
## um anel em cima, o serrilhado em listras finas e um anel no meio; a aba dourada; a ponta de metal dourado, com a luva,
## um isolante preto, o anel, outro isolante e o bico em ponta com a bolinha. `tip`
## falso: sem a ponta (entrando no encaixe, ela já está dentro). Entrando no buraco, só até `_cut`, escurecendo liso.
func _draw_plug_body(col: Array, tip: bool = true) -> void:
	var top := -PLUG_H if tip else -PLUG_LEN
	var bottom := minf(0.0, _cut)
	if bottom > top:
		draw_texture_rect_region(art(PLUG_ART, _plug_pal(col)), Rect2(-10, top, 20, bottom - top), Rect2(0, top + PLUG_H, 20, bottom - top))
	if _cut < INF:   # entrando no buraco, o plug escurece até a beira dele
		var none := Color(0, 0, 0, 0)
		var deep := Color(0, 0, 0, 0.6)
		draw_polygon(PackedVector2Array([Vector2(-10, _cut - 6.0), Vector2(10, _cut - 6.0), Vector2(10, _cut), Vector2(-10, _cut)]),
			PackedColorArray([none, none, deep, deep]))


## As cores do plug do cabo `col` ([cor, brilho]), pelos caracteres de `PLUG_ART`: o cabo de baquelite na cor dele
## (do brilho à beira), o metal dourado e os isolantes, cada um do brilho à beira escura. Guardadas por cabo.
static var _plug_pals := {}
func _plug_pal(col: Array) -> Dictionary:
	var c: Color = col[0]
	if not _plug_pals.has(c):
		var h: Color = col[1]
		_plug_pals[c] = {"1": h.lightened(0.15), "2": h, "3": c, "4": c.darkened(0.25), "5": c.darkened(0.45), "6": c.darkened(EDGE),
			"Y": Color("ecd29a"), "y": Color("e0c07a"), "b": Color("b8924e"), "B": Color("7a5a24"), "C": Color("5a4218"), "E": Color("3a2810"),
			"K": Color("2a2622"), "k": Color("141210")}
	return _plug_pals[c]


## O texto `text` na fonte do painel (`TINY`), em maiúsculas, branco (a cor vem na hora de desenhar): 4 px por letra
## e 10 de altura (os acentos nas linhas 0 e 1, as letras de 3 a 7, a cedilha em 8 e 9). Guardado.
static var _tinies := {}
static func tiny(text: String) -> ImageTexture:
	text = text.to_upper()
	if not _tinies.has(text):
		var img := Image.create(maxi(1, text.length() * 4 - 1), 10, false, Image.FORMAT_LA8)
		for i in text.length():
			var ch: String = TINY_ACCENTS.get(text[i], text[i])
			_tiny_glyph(img, TINY.get(ch[0], ""), i * 4, 3)
			if ch.length() > 1:
				_tiny_glyph(img, TINY_MARKS[ch[1]], i * 4, 8 if ch[1] == "," else 0)
		_tinies[text] = ImageTexture.create_from_image(img)
	return _tinies[text]


static func _tiny_glyph(img: Image, glyph: String, x: int, y: int) -> void:
	var rows := glyph.split("/")
	for r in rows.size():
		for c in rows[r].length():
			if rows[r][c] == "#":
				img.set_pixel(x + c, y + r, Color.WHITE)


## Pixel art de um mapa de texto (`rows`, um caractere por pixel; "." é vazio), nas cores de `pal` (caractere -> cor;
## "*" vale para os que faltam; sem cor, vazio). Guardada.
static var _arts := {}
static func art(rows: Array, pal: Dictionary) -> ImageTexture:
	var key := hash([rows, pal])
	if _arts.has(key):
		return _arts[key]
	var img := Image.create((rows[0] as String).length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in (rows[y] as String).length():
			var ch: String = rows[y][x]
			if ch != "." and (pal.has(ch) or pal.has("*")):
				img.set_pixel(x, y, pal.get(ch, pal.get("*")))
	var tex := ImageTexture.create_from_image(img)
	_arts[key] = tex
	return tex


## Peça redonda em pixel art, pixel a pixel (desenhada como círculo, saía embolotada): `d` pixels de diâmetro;
## `layers` de dentro para fora, [raio em pixels, cor] ou [raio, luz, meio, sombra] (a luz vem de `LIGHT`) ou
## [raio, luz, meio, sombra, true] (côncava: a luz bate do lado oposto, como no fundo de um furo). Guardada. O cenário,
## o painel e o bloom usam também (o mesmo acabamento em toda peça redonda).
static var _discs := {}
static func disc(d: int, layers: Array) -> ImageTexture:
	var key := str(d, layers)
	if _discs.has(key):
		return _discs[key]
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var mid := Vector2(d, d) / 2.0
	for y in d:
		for x in d:
			var o := Vector2(x + 0.5, y + 0.5) - mid
			for l in layers:
				if o.length() <= l[0]:
					var col: Color = l[1]
					if l.size() >= 4:
						var t := o.normalized().dot(LIGHT) if o.length() > 0.01 else 0.0
						if l.size() >= 5 and l[4]:
							t = -t
						col = l[1] if t > 0.38 else (l[3] if t < -0.38 else l[2])
					img.set_pixel(x, y, col)
					break
	var tex := ImageTexture.create_from_image(img)
	_discs[key] = tex
	return tex


## Desenha a peça `tex` centrada em `c`, presa aos pixels.
func _sprite(tex: Texture2D, c: Vector2, mod := Color.WHITE) -> void:
	var sz := Vector2(tex.get_size())
	draw_texture_rect(tex, Rect2((c - sz / 2.0).floor(), sz), false, mod)


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
