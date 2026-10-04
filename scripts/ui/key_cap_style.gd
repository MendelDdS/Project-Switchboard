@tool
class_name KeyCapStyle
extends StyleBox
## Tecla do console do telefone, vista de cima e de frente: o tampo na cor dela e, em volta, a saia mais escura (só um
## fio dos lados, mais embaixo, a frente da tecla). Apertada, afunda: o tampo desce e a frente quase some. Apagada
## (desabilitada), a cor escurece. As margens de conteúdo põem o texto no tampo (na apertada, mais embaixo).

const SKIRT := 6.0   ## px da frente da tecla à mostra, solta
const SUNK := 2.0    ## apertada

@export var color := Color.WHITE
@export var pressed := false
@export var hover := false
@export var off := false


func _draw(to: RID, rect: Rect2) -> void:
	var c := color.darkened(0.55) if off else color.lightened(0.12) if hover else color
	var top := rect.position.y + (SKIRT - SUNK if pressed else 0.0)
	var front := SUNK if pressed else SKIRT
	var key := Rect2(rect.position.x, top, rect.size.x, rect.end.y - top)
	var rs := RenderingServer
	rs.canvas_item_add_rect(to, key, Color.BLACK)
	rs.canvas_item_add_rect(to, key.grow(-1), c.darkened(0.5))   # a saia
	var face := Rect2(key.position.x + 3, key.position.y + 1, key.size.x - 6, key.size.y - 2 - front)
	rs.canvas_item_add_rect(to, face, c)   # o tampo
	rs.canvas_item_add_rect(to, Rect2(face.position, Vector2(face.size.x, 1)), c.lightened(0.3))   # luz no alto à esquerda
	rs.canvas_item_add_rect(to, Rect2(face.position, Vector2(1, face.size.y)), c.lightened(0.15))
	rs.canvas_item_add_rect(to, Rect2(face.position.x, face.end.y - 1, face.size.x, 1), c.darkened(0.15))
