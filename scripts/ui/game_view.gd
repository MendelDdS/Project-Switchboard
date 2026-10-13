class_name GameView
extends Control
## O jogo inteiro (`main.tscn`) desenhado numa tela própria de 1280×720 e ampliado para a janela. Ampliação inteira
## (1× em 720p, 2× em 1440p, 3× em 4K) sai com pixels perfeitos; quebrada (1,5× em 1080p) não dá: um pixel do jogo
## viraria ora 1, ora 2 pixels da tela, e linhas, letras e círculos ficavam desiguais. Por isso a tela do jogo passa
## por um filtro de pixel art ("sharp bilinear", `SHARP`): cada pixel do jogo vira um bloco do mesmo tamanho, e só a
## divisa entre dois blocos, um pixel da tela, mistura as duas cores. Nas ampliações inteiras ele não muda nada.
## Numa janela de outra proporção (um monitor largo), o jogo fica sempre em 1280×720, ampliado para a tela, e o
## que sobra é borda escura (antes ganhava largura até 21:9 e a sala se esticava, com mesa vazia entre os objetos).
## Em Configurações (`Settings`): tela cheia ou janela, e "pixels perfeitos", que só amplia por número inteiro (sem o
## filtro; numa tela de 1080p, o jogo fica em 1× com borda em volta).

const BASE := Vector2i(1280, 720)   ## a tela do jogo
const SHARP := """
shader_type canvas_item;
uniform float scale = 1.0;   // pixels da tela por pixel do jogo
void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = UV * size;
	vec2 d = fract(texel) - 0.5;
	float keep = 0.5 - 0.5 / max(scale, 1.0);   // o miolo do pixel, que não mistura com o vizinho
	vec2 f = (d - clamp(d, -keep, keep)) * scale + 0.5;
	COLOR = texture(TEXTURE, (floor(texel) + f) / size);
}
"""

@onready var _box: SubViewportContainer = $Box
@onready var _view: SubViewport = $Box/View


func _ready() -> void:
	# o projeto amplia a 1280×720 (para o `main.tscn` sozinho e os testes); aqui, a janela fica em pixels da tela
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var shader := Shader.new()
	shader.code = SHARP
	_box.material = ShaderMaterial.new()
	(_box.material as ShaderMaterial).shader = shader
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
	if Settings.pixel_perfect and k >= 1.0:
		k = floorf(k)
	_view.size = BASE
	_box.size = Vector2(_view.size)
	_box.scale = Vector2(k, k)
	_box.position = ((win - _box.size * k) / 2.0).floor()
	(_box.material as ShaderMaterial).set_shader_parameter("scale", k)
	Cursors.zoom(k)
