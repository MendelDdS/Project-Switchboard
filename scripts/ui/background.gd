class_name Background
extends Control
## Parede, janela (com o clima da noite), mesa de madeira e luminária — desenhados em pixels de 2x2 e esticados até
## a borda da tela (a janela ocupa o lugar reservado para ela na interface, `window`; a luminária, a borda direita).
## `weather`: "rain" (gotas no vidro), "fog" (névoa passando, luzes difusas) ou "clear" (estrelas e lua).
## `shadow`: a silhueta de alguém parado do lado de fora da janela (sai pouco antes da ligação desconhecida).

const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]

@export var window: Control   ## onde fica a janela (um Control vazio na interface, ao lado do rádio)

var flick := false
var lamp_level := 1.0
var weather := "rain"
var shadow := false
var _drops: Array = []
var _stars: Array[Vector2] = []
var _mist := 0.0
var _win := Vector2(104, 38)   # o vidro da janela, em pixels de 2x2 (do último desenho)
var _acc := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 120:   # gotas e estrelas em frações do vidro: a janela muda de tamanho com a tela
		_drops.append(Vector3(randf(), randf(), 0.6 + randf() * 0.7))
	for i in 30:
		_stars.append(Vector2(randf() * 0.95 + 0.02, randf() * 0.5 + 0.03))


func _process(delta: float) -> void:
	_acc += delta
	if _acc < 1.0 / 30.0:
		return
	_acc = 0.0
	_mist += 0.12
	for i in _drops.size():
		var d: Vector3 = _drops[i]
		d.y += d.z / _win.y
		d.x -= d.z * 0.25 / _win.x
		if d.y > 1.0:
			d.y = -0.05
			d.x = randf() * 1.1
		_drops[i] = d
	if flick:
		lamp_level = FLICK[int(Time.get_ticks_msec() / 90.0) % FLICK.size()]
	else:
		lamp_level = 1.0
	queue_redraw()


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	Bloom.clear(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var w := ceilf(size.x / 2.0)
	var h := ceilf(size.y / 2.0)
	_r(0, 0, w, h, Color("172023"))
	for x in range(0, w, 22):
		_r(x, 0, 2, 48, Color("141c1f"))
	_r(0, 47, w, 2, Color("1e282b"))
	_r(0, 49, w, h - 49, Color("211811"))
	for y in range(56, h, 9):
		_r(0, y, w, 1, Color("1b130d"))
	for i in int(40 * w * h / (640 * 360)):
		_r((i * 97) % int(w), 52 + ((i * 53) % int(h - 60)), 18 + (i % 5) * 6, 1, Color("2a1f16"))
	# janela, no lugar reservado (em pixels de 2x2: o vidro fica dentro do batente de 3)
	var wr := Rect2((window.global_position - global_position) / 2.0, window.size / 2.0) if window else Rect2(276, 2, 110, 44)
	var wx := ceilf(wr.position.x) + 3.0
	var wy := ceilf(wr.position.y) + 3.0
	var ww := floorf(wr.size.x) - 6.0
	var wh := floorf(wr.size.y) - 6.0
	_win = Vector2(ww, wh)
	_r(wx - 3, wy - 3, ww + 6, wh + 6, Color("2c2a24"))
	var fog := weather == "fog"
	_r(wx, wy, ww, wh, Color("1b252b") if fog else (Color("0a1422") if weather == "clear" else Color("0b141c")))
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			var on := sin(tw + i * 1.7) > -0.6
			_r(wx + floorf(s.x * ww), wy + floorf(s.y * wh), 1, 1, Color("c9d2dc") if on else Color("56606c"))
		draw_circle(Vector2(wx + ww - 20, wy + 9), 4.0, Color("d8d0a8"))
		draw_circle(Vector2(wx + ww - 18, wy + 8), 3.6, Color("0a1422"))
	_r(wx, wy + wh - 8, ww, 8, Color("1a252b") if fog else Color("10202b"))
	for i in int(ww / 13.0):
		_r(wx + 4 + i * 13, wy + wh - 6 - (i % 3) * 3, 9, 6 + (i % 3) * 3, Color("18222a") if fog else Color("0a1016"))
	var lit := [Vector2(wx + roundf(ww * 0.17), wy + wh - 8), Vector2(wx + roundf(ww * 0.68), wy + wh - 7), Vector2(wx + roundf(ww * 0.45), wy + wh - 5)]
	for i in lit.size():
		if flick and i == 1:
			continue
		var p: Vector2 = lit[i]
		if fog:
			draw_circle(p + Vector2(1, 1), 4.0, Color(0.85, 0.62, 0.3, 0.12))
		var window_light := Color("b38a3c") if i == 2 else Color("d59a3d")
		_r(p.x, p.y, 2, 2, window_light)
		Bloom.light(self, Rect2(p * 2.0, Vector2(4, 4)), window_light, 0.5)   # janela acesa lá fora (o desenho é em 2×)
	if shadow:
		# cabeça e ombros de alguém do lado de fora, colado ao vidro, contra a luz de um poste da rua
		# (a névoa e a chuva passam por cima)
		var sc := Color.BLACK
		var sx := wx + roundf(ww * 0.71)
		var base := wy + wh
		for k in 5:
			draw_circle(Vector2(sx + 3, base - 8), 22.0 - k * 4.0, Color(0.85, 0.62, 0.3, 0.035))
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 13, base), Vector2(sx - 9, base - 11), Vector2(sx - 3, base - 14),
			Vector2(sx + 3, base - 14), Vector2(sx + 9, base - 11), Vector2(sx + 13, base)]), sc)
		_r(sx - 2, base - 17, 4, 4, sc)
		draw_circle(Vector2(sx, base - 21), 4.5, sc)
	if weather == "rain":
		for d in _drops:
			if d.x >= 0.0 and d.x < 1.0 and d.y >= 0.0:
				_r(wx + floorf(d.x * ww), wy + floorf(d.y * (wh - 3)), 1, 3, Color("3a5563"))
	elif fog:
		# faixas de névoa passando devagar, recortadas pelo vidro
		var win := Rect2(wx, wy, ww, wh)
		for k in int(wh / 9.0):
			var x := wx - 60.0 + fmod(_mist * (0.6 + (k % 4) * 0.25) + k * 47.0, ww + 60.0)
			var band := Rect2(x, wy + 4 + k * 8, 60, 7).intersection(win)
			if band.has_area():
				draw_rect(band, Color(0.62, 0.7, 0.74, 0.07))
		draw_rect(win, Color(0.55, 0.62, 0.66, 0.06))
	_r(wx + floorf(ww / 2) - 1, wy, 2, wh, Color("2c2a24"))
	_r(wx, wy + floorf(wh / 2) - 1, ww, 2, Color("2c2a24"))
	# luminária
	var lx := w - 140.0
	_r(lx, 0, 2, 8, Color("111111"))
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 8, 8), Vector2(lx + 10, 8), Vector2(lx + 22, 22), Vector2(lx - 20, 22)]), Color("34422e"))
	_r(lx - 6, 9, 4, 3, Color("50623f"))
	_r(lx - 12, 15, 6, 3, Color("50623f"))
	_r(lx - 12, 22, 26, 3, Color(1.0, (200.0 + 30.0 * lamp_level) / 255.0, 140.0 / 255.0, 0.35 + 0.65 * lamp_level))
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 18, 24), Vector2(lx + 20, 24), Vector2(lx + 120, 90), Vector2(lx - 110, 90)]), Color(1.0, 0.82, 0.55, 0.08 * lamp_level))
