class_name Background
extends Control
## O cenário atrás da interface, esticado até a borda da tela e em pixels de 1x1 como ela (desenhado numa tela própria,
## `SceneView`, na resolução da tela; as contas são em unidades de 2 px, "px de 2x2", e os detalhes finos em `PX`/`_p`):
## o canto de uma sala vista por quem
## está sentado à mesa. Uma câmera só, em perspectiva de um ponto (`_vp`, perto dos objetos da mesa e na altura dos
## olhos, `EYE` acima do fundo do tampo; `_proj`/`_p3` levam um ponto da sala para a tela): a parede do fundo, com um
## armário de aço de chão atrás da mesa (a base fica escondida por ela); a parede da direita, entrando para o fundo a partir da quina (`CORNER`), com a janela vista de lado; a mesa de madeira, afastada da
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
## listas telefônicas, o mapa dobrado, o caderno aberto e a prancheta do registro (o relógio de flip e a caneca só
## enfeitam). Ficam na sala, em centímetros da
## mesa, e passam pela mesma câmera (tamanho, escorço e o lado que aparece saem da conta), desenhados em pixels de 1x1
## com o detalhe da mesa comutadora; o resto do cenário também tem o detalhe em 1x1 (`PX`). Sob o mouse, ganham contorno, o nome da ferramenta e
## o cursor de dedo (o `SceneView` repassa o mouse, `pointer`, e desenha o contorno, `draw_hover`); o clique só vale
## sobre eles (`prop_at`) e não com o papel de uma ferramenta por cima.

signal prop_clicked(id: String)

const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]   ## madeira (luz, meio, sombra), a mesma do móvel
const LIT := [Color("d59a3d"), Color("b38a3c"), Color("e2b25a")]   ## janelas acesas da cidade
const SLEEP := Vector3(19 * 60, 23 * 60 + 50, 0.15)   ## as janelas apagam entre x e y (minutos do dia); z: as que ficam acesas
const CHURCH_DARK := 22 * 60   ## a porta da igreja apaga
const SIGN_ENAMEL := Color("1f3b35")   ## a placa da companhia telefônica: o esmalte verde-escuro...
const SIGN_INK := Color("d8cfae")   ## ...e o creme das letras e do filete
const SIGN_AT := 0.62   ## onde fica o meio dela, na largura da mesa comutadora (à direita do horário do turno)
const PROPS := {"lista": T.Key.TAB_DIRECTORY, "despacho": T.Key.TAB_DISPATCH, "caderno": T.Key.TAB_LOGBOOK, "registro": T.Key.TAB_CALL_LOG,
	"jornal": T.Key.TAB_NEWS}
const DETAILS := ["cartaz_quermesse", "numero_anotado", "armario_entreaberto"]   ## o que `RoomChange.detail` pode pedir
const SKY := {"rain": Color("0b141c"), "fog": Color("1b252b"), "clear": Color("0a1422")}
const BOARD_SINK := 30.0   ## o fundo do tampo, em px da tela acima da base do painel: fica atrás da mesa comutadora
const PX := 0.5          ## um pixel da tela nas unidades da câmera (px de 2x2): os detalhes são desenhados em 1x1
const LAMP_Y := -30.0      ## a boca da luminária, acima da tela (px de 2x2): de onde sai a luz e saem as sombras na parede
const WALL_GAP := 40.0     ## quanto a luminária fica à frente da parede (px de 2x2): abre o arco de luz nela
# A câmera. Medidas da sala na escala da parede do fundo (px de 2x2 lá; ~0,56 cm): x para a direita e y para baixo a
# partir dos olhos, z a distância deles (a parede fica a `Z0`; mais perto, tudo cresce Z0/z vezes).
const VP_AT := 0.22     ## o ponto de fuga no espaço da mesa, da mesa comutadora (0) à quina (1): perto dos objetos (longe dele, eles entortam)
const EYE := 210.0      ## a altura dos olhos acima do fundo do tampo, na tela (px de 2x2): o ponto de fuga, logo acima da
                        ## tela (olhando a mesa de cima, de perto: com ele mais baixo, o que fica longe dele entortava demais)
# O operador está sentado à mesa e a câmera são os olhos dele: `SEAT_EYE` cm acima do tampo, com o fundo do tampo a
# `SEAT_BACK` cm (a parte da frente do tampo fica sob o console do painel; a tela mostra a de trás). A tela fixa onde
# ficam o ponto de fuga e o fundo do tampo (`EYE` px abaixo dele); o que resta é a distância focal, que sai da
# conta: a altura dos olhos sobre a distância ao fundo do tampo é a mesma na sala e na tela (`EYE` / `Z0` × `DESK_T`).
# Com uma distância focal menor (era 330), a mesa era vista de cima como por alguém em pé (a ~38° em vez de ~22–29°
# para baixo) e as profundidades saíam exageradas: a prancheta mais larga que funda, o relógio torto.
const SEAT_EYE := 45.0    ## a altura dos olhos acima do tampo (cm), sentado
const SEAT_BACK := 110.0  ## dos olhos ao fundo do tampo (cm), na horizontal
const Z0 := EYE * SEAT_BACK / SEAT_EYE   ## a distância dos olhos à parede do fundo (e a distância focal, em px de 2x2)
const DESK_T := 1.25    ## o fundo do tampo, Z0/DESK_T: a mesa fica afastada da parede (o armário cabe atrás)
const CORNER := 0.64    ## a quina das paredes, na largura da área das ferramentas
const BOARD_D := 14.0   ## o fundo do painel da mesa comutadora (z), atrás da prateleira: raso, como o das mesas de verdade (o corpo do móvel é o console); a lateral dele foge para o ponto de fuga
const PLANKS := 6       ## as tábuas do tampo, todas da mesma largura (a câmera as espaça)
const POOL_R := 150.0   ## o raio da poça de luz da luminária no tampo
const DUST := 240        ## grãos de poeira na luz da luminária
const BEADS := 50        ## gotas paradas no vidro, na chuva
const NOIR := Color(0.012, 0.022, 0.045, 0.72)   ## o escuro frio da sala fora da luz da luminária (`_draw_gloom`)
const GLOOM_R := Vector2(820, 330)   ## até onde vai a luz da luminária antes do escuro todo (px da tela, elipse em volta da poça na mesa: larga, a mesa toda na luz)
const GLOOM_IN := 0.25   ## dentro dessa fração do raio, nada de escuro: dali para fora ele cresce liso
const WINDOW_GLOW := Color(0.45, 0.62, 1.0, 0.12)   ## o brilho azul da noite entrando pela janela (`_draw_window_glow`)
const WINDOW_GLOW_R := 420.0   ## até onde ele chega (px da tela, a partir do meio do vidro)
const SHADE_MAX := 0.3   ## o mais escuro que um objeto da mesa fica, longe da poça de luz (`_shade`)
const CAB_W := 110.0             ## a largura do armário de aço, encostado na parede (px de 2x2 lá)
const POSTER_W := 30.0           ## a largura do cartaz da quermesse (px de 2x2)
const WALL_PAD := 10.0           ## a folga dos objetos da mesa até a parede da direita (x da sala)
const CAB_TOP := 29.0            ## o alto dele (y, a partir dos olhos): um pouco abaixo deles, o tampo aparece
const CAB_T := 1.15              ## a frente dele (escala): ~35 cm de fundo
const SIDE_T := 1.06        ## onde a janela começa na parede da direita (escala); termina perto da borda da tela
const SIDE_W := 150.0       ## a largura do vão, de frente (só a resolução da projeção)
const WIN_TOP := -8.0       ## o alto do vão (y, a partir dos olhos): logo acima deles, passando da borda de cima
const WIN_SILL := 26.0      ## quanto o peitoril fica acima do tampo (y)
const X2 := Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2.ZERO)   ## a escala dos px de 2x2 (`_sprite` volta a ela)
const MUG_HANDLE := ["hhhh..", "HHHHh.", "...hHh", "....Hs", "....Hs", "....Hs", "....Hs", "...hHs", "HHHHs.", "ssss.."]   ## a alça da caneca (as duas colunas da esquerda ficam atrás dela)
const PROP_K := 93.0 / 66.0   ## a escala dos objetos da mesa: a mesma dos plugs, que cresceram até o tamanho das tomadas (antes, o plug ficava maior que o relógio e o caderno)
const CLOCK := Vector3(24, 12.5, 14) * PROP_K   ## o relógio de flip da mesa: largura, altura e fundo (na escala da sala; ~15 × 8 × 9 cm, como as listas de 21 cm)
const CLOCK_TURN := 0.5     ## quanto ele está virado para os olhos do operador (1 = de frente para eles; 0 = para a parede)
const FLIP_SEC := 0.24      ## quanto a plaqueta leva para virar
const DIGITS := [   ## os algarismos das plaquetas, 9×19 px, desenhados à mão (estreitos, cantos redondos, traço de 2 px), lado a lado
	"..#####.. ....##... ..#####.. ..#####.. ##...##.. ######### ..#####.. ######### ..#####.. ..#####..",
	".#######. ...###... .#######. .#######. ##...##.. ######### .#######. ######### .#######. .#######.",
	"##.....## ..####... ##.....## ##.....## ##...##.. ##....... ##.....## .......## ##.....## ##.....##",
	"##.....## .##.##... .......## .......## ##...##.. ##....... ##....... .......## ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##...##.. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##...##.. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##...##.. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... ......##. .......## ##...##.. #######.. ##....... .....##.. .#######. ##.....##",
	"##.....## ....##... .....##.. ...#####. ##...##.. ########. ##.####.. .....##.. .#######. .########",
	"##.....## ....##... ....##... ...#####. ##...##.. .......## ########. .....##.. ##.....## ..####.##",
	"##.....## ....##... ...##.... .......## ##...##.. .......## ##.....## ....##... ##.....## .......##",
	"##.....## ....##... ..##..... .......## ######### .......## ##.....## ....##... ##.....## .......##",
	"##.....## ....##... .##...... .......## ######### .......## ##.....## ....##... ##.....## .......##",
	"##.....## ....##... ##....... .......## .....##.. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... .......## .....##.. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... .......## .....##.. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... ##.....## .....##.. ##.....## ##.....## ...##.... ##.....## ##.....##",
	".#######. ....##... ######### .#######. .....##.. .#######. .#######. ...##.... .#######. .#######.",
	"..#####.. ....##... ######### ..#####.. .....##.. ..#####.. ..#####.. ...##.... ..#####.. ..#####..",
]

@export var window: Control   ## a área das ferramentas: a quina e a janela ficam na parede dela
@export var desk: Control     ## a faixa da miniatura do painel (`ConsoleMini`), a frente do console da mesa comutadora: a borda da frente do tampo fica logo abaixo dela
@export var board: Control    ## o painel da mesa comutadora: pousa na prateleira do console; o fundo do tampo fica `BOARD_SINK` px acima da base dele
@export var dust: Control     ## onde a poeira do feixe é desenhada: acima da mesa comutadora (que fica no ar, na frente dela) e abaixo do painel e dos menus
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
var minutes := 18 * 60.0:   ## a hora do jogo (minutos do dia; o Main atualiza): o relógio de flip da mesa
	set(v):
		if int(v) != int(minutes):   # a plaqueta vira
			_flip_from = int(minutes)
			_flip_at = Time.get_ticks_msec()
		minutes = v
