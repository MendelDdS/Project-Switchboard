extends Control
## O compartimento de fitas (equipamento da B4, `Switchboard.set_equipment`): uma caixa funda no pé da coluna do lado
## do painel, embaixo do gravador, com as fitas virgens da noite (`Bureaucracy.tapes`) em pé, lado a lado, de lombada
## para a frente. Vista de cima e da direita (os olhos do operador): o fundo escurecendo para cima, na sombra da borda,
## a parede da esquerda por dentro, o alto e o lado de cada fita e a sombra dela no fundo; a beira da frente, mais alta,
## tapa o pé delas (`LIP`). Cada fita tem o lugar dela (`_full`): sob o mouse, a fita apontada sobe um pouco; o clique
## põe aquela no gravador: ela sobe de trás da beira (`RISE_SEC`, `RISE_PX`, desenhada aqui) e o gravador segue com o
## voo (`tape_recorder.gd`, de `slot_pos(taken)`); o lugar fica vazio e as outras balançam. A virgem devolvida pelo
## gravador volta para o lugar reservado (`hold`, vazio enquanto ela voa) e afunda nele (`land`). Sem fita ou com o
## gravador ocupado, o compartimento sacode de lado. `bump` faz as fitas pularem (a fita batendo no gravador logo acima).

const Cassette := preload("res://scripts/ui/equipment/cassette.gd")
const SLOTS := 3   ## os lugares (as fitas da noite)
const PITCH := 18.0   ## de uma fita à outra
const NICHE := Rect2(3, 3, 58, 95)   ## o vão, dentro da borda, até a beira da frente
const LIP := Rect2(3, 98, 58, 6)   ## a beira da frente, que tapa o pé das fitas
const FLOOR := 106.0   ## onde as fitas ficam de pé (atrás da beira e da borda de baixo: o alto delas cabe no vão, abaixo da borda de cima)
const WALL := 3.0   ## a parede da esquerda vista por dentro
const HOVER_PX := 1.0
const RISE_SEC := 0.08   ## a fita tirada subindo dentro do vão, até o alto quase na borda (aí o gravador a puxa
const RISE_PX := 2.0     ## para a frente, por cima da beira); a devolvida afunda o mesmo
const WOBBLE_SEC := 0.25   ## as fitas balançando
const DENY_SEC := 0.3   ## o compartimento sacudindo de lado

var taken := -1   ## o lugar da última fita tirada (de onde o gravador começa o voo)
var hold := -1    ## o lugar reservado para a fita que volta voando do gravador (vazio até ela chegar, `land`)
var _full: Array[bool] = []   ## os lugares com fita, um por lugar
var _pick := -1    ## o lugar clicado (tirada a fita, sai a dele)
var _hover := -1   ## a fita sob o mouse
var _wobble := 0.0   ## o que falta das fitas balançando
var _deny := 0.0     ## o que falta do compartimento sacudindo
var _move := 0.0     ## o que falta da fita subindo (tirada) ou afundando (devolvida)...
var _move_slot := -1   ## ...a do lugar...
var _move_up := true   ## ...e para onde
var _blank := -1     ## as virgens no último quadro
var _drawn := []     ## o que o último desenho mostrou

@onready var _desk := Bureaucracy.of(self)   ## o gerente (procurado uma vez: subir a árvore a cada quadro pesa)


func _ready() -> void:
	add_to_group(&"tape_rack")
	mouse_exited.connect(func(): _hover = -1)
	get_parent().move_child.call_deferred(self, 0)   # antes do gravador: a fita que sai daqui voa por cima (desenhada por ele)


## Onde fica (na tela) o canto de cima à esquerda da fita do lugar `i`, parada.
func slot_pos(i: int) -> Vector2:
	return global_position + _slot(i)


