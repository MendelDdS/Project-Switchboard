class_name Switchboard
extends Control
## Mesa comutadora.
## - ENTRADAS 01–10: onde as chamadas chegam. O FONE (cabo verde, que sai do telefone) entra aqui para atender.
## - SAÍDAS: uma tomada logo abaixo de cada entrada. Uma ponta do cabo de conexão entra aqui...
## - DESTINOS: ...e a outra ponta no número pedido.
## Os cabos de conexão são poucos (PATCHES): desmontar as conexões encerradas libera cabos.
## Cada ponta tem o próprio fio, que sai de um buraco (dois por cabo de conexão na base; o do FONE no encaixe).
## Arraste o plug até a tomada (clicar e segurar). Clicar num plug encaixado (sem arrastar),
## ou soltá-lo fora de uma tomada, solta o plug: ele cai e o fio o recolhe para o buraco.
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
var cursor := Vector2.ZERO
var _hover := -1               # ponta cujo plug está sob o mouse (pode ser pega); desenhada com destaque
var _order: Array = []         # ordem de desenho das pontas: a mexida por último fica por cima
var info_lines: PackedStringArray = []
var info_ghost := false
var info_line := -1
var info_until := 0
var _press_pos := Vector2.ZERO
var _loose := {}               # ponta solta voltando para o buraco -> {"t": s caindo/recolhendo, "seat": -1 ou 0..1 assentando, "direct", "from", "ang"}
const FALL_SEC := 0.35         # o plug solto cai livre antes de o fio começar a recolher
const NEAR_HOLE := 45.0        # solto acima do buraco (a qualquer altura) e com essa distância na horizontal, o fio puxa o plug direto (sem cair)
const PULL_SPEED := 480.0      # px/s de fio que entra no buraco
const SEAT_LEN := 12.0         # com o fio curto assim, o plug assenta no lugar
const SEAT_SEC := 0.1
const MAX_FLING := 1800.0      # px/s: o plug solto em movimento sai com o embalo da mão, até esse limite
const DROP_SPEED := 120.0      # px/s: batendo na mesa mais rápido que isso, faz barulho
const PLUG_BASE := Vector2(0, 20)   # do ponto de referência do plug (topo do corpo) até onde o fio entra nele
## Encaixado, de onde fica a tomada até onde o fio entra: a ponta de metal some dentro dela e o anel assenta no buraco.
const PLUG_SEAT := Vector2(0, 26)
const SHADOW := Color(0, 0, 0, 0.35)
const ROPE_SHADOW := Vector2(3, 4)  # deslocamento da sombra dos fios; a do plug cresce quando ele sai do painel
var _jacks: Array = []

# ---- física dos cabos (corda de Verlet) ----
const ROPE_N := 22                 # pontos por cabo
const GRAVITY := Vector2(0, 1600)  # px/s²
const DAMPING := 0.985             # 1 = sem atrito com o ar
const STIFF_ITER := 14             # iterações de restrição (maior = cabo menos elástico)
const SLACK := 70.0                # folga extra além da distância reta (fio do FONE)
const CORD_SLACK := 14.0           # idem, fios dos cabos de conexão
const FLOOR_Y := 348.0             # o cabo repousa sobre a mesa abaixo do painel
const STEP := 1.0 / 90.0
var ropes := {}                    # ponta -> corda (só enquanto o fio está para fora do buraco)
const SLEEP_STEPS := 30            # passos quase parado até o fio "dormir" (deixa de ser simulado até algo mexer nele)
const SLEEP_MOVE := 0.05           # px por passo: menos que isso conta como parado
var _acc := 0.0
var _last_mouse := Vector2.ZERO   # mouse no último passo da física
var _mouse_vel := Vector2.ZERO    # px/s, para o embalo do plug solto
var _rubbed := 0.0                # px de fio que passaram pelos buracos neste quadro (som de atrito)


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 1 + PATCHES * 2:
		ends.append(-1)
		_order.append(i)


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
	return Vector2(patch_x((e - 1) / 2) + (-14.0 if e % 2 == 1 else 14.0), 280)


## Buraco de onde sai o fio da ponta e (o do FONE sai do alto do encaixe, como sempre).
func hole(e: int) -> Vector2:
	if e == 0:
		return Vector2(home_pos(0).x, socket_rect().position.y)
	return home_pos(e) + PLUG_BASE + Vector2(0, 2)


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
	_loose.erase(e)
	_raise(e)
	Sfx.play("plug_in")
	end_changed.emit(e, j, -1)
	return true


## A ponta e passa a ser desenhada por cima das outras.
func _raise(e: int) -> void:
	_order.erase(e)
	_order.append(e)


