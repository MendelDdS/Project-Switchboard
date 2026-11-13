class_name CardMachines
extends Control
## A unidade de despacho vista de perto, em volta do mapa sob o vidro: a carcaça creme e, embaixo, a base (este nó
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
## recusa imprimir outro. O primeiro clique no mapa só datilografa o local na tira de papel (`draft`); o segundo, no
## mesmo trecho, imprime (outro trecho troca o local, sem cartão a triturar).
## Na carcaça, à direita, o anel de aproximar o mapa, como o de uma leitora de microfilme (`_knob`): girado com o mouse
## (arrastar para cima aproxima) ou pela roda, um degrau por vez, e o + e o − em cima e embaixo dele, um salto por
## clique (como a roda no mapa).
## O cartão é um nó filho (`card`) dentro de uma janela que recorta (`_window`): saindo da impressora ou entrando numa
## máquina, só aparece o que está acima da fenda.

signal inserted
signal discarded

enum State { IDLE, TYPING, PRINTING, READY, DRAGGING, FEEDING }
## As máquinas que puxam o cartão: o transmissor (envia) e a trituradora (descarta).
enum Machine { SEND, SHRED }

const BEZEL := 9.0         ## a carcaça em volta do vidro (px; o mapa, `Dispatch.city`, fica dentro dela)...
const SCREEN_RIM := 2.0    ## ...com o rebaixo escuro da tela em volta dele
const SCREEN_R := 18       # o raio dos cantos do vidro, na proporção dos da miniatura (o rebaixo, em volta, acompanha)
const CASE_R := 9           # o dos cantos de fora da carcaça e da base (no máximo `BEZEL`: a faixa de cima é o canto)
const KNOB_W := 28.0        ## a moldura da direita, mais larga: o anel de aproximar (na cena, o mapa acompanha)
const KNOB := Vector2(14, 64)   # o anel, em pé
const DETENT_PX := 6.0      # px de arraste por degrau do anel (cada degrau, um `CityMap.ZOOM_STEP` e um tique)
const RIDGES := 24          # sulcos numa volta do anel...
const DETENT_TURN := TAU / RIDGES / 3.0   # ...e o quanto ele gira por degrau, aos pulos (um terço de sulco)
const DRUM := 7.0           # px entre dois números no tambor do mostrador
const ROLL := 12.0          # décimos por segundo que o tambor rola, no mínimo (longe do número, mais depressa)
const BASE_H := 72.0        ## a altura da base das máquinas, embaixo do vidro
const STRIP := 10.0         ## a faixa da frente da base, embaixo das máquinas: as luzes e a plaqueta, como na miniatura da mesa
const TONGUE_H := 14.0      ## a tira de papel saindo da impressora sem cartão (sobe sobre o pé do mapa)
const CARD_W := PunchCard.W
const SLOT := 9.0          # as fendas, a partir do alto da base
const DRAG_START := 5.0     # px que o mouse anda com o botão apertado até virar arraste (antes disso, é clique)
const NEAR_SLOT := 18.0     # solto com a borda de baixo até esta distância da fenda (e por cima dela), entra
const TYPE_SEC := 0.9       # datilografando o local
const PRINT_SEC := 1.3      # o cartão saindo da impressora, sem parar
const FEED_SEC := 0.8       # o transmissor puxando o cartão...
const READ_SEC := 0.35      # ...e ainda lendo os furos, com ele já dentro, antes de enviar
const SHRED_SEC := 1.2      # a trituradora engolindo o cartão
const REFUSE_SEC := 1.6     # a impressora avisando que já há um cartão na mesa
const BLINK_SEC := 0.8      # o aviso de clicar de novo piscando, com o local datilografado
const TICK_GAP := 0.04      # s entre dois tiques do anel girando depressa

var dispatch: Dispatch:
	set(v):
		dispatch = v
		card.dispatch = v
