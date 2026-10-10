class_name Toll
extends VBoxContainer
## O calculógrafo da mesa visto de perto (a ferramenta `Tools.TOLL`, aberta pelo objeto dele na mesa): a máquina que
## conta as ligações interurbanas e imprime os bilhetes de tarifação e, embaixo, o tampo da mesa (`%Desk`) com a
## almofada de tinta, a caixinha dos bilhetes e, soltos, os bilhetes e o carimbo. Começa a contar sozinho quando a
## telefonista de lá completa a ligação (`start`) e, quando a conversa acaba (a linha sai de conectada,
## `Main._update_line_timers`), imprime o bilhete (`stop`, um `TollTicket`), que cai na mesa logo embaixo da fenda
## (com a ferramenta aberta, ele sai da fenda no tempo da impressora e cai, `_emerge`).
## Bilhetes e carimbo andam livres pela mesa e ficam onde são soltos (`_on_desk_input`: pegar, levar e soltar; na mão
## sobem e, soltos, caem, como o cartão do despacho, `Lift`; o carimbo bate na mesa, `_process`); o carimbo solto em
## cima de um bilhete o carimba, onde o meio dele caiu (a borracha seca a cada batida, `INK`, e volta a marcar
## passada na almofada), e o
## bilhete solto na caixinha (o mouse em cima dela) é guardado (`file`) e desce para dentro dela (`_sink`); sem o
## carimbo, o supervisor anota (`unstamped`).

signal unstamped(t: TollTicket)

const DIAL := 64   ## o mostrador do relógio da máquina (px)
const PAD := Vector2(150, 44)   ## a almofada de tinta, no canto de baixo à esquerda da mesa
const BOX := Vector2(220, 92)   ## a caixinha dos bilhetes, no canto de baixo à direita
const BOX_MOUTH := 30.0         ## da beira de trás da caixinha até a frente dela: a boca, onde o bilhete entra e some
const SINK_SEC := 0.3           ## o bilhete descendo para dentro da caixinha
## O carimbo em 3/4, como visto da cadeira (o nó): o cabo, o tampo do bloco, a frente com o nome gravado e a borracha.
const STAMP := Vector2(128, 73)
const STAMP_TOP := Rect2(0, 26, 128, 26)
const STAMP_FRONT := Rect2(0, 52, 128, 18)
const RUBBER_MID := Vector2(64, 60)   ## o meio da borracha na mesa (embaixo do bloco, atrás da frente): onde ele carimba
const KNOB := Vector2(17, 7)          ## o cabo: o raio do cilindro e a meia altura da elipse da boca dele
const KNOB_TOP := 11.0                ## a altura do meio do topo do cabo
## O cabo de baquelite: a faixa na luz, o meio, o lado na sombra, o topo e o brilho do topo.
const BAKELITE: Array[Color] = [Color("5a4a3c"), Color("3d3229"), Color("1d1712"), Color("6e5e4e"), Color("8d7c69")]
const DRY := Color("3a302a")    ## a borracha sem tinta
const INK := 2                  ## batidas depois de passar na almofada: a primeira cheia, a outra mais fraca; depois, seca
const BUMP := Vector2(0.04, -0.07)   ## a batida na mesa: o bloco se achata um pouco (em escala) e volta...
const BUMP_SEC := 0.12               ## ...nesse tempo

var filed := 0   ## bilhetes na caixinha
## O minuto do turno (o Main atualiza a cada quadro): o relógio da máquina e os minutos de quem está falando.
var now := 0.0:
	set(v):
		if int(v) != int(now) and is_node_ready():
			_machine.queue_redraw()
		now = v
var _meters := {}   # entrada -> [cidade, número de lá, minuto em que a outra ponta atendeu, número do bilhete]: contando
var _serial := 0
var _tickets: Array[TollTicket] = []   # na mesa, esperando a caixinha
var _fresh: Array[TollTicket] = []     # impressos com a mesa ainda sem tamanho (a ferramenta nunca aberta): vão para a saída da fenda quando ela se arruma
var _held: Control = null   # na mão: um bilhete ou o carimbo
var _grab := Vector2.ZERO   # onde ele foi pego (coordenadas dele)
var _placed := false        # o carimbo já está na mesa (começa na almofada)
var _stamp_lift := Lift.new()
var _ink := INK      # batidas com tinta que a borracha ainda tem
var _thud := false   # o carimbo foi solto: bate quando chegar na mesa
var _bump := 0.0     # o que falta da batida (s)

