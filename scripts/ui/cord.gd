extends RefCounted
## Um fio de pano da mesa comutadora: uma corda de Verlet presa no buraco (o primeiro ponto) e na traseira do plug (o
## último), com um ponto a cada `SEG` px de fio para fora (mais fio, mais pontos: a física fica igual de fina no fio
## curto e no longo). Só a física, sem tela nem som (`Switchboard.Cord`, testado direto no teste de fluxo): a mesa diz
## a cada passo onde ficam o buraco e o plug, quanto fio está para fora e o que há em volta (a prateleira, o tampo
## além dela, o mouse), e lê o que aconteceu no passo (o plug e o fio batendo na mesa, quanto fio entrou ou saiu) para
## tocar os sons. Os pontos têm inércia e gravidade; a distância entre vizinhos é mantida e a rigidez do pano é outra
## regra, a mesma em qualquer comprimento (`BEND_MIN`). Solto, o plug é a última conta da corda (cai). Parado por
## `SLEEP_STEPS` passos, o fio "dorme" e deixa de ser simulado até algo mexer nele.

const SEG := 16.0                  ## px de fio entre dois pontos (com 22 pontos fixos, o fio longo tinha trechos de 30 px)
const MIN_N := 5                   ## pontos, no mínimo (o fio quase todo dentro do buraco)
const GRAVITY := Vector2(0, 1600)  ## px/s²
const DAMPING := 0.985             ## 1 = sem atrito com o ar
const STIFF_ITER := 16            ## iterações das regras (indo e voltando, alternadas: maior = fio menos elástico)
const SLEEP_STEPS := 30            ## passos quase parado até dormir
const SLEEP_MOVE := 0.05           ## px por passo: menos que isso conta como parado
## O comprimento dos fios, o mesmo em todos: o do FONE, puxado do encaixe, chega ao meio das listas telefônicas da
## mesa (659 px em 1280 × 720); a tomada mais longe de um buraco fica a 564. Na mão, o plug não passa dele: a mão
## segue e ele para, com o fio esticado (e um tranco, `cord_snag`, ao esticar).
const MAX := 660.0
const MAX_N := int(MAX / SEG) + 2
## A rigidez do pano: cada ponto fica a pelo menos BEND_MIN de dois trechos do ponto dois adiante (o fio não dobra
## mais que ~50° por ponto, uma curva de uns 18 px de raio), corrigido BEND_K por iteração. Antes era um empurrão
## nos pontos perto do plug, uma vez por passo, que as outras regras desfaziam: duro no fio longo, gancho no curto.
const BEND_MIN := 0.9
const BEND_K := 0.3
## A beira da frente da prateleira (`lip_y`; além da lateral do console, a borda da frente do tampo, `ground.y`) é uma
## quina: com o plug abaixo dela, na frente do console (na mão, ou solto e pendurado), o fio vai pela prateleira até
## ela, passa por cima e fica no ar até o plug, pendendo com a gravidade. O ponto conta como no ar a AIR_GAP px abaixo
## dela, medido antes do passo (o que repousa no tampo, na borda, não cai através dele). Antes, tudo abaixo da prateleira
## era um bloco: o fio fazia um nó nela e atravessava o console, ou ficava reto do buraco à mão.
const AIR_GAP := 4.0
const RISE := 4.0    # px por passo que um ponto que estava no ar sobe ao voltar para a prateleira ou o tampo
const LIP_PTS := 2   # quantos pontos antes da beira podem estar no tampo da prateleira, entre os buracos e ela
const STUB := 6.0   ## encaixado, o fio sai da ponteira no eixo do plug por esses px; a rigidez faz o resto da curva
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
var floor_y := INF        ## a prateleira (y, a linha dos buracos), até...
var ground := Vector2(INF, INF)   ## ...a lateral do console (x); além dela, o tampo (y). INF: sem fim (sem cenário)
var lip_y := INF          ## a beira da frente da prateleira (y): abaixo dela, na frente do console, é o ar (`AIR_GAP`)
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
var air := -1             ## o primeiro ponto no ar, depois da beira (-1: o fio todo na prateleira ou no tampo)
var cross := Vector2.ZERO ## onde o fio passa pela beira (com `air`) ou pela quina em que pende (`hang`)
var over := 0.0           ## px de fio que passaram pela beira no passo (negativo: voltaram), para o atrito, e onde
var over_at := Vector2.ZERO
var edge_x := NAN         ## pendurado na beira da frente: o x de onde ele pende (NAN: na quina da lateral, ou solto)
var crossed := 0.0        ## px de fio do buraco até a beira (com `air`), pela prateleira
var _crossed := NAN       # o mesmo, no passo anterior
var swing := NAN          ## pendurado: o ângulo do fio do plug em volta da quina (NAN: chegou a ela)


