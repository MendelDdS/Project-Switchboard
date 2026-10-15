extends "res://scripts/ui/switchboard_base.gd"
## O painel da mesa comutadora (`Switchboard`): o móvel de madeira, as faixas gravadas, as plaquinhas, as lâmpadas,
## as tomadas, o desgaste, as chapas dos bancos e a prateleira com os buracos dos cabos.

const DEST_TOP := 141.0      # topo das tomadas da primeira fileira (a segunda fica DEST_ROW px abaixo)
const DEST_ROW := 27.0
const FRAME := 5.0           # a moldura de madeira do móvel, em volta do painel
## Faixas gravadas no painel que separam as seções (altura da linha; o nome fica sobre ela, à esquerda).
const RULES := {"in": 11.0, "out": 78.0}
const CABINET_RAG := 0.05    # o quanto a troca de tom da madeira da moldura anda de um veio para outro, na luz (`_wood_frame`)
## O buraco da prateleira (16×8, achatado pela perspectiva; o vão, 12 de largura, da largura do plug, que entra
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
const HOLE_PAL := {"b": Pal.BRASS_PLATE[2], "f": Pal.BRASS_PLATE[5], "F": Pal.BRASS_PLATE[6], "w": Pal.BRASS_PLATE[1], "h": Pal.BRASS_PLATE[0]}

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
const STRIP_W := 18.0   # a faixa rebaixada de cada linha, da plaquinha à saída
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
	PixelArt.sprite(_ci, _disc(10, [[4.0, BEZEL[0], BEZEL[1], BEZEL[2]], [5.0, NICKEL_EDGE[0], NICKEL_EDGE[1], NICKEL_EDGE[2]]]), c)   # o aro, do tamanho da tomada
	if level > 0.02:
		PixelArt.sprite(_ci, _disc(10, [[3.0, Color.TRANSPARENT], [4.0, Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT]]), c, Color(col, 0.35 * level))   # a luz no aro
	# o vidro abaulado (luz no alto à direita): o aceso por cima do apagado, com `level` no modulate (uma cor por quadro
	# na chave do `disc` guardava uma textura nova a cada quadro da lâmpada pulsando)
	PixelArt.sprite(_ci, _disc(6, [[3.0, LAMP_OFF.lightened(0.3), LAMP_OFF, LAMP_OFF.darkened(0.4)]]), c)
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
	var tones := {"E": NICKEL_EDGE[0], "e": NICKEL_EDGE[2], "P": b, "p": b.darkened(0.25), "L": BEZEL[0], "D": BEZEL[2],
		"l": b.lerp(hi, 0.6), "w": hi.lightened(0.25), "m": b, "d": b.darkened(0.4)}
	for v in levers:
		PixelArt.sprite(_ci, _disc(8, [[4.0, SHADOW]]), v[0] + Vector2(-1, 1))
	for v in levers:
		if v[1] != 0:
			_ci.draw_texture(PixelArt.art(LEVER_ART if v[1] > 0 else LEVER_UP, shade), _lever_corner(v) + Vector2(-1, 1))
	for v in levers:   # a porca (pequena: a haste aparece além dela)
		PixelArt.sprite(_ci, _disc(8, [[1.5, EDGE_DARK], [3.0, BEZEL[0], BEZEL[1], BEZEL[2]], [4.0, NICKEL_EDGE[0], NICKEL_EDGE[1], NICKEL_EDGE[2]]]), v[0])
	for v in levers:
		if v[1] == 0:
			PixelArt.sprite(_ci, _disc(6, [[2.0, b.lerp(hi, 0.6), b, b.darkened(0.4)], [3.0, b, b, b.darkened(0.25)]]), v[0])
		else:
			_ci.draw_texture(PixelArt.art(LEVER_ART if v[1] > 0 else LEVER_UP, tones), _lever_corner(v))


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


