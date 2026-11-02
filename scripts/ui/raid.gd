extends RefCounted
## A batida no hotel da noite 13 (`StreetEvent` "raid"), às 20h, antes do toque de recolher (a cena esvazia a rua:
## nenhum carro nem gente nova): um camburão
## (cabine preta e o cofre branco, a sirene girando) para junto do meio-fio de lá, logo depois da porta do hotel, e uma
## viatura logo atrás dele, `LATE` s depois. O motorista do camburão desce pela porta do lado de cá (`cab`), fica de
## guarda na traseira; os outros três (o do lado da calçada do camburão e os dois da viatura) entram no hotel. Lá
## dentro, as luzes dos andares acendem uma a uma (`floors`). Saem em fila: um policial na frente, os cinco presos
## algemados, de cabeça baixa, com um policial no meio e outro no fim; pela calçada, atrás do camburão, e descem para
## a rua no vão entre ele e a viatura, na traseira, onde o da guarda já abriu as duas portas do cofre (`rear`); cada
## preso sobe o degrau e some lá dentro.
## O da guarda fecha as portas (a de lá, depois a de cá), e cada um volta para o seu carro: o camburão sai, a viatura
## atrás. As luzes dos andares ficam acesas. Só o roteiro, como o `Beating`: tudo sai do tempo `t` (s desde que o
## camburão aparece), sem estado.

const Beating := preload("res://scripts/ui/beating.gd")
const VAN := "camburao"
const PATROL := "sedan"
const PARK := Vector2(6.4, 7.45)   ## a mão de lá (`CAR_LANES[0]`) e onde os dois encostam (z, m), como a Kombi
## Onde a frente do camburão para (x, m): na frente do hotel, quase na beira da janela (a porta, `Background.HOTEL_X`
## -6,3, fica atrás da cabine; só o alto dela aparece); o comprimento dele e da viatura, e o vão entre os dois.
const VAN_FRONT := -7.2
const VAN_LEN := 5.3
const PATROL_LEN := 4.5
const GAP := 2.4
const REAR := VAN_FRONT + VAN_LEN   ## a traseira do camburão (x, m)
const VAN_MID := VAN_FRONT + VAN_LEN / 2.0
const PATROL_MID := REAR + GAP + PATROL_LEN / 2.0
const LATE := 1.5      ## quanto a viatura chega depois do camburão (s)
const ARRIVE := 3.2    ## quando o camburão para (`Background.TAXI_STOP.x`)
## As portas do lado de cá, do motorista (x da dobradiça e do fim delas, m): no camburão e na viatura.
const VAN_CAB := Vector2(VAN_FRONT + 1.55, VAN_FRONT + 2.6)
const PATROL_CAB := Vector2(REAR + GAP + 1.1, REAR + GAP + 2.3)
const NEAR := 6.05     ## por onde se anda na rua, na frente dos carros (z, m)
const SIDE := PARK.y - 0.92   ## o lado de cá dos carros estacionados (z, m): as portas das cabines
const CURB := 8.65     ## e na calçada, atrás deles
const HOTEL := Vector2(-6.3, 10.2)   ## dentro da porta do hotel (`HOTEL_X`, a fachada mais 0,8 m: quem entra some nela)
const DOWN := Vector2(REAR + 1.3, PARK.y - 0.1)   ## por onde se desce da calçada para a rua: no vão entre o camburão e a viatura
const WALK := 1.5      ## m/s, os policiais
const LINE := 1.0      ## m/s, a fila dos presos
const DOOR_SEC := Vector2(0.5, 0.4)   ## quanto a porta da cabine leva abrindo e fechando (s)
const REAR_SEC := Vector2(1.0, 0.7)   ## e cada porta do cofre
const REAR_OPEN := Vector2(265.0, 95.0)   ## o quanto cada porta do cofre abre (graus: a de cá dobra rente ao lado, a de lá fica para trás)
const EXIT := 46.0     ## quando a fila sai do hotel (s)
const SPACE := 2.8     ## de um preso para o outro na fila (s)
const CLIMB := 2.4     ## o tempo de cada um subindo e entrando no cofre (s)
const FLOORS := [18.0, 25.0, 32.0]   ## quando acende cada andar do hotel (os policiais subindo)
const STEP_UP := 0.4   ## a altura do degrau do cofre (m)
## Onde o da guarda fica abrindo e fechando as portas do cofre (fora do giro delas) e ajudando cada um a subir (do lado
## de cá do vão), e onde cada preso para, atrás do cofre, antes de subir (x, z; m).
const OPENER := Vector2(REAR + 1.2, PARK.y - 0.1)
const HELPER := Vector2(REAR + 0.3, PARK.y - 0.7)
const STAND := Vector2(REAR + 0.75, PARK.y)
## Os presos: [a camisa, a calça, a pele, o tamanho]
const PRISONERS := [[0, 0, 1, 1.0], [1, 1, 3, 1.04], [2, 2, 0, 0.96], [3, 1, 2, 1.0], [4, 0, 1, 0.98]]

