class_name PhonePanel
extends Bevel
## Telefone do operador: visor, transcrição da ligação em foco, opções de fala e os botões.
## Mostra uma PhoneCall por vez (`show_call`) e se redesenha pelos sinais dela.

signal answer_pressed
signal transfer_pressed
signal hangup_pressed

@onready var fone_socket: FoneSocket = %FoneSocket
@onready var _display: Label = %Display
@onready var _line: Label = %CallLine
@onready var _state: Label = %CallState
@onready var _others: Label = %Others
@onready var _transcript: RichTextLabel = %Transcript
@onready var _choices: HFlowContainer = %Choices
@onready var _warn: Label = %Warn
@onready var _answer: Button = %Answer
@onready var _transfer: Button = %Transfer
@onready var _hangup: Button = %Hangup

var _call: PhoneCall
var _disp_until := 0
var _warn_gen := 0


func _ready() -> void:
	_answer.pressed.connect(answer_pressed.emit)
	_transfer.pressed.connect(transfer_pressed.emit)
	_hangup.pressed.connect(hangup_pressed.emit)
	set_buttons(false, false, false)


func _process(_delta: float) -> void:
	if _disp_until > 0 and Time.get_ticks_msec() > _disp_until:
		_disp_until = 0
		_display.text = ""


## Passa a exibir a ligação c (a transcrição e as opções acompanham os sinais dela).
func show_call(c: PhoneCall) -> void:
	if c == _call:
		_render_choices()
		return
	if _call != null:
		_call.transcript_changed.disconnect(_render_transcript)
		_call.options_changed.disconnect(_render_choices)
		_call.state_changed.disconnect(_sync_choices)
	_call = c
	if c != null:
		c.transcript_changed.connect(_render_transcript)
		c.options_changed.connect(_render_choices)
		c.state_changed.connect(_sync_choices)
	_render_transcript()
	_render_choices()


func shown() -> PhoneCall:
	return _call


func set_status(line_text: String, state_text: String, others_text: String) -> void:
	_line.text = line_text
	_state.text = state_text
	_others.text = others_text


func set_buttons(can_answer: bool, can_transfer: bool, can_hang: bool) -> void:
	_answer.disabled = not can_answer
	_transfer.disabled = not can_transfer
	_hangup.disabled = not can_hang


## Mensagem no visor por `ms` milissegundos.
func flash(text: String, ms: int = 2600) -> void:
	_display.text = text
	_disp_until = Time.get_ticks_msec() + ms


func clear_flash() -> void:
	_disp_until = 0
	_display.text = ""


func display_text() -> String:
	return _display.text


func warn(text: String) -> void:
	_warn.text = text
	_warn_gen += 1
	var g := _warn_gen
	await get_tree().create_timer(4.0).timeout
	if g == _warn_gen:
		_warn.text = ""


func _render_transcript() -> void:
	var s := ""
	if _call != null:
		for l in _call.transcript:
			var text := String(l["text"]).replace("[", "(")
			match l["cls"]:
				"sys":
					s += "[color=#9a917a][font_size=13]%s[/font_size][/color]\n" % text
				"op":
					s += "[color=#8dbb6c]%s[/color]  %s\n" % [T.text(T.Key.YOU), text]
				"ghost":
					s += "[color=#f3a83c]—[/color]  [color=#c6d3c4]%s[/color]\n" % text
				_:
					s += "[color=#f3a83c]%s[/color]  %s\n" % [tr(l["who"]), text]
	_transcript.text = s


## Só a ligação em que o operador está mostra as opções de fala.
func _render_choices() -> void:
	for ch in _choices.get_children():
		ch.queue_free()
	if _call == null or not _call.on_line:
		return
	for o in _call.options:
		var b := Button.new()
		b.text = o["label"]
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # já vem traduzido
		b.theme_type_variation = &"ChoiceButton"
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = _call.talking
		b.pressed.connect(o["fn"])
		_choices.add_child(b)


func _sync_choices() -> void:
	for b in _choices.get_children():
		if b is Button and not b.is_queued_for_deletion():
			b.disabled = _call.talking
