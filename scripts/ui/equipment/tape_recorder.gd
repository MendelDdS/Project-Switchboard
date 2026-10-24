extends Control
## O gravador de fitas (equipamento da B4, `Switchboard.set_equipment`) e, ao lado, a caixa das autoridades. No
## gravador: as teclas de piano (REC desce sozinha enquanto grava, `Bureaucracy.tapes.recording`; Entregar e
## Descartar tiram a fita, `Tapes.eject`), a porta com a fita atrás do vidro, na escala de verdade (a etiqueta escrita
## à mão com o nome de quem é gravado, a hora e um risquinho por palavra-chave; as bobinas girando e a fita passando de
## uma para a outra), o VU com o ponteiro pulando com a voz, o contador, a lâmpada REC e o alto-falante.
##
## Tudo se mexe com peso (`movimento-organico`): a fita que sai do porta-fitas sobe da fenda, vira no ar e cai na porta,
## que abre de mola e bate; o gravador e o porta-fitas pulam. Entregue, ela pula da porta e cai em pé na caixa; descartada,
## pula e cai pela beira da prateleira. A lógica acontece no clique; a animação só mostra (`_fly`).

const Cassette := preload("res://scripts/ui/equipment/cassette.gd")
const BODY := Rect2(0, 3, 96, 42)   ## a frente do gravador (a altura toda até o bloco interurbano)
const TOP := 3   ## as linhas do tampo
const KEY_Y := 5.0   ## as teclas, no alto da frente
const KEY_H := 7.0
const DOOR := Rect2(2, 15, 46, 28)   ## a porta com o vidro, a fita atrás
const SEAT := Vector2(3, 16)   ## o canto da fita dentro da porta
const VU := Rect2(53, 16, 25, 13)
const COUNTER := Rect2(81, 17, 13, 7)
const LAMP := Rect2(86, 28, 3, 3)
const GRILLE := Rect2(53, 33, 26, 9)   ## o alto-falante, furadinho
const BOX := Rect2(103, 33, 28, 12)   ## a frente da caixa das autoridades
const BOX_SPOT := Vector2(106, 15)   ## onde fica, em pé, a primeira fita entregue (as outras, `BOX_PITCH` à direita)
const BOX_PITCH := 7.0
const SPIN_MS := 120   ## a cada tanto, os raios das bobinas avançam um passo
const FILL_SEC := 90.0   ## gravando isso, a fita passou toda para a bobina da direita
const WRITE_SEC := 0.07   ## cada letra da etiqueta
const POP_SEC := 0.25   ## o risquinho novo, maior
const BOUNCE_SEC := 0.08   ## o gravador ou a caixa afundando 1 px quando a fita bate
const KEY_SEC := 0.18   ## a tecla apertada antes de voltar

## As animações da fita (`_fly`): o caminho é feito de trechos, cada um com a duração, de onde a onde, a largura
## (de lado a de frente) e a curva.
enum Fly { NONE, IN, DELIVER, DISCARD }

var _keys := []   ## [Rect2, entregar?, T.Key]: as teclas que tiram a fita
var _rec_key := Rect2()
var _hover := -1
var _pressed := -1   ## a tecla que está afundada (`KEY_SEC`)
var _press_t := 0.0
var _was_rec := false
var _rec_sec := 0.0   ## o tempo gravado na fita de agora (as bobinas e o contador)
var _bound: PhoneCall   ## a conversa na fita de agora (mudou: a etiqueta é escrita de novo)
var _label := ""
var _hour := ""   ## a hora em que ela começou a gravar, escrita embaixo do nome
var _write_t := 0.0
var _marks := 0
var _pop := 0.0
var _needle := 0.0   ## o ponteiro do VU, de 0 (parado) a 1 (no vermelho)
var _needle_v := 0.0
var _door := 0.0   ## a porta: 0 fechada, 1 aberta
var _bounce := 0.0
var _box_bounce := 0.0
var _delivered := 0   ## as fitas em pé na caixa
var _fly := Fly.NONE
var _fly_t := 0.0
var _flying := {}   ## a fita voando: {"from", "label", "marks", "fill", "deliver"}
var _had_tape := false
var _drawn := []

@onready var _desk := Bureaucracy.of(self)   ## o gerente (procurado uma vez: subir a árvore a cada quadro pesa)


