extends "res://scripts/ui/switchboard_base.gd"
## O painel da mesa comutadora (`Switchboard`): o móvel de madeira, as faixas gravadas, as plaquinhas, as lâmpadas,
## as tomadas, o desgaste, as chapas dos bancos e a prateleira com os buracos dos cabos.

const DEST_TOP := 211.0      # topo das tomadas da primeira fileira (a segunda fica DEST_ROW px abaixo)
const DEST_ROW := 46.0
const SIZE := Vector2(588, 362)
const FRAME := 7.0           # a moldura de madeira do móvel, em volta do painel
## Faixas gravadas no painel que separam as seções (altura da linha; o nome fica sobre ela, à esquerda).
const RULES := {"in": 22.0, "out": 131.0, "dest": 181.0}
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]   # madeira do móvel e da bandeja: luz, meio, sombra
## O buraco da prateleira (28×14, achatado pela perspectiva; o vão, 22 de largura, mais largo que o plug, que entra
## nele): b, a beira de trás do aro (na sombra); f e F, a da frente (na luz, com o brilho); w, a parede de dentro do lado
## de trás; h, o vão. As linhas são de elipses de pixel art (`draw_grommet`).
const HOLE_ART := [
	".........bbbbbbbbbb.........",
	"......bbbbbbbbbbbbbbbb......",
	"...bbbbbwwwwwwwwwwwwbbbbb...",
	"..bbbbwwwwwwhhhhwwwwwwbbbb..",
	".bbbwwwhhhhhhhhhhhhhhwwwbbb.",
	"bbbwwhhhhhhhhhhhhhhhhhhwwbbb",
	"bbbwhhhhhhhhhhhhhhhhhhhhwbbb",
	"fffhhhhhhhhhhhhhhhhhhhhhhfff",
	"fffhhhhhhhhhhhhhhhhhhhhhhfff",
	".fffhhhhhhhhhhhhhhhhhhhhfff.",
	"..ffffhhhhhhhhhhhhhhhhffff..",
	"...fffffhhhhhhhhhhhhfffff...",
	"......ffFffffffffffFff......",
	".........FFFFFFFFFF.........",
]
const HOLE_PAL := {"b": Color("7a6230"), "f": Color("c4a35a"), "F": Color("e6cf8e"), "w": Color("3a2a12"), "h": Color("140d06")}

var _lit := {}   ## lâmpada ("l3" linha, "d312" destino) -> [cor, quanto está acesa 0..1]; a cor fica enquanto apaga

