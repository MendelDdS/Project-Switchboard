extends Node
## Cursores do jogo (autoload `Cursors`): pixel art desenhada aqui, no lugar dos cursores do sistema, uma por forma
## (`Control.CURSOR_*`). Botões e controles deslizantes ganham sozinhos a mão com o dedo (`node_added`); a mesa troca
## a forma conforme o que está sob o mouse (mão aberta para pegar um plug, fechada segurando, proibido numa tomada
## que não aceita o plug).

## Na tela, cada pixel do desenho tem o tamanho de um pixel do jogo: o `GameView` passa a ampliação dele (`zoom`).
## Sozinho (o `main.tscn`, os testes), 2.
var scale := 2.0
const COLORS := {"k": Color("0e0c08"), "w": Color("e8dcbe"), "s": Color("b2a078"), "r": Color("d4553f")}

const ARROW := [
	"k...............",
	"kk..............",
	"kwk.............",
	"kwwk............",
	"kwwwk...........",
	"kwwwwk..........",
	"kwwwwwk.........",
	"kwwwwwwk........",
	"kwwwwwwwk.......",
	"kwwwwwwwwk......",
	"kwwwwwkkkkk.....",
	"kwwkwwk.........",
	"kwk.kwwk........",
	"kk...kwwk.......",
	"k....kwwk.......",
	"......kk........",
]
const POINT := [
	"....kk..........",
	"...kwwk.........",
	"...kwwk.........",
	"...kwwk.........",
	"...kwwkkk.......",
	"...kwwkwwkkk....",
	"...kwwkwwkwwkk..",
	".kkkwwkwwkwwkwk.",
	"kwwkwwwwwwwwkwk.",
	"kwwkwwwwwwwwwwk.",
	".kwwwwwwwwwwwwk.",
	".kwwwwwwwwwwwsk.",
	"..kwwwwwwwwwssk.",
	"...kwwwwwwwssk..",
	"....kwwwwwwsk...",
	"....kkkkkkkkk...",
]
const OPEN_HAND := [
	"......kk........",
	"...kk.kwk.kk....",
	"..kwwkkwkkwwk...",
	"..kwwkkwkkwwk.kk",
	"..kwwkkwkkwwkkwk",
	"..kwwkkwkkwwkkwk",
	"..kwwkkwkkwwkkwk",
	"kk.kwwwwwwwwwwwk",
	"kwkkwwwwwwwwwwwk",
	"kwwkwwwwwwwwwwk.",
	".kwwwwwwwwwwwsk.",
	".kwwwwwwwwwwssk.",
	"..kwwwwwwwwssk..",
	"...kwwwwwwssk...",
	"....kwwwwwsk....",
	"....kkkkkkkk....",
]
const FIST := [
	"................",
	"................",
	"................",
	"................",
	"....kk.kk.kk....",
	"...kwwkwwkwwkk..",
	"..kkwwkwwkwwkwk.",
	".kwkwwkwwkwwkwk.",
	".kwwwwwwwwwwwwk.",
	".kwwwwwwwwwwwwk.",
	".kwwwwwwwwwwwsk.",
	"..kwwwwwwwwwssk.",
	"...kwwwwwwwssk..",
	"....kwwwwwssk...",
	"....kwwwwwsk....",
	"....kkkkkkkk....",
]
const FORBIDDEN := [
	"................",
	".....kkkkkk.....",
	"...kkrrrrrrkk...",
	"..krrrkkkkrrrk..",
	"..krrk....krrrk.",
	".krrk....krrrrk.",
	".krk....krrrkrk.",
	".krk...krrrk.krk",
	".krk..krrrk..krk",
	".krk.krrrk...krk",
	".krkkrrrk...krk.",
	".krrrrrk...krrk.",
	"..krrrk...krrk..",
	"..krrrkkkkrrrk..",
	"...kkrrrrrrkk...",
	".....kkkkkk.....",
]
const BEAM := [
	"....kkk.kkk.....",
	"....kwwkwwk.....",
	".....kkwkk......",
	"......kwk.......",
	"......kwk.......",
	"......kwk.......",
	"......kwk.......",
	"......kwk.......",
	"......kwk.......",
	"......kwk.......",
	"......kwk.......",
	"......kwk.......",
	".....kkwkk......",
	"....kwwkwwk.....",
	"....kkk.kkk.....",
	"................",
]
## forma -> [desenho, ponto que clica, em pixels do desenho]
const SHAPES := {
	Control.CURSOR_ARROW: [ARROW, Vector2(0, 0)],
	Control.CURSOR_POINTING_HAND: [POINT, Vector2(4, 0)],
	Control.CURSOR_MOVE: [OPEN_HAND, Vector2(8, 8)],     # pode pegar
	Control.CURSOR_DRAG: [FIST, Vector2(8, 9)],          # segurando
	Control.CURSOR_FORBIDDEN: [FORBIDDEN, Vector2(8, 8)],
	Control.CURSOR_IBEAM: [BEAM, Vector2(7, 7)],
}


