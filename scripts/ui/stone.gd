extends RefCounted
## A pedra da noite 14 (`StreetEvent` "stone"), às 23h, com a rua já vazia do toque de recolher: atirada da rua
## embaixo da janela (quem atira não aparece), sobe crescendo até o vidro, bate na parte esquerda dele, quica para
## trás e cai de volta para a rua, e deixa o trincado, que fica (`Background.LASTING`: a noite 15 começa com ele). Desenhada por cima da vista, na camada do vidro
## trincado (`Background._crack`), em px da tela. Só o roteiro, sem estado: tudo sai do tempo `t` (s desde o arremesso).

const FLY := 0.45    ## quanto ela leva da rua ao vidro (s)
const HIT := Vector2(0.24, 0.6)   ## onde bate: fração do vidro que aparece (x da beira de longe, y do alto abaixo da persiana)
const FROM := Vector2(0.46, 0.97)   ## de onde ela vem: a rua embaixo da janela, no pé do vidro
const SIZE := Vector2(2.0, 6.0)   ## o tamanho dela (px da tela): na rua, longe, e chegando no vidro
const BOUNCE := Vector3(-0.05, -0.6, 0.7)   ## o quique: para o lado e para cima (fração do vidro por s) e o tamanho a que ela volta, se afastando...
const FALL := 4.2    ## ...a gravidade puxando para baixo (fração do vidro por s²)...
const DROP := 0.7    ## ...e quanto leva caindo até sumir no pé do vidro (s)
const END := FLY + DROP
const SQUASH := 0.72   ## o vidro visto de lado (na parede da direita): o trincado mais estreito que alto
const ART := Vector2i(150, 160)   ## o desenho do trincado (px da tela), com o ponto da batida no meio
const RAYS := 11     ## os riscos saindo do ponto da batida...
const RAY_LEN := Vector2(26.0, 76.0)   ## ...e o comprimento de cada um (px, antes do `SQUASH`)
const RINGS := [7.0, 16.0, 29.0, 45.0]   ## os arcos entre os riscos, a essa distância do ponto (px): cada vez menos deles

static var _art: ImageTexture


## Onde ela está no vidro (x, y em fração dele, como `HIT`) e de que tamanho (z, px), `t` s depois de atirada; já no
## fim da queda (ou ainda não atirada), z = 0. Vindo na nossa direção, ela cresce e corre mais no fim (a perspectiva);
## quicando, sobe um pouco, se afasta (encolhe) e cai.
static func at(t: float) -> Vector3:
	if t < 0.0 or t >= END:
		return Vector3.ZERO
	if t >= FLY:
		var d := t - FLY
		var q := HIT + Vector2(BOUNCE.x, BOUNCE.y) * d + Vector2(0.0, FALL * d * d / 2.0)
		return Vector3(q.x, q.y, SIZE.y * lerpf(1.0, BOUNCE.z, minf(1.0, d / 0.2)))
	var u := pow(t / FLY, 2.2)
	var p := FROM.lerp(HIT, u) + Vector2(0.0, -0.08 * sin(PI * t / FLY))   # (um arco de leve, subindo)
	return Vector3(p.x, p.y, lerpf(SIZE.x, SIZE.y, u))


## O vidro já trincado `t` s depois de atirada.
static func cracked(t: float) -> bool:
	return t >= FLY


