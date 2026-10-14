class_name ReportView
extends CenterContainer
## Relatório do supervisor no fim do turno, um memorando de verdade: papel timbrado da companhia (o fone e o nome em
## vermelho, o fio duplo), dobrado em três e com as fibras, o texto datilografado (`[typed]`, `PaperInk`), cada
## advertência com o carimbo da gravidade na cor dela (como os do caderno, a borracha falhando aqui e ali), o parecer
## escrito à mão pelo supervisor (`[hand]`, na caneta azul) e a rubrica dele. As manchetes não: o jornal da manhã já
## vem na mesa na noite seguinte.

signal closed

const SEVERITY_COLORS := ["4a4f5a", "8a5a14", "8a1a14", "5a0a40"]   ## a tinta de cada carimbo: grafite, sépia, vermelho, roxo
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
		_night.text = _ink(T.text(T.Key.REPORT_TRAINING) % [Main.fmt(0.0), Main.fmt(Main.SHIFT_END)])
	else:
		_night.text = _ink(T.text(T.Key.REPORT_NIGHT) % [r.night, Main.fmt(0.0), Main.fmt(Main.SHIFT_END)])
	var lines := 0
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
	_line(T.text(T.Key.REPORT_ACCUMULATED) % [r.severe_total(), ShiftReport.SEVERE_LIMIT])
	lines += 4   # (o jornal da manhã saiu: ele já vem na mesa na noite seguinte)
	%Scroll.custom_minimum_size.y = SCROLL_H if lines > MAX_LINES else 0.0   # a folha acompanha o texto: com poucas advertências, sem vão
	%Scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if lines > MAX_LINES else ScrollContainer.SCROLL_MODE_DISABLED
	var verdict: String = tr(C.verdicts[r.verdict()]) if r.verdict() < C.verdicts.size() else ""
	_verdict.text = "[hand]%s[/hand]" % verdict


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
