class_name GameView
extends Control
## O jogo inteiro (`main.tscn`) desenhado numa tela própria de 960×540 e ampliado para a janela só por número
## inteiro: 2× em 1080p, 4× em 4K, cada pixel do jogo um bloco exato de pixels da tela. Onde a conta não é inteira
## (1440p, 1600×900, 720p), fica a maior ampliação inteira que cabe e o resto é borda escura (a 1,5×, um pixel do jogo
## virava ora 1, ora 2 da tela; o filtro "sharp bilinear" que igualava os blocos misturava a divisa e saiu com a base
## de 960×540). Numa janela de outra proporção (um monitor largo), a mesma coisa: o que sobra é borda.
## Em Configurações (`Settings`): tela cheia ou janela.

const BASE := Vector2i(960, 540)   ## a tela do jogo

@onready var _box: SubViewportContainer = $Box
@onready var _view: SubViewport = $Box/View


func _ready() -> void:
	# o projeto amplia a 960×540 (para o `main.tscn` sozinho e os testes); aqui, a janela fica em pixels da tela
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_viewport().size_changed.connect(_fit)
	Settings.changed.connect(_apply)
	_apply()


## Aplica a tela das configurações: cheia ou janela, e a ampliação.
func _apply() -> void:
	var mode := Window.MODE_FULLSCREEN if Settings.fullscreen else Window.MODE_WINDOWED
	if get_window().mode != mode and not (mode == Window.MODE_WINDOWED and get_window().mode == Window.MODE_MAXIMIZED):
		get_window().mode = mode
	_fit()


func _fit() -> void:
	var win := get_viewport_rect().size
	var k := minf(win.x / BASE.x, win.y / BASE.y)
	if k >= 1.0:
		k = floorf(k)
	_view.size = BASE
	_box.size = Vector2(_view.size)
	_box.scale = Vector2(k, k)
	_box.position = ((win - _box.size * k) / 2.0).floor()
	Cursors.zoom(k)
