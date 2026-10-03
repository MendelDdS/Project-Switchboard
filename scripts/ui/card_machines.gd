class_name CardMachines
extends Control
## A ficha de despacho como objeto, por cima do mapa (este nó cobre a aba; fora das máquinas e do cartão o clique vai
## para o mapa, `_has_point`). Três máquinas: a impressora (canto de cima, à direita; desce quando a ficha abre e
## sobe quando fecha, com o × junto), a trituradora (embaixo dela, na borda de baixo) e o transmissor (canto de baixo,
## à esquerda); as duas de baixo sobem quando o cartão sai impresso e descem quando não há cartão. Fechar a ficha (`set_open`)
## espera as máquinas se recolherem (`closed`).
## Marcar o local faz a impressora datilografar o local (`typing`) e imprimir um cartão perfurado (`PunchCard`,
## `printer`), que sai pela fenda já com o local, o bairro e o setor; clicar nele perfura (`PunchCard.click`), e só
## andar `DRAG_START` px com o botão apertado o arrasta. O cartão vai para onde for arrastado, dentro do mapa, e fica onde for solto;
## solto na fenda do transmissor, é puxado e enviado (`inserted`), mesmo incompleto (o supervisor é quem pune); na da
## trituradora, é destruído (`discarded`). A mesa comporta um cartão por vez, de qualquer tipo (`can_print`): enquanto
## houver um, a impressora recusa imprimir outro.
## O cartão é um nó filho (`card`) dentro de uma janela que recorta (`_window`): saindo da impressora, só aparece o
## que passou da fenda; entrando numa máquina, só o que ainda não entrou.

signal inserted
signal discarded
## As máquinas terminaram de se recolher depois de `set_open(false)`: a ficha pode sumir.
signal closed

enum State { IDLE, TYPING, PRINTING, READY, DRAGGING, FEEDING }
## As máquinas que puxam o cartão: o transmissor (envia) e a trituradora (descarta).
enum Machine { SEND, SHRED }

const COL_W := 246.0        # a coluna da impressora e da trituradora, no canto direito
const CARD_W := PunchCard.W
const PRINTER_H := 30.0
const SENDER := Vector2(272, 74)
const SHREDDER_H := 58.0
const SLOT := 12.0          # a fenda de entrada, a partir do topo da máquina
const DRAG_START := 5.0     # px que o mouse anda com o botão apertado até virar arraste (antes disso, é clique)
const NEAR_SLOT := 24.0     # solto com a borda de baixo até esta distância da fenda (e por cima dela), entra
const TYPE_SEC := 0.9       # datilografando o local
const PRINT_SEC := 1.3      # o cartão saindo da impressora, sem parar
const LOWER_SEC := 0.45     # o transmissor e a trituradora subindo ou descendo
const PRINTER_SEC := 0.45   # a impressora descendo ou subindo
const FEED_SEC := 0.8       # o transmissor puxando o cartão...
const READ_SEC := 0.35      # ...e ainda lendo os furos, com ele já dentro, antes de enviar
const SHRED_SEC := 1.2      # a trituradora engolindo o cartão
const REFUSE_SEC := 1.6     # a impressora avisando que já há um cartão na mesa
const HAZARD := Color("d9a521")

var dispatch: Dispatch:
	set(v):
		dispatch = v
		card.dispatch = v
var state := State.IDLE
var _t := 0.0               ## segundos no estado atual
var _up := 0.0              ## 0..1: o transmissor e a trituradora à vista (sobem de baixo)
var _down := 0.0            ## 0..1: a impressora à vista (desce de cima)
var _open := false          ## a ficha aberta (as máquinas à vista)
var _closing := false       ## fechando: avisa `closed` quando as máquinas se recolherem
var _pos := Vector2.ZERO    ## canto do cartão (coordenadas deste nó)
var _from := 0.0            ## altura de onde o cartão começa a entrar na máquina
var _into := Machine.SEND   ## a máquina em que ele está entrando (em FEEDING)
var _grab := Vector2.ZERO   ## onde o mouse pegou o cartão
var _press := Vector2.INF   ## onde o botão foi apertado no cartão (INF = solto): ainda não se sabe se é clique ou arraste
var _shake := Vector2.ZERO  ## a trituradora tremendo (um sorteio por quadro)
var _refused := -1.0        ## segundos desde que a impressora recusou um cartão (-1 = sem aviso)
var _window := Control.new()
var card := PunchCard.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true   # as máquinas saem pelas bordas
	_window.clip_contents = true
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	_window.add_child(card)
	add_child(_window)
	move_child(_window, 0)   # o × da impressora fica por cima do cartão


