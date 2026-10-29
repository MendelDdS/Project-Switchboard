extends RefCounted
## O sinalizador da noite 15 (`StreetEvent` "flare"), às 21h: atirado de longe, atrás da cidade, sobe riscando o céu,
## acende vermelho no alto e desce devagar no paraquedas, levado pelo vento e balançando, deixando a fumaça para trás,
## até apagar. Desenhado entre o céu e a cidade (`Background._flare`): o que desce atrás dos telhados some neles. A luz
## dele tinge a rua (`FLARE_TINT`), entra na sala (`FLARE_LIGHT`) e desenha a janela nela (`Background._flare_steep`). Só o roteiro, como o `Beating`: tudo sai do tempo `t` (s desde
## o tiro), sem estado.

const FROM := Vector3(70.0, 330.0, 20.0)   ## de onde sai (x ao longo da rua, z distância, h altura; m): bem atrás da cidade, à direita da igreja
const APEX := 360.0    ## a altura em que acende (m)
const RISE := 2.6      ## quanto leva subindo (s)
const LEAN := 10.0     ## quanto anda para a esquerda subindo (m)
const FALL := 2.4      ## m/s no paraquedas
const WIND := 0.9      ## m/s para a esquerda, ele e a fumaça
const SWAY := Vector2(2.5, 1.3)   ## o balanço do paraquedas: m de lado e rad/s
const BURN := 48.0     ## quanto queima depois de acender (s)...
const OUT := 4.0       ## ...e quanto leva apagando
const SMOKE := 14.0    ## quanto a fumaça do caminho fica à vista (s)
const BURST := 1.2     ## o estouro ao acender: quanto a mais no primeiro instante...
const BURST_SEC := 0.35   ## ...e em quanto ele cai (s)
const CRACKLE := 14.0  ## a cintilação do magnésio: quantas vezes por segundo a força muda...
const DIP := Vector2(0.07, 0.35)   ## ...e a chance de cada vez ser uma falha (queimando; apagando, `OUT`)
const END := RISE + BURN + SMOKE


## Onde está no instante `t` (m: x, z, h).
static func at(t: float) -> Vector3:
	if t <= RISE:
		var u := t / RISE
		return FROM + Vector3(-LEAN * u, 0.0, (APEX - FROM.z) * (1.0 - (1.0 - u) * (1.0 - u)))
	var d := t - RISE
	return Vector3(FROM.x - LEAN - WIND * d + SWAY.x * sin(SWAY.y * d) * minf(1.0, d / 3.0), FROM.y, APEX - FALL * d)


## A força da luz no instante `t`, sem a cintilação: 0 apagado (subindo, ou já apagado), 1 aceso, mais no estouro de
## quando acende (`BURST`).
static func light(t: float) -> float:
	var d := t - RISE
	if d < 0.0 or d >= BURN:
		return 0.0
	return minf(1.0, d / 0.12) * (1.0 + BURST * exp(-d / BURST_SEC)) * (1.0 - smoothstep(BURN - OUT, BURN, d))


## A força da luz no instante `t` com a cintilação: mudando aos trancos (`CRACKLE`), de 0,78 a 1, e às vezes falhando,
## mais quando está apagando (`DIP`). Sorteada pelo tempo, sem estado: a mesma a cada vez.
static func glow(t: float) -> float:
	var k := light(t)
	if k <= 0.0:
		return 0.0
	var u := t * CRACKLE
	var n := floorf(u)
	var v := lerpf(_hash(n), _hash(n + 1.0), smoothstep(0.0, 1.0, u - n))
	var dip := lerpf(DIP.x, DIP.y, smoothstep(BURN - OUT, BURN, t - RISE))
	return k * (0.78 + 0.22 * v) * (0.55 if _hash(n * 7.31 + 3.0) < dip else 1.0)


static func _hash(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


## Os pontos da fumaça no instante `t`: Vector4(x, z, h, idade em s), do mais novo ao mais velho, um a cada `step` s do
## caminho, levados pelo vento desde que ele passou ali (a da subida, só depois de acender; antes ela é o rastro).
static func smoke(t: float, step := 0.5) -> Array[Vector4]:
	var out: Array[Vector4] = []
	var s := minf(t, RISE + BURN)
	while s > 0.0 and t - s < SMOKE:
		var p := at(s)
		out.append(Vector4(p.x - WIND * (t - s), p.y, p.z + 0.6 * (t - s), t - s))
		s -= step
	return out