var clock_x := 0.0   ## onde o relógio está na tela (x global): de lá vêm a badalada das horas e a campainha do turno
var _yaw := 0.0   # quanto o relógio da mesa está girado (rad; `_draw_flip_clock`)
var _flip_from := -1   # o minuto que a plaqueta mostrava antes de virar
var _flip_at := -100000   # quando ela começou a virar (ms)
var _drops: Array = []
var _dust: Control       # a poeira no feixe da luminária (`dust`): desenhada à parte, a 30 quadros por segundo, sem redesenhar a sala
var _motes: Array = []   # os grãos: Vector3(x de -1 a 1 na largura da luz, y de 0 a 1 do alto da tela ao fundo do tampo, fase do brilho)
var _beads: Array = []   # gotas paradas no vidro: Vector4(x, y em frações do vidro à vista, tamanho, velocidade; 0 = parada)
var _glass_from := 0.6   # de que fração da altura da vista o vidro aparece (acima: fora da tela ou atrás da persiana)
var _top := 200.0        # o fundo do tampo (px de 2x2), do último desenho: onde o feixe da luminária acaba
var _stars: Array[Vector2] = []
var _city: Array = []          # prédios da vista: {x, w, h, roof, lit: [Vector3...]} (px do vidro; z: o minuto em que a janela apaga)
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
var _glass := PackedVector2Array()   # o vidro da janela abaixo da persiana (px da tela): o escuro da sala não passa nele


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
	_dust = dust
	if _dust == null:   # (sem a camada da cena: aqui mesmo, atrás da interface)
		_dust = Control.new()
		_dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_dust)
	_dust.draw.connect(_draw_dust)
	for i in DUST:
		_motes.append(Vector3(randf() * 2.0 - 1.0, randf(), randf() * TAU))
	for i in BEADS:
		_beads.append(Vector4(randf(), randf(), 1 + randi() % 2, 0.0))


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
	for i in _motes.size():   # a poeira: sobe e desce devagar, ao sabor do ar
		var m: Vector3 = _motes[i]
		m.x += sin(m.z * 0.7) * 0.0014
		m.y += sin(m.z * 1.3) * 0.001 - 0.0003
		m.z += 0.014
		if m.y < 0.0 or m.y > 1.0 or absf(m.x) > 1.0:
			m = Vector3(randf() * 2.0 - 1.0, randf(), randf() * TAU)
		_motes[i] = m
	_dust.queue_redraw()
	if weather == "rain":
		for i in _beads.size():   # as gotas no vidro: paradas, até pesarem e escorrerem
			var b: Vector4 = _beads[i]
			if b.w == 0.0:
				if randf() < 0.002:
					b.w = 0.006 + randf() * 0.008
			else:
				b.y += b.w
				b.x += (randf() - 0.5) * 0.003   # serpenteia um pouco
				if b.y > 1.0:
					b = Vector4(randf(), randf() * 0.8, 1 + randi() % 2, 0.0)
			_beads[i] = b
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
		details, night, weather, int(minutes), _flip_step(), TranslationServer.get_locale()]


## Em que passo da virada está a plaqueta do relógio (0 a 2; 3 = parada).
func _flip_step() -> int:
	return mini(3, int((Time.get_ticks_msec() - _flip_at) / (FLIP_SEC * 1000.0 / 3.0)))


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


## Um retângulo em px da tela (1x1) dentro do desenho em escala 2: os detalhes finos, na mesma densidade da interface.
func _p(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x * PX, y * PX, w * PX, h * PX), c)


## Uma linha em pixel art de `a` a `b` (px da tela, fora da escala e da perspectiva; como traço comum, torta,
## serrilhava): um pixel por passo na direção mais longa e, na outra, a espessura em `cols` (de cima para baixo, ou da
## esquerda para a direita). Depois volta a valer `back` (a transformação de quem chamou).
func _pixel_line(a: Vector2, b: Vector2, cols: Array, back := Transform2D.IDENTITY) -> void:
	draw_set_transform(Vector2.ZERO)
	var d := b - a
	var n := maxi(1, roundi(maxf(absf(d.x), absf(d.y))))
	var flat := absf(d.x) >= absf(d.y)
	var o := floori(cols.size() / 2.0)
	for i in n + 1:
		var p := (a + d * i / n).floor()
		for k in cols.size():
			draw_rect(Rect2(p + (Vector2(0, k - o) if flat else Vector2(k - o, 0)), Vector2.ONE), cols[k])
	draw_set_transform_matrix(back)


## Uma peça redonda em pixel art (`Switchboard.disc`; como círculo, saía embolotada) centrada em `c` (px da tela),
## presa aos pixels, fora da escala e da perspectiva; depois volta a valer `back` (a transformação de quem chamou).
func _sprite(tex: Texture2D, c: Vector2, mod := Color.WHITE, back := Transform2D.IDENTITY) -> void:
	draw_set_transform(Vector2.ZERO)
	var sz := Vector2(tex.get_size())
	draw_texture_rect(tex, Rect2((c - sz / 2.0).floor(), sz), false, mod)
	draw_set_transform_matrix(back)


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
	_yd = EYE / DESK_T
	_cx = floorf(area.position.x + area.size.x * CORNER)
	var b := Rect2((board.global_position - global_position) / 2.0, board.size / 2.0) if board else Rect2()
	# o ponto de fuga fica na mesma fração do espaço da mesa (da mesa comutadora à quina) em qualquer largura: preso
	# à largura da tela, numa janela larga ele fugia dos objetos e os da ponta apareciam bem de lado
	_vp = Vector2(floorf(lerpf(b.end.x, _cx, VP_AT)), top - EYE)
	_top = top
	_draw_wall(Rect2(0, 0, w, top))
	_draw_wall_light(top)
	if board:   # a mesa comutadora, de pé na frente da parede, faz sombra nela (o tampo cobre a parte de baixo)
		_cast(b, 1.1)
		_draw_company_sign(Rect2(b.position * 2.0, b.size * 2.0))
	# na parede, entre a mesa comutadora e a quina, com a mesma folga entre eles em qualquer largura de janela: o
	# armário e o lugar do cartaz (guardado mesmo sem ele, para o armário não mudar de lugar de uma noite para outra)
	var gap := (_cx - b.end.x - CAB_W * CAB_T - POSTER_W) / 3.0
	var cab := _draw_steel_cabinet((b.end.x + gap - _vp.x) / CAB_T)
	if "cartaz_quermesse" in details:
		_draw_poster(Rect2(floorf(cab.end.x + gap), 34, POSTER_W, 38))
	_zd = Vector2(Z0 * _yd / (front - _vp.y), Z0 / DESK_T)
	_draw_desk(Rect2(0, top, w, h - top), front)
	_draw_switchboard(front)
	_draw_side_wall(top, front, w)
	_draw_desk_props()
	_draw_gloom()
	_draw_window_glow()
	if _cover.has_area():   # uma ferramenta na frente do operador: o cenário atrás escurece e o papel faz sombra nele
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(_cover.position + Vector2(10, 12), _cover.size), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.28))


## O escuro da sala (noir): tudo o que a luz da luminária não alcança fica frio e escuro (`NOIR`), liso, crescendo da
## luz para fora (`GLOOM_IN`, `GLOOM_R`; com uma borda marcada, parecia um recorte). O vidro da janela fica de fora: a
## rua tem a luz dela. A luminária piscando escurece tudo junto.
func _draw_gloom() -> void:
	draw_set_transform(Vector2.ZERO)
	var pool := _pool()
	var c := _proj(pool.x, _yd, pool.y) * 2.0
	var dark := func(p: Vector2) -> Color:
		var k := smoothstep(GLOOM_IN, 1.0, ((p - c) / GLOOM_R).length())
		return Color(NOIR, clampf(NOIR.a * k + (1.0 - lamp_level) * 0.3, 0.0, 0.9))
	var glass := _bounds(_glass) if _glass.size() > 2 else Rect2()
	var n := Vector2i(40, 24)
	var cell := size / Vector2(n)
	for j in n.y:
		for i in n.x:
			var a := cell * Vector2(i, j)
			var quad := PackedVector2Array([a, a + Vector2(cell.x, 0), a + cell, a + Vector2(0, cell.y)])
			var parts: Array = Geometry2D.clip_polygons(quad, _glass) if glass.intersects(Rect2(a, cell)) else [quad]
			for poly: PackedVector2Array in parts:
				var cols := PackedColorArray()
				for p in poly:
					cols.append(dark.call(p))
				draw_polygon(poly, cols)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Um brilho azul bem fraco vindo da janela (a noite lá fora), por cima do escuro da sala: liso, sumindo em volta dela.
func _draw_window_glow() -> void:
	if _glass.size() < 3:
		return
	draw_set_transform(Vector2.ZERO)
	var c := _bounds(_glass).get_center()
	var rim := PackedVector2Array()
	for i in 32:
		rim.append(c + Vector2.from_angle(TAU * i / 32.0) * WINDOW_GLOW_R)
	var strength: float = WINDOW_GLOW.a * {"clear": 1.0, "rain": 0.8, "fog": 1.2}.get(weather, 1.0)
	_light_fan(c, rim, Color(WINDOW_GLOW, strength))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## A placa esmaltada da companhia telefônica, na parede acima da mesa comutadora (`b`, em px da tela), à direita do
