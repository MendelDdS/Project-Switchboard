extends Control
## O canto esquerdo da mesa comutadora visto de perto, à direita da tela inicial (`title_screen.gd`): a moldura creme
## de canto redondo, a faixa das entradas, as plaquinhas, as lâmpadas, as tomadas e as teclas das primeiras linhas e o
## FONE encaixado na entrada 1, com o fio caindo para fora da tela. As peças da mesa (`Switchboard`) em `S` vezes o
## tamanho, cada uma refeita pixel a pixel com mais detalhe (ampliada pela transformação, a pixel art viraria blocos
## de 3 px ao lado dos de 1 px da fonte). No pé, as chapas dos bancos A e B (setores que o operador ainda não atende).
## Só redesenha quando o idioma muda (as legendas); as lâmpadas acesas ficam cada uma numa camada (`_lit`), pelo
## `modulate`: a do FONE pulsando como uma linha que chama, como no começo do treinamento, até o jogo começar
## (`fone_on`), e a da linha que toca de vez em quando (`ringing`).

const S := 3.0   ## quantas vezes maior que no painel da mesa
const OUTER := Rect2(20, 14, 640, 660)   ## a moldura de fora (passa da direita e de baixo da tela)
const FRAME := 15.0   ## a moldura de esmalte em volta do painel
const SHELL_R := 36.0   ## o raio do canto de fora da moldura (o do painel, por dentro, `SHELL_R - FRAME`)
const COL0 := 95.0   ## o meio da coluna da linha 1...
const PITCH := 99.0   ## ...e de uma coluna à outra
const COLS := 5
const SIZE := Vector2i(520, 540)   ## o tamanho dela na tela (as imagens se montam no `_ready`, antes do layout)
const Y := {"header": 32.0, "plate": 92.0, "lamp": 143.0, "in": 191.0, "key": 239.0, "out": 287.0, "rule": 341.0, "bank": 380.0}
const BANK_W := 340.0   ## a chapa de um banco (a da mesa em 3×); a do B começa `BANK_GAP` depois, cortada na beira
const BANK_GAP := 13.0
const PANEL := preload("res://scripts/ui/switchboard_panel.gd")   ## (as letras das chapas, `PLATE_LETTERS`)
const LIGHT := Vector2(0.7071, -0.7071)   ## a luz vem do alto à direita, como na mesa (`Switchboard.LIGHT`)
const LIT_LINE := 1   ## a linha do FONE, com a lâmpada acesa (em linha)
const LAMP_ON_SEC := 0.06   ## a lâmpada acende quase na hora e apaga devagar, como na mesa (`Switchboard.LAMP_*`)
const LAMP_OFF_SEC := 0.18
const CORD_END := 580.0   ## o fio do FONE cai reto da boca do plug até esta altura, fora da tela
## O FONE (`_fone_art`), as medidas do plug encaixado da mesa (`Switchboard.ELBOW_*`) em 3×:
const TILT := Vector2(0.6, -0.08)   ## px na tela por px de distância do painel: quem olha está na frente da tela,
## à esquerda do painel e um pouco abaixo, e vê o plug pelo lado esquerdo (o cotovelo pende para a direita)
const PLUG_R := 10.0   ## o raio do tubo (mais fino que o aro da tomada, como no jogo)
const SLEEVE_R := 9.0   ## o da ponta de metal: o do furo da tomada (`Switchboard.JACK_RINGS[0]` em 3×)
const PLUG_BODY := 24.0   ## do painel até o fim do corpo duro (curto: a cabeça lisa logo vira a dobra)
const BAND := Vector2(7.5, 13.5)   ## a faixa na cor do cabo, no corpo (px do painel)
const PLUG_ARC := 15.0   ## o raio do eixo no cotovelo
const COIL := 5.0   ## o passo dos anéis da mola do cotovelo...
const COIL_DEPTH := 2.5   ## ...e a fundura do sulco entre eles
const COILS_DOWN := 4   ## anéis da mola que seguem da dobra para a capa
const COLLAR := 28.0   ## o colarinho liso no fim da mola, afunilando até a boca do fio...
const TIP_R := 7.0   ## ...onde o raio é este (pouco mais que o fio)
const PLUG_BOOT := COIL * COILS_DOWN + COLLAR   ## da dobra até a boca do fio
const CORD_R := 5.5   ## a metade da largura do fio (um pouco mais que no jogo, onde tem uns 3 px)