func _slot(i: int) -> Vector2:
	var row := SLOTS * Cassette.SPINE.x + (SLOTS - 1) * (PITCH - Cassette.SPINE.x)
	return Vector2(floorf((size.x - row) / 2.0) + i * PITCH + 1.0, FLOOR - Cassette.SPINE.y)   # (+1: a parede da esquerda)


## As fitas pulam (algo bateu no gravador logo acima).
func bump() -> void:
	_wobble = WOBBLE_SEC


## Um lugar vazio para uma fita que volta (o primeiro da esquerda), ou -1.
func free_slot() -> int:
	return _full.find(false)


## A fita devolvida chegou ao lugar `i` (reservado em `hold`): afunda nele e as outras balançam.
func land(i: int) -> void:
	hold = -1
	_move_slot = i
	_move_up = false
	_move = RISE_SEC
	_wobble = WOBBLE_SEC


func _process(delta: float) -> void:
	_sync()
	_wobble = maxf(_wobble - delta, 0.0)
	_deny = maxf(_deny - delta, 0.0)
	_move = maxf(_move - delta, 0.0)
	var look := [_hover, _full.duplicate(), hold, ceili(_wobble / 0.05), ceili(_deny / 0.05), roundi(_move / RISE_SEC * RISE_PX)]
	if look != _drawn:
		_drawn = look
		queue_redraw()


## Os lugares acompanham as virgens (`Tapes.blank`): sai a clicada (ou a da direita), volta no reservado (`hold`).
func _sync() -> void:
	var blank: int = _desk.tapes.blank if _desk else 0
	if _full.is_empty():
		for i in SLOTS:
			_full.append(i < blank)
	elif blank != _blank:
		while _full.count(true) > blank:
			var i := _pick if _pick >= 0 and _full[_pick] else _full.rfind(true)
			_full[i] = false
			taken = i
			_move_slot = i
			_move_up = true
			_move = RISE_SEC
			_wobble = WOBBLE_SEC
		while _full.count(true) < mini(blank, SLOTS):
			_full[hold if hold >= 0 and not _full[hold] else _full.find(false)] = true
	_pick = -1
	_blank = blank


func _draw() -> void:
	var shake := Vector2(roundf(sin(_deny / DENY_SEC * TAU * 3.0)), 0.0) if _deny > 0.0 else Vector2.ZERO
	Switchboard.round_rect(self, Rect2(shake, size), Pal.SHELL[5])   # a caixa de plástico branco, como o gravador
	draw_rect(Rect2(shake + Vector2(2, 0), Vector2(size.x - 4, 1)), Pal.SHELL[7])   # a quina de cima, na luz
	draw_rect(Rect2(shake + Vector2(2, size.y - 1), Vector2(size.x - 4, 1)), Pal.SHELL[2])
	var n := Rect2(NICHE.position + shake, NICHE.size)
	# o fundo: escuro no alto, na sombra da borda, clareando para baixo (de onde vem a luz da sala, de cima)
	draw_primitive(PackedVector2Array([n.position, Vector2(n.end.x, n.position.y), n.end, Vector2(n.position.x, n.end.y)]),
		PackedColorArray([Pal.VOID, Pal.VOID, Pal.BOARD_INSET, Pal.BOARD_INSET]), PackedVector2Array())
	# a parede da esquerda, por dentro (vista da direita, de costas para a luz): o plástico na sombra, rente à borda na
	# frente e estreitando para o fundo, no alto; o canto com o fundo, mais escuro
	draw_primitive(PackedVector2Array([n.position, n.position + Vector2(WALL, WALL), Vector2(n.position.x + WALL, n.end.y),
		Vector2(n.position.x, n.end.y)]), PackedColorArray([Pal.SHELL[0], Pal.SHELL[0], Pal.SHELL[1], Pal.SHELL[1]]), PackedVector2Array())
	draw_rect(Rect2(n.position.x + WALL, n.position.y + WALL, 1, n.size.y - WALL), Pal.VOID)
	draw_rect(Rect2(n.position, Vector2(n.size.x, 1)), Pal.VOID)   # a borda de cima por dentro, na sombra
	for i in _full.size():
		var moving := i == _move_slot and _move > 0.0
		if (not _full[i] and not moving) or i == hold:
			continue
		var at := _slot(i) + shake
		if moving:
			var f := 1.0 - _move / RISE_SEC
			at.y -= roundf(RISE_PX * ((1.0 - (1.0 - f) * (1.0 - f)) if _move_up else (1.0 - f) * (1.0 - f)))
		elif i == _hover:
			at.y -= HOVER_PX   # a apontada, pronta para sair
		elif _wobble > 0.0 and (i + ceili(_wobble / 0.05)) % 2 == 0:
			at.y -= 1.0   # balançando
		_draw_tape(at, n)
	# a beira da frente e a borda de baixo, por cima do pé das fitas; o alto da beira pega a luz
	Switchboard.round_rect(self, Rect2(shake + Vector2(0, LIP.position.y), Vector2(size.x, size.y - LIP.position.y)), Pal.SHELL[5])
	draw_rect(Rect2(shake + Vector2(2, size.y - 1), Vector2(size.x - 4, 1)), Pal.SHELL[2])
	var l := Rect2(LIP.position + shake, LIP.size)
	draw_rect(l, Pal.SHELL[4])
	draw_rect(Rect2(l.position, Vector2(l.size.x, 1)), Pal.SHELL[7])
	draw_rect(Rect2(l.position + Vector2(0, l.size.y - 1), Vector2(l.size.x, 1)), Pal.SHELL[5])