## O móvel da mesa: a moldura de madeira (`_wood_frame`), com o brilho da luminária do teto na quina de cima, mais
## forte do lado dela (no meio da tela, à direita da mesa), e o painel de metal escuro dentro, rebaixado, com a beira
## no tom da luz da sala ali (`_lit_rect`).
func _draw_cabinet(r: Rect2) -> void:
	_ci.draw_texture(_wood_frame(r.size), r.position)
	var lamp := get_viewport_rect().size.x / 2.0 - global_position.x
	var glint := func(x: float) -> Color:
		return Color(Pal.CABINET_WOOD[6].lightened(0.45), 0.6 * clampf(1.0 - absf(x - lamp) / 525.0, 0.0, 1.0))
	var top := r.position.y + 1.0
	_ci.draw_primitive(PackedVector2Array([Vector2(r.position.x + 1, top), Vector2(r.end.x - 1, top), Vector2(r.end.x - 1, top + 1), Vector2(r.position.x + 1, top + 1)]),
		PackedColorArray([glint.call(r.position.x), glint.call(r.end.x), glint.call(r.end.x), glint.call(r.position.x)]), PackedVector2Array())
	var p := r.grow(-FRAME)
	var g := p.grow(1)   # a fresta entre a madeira e o painel: na sombra em cima e à esquerda, na luz embaixo e à direita
	var wood := func(step: int) -> Callable: return func(lit: float) -> Color: return Pal.cabinet(lit, step)
	_lit_rect(Rect2(g.position.x, g.end.y - 1, g.size.x, 1), wood.call(0))
	_lit_rect(Rect2(g.end.x - 1, g.position.y, 1, g.size.y), wood.call(0))
	_lit_rect(Rect2(g.position, Vector2(g.size.x, 1)), wood.call(-2))
	_lit_rect(Rect2(g.position, Vector2(1, g.size.y)), wood.call(-2))
	_ci.draw_rect(p, Pal.PANEL)
	_lit_rect(Rect2(p.position, Vector2(p.size.x, 2)), _metal(-2))   # rebaixado: a sombra fica em cima à esquerda
	_lit_rect(Rect2(p.position, Vector2(2, p.size.y)), _metal(-2))
	_lit_rect(Rect2(p.position.x, p.end.y - 1, p.size.x, 1), _metal(2))


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


## A faixa de cada linha: um rebaixo estreito do painel que liga a plaquinha, a lâmpada, a entrada e a saída da mesma
## coluna (sem ela, a saída parecia solta). As faixas gravadas passam por baixo; o nome delas, por cima.
func _draw_strips() -> void:
	for i in 10:
		var r := Rect2(col_x(i) - STRIP_W / 2.0, ROW_Y["plate"] + 3.0, STRIP_W, ROW_Y["out"] + JACK / 2.0 - ROW_Y["plate"])
		_ci.draw_rect(r, Pal.PANEL.darkened(0.05))
		_lit_rect(Rect2(r.position, Vector2(r.size.x, 1)), _metal(-1))   # rebaixada: a sombra em cima e à esquerda
		_lit_rect(Rect2(r.position, Vector2(1, r.size.y)), _metal(-1))
		_lit_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), _metal(1))
		_lit_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), _metal(1))


## O uso de anos: o painel gasto em volta das tomadas (claro liso, mais nas entradas, onde o FONE entra a noite toda,
## e nas primeiras linhas) e riscos finos onde a ponta do plug escorregou errando o furo. Sempre os mesmos.
func _draw_wear() -> void:
	for j in _jacks:
		var use := _use(j)
		PixelArt.sprite(_ci, _disc(20, [[7.0, Color(Pal.PANEL_HI, WEAR[0])], [8.5, Color(Pal.PANEL_HI, WEAR[1])], [10.0, Color(Pal.PANEL_HI, WEAR[2])]]),
			jack_rect(j).get_center(), Color(1, 1, 1, use))
		var rng := RandomNumberGenerator.new()
		rng.seed = j
		for k in roundi(use * 2.0):
			var a := rng.randf() * TAU
			var from := jack_rect(j).get_center() + Vector2.from_angle(a) * rng.randf_range(6.0, 8.0)
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * rng.randf_range(2.0, 4.0)
			_ci.draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), Color(Pal.PANEL_HI, 0.45), 1.0)