func _ready() -> void:
	var x := BODY.end.x - 3.0
	for k in [[T.Key.EQUIP_DISCARD, false], [T.Key.EQUIP_DELIVER, true]]:   # da direita para a esquerda
		var w := PixelArt.tiny(T.text(k[0])).get_width() + 4.0
		x -= w
		_keys.push_front([Rect2(x, KEY_Y, w, KEY_H), k[1], k[0]])
		x -= 2.0
	_rec_key = Rect2(x - 11.0, KEY_Y, 11, KEY_H)
	mouse_exited.connect(func(): _hover = -1)


func _process(delta: float) -> void:
	var tp = _desk.tapes if _desk else null
	if tp == null:
		return
	var loaded: bool = not tp.inside.is_empty()
	var rec: bool = tp.recording()
	if loaded and not _had_tape:   # uma fita entrou: vem voando do porta-fitas
		_start_in(tp.blank)
	_had_tape = loaded
	if rec != _was_rec:
		Sfx.play_at("tape_key" if rec else "click", _sx(), -4.0)
		_was_rec = rec
	if rec:
		_rec_sec += delta
	var c: PhoneCall = tp.inside.get("call") if loaded else null
	if c != _bound:
		_bound = c
		_label = Cassette.label_of(c) if c != null else ""
		_hour = Main.fmt(_desk.main.minutes) if c != null else ""
		_write_t = 0.0
		if c != null:
			Sfx.play_at("pencil", _sx(), -6.0)
	_write_t += delta
	var marks: int = tp.inside["words"].size() if loaded else 0
	if marks > _marks:
		_pop = POP_SEC
		Sfx.play_at("pencil", _sx(), -10.0, 1.4)
	_marks = marks
	_pop = maxf(_pop - delta, 0.0)
	_press_t = maxf(_press_t - delta, 0.0)
	if _press_t == 0.0:
		_pressed = -1
	_bounce = maxf(_bounce - delta, 0.0)
	_box_bounce = maxf(_box_bounce - delta, 0.0)
	_step_needle(delta, rec and c != null and _desk.main.eavesdrop.speaking(c.line))
	if _fly != Fly.NONE:
		_step_fly(delta)
	_delivered = tp.done.filter(func(t): return t["fate"] == "entregue").size() - (1 if _fly == Fly.DELIVER else 0)
	var shown := [_hover, loaded, rec, PixelArt.ms() / SPIN_MS if rec else 0, int(_rec_sec * 2.0), roundi(_needle * 12.0),
		_written(), _marks, _pop > 0.0, _pressed, roundi(_door * 8.0), _bounce > 0.0, _box_bounce > 0.0, _delivered,
		_fly, int(_fly_t * 60.0)]
	if shown != _drawn:
		_drawn = shown
		queue_redraw()


## O ponteiro do VU: com voz na linha gravada, pula para onde ela puxa; sem, cai. Uma mola com atrito (sobe rápido,
## passa um pouco e volta); o puxão varia com a fala, sem sorteio (o global segue a semente do jogo).
func _step_needle(delta: float, voice: bool) -> void:
	var ms := PixelArt.ms()
	var aim := 0.0
	if voice:
		aim = clampf(0.5 + 0.3 * sin(ms * 0.021) * sin(ms * 0.0057 + 1.3) + 0.2 * sin(ms * 0.047), 0.05, 1.0)
	_needle_v += ((aim - _needle) * 260.0 - _needle_v * 18.0) * delta
	_needle = clampf(_needle + _needle_v * delta, 0.0, 1.05)


func _written() -> int:
	return mini(int(_write_t / WRITE_SEC), _label.length() + _hour.length())


func _sx() -> float:
	return global_position.x / get_viewport().get_visible_rect().size.x


# ---- a fita voando

func _start_in(slot: int) -> void:
	var rack := get_tree().get_first_node_in_group(&"tape_rack") as Control
	var from: Vector2 = (rack.slot_pos(slot) - global_position) if rack else SEAT + Vector2(Cassette.FACE.x / 2.0 - 2, -30)
	_rec_sec = 0.0
	_fly = Fly.IN
	_fly_t = 0.0
	_flying = {"from": from, "label": "", "marks": 0, "fill": 0.0}


