class_name CityMap
extends Control
## Mapa em papel da cidade: uma folha por setor (bairro), todas com a mesma grade (3 ruas horizontais e 4 verticais).
## A Vila Serena (setor 3) fica no canto; as ruas dela continuam com o mesmo nome e a numeração seguindo no Centro (a
## leste) e no Alto da Serra (ao sul), e a zona rural (do setor 2) fecha o canto que sobra. Cada trecho de 100
## números é clicável. Só aparecem as folhas dos setores atendidos, e o mapa as enquadra. A roda do mouse aproxima e
## afasta; arrastar move o mapa. Os nomes não se encostam: na ordem de prioridade (bairro, rua, lugar, numeração),
## quem não cabe fica para quando o mapa estiver mais perto.

signal segment_selected(street: String, block: int, label: String)

const SHEET := Vector2(600, 440)
## Canto de cada folha no mapa: setor -> posição (0 = zona rural, só paisagem, que faz parte do setor 2).
const SHEETS := {3: Vector2(0, 0), 1: Vector2(600, 0), 2: Vector2(0, 440), 0: Vector2(600, 440)}
const SHEET_SECTOR := {0: 2, 1: 1, 2: 2, 3: 3}
const XS := [20.0, 110.0, 250.0, 390.0, 530.0, 580.0]   # grade de cada folha (as ruas ficam nos valores do meio)
const YS := [34.0, 90.0, 225.0, 360.0, 420.0]
## Lugares de cada folha, no quarteirão "coluna,linha" da grade (perto do endereço deles na lista).
const LM := {
	1: {"2,1": T.Key.MAP_SQUARE, "1,1": T.Key.MAP_CITY_HALL, "3,1": T.Key.MAP_POST_OFFICE, "2,0": T.Key.MAP_HOSPITAL,
		"1,2": T.Key.MAP_POLICE, "3,2": T.Key.MAP_FIRE_STATION, "4,1": T.Key.MAP_PHARMACY, "4,2": T.Key.MAP_BUS_STATION,
		"2,3": T.Key.MAP_BAKERY},
	2: {"1,0": T.Key.MAP_CLINIC, "3,0": T.Key.MAP_SCHOOL, "2,1": T.Key.MAP_BARBER, "1,2": T.Key.MAP_GROCERY,
		"3,2": T.Key.MAP_WAREHOUSE},
	3: {"4,0": T.Key.MAP_SAWMILL, "3,0": T.Key.MAP_GARAGE, "0,1": T.Key.MAP_HOTEL, "2,1": T.Key.MAP_BAR,
		"3,1": T.Key.MAP_RADIO, "0,2": T.Key.MAP_CINEMA, "2,3": T.Key.MAP_GAS_STATION, "3,3": T.Key.MAP_FUNERAL},
}
## Delegacia, bombeiros e hospital ficam no Centro (setor 1), em frente ao quarteirão de cada um.
const STATION := {
	"pol": {"p": Vector2(780, 225), "c": Color("2d4f8a"), "l": Color("4e86e0")},
	"bomb": {"p": Vector2(1060, 225), "c": Color("b8321f"), "l": Color("e04e3a")},
	"amb": {"p": Vector2(920, 90), "c": Color("f4f0e4"), "l": Color("e04e3a")},
}
const UNIT_SPEED := 115.0   # px de mapa por segundo: do Centro à Vila Serena, cerca de 7 s
const MIN_TRIP := 3.5       # s: a viagem mais curta
const MAX_K := 1.2          # aproximação máxima (escala de desenho)
const REVEAL_SEC := 2.5     # s: o mapa se abrindo para o bairro entregue na noite
const DISTRICT := {1: T.Key.MAP_DISTRICT_1, 2: T.Key.MAP_DISTRICT_2, 3: T.Key.MAP_DISTRICT_3}
const NAMES_K := 0.42       # abaixo desta escala, só os nomes dos bairros (a etiqueta do mouse diz a rua)
const NUMBERS_K := 0.8      # a numeração dos trechos só com o mapa perto
const PAPER := Color("cfc199")
const ROAD := Color("e8dcb9")
const LINE := Color("3a3226")