## horário do turno colado ali: fundo verde-escuro, filete creme, o nome em creme (`SIGN_COMPANY`), um parafuso de
## latão em cada ponta e a sombra na parede. Em px da tela (1x1: o texto fica nítido).
func _draw_company_sign(b: Rect2) -> void:
	draw_set_transform(Vector2.ZERO)
	var company := T.text(T.Key.SIGN_COMPANY)
	var tw := Pal.mono.get_string_size(company, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var r := Rect2(roundf(b.position.x + b.size.x * SIGN_AT - (tw + 44.0) / 2.0), b.position.y - 36.0, roundf(tw + 44.0), 24.0)
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r.grow(1), Switchboard.EDGE_DARK)
	draw_rect(r, SIGN_ENAMEL)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), SIGN_ENAMEL.lightened(0.25))   # a luz na beira de cima
	draw_rect(r.grow(-3), SIGN_INK, false, 1.0)   # o filete
	for x in [r.position.x + 9.0, r.end.x - 9.0]:
		_sprite(Switchboard.disc(5, [[1.5, Color("e6cf8e"), Color("c4a35a"), Color("7a6230")], [2.5, Color("3a2a12")]]), Vector2(x, r.get_center().y))
	draw_string(Pal.mono, Vector2(roundf(r.get_center().x - tw / 2.0), r.position.y + 16.0), company, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, SIGN_INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


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
	var h := r.size.y * 2.0
	for x in range(0, int(r.size.x) * 2, 44):   # as listras: a larga com o fio de luz e, no meio, a fina
		_p(x, 0, 3, h, Color("141c1f"))
		_p(x + 3, 0, 1, h, Color("1b2629"))
		_p(x + 22, 0, 1, h, Color("1a2427"))
	var frieze := Color("1e2a2d")   # o friso no alto: dois fios e os losangos entre eles
	_p(0, 7, r.size.x * 2.0, 1, frieze)
	_p(0, 17, r.size.x * 2.0, 1, frieze)
	for x in range(0, int(r.size.x) * 2, 22):
		for i in 5:
			var half := 2 - absi(i - 2)
			_p(x + 9 - half, 10 + i, half * 2 + 1, 1, frieze)


## A luz da luminária na parede, atrás dela: o cone que desce da boca corta a parede num arco (alto no meio, descendo
## para os lados) e acaba no tampo, onde vira a poça de `_draw_desk`; a dobra na quina mostra que são dois planos.
## Lisa: mais forte embaixo da luminária, na quina com o tampo, e sumindo até o arco (`_light_fan`).
func _draw_wall_light(top: float) -> void:
	var m := 0.75
	var w := sqrt(pow((top - LAMP_Y) / m, 2.0) - WALL_GAP * WALL_GAP)
	var pts := PackedVector2Array()
	for i in 25:
		var x := _lamp_x - w + w * 2.0 * i / 24.0
		pts.append(Vector2(x, minf(top, LAMP_Y + sqrt(pow(x - _lamp_x, 2.0) + WALL_GAP * WALL_GAP) * m)))
	_light_fan(Vector2(_lamp_x, top), pts, Color(1.0, 0.8, 0.52, 0.15 * lamp_level))


## Uma luz lisa, sem camadas: a cor `col` no ponto `c`, sumindo até a borda `rim` (fechada, vista de `c`), com a cor
## variando ponto a ponto (forte perto de `c` e caindo depressa, como a luz; em camadas, parecia artificial).
func _light_fan(c: Vector2, rim: PackedVector2Array, col: Color) -> void:
	var mid := Color(col, col.a * 0.35)
	var out := Color(col, 0.0)
	for i in rim.size():
		var a := rim[i]
		var b := rim[(i + 1) % rim.size()]
		_ci.draw_primitive(PackedVector2Array([c, c.lerp(a, 0.5), c.lerp(b, 0.5)]), PackedColorArray([col, mid, mid]), PackedVector2Array())
		_ci.draw_polygon(PackedVector2Array([c.lerp(a, 0.5), a, b, c.lerp(b, 0.5)]), PackedColorArray([mid, out, out, mid]))


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
	var o := r.position * 2.0
	_p(o.x, o.y, r.size.x * 2.0, r.size.y * 2.0, Color("e3d6b2"))
	_p(o.x, o.y, r.size.x * 2.0, 12, Color("8e2a22"))   # o cabeçalho com o mês
	_p(o.x, o.y, r.size.x * 2.0, 1, Color("b04a3e"))
	_p(o.x + 10, o.y + 5, r.size.x * 2.0 - 20, 2, Color("e3d6b2"))
	for k in 20:   # os dias; os que já passaram (uma noite cada) ficam riscados de vermelho
		var d := o + Vector2(5 + (k % 5) * 9, 17 + (k / 5) * 8)
		_p(d.x, d.y, 1, 4, Color("6e6450"))
		_p(d.x + 2, d.y, 2, 1, Color("6e6450"))
		_p(d.x + 3, d.y + 1, 1, 3, Color("6e6450"))
		if k < night - 1:
			_ci.draw_line((d + Vector2(-1, 5)) * PX, (d + Vector2(6, -1)) * PX, Color("b03a2e"), PX)
	_p(o.x + r.size.x - 1, o.y - 2, 2, 2, Color("3a3a3a"))   # o prego


# ---------------------------------------------------------------- parede da direita e janela

## Um ponto do vão da janela (`p`: ao longo da parede, de 0 a `SIDE_W`, e a altura a partir do alto do vão; pode
## passar da borda) na tela (px de 2x2). A distância ao longo da parede é linear em 1/t: a perspectiva certa.
func _side_pt(p: Vector2) -> Vector2:
	var t := 1.0 / lerpf(1.0 / SIDE_T, 1.0 / _t2, p.x / SIDE_W)
	return _vp + Vector2(_cx - _vp.x, WIN_TOP + p.y) * t


## Um retângulo do vão da janela projetado na parede.
func _side_quad(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([_side_pt(r.position), _side_pt(Vector2(r.end.x, r.position.y)), _side_pt(r.end), _side_pt(Vector2(r.position.x, r.end.y))])


## A vista da janela, de frente, no vidro fora da tela (`_vport`, do tamanho da janela na tela, em px da tela; a
## vista é desenhada nas mesmas unidades do resto, em escala 2, com os detalhes em `PX`).
func _draw_view() -> void:
	_ci = _view
	_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var g := Rect2(Vector2.ZERO, Vector2(_vport.size) / 2.0)
	_win = g.size
	if window_art:
		_view.draw_texture_rect(window_art, g, false)
	else:
		_draw_city(g)
	_draw_reflection(g)
	_draw_glass_weather(g)
	_ci = self


## À noite, com a sala acesa, o vidro reflete um pouco dela, por cima da cidade (e da silhueta, que fica atrás do
## reflexo): a luz da luminária, o contorno claro do armário e a luz quente da sala subindo de baixo. Liso, sem
## camadas, e acompanhando a luminária quando ela pisca. A vista passa da borda de cima da tela: só aparece do
## horizonte (58% da altura dela) para baixo, e é ali que o reflexo fica.
func _draw_reflection(g: Rect2) -> void:
	var lamp := Color(1.0, 0.85, 0.6, 0.28 * lamp_level)
	var c := g.position + g.size * Vector2(0.3, 0.7)
	var rim := PackedVector2Array()
	for i in 24:
		rim.append(c + Vector2(cos(TAU * i / 24.0) * g.size.x * 0.32, sin(TAU * i / 24.0) * g.size.y * 0.1))
	_light_fan(c, rim, lamp)
	# o armário, espelhado: claro embaixo, no meio dele, e sumindo para os lados e para cima (sem bordas: uma caixa
	# clara parecia uma camada por cima da vista)
	var cab := Rect2(g.position + g.size * Vector2(0.58, 0.62), g.size * Vector2(0.18, 0.38))
	var steel := Color(0.75, 0.8, 0.65, 0.07 * lamp_level)
	var none := Color(steel, 0.0)
	var mt := Vector2(cab.get_center().x, cab.position.y)
	var mb := Vector2(cab.get_center().x, cab.end.y)
	_ci.draw_polygon(PackedVector2Array([cab.position, mt, mb, Vector2(cab.position.x, cab.end.y)]), PackedColorArray([none, none, steel, none]))
	_ci.draw_polygon(PackedVector2Array([mt, Vector2(cab.end.x, cab.position.y), cab.end, mb]), PackedColorArray([none, none, none, steel]))
	var room := Color(1.0, 0.78, 0.5, 0.0)
	var low := Color(room, 0.08 * lamp_level)
	var y := g.position.y + g.size.y * 0.8
	_ci.draw_polygon(PackedVector2Array([Vector2(g.position.x, y), Vector2(g.end.x, y), g.end, Vector2(g.position.x, g.end.y)]),
		PackedColorArray([room, room, low, low]))


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
			draw_line(p, back.call(p), WOOD[1], 1.0)
		for y in [sy + (fy - sy) * 0.4, sy + (fy - sy) * 0.75]:
			draw_line(Vector2(fx1, y), deep.call(Vector2(fx1, y)), WOOD[1], 1.0)
		draw_line(Vector2(b.end.x, b.position.y), b.end, WOOD[0], 1.0)   # as quinas da frente pegam a luz
		draw_line(Vector2(fx1, sy), low, WOOD[0], 1.0)
	# a frente do console (aparece entre as peças embutidas), com a beira de cima e o rodapé
	_r(fx0, sy, fx1 - fx0, fy - sy, WOOD[1])
	_r(fx0, sy, fx1 - fx0, 2, WOOD[0])
	_r(fx0, fy - 3, fx1 - fx0, 3, WOOD[2])
	# a prateleira: o painel pousa no fundo dela, num rodapé, com a sombra de contato na frente
	_poly(PackedVector2Array([Vector2(fx0, sy), Vector2(fx1, sy), b.end, Vector2(b.position.x, b.end.y)]), Color("5a3a22"))
	for t in [0.3, 0.55, 0.8]:   # os veios da prateleira, de lado a lado
		var y := roundf(lerpf(sy, b.end.y, t))
		_r(lerpf(fx0, b.position.x, t), y, lerpf(fx1, b.end.x, t) - lerpf(fx0, b.position.x, t), 1, Color("4e321d"))
	_r(fx0, sy - 1, fx1 - fx0, 2, Color("8a6a2e"))   # o friso de latão na beira
	_r(fx0, sy - 1, fx1 - fx0, 1, Color("c4a35a"))
	var radio := desk.get_node_or_null("Mini") as Control
	if radio and radio.visible:   # na frente do console, em volta da miniatura do painel: a plaqueta e os botões dele
		var rr := Rect2(radio.global_position - global_position, radio.size)
		var my := roundf((sy + fy) / 2.0)
		var plate := Rect2(rr.position.x - 74, my - 8, 56, 16)
		draw_rect(Rect2(plate.position + Vector2(1, 1), plate.size), Color(0, 0, 0, 0.35))
		draw_rect(plate, Color("8a6a2e"))
		draw_rect(Rect2(plate.position, Vector2(plate.size.x, 1)), Color("c4a35a"))
		for i in 2:   # o nome gravado (as letras não se leem dessa distância)
			draw_rect(Rect2(plate.position.x + 8, plate.position.y + 5 + i * 5, plate.size.x - 16 - i * 12, 1), Color("4a3a18"))
		for i in 2:   # baquelite: a borda em volta do tampo, os dois com a luz no alto à esquerda
			var c := Vector2(rr.end.x + 24 + i * 30, my)
			_sprite(Switchboard.disc(19, [[9.0, Color(0, 0, 0, 0.35)]]), c + Vector2(1, 2))
			_sprite(Switchboard.disc(17, [[5.5, Color("5a5048"), Color("3a332c"), Color("2a2420")],
				[7.5, Color("4a4038"), Color("2a2420"), Color("1a1612")], [8.5, Color("120e0a")]]), c)
			var a := -PI * 0.75 + i * 1.1
			for j in range(2, 7):   # o risco de posição, pixel a pixel
				draw_rect(Rect2((c + Vector2(cos(a), sin(a)) * j).floor(), Vector2.ONE), Color("d6d1c3"))
	for p in [Vector2(fx1 - 8, sy + 8), Vector2(fx1 - 8, fy - 10), Vector2(8, sy + 8), Vector2(8, fy - 10)]:   # os parafusos
		if p.x > fx0 + 4:
			_sprite(Switchboard.disc(5, [[2.5, Color("4a3a24"), Color("2a1a0f"), Color("1a0f08")]]), p)
			draw_rect(Rect2(p.floor() - Vector2(1, 0), Vector2(3, 1)), Color("8e7a5a"))   # a fenda
	draw_rect(Rect2(b.position.x, b.end.y, b.size.x, 3), WOOD[2])
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
	# a luz da rua na mesa: sai de baixo da janela e cai para a esquerda, na frente; lisa, mais forte junto da janela e
	# da parede e sumindo para a esquerda e para a frente (de um tom só, a borda dela riscava a mesa na diagonal)
	_t2 = (w - 14.0 - _vp.x) / xc
	var a := _vp + Vector2(xc, _yd) * maxf(SIDE_T, DESK_T)
	var c := _vp + Vector2(xc, _yd) * minf(_t2, te)
	var cool: float = {"clear": 0.06, "rain": 0.04, "fog": 0.025}.get(weather, 0.04)
	if c.x > a.x + 4.0:   # (com a tela mudando de tamanho, a janela pode ainda não chegar à mesa)
		var street := Color(0.6, 0.72, 0.9, cool)
		var far := Color(street, cool * 0.3)
		var none := Color(street, 0.0)
		var cf := Vector2(c.x - 70, front)
		var af := Vector2(a.x - 110, front)
		draw_polygon(PackedVector2Array([a, a.lerp(c, 0.5), af.lerp(cf, 0.5), af]), PackedColorArray([none, street, far, none]))
		draw_polygon(PackedVector2Array([a.lerp(c, 0.5), c, cf, af.lerp(cf, 0.5)]), PackedColorArray([street, street, far, far]))
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
		var sw := maxf(2.0, roundf(3.0 * t))   # mais perto, mais larga (em px da tela)
		_p(roundf(x * 2.0), 0, sw, roundf(bottom * 2.0), Color("1b2629"))
		_p(roundf(x * 2.0) + sw, 0, 1, roundf(bottom * 2.0), Color("24323a"))
		k += 1
	for fy in [3.5, 8.5]:   # o friso: os dois fios, subindo para fora da tela
		draw_line(Vector2(_cx, fy), Vector2(w, _vp.y + (fy - _vp.y) * te), Color("26353a"), PX)
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
	# o vidro que aparece começa abaixo da persiana (e da borda de cima da tela): as gotas ficam dali para baixo
	_glass_from = clampf((maxf(0.0, _side_pt(Vector2(gw * 0.5, floorf(gh * 0.3))).y) - view.position.y) / view.size.y, 0.0, 0.95)
	if _vport.size != Vector2i(view.size * 2.0):   # o vidro em px da tela: a vista também é desenhada em 1x1
		_vport.size = Vector2i(view.size * 2.0)
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
	_glass = PackedVector2Array()
	for p in _side_quad(Rect2(0, blind, gw, gh - blind)):
		_glass.append(p * 2.0)
	for y in range(0, int(blind), 2):   # as lâminas: a face clara, o fio de luz na beira e a sombra embaixo
		draw_colored_polygon(_side_quad(Rect2(0, y, gw, 1.5)), Color("8a8070"))
		draw_colored_polygon(_side_quad(Rect2(0, y, gw, PX)), Color("a89e8a"))
		draw_colored_polygon(_side_quad(Rect2(0, y + 1.5, gw, PX)), Color("3a352c"))
	draw_line(_side_pt(Vector2(gw * 0.8, blind)), _side_pt(Vector2(gw * 0.8, blind + 8)), Color("8a8070"), PX)   # o cordão
	draw_colored_polygon(_side_quad(Rect2(gw * 0.8 - 1, blind + 8, 2, 2)), Color("6b5f4c"))   # o puxador dele
	# o vão: perto da quina aparece o lado de dentro do batente (virado para quem olha), o peitoril e a verga
	draw_colored_polygon(_side_quad(Rect2(0, 0, 10, gh)), Color("223033"))
	draw_line(_side_pt(Vector2(10, 0)), _side_pt(Vector2(10, gh)), Color(0, 0, 0, 0.4), PX)
	draw_colored_polygon(_side_quad(Rect2(0, gh - 3, gw, 3)), Color("2c3a3c"))
	draw_colored_polygon(_side_quad(Rect2(0, 0, gw, 2)), Color("0d1315"))
	# o peitoril de fora e o vaso
	draw_colored_polygon(_side_quad(Rect2(-8, gh + 4, gw + 16, 3)), WOOD[0])
	draw_colored_polygon(_side_quad(Rect2(-8, gh + 7, gw + 16, 2)), WOOD[2])
	var pp := (_side_pt(Vector2(gw * 0.82, gh + 4)) * 2.0).round()   # (px da tela)
	_p(pp.x + 1, pp.y - 13, 16, 13, Color("8a4a2a"))   # o vaso de barro, mais estreito embaixo
	_p(pp.x, pp.y - 15, 18, 3, Color("9a542f"))
	_p(pp.x, pp.y - 15, 18, 1, Color("b8683c"))
	_p(pp.x + 1, pp.y - 12, 16, 1, Color("5e321c"))
	_p(pp.x + 2, pp.y - 11, 2, 10, Color("a05a34"))
	for leaf in [Vector2(-6, -24), Vector2(2, -30), Vector2(10, -26), Vector2(16, -21), Vector2(-2, -20), Vector2(6, -22)]:
		var lp: Vector2 = pp + leaf
		_p(lp.x + 1, lp.y, 5, 1, Color("4f7040"))   # cada folha: miolo, borda escura e a nervura clara
		_p(lp.x, lp.y + 1, 7, 3, Color("3d5a32"))
		_p(lp.x + 1, lp.y + 4, 5, 1, Color("2c4224"))
		_p(lp.x + 2, lp.y + 2, 3, 1, Color("6a8e54"))
	_p(pp.x + 7, pp.y - 20, 1, 6, Color("2c4224"))   # o caule


## Armário de aço antigo, de chão, encostado na parede do fundo atrás da mesa (`x0` a partir do ponto de fuga, `CAB_W`, `CAB_TOP`, `CAB_T`; a mesa,
## desenhada depois, esconde a base): cornija no alto, duas portas verde-acinzentadas com venezianas, o porta-etiqueta
## niquelado, o puxador com a fechadura, as dobradiças e um calendário preso com ímã. Devolve a frente (px de 2x2).
func _draw_steel_cabinet(x0: float) -> Rect2:
	var back := Rect2(_vp + Vector2(x0, CAB_TOP), Vector2(CAB_W, 400))
	_cast(back, 1.05)
	var f := Rect2((_vp + Vector2(x0, CAB_TOP) * CAB_T).round(), (Vector2(CAB_W, 400) * CAB_T).round())
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
	for i in 36:   # a luz da luminária, mais forte do lado dela, caindo pixel a pixel (em faixas largas, pareciam camadas)
		_r(f.position.x + i * PX, f.position.y, PX, f.size.y, Color(1.0, 0.85, 0.6, 0.09 * (1.0 - i / 36.0) * lamp_level))
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, 5, steel.darkened(0.15))   # a cornija, com o friso
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, PX, steel.lightened(0.3))
	_r(f.position.x - 2, f.position.y + 1.5, f.size.x + 4, PX, steel.darkened(0.3))
	_r(f.position.x - 2, f.position.y + 4, f.size.x + 4, 1, Color("23281f"))
	_r(f.position.x, f.position.y + 5, PX, f.size.y, steel.lightened(0.15))   # a luz à esquerda, a sombra à direita
	_r(f.end.x - PX, f.position.y + 5, PX, f.size.y, steel.darkened(0.3))
	var mid := floorf(f.get_center().x)
	var doors := f.position.y + 8
	_r(mid - PX, doors, PX, f.size.y, Color("23281f"))   # a fresta entre as portas
	_r(mid, doors, PX, f.size.y, steel.lightened(0.12))
	for door in [Rect2(f.position.x + 3, doors, mid - f.position.x - 5, 60), Rect2(mid + 2, doors, f.end.x - mid - 5, 60)]:
		for i in 6:   # as venezianas, no alto de cada porta: a fenda e a aba que pega a luz
			_r(door.position.x + 6, door.position.y + 4 + i * 4, door.size.x - 12, 1.5, Color("2e342b"))
			_r(door.position.x + 6, door.position.y + 5.5 + i * 4, door.size.x - 12, PX, steel.lightened(0.25))
			_r(door.position.x + 6, door.position.y + 4 + i * 4, PX, 2, steel.darkened(0.2))
	# o porta-etiqueta na porta da esquerda, com o cartão datilografado
	var lab := Rect2(f.position.x + 12, doors + 34, 24, 11)
	_r(lab.position.x - PX, lab.position.y - PX, lab.size.x + 1, lab.size.y + 1, Color("8e897c"))
	_r(lab.position.x - PX, lab.position.y - PX, lab.size.x + 1, PX, Color("c9c4b5"))
	_r(lab.position.x, lab.position.y, lab.size.x, lab.size.y, Color("e3d6b2"))
	for i in 3:
		_r(lab.position.x + 2.5, lab.position.y + 2.5 + i * 2.5, lab.size.x - 5 - i * 4, PX, Color("4a4438"))
	# o puxador e a fechadura, junto da fresta, na altura da mão
	var hy := doors + 40.0
	_r(mid + 4, hy, 2.5, 16, Color("3a3d33"))
	_r(mid + 4, hy, 2, 15.5, Color("b8b2a2"))
	_r(mid + 4, hy, PX, 15.5, Color("ece7da"))
	_sprite(Switchboard.disc(8, [[3.0, Color("b8b2a2"), Color("8e897c"), Color("5a574e")], [4.0, Color.BLACK]]), Vector2(mid + 5.25, hy - 5) * 2.0, Color.WHITE, X2)
	_r(mid + 5, hy - 6, PX, 1.5, Color("23281f"))
	for y in [doors + 4, doors + 70]:   # as dobradiças
		for x in [f.position.x - 1, f.end.x - 1]:
			_r(x, y, 1.5, 7, Color("8e897c"))
			_r(x, y, PX, 7, Color("c9c4b5"))
			_r(x, y + 3.5, 1.5, PX, Color("4a4840"))
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
			_r(a.x, sy, inside.size.x, 1.5, steel.darkened(0.2))   # a beira da prateleira
			_r(a.x, sy, inside.size.x, PX, steel.lightened(0.1))
			var px := inside.position.x + 3
			var n := k * 3   # a próxima pasta (a cor e o tamanho variam por ela)
			var base: float = sy - 1.0 + ((bk.call(a) as Vector2).y - sy) * 0.4   # em pé um pouco para dentro
			while px < inside.end.x - 6:
				var pw := 3.0 + (n * 7) % 4
				var ph := 14.0 + (n * 5) % 8
				var col: Color = [Color("6e5a3a"), Color("8a7a5a"), Color("4a5a6a"), Color("7a3a2a"), Color("6e5a3a")][(n * 3) % 5]
				n += 1
				_r(px, base - ph, pw, ph, col)
				_r(px, base - ph, PX, ph, col.lightened(0.2))   # a lombada pega a luz
				_r(px + pw - PX, base - ph, PX, ph, col.darkened(0.3))
				_r(px + PX, base - ph + 3, pw - 1, 1.5, Color("e3d6b2"))   # a etiqueta
				px += pw + 1
		# a porta aberta, de lado: a face de dentro com o painel rebaixado e a beira (a espessura) pegando a luz
		var d0 := Vector2(f.end.x, doors - 1)
		var d1 := Vector2(f.end.x + 16, doors - 6)
		var d2 := Vector2(f.end.x + 16, f.end.y + 8)
		var d3 := Vector2(f.end.x, f.end.y)
		draw_colored_polygon(PackedVector2Array([d0, d1, d2, d3]), steel.darkened(0.1))
		draw_colored_polygon(PackedVector2Array([d0.lerp(d1, 0.25) + Vector2(0, 8), d1.lerp(d0, 0.25) + Vector2(0, 8),
			d2.lerp(d3, 0.25) - Vector2(0, 10), d3.lerp(d2, 0.25) - Vector2(0, 10)]), steel.darkened(0.25))
		draw_line(d1, d2, steel.lightened(0.25), PX)
		draw_line(d1 + Vector2(PX, 0), d2 + Vector2(PX, 0), steel.lightened(0.05), PX)
		draw_line(d1 + Vector2(1, 0), d2 + Vector2(1, 0), steel.darkened(0.45), PX)
		var rod := d1.lerp(d0, 0.3)   # a haste da fechadura
		draw_line(rod + Vector2(0, 30), rod + Vector2(0, 52), Color("8e897c"), PX)
	else:
		_draw_calendar(Rect2(mid + 14, doors + 46, 24, 26))   # preso com ímã
	if "numero_anotado" in details:   # o número de quem ligou, anotado num bilhete e colado com fita
		var n := Rect2(f.position.x + 10, doors + 52, 26, 14)
		_cast(n, 1.01)
		_r(n.position.x, n.position.y, n.size.x, n.size.y, Color("efe6cc"))
		var ink := Color("2a2a4a")
		for k in 5:   # os algarismos, à mão, em traço de caneta (px da tela)
			var d := (n.position + Vector2(3 + k * 4, 3.5 + (k % 2) * PX)) * 2.0
			match k % 3:
				0:   # um "1"
					_p(d.x + 2, d.y, 1, 7, ink)
					_p(d.x + 1, d.y + 1, 1, 1, ink)
				1:   # um "7"
					_p(d.x, d.y, 5, 1, ink)
					_p(d.x + 4, d.y + 1, 1, 2, ink)
					_p(d.x + 3, d.y + 3, 1, 4, ink)
				_:   # um "0"
					_p(d.x + 1, d.y, 3, 1, ink)
					_p(d.x, d.y + 1, 1, 5, ink)
					_p(d.x + 4, d.y + 1, 1, 5, ink)
					_p(d.x + 1, d.y + 6, 3, 1, ink)
		_r(n.position.x + 3, n.position.y + 10.5, n.size.x - 6, PX, Color("b03a2e"))   # sublinhado
		_r(n.position.x + 3, n.position.y + 11.5, n.size.x - 9, PX, Color("b03a2e"))
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
	_r(r.position.x + 1, r.position.y + 2.5, r.size.x - 2, PX, Color("5a4d3a"))   # o barbante
	var c := Vector2(r.get_center().x, r.position.y + 21)   # a fogueira
	draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 5), c + Vector2(0, -7), c + Vector2(6, 5)]), Color("e07a2a"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 5), c + Vector2(0, -2), c + Vector2(3, 5)]), Color("f0c040"))
	_r(c.x - 7, c.y + 5, 14, 1, Color("6b4529"))   # as toras, cruzadas
	_r(c.x - 6, c.y + 6, 12, 1, Color("4a2f1c"))
	_r(c.x - 7, c.y + 5, 14, PX, Color("8a5a36"))
	for k in 4:   # o convite
		_r(r.position.x + 4, r.position.y + 29 + k * 1.5, r.size.x - 8 - (k % 2) * 4, PX, Color("5a4d3a"))
	_sprite(Switchboard.disc(5, [[2.5, Color("e07060"), Color("b03a2e"), Color("7a2418")]]), Vector2(r.get_center().x, r.position.y) * 2.0, Color.WHITE, X2)   # a tachinha


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
	var hz := sky.lightened(0.12)   # o céu clareia perto do horizonte, liso (em faixas, pareciam camadas)
	_ci.draw_polygon(PackedVector2Array([Vector2(wx, wy + wh * 0.3), Vector2(wx + ww, wy + wh * 0.3), Vector2(wx + ww, wy + wh * 0.66),
		Vector2(wx, wy + wh * 0.66)]), PackedColorArray([sky, sky, hz, hz]))
	_r(wx, wy + wh * 0.66, ww, wh * 0.34, hz)
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			_r(wx + floorf(s.x * ww), wy + floorf(s.y * wh), PX, PX, Color("c9d2dc") if sin(tw + i * 1.7) > -0.6 else Color("56606c"))
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
		for p in b["lit"]:   # as janelas acesas, com a travessa no meio; a cidade vai dormindo
			if minutes >= p.z:
				continue
			flicked += 1
			if flick and flicked % 3 == 0:
				continue
			var lc: Color = LIT[int(p.x + p.y) % LIT.size()]
			_r(bx + p.x, by + p.y, 1.5, 2, lc)
			_r(bx + p.x, by + p.y + 1, 1.5, PX, lc.darkened(0.45))
	_draw_church(Vector2(wx + floorf(ww * 0.36), street), house)
	# a rua, o poste e o chão
	_r(wx, street, ww, 10, Color("10161b") if fog else Color("06090c"))
	_r(wx, street, ww, PX, Color("1d262c"))
	_r(wx, street + 3, ww, PX, Color("0c1115"))   # o meio-fio
	var lamp := Vector2(wx + floorf(ww * 0.8), street - 26)
	_r(lamp.x, lamp.y, PX, 26, Color("1d262c"))
	_r(lamp.x - 2.5, lamp.y - 1, 4, 1, Color("1d262c"))
	_r(lamp.x - PX, street - 2, 1.5, 2, Color("1d262c"))   # o pé do poste
	var on := lamp_level > 0.5
	if on:
		_r(lamp.x - 2, lamp.y, 3, PX, Color("ffd88a"))
		_ci.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-2, 2), lamp + Vector2(1, 2), lamp + Vector2(10, 26), lamp + Vector2(-11, 26)]),
			Color(1.0, 0.85, 0.55, 0.07 if not fog else 0.12))
		_light(Rect2((lamp + Vector2(-2, 1)) * 2.0, Vector2(6, 2)), Color("ffd88a"), 0.8)
	if weather == "rain":   # o chão molhado reflete as luzes
		for b in _city:
			var on_now: Array = b["lit"].filter(func(w: Vector3): return minutes < w.z)
			if not on_now.is_empty():
				var p: Vector3 = on_now[0]
				for k in 4:   # o reflexo, quebrado pelas poças
					_r(wx + b["x"] + p.x, street + 1.5 + k * 1.5, 1.5, PX, Color(LIT[0], 0.3 - k * 0.06))
		if on:
			for k in 5:
				_r(lamp.x - PX - (k % 2) * PX, street + 1.5 + k * 1.5, 1.5, PX, Color(1.0, 0.85, 0.55, 0.35 - k * 0.05))
	if shadow:
		# cabeça e ombros de alguém parado lá fora, contra a luz do poste (a névoa e a chuva passam por cima)
		var sx := wx + roundf(ww * 0.71)
		var base := street + 8.0
		var halo := PackedVector2Array()   # a luz do poste atrás dela, lisa
		for i in 24:
			halo.append(Vector2(sx + 3, base - 10) + Vector2(cos(TAU * i / 24.0), sin(TAU * i / 24.0)) * 22.0)
		_light_fan(Vector2(sx + 3, base - 10), halo, Color(0.85, 0.62, 0.3, 0.18))
		_ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 9, base), Vector2(sx - 7, base - 9), Vector2(sx - 2, base - 12),
			Vector2(sx + 2, base - 12), Vector2(sx + 7, base - 9), Vector2(sx + 9, base)]), Color.BLACK)
		_r(sx - 1, base - 15, 3, 3, Color.BLACK)
		_ci.draw_circle(Vector2(sx + 0.5, base - 18), 3.5, Color.BLACK)


