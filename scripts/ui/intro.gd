class_name Intro
extends ColorRect
## Tela inicial do turno.

signal start_pressed


func _ready() -> void:
	%Start.pressed.connect(func():
		visible = false
		start_pressed.emit())
