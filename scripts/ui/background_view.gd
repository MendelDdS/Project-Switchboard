extends "res://scripts/ui/background_base.gd"
## A vista da janela do cenário (`Background`): a rua lá fora numa cena 3D simples (`OUT_*`, `_o`), com a cidade,
## o clima, quem passa, os carros, o homem do mistério e o arbusto. Desenhada de frente no vidro (`_vport`).

const LIT := [Color("d59a3d"), Color("b38a3c"), Color("e2b25a")]   ## janelas acesas da cidade
const SLEEP := Vector3(19 * 60, 23 * 60 + 50, 0.15)   ## as janelas apagam entre x e y (minutos do dia); z: as que ficam acesas
const CHURCH_DARK := 22 * 60   ## a porta da igreja apaga
const SKY := {"rain": Color("0b141c"), "fog": Color("1b252b"), "clear": Color("0a1422")}
const RAIN_STREAK := Vector2(6.0, 14.0) ## o comprimento do risco (px da tela), do mais longe ao mais perto: o rastro do quadro
const RAIN_SLANT := 0.18 ## o vento: quanto o pingo anda para a esquerda a cada px que cai
const WALK_SEC := 18.0    ## quanto leva atravessando a vista (~1,8 m/s, de 16 m a 16 m; cada um ±20%)
const WALK_STEPS := 2.2   ## passos por segundo (as pernas alternam nesse ritmo)
## A vista é uma cena 3D simples projetada para o vidro (pensada antes, não elemento por elemento): uma câmera dentro
## do prédio, na altura de quem está na janela (`OUT_EYE` m acima da rua: o horizonte passa ali), olhando para fora,
## de frente para uma rua que passa ao lado do prédio e continua para os dois lados. Um ponto de fuga só, no meio do
## horizonte, que é o da sala (a altura dos olhos, `_vp`: uma câmera só para o cenário inteiro): para ele fogem só as linhas que vão para longe (a rua do cruzamento,
## as laterais dos prédios); a rua, os meios-fios e as fachadas de frente ficam na horizontal, e as paredes na
## vertical. Não é a perspectiva da janela (a diagonal dela é só do primeiro plano). Tudo em metros (`_o`: `x` ao longo
## da rua, `z` a distância dos olhos, `h` a altura), no tamanho de verdade.
const OUT_EYE := 4.5      ## os olhos acima da rua (m)
const OUT_F := 60.0       ## a distância focal (px de 2x2 de um metro a um metro)
## A rua, de perto para longe (z, m): a nossa fachada, a nossa calçada até o meio-fio, as duas mãos (a faixa no meio),
## o meio-fio de lá, a calçada de lá e as fachadas do outro lado, apoiadas nela.
const STREET := {"curb": 3.2, "lane": 7.2, "far_curb": 11.2, "far": 14.0}
const CROSSING := Vector2(-6.0, 2.0)   ## a rua do cruzamento, indo embora entre os prédios de lá (x, m)
const FAR_LAMPS := [2.6, -17.0, 19.0]  ## os postes da calçada de lá (x, m): o primeiro na esquina do prédio de tijolos, com o homem
const MAN_X := 3.4        ## onde o homem fica, embaixo do poste da esquina
const MAN_FROM := 16.0    ## de onde ele vem pela calçada (x, m; fora da vista) e para onde volta
const MAN_WALK := 6.0     ## quanto ele leva andando de lá até o poste (min de jogo: ~8 s, ~1,6 m/s)
const MAN_STRIDE := 0.75  ## o passo dele (m)
const HOTEL_X := -9.5     ## o letreiro do hotel, no prédio do outro lado da esquina
## O prédio de tijolos da esquina é de apartamentos: no 3º andar (de `floor` m), uma varanda de `x0` a `x1` (m ao longo
## da rua), saindo `deep` m da fachada, com a porta (`door`, de x a y) e a janela da sala (`win`), onde a TV fica ligada.
const APT := {"x0": 2.7, "x1": 7.6, "floor": 6.5, "deep": 1.0, "door": Vector2(3.2, 4.3), "win": Vector2(5.3, 6.9)}
const APT_DARK := 21 * 60 + 40   ## a luz da sala do apartamento apaga: dali em diante, só a TV
const TV_OFF := 23 * 60 + 35     ## e a TV também (alguém dormiu na frente dela)
const TV_BLUE := Color(0.42, 0.58, 0.95)   ## a luz da TV no vidro
## Janelas que acendem de madrugada (alguém levantou): `WAKE.x` delas, das janelas que já apagaram, acendem de novo
## uma vez entre `WAKE_FROM` e a meia-noite, por `WAKE_FOR` min (sorteado, sempre o mesmo).
const WAKE := 0.14
const WAKE_FROM := 21 * 60 + 30
const WAKE_FOR := Vector2(4, 14)
## As duas mãos da rua: [o meio do carro (z, m), o sentido (-1: para a esquerda)]. Pela mão de lá, da direita para a
## esquerda; pela de cá, entre o nosso meio-fio e a faixa do meio, voltando, da esquerda para a direita.
const CAR_LANES := [Vector2(9.2, -1.0), Vector2(6.4, 1.0)]
## O arbusto plantado junto da nossa parede, embaixo da janela: é do primeiro plano, como a janela, e fica no plano da
## parede dela (não na vista). O meio e a meia largura (fração da largura do vão) e quanto a copa sobe acima do
## peitoril (fração da altura).
const SHRUB := Vector3(0.62, 0.15, 0.11)
## As rajadas de vento no arbusto: as duas ondas lentas que as fazem (rad/s) e quanto elas empurram a copa para a
## esquerda (px da tela no alto dela).
const GUST := Vector3(0.23, 0.071, 2.5)
const MOON_BIG := 1.6     ## a lua no horizonte, maior (a ilusão da lua no horizonte); volta a 1 ao subir
const MOON_SHRINK := 0.4  ## até onde da subida (`_moon_t`) ela ainda está encolhendo
const MOON_LOW := Color("e0a868")   ## o tom dela perto do horizonte (o ar mais grosso avermelha)
## Na névoa, a lua espalhada: o raio do clarão em volta (vezes o halo de sempre), a força dele, a do miolo e a do
## disco (quase apagado).
const FOG_MOON := Vector4(6.0, 0.3, 0.55, 0.3)
const OVERCAST := 14      ## as nuvens do céu da chuva (`_draw_overcast`)
const OVERCAST_SPEED := 0.012
const OVERCAST_LIT := Color("3e3733")    ## a nuvem clareada por baixo pelas luzes da cidade (perto do horizonte)
const OVERCAST_DARK := Color("0d1216")   ## os vãos mais escuros entre elas
const OVERCAST_DECK := Color("1b1e23")   ## o fundo de nuvem no alto (no horizonte, `OVERCAST_LIT`)
const CHURCH_K := 0.45    ## a escala da igreja (desenhada em px de 2x2), no fim da rua do cruzamento
const SIGN_RED := Color("ff4a3a")    ## o neon dele aceso (apagado, quase preto)
const FOG := Color(0.55, 0.62, 0.66)   ## a cor da névoa (`_draw_fog`)
const FOG_VEIL := 0.2    ## o véu dela por cima de tudo lá fora (o longe some nele)
const FOG_GROUND := 0.2  ## o tanto a mais rente ao chão, sumindo até 3 m de altura
const FOG_WISPS := 9     ## os fiapos passando pela rua
## O peitoril (cm abaixo dos olhos): uns 24 cm acima do tampo, como numa sala de verdade (desce pouco: a parede fica a
## uns 70 cm da cabeça). Com os olhos acima da tela e o peitoril 38 cm abaixo deles, a janela descia uns 40° e parecia
## vista de cima.
const WIN_SILL := 21.0
const WALL_D := 16.0        ## a espessura da parede (para fora, nas unidades da parede do fundo): o vidro fica do lado de fora

var flick := false
var lamp_level := 1.0
var warm := 1.0   ## o quanto a luminária já esquentou (0..1, `warm_up`): o Main tinge o brilho dela de laranja até chegar a 1
var stranger := Vector2(INF, INF)   ## quando o homem do mistério para embaixo do poste e quando vai embora (min do dia; o Main atualiza)
var _drops: Array = []   # pingos caindo: Vector3(x, y em frações da vista, perto: 0 = longe, 1 = perto)
var _beads: Array = []   # gotas paradas no vidro: Vector4(x, y em frações do vidro à vista, tamanho, velocidade; 0 = parada)
var _moon_tex := {}   # a lua na fase da noite (`_moon_art`), por tamanho, guardada pela idade (`_moon_for`)
var _moon_for := -1.0
var _fog_moon := Vector4.ZERO   # na névoa, onde está a lua (x, y), o diâmetro e o quanto ela brilha: o clarão vai por cima do véu
var _glass_from := 0.6   # de que fração da altura da vista o vidro aparece (acima: fora da tela ou atrás da persiana)
var _stars: Array[Vector2] = []
var _houses: Array = []        # os prédios do outro lado da rua, de frente: {x0, x1, h, col, brick, wins: [Vector3(x, andar, hora de apagar)]} (m)
var _canyon: Array = []        # as paredes da rua do cruzamento: {x, z0, z1, h, col, wins: [Vector3(z, altura, hora de apagar)]} (m)
var _city: Array = []          # a cidade no fundo: {x, w, h, row, lit: [Vector3...]} (px do vidro; z: o minuto em que a janela apaga)
var _city_for := Vector2.ZERO  # tamanho do vidro para o qual `_city` foi montada
var _view_at := Vector2.ZERO   # onde a vista começa na tela (px de 2x2): o arbusto é posto pela parede da sala
var _near := 0.0         # a vista passa do peitoril de longe para baixo (px de 2x2): a parte de perto da janela, mais alta na tela, mostra a calçada embaixo dela
var _cars: Array[Dictionary] = []   # os carros passando lá fora: {"t": de 0 a 1, "lane": em `CAR_LANES`}
var _walkers: Array = []   # quem está passando na calçada de lá (`_walker`), na ordem do desenho: os de mais longe primeiro


