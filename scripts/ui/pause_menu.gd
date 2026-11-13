class_name PauseMenu
extends ColorRect
## Menu de pausa (Esc durante o turno) e configurações (também abertas pela tela inicial).
## Roda com o jogo pausado (process_mode ALWAYS): o relógio, as ligações e os timers param; o ambiente continua,
## abafado (`Sfx.muffle`), e nas configurações volta ao normal, para dar para ajustar o volume ouvindo.

signal resumed

const BUS_SLIDERS := {"Ambience": "%Ambience", "Voices": "%Voices", "Effects": "%Effects"}

var _settings_only := false   ## aberto pela tela inicial: Voltar fecha tudo (não há jogo pausado)
var _saved := {}              ## configurações ao abrir a tela: Voltar volta para elas, Aplicar grava as novas
var _asking := ""            ## a ação esperando a tecla nova (`_input`)
var _confirm := Callable()   ## o que perde a noite, esperando o Sim (`_ask`)


func _ready() -> void:
	$Version.text = Settings.version_text()
	%Resume.pressed.connect(resume)
	%OpenSettings.pressed.connect(_show_settings.bind(true))
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
	for l in Settings.LOCALES:
		%Language.add_item(Settings.LOCALE_NAMES[l])
	%Language.item_selected.connect(func(i: int): Settings.set_locale(Settings.LOCALES[i]))
	for bus in BUS_SLIDERS:
		var s: HSlider = get_node(BUS_SLIDERS[bus])
		s.value_changed.connect(func(v: float): Settings.set_volume(bus, v))
		s.drag_ended.connect(func(_c: bool): _preview(bus))
	%Display.item_selected.connect(func(i: int): Settings.set_fullscreen(i == 0))
	%Colors.item_selected.connect(func(i: int): Settings.set_colorblind(i == 1))
	for a: String in Settings.KEY_ACTIONS:   # as teclas do telefone: o nome do botão e a tecla, que se troca clicando
		var l := Label.new()
		l.theme_type_variation = &"InkLabel"
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


## Pausa o jogo e mostra o menu.
func open() -> void:
	_settings_only = false
	get_tree().paused = true
	visible = true
	_show_settings(false)


## Só as configurações (tela inicial, sem pausar).
func open_settings() -> void:
	_settings_only = true
	visible = true
	_show_settings(true)


func resume() -> void:
	Sfx.muffle(false)
	visible = false
	get_tree().paused = false
	resumed.emit()


## O que perde a noite em andamento pergunta antes, no mesmo papel (`key`, a pergunta); o Sim faz `action`.
func _ask(key: T.Key, action: Callable) -> void:
	Sfx.play("click")
	_confirm = action
	%Question.text = T.text(key)
	%Main.visible = false
	%Ask.visible = true
	%No.grab_focus()


## Voltar (ou Esc): na pergunta, volta ao menu; nas configurações, descarta o que mudou.
func _back() -> void:
	if %Ask.visible:
		_show_settings(false)
	elif %Settings.visible:
		Settings.restore(_saved)
		_close_settings()
	else:
		resume()


func _apply_settings() -> void:
	Settings.save()
	_close_settings()


func _close_settings() -> void:
	_asking = ""
	if _settings_only:
		visible = false
	else:
		_show_settings(false)


## Aplicar só acende quando há alguma mudança.
func _sync_apply() -> void:
	%Apply.disabled = Settings.snapshot() == _saved


func _show_settings(on: bool) -> void:
	Sfx.play("click")
	%Main.visible = not on
	%Settings.visible = on
	%Ask.visible = false
	if not _settings_only:   # o jogo pausado fica abafado; nas configurações, não (o volume se ajusta ouvindo)
		Sfx.muffle(not on)
	if on:
		_saved = Settings.snapshot()
		_sync_apply()
		%Language.select(Settings.LOCALES.find(Settings.locale))
		for bus in BUS_SLIDERS:
			(get_node(BUS_SLIDERS[bus]) as HSlider).set_value_no_signal(Settings.volumes[bus])
		%Display.select(0 if Settings.fullscreen else 1)
		%Colors.select(1 if Settings.colorblind else 0)


## As opções de texto traduzido (refeitas quando o idioma muda).
func _fill_options() -> void:
	%Display.clear()
	for k in [T.Key.DISPLAY_FULLSCREEN, T.Key.DISPLAY_WINDOW]:
		%Display.add_item(T.text(k))
	%Display.select(0 if Settings.fullscreen else 1)
	%Colors.clear()
	for k in [T.Key.COLORS_NORMAL, T.Key.COLORS_RED_GREEN]:
		%Colors.add_item(T.text(k))
	%Colors.select(1 if Settings.colorblind else 0)


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
