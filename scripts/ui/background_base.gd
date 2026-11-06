extends Control
## A base do cenário (`Background`): o estado em comum, a câmera da sala (`_proj`, `_p3`) e o desenho em pixel
## art (`_fill`, `_poly`, `_p`, `_pixel_line`, `_sprite`, `_light`). O cenário é dividido em camadas por herança:
## esta, a vista da janela (`background_view.gd`), os objetos da mesa (`background_props.gd`) e a sala com o resto
## (`background.gd`); cada uma só usa as de baixo.

const PX := 0.5          ## um pixel da tela nas unidades da câmera (px de 2x2): os detalhes são desenhados em 1x1
const CLEAN_TOL := 0.12  ## quanto a inclinação de uma beira longa pode mudar para cair numa limpa (`clean_slope`)
## A altura dos olhos acima do fundo do tampo, na tela (px de 2x2): o ponto de fuga, dentro da tela, na altura da
## janela. Era 210 (logo acima da tela): a mesa vista mais de cima, mas a parede da janela ficava a 44 cm da cabeça e a
## janela, bem abaixo dos olhos, descia uns 40°. Mais baixo, o que fica longe do ponto de fuga entorta mais.
const EYE := 90.0
# O operador está sentado à mesa e a câmera são os olhos dele: `SEAT_EYE` cm acima do tampo, com o fundo do tampo a
# `SEAT_BACK` cm (a parte da frente do tampo fica sob o console do painel; a tela mostra a de trás). A tela fixa onde
# ficam o ponto de fuga e o fundo do tampo (`EYE` px abaixo dele); o que resta é a distância focal, que sai da
# conta: a altura dos olhos sobre a distância ao fundo do tampo é a mesma na sala e na tela (`EYE` / `Z0` × `DESK_T`).
# Com uma distância focal menor (era 330), a mesa era vista de cima como por alguém em pé (a ~38° em vez de ~22–29°
# para baixo) e as profundidades saíam exageradas: a prancheta mais larga que funda, o relógio torto.
const SEAT_EYE := 45.0    ## a altura dos olhos acima do tampo (cm), sentado
const SEAT_BACK := 110.0  ## dos olhos ao fundo do tampo (cm), na horizontal
const Z0 := EYE * SEAT_BACK / SEAT_EYE   ## a distância dos olhos à parede do fundo (e a distância focal, em px de 2x2)
const WALL_K := 1.4   ## a parede do fundo fica a `Z0` × isto: afastada, o que está nela encolhe em volta do ponto de fuga e a quina
## anda para perto dele (a parede da direita, e com ela a janela, ganha a largura; o plano dela e a mesa não mudam)
## A chuva muda de força durante a noite (`rain_level`: de garoa, `RAIN_LEVEL.x`, a forte, 1), em ondas lentas de
## `RAIN_SPAN` min de jogo (duas, cada noite com as suas fases), em degraus de `RAIN_STEP`: o som (`Sfx.set_rain`), os
## pingos no vidro, o vento no arbusto e os relâmpagos (só com ela acima de `BOLT_RAIN`) seguem. A rua vai ficando mais
## molhada até `SOAK_MIN` min de chuva (as poças crescem).
const RAIN_LEVEL := Vector2(0.15, 1.0)
const RAIN_SPAN := Vector2(95.0, 37.0)
const RAIN_STEP := 0.05
## O amanhecer da última noite (o céu de verdade em 22/10/1973, a ~22° S, sem horário de verão): começa a clarear às
## 4h05, o sol nasce às 5h25 e às 6h já é dia (min do dia, depois da meia-noite); os postes e o neon apagam às 5h15 e a
## rua acorda das 5h às 6h.
const DAWN := Vector2(28 * 60 + 5, 30 * 60)
const SUNRISE := 29 * 60 + 25
const STREET_OFF := 29 * 60 + 15
const MORNING := Vector2(29 * 60, 30 * 60)
const CLEAR_SPAN := 40.0   ## minutos em que a chuva afina até a garoa antes de parar (`clears_at`)
const SOAK_MIN := 150.0
const CLOUD_SPEED := 0.004
## A lua sobe durante a noite (`_moon_at`): nasce atrás da igreja (`MOON_RISE.x`, minutos do dia), anda `MOON_DRIFT`
## da largura do vidro (quase reta, pelo vão entre os prédios da esquina) e some atrás da persiana em `MOON_RISE.y`.
## Em y, fração do céu à vista (0: o alto do vidro abaixo da persiana; 1: o horizonte), de `MOON_PATH.x` (o meio dela
## no horizonte) a `MOON_PATH.y` (acima).
const MOON_RISE := Vector2(18 * 60, 22 * 60 + 15)
const MOON_PATH := Vector2(1.0, -0.35)
const MOON_DRIFT := -0.04
const SYNODIC := 29.530588853   ## o mês da lua, de uma lua nova à outra (dias)
const NEW_MOON := 947182440     ## uma lua nova conhecida (6/1/2000, 18h14 UTC), de onde se conta a fase
const BOLT_PULSES := [Vector2(0.0, 1.0), Vector2(0.14, 0.55), Vector2(0.42, 0.8)]   ## os clarões dele: quando (s) e a força
const SIDE_T := 1.03 / WALL_K   ## onde a janela começa na parede da direita (escala, a da parede em `Z0`; a quina fica em 1/`WALL_K`): logo depois dela; termina perto da borda da tela
## O ponto de fuga da parede da direita, à esquerda do da sala (px de 2x2): ela fica em ângulo, abrindo para a frente
## a partir da quina, que não muda, e o peitoril e o alto da janela ficam mais retos (no da sala, o peitoril descia
## demais). Só as linhas dela usam este (`_side_pt`); a mesa e a parede do fundo continuam no da sala.
const SIDE_VP := -73.0
const SIDE_W := 150.0       ## a largura do vão, de frente (só a resolução da projeção)
const WIN_TOP := -40.0      ## o alto do vão (cm a partir dos olhos, para baixo): acima deles