## O fio para fora, reto, do buraco `a` até `to`.
func _init(a: Vector2, to: Vector2) -> void:
	length = a.distance_to(to)
	var n := count(length)
	for i in n:
		pts.append(a.lerp(to, float(i) / (n - 1)))
	old = pts.duplicate()


## Quantos pontos tem um fio com `want` px para fora.
static func count(want: float) -> int:
	return clampi(ceili(want / SEG) + 1, MIN_N, MAX_N)


## Refaz os pontos para `n`, ao longo do fio (e as posições anteriores junto, para não perder a velocidade): o fio
## que sai do buraco ganha pontos, o que entra perde. As pontas ficam onde estão.
func _resize(n: int) -> void:
	if n == pts.size():
		return
	var m := pts.size() - 1
	var p := PackedVector2Array()
	var o := PackedVector2Array()
	p.resize(n)
	o.resize(n)
	for k in n:
		var at := float(k) * m / (n - 1)
		var i := mini(int(at), m - 1)
		p[k] = pts[i].lerp(pts[i + 1], at - i)
		o[k] = old[i].lerp(old[i + 1], at - i)
	pts = p
	old = o


## Onde o fio entra no plug (solto, onde o plug está).
func tip() -> Vector2:
	return pts[pts.size() - 1]


func asleep() -> bool:
	return sleep.has_area()


## Um passo de `dt` s, com o buraco em `a`, a traseira do plug em `b` (solto, não vale: ele cai) e `want` px de fio
## para fora. Devolve false se o fio dormia e nada mexeu nele (nada mudou).
func step(dt: float, a: Vector2, b: Vector2, want: float) -> bool:
	pulled = 0.0
	drop = 0.0
	tap = 0.0
	if asleep():
		var poked := nudge.length_squared() > 0.5 and sleep.has_point(mouse)
		var settled_now := not held and not free
		if settled_now and pts[0] == a and pts[pts.size() - 1] == b and not poked:
			return false
		sleep = Rect2()
	_resize(count(want))
	var last := pts.size() - 1
	var settled := not held and not free
	var p := pts
	var o := old
	var seg := want / last
	# daqui em diante, no ar: a prateleira e o tampo não seguram. Na mão, o plug está erguido e o fio sai sempre pela
	# beira da prateleira (a mesma mão dá o mesmo fio, subindo ou descendo); solto, só com ele no ar (deitado no tampo,
	# o fio vem por cima)
	air = _first_air(p) if held or _in_air(b if not free else p[last]) else -1
	var moving := last + 1 if free else last
	# inércia + gravidade
	for i in range(1, moving):
		var v := (p[i] - o[i]) * DAMPING
		o[i] = p[i]
		if direct:
			p[i] += v * 0.5   # puxado direto: fio esticado, sem gravidade e quase sem embalo (o plug não pendula)
			continue
		p[i] += v + GRAVITY * dt * dt
		var under := _under(i, p[i], o[i])
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
	if stub != Vector2.ZERO:   # encaixado, o fio sai da ponteira no eixo do plug
		pin = last - 1
		p[pin] = p[last] + stub * minf(seg, STUB)
		o[pin] = p[pin]
	var fixed := last + 1 if free else pin   # os pontos daqui em diante estão presos (o 0 também)
	var bend := BEND_MIN * 2.0 * seg
	for it in STIFF_ITER:
		var back := it % 2 == 1   # ida e volta: a correção atravessa o fio inteiro em menos iterações
		for k in pin:   # o comprimento de cada trecho
			var i := pin - 1 - k if back else k
			_keep(p, i, i + 1, seg, fixed, 1.0, false)
		for k in range(0, pin - 1):   # a rigidez: o ponto dois adiante não chega perto demais
			var i := pin - 2 - k if back else k
			_keep(p, i, i + 2, bend, fixed, BEND_K, true)
		if pin < last:   # e na saída da ponteira, contando o trecho curto do eixo do plug (sem isso, dobrava ali)
			_keep(p, pin - 1, last, BEND_MIN * (seg + p[pin].distance_to(p[last])), fixed, BEND_K, true)
		for i in range(1, moving if air < 0 else air):
			if p[i].x < ground.x and p[i].y > floor_y and o[i].x >= ground.x and o[i].y > floor_y:
				p[i].x = ground.x   # veio de fora, por baixo da prateleira: bate na lateral do console
				o[i].y = lerpf(o[i].y, p[i].y, 0.3)   # atrito com ela
				continue
			var under := _under(i, p[i], o[i])
			if p[i].y > under:   # repousa na prateleira, à frente do painel, ou no tampo além dela
				# o que estava no ar sobe pela beira aos poucos, puxado (de uma vez, o fio saltava para a prateleira)
				p[i].y = maxf(under, o[i].y - RISE) if _in_air(o[i]) else under
				o[i].x = lerpf(o[i].x, p[i].x, 0.3)   # atrito com a mesa
	pts = p
	old = o
	pulled = want - length
	length = want
	_tension(length_of(route(p[0], p[last])))
	hang = false
	edge_x = NAN
	_over(seg)
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


