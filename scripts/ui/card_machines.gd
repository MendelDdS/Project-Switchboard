class_name CardMachines
extends Control
## A unidade de despacho vista de perto, em volta do mapa sob o vidro: a moldura de metal e, embaixo, a base (este nó
## cobre o papel todo; fora da moldura, da base e do cartão o clique vai para o mapa, `_has_point`; o cartão passa por
## cima de tudo, até a borda de baixo). Três máquinas lado a lado, sempre à vista, como na base da
## unidade da mesa (`Background._art_deck`): o transmissor à esquerda, a impressora no meio e a trituradora à direita,
## afastadas para o cartão impresso não cair numa delas sem querer (com a impressora logo acima da trituradora, solto
## ali mesmo, ele era triturado). Marcar o local faz a impressora datilografar o local (`typing`) e imprimir um cartão
## perfurado (`PunchCard`, `printer`), que sobe pela fenda dela, para cima do vidro, já com o local, o bairro e o setor;
## clicar nele perfura (`PunchCard.click`), e só andar `DRAG_START` px com o botão apertado o arrasta. O cartão vai para
## onde for arrastado, na unidade toda, e fica onde for solto; solto com a borda de baixo na fenda do transmissor, é
## puxado e enviado (`inserted`), mesmo incompleto (o supervisor é quem pune); na da trituradora, é destruído
## (`discarded`). A mesa comporta um cartão por vez, de qualquer tipo (`can_print`): enquanto houver um, a impressora
## recusa imprimir outro.
## O cartão é um nó filho (`card`) dentro de uma janela que recorta (`_window`): saindo da impressora ou entrando numa
## máquina, só aparece o que está acima da fenda.

signal inserted
signal discarded

enum State { IDLE, TYPING, PRINTING, READY, DRAGGING, FEEDING }
## As máquinas que puxam o cartão: o transmissor (envia) e a trituradora (descarta).
enum Machine { SEND, SHRED }

const BEZEL := 12.0         ## a moldura de metal em volta do vidro (px; o mapa, `Dispatch.city`, fica dentro dela)
const BASE_H := 96.0        ## a altura da base das máquinas, embaixo do vidro
const STRIP := 14.0         ## a faixa da frente da base, embaixo das máquinas: as luzes e a plaqueta, como na miniatura da mesa
const TONGUE_H := 22.0      ## a tira de papel saindo da impressora sem cartão (sobe sobre o pé do mapa)
const CARD_W := PunchCard.W
const SLOT := 12.0          # as fendas, a partir do alto da base
const DRAG_START := 5.0     # px que o mouse anda com o botão apertado até virar arraste (antes disso, é clique)
const NEAR_SLOT := 24.0     # solto com a borda de baixo até esta distância da fenda (e por cima dela), entra
const TYPE_SEC := 0.9       # datilografando o local
const PRINT_SEC := 1.3      # o cartão saindo da impressora, sem parar
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
var _pos := Vector2.ZERO    ## canto do cartão (coordenadas deste nó)
var _from := 0.0            ## altura de onde o cartão começa a entrar na máquina
var _into := Machine.SEND   ## a máquina em que ele está entrando (em FEEDING)
var _grab := Vector2.ZERO   ## onde o mouse pegou o cartão
var _press := Vector2.INF   ## onde o botão foi apertado no cartão (INF = solto): ainda não se sabe se é clique ou arraste
var _shake := Vector2.ZERO  ## a trituradora tremendo (um sorteio por quadro)
var _refused := -1.0        ## segundos desde que a impressora recusou um cartão (-1 = sem aviso)
var _alert := false         ## a luz vermelha da faixa: uma emergência em andamento
var _window := Control.new()
var card := PunchCard.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_window.clip_contents = true
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	_window.add_child(card)
	add_child(_window)


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


## Sem cartão (enviado, descartado, ou o despacho foi limpo).
func clear() -> void:
	if state != State.IDLE:
		_go(State.IDLE)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if s == State.PRINTING:
		_pos = _rest() + Vector2(0, card.size.y)   # ainda todo dentro da impressora
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

## A base, embaixo do vidro, na largura toda.
func _base() -> Rect2:
	return Rect2(0, size.y - BASE_H, size.x, BASE_H)


