extends "res://scripts/ui/switchboard_panel.gd"
## Os plugs e os fios da mesa comutadora (`Switchboard`): o plug em pé e o encaixado (de frente, com paralaxe), a
## luz e a sombra deles e o fio de pano pela corda (`_draw_rope`, `_kinked`, `_smooth`).

const Cord := preload("res://scripts/ui/cord.gd")   ## a física de cada fio
## [cor, brilho] de cada cabo: 0 = FONE (verde), 1..patches = cabos de conexão (vermelho, azul, amarelo, branco, preto).
## Mais cabos de conexão pedem mais cores aqui.
const CORD_COLORS := [
	[Color("3d6e34"), Color("6c9e58")],
	[Color("8e2a22"), Color("c4493b")],
	[Color("2a4a7c"), Color("4f7bb6")],
	[Color("b48c1c"), Color("e6c24c")],
	[Color("b8b2a2"), Color("e4dfd0")],   # branco de pano velho, puxado para o creme
	[Color("2a2723"), Color("57524a")],   # preto: o brilho mais claro, senão o trançado some
]
const HOLE_LIP := 3.0    # ...e some abaixo disto (px abaixo do buraco), atrás da beira da frente dele
const HOLE_SHADE := [[0.0, 5.0, 0.65], [5.0, 10.0, 0.4], [10.0, 16.0, 0.2]]   # o fio entrando no buraco escurece: [de, até (px a partir do buraco), escuro]

var _pushed := {}   ## ponta -> segundos desde que encaixou (a assentada, `PUSH_SEC`, e a passagem para de frente)
var _pushed_ang := {}   ## ponta -> o ângulo do plug na mão quando encaixou (a passagem para de frente gira dali)
var _silhouette := {}   ## inclinação do plug encaixado (em pé: false) -> polígono do contorno (destaque e sombra)
var cursor := Vector2.ZERO
var _hover := -1               # ponta cujo plug está sob o mouse (pode ser pega); desenhada com destaque
var _cut := INF   # desenhando o plug em pé: abaixo disto (y dele) está dentro do buraco da prateleira
var _loose := {}               # ponta solta voltando para o buraco -> {"t": s caindo/recolhendo, "seat": -1 ou s assentando, "direct", "ang", e, assentando, "from", "turn", "v0", "sink", "hit"}

