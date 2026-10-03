class_name PunchCard
extends Control
## O cartão perfurado do despacho, nas coordenadas dele (as máquinas, `CardMachines`, o imprimem, levam e recolhem):
## formulário impresso em vermelho (faixa, rótulos, posições de furo, pauta e rodapé) com os dados datilografados em
## preto, e sombra na mesa (maior na mão). O jogador perfura o tipo de ocorrência (um só) e as unidades, cada um na sua
## posição (clicar em qualquer ponto da linha perfura o quadradinho dela); furo não se desfaz. Os furos são só a vista
## do que o `Dispatch` guarda.
## O que as máquinas usam de um cartão (um tipo novo de cartão responde o mesmo): `size`, `held`, `click(p)`,
## `point(p)` e `cursor(p)`, com `p` nas coordenadas do cartão.

const W := 216.0
const ROW := 19.0
const CELL := Vector2(10, 14)
const CARD := Color("e9dcb4")
const CARD_EDGE := Color("a8966b")
const FORM := Color("8a2a1c")          # o formulário vem impresso na tinta vermelha das emergências (o carimbo do caderno)
const RULE := Color(0.35, 0.43, 0.55, 0.3)   # a pauta, como a do caderno
const HOLE := Color("17110b")
const MISSING := Color("8a3a14")
const SHADOW := Color(0, 0, 0, 0.35)
const SHADOW_REST := Vector2(3, 4)     # sombra do cartão na mesa...
const SHADOW_HELD := Vector2(9, 12)    # ...e erguido, na mão (como o plug da mesa)
const TOP := 82.0                      # o cabeçalho: faixa, local, bairro e setor, fio duplo
const FOOT := 22.0                     # o rodapé: fio e o nome da central
const CHAD_SEC := 0.45                 # o picote caindo

var dispatch: Dispatch
var serial := 0
var place := ""             ## o local impresso ("Rua do Sol, 1–99")
var sector := 0
## Na mão (sombra maior).
var held := false:
	set(v):
		held = v
		queue_redraw()
var cells: Array = []       ## [quadradinho no cartão, "type" | "unit", id, a linha inteira (clicável)]
var _hover: Array = []      ## a posição sob o mouse (a linha dela fica realçada se der para perfurar)
var _heads := {}            ## "type" / "unit" -> y do título da parte
var _rules: Array[float] = []   ## pauta entre as linhas
var _specks: Array[Vector2] = []   ## fibras do papel (cada cartão as suas)
var _chads: Array = []      ## picotes caindo: [posição no cartão, segundos]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # quem recebe o mouse são as máquinas
	set_process(false)


## Um cartão novo, em branco: número, local e setor datilografados.
func fill(n: int, at: String, sec: int) -> void:
	serial = n
	place = at
	sector = sec
	_hover = []
	_chads.clear()
	_layout()


## Clique em `p`: perfura a linha sob ele, se der. Devolve se perfurou.
func click(p: Vector2) -> bool:
	var c := _cell_at(p)
	if c.is_empty() or not _can_punch(c[1], c[2]):
		return false
	if c[1] == "type":
		dispatch.set_occurrence(c[2])
	else:
		dispatch.punch_unit(c[2])
	_chads.append([(c[0] as Rect2).get_center(), 0.0])
	set_process(true)
	return true


## O mouse em `p` (`Vector2.INF`: fora do cartão, ou ele não está para perfurar): realça a linha que dá para perfurar.
func point(p: Vector2) -> void:
	var h := [] if p == Vector2.INF else _cell_at(p)
	if h != _hover:
		_hover = h
		queue_redraw()


func cursor(p: Vector2) -> int:
	var c := _cell_at(p)
	if c.is_empty():
		return Control.CURSOR_MOVE
	if _can_punch(c[1], c[2]):
		return Control.CURSOR_POINTING_HAND
	return Control.CURSOR_ARROW if _punched(c[1], c[2]) else Control.CURSOR_FORBIDDEN