## O número do último cartão impresso (o que está na mesa, ou o que acabou de entrar numa máquina).
func serial() -> int:
	return card.serial


## A mesa comporta um cartão por vez, de qualquer tipo: enquanto houver um (imprimindo, na mesa ou entrando numa
## máquina), não sai outro; ele precisa ser enviado ou triturado antes. Todo cartão novo passa por `print_card`.
func can_print() -> bool:
	return state == State.IDLE


## Imprime um cartão novo e devolve verdadeiro; com um cartão na mesa, recusa (luz vermelha, aviso e `deny`).
func print_card(place: String, sector: int) -> bool:
	if not can_print():
		_refused = 0.0
		Sfx.play("deny")
		queue_redraw()
		return false
	_refused = -1.0
	card.fill(card.serial + 1, place, sector)
	_go(State.TYPING)
	Sfx.play("typing")
	return true


## Abre (as máquinas entram) ou fecha (saem; depois, `closed`).
func set_open(on: bool) -> void:
	_open = on
	_closing = not on
	queue_redraw()


## Sem cartão (enviado, descartado, ou o despacho foi limpo).
func clear() -> void:
	if state != State.IDLE:
		_go(State.IDLE)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if s == State.PRINTING:
		_pos = _rest() - Vector2(0, card.size.y)   # ainda todo dentro da impressora
	card.held = s == State.DRAGGING
	if s != State.READY:
		card.point(Vector2.INF)
	queue_redraw()


## Redesenha máquinas e cartão. Parado, nada se redesenha sozinho: quem muda o que eles mostram (furos, viaturas)
## chama isto.
func refresh() -> void:
	queue_redraw()
	card.queue_redraw()


# ------------------------------------------------------------------ lugar das coisas

## A impressora, escondida acima da borda (com a tira de papel) enquanto não desce.
func _printer() -> Rect2:
	var up := roundf((1.0 - smoothstep(0.0, 1.0, _down)) * (PRINTER_H + 32.0))
	return Rect2(size.x - 4.0 - COL_W + (COL_W - CARD_W) / 2.0 - 8.0, 2.0 - up, CARD_W + 16.0, PRINTER_H)


func _printer_slot() -> float:
	return _printer().end.y - 5.0


## Onde o cartão fica ao sair da impressora: pendurado na fenda.
func _rest() -> Vector2:
	return Vector2(_printer().position.x + 8.0, _printer_slot())


func _card_rect() -> Rect2:
	return Rect2(_pos, Vector2(CARD_W, card.size.y))


## SEND: o transmissor, no canto de baixo à esquerda. SHRED: a trituradora, embaixo da impressora (treme enquanto
## tritura). As duas ficam escondidas embaixo da borda enquanto não sobem.
func _machine(m: Machine) -> Rect2:
	var k := 1.0 - smoothstep(0.0, 1.0, _up)
	if m == Machine.SEND:
		return Rect2(6.0, size.y - SENDER.y - 4.0 + roundf(k * (SENDER.y + 10.0)), SENDER.x, SENDER.y)
	var y := size.y - SHREDDER_H - 4.0 + roundf(k * (SHREDDER_H + 10.0))
	return Rect2(Vector2(_printer().position.x, y) + _shake, Vector2(_printer().size.x, SHREDDER_H))


func _slot(m: Machine) -> float:
	return _machine(m).position.y + SLOT


## Dentro do mapa (este nó).
func _clamp(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 0.0, maxf(0.0, size.x - CARD_W)), clampf(p.y, 0.0, maxf(0.0, size.y - card.size.y)))


# ------------------------------------------------------------------ tempo