## A vista: céu do clima, morros ao fundo, casas e a igreja com o relógio aceso, a rua com o poste (a silhueta do
## mistério fica contra a luz dele) e, na chuva, o chão molhado refletindo as luzes.
func _draw_city(g: Rect2) -> void:
	var wx := g.position.x
	var wy := g.position.y
	var ww := g.size.x
	var wh := g.size.y
	var fog := weather == "fog"
	var hzy := _hz(g)
	var sky: Color = (SKY.get(weather, SKY["rain"]) as Color).lerp(Color("a2acbc"), _flash())   # o relâmpago clareia o céu
	_r(wx, wy, ww, wh, sky)
	var hz := sky.lightened(0.12)   # o céu clareia perto do horizonte, liso (em faixas, pareciam camadas)
	_fill(PackedVector2Array([Vector2(wx, hzy - 50), Vector2(wx + ww, hzy - 50), Vector2(wx + ww, hzy), Vector2(wx, hzy)]),
		PackedColorArray([sky, sky, hz, hz]))
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			_r(wx + floorf(s.x * ww), wy + floorf(s.y * (hzy - wy)), PX, PX, Color("c9d2dc") if sin(tw + i * 1.7) > -0.6 else Color("56606c"))
		_draw_moon(g, sky, hzy)
	elif weather == "fog":
		_draw_moon(g, sky, hzy)   # difusa: a névoa espalha a luz dela
	elif weather == "rain":
		_draw_overcast(g, sky, hzy)
	if hzy - wy < 40.0:   # (a tela ainda não se arrumou: o vidro ainda não tem o tamanho dele)
		return
	if _city_for != g.size:
		_build_city(g.size)
	var house := Color("141c22") if fog else Color("070b10")
	# bem longe: a cidade no fim da rua do cruzamento (os prédios de lá escondem o resto), em duas fileiras na névoa
	var flicked := 0
	for r in [0, 1]:
		var z: float = [400.0, 250.0][r]
		var haze: float = [0.55, 0.35][r] * (1.4 if fog else 1.0)
		var base := _o(g, 0.0, z).y
		var col := house.lerp(hz, haze)
		for b in _city:
			if b["row"] != r:
				continue
			_r(wx + b["x"], base - b["h"], b["w"], b["h"], col)
			for p in b["lit"]:
				if minutes >= p.z:
					continue
				flicked += 1
				if flick and flicked % 3 == 0:
					continue
				_r(wx + b["x"] + p.x, base - b["h"] + p.y, PX, PX, (LIT[int(p.x + p.y) % LIT.size()] as Color).lerp(hz, haze * 0.7))
	_draw_church(_church_pos(g), house.lerp(hz, 0.25))
	# o chão (a rua do cruzamento indo embora, a rua passando na frente, as calçadas e os meios-fios), as luzes nele
	_draw_street(g, hz)
	if weather == "rain":
		_draw_wet(g)
	# o outro lado: as paredes da rua do cruzamento (de longe para perto) e as fachadas de frente, apoiadas na calçada
	for i in range(_canyon.size() - 1, -1, -1):
		_draw_canyon_wall(g, _canyon[i], hz)
	# a névoa da noite na rua do cruzamento, clareando lisa para o fundo (a igreja aparece nela)
	var ff: float = STREET["far"]
	var mouth := PackedVector2Array([_o(g, CROSSING.x, ff), _o(g, CROSSING.y, ff), _o(g, CROSSING.y, ff, 16.0), _o(g, CROSSING.x, ff, 16.0)])
	_light_fan(Vector2(_o(g, (CROSSING.x + CROSSING.y) / 2.0, 200.0).x, _hz(g)), mouth, Color(hz.lightened(0.15), 0.5 if fog else 0.3))
	for b in _houses:
		_draw_far_house(g, b, hz)
	_draw_shopfront(g)
	_draw_marquee(g)
	if lamp_level > 0.5:   # a luz dos postes lavando as fachadas atrás deles, lisa
		for x: float in FAR_LAMPS:
			var c := _o(g, x, ff, 4.2)
			var rim := PackedVector2Array()
			for i in 20:
				var an := TAU * i / 20.0
				rim.append(_o(g, x + cos(an) * 3.2, ff, 4.2 + sin(an) * 3.4))
			_light_fan(c, rim, Color(1.0, 0.8, 0.5, 0.1))


## A lua da noite limpa subindo (`_moon_at`, `MOON_RISE`): nasce atrás da igreja, grande e alaranjada no horizonte
## (a ilusão da lua no horizonte, `MOON_BIG`, e o ar mais grosso avermelhando), e diminui até o tamanho dela ao subir,
## até sumir atrás da persiana. Com o halo e as nuvens passando devagar (`_clouds`): manchas lisas, um pouco mais
## claras que o céu (a cidade as ilumina por baixo), mais claras na beira quando estão na frente da lua; coberta, a lua
## e o halo escurecem (`_moon_light`). Desenhada antes da cidade, que a cobre no horizonte.
func _draw_moon(g: Rect2, sky: Color, hzy: float) -> void:
	var top := g.position.y + (g.size.y + _near) * _glass_from
	var sh := hzy - top
	var light := _moon_light()
	_moon_x0 = (_church_pos(g).x - g.position.x) / g.size.x
	var pos := _moon_at()
	var moon := Vector2(g.position.x + g.size.x * pos.x, lerpf(top, hzy, pos.y))   # (sem prender à grade de 2x2: ela anda 1 px por vez)
	var low := 1.0 - smoothstep(0.0, MOON_SHRINK, _moon_t())   # 1 no horizonte, 0 já no alto
	var d := int(roundf(14.0 * lerpf(1.0, MOON_BIG, low)))   # o diâmetro (px da tela), encolhendo 1 px por vez
	var fog := weather == "fog"
	_fog_moon = Vector4.ZERO
	var shine := 0.3 + 0.7 * _moon_lit()
	var tone := Color(0.75, 0.78, 0.7).lerp(MOON_LOW, low)
	if moon.y * 2.0 + d / 2.0 > top * 2.0:   # (acima disso, já atrás da persiana)
		if fog:   # o clarão espalhado na névoa vai por cima do véu dela (`_draw_fog`, `_fog_moon`)
			_fog_moon = Vector4(moon.x, moon.y, d, shine)
		else:
			_light_fan(moon, _ring(moon, 16.0 * d / 14.0), Color(tone, 0.16 * light * shine))
		_ci.draw_set_transform(Vector2.ZERO)   # a lua em pixel art, em px da tela, na fase da noite (`_moon_art`)
		var col := Color("d8d0a8").lerp(MOON_LOW, low).lerp(sky, (1.0 - light) * 0.6)
		PixelArt.sprite(_ci, _moon_art(_moon_age(), d), (moon * 2.0).round(), Color(col.lerp(tone, 0.4), FOG_MOON.w) if fog else col)
		_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	if fog:
		return
	for c in _clouds:
		var at := Vector2(g.position.x + _cloud_x(c) * g.size.x, top + c.y * sh)
		var r := Vector2(0.16 * c.z * g.size.x, 0.09 * c.z * sh)
		var lit := 1.0 - smoothstep(0.0, 1.6, ((at - moon) / r).length())   # na frente da lua, a beira pega a luz dela
		var col := sky.lightened(0.1).lerp(Color("8a8f8a"), 0.12 * lit * light)
		for k in 3:   # três manchas juntas, a do meio maior
			var o := at + Vector2((k - 1) * r.x * 0.55, (k % 2) * -r.y * 0.25)
			var rim := PackedVector2Array()
			for i in 12:
				rim.append(o + Vector2(cos(TAU * i / 12.0) * r.x * (0.9 if k == 1 else 0.6), sin(TAU * i / 12.0) * r.y * (1.0 if k == 1 else 0.7)))
			_light_fan(o, rim, Color(col, 0.85))


## O céu da chuva, nublado: nuvens grandes e lisas cobrindo tudo, passando com o vento (`OVERCAST_SPEED`), clareadas
## por baixo pela luz da cidade (mais perto do horizonte, `OVERCAST_LIT`), com vãos mais escuros entre elas
## (`OVERCAST_DARK`), e acesas pelo relâmpago (`_flash`). Sorteadas pelo índice, sempre as mesmas.
func _draw_overcast(g: Rect2, sky: Color, hzy: float) -> void:
	var top := g.position.y + (g.size.y + _near) * _glass_from
	var sh := hzy - top
	var flash := _flash()
	var deck := OVERCAST_DECK.lerp(Color("a2acbc"), flash * 0.6)   # o fundo: o céu inteiro coberto, clareando para o horizonte
	var deck_low := OVERCAST_LIT.lerp(Color("a2acbc"), flash * 0.6)
	_fill(PackedVector2Array([Vector2(g.position.x, g.position.y), Vector2(g.end.x, g.position.y), Vector2(g.end.x, hzy), Vector2(g.position.x, hzy)]),
		PackedColorArray([deck, deck, deck_low, deck_low]))
	for k in OVERCAST:
		var y := fmod(k * 0.618, 1.0) * 1.1 - 0.1   # (fração do céu à vista; as de cima passam da persiana)
		var at := Vector2(g.position.x + _overcast_x(k) * g.size.x, top + y * sh)
		var r := Vector2((0.22 + fmod(k * 0.37, 1.0) * 0.2) * g.size.x, (0.12 + fmod(k * 0.71, 1.0) * 0.1) * sh)
		var col := OVERCAST_DARK if k % 3 == 0 else OVERCAST_DECK.lerp(OVERCAST_LIT, clampf(y, 0.0, 1.0)).lightened(0.12)
		col = col.lerp(Color("a2acbc"), flash * (0.0 if k % 3 == 0 else 0.7))
		var rim := PackedVector2Array()
		for i in 16:
			rim.append(at + Vector2(cos(TAU * i / 16.0) * r.x, sin(TAU * i / 16.0) * r.y))
		_light_fan(at, rim, Color(col, 0.8))


## Onde está a nuvem `k` do céu nublado (fração do vidro), andando com o vento.
func _overcast_x(k: int) -> float:
	return fposmod(fmod(k * 0.53, 1.0) * 1.6 - _mist / 3.6 * OVERCAST_SPEED, 1.6) - 0.3


