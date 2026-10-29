extends RefCounted
## Os panfletos da noite 6 (`StreetEvent` "flyers"): uma Brasília passa devagar pela mão de lá e, da janela de trás do
## lado da calçada, jogam maços de panfletos para o alto, aos poucos, ao longo da rua (`THROWS`): cada papel sobe,
## perde o embalo no ar, cai planando e virando e pousa no asfalto ou na calçada de lá (`air`, `ground`). Um tempo
## depois chegam três varredores de uniforme, vassoura e saco, cada um num trecho (um da direita, um descendo a rua do
## cruzamento, um da esquerda), e limpam a calçada papel por papel: varrem e abaixam para pegar (`figures`); os da rua
## ficam até o fim da noite. Só o roteiro, como o `Beating`: tudo sai do tempo `t` (s desde que o carro aparece), sem
## estado.

const Beating := preload("res://scripts/ui/beating.gd")
const CAR := "brasilia"
const CAR_SEC := 10.0   ## quanto o carro leva passando (~13 km/h)
const THROWS: Array[float] = [1.8, 3.5, 5.2, 6.9]   ## quando jogam cada maço (s; a janela anda com o carro, `_window_x`)
const PER_THROW := 11
const WINDOW := Vector3(3.3, 7.1, 1.25)   ## a janela de trás do lado da calçada: m atrás da frente, z e altura
const GRAVITY := 9.8
const FALL := Vector2(0.7, 1.3)   ## a queda planando (m/s), de cada papel
const SIDEWALK := Vector2(7.7, 9.2)   ## a calçada de lá (z): os que eles recolhem
const VIEW := 12.0   ## até onde se vê a calçada (x, m; com 7,2, os da direita, ainda à vista, ficavam)
const SPAN := 1.0 / 30.0   ## o passo da trajetória guardada (s)
## Os varredores: quando cada um aparece (s), de onde vem (x, z), o trecho da calçada dele (de x a x) e para onde sai.
const CLEAN_AT: Array[float] = [48.0, 52.0, 57.0]
const SWEEPERS: Array[Dictionary] = [
	{"from": Vector2(13.0, 8.6), "span": Vector2(5.8, 99.0), "exit": Vector2(13.5, 8.6), "skin": 1},
	{"from": Vector2(0.8, 15.0), "span": Vector2(-4.2, 5.8), "exit": Vector2(13.5, 8.9), "skin": 2},
	{"from": Vector2(-13.0, 8.7), "span": Vector2(-99.0, -4.2), "exit": Vector2(-13.5, 8.7), "skin": 0},
]
const WALK := 1.1   ## m/s
const REACH := 0.55   ## a palha da vassoura, à frente do quadril, onde está o papel (m)

static var _paths: Array = []   # [instante em que sai, [Vector4(x, z, altura, virada)...] a cada SPAN s até pousar]
static var _crew: Array = []    # o roteiro de cada varredor
static var _picks := {}   # índice do papel -> quando o pegam


## Os papéis no ar no instante `t`: [x, z, altura (m), virada (-1..1: de chapa ou de lado)].
static func air(t: float) -> Array:
	var out := []
	for p: Array in _flight():
		var u: float = (t - p[0]) / SPAN
		var path: Array = p[1]
		if u >= 0.0 and u < path.size() - 1:
			var a: Vector4 = path[int(u)]
			out.append(a.lerp(path[int(u) + 1], u - floorf(u)))
	return out


## Os papéis no chão no instante `t` (os pousados que ainda não pegaram): [x, z, virada].
static func ground(t: float) -> Array:
	var out := []
	var paths := _flight()
	_crew_tracks()
	for i in paths.size():
		var p: Array = paths[i]
		if t - p[0] >= (p[1] as Array).size() * SPAN and t < _picks.get(i, INF):
			var last: Vector4 = p[1][-1]
			out.append(Vector3(last.x, last.y, last.w))
	return out


## Os varredores no instante `t` (os que estão na vista).
static func figures(t: float) -> Array:
	var out := []
	for track: Array in _crew_tracks():
		if t >= track[0][0] and t < track[-1][0]:
			out.append(Beating._at(track, t))
	return out


## Para onde quem está na calçada olha (x, m; INF: nada): os papéis voando, atrás do carro.
static func focus(t: float) -> float:
	return _window_x(minf(t, THROWS[-1])) - 1.0 if t >= THROWS[0] and t < THROWS[-1] + 3.0 else INF


## O x da janela de trás do carro no instante `t` (`Background._car_x` da mão de lá).
static func _window_x(t: float) -> float:
	return lerpf(16.0, -21.0, t / CAR_SEC) + WINDOW.x


