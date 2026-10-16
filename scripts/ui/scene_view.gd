class_name SceneView
extends TextureRect
## O cenário (`Background`) desenhado numa tela própria (`View`) na resolução da janela, nas coordenadas da interface:
## sai em 1x1 como ela. O cenário fica fora da árvore da
## interface: o mouse chega a ele por aqui (`Background.pointer`), e o contorno e o nome do objeto sob o mouse são
## desenhados aqui, nítidos (`Background.draw_hover`).

## A luz da luminária no shader (`lamp_light.gdshader`); o painel de debug desliga, para comparar com e sem.
static var lamp_light := true

@onready var _view: SubViewport = $View
var _label := Control.new()   # a etiqueta do objeto sob o mouse, num nó filho: fora do shader da luz (no próprio, saía branca)
@onready var _bg: Background = %Background


func _ready() -> void:
	texture = _view.get_texture()
	material = ShaderMaterial.new()
	(material as ShaderMaterial).shader = preload("res://scripts/ui/lamp_light.gdshader")
	resized.connect(_fit)
	get_window().size_changed.connect(_fit)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.draw.connect(func(): _bg.draw_hover(_label))
	add_child(_label)
	_bg.draw.connect(_label.queue_redraw)   # os objetos podem ter mudado de lugar
	_fit()


func _fit() -> void:
	# a ampliação da tela onde ele está: a janela (canvas_items, o `main.tscn` sozinho) ou a do `GameView` (1:1)
	var vp := get_viewport()
	var k := Vector2((vp as Window).size if vp is Window else (vp as SubViewport).size) / get_viewport_rect().size
	_view.size = Vector2i((size * k).ceil())
	_view.size_2d_override = Vector2i(size.ceil())
	_view.render_target_update_mode = SubViewport.UPDATE_ONCE   # (o cenário só se desenha quando muda: `Background._show`)


func _process(_delta: float) -> void:
	var m := material as ShaderMaterial
	if lamp_light:
		_bg.light(m)
	else:
		m.set_shader_parameter("level", 0.0)


func _has_point(p: Vector2) -> bool:
	return _bg.prop_at(p) != ""


func _gui_input(e: InputEvent) -> void:
	if _bg.pointer(e):
		accept_event()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _bg.pointing() else Control.CURSOR_ARROW
	_label.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_bg.leave()
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		_label.queue_redraw()