## O encaixe, pixel a pixel (16×16, menor que o `JACK`; par, para o meio dele cair entre dois pixels, como o das
## plaquinhas e das lâmpadas), na medida da ponta do plug: o furo preto tem 8 px, a largura da luva (com 20, a tomada
## ficava grande demais para ela). Um aro niquelado fino (2 a 3 pixels) com a beira escura por fora, em volta do furo.
## A luz (alto à esquerda) bate na face do aro desse lado, com um fio de brilho no meio dele, e, por dentro, na parede
## do furo do lado oposto (embaixo à direita). Os dois círculos (16 e 10 pixels) têm as larguras de linha das
## circunferências de pixel art (6, 10, 12, 14...): com outros raios saíam com lados retos, como um octógono; a beira e
## o chanfro têm sempre 1 pixel. As cores vêm de `_jack_pal`.
const JACK_ART := [
	".....eeeeee.....",
	"...eeLLLMMMee...",
	"..eLlllLLMMDDe..",
	".eLllLddddMMDDe.",
	".eLlldhhhhkMDDe.",
	"eLlldhhhhhhkMDDe",
	"eLldhhhhhhhhkMDe",
	"eLldhhhhhhhhWMDe",
	"eMLdhhhhhhhhWDDe",
	"eMLkhhhhhhhkWDDe",
	"eMMDkhhhhhkWDDde",
	".eDMDkkkkWWdDde.",
	".eDMMDdkWWdddde.",
	"..eDDDDDDdddde..",
	"...eeDDDDddee...",
	".....eeeeee.....",
]
const JACK_PX := 16   # o lado do `JACK_ART`, em pixels
const EDGE_DARK := Color("1c130b")   # a beira das peças: marrom quase preto, não preto puro
const SHADOW := Color(0, 0, 0, 0.35)
const PLATE := Color("4d483d")   # chapa sobre o banco que ainda não está em uso
const LAMP_R := 4.5         # raio do vidro da lâmpada de cada linha (o aro de metal fica em volta)
const BEZEL := [Color("d6d1c3"), Color("8e897c"), Color("45413a")]   # aro niquelado: luz, meio, sombra
const LAMP_OFF := Color("6b6556")   # o vidro leitoso da lâmpada apagada (escuro, parecia o furo de uma tomada)
const STRIP_W := 30.0   # a faixa rebaixada de cada linha, da plaquinha à saída
const WEAR := [0.5, 0.3, 0.15]   # o painel gasto em volta das tomadas: do perto ao longe (o quanto clareia)
const LAMP_ON_SEC := 0.06    # a lâmpada (de filamento) acende quase na hora...
const LAMP_OFF_SEC := 0.18   # ...e apaga mais devagar, o filamento esfriando: a linha tocando pulsa em vez de piscar seco


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
	PixelArt.sprite(self, PixelArt.disc(16, [[7.0, BEZEL[0], BEZEL[1], BEZEL[2]], [8.0, EDGE_DARK]]), c)   # o aro
	if level > 0.02:
		PixelArt.sprite(self, PixelArt.disc(16, [[6.0, Color.TRANSPARENT], [7.0, Color.WHITE, Color.TRANSPARENT, Color.TRANSPARENT]]), c, Color(col, 0.35 * level))   # a luz no aro
	# o vidro abaulado (luz no alto à esquerda): o aceso por cima do apagado, com `level` no modulate (uma cor por quadro
	# na chave do `disc` guardava uma textura nova a cada quadro da lâmpada pulsando)
	PixelArt.sprite(self, PixelArt.disc(12, [[6.0, LAMP_OFF.lightened(0.3), LAMP_OFF, LAMP_OFF.darkened(0.4)]]), c)
	if level > 0.02:   # acesa: o centro estoura para o branco (o halo é do Bloom; o miolo nítido, daqui)
		PixelArt.sprite(self, PixelArt.disc(12, [[6.0, col.lightened(0.3), col, col.darkened(0.4)]]), c, Color(1, 1, 1, level))
		PixelArt.sprite(self, PixelArt.disc(6, [[2.8, Color.WHITE]]), c, Color(Color.WHITE.lerp(col, Bloom.HOT_TINT), level))
		Bloom.light(self, Rect2(c - Vector2(LAMP_R, LAMP_R), Vector2(LAMP_R, LAMP_R) * 2.0), Color(col, level), 1.0, false, true)
	draw_rect(Rect2(c + Vector2(-3, -4), Vector2(2, 1)), Color(1, 1, 1, 0.5))   # o brilho da sala no vidro
	draw_rect(Rect2(c + Vector2(-4, -3), Vector2(1, 1)), Color(1, 1, 1, 0.25))


## Encaixe redondo como os das mesas antigas, pixel a pixel (`JACK_ART`), com a sombra no painel. `dim`: o metal mais
## escuro (`_jack_pal`).
func _draw_jack(jr: Rect2, dim := 0.0) -> void:
	var r := _jack_px(jr)
	draw_texture_rect(PixelArt.art(JACK_ART, {"*": Color(0, 0, 0, 0.35)}), Rect2(r.position + Vector2(1, 2), r.size), false)
	draw_texture_rect(PixelArt.art(JACK_ART, _jack_pal(dim)), r, false)


## Onde o desenho do encaixe `jr` fica (`JACK_PX` em volta do meio dele).
func _jack_px(jr: Rect2) -> Rect2:
	return Rect2(jr.get_center() - Vector2(JACK_PX, JACK_PX) / 2.0, Vector2(JACK_PX, JACK_PX))


