class_name Tools
extends VBoxContainer
## Ferramentas à direita da mesa: lista telefônica, mapa e despacho (a unidade de despacho), caderno, o registro das
## conversas e o calculógrafo dos interurbanos (o discador abre por cima da mesa comutadora, `DialView`). Ficam guardadas e a janela aparece no lugar delas; os objetos da mesa (`Background.prop_clicked`) ou as
## teclas 1 a 4 (Main.TAB_KEYS) abrem a ferramenta: o papel sai do objeto dela na mesa (`origin`) e vem para a frente do
## operador, com a forma do objeto (`PaperDeco`), e volta para ele ao guardar. Sem abas: para trocar, o objeto da mesa
## ou a tecla (as abas repetiam os objetos e tomavam altura do papel). A tecla da aberta ou Esc guardam. O jornal da
## manhã (`news`) também abre aqui, só pelo objeto da mesa.

## O id de cada ferramenta: o mesmo nos objetos da mesa (`Background.PROPS`), nas teclas (`Main.TAB_KEYS`) e no papel
## aberto (`PaperDeco.kind`). Use as constantes, nunca o texto.
const DIRECTORY := "lista"
const DISPATCH := "despacho"
const LOGBOOK := "caderno"
const CALL_LOG := "registro"
const NEWS := "jornal"   ## o jornal da manhã: só pelo objeto da mesa, sem tecla
const TOLL := "calculografo"   ## o calculógrafo dos interurbanos e os bilhetes de tarifação: só pelo objeto da mesa, sem tecla
const SLIDE_SEC := 0.2
## A cor do papel de cada ferramenta, a mesma do objeto dela na mesa (as outras, `Pal.PAPER`); a unidade de despacho é
## de metal (a moldura do vidro e a base das máquinas) e o calculógrafo fica no tampo da mesa.
const PAPER := {LOGBOOK: Pal.NOTE_PAGE, CALL_LOG: Pal.SHEET, NEWS: Pal.NEWSPRINT, DISPATCH: Pal.PANEL, TOLL: Pal.DESK}

@onready var book: PhoneBook = %PhoneBook
@onready var dispatch: Dispatch = %Dispatch
@onready var notebook: Notebook = %Notebook
@onready var call_log: CallLog = %CallLog
@onready var news: NewsView = %News
@onready var toll: Toll = %Toll
@onready var body: Control = %Body   ## onde a ferramenta aberta fica (e, guardada, a janela aparece)
@onready var _paper: Control = %Paper
@onready var _deco: PaperDeco = %Deco
@onready var _views := {DIRECTORY: book, DISPATCH: dispatch, LOGBOOK: notebook, CALL_LOG: call_log, NEWS: news, TOLL: toll}

var tab := DIRECTORY   ## a última aberta
var open := false
var origin: Callable   ## id -> Rect2 global do objeto da mesa daquela ferramenta (o Main liga; vazio: desliza da direita)
var light := 1.0:   ## a luz da luminária (o Main atualiza): cai também no papel aberto (`PaperDeco.light`)
	set(v):
		light = v
		if is_node_ready():
			_deco.light = v
var _slide: Tween
var _paper_box: StyleBoxFlat   # o fundo do papel, na cor da ferramenta (`PAPER`)


func _ready() -> void:
	_paper_box = _paper.get_theme_stylebox("panel").duplicate()
	_paper.add_theme_stylebox_override("panel", _paper_box)
	_apply()


## Abre a ferramenta `id` (já aberta, continua).
func set_tab(id: String) -> void:
	if id == tab and open:
		_apply()
		return
	Sfx.play("unroll" if id == DISPATCH else "page")   # o mapa é uma folha grande desenrolada
	tab = id
	if not open:
		open = true
		_apply()
		_move(true)
		return
	_apply()


## Tecla: abre a ferramenta, ou guarda se ela já está aberta.
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


## Quantos registros esperam no caderno: as tiras saindo do caderno aberto, como no da mesa.
func set_pending(n: int) -> void:
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
	if not opening:
		_slide.chain().tween_callback(func():
			_paper.visible = false
			_paper.scale = Vector2.ONE
			_paper.position = Vector2.ZERO)


func _apply() -> void:
	for id in _views:
		_views[id].visible = id == tab
	_deco.kind = tab
	_paper_box.bg_color = PAPER.get(tab, Pal.PAPER)
