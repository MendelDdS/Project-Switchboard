class_name Bloom
extends Control
## Bloom das luzes, no estilo do glow de cinema e em pixel art: em volta de cada luz acesa, um halo somado à tela
## (`CanvasItemMaterial` ADD) em duas camadas (uma curta e forte colada na luz, outra longa e fraca), desenhado em
## blocos de `BLOCK` px com poucos degraus lisos (`DITHER` liga o pontilhado ordenado entre eles), como o resto do jogo; por cima, a própria luz nítida,
## com o centro "estourando" para um branco tingido pela cor dela (`_cores`, mistura normal; sem isso o halo passa por
## cima da luz como uma fumaça). Fica acima da mesa e dos painéis e abaixo dos menus.
## Só brilha o que se declara luz: pela cor não dá (o plug vermelho e a lâmpada vermelha têm o mesmo tom). Quem desenha
## luzes chama `Bloom.clear(self)` no começo do `_draw` e `Bloom.light(self, rect, cor)` para cada luz acesa
## (coordenadas do próprio nó); o que fica na frente das próprias luzes (um plug encaixado) entra com
## `Bloom.occlude(self, polígono)` e o halo não passa por cima dele. ColorRect e Label no grupo "bloom" brilham na cor deles (a do texto, no Label) quando
## acesos; a meta "bloom" (0..1) atenua o halo deles; o Label só ganha o halo.

const BLOCK := 1.0        # px do jogo por bloco do halo (1x1, como o resto)
const SPREAD := 18.0      # px do jogo que o halo passa da luz
const INNER := 0.6        # a camada curta, colada na luz...
const INNER_FALL := 7.0   # ...e quão depressa ela cai
const OUTER := 0.4        # a camada longa e fraca
const LEVELS := 6.0       # degraus de intensidade do halo
const DITHER := false     # pontilhado entre os degraus (com ele, pontos escuros salpicavam o halo em volta das lâmpadas)
const STRENGTH := 0.55    # quanto do halo soma onde ele é mais forte
const MIN_VALUE := 0.45   # cor mais escura que isto (canal mais forte) é luz apagada
const INTENSITY := 1.2    # a luz nítida: o canal mais forte vezes isto (o tom não muda)...
const HOT := 0.85         # ...e o centro dela indo para o branco (luz forte demais "estoura")
const HOLLOW := 0.2       # dentro de uma luz sem miolo (o aro da tomada), o halo é só isto
const GLASS_SHADE := 0.3  # a borda de baixo do vidro, mais escura
const HOT_TINT := 0.35    # quanto da cor da luz fica no branco do centro (âmbar → amarelo-claro, verde → menta)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]   # pontilhado ordenado 4×4

static var _lights := {}  # instance_id de quem desenha -> [[Rect2 nas coordenadas dele, Color, halo, core, round], ...]
static var _masks := {}   # instance_id de quem desenha -> [PackedVector2Array nas coordenadas dele]: o que fica na frente das luzes dele

var _cores := Control.new()   ## as luzes nítidas, por cima dos halos (sem o blend ADD)
var _shown: Array = []        ## [Rect2 aqui, Color, round] das luzes deste quadro, para `_cores`
var _halos := {}              ## "l×a×redonda" -> ImageTexture do halo (branco; a cor vem na hora de desenhar)
var _cuts := {}               ## hash(halo, lugar, máscaras) -> o halo sem o que fica na frente dele


## Esquece as luzes de `owner` (no começo do `_draw` dele).
static func clear(owner: CanvasItem) -> void:
	_lights.erase(owner.get_instance_id())
	_masks.erase(owner.get_instance_id())


## Algo de `owner` na frente das luzes dele (`shape` nas coordenadas dele; um plug encaixado): o halo delas não passa
## por cima.
static func occlude(owner: CanvasItem, shape: PackedVector2Array) -> void:
	var id := owner.get_instance_id()
	if not _masks.has(id):
		_masks[id] = []
	_masks[id].append(shape)


