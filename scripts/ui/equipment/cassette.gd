extends RefCounted
## A fita cassete dos equipamentos da B4 (o compartimento e o gravador, na coluna do lado do painel), desenhada pixel a
## pixel de lado, em pé, na escala dos plugs (a fita de verdade tem 10 × 6,4 × 1,2 cm): a lombada de plástico escuro
## com a etiqueta de papel, a faixa da marca no alto e, escritos de lado (de baixo para cima, como na lombada de um
## livro), o nome de quem é gravado e a hora; acima, um risquinho por palavra-chave (`standing`). Gravada uma conversa
## que não foi a pedida, o operador risca a faixa da marca (`wrong`). Deitada, a mesma
## lombada virada para a direita, com a escrita de comprido (`lying`, a pilha da mesa vista de perto). Voando para a
## mesa, tomba de lado (girada 90°, exata) e encolhe num bloco liso (`block`).

const SPINE := Vector2i(12, 100)   ## de lado, em pé
const LABEL := Rect2i(2, 5, 8, 90)   ## a etiqueta de papel na lombada
const TEXT_FOOT := 92   ## onde a escrita começa (embaixo) e sobe
const MARKS_Y := 12   ## o primeiro risquinho, logo abaixo da faixa da marca
const LETTERS := 8   ## o que cabe do nome (mais que isso, cortado)
const HAND := Pal.PEN   ## a caneta do operador na etiqueta
const MARK := Pal.RED_PEN   ## o risquinho de cada palavra-chave
const TEXT_CACHE := 64

static var _sideways := {}   ## texto -> a fonte miúda girada 90° (exata, pixel a pixel: a escrita de lado)


## A fita em pé com o canto de cima à esquerda em `at`: na etiqueta, as `written` primeiras letras de "`name` `hour`"
## e `marks` risquinhos (o último, com `pop`, sai maior); `wrong`, a faixa da marca riscada (não é a conversa pedida).
static func standing(ci: CanvasItem, at: Vector2, name := "", hour := "", written := 0, marks := 0, pop := false, wrong := false) -> void:
	ci.draw_rect(Rect2(at, Vector2(SPINE)), Pal.BAKELITE[0])   # a beira
	ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(SPINE) - Vector2(2, 2)), Pal.BAKELITE[3])
	ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(1, SPINE.y - 2)), Pal.BAKELITE[5])   # a quina na luz
	var l := Rect2(at + Vector2(LABEL.position), LABEL.size)
	ci.draw_rect(l, Pal.LABEL_PAPER)
	ci.draw_rect(Rect2(l.end.x - 1, l.position.y, 1, l.size.y), Pal.PAPER_LINE)   # a beira da direita, na sombra
	ci.draw_rect(Rect2(l.position + Vector2(0, 1), Vector2(l.size.x - 1, 3)), Pal.RED)   # a faixa da marca
	ci.draw_rect(Rect2(l.position + Vector2(0, 4), Vector2(l.size.x - 1, 1)), Pal.RED.darkened(0.4))
	if wrong:
		ci.draw_rect(Rect2(l.position + Vector2(0, 2), Vector2(l.size.x - 1, 1)), HAND)   # riscada à caneta
	var text := (name + " " + hour).left(written) if written > 0 else ""
	if text.strip_edges() != "":
		var t := _turned(text)   # (as maiúsculas nas colunas 3 a 7 da textura girada: no meio do papel)
		ci.draw_texture(t, at + Vector2(1, TEXT_FOOT - t.get_height()), HAND)
	for i in marks:
		var wide := 5 if i == marks - 1 and pop else 3
		ci.draw_rect(Rect2(l.position.x + 1, at.y + MARKS_Y + i * 2, wide, 1), MARK)