var state := State.IDLE
var _t := 0.0               ## segundos no estado atual
var _pos := Vector2.ZERO    ## canto do cartão (coordenadas deste nó)
var _from := 0.0            ## altura de onde o cartão começa a entrar na máquina
var _into := Machine.SEND   ## a máquina em que ele está entrando (em FEEDING)
var _shake_rng := RandomNumberGenerator.new()   ## o tremor da trituradora, a cada quadro: fora do sorteio global (`--seed`)
var _grab := Vector2.ZERO   ## onde o mouse pegou o cartão
var _press := Vector2.INF   ## onde o botão foi apertado no cartão (INF = solto): ainda não se sabe se é clique ou arraste
var _shake := Vector2.ZERO  ## a trituradora tremendo (um sorteio por quadro)
var _refused := -1.0        ## segundos desde que a impressora recusou um cartão (-1 = sem aviso)
var _alert := false         ## a luz vermelha da faixa: uma emergência em andamento
var draft := ""             ## o local datilografado na tira, à espera do segundo clique no mapa ("" = nenhum)
var _draft_t := 0.0         ## segundos desde que o rascunho começou a ser datilografado
var _blink := false         ## o aviso do rascunho aceso (redesenha só quando troca)
var _turn := INF            ## a altura do mouse girando o anel (INF = solto)
var _turn_acc := 0.0        ## px arrastados que ainda não completaram um degrau
var _detent := 0            ## o degrau do aumento no último desenho (cada um que passa dá um tique)
var _roll := -1.0           ## o número no mostrador, em décimos, rolando até o aumento (-1 = ainda nenhum)
var _zoom_seen := -1.0      ## a aproximação do mapa no último desenho do anel
var _knob_hot := false      ## o mouse no anel (ou girando): os sulcos mais claros
var _since_tick := 1.0      ## segundos desde o último tique do anel (no máximo uns 25 por segundo)
var _window := Control.new()
static var _corners := {}   ## os cantos redondos da tela (`_corner`): [raio, lado, de fora] -> textura (oito, no máximo)
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
## Uma máquina trabalhando sozinha (imprimindo, transmitindo ou triturando): a barra da emergência espera (`Urgency`).
func working() -> bool:
	return state in [State.TYPING, State.PRINTING, State.FEEDING]


func can_print() -> bool:
	return state == State.IDLE


## Imprime um cartão novo e devolve verdadeiro; com um cartão na mesa, recusa (luz vermelha, aviso e `deny`). Com o
## local já datilografado (`draft`), o cartão sai direto.
func print_card(place: String, sector: int) -> bool:
	if not can_print():
		_refuse()
		return false
	_refused = -1.0
	card.fill(card.serial + 1, place, sector)
	var typed := draft == place
	draft = ""
	_go(State.PRINTING if typed else State.TYPING)
	Sfx.play("printer" if typed else "typing")
	return true


## O primeiro clique no mapa: datilografa o local na tira de papel, sem cartão ainda; outro clique troca o local, e o
## segundo no mesmo trecho imprime (`print_card`). Com um cartão na mesa, recusa como `print_card`.
func type_draft(place: String) -> bool:
	if not can_print():
		_refuse()
		return false
	_refused = -1.0
	draft = place
	_draft_t = 0.0
	Sfx.play("typing")
	queue_redraw()
	return true


func _refuse() -> void:
	_refused = 0.0
	Sfx.play("deny")
	queue_redraw()


## Sem cartão (enviado, descartado, ou o despacho foi limpo).
func clear() -> void:
	draft = ""
	if state != State.IDLE:
		_go(State.IDLE)
	queue_redraw()


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
	var alert := dispatch != null and not dispatch.fleet.incidents.is_empty()
	if alert != _alert:
		_alert = alert
		queue_redraw()
	if draft != "":
		_draft_t += delta
		var blink := _draft_t >= TYPE_SEC and fmod(_draft_t - TYPE_SEC, BLINK_SEC) < BLINK_SEC * 0.6
		if _draft_t < TYPE_SEC + delta or blink != _blink:   # datilografando, ou o aviso trocando
			_blink = blink
			queue_redraw()
	_since_tick += delta
	if dispatch != null:
		_knob_step(delta)
	var shredding := state == State.FEEDING and _into == Machine.SHRED
	_shake = Vector2(_shake_rng.randi_range(-1, 1), _shake_rng.randi_range(-1, 1)) if shredding else Vector2.ZERO
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
		_hot_knob(false)
		card.point(Vector2.INF)
	elif what == NOTIFICATION_RESIZED:
		if state in [State.READY, State.DRAGGING]:
			_pos = _clamp(_pos)
		queue_redraw()   # as máquinas ficam presas à base


# ------------------------------------------------------------------ mouse

func _has_point(p: Vector2) -> bool:
	if state == State.DRAGGING or _base().has_point(p) or not _glass().has_point(p):
		return true
	return state in [State.READY, State.FEEDING] and _card_rect().has_point(p)


## Apertar no cartão não faz nada ainda: andar `DRAG_START` px com o botão apertado o arrasta (de qualquer ponto,
## sem perfurar); soltar antes disso é clique, e perfura a linha.
func _gui_input(e: InputEvent) -> void:
	if _knob_input(e):
		accept_event()
		return
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