## As cores do encaixe: níquel (`dim` escurece o metal: as saídas, para não se confundirem com as entradas).
func _jack_pal(dim: float) -> Dictionary:
	var pal := {"l": Color("f3eee0"), "L": Color("cfc3a9"), "M": Color("8e8272"), "D": Color("4f4840"),
		"d": Color("35302a"), "W": Color("e0d6c0")}
	for k in pal:
		pal[k] = (pal[k] as Color).darkened(dim)
	pal.merge({"e": Color("0b0907"), "h": Color("050403"), "k": Color("1e1b17")})
	return pal


## A luz de uma lâmpada batendo no aro do encaixe logo abaixo dela (o lado de cima, virado para a luz).
func _reflect(jr: Rect2, col: Color, level: float) -> void:
	if level > 0.02:
		draw_texture_rect(PixelArt.art(JACK_ART, {"l": Color.WHITE, "L": Color.WHITE}), _jack_px(jr), false, Color(col, 0.55 * level))


## O móvel da mesa: a moldura de madeira (`_wood_frame`), com o brilho da luminária do teto na quina de cima, mais
## forte do lado dela (no meio da tela, à direita da mesa), e o painel de metal escuro dentro, rebaixado.
func _draw_cabinet(r: Rect2) -> void:
	draw_texture(_wood_frame(r.size), r.position)
	var lamp := get_viewport_rect().size.x / 2.0 - global_position.x
	var glint := func(x: float) -> Color:
		return Color(WOOD[0].lightened(0.45), 0.6 * clampf(1.0 - absf(x - lamp) / 700.0, 0.0, 1.0))
	var top := r.position.y + 1.0
	draw_primitive(PackedVector2Array([Vector2(r.position.x + 1, top), Vector2(r.end.x - 1, top), Vector2(r.end.x - 1, top + 1), Vector2(r.position.x + 1, top + 1)]),
		PackedColorArray([glint.call(r.position.x), glint.call(r.end.x), glint.call(r.end.x), glint.call(r.position.x)]), PackedVector2Array())
	var p := r.grow(-FRAME)
	draw_rect(p.grow(1), EDGE_DARK)
	draw_rect(p, Pal.PANEL)
	draw_rect(Rect2(p.position, Vector2(p.size.x, 2)), Pal.PANEL_LO)   # rebaixado: a sombra fica em cima à esquerda
	draw_rect(Rect2(p.position, Vector2(2, p.size.y)), Pal.PANEL_LO)
	draw_rect(Rect2(p.position.x, p.end.y - 1, p.size.x, 1), Pal.PANEL_HI)


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
			draw_primitive(quad, cols, PackedVector2Array())   # (primitivos seguidos são uma chamada de desenho só; polígonos, uma cada)


## A faixa de cada linha: um rebaixo estreito do painel que liga a plaquinha, a lâmpada, a entrada e a saída da mesma
## coluna (sem ela, a saída parecia solta). As faixas gravadas passam por baixo; o nome delas, por cima.
func _draw_strips() -> void:
	for i in 10:
		var r := Rect2(col_x(i) - STRIP_W / 2.0, ROW_Y["plate"] + 4.0, STRIP_W, ROW_Y["out"] + 11.0 - ROW_Y["plate"])
		draw_rect(r, Pal.PANEL.darkened(0.05))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(Pal.PANEL_LO, 0.6))   # rebaixada: a sombra em cima e à esquerda
		draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color(Pal.PANEL_LO, 0.6))
		draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), Color(Pal.PANEL_HI, 0.5))
		draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), Color(Pal.PANEL_HI, 0.5))


