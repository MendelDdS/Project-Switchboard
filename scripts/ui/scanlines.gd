@tool
extends Control
## Linhas de varredura sobre a tela inteira.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	for y in range(0, int(size.y), 3):
		draw_rect(Rect2(0, y, size.x, 1), Color(0, 0, 0, 0.08))
