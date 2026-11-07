class_name ReportView
extends CenterContainer
## Relatório do supervisor no fim do turno, um memorando de verdade: papel timbrado da companhia (o fone e o nome em
## vermelho, o fio duplo), dobrado em três e com as fibras, o texto datilografado (`[typed]`, `PaperInk`), cada
## advertência com o carimbo da gravidade na cor dela (como os do caderno, a borracha falhando aqui e ali), o parecer
## escrito à mão pelo supervisor (`[hand]`, na caneta azul), a rubrica dele e, ao lado dela, o carimbo redondo do
## conceito do turno (`_grade_stamp`). Antes das advertências, os serviços prestados, contados (sem os pontos da conta
## do `ShiftReport`). As manchetes não: o jornal da manhã já vem na mesa na noite seguinte.

signal closed

const SEVERITY_COLORS := ["4a4f5a", "8a5a14", "8a1a14", "5a0a40"]   ## a tinta de cada carimbo: grafite, sépia, vermelho, roxo
const GRADE_COLORS := ["1f3a6b", "4a4f5a", "8a5a14", "8a1a14"]   ## a tinta do carimbo de cada conceito: azul, grafite, sépia, vermelho
## Os serviços prestados no memorando: a linha e os acertos (`ShiftReport.CREDITS`) que ela conta; as emergências vêm
## dos desfechos (a resolvida no estágio crítico não dá crédito, mas foi atendida).
const SERVICES := [[T.Key.REPORT_TRANSFERS, ["transfer"]], [T.Key.REPORT_TRUNKS, ["trunk"]], [T.Key.REPORT_INFOS, ["info"]],
	[T.Key.REPORT_EMERGENCIES, []], [T.Key.REPORT_OCCURRENCES, ["occurrence"]], [T.Key.REPORT_PRANKS, ["prank"]],
	[T.Key.REPORT_TAPES, ["tape"]]]
## O carimbo do conceito (px): o raio, o aro de fora (2 px) e o de dentro (1 px), com o texto curvado entre eles (a
## fonte miúda em 2×, `STAMP_TEXT` linhas dela: na de 1×, curvada, as letras de 3 px se desfaziam), e a meia altura da
## faixa reta do meio, que atravessa os aros.
const STAMP_R := 56
const STAMP_OUTER := 54
const STAMP_INNER := 37
const STAMP_TEXT := 16
const STAMP_BAND := 8
const STAMP_STAR := ["..#..", "#####", ".###.", ".#.#.", "#...#"]
const STAMP_TILT := 0.3        ## o giro máximo (rad, ~17°): torto como batido à mão, nunca de lado nem de cabeça para baixo
const STAMP_STRAIGHT := 0.35   ## a chance de sair reto
const STAMP_JITTER := 8.0      ## quanto ele sobe ou desce do meio do pé do memorando (px)
const MAX_LINES := 16   ## acima disso o texto rola numa altura fixa (`SCROLL_H`), para a folha caber na tela
const SCROLL_H := 230.0
const INK := preload("res://scripts/ui/paper_ink.gd")
## A rubrica do supervisor (px, dentro do `%Scribble`): o traço da assinatura e o risco embaixo dela.
const SCRIBBLE := [Vector2(14, 15), Vector2(18, 5), Vector2(22, 2), Vector2(24, 8), Vector2(19, 16), Vector2(27, 11), Vector2(33, 5),
	Vector2(36, 12), Vector2(41, 7), Vector2(44, 13), Vector2(50, 6), Vector2(54, 11), Vector2(60, 4), Vector2(63, 12), Vector2(70, 8),
	Vector2(80, 9), Vector2(95, 6), Vector2(108, 8)]
const FLOURISH := [Vector2(20, 19), Vector2(60, 18), Vector2(104, 16)]
## O fone da companhia no timbre (como o da capa da lista telefônica), em pixel art.
const EMBLEM := ["....######....", "..##########..", ".####....####.", ".###......###.", ".##........##.", "....######....",
	"...########...", "..##########..", "..###.##.###..", "..##########..", "..###.##.###..", "..##########..", "..##########.."]

var C: GameContent = GameData.CONTENT
var _typed := INK.new()
var _hand := INK.new()

@onready var _night: RichTextLabel = %Night
@onready var _body: VBoxContainer = %Body
@onready var _verdict: RichTextLabel = %Verdict
var _grade: Control   ## o carimbo do conceito, no pé do memorando


