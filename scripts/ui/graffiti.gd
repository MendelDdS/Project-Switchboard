extends RefCounted
## A pichação da noite 4 e a tinta por cima na noite 7 (`StreetEvent` "graffiti" e "paint"), no muro do prédio do hotel
## entre a porta e a esquina. Na 4, de madrugada, alguém de capuz vem pela calçada, para no muro, olha para os lados,
## sacode a lata e picha três letras inventadas e um risco embaixo (o braço indo de pixel em pixel, a tinta aparecendo
## no caminho dele, `tag`, e escorrendo um pouco depois, `drips`), olha de novo e foge correndo para a direita
## (`tagger`). Na 7, um pintor de macacão vem da esquerda com o balde e o rolo, põe o balde no chão, molha o rolo e
## cobre a pichação em faixas, de baixo para cima (`patch`, `painter`, `bucket`), e vai embora. A mancha fica até o
## fim do jogo, e a pichação aparece nas noites entre as duas (`Background.left_behind`). Só o roteiro, como o
## `Beating`: tudo sai do tempo `t` (s desde o começo de cada cena).

const Beating := preload("res://scripts/ui/beating.gd")
const Chase := preload("res://scripts/ui/chase.gd")
const WALL := Vector3(-4.95, 9.4, 1.42)   ## o meio da pichação (x), a fachada (z) e a altura do alto das letras (m)
const CELL := 0.1   ## um pixel da pichação no muro (m; ~1 px da tela a essa distância)
## As letras inventadas, de 3x5 (de cima para baixo; "#" pinta), na ordem em que o braço passa por elas (cada uma
## desenhada de cima para baixo, coluna a coluna, como quem escreve).
const GLYPHS := [["#.#", "###", "#.#", "#..", "#.."], [".##", "#.#", ".##", "..#", "##."], ["##.", "#.#", "##.", "#.#", "##."]]
const PIXEL := 0.1   ## quanto o spray leva em cada pixel (s)
const ARM := Vector2(0.3, 0.28)   ## braço e antebraço (m; o `ARM` da vista)
const SHOULDER_H := 1.31   ## o ombro de quem está em pé (m; o quadril de `Beating.STAND` e o pescoço do rig)
const SHAKE := 12.75   ## quando ele sacode a lata (s)...
const SPRAY_AT := 13.6   ## ...quando a lata começa a pintar...
const SPRAY_END := 18.0   ## ...e quando para (o último pixel do risco; o som)
const SET_DOWN := 8.4   ## quando o pintor põe o balde no chão (s)
const DRIP := Vector2(0.6, 1.2)   ## a escorrida: começa tanto depois do pixel e desce um pixel nesse tempo (s)...
const DRIPS := 4   ## ...em tantas colunas
## O pintor: quando começa a passar o rolo, quanto leva cada faixa (s) e a mancha (x de um lado ao outro, de baixo a
## cima, m).
const ROLL_AT := 10.5
const BAND_SEC := 2.4
const PATCH := Rect2(-5.62, 0.72, 1.36, 0.9)
const ROLLER := 0.23   ## a largura do rolo (m)

static var _pixels: Array = []   # [Vector2i(coluna, linha a partir do alto), instante em que aparece]
static var _tagger: Array = []
static var _painter: Array = []


## Os pixels da pichação já pintados no instante `t`: Vector2i(coluna, linha), a partir do canto de cima à esquerda.
static func tag(t: float) -> Array:
	var out := []
	for p: Array in _paint_order():
		if t >= p[1]:
			out.append(p[0])
	return out


## A tinta escorrendo embaixo de algumas letras: [Vector2i(coluna, linha onde começa), quantos pixels desceu].
static func drips(t: float) -> Array:
	var out := []
	var order := _paint_order()
	for i in DRIPS:
		var p: Array = order[(i * 7 + 3) % order.size()]
		var run := clampi(floori((t - p[1] - DRIP.x) / DRIP.y) + 1, 0, 1 + i % 2)
		if run > 0:
			out.append([p[0] + Vector2i(0, 1), run])
	return out


## O rapaz de capuz no instante `t` (vazio fora da cena).
static func tagger(t: float) -> Dictionary:
	if _tagger.is_empty():
		_tagger = Beating._build(_tagger_keys())
	return {} if t < 0.0 or t >= _tagger[-1][0] else Beating._at(_tagger, t)


