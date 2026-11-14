class_name PauseMenu
extends ColorRect
## Menu de pausa (Esc durante o turno) e configurações (também abertas pela tela inicial). A pausa é como a tela
## inicial (`%Screen`, por cima do jogo inteiro): "Pausado" em letra grande e as opções com lâmpada à esquerda e, à
## direita, no lugar da mesa, um espectro de áudio esmaecido (`pause_spectrum.gd`). As configurações abrem numa coluna
## à direita do menu (`%Settings`, `_column`: o menu continua ali, com a lâmpada delas acesa, e o que está atrás da
## coluna esmaece), também ao lado do menu da tela inicial; a pergunta de quem perde a noite vem num papel com fita
## por cima (`$Center`).
## Roda com o jogo pausado (process_mode ALWAYS): o relógio, as ligações e os timers param; o ambiente continua,
## abafado (`Sfx.muffle`), e nas configurações volta ao normal, para dar para ajustar o volume ouvindo.

signal resumed

const BOARD := preload("res://scripts/ui/title_board.gd")   ## (a lâmpada das opções e a letra grande da tela inicial)
const SLIDE := 12.0   ## de quantos px à esquerda a coluna das configurações entra (`_slide_in`)
const SLIDE_SEC := 0.14
const BUS_SLIDERS := {"Ambience": "%Ambience", "Voices": "%Voices", "Effects": "%Effects"}

var _settings_only := false   ## aberto sem pausar (tela inicial, bilhete do supervisor): Voltar fecha tudo
var _backdrop := true   ## com o fundo da pausa atrás (na tela inicial, não: a coluna abre ao lado do menu dela)
var _saved := {}              ## configurações ao abrir a tela: Voltar volta para elas, Aplicar grava as novas
var _asking := ""            ## a ação esperando a tecla nova (`_input`)
var _slide: Tween
var _confirm := Callable()   ## o que perde a noite, esperando o Sim (`_ask`)

@onready var _column_at: Vector2 = %Settings.position


