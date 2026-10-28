extends PanelContainer
## A pilha de fitas da mesa vista de perto (B4): clicada a pilha (`Background.tapes_clicked`), abre num papel logo
## acima dela com as fitas tiradas do gravador (`Tapes.on_desk`), a última em cima, cada uma deitada com a etiqueta
## (`Cassette.lying`) e o botão Descartar (`Tapes.discard`): a descartada cai do papel para fora da tela (`_fall`). As que ficam vão para as autoridades no fim do turno
## (`Tapes.hand_over`). Fecha clicando fora dela ou com Esc, e sozinha quando não sobra fita ou o turno acaba.

const Cassette := preload("res://scripts/ui/equipment/cassette.gd")
const Tape := preload("res://scripts/bureaucracy/tape.gd")
const FALL_SEC := 0.45   ## a descartada caindo até sair da tela

var _shown: Array = []   ## as fitas na lista, de cima para baixo

var _desk: Bureaucracy

@onready var _rows: VBoxContainer = $Rows


func _ready() -> void:
	set_process(false)
	_hook.call_deferred()   # (o Main fica pronto depois dos filhos)


func _hook() -> void:
	_desk = Bureaucracy.of(self)
	_desk.main.background.tapes_clicked.connect(open)


func open() -> void:
	if not _desk.main.running or _desk.main.ending:
		return
	_fill()
	visible = true
	set_process(true)
	Sfx.play_at("tape_out", _sx())


func close() -> void:
	visible = false
	set_process(false)


func _process(_delta: float) -> void:
	if _desk.main.ending or _desk.tapes.on_desk().is_empty():
		close()
	elif _desk.tapes.on_desk().size() != _shown.size():   # chegou outra do gravador
		_fill()


## Monta uma linha por fita da mesa (a fita e o botão) e põe o quadro acima da pilha.
func _fill() -> void:
	for r in _rows.get_children():
		_rows.remove_child(r)
		r.queue_free()
	_shown = _desk.tapes.on_desk()
	_shown.reverse()
	for t in _shown:
		var row := HBoxContainer.new()
		var tape := Control.new()
		tape.custom_minimum_size = Vector2(Cassette.SPINE.y, Cassette.SPINE.x)
		tape.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tape.draw.connect(_draw_tape.bind(tape, t))
		var b := Button.new()
		b.theme_type_variation = &"InkButton"
		b.text = T.text(T.Key.EQUIP_DISCARD)
		b.pressed.connect(_discard.bind(t, tape))
		row.add_child(tape)
		row.add_child(b)
		_rows.add_child(row)
	reset_size()
	var pile: Rect2 = _desk.main.background.prop_rect(Background.TAPES_ID)
	var vp := get_viewport_rect().size
	position = Vector2(clampf(pile.get_center().x - size.x / 2.0, 4.0, vp.x - size.x - 4.0), maxf(pile.position.y - size.y - 6.0, 4.0)).round()


func _discard(t: Tape, tape: Control) -> void:
	_desk.tapes.discard(t)
	_fall(t, tape.global_position)
	if _desk.tapes.on_desk().is_empty():
		close()
	else:
		_fill()


## A fita `t` caindo de `from` (px da tela) até sair por baixo, acelerando e indo um pouco para o lado, por cima de
## tudo (fora do papel, que se refaz sem ela).
func _fall(t: Tape, from: Vector2) -> void:
	var tape := Control.new()
	tape.z_index = z_index + 1
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tape.position = from
	tape.draw.connect(_draw_tape.bind(tape, t))
	get_parent().add_child(tape)
	var drop := get_viewport_rect().size.y + 4.0 - from.y
	var tw := tape.create_tween()
	tw.tween_method(func(f: float): tape.position = (from + Vector2(-8.0 * f, drop * f * f)).round(), 0.0, 1.0, FALL_SEC)
	tw.tween_callback(tape.queue_free)


## A fita `t` deitada em `n`, com a etiqueta.
func _draw_tape(n: Control, t: Tape) -> void:
	Cassette.lying(n, Vector2.ZERO, Cassette.label_of(t.call) if t.call != null else "", t.hour, t.words.size(), t.call != null and not t.marked)


func _sx() -> float:
	return (position.x + size.x / 2.0) / get_viewport_rect().size.x


func _input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventMouseButton and e.pressed and not get_global_rect().has_point(e.position):
		close()   # (o clique segue: fora, vale para o que estiver lá)
	elif e.is_action_pressed("cancel_plug"):
		close()
		get_viewport().set_input_as_handled()