static var _tracks := {}
static var _in := {}   # quando cada um entra no carro ou no cofre
static var _rear := Vector4(INF, INF, INF, INF)   # as portas do cofre: a de cá abre, a de lá abre, a de lá fecha, a de cá fecha (s)
static var _cab := [[], []]   # as portas da cabine do lado de cá (camburão, viatura): [abre, fecha] de cada vez


## Quem está na cena no instante `t` (cada um entre aparecer e entrar no hotel, no carro ou no cofre). `clip` diz por
## onde ele aparece só em parte: "rear" (entrando no cofre), "van" ou "patrol" (na porta da cabine).
static func figures(t: float) -> Array:
	if t < 0.0:
		return []
	_build_all()
	var out := []
	for id: String in _tracks:
		var track: Array = _tracks[id]
		if t >= track[0][0] and t < track[-1][0]:
			var p := Beating._at(track, t)
			if not p.get("hidden", false):   # (dentro do hotel)
				out.append(p)
	return out


## O quanto a porta da cabine do lado de cá do carro `car` (0 o camburão, 1 a viatura) está aberta (0 a 1).
static func cab(t: float, car: int) -> float:
	_build_all()
	var open := 0.0
	for d: Vector2 in _cab[car]:
		open = maxf(open, clampf((t - d.x) / DOOR_SEC.x, 0.0, 1.0) * (1.0 - clampf((t - d.y) / DOOR_SEC.y, 0.0, 1.0)))
	return open


## O quanto cada porta do cofre está aberta (0 a 1): Vector2(a de cá, a de lá).
static func rear(t: float) -> Vector2:
	_build_all()
	return Vector2(smoothstep(_rear.x, _rear.x + REAR_SEC.x, t) - smoothstep(_rear.w, _rear.w + REAR_SEC.y, t),
		smoothstep(_rear.y, _rear.y + REAR_SEC.x, t) - smoothstep(_rear.z, _rear.z + REAR_SEC.y, t))


## Quando as portas do cofre batem (s), para o som.
static func rear_slams() -> Array:
	_build_all()
	return [_rear.z + REAR_SEC.y, _rear.w + REAR_SEC.y]


## Quantos andares do hotel estão acesos no instante `t` (antes da cena, nenhum; depois, os três ficam).
static func floors(t: float) -> int:
	return FLOORS.filter(func(f: float) -> bool: return t >= f).size() if t >= 0.0 else 0


## Quanto o carro `car` (0 o camburão, 1 a viatura) fica parado (s, desde que para) e quando as portas dele batem.
static func wait(car: int) -> float:
	_build_all()
	return (maxf(_in["o0"], _in["o1"]) + 1.6 - ARRIVE) if car == 0 else (maxf(_in["o2"], _in["o3"]) + 2.2 - ARRIVE - LATE)


static func slams(car: int) -> Array:
	_build_all()
	var stop := ARRIVE + LATE * car
	var out := []
	for d: Vector2 in _cab[car]:
		out.append(d.y + DOOR_SEC.y - stop)
	for id: String in (["o1"] if car == 0 else ["o3"]):   # a do lado da calçada: descendo e entrando
		out.append_array([_tracks[id][0][0] + 0.4 - stop, _in[id] + 0.3 - stop])
	return out


