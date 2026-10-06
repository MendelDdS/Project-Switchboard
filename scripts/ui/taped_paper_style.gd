@tool
class_name TapedPaperStyle
extends StyleBox
## Um papel preso com fita: a folha creme com a beira um pouco mais escura, a sombra na parede (embaixo à direita) e
## dois pedaços de fita translúcida nos cantos de cima, passando da beira. Para bilhetes da sala (a dica do manual na
## parede, o horário do turno colado acima da mesa comutadora), no lugar de placas e de texto solto.

@export var paper := Color(0.9, 0.86, 0.74)
@export var tape := Color(0.93, 0.9, 0.78, 0.55)


func _draw(to: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	rs.canvas_item_add_rect(to, Rect2(rect.position + Vector2(2, 3), rect.size), Color(0, 0, 0, 0.35))   # a sombra
	rs.canvas_item_add_rect(to, rect, paper.darkened(0.3))   # a beira
	rs.canvas_item_add_rect(to, rect.grow(-1), paper)
	rs.canvas_item_add_rect(to, Rect2(rect.position.x + 1, rect.end.y - 2, rect.size.x - 2, 1), paper.darkened(0.08))   # a folha curva embaixo
	for x in [rect.position.x - 3.0, rect.end.x - 11.0]:   # a fita
		var t := Rect2(x, rect.position.y - 2.0, 14.0, 6.0)
		rs.canvas_item_add_rect(to, t, tape)
		rs.canvas_item_add_rect(to, Rect2(t.position, Vector2(t.size.x, 1)), Color(1, 1, 1, 0.25))
