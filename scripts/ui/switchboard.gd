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
## Destinos em três bancos de tomadas, A, B e C, cada um com uma faixa de numeração (100–199, 200–299, 300–399), em
## duas fileiras. A mesa saiu de fábrica assim; a faixa coincide com o setor da cidade (o primeiro dígito), e o banco
## de um setor que ainda não é do operador fica tampado por uma chapa com a letra dele (`GameData.sectors`).
const SECTOR_ORDER := [1, 2, 3]
const DEST_PITCH := 29.0     # px entre duas tomadas de destino vizinhas
const BLOCK_GAP := 12.0      # px entre dois blocos
const DEST_TOP := 182.0      # topo das tomadas da primeira fileira (a segunda fica DEST_ROW px abaixo)
const DEST_ROW := 44.0
const SIZE := Vector2(588, 334)
const FONE_HOME := Vector2(18, 24)   # posição do plug do FONE dentro do encaixe

var _lit := {}   ## lâmpada ("l3" linha, "d312" destino) -> [cor, quanto está acesa 0..1]; a cor fica enquanto apaga
var exchange: Exchange
var fone_socket: Control       # encaixe do FONE no painel do telefone
var dest_nums: Array = []      # destinos em serviço (dos setores atendidos)
var _slots := {}               # número -> centro da tomada (de todos os setores, atendidos ou não)
var _blocks := {}              # setor -> retângulo do bloco
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
const TAP_SPEED := Vector2(150.0, 600.0)   # px/s: o fio batendo na mesa faz "tap" a partir de x; em y, no volume máximo
const TAP_GAP := 0.12          # s: intervalo mínimo entre dois "taps" do mesmo fio
const PLUG_BASE := Vector2(0, 20)   # do ponto de referência do plug (topo do corpo) até onde o fio entra nele
## Encaixado, de onde fica a tomada até onde o fio entra: a ponta de metal some dentro dela e o anel assenta no buraco.
const PLUG_SEAT := Vector2(0, 26)
const SHADOW := Color(0, 0, 0, 0.35)
const PLATE := Color("4d483d")   # chapa sobre o banco que ainda não está em uso
const LAMP_R := 4.5         # raio do vidro da lâmpada de cada linha (o aro de metal fica em volta)
const JACK := 22.0          # diâmetro de todos os encaixes (entradas, saídas e destinos)
## A coluna de cada linha, de cima para baixo: plaquinha com o número (topo e altura), estado (linha de base do texto),
## lâmpada, entrada e saída (centros). O estado fica acima da lâmpada: embaixo da entrada, o plug encaixado o cobria.
const ROW_Y := {"plate": 34.0, "plate_h": 17.0, "state": 62.0, "lamp": 76.0, "in": 101.0, "out": 131.0}
const STATE_FONT := 8       # o estado da linha ("conectada" em 11 não cabe na coluna): exceção à regra dos múltiplos de 11
const BEZEL := [Color("d6d1c3"), Color("8e897c"), Color("45413a")]   # aro niquelado: luz, meio, sombra
const LAMP_OFF := Color("2a2016")   # o vidro da lâmpada apagada
const LAMP_ON_SEC := 0.06    # a lâmpada (de filamento) acende quase na hora...
const LAMP_OFF_SEC := 0.18   # ...e apaga mais devagar, o filamento esfriando: a linha tocando pulsa em vez de piscar seco
const ROPE_SHADOW := Vector2(3, 4)  # deslocamento da sombra dos fios; a do plug cresce quando ele sai do painel
var _jacks: Array = []

