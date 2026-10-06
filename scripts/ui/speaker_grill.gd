class_name SpeakerGrill
extends Control
## O alto-falante do rádio: uma chapa perfurada na altura toda do bloco, com os furos em fileiras desencontradas
## (cada furo escuro com a beira de baixo pegando a luz) e a moldura com a luz no alto à esquerda.

const PLATE := Color("2a2620")
const HOLE := Color("0b0907")
const PITCH := 3   # px entre dois furos


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color.BLACK)
	draw_rect(r.grow(-1), PLATE)
	draw_rect(Rect2(1, 1, size.x - 2, 1), PLATE.lightened(0.2))
	draw_rect(Rect2(1, 1, 1, size.y - 2), PLATE.lightened(0.1))
	draw_rect(Rect2(1, size.y - 2, size.x - 2, 1), PLATE.darkened(0.4))
	for row in range(0, int((size.y - 8) / PITCH) + 1):
		var y := 4 + row * PITCH
		for x in range(4 + (row % 2) * 2, int(size.x) - 4, PITCH + 1):
			draw_rect(Rect2(x, y, 1, 1), HOLE)
			draw_rect(Rect2(x, y + 1, 1, 1), PLATE.lightened(0.15))