## O pintor no instante `t` (vazio fora da cena).
static func painter(t: float) -> Dictionary:
	if _painter.is_empty():
		_painter = Beating._build(_painter_keys())
	return {} if t < 0.0 or t >= _painter[-1][0] else Beating._at(_painter, t)


## A parte da mancha de tinta nova já pintada no instante `t`: os retângulos no muro (x, altura; m), uma faixa do rolo
## por vez, subindo; cada faixa um pouco desencontrada da vizinha em cima e embaixo (o rolo à mão).
static func patch(t: float) -> Array:
	var out := []
	var bands := ceili(PATCH.size.x / ROLLER)
	for i in bands:
		var u := clampf((t - ROLL_AT - i * BAND_SEC) / (BAND_SEC * 0.8), 0.0, 1.0)
		if u > 0.0:
			var x := PATCH.position.x + i * ROLLER
			var low := PATCH.position.y + 0.05 * ((i * 5 + 1) % 3 - 1)
			var high := PATCH.end.y + 0.05 * ((i * 7 + 2) % 3 - 1)
			out.append(Rect2(x, low, minf(ROLLER, PATCH.end.x - x), (high - low) * u))
	return out


## O balde do pintor no instante `t`: Vector3(x, z, 1 no chão; 0 na mão; -1 fora da cena).
static func bucket(t: float) -> Vector3:
	var p := painter(t)
	if p.is_empty():
		return Vector3(0, 0, -1)
	return Vector3(PATCH.position.x - 0.35, WALL.y - 0.3, 0.0 if p.get("bucket", false) else 1.0)


## Para onde quem está na calçada olha (x, m; INF: nada): ninguém, de madrugada; o pintor, de passagem, não chama atenção.
static func focus(_t: float) -> float:
	return INF


## A ordem dos pixels, uma vez: letra por letra, coluna por coluna, de cima para baixo, e o risco embaixo, da esquerda
## para a direita; cada um com o seu instante.
static func _paint_order() -> Array:
	if not _pixels.is_empty():
		return _pixels
	var t := SPRAY_AT
	for g in GLYPHS.size():
		for col in 3:
			for row in 5:
				if (GLYPHS[g][row] as String)[col] == "#":
					_pixels.append([Vector2i(g * 4 + col, row), t])
					t += PIXEL
		t += 0.35   # (de uma letra para a outra)
	for col in 11:   # o risco
		_pixels.append([Vector2i(col, 6), t])
		t += PIXEL * 0.5
	return _pixels


## O braço de cá (de frente, aberto para os lados: `open`) com a mão em (dx, altura) a partir do ombro (m): o braço
## aponta para lá e o cotovelo dobra o bastante para a mão chegar.
static func _reach(dx: float, h: float) -> Vector2:
	var dh := SHOULDER_H - h
	var r := clampf(Vector2(dx, dh).length(), 0.15, ARM.x + ARM.y - 0.01)
	var bend := acos(clampf((r * r - ARM.x * ARM.x - ARM.y * ARM.y) / (2.0 * ARM.x * ARM.y), -1.0, 1.0))
	var lag := atan2(ARM.y * sin(bend), ARM.x + ARM.y * cos(bend))
	return Vector2(rad_to_deg(atan2(dx, dh) - lag), rad_to_deg(bend))


