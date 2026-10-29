extends "res://scripts/ui/switchboard_panel.gd"
## Os plugs e os fios da mesa comutadora (`Switchboard`): o plug em pé e o encaixado (o cotovelo, com paralaxe), a
## luz e a sombra deles e o fio de pano pela corda (`_draw_rope`, `_kinked`, `_smooth`).

const Cord := preload("res://scripts/ui/cord.gd")   ## a física de cada fio
## [cor, brilho] de cada cabo: 0 = FONE (verde), 1..patches = cabos de conexão (vermelho, azul, amarelo, branco, preto).
## Mais cabos de conexão pedem mais cores aqui.
const HOLE_LIP := 2.0    # ...e some abaixo disto (px abaixo do buraco), atrás da beira da frente dele
const HOLE_SHADE := [[0.0, 4.0, 0.65], [4.0, 8.0, 0.4], [8.0, 12.0, 0.2]]   # o fio entrando no buraco escurece: [de, até (px a partir do buraco), escuro]

var _pushed := {}   ## ponta -> segundos desde que encaixou (a assentada, `PUSH_SEC`, e a passagem para de frente)
var _knocked := {}   ## ponta encaixada -> [segundos desde que um fio caiu nela, px que afunda] (`KNOCK_PX`)
var _draped := {}   ## ponta encaixada -> as pontas cujo fio tapava a tomada quando ela encaixou: o plug o levantou e ele corre por cima, sem esbarrar (esticado, não o contornava: preso nele, batia sem parar)
var _pushed_ang := {}   ## ponta -> o ângulo do plug na mão quando encaixou (a passagem para de frente gira dali)
var _silhouette := {}   ## encaixado (o cotovelo, pela `_elbow_pose`) ou em pé (false) -> polígono do contorno (destaque, clique)
var cursor := Vector2.ZERO
var _hover := -1               # ponta cujo plug está sob o mouse (pode ser pega); desenhada com destaque
var _cut := INF   # desenhando o plug em pé: abaixo disto (y dele) está dentro do buraco da prateleira
var _loose := {}               # ponta solta voltando para o buraco -> {"t": s caindo/recolhendo, "seat": -1 ou s assentando, "direct", "ang", e, assentando, "from", "turn", "v0", "sink", "hit"}

