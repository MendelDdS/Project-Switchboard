class_name Toll
extends VBoxContainer
## O calculógrafo da mesa visto de perto (a ferramenta `Tools.TOLL`, aberta pelo objeto dele na mesa): a máquina que
## conta as ligações interurbanas e imprime os bilhetes de tarifação e, embaixo, o tampo da mesa (`%Desk`) com a
## almofada de tinta, a caixinha dos bilhetes e, soltos, os bilhetes e o carimbo. Começa a contar sozinho quando a
## telefonista de lá completa a ligação (`start`) e, quando a conversa acaba (a linha sai de conectada,
## `Main._update_line_timers`), imprime o bilhete (`stop`, um `TollTicket`), que cai na mesa logo embaixo da fenda
## (com a ferramenta aberta, ele sai da fenda no tempo da impressora e cai, `_emerge`).
## Bilhetes e carimbo andam livres pela mesa e ficam onde são soltos (`_on_desk_input`: pegar, levar e soltar; na mão
## sobem e, soltos, caem, como o cartão do despacho, `Lift`); o carimbo posto em cima de um bilhete e clicado é
## apertado e o carimba, embaixo do meio da janela da sapata, quando os tipos encostam no papel (`_stamp_down`, `_touch`; a borracha seca a cada batida, `INK`, e volta a
## marcar apertada na almofada), e o bilhete solto na caixinha (o mouse em cima dela) é guardado (`file`) e desce para dentro dela (`_sink`); sem o
## carimbo, o supervisor anota (`unstamped`).

signal unstamped(t: TollTicket)

const NOMINAL := Vector2(632, 354)   ## a mesa dela no jogo (1280 × 720): a do calculógrafo da sala tem esta proporção (`layout`)
const PAD := Vector2(150, 44)   ## a almofada de tinta, embaixo à esquerda da mesa...
const BOX := Vector2(220, 92)   ## ...e a caixinha dos bilhetes, embaixo à direita, na mesma linha
## A folga da almofada e da caixinha até a beira dos lados e até a de baixo, a mesma nas duas. Encostadas nos cantos, na
## sala elas passavam dos lados da máquina (perto, a mesinha abre mais que ela) e o calculógrafo parecia torto.
const INSET := Vector2(48, 12)
const BOX_MOUTH := 30.0         ## da beira de trás da caixinha até a frente dela: a boca, onde o bilhete entra e some
const SINK_SEC := 0.3           ## o bilhete descendo para dentro da caixinha
const OUT_SEC := 0.45           ## o bilhete que esperava na fenda saindo dela quando a ferramenta abre
const LID := 22.0               ## a tampa da almofada, aberta, de pé atrás dela
const WET_SEC := 2.5            ## carimbada, a almofada perde o brilho da tinta no feltro e o recupera nesse tempo
const PLANK := 56.0             ## a largura das tábuas do tampo
const EDGE_H := 14.0            ## a borda da frente do tampo, embaixo do papel
## Os contadores do visor, um por entrada (`Exchange.LINES`), em duas fileiras de `COUNTER_COLS`: tambores de algarismos
## claros (`DIGITS`, 5 × 9 px), deste tamanho, que rolam para o algarismo seguinte na primeira fração `ROLL` de cada
## minuto começado.
const COUNTER_COLS := 5
const DRUMS := 3
const DRUM := Vector2(7, 13)
const ROLL := 0.2
const DIGITS := [".###./#...#/#...#/#...#/#...#/#...#/#...#/#...#/.###.", "..#../.##../#.#../..#../..#../..#../..#../..#../#####",
	".###./#...#/....#/....#/...#./..#../.#.../#..../#####", ".###./#...#/....#/....#/..##./....#/....#/#...#/.###.",
	"...#./..##./.#.#./#..#./#..#./#####/...#./...#./...#.", "#####/#..../#..../####./....#/....#/....#/#...#/.###.",
	".###./#...#/#..../#..../####./#...#/#...#/#...#/.###.", "#####/....#/....#/...#./...#./..#../..#../..#../..#..",
	".###./#...#/#...#/#...#/.###./#...#/#...#/#...#/.###.", ".###./#...#/#...#/#...#/.####/....#/....#/#...#/.###."]
## O carimbo visto de cima, inclinado, como da cadeira (o nó), no modelo do numerador automático de escritório (a
## referência do usuário): o cabo de baquelite preta em cogumelo, a haste cromada e o anel (`_knob`); o corpo de níquel,
## com o tampo à vista, a frente e a plaqueta; embaixo dele, o eixo com as pontas, as rodas de algarismos de latão e a
## seletor; e a armação parada: as pernas com os parafusos e a sapata, vista de cima, com a janela da borracha, por onde
## se vê onde ele vai carimbar. Apertado, tudo desce pelas pernas, menos a armação.
const STAMP := Vector2(88, 201)
const STAMP_TOP := Rect2(3, 69, 82, 23)      ## o tampo do corpo, com o anel da haste...
const STAMP_FRONT := Rect2(3, 92, 82, 35)    ## ...e a frente, com a plaqueta
const KNOB_AT := Vector2(20, 0)              ## o canto do cabo (`_knob`): o anel assenta no tampo
const KNOB := Vector2i(48, 82)
const KNOB_BASE := 76                        ## a linha do meio do anel, no cabo
const SQUASH := 0.38                         ## um círculo deitado, visto daqui: a altura dele pela largura
const LEG := 8.0                             ## a largura das pernas, que descem até o fundo da sapata, com a janela entre elas
const BASE := Rect2(4, 156, 80, 44)          ## a sapata, vista de cima...
const WINDOW := Rect2(12, 161, 64, 34)       ## ...e a janela dela, do tamanho da marca (`TollTicket.MARK_SIZE`)
const RUBBER_MID := Vector2(44, 178)         ## o meio da janela: onde ele carimba
const FOOT := Rect2(0, 127, 88, 74)          ## a armação na mesa: fica dentro dela (`_inside`); o resto pode passar por cima da máquina
const SELECTOR := Rect2(26, 140, 36, 10)     ## o seletor, entre as pernas: a plaqueta de latão com os riscos gravados e a alavanca serrilhada
const BRAND := "NUMEX"                       ## o fabricante (inventado), no medalhão de latão do tampo do cabo
const GLINT := Color("d9a35f")               ## o reflexo quente da luminária no cromado e na baquelite, do lado da luz
const SHADOW_NEAR := Vector2(1, 2)           ## a sombra curta e escura da armação encostada na mesa (some na mão)...
const SHADOW_NEAR_A := 0.3
const SHADOW_FAR_A := 0.22                   ## ...e a longa e fraca de tudo (`Lift.shadow`)
## As faixas de um cilindro na luz da esquerda (o cabo, a haste e o anel), de uma beira à outra: até onde vai cada uma
## (`BAND_U`, na largura) e o tom dela (`BANDS`, de 0, a sombra, a 4, o brilho).
const BAND_U := [0.07, 0.2, 0.3, 0.45, 0.62, 0.85, 0.95, 2.0]
const BANDS := [2, 3, 4, 3, 2, 1, 0, 1]
const DRY := Color("3a302a")    ## a borracha sem tinta
const INK := 2                  ## batidas depois de passar na almofada: a primeira cheia, a outra mais fraca; depois, seca
const PRESS := 57.0       ## clicado, cabo, corpo e rodas descem pelas pernas até as rodas encostarem no fundo da janela, tampando-a (px)...
const PRESS_DOWN := 0.07  ## ...acelerando, nesse tempo; batem (`_touch`), ficam no papel...
const PRESS_HOLD := 0.06
const PRESS_SEC := 0.3    ## ...e voltam, freando: o aperto inteiro
const SHAKE_SEC := 0.16   ## a batida sacode a mesa: o que está nela pula e assenta
const SHAKE_PX := 2.0