func _start_out(deliver: bool) -> void:
	_flying = {"from": SEAT, "label": _label, "hour": _hour, "written": _written(), "marks": _marks, "fill": _fill(), "deliver": deliver}
	_fly = Fly.DELIVER if deliver else Fly.DISCARD
	_fly_t = 0.0
	_bound = null
	_label = ""
	_hour = ""
	_marks = 0
	_rec_sec = 0.0


func _fill() -> float:
	return clampf(_rec_sec / FILL_SEC, 0.0, 1.0)


## Os trechos de cada voo: [segundos, até onde (o canto da fita), largura no fim (0 de lado, 1 de frente), curva].
## Curvas: "in" acelera (cai, sai da fenda), "out" freia (pula, sobe), "arc" anda reto e sobe e desce no meio.
func _legs() -> Array:
	var from: Vector2 = _flying["from"]
	var over := SEAT + Vector2(0, -12)   # em cima da porta, de frente
	match _fly:
		Fly.IN:
			var up := from + Vector2(0, -8)
			return [[0.12, up, 0.0, "in"], [0.24, over, 1.0, "arc"], [0.08, SEAT, 1.0, "in"]]
		Fly.DELIVER:
			var spot := BOX_SPOT + Vector2(_delivered * BOX_PITCH - (Cassette.FACE.x - Cassette.SPINE_W) / 2.0, 0)
			return [[0.13, SEAT + Vector2(0, -14), 1.0, "out"], [0.26, spot + Vector2(0, -10), 0.0, "arc"], [0.08, spot, 0.0, "in"]]
		Fly.DISCARD:
			return [[0.13, SEAT + Vector2(0, -14), 1.0, "out"], [0.55, SEAT + Vector2(-14, 110), 0.5, "fall"]]
	return []


## O ponto do voo agora: [canto, largura (0 a 1)]; nulo, acabou.
func _fly_pose() -> Array:
	var at: Vector2 = _flying["from"]
	var w := 0.0 if _fly == Fly.IN else 1.0
	var t := _fly_t
	for leg: Array in _legs():
		var k := t / float(leg[0])
		if k < 1.0:
			var to: Vector2 = leg[1]
			match leg[3]:
				"in":
					at = at.lerp(to, k * k)
				"out":
					at = at.lerp(to, 1.0 - (1.0 - k) * (1.0 - k))
				"arc":
					at = at.lerp(to, smoothstep(0.0, 1.0, k)) + Vector2(0, -10.0 * sin(PI * k))
				"fall":   # anda para a frente e cai acelerando, virando duas vezes
					at = Vector2(lerpf(at.x, to.x, k), at.y + (to.y - at.y) * k * k)
					return [at, absf(cos(k * TAU))]
			return [at, lerpf(w, float(leg[2]), smoothstep(0.0, 1.0, k))]
		t -= float(leg[0])
		at = leg[1]
		w = leg[2]
	return []


func _step_fly(delta: float) -> void:
	var before := _fly_t
	_fly_t += delta
	var legs := _legs()
	var ends := []   # quando acaba cada trecho
	var sum := 0.0
	for leg: Array in legs:
		sum += float(leg[0])
		ends.append(sum)
	match _fly:
		Fly.IN:
			_door = clampf(_fly_t / 0.08, 0.0, 1.0) if _fly_t < ends[-1] else _door
			if before < ends[-1] and _fly_t >= ends[-1]:   # bateu na porta: ela fecha de mola e tudo pula
				_land()
				Sfx.play_at("tape_in", _sx())
		Fly.DELIVER, Fly.DISCARD:
			var e := maxf(_fly_t - 0.03, 0.0)   # a porta pula aberta (passa um pouco e volta) e fecha depois
			_door = 1.0 + 0.15 * sin(clampf(e / 0.12, 0.0, 1.0) * PI) if e < 0.12 else (1.0 if _fly_t < 0.36 else maxf(1.0 - (_fly_t - 0.36) / 0.06, 0.0))
			if before < 0.36 + 0.06 and _fly_t >= 0.36 + 0.06:
				Sfx.play_at("tape_door", _sx(), -6.0)
			if _fly == Fly.DELIVER and before < ends[-1] and _fly_t >= ends[-1]:
				_box_bounce = BOUNCE_SEC
				Sfx.play_at("drop", _sx() + 0.1)
	if _fly == Fly.IN and _fly_t >= ends[-1]:
		_door = maxf(1.0 - (_fly_t - ends[-1]) / 0.06, 0.0)   # fecha acelerando
		if _door == 0.0:
			Sfx.play_at("tape_door", _sx())
			_fly = Fly.NONE
	elif _fly == Fly.DISCARD and before < ends[-1] - 0.12 and _fly_t >= ends[-1] - 0.12:
		Sfx.play_at("drop", _sx(), -9.0, 0.8)   # lá embaixo, no chão
	if _fly != Fly.IN and _fly_t >= maxf(ends[-1], 0.42):
		_fly = Fly.NONE