## O uso de anos: o painel gasto em volta das tomadas (claro liso, mais nas entradas, onde o FONE entra a noite toda,
## e nas primeiras linhas) e riscos finos onde a ponta do plug escorregou errando o furo. Sempre os mesmos.
func _draw_wear() -> void:
	for j in _jacks:
		var use := _use(j)
		PixelArt.sprite(self, PixelArt.disc(28, [[10.0, Color(Pal.PANEL_HI, WEAR[0])], [12.0, Color(Pal.PANEL_HI, WEAR[1])], [14.0, Color(Pal.PANEL_HI, WEAR[2])]]),
			jack_rect(j).get_center(), Color(1, 1, 1, use))
		var rng := RandomNumberGenerator.new()
		rng.seed = j
		for k in roundi(use * 2.0):
			var a := rng.randf() * TAU
			var from := jack_rect(j).get_center() + Vector2.from_angle(a) * rng.randf_range(9.0, 11.0)
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * rng.randf_range(3.0, 6.0)
			draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), Color(Pal.PANEL_HI, 0.45), 1.0)


## O quanto a tomada `j` é usada (0..1): as entradas mais, das primeiras linhas para as últimas; depois as saídas; os
## destinos, menos.
func _use(j: int) -> float:
	if j <= 10:
		return 1.0 - (j - 1) * 0.05
	if j <= 20:
		return 0.6 - (j - 11) * 0.03
	return 0.35


