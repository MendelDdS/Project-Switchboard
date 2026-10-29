extends Control
## Os broches ganhos (`Badges`, no `Progress`) espetados numa almofada de feltro deitada na prateleira da mesa
## comutadora, entre o tampo dos equipamentos (`bay_rect`) e o fim dela: quatro atrás e quatro na frente, cada um no
## seu lugar (o que falta deixa o feltro à mostra). Sob o mouse, o broche sobe 1 px e mostra o nome numa etiqueta de
## fita crepe (`TapedLabel`, como os objetos da mesa); o clique abre um papel com a descrição e a noite em que veio
## (um clique em qualquer outro lugar fecha). O mouse que não pega um broche segue para a mesa (`MOUSE_FILTER_PASS`):
## os plugs e os fios por cima continuam na mão.

const Badges := preload("res://scripts/model/badges.gd")
const PIN := 11          ## o diâmetro de cada broche
const STEP := 14.0       ## de um broche ao seguinte na fileira
const PAD_W := 58.0      ## a almofada, na linha do meio da prateleira
const DEPTH := 20        ## da beira de trás à da frente (como os tampos, `Switchboard.COVER_DEPTH`)
const FACE := 2          ## a frente da almofada, na sombra
const NOTE_W := 190.0    ## o papel da descrição
## O desenho de cada broche (7×7, no esmalte do desenho, `Pal.BADGE_ENAMEL`), no meio do fundo.
const ICONS := {
	"primorosas": [".###...", "##.....", "#....#.", "#...###", "#....#.", "##.....", ".###..."],   # a lua e a estrela
	"anjo": ["..###..", "..###..", "#######", "#######", "#######", "..###..", "..###.."],         # a cruz
	"linha_direta": [".......", "#######", "##.#.##", "..###..", ".#####.", ".#####.", "......."],  # o telefone de mesa
	"longa_distancia": ["..###..", ".#.#.#.", "#..#..#", "#######", "#..#..#", ".#.#.#.", "..###.."],   # o globo
	"faro": ["..###..", ".#...#.", ".....#.", "...##..", "...#...", ".......", "...#..."],         # a pergunta
	"contas": [".......", "......#", ".....##", "#...##.", "##.##..", ".###...", "..#...."],       # o visto
	"rush": ["#######", ".#...#.", "..#.#..", "...#...", "..###..", ".#####.", "#######"],         # a ampulheta, a areia já embaixo
	"veterano": ["...#...", "...#...", "#######", ".#####.", "..###..", ".##.##.", ".#...#."],     # a estrela
}

var earned := {}:   ## id -> a noite em que veio (`Progress.badges`)
	set(v):
		earned = v
		_open = ""
		queue_redraw()
var _hover := ""   ## o broche sob o mouse
var _open := ""    ## o broche com o papel da descrição aberto
var _mid := 0.0    ## a linha do meio da prateleira (`Switchboard._shelf_mid`), em px da mesa
var _cx := 0.0     ## o meio da almofada nela
var _drawn := []
var _pop := Control.new()   ## a etiqueta e o papel, por cima dos fios e dos plugs

@onready var _board: Switchboard = get_parent()


func _ready() -> void:
	mouse_exited.connect(func(): _hover = "")
	_pop.mouse_filter = MOUSE_FILTER_IGNORE
	_pop.z_index = 50
	_pop.draw.connect(_draw_pop)
	add_child(_pop)


func _process(_delta: float) -> void:
	var bay := _board.bay_rect()
	var from := bay.get_center().x + (bay.size.x - Switchboard.BAY_MARGIN) / 2.0   # a beira do tampo dos equipamentos
	_mid = _board._shelf_mid()
	_cx = roundf((from + _board.tray_rect().end.x - Switchboard.COVER_GAP) / 2.0)   # (o fim da prateleira à vista fica uns px antes do `tray_rect`)
	var r := Rect2(_cx - PAD_W / 2.0 - DEPTH, roundf(_mid - DEPTH / 2.0) - 4.0, PAD_W + DEPTH * 2.0, DEPTH + FACE + 6.0)
	if r != Rect2(position, size):
		position = r.position
		size = r.size
	if _board.held != -1:   # (com um plug na mão, o mouse é da mesa)
		_hover = ""
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if _hover != "" else _board.mouse_default_cursor_shape
	_show()


## Redesenha só quando o que é mostrado muda.
func _show() -> void:
	var look := [_hover, _open, earned.size(), position, _board._eye]   # (os olhos dão a inclinação, `_slant`)
	if look != _drawn:
		_drawn = look
		queue_redraw()
		_pop.queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_hover = ""
		for id: String in earned:
			if _board.held == -1 and (e.position + position).distance_to(_spot(id)) <= PIN / 2.0 + 1.0:
				_hover = id
		return
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or _hover == "":
		return
	if not b.pressed:
		_open = "" if _open == _hover else _hover
		if _open != "":
			Sfx.play_at("click", global_position.x / get_viewport().get_visible_rect().size.x, -6.0)
	accept_event()


## Um clique em qualquer outro lugar fecha o papel (e segue para onde foi).
func _input(e: InputEvent) -> void:
	var b := e as InputEventMouseButton
	if _open != "" and b != null and b.pressed and _hover != _open:
		_open = ""


