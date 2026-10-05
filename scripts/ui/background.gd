class_name Background
extends Control
## O cenário atrás da interface, esticado até a borda da tela e em pixels de 2x2: ele é desenhado numa tela própria com
## metade da resolução (`SceneView`), nas coordenadas da interface, e ampliado com "nearest" (as contas e a arte em
## unidades de 2 px, "px de 2x2"; o que é desenhado em px da tela, como os objetos da mesa, cai na mesma grade; a
## interface, na frente, fica na resolução da tela): o canto de uma sala vista por quem
## está sentado à mesa. Uma câmera só, em perspectiva de um ponto (`_vp`, perto dos objetos da mesa e na altura dos
## olhos, `EYE` acima do fundo do tampo; `_proj`/`_p3` levam um ponto da sala para a tela): a parede do fundo, com um
## armário de aço de chão atrás da mesa (a base fica escondida por ela; o relógio da sala é o `WallClock`, na parede
## acima da mesa comutadora, sempre à vista); a parede da direita, entrando para o fundo a partir da quina (`CORNER`), com a janela vista de lado; a mesa de madeira, afastada da
## parede (`DESK_T`), que termina na parede da direita, com a mesa comutadora em pé nela (um móvel só: o console, cuja
## frente é a faixa de mesa, e o painel na prateleira dele, `_draw_switchboard`). A luz vem de cima, do meio da tela, de
## uma luminária que não aparece (o desenho dela tirava a atenção): o arco na parede, a poça na mesa e as sombras.
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
## mesa, e passam pela mesma câmera (tamanho, escorço e o lado que aparece saem da conta), com o detalhe na grade de
## 2 px (`_flat` com `coarse`). Sob o mouse (o `SceneView` repassa, `pointer`), ganham contorno, o nome da ferramenta e o
## cursor de dedo (`draw_hover`); o clique só vale sobre eles (`prop_at`) e não com o papel de uma ferramenta por cima.

signal prop_clicked(id: String)

const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]   ## madeira (luz, meio, sombra), a mesma do móvel
const LIT := [Color("d59a3d"), Color("b38a3c"), Color("e2b25a")]   ## janelas acesas da cidade
const PROPS := {"lista": T.Key.TAB_DIRECTORY, "despacho": T.Key.TAB_DISPATCH, "caderno": T.Key.TAB_LOGBOOK, "registro": T.Key.TAB_CALL_LOG,
	"jornal": T.Key.TAB_NEWS}
const DETAILS := ["cartaz_quermesse", "numero_anotado", "armario_entreaberto"]   ## o que `RoomChange.detail` pode pedir
const SKY := {"rain": Color("0b141c"), "fog": Color("1b252b"), "clear": Color("0a1422")}
const BOARD_SINK := 30.0   ## o fundo do tampo, em px da tela acima da base do painel: fica atrás da mesa comutadora
const LAMP_Y := -30.0      ## a boca da luminária, acima da tela (px de 2x2): de onde sai a luz e saem as sombras na parede
const WALL_GAP := 40.0     ## quanto a luminária fica à frente da parede (px de 2x2): abre o arco de luz nela
# A câmera. Medidas da sala na escala da parede do fundo (px de 2x2 lá; ~0,56 cm): x para a direita e y para baixo a
# partir dos olhos, z a distância deles (a parede fica a `Z0`; mais perto, tudo cresce Z0/z vezes).
const VP_X := 0.55      ## o ponto de fuga na largura da tela: perto dos objetos da mesa (longe dele, eles entortam)
const EYE := 210.0      ## a altura dos olhos acima do fundo do tampo, na tela (px de 2x2): o ponto de fuga, logo acima da
                        ## tela (olhando a mesa de cima, de perto: com ele mais baixo, o que fica longe dele entortava demais)
const Z0 := 330.0       ## a distância dos olhos à parede do fundo
const DESK_T := 1.25    ## o fundo do tampo, Z0/DESK_T: a mesa fica afastada da parede (o armário cabe atrás)
const CORNER := 0.64    ## a quina das paredes, na largura da área das ferramentas
const BOARD_D := 14.0   ## o fundo do painel da mesa comutadora (z), atrás da prateleira: raso, como o das mesas de verdade (o corpo do móvel é o console); a lateral dele foge para o ponto de fuga
const PLANKS := 6       ## as tábuas do tampo, todas da mesma largura (a câmera as espaça)
const POOL_R := 150.0   ## o raio da poça de luz da luminária no tampo
const CAB_X := Vector2(-53, 57)  ## o armário de aço: de onde a onde (x), encostado na parede
const CAB_TOP := 29.0            ## o alto dele (y, a partir dos olhos): um pouco abaixo deles, o tampo aparece
const CAB_T := 1.15              ## a frente dele (escala): ~35 cm de fundo
const SIDE_T := 1.06        ## onde a janela começa na parede da direita (escala); termina perto da borda da tela
const SIDE_W := 150.0       ## a largura do vão, de frente (só a resolução da projeção)
const WIN_TOP := -8.0       ## o alto do vão (y, a partir dos olhos): logo acima deles, passando da borda de cima
const WIN_SILL := 26.0      ## quanto o peitoril fica acima do tampo (y)

@export var window: Control   ## a área das ferramentas: a quina e a janela ficam na parede dela
@export var desk: Control     ## a faixa do rádio, a frente do console da mesa comutadora: a borda da frente do tampo fica logo abaixo dela
@export var board: Control    ## o painel da mesa comutadora: pousa na prateleira do console; o fundo do tampo fica `BOARD_SINK` px acima da base dele
@export var wall_art: Texture2D     ## imagem da parede (repetida), no lugar do desenho
@export var window_art: Texture2D   ## imagem da vista da janela (esticada, de frente), no lugar da cidade desenhada
@export var desk_art: Texture2D     ## imagem da madeira da mesa (repetida), no lugar do desenho

