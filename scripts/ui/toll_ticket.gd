class_name TollTicket
extends Control
## O bilhete de tarifação que o calculógrafo (`Toll`) imprime quando acaba uma ligação interurbana: uma tira de papel
## fino com o formulário impresso em azul (a faixa com o número, os rótulos e as linhas de preencher) e, datilografados
## em preto, a entrada, a cidade e o número de lá, o horário e os minutos. Fica solto na mesa do calculógrafo (`Toll`,
## que o leva e o solta; na mão, sobe como o cartão do despacho, `Lift`); o carimbo batido em cima dele deixa a marca
## vermelha onde a janela dele estava (`stamp`), mais fraca com a borracha secando e cortada na beira do papel.

const SIZE := Vector2(190, 140)   ## o título e o número lado a lado na faixa (em 176, encostavam); embaixo, o campo do carimbo
const MARK_SIZE := Vector2(64, 34)   ## a janela da sapata do carimbo (`Toll.WINDOW`): a moldura e as três linhas
const MARK_VALID := 0.5   ## a parte da marca que tem que cair no papel para valer; menos é borrão
const BAND := 16.0   ## a faixa do formulário, em cima, com o título e o número
const VALUE_X := 62.0   ## onde começam os dados, à direita dos rótulos
const FIELD := Rect2(30, 92, 130, 42)   ## o campo impresso do carimbo, embaixo dos dados (cabe a marca, `MARK_SIZE`), com o nome em cima
const TEETH := 4.0   ## a beira de baixo, serrilhada onde a máquina cortou a tira: um dente a cada tanto (px)

var serial := 0
var line := 0
var city := ""
var far := ""        ## o número na outra cidade
var night := 1       ## a noite do turno: a data nas rodas do carimbo
var start := 0.0     ## o minuto do turno em que a outra ponta atendeu...
var end := 0.0       ## ...e o em que a conversa acabou
var stamped := false       ## carimbado com tinta (a marca da borracha seca não vale)
var mark := Vector2.ZERO   ## o meio da última marca do carimbo (coordenadas do bilhete; pode passar da beira)
var ink := -1.0            ## a tinta dela: 1 cheia, mais fraca a cada batida, 0 seca (só o vulto); -1 = sem marca
var top := 0.0             ## saindo da fenda (`Toll._emerge`): o quanto dele ainda está lá dentro
## Na mão (`Toll`): sobe; solto, cai de volta na mesa.
var held := false:
	set(v):
		held = v
		_lift.held = v
		set_process(true)

var _lift := Lift.new()
var _specks: Array[Vector2] = []   # as fibras do papel (cada bilhete as suas, pelo número)
var marks: Array[Vector3] = []     ## as batidas que ficaram no papel (o meio e a tinta), as que não valem também
var _inked := Control.new()        # as marcas, recortadas no papel (a beira serrilhada fica de fora)


func _init() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # a mesa (`Toll`) pega e leva
	_inked.size = SIZE - Vector2(0, 2)
	_inked.clip_contents = true
	_inked.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inked.draw.connect(_draw_marks)
	add_child(_inked)


## Os minutos cobrados: o primeiro conta inteiro, e os outros, começados.
func minutes() -> int:
	return maxi(1, ceili(end - start - 0.01))


## Quem é, no relatório do supervisor: a entrada e a cidade.
func detail() -> String:
	return "%s · %s" % [T.text(T.Key.LINE_N) % line, city]


## Carimba com o meio da marca em `at` (no bilhete; o que cai fora do papel não aparece), com a tinta `wet` da borracha.
## Vale com tinta e com ao menos `MARK_VALID` da marca no papel; seca (só o vulto) ou na beira (borrão), fica no
## papel e não vale, e dá para carimbar de novo.
func stamp(at: Vector2, wet := 1.0) -> void:
	mark = at
	ink = wet
	var on := Rect2(at - MARK_SIZE / 2.0, MARK_SIZE).intersection(Rect2(Vector2.ZERO, _inked.size)).get_area()
	stamped = wet > 0.0 and on >= MARK_SIZE.x * MARK_SIZE.y * MARK_VALID
	marks.append(Vector3(at.x, at.y, wet))
	_inked.queue_redraw()