func _process(delta: float) -> void:
	_t += delta
	if _refused >= 0.0:
		_refused += delta
		if _refused > REFUSE_SEC:
			_refused = -1.0
		queue_redraw()
	match state:
		State.TYPING:
			if _t >= TYPE_SEC:
				_go(State.PRINTING)
				Sfx.play("printer")
		State.PRINTING:
			var k := minf(_t / PRINT_SEC, 1.0)
			_pos = _rest() - Vector2(0, card.size.y * (1.0 - k))
			if k >= 1.0:
				_go(State.READY)
		State.FEEDING:
			var sec := FEED_SEC if _into == Machine.SEND else SHRED_SEC
			_pos.y = lerpf(_from, _slot(_into), ease(minf(_t / sec, 1.0), 1.6))
			if _t >= sec + (READ_SEC if _into == Machine.SEND else 0.0):
				_go(State.IDLE)
				(inserted if _into == Machine.SEND else discarded).emit()
	var shredding := state == State.FEEDING and _into == Machine.SHRED
	_shake = Vector2(randi_range(-1, 1), randi_range(-1, 1)) if shredding else Vector2.ZERO
	var shown := _open and state in [State.READY, State.DRAGGING, State.FEEDING]
	var was := Vector2(_up, _down)
	_up = move_toward(_up, 1.0 if shown else 0.0, delta / LOWER_SEC)
	_down = move_toward(_down, 1.0 if _open else 0.0, delta / PRINTER_SEC)
	var close := get_node_or_null("Close") as Control   # o × fica na impressora...
	if close != null:
		close.position.y = _printer().position.y + 5.0
		close.visible = state == State.IDLE   # ...e só sem cartão: com um, a ficha sai enviando ou triturando
	if _closing and _up == 0.0 and _down == 0.0:
		_closing = false
		closed.emit()
	_place_sheet()
	# só o que anima: luzes piscando, impressora, cartão entrando e máquinas subindo ou descendo
	if state in [State.TYPING, State.PRINTING, State.FEEDING] or _refused >= 0.0 or was != Vector2(_up, _down):
		queue_redraw()


## A janela que recorta o cartão: abaixo da fenda da impressora enquanto ele sai, acima da fenda da máquina enquanto
## entra; no resto do tempo, o mapa todo.
func _place_sheet() -> void:
	var win := Rect2(Vector2.ZERO, size)
	if state == State.PRINTING:
		win = Rect2(0, _printer_slot(), size.x, size.y - _printer_slot())
	elif state == State.FEEDING:
		win = Rect2(0, 0, size.x, _slot(_into))
	_window.position = win.position
	_window.size = win.size
	card.visible = state not in [State.IDLE, State.TYPING]
	card.position = _pos - win.position


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		card.point(Vector2.INF)
	elif what == NOTIFICATION_RESIZED:
		if state in [State.READY, State.DRAGGING]:
			_pos = _clamp(_pos)
		queue_redraw()   # as máquinas ficam presas às bordas


# ------------------------------------------------------------------ mouse

func _has_point(p: Vector2) -> bool:
	if _down > 0.0 and _printer().has_point(p) or state == State.DRAGGING:
		return true
	if state in [State.READY, State.FEEDING] and _card_rect().has_point(p):
		return true
	return _up > 0.0 and (_machine(Machine.SEND).has_point(p) or _machine(Machine.SHRED).has_point(p))


## Apertar no cartão não faz nada ainda: andar `DRAG_START` px com o botão apertado o arrasta (de qualquer ponto,
## sem perfurar); soltar antes disso é clique, e perfura a linha.
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		if _press != Vector2.INF and state == State.READY and e.position.distance_to(_press) > DRAG_START:
			_grab = _press - _pos
			_press = Vector2.INF
			_go(State.DRAGGING)
		if state == State.DRAGGING:
			_pos = _clamp(e.position - _grab)
		card.point(e.position - _pos if state == State.READY and _card_rect().has_point(e.position) else Vector2.INF)
		mouse_default_cursor_shape = _cursor(e.position)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and state == State.READY and _card_rect().has_point(e.position):
			_press = e.position
			accept_event()
		elif not e.pressed:
			if state == State.DRAGGING:
				_drop()
			elif _press != Vector2.INF and state == State.READY and card.click(_press - _pos):
				Sfx.play("punch")
			_press = Vector2.INF
			mouse_default_cursor_shape = _cursor(e.position)
			accept_event()


func _cursor(p: Vector2) -> int:
	if state == State.DRAGGING:
		return Control.CURSOR_DRAG
	if state != State.READY or not _card_rect().has_point(p):
		return Control.CURSOR_ARROW
	return card.cursor(p - _pos)


## Solto com a borda de baixo sobre a fenda do transmissor ou da trituradora, entra (o transmissor aceita cartão
## incompleto); em qualquer outro lugar, fica.
func _drop() -> void:
	var bottom := _pos.y + card.size.y
	for m: Machine in [Machine.SEND, Machine.SHRED]:
		var r := _machine(m)
		var centered := absf(_pos.x + CARD_W / 2.0 - r.get_center().x) < CARD_W / 3.0
		if _up > 0.5 and centered and bottom >= _slot(m) - NEAR_SLOT and bottom <= r.end.y:
			_pos.x = r.get_center().x - CARD_W / 2.0
			_from = _pos.y
			_into = m
			_go(State.FEEDING)
			Sfx.play("feed" if m == Machine.SEND else "shred")
			if m == Machine.SEND:
				Sfx.play("read")   # o leitor lendo os furos enquanto o cartão entra
			return
	_go(State.READY)