## Uma luz acesa de `owner`: `r` nas coordenadas dele, na cor `col` (o alpha também vale para a luz nítida);
## `halo` (0..1) atenua só o halo; `core` falso deixa só o halo (luz em forma de aro, que cobriria o que está dentro);
## `round`: a luz é o círculo inscrito em `r`.
static func light(owner: CanvasItem, r: Rect2, col: Color, halo := 1.0, core := true, round := false) -> void:
	var id := owner.get_instance_id()
	if not _lights.has(id):
		_lights[id] = []
	_lights[id].append([r, col, halo, core, round])


## As luzes que `owner` declarou no último desenho dele ([Rect2, Color, halo, core, round] nas coordenadas dele): a
## mesa as manda também ao shader do brilho no painel.
static func lights_of(owner: CanvasItem) -> Array:
	return _lights.get(owner.get_instance_id(), [])


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # os blocos do halo ficam retos
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add
	_cores.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cores.draw.connect(_draw_cores)
	add_child(_cores)


func _process(_delta: float) -> void:
	queue_redraw()   # as luzes se mexem e piscam com quem as desenha
	_cores.queue_redraw()


func _draw() -> void:
	_shown.clear()
	var to_me := get_global_transform_with_canvas().affine_inverse()
	for id in _lights.keys():
		var o := instance_from_id(id) as CanvasItem
		if o == null:
			_lights.erase(id)
		elif o.is_visible_in_tree():
			var xf := to_me * o.get_global_transform_with_canvas()
			var masks: Array = []
			for m in _masks.get(id, []):
				masks.append(xf * (m as PackedVector2Array))
			for l in _lights[id]:
				var r: Rect2 = l[0]
				if o is Control and (o as Control).clip_contents:   # quem recorta o que desenha recorta a luz também
					r = r.intersection(Rect2(Vector2.ZERO, (o as Control).size))
				if r.has_area():
					_glow(xf * r, l[1], l[2], l[3], l[4], masks)
	for n in get_tree().get_nodes_in_group("bloom"):
		var c: Control = n
		var col: Color = (c as ColorRect).color if c is ColorRect else c.get_theme_color("font_color")
		if c.is_visible_in_tree() and maxf(col.r, maxf(col.g, col.b)) >= MIN_VALUE:
			_glow(to_me * c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size), col,
				float(c.get_meta("bloom", 1.0)), c is ColorRect, false)


func _glow(r: Rect2, col: Color, halo: float, core: bool, round: bool, masks := []) -> void:
	var tex := _halo_for(r.size, round, not core)
	var at := ((r.position - Vector2(SPREAD, SPREAD)) / BLOCK).floor() * BLOCK   # na grade dos pixels do cenário
	var area := Rect2(at, Vector2(tex.get_size()) * BLOCK)
	var hit := masks.filter(func(m: PackedVector2Array) -> bool: return area.intersects(_bounds(m)))
	if not hit.is_empty():
		tex = _cut(tex, at, hit)
	draw_texture_rect(tex, Rect2(at, Vector2(tex.get_size()) * BLOCK), false,
		Color(col.r, col.g, col.b, STRENGTH * col.a * halo))
	if core:
		_shown.append([r, col, round])


## O halo `tex`, posto em `at`, sem os blocos cobertos por `masks` (guardado: o que cobre, como um plug encaixado,
## fica parado).
func _cut(tex: ImageTexture, at: Vector2, masks: Array) -> ImageTexture:
	var key := hash([tex.get_rid().get_id(), at, masks])
	if _cuts.has(key):
		return _cuts[key]
	if _cuts.size() > 128:
		_cuts.clear()
	var img := tex.get_image()
	for y in img.get_height():
		for x in img.get_width():
			var p := at + (Vector2(x, y) + Vector2(0.5, 0.5)) * BLOCK
			for m in masks:
				if Geometry2D.is_point_in_polygon(p, m):
					img.set_pixel(x, y, Color(1, 1, 1, 0))
					break
	var cut := ImageTexture.create_from_image(img)
	_cuts[key] = cut
	return cut


func _bounds(m: PackedVector2Array) -> Rect2:
	var b := Rect2(m[0], Vector2.ZERO)
	for p in m:
		b = b.expand(p)
	return b


