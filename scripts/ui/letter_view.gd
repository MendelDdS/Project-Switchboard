extends RichTextLabel
## A carta aberta (`Tools.LETTER`): o texto dela (`Night.letter_for`) escrito à mão (`[hand]`, `PaperInk`), num papel
## de carta. Refeito ao trocar o idioma.

const INK := preload("res://scripts/ui/paper_ink.gd")

var _text := ""


func _ready() -> void:
	var hand := INK.new()
	hand.bbcode = "hand"
	install_effect(hand)


## Põe a carta `t` (em português; traduzida ao mostrar).
func show_letter(t: String) -> void:
	_text = t
	_write()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_write()


func _write() -> void:
	text = "[hand]%s[/hand]" % tr(_text)
