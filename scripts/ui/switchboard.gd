class_name Switchboard
extends "res://scripts/ui/switchboard_plugs.gd"
## Mesa comutadora.
## - ENTRADAS 01–10: onde as chamadas chegam. O FONE (cabo verde, que sai do telefone) entra aqui para atender.
## - SAÍDAS: uma tomada logo abaixo de cada entrada. Uma ponta do cabo de conexão entra aqui...
## - DESTINOS: ...e a outra ponta no número pedido.
## Os cabos de conexão são poucos (PATCHES): desmontar as conexões encerradas libera cabos.
## Cada ponta tem o próprio fio, que sai de um buraco (dois por cabo de conexão na bandeja, na mesa à frente do painel;
## o do FONE no encaixe).
## Arraste o plug até a tomada (clicar e segurar). Clicar num plug encaixado (sem arrastar),
## ou soltá-lo fora de uma tomada, solta o plug: ele cai e o fio o recolhe para o buraco.
## A mesa não conhece ligações: lê as lâmpadas de `exchange` e avisa por `end_changed` quando um plug muda.
## Desenha por cima dos vizinhos (z_index na cena), porque o encaixe do FONE e a bandeja dos cabos ficam na mesa, fora
## do retângulo do painel (lugares reservados na cena, `setup`).

signal end_changed(end: int, jack: int, prev: int)
signal info_requested(jack: int)
signal warned(text: String)

## Destinos em três bancos de tomadas, A, B e C, cada um com uma faixa de numeração (100–199, 200–299, 300–399), em
## duas fileiras. A mesa saiu de fábrica assim; a faixa coincide com o setor da cidade (o primeiro dígito), e o banco
## de um setor que ainda não é do operador fica tampado por uma chapa com a letra dele (`GameData.sectors`).
const SECTOR_ORDER := [1, 2, 3]
const DEST_PITCH := 29.0     # px entre duas tomadas de destino vizinhas
const BLOCK_GAP := 12.0      # px entre dois blocos

var _pulled := {}   ## ponta -> [segundos desde que saiu do encaixe, onde ele estava]: o plug de frente sumindo
var exchange: Exchange
var dest_nums: Array = []      # destinos em serviço (dos setores atendidos)
var _blocks := {}              # setor -> retângulo do bloco
var _order: Array = []         # ordem de desenho das pontas: a mexida por último fica por cima
var info_lines: PackedStringArray = []
var info_ghost := false
var info_line := -1
var info_until := 0
var _press_pos := Vector2.ZERO
var _dragged := false   # já não é clique: a mão se afastou CLICK_PX de onde apertou ou segurou CLICK_SEC
var _held_for := 0.0    # s segurando desde o clique (tempo real, fora da velocidade do jogo)

