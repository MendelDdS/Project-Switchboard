class_name Switchboard
extends "res://scripts/ui/switchboard_plugs.gd"
## Mesa comutadora.
## - ENTRADAS 01–10: onde as chamadas chegam. O FONE (cabo verde, que sai do telefone) entra aqui para atender.
## - SAÍDAS: uma tomada logo abaixo de cada entrada. Uma ponta do cabo de conexão entra aqui...
## - DESTINOS: ...e a outra ponta no número pedido.
## Os cabos de conexão são poucos (`patches`; cada setor novo traz um): desmontar as conexões encerradas libera cabos.
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
signal lever_pressed(line: int)   ## clique na chave de escuta da linha

## Destinos em três bancos de tomadas, A, B e C, cada um com uma faixa de numeração (100–199, 200–299, 300–399), em
## duas fileiras. A mesa saiu de fábrica assim; a faixa coincide com o setor da cidade (o primeiro dígito), e o banco
## de um setor que ainda não é do operador fica tampado por uma chapa com a letra dele (`GameData.sectors`).
const SECTOR_ORDER := [1, 2, 3]
const DEST_PITCH := 18.0     # px entre duas tomadas de destino vizinhas (o número em cima, "305", tem 11 na fonte gravada)
const TRUNK_PITCH := 30.0    # px entre dois troncos (o nome em cima, "LITORAL", tem 27 na fonte gravada)
const BLOCK_GAP := 9.0      # px entre dois blocos
const DAY_LIFT := 0.35       # no amanhecer da última noite, o quanto a luz do dia clareia a mesa, na força toda (`dim`)

var _pulled := {}   ## ponta -> [segundos desde que saiu do encaixe, onde ele estava]: o plug de frente sumindo
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
var _levers := []       # a alavanca de cada linha como estava (para cima?), para saber quando ela vira
var _flips := {}        # linha -> s desde que a alavanca começou a virar (`LEVER_SEC`)
const LEVER_SEC := 0.09 # a alavanca virando: passa de frente e bate um pixel além antes de assentar

const CLICK_PX := 5.0   # apertar e soltar mexendo menos que isso, e mais rápido que CLICK_SEC s, é clique: desplugar,
const CLICK_SEC := 0.25 # não encaixar (segurando parado sobre a tomada de onde o plug saiu, soltar o encaixa de novo)
const NEAR_HOLE := 34.0        # solto acima do buraco (a qualquer altura) e com essa distância na horizontal, o fio puxa o plug direto (sem cair)
## O contrapeso de cada fio, numa roldana embaixo da prateleira, como nas mesas de verdade, puxa o fio para dentro do
## buraco o tempo todo. Solto, o plug volta na hora, o fio acelerando (`WEIGHT_ACCEL`) até `PULL_SPEED` (antes ele caía
## 0,35 s sem nada puxar e o fio recolhia sempre na mesma marcha); encaixado ou na mão, a folga volta para o buraco mais
## depressa do que sai (`WEIGHT_TAKE` por passo, contra `HAND_FEED`) e o fio fica quase reto, com a barriga do peso
## dele (`SAG`, `BEND_SLACK`).
const WEIGHT_ACCEL := 1400.0   # px/s²
const PULL_SPEED := 360.0      # px/s de fio que entra no buraco, no máximo (o atrito na roldana)
const WEIGHT_TAKE := 0.35
const HAND_FEED := 0.08
const SEAT_LEN := 2.0          # com o fio curto assim e a traseira do plug a SEAT_NEAR px da boca do buraco, ele assenta
const SEAT_NEAR := 3.0         # (o fio acaba antes de a corda alcançar: o plug ainda arrasta até ali, ou por SEAT_WAIT s)
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
const MAX_FLING := 1350.0      # px/s: o plug solto em movimento sai com o embalo da mão, até esse limite
const DROP_SPEED := 90.0      # px/s: batendo na mesa mais rápido que isso, faz barulho (mais alto até DROP_FULL)
const DROP_FULL := 525.0
## Na mão, o plug balança com o movimento, preso onde a mão o pega: a traseira (com o fio) fica para trás, como um
## pêndulo. SWING_K rad por px/s da mão na horizontal, no máximo SWING_MAX; mola e amortecimento em SWING_SPRING.
const SWING_K := 0.0008
const SWING_MAX := deg_to_rad(20.0)
const SWING_SPRING := Vector2(160.0, 11.0)
## Passando do fim do fio (`Cord.MAX`), o plug na mão se inclina para onde a mão puxa, inteiro a LEAN_PX px além: a
## traseira, com o fio, fica virada para o buraco (em pé, com o fio chegando de lado, a junção dobrava e o fio passava
## por cima dele).
const LEAN_PX := 30.0
const TAP_SPEED := Vector2(112.0, 450.0)   # px/s: o fio batendo na mesa faz "tap" a partir de x; em y, no volume máximo
const KNOCK_SPEED := Vector2(60.0, 300.0)   # px/s: o fio caindo num plug encaixado faz "toc" a partir de x (apoiado nele, 0); em y, no máximo
const TAP_GAP := 0.12          # s: intervalo mínimo entre dois "taps" do mesmo fio
## O puxão da mão, na direção do buraco para fora (`_pull_edges`): o fio parado que sai rápido dá um tranco
## (`cord_snag`: parado há SNAG_REST s, passa de SNAG_SPEED px/s até SNAG_WINDOW s depois de começar a andar) e o
## puxão rápido que para de repente, um "tsk" de fibra (`cord_snap`: a mão cai para SNAP_DROP do pico, que vale
## acima de SNAG_SPEED e é esquecido em SNAP_MEMORY s; parando devagar, o pico desce junto e não toca).
const SNAG_SPEED := 225.0
const SNAG_REST := 0.15
const SNAG_WINDOW := 0.12
const SNAP_DROP := 0.2
const SNAP_MEMORY := 0.08
const RUB_STILL := 22.0        # px/s: abaixo disso a mão está parada
## Tom do atrito de cada cabo (multiplica o tom e o corte): FONE, vermelho, azul, amarelo. Só uma nuance, para a
## mesa não soar como um fio só.
const CORD_TONE := [1.0, 1.05, 0.95, 1.02, 0.97, 1.04]

