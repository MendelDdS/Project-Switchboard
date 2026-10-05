@tool
class_name FoneSocket
extends Control
## Encaixe do FONE na prateleira da mesa comutadora, à frente do painel: o buraco onde o plug fica em pé e, embaixo,
## o nome gravado na madeira. A mesa desenha o plug e o fio por cima e recebe os cliques aqui (por isso este nó e os
## containers acima dele ignoram o mouse).

func _ready() -> void:
	custom_minimum_size = Vector2(100, 16)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	Switchboard.draw_grommet(self, Vector2(Switchboard.FONE_HOLE_X, Switchboard.SHELF_HOLE_Y))
	Switchboard.engrave(self, Vector2(Switchboard.FONE_HOLE_X, size.y), T.text(T.Key.FONE_LABEL))


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
