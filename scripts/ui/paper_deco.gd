class_name PaperDeco
extends Control
## O que faz o papel da ferramenta aberta parecer o objeto dela na mesa (`kind`, o id da ferramenta), desenhado por
## cima, na faixa da margem do papel e nos materiais do objeto (`Pal`): a lista é um livro (a capa de papelão mostarda
## com o grão e o friso, como a da mesa, e a sombra da lombada), o caderno é o bloco de fichas de ocorrência (a fita de
## pano da colagem no alto, a beira das folhas de baixo e o papelão em volta), com as tiras dos registros pendentes
## saindo de cima (`pending`), o registro fica preso na prancheta (a tábua, o prendedor
## niquelado e o cabeçalho datilografado com o fio vermelho, como as folhas da mesa), o jornal tem o vinco do meio e o
## despacho é a unidade de despacho de perto (a moldura do vidro e a base com as máquinas são do `CardMachines`, por baixo
## do cartão, que pode passar por cima delas). Por cima de tudo, a luz da luminária (`light`, `_draw_light`).

const COVER := 7     ## a largura da capa em volta do papel, na lista e no bloco de fichas (px)
const BOARD_W := 10  ## a da tábua da prancheta
const HEAD_Y := 34   ## o fio vermelho do cabeçalho do registro (o texto do `CallLog` começa abaixo dele, `CallLog.HEAD`)
const CLIP := Vector2i(76, 24)   ## o prendedor da prancheta
## A luz da luminária no papel: ela fica no alto do meio da tela (fração da tela), clareia um pouco o canto perto dela
## e escurece o longe, liso; apagando (piscando), o papel todo escurece junto.
const LAMP := Vector2(0.5, -0.4)
const LIGHT_NEAR := Color(1.0, 0.86, 0.6, 0.06)
const LIGHT_FAR := Color(0.02, 0.02, 0.05, 0.13)
const LIGHT_OFF := 0.35   ## o tanto que escurece com a luminária apagada

var kind := "":
	set(v):
		kind = v
		queue_redraw()
var pending := 0:   ## registros esperando no bloco de fichas: uma tira de papel saindo de cima dele por registro (até seis)
	set(v):
		pending = v
		queue_redraw()
var light := 1.0:   ## a luz da luminária agora (0 a 1: pisca com ela)
	set(v):
		if absf(v - light) > 0.01:
			light = v
			queue_redraw()

static var _skins := {}   # [kind, tamanho] -> a capa ou a tábua em volta do papel


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	var sz := Vector2i(size)
	if sz.x < CLIP.x + BOARD_W * 2 or sz.y < BOARD_W * 4:   # (o papel ainda sem tamanho)
		return
	match kind:
		Tools.DIRECTORY:
			draw_texture(_skin(kind, sz), Vector2.ZERO)
			var cx := floorf((size.x - PhoneBook.TAB_W) / 2.0)   # o meio do livro (as abas ficam à direita dele)
			for i in 6:   # a lombada: a sombra das páginas entrando no miolo
				draw_rect(Rect2(cx - 3 + i, COVER, 1, size.y - COVER * 2), Color(0, 0, 0, 0.16 - absf(i - 2.5) * 0.04))
		Tools.LOGBOOK:
			draw_texture(_skin(kind, sz), Vector2.ZERO)
			for i in mini(pending, 6):   # as tiras, saindo de baixo do bloco, por cima da fita (como no da mesa)
				var x := floorf(size.x * 0.56) + i * 26.0
				var col: Color = Pal.PENDING[i % 2]
				var h := COVER + 12.0 + (i * 5) % 4
				draw_rect(Rect2(x + 1, h, 12, 1), Color(0, 0, 0, 0.25))   # onde ela entra no papel
				draw_rect(Rect2(x, 0, 12, h), col)
				draw_rect(Rect2(x + 11, 0, 1, h), col.darkened(0.2))   # o lado na sombra
				draw_rect(Rect2(x + 3, 3, 6, 2), Pal.FORM_RED)
		Tools.CALL_LOG:
			draw_texture(_skin(kind, sz), Vector2.ZERO)
			var x0 := BOARD_W + 12.0
			var x1 := size.x - BOARD_W - 12.0
			draw_string(Pal.mono, Vector2(x0, HEAD_Y - 6), T.text(T.Key.TAB_CALL_LOG).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
				Pal.INK_SOFT)
			draw_rect(Rect2(x0, HEAD_Y, x1 - x0, 2), Pal.FORM_RED)   # o fio vermelho, duplo
			draw_rect(Rect2(x0, HEAD_Y + 3, x1 - x0, 1), Pal.FORM_RED)
			var at := Vector2(floorf((size.x - CLIP.x) / 2.0), 1)
			draw_texture(_skin("prendedor", CLIP), at + Vector2(2, 3), Color(0, 0, 0, 0.35))   # a sombra dele na folha
			draw_texture(_skin("prendedor", CLIP), at)
		Tools.NEWS:
			crease(self, Vector2(0, size.y / 2.0), Vector2(size.x, size.y / 2.0))
		Tools.LETTER:   # dobrada em três para caber no envelope
			for f in [1.0 / 3.0, 2.0 / 3.0]:
				crease(self, Vector2(0, roundf(size.y * f)), Vector2(size.x, roundf(size.y * f)))
	_draw_light()


