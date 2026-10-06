class_name ConsoleMini
extends Control
## O painel do operador em miniatura, embutido na frente do console da mesa comutadora, onde ficava o rádio: o painel
## de baixo (`PhonePanel`) é a vista de perto dele. Copia a disposição de verdade dos blocos (a tela da conversa, as
## três teclas e o rádio, cada um no lugar e na proporção que tem lá) e o estado: a tela acende com uma ligação no
## painel e as falas viram traços, as teclas ativas acendem, e o rádio acende as luzes dele e mostra traços quando fala.

const WOOD := PhonePanel.WOOD
const SCREEN := Color(0.043, 0.047, 0.05)   # o fundo das telas (`HudPanel`)
const BORDER := Color(0.1, 0.07, 0.045)
const INK := {"op": Color("8dbb6c"), "sys": Color("9a917a"), "ghost": Color("c6d3c4")}   # a cor de quem fala, como na tela
const TEXT := Color("e6dbbd")

var phone: PhonePanel


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if phone == null or not phone.is_inside_tree():
		return
	var src := phone.get_global_rect()
	var k := (size.x - 8.0) / src.size.x
	var o := Vector2(4.0, roundf((size.y - src.size.y * k) / 2.0))
	var at := func(c: Control) -> Rect2:   # o lugar de um bloco do painel, na miniatura
		var g := c.get_global_rect()
		return Rect2((o + (g.position - src.position) * k).round(), (g.size * k).round())
	# o console: a madeira, com a beira escura e a quina de cima pegando a luz
	var body := Rect2(o - Vector2(4, 3), src.size * k + Vector2(8, 6)).abs()
	draw_rect(Rect2(body.position + Vector2(1, 2), body.size), Color(0, 0, 0, 0.35))
	draw_rect(body.grow(1), Switchboard.EDGE_DARK)
	draw_rect(body, WOOD[3])
	draw_rect(Rect2(body.position, Vector2(body.size.x, 1)), WOOD[0])
	_screen(at.call(phone.screen))
	for b in phone.keys():
		_key(at.call(b), b)
	_radio(at)


## A tela da conversa: apagada sem ligação; com uma, as últimas falas viram traços (o nome na cor de quem fala e a fala
## em creme, do comprimento dela).
func _screen(r: Rect2) -> void:
	_block(r)
	var c := phone.shown()
	var inner := r.grow(-2)
	if c != null:
		var count := mini(phone.shown_lines, floori((inner.size.y - 1.0) / 3.0))   # as mesmas falas da tela, se couberem
		var lines: Array = c.transcript.slice(c.transcript.size() - count)
		for i in lines.size():
			var l: Dictionary = lines[i]
			var y := inner.position.y + 1.0 + i * 3.0
			var who: Color = INK.get(l["cls"], Pal.AMBER)
			var name_w := 0.0 if l["cls"] == "sys" else 3.0
			draw_rect(Rect2(inner.position.x + 1.0, y, name_w, 1), who)
			var w := clampf(String(l["text"]).length() * 0.35, 3.0, inner.size.x - name_w - 4.0)
			draw_rect(Rect2(inner.position.x + name_w + 2.0, y, roundf(w), 1), INK["sys"] if l["cls"] == "sys" else TEXT)
	else:
		draw_rect(inner, Color(0, 0, 0, 0.45))
		if fmod(Time.get_ticks_msec() / 1000.0, ScreenGlass.BLINK * 2.0) < ScreenGlass.BLINK:   # o cursor esperando
			draw_rect(Rect2(inner.position + Vector2(2, 2), Vector2(1, 2)), ScreenGlass.IDLE_INK)
	var x := inner.position.x + inner.size.x * 0.62   # o reflexo do vidro
	draw_colored_polygon(PackedVector2Array([Vector2(x, inner.position.y), Vector2(x + 4, inner.position.y),
		Vector2(x + 1, inner.end.y), Vector2(x - 3, inner.end.y)]), Color(1, 1, 1, 0.05))


## Uma tecla: o tampo na cor dela (apagada, escura) e a frente mais escura embaixo.
func _key(r: Rect2, b: Button) -> void:
	var cap := b.get_theme_stylebox("normal") as KeyCapStyle
	var col: Color = cap.color if cap else Pal.AMBER
	if b.disabled:
		col = col.darkened(0.55)
	draw_rect(r, Color.BLACK)
	draw_rect(r.grow(-1), col.darkened(0.5))
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, r.size.y - 4)), col)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), col.lightened(0.3))


## O rádio, peça por peça no lugar de cada uma no rádio de verdade (`Radio.parts`): o alto-falante em fendas, as
## duas luzes como estão, as legendas em traços apagados e a tela com as mesmas linhas, quebradas na largura dela como
## lá (`_wrap`): as mensagens anteriores, apagadas, em cima, e a de agora embaixo.
func _radio(at: Callable) -> void:
	var radio := phone.radio
	var p := radio.parts()
	_block(at.call(radio))
	var grill: Rect2 = at.call(p["grill"])
	for y in range(int(grill.position.y), int(grill.end.y), 2):
		draw_rect(Rect2(grill.position.x, y, grill.size.x, 1), Color(0.2353, 0.2078, 0.1529))
	var lamps := radio.lamps()
	for i in 2:
		var lr: Rect2 = at.call(p[["led", "alert"][i]])
		draw_rect(Rect2(lr.position, lr.size.max(Vector2(2, 2))), lamps[i])
	for key in ["caption", "alert_label"]:
		var label: Label = p[key]
		var lr: Rect2 = at.call(label)
		draw_rect(Rect2(lr.position.x, roundf(lr.get_center().y), lr.size.x, 1), Color(Pal.DIM, 0.6) * label.modulate)   # o rótulo tem a largura do texto
	draw_rect(at.call(p["box"]), Color(0.03, 0.045, 0.035))
	var k: float = (at.call(radio) as Rect2).size.x / maxf(1.0, radio.size.x)
	var lines := radio.lines()
	var now: Array = lines.pop_back()
	var hr: Rect2 = at.call(p["history"])
	var rows := []   # [comprimento em caracteres, cor], de cima para baixo
	for l in lines:
		for n in _wrap(l[0], (p["history"] as Control).size.x):
			rows.append([n, l[1]])
	var pitch := maxf(2.0, roundf(13.0 * k))
	var y := hr.end.y - rows.size() * pitch
	for row in rows:
		if y >= hr.position.y:
			draw_rect(Rect2(hr.position.x, y, roundf(row[0] * _char_w() * k), 1), row[1])
		y += pitch
	var sr: Rect2 = at.call(p["screen"])
	y = sr.position.y
	for n in _wrap(now[0], (p["screen"] as Control).size.x):
		draw_rect(Rect2(sr.position.x, y, maxf(1.0, roundf(n * _char_w() * k)), 1), now[1])
		y += pitch


## Os comprimentos (em caracteres) das linhas de `text` quebrado por palavra numa largura de `width` px, como a tela faz.
func _wrap(text: String, width: float) -> PackedInt32Array:
	var per := maxi(1, floori(width / _char_w()))
	var out := PackedInt32Array()
	var cur := 0
	for word in text.split(" ", false):
		var add := word.length() if cur == 0 else cur + 1 + word.length()
		if cur > 0 and add > per:
			out.append(cur)
			cur = word.length()
		else:
			cur = add
	if cur > 0:
		out.append(cur)
	return out


func _char_w() -> float:
	return Pal.mono.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x


## Um bloco do console: a tela escura com a borda dele.
func _block(r: Rect2) -> void:
	draw_rect(r, BORDER)
	draw_rect(r.grow(-1), SCREEN)