var sel: Dictionary = {}
var hover: Dictionary = {}
var trips: Array = []
var _k := 0.96
var _off := Vector2.ZERO   ## mapa -> tela: tela = mapa * _k + _off
var _tf := Transform2D.IDENTITY   ## transformação em uso no desenho (os textos a seguem só na posição)
var _zoom := 1.0           ## 1 = enquadra os setores atendidos
## Quantos px da direita estão cobertos (a ficha de despacho por cima): a escala continua a da área toda, mas o centro,
## os nomes e a rosa dos ventos ficam na parte à vista, e dá para arrastar o pedaço coberto para ela.
var cover := 0.0:
	set(v):
		if _center != Vector2.INF:   # o mapa não pula: o que está na tela fica onde está
			_center.x -= (v - cover) / (2.0 * _k)
		cover = v
		queue_redraw()
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
	var to := _frame_of(GameData.sectors)
	if _reveal < 0.0:
		return to
	var from := _frame_of(_before)
	var e := smoothstep(0.0, 1.0, _reveal)
	return Rect2(from.position.lerp(to.position, e), from.size.lerp(to.size, e))


static func _frame_of(sectors: Array) -> Rect2:
	var r := Rect2()
	for s in SHEETS:
		if SHEET_SECTOR[s] in sectors:
			var sr := Rect2(SHEETS[s], SHEET)
			r = sr if r.size == Vector2.ZERO else r.merge(sr)
	return r


func _fit_k() -> float:
	var f := _frame()
	return minf(size.x / f.size.x, size.y / f.size.y)


## Escala e deslocamento da vista; o centro não sai do enquadramento.
func _view() -> void:
	var f := _frame()
	_zoom = clampf(_zoom, 1.0, maxf(1.0, MAX_K / _fit_k()))
	_k = _fit_k() * _zoom
	if _center == Vector2.INF:
		_center = f.get_center()
	var seen := _seen().size
	var half := seen / (2.0 * _k)
	_center = Vector2(_axis(_center.x, f.position.x, f.end.x, half.x), _axis(_center.y, f.position.y, f.end.y, half.y))
	_off = seen / 2.0 - _center * _k


## A parte do mapa à vista (sem o pedaço coberto pela ficha).
func _seen() -> Rect2:
	return Rect2(0, 0, maxf(1.0, size.x - cover), size.y)


## Centro da vista num eixo: aproximado, anda só dentro do enquadramento; com sobra, fica no meio dele.
static func _axis(c: float, f0: float, f1: float, half: float) -> float:
	return clampf(c, f0 + half, f1 - half) if half * 2.0 <= f1 - f0 else (f0 + f1) / 2.0


func _to_map(p: Vector2) -> Vector2:
	return (p - _off) / _k


func _find_seg(mp: Vector2) -> Dictionary:
	var best := {}
	var bd := maxf(13.0, 8.0 / _k)   # perto da rua em px de tela, mesmo com o mapa afastado
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
		var h := _find_seg(_to_map(e.position))
		if h != hover:
			hover = h
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not h.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
	elif e is InputEventMouseButton and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and e.pressed:
		var at := _to_map(e.position)   # o ponto sob o mouse fica parado
		_zoom *= 1.2 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2
		_view()
		_center += at - _to_map(e.position)
		queue_redraw()
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
		var h := _find_seg(_to_map(e.position))
		if not h.is_empty():
			sel = h
			Sfx.play("click")
			segment_selected.emit(h["street"], h["block"], h["label"])
			queue_redraw()


func route(u: String, target: Dictionary) -> PackedVector2Array:
	var st: Vector2 = STATION[u]["p"]
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
	trips = trips.filter(func(t): return t["u"] != u)
	trips.append({"u": u, "pts": pts, "t0": Time.get_ticks_msec(), "dur": sec * 1000.0})
	return sec


func remove_units(us: Array) -> void:
	trips = trips.filter(func(t): return not (t["u"] in us))
	queue_redraw()


func _process(d: float) -> void:
	if _reveal >= 0.0:
		_reveal += d / REVEAL_SEC
		_center = Vector2.INF   # acompanha o enquadramento enquanto ele abre
		if _reveal >= 1.0:
			_reveal = -1.0
		queue_redraw()
	elif not trips.is_empty() and is_visible_in_tree():
		queue_redraw()


func _width(txt: String, sz: int) -> float:
	return Pal.ui.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x