func _draw_marks() -> void:
	for i in marks.size():
		_draw_mark(Vector2(marks[i].x, marks[i].y), marks[i].z, serial + i * 5)


## A marca do carimbo em `mark`, como a borracha a deixa: a moldura grossa de cantos redondos e, por dentro dela, um
## fio fino em cima e outro embaixo; a data das rodas entre dois traços, "TARIFADO" em negrito e o nome da cidade entre duas
## estrelinhas. A tinta falha nos fios (cada bilhete as suas, pelo número), mais do lado que a mão apertou menos, e
## carrega em alguns pontos; com menos tinta (`k`), mais clara e com mais falhas. Cada batida falha do seu jeito (`vary`).
func _draw_mark(at: Vector2, k: float, vary: int) -> void:
	var ci := _inked
	var o := (at - MARK_SIZE / 2.0).round()
	var w := int(MARK_SIZE.x)
	var h := int(MARK_SIZE.y)
	var tint := Color(Pal.TOLL_INK, lerpf(0.15, 0.85, k))
	var gaps := 1 + roundi((1.0 - k) * 5.0)   # de cada 13 pontos dos fios, quantos falham (no lado fraco, mais dois)
	var weak := vary % 2 == 0   # o lado fraco: a direita ou a esquerda
	var dot := func(x: int, y: int) -> void:
		var side := float(x) / (w - 1) if weak else 1.0 - float(x) / (w - 1)
		if posmod(x * 7 + y * 5 - vary, 13) >= gaps + roundi(side * 2.0):
			ci.draw_rect(Rect2(o.x + x, o.y + y, 1, 1), tint)
			if posmod(x * 11 + y * 3 + vary, 31) == 0:   # a tinta carregada
				ci.draw_rect(Rect2(o.x + x, o.y + y, 1, 1), tint)
	for x in w:   # a moldura grossa...
		for y: int in [0, 1, h - 2, h - 1]:
			if not ((x == 0 or x == w - 1) and (y == 0 or y == h - 1)):
				dot.call(x, y)
	for y in range(2, h - 2):
		for x: int in [0, 1, w - 2, w - 1]:
			dot.call(x, y)
	for x in range(3, w - 3):   # ...e os fios finos
		dot.call(x, 3)
		dot.call(x, h - 4)
	var d := GameData.date_of(night)
	var date := PixelArt.tiny("%02d %s %d" % [d.day, T.text(T.Key.CALENDAR_MONTH), d.year])
	var dx := floori((w - date.get_width()) / 2.0)
	ci.draw_texture(date, o + Vector2(dx, 2), tint)
	for i in dx - 5:   # os traços dos lados da data
		dot.call(3 + i, 7)
		dot.call(dx + date.get_width() + 2 + i, 7)
	var word := T.text(T.Key.TOLL_STAMP)
	var tx := floorf((w - Pal.mono.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x - 1.0) / 2.0)
	for b in 2:   # em negrito: o traço da borracha é grosso
		PunchCard.write(ci, o + Vector2(tx + b, 20), word, tint)
	var city := PixelArt.tiny(CityMap.CITY)
	var cx := floori((w - city.get_width()) / 2.0)
	ci.draw_texture(city, o + Vector2(cx, 21), tint)
	for x: int in [cx - 4, cx + city.get_width() + 3]:   # as estrelinhas
		for p: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			dot.call(x + p.x, 26 + p.y)


func _process(delta: float) -> void:
	if not _lift.step(delta):
		set_process(false)
	scale = _lift.scale()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
		_inked.queue_redraw()


