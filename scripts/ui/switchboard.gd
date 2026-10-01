class_name Switchboard
extends Control
## Mesa comutadora.
## - ENTRADAS 01–10: onde as chamadas chegam. O FONE (cabo verde, que sai do telefone) entra aqui para atender.
## - SAÍDAS: uma tomada logo abaixo de cada entrada. Uma ponta do cabo de conexão entra aqui...
## - DESTINOS: ...e a outra ponta no número pedido.
## Os cabos de conexão são poucos (PATCHES): desmontar as conexões encerradas libera cabos.
## Arraste o plug até a tomada (ou clique no plug e depois na tomada). Clicar num plug encaixado,
## ou soltá-lo fora de uma tomada, faz ele voltar sozinho para a base.
## A mesa não conhece ligações: lê as lâmpadas de `exchange` e avisa por `end_changed` quando um plug muda.
## Desenha por cima dos vizinhos (z_index na cena), porque o FONE mora num encaixe do painel do telefone.

signal end_changed(end: int, jack: int, prev: int)
signal info_requested(jack: int)
signal warned(text: String)

const PATCHES := 3
## [cor, brilho] de cada cabo: 0 = FONE (verde), 1..PATCHES = cabos de conexão (vermelho, azul, amarelo).
## Mais cabos de conexão pedem mais cores aqui.
const CORD_COLORS := [
	[Color("3d6e34"), Color("6c9e58")],
	[Color("8e2a22"), Color("c4493b")],
	[Color("2a4a7c"), Color("4f7bb6")],
	[Color("b48c1c"), Color("e6c24c")],
]
const DEST_COLS := 17
const SIZE := Vector2(588, 330)
const FONE_HOME := Vector2(18, 24)   # posição do plug do FONE dentro do encaixe

var exchange: Exchange
var fone_socket: Control       # encaixe do FONE no painel do telefone
var dest_nums: Array = []
var ends: Array = []           # tomada de cada ponta (-1 = na base). 0 = FONE; 1..2*PATCHES = pontas dos cabos de conexão
var held := -1
var held_from := -1
var cursor := Vector2.ZERO
var info_lines: PackedStringArray = []
var info_ghost := false
var info_line := -1
var info_until := 0
var _press_pos := Vector2.ZERO
var _press_ms := 0
var _pulled := false           # o clique atual tirou um plug de uma tomada
var _anim := {}                # ponta -> {"from": posição, "t": 0..1} voltando para a base
const RETURN_SEC := 0.35
const CLICK_MS := 300          # soltar antes disso, fora de uma tomada, conta como clique (não como arrastar)
var _jacks: Array = []

# ---- física dos cabos (corda de Verlet) ----
const ROPE_N := 22                 # pontos por cabo
const GRAVITY := Vector2(0, 1600)  # px/s²
const DAMPING := 0.985             # 1 = sem atrito com o ar
const STIFF_ITER := 14             # iterações de restrição (maior = cabo menos elástico)
const SLACK := 70.0                # folga extra além da distância reta
const FLOOR_Y := 348.0             # o cabo repousa sobre a mesa abaixo do painel
const STEP := 1.0 / 90.0
var ropes := {}
var _acc := 0.0
var _last_mouse := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 1 + PATCHES * 2:
		ends.append(-1)


func setup(ex: Exchange, socket: Control) -> void:
	exchange = ex
	fone_socket = socket
	dest_nums = ex.dest_numbers()
	_jacks = range(1, 21) + dest_nums


## Encaixe do FONE em coordenadas da mesa (ele fica no painel do telefone, fora do retângulo dela).
func socket_rect() -> Rect2:
	if fone_socket == null:
		return Rect2(16, 350, 76, 44)
	return Rect2(fone_socket.global_position - global_position, fone_socket.size)


