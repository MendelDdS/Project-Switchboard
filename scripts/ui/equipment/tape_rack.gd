extends Control
## O porta-fitas (equipamento da B4, `Switchboard.set_equipment`): um suporte de esmalte de pé na prateleira com as
## fitas virgens da noite (`Bureaucracy.tapes`) em pé nas fendas, cada uma no estojo, com a lombada para fora como
## livros numa estante. Sob o mouse, a próxima sobe um pouco; o clique a põe no gravador (o voo é desenhado por ele,
## `tape_recorder.gd`, a partir de `slot_pos`), a fenda fica vazia (de longe se vê quantas sobram) e as outras balançam.
## Sem fita ou com o gravador ocupado, o suporte sacode de lado. `bump` faz as fitas pularem (a fita batendo no gravador
## ao lado).

const Cassette := preload("res://scripts/ui/equipment/cassette.gd")
const SLOTS := 3   ## as fendas do suporte (as fitas da noite)
const PITCH := 10.0   ## de uma fenda à outra
const BASE := Rect2(0, 36, 34, 9)   ## a frente do suporte
const TOP := 3   ## as linhas do tampo dele
const SINK := 4.0   ## quanto cada estojo afunda na fenda
const HOVER_PX := 2.0
const WOBBLE_SEC := 0.25   ## as fitas balançando na fenda
const DENY_SEC := 0.3   ## o suporte sacudindo de lado

var _hover := false
var _wobble := 0.0   ## o que falta das fitas balançando
var _deny := 0.0     ## o que falta do suporte sacudindo
var _blank := -1     ## as virgens no último quadro (tirada uma, as outras balançam)
var _drawn := []     ## o que o último desenho mostrou

@onready var _desk := Bureaucracy.of(self)   ## o gerente (procurado uma vez: subir a árvore a cada quadro pesa)


func _ready() -> void:
	add_to_group(&"tape_rack")
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)


## Onde fica (na tela) o canto de cima à esquerda da fita da fenda `i` (de frente, como `Cassette.face` a desenha:
## de lado, ela fica no meio dessa largura), dentro do estojo parado.
func slot_pos(i: int) -> Vector2:
	var inside := Vector2(floorf((Cassette.CASE.x - Cassette.SPINE_W) / 2.0) - roundi((Cassette.FACE.x - Cassette.SPINE_W) / 2.0),
		floorf((Cassette.CASE.y - Cassette.FACE.y) / 2.0))
	return global_position + _slot(i) + inside


## O canto do estojo da fenda `i`, parado.
func _slot(i: int) -> Vector2:
	return Vector2(3.0 + i * PITCH + roundf(2 * Cassette.LEAN), BASE.position.y - 2.0 + SINK - Cassette.CASE.y)


## As fitas pulam na fenda (algo bateu na prateleira ao lado).
func bump() -> void:
	_wobble = WOBBLE_SEC


func _process(delta: float) -> void:
	var blank: int = _desk.tapes.blank if _desk else 0
	if _blank != -1 and blank < _blank:
		_wobble = WOBBLE_SEC
	_blank = blank
	_wobble = maxf(_wobble - delta, 0.0)
	_deny = maxf(_deny - delta, 0.0)
	var look := [_hover, blank, ceili(_wobble / 0.05), ceili(_deny / 0.05)]
	if look != _drawn:
		_drawn = look
		queue_redraw()


func _draw() -> void:
	var shake := Vector2(roundf(sin(_deny / DENY_SEC * TAU * 3.0) * 1.0), 0.0) if _deny > 0.0 else Vector2.ZERO
	var n := mini(_blank, SLOTS)
	for i in SLOTS:   # as fendas, escuras, no tampo
		draw_rect(Rect2(_slot(i) + shake + Vector2(0, Cassette.CASE.y - SINK - 1.0), Vector2(Cassette.CASE.x, 1)), Pal.BAKELITE[0])
	for i in n:
		var at := _slot(i) + shake
		if i == n - 1 and _hover:
			at.y -= HOVER_PX   # a próxima, pronta para sair
		if _wobble > 0.0 and (i + ceili(_wobble / 0.05)) % 2 == 0:
			at.y -= 1.0   # balançando na fenda
		Cassette.in_case(self, at)
	Cassette.block(self, Rect2(BASE.position + shake, BASE.size), TOP, Pal.SHELL[5], Pal.SHELL[3], Pal.SHELL[2])
	draw_rect(Rect2(BASE.position + shake, Vector2(BASE.size.x, 1)), Pal.SHELL[6])   # a quina da frente, na luz
	draw_rect(Rect2(BASE.position + shake + Vector2(0, BASE.size.y - 1), Vector2(BASE.size.x, 1)), Pal.SHELL[1])
	draw_rect(Rect2(BASE.position + shake + Vector2(0, BASE.size.y), Vector2(BASE.size.x + 2, 1)), Pal.SHELF_WOOD[0].darkened(0.5))   # a sombra rente


func _gui_input(e: InputEvent) -> void:
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or b.pressed:
		return
	var x := global_position.x / get_viewport().get_visible_rect().size.x
	if _desk.tapes.insert():
		Sfx.play_at("tape_out", x)
	else:
		_deny = DENY_SEC
		Sfx.play_at("deny", x, -8.0)
		_desk.main.warn(T.text(T.Key.WARN_NO_TAPES if _desk.tapes.blank <= 0 else T.Key.WARN_TAPE_INSIDE))
	accept_event()