## A fenda de cada máquina (`i`: 0 o transmissor, 1 a impressora, 2 a trituradora), da largura do cartão, com a mesma
## folga entre elas e as beiras.
func _mouth_x(i: int) -> float:
	var gap := maxf(0.0, (size.x - CARD_W * 3.0) / 4.0)
	return roundf(gap + i * (CARD_W + gap))


## O pedaço da base de cada máquina (`i` como em `_mouth_x`).
func _part(i: int) -> Rect2:
	var gap := maxf(0.0, (size.x - CARD_W * 3.0) / 4.0)
	var b := _base()
	return Rect2(_mouth_x(i) - floorf(gap / 2.0) + 2.0, b.position.y + 4.0, CARD_W + gap - 4.0, b.size.y - 8.0 - STRIP)


## A impressora, no meio da base.
func _printer() -> Rect2:
	return _part(1)


func _printer_slot() -> float:
	return _base().position.y + SLOT


## Onde o cartão fica ao sair da impressora: em pé na fenda dela, para cima do vidro.
func _rest() -> Vector2:
	return Vector2(_mouth_x(1), _printer_slot() - card.size.y)


func _card_rect() -> Rect2:
	return Rect2(_pos, Vector2(CARD_W, card.size.y))


## SEND: o transmissor, à esquerda. SHRED: a trituradora, à direita (treme enquanto tritura).
func _machine(m: Machine) -> Rect2:
	var r := _part(0 if m == Machine.SEND else 2)
	return Rect2(r.position + (_shake if m == Machine.SHRED else Vector2.ZERO), r.size)


func _slot(m: Machine) -> float:
	return _base().position.y + SLOT + (_shake.y if m == Machine.SHRED else 0.0)


## Dentro da unidade toda: o cartão passa por cima da moldura e das máquinas, até a borda de baixo.
func _clamp(p: Vector2) -> Vector2:
	return p.clamp(Vector2.ZERO, (size - card.size).max(Vector2.ZERO))


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
			_pos = _rest() + Vector2(0, card.size.y * (1.0 - k))
			if k >= 1.0:
				_go(State.READY)
		State.FEEDING:
			var sec := FEED_SEC if _into == Machine.SEND else SHRED_SEC
			_pos.y = lerpf(_from, _slot(_into), ease(minf(_t / sec, 1.0), 1.6))
			if _t >= sec + (READ_SEC if _into == Machine.SEND else 0.0):
				_go(State.IDLE)
				(inserted if _into == Machine.SEND else discarded).emit()
	var alert := dispatch != null and not dispatch.fleet.incident.is_empty()
	if alert != _alert:
		_alert = alert
		queue_redraw()
	var shredding := state == State.FEEDING and _into == Machine.SHRED
	_shake = Vector2(randi_range(-1, 1), randi_range(-1, 1)) if shredding else Vector2.ZERO
	_place_sheet()
	# só o que anima: luzes piscando, impressora, cartão entrando
	if state in [State.TYPING, State.PRINTING, State.FEEDING] or _refused >= 0.0:
		queue_redraw()


## A janela que recorta o cartão: acima das fendas enquanto ele sai da impressora ou entra numa máquina; no resto do
## tempo, o papel todo.
func _place_sheet() -> void:
	var win := Rect2(Vector2.ZERO, size)
	if state == State.PRINTING:
		win = Rect2(0, 0, size.x, _printer_slot())
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
		queue_redraw()   # as máquinas ficam presas à base


# ------------------------------------------------------------------ mouse

func _has_point(p: Vector2) -> bool:
	if state == State.DRAGGING or _base().has_point(p) or not Rect2(Vector2.ONE * BEZEL, size - Vector2.ONE * BEZEL * 2.0).has_point(p):
		return true
	return state in [State.READY, State.FEEDING] and _card_rect().has_point(p)


