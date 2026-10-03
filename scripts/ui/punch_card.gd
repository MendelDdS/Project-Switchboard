class_name PunchCard
extends Control
## A ficha de despacho como objeto, por cima do mapa (este nó cobre a aba; fora das máquinas e do cartão o clique vai
## para o mapa, `_has_point`). Três máquinas: a impressora (canto de cima, à direita; desce quando a ficha abre e
## sobe quando fecha, com o × junto), a trituradora (embaixo dela, na borda de baixo) e o transmissor (canto de baixo,
## à esquerda); as duas de baixo sobem quando o cartão sai impresso e descem quando não há cartão. Fechar a ficha (`set_open`)
## espera as máquinas se recolherem (`closed`).
## Marcar o local faz a impressora datilografar o local (`typing`) e imprimir um cartão perfurado (`printer`), que sai
## pela fenda já com o local, o bairro e o setor. O jogador perfura o tipo de ocorrência (um só) e as unidades, cada um
## na sua posição; furo não se desfaz. O cartão vai para onde for arrastado, dentro do mapa, e fica onde for solto;
## solto na fenda do transmissor, é puxado e enviado (`inserted`), mesmo incompleto (o supervisor é quem pune); na da
## trituradora, é destruído (`discarded`). A mesa comporta um cartão por vez, de qualquer tipo (`can_print`): enquanto
## houver um, a impressora recusa imprimir outro. Os furos são só a vista do que o `Dispatch` guarda.
## O cartão é um nó filho (`_sheet`) dentro de uma janela que recorta (`_window`): saindo da impressora, só aparece o
## que passou da fenda; entrando numa máquina, só o que ainda não entrou.

signal inserted
signal discarded
## As máquinas terminaram de se recolher depois de `set_open(false)`: a ficha pode sumir.
signal closed

enum State { IDLE, TYPING, PRINTING, READY, DRAGGING, FEEDING }

const COL_W := 246.0        # a coluna da impressora e da trituradora, no canto direito
const CARD_W := 216.0
const PRINTER_H := 30.0
const SENDER := Vector2(272, 74)
const SHREDDER_H := 58.0
const SLOT := 12.0          # a fenda de entrada, a partir do topo da máquina
const DRAG_START := 5.0     # px que o mouse anda com o botão apertado até virar arraste (antes disso, é clique)
const NEAR_SLOT := 24.0     # solto com a borda de baixo até esta distância da fenda (e por cima dela), entra
const TYPE_SEC := 0.9       # datilografando o local
const PRINT_SEC := 1.3      # o cartão saindo da impressora...
const PRINT_STEPS := 12     # ...aos solavancos, uma linha de cada vez
const LOWER_SEC := 0.45     # o transmissor e a trituradora subindo ou descendo
const PRINTER_SEC := 0.45   # a impressora descendo ou subindo
const FEED_SEC := 0.8       # o transmissor puxando o cartão...
const READ_SEC := 0.35      # ...e ainda lendo os furos, com ele já dentro, antes de enviar
const SHRED_SEC := 1.2      # a trituradora engolindo o cartão
const CHAD_SEC := 0.45      # o picote caindo
const REFUSE_SEC := 1.6     # a impressora avisando que já há um cartão na mesa
const ROW := 19.0
const CELL := Vector2(10, 14)
const CARD := Color("e9dcb4")
const CARD_EDGE := Color("a8966b")
const FORM := Color("8a2a1c")          # o formulário vem impresso na tinta vermelha das emergências (o carimbo do caderno)
const RULE := Color(0.35, 0.43, 0.55, 0.3)   # a pauta, como a do caderno
const HOLE := Color("17110b")
const MISSING := Color("8a3a14")
const SHADOW := Color(0, 0, 0, 0.35)
const SHADOW_REST := Vector2(3, 4)     # sombra do cartão na mesa...
const SHADOW_HELD := Vector2(9, 12)    # ...e erguido, na mão (como o plug da mesa)
const TOP := 82.0                      # o cabeçalho: faixa, local, bairro e setor, fio duplo
const FOOT := 22.0                     # o rodapé: fio e o nome da central
const HAZARD := Color("d9a521")

