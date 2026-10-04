class_name PhonePanel
extends MarginContainer
## Telefone do operador, um console em cunha visto de cima e de frente: na carcaça de trás, o encaixe do FONE e a tela
## (visor, transcrição da ligação em foco, avisos e opções de fala) e, logo abaixo dela, a fenda da barra de
## agravamento; no deck da frente, mais baixo, o alto-falante e as teclas (`KeyCapStyle`). Mostra uma PhoneCall por vez (`show_call`) e se
## redesenha pelos sinais dela.

const INSET := 10.0     ## a carcaça abre para baixo: no alto, ela fica tanto mais estreita de cada lado
const TOP_FACE := 9.0   ## o tampo da carcaça, visto de cima

signal answer_pressed
signal transfer_pressed
signal hangup_pressed

@onready var fone_socket: FoneSocket = %FoneSocket
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
@onready var _screen: Control = %Screen
@onready var _strip: Control = %Strip
@onready var _deck: Control = %DeckBox

var _call: PhoneCall
var _disp_until := 0
var _warn_gen := 0


func _ready() -> void:
	_answer.pressed.connect(answer_pressed.emit)
	_transfer.pressed.connect(transfer_pressed.emit)
	_hangup.pressed.connect(hangup_pressed.emit)
	set_buttons(false, false, false)
	resized.connect(queue_redraw)
	_deck.resized.connect(queue_redraw)


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
		for l in _call.transcript:
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


## A carcaça: silhueta que abre para baixo (perspectiva), tampo visto de cima, frente com a tela embutida (moldura mais
## grossa embaixo) e a fenda da barra; a carcaça faz sombra no deck, que termina na beira da frente. Luz no alto à
## esquerda, como no resto da mesa.
func _draw() -> void:
	var w := size.x
	var h := size.y
	var side := func(y: float) -> float: return INSET * (1.0 - y / h)   # quanto a silhueta recua de cada lado em y
	var band := func(y0: float, y1: float, pad: float) -> PackedVector2Array:
		return PackedVector2Array([Vector2(side.call(y0) + pad, y0), Vector2(w - side.call(y0) - pad, y0),
			Vector2(w - side.call(y1) - pad, y1), Vector2(side.call(y1) + pad, y1)])
	var deck_y := _box(_deck).position.y
	draw_colored_polygon(band.call(0.0, h, 0.0), Pal.EDGE)
	# o deck, mais baixo, e a beira da frente dele
	draw_colored_polygon(band.call(deck_y, h - 6.0, 2.0), Pal.PANEL_LO.lightened(0.06))
	draw_colored_polygon(band.call(h - 6.0, h - 2.0, 2.0), Pal.PANEL_LO)
	draw_colored_polygon(band.call(h - 6.0, h - 5.0, 2.0), Pal.PANEL.lightened(0.05))
	# a carcaça da tela: frente e tampo
	draw_colored_polygon(band.call(2.0, deck_y, 2.0), Pal.PANEL)
	draw_colored_polygon(band.call(2.0, TOP_FACE, 2.0), Pal.PANEL_HI)
	draw_colored_polygon(band.call(TOP_FACE, TOP_FACE + 1.0, 2.0), Pal.PANEL_HI.lightened(0.12))   # a aresta pega a luz
	draw_colored_polygon(band.call(deck_y - 2.0, deck_y, 2.0), Pal.PANEL_LO)   # a base da carcaça, na sombra
	# a tela embutida: moldura (mais grossa embaixo) e o rebaixo
	var scr := _box(_screen)
	draw_rect(scr.grow_individual(6, 5, 6, 9), Color("221e17"))
	draw_rect(Rect2(scr.position.x - 6, scr.end.y + 8, scr.size.x + 12, 1), Pal.PANEL_HI)   # luz na beira de baixo
	draw_rect(scr.grow(2), Color.BLACK)
	draw_rect(Rect2(scr.position - Vector2(2, 2), Vector2(scr.size.x + 4, 1)), Pal.PANEL_LO)
	# a fenda da barra de agravamento
	var slot := _box(_strip).grow_individual(-8, -4, -8, -2)
	draw_rect(slot, Color.BLACK)
	draw_rect(slot.grow(-1), Color("0c0b08"))
	draw_rect(Rect2(slot.position.x, slot.end.y, slot.size.x, 1), Pal.PANEL_HI)
	# o alto-falante, à esquerda das teclas: grade de frestas no deck
	var grill := Rect2(_box(_deck).position + Vector2(12, 16), Vector2(96, 30))
	draw_rect(grill.grow(1), Pal.PANEL_LO)
	for i in 6:
		draw_rect(Rect2(grill.position.x + 2, grill.position.y + 2 + i * 5, grill.size.x - 4, 2), Color("050403"))
		draw_rect(Rect2(grill.position.x + 2, grill.position.y + 4 + i * 5, grill.size.x - 4, 1), Pal.PANEL.lightened(0.08))
	# a sombra da carcaça no deck
	for i in 4:
		draw_colored_polygon(band.call(deck_y + i * 2.0, deck_y + i * 2.0 + 2.0, 2.0), Color(0, 0, 0, 0.32 - i * 0.08))


## O retângulo de um nó de dentro, nas coordenadas do painel.
func _box(n: Control) -> Rect2:
	return Rect2(n.global_position - global_position, n.size)
