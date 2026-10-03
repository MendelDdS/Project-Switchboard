class_name PhoneBook
extends Control
## Lista telefônica em páginas duplas, uma letra por vez: os contatos que começam com a letra aberta, em ordem
## alfabética do nome (como aparece: "Nome Sobrenome"), começam na página da esquerda e, se não couberem, seguem na da
## direita. Na borda direita, os cortes de índice (uma aba por letra; a da letra aberta fica destacada). Voltar e
## Virar passam de letra em letra; depois da última vem a página de anotações. Clique num contato para marcá-lo com o
## dedo. Os contatos vêm de GameData.CONTENT.directory (só os setores atendidos e o despacho).

const TAB_W := 26.0           # largura das abas de índice, na borda direita
const NAV_H := 56.0           # altura da barra de Voltar/Virar, embaixo do livro
const TOP := 40.0             # onde começam os contatos da página (abaixo do cabeçalho)
const PAPER := Color("e3d6b2")
const PLAIN := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ç": "c"}

var marked := -1
var hover := -1
var _hits: Array = []
var _entries: Array = []      ## contatos em ordem alfabética do nome
var _index: Array = []        ## letras que têm contato (uma aba cada)
var _letter := 0              ## letra aberta (índice em `_index`); `_index.size()` = página de anotações
var _hover_tab := -1
var book := Rect2()           ## o livro acompanha o tamanho da aba (`NOTIFICATION_RESIZED`)
var bottom := 0.0             ## até onde vão os contatos
var page_w := 0.0             ## largura do texto de cada página

@onready var _prev: Button = %Prev
@onready var _next: Button = %Next


func _ready() -> void:
	_entries = GameData.CONTENT.directory.filter(func(e): return e.dispatch_only or GameData.in_service(e.number))
	_entries.sort_custom(func(a, b): return _plain(a.name).naturalnocasecmp_to(_plain(b.name)) < 0)
	for e in _entries:
		if not initial(e) in _index:
			_index.append(initial(e))
	_prev.pressed.connect(turn.bind(-1))
	_next.pressed.connect(turn.bind(1))
	_update_nav()


## Nome sem acento, para ordenar e agrupar como numa lista de papel ("Célia" antes de "Cine").
static func _plain(s: String) -> String:
	var out := s.to_lower()
	for k in PLAIN:
		out = out.replace(k, PLAIN[k])
	return out


## Letra do contato (a aba dele).
static func initial(e: DirectoryEntry) -> String:
	return _plain(e.name.left(1)).to_upper()


## Letra aberta ("" na página de anotações).
func current_letter() -> String:
	return _index[_letter] if _letter < _index.size() else ""


## Contatos da letra aberta, divididos entre a página da esquerda e a da direita (pela altura de cada um).
func pages() -> Array:
	var all := _entries.filter(func(e): return initial(e) == current_letter())
	var h := TOP
	var n := 0
	while n < all.size() and h + entry_height(all[n]) <= bottom:
		h += entry_height(all[n])
		n += 1
	return [all.slice(0, n), all.slice(n)]


func turn(dir: int) -> void:
	_open(clampi(_letter + dir, 0, _index.size()))


## Abre a página dupla da letra.
func jump(letter: String) -> void:
	_open(maxi(0, _index.find(letter)))


func _open(i: int) -> void:
	if i != _letter:
		_letter = i
		Sfx.play("page")
		queue_redraw()
	_update_nav()


func _update_nav() -> void:
	_prev.disabled = _letter == 0
	_next.disabled = _letter >= _index.size()


## Aba de índice da letra `i`, na borda direita (a da letra aberta sai mais para fora).
func _tab_rect(i: int, out := false) -> Rect2:
	var h := minf(26.0, (book.size.y - 12.0) / _index.size())
	return Rect2(book.end.x - 4, 6 + i * h, TAB_W + (0.0 if out else -3.0), h - 2)