const CLICK_PX := 6.0   # apertar e soltar mexendo menos que isso, e mais rápido que CLICK_SEC s, é clique: desplugar,
const CLICK_SEC := 0.25 # não encaixar (segurando parado sobre a tomada de onde o plug saiu, soltar o encaixa de novo)
const FALL_SEC := 0.35         # o plug solto cai livre antes de o fio começar a recolher
const NEAR_HOLE := 45.0        # solto acima do buraco (a qualquer altura) e com essa distância na horizontal, o fio puxa o plug direto (sem cair)
const PULL_SPEED := 480.0      # px/s de fio que entra no buraco
const SEAT_LEN := 2.0          # com o fio curto assim e a traseira do plug a SEAT_NEAR px da boca do buraco, ele assenta
const SEAT_NEAR := 4.0         # (o fio acaba antes de a corda alcançar: o plug ainda arrasta até ali, ou por SEAT_WAIT s)
const SEAT_WAIT := 0.25
## Solto, o ângulo do plug segue o do fio LOOSE_TURN por passo (aos poucos: de pendurado para deitado, ele vira);
## pendurado na quina da prateleira (`Cord.hang_step`), segue o do fio pendurado HANG_TURN por passo.
const LOOSE_TURN := 0.35
const HANG_TURN := 0.25
## Assentando (`_seat_pose`), o fio já entrou todo: com a traseira presa na boca do buraco, o plug gira até ficar em
## pé (SEAT_TURN s para 90°, macio no começo e no fim) e afunda puxado pelo fio, partindo da velocidade com que
## chegou e acelerando SEAT_ACCEL px/s² até bater no fundo, onde quica SEAT_BOB px por SEAT_BOB_SEC s. (Antes, ele
## pulava em 0,1 s, de uma vez e em linha reta, de deitado na mesa para dentro do buraco: parecia travado.)
const SEAT_TURN := 0.14
const MAX_FLING := 1800.0      # px/s: o plug solto em movimento sai com o embalo da mão, até esse limite
const DROP_SPEED := 120.0      # px/s: batendo na mesa mais rápido que isso, faz barulho (mais alto até DROP_FULL)
const DROP_FULL := 700.0
## Na mão, o plug balança com o movimento, preso onde a mão o pega: a traseira (com o fio) fica para trás, como um
## pêndulo. SWING_K rad por px/s da mão na horizontal, no máximo SWING_MAX; mola e amortecimento em SWING_SPRING.
const SWING_K := 0.0006
const SWING_MAX := deg_to_rad(20.0)
const SWING_SPRING := Vector2(160.0, 11.0)
## Passando do fim do fio (`Cord.MAX`), o plug na mão se inclina para onde a mão puxa, inteiro a LEAN_PX px além: a
## traseira, com o fio, fica virada para o buraco (em pé, com o fio chegando de lado, a junção dobrava e o fio passava
## por cima dele).
const LEAN_PX := 40.0
const TAP_SPEED := Vector2(150.0, 600.0)   # px/s: o fio batendo na mesa faz "tap" a partir de x; em y, no volume máximo
const TAP_GAP := 0.12          # s: intervalo mínimo entre dois "taps" do mesmo fio
## O puxão da mão, na direção do buraco para fora (`_pull_edges`): o fio parado que sai rápido dá um tranco
## (`cord_snag`: parado há SNAG_REST s, passa de SNAG_SPEED px/s até SNAG_WINDOW s depois de começar a andar) e o
## puxão rápido que para de repente, um "tsk" de fibra (`cord_snap`: a mão cai para SNAP_DROP do pico, que vale
## acima de SNAG_SPEED e é esquecido em SNAP_MEMORY s; parando devagar, o pico desce junto e não toca).
const SNAG_SPEED := 300.0
const SNAG_REST := 0.15
const SNAG_WINDOW := 0.12
const SNAP_DROP := 0.2
const SNAP_MEMORY := 0.08
const RUB_STILL := 30.0        # px/s: abaixo disso a mão está parada
## Tom do atrito de cada cabo (multiplica o tom e o corte): FONE, vermelho, azul, amarelo. Só uma nuance, para a
## mesa não soar como um fio só.
const CORD_TONE := [1.0, 1.05, 0.95, 1.02]
## Onde o corpo do plug encaixado termina e a capa começa, como fração do comprimento a partir do painel (das
## `PLUG_LEN` linhas do `PLUG_ART` da aba até o fio, 3 de aba e 37 de corpo): a luz da lâmpada bate ali.
const PLUG_BODY_END := 40.0 / 59.0

const SLACK := 70.0                # folga extra além da distância reta (fio do FONE), no máximo...
const SLACK_PER_PX := 0.15         # ...e esta por px de distância na horizontal (logo acima do buraco, sobrava fio deitado na prateleira)
const SLACK_REACH := 0.08         # e todos, ao menos esta fração da distância do buraco ao plug (sem ela, logo acima do buraco, o fio ficava reto com um gancho na ponteira)
const CORD_SLACK := 14.0           # idem, fios dos cabos de conexão
const STEP := 1.0 / 90.0

