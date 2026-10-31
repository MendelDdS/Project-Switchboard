@tool
class_name KeyCapStyle
extends StyleBox
## Tecla do console do telefone, numa chapa oliva de cantos quebrados (como o painel da mesa, sem parafusos): no alto,
## a etiqueta creme com o atalho (o rótulo
## `Key` do botão fica nela); embaixo, num poço escuro, a tecla em relevo, vista de cima e de frente: o tampo na cor
## dela e, em volta, a saia mais escura (só um fio dos lados, mais embaixo, a frente da tecla). Apertada, afunda: o
## tampo desce e a frente quase some. Apagada (desabilitada), a cor escurece. As margens de conteúdo põem o texto no
## tampo (na apertada, mais embaixo).

const SKIRT := 5.0   ## px da frente da tecla à mostra, solta
const SUNK := 2.0    ## apertada
const SIDE := 3.0    ## px da chapa de cada lado da etiqueta e do poço
const PLATE := Rect2(0, 6, 0, 14)   ## a etiqueta: y e altura (a largura vem da tecla)
const WELL_H := 45.0   ## a altura máxima do poço da tecla
const PLATE_TONES := [Pal.BOARD_METAL[5], Pal.BOARD_METAL[3], Pal.BOARD_METAL[1]]   ## a chapa oliva: luz, meio, sombra

@export var color := Color.WHITE
@export var pressed := false
@export var hover := false
@export var off := false
@export var tag := true   ## a etiqueta no alto (sem ela, a tecla ocupa a chapa toda: as do discador, `DialView`)


func _draw(to: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	# a chapa oliva, de cantos quebrados, com a luz no alto à esquerda
	_cut_rect(to, rect, Pal.BOARD_INSET)
	var bz := rect.grow(-1)
	_cut_rect(to, bz, PLATE_TONES[1])
	rs.canvas_item_add_rect(to, Rect2(bz.position.x + 1, bz.position.y, bz.size.x - 2, 1), PLATE_TONES[0])
	rs.canvas_item_add_rect(to, Rect2(bz.position.x, bz.position.y + 1, 1, bz.size.y - 2), PLATE_TONES[0].darkened(0.1))
	rs.canvas_item_add_rect(to, Rect2(bz.position.x + 1, bz.end.y - 1, bz.size.x - 2, 1), PLATE_TONES[2])
	# a etiqueta creme impressa, onde fica o atalho
	var plate := Rect2(rect.position.x + SIDE, rect.position.y + PLATE.position.y, rect.size.x - SIDE * 2.0, PLATE.size.y)
	if tag:
		_cut_rect(to, plate.grow(1), Pal.BOARD_INSET)
		_cut_rect(to, plate, Pal.BOARD_TAG)
		rs.canvas_item_add_rect(to, Rect2(plate.position.x + 1, plate.position.y, plate.size.x - 2, 1), Pal.BOARD_TAG.lightened(0.15))
	# o poço da tecla, embaixo da etiqueta (sem ela, na chapa toda)
	var room := Rect2(rect.position.x, plate.end.y + 6.0, rect.size.x, rect.end.y - plate.end.y - 12.0) if tag else rect.grow(-2)
	var wh := minf(room.size.y, WELL_H)   # baixa, no meio do espaço (o texto, pelas margens, fica no meio dela)
	var well := Rect2(rect.position.x + SIDE - 2.0, roundf(room.get_center().y - wh / 2.0), rect.size.x - (SIDE - 2.0) * 2.0, wh)
	rs.canvas_item_add_rect(to, well, Pal.BOARD_INSET)
	rs.canvas_item_add_rect(to, Rect2(well.position.x, well.end.y, well.size.x, 1), PLATE_TONES[0])   # a beira de baixo pega a luz
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
	rs.canvas_item_add_rect(to, Rect2(face.position, Vector2(face.size.x, 1)), c.lightened(0.15))   # luz no alto à esquerda, fraca: plástico fosco
	rs.canvas_item_add_rect(to, Rect2(face.position, Vector2(1, face.size.y)), c.lightened(0.08))
	rs.canvas_item_add_rect(to, Rect2(face.position.x, face.end.y - 1, face.size.x, 1), c.darkened(0.15))


## Um retângulo com um pixel tirado de cada canto (a quina arredondada do plástico).
static func _cut_rect(to: RID, r: Rect2, col: Color) -> void:
	RenderingServer.canvas_item_add_rect(to, Rect2(r.position.x + 1, r.position.y, r.size.x - 2, r.size.y), col)
	RenderingServer.canvas_item_add_rect(to, Rect2(r.position.x, r.position.y + 1, r.size.x, r.size.y - 2), col)