@onready var _machine: Control = %Machine
@onready var _desk: Control = %Desk
@onready var _stamp: Control = %Stamp


func _ready() -> void:
	_machine.draw.connect(_draw_machine)
	_desk.draw.connect(_draw_desk)
	_stamp.draw.connect(_draw_stamp)
	_desk.gui_input.connect(_on_desk_input)
	_desk.resized.connect(_arrange)
	_stamp.size = STAMP
	set_process(false)   # só enquanto o carimbo sobe, cai ou bate


## O carimbo subindo ou caindo e, quando chega na mesa, a batida: o som e o bloco se achatando em cima da borracha.
func _process(delta: float) -> void:
	var moving := _stamp_lift.step(delta)
	if not moving and _thud:
		_thud = false
		_bump = BUMP_SEC
		_stamp.pivot_offset = Vector2(STAMP.x / 2.0, STAMP_FRONT.end.y)
		Sfx.play("thump")
	_bump = maxf(_bump - delta, 0.0)
	if not moving and _bump == 0.0:
		set_process(false)
	_stamp.scale = _stamp_lift.scale() + BUMP * sin(PI * _bump / BUMP_SEC)
	_stamp.queue_redraw()


## A outra ponta atendeu o interurbano da entrada `line` (para a cidade `city`, o número `far` de lá) no minuto `at`.
## O número do bilhete já fica reservado (`ticket_of`, para o caderno).
func start(line: int, city: String, far: String, at: float) -> void:
	_serial += 1
	_meters[line] = [city, far, at, _serial]
	_machine.queue_redraw()


## O número do bilhete do interurbano contando na entrada `line` (0 = nenhum).
func ticket_of(line: int) -> int:
	return int(_meters[line][3]) if _meters.has(line) else 0


func counting(line: int) -> bool:
	return _meters.has(line)


## Há interurbano sendo contado (a luz âmbar do calculógrafo da mesa).
func metering() -> bool:
	return not _meters.is_empty()


## A conversa da entrada `line` acabou no minuto `at`: o bilhete sai impresso e cai na mesa.
func stop(line: int, at: float) -> TollTicket:
	var m: Array = _meters[line]
	_meters.erase(line)
	var t := TollTicket.new()
	t.serial = m[3]
	t.line = line
	t.city = m[0]
	t.far = m[1]
	t.start = m[2]
	t.end = at
	_tickets.append(t)
	_fresh.append(t)
	_desk.add_child(t)
	_arrange()
	if is_visible_in_tree():
		_emerge(t)
	_machine.queue_redraw()
	return t


## Os bilhetes impressos ainda na mesa, esperando ir para a caixinha.
func tickets() -> Array[TollTicket]:
	return _tickets


## Quantos bilhetes esperam a caixinha (a cada quadro, para o calculógrafo da mesa).
func waiting() -> int:
	return _tickets.size()


## Guarda o bilhete na caixinha (já conta; a descida é só de vista, `_sink`); sem o carimbo, o supervisor anota.
func file(t: TollTicket) -> void:
	filed += 1
	if not t.stamped:
		unstamped.emit(t)
	_tickets.erase(t)
	_fresh.erase(t)
	_sink(t)


## O bilhete vai para cima da boca da caixinha e desce para dentro, acelerando, sumindo atrás da frente dela (recortado
## pela própria altura, que encolhe até a boca); lá dentro, a caixinha mostra mais uma beira.
func _sink(t: TollTicket) -> void:
	var mouth := _box().position.y + BOX_MOUTH
	var h := TollTicket.SIZE.y
	var sink := func(y: float) -> void:
		t.position.y = roundf(y)
		t.size.y = clampf(mouth - roundf(y), 0.0, h)
	var done := func() -> void:
		t.queue_free()
		Sfx.play("drop")
		_desk.queue_redraw()
	t.clip_contents = true
	var tw := t.create_tween()
	tw.tween_property(t, "position", Vector2(roundf(_box().get_center().x - TollTicket.SIZE.x / 2.0), mouth - h), 0.12)
	tw.tween_method(sink, mouth - h, mouth, SINK_SEC).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(done)