## As casas da vista, sorteadas sempre do mesmo jeito para cada tamanho de vidro (a cidade não muda de uma noite para
## outra): largura, altura, telhado e quais janelas estão acesas, cada uma com a hora em que apaga (`SLEEP`; algumas
## ficam acesas a noite toda): com o turno, a cidade vai dormindo.
func _build_city(gs: Vector2) -> void:
	_city.clear()
	_city_for = gs
	var rng := RandomNumberGenerator.new()
	rng.seed = 1957
	var sleep := RandomNumberGenerator.new()   # à parte: as casas continuam as mesmas
	sleep.seed = 1958
	var x := 1.0
	while x < gs.x - 4.0:
		var bw := minf(float(rng.randi_range(10, 20)), gs.x - x)   # a última casa termina na borda do vidro
		var church := absf(x + bw / 2.0 - gs.x * 0.36) < 12.0
		var bh := float(rng.randi_range(10, 26)) * (0.6 if church else 1.0)
		var lit: Array[Vector3] = []
		for yy in range(4, int(bh) - 3, 5):
			for xx in range(3, int(bw) - 3, 5):
				if rng.randf() < 0.22:
					var off := INF if sleep.randf() < SLEEP.z else sleep.randf_range(SLEEP.x, SLEEP.y)
					lit.append(Vector3(xx, yy, off))
		_city.append({"x": x, "w": bw, "h": bh, "roof": rng.randf() < 0.55 and x + bw < gs.x - 1.0, "lit": lit})
		x += bw + float(rng.randi_range(1, 4))


