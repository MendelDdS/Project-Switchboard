extends RefCounted
## A banca fechada da noite 12 (`StreetEvent` "newsstand"), antes das 19h, com ela aberta: um sedã escuro sem letreiro
## para junto do meio-fio de lá, perto da esquina; dois homens de terno e chapéu descem, vão até a banca, um aponta
## para o jornaleiro, que levanta as mãos e recua para a rua do cruzamento; o primeiro a chegar ao carro abre o
## porta-malas (`lid`) e os dois levam os jornais e as revistas em pilhas para dentro dele, duas viagens cada (a banca
## esvaziando, `state`); o último a pôr a pilha bate a tampa; baixam as portas, um põe o cadeado e o
## lacre, e vão embora no carro. O jornaleiro fica parado um tempo, de cabeça baixa, e sobe a rua do cruzamento. A
## banca fica fechada e lacrada até o fim do jogo (`Background.left_behind`). Só o roteiro, como o `Beating`: tudo sai
## do tempo `t` (s desde que o carro aparece), sem estado.

const Beating := preload("res://scripts/ui/beating.gd")
const CAR := "sedan"
const CAR_MID := 3.4   ## onde o meio do carro para (x, m; `Background._taxi_x`): na boca do cruzamento, a traseira na esquina
const ARRIVE := 3.2    ## quando ele para (`Background.TAXI_STOP.x`)
const OUT := [3.8, 4.4]   ## quando cada homem desce (s)
const WALK := 1.3   ## m/s
const COUNTER := [Vector2(5.0, 10.05), Vector2(5.55, 10.0)]   ## onde cada homem fica na frente do balcão (x, z)
const TRUNK := [Vector2(5.85, 6.3), Vector2(5.95, 7.0)]   ## e atrás do carro, na rua, de frente para o porta-malas (do lado da calçada, a tampa aberta os tapava)
const CORNER := Vector2(5.95, 7.75)   ## por onde passam da calçada para trás do carro, na frente do poste
const LID_SEC := Vector2(0.6, 0.25)   ## quanto a tampa do porta-malas leva abrindo e batendo (s)
const DOORS := [Vector2(2.3, 7.9), Vector2(3.7, 7.9)]   ## as portas do carro, do lado da calçada
const SHUT_SEC := 1.6   ## quanto as portas da banca levam descendo (s)
const VENDOR := Vector2(4.3, 10.85)

static var _tracks := {}
static var _picks: Array[float] = []   # quando cada pilha sai do balcão
static var _shut := Vector2.ZERO   # as portas descendo (s, do começo ao fim)...
static var _lock := 0.0   # ...o cadeado e o lacre...
static var _in: Array[float] = [0.0, 0.0]   # ...quando cada homem entra de volta no carro (a porta bate logo depois)...
static var _lid := Vector2(INF, -INF)   # ...e quando a tampa do porta-malas começa a abrir e a fechar
static var _puts: Array[float] = []   # quando cada pilha entra no porta-malas


## Quem está na cena no instante `t` (o jornaleiro desde o começo; os homens entre descer e subir no carro).
static func figures(t: float) -> Array:
	if t < 0.0:
		return []
	_build_all()
	var out := []
	for id: String in ["vendor", "m0", "m1"]:
		var track: Array = _tracks[id]
		if t >= track[0][0] and t < track[-1][0]:
			out.append(Beating._at(track, t))
	return out


## A banca no instante `t`: Vector3(o quanto das portas já desceu (0 aberta, 1 fechada), o quanto sobrou nela (0 a 1),
## 1 com o cadeado e o lacre). Antes da cena (`t` negativo), aberta e cheia.
static func state(t: float) -> Vector3:
	if t < 0.0:
		return Vector3(0.0, 1.0, 0.0)
	_build_all()
	var gone := _picks.filter(func(p: float) -> bool: return t >= p).size()
	return Vector3(clampf((t - _shut.x) / SHUT_SEC, 0.0, 1.0), 1.0 - float(gone) / _picks.size(), 1.0 if t >= _lock else 0.0)