## Texto no ponto p do mapa (linha de base), em `sz` px de tela: o mapa é desenhado em escala (`_k`), mas fonte de
## pixel escalada borra, então o texto acompanha só a posição e sai num tamanho nítido de `Pal.ui`.
func _t(p: Vector2, txt: String, sz: int, col: Color = LINE) -> void:
	draw_set_transform((_tf * p).round())
	draw_string(Pal.ui, Vector2(-roundf(_width(txt, sz) / 2.0), 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_set_transform_matrix(_tf)


## Nome centrado no ponto p do mapa (linha de base), em pé se `up`, com fundo `bg` (transparente = sem): só se couber
## inteiro na vista e não encostar num nome já desenhado (`_boxes`). Devolve se desenhou.
func _label(p: Vector2, txt: String, sz: int, col: Color = LINE, bg := Color.TRANSPARENT, up := false) -> bool:
	var w := _width(txt, sz)
	var at := (_tf * p).round()
	var box := Rect2(at.x - sz * 0.8, at.y - w / 2.0 - 1, sz + 2, w + 2) if up else Rect2(at.x - w / 2.0 - 1, at.y - sz * 0.8, w + 2, sz + 2)
	if not _seen().encloses(box) or _boxes.any(func(b: Rect2): return b.intersects(box)):
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
	_boxes = blocked.duplicate()
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
	_use(xf)
	# ruas: de borda a borda de cada folha por onde passam, para continuarem na vizinha
	for pass_ in [[LINE, 18.0], [ROAD, 13.0]]:
		for st in GameData.CONTENT.streets:
			for sheet in _sheets_of(st):
				var o: Vector2 = SHEETS[sheet]
				var a := o + (Vector2(0, st.pos) if st.horizontal else Vector2(st.pos, 0))
				var b := o + (Vector2(600, st.pos) if st.horizontal else Vector2(st.pos, 440))
				draw_line(a, b, pass_[0], pass_[1])
	# divisas entre bairros vizinhos que aparecem (a zona rural é do Alto da Serra)
	for seg in [[3, 1, Vector2(600, 0), Vector2(600, 440)], [3, 2, Vector2(0, 440), Vector2(600, 440)], [1, 0, Vector2(600, 440), Vector2(1200, 440)]]:
		if not (shown(seg[0]) and shown(seg[1])):
			continue
		var n := int(seg[2].distance_to(seg[3]) / 24.0)
		for i in n:
			draw_line(seg[2].lerp(seg[3], float(i) / n), seg[2].lerp(seg[3], (i + 0.5) / n), Color(LINE, 0.5), 3.0)
	# realce e seleção
	if not hover.is_empty():
		var g := seg_geom(GameData.street(hover["street"]), hover["block"])
		draw_line(g[0], g[1], Color(Pal.AMBER, 0.45), 16.0)
	if not sel.is_empty():
		var g := seg_geom(GameData.street(sel["street"]), sel["block"])
		var a: Vector2 = g[0]
		var b: Vector2 = g[1]
		var n := int(a.distance_to(b) / 15.0)
		for i in n:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, (i + 0.66) / n), Color("8e2a17"), 7.0)
		var m: Vector2 = g[2]
		draw_rect(Rect2(m.x - 8, m.y - 8, 16, 16), Color.BLACK)
		draw_rect(Rect2(m.x - 6, m.y - 6, 12, 12), Color("8e2a17"))
	_draw_units()
	_draw_names(_k >= NAMES_K)
	if _reveal >= 0.0:   # o bairro entregue aparece aos poucos
		for s in SHEETS:
			if shown(s) and not SHEET_SECTOR[s] in _before:
				draw_rect(Rect2(SHEETS[s], SHEET), Color(Pal.INK_SOFT, 1.0 - smoothstep(0.0, 1.0, _reveal)))
	# rosa dos ventos, no canto da vista
	_use(Transform2D.IDENTITY)
	var cp := _seen().end - Vector2(46, 40)
	draw_rect(Rect2(cp, Vector2(40, 34)), LINE)
	draw_rect(Rect2(cp + Vector2(2, 2), Vector2(36, 30)), PAPER)
	_t(cp + Vector2(20, 18), "N", 11)
	draw_colored_polygon(PackedVector2Array([cp + Vector2(20, 20), cp + Vector2(14, 29), cp + Vector2(26, 29)]), LINE)
	_use(xf)
	if not hover.is_empty():
		_tag(seg_geom(GameData.street(hover["street"]), hover["block"])[2], hover["label"])


## Folhas (que aparecem) por onde a rua passa.
func _sheets_of(st: Street) -> Array:
	return [st.sector, st.continues].filter(func(s): return s != 0 and shown(s))


