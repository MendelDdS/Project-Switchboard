@tool
class_name Bevel
extends MarginContainer
## Painel com borda chanfrada em pixel. Os filhos ficam dentro das margens (constantes margin_* do nó).

@export var fill := Pal.PANEL:
	set(v):
		fill = v
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Pal.EDGE)
	draw_rect(Rect2(3, 3, w - 6, h - 6), fill)
	draw_rect(Rect2(3, 3, w - 6, 3), Pal.PANEL_HI)
	draw_rect(Rect2(3, 3, 3, h - 6), Pal.PANEL_HI)
	draw_rect(Rect2(3, h - 6, w - 6, 3), Pal.PANEL_LO)
	draw_rect(Rect2(w - 6, 3, 3, h - 6), Pal.PANEL_LO)
