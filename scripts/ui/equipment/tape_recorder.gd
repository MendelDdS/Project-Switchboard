extends Control
## O gravador de fitas (equipamento da B4, `Switchboard.set_equipment`), de pé no alto da coluna do lado do painel:
## plástico branco com a frente oliva, como a mesa. À esquerda, a fenda vertical com a fita encaixada, só a lombada à
## vista, na escala de verdade (`Cassette.standing`: o nome de quem é gravado e a hora escritos de lado, um risquinho
## por palavra-chave); sem fita, a fenda fica fechada por uma tampinha de mola, como a dos toca-fitas de carro, que a
## fita empurra para dentro ao entrar e que bate de volta quando ela sai (`_flap`); à direita, o VU com o ponteiro
## pulando com a voz, o contador, a lâmpada, o alto-falante e a tecla REC vermelha, que trava embaixo (`Tapes.rec`,
## `press_rec`, também pela tecla R, `rec_tape`): presa e com a escuta na conversa, em qualquer ordem, grava
## (`Tapes.recording`, a lâmpada acesa); acabada a conversa gravada, solta sozinha (`rule_tapes.call_ended`).
##
## Tudo se mexe com peso (`movimento-organico`): a fita sobe dentro do compartimento embaixo (desenhada por ele,
## `Rack.RISE_SEC`), vem para a frente por cima da beira dele, voa e entra na fenda, e o gravador e o compartimento
## pulam. Sob o mouse, a fita na fenda mostra o que o clique faz (`TapedLabel`): virgem, volta para um lugar vazio do
## compartimento (`Tapes.put_back`, o caminho de ida ao contrário); gravada, pula da fenda (a REC volta) e voa para a
## mesa, ao lado do bloco de fichas, onde fica empilhada com as outras até o fim do turno (`Tapes.eject`,
## `Background.tapes_out`, `tape_spot`; o descarte é na pilha, `tape_pile.gd`). A lógica acontece no clique; a animação
## só mostra (`_fly`).

const Cassette := preload("res://scripts/ui/equipment/cassette.gd")
const Rack := preload("res://scripts/ui/equipment/tape_rack.gd")
const SLOT := Rect2(5, 5, 14, 102)   ## a fenda, com o aro escuro
const SEAT := Vector2(6, 6)   ## o canto da fita encaixada
const VU := Rect2(23, 6, 21, 13)
const COUNTER := Rect2(47, 6, 13, 7)
const LAMP := Rect2(52, 16, 3, 3)   ## a lâmpada de gravando, embaixo do contador
const GRILLE := Rect2(23, 26, 38, 56)   ## o alto-falante, furadinho
const REC_KEY := Rect2(23, 90, 37, 10)   ## (largura ímpar como o texto: as letras no meio exato)
const WRITE_SEC := 0.07   ## cada letra da etiqueta
const POP_SEC := 0.25   ## o risquinho novo, maior
const BOUNCE_SEC := 0.08   ## o gravador afundando 1 px quando a fita bate
const KEY_SEC := 0.18   ## a tecla apertada antes de voltar
const FLAP_PUSH := 0.08   ## a tampinha empurrada pela fita entrando (o último trecho do voo)
const FLAP_AT := 0.13   ## saindo, a fita deixa a fenda (o primeiro trecho) e a tampinha volta...
const FLAP_SEC := 0.05   ## ...de mola, rápido
const BLINK_MS := 500   ## a lâmpada piscando devagar com a fita cheia (meio segundo apagada, meio acesa)
const FRONT_SEC := 0.06   ## a fita vindo para a frente, por cima da beira do compartimento (um pouco para baixo e para a esquerda: perto do olho)

## As animações da fita (`_fly`): o caminho é feito de trechos, cada um com a duração, de onde a onde, o tamanho (1 em
## pé, inteira; 0 deitada na mesa, `Background.tape_spot`) e a curva.
enum Fly { NONE, IN, DELIVER, BACK }
enum Hover { NONE, KEY, TAPE }

