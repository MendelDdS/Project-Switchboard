class_name Notebook
extends Control
## Aba do caderno de ocorrências. Cada ligação encerrada entra numa fila; o jogador registra quando puder.
## Também guarda a anotação manuscrita da linha 07.

signal pending_changed(has_pending: bool)
signal registered

const TYPES := ["Escolha…", "Ligação comum", "Emergência", "Trote", "Outro"]
const NOTE_LOW := Vector2(30, 220)    ## anotação no espaço vazio do formulário
const NOTE_HIGH := Vector2(250, 40)   ## anotação sobre a tabela, enquanto houver formulário aberto

var entries: Array[Dictionary] = []
var pending: Dictionary = {}
var queue: Array[Dictionary] = []

@onready var _ledger: RichTextLabel = %Ledger
@onready var _form: Control = %Form
@onready var _time: Label = %Time
@onready var _who: LineEdit = %Who
@onready var _where: LineEdit = %Where
@onready var _type: OptionButton = %Type
@onready var _unit: LineEdit = %Unit
@onready var _obs: LineEdit = %Obs
@onready var _message: Label = %Message
@onready var scrawl: Scrawl = %Scrawl


func _ready() -> void:
	for t in TYPES:
		_type.add_item(t)
	%Register.pressed.connect(register)
	_render_ledger()
	_fill()


## Pautas do caderno.
func _draw() -> void:
	for k in 18:
		draw_rect(Rect2(0, 30 + k * 26, size.x, 1), Color(0.35, 0.43, 0.55, 0.22))


func has_pending() -> bool:
	return not pending.is_empty()


## Nova ocorrência. Se já há uma no formulário, entra na fila sem apagar o que o jogador está preenchendo.
func add(rec: Dictionary) -> void:
	if pending.is_empty():
		pending = rec
		_fill()
	else:
		queue.append(rec)
		_update_title()
	pending_changed.emit(true)


## O registro mudou depois de entrar no caderno (ex.: unidades enviadas para a emergência).
func refresh_record(rec: Dictionary) -> void:
	if is_same(rec, pending):
		_fill()


func register() -> void:
	if pending.is_empty():
		return
	if _type.selected <= 0:
		_message.text = tr("Escolha o tipo da ocorrência.")
		return
	entries.append({
		"time": pending["time"], "who": _who.text, "where": _where.text,
		"type": _type.get_item_text(_type.selected),
		"unit": _unit.text if _unit.text != "" else "—", "obs": _obs.text if _obs.text != "" else "—",
	})
	pending = queue.pop_front() if not queue.is_empty() else {}
	Sfx.play("pencil")
	_render_ledger()
	_fill()
	pending_changed.emit(has_pending())
	registered.emit()


func set_note(lines: PackedStringArray) -> void:
	scrawl.set_lines(lines)


func show_note() -> void:
	scrawl.visible = true


func _fill() -> void:
	scrawl.position = NOTE_LOW if pending.is_empty() else NOTE_HIGH
	_form.visible = not pending.is_empty()
	if pending.is_empty():
		return
	_update_title()
	_who.text = pending["who"]
	_where.text = pending["where"]
	_unit.text = pending["unit"]
	_obs.text = pending["obs"]
	_type.select(0)
	_message.text = ""


func _update_title() -> void:
	_time.text = tr("Nova ocorrência · %s") % pending["time"]
	if not queue.is_empty():
		_time.text += "   " + tr("(+%d na fila)") % queue.size()


func _render_ledger() -> void:
	var s := "[table=6]"
	for h in ["Horário", "Solicitante", "Local / destino", "Tipo", "Unidade", "Obs."]:
		s += "[cell padding=2,0,8,4][font=res://fonts/PixelifySans.ttf][font_size=12][color=#5a4d3a]%s[/color][/font_size][/font][/cell]" % tr(h)
	if entries.is_empty():
		s += "[/table]\n[font=res://fonts/PixelifySans.ttf][font_size=13][color=#5a4d3a]%s[/color][/font_size][/font]" % tr("Nenhuma ocorrência registrada neste turno.")
	else:
		for r in entries:
			for k in ["time", "who", "where", "type", "unit", "obs"]:
				s += "[cell padding=2,2,8,2]%s[/cell]" % String(r[k]).replace("[", "(")
		s += "[/table]"
	_ledger.text = s
