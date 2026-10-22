extends Control
## O porta-fitas (equipamento da B4, `Switchboard.set_equipment`): um suporte de madeira de pé na prateleira com as
## fitas virgens da noite (`Bureaucracy.tapes`); clicar põe uma no gravador. Pixel art provisória.

const SLOTS := 3   ## lugares no suporte (mais fitas que isso não aparecem)
const CASSETTE := Vector2(8, 14)

var _hover := false
var _drawn := [false, 0]   ## [sob o mouse, virgens] do último desenho

@onready var _desk := Bureaucracy.of(self)   ## o gerente (procurado uma vez: subir a árvore a cada quadro pesa)


func _ready() -> void:
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)


func _process(_delta: float) -> void:
	var look := [_hover, _desk.tapes.blank if _desk else 0]
	if look != _drawn:
		_drawn = look
		queue_redraw()


func _draw() -> void:
	var lift := Vector2(0, -1) if _hover else Vector2.ZERO   # sob o mouse, sobe um pixel, como os objetos da mesa
	var base := Rect2(Vector2(0, size.y - 5) + lift, Vector2(size.x, 5))
	for i in mini(_drawn[1], SLOTS):
		var at := Vector2(3 + i * 10, base.position.y + 3 - CASSETTE.y)   # cada fita afunda 3 px no suporte
		draw_rect(Rect2(at, CASSETTE), Pal.BAKELITE[1])
		draw_rect(Rect2(at + Vector2(1, 0), CASSETTE - Vector2(2, 1)), Pal.BAKELITE[3])
		draw_rect(Rect2(at + Vector2(1, 2), Vector2(6, 3)), Pal.TICKET)   # a etiqueta em branco
		draw_rect(Rect2(at + Vector2(2, 7), Vector2(1, 1)), Pal.NICKEL[2])
		draw_rect(Rect2(at + Vector2(5, 7), Vector2(1, 1)), Pal.NICKEL[2])
	draw_rect(base, Pal.BOARD[1])
	draw_rect(Rect2(base.position, Vector2(base.size.x, 1)), Pal.BOARD[0])
	draw_rect(Rect2(base.position + Vector2(0, 4), Vector2(base.size.x, 1)), Pal.BOARD[2])
	for i in SLOTS:   # as fendas dos lugares
		draw_rect(Rect2(base.position + Vector2(3 + i * 10, 1), Vector2(CASSETTE.x, 1)), Pal.BOARD[2])


func _gui_input(e: InputEvent) -> void:
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or b.pressed:
		return
	if _desk.tapes.insert():
		Sfx.play_at("key", global_position.x / get_viewport().get_visible_rect().size.x)
	else:
		_desk.main.warn(T.text(T.Key.WARN_NO_TAPES if _desk.tapes.blank <= 0 else T.Key.WARN_TAPE_INSIDE))
	accept_event()