var weather := "rain"
var clears_at := INF   ## a hora (minutos do dia) em que a chuva para na noite (`Night.clears_at`; o Main atualiza)
var _moon_x0 := 0.5   # onde a lua nasce: o x da igreja em fração do vidro (a vista atualiza ao desenhar)
var night := 1   ## a noite do jogo (o Main atualiza): a data da folhinha na parede e a fase da lua
var sign_from := 0.0   ## desde quando o letreiro do hotel acende (min do dia; o Main: apagado na última noite, aceso às 2h com o golpe vencido)
var minutes := 18 * 60.0:   ## a hora do jogo (minutos do dia; o Main atualiza): o relógio de flip da mesa
	set(v):
		if int(v) != int(minutes):   # a plaqueta vira
			_flip_from = int(minutes)
			_flip_at = PixelArt.ms()
		minutes = v


var _flip_from := -1   # o minuto que a plaqueta mostrava antes de virar
var _flip_at := -100000   # quando ela começou a virar (ms)
var _mist := 0.0
var _day := Color.WHITE   # a luz do dia na cidade: o `modulate` da `_back` e da `_view` (`Background._process`)
var _vp := Vector2.ZERO   # o ponto de fuga (px de 2x2)
var _yd := 0.0         # a altura do tampo (y da sala, abaixo dos olhos)
var _cx := 0.0         # o plano da parede da direita, na tela onde ele estaria em `Z0` (px de 2x2): a mesa vai até ele
var _svp := Vector2.ZERO   # o ponto de fuga da parede da direita (`SIDE_VP`)
var _sx := 0.0         # a parede da direita a partir dele, na escala da parede em `Z0` (a quina fica em t = 1/`WALL_K`)
var _qx := 0.0         # a quina das paredes na tela (px de 2x2): o plano da direita na parede do fundo, `WALL_K` mais longe
var _t2 := 1.6         # onde a janela termina na parede da direita (escala)
var _ci: CanvasItem    # onde a vista da janela é desenhada: aqui, ou no vidro fora da tela
var _snap := false     # `_fill` prende os pontos no pixel inteiro (só onde se desenha em px da tela: a mesa e o tampo)
var _lifted: Control   # o objeto da mesa erguido sob o mouse, numa camada só dele (`Background._draw_lifted`)
var _props_layer: Control   # os objetos da mesa, numa camada por cima da persiana e da luz do peitoril (`Background._draw_props_layer`)
var _glows: Array = []  # as luzes da sala para o brilho (`_light`): [retângulo, cor, halo, miolo, redonda]
var _spills: Array = []  # as luzes dos objetos da mesa que caem no tampo em volta (`_light` com `spill`): [retângulo, cor, alcance]
var _lifted_spills: Array = []  # as do objeto erguido pelo mouse, que se desenha na camada dele (`_lifted`)
var _posts: Array[Rect2] = []   # as cabeças dos postes de lá à vista, para o brilho (acesas só com a luminária acesa: `_draw_over`)
## O sorteio do cenário (chuva, poeira, carros, gente): fora do global, que é da agenda e das falas e segue o
## `--seed` (o cenário sorteia a cada quadro do relógio real; no global, o turno mudava com o FPS). Semeado no `_ready`.
var _rng := RandomNumberGenerator.new()
var _rain_phase := Vector2(_rng.randf() * TAU, _rng.randf() * TAU)   # as fases das ondas da chuva nesta noite
var _clouds: Array[Vector3] = []   # as nuvens da noite limpa: x (fração do vidro, sem o vento), altura (fração do céu à vista), tamanho
var _bolt := -1.0        # há quanto tempo caiu o relâmpago (s; -1 = nenhum)


