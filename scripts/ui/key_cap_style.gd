@tool
class_name KeyCapStyle
extends StyleBox
## Tecla do console do telefone, numa chapa de metal parafusada: no alto, a etiqueta de latão com o atalho (o rótulo
## `Key` do botão fica nela); embaixo, num poço escuro, a tecla em relevo, vista de cima e de frente: o tampo na cor
## dela e, em volta, a saia mais escura (só um fio dos lados, mais embaixo, a frente da tecla). Apertada, afunda: o
## tampo desce e a frente quase some. Apagada (desabilitada), a cor escurece. As margens de conteúdo põem o texto no
## tampo (na apertada, mais embaixo).

const SKIRT := 5.0   ## px da frente da tecla à mostra, solta
const SUNK := 2.0    ## apertada
const SIDE := 3.0    ## px da chapa de cada lado da etiqueta e do poço
const PLATE := Rect2(0, 6, 0, 14)   ## a etiqueta: y e altura (a largura vem da tecla)
const WELL_H := 45.0   ## a altura máxima do poço da tecla
const METAL := [Pal.NICKEL[1], Pal.NICKEL[2], Pal.NICKEL[3]]   ## a chapa niquelada: luz, meio, sombra
const BRASS := [Pal.BRASS_PLATE[6], Pal.BRASS_PLATE[4], Pal.BRASS_PLATE[2], Pal.BRASS_PLATE[1]]   ## latão: luz, meio, sombra, beira

@export var color := Color.WHITE
@export var pressed := false
@export var hover := false
@export var off := false


func _draw(to: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	# a chapa de metal, com a luz no alto à esquerda e um parafuso em cada canto
	rs.canvas_item_add_rect(to, rect, Color.BLACK)
	var bz := rect.grow(-1)
	rs.canvas_item_add_rect(to, bz, METAL[1].darkened(0.5))
	rs.canvas_item_add_rect(to, Rect2(bz.position, Vector2(bz.size.x, 1)), METAL[1].darkened(0.2))
	rs.canvas_item_add_rect(to, Rect2(bz.position, Vector2(1, bz.size.y)), METAL[1].darkened(0.3))
	rs.canvas_item_add_rect(to, Rect2(bz.position.x, bz.end.y - 1, bz.size.x, 1), METAL[2].darkened(0.3))
	for c in [bz.position + Vector2(2, 2), Vector2(bz.end.x - 4, bz.position.y + 2), Vector2(bz.position.x + 2, bz.end.y - 4), bz.end - Vector2(4, 4)]:
		rs.canvas_item_add_rect(to, Rect2(c, Vector2(2, 2)), METAL[2])
		rs.canvas_item_add_rect(to, Rect2(c, Vector2(1, 1)), METAL[0])
	# a etiqueta de latão, onde fica o atalho
	var plate := Rect2(rect.position.x + SIDE, rect.position.y + PLATE.position.y, rect.size.x - SIDE * 2.0, PLATE.size.y)
	rs.canvas_item_add_rect(to, plate.grow(1), BRASS[3])
	rs.canvas_item_add_rect(to, plate, BRASS[1])
	rs.canvas_item_add_rect(to, Rect2(plate.position, Vector2(plate.size.x, 1)), BRASS[0])
	rs.canvas_item_add_rect(to, Rect2(plate.position.x, plate.end.y - 1, plate.size.x, 1), BRASS[2])
	# o poço da tecla
	var room := Rect2(rect.position.x, plate.end.y + 6.0, rect.size.x, rect.end.y - plate.end.y - 12.0)   # embaixo da etiqueta
	var wh := minf(room.size.y, WELL_H)   # baixa, no meio do espaço (o texto, pelas margens, fica no meio dela)
	var well := Rect2(rect.position.x + SIDE - 2.0, roundf(room.get_center().y - wh / 2.0), rect.size.x - (SIDE - 2.0) * 2.0, wh)
	rs.canvas_item_add_rect(to, well, Pal.KEY_WELL)
	rs.canvas_item_add_rect(to, Rect2(well.position.x, well.end.y, well.size.x, 1), METAL[0].darkened(0.2))   # a beira de baixo pega a luz
	# a tecla, dentro dele
	var area := well.grow(-2)
	var c := color.darkened(0.55) if off else color.lightened(0.12) if hover else color
	var top := area.position.y + (SKIRT - SUNK if pressed else 0.0)
	var front := SUNK if pressed else SKIRT
	var key := Rect2(area.position.x, top, area.size.x, area.end.y - top)
	rs.canvas_item_add_rect(to, key, Color.BLACK)
	rs.canvas_item_add_rect(to, key.grow(-1), c.darkened(0.5))   # a saia
	var face := Rect2(key.position.x + 2, key.position.y + 1, key.size.x - 4, key.size.y - 2 - front)
	rs.canvas_item_add_rect(to, face, c)   # o tampo
	rs.canvas_item_add_rect(to, Rect2(face.position, Vector2(face.size.x, 1)), c.lightened(0.3))   # luz no alto à esquerda
	rs.canvas_item_add_rect(to, Rect2(face.position, Vector2(1, face.size.y)), c.lightened(0.15))
	rs.canvas_item_add_rect(to, Rect2(face.position.x, face.end.y - 1, face.size.x, 1), c.darkened(0.15))