func _ready() -> void:
	$Version.text = Settings.version_text()
	for b: Button in %Main.get_children() + [%Apply, %Back, %Language, %Display, %Colors]:
		b.icon = BOARD.lamp_art()
		b.mouse_entered.connect(b.grab_focus)   # o mouse escolhe como as setas: uma lâmpada acesa só
	_logo()
	%Resume.pressed.connect(resume)
	%OpenSettings.pressed.connect(func(): _show_settings(not %Settings.visible))
	%RestartNight.pressed.connect(_ask.bind(T.Key.PAUSE_ASK_RESTART, func():
		Sfx.muffle(false)
		get_tree().paused = false
		Main.restart()))
	%ToMenu.pressed.connect(_ask.bind(T.Key.PAUSE_ASK_MENU, func():   # a noite em andamento se perde, como em Recomeçar
		Sfx.muffle(false)
		get_tree().paused = false
		GameView.playing = false
		Main.restart()))
	%Yes.pressed.connect(func(): _confirm.call())
	%No.pressed.connect(_back)
	%Quit.pressed.connect(func(): get_tree().quit())
	%Back.pressed.connect(_back)
	%Apply.pressed.connect(_apply_settings)
	Settings.changed.connect(_sync_apply)
	_option(%Language, func(i: int): Settings.set_locale(Settings.LOCALES[i]))
	_option(%Display, func(i: int): Settings.set_fullscreen(i == 0))
	_option(%Colors, func(i: int): Settings.set_colorblind(i == 1))
	for bus in BUS_SLIDERS:
		var s: HSlider = get_node(BUS_SLIDERS[bus])
		s.value_changed.connect(func(v: float): Settings.set_volume(bus, v))
		s.drag_ended.connect(func(_c: bool): _preview(bus))
	for a: String in Settings.KEY_ACTIONS:   # as teclas do telefone: o nome do botão e a tecla, que se troca clicando
		var l := Label.new()
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		var b := Button.new()
		b.theme_type_variation = &"KeyCap"   # a tecla, numa borda de cantos redondos
		b.custom_minimum_size = Vector2(96, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.pressed.connect(_ask_key.bind(a, b))
		b.set_meta("action", a)
		l.set_meta("action", a)
		%KeyGrid.add_child(l)
		%KeyGrid.add_child(b)
	Settings.changed.connect(_key_names)
	_key_names()
	_fill_options()


## Esperando a tecla nova de `_asking` (a próxima apertada; Esc desiste).
func _input(e: InputEvent) -> void:
	if _asking == "" or not (e is InputEventKey and e.pressed and not e.echo):
		return
	get_viewport().set_input_as_handled()
	var code: int = (e as InputEventKey).physical_keycode
	var action := _asking
	_asking = ""
	if code == KEY_ESCAPE:
		_key_names()
	else:
		Settings.set_key(action, code)


func _ask_key(action: String, b: Button) -> void:
	_key_names()
	_asking = action
	b.text = T.text(T.Key.KEYS_PRESS)


## Os nomes das ações e das teclas de agora.
func _key_names() -> void:
	for n in %KeyGrid.get_children():
		var a: String = n.get_meta("action")
		n.text = T.text(Settings.KEY_ACTIONS[a]) if n is Label else Settings.key_name(Settings.key_of(a))


func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fill_options()
		_logo()


## "Pausado" em letra grande, como o nome do jogo na tela inicial.
func _logo() -> void:
	%Logo.texture = BOARD.logo_art(T.text(T.Key.SETTINGS if _settings_only else T.Key.PAUSE_TITLE), 2)


## Pausa o jogo e mostra o menu.
func open() -> void:
	_settings_only = false
	_backdrop = true
	_logo()
	get_tree().paused = true
	visible = true
	_show_settings(false)


## Só as configurações, sem pausar: por cima do jogo (o bilhete do supervisor), com o fundo da pausa, ou na tela
## inicial (`over_game` falso), só a coluna ao lado do menu dela.
func open_settings(over_game := true) -> void:
	_settings_only = true
	_backdrop = over_game
	_logo()
	visible = true
	_show_settings(true)


func resume() -> void:
	_column(false)
	Sfx.muffle(false)
	visible = false
	get_tree().paused = false
	resumed.emit()


## O que perde a noite em andamento pergunta antes, no mesmo papel (`key`, a pergunta); o Sim faz `action`.
func _ask(key: T.Key, action: Callable) -> void:
	Sfx.play("click")
	_confirm = action
	_column(false)
	%Question.text = T.text(key)
	%Main.visible = false
	$Center.visible = true
	%Ask.visible = true
	%No.grab_focus()


## Voltar (ou Esc): na pergunta, volta ao menu; nas configurações, descarta o que mudou.
func _back() -> void:
	if %Ask.visible:
		_show_settings(false)
	elif %Settings.visible:
		close_settings()
	else:
		resume()


func _apply_settings() -> void:
	Settings.save()
	_saved = Settings.snapshot()
	close_settings()


func close_settings() -> void:
	_show_settings(false)
	if _settings_only:
		visible = false


## Aplicar só acende quando há alguma mudança.
func _sync_apply() -> void:
	%Apply.disabled = Settings.snapshot() == _saved


## A coluna das configurações, à direita do menu: aberta, o que está atrás dela (o espectro, a mesa da tela inicial)
## esmaece debaixo de um véu (`%Veil`); fechada, o que não foi aplicado se desfaz.
func _column(on: bool) -> void:
	if %Settings.visible and not on and Settings.snapshot() != _saved:
		Settings.restore(_saved)
	_asking = ""
	%Settings.visible = on
	%OpenSettings.set_pressed_no_signal(on)   # a lâmpada dela fica acesa enquanto a coluna está aberta
	%Veil.visible = on


func _show_settings(on: bool) -> void:
	Sfx.play("click")
	var was: bool = %Settings.visible
	_column(on)
	%Screen.visible = _backdrop
	%Veil.self_modulate.a = 0.92 if _backdrop else 1.0   # na tela inicial o véu fecha mais: a mesa atrás é clara e cheia de letras
	$Version.visible = _backdrop   # (a tela inicial já mostra a versão)
	%Main.visible = not _settings_only
	$Center.visible = false
	%Ask.visible = false
	if not _settings_only:   # o jogo pausado fica abafado; nas configurações, não (o volume se ajusta ouvindo)
		Sfx.muffle(not on)
	if on:
		_saved = Settings.snapshot()
		_sync_apply()
		_fill_options()
		for bus in BUS_SLIDERS:
			(get_node(BUS_SLIDERS[bus]) as HSlider).set_value_no_signal(Settings.volumes[bus])
		%Language.grab_focus()
		_slide_in()
	elif not _settings_only:
		(%OpenSettings if was else %Resume).grab_focus()


## A coluna entra vindo do menu: uns poucos pixels inteiros para a direita, clareando.
func _slide_in() -> void:
	if _slide:
		_slide.kill()
	var at := _column_at
	_slide = create_tween().set_parallel()
	var t := _slide
	t.tween_method(func(k: float): %Settings.position = at - Vector2(roundf(SLIDE * (1.0 - k)), 0), 0.0, 1.0, SLIDE_SEC).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(%Settings, "modulate:a", 1.0, SLIDE_SEC).from(0.0)
	t.tween_property(%Veil, "modulate:a", 1.0, SLIDE_SEC).from(0.0)


## Uma opção de poucas escolhas, num botão: o clique ou o Enter passa à seguinte, as setas para os lados andam nas
## duas direções; `apply` recebe o índice da escolhida (os nomes, em `_set_option`).
func _option(b: Button, apply: Callable) -> void:
	b.set_meta("apply", apply)
	b.pressed.connect(_step.bind(b, 1))
	b.gui_input.connect(func(e: InputEvent):
		for d in [-1, 1]:
			if e.is_action_pressed("ui_left" if d < 0 else "ui_right"):
				b.accept_event()
				_step(b, d))


func _step(b: Button, by: int) -> void:
	var names: Array = b.get_meta("names")
	var at := posmod(int(b.get_meta("at")) + by, names.size())
	_set_option(b, names, at)
	(b.get_meta("apply") as Callable).call(at)


func _set_option(b: Button, names: Array, at: int) -> void:
	b.set_meta("names", names)
	b.set_meta("at", at)
	b.text = "< %s >" % names[at]


## As opções de texto traduzido (refeitas quando o idioma muda).
func _fill_options() -> void:
	_set_option(%Language, Settings.LOCALES.map(func(l: String) -> String: return Settings.LOCALE_NAMES[l]),
			Settings.LOCALES.find(Settings.locale))
	_set_option(%Display, [T.text(T.Key.DISPLAY_FULLSCREEN), T.text(T.Key.DISPLAY_WINDOW)], 0 if Settings.fullscreen else 1)
	_set_option(%Colors, [T.text(T.Key.COLORS_NORMAL), T.text(T.Key.COLORS_RED_GREEN)], 1 if Settings.colorblind else 0)


## Um som de amostra no barramento que acabou de mudar (o ambiente já está tocando).
func _preview(bus: String) -> void:
	match bus:
		"Voices":
			var sample := "alô"
			var vowel := false
			for i in sample.length():
				vowel = Sfx.speak_char("f", sample, i, vowel)
				await get_tree().create_timer(0.09).timeout
		"Effects":
			Sfx.play("sw")
