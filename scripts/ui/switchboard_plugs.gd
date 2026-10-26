extends "res://scripts/ui/switchboard_panel.gd"
## Os plugs e os fios da mesa comutadora (`Switchboard`): o plug em pé e o encaixado (de frente, com paralaxe), a
## luz e a sombra deles e o fio de pano pela corda (`_draw_rope`, `_kinked`, `_smooth`).

const Cord := preload("res://scripts/ui/cord.gd")   ## a física de cada fio
## [cor, brilho] de cada cabo: 0 = FONE (verde), 1..patches = cabos de conexão (vermelho, azul, amarelo, branco, preto).
## Mais cabos de conexão pedem mais cores aqui.
const HOLE_LIP := 2.0    # ...e some abaixo disto (px abaixo do buraco), atrás da beira da frente dele
const HOLE_SHADE := [[0.0, 4.0, 0.65], [4.0, 8.0, 0.4], [8.0, 12.0, 0.2]]   # o fio entrando no buraco escurece: [de, até (px a partir do buraco), escuro]

var _pushed := {}   ## ponta -> segundos desde que encaixou (a assentada, `PUSH_SEC`, e a passagem para de frente)
var _knocked := {}   ## ponta encaixada -> [segundos desde que um fio caiu nela, px que afunda] (`KNOCK_PX`)
var _pushed_ang := {}   ## ponta -> o ângulo do plug na mão quando encaixou (a passagem para de frente gira dali)
var _silhouette := {}   ## inclinação do plug encaixado (em pé: false) -> polígono do contorno (destaque e sombra)
var cursor := Vector2.ZERO
var _hover := -1               # ponta cujo plug está sob o mouse (pode ser pega); desenhada com destaque
var _cut := INF   # desenhando o plug em pé: abaixo disto (y dele) está dentro do buraco da prateleira
var _loose := {}               # ponta solta voltando para o buraco -> {"t": s caindo/recolhendo, "seat": -1 ou s assentando, "direct", "ang", e, assentando, "from", "turn", "v0", "sink", "hit"}

const SEAT_ACCEL := 2250.0
const SEAT_BOB := 1.5
const SEAT_BOB_SEC := 0.08
const PLUG_LEN := 33.0   # em pé: do fio até o alto da aba (a ponta de metal passa disso)
## Encaixado, de onde fica a tomada até onde o fio entra: a ponta de metal some dentro dela e o anel assenta no buraco.
const PLUG_FACE_R := 4.5   # encaixado: o raio do corpo (10 px com a beira, como o em pé: cobre o furo da tomada e quase todo o aro)
const EDGE := 0.65          # a beira do plug e do fio: a cor da peça escurecida assim (contorno preto destoava do cenário)
## Encaixado, o plug sai do painel na direção da câmera, a mesma do cenário: a ponta dele se afasta do ponto de fuga
## da sala (os olhos do operador, `eye`), mais quanto mais longe dele (paralaxe, `_tilt`). Os olhos ficam à direita da
## mesa, na altura das plaquinhas das entradas: os plugs das entradas saem quase só para a esquerda, os de baixo
## também para baixo. (Era um ponto fixo 600 px acima do painel: todos pareciam vistos de cima, contra a sala.)
const PLUG_DEPTH := 0.014   # px de deslocamento da ponta por px de distância do encaixe até os olhos (estilizado: a conta daria ~0,04, de lado demais; menor com o plug mais curto)
const PLUG_SHADE := Vector2(-4, 5)   # encaixado, a sombra vai do encaixe até aqui (luz no alto à direita, `LIGHT`)
const PLUG_ART := [   ## o plug em pé, de 12 × 51 px (y de -51 a -1; o fio sai de y = 0): `_plug_pal` dá as cores
	".....bE.....",
	"....yYbE....",
	"....bBCE....",
	".....bC.....",
	"...KKKkkk...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...KKKkkk...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"...yYbbBE...",
	"..YYYyybBE..",
	"..bybbBCCE..",
	"..bybbBCCE..",
	"..32334556..",
	".2122233456.",
	".4344455556.",
	".2122233456.",
	".2232343456.",
	".2232343456.",
	".2232343456.",
	".2232343456.",
	".2232343456.",
	".2232343456.",
	".2232343456.",
	".2122233456.",
	".4344455556.",
	".1111222346.",
	".2122233456.",
	".2122233456.",
	".2122233456.",
	".2122233456.",
	".2122233456.",
	"..32334556..",
	"..32334556..",
	"..54555556..",
	"...323456...",
	"...323456...",
	"...545556...",
	"...323456...",
	"....3456....",
	"....5556....",
	"....3456....",
	"....3456....",
]
const PLUG_CAPA_ROW := 40   # a linha do `PLUG_ART` onde começa a capa de borracha (os gomos, até o fio)
const PLUG_ABA_D := 8   # a aba dourada, com a beira (a largura dela no `PLUG_ART`): a sombra de contato do encaixado
## A luz da lâmpada ou do aro aceso no plug encaixado, pixel a pixel a partir da beira virada para ela (`_face_rim`):
## cheia na beira e sumindo para dentro em degraus. Com a beira acesa e o resto apagado, a luz tomava o plug de uma vez.
const RIM_FALL := [0.75, 0.4, 0.16]
const MORPH_SEC := 0.08   # encaixando ou saindo, o plug passa de em pé para de frente (e volta) nesse tempo
const PUSH_PX := 1.0     # ao encaixar, o plug afunda (o tampo encolhe tanto, px) e volta...
const ROT_STEP := deg_to_rad(5.0)   # solto ou na mão, o plug gira em passos assim, cada um montado pixel a pixel (`PixelArt.turned`)
const PUSH_SEC := 0.14   # ...nesse tempo, como se fosse empurrado para dentro
const KNOCK_PX := Vector2(0.5, 1.0)   # um fio caindo nele também o afunda (px, da batida fraca à forte: a fraca some no arredondamento)...
const KNOCK_SEC := 0.1   # ...e ele volta nesse tempo
const LAMP_ABOVE := 90.0   # px acima da tela: a luminária do teto, que não aparece
const CORD_LIT := 0.6   # o fio e os plugs em pé pegam essa parte da luz da sala do painel (estão na frente dele)
const TAIL_IN := 5.0   # px do fio que entram na traseira do plug em pé (`_draw_tail`)
const ROPE_W := 5.0   # px: a largura do fio com a beira (o miolo tem 2 a menos; esticado, os dois afinam 1). Era 7 em 1280 × 720.
const AIR_LIFT := Vector2(-6, 8)   # a sombra do fio no ar, depois da beira da prateleira: longe do console, como a do plug na mão
const SMOOTH_PX := 3.0   # px: o fio é desenhado em trechos retos deste tamanho, numa curva pelos pontos da corda (`_smooth`)
const KINK := 1.0   # px: as dobras que o fio de pano guarda, no máximo
const KINK_PULLED := 0.4   # esticado pelo contrapeso, o pano alisa: as dobras ficam nessa parte (inteiras, num fio reto viravam degraus)
const BRAID := 5.0   # px: o trançado do fio (o brilho dele vem em pedaços desse comprimento)
## Esticado (`Cord.taut`), o fio de pano alisa: as dobras somem aos poucos até o fim do fio, o trançado se espaça até
## TAUT_BRAID e, da metade disso em diante, ele afina 1 px; frouxo, volta com as dobras inteiras.
const TAUT_BRAID := 1.3
const CROSS_SHADE := Vector2(-1, 2)   # a sombra do fio sobre o fio de baixo, onde se cruzam (mais perto que a do painel)
const ROPE_SHADOW := Vector2(-2, 3)  # deslocamento da sombra dos fios junto ao buraco; até o plug, cresce como a dele (`_lift`)

