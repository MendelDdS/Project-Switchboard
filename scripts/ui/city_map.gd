class_name CityMap
extends Control
## Mapa em papel da cidade. Cada rua tem 3 trechos de numeração clicáveis.

signal segment_selected(street: String, block: int, label: String)

const XS := [20.0, 110.0, 250.0, 390.0, 530.0, 580.0]
const YS := [34.0, 90.0, 225.0, 360.0, 420.0]
const LM := {"1,0": T.Key.MAP_CLINIC, "2,0": T.Key.MAP_HOSPITAL, "3,0": T.Key.MAP_SCHOOL, "4,0": T.Key.MAP_SAWMILL, "1,1": T.Key.MAP_BUS_STATION, "2,1": T.Key.MAP_SQUARE, "3,1": T.Key.MAP_PHARMACY, "0,2": T.Key.MAP_CINEMA, "1,2": T.Key.MAP_POLICE, "3,2": T.Key.MAP_FIRE_STATION, "1,3": T.Key.MAP_GROCERY, "3,3": T.Key.MAP_FUNERAL}
const STATION := {
	"pol": {"p": Vector2(180, 225), "c": Color("2d4f8a"), "l": Color("4e86e0")},
	"bomb": {"p": Vector2(460, 225), "c": Color("b8321f"), "l": Color("e04e3a")},
	"amb": {"p": Vector2(320, 90), "c": Color("f4f0e4"), "l": Color("e04e3a")},
}
const ROAD := Color("e8dcb9")
const LINE := Color("3a3226")

var sel: Dictionary = {}
var hover: Dictionary = {}
var trips: Array = []
var _k := 0.96
var _off := Vector2.ZERO   ## deslocamento do mapa desenhado (centralizado quando sobra largura)
var _tf := Transform2D.IDENTITY   ## transformação em uso no desenho (os textos a seguem só na posição)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


static func seg_geom(s: Street, b: int) -> Array:
	if s.horizontal:
		var x0 := 20.0 + b * 560.0 / 3.0
		var a := Vector2(x0, s.pos)
		var c := Vector2(x0 + 560.0 / 3.0, s.pos)
		return [a, c, (a + c) / 2.0]
	var y0 := 34.0 + b * 386.0 / 3.0
	var a2 := Vector2(s.pos, y0)
	var c2 := Vector2(s.pos, y0 + 386.0 / 3.0)
	return [a2, c2, (a2 + c2) / 2.0]


func _find_seg(mp: Vector2) -> Dictionary:
	var best := {}
	var bd := 13.0
	for s in GameData.CONTENT.streets:
		for b in 3:
			var g := seg_geom(s, b)
			var d := Geometry2D.get_closest_point_to_segment(mp, g[0], g[1]).distance_to(mp)
			if d < bd:
				bd = d
				best = {"street": s.id, "block": b, "label": "%s, %s" % [s.name, GameData.CONTENT.block_labels[b]]}
	return best


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h := _find_seg((e.position - _off) / _k)
		if h != hover:
			hover = h
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not h.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var h := _find_seg((e.position - _off) / _k)
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
		if is_equal_approx(s.pos, st.y):
			return PackedVector2Array([st, m])
		var mid := (st.x + m.x) / 2.0
		var xv := 110.0
		for v in [110.0, 250.0, 390.0, 530.0]:
			if absf(v - mid) < absf(xv - mid):
				xv = v
		return PackedVector2Array([st, Vector2(xv, st.y), Vector2(xv, m.y), m])
	return PackedVector2Array([st, Vector2(m.x, st.y), m])


func trip(u: String, target: Dictionary) -> void:
	trips = trips.filter(func(t): return t["u"] != u)
	trips.append({"u": u, "pts": route(u, target), "t0": Time.get_ticks_msec(), "dur": 7000.0})


func remove_units(us: Array) -> void:
	trips = trips.filter(func(t): return not (t["u"] in us))
	queue_redraw()


func _process(_d: float) -> void:
	if not trips.is_empty() and is_visible_in_tree():
		queue_redraw()