## O quanto a tampa do porta-malas está aberta no instante `t` (0 fechada, 1 aberta).
static func lid(t: float) -> float:
	_build_all()
	return clampf((t - _lid.x) / LID_SEC.x, 0.0, 1.0) * (1.0 - clampf((t - _lid.y) / LID_SEC.y, 0.0, 1.0))


## Quanto o carro fica parado (s, desde que para) e quando cada porta dele bate (s depois de parar).
static func wait() -> float:
	_build_all()
	return _in.max() + 1.2 - ARRIVE


static func slams() -> Array:
	_build_all()
	return [OUT[0] + 0.5 - ARRIVE, OUT[1] + 0.5 - ARRIVE, _lid.y + LID_SEC.y - ARRIVE, _in[0] + 0.3 - ARRIVE, _in[1] + 0.3 - ARRIVE]


## Para onde quem está na calçada olha (x, m; INF: nada): a banca, enquanto os homens estão nela.
static func focus(t: float) -> float:
	_build_all()
	return 5.2 if t >= OUT[0] and t < _in.max() else INF


static func _build_all() -> void:
	if not _tracks.is_empty():
		return
	_tracks = {"m1": Beating._build(_man_keys(1))}   # (o que baixa as portas primeiro: o cadeado e o jornaleiro vêm depois)
	_tracks["m0"] = Beating._build(_man_keys(0))
	_tracks["vendor"] = Beating._build(_vendor_keys())


static func _walk(k: Array, t: float, from: Vector2, to: Vector2) -> float:
	return Beating.walk(k, t, from, to, WALK)


static func _vendor_keys() -> Array:
	var k := [[0.0, {"x": VENDOR.x, "z": VENDOR.y, "s": 1.0, "cop": false, "skin": 2, "hat": ""}]]
	k.append_array([
		[OUT[0] + 1.0, {"s": 1.0, "head": -8.0}],   # vê os dois descendo
		[7.6, {"s": 1.0, "head": 0.0}],
		[8.3, {"arms": [Vector2(70, 80), Vector2(60, 80)], "lean": -4.0}],   # as mãos para cima...
		[9.0, {"x": VENDOR.x - 0.3}],
		[10.4, {"x": VENDOR.x - 0.9, "z": VENDOR.y - 0.3, "arms": [Vector2(55, 75), Vector2(50, 70)]}],   # ...recuando
		[11.2, {"arms": Beating.STAND["arms"], "lean": 0.0}],
		[_in.max() + 3.0, {}],
		[_in.max() + 4.5, {"head": 18.0}],   # de cabeça baixa, olhando a banca lacrada
		[_in.max() + 12.0, {"head": 18.0}],
		[_in.max() + 13.0, {"head": 0.0, "front": true, "walk": true, "swing": true}],
		[_in.max() + 13.0 + 6.5 / WALK, {"z": VENDOR.y + 6.5}],   # sobe a rua do cruzamento
		[_in.max() + 13.1 + 6.5 / WALK, {"walk": false}],
	])
	return k


