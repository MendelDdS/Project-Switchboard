class_name Tools
extends VBoxContainer
## Ferramentas à direita da mesa: lista telefônica, mapa e despacho (uma aba só), caderno e o registro das conversas.
## Ficam guardadas e a janela aparece no lugar delas; os objetos da mesa (`Background.prop_clicked`) ou as teclas 1 a 4
## (Main.TAB_KEYS; o número fica no canto da aba) abrem a ferramenta: o papel sai do objeto dela na mesa (`origin`) e
## vem para a frente do operador, com a forma do objeto (`PaperDeco`), e volta para ele ao guardar; com uma aberta, as
## abas de papel trocam de uma para outra (guardadas, as abas somem: os objetos já dizem o mesmo).
## A tecla da aberta ou Esc guardam. O jornal da manhã (`news`) também abre aqui, só pelo objeto da mesa: não tem aba.

const TABS := {"lista": "%TabLista", "despacho": "%TabDespacho", "caderno": "%TabCaderno", "registro": "%TabRegistro"}
const SLIDE_SEC := 0.2
## A cor do papel de cada ferramenta, a mesma do objeto dela na mesa (as outras, `Pal.PAPER`); a aba aberta acompanha.
const PAPER := {"caderno": Pal.NOTE_PAGE, "registro": Pal.SHEET, "jornal": Pal.NEWSPRINT}

@onready var book: PhoneBook = %PhoneBook
@onready var dispatch: Dispatch = %Dispatch
@onready var notebook: Notebook = %Notebook
@onready var call_log: CallLog = %CallLog
@onready var news: NewsView = %News
@onready var body: Control = %Body   ## onde a ferramenta aberta fica (e, guardada, a janela aparece)
@onready var _paper: Control = %Paper
@onready var _bar: Control = $TabBar
@onready var _deco: PaperDeco = %Deco
@onready var _views := {"lista": book, "despacho": dispatch, "caderno": notebook, "registro": call_log, "jornal": news}

var tab := "lista"   ## a última aberta
var open := false
var origin: Callable   ## id -> Rect2 global do objeto da mesa daquela ferramenta (o Main liga; vazio: desliza da direita)
var light := 1.0:   ## a luz da luminária (o Main atualiza): cai também no papel aberto (`PaperDeco.light`)
	set(v):
		light = v
		if is_node_ready():
			_deco.light = v
var _slide: Tween
var _paper_box: StyleBoxFlat   # o fundo do papel e o da aba aberta, na cor da ferramenta (`PAPER`)
var _tab_box: StyleBoxFlat


func _ready() -> void:
	_paper_box = _paper.get_theme_stylebox("panel").duplicate()
	_paper.add_theme_stylebox_override("panel", _paper_box)
	_tab_box = (get_node(TABS["lista"]) as Button).get_theme_stylebox("pressed").duplicate()
	for id in TABS:
		var b: Button = get_node(TABS[id])
		b.pressed.connect(toggle.bind(id))
		b.add_theme_stylebox_override("pressed", _tab_box)
		b.add_theme_stylebox_override("hover_pressed", _tab_box)
	_apply()


## Abre a ferramenta `id` (já aberta, continua).
func set_tab(id: String) -> void:
	if id == tab and open:
		_apply()
		return
	Sfx.play("unroll" if id == "despacho" else "page")   # o mapa é uma folha grande desenrolada
	tab = id
	if not open:
		open = true
		_apply()
		_move(true)
		return
	_apply()


## Aba ou tecla: abre a ferramenta, ou guarda se ela já está aberta.
func toggle(id: String) -> void:
	if open and id == tab:
		close()
	else:
		set_tab(id)


func close() -> void:
	if not open:
		return
	open = false
	Sfx.play("page")
	_move(false)
	_apply()


## Selo com um número na aba (0 some): quantas coisas esperam ali. Só abas que têm o selo (`Count`).
func set_count(id: String, n: int) -> void:
	var c: Label = get_node(TABS[id]).get_node("Count")
	c.text = str(n)
	c.visible = n > 0
	if id == "caderno":   # as tiras saindo do caderno aberto, como no da mesa
		_deco.pending = n


## O papel sai do objeto da ferramenta na mesa (pequeno, em cima dele) e vem para o lugar, ou volta para ele e some.
## Sem objeto (`origin` vazio ou sem lugar), desliza da direita.
func _move(opening: bool) -> void:
	if _slide:
		_slide.kill()
	var from: Rect2 = origin.call(tab) if origin.is_valid() else Rect2()
	var away_pos := Vector2(body.size.x, 0)
	var away_scale := Vector2.ONE
	if from.has_area():
		var s := clampf(from.size.x / maxf(1.0, body.size.x), 0.05, 1.0)
		away_scale = Vector2(s, s)
		away_pos = from.get_center() - body.global_position - body.size * s / 2.0
	_paper.visible = true
	if opening:
		_paper.position = away_pos
		_paper.scale = away_scale
		_paper.modulate.a = 0.4
	_slide = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if opening else Tween.EASE_IN)
	_slide.tween_property(_paper, "position", Vector2.ZERO if opening else away_pos, SLIDE_SEC)
	_slide.tween_property(_paper, "scale", Vector2.ONE if opening else away_scale, SLIDE_SEC)
	_slide.tween_property(_paper, "modulate:a", 1.0 if opening else 0.4, SLIDE_SEC)
	_slide.tween_property(_bar, "modulate:a", 1.0 if opening else 0.0, SLIDE_SEC)
	if not opening:
		_slide.chain().tween_callback(func():
			_paper.visible = false
			_paper.scale = Vector2.ONE
			_paper.position = Vector2.ZERO)


func _apply() -> void:
	if not _slide:   # no começo, guardadas e sem animação
		_bar.modulate.a = 1.0 if open else 0.0
	for id in TABS:
		var b: Button = get_node(TABS[id])
		var on: bool = open and id == tab
		b.set_pressed_no_signal(on)
		b.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE   # guardadas, nem existem
		b.custom_minimum_size.y = 40.0 if on else 34.0   # a aba aberta fica mais alta
		# a tecla do atalho no canto: tinta no papel da aba aberta, apagada nas outras
		(b.get_node("Key") as Label).add_theme_color_override("font_color", Pal.INK_SOFT if on else Pal.DIM)
	for id in _views:
		_views[id].visible = id == tab
	_deco.kind = tab
	_paper_box.bg_color = PAPER.get(tab, Pal.PAPER)
	_tab_box.bg_color = _paper_box.bg_color