## O trincado (`ART`, o ponto da batida no meio), feito uma vez: o miolo moído em volta do ponto, os riscos saindo
## dele em zigue-zague, alguns com um galho, e os arcos ligando riscos vizinhos. Cada risco claro (o vidro partido pega
## a luz) com a sombra 1 px abaixo e à direita, mais fraco na ponta.
static func art() -> ImageTexture:
	if _art:
		return _art
	var img := Image.create(ART.x, ART.y, false, Image.FORMAT_RGBA8)
	var lit := Image.create(ART.x, ART.y, false, Image.FORMAT_RGBA8)   # (os claros, juntados por cima das sombras no fim)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1423
	var c := Vector2(ART) / 2.0
	var rays: Array[PackedVector2Array] = []
	for i in RAYS:
		var a := TAU * (i + rng.randf_range(-0.3, 0.3)) / RAYS
		var pts := _zigzag(rng, Vector2.ZERO, a, rng.randf_range(RAY_LEN.x, RAY_LEN.y))
		rays.append(pts)
		if rng.randf() < 0.55:   # um galho saindo do meio dele
			var k := rng.randi_range(2, maxi(2, pts.size() - 2))
			_crack_line(img, lit, c, _zigzag(rng, pts[k], a + rng.randf_range(0.5, 0.9) * signf(rng.randf() - 0.5), rng.randf_range(6.0, 14.0)), 0.55)
		_crack_line(img, lit, c, pts, 0.9)
	for n in RINGS.size():
		var r: float = RINGS[n]
		for i in RAYS:
			if rng.randf() > 0.8 - 0.22 * n:
				continue
			var a := _on(rays[i], r * rng.randf_range(0.9, 1.1))
			var b := _on(rays[(i + 1) % RAYS], r * rng.randf_range(0.9, 1.1))
			if a == Vector2.INF or b == Vector2.INF:
				continue
			var mid := (a + b) / 2.0 * rng.randf_range(1.04, 1.14)   # (o arco abaulado para fora)
			_crack_line(img, lit, c, PackedVector2Array([a, mid, b]), 0.6 - 0.12 * n)
	for y in range(-4, 5):   # o miolo moído, no ponto da batida
		for x in range(-4, 5):
			var d := Vector2(x, y).length()
			if d <= 2.0 or (d <= 4.2 and rng.randf() < 0.45):
				lit.set_pixel(int(c.x) + x, int(c.y) + y, Color(Pal.GLASS_CRACK, 0.95 if d <= 2.0 else 0.6))
	img.blend_rect(lit, Rect2i(Vector2i.ZERO, ART), Vector2i.ZERO)
	_art = ImageTexture.create_from_image(img)
	return _art


## Um risco de `from`, no ângulo `a`, com `len` px: passos curtos, cada um virando um pouco.
static func _zigzag(rng: RandomNumberGenerator, from: Vector2, a: float, len: float) -> PackedVector2Array:
	var pts := PackedVector2Array([from])
	var p := from
	var d := 0.0
	while d < len:
		var step := rng.randf_range(3.0, 7.0)
		a += rng.randf_range(-0.35, 0.35)
		p += Vector2(cos(a), sin(a)) * step
		d += step
		pts.append(p)
	return pts


## O ponto do risco `pts` a `r` px do ponto da batida (INF: o risco é mais curto).
static func _on(pts: PackedVector2Array, r: float) -> Vector2:
	for i in range(1, pts.size()):
		if pts[i].length() >= r:
			var a := pts[i - 1]
			var b := pts[i]
			return a.lerp(b, clampf((r - a.length()) / maxf(0.01, b.length() - a.length()), 0.0, 1.0))
	return Vector2.INF


## O risco `pts` (px a partir do ponto da batida, em `c`, antes do `SQUASH`) pixel a pixel: o claro em `lit`, de força
## `a` no começo até um terço dela na ponta, e a sombra em `img`.
static func _crack_line(img: Image, lit: Image, c: Vector2, pts: PackedVector2Array, a: float) -> void:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	var run := 0.0
	for i in range(1, pts.size()):
		var p0 := c + pts[i - 1] * Vector2(SQUASH, 1.0)
		var p1 := c + pts[i] * Vector2(SQUASH, 1.0)
		var n := maxi(1, int(ceilf(maxf(absf(p1.x - p0.x), absf(p1.y - p0.y)))))
		var seg := pts[i].distance_to(pts[i - 1])
		for s in n + 1:
			var p := Vector2i(p0.lerp(p1, float(s) / n).round())
			if p.x < 1 or p.y < 1 or p.x >= ART.x - 1 or p.y >= ART.y - 1:
				return
			var f := a * lerpf(1.0, 0.35, (run + seg * s / n) / maxf(1.0, total))
			if lit.get_pixel(p.x, p.y).a < f:
				lit.set_pixel(p.x, p.y, Color(Pal.GLASS_CRACK, f))
			img.set_pixel(p.x + 1, p.y + 1, Color(0, 0, 0, maxf(img.get_pixel(p.x + 1, p.y + 1).a, f * 0.45)))
		run += seg
