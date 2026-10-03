@tool
class_name FoneSocket
extends Control
## Encaixe do FONE no telefone. A mesa desenha o plug e o fio por cima e recebe os cliques aqui
## (por isso este nó e os containers acima dele ignoram o mouse).

func _ready() -> void:
	custom_minimum_size = Vector2(76, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# chapa com chanfro (luz em cima à esquerda), como a mesa
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Pal.PANEL)
	draw_rect(Rect2(1, 1, size.x - 2, 1), Pal.PANEL_HI)
	draw_rect(Rect2(1, 1, 1, size.y - 2), Pal.PANEL_HI)
	draw_rect(Rect2(1, size.y - 2, size.x - 2, 1), Pal.PANEL_LO)
	draw_rect(Rect2(size.x - 2, 1, 1, size.y - 2), Pal.PANEL_LO)
	# o berço onde o plug fica em pé: rebaixo escuro com a borda de latão, sombra no alto (é fundo)
	var cradle := Rect2(10, 3, 16, size.y - 6)
	draw_rect(cradle.grow(1), Color("7a6230"))
	draw_rect(Rect2(cradle.position - Vector2.ONE, Vector2(cradle.size.x + 2, 1)), Color("c4a35a"))
	draw_rect(cradle, Color("050403"))
	draw_rect(Rect2(cradle.position, Vector2(cradle.size.x, 2)), Pal.PANEL_LO)
	for c in [Vector2(size.x - 6, 6), Vector2(size.x - 6, size.y - 6)]:   # parafusos
		draw_circle(c, 2.5, Pal.PANEL_LO)
		draw_circle(c - Vector2(0.4, 0.4), 1.6, Color("8e897c"))
		draw_line(c - Vector2(1.2, 0), c + Vector2(1.2, 0), Pal.PANEL_LO, 1.0)
	# no editor (@tool) as fontes de Pal ainda não foram carregadas
	var f: Font = Pal.ui if Pal.ui != null else get_theme_default_font()
	# a palavra muda com o idioma (FONE, HEADSET, AURICULAR): o maior tamanho em que a fonte fica nítida e cabe
	var label := T.text(T.Key.FONE_LABEL)
	var fs := 22 if f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x <= size.x - 38 else 11
	draw_string(f, Vector2(34, 28), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.BRASS)


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