## A lua na fase dela (`age`: dias desde a lua nova) e no diâmetro `size`, pixel a pixel e guardada: a parte acesa
## vai até o terminador (a meia elipse que separa a luz da sombra), a beira um pouco mais escura e o lado apagado bem
## fraco (a luz da Terra).
## No hemisfério sul a crescente tem a luz à esquerda e a minguante à direita (o contrário do norte).
func _moon_art(age: float, size: int) -> Texture2D:
	var key := snappedf(age, 0.25)
	if key != _moon_for:   # outra noite: os tamanhos guardados eram de outra fase
		_moon_for = key
		_moon_tex.clear()
	if _moon_tex.has(size):
		return _moon_tex[size]
	var c := cos(TAU * key / SYNODIC)
	var waxing := key < SYNODIC / 2.0
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / (size / 2.0) - Vector2.ONE
			if p.length() > 1.0:
				continue
			var s := sqrt(1.0 - p.y * p.y)
			var u := -p.x   # (espelhado: hemisfério sul)
			var on := u > s * c if waxing else u < -s * c
			img.set_pixel(x, y, Color.WHITE.darkened(0.22 * p.length_squared()) if on else Color(1, 1, 1, 0.07))
	_moon_tex[size] = ImageTexture.create_from_image(img)
	return _moon_tex[size]


## A frente da vista, por cima da de trás (`_draw_city`) e redesenhada a cada quadro dela: o letreiro (o T falha
## sozinho), quem passa, os postes, o homem, o carro (na chuva, com o farol espelhado na rua) e a névoa.
func _draw_city_front(g: Rect2) -> void:
	if _hz(g) - g.position.y < 40.0:   # (a tela ainda não se arrumou: o vidro ainda não tem o tamanho dele)
		return
	_draw_hotel_sign(_hotel_pos(g))
	_draw_balcony_front(g)
	for w: Dictionary in _walkers:   # passam atrás dos postes e do homem
		_draw_walker(g, w)
	for x: float in FAR_LAMPS:
		_draw_lamp_post(g, x, STREET["far_curb"] + 0.4)
	var mx := _man_x()
	if not is_nan(mx):
		_draw_stranger(g, mx)
	_cars.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["lane"] < b["lane"])   # o de lá primeiro
	for c in _cars:
		if weather == "rain":
			_draw_wet(g, c)
		_draw_car(g, c)
	if weather == "fog":
		_draw_fog(g)


## A névoa, por cima da rua e do outro lado (o arbusto, perto, fica fora dela): um véu liso, mais grosso rente ao chão
## (`FOG_VEIL`, `FOG_GROUND`), fiapos largos e lisos atravessando a rua devagar (`FOG_WISPS`, com o vento, `_mist`) e as
## luzes espalhando nela: um halo e um cone embaixo de cada poste e o vermelho do neon em volta do letreiro.
func _draw_fog(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var base := _o(g, 0.0, ff).y   # o pé das fachadas de lá
	var high := _o(g, 0.0, ff, 3.0).y
	var x0 := g.position.x
	var x1 := g.end.x
	var y1 := g.end.y + _near   # até o pé do vidro: a rua de perto também
	_r(x0, g.position.y, g.size.x, y1 - g.position.y, Color(FOG, FOG_VEIL))
	_fill(PackedVector2Array([Vector2(x0, high), Vector2(x1, high), Vector2(x1, base), Vector2(x0, base)]),
		PackedColorArray([Color(FOG, 0.0), Color(FOG, 0.0), Color(FOG, FOG_GROUND), Color(FOG, FOG_GROUND)]))
	_fill(PackedVector2Array([Vector2(x0, base), Vector2(x1, base), Vector2(x1, y1), Vector2(x0, y1)]),
		PackedColorArray([Color(FOG, FOG_GROUND), Color(FOG, FOG_GROUND), Color(FOG, FOG_GROUND * 0.4), Color(FOG, FOG_GROUND * 0.4)]))
	if _fog_moon.z > 0.0:   # a lua na névoa: a luz dela espalhada num clarão largo e liso, mais forte no meio
		var m := Vector2(_fog_moon.x, _fog_moon.y)
		var tone := Color(0.8, 0.82, 0.76)
		_light_fan(m, _ring(m, 16.0 * _fog_moon.z / 14.0 * FOG_MOON.x), Color(tone, FOG_MOON.y * _fog_moon.w))
		_light_fan(m, _ring(m, 9.0 * _fog_moon.z / 14.0), Color(tone.lightened(0.4), FOG_MOON.z * _fog_moon.w))
	for k in FOG_WISPS:   # cada um na sua distância, altura, tamanho e velocidade, sempre os mesmos
		var z := lerpf(STREET["curb"] + 1.0, ff, fmod(k * 0.37, 1.0))
		var c := _o(g, fposmod(k * 13.7 + _mist * (0.08 + (k % 3) * 0.03), 70.0) - 35.0, z, 0.3 + fmod(k * 0.53, 1.0) * 1.6)
		var rx := OUT_F * (5.0 + (k % 4) * 1.5) / z
		var ry := OUT_F * (0.5 + (k % 3) * 0.25) / z
		var rim := PackedVector2Array()
		for i in 16:
			rim.append(c + Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * ry))
		_light_fan(c, rim, Color(FOG, 0.14))
	if lamp_level > 0.5:
		var heads := _lamp_heads(g)
		var lit := Color(1.0, 0.85, 0.55, 0.14)
		for i in FAR_LAMPS.size():
			var x: float = FAR_LAMPS[i]
			var z: float = STREET["far_curb"] - 0.2
			var h: Vector2 = heads[i]
			var foot := _o(g, x, z)
			var w := Vector2(1, 0)
			# o cone: claro no meio, sumindo para os lados (com a borda reta, parecia um triângulo recortado)
			_fill(PackedVector2Array([h - w, h, foot, _o(g, x - 3.5, z)]), PackedColorArray([Color(lit, 0.0), lit, Color(lit, lit.a * 0.4), Color(lit, 0.0)]))
			_fill(PackedVector2Array([h, h + w, _o(g, x + 3.5, z), foot]), PackedColorArray([lit, Color(lit, 0.0), Color(lit, 0.0), Color(lit, lit.a * 0.4)]))
			var halo := PackedVector2Array()
			for k in 20:
				halo.append(h + Vector2(cos(TAU * k / 20.0), sin(TAU * k / 20.0)) * OUT_F * 2.2 / z)
			_light_fan(h, halo, Color(lit, 0.22))
	if _sign_on():
		var sc := _hotel_pos(g) + Vector2(2, 8)
		var glow := PackedVector2Array()
		for k in 20:
			glow.append(sc + Vector2(cos(TAU * k / 20.0) * 12.0, sin(TAU * k / 20.0) * 24.0))
		_light_fan(sc, glow, Color(SIGN_RED, 0.12))


## O horizonte da vista `g` (a altura dos olhos).
func _hz(g: Rect2) -> float:
	return g.position.y + _vp.y - _view_at.y


## Um ponto lá fora na vista `g`: `x` m ao longo da rua (a partir da frente da janela), a `z` m dos olhos e `h` m acima
## da rua. A câmera olha de frente para a rua: a linha que vai para longe foge para o meio do horizonte.
func _o(g: Rect2, x: float, z: float, h := 0.0) -> Vector2:
	z = maxf(0.3, z)
	return Vector2(g.position.x + g.size.x * 0.5 + OUT_F * x / z, _hz(g) + OUT_F * (OUT_EYE - h) / z)


## Um retângulo no chão (ou na altura `h`) de `x0` a `x1` ao longo da rua e de `z0` a `z1` de distância.
func _patch(g: Rect2, x0: float, x1: float, z0: float, z1: float, h := 0.0) -> PackedVector2Array:
	return PackedVector2Array([_o(g, x0, z0, h), _o(g, x1, z0, h), _o(g, x1, z1, h), _o(g, x0, z1, h)])


## O pé da igreja, no fim da rua do cruzamento.
func _church_pos(g: Rect2) -> Vector2:
	return _o(g, (CROSSING.x + CROSSING.y) / 2.0, 120.0)


## O alto do letreiro do hotel, preso na fachada do outro lado.
func _hotel_pos(g: Rect2) -> Vector2:
	return _o(g, HOTEL_X, STREET["far"] - 0.6, 10.0)


## As cabeças dos postes da calçada de lá (para o brilho delas no vidro).
func _lamp_heads(g: Rect2) -> Array:
	var out := []
	for x: float in FAR_LAMPS:
		out.append(_o(g, x, STREET["far_curb"] - 0.6, 5.0))
	return out


## A cabeça do poste da esquina, o mais perto (as gotas no vidro esquentam perto dele).
func _post(g: Rect2) -> Vector2:
	return _lamp_heads(g)[0]


## Onde está a frente do carro `c` (x, m): entra por um lado da vista e sai pelo outro, no sentido da mão dele.
func _car_x(c: Dictionary) -> float:
	var d: float = CAR_LANES[c["lane"]].y
	return lerpf(16.0, -21.0, c["t"]) * -d


