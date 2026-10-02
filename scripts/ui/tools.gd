class_name Tools
extends VBoxContainer
## Abas de ferramentas à direita da mesa: lista telefônica, mapa e despacho (uma aba só), e caderno.

const TABS := {"lista": "%TabLista", "despacho": "%TabDespacho", "caderno": "%TabCaderno"}

@onready var book: PhoneBook = %PhoneBook
@onready var dispatch: Dispatch = %Dispatch
@onready var notebook: Notebook = %Notebook
@onready var _views := {"lista": book, "despacho": dispatch, "caderno": notebook}

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
	Sfx.play("unroll" if id == "despacho" else "page")   # o mapa é uma folha grande desenrolada
	_apply()


## Selo com um número na aba (0 some): quantas coisas esperam ali. Só abas que têm o selo (`Count`).
func set_count(id: String, n: int) -> void:
	var c: Label = get_node(TABS[id]).get_node("Count")
	c.text = str(n)
	c.visible = n > 0


func _apply() -> void:
	for id in TABS:
		var b: Button = get_node(TABS[id])
		b.set_pressed_no_signal(id == tab)
		b.custom_minimum_size.y = 40.0 if id == tab else 34.0   # a aba ativa fica mais alta
		_views[id].visible = id == tab
