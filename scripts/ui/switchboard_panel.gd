extends "res://scripts/ui/switchboard_base.gd"
## O painel da mesa comutadora (`Switchboard`), retrofuturista (como na série Ruptura): o móvel de esmalte de cantos
## redondos, a faixa escura do alto, os trilhos das colunas, as plaquinhas creme, as lâmpadas, as tomadas, o
## desgaste, os blocos rebaixados dos bancos, as chapas deles e a prateleira com os buracos dos cabos.

const DEST_TOP := 141.0      # topo das tomadas da primeira fileira (a segunda fica DEST_ROW px abaixo)
const DEST_ROW := 27.0
const FRAME := 5.0           # a moldura de esmalte do móvel, em volta do painel
## Faixas gravadas no painel que separam as seções (altura da linha; o nome fica sobre ela, à esquerda).
const RULES := {"in": 11.0, "out": 78.0}
const SHELL_R := 12.0        # o raio dos cantos de fora do móvel (`_shell_frame`); os do painel, por dentro, `SHELL_R - FRAME`
## O buraco da prateleira (16×8, niquelado, achatado pela perspectiva; o vão, 12 de largura, da largura do plug, que entra
## nele): b, a beira de trás do aro (na sombra); f e F, a da frente (na luz, com o brilho); w, a parede de dentro do lado
## de trás; h, o vão. As linhas são de elipses de pixel art (`draw_grommet`).
const HOLE_ART := [
	"....bbbbbbbb....",
	".bbbbwwwwwwbbbb.",
	"bbbwwhhhhhhwwbbb",
	"bbwhhhhhhhhhhwbb",
	"ffhhhhhhhhhhhhff",
	".ffhhhhhhhhhhff.",
	"..ffFffffffFff..",
	"....FFFFFFFF....",
]
const HOLE_PAL := {"b": Pal.NICKEL_EDGE[1], "f": Pal.NICKEL[2], "F": Pal.NICKEL[1], "w": Pal.NICKEL_EDGE[2], "h": Pal.JACK_HOLE}   # níquel: o buraco, a plaquinha do FONE e a do fabricante

var _lit := {}   ## lâmpada ("l3" linha, "d312" destino) -> [cor, quanto está acesa 0..1]; a cor fica enquanto apaga

## O encaixe (12×12, o `JACK`; par, para o meio dele cair entre dois pixels, como o das plaquinhas e das lâmpadas),
## pela referência do usuário: um aro de metal abaulado em volta de um furo preto largo (`_jack_tex`). De dentro para
## fora, nos raios de `JACK_RINGS`: o furo (6 px); a parede da bucha, côncava (a luz bate nela do lado oposto, embaixo
## à esquerda); a face do aro, abaulada (clara no alto à direita, virada para a luminária, e escura embaixo à
## esquerda); e a descida dela até o painel, dois tons mais escura (o aro recortado no painel, sem beira preta). Cada
## pixel do aro escolhe o tom pela luz numa rampa de cinco (`JACK_METAL`, do claro ao escuro), em degraus: com três
## tons por anel ele parecia chato, e com o furo de 4 px e a face cinza, estranho; com uma beira escura em volta, o aro
## ficava fino demais. O brilho do níquel é um pixel por cima da luz da sala (`_draw_glints`).
const JACK_RINGS := [3.0, 4.0, 5.0, 5.8]   # até onde vão o furo, a parede da bucha, a face e a descida (px do meio)
const JACK_METAL := Pal.JACK_METAL
const JACK_HOLE := Pal.JACK_HOLE
const JACK_GLINT := Vector2(3, -4)   # o brilho do níquel, do meio do encaixe: na face, no alto à direita, virado para a luz
const JACK_GLINT_COLOR := Color(1.0, 0.96, 0.86, 0.85)
const JACK_PX := 12   # o lado do desenho do encaixe, em pixels
const EDGE_DARK := Pal.NUT_HOLE   # o fundo do furo da porca da chave: marrom quase preto
## A quina do níquel descendo até o painel: na luz, no meio e na sombra. No lugar da beira quase preta (`EDGE_DARK`),
## que em volta das tomadas, das lâmpadas, das alavancas e das plaquinhas parecia um contorno preto.
const NICKEL_EDGE := Pal.NICKEL_EDGE
const SHADOW := Color(0, 0, 0, 0.35)
const PLATE := Pal.BANK_PLATE   # chapa sobre o banco que ainda não está em uso
const LAMP_R := 2.5         # o raio da luz da lâmpada de cada linha, no `Bloom` (o vidro tem 4; o aro de metal fica em volta)
const BEZEL := [Pal.NICKEL[1], Pal.NICKEL[2], Pal.NICKEL[3]]   # aro niquelado: luz, meio, sombra
const LAMP_OFF := Pal.LAMP_GLASS
const WEAR := [0.5, 0.3, 0.15]   # o painel gasto em volta das tomadas: do perto ao longe (o quanto clareia)
const LAMP_ON_SEC := 0.06    # a lâmpada (de filamento) acende quase na hora...
const LAMP_OFF_SEC := 0.18   # ...e apaga mais devagar, o filamento esfriando: a linha tocando pulsa em vez de piscar seco
## A alavanca da chave de escuta para baixo, do eixo (no meio da porca) à ponta: um bastão que engrossa até a ponta
## arredondada, a luz à direita e a ponta, virada para baixo, na sombra. Cabe entre a entrada e a saída.
const CORD_COLORS := Pal.CORDS
const LEVER_ART := [   # para baixo: a haste curta de metal (L, D) saindo da porca e, na ponta, o pino comprido de baquelite preta (l, w, m, d)
	".eDLE.",   # a beira de cada peça no tom dela, na luz à direita e na sombra à esquerda (E, e no metal; P, p no pino)
	".eDLE.",
	".eDLE.",
	"pdmllP",
	"pdmlwP",
	"pdmllP",
	"pdmmlP",
	".pddp.",
]
## Para cima: o pino visto mais de frente (a ponta redonda) e a haste embaixo dele.
const LEVER_UP := [".PllP.", "pdmmlP", "pdmlwP", "pdmllP", "pdmmlP", ".eDLE.", ".eDLE.", ".eDLE."]


