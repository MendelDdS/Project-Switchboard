extends Button
## O campo "Ciente" de um papel (o bilhete do supervisor na abertura, o relatório no fim): a linha com o "×" a lápis e,
## embaixo, o que fazer ("Assine para começar o turno"). Sob o mouse a linha escurece e o nome aparece de leve; o
## clique (ou `sign()`, pelo Enter) faz Maria assinar com a letra de mão, letra a letra, e só então `signed`.
## Esperando, chama a atenção: um lápis pequeno bate no começo da linha (`TAP_SEC`) e o "×" e o texto clareiam e
## escurecem (`PULSE_SEC`); assinando, o lápis corre com o nome e some.

signal signed

const WRITE_SEC := 0.45   ## o nome escrito
const HOLD_SEC := 0.3     ## o nome assinado parado antes do `signed` (para ser visto)
const NAME := "Maria"     ## (nome próprio: não se traduz)
const MIN_W := 150.0      ## a linha, no mínimo (a da rubrica do supervisor); cresce com o texto de baixo
const TAP_SEC := 0.9      ## o lápis batendo no papel: encostado no fim de cada volta (`TAP_DOWN` dela), erguido no resto
const TAP_DOWN := 0.25
const TAP_UP := 2         ## o quanto ele se ergue, em px
const PULSE_SEC := 1.6    ## o "×" e o texto, no ritmo do papel esquecido na mesa (`Background.NAG_PULSE_SEC`)
const PEN := 9            ## o lápis em diagonal, da ponta (embaixo à esquerda) à borracha: `PEN` + 1 px de lado

@export var hint := ""   ## a chave do que fazer, embaixo da linha antes de assinar (`T.Key`)

var done := false


func _ready() -> void:
	%Name.text = NAME
	for n: Control in [%Mark, %Name]:   # o lápis de Maria (o do diário), não a caneta azul do supervisor
		n.add_theme_color_override("default_color", Pal.PENCIL_LEAD)
	%Name.visible_ratio = 0.0
	%Pen.texture = _pen_art()
	pressed.connect(sign)
	mouse_entered.connect(_look)
	mouse_exited.connect(_look)
	_look()


## Volta ao campo em branco (a abertura de outra noite).
func clear() -> void:
	set_process(true)
	%Pen.visible = true
	done = false
	disabled = false
	%Name.visible_ratio = 0.0
	_look()


## Já assinado, sem animação nem `signed` (o bilhete relido no turno).
func fill() -> void:
	done = true
	disabled = true
	%Name.modulate.a = 1.0
	%Name.visible_ratio = 1.0
	%Pen.visible = false
	set_process(false)
	_look()


## Assina: o nome escrito com o som do lápis e, parado um instante, `signed`.
func sign() -> void:
	if done:
		return
	done = true
	disabled = true
	Sfx.play("pencil")
	%Name.modulate.a = 1.0
	%Name.visible_ratio = 0.0   # (sob o mouse, o nome de leve estava inteiro)
	var tw := create_tween()
	tw.tween_property(%Name, "visible_ratio", 1.0, WRITE_SEC).from(0.0)
	tw.tween_callback(func(): %Pen.visible = false)
	tw.tween_interval(HOLD_SEC)
	tw.tween_callback(func(): set_process(false); signed.emit())
	_look()


## A linha, o "×" e o nome de leve sob o mouse; assinado, embaixo, quem assinou.
func _look() -> void:
	var over := is_hovered() and not done
	%Line.color = Color(Pal.INK, 0.9 if over or done else 0.5)
	%Mark.modulate.a = 0.0 if done else 1.0
	%Who.modulate.a = 1.0
	if not done:
		%Name.visible_ratio = 1.0 if over else 0.0
		%Name.modulate.a = 0.3
	%Who.text = T.text(T.Key.SIGN_OPERATOR) if done else (T.text(T.Key[hint]) if hint != "" else "")
	custom_minimum_size.x = maxf(MIN_W, %Who.get_minimum_size().x)


## O lápis (a ponta no começo do nome, rente à linha) e o pulsar do "×" e do texto; só mexe no lugar e no
## `modulate`, sem redesenhar.
func _process(_d: float) -> void:
	var t := PixelArt.ms() / 1000.0
	var tip: Vector2 = Vector2(%Name.position.x + $VBox/Row.position.x, %Line.position.y) + $VBox.position
	if done:   # assinando: corre com a letra
		tip.x += roundf(%Name.size.x * %Name.visible_ratio)
	elif not is_hovered() and fposmod(t, TAP_SEC) < TAP_SEC * (1.0 - TAP_DOWN):
		tip.y -= TAP_UP
	%Pen.position = tip - Vector2(0, PEN + 1)
	if done:
		return
	var a := 1.0 if is_hovered() else snappedf(0.7 + 0.3 * cos(TAU * t / PULSE_SEC), 0.05)
	%Mark.modulate.a = a
	%Who.modulate.a = a


## O lápis pequeno em diagonal (as cores do da mesa, `Pal.PENCIL_*`): a faixa de 3 px em volta da diagonal, o grafite
## na ponta, a madeira apontada, o corpo com o lado de cima claro e a borracha no fim.
static func _pen_art() -> ImageTexture:
	var rows: Array = []
	for y in PEN + 1:
		var row := ""
		for x in PEN + 1:
			var d := x + y - PEN   # do outro lado da diagonal: -1 em cima, 1 embaixo
			var u := x - y + PEN   # ao longo dela, da ponta (0) à borracha (2 × PEN)
			if absi(d) > 1 or (u < 3 and absi(d) == 1):
				row += "."
			elif u == 0:
				row += "L"
			elif u < 4:
				row += "w" if d < 1 else "W"
			elif u > 2 * PEN - 3:
				row += "e" if d < 1 else "E"
			else:
				row += ["a", "b", "c"][d + 1]
		rows.append(row)
	return PixelArt.art(rows, {"L": Pal.PENCIL_LEAD, "w": Pal.PENCIL_WOOD[0], "W": Pal.PENCIL_WOOD[2],
		"a": Pal.PENCIL_BODY[0], "b": Pal.PENCIL_BODY[1], "c": Pal.PENCIL_BODY[2], "e": Pal.PENCIL_ERASER[0], "E": Pal.PENCIL_ERASER[2]})


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_look()