## O chão: a rua do cruzamento indo embora (com as calçadas e os postes dela, menores com a distância), a nossa calçada
## de lajotas até o meio-fio, o asfalto da rua (manchas, desgaste dos pneus nas duas mãos, grão perto, poças espelhando o
## céu, a faixa tracejada no meio e a faixa de pedestres na boca do cruzamento), o meio-fio de lá com a face virada para
## nós, a calçada de lá e a luz dos postes no chão. Tudo no mesmo plano horizontal; só a perspectiva inclina as linhas
## que vão para longe.
func _draw_street(g: Rect2, hz: Color) -> void:
	var fog := weather == "fog"
	var asphalt := Color("090c10") if not fog else Color("141a1f")
	var walk := Color("1b2227") if not fog else Color("232b31")
	var cu: float = STREET["curb"]
	var fc: float = STREET["far_curb"]
	var ff: float = STREET["far"]
	var cx0 := CROSSING.x
	var cx1 := CROSSING.y
	var wide := 80.0
	_poly(PackedVector2Array([Vector2(g.position.x, _hz(g)), Vector2(g.end.x, _hz(g)), Vector2(g.end.x, g.end.y + _near),
		Vector2(g.position.x, g.end.y + _near)]), asphalt)
	# a rua do cruzamento, indo embora até a praça da igreja, com as calçadas dela
	var far := asphalt.lerp(hz, 0.35)
	_fill(_patch(g, cx0 + 1.8, cx1 - 1.8, fc, 130.0), PackedColorArray([asphalt, asphalt, far, far]))
	for side: Vector2 in [Vector2(cx0, cx0 + 1.8), Vector2(cx1 - 1.8, cx1)]:
		_fill(_patch(g, side.x, side.y, ff, 130.0), PackedColorArray([walk, walk, walk.lerp(hz, 0.35), walk.lerp(hz, 0.35)]))
		var curb_x := side.y if side.x == cx0 else side.x
		_ci.draw_line(_o(g, curb_x, ff, 0.15), _o(g, curb_x, 130.0, 0.15), Color(hz, 0.6), PX)
	for i in 6:   # os postes dela, menores e mais juntos com a distância
		var z := 24.0 + i * 16.0
		for x in [cx0 + 1.4, cx1 - 1.4]:
			var foot := _o(g, x, z)
			var head := _o(g, x, z, 5.0)
			var near := clampf(24.0 / z, 0.0, 1.0)
			_r(foot.x, head.y, PX, foot.y - head.y, Color("1d262c").lerp(hz, 1.0 - near))
			if lamp_level > 0.5:
				_r(head.x - PX, head.y - PX, maxf(PX, 1.5 * near), maxf(PX, near), Color("ffd88a").lerp(hz, (1.0 - near) * 0.6))
				_r(foot.x - 2.0 * near, foot.y - PX, 4.0 * near + PX, PX, Color(1.0, 0.85, 0.55, 0.2 * near))
	# a calçada de lá, dos dois lados da boca do cruzamento (a nossa não aparece: o que encosta no nosso prédio diria
	# para que lado a nossa parede vai, e a sala já diz outra coisa)
	_poly(_patch(g, -wide, cx0, fc, ff), walk)
	_poly(_patch(g, cx1, wide, fc, ff), walk)
	# o asfalto não é liso: manchas e remendos, o desgaste dos pneus em cada mão, poças e o grão perto
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	for i in 36:
		var x := rng.randf_range(-20.0, 20.0)
		var z := rng.randf_range(cu + 0.3, fc - 0.5)
		var tone := Color(1, 1, 1, rng.randf_range(0.015, 0.035)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(0.1, 0.22))
		_poly(_patch(g, x, x + rng.randf_range(1.0, 5.0), z, z + rng.randf_range(0.3, 1.2)), tone)
	for lane: float in [cu + 1.3, cu + 2.7, fc - 2.7, fc - 1.3]:
		_poly(_patch(g, -wide, wide, lane - 0.3, lane + 0.3), Color(0.6, 0.7, 0.8, 0.035))
	var wet := 1.0 + 1.6 * _soaked() if weather == "rain" else 1.0   # as poças crescem com a noite de chuva
	for i in 12:   # as poças: espelham o céu (na chuva, mais)
		var x := rng.randf_range(-14.0, 14.0)
		var z := rng.randf_range(cu + 0.4, fc - 0.8)
		var puddle := _patch(g, x, x + rng.randf_range(1.0, 2.6), z, z + rng.randf_range(0.4, 0.9))
		_poly(puddle, Color(0.45, 0.55, 0.7, 0.05 * wet))
		_ci.draw_line(puddle[2], puddle[3], Color(0.6, 0.7, 0.85, 0.08 * wet), PX)
	for i in 240:
		var gp := _o(g, rng.randf_range(-8.0, 8.0), rng.randf_range(cu + 0.5, 6.5))
		_r(floorf(gp.x * 2.0) * PX, floorf(gp.y * 2.0) * PX, PX, PX, Color(1, 1, 1, 0.04) if i % 2 else Color(0, 0, 0, 0.2))
	var x0 := -wide   # a faixa tracejada no meio
	while x0 < wide:
		_poly(_patch(g, x0, x0 + 3.0, STREET["lane"] - 0.08, STREET["lane"] + 0.08), Color(0.75, 0.72, 0.6, 0.3))
		x0 += 9.0
	# as juntas das lajotas de lá: ao longo da rua (na horizontal) e para longe (para o ponto de fuga)
	var joint := Color(0, 0, 0, 0.35)
	_ci.draw_line(_o(g, -wide, fc + 1.4), _o(g, cx0, fc + 1.4), joint, PX)
	_ci.draw_line(_o(g, cx1, fc + 1.4), _o(g, wide, fc + 1.4), joint, PX)
	var xj := -30.0
	while xj < 30.0:
		if xj < cx0 or xj > cx1:
			_ci.draw_line(_o(g, xj, fc), _o(g, xj, ff), joint, PX)
		xj += 1.5
	# perto, embaixo da janela, a rua some na sombra do nosso prédio, lisa e sem nenhuma linha
	var dark := Color(0, 0, 0, 0.6)
	_fill(_patch(g, -wide, wide, 0.3, cu + 1.5), PackedColorArray([dark, dark, Color(dark, 0.0), Color(dark, 0.0)]))
	# o meio-fio de lá, com a face virada para nós e a quina
	for seg: Vector2 in [Vector2(-wide, cx0), Vector2(cx1, wide)]:
		_poly(PackedVector2Array([_o(g, seg.x, fc), _o(g, seg.y, fc), _o(g, seg.y, fc, 0.15), _o(g, seg.x, fc, 0.15)]), Color("2a3237"))
		_ci.draw_line(_o(g, seg.x, fc, 0.15), _o(g, seg.y, fc, 0.15), Color("4a555c"), PX)
	if lamp_level > 0.5:   # a luz de cada poste de lá no chão, em volta do pé dele
		for x: float in FAR_LAMPS:
			var c := _o(g, x, fc - 0.2)
			var rim := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				rim.append(_o(g, x + cos(a) * 4.5, fc - 0.2 + sin(a) * 3.0))
			_light_fan(c, rim, Color(1.0, 0.85, 0.55, 0.28))


## A chuva no chão: o asfalto molhado espelha as luzes em riscos verticais, quebrados, embaixo de cada uma (os postes
## e o letreiro; com `car`, só o farol daquele carro, que anda: vai na frente da vista), mais fracos para baixo.
func _draw_wet(g: Rect2, car: Dictionary = {}) -> void:
	var lights := []   # [cabeça, pé, cor]
	if not car.is_empty():
		var z: float = CAR_LANES[car["lane"]].x
		lights.append([_o(g, _car_x(car), z - 0.9, 0.7), _o(g, _car_x(car), z - 1.2), Color("fff1c8")])
	else:
		if lamp_level > 0.5:
			for i in FAR_LAMPS.size():
				lights.append([_lamp_heads(g)[i], _o(g, FAR_LAMPS[i], STREET["far_curb"] - 0.5), Color(1.0, 0.85, 0.55)])
		if _sign_on():
			lights.append([_hotel_pos(g), _o(g, HOTEL_X, STREET["far_curb"] - 0.5), SIGN_RED])
	for l: Array in lights:
		_wet_streak(l[0], l[1], l[2])


## O reflexo da luz `col` (que fica em `head`) no asfalto molhado, um risco vertical quebrado descendo de `foot`.
func _wet_streak(head: Vector2, foot: Vector2, col: Color) -> void:
	var length := (foot.y - head.y) * 0.9
	var n := maxi(3, int(length / 1.5))
	for k in n:
		if k % 3 == 2:
			continue   # quebrado pelas poças e pelos pingos
		_r(foot.x - PX * (k % 2), foot.y + length * k / n, maxf(PX, 1.5 - k * 0.05), PX, Color(col, 0.32 * (1.0 - float(k) / n)))


## Uma parede da rua do cruzamento (`w`: o lado `x`, de `z0` a `z1`, `h` m), indo embora para o ponto de fuga, com
## algumas janelas acesas.
func _draw_canyon_wall(g: Rect2, w: Dictionary, hz: Color) -> void:
	var x: float = w["x"]
	var z0: float = w["z0"]
	var z1: float = w["z1"]
	var ht: float = w["h"]
	var col: Color = (w["col"] as Color).lerp(hz, clampf((z0 - 14.0) / 160.0, 0.0, 0.5))
	_poly(PackedVector2Array([_o(g, x, z0), _o(g, x, z1), _o(g, x, z1, ht), _o(g, x, z0, ht)]), col)
	_ci.draw_line(_o(g, x, z0), _o(g, x, z0, ht), col.darkened(0.4), PX)   # a quina
	for wv: Vector3 in w["wins"]:   # (z, altura, hora de apagar)
		if wv.z > minutes:
			var p := _o(g, x, wv.x, wv.y)
			_r(p.x, p.y, PX, maxf(PX, 1.2 * OUT_F / wv.x), LIT[int(wv.x) % LIT.size()])