## Apertar no cartão não faz nada ainda: andar `DRAG_START` px com o botão apertado o arrasta (de qualquer ponto,
## sem perfurar); soltar antes disso é clique, e perfura a linha.
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		if _press != Vector2.INF and state == State.READY and e.position.distance_to(_press) > DRAG_START:
			_grab = _press - _pos
			card.pivot_offset = _grab   # chega perto e se afasta em volta de onde a mão pegou
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
## incompleto); em qualquer outro lugar, fica (na fenda da impressora, também).
func _drop() -> void:
	var bottom := _pos.y + card.size.y
	for m: Machine in [Machine.SEND, Machine.SHRED]:
		var x := _mouth_x(0 if m == Machine.SEND else 2)
		var centered := absf(_pos.x - x) < CARD_W / 3.0
		if centered and bottom >= _slot(m) - NEAR_SLOT:
			_pos.x = x
			_from = _pos.y
			_into = m
			_go(State.FEEDING)
			Sfx.play("feed" if m == Machine.SEND else "shred")
			if m == Machine.SEND:
				Sfx.play("read")   # o leitor lendo os furos enquanto o cartão entra
			return
	_go(State.READY)


# ------------------------------------------------------------------ desenho

## A base e as máquinas (o cartão é o `card`, desenhado por cima).
func _draw() -> void:
	Bloom.clear(self)
	_draw_bezel()
	var b := _base()
	draw_rect(Rect2(BEZEL, b.position.y - 3.0, b.size.x - BEZEL * 2.0, 3), Color(0, 0, 0, 0.3))   # a sombra da base no vidro
	draw_rect(b, Pal.EDGE)
	draw_rect(b.grow(-1.0), Pal.PANEL_LO)
	_draw_sender()
	_draw_printer()
	_draw_shredder()
	_draw_strip()
	if state == State.IDLE or state == State.TYPING:
		_draw_tongue()


## A moldura de metal em volta do vidro do mapa (`BEZEL`, até a base): a beira na luz no alto e à esquerda, o rebaixo
## escuro onde o vidro entra (no alto e nos lados; embaixo fica a base), a sombra da moldura no vidro e os parafusos.
func _draw_bezel() -> void:
	var w := BEZEL
	var glass := Rect2(w, w, size.x - w * 2.0, size.y - w - BASE_H)
	for r: Rect2 in [Rect2(0, 0, size.x, w), Rect2(0, 0, w, glass.end.y), Rect2(glass.end.x, 0, w, glass.end.y)]:
		draw_rect(r, Pal.PANEL)
	draw_rect(Rect2(0, 0, size.x, 1), Pal.PANEL_HI)
	draw_rect(Rect2(0, 0, 1, glass.end.y), Pal.PANEL_HI)
	draw_rect(Rect2(size.x - 1, 0, 1, glass.end.y), Pal.PANEL_LO)
	draw_rect(Rect2(w - 1, w - 1, glass.size.x + 2, 1), Pal.EDGE)   # o rebaixo
	draw_rect(Rect2(w - 1, w - 1, 1, glass.size.y + 1), Pal.EDGE)
	draw_rect(Rect2(glass.end.x, w - 1, 1, glass.size.y + 1), Pal.EDGE)
	draw_rect(Rect2(glass.position, Vector2(glass.size.x, 2)), Color(0, 0, 0, 0.3))   # a sombra da moldura no vidro
	draw_rect(Rect2(glass.position + Vector2(0, 2), Vector2(2, glass.size.y - 2)), Color(0, 0, 0, 0.18))
	for c: Vector2 in [Vector2(4, 4), Vector2(size.x - 7, 4), Vector2(4, glass.end.y - 7), Vector2(size.x - 7, glass.end.y - 7)]:
		draw_rect(Rect2(c, Vector2(3, 3)), Pal.BRASS)
		draw_rect(Rect2(c + Vector2(1, 1), Vector2(1, 1)), Pal.PANEL_LO)   # a fenda do parafuso


## A faixa da frente da base, como a frente da unidade da mesa (`Background._draw_dispatch_unit`): a luz vermelha de
## emergência em andamento e a âmbar de cartão na mesa, à esquerda, a plaqueta de latão no meio e a saída de ar.
func _draw_strip() -> void:
	var b := _base()
	var y := b.end.y - STRIP - 3.0
	var mid := y + floorf(STRIP / 2.0)
	_led(Vector2(b.position.x + 12.0, mid - 2.0), _alert, Pal.RED)
	_led(Vector2(b.position.x + 24.0, mid - 2.0), state != State.IDLE, Pal.AMBER)
	var plate := Rect2(floorf(b.get_center().x - 60.0), mid - 3.0, 120, 7)
	draw_rect(plate, Pal.BRASS.darkened(0.25))
	draw_rect(plate.grow(-1.0), Pal.BRASS)
	for x: float in [plate.position.x + 2.0, plate.end.x - 3.0]:   # os parafusos dela
		draw_rect(Rect2(x, mid, 1, 1), Pal.PANEL_LO)
	for i in 3:
		draw_rect(Rect2(b.end.x - 60.0, mid - 3.0 + i * 3, 46, 1), Pal.PANEL_LO)