## Quanto a almofada anda para o lado na linha `y`: paralela à lateral da mesa, como a beira direita do tampo dos
## equipamentos ao lado (`_draw_cover` com `side`; na inclinação dos plugs, `_lean`, pendia mais que a prateleira ali).
func _slant(y: float) -> float:
	var end := _board.tray_rect().end.x
	return _board._receding(Vector2(end, _mid), y) - end


## As beiras da almofada na linha `y` (px da mesa), sem arredondar: a da esquerda e a da direita.
func edges(y: float) -> Vector2:
	var dx := _slant(minf(y, roundf(_mid - DEPTH / 2.0) + DEPTH - 1))   # (a frente fica em pé: não deita mais)
	return Vector2(_cx - PAD_W / 2.0 + dx, _cx + PAD_W / 2.0 + dx)


## O meio do broche `id` (px da mesa), deitado na almofada como ela.
func _spot(id: String) -> Vector2:
	var i := Badges.ALL.keys().find(id)
	var y := roundf(_mid - DEPTH / 2.0) + (3.0 if i < 4 else 14.0)
	return Vector2(roundf(_cx + (i % 4 - 1.5) * STEP + _slant(y)), y)


## A almofada, linha a linha na inclinação da prateleira ali (`_slant`), com a beira de trás na
## luz e a frente em pé, na sombra; os broches em cima, cada um com a sombra no feltro.
func _draw() -> void:
	draw_set_transform(-position)
	var y0 := roundf(_mid - DEPTH / 2.0)
	for v in DEPTH + FACE:
		var y := y0 + v
		var e := edges(y).round()
		draw_rect(Rect2(e.x, y, e.y - e.x, 1), Pal.BADGE_FELT[2 if v == 0 else (0 if v >= DEPTH else 1)])
	for id: String in earned:
		var c := _spot(id)
		draw_texture(PixelArt.disc(PIN, [[5.5, Color(0, 0, 0, 0.4)]]), c - Vector2(4, 4))
		var at := c - Vector2(5, 6 if id == _hover else 5)
		var e: Array = Pal.BADGE_ENAMEL[id]
		var b := Pal.BRASS_PLATE
		draw_texture(Switchboard._disc(PIN, [[4.6, e[0].lightened(0.12), e[0], e[0].darkened(0.25)], [5.5, b[6], b[4], b[2]]]), at)
		draw_texture(PixelArt.art(ICONS[id], {"#": e[1]}), at + Vector2(2, 2))


func _draw_pop() -> void:
	_pop.draw_set_transform(-position)
	if _open != "":
		_draw_note(_open)
	elif _hover != "":
		_draw_tip(T.text(Badges.ALL[_hover][0]), _spot(_hover))


## O nome, numa etiqueta de fita crepe acima da almofada (como `Background.draw_hover`).
func _draw_tip(cap: String, p: Vector2) -> void:
	var tape := get_theme_stylebox("normal", "TapedLabel")
	var ts := (Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11) + tape.get_minimum_size()).round()
	var at := Vector2(minf(roundf(p.x - ts.x / 2.0), _board.size.x - ts.x - 2.0), roundf(_mid - DEPTH / 2.0) - ts.y - 6.0)
	tape.draw(_pop.get_canvas_item(), Rect2(at, ts))
	_pop.draw_string(Pal.ui, at + Vector2(tape.content_margin_left, tape.content_margin_top + Pal.ui.get_ascent(11)), cap,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, get_theme_color("default_color", "TapedLabel"))


## O papel com fita (`TapedNote`) acima da almofada: o nome em negrito, a descrição e a noite em que o broche veio.
func _draw_note(id: String) -> void:
	var paper := get_theme_stylebox("panel", "TapedNote")
	var ink := get_theme_color("font_color", "InkLabel")
	var title := T.text(Badges.ALL[id][0])
	var body := T.text(Badges.ALL[id][1])
	var w := NOTE_W - paper.get_minimum_size().x
	var line := Pal.ui.get_height(11)
	var bh := Pal.ui.get_multiline_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, w, 11).y
	var sz := Vector2(NOTE_W, paper.get_minimum_size().y + line * 2.0 + bh + 6.0).round()
	var at := Vector2(minf(_spot(id).x - sz.x / 2.0, _board.size.x - sz.x - 2.0), roundf(_mid - DEPTH / 2.0) - sz.y - 6.0).round()
	paper.draw(_pop.get_canvas_item(), Rect2(at, sz))
	var o := at + Vector2(paper.content_margin_left, paper.content_margin_top + Pal.ui.get_ascent(11))
	for dx in 2:   # (o negrito: a sombra de 1 px ao lado, como o `InkBoldLabel`)
		_pop.draw_string(Pal.ui, o + Vector2(dx, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
	_pop.draw_multiline_string(Pal.ui, o + Vector2(0, line + 3.0), body, HORIZONTAL_ALIGNMENT_LEFT, w, 11, -1, ink)
	_pop.draw_string(Pal.ui, o + Vector2(0, line + bh + 6.0), T.text(T.Key.BADGE_EARNED) % earned[id], HORIZONTAL_ALIGNMENT_LEFT,
		-1, 11, Color(ink, 0.7))