## A igreja da praça: nave, torre com a ponta e o relógio aceso no alto; a porta acesa até `CHURCH_DARK`.
func _draw_church(base: Vector2, col: Color) -> void:
	_r(base.x - 12, base.y - 18, 24, 18, col)
	_ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-13, -18), base + Vector2(0, -26), base + Vector2(13, -18)]), col)
	_r(base.x - 4, base.y - 48, 8, 30, col)
	_ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-5, -48), base + Vector2(0, -60), base + Vector2(5, -48)]), col)
	_r(base.x - PX, base.y - 64, PX, 4, col)   # a cruz
	_r(base.x - 1.5, base.y - 63, 2.5, PX, col)
	var face := base + Vector2(0, -40)
	_ci.draw_circle(face, 2.5, Color("e2b25a"))
	_r(face.x - PX, face.y - 2, PX, 2, Color("2a2016"))   # os ponteiros
	_r(face.x - PX, face.y - PX, 1.5, PX, Color("2a2016"))
	for k in 3:   # as janelinhas da torre e a da nave
		_r(base.x - PX, base.y - 32 + k * 6, PX, 2, Color("1a2028"))
	_light(Rect2((face - Vector2(2.5, 2.5)) * 2.0, Vector2(10, 10)), Color("e2b25a"), 0.6, true)
	if minutes < CHURCH_DARK:
		_r(base.x - 2, base.y - 10, 4, 10, Color(LIT[1], 0.8))   # a porta, com luz dentro (o relógio fica aceso)


## A poeira na luz da luminária: grãos de um pixel em toda a área que ela ilumina (a do brilho da luz de teto,
## `%Glow`: um círculo largo a partir do alto do meio da tela, que passa por cima da mesa comutadora), mais claros
## perto da luminária e brilhando devagar ao virarem na luz. Fica na camada `dust`, acima da mesa comutadora (a
## poeira que passa na frente dela); o papel de uma ferramenta fica na frente, e ela não desce abaixo do fundo do tampo.
func _draw_dust() -> void:
	var k := lamp_level * (0.5 if _cover.has_area() else 1.0)
	var c := Vector2(_lamp_x * 2.0, 0.0)   # px da tela
	var reach := size.x * 0.5
	for m in _motes:
		var p := Vector2(c.x + m.x * reach, m.y * _top * 2.0)
		var a := (1.0 - minf(1.0, p.distance_to(c) / reach)) * (0.5 + 0.5 * sin(m.z)) * 0.6 * k
		if a > 0.02 and not _cover.has_point(p):
			_dust.draw_rect(Rect2(p.floor(), Vector2.ONE), Color(1.0, 0.9, 0.7, a))


## O clima no vidro: a chuva passando e as gotas paradas no vidro, que às vezes escorrem (chuva), faixas de névoa
## passando (névoa) e um reflexo na diagonal.
func _draw_glass_weather(g: Rect2) -> void:
	if weather == "rain":
		for d in _drops:
			if d.x >= 0.0 and d.x < 1.0 and d.y >= 0.0:
				var dp := Vector2(g.position.x + floorf(d.x * g.size.x * 2.0) * PX, g.position.y + floorf(d.y * (g.size.y - 3)))
				_r(dp.x, dp.y, PX, 2, Color("3a5563"))   # a gota escorrendo, com o brilho na ponta
				_r(dp.x, dp.y + 2, PX, PX, Color("6a8593"))
		# as gotas no vidro, só na parte dele que aparece: escuras, com um brilho, quente perto do poste (`_draw_city`)
		var top := g.position.y + g.size.y * _glass_from
		var post := g.position + Vector2(floorf(g.size.x * 0.8), g.size.y - 36.0)
		for b in _beads:
			var p := Vector2(g.position.x + floorf(b.x * g.size.x * 2.0) * PX, top + floorf(b.y * (g.end.y - top) * 2.0) * PX)
			if b.w > 0.0:   # escorrendo: o rastro molhado acima dela
				for k in 4:
					_r(p.x, p.y - (k + 1) * PX, PX, PX, Color(0.55, 0.66, 0.74, 0.2 - k * 0.045))
			_r(p.x, p.y, b.z * PX, b.z * PX, Color("1c2a32"))
			var warm := clampf(1.0 - p.distance_to(post) / 30.0, 0.0, 1.0) if lamp_level > 0.5 else 0.0
			_r(p.x, p.y, PX, PX, Color("7f98a8").lerp(Color("ffd88a"), warm))
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
	var w2 := r.size.x * 2.0
	if desk_art:
		draw_texture_rect(desk_art, Rect2(r.position, Vector2(r.size.x, depth)), true)
	else:
		_r(r.position.x, r.position.y, r.size.x, depth, Color("241a12"))
		# as emendas: tábuas da mesma largura, espaçadas pela câmera (mais juntas no fundo)
		var zb := Z0 / DESK_T
		var zf := Z0 * _yd / (front - _vp.y)
		for k in PLANKS:
			var y0 := roundf(_proj(0, _yd, lerpf(zb, zf, float(k) / PLANKS)).y * 2.0)
			var y1 := roundf(_proj(0, _yd, lerpf(zb, zf, float(k + 1) / PLANKS)).y * 2.0)
			_p(0, y1 - 1, w2, 1, Color("1a120c"))
			_p(0, y0, w2, 1, Color("2b2016"))   # a beira de cada tábua pega luz
			for i in int(w2 / 60.0):   # os veios, mais compridos na frente (mais perto)
				var gx := fmod(i * 197.0 + k * 61.0, w2)
				var gy := roundf(y0 + (y1 - y0) * (0.25 + 0.5 * ((i * 7 + k) % 5) / 4.0))
				var gl := 16.0 + (i % 4) * 10.0 + k * 10.0
				_p(gx, gy, gl, 1, Color("2e2219"))
				_p(gx + gl * 0.3, gy + 1, gl * 0.5, 1, Color("20170f"))
		for k in 2:   # o fundo escurece de leve (sem linha na quina: com ela parecia o rodapé de um chão)
			_r(r.position.x, r.position.y, r.size.x, depth * (0.16 - k * 0.08), Color(0, 0, 0, 0.04))
	# a luz da luminária: um círculo no tampo, embaixo dela (que fica um pouco à frente do fundo da mesa), liso e mais
	# forte no meio; o que passaria do fundo do tampo fica na parede (o arco de `_draw_wall_light`)
	var pool := _pool()
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(_proj(pool.x + cos(a) * POOL_R, _yd, clampf(pool.y + sin(a) * POOL_R * 0.5, 40.0, Z0 / DESK_T)))
	_light_fan(_proj(pool.x, _yd, pool.y), pts, Color(1.0, 0.78, 0.48, 0.22 * lamp_level))
	# a borda da frente: o canto arredondado do tampo pega a luz, a espessura dele e, embaixo, o escuro sob a mesa
	var f := front * 2.0
	_p(0, f - 2, w2, 1, Color("5a4030"))
	_p(0, f - 1, w2, 1, Color("7a5434"))
	_p(0, f, w2, 2, Color("6b4529"))
	_p(0, f + 2, w2, 8, Color("3a2616"))
	_p(0, f + 4, w2, 1, Color("442c1a"))   # um friso na espessura
	_p(0, f + 10, w2, 2, Color("1a120c"))
	_r(r.position.x, front + 6, r.size.x, r.end.y - front - 6, Color("0a0705"))


