class_name Ending
extends ColorRect
## Tela final: escurece a mesa e pergunta se você atenderia novamente.

@onready var _title: Label = %Title
@onready var _question: Label = %Question
@onready var _restart: Button = %Restart


func _ready() -> void:
	color.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in [_title, _question, _restart]:
		n.modulate.a = 0.0
	_restart.visible = false
	_restart.pressed.connect(func(): get_tree().reload_current_scene())


func play() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	create_tween().tween_property(self, "color:a", 1.0, 3.0)
	await get_tree().create_timer(3.4).timeout
	create_tween().tween_property(_title, "modulate:a", 1.0, 2.0)
	await get_tree().create_timer(2.6).timeout
	create_tween().tween_property(_question, "modulate:a", 1.0, 2.5)
	await get_tree().create_timer(2.4).timeout
	_restart.visible = true
	create_tween().tween_property(_restart, "modulate:a", 1.0, 1.5)
