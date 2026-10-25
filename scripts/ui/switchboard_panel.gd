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
const JACK_GLINT_COLOR := Color(0.94, 0.98, 1.0, 0.85)   # o brilho frio do cromado
const JACK_PX := 12   # o lado do desenho do encaixe, em pixels
## A quina do níquel descendo até o painel: na luz, no meio e na sombra. No lugar de uma beira quase preta, que em
## volta das tomadas, das lâmpadas e das plaquinhas parecia um contorno preto.
const NICKEL_EDGE := Pal.NICKEL_EDGE
const SHADOW := Color(0, 0, 0, 0.35)
const PLATE := Pal.BANK_PLATE   # chapa sobre o banco que ainda não está em uso
const LAMP_R := 2.5         # o raio da luz da lâmpada de cada linha, no `Bloom` (a cúpula tem 3; o aro creme fica em volta)
const BEZEL := [Pal.NICKEL[1], Pal.NICKEL[2], Pal.NICKEL[3]]   # aro niquelado: luz, meio, sombra
const LAMP_OFF := Pal.LAMP_GLASS
const ROUND := [2, 1]   # o canto redondo dos blocos, das abas e das chapas: o quanto as duas linhas da ponta recuam (`round_rect`)
const BADGE := "CTSS"   # a sigla da companhia no emblema (`_draw_badge`), igual em todos os idiomas
const LAMP_ON_SEC := 0.06    # a lâmpada (de filamento) acende quase na hora...
const LAMP_OFF_SEC := 0.18   # ...e apaga mais devagar, o filamento esfriando: a linha tocando pulsa em vez de piscar seco
const CORD_COLORS := Pal.CORDS


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


## Lâmpada de plástico fosco, como a tecla de escuta: uma cúpula lisa num aro do plástico creme do móvel. Apagada,
## leitosa (`LAMP_OFF`); acesa, toda de uma cor só, a beira um pouco mais apagada, com a luz opaca em volta (sem miolo
## branco nem brilho de vidro: o halo é do `Bloom`), e o aro pega a cor dela.
func _draw_lamp(c: Vector2, col: Color, level: float) -> void:
	var lit := _room_lit(c)
	var ring := func(step: int) -> Color: return Pal.cabinet(lit, step)
	PixelArt.sprite(_ci, _disc(10, [[4.0, ring.call(2), ring.call(0), ring.call(-2)], [5.0, ring.call(-1), ring.call(-3), ring.call(-4)]]), c)
	if level > 0.02:
		PixelArt.sprite(_ci, _disc(10, [[3.0, Color.TRANSPARENT], [4.0, Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT]]), c, Color(col, 0.35 * level))   # a luz no aro
	# a cúpula: a acesa por cima da apagada, com `level` no modulate (uma cor por quadro na chave do `disc` guardava uma
	# textura nova a cada quadro da lâmpada pulsando)
	var glass := Pal.lit(LAMP_OFF, _step_at(c))
	PixelArt.sprite(_ci, _disc(6, [[2.0, glass], [3.0, glass.darkened(0.2)]]), c)
	if level > 0.02:
		PixelArt.sprite(_ci, _disc(6, [[2.0, col.lightened(0.25)], [3.0, col]]), c, Color(1, 1, 1, level))
		Bloom.light(_ci, Rect2(c - Vector2(LAMP_R, LAMP_R), Vector2(LAMP_R, LAMP_R) * 2.0), Color(col, level), 1.0, false, true)


