class_name Background
extends Control
## O cenário atrás da interface, em pixels de 2x2 e esticado até a borda da tela: o canto de uma sala vista por quem
## está sentado à mesa. Uma câmera só, em perspectiva de um ponto (`_vp`, no meio da tela e na altura dos olhos,
## `EYE` acima do fundo do tampo; `_proj`/`_p3` levam um ponto da sala para a tela): a parede do fundo, com o relógio
## (hora do jogo) e um armário de aço de chão atrás da mesa (a base fica escondida por ela); a parede da direita,
## entrando para o fundo a partir da quina (`CORNER`), com a janela vista de lado; a mesa de madeira, afastada da
## parede (`DESK_T`), que termina na parede da direita; e a luminária pendurada sobre a mesa comutadora.
## A vista da janela (a cidade com o clima da noite) é desenhada de frente num vidro fora da tela (`_vport`): ela está
## longe e não entorta com a janela; só o batente, o caixilho e a persiana ficam na perspectiva da parede e a recortam.
## A interface diz onde fica cada coisa: a área das ferramentas (`window`; com uma aberta por cima, o papel cobre o
## cenário), a faixa de baixo da coluna da esquerda (`desk`, a borda da frente do tampo) e a mesa comutadora (`board`,
## de pé no tampo). Cada camada pode virar imagem (PNG): com `wall_art`, `window_art` ou `desk_art`, a imagem entra
## no lugar do desenho daquela camada (o clima continua por cima da vista).
## `weather`: "rain" (gotas no vidro, chão molhado), "fog" (névoa passando, luzes difusas) ou "clear" (estrelas e lua).
## `shadow`: a silhueta de alguém parado do lado de fora da janela (sai pouco antes da ligação desconhecida).
## Objetos na mesa, ao alcance do operador, abrem as ferramentas (`prop_clicked`, o id da aba em `Tools.TABS`): as
## listas telefônicas, o mapa dobrado, o caderno aberto e a prancheta do registro. Ficam na sala, em centímetros da
## mesa, e passam pela mesma câmera (tamanho, escorço e o lado que aparece saem da conta), desenhados em pixels de 1x1
## com o detalhe da mesa comutadora; o resto do cenário é em 2x2. Sob o mouse, ganham contorno, o nome da ferramenta e
## o cursor de dedo; o clique só vale sobre eles (`_has_point`) e não com o papel de uma ferramenta por cima.

signal prop_clicked(id: String)

const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]   ## madeira (luz, meio, sombra), a mesma do móvel
const LIT := [Color("d59a3d"), Color("b38a3c"), Color("e2b25a")]   ## janelas acesas da cidade
const PROPS := {"lista": T.Key.TAB_DIRECTORY, "despacho": T.Key.TAB_DISPATCH, "caderno": T.Key.TAB_LOGBOOK, "registro": T.Key.TAB_CALL_LOG}
const SKY := {"rain": Color("0b141c"), "fog": Color("1b252b"), "clear": Color("0a1422")}
const BOARD_SINK := 30.0   ## quanto da mesa comutadora (px da tela) desce sobre o tampo: o fundo dele fica atrás dela
const LAMP_Y := 24.0       ## a boca da luminária (px de 2x2): de onde sai a luz e saem as sombras na parede
const WALL_GAP := 40.0     ## quanto a luminária fica à frente da parede (px de 2x2): abre o arco de luz nela
# A câmera. Medidas da sala na escala da parede do fundo (px de 2x2 lá; ~0,56 cm): x para a direita e y para baixo a
# partir dos olhos, z a distância deles (a parede fica a `Z0`; mais perto, tudo cresce Z0/z vezes).
const VP_X := 0.55      ## o ponto de fuga na largura da tela: perto dos objetos da mesa (longe dele, eles entortam)
const EYE := 130.0      ## a altura dos olhos acima do fundo do tampo, na tela (px de 2x2): o ponto de fuga
const Z0 := 330.0       ## a distância dos olhos à parede do fundo
const DESK_T := 1.25    ## o fundo do tampo, Z0/DESK_T: a mesa fica afastada da parede (o armário cabe atrás)
const CORNER := 0.64    ## a quina das paredes, na largura da área das ferramentas
const CAB_X := Vector2(-53, 57)  ## o armário de aço: de onde a onde (x), encostado na parede
const CAB_TOP := -40.0           ## o alto dele (y, acima dos olhos): ~1,6 m do chão
const CAB_T := 1.15              ## a frente dele (escala): ~35 cm de fundo
const SIDE_T := 1.06        ## onde a janela começa na parede da direita (escala); termina perto da borda da tela
const SIDE_W := 150.0       ## a largura do vão, de frente (só a resolução da projeção)
const WIN_TOP := -70.0      ## o alto do vão (y, acima dos olhos): passa da borda de cima, como uma janela de verdade
const WIN_SILL := 26.0      ## quanto o peitoril fica acima do tampo (y)

@export var window: Control   ## a área das ferramentas: a quina e a janela ficam na parede dela
@export var desk: Control     ## a faixa de mesa da coluna da esquerda: a borda da frente do tampo fica logo abaixo dela
@export var board: Control    ## a mesa comutadora: fica de pé no tampo, com a base `BOARD_SINK` px à frente do fundo dele
@export var wall_art: Texture2D     ## imagem da parede (repetida), no lugar do desenho
@export var window_art: Texture2D   ## imagem da vista da janela (esticada, de frente), no lugar da cidade desenhada
@export var desk_art: Texture2D     ## imagem da madeira da mesa (repetida), no lugar do desenho

var flick := false
var lamp_level := 1.0
var weather := "rain"
var shadow := false
var clock_min := 18 * 60.0   ## a hora do jogo, em minutos do dia (o Main atualiza): o relógio de parede
var pending := 0:   ## registros esperando no caderno (o Main atualiza): o selo no caderno da mesa
	set(v):
		pending = v
		queue_redraw()
var _drops: Array = []
var _stars: Array[Vector2] = []
var _city: Array = []          # prédios da vista: {x, w, h, roof, lit: [Vector2...]} (em frações e px do vidro)
var _city_for := Vector2.ZERO  # tamanho do vidro para o qual `_city` foi montada
var _mist := 0.0
var _win := Vector2(104, 38)   # a vista da janela, em pixels de 2x2 (do último desenho)
var _acc := 0.0
var _props := {}       # objeto que abre ferramenta -> retângulo dele (px da tela), do último desenho
var _hot := ""         # objeto sob o mouse
var _lamp_x := 0.0     # onde está a luminária (px de 2x2): a luz na mesa e a sombra dos objetos dependem dela
var _vp := Vector2.ZERO   # o ponto de fuga (px de 2x2)
var _yd := 0.0         # a altura do tampo (y da sala, abaixo dos olhos)
var _cx := 0.0         # a quina das paredes (px de 2x2, na tela)
var _t2 := 1.6         # onde a janela termina na parede da direita (escala)
var _ci: CanvasItem    # onde a vista da janela é desenhada: aqui, ou no vidro fora da tela
var _view: Control     # desenha a vista da janela no `_vport`
var _vport: SubViewport
var _cover := Rect2()   # onde está o papel da ferramenta aberta (px da tela, não de 2x2): luz embaixo dele não brilha


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP   # só sobre os objetos (`_has_point`)
	_ci = self
	_vport = SubViewport.new()
	_vport.size = Vector2i(64, 64)
	_vport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view = Control.new()
	_view.draw.connect(_draw_view)
	_vport.add_child(_view)
	add_child(_vport)
	for i in 120:   # gotas e estrelas em frações do vidro: a janela muda de tamanho com a tela
		_drops.append(Vector3(randf(), randf(), 0.6 + randf() * 0.7))
	for i in 30:
		_stars.append(Vector2(randf() * 0.95 + 0.02, randf() * 0.45 + 0.03))