## Leva os pontos `i` e `j` à distância `d` (com `at_least`, só os afasta), `k` da diferença por vez, dividida entre os
## dois; o 0 e os de `fixed` em diante não se mexem.
static func _keep(p: PackedVector2Array, i: int, j: int, d: float, fixed: int, k: float, at_least: bool) -> void:
	var gap := p[j] - p[i]
	var l := gap.length()
	if l < 0.0001 or (at_least and l >= d):
		return
	var mi := 0.0 if i == 0 or i >= fixed else 1.0
	var mj := 0.0 if j >= fixed else 1.0
	if mi + mj == 0.0:
		return
	var corr := gap * ((l - d) / l * k / (mi + mj))
	p[i] += corr * mi
	p[j] -= corr * mj


## Até onde o ponto `i` desce (o de antes do passo em `q`): no ar, sem limite; os últimos antes da beira atravessam o
## tampo da prateleira até ela (presos na linha dos buracos, eles subiam a cada passo e o fio dava chicotadas).
func _under(i: int, p: Vector2, q: Vector2) -> float:
	if air >= 1 and i >= air:
		return INF
	var y := _surface(p, q)
	return _edge(p.x) if air >= 1 and i >= air - LIP_PTS and y == floor_y else y


## A beira sob o x `x`: a da frente da prateleira até a lateral do console, a borda da frente do tampo além dela.
func _edge(x: float) -> float:
	return lip_y if x < ground.x else ground.y


## Se `q` está no ar, abaixo da beira, na frente do console ou do tampo.
func _in_air(q: Vector2) -> bool:
	return q.y > _edge(q.x) + AIR_GAP


## O primeiro ponto de `p` abaixo da beira da prateleira, no ar (-1: nenhum). Também na frente do tampo: deitado
## nele até a borda, o fio fazia um "Z" ali e tinha outra forma que o da mesma mão vinda de baixo.
func _first_air(p: PackedVector2Array) -> int:
	for i in range(1, p.size()):
		if p[i].y > lip_y + AIR_GAP:
			return i
	return -1


## Onde o fio passa pela beira (`cross`) e quanto dele passou por ela desde o passo anterior (`over`, o atrito).
func _over(seg: float) -> void:
	over = 0.0
	if air < 1:
		_crossed = NAN
		return
	var u := pts[air - 1]
	var w := pts[air]
	var e := lip_y
	var k := clampf((e - u.y) / maxf(w.y - u.y, 0.001), 0.0, 1.0)
	cross = u.lerp(w, k)
	crossed = (air - 1 + k) * seg
	if not is_nan(_crossed):
		over = crossed - _crossed
		over_at = cross
	_crossed = crossed