## As chaves de escuta, teclas quadradas de plástico ciano (como as dos terminais da série Ruptura), cada uma num
## rebaixo escuro do painel: solta, a tecla sai dele (o topo e, embaixo, a frente dela, mais escura, com a sombra embaixo
## à esquerda: a luz vem do alto à direita, `LIGHT`); presa (escutando, ou o destino tocando), afunda rente ao painel e
## acende por inteiro, fosca, de uma cor só (`Pal.KEY_GLOW`). Cada uma em `levers` é [centro, direção, px além]: presa (-1),
## solta (1) ou no meio do caminho (0), `over` px além, na batida.
func _draw_levers(levers: Array) -> void:
	var k := Pal.KEY_CAP
	for v in levers:
		var c: Vector2 = (v[0] as Vector2).round()
		var s := _step_at(c)
		var well := Rect2(c - Vector2(5, 5), Vector2(10, 10))
		_ci.draw_rect(well, Pal.BOARD_INSET)
		_ci.draw_rect(Rect2(well.position.x, well.end.y, well.size.x, 1), _metal_at(c, 2))   # a beira de baixo, na luz
		_ci.draw_rect(Rect2(well.end.x, well.position.y, 1, well.size.y + 1), _metal_at(c, 2))
		var dir: int = v[1]
		var lift := clampi((2 if dir > 0 else 1 if dir == 0 else 0) + dir * roundi(v[2]), 0, 3)   # a altura da frente
		var t := clampi(2 + s, 1, k.size() - 2)   # o tom do topo, na luz da sala
		var top := Rect2(c.x - 4, c.y - 3 - lift, 8, 7)
		if lift > 0:
			_ci.draw_rect(Rect2(top.position + Vector2(-1, 1), Vector2(8, 7 + lift)), SHADOW)
			_ci.draw_rect(Rect2(top.position.x, top.end.y, 8, lift), k[t - 1])   # a frente da tecla
		if dir < 0:   # presa: a tecla toda acesa por dentro, fosca: uma cor só, a beira um pouco mais apagada, luz opaca sem miolo
			var glow := Pal.KEY_GLOW
			_ci.draw_rect(top, glow.darkened(0.2))
			_ci.draw_rect(top.grow(-1), glow)
			Bloom.light(_ci, top, glow, 0.6, false)
			continue
		_ci.draw_rect(top, k[t])
		_ci.draw_rect(Rect2(top.position, Vector2(8, 1)), k[t + 1])   # a quina de cima e a da direita, na luz
		_ci.draw_rect(Rect2(top.end.x - 1, top.position.y, 1, 7), k[t + 1])
		_ci.draw_rect(Rect2(top.position.x, top.position.y + 1, 1, 6), k[t - 1])


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


## A etiqueta do fabricante em `r` (96×32), creme e impressa em oliva escuro, colada na placa da frente do console
## (desenhada pelo cenário, ao lado da miniatura do painel), sem parafusos nem relevo. Com 26 de altura,
## o acento do Ô caía no friso e o til de "SÃO" encostava no pé da linha de cima: agora há 1 px livre entre eles.
static func draw_maker_plate(ci: CanvasItem, r: Rect2) -> void:
	var ink := Pal.BOARD_STRIP
	var cx := r.get_center().x
	round_rect(ci, r.grow(1), Pal.BOARD_SIDE.darkened(0.5))   # colada rente na placa
	round_rect(ci, r, Pal.BOARD_TAG)
	ci.draw_rect(Rect2(r.position.x + 2, r.position.y, r.size.x - 4, 1), Pal.BOARD_TAG.lightened(0.15))
	var maker := PixelArt.tiny(T.text(T.Key.BOARD_MAKER))
	ci.draw_texture(maker, Vector2(roundf(cx - maker.get_width() / 2.0), r.position.y + 5.0), ink)
	ci.draw_rect(Rect2(r.position.x + 8, r.position.y + 14, r.size.x - 16, 1), ink)   # o filete impresso entre as linhas
	var town := "SÃO SOTERO"
	var nw := Pal.mono.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	ci.draw_string(Pal.mono, Vector2(roundf(cx - nw / 2.0), r.end.y - 6.0), town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)


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
		PixelArt.sprite(_ci, _disc(7, [[2.0, Color.TRANSPARENT], [3.5, Pal.SHELL[6], Pal.SHELL[4], Pal.SHELL[2]]]), Vector2(x + 3.5, y))   # o aro creme, como o das lâmpadas
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
		round_rect(_ci, tab, Pal.BOARD_STRIP)
		_ci.draw_rect(Rect2(tab.position.x + 2, tab.end.y, tab.size.x - 4, 1), _metal_at(tab.position, 2))   # a beira de baixo, na luz
		_ci.draw_texture(t, Vector2(FRAME + 10, y - 4), Pal.BOARD_INK)   # as letras nas linhas 3 a 7: em volta da faixa


