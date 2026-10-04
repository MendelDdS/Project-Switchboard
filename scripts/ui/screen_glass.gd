class_name ScreenGlass
extends Control
## O vidro de uma tela embutida no console (a da conversa): um reflexo na diagonal sempre e, desligada (`off`, sem
## ligação no painel), o vidro escuro, como uma tela apagada em vez de uma caixa vazia.

var off := true:
	set(v):
		off = v
		queue_redraw()


func _draw() -> void:
	if off:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var x := size.x * 0.62
	draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 70, 0), Vector2(x + 20, size.y), Vector2(x - 50, size.y)]),
		Color(1, 1, 1, 0.035 if off else 0.02))