var filed := 0   ## bilhetes na caixinha
var night := 1   ## a noite do turno (`Main`): a data nas rodas do carimbo
## O minuto do turno (o Main atualiza a cada quadro): os minutos de quem está falando (o visor só se redesenha quando um
## tambor rola).
var now := 0.0:
	set(v):
		if is_node_ready() and (_rolling(v) or _rolling(now)):
			_machine.queue_redraw()
		now = v
var _meters := {}   # entrada -> [cidade, número de lá, minuto em que a outra ponta atendeu, número do bilhete]: contando
var _serial := 0
var _tickets: Array[TollTicket] = []   # na mesa, esperando a caixinha
var _fresh: Array[TollTicket] = []     # impressos com a ferramenta fechada: esperam na fenda (na sala, a ponta de pé) e saem quando ela abre
var _held: Control = null   # na mão: um bilhete ou o carimbo
var _grab := Vector2.ZERO   # onde ele foi pego (coordenadas dele)
var _placed := false        # o carimbo já está na mesa (começa na almofada)
var _stamp_lift := Lift.new()
var _ink := INK      # batidas com tinta que a borracha ainda tem
var _press := Vector2.INF   # onde o carimbo foi apertado: andando `CardMachines.DRAG_START` px, vira arraste; solto antes, é clique
var _thud := false   # o carimbo foi solto: faz barulho quando chegar na mesa
var _pressing := 0.0 # o que falta do aperto (s)
var _shake := 0.0    # o que falta da mesa sacudindo (s)
var _desk_at := Vector2.ZERO   # onde a mesa fica parada (a do contêiner)
var _filed: Array[bool] = []   # os bilhetes na caixinha (carimbado ou não), na ordem em que entraram
## O brilho da tinta no feltro da almofada (1 molhado; carimbada, cai a 0 e volta, `WET_SEC`).
var _wet := 1.0:
	set(v):
		_wet = v
		if is_node_ready():
			_desk.queue_redraw()
var _wet_tween: Tween
static var _strip: ImageTexture   # os algarismos dos tambores, um embaixo do outro (`_drum_strip`)
static var _felts := {}           # tamanho -> o feltro da almofada (`_felt`)
static var _knob_tex: ImageTexture   # o cabo do carimbo (`_knob`)

@onready var _machine: Control = %Machine
@onready var _desk: Control = %Desk
@onready var _stamp: Control = %Stamp


func _ready() -> void:
	_machine.draw.connect(_draw_machine)
	_desk.draw.connect(_draw_desk)
	_stamp.draw.connect(_draw_stamp)
	_desk.gui_input.connect(_on_desk_input)
	_desk.resized.connect(_arrange)
	_stamp.size = STAMP
	set_process(false)   # só enquanto o carimbo sobe, cai ou é apertado


## O tampo da mesa por baixo de tudo, até a beira do papel (a borda dele, do tema): as tábuas de um lado ao outro, com
## as emendas e os veios, e embaixo a borda da frente, de frente, com a quina arredondada na luz; os da mesa da sala
## (`Pal.DESK_GRAIN`, `Pal.DESK_EDGE`).
func _draw() -> void:
	var paper := get_parent_control()
	if paper == null:
		return
	var r := Rect2(-position + Vector2(2, 2), paper.size - Vector2(4, 4))
	var edge := r.end.y - EDGE_H
	for k in int(ceilf((edge - r.position.y) / PLANK)):
		var y0 := r.position.y + k * PLANK
		var y1 := minf(y0 + PLANK, edge)
		draw_rect(Rect2(r.position.x, y0, r.size.x, 1), Pal.DESK_GRAIN[1])   # a beira da tábua, na luz...
		draw_rect(Rect2(r.position.x, y1 - 1.0, r.size.x, 1), Pal.DESK_GRAIN[0])   # ...e a emenda
		for i in int(r.size.x / 60.0):
			var gx := r.position.x + fmod(i * 197.0 + k * 61.0, r.size.x - 40.0)
			var gy := roundf(y0 + (y1 - y0) * (0.25 + 0.5 * ((i * 7 + k) % 5) / 4.0))
			var gl := 24.0 + (i % 4) * 12.0
			draw_rect(Rect2(gx, gy, minf(gl, r.end.x - gx), 1), Pal.DESK_GRAIN[2])
			draw_rect(Rect2(gx + roundf(gl * 0.3), gy + 1.0, roundf(gl * 0.5), 1), Pal.DESK_GRAIN[3])
	for row: Array in [[0, 1, 0], [1, 1, 1], [2, 2, 2], [4, 8, 3], [6, 1, 4]]:   # [de, altura, cor]: a quina, a espessura e o friso
		draw_rect(Rect2(r.position.x, edge + row[0], r.size.x, row[1]), Pal.DESK_EDGE[row[2]])
	draw_rect(Rect2(r.position.x, edge + 12.0, r.size.x, 2), Pal.DESK_GRAIN[0])


## O carimbo subindo ou caindo (chegando na mesa, o som), o aperto (no fim da descida, a batida, `_touch`) e a mesa
## sacudindo com ela.
func _process(delta: float) -> void:
	var moving := _stamp_lift.step(delta)
	if not moving and _thud:
		_thud = false
		Sfx.play("drop")
	var was := _pressing
	_pressing = maxf(_pressing - delta, 0.0)
	if was > PRESS_SEC - PRESS_DOWN and _pressing <= PRESS_SEC - PRESS_DOWN:
		_touch()
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		var k := _shake / SHAKE_SEC
		_desk.position = _desk_at + Vector2(0, roundf(SHAKE_PX * k * cos(TAU * 2.0 * (1.0 - k))))
	if not moving and _pressing == 0.0 and _shake == 0.0:
		set_process(false)
	_stamp.scale = _stamp_lift.scale()
	_stamp.queue_redraw()


## A outra ponta atendeu o interurbano da entrada `line` (para a cidade `city`, o número `far` de lá) no minuto `at`.
## O número do bilhete já fica reservado (`ticket_of`, para o caderno).
func start(line: int, city: String, far: String, at: float) -> void:
	_serial += 1
	_meters[line] = [city, far, at, _serial]
	_machine.queue_redraw()


