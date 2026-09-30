class_name Switchboard
extends Control
## Mesa comutadora: 10 linhas com lâmpada e tomada, e dois plugues (FONE e SWITCH).
## Clique no plug para pegá-lo e clique na tomada para encaixar — ou arraste.

signal plug_changed(plug: String, line: int, prev: int)
signal info_requested(line: int)
signal warned(text: String)

var lines: Array = []          # referência ao array de estados mantido pelo Main
var plugs := {"fone": -1, "sw": -1}
var held := ""
var held_from := -1
var cursor := Vector2.ZERO
var sfx: Sfx
var info_lines: PackedStringArray = []
var info_ghost := false
var info_line := -1
var info_until := 0
var _picked := false

# ---- física dos cabos (corda de Verlet) ----
const ROPE_N := 22                 # pontos por cabo
const GRAVITY := Vector2(0, 1600)  # px/s²
const DAMPING := 0.985             # 1 = sem atrito com o ar
const STIFF_ITER := 14             # iterações de restrição (maior = cabo menos elástico)
const SLACK := 70.0                # folga extra além da distância reta
const FLOOR_Y := 300.0             # o cabo repousa sobre a mesa abaixo do painel
const STEP := 1.0 / 90.0
var ropes := {}
var _acc := 0.0
var _last_mouse := Vector2.ZERO


func _ready() -> void:
	size = Vector2(588, 268)
	mouse_filter = Control.MOUSE_FILTER_STOP


func col_x(i: int) -> float:
	return 42.0 + i * 56.0


func jack_rect(i: int) -> Rect2:
	return Rect2(col_x(i) - 16, 104, 32, 32)


func top_rect(i: int) -> Rect2:
	return Rect2(col_x(i) - 20, 42, 40, 56)


func home_rect(p: String) -> Rect2:
	return Rect2(17 if p == "fone" else 133, 194, 92, 62)


func plug_at(n: int) -> String:
	if plugs["fone"] == n:
		return "fone"
	if plugs["sw"] == n:
		return "sw"
	return ""


# ------------------------------------------------------------------ ações

func place(p: String, n: int) -> void:
	var other := "sw" if p == "fone" else "fone"
	if plugs[other] == n:
		warned.emit("Essa tomada já tem um plug.")
		return
	plugs[p] = n
	held = ""
	sfx.play("plug_in")
	plug_changed.emit(p, n, -1)


func pick_up(p: String) -> void:
	var prev: int = plugs[p]
	plugs[p] = -1
	held = p
	held_from = prev
	sfx.play("plug_out")
	plug_changed.emit(p, -1, prev)


func go_home(p: String) -> void:
	var prev: int = plugs[p]
	plugs[p] = -1
	if held == p:
		held = ""
	sfx.play("plug_out")
	if prev != -1:
		plug_changed.emit(p, -1, prev)


func return_all() -> void:
	plugs["fone"] = -1
	plugs["sw"] = -1
	held = ""
	sfx.play("plug_out")


func show_info(text_lines: PackedStringArray, ghost: bool, line: int) -> void:
	info_lines = text_lines
	info_ghost = ghost
	info_line = line
	info_until = Time.get_ticks_msec() + (7000 if ghost else 2600)


# ------------------------------------------------------------------ entrada

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press(e.position)
		else:
			_release(e.position)
		accept_event()


func _press(pos: Vector2) -> void:
	_picked = false
	for p in ["fone", "sw"]:
		if home_rect(p).has_point(pos):
			if held == p:
				go_home(p)
			else:
				if held != "":
					go_home(held)
				if plugs[p] != -1:
					go_home(p)
				else:
					held = p
					held_from = -1
					_picked = true
					sfx.play("plug_out")
			return
	for i in 10:
		var n := i + 1
		if jack_rect(i).grow(4).has_point(pos):
			if held == "":
				var p := plug_at(n)
				if p != "":
					pick_up(p)
					_picked = true
				else:
					info_requested.emit(n)
			return
		if top_rect(i).has_point(pos):
			info_requested.emit(n)
			return


func _release(pos: Vector2) -> void:
	if held != "":
		for i in 10:
			if jack_rect(i).grow(4).has_point(pos):
				var n := i + 1
				if not (_picked and held_from == n):
					place(held, n)
				break
	_picked = false


func _process(delta: float) -> void:
	if held != "":
		cursor = get_local_mouse_position()
	_acc = minf(_acc + delta, STEP * 6)
	while _acc >= STEP:
		_acc -= STEP
		for p in ["fone", "sw"]:
			_step_rope(p, STEP)
		_last_mouse = get_local_mouse_position()
	queue_redraw()


func _plug_pos(p: String) -> Vector2:
	if held == p:
		return cursor
	if plugs[p] != -1:
		return jack_rect(int(plugs[p]) - 1).get_center()
	var hr := home_rect(p)
	return Vector2(hr.get_center().x, hr.position.y + 16)