const SEAT_ACCEL := 2250.0
const SEAT_BOB := 1.5
const SEAT_BOB_SEC := 0.08
const PLUG_LEN := 48.0   # em pé: do fio até o alto do corpo (a ponta de metal passa disso)
## Encaixado, o plug é de cotovelo, como os da referência do usuário (a foto da mesa dos anos 60): um tubo só, da
## largura da capa, que sai da tomada na direção da câmera, a mesma do cenário, faz um arco e desce na capa
## comprida, com frisos na curva e no alto dela, e o fio continua da capa, na mesma linha. O pescoço, da tomada à curva,
## se afasta do ponto de fuga da sala (os olhos do operador, `eye`), mais quanto mais longe dele (paralaxe, `_tilt`; os
## olhos ficam à direita da mesa, na altura das plaquinhas das entradas: as entradas saem quase só para a esquerda, as
## de baixo também para baixo); a capa gira na tomada, para o lado do fio (`_elbow_ang`). Montado pixel a pixel
## (`_elbow`, nas cores do `_plug_pal`, luz no alto à direita). (Com uma bola na cabeça e a capa curta e fixa,
## ficava pequeno e grosso.)
const PLUG_DEPTH := 0.03   # px de deslocamento da curva por px de distância da tomada até os olhos (com 0,014, mal se via o pescoço)
const ELBOW_LEN := 24.0   # px: da curva ao pé da capa (na foto, uns 3 × a largura dela)
const ELBOW_W := Vector2(4.0, 2.5)   # px: a meia largura do tubo e a do pé da capa (a do fio: a capa afunila até ele)
const ELBOW_RIBS := Vector2(7.0, 16.0)   # px do eixo, a partir do começo da curva: os frisos, um a cada 3 px, do fim da curva ao alto da capa (no meio da curva, vistos de lado, viravam pedaços de arco soltos)
const ELBOW_MAX := deg_to_rad(60.0)   # e nunca mais deitada que isso
const ELBOW_SLEEVE := Vector2(3.0, 1.5)   # px: o raio e a altura da ponta de metal à mostra, na boca da tomada
const ELBOW_BODY := 15.0   # px do painel até onde acaba o corpo duro (e começa a curva de borracha); fundo o bastante para o deslocamento da curva (`_tilt`, até ~19 px) dar menos de 1 px na tela por px de profundidade (com 7, a 1,5, o corpo e a faixa esticavam)
const ELBOW_BAND := Vector2(2.5, 2.0)   # px do painel e largura da faixa na cor do cabo, no corpo duro (como no plug em pé, `PLUG_ART`)
const ELBOW_ARC := 5.0   # px: o raio do eixo na curva, do corpo para a capa
const ELBOW_Z := ELBOW_BODY + ELBOW_ARC   # a capa, a tantos px do painel (aparece deslocada `_tilt`)
const PLUG_SHADE := Vector2(-4, 5)   # encaixado, a sombra do plug no painel, deslocada assim (luz no alto à direita, `LIGHT`)
const PLUG_ART := [   ## o plug em pé, de 12 × 72 px (y de -72 a -1; o fio sai de y = 0): a ponta de metal, o corpo de
	".....mm.....",
	"....gmms....",
	"...gmmmss...",
	"...gmmmss...",
	"....mmss....",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...kkkkkk...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"...gmmmss...",
	"..12334556..",
	".1223334556.",
	".2233334556.",
	".2233334556.",
	".abbbbbbbcc.",
	".abbbbbbbcc.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	".2233334556.",
	"..23334556..",
	"..45556666..",
	"..23334556..",
	"..23334556..",
	"..45556666..",
	"..23334556..",
	"..23334556..",
	"..45556666..",
	"..23334556..",
	"..23334556..",
	"..45556666..",
	"..23334556..",
	"..23334556..",
	"..23334556..",
	"..23334556..",
	"..23334556..",
	"..23334556..",
	"...334556...",
	"...334556...",
	"...334556...",
	"...334556...",
	"...334556...",
	"...334556...",
	"...556666...",
]
## As cores do `PLUG_ART`: o corpo de plástico cinza fosco, no tom do móvel (`Pal.SHELL`, do brilho à beira da sombra,
## clara: sem contorno escuro), igual em todos os cabos; a ponta de metal prateado. A faixa na cor do cabo vem de `_plug_pal`
## (guardado, o fio fica dentro do buraco: sem ela, não se sabia de que par era o plug).
const PLUG_PAL := {"1": Pal.SHELL[7], "2": Pal.SHELL[6], "3": Pal.SHELL[5], "4": Pal.SHELL[4], "5": Pal.SHELL[3],
	"6": Pal.SHELL[2], "g": Pal.PLUG_TIP[3], "m": Pal.PLUG_TIP[2], "s": Pal.PLUG_TIP[1], "k": Pal.PLUG_TIP[0]}
## A luz da lâmpada ou do aro aceso no plug encaixado, pixel a pixel a partir da beira virada para ela (`_elbow_rim`):
## cheia na beira e sumindo para dentro em degraus. Com a beira acesa e o resto apagado, a luz tomava o plug de uma vez.
const RIM_FALL := [0.75, 0.4, 0.16]
const MORPH_SEC := 0.08   # encaixando ou saindo, o plug passa de em pé para o cotovelo de frente (e volta) nesse tempo
const PUSH_PX := 1.0     # ao encaixar, o plug desce tanto (px) e volta...
const ROT_STEP := deg_to_rad(5.0)   # solto ou na mão, o plug gira em passos assim, cada um montado pixel a pixel (`PixelArt.turned`)
const PUSH_SEC := 0.14   # ...nesse tempo, como se fosse empurrado para dentro
const KNOCK_PX := Vector2(0.5, 1.0)   # um fio caindo nele também o afunda (px, da batida fraca à forte: a fraca some no arredondamento)...
const KNOCK_SEC := 0.1   # ...e ele volta nesse tempo
const LAMP_ABOVE := 90.0   # px acima da tela: a luminária do teto, que não aparece
const CORD_LIT := 0.6   # o fio e os plugs em pé pegam essa parte da luz da sala do painel (estão na frente dele)
const TAIL_IN := 5.0   # px do fio que entram na traseira do plug em pé (`_draw_tail`)
const ROPE_W := 5.0   # px: a largura do fio com a beira (o miolo tem 2 a menos; esticado, os dois afinam 1). Era 7 em 1280 × 720.
## A beira do fio do lado da sombra: a cor dele escurecida assim; do lado da luz, sem beira (o volume pelo tom, sem o
## contorno escuro dos dois lados, que deixava o fio com cara de desenho).
const ROPE_EDGE := 0.3
const AIR_LIFT := Vector2(-6, 8)   # a sombra do fio no ar, depois da beira da prateleira: longe do console, como a do plug na mão
const SMOOTH_PX := 3.0   # px: o fio é desenhado em trechos retos deste tamanho, numa curva pelos pontos da corda (`_smooth`)
const KINK := 1.0   # px: as dobras que o fio de pano guarda, no máximo
const KINK_PULLED := 0.4   # esticado pelo contrapeso, o pano alisa: as dobras ficam nessa parte (inteiras, num fio reto viravam degraus)
const BRAID := 5.0   # px: o trançado do fio (o brilho dele vem em pedaços desse comprimento)...
const BRAID_MIX := 0.5   # ...no meio do caminho entre o pano e o brilho dele (o brilho cheio listrava o fio, como o pano mesclado não faz)
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
		var pose := _elbow_pose(e)   # encaixado: o fio sai do pé da capa
		return jack_rect(int(ends[e])).get_center() + Vector2(pose.x, pose.y) + (Vector2.DOWN.rotated(pose.z) * (ELBOW_LEN - 1.0)).round()
	if _loose.has(e):
		if _loose[e]["seat"] >= 0.0:
			return _seat_pose(e)[0]
		return (ropes[e] as Cord).tip()
	return _rest(e)