## O número do bilhete do interurbano contando na entrada `line` (0 = nenhum).
func ticket_of(line: int) -> int:
	return int(_meters[line][3]) if _meters.has(line) else 0


func counting(line: int) -> bool:
	return _meters.has(line)


## Há interurbano sendo contado (a luz âmbar do calculógrafo da mesa).
func metering() -> bool:
	return not _meters.is_empty()


## A conversa da entrada `line` acabou no minuto `at`: o bilhete sai impresso e cai na mesa.
func stop(line: int, at: float) -> TollTicket:
	var m: Array = _meters[line]
	_meters.erase(line)
	var t := TollTicket.new()
	t.serial = m[3]
	t.night = night
	t.line = line
	t.city = m[0]
	t.far = m[1]
	t.start = m[2]
	t.end = at
	_tickets.append(t)
	_desk.add_child(t)
	if is_visible_in_tree() and _placed:
		_emerge(t, Background.TIP_SEC)
	else:
		_fresh.append(t)
	_machine.queue_redraw()
	return t


## Os bilhetes impressos ainda na mesa, esperando ir para a caixinha.
func tickets() -> Array[TollTicket]:
	return _tickets


## Quantos bilhetes esperam a caixinha.
func waiting() -> int:
	return _tickets.size()


## Quantos esperam na fenda, impressos com a ferramenta fechada (no calculógrafo da sala, a ponta saindo dela).
func in_slot() -> int:
	return _fresh.size()


## As entradas contando, um bit cada (`1 << entrada`): os contadores acesos no calculógrafo da sala.
func counters() -> int:
	var bits := 0
	for line: int in _meters:
		bits |= 1 << line
	return bits


## A mesa dela para o calculógrafo da sala, em frações dela (0 a 1; em y, da máquina para a frente): a almofada, a
## caixinha, quantos bilhetes há nela, a sapata do carimbo e os bilhetes soltos, na ordem em que estão empilhados, cada
## um [onde está, as marcas do carimbo (o meio em frações dele e a tinta)]. Antes de ela abrir pela primeira vez, a
## mesa ainda não tem tamanho: a de `NOMINAL`, com o carimbo na almofada.
func layout() -> Array:
	var s := _desk.size if _placed else NOMINAL
	var frac := func(r: Rect2) -> Rect2: return Rect2(r.position / s, r.size / s)
	var shoe := Rect2(_stamp.position + BASE.position, BASE.size) if _placed else Rect2(_pad(s).get_center() - BASE.size / 2.0, BASE.size)
	var out := [frac.call(_pad(s)), frac.call(_box(s)), _filed.size(), frac.call(shoe)]
	for c in _desk.get_children():
		var t := c as TollTicket
		if t and t in _tickets and t not in _fresh and not t.clip_contents:   # (não o que espera na fenda, sai dela ou desce para a caixinha)
			var marks := []
			for m: Vector3 in t.marks:
				marks.append(Vector3(m.x / TollTicket.SIZE.x, m.y / TollTicket.SIZE.y, m.z))
			out.append([frac.call(t.get_rect()), marks])
	return out


## Guarda o bilhete na caixinha (já conta; a descida é só de vista, `_sink`); sem o carimbo, o supervisor anota.
func file(t: TollTicket) -> void:
	filed += 1
	_filed.append(t.stamped)
	if not t.stamped:
		unstamped.emit(t)
	_tickets.erase(t)
	_fresh.erase(t)
	_sink(t)


## O bilhete vai para cima da boca da caixinha e desce para dentro, acelerando, sumindo atrás da frente dela (recortado
## pela própria altura, que encolhe até a boca); lá dentro, a caixinha mostra mais uma beira.
func _sink(t: TollTicket) -> void:
	var mouth := _box().position.y + BOX_MOUTH
	var h := TollTicket.SIZE.y
	var sink := func(y: float) -> void:
		t.position.y = roundf(y)
		t.size.y = clampf(mouth - roundf(y), 0.0, h)
	var done := func() -> void:
		t.queue_free()
		Sfx.play("drop")
		_desk.queue_redraw()
	t.clip_contents = true
	var tw := t.create_tween()
	tw.tween_property(t, "position", Vector2(roundf(_box().get_center().x - TollTicket.SIZE.x / 2.0), mouth - h), 0.12)
	tw.tween_method(sink, mouth - h, mouth, SINK_SEC).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(done)