var _acc := 0.0
var _last_mouse := Vector2.ZERO   # mouse no último passo da física
var _mouse_vel := Vector2.ZERO    # px/s, para o embalo do plug solto
var _taut := false                # o fio do plug na mão está esticado no fim (`Cord.MAX`)
var _hand_was := Vector2.ZERO     # onde o plug na mão (ou o mouse) estava no quadro anterior, para `_mouse_vel`
## Onde a prateleira acaba (`Background.shelf`, em px da tela: x da lateral do console, y do tampo ao pé dele).
## Sem ela (testes sem cenário), a prateleira não tem fim, como antes.
var shelf: Callable
## Os olhos do operador, o ponto de fuga da sala (`Background.eye`, em px da tela); sem ele, `PLUG_EYE`.
var eye: Callable
var _swing_v := 0.0
# fio que passou pelos buracos neste quadro, para o som de atrito (px): saindo, entrando, e somas pesadas por px
# do lugar do buraco na tela (0..1) e do que era o fio do FONE
var _rub_out := 0.0
var _rub_in := 0.0
var _rub_x := 0.0
var _rub_fone := 0.0
var _rub_loose := 0.0
var _rub_tone := 0.0
var _pull_rest := 0.0   # s com a mão parada (ou chegando perto do buraco)
var _pull_run := -1.0   # s desde que a mão começou a puxar (-1: tranco já dado ou fora da janela)
var _pull_top := 0.0    # pico recente do puxão, px/s
var _drawn := []   # o que estava à mostra no último desenho (`_look`)


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 1 + PATCHES * 2:
		ends.append(-1)
		_order.append(i)


func setup(ex: Exchange, socket: Control, cord_tray: Control) -> void:
	exchange = ex
	fone_socket = socket
	tray = cord_tray
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
		# o mesmo vão (8 px) entre a moldura e os números, em cima, e entre a moldura e as tomadas de baixo
		_blocks[s] = Rect2(x - 3, DEST_TOP - 21, cols[k] * DEST_PITCH + 6, DEST_ROW + 50)
		x += cols[k] * DEST_PITCH + BLOCK_GAP


## Os fios repousam na prateleira, na linha dos buracos (os nomes gravados ficam na frente, livres).
func _floor() -> float:
	return tray_rect().position.y + SHELF_HOLE_Y


func _has_point(p: Vector2) -> bool:   # o painel até a prateleira, com o vão entre eles (os plugs guardados passam por ele)
	return Rect2(Vector2.ZERO, size).merge(socket_rect()).merge(tray_rect()).has_point(p)


func place(e: int, j: int) -> bool:
	var why := refuse(e, j)
	if why != "":
		warned.emit(why)
		_sfx("click", jack_rect(j).get_center())
		return false
	_pushed_ang[e] = _plug_angle(e)
	ends[e] = j
	held = -1
	_loose.erase(e)
	_raise(e)
	_pushed[e] = 0.0
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
	_unseat(e)
	ends[e] = -1
	held = e
	_raise(e)
	if prev != -1:
		end_changed.emit(e, -1, prev)


## O plug encaixado vai sair: a vista de frente some aos poucos no encaixe (`_pulled`).
func _unseat(e: int) -> void:
	if ends[e] != -1:
		_pulled[e] = [0.0, jack_rect(int(ends[e])).get_center(), _tilt(int(ends[e]))]
	_pushed.erase(e)
	_pushed_ang.erase(e)