## Quanto o plug encaixado desce (px): a assentada, recém-encaixado, e a batida de um fio caindo nele.
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
	if r.hinged():   # o fio entra no pé da capa desenhada (no passo de `ROT_STEP` dela)
		pts = pts.duplicate()
		pts[pts.size() - 1] = _plug_base(e)
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
## (dois sobrepostos escureciam duas vezes) e os plugs encaixados (`pegs`: eles ficam por cima). Em
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


## O fio se mexendo, traçado pela placa de vídeo: a beira da sombra e o resto (meio pixel para a luz) e, por cima, o
## trançado e a sombra do buraco.
func _draw_rope_line(pts: PackedVector2Array, lights: PackedColorArray, col: Array, thin: float, braid: float) -> void:
	var pts2 := PackedVector2Array()   # o brilho, 1 px para o lado do fio virado para a luz (`LIGHT`, alto à direita)
	var half := PackedVector2Array()   # o miolo com a beira da luz, meio px para ela
	var length := 0.0
	for i in pts.size():
		var side := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).orthogonal().normalized()
		side = side if side.dot(LIGHT) > 0.0 else -side
		pts2.append(pts[i] + side.round())
		half.append(pts[i] + side * 0.5)
		if i > 0:
			length += pts[i].distance_to(pts[i - 1])
	_ci.draw_polyline_colors(pts, _tinted((col[0] as Color).darkened(ROPE_EDGE), lights), ROPE_W - thin)
	_ci.draw_polyline_colors(half, _tinted(col[0], lights), ROPE_W - 1.0 - thin)
	var at := 0.0
	var segs := PackedVector2Array()   # o trançado inteiro numa chamada de desenho só (um traço por pedaço eram dezenas)
	var tones := PackedColorArray()
	while at < length:   # o trançado do pano: o brilho em pedaços
		var part := Cord.along(pts2, at, minf(at + braid - 2.0, length))
		var tone := (col[0] as Color).lerp(col[1], BRAID_MIX) * _lit_by(part[0]) if part.size() >= 2 else Color()
		for i in part.size() - 1:
			segs.append_array([part[i], part[i + 1]])
			tones.append(tone)
		at += braid
	if not segs.is_empty():
		_ci.draw_multiline_colors(segs, tones, 1.0)
	for band in HOLE_SHADE:   # perto do buraco, a sombra de dentro dele, em degraus
		var part := Cord.along(pts, band[0], band[1])
		if part.size() >= 2:
			_ci.draw_polyline(part, Color(0, 0, 0, band[2]), ROPE_W - thin)


## Os fios parados já montados: [pontos, luzes, cabo, afinado, trançado] -> [canto, textura] (`_rope_image`).
static var _rope_arts := {}
var _laid := {}   ## ponta -> [polígonos, caixa] do fio já desenhado neste desenho (o de cima faz sombra nele, `_cross_shade`)


