extends RefCounted
## O fim da presa (`StreetEvent` "arrest", posto pelo `Main.start_ending` no lugar do relatório): o homem de sobretudo
## das noites 13 e 14 vem pela calçada de lá, sem pressa, fumando, e para embaixo do poste da esquina (`Background.MAN_X`),
## de frente para a central. Enquanto ele olha para a janela, uma viatura vem pela mão de cá, com a sirene girando e sem
## som, e para em frente ao prédio (`CAR_*`); descem os dois policiais pelo lado da rua (o do banco de trás e o
## motorista: o lado de cá dela fica embaixo do peitoril), dão a volta pela traseira e vão para a porta, sumindo atrás
## do arbusto. Ele dá uma última tragada, deixa o cigarro cair, pisa
## nele e atravessa a rua atrás deles, contornando a traseira da viatura, crescendo, até sumir atrás do arbusto também.
## Só o roteiro, como o `Beating`: tudo sai do tempo `t` (s desde o começo), sem estado.

const Beating := preload("res://scripts/ui/beating.gd")
const FROM := Vector2(13.0, 8.7)   ## de onde ele vem (x, z em m: a calçada de lá, fora do vidro)...
const POST := Vector2(6.7, 8.7)    ## ...onde para (`Background.MAN_X`, a 1,1 m do meio-fio de lá)...
const CAR_AT := 4.0   ## quando a viatura aparece, vindo pela mão de cá (s)
const STOP_SEC := 3.2 ## quanto ela leva freando até parar (`Background.TAXI_STOP.x`)
const CAR_MID := -0.4  ## onde o meio dela para (x, m): em frente ao prédio, à esquerda do arbusto (as portas brancas à vista)
const CAR_LEN := 4.5  ## o sedã (`Background.PATROL_KIND`)
const CAR_Z := 3.95   ## o meio dela, encostada no meio-fio de cá (z, m; 1,8 de largura)
const CAR_NEAR := CAR_Z - 0.9   ## o lado de cá dela: quem está mais perto é desenhado na frente dela
const DOOR := Vector2(-3.0, 2.2)   ## a porta da central, embaixo da janela, um pouco atrás da traseira da viatura (ali já some atrás do arbusto)
const CORNER := Vector2(CAR_MID - CAR_LEN / 2.0 - 0.8, CAR_Z + 1.3)   ## por onde ele contorna a traseira dela
const COP_WALK := 1.5   ## m/s, os policiais
const WALK := 1.3    ## m/s, sem pressa
const DROP := 0.4    ## quanto o cigarro leva caindo da mão ao chão (s)
const FALL_FROM := 0.86   ## a altura da mão caída (m), de onde o cigarro cai
## Os braços (`Beating.STAND`; de frente, só para a frente e para trás: o 0 é o de cá):
const SMOKE := [Vector2(60, 112), Vector2(4, 8)]   ## a mão de cá na boca, a tragada
const HANG := [Vector2(6, 10), Vector2(4, 8)]      ## caídos, a brasa rente ao casaco
const COAT := {"cop": false, "hat": "fedora", "long": true, "skin": 0, "cloth": Pal.STRANGER[0], "pants": Pal.STRANGER[1]}

static var _track: Array = []
static var _puff_at := 0.0    # quando ele tira o cigarro da boca
static var _drop_at := 0.0    # quando ele solta o cigarro
static var _stamp_at := 0.0   # quando pisa nele
static var _end := 0.0        # quando ele some atrás do arbusto
static var _cops: Array = []  # o roteiro de cada policial


## A pose dele no instante `t` (`x`, `z` em m, o rig de `Background._draw_rig`; `ember`: o cigarro na mão); vazio
## depois que ele entra atrás do arbusto.
static func man(t: float) -> Dictionary:
	_build_all()
	return {} if t >= _end else Beating._at(_track, maxf(t, 0.0))


## Os policiais que estão na rua no instante `t` (entre descer da viatura e sumir atrás do arbusto).
static func cops(t: float) -> Array:
	_build_all()
	var out := []
	for track: Array in _cops:
		if t >= track[0][0] and t < track[-1][0]:
			out.append(Beating._at(track, t))
	return out


## Quando as portas da viatura batem (s desde que ela para): cada policial descendo.
static func slams() -> Array:
	_build_all()
	return _cops.map(func(track: Array) -> float: return track[0][0] + 0.4 - CAR_AT - STOP_SEC)   # (desceu e fechou)


