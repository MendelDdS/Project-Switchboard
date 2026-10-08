class_name Intro
extends ColorRect
## Tela inicial do turno: qual noite é e o bilhete do supervisor.

signal start_pressed
signal settings_pressed

var _n := 0
var _night: Night


func _ready() -> void:
	$Version.text = Settings.version_text()
	%Start.pressed.connect(func():
		visible = false
		start_pressed.emit())
	%Settings.pressed.connect(settings_pressed.emit)
	%Reset.pressed.connect(func():
		Progress.clear()
		get_tree().reload_current_scene())


func setup(n: int, night: Night, can_reset: bool) -> void:
	_n = n
	_night = night
	%Reset.visible = can_reset
	_texts()


## O idioma pode mudar nas configurações com esta tela aberta.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _night != null:
		_texts()


func _texts() -> void:
	var night := _night
	var n := _n
	%Date.text = T.text(T.Key.INTRO_NIGHT) % [n, GameData.date_text(n), Main.fmt(0.0)]
	%Text.text = tr(night.note)
