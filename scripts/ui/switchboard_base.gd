extends Control
## A base da mesa comutadora (`Switchboard`): o estado em comum e a geometria (onde fica cada tomada, buraco e
## plug: `jack_rect`, `hole`, `home_pos`; quem está ligado a quem: `mate`, `dest_of_output`, `refuse`). A mesa é
## dividida em camadas por herança: esta, o painel (`switchboard_panel.gd`), os plugs e fios
## (`switchboard_plugs.gd`) e a mesa com a entrada, a física e o desenho (`switchboard.gd`); cada uma só usa as de baixo.

const SIZE := Vector2(492, 304)   # era 588 × 362: com as tomadas na medida dos plugs, tudo ficava espaçado e a mesa tomava a sala
const SHELF_SLOTS := 5   # lugares de cabo na prateleira: um por setor ainda não atendido fica tampado, à espera do cabo novo (`patches`)
const TRUNK_GAP := 8.0      # do último plug guardado até o bloco interurbano (o vão da moldura dos bancos)
const PAIR_SHIFT := 16.0    # a ponta da frente de um cabo, à esquerda da de trás: encostadas, as duas se leem como um par
const FONE_HOLE_X := 40.0   # o buraco do FONE, a partir da esquerda do encaixe (o nome gravado embaixo cabe nos três idiomas)
const SHELF_HOLE_Y := 10.0  # a fileira de trás dos buracos da prateleira (o FONE e a primeira ponta de cada cabo), afastada do rodapé do painel
const SHELF_FRONT_Y := 29.0 # a fileira da frente (a outra ponta), à frente da de trás, como nas mesas de verdade; o mesmo vão entre as fileiras e até as beiras
const PLUG_SINK := 14.0  # guardado, o plug entra tanto no buraco (px abaixo dele: a capa de borracha some nele, o corpo fica à mostra)...

var exchange: Exchange
var fone_socket: Control       # encaixe do FONE, na prateleira à frente do painel
var tray: Control              # os buracos dos cabos de conexão, na prateleira à frente do painel
var _slots := {}               # número -> centro da tomada (de todos os setores, atendidos ou não)
var ends: Array = []           # tomada de cada ponta (-1 = na base). 0 = FONE; 1..2*patches = pontas dos cabos de conexão
var patches := 3               # cabos de conexão em uso: cada setor entregue ao operador traz um par (a mesa conta ao montar)
var held := -1
## Os olhos do operador, o ponto de fuga da sala, em px da mesa (medido a cada quadro pela mesa; sem cenário, nos
## testes, onde eles ficam em 1280 × 720): os plugs encaixados apontam para ele e a prateleira foge para ele.
const PLUG_EYE := Vector2(SIZE.x + 176, 108)
var _eye := PLUG_EYE
var trunks := Rect2()   # o bloco interurbano no painel (a mesa o põe ao montar os bancos): os cabos vão até ele

const PLUG_BASE := Vector2(0, 26)   # de onde a mão pega o plug (o meio do corpo) até onde o fio entra nele
const PLUG_H := 66.0   # a altura do `PLUG_ART`: do bico até onde sai o fio...
const PLUG_W := 16.0   # ...e a largura dele (o corpo tem 14)
const JACK := 16.0          # o lugar de cada encaixe (entradas, saídas e destinos; o desenho, `JACK_PX`, é menor)
## A coluna de cada linha, de cima para baixo: plaquinha com o número (topo e altura), estado (linha de base do texto),
## lâmpada, entrada, chave de escuta e saída (centros). O estado fica acima da lâmpada: embaixo da entrada, o plug
## encaixado o cobria.
const ROW_Y := {"plate": 30.0, "plate_h": 15.0, "state": 57.0, "lamp": 68.0, "in": 90.0, "key": 111.0, "out": 132.0}
const ROOM_LIGHT_R := 900.0   # px: até onde a luz dela chega no painel
const ROOM_LIT := Color(1.0, 0.88, 0.66, 0.07)   # perto dela, o painel clareia quente...
const ROOM_DARK := Color(0.012, 0.022, 0.045, 0.36)   # ...e longe, escurece

var _jacks: Array = []
var _lamp_at := Vector2.ZERO   # onde fica a luminária do teto, medida a cada quadro (`_lamp_pos`)
var _ci: CanvasItem   # onde as funções de desenho desenham: a mesa, ou uma das camadas por cima dela (`_layers`)