## O plug solto recolhendo, pendurado: abaixo da prateleira, ao lado do console, a quina dela é uma roldana; na frente
## do console, a beira da frente da prateleira (ou do tampo) onde o fio passou. O fio vai reto do buraco `a` até ela
## (pela quina da lateral, se ele pende do tampo) e dali até o plug, que balança preso nela como um pêndulo (sem passar
## para dentro do console nem do tampo); recolhendo, o pedaço de fora encurta e o iça até ela, onde ele volta para
## cima da prateleira (ou do tampo) e para a corda de sempre. (Com a corda solta contra a quina, ele ficava preso, laçava
## ou era arremessado.) Devolve se cuidou do passo (o plug estava pendurado).
func hang_step(dt: float, a: Vector2, want: float) -> bool:
	var q := pts[pts.size() - 1]
	var corner := Vector2(ground.x, floor_y)
	var route := PackedVector2Array([a])   # do buraco até onde ele pende
	if q.y > _edge(q.x) + AIR_GAP or not is_nan(edge_x):   # na frente: pende da beira
		if is_nan(edge_x):
			edge_x = cross.x if air >= 1 else q.x
		if edge_x >= ground.x:
			route.append(corner)
		route.append(Vector2(edge_x, _edge(edge_x)))
	elif q.x >= ground.x - 0.5 and q.y > floor_y:   # ao lado do console: pende da quina
		route.append(corner)
	else:
		return false
	_resize(count(want))
	var last := pts.size() - 1
	pulled = 0.0
	drop = 0.0
	tap = 0.0
	swing = NAN
	var p := pts
	var o := old
	var lip := route[route.size() - 1]
	var spent := 0.0
	for i in route.size() - 1:
		spent += route[i].distance_to(route[i + 1])
	var out := want - spent   # o fio do lado de fora da quina
	if out <= 1.0:   # chegou à quina: sobe na prateleira (ou no tampo)
		q = lip + Vector2(-2.0, -1.0) if is_nan(edge_x) else Vector2(q.x, minf(floor_y if q.x < ground.x else ground.y, lip.y) - 1.0)
		o[last] = q
		if not is_nan(edge_x):   # da beira da frente, o fio vai reto do buraco a ele (pela beira, empurrava o plug para cima)
			route = PackedVector2Array([a])
			spent = 0.0
		edge_x = NAN
	else:
		var v := (q - o[last]) * DAMPING
		o[last] = q
		q += v + GRAVITY * dt * dt
		if q.distance_to(lip) > out:
			q = lip + (q - lip).normalized() * out
		if is_nan(edge_x):
			q.x = maxf(q.x, ground.x)   # encostado na lateral do console
			q.y = minf(q.y, ground.y)   # ou no tampo
		else:
			q.y = maxf(q.y, lip.y)   # na frente do console, abaixo da beira
		swing = (q - lip).angle() + PI / 2
	# o fio esticado: do buraco à quina e dela ao plug
	var total := spent + route[route.size() - 1].distance_to(q)
	route.append(q)
	air = -1
	for i in last:
		var part := along(route, 0.0, total * i / last)
		p[i] = part[part.size() - 1] if part.size() > 0 else a
		o[i] = p[i]
		if air < 0 and total * i / last > spent and not is_nan(edge_x):
			air = i
	p[last] = q
	pts = p
	old = o
	cross = lip
	_tension(total)   # pendurado na quina, o caminho todo conta
	hang = true
	pulled = want - length
	over = pulled   # o fio que entra no buraco passou antes pela quina
	over_at = lip
	_crossed = NAN
	length = want
	return true


## O caminho do fio esticado do buraco `a` até `q`: reto ou, com o plug solto deitado no tampo além da lateral do
## console e a reta passando por dentro dele, pela quina da prateleira (reto, o fio atravessava o console). Na mão, o
## plug está erguido e o fio vai reto, pela beira: o limite da mão não salta quando ele passa pela borda do tampo.
func route(a: Vector2, q: Vector2) -> PackedVector2Array:
	var corner := Vector2(ground.x, floor_y)
	if not held and q.x > ground.x and q.y > floor_y and not _in_air(q) and a.x < ground.x:
		if lerpf(a.y, q.y, (ground.x - a.x) / (q.x - a.x)) > floor_y:
			return PackedVector2Array([a, corner, q])
	return PackedVector2Array([a, q])


## O comprimento da linha `line`.
static func length_of(line: PackedVector2Array) -> float:
	var total := 0.0
	for i in line.size() - 1:
		total += line[i].distance_to(line[i + 1])
	return total


## O ponto a `d` px do começo da linha `line`.
static func point_at(line: PackedVector2Array, d: float) -> Vector2:
	for i in line.size() - 1:
		var run := line[i].distance_to(line[i + 1])
		if d <= run or i == line.size() - 2:
			return line[i].lerp(line[i + 1], clampf(d / maxf(run, 0.001), 0.0, 1.0))
		d -= run
	return line[0]


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
