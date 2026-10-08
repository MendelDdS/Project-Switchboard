extends Control
## A base do cenário (`Background`): o estado em comum, a câmera da sala (`_proj`, `_p3`) e o desenho em pixel
## art (`_fill`, `_poly`, `_p`, `_pixel_line`, `_sprite`, `_light`). O cenário é dividido em camadas por herança:
## esta, a vista da janela (`background_view.gd`), os objetos da mesa (`background_props.gd`) e a sala com o resto
## (`background.gd`); cada uma só usa as de baixo.

const PX := 0.5          ## um pixel da tela nas unidades da câmera (px de 2x2): os detalhes são desenhados em 1x1
## A altura dos olhos acima do fundo do tampo, na tela (px de 2x2): o ponto de fuga, dentro da tela, na altura da
## janela. Era 210 (logo acima da tela): a mesa vista mais de cima, mas a parede da janela ficava a 44 cm da cabeça e a
## janela, bem abaixo dos olhos, descia uns 40°. Mais baixo, o que fica longe do ponto de fuga entorta mais.
const EYE := 120.0
# O operador está sentado à mesa e a câmera são os olhos dele: `SEAT_EYE` cm acima do tampo, com o fundo do tampo a
# `SEAT_BACK` cm (a parte da frente do tampo fica sob o console do painel; a tela mostra a de trás). A tela fixa onde
# ficam o ponto de fuga e o fundo do tampo (`EYE` px abaixo dele); o que resta é a distância focal, que sai da
# conta: a altura dos olhos sobre a distância ao fundo do tampo é a mesma na sala e na tela (`EYE` / `Z0` × `DESK_T`).
# Com uma distância focal menor (era 330), a mesa era vista de cima como por alguém em pé (a ~38° em vez de ~22–29°
# para baixo) e as profundidades saíam exageradas: a prancheta mais larga que funda, o relógio torto.
const SEAT_EYE := 45.0    ## a altura dos olhos acima do tampo (cm), sentado
const SEAT_BACK := 110.0  ## dos olhos ao fundo do tampo (cm), na horizontal
const Z0 := EYE * SEAT_BACK / SEAT_EYE   ## a distância dos olhos à parede do fundo (e a distância focal, em px de 2x2)
## A chuva muda de força durante a noite (`rain_level`: de garoa, `RAIN_LEVEL.x`, a forte, 1), em ondas lentas de
## `RAIN_SPAN` min de jogo (duas, cada noite com as suas fases), em degraus de `RAIN_STEP`: o som (`Sfx.set_rain`), os
## pingos no vidro, o vento no arbusto e os relâmpagos (só com ela acima de `BOLT_RAIN`) seguem. A rua vai ficando mais
## molhada até `SOAK_MIN` min de chuva (as poças crescem).
const RAIN_LEVEL := Vector2(0.15, 1.0)
const RAIN_SPAN := Vector2(95.0, 37.0)
const RAIN_STEP := 0.05
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
const SIDE_T := 1.06        ## onde a janela começa na parede da direita (escala); termina perto da borda da tela
const SIDE_W := 150.0       ## a largura do vão, de frente (só a resolução da projeção)
const WIN_TOP := -28.0      ## o alto do vão (cm a partir dos olhos, para baixo): acima deles

var weather := "rain"
var _moon_x0 := 0.5   # onde a lua nasce: o x da igreja em fração do vidro (a vista atualiza ao desenhar)
var night := 1   ## a noite do jogo (o Main atualiza): a data do calendário do armário e a fase da lua
var minutes := 18 * 60.0:   ## a hora do jogo (minutos do dia; o Main atualiza): o relógio de flip da mesa
	set(v):
		if int(v) != int(minutes):   # a plaqueta vira
			_flip_from = int(minutes)
			_flip_at = Time.get_ticks_msec()
		minutes = v


var _flip_from := -1   # o minuto que a plaqueta mostrava antes de virar
var _flip_at := -100000   # quando ela começou a virar (ms)
var _mist := 0.0
var _vp := Vector2.ZERO   # o ponto de fuga (px de 2x2)
var _yd := 0.0         # a altura do tampo (y da sala, abaixo dos olhos)
var _cx := 0.0         # a quina das paredes (px de 2x2, na tela)
var _t2 := 1.6         # onde a janela termina na parede da direita (escala)
var _ci: CanvasItem    # onde a vista da janela é desenhada: aqui, ou no vidro fora da tela
var _glows: Array = []  # as luzes da sala para o brilho (`_light`): [retângulo, cor, halo, miolo, redonda]
var _rain_phase := Vector2(randf() * TAU, randf() * TAU)   # as fases das ondas da chuva nesta noite
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
	return snappedf(clampf(k, RAIN_LEVEL.x, RAIN_LEVEL.y), RAIN_STEP)


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
	return not (int(Time.get_ticks_msec() / 110.0) % 97 in [40, 42, 43, 71])


## Uma luz do cenário (`r` em px da tela) que brilha, a não ser que o papel de uma ferramenta esteja por cima dela.
func _light(r: Rect2, col: Color, halo: float, round := false, core := true) -> void:
	if _ci == self:   # a vista da janela: as luzes dela vêm de `_draw_side_wall`, que sabe onde o vidro está
		_glows.append([r, col, halo, core, round])   # a camada de cima as acende, cortadas onde o papel está


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x, y, w, h), c)


## Um retângulo em px da tela (1x1) dentro do desenho em escala 2: os detalhes finos, na mesma densidade da interface.
func _p(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x * PX, y * PX, w * PX, h * PX), c)


