extends RefCounted
## Um fio de pano da mesa comutadora: uma corda de Verlet de `N` pontos, presa no buraco (o primeiro) e na traseira do
## plug (o último). Só a física, sem tela nem som (`Switchboard.Cord`, testado direto no teste de fluxo): a mesa diz a
## cada passo onde ficam o buraco e o plug, quanto fio está para fora e o que há em volta (a prateleira, o tampo além
## dela, o mouse), e lê o que aconteceu no passo (o plug e o fio batendo na mesa, quanto fio entrou ou saiu) para
## tocar os sons. Os pontos têm inércia e gravidade e a distância entre eles é mantida; solto, o plug é a última conta
## da corda (cai). Parado por `SLEEP_STEPS` passos, o fio "dorme" e deixa de ser simulado até algo mexer nele.

const N := 22                      ## pontos por fio
const GRAVITY := Vector2(0, 1600)  ## px/s²
const DAMPING := 0.985             ## 1 = sem atrito com o ar
const STIFF_ITER := 14             ## iterações de restrição (maior = fio menos elástico)
const SLEEP_STEPS := 30            ## passos quase parado até dormir
const SLEEP_MOVE := 0.05           ## px por passo: menos que isso conta como parado
## O comprimento dos fios, o mesmo em todos: o do FONE, puxado do encaixe, chega ao meio das listas telefônicas da
## mesa (659 px em 1280 × 720); a tomada mais longe de um buraco fica a 564. Na mão, o plug não passa dele: a mão
## segue e ele para, com o fio esticado (e um tranco, `cord_snag`, ao esticar).
const MAX := 660.0
const STUB := 6.0   ## encaixado, o fio sai da ponteira no eixo do plug por esses px antes de cair...
const BEND := [0.15, 0.06]   ## ...e os pontos seguintes tendem a continuar a direção dos anteriores (curva suave)
## O plug solto quica na mesa: volta com BOUNCE da velocidade com que bateu, enquanto bater a mais de BOUNCE_MIN px/s
## (devagar, assenta). Antes, ele grudava na mesa ao cair.
const BOUNCE := 0.35
const BOUNCE_MIN := 90.0
## Esticado, o fio de pano alisa: a partir de TAUT_FROM do comprimento (`MAX`) entre o buraco e a ponta dele, a tensão
## (`taut`) sobe até 1 no fim do fio, TAUT_EASE por passo (sem piscar). O desenho usa: as dobras somem, o trançado se
## espaça e ele afina (`Switchboard._draw_rope`).
const TAUT_FROM := 0.75
const TAUT_EASE := 0.15

var pts: PackedVector2Array
var old: PackedVector2Array   ## os pontos no passo anterior (a velocidade, no Verlet)
var length := 0.0         ## px de fio para fora do buraco
var taut := 0.0           ## quanto está esticado (0..1)
var hang := false         ## pendurado na quina da prateleira (`hang_step`): reto em dois trechos
var sleep := Rect2()      ## dormindo: a área onde o mouse o acorda (vazia: acordado)
var calm := 0             ## passos quase parado
var tap_wait := 0.0       ## s até o próximo "tap" do fio na mesa poder tocar (a mesa conta)

# o lugar e o estado do plug, que a mesa atualiza antes de cada passo
var floor_y := INF        ## a prateleira (y), até...
var ground := Vector2(INF, INF)   ## ...a lateral do console (x); além dela, o tampo (y). INF: sem fim (sem cenário)
var free := false         ## solto: o plug é a última conta e cai junto (não segue a ponta)
var direct := false       ## solto e puxado direto para o buraco: esticado, sem gravidade e quase sem embalo
var held := false         ## o plug na mão: o mouse não empurra o fio e ele não dorme
var stub := Vector2.ZERO  ## encaixado: a direção em que o fio sai da ponteira (zero: em pé)
var mouse := Vector2.INF
var nudge := Vector2.ZERO ## quanto o mouse andou no passo: passando por cima do fio, empurra