## As trajetórias, calculadas uma vez (sempre as mesmas): cada papel sai da janela com o embalo do carro e do braço,
## para cima e para a calçada; o ar freia o embalo de lado, a queda chega na de planar e ele balança e vira.
static func _flight() -> Array:
	if not _paths.is_empty():
		return _paths
	var rng := RandomNumberGenerator.new()
	rng.seed = 1964
	var car_v := 37.0 / CAR_SEC
	for throw in THROWS:
		for i in PER_THROW:
			var t0 := throw + rng.randf_range(0.0, 0.4)
			var at := Vector3(_window_x(t0), WINDOW.y, WINDOW.z)
			var v := Vector3(-car_v * rng.randf_range(0.5, 1.0) + rng.randf_range(-1.2, 1.2), rng.randf_range(0.3, 1.9), rng.randf_range(1.5, 4.2))   # (x, z: para a calçada, para cima)
			var fall := rng.randf_range(FALL.x, FALL.y)
			var sway := Vector2(rng.randf_range(2.0, 4.5), rng.randf_range(0.0, TAU))   # (a frequência e a fase do balanço)
			var path := []
			var s := 0.0
			while at.z > 0.0 and path.size() < 400:
				var w := sin(sway.x * s + sway.y)
				path.append(Vector4(at.x + 0.18 * w, at.y, at.z, cos(sway.x * 1.7 * s + sway.y)))
				v.x *= exp(-SPAN / 0.5)
				v.y *= exp(-SPAN / 0.6)
				v.z = maxf(v.z - GRAVITY * SPAN, -fall)
				at += v * SPAN
				at.z = at.z if at.z > 0.0 else 0.0
				at.y = minf(at.y, SIDEWALK.y)   # (a fachada: escorrega por ela até o chão)
				s += SPAN
			var w := sin(sway.x * s + sway.y)
			path.append(Vector4(at.x + 0.18 * w, at.y, 0.0, signf(rng.randf() - 0.5)))
			_paths.append([t0, path])
	return _paths


## O roteiro dos três, uma vez: cada um vem, vai de papel em papel do trecho dele na calçada à vista (o mais perto
## primeiro), varre duas vezes, abaixa e pega (o papel some, `_picks`) e guarda no saco; no fim, sai.
static func _crew_tracks() -> Array:
	if not _crew.is_empty():
		return _crew
	var paths := _flight()
	var bend := {"lean": 58.0, "hip": 0.62, "legs": [Vector2(30, 55), Vector2(-5, 35)], "arms": [Vector2(55, 10), Vector2(70, 5)]}
	var stand := {"lean": 10.0, "hip": 0.82, "legs": Beating.STAND["legs"], "arms": [Vector2(30, 35), Vector2(-4, 8)]}
	for n in SWEEPERS.size():
		var crew: Dictionary = SWEEPERS[n]
		var span: Vector2 = crew["span"]
		var at: Vector2 = crew["from"]
		var todo := []
		for i in paths.size():
			var last: Vector4 = paths[i][1][-1]
			if last.y >= SIDEWALK.x and absf(last.x) < VIEW and last.x >= span.x and last.x < span.y:
				todo.append(i)
		todo.sort_custom(func(a: int, b: int) -> bool: return absf(paths[a][1][-1].x - at.x) < absf(paths[b][1][-1].x - at.x))
		var k := [[CLEAN_AT[n], stand.merged({"x": at.x, "z": at.y, "s": -signf(at.x), "cop": false, "hat": "cap", "cloth": Pal.SWEEPER[0],
			"pants": Pal.SWEEPER[1], "skin": crew["skin"], "sack": true, "broom": REACH, "front": at.y > SIDEWALK.y + 1.0})]]
		var t := CLEAN_AT[n]
		for i: int in todo:
			var f: Vector4 = paths[i][1][-1]
			var side := signf(f.x - at.x) if absf(f.x - at.x) > 0.3 else -signf(at.x)
			var to := Vector2(f.x - side * REACH, clampf(f.y - 0.1, SIDEWALK.x + 0.1, SIDEWALK.y - 0.2))
			t = Beating.walk(k, t, at, to, WALK)
			at = to
			k.append_array([
				[t + 0.2, stand.merged({"front": false, "s": side, "lean": 22.0, "arms": [Vector2(40, 20), Vector2(-4, 8)], "broom": REACH + 0.1})],
				[t + 0.55, {"broom": REACH - 0.3, "arms": [Vector2(20, 30), Vector2(-4, 8)]}],   # puxa a vassoura...
				[t + 0.9, {"broom": REACH + 0.1, "arms": [Vector2(40, 20), Vector2(-4, 8)]}],
				[t + 1.25, {"broom": REACH - 0.25, "arms": [Vector2(22, 30), Vector2(-4, 8)]}],   # ...duas vezes
				[t + 1.7, bend.merged({"broom": REACH - 0.25})],   # e abaixa para pegar
				[t + 2.3, stand.merged({"broom": REACH})],
			])
			_picks[i] = t + 1.8
			t += 2.4
		t = Beating.walk(k, t, at, crew["exit"], WALK)
		k[-1][2] = "lin"   # (sai no passo, sem frear)
		k.append([t + 0.1, {}])
		_crew.append(Beating._build(k))
	return _crew
