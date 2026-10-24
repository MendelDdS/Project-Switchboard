extends RefCounted
## A fita cassete dos equipamentos da B4 (o porta-fitas, o gravador e a caixa das autoridades), desenhada pixel a
## pixel: de frente (`face`: a etiqueta escrita à mão, a janelinha com as bobinas), de lado, em pé (`spine`), e de lado
## no estojo (`in_case`, como fica no porta-fitas). Virando no ar, a de frente vai estreitando até a de lado (`w` entre
## `SPINE_W` e `FACE.x`). E a caixa de pé na prateleira, com tampo e lateral na inclinação dos pares de plugs
## (`block`), de que os três são feitos.

const FACE := Vector2i(44, 26)   ## de frente, na escala dos plugs (a fita de verdade tem 10 × 6,4 cm)
const SPINE_W := 5               ## de lado
const LABEL := Rect2i(3, 2, 38, 13)   ## a etiqueta de papel, de frente: o nome numa linha, a hora e os risquinhos na outra
const LETTERS := 8               ## o que cabe numa linha dela (mais que isso, cortado)
const WINDOW := Rect2i(9, 16, 26, 7)   ## a janelinha das bobinas, embaixo da etiqueta
const CASE := Vector2i(8, 30)    ## o estojo de lado, em pé: a lombada de papel com a faixa da marca
const HAND := Pal.PEN            ## a caneta do operador na etiqueta
const MARK := Pal.RED_PEN        ## o risquinho de cada palavra-chave
const PACK := Pal.TAPE_PACK       ## a fita enrolada nas bobinas


## A fita de frente com o canto de cima à esquerda em `at`, `w` de largura (virando, menos que `FACE.x`): na etiqueta,
## as `written` primeiras letras de `name` e, na linha de baixo, da hora `hour` (escritas nessa ordem), e `marks`
## risquinhos (o último, `pop` de 0 a 1, sai maior); nas bobinas, `fill` de 0 a 1 já passou para a da direita e os
## dentes no passo `step`.
static func face(ci: CanvasItem, at: Vector2, w: int, name := "", hour := "", written := 0, marks := 0, pop := 0.0, fill := 0.0, step := 0) -> void:
	if w <= SPINE_W:
		spine(ci, at + Vector2(roundi((FACE.x - SPINE_W) / 2.0), 0))
		return
	var x := at.x + roundi((FACE.x - w) / 2.0)   # estreitando pelo meio
	var h := FACE.y
	ci.draw_rect(Rect2(x, at.y, w, h), Pal.BAKELITE[0])   # a beira
	ci.draw_rect(Rect2(x + 1, at.y + 1, w - 2, h - 2), Pal.BAKELITE[3])
	ci.draw_rect(Rect2(x + 1, at.y + 1, w - 2, 1), Pal.BAKELITE[5])   # a luz na beira de cima
	var lw := maxi(roundi(LABEL.size.x * w / float(FACE.x)), 1)
	var lx := x + roundi((w - lw) / 2.0)
	ci.draw_rect(Rect2(lx, at.y + LABEL.position.y, lw, LABEL.size.y), Pal.LABEL_PAPER)
	ci.draw_rect(Rect2(lx, at.y + LABEL.end.y - 1, lw, 1), Pal.PAPER_LINE)
	if w < FACE.x:   # virando: sem as letras nem a janelinha, que não esticam
		return
	var l := at + Vector2(LABEL.position)
	if written > 0:   # (a fonte miúda tem 3 linhas em cima, para os acentos)
		ci.draw_texture(PixelArt.tiny(name.left(written)), l + Vector2(1, -2), HAND)
	if written > name.length():
		ci.draw_texture(PixelArt.tiny(hour.left(written - name.length())), l + Vector2(1, 4), HAND)
	for i in marks:   # os risquinhos, à direita da hora
		var tall := 4 if i == marks - 1 and pop > 0.0 else 3
		ci.draw_rect(Rect2(l.x + LABEL.size.x - 3 - i * 2, l.y + LABEL.size.y - 2 - tall, 1, tall), MARK)
	# a janelinha com as duas bobinas: a fita passa da esquerda para a direita enquanto grava
	var win := Rect2(at + Vector2(WINDOW.position), WINDOW.size)
	ci.draw_rect(win, Pal.VOID)
	for k in 2:
		var hc := win.position.x + 5 + k * 15   # o meio do cubo
		var r := roundi(lerpf(4.0, 1.0, fill) if k == 0 else lerpf(1.0, 4.0, fill))   # o rolo de fita em volta dele
		ci.draw_rect(Rect2(hc - r, win.position.y, r * 2 + 1, win.size.y), PACK)
		ci.draw_rect(Rect2(hc - 1, win.position.y + 1, 3, 5), Pal.LABEL_PAPER.darkened(0.25))   # o cubo branco, vazado...
		ci.draw_rect(Rect2(hc, win.position.y + 2, 1, 3), Pal.VOID)
		var tooth: Vector2 = [Vector2(0, 0), Vector2(1, 2), Vector2(0, 4), Vector2(-1, 2)][posmod(step + k, 4)]
		ci.draw_rect(Rect2(Vector2(hc, win.position.y + 1) + tooth, Vector2.ONE), Pal.BAKELITE[5])   # ...com o dente que gira
	ci.draw_rect(Rect2(at.x + 3, at.y + h - 2, 2, 1), Pal.BAKELITE[1])   # os parafusinhos de baixo
	ci.draw_rect(Rect2(at.x + FACE.x - 5, at.y + h - 2, 2, 1), Pal.BAKELITE[1])