## A luz da luminária por cima do papel, lisa: uma grade de quadrados com a cor nos cantos, do claro (perto dela) ao
## escuro (longe), e mais escuro com ela apagada.
func _draw_light() -> void:
	var lamp := get_global_transform().affine_inverse() * (get_viewport_rect().size * LAMP)
	var near := lamp.distance_to(Vector2.ZERO)
	var far := lamp.distance_to(size)
	var dark := (1.0 - light) * LIGHT_OFF
	var tint := func(p: Vector2) -> Color:
		var c := LIGHT_NEAR.lerp(LIGHT_FAR, clampf((lamp.distance_to(p) - near) / maxf(1.0, far - near), 0.0, 1.0))
		return c if dark == 0.0 else Color(LIGHT_FAR, c.a + dark)
	var n := Vector2i(6, 4)
	var step := size / Vector2(n)
	for j in n.y:
		for i in n.x:
			var p := Vector2(i, j) * step
			var q := PackedVector2Array([p, p + Vector2(step.x, 0), p + step, p + Vector2(0, step.y)])
			var cols := PackedColorArray()
			for v in q:
				cols.append(tint.call(v))
			draw_primitive(q, cols, PackedVector2Array())   # (primitivos seguidos são uma chamada de desenho só; polígonos, uma cada)


## A capa (ou a tábua, ou o prendedor) pixel a pixel, guardada por tamanho.
static func _skin(k: String, sz: Vector2i) -> ImageTexture:
	var key := [k, sz]
	if not _skins.has(key):
		if _skins.size() > 8:
			_skins.clear()
		_skins[key] = ImageTexture.create_from_image(_clip(sz) if k == "prendedor" else _cover(k, sz))
	return _skins[key]