## Uma linha em pixel art de `a` a `b` (px da tela, fora da escala e da perspectiva; como traço comum, torta,
## serrilhava): um pixel por passo na direção mais longa e, na outra, a espessura em `cols` (de cima para baixo, ou da
## esquerda para a direita). Depois volta a valer `back` (a transformação de quem chamou).
func _pixel_line(a: Vector2, b: Vector2, cols: Array, back := Transform2D.IDENTITY) -> void:
	draw_set_transform(Vector2.ZERO)
	var d := b - a
	var n := maxi(1, roundi(maxf(absf(d.x), absf(d.y))))
	var flat := absf(d.x) >= absf(d.y)
	var o := floori(cols.size() / 2.0)
	for i in n + 1:
		var p := (a + d * i / n).floor()
		for k in cols.size():
			draw_rect(Rect2(p + (Vector2(0, k - o) if flat else Vector2(k - o, 0)), Vector2.ONE), cols[k])
	draw_set_transform_matrix(back)


## Uma peça redonda em pixel art (`PixelArt.disc`; como círculo, saía embolotada) centrada em `c` (px da tela),
## presa aos pixels, fora da escala e da perspectiva; depois volta a valer `back` (a transformação de quem chamou).
func _sprite(tex: Texture2D, c: Vector2, mod := Color.WHITE, back := Transform2D.IDENTITY) -> void:
	draw_set_transform(Vector2.ZERO)
	PixelArt.sprite(self, tex, c, mod)
	draw_set_transform_matrix(back)


## Um círculo de raio `r` em volta de `c` (a borda de uma luz lisa, `_light_fan`).
func _ring(c: Vector2, r: float) -> PackedVector2Array:
	var rim := PackedVector2Array()
	for i in 32:
		rim.append(c + Vector2.from_angle(TAU * i / 32.0) * r)
	return rim


## Um ponto da sala na tela (px de 2x2): x e y a partir dos olhos, z a distância (ver `Z0`).
func _proj(x: float, y: float, z: float) -> Vector2:
	return _vp + Vector2(x, y) * (Z0 / z)


## O mesmo, em px da tela (os objetos da mesa, desenhados em 1x1).
func _p3(x: float, y: float, z: float) -> Vector2:
	return _proj(x, y, z) * 2.0


## O retângulo que contém os pontos `pts`.
func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


## Uma luz lisa, sem camadas: a cor `col` no ponto `c`, sumindo até a borda `rim` (fechada, vista de `c`), com a cor
## variando ponto a ponto (forte perto de `c` e caindo depressa, como a luz; em camadas, parecia artificial).
func _light_fan(c: Vector2, rim: PackedVector2Array, col: Color) -> void:
	var mid := Color(col, col.a * 0.35)
	var out := Color(col, 0.0)
	for i in rim.size():
		var a := rim[i]
		var b := rim[(i + 1) % rim.size()]
		_ci.draw_primitive(PackedVector2Array([c, c.lerp(a, 0.5), c.lerp(b, 0.5)]), PackedColorArray([col, mid, mid]), PackedVector2Array())
		_fill(PackedVector2Array([c.lerp(a, 0.5), a, b, c.lerp(b, 0.5)]), PackedColorArray([mid, out, out, mid]))


## `v` cm da sala nas unidades da parede do fundo (px de 2x2 lá): a altura dos olhos acima do tampo é `SEAT_EYE`.
func _cm(v: float) -> float:
	return v * _yd / SEAT_EYE


## Um ponto do vão da janela (`p`: ao longo da parede, de 0 a `SIDE_W`, e a altura a partir do alto do vão; pode
## passar da borda) na tela (px de 2x2). A distância ao longo da parede é linear em 1/t: a perspectiva certa.
## `out`: para fora da parede (negativo: para dentro da sala), na mesma profundidade.
func _side_pt(p: Vector2, out := 0.0) -> Vector2:
	var t := 1.0 / lerpf(1.0 / SIDE_T, 1.0 / _t2, p.x / SIDE_W)
	return _vp + Vector2(_cx - _vp.x + out, _cm(WIN_TOP) + p.y) * t


## Uma face de objeto (sem contorno: um fio preto torto pela perspectiva serrilhava e parecia desenho mal feito; as
## faces se separam pela luz, o tampo mais claro e os lados mais escuros).
func _poly(pts: PackedVector2Array, col: Color) -> void:
	_fill(pts, PackedColorArray([col]))


## Um polígono cheio em `_ci` com a cor de cada ponto (`cols`, ou uma só para tudo), em primitivos: o Godot junta os
## `draw_primitive` seguidos numa chamada de desenho só, e cada `draw_polygon` era uma (a sala passava de 2000 por
## quadro, 6 ms de renderização parada, e cada redesenho criava mil polígonos). O quadrilátero vai inteiro (os da sala
## são convexos); o resto, em triângulos. Sem área (uma face vista de quina), não aparece nada.
func _fill(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if pts.size() <= 4:
		_ci.draw_primitive(pts, cols, PackedVector2Array())
		return
	var tri := Geometry2D.triangulate_polygon(pts)
	for i in range(0, tri.size(), 3):
		var c := cols if cols.size() == 1 else PackedColorArray([cols[tri[i]], cols[tri[i + 1]], cols[tri[i + 2]]])
		_ci.draw_primitive(PackedVector2Array([pts[tri[i]], pts[tri[i + 1]], pts[tri[i + 2]]]), c, PackedVector2Array())