var _hover := Hover.NONE
var _press_t := 0.0   ## a tecla apertada sem fita, afundada antes de voltar (`KEY_SEC`)
var _rec_sec := 0.0   ## o tempo gravado na fita de agora (o contador)
var _bound: PhoneCall   ## a conversa na fita de agora (mudou: a etiqueta é escrita de novo)
var _label := ""
var _hour := ""   ## a hora em que ela começou a gravar, escrita depois do nome
var _write_t := 0.0
var _marks := 0
var _wrong := false   ## a conversa gravada não é a pedida (a faixa da etiqueta riscada, `Cassette.standing`)
var _blink := false   ## a lâmpada apagada no pisca da fita cheia (`Tapes.full`: escutar mais só arrisca)
var _pop := 0.0
var _needle := 0.0   ## o ponteiro do VU, de 0 (parado) a 1 (no vermelho)
var _needle_v := 0.0
var _bounce := 0.0
var _flap := 0.0   ## a tampinha da fenda: 0 fechada, 1 empurrada para dentro
var _fly := Fly.NONE
var _fly_t := 0.0
var _flying := {}   ## a fita voando: {"from", "label", "hour", "written", "marks", "spot" (na mesa, Rect2)}
var _had_tape := false
var _latched := false   ## a REC presa no último quadro (soltou sozinha: o estalo dela)
var _drawn := []

@onready var _desk := Bureaucracy.of(self)   ## o gerente (procurado uma vez: subir a árvore a cada quadro pesa)


func _ready() -> void:
	mouse_exited.connect(func(): _hover = Hover.NONE)


## A tecla R aperta a REC (como o Z, a escuta; com um campo de texto em foco, a tecla fica com ele).
func _input(e: InputEvent) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if e.is_action_pressed("rec_tape") and not (focus is LineEdit or focus is TextEdit):
		get_viewport().set_input_as_handled()
		_press_rec()


func _process(delta: float) -> void:
	var tp = _desk.tapes if _desk else null
	if tp == null:
		return
	var loaded: bool = tp.inside != null
	var rec: bool = tp.recording()
	if loaded and not _had_tape:   # uma fita entrou: vem do compartimento, do lugar dela
		_start_in(tp.inside.slot)
	_had_tape = loaded
	if _latched and not tp.rec:
		Sfx.play_at("click", _sx(), -4.0)   # a REC volta (soltada, sozinha no fim da conversa ou com a fita saindo)
	_latched = tp.rec
	if rec:
		_rec_sec += delta
	var c: PhoneCall = tp.inside.call if loaded else null
	if c != _bound:
		_bound = c
		_label = Cassette.label_of(c) if c != null else ""
		_hour = tp.inside.hour if c != null else ""
		_write_t = 0.0
		if c != null:
			Sfx.play_at("pencil", _sx(), -6.0)
	_write_t += delta
	var marks: int = tp.inside.words.size() if loaded else 0
	if marks > _marks:
		_pop = POP_SEC
		Sfx.play_at("pencil", _sx(), -10.0, 1.4)
	_marks = marks
	_wrong = c != null and not tp.inside.marked
	_blink = rec and tp.full(tp.inside) and int(PixelArt.ms() / BLINK_MS) % 2 == 1
	_pop = maxf(_pop - delta, 0.0)
	_press_t = maxf(_press_t - delta, 0.0)
	_bounce = maxf(_bounce - delta, 0.0)
	_step_needle(delta, rec and c != null and _desk.main.eavesdrop.speaking(c.line))
	if _fly != Fly.NONE:
		_step_fly(delta)
	else:
		_flap = 1.0 if loaded else 0.0
	# as tiradas ficam na mesa (a que voa, só quando chega)
	_desk.main.background.tapes_out = tp.on_desk().size() - (1 if _fly == Fly.DELIVER else 0)
	var shown := [_hover, loaded, rec, tp.rec, int(_rec_sec * 2.0), roundi(_needle * 12.0), _written(), _marks, _pop > 0.0, _press_t > 0.0,
		_bounce > 0.0, _wrong, _blink, _fly, int(_fly_t * 60.0), roundi(_flap * 12.0)]
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
	return mini(int(_write_t / WRITE_SEC), _label.length() + 1 + _hour.length()) if _label != "" else 0


func _sx() -> float:
	return global_position.x / get_viewport().get_visible_rect().size.x


# ---- a fita voando

func _start_in(slot: int) -> void:
	var rack := get_tree().get_first_node_in_group(&"tape_rack") as Control
	_rec_sec = 0.0
	_fly = Fly.IN
	_fly_t = 0.0
	_flying = {"from": (rack.slot_pos(slot) - global_position) if rack else SEAT + Vector2(0, 110)}


## A virgem voltando para o lugar `slot` do compartimento (reservado nele, `hold`).
func _start_back(slot: int) -> void:
	var rack := get_tree().get_first_node_in_group(&"tape_rack") as Control
	rack.hold = slot
	_fly = Fly.BACK
	_fly_t = 0.0
	_flying = {"from": SEAT, "slot": slot, "to": rack.slot_pos(slot) - global_position}
	_bound = null
	_rec_sec = 0.0


