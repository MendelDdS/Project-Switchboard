extends Control
## O discador da mesa, deitado na prateleira da mesa comutadora, à direita da almofada dos broches, no meio do vão até o
## fim dela (`Switchboard.dialer_x`): uma caixinha de plástico creme, como o móvel, com a placa oliva rebaixada em cima e, nela, o visor escuro
## (o número digitado em verde, `PixelArt.tiny`) e, embaixo dele, a lâmpada de linha (âmbar piscando chamando, verde em conversa,
## vermelha nos avisos, como as do painel); à direita, o teclado de 3 × 4 teclas ciano, Discar verde e Encerrar vermelha nos
## cantos de baixo (`Dialing`). Linha a linha, na inclinação da prateleira ali (como a almofada, `_slant`), com a
## frente em pé, na sombra. Sob o mouse, sobe 1 px e mostra o nome numa etiqueta de fita crepe; o clique abre o
## discador de perto (`clicked`, a ferramenta `Tools.DIALER`). O mouse que não é dele segue para a mesa
## (`MOUSE_FILTER_PASS`): os plugs e os fios por cima continuam na mão.

signal clicked

const Dialing := preload("res://scripts/dialing.gd")
const DialView := preload("res://scripts/ui/dial_view.gd")
const DEPTH := 22   ## da beira de trás à da frente, deitado
const FACE := 3     ## a frente, em pé
const KEY := Vector2i(10, 4)   ## cada tecla, deitada (largura e fundura: o tampo na luz, o meio e a frente)...
const KEY_GAP := Vector2i(2, 1)   ## ...e o vão entre elas
const KEYS_AT := Vector2i(25, 2)   ## o canto de trás à esquerda do teclado, na tampa: à direita, na fundura toda
const SCREEN := Rect2i(3, 3, 19, 8)   ## o visor, na tampa, à esquerda do teclado...
const LAMP_AT := Vector2i(11, 14)   ## ...e embaixo dele, a lâmpada de linha (3 × 3), com o aro em volta
const BLINK := 0.5   ## s: a lâmpada acesa, depois apagada, chamando (como no de perto, `DialView.BLINK`)

var dialing: Dialing   ## o Main liga
var _hover := false
var _mid := 0.0   ## a linha do meio da prateleira (px da mesa)
var _cx := 0.0    ## o meio do discador nela
var _drawn := []
var _pop := Control.new()   ## a etiqueta, por cima dos fios e dos plugs

@onready var _board: Switchboard = get_parent()


func _ready() -> void:
	mouse_exited.connect(func(): _hover = false)
	_pop.mouse_filter = MOUSE_FILTER_IGNORE
	_pop.z_index = 50
	_pop.draw.connect(_draw_pop)
	add_child(_pop)


func _process(_delta: float) -> void:
	_mid = _board._shelf_mid()
	_cx = _board.dialer_x()
	var r := Rect2(_cx - Switchboard.DIALER_W / 2.0 - 8.0, roundf(_mid - DEPTH / 2.0) - 3.0, Switchboard.DIALER_W + 16.0, DEPTH + FACE + 5.0)
	if r != Rect2(position, size):
		position = r.position
		size = r.size
	if _board.held != -1:   # (com um plug na mão, o mouse é da mesa)
		_hover = false
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if _hover else _board.mouse_default_cursor_shape
	var look := [_hover, position, _board._eye, _lamp(), dialing.digits if dialing else ""]
	if look != _drawn:
		_drawn = look
		queue_redraw()
		_pop.queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_hover = _board.held == -1 and _inside(e.position + position)
		return
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or not _hover:
		return
	if not b.pressed:
		clicked.emit()
	accept_event()


## Quanto o discador anda para o lado na linha `y`: paralelo à lateral da mesa, como a almofada (`badges.gd`).
func _slant(y: float) -> float:
	var end := _board.tray_rect().end.x
	return _board._receding(Vector2(end, _mid), y) - end


## A beira esquerda do discador na linha `y` (px da mesa); a frente fica em pé e não deita mais.
func _left(y: float) -> float:
	return roundf(_cx - Switchboard.DIALER_W / 2.0 + _slant(minf(y, roundf(_mid - DEPTH / 2.0) + DEPTH - 1)))


func _inside(p: Vector2) -> bool:
	var y0 := roundf(_mid - DEPTH / 2.0) - (1.0 if _hover else 0.0)
	return p.y >= y0 and p.y < y0 + DEPTH + FACE and p.x >= _left(p.y) and p.x < _left(p.y) + Switchboard.DIALER_W