var flick := false
var lamp_level := 1.0
var weather := "rain"
var shadow := false
# O estado do jogo nos objetos da mesa, para ler de relance sem abrir nada (o Main atualiza):
var pending := 0     ## registros esperando no caderno: uma tira de papel saindo dele por registro
var alert := -1      ## estágio da emergência em andamento (-1 = nenhuma): o alfinete do mapa pisca, mais rápido se piora
var unread := false  ## o registro das conversas tem fala nova: uma folha nova presa na prancheta
var news := false    ## o jornal da manhã está na mesa (da segunda noite em diante; `Main.set_news`)
# A sala muda ao longo das noites (o Main atualiza): os detalhes valendo (`RoomChange.detail`) e a noite (o calendário
# do armário risca um dia por noite).
var details := PackedStringArray()
var night := 1
var _drops: Array = []
var _stars: Array[Vector2] = []
var _city: Array = []          # prédios da vista: {x, w, h, roof, lit: [Vector2...]} (em frações e px do vidro)
var _city_for := Vector2.ZERO  # tamanho do vidro para o qual `_city` foi montada
var _mist := 0.0
var _win := Vector2(104, 38)   # a vista da janela, em pixels de 2x2 (do último desenho)
var _acc := 0.0
var _props := {}       # objeto que abre ferramenta -> retângulo dele (px da tela), do último desenho
var _hot := ""         # objeto sob o mouse
var _lamp_x := 0.0     # onde está a luminária, no meio da tela (px de 2x2): a luz na mesa e a sombra dos objetos dependem dela
var _vp := Vector2.ZERO   # o ponto de fuga (px de 2x2)
var _yd := 0.0         # a altura do tampo (y da sala, abaixo dos olhos)
var _zd := Vector2.ZERO   # a frente e o fundo do tampo (z)
var _side_x := 0.0     # a lateral da mesa comutadora na sala (x): os objetos da mesa ficam à direita dela
var _cx := 0.0         # a quina das paredes (px de 2x2, na tela)
var _t2 := 1.6         # onde a janela termina na parede da direita (escala)
var _ci: CanvasItem    # onde a vista da janela é desenhada: aqui, ou no vidro fora da tela
var _view: Control     # desenha a vista da janela no `_vport`
var _vport: SubViewport
var _paint_xf := Transform2D()   # a perspectiva do objeto chato sendo desenhado (`_flat`): luzes dele na tela
var _cover := Rect2()   # onde está o papel da ferramenta aberta (px da tela, não de 2x2): luz embaixo dele não brilha
var _drawn := []        # o `_state` do último desenho da sala


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # o mouse chega pelo `SceneView`
	_ci = self
	_vport = SubViewport.new()
	_vport.size = Vector2i(64, 64)
	_vport.render_target_update_mode = SubViewport.UPDATE_ONCE   # a cada quadro da vista (`_process`)
	_view = Control.new()
	_view.draw.connect(_draw_view)
	_vport.add_child(_view)
	add_child(_vport)
	for i in 120:   # gotas e estrelas em frações do vidro: a janela muda de tamanho com a tela
		_drops.append(Vector3(randf(), randf(), 0.6 + randf() * 0.7))
	for i in 30:
		_stars.append(Vector2(randf() * 0.95 + 0.02, randf() * 0.45 + 0.03))


## A sala só se redesenha quando algo que ela mostra muda (`_state`): parada, ela custa só o desenho já guardado. A
## vista da janela (chuva, névoa, estrelas) anda a 30 quadros por segundo no vidro fora da tela, sem redesenhar a sala.
func _process(delta: float) -> void:
	var st := _state()
	if st != _drawn:   # (o papel deslizando entra aqui: o corte do brilho acompanha já neste quadro)
		_drawn = st
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
	_view.queue_redraw()
	_vport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Tudo de que o desenho da sala depende (fora o mouse, que redesenha sozinho): onde a interface pôs as coisas, o
## papel da ferramenta, a luminária, o alfinete e o estado do jogo nos objetos.
func _state() -> Array:
	return [size, board.get_global_rect() if board else Rect2(), desk.get_global_rect() if desk else Rect2(),
		window.get_global_rect() if window else Rect2(), _paper(), lamp_level, _pin_lit(), pending, unread, news,
		details, night, weather]


## O alfinete do mapa aceso: com uma emergência em andamento ele pisca, mais rápido a cada estágio.
func _pin_lit() -> bool:
	return alert >= 0 and int(Time.get_ticks_msec() / (420.0 - alert * 90.0)) % 2 == 0


## Onde está o papel da ferramenta aberta ou vindo do objeto (px da tela; vazio com tudo guardado).
func _paper() -> Rect2:
	for n in window.get_children() if window else []:
		if n is Control and n.visible:
			return (n as Control).get_global_transform() * Rect2(Vector2.ZERO, n.size)
	return Rect2()


## Onde fica na tela (global) o objeto da mesa que abre a ferramenta `id` (vazio se ele não está na mesa): de onde o
## papel dela sai (`Tools.origin`).
func prop_rect(id: String) -> Rect2:
	return Rect2(global_position + (_props[id] as Rect2).position, (_props[id] as Rect2).size) if _props.has(id) else Rect2()


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
	_lamp_x = floorf(w / 2.0)
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
	if "cartaz_quermesse" in details:
		_draw_poster(Rect2(floorf((cab.end.x + _cx) / 2.0) - 15, 34, 30, 38))
	_zd = Vector2(Z0 * _yd / (front - _vp.y), Z0 / DESK_T)
	_draw_desk(Rect2(0, top, w, h - top), front)
	_draw_switchboard(front)
	_draw_side_wall(top, front, w)
	_draw_desk_props()
	if _cover.has_area():   # uma ferramenta na frente do operador: o cenário atrás escurece e o papel faz sombra nele
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(_cover.position + Vector2(10, 12), _cover.size), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.28))


## O objeto sob o mouse: contorno e o nome da ferramenta que ele abre, desenhados em `ci` (o `SceneView`, por cima do
## cenário e na resolução da interface: o texto fica nítido).
func draw_hover(ci: CanvasItem) -> void:
	if _hot == "" or not _props.has(_hot):
		return
	var hr: Rect2 = _props[_hot]
	ci.draw_rect(hr.grow(2), Color(Pal.GLOW, 0.8), false, 2.0)
	var cap := T.text(PROPS[_hot])
	var cw := Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var at := Vector2(clampf(hr.get_center().x - cw / 2.0 - 5, 4, size.x - cw - 14), hr.position.y - 22)
	ci.draw_rect(Rect2(at, Vector2(cw + 10, 16)), Color(0, 0, 0, 0.8))
	ci.draw_string(Pal.ui, at + Vector2(5, 12), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT)


## O objeto da cena em `p` (px da tela), ou "" (nenhum, ou o papel de uma ferramenta por cima).
func prop_at(p: Vector2) -> String:
	if _cover.has_point(p):
		return ""
	for id in _props:
		if (_props[id] as Rect2).grow(2).has_point(p):
			return id
	return ""


## O mouse no cenário (o `SceneView` repassa: o cenário fica numa tela própria, fora da árvore da interface).
## Devolve se o evento foi usado (o clique num objeto).
func pointer(e: InputEvent) -> bool:
	if e is InputEventMouseMotion:
		var id := prop_at(e.position)
		if id != _hot:
			_hot = id
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id := prop_at(e.position)
		if id != "":
			prop_clicked.emit(id)
			return true
	return false


## O objeto sob o mouse ("" = nenhum).
func hot() -> String:
	return _hot


## O mouse saiu de cima do cenário.
func leave() -> void:
	if _hot != "":
		_hot = ""
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
	for x in range(0, int(r.size.x), 22):   # as listras: a larga com o fio de luz e, no meio, a fina
		_r(x, 0, 2, r.size.y, Color("141c1f"))
		_r(x + 2, 0, 1, r.size.y, Color("1b2629"))
		_r(x + 11, 0, 1, r.size.y, Color("1a2427"))
	var frieze := Color("1e2a2d")   # o friso no alto: dois fios e os losangos entre eles
	_r(0, 3, r.size.x, 1, frieze)
	_r(0, 9, r.size.x, 1, frieze)
	for x in range(0, int(r.size.x), 11):
		_r(x + 5, 5, 1, 1, frieze)
		_r(x + 4, 6, 3, 1, frieze)
		_r(x + 5, 7, 1, 1, frieze)


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


