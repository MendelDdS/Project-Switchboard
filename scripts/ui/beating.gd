extends RefCounted
## A cena da rua na noite 3 (`Night.street_scene` "beating"): um homem vem pela calçada de lá, da direita; um policial
## desce a rua do cruzamento, o aborda, o empurra para o asfalto da boca do cruzamento (o meio da avenida fica abaixo
## do peitoril, fora da vista), bate nele caído com o cassetete e com chutes, o levanta pela gola e o arrasta para a
## direita, embaixo do poste, até sumir do vidro. Só o roteiro: as poses de cada um a cada instante (`officer`,
## `victim`) e o sangue (`drops`, `pool`); a vista desenha (`Background._draw_beating`). Tudo sai do tempo `t` (s desde
## o começo), sem estado: a captura e o fim da noite mostram o mesmo chão.
##
## Pose: `x`, `z` (m, a rua da vista) onde fica o quadril, `s` o sentido para onde a pessoa olha, `hip` a altura dele
## (m), `lean` o tronco a partir da vertical (graus; positivo: para a frente), `head` a cabeça dobrada a partir do
## tronco, `legs` e `arms` [o de cá, o de lá] (x: a coxa ou o braço a partir da vertical para baixo, positivo para a
## frente; y: quanto o joelho ou o cotovelo dobra, para a frente), `front` de frente para nós, `walk` (andando nesse
## trecho: as pernas da passada pela distância), `swing` (os braços também), `baton` o cassetete na mão de cá.

const END := 28.5   ## quando os dois saem do vidro
const X0 := 2.6     ## onde o policial para o homem (m; a boca do cruzamento vai de -4,2 a 5,8)
const STEP := 0.21  ## o quanto se anda por quadro da passada (4 quadros por passo de ~0,84 m)
## As pancadas: [o instante do golpe (s), 0 cassetete ou 1 chute]. Irregulares, com pausas.
const HITS := [[11.3, 0], [11.9, 0], [12.5, 0], [13.5, 0], [14.05, 0], [14.6, 0], [15.6, 1], [16.6, 0], [17.15, 0],
	[18.1, 1], [18.9, 0], [19.45, 0]]
const WATCH := 8.7   ## quando quem está na calçada para e se afasta para assistir (o policial agarra a gola)...
const BACK_OFF := 4.5   ## ...até ficar a tantos metros da briga
## Quem vem pela calçada quando a cena começa, para ter quem assista: [onde está quando para (x, m), o sentido].
const ONLOOKERS: Array[Vector2] = [Vector2(-2.0, 1.0), Vector2(-4.0, -1.0), Vector2(8.8, -1.0)]
const GRAVITY := 9.8
const POOL := Vector3(12.5, 21.9, 0.22)   ## a poça embaixo da cabeça: começa, para de crescer (quando ele é levantado) e o raio (m)
const TRAIL := Vector3(23.6, 0.6, 8)      ## o rastro do arrasto: a primeira gota (s), o intervalo e quantas

const STAND := {"hip": 0.82, "lean": 0.0, "head": 0.0, "legs": [Vector2(3, 4), Vector2(-3, 4)], "arms": [Vector2(8, 12), Vector2(-6, 10)],
	"front": false, "walk": false, "swing": false, "baton": false}

static var _cop: Array = []
static var _man: Array = []
static var _drops: Array = []


## A pose do policial no instante `t`.
static func officer(t: float) -> Dictionary:
	if _cop.is_empty():
		_cop = _build(_cop_keys())
	return _at(_cop, t)


## A pose do homem no instante `t`.
static func victim(t: float) -> Dictionary:
	if _man.is_empty():
		_man = _build(_man_keys())
	return _at(_man, t)


## Para onde quem assiste olha (x, m): o meio entre os dois.
static func focus(t: float) -> float:
	return (officer(t)["x"] + victim(t)["x"]) / 2.0


## As gotas de sangue até o instante `t`: [x, altura, z (m), tamanho (px), tom (`Pal.BLOOD`)], no ar ou já no chão
## (altura 0, para sempre).
static func drops(t: float) -> Array:
	if _drops.is_empty():
		_drops = _spray()
	var out := []
	for d: Array in _drops:   # [instante, origem (x, altura, z), velocidade, tamanho, tom]
		var dt: float = t - d[0]
		if dt < 0.0:
			continue
		var o: Vector3 = d[1]
		var v: Vector3 = d[2]
		var h := o.y + v.y * dt - GRAVITY * dt * dt / 2.0
		var land := (v.y + sqrt(v.y * v.y + 2.0 * GRAVITY * o.y)) / GRAVITY
		dt = minf(dt, land)
		out.append([o.x + v.x * dt, maxf(h, 0.0), o.z + v.z * dt, d[3], d[4]])
	return out