var dispatch: Dispatch
var state := State.IDLE
var _t := 0.0               ## segundos no estado atual
var _up := 0.0              ## 0..1: o transmissor e a trituradora à vista (sobem de baixo)
var _down := 0.0            ## 0..1: a impressora à vista (desce de cima)
var _open := false          ## a ficha aberta (as máquinas à vista)
var _closing := false       ## fechando: avisa `closed` quando as máquinas se recolherem
var _pos := Vector2.ZERO    ## canto do cartão (coordenadas deste nó)
var _from := 0.0            ## altura de onde o cartão começa a entrar na máquina
var _into := ""             ## a máquina em que ele está entrando: "send" ou "shred"
var _grab := Vector2.ZERO   ## onde o mouse pegou o cartão
var _press := Vector2.INF   ## onde o botão foi apertado no cartão (INF = solto): ainda não se sabe se é clique ou arraste
var _shake := Vector2.ZERO  ## a trituradora tremendo (um sorteio por quadro)
var _serial := 0
var _refused := -1.0        ## segundos desde que a impressora recusou um cartão (-1 = sem aviso)
var _place := ""            ## o local impresso ("Rua do Sol, 1–99")
var _sector := 0
var _cells: Array = []      ## [quadradinho no cartão, "type" | "unit", id, a linha inteira (clicável)]
var _hover: Array = []      ## a posição sob o mouse (a linha dela fica realçada se der para perfurar)
var _heads := {}            ## "type" / "unit" -> y do título da parte
var _card_h := 0.0
var _rules: Array[float] = []   ## pauta entre as linhas
var _specks: Array[Vector2] = []   ## fibras do papel (cada cartão as suas)
var _chads: Array = []      ## picotes caindo: [posição no cartão, segundos]
var _window := Control.new()
var _sheet := Control.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true   # as máquinas saem pelas bordas
	_window.clip_contents = true
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.visible = false
	_sheet.draw.connect(_draw_card)
	_window.add_child(_sheet)
	add_child(_window)
	move_child(_window, 0)   # o × da impressora fica por cima do cartão


## Imprime um cartão novo (o que estava na mesa vai embora).
## O número do último cartão impresso (o que está na mesa, ou o que acabou de entrar numa máquina).
func serial() -> int:
	return _serial


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
	_serial += 1
	_place = place
	_sector = sector
	_layout()
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
		_pos = _rest() - Vector2(0, _card_h)   # ainda todo dentro da impressora
	queue_redraw()


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
	return Rect2(_pos, Vector2(CARD_W, _card_h))


## "send": o transmissor, no canto de baixo à esquerda. "shred": a trituradora, embaixo da impressora (treme enquanto
## tritura). As duas ficam escondidas embaixo da borda enquanto não sobem.
func _machine(m: String) -> Rect2:
	var k := 1.0 - smoothstep(0.0, 1.0, _up)
	if m == "send":
		return Rect2(6.0, size.y - SENDER.y - 4.0 + roundf(k * (SENDER.y + 10.0)), SENDER.x, SENDER.y)
	var y := size.y - SHREDDER_H - 4.0 + roundf(k * (SHREDDER_H + 10.0))
	return Rect2(Vector2(_printer().position.x, y) + _shake, Vector2(_printer().size.x, SHREDDER_H))


func _slot(m: String) -> float:
	return _machine(m).position.y + SLOT


## Posições de perfuração (o tipo de ocorrência, depois as unidades, cada uma com o protocolo embaixo).
func _layout() -> void:
	_cells.clear()
	_rules.clear()
	var y := TOP
	_heads["type"] = y
	y += 20.0
	for o in GameData.CONTENT.occurrences:
		_cells.append([Rect2(Vector2(10, y), CELL), "type", o, Rect2(4, y - 3.0, CARD_W - 8.0, ROW)])
		y += ROW
		_rules.append(y - 3.0)
	y += 6.0
	_heads["unit"] = y
	y += 20.0
	for u in Dispatch.UNIT_IDS:
		var top := y
		y += 16.0 + Pal.ui.get_multiline_string_size(_why(u), HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 36.0, 11).y + 4.0
		_cells.append([Rect2(Vector2(10, top), CELL), "unit", u, Rect2(4, top - 3.0, CARD_W - 8.0, y - top)])
		_rules.append(y - 3.0)
	_card_h = y + FOOT
	_sheet.size = Vector2(CARD_W, _card_h)
	var rng := RandomNumberGenerator.new()
	rng.seed = _serial
	_specks.clear()
	for i in 46:
		_specks.append(Vector2(rng.randi_range(3, int(CARD_W) - 5), rng.randi_range(22, int(_card_h) - 6)))