func _process(delta: float) -> void:
	if _paper() != _cover:   # o papel se mexeu: o corte do brilho acompanha já neste quadro
		queue_redraw()
	_acc += delta
	if _acc < 1.0 / 30.0:
		return
	_acc = 0.0
	_mist += 0.12
	for i in _drops.size():
		var d: Vector3 = _drops[i]
		d.y += d.z / _win.y
		d.x -= d.z * 0.25 / _win.x
		if d.y > 1.0:
			d.y = -0.05
			d.x = randf() * 1.1
		_drops[i] = d
	if flick:
		lamp_level = FLICK[int(Time.get_ticks_msec() / 90.0) % FLICK.size()]
	else:
		lamp_level = 1.0
	queue_redraw()
	_view.queue_redraw()


## Onde está o papel da ferramenta aberta ou deslizando (px da tela; vazio com tudo guardado).
func _paper() -> Rect2:
	for n in window.get_children() if window else []:
		if n is Control and n.visible:
			return Rect2(n.global_position - global_position, n.size)
	return Rect2()


## Uma luz do cenário (`r` em px da tela) que brilha, a não ser que o papel de uma ferramenta esteja por cima dela.
func _light(r: Rect2, col: Color, halo: float, round := false) -> void:
	if _ci != self:   # a vista da janela: as luzes dela vêm de `_draw_side_wall`, que sabe onde o vidro está
		return
	if not _cover.intersects(r):
		Bloom.light(self, r, col, halo, true, round)


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	Bloom.clear(self)
	_props.clear()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var w := ceilf(size.x / 2.0)
	var h := ceilf(size.y / 2.0)
	# o fundo do tampo: atrás da mesa comutadora, que fica de pé nele
	var top := floorf((board.global_position.y - global_position.y + board.size.y - BOARD_SINK) / 2.0) if board else 200.0
	# a borda da frente do tampo: logo abaixo da faixa de mesa (o painel do operador cobre o resto)
	var front := floorf((desk.global_position.y - global_position.y + desk.size.y) / 2.0) + 1.0 if desk else h - 20.0
	_lamp_x = floorf((desk.global_position.x - global_position.x + desk.size.x) / 2.0) - 40.0 if desk else w - 140.0
	var area := Rect2((window.global_position - global_position) / 2.0, window.size / 2.0) if window else Rect2(320, 26, 300, 180)
	# o papel da ferramenta aberta (ou deslizando) cobre o cenário por estar na frente; só o brilho das luzes, que fica
	# por cima de tudo, precisa ser cortado onde ele está
	_cover = _paper()
	_vp = Vector2(floorf(w * VP_X), top - EYE)
	_yd = EYE / DESK_T
	_cx = floorf(area.position.x + area.size.x * CORNER)
	_draw_wall(Rect2(0, 0, w, top))
	_draw_wall_light(top)
	var b := Rect2((board.global_position - global_position) / 2.0, board.size / 2.0) if board else Rect2()
	if board:   # a mesa comutadora, de pé na frente da parede, faz sombra nela (o tampo cobre a parte de baixo)
		_cast(b, 1.1)
	var cab := _draw_steel_cabinet()
	_draw_wall_clock(Vector2(floorf((cab.end.x + _cx) / 2.0), 40))
	_draw_desk(Rect2(0, top, w, h - top), front)
	if board:   # a sombra de contato da mesa comutadora no tampo
		_r(b.position.x - 2, b.end.y - 3, b.size.x + 4, 5, Color(0, 0, 0, 0.45))
		_r(b.position.x + 2, b.end.y + 2, b.size.x + 2, 2, Color(0, 0, 0, 0.25))
	_draw_side_wall(top, front, w)
	_draw_desk_props()
	_draw_lamp(_lamp_x)
	if _hot != "" and _props.has(_hot):   # o objeto sob o mouse: contorno e o nome da ferramenta que ele abre
		var hr: Rect2 = _props[_hot]
		draw_set_transform(Vector2.ZERO)
		draw_rect(hr.grow(2), Color(Pal.GLOW, 0.8), false, 2.0)
		var cap := T.text(PROPS[_hot])
		var cw := Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var at := Vector2(clampf(hr.get_center().x - cw / 2.0 - 5, 4, size.x - cw - 14), hr.position.y - 22)
		draw_rect(Rect2(at, Vector2(cw + 10, 16)), Color(0, 0, 0, 0.8))
		draw_string(Pal.ui, at + Vector2(5, 12), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT)


func _has_point(p: Vector2) -> bool:
	return _prop_at(p) != ""