## Cor da lâmpada de uma linha (Exchange.Line) e quanto ela quer estar acesa (0..1); `_fade` chega lá aos poucos.
func _lamp(st: int, ms: int, steady: bool) -> Array:
	match st:
		Exchange.Line.RING:
			return [Pal.AMBER, 1.0 if steady or (ms / 250) % 2 == 0 else 0.0]
		Exchange.Line.TALK:
			return [Pal.AMBER, 1.0]
		Exchange.Line.HOLD:
			return [Pal.AMBER, 1.0 if (ms / 800) % 2 == 0 else 0.45]
		Exchange.Line.CONN:
			return [Pal.GREEN, 1.0]
		Exchange.Line.DONE:
			return [Pal.RED, 1.0]
	return [LAMP_OFF, 0.0]


## Os estados de destino (Exchange.Dest) acendem como os de linha equivalentes.
func _dest_lamp(st: int, ms: int) -> Array:
	match st:
		Exchange.Dest.RING:
			return _lamp(Exchange.Line.RING, ms, false)
		Exchange.Dest.CONN:
			return [Pal.GREEN, 1.0]
		Exchange.Dest.DONE:
			return [Pal.RED, 1.0]
	return [LAMP_OFF, 0.0]


## A lâmpada `key` vai para `want` ([cor, nível]): acende em `LAMP_ON_SEC`, apaga em `LAMP_OFF_SEC`, mantendo a cor.
func _fade(key: String, want: Array, delta: float) -> void:
	var cur: Array = _lit.get(key, [want[0], 0.0])
	if want[1] > 0.0:
		cur[0] = want[0]
	var lv: float = cur[1]
	cur[1] = move_toward(lv, want[1], delta / (LAMP_ON_SEC if want[1] > lv else LAMP_OFF_SEC))
	_lit[key] = cur


## Lâmpada de mesa antiga: uma tampa de vidro leitoso, abaulada, num aro fino de níquel, sem furo (com o assento
## preto, ela parecia mais uma tomada). Apagada, o vidro fica leitoso (`LAMP_OFF`); acesa, toma a cor da linha, o aro
## pega a cor dela e o centro estoura para o branco (o halo é do `Bloom`). A luz da sala brilha no alto do vidro.
func _draw_lamp(c: Vector2, col: Color, level: float) -> void:
	var s := _step_at(c)
	var n := _nickel(s)
	PixelArt.sprite(_ci, _disc(10, [[4.0, n[0], n[1], n[2]], [5.0, n[3], n[4], n[5]]]), c)   # o aro, do tamanho da tomada
	if level > 0.02:
		PixelArt.sprite(_ci, _disc(10, [[3.0, Color.TRANSPARENT], [4.0, Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT]]), c, Color(col, 0.35 * level))   # a luz no aro
	# o vidro abaulado (luz no alto à direita): o aceso por cima do apagado, com `level` no modulate (uma cor por quadro
	# na chave do `disc` guardava uma textura nova a cada quadro da lâmpada pulsando)
	var glass := Pal.lit(LAMP_OFF, s)
	PixelArt.sprite(_ci, _disc(6, [[3.0, glass.lightened(0.3), glass, glass.darkened(0.4)]]), c)
	if level > 0.02:   # acesa: o centro estoura para o branco (o halo é do Bloom; o miolo nítido, daqui)
		PixelArt.sprite(_ci, _disc(6, [[3.0, col.lightened(0.3), col, col.darkened(0.4)]]), c, Color(1, 1, 1, level))
		PixelArt.sprite(_ci, _disc(2, [[1.0, Color.WHITE]]), c, Color(Color.WHITE.lerp(col, Bloom.HOT_TINT), level))
		Bloom.light(_ci, Rect2(c - Vector2(LAMP_R, LAMP_R), Vector2(LAMP_R, LAMP_R) * 2.0), Color(col, level), 1.0, false, true)
	_ci.draw_rect(Rect2(c + Vector2(1, -2), Vector2(1, 1)), Color(1, 1, 1, 0.5))   # o brilho da sala no vidro


## As chaves de escuta, como as das mesas de verdade: a porca niquelada no painel e a alavanca de bastão (`LEVER_ART`).
## Cada uma em `levers` é [centro, direção, px além]: para cima (-1), para baixo (1) ou, virando, de frente (0: só a
## ponta, virada para os olhos), `over` px além, na batida. A sombra cai embaixo à esquerda (a luz vem do alto à
## direita, `LIGHT`). Em passadas, todas as sombras, as porcas e as alavancas, para cada textura ser uma chamada de desenho só.
func _draw_levers(levers: Array) -> void:
	var b: Color = CORD_COLORS[5][0]   # o pino da ponta, de baquelite preta, como os cabos pretos; a haste é de metal
	var hi: Color = CORD_COLORS[5][1]
	var shade := {"E": SHADOW, "e": SHADOW, "P": SHADOW, "p": SHADOW, "L": SHADOW, "D": SHADOW, "l": SHADOW, "w": SHADOW,
		"m": SHADOW, "d": SHADOW}
	var tones := {}   # o degrau da luz da sala (`_step_at`) -> as cores da alavanca nele
	for v in levers:
		var s := _step_at(v[0])
		if tones.has(s):
			continue
		var n := _nickel(s)
		var k := Pal.lit(b, s)
		tones[s] = {"E": n[3], "e": n[5], "P": k, "p": k.darkened(0.25), "L": n[0], "D": n[2], "l": Pal.lit(b.lerp(hi, 0.6), s),
			"w": Pal.lit(hi.lightened(0.25), s), "m": k, "d": k.darkened(0.4)}
	for v in levers:
		PixelArt.sprite(_ci, _disc(8, [[4.0, SHADOW]]), v[0] + Vector2(-1, 1))
	for v in levers:
		if v[1] != 0:
			_ci.draw_texture(PixelArt.art(LEVER_ART if v[1] > 0 else LEVER_UP, shade), _lever_corner(v) + Vector2(-1, 1))
	for v in levers:   # a porca (pequena: a haste aparece além dela)
		var n := _nickel(_step_at(v[0]))
		PixelArt.sprite(_ci, _disc(8, [[1.5, EDGE_DARK], [3.0, n[0], n[1], n[2]], [4.0, n[3], n[4], n[5]]]), v[0])
	for v in levers:
		var t: Dictionary = tones[_step_at(v[0])]
		if v[1] == 0:
			PixelArt.sprite(_ci, _disc(6, [[2.0, t["l"], t["m"], t["d"]], [3.0, t["m"], t["m"], t["p"]]]), v[0])
		else:
			_ci.draw_texture(PixelArt.art(LEVER_ART if v[1] > 0 else LEVER_UP, t), _lever_corner(v))


