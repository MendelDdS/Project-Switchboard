class_name GameView
extends Control
## O jogo inteiro (`main.tscn`) desenhado numa tela própria de 960×540 e ampliado para a janela só por número
## inteiro: 2× em 1080p, 4× em 4K, cada pixel do jogo um bloco exato de pixels da tela. Onde a conta não é inteira
## (1440p, 1600×900, 720p), fica a maior ampliação inteira que cabe e o resto é borda escura (a 1,5×, um pixel do jogo
## virava ora 1, ora 2 da tela; o filtro "sharp bilinear" que igualava os blocos misturava a divisa e saiu com a base
## de 960×540). Numa janela de outra proporção (um monitor largo), a mesma coisa: o que sobra é borda.
## Em Configurações (`Settings`): tela cheia ou janela.

const BASE := Vector2i(960, 540)   ## a tela do jogo
const TITLE_BAR := 40   ## px de tela que a barra de título e as bordas da janela tomam, no modo janela
## A gradação de cor de cada clima (`grade.gdshader`, `grade_weather`): a noite limpa com mais contraste e luzes mais
## quentes, a chuva mais fria e a névoa mais lavada, com menos contraste.
const GRADES := {
	"clear": {"shadow_lift": Vector3(-0.012, 0.002, 0.035), "light_tint": Vector3(1.06, 1.0, 0.9), "contrast": 1.1, "saturation": 1.0},
	"rain": {"shadow_lift": Vector3(-0.016, 0.004, 0.045), "light_tint": Vector3(1.03, 1.0, 0.94), "contrast": 1.06, "saturation": 1.0},
	"fog": {"shadow_lift": Vector3(-0.008, 0.006, 0.03), "light_tint": Vector3(1.04, 1.0, 0.93), "contrast": 1.02, "saturation": 1.0},
}
## A do dia, para onde a do clima vai no amanhecer da última noite (`grade_day`): as sombras quase sem o azul da noite,
## mais contraste e as cores mais vivas (com o contraste de 1,04, o amanhecer saía opaco, sem a força da luz baixa).
const DAY_GRADE := {"shadow_lift": Vector3(-0.004, 0.002, 0.012), "light_tint": Vector3(1.06, 1.0, 0.92), "contrast": 1.16, "saturation": 1.25}

@onready var _box: SubViewportContainer = $Box
@onready var _view: SubViewport = $Box/View


## A gradação entra antes do `_ready` do `Main` (o dos filhos vem antes do deste), que põe a do clima da noite: posta
## no `_ready`, ela não existia ainda, a noite ficava na gradação de sempre e a troca de clima não achava o que mudar.
func _enter_tree() -> void:
	$Box.material = grade_material()


func _ready() -> void:
	# o projeto amplia a 960×540 (para o `main.tscn` sozinho e os testes); aqui, a janela fica em pixels da tela
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_viewport().size_changed.connect(_fit)
	Settings.changed.connect(_apply)
	_apply()
	if get_window().mode == Window.MODE_WINDOWED:   # o projeto abre em 960×540: na tela grande, 1× ficava minúsculo
		_size_window.call_deferred()


## A gradação de cor do jogo inteiro (`grade.gdshader`), posta na tela que mostra o jogo: o `Box` aqui e a da
## captura (`tools/shot.gd`).
static func grade_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/ui/grade.gdshader")
	return m


## Liga ou desliga a gradação na tela que mostra o jogo de `node` (o painel de debug compara na hora); com o
## `main.tscn` sozinho não há gradação, e nada muda.
static func set_grade(node: Node, on: bool) -> void:
	var m := _grade_of(node)
	if m:
		m.set_shader_parameter("strength", 1.0 if on else 0.0)


## A gradação do clima `weather` (`GRADES`) na tela que mostra o jogo de `node`, aos poucos em `sec` segundos (0: na
## hora).
static func grade_weather(node: Node, weather: String, sec := 0.0) -> void:
	var m := _grade_of(node)
	if m == null:
		return
	var t := node.create_tween().set_parallel() if sec > 0.0 else null
	for k: String in GRADES[weather]:
		if t:
			t.tween_property(m, "shader_parameter/" + k, GRADES[weather][k], sec)
		else:
			m.set_shader_parameter(k, GRADES[weather][k])


## A gradação do clima `weather` indo para a do dia (`DAY_GRADE`) até `k` (0 a 1), na hora.
static func grade_day(node: Node, weather: String, k: float) -> void:
	var m := _grade_of(node)
	if m:
		for key: String in DAY_GRADE:
			m.set_shader_parameter(key, lerp(GRADES[weather][key], DAY_GRADE[key], k))


## A gradação da tela que mostra o jogo de `node` (o `Box`, ou a da captura); nula com o `main.tscn` sozinho.
static func _grade_of(node: Node) -> ShaderMaterial:
	var box := node.get_viewport().get_parent() as CanvasItem
	return box.material as ShaderMaterial if box else null


## Aplica a tela das configurações: cheia ou janela, e a ampliação.
func _apply() -> void:
	var mode := Window.MODE_FULLSCREEN if Settings.fullscreen else Window.MODE_WINDOWED
	if get_window().mode != mode and not (mode == Window.MODE_WINDOWED and get_window().mode == Window.MODE_MAXIMIZED):
		get_window().mode = mode
		if mode == Window.MODE_WINDOWED:
			_size_window.call_deferred()   # (saindo da tela cheia, o tamanho só pega depois da troca)
	_fit()


## A janela no maior múltiplo inteiro da tela do jogo que cabe na área livre da tela (sem a barra de tarefas e com a
## barra de título): 2× em 1440p, 3× em 4K; em 1080p, 1× (o 2× é a tela inteira). No meio da tela.
func _size_window() -> void:
	var w := get_window()
	var free := DisplayServer.screen_get_usable_rect(w.current_screen)
	var k := maxi(1, mini(free.size.x / BASE.x, (free.size.y - TITLE_BAR) / BASE.y))
	w.size = BASE * k
	w.position = free.position + (free.size - w.size) / 2


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