func _has_point(p: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(p) or socket_rect().has_point(p)


# ------------------------------------------------------------------ geometria
# Tomadas: 1–10 entradas, 11–20 saídas (linha + 10), destinos pelo próprio número (101–399).

func col_x(i: int) -> float:
	return 42.0 + i * 56.0


func jack_rect(j: int) -> Rect2:
	if j <= 10:
		return Rect2(col_x(j - 1) - 12, 74, 24, 24)
	if j <= 20:
		return Rect2(col_x(j - 11) - 10, 116, 20, 20)
	var k := dest_nums.find(j)
	return Rect2(38.0 + (k % DEST_COLS) * 32.0 - 11, 172 + int(k / DEST_COLS) * 50, 22, 22)


func jack_at(pos: Vector2) -> int:
	for j in _jacks:
		if jack_rect(j).grow(4).has_point(pos):
			return j
	return -1


func top_rect(i: int) -> Rect2:
	return Rect2(col_x(i) - 20, 36, 40, 36)


func patch_x(k: int) -> float:
	return 80.0 + k * 125.0


func home_pos(e: int) -> Vector2:
	if e == 0:
		return socket_rect().position + FONE_HOME
	return Vector2(patch_x((e - 1) / 2) + (-14.0 if e % 2 == 1 else 14.0), 278)


func home_rect(e: int) -> Rect2:
	if e == 0:
		return socket_rect()
	var h := home_pos(e)
	return Rect2(h.x - 12, 258, 24, 50)


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


# ------------------------------------------------------------------ ações

func place(e: int, j: int) -> bool:
	var why := refuse(e, j)
	if why != "":
		warned.emit(why)
		Sfx.play("click")
		return false
	ends[e] = j
	held = -1
	Sfx.play("plug_in")
	end_changed.emit(e, j, -1)
	return true


func pick_up(e: int) -> void:
	var prev: int = ends[e]
	ends[e] = -1
	held = e
	held_from = prev
	Sfx.play("plug_out")
	if prev != -1:
		end_changed.emit(e, -1, prev)


## O plug volta para a base (o FONE volta ao telefone), num arco curto.
func go_home(e: int) -> void:
	var from := _plug_pos(e)
	var prev: int = ends[e]
	ends[e] = -1
	if held == e:
		held = -1
	if from.distance_to(home_pos(e)) > 2.0:
		_anim[e] = {"from": from, "t": 0.0}
	else:
		Sfx.play("thump", -14.0)
	if prev != -1:
		end_changed.emit(e, -1, prev)


func show_info(text_lines: PackedStringArray, ghost: bool, line: int) -> void:
	info_lines = text_lines
	info_ghost = ghost
	info_line = line
	info_until = Time.get_ticks_msec() + (7000 if ghost else 2600)


# ------------------------------------------------------------------ entrada

func _gui_input(e: InputEvent) -> void:
	if e.is_action_pressed("cancel_plug") and held != -1:
		go_home(held)
		accept_event()
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press(e.position)
		else:
			_release(e.position)
		accept_event()


func _press(pos: Vector2) -> void:
	_press_pos = pos
	_press_ms = Time.get_ticks_msec()
	_pulled = false
	if held != -1:
		var j := jack_at(pos)
		if j != -1:
			place(held, j)
		else:
			go_home(held)
		return
	for e in ends.size():
		if ends[e] == -1 and not _anim.has(e) and home_rect(e).has_point(pos):
			held = e
			held_from = -1
			Sfx.play("plug_out")
			return
	var j := jack_at(pos)
	if j != -1:
		var e := cord_at(j)
		if e != -1:
			pick_up(e)
			_pulled = true
		else:
			info_requested.emit(j)
		return
	for i in 10:
		if top_rect(i).has_point(pos):
			info_requested.emit(i + 1)
			return


## Clique num plug encaixado: ele volta para a base. Clique num plug da base: fica na mão até
## o próximo clique. Arrastar e soltar encaixa na tomada (ou devolve à base, se soltar fora).
## Um clique rápido que mexe uns pixels (mouse tremendo, toque no trackpad) continua sendo clique.
func _release(pos: Vector2) -> void:
	if held == -1:
		return
	var j := jack_at(pos)
	var quick := Time.get_ticks_msec() - _press_ms < CLICK_MS and j == -1
	if pos.distance_to(_press_pos) < 6.0 or quick:
		if _pulled:
			go_home(held)
		return
	if j == -1 or not place(held, j):
		go_home(held)


func _process(delta: float) -> void:
	if held != -1:
		cursor = get_local_mouse_position()
	for e in _anim.keys():
		_anim[e]["t"] += delta / RETURN_SEC
		if _anim[e]["t"] >= 1.0:
			_anim.erase(e)
			Sfx.play("thump", -14.0)
	_acc = minf(_acc + delta, STEP * 6)
	while _acc >= STEP:
		_acc -= STEP
		for c in PATCHES + 1:
			_step_rope(c, STEP)
		_last_mouse = get_local_mouse_position()
	queue_redraw()


func _plug_pos(e: int) -> Vector2:
	if held == e:
		return cursor
	if ends[e] != -1:
		return jack_rect(int(ends[e])).get_center()
	if _anim.has(e):
		var k: float = 1.0 - pow(1.0 - float(_anim[e]["t"]), 3.0)
		var from: Vector2 = _anim[e]["from"]
		return from.lerp(home_pos(e), k) + Vector2(0, -sin(k * PI) * 36.0)
	return home_pos(e)


## Pontas da corda do cabo c (0 = FONE, 1.. = conexão); vazio = cabo recolhido.
func _rope_ends(c: int) -> Array:
	if c == 0:
		if held != 0 and ends[0] == -1 and not _anim.has(0):
			return []
		return [Vector2(home_pos(0).x, socket_rect().position.y), _plug_pos(0) + Vector2(0, 20)]
	var a := c * 2 - 1
	var b := c * 2
	if held != a and held != b and ends[a] == -1 and ends[b] == -1 and not _anim.has(a) and not _anim.has(b):
		return []
	return [_plug_pos(a) + Vector2(0, 20), _plug_pos(b) + Vector2(0, 20)]


## Simula o cabo como uma corda: os pontos têm inércia e gravidade,
## as pontas ficam presas e a distância entre pontos é mantida.
func _step_rope(c: int, dt: float) -> void:
	var re := _rope_ends(c)
	if re.is_empty():
		ropes.erase(c)
		return
	var a: Vector2 = re[0]
	var e: Vector2 = re[1]
	var floor_y := FLOOR_Y   # o fio do FONE também repousa na fresta entre a mesa e o telefone
	var target_len := a.distance_to(e) + SLACK
	if not ropes.has(c):
		var init := PackedVector2Array()
		for i in ROPE_N:
			init.append(a.lerp(e, float(i) / (ROPE_N - 1)))
		ropes[c] = {"pts": init, "old": init.duplicate(), "len": target_len}
	var r: Dictionary = ropes[c]
	var pts: PackedVector2Array = r["pts"]
	var old: PackedVector2Array = r["old"]
	var length: float = lerpf(float(r["len"]), target_len, 0.08)
	var seg := length / (ROPE_N - 1)
	# inércia + gravidade
	var mouse := get_local_mouse_position()
	var mv := mouse - _last_mouse
	var in_hand := held != -1 and cable_of(held) == c
	for i in range(1, ROPE_N - 1):
		var v := (pts[i] - old[i]) * DAMPING
		old[i] = pts[i]
		pts[i] += v + GRAVITY * dt * dt
		# passar o mouse por cima do cabo empurra o fio
		if not in_hand and mv.length_squared() > 0.5 and pts[i].distance_to(mouse) < 16.0:
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
			if pts[i].y > floor_y:
				pts[i].y = floor_y
				old[i].x = lerpf(old[i].x, pts[i].x, 0.3)   # atrito com a mesa
	r["pts"] = pts
	r["old"] = old
	r["len"] = length


# ------------------------------------------------------------------ desenho

## Cor da lâmpada para um estado de linha (Exchange.Line); alpha 0 = apagada.
func _lamp(st: int, ms: int, steady: bool) -> Color:
	match st:
		Exchange.Line.RING:
			if steady or (ms / 250) % 2 == 0:
				return Pal.AMBER
		Exchange.Line.TALK:
			return Pal.AMBER
		Exchange.Line.HOLD:
			return Pal.AMBER if (ms / 800) % 2 == 0 else Pal.AMBER.darkened(0.45)
		Exchange.Line.CONN:
			return Pal.GREEN
		Exchange.Line.DONE:
			return Pal.RED
	return Color(0, 0, 0, 0)


## Os estados de destino (Exchange.Dest) acendem como os de linha equivalentes.
func _dest_lamp(st: int, ms: int) -> Color:
	match st:
		Exchange.Dest.RING:
			return _lamp(Exchange.Line.RING, ms, false)
		Exchange.Dest.CONN:
			return Pal.GREEN
		Exchange.Dest.DONE:
			return Pal.RED
	return Color(0, 0, 0, 0)


func _draw_lamp(r: Rect2, col: Color) -> void:
	if col.a > 0.0:
		var gc := col
		gc.a = 0.25
		draw_rect(r.grow(4), gc)
	draw_rect(r.grow(2), Color.BLACK)
	draw_rect(r, col if col.a > 0.0 else Color("2a2016"))


func _draw_jack(jr: Rect2, rim: Color = Pal.BRASS) -> void:
	draw_rect(jr, Color.BLACK)
	draw_rect(jr.grow(-2), rim)
	var hole := jr.size.x * 0.45
	draw_rect(Rect2(jr.get_center() - Vector2(hole, hole) / 2.0 + Vector2(0, 2), Vector2(hole, hole)), Color("050403"))


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
	draw_string(Pal.mono, Vector2(17, 28), T.text(T.Key.BOARD_TITLE), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.BRASS)
	draw_string(Pal.ui, Vector2(17, 26), T.text(T.Key.BOARD_LEGEND), HORIZONTAL_ALIGNMENT_RIGHT, w - 34, 11, Pal.DIM)
	if exchange == null:
		return

	# entradas e saídas
	for i in 10:
		var n := i + 1
		var st := exchange.line(n)
		var cx := col_x(i)
		draw_rect(Rect2(cx - 17, 36, 34, 20), Color.BLACK)
		draw_rect(Rect2(cx - 15, 38, 30, 16), Color("1a1711"))
		draw_string(Pal.mono, Vector2(cx - 15, 52), "%02d" % n, HORIZONTAL_ALIGNMENT_CENTER, 30, 19, Color("d8c9a2"))
		_draw_lamp(Rect2(cx - 7, 60, 14, 9), _lamp(st, ms, fone_line() == n))
		_draw_jack(jack_rect(n))
		var sc := Pal.DIM
		if st in [Exchange.Line.RING, Exchange.Line.TALK, Exchange.Line.HOLD]:
			sc = Pal.AMBER
		elif st == Exchange.Line.DONE:
			sc = Pal.RED
		draw_string(Pal.ui, Vector2(cx - 28, 110), exchange.line_label(n), HORIZONTAL_ALIGNMENT_CENTER, 56, 10, sc)
		_draw_jack(jack_rect(n + 10), Color("7a6230"))

	# destinos
	draw_rect(Rect2(12, 142, w - 24, 2), Pal.PANEL_LO)
	draw_string(Pal.ui, Vector2(17, 154), T.text(T.Key.BOARD_DESTS), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.DIM)
	for d in dest_nums:
		var jr := jack_rect(d)
		var cx := jr.get_center().x
		var st := exchange.dest(d)
		draw_string(Pal.mono, Vector2(cx - 16, jr.position.y - 5), str(d), HORIZONTAL_ALIGNMENT_CENTER, 32, 17, Color("d8c9a2") if st == Exchange.Dest.FREE else Pal.TEXT)
		var lc := _dest_lamp(st, ms)
		if lc.a > 0.0:
			draw_rect(jr.grow(3), lc)   # o aro da tomada acende
		_draw_jack(jr)

	# base dos cabos de conexão
	draw_rect(Rect2(12, 250, w - 24, 2), Pal.PANEL_LO)
	for k in PATCHES:
		var cx := patch_x(k)
		draw_rect(Rect2(cx - 30, 298, 60, 14), Color.BLACK)
		draw_rect(Rect2(cx - 28, 300, 56, 10), Color("1b1812"))
		var a := 1 + k * 2
		if ends[a] == -1 and ends[a + 1] == -1 and held != a and held != a + 1 and not _anim.has(a) and not _anim.has(a + 1):
			# cabo enrolado na base
			var coil := PackedVector2Array([Vector2(cx - 14, 298), Vector2(cx - 10, 306), Vector2(cx, 309), Vector2(cx + 10, 306), Vector2(cx + 14, 298)])
			draw_polyline(coil, Color.BLACK, 7.0)
			draw_polyline(coil, _cable_col(a)[0], 4.0)
		draw_string(Pal.mono, Vector2(cx - 30, 322), T.text(T.Key.BOARD_CORD) % (k + 1), HORIZONTAL_ALIGNMENT_CENTER, 60, 14, Pal.BRASS)
	# legenda
	var leg := [[Pal.AMBER, T.Key.LEGEND_RING], [Pal.GREEN, T.Key.LEGEND_CONN], [Pal.RED, T.Key.LEGEND_DONE], [Color("2a2016"), T.Key.LEGEND_FREE]]
	for k in leg.size():
		var y := 268 + k * 16
		draw_rect(Rect2(452, y - 9, 9, 9), Color.BLACK)
		draw_rect(Rect2(453, y - 8, 7, 7), leg[k][0])
		draw_string(Pal.ui, Vector2(467, y), T.text(leg[k][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.DIM)

	# destaque da tomada sob o plug
	if held != -1:
		var hj := jack_at(get_local_mouse_position())
		if hj != -1:
			var ok := refuse(held, hj) == ""
			var hr := jack_rect(hj).grow(4)
			draw_rect(hr, Pal.GLOW if ok else Pal.RED, false, 2.0)
			if ok:
				var gc := Pal.GLOW
				gc.a = 0.2
				draw_rect(hr, gc)

	# cabos e plugues (o que está na mão é desenhado por último, por cima dos outros)
	var top := cable_of(held) if held != -1 else -1
	for c in PATCHES + 1:
		if c != top:
			_draw_rope(c)
	if top != -1:
		_draw_rope(top)
	for e in ends.size():
		if e != held:
			_draw_plug(e)
	if held != -1:
		_draw_plug(held)

	# balão de informação
	if ms < info_until and info_line > 0:
		var jr := jack_rect(info_line)
		var bw := 200.0
		var bh := 12.0 + info_lines.size() * 19.0
		var bx := clampf(jr.get_center().x - bw / 2, 8, w - bw - 8)
		var by := minf(jr.end.y + 8, h - bh - 8)
		var bc := Pal.GHOST if info_ghost else Pal.BRASS
		draw_rect(Rect2(bx, by, bw, bh), bc)
		draw_rect(Rect2(bx + 2, by + 2, bw - 4, bh - 4), Color("0e0c08"))
		for k in info_lines.size():
			draw_string(Pal.mono, Vector2(bx + 10, by + 22 + k * 19), info_lines[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Pal.GHOST if info_ghost else Pal.TEXT)


## [cor, brilho] do cabo da ponta e.
func _cable_col(e: int) -> Array:
	return CORD_COLORS[cable_of(e)]


func _draw_rope(c: int) -> void:
	if not ropes.has(c):
		return
	var col: Array = CORD_COLORS[c]
	var pts: PackedVector2Array = ropes[c]["pts"]
	draw_polyline(pts, Color.BLACK, 8.0)
	draw_polyline(pts, col[0], 5.0)
	var pts2 := PackedVector2Array()
	for q in pts:
		pts2.append(q + Vector2(-1, -1))
	draw_polyline(pts2, col[1], 1.5)


func _draw_plug(e: int) -> void:
	var end := _plug_pos(e)
	var col: Array = _cable_col(e)
	var px := roundf(end.x)
	var py := roundf(end.y)
	draw_rect(Rect2(px - 7, py - 2, 14, 22), Color.BLACK)
	draw_rect(Rect2(px - 5, py, 10, 18), col[0])
	draw_rect(Rect2(px - 5, py, 3, 18), col[1])
	draw_rect(Rect2(px - 4, py - 9, 8, 9), Color.BLACK)
	draw_rect(Rect2(px - 3, py - 8, 6, 8), Color("d9b56a"))


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