## Onde está a brasa do cigarro caído (x, z, altura em m; `w` de 0 a 1, o quanto ainda está acesa); NAN em x antes de
## ele soltar e depois de pisar.
static func butt(t: float) -> Vector3:
	_build_all()
	if t < _drop_at or t >= _stamp_at + 0.15:
		return Vector3(NAN, 0.0, 0.0)
	var u := clampf((t - _drop_at) / DROP, 0.0, 1.0)
	return Vector3(POST.x - 0.2 + 0.25 * u, POST.y - 0.12 * u, FALL_FROM * (1.0 - u * u))


## Segundos desde que ele tirou o cigarro da boca (o sopro da fumaça, `Background._draw_smoke`; -1 antes).
static func exhale(t: float) -> float:
	_build_all()
	return t - _puff_at if t >= _puff_at else -1.0


## Quando o cigarro bate no chão (s).
static func landed() -> float:
	_build_all()
	return _drop_at + DROP


## Anda pelos pontos `pts` (x, z) a `v` m/s desde `t`, a passo igual, sem frear nas voltas (de frente quando vem
## mais para cá do que para o lado); devolve quando chega. (O sentido e o "de frente" valem do momento de antes:
## cada trecho leva os do ponto onde começa.)
static func _path(k: Array, t: float, pts: Array, v: float) -> float:
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var key := {"x": a.x, "z": a.y, "walk": true, "swing": true, "front": absf(b.x - a.x) < absf(b.y - a.y)}
		if absf(b.x - a.x) > 0.05:
			key["s"] = signf(b.x - a.x)
		k.append([t, key, "lin" if i > 1 else ""])
		t += a.distance_to(b) / v
	k.append([t, {"x": pts[-1].x, "z": pts[-1].y}, "lin"])
	return t


## Os passos de `a` a `b` (s): cada pé que bate no chão.
static func footfalls(a: float, b: float) -> int:
	var sa: int = man(a).get("step", -1)
	var sb: int = man(b).get("step", -1)
	if sb < 0:
		return 0
	return 1 if sa < 0 or floori(sb / 4.0) != floori(sa / 4.0) else 0   # (`STRIDE`: 4 quadros por meia passada)


## Quando a cena acaba (s): o último a sumir atrás do arbusto.
static func end() -> float:
	_build_all()
	return maxf(_end, _cops.map(func(track: Array) -> float: return track[-1][0]).max())


static func _build_all() -> void:
	if not _track.is_empty():
		return
	var p: Dictionary = COAT.merged({"x": FROM.x, "z": FROM.y, "s": -1.0, "front": false, "arms": HANG, "ember": true})
	var k := [[0.0, p]]
	var t := Beating.walk(k, 0.0, FROM, POST, WALK)   # pela calçada de lá até o poste, freando no fim
	k.append([t + 0.35, {"front": true}])   # vira para a central
	t += 2.2   # olhando para a janela
	k.append([t, {}])
	k.append([t + 0.6, {"arms": SMOKE}])   # a última tragada...
	t += 1.6
	_puff_at = t
	k.append([t, {}])
	k.append([t + 0.7, {"arms": HANG}, "out"])   # ...e a mão descendo devagar
	t += 1.2
	_drop_at = t
	k.append([t, {"ember": false}])   # os dedos abrem: o cigarro cai
	t += DROP + 0.5
	k.append([t, {"legs": [Vector2(28, 50), Vector2(0, 0)]}])   # ergue o pé de cá...
	_stamp_at = t + 0.25
	k.append([_stamp_at, {"legs": Beating.STAND["legs"]}, "in"])   # ...e pisa, firme
	k.append([_stamp_at + 0.5, {"legs": [Vector2(4, 2), Vector2(0, 0)]}])   # torcendo o pé em cima
	t = _stamp_at + 1.2
	k.append([t, {"legs": Beating.STAND["legs"]}])
	_end = _path(k, t + 0.6, [POST, CORNER, DOOR], WALK)   # atravessa a rua até a porta do prédio, pela traseira da viatura
	_track = Beating._build(k)
	var stop := CAR_AT + STOP_SEC
	var rear := CAR_MID - CAR_LEN / 2.0
	var cop := {"cop": true, "baton": false, "front": true}
	for c: Array in [[stop + 0.7, [Vector2(CAR_MID - 0.6, CAR_Z + 1.2), Vector2(rear - 0.6, CAR_Z + 1.0), Vector2(DOOR.x + 0.5, DOOR.y)]],   # o do banco de trás
			[stop + 1.2, [Vector2(CAR_MID + 0.5, CAR_Z + 1.2), Vector2(rear - 0.9, CAR_Z + 1.1), Vector2(DOOR.x, DOOR.y)]]]:   # e o motorista
		var ck := [[c[0], cop.merged({"x": c[1][0].x, "z": c[1][0].y, "s": -1.0})]]
		_path(ck, c[0] + 0.5, c[1], COP_WALK)
		_cops.append(Beating._build(ck))
