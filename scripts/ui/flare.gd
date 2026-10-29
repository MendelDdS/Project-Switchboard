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
const SMOKE := 30.0    ## quanto a fumaça do caminho fica à vista (s)
const SHEAR := 0.8     ## o vento mais forte no alto: quanto a mais ele leva a fumaça lá em cima (o rastro da subida entorta)
const CURL := Vector3(12.0, 70.0, 8.0)   ## a fumaça ondulando com o tempo: quanto de lado (m), em quantos m de altura uma volta (e uma menor por cima, `_curl`), e em quantos s chega a isso
## O tamanho de cada bolota da fumaça (raio, m): a da subida, fina, a da queda, grossa (o magnésio queimando), e quanto
## ela abre por segundo; a força de cada uma e quanto ela vai se partindo com a idade (as bolotas somem antes do fim).
const PUFF := Vector4(2.4, 4.0, 0.3, 0.45)
const PUFF_A := 0.6
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
	var v := lerpf(noise(n), noise(n + 1.0), smoothstep(0.0, 1.0, u - n))
	var dip := lerpf(DIP.x, DIP.y, smoothstep(BURN - OUT, BURN, t - RISE))
	return k * (0.78 + 0.22 * v) * (0.55 if noise(n * 7.31 + 3.0) < dip else 1.0)


## Um número de 0 a 1 sorteado por `n`, sem estado: o mesmo `n` dá sempre o mesmo.
static func noise(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


## Os pontos da fumaça no instante `t`: Vector4(x, z, h, idade em s), do mais novo ao mais velho, ao longo do caminho
## (na subida, rápida, a cada 1/100 s; na queda, a cada meio segundo), levados pelo vento desde que ele passou ali, mais
## no alto (`SHEAR`), e ondulando aos poucos (`CURL`); a da subida, só depois de acender (antes ela é o rastro).
static func smoke(t: float) -> Array[Vector4]:
	var out: Array[Vector4] = []
	var s := minf(t, RISE + BURN)
	while s > 0.0 and t - s < SMOKE:
		var p := at(s)
		var age := t - s
		var curl := CURL.x * _curl(p.z) * (1.0 - exp(-age / CURL.z))
		out.append(Vector4(p.x - WIND * age * (1.0 + SHEAR * p.z / APEX) + curl, p.y, p.z + 0.6 * age, age))
		s -= 0.01 if s <= RISE else 0.5
	return out


## A bolota da fumaça `q` (de `smoke`, no instante `t`): Vector2(raio em m, força); força 0 é um buraco (ela vai se
## partindo com a idade, cada bolota no seu tempo), e cada uma tem o seu tamanho.
static func puff(t: float, q: Vector4) -> Vector2:
	var id := t - q.w   # (o instante em que ela saiu: a mesma bolota a cada quadro)
	if noise(id * 13.7) < PUFF.w * q.w / SMOKE:
		return Vector2.ZERO
	var r := (PUFF.x if id <= RISE else PUFF.y) + PUFF.z * q.w
	var bulge := 0.6 + 0.4 * sin(TAU * q.z / 31.0 + 2.0) + 0.3 * noise(id * 3.3)   # (engrossa e afina pelo caminho)
	return Vector2(r * bulge, PUFF_A * (1.0 - pow(q.w / SMOKE, 2.0)))


## A ondulação da fumaça na altura `h` (m), de -1,5 a 1,5: uma volta larga e uma menor, desencontradas.
static func _curl(h: float) -> float:
	return sin(TAU * h / CURL.y + 1.3) + 0.5 * sin(TAU * h / 23.0 + 0.4)