## A folga do fio esticado pelo contrapeso, além da distância do buraco ao plug: só a barriga do peso dele, que cresce
## com o cubo do vão (SAG × vão³: ~1 px em 330, ~4 no fio todo), e nunca menos que BEND_SLACK, para a curva saindo do
## plug. Pouca: a barriga de uma corda presa nas duas pontas cresce com a raiz da folga vezes o vão (10 px de folga
## em 200 de vão já são ~27 de barriga, e o fio parecia solto, encaixado e na mão). (Antes, uma folga fixa, maior no
## FONE, até 52 px: o fio ficava mole, deitava na prateleira e passava por cima dos plugs guardados antes de subir.)
const SAG := 3e-8
const BEND_SLACK := 3.0
## Encaixado, o contrapeso recolhe HINGE_PULL a mais (do vão) que o fio esticado do buraco à curva menos a capa (a
## mesma tensão no fio curto e no longo; 6%: ~25 px no vão de 420): o fio fica
## sob tensão, quase reto, e puxa a capa, que gira na curva, para a direção do buraco; o peso dela a leva para baixo
## (`Cord.BOOT_WEIGHT`). (Com folga, o fio pendia mole e a capa quase reta; contando do pé da capa, o fio ganhava
## folga a cada passo.)
const HINGE_PULL := 0.06
const HINGE_TAKE := 120.0   # px/s: encaixado, o contrapeso recolhe o fio no máximo assim
const CORD_SLACK := 10.0           # no ar, na frente do console: o peso do fio pendurado puxa a folga pela beira
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
var _layers: Array[CanvasItem] = []   # a mesa (o painel parado) e as camadas por cima dela, cada uma com o seu desenho
var _lamps: Control
var _top: Control
var _cords: Control
var _glow: ColorRect   # a luz das lâmpadas acesas no painel em volta, num shader (`board_glow.gdshader`): por cima da luz da sala, por baixo dos fios
var _drawn := [[], [], [], []]   # o que cada uma mostrava no último desenho (`_look`)
var _equipment := {}   # id -> a cena do equipamento de pé na prateleira (`set_equipment`), na ordem em que ficam
var _bay_at := Rect2()   # onde estava a faixa deles na última vez que foram postos (os containers arrumam a prateleira depois)

const EQUIPMENT_DIR := "res://scenes/ui/equipment/"
const BAY_GAP := 6.0   # entre um equipamento e o seguinte, e da beira do bloco interurbano até o primeiro


