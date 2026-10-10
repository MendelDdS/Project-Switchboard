class_name Toll
extends VBoxContainer
## O calculógrafo da mesa visto de perto (a ferramenta `Tools.TOLL`, aberta pelo objeto dele na mesa): a máquina que
## conta as ligações interurbanas e imprime os bilhetes de tarifação e, embaixo, o tampo da mesa (`%Desk`) com a
## almofada de tinta, a caixinha dos bilhetes e, soltos, os bilhetes e o carimbo. Começa a contar sozinho quando a
## telefonista de lá completa a ligação (`start`) e, quando a conversa acaba (a linha sai de conectada,
## `Main._update_line_timers`), imprime o bilhete (`stop`, um `TollTicket`), que cai na mesa logo embaixo da fenda.
## Bilhetes e carimbo andam livres pela mesa e ficam onde são soltos (`_on_desk_input`: pegar, levar e soltar, com a
## sombra afastada enquanto estão na mão); o carimbo solto em cima de um bilhete o carimba, onde o meio dele caiu, e o
## bilhete solto na caixinha (o mouse em cima dela) é guardado (`file`); sem o carimbo, o supervisor anota (`unstamped`).

signal unstamped(t: TollTicket)

const DIAL := 64   ## o mostrador do relógio da máquina (px)
const PAD := Vector2(150, 44)   ## a almofada de tinta, no canto de baixo à esquerda da mesa
const BOX := Vector2(220, 92)   ## a caixinha dos bilhetes, no canto de baixo à direita
const BLOCK := Vector2(2, 2)    ## onde começa o bloco do carimbo (do tamanho da borracha, `TollTicket.MARK_SIZE`) no nó dele

var filed := 0   ## bilhetes na caixinha
## O minuto do turno (o Main atualiza a cada quadro): o relógio da máquina e os minutos de quem está falando.
var now := 0.0:
	set(v):
		if int(v) != int(now) and is_node_ready():
			_machine.queue_redraw()
		now = v
var _meters := {}   # entrada -> [cidade, número de lá, minuto em que a outra ponta atendeu]: contando
var _serial := 0
var _tickets: Array[TollTicket] = []   # na mesa, esperando a caixinha
var _fresh: Array[TollTicket] = []     # impressos com a mesa ainda sem tamanho (a ferramenta nunca aberta): vão para a saída da fenda quando ela se arruma
var _held: Control = null   # na mão: um bilhete ou o carimbo
var _grab := Vector2.ZERO   # onde ele foi pego (coordenadas dele)
var _placed := false        # o carimbo já está na mesa (começa na almofada)

@onready var _machine: Control = %Machine
@onready var _desk: Control = %Desk
@onready var _stamp: Control = %Stamp


func _ready() -> void:
	_machine.draw.connect(_draw_machine)
	_desk.draw.connect(_draw_desk)
	_stamp.draw.connect(_draw_stamp)
	_desk.gui_input.connect(_on_desk_input)
	_desk.resized.connect(_arrange)
	_stamp.size = TollTicket.MARK_SIZE + BLOCK * 2.0 + Vector2(0, 2)   # a borracha aparece embaixo do bloco


## A outra ponta atendeu o interurbano da entrada `line` (para a cidade `city`, o número `far` de lá) no minuto `at`.
func start(line: int, city: String, far: String, at: float) -> void:
	_meters[line] = [city, far, at]
	_machine.queue_redraw()


func counting(line: int) -> bool:
	return _meters.has(line)


## Há interurbano sendo contado (a luz âmbar do calculógrafo da mesa).
func metering() -> bool:
	return not _meters.is_empty()


## A conversa da entrada `line` acabou no minuto `at`: o bilhete sai impresso e cai na mesa.
func stop(line: int, at: float) -> TollTicket:
	var m: Array = _meters[line]
	_meters.erase(line)
	_serial += 1
	var t := TollTicket.new()
	t.serial = _serial
	t.line = line
	t.city = m[0]
	t.far = m[1]
	t.start = m[2]
	t.end = at
	_tickets.append(t)
	_fresh.append(t)
	_desk.add_child(t)
	_arrange()
	_machine.queue_redraw()
	return t


## Os bilhetes impressos ainda na mesa, esperando ir para a caixinha.
func tickets() -> Array[TollTicket]:
	return _tickets


## Quantos bilhetes esperam a caixinha (a cada quadro, para o calculógrafo da mesa).
func waiting() -> int:
	return _tickets.size()