## Calendário de folhinha: cabeçalho vermelho e a grade dos dias, um deles riscado.
func _draw_calendar(r: Rect2) -> void:
	_cast(r, 1.01)
	_r(r.position.x, r.position.y, r.size.x, r.size.y, Color("e3d6b2"))
	_r(r.position.x, r.position.y, r.size.x, 6, Color("8e2a22"))   # o cabeçalho com o mês
	_r(r.position.x + 5, r.position.y + 2, r.size.x - 10, 1, Color("e3d6b2"))
	for k in 20:   # os dias; os que já passaram (uma noite cada) ficam riscados de vermelho
		var d := Vector2(r.position.x + 2 + (k % 5) * 4, r.position.y + 9 + (k / 5) * 4)
		_r(d.x, d.y, 2, 2, Color("8a7d62"))
		if k < night - 1:
			_r(d.x - 1, d.y + 1, 4, 1, Color("b03a2e"))
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


## A vista da janela, de frente, no vidro fora da tela (`_vport`, do tamanho da janela na tela, em px de 2x2).
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


## A mesa comutadora é um móvel só, em pé no tampo: embaixo, o console, cuja frente é a faixa de mesa (`desk`, com o
## rádio embutido) e cujo alto é a prateleira, onde ficam o encaixe do FONE e os buracos dos cabos com os plugs em pé
## (a mesa desenha); no fundo da prateleira, o painel (`board`). A interface é a frente do painel e do rádio; aqui
## ficam a frente do console em volta dele, a prateleira com o rodapé e a sombra do painel, a lateral em L virada para o ponto de fuga (o console até o fundo do móvel,
## `BOARD_D`, e o painel em cima dele) e, com os olhos acima dele, o tampo do painel. Painel e console têm a mesma
## largura na sala: o console, mais perto, sai mais largo na tela (a esquerda passa da borda). Em px da tela (1x1).
func _draw_switchboard(front: float) -> void:
	if not (board and desk):
		return
	draw_set_transform(Vector2.ZERO)
	var vp := _vp * 2.0
	var b := Rect2(board.global_position - global_position, board.size)
	var sy := desk.global_position.y - global_position.y   # a prateleira, no alto da faixa de mesa
	var fy := front * 2.0                                  # o pé do console, na borda da frente do tampo
	var k := (b.end.y - vp.y) / maxf(1.0, sy - vp.y)       # quanto o painel encolhe visto da frente do console
	var zp := _zd.x / k                                    # o painel (z): o console começa na frente do tampo
	var kb := zp / (zp + BOARD_D)
	_side_x = (b.end.x / 2.0 - _vp.x) * zp / Z0
	var near := func(p: Vector2) -> Vector2: return vp + (p - vp) / k    # da linha do painel para a frente
	var back := func(p: Vector2) -> Vector2: return vp + (p - vp) * kb   # da linha do painel para o fundo
	var fx0: float = near.call(Vector2(b.position.x, b.end.y)).x
	var fx1: float = near.call(b.end).x
	var low := Vector2(fx1, fy)   # o canto de baixo da frente, do lado do ponto de fuga
	var deep := func(p: Vector2) -> Vector2: return vp + (p - vp) * k * kb   # da frente do console para o fundo
	var low_back: Vector2 = deep.call(low)
	_desk_shadow(PackedVector2Array([Vector2(fx0, fy), low, low_back, deep.call(Vector2(fx0, fy))]))
	if b.end.x < vp.x - 2.0:   # a lateral em L: o console e, em cima dele, o painel
		var side := WOOD[2] as Color
		_poly(PackedVector2Array([Vector2(fx1, sy), low, low_back, back.call(b.end)]), side)
		_poly(PackedVector2Array([Vector2(b.end.x, b.position.y), b.end, back.call(b.end), back.call(Vector2(b.end.x, b.position.y))]), side)
		for i in range(1, 7):   # o veio, no rumo do ponto de fuga
			var p := Vector2(b.end.x, b.position.y + b.size.y * i / 7.0 + (i % 2) * 5.0)
			draw_line(p, back.call(p), WOOD[1], 2.0)
		for y in [sy + (fy - sy) * 0.4, sy + (fy - sy) * 0.75]:
			draw_line(Vector2(fx1, y), deep.call(Vector2(fx1, y)), WOOD[1], 2.0)
		draw_line(Vector2(b.end.x, b.position.y), b.end, WOOD[0], 2.0)   # as quinas da frente pegam a luz
		draw_line(Vector2(fx1, sy), low, WOOD[0], 2.0)
	# a frente do console (aparece entre as peças embutidas), com a beira de cima e o rodapé
	_r(fx0, sy, fx1 - fx0, fy - sy, WOOD[1])
	_r(fx0, sy, fx1 - fx0, 2, WOOD[0])
	_r(fx0, fy - 4, fx1 - fx0, 4, WOOD[2])
	# a prateleira: o painel pousa no fundo dela, num rodapé, com a sombra de contato na frente
	_poly(PackedVector2Array([Vector2(fx0, sy), Vector2(fx1, sy), b.end, Vector2(b.position.x, b.end.y)]), Color("5a3a22"))
	for t in [0.3, 0.55, 0.8]:   # os veios da prateleira, de lado a lado
		var y := floorf(lerpf(sy, b.end.y, t) / 2.0) * 2.0   # (na grade de 2 px)
		_r(lerpf(fx0, b.position.x, t), y, lerpf(fx1, b.end.x, t) - lerpf(fx0, b.position.x, t), 2, Color("4e321d"))
	_r(fx0, sy - 2, fx1 - fx0, 2, Color("a8873e"))   # o friso de latão na beira
	var radio := desk.get_node_or_null("Radio") as Control
	if radio and radio.visible:   # na frente do console, em volta do rádio: a plaqueta e os botões dele
		var rr := Rect2(radio.global_position - global_position, radio.size)
		var my := floorf((sy + fy) / 4.0) * 2.0
		var plate := Rect2(floorf((rr.position.x - 74) / 2.0) * 2.0, my - 8, 56, 16)
		draw_rect(Rect2(plate.position + Vector2(2, 2), plate.size), Color(0, 0, 0, 0.35))
		draw_rect(plate, Color("8a6a2e"))
		draw_rect(Rect2(plate.position, Vector2(plate.size.x, 2)), Color("c4a35a"))
		for i in 2:   # o nome gravado (as letras não se leem dessa distância)
			draw_rect(Rect2(plate.position.x + 8, plate.position.y + 6 + i * 4, plate.size.x - 16 - i * 12, 2), Color("4a3a18"))
		for i in 2:
			var c := Vector2(floorf(rr.end.x / 2.0) * 2.0 + 24 + i * 30, my)
			draw_circle(c + Vector2(2, 2), 9.0, Color(0, 0, 0, 0.35))
			draw_circle(c, 8.0, Color("2a2420"))
			draw_arc(c, 6.0, PI * 1.05, PI * 1.6, 8, Color("4a4038"), 2.0)   # a luz na borda
			var a := -PI * 0.75 + i * 1.1
			draw_line(c, c + Vector2(cos(a), sin(a)) * 6.0, Color("d6d1c3"), 2.0)   # o risco de posição
	for p in [Vector2(fx1 - 8, sy + 8), Vector2(fx1 - 8, fy - 10), Vector2(8, sy + 8), Vector2(8, fy - 10)]:   # os parafusos
		if p.x > fx0 + 4:
			draw_rect(Rect2((p / 2.0).floor() * 2.0, Vector2(4, 4)), Color("2a1a0f"))
	draw_rect(Rect2(b.position.x, b.end.y, b.size.x, 4), WOOD[2])
	draw_colored_polygon(PackedVector2Array([Vector2(b.position.x, b.end.y + 3), Vector2(b.end.x, b.end.y + 3),
		Vector2(b.end.x + 2, b.end.y + 7), Vector2(b.position.x - 3, b.end.y + 7)]), Color(0, 0, 0, 0.3))
	if b.position.y > vp.y + 1.0:   # os olhos estão acima do painel: o tampo dele aparece
		var tl := b.position
		var tr := Vector2(b.end.x, b.position.y)
		_poly(PackedVector2Array([tl, tr, back.call(tr), back.call(tl)]), WOOD[0])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


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
		_r(roundf(x), 0, maxf(1.0, roundf(1.5 * t)), roundf(bottom), Color("1b2629"))   # mais perto, mais larga
		k += 1
	for fy in [3.5, 9.5]:   # o friso: os dois fios, subindo para fora da tela
		draw_line(Vector2(_cx, fy), Vector2(w, _vp.y + (fy - _vp.y) * te), Color("26353a"), 1.0)
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
	for y in range(0, int(blind), 3):   # as lâminas: a face clara e a sombra embaixo
		draw_colored_polygon(_side_quad(Rect2(0, y, gw, 2)), Color("8a8070"))
		draw_colored_polygon(_side_quad(Rect2(0, y + 2, gw, 1)), Color("4a4438"))
	draw_line(_side_pt(Vector2(gw * 0.8, blind)), _side_pt(Vector2(gw * 0.8, blind + 8)), Color("8a8070"), 1.0)   # o cordão
	draw_colored_polygon(_side_quad(Rect2(gw * 0.8 - 1, blind + 8, 2, 2)), Color("6b5f4c"))   # o puxador dele
	# o vão: perto da quina aparece o lado de dentro do batente (virado para quem olha), o peitoril e a verga
	draw_colored_polygon(_side_quad(Rect2(0, 0, 10, gh)), Color("223033"))
	draw_line(_side_pt(Vector2(10, 0)), _side_pt(Vector2(10, gh)), Color(0, 0, 0, 0.4), 1.0)
	draw_colored_polygon(_side_quad(Rect2(0, gh - 3, gw, 3)), Color("2c3a3c"))
	draw_colored_polygon(_side_quad(Rect2(0, 0, gw, 2)), Color("0d1315"))
	# o peitoril de fora e o vaso
	draw_colored_polygon(_side_quad(Rect2(-8, gh + 4, gw + 16, 3)), WOOD[0])
	draw_colored_polygon(_side_quad(Rect2(-8, gh + 7, gw + 16, 2)), WOOD[2])
	var pp := _side_pt(Vector2(gw * 0.82, gh + 4)).round()
	_r(pp.x, pp.y - 8, 9, 2, Color("9a542f"))   # o vaso de barro, com a borda
	_r(pp.x, pp.y - 8, 9, 1, Color("b8683c"))
	_r(pp.x + 1, pp.y - 6, 7, 6, Color("8a4a2a"))
	_r(pp.x + 1, pp.y - 6, 1, 6, Color("a05a34"))
	_r(pp.x + 4, pp.y - 11, 1, 3, Color("2c4224"))   # o caule
	for leaf in [Vector2(-3, -13), Vector2(1, -16), Vector2(5, -14), Vector2(8, -11), Vector2(-1, -11)]:
		_r(pp.x + leaf.x, pp.y + leaf.y, 4, 2, Color("3d5a32"))
		_r(pp.x + leaf.x + 1, pp.y + leaf.y, 2, 1, Color("5a7a46"))


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
	if CAB_TOP > 0.0:   # os olhos acima dele: o tampo aparece, fugindo para a parede
		draw_colored_polygon(PackedVector2Array([back.position + Vector2(-2, 0), Vector2(back.end.x + 2, back.position.y),
			Vector2(f.end.x + 2, f.position.y - 1), Vector2(f.position.x - 2, f.position.y - 1)]), steel.darkened(0.2))
	_r(f.position.x, f.position.y, f.size.x, f.size.y, steel)
	for i in 3:   # a luz da luminária, mais forte do lado dela
		_r(f.position.x + i * 6, f.position.y, 6, f.size.y, Color(1.0, 0.85, 0.6, 0.03 * (3 - i) * lamp_level))
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, 5, steel.darkened(0.15))   # a cornija, com o friso
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, 1, steel.lightened(0.3))
	_r(f.position.x - 2, f.position.y + 4, f.size.x + 4, 1, Color("23281f"))
	_r(f.position.x, f.position.y + 5, 1, f.size.y, steel.lightened(0.15))   # a luz à esquerda, a sombra à direita
	_r(f.end.x - 1, f.position.y + 5, 1, f.size.y, steel.darkened(0.3))
	var mid := floorf(f.get_center().x)
	var doors := f.position.y + 8
	_r(mid - 1, doors, 1, f.size.y, Color("23281f"))   # a fresta entre as portas
	_r(mid, doors, 1, f.size.y, steel.lightened(0.12))
	for door in [Rect2(f.position.x + 3, doors, mid - f.position.x - 5, 60), Rect2(mid + 2, doors, f.end.x - mid - 5, 60)]:
		for i in 6:   # as venezianas, no alto de cada porta: a fenda e a aba que pega a luz
			_r(door.position.x + 6, door.position.y + 4 + i * 4, door.size.x - 12, 2, Color("2e342b"))
			_r(door.position.x + 6, door.position.y + 6 + i * 4, door.size.x - 12, 1, steel.lightened(0.2))
	# o porta-etiqueta na porta da esquerda, com o cartão datilografado
	var lab := Rect2(f.position.x + 12, doors + 34, 24, 11)
	_r(lab.position.x - 1, lab.position.y - 1, lab.size.x + 2, lab.size.y + 2, Color("8e897c"))
	_r(lab.position.x, lab.position.y, lab.size.x, lab.size.y, Color("e3d6b2"))
	_r(lab.position.x + 3, lab.position.y + 3, lab.size.x - 6, 1, Color("4a4438"))
	_r(lab.position.x + 3, lab.position.y + 6, lab.size.x - 11, 1, Color("4a4438"))
	# o puxador e a fechadura, junto da fresta, na altura da mão
	var hy := doors + 40.0
	_r(mid + 4, hy, 3, 16, Color("3a3d33"))
	_r(mid + 4, hy, 2, 15, Color("d6d1c3"))
	_r(mid + 4, hy - 7, 3, 3, Color("8e897c"))
	_r(mid + 5, hy - 6, 1, 1, Color("23281f"))
	for y in [doors + 4, doors + 70]:   # as dobradiças
		_r(f.position.x - 1, y, 2, 7, Color("8e897c"))
		_r(f.end.x - 1, y, 2, 7, Color("8e897c"))
		_r(f.position.x - 1, y + 3, 2, 1, Color("4a4840"))
		_r(f.end.x - 1, y + 3, 2, 1, Color("4a4840"))
	if "armario_entreaberto" in details:   # a porta da direita aberta: o vão com as prateleiras e as pastas, a porta de lado
		var inside := Rect2(mid + 1, doors, f.end.x - mid - 1, f.end.y - doors)
		var bk := func(p: Vector2) -> Vector2: return _vp + (p - _vp) / CAB_T   # o fundo do armário, na parede
		var tl := inside.position
		var tr := Vector2(inside.end.x, inside.position.y)
		var bl := Vector2(inside.position.x, inside.end.y)
		_r(inside.position.x, inside.position.y, inside.size.x, inside.size.y, Color("0d110d"))
		draw_colored_polygon(PackedVector2Array([bk.call(tl), bk.call(tr), bk.call(inside.end), bk.call(bl)]), Color("151a14"))   # o fundo
		# a parede de dentro virada para quem olha (o vão fica à direita do ponto de fuga)
		draw_colored_polygon(PackedVector2Array([tr, bk.call(tr), bk.call(inside.end), inside.end]), Color("1d241c"))
		_r(inside.position.x, inside.position.y, inside.size.x, 3, Color(0, 0, 0, 0.5))   # a sombra do alto
		for k in 3:   # as prateleiras (os olhos acima delas: o tampo aparece) com pastas e caixas de arquivo
			var sy := doors + 24.0 + k * 30.0
			var a := Vector2(inside.position.x, sy)
			var c := Vector2(inside.end.x, sy)
			draw_colored_polygon(PackedVector2Array([a, c, bk.call(c), bk.call(a)]), Color("3a4236"))
			_r(a.x, sy, inside.size.x, 2, steel.darkened(0.2))   # a beira da prateleira
			_r(a.x, sy, inside.size.x, 1, steel.lightened(0.1))
			var px := inside.position.x + 3
			var n := k * 3   # a próxima pasta (a cor e o tamanho variam por ela)
			var base: float = floorf(sy - 1.0 + ((bk.call(a) as Vector2).y - sy) * 0.4)   # em pé um pouco para dentro
			while px < inside.end.x - 6:
				var pw := 3.0 + (n * 7) % 3
				var ph := 14.0 + (n * 5) % 8
				var col: Color = [Color("6e5a3a"), Color("8a7a5a"), Color("4a5a6a"), Color("7a3a2a"), Color("6e5a3a")][(n * 3) % 5]
				n += 1
				_r(px, base - ph, pw, ph, col)
				_r(px, base - ph, 1, ph, col.lightened(0.2))   # a lombada pega a luz
				_r(px + 1, base - ph + 3, pw - 2, 2, Color("e3d6b2"))   # a etiqueta
				px += pw + 1
		# a porta aberta, de lado: a face de dentro com o painel rebaixado e a beira (a espessura) pegando a luz
		var d0 := Vector2(f.end.x, doors - 1)
		var d1 := Vector2(f.end.x + 16, doors - 6)
		var d2 := Vector2(f.end.x + 16, f.end.y + 8)
		var d3 := Vector2(f.end.x, f.end.y)
		draw_colored_polygon(PackedVector2Array([d0, d1, d2, d3]), steel.darkened(0.1))
		draw_colored_polygon(PackedVector2Array([d0.lerp(d1, 0.25) + Vector2(0, 8), d1.lerp(d0, 0.25) + Vector2(0, 8),
			d2.lerp(d3, 0.25) - Vector2(0, 10), d3.lerp(d2, 0.25) - Vector2(0, 10)]), steel.darkened(0.25))
		draw_line(d1, d2, steel.lightened(0.25), 1.0)
		draw_line(d1 + Vector2(1, 0), d2 + Vector2(1, 0), steel.darkened(0.45), 1.0)
		var rod := d1.lerp(d0, 0.3)   # a haste da fechadura
		draw_line(rod + Vector2(0, 30), rod + Vector2(0, 52), Color("8e897c"), 1.0)
	else:
		_draw_calendar(Rect2(mid + 14, doors + 46, 24, 26))   # preso com ímã
	if "numero_anotado" in details:   # o número de quem ligou, anotado num bilhete e colado com fita
		var n := Rect2(f.position.x + 10, doors + 52, 26, 14)
		_cast(n, 1.01)
		_r(n.position.x, n.position.y, n.size.x, n.size.y, Color("efe6cc"))
		var ink := Color("2a2a4a")
		for k in 5:   # os algarismos, à mão: traços de um bloco
			var d := n.position + Vector2(2 + k * 5, 3 + k % 2)
			match k % 3:
				0:   # um "1"
					_r(d.x + 1, d.y, 1, 5, ink)
				1:   # um "7"
					_r(d.x, d.y, 3, 1, ink)
					_r(d.x + 2, d.y + 1, 1, 2, ink)
					_r(d.x + 1, d.y + 3, 1, 2, ink)
				_:   # um "0"
					_r(d.x, d.y, 3, 1, ink)
					_r(d.x, d.y + 4, 3, 1, ink)
					_r(d.x, d.y + 1, 1, 3, ink)
					_r(d.x + 2, d.y + 1, 1, 3, ink)
		_r(n.position.x + 2, n.position.y + 10, n.size.x - 4, 1, Color("b03a2e"))   # sublinhado
		_r(n.position.x - 2, n.position.y - 1, 6, 3, Color(1, 1, 1, 0.35))   # a fita
		_r(n.end.x - 4, n.position.y - 1, 6, 3, Color(1, 1, 1, 0.35))
	return f