## Visto sair (a ferramenta aberta): o bilhete desce da fenda da máquina no tempo do som da impressora, a beira de
## baixo na frente (recortado pela própria altura, como na caixinha, `_sink`), e cai no lugar dele na mesa.
func _emerge(t: TollTicket) -> void:
	var rest := t.position
	var h := TollTicket.SIZE.y
	var out := func(v: float) -> void:
		t.top = h - roundf(v)
		t.size.y = h - t.top
		t.queue_redraw()
	var slot := Vector2(roundf(_screen().get_center().x - TollTicket.SIZE.x / 2.0), _machine.size.y - 13.0)   # embaixo da fenda (`CardMachines.mouth`)
	t.position = slot + _machine.position - _desk.position
	t.clip_contents = true
	out.call(0.0)
	var tw := t.create_tween()
	tw.tween_method(out, 0.0, h, Background.TIP_SEC)
	tw.tween_callback(func() -> void: t.clip_contents = false)
	tw.tween_property(t, "position", rest, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


## A mesa ganhou tamanho: o carimbo na almofada (da primeira vez), os bilhetes novos embaixo da fenda (um pouco
## desencontrados) e tudo dentro dela.
func _arrange() -> void:
	if _desk.size.x < TollTicket.SIZE.x:   # (ainda sem tamanho: a ferramenta nunca aberta)
		return
	if not _placed:
		_placed = true
		_stamp.position = (_pad().get_center() - RUBBER_MID).round()
	for t in _fresh:
		var i := _tickets.find(t) % 4
		t.position = Vector2(roundf(_screen().get_center().x - TollTicket.SIZE.x / 2.0) + i * 14.0, 4.0 + i * 12.0)
	_fresh.clear()
	for c: Control in _desk.get_children():
		if c == _stamp or c in _tickets:   # (não o que está descendo para a caixinha)
			c.position = _inside(c, c.position)


## `p` (o canto do `c`) dentro da mesa.
func _inside(c: Control, p: Vector2) -> Vector2:
	return p.clamp(Vector2.ZERO, (_desk.size - c.size).max(Vector2.ZERO)).round()


## O que está em `p` na mesa, o de cima primeiro (um bilhete ou o carimbo; nulo = a mesa).
func _piece_at(p: Vector2, only_tickets := false) -> Control:
	for i in range(_desk.get_child_count() - 1, -1, -1):
		var c := _desk.get_child(i) as Control
		if ((c is TollTicket and c in _tickets and not c.clip_contents) or (c == _stamp and not only_tickets)) and c.get_rect().has_point(p):   # (o que sai da fenda ainda não se pega)
			return c
	return null


## Pegar (apertar em cima), levar (o canto segue o mouse de onde foi pego, dentro da mesa) e soltar.
func _on_desk_input(e: InputEvent) -> void:
	if not e is InputEventMouse:
		return
	var b := e as InputEventMouseButton
	if b and b.button_index == MOUSE_BUTTON_LEFT:
		if b.pressed:
			_held = _piece_at(b.position)
			if _held:
				_grab = b.position - _held.position
				_held.move_to_front()
				_lift(_held, true)
		elif _held:
			_put(b.position)
	elif e is InputEventMouseMotion and _held:
		_held.position = _inside(_held, e.position - _grab)
	_desk.mouse_default_cursor_shape = Control.CURSOR_DRAG if _held else (Control.CURSOR_MOVE if _piece_at(e.position) else Control.CURSOR_ARROW)


## Solta o que está na mão: o carimbo carimba o bilhete de cima embaixo do meio dele (uma vez só; seca a borracha um
## pouco) ou, na almofada, ganha tinta; o bilhete com o mouse em cima da caixinha vai para ela.
func _put(at: Vector2) -> void:
	var c := _held
	_held = null
	_lift(c, false)
	if c == _stamp:
		_thud = true
		var mid := _stamp.position + RUBBER_MID
		var t := _piece_at(mid, true) as TollTicket
		if t and not t.stamped:
			t.stamp(mid - t.position, float(_ink) / INK)
			_ink = maxi(_ink - 1, 0)
		elif _pad().has_point(mid):
			_ink = INK
	elif _box().has_point(at):
		file(c as TollTicket)


func _lift(c: Control, on: bool) -> void:
	if on:
		c.pivot_offset = _grab   # chega perto e se afasta em volta de onde a mão pegou
	if c is TollTicket:
		(c as TollTicket).held = on
	else:
		_stamp_lift.held = on
		_thud = false
		_bump = 0.0
		set_process(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for c: Control in [_machine, _desk]:
			c.queue_redraw()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _held:   # guardada com algo na mão: fica onde estava
		var c := _held
		_held = null
		_lift(c, false)


func _pad() -> Rect2:
	return Rect2(6, _desk.size.y - PAD.y - 6, PAD.x, PAD.y)


func _box() -> Rect2:
	return Rect2(_desk.size.x - BOX.x - 6, _desk.size.y - BOX.y - 4, BOX.x, BOX.y)


## O visor da máquina (no desenho dela): no meio, entre o relógio e a placa; a fenda do bilhete fica embaixo dele.
func _screen() -> Rect2:
	var r := Rect2(Vector2.ZERO, _machine.size - Vector2(2, 2)).abs()
	return Rect2(r.position.x + DIAL + 34.0, r.position.y + 12.0, r.size.x - DIAL - 34.0 - 150.0, r.size.y - 40.0)


## A máquina: a caixa de metal das do despacho (`CardMachines.box`) com o relógio redondo à esquerda (os ponteiros na
## hora do turno), o visor com cada interurbano contando (a entrada, a cidade e o número de lá, e os minutos), a placa,
## a luz âmbar acesa enquanto conta e, embaixo, a fenda de onde sai o bilhete.
func _draw_machine() -> void:
	var ci := _machine
	Bloom.clear(ci)
	var r := Rect2(Vector2.ZERO, ci.size - Vector2(2, 2)).abs()
	CardMachines.box(ci, r)
	var c := Vector2(roundf(r.position.x + 16.0 + DIAL / 2.0), roundf(r.position.y + 12.0 + DIAL / 2.0))
	ci.draw_texture(PixelArt.disc(DIAL + 6, [[DIAL / 2.0 - 1.0, Pal.SHEET_NEW], [DIAL / 2.0 + 3.0, Pal.NICKEL[1], Pal.NICKEL[2], Pal.NICKEL[3]]]),
		c - Vector2(DIAL + 6, DIAL + 6) / 2.0)
	for i in 12:   # as marcas das horas
		var d := Vector2.UP.rotated(TAU * i / 12.0)
		ci.draw_rect(Rect2((c + d * (DIAL / 2.0 - 5.0)).round() - Vector2.ONE, Vector2(2, 2) if i % 3 == 0 else Vector2.ONE), Pal.INK)
	var t := Main.SHIFT_START_HOUR * 60 + int(now)
	var mins := Vector2.UP.rotated(TAU * (t % 60) / 60.0)
	var hours := Vector2.UP.rotated(TAU * ((t / 60) % 12 + (t % 60) / 60.0) / 12.0)
	ci.draw_line(c, (c + hours * DIAL * 0.26).round(), Pal.INK, 2.0)
	ci.draw_line(c, (c + mins * DIAL * 0.38).round(), Pal.INK, 1.0)
	ci.draw_rect(Rect2(c - Vector2.ONE, Vector2(2, 2)), Pal.INK_RED)
	var screen := _screen()
	ci.draw_rect(screen.grow(1.0), Pal.EDGE)
	ci.draw_rect(screen, Color("0f0d09"))
	var y := screen.position.y + 15.0
	if _meters.is_empty():
		PunchCard.write(ci, Vector2(screen.position.x + 8.0, y), T.text(T.Key.TOLL_IDLE), Pal.DIM)
	for line: int in _meters:
		if y > screen.end.y - 2.0:
			break
		var m: Array = _meters[line]
		PunchCard.write(ci, Vector2(screen.position.x + 8.0, y), "%02d  %s %s" % [line, String(m[0]).to_upper(), m[1]], Pal.AMBER)
		PunchCard.write(ci, Vector2(screen.position.x, y), T.text(T.Key.TOLL_MIN) % maxi(1, ceili(now - float(m[2]))), Pal.AMBER,
			screen.size.x - 8.0, HORIZONTAL_ALIGNMENT_RIGHT)
		y += 15.0
	var side := Rect2(screen.end.x + 8.0, r.position.y, r.end.x - screen.end.x - 8.0, r.size.y)
	CardMachines.plate(ci, Rect2(side.position.x - 10.0, side.position.y - 10.0, side.size.x, side.size.y), T.text(T.Key.TOLL_MACHINE))
	CardMachines.led(ci, side.position + Vector2(2, 40), metering(), Pal.AMBER)
	CardMachines.vent(ci, side.position + Vector2(18, 40), 4, side.size.x - 34.0)
	CardMachines.mouth(ci, roundf(screen.get_center().x - TollTicket.SIZE.x / 2.0), r.end.y - 12.0, TollTicket.SIZE.x)


## O carimbo em 3/4: o bloco de madeira com o tampo chanfrado na luz e, na frente, o nome gravado num rebaixo; a
## borracha suja de tinta aparecendo embaixo; e, no meio do tampo, o cabo de baquelite (um cilindro, com a sombra no
## tampo e o brilho no topo). Na mão, a sombra na mesa se afasta (`_stamp_lift`).
func _draw_stamp() -> void:
	var ci := _stamp
	var wood := Pal.BOARD
	_rounded(ci, Rect2(STAMP_TOP.position + _stamp_lift.shadow(), Vector2(STAMP.x, STAMP.y - STAMP_TOP.position.y)), Lift.SHADOW)
	ci.draw_rect(Rect2(2, STAMP_FRONT.end.y, STAMP.x - 4.0, STAMP.y - STAMP_FRONT.end.y), TollTicket.MARK.darkened(0.45).lerp(DRY, 1.0 - float(_ink) / INK))   # a borracha
	_rounded(ci, STAMP_FRONT, wood[1])
	ci.draw_rect(Rect2(STAMP_FRONT.position, Vector2(STAMP.x, 2)), wood[0].lerp(wood[1], 0.4))   # a quina arredondada entre o tampo e a frente
	for x: float in [0.0, STAMP.x - 2.0]:   # os cantos da frente se arredondam: o da esquerda na luz, o da direita na sombra
		ci.draw_rect(Rect2(x, STAMP_FRONT.position.y + 2.0, 2, STAMP_FRONT.size.y - 3.0), wood[1].lerp(wood[0], 0.4) if x == 0.0 else wood[2])
	ci.draw_rect(Rect2(STAMP_FRONT.position.x + 1.0, STAMP_FRONT.end.y - 2.0, STAMP.x - 2.0, 2), wood[2])
	var label := T.text(T.Key.TOLL_STAMP)
	var lw := roundf(Pal.mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x) + 12.0
	var plate := Rect2(roundf((STAMP.x - lw) / 2.0), STAMP_FRONT.position.y + 4.0, lw, 12)
	ci.draw_rect(plate, wood[2])
	ci.draw_rect(Rect2(plate.position, Vector2(plate.size.x, 1)), wood[2].darkened(0.35))   # a beira de cima do rebaixo, na sombra
	PunchCard.write(ci, Vector2(plate.position.x, plate.end.y - 2.0), label, wood[0], plate.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_rounded(ci, STAMP_TOP, wood[0])   # o tampo: a beira chanfrada, na luz, em volta do meio, mais baixo
	ci.draw_rect(Rect2(STAMP_TOP.position.x + 2.0, STAMP_TOP.position.y, STAMP.x - 4.0, 1), wood[0].lightened(0.2))   # a quina de trás
	var mid := STAMP_TOP.grow_individual(-5, -5, -5, -4)
	ci.draw_rect(mid, wood[0].lerp(wood[1], 0.45))
	ci.draw_rect(Rect2(mid.position - Vector2(0, 1), Vector2(mid.size.x, 1)), wood[1])   # o chanfro de trás, na sombra
	ci.draw_rect(Rect2(mid.position.x, mid.end.y, mid.size.x, 1), wood[0].lightened(0.1))   # o da frente, virado para a luz
	for x: float in [12.0, 90.0]:   # o veio
		ci.draw_rect(Rect2(x, mid.position.y + 5.0, 26, 1), wood[0].lerp(wood[1], 0.75))
		ci.draw_rect(Rect2(x + 6.0, mid.position.y + 11.0, 18, 1), wood[0].lerp(wood[1], 0.75))
	var base := Vector2(STAMP.x / 2.0, STAMP_TOP.get_center().y)
	_ellipse(ci, base + Vector2(3, 2), KNOB + Vector2.ONE, wood[1].darkened(0.2))   # a sombra do cabo no tampo
	for i in int(KNOB.x * 2.0):   # o cilindro, coluna a coluna: a faixa na luz à esquerda, o meio e o lado na sombra
		var dx := i + 0.5 - KNOB.x
		var u := i / (KNOB.x * 2.0)
		var col := BAKELITE[1] if u < 0.15 or (u >= 0.4 and u < 0.75) else (BAKELITE[0] if u < 0.4 else BAKELITE[2])
		var bottom := roundf(base.y + KNOB.y * sqrt(1.0 - (dx / KNOB.x) ** 2))
		ci.draw_rect(Rect2(base.x - KNOB.x + i, KNOB_TOP, 1, bottom - KNOB_TOP), col)
	_ellipse(ci, Vector2(base.x, KNOB_TOP), KNOB, BAKELITE[3])
	_ellipse(ci, Vector2(base.x - 3.0, KNOB_TOP - 1.0), Vector2(6, 2), BAKELITE[4])


## Retângulo com os cantos de 1 px cortados (sem sobrepor: a sombra transparente fica por igual).
static func _rounded(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x + 1.0, r.position.y, r.size.x - 2.0, r.size.y), c)
	for x: float in [r.position.x, r.end.x - 1.0]:
		ci.draw_rect(Rect2(x, r.position.y + 1.0, 1, r.size.y - 2.0), c)


## Elipse cheia de meios-eixos `r` em volta de `c`, linha a linha.
static func _ellipse(ci: CanvasItem, c: Vector2, r: Vector2, col: Color) -> void:
	for i in int(r.y * 2.0):
		var half := roundf(r.x * sqrt(1.0 - ((i + 0.5 - r.y) / r.y) ** 2))
		ci.draw_rect(Rect2(roundf(c.x) - half, roundf(c.y - r.y) + i, half * 2.0, 1), col)


## O tampo: a almofada de tinta (a lata com o feltro vermelho) e a caixinha de madeira, aberta, com a borda de cima de
## cada bilhete guardado (até alguns) e a plaqueta de latão na frente.
func _draw_desk() -> void:
	var ci := _desk
	var pad := _pad()
	ci.draw_rect(Rect2(pad.position + Vector2(2, 3), pad.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(pad, Pal.NICKEL[3])
	ci.draw_rect(pad.grow(-1.0), Pal.NICKEL[2])
	ci.draw_rect(Rect2(pad.position + Vector2(1, 1), Vector2(pad.size.x - 2.0, 1)), Pal.NICKEL[1])
	ci.draw_rect(pad.grow(-5.0), TollTicket.MARK.darkened(0.55))   # o feltro
	ci.draw_rect(Rect2(pad.position + Vector2(5, 5), Vector2(pad.size.x - 10.0, 1)), TollTicket.MARK.darkened(0.35))
	var r := _box()
	ci.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(r, Pal.BOARD[2])
	var inside := Rect2(r.position + Vector2(5, 4), Vector2(r.size.x - 10.0, BOX_MOUTH - 4.0))
	ci.draw_rect(inside, Color("140e09"))
	for i in mini(filed, 12):   # os bilhetes de pé lá dentro, cada um um pouco mais para trás
		ci.draw_rect(Rect2(inside.position.x + 4.0 + (i * 5) % 9, inside.end.y - 4.0 - i * 1.5, inside.size.x - 16.0, 1),
			TollTicket.PAPER.darkened(0.15 + i * 0.03))
	var front := Rect2(r.position.x, inside.end.y, r.size.x, r.end.y - inside.end.y)
	ci.draw_rect(front, Pal.BOARD[1])
	ci.draw_rect(Rect2(front.position, Vector2(front.size.x, 2)), Pal.BOARD[0])
	ci.draw_rect(Rect2(front.position.x, front.end.y - 2.0, front.size.x, 2), Pal.BOARD[2])
	var brass := Rect2(floorf(front.get_center().x - 50.0), front.position.y + roundf(front.size.y / 2.0) - 9.0, 100, 18)
	ci.draw_rect(brass, Pal.BRASS)
	ci.draw_rect(brass.grow(-1.0), Pal.BRASS.darkened(0.25))
	PunchCard.write(ci, Vector2(brass.position.x, brass.position.y + 13.0), T.text(T.Key.TOLL_BOX), Pal.INK, brass.size.x, HORIZONTAL_ALIGNMENT_CENTER)
