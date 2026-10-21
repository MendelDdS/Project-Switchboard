class_name CityMap
extends Control
## Mapa em papel da cidade, aberto sob o vidro da unidade de despacho (sem dobras): uma folha por setor (bairro), todas com a mesma grade (3 ruas horizontais e 4 verticais).
## A Vila Serena (setor 3) fica no canto; as ruas dela continuam com o mesmo nome e a numeração seguindo no Centro (a
## leste) e no Alto da Serra (ao sul), e a zona rural (do setor 2) fecha o canto que sobra. Cada trecho de 100
## números é clicável. Só aparecem as folhas dos setores atendidos, e o mapa as enquadra. A roda do mouse aproxima e
## afasta; arrastar move o mapa. Os nomes não se encostam: na ordem de prioridade (bairro, rua, lugar, numeração),
## quem não cabe fica para quando o mapa estiver mais perto.

signal segment_selected(street: String, block: int, label: String)

const SHEET := Vector2(600, 440)
## Canto de cada folha no mapa: setor -> posição (0 = zona rural, só paisagem, que faz parte do setor 2).
## Delegacia, bombeiros e hospital ficam no Centro (setor 1), em frente ao quarteirão de cada um.
const SHEETS := MapGrid.SHEETS
const SHEET_SECTOR := MapGrid.SHEET_SECTOR
const XS := MapGrid.XS
const YS := MapGrid.YS
const LM := MapGrid.LM
const STATION := {
	"pol": {"p": Vector2(780, 225)},
	"bomb": {"p": Vector2(1060, 225)},
	"amb": {"p": Vector2(920, 90)},
}
const UNIT_SPEED := 115.0   # px de mapa por segundo: do Centro à Vila Serena, cerca de 7 s
const MIN_TRIP := 3.5       # s: a viagem mais curta
const MAX_K := 1.2          # aproximação máxima (escala de desenho)
const ZOOM_STEP := 0.1      # o aumento anda em degraus (1.0, 1.1, 1.2...: os do anel do despacho, `CardMachines`)
const REVEAL_SEC := 2.5     # s: o mapa se abrindo para o bairro entregue na noite
const DISTRICT := {1: T.Key.MAP_DISTRICT_1, 2: T.Key.MAP_DISTRICT_2, 3: T.Key.MAP_DISTRICT_3}
var bottom_inset := 0.0   ## px no pé do mapa cobertos pelo que fica por cima dele (o `Dispatch` diz)
const NUMBERS_K := 0.8      # a numeração dos trechos só com o mapa perto
const LIT := [0.4, 0.8]     # o realce da rua sob o mouse: ela inteira e o trecho (a força do âmbar sobre o papel)
const PAPER := Pal.MAP_PAPER   # o papel, e as ruas são ele à mostra (como no mapa dobrado da mesa)
const ROAD := Pal.MAP_PAPER
const LINE := Pal.MAP_INK
const CITY := "SÃO SOTERO"     # o nome no selo do mapa (nome próprio: o mesmo nos três idiomas)
## As divisas entre bairros vizinhos, quando os dois aparecem: [folha, folha, de, até] (a zona rural é do Alto da Serra).
const BORDERS := [[3, 1, Vector2(600, 0), Vector2(600, 440)], [3, 2, Vector2(0, 440), Vector2(600, 440)],
	[1, 0, Vector2(600, 440), Vector2(1200, 440)]]
## O que há num quarteirão (`lots`): casa com a cumeeira deitada, casa com ela em pé (dos lados) e árvore.
enum Lot { HOUSE, HOUSE_ACROSS, TREE }
## A zona rural: o rio e as estradas de terra (que continuam as ruas vizinhas).
const RIVER := [Vector2(60, 440), Vector2(120, 380), Vector2(260, 350), Vector2(330, 250), Vector2(470, 210), Vector2(600, 160)]
const ROADS_V := [110.0, 250.0, 390.0, 530.0]
const ROADS_H := [90.0, 225.0, 360.0]

var sel: Dictionary = {}
var pend: Dictionary = {}  ## o trecho do primeiro clique, à espera do segundo para imprimir (o `Dispatch` põe)
var hover: Dictionary = {}
var _spot: Array = []      ## o lugar de referência sob o mouse, longe das ruas: [ponto do mapa, nome] (vazio = nenhum)
## Uma viagem de viatura: o caminho e quanto dele já foi, no tempo do jogo.
class Trip:
	var u: String              ## a unidade (`Fleet.IDS`)
	var pts: PackedVector2Array   ## o caminho (px do mapa), da saída à chegada
	var t := 0.0               ## segundos andados
	var dur := 0.0             ## segundos até chegar
	var back := false          ## voltando para a base