var _shell: ImageTexture
var _fone: ImageTexture
var _shade: GradientTexture2D
var _glow: GradientTexture2D
var _notice := {}   ## o aviso da chapa em 3×, pelo texto (o idioma)
var _lit := {}   ## linha -> a camada da cúpula acesa (quanto está acesa, 0..1, no `modulate`)
var fone_on := true   ## a linha do FONE chamando, como no começo do treinamento (apaga quando o jogo começa)
var ringing := 0   ## a linha tocando (0 = nenhuma)


func _ready() -> void:
	_shell = _shell_art()
	_fone = _fone_art()
	_shade = _light_art()
	_glow = GradientTexture2D.new()   # (feita aqui: criada no `_draw`, ainda não estava pronta e saía um quadrado branco)
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(0.5, 0.0)
	_glow.gradient = Gradient.new()
	_glow.gradient.set_color(0, Color(Pal.AMBER, 0.45))
	_glow.gradient.set_color(1, Color(Pal.AMBER, 0.0))
	for n in range(1, COLS + 1):   # a cúpula acesa de cada lâmpada numa camada própria: pisca pelo `modulate`, sem redesenhar
		var lit := Control.new()
		lit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lit.modulate.a = 0.0
		lit.draw.connect(_draw_lit.bind(lit, Vector2(COL0 + PITCH * (n - 1), Y["lamp"])))
		add_child(lit)
		_lit[n] = lit


func _process(delta: float) -> void:
	var blink := (PixelArt.ms() / 250) % 2 == 0   # o toque, como `Switchboard._lamp` (RING)
	for n: int in _lit:
		var want := 1.0 if ((n == LIT_LINE and fone_on) or n == ringing) and blink else 0.0
		var lit: Control = _lit[n]
		lit.modulate.a = move_toward(lit.modulate.a, want, delta / (LAMP_ON_SEC if want > lit.modulate.a else LAMP_OFF_SEC))


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	var inner := OUTER.grow(-FRAME)
	draw_rect(inner, Pal.BOARD_FACE)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 3)), Pal.BOARD_METAL[1])   # rebaixado: a sombra em cima e à esquerda
	draw_rect(Rect2(inner.position, Vector2(3, inner.size.y)), Pal.BOARD_METAL[1])
	draw_texture(_shell, Vector2.ZERO)
	_draw_header(inner)
	_groove(Rect2(inner.position.x + 9, Y["key"] - 1, size.x, 3), true)   # a faixa das chaves de escuta, atrás delas
	for i in COLS:
		_draw_column(i)
	_draw_rule(inner, Y["rule"], T.text(T.Key.BOARD_OUTPUTS))
	_inset(Rect2(inner.position.x + 12, Y["bank"], size.x, size.y), 6.0)   # o alto do primeiro banco, sumindo no escuro
	for i in 2:   # as chapas dos bancos A e B (a do B cortada na beira da tela)
		_draw_bank_plate(Rect2(inner.position.x + 22 + (BANK_W + BANK_GAP) * i, Y["bank"] + 10, BANK_W, size.y), "AB"[i])
	draw_texture(_fone, Vector2.ZERO)
	draw_texture_rect(_shade, Rect2(Vector2.ZERO, size), false)


## A faixa escura do alto, com o nome das entradas e a legenda das lâmpadas (cortada na beira da tela, como o resto).
func _draw_header(inner: Rect2) -> void:
	var r := Rect2(inner.position.x + 9, Y["header"], size.x, 32)
	_rounded(r, 6.0, Pal.BOARD_STRIP)
	draw_rect(Rect2(r.position.x + 4, r.end.y, r.size.x, 1), Pal.BOARD_METAL[5])   # a beira de baixo, na luz
	var y := r.get_center().y
	var x := r.position.x + 15.0
	x += _text(T.text(T.Key.BOARD_INPUTS), x, y, Pal.BOARD_INK) + 36.0
	for item in [[Pal.AMBER, T.Key.LEGEND_RING], [Pal.GREEN, T.Key.LEGEND_CONN]]:
		var c := Vector2(x, y)
		PixelArt.sprite(self, PixelArt.disc(19, [[6.0, Color.WHITE], [9.5, Pal.SHELL[6], Pal.SHELL[4], Pal.SHELL[2]]], LIGHT), c)
		PixelArt.sprite(self, PixelArt.disc(19, [[3.0, Color.WHITE], [6.0, Color(1, 1, 1, 0.82)]], LIGHT), c, item[0])
		x += 16.0 + _text(T.text(item[1]), x + 16.0, y, Pal.BOARD_INK) + 30.0