## Solta o plug: ele cai e o fio o puxa de volta para o buraco (o FONE volta ao telefone).
func go_home(e: int) -> void:
	var from := _plug_base(e)
	var fling := _mouse_vel.limit_length(MAX_FLING) if held == e else Vector2.ZERO
	var ang := _swing if held == e else 0.0
	var prev: int = ends[e]
	_unseat(e)
	ends[e] = -1
	if held == e:
		held = -1
	if from.distance_to(_rest(e)) > 2.0:
		if not ropes.has(e):
			ropes[e] = Cord.new(hole(e), from)
		# acima do buraco o fio já puxa, esticado, e o plug vai direto para ele (sem cair no chão antes);
		# fora disso ele cai, com o embalo da mão, antes de o fio recolher
		var direct := from.y < hole(e).y and absf(from.x - hole(e).x) < NEAR_HOLE
		_loose[e] = {"t": FALL_SEC if direct else 0.0, "seat": -1.0, "direct": direct, "ang": ang}
		var r: Cord = ropes[e]
		if direct:
			r.length = minf(r.length, from.distance_to(hole(e)))
		else:
			for i in r.pts.size():   # o fio que a mão esticava solta parado (senão, o plug sai como de um estilingue)
				r.old[i] = r.pts[i]
			r.old[r.pts.size() - 1] = from - fling * STEP
	else:
		_sfx("thump", from, -14.0)
	if prev != -1:
		end_changed.emit(e, -1, prev)


func show_info(text_lines: PackedStringArray, ghost: bool, line: int) -> void:
	info_lines = text_lines
	info_ghost = ghost
	info_line = line
	info_until = Time.get_ticks_msec() + (7000 if ghost else 2600)


func _gui_input(e: InputEvent) -> void:
	if e.is_action_pressed("cancel_plug") and held != -1:
		go_home(held)
		accept_event()
		return
	if e is InputEventMouseMotion and held != -1:
		_dragged = _dragged or e.position.distance_to(_press_pos) >= CLICK_PX
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press(e.position)
		else:
			_release(e.position)
		accept_event()


func _press(pos: Vector2) -> void:
	cursor = pos
	_press_pos = pos
	_dragged = false
	_held_for = 0.0
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
	# tirado da tomada e devolvido a ela no mesmo arraste, solta perto de onde apertou: é arraste, não clique
	_dragged = _dragged or pos.distance_to(_press_pos) >= CLICK_PX
	if not _dragged or j == -1 or not place(held, j):
		go_home(held)


func _process(delta: float) -> void:
	if eye.is_valid():
		var at: Vector2 = eye.call()
		_eye = at - global_position if at.x < INF else PLUG_EYE
	for e in _pushed.keys():   # a assentada anda antes dos fios: a ponta deles acompanha o plug no mesmo quadro
		_pushed[e] += delta
		if _pushed[e] >= maxf(PUSH_SEC, MORPH_SEC):
			_pushed.erase(e)
			_pushed_ang.erase(e)
	for e in _pulled.keys():
		_pulled[e][0] += delta
		if _pulled[e][0] >= MORPH_SEC:
			_pulled.erase(e)
	var mouse := get_local_mouse_position()
	if held != -1:
		cursor = _reach(mouse)
		_held_for += delta / maxf(Engine.time_scale, 0.001)
		_dragged = _dragged or mouse.distance_to(_press_pos) >= CLICK_PX or _held_for >= CLICK_SEC
	var hand := cursor if held != -1 else mouse   # a velocidade é a do plug (preso no fim do fio, ele para)
	if delta > 0.0:
		_mouse_vel = _mouse_vel.lerp((hand - _hand_was) / delta, 0.5)
	_hand_was = hand
	_pull_edges(delta)
	_swing_step(delta)
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
		Sfx.cord_rub(moved / delta, _rub_x / moved, _rub_out / moved, _rub_fone / moved, _rub_loose / moved,
				_rub_tone / moved)
	else:
		Sfx.cord_rub(0.0)
	_rub_out = 0.0
	_rub_in = 0.0
	_rub_x = 0.0
	_rub_fone = 0.0
	_rub_loose = 0.0
	_rub_tone = 0.0
	if exchange != null:
		var ms := Time.get_ticks_msec()
		for n in range(1, 11):
			_fade("l%d" % n, _lamp(exchange.line(n), ms, fone_line() == n), delta)
		for d in dest_nums:
			_fade("d%d" % d, _dest_lamp(exchange.dest(d), ms), delta)
	var moving := held != -1 or not (_loose.is_empty() and _pushed.is_empty() and _pulled.is_empty())
	for e in ropes:
		moving = moving or not (ropes[e] as Cord).asleep()
	var now := _look()
	now.append(moving)   # no quadro em que tudo para, mais um desenho: o do lugar final (sem ele, o plug ficava torto, meio fora do buraco)
	if moving or now != _drawn:
		_drawn = now
		queue_redraw()