## O anel e o mostrador seguem o aumento do mapa (também pela roda no mapa): o anel pula de degrau em degrau, com um
## tique, e o tambor do mostrador rola até o número novo.
func _knob_step(delta: float) -> void:
	var zoom := dispatch.city.zoom_level()
	var detent := roundi((dispatch.city.magnification() - 1.0) / CityMap.ZOOM_STEP)
	if zoom != _zoom_seen or detent != _detent:
		_zoom_seen = zoom
		queue_redraw()
		if detent != _detent and is_visible_in_tree() and _since_tick >= TICK_GAP:   # a catraca
			Sfx.play_at("knob_tick", get_global_rect().end.x / get_viewport_rect().size.x)
			_since_tick = 0.0
		_detent = detent
	var target := 10.0 + detent
	if _roll < 0.0 or not is_visible_in_tree():
		_roll = target
	elif _roll != target:
		_roll = move_toward(_roll, target, delta * maxf(ROLL, absf(target - _roll) * 8.0))
		queue_redraw()


## O anel de aproximar: apertado nele, arrastar o gira (para cima aproxima); a roda, sobre ele ou sobre o + e o −, um
## degrau; o + e o −, um salto (`CityMap.zoom_by`). Devolve se o evento era dele.
func _knob_input(e: InputEvent) -> bool:
	var zone := _knob().grow_individual(0, 14, 0, 14)
	if e is InputEventMouse:
		_hot_knob(_turn != INF or zone.has_point(e.position))
	if e is InputEventMouseMotion and _turn != INF:   # um degrau a cada `DETENT_PX` arrastados
		_turn_acc += _turn - e.position.y
		_turn = e.position.y
		var n := int(_turn_acc / DETENT_PX)
		if n != 0:
			_turn_acc -= n * DETENT_PX
			dispatch.city.zoom_step(n)
		return true
	if not (e is InputEventMouseButton and (_turn != INF or zone.has_point(e.position))):
		if e is InputEventMouseMotion and zone.has_point(e.position):
			mouse_default_cursor_shape = Control.CURSOR_MOVE if _knob().has_point(e.position) else Control.CURSOR_POINTING_HAND
			return true
		return false
	var b := e as InputEventMouseButton
	if b.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and b.pressed:   # a roda gira o anel um degrau
		dispatch.city.zoom_step(1 if b.button_index == MOUSE_BUTTON_WHEEL_UP else -1)
	elif b.button_index == MOUSE_BUTTON_LEFT:
		if not b.pressed:
			_turn = INF
		elif _knob().has_point(b.position):
			_turn = b.position.y
			_turn_acc = 0.0
		else:
			dispatch.city.zoom_by(1.2 if b.position.y < _knob().position.y else 1.0 / 1.2)
			Sfx.play("click")
		mouse_default_cursor_shape = Control.CURSOR_DRAG if _turn != INF else Control.CURSOR_MOVE if _knob().has_point(b.position) else Control.CURSOR_POINTING_HAND
	return true


func _hot_knob(on: bool) -> void:
	if on != _knob_hot:
		_knob_hot = on
		queue_redraw()


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
	_draw_knob()
	var b := _base()
	draw_rect(Rect2(BEZEL, b.position.y - 3.0, _glass().size.x, 3), Color(0, 0, 0, 0.3))   # a sombra da base no vidro
	_draw_tray(b)
	_draw_sender()
	_draw_printer()
	_draw_shredder()
	_draw_strip()
	if state == State.IDLE or state == State.TYPING:
		_draw_tongue()