func _start_out() -> void:
	var spot: Rect2 = _desk.main.background.tape_spot()
	_flying = {"from": SEAT, "label": _label, "hour": _hour, "written": _written(), "marks": _marks, "wrong": _wrong,
		"spot": Rect2(spot.position - global_position, spot.size)}
	_fly = Fly.DELIVER
	_fly_t = 0.0
	_bound = null
	_label = ""
	_hour = ""
	_marks = 0
	_rec_sec = 0.0


## Os trechos de cada voo: [segundos, até onde (o canto da fita), tamanho no fim (1 em pé, 0 na mesa), curva].
## Curvas: "in" acelera (entra, cai), "out" freia (pula, sobe), "arc" anda reto e sobe e desce no meio, "rack" sobe
## dentro do compartimento, desenhada por ele (atrás da beira dele).
func _legs() -> Array:
	var from: Vector2 = _flying["from"]
	match _fly:
		Fly.IN:
			var lifted := from + Vector2(0, -Rack.RISE_PX)
			return [[Rack.RISE_SEC, lifted, 1.0, "rack"], [FRONT_SEC, lifted + Vector2(-1, 1), 1.0, "out"],
				[0.3, SEAT + Vector2(0, -4), 1.0, "arc"], [0.08, SEAT, 1.0, "in"]]
		Fly.DELIVER:
			return [[0.13, SEAT + Vector2(0, -14), 1.0, "out"], [0.32, (_flying["spot"] as Rect2).position, 0.0, "arc"]]
		Fly.BACK:   # (o compartimento afunda ela no lugar, `land`)
			var lifted: Vector2 = _flying["to"] + Vector2(0, -Rack.RISE_PX)
			return [[0.13, SEAT + Vector2(0, -14), 1.0, "out"], [0.3, lifted + Vector2(-1, 1), 1.0, "arc"], [FRONT_SEC, lifted, 1.0, "in"]]
	return []


## O ponto do voo agora: [canto, tamanho (0 a 1), desenhada aqui?]; nulo, acabou.
func _fly_pose() -> Array:
	var at: Vector2 = _flying["from"]
	var k := 1.0
	var t := _fly_t
	for leg: Array in _legs():
		var f := t / float(leg[0])
		if f < 1.0:
			var to: Vector2 = leg[1]
			match leg[3]:
				"in":
					at = at.lerp(to, f * f)
				"out", "rack":
					at = at.lerp(to, 1.0 - (1.0 - f) * (1.0 - f))
				"arc":
					at = at.lerp(to, smoothstep(0.0, 1.0, f)) + Vector2(0, -10.0 * sin(PI * f))
			return [at, lerpf(k, float(leg[2]), smoothstep(0.0, 1.0, f)), leg[3] != "rack"]
		t -= float(leg[0])
		at = leg[1]
		k = leg[2]
	return []


func _step_fly(delta: float) -> void:
	var before := _fly_t
	_fly_t += delta
	var total := 0.0
	for leg: Array in _legs():
		total += float(leg[0])
	var landed := before < total and _fly_t >= total
	if _fly == Fly.IN:
		_flap = clampf((_fly_t - (total - FLAP_PUSH)) / FLAP_PUSH, 0.0, 1.0)
	else:
		var was := _flap
		_flap = 1.0 if _fly_t < FLAP_AT else maxf(1.0 - (_fly_t - FLAP_AT) / FLAP_SEC, 0.0)
		if was > 0.0 and _flap == 0.0:
			Sfx.play_at("tape_door", _sx(), -4.0)   # a tampinha batendo
	match _fly:
		Fly.IN:
			if landed:   # entrou na fenda: o gravador afunda e as fitas embaixo pulam
				_bounce = BOUNCE_SEC
				Sfx.play_at("tape_in", _sx())
				var rack := get_tree().get_first_node_in_group(&"tape_rack")
				if rack:
					rack.bump()
		Fly.DELIVER:
			if landed:
				Sfx.play_at("drop", (global_position.x + (_flying["spot"] as Rect2).position.x) / get_viewport_rect().size.x)
		Fly.BACK:
			if landed:   # de volta no lugar dela
				Sfx.play_at("tape_out", _sx(), -2.0)
				var rack := get_tree().get_first_node_in_group(&"tape_rack")
				if rack:
					rack.land(_flying["slot"])
	if _fly_t >= total:
		_fly = Fly.NONE