## Uma legenda do painel em maiúsculas, na fonte do jogo em dobro com o detalhe de 1 px (`PixelArt.big`), à altura das
## letras miúdas da mesa (`PixelArt.tiny`) em 3×; a partir de `x`, centrada em `cy`. Devolve a largura.
func _text(t: String, x: float, cy: float, col: Color) -> float:
	var tex := PixelArt.art(PixelArt.big(t.to_upper(), 1), {"*": col})
	draw_texture(tex, Vector2(roundf(x), roundf(cy - tex.get_height() / 2.0)))
	return tex.get_width()


## Uma coluna de linha: o trilho, a plaquinha do número, a lâmpada, a entrada, a tecla de escuta e a saída.
func _draw_column(i: int) -> void:
	var x := COL0 + PITCH * i
	_groove(Rect2(x - 1, Y["plate"] + 20, 3, Y["out"] - Y["plate"] - 20), false)
	_draw_plate(Vector2(x, Y["plate"]), "%02d" % (i + 1))
	_draw_lamp(Vector2(x, Y["lamp"]))
	_draw_jack(Vector2(x, Y["in"]), 0.0)
	_draw_key(Vector2(x, Y["key"]))
	_draw_jack(Vector2(x, Y["out"]), 0.22)   # as saídas mais escuras, como na mesa


## Um sulco no painel (o trilho das colunas, a faixa das teclas): a sombra de um lado, o fundo e a luz do outro.
func _groove(r: Rect2, across: bool) -> void:
	if across:
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Pal.BOARD_METAL[1])
		draw_rect(Rect2(r.position.x, r.position.y + 1, r.size.x, 1), Pal.BOARD_METAL[2])
		draw_rect(Rect2(r.position.x, r.position.y + 2, r.size.x, 1), Pal.BOARD_METAL[5])
	else:
		draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Pal.BOARD_METAL[1])
		draw_rect(Rect2(r.position.x + 1, r.position.y, 1, r.size.y), Pal.BOARD_METAL[2])
		draw_rect(Rect2(r.position.x + 2, r.position.y, 1, r.size.y), Pal.BOARD_METAL[5])


## A plaquinha creme com o número da linha impresso, embutida no painel.
func _draw_plate(c: Vector2, text: String) -> void:
	var r := Rect2((c - Vector2(39, 19)).round(), Vector2(78, 38))
	_rounded(r.grow(1), 5.0, Pal.BOARD_METAL[0])
	_rounded(r, 4.0, Pal.BOARD_TAG)
	draw_rect(Rect2(r.position.x + 3, r.position.y, r.size.x - 6, 1), Pal.BOARD_TAG.lightened(0.18))
	draw_rect(Rect2(r.position.x + 3, r.end.y - 1, r.size.x - 6, 1), Pal.BOARD_TAG.darkened(0.2))
	draw_rect(Rect2(r.position.x + 1, r.end.y - 2, r.size.x - 2, 1), Pal.BOARD_TAG.darkened(0.1))
	var rows := PixelArt.big(text, 1)
	PixelArt.sprite(self, PixelArt.art(rows, {"*": Pal.ENGRAVED}), r.get_center() + Vector2(0, 1))


## A lâmpada da linha: o aro creme, a beira dele por dentro e a cúpula de vidro leitoso, apagada (a acesa fica por
## cima, na camada dela, `_draw_lit`).
func _draw_lamp(c: Vector2) -> void:
	PixelArt.sprite(self, PixelArt.disc(36, [[17.0, Color(0, 0, 0, 0.3)]], LIGHT), c + Vector2(-2, 2))   # a sombra no painel
	PixelArt.sprite(self, PixelArt.disc(34, [[11.0, Color.TRANSPARENT], [12.5, Pal.SHELL[2], Pal.SHELL[3], Pal.SHELL[5], true],
		[15.5, Pal.SHELL[7], Pal.SHELL[5], Pal.SHELL[3]], [17.0, Pal.SHELL[4], Pal.SHELL[3], Pal.SHELL[1]]], LIGHT), c)
	_dome(self, c, Pal.LAMP_GLASS, 0.35)


## A cúpula acesa da lâmpada em `c`, na camada `ci`, com a luz lisa em volta, sem degraus.
func _draw_lit(ci: CanvasItem, c: Vector2) -> void:
	_dome(ci, c, Pal.AMBER, 0.6)
	ci.draw_texture_rect(_glow, Rect2(c - Vector2(48, 48), Vector2(96, 96)), false)


