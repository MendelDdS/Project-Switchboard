extends Node
## Configurações do jogador (autoload `Settings`), salvas em user://settings.cfg: idioma, volume de cada barramento
## a tela (cheia ou janela; ampliação suave ou só por inteiro, que o `GameView` aplica), as cores para daltonismo e
## as teclas do telefone (`KEY_ACTIONS`). Os `set_*` valem na hora (prévia) mas só ficam salvos com `save()`; `snapshot()`/`restore()`
## permitem descartar. O menu de configurações (PauseMenu) usa os dois: Aplicar salva, Voltar restaura.
## `-- --lang=en` força um idioma nesta execução. Testes (`-s`) não leem nem gravam o arquivo do jogador.

signal changed

const PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "pt_BR"
const LOCALES := ["pt_BR", "en", "es"]
## Cada idioma escrito no próprio idioma (não se traduz).
const LOCALE_NAMES := {"pt_BR": "Português (Brasil)", "en": "English (US)", "es": "Español"}
const BUSES := ["Ambience", "Voices", "Effects"]
## As ações que o jogador troca de tecla nas configurações, com o nome do botão de cada uma (`keys`).
const KEY_ACTIONS := {"answer_call": T.Key.ANSWER, "transfer_call": T.Key.TRANSFER, "listen_call": T.Key.LISTEN, "hang_up": T.Key.HANG_UP}
## Barramentos sem controle próprio, que seguem o volume de outro (o atrito do fio vai direto para o Master).
const FOLLOWS := {"Rub": "Effects"}

var locale := DEFAULT_LOCALE
var volumes := {"Ambience": 1.0, "Voices": 1.0, "Effects": 1.0}   ## 0..1, linear
var fullscreen := true                                              ## tela cheia (falso: janela)
var keys := {}   ## ação de `KEY_ACTIONS` -> a tecla escolhida (`physical_keycode`; sem ela, a do projeto)
var _default_keys := {}   ## as teclas do projeto (`project.godot`), lidas antes de aplicar as escolhidas
var colorblind := false   ## as cores para daltonismo vermelho-verde: o verde das lâmpadas vira azul (`Pal.ok`)
var _persist := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ThemeDB.get_project_theme().set_font("normal_font", "HandText", Pal.hand)   # a letra de mão é montada em código
	var args := OS.get_cmdline_args()
	# testes (`tests/runner.tscn -- --test=x`, ou um script com -s) não leem nem gravam o arquivo do jogador
	for a: String in KEY_ACTIONS:
		_default_keys[a] = InputMap.action_get_events(a).filter(func(e): return e is InputEventKey)[0].physical_keycode
	_persist = not ("-s" in args or "--script" in args or Array(OS.get_cmdline_user_args()).any(func(a: String): return a.begins_with("--test=")))
	if _persist:
		_load()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang=") and a.get_slice("=", 1) in LOCALES:
			locale = a.get_slice("=", 1)
	_apply()


func set_locale(l: String) -> void:
	if l in LOCALES:
		locale = l
		_changed()


## `v` de 0 a 1.
func set_volume(bus: String, v: float) -> void:
	volumes[bus] = clampf(v, 0.0, 1.0)
	_changed()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_changed()


## Troca a tecla de `action`; a ação que já usava `code` fica com a tecla antiga desta (as duas trocam).
func set_key(action: String, code: int) -> void:
	for a: String in KEY_ACTIONS:
		if a != action and key_of(a) == code:
			keys[a] = key_of(action)
	keys[action] = code
	_changed()


## A tecla de `action` agora (`physical_keycode`).
func key_of(action: String) -> int:
	return keys.get(action, _default_keys.get(action, 0))


## O nome da tecla `code` como ela aparece no teclado (Espaço traduzido; as outras, pelo leiaute do jogador).
static func key_name(code: int) -> String:
	if code == KEY_SPACE:
		return T.text(T.Key.KEY_SPACE)
	if DisplayServer.get_name() == "headless":   # (sem tela não há leiaute: o nome no teclado americano)
		return OS.get_keycode_string(code)
	return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(code))


func set_colorblind(on: bool) -> void:
	colorblind = on
	_changed()


## A versão do jogo como ela aparece na tela inicial e na pausa ("v0.4.0 alpha"): o número do projeto
## (`application/config/version`, que as exportações usam; veja VERSOES.md) e a fase (`application/config/stage`;
## vazia na 1.0).
static func version_text() -> String:
	var stage := str(ProjectSettings.get_setting("application/config/stage", ""))
	return ("v%s %s" % [ProjectSettings.get_setting("application/config/version", ""), stage]).strip_edges()


## Estado atual, para comparar ou restaurar depois.
func snapshot() -> Dictionary:
	return {"locale": locale, "volumes": volumes.duplicate(), "fullscreen": fullscreen, "colorblind": colorblind, "keys": keys.duplicate()}


func restore(s: Dictionary) -> void:
	locale = s["locale"]
	volumes = s["volumes"].duplicate()
	fullscreen = s["fullscreen"]
	colorblind = s["colorblind"]
	keys = s["keys"].duplicate()
	_changed()


func save() -> void:
	if not _persist:
		return
	var f := ConfigFile.new()
	f.set_value("settings", "locale", locale)
	f.set_value("display", "fullscreen", fullscreen)
	f.set_value("display", "colorblind", colorblind)
	for a: String in keys:
		f.set_value("keys", a, keys[a])
	for bus in BUSES:
		f.set_value("volume", bus, volumes[bus])
	f.save(PATH)


func _changed() -> void:
	_apply()
	changed.emit()


func _apply() -> void:
	Pal.colorblind = colorblind
	for a: String in KEY_ACTIONS:   # (os outros eventos da ação, como o botão do mouse, ficam)
		for e in InputMap.action_get_events(a):
			if e is InputEventKey:
				InputMap.action_erase_event(a, e)
		var k := InputEventKey.new()
		k.physical_keycode = key_of(a) as Key
		InputMap.action_add_event(a, k)
	if TranslationServer.get_locale() != locale:
		TranslationServer.set_locale(locale)
	for bus in BUSES + FOLLOWS.keys():
		var v: float = volumes[FOLLOWS.get(bus, bus)]
		var i := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_db(i, linear_to_db(v))
		AudioServer.set_bus_mute(i, v <= 0.001)


func _load() -> void:
	var f := ConfigFile.new()
	if f.load(PATH) != OK:
		return
	locale = f.get_value("settings", "locale", locale)
	fullscreen = f.get_value("display", "fullscreen", fullscreen)
	colorblind = f.get_value("display", "colorblind", colorblind)
	for a: String in KEY_ACTIONS:
		if f.has_section_key("keys", a):
			keys[a] = int(f.get_value("keys", a))
	for bus in BUSES:
		volumes[bus] = f.get_value("volume", bus, volumes[bus])