func _why(u: String) -> String:
	return T.text({"pol": T.Key.DISPATCH_WHY_POL, "bomb": T.Key.DISPATCH_WHY_BOMB, "amb": T.Key.DISPATCH_WHY_AMB}[u])


## A posição de perfuração da linha sob `p` (clicar em qualquer ponto da linha perfura o quadradinho dela).
func _cell_at(p: Vector2) -> Array:
	for c in _cells:
		if (c[3] as Rect2).has_point(p - _pos):
			return c
	return []


func _punched(kind: String, id: String) -> bool:
	return dispatch.occurrence() == id if kind == "type" else id in dispatch.picked()


func _can_punch(kind: String, id: String) -> bool:
	if kind == "type":
		return dispatch.occurrence() == ""   # um tipo só
	return dispatch.unit_free(id) and not id in dispatch.picked()


## Dentro do mapa (este nó).
func _clamp(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 0.0, maxf(0.0, size.x - CARD_W)), clampf(p.y, 0.0, maxf(0.0, size.y - _card_h)))


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
			_pos = _rest() - Vector2(0, _card_h * (1.0 - floorf(k * PRINT_STEPS) / PRINT_STEPS))
			if k >= 1.0:
				_go(State.READY)
		State.FEEDING:
			var sec := FEED_SEC if _into == "send" else SHRED_SEC
			_pos.y = lerpf(_from, _slot(_into), ease(minf(_t / sec, 1.0), 1.6))
			if _t >= sec + (READ_SEC if _into == "send" else 0.0):
				_go(State.IDLE)
				(inserted if _into == "send" else discarded).emit()
	var shredding := state == State.FEEDING and _into == "shred"
	_shake = Vector2(randi_range(-1, 1), randi_range(-1, 1)) if shredding else Vector2.ZERO
	var shown := _open and state in [State.READY, State.DRAGGING, State.FEEDING]
	var was := Vector2(_up, _down)
	_up = move_toward(_up, 1.0 if shown else 0.0, delta / LOWER_SEC)
	_down = move_toward(_down, 1.0 if _open else 0.0, delta / PRINTER_SEC)
	var close := get_node_or_null("Close") as Control   # o × fica na impressora
	if close != null:
		close.position.y = _printer().position.y + 5.0
	if _closing and _up == 0.0 and _down == 0.0:
		_closing = false
		closed.emit()
	for ch in _chads:
		ch[1] += delta
	_chads = _chads.filter(func(ch): return ch[1] < CHAD_SEC)
	_place_sheet()
	if state != State.IDLE or _up > 0.0 or was != Vector2(_up, _down):
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
	_sheet.visible = state not in [State.IDLE, State.TYPING]
	_sheet.position = _pos - win.position
	_sheet.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover = []
	elif what == NOTIFICATION_RESIZED and state in [State.READY, State.DRAGGING]:
		_pos = _clamp(_pos)
	elif what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _cells.is_empty():
		_layout()   # o protocolo muda de tamanho com o idioma
		queue_redraw()


# ------------------------------------------------------------------ mouse

func _has_point(p: Vector2) -> bool:
	if _down > 0.0 and _printer().has_point(p) or state == State.DRAGGING:
		return true
	if state in [State.READY, State.FEEDING] and _card_rect().has_point(p):
		return true
	return _up > 0.0 and (_machine("send").has_point(p) or _machine("shred").has_point(p))


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
		var h := _cell_at(e.position) if state == State.READY and _card_rect().has_point(e.position) else []
		if h != _hover:
			_hover = h
			_sheet.queue_redraw()
		mouse_default_cursor_shape = _cursor(e.position)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and state == State.READY and _card_rect().has_point(e.position):
			_press = e.position
			accept_event()
		elif not e.pressed:
			if state == State.DRAGGING:
				_drop()
			elif _press != Vector2.INF and state == State.READY:
				var c := _cell_at(_press)
				if not c.is_empty():
					_punch(c)
			_press = Vector2.INF
			mouse_default_cursor_shape = _cursor(e.position)
			accept_event()