var ropes := {}                    # ponta -> Cord (só enquanto o fio está para fora do buraco)
var _swing := 0.0                 # rad: o balanço do plug na mão (`SWING_*`)


## Onde o fio entra no plug.
func _plug_base(e: int) -> Vector2:
	if held == e:
		return cursor + PLUG_BASE.rotated(_swing)   # balança em volta de onde a mão pega
	if ends[e] != -1:
		return jack_rect(int(ends[e])).get_center() + _tilt(int(ends[e]))   # encaixado: o fio sai da ponteira
	if _loose.has(e):
		if _loose[e]["seat"] >= 0.0:
			return _seat_pose(e)[0]
		return (ropes[e] as Cord).tip()
	return _rest(e)


## Quanto o plug encaixado está afundado (px): a assentada, recém-encaixado, e a batida de um fio caindo nele.
func _push(e: int) -> float:
	var px := PUSH_PX * sin(PI * minf(float(_pushed[e]) / PUSH_SEC, 1.0)) if _pushed.has(e) else 0.0
	if _knocked.has(e):
		px += float(_knocked[e][1]) * sin(PI * minf(float(_knocked[e][0]) / KNOCK_SEC, 1.0))
	return px


## Onde o fio entra no plug guardado (assentado: `hole(e) + (0, PLUG_SINK)`, o fim de `_seat_pose`).
func _rest(e: int) -> Vector2:
	return home_pos(e) + PLUG_BASE


## Inclinação do plug: em pé, menos quando solto (segue o fio, que sai da traseira dele).
func _plug_angle(e: int) -> float:
	if held == e:
		return snappedf(_swing, ROT_STEP)
	if not _loose.has(e):
		return 0.0
	var an: Dictionary = _loose[e]
	return snappedf(_seat_pose(e)[1] if an["seat"] >= 0.0 else float(an["ang"]), ROT_STEP)


## O plug assentando (`_loose[e]["seat"]` >= 0): [onde o fio entra nele, ângulo, quanto já afundou (0..1)].
func _seat_pose(e: int) -> Array:
	var an: Dictionary = _loose[e]
	var t: float = an["seat"]
	var turn: float = an["turn"]
	if t < turn:   # girando em pé, com a traseira indo para a boca do buraco
		var k := smoothstep(0.0, 1.0, t / turn)
		return [(an["from"] as Vector2).lerp(hole(e), k), lerp_angle(an["ang"], 0.0, k), 0.0]
	t -= turn
	var v0: float = an["v0"]
	var sink := minf(v0 * t + 0.5 * SEAT_ACCEL * t * t, PLUG_SINK)
	var after: float = t - float(an["sink"])
	if after > 0.0:   # bateu no fundo: quica
		sink -= SEAT_BOB * sin(PI * minf(after / SEAT_BOB_SEC, 1.0))
	return [hole(e) + Vector2(0, sink), 0.0, sink / PLUG_SINK]


## Quanto o ponto `q` do fio está apoiado num plug encaixado (`Cord.pegs`), de 0 a 1: encostado, o fio está na altura
## da ponta dele, afastado do painel, e a sombra cai tão longe quanto a do plug (`PLUG_SHADE`); a dois trechos dele,
## volta a encostar no painel (com a sombra de sempre, parecia que o fio estava colado no painel por cima do plug).
static func _on_peg(q: Vector2, pegs: PackedVector3Array) -> float:
	var k := 0.0
	for g in pegs:
		var off := q.distance_to(Vector2(g.x, g.y)) - g.z
		k = maxf(k, clampf(1.0 - off / (Cord.SEG * 2.0), 0.0, 1.0))
	return k


## [cor, brilho] do cabo da ponta e.
func _cable_col(e: int) -> Array:
	return CORD_COLORS[cable_of(e)]


