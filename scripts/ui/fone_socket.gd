@tool
class_name FoneSocket
extends Control
## Encaixe do FONE no telefone. A mesa desenha o plug e o fio por cima e recebe os cliques aqui
## (por isso este nó e os containers acima dele ignoram o mouse).

func _ready() -> void:
	custom_minimum_size = Vector2(76, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("1b1812"))
	draw_rect(Rect2(10, 26, 16, 12), Color("050403"))
	# no editor (@tool) as fontes de Pal ainda não foram carregadas
	var f: Font = Pal.mono if Pal.mono != null else get_theme_default_font()
	draw_string(f, Vector2(34, 28), tr("FONE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.BRASS)
