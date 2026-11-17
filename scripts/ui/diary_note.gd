extends Control
## O aviso "Diário atualizado" no alto, acima da mesa comutadora (`Main._diary_notice`, que o mostra e esconde pelo
## `modulate`): a fita marca-página do diário, no pano vinho da capa dele, com o pesponto nas beiras e a ponta em V.

const H := 19          ## a altura (px)
const PAD := 8         ## da beira ao texto
const NOTCH := 6       ## a fundura do V na ponta
const SHADOW := Color(0, 0, 0, 0.35)

var _text := ""


func _ready() -> void:
	_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit()


func _fit() -> void:
	_text = T.text(T.Key.DIARY_UPDATED)
	custom_minimum_size = Vector2(ceilf(Pal.ui.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x) + PAD * 2 + NOTCH, H)
	queue_redraw()


func _draw() -> void:
	var w := int(size.x)
	var cut := func(y: int) -> int: return NOTCH - absi(y - H / 2) * NOTCH / (H / 2)   # a ponta em V
	for y in H:   # a sombra na parede
		draw_rect(Rect2(2, y + 3, w - cut.call(y), 1), SHADOW)
	for y in H:
		draw_rect(Rect2(0, y, w - cut.call(y), 1), Pal.DIARY_COVER[0 if y < 2 else (2 if y >= H - 3 else 1)])
	draw_rect(Rect2(0, 0, 3, H), Pal.DIARY_COVER[2])   # a dobra de onde ela sai
	for x in range(5, w - NOTCH - 2, 4):   # o pesponto
		draw_rect(Rect2(x, 3, 2, 1), Pal.DIARY_COVER[0])
		draw_rect(Rect2(x, H - 5, 2, 1), Pal.DIARY_COVER[0])
	draw_string(Pal.ui, Vector2(PAD, 13), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.DIARY_FLAP)
