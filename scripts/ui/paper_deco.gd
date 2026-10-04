class_name PaperDeco
extends Control
## O que faz o papel da ferramenta aberta parecer o objeto dela (`kind`, o id da ferramenta), desenhado por cima, na
## faixa da margem do papel: a lista é um livro (capa amarela como a da mesa, a sombra da lombada no meio), o mapa é
## uma folha dobrada (os vincos), o caderno é um livro-ata (encadernação de pano e cantoneiras de couro), o registro
## fica preso na prancheta (a tábua em volta e o prendedor) e o jornal tem o vinco do meio.

var kind := "":
	set(v):
		kind = v
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	match kind:
		"lista":
			_frame(r, 7.0, Color("b48c1c"))
			var cx := floorf(size.x / 2.0)
			for i in 6:   # a lombada: a sombra das páginas entrando no miolo
				draw_rect(Rect2(cx - 3 + i, 7, 1, size.y - 14), Color(0, 0, 0, 0.16 - absf(i - 2.5) * 0.04))
		"despacho":
			for k in [1, 2]:
				_crease(Vector2(size.x * k / 3.0, 0), Vector2(size.x * k / 3.0, size.y))
			_crease(Vector2(0, size.y / 2.0), Vector2(size.x, size.y / 2.0))
		"caderno":
			_frame(r, 6.0, Color("2e4a3a"))
			for c in [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]:   # as cantoneiras
				var d := Vector2(signf(size.x / 2.0 - c.x), signf(size.y / 2.0 - c.y)) * 22.0
				var tri := PackedVector2Array([c, c + Vector2(d.x, 0), c + Vector2(0, d.y)])
				draw_colored_polygon(tri, Color("6e2a1c"))
				draw_line(c + Vector2(d.x, 0), c + Vector2(0, d.y), Color("8e3a26"), 1.0)
		"registro":
			_frame(r, 10.0, Color("7a5230"))
			var cx := floorf(size.x / 2.0)
			var clip := Rect2(cx - 34, -4, 68, 18)
			draw_rect(Rect2(clip.position + Vector2(2, 3), clip.size), Color(0, 0, 0, 0.3))
			draw_rect(clip.grow(1), Color.BLACK)
			draw_rect(clip, Color("8e897c"))
			draw_rect(Rect2(clip.position, Vector2(clip.size.x, 3)), Color("d6d1c3"))
			draw_rect(Rect2(clip.position.x, clip.end.y - 2, clip.size.x, 2), Color("45413a"))
			draw_rect(Rect2(cx - 14, clip.position.y + 6, 28, 6), Color("45413a"))   # a fenda da mola
			for x in [clip.position.x + 7, clip.end.x - 7]:
				draw_circle(Vector2(x, clip.get_center().y), 2.5, Color("d6d1c3"))
		"jornal":
			_crease(Vector2(0, size.y / 2.0), Vector2(size.x, size.y / 2.0))


## Uma borda de `w` px na cor `col` em volta do papel, com a luz por dentro no alto e a sombra embaixo.
func _frame(r: Rect2, w: float, col: Color) -> void:
	draw_rect(Rect2(r.position, Vector2(r.size.x, w)), col)
	draw_rect(Rect2(r.position.x, r.end.y - w, r.size.x, w), col.darkened(0.2))
	draw_rect(Rect2(r.position, Vector2(w, r.size.y)), col.darkened(0.08))
	draw_rect(Rect2(r.end.x - w, r.position.y, w, r.size.y), col.darkened(0.15))
	draw_rect(r, Color.BLACK, false, 2.0)
	draw_rect(r.grow(-w), Color(0, 0, 0, 0.5), false, 1.0)
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 1)), col.lightened(0.25))


## Um vinco de dobra: uma linha de sombra e, ao lado, uma de luz.
func _crease(a: Vector2, b: Vector2) -> void:
	var n := (b - a).orthogonal().normalized()
	draw_line(a, b, Color(0, 0, 0, 0.14), 1.0)
	draw_line(a + n, b + n, Color(1, 1, 1, 0.18), 1.0)