func _draw_rope(e: int, shadow: bool) -> void:
	if not ropes.has(e):
		return
	var r: Cord = ropes[e]
	var pts := r.pts
	var taut := r.taut
	var thin := 1.0 if taut > 0.5 else 0.0   # esticado, o fio afina 1 px
	if taut > 0.0 and not r.hang:
		# e fica reto: a física deixa uma barriga (a gravidade puxa o meio a cada passo e a corda não a desfaz a
		# tempo), então o desenho vai para a reta do buraco à ponta; pendurado na quina, ele já é reto em dois trechos
		pts = pts.duplicate()
		var n := pts.size() - 1
		var line := r.route(pts[0], pts[n])   # reto, ou pela quina da prateleira
		var total := Cord.length_of(line)
		for i in range(1, n):
			pts[i] = pts[i].lerp(Cord.point_at(line, total * i / n), smoothstep(0.0, 1.0, taut))
		Cord.clear(pts, r.pegs, n)   # reto, passaria por dentro dos plugs encaixados no caminho: dobra neles
	if shadow:
		var sh := PackedVector2Array()   # o fio desce do plug até o buraco: a sombra vai da do plug até a de rente ao painel
		var lift := _lift(e)
		for i in pts.size():
			var k := float(i) / (pts.size() - 1)
			if r.air >= 1:   # no ar, na frente do console: a sombra se afasta logo depois da beira e cai nele
				sh.append(pts[i] + (ROPE_SHADOW if i < r.air else AIR_LIFT))
				continue
			sh.append(pts[i] + ROPE_SHADOW.lerp(lift, k * k).lerp(PLUG_SHADE, _on_peg(pts[i], r.pegs)))
		_ci.draw_polyline(_smooth(sh), SHADOW, ROPE_W - 1.0 - thin)
		return
	var col: Array = _cable_col(e)
	pts = _smooth(_kinked(e, pts, (1.0 - taut) * KINK_PULLED))
	var lights := PackedColorArray()   # a luz da sala ao longo do fio
	for q in pts:
		lights.append(_lit_by(q))
	var braid := BRAID * lerpf(1.0, TAUT_BRAID, taut)   # o pano esticado espaça o trançado
	var laid := [Geometry2D.offset_polyline(pts, (ROPE_W - thin) / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND),
		PixelArt.bounds(pts).grow((ROPE_W - thin) / 2.0)]
	_cross_shade(laid, r.pegs)
	_laid[e] = laid
	if r.asleep():   # parado, pixel a pixel numa imagem guardada (traçado, a beira engrossava e afinava pela curva)
		var key := [pts, lights, col, thin, braid]
		if not _rope_arts.has(key):
			if _rope_arts.size() > 40:
				_rope_arts.clear()
			_rope_arts[key] = _rope_image(pts, lights, col, thin, braid)
		_ci.draw_texture(_rope_arts[key][1], _rope_arts[key][0])
	else:
		_draw_rope_line(pts, lights, col, thin, braid)
	if ends[e] == -1:   # em pé (na mão, solto ou guardado): o fio entra na traseira do plug
		_draw_tail(e, pts[pts.size() - 1], col[0], lights[lights.size() - 1], thin)


## A sombra do fio `laid` ([polígonos, caixa]) nos fios já desenhados (`_laid`): o fio deslocado de `CROSS_SHADE`
## cortado em cada um deles (o fio, desenhado depois, cobre o resto), menos o que os desenhados depois deste cobrem
## (dois sobrepostos escureciam duas vezes) e os plugs encaixados (`pegs`: a ponteira deles fica por cima). Em
## polígonos (`Geometry2D`): pixel a pixel, eram ~4 ms por quadro com fios lado a lado.
func _cross_shade(laid: Array, pegs: PackedVector3Array) -> void:
	if _laid.is_empty():
		return
	var box: Rect2 = laid[1]
	box.position += CROSS_SHADE
	var band: Array[PackedVector2Array] = []
	for q: PackedVector2Array in laid[0]:
		band.append(Transform2D(0.0, CROSS_SHADE) * q)
	var cover: Array = []   # [polígonos, caixa] dos já vistos, de cima para baixo
	for g in pegs:
		var r := Rect2(g.x - g.z, g.y - g.z, g.z * 2.0, g.z * 2.0)
		if r.intersects(box):
			var disc := PackedVector2Array()
			for k in 16:
				disc.append(Vector2(g.x, g.y) + Vector2.from_angle(TAU * k / 16.0) * g.z)
			cover.append([[disc], r])
	var keys := _laid.keys()
	keys.reverse()
	for f in keys:
		var under: Array = _laid[f]
		if not box.intersects(under[1]):
			continue
		var parts: Array[PackedVector2Array] = []
		for s: PackedVector2Array in band:
			for u: PackedVector2Array in under[0]:
				parts.append_array(Geometry2D.intersect_polygons(s, u))
		for c: Array in cover:
			if not under[1].intersects(c[1]):
				continue
			for o: PackedVector2Array in c[0]:
				var left: Array[PackedVector2Array] = []
				for q in parts:
					left.append_array(Geometry2D.clip_polygons(q, o))
				parts = left
		for q in parts:
			if Geometry2D.is_polygon_clockwise(q):
				continue   # ponytail: um buraco no recorte (um fio inteiro dentro da sombra) sai escuro; só um toco faria isso
			var tri := Geometry2D.triangulate_polygon(q)
			for i in range(0, tri.size(), 3):
				_ci.draw_primitive(PackedVector2Array([q[tri[i]], q[tri[i + 1]], q[tri[i + 2]]]), PackedColorArray([SHADOW]), PackedVector2Array())
		cover.append(under)