func pick_up(e: int) -> void:
	var prev: int = ends[e]
	ends[e] = -1
	held = e
	_raise(e)
	Sfx.play("plug_out")
	if prev != -1:
		end_changed.emit(e, -1, prev)


## Solta o plug: ele cai e o fio o puxa de volta para o buraco (o FONE volta ao telefone).
func go_home(e: int) -> void:
	var from := _plug_base(e)
	var fling := _mouse_vel.limit_length(MAX_FLING) if held == e else Vector2.ZERO
	var prev: int = ends[e]
	ends[e] = -1
	if held == e:
		held = -1
	if from.distance_to(_rest(e)) > 2.0:
		if not ropes.has(e):
			_new_rope(e, from)
		# acima do buraco o fio já puxa, esticado, e o plug vai direto para ele (sem cair no chão antes);
		# fora disso ele cai, com o embalo da mão, antes de o fio recolher
		var direct := from.y < hole(e).y and absf(from.x - hole(e).x) < NEAR_HOLE
		_loose[e] = {"t": FALL_SEC if direct else 0.0, "seat": -1.0, "direct": direct}
		var r: Dictionary = ropes[e]
		if direct:
			r["len"] = minf(r["len"], from.distance_to(hole(e)))
		else:
			r["old"][ROPE_N - 1] = from - fling * STEP
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
	cursor = pos
	_press_pos = pos
	var e := _plug_under(pos)
	if e != -1:
		_loose.erase(e)
		pick_up(e)
		return
	var j := jack_at(pos)
	if j == -1:
		j = _top_at(pos)
	if j != -1:
		info_requested.emit(j)   # tomada vazia ou plaqueta da linha: mostra o que é


## A ponta cujo plug está em p (-1 = nenhuma), o de cima primeiro: guardado, solto voltando ou encaixado.
func _plug_under(p: Vector2) -> int:
	for i in range(_order.size() - 1, -1, -1):
		var e: int = _order[i]
		if e != held and _plug_hit(e, p):
			return e
	return cord_at(jack_at(p))


## A linha (1–10) cuja plaqueta está em p, ou -1.
func _top_at(p: Vector2) -> int:
	for i in 10:
		if top_rect(i).has_point(p):
			return i + 1
	return -1


## Cursor conforme o que está sob o mouse: mão aberta num plug que pode ser pego, fechada segurando
## (proibido sobre uma tomada que não o aceita), dedo no que mostra informação ao clicar.
func _cursor_shape(p: Vector2) -> CursorShape:
	if held != -1:
		var j := jack_at(p)
		return CURSOR_FORBIDDEN if j != -1 and refuse(held, j) != "" else CURSOR_DRAG
	if _hover != -1:
		return CURSOR_MOVE
	if jack_at(p) != -1 or _top_at(p) != -1:
		return CURSOR_POINTING_HAND
	return CURSOR_ARROW


## Arrastar e soltar encaixa na tomada; soltar fora dela, ou clicar sem arrastar (desplugar), solta o plug.
## Mexer uns pixels (mouse tremendo, toque no trackpad) ainda conta como clique.
func _release(pos: Vector2) -> void:
	if held == -1:
		return
	var j := jack_at(pos)
	if pos.distance_to(_press_pos) < 6.0 or j == -1 or not place(held, j):
		go_home(held)


func _process(delta: float) -> void:
	var mouse := get_local_mouse_position()
	if held != -1:
		cursor = mouse
	if delta > 0.0:
		_mouse_vel = _mouse_vel.lerp((mouse - _last_mouse) / delta, 0.5)
	_hover = -1 if held != -1 else _plug_under(mouse)
	mouse_default_cursor_shape = _cursor_shape(mouse)
	_acc = minf(_acc + delta, STEP * 6)
	while _acc >= STEP:
		_acc -= STEP
		for e in ends.size():
			_step_rope(e, STEP)
		_last_mouse = get_local_mouse_position()
	if delta > 0.0:
		Sfx.cord_rub(_rubbed / delta)
	_rubbed = 0.0
	queue_redraw()


## Onde o fio entra no plug.
func _plug_base(e: int) -> Vector2:
	if held == e:
		return cursor + PLUG_BASE
	if ends[e] != -1:
		return jack_rect(int(ends[e])).get_center() + PLUG_SEAT
	if _loose.has(e):
		var an: Dictionary = _loose[e]
		if an["seat"] >= 0.0:
			return (an["from"] as Vector2).lerp(_rest(e), an["seat"])
		return ropes[e]["pts"][ROPE_N - 1]
	return _rest(e)