# ---- desenho

func _draw() -> void:
	Bloom.clear(self)
	var tp = _desk.tapes if _desk else null
	var loaded: bool = tp != null and tp.inside != null and _fly != Fly.IN
	var rec: bool = tp != null and tp.recording()
	var dy := Vector2(0, 1) if _bounce > 0.0 else Vector2.ZERO
	Switchboard.round_rect(self, Rect2(dy, size), Pal.SHELL[5])   # plástico branco, como o móvel da mesa
	draw_rect(Rect2(Vector2(2, 0) + dy, Vector2(size.x - 4, 1)), Pal.SHELL[7])   # a quina de cima, na luz
	draw_rect(Rect2(Vector2(2, size.y - 1) + dy, Vector2(size.x - 4, 1)), Pal.SHELL[2])
	Switchboard.round_rect(self, Rect2(Vector2(2, 2) + dy, size - Vector2(4, 4)), Pal.BOARD_FACE)   # a frente oliva, como o painel
	var s := Rect2(SLOT.position + dy, SLOT.size)
	draw_rect(s, Pal.BOARD_INSET)
	draw_rect(s.grow(-1), Pal.VOID)
	if loaded:   # sob o mouse, pronta para sair: sobe 1 px
		Cassette.standing(self, SEAT + dy - Vector2(0, 1 if _hover == Hover.TAPE else 0), _label, _hour, _written(), _marks, _pop > 0.0, _wrong)
	else:
		_draw_flap(dy)
	_draw_meters(dy, rec)
	_draw_key(dy, tp != null and tp.rec, rec and not _blink)
	if _fly != Fly.NONE:
		var pose := _fly_pose()
		if not pose.is_empty() and pose[2]:
			_draw_tape(pose[0], pose[1])
	if _hover == Hover.TAPE and loaded:
		_draw_tip(T.text(T.Key.TAPE_RETURN if tp.inside.call == null else T.Key.TAPE_TAKE))


## O que o clique na fita faz, numa etiqueta de fita crepe como a dos objetos da mesa (`Background.draw_hover`), à
## esquerda da fenda, na frente do painel (acima, invadia a borda dele e a placa da companhia).
func _draw_tip(cap: String) -> void:
	var tape := get_theme_stylebox("normal", "TapedLabel")
	var ts := (Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11) + tape.get_minimum_size()).round()
	var at := Vector2(-8.0 - ts.x, SLOT.position.y + 6.0)   # (fora da moldura da coluna)
	tape.draw(get_canvas_item(), Rect2(at, ts))
	draw_string(Pal.ui, at + Vector2(tape.content_margin_left, tape.content_margin_top + Pal.ui.get_ascent(11)), cap,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, get_theme_color("default_color", "TapedLabel"))


## A tampinha da fenda: plástico escuro, presa pela beira da esquerda; empurrada, gira para dentro e, de frente, vai
## estreitando até sumir (`_flap`).
func _draw_flap(dy: Vector2) -> void:
	var w := roundf(Cassette.SPINE.x * (1.0 - _flap))
	if w <= 0.0:
		return
	var r := Rect2(SEAT + dy, Vector2(w, Cassette.SPINE.y))
	draw_rect(r, Pal.BAKELITE[2])
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Pal.BAKELITE[4])   # a beira da dobradiça, na luz
	draw_rect(Rect2(r.position, Vector2(w, 1)), Pal.BAKELITE[4])
	if w > 2.0:
		draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), Pal.BAKELITE[0])   # a beira solta, na sombra


## A tecla REC: vermelha, com o nome no meio; presa (`latched`), fica afundada; sob o dedo, desce 1 px. Ao lado do
## contador, a lâmpada, acesa enquanto grava (`rec`).
func _draw_key(dy: Vector2, latched: bool, rec: bool) -> void:
	var r := Rect2(REC_KEY.position + dy, REC_KEY.size)
	draw_rect(r.grow(1), Pal.KEY_WELL)
	var sink := 2.0 if latched or _press_t > 0.0 else (1.0 if _hover == Hover.KEY else 0.0)
	r.position.y += sink
	r.size.y -= sink
	var down := sink >= 2.0
	draw_rect(r, Pal.REC_CAP[1] if down else Pal.REC_CAP[2])
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Pal.REC_CAP[2] if down else Pal.REC_CAP[3])   # o alto da tecla
	var t := PixelArt.tiny("REC")
	var top := floorf((r.size.y - 1.0 - 5.0) / 2.0) + 1.0   # (as maiúsculas, 5 linhas, no meio da frente, abaixo do alto)
	draw_texture(t, r.position + Vector2(floorf((r.size.x - t.get_width()) / 2.0), top - 3.0), Pal.BOARD_INK)
	var l := Rect2(LAMP.position + dy, LAMP.size)
	draw_rect(l.grow(1), Pal.BOARD_INSET)
	draw_rect(l, Pal.RED if rec else Pal.INK_RED.darkened(0.4))
	if rec:
		Bloom.light(self, l, Pal.RED, 0.6)