## O fio se mexendo, traçado pela placa de vídeo: a beira e o miolo e, por cima, o trançado e a sombra do buraco.
func _draw_rope_line(pts: PackedVector2Array, lights: PackedColorArray, col: Array, thin: float, braid: float) -> void:
	_ci.draw_polyline_colors(pts, _tinted((col[0] as Color).darkened(EDGE), lights), ROPE_W - thin)
	_ci.draw_polyline_colors(pts, _tinted(col[0], lights), ROPE_W - 2.0 - thin)
	var pts2 := PackedVector2Array()   # o brilho, 1 px para o lado do fio virado para a luz (`LIGHT`, alto à direita)
	var length := 0.0
	for i in pts.size():
		var side := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).orthogonal().normalized()
		pts2.append(pts[i] + (side if side.dot(LIGHT) > 0.0 else -side).round())
		if i > 0:
			length += pts[i].distance_to(pts[i - 1])
	var at := 0.0
	var segs := PackedVector2Array()   # o trançado inteiro numa chamada de desenho só (um traço por pedaço eram dezenas)
	var tones := PackedColorArray()
	while at < length:   # o trançado do pano: o brilho em pedaços
		var part := Cord.along(pts2, at, minf(at + braid - 2.0, length))
		var tone := (col[1] as Color) * _lit_by(part[0]) if part.size() >= 2 else Color()
		for i in part.size() - 1:
			segs.append_array([part[i], part[i + 1]])
			tones.append(tone)
		at += braid
	if not segs.is_empty():
		_ci.draw_multiline_colors(segs, tones, 1.0)
	for band in HOLE_SHADE:   # perto do buraco, a sombra de dentro dele, em degraus
		var part := Cord.along(pts, band[0], band[1])
		if part.size() >= 2:
			_ci.draw_polyline(part, Color(0, 0, 0, band[2]), ROPE_W - 2.0 - thin)


## Os fios parados já montados: [pontos, luzes, cabo, afinado, trançado] -> [canto, textura] (`_rope_image`).
static var _rope_arts := {}
var _laid := {}   ## ponta -> [polígonos, caixa] do fio já desenhado neste desenho (o de cima faz sombra nele, `_cross_shade`)


## A imagem do fio parado pelos pontos `pts` (px da mesa), cada pixel pelo trecho mais perto dele: a distância à linha
## do meio dá a beira e o miolo (a mesma largura em toda a curva), o lado dá o brilho do trançado (1 px para a luz,
## em pedaços de `braid`) e o comprimento até ali, a sombra de dentro do buraco (`HOLE_SHADE`). As mesmas cores do fio
## traçado (`_draw_rope_line`). Só em volta de cada trecho: a conta é pequena.
func _rope_image(pts: PackedVector2Array, lights: PackedColorArray, col: Array, thin: float, braid: float) -> Array:
	var edge := (ROPE_W - thin) / 2.0
	var core := edge - 1.0
	var r := PixelArt.bounds(pts).grow(edge + 1.0)
	r = Rect2(r.position.floor(), (r.end.ceil() - r.position.floor()))
	var w := int(r.size.x)
	var best := PackedFloat32Array()
	best.resize(w * int(r.size.y))
	best.fill(edge)
	var img := Image.create(w, int(r.size.y), false, Image.FORMAT_RGBA8)
	var at := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		var n := (b - a).orthogonal().normalized()
		if n.dot(LIGHT) < 0.0:
			n = -n
		var box := Rect2(a, Vector2.ZERO).expand(b).grow(edge + 1.0)
		for y in range(maxi(0, floori(box.position.y - r.position.y)), mini(int(r.size.y), ceili(box.end.y - r.position.y))):
			for x in range(maxi(0, floori(box.position.x - r.position.x)), mini(w, ceili(box.end.x - r.position.x))):
				var c := r.position + Vector2(x + 0.5, y + 0.5)
				var q := Geometry2D.get_closest_point_to_segment(c, a, b)
				var d := c.distance_to(q)
				if d >= best[y * w + x]:
					continue
				best[y * w + x] = d
				var t := q.distance_to(a) / maxf(seg, 0.001)
				var tone: Color = (col[0] as Color).darkened(EDGE) if d >= core else col[0]
				var side := (c - q).dot(n)
				if d < core and side >= 0.5 and fposmod(at + t * seg, braid) < braid - 2.0:   # o trançado, do lado da luz
					tone = col[1]
				var light := lights[i].lerp(lights[i + 1], t)
				for band in HOLE_SHADE:   # perto do buraco, a sombra de dentro dele
					if d < core and at + t * seg >= band[0] and at + t * seg < band[1]:
						tone = tone.lerp(Color.BLACK, band[2])
				img.set_pixel(x, y, Color(tone * light, 1.0))
		at += seg
	return [r.position, ImageTexture.create_from_image(img)]


## O fio entrando na traseira do plug em pé, em `at`: um trecho dele segue TAIL_IN px para dentro do plug, no eixo
## dele (o plug, desenhado depois, o cobre), e uma junta redonda fecha a dobra. Sem isso, o fio chegando de lado
## terminava num corte reto no meio da ponta do plug e deixava um vão do outro lado.
func _draw_tail(e: int, at: Vector2, c: Color, light: Color, thin: float) -> void:
	var inside := at + Vector2.UP.rotated(_plug_angle(e)) * TAIL_IN
	_ci.draw_line(at, inside, c.darkened(EDGE) * light, ROPE_W - thin)
	_ci.draw_line(at, inside, c * light, ROPE_W - 2.0 - thin)
	var w := int(ROPE_W - thin)
	PixelArt.sprite(_ci, _disc(w, [[(w - 2) / 2.0, c], [w / 2.0, c.darkened(EDGE)]]), at, light)


## A linha `pts` alisada numa curva (Catmull-Rom) que passa pelos mesmos pontos, em trechos de até SMOOTH_PX: com
## os pontos da corda ficam a `Cord.SEG` px um do outro e, ligados por retas, o fio virava uma linha quebrada.
func _smooth(pts: PackedVector2Array) -> PackedVector2Array:
	var n := pts.size()
	var out := PackedVector2Array()
	for i in n - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, n - 1)]
		var parts := maxi(1, ceili(p1.distance_to(p2) / SMOOTH_PX))
		for k in parts:
			var t := float(k) / parts
			out.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	out.append(pts[n - 1])
	return out