## O plug da ponta e está no ponto p (guardado, vale a base inteira; fora dela, o desenho do plug).
func _plug_hit(e: int, p: Vector2) -> bool:
	if ends[e] == -1 and not _loose.has(e):
		return home_rect(e).has_point(p)
	var q := (p - _plug_base(e)).rotated(-_plug_angle(e))
	return _plug_rect(ends[e] != -1).grow(2.0).has_point(q)


## Contorno do plug a partir de onde o fio entra nele (em pé); encaixado, sem a ponta de metal.
func _plug_rect(seated: bool) -> Rect2:
	return Rect2(-7, -27, 14, 27) if seated else Rect2(-7, -42, 14, 42)


## Onde o fio entra no plug guardado.
func _rest(e: int) -> Vector2:
	return home_pos(e) + PLUG_BASE


## Inclinação do plug: em pé, menos quando solto (segue o fio, que sai da traseira dele).
func _plug_angle(e: int) -> float:
	if not _loose.has(e):
		return 0.0
	var an: Dictionary = _loose[e]
	if an["seat"] >= 0.0:
		return lerp_angle(an["ang"], 0.0, an["seat"])
	return _cord_angle(e)


func _cord_angle(e: int) -> float:
	var pts: PackedVector2Array = ropes[e]["pts"]
	var d := pts[ROPE_N - 1] - pts[ROPE_N - 4]
	return 0.0 if d.length_squared() < 1.0 else d.angle() + PI / 2


func _new_rope(e: int, to: Vector2) -> void:
	var a := hole(e)
	var init := PackedVector2Array()
	for i in ROPE_N:
		init.append(a.lerp(to, float(i) / (ROPE_N - 1)))
	ropes[e] = {"pts": init, "old": init.duplicate(), "len": a.distance_to(to)}


## Simula o fio da ponta e como uma corda presa no buraco: os pontos têm inércia e gravidade e a distância
## entre eles é mantida. A outra ponta segue o plug; solto, o plug é a última conta da corda (cai) e o
## comprimento encolhe até ele assentar no buraco.
func _step_rope(e: int, dt: float) -> void:
	if held != e and ends[e] == -1 and not _loose.has(e):
		ropes.erase(e)   # o fio está todo dentro do buraco
		return
	var a := hole(e)
	if not ropes.has(e):
		_new_rope(e, _plug_base(e))
	var r: Dictionary = ropes[e]
	var pts: PackedVector2Array = r["pts"]
	var old: PackedVector2Array = r["old"]
	var last := ROPE_N - 1
	var length: float = r["len"]
	var an: Dictionary = _loose.get(e, {})
	var free: bool = not an.is_empty() and an["seat"] < 0.0
	if free:
		an["t"] += dt
		if an["t"] > FALL_SEC:
			length = maxf(length - PULL_SPEED * dt, 0.0)
	elif not an.is_empty():
		an["seat"] += dt / SEAT_SEC
		if an["seat"] >= 1.0:
			_loose.erase(e)
			ropes.erase(e)
			Sfx.play("thump", -14.0)
			return
		length = a.distance_to(_plug_base(e))
	else:
		length = lerpf(length, a.distance_to(_plug_base(e)) + (SLACK if e == 0 else CORD_SLACK), 0.08)
	var mouse := get_local_mouse_position()
	var mv := mouse - _last_mouse
	var settled := held != e and an.is_empty()
	if r.has("sleep"):
		# dormindo: só volta a simular se a ponta ou o buraco saírem do lugar, ou se o mouse passar mexendo no fio
		var poked: bool = mv.length_squared() > 0.5 and (r["sleep"] as Rect2).has_point(mouse)
		if settled and pts[0] == a and pts[last] == _plug_base(e) and not poked:
			return
		r.erase("sleep")
	var seg := length / last
	# inércia + gravidade
	var moving := last + 1 if free else last
	var direct: bool = free and an["direct"]
	for i in range(1, moving):
		var v := (pts[i] - old[i]) * DAMPING
		old[i] = pts[i]
		if direct:
			pts[i] += v * 0.5   # puxado direto: fio esticado, sem gravidade e quase sem embalo (o plug não pendula)
			continue
		pts[i] += v + GRAVITY * dt * dt
		if i == last and pts[i].y > FLOOR_Y and v.y > DROP_SPEED * dt:
			Sfx.play("drop")   # o plug solto bate na mesa
		# passar o mouse por cima do fio empurra o fio
		if held != e and mv.length_squared() > 0.5 and pts[i].distance_to(mouse) < 16.0:
			pts[i] += mv * 0.35
	pts[0] = a
	if not free:
		pts[last] = _plug_base(e)
		old[last] = pts[last]
	# restrições de comprimento
	for _it in STIFF_ITER:
		for i in last:
			var d := pts[i + 1] - pts[i]
			var l := d.length()
			if l < 0.0001:
				continue
			var corr := d * ((l - seg) / l)
			if i == 0:
				pts[i + 1] -= corr
			elif i + 1 == last and not free:
				pts[i] += corr
			else:
				pts[i] += corr * 0.5
				pts[i + 1] -= corr * 0.5
		for i in range(1, moving):
			if pts[i].y > FLOOR_Y:   # o fio do FONE também repousa na fresta entre a mesa e o telefone
				pts[i].y = FLOOR_Y
				old[i].x = lerpf(old[i].x, pts[i].x, 0.3)   # atrito com a mesa
	r["pts"] = pts
	r["old"] = old
	_rubbed += absf(length - float(r["len"]))   # fio entrando ou saindo do buraco
	r["len"] = length
	var moved := 0.0
	for i in range(1, last):
		moved = maxf(moved, pts[i].distance_squared_to(old[i]))
	r["calm"] = r.get("calm", 0) + 1 if settled and moved < SLEEP_MOVE * SLEEP_MOVE else 0
	if r["calm"] > SLEEP_STEPS:
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		r["sleep"] = box.grow(16.0)   # área onde o mouse acorda o fio
	if free and length <= SEAT_LEN:
		an["seat"] = 0.0
		an["from"] = pts[last]
		an["ang"] = _cord_angle(e)


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
		for e in [1 + k * 2, 2 + k * 2]:   # os dois buracos de onde saem os fios
			var hp := hole(e)
			draw_rect(Rect2(hp.x - 7, hp.y - 4, 14, 8), Color("050403"))
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

	# cada ponta (fio e plug) na ordem em que foi mexida: o fio da mais recente passa por cima dos plugs das
	# outras (o da mão inclusive); as sombras antes, por baixo de tudo
	for e in _order:
		_draw_rope(e, true)
		_draw_plug(e, true)
	for e in _order:
		_draw_rope(e, false)
		_draw_plug(e, false)

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