var trips: Array[Trip] = []
var _k := 0.96
var _off := Vector2.ZERO   ## mapa -> tela: tela = mapa * _k + _off
var _tf := Transform2D.IDENTITY   ## transformação em uso no desenho (os textos a seguem só na posição)
var _zoom := 1.0           ## 1 = enquadra os setores atendidos
## Retângulos (em px de tela) com botões por cima do mapa: nenhum nome é desenhado ali.
var blocked: Array[Rect2] = []
var _center := Vector2.INF ## ponto do mapa no centro da vista (INF = o centro do enquadramento)
var _press := Vector2.INF  ## onde o botão foi apertado (para separar clique de arrasto)
var _dragging := false
## Setores de antes da entrega desta noite: na primeira vez que o mapa aparece, ele sai desse enquadramento e se
## abre para o bairro novo (Main define; vazio = nada a revelar).
var pending_reveal: Array = []
var _reveal := -1.0        ## 0..1 enquanto o mapa se abre (-1 = parado)
var _before: Array = []
var _boxes: Array[Rect2] = []      ## onde já há nome neste desenho (em px de tela): o próximo não pode encostar
var _places: Array = []            ## nomes de lugares a desenhar depois das ruas: [retângulo no mapa, texto, em pé]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


static func seg_geom(s: Street, b: int) -> Array:
	var o: Vector2 = SHEETS[s.block_sector(b)]
	var lb := b % 3
	if s.horizontal:
		var x0 := 20.0 + lb * 560.0 / 3.0
		var a := o + Vector2(x0, s.pos)
		var c := o + Vector2(x0 + 560.0 / 3.0, s.pos)
		return [a, c, (a + c) / 2.0]
	var y0 := 34.0 + lb * 386.0 / 3.0
	var a2 := o + Vector2(s.pos, y0)
	var c2 := o + Vector2(s.pos, y0 + 386.0 / 3.0)
	return [a2, c2, (a2 + c2) / 2.0]


## A folha aparece no mapa (é de um setor atendido)?
static func shown(sheet: int) -> bool:
	return SHEET_SECTOR[sheet] in GameData.sectors


## As folhas dos setores atendidos (durante a revelação, a caminho delas a partir das de antes).
func _frame() -> Rect2:
	var to := frame_of(GameData.sectors)
	if _reveal < 0.0:
		return to
	var from := frame_of(_before)
	var e := smoothstep(0.0, 1.0, _reveal)
	return Rect2(from.position.lerp(to.position, e), from.size.lerp(to.size, e))


static func frame_of(sectors: Array) -> Rect2:
	var r := Rect2()
	for s in SHEETS:
		if SHEET_SECTOR[s] in sectors:
			var sr := Rect2(SHEETS[s], SHEET)
			r = sr if r.size == Vector2.ZERO else r.merge(sr)
	return r


func _fit_k() -> float:
	var f := _frame()
	var seen := _seen().size
	return minf(seen.x / f.size.x, seen.y / f.size.y)


## Escala e deslocamento da vista; o centro não sai do enquadramento.
func _view() -> void:
	var f := _frame()
	_zoom = clampf(_zoom, 1.0, _top())
	_k = _fit_k() * _zoom
	if _center == Vector2.INF:
		_center = f.get_center()
	var seen := _seen().size
	var half := seen / (2.0 * _k)
	_center = Vector2(_axis(_center.x, f.position.x, f.end.x, half.x), _axis(_center.y, f.position.y, f.end.y, half.y))
	_off = seen / 2.0 - _center * _k


## A parte do mapa à vista: acima de `bottom_inset` (a tira de papel da impressora sobe por ali; o mapa enquadrado
## inteiro acima dela, com o nome do bairro no pé da folha à vista).
func _seen() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size.x, maxf(1.0, size.y - bottom_inset)))


## Centro da vista num eixo: aproximado, anda só dentro do enquadramento; com sobra, fica no meio dele.
static func _axis(c: float, f0: float, f1: float, half: float) -> float:
	return clampf(c, f0 + half, f1 - half) if half * 2.0 <= f1 - f0 else (f0 + f1) / 2.0


func _to_map(p: Vector2) -> Vector2:
	return (p - _off) / _k


## O trecho sob o ponto `mp` do mapa. No cruzamento as duas ruas empatam: fica a que o mouse vinha seguindo (`hover`)
## até ele sair dela; antes, vencia a primeira da lista e o clique na vertical marcava a horizontal.
func _find_seg(mp: Vector2) -> Dictionary:
	var best := {}
	var bd := maxf(13.0, 8.0 / _k)   # perto da rua em px de tela, mesmo com o mapa afastado
	if not hover.is_empty():
		var h := seg_geom(GameData.street(hover["street"]), hover["block"])
		if Geometry2D.get_closest_point_to_segment(mp, h[0], h[1]).distance_to(mp) < bd:
			return hover
	for s in GameData.CONTENT.streets:
		for b in s.blocks():
			if not s.block_sector(b) in GameData.sectors:
				continue
			var g := seg_geom(s, b)
			var d := Geometry2D.get_closest_point_to_segment(mp, g[0], g[1]).distance_to(mp)
			if d < bd:
				bd = d
				best = {"street": s.id, "block": b, "label": "%s, %s" % [s.name, Street.block_label(b)]}
	return best


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		if _press != Vector2.INF and (_dragging or e.position.distance_to(_press) > 5.0):
			_dragging = true
			_center -= e.relative / _k
			mouse_default_cursor_shape = Control.CURSOR_DRAG
			queue_redraw()
			return
		var mp := _to_map(e.position)
		var h := _find_seg(mp)
		var spot := []   # o nome do lugar não cabe no telhado com o mapa afastado: a etiqueta diz qual é
		if h.is_empty():
			for pl in _places:
				if (pl[0] as Rect2).has_point(mp):
					spot = [(pl[0] as Rect2).get_center(), pl[1]]
		if h != hover or spot != _spot:
			hover = h
			_spot = spot
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not h.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
	elif e is InputEventMouseButton and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and e.pressed:
		zoom_by(1.2 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2, e.position)
		accept_event()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press = e.position
			_dragging = false
			return
		var was_drag := _dragging
		_press = Vector2.INF
		_dragging = false
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not hover.is_empty() else Control.CURSOR_ARROW
		if was_drag:
			return
		var h := _find_seg(_to_map(e.position))   # o destacado, se o mouse ainda está nele
		if not h.is_empty():
			Sfx.play("click")
			segment_selected.emit(h["street"], h["block"], h["label"])   # (o `Dispatch` marca `pend` ou `sel`)
			queue_redraw()