# o que aconteceu no último passo (para os sons e o plug solto)
var pulled := 0.0         ## px de fio que saíram do buraco (negativo: entraram)
var drop := 0.0           ## px/s do plug solto batendo na mesa (0: não bateu)
var drop_at := Vector2.ZERO
var tap := 0.0            ## px/passo da batida mais forte de um ponto do fio na mesa, e onde
var tap_at := Vector2.ZERO
var swing := NAN          ## pendurado: o ângulo do fio do plug em volta da quina (NAN: chegou a ela)


## O fio para fora, reto, do buraco `a` até `to`.
func _init(a: Vector2, to: Vector2) -> void:
	for i in N:
		pts.append(a.lerp(to, float(i) / (N - 1)))
	old = pts.duplicate()
	length = a.distance_to(to)


## Onde o fio entra no plug (solto, onde o plug está).
func tip() -> Vector2:
	return pts[N - 1]


func asleep() -> bool:
	return sleep.has_area()


## Um passo de `dt` s, com o buraco em `a`, a traseira do plug em `b` (solto, não vale: ele cai) e `want` px de fio
## para fora. Devolve false se o fio dormia e nada mexeu nele (nada mudou).
func step(dt: float, a: Vector2, b: Vector2, want: float) -> bool:
	pulled = 0.0
	drop = 0.0
	tap = 0.0
	var last := N - 1
	var settled := not held and not free
	if asleep():
		var poked := nudge.length_squared() > 0.5 and sleep.has_point(mouse)
		if settled and pts[0] == a and pts[last] == b and not poked:
			return false
		sleep = Rect2()
	var p := pts
	var o := old
	var seg := want / last
	# inércia + gravidade
	var moving := last + 1 if free else last
	for i in range(1, moving):
		var v := (p[i] - o[i]) * DAMPING
		o[i] = p[i]
		if direct:
			p[i] += v * 0.5   # puxado direto: fio esticado, sem gravidade e quase sem embalo (o plug não pendula)
			continue
		p[i] += v + GRAVITY * dt * dt
		var under := _surface(p[i], o[i])
		if p[i].y > under:
			if i == last:   # o plug solto bate na mesa...
				drop = v.y / dt
				drop_at = p[i]
				if drop > BOUNCE_MIN:   # ...e quica: volta para cima com parte da velocidade
					p[i].y = under
					o[i].y = under + v.y * BOUNCE
			elif v.y > tap:
				tap = v.y
				tap_at = p[i]
		# passar o mouse por cima do fio empurra o fio
		if not held and nudge.length_squared() > 0.5 and p[i].distance_to(mouse) < 16.0:
			p[i] += nudge * 0.35
	p[0] = a
	var pin := last   # daqui até o plug, o fio não se mexe
	if not free:
		p[last] = b
		o[last] = b
	if stub != Vector2.ZERO:   # encaixado, o fio sai da ponteira no eixo do plug antes de cair
		pin = last - 1
		p[pin] = p[last] + stub * minf(seg, STUB)
		o[pin] = p[pin]
		for k in BEND.size():   # e faz a curva aos poucos, como um fio de verdade
			var i := pin - 1 - k
			p[i] = p[i].lerp(p[i + 1] + (p[i + 1] - p[i + 2]).normalized() * seg, BEND[k])
	# restrições de comprimento
	for _it in STIFF_ITER:
		for i in pin:
			var d := p[i + 1] - p[i]
			var l := d.length()
			if l < 0.0001:
				continue
			var corr := d * ((l - seg) / l)
			if i == 0:
				p[i + 1] -= corr
			elif i + 1 == pin and not free:
				p[i] += corr
			else:
				p[i] += corr * 0.5
				p[i + 1] -= corr * 0.5
		for i in range(1, moving):
			if p[i].x < ground.x and p[i].y > floor_y and o[i].x >= ground.x and o[i].y > floor_y:
				p[i].x = ground.x   # veio de fora, por baixo da prateleira: bate na lateral do console
				o[i].y = lerpf(o[i].y, p[i].y, 0.3)   # atrito com ela
				continue
			var under := _surface(p[i], o[i])
			if p[i].y > under:   # repousa na prateleira, à frente do painel, ou no tampo além dela
				p[i].y = under
				o[i].x = lerpf(o[i].x, p[i].x, 0.3)   # atrito com a mesa
	pts = p
	old = o
	pulled = want - length
	length = want
	_tension(p[0].distance_to(p[last]))
	hang = false
	var moved := 0.0
	for i in range(1, last):
		moved = maxf(moved, p[i].distance_squared_to(o[i]))
	calm = calm + 1 if settled and moved < SLEEP_MOVE * SLEEP_MOVE else 0
	if calm > SLEEP_STEPS:
		var box := Rect2(p[0], Vector2.ZERO)
		for q in p:
			box = box.expand(q)
		sleep = box.grow(16.0)
	return true