## O que a mesa mostra parada: muda, ela se redesenha (com algo se mexendo, a cada quadro). Parada, fica o desenho
## guardado (as luzes do `Bloom` também ficam: ele guarda as de quem desenha até a próxima vez).
func _look() -> Array:
	var levels := PackedFloat32Array()
	for key in _lit:
		var lt: Array = _lit[key]
		levels.append_array([lt[1], (lt[0] as Color).r, (lt[0] as Color).g])
	var states := PackedInt32Array()
	if exchange != null:
		for n in range(1, 11):
			states.append(exchange.line(n))
		for d in dest_nums:
			states.append(exchange.dest(d))
	return [size, ends.duplicate(), _hover, levels, states, Time.get_ticks_msec() < info_until, info_line, GameData.sectors.duplicate(), _eye]


## O plug da ponta e está no ponto p (guardado, vale a base inteira; fora dela, o desenho do plug).
func _plug_hit(e: int, p: Vector2) -> bool:
	if ends[e] == -1 and not _loose.has(e):
		return home_rect(e).has_point(p)
	var q := (p - _plug_base(e)).rotated(-_plug_angle(e))
	return _plug_rect(e).grow(2.0).has_point(q)


## Contorno do plug a partir de onde o fio entra nele: em pé (solto, na mão, na base) ou, encaixado, visto de frente.
func _plug_rect(e: int) -> Rect2:
	if ends[e] != -1:   # do encaixe (atrás) até a ponteira (aqui)
		var r := PLUG_FACE_R + 1.0
		return Rect2(-_tilt(int(ends[e])) - Vector2(r, r), Vector2(r, r) * 2.0).merge(Rect2(-r, -r, r * 2.0, r * 2.0))
	return Rect2(-10, -PLUG_H, 20, PLUG_H)


## Começa a assentar a ponta e, que chegou à boca do buraco com a traseira em `at`: o fio já entrou todo.
func _seat(e: int, at: Vector2) -> void:
	var an: Dictionary = _loose[e]
	var ang := wrapf(float(an["ang"]), -PI, PI)
	var turn := SEAT_TURN * absf(ang) / (PI / 2.0)
	# já em pé (vindo de cima), entra no embalo do fio; deitado, gira e afunda partindo do zero
	var v0 := PULL_SPEED if turn < STEP else 0.0
	an.merge({"seat": 0.0, "from": at, "ang": ang, "turn": turn, "v0": v0,
			"sink": (sqrt(v0 * v0 + 2.0 * SEAT_ACCEL * PLUG_SINK) - v0) / SEAT_ACCEL}, true)
	ropes.erase(e)
	_sfx("cord_stop", hole(e))   # o fio terminou de entrar


func _seat_step(e: int, dt: float) -> void:
	var an: Dictionary = _loose[e]
	an["seat"] += dt
	var t: float = an["seat"] - an["turn"] - an["sink"]
	if t >= 0.0 and not an.has("hit"):
		an["hit"] = true
		_sfx("thump", hole(e), -14.0)
	if t >= SEAT_BOB_SEC:
		_loose.erase(e)


## Onde fica o ponto p da mesa na tela, de 0 (borda esquerda) a 1 (direita): os sons vêm daquele lado.
func screen_x(p: Vector2) -> float:
	return (get_global_transform_with_canvas() * p).x / get_viewport_rect().size.x


## Som da mesa vindo do ponto p.
func _sfx(id: String, p: Vector2, db: float = 0.0) -> void:
	Sfx.play_at(id, screen_x(p), db)