## O cartaz da quermesse preso na parede (a pessoa prometeu ir): papel creme com bandeirinhas coloridas em zigue-zague,
## a fogueira e as linhas do convite.
func _draw_poster(r: Rect2) -> void:
	_cast(r, 1.01)
	_r(r.position.x, r.position.y, r.size.x, r.size.y, Color("e8dcc0"))
	var cols := [Color("b03a2e"), Color("e0b040"), Color("3a6aa0"), Color("4a8a4a")]
	for k in int(r.size.x / 5.0):   # as bandeirinhas
		var x := r.position.x + 1 + k * 5
		draw_colored_polygon(PackedVector2Array([Vector2(x, r.position.y + 3), Vector2(x + 4, r.position.y + 3), Vector2(x + 2, r.position.y + 7)]), cols[k % 4])
	_r(r.position.x + 1, r.position.y + 2, r.size.x - 2, 1, Color("5a4d3a"))   # o barbante
	var c := Vector2(r.get_center().x, r.position.y + 21)   # a fogueira
	draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 5), c + Vector2(0, -7), c + Vector2(6, 5)]), Color("e07a2a"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 5), c + Vector2(0, -2), c + Vector2(3, 5)]), Color("f0c040"))
	_r(c.x - 7, c.y + 5, 14, 1, Color("8a5a36"))   # as toras
	_r(c.x - 6, c.y + 6, 12, 1, Color("4a2f1c"))
	for k in 3:   # o convite
		_r(r.position.x + 4, r.position.y + 30 + k * 2, r.size.x - 8 - k * 4, 1, Color("5a4d3a"))
	_r(r.get_center().x - 1, r.position.y - 1, 2, 2, Color("b03a2e"))   # a tachinha


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
		for p in b["lit"]:   # as janelas acesas, com a travessa no meio
			flicked += 1
			if flick and flicked % 3 == 0:
				continue
			_r(bx + p.x, by + p.y, 2, 2, LIT[int(p.x + p.y) % LIT.size()])
	_draw_church(Vector2(wx + floorf(ww * 0.36), street), house)
	# a rua, o poste e o chão
	_r(wx, street, ww, 10, Color("10161b") if fog else Color("06090c"))
	_r(wx, street, ww, 1, Color("1d262c"))
	_r(wx, street + 3, ww, 1, Color("0c1115"))   # o meio-fio
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
				for k in 3:   # o reflexo, quebrado pelas poças
					_r(wx + b["x"] + p.x, street + 2 + k * 2, 2, 1, Color(LIT[0], 0.3 - k * 0.08))
		if on:
			for k in 4:
				_r(lamp.x - 1 + k % 2, street + 2 + k * 2, 2, 1, Color(1.0, 0.85, 0.55, 0.35 - k * 0.07))
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
				var dp := Vector2(g.position.x + floorf(d.x * g.size.x), g.position.y + floorf(d.y * (g.size.y - 3)))
				_r(dp.x, dp.y, 1, 2, Color("3a5563"))   # a gota escorrendo, com o brilho na ponta
				_r(dp.x, dp.y + 2, 1, 1, Color("6a8593"))
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
		# as emendas: tábuas da mesma largura, espaçadas pela câmera (mais juntas no fundo)
		var zb := Z0 / DESK_T
		var zf := Z0 * _yd / (front - _vp.y)
		for k in PLANKS:
			var y0 := floorf(_proj(0, _yd, lerpf(zb, zf, float(k) / PLANKS)).y)
			var y1 := floorf(_proj(0, _yd, lerpf(zb, zf, float(k + 1) / PLANKS)).y)
			_r(r.position.x, y1 - 1, r.size.x, 1, Color("1a120c"))
			_r(r.position.x, y0, r.size.x, 1, Color("2b2016"))   # a beira de cada tábua pega luz
			for i in int(r.size.x / 30.0):   # os veios, mais compridos na frente (mais perto)
				var gx := fmod(i * 97.0 + k * 31.0, r.size.x)
				var gy := floorf(y0 + (y1 - y0) * (0.3 + 0.4 * ((i + k) % 3) / 2.0))
				_r(gx, gy, 8 + (i % 4) * 5 + k * 5, 1, Color("2e2219"))
		for k in 2:   # o fundo escurece de leve (sem linha na quina: com ela parecia o rodapé de um chão)
			_r(r.position.x, r.position.y, r.size.x, depth * (0.16 - k * 0.08), Color(0, 0, 0, 0.04))
	# a luz da luminária: um círculo no tampo, embaixo dela (que fica um pouco à frente do fundo da mesa), em degraus,
	# mais forte no meio; o que passaria do fundo do tampo fica na parede (o arco de `_draw_wall_light`)
	var zb2 := Z0 / DESK_T
	var zl := zb2 * 0.85
	var lx := (_lamp_x - _vp.x) * zl / Z0
	for k in 4:
		var rr := POOL_R * (1.0 - k * 0.22)
		var pts := PackedVector2Array()
		for i in 32:
			var a := TAU * i / 32.0
			pts.append(_proj(lx + cos(a) * rr, _yd, clampf(zl + sin(a) * rr * 0.5, 40.0, zb2)))
		draw_colored_polygon(pts, Color(1.0, 0.78, 0.48, 0.035 * lamp_level))
	# a borda da frente: o canto arredondado do tampo pega a luz, a espessura dele e, embaixo, o escuro sob a mesa
	_r(r.position.x, front - 1, r.size.x, 1, Color("5a4030"))
	_r(r.position.x, front, r.size.x, 1, Color("6b4529"))
	_r(r.position.x, front + 1, r.size.x, 4, Color("3a2616"))
	_r(r.position.x, front + 2, r.size.x, 1, Color("442c1a"))   # um friso na espessura
	_r(r.position.x, front + 5, r.size.x, 1, Color("1a120c"))
	_r(r.position.x, front + 6, r.size.x, r.end.y - front - 6, Color("0a0705"))


