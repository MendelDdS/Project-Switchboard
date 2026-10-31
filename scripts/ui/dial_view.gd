extends MarginContainer
## O discador da mesa de perto, num pop-up por cima do painel, logo acima do discador da prateleira (`Dialer`, que o
## abre e o põe no lugar; a lista e as outras ferramentas continuam abertas ao lado): a chapa oliva do painel com, à
## esquerda, o visor (a tela do console, `HudPanel`, com os algarismos em sete segmentos no verde da fala do operador,
## os apagados bem fracos, e embaixo o que está acontecendo, `Dialing.TEXT`) e a lâmpada de linha (como as do painel:
## âmbar piscando chamando, verde em conversa, vermelha no ocupado e nos avisos); à direita, o teclado nas teclas do
## console sem etiqueta (`KeyCapStyle.tag`): Discar verde e Encerrar vermelha, com o fone desenhado. Só o clique: o
## teclado do computador fica com as ferramentas. O visor e a lâmpada só se redesenham quando o que mostram muda
## (`_look`); a piscada vai no `modulate`.

const Dialing := preload("res://scripts/dialing.gd")
const SEG := {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc",
	"8": "abcdefg", "9": "abcdfg"}
const CELL := Vector2(12, 20)   ## cada algarismo do visor...
const STROKE := 3               ## ...a grossura do segmento...
const GAP := 5.0                ## ...e o vão entre eles
const INK: Color = ConsoleMini.INK["op"]   ## o verde da fala do operador nas telas
const GHOST := 0.07             ## os segmentos apagados, quase sumindo no vidro
const BLINK := 0.5              ## s: a lâmpada acesa, depois apagada, chamando
const FAIL_SEC := 4.0           ## s: a lâmpada vermelha dos avisos (ocupado, não atende...)
## O fone desenhado em Discar (fora do gancho) e em Encerrar (no gancho).
const HANDSET := {"up": [".##.....", "###.....", "##......", "##......", "###.....", ".###..##", "..######", "....###."],
	"down": ["##....##", "########", "##....##", "........", ".######."]}

var dialing: Dialing   ## o Main liga
var _look := []

@onready var _readout: Control = %Readout
@onready var _lamp: Control = %Lamp
@onready var _keys: GridContainer = %Keys


func _ready() -> void:
	_readout.draw.connect(_draw_readout)
	_lamp.draw.connect(_draw_lamp)
	for b: Button in _keys.get_children():
		match b.name:
			"Dial":
				b.pressed.connect(func(): dialing.dial())
			"End":
				b.pressed.connect(func(): dialing.end())
			_:
				b.pressed.connect(func(): dialing.press(b.text))
	(%Keys/Dial as Button).icon = PixelArt.art(HANDSET["up"], {"#": get_theme_color("font_color", "CallKey")})
	(%Keys/End as Button).icon = PixelArt.art(HANDSET["down"], {"#": get_theme_color("font_color", "EndKey")})


func _process(_delta: float) -> void:
	if dialing == null or not is_visible_in_tree():
		return
	var talk := int(dialing.main.talk_clock - dialing.since) if dialing.status == Dialing.Status.TALK else 0
	var look := [dialing.digits, dialing.status, talk, _lamp_color()]
	if look != _look:
		_look = look
		_readout.queue_redraw()
		_lamp.queue_redraw()
		queue_redraw()
	var calling := dialing.status == Dialing.Status.CALLING
	_lamp.modulate.a = 1.0 if not calling or fmod(dialing.main.talk_clock - dialing.since, BLINK * 2.0) < BLINK else 0.25


## A chapa oliva do painel atrás do visor e do teclado, de cantos redondos, com a beira na luz no alto e na sombra
## embaixo, e a sombra dela no painel (embaixo e à direita, como a do discador da prateleira).
func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size - Vector2.ONE)
	Switchboard.round_rect(self, Rect2(Vector2.ONE, r.size), Color(0, 0, 0, 0.35))
	Switchboard.round_rect(self, r, Pal.BOARD_INSET)
	Switchboard.round_rect(self, r.grow(-1), Pal.BOARD_FACE)
	draw_rect(Rect2(r.position.x + 4, r.position.y + 1, r.size.x - 8, 1), Pal.BOARD_METAL[5])
	draw_rect(Rect2(r.position.x + 4, r.end.y - 2, r.size.x - 8, 1), Pal.BOARD_METAL[1])


