class_name PhoneBook
extends Control
## Lista telefônica em páginas duplas. Clique num contato para marcá-lo com o dedo.

const PER := 6
const BOOK := Rect2(0, 0, 576, 430)

var sfx: Sfx
var pages: Array = []
var spread := 0
var marked := -1
var hover := -1
var _hits: Array = []
var _prev: Button
var _next: Button


func _ready() -> void:
	var d := GameData.DIR
	for i in range(0, d.size(), PER):
		pages.append(d.slice(i, i + PER))
	if pages.size() % 2 == 1:
		pages.append(null)
	_prev = _nav_button("◀ Voltar", Vector2(0, 444))
	_next = _nav_button("Virar ▶", Vector2(480, 444))
	_prev.pressed.connect(func(): turn(-1))
	_next.pressed.connect(func(): turn(1))
	var flow := HFlowContainer.new()
	flow.position = Vector2(104, 440)
	flow.size = Vector2(368, 46)
	flow.add_theme_constant_override("h_separation", 3)
	flow.add_theme_constant_override("v_separation", 3)
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	add_child(flow)
	var letters: Array = []
	for e in d:
		var l: String = String(e["n"]).substr(0, 1)
		if not l in letters:
			letters.append(l)
	for l in letters:
		var b := Button.new()
		b.text = l
		b.custom_minimum_size = Vector2(22, 20)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", Pal.mono)
		b.add_theme_font_size_override("font_size", 18)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Pal.INK_SOFT
		sb.set_border_width_all(1)
		var sbh := sb.duplicate()
		sbh.bg_color = Color(0, 0, 0, 0.1)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sbh)
		b.add_theme_stylebox_override("pressed", sbh)
		b.add_theme_color_override("font_color", Pal.INK)
		b.add_theme_color_override("font_hover_color", Pal.INK)
		b.add_theme_color_override("font_pressed_color", Pal.INK)
		var letter: String = l
		b.pressed.connect(func(): jump(letter))
		flow.add_child(b)
	_update_nav()


func _nav_button(t: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = Vector2(96, 34)
	b.focus_mode = Control.FOCUS_NONE
	add_child(b)
	return b


func turn(dir: int) -> void:
	var ns := clampi(spread + dir, 0, pages.size() / 2 - 1)
	if ns != spread:
		spread = ns
		sfx.play("page")
		_update_nav()
		queue_redraw()


func jump(letter: String) -> void:
	for i in GameData.DIR.size():
		if String(GameData.DIR[i]["n"]).begins_with(letter):
			var sp := int(i / PER) / 2
			if sp != spread:
				spread = sp
				sfx.play("page")
				_update_nav()
				queue_redraw()
			return


func _update_nav() -> void:
	_prev.disabled = spread == 0
	_next.disabled = spread >= pages.size() / 2 - 1


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h := _hit(e.position)
		if h != hover:
			hover = h
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var h := _hit(e.position)
		if h >= 0:
			marked = -1 if marked == h else h
			sfx.play("click")
			queue_redraw()


func _hit(pos: Vector2) -> int:
	for hit in _hits:
		if (hit[0] as Rect2).has_point(pos):
			return int(hit[1])
	return -1


func _draw() -> void:
	_hits.clear()
	draw_rect(BOOK, Pal.INK_SOFT)
	draw_rect(BOOK.grow(-2), Color("e3d6b2"))
	var y := 6.0
	while y < BOOK.size.y - 4:
		draw_rect(Rect2(287, y, 2, 5), Pal.PAPER_LINE)
		y += 9
	var mono := Pal.mono
	for k in 2:
		var pi := spread * 2 + k
		var x0 := 14.0 + k * 288.0
		var wdt := 260.0
		var pg = pages[pi] if pi < pages.size() else null
		if pg == null:
			draw_string(mono, Vector2(x0, 26), "Anotações", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Pal.INK_SOFT)
			draw_string(mono, Vector2(x0, 26), str(pi + 1), HORIZONTAL_ALIGNMENT_RIGHT, wdt, 18, Pal.INK_SOFT)
			draw_rect(Rect2(x0, 31, wdt, 2), Pal.INK_SOFT)
			var note := "Emergências não se transferem: marque o local no mapa e use o despacho.\n\nFarmácia de plantão nesta semana: Santa Rita.\n\nLinhas 01 a 10 são da mesa 1."
			draw_multiline_string(Pal.ui, Vector2(x0, 58), note, HORIZONTAL_ALIGNMENT_LEFT, wdt, 14, -1, Pal.INK_SOFT)
			continue
		var first: String = String(pg[0]["n"]).substr(0, 1)
		var last: String = String(pg[pg.size() - 1]["n"]).substr(0, 1)
		draw_string(mono, Vector2(x0, 26), first + ("–" + last if first != last else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Pal.INK_SOFT)
		draw_string(mono, Vector2(x0, 26), str(pi + 1), HORIZONTAL_ALIGNMENT_RIGHT, wdt, 18, Pal.INK_SOFT)
		draw_rect(Rect2(x0, 31, wdt, 2), Pal.INK_SOFT)
		var ey := 40.0
		for e in pg:
			var idx := GameData.DIR.find(e)
			var name_s: String = e["n"]
			var sub: String = e["s"]
			var addr: String = (sub + " · " if sub != "" else "") + String(e["a"])
			var nh := mono.get_multiline_string_size(name_s, HORIZONTAL_ALIGNMENT_LEFT, 200, 21).y
			var ah := mono.get_multiline_string_size(addr, HORIZONTAL_ALIGNMENT_LEFT, wdt, 17).y
			var eh := nh + ah + 12
			var r := Rect2(x0 - 6, ey, wdt + 12, eh)
			_hits.append([r, idx])
			if idx == marked:
				draw_rect(r, Color(Pal.AMBER, 0.38))
			elif idx == hover:
				draw_rect(r, Color(Pal.AMBER, 0.16))
			draw_multiline_string(mono, Vector2(x0, ey + 4 + mono.get_ascent(21)), name_s, HORIZONTAL_ALIGNMENT_LEFT, 200, 21, -1, Color.BLACK)
			draw_string(mono, Vector2(x0, ey + 4 + mono.get_ascent(23)), String(e["num"]), HORIZONTAL_ALIGNMENT_RIGHT, wdt, 23, Color.BLACK)
			draw_multiline_string(mono, Vector2(x0, ey + 6 + nh + mono.get_ascent(17)), addr, HORIZONTAL_ALIGNMENT_LEFT, wdt, 17, -1, Pal.INK_SOFT)
			var dy := ey + eh - 1
			var dx := x0 - 4
			while dx < x0 + wdt + 4:
				draw_rect(Rect2(dx, dy, 2, 1), Pal.PAPER_LINE)
				dx += 4
			ey += eh