## A força do clarão do relâmpago agora (0 a 1): os pulsos dele, cada um sumindo depressa.
func _flash() -> float:
	var f := 0.0
	if _bolt >= 0.0:
		for p: Vector2 in BOLT_PULSES:
			if _bolt >= p.x:
				f = maxf(f, p.y * exp(-(_bolt - p.x) / 0.07))
	return f


## A força da chuva agora (`RAIN_LEVEL.x` = garoa, 1 = forte), pela hora: duas ondas lentas com as fases da noite.
func rain_level() -> float:
	var k := 0.55 + 0.3 * sin(TAU * minutes / RAIN_SPAN.x + _rain_phase.x) + 0.2 * sin(TAU * minutes / RAIN_SPAN.y + _rain_phase.y)
	k = lerpf(RAIN_LEVEL.x, k, _clearing())   # parando: afina até a garoa
	return snappedf(clampf(k, RAIN_LEVEL.x, RAIN_LEVEL.y), RAIN_STEP)


## O quanto da chuva ou da névoa ainda há (1; 0 quando elas param, `clears_at`, afinando nos `CLEAR_SPAN` min antes).
func _clearing() -> float:
	return 1.0 - clampf((minutes - clears_at + CLEAR_SPAN) / CLEAR_SPAN, 0.0, 1.0)


## O quanto já amanheceu (0 até as 4h05, 1 às 6h; `DAWN`): só na última noite o turno chega lá.
func dawn() -> float:
	return clampf((minutes - DAWN.x) / (DAWN.y - DAWN.x), 0.0, 1.0)


## O quanto a rua já acordou (0 às 5h, 1 às 6h; `MORNING`): mais gente e carro.
func morning() -> float:
	return clampf((minutes - MORNING.x) / (MORNING.y - MORNING.x), 0.0, 1.0)


## O dia da semana da noite (0 = domingo): na sexta e no sábado a rua tem mais gente, no domingo menos.
func weekday() -> int:
	return GameData.date_of(night).weekday


## O quanto a rua já está molhada (0..1): cresce com a noite de chuva, até `SOAK_MIN` min.
func _soaked() -> float:
	return clampf((minutes - 18 * 60.0) / SOAK_MIN, 0.0, 1.0) if weather == "rain" else 0.0


## Onde está cada nuvem agora (x em fração do vidro, levada pelo vento devagar).
func _cloud_x(c: Vector3) -> float:
	return fposmod(c.x + _mist / 3.6 * CLOUD_SPEED, 1.4) - 0.2


## A idade da lua na noite do jogo (dias desde a lua nova), às 21h de Brasília (meia-noite UTC): a do calendário de
## verdade (8 de outubro de 1973 é crescente quase cheia; a cheia vem no dia 11).
func _moon_age() -> float:
	var t := Time.get_unix_time_from_datetime_dict(GameData.date_of(night)) + 12 * 3600   # (`date_of` dá o meio-dia UTC)
	return fposmod((t - NEW_MOON) / 86400.0, SYNODIC)


## Quanto da lua está iluminado (0: nova, 1: cheia).
func _moon_lit() -> float:
	return (1.0 - cos(TAU * _moon_age() / SYNODIC)) / 2.0


## Quanto a lua já subiu (0: nascendo atrás da igreja; 1: sumiu atrás da persiana).
func _moon_t() -> float:
	return clampf((minutes - MOON_RISE.x) / (MOON_RISE.y - MOON_RISE.x), 0.0, 1.0)


## Onde a lua está agora: x em fração do vidro, y em fração do céu à vista (ver `MOON_RISE`).
func _moon_at() -> Vector2:
	var t := _moon_t()
	return Vector2(_moon_x0 + MOON_DRIFT * t, lerpf(MOON_PATH.x, MOON_PATH.y, t))