## A imagem do fio parado pelos pontos `pts` (px da mesa), cada pixel pelo trecho mais perto dele: a distância à linha
## do meio dá a beira e o miolo (a mesma largura em toda a curva), o lado dá a beira (só a da sombra é escura,
## `ROPE_EDGE`) e o brilho do trançado (1 px para a luz,
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
				var side := (c - q).dot(n)
				var tone: Color = (col[0] as Color).darkened(ROPE_EDGE) if d >= core and side < 0.0 else col[0]
				if d < core and side >= 0.5 and fposmod(at + t * seg, braid) < braid - 2.0:   # o trançado, do lado da luz
					tone = (col[0] as Color).lerp(col[1], BRAID_MIX)
				var light := lights[i].lerp(lights[i + 1], t)
				for band in HOLE_SHADE:   # perto do buraco, a sombra de dentro dele
					if at + t * seg >= band[0] and at + t * seg < band[1]:
						tone = tone.lerp(Color.BLACK, band[2])
				img.set_pixel(x, y, Color(tone * light, 1.0))
		at += seg
	return [r.position, ImageTexture.create_from_image(img)]


## O fio entrando na traseira do plug em pé, em `at`: um trecho dele segue TAIL_IN px para dentro do plug, no eixo
## dele (o plug, desenhado depois, o cobre), e uma junta redonda fecha a dobra. Sem isso, o fio chegando de lado
## terminava num corte reto no meio da ponta do plug e deixava um vão do outro lado.
func _draw_tail(e: int, at: Vector2, c: Color, light: Color, thin: float) -> void:
	var inside := at + Vector2.UP.rotated(_plug_angle(e)) * TAIL_IN
	_ci.draw_line(at, inside, c.darkened(ROPE_EDGE) * light, ROPE_W - thin)
	_ci.draw_line(at, inside, c * light, ROPE_W - 2.0 - thin)
	var w := int(ROPE_W - thin)
	PixelArt.sprite(_ci, _disc(w, [[(w - 2) / 2.0, c], [w / 2.0, c.darkened(ROPE_EDGE)]]), at, light)


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
	var pose := _elbow_pose(e) if seated else Vector3.ZERO
	var at := jack_rect(int(ends[e])).get_center() if seated else _plug_base(e)   # encaixado, desenha a partir da tomada
	if shadow and not seated:
		at += _lift(e)
	_ci.draw_set_transform(at.round(), _plug_angle(e))
	_cut = hole(e).y + HOLE_LIP - at.round().y if _in_hole(e) else INF
	if shadow and seated:   # da tomada até onde a luz joga a frente da cabeça, e dali a capa
		_ci.draw_colored_polygon(_elbow_shadow(pose), SHADOW)
	elif shadow:
		_draw_cut(_plug_outline(e, 0.0), SHADOW)
	else:
		if e == _hover:   # contorno claro, na forma do plug: dá para pegar
			_draw_cut(_plug_outline(e, 2.0), Pal.GLOW)
		if seated:
			var k := minf(float(_pushed.get(e, MORPH_SEC)) / MORPH_SEC, 1.0)
			if k < 1.0:   # acabou de encaixar: o cotovelo cresce enquanto o corpo em pé entra no encaixe
				_ci.draw_set_transform(at.round(), 0.0, Vector2.ONE * lerpf(0.4, 1.0, k))
			_draw_elbow(_cable_col(e), pose, _push(e), 1.0, int(ends[e]), _lit_by(at))
			if k < 1.0:   # o corpo em pé gira para a tomada e encurta até o tamanho do cotovelo, entrando no encaixe
				var to := _plug_base(e) - at
				var axis := Transform2D(lerp_angle(float(_pushed_ang.get(e, 0.0)), to.angle() - PI / 2.0, k), Vector2(1.0, lerpf(1.0, to.length() / PLUG_LEN, k)), 0.0, at.round())
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


## Quanto a sombra se desloca de onde o fio entra no plug: mais quanto mais o plug sai do painel (na mão, mais).
## Encaixado, a do pé da capa, como a do plug (`PLUG_SHADE`).
func _lift(e: int) -> Vector2:
	if ends[e] != -1:
		return PLUG_SHADE
	if _loose.has(e) and _loose[e]["seat"] >= 0.0:   # afundando, a sombra cola na prateleira
		return Vector2(-3, 4).lerp(Vector2(-2, 2), _seat_pose(e)[2])
	return Vector2(-6, 8) if held == e else Vector2(-3, 4) if _loose.has(e) else Vector2(-2, 2)


