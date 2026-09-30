class_name Background
extends Control
## Parede, janela (com o clima da noite), mesa de madeira e luminária — desenhados em 640x360 e ampliados 2x.
## `weather`: "rain" (gotas no vidro), "fog" (névoa passando, luzes difusas) ou "clear" (estrelas e lua).
## `shadow`: a silhueta de alguém parado do lado de fora da janela (antes da ligação desconhecida).

const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]

var flick := false
var lamp_level := 1.0
var weather := "rain"
var shadow := false
var _drops: Array = []
var _stars: Array[Vector2] = []
var _mist := 0.0
var _acc := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 60:
		_drops.append(Vector3(randf() * 110.0, randf() * 44.0, 0.6 + randf() * 0.7))
	for i in 18:
		_stars.append(Vector2(randf() * 100.0 + 2.0, randf() * 22.0 + 2.0))


func _process(delta: float) -> void:
	_acc += delta
	if _acc < 1.0 / 30.0:
		return
	_acc = 0.0
	_mist += 0.12
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
	var fog := weather == "fog"
	_r(wx, wy, ww, wh, Color("1b252b") if fog else (Color("0a1422") if weather == "clear" else Color("0b141c")))
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			var on := sin(tw + i * 1.7) > -0.6
			_r(wx + floorf(s.x), wy + floorf(s.y), 1, 1, Color("c9d2dc") if on else Color("56606c"))
		draw_circle(Vector2(wx + 84, wy + 9), 4.0, Color("d8d0a8"))
		draw_circle(Vector2(wx + 86, wy + 8), 3.6, Color("0a1422"))
	_r(wx, wy + wh - 8, ww, 8, Color("1a252b") if fog else Color("10202b"))
	for i in 8:
		_r(wx + 4 + i * 13, wy + wh - 6 - (i % 3) * 3, 9, 6 + (i % 3) * 3, Color("18222a") if fog else Color("0a1016"))
	var lit := [Vector2(wx + 18, wy + 30), Vector2(wx + 71, wy + 31), Vector2(wx + 47, wy + 33)]
	for i in lit.size():
		if flick and i == 1:
			continue
		var p: Vector2 = lit[i]
		if fog:
			draw_circle(p + Vector2(1, 1), 4.0, Color(0.85, 0.62, 0.3, 0.12))
		_r(p.x, p.y, 2, 2, Color("b38a3c") if i == 2 else Color("d59a3d"))
	if shadow:
		# cabeça e ombros de alguém do lado de fora, colado ao vidro (a névoa e a chuva passam por cima)
		var sc := Color(0.07, 0.09, 0.1, 0.92) if fog else Color("040608")
		var sx := wx + 74.0
		var base := wy + wh
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 13, base), Vector2(sx - 9, base - 11), Vector2(sx - 3, base - 14),
			Vector2(sx + 3, base - 14), Vector2(sx + 9, base - 11), Vector2(sx + 13, base)]), sc)
		_r(sx - 2, base - 17, 4, 4, sc)
		draw_circle(Vector2(sx, base - 21), 4.5, sc)
	if weather == "rain":
		for d in _drops:
			if d.x >= 0.0 and d.x < ww:
				_r(wx + floorf(d.x), wy + floorf(d.y), 1, 3, Color("3a5563"))
	elif fog:
		# faixas de névoa passando devagar, recortadas pelo vidro
		var win := Rect2(wx, wy, ww, wh)
		for k in 4:
			var x := wx - 60.0 + fmod(_mist * (0.6 + k * 0.25) + k * 47.0, ww + 60.0)
			var band := Rect2(x, wy + 4 + k * 8, 60, 7).intersection(win)
			if band.has_area():
				draw_rect(band, Color(0.62, 0.7, 0.74, 0.07))
		draw_rect(win, Color(0.55, 0.62, 0.66, 0.06))
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