const SEAT_ACCEL := 3000.0
const SEAT_BOB := 2.0
const SEAT_BOB_SEC := 0.08
const PLUG_LEN := 59.0   # em pé: do fio até o alto da aba (a ponta de metal passa disso)
## Encaixado, de onde fica a tomada até onde o fio entra: a ponta de metal some dentro dela e o anel assenta no buraco.
const PLUG_FACE_R := 8.0   # encaixado: o raio do corpo (18 px com a beira, como o em pé; ele cobre a tomada e a aba)
const EDGE := 0.65          # a beira do plug e do fio: a cor da peça escurecida assim (contorno preto destoava do cenário)
## Encaixado, o plug sai do painel na direção da câmera, a mesma do cenário: a ponta dele se afasta do ponto de fuga
## da sala (os olhos do operador, `eye`), mais quanto mais longe dele (paralaxe, `_tilt`). Os olhos ficam à direita da
## mesa, na altura das plaquinhas das entradas: os plugs das entradas saem quase só para a esquerda, os de baixo
## também para baixo. (Era um ponto fixo 600 px acima do painel: todos pareciam vistos de cima, contra a sala.)
const PLUG_DEPTH := 0.02   # px de deslocamento da ponta por px de distância do encaixe até os olhos (estilizado: a conta daria ~0,06, de lado demais)
const PLUG_SHADE := Vector2(7, 9)   # encaixado, a sombra vai do encaixe até aqui (luz no alto à esquerda)
const PLUG_ART := [   ## o plug em pé, de 20 × 93 px (y de -93 a -1; o fio sai de y = 0): `_plug_pal` dá as cores
	".........bE.........",
	"........yYbE........",
	".......yYbbBE.......",
	".......yYbbBE.......",
	".......byBBCE.......",
	"........BbCE........",
	"........BbCE........",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......KKKkkkkk......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"......yYybbBBE......",
	"....YYYYYyyybbBE....",
	"....bybbbBBBCCCE....",
	"....bybbbBBBCCCE....",
	"..3233334444555556..",
	".212222233333444556.",
	".434444455555555556.",
	".212222233333444556.",
	".212222233333444556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".222323243434454556.",
	".212222233333444556.",
	".212222233333444556.",
	".434444455555555556.",
	".434444455555555556.",
	".111111122222333446.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	".212222233333444556.",
	"..3233334444555556..",
	"..3233334444555556..",
	"..3233334444555556..",
	"..3233334444555556..",
	"...54555555555556...",
	"...32333344455556...",
	"...32333344455556...",
	"....545555555556....",
	"...32333344455556...",
	"...32333344455556...",
	"....545555555556....",
	"....323334445556....",
	"....323334445556....",
	".....5455555556.....",
	"....323334445556....",
	"....323334445556....",
	".....5455555556.....",
	".....3233445556.....",
	".....3233445556.....",
	"......54555556......",
	".....3233445556.....",
	".....3233445556.....",
]
const PLUG_CAPA_ROW := 72   # a linha do `PLUG_ART` onde começa a capa de borracha (os gomos, até o fio)
const PLUG_ABA_D := 12   # a aba dourada, com a beira (a largura dela no `PLUG_ART`): a luz e a sombra de contato do encaixado
const MORPH_SEC := 0.08   # encaixando ou saindo, o plug passa de em pé para de frente (e volta) nesse tempo
const PUSH_PX := 1.5     # ao encaixar, o plug afunda (o tampo encolhe tanto, px) e volta...
const ROT_STEP := deg_to_rad(5.0)   # solto ou na mão, o plug gira em passos assim, cada um montado pixel a pixel (`PixelArt.turned`)
const PUSH_SEC := 0.14   # ...nesse tempo, como se fosse empurrado para dentro
const LAMP_ABOVE := 120.0   # px acima da tela: a luminária do teto, que não aparece
const CORD_LIT := 0.6   # o fio e os plugs em pé pegam essa parte da luz da sala do painel (estão na frente dele)
const TAIL_IN := 6.0   # px do fio que entram na traseira do plug em pé (`_draw_tail`)
const ROPE_W := 9.0   # px: a largura do fio com a beira (o miolo tem 3 a menos; esticado, os dois afinam 1). Era 8.
const AIR_LIFT := Vector2(8, 10)   # a sombra do fio no ar, depois da beira da prateleira: longe do console, como a do plug na mão
const SMOOTH_PX := 4.0   # px: o fio é desenhado em trechos retos deste tamanho, numa curva pelos pontos da corda (`_smooth`)
const KINK := 1.5   # px: as dobras que o fio de pano guarda, no máximo
const BRAID := 6.0   # px: o trançado do fio (o brilho dele vem em pedaços desse comprimento)
## Esticado (`Cord.taut`), o fio de pano alisa: as dobras somem aos poucos até o fim do fio, o trançado se espaça até
## TAUT_BRAID e, da metade disso em diante, ele afina 1 px; frouxo, volta com as dobras inteiras.
const TAUT_BRAID := 1.3
const ROPE_SHADOW := Vector2(3, 4)  # deslocamento da sombra dos fios junto ao buraco; até o plug, cresce como a dele (`_lift`)

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