## A silhueta do plug num polígono só (a sombra não escurece duas vezes onde as partes se sobrepõem), alargada `grow`
## px para o destaque: a do desenho dele (o cotovelo, encaixado, a partir da tomada; em pé, a partir do fio).
func _plug_outline(e: int, grow: float) -> PackedVector2Array:
	var seated: bool = ends[e] != -1
	var key: Variant = _elbow_pose(e) if seated else false
	if not _silhouette.has(key):
		if seated:
			var art := _elbow(key)
			_silhouette[key] = _art_outline(art[0], -(art[1] as Vector2))
		else:
			_silhouette[key] = _art_outline(PLUG_ART, Vector2(-PLUG_W / 2.0, -PLUG_H))
	if grow == 0.0:
		return _silhouette[key]
	return Geometry2D.offset_polygon(_silhouette[key], grow, Geometry2D.JOIN_ROUND)[0]


## O contorno do mapa `rows` (pixel art) posto em `origin`, em degraus (um a cada linha em que a largura muda); as
## linhas vazias, em cima e embaixo, ficam de fora (contadas, faziam o contorno dar a volta errado).
static func _art_outline(rows: Array, origin: Vector2) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var was := Vector2.INF
	var last := 0
	for i in rows.size():
		var row: String = rows[i]
		if row.lstrip(".").is_empty():
			continue
		last = i
		var span := Vector2(row.length() - row.lstrip(".").length(), row.rstrip(".").length()) + Vector2.ONE * origin.x
		if span != was:
			if was != Vector2.INF:
				left.append(Vector2(was.x, origin.y + i))
				right.append(Vector2(was.y, origin.y + i))
			left.append(Vector2(span.x, origin.y + i))
			right.append(Vector2(span.y, origin.y + i))
			was = span
	left.append(Vector2(was.x, origin.y + last + 1))
	right.append(Vector2(was.y, origin.y + last + 1))
	right.reverse()
	return left + right


## O plug encaixado (`_elbow`), com o meio da tomada em (0, 0), na pose `pose` (`_elbow_pose`): `push` o empurra tantos
## px para dentro (a assentada, a batida de um fio), `alpha` some (saindo), `lit` é a luz da sala ali, como no fio que
## sai dele. `j`: o encaixe, para a luz que bate no plug (`_plug_light`): ele acende a partir da beira (`_elbow_rim`),
## a de cima (a lâmpada logo acima) ou a toda volta (o aro aceso do destino), sumindo para dentro.
func _draw_elbow(col: Array, pose: Vector3, push: float, alpha: float, j := -1, lit := Color.WHITE) -> void:
	var t := Vector2(pose.x, pose.y)
	t = (t - t.normalized() * minf(push, t.length())).round()
	var key := Vector3(t.x, t.y, pose.z)
	var art := _elbow(key)
	var p: Vector2 = -art[1]
	_ci.draw_texture(PixelArt.art(art[0], _plug_pal(col)), p, Color(lit.r, lit.g, lit.b, alpha))
	var light := _plug_light(j)
	if light[1] > 0.02:
		_ci.draw_texture(_elbow_rim(key, light[2]), p, Color((light[0] as Color).lightened(0.2), light[1] * 0.65 * alpha))


## Quanto a curva do plug encaixado em `j` fica deslocada da tomada: o pescoço sai do painel na direção da câmera, que o
## vê mais de lado quanto mais longe dos olhos (`eye`).
func _tilt(j: int) -> Vector2:
	return ((jack_rect(j).get_center() - _eye) * PLUG_DEPTH).round()


## O ângulo da capa do plug encaixado da ponta `e`, da vertical (positivo: para a esquerda), em passos de `ROT_STEP`:
## o plug gira na tomada e a capa vai com o fio (`Cord.pivot`: o peso dela e o fio puxando para o buraco). Antes do
## primeiro passo do fio, a meio caminho entre a vertical e a direção do buraco (`hole`). Tapando a chave de escuta, o
## clique ali é dela (`_plug_under`).
func _elbow_ang(e: int) -> float:
	var r: Cord = ropes.get(e)
	var a := Vector2.DOWN.angle_to(r.tip() - r.pivot) if r != null and r.hinged() else Vector2.DOWN.angle_to((hole(e) - jack_rect(int(ends[e])).get_center()).normalized() + Vector2.DOWN)
	return snappedf(clampf(a, -ELBOW_MAX, ELBOW_MAX), ROT_STEP)


