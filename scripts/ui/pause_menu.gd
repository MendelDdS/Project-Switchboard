class_name PauseMenu
extends ColorRect
## Menu de pausa (Esc durante o turno) e configurações (também abertas pela tela inicial).
## Roda com o jogo pausado (process_mode ALWAYS): o relógio, as ligações e os timers param; o ambiente continua,
## para dar para ajustar o volume ouvindo.

signal resumed

const BUS_SLIDERS := {"Ambience": "%Ambience", "Voices": "%Voices", "Effects": "%Effects"}

var _settings_only := false   ## aberto pela tela inicial: Voltar fecha tudo (não há jogo pausado)
var _saved := {}              ## configurações ao abrir a tela: Voltar volta para elas, Aplicar grava as novas


func _ready() -> void:
	%Resume.pressed.connect(resume)
	%OpenSettings.pressed.connect(_show_settings.bind(true))
	%RestartNight.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
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
	%Speed.item_selected.connect(Settings.set_text_speed)
	_fill_speeds()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fill_speeds()


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
	visible = false
	get_tree().paused = false
	resumed.emit()


## Voltar (ou Esc): nas configurações, descarta o que mudou.
func _back() -> void:
	if %Settings.visible:
		Settings.restore(_saved)
		_close_settings()
	else:
		resume()


func _apply_settings() -> void:
	Settings.save()
	_close_settings()


func _close_settings() -> void:
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
	if on:
		_saved = Settings.snapshot()
		_sync_apply()
		%Language.select(Settings.LOCALES.find(Settings.locale))
		for bus in BUS_SLIDERS:
			(get_node(BUS_SLIDERS[bus]) as HSlider).set_value_no_signal(Settings.volumes[bus])
		%Speed.select(Settings.text_speed)


func _fill_speeds() -> void:
	%Speed.clear()
	for k in [T.Key.SPEED_SLOW, T.Key.SPEED_NORMAL, T.Key.SPEED_FAST]:
		%Speed.add_item(T.text(k))
	%Speed.select(Settings.text_speed)


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