# ---- física dos cabos (corda de Verlet) ----
const ROPE_N := 22                 # pontos por cabo
const GRAVITY := Vector2(0, 1600)  # px/s²
const DAMPING := 0.985             # 1 = sem atrito com o ar
const STIFF_ITER := 14             # iterações de restrição (maior = cabo menos elástico)
const SLACK := 70.0                # folga extra além da distância reta (fio do FONE)
const CORD_SLACK := 14.0           # idem, fios dos cabos de conexão
const FLOOR_Y := 354.0             # o cabo repousa sobre a mesa abaixo do painel
const STEP := 1.0 / 90.0
var ropes := {}                    # ponta -> corda (só enquanto o fio está para fora do buraco)
const SLEEP_STEPS := 30            # passos quase parado até o fio "dormir" (deixa de ser simulado até algo mexer nele)
const SLEEP_MOVE := 0.05           # px por passo: menos que isso conta como parado
var _acc := 0.0
var _last_mouse := Vector2.ZERO   # mouse no último passo da física
var _mouse_vel := Vector2.ZERO    # px/s, para o embalo do plug solto
# fio que passou pelos buracos neste quadro, para o som de atrito (px): saindo, entrando, e somas pesadas por px
# do lugar do buraco na tela (0..1) e do que era o fio do FONE
var _rub_out := 0.0
var _rub_in := 0.0
var _rub_x := 0.0
var _rub_fone := 0.0


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
	_layout_dests()


## Posição de cada tomada de destino: blocos lado a lado, centralizados na mesa.
func _layout_dests() -> void:
	var by_sector := {}
	for e in GameData.CONTENT.directory:
		if not e.dispatch_only:
			var s := int(e.number.left(1))
			if not by_sector.has(s):
				by_sector[s] = []
			by_sector[s].append(int(e.number))
	var cols := SECTOR_ORDER.map(func(s): return ceili(by_sector.get(s, []).size() / 2.0))
	var total: float = cols.reduce(func(a, c): return a + c, 0) * DEST_PITCH + BLOCK_GAP * (SECTOR_ORDER.size() - 1)
	var x := (SIZE.x - total) / 2.0
	for k in SECTOR_ORDER.size():
		var s: int = SECTOR_ORDER[k]
		var nums: Array = by_sector.get(s, [])
		nums.sort()
		for i in nums.size():
			_slots[nums[i]] = Vector2(x + (i % cols[k]) * DEST_PITCH + DEST_PITCH / 2.0, DEST_TOP + 11.0 + int(i / cols[k]) * DEST_ROW)
		_blocks[s] = Rect2(x - 3, DEST_TOP - 21, cols[k] * DEST_PITCH + 6, DEST_ROW + 43)
		x += cols[k] * DEST_PITCH + BLOCK_GAP


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
	var c: Vector2
	if j <= 10:
		c = Vector2(col_x(j - 1), ROW_Y["in"])
	elif j <= 20:
		c = Vector2(col_x(j - 11), ROW_Y["out"])
	else:
		c = _slots.get(j, Vector2.ZERO)
	return Rect2(c - Vector2(JACK, JACK) / 2.0, Vector2(JACK, JACK))


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
	return Vector2(patch_x((e - 1) / 2) + (-14.0 if e % 2 == 1 else 14.0), 284)


## Buraco de onde sai o fio da ponta e (o do FONE sai do alto do encaixe, como sempre).
func hole(e: int) -> Vector2:
	if e == 0:
		return Vector2(home_pos(0).x, socket_rect().position.y)
	return home_pos(e) + PLUG_BASE + Vector2(0, 2)


func home_rect(e: int) -> Rect2:
	if e == 0:
		return socket_rect()
	var h := home_pos(e)
	return Rect2(h.x - 12, 262, 24, 50)


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
		_sfx("click", jack_rect(j).get_center())
		return false
	ends[e] = j
	held = -1
	_loose.erase(e)
	_raise(e)
	_sfx("plug_in", jack_rect(j).get_center())
	end_changed.emit(e, j, -1)
	return true


## A ponta e passa a ser desenhada por cima das outras.
func _raise(e: int) -> void:
	_order.erase(e)
	_order.append(e)