## Na mesa, embaixo da janela, ao alcance do operador: as listas telefônicas, o caderno aberto, a caneca de café, a
## prancheta do registro e o mapa dobrado, do fundo para a frente (quem está mais perto é desenhado por cima). Cada um
## fica num lugar da sala (x a partir dos olhos, z a distância; ver `Z0`) e é desenhado em px da tela (1x1).
func _draw_desk_props() -> void:
	draw_set_transform(Vector2.ZERO)
	# em duas fileiras, a partir da lateral da mesa comutadora (numa tela mais larga, a folga sobra perto da janela),
	# com a caneca junto da parede da direita
	var l := _side_x + 8.0
	_draw_books(l, _at(0.5), 33, _deep(0.32))
	_flat("caderno", l + 44, _at(0.52), 51, _deep(0.28), 2, Color("3a2414"), _draw_open_notebook, true)
	if news:
		_flat("jornal", l + 106, _at(0.56), 37, _deep(0.21), 2, Color("b8b0a0"), _draw_newspaper, true)
	_draw_mug(_cx - _vp.x - 28.0, _at(0.42), 6.6, 15)
	_flat("despacho", l + 4, _at(0.08), 40, _deep(0.21), 1, Color("a89a76"), _draw_folded_map, true)
	_flat("registro", l + 74, _at(0.06), 29, _deep(0.32), 2, Color("4a3018"), _draw_clipboard, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Onde fica no tampo (z) o que está a `t` da frente dele (0 = a borda da frente, 1 = o fundo): os objetos da mesa
## ficam no tampo seja qual for a câmera.
func _at(t: float) -> float:
	return lerpf(_zd.x, _zd.y, t)


## Uma profundidade (z) que é a fração `t` do tampo.
func _deep(t: float) -> float:
	return t * (_zd.y - _zd.x)


## Um ponto (px da tela) preso à grade de 2 px do cenário.
func _even(p: Vector2) -> Vector2:
	return (p / 2.0).floor() * 2.0


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


## Uma face de objeto (sem contorno: um fio preto torto pela perspectiva serrilhava e parecia desenho mal feito; as
## faces se separam pela luz, o tampo mais claro e os lados mais escuros).
func _poly(pts: PackedVector2Array, col: Color) -> void:
	draw_colored_polygon(pts, col)


## Um paralelogramo da tela (o tampo `q` de uma caixa) como transformação de um retângulo de px (0, 0)–`size`: o
## desenho de frente de um objeto chato vira o tampo dele na perspectiva. Com `cell` 2, o retângulo é em blocos de 2 px
## (o desenho na grade do cenário). Devolve [Transform2D, size].
func _top_xf(q: PackedVector2Array, cell := 1.0) -> Array:
	var u := ((q[1] - q[0]) + (q[2] - q[3])) / 2.0
	var v := ((q[3] - q[0]) + (q[2] - q[1])) / 2.0
	var s := Vector2(maxf(1.0, roundf(u.length() / cell)), maxf(1.0, roundf(absf(v.y) / cell)))   # em blocos de `cell` px
	var c := (q[0] + q[1] + q[2] + q[3]) / 4.0
	var o := c - u / 2.0 - v / 2.0
	if cell > 1.0:   # presos à grade da tela: cada bloco vira exatamente `cell` px (senão as linhas escorregam entre os
		# pixels que o filtro de 2x2 lê, e umas somem)
		u = u.normalized() * s.x * cell
		v *= s.y * cell / absf(v.y)
		o = (o / cell).floor() * cell
	return [Transform2D(u / s.x, v / s.y, o), s]


## Sombra de um objeto na mesa (`foot`, a marca dele no tampo), apontando para longe da luminária.
func _desk_shadow(foot: PackedVector2Array) -> void:
	var off := Vector2(clampf((_bounds(foot).get_center().x - _lamp_x * 2.0) / 60.0, -6.0, 8.0), 4.0).round()
	var pts := PackedVector2Array()
	for p in foot:
		pts.append(p + off)
	draw_colored_polygon(pts, Color(0, 0, 0, 0.35))


## Um objeto chato que abre a ferramenta `id`: a sombra, a espessura (`h`, na cor `edge`: a frente e o lado virado para
## o ponto de fuga) e o tampo, desenhado de frente por `paint` (um retângulo de px; com `coarse`, de blocos de 2 px) e
## posto na perspectiva. Devolve o
## tampo (px da tela).
func _flat(id: String, x0: float, zf: float, wx: float, dz: float, h: float, edge: Color, paint: Callable, coarse := false) -> PackedVector2Array:
	var foot := _box(x0, zf, wx, dz, _yd, 0.0)["top"] as PackedVector2Array
	_desk_shadow(foot)
	var bx := _box(x0, zf, wx, dz, _yd, h)
	if not (bx["side"] as PackedVector2Array).is_empty():
		_poly(bx["side"], edge.darkened(0.35))
	_poly(PackedVector2Array([bx["top"][3], bx["top"][2], foot[2], foot[3]]), edge)
	var xf: Array = _top_xf(bx["top"], 2.0 if coarse else 1.0)
	_paint_xf = xf[0]
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
			_poly(side, c.darkened(0.2))   # a lombada, com os filetes dourados
			draw_line(side[0].lerp(side[3], 0.3), side[1].lerp(side[2], 0.3), Color("e0c07a"), 2.0)
			draw_line(side[0].lerp(side[3], 0.7), side[1].lerp(side[2], 0.7), Color("e0c07a"), 2.0)
		var top: PackedVector2Array = bx["top"]
		_poly(top, c)
		var f: Rect2 = bx["front"]
		f = Rect2(_even(f.position), _even(f.end) - _even(f.position))   # (na grade de 2 px)
		draw_rect(f, Color("e3d6b2"))   # o miolo
		for k in range(4, int(f.size.y) - 3, 4):   # as folhas
			draw_rect(Rect2(f.position.x + 2, f.position.y + k, f.size.x - 4, 2), Color("c2b288"))
		draw_rect(Rect2(f.position, Vector2(f.size.x, 2)), c.lightened(0.15))   # a capa de cima e a de baixo
		draw_rect(Rect2(f.position.x, f.end.y - 2, f.size.x, 2), c.darkened(0.3))
		all.append_array(top)
		all.append_array(side)
		all.append(f.position)
		all.append(f.end)
		if b == 2:   # o tampo do volume de cima: a faixa do título e o emblema da central (em blocos de 2 px)
			var xf: Array = _top_xf(top, 2.0)
			var s: Vector2 = xf[1]
			draw_set_transform_matrix(xf[0])
			draw_rect(Rect2(0, 0, s.x, 1), c.lightened(0.25))
			draw_rect(Rect2(3, floorf(s.y * 0.35), s.x - 11, maxf(1.0, floorf(s.y * 0.3))), c.darkened(0.3))
			draw_rect(Rect2(s.x - 6, floorf(s.y * 0.5) - 1, 3, 2), c.darkened(0.35))
			draw_rect(Rect2(s.x - 5, floorf(s.y * 0.5) - 1, 1, 1), Color("e0c07a"))
			draw_set_transform(Vector2.ZERO)
	_props["lista"] = _bounds(all)


## A caneca de café em pé na mesa (centro `xc`, `zc`; raio `rr`, altura `hh`): cerâmica creme com o sombreado do
## cilindro, a boca em elipse com o café, a alça e o emblema da central.
func _draw_mug(xc: float, zc: float, rr: float, hh: float) -> void:
	var a := _even(_p3(xc - rr, _yd - hh, zc))
	var body := Rect2(a, _even(_p3(xc + rr, _yd, zc)) - a)   # (na grade de 2 px)
	var ry := maxf(2.0, roundf((_p3(xc, _yd - hh, zc - rr).y - _p3(xc, _yd - hh, zc + rr).y) / 2.0))
	var rx := body.size.x / 2.0
	_desk_shadow(PackedVector2Array([body.position + Vector2(0, body.size.y - ry), body.end - Vector2(0, ry), body.end, Vector2(body.position.x, body.end.y)]))
	var hx := body.end.x
	draw_rect(Rect2(hx, body.position.y + 4, 6, 12), Color("c2b288"))   # a alça, com o vão
	draw_rect(Rect2(hx, body.position.y + 8, 2, 4), Color("211811"))
	draw_rect(body, Color("d8caa3"))
	draw_rect(Rect2(body.position, Vector2(4, body.size.y)), Color("ece2c6"))   # a luz
	draw_rect(Rect2(body.end.x - 4, body.position.y, 4, body.size.y), Color("a89a76"))   # a sombra
	var top := Vector2(body.get_center().x, body.position.y)
	_ellipse(top, rx + 1, ry + 1, Color("a89a76"))   # a boca, com a beira no tom da sombra da caneca
	_ellipse(top, rx, ry, Color("e3d6b2"))
	_ellipse(top + Vector2(0, 1), rx - 2, ry - 1, Color("3a2414"))   # o café
	var em := _even(body.get_center() + Vector2(-3, 0))   # o emblema
	draw_rect(Rect2(em, Vector2(6, 6)), Color("8e2a22"))
	draw_rect(Rect2(em + Vector2(2, 2), Vector2(2, 2)), Color("e0c07a"))


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(c + Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * ry))
	draw_colored_polygon(pts, col)