## Caixa de metal: sombra, borda, luz em cima e à esquerda, sombra embaixo e à direita, parafusos nos cantos.
func _box(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, Pal.EDGE)
	var b := r.grow(-1.0)
	draw_rect(b, Pal.PANEL)
	draw_rect(Rect2(b.position, Vector2(b.size.x, 1)), Pal.PANEL_HI)
	draw_rect(Rect2(b.position, Vector2(1, b.size.y)), Pal.PANEL_HI)
	draw_rect(Rect2(b.position.x, b.end.y - 2.0, b.size.x, 2), Pal.PANEL_LO)
	draw_rect(Rect2(b.end.x - 2.0, b.position.y, 2, b.size.y), Pal.PANEL_LO)
	for c in [Vector2(4, 4), Vector2(r.size.x - 7, 4), Vector2(4, r.size.y - 7), Vector2(r.size.x - 7, r.size.y - 7)]:
		draw_rect(Rect2(r.position + c, Vector2(3, 3)), Pal.BRASS)
		draw_rect(Rect2(r.position + c + Vector2(1, 1), Vector2(1, 1)), Pal.PANEL_LO)   # a fenda do parafuso


## Saída de ar: `n` riscos escuros com o brilho embaixo.
func _vent(at: Vector2, n: int, w: float) -> void:
	for i in n:
		draw_rect(Rect2(at + Vector2(0, i * 4), Vector2(w, 2)), Pal.PANEL_LO)
		draw_rect(Rect2(at + Vector2(0, i * 4 + 2), Vector2(w, 1)), Color(Pal.PANEL_HI, 0.5))


## Fenda de entrada ou saída: um rasgo fino, com a beira de metal na luz embaixo dele.
func _mouth(x: float, y: float, w: float) -> void:
	draw_rect(Rect2(x - 2.0, y - 2.0, w + 4.0, 5), Pal.PANEL_LO)
	draw_rect(Rect2(x, y - 1.0, w, 2), Color.BLACK)
	draw_rect(Rect2(x - 2.0, y + 2.0, w + 4.0, 1), Pal.PANEL_HI)


func _led(at: Vector2, on: bool, col: Color) -> void:
	draw_rect(Rect2(at - Vector2(1, 1), Vector2(7, 7)), Pal.EDGE)
	draw_rect(Rect2(at, Vector2(5, 5)), col if on else Pal.PANEL_LO)
	if on:
		draw_rect(Rect2(at + Vector2(1, 1), Vector2(1, 1)), Color(1, 1, 1, 0.6))   # o brilho da lâmpada
		Bloom.light(self, Rect2(at, Vector2(5, 5)), col)


