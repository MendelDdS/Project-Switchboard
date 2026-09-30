class_name Scrawl
extends Control
## Anotação manuscrita que aparece sozinha no caderno.

var lines: PackedStringArray = ["02:13", "Linha 07", "NÃO ATENDER NOVAMENTE."]
var _jit: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotation = deg_to_rad(-2.5)
	set_lines(lines)


func set_lines(new_lines: PackedStringArray) -> void:
	lines = new_lines
	_jit.clear()
	for l in lines:
		var row: Array = []
		for i in l.length():
			row.append(Vector2(randf_range(-4.0, 4.0), randf_range(-1.5, 1.5)))
		_jit.append(row)
	queue_redraw()


func _draw() -> void:
	var f := Pal.ui
	var sz := 24
	for li in lines.size():
		var x := 0.0
		var y := 26.0 + li * 30.0
		var l: String = lines[li]
		for i in l.length():
			var ch := l[i]
			var j: Vector2 = _jit[li][i]
			draw_set_transform(Vector2(x, y + j.y), deg_to_rad(j.x), Vector2.ONE)
			draw_char(f, Vector2.ZERO, ch, sz, Pal.INK_RED)
			x += f.get_char_size(ch.unicode_at(0), sz).x + 0.5
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
