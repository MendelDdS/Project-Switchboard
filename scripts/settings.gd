extends Node
## Configurações do jogador (autoload `Settings`), salvas em user://settings.cfg: idioma, volume de cada barramento,
## velocidade do texto e a tela (cheia ou janela; ampliação suave ou só por inteiro, que o `GameView` aplica). Os `set_*` valem na hora (prévia) mas só ficam salvos com `save()`; `snapshot()`/`restore()`
## permitem descartar. O menu de configurações (PauseMenu) usa os dois: Aplicar salva, Voltar restaura.
## `-- --lang=en` força um idioma nesta execução. Testes (`-s`) não leem nem gravam o arquivo do jogador.

signal changed

const PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "pt_BR"
const LOCALES := ["pt_BR", "en", "es"]
## Cada idioma escrito no próprio idioma (não se traduz).
const LOCALE_NAMES := {"pt_BR": "Português (Brasil)", "en": "English (US)", "es": "Español"}
const BUSES := ["Ambience", "Voices", "Effects"]
## Barramentos sem controle próprio, que seguem o volume de outro (o atrito do fio vai direto para o Master).
const FOLLOWS := {"Rub": "Effects"}
## Quanto cada letra demora, relativo ao normal: lenta, normal, rápida.
const TEXT_SPEEDS := [1.6, 1.0, 0.55]

var locale := DEFAULT_LOCALE
var volumes := {"Ambience": 1.0, "Voices": 1.0, "Effects": 1.0}   ## 0..1, linear
var text_speed := 1                                                 ## índice em TEXT_SPEEDS
var fullscreen := true                                              ## tela cheia (falso: janela)
var pixel_perfect := false                                          ## só ampliação inteira, com borda (falso: suave)
var _persist := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_args()
	# testes (`tests/runner.tscn -- --test=x`, ou um script com -s) não leem nem gravam o arquivo do jogador
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


func set_text_speed(i: int) -> void:
	text_speed = clampi(i, 0, TEXT_SPEEDS.size() - 1)
	_changed()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_changed()


func set_pixel_perfect(on: bool) -> void:
	pixel_perfect = on
	_changed()


## Multiplicador do tempo de cada letra das falas (conversa e rádio).
## A versão do jogo como ela aparece na tela inicial e na pausa ("v0.4.0 alpha"): o número do projeto
## (`application/config/version`, que as exportações usam; veja VERSOES.md) e a fase (`application/config/stage`;
## vazia na 1.0).
static func version_text() -> String:
	var stage := str(ProjectSettings.get_setting("application/config/stage", ""))
	return ("v%s %s" % [ProjectSettings.get_setting("application/config/version", ""), stage]).strip_edges()


func char_delay() -> float:
	return TEXT_SPEEDS[text_speed]


## Estado atual, para comparar ou restaurar depois.
func snapshot() -> Dictionary:
	return {"locale": locale, "volumes": volumes.duplicate(), "text_speed": text_speed, "fullscreen": fullscreen,
		"pixel_perfect": pixel_perfect}


func restore(s: Dictionary) -> void:
	locale = s["locale"]
	volumes = s["volumes"].duplicate()
	text_speed = s["text_speed"]
	fullscreen = s["fullscreen"]
	pixel_perfect = s["pixel_perfect"]
	_changed()


func save() -> void:
	if not _persist:
		return
	var f := ConfigFile.new()
	f.set_value("settings", "locale", locale)
	f.set_value("settings", "text_speed", text_speed)
	f.set_value("display", "fullscreen", fullscreen)
	f.set_value("display", "pixel_perfect", pixel_perfect)
	for bus in BUSES:
		f.set_value("volume", bus, volumes[bus])
	f.save(PATH)


func _changed() -> void:
	_apply()
	changed.emit()


func _apply() -> void:
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
	text_speed = f.get_value("settings", "text_speed", text_speed)
	fullscreen = f.get_value("display", "fullscreen", fullscreen)
	pixel_perfect = f.get_value("display", "pixel_perfect", pixel_perfect)
	for bus in BUSES:
		volumes[bus] = f.get_value("volume", bus, volumes[bus])