func pick_up(e: int) -> void:
	_sfx("plug_out", _plug_base(e))
	var prev: int = ends[e]
	ends[e] = -1
	held = e
	_raise(e)
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
		_sfx("thump", from, -14.0)
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
	var moved := _rub_out + _rub_in
	if delta > 0.0 and moved > 0.0:
		Sfx.cord_rub(moved / delta, _rub_x / moved, _rub_out / moved, _rub_fone / moved)
	else:
		Sfx.cord_rub(0.0)
	_rub_out = 0.0
	_rub_in = 0.0
	_rub_x = 0.0
	_rub_fone = 0.0
	if exchange != null:
		var ms := Time.get_ticks_msec()
		for n in range(1, 11):
			_fade("l%d" % n, _lamp(exchange.line(n), ms, fone_line() == n), delta)
		for d in dest_nums:
			_fade("d%d" % d, _dest_lamp(exchange.dest(d), ms), delta)
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


## Onde fica o ponto p da mesa na tela, de 0 (borda esquerda) a 1 (direita): os sons vêm daquele lado.
func screen_x(p: Vector2) -> float:
	return (get_global_transform_with_canvas() * p).x / get_viewport_rect().size.x


## Som da mesa vindo do ponto p.
func _sfx(id: String, p: Vector2, db: float = 0.0) -> void:
	Sfx.play_at(id, screen_x(p), db)


## `d` px do fio da ponta e passaram pelo buraco (positivo: saindo; negativo: entrando), para o som de atrito.
func _count_rub(e: int, d: float) -> void:
	if d > 0.0:
		_rub_out += d
	else:
		_rub_in -= d
	_rub_x += absf(d) * screen_x(hole(e))
	if e == 0:
		_rub_fone += absf(d)


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
			_sfx("thump", a, -14.0)
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
	var tap := 0.0   # a batida mais forte de um ponto do fio na mesa, neste passo (px/passo), e onde
	var tap_at := Vector2.ZERO
	var direct: bool = free and an["direct"]
	for i in range(1, moving):
		var v := (pts[i] - old[i]) * DAMPING
		old[i] = pts[i]
		if direct:
			pts[i] += v * 0.5   # puxado direto: fio esticado, sem gravidade e quase sem embalo (o plug não pendula)
			continue
		pts[i] += v + GRAVITY * dt * dt
		if pts[i].y > FLOOR_Y:
			if i == last:
				if v.y > DROP_SPEED * dt:
					_sfx("drop", pts[i])   # o plug solto bate na mesa
			elif v.y > tap:
				tap = v.y
				tap_at = pts[i]
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
	_count_rub(e, length - float(r["len"]))
	r["tap"] = maxf(float(r.get("tap", 0.0)) - dt, 0.0)
	if tap > TAP_SPEED.x * dt and r["tap"] == 0.0:   # o fio caiu ou chicoteou na mesa
		var k := clampf((tap / dt - TAP_SPEED.x) / (TAP_SPEED.y - TAP_SPEED.x), 0.0, 1.0)
		_sfx("cord_tap", tap_at, lerpf(-12.0, 0.0, k))
		r["tap"] = TAP_GAP
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
		_sfx("cord_stop", a)   # o fio terminou de entrar
		an["seat"] = 0.0
		an["from"] = pts[last]
		an["ang"] = _cord_angle(e)


# ------------------------------------------------------------------ desenho

## Cor da lâmpada de uma linha (Exchange.Line) e quanto ela quer estar acesa (0..1); `_fade` chega lá aos poucos.
func _lamp(st: int, ms: int, steady: bool) -> Array:
	match st:
		Exchange.Line.RING:
			return [Pal.AMBER, 1.0 if steady or (ms / 250) % 2 == 0 else 0.0]
		Exchange.Line.TALK:
			return [Pal.AMBER, 1.0]
		Exchange.Line.HOLD:
			return [Pal.AMBER, 1.0 if (ms / 800) % 2 == 0 else 0.45]
		Exchange.Line.CONN:
			return [Pal.GREEN, 1.0]
		Exchange.Line.DONE:
			return [Pal.RED, 1.0]
	return [LAMP_OFF, 0.0]