func _draw_rope(e: int, shadow: bool) -> void:
	if not ropes.has(e):
		return
	var pts: PackedVector2Array = ropes[e]["pts"]
	if shadow:
		var sh := PackedVector2Array()
		for q in pts:
			sh.append(q + ROPE_SHADOW)
		draw_polyline(sh, SHADOW, 7.0)
		return
	var col: Array = _cable_col(e)
	draw_polyline(pts, Color.BLACK, 8.0)
	draw_polyline(pts, col[0], 5.0)
	var pts2 := PackedVector2Array()
	for q in pts:
		pts2.append(q + Vector2(-1, -1))
	draw_polyline(pts2, col[1], 1.5)


## Plug em pé, a partir de onde o fio entra nele: corpo na cor do cabo, anel de latão e ponta de metal (com o
## risco que separa ponta e anel, como num plug de mesa telefônica). Encaixado, a ponta está dentro da tomada.
## Girado quando solto. A sombra é o contorno, mais longe quanto mais o plug sai do painel (na mão, mais).
func _draw_plug(e: int, shadow: bool) -> void:
	var seated: bool = ends[e] != -1
	var at := _plug_base(e)
	if shadow:
		at += Vector2(8, 10) if held == e else (Vector2(4, 5) if _loose.has(e) else Vector2(2, 2))
	draw_set_transform(at.round(), _plug_angle(e))
	if shadow:
		draw_rect(_plug_rect(seated), SHADOW)
	else:
		var col: Array = _cable_col(e)
		if e == _hover:   # contorno claro: dá para pegar
			draw_rect(_plug_rect(seated).grow(2.0), Pal.GLOW)
		draw_rect(Rect2(-7, -22, 14, 22), Color.BLACK)
		draw_rect(Rect2(-5, -20, 10, 18), col[0])
		draw_rect(Rect2(-5, -20, 3, 18), col[1])
		draw_rect(Rect2(-6, -27, 12, 5), Color.BLACK)   # anel
		draw_rect(Rect2(-5, -26, 10, 3), Color("8a6a32"))
		if not seated:
			draw_rect(Rect2(-4, -42, 8, 15), Color.BLACK)   # ponta de metal
			draw_rect(Rect2(-3, -41, 6, 14), Color("d9b56a"))
			draw_rect(Rect2(-3, -41, 2, 14), Color("f0d79a"))
			draw_rect(Rect2(-3, -34, 6, 1), Color("5a4520"))
	draw_set_transform(Vector2.ZERO)


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
