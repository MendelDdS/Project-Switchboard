class_name PhonePanel
extends MarginContainer
## Painel de baixo, do operador: a ligação em foco (linha, situação, visor e a barra de agravamento), a conversa (só as
## últimas `LINES` falas; o registro inteiro fica na ferramenta Registro, `CallLog`), avisos e opções de fala, as teclas
## (`KeyCapStyle`), o destino ligado à saída da linha e as outras linhas. Mostra uma PhoneCall por vez (`show_call`) e
## se redesenha pelos sinais dela. É um console embutido na frente da mesa (`_draw`: a madeira de borda a borda, logo
## abaixo da borda do tampo); os blocos são telas e chapas encaixadas nela, e a tela da conversa apaga sem ligação
## (`ScreenGlass`).

const LINES := 3   ## falas da ligação em foco no painel
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f"), Color("3a2616")]   ## luz, meio, sombra, a frente da mesa

signal answer_pressed
signal transfer_pressed
signal hangup_pressed

@onready var urgency: UrgencyBar = %Urgency
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
@onready var _dest: Label = %Dest
@onready var _dest_state: Label = %DestState
@onready var _glass: ScreenGlass = %Glass

var _call: PhoneCall
var _disp_until := 0
var _warn_gen := 0


func _ready() -> void:
	_answer.pressed.connect(answer_pressed.emit)
	_transfer.pressed.connect(transfer_pressed.emit)
	_hangup.pressed.connect(hangup_pressed.emit)
	set_buttons(false, false, false)


## Atalhos (Input Map): tratados aqui, antes da interface, porque Espaço e Tab também servem para apertar o botão
## em foco e passar o foco adiante; com um campo de texto em foco, a tecla fica com ele (digitar no caderno).
## Só valem com o botão ativo; na pausa o painel não recebe nada.
func _input(e: InputEvent) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	for pair in [["answer_call", _answer], ["transfer_call", _transfer], ["hang_up", _hangup]]:
		var b: Button = pair[1]
		if e.is_action_pressed(pair[0]) and not b.disabled and b.is_visible_in_tree():
			get_viewport().set_input_as_handled()
			b.pressed.emit()
			return


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
	_glass.off = c == null
	_render_transcript()
	_render_choices()


## O corpo do console: a frente de madeira da mesa, de uma borda da tela à outra, com o veio na horizontal, a quina do
## tampo pegando a luz no alto e os parafusos de latão que prendem o painel.
func _draw() -> void:
	var r := Rect2(Vector2(-global_position.x, -8), Vector2(get_viewport_rect().size.x, size.y + 40))
	draw_rect(r, WOOD[3])
	for i in int(r.size.y / 5.0):   # o veio
		var y := r.position.y + 6 + i * 5
		var x := r.position.x + fmod(i * 173.0, 90.0)
		while x < r.end.x:
			draw_rect(Rect2(x, y + (int(x) / 7) % 2, 40 + int(x * 0.37) % 70, 1), WOOD[2] if (i + int(x)) % 3 else WOOD[1])
			x += 150 + int(x * 0.13) % 60
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), WOOD[0])   # a quina do tampo
	draw_rect(Rect2(r.position + Vector2(0, 1), Vector2(r.size.x, 2)), WOOD[1])
	draw_rect(Rect2(r.position + Vector2(0, 3), Vector2(r.size.x, 1)), WOOD[2])
	for p in [Vector2(-12, 6), Vector2(size.x + 12, 6), Vector2(-12, size.y - 6), Vector2(size.x + 12, size.y - 6)]:
		draw_texture_rect(Switchboard.disc(6, [[2.0, Color("d8bc78"), Color("b49a5a"), Color("7a6438")], [3.0, Color("1a120c")]]), Rect2(p - Vector2(3, 3), Vector2(6, 6)), false)
		draw_rect(Rect2(p - Vector2(1, 0.5), Vector2(3, 1)), Color("5a4a2a"))   # a fenda


func shown() -> PhoneCall:
	return _call


func set_status(line_text: String, state_text: String, others_text: String) -> void:
	_line.text = line_text
	_state.text = state_text
	_others.text = others_text


## O destino ligado à saída da linha em foco (-1 = nenhum cabo) e a situação dele, já traduzida.
func set_dest(number: int, state: String) -> void:
	_dest.text = "—" if number == -1 else str(number)
	_dest_state.text = state


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


## Aviso numa linha da tela, por 4 s (enquanto isso a transcrição encolhe).
func warn(text: String) -> void:
	_warn.text = text
	_warn.visible = text != ""
	_warn_gen += 1
	var g := _warn_gen
	await get_tree().create_timer(4.0, false).timeout
	if g == _warn_gen:
		_warn.text = ""
		_warn.visible = false


func _render_transcript() -> void:
	var s := ""
	if _call != null:
		for l in _call.transcript.slice(-LINES):
			var text := String(l["text"]).replace("[", "(")
			match l["cls"]:
				"sys":
					s += "[color=#9a917a][font_size=11]%s[/font_size][/color]\n" % text
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

