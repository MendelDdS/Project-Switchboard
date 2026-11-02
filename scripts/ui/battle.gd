extends RefCounted
## O combate da noite 15 (`StreetEvent` "battle"), longe, atrás da cidade: às 21:20 um clarão amarelo no horizonte, à
## esquerda da igreja, e logo a fumaça do incêndio subindo, acesa de baixo; até a meia-noite, estouros (o clarão no céu
## e, depois, o estrondo, pela distância) e rajadas (as faíscas no horizonte, o pipocar e, das mais perto, os traçantes
## riscando o céu por trás da igreja); depois, o fogo ainda forte até a 1h, apagando até as 4h, e a última fumaça. Desenhado entre o céu e a
## cidade (`Background._battle`, `_battle_add`): o que fica atrás dos telhados e da igreja some neles. Como o `Flare`:
## tudo sai do tempo `t` (s desde as 21:20), sorteado por ele, sem estado.

const FIRE := Vector3(-22.0, 280.0, 0.0)   ## o incêndio (x ao longo da rua, z distância, h altura; m): atrás da cidade, à esquerda da igreja
const CATCH := 8.0       ## quanto o fogo leva para pegar de todo (s): primeiro a luz amarela no horizonte...
const SMOKE_AT := 3.0    ## ...e a fumaça começando a subir depois
const FIGHT := 213.0     ## até quando se luta (s): das 21:20 à meia-noite, a 0,75 min de jogo por segundo
const DOUSE := 293.0     ## depois, o fogo ainda forte até a 1h (s)...
const EMBERS := 240.0    ## ...e apagando até as 4h (s; 3 h de jogo): o amanhecer já não tem incêndio
const SMOKE_LIFE := 60.0   ## quanto cada bolota da fumaça leva subindo até sumir (s)
const SMOKE_EVERY := 1.2   ## de quanto em quanto tempo sai uma (s)
const RISE := 7.0        ## m/s subindo...
const WIND := 0.9        ## ...e m/s indo para a esquerda (mais no alto, `SHEAR`), o mesmo vento do sinalizador
const SHEAR := 1.2
const PUFF := Vector3(20.0, 0.5, 0.6)   ## o raio de uma bolota ao sair (m), quanto ela abre por segundo e a força
const END := DOUSE + EMBERS + SMOKE_LIFE
const SLOT := 1.0        ## o combate em fatias de 1 s, cada uma sorteada: um estouro, uma rajada ou nada...
const BOOM := 0.07       ## ...a chance de um estouro (no auge)...
const BURST := 0.3       ## ...e a de uma rajada
const WARM := 20.0       ## o combate crescendo no começo (s)
const SOUND := 340.0     ## m/s: o estrondo chega depois do clarão
const BLAST_SEC := 0.8   ## quanto o clarão de um estouro leva sumindo
const BLAST_SMOKE := 25.0   ## e a fumaça dele subindo (s)
const SHOTS := Vector2i(4, 9)   ## os tiros de uma rajada...
const GAP := Vector2(0.07, 0.13)   ## ...e o intervalo entre eles (s)
const TRACE := 4         ## um traçante a cada tantos tiros (nas rajadas de perto)
const TRACE_SEC := 1.0   ## quanto um traçante leva voando à vista (s)...
const TRACE_V := Vector3(200.0, 0.0, 260.0)   ## ...a velocidade dele (m/s; x de lado, para o lado da rajada, h para cima: em diagonal, subindo)...
const TRACE_TAIL := 0.15   ## ...e o tanto de voo que se vê aceso de uma vez (s): uma linha reta, inteira


## A força do fogo no instante `t` (0 a 1), sem a cintilação: pegando, aceso e apagando da 1h às 4h.
static func fire(t: float) -> float:
	if t < 0.0 or t >= DOUSE + EMBERS:
		return 0.0
	return smoothstep(0.0, CATCH, t) * (1.0 - smoothstep(DOUSE, DOUSE + EMBERS, t))


## A força do fogo com a cintilação: as chamas mudando aos trancos, suavizados (`Flare.noise`, o mesmo sorteio).
static func flicker(t: float) -> float:
	var u := t * 6.0
	var n := floorf(u)
	return fire(t) * (0.8 + 0.2 * lerpf(noise(n), noise(n + 1.0), smoothstep(0.0, 1.0, u - n)))


## O quanto se luta no instante `t` (0 a 1): crescendo no começo, em ondas (a luta aperta e afrouxa) e parando à meia-noite.
static func heat(t: float) -> float:
	if t < 4.0 or t >= FIGHT:
		return 0.0
	return smoothstep(4.0, WARM, t) * (0.35 + 0.65 * (0.5 + 0.5 * sin(t / 17.0 + 2.0 * sin(t / 41.0))))


