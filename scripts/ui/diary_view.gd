extends Control
## O diário de Maria aberto (`Tools.DIARY`): página dupla pautada, como a lista. À esquerda, a data e as tarefas da
## noite (`Diary.tasks`) na letra dela a lápis (o jeito do `[hand]` do `paper_ink.gd`, letra a letra): riscada a
## cumprida, com um X a que não dá mais; a rotina com quanto falta. Com o diário aberto, a linha nova se escreve letra
## a letra e o risco se traça na hora, com o som do lápis; fechado, a linha já aparece escrita e o risco espera abrir.
## À direita, as anotações dela (`Diary.notes`), escritas do mesmo jeito, depois das tarefas que não couberam à
## esquerda; a carta lida fica guardada entre as páginas, a ponta para fora no alto da direita (o clique abre).
## As noites que passaram (`pages`, do `Progress.diary`) ficam antes, como ficaram: folheia-se pelas dobras nos cantos
## de baixo (a da esquerda volta, a da direita avança), que dobram mais com o mouse em cima.

signal letter_open(text: String)   ## clicou na carta guardada: `text`, em português

const DIARY := preload("res://scripts/diary.gd")
const TOP := 62.0         ## a primeira pauta das tarefas (em cima, a data e o título da página)
const ROW := 16.0         ## de uma pauta à outra
const INDENT := 12.0      ## o texto depois do tracinho (ou do X)
const WRITE_CPS := 45.0   ## letras por segundo, escrevendo
const STRIKE_SEC := 0.3   ## o risco (ou cada perna do X)
const SCRATCH_EVERY := 6  ## o som do lápis a cada tantas letras
const FOLD := 16.0        ## o canto dobrado, em px (a perna da dobra)...
const FOLD_HOVER := 24.0  ## ...e com o mouse em cima
const FOLD_SPEED := 60.0  ## px por segundo, dobrando e desdobrando
const LETTER_AT := Rect2(-64, -9, 38, 25)   ## a ponta da carta guardada, a partir do canto de cima à direita

var night := 1
var tasks: Array[Dictionary] = []:   ## as de `Diary.tasks` (o Main repassa quando mudam)
	set(v):
		tasks = v
		_settle(v)
var notes: Array[Dictionary] = []:   ## as de `Diary.notes`
	set(v):
		notes = v
		_settle(v)
var letter := "":   ## a carta de hoje, já lida e guardada aqui (em português; vazio: nenhuma)
	set(v):
		letter = v
		queue_redraw()
var pages := {}:   ## noite -> a página dela como ficou (`Diary.page`): as noites antes desta
	set(v):
		pages = v
		queue_redraw()
var _shown := {}   # id -> o que está na página: {"chars" escritas, "state" traçado, "mark" do traço em andamento (0 a 1)}
var page_w := 0.0
var _at := -1          # a noite aberta (-1: a de hoje)
var _hover := -1       # a dobra com o mouse em cima (0 volta, 1 avança; -1 nenhuma)
var _fold := [FOLD, FOLD]   # o tamanho de cada dobra agora (vai ao de `_hover`)


## Linhas novas em `list`: com o diário fechado, já aparecem escritas; aberto, se escrevem no `_process`.
func _settle(list: Array[Dictionary]) -> void:
	if not is_visible_in_tree():
		for t in list:
			if not _shown.has(t.id):
				_shown[t.id] = {"chars": float(t.text.length()), "state": DIARY.State.OPEN, "mark": 0.0}
	set_process(true)
	queue_redraw()


func _ready() -> void:
	visibility_changed.connect(func():   # (abre sempre na noite de hoje)
		_at = -1
		set_process(is_visible_in_tree()))
	set_process(false)


