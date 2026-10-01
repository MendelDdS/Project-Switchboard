extends Node
## Cursores do jogo (autoload `Cursors`): pixel art desenhada aqui, no lugar dos cursores do sistema, uma por forma
## (`Control.CURSOR_*`). Botões e controles deslizantes ganham sozinhos a mão com o dedo (`node_added`); a mesa troca
## a forma conforme o que está sob o mouse (mão aberta para pegar um plug, fechada segurando, proibido numa tomada
## que não aceita o plug).

const SCALE := 2   # cada pixel do desenho vira SCALE×SCALE na tela
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
	for shape in SHAPES:
		Input.set_custom_mouse_cursor(_image(SHAPES[shape][0]), shape, SHAPES[shape][1] * SCALE)


## Tudo que se clica para escolher (botões, listas, controles deslizantes) mostra a mão com o dedo.
func _on_node_added(n: Node) -> void:
	if (n is BaseButton or n is Slider) and n.mouse_default_cursor_shape == Control.CURSOR_ARROW:
		n.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Uma Image (e não textura): o Input a guarda até o fim, e textura sobrevivendo ao servidor de renderização vaza.
func _image(rows: Array) -> Image:
	var img := Image.create(16 * SCALE, 16 * SCALE, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			var ch: String = rows[y][x]
			if COLORS.has(ch):
				img.fill_rect(Rect2i(x * SCALE, y * SCALE, SCALE, SCALE), COLORS[ch])
	return img