## Quanto o plug recém-encaixado está afundado (px, a assentada).
func _push(e: int) -> float:
	return PUSH_PX * sin(PI * minf(float(_pushed[e]) / PUSH_SEC, 1.0)) if _pushed.has(e) else 0.0


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
	if shadow:
		var sh := PackedVector2Array()   # o fio desce do plug até o buraco: a sombra vai da do plug até a de rente ao painel
		var lift := _lift(e)
		for i in pts.size():
			var k := float(i) / (pts.size() - 1)
			if r.air >= 1:   # no ar, na frente do console: a sombra se afasta logo depois da beira e cai nele
				sh.append(pts[i] + (ROPE_SHADOW if i < r.air else AIR_LIFT))
				continue
			sh.append(pts[i] + ROPE_SHADOW.lerp(lift, k * k))
		_ci.draw_polyline(_smooth(sh), SHADOW, ROPE_W - 1.0 - thin)
		return
	var col: Array = _cable_col(e)
	pts = _smooth(_kinked(e, pts, 1.0 - taut))
	var lights := PackedColorArray()   # a luz da sala ao longo do fio
	for q in pts:
		lights.append(_lit_by(q))
	_ci.draw_polyline_colors(pts, _tinted((col[0] as Color).darkened(EDGE), lights), ROPE_W - thin)
	_ci.draw_polyline_colors(pts, _tinted(col[0], lights), ROPE_W - 3.0 - thin)
	if ends[e] == -1:   # em pé (na mão, solto ou guardado): o fio entra na traseira do plug
		_draw_tail(e, pts[pts.size() - 1], col[0], lights[lights.size() - 1], thin)
	var pts2 := PackedVector2Array()
	var length := 0.0
	for i in pts.size():
		pts2.append(pts[i] + Vector2(-1, -1))
		if i > 0:
			length += pts[i].distance_to(pts[i - 1])
	var at := 0.0
	var braid := BRAID * lerpf(1.0, TAUT_BRAID, taut)   # o pano esticado espaça o trançado
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
		_ci.draw_multiline_colors(segs, tones, 1.5)
	for band in HOLE_SHADE:   # perto do buraco, a sombra de dentro dele, em degraus
		var part := Cord.along(pts, band[0], band[1])
		if part.size() >= 2:
			_ci.draw_polyline(part, Color(0, 0, 0, band[2]), ROPE_W - 3.0 - thin)


## O fio entrando na traseira do plug em pé, em `at`: um trecho dele segue TAIL_IN px para dentro do plug, no eixo
## dele (o plug, desenhado depois, o cobre), e uma junta redonda fecha a dobra. Sem isso, o fio chegando de lado
## terminava num corte reto no meio da ponta do plug e deixava um vão do outro lado.
func _draw_tail(e: int, at: Vector2, c: Color, light: Color, thin: float) -> void:
	var inside := at + Vector2.UP.rotated(_plug_angle(e)) * TAIL_IN
	_ci.draw_line(at, inside, c.darkened(EDGE) * light, ROPE_W - thin)
	_ci.draw_line(at, inside, c * light, ROPE_W - 3.0 - thin)
	var w := int(ROPE_W - thin)
	PixelArt.sprite(_ci, PixelArt.disc(w, [[(w - 3) / 2.0, c], [w / 2.0, c.darkened(EDGE)]]), at, light)


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
		PixelArt.sprite(_ci, PixelArt.disc(PLUG_ABA_D + 2, [[PLUG_ABA_D / 2.0 + 1.0, Color.WHITE]]), Vector2.ZERO, SHADOW)   # sombra de contato: a aba presa no encaixe
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
			var t := PixelArt.turned(_plug_art(ang), ang, Vector2(10, PLUG_H))
			_ci.draw_set_transform(at.round())
			_ci.draw_texture(PixelArt.art(t[0], _plug_pal(_cable_col(e))), -(t[1] as Vector2), _lit_by(at))
		else:
			_draw_plug_body(_cable_col(e), true, _lit_by(at))
	_ci.draw_set_transform(Vector2.ZERO)
	if _cut < INF and not shadow:
		draw_lip(_ci, hole(e))
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
		var cut := Geometry2D.intersect_polygons(shape, PackedVector2Array([Vector2(-30, -90), Vector2(30, -90), Vector2(30, _cut), Vector2(-30, _cut)]))
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
		return Vector2(4, 5).lerp(Vector2(2, 2), _seat_pose(e)[2])
	return Vector2(8, 10) if held == e else Vector2(4, 5) if _loose.has(e) else Vector2(2, 2)