## Sempre no tamanho inteiro (`SIZE`): entrando na caixinha, a altura encolhe e recorta (`clip_contents`, `Toll._sink`);
## saindo da fenda, também, e o desenho sobe o que ainda está lá dentro (`top`). O papel com as fibras (como o cartão
## do despacho), a beira de baixo serrilhada e, embaixo dos dados, o campo do carimbo, tracejado; as marcas por cima,
## no `_inked`.
func _draw() -> void:
	draw_set_transform(Vector2(0, -top))
	draw_rect(Rect2(_lift.shadow(), SIZE - Vector2(0, 1)), Lift.SHADOW)   # a sombra na mesa
	draw_rect(Rect2(0, 0, SIZE.x, SIZE.y - 2.0), Pal.TICKET)
	if _specks.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = serial
		for i in 40:
			_specks.append(Vector2(rng.randi_range(2, int(SIZE.x) - 4), rng.randi_range(18, int(SIZE.y) - 5)))
	for sp in _specks:
		draw_rect(Rect2(sp, Vector2(2 if int(sp.x) % 3 == 0 else 1, 1)), Pal.TICKET.darkened(0.1))
	draw_rect(Rect2(0, 0, SIZE.x, BAND), Pal.TICKET_FORM)
	PunchCard.write(self, Vector2(6, 12), T.text(T.Key.TOLL_TICKET), Pal.TICKET)
	PunchCard.write(self, Vector2(6, 12), "%04d" % serial, Pal.TICKET, SIZE.x - 12.0, HORIZONTAL_ALIGNMENT_RIGHT)
	var rows := [[T.Key.TOLL_LINE, "%02d" % line], [T.Key.TOLL_TO, "%s %s" % [city.to_upper(), far]],
		[T.Key.TOLL_TIME, "%s–%s" % [Main.fmt(start), Main.fmt(end)]], [T.Key.TOLL_MINUTES, str(minutes())]]
	for i in rows.size():
		var y := 31.0 + i * 16.0
		PunchCard.write(self, Vector2(6, y), T.text(rows[i][0]), Pal.TICKET_FORM)
		PunchCard.write(self, Vector2(VALUE_X, y), rows[i][1], Pal.INK)
		for x in range(int(VALUE_X), int(SIZE.x) - 6, 3):   # a linha de preencher
			draw_rect(Rect2(x, y + 3.0, 1, 1), Color(Pal.TICKET_FORM, 0.6))
	for x in range(int(FIELD.position.x), int(FIELD.end.x), 3):   # o campo do carimbo
		for y: float in [FIELD.position.y, FIELD.end.y - 1.0]:
			draw_rect(Rect2(x, y, 2, 1), Color(Pal.TICKET_FORM, 0.6))
	for y in range(int(FIELD.position.y), int(FIELD.end.y), 3):
		for x: float in [FIELD.position.x, FIELD.end.x - 1.0]:
			draw_rect(Rect2(x, y, 1, 2), Color(Pal.TICKET_FORM, 0.6))
	var label := PixelArt.tiny(T.text(T.Key.TOLL_FIELD))
	draw_texture(label, FIELD.position + Vector2(0, -9), Pal.TICKET_FORM)
	Switchboard.badge(self, Vector2((FIELD.end.x + SIZE.x) / 2.0, FIELD.get_center().y), Pal.TICKET_FORM, Color.TRANSPARENT, 8.0, 10)   # o selo da companhia, ao lado do carimbo
	var bottom := SIZE.y - 2.0
	draw_rect(Rect2(0, 0, SIZE.x, 1), Pal.TICKET_EDGE)   # a beira: em cima e dos lados...
	for x: float in [0.0, SIZE.x - 1.0]:
		draw_rect(Rect2(x, 0, 1, bottom), Pal.TICKET_EDGE)
	for x in range(0, int(SIZE.x), int(TEETH)):   # ...e os dentes embaixo
		draw_rect(Rect2(x, bottom, TEETH - 1.0, 1), Pal.TICKET)
		draw_rect(Rect2(x + TEETH - 1.0, bottom, 1, 1), Pal.TICKET_EDGE)
		draw_rect(Rect2(x, bottom + 1.0, TEETH - 1.0, 1), Pal.TICKET_EDGE)
