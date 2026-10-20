class_name ScreenGlass
extends Control
## O vidro de uma tela embutida no console: um reflexo na diagonal sempre e, desligada (`off`, sem ligação no
## painel), o vidro escuro. Com `idle`, a tela desligada continua ligada esperando, como um terminal antigo: o aviso
## bem apagado e o cursor piscando (a da conversa; sem ele parecia só um retângulo escuro).

const IDLE_INK := Color(0.72, 0.79, 0.66, 0.3)
const BLINK := 0.53   # s: o cursor aceso, depois apagado

var off := true:
	set(v):
		off = v
		set_process(off and idle != -1)
		queue_redraw()
var idle := -1   ## o aviso de espera (`T.Key`; -1 = sem aviso)
var _blink_on := true


func _ready() -> void:
	set_process(off and idle != -1)


func _process(_delta: float) -> void:
	var lit := fmod(PixelArt.ms() / 1000.0, BLINK * 2.0) < BLINK
	if lit != _blink_on:
		_blink_on = lit
		queue_redraw()


func _draw() -> void:
	if off:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
		if idle != -1:
			var text := T.text(idle)
			var at := Vector2(10, 18)
			draw_string(Pal.mono, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, IDLE_INK)
			if _blink_on:
				var w := Pal.mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
				draw_rect(Rect2(at.x + w + 3, at.y - 9, 6, 11), IDLE_INK)
	var x := size.x * 0.62
	draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 70, 0), Vector2(x + 20, size.y), Vector2(x - 50, size.y)]),
		Color(1, 1, 1, 0.035 if off else 0.02))