## Onde vai o canto da alavanca [centro, direção, px além] de `_draw_levers`.
static func _lever_corner(v: Array) -> Vector2:
	return v[0] + Vector2(-LEVER_ART[0].length() / 2.0, (0.0 if v[1] > 0 else 1.0 - LEVER_ART.size()) + v[1] * v[2])


## Encaixe redondo como os das mesas antigas (`_jack_tex`), com a sombra curta no painel. `dim`: o metal mais escuro.
func _draw_jack(jr: Rect2, dim := 0.0) -> void:
	var r := _jack_px(jr)
	_ci.draw_texture_rect(_disc(JACK_PX, [[JACK_PX / 2.0, Color(0, 0, 0, 0.25)]]), Rect2(r.position + Vector2(-1, 1), r.size), false)   # rente ao painel: sombra curta
	_ci.draw_texture_rect(_jack_tex(dim), r, false)


## Onde o desenho do encaixe `jr` fica (`JACK_PX` em volta do meio dele).
func _jack_px(jr: Rect2) -> Rect2:
	return Rect2(jr.get_center() - Vector2(JACK_PX, JACK_PX) / 2.0, Vector2(JACK_PX, JACK_PX))


## O desenho do encaixe (`JACK_RINGS`, `JACK_METAL`; `dim` escurece o metal: as saídas, para não se confundirem com
## as entradas), pixel a pixel. Guardado (um por `dim`).
static var _jack_arts := {}


static func _jack_tex(dim: float) -> ImageTexture:
	if not _jack_arts.has(dim):
		var img := Image.create(JACK_PX, JACK_PX, false, Image.FORMAT_RGBA8)
		for y in JACK_PX:
			for x in JACK_PX:
				var o := Vector2(x + 0.5, y + 0.5) - Vector2(JACK_PX, JACK_PX) / 2.0
				var r := o.length()
				if r <= JACK_RINGS[0]:
					img.set_pixel(x, y, JACK_HOLE)
				elif r <= JACK_RINGS[3]:
					var face: bool = r > JACK_RINGS[1]
					var ramp: Array = JACK_METAL["face" if face else "wall"]
					var lit := o.normalized().dot(LIGHT) * (1.0 if face else -1.0)   # (a parede, côncava, pega a luz do outro lado)
					var k := int((1.0 - lit) / 2.0 * ramp.size()) + (2 if r > JACK_RINGS[2] else 0)   # (a descida, dois tons abaixo)
					img.set_pixel(x, y, (ramp[clampi(k, 0, ramp.size() - 1)] as Color).darkened(dim))
		_jack_arts[dim] = ImageTexture.create_from_image(img)
	return _jack_arts[dim]


## O brilho do níquel de cada encaixe `jacks` ([retângulo, força]), por cima da luz da sala, que o apagava.
func _draw_glints(jacks: Array) -> void:
	for j in jacks:
		_ci.draw_rect(Rect2(((j[0] as Rect2).get_center() + JACK_GLINT).floor(), Vector2.ONE), Color(JACK_GLINT_COLOR, JACK_GLINT_COLOR.a * j[1]))


## A luz de uma lâmpada batendo no aro do encaixe logo abaixo dela (o lado de cima, virado para a luz).
func _reflect(jr: Rect2, col: Color, level: float) -> void:
	if level > 0.02:
		_ci.draw_texture_rect(PixelArt.disc(JACK_PX, [[JACK_RINGS[0], Color.TRANSPARENT], [JACK_RINGS[2], Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT]], Vector2.UP), _jack_px(jr), false, Color(col, 0.55 * level))


## O móvel da mesa: o painel de metal, rebaixado, com a beira no tom da luz da sala ali (`_lit_rect`), e por cima dele
## a moldura de esmalte (`_shell_frame`, que arredonda os cantos dele), com o brilho da luminária do teto na quina de
## cima, mais forte do lado dela (no meio da tela, à direita da mesa).
func _draw_cabinet(r: Rect2) -> void:
	var p := r.grow(-FRAME)
	_ci.draw_rect(p, Pal.BOARD_FACE)
	_lit_rect(Rect2(p.position, Vector2(p.size.x, 2)), _metal(-2))   # rebaixado: a sombra fica em cima à esquerda
	_lit_rect(Rect2(p.position, Vector2(2, p.size.y)), _metal(-2))
	_lit_rect(Rect2(p.position.x, p.end.y - 1, p.size.x, 1), _metal(2))
	_ci.draw_texture(_shell_frame(r.size), r.position)
	var lamp := get_viewport_rect().size.x / 2.0 - global_position.x
	var glint := func(x: float) -> Color:
		return Color(Pal.SHELL[7].lightened(0.3), 0.6 * clampf(1.0 - absf(x - lamp) / 525.0, 0.0, 1.0))
	var top := r.position.y + 1.0
	_ci.draw_primitive(PackedVector2Array([Vector2(r.position.x + SHELL_R, top), Vector2(r.end.x - SHELL_R, top), Vector2(r.end.x - SHELL_R, top + 1), Vector2(r.position.x + SHELL_R, top + 1)]),
		PackedColorArray([glint.call(r.position.x), glint.call(r.end.x), glint.call(r.end.x), glint.call(r.position.x)]), PackedVector2Array())


## O metal do painel `step` tons acima ou abaixo do tom do lugar (`Pal.panel_metal`), para o `_lit_rect`.
static func _metal(step: int) -> Callable:
	return func(lit: float) -> Color: return Pal.panel_metal(lit, step)


## Um filete do painel ou da moldura (`r`, na horizontal ou na vertical), cada trecho no tom de `tone` (a luz da sala,
## `_room_lit`, para o tom, em degraus) pela luz ali: mais claro e quente perto da luminária, frio longe dela.
func _lit_rect(r: Rect2, tone: Callable) -> void:
	var along := Vector2.RIGHT if r.size.x >= r.size.y else Vector2.DOWN
	var n := int(r.size.dot(along))
	var from := 0
	var col: Color = tone.call(_room_lit(r.position))
	for i in range(1, n + 1):
		var c: Color = col if i == n else tone.call(_room_lit(r.position + along * i))
		if c != col or i == n:
			_ci.draw_rect(Rect2(r.position + along * from, r.size * (Vector2.ONE - along) + along * (i - from)), col)
			from = i
			col = c