## A luz que a lua manda para a sala pela janela (0..1, em passos): a fase, as nuvens e se ela ainda está à vista.
func _moon_glow() -> float:
	if weather != "clear":
		return 1.0
	return snappedf(_moon_light() * _moon_lit() * smoothstep(MOON_PATH.y, MOON_PATH.y + 0.3, _moon_at().y), 0.05)


## A luz da lua agora (0..1): o quanto as nuvens a deixam aparecer, na noite limpa (as outras não têm lua).
func _moon_light() -> float:
	if weather != "clear":
		return 1.0
	var cover := 0.0
	for c in _clouds:
		var d := ((Vector2(_cloud_x(c), c.y) - _moon_at()) / Vector2(0.16 * c.z, 0.09 * c.z)).length()
		cover = maxf(cover, 1.0 - smoothstep(0.35, 1.0, d))
	return snappedf(1.0 - cover * 0.85, 0.05)


## O letreiro aceso: quase sempre; de vez em quando apaga um instante, como neon velho.
func _sign_on() -> bool:
	return minutes >= sign_from and minutes < STREET_OFF and not (int(PixelArt.ms() / 110.0) % 97 in [40, 42, 43, 71])


## A letra do letreiro que falha (`SIGN_BUZZ`) acesa: com ele aceso (`_sign_on`), ela falha sozinha, em rajadas.
func _sign_buzz_on() -> bool:
	return _sign_on() and not (int(PixelArt.ms() / 70.0) % 23 in [3, 4, 9, 15, 16, 17])


## Uma luz do cenário (`r` em px da tela) que brilha, a não ser que o papel de uma ferramenta esteja por cima dela.
## `spill`: até onde ela ilumina o tampo em volta (px; 0 = não ilumina), só nos objetos da mesa (`_window_lights`).
func _light(r: Rect2, col: Color, halo: float, round := false, core := true, spill := 0.0) -> void:
	if _ci == self or _ci == _props_layer:   # a vista da janela: as luzes dela vêm de `_draw_side_wall`, que sabe onde o vidro está
		_glows.append([r, col, halo, core, round])   # a camada de cima as acende, cortadas onde o papel está
		if spill > 0.0 and _ci == _props_layer:
			_spills.append([r, col, spill])
	elif _ci == _lifted:   # o objeto erguido: a luz sobe com a camada dele
		Bloom.light(_lifted, r, col, halo, core, round)
		if spill > 0.0:   # (e continua caindo no tampo: sem isso, ela sumia com o mouse em cima)
			_lifted_spills.append([r, col, spill])


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x, y, w, h), c)


## Um retângulo em px da tela (1x1) dentro do desenho em escala 2: os detalhes finos, na mesma densidade da interface.
func _p(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x * PX, y * PX, w * PX, h * PX), c)


## Uma linha em pixel art de `a` a `b` (px da tela, fora da escala e da perspectiva; como traço comum, torta,
## serrilhava): um pixel por passo na direção mais longa e, na outra, a espessura em `cols` (de cima para baixo, ou da
## esquerda para a direita). Depois volta a valer `back` (a transformação de quem chamou). As pontas vão para o pixel
## delas e, entre elas, os degraus saem distribuídos por igual (de pontas quebradas, saíam 1-2-1-3 numa reta só).
func _pixel_line(a: Vector2, b: Vector2, cols: Array, back := Transform2D.IDENTITY) -> void:
	_ci.draw_set_transform(Vector2.ZERO)
	a = a.floor()
	var d := b.floor() - a
	var n := maxi(1, int(maxf(absf(d.x), absf(d.y))))
	var flat := absf(d.x) >= absf(d.y)
	var o := floori(cols.size() / 2.0)
	for i in n + 1:
		var p := (a + d * i / n + Vector2(0.5, 0.5)).floor()
		for k in cols.size():
			_ci.draw_rect(Rect2(p + (Vector2(0, k - o) if flat else Vector2(k - o, 0)), Vector2.ONE), cols[k])
	_ci.draw_set_transform_matrix(back)