## Na mesa, embaixo da janela, ao alcance do operador: as listas telefônicas, o caderno aberto, a caneca de café, a
## prancheta do registro e o mapa dobrado, do fundo para a frente (quem está mais perto é desenhado por cima). Cada um
## fica num lugar da sala (x a partir dos olhos, z a distância; ver `Z0`) e é desenhado em px da tela (1x1).
func _draw_desk_props() -> void:
	draw_set_transform(Vector2.ZERO)
	# em duas fileiras, distribuídas de ponta a ponta entre a lateral da mesa comutadora e a parede da direita (a
	# mesma folga entre eles, em qualquer largura de janela: presos a uma ponta só, sobrava mesa vazia na outra, e
	# presos a pontas diferentes, eles se trombavam). Atrás: listas, caderno e o relógio com a caneca na frente dele;
	# na frente: mapa, prancheta e o lugar do jornal (guardado mesmo sem ele, para nada mudar de lugar entre as noites).
	# Todos em `PROP_K`, a escala dos plugs da mesa comutadora (que seguem as tomadas)
	var l := _side_x + 8.0
	var r := _cx - _vp.x - WALL_PAD   # a parede da direita é o plano x = quina (na escala da parede do fundo)
	var k := PROP_K
	var cw := CLOCK.x + 2.0   # o relógio, meio virado, ocupa um pouco mais que a largura dele
	var mr := 6.6 * k         # a caneca, na frente do relógio, encostada na ponta direita dele
	var back := _row(l, r, [33.0 * k, 51.0 * k, cw + mr])
	var near := _row(l + 4.0, r, [40.0 * k, 29.0 * k, 37.0 * k])
	_draw_books(back[0], _at(0.5), 33 * k, _deep(0.32 * k))
	_flat("caderno", back[1], _at(0.52), 51 * k, _deep(0.28 * k), 2 * k, Color("3a2414"), _draw_open_notebook)
	_draw_flip_clock(back[2] + cw / 2.0, _at(0.72))   # logo atrás da caneca (desenhado antes dela)
	_draw_mug(back[2] + cw, _at(0.46), mr, 15 * k)
	_flat("despacho", near[0], _at(0.04), 40 * k, _deep(0.21 * k), 1 * k, Color("a89a76"), _draw_folded_map)
	_flat("registro", near[1], _at(0.03), 29 * k, _deep(0.32 * k), 2 * k, Color("4a3018"), _draw_clipboard)
	if news:
		_flat("jornal", near[2], _at(0.05), 37 * k, _deep(0.21 * k), 2 * k, Color("b8b0a0"), _draw_newspaper)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O relógio da sala: um relógio de flip na mesa (centro `xc`, `zc`; medidas em `CLOCK`), meio virado para o operador
## (`CLOCK_TURN` do ângulo até os olhos, `_yaw`): caixa de baquelite creme numa base escura e, na janela, as duas plaquetas (horas e minutos), que viram
## quando a hora muda (`minutes`, `_flip_step`); no tampo, as fendas e o botão do alarme; no lado, a rodinha de
## acertar a hora. É o único relógio da tela.
func _draw_flip_clock(xc: float, zc: float) -> void:
	_yaw = -CLOCK_TURN * atan2(xc, zc)   # a frente gira para os olhos (que estão na origem)
	var hw := CLOCK.x / 2.0
	var hd := CLOCK.z / 2.0
	var bh := 1.5 * PROP_K   # a base, um pouco maior que a caixa, que a levanta da mesa
	_desk_shadow(PackedVector2Array([_clock_pt(xc, zc, -hw - 1, hd + 1, _yd), _clock_pt(xc, zc, hw + 1, hd + 1, _yd),
		_clock_pt(xc, zc, hw + 1, -hd - 1, _yd), _clock_pt(xc, zc, -hw - 1, -hd - 1, _yd)]))
	var dark := _shade(xc, zc)
	var lit := Color.WHITE.darkened(dark)   # longe da luz
	_clock_box(xc, zc, hw + 0.8, hd + 0.8, _yd, bh, Color("4e3a28"), Color("2a1d13"), Color("3a2a1c"))
	var box := _clock_box(xc, zc, hw, hd, _yd - bh, CLOCK.y, Color("dccfa8"), Color("998a66"), Color.TRANSPARENT)
	var y1 := _yd - bh - CLOCK.y
	clock_x = global_position.x + _bounds(box["top"]).get_center().x
	for i in 4:   # as fendas do alarme, no fundo do tampo
		var v := hd - 1.6 - i * 1.1
		_pixel_line(_clock_pt(xc, zc, -hw * 0.75, v, y1), _clock_pt(xc, zc, 0.0, v, y1), [Color("a89a76").darkened(dark)])
	var bt := _clock_pt(xc, zc, hw * 0.55, hd * 0.3, y1)   # o botão niquelado do alarme
	_sprite(Switchboard.disc(7, [[3.5, Color(0, 0, 0, 0.3)]]), bt + Vector2(1, 0))
	_sprite(Switchboard.disc(6, [[1.2, Color("f4f0e6")], [3.0, Color("d6d1c3"), Color("8e897c"), Color("45413a")]]), bt - Vector2(0, 2), lit)
	if box.has("left"):   # a rodinha serrilhada de acertar a hora, saindo do lado
		var a := _clock_pt(xc, zc, -hw - 0.8, hd * 0.3, y1 + CLOCK.y * 0.5 - 2.4).round()
		var b := _clock_pt(xc, zc, -hw - 0.8, hd * 0.3, y1 + CLOCK.y * 0.5 + 2.4).round()
		draw_rect(Rect2(a.x + 2, a.y + 1, 1, b.y - a.y), Color(0, 0, 0, 0.35))   # a sombra no lado
		for y in range(int(a.y), int(b.y)):
			draw_rect(Rect2(a.x - 1, y, 3, 1), (Color("b8b2a2") if int(y - a.y) % 2 == 0 else Color("5a574e")).darkened(dark))
	if not box.has("front"):
		return
	# a frente: montada reta, pixel a pixel (`_clock_face`), e posta coluna a coluna na perspectiva (como imagem torta
	# por uma transformação, os algarismos quebravam): cada coluna da tela é um raio dos olhos, que acerta a frente num
	# ponto dela (`a`, de 0 a 1 na largura) a uma distância `z`; de pé, a coluna vai da altura de cima à de baixo nela
	var front: PackedVector2Array = box["front"]
	var l := _clock_xz(xc, zc, -hw, -hd)
	var r := _clock_xz(xc, zc, hw, -hd)
	var x0 := roundi(front[0].x)
	var w := roundi(front[1].x) - x0
	var h := roundi(((front[3].y - front[0].y) + (front[2].y - front[1].y)) / 2.0)
	if w < 8 or h < 8:
		return
	var face := _clock_face(Vector2i(w, h))
	for i in w:
		var t := ((x0 + i + 0.5) / 2.0 - _vp.x) / Z0   # o rumo do raio: x/z
		var a := clampf((t * l.y - l.x) / ((r.x - l.x) - t * (r.y - l.y)), 0.0, 0.999)
		var p := l.lerp(r, a)
		var y0 := roundf(_p3(0, y1, p.y).y)
		var y2 := roundf(_p3(0, y1 + CLOCK.y, p.y).y)
		var sh := _shade(p.x, p.y)   # longe da luz, coluna a coluna
		draw_texture_rect_region(face, Rect2(x0 + i, y0, 1, y2 - y0), Rect2(floorf(a * w), 0, 1, h), Color.WHITE.darkened(sh))
		draw_rect(Rect2(x0 + i, y0 - 1, 1, 1), Color("dccfa8").darkened(sh))   # a quina com o tampo (sem ela, sobravam furos)


## Onde fica na sala (x, z) o ponto do relógio a `u` na largura e `v` no fundo, a partir do centro (`xc`, `zc`), girado
## por `_yaw`.
func _clock_xz(xc: float, zc: float, u: float, v: float) -> Vector2:
	return Vector2(xc + u * cos(_yaw) - v * sin(_yaw), zc + u * sin(_yaw) + v * cos(_yaw))


## Um ponto do relógio da mesa na tela (`_clock_xz`); `y`, a altura.
func _clock_pt(xc: float, zc: float, u: float, v: float, y: float) -> Vector2:
	var p := _clock_xz(xc, zc, u, v)
	return _p3(p.x, y, p.y)


## Uma caixa do relógio, girada como ele (meia largura `hw`, meio fundo `hd`, de `y0` até `h` acima): só as faces
## viradas para os olhos, as de pé em `side` (a da frente em `front`; transparente, quem chama a desenha) e o tampo em
## `top`, escurecendo ponto a ponto longe da luz (`_shade`). Devolve as faces que apareceram ("front", "right", "back",
## "left", "top").
func _clock_box(xc: float, zc: float, hw: float, hd: float, y0: float, h: float, top: Color, side: Color, front: Color) -> Dictionary:
	var cs := cos(_yaw)
	var sn := sin(_yaw)
	var y1 := y0 - h
	var out := {}
	# [nome, normal (u, v), de onde a onde (u, v), da esquerda para a direita de quem olha de fora]
	for f in [["front", Vector2(0, -1), Vector2(-hw, -hd), Vector2(hw, -hd)], ["right", Vector2(1, 0), Vector2(hw, -hd), Vector2(hw, hd)],
			["back", Vector2(0, 1), Vector2(hw, hd), Vector2(-hw, hd)], ["left", Vector2(-1, 0), Vector2(-hw, hd), Vector2(-hw, -hd)]]:
		var n: Vector2 = f[1]
		var m: Vector2 = (f[2] + f[3]) / 2.0
		if Vector2(n.x * cs - n.y * sn, n.x * sn + n.y * cs).dot(-Vector2(xc + m.x * cs - m.y * sn, zc + m.x * sn + m.y * cs)) <= 0.0:
			continue
		var q := PackedVector2Array([_clock_pt(xc, zc, f[2].x, f[2].y, y1), _clock_pt(xc, zc, f[3].x, f[3].y, y1),
			_clock_pt(xc, zc, f[3].x, f[3].y, y0), _clock_pt(xc, zc, f[2].x, f[2].y, y0)])
		if _bounds(q).size.x < 1.0:   # quase de perfil, não aparece (e o polígono nem fecha)
			continue
		out[f[0]] = q
		var col: Color = front if f[0] == "front" else side
		if col.a > 0.0:
			var a := _clock_xz(xc, zc, f[2].x, f[2].y)
			var b := _clock_xz(xc, zc, f[3].x, f[3].y)
			_shaded(q, [a, b, b, a], col)
			if f[0] == "left":   # a quina com a frente pega a luz
				draw_line(q[1], q[2], col.lightened(0.15).darkened(_shade(b.x, b.y)), 1.0)
			elif f[0] == "right":
				draw_line(q[0], q[3], col.lightened(0.15).darkened(_shade(a.x, a.y)), 1.0)
	out["top"] = PackedVector2Array([_clock_pt(xc, zc, -hw, hd, y1), _clock_pt(xc, zc, hw, hd, y1), _clock_pt(xc, zc, hw, -hd, y1), _clock_pt(xc, zc, -hw, -hd, y1)])
	_shaded(out["top"], [_clock_xz(xc, zc, -hw, hd), _clock_xz(xc, zc, hw, hd), _clock_xz(xc, zc, hw, -hd), _clock_xz(xc, zc, -hw, -hd)], top)
	return out


## Uma face na cor `col`, escurecendo ponto a ponto longe da luz (`xz`: os pontos dela na sala).
func _shaded(pts: PackedVector2Array, xz: Array, col: Color) -> void:
	var cols := PackedColorArray()
	for p in xz:
		cols.append(col.darkened(_shade(p.x, p.y)))
	draw_polygon(pts, cols)


## A frente do relógio, de frente, em `sz` px: a caixa creme, a janela preta de aro niquelado com as duas plaquetas
## (horas e minutos) e a plaquinha de latão da marca embaixo. Guardada até a hora ou a virada mudar.
var _face_key := []
var _face: ImageTexture
func _clock_face(sz: Vector2i) -> ImageTexture:
	var m := int(minutes) % 1440
	var was := (_flip_from + 1440) % 1440
	var step := _flip_step()
	var key := [sz, m, was, step]
	if key == _face_key:
		return _face
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Color("c9bb92"))   # um creme envelhecido: mais claro, puxava o olho mais que os outros objetos
	img.fill_rect(Rect2i(0, 0, sz.x, 1), Color("e4d8b4"))
	img.fill_rect(Rect2i(0, sz.y - 1, sz.x, 1), Color("998a66"))
	var win := Rect2i(3, 3, sz.x - 6, sz.y - 8)
	img.fill_rect(win.grow(1), Color("998a66"))   # o rebaixo em volta do aro
	img.fill_rect(win, Color("b8b2a2"))   # o aro niquelado: claro em cima, escuro embaixo
	img.fill_rect(Rect2i(win.position.x, win.end.y - 1, win.size.x, 1), Color("5a574e"))
	img.fill_rect(win.grow(-1), Color("0e0c0a"))
	img.fill_rect(Rect2i(sz.x / 2 - 6, sz.y - 4, 12, 2), Color("8a6a2e"))   # a plaquinha da marca, embaixo da janela
	img.fill_rect(Rect2i(sz.x / 2 - 6, sz.y - 4, 12, 1), Color("c4a35a"))
	var card := Vector2i((win.size.x - 5) / 2, win.size.y - 4)
	_flip_card(img, Vector2i(win.position.x + 2, win.position.y + 2), card, "%02d" % (was / 60), "%02d" % (m / 60), step)
	_flip_card(img, Vector2i(win.end.x - 2 - card.x, win.position.y + 2), card, "%02d" % (was % 60), "%02d" % (m % 60), step)
	_face_key = key
	_face = ImageTexture.create_from_image(img)
	return _face