## A cor da lâmpada de linha agora, com a piscada (transparente: apagada).
func _lamp() -> Color:
	if dialing == null:
		return Color.TRANSPARENT
	match dialing.status:
		Dialing.Status.CALLING:
			return Pal.AMBER if fmod(dialing.main.talk_clock - dialing.since, BLINK * 2.0) < BLINK else Color.TRANSPARENT
		Dialing.Status.TALK:
			return Pal.GREEN
		Dialing.Status.IDLE, Dialing.Status.ENDED:
			return Color.TRANSPARENT
	return Pal.RED if dialing.main.talk_clock - dialing.since < DialView.FAIL_SEC else Color.TRANSPARENT


## Um retângulo `r` no plano da tampa (x ao longo do discador, y da beira de trás para a frente), cada linha no lugar
## dela na prateleira.
func _flat(r: Rect2i, col: Color) -> void:
	var y0 := roundf(_mid - DEPTH / 2.0) - (1.0 if _hover else 0.0)
	for v in range(r.position.y, r.end.y):
		var y := y0 + v
		draw_rect(Rect2(_left(y + (1.0 if _hover else 0.0)) + r.position.x, y, r.size.x, 1), col)


func _draw() -> void:
	draw_set_transform(-position)
	var w := int(Switchboard.DIALER_W)
	var s := Pal.SHELL
	# a sombra na prateleira, a caixa (a tampa e a frente em pé) com as quinas quebradas
	var y0 := roundf(_mid - DEPTH / 2.0)
	draw_rect(Rect2(_left(y0 + DEPTH) + 1.0, y0 + DEPTH + FACE, w, 1), Color(0, 0, 0, 0.3))
	_flat(Rect2i(1, 0, w - 2, 1), s[7])
	_flat(Rect2i(0, 1, w, DEPTH - 1), s[6])
	_flat(Rect2i(0, 1, 1, DEPTH - 1), s[7])   # a beira da esquerda na luz, a da direita na sombra
	_flat(Rect2i(w - 1, 1, 1, DEPTH - 1), s[4])
	_flat(Rect2i(0, DEPTH, w, FACE - 1), s[3])
	_flat(Rect2i(1, DEPTH + FACE - 1, w - 2, 1), s[2])
	# a placa oliva rebaixada, com a beira de trás na sombra
	_flat(Rect2i(2, 1, w - 4, DEPTH - 2), Pal.BOARD_FACE)
	_flat(Rect2i(2, 1, w - 4, 1), Pal.BOARD_INSET)
	# o visor, com o número digitado em verde
	_flat(SCREEN, Pal.BOARD_INSET)
	if dialing != null and dialing.digits != "":   # no meio do visor (as letras do `tiny` ficam nas linhas 3 a 7 da imagem)
		var mid := y0 - (1.0 if _hover else 0.0) + SCREEN.get_center().y
		draw_texture(PixelArt.tiny(dialing.digits), Vector2(_left(mid + (1.0 if _hover else 0.0)) + SCREEN.position.x + 4, roundf(mid) - 5.0), Pal.GREEN)
	# a lâmpada, no aro creme
	_flat(Rect2i(LAMP_AT - Vector2i.ONE, Vector2i(5, 5)), s[4])
	var lamp := _lamp()
	_flat(Rect2i(LAMP_AT, Vector2i(3, 3)), Pal.LAMP_GLASS if lamp.a == 0.0 else lamp)
	# o teclado: as teclas com o tampo na luz e a frente na sombra; Discar e Encerrar nos cantos de baixo
	for i in 12:
		var k := KEYS_AT + Vector2i(i % 3, i / 3) * (KEY + KEY_GAP)
		var cap: Array = Pal.CALL_CAP if i == 9 else Pal.REC_CAP if i == 11 else Pal.KEY_CAP
		_flat(Rect2i(k, Vector2i(KEY.x, 1)), cap[3])
		_flat(Rect2i(k + Vector2i(0, 1), Vector2i(KEY.x, KEY.y - 2)), cap[2])
		_flat(Rect2i(k + Vector2i(0, KEY.y - 1), Vector2i(KEY.x, 1)), cap[1])


func _draw_pop() -> void:
	if not _hover:
		return
	_pop.draw_set_transform(-position)
	var cap := T.text(T.Key.DIAL_TITLE)
	var tape := get_theme_stylebox("normal", "TapedLabel")
	var ts := (Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11) + tape.get_minimum_size()).round()
	var at := Vector2(minf(roundf(_cx - ts.x / 2.0), _board.size.x - ts.x - 2.0), roundf(_mid - DEPTH / 2.0) - ts.y - 6.0)
	tape.draw(_pop.get_canvas_item(), Rect2(at, ts))
	_pop.draw_string(Pal.ui, at + Vector2(tape.content_margin_left, tape.content_margin_top + Pal.ui.get_ascent(11)), cap,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, get_theme_color("default_color", "TapedLabel"))

