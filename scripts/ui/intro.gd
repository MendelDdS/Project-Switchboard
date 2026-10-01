class_name Intro
extends ColorRect
## Tela inicial do turno: qual noite é e o bilhete do supervisor.

signal start_pressed


func _ready() -> void:
	%Start.pressed.connect(func():
		visible = false
		start_pressed.emit())
	%Reset.pressed.connect(func():
		Progress.clear()
		get_tree().reload_current_scene())


func setup(n: int, night: Night, can_reset: bool) -> void:
	%Date.text = tr("Noite %d · %s · %s") % [n, tr(night.weekday), Main.fmt(0.0)]
	%Text.text = tr(night.note)
	%Reset.visible = can_reset