## A carcaça do mapa, como a do terminal da série Ruptura e o móvel da mesa comutadora: plástico creme de cantos
## redondos (a quina na luz no alto e à esquerda, na sombra à direita) e, em volta do vidro, o rebaixo escuro da tela
## (`SCREEN_RIM`, de cantos redondos, como o dos bancos do painel), com a sombra dele no vidro. Embaixo fica a base.
func _draw_bezel() -> void:
	const S := Pal.SHELL
	var glass := _glass()
	var arc := _arc(CASE_R)
	var h := _base().position.y + CASE_R   # (as laterais descem por trás da base, até onde os cantos de cima dela recuam)
	_rounded(Rect2(0, 0, size.x, BEZEL), S[5], true, false)
	for r: Rect2 in [Rect2(0, BEZEL, BEZEL, h - BEZEL), Rect2(glass.end.x, BEZEL, KNOB_W, h - BEZEL)]:
		draw_rect(r, S[5])
	for i in CASE_R:   # a quina de cima e a da esquerda, na luz, e a da direita, na sombra, seguindo a curva
		var run: float = maxf(1.0, (arc[i - 1] if i > 0 else size.x / 2.0) - arc[i])
		draw_rect(Rect2(arc[i], i, run, 1), S[7] if i == 0 else S[6])
		draw_rect(Rect2(size.x - arc[i] - run, i, run, 1), S[7] if i == 0 else S[3])
	draw_rect(Rect2(0, CASE_R, 1, h - CASE_R), S[6])
	draw_rect(Rect2(size.x - 1.0, CASE_R, 1, h - CASE_R), S[3])
	var rim := glass.grow(SCREEN_RIM)
	_ring(rim.grow(1.0), S[3])   # a beira do plástico descendo para o rebaixo...
	_ring(rim, Pal.BOARD_INSET, SCREEN_RIM)   # ...e o rebaixo escuro
	draw_rect(Rect2(glass.position, Vector2(glass.size.x, 2)), Color(0, 0, 0, 0.3))   # a sombra do rebaixo no vidro
	draw_rect(Rect2(glass.position + Vector2(0, 2), Vector2(2, glass.size.y - 2)), Color(0, 0, 0, 0.18))
	if glass.size.x < SCREEN_R * 2.0 or glass.size.y < SCREEN_R * 2.0:   # (no primeiro quadro a tela ainda se arruma)
		return
	for k in 4:   # os cantos redondos: o vidro no rebaixo e, em cima (embaixo fica a base), o rebaixo no plástico
		var d := Vector2i(1 if k % 2 == 0 else -1, 1 if k < 2 else -1)
		var g := Vector2(glass.position.x if d.x > 0 else glass.end.x, glass.position.y if d.y > 0 else glass.end.y)
		var o := SCREEN_RIM + 1.0
		_corner(g, d, SCREEN_R, false)   # (antes: o de fora, com o mesmo centro, pinta a beira por cima)
		if k < 2:
			_corner(g - Vector2(d) * o, d, SCREEN_R + int(o), true)


## Os recuos de cada linha de um canto redondo de raio `rad` (para `Switchboard.round_rect` e `_rounded`).
static func _arc(rad: int) -> Array:
	var cut := []
	for i in rad:
		cut.append(roundf(rad - sqrt(rad * rad - pow(rad - i - 0.5, 2.0))))
	return cut


## O retângulo `r` de `col` com os cantos de cima (`top`) e/ou os de baixo (`bottom`) redondos, de raio `CASE_R`.
func _rounded(r: Rect2, col: Color, top: bool, bottom: bool) -> void:
	var arc := _arc(CASE_R)
	var y0 := r.position.y + (CASE_R if top else 0)
	var y1 := r.end.y - (CASE_R if bottom else 0)
	draw_rect(Rect2(r.position.x, y0, r.size.x, y1 - y0), col)
	for i in CASE_R:
		var row := Rect2(r.position.x + arc[i], 0, r.size.x - arc[i] * 2.0, 1)
		if top:
			draw_rect(Rect2(row.position.x, r.position.y + i, row.size.x, 1), col)
		if bottom:
			draw_rect(Rect2(row.position.x, r.end.y - 1 - i, row.size.x, 1), col)


## O canto redondo de raio `rad` no ponto `c` (`d`, para dentro), uma textura guardada por canto: fora do arco, o
## escuro do rebaixo; com `outer` (o rebaixo no plástico), fora dele o creme, a beira na linha e o rebaixo dentro,
## menos o quadrante do vidro (`SCREEN_RIM` + 1 para dentro), onde o mapa aparece.
func _corner(c: Vector2, d: Vector2i, rad: int, outer: bool) -> void:
	var key := [rad, d, outer]
	if not _corners.has(key):
		var img := Image.create(rad, rad, false, Image.FORMAT_RGBA8)
		var o := int(SCREEN_RIM) + 1
		for j in rad:
			for i in rad:
				var far := Vector2(rad - i - 0.5, rad - j - 0.5).length()
				var col := Color.TRANSPARENT
				if not outer:
					col = Pal.BOARD_INSET if far > rad else col
				elif far > rad:
					col = Pal.SHELL[5]
				elif far > rad - 1.0:
					col = Pal.SHELL[3]
				elif i < o or j < o:
					col = Pal.BOARD_INSET
				img.set_pixel(i if d.x > 0 else rad - 1 - i, j if d.y > 0 else rad - 1 - j, col)
		_corners[key] = ImageTexture.create_from_image(img)
	draw_texture(_corners[key], c - Vector2(0 if d.x > 0 else rad, 0 if d.y > 0 else rad))