## Texto no ponto p do mapa (linha de base), em `sz` px de tela: o mapa é desenhado em escala (`_k`), mas fonte de
## pixel escalada borra, então o texto acompanha só a posição (e a rotação) e sai num tamanho nítido de `Pal.ui`.
func _t(p: Vector2, txt: String, sz: int, col: Color = LINE, center: bool = true) -> void:
	var w := Pal.ui.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_set_transform((_tf * p).round(), _tf.get_rotation())
	draw_string(Pal.ui, Vector2(-roundf(w / 2.0) if center else 0.0, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_set_transform_matrix(_tf)


## Muda a transformação do desenho (e a que os textos seguem).
func _use(xf: Transform2D) -> void:
	_tf = xf
	draw_set_transform_matrix(xf)


func _draw() -> void:
	_k = minf(size.x / 600.0, size.y / 440.0)
	_off = Vector2((size.x - 600.0 * _k) / 2.0, 0.0)
	var xf := Transform2D(0.0, Vector2(_k, _k), 0.0, _off)
	_use(xf)
	draw_rect(Rect2(0, 0, 600, 440), Pal.INK_SOFT)
	draw_rect(Rect2(2, 2, 596, 436), Color("cfc199"))
	# quarteirões
	for ci in 5:
		for ri in 4:
			var x0: float = XS[ci] + (11.0 if ci > 0 else 4.0)
			var x1: float = XS[ci + 1] - (11.0 if ci < 4 else 4.0)
			var y0: float = YS[ri] + (11.0 if ri > 0 else -26.0)
			var y1: float = YS[ri + 1] - (11.0 if ri < 3 else 4.0)
			if ri == 0:
				y0 = 40.0
			var r := Rect2(x0, y0, x1 - x0, y1 - y0)
			var key := "%d,%d" % [ci, ri]
			var lm: int = LM.get(key, -1)
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
				_t(Vector2(c.x, y1 - 6), T.text(T.Key.MAP_SQUARE), 12)
			elif lm != -1:
				draw_rect(r, LINE)
				draw_rect(r.grow(-2), Color("b7a67b"))
				draw_rect(Rect2(x0 + 4, y0 + 4, r.size.x - 8, minf(14.0, r.size.y - 8)), Color("a39166"))
				if r.size.x < 60:
					var c2 := r.get_center()
					_use(xf * Transform2D(-PI / 2.0, Vector2(c2.x + 5, c2.y)))
					_t(Vector2.ZERO, T.text(lm), 11)
					_use(xf)
				else:
					_t(r.get_center() + Vector2(0, 6), T.text(lm), 14)
			else:
				draw_rect(r, Color("8f7f5b"))
				draw_rect(r.grow(-1), Color("c3b48b"))
				var yy := y0 + 6
				while yy + 12 < y1:
					var xx := x0 + 6
					while xx + 12 < x1:
						if int(xx * 7 + yy * 3) % 5 != 0:
							draw_rect(Rect2(xx, yy, 10, 10), Color("a8976c"))
						xx += 18
					yy += 18
	# ruas
	for s in GameData.CONTENT.streets:
		var a := Vector2(20, s.pos) if s.horizontal else Vector2(s.pos, 34)
		var b := Vector2(580, s.pos) if s.horizontal else Vector2(s.pos, 420)
		draw_line(a, b, LINE, 18.0)
	for s in GameData.CONTENT.streets:
		var a := Vector2(20, s.pos) if s.horizontal else Vector2(s.pos, 34)
		var b := Vector2(580, s.pos) if s.horizontal else Vector2(s.pos, 420)
		draw_line(a, b, ROAD, 13.0)
	# nomes e numeração
	for s in GameData.CONTENT.streets:
		if s.horizontal:
			var nx := 124.0
			var w := Pal.ui.get_string_size(s.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x / _k
			draw_rect(Rect2(nx - 2, s.pos - 7, w + 4, 14), ROAD)
			_t(Vector2(nx, s.pos + 4), s.name, 12, LINE, false)
		else:
			_t(Vector2(s.pos, 27), s.name, 12)
		for b in [1, 2]:
			var g := seg_geom(s, b)
			var p0: Vector2 = g[0]
			if s.horizontal:
				_t(p0 + Vector2(3, 22), str(b * 100), 11, Pal.INK_SOFT, false)
			else:
				_t(p0 + Vector2(10, 4), str(b * 100), 11, Pal.INK_SOFT, false)
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
	# unidades
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
		var st: Dictionary = STATION[tr["u"]]
		draw_rect(Rect2(p.x - 7, p.y - 7, 14, 14), Color.BLACK)
		draw_rect(Rect2(p.x - 5, p.y - 5, 10, 10), st["c"])
		if k < 1.0 and (now / 300) % 2 == 0:
			draw_rect(Rect2(p.x - 2, p.y - 11, 4, 4), st["l"])
	# rosa dos ventos
	draw_rect(Rect2(546, 382, 40, 34), LINE)
	draw_rect(Rect2(548, 384, 36, 30), Color("cfc199"))
	_t(Vector2(566, 400), "N", 14)
	draw_colored_polygon(PackedVector2Array([Vector2(566, 402), Vector2(560, 411), Vector2(572, 411)]), LINE)


## O idioma mudou nas configurações: redesenha os textos.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
