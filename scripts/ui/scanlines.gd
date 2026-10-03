@tool
extends Control
## Linhas de varredura sobre a tela inteira.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(queue_redraw)


## Em pixels reais da tela (com a janela menor que 1280×720, linhas a cada 3 px do jogo cortavam as letras).
func _draw() -> void:
	var px := 1.0 / maxf(0.01, get_viewport().get_final_transform().get_scale().y)
	var y := 0.0
	while y < size.y:
		draw_rect(Rect2(0, y, size.x, px), Color(0, 0, 0, 0.08))
		y += 3.0 * px