## A plaqueta de latão do fabricante, no pé do painel (ali ficava vazio), no vão entre os dois primeiros pares de
## buracos da prateleira, onde nenhum plug guardado fica na frente: o nome da central gravado (escuro, com o brilho
## embaixo) e um parafuso em cada ponta.
func _draw_maker_plate() -> void:
	var cx := roundf((hole(2).x + hole(3).x) / 2.0)
	var bottom := DEST_TOP - 21.0 + DEST_ROW + 50.0   # o pé dos bancos de destino
	var r := Rect2(cx - 48.0, roundf((bottom + SIZE.y - FRAME) / 2.0 - 13.0), 96.0, 26.0)
	var pal := HOLE_PAL
	draw_rect(Rect2(r.position + Vector2(1, 2), r.size), SHADOW)
	draw_rect(r.grow(1), EDGE_DARK)
	draw_rect(r, Color("b0904c"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), pal["F"])
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), pal["f"])
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), pal["b"])
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), pal["b"])
	draw_rect(r.grow(-3), pal["b"], false, 1.0)   # o friso gravado em volta
	for x in [r.position.x + 7.0, r.end.x - 7.0]:
		PixelArt.sprite(self, PixelArt.disc(5, [[1.5, pal["F"], pal["f"], pal["b"]], [2.5, pal["w"]]]), Vector2(x, r.get_center().y))
		draw_rect(Rect2(x - 1.0, r.get_center().y, 3, 1), pal["w"])   # a fenda
	var maker := PixelArt.tiny(T.text(T.Key.BOARD_MAKER))
	var at := Vector2(roundf(cx - maker.get_width() / 2.0), r.position.y + 2.0)
	draw_texture(maker, at + Vector2(0, 1), pal["F"])
	draw_texture(maker, at, pal["w"])
	var town := "SÃO SOTERO"
	var nw := Pal.mono.get_string_size(town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var np := Vector2(roundf(cx - nw / 2.0), r.end.y - 6.0)
	draw_string(Pal.mono, np + Vector2(0, 1), town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["F"])
	draw_string(Pal.mono, np, town, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pal["w"])


## A moldura de madeira do móvel, pixel a pixel e guardada: quatro trilhos com os cantos em meia-esquadria (uma
## emenda escura na diagonal), cada um com os veios ao longo dele, ondulando (os de cima e de baixo deitados, os dos
## lados em pé); a beira escura por fora, a luz em cima e à esquerda, a sombra embaixo e à direita, e as quinas gastas,
## mais claras, de anos de mãos.
static var _woods := {}


func _wood_frame(sz: Vector2) -> ImageTexture:
	if not _woods.has(sz):
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
				var c: Color = WOOD[1]
				if g < 0.55:
					c = WOOD[2].lightened(0.12)   # o veio escuro
				elif g > 1.6 and g < 1.9:
					c = WOOD[1].lightened(0.08)   # o claro entre os veios
				if ex == ey and ex < f:
					c = WOOD[2]   # a emenda do canto
				var corner := Vector2(mini(x, w - 1 - x), mini(y, h - 1 - y)).length()
				c = c.lerp(WOOD[0].lightened(0.15), 0.45 * clampf(1.0 - corner / 10.0, 0.0, 1.0))   # quina gasta
				if ex == 0 or ey == 0:
					c = EDGE_DARK
				elif (x == 1 or y == 1) and x < w - 2 and y < h - 2:
					c = WOOD[0]   # a luz em cima e à esquerda
				elif x == w - 2 or y == h - 2:
					c = WOOD[2]
				img.set_pixel(x, y, c)
		_woods[sz] = ImageTexture.create_from_image(img)
	return _woods[sz]


## Faixa gravada que separa as seções do painel, com o nome dela em cima, à esquerda (sem nome, só a faixa; sem
## `line`, só o nome).
## A legenda das lâmpadas, na faixa das entradas, alinhada à direita e logo acima das lâmpadas que ela explica, na
## fonte gravada do painel (`tiny`; em 11 não cabia ali). No pé do painel, os plugs guardados passavam na frente dela.
func _draw_legend() -> void:
	var leg := [[Pal.AMBER, T.Key.LEGEND_RING], [Pal.GREEN, T.Key.LEGEND_CONN], [Pal.RED, T.Key.LEGEND_DONE], [LAMP_OFF, T.Key.LEGEND_FREE]]
	var texts := []
	var width := -10.0
	for item in leg:
		var t := PixelArt.tiny(T.text(item[1]))
		texts.append(t)
		width += 9.0 + 4.0 + t.get_width() + 10.0
	var y := RULES["in"] + 1.0
	var x := floorf(size.x - FRAME - 18.0 - width)
	draw_rect(Rect2(x - 5, y - 8, width + 10, 15), Pal.PANEL)   # tampa a faixa, como o nome dela
	for k in leg.size():
		PixelArt.sprite(self, PixelArt.disc(9, [[3.0, Color.WHITE], [4.5, EDGE_DARK]]), Vector2(x + 4.5, y), leg[k][0])   # lâmpadas redondas, como as da mesa
		PixelArt.sprite(self, PixelArt.disc(9, [[3.0, Color.TRANSPARENT], [4.5, EDGE_DARK]]), Vector2(x + 4.5, y))
		draw_texture(texts[k], Vector2(x + 13.0, y - 5.0), Pal.DIM)
		x += 9.0 + 4.0 + (texts[k] as Texture2D).get_width() + 10.0


func _draw_rule(y: float, caption: String, line := true) -> void:
	if line:
		draw_rect(Rect2(FRAME + 6, y, size.x - FRAME * 2 - 12, 1), Pal.PANEL_LO)
		draw_rect(Rect2(FRAME + 6, y + 1, size.x - FRAME * 2 - 12, 1), Pal.PANEL_HI)
	if caption != "":
		var cw := Pal.ui.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_rect(Rect2(FRAME + 14, y - 7, cw + 8, 15), Pal.PANEL)
		draw_string(Pal.ui, Vector2(FRAME + 18, y + 5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.BRASS)


## A prateleira à frente do painel, onde os cabos de conexão ficam guardados de pé: os buracos de onde saem os fios
## (a cor de cada cabo já diz qual é; o nome gravado embaixo saiu, a pedido).
func _draw_tray(_r: Rect2) -> void:
	for k in PATCHES:
		for e in [1 + k * 2, 2 + k * 2]:
			draw_grommet(self, hole(e))


## Um nome gravado na madeira da prateleira, centrado em `at.x` com a base em `at.y`: o sulco escuro e o latão.
static func engrave(ci: CanvasItem, at: Vector2, text: String) -> void:
	var f: Font = Pal.mono if Pal.mono != null else ThemeDB.fallback_font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var p := Vector2(roundf(at.x - w / 2.0), at.y)
	ci.draw_string(f, p + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0, 0, 0, 0.6))
	ci.draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.BRASS)


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
	draw_rect(r.grow(1), EDGE_DARK)
	draw_rect(r, BEZEL[1])
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), BEZEL[0])
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), BEZEL[0].darkened(0.1))
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), BEZEL[2])
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), BEZEL[2].lightened(0.1))
	for x in [r.position.x + 2.0, r.end.x - 5.0]:   # rebites: um pixel claro no alto de um escuro
		var rv := Vector2(x, floorf(r.get_center().y - 1.5))
		draw_rect(Rect2(rv, Vector2(3, 3)), BEZEL[2])
		draw_rect(Rect2(rv, Vector2(1, 1)), BEZEL[0])