## Onde fica o plug na mão com o mouse em `mouse`: até onde o fio dele alcança (`Cord.MAX` do buraco até a
## traseira dele); passando, ele para no fim do fio, esticado, e o fio dá um tranco.
func _reach(mouse: Vector2) -> Vector2:
	var a := hole(held)
	var base := PLUG_BASE.rotated(_swing)   # o fio prende na traseira do plug, girado com ele
	var d := mouse + base - a
	var taut := d.length() > Cord.MAX
	if taut and not _taut:
		_sfx("cord_snag", a, -3.0)
	_taut = taut
	return a + d.limit_length(Cord.MAX) - base


## O balanço do plug na mão: uma mola que puxa o ângulo para o que a velocidade da mão pede.
func _swing_step(delta: float) -> void:
	if held == -1:
		_swing = 0.0
		_swing_v = 0.0
		return
	var want := clampf(_mouse_vel.x * SWING_K, -SWING_MAX, SWING_MAX)
	var pull := get_local_mouse_position() + PLUG_BASE - hole(held)   # da mão até o buraco
	var over := clampf((pull.length() - Cord.MAX) / LEAN_PX, 0.0, 1.0)
	if over > 0.0:   # puxando além do fim do fio: a ponta vai para o lado do puxão
		want = lerp_angle(want, pull.angle() + PI / 2, over)
	_swing_v += (wrapf(want - _swing, -PI, PI) * SWING_SPRING.x - _swing_v * SWING_SPRING.y) * delta
	_swing = wrapf(_swing + _swing_v * delta, -PI, PI)


## Começo e fim de um puxão do plug na mão: o tranco do fio parado e o "tsk" quando a mão para de repente.
func _pull_edges(delta: float) -> void:
	if held == -1 or delta <= 0.0:
		_pull_rest = SNAG_REST
		_pull_run = -1.0
		_pull_top = 0.0
		return
	var a := hole(held)
	var pull := _mouse_vel.dot((get_local_mouse_position() - a).normalized())
	if pull < RUB_STILL:
		_pull_rest += delta
		_pull_run = -1.0
	else:
		if _pull_rest >= SNAG_REST:
			_pull_run = 0.0
		_pull_rest = 0.0
		if _pull_run >= 0.0:
			_pull_run += delta
			if pull > SNAG_SPEED:
				_sfx("cord_snag", a)
				_pull_run = -1.0
			elif _pull_run > SNAG_WINDOW:
				_pull_run = -1.0
	_pull_top *= exp(-delta / SNAP_MEMORY)
	if _pull_top > SNAG_SPEED and pull < _pull_top * SNAP_DROP:
		_sfx("cord_snap", a)
		_pull_top = 0.0
	_pull_top = maxf(_pull_top, pull)


## `d` px do fio da ponta e passaram pelo buraco (positivo: saindo; negativo: entrando), para o som de atrito.
func _count_rub(e: int, d: float, at := Vector2.INF) -> void:
	if d > 0.0:
		_rub_out += d
	else:
		_rub_in -= d
	_rub_x += absf(d) * screen_x(hole(e) if at == Vector2.INF else at)
	if e == 0:
		_rub_fone += absf(d)
	if _loose.has(e):
		_rub_loose += absf(d)
	_rub_tone += absf(d) * CORD_TONE[cable_of(e)]


## Até onde há prateleira, na mesa: x da lateral do console e y do tampo ao pé dele (INF: sem fim, sem cenário).
func _ground() -> Vector2:
	if not shelf.is_valid():
		return Vector2(INF, INF)
	var g: Vector2 = shelf.call()
	return g - global_position if g.x < INF else g