## O objeto da cena em `p` (px da tela), ou "" (nenhum, ou o papel de uma ferramenta por cima).
func _prop_at(p: Vector2) -> String:
	if _cover.has_point(p):
		return ""
	for id in _props:
		if (_props[id] as Rect2).grow(2).has_point(p):
			return id
	return ""


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var id := _prop_at(e.position)
		if id != _hot:
			_hot = id
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != "" else Control.CURSOR_ARROW
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id := _prop_at(e.position)
		if id != "":
			accept_event()
			prop_clicked.emit(id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hot != "":
		_hot = ""
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		queue_redraw()


# ---------------------------------------------------------------- câmera

## Um ponto da sala na tela (px de 2x2): x e y a partir dos olhos, z a distância (ver `Z0`).
func _proj(x: float, y: float, z: float) -> Vector2:
	return _vp + Vector2(x, y) * (Z0 / z)


## O mesmo, em px da tela (os objetos da mesa, desenhados em 1x1).
func _p3(x: float, y: float, z: float) -> Vector2:
	return _proj(x, y, z) * 2.0


## O retângulo que contém os pontos `pts`.
func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


# ---------------------------------------------------------------- parede

## Papel de parede verde-escuro com listras e um friso de losangos (sem rodapé: embaixo dela é a mesa, não o chão).
func _draw_wall(r: Rect2) -> void:
	if wall_art:
		draw_texture_rect(wall_art, r, true)
		return
	_r(r.position.x, r.position.y, r.size.x, r.size.y, Color("172023"))
	for x in range(0, int(r.size.x), 22):
		_r(x, 0, 2, r.size.y, Color("141c1f"))
		_r(x + 11, 0, 1, r.size.y, Color("1a2427"))
	for x in range(0, int(r.size.x), 11):   # friso no alto
		_r(x + 4, 6, 3, 1, Color("1e2a2d"))
		_r(x + 5, 5, 1, 3, Color("1e2a2d"))


## A luz da luminária na parede, atrás dela: o cone que desce da boca corta a parede num arco (alto no meio, descendo
## para os lados) e acaba no tampo, onde vira a poça de `_draw_desk`; a dobra na quina mostra que são dois planos.
## Em degraus, do arco largo e fraco ao miolo.
func _draw_wall_light(top: float) -> void:
	for k in 3:
		var m := 0.75 + k * 0.2   # mais fechado, mais forte
		var w := sqrt(pow((top - LAMP_Y) / m, 2.0) - WALL_GAP * WALL_GAP)
		var pts := PackedVector2Array()
		for i in 25:
			var x := _lamp_x - w + w * 2.0 * i / 24.0
			pts.append(Vector2(x, minf(top, LAMP_Y + sqrt(pow(x - _lamp_x, 2.0) + WALL_GAP * WALL_GAP) * m)))
		draw_colored_polygon(pts, Color(1.0, 0.8, 0.52, 0.03 * lamp_level))


## Sombra na parede de um objeto à frente dela (`r` em px de 2x2): a silhueta ampliada a partir da luminária, `s` vezes
## (mais longe da parede, maior), com a penumbra em degraus.
func _cast(r: Rect2, s: float) -> void:
	var l := Vector2(_lamp_x, LAMP_Y)
	for k in 3:
		var f := 1.0 + (s - 1.0) * (1.0 + k * 0.35)
		var p := (l + (r.position - l) * f).round()
		_r(p.x, p.y, roundf(r.size.x * f), roundf(r.size.y * f), Color(0, 0, 0, 0.14))


## Relógio de parede redondo, de moldura de madeira, com os ponteiros na hora do jogo.
func _draw_wall_clock(c: Vector2) -> void:
	var l := Vector2(_lamp_x, LAMP_Y)
	draw_circle((l + (c - l) * 1.03).round(), 11.0, Color(0, 0, 0, 0.4))
	draw_circle(c, 11.0, WOOD[2])
	draw_circle(c, 10.0, WOOD[1])
	draw_circle(c - Vector2(0.5, 0.5), 8.5, Color("e3d6b2"))
	draw_circle(c, 8.0, Color("d8caa3"))
	for i in 12:   # marcas das horas
		var a := TAU * i / 12.0
		_r(roundf(c.x + sin(a) * 6.5), roundf(c.y - cos(a) * 6.5), 1, 1, Color("5a4d3a"))
	var hr := fmod(clock_min / 60.0, 12.0) / 12.0 * TAU
	var mn := fmod(clock_min, 60.0) / 60.0 * TAU
	draw_line(c, c + Vector2(sin(hr), -cos(hr)) * 4.0, Color("2a2319"), 1.5)
	draw_line(c, c + Vector2(sin(mn), -cos(mn)) * 6.5, Color("2a2319"), 1.0)
	draw_circle(c, 1.0, Color("6e1a12"))


## Calendário de folhinha: cabeçalho vermelho e a grade dos dias, um deles riscado.
func _draw_calendar(r: Rect2) -> void:
	_cast(r, 1.01)
	_r(r.position.x, r.position.y, r.size.x, r.size.y, Color("e3d6b2"))
	_r(r.position.x, r.position.y, r.size.x, 6, Color("8e2a22"))
	for k in 20:
		_r(r.position.x + 2 + (k % 5) * 4, r.position.y + 9 + (k / 5) * 4, 2, 2, Color("8a7d62"))
	_r(r.position.x + 10, r.position.y + 13, 4, 1, Color("8e2a22"))
	_r(r.get_center().x - 1, r.position.y - 1, 2, 2, Color("3a3a3a"))   # o prego


# ---------------------------------------------------------------- parede da direita e janela

## Um ponto do vão da janela (`p`: ao longo da parede, de 0 a `SIDE_W`, e a altura a partir do alto do vão; pode
## passar da borda) na tela (px de 2x2). A distância ao longo da parede é linear em 1/t: a perspectiva certa.
func _side_pt(p: Vector2) -> Vector2:
	var t := 1.0 / lerpf(1.0 / SIDE_T, 1.0 / _t2, p.x / SIDE_W)
	return _vp + Vector2(_cx - _vp.x, WIN_TOP + p.y) * t


## Um retângulo do vão da janela projetado na parede.
func _side_quad(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([_side_pt(r.position), _side_pt(Vector2(r.end.x, r.position.y)), _side_pt(r.end), _side_pt(Vector2(r.position.x, r.end.y))])


## A vista da janela, de frente, no vidro fora da tela (`_vport`, do tamanho da janela na tela).
func _draw_view() -> void:
	_ci = _view
	var g := Rect2(Vector2.ZERO, Vector2(_vport.size))
	_win = g.size
	if window_art:
		_view.draw_texture_rect(window_art, g, false)
	else:
		_draw_city(g)
	_draw_glass_weather(g)
	_ci = self


## A parede da direita, entrando para o fundo a partir da quina (`_cx`): cobre o que fica atrás dela (a mesa termina
## nela, numa linha que foge para o ponto de fuga; entre a quina e o fundo do tampo ela desce atrás da mesa), com as
## listras do papel de parede alargando para a frente, o friso subindo para fora da tela e a janela vista de lado:
## batente, o lado de dentro do vão perto da quina, a vista (reta: está longe) recortada pelo vidro, o caixilho e a
## persiana na perspectiva da parede, e o peitoril com o vaso. A luz da rua entra por ela e cai na mesa, na diagonal.
func _draw_side_wall(top: float, front: float, w: float) -> void:
	var xc := _cx - _vp.x
	if xc < 20.0:   # a tela ainda não se arrumou (primeiro quadro)
		return
	var te := (w - _vp.x) / xc   # a escala na borda da tela
	var j := _vp + Vector2(xc, _yd) * te
	var d := _vp + Vector2(xc, _yd) * DESK_T
	# a luz da rua na mesa: sai de baixo da janela e cai para a esquerda, na frente
	_t2 = (w - 14.0 - _vp.x) / xc
	var a := _vp + Vector2(xc, _yd) * maxf(SIDE_T, DESK_T)
	var c := _vp + Vector2(xc, _yd) * minf(_t2, te)
	var cool: float = {"clear": 0.06, "rain": 0.04, "fog": 0.025}.get(weather, 0.04)
	if c.x > a.x + 4.0:   # (com a tela mudando de tamanho, a janela pode ainda não chegar à mesa)
		draw_colored_polygon(PackedVector2Array([a, c, Vector2(c.x - 70, front), Vector2(a.x - 110, front)]), Color(0.6, 0.72, 0.9, cool))
	var wall := Color("202d30")   # virada para a luminária: mais clara que a do fundo (é o que mostra a quina)
	draw_colored_polygon(PackedVector2Array([Vector2(_cx, 0), Vector2(w, 0), j, d, Vector2(_cx, top)]), wall)
	var k := 1
	while true:   # as listras: passos iguais na parede são passos iguais em 1/t
		var inv := 1.0 - k * 0.04
		if inv <= 0.0:
			break
		var t := 1.0 / inv
		var x := _vp.x + xc * t
		if x >= w:
			break
		var bottom := top if t < DESK_T else _vp.y + _yd * t
		_r(roundf(x), 0, maxf(1.0, roundf(1.5 * t)), roundf(bottom), Color("1b2629"))
		k += 1
	draw_line(Vector2(_cx, 6), Vector2(w, _vp.y + (6 - _vp.y) * te), Color("26353a"), 1.0)   # o friso
	for i in 3:   # a quina: a parede da direita escurece de leve perto dela
		_r(_cx, 0, 6 - i * 2, top, Color(0, 0, 0, 0.06))
	# o batente
	var gw := SIDE_W
	var gh := _yd - WIN_SILL - WIN_TOP
	draw_colored_polygon(_side_quad(Rect2(-5, -5, gw + 10, gh + 10)), WOOD[2])
	draw_colored_polygon(_side_quad(Rect2(-4, -4, gw + 8, gh + 8)), WOOD[1])
	draw_colored_polygon(_side_quad(Rect2(-4, -4, gw + 8, 1)), WOOD[0])
	# a vista, reta, recortada pelo vidro: o horizonte dela na altura dos olhos
	var q := _side_quad(Rect2(0, 0, gw, gh))
	var box := _bounds(q)
	box = box.intersection(Rect2(0, 0, w, box.end.y))
	# a cidade põe o horizonte a 58% da altura: na altura dos olhos, com a rua logo acima do peitoril de longe
	var low := _side_pt(Vector2(0, gh)).y
	var vh := (low - _vp.y) / 0.42
	var view := Rect2(floorf(box.position.x), floorf(low - vh), ceilf(box.size.x) + 1, ceilf(vh))
	if _vport.size != Vector2i(view.size):
		_vport.size = Vector2i(view.size)
	var uv := PackedVector2Array()
	for p in q:
		uv.append((p - view.position) / view.size)
	draw_polygon(q, PackedColorArray([Color.WHITE]), uv, _vport.get_texture())
	# as luzes da vista brilham onde aparecem no vidro: o relógio da igreja e o poste
	var street := view.size.y - 10.0
	var face := view.position + Vector2(floorf(view.size.x * 0.36), street - 40)
	if Geometry2D.is_point_in_polygon(face, q):
		_light(Rect2(face * 2.0 - Vector2(5, 5), Vector2(10, 10)), Color("e2b25a"), 0.6, true)
	var lamp := view.position + Vector2(floorf(view.size.x * 0.8), street - 26)
	if lamp_level > 0.5 and Geometry2D.is_point_in_polygon(lamp, q):
		_light(Rect2((lamp + Vector2(-2, 1)) * 2.0, Vector2(6, 2)), Color("ffd88a"), 0.8)
	# o caixilho em cruz e a persiana meio baixada, na parede
	draw_colored_polygon(_side_quad(Rect2(gw / 2.0 - 1, 0, 2, gh)), WOOD[1])
	draw_colored_polygon(_side_quad(Rect2(0, floorf(gh * 0.55) - 1, gw, 2)), WOOD[1])
	var blind := floorf(gh * 0.3)
	for y in range(0, int(blind), 3):
		draw_colored_polygon(_side_quad(Rect2(0, y, gw, 2)), Color("8a8070"))
		draw_colored_polygon(_side_quad(Rect2(0, y + 2, gw, 1)), Color("4a4438"))
	draw_line(_side_pt(Vector2(gw * 0.8, blind)), _side_pt(Vector2(gw * 0.8, blind + 8)), Color("8a8070"), 1.0)   # o cordão
	# o vão: perto da quina aparece o lado de dentro do batente (virado para quem olha), o peitoril e a verga
	draw_colored_polygon(_side_quad(Rect2(0, 0, 10, gh)), Color("223033"))
	draw_line(_side_pt(Vector2(10, 0)), _side_pt(Vector2(10, gh)), Color(0, 0, 0, 0.4), 1.0)
	draw_colored_polygon(_side_quad(Rect2(0, gh - 3, gw, 3)), Color("2c3a3c"))
	draw_colored_polygon(_side_quad(Rect2(0, 0, gw, 2)), Color("0d1315"))
	# o peitoril de fora e o vaso
	draw_colored_polygon(_side_quad(Rect2(-8, gh + 4, gw + 16, 3)), WOOD[0])
	draw_colored_polygon(_side_quad(Rect2(-8, gh + 7, gw + 16, 2)), WOOD[2])
	var pp := _side_pt(Vector2(gw * 0.82, gh + 4)).round()
	_r(pp.x, pp.y - 7, 9, 7, Color("8a4a2a"))
	_r(pp.x, pp.y - 7, 9, 1, Color("a85c36"))
	for leaf in [Vector2(-3, -12), Vector2(1, -15), Vector2(5, -13), Vector2(9, -10), Vector2(-1, -10)]:
		_r(pp.x + leaf.x, pp.y + leaf.y, 4, 3, Color("3d5a32"))
		_r(pp.x + leaf.x, pp.y + leaf.y, 2, 1, Color("5a7a46"))


## Armário de aço antigo, de chão, encostado na parede do fundo atrás da mesa (`CAB_X`, `CAB_TOP`, `CAB_T`; a mesa,
## desenhada depois, esconde a base): cornija no alto, duas portas verde-acinzentadas com venezianas, o porta-etiqueta
## niquelado, o puxador com a fechadura, as dobradiças e um calendário preso com ímã. Devolve a frente (px de 2x2).
func _draw_steel_cabinet() -> Rect2:
	var back := Rect2(_vp + Vector2(CAB_X.x, CAB_TOP), Vector2(CAB_X.y - CAB_X.x, 400))
	_cast(back, 1.05)
	var f := Rect2((_vp + Vector2(CAB_X.x, CAB_TOP) * CAB_T).round(), (Vector2(CAB_X.y - CAB_X.x, 400) * CAB_T).round())
	var steel := Color("566052")
	if back.position.x < f.position.x:   # à direita do ponto de fuga: aparece o lado esquerdo, fugindo para a parede
		draw_colored_polygon(PackedVector2Array([back.position, f.position, Vector2(f.position.x, f.end.y), Vector2(back.position.x, back.end.y)]),
			steel.darkened(0.45))
	elif back.end.x > f.end.x:   # à esquerda: o lado direito
		draw_colored_polygon(PackedVector2Array([Vector2(f.end.x, f.position.y), Vector2(back.end.x, back.position.y), back.end, f.end]),
			steel.darkened(0.3))
	_r(f.position.x - 1, f.position.y - 1, f.size.x + 2, f.size.y + 2, Color.BLACK)
	_r(f.position.x, f.position.y, f.size.x, f.size.y, steel)
	for i in 3:   # a luz da luminária, mais forte do lado dela
		_r(f.position.x + i * 6, f.position.y, 6, f.size.y, Color(1.0, 0.85, 0.6, 0.03 * (3 - i)))
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, 5, steel.darkened(0.15))   # a cornija
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, 1, steel.lightened(0.3))
	_r(f.position.x - 2, f.position.y + 4, f.size.x + 4, 1, Color("23281f"))
	_r(f.position.x, f.position.y + 5, 1, f.size.y, steel.lightened(0.15))   # a luz à esquerda, a sombra à direita
	_r(f.end.x - 1, f.position.y + 5, 1, f.size.y, steel.darkened(0.3))
	var mid := floorf(f.get_center().x)
	var doors := f.position.y + 8
	_r(mid - 1, doors, 1, f.size.y, Color("23281f"))   # a fresta entre as portas
	_r(mid, doors, 1, f.size.y, steel.lightened(0.12))
	for door in [Rect2(f.position.x + 3, doors, mid - f.position.x - 5, 60), Rect2(mid + 2, doors, f.end.x - mid - 5, 60)]:
		for i in 6:   # as venezianas, no alto de cada porta
			_r(door.position.x + 6, door.position.y + 4 + i * 4, door.size.x - 12, 2, Color("2e342b"))
			_r(door.position.x + 6, door.position.y + 6 + i * 4, door.size.x - 12, 1, steel.lightened(0.2))
	# o porta-etiqueta na porta da esquerda, com o cartão datilografado
	var lab := Rect2(f.position.x + 12, doors + 34, 24, 11)
	_r(lab.position.x - 1, lab.position.y - 1, lab.size.x + 2, lab.size.y + 2, Color("8e897c"))
	_r(lab.position.x, lab.position.y, lab.size.x, lab.size.y, Color("e3d6b2"))
	_r(lab.position.x + 3, lab.position.y + 4, lab.size.x - 6, 1, Color("4a4438"))
	_r(lab.position.x + 3, lab.position.y + 7, lab.size.x - 11, 1, Color("4a4438"))
	# o puxador e a fechadura, junto da fresta, na altura da mão
	var hy := _vp.y + 30.0 * CAB_T
	_r(mid + 4, hy, 3, 16, Color.BLACK)
	_r(mid + 4, hy, 2, 15, Color("d6d1c3"))
	draw_circle(Vector2(mid + 5.5, hy - 5), 2.0, Color("8e897c"))
	_r(mid + 5, hy - 6, 1, 2, Color("23281f"))
	for y in [doors + 4, doors + 70]:   # as dobradiças
		_r(f.position.x - 1, y, 2, 7, Color("8e897c"))
		_r(f.end.x - 1, y, 2, 7, Color("8e897c"))
	_draw_calendar(Rect2(mid + 14, doors + 46, 24, 26))   # preso com ímã
	return f