## A faixa escura do alto do painel, de ponta a ponta, onde vão o nome das entradas e a legenda das lâmpadas.
func _draw_header() -> void:
	var r := Rect2(FRAME + 3, RULES["in"] - 5, size.x - FRAME * 2 - 6, 12)
	round_rect(_ci, r, Pal.BOARD_STRIP)
	_lit_rect(Rect2(r.position.x + 2, r.end.y, r.size.x - 4, 1), _metal(2))


## O emblema da companhia no vão à esquerda do interurbano, acima dos plugs guardados, com o meio em `c`: um oval
## ciano com a beira e a sigla em creme, como o logotipo nos terminais da série Ruptura.
func _draw_badge(c: Vector2) -> void:
	badge(_ci, c, Pal.BOARD_INK, Pal.KEY_CAP[2], 20.0, 12)


## O selo oval da companhia (`BADGE`) em `ci`, no meio `c`: o texto e a beira na cor `ink` e, dentro dela, o oval em
## `fill` (transparente: só a beira, como o selo impresso nos papéis, `PunchCard`, `TollTicket`); `pad` px de folga
## em volta do texto e `h` de altura.
static func badge(ci: CanvasItem, c: Vector2, ink: Color, fill: Color, pad: float, h: int) -> void:
	var t := PixelArt.tiny(BADGE)
	var w := t.get_width() + pad
	var r := Rect2((c - Vector2(w, h) / 2.0).round(), Vector2(w, h))
	var mid := r.get_center().x
	for y in h:   # pixel a pixel, linha a linha: a beira e, dentro dela, o oval
		var dy := y + 0.5 - h / 2.0
		var hw := roundf(w / 2.0 * sqrt(1.0 - pow(dy / (h / 2.0), 2.0)))
		var hi := roundf((w / 2.0 - 1.5) * sqrt(1.0 - pow(dy / (h / 2.0 - 1.0), 2.0))) if absf(dy) < h / 2.0 - 1.0 else -1.0
		if hi < 0.0:
			ci.draw_rect(Rect2(mid - hw, r.position.y + y, hw * 2.0, 1), ink)
			continue
		ci.draw_rect(Rect2(mid - hw, r.position.y + y, hw - hi, 1), ink)
		ci.draw_rect(Rect2(mid + hi, r.position.y + y, hw - hi, 1), ink)
		if fill.a > 0.0:
			ci.draw_rect(Rect2(mid - hi, r.position.y + y, hi * 2.0, 1), fill)
	ci.draw_texture(t, (r.get_center() - Vector2(t.get_width() / 2.0, 3.0 + 2.5)).round(), ink)


## Um retângulo cheio de cantos redondos, pixel a pixel: `cut` diz quanto cada linha da ponta recua, de fora para
## dentro (`ROUND`, o canto dos blocos; [1], o das plaquinhas).
static func round_rect(ci: CanvasItem, r: Rect2, col: Color, cut: Array = ROUND) -> void:
	var n := cut.size()
	ci.draw_rect(Rect2(r.position.x, r.position.y + n, r.size.x, r.size.y - n * 2), col)
	for i in n:
		var w: float = r.size.x - cut[i] * 2
		ci.draw_rect(Rect2(r.position.x + cut[i], r.position.y + i, w, 1), col)
		ci.draw_rect(Rect2(r.position.x + cut[i], r.end.y - 1 - i, w, 1), col)


## Um bloco rebaixado no painel (os bancos de destino, o interurbano), de cantos redondos: o fundo escuro, com a
## sombra da beira em cima e à esquerda e a luz embaixo e à direita.
func _draw_inset(r: Rect2) -> void:
	var g := r.grow(1)
	round_rect(_ci, g, _metal_at(r.end, 2))
	round_rect(_ci, Rect2(g.position, g.size - Vector2.ONE), _metal_at(r.position, -2))
	round_rect(_ci, r, Pal.BOARD_INSET)


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
	var plate := Pal.cabinet(_room_lit(Vector2(x, ym)), 1)   # o plástico creme do móvel, pela luz da sala ali
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