## O quanto a tomada `j` é usada (0..1): as entradas mais, das primeiras linhas para as últimas; depois as saídas; os
## destinos, menos.
func _use(j: int) -> float:
	if j <= 10:
		return 1.0 - (j - 1) * 0.05
	if j <= 20:
		return 0.6 - (j - 11) * 0.03
	return 0.35


## A plaqueta de latão do fabricante em `r` (96×26), desenhada pelo cenário na frente do console, ao lado da miniatura
## do painel: o nome da central gravado (escuro, com o brilho embaixo) e um parafuso em cada ponta.
static func draw_maker_plate(ci: CanvasItem, r: Rect2) -> void:
	var pal := HOLE_PAL
	var cx := r.get_center().x
	ci.draw_rect(Rect2(r.position + Vector2(1, 2), r.size), SHADOW)
	rim(ci, r, pal["b"], pal["b"].darkened(0.35))
	ci.draw_rect(r, Pal.BRASS_PLATE[4])
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), pal["F"])
	ci.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), pal["f"])
	ci.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), pal["b"])
	ci.draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), pal["b"])
	ci.draw_rect(r.grow(-3), pal["b"], false, 1.0)   # o friso gravado em volta
	for x in [r.position.x + 7.0, r.end.x - 7.0]:
		PixelArt.sprite(ci, _disc(5, [[1.5, pal["F"], pal["f"], pal["b"]], [2.5, pal["w"]]]), Vector2(x, r.get_center().y))
		ci.draw_rect(Rect2(x - 1.0, r.get_center().y, 3, 1), pal["w"])   # a fenda
	var maker := PixelArt.tiny(T.text(T.Key.BOARD_MAKER))
	var at := Vector2(roundf(cx - maker.get_width() / 2.0), r.position.y + 2.0)
	ci.draw_texture(maker, at + Vector2(0, 1), pal["F"])
	ci.draw_texture(maker, at, pal["w"])
	var town := "SÃO SOTERO"
	var nw := Pal.mono.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var np := Vector2(roundf(cx - nw / 2.0), r.end.y - 6.0)
	ci.draw_string(Pal.mono, np + Vector2(0, 1), town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["F"])
	ci.draw_string(Pal.mono, np, town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["w"])


static var _woods := {}   # as molduras guardadas, por tamanho e lugar da luminária (`_wood_frame`)


## Os troncos interurbanos, no canto de baixo à direita do painel, em `br` (a largura de um banco de destino): um
## banco como os de destino, com o nome gravado na moldura e o da cidade em cima de cada tomada. As tomadas são
## destinos (`GameData.TRUNKS`, posição em `_layout_dests`), desenhadas e acesas com os outros.
func _draw_trunks(br: Rect2) -> void:
	_ci.draw_rect(br, Pal.PANEL_LO, false, 1.0)
	var cap := PixelArt.tiny(T.text(T.Key.BOARD_TRUNKS))   # na moldura, como o nome das faixas
	var at := Vector2(roundf(br.get_center().x - cap.get_width() / 2.0), br.position.y - 5.0)
	_ci.draw_rect(Rect2(at.x - 3.0, br.position.y - 1.0, cap.get_width() + 6.0, 3.0), Pal.PANEL)
	_ci.draw_texture(cap, at, Pal.BRASS)
	for k in GameData.TRUNKS.size():
		var d: int = GameData.TRUNKS[k]
		var label := PixelArt.tiny(T.text(GameData.TRUNK_NAMES[k]))
		var x := jack_rect(d).get_center().x
		_ci.draw_texture(label, Vector2(roundf(x - label.get_width() / 2.0), br.position.y + 4.0),
			Pal.NUMBER_PAINT if exchange.dest(d) == Exchange.Dest.FREE else Pal.TEXT)