## Um prédio do outro lado da rua, de frente (`b`: de `x0` a `x1`, `h` m, andares de 3,2 m), apoiado na calçada de lá:
## a fachada vertical (de tijolos, no da esquina), a cornija, a faixa acima do térreo, a porta e a vitrine no térreo e as
## janelas, acesas até a hora delas ou apagadas com o reflexo da rua.
func _draw_far_house(g: Rect2, b: Dictionary, hz: Color) -> void:
	var ff: float = STREET["far"]
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var ht: float = b["h"]
	var col: Color = b["col"]
	var a := _o(g, x0, ff, ht)
	var e := _o(g, x1, ff)
	var k := OUT_F / ff   # px de 2x2 por metro na fachada
	_r(a.x, a.y, e.x - a.x, e.y - a.y, col)
	if b["brick"]:   # as fiadas de tijolo, de meio em meio metro
		var hb := 0.5
		while hb < ht:
			_r(a.x, _o(g, x0, ff, hb).y, e.x - a.x, PX, col.darkened(0.22))
			hb += 0.5
	_r(a.x - PX, a.y - 1, e.x - a.x + PX * 2.0, 1, col.lightened(0.18))   # a cornija, com a sombra embaixo
	_r(a.x, a.y, e.x - a.x, PX, Color(0, 0, 0, 0.4))
	_r(a.x, _o(g, x0, ff, 3.4).y, e.x - a.x, PX, col.lightened(0.12))   # a faixa acima do térreo
	_r(a.x, a.y, PX, e.y - a.y, col.darkened(0.4))   # a divisa com o vizinho
	_r(a.x, e.y - PX, e.x - a.x, PX, Color(0, 0, 0, 0.45))   # o pé, na calçada
	var wake: Dictionary = b["wake"]
	for j in b["wins"].size():   # (x do meio, andar, hora de apagar; -1: apagada)
		var wv: Vector3 = b["wins"][j]
		var ground := wv.y == 0.0
		var w := (1.8 if ground else 1.2) * k
		var top := _o(g, wv.x, ff, 2.6 if ground else wv.y * 3.2 + 2.5)
		var h := (2.6 if ground else 1.5) * k
		var p := Vector2(top.x - w / 2.0, top.y)
		_r(p.x - PX, p.y - PX, w + PX * 2.0, h + PX, col.darkened(0.55))   # o vão
		var woke: Vector2 = wake.get(j, Vector2.ZERO)
		if wv.z > minutes or (minutes >= woke.x and minutes < woke.y):
			var lc: Color = LIT[int(wv.x + wv.y) % LIT.size()]
			_r(p.x, p.y, w, h, lc)
			_r(p.x, p.y + h * 0.45, w, PX, lc.darkened(0.45))   # a travessa
			_r(p.x, p.y, w * 0.3, h, lc.darkened(0.25))   # a cortina
			_r(p.x, p.y, w, maxf(PX, 0.15 * k), lc.darkened(0.5))   # a sombra da verga: a janela é funda
		else:
			_r(p.x, p.y, w, h, Color("080b0e"))
			_r(p.x, p.y, w, PX, Color(hz, 0.5))   # o reflexo da rua no vidro
		if not ground:
			_r(p.x - PX * 2.0, p.y + h, w + PX * 4.0, PX, col.lightened(0.25))   # o peitoril, saindo da parede, e a sombra dele
			_r(p.x - PX, p.y + h + PX, w + PX * 2.0, PX, col.darkened(0.35))
			_r(p.x - PX * 2.0, p.y - PX * 2.0, w + PX * 4.0, PX, col.darkened(0.3))   # a verga
	if b["brick"]:
		_draw_balcony_back(g, col)