## A poça embaixo da cabeça no instante `t`: Vector3(x, z, raio em m); raio 0 antes de começar.
static func pool(t: float) -> Vector3:
	var head := _head(victim(POOL.y))
	return Vector3(head.x, 8.05, POOL.z * clampf((t - POOL.x) / (POOL.y - POOL.x), 0.0, 1.0))


## Onde fica a cabeça do homem (x, altura).
static func _head(p: Dictionary) -> Vector2:
	var a := deg_to_rad(p["lean"])
	return Vector2(p["x"] + sin(a) * p["s"] * 0.72, p["hip"] + cos(a) * 0.72)


## As gotas sorteadas uma vez, sempre as mesmas (a semente de cada pancada): das pancadas a partir da terceira, mais a
## cada uma, e o rastro do arrasto.
static func _spray() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	for i in HITS.size():
		if i < 2:
			continue
		rng.seed = i * 7919 + 13
		var at: float = HITS[i][0]
		var p := victim(at)
		var hit := _head(p).lerp(Vector2(p["x"], p["hip"]), 0.5 if HITS[i][1] == 1 else 0.15)   # a cabeça, ou o tronco no chute
		for j in mini(2 + i / 3 + rng.randi_range(0, 2), 6):
			out.append([at, Vector3(hit.x, maxf(hit.y, 0.12), p["z"] + rng.randf_range(-0.05, 0.05)),
				Vector3(rng.randf_range(-0.9, 1.6), rng.randf_range(0.6, 2.0), rng.randf_range(-0.35, 0.25)),
				2 if rng.randf() < 0.3 else 1, rng.randi_range(0, 2)])
	for i in int(TRAIL.z):   # pingando no arrasto, da cabeça
		var at: float = TRAIL.x + i * TRAIL.y
		rng.seed = 104729 + i
		var head := _head(victim(at))
		out.append([at, Vector3(head.x, head.y, victim(at)["z"] - 0.05), Vector3(rng.randf_range(-0.2, 0.2), 0.0, 0.0), 1, rng.randi_range(0, 2)])
	return out