## A moldura de madeira do móvel, pixel a pixel e guardada: quatro trilhos com os cantos em meia-esquadria (uma
## emenda escura na diagonal), cada um com os veios ao longo dele, ondulando (os de cima e de baixo deitados, os dos
## lados em pé); a beira escura por fora, a luz em cima e à esquerda, a sombra embaixo e à direita, e as quinas gastas,
## mais claras, de anos de mãos. Cada pixel no tom da madeira pela luz da sala ali (`Pal.cabinet`, `_room_lit`):
## quente perto da luminária e escura e fria no canto longe dela; a troca de tom anda um pouco de um veio para outro
## (`CABINET_RAG`), como na madeira do tampo.
func _wood_frame(sz: Vector2) -> ImageTexture:
	var key := Rect2(_lamp_at, sz)
	if not _woods.has(key):
		if _woods.size() >= 8:
			_woods.clear()
		var w := int(sz.x)
		var h := int(sz.y)
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var f := int(FRAME)
		for y in h:
			for x in w:
				var ex := mini(x, w - 1 - x)   # distância à beira de fora, na horizontal e na vertical
				var ey := mini(y, h - 1 - y)
				if ex >= f and ey >= f:
					continue   # o painel
				var upright := ex < ey   # nos cantos, a emenda em diagonal decide o trilho
				var rail := (0 if x < w / 2 else 1) if upright else (2 if y < h / 2 else 3)
				var along := float(y if upright else x)
				var across := float(ex if upright else ey)
				var g := fposmod(across + 1.4 * sin(along * 0.035 + rail * 2.1) + 0.7 * sin(along * 0.11 + rail * 4.3), 3.0)
				var step := 0   # tons acima ou abaixo do tom da madeira ali
				if g < 0.55:
					step = -1   # o veio escuro
				elif g > 1.6 and g < 1.9:
					step = 1    # o claro entre os veios
				if ex == ey and ex < f:
					step = -2   # a emenda do canto
				var corner := Vector2(mini(x, w - 1 - x), mini(y, h - 1 - y)).length()
				step += 2 if corner < 3.0 else (1 if corner < 7.0 else 0)   # quina gasta
				if x == 0 or y == 0:
					step = 0    # a quina de fora, arredondada: no tom da madeira (escura, parecia um contorno)
				elif x == w - 1 or y == h - 1:
					step = -3
				elif (x == 1 or y == 1) and x < w - 2 and y < h - 2:
					step = 2    # a luz em cima e à esquerda
				elif x == w - 2 or y == h - 2:
					step = -2
				var rag := fposmod(sin(across * 12.9898 + rail * 7.13 + floorf(along / 11.0) * 3.71) * 43758.55, 1.0) - 0.5
				img.set_pixel(x, y, Pal.cabinet(_room_lit(Vector2(x, y)) + rag * CABINET_RAG, step))
		_woods[key] = ImageTexture.create_from_image(img)
	return _woods[key]


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
	_ci.draw_rect(Rect2(x - 4, y - 6, width + 8, 12), Pal.PANEL)   # tampa a faixa, como o nome dela
	for k in leg.size():
		PixelArt.sprite(_ci, _disc(7, [[2.0, Color.WHITE], [3.5, Color.TRANSPARENT]]), Vector2(x + 3.5, y), leg[k][0])   # lâmpadas redondas, como as da mesa
		PixelArt.sprite(_ci, _disc(7, [[2.0, Color.TRANSPARENT], [3.5, NICKEL_EDGE[0], NICKEL_EDGE[1], NICKEL_EDGE[2]]]), Vector2(x + 3.5, y))
		_ci.draw_texture(texts[k], Vector2(x + 10.0, y - 5.0), Pal.DIM)
		x += 7.0 + 3.0 + (texts[k] as Texture2D).get_width() + 8.0