## Um número de 0 a 1 sorteado por `n`, sem estado (o do `Flare`).
static func noise(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


## Os estouros e as rajadas que começam de `t0` a `t1` (s): {kind ("boom" ou "burst"), at, pos (x, z, h; m), id e,
## nas rajadas, shots (os instantes de cada tiro, desde `at`) e trace (com traçantes: as de perto, por trás da igreja;
## e o lado para onde atiram, `side`)}.
static func events(t0: float, t1: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in range(maxi(0, floori(t0 / SLOT)), floori(t1 / SLOT) + 1):
		var at := (n + noise(n * 1.7 + 0.3)) * SLOT
		var h := heat(at)
		if at < t0 or at >= t1 or h <= 0.0:
			continue
		var r := noise(n * 3.1 + 0.7)
		if r < BOOM * h:
			out.append({"kind": "boom", "at": at, "id": n,
				"pos": Vector3(lerpf(-160.0, 160.0, noise(n * 5.3)), lerpf(260.0, 650.0, noise(n * 7.7)), 0.0)})
		elif r < (BOOM + BURST) * h:
			var trace := noise(n * 9.1) < 0.45
			var shots: Array[float] = []
			var s := 0.0
			for i in lerpf(SHOTS.x, SHOTS.y + 0.99, noise(n * 2.9)):
				shots.append(s)
				s += lerpf(GAP.x, GAP.y, noise(n * 4.1 + i))
			var z := lerpf(180.0, 320.0, noise(n * 6.7)) if trace else lerpf(260.0, 700.0, noise(n * 6.7))
			out.append({"kind": "burst", "at": at, "id": n, "shots": shots, "trace": trace, "side": 1.0 if noise(n * 8.3) < 0.5 else -1.0,
				"pos": Vector3(lerpf(-130.0, 130.0, noise(n * 5.9)), z, lerpf(5.0, 40.0, noise(n * 1.3)) if trace else 0.0)})
	return out


## De onde a rajada `e` atira (m): a de longe, onde ela está; a com traçantes, de um lado da igreja, para que eles
## cruzem o céu por trás dela, de um lado ao outro.
static func muzzle(e: Dictionary) -> Vector3:
	var p: Vector3 = e["pos"]
	if not e["trace"]:
		return Vector3(p.x, p.y, 2.0)
	return Vector3(-float(e["side"]) * 150.0 + (noise(e["id"] * 4.7) - 0.5) * 60.0, p.y, p.z)


## Onde o traçante do tiro dado da rajada `e` está, `s` s depois do tiro (m): sai da arma (`muzzle`, atrás dos telhados,
## cada um com o seu desvio) e sobe reto pelo céu, em diagonal, para o lado `side` (uma bala: nada de curva).
static func tracer(e: Dictionary, shot: int, s: float) -> Vector3:
	var side: float = e["side"]
	var v := Vector3(TRACE_V.x * side, (noise(e["id"] * 3.3 + shot) - 0.5) * 30.0, TRACE_V.z + (noise(e["id"] * 7.1 + shot) - 0.5) * 60.0)
	return muzzle(e) + v * s


## As bolotas da fumaça no instante `t`: Vector4(x, z, h, idade em s), da mais velha (mais alta) para a mais nova; a do
## incêndio e a de cada estouro recente (mais escura, que sobe menos), com a força em `w` negativa (`puff`).
static func smoke(t: float) -> Array[Vector4]:
	var out: Array[Vector4] = []
	var s := maxf(SMOKE_AT, floorf((t - SMOKE_LIFE) / SMOKE_EVERY) * SMOKE_EVERY)
	while s <= t:
		var age := t - s
		if fire(s) > 0.05 and age < SMOKE_LIFE:
			var h := RISE * age * (1.0 - 0.25 * age / SMOKE_LIFE) * lerpf(0.5, 1.0, fire(s))   # (mais devagar no alto; com o fogo fraco, mais baixa)
			var curl := 18.0 * sin(TAU * h / 160.0 + noise(s) * 2.0) * minf(1.0, age / 15.0)
			out.append(Vector4(FIRE.x - WIND * age * (1.0 + SHEAR * h / 300.0) + curl, FIRE.y + (noise(s * 1.9) - 0.5) * 20.0, h, age))
		s += SMOKE_EVERY
	return out


## A bolota `q` (de `smoke`, no instante `t`): Vector2(raio em m, força), as de perto do fogo maiores e mais fortes,
## abrindo e sumindo com a idade.
static func puff(t: float, q: Vector4) -> Vector2:
	var born := t - q.w
	var r := PUFF.x * (0.8 + 0.4 * noise(born * 3.7)) + PUFF.y * q.w * 1.6
	return Vector2(r, PUFF.z * fire(born) * (1.0 - pow(q.w / SMOKE_LIFE, 1.5)))