## Quando a cena acaba (s): a viatura já saiu da vista.
static func end() -> float:
	return ARRIVE + LATE + wait(1) + 3.5


static func _build_all() -> void:
	if not _tracks.is_empty():
		return
	_cab = [[], []]
	var o0 := _guard_keys()   # (abre o cofre: os presos sobem depois disso...)
	for i in PRISONERS.size():
		_tracks["p%d" % i] = Beating._build(_prisoner_keys(i))
	o0.append_array(_guard_after())   # (...e ele fecha depois do último: os outros voltam aos carros depois disso)
	_tracks["o0"] = Beating._build(o0)
	for i in [1, 2, 3]:
		_tracks["o%d" % i] = Beating._build(_officer_keys(i))


static func _walk(k: Array, t: float, from: Vector2, to: Vector2, v := WALK) -> float:
	return Beating.walk(k, t, from, to, v)


## O caminho a passo igual por `path` (os momentos "lin", sem frear em cada ponto: `Beating.walk` freia no fim),
## devolvendo quando chega.
static func _go(k: Array, t: float, path: Array, v: float, extra := {}) -> float:
	k.append([t, {"x": path[0].x, "z": path[0].y, "walk": true, "swing": not extra.has("cuffs")}.merged(extra)])
	for i in range(1, path.size()):
		t += (path[i] as Vector2).distance_to(path[i - 1]) / v
		var key := {"x": path[i].x, "z": path[i].y}
		var dx: float = path[i].x - path[i - 1].x
		if absf(dx) > 0.05:
			key["s"] = signf(dx)
		key["front"] = absf(dx) < absf(path[i].y - path[i - 1].y)   # (descendo ou subindo a calçada: de frente)
		k.append([t, key, "lin"])
	k.append([t + 0.01, {"walk": false, "swing": false, "front": false}])
	return t + 0.01


## A porta da cabine do lado de cá do carro `car` abre em `t` e fecha `shut` s depois.
static func _door(car: int, t: float, shut: float) -> void:
	_cab[car].append(Vector2(t, t + shut))


## Onde fica quem abre ou fecha a porta da cabine `cab` (x da dobradiça e do fim): na rua, logo atrás da beira solta
## dela, fora do giro.
static func _handle(cab: Vector2) -> Vector2:
	return Vector2(cab.y + 0.3, SIDE - 0.5)


## Descendo da cabine do lado de cá do carro `car` (0 o camburão, 1 a viatura; `cab` a porta) em `t`: a porta abre, ele
## sai do banco pelo vão (aparece só nele: sentado, do peitoril para cima; pondo o pé na rua, até o chão), fica de pé,
## vai para trás da porta e a empurra, e ela bate. `pose`: como ele é. Devolve quando acaba, com ele em `_handle(cab)`.
static func _out_of_cab(k: Array, t: float, car: int, cab: Vector2, pose: Dictionary) -> float:
	var id: String = ["van", "patrol"][car]
	_door(car, t, 1.9)
	k.append([t + 0.3, pose.merged({"x": (cab.x + cab.y) / 2.0, "z": SIDE + 0.35, "s": -1.0, "front": true, "clip": id + "_in", "hip": 0.6,
		"legs": [Vector2(75, 85), Vector2(70, 80)], "lean": -5.0})])   # sentado no banco
	k.append([t + 0.8, {"z": SIDE + 0.05, "hip": 0.75, "legs": [Vector2(40, 50), Vector2(10, 15)], "lean": 10.0, "clip": id}])   # o pé na rua
	k.append([t + 1.2, {"z": SIDE - 0.2, "hip": 0.82, "legs": Beating.STAND["legs"], "lean": 0.0, "clip": "", "walk": true}])   # de pé, sai do vão...
	k.append([t + 1.6, {"x": _handle(cab).x, "z": _handle(cab).y, "s": 1.0, "front": false}])
	k.append([t + 1.65, {"walk": false, "s": -1.0, "arms": [Vector2(70, 15), Vector2(-6, 10)]}])   # ...e empurra a porta pela beira
	k.append([t + 2.3, {"arms": Beating.STAND["arms"]}])
	return t + 2.3


