@tool
class_name FoneSocket
extends Control
## Encaixe do FONE na prateleira da mesa comutadora, à frente do painel: o buraco onde o plug fica em pé. A mesa
## desenha o plug e o fio por cima e recebe os cliques aqui (por isso este nó e os containers acima dele ignoram o mouse).

func _ready() -> void:
	custom_minimum_size = Vector2(58, 32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## O buraco (a plaquinha com o nome, a mesa desenha: `Switchboard._draw_fone_tag`).
func _draw() -> void:
	Switchboard.draw_grommet(self, Vector2(Switchboard.FONE_HOLE_X, Switchboard.SHELF_HOLE_Y))