## A luz da luminária do teto no painel (`lamp`, nas coordenadas da mesa: no meio da tela, acima dela): lisa, ponto a
## ponto numa grade com a cor nos cantos de cada quadrado, mais clara e quente perto dela (no alto, à direita) e mais
## escura nos cantos de baixo, longe; sem ela, o painel tinha a mesma luz em toda parte e parecia fora da sala. Por
## cima de tudo que é do painel e por baixo dos plugs e fios (que saem dele, na frente).
func _draw_room_light(p: Rect2) -> void:
	var n := Vector2i(12, 8)
	for j in n.y:
		for i in n.x:
			var a := p.position + p.size * Vector2(i, j) / Vector2(n)
			var b := p.position + p.size * Vector2(i + 1, j + 1) / Vector2(n)
			var quad := PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])
			var cols := PackedColorArray()
			for q in quad:
				cols.append(_room_tone(q))
			_ci.draw_primitive(quad, cols, PackedVector2Array())   # (primitivos seguidos são uma chamada de desenho só; polígonos, uma cada)


## O trilho de cada linha: um sulco fino que desce da plaquinha à saída, ligando a lâmpada, a entrada, a chave e a
## saída da mesma coluna (sem ele, a saída parecia solta). A faixa das chaves cruza por cima.
func _draw_strips() -> void:
	for i in 10:
		var r := Rect2(col_x(i) - 1.0, ROW_Y["plate"] + ROW_Y["plate_h"] + 2.0, 2.0, ROW_Y["out"] - ROW_Y["plate"] - ROW_Y["plate_h"] - 2.0)
		_lit_rect(Rect2(r.position, Vector2(1, r.size.y)), _metal(-2))   # rebaixado: a sombra à esquerda, a luz à direita
		_lit_rect(Rect2(r.position.x + 1.0, r.position.y, 1, r.size.y), _metal(2))


## O uso de anos: o painel gasto em volta das tomadas (claro liso, mais nas entradas, onde o FONE entra a noite toda,
## e nas primeiras linhas) e riscos finos onde a ponta do plug escorregou errando o furo. Sempre os mesmos.
func _draw_wear() -> void:
	var hi: Color = Pal.BOARD_METAL[6]
	for j in _jacks:
		if j > 20:
			continue   # nos bancos, rebaixados e escuros, o gasto não aparece
		var use := _use(j)
		PixelArt.sprite(_ci, _disc(20, [[7.0, Color(hi, WEAR[0])], [8.5, Color(hi, WEAR[1])], [10.0, Color(hi, WEAR[2])]]),
			jack_rect(j).get_center(), Color(1, 1, 1, use))
		var rng := RandomNumberGenerator.new()
		rng.seed = j
		for k in roundi(use * 2.0):
			var a := rng.randf() * TAU
			var from := jack_rect(j).get_center() + Vector2.from_angle(a) * rng.randf_range(6.0, 8.0)
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * rng.randf_range(2.0, 4.0)
			_ci.draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), Color(hi, 0.45), 1.0)


## O quanto a tomada `j` é usada (0..1): as entradas mais, das primeiras linhas para as últimas; depois as saídas; os
## destinos, menos.
func _use(j: int) -> float:
	if j <= 10:
		return 1.0 - (j - 1) * 0.05
	if j <= 20:
		return 0.6 - (j - 11) * 0.03
	return 0.35


## A plaqueta do fabricante em `r` (96×32), no esmalte claro com a beira niquelada, desenhada pelo cenário na frente do console, ao lado
## da miniatura do painel: o nome da central gravado (escuro, com o brilho embaixo) e um parafuso em cada ponta. Com 26 de altura,
## o acento do Ô caía no friso e o til de "SÃO" encostava no pé da linha de cima: agora há 1 px livre entre eles.
static func draw_maker_plate(ci: CanvasItem, r: Rect2) -> void:
	var pal := HOLE_PAL
	var cx := r.get_center().x
	ci.draw_rect(Rect2(r.position + Vector2(1, 2), r.size), SHADOW)
	rim(ci, r, pal["b"], pal["b"].darkened(0.35))
	ci.draw_rect(r, Pal.SHELL[6])
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), pal["F"])
	ci.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), pal["f"])
	ci.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), pal["b"])
	ci.draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), pal["b"])
	ci.draw_rect(r.grow(-3), pal["b"], false, 1.0)   # o friso gravado em volta
	for x in [r.position.x + 7.0, r.end.x - 7.0]:
		PixelArt.sprite(ci, _disc(5, [[1.5, pal["F"], pal["f"], pal["b"]], [2.5, pal["w"]]]), Vector2(x, r.get_center().y))
		ci.draw_rect(Rect2(x - 1.0, r.get_center().y, 3, 1), pal["w"])   # a fenda
	var maker := PixelArt.tiny(T.text(T.Key.BOARD_MAKER))
	var at := Vector2(roundf(cx - maker.get_width() / 2.0), r.position.y + 5.0)   # o acento 2 px abaixo do friso
	ci.draw_texture(maker, at + Vector2(0, 1), pal["F"])
	ci.draw_texture(maker, at, pal["w"])
	var town := "SÃO SOTERO"
	var nw := Pal.mono.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var np := Vector2(roundf(cx - nw / 2.0), r.end.y - 6.0)
	ci.draw_string(Pal.mono, np + Vector2(0, 1), town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["F"])
	ci.draw_string(Pal.mono, np, town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["w"])


static var _shells := {}   # as molduras guardadas, por tamanho e lugar da luminária (`_shell_frame`)