## Um passo do fio da ponta e (`Cord`): preso no buraco, a outra ponta segue o plug; solto, o plug é a última conta da
## corda (cai) e o comprimento encolhe até ele assentar no buraco. A mesa cuida do comprimento, dos sons e do plug.
func _step_rope(e: int, dt: float) -> void:
	if held != e and ends[e] == -1 and not _loose.has(e):
		ropes.erase(e)   # o fio está todo dentro do buraco
		return
	var an: Dictionary = _loose.get(e, {})
	if not an.is_empty() and an["seat"] >= 0.0:
		_seat_step(e, dt)
		return
	var a := hole(e)
	if not ropes.has(e):
		ropes[e] = Cord.new(a, _plug_base(e))
	var r: Cord = ropes[e]
	r.floor_y = _floor()
	r.lip_y = tray_rect().end.y   # a beira da frente da prateleira: abaixo dela, o fio fica no ar
	r.ground = _ground()   # a lateral do console (x) e o tampo ao pé dele (y), além da prateleira
	r.free = not an.is_empty()
	r.direct = r.free and an["direct"]
	r.held = held == e
	r.stub = _tilt(int(ends[e])).normalized() if ends[e] != -1 else Vector2.ZERO
	r.mouse = get_local_mouse_position()
	r.nudge = r.mouse - _last_mouse
	var length := r.length
	var b := Vector2.ZERO
	if r.free:
		an["t"] += dt
		if an["t"] > FALL_SEC:
			length = maxf(length - PULL_SPEED * dt, 0.0)
			if r.hang_step(dt, a, length):   # pendurado na quina da prateleira
				if not is_nan(r.swing):
					an["ang"] = lerp_angle(float(an["ang"]), r.swing, HANG_TURN)
				_count_rub(e, r.pulled)
				_count_rub(e, r.over, r.over_at)
				return
	else:
		b = _plug_base(e)
		var reach := a.distance_to(b)
		var slack := clampf(absf(b.x - a.x) * SLACK_PER_PX, CORD_SLACK, SLACK) if e == 0 else CORD_SLACK
		slack = maxf(slack, reach * SLACK_REACH)
		if r.air >= 1:   # no ar, o peso do fio pendurado puxa a folga pela beira (sobrava em laço na prateleira)
			slack = CORD_SLACK
		length = lerpf(length, minf(reach + slack, Cord.MAX), 0.08)
	if not r.step(dt, a, b, length):
		return   # dormindo
	_count_rub(e, r.pulled)
	_count_rub(e, r.over, r.over_at)
	if r.drop > DROP_SPEED:   # o plug solto bate na mesa
		_sfx("drop", r.drop_at, lerpf(-10.0, 0.0, clampf((r.drop - DROP_SPEED) / (DROP_FULL - DROP_SPEED), 0.0, 1.0)))
	r.tap_wait = maxf(r.tap_wait - dt, 0.0)
	if r.tap > TAP_SPEED.x * dt and r.tap_wait == 0.0:   # o fio caiu ou chicoteou na mesa
		var k := clampf((r.tap / dt - TAP_SPEED.x) / (TAP_SPEED.y - TAP_SPEED.x), 0.0, 1.0)
		_sfx("cord_tap", r.tap_at, lerpf(-12.0, 0.0, k))
		r.tap_wait = TAP_GAP
	if r.free:   # o plug solto segue o fio, que sai da traseira dele (com o fio quase todo dentro, fica como estava)
		var pts := r.pts
		var last := pts.size() - 1
		var d := pts[last] - pts[last - 3]
		if d.length_squared() >= 4.0:   # aos poucos: de pendurado para deitado, ele vira, não salta
			an["ang"] = lerp_angle(float(an["ang"]), d.angle() + PI / 2, LOOSE_TURN)
		if r.length <= SEAT_LEN:
			an["dry"] = float(an.get("dry", 0.0)) + dt
			var on_shelf := pts[last].x < r.ground.x and pts[last].y <= r.floor_y + 1.0
			if pts[last].distance_to(a) <= SEAT_NEAR or (an["dry"] > SEAT_WAIT and on_shelf):
				_seat(e, pts[last])