## Os estados de destino (Exchange.Dest) acendem como os de linha equivalentes.
func _dest_lamp(st: int, ms: int) -> Array:
	match st:
		Exchange.Dest.RING:
			return _lamp(Exchange.Line.RING, ms, false)
		Exchange.Dest.CONN:
			return [Pal.GREEN, 1.0]
		Exchange.Dest.DONE:
			return [Pal.RED, 1.0]
	return [LAMP_OFF, 0.0]


## A lâmpada `key` vai para `want` ([cor, nível]): acende em `LAMP_ON_SEC`, apaga em `LAMP_OFF_SEC`, mantendo a cor.
func _fade(key: String, want: Array, delta: float) -> void:
	var cur: Array = _lit.get(key, [want[0], 0.0])
	if want[1] > 0.0:
		cur[0] = want[0]
	var lv: float = cur[1]
	cur[1] = move_toward(lv, want[1], delta / (LAMP_ON_SEC if want[1] > lv else LAMP_OFF_SEC))
	_lit[key] = cur


## Lâmpada redonda com aro de metal (luz no alto à esquerda, sombra embaixo à direita; acesa, o aro pega a cor dela),
## assento preto e o vidro, que vai do escuro à cor da linha conforme `level`. Acesa, brilha (`Bloom`); apagada, só
## um reflexo fraco no vidro.
func _draw_lamp(c: Vector2, col: Color, level: float) -> void:
	draw_circle(c, LAMP_R + 3.5, Color.BLACK)
	draw_circle(c, LAMP_R + 2.5, BEZEL[2])
	draw_circle(c - Vector2(0.6, 0.6), LAMP_R + 1.9, BEZEL[0])
	draw_circle(c, LAMP_R + 1.5, BEZEL[1])
	draw_circle(c, LAMP_R + 1.5, Color(col, 0.3 * level))   # a luz batendo no metal
	draw_circle(c, LAMP_R + 0.5, Color.BLACK)   # o assento do vidro
	draw_circle(c, LAMP_R, LAMP_OFF.lerp(col, level))
	if level > 0.02:
		Bloom.light(self, Rect2(c - Vector2(LAMP_R, LAMP_R), Vector2(LAMP_R, LAMP_R) * 2.0), Color(col, level), 1.0, true, true)
	if level < 0.5:
		draw_circle(c - Vector2(LAMP_R, LAMP_R) * 0.45, 1.0, Color(1, 1, 1, 0.15 * (1.0 - level)))


## Encaixe redondo como os das mesas antigas: bucha de metal com a aba chanfrada (luz no alto à esquerda, sombra embaixo
## à direita), a parede de dentro rebaixada (côncava: a sombra no alto, a luz embaixo) e o furo escuro no meio.
func _draw_jack(jr: Rect2, rim: Color = Pal.BRASS) -> void:
	var c := jr.get_center()
	var r := jr.size.x / 2.0
	draw_circle(c + Vector2(1, 1.5), r, Color(0, 0, 0, 0.35))   # sombra no painel
	draw_circle(c, r, Color.BLACK)
	draw_circle(c, r - 1.0, rim.darkened(0.45))
	draw_circle(c - Vector2(0.8, 0.8), r - 1.8, rim.lightened(0.3))
	draw_circle(c, r - 2.2, rim)
	var wall := r * 0.62
	draw_circle(c, wall, rim.lightened(0.15))
	draw_circle(c - Vector2(0.8, 0.8), wall - 0.7, rim.darkened(0.4))
	draw_circle(c, r * 0.4, Color("050403"))   # o furo


## A luz de uma lâmpada batendo na aba do encaixe logo abaixo dela (o lado de cima, virado para a luz).
func _reflect(jr: Rect2, col: Color, level: float) -> void:
	if level > 0.02:
		draw_arc(jr.get_center(), jr.size.x / 2.0 - 1.6, PI * 1.15, PI * 1.85, 12, Color(col, 0.55 * level), 1.5)