## O mapa da cidade dobrado em três, meio aberto na mesa: os painéis alternam luz e sombra nas dobras, com quadras,
## ruas, o rio e um local marcado com alfinete.
func _draw_folded_map(r: Rect2) -> void:
	var pw := floorf(r.size.x / 3.0)
	for k in 3:   # (em blocos de 2 px) o painel do meio fica na sombra da dobra
		var pr := Rect2(r.position.x + k * pw, r.position.y, pw if k < 2 else r.size.x - pw * 2, r.size.y)
		draw_rect(pr, Color("e3d6b2") if k != 1 else Color("cdbf98"))
	for x in range(2, int(r.size.x) - 3, 5):   # quadras
		for y in range(3, int(r.size.y) - 2, 4):
			draw_rect(Rect2(r.position.x + x, r.position.y + y, 3, 2), Color("bcae8a"))
	draw_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, 1), Color("a8986e"))   # a avenida
	draw_polyline(PackedVector2Array([r.position + Vector2(1, r.size.y - 3), r.position + Vector2(r.size.x * 0.3, r.size.y - 6),
		r.position + Vector2(r.size.x * 0.55, r.size.y - 4), r.position + Vector2(r.size.x - 1, 3)]), Color("4f7bb6"), 1.0)   # o rio
	for k in [1, 2]:   # as dobras
		draw_rect(Rect2(r.position.x + k * pw - 1, r.position.y, 1, r.size.y), Color(0, 0, 0, 0.2))
	var pin := (r.position + Vector2(r.size.x * 0.7, r.size.y * 0.42)).floor()   # o alfinete no local marcado
	draw_rect(Rect2(pin + Vector2(1, 1), Vector2(2, 2)), Color(0, 0, 0, 0.35))
	var lit := _pin_lit()   # com uma emergência em andamento, ele pisca e brilha
	draw_rect(Rect2(pin, Vector2(2, 2)), Color("ff5a3c") if lit else Color("b03a2e"))
	draw_rect(Rect2(pin, Vector2(1, 1)), Color("ffc0a0") if lit else Color("e07060"))
	if lit:
		var sp := _paint_xf * (pin + Vector2(1, 1))
		_light(Rect2(sp - Vector2(3, 3), Vector2(6, 6)), Color("ff5a3c"), 0.9, true)