## A vista: céu do clima, morros ao fundo, casas e a igreja com o relógio aceso, a rua com o poste (a silhueta do
## mistério fica contra a luz dele) e, na chuva, o chão molhado refletindo as luzes.
func _draw_city(g: Rect2) -> void:
	var wx := g.position.x
	var wy := g.position.y
	var ww := g.size.x
	var wh := g.size.y
	var fog := weather == "fog"
	var sky: Color = SKY.get(weather, SKY["rain"])
	_r(wx, wy, ww, wh, sky)
	for k in 3:   # o céu clareia perto do horizonte
		_r(wx, wy + wh * (0.3 + k * 0.12), ww, wh * 0.12, sky.lightened(0.04 * (k + 1)))
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			_r(wx + floorf(s.x * ww), wy + floorf(s.y * wh), 1, 1, Color("c9d2dc") if sin(tw + i * 1.7) > -0.6 else Color("56606c"))
		_ci.draw_circle(Vector2(wx + ww - 30, wy + 30), 5.0, Color("d8d0a8"))
		_ci.draw_circle(Vector2(wx + ww - 28, wy + 29), 4.6, sky)
	# morros ao fundo
	var hill := sky.lightened(0.07) if fog else sky.lightened(0.03)
	var hy := wy + wh * 0.58
	var pts := PackedVector2Array([Vector2(wx, wy + wh)])
	for i in 9:
		pts.append(Vector2(wx + ww * i / 8.0, hy - [6, 12, 9, 16, 11, 7, 13, 8, 5][i]))
	pts.append(Vector2(wx + ww, wy + wh))
	_ci.draw_colored_polygon(pts, hill)
	# casas e a igreja
	if _city_for != g.size:
		_build_city(g.size)
	var street := wy + wh - 10.0
	var house := Color("141c22") if fog else Color("070b10")
	var flicked := 0
	for b in _city:
		var bx: float = wx + b["x"]
		var by: float = street - b["h"]
		_r(bx, by, b["w"], b["h"], house)
		if b["roof"]:
			_ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 1, by), Vector2(bx + b["w"] / 2.0, by - 5), Vector2(bx + b["w"] + 1, by)]), house)
		for p in b["lit"]:
			flicked += 1
			if flick and flicked % 3 == 0:
				continue
			_r(bx + p.x, by + p.y, 2, 2, LIT[int(p.x + p.y) % LIT.size()])
	_draw_church(Vector2(wx + floorf(ww * 0.36), street), house)
	# a rua, o poste e o chão
	_r(wx, street, ww, 10, Color("10161b") if fog else Color("06090c"))
	_r(wx, street, ww, 1, Color("1d262c"))
	var lamp := Vector2(wx + floorf(ww * 0.8), street - 26)
	_r(lamp.x, lamp.y, 1, 26, Color("1d262c"))
	_r(lamp.x - 3, lamp.y - 1, 5, 2, Color("1d262c"))
	var on := lamp_level > 0.5
	if on:
		_r(lamp.x - 2, lamp.y + 1, 3, 1, Color("ffd88a"))
		_ci.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-2, 2), lamp + Vector2(1, 2), lamp + Vector2(10, 26), lamp + Vector2(-11, 26)]),
			Color(1.0, 0.85, 0.55, 0.07 if not fog else 0.12))
		_light(Rect2((lamp + Vector2(-2, 1)) * 2.0, Vector2(6, 2)), Color("ffd88a"), 0.8)
	if weather == "rain":   # o chão molhado reflete as luzes
		for b in _city:
			if not b["lit"].is_empty():
				var p: Vector2 = b["lit"][0]
				_r(wx + b["x"] + p.x, street + 2, 2, 5, Color(LIT[0], 0.25))
		if on:
			_r(lamp.x - 1, street + 2, 2, 7, Color(1.0, 0.85, 0.55, 0.3))
	if shadow:
		# cabeça e ombros de alguém parado lá fora, contra a luz do poste (a névoa e a chuva passam por cima)
		var sx := wx + roundf(ww * 0.71)
		var base := street + 8.0
		for k in 5:
			_ci.draw_circle(Vector2(sx + 3, base - 10), 22.0 - k * 4.0, Color(0.85, 0.62, 0.3, 0.035))
		_ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 9, base), Vector2(sx - 7, base - 9), Vector2(sx - 2, base - 12),
			Vector2(sx + 2, base - 12), Vector2(sx + 7, base - 9), Vector2(sx + 9, base)]), Color.BLACK)
		_r(sx - 1, base - 15, 3, 3, Color.BLACK)
		_ci.draw_circle(Vector2(sx + 0.5, base - 18), 3.5, Color.BLACK)