## Nomes, na ordem de prioridade: bairros, ruas, lugares e a numeração dos trechos. Afastado (`names` falso), só os
## bairros, no meio da folha.
func _draw_names(names: bool) -> void:
	for s in SHEETS:
		if s != 0 and shown(s):
			var at: Vector2 = SHEETS[s] + (Vector2(300, 433) if names else Vector2(300, 226))
			_label(at, T.text(DISTRICT[s]).to_upper(), 11, Pal.INK_SOFT, PAPER)
	if not names:
		return
	if shown(0):
		_label(SHEETS[0] + Vector2(320, 300), T.text(T.Key.MAP_RURAL), 11, Pal.INK_SOFT)
	for st in GameData.CONTENT.streets:
		for sheet in _sheets_of(st):
			var o: Vector2 = SHEETS[sheet]
			if st.horizontal:
				_label(o + Vector2(180, st.pos + 5), st.name, 11, LINE, ROAD)
			else:
				_vertical_name(o, st)
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
				_label(p0 + Vector2(16, 22), str(b * 100), 11, Pal.INK_SOFT)
			else:
				_label(p0 + Vector2(-13, 26), str(b * 100), 11, Pal.INK_SOFT, Color.TRANSPARENT, true)   # na beira da quadra


## Rua vertical: o nome em pé ao longo dela (como nos aplicativos de mapa), no meio de um trecho entre dois
## cruzamentos, primeiro os compridos; abreviado ("R. do Sol") se o inteiro não couber no trecho; com o mapa afastado,
## o abreviado pode passar por um cruzamento. Sem lugar (encostaria noutro nome), fica para a etiqueta do mouse.
func _vertical_name(o: Vector2, st: Street) -> void:
	var short := st.name.replace("Rua ", "R. ").replace("Avenida ", "Av. ")
	for opt in [[st.name, true], [short, true], [short, false]]:
		for i in [1, 2, 0, 3]:
			var y0: float = YS[i]
			var y1: float = YS[i + 1]
			var fits: bool = _width(opt[0], 11) + 12.0 <= (y1 - y0) * _k
			if (fits or not opt[1]) and _label(o + Vector2(st.pos + 5, (y0 + y1) / 2.0), opt[0], 11, LINE, ROAD, true):
				return


## Nome do lugar no quarteirão `r` (coordenadas do mapa): numa linha, em duas ("Hotel / Estrela") ou em pé no
## quarteirão estreito; se não couber, só aproximando.
func _place_name(r: Rect2, txt: String, up: bool) -> void:
	var c := r.get_center()
	if up:
		if _width(txt, 11) <= r.size.y * _k - 6:
			_label(c + Vector2(5, 0), txt, 11, LINE, Color.TRANSPARENT, true)
		return
	var room := r.size.x * _k - 6
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


## Quarteirões de uma folha (coordenadas da folha): lugares (`LM`) e casas. Os nomes dos lugares ficam para depois
## das ruas (`_places`).
func _draw_blocks(sector: int) -> void:
	var o: Vector2 = SHEETS[sector]
	for ci in 5:
		for ri in 4:
			var x0: float = XS[ci] + (11.0 if ci > 0 else 4.0)
			var x1: float = XS[ci + 1] - (11.0 if ci < 4 else 4.0)
			var y0: float = 40.0 if ri == 0 else YS[ri] + 11.0
			var y1: float = YS[ri + 1] - (11.0 if ri < 3 else 4.0)
			var r := Rect2(x0, y0, x1 - x0, y1 - y0)
			var lm: int = LM.get(sector, {}).get("%d,%d" % [ci, ri], -1)
			if lm == T.Key.MAP_SQUARE:
				draw_rect(r, LINE)
				draw_rect(r.grow(-2), Color("9fae78"))
				for t in 9:
					draw_rect(Rect2(x0 + 8 + (t % 3) * (r.size.x - 24) / 2.0, y0 + 8 + int(t / 3) * (r.size.y - 24) / 2.0, 8, 8), Color("5f7445"))
				var c := r.get_center()
				draw_rect(Rect2(c.x - 14, c.y - 12, 28, 24), LINE)
				draw_rect(Rect2(c.x - 12, c.y - 10, 24, 20), Color("e6dab8"))
				draw_rect(Rect2(c.x - 2, c.y - 24, 4, 14), LINE)
				draw_rect(Rect2(c.x - 6, c.y - 20, 12, 4), LINE)
				_places.append([Rect2(o.x + x0, o.y + y1 - 30, r.size.x, 30), T.text(lm), false])
			elif lm != -1:
				draw_rect(r, LINE)
				draw_rect(r.grow(-2), Color("b7a67b"))
				draw_rect(Rect2(x0 + 4, y0 + 4, r.size.x - 8, minf(14.0, r.size.y - 8)), Color("a39166"))
				_places.append([Rect2(o + r.position, r.size), T.text(lm), r.size.x < 60])
			else:
				draw_rect(r, Color("8f7f5b"))
				draw_rect(r.grow(-1), Color("c3b48b"))
				var yy := y0 + 6
				while yy + 12 < y1:
					var xx := x0 + 6
					while xx + 12 < x1:
						if int(xx * 7 + yy * 3 + sector * 11) % 5 != 0:
							draw_rect(Rect2(xx, yy, 10, 10), Color("a8976c"))
						xx += 18
					yy += 18