## Um dos homens (`i`): desce, vai ao balcão, (o primeiro) aponta para o jornaleiro, leva duas pilhas ao porta-malas,
## (o segundo) baixa as portas e (o primeiro) põe o cadeado, e voltam para o carro.
static func _man_keys(i: int) -> Array:
	var bend := {"lean": 40.0, "hip": 0.74, "legs": [Vector2(20, 30), Vector2(-5, 20)], "arms": [Vector2(75, 10), Vector2(65, 15)]}
	var up := {"lean": 2.0, "hip": 0.82, "legs": Beating.STAND["legs"]}
	var carry := {"arms": [Vector2(55, 70), Vector2(50, 75)], "carry": true}
	var k := [[OUT[i], {"x": DOORS[i].x, "z": DOORS[i].y, "s": -1.0, "cloth": Pal.CHASE_SUIT[i], "pants": Pal.CHASE_SUIT[i],
		"hat": "fedora", "skin": 0, "cop": false}]]
	var t := _walk(k, OUT[i] + 0.3, DOORS[i], COUNTER[i])
	k.append([t + 0.3, {"front": true}])
	if i == 0:   # aponta para o jornaleiro, dois trancos
		k.append_array([
			[t + 0.5, {"front": false, "s": -1.0}],
			[t + 0.9, {"arms": [Vector2(85, 5), Vector2(-6, 10)], "lean": 6.0}, "out"],
			[t + 1.3, {"arms": [Vector2(70, 20), Vector2(-6, 10)]}],
			[t + 1.6, {"arms": [Vector2(88, 5), Vector2(-6, 10)]}, "in"],
			[t + 2.6, {"arms": Beating.STAND["arms"], "lean": 2.0}],
		])
	t = maxf(t + 3.0, 10.6 + 0.6 * i)
	for trip in 2:   # cada viagem: pega uma pilha no balcão, leva, põe no porta-malas e volta
		k.append_array([[t, {"s": 1.0, "front": true}], [t + 0.5, bend], [t + 0.9, bend.merged(carry)], [t + 1.4, up.merged(carry)]])
		_picks.append(t + 0.9)
		t = _walk(k, _walk(k, t + 1.5, COUNTER[i], CORNER), CORNER, TRUNK[i])
		if trip == 0 and t < _lid.x:   # o primeiro a chegar abre a tampa: a mão nela, subindo
			_lid.x = t + 0.3
			k.append_array([[t + 0.25, {"s": -1.0, "arms": [Vector2(40, 10), Vector2(50, 75)]}], [t + 0.3 + LID_SEC.x, {"arms": [Vector2(120, 10), Vector2(50, 75)]}]])
			t += 0.3 + LID_SEC.x
		k.append_array([[t + 0.4, bend.merged({"carry": true, "s": -1.0})], [t + 0.8, bend.merged({"carry": false})], [t + 1.2, up.merged({"arms": Beating.STAND["arms"]})]])
		_puts.append(t + 0.8)
		if trip == 1 and i == 0:   # o último bate a tampa (o primeiro, que apontou para o jornaleiro; feito depois do outro)
			_lid.y = maxf(t + 1.4, _puts.max() + 0.6)
			k.append_array([[_lid.y, {"arms": [Vector2(120, 10), Vector2(-6, 10)]}], [_lid.y + LID_SEC.y, {"arms": [Vector2(50, 10), Vector2(-6, 10)]}, "in"],
				[_lid.y + 0.6, {"arms": Beating.STAND["arms"]}]])
			t = _lid.y + 0.6 - 1.3
		if trip == 0:
			t = _walk(k, _walk(k, t + 1.3, TRUNK[i], CORNER), CORNER, COUNTER[i])
		else:
			t += 1.3
	t = _walk(k, _walk(k, t, TRUNK[i], CORNER), CORNER, COUNTER[i])
	if i == 1:   # baixa as portas: as mãos no alto e o corpo descendo com elas
		_shut = Vector2(t + 0.8, t + 0.8 + SHUT_SEC)
		k.append_array([
			[t + 0.4, {"front": true, "arms": [Vector2(170, 5), Vector2(165, 5)], "lean": -3.0}],
			[_shut.x, {}],
			[_shut.y, {"arms": [Vector2(40, 20), Vector2(35, 20)], "lean": 30.0, "hip": 0.72}, "in"],
			[_shut.y + 0.6, up.merged({"arms": Beating.STAND["arms"]})],
		])
		t = _shut.y + 0.8
	else:   # o cadeado e o lacre, embaixo, com as portas já descidas
		_lock = maxf(t + 0.8, _shut.y + 1.2)
		k.append_array([
			[_lock - 0.8, {"front": true}], [_lock - 0.3, bend.merged({"lean": 55.0, "hip": 0.62})], [_lock + 1.0, {}],
			[_lock + 1.5, up.merged({"arms": Beating.STAND["arms"]})],
		])
		t = _lock + 1.6
	t = _walk(k, t, COUNTER[i], DOORS[i])
	_in[i] = t + 0.5 + 0.6 * i
	k.append([_in[i], {"front": false, "s": -1.0}])
	return k