## Uma fita em pé com o canto em `at`, dentro do vão `n`: a sombra dela no fundo (à direita, longe da luz), o lado
## direito e o alto (vistos de cima e da direita) e a lombada.
func _draw_tape(at: Vector2, n: Rect2) -> void:
	var s := Vector2(Cassette.SPINE)
	var top := maxf(at.y - 2.0, n.position.y)
	draw_rect(Rect2(at.x + s.x + 1.0, top + 2.0, 2.0, n.end.y - top - 2.0), Pal.VOID)   # a sombra no fundo
	draw_rect(Rect2(at.x + s.x, top + 1.0, 1.0, n.end.y - top - 1.0), Pal.BAKELITE[1])   # o lado, fora da luz
	if at.y - 2.0 >= n.position.y - 1.0:   # o alto, na luz (sumindo na borda de cima quando a fita sobe)
		draw_rect(Rect2(at.x + 1.0, at.y - 2.0, s.x, 1.0), Pal.BAKELITE[4])
		draw_rect(Rect2(at.x, at.y - 1.0, s.x, 1.0), Pal.BAKELITE[5])
	Cassette.standing(self, at)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_hover = -1
		for i in _full.size():
			if _full[i] and i != hold and Rect2(_slot(i) - Vector2(2, 2), Vector2(Cassette.SPINE) + Vector2(4, 0)).has_point(e.position):
				_hover = i
		mouse_default_cursor_shape = CURSOR_ARROW if _hover == -1 else CURSOR_POINTING_HAND
		return
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or b.pressed:
		return
	var x := global_position.x / get_viewport().get_visible_rect().size.x
	_sync()   # (os lugares em dia antes de escolher: o clique pode vir antes do primeiro quadro)
	if _hover >= 0 and _desk.tapes.inside.is_empty():
		_pick = _hover
		_hover = -1
		_desk.tapes.insert()
		Sfx.play_at("tape_out", x)
	elif _desk.tapes.blank <= 0 or not _desk.tapes.inside.is_empty():
		_deny = DENY_SEC
		Sfx.play_at("deny", x, -8.0)
		_desk.main.warn(T.text(T.Key.WARN_NO_TAPES if _desk.tapes.blank <= 0 else T.Key.WARN_TAPE_INSIDE))
	accept_event()