## Guarda o bilhete na caixinha; sem o carimbo, o supervisor anota.
func file(t: TollTicket) -> void:
	filed += 1
	if not t.stamped:
		unstamped.emit(t)
	_tickets.erase(t)
	_fresh.erase(t)
	_desk.remove_child(t)
	t.queue_free()
	Sfx.play("drop")
	_desk.queue_redraw()


## A mesa ganhou tamanho: o carimbo na almofada (da primeira vez), os bilhetes novos embaixo da fenda (um pouco
## desencontrados) e tudo dentro dela.
func _arrange() -> void:
	if _desk.size.x < TollTicket.SIZE.x:   # (ainda sem tamanho: a ferramenta nunca aberta)
		return
	if not _placed:
		_placed = true
		_stamp.position = (_pad().get_center() - _stamp.size / 2.0).round()
	for t in _fresh:
		var i := _tickets.find(t) % 4
		t.position = Vector2(roundf(_screen().get_center().x - TollTicket.SIZE.x / 2.0) + i * 14.0, 4.0 + i * 12.0)
	_fresh.clear()
	for c: Control in _desk.get_children():
		c.position = _inside(c, c.position)


## `p` (o canto do `c`) dentro da mesa.
func _inside(c: Control, p: Vector2) -> Vector2:
	return p.clamp(Vector2.ZERO, (_desk.size - c.size).max(Vector2.ZERO)).round()


## O que está em `p` na mesa, o de cima primeiro (um bilhete ou o carimbo; nulo = a mesa).
func _piece_at(p: Vector2, only_tickets := false) -> Control:
	for i in range(_desk.get_child_count() - 1, -1, -1):
		var c := _desk.get_child(i) as Control
		if c.get_rect().has_point(p) and (c is TollTicket or not only_tickets):
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


## Solta o que está na mão: o carimbo carimba o bilhete de cima embaixo do meio dele (uma vez só); o bilhete com o
## mouse em cima da caixinha vai para ela.
func _put(at: Vector2) -> void:
	var c := _held
	_held = null
	_lift(c, false)
	if c == _stamp:
		var mid := _stamp.position + BLOCK + TollTicket.MARK_SIZE / 2.0
		var t := _piece_at(mid, true) as TollTicket
		if t and not t.stamped:
			t.stamp(mid - t.position)
			Sfx.play("thump")
	elif _box().has_point(at):
		file(c as TollTicket)


func _lift(c: Control, on: bool) -> void:
	if c is TollTicket:
		(c as TollTicket).held = on
	c.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for c: Control in [_machine, _desk]:
			c.queue_redraw()


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


## O carimbo visto de cima: o bloco de madeira do tamanho da borracha, com a borracha suja de tinta aparecendo
## embaixo, e o pegador redondo no meio; na mão, a sombra se afasta (`TollTicket.LIFT`).
func _draw_stamp() -> void:
	var ci := _stamp
	var held := _held == _stamp
	var block := Rect2(BLOCK, TollTicket.MARK_SIZE)
	var off := TollTicket.LIFT if held else Vector2(2, 3)
	ci.draw_rect(Rect2(block.position + off, block.size + Vector2(0, 2)), Color(0, 0, 0, 0.25 if held else 0.4))
	ci.draw_rect(Rect2(block.position.x + 1.0, block.end.y, block.size.x - 2.0, 2), TollTicket.MARK.darkened(0.45))   # a borracha
	ci.draw_rect(block, Pal.BOARD[1])
	ci.draw_rect(Rect2(block.position, Vector2(block.size.x, 2)), Pal.BOARD[0])   # a quina de cima pega a luz
	ci.draw_rect(Rect2(block.position.x, block.end.y - 2.0, block.size.x, 2), Pal.BOARD[2])
	for i in 3:   # o veio
		ci.draw_rect(Rect2(block.position.x + 5.0 + i * 9.0, block.position.y + 7.0 + i * 7.0, block.size.x - 18.0 - i * 13.0, 1),
			Pal.BOARD[2].lerp(Pal.BOARD[1], 0.5))
	var knob := 24
	var c := (block.get_center() - Vector2(knob, knob) / 2.0).round()
	ci.draw_texture(PixelArt.disc(knob, [[knob / 2.0, Color(0, 0, 0, 0.35)]]), c + (off / 2.0).round())
	ci.draw_texture(PixelArt.disc(knob, [[knob / 2.0 - 3.0, Pal.BOARD[0], Pal.BOARD[0].lerp(Pal.BOARD[1], 0.5), Pal.BOARD[1]], [knob / 2.0, Pal.BOARD[2]]]), c)


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
	var inside := Rect2(r.position + Vector2(5, 4), Vector2(r.size.x - 10.0, 26))
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
