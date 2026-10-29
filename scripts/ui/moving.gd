extends RefCounted
## A fuga da família do apartamento da varanda na noite 14 (`StreetEvent` "moving"), antes do toque de recolher: uma
## Kombi encosta no meio-fio de lá, um pouco depois do hotel, como quem estaciona, e o motorista não desce. Na varanda
## do apartamento do prédio de tijolos (`Background.APT`), alguém sai e recolhe a roupa do varal, peça por peça
## (`balcony`), e entra; a luz da sala e a TV apagam (`gone`). A família desce às pressas pela rua do cruzamento, a mãe
## com uma mala e o filho do lado, o pai atrás com outra mala, olhando para trás; atravessam a boca da rua e entram pela
## porta da Kombi do lado da calçada, que sai em seguida. O apartamento fica vazio até o fim do jogo, com as plantas
## deixadas na varanda (`Background.left_behind`). Só o roteiro, como o `Beating`: tudo sai do tempo `t` (s desde que a
## Kombi aparece), sem estado.

const Beating := preload("res://scripts/ui/beating.gd")
const CAR := "kombi"
const PARK := Vector2(6.4, 7.45)   ## a mão de lá (`CAR_LANES[0]`) e onde a Kombi encosta (z, m: o lado de lá quase no meio-fio)
const CAR_MID := -5.6   ## onde o meio dela para (x, m; `Background._taxi_x`): na frente do hotel, a traseira já passando a porta (mais para lá, a vista corta a frente)
const ARRIVE := 3.2    ## quando ela para (`Background.TAXI_STOP.x`)
const WALK := 1.7   ## m/s (às pressas)
const FROM := Vector2(5.0, 13.0)   ## de onde a família vem, descendo a calçada da rua do cruzamento (do lado do prédio)
const CORNER := Vector2(4.6, 8.4)
const DOOR := Vector2(CAR_MID + 0.4, 8.2)   ## a porta da Kombi do lado da calçada (atrás dela: quem chega some nela)
const FAMILY_AT := 15.0   ## quando a família aparece na rua do cruzamento (s)
## A varanda: quando quem recolhe a roupa sai pela porta, o tempo de cada peça e quando a luz e a TV apagam.
const BALCONY_AT := 4.0
const PIECE_SEC := 1.5
const DARK_AT := 13.0
const BALCONY_WALK := 2.0   ## da porta até o varal (s)

static var _tracks := {}
static var _in := {}   # quando cada um entra na Kombi


## Quem está na cena no instante `t` (cada um entre aparecer e entrar na Kombi).
static func figures(t: float) -> Array:
	if t < 0.0:
		return []
	_build_all()
	var out := []
	for id: String in ["mother", "child", "father"]:
		var track: Array = _tracks[id]
		if t >= track[0][0] and t < track[-1][0]:
			out.append(Beating._at(track, t))
	return out


## Quem recolhe a roupa na varanda no instante `t`: Vector3(onde está (-1 na porta; 0, 1, 2 embaixo de cada peça do
## varal, contínuo entre elas; -9: ninguém), 1 andando, 1 com o braço erguido no varal).
static func balcony(t: float) -> Vector3:
	var n := Pal.LAUNDRY.size()
	var u := t - BALCONY_AT
	var take := PIECE_SEC * n
	if u < 0.0 or u >= BALCONY_WALK * 2.0 + take:
		return Vector3(-9.0, 0.0, 0.0)
	if u < BALCONY_WALK:
		return Vector3(-1.0 + smoothstep(0.0, 1.0, u / BALCONY_WALK), 1.0, 0.0)
	u -= BALCONY_WALK
	if u >= take:
		return Vector3(lerpf(n - 1.0, -1.0, smoothstep(0.0, 1.0, (u - take) / BALCONY_WALK)), 1.0, 0.0)
	var piece := floorf(u / PIECE_SEC)
	var f := fmod(u, PIECE_SEC) / PIECE_SEC
	var on := piece < n - 1 and f >= 0.6   # (indo para a próxima peça)
	return Vector3(piece + (smoothstep(0.6, 1.0, f) if on else 0.0), 1.0 if on else 0.0, 1.0 if f < 0.6 else 0.0)


