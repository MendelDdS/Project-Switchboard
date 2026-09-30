class_name MapView
extends VBoxContainer
## Aba do mapa: a cidade clicável e o trecho marcado para o despacho.

signal location_selected(street: String, block: int, label: String)
signal use_pressed

@onready var city: CityMap = %City
@onready var _selected: Label = %Selected


func _ready() -> void:
	city.segment_selected.connect(_on_segment)
	%Use.pressed.connect(use_pressed.emit)


func _on_segment(street: String, block: int, label: String) -> void:
	_selected.text = label
	location_selected.emit(street, block, label)
