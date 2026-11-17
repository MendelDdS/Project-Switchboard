extends Control
## O aviso "Diário atualizado" no alto, acima da mesa comutadora (`Main.notice`, que o mostra e esconde pelo
## `modulate`): a fita marca-página do diário, no pano vinho da capa dele, mais claro (no alto da sala, no escuro, o da capa mal se via), com o pesponto nas beiras e a ponta em V.

const H := 19          ## a altura (px)
const PAD := 8         ## da beira ao texto...
const PAD_END := 4     ## ...e do texto à ponta em V
const NOTCH := 6       ## a fundura do V na ponta
const MAX_W := 441.0   ## a largura da coluna da mesa comutadora: tarefa mais comprida que isso é cortada (maior, a fita empurrava a tela)
const SHADOW := Color(0, 0, 0, 0.35)

var text := "":   ## o que a fita mostra no lugar de "Diário atualizado" (""): a tarefa com hora marcada (em português, traduzida aqui) ou a dica de uma regra (já traduzida)
	set(v):
		text = v
		if is_node_ready():
			_fit()
var _text := ""


func _ready() -> void:
	_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit()


func _fit() -> void:
	_text = tr(text) if text != "" else T.text(T.Key.DIARY_UPDATED)
	custom_minimum_size = Vector2(minf(MAX_W, ceilf(Pal.ui.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x) + PAD + PAD_END + NOTCH), H)
	queue_redraw()


func _draw() -> void:
	var w := int(size.x)
	var cut := func(y: int) -> int: return NOTCH - absi(y - H / 2) * NOTCH / (H / 2)   # a ponta em V
	for y in H:   # a sombra na parede
		draw_rect(Rect2(2, y + 3, w - cut.call(y), 1), SHADOW)
	for y in H:
		draw_rect(Rect2(0, y, w - cut.call(y), 1), Pal.DIARY_RIBBON[0 if y < 2 else (2 if y >= H - 3 else 1)])
	draw_rect(Rect2(0, 0, 3, H), Pal.DIARY_RIBBON[2])   # a dobra de onde ela sai
	for x in range(5, w - NOTCH - 2, 4):   # o pesponto
		draw_rect(Rect2(x, 3, 2, 1), Pal.DIARY_RIBBON[0])
		draw_rect(Rect2(x, H - 5, 2, 1), Pal.DIARY_RIBBON[0])
	draw_string(Pal.ui, Vector2(PAD, 13), _text, HORIZONTAL_ALIGNMENT_LEFT, w - PAD - PAD_END - NOTCH, 11, Pal.DIARY_FLAP)