## A fita de lado, em pé, com o canto de cima à esquerda em `at`: a casca escura e a beira da etiqueta.
static func spine(ci: CanvasItem, at: Vector2) -> void:
	ci.draw_rect(Rect2(at, Vector2(SPINE_W, FACE.y)), Pal.BAKELITE[0])
	ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(SPINE_W - 2, FACE.y - 2)), Pal.BAKELITE[3])
	ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(1, FACE.y - 2)), Pal.BAKELITE[5])   # a luz de quina
	ci.draw_rect(Rect2(at + Vector2(1, LABEL.position.y), Vector2(SPINE_W - 2, LABEL.size.y)), Pal.LABEL_PAPER)   # a etiqueta dobrada na beira
	ci.draw_rect(Rect2(at + Vector2(1, LABEL.end.y - 1), Vector2(SPINE_W - 2, 1)), Pal.PAPER_LINE)


## O estojo de lado, em pé, com o canto de cima à esquerda em `at`: o plástico com a quina na luz e, atrás dele, a
## lombada de papel com a faixa da marca e as linhas impressas.
static func in_case(ci: CanvasItem, at: Vector2) -> void:
	ci.draw_rect(Rect2(at, Vector2(CASE)), Pal.BAKELITE[0])
	ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(CASE) - Vector2(2, 2)), Pal.LABEL_PAPER.darkened(0.1))
	ci.draw_rect(Rect2(at + Vector2(1, 4), Vector2(CASE.x - 2, 4)), Pal.RED)   # a faixa da marca
	ci.draw_rect(Rect2(at + Vector2(1, 8), Vector2(CASE.x - 2, 1)), Pal.RED.darkened(0.4))
	for y in [12, 15, 18]:   # o que vem impresso (a fita é virgem: o operador não escreve na lombada)
		ci.draw_rect(Rect2(at + Vector2(2, y), Vector2(CASE.x - 4 - (y % 2), 1)), Pal.PAPER_LINE)
	ci.draw_rect(Rect2(at + Vector2(1, 1), Vector2(1, CASE.y - 2)), Pal.NICKEL[1])   # a quina do plástico, na luz
	ci.draw_rect(Rect2(at + Vector2(1, CASE.y - 2), Vector2(CASE.x - 2, 1)), Pal.NICKEL[2])


## O nome que o operador escreve na etiqueta: o primeiro nome de quem ligou (o do roteiro, sem tratamento; sem ele,
## o que a mesa mostra), em maiúsculas, cortado no que cabe.
static func label_of(c: PhoneCall) -> String:
	var t := c.data as TransferCall
	var full: String = t.caller_name if t != null and t.caller_name != "" else (c.named if c.named != "" else TranslationServer.translate(c.caller))
	return full.get_slice(" ", 0).to_upper().left(LETTERS)


## A inclinação de tudo que fica deitado na prateleira (o tampo de cima e a lateral dos equipamentos): a dos pares de
## plugs (`Switchboard._lean`), em px para o lado por linha para trás.
const LEAN := Switchboard.PAIR_SHIFT / (Switchboard.SHELF_FRONT_Y - Switchboard.SHELF_HOLE_Y)


## Uma caixa de pé na prateleira: a frente `front`, o tampo de `top` linhas em cima (cada uma `LEAN` mais à direita)
## e a lateral da direita entre os dois.
static func block(ci: CanvasItem, front: Rect2, top: int, top_col: Color, front_col: Color, side_col: Color) -> void:
	var d := roundf(top * LEAN)
	for y in range(int(front.position.y) - top, int(front.end.y)):
		var l := front.end.x + (roundf((front.position.y - y) * LEAN) if y < front.position.y else 0.0)
		var low := front.end.y - 1 - top
		var r := front.end.x + d - (roundf((y - low) * LEAN) if y > low else 0.0)
		if r > l:
			ci.draw_rect(Rect2(l, y, r - l, 1), side_col)
		if y < front.position.y:
			ci.draw_rect(Rect2(front.position.x + roundf((front.position.y - y) * LEAN), y, front.size.x, 1), top_col)
	ci.draw_rect(front, front_col)