## A cúpula de vidro leitoso na cor `g`, com o reflexo `shine` mais claro.
static func _dome(ci: CanvasItem, c: Vector2, g: Color, shine: float) -> void:
	PixelArt.sprite(ci, PixelArt.disc(24, [[11.0, g.lightened(0.1), g, g.darkened(0.22)]], LIGHT), c)
	PixelArt.sprite(ci, PixelArt.disc(24, [[7.0, g.lightened(0.18), g.lightened(0.06), g.darkened(0.06)]], LIGHT), c + Vector2(1, -1))
	PixelArt.sprite(ci, PixelArt.disc(4, [[2.0, g.lightened(shine)]]), c + Vector2(4, -5))   # o reflexo no vidro


## A chapa sobre um banco, como na mesa (`Switchboard._draw_plate`): oliva-acinzentada, a beira de cima na luz e a
## de baixo na sombra, a letra estampada em relevo no meio e, embaixo dela, o aviso pintado com estêncil, já gasto.
func _draw_bank_plate(r: Rect2, letter: String) -> void:
	_rounded(r.grow(1), 7.0, Pal.BANK_PLATE.darkened(0.5))
	_rounded(r, 6.0, Pal.BANK_PLATE)
	draw_rect(Rect2(r.position.x + 4, r.position.y, r.size.x, 1), Pal.BANK_PLATE.lightened(0.18))
	draw_rect(Rect2(r.position.x + 2, r.position.y + 1, r.size.x, 1), Pal.BANK_PLATE.lightened(0.08))
	var rows := _tripled(PixelArt.relief(PANEL.PLATE_LETTERS[letter]))   # a letra estampada da mesa, em 3×
	var at := Vector2(r.get_center().x, r.position.y + 74)   # (as alturas da mesa em 3×)
	PixelArt.sprite(self, PixelArt.art(rows, {"*": Pal.BANK_PLATE.darkened(0.45)}), at + Vector2(3, 3))
	PixelArt.sprite(self, PixelArt.art(rows, {"u": Pal.BANK_PLATE.lightened(0.35), "d": Pal.BANK_PLATE.darkened(0.2), "+": Pal.BANK_PLATE.lightened(0.15)}), at)
	var key := T.text(T.Key.BOARD_PLATE_NOTICE)
	if not _notice.has(key):   # o aviso em estêncil, nas letras miúdas da mesa (`PixelArt.tiny`) em 3×, guardado
		var img := PixelArt.tiny(key).get_image()
		img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
		_notice = {key: ImageTexture.create_from_image(img)}
	var notice: ImageTexture = _notice[key]
	draw_texture(notice, (Vector2(at.x, r.position.y + 132) - notice.get_size() / 2.0).round(), Color(Pal.STENCIL, 0.85))


## O mapa `rows` (de `PixelArt.relief`/`art`) com cada caractere em 3×3: a peça da mesa no tamanho do painel de perto.
static func _tripled(rows: Array) -> Array:
	var out := []
	for row: String in rows:
		var line := ""
		for ch in row:
			line += ch.repeat(3)
		out.append_array([line, line, line])
	return out


## A tomada de perto: a sombra curta no painel, o aro cromado (`_jack_art`) e o brilho no alto à direita.
func _draw_jack(c: Vector2, dim: float) -> void:
	PixelArt.sprite(self, PixelArt.disc(36, [[17.5, Color(0, 0, 0, 0.3)]]), c + Vector2(-2, 2))
	PixelArt.sprite(self, _jack_art(dim), c)
	draw_rect(Rect2(c + Vector2(6, -11), Vector2(2, 1)), Color(Pal.JACK_METAL["face"][0], 0.9 - dim))
	draw_rect(Rect2(c + Vector2(8, -10), Vector2(1, 1)), Color(Pal.JACK_METAL["face"][0], 0.7 - dim))