func _draw() -> void:
	Bloom.clear(self)
	var w := size.x
	var h := size.y
	var ms := Time.get_ticks_msec()
	draw_rect(Rect2(Vector2.ZERO, size), Pal.EDGE)
	draw_rect(Rect2(3, 3, w - 6, h - 6), Pal.PANEL)
	draw_rect(Rect2(3, 3, w - 6, 3), Pal.PANEL_HI)
	draw_rect(Rect2(3, 3, 3, h - 6), Pal.PANEL_HI)
	draw_rect(Rect2(3, h - 6, w - 6, 3), Pal.PANEL_LO)
	draw_rect(Rect2(w - 6, 3, 3, h - 6), Pal.PANEL_LO)
	draw_string(Pal.mono, Vector2(17, 28), T.text(T.Key.BOARD_TITLE), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.BRASS)
	draw_string(Pal.ui, Vector2(17, 26), T.text(T.Key.BOARD_LEGEND), HORIZONTAL_ALIGNMENT_RIGHT, w - 34, 11, Pal.DIM)
	if exchange == null:
		return

	# entradas e saídas
	for i in 10:
		var n := i + 1
		var st := exchange.line(n)
		var cx := col_x(i)
		_draw_number_plate(Rect2(cx - 18, ROW_Y["plate"], 36, ROW_Y["plate_h"]), "%02d" % n)
		var lt: Array = _lit.get("l%d" % n, [LAMP_OFF, 0.0])
		_draw_lamp(Vector2(cx, ROW_Y["lamp"]), lt[0], lt[1])
		_draw_jack(jack_rect(n))
		_reflect(jack_rect(n), lt[0], lt[1])
		var sc := Pal.DIM
		if st in [Exchange.Line.RING, Exchange.Line.TALK, Exchange.Line.HOLD]:
			sc = Pal.AMBER
		elif st == Exchange.Line.DONE:
			sc = Pal.RED
		draw_string(Pal.ui, Vector2(cx - 28, ROW_Y["state"]), exchange.line_label(n), HORIZONTAL_ALIGNMENT_CENTER, 56, STATE_FONT, sc)
		_draw_jack(jack_rect(n + 10), Color("7a6230"))

	# destinos: a faixa de numeração do banco fica sobre a linha divisória, como rótulo da seção
	draw_rect(Rect2(12, 151, w - 24, 2), Pal.PANEL_LO)
	for s in _blocks:
		var br: Rect2 = _blocks[s]
		var cap := "%d–%d" % [s * 100, s * 100 + 99]
		draw_rect(Rect2(br.position.x, 144, Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 8, 15), Pal.PANEL)
		draw_string(Pal.ui, Vector2(br.position.x + 4, 156), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.DIM)
		draw_rect(br, Pal.PANEL_LO, false, 1.0)
	for d in dest_nums:
		var jr := jack_rect(d)
		var cx := jr.get_center().x
		var st := exchange.dest(d)
		draw_string(Pal.mono, Vector2(cx - 16, jr.position.y - 5), str(d), HORIZONTAL_ALIGNMENT_CENTER, 32, 11, Color("d8c9a2") if st == Exchange.Dest.FREE else Pal.TEXT)
		var dl: Array = _lit.get("d%d" % d, [LAMP_OFF, 0.0])
		if dl[1] > 0.02:   # o aro em volta da tomada acende
			draw_circle(jr.get_center(), jr.size.x / 2.0 + 3.0, Color(dl[0], dl[1]))
			Bloom.light(self, jr.grow(3), Color(dl[0], dl[1]), 1.0, false, true)
		_draw_jack(jr)
	for s in _blocks:
		if not s in GameData.sectors:
			_draw_plate(_blocks[s], "ABC"[SECTOR_ORDER.find(s)])

	# base dos cabos de conexão
	draw_rect(Rect2(12, 254, w - 24, 2), Pal.PANEL_LO)
	for k in PATCHES:
		var cx := patch_x(k)
		draw_rect(Rect2(cx - 30, 302, 60, 14), Color.BLACK)
		draw_rect(Rect2(cx - 28, 304, 56, 10), Color("1b1812"))
		for e in [1 + k * 2, 2 + k * 2]:   # os dois buracos de onde saem os fios
			var hp := hole(e)
			draw_rect(Rect2(hp.x - 7, hp.y - 4, 14, 8), Color("050403"))
		draw_string(Pal.mono, Vector2(cx - 30, 326), T.text(T.Key.BOARD_CORD) % (k + 1), HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Pal.BRASS)
	# legenda
	var leg := [[Pal.AMBER, T.Key.LEGEND_RING], [Pal.GREEN, T.Key.LEGEND_CONN], [Pal.RED, T.Key.LEGEND_DONE], [LAMP_OFF, T.Key.LEGEND_FREE]]
	for k in leg.size():
		var y := 270 + k * 18
		draw_circle(Vector2(413, y - 5), 5.5, Color.BLACK)   # lâmpadas redondas, como as da mesa
		draw_circle(Vector2(413, y - 5), 4.0, leg[k][0])
		draw_string(Pal.ui, Vector2(424, y), T.text(leg[k][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.DIM)

	# destaque da tomada sob o plug
	if held != -1:
		var hj := jack_at(get_local_mouse_position())
		if hj != -1:
			var ok := refuse(held, hj) == ""
			var hr := jack_rect(hj)
			draw_arc(hr.get_center(), hr.size.x / 2.0 + 4.0, 0.0, TAU, 32, Pal.GLOW if ok else Pal.RED, 2.0)
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
			draw_string(Pal.mono, Vector2(bx + 10, by + 22 + k * 19), info_lines[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.GHOST if info_ghost else Pal.TEXT)


## Plaquinha de metal niquelado com o número da linha gravado (escuro, com o brilho embaixo de quem foi rebaixado),
## chanfro claro em cima e escuro embaixo, e um rebite de cada lado. O número fica centrado pela medida da fonte.
func _draw_number_plate(r: Rect2, text: String) -> void:
	draw_rect(r.grow(1), Color.BLACK)
	draw_rect(r, BEZEL[1])
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), BEZEL[0])
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), BEZEL[0].darkened(0.1))
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), BEZEL[2])
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), BEZEL[2].lightened(0.1))
	for x in [r.position.x + 3.5, r.end.x - 3.5]:   # rebites
		draw_circle(Vector2(x, r.get_center().y), 1.5, BEZEL[2])
		draw_circle(Vector2(x - 0.4, r.get_center().y - 0.4), 0.8, BEZEL[0])
	var size := Pal.mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	var at := Vector2(roundf(r.get_center().x - size.x / 2.0), roundf(r.get_center().y + (Pal.mono.get_ascent(11) - Pal.mono.get_descent(11)) / 2.0))
	draw_string(Pal.mono, at + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BEZEL[0])   # o brilho do rebaixo
	draw_string(Pal.mono, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("1d1a14"))


