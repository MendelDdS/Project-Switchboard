extends RefCounted
## A corrida da noite 8 (`StreetEvent` "chase"): um rapaz de blusão sai de baixo do peitoril, atravessa a mão de lá
## correndo na diagonal, sobe na calçada, corre para a esquerda olhando para trás e entra pela porta do hotel. Logo
## depois de ele sumir na porta, dois homens de terno e chapéu vêm correndo atrás pelo mesmo caminho, perdem o rastro na
## boca do cruzamento, param, olham em volta (um aponta a rua do cruzamento, o outro entra um pouco nela e volta) e
## seguem andando devagar para a esquerda, passando pela porta do hotel sem saber. Só o roteiro, como o `Beating` (as poses no instante `t`, sem estado); a vista desenha
## (`Background._scene_figs`, `_draw_rig`). Pose como a do `Beating`, mais a roupa (`cloth`, `pants`, `hat`) e `back`
## (a cabeça virada para trás).

const Beating := preload("res://scripts/ui/beating.gd")
const END := 33.0   ## quando os dois homens saem da vista
const DOOR := Vector2(-6.3, 10.2)   ## a porta do hotel, onde o rapaz some (x, z; `Background.HOTEL_X`)
## A corrida: o tempo de um ciclo de dois passos (s) e a velocidade (m/s) do rapaz e dos homens.
const RUN := {"cycle": 0.62, "young": 4.6, "men": 4.1}
const KEYS_PER_CYCLE := 8
## O rapaz: o caminho (x, z) e os instantes em que ele olha para trás (s, quanto tempo).
const YOUNG_PATH: Array[Vector2] = [Vector2(11.0, 5.0), Vector2(6.5, 8.4), Vector2(-5.4, 8.8)]
const LOOKS: Array[Vector2] = [Vector2(1.7, 0.35), Vector2(3.1, 0.3)]
const MEN_START := [5.8, 6.3]   ## quando cada homem aparece (s): o rapaz já entrou (~4,9 s), e eles não o veem

static var _tracks := {}


## As figuras da cena no instante `t` ([pose...]; a do rapaz com `door` quando passa pela porta); nenhuma fora dela.
static func figures(t: float) -> Array:
	if t < 0.0 or t >= END:
		return []
	if _tracks.is_empty():
		_tracks = {"young": Beating._build(_young_keys()), "m0": Beating._build(_man_keys(0)), "m1": Beating._build(_man_keys(1))}
	var out := []
	if t < _tracks["young"][-1][0]:
		out.append(Beating._at(_tracks["young"], t))
	for id: String in ["m0", "m1"]:
		if t >= _tracks[id][0][0]:
			out.append(Beating._at(_tracks[id], t))
	return out


## Para onde quem está na calçada olha (x, m): o rapaz e, depois que ele entra, os homens.
static func focus(t: float) -> float:
	var f := figures(t)
	return INF if f.is_empty() else (f[0] as Dictionary)["x"]


## Quantos passos de corrida caem entre `a` e `b` (s): um pé no chão a cada meio ciclo de quem está correndo.
static func footfalls(a: float, b: float) -> int:
	var n := 0
	for id: String in ["young", "m0", "m1"]:
		var span: Vector2 = _run_span(id)
		var half: float = RUN["cycle"] / 2.0
		n += maxi(0, floori((clampf(b, span.x, span.y) - span.x) / half) - floori((clampf(a, span.x, span.y) - span.x) / half))
	return n


## Quando cada um corre (s, do começo ao fim da corrida).
static func _run_span(id: String) -> Vector2:
	if id == "young":
		return Vector2(0.0, _length(YOUNG_PATH) / RUN["young"])
	var i := int(id[1])
	return Vector2(MEN_START[i], MEN_START[i] + _length(_men_path(i)) / RUN["men"])


static func _length(path: Array[Vector2]) -> float:
	var d := 0.0
	for i in path.size() - 1:
		d += path[i].distance_to(path[i + 1])
	return d


## O caminho de cada homem: o do rapaz até a boca do cruzamento, um de cada lado.
static func _men_path(i: int) -> Array[Vector2]:
	return [Vector2(11.4 + 0.5 * i, 5.0 - 0.2 * i), Vector2(6.8, 8.2 + 0.5 * i), Vector2(0.4 if i == 0 else 2.3, 8.3 + 0.5 * i)]