static func _tagger_keys() -> Array:
	var stand := Vector2(WALL.x + 0.15, WALL.y - 0.35)
	var k := [[0.0, {"x": 9.5, "z": 8.9, "s": -1.0, "hat": "hood", "cloth": Pal.TAGGER[0], "pants": Pal.TAGGER[1], "skin": 2, "cop": false}]]
	Beating.walk(k, 0.0, Vector2(9.5, 8.9), stand, 1.5)
	k.append_array([
		[10.3, {"s": 1.0}], [11.1, {"s": 1.0, "head": 6.0}], [11.6, {"s": -1.0, "head": 0.0}], [12.4, {}],   # olha para os lados
		[12.7, {"front": true, "open": true, "arms": [Vector2(20, 90), Vector2(-6, 10)]}],
	])
	for i in 4:   # sacode a lata
		k.append([12.75 + i * 0.2, {"arms": [Vector2(35, 100) if i % 2 == 0 else Vector2(10, 70), Vector2(-6, 10)]}])
	var top := WALL.z
	var left := WALL.x - 5.0 * CELL
	var shoulder_x := -0.18   # (o ombro do braço de cá, de frente)
	for p: Array in _paint_order():   # a mão no pixel que está pintando, o corpo acompanhando de letra em letra
		var px: Vector2i = p[0]
		var x := left + px.x * CELL
		var body := clampf(x + 0.12, left + 0.15, left + 1.0)
		var aim := _reach(x - (body + shoulder_x), top - px.y * CELL)
		k.append([p[1], {"x": body, "arms": [aim, Vector2(-6, 10)], "lean": -2.0}, "lin"])
	var done: float = _paint_order()[-1][1] + 0.3
	k.append_array([
		[done + 0.4, {"arms": [Vector2(10, 40), Vector2(-6, 10)], "lean": 0.0}],
		[done + 0.8, {"front": false, "open": false, "s": 1.0}],
		[done + 1.3, {"s": -1.0}],
		[done + 1.7, {"s": 1.0}],
	])
	Chase._run(k, done + 2.0, [Vector2(left + 0.8, stand.y), Vector2(4.0, 8.7), Vector2(12.0, 8.4)], 4.4)
	return k


static func _painter_keys() -> Array:
	var stand := Vector2(PATCH.position.x + 0.2, WALL.y - 0.4)
	var dip := {"lean": 55.0, "hip": 0.66, "legs": [Vector2(28, 50), Vector2(-4, 30)], "arms": [Vector2(60, 10), Vector2(10, 20)]}
	var up := {"lean": 0.0, "hip": 0.82, "legs": Beating.STAND["legs"], "arms": [Vector2(10, 20), Vector2(-6, 10)]}
	var k := [[0.0, {"x": -12.5, "z": 8.9, "s": 1.0, "hat": "", "cloth": Pal.PAINTER[0], "pants": Pal.PAINTER[0], "skin": 1,
		"cop": false, "bucket": true, "roller": true, "arms": [Vector2(10, 20), Vector2(-4, 8)]}]]
	Beating.walk(k, 0.0, Vector2(-12.5, 8.9), Vector2(PATCH.position.x - 0.1, stand.y), 1.0)   # (com o balde: devagar, sem balançar os braços)
	for key: Array in k:
		key[1].erase("swing")
	k.append_array([
		[8.3, dip.merged({"bucket": true})],   # põe o balde no chão
		[8.4, {"bucket": false}],
		[9.0, up],
		[9.4, dip], [9.9, dip.merged({"arms": [Vector2(70, 15), Vector2(10, 20)]})], [10.3, up],   # molha o rolo
	])
	var bands := ceili(PATCH.size.x / ROLLER)
	for i in bands:   # cada faixa: o rolo sobe e desce duas vezes, subindo um pouco mais a cada vez
		var t0 := ROLL_AT + i * BAND_SEC
		var x := PATCH.position.x + (i + 0.5) * ROLLER
		var dx := -0.2 + 0.18   # (o corpo um palmo à direita da faixa; a mão, no ombro de cá, em cima dela)
		k.append([t0, {"x": x + 0.2, "z": stand.y, "front": true, "open": true, "arms": [_reach(dx, PATCH.position.y + 0.1), Vector2(-6, 10)]}])
		for j in 4:
			var h := PATCH.position.y + PATCH.size.y * (0.55 + 0.45 * float(j) / 3.0 if j % 2 == 0 else 0.15)
			k.append([t0 + BAND_SEC * (j + 1) / 5.0, {"arms": [_reach(dx, h), Vector2(-6, 10)]}])
	var done := ROLL_AT + bands * BAND_SEC
	k.append_array([
		[done + 0.3, up.merged({"front": false, "open": false, "s": -1.0})],
		[done + 0.8, {"x": PATCH.position.x - 0.1}],
		[done + 1.3, dip],   # pega o balde
		[done + 1.5, {"bucket": true}],
		[done + 2.1, up.merged({"walk": true})],
		[done + 2.1 + 7.0, {"x": -13.0}, "lin"],   # (sai no passo, sem frear)
	])
	return k