## Uma plaqueta do relógio em `img`, em `at` e do tamanho `sz`, virando de `a` para `b` no passo `step` (0: a metade
## de cima de `a` caindo; 1: ela de lado; 2: a metade de baixo de `b` descendo; 3: parada em `b`). Atrás da que cai,
## em cima já está `b` e embaixo ainda `a`.
func _flip_card(img: Image, at: Vector2i, sz: Vector2i, a: String, b: String, step: int) -> void:
	var cb := _card(b, sz)
	if step >= 3 or a == b:
		img.blit_rect(cb, Rect2i(Vector2i.ZERO, sz), at)
		return
	var ca := _card(a, sz)
	var h := sz.y / 2
	img.blit_rect(cb, Rect2i(0, 0, sz.x, h), at)
	img.blit_rect(ca, Rect2i(0, h, sz.x, sz.y - h), at + Vector2i(0, h))
	if step == 1:   # de lado: só a espessura dela
		img.fill_rect(Rect2i(at.x, at.y + h - 1, sz.x, 2), Color("3a352e"))
		return
	var flap := (ca if step == 0 else cb).get_region(Rect2i(0, 0, sz.x, h) if step == 0 else Rect2i(0, h, sz.x, sz.y - h))
	flap.resize(sz.x, maxi(1, flap.get_height() / 2), Image.INTERPOLATE_NEAREST)   # inclinada, encurta
	flap.adjust_bcs(0.8, 1.0, 1.0)   # e pega menos luz
	img.blit_rect(flap, Rect2i(Vector2i.ZERO, flap.get_size()), at + Vector2i(0, h - flap.get_height() if step == 0 else h))


## A plaqueta com os dois algarismos `text` (`DIGITS`; reduzidos se a plaqueta for menor), do tamanho `sz`: preta,
## com a beira de cima clara e a divisa no meio, onde ela dobra. Guardada.
static var _cards := {}
func _card(text: String, sz: Vector2i) -> Image:
	var key := text + str(sz)
	if _cards.has(key):
		return _cards[key]
	if _cards.size() > 200:   # a tela mudou de tamanho: o relógio também
		_cards.clear()
	var img := Image.create(maxi(1, sz.x), maxi(1, sz.y), false, Image.FORMAT_RGBA8)
	img.fill(Color("1e1b17"))
	img.fill_rect(Rect2i(0, 0, sz.x, 1), Color("3a352e"))
	img.fill_rect(Rect2i(0, sz.y / 2, sz.x, 1), Color("060505"))   # a divisa (por baixo dos algarismos: cortados, não se liam)
	var ink := Image.create(21, 19, false, Image.FORMAT_RGBA8)   # os dois algarismos, com 3 px entre eles
	for i in 2:
		for r in 19:
			var row: String = DIGITS[r].substr(int(text[i]) * 10, 9)
			for c in 9:
				if row[c] == "#":
					ink.set_pixel(i * 12 + c, r, Color("efe4c4"))
	var fit := minf(1.0, minf((sz.x - 2) / 21.0, (sz.y - 4) / 19.0))
	if fit < 1.0:
		ink.resize(maxi(1, int(21 * fit)), maxi(1, int(19 * fit)), Image.INTERPOLATE_NEAREST)
	img.blend_rect(ink, Rect2i(Vector2i.ZERO, ink.get_size()), (sz - ink.get_size() + Vector2i(0, 1)) / 2)
	_cards[key] = img
	return img


## Uma fileira de objetos das larguras `ws` de `a` a `b` (x da sala), com a mesma folga entre eles (nunca negativa:
## numa tela estreita demais, eles se encostam e passam de `b`). Devolve onde cada um começa.
func _row(a: float, b: float, ws: Array) -> Array:
	var total := 0.0
	for w in ws:
		total += w
	var gap := maxf(0.0, (b - a - total) / maxf(1.0, ws.size() - 1.0))
	var out := []
	for w in ws:
		out.append(a)
		a += w + gap
	return out


## Onde fica no tampo (z) o que está a `t` da frente dele (0 = a borda da frente, 1 = o fundo): os objetos da mesa
## ficam no tampo seja qual for a câmera.
func _at(t: float) -> float:
	return lerpf(_zd.x, _zd.y, t)


## Uma profundidade (z) que é a fração `t` do tampo.
func _deep(t: float) -> float:
	return t * (_zd.y - _zd.x)


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
## desenho de frente de um objeto chato vira o tampo dele na perspectiva. Devolve [Transform2D, size].
func _top_xf(q: PackedVector2Array) -> Array:
	var u := ((q[1] - q[0]) + (q[2] - q[3])) / 2.0
	var v := ((q[3] - q[0]) + (q[2] - q[1])) / 2.0
	var s := Vector2(maxf(1.0, roundf(u.length())), maxf(1.0, roundf(absf(v.y))))
	var c := (q[0] + q[1] + q[2] + q[3]) / 4.0
	return [Transform2D(u / s.x, v / s.y, c - u / 2.0 - v / 2.0), s]


## Sombra de um objeto na mesa (`foot`, a marca dele no tampo), apontando para longe da luminária, em degraus: a
## penumbra em volta, a sombra e, colado na base, o escuro de onde ele encosta na mesa (sem ele, os objetos pareciam
## pousados por cima do tampo).
func _desk_shadow(foot: PackedVector2Array) -> void:
	var off := Vector2(clampf((_bounds(foot).get_center().x - _lamp_x * 2.0) / 60.0, -6.0, 8.0), 4.0).round()
	var pts := PackedVector2Array()
	for p in foot:
		pts.append(p + off)
	for g in Geometry2D.offset_polygon(pts, 1.5, Geometry2D.JOIN_MITER):
		draw_colored_polygon(g, Color(0, 0, 0, 0.15))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.3))
	for g in Geometry2D.offset_polygon(foot, 1.0, Geometry2D.JOIN_MITER):
		draw_colored_polygon(g, Color(0, 0, 0, 0.45))


## Onde fica a poça de luz da luminária no tampo (x, z da sala): embaixo dela, um pouco à frente do fundo da mesa.
func _pool() -> Vector2:
	var zl := Z0 / DESK_T * 0.85
	return Vector2((_lamp_x - _vp.x) * zl / Z0, zl)


## Quanto o ponto (`x`, `z`) da mesa fica no escuro: nada embaixo da luminária e mais longe da poça de luz, até
## `SHADE_MAX`; a luminária piscando escurece tudo junto (os objetos tinham a mesma cor em qualquer lugar da mesa e
## pareciam soltos da luz da sala). Contínuo: cada objeto escurece ponto a ponto (`_dim`), não de um tom só.
func _shade(x: float, z: float) -> float:
	var p := _pool()
	var d := Vector2((x - p.x) / POOL_R, (z - p.y) / (POOL_R * 0.5)).length()
	return clampf((d - 0.35) * 0.5, 0.0, SHADE_MAX) + (1.0 - lamp_level) * 0.3


## Escurece o polígono `pts` (px da tela) longe da luz, ponto a ponto: `xz` são os mesmos pontos na sala (x, z), e o
## escuro de cada um (`_shade`) varia liso entre eles.
func _dim(pts: PackedVector2Array, xz: Array) -> void:
	var cols := PackedColorArray()
	for p in xz:
		cols.append(Color(0, 0, 0, _shade(p.x, p.y)))
	draw_polygon(pts, cols)


## Um objeto chato que abre a ferramenta `id`: a sombra, a espessura (`h`, na cor `edge`: a frente e o lado virado para
## o ponto de fuga) e o tampo, desenhado de frente por `paint` (um retângulo de px) e posto na perspectiva. Devolve o
## tampo (px da tela).
func _flat(id: String, x0: float, zf: float, wx: float, dz: float, h: float, edge: Color, paint: Callable) -> PackedVector2Array:
	var foot := _box(x0, zf, wx, dz, _yd, 0.0)["top"] as PackedVector2Array
	_desk_shadow(foot)
	var dark := _shade(x0 + wx / 2.0, zf + dz / 2.0)
	var bx := _box(x0, zf, wx, dz, _yd, h)
	if not (bx["side"] as PackedVector2Array).is_empty():
		_poly(bx["side"], edge.darkened(0.35).darkened(dark))
	_poly(PackedVector2Array([bx["top"][3], bx["top"][2], foot[2], foot[3]]), edge.darkened(dark))
	var xf: Array = _top_xf(bx["top"])
	_paint_xf = xf[0]
	draw_set_transform_matrix(xf[0])
	paint.call(Rect2(Vector2.ZERO, xf[1]))
	draw_set_transform(Vector2.ZERO)
	var t: Transform2D = xf[0]   # longe da luz, ponto a ponto
	var s: Vector2 = xf[1]
	_dim(PackedVector2Array([t * Vector2.ZERO, t * Vector2(s.x, 0), t * s, t * Vector2(0, s.y)]),
		[Vector2(x0, zf + dz), Vector2(x0 + wx, zf + dz), Vector2(x0 + wx, zf), Vector2(x0, zf)])
	_props[id] = _bounds(foot + (bx["top"] as PackedVector2Array))
	return bx["top"]


## As listas telefônicas, três volumes grossos empilhados meio tortos: a lombada na cor da capa, do lado virado para o
## ponto de fuga, com os filetes dourados; na frente, o miolo de papel com as folhas marcadas entre as capas; e, no de
## cima, o tampo com a faixa do título e o emblema da central.
func _draw_books(x0: float, zf: float, wx: float, dz: float) -> void:
	var cols := [Color("8e2a22"), Color("2a4a7c"), Color("b48c1c")]
	var offs := [Vector2(1, 0) * PROP_K, Vector2(3, 2) * PROP_K, Vector2(0, 1) * PROP_K]   # meio tortos: x e z de cada volume
	var bh := 5.5 * PROP_K
	var all := PackedVector2Array()
	_desk_shadow(_box(x0, zf, wx, dz, _yd, 0.0)["top"])
	for b in 3:
		var c: Color = cols[b]
		var bx := _box(x0 + offs[b].x, zf + offs[b].y, wx, dz, _yd - b * bh, bh)
		var side: PackedVector2Array = bx["side"]
		if not side.is_empty():
			_poly(side, c.darkened(0.2))   # a lombada
			_pixel_line(side[0].lerp(side[3], 0.3), side[1].lerp(side[2], 0.3), [Color("e0c07a")])
			_pixel_line(side[0].lerp(side[3], 0.7), side[1].lerp(side[2], 0.7), [Color("e0c07a")])
		var top: PackedVector2Array = bx["top"]
		_poly(top, c)
		var f: Rect2 = bx["front"]
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
			_sprite(Switchboard.disc(6, [[1.8, Color("f0d8a0"), Color("e0c07a"), Color("b8924e")], [3.0, c.darkened(0.35)]]), (xf[0] as Transform2D) * Vector2(s.x - 8, s.y * 0.5))
		# longe da luz, ponto a ponto: cada volume logo depois de desenhado (os de cima cobrem os de baixo)
		var x: float = x0 + offs[b].x
		var z: float = zf + offs[b].y
		var sx: float = x if x > 0.0 else x + wx
		if not side.is_empty():
			_dim(side, [Vector2(sx, z + dz), Vector2(sx, z), Vector2(sx, z), Vector2(sx, z + dz)])
		_dim(top, [Vector2(x, z + dz), Vector2(x + wx, z + dz), Vector2(x + wx, z), Vector2(x, z)])
		_dim(PackedVector2Array([f.position, Vector2(f.end.x, f.position.y), f.end, Vector2(f.position.x, f.end.y)]),
			[Vector2(x, z), Vector2(x + wx, z), Vector2(x + wx, z), Vector2(x, z)])
	_props["lista"] = _bounds(all)