## A fita bateu no gravador: ele afunda 1 px e o porta-fitas ao lado pula.
func _land() -> void:
	_bounce = BOUNCE_SEC
	var rack := get_tree().get_first_node_in_group(&"tape_rack")
	if rack:
		rack.bump()


# ---- desenho

func _draw() -> void:
	Bloom.clear(self)
	var tp = _desk.tapes if _desk else null
	var loaded: bool = tp != null and not tp.inside.is_empty() and _fly != Fly.IN
	var rec: bool = _drawn[2] if not _drawn.is_empty() else false
	_draw_box()
	var dy := Vector2(0, 1) if _bounce > 0.0 else Vector2.ZERO
	draw_rect(Rect2(BODY.position.x + 1, BODY.end.y, BODY.size.x + 2, 1), Pal.SHELF_WOOD[0].darkened(0.5))   # a sombra rente
	Cassette.block(self, Rect2(BODY.position + dy, BODY.size), TOP, Pal.BAKELITE[4], Pal.BAKELITE[2], Pal.BAKELITE[1])
	draw_rect(Rect2(BODY.position + dy, Vector2(BODY.size.x, 1)), Pal.BAKELITE[5])   # a quina de cima, na luz
	draw_rect(Rect2(BODY.position + dy + Vector2(0, BODY.size.y - 1), Vector2(BODY.size.x, 1)), Pal.BAKELITE[0])
	draw_rect(Rect2(Vector2(1, KEY_Y + KEY_H + 1) + dy, Vector2(BODY.size.x - 2, 1)), Pal.BAKELITE[1])   # o friso embaixo das teclas
	_draw_keys(dy, loaded, rec)
	_draw_door(dy, loaded, rec)
	_draw_meters(dy, rec)
	if _fly != Fly.NONE:
		var pose := _fly_pose()
		if not pose.is_empty() and not (_fly == Fly.IN and _door < 1.0 and _fly_t > 0.3):
			_draw_tape(pose[0], pose[1], _flying)


func _draw_keys(dy: Vector2, loaded: bool, rec: bool) -> void:
	draw_rect(Rect2(Vector2(_rec_key.position.x - 1, KEY_Y - 1) + dy, Vector2(BODY.end.x - _rec_key.position.x - 1, KEY_H + 2)), Pal.KEY_WELL)
	var all := [[_rec_key, rec, Pal.RED, ""]]
	for i in _keys.size():
		var down: bool = i == _pressed or (i == _hover and loaded)
		all.append([_keys[i][0], down, Pal.NICKEL[3], T.text(_keys[i][2])])
	for k: Array in all:
		var r: Rect2 = k[0]
		r.position += dy
		var sink := (2.0 if k[1] and k != all[0] or (k == all[0] and rec) else 0.0)
		if k != all[0] and k[1] and _pressed == -1:
			sink = 1.0   # sob o dedo, ainda sem apertar
		r.position.y += sink
		r.size.y -= sink
		draw_rect(r, Pal.BAKELITE[4] if sink < 2.0 else Pal.BAKELITE[3])
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), k[2] if sink < 2.0 else Color(k[2], 1.0).darkened(0.35))   # o alto da tecla
		if k[3] != "":
			draw_texture(PixelArt.tiny(k[3]), r.position + Vector2(2, -1), Pal.TEXT if loaded else Pal.DIM)
		else:
			draw_rect(Rect2(r.position + Vector2(4, 2), Vector2(3, 2)), Pal.RED.darkened(0.2 if rec else 0.5))   # o ponto vermelho do REC