## Os troncos interurbanos, no canto de baixo à direita do painel, em `br` (a largura de um banco de destino): um
## banco como os de destino, com o nome gravado na moldura e o da cidade em cima de cada tomada. As tomadas são
## destinos (`GameData.TRUNKS`, posição em `_layout_dests`), desenhadas e acesas com os outros. Embaixo, a régua dos
## equipamentos.
func _draw_trunks(br: Rect2) -> void:
	_draw_inset(br)
	var cap := PixelArt.tiny(T.text(T.Key.BOARD_TRUNKS))   # na beira de cima, como o nome dos bancos
	var at := Vector2(roundf(br.get_center().x - cap.get_width() / 2.0), br.position.y - 5.0)
	_ci.draw_rect(Rect2(at.x - 3.0, br.position.y - 1.0, cap.get_width() + 6.0, 3.0), Pal.BOARD_INSET)
	_ci.draw_texture(cap, at, Pal.BOARD_INK)
	for k in GameData.TRUNKS.size():
		var d: int = GameData.TRUNKS[k]
		var label := PixelArt.tiny(T.text(GameData.TRUNK_NAMES[k]))
		var x := jack_rect(d).get_center().x
		_ci.draw_texture(label, Vector2(roundf(x - label.get_width() / 2.0), br.position.y + 4.0),
			Pal.NUMBER_PAINT if exchange.dest(d) == Exchange.Dest.FREE else Pal.TEXT)
	# embaixo dele, no meio do vão até a moldura, a régua niquelada onde encostam os equipamentos da prateleira (sem
	# eles, marca o lugar; com eles, aparece entre um e outro)
	var rail := Rect2(br.position.x + 4.0, br.end.y + roundf((size.y - FRAME - br.end.y) / 2.0) - 1.0, br.size.x - 8.0, 3.0)
	var n := _nickel(_step_at(rail.get_center()))
	_ci.draw_rect(rail, n[1])
	_ci.draw_rect(Rect2(rail.position, Vector2(rail.size.x, 1)), n[0])
	_ci.draw_rect(Rect2(rail.position.x, rail.end.y - 1, rail.size.x, 1), n[2])
	_ci.draw_rect(Rect2(rail.position.x, rail.end.y, rail.size.x, 1), SHADOW)
	for x in [rail.position.x + 3.0, rail.end.x - 4.0]:   # os parafusos das pontas
		_ci.draw_rect(Rect2(x, rail.position.y + 1.0, 1, 1), n[5])


## A moldura de esmalte do móvel, pixel a pixel e guardada: lisa, com os cantos de cima bem redondos por fora
## (`SHELL_R`; a lateral e o tampo, no cenário, seguem o arco, `Background._round_edge`) e os quatro do painel, por dentro, também (o que fica entre o canto do painel e o arco é do esmalte); a beira de fora no tom
## dela (escura, parecia um contorno), a luz na quina de cima e à esquerda e a sombra embaixo e à direita; na fresta
## em volta do painel, o contrário (rebaixado); e a casca de laranja do esmalte num grão fino, sempre no mesmo lugar.
## Cada pixel no tom do esmalte pela luz da sala ali (`Pal.cabinet`, `_room_lit`).
func _shell_frame(sz: Vector2) -> ImageTexture:
	var key := Rect2(_lamp_at, sz)
	if not _shells.has(key):
		if _shells.size() >= 8:
			_shells.clear()
		var w := int(sz.x)
		var h := int(sz.y)
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var outer := Rect2(0, 0, w, h)
		var inner := outer.grow(-FRAME)
		var ri := SHELL_R - FRAME
		for y in h:
			for x in w:
				var ex := mini(x, w - 1 - x)
				var ey := mini(y, h - 1 - y)
				if ex >= FRAME + 1 and ey >= FRAME + 1 and (ex >= SHELL_R or ey >= SHELL_R):
					continue   # o painel, longe dos cantos (a conta, cara, só nos cantos e na beira)
				var c := Vector2(x + 0.5, y + 0.5)
				var din := _round_dist(c, inner, ri)
				var dout := _round_dist(c, outer, SHELL_R if y < h / 2 else 0.0)   # embaixo, reto: o móvel entra no console
				if dout >= 0.0 or din < 0.0:
					continue   # fora do canto redondo, ou dentro do painel
				var lit := (c.x - outer.get_center().x) / w + (c.y - outer.get_center().y) / h < 0.0   # o lado de cima e à esquerda
				var step := 0
				if dout > -1.0:
					step = -1 if lit else -3   # a beira de fora
				elif dout > -2.0:
					step = 2 if lit else -2    # a quina, na luz ou na sombra
				elif din < 1.0:
					step = -3 if lit else 1    # a fresta em volta do painel, rebaixada
				elif posmod((x * 73856093) ^ (y * 19349663), 23) == 0:
					step = -1   # o grão do esmalte
				img.set_pixel(x, y, Pal.cabinet(_room_lit(Vector2(x, y)), step))
		_shells[key] = ImageTexture.create_from_image(img)
	return _shells[key]


## A distância de `p` à beira do retângulo `r` de cantos redondos de raio `rad`: negativa dentro, positiva fora.
static func _round_dist(p: Vector2, r: Rect2, rad: float) -> float:
	var q := (p - r.get_center()).abs() - (r.size / 2.0 - Vector2(rad, rad))
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - rad


## A legenda das lâmpadas, na faixa das entradas, alinhada à direita e logo acima das lâmpadas que ela explica, na
## fonte gravada do painel (`tiny`; em 11 não cabia ali). No pé do painel, os plugs guardados passavam na frente dela.
func _draw_legend() -> void:
	var leg := [[Pal.AMBER, T.Key.LEGEND_RING], [Pal.GREEN, T.Key.LEGEND_CONN], [Pal.RED, T.Key.LEGEND_DONE], [LAMP_OFF, T.Key.LEGEND_FREE]]
	var texts := []
	var width := -10.0
	for item in leg:
		var t := PixelArt.tiny(T.text(item[1]))
		texts.append(t)
		width += 7.0 + 3.0 + t.get_width() + 8.0
	var y := RULES["in"] + 1.0
	var x := floorf(size.x - FRAME - 14.0 - width)
	for k in leg.size():
		PixelArt.sprite(_ci, _disc(7, [[2.0, Color.WHITE], [3.5, Color.TRANSPARENT]]), Vector2(x + 3.5, y), leg[k][0])   # lâmpadas redondas, como as da mesa
		PixelArt.sprite(_ci, _disc(7, [[2.0, Color.TRANSPARENT], [3.5, NICKEL_EDGE[0], NICKEL_EDGE[1], NICKEL_EDGE[2]]]), Vector2(x + 3.5, y))
		_ci.draw_texture(texts[k], Vector2(x + 10.0, y - 5.0), Pal.BOARD_INK)
		x += 7.0 + 3.0 + (texts[k] as Texture2D).get_width() + 8.0