## Subindo na cabine do lado de cá do carro `car` (`cab` a porta), a partir de `_handle(cab)`, em `t`: puxa a porta
## pela beira, recua enquanto ela gira, passa para o vão entre ela e o carro e senta no banco, sumindo nele (até o chão,
## e depois do peitoril para cima); a porta bate. Devolve quando ele está dentro.
static func _into_cab(k: Array, t: float, car: int, cab: Vector2) -> float:
	var id: String = ["van", "patrol"][car]
	k.append([t, {"s": -1.0, "front": false, "arms": [Vector2(70, 15), Vector2(-6, 10)]}])   # a mão na beira da porta
	_door(car, t + 0.2, 1.6)
	k.append([t + 0.7, {"x": cab.y + 0.5, "arms": [Vector2(45, 30), Vector2(-6, 10)], "walk": true}])   # recua com ela abrindo
	k.append([t + 1.2, {"x": (cab.x + cab.y) / 2.0, "z": SIDE - 0.15, "front": true, "arms": Beating.STAND["arms"], "walk": false, "clip": id}])   # no vão
	k.append([t + 1.6, {"z": SIDE + 0.1, "hip": 0.72, "legs": [Vector2(45, 55), Vector2(10, 15)], "lean": 8.0, "clip": id + "_in"}])
	k.append([t + 2.0, {"z": SIDE + 0.35, "hip": 0.6, "legs": [Vector2(75, 85), Vector2(70, 80)], "lean": -5.0}])   # sentado
	return t + 2.0


## O motorista do camburão: desce pela porta do lado de cá, fecha, vai para a traseira e fica de guarda, olhando a
## rua e o hotel; abre as portas do cofre quando a fila sai e ajuda cada preso a subir, com a mão nas costas dele.
static func _guard_keys() -> Array:
	var k := []
	var t := _out_of_cab(k, ARRIVE + 1.0, 0, VAN_CAB, {"cop": true})
	t = _walk(k, t + 0.3, _handle(VAN_CAB), Vector2(REAR + 0.7, NEAR))
	var post := Vector2(REAR + 0.7, NEAR)
	for look: Array in [[t + 1.5, {"s": -1.0}], [t + 6.0, {"front": true}], [t + 9.0, {"s": 1.0, "front": false}], [t + 14.0, {"front": true}],
			[t + 20.0, {"s": -1.0, "front": false, "head": -6.0}], [t + 24.0, {"head": 0.0}], [t + 30.0, {"front": true}]]:   # de guarda, olhando a rua, o hotel e as janelas acesas
		k.append(look)
	var open := EXIT + 6.0   # vai para trás do cofre, abre a porta de cá (que dobra rente ao lado) e a de lá, de fora do giro delas
	t = _walk(k, open - 1.2, post, OPENER)
	k.append([t + 0.1, {"s": -1.0, "front": false}])
	_rear.x = t + 0.3
	k.append_array([[_rear.x, {"arms": [Vector2(60, 20), Vector2(-6, 10)]}], [_rear.x + REAR_SEC.x * 0.6, {"arms": [Vector2(85, 5), Vector2(-6, 10)]}],
		[_rear.x + REAR_SEC.x, {"arms": Beating.STAND["arms"]}]])
	_rear.y = _rear.x + REAR_SEC.x + 0.4
	k.append_array([[_rear.y, {"arms": [Vector2(70, 10), Vector2(-6, 10)]}], [_rear.y + REAR_SEC.x, {"arms": Beating.STAND["arms"]}]])
	_walk(k, _rear.y + REAR_SEC.x + 0.3, OPENER, HELPER)   # e fica do lado de cá do vão, para ajudar a subir
	return k