# ------------------------------------------------------------------ desenho

## As máquinas (o cartão é o `card`, desenhado por cima).
func _draw() -> void:
	if _up > 0.0:
		_draw_sender()
		_draw_shredder()
	if _down > 0.0:
		_draw_printer()
		if state == State.IDLE or state == State.TYPING:
			_draw_tongue()


## Caixa de metal: sombra na mesa, borda, luz em cima e à esquerda, sombra embaixo e à direita, parafusos nos cantos.
func _box(r: Rect2, a := 1.0) -> void:
	draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Color(0, 0, 0, 0.35 * a))
	draw_rect(r, Color(Pal.EDGE, a))
	var b := r.grow(-1.0)
	draw_rect(b, Color(Pal.PANEL, a))
	draw_rect(Rect2(b.position, Vector2(b.size.x, 1)), Color(Pal.PANEL_HI, a))
	draw_rect(Rect2(b.position, Vector2(1, b.size.y)), Color(Pal.PANEL_HI, a))
	draw_rect(Rect2(b.position.x, b.end.y - 2.0, b.size.x, 2), Color(Pal.PANEL_LO, a))
	draw_rect(Rect2(b.end.x - 2.0, b.position.y, 2, b.size.y), Color(Pal.PANEL_LO, a))
	for c in [Vector2(4, 4), Vector2(r.size.x - 7, 4), Vector2(4, r.size.y - 7), Vector2(r.size.x - 7, r.size.y - 7)]:
		draw_rect(Rect2(r.position + c, Vector2(3, 3)), Color(Pal.BRASS, a))
		draw_rect(Rect2(r.position + c + Vector2(1, 1), Vector2(1, 1)), Color(Pal.PANEL_LO, a))   # a fenda do parafuso


## Saída de ar: `n` riscos escuros com o brilho embaixo.
func _vent(at: Vector2, n: int, w: float, a := 1.0) -> void:
	for i in n:
		draw_rect(Rect2(at + Vector2(0, i * 4), Vector2(w, 2)), Color(Pal.PANEL_LO, a))
		draw_rect(Rect2(at + Vector2(0, i * 4 + 2), Vector2(w, 1)), Color(Pal.PANEL_HI, 0.5 * a))


## Fenda de entrada ou saída, com o rebaixo de metal em volta.
func _mouth(x: float, y: float, w: float, a := 1.0) -> void:
	draw_rect(Rect2(x - 3.0, y - 4.0, w + 6.0, 8), Color(Pal.PANEL_HI, 0.6 * a))
	draw_rect(Rect2(x, y - 2.0, w, 4), Color(Color.BLACK, a))


func _led(at: Vector2, on: bool, col: Color, a := 1.0) -> void:
	draw_rect(Rect2(at - Vector2(1, 1), Vector2(7, 7)), Color(Pal.EDGE, a))
	draw_rect(Rect2(at, Vector2(5, 5)), Color(col if on else Pal.PANEL_LO, a))
	if on:
		draw_rect(Rect2(at + Vector2(1, 1), Vector2(1, 1)), Color(1, 1, 1, 0.6 * a))   # o brilho da lâmpada


func _draw_printer() -> void:
	var r := _printer()
	_box(r)
	_mouth(r.position.x + 8.0, _printer_slot(), CARD_W)
	var busy := state in [State.TYPING, State.PRINTING]
	if _refused >= 0.0:   # recusou: luz vermelha piscando e o aviso no lugar do nome
		_led(r.position + Vector2(10, 8), fmod(_refused, 0.3) < 0.15, Pal.RED)
		PunchCard.write(self, Vector2(r.position.x + 22.0, r.position.y + 16.0), T.text(T.Key.CARD_ONE_AT_A_TIME), Pal.RED)
	else:
		_led(r.position + Vector2(10, 8), busy and fmod(_t, 0.24) < 0.12, Pal.AMBER)
		PunchCard.write(self, Vector2(r.position.x + 22.0, r.position.y + 16.0), T.text(T.Key.CARD_PRINTER), Pal.DIM)
	_vent(Vector2(r.end.x - 74.0, r.position.y + 6.0), 3, 28.0)