## O caderno de ocorrências aberto: capa de couro em volta, duas páginas pautadas com margem vermelha e anotações à
## mão, a sombra da lombada no meio e o lápis apoiado na página da direita.
func _draw_open_notebook(r: Rect2) -> void:
	for i in mini(pending, 6):   # um registro pendente = uma tira de papel marcando a página, saindo pelo fundo
		var sx := r.position.x + 3 + i * floorf((r.size.x - 8) / 6.0)
		var up := 3.0 + i % 2
		draw_rect(Rect2(sx, r.position.y - up, 3, up + 1), Color("f0dc9a") if i % 2 == 0 else Color("e8d8c0"))
		draw_rect(Rect2(sx, r.position.y - up + 1, 3, 1), Color("b03a2e"))
	draw_rect(r, Color("4a2f1c"))   # a capa
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color("6b4529"))
	var half := floorf(r.size.x / 2.0)
	for k in 2:
		var pg := Rect2(r.position.x + 1 + k * half, r.position.y + 1, half - 2, r.size.y - 2)
		draw_rect(pg, Color("ece2c6"))
		draw_rect(Rect2(pg.position.x + 3, pg.position.y, 1, pg.size.y), Color("d88a7a"))   # a margem
		for y in range(2, int(pg.size.y) - 1, 3):   # a letra de mão, linha por linha
			var lx := pg.position.x + 5
			for w in 4:
				var ww := 2 + (y * 3 + w * 5 + k) % 4
				if lx + ww > pg.end.x - 2:
					break
				draw_rect(Rect2(lx, pg.position.y + y, ww, 1), Color("3a3a5a"))
				lx += ww + 1
	draw_rect(Rect2(r.position.x + half - 1, r.position.y + 1, 2, r.size.y - 2), Color(0, 0, 0, 0.3))   # a lombada
	# o lápis, na diagonal sobre a página da direita
	var a := r.position + Vector2(half + 6, r.size.y - 3)
	var b := r.position + Vector2(r.size.x - 4, 3)
	var d := (b - a).normalized()
	draw_line(a + Vector2(1, 1), b + Vector2(1, 1), Color(0, 0, 0, 0.3), 2.0)
	draw_line(a, b, Color("d8a830"), 2.0)
	draw_line(b, b + d * 2, Color("8e897c"), 2.0)   # a ponteira de metal
	draw_line(b + d * 2, b + d * 3, Color("d88a8a"), 2.0)   # a borracha
	draw_line(a, a - d * 2, Color("d8b88a"), 2.0)   # a madeira apontada