## A cor `c` sob cada luz de `lights`.
func _tinted(c: Color, lights: PackedColorArray) -> PackedColorArray:
	var out := PackedColorArray()
	for l in lights:
		out.append(c * l)
	return out


## As dobras que um fio de pano velho guarda: cada ponto da corda sai um pouco para um lado, sempre o mesmo para cada
## ponto (a dobra anda com o fio), menos perto das pontas. Só no desenho: a física continua com a corda lisa.
## Com o fio quase todo dentro do buraco, os pontos ficam colados e a dobra encolhe com eles (do tamanho de sempre,
## ela passava do trecho e o fio virava um rabisco na boca do buraco). `amount` (0..1) é quanto delas o fio guarda:
## esticado, o pano alisa.
func _kinked(e: int, pts: PackedVector2Array, amount := 1.0) -> PackedVector2Array:
	var out := pts.duplicate()
	var n := pts.size()
	for i in range(1, n - 1):
		var side := fposmod(sin(i * 12.9898 + e * 78.233) * 43758.5453, 1.0) * 2.0 - 1.0
		var d := pts[i + 1] - pts[i - 1]
		var room := clampf(d.length() / (KINK * 4.0), 0.0, 1.0)
		out[i] += d.normalized().orthogonal() * KINK * side * sin(PI * i / (n - 1)) * room * amount
	return out


## Plug em pé, a partir de onde o fio entra nele: corpo na cor do cabo, anel de latão e ponta de metal (com o
## risco que separa ponta e anel, como num plug de mesa telefônica). Encaixado, a ponta está dentro da tomada.
## Girado quando solto. A sombra é o contorno, mais longe quanto mais o plug sai do painel (na mão, mais).
func _draw_plug(e: int, shadow: bool) -> void:
	var seated: bool = ends[e] != -1
	var tilt := _tilt(int(ends[e])) if seated else Vector2.ZERO
	var at := _plug_base(e) - tilt   # encaixado, desenha a partir do encaixe
	if shadow and not seated:
		at += _lift(e)
	_ci.draw_set_transform(at.round(), _plug_angle(e))
	_cut = hole(e).y + HOLE_LIP - at.round().y if _in_hole(e) else INF
	if shadow and seated:   # do encaixe até onde a luz joga a ponta, no painel
		_ci.draw_colored_polygon(Geometry2D.convex_hull(_circle(Vector2.ZERO, PLUG_FACE_R + 1.0) + _circle(PLUG_SHADE, PLUG_FACE_R)), SHADOW)
		PixelArt.sprite(_ci, _disc(PLUG_ABA_D + 2, [[PLUG_ABA_D / 2.0 + 1.0, Color.WHITE]]), Vector2.ZERO, SHADOW)   # sombra de contato: a aba presa no encaixe
	elif shadow:
		_draw_cut(_plug_outline(e, 0.0), SHADOW)
	else:
		if e == _hover:   # contorno claro, na forma do plug: dá para pegar
			_draw_cut(_plug_outline(e, 2.0), Pal.GLOW)
		if seated:
			var k := minf(float(_pushed.get(e, MORPH_SEC)) / MORPH_SEC, 1.0)
			if k < 1.0:   # acabou de encaixar: a vista de frente cresce enquanto o corpo em pé entra no encaixe
				_ci.draw_set_transform(at.round(), 0.0, Vector2.ONE * lerpf(0.4, 1.0, k))
			_draw_plug_face(_cable_col(e), tilt, _push(e), 1.0, int(ends[e]), _lit_by(at))
			if k < 1.0:   # o corpo em pé gira para o eixo do encaixado e encurta até o tamanho dele, entrando no encaixe
				var axis := Transform2D(lerp_angle(float(_pushed_ang.get(e, 0.0)), tilt.angle() - PI / 2.0, k), Vector2(1.0, lerpf(1.0, tilt.length() / PLUG_LEN, k)), 0.0, at.round())
				_ci.draw_set_transform_matrix(axis * Transform2D(0.0, Vector2(0, PLUG_LEN)))
				_draw_plug_body(_cable_col(e), false, _lit_by(at))
		elif _plug_angle(e) != 0.0:   # girado pixel a pixel, preso aos pixels (girado pelo desenho, serrilhava)
			var ang := _plug_angle(e)
			var t := PixelArt.turned(_plug_art(ang), ang, Vector2(PLUG_W / 2.0, PLUG_H))
			_ci.draw_set_transform(at.round())
			_ci.draw_texture(PixelArt.art(t[0], _plug_pal(_cable_col(e))), -(t[1] as Vector2), _lit_by(at))
		else:
			_draw_plug_body(_cable_col(e), true, _lit_by(at))
	_ci.draw_set_transform(Vector2.ZERO)
	_cut = INF


## O plug em pé está entrando no buraco dele (guardado ou assentando): a parte de baixo some no buraco.
func _in_hole(e: int) -> bool:
	if ends[e] != -1 or held == e:
		return false
	if not _loose.has(e):
		return true
	var an: Dictionary = _loose[e]
	return an["seat"] >= 0.0 and an["seat"] >= an["turn"]   # já em pé, afundando (girando, o corte sairia torto)


## Desenha o polígono `shape` do plug em pé só até `_cut` (sombra e destaque).
func _draw_cut(shape: PackedVector2Array, col: Color) -> void:
	if _cut < INF:
		var cut := Geometry2D.intersect_polygons(shape, PackedVector2Array([Vector2(-30, -70), Vector2(30, -70), Vector2(30, _cut), Vector2(-30, _cut)]))
		shape = cut[0] if not cut.is_empty() else PackedVector2Array()
	if shape.size() >= 3:
		_ci.draw_colored_polygon(shape, col)


## Desenha `r` no plug em pé só até `_cut` (o resto está dentro do buraco da prateleira).
func _pr(r: Rect2, col: Color) -> void:
	r.size.y = minf(r.end.y, _cut) - r.position.y
	if r.size.y > 0.0:
		_ci.draw_rect(r, col)