## A capa em volta do papel, no material do objeto da mesa: o grão dele, a beira na luz no alto e à esquerda e na
## sombra embaixo e à direita, a sombra do papel por dentro e os cantos (gastos no papelão da lista, cortados na
## tábua). A lista tem o friso em baixo-relevo, como a capa da mesa; o bloco de fichas, a fita da colagem no alto e,
## dos lados e embaixo, a beira das folhas de baixo, entre a de cima e o papelão.
static func _cover(k: String, sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var w := BOARD_W if k == Tools.CALL_LOG else COVER
	var c: Color = {Tools.DIRECTORY: Pal.BOOK.darkened(0.15), Tools.LOGBOOK: Pal.PAD_BACK[1], Tools.CALL_LOG: Pal.BOARD[1]}[k]
	var hi: Color = {Tools.DIRECTORY: c.lightened(0.22), Tools.LOGBOOK: Pal.PAD_BACK[0], Tools.CALL_LOG: Pal.BOARD[0]}[k]
	var lo: Color = {Tools.DIRECTORY: c.darkened(0.25), Tools.LOGBOOK: Pal.PAD_BACK[2], Tools.CALL_LOG: Pal.BOARD[2]}[k]
	for y in sz.y:
		var band := y < w or y >= sz.y - w
		for x in (range(sz.x) if band else range(w) + range(sz.x - w, sz.x)):
			img.set_pixel(x, y, _grain(k, c, x, y))
	var fr := func(x: int, y: int, ww: int, hh: int, col: Color) -> void:
		img.fill_rect(Rect2i(x, y, ww, hh), col)
	if k == Tools.DIRECTORY:   # o friso: a sombra em cima e à esquerda, a luz embaixo e à direita
		fr.call(2, 2, sz.x - 4, 1, c.darkened(0.16))
		fr.call(2, 2, 1, sz.y - 4, c.darkened(0.16))
		fr.call(2, sz.y - 3, sz.x - 4, 1, c.lightened(0.1))
		fr.call(sz.x - 3, 2, 1, sz.y - 4, c.lightened(0.1))
	fr.call(0, 0, sz.x, 1, hi)
	fr.call(0, 0, 1, sz.y, hi.lerp(c, 0.5))
	fr.call(sz.x - 1, 0, 1, sz.y, lo)
	fr.call(0, sz.y - 1, sz.x, 1, lo)
	fr.call(w - 1, w - 1, sz.x - w * 2 + 2, 1, c.darkened(0.3))   # a beira do papel, em cima e à esquerda (a capa sobe até ele)...
	fr.call(w - 1, w - 1, 1, sz.y - w * 2 + 2, c.darkened(0.3))
	fr.call(w - 1, sz.y - w, sz.x - w * 2 + 2, 1, c.lightened(0.12))   # ...e a luz na de baixo e na da direita
	fr.call(sz.x - w, w - 1, 1, sz.y - w * 2 + 2, c.lightened(0.12))
	if k == Tools.LOGBOOK:
		for i in w - 2:   # a beira da de cima e a das folhas de baixo, uma por pixel, mais escuras para fora (o papelão fica nos 2 de fora)
			var sheet := Pal.NOTE_PAGE.darkened(0.3 if i == 0 else 0.06 + 0.07 * i)
			fr.call(w - 1 - i, w - 1, 1, sz.y - w * 2 + 2 + i, sheet)
			fr.call(sz.x - w + i, w - 1, 1, sz.y - w * 2 + 2 + i, sheet)
			fr.call(w - 1 - i, sz.y - w + i, sz.x - w * 2 + 2 + i * 2, 1, sheet)
		for y in w:   # a fita de pano, dobrada sobre a colagem: a beira de cima na luz, a trama e a de baixo na sombra
			for x in sz.x:
				var t: Color = Pal.PAD_TAPE[0] if y == 0 else (Pal.PAD_TAPE[2] if y == w - 1 else Pal.PAD_TAPE[1])
				img.set_pixel(x, y, t.lightened(0.05) if y > 0 and y < w - 1 and (x + y * 2) % 5 == 0 else t)
		fr.call(w - 1, w, sz.x - w * 2 + 2, 1, Color(0, 0, 0, 0.18))   # a sombra da fita na folha
	for p: Vector2i in [Vector2i(0, 0), Vector2i(sz.x - 1, 0), Vector2i(0, sz.y - 1), sz - Vector2i.ONE]:
		var d := Vector2i(1 if p.x == 0 else -1, 1 if p.y == 0 else -1)
		if k == Tools.CALL_LOG:   # o canto cortado
			img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		elif k == Tools.DIRECTORY:   # gasto: mais claro
			for i in 3:
				for j in 3 - i:
					img.set_pixel(p.x + d.x * i, p.y + d.y * j, c.lightened(0.3))
	return img


## O grão de cada material, sempre o mesmo em cada ponto: o papelão (o da capa da lista e o de trás do bloco de
## fichas) com pontos mais escuros e mais claros e a tábua, quase lisa, com fibras ao comprido.
static func _grain(k: String, c: Color, x: int, y: int) -> Color:
	match k:
		Tools.DIRECTORY, Tools.LOGBOOK:
			var g := (x * 73 + y * 151 + x * y * 7) % 97
			return c.darkened(0.07) if g < 6 else (c.lightened(0.05) if g > 92 else c)
		_:
			var g := (y * 37 + (x / 9) * 11 + x % 3) % 53
			return c.darkened(0.06) if g < 4 else c


## O prendedor da prancheta, de pé na beira de cima, no níquel da mesa (o da prancheta da sala,
## de frente): a alavanca em arco por cima e o corpo com a luz no alto, a sombra embaixo e os rebites nas pontas.
static func _clip(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var edge := Color("2a2620")
	var top := sz.y / 2 - 2   # onde o corpo começa
	for y in top:   # a alavanca: um arco de 3 px, abrindo para baixo
		var inset := 12 - (y * 4) / maxi(1, top)   # as pernas descem abrindo
		var x0 := inset
		var x1 := sz.x - 1 - inset
		img.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), edge)
		if y == 0:
			continue
		var inner := y > 3
		var shade: Color = Pal.NICKEL[1] if y == 1 else Pal.NICKEL[2]
		if inner:   # as pernas: luz na da esquerda, sombra na da direita
			img.fill_rect(Rect2i(x0 + 1, y, 2, 1), Pal.NICKEL[1])
			img.fill_rect(Rect2i(x1 - 2, y, 2, 1), Pal.NICKEL[3])
			img.fill_rect(Rect2i(x0 + 3, y, x1 - x0 - 5, 1), Color(0, 0, 0, 0))
		else:
			img.fill_rect(Rect2i(x0 + 1, y, x1 - x0 - 1, 1), shade)
			img.set_pixel(x0 + 1, y, Pal.NICKEL[0])
	img.fill_rect(Rect2i(0, top, sz.x, sz.y - top), edge)   # o corpo
	img.fill_rect(Rect2i(1, top + 1, sz.x - 2, 1), Pal.NICKEL[0])
	img.fill_rect(Rect2i(1, top + 2, sz.x - 2, 2), Pal.NICKEL[1])
	img.fill_rect(Rect2i(1, top + 4, sz.x - 2, sz.y - top - 7), Pal.NICKEL[2])
	img.fill_rect(Rect2i(1, sz.y - 3, sz.x - 2, 2), Pal.NICKEL[3])
	img.fill_rect(Rect2i(sz.x - 2, top + 1, 1, sz.y - top - 2), Pal.NICKEL[3])
	for x in [4, sz.x - 8]:   # os rebites
		var r := Rect2i(x, top + 4, 4, 4)
		img.fill_rect(r, Color("ece7da"))
		img.fill_rect(Rect2i(r.position.x + 1, r.end.y - 1, 3, 1), Pal.NICKEL[3])
		img.fill_rect(Rect2i(r.end.x - 1, r.position.y + 1, 1, 3), Pal.NICKEL[3])
	img.set_pixel(0, top, Color(0, 0, 0, 0))
	img.set_pixel(sz.x - 1, top, Color(0, 0, 0, 0))
	return img


## Um vinco de dobra em `ci`: uma linha de sombra e, ao lado, uma de luz.
static func crease(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	var n := (b - a).orthogonal().normalized()
	ci.draw_line(a, b, Color(0, 0, 0, 0.14), 1.0)
	ci.draw_line(a + n, b + n, Color(1, 1, 1, 0.18), 1.0)