func _draw_meters(dy: Vector2, rec: bool) -> void:
	# o VU: a face creme, acesa por trás gravando, a escala e o ponteiro preto do pivô embaixo
	var v := Rect2(VU.position + dy, VU.size)
	draw_rect(v.grow(1), Pal.BOARD_INSET)
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
	draw_rect(c.grow(1), Pal.BOARD_INSET)
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
	# o alto-falante
	for y in range(int(GRILLE.position.y), int(GRILLE.end.y), 2):
		for x in range(int(GRILLE.position.x) + (y / 2) % 2, int(GRILLE.end.x), 2):
			draw_rect(Rect2(Vector2(x, y) + dy, Vector2.ONE), Pal.BOARD_INSET)


## O pedaço da textura `tex` posta em `at` que cai dentro da janela `win` (as rodinhas do contador somem na moldura).
func _clipped(tex: Texture2D, at: Vector2, win: Rect2) -> void:
	var top := maxf(win.position.y - at.y, 0.0)
	var bottom := minf(win.end.y - at.y, tex.get_height())
	if bottom > top:
		draw_texture_rect_region(tex, Rect2(at.x, at.y + top, tex.get_width(), bottom - top), Rect2(0, top, tex.get_width(), bottom - top), Pal.TEXT)


## A fita voando: em pé, com a etiqueta; indo para a mesa, no meio do caminho (`k` 0,5) tomba de lado, girada 90°
## pelo meio dela, e daí encolhe até o tamanho dela lá (`Background.tape_spot`), chegando no canto de lá.
func _draw_tape(at: Vector2, k: float) -> void:
	if k > 0.5:
		Cassette.standing(self, at.round(), _flying.get("label", ""), _flying.get("hour", ""), _flying.get("written", 0), _flying.get("marks", 0), false, _flying.get("wrong", false))
		return
	var stand := Vector2(Cassette.SPINE)
	var turned := Vector2(stand.y, stand.x)
	var t := 1.0 - k * 2.0   # 0 ao tombar, 1 na mesa
	var sz := turned.lerp((_flying["spot"] as Rect2).size, t)
	Cassette.block(self, Rect2((at + (stand - turned) / 2.0 * (1.0 - t)).round(), sz.round()))


func _gui_input(e: InputEvent) -> void:
	var tp = _desk.tapes
	if e is InputEventMouseMotion:
		_hover = Hover.KEY if REC_KEY.grow(1).has_point(e.position) else (
			Hover.TAPE if SLOT.has_point(e.position) and tp.inside != null and _fly == Fly.NONE else Hover.NONE)
		mouse_default_cursor_shape = CURSOR_ARROW if _hover == Hover.NONE else CURSOR_POINTING_HAND
		return
	var b := e as InputEventMouseButton
	if b == null or b.button_index != MOUSE_BUTTON_LEFT or b.pressed or _hover == Hover.NONE:
		return
	if _hover == Hover.TAPE:
		_take_out()
	else:
		_press_rec()
	accept_event()


## A fita clicada sai da fenda: virgem, volta para o compartimento (se houver lugar); gravada, vai para a mesa.
func _take_out() -> void:
	var tp = _desk.tapes
	var slot: int = tp.put_back()
	_hover = Hover.NONE
	_had_tape = false
	if slot >= 0:
		_start_back(slot)
	else:
		tp.eject()
		_start_out()
	Sfx.play_at("tape_pop", _sx(), -2.0)


## A tecla REC: trava ou solta; sem fita, desce e volta com o aviso.
func _press_rec() -> void:
	var tp = _desk.tapes
	if tp.press_rec():
		if tp.rec:
			Sfx.play_at("tape_key", _sx())   # (a volta tem o estalo dela, no `_process`)
	else:
		_press_t = KEY_SEC
		Sfx.play_at("tape_key", _sx())
		_desk.main.warn(T.text(T.Key.WARN_NO_TAPE))