## Faixa gravada que separa as seções do painel, com o nome dela numa aba escura, à esquerda, na fonte gravada do
## painel como a legenda (`tiny`; em 11 enchia a faixa e encostava nas plaquinhas) (sem nome, só a faixa; sem
## `line`, só o nome).
func _draw_rule(y: float, caption: String, line := true) -> void:
	if line:
		_lit_rect(Rect2(FRAME + 5, y, size.x - FRAME * 2 - 10, 1), _metal(-2))
		_lit_rect(Rect2(FRAME + 5, y + 1, size.x - FRAME * 2 - 10, 1), _metal(2))
	if caption != "":
		var t := PixelArt.tiny(caption)
		var tab := Rect2(FRAME + 3, y - 5, t.get_width() + 15, 12)
		_ci.draw_rect(tab, Pal.BOARD_STRIP)
		_ci.draw_rect(Rect2(tab.position.x, tab.end.y, tab.size.x, 1), _metal_at(tab.position, 2))   # a beira de baixo, na luz
		_ci.draw_texture(t, Vector2(FRAME + 10, y - 4), Pal.BOARD_INK)   # as letras nas linhas 3 a 7: em volta da faixa


## A faixa escura do alto do painel, de ponta a ponta, onde vão o nome das entradas e a legenda das lâmpadas.
func _draw_header() -> void:
	var r := Rect2(FRAME + 3, RULES["in"] - 5, size.x - FRAME * 2 - 6, 12)
	_ci.draw_rect(r, Pal.BOARD_STRIP)
	_lit_rect(Rect2(r.position.x, r.end.y, r.size.x, 1), _metal(2))


## Um bloco rebaixado no painel (os bancos de destino, o interurbano): o fundo escuro, com a sombra da beira em cima e
## à esquerda e a luz embaixo e à direita.
func _draw_inset(r: Rect2) -> void:
	_lit_rect(Rect2(r.position.x - 1, r.position.y - 1, r.size.x + 2, 1), _metal(-2))
	_lit_rect(Rect2(r.position.x - 1, r.position.y, 1, r.size.y + 1), _metal(-2))
	_lit_rect(Rect2(r.position.x, r.end.y, r.size.x + 1, 1), _metal(2))
	_lit_rect(Rect2(r.end.x, r.position.y - 1, 1, r.size.y + 1), _metal(2))
	_ci.draw_rect(r, Pal.BOARD_INSET)


## O tom do metal do painel em `p`, `step` tons acima ou abaixo.
func _metal_at(p: Vector2, step: int) -> Color:
	return Pal.panel_metal(_room_lit(p), step)


## A prateleira à frente do painel, onde os cabos de conexão ficam guardados de pé: os buracos de onde saem os fios
## (a cor de cada cabo já diz qual é; o nome gravado embaixo saiu, a pedido).
func _draw_tray() -> void:
	_draw_fone_tag()
	for k in patches:
		for e in [1 + k * 2, 2 + k * 2]:
			draw_grommet(_ci, hole(e))
	var bay_w := bay_rect().size.x - BAY_MARGIN
	# cada setor novo traz um cabo: até lá, o lugar dele fica sob um tampo, sempre o mesmo e no mesmo lugar, contados
	# do tampo dos equipamentos para a esquerda (o par novo surge no lugar do tampo que sai; os outros não mudam)
	var right := (bay_rect().get_center().x - bay_w / 2.0 if trunks.has_area() else tray_rect().end.x) - COVER_GAP
	for k in range(patches, SHELF_SLOTS):
		_draw_cover(right - COVER_W / 2.0 - (SHELF_SLOTS - 1 - k) * (COVER_W + COVER_GAP), COVER_W)
	if equipped.is_empty() and trunks.has_area():   # o lugar dos equipamentos, tampado até chegar o primeiro
		_draw_cover(bay_rect().get_center().x, bay_w, true)


const COVER_W := 24.0   # o tampo de um lugar vago, na linha do meio (os pares são mais juntos: os tampos não ficam em cima deles)
const COVER_GAP := 6.0   # o vão entre os tampos e até o dos equipamentos
const BAY_MARGIN := 24.0   # o tampo dos equipamentos: a largura do bloco interurbano menos isto


## Um lugar vago na prateleira sob uma chapa parafusada, deitada no meio dela (`_shelf_mid`): `w` de largura em `x`
## na linha do meio. Na inclinação dos pares de plugs, chapa e textura juntas: cada linha fica deitada e as beiras
## pendem como a ponta da frente de um par em relação à de trás (`_lean`; reta, parecia em pé; pelo ponto de fuga da
## sala, mais inclinada que os plugs ao lado). Com `side`, a da direita (o tampo largo dos equipamentos, junto da
## lateral da mesa) fica paralela a ela, com a inclinação da lateral (`_receding` na beira da prateleira; fugindo
## daqui para os olhos, pendia mais que ela). A textura (`_cover_px`) vem esticada linha a linha, em trechos do mesmo tom; os parafusos, redondos por cima, no
## lugar deles (esticados, viravam serrilhado). Rente à madeira: a sombra é uma linha
## só, embaixo e à direita (afastada, ela flutuava).
func _draw_cover(x: float, w: float, side := false) -> void:
	var ym := _shelf_mid()
	var y0 := roundf(ym - COVER_DEPTH / 2.0)
	var plate := Pal.lit(PLATE, _step_at(Vector2(x, ym)))   # no metal das chapas dos setores, pela luz da sala ali
	var span := func(y: float) -> Vector2:   # as beiras da chapa na linha y, ainda sem arredondar
		var r := x + w / 2.0 + (_receding(Vector2(tray_rect().end.x, ym), y) - tray_rect().end.x if side else _lean(y - ym))
		return Vector2(x - w / 2.0 + _lean(y - ym), r)
	for v in int(COVER_DEPTH) + 1:
		var y := y0 + v
		var e: Vector2 = span.call(y)
		var l := roundf(e.x)
		var r := roundf(e.y)
		_ci.draw_rect(Rect2(r, y + 1.0, 1, 1), SHADOW)   # a sombra à direita...
		if v == int(COVER_DEPTH):   # ...e embaixo
			_ci.draw_rect(Rect2(l + 1.0, y + 1.0, r - l, 1), SHADOW)
		var run := l
		var last := Color(0, 0, 0, 0)
		for px in range(int(l), int(r) + 1):
			var c := Color(0, 0, 0, 0) if px == int(r) else \
				_cover_px(int((px + 0.5 - e.x) / (e.y - e.x) * w), v, int(w), plate)
			if px > int(l) and c != last:
				if last.a > 0.0:
					_ci.draw_rect(Rect2(run, y, px - run, 1), last)
				run = px
			last = c
	for c: Vector2 in [Vector2(4, 4), Vector2(w - 4, 4), Vector2(4, COVER_DEPTH - 3), Vector2(w - 4, COVER_DEPTH - 3)]:
		var e: Vector2 = span.call(y0 + c.y)
		var at := Vector2(roundf(lerpf(e.x, e.y, c.x / w)), y0 + c.y)   # redondo, no lugar dele
		PixelArt.sprite(_ci, _disc(4, [[1.0, plate.lightened(0.3), plate.darkened(0.15), plate.darkened(0.4)], [2.0, plate.darkened(0.6)]]), at)


