class_name SupervisorNote
extends PanelContainer
## O recado do supervisor da noite num bilhete do papel timbrado do memorando (`ReportView`): o fone e o nome da
## companhia em vermelho, o fio duplo, a noite datilografada (`[typed]`), o recado à mão na caneta azul (`[hand]`,
## `PaperInk`), a rubrica dele e as fibras do papel; no alto, a tachinha com que ele fica pregado no quadro de avisos
## (`Background._draw_pinned_note`). O mesmo papel na tela de abertura (`Intro`, com os botões embaixo) e lido de novo
## pelo quadro (`Intro.reread`). No pé, à esquerda, o "Ciente" de Maria (`sign_field`): assinado, o turno começa.

signal signed

const INK := preload("res://scripts/ui/paper_ink.gd")
const TACK := 9   ## a tachinha no alto (px)

var _n := 0
var _night: Night
var _flags: StoryFlags
var _extra := PackedStringArray()   ## os parágrafos a mais (o aviso da noite decisiva, as fitas, o código), já traduzidos


func _ready() -> void:
	var hand := INK.new()
	hand.bbcode = "hand"
	%Date.install_effect(INK.new())
	%Text.install_effect(hand)
	%Emblem.draw.connect(func(): %Emblem.draw_texture(PixelArt.art(ReportView.EMBLEM, {"#": Pal.INK_RED}), Vector2(5, 5)))
	%Rule.draw.connect(func():
		%Rule.draw_rect(Rect2(0, 1, %Rule.size.x, 1), Pal.INK_RED)
		%Rule.draw_rect(Rect2(0, 3, %Rule.size.x, 1), Pal.INK_RED))
	%Scribble.draw.connect(func():
		%Scribble.draw_polyline(PackedVector2Array(ReportView.SCRIBBLE), Pal.PEN, 1.0)
		%Scribble.draw_polyline(PackedVector2Array(ReportView.FLOURISH), Color(Pal.PEN, 0.8), 1.0))
	resized.connect(queue_redraw)
	%Sign.signed.connect(signed.emit)


## Maria assina (o Enter da abertura).
func sign() -> void:
	%Sign.sign()


## O campo em branco, esperando a assinatura (`on`), ou já assinado (relendo no turno).
func blank(on: bool) -> void:
	%Sign.clear()
	if not on:
		%Sign.fill()


## O recado da noite `n` (`Night.note_for` pelos marcadores `flags`) e os parágrafos `extra`, depois dele (quem
## põe refaz ao trocar o idioma).
func write(n: int, night: Night, flags: StoryFlags, extra: PackedStringArray) -> void:
	_n = n
	_night = night
	_flags = flags
	_extra = extra
	_texts()


func _texts() -> void:
	var date: String
	if _n == 0:
		date = T.text(T.Key.INTRO_TRAINING) % [GameData.date_text(_n), Main.fmt(0.0)]
	else:
		var of := GameData.CONTENT.nights.size()   # "Noite 7 de 15" (a hora fica no relógio do turno); o epílogo, sem o "de"
		date = T.text(T.Key.INTRO_NIGHT_OF) % [_n, of, GameData.date_text(_n)] if _n <= of \
			else T.text(T.Key.INTRO_NIGHT) % [_n, GameData.date_text(_n), Main.fmt(0.0)]
	%Date.text = "[typed]%s[/typed]" % date
	var note := tr(_night.note_for(_flags))
	for p in _extra:
		note += "\n\n" + p
	%Text.text = "[hand]%s[/hand]" % note


## As fibras do papel (as do memorando, `ReportView.fibers`) e a tachinha vermelha no alto do meio, a do quadro.
func _draw() -> void:
	ReportView.fibers(self, size, 0)
	draw_texture(PixelArt.disc(TACK, [[4.0, Pal.POSTER_TACK[0], Pal.POSTER_TACK[1], Pal.POSTER_TACK[2]]]), Vector2(floorf((size.x - TACK) / 2.0), -3))