## A caneca de café em pé na mesa (centro `xc`, `zc`; raio `rr`, altura `hh`): cerâmica creme com o sombreado do
## cilindro, a boca em elipse com o café, a alça e o emblema da central.
func _draw_mug(xc: float, zc: float, rr: float, hh: float) -> void:
	var a := _p3(xc - rr, _yd - hh, zc).round()
	var body := Rect2(a, _p3(xc + rr, _yd, zc).round() - a)
	var ry := maxf(2.0, roundf((_p3(xc, _yd - hh, zc - rr).y - _p3(xc, _yd - hh, zc + rr).y) / 2.0))
	var rx := body.size.x / 2.0
	_desk_shadow(PackedVector2Array([body.position + Vector2(0, body.size.y - ry), body.end - Vector2(0, ry), body.end, Vector2(body.position.x, body.end.y)]))
	var dark := _shade(xc, zc)
	var lit := Color.WHITE.darkened(dark)   # longe da luz
	draw_texture_rect(Switchboard.art(MUG_HANDLE, {"h": Color("d8caa3"), "H": Color("b8aa86"), "s": Color("8a7c5a")}),
		Rect2(body.end.x - 2, body.position.y + 4, 6, 10), false, lit)
	for x in int(body.size.x):   # o cilindro, coluna a coluna: a luz à esquerda, a sombra à direita, o fundo redondo
		var nx := (x + 0.5) / body.size.x * 2.0 - 1.0
		var col := Color("ece2c6") if nx < -0.55 else (Color("d8caa3") if nx < 0.35 else (Color("c2b288") if nx < 0.75 else Color("a89a76")))
		draw_rect(Rect2(body.position.x + x, body.position.y, 1, body.size.y - ry + roundf(sqrt(1.0 - nx * nx) * ry)), col.darkened(_shade(xc + nx * rr, zc)))
	var top := Vector2(body.get_center().x, body.position.y)
	_ellipse(top, rx + 1, ry + 1, Color("a89a76").darkened(dark))   # a boca, com a beira no tom da sombra da caneca
	_ellipse(top, rx, ry, Color("e3d6b2").darkened(dark))
	_ellipse(top + Vector2(0, 1), rx - 2, ry - 1, Color("3a2414").darkened(dark))   # o café
	_sprite(Switchboard.disc(8, [[1.8, Color("f0d8a0"), Color("e0c07a"), Color("b8924e")], [4.0, Color("8e2a22")]]), body.get_center() + Vector2(-1, 3), lit)   # o emblema


## Uma elipse cheia em pixel art (como polígono, saía embolotada), centrada em `c`. Guardada por tamanho.
static var _ovals := {}
func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var sz := Vector2i(maxi(1, roundi(rx * 2.0)), maxi(1, roundi(ry * 2.0)))
	if not _ovals.has(sz):
		var img := Image.create(sz.x, sz.y, false, Image.FORMAT_LA8)
		var h := Vector2(sz) / 2.0
		for y in sz.y:
			for x in sz.x:
				if ((Vector2(x, y) + Vector2(0.5, 0.5) - h) / h).length_squared() <= 1.0:
					img.set_pixel(x, y, Color.WHITE)
		_ovals[sz] = ImageTexture.create_from_image(img)
	draw_texture_rect(_ovals[sz], Rect2((c - Vector2(sz) / 2.0).floor(), Vector2(sz)), false, col)


## O mapa da cidade dobrado em três, meio aberto na mesa: os painéis alternam luz e sombra nas dobras, com quadras,
## ruas, o rio e um local marcado com alfinete.
func _draw_folded_map(r: Rect2) -> void:
	var pw := r.size.x / 3.0
	for k in 3:
		var pr := Rect2(r.position.x + k * pw, r.position.y, pw, r.size.y)
		draw_rect(pr, Color("e3d6b2") if k != 1 else Color("cdbf98"))   # o painel do meio fica na sombra da dobra
	for x in range(4, int(r.size.x) - 4, 10):   # quadras
		for y in range(4, int(r.size.y) - 4, 8):
			draw_rect(Rect2(r.position.x + x, r.position.y + y, 7, 5), Color(0.62, 0.55, 0.4, 0.55))
	var river := PackedVector2Array([r.position + Vector2(2, r.size.y - 6), r.position + Vector2(30, r.size.y - 12),
		r.position + Vector2(58, r.size.y - 9), r.position + Vector2(r.size.x - 2, 6)])
	for i in river.size() - 1:   # o rio, em pixel art na tela (torto pela perspectiva do mapa, serrilhava)
		_pixel_line(_paint_xf * river[i], _paint_xf * river[i + 1], [Color("6a94c8"), Color("4f7bb6")], _paint_xf)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 2), Color(0.5, 0.42, 0.3, 0.6))   # a avenida
	for k in [1, 2]:   # as dobras
		draw_rect(Rect2(r.position.x + k * pw - 1, r.position.y, 1, r.size.y), Color(0, 0, 0, 0.25))
		draw_rect(Rect2(r.position.x + k * pw, r.position.y, 1, r.size.y), Color(1, 1, 1, 0.25))
	# o alfinete no local marcado: a cabeça redonda vista de cima, fora da perspectiva do mapa (torta, serrilhava)
	var sp := _paint_xf * (r.position + Vector2(r.size.x * 0.7, r.size.y * 0.42))
	var lit := _pin_lit()   # com uma emergência em andamento, ele pisca e brilha
	_sprite(Switchboard.disc(6, [[3.0, Color(0, 0, 0, 0.35)]]), sp + Vector2(2, 2), Color.WHITE, _paint_xf)
	_sprite(Switchboard.disc(6, [[1.2, Color("ffe0c8") if lit else Color("f0a090")],
		[3.0, Color("ff8a6c") if lit else Color("e07060"), Color("ff5a3c") if lit else Color("b03a2e"), Color("c03a22") if lit else Color("7a2418")]]), sp, Color.WHITE, _paint_xf)
	if lit:
		_light(Rect2(sp - Vector2(3, 3), Vector2(6, 6)), Color("ff5a3c"), 0.9, true)


## O caderno de ocorrências aberto: capa de couro em volta, duas páginas pautadas com margem vermelha e anotações à
## mão, a sombra da lombada no meio e o lápis apoiado na página da direita.
func _draw_open_notebook(r: Rect2) -> void:
	for i in mini(pending, 6):   # um registro pendente = uma tira de papel marcando a página, saindo pelo fundo
		var sx := r.position.x + 8 + i * floorf((r.size.x - 22) / 6.0)
		var up := 7.0 + (i * 5) % 4
		draw_rect(Rect2(sx, r.position.y - up, 7, up + 2), Color("f0dc9a") if i % 2 == 0 else Color("e8d8c0"))
		draw_rect(Rect2(sx + 1, r.position.y - up + 2, 5, 1), Color("b03a2e"))
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
	# o lápis, na diagonal sobre a página da direita, em pixel art na tela (torto pela perspectiva do caderno,
	# serrilhava): o corpo com a luz em cima, a madeira apontada e o grafite, a ponteira de metal e a borracha
	var a := _paint_xf * (r.position + Vector2(half + 14, r.size.y - 6))
	var b := _paint_xf * (r.position + Vector2(r.size.x - 6, 8))
	var d := (b - a).normalized()
	var xf := _paint_xf
	_pixel_line(a + Vector2(2, 2), b + d * 7 + Vector2(2, 2), [Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3)], xf)
	_pixel_line(a, b, [Color("e6c24c"), Color("b48c1c"), Color("8a6a14")], xf)
	_pixel_line(a - d * 4, a, [Color("e8c89a"), Color("d8b88a"), Color("b8986a")], xf)   # a madeira apontada
	_pixel_line(a - d * 6, a - d * 4, [Color("2a2a2a")], xf)   # o grafite
	_pixel_line(b, b + d * 4, [Color("d6d1c3"), Color("8e897c"), Color("5a574e")], xf)   # a ponteira de metal
	_pixel_line(b + d * 4, b + d * 7, [Color("e8a8a8"), Color("d88a8a"), Color("a85a5a")], xf)   # a borracha


## A prancheta do registro: tábua de duratex com os cantos cortados, a folha datilografada com o cabeçalho e o
## prendedor niquelado com os rebites.
func _draw_clipboard(r: Rect2) -> void:
	var board := PackedVector2Array([r.position + Vector2(3, 0), Vector2(r.end.x - 3, r.position.y), Vector2(r.end.x, r.position.y + 3),
		r.end - Vector2(0, 3), r.end - Vector2(3, 0), Vector2(r.position.x + 3, r.end.y), Vector2(r.position.x, r.end.y - 3), r.position + Vector2(0, 3)])
	draw_colored_polygon(board, Color("7a5230"))
	draw_rect(Rect2(r.position.x + 3, r.position.y + 1, r.size.x - 6, 1), Color("9a6a40"))
	var paper := Rect2(r.position.x + 5, r.position.y + 7, r.size.x - 10, r.size.y - 11)
	draw_rect(Rect2(paper.position + Vector2(1, 1), paper.size), Color(0, 0, 0, 0.25))
	draw_rect(paper, Color("ece2c6"))
	draw_rect(Rect2(paper.position.x + 3, paper.position.y + 6, paper.size.x - 6, 2), Color("8e2a22"))   # o cabeçalho
	for y in range(11, int(paper.size.y) - 2, 3):   # as linhas datilografadas
		var w := paper.size.x - 8 - (y * 7) % 13
		draw_rect(Rect2(paper.position.x + 4, paper.position.y + y, w, 1), Color("4a4438"))
	if unread:   # fala nova no registro: uma folha nova, mais branca, presa por cima e meio torta, com poucas linhas
		var sheet := Rect2(paper.position + Vector2(4, -2), paper.size - Vector2(2, 6))
		draw_rect(Rect2(sheet.position + Vector2(1, 2), sheet.size), Color(0, 0, 0, 0.3))
		draw_rect(sheet, Color("f8f2e0"))
		draw_rect(Rect2(sheet.position.x + 3, sheet.position.y + 8, sheet.size.x - 6, 2), Color("8e2a22"))
		for y in range(13, 22, 3):
			draw_rect(Rect2(sheet.position.x + 4, sheet.position.y + y, sheet.size.x - 10 - (y * 5) % 9, 1), Color("4a4438"))
	# o prendedor
	var cx := r.get_center().x
	draw_rect(Rect2(cx - 11, r.position.y, 22, 7), Color("8e897c"))
	draw_rect(Rect2(cx - 11, r.position.y, 22, 2), Color("d6d1c3"))
	draw_rect(Rect2(cx - 11, r.position.y + 6, 22, 1), Color("45413a"))
	draw_rect(Rect2(cx - 5, r.position.y + 2, 10, 3), Color("45413a"))   # a fenda da mola
	for rx in [cx - 8, cx + 7]:   # rebites
		_sprite(Switchboard.disc(3, [[1.5, Color("ece7da"), Color("d6d1c3"), Color("8e897c")]]), _paint_xf * Vector2(rx, r.position.y + 4), Color.WHITE, _paint_xf)


## O jornal da manhã dobrado ao meio: papel-jornal acinzentado, o nome no alto numa faixa preta, a manchete grossa,
## as colunas de texto miúdo, uma foto e o vinco da dobra.
func _draw_newspaper(r: Rect2) -> void:
	draw_rect(r, Color("dcd5c2"))
	draw_rect(Rect2(r.position.x + 3, r.position.y + 2, r.size.x - 6, 4), Color("1d1a14"))   # o nome do jornal
	draw_rect(Rect2(r.position.x + 3, r.position.y + 7, r.size.x - 6, 1), Color("4a4438"))
	draw_rect(Rect2(r.position.x + 3, r.position.y + 10, r.size.x * 0.7, 3), Color("2a2319"))   # a manchete
	var photo := Rect2(r.end.x - r.size.x * 0.32 - 3, r.position.y + 15, r.size.x * 0.32, r.size.y * 0.4)
	draw_rect(photo, Color("8a8478"))
	draw_rect(Rect2(photo.position.x + 2, photo.end.y - 4, photo.size.x - 4, 2), Color("5a554a"))
	for y in range(16, int(r.size.y) - 2, 2):   # as colunas
		for col in 2:
			var cx := r.position.x + 3 + col * (r.size.x * 0.3)
			if Rect2(cx, r.position.y + y, r.size.x * 0.26, 1).intersects(photo):
				continue
			draw_rect(Rect2(cx, r.position.y + y, r.size.x * 0.26 - (y * 3) % 5, 1), Color("8a8478"))
	draw_rect(Rect2(r.position.x, r.get_center().y, r.size.x, 1), Color(0, 0, 0, 0.18))   # o vinco