## Escreve ou risca a primeira tarefa que ainda não está na página como deveria; nada a fazer, para.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		set_process(false)
		return
	var folding := false
	for i in 2:   # as dobras indo ao tamanho delas
		var want := FOLD_HOVER if i == _hover else FOLD
		if _fold[i] != want:
			_fold[i] = move_toward(_fold[i], want, FOLD_SPEED * delta)
			folding = true
			queue_redraw()
	for t in tasks + notes:
		if not _shown.has(t.id):
			_shown[t.id] = {"chars": 0.0, "state": DIARY.State.OPEN, "mark": 0.0}
		var s: Dictionary = _shown[t.id]
		if s.chars < t.text.length():
			if int(s.chars) % SCRATCH_EVERY == 0 and int(s.chars + WRITE_CPS * delta) != int(s.chars):
				Sfx.play("pencil", -8.0)
			s.chars = minf(s.chars + WRITE_CPS * delta, t.text.length())
			queue_redraw()
			return
		if s.state != t.state:
			if t.state == DIARY.State.OPEN:   # (voltou a valer: só apaga)
				s.state = t.state
				continue
			if s.mark == 0.0:
				Sfx.play("pencil")
			var legs := 2.0 if t.state == DIARY.State.FAILED else 1.0
			s.mark += delta / (STRIKE_SEC * legs)
			if s.mark >= 1.0:
				s.state = t.state
				s.mark = 0.0
			queue_redraw()
			return
	set_process(folding)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		page_w = size.x / 2.0 - 30
		queue_redraw()
	elif what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT and _hover != -1:
		_hover = -1
		set_process(true)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h := _corner_at(e.position)
		var hot := h >= 0 or _letter_rect().has_point(e.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hot else Control.CURSOR_ARROW
		if h != _hover:
			_hover = h
			set_process(true)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var h := _corner_at(e.position)
		if _letter_rect().has_point(e.position):
			letter_open.emit(_letter_shown())
		elif h >= 0:
			var nights := _nights()
			var n: int = nights[nights.find(_night_shown()) + (1 if h == 1 else -1)]
			_at = -1 if n == night else n
			_hover = _corner_at(e.position)   # (na primeira ou na última, a dobra daquele lado some)
			Sfx.play("page")
			set_process(true)
			queue_redraw()


## As noites do diário, em ordem: as que passaram e a de hoje.
func _nights() -> Array:
	var out := pages.keys().filter(func(n: int) -> bool: return n < night)
	out.sort()
	return out + [night]


func _night_shown() -> int:
	return night if _at < 0 else _at


## A carta guardada na noite aberta (vazio: nenhuma).
func _letter_shown() -> String:
	return letter if _at < 0 else str(pages[_at].get("letter", ""))


## Onde está a ponta da carta guardada (vazio: nenhuma), no alto da página da direita.
func _letter_rect() -> Rect2:
	if _letter_shown() == "":
		return Rect2()
	return Rect2(LETTER_AT.position + Vector2(size.x, 0), LETTER_AT.size).intersection(Rect2(Vector2.ZERO, size))


## A dobra no ponto `p` (0 a de voltar, 1 a de avançar; -1 nenhuma): só a que tem página para aquele lado.
func _corner_at(p: Vector2) -> int:
	var nights := _nights()
	var i := nights.find(_night_shown())
	var r := FOLD_HOVER + 2.0
	if i > 0 and Rect2(0, size.y - r, r, r).has_point(p):
		return 0
	if i < nights.size() - 1 and Rect2(size.x - r, size.y - r, r, r).has_point(p):
		return 1
	return -1


## O canto dobrado de baixo (`side` 0, o da esquerda; 1, o da direita). No lugar do canto, a folha de baixo (com a
## pauta dela), mais escura junto do vinco; por cima da página, a ponta virada (o reflexo do canto no vinco), clara na
## ponta, que pega a luz, com a beira da folha e a sombra macia em volta. Medidas a partir da beira de fora (`o`) e de
## baixo (`r`), em px.
func _draw_fold(side: int) -> void:
	var f := int(roundf(_fold[side]))
	var pt := func(o: float, r: float) -> Vector2:
		return Vector2(o if side == 0 else size.x - o, size.y - r)
	var span := func(o: int, w: int, r: int, col: Color) -> void:   # `w` px a partir de `o`, na linha `r` (de baixo)
		if w > 0:
			draw_rect(Rect2(o if side == 0 else size.x - o - w, size.y - 1 - r, w, 1), col)
	for d in 2:   # a sombra da ponta na página, em volta das duas beiras dela
		var shade := Color(0, 0, 0, 0.16 - d * 0.08)
		span.call(0, f + 1 - d, f + d, shade)
		for r in f - d:
			span.call(f + d, 1, r, shade)
	var under: Array[Color] = [Pal.DIARY_PAGE, Pal.DIARY_UNDER, Pal.DIARY_UNDER]
	draw_primitive([pt.call(0, 0), pt.call(f, 0), pt.call(0, f)], under, [])
	var line := TOP + 3.0
	while line < size.y - 8:   # a pauta da folha de baixo (a da página começa a 10 px da beira de fora)
		var r := int(size.y - 1 - line)
		span.call(10, f - r - 10, r, Pal.PAPER_LINE)
		line += ROW
	for k in f:   # a beira das folhas de baixo, como a da página (2 px embaixo e na beira de fora)
		span.call(0, f - k if k < 2 else mini(2, f - k), k, Pal.INK_SOFT)
	var flap: Array[Color] = [Pal.DIARY_FLAP, Pal.DIARY_PAGE, Pal.DIARY_PAGE]
	draw_primitive([pt.call(f, f), pt.call(f, 0), pt.call(0, f)], flap, [])
	span.call(1, f - 1, f - 1, Pal.DIARY_EDGE)   # a beira da folha na ponta virada
	for r in range(1, f):
		span.call(f - 1, 1, r, Pal.DIARY_EDGE)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Pal.INK_SOFT)
	draw_rect(Rect2(Vector2.ZERO, size).grow(-2), Pal.DIARY_PAGE)
	var mid := floorf(size.x / 2.0)
	for i in 6:   # o miolo: a sombra das páginas entrando na costura
		draw_rect(Rect2(mid - 3 + i, 2, 1, size.y - 4), Color(0, 0, 0, 0.12 - absf(i - 2.5) * 0.03))
	var left := 14.0
	var right := mid + 16.0
	for x0 in [left, right]:   # a pauta
		var y := TOP
		while y < size.y - 8:
			draw_rect(Rect2(x0 - 4, y + 3, page_w + 8, 1), Pal.PAPER_LINE)
			y += ROW
	var d := GameData.date_of(_night_shown())
	_hand(Vector2(left, 24), T.text(T.Key.DIARY_DATE) % [T.text(GameData.WEEKDAYS[d.weekday]), d.day], -1)
	_head(left, TOP, T.Key.DIARY_TASKS)
	var list := tasks
	var written := notes
	if _at >= 0:   # uma noite que passou: como ficou, já escrita e riscada
		list = _past(pages[_at].get("tasks", []))
		written = _past(pages[_at].get("notes", []))
	var x0 := left
	var y := TOP
	for t in list:   # as que não cabem seguem na página da direita, e as anotações descem
		if x0 == left and y + (_lines(t).size() - 1) * ROW > size.y - 10:
			x0 = right
			y = TOP
		if y > size.y - 10:
			break
		y = _task(x0, y, t)
	y = TOP if x0 == left else y + 2 * ROW   # (uma pauta em branco antes)
	_head(right, y, T.Key.DIARY_NOTES)
	for t in written:
		if y > size.y - 10:
			break
		y = _task(right, y, t, false)
	if _letter_shown() != "":
		_draw_letter()
	var at := _nights().find(_night_shown())
	if at > 0:
		_draw_fold(0)
	if at < _nights().size() - 1:
		_draw_fold(1)


