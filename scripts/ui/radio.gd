class_name Radio
extends Bevel
## Rádio de despacho: mostra as mensagens das viaturas uma por vez, com voz de rádio. A luz de ocorrência mostra
## a emergência em andamento; com o operador fora da linha dela, o rádio inteiro acende (`alert`).

@onready var _led: ColorRect = %Led
@onready var _screen: Label = %Screen
@onready var _alert_lamp: ColorRect = %Alert
@onready var _alert_label: Label = %AlertLabel

## Terminou de dizer `text` (o mesmo texto passado a `say`).
signal said(text: String)

const LED_OFF := Color("3a1a12")
const ALERT_OFF := Color("1a1712")
const ALERT_COLORS := [Pal.GREEN, Pal.AMBER, Pal.RED]   # estágios da barra de agravamento
const ALERT_BLINK := 1.4   # segundos piscando quando o estágio muda (no vermelho, pisca sempre)
const PULSE_HZ := [0.7, 1.2, 2.2]   # moldura: pulsa mais rápido quanto pior o estágio

var _queue: Array[String] = []
var _busy := false
var _alert := -1
var _away := ""            ## aviso na tela com o operador fora da linha da emergência ("" = na linha ou sem emergência)
var _away_shown := false
var _blink := 0.0
var _t := 0.0
var _screen_color: Color


func _ready() -> void:
	_screen_color = _screen.get_theme_color("font_color")


## Luz de ocorrência: acesa na cor do estágio da barra de agravamento enquanto uma emergência atendida não tem o
## socorro completo a caminho; -1 apaga. Com o operador fora da linha dela, `away` (já traduzido) acende o rádio
## inteiro: moldura pulsando na cor do estágio e o aviso na tela entre uma mensagem e outra. Main chama a cada quadro.
func alert(stage: int, away := "") -> void:
	if stage > _alert and _alert >= 0:
		_blink = ALERT_BLINK
	_alert = stage
	_away = away if stage >= 0 else ""


## Aviso sonoro de que a emergência mudou de estágio (`stage` 1–3): chiado curto e bipes vindos do rádio, mais
## agudos quanto pior. Avisa quem está olhando o mapa ou outra ligação.
func chirp(stage: int) -> void:
	Sfx.play_at("radio_alert", screen_x(), -2.0, [1.0, 1.0, 1.12, 1.25][stage])


## Onde o rádio fica na tela (0 = esquerda, 1 = direita): a voz, o chiado e os bipes vêm de lá.
func screen_x() -> float:
	return get_global_rect().get_center().x / get_viewport_rect().size.x


func _process(delta: float) -> void:
	_t += delta
	_blink = maxf(0.0, _blink - delta)
	var lit := _alert >= 0 and not ((_alert == 2 or _blink > 0.0) and fmod(_t, 0.5) > 0.25)
	_alert_lamp.color = ALERT_COLORS[_alert] if lit else ALERT_OFF
	_alert_label.modulate = ALERT_COLORS[_alert] if _alert >= 0 else Color.WHITE
	if not _busy:
		if _away != "":
			_screen.text = _away
			_screen.add_theme_color_override("font_color", ALERT_COLORS[_alert])
			_away_shown = true
		elif _away_shown:
			_away_shown = false
			_screen.text = "…"
			_screen.add_theme_color_override("font_color", _screen_color)
	queue_redraw()


func _draw() -> void:
	super()
	if _away == "":
		return
	# o rádio inteiro acende: moldura grossa pulsando na cor do estágio
	var a := 0.55 + 0.45 * sin(_t * TAU * PULSE_HZ[_alert])
	var col := (ALERT_COLORS[_alert] as Color)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(col, a), false, 4.0)
	draw_rect(Rect2(Vector2(7, 7), size - Vector2(14, 14)), Color(col, a * 0.35), false, 2.0)


## `text` já traduzido.
func say(text: String) -> void:
	_queue.append(text)
	if not _busy:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		_led.color = LED_OFF
		return
	_busy = true
	_away_shown = false
	_screen.add_theme_color_override("font_color", _screen_color)
	var t: String = _queue.pop_front()
	_led.color = Pal.RED
	Sfx.static_burst(0.0, screen_x())
	await get_tree().create_timer(0.45, false).timeout
	_screen.text = ""
	var rv := false
	for i in t.length():
		_screen.text += t[i]
		rv = Sfx.speak_char("r", t, i, rv, false, screen_x())
		await get_tree().create_timer(0.032 * Settings.char_delay(), false).timeout
	Sfx.static_burst(-2.0, screen_x())
	said.emit(t)
	await get_tree().create_timer(1.6, false).timeout
	_led.color = LED_OFF
	await get_tree().create_timer(0.4, false).timeout
	_next()
