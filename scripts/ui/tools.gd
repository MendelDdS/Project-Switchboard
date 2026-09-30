class_name Tools
extends VBoxContainer
## Abas de ferramentas à direita da mesa: lista telefônica, mapa, despacho e caderno.

signal tab_changed(id: String)

const TABS := {"lista": "%TabLista", "mapa": "%TabMapa", "despacho": "%TabDespacho", "caderno": "%TabCaderno"}

@onready var book: PhoneBook = %PhoneBook
@onready var map_view: MapView = %MapView
@onready var dispatch: Dispatch = %Dispatch
@onready var notebook: Notebook = %Notebook
@onready var _views := {"lista": book, "mapa": map_view, "despacho": dispatch, "caderno": notebook}

var tab := "lista"


func _ready() -> void:
	for id in TABS:
		var b: Button = get_node(TABS[id])
		b.pressed.connect(set_tab.bind(id))
	_apply()


func set_tab(id: String) -> void:
	if id == tab:
		_apply()
		return
	tab = id
	Sfx.play("page")
	_apply()
	tab_changed.emit(id)


## Bolinha âmbar na aba: tem algo novo ali.
func set_dot(id: String, on: bool) -> void:
	(get_node(TABS[id]).get_node("Dot") as CanvasItem).visible = on


func has_dot(id: String) -> bool:
	return (get_node(TABS[id]).get_node("Dot") as CanvasItem).visible


func _apply() -> void:
	for id in TABS:
		var b: Button = get_node(TABS[id])
		b.set_pressed_no_signal(id == tab)
		b.custom_minimum_size.y = 40.0 if id == tab else 34.0   # a aba ativa fica mais alta
		_views[id].visible = id == tab