## Quanto a sombra se desloca de onde o fio entra no plug: mais quanto mais o plug sai do painel (na mão, mais).
## Encaixado, a sombra da ponteira fica no fim da do plug (`PLUG_SHADE`, contada do encaixe).
func _lift(e: int) -> Vector2:
	if ends[e] != -1:
		return PLUG_SHADE - _tilt(int(ends[e]))
	if _loose.has(e) and _loose[e]["seat"] >= 0.0:   # afundando, a sombra cola na prateleira
		return Vector2(-3, 4).lerp(Vector2(-2, 2), _seat_pose(e)[2])
	return Vector2(-6, 8) if held == e else Vector2(-3, 4) if _loose.has(e) else Vector2(-2, 2)


## A silhueta do plug num polígono só (a sombra não escurece duas vezes onde as partes se sobrepõem), alargada `grow`
## px para o destaque: em pé, a do `PLUG_ART`, em degraus (um a cada linha em que a largura muda).
func _plug_outline(e: int, grow: float) -> PackedVector2Array:
	var seated: bool = ends[e] != -1
	var key: Variant = _tilt(int(ends[e])) if seated else false
	if not _silhouette.has(key):
		if seated:
			_silhouette[key] = Geometry2D.convex_hull(_circle(Vector2.ZERO, PLUG_FACE_R + 1.0) + _circle(key, PLUG_FACE_R + 1.0))
		else:
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			var was := Vector2.INF
			for i in PLUG_ART.size():
				var row: String = PLUG_ART[i]
				var span := Vector2(row.length() - row.lstrip(".").length(), row.rstrip(".").length()) - Vector2.ONE * PLUG_W / 2.0
				if span != was:
					if was != Vector2.INF:
						left.append(Vector2(was.x, i - PLUG_H))
						right.append(Vector2(was.y, i - PLUG_H))
					left.append(Vector2(span.x, i - PLUG_H))
					right.append(Vector2(span.y, i - PLUG_H))
					was = span
			left.append(Vector2(was.x, 0))
			right.append(Vector2(was.y, 0))
			right.reverse()
			_silhouette[key] = left + right
	if grow == 0.0:
		return _silhouette[key]
	return Geometry2D.offset_polygon(_silhouette[key], grow, Geometry2D.JOIN_ROUND)[0]


func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(c + Vector2.from_angle(TAU * i / 16.0) * r)
	return pts


## Quanto a ponta do plug encaixado em `j` fica deslocada do encaixe: ele sai do painel na direção da câmera, que o
## vê mais de lado quanto mais longe dos olhos (`eye`).
func _tilt(j: int) -> Vector2:
	return _tilt_at(jack_rect(j).get_center()).round()


## A paralaxe num ponto `p` da mesa: o que sai do painel ali se desloca assim (e o que entra, para o lado oposto).
func _tilt_at(p: Vector2) -> Vector2:
	return (p - _eye) * PLUG_DEPTH


## O plug encaixado, a partir do encaixe, saindo do painel até `tilt`: o próprio plug em pé (`PLUG_ART`, da aba ao
## fio) visto de frente, em pixel art como as peças redondas: um disco (`disc`) por pixel ao longo do eixo, do painel
## para a frente, cada um com a largura, a beira e os tons da linha do plug em pé que cai ali (`_face_row`): o corpo
## na cor do cabo com o anel e o friso claro em cima, o serrilhado (discos riscados, `_knurled`) e o anel do meio, e a
## capa de borracha em gomos afinando até o fio (a luva de latão fica toda dentro da tomada: à mostra, numa beira
## dourada entre ela e o corpo, ninguém sabia o que era). `lit`: a
## luz da sala ali, como no fio que sai dele. No corpo, primeiro a beira de todos (só o contorno fica à mostra) e
## depois o miolo sombreado (luz no alto à direita); a capa, disco a disco, mostra os sulcos (`PLUG_CAPA_ROW`).
## (Antes eram cápsulas e círculos vetoriais: embolotados.)
## O fio sai do meio da capa, por cima (desenhado depois). `push`: a assentada, o plug afunda tantos px. `j`: o
## encaixe, para a luz que bate no plug (`_plug_light`): no fim, o plug acende a partir da beira (`_face_rim`), a de
## cima (a lâmpada logo acima) ou a toda volta (o aro aceso do destino), sumindo para dentro. (Um anel solto por cima,
## antes, flutuava sobre a capa e a luz vinha do lado; uma beira acesa por disco listrava o plug todo.)
func _draw_plug_face(col: Array, tilt: Vector2, push: float, alpha: float, j := -1, lit := Color.WHITE) -> void:
	var pal := _plug_pal(col)
	var t := tilt - tilt.normalized() * push
	var n := maxi(1, ceili(t.length()))
	var mod := Color(lit.r, lit.g, lit.b, alpha)   # a luz da sala, como no fio que sai dele
	var light := _plug_light(j)
	# o corpo: primeiro a beira de todos os discos (só o contorno fica à mostra), depois os miolos; a capa, por
	# cima, disco a disco com a beira de cada um: ela afina para o fio, e a beira de cada gomo fica à mostra em volta
	# do seguinte, menor (os sulcos, em anéis em volta da saída do fio)
	for layer in 3:
		for k in n + 1:
			var r := _face_row(n, k)
			if (layer == 2) != r[6]:
				continue
			if layer != 1:
				PixelArt.sprite(_ci, _disc(r[0], [[r[0] / 2.0, pal[r[1]]]]), t * float(k) / n, mod)
			if layer != 0:
				var d: int = r[0] - 2
				var tones := [pal[r[2]], pal[r[3]], pal[r[4]]]
				PixelArt.sprite(_ci, _knurled(d, tones) if r[5] else _disc(d, [[d / 2.0, tones[0], tones[1], tones[2]]]), t * float(k) / n, mod)
	if light[1] > 0.02:
		var rim: Array = _face_rim(t, n, light[2])
		_ci.draw_texture(rim[0], rim[1], Color((light[0] as Color).lightened(0.2), light[1] * 0.65 * alpha))