## Aproxima (`f` > 1) ou afasta o mapa `f` vezes, no degrau mais perto (ao menos um), com o ponto `at` da tela
## parado (a roda do mouse, ali; o + e o − do anel, no meio da vista).
func zoom_by(f: float, at := Vector2.INF) -> void:
	var to := snappedf(_zoom * f, ZOOM_STEP)
	if is_equal_approx(to, _zoom):
		to = _zoom + signf(f - 1.0) * ZOOM_STEP
	_zoom_to(to, at)


## `n` degraus do aumento (o anel girado), no meio da vista.
func zoom_step(n: int) -> void:
	_zoom_to(snappedf(_zoom + n * ZOOM_STEP, ZOOM_STEP), Vector2.INF)


func _zoom_to(to: float, at: Vector2) -> void:
	if at == Vector2.INF:
		at = _seen().get_center()
	var p := _to_map(at)
	_zoom = to
	_view()
	_center += p - _to_map(at)
	queue_redraw()


## O aumento máximo, no degrau abaixo do limite da escala (`MAX_K`).
func _top() -> float:
	return maxf(1.0, floorf(MAX_K / _fit_k() / ZOOM_STEP + 0.001) * ZOOM_STEP)


## O aumento do mapa: 1 enquadrado (o mostrador do anel, `CardMachines`).
func magnification() -> float:
	return _zoom


## Quanto o mapa está aproximado, de 0 (enquadrado) a 1 (o máximo).
func zoom_level() -> float:
	var top := _top()
	return 0.0 if top <= 1.0 else clampf(log(_zoom) / log(top), 0.0, 1.0)


func route(u: String, target: Dictionary) -> PackedVector2Array:
	var st: Vector2 = STATION[Fleet.kind(u)]["p"]   # a de reserva sai da mesma base
	var s := GameData.street(target["street"])
	var g := seg_geom(s, target["block"])
	var m: Vector2 = g[2]
	if s.horizontal:
		if is_equal_approx(m.y, st.y):
			return PackedVector2Array([st, m])
		# por uma rua vertical (todas atravessam o mapa de cima a baixo), a mais perto do meio do caminho
		var mid := (st.x + m.x) / 2.0
		var xv := 0.0
		var best := INF
		for o in [0.0, 600.0]:
			for v in [110.0, 250.0, 390.0, 530.0]:
				if absf(o + v - mid) < best:
					best = absf(o + v - mid)
					xv = o + v
		return PackedVector2Array([st, Vector2(xv, st.y), Vector2(xv, m.y), m])
	return PackedVector2Array([st, Vector2(m.x, st.y), m])


## A unidade sai da base para o trecho; devolve quantos segundos leva para chegar (pela distância).
func trip(u: String, target: Dictionary) -> float:
	var pts := route(u, target)
	var dist := 0.0
	for i in range(1, pts.size()):
		dist += pts[i].distance_to(pts[i - 1])
	var sec := maxf(MIN_TRIP, dist / UNIT_SPEED)
	trips = trips.filter(func(t: Trip): return t.u != u)
	var tr := Trip.new()
	tr.u = u
	tr.pts = pts
	tr.dur = sec
	trips.append(tr)
	return sec


## A unidade volta do lugar onde está para a base, pelo mesmo caminho; devolve quantos segundos leva. (As viaturas
## não aparecem no mapa: de papel sob o vidro, ele não mostra nada andando; a viagem só conta o tempo.)
func go_home(u: String) -> float:
	for tr in trips:
		if tr.u == u:
			tr.pts.reverse()
			tr.t = 0.0
			tr.back = true
			return tr.dur
	return 0.0


func remove_units(us: Array) -> void:
	trips = trips.filter(func(t: Trip): return not (t.u in us))
	queue_redraw()


func _process(d: float) -> void:
	if _reveal >= 0.0:
		_reveal += d / REVEAL_SEC
		_center = Vector2.INF   # acompanha o enquadramento enquanto ele abre
		if _reveal >= 1.0:
			_reveal = -1.0
		queue_redraw()
	for tr in trips:   # no tempo do jogo: para na pausa e acompanha a velocidade
		tr.t = minf(tr.t + d, tr.dur)


func _width(txt: String, sz: int) -> float:
	return Pal.ui.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x