## Faixa gravada que separa as seções do painel, com o nome dela em cima, à esquerda, na fonte gravada do painel como a legenda (`tiny`; em 11 enchia a
## faixa e encostava nas plaquinhas) (sem nome, só a faixa; sem
## `line`, só o nome).
func _draw_rule(y: float, caption: String, line := true) -> void:
	if line:
		_lit_rect(Rect2(FRAME + 5, y, size.x - FRAME * 2 - 10, 1), _metal(-2))
		_lit_rect(Rect2(FRAME + 5, y + 1, size.x - FRAME * 2 - 10, 1), _metal(2))
	if caption != "":
		var t := PixelArt.tiny(caption)
		_ci.draw_rect(Rect2(FRAME + 10, y - 5, t.get_width() + 8, 12), Pal.PANEL)   # como a da legenda
		_ci.draw_texture(t, Vector2(FRAME + 14, y - 4), Pal.BRASS)   # as letras nas linhas 3 a 7: em volta da faixa


## A prateleira à frente do painel, onde os cabos de conexão ficam guardados de pé: os buracos de onde saem os fios
## (a cor de cada cabo já diz qual é; o nome gravado embaixo saiu, a pedido).
func _draw_tray() -> void:
	_draw_fone_tag()
	for k in patches:
		for e in [1 + k * 2, 2 + k * 2]:
			draw_grommet(_ci, hole(e))
	for k in range(patches, SHELF_SLOTS):   # cada setor novo traz um cabo: até lá, o lugar dele fica tampado
		_draw_cover(k)


const COVER_W := 26.0   # a largura do tampo: cobre os buracos do par, com um vão até o lugar seguinte


## O lugar vago do cabo `k` na prateleira, sob um tampo de metal parafusado, deitado nela: linha a linha de pixels,
## na inclinação dos pares de buracos (`front_of`: a ponta da frente à esquerda da de trás), por cima dos dois.
func _draw_cover(k: int) -> void:
	var back := Vector2(patch_x(k), tray_rect().position.y + SHELF_HOLE_Y)
	var front := front_of(back)
	var y0 := back.y - 5.0
	var y1 := front.y + 5.0
	var at := func(y: float) -> float:   # o meio do tampo na linha y: na reta do buraco de trás ao da frente
		return roundf(back.x + (front.x - back.x) * (y - back.y) / (front.y - back.y))
	for y in range(int(y0), int(y1) + 1):
		var x: float = at.call(y)
		_ci.draw_rect(Rect2(x - COVER_W / 2.0 + 1.0, y + 2.0, COVER_W, 1), SHADOW)
		_ci.draw_rect(Rect2(x - COVER_W / 2.0 - 1.0, y, COVER_W + 2.0, 1), Pal.PANEL.darkened(0.3))   # a beira do tampo
		var c: Color = Pal.PANEL_HI if y == int(y0) else (Pal.PANEL_LO if y == int(y1) else Pal.PANEL.lightened(0.06))
		_ci.draw_rect(Rect2(x - COVER_W / 2.0, y, COVER_W, 1), c)
	for sy in [y0 + 3.0, y1 - 3.0]:   # um parafuso de latão em cada canto, com a fenda
		for dx in [-COVER_W / 2.0 + 4.0, COVER_W / 2.0 - 4.0]:
			var sp := Vector2(at.call(sy) + dx, sy)
			PixelArt.sprite(_ci, _disc(5, [[1.5, HOLE_PAL["F"], HOLE_PAL["f"], HOLE_PAL["b"]], [2.5, HOLE_PAL["w"]]]), sp)
			_ci.draw_rect(Rect2(sp.x - 1.0, sy, 3, 1), HOLE_PAL["w"])


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


## Chapa de metal niquelado: chanfro claro em cima e escuro embaixo, e um rebite em cada ponta.
func _draw_metal(r: Rect2) -> void:
	rim(_ci, r, NICKEL_EDGE[0], NICKEL_EDGE[2])
	_ci.draw_rect(r, BEZEL[1])
	_ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), BEZEL[0])
	_ci.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), BEZEL[0].darkened(0.1))
	_ci.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), BEZEL[2])
	_ci.draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), BEZEL[2].lightened(0.1))
	for x in [r.position.x + 2.0, r.end.x - 5.0]:   # rebites: um pixel claro no alto de um escuro
		var rv := Vector2(x, floorf(r.get_center().y - 1.5))
		_ci.draw_rect(Rect2(rv, Vector2(3, 3)), BEZEL[2])
		_ci.draw_rect(Rect2(rv, Vector2(1, 1)), BEZEL[0])