## A linha do `PLUG_ART` que aparece no passo `k` de `n` do plug encaixado, como [diâmetro com a beira, beira, luz,
## meio, sombra, serrilhado] (caracteres da paleta, `_plug_pal`). Encaixado, ele tem poucos px de comprido: das linhas
## que caem no passo, da mesma peça que a primeira, vale a que mais se destaca (um anel, o friso claro; o serrilhado no
## empate), senão os detalhes sumiam entre um passo e outro; na capa, gomo escuro e claro se revezam. Guardada.
static var _face_rows := {}


func _face_row(n: int, k: int) -> Array:
	var key := Vector2i(n, k)
	if not _face_rows.has(key):
		var top := int(PLUG_H - PLUG_LEN)
		var a := top + floori(PLUG_LEN * k / (n + 1.0))
		var b := maxi(a + 1, top + floori(PLUG_LEN * (k + 1) / (n + 1.0)))
		var best := []
		var score := -1.0
		for i in range(a, mini(b, int(PLUG_H))):
			var row: String = PLUG_ART[i]
			var l := row.length() - row.lstrip(".").length()
			var r := row.rstrip(".").length() - 1
			if not best.is_empty() and row[r] != best[1]:
				continue   # outra peça
			var mid := row[(l + r) / 2]
			var knurl := "2323" in row or "3434" in row
			var sc := absf(float(mid) - 3.5) if mid.is_valid_int() else 0.0
			if i >= PLUG_CAPA_ROW:   # na capa, um gomo escuro sim, outro não (só os escuros a deixavam preta)
				sc = 1.0 if (mid == "5") == (k % 2 == 1) else 0.0
			if sc > score or (sc == score and knurl):
				best = [r - l + 1, row[r], row[l + 2], mid, row[r - 2], knurl, i >= PLUG_CAPA_ROW]
				score = sc
		_face_rows[key] = best
	return _face_rows[key]


## Um disco do corpo serrilhado: o disco de `d` px nos tons `tones`, riscado em fatias; enfileirados no plug
## encaixado, os riscos viram as listras ao longo dele, como as do plug em pé. Guardado.
static var _knurls := {}


func _knurled(d: int, tones: Array) -> ImageTexture:
	var key := str(d, tones)
	if not _knurls.has(key):
		var img := _disc(d, [[d / 2.0, tones[0], tones[1], tones[2]]]).get_image()
		for y in d:
			for x in d:
				var c := img.get_pixel(x, y)
				if c.a > 0.0 and posmod(floori(Vector2(x + 0.5 - d / 2.0, y + 0.5 - d / 2.0).angle() / TAU * 28.0), 2) == 1:
					img.set_pixel(x, y, c.darkened(0.2))
		_knurls[key] = ImageTexture.create_from_image(img)
	return _knurls[key]


## Por cima do fio, no meio do plug encaixado: a ponteira de onde o fio sai. O fio passa por cima do tampo e chega
## até ela, no centro.
func _draw_plug_cap(e: int) -> void:
	if float(_pushed.get(e, MORPH_SEC)) < MORPH_SEC:
		return   # ainda entrando: o corpo em pé está por cima
	var col: Array = _cable_col(e)
	var w := int(ROPE_W - 2.0)   # na cor e na largura do miolo do fio, sem contorno: o fio continua nela
	PixelArt.sprite(_ci, _disc(w, [[1.0, col[1]], [w / 2.0, col[0]]]), _plug_base(e).round(), _lit_by(_plug_base(e)))


## A luz que bate no plug encaixado em `j`, como [cor, nível, de todos os lados]: na entrada, a lâmpada da linha,
## logo acima (acende a beira de cima); no destino, o aro aceso em volta da tomada (a beira toda, mais fraco). A saída
## não tem lâmpada.
func _plug_light(j: int) -> Array:
	if j >= 1 and j <= 10:
		var lt: Array = _lit.get("l%d" % j, [LAMP_OFF, 0.0])
		return [lt[0], lt[1], false]
	if j > 20:
		var dl: Array = _lit.get("d%d" % j, [LAMP_OFF, 0.0])
		return [dl[0], 0.6 * dl[1], true]
	return [LAMP_OFF, 0.0, false]


## A luz no plug encaixado que sai até `t` em `n` passos: a silhueta dos discos juntos (os mesmos lugares de
## `PixelArt.sprite`), cada pixel dela aceso pela distância à beira de cima, contada para baixo, ou à beira mais perto
## (`around`), em `RIM_FALL`. Devolve [textura, onde desenhar]. Guardado (enquanto o plug assenta, `t` muda a cada
## quadro: limitado).
static var _face_rims := {}


