class_name SceneView
extends TextureRect
## O cenário (`Background`) desenhado numa tela própria (`View`) na resolução da janela, nas coordenadas da interface:
## sai em 1x1 como ela. O cenário fica fora da árvore da
## interface: o mouse chega a ele por aqui (`Background.pointer`), e o contorno e o nome do objeto sob o mouse são
## desenhados aqui, nítidos (`Background.draw_hover`).

@onready var _view: SubViewport = $View
@onready var _bg: Background = %Background


func _ready() -> void:
	texture = _view.get_texture()
	resized.connect(_fit)
	get_window().size_changed.connect(_fit)
	_bg.draw.connect(queue_redraw)   # os objetos podem ter mudado de lugar
	_fit()


func _fit() -> void:
	var k := Vector2(get_window().size) / get_viewport_rect().size   # a ampliação da tela (canvas_items)
	_view.size = Vector2i((size * k).ceil())
	_view.size_2d_override = Vector2i(size.ceil())


func _has_point(p: Vector2) -> bool:
	return _bg.prop_at(p) != ""


func _gui_input(e: InputEvent) -> void:
	if _bg.pointer(e):
		accept_event()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _bg.hot() != "" else Control.CURSOR_ARROW
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_bg.leave()
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		queue_redraw()


func _draw() -> void:
	_bg.draw_hover(self)