## A beira de 1 px em volta de `r`, no tom da própria peça: `lit` em cima e à esquerda, `shade` embaixo e à direita (a
## beira quase preta em volta, `EDGE_DARK`, parecia um contorno de desenho). Num rebaixo, ao contrário: escura em cima.
static func rim(ci: CanvasItem, r: Rect2, lit: Color, shade: Color) -> void:
	ci.draw_rect(r.grow(1), shade)
	ci.draw_rect(Rect2(r.position - Vector2.ONE, Vector2(r.size.x + 1, 1)), lit)
	ci.draw_rect(Rect2(r.position - Vector2.ONE, Vector2(1, r.size.y + 1)), lit)


## Plaquinha de metal com o número da linha gravado (escuro, com o brilho embaixo de quem foi rebaixado), na fonte
## miúda do painel (`PixelArt.tiny`), no meio dela: na de 11 o número enchia a chapa de alto a baixo e parecia grosso.
func _draw_number_plate(r: Rect2, text: String) -> void:
	_draw_metal(r)
	var tex := PixelArt.tiny(text)
	var at := (r.get_center() - Vector2(tex.get_width() / 2.0, 3.0 + 2.5)).round()   # as letras ficam nas linhas 3 a 7 da imagem
	_ci.draw_texture(tex, at + Vector2(0, 1), BEZEL[0])   # o brilho do rebaixo
	_ci.draw_texture(tex, at, Pal.ENGRAVED)


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
	rim(_ci, r, PLATE.darkened(0.15), PLATE.darkened(0.5))
	_ci.draw_rect(r, PLATE)
	_ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), PLATE.lightened(0.18))
	_ci.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), PLATE.darkened(0.35))
	for c in [r.position + Vector2(5, 5), Vector2(r.end.x - 5, r.position.y + 5), Vector2(r.position.x + 5, r.end.y - 5), r.end - Vector2(5, 5)]:
		for k in 2:   # a chave de fenda escorregou, sempre para dentro da chapa (para fora, o risco passava da borda)
			var a: float = (r.get_center() - c).angle() + rng.randf_range(-0.6, 0.6)
			var from: Vector2 = c + Vector2.from_angle(a) * 3.0
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.3, 0.3)) * rng.randf_range(2.0, 4.0)
			_ci.draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), PLATE.lightened(0.3), 1.0)
		PixelArt.sprite(_ci, _disc(5, [[1.5, PLATE.lightened(0.35), PLATE.lightened(0.15), PLATE.darkened(0.2)], [2.5, PLATE.darkened(0.5)]]), c)
		_ci.draw_rect(Rect2((c - Vector2(2, 1)).floor(), Vector2(3, 1)), PLATE.darkened(0.5))   # fenda do parafuso
	var rows := PixelArt.relief(PLATE_LETTERS[letter])   # a letra estampada
	var at := (r.get_center() - Vector2(0, 4)).round()
	PixelArt.sprite(_ci, PixelArt.art(rows, {"*": PLATE.darkened(0.45)}), at + Vector2(1, 1))
	PixelArt.sprite(_ci, PixelArt.art(rows, {"u": PLATE.lightened(0.35), "d": PLATE.darkened(0.2), "+": PLATE.lightened(0.15)}), at)
	var notice := PixelArt.tiny(T.text(T.Key.BOARD_PLATE_NOTICE))   # pintado com estêncil, já gasto
	_ci.draw_texture(notice, Vector2(roundf(r.get_center().x - notice.get_width() / 2.0), roundf(r.get_center().y + 10.0)), Color(Pal.STENCIL, 0.6))