func _ready() -> void:
	custom_minimum_size = SIZE + Vector2(SIDE_W, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ci = self
	_layers.append(self)
	patches = SHELF_SLOTS - SECTOR_ORDER.size() + GameData.sectors.size()   # um lugar tampado por setor que ainda não é do operador
	for f: Callable in [_draw_lamps, _draw_top, _draw_cords]:   # por cima do painel, nesta ordem (`_draw`)
		var layer := Control.new()
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.draw.connect(f)
		add_child(layer)
		_layers.append(layer)
	_lamps = _layers[1]
	_top = _layers[2]
	_cords = _layers[3]
	_glow = ColorRect.new()
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.material = ShaderMaterial.new()
	(_glow.material as ShaderMaterial).shader = preload("res://scripts/ui/board_glow.gdshader")
	add_child(_glow)
	move_child(_glow, _cords.get_index())
	for i in 1 + patches * 2:
		ends.append(-1)
		_order.append(i)


## A luminária piscando ou ainda fria escurece a mesa como escurece a sala (`Background.lamp_dark`, posto pelo Main a
## cada quadro), no `modulate`: tudo o que ela desenha, onde estiver (os plugs na prateleira, o fio arrastado até o
## painel de baixo), e nada se redesenha. (Uma camada por cima, com o shader do escuro da sala, só cobria o retângulo
## dela; estendida até a prateleira, escurecia duas vezes a madeira, que é do cenário.)
func dim(extra: float, day := Color(1, 1, 1, 0)) -> void:
	var lift := 1.0 + DAY_LIFT * day.a   # (de dia, a luz da janela chega fraca até ela)
	modulate = Color.WHITE.darkened(extra) * Color(lerpf(1.0, lift, day.r), lerpf(1.0, lift, day.g), lerpf(1.0, lift, day.b))


func setup(ex: Exchange, socket: Control, cord_tray: Control) -> void:
	exchange = ex
	fone_socket = socket
	tray = cord_tray
	dest_nums = ex.dest_numbers()
	_jacks = range(1, 21) + dest_nums
	_layout_dests()


## Os equipamentos liberados (`Bureaucracy.equipment`), de pé na prateleira embaixo do bloco interurbano (`bay_rect`),
## lado a lado na ordem de `ids`, ou, com `side` na cena (0 em cima, 1 embaixo), na coluna do lado do painel
## (`side_rect`): cada um é a cena `scenes/ui/equipment/<id>.tscn` e cuida de si (desenho, clique); a
## mesa só os põe no lugar, por baixo da luz das lâmpadas e dos fios. Sem nenhum, o lugar fica tampado.
func set_equipment(ids: PackedStringArray) -> void:
	for id: String in _equipment.keys():
		if not id in ids:
			(_equipment[id] as Node).queue_free()
			_equipment.erase(id)
	for id in ids:
		if not _equipment.has(id) and ResourceLoader.exists(EQUIPMENT_DIR + id + ".tscn"):
			var n: Control = load(EQUIPMENT_DIR + id + ".tscn").instantiate()
			add_child(n)
			move_child(n, _glow.get_index())
			_equipment[id] = n
	equipped = PackedStringArray(_equipment.keys())
	_place_equipment()


## Põe os equipamentos no lugar: os da coluna do lado, no alto ou no pé dela; os outros lado a lado, de pé na fileira
## da frente da faixa deles.
func _place_equipment() -> void:
	_bay_at = bay_rect()
	var x := _bay_at.position.x + BAY_GAP
	var side := side_rect()
	shelf_used = false
	side_used = false
	for n: Control in _equipment.values():
		n.size = n.custom_minimum_size
		var at: int = n.get_meta("side", -1)
		if at >= 0:
			side_used = true
			n.position = Vector2(side.get_center().x - n.size.x / 2.0, side.position.y if at == 0 else side.end.y - n.size.y).round()
			continue
		shelf_used = true
		n.position = Vector2(x, _bay_at.position.y + SHELF_FRONT_Y + 3.0 - n.size.y).round()
		x += n.size.x + BAY_GAP


## A coluna do móvel à direita das tomadas (`SIDE_W`), dentro da moldura, depois do friso que a separa delas.
func side_rect() -> Rect2:
	return Rect2(SIZE.x - FRAME + 4.0, FRAME + 3.0, SIDE_W - 7.0, SIZE.y - FRAME * 2.0 - 6.0)


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
			_slots[nums[i]] = Vector2(x + (i % cols[k]) * DEST_PITCH + DEST_PITCH / 2.0, DEST_TOP + 8.0 + int(i / cols[k]) * DEST_ROW)
		# em cima, a moldura rente aos números (o vão que sobra fica para o nome das saídas); embaixo, 6 px até as tomadas
		_blocks[s] = Rect2(x - 2, DEST_TOP - 13, cols[k] * DEST_PITCH + 4, DEST_ROW + JACK + 18)
		x += cols[k] * DEST_PITCH + BLOCK_GAP
	var tw := GameData.TRUNKS.size() * TRUNK_PITCH + 4.0
	trunks = Rect2(_blocks[3].end.x - tw, _blocks[3].end.y + 5.0, tw, 29.0)   # embaixo do banco C, alinhado à direita dele (5 px: o pé do painel)
	for k in GameData.TRUNKS.size():   # uma tomada por cidade, com o nome dela em cima (`_draw_trunks`)
		_slots[GameData.TRUNKS[k]] = Vector2(trunks.position.x + 2.0 + (k + 0.5) * TRUNK_PITCH, trunks.position.y + 19.0)


func _has_point(p: Vector2) -> bool:   # o painel até a prateleira, com o vão entre eles (os plugs guardados passam por ele)
	return Rect2(Vector2.ZERO, size).merge(socket_rect()).merge(tray_rect()).has_point(p)


func place(e: int, j: int) -> bool:
	var why := refuse(e, j)
	if why != "":
		warned.emit(why)
		_sfx("click", jack_rect(j).get_center())
		return false
	_pushed_from[e] = [cursor + (PLUG_BASE - Vector2(0, PLUG_LEN)).rotated(_swing) - jack_rect(j).get_center(), _swing]   # a frente do plug na mão
	ends[e] = j
	var c := jack_rect(j).get_center()
	var over := ropes.keys().filter(func(x: int) -> bool: return x != e and ends[x] != -1 and (ropes[x] as Cord).touching(Vector3(c.x, c.y, (JACK + ROPE_W) / 2.0)))
	if not over.is_empty():
		_draped[e] = over
	held = -1
	_loose.erase(e)
	_raise(e)
	_pushed[e] = 0.0   # o estalo vem na batida no fundo (`_impact`)
	end_changed.emit(e, j, -1)
	return true


## O plug que está encaixando bate no fundo da tomada: o estalo, e os encaixados perto pulam (o brilho, `_draw_plug`).
func _impact(e: int) -> void:
	var c := jack_rect(int(ends[e])).get_center()
	_sfx("plug_in", c)
	for x in ends.size():
		if x != e and ends[x] != -1 and not _pushed.has(x) and jack_rect(int(ends[x])).get_center().distance_to(c) < NEIGHBOR:
			_knocked[x] = [0.0, KNOCK_PX.y]


## A ponta `e` já encaixada na tomada `j`, sem som nem animação (o treinamento começa com o FONE na entrada 1).
func plugged(e: int, j: int) -> void:
	ends[e] = j
	_raise(e)
	end_changed.emit(e, j, -1)


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
		_pulled[e] = [0.0, jack_rect(int(ends[e])).get_center(), _elbow_pose(e)]
	_pushed.erase(e)
	_pushed_from.erase(e)
	_draped.erase(e)
	for x in _draped:   # o fio dela sai de cima dos plugs
		_draped[x].erase(e)


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
		_loose[e] = {"v": 0.0, "seat": -1.0, "direct": direct, "ang": ang}
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
	info_until = PixelArt.ms() + (7000 if ghost else 2600)


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
	if j == -1 and _lever_at(pos) != -1:
		lever_pressed.emit(_lever_at(pos))
		return
	if j == -1:
		j = _top_at(pos)
	if j != -1:
		info_requested.emit(j)   # tomada vazia ou plaqueta da linha: mostra o que é


## A ponta cujo plug está em p (-1 = nenhuma), o de cima primeiro: guardado, solto voltando ou encaixado.
func _plug_under(p: Vector2) -> int:
	if _lever_at(p) != -1 and jack_at(p) == -1:
		return -1   # a chave de escuta ganha da capa do plug encaixado que a tapa (`_elbow_ang`)
	for i in range(_order.size() - 1, -1, -1):
		var e: int = _order[i]
		if e != held and _plug_hit(e, p):
			return e
	return cord_at(jack_at(p))


## A linha (1–10) cuja chave de escuta está em p, ou -1.
func _lever_at(p: Vector2) -> int:
	for i in 10:
		if lever_rect(i).has_point(p):
			return i + 1
	return -1


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
	if jack_at(p) != -1 or _top_at(p) != -1 or _lever_at(p) != -1:
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
	if not _equipment.is_empty() and bay_rect() != _bay_at:
		_place_equipment()
	if eye.is_valid():
		var at: Vector2 = eye.call()
		_eye = at - global_position if at.x < INF else PLUG_EYE
	for e in _pushed.keys():   # a assentada anda antes dos fios: a ponta deles acompanha o plug no mesmo quadro
		if _pushed[e] < HIT_SEC and _pushed[e] + delta >= HIT_SEC:
			_impact(e)
		_pushed[e] += delta
		if _pushed[e] >= PUSH_SEC:
			_pushed.erase(e)
			_pushed_from.erase(e)
	for e in _knocked.keys():
		_knocked[e][0] += delta
		if _knocked[e][0] >= KNOCK_SEC or ends[e] == -1:
			_knocked.erase(e)
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
		var ms := PixelArt.ms()
		for n in range(1, 11):
			_fade("l%d" % n, _lamp(exchange.line(n), ms), delta)
		for d in dest_nums:
			_fade("d%d" % d, _dest_lamp(exchange.dest(d), ms), delta)
		_flip_levers(delta)
	var moving := held != -1 or not (_loose.is_empty() and _pushed.is_empty() and _pulled.is_empty() and _knocked.is_empty())
	for e in ropes:
		moving = moving or not (ropes[e] as Cord).asleep()
	_lamp_at = _lamp_pos()
	var now := _look()
	now[3].append(moving)   # no quadro em que tudo para, mais um desenho: o do lugar final (sem ele, o plug ficava torto, meio fora do buraco)
	for k in now.size():
		if now[k] != _drawn[k] or (k == 3 and moving):
			_layers[k].queue_redraw()
	_drawn = now


## A alavanca que virou começa a animação (e estala, vinda dela); as que estão virando andam.
func _flip_levers(delta: float) -> void:
	for n in _flips.keys():
		_flips[n] += delta
		if _flips[n] >= LEVER_SEC:
			_flips.erase(n)
	for n in range(1, 11):
		var up := lever_up(n)
		if _levers.size() == 10 and _levers[n - 1] != up:
			_flips[n] = 0.0
			_sfx("click", lever_rect(n - 1).get_center(), -2.0)
			_sfx("sw", lever_rect(n - 1).get_center(), -10.0)
		if _levers.size() < 10:
			_levers.append(up)
		_levers[n - 1] = up


## A pose da alavanca da linha `n`: [direção (-1 para cima, 1 para baixo, 0 de frente), px além (a batida)].
func _lever_pose(n: int) -> Array:
	var dir := -1 if _levers.size() == 10 and _levers[n - 1] else 1
	if not _flips.has(n):
		return [dir, 0.0]
	var k: float = _flips[n] / LEVER_SEC
	return [0, 0.0] if k < 0.4 else [dir, 1.0 if k < 0.75 else 0.0]


## O que cada camada mostra parada, na ordem de `_layers`: mudou, ela se redesenha (os fios, com algo se mexendo, a
## cada quadro). Parada, fica o desenho guardado (as luzes do `Bloom` também ficam: ele guarda as de quem desenha até
## a próxima vez).
func _look() -> Array:
	var levels := PackedFloat32Array()
	for key in _lit:
		var lt: Array = _lit[key]
		levels.append_array([lt[1], (lt[0] as Color).r, (lt[0] as Color).g])
	var states := PackedInt32Array()
	var plugs := []   # a luz das lâmpadas nos plugs encaixados (`_plug_light`)
	var poses := []   # as chaves de escuta (`_lever_pose`)
	if exchange != null:
		for n in range(1, 11):
			states.append(exchange.line(n))
			poses.append(_lever_pose(n))
		for d in dest_nums:
			states.append(exchange.dest(d))
		for j in ends:
			if j != -1:
				plugs.append(_plug_light(j))
	return [[size, states, GameData.sectors.duplicate(), _lamp_at, equipped, _eye], [size, levels, ends.duplicate(), _eye, poses, _lamp_at],
		[size, GameData.sectors.duplicate(), _lamp_at, side_used],
		[size, ends.duplicate(), _hover, plugs, PixelArt.ms() < info_until, info_line, _eye, _lamp_at]]


## O plug da ponta e está no ponto p (guardado, vale a base inteira; fora dela, o desenho do plug).
func _plug_hit(e: int, p: Vector2) -> bool:
	if ends[e] == -1 and not _loose.has(e):
		return home_rect(e).has_point(p)
	if ends[e] != -1:   # encaixado, pela silhueta do cotovelo (a caixa dele, na diagonal, pegava a chave de escuta)
		return Geometry2D.is_point_in_polygon(p - jack_rect(int(ends[e])).get_center(), _plug_outline(e, 2.0))
	var q := (p - _plug_base(e)).rotated(-_plug_angle(e))
	return Rect2(-PLUG_W / 2.0, -PLUG_H, PLUG_W, PLUG_H).grow(2.0).has_point(q)


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
## Os plugs encaixados das outras pontas, como obstáculos do fio de `e` (`Cord.pegs`): os discos da cabeça e da capa
## de cada um (`_elbow_pegs`), do tamanho do plug ali mais meio fio. Encaixando,
## cresce enquanto ele é empurrado para dentro (`PUSH_SEC`): o fio embaixo dele vai para o lado aos poucos (com o
## plug inteiro de uma vez, saltava 8 px num passo).
func _pegs(e: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for x in ends.size():
		if x != e and ends[x] != -1 and not e in _draped.get(x, []):
			var grow := minf(float(_pushed.get(x, PUSH_SEC)) / PUSH_SEC, 1.0)
			for g in _elbow_pegs(x):
				out.append(Vector3(g.x, g.y, (g.z + ROPE_W / 2.0) * grow))
	return out


## A ponta encaixada que é o plug `g` de `Cord.pegs` (-1: nenhuma; o raio não conta: encaixando, ele cresce).
func _end_of_peg(g: Vector3) -> int:
	var c := Vector2(g.x, g.y)
	for x in ends.size():
		if ends[x] != -1:
			for part in _elbow_pegs(x):
				if Vector2(part.x, part.y).is_equal_approx(c):
					return x
	return -1


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
	r.floor_y = a.y   # o fio repousa na prateleira na fileira do buraco dele (na de trás, o da frente não descia até o buraco)
	r.lip_y = tray_rect().end.y   # a beira da frente da prateleira: abaixo dela, o fio fica no ar
	r.ground = _ground()   # a lateral do console (x) e o tampo ao pé dele (y), além da prateleira
	r.free = not an.is_empty()
	r.direct = r.free and an["direct"]
	r.held = held == e
	var j := int(ends[e])
	var pivot := jack_rect(j).get_center() + _tilt(j) if j != -1 and _turning(e).is_empty() else Vector2.INF   # encaixado, a capa gira com o fio (`Cord.pivot`; virando, o fio segue o pé dela)
	if pivot != r.pivot:   # encaixou ou mudou de tomada: o fio acorda, com o pé da capa entre a vertical e o buraco
		r.pivot = Vector2.INF
		if j != -1:
			r.pts[r.pts.size() - 1] = _plug_base(e)
		r.pivot = pivot
		r.sleep = Rect2()
	r.arm = ELBOW_LEN - 1.0
	r.arm_max = ELBOW_MAX
	var pegs := _pegs(e) if ends[e] != -1 or held == e else PackedVector3Array()
	if pegs != r.pegs:   # um plug encaixou ou saiu: o fio acorda para se acomodar
		for g in r.pegs:   # o que o segurava saiu: o fio cai e bate no painel
			if ends[e] != -1 and not Array(pegs).any(func(h: Vector3) -> bool: return Vector2(h.x, h.y).is_equal_approx(Vector2(g.x, g.y))) and r.touching(g):
				_sfx("cord_tap", Vector2(g.x, g.y), -8.0)
				break
		r.pegs = pegs
		r.sleep = Rect2()
		r.calm = 0   # (sem isso, voltava a dormir no passo seguinte, ainda dentro do plug novo)
	r.mouse = get_local_mouse_position()
	r.nudge = r.mouse - _last_mouse
	var length := r.length
	var b := Vector2.ZERO
	if r.free:
		an["v"] = minf(float(an["v"]) + WEIGHT_ACCEL * dt, PULL_SPEED)   # o contrapeso puxa desde que ele saiu da mão
		length = maxf(length - float(an["v"]) * dt, 0.0)
		if r.hang_step(dt, a, length):   # pendurado na quina da prateleira
			if not is_nan(r.swing):
				an["ang"] = lerp_angle(float(an["ang"]), r.swing, HANG_TURN)
			_count_rub(e, r.pulled)
			_count_rub(e, r.over, r.over_at)
			return
	else:
		b = r.tip() if r.hinged() else _plug_base(e)
		var reach := a.distance_to(b)
		var slack := maxf(BEND_SLACK, SAG * reach * reach * reach)
		if r.hinged():   # encaixado, o contrapeso conta da curva do plug e estica o fio (`HINGE_PULL`)
			reach = a.distance_to(r.pivot) - r.arm
			slack = -reach * HINGE_PULL
		if r.air >= 1:   # no ar, o peso do fio pendurado puxa a folga pela beira (sobrava em laço na prateleira)
			slack = CORD_SLACK
		var target := minf(reach + slack, Cord.MAX)
		length = lerpf(length, target, WEIGHT_TAKE if target < length else HAND_FEED)   # o contrapeso recolhe; a mão puxa
		if r.hinged():   # esticando, recolhe aos poucos: de uma vez, o fio chicoteava e se enroscava nos plugs
			length = maxf(length, r.length - HINGE_TAKE * dt)
	if not r.step(dt, a, b, length):
		return   # dormindo
	var hooked := _end_of_peg(r.hook()) if j != -1 else -1
	if hooked != -1:   # enganchado por baixo num plug: escorrega pela frente dele e corre por cima (`Cord.HOOK`)
		_draped[hooked] = _draped.get(hooked, []) + [e]
	_count_rub(e, r.pulled)
	_count_rub(e, r.over, r.over_at)
	if r.drop > DROP_SPEED:   # o plug solto bate na mesa
		_sfx("drop", r.drop_at, lerpf(-10.0, 0.0, clampf((r.drop - DROP_SPEED) / (DROP_FULL - DROP_SPEED), 0.0, 1.0)))
	r.tap_wait = maxf(r.tap_wait - dt, 0.0)
	if r.tap > TAP_SPEED.x * dt and r.tap_wait == 0.0:   # o fio caiu ou chicoteou na mesa
		var k := clampf((r.tap / dt - TAP_SPEED.x) / (TAP_SPEED.y - TAP_SPEED.x), 0.0, 1.0)
		_sfx("cord_tap", r.tap_at, lerpf(-12.0, 0.0, k))
		r.tap_wait = TAP_GAP
	var hit := _end_of_peg(r.knock_peg) if r.knock > KNOCK_SPEED.x * dt and r.tap_wait == 0.0 else -1
	if hit != -1 and not _pushed.has(hit):   # o fio caiu num plug encaixado: o "toc" e o plug afunda um instante (encaixando, é ele que empurra o fio)
		var k := clampf((r.knock / dt - KNOCK_SPEED.x) / (KNOCK_SPEED.y - KNOCK_SPEED.x), 0.0, 1.0)
		_sfx("cord_knock", r.knock_at, lerpf(-12.0, 0.0, k))
		r.tap_wait = TAP_GAP
		_knocked[hit] = [0.0, lerpf(KNOCK_PX.x, KNOCK_PX.y, k)]
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


## O painel parado: o móvel, as faixas, as plaquinhas, as tomadas das linhas e a numeração. Por cima dele, cada uma
## com o seu desenho (refeito só quando o que ela mostra muda, `_look`): as lâmpadas (`_lamps`), as tomadas dos
## destinos com a luz da sala (`_top`) e os plugs com os fios (`_cords`).
func _draw() -> void:
	_draw_cabinet(Rect2(Vector2.ZERO, size))
	var div := Rect2(SIZE.x - FRAME, FRAME + 3.0, 1, SIZE.y - FRAME * 2.0 - 6.0)   # o friso entre as tomadas e a coluna do lado
	_lit_rect(div, _metal(-2))
	_lit_rect(Rect2(div.position + Vector2(1, 0), div.size), _metal(2))
	_draw_tray()
	_draw_header()
	_draw_rule(RULES["out"], "")   # a faixa das chaves de escuta
	if exchange == null:
		return
	_draw_strips()
	_draw_rule(RULES["in"], T.text(T.Key.BOARD_INPUTS), false)   # os nomes por cima das faixas
	# o nome das saídas embaixo delas, no meio do vão até os bancos, sobre uma faixa como a das entradas, que separa as
	# seções (a faixa entre as entradas e as saídas é das chaves de escuta)
	_draw_rule(roundf((ROW_Y["out"] + JACK / 2.0 + DEST_TOP - 13.0) / 2.0), T.text(T.Key.BOARD_OUTPUTS))
	_draw_trunks(trunks)

	# entradas e saídas
	for i in 10:
		var n := i + 1
		var cx := col_x(i)
		_draw_number_plate(Rect2(cx - 13, ROW_Y["plate"], 26, ROW_Y["plate_h"]), "%02d" % n)
		_draw_jack(jack_rect(n))
		_draw_jack(jack_rect(n + 10), 0.25)

	# destinos: a moldura de cada banco (a faixa de numeração vai nela, por cima da chapa: `_draw_top`)
	for s in _blocks:
		_draw_inset(_blocks[s])
	for d in dest_nums:
		if not GameData.is_trunk(d):   # o tronco tem o nome da cidade em cima (`_draw_trunks`)
			var jr := jack_rect(d)
			var num := PixelArt.tiny(str(d))   # gravado, como o nome dos troncos (em 11, "305" não cabia entre duas tomadas)
			draw_texture(num, Vector2(roundf(jr.get_center().x - num.get_width() / 2.0), jr.position.y - 10.0),
				Pal.NUMBER_PAINT if exchange.dest(d) == Exchange.Dest.FREE else Pal.TEXT)

	_draw_legend()   # na faixa do alto
	_draw_badge(Vector2((FRAME + trunks.position.x) / 2.0, trunks.position.y + 4.0))


## As lâmpadas das linhas (com a luz delas no aro da entrada) e o aro aceso dos destinos. As luzes vão para o `Bloom`,
## cortadas pelos plugs encaixados, que ficam na frente delas.
func _draw_lamps() -> void:
	if exchange == null:
		return
	_ci = _lamps
	Bloom.clear(_lamps)
	var levers := []
	for i in 10:
		var n := i + 1
		var lt: Array = _lit.get("l%d" % n, [LAMP_OFF, 0.0])
		_draw_lamp(Vector2(col_x(i), ROW_Y["lamp"]), lt[0], lt[1])
		_reflect(jack_rect(n), lt[0], lt[1])
		levers.append([Vector2(col_x(i), ROW_Y["key"])] + _lever_pose(n))
	_draw_levers(levers)
	for d in dest_nums:
		var dl: Array = _lit.get("d%d" % d, [LAMP_OFF, 0.0])
		if dl[1] > 0.02:   # o aro em volta da tomada acende (a tomada, por cima, é da `_top`)
			var jr := jack_rect(d)
			PixelArt.sprite(_lamps, _disc(JACK_PX + 6, [[JACK_PX / 2.0 + 3.0, Color.WHITE]]), jr.get_center(), Color(dl[0], dl[1]))
			Bloom.light(_lamps, jr.grow((JACK_PX - JACK) / 2.0 + 2.0), Color(dl[0], dl[1]), 1.0, false, true)
	for e in ends.size():
		if ends[e] != -1:
			Bloom.occlude(_lamps, Transform2D(0.0, jack_rect(int(ends[e])).get_center().round()) * _plug_outline(e, 1.0))
	_ci = self
	_glow_params()


## As luzes que as lâmpadas acabaram de declarar ao `Bloom` vão também para o brilho no painel (`_glow`), com o fim do
## halo delas: só parâmetros, nada se redesenha por isso.
func _glow_params() -> void:
	var lights := PackedVector4Array()
	var colors := PackedColorArray()
	for l: Array in Bloom.lights_of(_lamps):
		var r: Rect2 = l[0]
		var col: Color = l[1]
		if lights.size() < 16:
			lights.append(Vector4(r.get_center().x, r.get_center().y, r.size.x / 2.0 + Bloom.SPREAD, col.a))
			colors.append(Color(col, 1.0))
	var m := _glow.material as ShaderMaterial
	m.set_shader_parameter("count", lights.size())
	m.set_shader_parameter("lights", lights)
	m.set_shader_parameter("colors", colors)


## Por cima das lâmpadas: as tomadas dos destinos (o aro aceso fica em volta delas), as chapas dos bancos que ainda não
## são do operador, a luz da sala, que cai em tudo o que é do painel, e, por cima dela, o brilho do níquel das tomadas.
func _draw_top() -> void:
	if exchange == null:
		return
	_ci = _top
	for d in dest_nums:
		_draw_jack(jack_rect(d))
	for s in _blocks:
		if not s in GameData.sectors:
			_draw_plate(_blocks[s], "ABC"[SECTOR_ORDER.find(s)])
	if not side_used:   # a coluna do lado, tampada até chegar o primeiro equipamento dela
		_draw_plate(side_rect().grow(-1), "")
	for s in GameData.sectors:   # a faixa de numeração na moldura de cima, à esquerda, como o nome do INTERURBANO (a chapa dispensa)
		var br: Rect2 = _blocks[s]
		var cap := PixelArt.tiny("%d-%d" % [s * 100, s * 100 + 99])
		var at := Vector2(br.position.x + 10.0, br.position.y - 5.0).round()   # (passando o parafuso da chapa)
		_top.draw_rect(Rect2(at.x - 3.0, br.position.y - 1.0, cap.get_width() + 6.0, 3.0), Pal.BOARD_INSET)
		_top.draw_texture(cap, at, Pal.BOARD_INK)
	_draw_room_light(Rect2(Vector2.ZERO, size).grow(-FRAME))
	var jacks := []
	for n in 20:
		jacks.append([jack_rect(n + 1), 1.0 if n < 10 else 0.6])   # nas saídas, de metal mais escuro, mais fraco
	for d in dest_nums:
		jacks.append([jack_rect(d), 1.0])
	_draw_glints(jacks)
	_ci = self


## Os plugs e os fios, na frente do painel, e o balão de informação.
func _draw_cords() -> void:
	if exchange == null:
		return
	_ci = _cords
	# destaque da tomada sob o plug (antes de virar arraste, soltar desencaixa: sem destaque)
	if held != -1 and _dragged:
		var hj := jack_at(get_local_mouse_position())
		if hj != -1:
			var ok := refuse(held, hj) == ""
			var hr := jack_rect(hj)
			_cords.draw_arc(hr.get_center(), hr.size.x / 2.0 + 3.0, 0.0, TAU, 32, Pal.GLOW if ok else Pal.RED, 2.0)
			if ok:
				var gc := Pal.GLOW
				gc.a = 0.2
				_cords.draw_rect(hr, gc)

	# cada ponta (fio e plug) na ordem em que foi mexida: o fio da mais recente passa por cima dos plugs encaixados
	# das outras (e se apoia neles, `Cord.pegs`); as sombras antes, por baixo de tudo. Fileira por fileira, de trás para
	# a frente: os encaixados que saem dela, depois os guardados em pé nela. O fio vai do buraco para trás, até o painel:
	# passa atrás dos guardados da fileira dele e dos da frente (antes, por dentro deles) e, saindo da fileira da frente,
	# na frente dos da de trás (só fica mais fundo que eles a 14/18 do caminho, já alto). Por último os da mão e os soltos, que
	# vêm para a frente
	var front := func(e: int) -> bool: return e % 2 == 0 and e != 0
	var home := _order.filter(func(e: int) -> bool: return _in_hole(e))
	var seated := _order.filter(func(e: int) -> bool: return ends[e] != -1)
	var order: Array = seated.filter(func(e: int) -> bool: return not front.call(e)) + home.filter(func(e: int) -> bool: return not front.call(e)) \
		+ seated.filter(front) + home.filter(front) + _order.filter(func(e: int) -> bool: return ends[e] == -1 and not _in_hole(e))
	for x in _draped:   # o fio que corre por cima de um plug vem depois dele
		for c in _draped[x]:
			if order.find(c) < order.find(x):
				order.erase(c)
				order.insert(order.find(x) + 1, c)
	for e in order:
		_draw_rope(e, true)
		_draw_plug(e, true)
	for e in _pulled:   # plugs que acabaram de sair: o cotovelo sumindo no encaixe
		var k: float = _pulled[e][0] / MORPH_SEC
		_cords.draw_set_transform(_pulled[e][1], 0.0, Vector2.ONE * lerpf(1.0, 0.4, k))
		_draw_elbow(_cable_col(e), _pulled[e][2], 0.0, 1.0 - k, -1, _lit_by(_pulled[e][1]))
		_cords.draw_set_transform(Vector2.ZERO)
	# a beira da frente de cada buraco, antes de fios e plugs: o fio deitado na prateleira passa por cima dela (desenhada
	# depois de cada fio, ela cobria os que passavam pelo buraco antes) e o plug guardado, cortado nela (`_cut`), entra
	# atrás; o fio que sai do buraco começa no meio dele e, subindo, não chega à beira
	for e in order:
		draw_lip(_cords, hole(e))
	_laid.clear()
	for e in order:   # o plug por cima do fio dele: em pé, o fio entra na traseira; encaixado, sai do pé da capa
		_draw_rope(e, false)
		_draw_plug(e, false)

	# balão de informação
	if PixelArt.ms() < info_until and info_line > 0:
		var jr := jack_rect(info_line)
		var bw := 150.0
		var bh := 8.0 + info_lines.size() * 14.0
		var bx := clampf(jr.get_center().x - bw / 2, 6, size.x - bw - 6)
		var by := minf(jr.end.y + 6, size.y - bh - 6)
		var bc := Pal.GHOST if info_ghost else Pal.BRASS
		_cords.draw_rect(Rect2(bx, by, bw, bh), bc)
		_cords.draw_rect(Rect2(bx + 2, by + 2, bw - 4, bh - 4), Pal.BALLOON)
		for k in info_lines.size():
			_cords.draw_string(Pal.mono, Vector2(bx + 7, by + 14 + k * 14), info_lines[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.GHOST if info_ghost else Pal.TEXT)
	_ci = self


## O painel e as camadas por cima dele, tudo de novo.
func _redraw_all() -> void:
	for layer in _layers:
		layer.queue_redraw()


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_redraw_all()