## Texto no ponto p do mapa (linha de base), em `sz` px de tela: o mapa é desenhado em escala (`_k`), mas fonte de
## pixel escalada borra, então o texto acompanha só a posição e sai num tamanho nítido de `Pal.ui`.
func _t(p: Vector2, txt: String, sz: int, col: Color = LINE) -> void:
	draw_set_transform((_tf * p).round())
	draw_string(Pal.ui, Vector2(-roundf(_width(txt, sz) / 2.0), 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_set_transform_matrix(_tf)


## Nome centrado no ponto p do mapa (linha de base), em pé se `up`, com fundo `bg` (transparente = sem): só se couber
## inteiro na vista e não encostar num nome já desenhado (`_boxes`; `over`, por cima deles). Devolve se desenhou.
func _label(p: Vector2, txt: String, sz: int, col: Color = LINE, bg := Color.TRANSPARENT, up := false, over := false) -> bool:
	var w := _width(txt, sz)
	var at := (_tf * p).round()
	var box := Rect2(at.x - sz * 0.8, at.y - w / 2.0 - 1, sz + 2, w + 2) if up else Rect2(at.x - w / 2.0 - 1, at.y - sz * 0.8, w + 2, sz + 2)
	if not _seen().encloses(box) or not over and _boxes.any(func(b: Rect2): return b.intersects(box)):
		return false
	_boxes.append(box)
	draw_set_transform(Vector2.ZERO)
	if bg.a > 0.0:
		draw_rect(box, bg)
	draw_set_transform(at, -PI / 2.0 if up else 0.0)
	draw_string(Pal.ui, Vector2(-roundf(w / 2.0), 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_set_transform_matrix(_tf)
	return true


## Muda a transformação do desenho (e a que os textos seguem).
func _use(xf: Transform2D) -> void:
	_tf = xf
	draw_set_transform_matrix(xf)


func _draw() -> void:
	_view()
	var seal := Rect2(_seen().end - Vector2(124, 40), Vector2(118, 34))   # o selo, no canto da vista: nenhum nome embaixo dele
	_boxes = blocked.duplicate()
	_boxes.append(seal)
	_places.clear()
	var xf := Transform2D(0.0, Vector2(_k, _k), 0.0, _off)
	draw_rect(Rect2(Vector2.ZERO, size), Pal.INK_SOFT)
	for s in SHEETS:
		if not shown(s):
			continue
		_use(xf * Transform2D(0.0, SHEETS[s]))
		draw_rect(Rect2(Vector2.ZERO, SHEET), PAPER)
		if s == 0:
			_draw_rural()
		else:
			_draw_blocks(s)
	_use(xf)   # (as ruas são o papel entre os quarteirões: continuam de uma folha para a outra sozinhas)
	for seg in BORDERS:
		if not (shown(seg[0]) and shown(seg[1])):
			continue
		var n := int(seg[2].distance_to(seg[3]) / 24.0)
		for i in n:
			draw_line(seg[2].lerp(seg[3], float(i) / n), seg[2].lerp(seg[3], (i + 0.5) / n), Color(LINE, 0.5), 3.0)
	# realce e seleção (a faixa de papel do nome da rua sob o mouse tem o realce dela, `_road_of`, senão o tapava)
	if not hover.is_empty():
		var hs := GameData.street(hover["street"])
		for b in hs.blocks():
			if shown(hs.block_sector(b)):
				var g := seg_geom(hs, b)
				draw_line(g[0], g[1], _road_of(hs, b), 16.0)
	# o local impresso: tracejado cheio e o quadradinho; o do primeiro clique, à espera do segundo: tracejado ralo e
	# o quadradinho vazado (ainda não é cartão). O tracejado fica embaixo dos nomes, com ao menos 3 px de tela; o
	# quadradinho, por cima (o nome no meio do trecho o tapava), em tamanho de tela (afastado, sumia)
	for at: Dictionary in [sel, pend]:
		if not at.is_empty():
			var g := seg_geom(GameData.street(at["street"]), at["block"])
			var a: Vector2 = g[0]
			var b: Vector2 = g[1]
			var n := int(a.distance_to(b) / 15.0)
			var dash := 0.66 if at == sel else 0.4
			for i in n:
				draw_line(a.lerp(b, float(i) / n), a.lerp(b, (i + dash) / n), Pal.MAP_MARK, maxf(7.0 if at == sel else 5.0, 3.0 / _k))
	_draw_names()
	draw_set_transform(Vector2.ZERO)
	for at: Dictionary in [sel, pend]:
		if not at.is_empty():
			var m := (_tf * (seg_geom(GameData.street(at["street"]), at["block"])[2] as Vector2)).round()
			draw_rect(Rect2(m - Vector2(6, 6), Vector2(12, 12)), Color.BLACK)
			draw_rect(Rect2(m - Vector2(4, 4), Vector2(8, 8)), Pal.MAP_MARK if at == sel else PAPER)
	draw_set_transform_matrix(_tf)
	if not hover.is_empty():
		_draw_spans()
	if _reveal >= 0.0:   # o bairro entregue aparece aos poucos
		for s in SHEETS:
			if shown(s) and not SHEET_SECTOR[s] in _before:
				draw_rect(Rect2(SHEETS[s], SHEET), Color(Pal.INK_SOFT, 1.0 - smoothstep(0.0, 1.0, _reveal)))
	_use(Transform2D.IDENTITY)
	# o selo (o mesmo do mapa da mesa): a moldura vermelha, a rosa dos ventos e o nome da cidade
	draw_rect(seal, Pal.SEAL)
	draw_rect(seal.grow(-2), PAPER)
	draw_rect(seal.grow(-4), Pal.SEAL, false, 1.0)
	var cp := seal.position + Vector2(18, 0)
	_t(cp + Vector2(0, 16), "N", 11)
	draw_colored_polygon(PackedVector2Array([cp + Vector2(0, 18), cp + Vector2(-6, 28), cp + Vector2(6, 28)]), LINE)
	_t(seal.position + Vector2(72, 22), CITY, 11)
	_use(xf)
	if not hover.is_empty():
		var st := GameData.street(hover["street"])   # na vertical, ao lado: em cima tapava o trecho e o número dele
		_tag(seg_geom(st, hover["block"])[2], hover["label"], not st.horizontal, T.text(T.Key.MAP_CLICK_AGAIN) if hover == pend else "")
	elif not _spot.is_empty():
		_tag(_spot[0], _spot[1])


## A cor da rua `st` no trecho `b`: o papel, ou o realce se ela está sob o mouse (inteira de leve, o trecho forte).
func _road_of(st: Street, b: int) -> Color:
	if hover.is_empty() or hover["street"] != st.id:
		return ROAD
	return ROAD.lerp(Pal.AMBER, LIT[1] if b == hover["block"] else LIT[0])


## A cor da rua `st` no ponto `p` do mapa (o fundo do nome dela ali).
func _road_at(st: Street, p: Vector2) -> Color:
	var b := 0
	var best := INF
	for i in st.blocks():
		var g := seg_geom(st, i)
		var dd := Geometry2D.get_closest_point_to_segment(p, g[0], g[1]).distance_to(p)
		if dd < best:
			best = dd
			b = i
	return _road_of(st, b)


## A numeração de cada trecho da rua sob o mouse ("200–299": o trecho começa no meio de um quarteirão; sem isso, só
## aproximando bem se via onde ficava o 260), na beira da rua (em cima dela tapava os nomes), no ponto do trecho mais
## perto do meio que não encoste em nome nenhum; sem nenhum, por cima. O do trecho sob o mouse está na etiqueta.
func _draw_spans() -> void:
	var st := GameData.street(hover["street"])
	for b in st.blocks():
		if b == hover["block"] or not shown(st.block_sector(b)):
			continue
		var g := seg_geom(st, b)
		var txt := Street.block_label(b)
		var sides := [Vector2(0, 17), Vector2(0, -8)] if st.horizontal else [Vector2(_width(txt, 11) / 2.0 + 7, 5), Vector2(-_width(txt, 11) / 2.0 - 7, 5)]
		var paper := _frame().grow_individual(-(_width(txt, 11) / 2.0 + 2) / _k, -12 / _k, -(_width(txt, 11) / 2.0 + 2) / _k, -4 / _k)
		if not paper.has_area():   # (o mapa ainda sem tamanho, antes do primeiro arranjo)
			continue
		var spots := []   # (dentro do papel: a vista vai até a moldura)
		for t: float in [0.5, 0.35, 0.65, 0.2, 0.8, 0.1, 0.9]:
			for sd: Vector2 in sides:
				var q: Vector2 = (g[0] as Vector2).lerp(g[1], t) + sd / _k
				if paper.has_point(q):
					spots.append(q)
		if spots.is_empty():
			continue
		if not spots.any(func(q: Vector2): return _label(q, txt, 11, LINE, Pal.MAP_TAG)):
			_label(spots[0], txt, 11, LINE, Pal.MAP_TAG, false, true)   # só enquanto o mouse está na rua: por cima, se preciso


## Folhas (que aparecem) por onde a rua passa.
func _sheets_of(st: Street) -> Array:
	return [st.sector, st.continues].filter(func(s): return s != 0 and shown(s))


## Nomes, na ordem de prioridade: bairros, ruas, lugares e a numeração dos trechos. As ruas desde o mapa afastado
## (antes só os bairros: achar a rua pedida era passar o mouse em cada uma); as horizontais primeiro (`_street_name`
## as põe alternando os lados e deixa colunas para as verticais).
func _draw_names() -> void:
	for s in SHEETS:
		if s != 0 and shown(s):
			_label(SHEETS[s] + Vector2(300, 433), T.text(DISTRICT[s]).to_upper(), 11, Pal.INK_SOFT, PAPER)
	if shown(0):
		_label(SHEETS[0] + Vector2(320, 300), T.text(T.Key.MAP_RURAL), 11, Pal.INK_SOFT)
	for turn in 2:   # cada rua primeiro no bairro onde começa; depois, se couber, na folha para onde continua
		for up in [false, true]:
			for st in GameData.CONTENT.streets:
				var sheet: int = [st.sector, st.continues][turn]
				if st.horizontal != up and sheet != 0 and shown(sheet):
					_street_name(SHEETS[sheet], st)
	for pl in _places:
		_place_name(pl[0], pl[1], pl[2])
	if _k < NUMBERS_K:
		return
	for st in GameData.CONTENT.streets:
		for b in range(1, st.blocks()):
			if not shown(st.block_sector(b)):
				continue
			var p0: Vector2 = seg_geom(st, b)[0]
			if st.horizontal:
				_label(p0 + Vector2(16, 22), str(b * 100), 11, Pal.INK_SOFT, PAPER)
			else:
				_label(p0 + Vector2(-13, 26), str(b * 100), 11, Pal.INK_SOFT, PAPER, true)   # na beira da quadra


## Nome da rua ao longo dela (as verticais em pé, como nos aplicativos de mapa), no meio de um trecho entre dois
## cruzamentos: o primeiro trecho à vista em que caiba inteiro (os compridos primeiro), senão abreviado ("R. do Sol",
## "Av. Brasil"); com o mapa afastado, o abreviado (ou só o nome, "Tiradentes") passa pelos cruzamentos, em qualquer
## ponto da folha, para fugir dos nomes já postos. Sem lugar (fora da vista ou encostando noutro nome), fica para a
## etiqueta do mouse.
func _street_name(o: Vector2, st: Street) -> void:
	var short := st.name.replace("Rua ", "R. ").replace("Avenida ", "Av. ")
	var cuts: Array = XS if st.horizontal else YS   # onde as ruas do outro sentido a cruzam
	for txt in [st.name, short]:
		for i in ([1, 2, 3, 0, 4] if st.horizontal else [1, 2, 0, 3]):
			var a: float = cuts[i]
			var b: float = cuts[i + 1]
			var mid := Vector2((a + b) / 2.0, st.pos + 5) if st.horizontal else Vector2(st.pos + 5, (a + b) / 2.0)
			if _width(txt, 11) + 12.0 <= (b - a) * _k and _label(o + mid, txt, 11, LINE, _road_at(st, o + mid), not st.horizontal):
				return
	var bare := short.trim_prefix("R. ").trim_prefix("Av. ").trim_prefix("das ").trim_prefix("da ").trim_prefix("dos ").trim_prefix("do ")
	# as verticais do meio para as pontas; as horizontais de um lado, alternando (a 1ª e a 3ª à esquerda, a do meio à
	# direita), para deixar colunas livres para os nomes das verticais (no meio, as três tapavam as mesmas duas)
	var c: float = (cuts[0] + cuts[-1]) / 2.0
	var spots := []
	for d in range(0, int(cuts[-1] - c), 10):
		spots.append_array([c - d, c + d])
	if st.horizontal:
		spots.sort()
		if ROADS_H.find(st.pos) == 1:
			spots.reverse()
	var end: float = SHEET.x if st.horizontal else SHEET.y
	for txt in [short, bare]:
		var half := (_width(txt, 11) / 2.0 + 2.0) / _k   # o nome não sai da folha do bairro
		for at: float in spots:
			var p := o + (Vector2(at, st.pos + 5) if st.horizontal else Vector2(st.pos + 5, at))
			if at - half >= 0.0 and at + half <= end and _label(p, txt, 11, LINE, _road_at(st, p), not st.horizontal):
				return


## Nome do lugar dentro de `r` (coordenadas do mapa: o telhado do prédio, a faixa da praça), com 1 px livre de cada
## lado (a largura do texto já traz 1 px de ar depois da última letra): numa linha, em duas ("Hotel / Estrela") ou em
## pé no prédio estreito; se não couber, só aproximando.
func _place_name(r: Rect2, txt: String, up: bool) -> void:
	var c := r.get_center()
	if up:
		if _width(txt, 11) <= r.size.y * _k - 1:
			_label(c + Vector2(5, 0), txt, 11, LINE, Color.TRANSPARENT, true)
		return
	var room := r.size.x * _k - 1
	if _width(txt, 11) <= room:
		_label(c + Vector2(0, 6), txt, 11)
		return
	var half := txt.length() / 2
	var cut := txt.find(" ", half)
	var back := txt.rfind(" ", half)
	if cut == -1 or back != -1 and half - back < cut - half:
		cut = back
	if cut == -1:
		return
	var a := txt.left(cut)
	var b := txt.substr(cut + 1)
	if maxf(_width(a, 11), _width(b, 11)) <= room and 40.0 <= r.size.y * _k:
		if _label(c + Vector2(0, -3 / _k), a, 11):
			_label(c + Vector2(0, 17 / _k), b, 11)


## Quarteirões de uma folha (coordenadas da folha), no tom do bairro (`Pal.MAP_TINTS`, os do mapa dobrado da mesa),
## com a beira mais escura (as ruas são o papel entre eles): as casas em volta, de frente para as ruas (`_houses`), os
## lugares (`LM`) num prédio só, de telhado de barro, e a praça verde, com os caminhos, as árvores e o coreto. Os nomes
## dos lugares ficam para depois das ruas (`_places`). O mapa da mesa (`Background._art_map`) é este em miniatura.
func _draw_blocks(sector: int) -> void:
	var o: Vector2 = SHEETS[sector]
	var tint: Color = Pal.MAP_TINTS[SHEET_SECTOR[sector]]
	for ci in 5:
		for ri in 4:
			var r := block_rect(ci, ri)
			var lm: int = LM.get(sector, {}).get("%d,%d" % [ci, ri], -1)
			draw_rect(r, tint.darkened(0.3))
			draw_rect(r.grow(-2), Pal.MAP_PLAZA if lm == T.Key.MAP_SQUARE else tint)
			if lm == T.Key.MAP_SQUARE:
				_draw_square(r.grow(-2))
				_places.append([Rect2(o.x + r.position.x + 4, o.y + r.end.y - 30, r.size.x - 8, 30), T.text(lm), false])
			elif lm != -1:   # o lugar: um prédio só, de duas águas como as casas, com o terreno em volta
				var b := r.grow(-8)
				draw_rect(b, LINE)
				draw_rect(b.grow(-2), Pal.MAP_LANDMARK)
				var lit := Rect2(b.position + Vector2(2, 2), (b.size - Vector2(4, 4)) * (Vector2(1, 0.5) if b.size.x >= b.size.y else Vector2(0.5, 1)))
				draw_rect(lit.abs(), Pal.MAP_LANDMARK.lightened(0.12))
				_places.append([Rect2(o + b.position, b.size).grow(-2), T.text(lm), r.size.x < 60])   # no telhado: medido no quarteirão, vazava do prédio
			else:
				_houses(r.grow(-4), sector * 31 + ci * 7 + ri * 3, tint)


## O quarteirão da coluna `ci` e da linha `ri` da grade de uma folha (coordenadas da folha), sem a calçada.
static func block_rect(ci: int, ri: int) -> Rect2:
	var x0: float = XS[ci] + (11.0 if ci > 0 else 4.0)
	var x1: float = XS[ci + 1] - (11.0 if ci < 4 else 4.0)
	var y0: float = 40.0 if ri == 0 else YS[ri] + 11.0
	var y1: float = YS[ri + 1] - (11.0 if ri < 3 else 4.0)
	return Rect2(x0, y0, x1 - x0, y1 - y0)


## As casas de um quarteirão (`r`, dentro da beira), no telhado de duas águas, a metade de cima (ou da esquerda) na
## luz; as árvores dos quintais com `_tree`.
func _houses(r: Rect2, seed: int, tint: Color) -> void:
	var roof := tint.darkened(0.22)
	for lot: Array in lots(r, seed):
		var h: Rect2 = lot[0]
		if lot[1] == Lot.TREE:
			_tree(h.position)
			continue
		draw_rect(h, roof)
		var half := Vector2(floorf(h.size.x / 2.0), h.size.y) if lot[1] == Lot.HOUSE_ACROSS else Vector2(h.size.x, floorf(h.size.y / 2.0))
		draw_rect(Rect2(h.position, half), roof.lightened(0.1))


## O que há num quarteirão (`r`, dentro da beira), sempre o mesmo por `seed`: [retângulo, `Lot`]. Em volta dele, as
## casas de frente para as ruas, cada uma de uma largura, com um terreno vazio de vez em quando; no meio, os quintais,
## com uma árvore (8 de lado) ou outra. O mapa aberto e o da mesa desenham as mesmas.
static func lots(r: Rect2, seed: int) -> Array:
	var out := []
	var d := minf(14.0, floorf((r.size.y - 4.0) / 2.0))
	for side in 2:   # em cima e embaixo
		var y := r.position.y if side == 0 else r.end.y - d
		var x := r.position.x
		var i := 0
		while x < r.end.x - 4.0:
			var w := minf(10.0 + float((seed * 31 + side * 17 + i * 13) % 13), r.end.x - x)
			if (seed + i * 7 + side) % 9 != 0:
				out.append([Rect2(x, y, w, d), Lot.HOUSE])
			x += w + 2.0
			i += 1
	if r.size.x > d * 2.0 + 8.0 and r.size.y > d * 2.0 + 14.0:   # dos lados, entre as de cima e as de baixo
		for side in 2:
			var x := r.position.x if side == 0 else r.end.x - d
			var y := r.position.y + d + 2.0
			var i := 0
			while y < r.end.y - d - 6.0:
				var h := minf(10.0 + float((seed * 13 + side * 29 + i * 11) % 11), r.end.y - d - 2.0 - y)
				if (seed + i * 5 + side) % 7 != 0:
					out.append([Rect2(x, y, d, h), Lot.HOUSE_ACROSS])
				y += h + 2.0
				i += 1
	var yard := r.grow(-d - 4.0)
	if yard.size.x > 16.0 and yard.size.y > 16.0:   # as árvores dos quintais
		for t in 1 + seed % 3:
			var p := yard.position + Vector2(float((seed * 17 + t * 41) % int(yard.size.x - 8.0)), float((seed * 23 + t * 29) % int(yard.size.y - 8.0)))
			out.append([Rect2(p, Vector2(8, 8)), Lot.TREE])
	return out


## Uma árvore vista de cima (8 de lado): a copa escura com a luz no alto à esquerda.
func _tree(p: Vector2) -> void:
	draw_rect(Rect2(p, Vector2(8, 8)), Pal.MAP_TREE)
	draw_rect(Rect2(p, Vector2(4, 4)), Pal.MAP_TREE.lightened(0.25))


## A praça (`r`, dentro da beira): os caminhos no papel, em cruz e nas diagonais (`square_paths`), as árvores entre
## eles (`square_trees`) e o coreto no meio.
func _draw_square(r: Rect2) -> void:
	var c := r.get_center()
	for seg: Array in square_paths(r):
		draw_line(seg[0], seg[1], PAPER, 4.0)
	for p: Vector2 in square_trees(r):
		_tree(p)
	draw_rect(Rect2(c.x - 14, c.y - 12, 28, 24), LINE)   # o coreto
	draw_rect(Rect2(c.x - 12, c.y - 10, 24, 20), Pal.MAP_BANDSTAND)
	draw_rect(Rect2(c.x - 2, c.y - 24, 4, 14), LINE)
	draw_rect(Rect2(c.x - 6, c.y - 20, 12, 4), LINE)


## Os caminhos da praça `r`: [de, até], em cruz e nas diagonais.
static func square_paths(r: Rect2) -> Array:
	var c := r.get_center()
	return [[r.position, r.end], [Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y)],
		[Vector2(c.x, r.position.y), Vector2(c.x, r.end.y)], [Vector2(r.position.x, c.y), Vector2(r.end.x, c.y)]]


## As árvores da praça `r` (o canto de cima à esquerda de cada uma): duas em cada canto, longe dos caminhos.
static func square_trees(r: Rect2) -> Array:
	var c := r.get_center()
	var out := []
	for q in 4:
		var corner := Vector2(r.position.x if q % 2 == 0 else r.end.x, r.position.y if q < 2 else r.end.y)
		var into := (c - corner).sign()
		for t in 2:
			var off := Vector2(r.size.x * (0.3 if t == 0 else 0.12), r.size.y * (0.12 if t == 0 else 0.3))
			out.append(corner + into * off - Vector2(4, 4))
	return out


## Zona rural (folha sem setor): roças entre as estradas de terra (que continuam as ruas vizinhas) e um rio.
func _draw_rural() -> void:
	for ci in 5:
		for ri in 4:
			var f := field_rect(ci, ri)
			var k := (ci + ri) % 2
			draw_rect(f, Pal.MAP_FIELDS[k])
			var yy := f.position.y + 6
			while yy < f.end.y - 4:
				draw_line(Vector2(f.position.x + 4, yy), Vector2(f.end.x - 4, yy), Pal.MAP_FURROWS[k], 2.0)
				yy += 10
	draw_polyline(PackedVector2Array(RIVER), Pal.MAP_RIVER, 12.0)
	for v in ROADS_V:
		draw_line(Vector2(v, 0), Vector2(v, 440), Pal.MAP_DIRT, 10.0)
	for h in ROADS_H:
		draw_line(Vector2(0, h), Vector2(600, h), Pal.MAP_DIRT, 10.0)


## A roça da coluna `ci` e da linha `ri` da zona rural (coordenadas da folha).
static func field_rect(ci: int, ri: int) -> Rect2:
	var p := Vector2(XS[ci] + 8.0, (YS[ri] if ri > 0 else 0.0) + 8.0)
	return Rect2(p, Vector2(XS[ci + 1] - 8.0, YS[ri + 1] - 8.0) - p)


## Etiqueta de papel com o nome e a faixa de números do trecho sob o mouse ("Rua do Sol, 1–99"): mostra onde fica
## o número que a pessoa disse antes de clicar. Em tamanho de tela, acima do trecho, sem sair do mapa. `hint`, na fonte
## miúda embaixo do nome, em vermelho (o trecho do primeiro clique: "clique de novo para imprimir").
func _tag(p: Vector2, txt: String, beside := false, hint := "") -> void:
	var tip := PixelArt.tiny(hint) if hint != "" else null
	var w := maxf(_width(txt, 11), 0.0 if tip == null else tip.get_width())
	var h := 20.0 if tip == null else 28.0
	var at := (_tf * p).round() + (Vector2(14, -10) if beside else Vector2(-roundf(w / 2.0) - 5, 6 - h - 20))
	if beside and at.x + w + 12 > _seen().end.x:   # sem lugar à direita, à esquerda da rua
		at.x -= w + 38
	at = Vector2(clampf(at.x, 2, _seen().end.x - w - 12), maxf(at.y, 2))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(at, Vector2(w + 10, h)), LINE)
	draw_rect(Rect2(at + Vector2.ONE, Vector2(w + 8, h - 2)), Pal.MAP_TAG)
	draw_string(Pal.ui, at + Vector2(5, 15), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LINE)
	if tip != null:
		draw_texture(tip, at + Vector2(5, 19), Pal.MAP_MARK)
	draw_set_transform_matrix(_tf)


## Tira a marcação do trecho (o despacho limpa depois de enviar).
func clear_selection() -> void:
	sel = {}
	pend = {}
	queue_redraw()


## O idioma mudou nas configurações: redesenha os textos. O mouse saiu do mapa: some o realce e a etiqueta.
## O mapa apareceu pela primeira vez na noite de entrega de um setor: abre para o bairro novo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT and not (hover.is_empty() and _spot.is_empty()):
		hover = {}
		_spot = []
		queue_redraw()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and not pending_reveal.is_empty():
		_before = pending_reveal
		pending_reveal = []
		_reveal = 0.0
		_zoom = 1.0