## A silhueta do plug (as mesmas partes de `_draw_plug_body`, juntas num polígono só: a sombra não escurece duas
## vezes onde elas se sobrepõem), alargada `grow` px para o destaque.
func _plug_outline(e: int, grow: float) -> PackedVector2Array:
	var seated: bool = ends[e] != -1
	var key: Variant = _tilt(int(ends[e])) if seated else false
	if not _silhouette.has(key):
		var box := func(r: Rect2) -> PackedVector2Array:
			return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		var parts := [Geometry2D.convex_hull(_circle(Vector2.ZERO, PLUG_FACE_R + 1.0) + _circle(key, PLUG_FACE_R + 1.0))] if seated else [box.call(Rect2(-9, -56, 18, 36)),
			box.call(Rect2(-8, -20, 16, 20)), box.call(Rect2(-6, -59, 12, 3)), box.call(Rect2(-4, -86, 8, 27)), box.call(Rect2(-3, -91, 6, 5)),
			box.call(Rect2(-1, -93, 2, 2))]
		var shape: PackedVector2Array = parts[0]
		for part in parts.slice(1):
			shape = Geometry2D.merge_polygons(shape, part)[0]
		_silhouette[key] = shape
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
## capa de borracha em gomos afinando até o fio (a aba dourada, mais estreita, fica escondida atrás do corpo). `lit`: a
## luz da sala ali, como no fio que sai dele. No corpo, primeiro a beira de todos (só o contorno fica à mostra) e
## depois o miolo sombreado (luz no alto à esquerda); a capa, disco a disco, mostra os sulcos (`PLUG_CAPA_ROW`).
## (Antes eram cápsulas e círculos vetoriais: embolotados.)
## O fio sai do meio da capa, por cima (desenhado depois). `push`: a assentada, o plug afunda tantos px. `j`: o
## encaixe, para a luz que bate no plug (`_plug_light`): no fim, o contorno do plug inteiro acende (`_face_rim`), só
## em cima (a lâmpada logo acima) ou em volta toda (o aro aceso do destino). (Um anel solto por cima, antes, flutuava
## sobre a capa e a luz vinha do lado; uma beira acesa por disco listrava o plug todo.)
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
				PixelArt.sprite(_ci, PixelArt.disc(r[0], [[r[0] / 2.0, pal[r[1]]]]), t * float(k) / n, mod)
			if layer != 0:
				var d: int = r[0] - 2
				var tones := [pal[r[2]], pal[r[3]], pal[r[4]]]
				PixelArt.sprite(_ci, _knurled(d, tones) if r[5] else PixelArt.disc(d, [[d / 2.0, tones[0], tones[1], tones[2]]]), t * float(k) / n, mod)
	if light[1] > 0.02:
		var rim: Array = _face_rim(t, n, light[2])
		_ci.draw_texture(rim[0], rim[1], Color((light[0] as Color).lightened(0.35), light[1] * 0.8 * alpha))


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
			if r - l + 1 < PLUG_ABA_D + 4 and row[r] == "6":   # na capa, um gomo escuro sim, outro não (só os escuros a deixavam preta)
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
		var img := PixelArt.disc(d, [[d / 2.0, tones[0], tones[1], tones[2]]]).get_image()
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
	var w := int(ROPE_W - 3.0)   # na cor e na largura do miolo do fio, sem contorno: o fio continua nela
	PixelArt.sprite(_ci, PixelArt.disc(w, [[1.0, col[1]], [w / 2.0, col[0]]]), _plug_base(e).round(), _lit_by(_plug_base(e)))


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


