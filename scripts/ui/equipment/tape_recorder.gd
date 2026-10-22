extends Control
## O gravador de fitas (equipamento da B4, `Switchboard.set_equipment`): a janela com a fita (as bobinas giram
## gravando), a lâmpada REC acesa enquanto grava (`Bureaucracy.tapes.recording`) e as duas teclas, Entregar (às
## autoridades) e Descartar (`Tapes.eject`). Pixel art provisória.

const WINDOW := Rect2(4, 7, 26, 10)
const LAMP := Rect2(35, 8, 3, 3)
const KEY_Y := 8.0
const KEY_H := 9.0
const SPIN_MS := 160   ## a cada tanto, os raios das bobinas avançam um passo

var _keys := []   ## [Rect2, entregar?]
var _hover := -1
var _drawn := [-1, false, false, 0]   ## [tecla sob o mouse, com fita, gravando, passo das bobinas] do último desenho

@onready var _desk := Bureaucracy.of(self)   ## o gerente (procurado uma vez: subir a árvore a cada quadro pesa)


func _ready() -> void:
	var x := 44.0
	for k in [[T.Key.EQUIP_DELIVER, true], [T.Key.EQUIP_DISCARD, false]]:
		var w := PixelArt.tiny(T.text(k[0])).get_width() + 4.0
		_keys.append([Rect2(x, KEY_Y, w, KEY_H), k[1], k[0]])
		x += w + 2.0
	mouse_exited.connect(func(): _hover = -1)


func _process(_delta: float) -> void:
	var tp = _desk.tapes if _desk else null
	var rec: bool = tp != null and tp.recording()
	var look := [_hover, tp != null and not tp.inside.is_empty(), rec, PixelArt.ms() / SPIN_MS if rec else 0]
	if look != _drawn:
		_drawn = look
		queue_redraw()


func _draw() -> void:
	Bloom.clear(self)
	var loaded: bool = _drawn[1]
	var rec: bool = _drawn[2]
	var body := Rect2(0, 4, size.x, size.y - 4)
	draw_rect(Rect2(1, 2, size.x - 2, 2), Pal.BAKELITE[3])   # o tampo, visto de cima
	draw_rect(body, Pal.BAKELITE[2])
	draw_rect(Rect2(body.position, Vector2(body.size.x, 1)), Pal.BAKELITE[4])
	draw_rect(Rect2(body.position + Vector2(0, body.size.y - 1), Vector2(body.size.x, 1)), Pal.BAKELITE[0])
	draw_rect(WINDOW, Pal.VOID)
	if loaded:
		draw_rect(WINDOW.grow(-1), Pal.BAKELITE[3])
		draw_rect(Rect2(WINDOW.position + Vector2(3, 2), Vector2(WINDOW.size.x - 6, 2)), Pal.TICKET)
		var step: int = _drawn[3] % 4
		for cx in [WINDOW.position.x + 7, WINDOW.position.x + WINDOW.size.x - 9]:
			var hub := Rect2(cx, WINDOW.position.y + 5, 3, 3)
			draw_rect(hub, Pal.NICKEL[2])
			draw_rect(Rect2(hub.position + [Vector2(1, 0), Vector2(2, 1), Vector2(1, 2), Vector2(0, 1)][step], Vector2.ONE), Pal.NICKEL[3])
	draw_rect(LAMP, Pal.RED if rec else Pal.INK_RED.darkened(0.4))
	if rec:
		Bloom.light(self, LAMP, Pal.RED, 0.6)
	draw_texture(PixelArt.tiny("REC"), Vector2(LAMP.position.x - 4, LAMP.end.y - 1), Pal.DIM)
	for i in _keys.size():
		var r: Rect2 = _keys[i][0]
		if i == _hover and loaded:
			r.position.y += 1   # a tecla afunda sob o dedo
		draw_rect(r, Pal.BAKELITE[4] if loaded else Pal.BAKELITE[3])
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Pal.NICKEL[3])
		draw_texture(PixelArt.tiny(T.text(_keys[i][2])), r.position + Vector2(2, -2), Pal.TEXT if loaded else Pal.DIM)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_hover = _keys.find_custom(func(k): return (k[0] as Rect2).grow(1).has_point(e.position))
		return
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or b.pressed or _hover == -1:
		return
	if _desk.tapes.inside.is_empty():
		_desk.main.warn(T.text(T.Key.WARN_NO_TAPE))
	else:
		_desk.tapes.eject(_keys[_hover][1])
		Sfx.play_at("key", global_position.x / get_viewport().get_visible_rect().size.x)
	accept_event()