## Texto datilografado (Departure Mono 11), também para as máquinas.
static func write(ci: CanvasItem, p: Vector2, s: String, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(Pal.mono, p.round(), s, align, width, 11, col)


func _process(delta: float) -> void:
	for ch in _chads:
		ch[1] += delta
	_chads = _chads.filter(func(ch): return ch[1] < CHAD_SEC)
	if _chads.is_empty():
		set_process(false)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not cells.is_empty():
		_layout()   # o protocolo muda de tamanho com o idioma


## Posições de perfuração (o tipo de ocorrência, depois as unidades, cada uma com o protocolo embaixo).
func _layout() -> void:
	cells.clear()
	_rules.clear()
	var y := TOP
	_heads["type"] = y
	y += 20.0
	for o in GameData.CONTENT.occurrences:
		cells.append([Rect2(Vector2(10, y), CELL), "type", o, Rect2(4, y - 3.0, W - 8.0, ROW)])
		y += ROW
		_rules.append(y - 3.0)
	y += 6.0
	_heads["unit"] = y
	y += 20.0
	for u in Dispatch.UNIT_IDS:
		var top := y
		y += 16.0 + Pal.ui.get_multiline_string_size(_why(u), HORIZONTAL_ALIGNMENT_LEFT, W - 36.0, 11).y + 4.0
		cells.append([Rect2(Vector2(10, top), CELL), "unit", u, Rect2(4, top - 3.0, W - 8.0, y - top)])
		_rules.append(y - 3.0)
	size = Vector2(W, y + FOOT)
	queue_redraw()
	var rng := RandomNumberGenerator.new()
	rng.seed = serial
	_specks.clear()
	for i in 46:
		_specks.append(Vector2(rng.randi_range(3, int(W) - 5), rng.randi_range(22, int(size.y) - 6)))


func _why(u: String) -> String:
	return T.text({"pol": T.Key.DISPATCH_WHY_POL, "bomb": T.Key.DISPATCH_WHY_BOMB, "amb": T.Key.DISPATCH_WHY_AMB}[u])


## A posição de perfuração da linha sob `p` (clicar em qualquer ponto da linha perfura o quadradinho dela).
func _cell_at(p: Vector2) -> Array:
	for c in cells:
		if (c[3] as Rect2).has_point(p):
			return c
	return []


func _punched(kind: String, id: String) -> bool:
	return dispatch.occurrence() == id if kind == "type" else id in dispatch.picked()


func _can_punch(kind: String, id: String) -> bool:
	if kind == "type":
		return dispatch.occurrence() == ""   # um tipo só
	return dispatch.unit_free(id) and not id in dispatch.picked()


func _draw() -> void:
	var shape := PackedVector2Array([Vector2(10, 0), Vector2(W, 0), Vector2(W, size.y), Vector2(0, size.y), Vector2(0, 10)])
	var lift := SHADOW_HELD if held else SHADOW_REST
	var shadow := PackedVector2Array()
	for q in shape:
		shadow.append(q + lift)
	draw_colored_polygon(shadow, SHADOW)
	draw_colored_polygon(shape, CARD)   # o canto cortado dos cartões perfurados
	for sp in _specks:   # fibras do papel
		draw_rect(Rect2(sp, Vector2(2 if int(sp.x) % 3 == 0 else 1, 1)), CARD.darkened(0.1))
	# cabeçalho: a faixa impressa, o local e o bairro datilografados em linhas de preencher
	draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(W, 0), Vector2(W, 18), Vector2(0, 18), Vector2(0, 10)]), FORM)
	write(self, Vector2(14, 13), T.text(T.Key.CARD_TITLE), CARD)
	write(self, Vector2(14, 13), T.text(T.Key.CARD_SERIAL) % serial, CARD, W - 22.0, HORIZONTAL_ALIGNMENT_RIGHT)
	write(self, Vector2(10, 32), T.text(T.Key.CARD_PLACE), FORM)
	var box := Rect2(W - 21.0, 22.0, 11, 12)   # o setor, datilografado numa caixinha à direita
	draw_rect(box, FORM, false, 1.0)
	write(self, Vector2(box.position.x, 32), str(sector), Pal.INK, box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	write(self, Vector2(10, 32), T.text(T.Key.CARD_SECTOR), FORM, box.position.x - 15.0, HORIZONTAL_ALIGNMENT_RIGHT)
	write(self, Vector2(10, 47), place, Pal.INK)
	_field(10.0, 50.0)
	var label := T.text(T.Key.CARD_DISTRICT)
	var at := 16.0 + Pal.ui.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	write(self, Vector2(10, 66), label, FORM)
	write(self, Vector2(at, 66), T.text(CityMap.DISTRICT[sector]).to_upper(), Pal.INK)
	_field(at, 69.0)
	draw_rect(Rect2(6, TOP - 7.0, W - 12.0, 1), FORM)   # fio duplo
	draw_rect(Rect2(6, TOP - 5.0, W - 12.0, 1), FORM)
	# as partes: título com a caixinha (um X datilografado quando perfurada) e a pauta entre as linhas
	var heads := {"type": [dispatch.occurrence() != "", T.Key.DISPATCH_CHECK_TYPE], "unit": [not dispatch.picked().is_empty(), T.Key.DISPATCH_CHECK_UNITS]}
	for kind in heads:
		var y: float = _heads[kind]
		write(self, Vector2(10, y + 11.0), T.text(heads[kind][1]).to_upper(), FORM)
		var check := Rect2(W - 21.0, y + 1.0, 11, 11)
		draw_rect(check, FORM, false, 1.0)
		if heads[kind][0]:
			write(self, Vector2(check.position.x, check.position.y + 10.0), "X", Pal.INK, check.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		draw_rect(Rect2(10, y + 15.0, W - 20.0, 1), Color(FORM, 0.5))
	if not _hover.is_empty() and _can_punch(_hover[1], _hover[2]):
		draw_rect(_hover[3], Color(Pal.AMBER, 0.16))   # a linha que vai ser perfurada
	for y in _rules:
		draw_rect(Rect2(28, y, W - 38.0, 1), RULE)
	var count := {"type": 0, "unit": 0}   # cada parte numera as suas posições: 1, 2, 3...
	for c in cells:
		count[c[1]] += 1
		_draw_cell(c[0], c[1], c[2], count[c[1]])
	# rodapé: o fio, o nome da central e as marcas de coluna na borda, como nos cartões perfurados
	var foot := size.y - FOOT + 4.0
	draw_rect(Rect2(6, foot, W - 12.0, 1), FORM)
	write(self, Vector2(0, foot + 12.0), T.text(T.Key.GAME_TITLE).to_upper(), Color(FORM, 0.8), W, HORIZONTAL_ALIGNMENT_CENTER)
	for x in range(6, int(W) - 4, 6):
		draw_rect(Rect2(x, size.y - 3.0, 1, 2), Color(FORM, 0.35))
	shape.append(shape[0])
	draw_polyline(shape, CARD_EDGE, 1.0)
	draw_rect(Rect2(1, size.y - 1.0, W - 1.0, 1), CARD_EDGE.darkened(0.25))   # a espessura do cartão
	draw_rect(Rect2(W - 1.0, 1, 1, size.y - 1.0), CARD_EDGE.darkened(0.25))
	for ch in _chads:   # o picote do furo caindo
		var k: float = ch[1] / CHAD_SEC
		draw_rect(Rect2(ch[0] + Vector2(-3, -5 + 60.0 * k * k), Vector2(6, 9)), Color(CARD, 1.0 - k))


## Linha de preencher (pontilhado vermelho) embaixo de um dado datilografado.
func _field(x: float, y: float) -> void:
	for fx in range(int(x), int(W) - 10, 3):
		draw_rect(Rect2(fx, y, 1, 1), Color(FORM, 0.6))


## Uma posição de perfuração (impressa em vermelho, com o número) e o que ela quer dizer.
func _draw_cell(r: Rect2, kind: String, id: String, n: int) -> void:
	var busy := kind == "unit" and not dispatch.unit_free(id)
	if _punched(kind, id):
		draw_rect(r, HOLE)
		draw_rect(Rect2(r.position.x, r.end.y - 1.0, r.size.x, 1), Color(1, 1, 1, 0.18))   # a luz passando pelo furo
	else:
		draw_rect(r, Color(FORM, 0.08))
		draw_rect(r, FORM, false, 1.0)
		write(self, Vector2(r.position.x, r.position.y + 11.0), str(n), Color(FORM, 1.0 if _can_punch(kind, id) else 0.3),
			r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var at := Vector2(r.end.x + 8.0, r.position.y + 11.0)
	if kind == "type":
		write(self, at, tr(id), Pal.INK, W - 36.0)
		return
	write(self, at, T.text(Dispatch.UNIT_NAMES[id]), MISSING if busy else Pal.INK, W - 36.0)
	if busy:   # ocupada: riscada, e o estado no lugar do protocolo
		draw_line(r.position, r.end, Pal.INK, 1.0)
		draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Pal.INK, 1.0)
		write(self, at + Vector2(0, 14), T.text(Dispatch.UNIT_STATUS[dispatch.unit_state(id)]), MISSING, W - 36.0)
		return
	draw_multiline_string(Pal.mono, (at + Vector2(0, 14)).round(), _why(id), HORIZONTAL_ALIGNMENT_LEFT, W - 36.0, 11, -1, Pal.INK_SOFT)