## As casas da vista, sorteadas sempre do mesmo jeito para cada tamanho de vidro (a cidade não muda de uma noite para
## outra): largura, altura, telhado e quais janelas estão acesas.
func _build_city(gs: Vector2) -> void:
	_city.clear()
	_city_for = gs
	var rng := RandomNumberGenerator.new()
	rng.seed = 1957
	var x := 1.0
	while x < gs.x - 4.0:
		var bw := minf(float(rng.randi_range(10, 20)), gs.x - x)   # a última casa termina na borda do vidro
		var church := absf(x + bw / 2.0 - gs.x * 0.36) < 12.0
		var bh := float(rng.randi_range(10, 26)) * (0.6 if church else 1.0)
		var lit: Array[Vector2] = []
		for yy in range(4, int(bh) - 3, 5):
			for xx in range(3, int(bw) - 3, 5):
				if rng.randf() < 0.22:
					lit.append(Vector2(xx, yy))
		_city.append({"x": x, "w": bw, "h": bh, "roof": rng.randf() < 0.55 and x + bw < gs.x - 1.0, "lit": lit})
		x += bw + float(rng.randi_range(1, 4))


## A igreja da praça: nave, torre com a ponta e o relógio aceso no alto.
func _draw_church(base: Vector2, col: Color) -> void:
	_r(base.x - 12, base.y - 18, 24, 18, col)
	_ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-13, -18), base + Vector2(0, -26), base + Vector2(13, -18)]), col)
	_r(base.x - 4, base.y - 48, 8, 30, col)
	_ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-5, -48), base + Vector2(0, -60), base + Vector2(5, -48)]), col)
	_r(base.x, base.y - 64, 1, 4, col)   # a cruz
	_r(base.x - 1, base.y - 63, 3, 1, col)
	var face := base + Vector2(0, -40)
	_ci.draw_circle(face, 2.5, Color("e2b25a"))
	_r(face.x, face.y - 2, 1, 2, Color("2a2016"))
	_light(Rect2((face - Vector2(2.5, 2.5)) * 2.0, Vector2(10, 10)), Color("e2b25a"), 0.6, true)
	_r(base.x - 2, base.y - 10, 4, 10, Color(LIT[1], 0.8))   # a porta, com luz dentro


