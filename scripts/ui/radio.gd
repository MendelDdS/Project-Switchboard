class_name Radio
extends Bevel
## Rádio de despacho: mostra as mensagens das viaturas uma por vez, com voz de rádio.

@onready var _led: ColorRect = %Led
@onready var _screen: Label = %Screen

const LED_OFF := Color("3a1a12")

var _queue: Array[String] = []
var _busy := false


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
	var t: String = _queue.pop_front()
	_led.color = Pal.RED
	Sfx.static_burst()
	await get_tree().create_timer(0.45, false).timeout
	_screen.text = ""
	var rv := false
	for i in t.length():
		_screen.text += t[i]
		rv = Sfx.speak_char("r", t, i, rv)
		await get_tree().create_timer(0.032 * Settings.char_delay(), false).timeout
	Sfx.static_burst(-2.0)
	await get_tree().create_timer(1.6, false).timeout
	_led.color = LED_OFF
	await get_tree().create_timer(0.4, false).timeout
	_next()
