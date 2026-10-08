extends Control
## A base da mesa comutadora (`Switchboard`): o estado em comum e a geometria (onde fica cada tomada, buraco e
## plug: `jack_rect`, `hole`, `home_pos`; quem está ligado a quem: `mate`, `dest_of_output`, `refuse`). A mesa é
## dividida em camadas por herança: esta, o painel (`switchboard_panel.gd`), os plugs e fios
## (`switchboard_plugs.gd`) e a mesa com a entrada, a física e o desenho (`switchboard.gd`); cada uma só usa as de baixo.

const PATCHES := 3
const FONE_HOLE_X := 50.0   # o buraco do FONE, a partir da esquerda do encaixe (no meio dele)
const SHELF_HOLE_Y := 3.0   # os buracos da prateleira, no alto da faixa dela (o nome fica gravado embaixo)
const PLUG_SINK := 22.0  # guardado, o plug entra tanto no buraco (px abaixo dele: a capa de borracha some nele, o corpo fica à mostra)...

var fone_socket: Control       # encaixe do FONE, na prateleira à frente do painel
var tray: Control              # os buracos dos cabos de conexão, na prateleira à frente do painel
var _slots := {}               # número -> centro da tomada (de todos os setores, atendidos ou não)
var ends: Array = []           # tomada de cada ponta (-1 = na base). 0 = FONE; 1..2*PATCHES = pontas dos cabos de conexão
var held := -1

const PLUG_BASE := Vector2(0, 36)   # do ponto de referência do plug (topo do corpo) até onde o fio entra nele
const PLUG_H := 93.0   # a altura do `PLUG_ART`: do bico até onde sai o fio
const JACK := 22.0          # diâmetro de todos os encaixes (entradas, saídas e destinos)
## A coluna de cada linha, de cima para baixo: plaquinha com o número (topo e altura), estado (linha de base do texto),
## lâmpada, entrada e saída (centros). O estado fica acima da lâmpada: embaixo da entrada, o plug encaixado o cobria.
const ROW_Y := {"plate": 32.0, "plate_h": 17.0, "state": 61.0, "lamp": 76.0, "in": 104.0, "out": 156.0}
const ROOM_LIGHT_R := 900.0   # px: até onde a luz dela chega no painel
const ROOM_LIT := Color(1.0, 0.88, 0.66, 0.07)   # perto dela, o painel clareia quente...
const ROOM_DARK := Color(0.012, 0.022, 0.045, 0.36)   # ...e longe, escurece

var _jacks: Array = []
var _lamp_at := Vector2.ZERO   # onde fica a luminária do teto, medida no começo de cada desenho (`_lamp_pos`)


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


## O tom da luz da sala no ponto p da mesa: a cor e, no alfa, quanto ela pesa.
func _room_tone(p: Vector2) -> Color:
	var k := clampf(1.0 - p.distance_to(_lamp_at) / ROOM_LIGHT_R, 0.0, 1.0)
	return ROOM_DARK.lerp(ROOM_LIT, k * k)