## O clima no vidro: gotas escorrendo (chuva), faixas de névoa passando (névoa) e um reflexo na diagonal.
func _draw_glass_weather(g: Rect2) -> void:
	if weather == "rain":
		for d in _drops:
			if d.x >= 0.0 and d.x < 1.0 and d.y >= 0.0:
				_r(g.position.x + floorf(d.x * g.size.x), g.position.y + floorf(d.y * (g.size.y - 3)), 1, 3, Color("3a5563"))
	elif weather == "fog":
		for k in int(g.size.y / 9.0):
			var x := g.position.x - 60.0 + fmod(_mist * (0.6 + (k % 4) * 0.25) + k * 47.0, g.size.x + 60.0)
			var band := Rect2(x, g.position.y + 4 + k * 8, 60, 7).intersection(g)
			if band.has_area():
				_ci.draw_rect(band, Color(0.62, 0.7, 0.74, 0.07))
		_ci.draw_rect(g, Color(0.55, 0.62, 0.66, 0.06))
	_ci.draw_colored_polygon(PackedVector2Array([g.position + Vector2(g.size.x * 0.12, 0), g.position + Vector2(g.size.x * 0.22, 0),
		g.position + Vector2(g.size.x * 0.02, g.size.y * 0.5), g.position + Vector2(0, g.size.y * 0.5)]), Color(1, 1, 1, 0.03))


# ---------------------------------------------------------------- mesa

## Tampo de madeira visto de cima e da frente, de `r.position.y` (o fundo dele) até `front` (a borda da frente,
## com a espessura do tampo embaixo): tábuas compridas de um lado ao outro, sem juntas (com juntas parecia assoalho),
## com as emendas mais juntas no fundo e mais espaçadas na frente, e o fundo mais escuro. Por cima, a poça de luz quente
## da luminária, que escurece para longe dela (a luz da janela, de lado, vem com a parede da direita).
func _draw_desk(r: Rect2, front: float) -> void:
	var depth := front - r.position.y
	if desk_art:
		draw_texture_rect(desk_art, Rect2(r.position, Vector2(r.size.x, depth)), true)
	else:
		_r(r.position.x, r.position.y, r.size.x, depth, Color("241a12"))
		var seams := [0.0, 0.1, 0.22, 0.37, 0.55, 0.76, 1.0]   # as emendas, cada vez mais espaçadas para a frente
		for k in seams.size() - 1:
			var y0: float = r.position.y + depth * seams[k]
			var y1: float = r.position.y + depth * seams[k + 1]
			_r(r.position.x, floorf(y1) - 1, r.size.x, 1, Color("1a120c"))
			_r(r.position.x, floorf(y0), r.size.x, 1, Color("2b2016"))   # a beira de cada tábua pega luz
			for i in int(r.size.x / 40.0):   # veios, mais compridos na frente (mais perto)
				var gx := fmod(i * 97.0 + k * 31.0, r.size.x)
				_r(gx, floorf(y0 + (y1 - y0) * (0.3 + 0.4 * ((i + k) % 3) / 2.0)), 10 + (i % 4) * 6 + k * 6, 1, Color("2e2219"))
		for k in 2:   # o fundo escurece de leve (sem linha na quina: com ela parecia o rodapé de um chão)
			_r(r.position.x, r.position.y, r.size.x, depth * (0.16 - k * 0.08), Color(0, 0, 0, 0.04))
	# a luz da luminária: elipses em degraus, mais forte embaixo dela
	for k in 4:
		var rx := 210.0 - k * 45.0
		var ry := depth * (0.95 - k * 0.18)
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(Vector2(_lamp_x + cos(a) * rx, r.position.y + depth * 0.45 + sin(a) * ry))
		draw_colored_polygon(pts, Color(1.0, 0.78, 0.48, 0.035))
	# a borda da frente: o canto arredondado do tampo pega a luz, a espessura dele e, embaixo, o escuro sob a mesa
	_r(r.position.x, front - 1, r.size.x, 1, Color("5a4030"))
	_r(r.position.x, front, r.size.x, 1, Color("6b4529"))
	_r(r.position.x, front + 1, r.size.x, 4, Color("3a2616"))
	_r(r.position.x, front + 5, r.size.x, 1, Color("1a120c"))
	_r(r.position.x, front + 6, r.size.x, r.end.y - front - 6, Color("0a0705"))


