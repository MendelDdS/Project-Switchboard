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
	[T.Key.REPORT_EMERGENCIES, []], [T.Key.REPORT_OCCURRENCES, ["occurrence"]], [T.Key.REPORT_PRANKS, ["prank"]]]
## O carimbo do conceito (px): o raio, o aro de fora (2 px) e o de dentro (1 px), com o texto curvado entre eles (a
## fonte miúda em 2×, `STAMP_TEXT` linhas dela: na de 1×, curvada, as letras de 3 px se desfaziam), e a meia altura da
## faixa reta do meio, que atravessa os aros.
const STAMP_R := 56
const STAMP_OUTER := 54
const STAMP_INNER := 37
const STAMP_TEXT := 16
const STAMP_BAND := 8
const STAMP_STAR := ["..#..", "#####", ".###.", ".#.#.", "#...#"]
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
		var text := _line("%s  %s%s" % [f["time"], T.text(ShiftReport.FAULTS[f["id"]][1]), detail.replace("[", "(")], row)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(_stamp(ShiftReport.severity(f["id"])))
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
## entre estrelinhas em cima dela e a data da noite embaixo; na tinta do conceito, a borracha falhando (sempre igual na
## mesma noite). O que é pixel vem de uma imagem (`_stamp_image`), o conceito é texto por cima.
func _grade_stamp(r: ShiftReport) -> Control:
	var g := r.grade()
	var col := Color(GRADE_COLORS[g])
	var tex := ImageTexture.create_from_image(_stamp_image(r.night))
	var text := T.text(ShiftReport.GRADE_NAMES[g]).to_upper()
	var c := Control.new()
	c.custom_minimum_size = tex.get_size()
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		c.draw_texture(tex, Vector2.ZERO, Color(col, 0.85))
		var x := roundf((tex.get_width() - Pal.ui.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x) / 2.0)
		for dx in [0, 1]:   # 11 em negrito: a sombra de 1 px ao lado
			c.draw_string(Pal.ui, Vector2(x + dx, STAMP_R + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(col, 0.9)))
	return c


## Os pixels do carimbo do conceito (branco; a tinta vem no desenho): aros, faixa, texto curvado (a fonte miúda
## desenrolada em volta do círculo, `PixelArt.tiny`), "CONCEITO" com as estrelinhas e a data.
func _stamp_image(night: int) -> Image:
	var d := STAMP_R * 2 + 1
	var img := Image.create(d, d, false, Image.FORMAT_LA8)
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
				_ink_px(img, x, y, night)
	var label := PixelArt.tiny(T.text(T.Key.REPORT_GRADE)).get_image()
	var lx := STAMP_R - label.get_width() / 2
	var ly := STAMP_R - STAMP_BAND - 3 - 7   # o pé das letras (linha 7 da fonte) 3 px acima da faixa
	_blit(img, label, Vector2i(lx, ly), night)
	var star := PixelArt.art(STAMP_STAR, {"#": Color.WHITE}).get_image()
	_blit(img, star, Vector2i(lx - 8, ly + 3), night)
	_blit(img, star, Vector2i(lx + label.get_width() + 3, ly + 3), night)
	var day := GameData.date_of(night)
	var date := PixelArt.tiny("%02d·%02d·%d" % [day.day, day.month, day.year]).get_image()
	_blit(img, date, Vector2i(STAMP_R - date.get_width() / 2, STAMP_R + STAMP_BAND + 3 - 3), night)
	return img


## O texto curvado do carimbo: a fonte miúda em 2×, sem as linhas da cedilha.
func _stamp_strip(text: String) -> Image:
	var img := PixelArt.tiny(text).get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return img.get_region(Rect2i(0, 0, img.get_width(), STAMP_TEXT))


## Um pixel de tinta do carimbo, onde a borracha pegou.
func _ink_px(img: Image, x: int, y: int, night: int) -> void:
	if fposmod(sin((x * 131 + y * 17 + night * 7) * 7.13) * 917.3, 1.0) > 0.1:
		img.set_pixel(x, y, Color.WHITE)


func _blit(img: Image, src: Image, at: Vector2i, night: int) -> void:
	for y in src.get_height():
		for x in src.get_width():
			if src.get_pixel(x, y).a > 0.5:
				_ink_px(img, at.x + x, at.y + y, night)


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
	var p: PanelContainer = %Paper
	var sz := p.size
	var rng := RandomNumberGenerator.new()
	rng.seed = 1973
	for i in int(sz.x * sz.y / 900.0):
		p.draw_rect(Rect2(rng.randi_range(3, int(sz.x) - 5), rng.randi_range(3, int(sz.y) - 4), 2 if i % 3 == 0 else 1, 1), Pal.PAPER.darkened(0.1))
	for k in [1, 2]:
		var y := roundf(sz.y * k / 3.0)
		p.draw_rect(Rect2(1, y, sz.x - 2, 1), Color(1, 1, 1, 0.08))   # (mais fortes, pareciam o fio de uma tabela)
		p.draw_rect(Rect2(1, y + 1, sz.x - 2, 1), Color(0, 0, 0, 0.035))
