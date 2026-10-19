class_name PhonePanel
extends MarginContainer
## Painel de baixo, do operador, em três blocos: a tela da conversa (as últimas falas que couberem, `_fit`; o registro inteiro
## fica na ferramenta Registro, `CallLog`), com os avisos (`flash`/`warn`, a última linha das falas), as opções de fala e a barra de agravamento;
## as teclas (`KeyCapStyle`); e o rádio de despacho (`radio`). A mesa comutadora tem uma miniatura dele
## (`ConsoleMini`): este painel é a vista de perto daquela. Mostra uma PhoneCall por vez (`show_call`) e se redesenha
## pelos sinais dela. É um console embutido na frente da mesa (`_draw`: a madeira de borda a borda, logo abaixo da
## borda do tampo); os blocos são telas e chapas encaixadas nela, e a tela da conversa apaga sem ligação
## (`ScreenGlass`). (A ligação em foco com o visor e o bloco do destino e das outras linhas saíram: a mesa já mostra.)

const LINES := 20   ## falas da ligação em foco consideradas; a tela mostra as últimas que couberem (`_fit`)
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f"), Color("3a2616")]   ## luz, meio, sombra, a frente da mesa
const BLINK := Color(1.7, 1.55, 1.1)   ## a tecla Atender no auge da piscada (`blink_answer`)

signal answer_pressed
signal transfer_pressed
signal hangup_pressed
signal listen_pressed

@onready var urgency: UrgencyBar = %Urgency
@onready var radio: Radio = %Radio
@onready var screen: Control = %ConvBox   ## a tela da conversa (a miniatura copia o lugar dela)
@onready var _transcript: RichTextLabel = %Transcript
@onready var _choices: HFlowContainer = %Choices
@onready var _answer: Button = %Answer
@onready var _transfer: Button = %Transfer
@onready var _hangup: Button = %Hangup
@onready var _listen: Button = %Listen   ## a chave de escuta da linha do FONE (Escutar / Soltar)
@onready var _glass: ScreenGlass = %Glass

var _call: PhoneCall
var _warn := ""   # o aviso na tela agora, embaixo das falas (numa linha à parte, empurrava o painel para cima)
var _warn_gen := 0
var _lines := PackedStringArray()   # as falas prontas para a tela, da mais antiga à mais nova
var shown_lines := 0   ## quantas falas cabem e aparecem agora (a miniatura mostra as mesmas)
var _blink: Tween   # a tecla Atender piscando (o treinamento mostra o que apertar)


func _ready() -> void:
	_answer.pressed.connect(answer_pressed.emit)
	_transfer.pressed.connect(transfer_pressed.emit)
	_hangup.pressed.connect(hangup_pressed.emit)
	_listen.pressed.connect(listen_pressed.emit)
	set_buttons(false, false, false)
	set_listen(false, false)
	_glass.idle = T.Key.CONSOLE_IDLE   # sem ligação, a tela espera com o cursor piscando
	_glass.off = true
	_transcript.resized.connect(_fit)   # as opções e os avisos ganham ou perdem fileiras: cabe mais ou menos conversa


## Atalhos (Input Map): tratados aqui, antes da interface, porque Espaço e Tab também servem para apertar o botão
## em foco e passar o foco adiante; com um campo de texto em foco, a tecla fica com ele (digitar no caderno).
## Só valem com o botão ativo; na pausa o painel não recebe nada.
func _input(e: InputEvent) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	for pair in [["answer_call", _answer], ["transfer_call", _transfer], ["listen_call", _listen], ["hang_up", _hangup]]:
		var b: Button = pair[1]
		if e.is_action_pressed(pair[0]) and not b.disabled and b.is_visible_in_tree():
			get_viewport().set_input_as_handled()
			b.pressed.emit()
			return


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
		draw_texture_rect(PixelArt.disc(6, [[2.0, Color("d8bc78"), Color("b49a5a"), Color("7a6438")], [3.0, Color("1a120c")]]), Rect2(p - Vector2(3, 3), Vector2(6, 6)), false)
		draw_rect(Rect2(p - Vector2(1, 0.5), Vector2(3, 1)), Color("5a4a2a"))   # a fenda


func shown() -> PhoneCall:
	return _call


func set_buttons(can_answer: bool, can_transfer: bool, can_hang: bool) -> void:
	_answer.disabled = not can_answer
	_transfer.disabled = not can_transfer
	_hangup.disabled = not can_hang


## A tecla Escutar: ativa com o FONE numa linha conectada; com a chave dela levantada, vira Soltar.
func set_listen(can: bool, up: bool) -> void:
	_listen.disabled = not can
	_listen.text = "LISTEN_STOP" if up else "LISTEN"


## Pisca a tecla Atender (no treinamento, para o jogador saber o que apertar) ou para de piscar.
func blink_answer(on: bool) -> void:
	if (_blink != null) == on:
		return
	if on:
		_blink = create_tween().set_loops()
		_blink.tween_property(_answer, "modulate", BLINK, 0.4)
		_blink.tween_property(_answer, "modulate", Color.WHITE, 0.4)
	else:
		_blink.kill()
		_blink = null
		_answer.modulate = Color.WHITE


## As três teclas, na ordem do painel (a miniatura acende as que estão ativas).
func keys() -> Array[Button]:
	return [_answer, _transfer, _listen, _hangup]


## Aviso numa linha da tela da conversa por `ms` milissegundos (enquanto isso a transcrição encolhe): o que acontece
## na linha ("Chamando 305...", "número não existe") e os avisos do jogo (`warn`).
func flash(text: String, ms: int = 2600) -> void:
	_warn = text
	_render_transcript()
	_warn_gen += 1
	var g := _warn_gen
	await get_tree().create_timer(ms / 1000.0, false).timeout
	if g == _warn_gen:
		clear_flash()


func clear_flash() -> void:
	_warn_gen += 1
	_warn = ""
	_render_transcript()


func display_text() -> String:
	return _warn


func warn(text: String) -> void:
	flash(text, 4000)


func _render_transcript() -> void:
	_lines.clear()
	if _call != null:
		for l in _call.transcript.slice(-LINES):
			var text := String(l["text"]).replace("[", "(")
			var marks: Array = l.get("marks", [])   # palavras-chave ouvidas, na ordem da fala
			for k in range(marks.size() - 1, -1, -1):   # do fim para o começo: uma não muda a posição da outra
				text = text.insert(marks[k][1], "[/u]").insert(marks[k][0], "[u]")
			match l["cls"]:
				"sys":
					_lines.append("[color=#9a917a][font_size=11]%s[/font_size][/color]\n" % text)
				"op":
					_lines.append("[color=#8dbb6c]%s[/color]  %s\n" % [T.text(T.Key.YOU), text])
				"ghost":
					_lines.append("[color=#f3a83c]—[/color]  [color=#c6d3c4]%s[/color]\n" % text)
				_:
					_lines.append("[color=#f3a83c]%s[/color]  %s\n" % [tr(l["who"]), text])
	if _warn != "":
		_lines.append("[color=#f3a83c]%s[/color]\n" % _warn.replace("[", "("))
	_fit()


## Mostra as últimas falas que cabem inteiras na tela (o que sobra dela depois dos avisos, das opções e da barra de
## agravamento; fala longa quebra em mais de uma linha), sempre pelo menos a mais nova.
func _fit() -> void:
	var n := _lines.size()
	while true:
		_transcript.text = "".join(_lines.slice(-n))
		if n <= 1 or _transcript.get_content_height() <= _transcript.size.y:
			break
		n -= 1
	shown_lines = n


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

