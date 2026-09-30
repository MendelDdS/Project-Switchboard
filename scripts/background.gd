class_name Background
extends Control
## Parede, janela com chuva, mesa de madeira e luminária — desenhados em 640x360 e ampliados 2x.

const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]

var flick := false
var lamp_level := 1.0
var _drops: Array = []
var _acc := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 60:
		_drops.append(Vector3(randf() * 110.0, randf() * 44.0, 0.6 + randf() * 0.7))


func _process(delta: float) -> void:
	_acc += delta
	if _acc < 1.0 / 30.0:
		return
	_acc = 0.0
	for i in _drops.size():
		var d: Vector3 = _drops[i]
		d.y += d.z
		d.x -= d.z * 0.25
		if d.y > 38.0:
			d.y = -3.0
			d.x = randf() * 104.0 + 10.0
		_drops[i] = d
	if flick:
		lamp_level = FLICK[int(Time.get_ticks_msec() / 90.0) % FLICK.size()]
	else:
		lamp_level = 1.0
	queue_redraw()


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	_r(0, 0, 640, 360, Color("172023"))
	for x in range(0, 640, 22):
		_r(x, 0, 2, 48, Color("141c1f"))
	_r(0, 47, 640, 2, Color("1e282b"))
	_r(0, 49, 640, 311, Color("211811"))
	for y in range(56, 360, 9):
		_r(0, y, 640, 1, Color("1b130d"))
	for i in 40:
		_r((i * 97) % 640, 52 + ((i * 53) % 300), 18 + (i % 5) * 6, 1, Color("2a1f16"))
	# janela
	var wx := 276.0
	var wy := 5.0
	var ww := 104.0
	var wh := 38.0
	_r(wx - 3, wy - 3, ww + 6, wh + 6, Color("2c2a24"))
	_r(wx, wy, ww, wh, Color("0b141c"))
	_r(wx, wy + wh - 8, ww, 8, Color("10202b"))
	for i in 8:
		_r(wx + 4 + i * 13, wy + wh - 6 - (i % 3) * 3, 9, 6 + (i % 3) * 3, Color("0a1016"))
	var lit := [Vector2(wx + 18, wy + 30), Vector2(wx + 71, wy + 31), Vector2(wx + 47, wy + 33)]
	for i in lit.size():
		if flick and i == 1:
			continue
		var p: Vector2 = lit[i]
		_r(p.x, p.y, 2, 2, Color("b38a3c") if i == 2 else Color("d59a3d"))
	for d in _drops:
		if d.x >= 0.0 and d.x < ww:
			_r(wx + floorf(d.x), wy + floorf(d.y), 1, 3, Color("3a5563"))
	_r(wx + ww / 2 - 1, wy, 2, wh, Color("2c2a24"))
	_r(wx, wy + wh / 2 - 1, ww, 2, Color("2c2a24"))
	# luminária
	var lx := 500.0
	_r(lx, 0, 2, 8, Color("111111"))
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 8, 8), Vector2(lx + 10, 8), Vector2(lx + 22, 22), Vector2(lx - 20, 22)]), Color("34422e"))
	_r(lx - 6, 9, 4, 3, Color("50623f"))
	_r(lx - 12, 15, 6, 3, Color("50623f"))
	_r(lx - 12, 22, 26, 3, Color(1.0, (200.0 + 30.0 * lamp_level) / 255.0, 140.0 / 255.0, 0.35 + 0.65 * lamp_level))
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 18, 24), Vector2(lx + 20, 24), Vector2(lx + 120, 90), Vector2(lx - 110, 90)]), Color(1.0, 0.82, 0.55, 0.08 * lamp_level))