## Em `_enter_tree`, não `_ready`: as cenas entram na árvore (e emitem `node_added`) antes de qualquer `_ready`.
func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _ready() -> void:
	_apply()


## Monta os cursores na ampliação `k` do jogo (pixels da janela por pixel do jogo). Sempre em 2×, eles ficavam
## grossos demais em 1080p (o jogo em 1,5×) e finos em 4K (em 3×).
func zoom(k: float) -> void:
	k = maxf(1.0, k / DisplayServer.screen_get_scale())   # no Retina do Mac o sistema dobra o cursor
	if not is_equal_approx(k, scale):
		scale = k
		_apply()


func _apply() -> void:
	for shape in SHAPES:
		Input.set_custom_mouse_cursor(_image(SHAPES[shape][0]), shape, (SHAPES[shape][1] * scale).floor())


## Tudo que se clica para escolher (botões, listas, controles deslizantes) mostra a mão com o dedo.
func _on_node_added(n: Node) -> void:
	if n is BaseButton or n is Slider:
		_point.call_deferred(n)


## Depois do quadro: trocar o cursor faz o Viewport olhar o que está sob o mouse, e no meio de uma cena entrando na
## árvore isso esbarra em nós que ainda não entraram (erro `!is_inside_tree()` no log).
func _point(c: Control) -> void:
	if is_instance_valid(c) and c.mouse_default_cursor_shape == Control.CURSOR_ARROW:
		c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Uma Image (e não textura): o Input a guarda até o fim, e textura sobrevivendo ao servidor de renderização vaza.
## Ampliada como o `GameView` amplia o jogo (o filtro `SHARP`): cada pixel vira um bloco, e só a divisa entre dois
## blocos, um pixel da tela, mistura as duas cores (em ampliação inteira, blocos exatos).
func _image(rows: Array) -> Image:
	var src := []   # as cores com o alfa multiplicado (misturar com o vazio não escurece a beira)
	for y in 16:
		for x in 16:
			var c: Color = COLORS.get(rows[y][x], Color(0, 0, 0, 0))
			src.append(Color(c.r * c.a, c.g * c.a, c.b * c.a, c.a))
	var at := func(x: int, y: int) -> Color:
		return src[clampi(y, 0, 15) * 16 + clampi(x, 0, 15)]
	var n := ceili(16 * scale)
	var keep := 0.5 - 0.5 / scale
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var t := Vector2(x + 0.5, y + 0.5) / scale
			var d := t - t.floor() - Vector2(0.5, 0.5)
			var f := (d - d.clamp(Vector2(-keep, -keep), Vector2(keep, keep))) * scale + t.floor()   # o meio de um pixel do desenho fica em +0,5: aqui, em índices
			var i := Vector2i(f.floor())
			var w := f - f.floor()
			var c: Color = (at.call(i.x, i.y) as Color).lerp(at.call(i.x + 1, i.y), w.x).lerp(
				(at.call(i.x, i.y + 1) as Color).lerp(at.call(i.x + 1, i.y + 1), w.x), w.y)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(c.r / c.a, c.g / c.a, c.b / c.a, c.a))
	return img