## O bilhete desce da fenda da máquina em `sec` (impresso com a ferramenta aberta, no tempo do som da impressora;
## esperando na fenda, mais depressa, quando ela abre), depois de `after`, a beira de baixo na frente (recortado pela
## própria altura, como na caixinha, `_sink`), e cai na mesa embaixo dela, um pouco desencontrado dos outros.
func _emerge(t: TollTicket, sec: float, after := 0.0) -> void:
	var i := _tickets.find(t) % 4
	var rest := Vector2(roundf(_screen().get_center().x - TollTicket.SIZE.x / 2.0) + i * 14.0, 4.0 + i * 12.0)
	var h := TollTicket.SIZE.y
	var out := func(v: float) -> void:
		t.top = h - roundf(v)
		t.size.y = h - t.top
		t.queue_redraw()
	var slot := Vector2(roundf(_screen().get_center().x - TollTicket.SIZE.x / 2.0), _machine.size.y - 13.0)   # embaixo da fenda (`CardMachines.mouth`)
	t.position = slot + _machine.position - _desk.position
	t.clip_contents = true
	out.call(0.0)
	var tw := t.create_tween()
	tw.tween_interval(after)
	tw.tween_method(out, 0.0, h, sec)
	tw.tween_callback(func() -> void: t.clip_contents = false)
	tw.tween_property(t, "position", rest, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


## A mesa ganhou tamanho ou a ferramenta abriu: o carimbo na almofada (da primeira vez), tudo dentro da mesa e os
## bilhetes que esperavam na fenda saindo, um depois do outro.
func _arrange() -> void:
	if _desk.size.x < TollTicket.SIZE.x:   # (ainda sem tamanho: a ferramenta nunca aberta)
		return
	if not _placed:
		_placed = true
		_stamp.position = (_pad().get_center() - RUBBER_MID).round()
	for c: Control in _desk.get_children():
		if c == _stamp or (c in _tickets and not c.clip_contents):   # (não o que sai da fenda nem o que desce para a caixinha)
			c.position = _inside(c, c.position)
	if is_visible_in_tree():
		for i in _fresh.size():
			_emerge(_fresh[i], OUT_SEC, i * OUT_SEC)
		_fresh.clear()


## `p` (o canto do `c`) dentro da mesa (do carimbo, só o fundo, `FOOT`).
func _inside(c: Control, p: Vector2) -> Vector2:
	var r := FOOT if c == _stamp else Rect2(Vector2.ZERO, c.size)
	return p.clamp(-r.position, (_desk.size - r.end).max(-r.position)).round()


## O que está em `p` na mesa, o de cima primeiro (um bilhete ou o carimbo; nulo = a mesa).
func _piece_at(p: Vector2, only_tickets := false) -> Control:
	for i in range(_desk.get_child_count() - 1, -1, -1):
		var c := _desk.get_child(i) as Control
		if c is TollTicket and c in _tickets and not c.clip_contents and c.get_rect().has_point(p):   # (o que sai da fenda ainda não se pega)
			return c
		if c == _stamp and not only_tickets and _stamp_has(p - c.position):
			return c
	return null


## O bilhete de cima embaixo da borracha em `r` (na mesa), nem que só uma beira dele.
func _ticket_under(r: Rect2) -> TollTicket:
	for i in range(_desk.get_child_count() - 1, -1, -1):
		var c := _desk.get_child(i) as TollTicket
		if c and c in _tickets and not c.clip_contents and c.get_rect().intersects(r):
			return c
	return null


## `p` (coordenadas do carimbo) cai no desenho dele: o corpo e a armação, ou o cabo com a haste.
func _stamp_has(p: Vector2) -> bool:
	return (Rect2(0, STAMP_TOP.position.y, STAMP.x, STAMP.y - STAMP_TOP.position.y).has_point(p)
		or Rect2(KNOB_AT, Vector2(KNOB.x, STAMP_TOP.position.y)).has_point(p))


## Pegar (apertar em cima), levar (o canto segue o mouse de onde foi pego, dentro da mesa) e soltar. O carimbo só sobe
## quando o mouse anda com o botão apertado: apertar e soltar no lugar é clique, e aperta ele (`_stamp_down`). O mouse
## em cima do carimbo vem por ele (`mouse_filter` PASS, já nas coordenadas da mesa), também na parte que passa da mesa.
func _on_desk_input(e: InputEvent) -> void:
	if not e is InputEventMouse:
		return
	var b := e as InputEventMouseButton
	if b and b.button_index == MOUSE_BUTTON_LEFT:
		if b.pressed:
			_held = _piece_at(b.position)
			if _held:
				_grab = b.position - _held.position
				_held.move_to_front()
				if _held == _stamp:
					_press = b.position
				else:
					_lift(_held, true)
		elif _held:
			_put(b.position)
	elif e is InputEventMouseMotion and _held:
		if _press != Vector2.INF and e.position.distance_to(_press) > CardMachines.DRAG_START:
			_press = Vector2.INF
			_lift(_held, true)
		if _press == Vector2.INF:
			_held.position = _inside(_held, e.position - _grab)
	_desk.mouse_default_cursor_shape = Control.CURSOR_DRAG if _held else (Control.CURSOR_MOVE if _piece_at(e.position) else Control.CURSOR_ARROW)
	_stamp.mouse_default_cursor_shape = _desk.mouse_default_cursor_shape


## Solta o que está na mão: o carimbo clicado é apertado (`_stamp_down`) e o levado fica onde caiu; o bilhete com o
## mouse em cima da caixinha vai para ela.
func _put(at: Vector2) -> void:
	var c := _held
	_held = null
	if _press != Vector2.INF:
		_press = Vector2.INF
		_stamp_down()
		return
	_lift(c, false)
	if c == _stamp:
		_thud = true
	elif _box().has_point(at):
		file(c as TollTicket)


## O carimbo apertado onde está: cabo, corpo e rodas descem pelas pernas e voltam (a batida é no fundo, `_touch`).
## Quanto desceu (`_press_k`): acelera até o papel, fica nele um instante e volta freando.
func _stamp_down() -> void:
	if _pressing > 0.0:
		return
	_pressing = PRESS_SEC
	set_process(true)


## 0 em cima, 1 com as rodas no papel (`PRESS_DOWN`, `PRESS_HOLD`, `PRESS_SEC`).
func _press_k() -> float:
	var e := PRESS_SEC - _pressing
	if e < PRESS_DOWN:
		return pow(e / PRESS_DOWN, 2.0)
	if e < PRESS_DOWN + PRESS_HOLD:
		return 1.0
	return pow(1.0 - (e - PRESS_DOWN - PRESS_HOLD) / (PRESS_SEC - PRESS_DOWN - PRESS_HOLD), 2.0)


## Os tipos encostam no papel, na janela: marcam o bilhete de cima embaixo dela, nem que só a beira (o que ainda não
## tem marca que vale; seca a borracha um pouco), e, com o meio da janela na almofada, ganham tinta.
func _touch() -> void:
	Sfx.play("thump")
	Sfx.play("punch")   # o estalo do metal por cima do baque
	if _shake == 0.0:
		_desk_at = _desk.position
	_shake = SHAKE_SEC
	var mid := _stamp.position + RUBBER_MID
	var t := _ticket_under(Rect2(mid - TollTicket.MARK_SIZE / 2.0, TollTicket.MARK_SIZE))
	if t and not t.stamped:
		t.stamp(mid - t.position, float(_ink) / INK)
		_ink = maxi(_ink - 1, 0)
	if _pad().has_point(mid):
		_ink = INK
		if _wet_tween:
			_wet_tween.kill()
		_wet_tween = create_tween()
		_wet_tween.tween_property(self, "_wet", 1.0, WET_SEC).from(0.0)


func _lift(c: Control, on: bool) -> void:
	if on:
		c.pivot_offset = _grab   # chega perto e se afasta em volta de onde a mão pegou
	if c is TollTicket:
		(c as TollTicket).held = on
	else:
		_stamp_lift.held = on
		_thud = false
		set_process(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for c: Control in [_machine, _desk]:
			c.queue_redraw()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and is_node_ready():
		_arrange()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and _held:   # guardada com algo na mão: fica onde estava
		var c := _held
		_held = null
		_press = Vector2.INF
		_lift(c, false)


func _pad(s := _desk.size) -> Rect2:
	return Rect2(INSET.x, s.y - PAD.y - INSET.y, PAD.x, PAD.y)


func _box(s := _desk.size) -> Rect2:
	return Rect2(s.x - BOX.x - INSET.x, s.y - BOX.y - INSET.y, BOX.x, BOX.y)


## O visor da máquina (no desenho dela): à esquerda da placa; a fenda do bilhete fica embaixo do meio dele.
func _screen() -> Rect2:
	var r := Rect2(Vector2.ZERO, _machine.size - Vector2(2, 2)).abs()
	return Rect2(r.position.x + 16.0, r.position.y + 12.0, r.size.x - 16.0 - 150.0, r.size.y - 40.0)


## A máquina: a caixa de metal das do despacho (`CardMachines.box`) com o painel dos contadores (um por entrada, com a
## plaquinha, os tambores dos minutos, `_counter`, e a lâmpada acesa enquanto conta), a placa, a luz âmbar acesa
## enquanto conta algum e, embaixo, a fenda de onde sai o bilhete; apoiada na mesa pelos pés de borracha. Sem relógio:
## o da mesa da sala, ao lado, já dá a hora.
func _draw_machine() -> void:
	var ci := _machine
	Bloom.clear(ci)
	var r := Rect2(Vector2.ZERO, ci.size - Vector2(2, 2)).abs()
	CardMachines.box(ci, r)
	var screen := _screen()
	ci.draw_rect(screen.grow(1.0), Pal.EDGE)
	ci.draw_rect(screen, Pal.PANEL_LO)
	var cell := (screen.size / Vector2(COUNTER_COLS, ceilf(float(Exchange.LINES) / COUNTER_COLS))).floor()
	for n in range(1, Exchange.LINES + 1):
		var o := screen.position + Vector2((n - 1) % COUNTER_COLS, (n - 1) / COUNTER_COLS) * cell + Vector2(roundf((cell.x - 62.0) / 2.0), 0)   # no meio da célula
		var plate := Rect2(o.x + 3.0, o.y + roundf((cell.y - 13.0) / 2.0), 18, 13)   # a plaquinha da entrada
		ci.draw_rect(plate, Pal.BRASS)
		ci.draw_rect(plate.grow(-1.0), Pal.BRASS.darkened(0.25))
		PunchCard.write(ci, Vector2(plate.position.x, plate.end.y - 3.0), "%02d" % n, Pal.INK, plate.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		var win := Rect2(plate.end.x + 3.0, o.y + roundf((cell.y - DRUM.y - 2.0) / 2.0), DRUMS * (DRUM.x + 1.0) + 1.0, DRUM.y + 2.0)
		_counter(ci, win, n)
		CardMachines.led(ci, Vector2(win.end.x + 4.0, win.position.y + 5.0), counting(n), Pal.AMBER)
	var side := Rect2(screen.end.x + 8.0, r.position.y, r.end.x - screen.end.x - 8.0, r.size.y)
	CardMachines.plate(ci, Rect2(side.position.x - 10.0, side.position.y - 10.0, side.size.x, side.size.y), T.text(T.Key.TOLL_MACHINE))
	CardMachines.led(ci, side.position + Vector2(2, 40), metering(), Pal.AMBER)
	CardMachines.vent(ci, side.position + Vector2(18, 40), 4, side.size.x - 34.0)
	CardMachines.mouth(ci, roundf(screen.get_center().x - TollTicket.SIZE.x / 2.0), r.end.y - 12.0, TollTicket.SIZE.x)
	ci.draw_rect(Rect2(r.position.x + 6.0, r.end.y + 2.0, r.size.x - 6.0, 5), Color(0, 0, 0, 0.3))   # apoiada na mesa: a sombra embaixo...
	for x: float in [r.position.x + 16.0, r.end.x - 40.0]:   # ...e os pés de borracha
		ci.draw_rect(Rect2(x, r.end.y, 24, 4), Pal.EDGE)
		ci.draw_rect(Rect2(x + 1.0, r.end.y, 22, 1), Pal.PANEL_LO)


## O contador da entrada `n` na janela `win`: os tambores com os minutos começados de quem está falando, cada um rolando
## do algarismo de antes para o seguinte no começo do minuto (a janela da tira de algarismos desce, como no tambor de
## verdade); parado, zerado e apagado. A sombra em cima e embaixo de cada tambor faz a curva dele.
func _counter(ci: CanvasItem, win: Rect2, n: int) -> void:
	ci.draw_rect(win, Pal.EDGE)
	var cur := 0
	var t := 1.0
	if _meters.has(n):
		var e := now - float(_meters[n][2])
		cur = maxi(1, ceili(e))
		t = minf((e - floorf(e)) / ROLL, 1.0)
	for i in DRUMS:
		var d := Rect2(win.position + Vector2(1.0 + i * (DRUM.x + 1.0), 1.0), DRUM)
		var p := int(pow(10, DRUMS - 1 - i))
		var digit := float(cur / p % 10)
		var before := (cur - 1) / p % 10
		if cur > 0 and before != int(digit):
			digit = before + t
		ci.draw_rect(d, Pal.INK)
		ci.draw_texture_rect_region(_drum_strip(), d, Rect2(0, roundf(digit * DRUM.y), DRUM.x, DRUM.y), Pal.TEXT if cur > 0 else Pal.INK_SOFT)
		for y: float in [d.position.y, d.end.y - 2.0]:
			ci.draw_rect(Rect2(d.position.x, y, DRUM.x, 2), Color(0, 0, 0, 0.45))


## Algum interurbano está com o tambor rolando no minuto `at` (o visor se redesenha a cada quadro só então).
func _rolling(at: float) -> bool:
	for m: Array in _meters.values():
		var e := at - float(m[2])
		if e - floorf(e) < ROLL:
			return true
	return false


## A tira dos tambores: os algarismos (`DIGITS`) de 0 a 9 e o 0 de novo (o 9 rola para ele), um a cada `DRUM.y`, em
## branco (a cor vem no desenho).
static func _drum_strip() -> ImageTexture:
	if _strip == null:
		var img := Image.create(int(DRUM.x), int(DRUM.y) * 11, false, Image.FORMAT_RGBA8)
		for k in 11:
			var rows: PackedStringArray = DIGITS[k % 10].split("/")
			for y in rows.size():
				for x in rows[y].length():
					if rows[y][x] == "#":
						img.set_pixel(1 + x, k * int(DRUM.y) + 2 + y, Color.WHITE)
		_strip = ImageTexture.create_from_image(img)
	return _strip


## O carimbo de cima, inclinado: a sombra na mesa, peça por peça (a janela fica limpa), a da armação em duas, a curta e
## escura de quem encosta na mesa (some na mão) e a longa e fraca, como a do corpo e do cabo; a armação parada (as
## pernas até o fundo, com o rasgo do eixo, a sapata entre elas, com a parede de trás da janela à vista e os dentes dos
## lados, os parafusos de latão e o seletor); e o que desce no aperto (`_press_k`, até as rodas encostarem no fundo da
## janela, tampando-a; perto do papel, a sombra deles encurta): as rodas de algarismos com os tipos na cor da tinta
## (secando, `_ink`), o eixo com as pontas, o corpo (o tampo com a quina da frente na luz, a frente com as beiras
## arredondadas e a plaqueta parafusada) e o cabo.
func _draw_stamp() -> void:
	var ci := _stamp
	var n := Pal.NICKEL
	var b := Pal.BRASS
	var k := _press_k()
	var d := Vector2(0, roundf(PRESS * k))
	var s := _stamp_lift.shadow()
	var sd := s.lerp(SHADOW_NEAR, k)   # a sombra do que desce
	var legs: Array[Rect2] = []
	for x: float in [BASE.position.x, BASE.end.x - LEG]:
		legs.append(Rect2(x, STAMP_FRONT.end.y, LEG, BASE.end.y - STAMP_FRONT.end.y))
	var bars: Array[Rect2] = [Rect2(WINDOW.position.x, BASE.position.y, WINDOW.size.x, WINDOW.position.y - BASE.position.y),
		Rect2(WINDOW.position.x, WINDOW.end.y, WINDOW.size.x, BASE.end.y - WINDOW.end.y)]
	var lever := Rect2(SELECTOR.position.x + 10.0, SELECTOR.end.y, 7, 5)   # embaixo do segundo risco
	var body := Rect2(STAMP_TOP.position + sd + d, STAMP_TOP.merge(STAMP_FRONT).size)
	var far := Color(0, 0, 0, SHADOW_FAR_A)
	for r: Rect2 in legs + bars + [SELECTOR, lever]:   # a armação: a sombra curta e a longa (menos onde cai a do corpo: dobrava)
		ci.draw_rect(Rect2(r.position + SHADOW_NEAR, r.size), Color(0, 0, 0, SHADOW_NEAR_A * (1.0 - _stamp_lift.height)))
		for part in _minus(Rect2(r.position + s, r.size), body):
			ci.draw_rect(part, far)
	ci.draw_rect(body, far)
	ci.draw_texture(_knob(), KNOB_AT + sd + d, far)
	for leg in legs:   # as pernas, com o rasgo do eixo, o pé e o parafuso de fora
		_bevel(ci, leg, n[1], n[0], n[2])
		ci.draw_rect(Rect2(leg.position.x + 3.0, leg.position.y + 3.0, 2, WINDOW.end.y - leg.position.y - 6.0), n[3])
		ci.draw_rect(Rect2(leg.position.x, leg.end.y - 1.0, LEG, 1), n[3])
		_bevel(ci, Rect2(leg.position.x - 4.0 if leg.position.x < STAMP.x / 2.0 else leg.end.x, BASE.position.y - 12.0, 4, 8), b, b.lightened(0.3), b.darkened(0.45))
	for r in bars:   # a sapata entre as pernas
		ci.draw_rect(r, n[1])
	ci.draw_rect(Rect2(bars[0].position, Vector2(bars[0].size.x, 1)), n[2])   # a beira de trás...
	ci.draw_rect(Rect2(bars[1].position.x, BASE.end.y - 2.0, bars[1].size.x, 2), n[2])   # ...e a da frente, de pé
	ci.draw_rect(Rect2(bars[1].position.x, BASE.end.y - 1.0, bars[1].size.x, 1), n[3])
	ci.draw_rect(Rect2(WINDOW.position, Vector2(WINDOW.size.x, 2)), n[3])   # a parede de trás da janela, na sombra
	ci.draw_rect(Rect2(WINDOW.position.x, WINDOW.end.y, WINDOW.size.x, 1), n[0])   # a quina de dentro da frente, na luz
	for y in range(int(WINDOW.position.y) + 3, int(WINDOW.end.y) - 1, 4):   # os dentes dos lados
		ci.draw_rect(Rect2(WINDOW.position.x, y, 2, 2), n[2])
		ci.draw_rect(Rect2(WINDOW.end.x - 2.0, y, 2, 2), n[2])
	_bevel(ci, SELECTOR, b, b.lightened(0.3), b.darkened(0.45))   # o seletor: os riscos gravados (a parede da direita na luz)...
	for i in 4:
		var x := SELECTOR.position.x + 5.0 + i * 8.0
		ci.draw_rect(Rect2(x, SELECTOR.position.y + 3.0, 1, 4), b.darkened(0.6))
		ci.draw_rect(Rect2(x + 1.0, SELECTOR.position.y + 3.0, 1, 4), b.lightened(0.25))
	for i in int(lever.size.x):   # ...e a alavanca, de ponta serrilhada
		ci.draw_rect(Rect2(lever.position.x + i, lever.position.y, 1, lever.size.y - 1.0), b.lightened(0.2) if i % 2 == 0 else b.darkened(0.35))
	ci.draw_rect(Rect2(lever.position.x, lever.end.y - 1.0, lever.size.x, 1), b.darkened(0.55))
	var wheels := Rect2(Vector2(WINDOW.position.x, STAMP_FRONT.end.y) + d, Vector2(WINDOW.size.x, 11))   # as rodas de algarismos, de latão, da largura da janela
	var rows: Array[Color] = [b.darkened(0.55), b.lightened(0.25), b.lightened(0.1), b, b, b, b.darkened(0.2), b.darkened(0.2), b.darkened(0.4), b.darkened(0.55), b.darkened(0.55)]
	for i in rows.size():
		ci.draw_rect(Rect2(wheels.position.x, wheels.position.y + i, wheels.size.x, 1), rows[i])
	var ink := TollTicket.MARK.darkened(0.25).lerp(DRY, 1.0 - float(_ink) / INK)
	for i in 8:
		var x := wheels.position.x + i * 8.0
		ci.draw_rect(Rect2(x + 7.0, wheels.position.y + 1.0, 1, wheels.size.y - 2.0), b.darkened(0.55))
		ci.draw_rect(Rect2(x + 2.0, wheels.end.y - 2.0, 4, 2), ink)   # o tipo de baixo, com a tinta
	for x: float in [0.0, STAMP.x - 8.0]:   # o eixo, passando pelas pernas, e as pontas dele
		ci.draw_rect(Rect2(Vector2(x + (8.0 if x == 0.0 else -4.0), 130) + d, Vector2(4, 5)), n[2])
		var tip := Rect2(Vector2(x, 128) + d, Vector2(8, 9))
		_rounded(ci, tip, n[2])
		ci.draw_rect(Rect2(tip.position.x + 1.0, tip.position.y, 6, 1), n[0])
		ci.draw_rect(Rect2(tip.position.x, tip.position.y + 1.0, 8, 3), n[1])
		ci.draw_rect(Rect2(tip.position.x + 1.0, tip.end.y - 1.0, 6, 1), n[3])
	var top := Rect2(STAMP_TOP.position + d, STAMP_TOP.size)
	_chamfer(ci, top, n[2], 3)
	_chamfer(ci, top.grow_individual(-1, -1, -1, 0), n[1], 2)   # o tampo...
	ci.draw_rect(Rect2(top.position.x + 1.0, top.end.y - 3.0, top.size.x - 2.0, 1), n[0])   # ...e a quina da frente, arredondada, na luz
	var front := Rect2(STAMP_FRONT.position + d, STAMP_FRONT.size)
	ci.draw_rect(front, n[2].lerp(n[1], 0.5))
	ci.draw_rect(Rect2(front.position, Vector2(front.size.x, 1)), n[2])
	for i in 3:   # as beiras arredondadas: a da esquerda na luz, a da direita na sombra
		ci.draw_rect(Rect2(front.position.x + i, front.position.y, 1, front.size.y), [n[2], n[0], n[1]][i])
		ci.draw_rect(Rect2(front.end.x - 1.0 - i, front.position.y, 1, front.size.y), [n[3], n[2], n[2]][i])
	ci.draw_rect(Rect2(front.position.x, front.end.y - 1.0, front.size.x, 1), n[3])
	var plate := Rect2(front.position.x + 11.0, front.position.y + 6.0, 60, 24)   # a plaqueta, parafusada nos cantos
	_bevel(ci, plate, n[0].lerp(n[1], 0.4), n[0], n[3])
	for c: Vector2 in [Vector2(2, 2), Vector2(plate.size.x - 4.0, 2), Vector2(2, plate.size.y - 4.0), plate.size - Vector2(4, 4)]:
		ci.draw_rect(Rect2(plate.position + c, Vector2(2, 2)), n[2])
	PunchCard.write(ci, Vector2(plate.position.x, plate.position.y + 16.0), T.text(T.Key.TOLL_STAMP), Pal.INK, plate.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	ci.draw_texture(_knob(), KNOB_AT + d)


## `r` sem o que cai em `cut`: até quatro retângulos (em cima, embaixo e dos lados do corte), sem se sobrepor.
static func _minus(r: Rect2, cut: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var c := r.intersection(cut)
	if not c.has_area():
		out.append(r)
		return out
	if c.position.y > r.position.y:
		out.append(Rect2(r.position.x, r.position.y, r.size.x, c.position.y - r.position.y))
	if c.end.y < r.end.y:
		out.append(Rect2(r.position.x, c.end.y, r.size.x, r.end.y - c.end.y))
	if c.position.x > r.position.x:
		out.append(Rect2(r.position.x, c.position.y, c.position.x - r.position.x, c.size.y))
	if c.end.x < r.end.x:
		out.append(Rect2(c.end.x, c.position.y, r.end.x - c.end.x, c.size.y))
	return out


## Peça de metal de frente, `r`, na cor `c`: a beira de cima e a da esquerda na luz (`hi`), a de baixo e a da direita na
## sombra (`lo`).
static func _bevel(ci: CanvasItem, r: Rect2, c: Color, hi: Color, lo: Color) -> void:
	ci.draw_rect(r, c)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), hi)
	ci.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), hi)
	ci.draw_rect(Rect2(r.end.x - 1.0, r.position.y, 1, r.size.y), lo)
	ci.draw_rect(Rect2(r.position.x, r.end.y - 1.0, r.size.x, 1), lo)


## O cabo, de torno, visto de cima (guardado): uma fatia redonda por linha de altura (`_knob_r`), deitada (`SQUASH`), de
## baixo para cima, cada uma por cima da de baixo, que fica à vista só na frente; cada coluna na faixa de luz dela
## (`_knob_tone`). O anel e a haste cromados (`Pal.NICKEL`); a pega e a bola em cogumelo, de baquelite, no preto dos cabos
## da mesa (`Switchboard.CORD_COLORS`); no meio do tampo, o medalhão de latão do fabricante (`BRAND`).
static func _knob() -> ImageTexture:
	if _knob_tex == null:
		var img := Image.create(KNOB.x, KNOB.y, false, Image.FORMAT_RGBA8)
		var mid := KNOB.x / 2.0
		var top := 63
		for h in top + 1:
			var r := _knob_r(h)
			var ry := r * SQUASH
			var yc := KNOB_BASE - h
			for y in range(floori(yc - ry), ceili(yc + ry)):
				var t := (y + 0.5 - yc) / ry
				if absf(t) >= 1.0:
					continue
				var w := r * sqrt(1.0 - t * t)
				for x in range(roundi(mid - w), roundi(mid + w)):
					img.set_pixel(x, y, _knob_tone((x + 0.5 - mid + r) / (2.0 * r), t, h, top))
		var b := Pal.BRASS   # o medalhão no meio do tampo: latão com a beira escura, o brilho da janela e o nome gravado
		var rt := _knob_r(top)
		var my := KNOB_BASE - top
		for y in range(my - 5, my + 5):
			for x in range(roundi(mid - 13.0), roundi(mid + 13.0)):
				var ex := (x + 0.5 - mid) / 13.0
				var ey := (y + 0.5 - my) / 5.0
				var e := ex * ex + ey * ey
				if e >= 1.0:
					continue
				var u := (x + 0.5 - mid + rt) / (2.0 * rt)
				var t := (y + 0.5 - my) / (rt * SQUASH)
				var c := b.darkened(0.45) if e > 0.7 else (b.lightened(0.2) if ex < -0.35 else b)
				if u > 0.55 and u < 0.72 and t > -0.75 and t < -0.25:
					c = b.lightened(0.5)
				img.set_pixel(x, y, c)
		var x0 := floori(mid - (BRAND.length() * 4 - 1) / 2.0)
		for i in BRAND.length():
			var glyph := (PixelArt.TINY[BRAND[i]] as String).split("/")
			for gy in glyph.size():
				for gx in glyph[gy].length():
					if glyph[gy][gx] == "#":
						img.set_pixel(x0 + i * 4 + gx, my - 2 + gy, b.darkened(0.6))
		_knob_tex = ImageTexture.create_from_image(img)
	return _knob_tex


## O raio do cabo na altura `h` (de baixo, em px da tela): o anel, a haste, a ponta arredondada da pega, a pega
## alargando, a curva de baixo da bola, a beira dela e o domo baixo, até o tampo.
static func _knob_r(h: int) -> float:
	if h < 4:
		return 14.0
	if h < 29:
		return 9.0
	if h < 31:
		return 10.5 + (h - 29) * 1.5
	if h < 51:
		return lerpf(12.5, 16.0, (h - 31) / 20.0)
	if h < 55:
		return 16.0 + 8.0 * sqrt((h - 50) / 4.0)
	return 24.0 - maxi(h - 60, 0) ** 2 / 3.0


## A cor do cabo em `u` (0 na beira da esquerda, 1 na da direita) e `t` (-1 atrás, 1 na frente da fatia) na altura `h`:
## a faixa de luz (`BANDS`), mais clara no tampo do anel e mais escura embaixo da bola e da pega; o tampo da bola (`top`),
## oval e escuro, mais claro à esquerda, na sombra à direita, com o brilho da janela.
static func _knob_tone(u: float, t: float, h: int, top: int) -> Color:
	var tones: Array[Color]
	if h < 29:
		var n := Pal.NICKEL
		tones = [n[3], n[2], n[2].lerp(n[1], 0.5), n[1], n[0]]
	else:
		var c: Color = Switchboard.CORD_COLORS[5][0]
		var l: Color = Switchboard.CORD_COLORS[5][1]
		tones = [c.darkened(0.5), c.darkened(0.2), c, c.lerp(l, 0.6), l.lightened(0.2)]
	if h == top:
		if u > 0.55 and u < 0.72 and t > -0.75 and t < -0.25:
			return tones[4]
		return tones[1 if u > 0.75 else (3 if u < 0.4 and t > -0.3 else 2)]
	var band: int = BANDS[BAND_U.bsearch(u)]
	var i := band
	if h == 3:
		i += 1
	elif (h >= 45 and h < 55) or (h >= 25 and h < 29):
		i -= 1
	if band == 4 and (h < 29 or (h >= 47 and h < 60)):   # o reflexo quente da luminária, do lado da luz
		return tones[clampi(i, 0, 4)].lerp(GLINT, 0.35)
	return tones[clampi(i, 0, 4)]


## Retângulo com as quinas de cima chanfradas em `cut` degraus de 1 px.
static func _chamfer(ci: CanvasItem, r: Rect2, c: Color, cut: int) -> void:
	for row in cut:
		ci.draw_rect(Rect2(r.position.x + cut - row, r.position.y + row, r.size.x - (cut - row) * 2.0, 1), c)
	ci.draw_rect(Rect2(r.position.x, r.position.y + cut, r.size.x, r.size.y - cut), c)


## Retângulo com os cantos de 1 px cortados (sem sobrepor: a sombra transparente fica por igual).
static func _rounded(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x + 1.0, r.position.y, r.size.x - 2.0, r.size.y), c)
	for x: float in [r.position.x, r.end.x - 1.0]:
		ci.draw_rect(Rect2(x, r.position.y + 1.0, 1, r.size.y - 2.0), c)