## A volta de `w` px por dentro de `r` (o meio fica sem desenhar: o mapa aparece por ele), até a base.
func _ring(r: Rect2, col: Color, w := 1.0) -> void:
	draw_rect(Rect2(r.position, Vector2(r.size.x, w)), col)
	draw_rect(Rect2(r.position.x, r.position.y + w, w, r.size.y - w), col)
	draw_rect(Rect2(r.end.x - w, r.position.y + w, w, r.size.y - w), col)


## A base, como a bandeja do teclado do terminal da série Ruptura e a frente do console da mesa: o plástico creme de
## cantos redondos em volta da placa oliva rebaixada, onde as máquinas ficam; a faixa das luzes, no creme, embaixo.
func _draw_tray(b: Rect2) -> void:
	const S := Pal.SHELL
	_rounded(b, S[2], false, true)   # (os cantos de cima ficam atrás das laterais da carcaça)
	_rounded(Rect2(b.position, b.size - Vector2.ONE), S[7], false, true)
	_rounded(b.grow(-1.0), S[5], false, true)
	var plate := Rect2(b.position.x + 4.0, b.position.y + 2.0, b.size.x - 8.0, b.size.y - STRIP - 6.0)
	Switchboard.round_rect(self, plate.grow(1.0), Pal.BOARD_SIDE.darkened(0.5))
	Switchboard.round_rect(self, plate, Pal.BOARD_SIDE)
	draw_rect(Rect2(plate.position.x + 2.0, plate.end.y + 1.0, plate.size.x - 4.0, 1), S[7])   # a beira de baixo do rebaixo, na luz


## O vidro do mapa, dentro da moldura (a da direita mais larga, com o anel).
func _glass() -> Rect2:
	return Rect2(BEZEL, BEZEL, size.x - BEZEL - KNOB_W, size.y - BEZEL - BASE_H)


## O anel de aproximar, em pé no meio da moldura da direita, à altura do meio do vidro.
func _knob() -> Rect2:
	var g := _glass()
	return Rect2(g.end.x + floorf((KNOB_W - KNOB.x) / 2.0), roundf(g.get_center().y - KNOB.y / 2.0), KNOB.x, KNOB.y)


## O anel visto de lado, um cilindro de borracha: escuro nas pontas, claro no meio, com os sulcos que pulam um terço
## de sulco por degrau do aumento (`DETENT_TURN`); o + em cima e o − embaixo, apagados no limite; embaixo, o mostrador.
func _draw_knob() -> void:
	const M := Pal.KEY_CAP   # o anel, no plástico ciano das teclas (como o botão na lateral do terminal da série Ruptura)
	const S := Pal.SHELL     # a carcaça creme
	var r := _knob()
	var slot := r.grow(2.0)   # o rasgo na carcaça, com um vão em volta do anel; a beira de baixo e a da direita na luz
	Switchboard.round_rect(self, slot, Pal.BOARD_INSET, [1])
	draw_rect(Rect2(slot.position.x + 1.0, slot.end.y, slot.size.x, 1), S[7])
	draw_rect(Rect2(slot.end.x, slot.position.y + 1.0, 1, slot.size.y - 1.0), S[7])
	var half := r.size.y / 2.0
	for y in int(r.size.y):   # o tom de cada linha pela inclinação dela no cilindro
		var z := cos(asin(clampf((y + 0.5 - half) / half, -1.0, 1.0)))
		draw_rect(Rect2(r.position.x, r.position.y + y, r.size.x, 1), M[mini(int(z * 3.0) + int(_knob_hot), M.size() - 2)])
	var phase := _detent * DETENT_TURN
	for i in RIDGES:   # os sulcos, só os da frente
		var a := wrapf(phase + i * TAU / RIDGES, -PI, PI)
		if absf(a) < PI / 2.0 - 0.15:
			var y := r.position.y + roundf(half + sin(a) * (half - 1.0))
			draw_rect(Rect2(r.position.x + 1, y, r.size.x - 2, 1), M[0])
	var cx := r.get_center().x
	for k in 2:   # + em cima, − embaixo, impressos em oliva escuro no creme
		var at := Vector2(cx, r.position.y - 9.0 if k == 0 else r.end.y + 9.0)
		var lit := (_zoom_seen < 1.0) if k == 0 else (_zoom_seen > 0.0)
		var col := Pal.BOARD_STRIP if lit else S[3]
		draw_rect(Rect2(at.x - 3, at.y, 7, 1), col)
		if k == 0:
			draw_rect(Rect2(at.x, at.y - 3, 1, 7), col)
	# o mostrador do aumento, embaixo do −, como o das leitoras de microfilme: um contador com um tambor por algarismo
	# ("1.4X"), cada um no seu rasgo da chapa, o das unidades virando só quando o dos décimos passa do 9, como num
	# hodômetro; o ponto e o X impressos em oliva escuro
	var x0 := roundf(cx - 9.0)
	var y0 := r.end.y + 17.0
	var tenths := fmod(_roll, 10.0)
	_drum(Rect2(x0, y0, 5, 9), floorf(_roll / 10.0) + maxf(0.0, tenths - 9.0))
	_drum(Rect2(x0 + 8.0, y0, 5, 9), tenths)
	for c: Array in [[".", 5.0], ["X", 15.0]]:
		PunchCard.small(self, Vector2(x0 + c[1], y0 + 2.0), c[0], Pal.BOARD_STRIP)