## Os momentos do policial: [instante, o que muda na pose, curva até ele ("in" acelera, "out" freia, vazio: os dois)].
static func _cop_keys() -> Array:
	var k := [
		[0.0, {"x": X0 - 0.2, "z": 17.0, "s": 1.0, "front": true, "walk": true, "swing": true}],   # descendo a rua do cruzamento
		[5.2, {"z": 9.6}],
		[6.0, {"z": 8.7, "walk": false, "swing": false}, "out"],
		[6.4, {"front": false, "x": X0 - 0.3, "z": 8.6, "walk": true, "swing": true}],   # vira para ele e vai
		[7.0, {"x": X0, "walk": false, "swing": false}, "out"],
		[7.2, {"arms": [Vector2(70, 20), Vector2(-6, 10)], "lean": 5.0}],   # aponta: dois trancos com o dedo
		[7.45, {"arms": [Vector2(85, 5), Vector2(-6, 10)]}, "in"],
		[7.7, {"arms": [Vector2(70, 25), Vector2(-6, 10)]}],
		[7.95, {"arms": [Vector2(88, 5), Vector2(-6, 10)], "lean": 8.0}, "in"],
		[8.4, {"arms": [Vector2(60, 30), Vector2(-5, 15)]}],
		[8.75, {"arms": [Vector2(80, 30), Vector2(60, 40)], "lean": 12.0, "x": X0 + 0.15}, "out"],   # agarra a gola
		[8.95, {"arms": [Vector2(70, 50), Vector2(60, 55)], "lean": 5.0, "x": X0 + 0.1}],
		[9.25, {"arms": [Vector2(95, 0), Vector2(90, 5)], "lean": 28.0, "x": X0 + 0.6, "hip": 0.76,   # o empurrão
			"legs": [Vector2(25, 5), Vector2(-25, 15)]}, "in"],
		[9.7, {"arms": [Vector2(30, 20), Vector2(10, 15)], "lean": 10.0, "x": X0 + 0.8, "hip": 0.8,
			"legs": [Vector2(10, 10), Vector2(-15, 10)]}, "out"],
		[10.0, {"walk": true, "legs": STAND["legs"], "hip": 0.82, "lean": 4.0}],   # vai até ele, caído
		[10.6, {"x": 4.25, "z": 8.5, "walk": false}, "out"],
		[10.95, {"arms": [Vector2(-20, 60), Vector2(-6, 12)], "baton": true}],   # tira o cassetete do cinto
		[11.1, {"arms": [Vector2(110, 30), Vector2(-6, 12)], "lean": 15.0, "hip": 0.79}, "out"],
	]
	for h: Array in HITS:
		var at: float = h[0]
		if h[1] == 0:   # o cassetete: no alto, a pancada (acelerando), segura e volta
			k.append_array([
				[at - 0.12, {"arms": [Vector2(175, 40), Vector2(-10, 15)], "lean": -6.0, "hip": 0.82, "legs": STAND["legs"]}, "out"],
				[at, {"arms": [Vector2(45, -10), Vector2(-15, 20)], "lean": 30.0, "hip": 0.74, "legs": [Vector2(18, 22), Vector2(-14, 18)]}, "in"],
				[at + 0.08, {"arms": [Vector2(42, -12), Vector2(-15, 20)], "lean": 31.0}],
				[at + 0.3, {"arms": [Vector2(110, 30), Vector2(-10, 15)], "lean": 15.0, "hip": 0.79, "legs": [Vector2(8, 10), Vector2(-8, 10)]}, "out"]])
		else:   # o chute: a perna para trás, para a frente com tudo, e volta
			k.append_array([
				[at - 0.12, {"legs": [Vector2(-40, 70), Vector2(-3, 6)], "lean": 8.0, "arms": [Vector2(40, 30), Vector2(-20, 20)], "hip": 0.8}, "out"],
				[at, {"legs": [Vector2(55, 15), Vector2(-6, 8)], "lean": -8.0, "arms": [Vector2(30, 30), Vector2(-30, 25)]}, "in"],
				[at + 0.1, {"legs": [Vector2(50, 20), Vector2(-6, 8)]}],
				[at + 0.3, {"legs": [Vector2(5, 8), Vector2(-5, 8)], "lean": 12.0, "arms": [Vector2(110, 30), Vector2(-10, 15)], "hip": 0.79}, "out"]])
	k.append_array([
		[20.2, {"arms": [Vector2(-15, 50), Vector2(-6, 10)], "lean": 5.0, "hip": 0.82, "legs": STAND["legs"]}],   # guarda o cassetete
		[20.5, {"arms": [Vector2(6, 12), Vector2(-6, 10)], "baton": false, "walk": true, "swing": true}],   # dá a volta pela cabeça dele
		[21.4, {"x": 6.1, "z": 8.15, "walk": false, "swing": false}, "out"],
		[21.45, {"s": -1.0}],
		[21.9, {"lean": 55.0, "hip": 0.7, "legs": [Vector2(25, 40), Vector2(-10, 30)], "arms": [Vector2(55, 10), Vector2(50, 15)]}],   # abaixa e agarra
		[23.2, {"lean": 18.0, "hip": 0.8, "legs": [Vector2(6, 8), Vector2(-6, 8)], "arms": [Vector2(35, 25), Vector2(30, 25)], "x": 6.2}, "out"],   # levanta
		[23.3, {"s": 1.0, "arms": [Vector2(-35, 15), Vector2(10, 10)], "lean": 12.0}],   # vira e puxa
		[23.5, {"walk": true}],
		[28.3, {"x": 11.6}],
		[END, {"walk": false}],
	])
	return k