## A prancheta do registro: tábua de duratex com os cantos cortados, a folha datilografada com o cabeçalho e o
## prendedor niquelado com os rebites.
func _draw_clipboard(r: Rect2) -> void:
	var board := PackedVector2Array([r.position + Vector2(2, 0), Vector2(r.end.x - 2, r.position.y), Vector2(r.end.x, r.position.y + 2),
		r.end - Vector2(0, 2), r.end - Vector2(2, 0), Vector2(r.position.x + 2, r.end.y), Vector2(r.position.x, r.end.y - 2), r.position + Vector2(0, 2)])
	draw_colored_polygon(board, Color("7a5230"))
	draw_rect(Rect2(r.position.x + 2, r.position.y, r.size.x - 4, 1), Color("9a6a40"))
	var paper := Rect2(r.position.x + 3, r.position.y + 4, r.size.x - 6, r.size.y - 6)
	draw_rect(Rect2(paper.position + Vector2(1, 1), paper.size), Color(0, 0, 0, 0.25))
	draw_rect(paper, Color("ece2c6"))
	draw_rect(Rect2(paper.position.x + 2, paper.position.y + 3, paper.size.x - 4, 1), Color("8e2a22"))   # o cabeçalho
	for y in range(6, int(paper.size.y) - 1, 2):   # as linhas datilografadas
		draw_rect(Rect2(paper.position.x + 2, paper.position.y + y, paper.size.x - 4 - (y * 7) % 5, 1), Color("6a6250"))
	if unread:   # fala nova no registro: uma folha nova, mais branca, presa por cima e meio torta, com poucas linhas
		var sheet := Rect2(paper.position + Vector2(2, -1), paper.size - Vector2(1, 4))
		draw_rect(Rect2(sheet.position + Vector2(1, 1), sheet.size), Color(0, 0, 0, 0.3))
		draw_rect(sheet, Color("f8f2e0"))
		draw_rect(Rect2(sheet.position.x + 2, sheet.position.y + 4, sheet.size.x - 4, 1), Color("8e2a22"))
		for y in [7, 9, 11]:
			draw_rect(Rect2(sheet.position.x + 2, sheet.position.y + y, sheet.size.x - 5 - y % 3, 1), Color("6a6250"))
	# o prendedor
	var cx := floorf(r.get_center().x)
	draw_rect(Rect2(cx - 6, r.position.y - 1, 12, 4), Color("8e897c"))
	draw_rect(Rect2(cx - 6, r.position.y - 1, 12, 1), Color("d6d1c3"))
	draw_rect(Rect2(cx - 3, r.position.y + 1, 6, 1), Color("45413a"))   # a fenda da mola


## O jornal da manhã dobrado ao meio: papel-jornal acinzentado, o nome no alto numa faixa preta, a manchete grossa,
## as colunas de texto miúdo, uma foto e o vinco da dobra.
func _draw_newspaper(r: Rect2) -> void:
	draw_rect(r, Color("dcd5c2"))   # (em blocos de 2 px)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 1, r.size.x - 4, 2), Color("1d1a14"))   # o nome do jornal
	draw_rect(Rect2(r.position.x + 2, r.position.y + 4, r.size.x - 4, 1), Color("6a6250"))
	draw_rect(Rect2(r.position.x + 2, r.position.y + 6, floorf(r.size.x * 0.6), 1), Color("2a2319"))   # a manchete
	var photo := Rect2(r.end.x - floorf(r.size.x * 0.3) - 2, r.position.y + 6, floorf(r.size.x * 0.3), maxf(2.0, r.size.y - 8))
	draw_rect(photo, Color("8a8478"))
	draw_rect(Rect2(photo.position.x, photo.end.y - 1, photo.size.x, 1), Color("5a554a"))
	for y in range(8, int(r.size.y) - 1, 2):   # as colunas
		for col in 2:
			var cx := r.position.x + 2 + col * floorf(r.size.x * 0.3)
			var line := Rect2(cx, r.position.y + y, floorf(r.size.x * 0.26) - (y * 3) % 3, 1)
			if not line.intersects(photo):
				draw_rect(line, Color("9a9488"))
	draw_rect(Rect2(r.position.x, r.position.y + floorf(r.size.y / 2.0), r.size.x, 1), Color(0, 0, 0, 0.15))   # o vinco