func _tab_at(p: Vector2) -> int:
	for i in _index.size():
		if _tab_rect(i, true).has_point(p):
			return i
	return -1


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h := _hit(e.position)
		var t := _tab_at(e.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h >= 0 or t >= 0 else Control.CURSOR_ARROW
		if h != hover or t != _hover_tab:
			hover = h
			_hover_tab = t
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var t := _tab_at(e.position)
		if t >= 0:
			_open(t)
			return
		var h := _hit(e.position)
		if h >= 0:
			marked = -1 if marked == h else h
			Sfx.play("click")
			queue_redraw()


func _hit(pos: Vector2) -> int:
	for hit in _hits:
		if (hit[0] as Rect2).has_point(pos):
			return int(hit[1])
	return -1


func _draw() -> void:
	_hits.clear()
	_draw_tabs()
	draw_rect(book, Pal.INK_SOFT)
	draw_rect(book.grow(-2), PAPER)
	var mid := book.size.x / 2.0
	var y := 6.0
	while y < book.size.y - 4:
		draw_rect(Rect2(mid - 1, y, 2, 5), Pal.PAPER_LINE)
		y += 9
	var left := 14.0
	var right := 14.0 + mid
	if current_letter() == "":   # depois da última letra: anotações
		_page_head(left, T.text(T.Key.BOOK_NOTES))
		draw_multiline_string(Pal.ui, Vector2(left, 58), T.text(T.Key.BOOK_NOTE_TEXT), HORIZONTAL_ALIGNMENT_LEFT, page_w, 11, -1, Pal.INK_SOFT)
		_ruled(right)
		return
	var pg := pages()
	_page_letter(left, current_letter())
	var ey := TOP
	for e in pg[0]:
		_draw_entry(left, ey, e)
		ey += entry_height(e)
	if pg[1].is_empty():
		_ruled(right)
		return
	_page_letter(right, current_letter())
	ey = TOP
	for e in pg[1]:
		_draw_entry(right, ey, e)
		ey += entry_height(e)


## Cortes de índice na borda direita, por baixo da capa: a aba da letra aberta sai mais e fica escura.
func _draw_tabs() -> void:
	for i in _index.size():
		var on := i == _letter
		var r := _tab_rect(i, on or i == _hover_tab)
		draw_rect(r, Pal.INK_SOFT)
		draw_rect(r.grow(-1), Pal.INK_SOFT if on else (PAPER.darkened(0.06) if i == _hover_tab else PAPER.darkened(0.12)))
		draw_string(Pal.mono, Vector2(r.position.x + 4, r.position.y + (r.size.y + Pal.mono.get_ascent(11)) / 2.0 - 2),
			_index[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4, 20, PAPER if on else Pal.INK_SOFT)


## Cabeçalho da página: um título e o fio embaixo.
func _page_head(x0: float, txt: String) -> void:
	draw_string(Pal.mono, Vector2(x0, 26), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.INK_SOFT)
	draw_rect(Rect2(x0, 31, page_w, 2), Pal.INK_SOFT)


## Cabeçalho da página de uma letra: a letra num quadrado de tinta e o fio até a margem.
func _page_letter(x0: float, letter: String) -> void:
	draw_rect(Rect2(x0, 6, 24, 24), Pal.INK_SOFT)
	draw_string(Pal.mono, Vector2(x0, 6 + Pal.mono.get_ascent(22)), letter, HORIZONTAL_ALIGNMENT_CENTER, 24, 22, PAPER)
	draw_rect(Rect2(x0 + 30, 29, page_w - 30, 2), Pal.INK_SOFT)


## Página sem contatos: só a pauta.
func _ruled(x0: float) -> void:
	var y := TOP + 24.0
	while y < bottom:
		var lx := x0 - 4
		while lx < x0 + page_w + 4:
			draw_rect(Rect2(lx, y, 2, 1), Pal.PAPER_LINE)
			lx += 4
		y += 32.0


## Contato: nome, pontilhado até o número e, embaixo, observação, endereço e bairro.
func _draw_entry(x0: float, ey: float, e: DirectoryEntry) -> void:
	var mono := Pal.mono
	var idx := GameData.CONTENT.directory.find(e)
	var eh := entry_height(e)
	var r := Rect2(x0 - 6, ey, page_w + 12, eh)
	_hits.append([r, idx])
	if idx == marked:
		draw_rect(r, Color(Pal.AMBER, 0.38))
	elif idx == hover:
		draw_rect(r, Color(Pal.AMBER, 0.16))
	var base := ey + 4 + mono.get_ascent(11)
	draw_multiline_string(mono, Vector2(x0, base), e.name, HORIZONTAL_ALIGNMENT_LEFT, page_w - 57, 11, -1, Color.BLACK)
	draw_string(mono, Vector2(x0, base), e.number, HORIZONTAL_ALIGNMENT_RIGHT, page_w, 11, Color.BLACK)
	var nh := mono.get_multiline_string_size(e.name, HORIZONTAL_ALIGNMENT_LEFT, page_w - 57, 11).y
	if nh <= 24.0:   # nome numa linha: pontilhado até o número
		var dx := x0 + mono.get_string_size(e.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 6
		var nx := x0 + page_w - mono.get_string_size(e.number, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x - 6
		while dx < nx:
			draw_rect(Rect2(dx, base - 2, 2, 2), Pal.INK_SOFT)
			dx += 6
	draw_multiline_string(mono, Vector2(x0, ey + 6 + nh + mono.get_ascent(11)), _addr(e), HORIZONTAL_ALIGNMENT_LEFT, page_w, 11, -1, Pal.INK_SOFT)
	var dy := ey + eh - 1
	var lx := x0 - 4
	while lx < x0 + page_w + 4:
		draw_rect(Rect2(lx, dy, 2, 1), Pal.PAPER_LINE)
		lx += 4


## Linha de baixo do contato: a observação, o endereço e o bairro (as ruas que continuam têm a numeração seguindo
## de um bairro para o outro, então o número sozinho não diz onde fica).
func _addr(e: DirectoryEntry) -> String:
	var sub: String = tr(e.note) if e.note != "" else ""
	# o bairro e "rua, número" não quebram no meio; se não couber, o bairro desce inteiro para a linha de baixo
	var nb := func(s: String): return s.replace(" ", " ")
	var district: String = nb.call(T.text(CityMap.DISTRICT[int(e.number.left(1))]))
	return (sub + " · " if sub != "" else "") + e.address.replace(", ", ", ") + " · " + district


## Altura do contato na página (nome e endereço podem quebrar linha).
func entry_height(e: DirectoryEntry) -> float:
	var nh := Pal.mono.get_multiline_string_size(e.name, HORIZONTAL_ALIGNMENT_LEFT, page_w - 57, 11).y
	return nh + Pal.mono.get_multiline_string_size(_addr(e), HORIZONTAL_ALIGNMENT_LEFT, page_w, 11).y + 12


## O idioma mudou nas configurações: redesenha os textos. O mouse saiu: some o realce.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
	elif what == NOTIFICATION_RESIZED:
		book = Rect2(0, 0, size.x - TAB_W, size.y - NAV_H)
		bottom = book.size.y - 6
		page_w = book.size.x / 2.0 - 28
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT and (hover != -1 or _hover_tab != -1):
		hover = -1
		_hover_tab = -1
		queue_redraw()