## Chapa parafusada sobre um banco que ainda não está em uso, com a letra dele (A, B, C).
func _draw_plate(r: Rect2, letter: String) -> void:
	draw_rect(r.grow(1), Color.BLACK)
	draw_rect(r, PLATE)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), PLATE.lightened(0.18))
	draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), PLATE.darkened(0.35))
	for c in [r.position + Vector2(7, 7), Vector2(r.end.x - 7, r.position.y + 7), Vector2(r.position.x + 7, r.end.y - 7), r.end - Vector2(7, 7)]:
		draw_circle(c, 3.5, PLATE.darkened(0.45))
		draw_circle(c, 2.5, PLATE.lightened(0.25))
		draw_line(c - Vector2(2, 0), c + Vector2(2, 0), PLATE.darkened(0.45), 1.0)   # fenda do parafuso
	draw_string(Pal.mono, Vector2(r.position.x, r.get_center().y + 10), letter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, PLATE.lightened(0.35))


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
		if e == _hover:   # contorno claro: dá para pegar
			draw_rect(_plug_rect(seated).grow(2.0), Pal.GLOW)
		_draw_plug_body(_cable_col(e), seated)
	draw_set_transform(Vector2.ZERO)


## O plug, de pé, com o fio saindo de baixo (y = 0): cabo de baquelite na cor do cabo (sombreado de cilindro, dois sulcos
## de pegada e a ponteira de onde sai o fio), colar niquelado e, solto, a ponta de três partes dos plugues de mesa
## (bico e anel niquelados, luva de latão, faixas isolantes pretas entre elas). Encaixado, a ponta some no furo e uma
## aba redonda niquelada assenta sobre o encaixe. Luz no alto à esquerda, como no resto da mesa.
func _draw_plug_body(col: Array, seated: bool) -> void:
	var base: Color = col[0]
	var hi: Color = col[1]
	var dark := base.darkened(0.4)
	if seated:   # a aba sobre o furo (o centro do encaixe fica em y = -PLUG_SEAT.y)
		var c := Vector2(0, -PLUG_SEAT.y)
		draw_circle(c, 7.5, Color.BLACK)
		draw_circle(c, 6.5, BEZEL[2])
		draw_circle(c - Vector2(0.6, 0.6), 5.8, BEZEL[0])
		draw_circle(c, 5.3, BEZEL[1])
	else:
		draw_rect(Rect2(-4, -42, 8, 15), Color.BLACK)   # contorno da ponta
		draw_circle(Vector2(0, -38.5), 3.5, Color.BLACK)
		draw_rect(Rect2(-3, -33, 6, 6), Color("b8924e"))   # luva de latão
		draw_rect(Rect2(-3, -33, 2, 6), Color("e0c07a"))
		draw_rect(Rect2(2, -33, 1, 6), Color("7a5a24"))
		draw_rect(Rect2(-3, -34, 6, 1), Color("141210"))   # isolante
		draw_rect(Rect2(-3, -37, 6, 3), BEZEL[1])   # anel
		draw_rect(Rect2(-3, -37, 2, 3), BEZEL[0])
		draw_rect(Rect2(-3, -38, 6, 1), Color("141210"))   # isolante
		draw_circle(Vector2(0, -38.5), 2.6, BEZEL[1])   # bico
		draw_rect(Rect2(-2.5, -40, 1.5, 2), BEZEL[0])
	# colar niquelado
	draw_rect(Rect2(-7, -27, 14, 6), Color.BLACK)
	draw_rect(Rect2(-6, -26, 12, 4), BEZEL[1])
	draw_rect(Rect2(-6, -26, 12, 1), BEZEL[0])
	draw_rect(Rect2(-6, -23, 12, 1), BEZEL[2])
	# cabo de baquelite, arredondado nas pontas
	draw_rect(Rect2(-7, -21, 14, 18), Color.BLACK)
	draw_rect(Rect2(-6, -21, 12, 17), base)
	draw_rect(Rect2(-6, -21, 3, 17), hi)
	draw_rect(Rect2(2, -21, 4, 17), dark)
	draw_rect(Rect2(-6, -21, 12, 1), hi.lightened(0.2))
	for y in [-16, -11]:   # sulcos de pegada
		draw_rect(Rect2(-6, y, 12, 1), dark.darkened(0.3))
		draw_rect(Rect2(-6, y + 1, 12, 1), Color(hi, 0.5))
	# ponteira de onde sai o fio
	draw_rect(Rect2(-5, -4, 10, 4), Color.BLACK)
	draw_rect(Rect2(-4, -4, 8, 3), dark)
	draw_rect(Rect2(-4, -4, 2, 3), base)


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