func _ready() -> void:
	_hand.bbcode = "hand"
	_night.install_effect(_typed)
	_verdict.install_effect(_hand)
	%Paper.draw.connect(_draw_paper)
	%Emblem.draw.connect(func(): %Emblem.draw_texture(PixelArt.art(EMBLEM, {"#": Pal.INK_RED}), Vector2(5, 5)))
	%Rule.draw.connect(func():
		%Rule.draw_rect(Rect2(0, 1, %Rule.size.x, 1), Pal.INK_RED)
		%Rule.draw_rect(Rect2(0, 3, %Rule.size.x, 1), Pal.INK_RED))
	%Scribble.draw.connect(func():
		%Scribble.draw_polyline(PackedVector2Array(SCRIBBLE), Pal.PEN, 1.0)
		%Scribble.draw_polyline(PackedVector2Array(FLOURISH), Color(Pal.PEN, 0.8), 1.0))
	%Sign.pressed.connect(func():
		Sfx.play("pencil")
		closed.emit())


func show_report(r: ShiftReport) -> void:
	for n in _body.get_children():
		n.queue_free()
	if r.night == 0:
		_night.text = _ink(T.text(T.Key.REPORT_TRAINING) % [Main.fmt(0.0), Main.fmt(r.end)])
	else:
		_night.text = _ink(T.text(T.Key.REPORT_NIGHT) % [r.night, Main.fmt(0.0), Main.fmt(r.end)])
	var lines := 0
	if r.night > 0:   # o treinamento não tem conceito
		lines += _services(r)
	_line("[u]%s[/u]" % T.text(T.Key.REPORT_WARNINGS))
	if r.faults.is_empty():
		_line(T.text(T.Key.REPORT_NONE))
	for f in r.faults:
		var detail: String = " — " + String(f["detail"]) if f["detail"] != "" else ""
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var text := _line("%s  %s%s" % [f["time"], ShiftReport.text_of(f), detail.replace("[", "(")], row)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(_stamp(ShiftReport.level(f)))
		_body.add_child(row)
		lines += 1
	_gap()
	_line("%s: %d   ·   %s: %d   ·   %s: %d   ·   %s: %d" % [T.text(T.Key.REPORT_CRITICAL), r.count(ShiftReport.Severity.CRITICAL),
		T.text(T.Key.REPORT_SEVERE), r.count(ShiftReport.Severity.SEVERE),
		T.text(T.Key.REPORT_MEDIUM), r.count(ShiftReport.Severity.MEDIUM), T.text(T.Key.REPORT_LIGHT), r.count(ShiftReport.Severity.LIGHT)])
	lines += 4   # (o jornal da manhã saiu: ele já vem na mesa na noite seguinte)
	if _grade:
		_grade.queue_free()
		_grade = null
	if r.night > 0:
		_gap()
		_line(T.text(T.Key.REPORT_GOAL) % T.text(ShiftReport.GRADE_NAMES[ShiftReport.GOAL]))
		if r.low_nights() > 0:
			_line(T.text(T.Key.REPORT_LOW) % [r.low_nights(), ShiftReport.LOW_LIMIT])
		lines += 3
		_grade = _grade_stamp(r)
		%Foot.add_child(_grade)
		%Foot.move_child(_grade, 1)
	%Scroll.custom_minimum_size.y = SCROLL_H if lines > MAX_LINES else 0.0   # a folha acompanha o texto: com poucas advertências, sem vão
	%Scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if lines > MAX_LINES else ScrollContainer.SCROLL_MODE_DISABLED
	var verdict: String = tr(C.verdict_fired) if r.fired() else tr(C.verdicts[r.grade()]) if r.grade() < C.verdicts.size() else ""
	_verdict.text = "[hand]%s[/hand]" % verdict


## Os serviços prestados, contados, em duas colunas como num formulário; devolve as linhas que ocupa.
func _services(r: ShiftReport) -> int:
	_line("[u]%s[/u]" % T.text(T.Key.REPORT_SERVICES))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	for s in SERVICES:
		var n: int = r.credits.filter(func(c): return c["id"] in s[1]).size()
		if s[1].is_empty():
			n = r.outcomes().values().filter(func(o): return o != ShiftReport.Outcome.BAD).size()
		if n > 0:
			var l := _line(T.text(s[0]) % n, grid)
			l.autowrap_mode = TextServer.AUTOWRAP_OFF   # (numa grade, com quebra, a coluna encolhia a nada)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rows := ceili(grid.get_child_count() / 2.0)
	if rows == 0:
		grid.free()
		_line(T.text(T.Key.REPORT_NONE_SERVICES))
	else:
		_body.add_child(grid)
	_gap()
	return 2 + maxi(rows, 1)