func _cursor(p: Vector2) -> int:
	if state == State.DRAGGING:
		return Control.CURSOR_DRAG
	if state != State.READY or not _card_rect().has_point(p):
		return Control.CURSOR_ARROW
	var c := _cell_at(p)
	if c.is_empty():
		return Control.CURSOR_MOVE
	if _can_punch(c[1], c[2]):
		return Control.CURSOR_POINTING_HAND
	return Control.CURSOR_ARROW if _punched(c[1], c[2]) else Control.CURSOR_FORBIDDEN


func _punch(c: Array) -> void:
	if not _can_punch(c[1], c[2]):
		return
	if c[1] == "type":
		dispatch.set_occurrence(c[2])
	else:
		dispatch.punch_unit(c[2])
	Sfx.play("punch")
	_chads.append([(c[0] as Rect2).get_center(), 0.0])


## Solto com a borda de baixo sobre a fenda do transmissor ou da trituradora, entra (o transmissor aceita cartão
## incompleto); em qualquer outro lugar, fica.
func _drop() -> void:
	var bottom := _pos.y + _card_h
	for m in ["send", "shred"]:
		var r := _machine(m)
		var centered := absf(_pos.x + CARD_W / 2.0 - r.get_center().x) < CARD_W / 3.0
		if _up > 0.5 and centered and bottom >= _slot(m) - NEAR_SLOT and bottom <= r.end.y:
			_pos.x = r.get_center().x - CARD_W / 2.0
			_from = _pos.y
			_into = m
			_go(State.FEEDING)
			Sfx.play("feed" if m == "send" else "shred")
			if m == "send":
				Sfx.play("read")   # o leitor lendo os furos enquanto o cartão entra
			return
	_go(State.READY)


# ------------------------------------------------------------------ desenho