## A cor do pixel `u`, `v` da chapa de `w` de largura, de frente: a beira de fora escura com os cantos quebrados
## (transparentes), o chanfro (luz em cima à esquerda, sombra embaixo à direita), um sulco, o campo mais escuro com
## grão fino sempre no mesmo lugar, como na referência do usuário (os parafusos vêm por cima, `_draw_cover`).
static func _cover_px(u: int, v: int, w: int, plate: Color) -> Color:
	var h := int(COVER_DEPTH)
	var b := mini(mini(u, v), mini(w - 1 - u, h - v))   # a distância à beira mais perto
	if b == 0:
		return Color(0, 0, 0, 0) if (u == 0 or u == w - 1) and (v == 0 or v == h) else plate.darkened(0.55)
	if b == 1:
		if v == 1 and u < w - 2:
			return plate.lightened(0.22)
		return plate.lightened(0.1) if u == 1 and v < h - 1 else plate.darkened(0.3)
	if b == 2:
		return plate.darkened(0.42)
	var g := posmod((u * 73856093) ^ (v * 19349663) ^ (w * 83492791), 17)   # o grão
	return plate.darkened(0.06 if g == 0 else (0.22 if g == 1 else 0.14))


const COVER_DEPTH := 20.0   # da beira de trás à da frente: menos que a prateleira, com madeira à mostra em volta


## Quanto uma reta deitada na prateleira anda para o lado a `dy` linhas (para a frente, à esquerda): a inclinação dos
## pares de plugs (`front_of`), a de tudo que fica deitado nela.
static func _lean(dy: float) -> float:
	return -dy * PAIR_SHIFT / (SHELF_FRONT_Y - SHELF_HOLE_Y)


## A coluna, na linha `y`, da reta deitada na prateleira que passa por `p` e foge para os olhos (`_eye`), como a lateral
## da mesa comutadora.
func _receding(p: Vector2, y: float) -> float:
	return p.x + (_eye.x - p.x) * (y - p.y) / (_eye.y - p.y)


## A linha do meio da prateleira, do pé do painel à beira de latão (o vão do painel à faixa dos buracos se repete até
## ela).
func _shelf_mid() -> float:
	return (tray_rect().position.y + tray_rect().end.y - 1.0) / 2.0


static var _fone_tags := {}   # nome -> textura


## A plaquinha de latão com o nome do FONE na prateleira, na fileira da frente, logo embaixo do buraco dele (reta:
## inclinada pela perspectiva, linha a linha, ficava torta demais).
func _draw_fone_tag() -> void:
	var c := hole(0) + Vector2(0, SHELF_FRONT_Y - SHELF_HOLE_Y)   # na fileira da frente, logo embaixo do buraco do FONE
	var text := T.text(T.Key.FONE_LABEL)
	if not _fone_tags.has(text):
		_fone_tags[text] = _fone_tag(text)
	var tag: Texture2D = _fone_tags[text]
	_ci.draw_texture(tag, (c - Vector2(tag.get_size()) / 2.0 - Vector2(0.5, 0)).round())   # o plug vai de x - 10 a x + 9


## A plaquinha: latão com a quina de cima pegando a luz, a beira no tom dele e as letras gravadas.
static func _fone_tag(text: String) -> Texture2D:
	var letters := PixelArt.tiny(text).get_image()
	var w := letters.get_width() + 6   # beira de 1 e 2 de margem de cada lado...
	w += w % 2   # ...e largura par, como o plug: com o meio entre dois pixels, a placa fica bem embaixo dele
	var out := Image.create(w, 9, false, Image.FORMAT_RGBA8)
	out.fill(HOLE_PAL["b"].darkened(0.35))   # a beira: no tom do latão, na sombra embaixo e à direita...
	out.fill_rect(Rect2i(0, 0, w - 1, 1), HOLE_PAL["b"])   # ...e na luz em cima e à esquerda
	out.fill_rect(Rect2i(0, 0, 1, 8), HOLE_PAL["b"])
	out.fill_rect(Rect2i(1, 1, w - 2, 7), HOLE_PAL["f"])
	out.fill_rect(Rect2i(1, 1, w - 2, 1), HOLE_PAL["F"])
	for y in range(3, 8):   # as letras ocupam as linhas 3 a 7 da imagem
		for x in letters.get_width():
			if letters.get_pixel(x, y).a > 0.5:
				out.set_pixel(3 + x, y - 1, HOLE_PAL["w"])
	return ImageTexture.create_from_image(out)