## Plaquinha de metal com o número da linha gravado (escuro, com o brilho embaixo de quem foi rebaixado), centrado
## pela medida da fonte.
func _draw_number_plate(r: Rect2, text: String) -> void:
	_draw_metal(r)
	var size := Pal.mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	var at := Vector2(roundf(r.get_center().x - size.x / 2.0), roundf(r.get_center().y + (Pal.mono.get_ascent(11) - Pal.mono.get_descent(11)) / 2.0))
	draw_string(Pal.mono, at + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BEZEL[0])   # o brilho do rebaixo
	draw_string(Pal.mono, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("1d1a14"))


## Chapa de metal parafusada sobre um banco que ainda não está em uso (lisa: o escovado saiu, a pedido): a letra do
## banco estampada em relevo (luz em cima à esquerda, sombra embaixo à direita), o aviso
## pintado com estêncil embaixo e, em volta dos parafusos, os riscos da chave de fenda que escorregou. Sempre os mesmos.
func _draw_plate(r: Rect2, letter: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(letter)
	draw_rect(r.grow(1), EDGE_DARK)
	draw_rect(r, PLATE)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), PLATE.lightened(0.18))
	draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), PLATE.darkened(0.35))
	for c in [r.position + Vector2(7, 7), Vector2(r.end.x - 7, r.position.y + 7), Vector2(r.position.x + 7, r.end.y - 7), r.end - Vector2(7, 7)]:
		for k in 2:   # a chave de fenda escorregou, sempre para dentro da chapa (para fora, o risco passava da borda)
			var a: float = (r.get_center() - c).angle() + rng.randf_range(-0.6, 0.6)
			var from: Vector2 = c + Vector2.from_angle(a) * 4.0
			var to := from + Vector2.from_angle(a + rng.randf_range(-0.3, 0.3)) * rng.randf_range(2.0, 5.0)
			draw_line(from.round() + Vector2(0.5, 0.5), to.round() + Vector2(0.5, 0.5), PLATE.lightened(0.3), 1.0)
		PixelArt.sprite(self, PixelArt.disc(7, [[2.5, PLATE.lightened(0.35), PLATE.lightened(0.15), PLATE.darkened(0.2)], [3.5, PLATE.darkened(0.5)]]), c)
		draw_rect(Rect2((c - Vector2(2, 1)).floor(), Vector2(3, 1)), PLATE.darkened(0.5))   # fenda do parafuso
	var at := Vector2(r.position.x, r.get_center().y + 8.0)   # a letra estampada
	draw_string(Pal.mono, at + Vector2(1, 1), letter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 33, PLATE.darkened(0.45))
	draw_string(Pal.mono, at - Vector2(0, 1), letter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 33, PLATE.lightened(0.35))
	draw_string(Pal.mono, at, letter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 33, PLATE.lightened(0.15))
	var notice := PixelArt.tiny(T.text(T.Key.BOARD_PLATE_NOTICE))   # pintado com estêncil, já gasto
	draw_texture(notice, Vector2(roundf(r.get_center().x - notice.get_width() / 2.0), r.get_center().y + 13.0), Color("c9b98f", 0.6))