## Os momentos de quem corre pelo caminho `path` a `v` m/s desde `t0`, um a cada oitavo de ciclo (em linha reta entre
## eles, `lin`): as pernas e os braços do ciclo da corrida (a coxa indo e voltando, o joelho dobrando quando ela vem
## para a frente, os braços dobrados ao contrário das pernas), o tronco inclinado e o quadril subindo nos dois pés
## fora do chão. Devolve o instante em que chega.
static func _run(k: Array, t0: float, path: Array[Vector2], v: float) -> float:
	var cycle: float = RUN["cycle"]
	var dt := cycle / KEYS_PER_CYCLE
	var total := _length(path)
	var seg := 0
	var done := 0.0   # o caminho até o começo do trecho `seg`
	var d := 0.0
	var i := 0
	while true:
		d = minf(i * dt * v, total)
		while seg < path.size() - 2 and d > done + path[seg].distance_to(path[seg + 1]):
			done += path[seg].distance_to(path[seg + 1])
			seg += 1
		var at := path[seg].move_toward(path[seg + 1], d - done)
		var ph := TAU * i / KEYS_PER_CYCLE
		var legs := []
		for side in 2:
			var q := ph + PI * side
			legs.append(Vector2(48.0 * sin(q) - 4.0, 18.0 + 92.0 * maxf(0.0, cos(q))))
		var arm := 42.0 * sin(ph)
		k.append([t0 + i * dt, {"x": at.x, "z": at.y, "s": signf(path[seg + 1].x - path[seg].x), "legs": legs,
			"arms": [Vector2(-arm, 95.0), Vector2(arm, 95.0)], "hip": 0.84 + 0.035 * cos(2.0 * ph), "lean": 16.0,
			"walk": false, "swing": false, "front": false, "back": false}, "lin"])
		if d >= total:
			return t0 + i * dt
		i += 1
	return t0


## O rapaz: blusão claro e calça escura, sem chapéu; corre, olha para trás duas vezes, freia na porta e entra.
static func _young_keys() -> Array:
	var k := [[0.0, {"cloth": Pal.CHASE_YOUNG[0], "pants": Pal.CHASE_YOUNG[1], "hat": "", "skin": 1, "cop": false}]]
	var arrive := _run(k, 0.0, YOUNG_PATH, RUN["young"])
	for key: Array in k:   # a cabeça virada para trás, por um instante, no meio da corrida
		for look: Vector2 in LOOKS:
			if key[0] >= look.x and key[0] < look.x + look.y:
				key[1]["back"] = true
				key[1]["lean"] = 10.0
	k.append_array([
		[arrive + 0.25, {"x": YOUNG_PATH[-1].x - 0.4, "legs": [Vector2(20, 15), Vector2(-25, 30)], "arms": [Vector2(30, 60), Vector2(-20, 60)],
			"lean": -4.0, "hip": 0.8}, "out"],   # freia
		[arrive + 0.4, {"front": true, "walk": true, "swing": true, "lean": 6.0, "hip": 0.82, "legs": Beating.STAND["legs"], "arms": Beating.STAND["arms"]}],
		[arrive + 1.1, {"x": DOOR.x, "z": DOOR.y}],   # entra pela porta
	])
	return k


## Um dos homens (`i`): terno escuro e chapéu; corre até a boca do cruzamento, para ofegando, olha para os dois lados
## e para a rua do cruzamento; o primeiro aponta para ela, o segundo entra um pouco nela e volta; os dois seguem
## andando para a esquerda, pelo caminho do rapaz.
static func _man_keys(i: int) -> Array:
	var t0: float = MEN_START[i]
	var k := [[t0, {"cloth": Pal.CHASE_SUIT[i], "pants": Pal.CHASE_SUIT[i], "hat": "fedora", "skin": 0, "cop": false}]]
	var path := _men_path(i)
	var t := _run(k, t0, path, RUN["men"])
	var at: Vector2 = path[-1]
	k.append_array([
		[t + 0.4, {"x": at.x - 0.5, "legs": [Vector2(18, 12), Vector2(-20, 25)], "arms": [Vector2(20, 50), Vector2(-15, 50)], "lean": -3.0, "hip": 0.8}, "out"],
		[t + 0.9, {"legs": Beating.STAND["legs"], "arms": Beating.STAND["arms"], "lean": 14.0, "hip": 0.8, "head": 8.0}],   # ofegando, curvado
		[t + 1.6, {"lean": 4.0, "hip": 0.82, "head": 0.0}],
		[t + 2.1, {"s": 1.0}],   # olha para trás, por onde veio
		[t + 3.0, {"s": -1.0}],   # e para a frente
	])
	t += 3.4
	if i == 0:   # aponta a rua do cruzamento, de frente para ela
		k.append_array([
			[t, {"front": true}],
			[t + 0.6, {"arms": [Vector2(120, 10), Vector2(-6, 10)], "lean": 2.0}, "out"],
			[t + 1.4, {"arms": [Vector2(125, 5), Vector2(-6, 10)]}],
			[t + 1.9, {"arms": Beating.STAND["arms"]}],
			[t + 4.6, {}],
			[t + 4.8, {"front": false, "s": -1.0, "walk": true, "swing": true}],
		])
	else:   # entra um pouco na rua do cruzamento, olha e volta
		k.append_array([
			[t + 0.3, {"front": true, "walk": true, "swing": true}],
			[t + 1.8, {"z": at.y + 2.2, "walk": false, "swing": false}, "out"],
			[t + 2.6, {"head": -6.0}],
			[t + 3.4, {"head": 0.0, "walk": true, "swing": true}],
			[t + 4.8, {"z": at.y, "s": -1.0, "front": false}],
		])
	t += 4.8
	k.append([END - 1.2 * i, {"x": -13.5, "z": 8.8 + 0.3 * i}, "lin"])   # devagar, para a esquerda, até sair da vista
	return k