## Na mesa, embaixo da janela, ao alcance do operador: as listas telefônicas, o caderno aberto, a caneca de café, a
## prancheta do registro e o mapa dobrado, do fundo para a frente (quem está mais perto é desenhado por cima). Cada um
## fica num lugar da sala (x a partir dos olhos, z a distância; ver `Z0`) e é desenhado em px da tela (1x1).
func _draw_desk_props() -> void:
	draw_set_transform(Vector2.ZERO)
	_draw_books(-21, 205, 30, 34)
	var nb := _flat("caderno", 21, 205, 46, 30, 2, Color("3a2414"), _draw_open_notebook)
	_draw_mug(123, 205, 6, 14)
	_flat("registro", 81, 172, 26, 34, 2, Color("4a3018"), _draw_clipboard)
	_flat("despacho", -9, 172, 36, 22, 1, Color("a89a76"), _draw_folded_map)
	if pending > 0:   # quantos registros esperam: o selo âmbar no canto do caderno, como o da aba
		var t := str(pending)
		var sw := maxf(16.0, Pal.ui.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 6.0)
		var sr := Rect2(nb[1] + Vector2(-sw / 2.0, -10), Vector2(sw, 16)).abs()
		sr.position = sr.position.round()
		draw_rect(sr.grow(1), Color.BLACK)
		draw_rect(sr, Pal.AMBER)
		draw_string(Pal.ui, sr.position + Vector2(0, 12), t, HORIZONTAL_ALIGNMENT_CENTER, sw, 11, Color("2a2319"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Os cantos de uma caixa deitada na mesa (px da tela): de `x0` a `x0 + wx`, de `zf` (frente) a `zf + dz` (fundo), do
## chão `y0` até `h` acima. Devolve {top: [fundo-esq, fundo-dir, frente-dir, frente-esq], front: Rect2, side: [...]}.
func _box(x0: float, zf: float, wx: float, dz: float, y0: float, h: float) -> Dictionary:
	var y1 := y0 - h
	var front := Rect2(_p3(x0, y1, zf).round(), Vector2.ZERO).expand(_p3(x0 + wx, y0, zf).round())
	var sx := x0 if x0 > 0.0 else x0 + wx   # o lado virado para o ponto de fuga (atravessando-o, nenhum)
	var side := PackedVector2Array()
	if x0 > 0.0 or x0 + wx < 0.0:
		side = PackedVector2Array([_p3(sx, y1, zf + dz), _p3(sx, y1, zf), _p3(sx, y0, zf), _p3(sx, y0, zf + dz)])
	return {
		"top": PackedVector2Array([_p3(x0, y1, zf + dz), _p3(x0 + wx, y1, zf + dz), _p3(x0 + wx, y1, zf), _p3(x0, y1, zf)]),
		"front": front,
		"side": side,
	}


## Um polígono com contorno preto de 1 px (o contorno dos objetos, como na mesa comutadora).
func _poly(pts: PackedVector2Array, col: Color) -> void:
	var out := Geometry2D.offset_polygon(pts, 1.0)
	if not out.is_empty():
		draw_colored_polygon(out[0], Color.BLACK)
	draw_colored_polygon(pts, col)


## Um paralelogramo da tela (o tampo `q` de uma caixa) como transformação de um retângulo de px (0, 0)–`size`: o
## desenho de frente de um objeto chato vira o tampo dele na perspectiva. Devolve [Transform2D, size].
func _top_xf(q: PackedVector2Array) -> Array:
	var u := ((q[1] - q[0]) + (q[2] - q[3])) / 2.0
	var v := ((q[3] - q[0]) + (q[2] - q[1])) / 2.0
	var s := Vector2(maxf(1.0, roundf(u.length())), maxf(1.0, roundf(absf(v.y))))
	var c := (q[0] + q[1] + q[2] + q[3]) / 4.0
	return [Transform2D(u / s.x, v / s.y, c - u / 2.0 - v / 2.0), s]


## Sombra de um objeto na mesa (`foot`, a marca dele no tampo), apontando para longe da luminária.
func _desk_shadow(foot: PackedVector2Array) -> void:
	var off := Vector2(clampf((_bounds(foot).get_center().x - _lamp_x * 2.0) / 60.0, -6.0, 8.0), 4.0).round()
	var pts := PackedVector2Array()
	for p in foot:
		pts.append(p + off)
	draw_colored_polygon(pts, Color(0, 0, 0, 0.35))


## Um objeto chato que abre a ferramenta `id`: a sombra, a espessura (`h`, na cor `edge`: a frente e o lado virado para
## o ponto de fuga) e o tampo, desenhado de frente por `paint` (um retângulo de px) e posto na perspectiva. Devolve o
## tampo (px da tela).
func _flat(id: String, x0: float, zf: float, wx: float, dz: float, h: float, edge: Color, paint: Callable) -> PackedVector2Array:
	var foot := _box(x0, zf, wx, dz, _yd, 0.0)["top"] as PackedVector2Array
	_desk_shadow(foot)
	var bx := _box(x0, zf, wx, dz, _yd, h)
	if not (bx["side"] as PackedVector2Array).is_empty():
		_poly(bx["side"], edge.darkened(0.35))
	_poly(PackedVector2Array([bx["top"][3], bx["top"][2], foot[2], foot[3]]), edge)
	var xf: Array = _top_xf(bx["top"])
	draw_set_transform_matrix(xf[0])
	paint.call(Rect2(Vector2.ZERO, xf[1]))
	draw_set_transform(Vector2.ZERO)
	_props[id] = _bounds(foot + (bx["top"] as PackedVector2Array))
	return bx["top"]


## As listas telefônicas, três volumes grossos empilhados meio tortos: a lombada na cor da capa, do lado virado para o
## ponto de fuga, com os filetes dourados; na frente, o miolo de papel com as folhas marcadas entre as capas; e, no de
## cima, o tampo com a faixa do título e o emblema da central.
func _draw_books(x0: float, zf: float, wx: float, dz: float) -> void:
	var cols := [Color("8e2a22"), Color("2a4a7c"), Color("b48c1c")]
	var offs := [Vector2(1, 0), Vector2(3, 2), Vector2(0, 1)]   # meio tortos: x e z de cada volume
	var bh := 5.5
	var all := PackedVector2Array()
	_desk_shadow(_box(x0, zf, wx, dz, _yd, 0.0)["top"])
	for b in 3:
		var c: Color = cols[b]
		var bx := _box(x0 + offs[b].x, zf + offs[b].y, wx, dz, _yd - b * bh, bh)
		var side: PackedVector2Array = bx["side"]
		if not side.is_empty():
			_poly(side, c.darkened(0.2))   # a lombada
			draw_line(side[0].lerp(side[3], 0.3), side[1].lerp(side[2], 0.3), Color("e0c07a"), 1.0)
			draw_line(side[0].lerp(side[3], 0.7), side[1].lerp(side[2], 0.7), Color("e0c07a"), 1.0)
		var top: PackedVector2Array = bx["top"]
		_poly(top, c)
		var f: Rect2 = bx["front"]
		draw_rect(f.grow(1), Color.BLACK)
		draw_rect(f, Color("e3d6b2"))   # o miolo
		for k in range(2, int(f.size.y) - 1, 2):   # as folhas
			draw_rect(Rect2(f.position.x + 2, f.position.y + k, f.size.x - 4, 1), Color("c2b288"))
		draw_rect(Rect2(f.position, Vector2(f.size.x, 2)), c.lightened(0.15))   # a capa de cima e a de baixo
		draw_rect(Rect2(f.position.x, f.end.y - 2, f.size.x, 2), c.darkened(0.3))
		all.append_array(top)
		all.append_array(side)
		all.append(f.position)
		all.append(f.end)
		if b == 2:   # o tampo do volume de cima: a faixa do título e o emblema da central
			var xf: Array = _top_xf(top)
			var s: Vector2 = xf[1]
			draw_set_transform_matrix(xf[0])
			draw_rect(Rect2(0, 0, s.x, 1), c.lightened(0.25))
			draw_rect(Rect2(6, s.y * 0.35, s.x - 22, maxf(2.0, s.y * 0.25)), c.darkened(0.3))
			draw_circle(Vector2(s.x - 8, s.y * 0.5), 3.0, c.darkened(0.35))
			draw_circle(Vector2(s.x - 8.5, s.y * 0.5 - 0.5), 1.6, Color("e0c07a"))
			draw_set_transform(Vector2.ZERO)
	_props["lista"] = _bounds(all)


## A caneca de café em pé na mesa (centro `xc`, `zc`; raio `rr`, altura `hh`): cerâmica creme com o sombreado do
## cilindro, a boca em elipse com o café, a alça e o emblema da central.
func _draw_mug(xc: float, zc: float, rr: float, hh: float) -> void:
	var a := _p3(xc - rr, _yd - hh, zc).round()
	var body := Rect2(a, _p3(xc + rr, _yd, zc).round() - a)
	var ry := maxf(2.0, roundf((_p3(xc, _yd - hh, zc - rr).y - _p3(xc, _yd - hh, zc + rr).y) / 2.0))
	var rx := body.size.x / 2.0
	_desk_shadow(PackedVector2Array([body.position + Vector2(0, body.size.y - ry), body.end - Vector2(0, ry), body.end, Vector2(body.position.x, body.end.y)]))
	var hx := body.end.x
	draw_rect(Rect2(hx, body.position.y + 4, 7, 13), Color.BLACK)   # a alça
	draw_rect(Rect2(hx, body.position.y + 5, 6, 11), Color("c2b288"))
	draw_rect(Rect2(hx, body.position.y + 8, 3, 5), Color("211811"))
	draw_rect(body.grow(1), Color.BLACK)
	draw_rect(body, Color("d8caa3"))
	draw_rect(Rect2(body.position, Vector2(4, body.size.y)), Color("ece2c6"))   # a luz
	draw_rect(Rect2(body.end.x - 5, body.position.y, 5, body.size.y), Color("a89a76"))   # a sombra
	var top := Vector2(body.get_center().x, body.position.y)
	_ellipse(top, rx + 1, ry + 1, Color.BLACK)   # a boca
	_ellipse(top, rx, ry, Color("e3d6b2"))
	_ellipse(top + Vector2(0, 1), rx - 2, ry - 1, Color("3a2414"))   # o café
	draw_circle(body.get_center() + Vector2(-1, 3), 4.0, Color("8e2a22"))   # o emblema
	draw_circle(body.get_center() + Vector2(-1.5, 2.5), 1.8, Color("e0c07a"))


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(c + Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * ry))
	draw_colored_polygon(pts, col)


## O mapa da cidade dobrado em três, meio aberto na mesa: os painéis alternam luz e sombra nas dobras, com quadras,
## ruas, o rio e um local marcado com alfinete.
func _draw_folded_map(r: Rect2) -> void:
	draw_rect(r.grow(1), Color("3a2e1e"))
	var pw := r.size.x / 3.0
	for k in 3:
		var pr := Rect2(r.position.x + k * pw, r.position.y, pw, r.size.y)
		draw_rect(pr, Color("e3d6b2") if k != 1 else Color("cdbf98"))   # o painel do meio fica na sombra da dobra
	for x in range(4, int(r.size.x) - 4, 10):   # quadras
		for y in range(4, int(r.size.y) - 4, 8):
			draw_rect(Rect2(r.position.x + x, r.position.y + y, 7, 5), Color(0.62, 0.55, 0.4, 0.55))
	draw_polyline(PackedVector2Array([r.position + Vector2(2, r.size.y - 6), r.position + Vector2(30, r.size.y - 12),
		r.position + Vector2(58, r.size.y - 9), r.position + Vector2(r.size.x - 2, 6)]), Color("4f7bb6"), 2.0)   # o rio
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 2), Color(0.5, 0.42, 0.3, 0.6))   # a avenida
	for k in [1, 2]:   # as dobras
		draw_rect(Rect2(r.position.x + k * pw - 1, r.position.y, 1, r.size.y), Color(0, 0, 0, 0.25))
		draw_rect(Rect2(r.position.x + k * pw, r.position.y, 1, r.size.y), Color(1, 1, 1, 0.25))
	var pin := r.position + Vector2(r.size.x * 0.7, r.size.y * 0.42)   # o alfinete no local marcado
	draw_circle(pin + Vector2(2, 2), 2.5, Color(0, 0, 0, 0.35))
	draw_circle(pin, 2.5, Color("b03a2e"))
	draw_circle(pin - Vector2(0.8, 0.8), 1.0, Color("e07060"))