## O carimbo redondo do conceito, como o de inspeção de uma repartição: os dois aros, o nome da cidade curvado em
## cima e "SUPERVISÃO" embaixo, na fonte miúda em 2×, a faixa reta atravessando o meio com o conceito em 11 negrito, "CONCEITO"
## entre estrelinhas em cima dela e a data da noite embaixo; na tinta do conceito, a borracha falhando. Batido à mão
## (sorteado a cada memorando): em qualquer lugar do vão entre o botão e a rubrica, um pouco acima ou abaixo, e às
## vezes torto (`STAMP_TILT`), girado pixel a pixel (`PixelArt.turned`, o RotSprite dos plugs: girado pela
## transformação do desenho, serrilhava). Por isso o conceito também é pixel da imagem (`PixelArt.big`), não texto.
func _grade_stamp(r: ShiftReport) -> Control:
	var angle := 0.0 if randf() < STAMP_STRAIGHT else randf_range(-STAMP_TILT, STAMP_TILT)
	var turned := PixelArt.turned(_stamp_rows(r), angle, Vector2(STAMP_R + 0.5, STAMP_R + 0.5))
	var tex := ImageTexture.create_from_image(_stamp_image(turned[0], r.night))
	var col := Color(GRADE_COLORS[r.grade()], 0.85)
	var at := Vector2(randf(), randf_range(-STAMP_JITTER, STAMP_JITTER))
	var c := Control.new()
	c.custom_minimum_size = Vector2.ONE * (STAMP_R * 2 + 1)   # (o giro passa um pouco disso: é tinta no papel)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var free := c.size - tex.get_size()
		c.draw_texture(tex, Vector2(roundf(at.x * maxf(free.x, 0.0)), roundf(free.y / 2.0 + at.y)), col))
	return c


## O desenho do carimbo reto, como mapa de `PixelArt` ("#" é tinta): aros, faixa, texto curvado (a fonte miúda
## desenrolada em volta do círculo, `PixelArt.tiny`), o conceito, "CONCEITO" com as estrelinhas e a data.
func _stamp_rows(r: ShiftReport) -> Array:
	var d := STAMP_R * 2 + 1
	var buf := PackedByteArray()
	buf.resize(d * d)
	buf.fill(46)   # "."
	var top := _stamp_strip(CityMap.CITY)   # em cima, as letras com o pé para dentro
	var bottom := _stamp_strip(T.text(T.Key.REPORT_STAMP_DEPT))   # embaixo, com a cabeça para dentro
	var mid := float(STAMP_INNER + STAMP_OUTER) / 2.0
	for y in d:
		for x in d:
			var dx := x - STAMP_R
			var dy := y - STAMP_R
			var ri := roundi(sqrt(dx * dx + dy * dy))
			var ink := ri == STAMP_OUTER or ri == STAMP_OUTER + 1
			if absi(dy) <= STAMP_BAND:   # a faixa reta: por cima do aro de dentro e do texto
				ink = ink or absi(dy) == STAMP_BAND and ri < STAMP_OUTER
			elif ri == STAMP_INNER:
				ink = true
			elif ri > STAMP_INNER and ri < STAMP_OUTER:
				var a := atan2(dy, dx)
				var strip := top if dy < 0 else bottom
				var sx := floori((a + PI / 2.0 if dy < 0 else PI / 2.0 - a) * mid + strip.get_width() / 2.0)
				var sy := (STAMP_OUTER - 1 - ri) if dy < 0 else (ri - STAMP_INNER - 1)   # a linha 0 (os acentos): para fora em cima, para dentro embaixo
				ink = sx >= 0 and sx < strip.get_width() and sy >= 0 and sy < strip.get_height() and strip.get_pixel(sx, sy).a > 0.5
			if ink:
				buf[y * d + x] = 35   # "#"
	var grade_px: Array = PixelArt.big(T.text(ShiftReport.GRADE_NAMES[r.grade()]).to_upper(), 0)   # a fonte de 11, pixel a pixel
	var nw := (grade_px[0] as String).length()
	for y in grade_px.size():
		for x in nw:
			if grade_px[y][x] != ".":
				for bold in 2:   # 11 em negrito: a sombra de 1 px ao lado
					buf[(STAMP_R - grade_px.size() / 2 + y) * d + STAMP_R - (nw + 1) / 2 + x + bold] = 35
	var label := PixelArt.tiny(T.text(T.Key.REPORT_GRADE)).get_image()
	var lx := STAMP_R - label.get_width() / 2
	var ly := STAMP_R - STAMP_BAND - 3 - 7   # o pé das letras (linha 7 da fonte) 3 px acima da faixa
	_blit(buf, d, label, Vector2i(lx, ly))
	var star := PixelArt.art(STAMP_STAR, {"#": Color.WHITE}).get_image()
	_blit(buf, d, star, Vector2i(lx - 8, ly + 3))
	_blit(buf, d, star, Vector2i(lx + label.get_width() + 3, ly + 3))
	var day := GameData.date_of(r.night)
	var date := PixelArt.tiny("%02d·%02d·%d" % [day.day, day.month, day.year]).get_image()
	_blit(buf, d, date, Vector2i(STAMP_R - date.get_width() / 2, STAMP_R + STAMP_BAND + 3 - 3))
	var rows := []
	for y in d:
		rows.append(buf.slice(y * d, (y + 1) * d).get_string_from_ascii())
	return rows