func _draw_door(dy: Vector2, loaded: bool, rec: bool) -> void:
	var d := Rect2(DOOR.position + dy, DOOR.size)
	draw_rect(d.grow(1), Pal.BAKELITE[0])
	draw_rect(d, Pal.VOID)   # o vão atrás da porta
	if loaded:
		Cassette.face(self, SEAT + dy, Cassette.FACE.x, _label, _hour, _written(), _marks, _pop / POP_SEC, _fill(),
			PixelArt.ms() / SPIN_MS if rec else 0)
	if _door <= 0.0:   # fechada: o vidro com um reflexo
		draw_rect(Rect2(d.position + Vector2(d.size.x - 4, d.size.y - 9), Vector2(1, 6)), Pal.NICKEL[2])   # (embaixo, longe da etiqueta)
		draw_rect(Rect2(d.position + Vector2(d.size.x - 6, d.size.y - 6), Vector2(1, 3)), Pal.NICKEL[3])
		return
	# aberta: a porta tomba para a frente pela dobradiça de baixo, mostrando a face de dentro, mais curta e mais larga
	var h := roundf(lerpf(d.size.y, 5.0, minf(_door, 1.0))) - (2.0 if _door > 1.0 else 0.0)
	var r := Rect2(d.position.x - 1, d.end.y - h + (1.0 if _door > 0.5 else 0.0), d.size.x + 2, h)
	draw_rect(r, Pal.BAKELITE[3])
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Pal.BAKELITE[5])
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, maxf(r.size.y - 3, 1))), Pal.BAKELITE[1])


func _draw_meters(dy: Vector2, rec: bool) -> void:
	# o VU: a face creme, acesa por trás gravando, a escala e o ponteiro preto do pivô embaixo
	var v := Rect2(VU.position + dy, VU.size)
	draw_rect(v.grow(1), Pal.BAKELITE[0])
	draw_rect(v, Pal.GLOW.lerp(Pal.LABEL_PAPER, 0.4) if rec else Pal.LABEL_PAPER.darkened(0.35))
	if rec:
		Bloom.light(self, v, Pal.AMBER, 0.35, false)
	for i in 9:   # a escala em arco, a parte de cima em vermelho
		var a := lerpf(-0.9, 0.9, i / 8.0)
		var p := (v.position + Vector2(v.size.x / 2.0, v.size.y + 2.0) + Vector2(sin(a), -cos(a)) * (v.size.y - 2.0)).floor()
		draw_rect(Rect2(p, Vector2.ONE), Pal.RED if i >= 6 else Pal.INK_SOFT)
	var ang := lerpf(-0.95, 0.95, _needle)
	var pivot := v.position + Vector2(floorf(v.size.x / 2.0), v.size.y - 1)
	for s in int(v.size.y) - 3:   # o ponteiro, pixel a pixel
		var p := (pivot + Vector2(sin(ang), -cos(ang)) * s).round()
		if v.has_point(p):
			draw_rect(Rect2(p, Vector2.ONE), Pal.INK)
	draw_rect(Rect2(pivot + Vector2(-1, 0), Vector2(3, 1)), Pal.BAKELITE[1])
	# o contador: três rodinhas de números que rolam
	var c := Rect2(COUNTER.position + dy, COUNTER.size)
	draw_rect(c.grow(1), Pal.BAKELITE[0])
	draw_rect(c, Pal.VOID)
	var n := int(_rec_sec * 2.0)
	var frac := fmod(_rec_sec * 2.0, 1.0)
	for i in 3:
		var place := int(pow(10, 2 - i))
		var digit := (n / place) % 10
		var rolling := i == 2 or (n % place) == place - 1   # a da direita sempre; as outras na virada
		var off := roundf(smoothstep(0.7, 1.0, frac) * 6.0) if rolling and rec else 0.0
		var at := c.position + Vector2(1 + i * 4, -2 - off)   # (a fonte miúda tem 3 linhas em cima, para os acentos)
		_clipped(PixelArt.tiny(str(digit)), at, c)
		if off > 0.0:
			_clipped(PixelArt.tiny(str((digit + 1) % 10)), at + Vector2(0, 6), c)
	# a lâmpada REC
	var l := Rect2(LAMP.position + dy, LAMP.size)
	draw_rect(l, Pal.RED if rec else Pal.INK_RED.darkened(0.4))
	if rec:
		Bloom.light(self, l, Pal.RED, 0.6)
	draw_texture(PixelArt.tiny("REC"), l.position + Vector2(-4, 4), Pal.DIM)
	# o alto-falante
	for y in range(int(GRILLE.position.y), int(GRILLE.end.y), 2):
		for x in range(int(GRILLE.position.x) + (y / 2) % 2, int(GRILLE.end.x), 2):
			draw_rect(Rect2(Vector2(x, y) + dy, Vector2.ONE), Pal.BAKELITE[0])