## O resto do da guarda (depois dos presos, que marcam quando cada um sobe): a mão nas costas de cada um, fecha as
## portas e volta para a cabine.
static func _guard_after() -> Array:
	var k := []
	for i in PRISONERS.size():
		var up: float = _in["p%d" % i] - CLIMB + 0.3
		k.append_array([[up, {"s": -1.0, "front": false, "arms": [Vector2(65, 25), Vector2(-6, 10)], "lean": 8.0}],
			[up + 1.4, {"arms": [Vector2(80, 10), Vector2(-6, 10)]}], [up + 2.0, {"arms": Beating.STAND["arms"], "lean": 0.0}]])
	var last: float = _in["p%d" % (PRISONERS.size() - 1)]
	var t := _walk(k, last + 0.2, HELPER, OPENER)   # (de fora do giro da porta de cá)
	k.append([t + 0.1, {"s": -1.0, "front": false}])
	_rear.z = t + 0.3   # a de lá primeiro, por dentro do vão; a de cá por cima
	_rear.w = _rear.z + REAR_SEC.y + 0.5
	k.append_array([[_rear.z, {"arms": [Vector2(80, 5), Vector2(-6, 10)], "lean": 10.0}], [_rear.z + REAR_SEC.y, {"arms": [Vector2(55, 15), Vector2(-6, 10)]}],
		[_rear.w, {"arms": [Vector2(85, 10), Vector2(-6, 10)]}], [_rear.w + REAR_SEC.y, {"arms": [Vector2(60, 20), Vector2(-6, 10)], "lean": 4.0}],
		[_rear.w + REAR_SEC.y + 0.6, {"arms": Beating.STAND["arms"], "lean": 0.0}]])
	t = _go(k, _rear.w + REAR_SEC.y + 1.0, [OPENER, Vector2(REAR + 0.4, NEAR), _handle(VAN_CAB)], WALK)
	_in["o0"] = _into_cab(k, t + 0.1, 0, VAN_CAB)
	return k


## Os outros três policiais (`i`: 1 o do lado da calçada do camburão, 2 o motorista da viatura, 3 o do lado da calçada
## dela): descem, vão até a porta do hotel e entram; saem com a fila (o 1 na frente, o 3 no meio, o 2 no fim), ficam
## na rua de olho e voltam cada um para o seu carro.
static func _officer_keys(i: int) -> Array:
	var stop: float = ARRIVE + (LATE if i > 1 else 0.0)
	var cab: Vector2 = VAN_CAB if i == 1 else PATROL_CAB
	var mid := (cab.x + cab.y) / 2.0
	var k := []
	var t := stop + (1.0 if i != 2 else 0.8)
	var pose := {"cop": true, "skin": [0, 0, 2, 1][i], "hip": 0.82}
	if i == 2:   # o motorista da viatura, pela porta do lado de cá, e pela rua na frente dos dois carros
		t = _out_of_cab(k, t, 1, PATROL_CAB, pose)
		t = _go(k, t + 0.2, [_handle(PATROL_CAB), Vector2(DOWN.x, NEAR), DOWN, Vector2(DOWN.x, CURB), Vector2(HOTEL.x + 0.5, CURB + 0.1), Vector2(HOTEL.x, 9.2), HOTEL], WALK)
	else:   # o do lado da calçada: aparece atrás do carro, sobe na calçada e vai pela calçada
		k.append([t, pose.merged({"x": mid, "z": CURB - 0.2, "s": -1.0, "front": false})])
		t = _go(k, t + 0.2, [Vector2(mid, CURB - 0.2), Vector2(mid - 0.4, CURB), Vector2(HOTEL.x + 0.5, CURB + 0.1), Vector2(HOTEL.x, 9.2), HOTEL], WALK)
	k.append([t + 0.1, {"hidden": true}])   # (dentro do hotel: fora da vista até a fila sair)
	var out: float = {1: EXIT, 3: EXIT + 1.5 + SPACE * 2.0 + 1.2, 2: EXIT + 1.5 + SPACE * (PRISONERS.size() - 1) + 1.4}[i]
	var spot: Vector2 = {1: Vector2(REAR + 1.6, PARK.y - 0.3), 3: Vector2(REAR - 2.2, NEAR - 0.45), 2: Vector2(REAR - 0.8, NEAR - 0.5)}[i]
	var path := [HOTEL, Vector2(HOTEL.x + 0.3, 9.0), Vector2(DOWN.x, CURB), DOWN]   # (pela calçada, atrás do camburão)
	if spot.y < NEAR:   # (os que ficam na rua, na frente dele)
		path.append(Vector2(REAR + 1.0, NEAR))
	path.append(spot)
	k.append([out - 0.01, {"x": HOTEL.x, "z": HOTEL.y, "hidden": false}])
	t = _go(k, out, path, LINE)
	var face := -1.0 if i != 2 else 1.0   # de olho: o 1 nos presos subindo, o 3 no hotel, o 2 na traseira
	k.append_array([[t + 0.3, {"s": face}], [t + 4.0, {"front": i == 3}], [t + 9.0, {"front": false}]])
	var back: float = _rear.w + REAR_SEC.y + 1.6 + 0.4 * i   # (depois das portas fechadas: cada um para o seu carro)
	if i == 2:   # pela rua, mais para cá que o da guarda (que volta ao camburão), até a porta do motorista da viatura
		t = _go(k, back, [spot, Vector2(_handle(PATROL_CAB).x, spot.y), _handle(PATROL_CAB)], WALK)
		_in["o2"] = _into_cab(k, t + 0.1, 1, PATROL_CAB)
	else:   # pelo vão entre os dois, para trás deles, até a porta do lado da calçada
		var to: Array = [spot, Vector2(REAR + 1.2, PARK.y), Vector2(REAR + 1.2, CURB), Vector2(mid, CURB), Vector2(mid, CURB - 0.25)]
		if i == 3:
			to = [spot, Vector2(REAR + 1.0, NEAR), Vector2(REAR + 1.3, PARK.y), Vector2(REAR + 1.3, CURB), Vector2(mid, CURB), Vector2(mid, CURB - 0.25)]
		t = _go(k, back, to, WALK)
		_in["o%d" % i] = t + 0.2
		k.append([t + 0.2, {}])
	return k