func _anchor(p: String) -> Vector2:
	return Vector2(home_rect(p).get_center().x, 262)


## Simula o cabo como uma corda: os pontos têm inércia e gravidade,
## as pontas ficam presas (saída no painel e plug) e a distância entre pontos é mantida.
func _step_rope(p: String, dt: float) -> void:
	var at_home: bool = held != p and plugs[p] == -1
	if at_home:
		ropes.erase(p)   # o cabo recolhe para dentro da mesa
		return
	var a := _anchor(p)
	var e := _plug_pos(p) + Vector2(0, 20)
	var target_len := a.distance_to(e) + SLACK
	if not ropes.has(p):
		var init := PackedVector2Array()
		for i in ROPE_N:
			init.append(a.lerp(e, float(i) / (ROPE_N - 1)))
		ropes[p] = {"pts": init, "old": init.duplicate(), "len": target_len}
	var r: Dictionary = ropes[p]
	var pts: PackedVector2Array = r["pts"]
	var old: PackedVector2Array = r["old"]
	var length: float = lerpf(float(r["len"]), target_len, 0.08)
	var seg := length / (ROPE_N - 1)
	# inércia + gravidade
	var mouse := get_local_mouse_position()
	var mv := mouse - _last_mouse
	for i in range(1, ROPE_N - 1):
		var v := (pts[i] - old[i]) * DAMPING
		old[i] = pts[i]
		pts[i] += v + GRAVITY * dt * dt
		# passar o mouse por cima do cabo empurra o fio
		if held != p and mv.length_squared() > 0.5 and pts[i].distance_to(mouse) < 16.0:
			pts[i] += mv * 0.35
	pts[0] = a
	pts[ROPE_N - 1] = e
	# restrições de comprimento
	for _it in STIFF_ITER:
		for i in ROPE_N - 1:
			var d := pts[i + 1] - pts[i]
			var l := d.length()
			if l < 0.0001:
				continue
			var corr := d * ((l - seg) / l)
			if i == 0:
				pts[i + 1] -= corr
			elif i + 1 == ROPE_N - 1:
				pts[i] += corr
			else:
				pts[i] += corr * 0.5
				pts[i + 1] -= corr * 0.5
		for i in range(1, ROPE_N - 1):
			if pts[i].y > FLOOR_Y:
				pts[i].y = FLOOR_Y
				old[i].x = lerpf(old[i].x, pts[i].x, 0.3)   # atrito com a mesa
	r["pts"] = pts
	r["old"] = old
	r["len"] = length


# ------------------------------------------------------------------ desenho