func _text(ci: CanvasItem, p: Vector2, s: String, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(Pal.mono, p.round(), s, align, width, 11, col)


## As máquinas (o cartão é o `_sheet`, desenhado por cima).
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
		_text(self, Vector2(r.position.x + 22.0, r.position.y + 16.0), T.text(T.Key.CARD_ONE_AT_A_TIME), Pal.RED)
	else:
		_led(r.position + Vector2(10, 8), busy and fmod(_t, 0.24) < 0.12, Pal.AMBER)
		_text(self, Vector2(r.position.x + 22.0, r.position.y + 16.0), T.text(T.Key.CARD_PRINTER), Pal.DIM)
	_vent(Vector2(r.end.x - 74.0, r.position.y + 6.0), 3, 28.0)


## Sem cartão, uma tira de papel sai da fenda: o aviso ou, enquanto datilografa, o local aparecendo.
func _draw_tongue() -> void:
	var r := Rect2(_rest().x + 20.0, _printer_slot(), CARD_W - 40.0, 22.0)
	draw_rect(r, CARD_EDGE)
	draw_rect(r.grow(-1.0), CARD)
	var txt := T.text(T.Key.DISPATCH_CLICK_STREET)
	if state == State.TYPING:
		txt = _place.left(ceili(_place.length() * minf(_t / (TYPE_SEC * 0.85), 1.0)))
	_text(self, Vector2(r.position.x, r.position.y + 15.0), txt, Pal.INK_SOFT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


## O transmissor: fenda em cima com setas, placa com o nome, luz de pronto e o aviso, saída de ar e pés.
func _draw_sender() -> void:
	var r := _machine("send")
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
	_text(self, Vector2(plate.position.x, plate.position.y + 13.0), T.text(T.Key.CARD_SENDER), Color(Pal.INK, a), plate.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var feeding := state == State.FEEDING and _into == "send"
	var ready := dispatch.can_send()
	_led(Vector2(r.position.x + 12.0, r.position.y + 52.0), feeding and fmod(_t, 0.2) < 0.1 or not feeding and ready, Pal.AMBER if feeding else Pal.GREEN, a)
	var msg := T.text(T.Key.CARD_SENDING) if feeding else T.text(T.Key.CARD_INSERT)
	_text(self, Vector2(r.position.x + 24.0, r.position.y + 60.0), msg, Color(Pal.AMBER, a))
	_vent(Vector2(r.end.x - 60.0, r.position.y + 26.0), 9, 46.0, a)


## A trituradora: fenda com as lâminas, faixa de perigo, nome e saída de ar; treme enquanto tritura.
func _draw_shredder() -> void:
	var r := _machine("shred")
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
	var busy := state == State.FEEDING and _into == "shred"
	_led(r.position + Vector2(10, 38), busy, Pal.RED)
	_text(self, Vector2(r.position.x + 22.0, r.position.y + 46.0), T.text(T.Key.CARD_SHREDDER), Pal.DIM)
	_vent(Vector2(r.end.x - 60.0, r.position.y + 37.0), 3, 46.0)


## O cartão, nas coordenadas dele (`_sheet`): formulário impresso em vermelho (faixa, rótulos, posições de furo,
## pauta e rodapé) e os dados datilografados em preto, com sombra na mesa (maior com ele na mão).
func _draw_card() -> void:
	var ci := _sheet
	var shape := PackedVector2Array([Vector2(10, 0), Vector2(CARD_W, 0), Vector2(CARD_W, _card_h), Vector2(0, _card_h), Vector2(0, 10)])
	var lift := SHADOW_HELD if state == State.DRAGGING else SHADOW_REST
	var shadow := PackedVector2Array()
	for q in shape:
		shadow.append(q + lift)
	ci.draw_colored_polygon(shadow, SHADOW)
	ci.draw_colored_polygon(shape, CARD)   # o canto cortado dos cartões perfurados
	for sp in _specks:   # fibras do papel
		ci.draw_rect(Rect2(sp, Vector2(2 if int(sp.x) % 3 == 0 else 1, 1)), CARD.darkened(0.1))
	# cabeçalho: a faixa impressa, o local e o bairro datilografados em linhas de preencher
	ci.draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(CARD_W, 0), Vector2(CARD_W, 18), Vector2(0, 18), Vector2(0, 10)]), FORM)
	_text(ci, Vector2(14, 13), T.text(T.Key.CARD_TITLE), CARD)
	_text(ci, Vector2(14, 13), T.text(T.Key.CARD_SERIAL) % _serial, CARD, CARD_W - 22.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(ci, Vector2(10, 32), T.text(T.Key.CARD_PLACE), FORM)
	var box := Rect2(CARD_W - 21.0, 22.0, 11, 12)   # o setor, datilografado numa caixinha à direita
	ci.draw_rect(box, FORM, false, 1.0)
	_text(ci, Vector2(box.position.x, 32), str(_sector), Pal.INK, box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(ci, Vector2(10, 32), T.text(T.Key.CARD_SECTOR), FORM, box.position.x - 15.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(ci, Vector2(10, 47), _place, Pal.INK)
	_field(ci, 10.0, 50.0)
	var label := T.text(T.Key.CARD_DISTRICT)
	var at := 16.0 + Pal.ui.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	_text(ci, Vector2(10, 66), label, FORM)
	_text(ci, Vector2(at, 66), T.text(CityMap.DISTRICT[_sector]).to_upper(), Pal.INK)
	_field(ci, at, 69.0)
	ci.draw_rect(Rect2(6, TOP - 7.0, CARD_W - 12.0, 1), FORM)   # fio duplo
	ci.draw_rect(Rect2(6, TOP - 5.0, CARD_W - 12.0, 1), FORM)
	# as partes: título com a caixinha (um X datilografado quando perfurada) e a pauta entre as linhas
	var heads := {"type": [dispatch.occurrence() != "", T.Key.DISPATCH_CHECK_TYPE], "unit": [not dispatch.picked().is_empty(), T.Key.DISPATCH_CHECK_UNITS]}
	for kind in heads:
		var y: float = _heads[kind]
		_text(ci, Vector2(10, y + 11.0), T.text(heads[kind][1]).to_upper(), FORM)
		var check := Rect2(CARD_W - 21.0, y + 1.0, 11, 11)
		ci.draw_rect(check, FORM, false, 1.0)
		if heads[kind][0]:
			_text(ci, Vector2(check.position.x, check.position.y + 10.0), "X", Pal.INK, check.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		ci.draw_rect(Rect2(10, y + 15.0, CARD_W - 20.0, 1), Color(FORM, 0.5))
	if not _hover.is_empty() and state == State.READY and _can_punch(_hover[1], _hover[2]):
		ci.draw_rect(_hover[3], Color(Pal.AMBER, 0.16))   # a linha que vai ser perfurada
	for y in _rules:
		ci.draw_rect(Rect2(28, y, CARD_W - 38.0, 1), RULE)
	var count := {"type": 0, "unit": 0}   # cada parte numera as suas posições: 1, 2, 3...
	for c in _cells:
		count[c[1]] += 1
		_draw_cell(ci, c[0], c[1], c[2], count[c[1]])
	# rodapé: o fio, o nome da central e as marcas de coluna na borda, como nos cartões perfurados
	var foot := _card_h - FOOT + 4.0
	ci.draw_rect(Rect2(6, foot, CARD_W - 12.0, 1), FORM)
	_text(ci, Vector2(0, foot + 12.0), T.text(T.Key.GAME_TITLE).to_upper(), Color(FORM, 0.8), CARD_W, HORIZONTAL_ALIGNMENT_CENTER)
	for x in range(6, int(CARD_W) - 4, 6):
		ci.draw_rect(Rect2(x, _card_h - 3.0, 1, 2), Color(FORM, 0.35))
	shape.append(shape[0])
	ci.draw_polyline(shape, CARD_EDGE, 1.0)
	ci.draw_rect(Rect2(1, _card_h - 1.0, CARD_W - 1.0, 1), CARD_EDGE.darkened(0.25))   # a espessura do cartão
	ci.draw_rect(Rect2(CARD_W - 1.0, 1, 1, _card_h - 1.0), CARD_EDGE.darkened(0.25))
	for ch in _chads:   # o picote do furo caindo
		var k: float = ch[1] / CHAD_SEC
		ci.draw_rect(Rect2(ch[0] + Vector2(-3, -5 + 60.0 * k * k), Vector2(6, 9)), Color(CARD, 1.0 - k))


## Linha de preencher (pontilhado vermelho) embaixo de um dado datilografado.
func _field(ci: CanvasItem, x: float, y: float) -> void:
	for fx in range(int(x), int(CARD_W) - 10, 3):
		ci.draw_rect(Rect2(fx, y, 1, 1), Color(FORM, 0.6))


## Uma posição de perfuração (impressa em vermelho, com o número) e o que ela quer dizer.
func _draw_cell(ci: CanvasItem, r: Rect2, kind: String, id: String, n: int) -> void:
	var busy := kind == "unit" and not dispatch.unit_free(id)
	if _punched(kind, id):
		ci.draw_rect(r, HOLE)
		ci.draw_rect(Rect2(r.position.x, r.end.y - 1.0, r.size.x, 1), Color(1, 1, 1, 0.18))   # a luz passando pelo furo
	else:
		ci.draw_rect(r, Color(FORM, 0.08))
		ci.draw_rect(r, FORM, false, 1.0)
		_text(ci, Vector2(r.position.x, r.position.y + 11.0), str(n), Color(FORM, 1.0 if _can_punch(kind, id) else 0.3),
			r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var at := Vector2(r.end.x + 8.0, r.position.y + 11.0)
	if kind == "type":
		_text(ci, at, tr(id), Pal.INK, CARD_W - 36.0)
		return
	_text(ci, at, T.text(Dispatch.UNIT_NAMES[id]), MISSING if busy else Pal.INK, CARD_W - 36.0)
	if busy:   # ocupada: riscada, e o estado no lugar do protocolo
		ci.draw_line(r.position, r.end, Pal.INK, 1.0)
		ci.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Pal.INK, 1.0)
		_text(ci, at + Vector2(0, 14), T.text(Dispatch.UNIT_STATUS[dispatch.unit_state(id)]), MISSING, CARD_W - 36.0)
		return
	ci.draw_multiline_string(Pal.mono, (at + Vector2(0, 14)).round(), _why(id), HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 36.0, 11, -1, Pal.INK_SOFT)