## Buraco da prateleira visto de cima (achatado pela perspectiva), pixel a pixel (`HOLE_ART`): o aro de latão, com a
## beira de trás na sombra e a da frente pegando a luz, a parede de dentro do lado de trás (olhando de cima, é a que
## aparece) e o vão escuro. Sem contorno preto (destoava do cenário).
static func draw_grommet(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_texture_rect(PixelArt.art(HOLE_ART, HOLE_PAL), _hole_px(c), false)


## A beira da frente do buraco (`draw_grommet`), por cima do plug guardado nele: o plug entra no buraco.
static func draw_lip(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_texture_rect(PixelArt.art(HOLE_ART, {"f": HOLE_PAL["f"], "F": HOLE_PAL["F"]}), _hole_px(c), false)


static func _hole_px(c: Vector2) -> Rect2:
	var size := Vector2((HOLE_ART[0] as String).length(), HOLE_ART.size())
	return Rect2((c - size / 2.0).round(), size)


## O degrau da luz da sala no ponto `p` do painel (`Pal.panel_step`), o mesmo do relevo: as peças de metal paradas
## escolhem o tom por ele, no meio delas.
func _step_at(p: Vector2) -> int:
	return Pal.panel_step(_room_lit(p))


## O níquel das peças paradas do painel no degrau `s` da luz da sala (`_step_at`): o aro (`BEZEL`: luz, meio, sombra) e
## a quina (`NICKEL_EDGE`), mais claros e quentes perto da luminária e mais escuros e frios longe dela (`Pal.lit`).
static func _nickel(s: int) -> Array:
	var out := []
	for c: Color in [BEZEL[0], BEZEL[1], BEZEL[2], NICKEL_EDGE[0], NICKEL_EDGE[1], NICKEL_EDGE[2]]:
		out.append(Pal.lit(c, s))
	return out


## A beira de 1 px em volta de `r`, no tom da própria peça: `lit` em cima e à esquerda, `shade` embaixo e à direita (a
## beira quase preta em volta, `EDGE_DARK`, parecia um contorno de desenho). Num rebaixo, ao contrário: escura em cima.
static func rim(ci: CanvasItem, r: Rect2, lit: Color, shade: Color) -> void:
	ci.draw_rect(r.grow(1), shade)
	ci.draw_rect(Rect2(r.position - Vector2.ONE, Vector2(r.size.x + 1, 1)), lit)
	ci.draw_rect(Rect2(r.position - Vector2.ONE, Vector2(1, r.size.y + 1)), lit)


## Plaquinha creme com o número da linha impresso em escuro, na fonte miúda do painel (`PixelArt.tiny`), no meio
## dela: na de 11 o número enchia a chapa de alto a baixo e parecia grosso.
func _draw_number_plate(r: Rect2, text: String) -> void:
	var s := _step_at(r.get_center())
	var tag := Pal.lit(Pal.BOARD_TAG, s)
	rim(_ci, r, tag.darkened(0.5), tag.darkened(0.65))   # embutida: a beira escura em volta
	_ci.draw_rect(r, tag)
	_ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), tag.lightened(0.15))
	_ci.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), tag.darkened(0.15))
	var tex := PixelArt.tiny(text)
	var at := (r.get_center() - Vector2(tex.get_width() / 2.0, 3.0 + 2.5)).round()   # as letras ficam nas linhas 3 a 7 da imagem
	_ci.draw_texture(tex, at, Pal.lit(Pal.ENGRAVED, s))


## As letras estampadas nas chapas dos bancos, 10×14, desenhadas à mão (traço de 2 px e cantos em degrau de 1 px): na
## fonte em 33, cada pixel dela virava um bloco de 3 px ao lado dos de 1 px do painel.
const PLATE_LETTERS := {
	"A": ["..######..", ".########.", "###....###", "##......##", "##......##", "##......##", "##########",
		"##########", "##......##", "##......##", "##......##", "##......##", "##......##", "##......##"],
	"B": ["########..", "#########.", "##.....###", "##......##", "##.....###", "#########.", "########..",
		"#########.", "##.....###", "##......##", "##......##", "##.....###", "#########.", "########.."],
	"C": ["..######..", ".########.", "###....###", "##......##", "##........", "##........", "##........",
		"##........", "##........", "##........", "##......##", "###....###", ".########.", "..######.."],
}


## Chapa de metal parafusada sobre um banco que ainda não está em uso (lisa: o escovado saiu, a pedido): a letra do
## banco estampada em relevo (luz em cima à esquerda, sombra embaixo à direita), o aviso
## pintado com estêncil embaixo e, em volta dos parafusos, os riscos da chave de fenda que escorregou. Sempre os mesmos.
func _draw_plate(r: Rect2, letter: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(letter)
	var plate := Pal.lit(PLATE, _step_at(r.get_center()))   # no tom da luz da sala no meio dela
	rim(_ci, r, plate.darkened(0.15), plate.darkened(0.5))
	_ci.draw_rect(r, plate)
	_ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), plate.lightened(0.18))
	_ci.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), plate.darkened(0.35))
	for c in [r.position + Vector2(5, 5), Vector2(r.end.x - 5, r.position.y + 5), Vector2(r.position.x + 5, r.end.y - 5), r.end - Vector2(5, 5)]:
		for k in 2:   # a chave de fenda escorregou, sempre para dentro da chapa (para fora, o risco passava da borda)
			var a: float = (r.get_center() - c).angle() + rng.randf_range(-0.6, 0.6)
			var from: Vector2 = c + Vector2.from_angle(a) * 3.0
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.3, 0.3)) * rng.randf_range(2.0, 4.0)
			_ci.draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), plate.lightened(0.3), 1.0)
		PixelArt.sprite(_ci, _disc(5, [[1.5, plate.lightened(0.35), plate.lightened(0.15), plate.darkened(0.2)], [2.5, plate.darkened(0.5)]]), c)
		_ci.draw_rect(Rect2((c - Vector2(2, 1)).floor(), Vector2(3, 1)), plate.darkened(0.5))   # fenda do parafuso
	var rows := PixelArt.relief(PLATE_LETTERS[letter])   # a letra estampada
	var at := (r.get_center() - Vector2(0, 4)).round()
	PixelArt.sprite(_ci, PixelArt.art(rows, {"*": plate.darkened(0.45)}), at + Vector2(1, 1))
	PixelArt.sprite(_ci, PixelArt.art(rows, {"u": plate.lightened(0.35), "d": plate.darkened(0.2), "+": plate.lightened(0.15)}), at)
	var notice := PixelArt.tiny(T.text(T.Key.BOARD_PLATE_NOTICE))   # pintado com estêncil, já gasto
	_ci.draw_texture(notice, Vector2(roundf(r.get_center().x - notice.get_width() / 2.0), roundf(r.get_center().y + 10.0)), Color(Pal.STENCIL, 0.6))