## Zona rural (folha sem setor): roças entre as estradas de terra (que continuam as ruas vizinhas) e um rio.
func _draw_rural() -> void:
	for ci in 5:
		for ri in 4:
			var x0: float = XS[ci] + 8.0
			var x1: float = XS[ci + 1] - 8.0
			var y0: float = (YS[ri] if ri > 0 else 0.0) + 8.0
			var y1: float = YS[ri + 1] - 8.0
			var green := (ci + ri) % 2 == 0
			draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), Color("a9b37d") if green else Color("bfae7c"))
			var yy := y0 + 6
			while yy < y1 - 4:
				draw_line(Vector2(x0 + 4, yy), Vector2(x1 - 4, yy), Color("8f9a63") if green else Color("a8956a"), 2.0)
				yy += 10
	draw_polyline(PackedVector2Array([Vector2(60, 440), Vector2(120, 380), Vector2(260, 350), Vector2(330, 250), Vector2(470, 210), Vector2(600, 160)]), Color("6f8fa0"), 12.0)
	for v in [110.0, 250.0, 390.0, 530.0]:
		draw_line(Vector2(v, 0), Vector2(v, 440), Color("b49d72"), 10.0)
	for h in [90.0, 225.0, 360.0]:
		draw_line(Vector2(0, h), Vector2(600, h), Color("b49d72"), 10.0)


func _draw_units() -> void:
	var now := Time.get_ticks_msec()
	for tr in trips:
		var pts: PackedVector2Array = tr["pts"]
		var k := minf(1.0, (now - int(tr["t0"])) / float(tr["dur"]))
		var tot := 0.0
		for i in range(1, pts.size()):
			tot += pts[i].distance_to(pts[i - 1])
		var dist := k * tot
		var p := pts[pts.size() - 1]
		for i in range(1, pts.size()):
			var sl := pts[i].distance_to(pts[i - 1])
			if dist <= sl:
				p = pts[i - 1].lerp(pts[i], dist / sl if sl > 0 else 0.0)
				break
			dist -= sl
		if not SHEETS.keys().any(func(s): return shown(s) and Rect2(SHEETS[s], SHEET).has_point(p)):
			continue   # ainda no Centro, que não aparece: entra pela borda do bairro
		var st: Dictionary = STATION[tr["u"]]
		var r := 7.0 / minf(_k, 1.0)   # do mesmo tamanho na tela, mesmo com o mapa afastado
		draw_rect(Rect2(p.x - r, p.y - r, 2 * r, 2 * r), Color.BLACK)
		draw_rect(Rect2(p.x - r * 5 / 7, p.y - r * 5 / 7, r * 10 / 7, r * 10 / 7), st["c"])
		if k < 1.0 and (now / 300) % 2 == 0:
			draw_rect(Rect2(p.x - r * 2 / 7, p.y - r * 11 / 7, r * 4 / 7, r * 4 / 7), st["l"])


## Etiqueta de papel com o nome e a faixa de números do trecho sob o mouse ("Rua do Sol, 1–99"): mostra onde fica
## o número que a pessoa disse antes de clicar. Em tamanho de tela, acima do trecho, sem sair do mapa.
func _tag(p: Vector2, txt: String) -> void:
	var w := _width(txt, 11)
	var at := (_tf * p).round() + Vector2(-roundf(w / 2.0) - 5, -34)
	at = Vector2(clampf(at.x, 2, _seen().end.x - w - 12), maxf(at.y, 2))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(at, Vector2(w + 10, 20)), LINE)
	draw_rect(Rect2(at + Vector2.ONE, Vector2(w + 8, 18)), Color("f4ecd2"))
	draw_string(Pal.ui, at + Vector2(5, 15), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LINE)
	draw_set_transform_matrix(_tf)


## Tira a marcação do trecho (o despacho limpa depois de enviar).
func clear_selection() -> void:
	sel = {}
	queue_redraw()


## O idioma mudou nas configurações: redesenha os textos. O mouse saiu do mapa: some o realce e a etiqueta.
## O mapa apareceu pela primeira vez na noite de entrega de um setor: abre para o bairro novo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT and not hover.is_empty():
		hover = {}
		queue_redraw()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and not pending_reveal.is_empty():
		_before = pending_reveal
		pending_reveal = []
		_reveal = 0.0
		_zoom = 1.0
