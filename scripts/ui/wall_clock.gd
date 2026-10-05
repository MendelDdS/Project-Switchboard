class_name WallClock
extends Control
## O relógio da sala, pendurado na parede acima da mesa comutadora: aro de madeira, mostrador creme com as marcas,
## ponteiros na hora do jogo (`minutes`, minutos do dia; o Main atualiza) e a sombra na parede. É o único relógio da
## tela (o painel digital saiu: destoava da época e repetia a hora); fica à esquerda, onde o papel das ferramentas não
## o cobre.

const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]
const INK := Color("1a1610")
const HAND := Color("8e2a22")   ## o ponteiro dos minutos: outra cor, para não confundir com o das horas

var minutes := 18 * 60.0:
	set(v):
		if v != minutes:
			minutes = v
			queue_redraw()


func _draw() -> void:
	var c := (size / 2.0).round()
	var r := floorf(minf(size.x, size.y) / 2.0) - 2.0
	draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.35))   # a sombra na parede
	draw_circle(c, r, Color.BLACK)
	draw_circle(c, r - 1, WOOD[1])   # o aro
	draw_arc(c, r - 2, PI * 0.9, PI * 1.6, 12, WOOD[0], 1.0)   # a luz no alto à esquerda
	draw_circle(c, r - 4, Color.BLACK)
	draw_circle(c, r - 5, Color("efe4c4"))   # o mostrador, claro (a sala é escura)
	draw_circle(c + Vector2(1, 1), r - 7, Color("e6d9b4"))
	for i in 12:   # as marcas das horas, grossas e compridas nas de 3 em 3 (nesse tamanho, números batiam nos ponteiros)
		var a := TAU * i / 12.0
		var d := Vector2(sin(a), -cos(a))
		if i == 0:   # o 12 em marca dupla: diz para onde é o alto mesmo com os ponteiros juntos
			for o in [-2.0, 2.0]:
				draw_line(c + Vector2(o, -(r - 7)), c + Vector2(o, -(r - 13)), INK, 2.0)
			continue
		draw_line(c + d * (r - 7), c + d * (r - (12 if i % 3 == 0 else 9)), INK, 3.0 if i % 3 == 0 else 1.0)
	var hr := fmod(minutes / 60.0, 12.0) / 12.0 * TAU
	var mn := fmod(minutes, 60.0) / 60.0 * TAU
	_hand(c, hr, r * 0.46, 4.0, INK)          # as horas: curto e largo, preto
	_hand(c, mn, r * 0.78, 2.0, HAND)         # os minutos: comprido e fino, vermelho-escuro
	draw_circle(c, 3.0, INK)
	draw_circle(c, 1.5, HAND)


## Um ponteiro saindo do centro `c` no ângulo `a` (0 = 12 h), com um rabicho do outro lado (o contrapeso).
func _hand(c: Vector2, a: float, length: float, width: float, col: Color) -> void:
	var d := Vector2(sin(a), -cos(a))
	draw_line(c - d * 4.0, c + d * length, col, width)
	draw_line(c + d * (length - 3.0), c + d * length, col, maxf(1.0, width - 1.0))   # a ponta afina