## A fita deitada com o canto de cima à esquerda em `at` (`standing` virada um quarto para a direita: a faixa da marca
## na ponta da direita, a escrita da esquerda para a direita, `marks` risquinhos antes da faixa; `wrong`, riscada).
static func lying(ci: CanvasItem, at: Vector2, name := "", hour := "", marks := 0, wrong := false) -> void:
	var s := Vector2(SPINE.y, SPINE.x)
	ci.draw_rect(Rect2(at, s), Pal.BAKELITE[0])
	ci.draw_rect(Rect2(at + Vector2(1, 1), s - Vector2(2, 2)), Pal.BAKELITE[3])
	ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(s.x - 2, 1)), Pal.BAKELITE[5])   # a quina na luz
	var l := Rect2(at + Vector2(s.x - LABEL.end.y, LABEL.position.x), Vector2(LABEL.size.y, LABEL.size.x))
	ci.draw_rect(l, Pal.LABEL_PAPER)
	ci.draw_rect(Rect2(l.position.x, l.end.y - 1, l.size.x, 1), Pal.PAPER_LINE)   # a beira de baixo, na sombra
	ci.draw_rect(Rect2(l.end.x - 4, l.position.y, 3, l.size.y - 1), Pal.RED)   # a faixa da marca
	ci.draw_rect(Rect2(l.end.x - 5, l.position.y, 1, l.size.y - 1), Pal.RED.darkened(0.4))
	if wrong:
		ci.draw_rect(Rect2(l.end.x - 3, l.position.y, 1, l.size.y - 1), HAND)
	var text := (name + " " + hour).strip_edges()
	if text != "":
		ci.draw_texture(PixelArt.tiny(text), at + Vector2(s.x - TEXT_FOOT, 0), HAND)   # (as maiúsculas nas linhas 3 a 7: no meio do papel)
	for i in marks:
		ci.draw_rect(Rect2(l.end.x - 1 - MARKS_Y - i * 2, l.position.y + 1, 1, 3), MARK)


## A fita voando no retângulo `r`, sem letras (que não encolhem): em pé, a lombada com a etiqueta ao comprido, como na
## `standing`; deitada (mais larga que alta), como fica na pilha da mesa (`Background._art_tape`): o plástico escuro
## com a etiqueta nos 60% da esquerda.
static func block(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Pal.BAKELITE[0])
	if r.size.x > 2 and r.size.y > 2:
		ci.draw_rect(r.grow(-1), Pal.BAKELITE[3])
		var l: Rect2
		if r.size.x > r.size.y:
			var dy := maxf(roundf(r.size.y * 0.15), 1.0)
			l = Rect2(r.position.x + 1.0, r.position.y + dy, roundf(r.size.x * 0.6), r.size.y - dy * 2.0)
		else:
			var d := (r.size * Vector2(0.17, 0.05)).round().max(Vector2.ONE)   # (na `standing`: 2 de 12 no lado, 5 de 100 na ponta)
			l = r.grow_individual(-d.x, -d.y, -d.x, -d.y)
		if l.size.x >= 1 and l.size.y >= 1:
			ci.draw_rect(l, Pal.LABEL_PAPER)


## O texto `s` na fonte miúda, girado para ler de baixo para cima.
static func _turned(s: String) -> Texture2D:
	if not _sideways.has(s):
		if _sideways.size() >= TEXT_CACHE:
			_sideways.clear()
		var img := PixelArt.tiny(s).get_image()
		img.rotate_90(COUNTERCLOCKWISE)
		_sideways[s] = ImageTexture.create_from_image(img)
	return _sideways[s]


## O nome que o operador escreve na etiqueta: o primeiro nome de quem ligou (o do roteiro, sem tratamento; sem ele,
## o que a mesa mostra), em maiúsculas, cortado no que cabe.
static func label_of(c: PhoneCall) -> String:
	var t := c.data as TransferCall
	var full: String = t.caller_name if t != null and t.caller_name != "" else (c.named if c.named != "" else TranslationServer.translate(c.caller))
	return full.get_slice(" ", 0).to_upper().left(LETTERS)