## Sem cartão, uma tira de papel sai da fenda: o aviso ou, enquanto datilografa, o local aparecendo.
func _draw_tongue() -> void:
	var r := Rect2(_rest().x + 20.0, _printer_slot(), CARD_W - 40.0, 22.0)
	draw_rect(r, PunchCard.CARD_EDGE)
	draw_rect(r.grow(-1.0), PunchCard.CARD)
	var txt := T.text(T.Key.DISPATCH_CLICK_STREET)
	if state == State.TYPING:
		txt = card.place.left(ceili(card.place.length() * minf(_t / (TYPE_SEC * 0.85), 1.0)))
	PunchCard.write(self, Vector2(r.position.x, r.position.y + 15.0), txt, Pal.INK_SOFT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## O transmissor: fenda em cima com setas, placa com o nome, luz de pronto e o aviso, saída de ar e pés.
func _draw_sender() -> void:
	var r := _machine(Machine.SEND)
	var a := 1.0
	for x in [r.position.x + 14.0, r.end.x - 34.0]:
		draw_rect(Rect2(x, r.end.y, 20, 3), Color(Pal.EDGE, a))   # os pés
	_box(r, a)
	var x0 := r.get_center().x - CARD_W / 2.0
	_mouth(x0, r.position.y + SLOT, CARD_W, a)
	for side in [x0 - 10.0, x0 + CARD_W + 4.0]:   # setas apontando a fenda
		draw_colored_polygon(PackedVector2Array([Vector2(side, r.position.y + SLOT - 3.0), Vector2(side + 6.0, r.position.y + SLOT - 3.0),
			Vector2(side + 3.0, r.position.y + SLOT + 2.0)]), Color(Pal.AMBER, a))
	var plate := Rect2(r.position.x + 10.0, r.position.y + 24.0, 112.0, 18.0)
	draw_rect(plate, Color(Pal.BRASS, a))
	draw_rect(plate.grow(-1.0), Color(Pal.BRASS.darkened(0.25), a))
	PunchCard.write(self, Vector2(plate.position.x, plate.position.y + 13.0), T.text(T.Key.CARD_SENDER), Color(Pal.INK, a), plate.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var feeding := state == State.FEEDING and _into == Machine.SEND
	var ready := dispatch.can_send()
	_led(Vector2(r.position.x + 12.0, r.position.y + 52.0), feeding and fmod(_t, 0.2) < 0.1 or not feeding and ready, Pal.AMBER if feeding else Pal.GREEN, a)
	var msg := T.text(T.Key.CARD_SENDING) if feeding else T.text(T.Key.CARD_INSERT)
	PunchCard.write(self, Vector2(r.position.x + 24.0, r.position.y + 60.0), msg, Color(Pal.AMBER, a))
	_vent(Vector2(r.end.x - 60.0, r.position.y + 26.0), 9, 46.0, a)


## A trituradora: fenda com as lâminas, faixa de perigo, nome e saída de ar; treme enquanto tritura.
func _draw_shredder() -> void:
	var r := _machine(Machine.SHRED)
	_box(r)
	var x0 := r.position.x + 8.0
	var y := r.position.y + SLOT
	_mouth(x0, y, CARD_W)
	for x in range(int(x0) + 2, int(x0 + CARD_W) - 4, 6):   # as lâminas aparecendo na fenda
		draw_colored_polygon(PackedVector2Array([Vector2(x, y + 2), Vector2(x + 3, y - 1), Vector2(x + 6, y + 2)]), Pal.DIM)
	var band := Rect2(r.position.x + 6.0, r.position.y + 22.0, r.size.x - 12.0, 8.0)
	draw_rect(band, Color.BLACK)
	for x in range(int(band.position.x) - 8, int(band.end.x), 12):   # faixa amarela e preta
		var poly := PackedVector2Array([Vector2(x, band.end.y), Vector2(x + 6, band.end.y), Vector2(x + 14, band.position.y), Vector2(x + 8, band.position.y)])
		var clipped := Geometry2D.intersect_polygons(poly, PackedVector2Array([band.position, Vector2(band.end.x, band.position.y), band.end, Vector2(band.position.x, band.end.y)]))
		for c in clipped:
			draw_colored_polygon(c, HAZARD)
	var busy := state == State.FEEDING and _into == Machine.SHRED
	_led(r.position + Vector2(10, 38), busy, Pal.RED)
	PunchCard.write(self, Vector2(r.position.x + 22.0, r.position.y + 46.0), T.text(T.Key.CARD_SHREDDER), Pal.DIM)
	_vent(Vector2(r.end.x - 60.0, r.position.y + 37.0), 3, 46.0)