## O título da página, sublinhado, na pauta acima de `y`.
func _head(x0: float, y: float, key: T.Key) -> void:
	var head := T.text(key)
	_hand(Vector2(x0, y - ROW - 1), head, -1)
	draw_rect(Rect2(x0, y - ROW + 2, _w(head), 1), Pal.DIARY_HAND)


## O texto da tarefa (com quanto falta, já escrito) nas linhas da página.
func _lines(t: Dictionary) -> PackedStringArray:
	return _wrap(_full(t), page_w - INDENT)


func _full(t: Dictionary) -> String:
	var s := _seen(t)
	if int(s.chars) >= t.text.length() and t.state == DIARY.State.OPEN and t.left > 0:
		return t.text + " " + T.text(T.Key.DIARY_LEFT) % t.left
	return t.text


## O que da tarefa já está na página (a de uma aba, toda).
func _seen(t: Dictionary) -> Dictionary:
	if t.has("past"):
		return {"chars": float(t.text.length()), "state": t.state, "mark": 0.0}
	return _shown.get(t.id, {"chars": 0.0, "state": DIARY.State.OPEN, "mark": 0.0})


## As linhas guardadas de uma noite que passou (`Diary.page`), para desenhar como as de hoje.
func _past(saved: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in saved:
		out.append({"id": "", "text": DIARY.text_of(t), "left": t.left, "state": t.state, "past": true})
	return out


## A ponta da carta guardada entre as páginas, saindo por cima da da direita: a folha dobrada, com a sombra na página
## e as linhas da letra de Sebastião aparecendo.
func _draw_letter() -> void:
	var r := Rect2(LETTER_AT.position + Vector2(size.x, 0), LETTER_AT.size)
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color(0, 0, 0, 0.15))
	draw_rect(r, Pal.DIARY_EDGE)
	draw_rect(r.grow(-1), Pal.SHEET_NEW)
	draw_rect(Rect2(r.position.x + 1, r.position.y + 11, r.size.x - 2, 1), Pal.DIARY_UNDER)   # a dobra da carta
	for i in 3:
		var ly := r.position.y + 4 + i * 3 + (3 if i > 1 else 0)
		draw_rect(Rect2(r.position.x + 4, ly, r.size.x - 10 - (i % 2) * 7, 1), Color(Pal.DIARY_HAND, 0.5))