## O aro da tomada, pixel a pixel (a do painel, `Switchboard._jack_tex`, em 3×, com o que não cabia em 12 px): o furo
## com a mola de contato lá dentro, a parede da bucha (côncava: pega a luz do outro lado), a face e a descida até o
## painel. Guardado por `dim`.
static var _jacks := {}
static func _jack_art(dim: float) -> ImageTexture:
	if _jacks.has(dim):
		return _jacks[dim]
	var d := 36
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	for y in d:
		for x in d:
			var o := Vector2(x + 0.5, y + 0.5) - Vector2(d, d) / 2.0
			var r := o.length()
			var lit := o.normalized().dot(LIGHT) if r > 0.01 else 0.0
			var col := Color.TRANSPARENT
			if r <= 5.0:
				col = Pal.JACK_HOLE
			elif r <= 6.5:   # a mola de contato, no fundo do furo, quase sem luz
				col = Pal.JACK_HOLE.lerp(Pal.JACK_METAL["wall"][4] if lit < 0.0 else Pal.JACK_METAL["wall"][3], 0.5)
			elif r <= 8.5:
				col = Pal.JACK_HOLE.lightened(0.04)
			elif r <= 17.5:
				var face := r > 11.5
				var ramp: Array = Pal.JACK_METAL["face" if face else "wall"]
				var t := lit if face else -lit
				var k := int((1.0 - t) / 2.0 * ramp.size()) + (2 if r > 15.5 else 0)
				if face and r > 11.5 and r <= 12.5:
					k += 1   # a quina entre a bucha e a face
				col = (ramp[clampi(k, 0, ramp.size() - 1)] as Color).darkened(dim)
			img.set_pixel(x, y, col)
	_jacks[dim] = ImageTexture.create_from_image(img)
	return _jacks[dim]


## A tecla de escuta solta, no rebaixo dela: a base e o tampo menor (a tecla afunila), com as laterais à mostra e a
## sombra embaixo à esquerda (a da mesa, `Switchboard._key_cap`, em 3×).
func _draw_key(c: Vector2) -> void:
	var well := Rect2(c - Vector2(15, 15), Vector2(30, 30))
	_rounded(well, 2.0, Pal.BOARD_INSET)
	draw_rect(Rect2(well.position.x + 1, well.end.y, well.size.x - 1, 1), Pal.BOARD_METAL[5])
	draw_rect(Rect2(well.end.x, well.position.y + 1, 1, well.size.y), Pal.BOARD_METAL[5])
	PixelArt.sprite(self, _key_art(), c)


static var _key: ImageTexture
static func _key_art() -> ImageTexture:
	if _key:
		return _key
	var k := Pal.KEY_CAP
	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	var base := Rect2i(8, 8, 24, 24)
	var top := Rect2i(11, 5, 18, 18)   # 6 px acima da base: a tecla solta
	var layers := []
	for i in 13:
		var f := i / 12.0
		layers.append(Rect2i(Vector2(base.position).lerp(Vector2(top.position), f).round(), Vector2(base.size).lerp(Vector2(top.size), f).round()))
	for r: Rect2i in layers:
		img.fill_rect(Rect2i(r.position + Vector2i(-2, 2), r.size), Color(0, 0, 0, 0.35))   # a sombra
	for r: Rect2i in layers:
		img.fill_rect(r, k[1])   # a frente e a esquerda
		img.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, 1), k[2])   # a de trás
		img.fill_rect(Rect2i(r.end.x - 1, r.position.y, 1, r.size.y - 1), k[2])   # a direita, para a luz
	img.fill_rect(Rect2i(base.position.x, base.end.y - 1, base.size.x, 1), k[0])   # o pé, rente ao rebaixo
	img.fill_rect(top, k[3])
	img.fill_rect(top.grow(-3), k[3].lerp(k[2], 0.35))   # o tampo côncavo, onde o dedo apoia
	img.fill_rect(Rect2i(top.position.x + 3, top.position.y + 3, top.size.x - 6, 1), k[2])
	img.fill_rect(Rect2i(top.position.x + 1, top.position.y, top.size.x - 1, 1), k[4])   # as quinas de cima e da direita, na luz
	img.fill_rect(Rect2i(top.end.x - 1, top.position.y, 1, top.size.y - 1), k[4])
	img.set_pixel(top.end.x - 2, top.position.y + 1, k[5])
	_key = ImageTexture.create_from_image(img)
	return _key


## A faixa gravada que separa as saídas, com o nome numa aba escura à esquerda.
func _draw_rule(inner: Rect2, y: float, caption: String) -> void:
	draw_rect(Rect2(inner.position.x + 15, y, size.x, 1), Pal.BOARD_METAL[1])
	draw_rect(Rect2(inner.position.x + 15, y + 1, size.x, 1), Pal.BOARD_METAL[5])
	var w := PixelArt.art(PixelArt.big(caption.to_upper(), 1), {"*": Pal.BOARD_INK}).get_width()
	var tab := Rect2(inner.position.x + 9, y - 15, w + 30, 32)
	_rounded(tab, 5.0, Pal.BOARD_STRIP)
	draw_rect(Rect2(tab.position.x + 4, tab.end.y, tab.size.x - 8, 1), Pal.BOARD_METAL[5])
	_text(caption, tab.position.x + 15, tab.get_center().y, Pal.BOARD_INK)