func _draw() -> void:
	Bloom.clear(self)
	_lamp_at = _lamp_pos()   # uma vez por desenho: a luz da sala no painel, nos fios e nos plugs sai dela
	var w := size.x
	var h := size.y
	var ms := Time.get_ticks_msec()
	_draw_cabinet(Rect2(Vector2.ZERO, size))
	_draw_tray(tray_rect())
	for y in RULES.values():
		_draw_rule(y, "")
	if exchange == null:
		return
	_draw_strips()
	_draw_rule(RULES["in"], T.text(T.Key.BOARD_INPUTS), false)   # os nomes por cima das faixas
	_draw_rule(RULES["out"], T.text(T.Key.BOARD_OUTPUTS), false)
	_draw_wear()
	_draw_maker_plate()

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
		var label := PixelArt.tiny(exchange.line_label(n))   # as letras vão de 3 a 7 na imagem: o pé delas logo acima de ROW_Y
		draw_texture(label, Vector2(roundf(cx - label.get_width() / 2.0), ROW_Y["state"] - 8.0), sc)
		_draw_jack(jack_rect(n + 10), 0.25)

	# destinos: a faixa de numeração de cada banco fica sobre a faixa gravada, como rótulo da seção
	for s in _blocks:
		var br: Rect2 = _blocks[s]
		var cap := "%d–%d" % [s * 100, s * 100 + 99]
		draw_rect(Rect2(br.position.x, RULES["dest"] - 7, Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 8, 15), Pal.PANEL)
		draw_string(Pal.ui, Vector2(br.position.x + 4, RULES["dest"] + 5), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.DIM)
		draw_rect(br, Pal.PANEL_LO, false, 1.0)
	for d in dest_nums:
		var jr := jack_rect(d)
		var cx := jr.get_center().x
		var st := exchange.dest(d)
		draw_string(Pal.mono, Vector2(cx - 16, jr.position.y - 5), str(d), HORIZONTAL_ALIGNMENT_CENTER, 32, 11, Color("d8c9a2") if st == Exchange.Dest.FREE else Pal.TEXT)
		var dl: Array = _lit.get("d%d" % d, [LAMP_OFF, 0.0])
		if dl[1] > 0.02:   # o aro em volta da tomada acende
			PixelArt.sprite(self, PixelArt.disc(JACK_PX + 8, [[JACK_PX / 2.0 + 4.0, Color.WHITE]]), jr.get_center(), Color(dl[0], dl[1]))
			Bloom.light(self, jr.grow((JACK_PX - JACK) / 2.0 + 3.0), Color(dl[0], dl[1]), 1.0, false, true)
		_draw_jack(jr)
	for s in _blocks:
		if not s in GameData.sectors:
			_draw_plate(_blocks[s], "ABC"[SECTOR_ORDER.find(s)])

	# legenda das lâmpadas, numa linha no pé do painel
	_draw_legend()
	_draw_room_light(Rect2(Vector2.ZERO, size).grow(-FRAME))

	# destaque da tomada sob o plug (antes de virar arraste, soltar desencaixa: sem destaque)
	if held != -1 and _dragged:
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
	for e in _pulled:   # plugs que acabaram de sair: a vista de frente sumindo no encaixe
		var k: float = _pulled[e][0] / MORPH_SEC
		draw_set_transform(_pulled[e][1], 0.0, Vector2.ONE * lerpf(1.0, 0.4, k))
		_draw_plug_face(_cable_col(e), _pulled[e][2], 0.0, 1.0 - k, -1, _lit_by(_pulled[e][1]))
		draw_set_transform(Vector2.ZERO)
	for e in _order:
		if ends[e] != -1:   # encaixado, visto de frente: o fio sai do meio dele (da ponteira), por cima do tampo
			_draw_plug(e, false)
			Bloom.occlude(self, Transform2D(0.0, jack_rect(int(ends[e])).get_center().round()) * _plug_outline(e, 1.0))
			_draw_rope(e, false)
			_draw_plug_cap(e)
		else:
			_draw_rope(e, false)
			_draw_plug(e, false)
		if ropes.has(e) and not _in_hole(e):   # o fio sai de dentro do buraco: a beira da frente passa por cima dele
			draw_lip(self, hole(e))

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


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
