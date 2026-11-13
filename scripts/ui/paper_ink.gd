@tool
extends RichTextEffect
## A tinta das letras num papel, para `[typed]` e `[hand]` no texto de um RichTextLabel que instalou o efeito (um com
## cada `bbcode`). Datilografado: cada letra com a fita um pouco mais fraca ou mais forte e, de vez em quando, uma que
## bateu um pixel mais baixo. À mão: a caneta apertando mais ou menos (a letra é a de mão, `HandFont`, posta no tema
## `HandText`). Cada letra sempre do mesmo jeito (o sorteio é pela posição dela no texto).

var bbcode := "typed"


func _process_custom_fx(c: CharFXTransform) -> bool:
	var h := fposmod(sin(c.range.x * 12.9898 + 4.1) * 43758.5453, 1.0)
	if bbcode == "hand":
		c.color.a *= 0.78 + 0.22 * h
	else:
		c.color.a *= 0.7 + 0.3 * h
		if h > 0.95:
			c.offset.y += 1.0
	return true
