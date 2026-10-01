class_name PhoneBook
extends Control
## Lista telefônica em páginas duplas. Clique num contato para marcá-lo com o dedo.
## Os contatos vêm de GameData.CONTENT.directory; a barra de navegação fica na cena (phone_book.tscn).

const PER := 6
const BOOK := Rect2(0, 0, 576, 406)

var pages: Array = []
var spread := 0
var marked := -1
var hover := -1
var _hits: Array = []

@onready var _prev: Button = %Prev
@onready var _next: Button = %Next
@onready var _letters: HFlowContainer = %Letters


func _ready() -> void:
	var d := GameData.CONTENT.directory
	for i in range(0, d.size(), PER):
		pages.append(d.slice(i, i + PER))
	if pages.size() % 2 == 1:
		pages.append(null)
	_prev.pressed.connect(turn.bind(-1))
	_next.pressed.connect(turn.bind(1))
	var letters: Array = []
	for e in d:
		var l := e.name.substr(0, 1)
		if not l in letters:
			letters.append(l)
	for l in letters:
		var b := Button.new()
		b.text = l
		b.theme_type_variation = &"LetterButton"
		b.custom_minimum_size = Vector2(22, 20)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(jump.bind(l))
		_letters.add_child(b)
	_update_nav()


func turn(dir: int) -> void:
	var ns := clampi(spread + dir, 0, pages.size() / 2 - 1)
	if ns != spread:
		spread = ns
		Sfx.play("page")
		_update_nav()
		queue_redraw()


func jump(letter: String) -> void:
	var d := GameData.CONTENT.directory
	for i in d.size():
		if d[i].name.begins_with(letter):
			var sp := int(i / PER) / 2
			if sp != spread:
				spread = sp
				Sfx.play("page")
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
			Sfx.play("click")
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
			draw_string(mono, Vector2(x0, 26), T.text(T.Key.BOOK_NOTES), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Pal.INK_SOFT)
			draw_string(mono, Vector2(x0, 26), str(pi + 1), HORIZONTAL_ALIGNMENT_RIGHT, wdt, 18, Pal.INK_SOFT)
			draw_rect(Rect2(x0, 31, wdt, 2), Pal.INK_SOFT)
			var note := T.text(T.Key.BOOK_NOTE_TEXT)
			draw_multiline_string(Pal.ui, Vector2(x0, 58), note, HORIZONTAL_ALIGNMENT_LEFT, wdt, 14, -1, Pal.INK_SOFT)
			continue
		var first: String = pg[0].name.substr(0, 1)
		var last: String = pg[pg.size() - 1].name.substr(0, 1)
		draw_string(mono, Vector2(x0, 26), first + ("–" + last if first != last else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Pal.INK_SOFT)
		draw_string(mono, Vector2(x0, 26), str(pi + 1), HORIZONTAL_ALIGNMENT_RIGHT, wdt, 18, Pal.INK_SOFT)
		draw_rect(Rect2(x0, 31, wdt, 2), Pal.INK_SOFT)
		var ey := 40.0
		for e in pg:
			var idx := GameData.CONTENT.directory.find(e)
			var name_s: String = e.name
			var sub: String = tr(e.note) if e.note != "" else ""
			var addr: String = (sub + " · " if sub != "" else "") + e.address
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
			draw_string(mono, Vector2(x0, ey + 4 + mono.get_ascent(23)), e.number, HORIZONTAL_ALIGNMENT_RIGHT, wdt, 23, Color.BLACK)
			draw_multiline_string(mono, Vector2(x0, ey + 6 + nh + mono.get_ascent(17)), addr, HORIZONTAL_ALIGNMENT_LEFT, wdt, 17, -1, Pal.INK_SOFT)
			var dy := ey + eh - 1
			var dx := x0 - 4
			while dx < x0 + wdt + 4:
				draw_rect(Rect2(dx, dy, 2, 1), Pal.PAPER_LINE)
				dx += 4
			ey += eh