## Um tambor do mostrador no rasgo `win` da chapa, no número `pos` (entre dois, a meio caminho: o de baixo subindo),
## recortado pelo rasgo. O rasgo é rebaixado (a beira de cima e a da esquerda escuras, a de baixo e a da direita na
## luz) e o tambor, um cilindro de papel: mais escuro no alto, à sombra da beira, e embaixo, onde ele faz a curva.
func _drum(win: Rect2, pos: float) -> void:
	draw_rect(win.grow(1.0), Pal.BOARD_INSET)
	draw_rect(Rect2(win.position.x, win.end.y + 1.0, win.size.x + 1.0, 1), Pal.SHELL[7])   # a beira de baixo e a da direita, na luz
	draw_rect(Rect2(win.end.x + 1.0, win.position.y, 1, win.size.y + 1.0), Pal.SHELL[7])
	draw_rect(win, Pal.CARD)
	var d := floori(pos)
	for i in 2:
		var y := roundf(2.0 - (pos - d) * DRUM) + i * DRUM   # o alto do número no rasgo (no meio, parado)
		var top := maxf(0.0, -y)
		var h := minf(5.0, win.size.y - y) - top
		if h > 0.0:
			draw_texture_rect_region(PixelArt.tiny(str((d + i) % 10)), Rect2(win.position + Vector2(1, y + top), Vector2(3, h)),
				Rect2(0, 3.0 + top, 3, h), Pal.INK)
	for k: Array in [[0, 0.45], [1, 0.2], [win.size.y - 2.0, 0.1], [win.size.y - 1.0, 0.3]]:   # a curva do cilindro
		draw_rect(Rect2(win.position + Vector2(0, k[0]), Vector2(win.size.x, 1)), Color(0, 0, 0, k[1]))


## A faixa da frente da base, como a frente da unidade da mesa (`Background._draw_dispatch_unit`): a luz vermelha de
## emergência em andamento e a âmbar de cartão na mesa, à esquerda, e o selo oval da companhia no meio (`Switchboard.badge`).
func _draw_strip() -> void:
	var b := _base()
	var y := b.end.y - STRIP - 3.0
	var mid := y + floorf(STRIP / 2.0)
	led(self, Vector2(b.position.x + 9.0, mid - 2.0), _alert, Pal.RED)
	led(self, Vector2(b.position.x + 18.0, mid - 2.0), state != State.IDLE, Pal.AMBER)
	Switchboard.badge(self, Vector2(b.get_center().x, mid), Pal.BOARD_INK, Pal.KEY_CAP[2], 16.0, 9)


## Caixa de plástico creme, como o móvel da mesa comutadora (série Ruptura): cantos arredondados, sem parafusos, a
## sombra embaixo, a quina na luz em cima e à esquerda e na sombra embaixo e à direita.
static func box(ci: CanvasItem, r: Rect2) -> void:
	Switchboard.round_rect(ci, Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.35))
	Switchboard.round_rect(ci, r, Pal.SHELL[2])
	Switchboard.round_rect(ci, Rect2(r.position, r.size - Vector2.ONE), Pal.SHELL[7])
	Switchboard.round_rect(ci, r.grow(-1.0), Pal.SHELL[5])