## O plug encaixado da ponta `e` como (x, y, ângulo): a curva, a partir da tomada (`_tilt`), e a capa (`_elbow_ang`).
func _elbow_pose(e: int) -> Vector3:
	var t := _tilt(int(ends[e]))
	return Vector3(t.x, t.y, _elbow_ang(e))


## As partes do plug encaixado da ponta `e` em que os outros fios esbarram (`Cord.pegs`), como (x, y, raio): a curva e
## a capa, em dois discos, à frente do painel, na altura do fio que cai de outra capa. O pescoço, da tomada à curva,
## fica atrás: com a paralaxe, deitado, ele segurava o fio como uma prateleira e o fio serpenteava pelas cabeças.
func _elbow_pegs(e: int) -> Array[Vector3]:
	var pose := _elbow_pose(e)
	var t := Vector2(pose.x, pose.y)
	var c := jack_rect(int(ends[e])).get_center()
	var out: Array[Vector3] = [Vector3(c.x + t.x, c.y + t.y, ELBOW_W.x + 0.5)]
	for k: float in [0.35, 0.75]:
		var b := c + t + Vector2.DOWN.rotated(pose.z) * ELBOW_LEN * k
		out.append(Vector3(b.x, b.y, lerpf(ELBOW_W.x, ELBOW_W.y, clampf((ELBOW_LEN * k - ELBOW_RIBS.y) / (ELBOW_LEN - ELBOW_RIBS.y), 0.0, 1.0)) + 0.5))   # a capa afunila (`_elbow`)
	return out


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


## O plug encaixado em pixel art, na pose (x, y da curva a partir da tomada, ângulo da capa), como [mapa (os
## caracteres do `_plug_pal`), onde fica o meio da tomada nele]. Um tubo em 3D pelo eixo dele: o ponto do eixo a z px
## do painel aparece deslocado `z × t / ELBOW_Z` (a curva, em `t`), e em volta de cada um, um círculo do raio do tubo,
## da mesma largura de qualquer lado (projetar cada ponto da superfície assim esticava o tubo para o lado do
## deslocamento: quanto mais longe dos olhos, mais grosso). Da tomada para fora: a ponta de metal (`ELBOW_SLEEVE`), o
## corpo duro com a faixa na cor do cabo (`ELBOW_BODY`, `ELBOW_BAND`), a curva de borracha num quarto de círculo
## (`ELBOW_ARC`) e a capa, paralela ao painel, até o pé. Cada pixel mostra o ponto mais à frente (na direção da vista),
## no tom da luz na normal do tubo ali (`LIGHT`, um pouco de frente): a faixa e os frisos saem em anel. Junto do
## painel, mais escuro. Guardado pela pose. (Desenhado em 2D, com discos, ficava chapado, sem profundidade.)
static var _elbows := {}