## A cor do pixel `u`, `v` da tampa de `w` de largura, de frente: plástico liso encaixado na prateleira, sem
## parafusos nem grão (como tudo na série Ruptura): a fresta em volta, escura, com os cantos quebrados (transparentes),
## e a quina (luz em cima à esquerda, sombra embaixo à direita).
static func _cover_px(u: int, v: int, w: int, plate: Color) -> Color:
	var h := int(COVER_DEPTH)
	var b := mini(mini(u, v), mini(w - 1 - u, h - v))   # a distância à beira mais perto
	if b == 0:
		return Color(0, 0, 0, 0) if (u <= 1 or u >= w - 2) and (v <= 1 or v >= h - 1) and (u == 0 or u == w - 1 or v == 0 or v == h) else plate.darkened(0.45)
	if b == 1:
		if v == 1 or u == 1:
			return plate.lightened(0.12)
		return plate.darkened(0.15)
	return plate


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
## beira quase preta em volta parecia um contorno de desenho). Num rebaixo, ao contrário: escura em cima.
static func rim(ci: CanvasItem, r: Rect2, lit: Color, shade: Color) -> void:
	ci.draw_rect(r.grow(1), shade)
	ci.draw_rect(Rect2(r.position - Vector2.ONE, Vector2(r.size.x + 1, 1)), lit)
	ci.draw_rect(Rect2(r.position - Vector2.ONE, Vector2(1, r.size.y + 1)), lit)


## Plaquinha creme com o número da linha impresso em escuro, na fonte miúda do painel (`PixelArt.tiny`), no meio
## dela: na de 11 o número enchia a chapa de alto a baixo e parecia grosso.
func _draw_number_plate(r: Rect2, text: String) -> void:
	var s := _step_at(r.get_center())
	var tag := Pal.lit(Pal.BOARD_TAG, s)
	round_rect(_ci, r.grow(1), tag.darkened(0.55), [1])   # embutida: a beira escura em volta
	round_rect(_ci, r, tag, [1])
	_ci.draw_rect(Rect2(r.position.x + 1, r.position.y, r.size.x - 2, 1), tag.lightened(0.15))
	_ci.draw_rect(Rect2(r.position.x + 1, r.end.y - 1, r.size.x - 2, 1), tag.darkened(0.15))
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


## Tampa lisa de cantos redondos sobre um banco que ainda não está em uso, encaixada, sem parafusos (limpa, como
## tudo na série Ruptura; os parafusos e os riscos da chave de fenda saíram): a letra do banco estampada em relevo (luz
## em cima à esquerda, sombra embaixo à direita) e o aviso pintado com estêncil embaixo.
func _draw_plate(r: Rect2, letter: String) -> void:
	var plate := Pal.lit(PLATE, _step_at(r.get_center()))   # no tom da luz da sala no meio dela
	round_rect(_ci, r.grow(1), plate.darkened(0.5))
	round_rect(_ci, r, plate)
	for i in ROUND.size():   # a luz na beira de cima e a sombra na de baixo, seguindo o canto
		var cut: int = ROUND[i]
		_ci.draw_rect(Rect2(r.position.x + cut, r.position.y + i, r.size.x - cut * 2, 1), plate.lightened(0.18))
		_ci.draw_rect(Rect2(r.position.x + cut, r.end.y - 1 - i, r.size.x - cut * 2, 1), plate.darkened(0.35))
	var rows := PixelArt.relief(PLATE_LETTERS[letter])   # a letra estampada
	var at := (r.get_center() - Vector2(0, 4)).round()
	PixelArt.sprite(_ci, PixelArt.art(rows, {"*": plate.darkened(0.45)}), at + Vector2(1, 1))
	PixelArt.sprite(_ci, PixelArt.art(rows, {"u": plate.lightened(0.35), "d": plate.darkened(0.2), "+": plate.lightened(0.15)}), at)
	var notice := PixelArt.tiny(T.text(T.Key.BOARD_PLATE_NOTICE))   # pintado com estêncil, já gasto
	_ci.draw_texture(notice, Vector2(roundf(r.get_center().x - notice.get_width() / 2.0), roundf(r.get_center().y + 10.0)), Color(Pal.STENCIL, 0.85))
