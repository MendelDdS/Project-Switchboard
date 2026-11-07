extends RefCounted
## A bandeira da noite 15 (`StreetEvent` "banner"), no veredito das 4h, só com o golpe vencido (`requires` "golpe_venceu"):
## a luz da sala do apartamento vazio da varanda do prédio de tijolos (`Background.APT`) acende, a porta estala e um
## homem sai com a bandeira enrolada debaixo do braço; para no gradil, vira para a rua, ergue o rolo por cima do
## corrimão e o solta segurando a beira de cima: o pano desenrola caindo (`drop`), estala ao chegar no fim, quica e
## balança até assentar (`sway`). Ele amarra as pontas no corrimão, uma mão de cada vez, se endireita, fica olhando a
## rua, ergue o punho, baixa e volta para dentro. A luz fica acesa e a bandeira fica, mexendo com o vento, até o fim do
## turno, no amanhecer. Só o roteiro, como o `Beating`: tudo sai do tempo `t` (s desde que a luz acende), sem estado.

const Beating := preload("res://scripts/ui/beating.gd")
const SIZE := Vector2(1.3, 1.1)   ## a bandeira (m): a largura e quanto desce do corrimão
const DOOR := -1.2     ## a porta do apartamento, a partir de onde ele para no gradil (m; o meio da porta de `APT`, `Background._banner_x`)
const OUT_AT := 0.6    ## quando ele aparece na porta (s depois da luz)
const WALK := 1.0      ## m/s, sem pressa
const FALL := 3.9      ## m/s²: o pano desenrolando cai mais devagar que o peso solto (o rolo freia), ~0,75 s até o fim
const BOUNCE := Vector2(0.07, 0.3)   ## o rolo quicando ao esticar: quanto sobe (m) e em quanto tempo some (s)
const SWING := Vector3(0.08, 4.6, 1.1)   ## o balanço da beira de baixo: quanto vai para o lado (m), a frequência (rad/s) e em quanto some (s)
## Os braços (`Beating.STAND`; de frente, abertos no plano do desenho: o 0 à esquerda, ângulos negativos):
const CARRY := [Vector2(22, 72), Vector2(14, 80)]      ## de perfil, o rolo debaixo do braço
const LOW := [Vector2(-14, 46), Vector2(14, -46)]      ## de frente, o rolo na cintura
const LIFT := [Vector2(-75, -25), Vector2(75, 25)]     ## o rolo erguido na altura do peito
const RAIL := [Vector2(-60, -30), Vector2(60, 30)]     ## as mãos nas pontas, por cima da dobra no corrimão
const DOWN := [Vector2(-6, 4), Vector2(6, -4)]         ## de frente, caídos
const FIST := [Vector2(-168, -8), Vector2(6, -4)]      ## o punho erguido (a mão de cá, à esquerda)

static var _track: Array = []
static var _release := 0.0   # quando ele solta o rolo
static var _end := 0.0       # quando entra


## A pose de quem estende a bandeira no instante `t` (`x` a partir do gradil, m; vazio: ninguém).
static func man(t: float) -> Dictionary:
	_build_all()
	if t < OUT_AT or t >= _end:
		return {}
	return Beating._at(_track, t)


## Quanto da bandeira já desceu do corrimão no instante `t` (0 a 1; o rolo ainda nas mãos: 0).
static func drop(t: float) -> float:
	_build_all()
	var u := t - _release
	return clampf(0.5 * FALL * u * u / SIZE.y, 0.0, 1.0) if u > 0.0 else 0.0


## O pano assentando depois de esticar: Vector2(quanto a beira de baixo vai para o lado, quanto ela sobe) (m).
static func sway(t: float) -> Vector2:
	_build_all()
	var u := t - _release - sqrt(2.0 * SIZE.y / FALL)   # desde que esticou
	if u < 0.0:
		return Vector2.ZERO
	return Vector2(SWING.x * sin(u * SWING.y) * exp(-u / SWING.z), BOUNCE.x * absf(sin(u * PI / BOUNCE.y * 1.5)) * exp(-u / BOUNCE.y))


## Quando ele solta o rolo (s; o som do pano caindo começa ali).
static func release() -> float:
	_build_all()
	return _release


static func _build_all() -> void:
	if not _track.is_empty():
		return
	var p := {"x": DOOR, "z": 0.0, "s": 1.0, "front": false, "skin": 1, "hat": "beret", "cop": false, "cloth": Pal.REBEL[0],
		"pants": Pal.REBEL[1], "shirt": Pal.REBEL[2], "roll": true, "arms": CARRY}
	var k := [[0.0, p]]
	var t := Beating.walk(k, OUT_AT, Vector2(DOOR, 0.0), Vector2.ZERO, WALK)   # da porta ao gradil, freando no fim
	k.append([t + 0.2, {"front": true, "arms": LOW}])   # vira para a rua
	k.append([t + 0.8, {"arms": LIFT}, "out"])   # ergue o rolo por cima do corrimão
	k.append([t + 1.3, {"arms": RAIL, "hip": 0.78, "legs": [Vector2(4, 10), Vector2(-4, 10)]}])   # e o apoia nele, dobrando os joelhos
	_release = t + 1.4
	k.append([_release, {"roll": false}])
	t = _release + sqrt(2.0 * SIZE.y / FALL) + 0.6   # segura a beira enquanto o pano cai e assenta
	k.append([t, {}])
	for i in 4:   # amarra as pontas, uma mão de cada vez, aos trancos
		var a: Array = RAIL.duplicate()
		a[i % 2] = (RAIL[i % 2] as Vector2) + Vector2(-12.0 if i % 2 == 0 else 12.0, 0.0) * (1.0 if i < 2 else 0.6)
		k.append([t + 0.35 * (i + 1), {"arms": a}])
	t += 0.35 * 5
	k.append([t, {"arms": RAIL}])
	t += 0.5
	k.append([t, {"arms": DOWN, "hip": 0.82, "legs": Beating.STAND["legs"]}])   # se endireita
	t += 1.2
	k.append([t, {}])   # olhando a rua
	t += 0.35
	k.append([t, {"arms": FIST}, "out"])   # o punho erguido, rápido...
	t += 1.4
	k.append([t, {}])
	t += 0.5
	k.append([t, {"arms": DOWN}])   # ...e baixando devagar
	t += 0.6
	k.append([t, {"front": false, "s": -1.0, "arms": Beating.STAND["arms"]}])
	_end = Beating.walk(k, t + 0.2, Vector2.ZERO, Vector2(DOOR, 0.0), WALK)
	_track = Beating._build(k)