## Um bloco rebaixado do painel: a sombra da beira em cima e à esquerda, a luz embaixo e à direita, o fundo escuro.
func _inset(r: Rect2, rad: float) -> void:
	_rounded(r.grow(1), rad + 1.0, Pal.BOARD_METAL[1])
	_rounded(r, rad, Pal.BOARD_INSET)


## Retângulo cheio de cantos redondos de raio `rad`, linha a linha (o canto pelo meio de cada pixel).
func _rounded(r: Rect2, rad: float, col: Color) -> void:
	var n := int(rad)
	draw_rect(Rect2(r.position.x, r.position.y + n, r.size.x, r.size.y - n * 2), col)
	for i in n:
		var dy := rad - i - 0.5
		var cut := roundf(rad - sqrt(maxf(rad * rad - dy * dy, 0.0)))
		draw_rect(Rect2(r.position.x + cut, r.position.y + i, r.size.x - cut * 2, 1), col)
		draw_rect(Rect2(r.position.x + cut, r.end.y - 1 - i, r.size.x - cut * 2, 1), col)


## A moldura de esmalte creme em volta do painel, pixel a pixel (como `Switchboard._shell_frame`): o canto de fora bem
## redondo, a beira no tom dela, a quina na luz, a fresta rebaixada em volta do painel e o grão do esmalte. Num tom só
## (a luz da sala, lisa, vem por cima, `_light_art`: mais clara para a direita, a rampa dava faixas).
func _shell_art() -> ImageTexture:
	var w := SIZE.x
	var h := SIZE.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var inner := OUTER.grow(-FRAME)
	for y in range(int(OUTER.position.y), h):
		for x in range(int(OUTER.position.x), w):
			var ex := x - OUTER.position.x
			var ey := y - OUTER.position.y
			if ex >= FRAME + 1 and ey >= FRAME + 1 and (ex >= SHELL_R or ey >= SHELL_R):
				continue
			var c := Vector2(x + 0.5, y + 0.5)
			var dout := _round_dist(c, OUTER, SHELL_R)
			var din := _round_dist(c, inner, SHELL_R - FRAME)
			if dout >= 0.0 or din < 0.0:
				continue
			var step := 0
			if dout > -1.0:
				step = -1   # a beira de fora
			elif dout > -3.0:
				step = 2   # a quina, na luz
			elif din < 1.0:
				step = -3   # a fresta em volta do painel
			elif din < 2.0:
				step = -1
			elif posmod((x * 73856093) ^ (y * 19349663), 23) == 0:
				step = -1   # o grão do esmalte
			img.set_pixel(x, y, Pal.cabinet(0.3, step))
	return ImageTexture.create_from_image(img)


static func _round_dist(p: Vector2, r: Rect2, rad: float) -> float:
	var q := (p - r.get_center()).abs() - (r.size / 2.0 - Vector2(rad, rad))
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - rad