func _draw() -> void:
	var w := size.x
	var h := size.y
	var ms := Time.get_ticks_msec()
	draw_rect(Rect2(Vector2.ZERO, size), Pal.EDGE)
	draw_rect(Rect2(3, 3, w - 6, h - 6), Pal.PANEL)
	draw_rect(Rect2(3, 3, w - 6, 3), Pal.PANEL_HI)
	draw_rect(Rect2(3, 3, 3, h - 6), Pal.PANEL_HI)
	draw_rect(Rect2(3, h - 6, w - 6, 3), Pal.PANEL_LO)
	draw_rect(Rect2(w - 6, 3, 3, h - 6), Pal.PANEL_LO)
	draw_string(Pal.mono, Vector2(17, 32), "MESA COMUTADORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.BRASS)
	draw_string(Pal.mono, Vector2(17, 32), "LINHAS 01–10", HORIZONTAL_ALIGNMENT_RIGHT, w - 34, 19, Pal.DIM)

	for i in 10:
		var n := i + 1
		var st: String = lines[i] if i < lines.size() else "free"
		var cx := col_x(i)
		# número
		draw_rect(Rect2(cx - 17, 46, 34, 24), Color.BLACK)
		draw_rect(Rect2(cx - 15, 48, 30, 20), Color("1a1711"))
		draw_string(Pal.mono, Vector2(cx - 15, 65), "%02d" % n, HORIZONTAL_ALIGNMENT_CENTER, 30, 22, Color("d8c9a2"))
		# lâmpada
		var lr := Rect2(cx - 8, 78, 16, 16)
		var col := Color("2a2016")
		var glow := false
		match st:
			"ring":
				if (ms / 250) % 2 == 0:
					col = Pal.AMBER
					glow = true
			"talk":
				col = Pal.AMBER
				glow = true
			"hold":
				col = Pal.AMBER if (ms / 800) % 2 == 0 else Pal.AMBER.darkened(0.45)
				glow = true
			"busy", "conn":
				col = Pal.GREEN
				glow = true
			"ghost":
				var ph := (ms % 3300) / 3300.0
				col = Pal.GHOST if not (ph > 0.47 and ph < 0.53) else Pal.GHOST.darkened(0.6)
				glow = true
		if glow:
			var gc := col
			gc.a = 0.25
			draw_rect(lr.grow(5), gc)
		draw_rect(lr.grow(2), Color.BLACK)
		draw_rect(lr, col)
		# tomada
		var jr := jack_rect(i)
		draw_rect(jr, Color.BLACK)
		draw_rect(jr.grow(-2), Pal.BRASS)
		draw_rect(Rect2(cx - 7, jr.position.y + 9, 14, 14), Color("050403"))
		if held != "" and plug_at(n) == "":
			_dashed(jr.grow(5), Pal.GLOW)
		# estado
		var lbl: String = GameData.LINE_LABEL.get(st, "")
		var sc := Pal.DIM
		if st in ["ring", "talk", "hold"]:
			sc = Pal.AMBER
		elif st == "ghost":
			sc = Pal.GHOST
		var lw := 84.0 if st == "ghost" else 56.0
		draw_string(Pal.ui, Vector2(cx - lw / 2.0, 157), lbl, HORIZONTAL_ALIGNMENT_CENTER, lw, 10 if st == "ghost" else 11, sc)

	# bases dos plugues
	for p in ["fone", "sw"]:
		var hr := home_rect(p)
		draw_rect(hr, Color.BLACK)
		draw_rect(hr.grow(-2), Color("1b1812"))
		draw_rect(Rect2(hr.position.x + 33, hr.position.y + 6, 26, 18), Color("3a3223"))
		draw_rect(Rect2(hr.position.x + 35, hr.position.y + 8, 22, 14), Color("050403"))
		draw_string(Pal.mono, Vector2(hr.position.x, hr.end.y - 8), "FONE" if p == "fone" else "SWITCH", HORIZONTAL_ALIGNMENT_CENTER, hr.size.x, 18, Pal.BRASS)
	# legenda
	var leg := [[Pal.AMBER, "chamando ou em linha"], [Pal.GREEN, "ocupada ou conectada"], [Color("2a2016"), "livre"]]
	for k in leg.size():
		var y := 206 + k * 17
		draw_rect(Rect2(380, y - 9, 9, 9), Color.BLACK)
		draw_rect(Rect2(381, y - 8, 7, 7), leg[k][0])
		draw_string(Pal.ui, Vector2(395, y), leg[k][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Pal.DIM)

	# cabos e plugues
	for p in ["fone", "sw"]:
		_draw_cord(p)

	# balão de informação
	if ms < info_until and info_line > 0:
		var jr := jack_rect(info_line - 1)
		var bw := 200.0
		var bh := 12.0 + info_lines.size() * 19.0
		var bx := clampf(jr.get_center().x - bw / 2, 8, w - bw - 8)
		var by := jr.end.y + 8
		var bc := Pal.GHOST if info_ghost else Pal.BRASS
		draw_rect(Rect2(bx, by, bw, bh), bc)
		draw_rect(Rect2(bx + 2, by + 2, bw - 4, bh - 4), Color("0e0c08"))
		for k in info_lines.size():
			draw_string(Pal.mono, Vector2(bx + 10, by + 22 + k * 19), info_lines[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Pal.GHOST if info_ghost else Pal.TEXT)


func _dashed(r: Rect2, c: Color) -> void:
	var x := r.position.x
	while x < r.end.x:
		draw_rect(Rect2(x, r.position.y, 4, 2), c)
		draw_rect(Rect2(x, r.end.y - 2, 4, 2), c)
		x += 7
	var y := r.position.y
	while y < r.end.y:
		draw_rect(Rect2(r.position.x, y, 2, 4), c)
		draw_rect(Rect2(r.end.x - 2, y, 2, 4), c)
		y += 7


func _draw_cord(p: String) -> void:
	var end := _plug_pos(p)
	var col := Color("7d2e22") if p == "fone" else Color("27435a")
	var hi := Color("a8473a") if p == "fone" else Color("3b6687")
	if ropes.has(p):
		var pts: PackedVector2Array = ropes[p]["pts"]
		draw_polyline(pts, Color.BLACK, 8.0)
		draw_polyline(pts, col, 5.0)
		var pts2 := PackedVector2Array()
		for q in pts:
			pts2.append(q + Vector2(-1, -1))
		draw_polyline(pts2, hi, 1.5)
	var px := roundf(end.x)
	var py := roundf(end.y)
	draw_rect(Rect2(px - 7, py - 2, 14, 22), Color.BLACK)
	draw_rect(Rect2(px - 5, py, 10, 18), col)
	draw_rect(Rect2(px - 5, py, 3, 18), hi)
	draw_rect(Rect2(px - 4, py - 9, 8, 9), Color.BLACK)
	draw_rect(Rect2(px - 3, py - 8, 6, 8), Color("d9b56a"))
