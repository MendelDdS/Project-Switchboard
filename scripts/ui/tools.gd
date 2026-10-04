class_name Tools
extends VBoxContainer
## Ferramentas à direita da mesa: lista telefônica, mapa e despacho (uma aba só), caderno e o registro das conversas.
## Ficam guardadas e a janela aparece no lugar delas; os objetos da mesa (`Background.prop_clicked`) ou as teclas 1 a 4
## (Main.TAB_KEYS; o número fica no canto da aba) abrem a ferramenta, que desliza sobre a janela como um papel posto
## na mesa, com as abas de papel para trocar de uma para outra (guardadas, as abas somem: os objetos já dizem o mesmo).
## A tecla da aberta ou Esc guardam.

const TABS := {"lista": "%TabLista", "despacho": "%TabDespacho", "caderno": "%TabCaderno", "registro": "%TabRegistro"}
const SLIDE_SEC := 0.16

@onready var book: PhoneBook = %PhoneBook
@onready var dispatch: Dispatch = %Dispatch
@onready var notebook: Notebook = %Notebook
@onready var call_log: CallLog = %CallLog
@onready var body: Control = %Body   ## onde a ferramenta aberta fica (e, guardada, a janela aparece)
@onready var _paper: Control = %Paper
@onready var _bar: Control = $TabBar
@onready var _views := {"lista": book, "despacho": dispatch, "caderno": notebook, "registro": call_log}

var tab := "lista"   ## a última aberta
var open := false
var _slide: Tween


func _ready() -> void:
	for id in TABS:
		var b: Button = get_node(TABS[id])
		b.pressed.connect(toggle.bind(id))
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
		_slide_to(0.0)
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
	_slide_to(body.size.x)
	_apply()


## Selo com um número na aba (0 some): quantas coisas esperam ali. Só abas que têm o selo (`Count`).
func set_count(id: String, n: int) -> void:
	var c: Label = get_node(TABS[id]).get_node("Count")
	c.text = str(n)
	c.visible = n > 0


## O papel desliza da direita (x = largura da área) até o lugar (x = 0), ou volta; guardado, some.
func _slide_to(x: float) -> void:
	if _slide:
		_slide.kill()
	_paper.visible = true
	if x == 0.0 and _paper.position.x == 0.0:
		_paper.position.x = body.size.x
	_slide = create_tween()
	_slide.tween_property(_paper, "position:x", x, SLIDE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slide.parallel().tween_property(_bar, "modulate:a", 1.0 if x == 0.0 else 0.0, SLIDE_SEC)
	if x != 0.0:
		_slide.tween_callback(func(): _paper.visible = false)


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
		_views[id].visible = id == tab