## Os momentos do homem (como os do policial).
static func _man_keys() -> Array:
	var curl := [Vector2(130, 105), Vector2(120, 95)]   # caído de costas, encolhido, os braços na cabeça
	var cover := [Vector2(160, 130), Vector2(150, 140)]
	var k := [
		[0.0, {"x": 12.0, "z": 8.6, "s": -1.0, "walk": true, "swing": true}],   # vindo pela calçada de lá
		[4.4, {"x": 4.3}],
		[5.2, {"x": X0 + 0.8, "walk": false, "swing": false}, "out"],
		[6.0, {"head": 12.0}],   # olha o policial chegando
		[6.8, {"arms": [Vector2(60, 70), Vector2(50, 75)], "lean": -3.0, "head": 0.0}],   # as mãos meio para cima
		[7.5, {"arms": [Vector2(65, 80), Vector2(55, 80)], "x": X0 + 0.9}],
		[8.4, {"arms": [Vector2(55, 70), Vector2(45, 70)]}],
		[8.75, {"lean": 6.0, "x": X0 + 0.85, "head": -10.0}, "out"],   # puxado pela gola
		[8.95, {"lean": 3.0}],
		[9.25, {"lean": -30.0, "x": X0 + 1.2, "z": 8.45, "hip": 0.78, "legs": [Vector2(-20, 10), Vector2(15, 20)],   # o empurrão
			"arms": [Vector2(110, 20), Vector2(130, 30)]}, "in"],
		[9.6, {"lean": -55.0, "x": X0 + 1.9, "z": 8.15, "hip": 0.6, "legs": [Vector2(25, 40), Vector2(-10, 30)],
			"arms": [Vector2(150, 30), Vector2(120, 20)]}],
		[9.95, {"lean": -88.0, "x": X0 + 2.2, "z": 8.05, "hip": 0.13, "legs": [Vector2(75, 30), Vector2(85, 20)],   # no chão
			"arms": [Vector2(250, 0), Vector2(240, 5)], "head": 10.0}, "in"],
		[10.08, {"hip": 0.18, "lean": -84.0}, "out"],
		[10.2, {"hip": 0.13, "lean": -90.0, "head": 0.0}, "in"],
		[10.8, {"legs": curl, "arms": cover}],
	]
	for h: Array in HITS:   # a cada pancada, encolhe de uma vez e afrouxa devagar
		var at: float = h[0]
		var jolt := 0.08 if h[1] == 1 else 0.03
		k.append_array([
			[at - 0.02, {"legs": curl, "hip": 0.13, "lean": -90.0, "x": X0 + 2.2}],
			[at + 0.04, {"legs": [Vector2(140, 115), Vector2(130, 105)], "hip": 0.16, "lean": -86.0, "x": X0 + 2.2 + jolt}, "in"],
			[at + 0.3, {"legs": curl, "hip": 0.13, "lean": -90.0, "x": X0 + 2.2}, "out"]])
	k.append_array([
		[20.5, {"legs": [Vector2(100, 70), Vector2(95, 60)], "arms": [Vector2(85, 5), Vector2(95, 0)]}],   # largado, os braços no chão
		[21.9, {}],
		[23.2, {"lean": -50.0, "hip": 0.45, "x": 6.2 - 0.73, "z": 8.1, "legs": [Vector2(70, 15), Vector2(75, 10)],   # levantado pela gola
			"arms": [Vector2(-10, 5), Vector2(5, 5)], "head": 25.0}, "out"],
	])
	var n := 14   # arrastado: as pernas sacodem no chão a cada passo dele
	for i in n + 1:
		var u := float(i) / n
		k.append([lerpf(23.5, 28.3, u), {"x": lerpf(6.2, 11.6, u) - 0.73, "hip": 0.45 + 0.02 * (i % 2),
			"legs": [Vector2(70 + 4 * (i % 2), 15), Vector2(75 - 4 * (i % 2), 10)]}])
	return k


## Os momentos completos: cada um com o que veio antes (`STAND` no começo).
static func _build(keys: Array) -> Array:
	var out := []
	var pose: Dictionary = STAND.duplicate(true)
	for key: Array in keys:
		pose = pose.merged(key[1], true)
		out.append([key[0], pose, key[2] if key.size() > 2 else ""])
	return out


## A pose no instante `t`, entre os dois momentos em volta, pela curva do de depois. O que não é número (o sentido,
## de frente, o cassetete) vale o do momento de antes; andando, o quadro da passada sai da distância andada.
static func _at(track: Array, t: float) -> Dictionary:
	var i := 0
	while i < track.size() - 1 and t >= track[i + 1][0]:
		i += 1
	var a: Dictionary = track[i][1]
	if i == track.size() - 1:
		return a.merged({"step": -1})
	var b: Dictionary = track[i + 1][1]
	var u := clampf((t - track[i][0]) / maxf(track[i + 1][0] - track[i][0], 0.001), 0.0, 1.0)
	match track[i + 1][2]:
		"in":
			u = u * u
		"out":
			u = 1.0 - (1.0 - u) * (1.0 - u)
		_:
			u = smoothstep(0.0, 1.0, u)
	var out := a.duplicate()
	for key: String in ["x", "z", "hip", "lean", "head"]:
		out[key] = lerpf(a[key], b[key], u)
	for key: String in ["legs", "arms"]:
		out[key] = [(a[key][0] as Vector2).lerp(b[key][0], u), (a[key][1] as Vector2).lerp(b[key][1], u)]
	out["step"] = -1
	if a["walk"]:   # (o quadro pela distância desde o primeiro momento desse trecho a pé)
		var j := i
		while j > 0 and track[j - 1][1]["walk"]:
			j -= 1
		var dist := 0.0
		for m in range(j, i):
			dist += Vector2(track[m + 1][1]["x"] - track[m][1]["x"], track[m + 1][1]["z"] - track[m][1]["z"]).length()
		dist += Vector2(out["x"] - a["x"], out["z"] - a["z"]).length()
		out["step"] = int(dist / STEP)
	return out