## O plug solto recolhendo, ao lado do console, abaixo da prateleira: a quina dela é uma roldana. O fio vai reto do
## buraco `a` até a quina e dali até o plug, que balança preso nela como um pêndulo (sem passar para dentro do console
## nem do tampo); recolhendo, o pedaço de fora encurta e o iça até a quina, onde ele volta para cima da prateleira e
## para a corda de sempre. (Com a corda solta contra a quina, ele ficava preso, laçava ou era arremessado.)
## Devolve se cuidou do passo (o plug estava pendurado).
func hang_step(dt: float, a: Vector2, want: float) -> bool:
	var last := N - 1
	var q := pts[last]
	if q.x < ground.x - 0.5 or q.y <= floor_y:
		return false
	pulled = 0.0
	drop = 0.0
	tap = 0.0
	swing = NAN
	var p := pts
	var o := old
	var lip := Vector2(ground.x, floor_y)
	var out := want - a.distance_to(lip)   # o fio do lado de fora da quina
	if out <= 1.0:   # chegou à quina: sobe na prateleira
		q = lip + Vector2(-2.0, -1.0)
		o[last] = q
	else:
		var v := (q - o[last]) * DAMPING
		o[last] = q
		q += v + GRAVITY * dt * dt
		if q.distance_to(lip) > out:
			q = lip + (q - lip).normalized() * out
		q.x = maxf(q.x, ground.x)   # encostado na lateral do console
		q.y = minf(q.y, ground.y)   # ou no tampo
		swing = (q - lip).angle() + PI / 2
	# o fio esticado: do buraco à quina e dela ao plug
	var path := PackedVector2Array([a, lip, q])
	var total := a.distance_to(lip) + lip.distance_to(q)
	for i in last:
		var part := along(path, 0.0, total * i / last)
		p[i] = part[part.size() - 1] if part.size() > 0 else a
		o[i] = p[i]
	p[last] = q
	pts = p
	old = o
	_tension(total)   # pendurado na quina, o caminho todo conta
	hang = true
	pulled = want - length
	length = want
	return true


## Quanto o fio está esticado, pela distância `reach` do buraco até a ponta dele (`TAUT_*`).
func _tension(reach: float) -> void:
	taut = lerpf(taut, clampf((reach / MAX - TAUT_FROM) / (1.0 - TAUT_FROM), 0.0, 1.0), TAUT_EASE)


## A altura da superfície sob o ponto p (vindo de q): a prateleira até a lateral do console, o tampo além dela. Quem
## está fora, abaixo da prateleira, continua fora (bate na lateral, não sobe para cima dela).
func _surface(p: Vector2, q: Vector2) -> float:
	if p.x < ground.x and not (q.x >= ground.x and q.y > floor_y):
		return floor_y
	return ground.y


## O trecho da linha `line` entre `from` e `to` px a partir do começo dela.
static func along(line: PackedVector2Array, from: float, to: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var run := 0.0
	for i in line.size() - 1:
		var d := line[i].distance_to(line[i + 1])
		if d > 0.0 and run + d > from:
			out.append(line[i].lerp(line[i + 1], clampf((maxf(from, run) - run) / d, 0.0, 1.0)))
			if run + d >= to:
				out.append(line[i].lerp(line[i + 1], (to - run) / d))
				return out
		run += d
	if not out.is_empty():
		out.append(line[line.size() - 1])
	return out