func _face_rim(t: Vector2, n: int, around: bool) -> Array:
	var key := [t, around]
	if not _face_rims.has(key):
		if _face_rims.size() > 32:
			_face_rims.clear()
		var spots := []   # [posição do canto, máscara]
		var lo := Vector2(INF, INF)
		var hi := -lo
		for k in n + 1:
			var d: int = _face_row(n, k)[0]
			var p := (t * float(k) / n - Vector2(d, d) / 2.0).floor()
			spots.append([p, _disc(d, [[d / 2.0, Color.WHITE]]).get_image()])
			lo = lo.min(p)
			hi = hi.max(p + Vector2(d, d))
		var size := Vector2i(hi - lo) + Vector2i(2, 2)
		var mask := Image.create(size.x, size.y, false, Image.FORMAT_LA8)
		for sp in spots:
			var src: Image = sp[1]
			var at := Vector2i((sp[0] as Vector2) - lo) + Vector2i.ONE
			for y in src.get_height():
				for x in src.get_width():
					if src.get_pixel(x, y).a > 0.5:
						mask.set_pixel(at.x + x, at.y + y, Color.WHITE)
		var inside := func(x: int, y: int) -> bool:
			return x >= 0 and y >= 0 and x < size.x and y < size.y and mask.get_pixel(x, y).a > 0.5
		var far := RIM_FALL.size()
		var dist := PackedInt32Array()   # quantos pixels da beira acesa (`far`: longe dela, ou fora)
		dist.resize(size.x * size.y)
		dist.fill(far)
		var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)] if around else [Vector2i(0, -1)]
		for d in far:   # a beira e, camada a camada, para dentro (a de cima, só para baixo)
			for y in size.y:
				for x in size.x:
					if dist[y * size.x + x] < far or not inside.call(x, y):
						continue
					for v: Vector2i in dirs:
						var q := Vector2i(x, y) + v
						var out: bool = not inside.call(q.x, q.y)
						if (d == 0 and out) or (d > 0 and not out and dist[q.y * size.x + q.x] == d - 1):
							dist[y * size.x + x] = d
							break
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		for i in dist.size():
			if dist[i] < far:
				img.set_pixel(i % size.x, i / size.x, Color(1, 1, 1, RIM_FALL[dist[i]]))
		_face_rims[key] = [ImageTexture.create_from_image(img), lo - Vector2.ONE]
	return _face_rims[key]


## O plug de pé, com o fio saindo de baixo (y = 0), no formato de um P10 e na escala da sala (12 × 51 px, uns 2 × 9 cm
## no fundo da mesa: menor que o relógio e as listas, `Background.PROP_K`; o corpo enche o buraco da prateleira e a
## luva entra no furo da tomada), em pixel art (`PLUG_ART`, no acabamento do relógio da mesa: sombreado de cilindro com o brilho
## numa coluna só e a beira escura do lado da sombra, cantos arredondados), no jeito de um plugue P10 (a referência do
## usuário): a capa de borracha em gomos, afinando até o fio; o corpo na cor do cabo (é o que identifica o cabo), com
## um anel em cima, o serrilhado em listras finas e um anel no meio; a aba dourada; a ponta de metal dourado, com a luva,
## um isolante preto, o anel, outro isolante e o bico em ponta com a bolinha. `tip`
## falso: sem a ponta (entrando no encaixe, ela já está dentro). Entrando no buraco, só até `_cut`, escurecendo liso.
func _draw_plug_body(col: Array, tip: bool = true, light := Color.WHITE) -> void:
	var top := -PLUG_H if tip else -PLUG_LEN
	var bottom := minf(0.0, _cut)
	if bottom > top:
		_ci.draw_texture_rect_region(PixelArt.art(_plug_art(0.0), _plug_pal(col)), Rect2(-PLUG_W / 2.0, top, PLUG_W, bottom - top), Rect2(0, top + PLUG_H, PLUG_W, bottom - top), light)
	if _cut < INF:   # entrando no buraco, o plug escurece até a beira dele
		var none := Color(0, 0, 0, 0)
		var deep := Color(0, 0, 0, 0.6)
		_ci.draw_primitive(PackedVector2Array([Vector2(-PLUG_W / 2.0, _cut - 5.0), Vector2(PLUG_W / 2.0, _cut - 5.0), Vector2(PLUG_W / 2.0, _cut), Vector2(-PLUG_W / 2.0, _cut)]),
			PackedColorArray([none, none, deep, deep]), PackedVector2Array())


## O mapa do plug para o ângulo `ang`: o brilho do `PLUG_ART` fica do lado esquerdo; com esse lado de costas para a
## luz (`LIGHT`, alto à direita: em pé, por exemplo), vale o mapa espelhado, com o brilho do outro lado (sem isso, o
## plug deitado com a ponta para a esquerda tinha a luz vindo de baixo).
static var _plug_flipped: Array = []


func _plug_art(ang: float) -> Array:
	if Vector2.LEFT.rotated(ang).dot(LIGHT) >= 0.0:
		return PLUG_ART
	if _plug_flipped.is_empty():
		for row: String in PLUG_ART:
			_plug_flipped.append(row.reverse())
	return _plug_flipped


## A luz da luminária do teto no ponto p (da mesa), como a que cai no painel (`_draw_room_light`), em `CORD_LIT` da
## força: a cor que multiplica o fio e os plugs ali (longe dela, mais escuros e frios).
func _lit_by(p: Vector2) -> Color:
	var t := _room_tone(p)
	return Color.WHITE.lerp(Color(t.r, t.g, t.b), t.a * CORD_LIT)


## Onde fica a luminária do teto, nas coordenadas da mesa: no meio da tela, acima dela.
func _lamp_pos() -> Vector2:
	return Vector2(get_viewport_rect().size.x / 2.0 - global_position.x, -global_position.y - LAMP_ABOVE)


## As cores do plug do cabo `col` ([cor, brilho]), pelos caracteres de `PLUG_ART`: o cabo de baquelite na cor dele
## (do brilho à beira), o metal dourado e os isolantes, cada um do brilho à beira escura. Guardadas por cabo.
static var _plug_pals := {}


func _plug_pal(col: Array) -> Dictionary:
	var c: Color = col[0]
	if not _plug_pals.has(c):
		var h: Color = col[1]
		_plug_pals[c] = {"1": h.lightened(0.15), "2": h, "3": c, "4": c.darkened(0.25), "5": c.darkened(0.45), "6": c.darkened(EDGE),
			"Y": Pal.BRASS_PLUG[5], "y": Pal.BRASS_PLUG[4], "b": Pal.BRASS_PLUG[3], "B": Pal.BRASS_PLUG[2], "C": Pal.BRASS_PLUG[1],
			"E": Pal.BRASS_PLUG[0], "K": Pal.PLUG_INSULATOR[1], "k": Pal.PLUG_INSULATOR[0]}
	return _plug_pals[c]
