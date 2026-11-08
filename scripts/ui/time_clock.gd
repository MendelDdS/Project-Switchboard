extends Control
## O relógio de ponto da abertura (`Intro`): o cartão de Maria, da quinzena de outubro (uma linha por noite, 1 a 15,
## o dia do mês e o domingo em vermelho), em pé na fenda do relógio, com a entrada e a saída das noites que passaram
## carimbadas (a tinta do carimbo, `Pal.TOLL_INK`). O clique (ou o Enter, gravado na caixa; `punch`) bate o ponto: o cartão desce na fenda puxado pelo relógio, o furador
## bate, ele sobe com a entrada da noite carimbada e o turno começa (`punched`). Sob o mouse, o cartão sobe um pouco.

signal punched

const CARD := Rect2(8, 0, 64, 112)   ## o cartão em pé, na posição de descanso (o pé dentro da fenda)
const MACHINE := Rect2(0, 106, 80, 50)   ## a caixa do relógio, com a fenda em cima
const ROW_TOP := 14.0   ## a primeira linha do cartão
const ROW := 6.0
const DIP := 40.0   ## o quanto o cartão desce na fenda batendo o ponto
const DIP_SEC := 0.22
const LIFT_PX := 2.0

var night := 0   ## a noite de hoje (0: o treinamento, sem linha no cartão; 16: o epílogo, depois da última)
var last := 15   ## a última noite (as linhas do cartão)
var _done := false   ## a entrada de hoje já carimbada
var _busy := false
var _dip := 0.0:
	set(v):
		_dip = v
		queue_redraw()
var _lift := 0.0:
	set(v):
		_lift = v
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = MACHINE.end
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): if not _busy: create_tween().tween_property(self, "_lift", 1.0, 0.1))
	mouse_exited.connect(func(): create_tween().tween_property(self, "_lift", 0.0, 0.1))


## Volta ao começo (a abertura de uma noite nova).
func reset(n: int, last_night: int) -> void:
	night = n
	last = last_night
	_done = false
	_busy = false
	_dip = 0.0


## Bate o ponto: o cartão desce, o furador bate, a entrada aparece e ele sobe; no fim, `punched`.
func punch() -> void:
	if _busy:
		return
	_busy = true
	Sfx.play("feed", -6.0)
	var tw := create_tween()
	tw.tween_property(self, "_lift", 0.0, 0.06)
	tw.tween_property(self, "_dip", 1.0, DIP_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		Sfx.play("punch")
		_done = true)
	tw.tween_interval(0.12)
	tw.tween_property(self, "_dip", 0.0, DIP_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_callback(punched.emit)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		accept_event()
		punch()


func _draw() -> void:
	var c := CARD
	c.position.y += roundf(_dip * DIP - _lift * LIFT_PX)
	_draw_card(c)
	_draw_machine()


## O cartão: o papel, o título e o nome no alto, o fio vermelho e as linhas das noites, com o dia, a entrada e a saída.
func _draw_card(c: Rect2) -> void:
	draw_rect(Rect2(c.position + Vector2(2, 2), c.size), Color(0, 0, 0, 0.35))   # a sombra
	draw_rect(c, Pal.PAPER)
	draw_rect(Rect2(c.position.x, c.position.y, c.size.x, 1), Pal.lit(Pal.PAPER, 1))   # a beira de cima, na luz
	var title := PixelArt.tiny(T.text(T.Key.TIME_CARD))
	draw_texture(title, Vector2(c.position.x + floorf((c.size.x - title.get_width()) / 2.0), c.position.y - 1), Pal.INK)
	draw_rect(Rect2(c.position.x + 2, c.position.y + 10, c.size.x - 4, 1), Pal.INK_RED)
	for i in last:
		var n := i + 1
		var y := c.position.y + ROW_TOP + i * ROW
		draw_rect(Rect2(c.position.x + 2, y + 5, c.size.x - 4, 1), Pal.NOTE_RULE)
		var d := GameData.date_of(n)
		draw_texture(PixelArt.tiny(str(d.day)), Vector2(c.position.x + 3, y - 3), Pal.INK_RED if d.weekday == 0 else Pal.INK)
		if n < night or (n == night and _done):
			draw_texture(PixelArt.tiny("18:00"), Vector2(c.position.x + 18, y - 3), Pal.TOLL_INK)
		if n < night:
			draw_texture(PixelArt.tiny("06:00" if n == last else "00:00"), Vector2(c.position.x + 41, y - 3), Pal.TOLL_INK)


## A caixa do relógio: o aço pintado com a beira de cima na luz, a fenda escura, o mostrador com os ponteiros nas 18h
## e os parafusos.
func _draw_machine() -> void:
	var m := MACHINE
	var steel: Array[Color] = Pal.STEEL_TONES
	draw_rect(m, steel[3])
	draw_rect(Rect2(m.position, Vector2(m.size.x, 2)), steel[5])
	draw_rect(Rect2(m.position.x, m.end.y - 2, m.size.x, 2), steel[1])
	draw_rect(Rect2(m.end.x - 2, m.position.y + 2, 2, m.size.y - 4), steel[2])
	draw_rect(Rect2(CARD.position.x - 2, m.position.y + 2, CARD.size.x + 4, 3), Pal.STEEL_DARK[0])   # a fenda
	var mid := Vector2(m.get_center().x, m.position.y + 28)
	draw_texture(PixelArt.disc(25, [[10.5, Pal.PAPER], [12.5, Pal.NICKEL[1], Pal.NICKEL[2], Pal.NICKEL[3]]]), mid - Vector2(12, 12))
	for k in 12:   # as marcas das horas
		var a := TAU * k / 12.0
		draw_rect(Rect2((mid + Vector2(sin(a), -cos(a)) * 8.0).round(), Vector2.ONE), Pal.INK)
	draw_rect(Rect2(mid.x, mid.y - 7, 1, 7), Pal.INK)   # o ponteiro dos minutos, no 12
	draw_rect(Rect2(mid.x, mid.y, 1, 5), Pal.INK)   # o das horas, no 6
	for x in [m.position.x + 4, m.end.x - 6]:   # os parafusos
		draw_rect(Rect2(x, m.end.y - 7, 2, 2), Pal.NICKEL[2])
	var key := PixelArt.tiny("ENTER")   # gravado: a tecla que também bate o ponto
	draw_texture(key, Vector2(mid.x - floorf(key.get_width() / 2.0), m.end.y - 13), steel[1])