## Quantas peças de roupa ainda estão no varal no instante `t` (antes da cena, todas; tiradas da primeira em diante).
static func laundry(t: float) -> int:
	var n := Pal.LAUNDRY.size()
	if t < 0.0:
		return n
	return n - clampi(int(floorf((t - BALCONY_AT - BALCONY_WALK) / PIECE_SEC - 0.6)) + 1, 0, n)


## O apartamento já está vazio no instante `t` (a luz e a TV apagadas; a marca da cena nas noites seguintes).
static func gone(t: float) -> bool:
	return t >= DARK_AT


## Quanto a Kombi fica parada (s, desde que para) e quando a porta de correr bate (s depois de parar).
static func wait() -> float:
	_build_all()
	return _in.values().max() + 1.0 - ARRIVE


static func slams() -> Array:
	_build_all()
	return [_in.values().max() + 0.3 - ARRIVE]


## Para onde quem está na calçada olha (x, m; INF: nada): a família atravessando.
static func focus(t: float) -> float:
	_build_all()
	return Beating._at(_tracks["father"], t)["x"] if t >= FAMILY_AT and t < _in["father"] else INF


static func _build_all() -> void:
	if not _tracks.is_empty():
		return
	_tracks["mother"] = Beating._build(_keys("mother"))
	_tracks["child"] = Beating._build(_keys("child"))
	_tracks["father"] = Beating._build(_keys("father"))


## Cada um da família: desce a rua do cruzamento de frente, vira na esquina e atravessa a boca da rua até a porta da
## Kombi. A mãe na frente com uma mala, o filho do lado dela (menor, de mão dada), o pai atrás com a outra mala, que
## olha para trás no meio da travessia.
static func _keys(id: String) -> Array:
	var off: Vector2 = {"mother": Vector2.ZERO, "child": Vector2(0.3, -0.3), "father": Vector2(0.9, 0.35)}[id]
	var t0: float = FAMILY_AT + {"mother": 0.0, "child": 0.0, "father": 0.9}[id]
	var pose := {"x": FROM.x + off.x, "z": FROM.y + off.y, "s": -1.0, "front": true, "skin": 0, "hat": "", "cop": false,
		"pants": Pal.MOVING[0]}
	match id:
		"mother":
			pose.merge({"cloth": Pal.MOVING[2], "pants": Pal.MOVING[2], "case": true})
		"child":
			pose.merge({"cloth": Pal.MOVING[3], "size": 0.62})
		"father":
			pose.merge({"cloth": Pal.MOVING[1], "case": true})
	var to := DOOR + Vector2(off.x * 0.6, 0.0)
	var path := [FROM + off, CORNER + off, to]
	if id == "father":   # no meio da travessia, olha para trás, para a rua do cruzamento, sem parar de andar
		path = [FROM + off, CORNER + off, (CORNER + off).lerp(to, 0.3), (CORNER + off).lerp(to, 0.55), to]
	pose.merge({"walk": true, "swing": id == "child"})
	var k := [[t0, pose]]
	var t := t0
	for i in range(1, path.size()):   # o passo igual do começo até a porta, que eles entram andando (sem frear: `Beating.walk` freia no fim)
		t += (path[i] as Vector2).distance_to(path[i - 1]) / WALK
		var key := {"x": path[i].x, "z": path[i].y}
		if i == 1:   # (na esquina: de perfil, para a esquerda)
			key["front"] = false
		elif id == "father" and i < path.size() - 1:
			key["back"] = i == 2
		k.append([t, key, "lin"])
	_in[id] = t
	return k