## A frente oliva rebaixada da máquina `r`, embaixo da fenda, como a placa do teclado do terminal da série Ruptura: o
## nome impresso em creme (`_name`), a luz, o aviso dela e, na trituradora, a faixa de perigo ficam nela.
static func face(ci: CanvasItem, r: Rect2) -> void:
	var f := Rect2(r.position.x + 5.0, r.position.y + 12.0, r.size.x - 10.0, r.size.y - 16.0)
	Switchboard.round_rect(ci, f.grow(1.0), Pal.SHELL[3])
	Switchboard.round_rect(ci, f, Pal.BOARD_FACE)
	ci.draw_rect(Rect2(f.position.x + 1.0, f.position.y, f.size.x - 2.0, 1), Pal.BOARD_INSET)   # a sombra da beira de cima


## Saída de ar no plástico: `n` frisos escuros com a beira de baixo na luz.
static func vent(ci: CanvasItem, at: Vector2, n: int, w: float) -> void:
	for i in n:
		ci.draw_rect(Rect2(at + Vector2(0, i * 4), Vector2(w, 2)), Pal.SHELL[1])
		ci.draw_rect(Rect2(at + Vector2(0, i * 4 + 2), Vector2(w, 1)), Pal.SHELL[7])


## Fenda de entrada ou saída: um rasgo fino, com a beira do plástico na luz embaixo dele.
static func mouth(ci: CanvasItem, x: float, y: float, w: float) -> void:
	ci.draw_rect(Rect2(x - 2.0, y - 2.0, w + 4.0, 5), Pal.SHELL[2])
	ci.draw_rect(Rect2(x, y - 1.0, w, 2), Color.BLACK)
	ci.draw_rect(Rect2(x - 2.0, y + 2.0, w + 4.0, 1), Pal.SHELL[7])


## A lâmpada de 5 px em `at`, como as da mesa comutadora (`Switchboard._draw_lamp`): uma cúpula de plástico fosco num
## aro creme; apagada, leitosa; acesa, toda de uma cor só, com a luz opaca em volta (sem brilho de vidro).
static func led(ci: CanvasItem, at: Vector2, on: bool, col: Color) -> void:
	ci.draw_texture(PixelArt.disc(9, [[2.5, Color.TRANSPARENT], [4.5, Pal.SHELL[6], Pal.SHELL[4], Pal.SHELL[2]]]), at - Vector2(2, 2))
	var dome := [[1.5, col.lightened(0.25)], [2.5, col]] if on else [[1.5, Pal.LAMP_GLASS], [2.5, Pal.LAMP_GLASS.darkened(0.2)]]
	ci.draw_texture(PixelArt.disc(5, dome), at)
	if on:
		Bloom.light(ci, Rect2(at, Vector2(5, 5)), col, 1.0, false, true)