## A vitrine acesa de um bar no térreo do prédio de tijolos, logo atrás do homem (`MAN_X`): ele fica em silhueta contra
## ela. Vidro quente com o caixilho e o letreiro pintado, e a luz dela saindo pela calçada.
func _draw_shopfront(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var x0 := CROSSING.y + 0.5   # (a quina do prédio fica em CROSSING.y: antes, a vitrine passava dela)
	var x1 := CROSSING.y + 2.5   # (com três divisões, encostava na porta)
	var a := _o(g, x0, ff, 2.5)
	var e := _o(g, x1, ff, 0.4)
	_r(a.x - PX, a.y - PX, e.x - a.x + 1, e.y - a.y + 1, Color("1a0f0a"))
	_fill(PackedVector2Array([a, Vector2(e.x, a.y), e, Vector2(a.x, e.y)]),
		PackedColorArray([Color("c98a3e"), Color("c98a3e"), Color("f0c070"), Color("f0c070")]))
	_r(lerpf(a.x, e.x, 0.5), a.y, PX, e.y - a.y, Color("3a2414"))   # o caixilho
	_r(a.x, lerpf(a.y, e.y, 0.3), e.x - a.x, PX, Color("3a2414"))
	_r(lerpf(a.x, e.x, 0.12), lerpf(a.y, e.y, 0.12), (e.x - a.x) * 0.5, PX, Color("7a3a1a"))   # o letreiro pintado no vidro
	var c := _o(g, MAN_X, STREET["far_curb"] + 0.3)   # a luz dela na calçada e no meio-fio
	var rim := PackedVector2Array()
	for i in 20:
		var an := TAU * i / 20.0
		rim.append(_o(g, MAN_X + cos(an) * 2.6, ff - 1.2 + sin(an) * 1.6))
	_light_fan(c, rim, Color(1.0, 0.75, 0.4, 0.2))


## A marquise do hotel sobre a porta (embaixo do letreiro): saindo 1,2 m da fachada, o alto visto de cima (os olhos
## ficam acima), a beira da frente e a luz quente embaixo dela, na porta e na calçada.
func _draw_marquee(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var x0 := HOTEL_X - 1.8
	var x1 := HOTEL_X + 1.8
	var door := _o(g, HOTEL_X - 0.6, ff, 2.3)
	var de := _o(g, HOTEL_X + 0.6, ff)
	_fill(PackedVector2Array([door, Vector2(de.x, door.y), de, Vector2(door.x, de.y)]),
		PackedColorArray([Color("8a5a2a"), Color("8a5a2a"), Color("e0a858"), Color("e0a858")]))   # a porta aberta, com a luz do saguão
	var c := _o(g, HOTEL_X, ff - 0.6)
	var rim := PackedVector2Array()
	for i in 20:
		var an := TAU * i / 20.0
		rim.append(_o(g, HOTEL_X + cos(an) * 2.8, ff - 0.8 + sin(an) * 1.4))
	_light_fan(c, rim, Color(1.0, 0.78, 0.45, 0.22))
	var top := PackedVector2Array([_o(g, x0, ff, 3.0), _o(g, x1, ff, 3.0), _o(g, x1, ff - 1.2, 3.0), _o(g, x0, ff - 1.2, 3.0)])
	_poly(top, Color("2a1c16"))
	_poly(PackedVector2Array([top[3], top[2], _o(g, x1, ff - 1.2, 2.75), _o(g, x0, ff - 1.2, 2.75)]), Color("6a1e18"))   # a beira, vermelha
	_ci.draw_line(_o(g, x0, ff - 1.2, 2.75), _o(g, x1, ff - 1.2, 2.75), Color(1.0, 0.8, 0.5, 0.6), PX)   # a luz embaixo dela


## A parte parada da varanda do apartamento no prédio de tijolos (`APT`), na camada de trás: a porta (acesa, com a
## cortina, até `APT_DARK`), o vão da janela da sala (o vidro com a TV é da frente, `_draw_balcony_front`), os vasos de
## planta nos cantos e o lado de baixo da laje, visto de baixo (os olhos ficam abaixo dela).
func _draw_balcony_back(g: Rect2, col: Color) -> void:
	var ff: float = STREET["far"]
	var fl: float = APT["floor"]
	var dz: float = ff - APT["deep"]
	var d: Vector2 = APT["door"]
	var a := _o(g, d.x, ff, fl + 2.3)
	var e := _o(g, d.y, ff, fl + 0.05)
	_r(a.x - PX, a.y - PX, e.x - a.x + PX * 2.0, e.y - a.y + PX, col.darkened(0.55))
	if minutes < APT_DARK:
		var lc: Color = (LIT[1] as Color).darkened(0.15)
		_r(a.x, a.y, e.x - a.x, e.y - a.y, lc)
		_r(a.x, a.y, (e.x - a.x) * 0.6, e.y - a.y, lc.darkened(0.3))   # a cortina
	else:
		_r(a.x, a.y, e.x - a.x, e.y - a.y, Color("080b0e"))
		_r(a.x, a.y, e.x - a.x, PX, Color(0.5, 0.55, 0.6, 0.3))
	_r((a.x + e.x) / 2.0, a.y, PX, e.y - a.y, col.darkened(0.5))   # as duas folhas
	var w: Vector2 = APT["win"]
	var wa := _o(g, w.x, ff, fl + 2.4)
	var we := _o(g, w.y, ff, fl + 0.9)
	_r(wa.x - PX, wa.y - PX, we.x - wa.x + PX * 2.0, we.y - wa.y + PX, col.darkened(0.55))
	_r(wa.x, wa.y, we.x - wa.x, we.y - wa.y, Color("080b0e"))
	_r(wa.x - PX * 2.0, wa.y - PX * 2.0, we.x - wa.x + PX * 4.0, PX, col.darkened(0.3))   # a verga
	for px: float in [APT["x0"] + 0.35, APT["x1"] - 0.4]:   # os vasos, atrás do gradil
		var foot := _o(g, px, dz + 0.3, fl + 0.15)
		var k := OUT_F / (dz + 0.3)
		_r(foot.x - 0.18 * k, foot.y - 0.35 * k, 0.36 * k, 0.35 * k, Color("4a2a1c"))
		for i in 7:
			var lx := foot.x + (fposmod(i * 0.37, 1.0) - 0.5) * 0.6 * k
			var ly := foot.y - (0.35 + 0.15 + fposmod(i * 0.61, 1.0) * 0.5) * k
			_r(lx - PX, ly, PX * 3.0, PX * 2.0, Color("142219") if i % 2 else Color("1c2e22"))
	var under := PackedVector2Array([_o(g, APT["x0"], ff, fl), _o(g, APT["x1"], ff, fl), _o(g, APT["x1"], dz, fl), _o(g, APT["x0"], dz, fl)])
	_poly(under, col.darkened(0.65))


## A parte da varanda que muda ou fica na frente, na camada da frente: o vidro da janela da sala com a luz da TV
## piscando (as cenas trocando, `TV_BLUE`; com a luz da sala acesa, mistura com ela; até `TV_OFF`), a beira da laje e o
## gradil de ferro na frente de tudo, que a TV tinge quando a sala está escura.
func _draw_balcony_front(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var fl: float = APT["floor"]
	var dz: float = ff - APT["deep"]
	var tv := Color(0, 0, 0, 0)
	if minutes < TV_OFF:
		var t := Time.get_ticks_msec() / 1000.0
		var cut := floorf(t * 0.8 + sin(t * 0.31) * 0.7)   # cada cena, um brilho e um tom
		var lv := 0.45 + 0.45 * fposmod(sin(cut * 12.9898) * 43758.5453, 1.0) + 0.05 * sin(t * 17.0)
		var tint := TV_BLUE.lerp(Color(0.8, 0.88, 1.0), fposmod(sin(cut * 78.233) * 12345.6, 1.0) * 0.5)
		var w: Vector2 = APT["win"]
		var wa := _o(g, w.x, ff, fl + 2.4)
		var we := _o(g, w.y, ff, fl + 0.9)
		var glass: Color
		if minutes < APT_DARK:
			glass = (LIT[0] as Color).darkened(0.1).lerp(tint, 0.3 * lv)
		else:
			glass = Color("0b1018").lerp(tint, 0.2 + 0.55 * lv)
			tv = Color(tint, lv)
			var c := (wa + we) / 2.0
			var rim := PackedVector2Array()
			for i in 16:
				rim.append(c + Vector2(cos(TAU * i / 16.0) * (we.x - wa.x) * 1.4, sin(TAU * i / 16.0) * (we.y - wa.y) * 1.3))
			_light_fan(c, rim, Color(tint, 0.1 * lv))
		_r(wa.x, wa.y, we.x - wa.x, we.y - wa.y, glass)
		_r(we.x - (we.x - wa.x) * 0.25, wa.y, (we.x - wa.x) * 0.25, we.y - wa.y, glass.darkened(0.45))   # a cortina
		_r(wa.x, wa.y, we.x - wa.x, maxf(PX, 0.15 * OUT_F / ff), glass.darkened(0.5))   # a sombra da verga
	var iron := Color("15191c")
	var x0: float = APT["x0"]
	var x1: float = APT["x1"]
	_poly(PackedVector2Array([_o(g, x0, dz, fl), _o(g, x1, dz, fl), _o(g, x1, dz, fl + 0.15), _o(g, x0, dz, fl + 0.15)]), Color("2a1a14"))
	for h: float in [fl + 0.25, fl + 1.05]:   # o gradil: os corrimãos, o da frente e os dos lados até a fachada
		_ci.draw_line(_o(g, x0, dz, h), _o(g, x1, dz, h), iron, PX)
		_ci.draw_line(_o(g, x0, dz, h), _o(g, x0, ff, h), iron, PX)
		_ci.draw_line(_o(g, x1, dz, h), _o(g, x1, ff, h), iron, PX)
	var xb := x0
	while xb <= x1 + 0.01:
		var w: Vector2 = APT["win"]
		var bar := iron.lerp(tv, 0.35 * tv.a) if xb > w.x - 0.6 and xb < w.y + 0.6 else iron
		_r(_o(g, xb, dz).x, _o(g, xb, dz, fl + 1.05).y, PX, _o(g, xb, dz, fl + 0.15).y - _o(g, xb, dz, fl + 1.05).y, bar)
		xb += 0.25


## Um poste da calçada de lá (em `x`, `z`), com 5 m: o tubo, o braço virado para a rua e a cabeça acesa.
func _draw_lamp_post(g: Rect2, x: float, z: float) -> void:
	var foot := _o(g, x, z)
	var top := _o(g, x, z, 5.0)
	var head := _o(g, x, z - 1.0, 5.0)
	var k := (foot.y - top.y) / 5.0
	var pole := Color("1d262c")
	_r(foot.x - maxf(PX, 0.08 * k), top.y, maxf(PX, 0.16 * k), foot.y - top.y, pole)
	_ci.draw_line(top, head, pole, maxf(PX, 0.1 * k))
	_r(head.x - 0.3 * k, head.y, 0.6 * k, maxf(PX, 0.15 * k), pole)
	if lamp_level > 0.5:
		_r(head.x - 0.25 * k, head.y + 0.15 * k, 0.5 * k, maxf(PX, 0.12 * k), Color("ffd88a"))
		_poly(PackedVector2Array([head + Vector2(-0.25 * k, 0.2 * k), head + Vector2(0.25 * k, 0.2 * k),
			Vector2(head.x + 1.6 * k, foot.y), Vector2(head.x - 1.6 * k, foot.y)]), Color(1.0, 0.85, 0.55, 0.05))


## Onde está o homem do mistério na calçada de lá (x, m), ou NAN sem ele: vem andando de `MAN_FROM`, fica parado
## embaixo do poste da esquina (`MAN_X`) de `stranger.x` a `stranger.y` e volta por onde veio (`MAN_WALK` min para cada
## lado). Sai da hora do jogo: pausa e pulo do relógio valem para ele também.
func _man_x() -> float:
	if minutes < stranger.x - MAN_WALK or minutes >= stranger.y + MAN_WALK:
		return NAN
	if minutes < stranger.x:
		return lerpf(MAN_FROM, MAN_X, (minutes - stranger.x + MAN_WALK) / MAN_WALK)
	if minutes < stranger.y:
		return MAN_X
	return lerpf(MAN_X, MAN_FROM, (minutes - stranger.y) / MAN_WALK)


## O homem do mistério na calçada de lá, em `x` (`_man_x`), de chapéu e casaco comprido, com 1,8 m: andando, as pernas
## alternam a cada passo; parado embaixo do poste da esquina, fica contra a luz dele, com a sombra no chão para longe
## dela. Em px da tela; a névoa e a chuva passam por cima.
func _draw_stranger(g: Rect2, x: float) -> void:
	var z: float = STREET["far_curb"] + 1.1
	var walking := x != MAN_X
	var steps := int(absf(x - MAN_FROM) / MAN_STRIDE)
	var foot := (_o(g, x, z) * 2.0).floor() - Vector2(0, steps % 2 if walking else 0)
	var k := OUT_F / z * 2.0   # px da tela por metro
	var hc := _o(g, x, z, 1.0)
	var halo := PackedVector2Array()   # a luz do poste atrás dele, lisa
	for i in 24:
		halo.append(hc + Vector2.from_angle(TAU * i / 24.0) * k * 0.45)
	_light_fan(hc, halo, Color(0.85, 0.62, 0.3, 0.16 * clampf(1.0 - absf(x - MAN_X) / 2.0, 0.0, 1.0)))
	var dir := 1.0 if x >= (FAR_LAMPS[0] as float) else -1.0
	_poly(PackedVector2Array([_o(g, x - 0.2, z), _o(g, x + 0.2, z), _o(g, x + dir * 2.4, z + 0.6), _o(g, x + dir * 2.0, z + 0.6)]),
		Color(0, 0, 0, 0.5))
	# (x de um lado a outro, altura de baixo para cima), em metros: pernas, casaco, ombros, cabeça, aba e copa do chapéu
	var legs: Array[Rect2] = [Rect2(-0.17, 0.0, 0.13, 0.8), Rect2(0.04, 0.0, 0.13, 0.8)]
	if walking and steps % 2 == 0:
		legs = [Rect2(-0.22, 0.0, 0.13, 0.8), Rect2(0.09, 0.0, 0.13, 0.8)]
	elif walking:
		legs = [Rect2(-0.07, 0.0, 0.14, 0.8)]
	for part: Rect2 in legs + [Rect2(-0.24, 0.55, 0.48, 0.8),
			Rect2(-0.27, 1.25, 0.54, 0.2), Rect2(-0.1, 1.45, 0.2, 0.22), Rect2(-0.2, 1.66, 0.4, 0.05), Rect2(-0.11, 1.7, 0.22, 0.13)]:
		var a := Vector2(roundf(part.position.x * k), -roundf((part.position.y + part.size.y) * k))
		var b := Vector2(roundf(part.end.x * k), -roundf(part.position.y * k))
		_p(foot.x + a.x, foot.y + a.y, maxf(1.0, b.x - a.x), maxf(1.0, b.y - a.y), Color.BLACK)


## Alguém novo na calçada de lá, indo de um lado ao outro: cada um com o seu passo, a sua altura, a sua distância das
## fachadas e, sem chuva, de chapéu ou não. `t` vai de 0 a 1 (negativo: ainda não entrou na rua).
func _walker() -> Dictionary:
	return {"t": 0.0, "dir": 1.0 if randf() < 0.5 else -1.0, "sec": WALK_SEC * randf_range(0.8, 1.2), "z": randf_range(12.4, 13.6),
		"h": randf_range(0.92, 1.06), "hat": randf() < 0.5}


## Põe `w` na calçada, na ordem do desenho (os de mais longe primeiro).
func _add_walker(w: Dictionary) -> void:
	_walkers.insert(_walkers.bsearch_custom(w, func(a: Dictionary, b: Dictionary) -> bool: return a["z"] > b["z"]), w)


## Alguém passando pela calçada de lá (`w`, de `_walker`; fora da vista, não desenha): silhueta escura de 1,7 m contra as luzes, as pernas
## alternando a cada passo, com um balanço leve, e de guarda-chuva aberto na chuva. Em px da tela, como o homem.
func _draw_walker(g: Rect2, w: Dictionary) -> void:
	var z: float = w["z"]
	var x: float = lerpf(-16.0, 16.0, w["t"]) * w["dir"]
	if absf(x) > g.size.x * 0.5 * z / OUT_F + 1.0:
		return
	var steps := int(w["t"] * w["sec"] * WALK_STEPS)
	var foot := (_o(g, x, z) * 2.0).floor() - Vector2(0, posmod(steps, 2))
	var k: float = OUT_F / z * 2.0 * w["h"]   # px da tela por metro (na altura dele)
	var dark := Color("07090c")
	_poly(PackedVector2Array([_o(g, x - 0.3, z), _o(g, x + 0.3, z), _o(g, x + 0.3, z + 0.2), _o(g, x - 0.3, z + 0.2)]), Color(0, 0, 0, 0.35))
	var parts: Array[Rect2] = [Rect2(-0.2, 0.75, 0.4, 0.68), Rect2(-0.1, 1.43, 0.2, 0.22)]   # o casaco e a cabeça
	parts.append_array([Rect2(-0.22, 0.0, 0.13, 0.8), Rect2(0.09, 0.0, 0.13, 0.8)] if posmod(steps, 2) == 0 else [Rect2(-0.07, 0.0, 0.14, 0.8)])
	if weather == "rain":   # o guarda-chuva: a cúpula, a beira e o cabo
		parts.append_array([Rect2(-0.55, 1.74, 1.1, 0.1), Rect2(-0.42, 1.84, 0.84, 0.1), Rect2(-0.2, 1.94, 0.4, 0.05), Rect2(-0.02, 1.4, 0.04, 0.36)])
	elif w["hat"]:
		parts.append_array([Rect2(-0.18, 1.63, 0.36, 0.04), Rect2(-0.1, 1.66, 0.2, 0.1)])
	for part in parts:
		var a := Vector2(roundf(part.position.x * k), -roundf((part.position.y + part.size.y) * k))
		var b := Vector2(roundf(part.end.x * k), -roundf(part.position.y * k))
		_p(foot.x + a.x, foot.y + a.y, maxf(1.0, b.x - a.x), maxf(1.0, b.y - a.y), dark)


## O carro `c` passando pela mão dele (`CAR_LANES`), apoiado no asfalto: a sombra de contato, o facho dos faróis no
## chão à frente, o lado de cá (vidros, coluna, frisos, rodas com calota), o capô, o teto e o porta-malas vistos um
## pouco de cima (os olhos ficam acima dele) e a frente ou a traseira, a que estiver virada para nós. Posto a partir da
## frente (`_car_x`), no sentido em que anda: o de lá vai para a esquerda, o de cá volta para a direita. 4,5 × 1,8 ×
## 1,45 m.
func _draw_car(g: Rect2, c: Dictionary) -> void:
	var lane: Vector2 = CAR_LANES[c["lane"]]
	var d := lane.y   # o sentido: a frente vai para lá
	var x := _car_x(c)
	var at := func(a: float) -> float: return x - d * a   # a metros da frente, para trás
	var span := func(a: float, b: float) -> Vector2: return Vector2(minf(at.call(a), at.call(b)), maxf(at.call(a), at.call(b)))
	var z0 := lane.x - 0.9   # o lado de cá
	var z1 := lane.x + 0.9
	var body := Color("1b2530")
	var top := Color("2e3a46")
	var glass := Color("0b1218")
	var chrome := Color("5a6670")
	var all: Vector2 = span.call(-0.2, 4.7)
	_poly(_patch(g, all.x, all.y, z0 - 0.15, z1 + 0.15), Color(0, 0, 0, 0.55))   # o contato com o asfalto
	_poly(PackedVector2Array([_o(g, x, z0 + 0.2), _o(g, x, z1 - 0.2), _o(g, x + d * 8.0, z1 + 0.6), _o(g, x + d * 8.0, z0 - 0.6)]),
		Color(1.0, 0.95, 0.8, 0.12))   # o facho dos faróis
	var trunk: Vector2 = span.call(3.6, 4.5)
	_poly(_patch(g, trunk.x, trunk.y, z0, z1, 0.95), top)   # o porta-malas
	var roof: Vector2 = span.call(1.6, 3.2)
	_poly(_patch(g, roof.x, roof.y, z0 + 0.15, z1 - 0.15, 1.45), top.lightened(0.08))   # o teto
	_poly(PackedVector2Array([_o(g, at.call(1.1), z0 + 0.1, 0.95), _o(g, at.call(1.6), z0 + 0.15, 1.45),
		_o(g, at.call(1.6), z1 - 0.15, 1.45), _o(g, at.call(1.1), z1 - 0.1, 0.95)]), glass)   # o para-brisa
	var hood: Vector2 = span.call(0.0, 1.1)
	_poly(_patch(g, hood.x, hood.y, z0, z1, 0.95), top)   # o capô
	var rear: float = at.call(4.5)
	if d * x < 0.0:   # a frente, virada para nós enquanto ele vem
		_poly(PackedVector2Array([_o(g, x, z0, 0.3), _o(g, x, z1, 0.3), _o(g, x, z1, 0.95), _o(g, x, z0, 0.95)]), body.darkened(0.2))
	elif d * rear > 0.0:   # a traseira, quando ele já passou
		_poly(PackedVector2Array([_o(g, rear, z0, 0.3), _o(g, rear, z1, 0.3), _o(g, rear, z1, 0.95), _o(g, rear, z0, 0.95)]),
			body.darkened(0.2))
	var side := PackedVector2Array()   # o lado de cá
	for p: Vector2 in [Vector2(0.0, 0.3), Vector2(0.0, 0.8), Vector2(0.1, 0.95), Vector2(4.4, 0.95), Vector2(4.5, 0.8), Vector2(4.5, 0.3)]:
		side.append(_o(g, at.call(p.x), z0, p.y))
	_poly(side, body)
	var win := PackedVector2Array()
	for p: Vector2 in [Vector2(1.1, 0.97), Vector2(1.6, 1.43), Vector2(3.2, 1.43), Vector2(3.6, 0.97)]:
		win.append(_o(g, at.call(p.x), z0 + 0.05, p.y))
	_poly(win, glass)
	_ci.draw_line(_o(g, at.call(2.35), z0, 0.97), _o(g, at.call(2.35), z0, 1.43), body, PX)   # a coluna do meio
	_ci.draw_line(_o(g, at.call(1.5), z0, 1.2), _o(g, at.call(1.9), z0, 1.38), Color("3a4a58"), PX)   # o reflexo
	_ci.draw_line(_o(g, x, z0, 0.95), _o(g, rear, z0, 0.95), chrome, PX)   # os frisos
	_ci.draw_line(_o(g, x, z0, 0.4), _o(g, rear, z0, 0.4), chrome, PX)
	_ci.draw_line(_o(g, at.call(2.3), z0, 0.4), _o(g, at.call(2.3), z0, 0.95), Color(0, 0, 0, 0.5), PX)   # a porta
	for wx2 in [0.8, 3.6]:   # as rodas, com a calota
		var a := _o(g, minf(at.call(wx2 - 0.33), at.call(wx2 + 0.33)), z0, 0.62)
		var b := _o(g, maxf(at.call(wx2 - 0.33), at.call(wx2 + 0.33)), z0, 0.0)
		_r(a.x, a.y, b.x - a.x, b.y - a.y, Color("030506"))
		var m := (a + b) / 2.0
		_r(m.x - (b.x - a.x) * 0.2, m.y - (b.y - a.y) * 0.2, (b.x - a.x) * 0.4, (b.y - a.y) * 0.4, Color("3a444b"))
	var k := OUT_F / z0
	var w := maxf(1.0, 0.2 * k)
	var hl := _o(g, x, z0, 0.7)
	_r(hl.x - PX if d < 0.0 else hl.x - w + PX, hl.y - 0.08 * k, w, maxf(1.0, 0.16 * k), Color("fff1c8"))   # o farol
	var tw := maxf(PX, 0.15 * k)
	var tl := _o(g, rear, z0, 0.75)
	_r(tl.x - tw if d < 0.0 else tl.x, tl.y - 0.08 * k, tw, maxf(1.0, 0.16 * k), Color("8a1e14"))   # a lanterna


## O arbusto plantado junto da nossa parede, embaixo da janela (`SHRUB`): só a copa aparece, subindo do peitoril
## atrás do vidro, posta pela parede da sala (`_side_pt`) e não pela câmera da vista. Folhas em quatro tons (as de
## cima pegando a luz da rua), maiores do lado de perto, mexendo com o vento.
func _draw_shrub() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var t := Time.get_ticks_msec() / 1000.0
	var wind := {"rain": 0.5 + rain_level(), "clear": 0.6, "fog": 0.3}.get(weather, 0.6) as float
	# as rajadas: o vento cresce e some em ondas lentas e empurra a copa para um lado (`GUST`)
	var gust := pow(maxf(0.0, sin(t * GUST.x) * sin(t * GUST.y + 1.3)), 0.6)
	var tones := [Color("08120c"), Color("0f2016"), Color("193323"), Color("2a4a33")]
	var f := _flash()
	_ci.draw_set_transform(Vector2.ZERO)   # as folhas em px da tela
	var gw := SIDE_W
	var gh := _cm(WIN_SILL - WIN_TOP)
	for i in 360:
		var hgt := pow(rng.randf(), 0.7) * SHRUB.z
		var r := SHRUB.y * sqrt(maxf(0.0, 1.0 - pow(hgt / SHRUB.z, 2.0)))   # a copa: redonda, mais larga embaixo
		var dx := rng.randf_range(-r, r)
		var w := Vector2((SHRUB.x + dx) * gw, gh * (1.0 - hgt) + rng.randf_range(-1.0, 1.0))
		var p := (_side_pt(w, WALL_D + 8.0) - _view_at) * 2.0   # do lado de fora, atrás do vidro
		var k := clampf(_side_pt(w + Vector2(0, 1)).y - _side_pt(w).y, 0.8, 1.6)   # a escala da parede ali
		var sway := roundf((sin(t * (1.4 + gust) + i * 0.7) * (1.0 + gust) - gust * GUST.z) * wind * hgt / SHRUB.z * 1.5)
		var lit := clampf(hgt / SHRUB.z * 0.7 + (dx / maxf(0.01, r)) * 0.15 + rng.randf_range(-0.25, 0.2), 0.0, 0.99)
		var c: Color = (tones[int(lit * tones.size())] as Color).lerp(Color("5a7090"), f * 0.5)
		var px := p.floor() + Vector2(sway, 0)
		var lw := roundf(5.0 * k)
		var lh := roundf(3.0 * k)
		_ci.draw_rect(Rect2(px, Vector2(lw, lh)), c)
		_ci.draw_rect(Rect2(px + Vector2(1, -1), Vector2(lw - 2, 1)), c)
		_ci.draw_rect(Rect2(px + Vector2(1, lh), Vector2(lw - 2, 1)), c.darkened(0.3))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O letreiro de neon do hotel, preso na fachada do outro lado (`o`: o alto dele): HOTEL de cima para baixo, na fonte
## gravada da mesa comutadora (`PixelArt.tiny`). Aceso quase sempre (`_sign_on`); o T falha sozinho.
func _draw_hotel_sign(o: Vector2) -> void:
	_r(o.x + 5, o.y + 2, 1.5, PX, Color("1d262c"))   # o braço
	_r(o.x, o.y, 5, 31 * PX, Color("0a0d10"))   # a caixa
	var on := _sign_on()
	var buzz := on and not (int(Time.get_ticks_msec() / 70.0) % 23 in [3, 4, 9, 15, 16, 17])
	_ci.draw_set_transform(Vector2.ZERO)
	for i in 5:
		var lit := buzz if i == 2 else on
		var tex := PixelArt.tiny("HOTEL"[i])
		_ci.draw_texture(tex, (o * 2.0 + Vector2(3, i * 6 - 2)).floor(), SIGN_RED if lit else Color("3a1512"))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Sorteados sempre do mesmo jeito: a cidade no fundo (em px de 2x2, para cada tamanho de vidro: duas fileiras), os
## prédios do outro lado da rua, de frente (`_houses`, em metros: o de tijolos na esquina, à direita do cruzamento) e
## as paredes da rua do cruzamento (`_canyon`); cada janela acesa com a hora em que apaga (`SLEEP`; algumas ficam
## acesas a noite toda).
func _build_city(gs: Vector2) -> void:
	_city.clear()
	_city_for = gs
	var rng := RandomNumberGenerator.new()
	rng.seed = 1957
	var sleep := RandomNumberGenerator.new()   # à parte: as casas continuam as mesmas
	sleep.seed = 1958
	var up := RandomNumberGenerator.new()   # quem levanta de madrugada, também à parte
	up.seed = 1959
	var off := func() -> float:
		return INF if sleep.randf() < SLEEP.z else sleep.randf_range(SLEEP.x, SLEEP.y)
	for r in [0, 1]:
		var k: float = OUT_F / [400.0, 250.0][r]
		var x := -rng.randf() * 4.0
		while x < gs.x:
			var bw := rng.randf_range(15.0, 35.0) * k
			var bh := (rng.randf_range(30.0, 80.0) if r == 0 else rng.randf_range(15.0, 45.0)) * k
			var lit: Array[Vector3] = []
			var yy := 1.5
			while yy < bh - 1.0:
				var xx := 1.0
				while xx < bw - 1.0:
					if rng.randf() < 0.2:
						lit.append(Vector3(xx, yy, off.call()))
					xx += 2.0
				yy += 2.0
			_city.append({"x": x, "w": bw, "h": bh, "row": r, "lit": lit})
			x += bw + rng.randf_range(0.0, 1.5)
	_houses.clear()
	var tones := [Color("1c1714"), Color("13171b"), Color("1a1512"), Color("171a1d")]
	var spans := [Vector2(CROSSING.y, CROSSING.y + 15.0)]   # o de tijolos, na esquina
	var x := CROSSING.y + 15.0
	while x < 40.0:
		var w := rng.randf_range(9.0, 14.0)
		spans.append(Vector2(x, x + w))
		x += w
	x = CROSSING.x
	while x > -40.0:
		var w := rng.randf_range(9.0, 14.0)
		spans.append(Vector2(x - w, x))
		x -= w
	for i in spans.size():
		var sp: Vector2 = spans[i]
		var floors := 4 if i == 0 else rng.randi_range(2, 4)
		if sp.x <= HOTEL_X and HOTEL_X <= sp.y:   # o do hotel cobre o letreiro (alto a 10 m, `_hotel_pos`)
			floors = 4
		var wins: Array[Vector3] = []
		for f in floors:
			var wsx := sp.x + 1.5
			while wsx < sp.y - 1.0:
				if i == 0 and f == 2 and wsx < APT["x1"]:   # a varanda do apartamento (`_draw_balcony`)
					wsx += 3.0
					continue
				var o := -1.0   # apagada
				if rng.randf() < (0.35 if f > 0 else 0.25):
					o = off.call()
				wins.append(Vector3(wsx, f, o))
				wsx += 3.0
		var wake := {}   # janela -> quando ela acende de novo (min do dia, de x a y)
		for j in wins.size():
			var wv := wins[j]
			if wv.y > 0.0 and wv.z < INF and up.randf() < WAKE:
				var at := up.randf_range(maxf(wv.z, WAKE_FROM) + 10.0, 23 * 60 + 50)
				wake[j] = Vector2(at, at + up.randf_range(WAKE_FOR.x, WAKE_FOR.y))
		_houses.append({"x0": sp.x, "x1": sp.y, "h": floors * 3.2 + 0.8, "col": Color("3a2219") if i == 0 else tones[rng.randi_range(0, 3)],
			"brick": i == 0, "wins": wins, "wake": wake})
	_canyon.clear()   # as paredes da rua do cruzamento: os fundos dos prédios da esquina e os que vêm depois, até a praça
	for side: float in [CROSSING.x, CROSSING.y]:
		var z := STREET["far"] as float
		while z < 118.0:
			var d := rng.randf_range(10.0, 22.0)
			var ht := rng.randf_range(7.0, 16.0)
			if z == STREET["far"]:   # a lateral do prédio da esquina: a altura da fachada dele
				for b: Dictionary in _houses:
					if is_equal_approx(b["x1"], side) or is_equal_approx(b["x0"], side):
						ht = b["h"]
			var wins: Array[Vector3] = []
			for i in 6:
				if rng.randf() < 0.4:
					wins.append(Vector3(rng.randf_range(z + 1.0, z + d - 1.0), rng.randf_range(2.0, ht - 1.5), off.call()))
			_canyon.append({"x": side, "z0": z, "z1": z + d, "h": ht, "col": tones[rng.randi_range(0, 3)], "wins": wins})
			z += d
	_canyon.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["z0"] < b["z0"])


## A igreja no fim da rua do cruzamento (na escala dela, `CHURCH_K`): nave, torre com a ponta e o relógio aceso no
## alto; a porta acesa até `CHURCH_DARK`.
func _draw_church(base: Vector2, col: Color) -> void:
	var k := CHURCH_K
	_r(base.x - 12 * k, base.y - 18 * k, 24 * k, 18 * k, col)
	_poly(PackedVector2Array([base + Vector2(-13, -18) * k, base + Vector2(0, -26) * k, base + Vector2(13, -18) * k]), col)
	_r(base.x - 4 * k, base.y - 48 * k, 8 * k, 30 * k, col)
	_poly(PackedVector2Array([base + Vector2(-5, -48) * k, base + Vector2(0, -60) * k, base + Vector2(5, -48) * k]), col)
	var top := Vector2(roundf(base.x / PX) * PX, roundf((base.y - 60 * k) / PX) * PX)   # a ponta da torre, presa ao pixel
	_r(top.x - PX, top.y - 3.5, 2 * PX, 4.0, col)   # a cruz: a haste entra na ponta, e os braços ficam no alto dela
	_r(top.x - 1.5, top.y - 2.5, 3.0, PX, col)
	var face := base + Vector2(0, -40 * k)
	_ci.draw_circle(face, 1.3, Color("e2b25a"))
	_r(face.x - PX, face.y - 1, PX, 1, Color("2a2016"))   # os ponteiros
	if minutes < CHURCH_DARK:
		_r(base.x - 1, base.y - 4, 2, 4, Color(LIT[1], 0.8))   # a porta, com luz dentro (o relógio fica aceso)


## O clima no vidro: a chuva passando e as gotas paradas no vidro, que às vezes escorrem (chuva), e um reflexo na
## diagonal (a névoa fica na vista, `_draw_fog`).
func _draw_glass_weather(g: Rect2) -> void:
	if weather == "rain":
		# os pingos: riscos de 1 px inclinados pelo vento, mais longos e claros os de perto, e acesos perto dos postes
		var heads := _lamp_heads(g)
		var many := int(_drops.size() * rain_level())   # na garoa, poucos
		for i in many:
			var d: Vector3 = _drops[i]
			if d.x < 0.0 or d.x >= 1.0 or d.y < 0.0:
				continue
			var hp := Vector2(g.position.x + floorf(d.x * g.size.x * 2.0) * PX, g.position.y + floorf(d.y * g.size.y * 2.0) * PX)
			var lit := 0.0
			for h: Vector2 in heads:
				lit = maxf(lit, 1.0 - hp.distance_to(h) / 45.0)
			var col := Color(0.62, 0.72, 0.8).lerp(Color("ffd88a"), lit * 0.7)
			col.a = lerpf(0.14, 0.34, d.z) + lit * 0.3
			var n := lerpf(RAIN_STREAK.x, RAIN_STREAK.y, d.z)
			var cols := 1 + int(n * RAIN_SLANT)   # o rastro sobe para a direita, de onde ele veio, em degraus de 1 px
			var seg := ceilf(n / cols)
			for k in cols:
				_r(hp.x + k * PX, hp.y - (k + 1) * seg * PX, PX, seg * PX, col)
			_r(hp.x, hp.y, PX, PX, Color(col, minf(1.0, col.a * 1.6)))   # a ponta, mais clara
		# as gotas no vidro, só na parte dele que aparece: escuras, com um brilho, quente perto do poste (`_draw_city`)
		var top := g.position.y + g.size.y * _glass_from
		var post := _post(Rect2(g.position, g.size - Vector2(0, _near)))
		for b in _beads:
			var p := Vector2(g.position.x + floorf(b.x * g.size.x * 2.0) * PX, top + floorf(b.y * (g.end.y - top) * 2.0) * PX)
			if b.w > 0.0:   # escorrendo: o rastro molhado acima dela
				for k in 4:
					_r(p.x, p.y - (k + 1) * PX, PX, PX, Color(0.55, 0.66, 0.74, 0.2 - k * 0.045))
			_r(p.x, p.y, b.z * PX, b.z * PX, Color("1c2a32"))
			var warm := clampf(1.0 - p.distance_to(post) / 30.0, 0.0, 1.0) if lamp_level > 0.5 else 0.0
			_r(p.x, p.y, PX, PX, Color("7f98a8").lerp(Color("ffd88a"), warm))
	_poly(PackedVector2Array([g.position + Vector2(g.size.x * 0.12, 0), g.position + Vector2(g.size.x * 0.22, 0),
		g.position + Vector2(g.size.x * 0.02, g.size.y * 0.5), g.position + Vector2(0, g.size.y * 0.5)]), Color(1, 1, 1, 0.03))