## Os algarismos em sete segmentos (os apagados fracos, por trás; os acesos com um fio de brilho em volta) e, embaixo,
## o que está acontecendo: chamando, em linha com o tempo de conversa, os avisos.
func _draw_readout() -> void:
	if dialing == null:
		return
	var at := Vector2(roundf((_readout.size.x - Dialing.DIGITS * (CELL.x + GAP) + GAP) / 2.0), 4.0)
	for i in Dialing.DIGITS:
		var o := at + Vector2(i * (CELL.x + GAP), 0)
		var on: String = SEG.get(dialing.digits[i], "") if i < dialing.digits.length() else ""
		for s in "abcdefg":
			if not s in on:
				_segment(o, s, Color(INK, GHOST))
		for s in on:
			_segment(o, s, Color(INK, 0.22), 1)
		for s in on:
			_segment(o, s, INK)
	var say := ""
	if dialing.status in Dialing.TEXT:
		say = T.text(Dialing.TEXT[dialing.status])
	if dialing.status == Dialing.Status.TALK:
		var sec := int(dialing.main.talk_clock - dialing.since)
		say += "  %02d:%02d" % [sec / 60, sec % 60]
	for dx in 2:   # embaixo dos algarismos, no meio (em negrito, como o `InkBoldLabel`: fino, sumia no vidro)
		_readout.draw_string(Pal.mono, Vector2(dx, at.y + CELL.y + 13.0), say, HORIZONTAL_ALIGNMENT_CENTER, _readout.size.x - 1.0, 11, INK)


## Um segmento `s` do algarismo na célula `o`, com as pontas chanfradas (um pixel a menos de cada lado na beira),
## crescido `grow` px (o brilho).
func _segment(o: Vector2, s: String, col: Color, grow := 0) -> void:
	var w := CELL.x
	var h := CELL.y
	var t := float(STROKE)
	var half := roundf((h - t) / 2.0)
	var r: Rect2
	var flat := s in "adg"
	match s:
		"a":
			r = Rect2(o.x + 2, o.y, w - 4, t)
		"g":
			r = Rect2(o.x + 2, o.y + half, w - 4, t)
		"d":
			r = Rect2(o.x + 2, o.y + h - t, w - 4, t)
		"f":
			r = Rect2(o.x, o.y + 2, t, half)
		"b":
			r = Rect2(o.x + w - t, o.y + 2, t, half)
		"e":
			r = Rect2(o.x, o.y + half + 2, t, h - half - 4)
		"c":
			r = Rect2(o.x + w - t, o.y + half + 2, t, h - half - 4)
	r = r.grow(grow)
	if flat:   # (a ponta em bisel: a linha do meio inteira, as de fora um pixel mais curtas de cada lado)
		_readout.draw_rect(Rect2(r.position.x + 1, r.position.y, r.size.x - 2, r.size.y), col)
		_readout.draw_rect(Rect2(r.position.x, r.position.y + 1, 1, r.size.y - 2), col)
		_readout.draw_rect(Rect2(r.end.x - 1, r.position.y + 1, 1, r.size.y - 2), col)
	else:
		_readout.draw_rect(Rect2(r.position.x, r.position.y + 1, r.size.x, r.size.y - 2), col)
		_readout.draw_rect(Rect2(r.position.x + 1, r.position.y, r.size.x - 2, 1), col)
		_readout.draw_rect(Rect2(r.position.x + 1, r.end.y - 1, r.size.x - 2, 1), col)


## A cor da lâmpada de linha agora (transparente: apagada).
func _lamp_color() -> Color:
	match dialing.status:
		Dialing.Status.CALLING:
			return Pal.AMBER
		Dialing.Status.TALK:
			return Pal.GREEN
		Dialing.Status.IDLE, Dialing.Status.ENDED:
			return Color.TRANSPARENT
	return Pal.RED if dialing.main.talk_clock - dialing.since < FAIL_SEC else Color.TRANSPARENT


## A lâmpada de linha, como as do painel: o aro creme e o vidro leitoso; acesa, toda de uma cor, com o halo em volta.
func _draw_lamp() -> void:
	if dialing == null:
		return
	var c := (_lamp.size / 2.0).floor()
	var s := Pal.SHELL
	PixelArt.sprite(_lamp, PixelArt.disc(14, [[5.0, s[6], s[4], s[2]], [6.5, s[3], s[1], s[0]]]), c)
	var col := _lamp_color()
	var glass := Pal.LAMP_GLASS if col.a == 0.0 else col
	PixelArt.sprite(_lamp, PixelArt.disc(10, [[3.5, glass.lightened(0.2), glass, glass.darkened(0.25)]]), c)
	if col.a > 0.0:
		PixelArt.sprite(_lamp, PixelArt.disc(18, [[8.5, Color(col, 0.25), Color(col, 0.18), Color(col, 0.1)]]), c)
		PixelArt.sprite(_lamp, PixelArt.disc(4, [[1.5, col.lightened(0.5)]]), c - Vector2(1, 1))