## O FONE encaixado na entrada 1, pixel a pixel numa imagem do tamanho da tela, como o plug encaixado da mesa
## (`Switchboard._elbow`, em 3×): um tubo em 3D pelo eixo, que sai da tomada na direção de quem olha e aparece
## deslocado `TILT` por px de profundidade. Montado em anéis de pontos na superfície (a cada quarto de px do eixo), cada
## pixel com o ponto mais à frente, no tom da luz na normal ali. Da tomada para fora: a ponta de metal, a cabeça lisa
## e curta com a faixa verde do cabo junto do painel, o cotovelo (a dobra toda numa mola de borracha: o raio ondula
## em anéis redondos com sulcos fundos, `_coil_r`, e a normal acompanha, então cada anel tem a luz em cima e a sombra
## embaixo e a beira sai recortada; segue `COILS_DOWN` anéis para baixo), o colarinho liso afunilando (`TIP_R`) e o
## fio de pano trançado, um tubo também, caindo reto até sair da tela (`CORD_END`). Embaixo à esquerda, a sombra de tudo no painel.
func _fone_art() -> ImageTexture:
	var w := SIZE.x
	var h := SIZE.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var j := Vector2(COL0 + PITCH * (LIT_LINE - 1), Y["in"])
	var cord: Array = Pal.CORDS[0]
	var sun := Vector3(LIGHT.x, LIGHT.y, 1.1).normalized()
	var eye := Vector3(-TILT.x, -TILT.y, 1.0).normalized()   # a direção de quem olha: andar nela não muda o pixel
	var arc := PI / 2.0 * PLUG_ARC
	var spring_end := 1.0 + COIL * floorf((arc + COIL * COILS_DOWN - 1.0) / COIL)   # (acaba num sulco inteiro)
	# o eixo, a cada quarto de px: [ponto (z para fora do painel, y para baixo), tangente, parte, z no corpo, pela mola]
	var axis := []
	for i in int(PLUG_BODY * 4.0):
		var z := i / 4.0
		axis.append([Vector3(0, 0, z), Vector3.BACK, "sleeve" if z < 4.5 else "body", z, -1.0])
	for i in int(arc * 4.0):
		var s := i / 4.0
		var th := s / PLUG_ARC
		axis.append([Vector3(0, PLUG_ARC * (1.0 - cos(th)), PLUG_BODY + PLUG_ARC * sin(th)), Vector3(0, sin(th), cos(th)), "coil", 0.0, s])
	var bent := Vector3(0, PLUG_ARC, PLUG_BODY + PLUG_ARC)
	for i in int(PLUG_BOOT * 4.0) + 1:
		var u := i / 4.0
		axis.append([bent + Vector3(0, u, 0), Vector3(0, 1, 0), "mouth" if u > PLUG_BOOT - 2.0 else "boot", 0.0, arc + u])
	var last: Vector3 = axis[-1][0]
	var foot := j + Vector2(last.x, last.y) + TILT * last.z
	# o raio pela mola e pela ponta: os anéis e, depois deles, o colarinho afunilando até quase a grossura do fio
	var tube_r := func(s: float) -> float:
		if s < 1.0:
			return PLUG_R
		if s < spring_end:
			return _coil_r(s)
		return lerpf(PLUG_R, TIP_R, smoothstep(0.0, 1.0, (s - spring_end) / (arc + PLUG_BOOT - spring_end)))
	var front := {}   # pixel -> [o mais à frente, cor]
	for a: Array in axis:
		var pt: Vector3 = a[0]
		var t: Vector3 = a[1]
		var along: float = a[4]
		var spring := along >= 1.0 and along < spring_end
		var r: float = tube_r.call(along) if along >= 0.0 else (SLEEVE_R if a[2] == "sleeve" else PLUG_R)
		var dr: float = (tube_r.call(along + 0.05) - tube_r.call(along - 0.05)) / 0.1 if along >= 1.0 else 0.0
		var n2 := t.cross(Vector3.RIGHT)
		var steps := ceili(TAU * r / 0.3)   # (mais fino que o pixel: sem furos)
		for k in steps:
			var phi := TAU * k / steps
			var radial := Vector3.RIGHT * cos(phi) + n2 * sin(phi)
			var q := pt + radial * r
			var at := j + Vector2(q.x, q.y) + TILT * q.z
			if at.y >= foot.y:   # (o colarinho acaba reto, na boca do fio)
				continue
			var px := Vector2i(floori(at.x), floori(at.y))
			var d := q.dot(eye)
			if front.has(px) and front[px][0] >= d:
				continue
			var nv := (radial - t * dr).normalized()
			if nv.dot(eye) < 0.0:   # a parede de dentro (vista pela fresta entre a cabeça e a dobra): fora; o furo se tapa embaixo
				continue
			var lit := nv.dot(sun)
			var col: Color
			if a[2] == "sleeve":
				col = Pal.PLUG_TIP[3 if lit > 0.6 else (2 if lit > 0.2 else (1 if lit > -0.2 else 0))]
			elif a[2] == "body" and a[3] >= BAND.x and a[3] < BAND.y:   # a faixa do cabo
				col = cord[1] if lit > 0.97 else (cord[0] if lit > 0.3 else cord[0].darkened(0.3))
			else:
				var dark := 1 if q.z < 4.5 or a[2] == "mouth" else 0   # junto do painel, na sombra dele; a beira da boca
				if spring:
					dark += clampi(int((PLUG_R - r) / COIL_DEPTH * 4.5), 0, 4)   # o fundo do sulco, onde a luz não chega
				var idx := mini((1 if lit > 0.97 else 6 - clampi(int((lit + 0.05) * 4.0), 0, 4)) + dark, 8)
				col = Pal.SHELL[8 - idx]
			front[px] = [d, col]
	for pass_ in 2:   # o pixel que nenhum ponto pegou, entre dois do plug (dos lados ou em cima e embaixo): o tom do vizinho
		for p: Vector2i in front.keys():
			var n := p + Vector2i.RIGHT
			if not front.has(n) and (front.has(n + Vector2i.RIGHT) or front.has(n + Vector2i.UP) and front.has(n + Vector2i.DOWN)):
				front[n] = front[p]
	var shape := {}   # pixel -> cor
	_fone_cord(shape, foot, sun, cord)
	for p: Vector2i in front:
		shape[p] = front[p][1]
	for p: Vector2i in shape:   # a sombra no painel, embaixo à esquerda
		var s := p + Vector2i(-6, 6)
		if s.x >= 0 and s.y < h and not shape.has(s):
			img.set_pixel(s.x, s.y, Color(0, 0, 0, 0.32))
	for p: Vector2i in shape:
		if p.x >= 0 and p.x < w and p.y >= 0 and p.y < h:
			img.set_pixel(p.x, p.y, shape[p])
	return ImageTexture.create_from_image(img)