## A placa de latão com o nome da máquina.
func _plate(r: Rect2, text: String) -> void:
	var plate := Rect2(r.position.x + 10.0, r.position.y + 22.0, minf(112.0, r.size.x - 20.0), 18.0)
	draw_rect(plate, Pal.BRASS)
	draw_rect(plate.grow(-1.0), Pal.BRASS.darkened(0.25))
	PunchCard.write(self, Vector2(plate.position.x, plate.position.y + 13.0), text, Pal.INK, plate.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## A impressora, no meio: a fenda por onde o cartão sobe, a placa, a luz (âmbar trabalhando; vermelha piscando com o
## aviso, quando recusa) e a saída de ar.
func _draw_printer() -> void:
	var r := _printer()
	_box(r)
	_mouth(_mouth_x(1), _printer_slot(), CARD_W)
	_plate(r, T.text(T.Key.CARD_PRINTER))
	var busy := state in [State.TYPING, State.PRINTING]
	if _refused >= 0.0:   # recusou: luz vermelha piscando e o aviso embaixo da placa
		_led(r.position + Vector2(12, 50), fmod(_refused, 0.3) < 0.15, Pal.RED)
		PunchCard.write(self, Vector2(r.position.x + 24.0, r.position.y + 58.0), T.text(T.Key.CARD_ONE_AT_A_TIME), Pal.RED, r.size.x - 30.0)
	else:
		_led(r.position + Vector2(12, 50), busy and fmod(_t, 0.24) < 0.12, Pal.AMBER)
	_vent(Vector2(r.end.x - 44.0, r.position.y + 24.0), 4, 32.0)


## Sem cartão, uma tira de papel sai da fenda da impressora: o aviso ou, enquanto datilografa, o local aparecendo.
func _draw_tongue() -> void:
	var r := Rect2(_mouth_x(1) + 14.0, _printer_slot() - TONGUE_H, CARD_W - 28.0, TONGUE_H)
	draw_rect(r, PunchCard.CARD_EDGE)
	draw_rect(r.grow(-1.0), PunchCard.CARD)
	var txt := T.text(T.Key.DISPATCH_CLICK_STREET)
	if state == State.TYPING:
		txt = card.place.left(ceili(card.place.length() * minf(_t / (TYPE_SEC * 0.85), 1.0)))
	PunchCard.write(self, Vector2(r.position.x, r.position.y + 15.0), txt, Pal.INK_SOFT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## O transmissor, à esquerda: a fenda com setas, a placa, a luz de pronto e o aviso e a saída de ar.
func _draw_sender() -> void:
	var r := _machine(Machine.SEND)
	_box(r)
	var x0 := _mouth_x(0)
	var y := _slot(Machine.SEND)
	_mouth(x0, y, CARD_W)
	for side in [x0 - 10.0, x0 + CARD_W + 4.0]:   # setas apontando a fenda
		if side > r.position.x and side + 6.0 < r.end.x:
			draw_primitive(PackedVector2Array([Vector2(side, y - 3.0), Vector2(side + 6.0, y - 3.0), Vector2(side + 3.0, y + 2.0)]),
				PackedColorArray([Pal.AMBER]), PackedVector2Array())
	_plate(r, T.text(T.Key.CARD_SENDER))
	var feeding := state == State.FEEDING and _into == Machine.SEND
	var ready := dispatch.can_send()
	_led(r.position + Vector2(12, 50), feeding and fmod(_t, 0.2) < 0.1 or not feeding and ready, Pal.AMBER if feeding else Pal.GREEN)
	var msg := T.text(T.Key.CARD_SENDING) if feeding else T.text(T.Key.CARD_INSERT)
	PunchCard.write(self, Vector2(r.position.x + 24.0, r.position.y + 58.0), msg, Pal.AMBER, r.size.x - 30.0)
	_vent(Vector2(r.end.x - 44.0, r.position.y + 24.0), 4, 32.0)


## A trituradora, à direita: a fenda com as lâminas, a faixa de perigo, a placa e a luz; treme enquanto tritura.
func _draw_shredder() -> void:
	var r := _machine(Machine.SHRED)
	_box(r)
	var x0 := _mouth_x(2) + _shake.x
	var y := _slot(Machine.SHRED)
	_mouth(x0, y, CARD_W)
	for x in range(int(x0) + 2, int(x0 + CARD_W) - 4, 6):   # as lâminas aparecendo na fenda
		draw_colored_polygon(PackedVector2Array([Vector2(x, y + 2), Vector2(x + 3, y - 1), Vector2(x + 6, y + 2)]), Pal.DIM)
	_plate(r, T.text(T.Key.CARD_SHREDDER))
	var band := Rect2(r.position.x + 6.0, r.end.y - 16.0, r.size.x - 12.0, 8.0)
	draw_rect(band, Color.BLACK)
	var clip := PackedVector2Array([band.position, Vector2(band.end.x, band.position.y), band.end, Vector2(band.position.x, band.end.y)])
	for x in range(int(band.position.x) - 8, int(band.end.x), 12):   # faixa amarela e preta
		var poly := PackedVector2Array([Vector2(x, band.end.y), Vector2(x + 6, band.end.y), Vector2(x + 14, band.position.y), Vector2(x + 8, band.position.y)])
		for c in Geometry2D.intersect_polygons(poly, clip):
			draw_colored_polygon(c, HAZARD)
	_led(r.position + Vector2(12, 50), state == State.FEEDING and _into == Machine.SHRED, Pal.RED)
	_vent(Vector2(r.end.x - 44.0, r.position.y + 24.0), 4, 32.0)