static func _elbow(pose: Vector3) -> Array:
	if not _elbows.has(pose):
		if _elbows.size() > 256:
			_elbows.clear()
		var sun := Vector3(LIGHT.x, LIGHT.y, 1.1).normalized()
		var t := Vector2(pose.x, pose.y)
		var sv := t / ELBOW_Z   # o deslocamento na tela por px de profundidade
		var eye := Vector3(-sv.x, -sv.y, 1.0).normalized()   # para onde está quem olha
		var ex := (Vector3.RIGHT - eye * eye.x).normalized()   # os eixos da tela, de frente para ele
		var ey := (Vector3(0, 1, 0) - eye * eye.y).normalized()   # (y da tela para baixo)
		var dir := Vector2.DOWN.rotated(pose.z)
		var r := ELBOW_W.x
		var arc := PI / 2.0 * ELBOW_ARC   # o comprimento do eixo na curva
		var cap := ELBOW_LEN - ELBOW_ARC   # e na capa
		var axis := []   # [ponto, tangente, raio, parte, px do eixo desde o começo da curva], a cada quarto de px
		for i in int(ELBOW_BODY * 4.0):
			var z := i / 4.0
			axis.append([Vector3(0, 0, z), Vector3.BACK, ELBOW_SLEEVE.x if z < ELBOW_SLEEVE.y else r,
				"sleeve" if z < ELBOW_SLEEVE.y else "body", z - ELBOW_BODY])
		for i in int(arc * 4.0):
			var th := i / 4.0 / ELBOW_ARC
			axis.append([Vector3(dir.x * ELBOW_ARC * (1.0 - cos(th)), dir.y * ELBOW_ARC * (1.0 - cos(th)), ELBOW_BODY + ELBOW_ARC * sin(th)),
				Vector3(dir.x * sin(th), dir.y * sin(th), cos(th)), r, "bend", i / 4.0])
		for i in int(cap * 4.0) + 1:
			var u := i / 4.0
			var w := lerpf(r, ELBOW_W.y, clampf((arc + u - ELBOW_RIBS.y) / (arc + cap - ELBOW_RIBS.y), 0.0, 1.0))   # afunila do fim dos frisos até o fio
			axis.append([Vector3(dir.x * (ELBOW_ARC + u), dir.y * (ELBOW_ARC + u), ELBOW_Z), Vector3(dir.x, dir.y, 0.0), w,
				"mouth" if u > cap - 1.0 else "cap", arc + u])
		var foot := t + dir * ELBOW_LEN
		var lo := Vector2i((Vector2.ZERO.min(t).min(foot) - Vector2.ONE * (r + 2.0)).floor())
		var hi := Vector2i((Vector2.ZERO.max(t).max(foot) + Vector2.ONE * (r + 2.0)).ceil())
		var size := hi - lo
		var depth := PackedFloat32Array()   # o mais à frente em cada pixel
		depth.resize(size.x * size.y)
		depth.fill(-INF)
		var hit := PackedInt32Array()   # qual ponto do eixo
		hit.resize(size.x * size.y)
		var off := PackedVector2Array()   # e onde, do meio do círculo dele
		off.resize(size.x * size.y)
		for k in axis.size():
			var a: Array = axis[k]
			var pt: Vector3 = a[0]
			var rk: float = a[2]
			var at := Vector2(pt.x, pt.y) + sv * pt.z
			for y in range(maxi(floori(at.y - rk) - lo.y, 0), mini(ceili(at.y + rk) - lo.y, size.y)):
				for x in range(maxi(floori(at.x - rk) - lo.x, 0), mini(ceili(at.x + rk) - lo.x, size.x)):
					var o := Vector2(x + lo.x + 0.5, y + lo.y + 0.5) - at
					if o.length_squared() > rk * rk:
						continue
					var d := pt.dot(eye) + sqrt(rk * rk - o.length_squared())
					var i := y * size.x + x
					if d > depth[i]:
						depth[i] = d
						hit[i] = k
						off[i] = o
		var rows := []
		for y in size.y:
			var row := ""
			for x in size.x:
				var i := y * size.x + x
				if depth[i] == -INF:
					row += "."
					continue
				var a: Array = axis[hit[i]]
				var pt: Vector3 = a[0]
				var tan: Vector3 = a[1]
				var rk: float = a[2]
				var o := off[i] / rk
				var nv := ex * o.x + ey * o.y + eye * sqrt(maxf(1.0 - o.length_squared(), 0.0))
				nv = (nv - tan * nv.dot(tan)).normalized()   # a normal do tubo (sem a parte ao longo dele)
				var lit := nv.dot(sun)   # de frente, o tom 3, como o corpo do plug em pé; o 1 só no brilho
				if a[3] == "sleeve":
					row += "g" if lit > 0.6 else ("m" if lit > 0.2 else ("s" if lit > -0.2 else "k"))
					continue
				if a[3] == "body" and pt.z >= ELBOW_BAND.x and pt.z < ELBOW_BAND.x + ELBOW_BAND.y:   # a faixa do cabo
					row += "a" if lit > 0.97 else ("b" if lit > 0.3 else "c")
					continue
				var dark := 1 if pt.z < 1.5 else 0   # junto do painel, na sombra dele
				var along: float = a[4]
				if a[3] == "mouth":
					dark = 2   # a boca de onde sai o fio
				elif a[3] != "body" and along >= ELBOW_RIBS.x and along < ELBOW_RIBS.y and fposmod(along - ELBOW_RIBS.x, 3.0) < 1.0:
					dark = 2   # o friso
				row += str(mini((1 if lit > 0.97 else 6 - clampi(int((lit + 0.05) * 4.0), 0, 4)) + dark, 6))
			rows.append(row)
		_elbows[pose] = [rows, -Vector2(lo)]
	return _elbows[pose]


