class_name UrgencyBar
extends Control
## Barra de agravamento da emergência, no bloco da ligação do painel de baixo, numa linha só (o estágio escrito à
## esquerda, a barra à direita; um em cima do outro, empurravam o painel para cima): o tempo até a situação piorar.
## Esvazia da direita para a esquerda pelos três estágios (inicial, agravando, agravada) e pisca quando muda de estágio. Só aparece com o operador na linha da emergência;
## fora dela continua correndo (a luz de ocorrência do rádio mostra). O estado fica na PhoneCall (`Urgency`).

const COLORS := [Pal.GREEN, Pal.AMBER, Pal.RED]
const NAMES := [T.Key.URGENCY_0, T.Key.URGENCY_1, T.Key.URGENCY_2]
const BLINK_SEC := 1.4   ## quanto tempo pisca ao mudar de estágio

var call: PhoneCall      ## a emergência na linha do FONE (o `Urgency` põe a cada quadro)

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
	Bloom.clear(self)
	# o `Urgency` pode passar ao estágio 3 (perdida) depois do `_process` daqui, no mesmo quadro: ainda visível
	if not _active() or fmod(_blink, 0.3) > 0.15:
		return
	var e: EmergencyCall = call.data
	var col: Color = COLORS[call.stage]
	draw_string(Pal.ui, Vector2(0, 10), T.text(NAMES[call.stage]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	var label_w := 0.0   # a do nome mais longo: a barra não muda de lugar com o estágio
	for k in NAMES:
		label_w = maxf(label_w, Pal.ui.get_string_size(T.text(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x)
	var r := Rect2(label_w + 10, 3, size.x - label_w - 12, size.y - 6)
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
	Bloom.light(self, Rect2(r.position, Vector2(left, r.size.y)), col, 0.6)