## Uma peça redonda em pixel art (`PixelArt.disc`; como círculo, saía embolotada) centrada em `c` (px da tela),
## presa aos pixels, fora da escala e da perspectiva; depois volta a valer `back` (a transformação de quem chamou).
func _sprite(tex: Texture2D, c: Vector2, mod := Color.WHITE, back := Transform2D.IDENTITY) -> void:
	_ci.draw_set_transform(Vector2.ZERO)
	PixelArt.sprite(_ci, tex, c, mod)
	_ci.draw_set_transform_matrix(back)


## Um círculo de raio `r` em volta de `c` (a borda de uma luz lisa, `_light_fan`).
func _ring(c: Vector2, r: float) -> PackedVector2Array:
	var rim := PackedVector2Array()
	for i in 32:
		rim.append(c + Vector2.from_angle(TAU * i / 32.0) * r)
	return rim


## O `clean_slope` do canto `b` andando só de lado e, se a razão sai só quase exata, também 1 px na altura, se assim ela
## fica exata (a quase exata põe o degrau diferente onde a placa de vídeo quiser, no meio da beira: 2-1-2-2-1). Para
## os cantos de trás dos objetos da mesa: a beira do fundo ganha no máximo um degrau.
static func exact_slope(a: Vector2, b: Vector2, tol := CLEAN_TOL) -> Vector2:
	var near := clean_slope(a, b, Vector2(1, 0), tol)
	for dy in [0.0, -1.0, 1.0]:
		var e := clean_slope(a, b.round() + Vector2(0, dy), Vector2(1, 0), tol)
		var d := (e - a.round()).abs()
		var l := int(maxf(d.x, d.y))
		var s := int(minf(d.x, d.y))
		if s > 0 and (2 * l) % s == 0:   # l/s inteiro ou n + ½ (com s par)
			return e
	return near

## O ponto `b` (px da tela) levado à inclinação limpa mais perto da beira que vem de `a`: degraus iguais (1:1, 1:2,
## 1:3...) ou alternados por igual (2-3-2-3), em vez dos desencontrados (10-12-9) de uma razão qualquer. Só se a razão
## muda menos de `tol` (`CLEAN_TOL`); mexe só nos eixos de `free` (para uma quina continuar em pé, por exemplo) e o mínimo
## possível; sem a razão exata nesses eixos, a quase exata (um degrau diferente, na ponta). Devolve os dois no pixel inteiro: `b` limpo (ou só arredondado).
static func clean_slope(a: Vector2, b: Vector2, free := Vector2.ONE, tol := CLEAN_TOL) -> Vector2:
	a = a.round()
	b = b.round()
	var d := b - a
	var flat := absf(d.x) >= absf(d.y)
	var l := absf(d.x if flat else d.y)   # o eixo longo e o curto
	var s := absf(d.y if flat else d.x)
	if s == 0.0:
		return b
	var r := l / s
	var best := b
	var move := INF
	for exact: bool in [true, false]:   # (sem razão exata nos eixos livres, a quase exata: um degrau diferente, na ponta)
		for q: int in [1, 2]:   # a razão p/q: degraus de n, ou de n e n + 1 alternados
			var p := roundi(r * q)
			var c := float(p) / q
			if p < q or absf(c - r) / r > tol:
				continue
			# [longo, curto]: o curto em múltiplos de q (o longo sai inteiro) ou, quase exata, o curto como está (com o longo
			# como está, o curto arredondado voltava a ser o de `b`)
			var tries := [floorf(s / q) * q, ceilf(s / q) * q, floorf(l / p) * q, ceilf(l / p) * q].map(func(n: float) -> Vector2: return Vector2(n * c, n)) \
				if exact else [Vector2(roundf(s * c), s)]
			for t: Vector2 in tries:
				var e := a + (t if flat else Vector2(t.y, t.x)) * d.sign()
				if t.y > 0.0 and (e.x == b.x or free.x != 0.0) and (e.y == b.y or free.y != 0.0) and e.distance_to(b) < move:
					best = e
					move = e.distance_to(b)
		if move < INF:
			break
	return best


## Um ponto da sala na tela (px de 2x2): x e y a partir dos olhos, z a distância (ver `Z0`).
func _proj(x: float, y: float, z: float) -> Vector2:
	return _vp + Vector2(x, y) * (Z0 / z)


## O mesmo, em px da tela (os objetos da mesa, desenhados em 1x1).
func _p3(x: float, y: float, z: float) -> Vector2:
	return _proj(x, y, z) * 2.0