## Um dos presos (`i`): sai do hotel na fila, as mãos algemadas nas costas e a cabeça baixa, anda pela calçada atrás do
## camburão, desce para a rua na traseira dele, vira, sobe o degrau e entra no cofre (some no vão, `clip` "rear").
static func _prisoner_keys(i: int) -> Array:
	var look: Array = PRISONERS[i]
	var pose := {"x": HOTEL.x, "z": HOTEL.y, "s": 1.0, "cop": false, "hat": "", "cuffs": true, "head": 18.0,
		"cloth": Pal.RAID_SHIRTS[look[0]], "pants": Pal.RAID_PANTS[look[1]], "skin": look[2], "size": look[3],
		"arms": [Vector2(-30, 45), Vector2(-30, 45)]}
	var t: float = EXIT + 1.5 + SPACE * i
	var k := [[t - 0.01, pose]]
	t = _go(k, t, [HOTEL, Vector2(HOTEL.x + 0.3, 9.0), Vector2(DOWN.x, CURB), DOWN, STAND], LINE, {"cuffs": true})
	var up := maxf(t, (_in.get("p%d" % (i - 1), 0.0) as float) + 0.2)   # (se o da frente ainda está subindo, espera)
	k.append_array([
		[up + 0.3, {"s": -1.0, "front": false, "head": 8.0}],   # vira para o vão
		[up + 0.8, {"x": REAR + 0.45, "hip": 0.82 + STEP_UP * 0.5, "lean": 18.0, "legs": [Vector2(55, 75), Vector2(-4, 6)]}],   # o pé no degrau
		[up + 1.3, {"x": REAR + 0.3, "hip": 0.82 + STEP_UP, "lean": 22.0, "legs": [Vector2(10, 20), Vector2(-15, 25)], "clip": "rear"}],   # em cima, abaixando a cabeça
		[up + CLIMB, {"x": REAR - 0.6, "lean": 28.0, "head": 20.0, "legs": [Vector2(20, 30), Vector2(-10, 20)]}],   # entrando
	])
	_in["p%d" % i] = up + CLIMB
	return k