## O halo de uma luz do tamanho `size` (guardado por tamanho): branco, em blocos, das duas camadas. `hollow`: fraco
## dentro da luz (ela não tem miolo para cobrir o halo, e o que está dentro dela não é luz).
func _halo_for(size: Vector2, round: bool, hollow: bool) -> ImageTexture:
	var key := "%d×%d×%s×%s" % [roundi(size.x), roundi(size.y), round, hollow]
	if _halos.has(key):
		return _halos[key]
	if _halos.size() > 128:   # a barra de agravamento muda de largura: não guarda todas
		_halos.clear()
	var cells := Vector2i(ceili((size.x + 2.0 * SPREAD) / BLOCK), ceili((size.y + 2.0 * SPREAD) / BLOCK))
	var img := Image.create(cells.x, cells.y, false, Image.FORMAT_LA8)
	var inside := Rect2(Vector2(SPREAD, SPREAD), size)
	var radius := minf(size.x, size.y) / 2.0
	for y in cells.y:
		for x in cells.x:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) * BLOCK
			var d: float   # px fora da luz
			if round:
				d = maxf(0.0, p.distance_to(inside.get_center()) - radius)
			else:
				d = Vector2(maxf(maxf(inside.position.x - p.x, p.x - inside.end.x), 0.0),
					maxf(maxf(inside.position.y - p.y, p.y - inside.end.y), 0.0)).length()
			var k := d / SPREAD
			var v := INNER * exp(-k * INNER_FALL) + (OUTER * (1.0 - k) * (1.0 - k) if k < 1.0 else 0.0)
			if hollow and d == 0.0:
				v *= HOLLOW
			# abaixo de meio degrau, nada: pontos soltos no fim do halo pareciam ruído
			var step := 0.0 if v * LEVELS < 0.5 else floorf(v * LEVELS + (BAYER[(y % 4) * 4 + x % 4] / 16.0 if DITHER else 0.5)) / LEVELS
			img.set_pixel(x, y, Color(1, 1, 1, clampf(step, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	_halos[key] = tex
	return tex


## A luz nítida e intensa: a cor dela (mais forte) nas bordas e, em degraus, o centro indo para um branco tingido por
## ela. O vidro: a borda de baixo um pouco mais escura (a tampa é curva) e, nas redondas, o reflexo no alto, à esquerda.
func _draw_cores() -> void:
	for l in _shown:
		var r: Rect2 = l[0]
		var col: Color = l[1]
		var top := maxf(col.r, maxf(col.g, col.b))
		var k := minf(1.0, top * INTENSITY) / maxf(top, 0.001)
		var base := Color(col.r * k, col.g * k, col.b * k, col.a)
		var hot := Color.WHITE.lerp(Color(col.r / top, col.g / top, col.b / top), HOT_TINT)
		if l[2]:   # redonda, em pixel art como as lâmpadas da mesa: a sombra do vidro embaixo à direita
			var d := maxi(2, roundi(minf(r.size.x, r.size.y)))
			var o := Color(base, 1.0)
			_cores.draw_texture_rect(PixelArt.disc(d, [[d * 0.18, o.lerp(hot, HOT)], [d * 0.33, o.lerp(hot, HOT * 0.55)],
				[d / 2.0, o, o, o.darkened(GLASS_SHADE)]]), Rect2((r.get_center() - Vector2(d, d) / 2.0).floor(), Vector2(d, d)), false, Color(1, 1, 1, col.a))
		else:
			_cores.draw_rect(r, base)
			if r.size.y >= 4.0:
				_cores.draw_rect(Rect2(r.position.x, r.end.y - 1.0, r.size.x, 1.0), Color(base.darkened(GLASS_SHADE), base.a))
			var m := minf(r.size.x, r.size.y)
			for ring in [[0.22, 0.55], [0.38, 1.0]]:   # degraus para dentro: [quanto encolhe, força]
				var inner := r.grow(-m * float(ring[0]))
				if inner.has_area():
					_cores.draw_rect(inner, Color(hot, HOT * float(ring[1]) * col.a))
