class_name SceneView
extends TextureRect
## O cenário (`Background`) desenhado numa tela própria (`View`) com metade da resolução da interface, nas mesmas
## coordenadas dela, e ampliado com "nearest": os pixels dele são blocos de 2x2 da tela base, que viram quadrados
## inteiros nas telas comuns (640×360 cabe 2× em 720p, 3× em 1080p, 4× em 1440p, 6× em 4K), sem borrar. A interface,
## por cima, continua desenhada na resolução da tela (o texto fica legível). O cenário fica fora da árvore da
## interface: o mouse chega a ele por aqui (`Background.pointer`), e o contorno e o nome do objeto sob o mouse são
## desenhados aqui, nítidos (`Background.draw_hover`).

@onready var _view: SubViewport = $View
@onready var _bg: Background = %Background


func _ready() -> void:
	texture = _view.get_texture()
	resized.connect(_fit)
	_bg.draw.connect(queue_redraw)   # os objetos podem ter mudado de lugar
	_fit()


func _fit() -> void:
	_view.size = Vector2i((size / 2.0).ceil())
	_view.size_2d_override = _view.size * 2


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