## Uma luz lisa, sem camadas: a cor `col` no ponto `c`, sumindo até a borda `rim` (fechada, vista de `c`), com a cor
## variando ponto a ponto (forte perto de `c` e caindo depressa, como a luz; em camadas, parecia artificial).
func _light_fan(c: Vector2, rim: PackedVector2Array, col: Color) -> void:
	_light_fans([[c, rim, col]])


## Várias luzes de `_light_fan` ([c, rim, col] cada), os triângulos de todas e depois os quadriláteros: o lote só junta
## primitivos com o mesmo número de pontos (uma depois da outra, eram duas chamadas de desenho por luz).
func _light_fans(fans: Array) -> void:
	for fan: Array in fans:
		var c: Vector2 = fan[0]
		var rim: PackedVector2Array = fan[1]
		var col: Color = fan[2]
		var mid := Color(col, col.a * 0.35)
		for i in rim.size():
			_ci.draw_primitive(PackedVector2Array([c, c.lerp(rim[i], 0.5), c.lerp(rim[(i + 1) % rim.size()], 0.5)]), PackedColorArray([col, mid, mid]), PackedVector2Array())
	for fan: Array in fans:
		var c: Vector2 = fan[0]
		var rim: PackedVector2Array = fan[1]
		var col: Color = fan[2]
		var mid := Color(col, col.a * 0.35)
		var out := Color(col, 0.0)
		for i in rim.size():
			var a := rim[i]
			var b := rim[(i + 1) % rim.size()]
			_fill(PackedVector2Array([c.lerp(a, 0.5), a, b, c.lerp(b, 0.5)]), PackedColorArray([mid, out, out, mid]))


## `v` cm da sala nas unidades da parede do fundo (px de 2x2 lá): a altura dos olhos acima do tampo é `SEAT_EYE`.
func _cm(v: float) -> float:
	return v * _yd / SEAT_EYE


## Um ponto do vão da janela (`p`: ao longo da parede, de 0 a `SIDE_W`, e a altura a partir do alto do vão; pode
## passar da borda) na tela (px de 2x2). A distância ao longo da parede é linear em 1/t: a perspectiva certa.
## `out`: para fora da parede (negativo: para dentro da sala), na mesma profundidade.
func _side_pt(p: Vector2, out := 0.0) -> Vector2:
	var t := 1.0 / lerpf(1.0 / SIDE_T, 1.0 / _t2, p.x / SIDE_W)
	return _svp + Vector2(_sx + out, _cm(WIN_TOP) + p.y) * t


## A parede da direita a `z` de fundo, para as contas em 3D (`_p3`, a partir do ponto de fuga da sala): em ângulo
## (`SIDE_VP`), ela vai para fora vindo para a frente.
func _wall_x(z: float) -> float:
	return _sx + SIDE_VP * z / Z0


## Uma face de objeto (sem contorno: um fio preto torto pela perspectiva serrilhava e parecia desenho mal feito; as
## faces se separam pela luz, o tampo mais claro e os lados mais escuros).
func _poly(pts: PackedVector2Array, col: Color) -> void:
	_fill(pts, PackedColorArray([col]))


## Um polígono cheio em `_ci` com a cor de cada ponto (`cols`, ou uma só para tudo), em primitivos: o Godot junta os
## `draw_primitive` seguidos numa chamada de desenho só, e cada `draw_polygon` era uma (a sala passava de 2000 por
## quadro, 6 ms de renderização parada, e cada redesenho criava mil polígonos). O quadrilátero vai inteiro (os da sala
## são convexos); o resto, em triângulos. Sem área (uma face vista de quina), não aparece nada. Com `_snap`, os pontos
## vão para o pixel inteiro.
func _fill(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if _snap:   # (com os pontos fracionários, uma beira reta saía em degraus de tamanhos desencontrados, 1-2-1-3)
		var r := PackedVector2Array()
		for p in pts:
			r.append(p.round())
		pts = r
	if pts.size() <= 4:
		_ci.draw_primitive(pts, cols, PackedVector2Array())
		return
	var tri := Geometry2D.triangulate_polygon(pts)
	for i in range(0, tri.size(), 3):
		var c := cols if cols.size() == 1 else PackedColorArray([cols[tri[i]], cols[tri[i + 1]], cols[tri[i + 2]]])
		_ci.draw_primitive(PackedVector2Array([pts[tri[i]], pts[tri[i + 1]], pts[tri[i + 2]]]), c, PackedVector2Array())


## Um item qualquer de `a`, no sorteio do cenário (`_rng`).
func _pick(a: Array) -> Variant:
	return a[_rng.randi() % a.size()]