## O feltro da almofada, `sz`, pixel a pixel: o vermelho da tinta com fiapos mais escuros e mais claros, sempre os
## mesmos. Guardado por tamanho.
static func _felt(sz: Vector2i) -> ImageTexture:
	if not _felts.has(sz):
		var img := Image.create(maxi(sz.x, 1), maxi(sz.y, 1), false, Image.FORMAT_RGBA8)
		var c := TollTicket.MARK.darkened(0.55)
		for y in sz.y:
			for x in sz.x:
				var g := (x * 73 + y * 151 + x * y * 7) % 37
				img.set_pixel(x, y, c.darkened(0.25) if g < 4 else (c.lightened(0.1) if g > 33 else c))
		_felts[sz] = ImageTexture.create_from_image(img)
	return _felts[sz]



## A mesa: a almofada de tinta (a lata de níquel com a tampa aberta atrás, o feltro e o brilho da tinta molhada, `_wet`)
## e a caixinha de madeira, aberta, com a beira de cima de cada bilhete guardado (até alguns: a faixa do formulário e,
## nos carimbados, a ponta da marca) e a plaqueta de latão na frente.
func _draw_desk() -> void:
	var ci := _desk
	var pad := _pad()
	var lid := Rect2(pad.position.x + 3.0, pad.position.y - LID, pad.size.x - 6.0, LID + 2.0)   # a tampa aberta, por dentro
	ci.draw_rect(lid, Pal.NICKEL[3])
	ci.draw_rect(lid.grow(-1.0), Pal.NICKEL[2])
	ci.draw_rect(Rect2(lid.position + Vector2(1, 1), Vector2(lid.size.x - 2.0, 1)), Pal.NICKEL[1])   # a beira de cima, na luz
	ci.draw_rect(lid.grow_individual(-4, -4, -4, -6), Pal.NICKEL[2].darkened(0.12))   # o fundo dela, rebaixado
	ci.draw_rect(Rect2(lid.position.x + 4.0, lid.position.y + 4.0, lid.size.x - 8.0, 1), Pal.NICKEL[3])
	ci.draw_rect(Rect2(pad.position + Vector2(2, 3), pad.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(pad, Pal.NICKEL[3])
	ci.draw_rect(pad.grow(-1.0), Pal.NICKEL[2])
	ci.draw_rect(Rect2(pad.position + Vector2(1, 1), Vector2(pad.size.x - 2.0, 1)), Pal.NICKEL[1])
	for x: float in [pad.position.x + 12.0, pad.end.x - 26.0]:   # as dobradiças da tampa
		ci.draw_rect(Rect2(x, pad.position.y - 1.0, 14, 3), Pal.NICKEL[3])
		ci.draw_rect(Rect2(x + 1.0, pad.position.y - 1.0, 12, 1), Pal.NICKEL[1])
	var felt := pad.grow(-5.0)
	ci.draw_texture(_felt(Vector2i(felt.size)), felt.position)
	ci.draw_rect(Rect2(felt.position, Vector2(felt.size.x, 1)), TollTicket.MARK.darkened(0.35))
	var sheen := Color(TollTicket.MARK.lightened(0.35), 0.5 * _wet)   # a tinta molhada
	for line: Rect2 in [Rect2(12, 5, 46, 1), Rect2(20, 7, 24, 1), Rect2(84, 21, 30, 1), Rect2(92, 23, 12, 1)]:
		ci.draw_rect(Rect2(felt.position + line.position, line.size), sheen)
	var r := _box()
	ci.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(r, Pal.BOARD[2])
	var inside := Rect2(r.position + Vector2(5, 4), Vector2(r.size.x - 10.0, BOX_MOUTH - 4.0))
	ci.draw_rect(inside, Color("140e09"))
	for i in range(mini(_filed.size(), 10) - 1, -1, -1):   # os bilhetes de pé lá dentro, do fundo para a frente (o último na frente)
		var tk := Rect2(inside.position.x + 4.0 + (i * 5) % 9, inside.end.y - 5.0 - i * 2.0, inside.size.x - 16.0, 2)
		var k := 0.15 + i * 0.03
		ci.draw_rect(Rect2(tk.position, Vector2(tk.size.x, 1)), TollTicket.FORM.darkened(k))   # a beira de cima: a faixa do formulário
		ci.draw_rect(Rect2(tk.position.x, tk.position.y + 1.0, tk.size.x, 1), TollTicket.PAPER.darkened(k))
		if _filed[_filed.size() - 1 - i]:
			ci.draw_rect(Rect2(tk.position.x + roundf(tk.size.x * 0.55), tk.position.y + 1.0, 5, 1), TollTicket.MARK.darkened(k))   # a ponta da marca
	var front := Rect2(r.position.x, inside.end.y, r.size.x, r.end.y - inside.end.y)
	ci.draw_rect(front, Pal.BOARD[1])
	ci.draw_rect(Rect2(front.position, Vector2(front.size.x, 2)), Pal.BOARD[0])
	ci.draw_rect(Rect2(front.position.x, front.end.y - 2.0, front.size.x, 2), Pal.BOARD[2])
	var brass := Rect2(floorf(front.get_center().x - 50.0), front.position.y + roundf(front.size.y / 2.0) - 9.0, 100, 18)
	ci.draw_rect(brass, Pal.BRASS)
	ci.draw_rect(brass.grow(-1.0), Pal.BRASS.darkened(0.25))
	PunchCard.write(ci, Vector2(brass.position.x, brass.position.y + 13.0), T.text(T.Key.TOLL_BOX), Pal.INK, brass.size.x, HORIZONTAL_ALIGNMENT_CENTER)