## A sombra do plug encaixado no painel, a partir da tomada, na pose `pose`: da tomada até a curva deslocada
## `PLUG_SHADE` (luz no alto à direita) e, dali, a da capa, num polígono só (não escurece duas vezes onde se sobrepõem).
## Segue o plug desenhado, com a paralaxe: sem ela, a sombra da capa caía do lado da luz. Guardada.
static var _elbow_shades := {}


static func _elbow_shadow(pose: Vector3) -> PackedVector2Array:
	if not _elbow_shades.has(pose):
		if _elbow_shades.size() > 256:
			_elbow_shades.clear()
		var dir := Vector2.DOWN.rotated(pose.z)
		var side := dir.orthogonal()
		var top := Vector2(pose.x, pose.y) + PLUG_SHADE
		var foot := top + dir * ELBOW_LEN
		var head := Geometry2D.convex_hull(_circle(Vector2.ZERO, ELBOW_W.x + 1.0) + _circle(top, ELBOW_W.x))
		var boot := PackedVector2Array([top + side * ELBOW_W.x, foot + side * ELBOW_W.y, foot - side * ELBOW_W.y, top - side * ELBOW_W.x])
		_elbow_shades[pose] = Geometry2D.merge_polygons(head, boot)[0]
	return _elbow_shades[pose]


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(c + Vector2.from_angle(TAU * i / 16.0) * r)
	return pts


## A luz no plug encaixado, como máscara do `_elbow(pose)`: cheia na beira de cima (ou na de toda volta, `around`) e
## sumindo para dentro, pixel a pixel, em `RIM_FALL`. Guardada.
static var _elbow_rims := {}


func _elbow_rim(pose: Vector3, around: bool) -> ImageTexture:
	var key := Vector4(pose.x, pose.y, pose.z, 1.0 if around else 0.0)
	if not _elbow_rims.has(key):
		if _elbow_rims.size() > 256:
			_elbow_rims.clear()
		var rows: Array = _elbow(pose)[0]
		var size := Vector2i((rows[0] as String).length(), rows.size())
		var inside := func(x: int, y: int) -> bool:
			return x >= 0 and y >= 0 and x < size.x and y < size.y and rows[y][x] != "."
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
		_elbow_rims[key] = ImageTexture.create_from_image(img)
	return _elbow_rims[key]


## O plug de pé, com o fio saindo de baixo (y = 0), na escala da sala (12 × 72 px; o corpo, 10 de largura, enche o
## buraco da prateleira; à mostra, a ponta é quase tão alta quanto ele, como na foto), em pixel art (`PLUG_ART`, `_plug_pal`),
## limpo como os da referência do usuário (uma mesa comutadora dos anos 60): o corpo cilíndrico de plástico cinza liso,
## sombreado de cilindro sem contorno escuro, do comprimento da ponta, com uma faixa na cor do cabo, e a capa flexível
## afunilando até o fio (a mesma do cotovelo encaixado: sem ela, ele sumia ao tirar o plug), e a ponta de metal
## prateado, reta do corpo até a bolinha arredondada do bico, da largura do furo da tomada (6 px, `JACK_RINGS`), com o anel
## isolante. `tip` falso: sem a ponta (entrando no encaixe, ela já está dentro).
## Entrando no buraco, só até `_cut`, escurecendo liso.
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


## As cores do plug do cabo `col` ([cor, brilho]): `PLUG_PAL` com a faixa na cor dele. Guardadas por cabo.
static var _plug_pals := {}


func _plug_pal(col: Array) -> Dictionary:
	var c: Color = col[0]
	if not _plug_pals.has(c):
		_plug_pals[c] = PLUG_PAL.merged({"a": col[1], "b": c, "c": c.darkened(ROPE_EDGE)})
	return _plug_pals[c]


## A luz da luminária do teto no ponto p (da mesa), como a que cai no painel (`_draw_room_light`), em `CORD_LIT` da
## força: a cor que multiplica o fio e os plugs ali (longe dela, mais escuros e frios).
func _lit_by(p: Vector2) -> Color:
	var t := _room_tone(p)
	return Color.WHITE.lerp(Color(t.r, t.g, t.b), t.a * CORD_LIT)


## Onde fica a luminária do teto, nas coordenadas da mesa: no meio da tela, acima dela.
func _lamp_pos() -> Vector2:
	return Vector2(get_viewport_rect().size.x / 2.0 - global_position.x, -global_position.y - LAMP_ABOVE)