## A tinta do carimbo já girado (branco; a cor vem no desenho), falhando onde a borracha não pegou (sempre igual na
## mesma noite e no mesmo giro).
func _stamp_image(rows: Array, night: int) -> Image:
	var img := Image.create((rows[0] as String).length(), rows.size(), false, Image.FORMAT_LA8)
	for y in rows.size():
		for x in (rows[y] as String).length():
			if rows[y][x] == "#" and fposmod(sin((x * 131 + y * 17 + night * 7) * 7.13) * 917.3, 1.0) > 0.1:
				img.set_pixel(x, y, Color.WHITE)
	return img


## O texto curvado do carimbo: a fonte miúda em 2×, sem as linhas da cedilha.
func _stamp_strip(text: String) -> Image:
	var img := PixelArt.tiny(text).get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return img.get_region(Rect2i(0, 0, img.get_width(), STAMP_TEXT))


## Os pixels de `src` como tinta no mapa `buf` (`d` de lado), a partir de `at`.
func _blit(buf: PackedByteArray, d: int, src: Image, at: Vector2i) -> void:
	for y in src.get_height():
		for x in src.get_width():
			if src.get_pixel(x, y).a > 0.5:
				buf[(at.y + y) * d + at.x + x] = 35


## O texto datilografado (`[typed]`).
func _ink(s: String) -> String:
	return "[typed]%s[/typed]" % s


## Uma linha datilografada no corpo do memorando (ou em `into`, a linha de uma advertência).
func _line(bb: String, into: Control = null) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("default_color", Pal.INK)
	l.install_effect(_typed)
	l.text = _ink(bb)
	(into if into else _body).add_child(l)
	return l


## Um respiro entre as partes do memorando (a linha vazia não tinha altura).
func _gap() -> void:
	var c := Control.new()
	c.custom_minimum_size.y = 8.0
	_body.add_child(c)


## O carimbo da gravidade `sev` (`ShiftReport.Severity`): a moldura de 2 px e o nome em maiúsculas na tinta dela, o
## fundo levemente tingido e a borracha falhando em alguns pontos da moldura, sempre os mesmos.
func _stamp(sev: int) -> Control:
	var c := Control.new()
	var text := T.text(ShiftReport.SEVERITY_NAMES[sev]).to_upper()
	c.custom_minimum_size = Vector2(Pal.ui.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12.0, 16)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.draw.connect(func():
		var col := Color(SEVERITY_COLORS[sev])
		var w := int(c.size.x)
		var h := int(c.size.y)
		c.draw_rect(Rect2(1, 1, w - 2, h - 2), Color(col, 0.08))
		var edge: Array[Rect2] = []   # a moldura, de pixel em pixel, falhando onde a borracha não pegou
		for x in w:
			edge.append_array([Rect2(x, 0, 1, 2), Rect2(x, h - 2, 1, 2)])
		for y in range(2, h - 2):
			edge.append_array([Rect2(0, y, 2, 1), Rect2(w - 2, y, 2, 1)])
		for i in edge.size():
			if fposmod(sin((i + sev * 31) * 7.13) * 917.3, 1.0) > 0.12:
				c.draw_rect(edge[i], Color(col, 0.85))
		c.draw_string(Pal.ui, Vector2(0, 12), text, HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color(col, 0.9)))
	return c


## O papel por baixo do texto: as fibras e as duas dobras do memorando dobrado em três (a de cima na luz, a de baixo
## na sombra), sempre as mesmas.
func _draw_paper() -> void:
	fibers(%Paper, %Paper.size, 2)


## As fibras do papel timbrado em `ci` (do tamanho `sz`), sempre as mesmas, e as `folds` dobras dele (o memorando,
## dobrado em três, tem duas; o bilhete do supervisor, `SupervisorNote`, nenhuma).
static func fibers(ci: CanvasItem, sz: Vector2, folds: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1973
	for i in int(sz.x * sz.y / 900.0):
		ci.draw_rect(Rect2(rng.randi_range(3, int(sz.x) - 5), rng.randi_range(3, int(sz.y) - 4), 2 if i % 3 == 0 else 1, 1), Pal.PAPER.darkened(0.1))
	for k in range(1, folds + 1):
		var y := roundf(sz.y * k / (folds + 1.0))
		ci.draw_rect(Rect2(1, y, sz.x - 2, 1), Color(1, 1, 1, 0.08))   # (mais fortes, pareciam o fio de uma tabela)
		ci.draw_rect(Rect2(1, y + 1, sz.x - 2, 1), Color(0, 0, 0, 0.035))