## A etiqueta com o nome da máquina: creme, impressa em oliva escuro, colada rente (como a do fabricante na mesa).
static func plate(ci: CanvasItem, r: Rect2, text: String) -> void:
	var tag := Rect2(r.position.x + 8.0, r.position.y + 14.0, minf(84.0, r.size.x - 16.0), 15.0)
	Switchboard.round_rect(ci, tag.grow(1.0), Pal.SHELL[2])
	Switchboard.round_rect(ci, tag, Pal.BOARD_TAG)
	PunchCard.write(ci, Vector2(tag.position.x, tag.position.y + 11.0), text, Pal.BOARD_STRIP, tag.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## O nome da máquina `r`, impresso em creme na frente oliva dela, no meio (sem etiqueta, como o CTSS da mesa).
func _name(r: Rect2, text: String) -> void:
	PunchCard.write(self, Vector2(r.position.x + 8.0, r.position.y + 25.0), text, Pal.BOARD_INK, r.size.x - 16.0, HORIZONTAL_ALIGNMENT_CENTER)


## A impressora, no meio: a fenda por onde o cartão sobe, o nome e a luz (âmbar trabalhando; vermelha piscando com o
## aviso, quando recusa).
func _draw_printer() -> void:
	var r := _printer()
	box(self, r)
	face(self, r)
	mouth(self, _mouth_x(1), _printer_slot(), CARD_W)
	_name(r, T.text(T.Key.CARD_PRINTER))
	var busy := state in [State.TYPING, State.PRINTING]
	if _refused >= 0.0:   # recusou: luz vermelha piscando e o aviso embaixo da placa
		led(self, r.position + Vector2(9, 36), fmod(_refused, 0.3) < 0.15, Pal.RED)
		PunchCard.small(self, Vector2(r.position.x + 18.0, r.position.y + 37.0), T.text(T.Key.CARD_ONE_AT_A_TIME), Pal.RED)
	elif draft != "" and _draft_t >= TYPE_SEC:   # o local datilografado espera o segundo clique: o aviso piscando
		led(self, r.position + Vector2(9, 36), _blink, Pal.AMBER)
		if _blink:
			PunchCard.small(self, Vector2(r.position.x + 18.0, r.position.y + 37.0), T.text(T.Key.MAP_CLICK_AGAIN), Pal.BOARD_INK)
	else:
		led(self, r.position + Vector2(9, 36), busy and fmod(_t, 0.24) < 0.12, Pal.AMBER)


## Sem cartão, uma tira de papel sai da fenda da impressora: o aviso ou, enquanto datilografa, o local aparecendo.
func _draw_tongue() -> void:
	var r := Rect2(_mouth_x(1) + 10.0, _printer_slot() - TONGUE_H, CARD_W - 20.0, TONGUE_H)
	draw_rect(r, Pal.CARD_EDGE)
	draw_rect(r.grow(-1.0), Pal.CARD)
	var txt := T.text(T.Key.DISPATCH_CLICK_STREET)
	var place := draft if draft != "" else card.place if state == State.TYPING else ""
	if place != "":
		txt = place.left(ceili(place.length() * minf((_draft_t if draft != "" else _t) / (TYPE_SEC * 0.85), 1.0)))
	PunchCard.small(self, Vector2(r.position.x, r.position.y + 5.0), txt, Pal.INK_SOFT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## O transmissor, à esquerda: a fenda com setas ciano, o nome, a luz de pronto e o aviso.
func _draw_sender() -> void:
	var r := _machine(Machine.SEND)
	box(self, r)
	face(self, r)
	var x0 := _mouth_x(0)
	var y := _slot(Machine.SEND)
	mouth(self, x0, y, CARD_W)
	for side in [x0 - 9.0, x0 + CARD_W + 3.0]:   # setas apontando a fenda
		if side > r.position.x and side + 6.0 < r.end.x:
			draw_primitive(PackedVector2Array([Vector2(side, y - 3.0), Vector2(side + 6.0, y - 3.0), Vector2(side + 3.0, y + 2.0)]),
				PackedColorArray([Pal.KEY_CAP[3]]), PackedVector2Array())
	_name(r, T.text(T.Key.CARD_SENDER))
	var feeding := state == State.FEEDING and _into == Machine.SEND
	var ready := dispatch.can_send()
	led(self, r.position + Vector2(9, 36), feeding and fmod(_t, 0.2) < 0.1 or not feeding and ready, Pal.AMBER if feeding else Pal.GREEN)
	var msg := T.text(T.Key.CARD_SENDING) if feeding else T.text(T.Key.CARD_INSERT)
	PunchCard.small(self, Vector2(r.position.x + 18.0, r.position.y + 37.0), msg, Pal.BOARD_INK)


## A trituradora, à direita: a fenda com as lâminas, a faixa de perigo, o nome e a luz; treme enquanto tritura.
func _draw_shredder() -> void:
	var r := _machine(Machine.SHRED)
	box(self, r)
	face(self, r)
	var x0 := _mouth_x(2) + _shake.x
	var y := _slot(Machine.SHRED)
	mouth(self, x0, y, CARD_W)
	for x in range(int(x0) + 2, int(x0 + CARD_W) - 4, 6):   # as lâminas aparecendo na fenda
		draw_primitive(PackedVector2Array([Vector2(x, y + 2), Vector2(x + 3, y - 1), Vector2(x + 6, y + 2)]), PackedColorArray([Pal.DIM]), PackedVector2Array())
	_name(r, T.text(T.Key.CARD_SHREDDER))
	var band := Rect2(r.position.x + 9.0, r.end.y - 11.0, r.size.x - 18.0, 5.0)
	draw_rect(band, Pal.SHELL[4])
	var clip := PackedVector2Array([band.position, Vector2(band.end.x, band.position.y), band.end, Vector2(band.position.x, band.end.y)])
	for x in range(int(band.position.x) - 6, int(band.end.x), 9):   # faixa creme e petróleo
		var poly := PackedVector2Array([Vector2(x, band.end.y), Vector2(x + 4, band.end.y), Vector2(x + 10, band.position.y), Vector2(x + 6, band.position.y)])
		for c in Geometry2D.intersect_polygons(poly, clip):
			draw_colored_polygon(c, Pal.HAZARD)
	led(self, r.position + Vector2(9, 36), state == State.FEEDING and _into == Machine.SHRED, Pal.RED)
