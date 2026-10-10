class_name TollTicket
extends Control
## O bilhete de tarifação que o calculógrafo (`Toll`) imprime quando acaba uma ligação interurbana: uma tira de papel
## fino com o formulário impresso em azul (a faixa com o número, os rótulos e as linhas de preencher) e, datilografados
## em preto, a entrada, a cidade e o número de lá, o horário e os minutos. Fica solto na mesa do calculógrafo (`Toll`,
## que o leva e o solta; na mão, sobe como o cartão do despacho, `Lift`); o carimbo solto em cima dele deixa a marca
## vermelha onde o meio dele caiu (`stamp`), mais fraca com a borracha secando.

const SIZE := Vector2(190, 92)   ## o título e o número lado a lado na faixa (em 176, encostavam)
const PAPER := Color("e4dcc0")
const EDGE := Color("a89c78")
const FORM := Color("34507e")   ## o formulário vem impresso em azul (o cartão do despacho, em vermelho)
const MARK := Color("b03a2e")   ## a tinta do carimbo
const MARK_SIZE := Vector2(124, 30)   ## na largura do nome da central em inglês, o mais longo
const VALUE_X := 62.0   ## onde começam os dados, à direita dos rótulos

var serial := 0
var line := 0
var city := ""
var far := ""        ## o número na outra cidade
var start := 0.0     ## o minuto do turno em que a outra ponta atendeu...
var end := 0.0       ## ...e o em que a conversa acabou
var stamped := false       ## carimbado com tinta (a marca da borracha seca não vale)
var mark := Vector2.ZERO   ## o meio da marca do carimbo (coordenadas do bilhete)
var ink := -1.0            ## a tinta da marca: 1 cheia, mais fraca a cada batida, 0 seca (só o vulto); -1 = sem marca
var top := 0.0             ## saindo da fenda (`Toll._emerge`): o quanto dele ainda está lá dentro
## Na mão (`Toll`): sobe; solto, cai de volta na mesa.
var held := false:
	set(v):
		held = v
		_lift.held = v
		set_process(true)

var _lift := Lift.new()


func _init() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # a mesa (`Toll`) pega e leva


## Os minutos cobrados: o primeiro conta inteiro, e os outros, começados.
func minutes() -> int:
	return maxi(1, ceili(end - start - 0.01))


## Quem é, no relatório do supervisor: a entrada e a cidade.
func detail() -> String:
	return "%s · %s" % [T.text(T.Key.LINE_N) % line, city]


## Carimba com o meio da marca em `at` (dentro do bilhete), com a tinta `wet` da borracha (0 = seca: não vale).
func stamp(at: Vector2, wet := 1.0) -> void:
	stamped = wet > 0.0
	ink = wet
	mark = at.clamp(MARK_SIZE / 2.0 + Vector2(3, 3), SIZE - MARK_SIZE / 2.0 - Vector2(3, 3))
	queue_redraw()


## A marca do carimbo em `mark`: o fio duplo, "TARIFADO" e o nome da central na letra miúda, com falhas da tinta
## (cada bilhete as suas, pelo número; com menos tinta, mais claras e mais falhas).
func _draw_mark() -> void:
	var r := Rect2((mark - MARK_SIZE / 2.0).round(), MARK_SIZE)
	var tint := Color(MARK, lerpf(0.15, 0.85, ink))
	var gaps := 1 + roundi((1.0 - ink) * 5.0)   # de cada 13 (ou 11) pontos do fio, quantos falham
	var n := serial
	for k in 2:
		var b := r.grow(-k * 2.0)
		for x in range(int(b.position.x), int(b.end.x)):
			for y: float in [b.position.y, b.end.y - 1.0]:
				if posmod(x * 7 + int(y) * 3 - n, 13) >= gaps:
					draw_rect(Rect2(x, y, 1, 1), tint)
		for y in range(int(b.position.y), int(b.end.y)):
			for x: float in [b.position.x, b.end.x - 1.0]:
				if posmod(y * 5 + int(x) - n, 11) >= gaps:
					draw_rect(Rect2(x, y, 1, 1), tint)
	PunchCard.write(self, Vector2(r.position.x, r.position.y + 15.0), T.text(T.Key.TOLL_STAMP), tint, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var central := PixelArt.tiny(T.text(T.Key.GAME_TITLE))
	draw_texture(central, Vector2(floorf(mark.x - central.get_width() / 2.0), r.end.y - 10.0), tint)


func _process(delta: float) -> void:
	if not _lift.step(delta):
		set_process(false)
	scale = _lift.scale()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


## Sempre no tamanho inteiro (`SIZE`): entrando na caixinha, a altura encolhe e recorta (`clip_contents`, `Toll._sink`);
## saindo da fenda, também, e o desenho sobe o que ainda está lá dentro (`top`).
func _draw() -> void:
	draw_set_transform(Vector2(0, -top))
	draw_rect(Rect2(_lift.shadow(), SIZE), Lift.SHADOW)   # a sombra na mesa
	draw_rect(Rect2(Vector2.ZERO, SIZE), PAPER)
	draw_rect(Rect2(0, 0, SIZE.x, 16), FORM)
	PunchCard.write(self, Vector2(6, 12), T.text(T.Key.TOLL_TICKET), PAPER)
	PunchCard.write(self, Vector2(6, 12), "%04d" % serial, PAPER, SIZE.x - 12.0, HORIZONTAL_ALIGNMENT_RIGHT)
	var rows := [[T.Key.TOLL_LINE, "%02d" % line], [T.Key.TOLL_TO, "%s %s" % [city.to_upper(), far]],
		[T.Key.TOLL_TIME, "%s–%s" % [Main.fmt(start), Main.fmt(end)]], [T.Key.TOLL_MINUTES, str(minutes())]]
	for i in rows.size():
		var y := 31.0 + i * 16.0
		PunchCard.write(self, Vector2(6, y), T.text(rows[i][0]), FORM)
		PunchCard.write(self, Vector2(VALUE_X, y), rows[i][1], Pal.INK)
		for x in range(int(VALUE_X), int(SIZE.x) - 6, 3):   # a linha de preencher
			draw_rect(Rect2(x, y + 3.0, 1, 1), Color(FORM, 0.6))
	draw_rect(Rect2(Vector2.ZERO, SIZE), EDGE, false, 1.0)
	if ink >= 0.0:
		_draw_mark()