## O raio da mola a `along` px do começo da dobra: anéis redondos (o seno achatado no alto) e o sulco fundo e estreito
## entre eles, `COIL_DEPTH` para dentro.
static func _coil_r(along: float) -> float:
	var ph := fposmod(along - 1.0, COIL) / COIL
	return PLUG_R - COIL_DEPTH * (1.0 - pow(sin(PI * ph), 0.7))


## O fio do FONE em `shape`: um tubo de pano saindo do colarinho em `foot` e caindo reto até sair da tela; o tom pela luz na normal (redondo, sem faixas chapadas), o trançado fino em V por cima, mais forte na
## luz e sumindo na sombra, e a sombra do colarinho no começo dele.
func _fone_cord(shape: Dictionary, foot: Vector2, sun: Vector3, cord: Array) -> void:
	var tones: Array = [cord[1], cord[0], cord[0].darkened(0.3), cord[0].darkened(0.55)]
	var p0 := foot + Vector2(0, -1)
	var p3 := Vector2(foot.x, CORD_END)   # reto para baixo (a pedido)
	var p1 := p0.lerp(p3, 1.0 / 3.0)
	var p2 := p0.lerp(p3, 2.0 / 3.0)
	var depth := {}
	var along := 0.0
	var prev := p0
	for i in 2401:
		var f := i / 2400.0
		var c := p0.bezier_interpolate(p1, p2, p3, f)
		along += c.distance_to(prev)
		prev = c
		var tg := p0.bezier_derivative(p1, p2, p3, f).normalized()
		var n := Vector2(-tg.y, tg.x)
		if n.x < 0.0:
			n = -n
		for k in int(CORD_R * 4.0) + 1:
			var off := -CORD_R + k * 0.5
			var u := off / CORD_R
			if absf(u) > 1.0:
				continue
			var px := Vector2i((c + n * off).floor())
			var dz := sqrt(1.0 - u * u)
			if depth.get(px, -1.0) >= dz:
				continue
			depth[px] = dz
			var lit := Vector3(n.x * u, n.y * u, dz).dot(sun)
			var idx := 0 if lit > 0.75 else (1 if lit > 0.35 else (2 if lit > -0.05 else 3))
			if along < 4.0:
				idx = mini(idx + 1, 3)   # embaixo do colarinho
			var col: Color = tones[idx]
			var v := asin(u) * CORD_R   # em volta do fio, em px da superfície
			if fposmod(along + absf(v) * 0.9, 3.0) < 1.0:   # o trançado: as fibras em V
				col = col.darkened(0.28 * clampf(lit + 0.3, 0.0, 1.0))
			shape[px] = col


## A luz da sala no painel, lisa: mais clara no alto à direita (a luminária fica para lá) e sumindo no escuro embaixo
## e à esquerda.
func _light_art() -> GradientTexture2D:
	var g := GradientTexture2D.new()
	g.width = SIZE.x
	g.height = SIZE.y
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(1.05, -0.1)
	g.fill_to = Vector2(-0.15, 1.1)
	g.gradient = Gradient.new()
	g.gradient.set_color(0, Color(1.0, 0.88, 0.66, 0.06))
	g.gradient.set_color(1, Color(0.012, 0.022, 0.045, 0.78))
	g.gradient.add_point(0.55, Color(0.012, 0.022, 0.045, 0.18))
	return g