## Encaixe do FONE em coordenadas da mesa (na prateleira à frente do painel, fora do retângulo dela).
func socket_rect() -> Rect2:
	if fone_socket == null:
		return Rect2(0, SIZE.y + 8.0, 58, 32)
	return Rect2(fone_socket.global_position - global_position, fone_socket.size)


## A faixa dos buracos dos cabos na prateleira, em coordenadas da mesa (também fora do retângulo dela).
func tray_rect() -> Rect2:
	if tray == null:
		return Rect2(70, SIZE.y + 8.0, SIZE.x - 70.0, 32)
	return Rect2(tray.global_position - global_position, tray.size)


# Tomadas: 1–10 entradas, 11–20 saídas (linha + 10), destinos pelo próprio número (101–399).
func col_x(i: int) -> float:
	return 48.0 + i * 44.0   # 44: o estado mais longo ("ON THE LINE", 43 px na fonte gravada) cabe ao lado do vizinho


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


## A chave de escuta da coluna `i`, entre a entrada e a saída (a alavanca para cima ou para baixo).
func lever_rect(i: int) -> Rect2:
	return Rect2(col_x(i) - 6, ROW_Y["key"] - 13, 12, 26)


## A alavanca da linha `n` levantada: a chave de escuta, ou o destino tocando (o operador ouve chamar; quando atendem,
## ela desce sozinha).
func lever_up(n: int) -> bool:
	var d := dest_of_output(n)
	return exchange.key(n) or d != -1 and exchange.dest(d) == Exchange.Dest.RING


func top_rect(i: int) -> Rect2:
	return Rect2(col_x(i) - 20, ROW_Y["plate"] - 2, 40, ROW_Y["lamp"] - ROW_Y["plate"] + 8)


## A coluna do cabo de conexão k na prateleira, na fileira de trás. As duas pontas de cada cabo ficam juntas (a da
## frente encostada, `front_of`) e os `SHELF_SLOTS` lugares, a um passo igual, enchem a prateleira até o bloco
## interurbano.
func patch_x(k: int) -> float:
	return socket_rect().position.x + FONE_HOLE_X + _pitch() * (k + 1)


## De um lugar de cabo ao seguinte.
func _pitch() -> float:
	var right := (trunks.position.x if trunks.has_area() else tray_rect().end.x) - TRUNK_GAP - PLUG_W / 2.0 - 2.0   # a metade do plug guardado (`home_rect`)
	return (right - socket_rect().position.x - FONE_HOLE_X) / SHELF_SLOTS


## Onde fica o plug guardado, de pé no buraco dele na prateleira, como nas mesas de verdade (o fio desce por ele).
func home_pos(e: int) -> Vector2:
	return hole(e) - PLUG_BASE + Vector2(0, PLUG_SINK)


## Buraco de onde sai o fio da ponta e, na prateleira (o do FONE no encaixe dele; os de conexão um atrás do outro).
func hole(e: int) -> Vector2:
	if e == 0:
		return socket_rect().position + Vector2(FONE_HOLE_X, SHELF_HOLE_Y)
	var back := Vector2(patch_x((e - 1) / 2), tray_rect().position.y + SHELF_HOLE_Y)
	return back if e % 2 == 1 else front_of(back)


## O lugar da fileira da frente ao lado do buraco de trás `p` (a outra ponta do mesmo cabo): `PAIR_SHIFT` à esquerda,
## sempre o mesmo (pela perspectiva exata seriam 20 a 32 px, um a cada coluna, e o desencontro parecia bagunça).
func front_of(p: Vector2) -> Vector2:
	return p + Vector2(-PAIR_SHIFT, SHELF_FRONT_Y - SHELF_HOLE_Y)


func home_rect(e: int) -> Rect2:
	var h := home_pos(e)
	return Rect2(h.x - PLUG_W / 2.0 - 2.0, h.y + PLUG_BASE.y - PLUG_H, PLUG_W + 4.0, PLUG_H - 2.0)   # do bico até a beira do buraco


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
	for k in patches:
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


## O tom da luz da sala no ponto p da mesa: a cor e, no alfa, quanto ela pesa.
func _room_tone(p: Vector2) -> Color:
	var k := clampf(1.0 - p.distance_to(_lamp_at) / ROOM_LIGHT_R, 0.0, 1.0)
	return ROOM_DARK.lerp(ROOM_LIT, k * k)