## O pedaço da textura `tex` posta em `at` que cai dentro da janela `win` (as rodinhas do contador somem na moldura).
func _clipped(tex: Texture2D, at: Vector2, win: Rect2) -> void:
	var top := maxf(win.position.y - at.y, 0.0)
	var bottom := minf(win.end.y - at.y, tex.get_height())
	if bottom > top:
		draw_texture_rect_region(tex, Rect2(at.x, at.y + top, tex.get_width(), bottom - top), Rect2(0, top, tex.get_width(), bottom - top), Pal.TEXT)


## A caixa das autoridades: uma bandeja de aço aberta em cima, com o lacre vermelho na frente; as fitas entregues
## ficam em pé dentro dela.
func _draw_box() -> void:
	var dy := Vector2(0, 1) if _box_bounce > 0.0 else Vector2.ZERO
	draw_rect(Rect2(BOX.position.x + 1, BOX.end.y, BOX.size.x + 2, 1), Pal.SHELF_WOOD[0].darkened(0.5))
	Cassette.block(self, Rect2(BOX.position + dy, BOX.size), TOP, Pal.STEEL_TONES[1], Pal.STEEL_TONES[3], Pal.STEEL_TONES[2])
	draw_rect(Rect2(BOX.position + dy + Vector2(1, -2), Vector2(BOX.size.x - 2 + roundf(Cassette.LEAN), 2)), Pal.STEEL_DARK[1])   # a boca
	for i in _delivered:
		var at := BOX_SPOT + Vector2(i * BOX_PITCH, 0) + dy
		if _box_bounce > 0.0 and i % 2 == 0:
			at.y -= 1.0
		Cassette.spine(self, at)
	draw_rect(Rect2(BOX.position + dy, BOX.size), Pal.STEEL_TONES[3])   # a frente por cima das fitas
	draw_rect(Rect2(BOX.position + dy, Vector2(BOX.size.x, 1)), Pal.STEEL_TONES[5])
	draw_rect(Rect2(BOX.position + dy + Vector2(0, BOX.size.y - 1), Vector2(BOX.size.x, 1)), Pal.STEEL_TONES[1])
	var seal := BOX.position + dy + Vector2(BOX.size.x / 2.0 - 2, 3)   # o lacre de cera, redondo
	draw_rect(Rect2(seal + Vector2(1, 0), Vector2(3, 5)), Pal.SEAL)
	draw_rect(Rect2(seal + Vector2(0, 1), Vector2(5, 3)), Pal.SEAL)
	draw_rect(Rect2(seal + Vector2(1, 1), Vector2(1, 1)), Pal.CALENDAR_HEAD[1])
	draw_rect(Rect2(seal + Vector2(-5, 2), Vector2(5, 1)), Pal.PAPER_LINE)   # o barbante do lacre
	draw_rect(Rect2(seal + Vector2(5, 2), Vector2(5, 1)), Pal.PAPER_LINE)


func _draw_tape(at: Vector2, w: float, t: Dictionary) -> void:
	var px := roundi(lerpf(Cassette.SPINE_W, Cassette.FACE.x, w))
	Cassette.face(self, at.round(), px, t.get("label", ""), t.get("hour", ""), t.get("written", 0), t.get("marks", 0), 0.0, t.get("fill", 0.0))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_hover = _keys.find_custom(func(k): return (k[0] as Rect2).grow(1).has_point(e.position))
		return
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or b.pressed or _hover == -1:
		return
	_pressed = _hover
	_press_t = KEY_SEC
	Sfx.play_at("tape_key", _sx())
	if _desk.tapes.inside.is_empty():
		_desk.main.warn(T.text(T.Key.WARN_NO_TAPE))
	else:
		var deliver: bool = _keys[_hover][1]
		_desk.tapes.eject(deliver)
		_had_tape = false
		_start_out(deliver)
		Sfx.play_at("tape_pop", _sx(), -2.0)
	accept_event()