## Uma linha a partir da pauta `y`: o tracinho (ou o X) da tarefa (`mark`), o texto na largura da página e o risco;
## devolve a pauta seguinte.
func _task(x0: float, y: float, t: Dictionary, mark := true) -> float:
	var s := _seen(t)
	var full := _full(t)
	var written := full.length() if full != t.text else int(s.chars)
	var lines := _lines(t)
	var failing: bool = (s.state == DIARY.State.FAILED) or (t.state == DIARY.State.FAILED and s.mark > 0.0)
	var x_mark: float = 1.0 if s.state == DIARY.State.FAILED else (s.mark if t.state == DIARY.State.FAILED else 0.0)
	if failing:
		_cross(Vector2(x0, y - 7), x_mark)
	elif mark:
		draw_rect(Rect2(x0 + 1, y - 3, 5, 1), Pal.DIARY_HAND)
	var strike: float = 1.0 if s.state == DIARY.State.DONE else (s.mark if t.state == DIARY.State.DONE else 0.0)
	var total := 0
	for l: String in lines:
		total += l.length()
	var done := 0
	for i in lines.size():
		var l := lines[i]
		var at := x0 + (INDENT if mark or i == 0 else 0.0)   # (a anotação é um parágrafo: só a primeira linha recuada)
		var shown := clampi(written - done, 0, l.length())
		_hand(Vector2(at, y), l, shown)
		if strike > 0.0:   # o risco anda pelas linhas na ordem, como a mão
			var part := clampf((strike * total - done) / maxf(1.0, l.length()), 0.0, 1.0)
			_scribble(Vector2(at - 1, y - 4), (_w(l) + 2) * part)
		done += l.length()
		y += ROW
	return y


## Texto `s` na letra de mão (`Pal.hand`), as primeiras `n` letras (-1: todas), a partir da linha de base `at`: cada
## letra aperta mais ou menos o lápis, sempre do mesmo jeito (o `[hand]` do `paper_ink.gd`).
func _hand(at: Vector2, s: String, n: int) -> void:
	var x := at.x
	for i in (s.length() if n < 0 else mini(n, s.length())):
		var h := fposmod(sin(i * 12.9898 + 4.1) * 43758.5453, 1.0)
		x += Pal.hand.draw_char(get_canvas_item(), Vector2(x, at.y), s.unicode_at(i), 11, Color(Pal.DIARY_HAND, 0.78 + 0.22 * h))


## O risco a lápis por cima da linha, `w` px, subindo e descendo um pixel.
func _scribble(at: Vector2, w: float) -> void:
	var x := 0.0
	while x < w:
		draw_rect(Rect2(at.x + x, at.y + roundf(sin((at.x + x) * 0.21) * 0.7), minf(3.0, w - x), 1), Pal.DIARY_HAND)
		x += 3.0


## O X da tarefa perdida (7×7), as duas pernas traçadas em `part` (0 a 1).
func _cross(at: Vector2, part: float) -> void:
	for leg in 2:
		var p := clampf(part * 2.0 - leg, 0.0, 1.0)
		for i in roundi(7 * p):
			draw_rect(Rect2(at.x + (i if leg == 0 else 6 - i), at.y + i, 1, 1), Pal.DIARY_HAND)


## A largura de `s` na letra de mão.
func _w(s: String) -> float:
	return Pal.hand.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x


## Quebra `s` em linhas de até `w` px, nas palavras.
func _wrap(s: String, w: float) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in s.split(" "):
		if line != "" and _w(line + " " + word) > w:
			out.append(line)
			line = word
		else:
			line = word if line == "" else line + " " + word
	out.append(line)
	return out