## O caderno de ocorrências aberto: capa de couro em volta, duas páginas pautadas com margem vermelha e anotações à
## mão, a sombra da lombada no meio e o lápis apoiado na página da direita.
func _draw_open_notebook(r: Rect2) -> void:
	draw_rect(r.grow(1), Color.BLACK)
	draw_rect(r, Color("4a2f1c"))   # a capa
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color("6b4529"))
	var half := floorf(r.size.x / 2.0)
	for k in 2:
		var pg := Rect2(r.position.x + 2 + k * half, r.position.y + 2, half - 4, r.size.y - 4)
		draw_rect(pg, Color("ece2c6"))
		for y in range(6, int(pg.size.y) - 1, 4):   # a pauta
			draw_rect(Rect2(pg.position.x, pg.position.y + y, pg.size.x, 1), Color("c8d0d0"))
		draw_rect(Rect2(pg.position.x + 6, pg.position.y, 1, pg.size.y), Color("d88a7a"))   # a margem
		for y in range(5, int(pg.size.y) - 4, 4):   # a letra de mão, linha por linha
			var n := 3 + (y * 7 + k * 5) % 4
			var lx := pg.position.x + 9
			for w in n:
				var ww := 3 + (y * 3 + w * 5 + k) % 6
				if lx + ww > pg.end.x - 3:
					break
				draw_rect(Rect2(lx, pg.position.y + y, ww, 1), Color("3a3a4a"))
				lx += ww + 2
	for i in 4:   # a sombra da lombada
		draw_rect(Rect2(r.position.x + half - 2 + i, r.position.y + 2, 1, r.size.y - 4), Color(0, 0, 0, 0.3 - absf(i - 1.5) * 0.1))
	# o lápis, na diagonal sobre a página da direita
	var a := r.position + Vector2(half + 14, r.size.y - 6)
	var b := r.position + Vector2(r.size.x - 6, 8)
	draw_line(a + Vector2(2, 2), b + Vector2(2, 2), Color(0, 0, 0, 0.3), 4.0)
	draw_line(a, b, Color("b48c1c"), 4.0)
	draw_line(a + Vector2(-1, -1), b + Vector2(-1, -1), Color("e6c24c"), 1.0)
	var d := (b - a).normalized()
	draw_line(b, b + d * 4, Color("8e897c"), 4.0)   # a ponteira de metal
	draw_line(b + d * 4, b + d * 7, Color("d88a8a"), 4.0)   # a borracha
	draw_line(a, a - d * 5, Color("d8b88a"), 3.0)   # a madeira apontada
	draw_line(a - d * 4, a - d * 6, Color("2a2a2a"), 1.5)   # o grafite


## A prancheta do registro: tábua de duratex com os cantos cortados, a folha datilografada com o cabeçalho e o
## prendedor niquelado com os rebites.
func _draw_clipboard(r: Rect2) -> void:
	var board := PackedVector2Array([r.position + Vector2(3, 0), Vector2(r.end.x - 3, r.position.y), Vector2(r.end.x, r.position.y + 3),
		r.end - Vector2(0, 3), r.end - Vector2(3, 0), Vector2(r.position.x + 3, r.end.y), Vector2(r.position.x, r.end.y - 3), r.position + Vector2(0, 3)])
	draw_colored_polygon(Geometry2D.offset_polygon(board, 1.0)[0], Color.BLACK)
	draw_colored_polygon(board, Color("7a5230"))
	draw_rect(Rect2(r.position.x + 3, r.position.y + 1, r.size.x - 6, 1), Color("9a6a40"))
	var paper := Rect2(r.position.x + 5, r.position.y + 7, r.size.x - 10, r.size.y - 11)
	draw_rect(Rect2(paper.position + Vector2(1, 1), paper.size), Color(0, 0, 0, 0.25))
	draw_rect(paper, Color("ece2c6"))
	draw_rect(Rect2(paper.position.x + 3, paper.position.y + 6, paper.size.x - 6, 2), Color("8e2a22"))   # o cabeçalho
	for y in range(11, int(paper.size.y) - 2, 3):   # as linhas datilografadas
		var w := paper.size.x - 8 - (y * 7) % 13
		draw_rect(Rect2(paper.position.x + 4, paper.position.y + y, w, 1), Color("4a4438"))
	# o prendedor
	var cx := r.get_center().x
	draw_rect(Rect2(cx - 12, r.position.y - 1, 24, 9), Color.BLACK)
	draw_rect(Rect2(cx - 11, r.position.y, 22, 7), Color("8e897c"))
	draw_rect(Rect2(cx - 11, r.position.y, 22, 2), Color("d6d1c3"))
	draw_rect(Rect2(cx - 11, r.position.y + 6, 22, 1), Color("45413a"))
	draw_rect(Rect2(cx - 5, r.position.y + 2, 10, 3), Color("45413a"))   # a fenda da mola
	for rx in [cx - 8, cx + 7]:   # rebites
		draw_circle(Vector2(rx, r.position.y + 4), 1.3, Color("d6d1c3"))


# ---------------------------------------------------------------- luminária

## Luminária pendurada sobre a mesa comutadora (o `%Glow` do Main é a luz dela; na parede, `_draw_wall_light`).
func _draw_lamp(lx: float) -> void:
	_r(lx, 0, 2, 8, Color("111111"))
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 8, 8), Vector2(lx + 10, 8), Vector2(lx + 22, 22), Vector2(lx - 20, 22)]), Color("34422e"))
	_r(lx - 6, 9, 4, 3, Color("50623f"))
	_r(lx - 12, 15, 6, 3, Color("50623f"))
	_r(lx - 12, 22, 26, 3, Color(1.0, (200.0 + 30.0 * lamp_level) / 255.0, 140.0 / 255.0, 0.35 + 0.65 * lamp_level))
