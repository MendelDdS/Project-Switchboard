class_name UrgencyBar
extends Control
## Barra de agravamento da emergência, na base da caixa da conversa (aparece ocupando uma linha dela, sem mexer no
## resto do painel): o tempo até a situação piorar. Esvazia da direita para a esquerda pelos três estágios
## (inicial, agravando, agravada) e pisca quando muda de estágio. Só aparece com o operador na linha da emergência;
## fora dela continua correndo (a luz de ocorrência do rádio mostra). O estado fica na PhoneCall (Main._worsen).

const COLORS := [Pal.GREEN, Pal.AMBER, Pal.RED]
const NAMES := [T.Key.URGENCY_0, T.Key.URGENCY_1, T.Key.URGENCY_2]
const BAR_X := 236.0     ## onde a barra começa (antes dela, o estágio)
const BLINK_SEC := 1.4   ## quanto tempo pisca ao mudar de estágio

var call: PhoneCall      ## emergência em andamento (Main põe quando ela toca)

var _stage := 0
var _blink := 0.0


func _process(delta: float) -> void:
	_blink = maxf(0.0, _blink - delta)
	if _active() and call.stage != _stage:
		_blink = BLINK_SEC
	_stage = call.stage if call != null else 0
	if visible != _active():
		visible = _active()
	queue_redraw()


func _active() -> bool:
	return call != null and call.urgent() and call.on_line


func _draw() -> void:
	if fmod(_blink, 0.3) > 0.15:
		return
	var e: EmergencyCall = call.data
	var col: Color = COLORS[call.stage]
	var label := T.text(NAMES[call.stage])
	draw_string(Pal.ui, Vector2(0, size.y - 2), label, HORIZONTAL_ALIGNMENT_LEFT, BAR_X - 8, 11, col)
	var r := Rect2(BAR_X, 4, size.x - BAR_X - 2, size.y - 8)
	draw_rect(r.grow(2), Pal.EDGE)
	var total := e.stage_sec.x + e.stage_sec.y + e.stage_sec.z
	var x := r.end.x
	for i in 3:   # as três zonas, da direita (inicial) para a esquerda (agravada)
		var w := r.size.x * e.stage_sec[i] / total
		draw_rect(Rect2(x - w, r.position.y, w, r.size.y), (COLORS[i] as Color).darkened(0.72))
		if i > 0:
			draw_rect(Rect2(x - 1, r.position.y, 2, r.size.y), Pal.EDGE)
		x -= w
	var left := floorf(r.size.x * clampf(1.0 - call.urgency / total, 0.0, 1.0))
	draw_rect(Rect2(r.position, Vector2(left, r.size.y)), col)