## O contorno aceso do plug encaixado que sai até `t` em `n` passos: a silhueta dos discos juntos (os mesmos lugares
## de `PixelArt.sprite`), e dela só os pixels da beira de cima, com o de baixo deles mais fraco, ou a beira toda
## (`around`). Devolve [textura, onde desenhar]. Guardado (enquanto o plug assenta, `t` muda a cada quadro: limitado).
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
			spots.append([p, PixelArt.disc(d, [[d / 2.0, Color.WHITE]]).get_image()])
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
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		for y in size.y:
			for x in size.x:
				if not inside.call(x, y):
					continue
				if around:
					if not (inside.call(x - 1, y) and inside.call(x + 1, y) and inside.call(x, y - 1) and inside.call(x, y + 1)):
						img.set_pixel(x, y, Color.WHITE)
				elif not inside.call(x, y - 1):
					img.set_pixel(x, y, Color.WHITE)
				elif not inside.call(x, y - 2):
					img.set_pixel(x, y, Color(1, 1, 1, 0.35))
		_face_rims[key] = [ImageTexture.create_from_image(img), lo - Vector2.ONE]
	return _face_rims[key]


## O plug de pé, com o fio saindo de baixo (y = 0), no formato de um P10 e na escala das tomadas (18 × 93 px: o corpo
## enche o buraco da prateleira e a luva de 8 entra no furo de 11 da tomada; os objetos da mesa crescem na mesma
## proporção, `Background.PROP_K`, para o plug não ficar maior que eles), em pixel art (`PLUG_ART`, no acabamento do relógio da mesa: sombreado de cilindro com o brilho
## numa coluna só e a beira escura à direita, cantos arredondados), no jeito de um plugue P10 (a referência do
## usuário): a capa de borracha em gomos, afinando até o fio; o corpo na cor do cabo (é o que identifica o cabo), com
## um anel em cima, o serrilhado em listras finas e um anel no meio; a aba dourada; a ponta de metal dourado, com a luva,
## um isolante preto, o anel, outro isolante e o bico em ponta com a bolinha. `tip`
## falso: sem a ponta (entrando no encaixe, ela já está dentro). Entrando no buraco, só até `_cut`, escurecendo liso.
func _draw_plug_body(col: Array, tip: bool = true, light := Color.WHITE) -> void:
	var top := -PLUG_H if tip else -PLUG_LEN
	var bottom := minf(0.0, _cut)
	if bottom > top:
		_ci.draw_texture_rect_region(PixelArt.art(PLUG_ART, _plug_pal(col)), Rect2(-10, top, 20, bottom - top), Rect2(0, top + PLUG_H, 20, bottom - top), light)
	if _cut < INF:   # entrando no buraco, o plug escurece até a beira dele
		var none := Color(0, 0, 0, 0)
		var deep := Color(0, 0, 0, 0.6)
		_ci.draw_primitive(PackedVector2Array([Vector2(-10, _cut - 6.0), Vector2(10, _cut - 6.0), Vector2(10, _cut), Vector2(-10, _cut)]),
			PackedColorArray([none, none, deep, deep]), PackedVector2Array())


## O mapa do plug para o ângulo `ang`: o brilho dele fica do lado esquerdo, virado para a luz (`PixelArt.LIGHT`, alto
## à esquerda); girado a ponto de esse lado ficar de costas para ela, vale o mapa espelhado, com o brilho do outro
## lado (sem isso, o plug deitado com a ponta para a esquerda tinha a luz vindo de baixo).
static var _plug_flipped: Array = []


func _plug_art(ang: float) -> Array:
	if Vector2.LEFT.rotated(ang).dot(PixelArt.LIGHT) >= 0.0:
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
			"Y": Color("ecd29a"), "y": Color("e0c07a"), "b": Color("b8924e"), "B": Color("7a5a24"), "C": Color("5a4218"), "E": Color("3a2810"),
			"K": Color("2a2622"), "k": Color("141210")}
	return _plug_pals[c]
