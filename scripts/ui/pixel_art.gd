class_name PixelArt
## Pixel art feita em código, guardada em texturas: mapas de texto (`art`), peças redondas (`disc`) e a fonte gravada
## do painel (`tiny`). Mesa comutadora, cenário, painel do operador e bloom desenham com elas. Cada textura fica
## guardada pela chave (o mapa e as cores; o diâmetro e as camadas; o texto), sem esvaziar (só passando de
## `CACHE_MAX`): cor que muda a cada quadro vai no `modulate` do desenho, nunca nas cores daqui.
## `tools/sprite_sheet.gd` mostra tudo ampliado.

const LIGHT := Vector2(-0.7071, -0.7071)   # de onde vem a luz das peças redondas (alto à esquerda)
## Rede de segurança: um cache que passa disto foi usado com cor de cada quadro (contra a regra acima) e é esvaziado. No uso
## certo o jogo fica bem abaixo (umas 40 peças redondas numa noite); esvaziar só custa remontar o que estiver na tela.
const CACHE_MAX := 512
## A fonte gravada no painel da mesa comutadora (o estado de cada linha, a legenda, as chapas; também o letreiro do
## hotel): maiúsculas de 3 × 5 px, desenhadas pixel a pixel (`tiny`). Na fonte da tela, em 11, "conectada" não cabe na
## coluna da linha; em 8, fora da grade dela, a letra borrava.
const TINY := {"A": "###/#.#/###/#.#/#.#", "B": "##./#.#/##./#.#/##.", "C": ".##/#../#../#../.##", "D": "##./#.#/#.#/#.#/##.",
	"E": "###/#../##./#../###", "F": "###/#../##./#../#..", "G": ".##/#../#.#/#.#/.##", "H": "#.#/#.#/###/#.#/#.#",
	"I": "###/.#./.#./.#./###", "J": "..#/..#/..#/#.#/.#.", "K": "#.#/#.#/##./#.#/#.#", "L": "#../#../#../#../###",
	"M": "#.#/###/###/#.#/#.#", "N": "##./#.#/#.#/#.#/#.#", "O": ".#./#.#/#.#/#.#/.#.", "P": "##./#.#/##./#../#..",
	"Q": ".#./#.#/#.#/##./.##", "R": "##./#.#/##./#.#/#.#", "S": ".##/#../.#./..#/##.", "T": "###/.#./.#./.#./.#.",
	"U": "#.#/#.#/#.#/#.#/###", "V": "#.#/#.#/#.#/#.#/.#.", "W": "#.#/#.#/###/###/#.#", "X": "#.#/#.#/.#./#.#/#.#",
	"Y": "#.#/#.#/.#./.#./.#.", "Z": "###/..#/.#./#../###", "0": "###/#.#/#.#/#.#/###", "1": ".#./##./.#./.#./###",
	"2": "##./..#/.#./#../###", "3": "##./..#/.#./..#/##.", "4": "#.#/#.#/###/..#/..#", "5": "###/#../##./..#/##.",
	"6": ".##/#../###/#.#/###", "7": "###/..#/.#./.#./.#.", "8": "###/#.#/###/#.#/###", "9": "###/#.#/###/..#/##.",
	".": ".../.../.../.../.#.", "·": ".../.../.#./.../...", ",": ".../.../.../.#./#..", "-": ".../.../###/.../...", ":": ".../.#./.../.#./...", "/": "..#/..#/.#./#../#..",
	"(": ".#./#../#../#../.#.", ")": ".#./..#/..#/..#/.#."}
const TINY_MARKS := {"´": "..#/.#.", "`": "#../.#.", "^": ".#./#.#", "~": ".##/##.", "¨": "#.#/...", ",": ".#./##."}   ## acentos (2 linhas acima da letra; a cedilha, abaixo)
const TINY_ACCENTS := {"Á": "A´", "À": "A`", "Â": "A^", "Ã": "A~", "Ä": "A¨", "É": "E´", "È": "E`", "Ê": "E^", "Ë": "E¨",
	"Í": "I´", "Ì": "I`", "Î": "I^", "Ï": "I¨", "Ó": "O´", "Ò": "O`", "Ô": "O^", "Õ": "O~", "Ö": "O¨", "Ú": "U´", "Ù": "U`",
	"Û": "U^", "Ü": "U¨", "Ñ": "N~", "Ç": "C,", "–": "-"}


## O texto `text` na fonte do painel (`TINY`), em maiúsculas, branco (a cor vem na hora de desenhar): 4 px por letra
## e 10 de altura (os acentos nas linhas 0 e 1, as letras de 3 a 7, a cedilha em 8 e 9). Guardado.
static var _tinies := {}
static func tiny(text: String) -> ImageTexture:
	text = text.to_upper()
	if not _tinies.has(text):
		if _tinies.size() > CACHE_MAX:
			_tinies.clear()
		var img := Image.create(maxi(1, text.length() * 4 - 1), 10, false, Image.FORMAT_LA8)
		for i in text.length():
			var ch: String = TINY_ACCENTS.get(text[i], text[i])
			_tiny_glyph(img, TINY.get(ch[0], ""), i * 4, 3)
			if ch.length() > 1:
				_tiny_glyph(img, TINY_MARKS[ch[1]], i * 4, 8 if ch[1] == "," else 0)
		_tinies[text] = ImageTexture.create_from_image(img)
	return _tinies[text]


static func _tiny_glyph(img: Image, glyph: String, x: int, y: int) -> void:
	var rows := glyph.split("/")
	for r in rows.size():
		for c in rows[r].length():
			if rows[r][c] == "#":
				img.set_pixel(x + c, y + r, Color.WHITE)


## Pixel art de um mapa de texto (`rows`, um caractere por pixel; "." é vazio), nas cores de `pal` (caractere -> cor;
## "*" vale para os que faltam; sem cor, vazio). Guardada.
static var _arts := {}
static func art(rows: Array, pal: Dictionary) -> ImageTexture:
	var key := hash([rows, pal])
	if _arts.has(key):
		return _arts[key]
	if _arts.size() > CACHE_MAX:
		_arts.clear()
	var img := Image.create((rows[0] as String).length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in (rows[y] as String).length():
			var ch: String = rows[y][x]
			if ch != "." and (pal.has(ch) or pal.has("*")):
				img.set_pixel(x, y, pal.get(ch, pal.get("*")))
	var tex := ImageTexture.create_from_image(img)
	_arts[key] = tex
	return tex


## Peça redonda em pixel art, pixel a pixel (desenhada como círculo, saía embolotada): `d` pixels de diâmetro;
## `layers` de dentro para fora, [raio em pixels, cor] ou [raio, luz, meio, sombra] (a luz vem de `light`) ou
## [raio, luz, meio, sombra, true] (côncava: a luz bate do lado oposto, como no fundo de um furo). Guardada. Toda peça
## redonda do jogo sai daqui (o mesmo acabamento em todas).
static var _discs := {}
static func disc(d: int, layers: Array, light := LIGHT) -> ImageTexture:
	var key := str(d, layers, light)
	if _discs.has(key):
		return _discs[key]
	if _discs.size() > CACHE_MAX:
		_discs.clear()
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var mid := Vector2(d, d) / 2.0
	for y in d:
		for x in d:
			var o := Vector2(x + 0.5, y + 0.5) - mid
			for l in layers:
				if o.length() <= l[0]:
					var col: Color = l[1]
					if l.size() >= 4:
						var t := o.normalized().dot(light) if o.length() > 0.01 else 0.0
						if l.size() >= 5 and l[4]:
							t = -t
						col = l[1] if t > 0.38 else (l[3] if t < -0.38 else l[2])
					img.set_pixel(x, y, col)
					break
	var tex := ImageTexture.create_from_image(img)
	_discs[key] = tex
	return tex


## O mapa `rows` (de `art`) girado `angle` rad em volta de `pivot` (px do mapa; um canto entre pixels), pixel a pixel
## como no RotSprite: o mapa ampliado 8× pelo Scale2x três vezes (as diagonais viram degraus limpos, sem serrilhar) e
## lido de volta, girado, no tamanho de antes. Girada pela transformação do desenho, a pixel art serrilhava e
## esticava os pixels. Devolve [mapa girado, onde o pivô cai nele]. Guardado por mapa e ângulo; as cores ficam com
## `art`, então um mapa girado serve para qualquer paleta.
static var _turns := {}
static var _bigs := {}
static func turned(rows: Array, angle: float, pivot: Vector2) -> Array:
	var key := hash([rows, snappedf(angle, 0.001), pivot])
	if _turns.has(key):
		return _turns[key]
	if _turns.size() > CACHE_MAX:
		_turns.clear()
	var w := (rows[0] as String).length()
	var h := rows.size()
	var big: PackedByteArray = _bigs.get(hash(rows), PackedByteArray())
	if big.is_empty():
		if _bigs.size() > CACHE_MAX:
			_bigs.clear()
		big = PackedByteArray()
		for y in h:
			big.append_array((rows[y] as String).to_ascii_buffer())
		for k in 3:
			big = _scale2x(big, w << k, h << k)
		_bigs[hash(rows)] = big
	var bw := w * 8
	var bh := h * 8
	var box := Rect2(-pivot, Vector2(w, h))
	var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	var lo := Vector2(INF, INF)
	var hi := -lo
	for c: Vector2 in corners:
		var r := c.rotated(angle)
		lo = lo.min(r)
		hi = hi.max(r)
	var o := Vector2i(floori(lo.x), floori(lo.y))
	var size := Vector2i(ceili(hi.x), ceili(hi.y)) - o
	var cs := cos(-angle)
	var sn := sin(-angle)
	var out := []
	for y in size.y:
		var line := PackedByteArray()
		line.resize(size.x)
		line.fill(46)   # "."
		var py := o.y + y + 0.5
		for x in size.x:
			var px := o.x + x + 0.5
			# o centro deste pixel, de volta ao mapa sem giro (e na escala do ampliado)
			var sx := floori(((px * cs - py * sn) + pivot.x) * 8.0)
			var sy := floori(((px * sn + py * cs) + pivot.y) * 8.0)
			if sx >= 0 and sy >= 0 and sx < bw and sy < bh:
				line[x] = big[sy * bw + sx]
		out.append(line.get_string_from_ascii())
	var res := [out, -Vector2(o)]
	_turns[key] = res
	return res


## O texto `text` na fonte do jogo (`Pal.mono`, lida em 11, onde cada pixel dela é um pixel) ampliado 2^`passes`
## vezes pelo Scale2x, recortado à tinta e em relevo (`relief`). Na fonte em 22 ou 44 cada pixel dela vira um bloco
## de 2 ou 4 px ao lado dos de 1 px da sala; aqui a diagonal sai em degrau de 1 px e a beira e o miolo pintados à
## parte dão o detalhe de 1 px. (O Scale3x, para 3×, inventava bicos nas letras de traço fino e saiu.) Guardado.
static var _texts := {}
static func big(text: String, passes: int) -> Array:
	var key := [text, passes]
	if _texts.has(key):
		return _texts[key]
	if _texts.size() > CACHE_MAX:
		_texts.clear()
	var ts := TextServerManager.get_primary_interface()
	var rid: RID = Pal.mono.get_rids()[0]
	var asc := int(Pal.mono.get_ascent(11))
	var h := asc + int(Pal.mono.get_descent(11))
	var glyphs := []   # [contornos, x]
	var w := 0.0
	for ch in text:
		var g := ts.font_get_glyph_index(rid, 11, ch.unicode_at(0), 0)
		var d: Dictionary = ts.font_get_glyph_contours(rid, 11, g)
		var polys := []
		var start := 0
		for end: int in d.get("contours", PackedInt32Array()):
			var p := PackedVector2Array()
			for i in range(start, end + 1):
				p.append(Vector2(d["points"][i].x, d["points"][i].y))
			polys.append(p)
			start = end + 1
		glyphs.append([polys, w])
		w += ts.font_get_glyph_advance(rid, 11, g).x
	var bw := int(w)
	var buf := PackedByteArray()
	buf.resize(bw * h)
	buf.fill(46)   # "."
	for e: Array in glyphs:   # o pixel é tinta se o meio dele fica dentro de um número ímpar de contornos
		for y in h:
			for x in range(maxi(0, int(e[1])), mini(bw, int(e[1]) + 11)):
				var inside := false
				for p: PackedVector2Array in e[0]:
					if Geometry2D.is_point_in_polygon(Vector2(x + 0.5 - e[1], y + 0.5 - asc), p):
						inside = not inside
				if inside:
					buf[y * bw + x] = 35   # "#"
	for i in passes:
		buf = _scale2x(buf, bw << i, h << i)
	bw <<= passes
	h <<= passes
	var ink := Rect2i()
	for y in h:
		for x in bw:
			if buf[y * bw + x] == 35:
				ink = Rect2i(x, y, 1, 1) if ink.size == Vector2i.ZERO else ink.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
	var rows := []
	for y in range(ink.position.y, ink.end.y):
		rows.append(buf.slice(y * bw + ink.position.x, y * bw + ink.end.x).get_string_from_ascii())
	_texts[key] = relief(rows)
	return _texts[key]


## O mapa `rows` ("#" é tinta) em relevo, como mapa de `art`: "u" na beira com vazio em cima ou à esquerda (a luz),
## "d" no resto da beira e "+" no miolo.
static func relief(rows: Array) -> Array:
	var h := rows.size()
	var w := (rows[0] as String).length()
	var ink := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and rows[y][x] == "#"
	var out := []
	for y in h:
		var line := ""
		for x in w:
			if not ink.call(x, y):
				line += "."
			elif not ink.call(x, y - 1) or not ink.call(x - 1, y) or not ink.call(x - 1, y - 1):
				line += "u"
			elif not (ink.call(x + 1, y) and ink.call(x, y + 1) and ink.call(x + 1, y + 1) and ink.call(x + 1, y - 1) and ink.call(x - 1, y + 1)):
				line += "d"
			else:
				line += "+"
		out.append(line)
	return out


## Scale2x (EPX) de um mapa de caracteres `w` × `h`, um byte por pixel: cada pixel vira quatro, e o canto que fica
## entre dois vizinhos iguais toma a cor deles (a diagonal sai em degrau de meio pixel, sem borrar).
static func _scale2x(src: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var dst := PackedByteArray()
	dst.resize(w * h * 4)
	var w2 := w * 2
	for y in h:
		for x in w:
			var p := src[y * w + x]
			var a := src[(y - 1) * w + x] if y > 0 else 46
			var b := src[y * w + x + 1] if x < w - 1 else 46
			var c := src[y * w + x - 1] if x > 0 else 46
			var d := src[(y + 1) * w + x] if y < h - 1 else 46
			var i := y * 2 * w2 + x * 2
			dst[i] = a if c == a and c != d and a != b else p
			dst[i + 1] = b if a == b and a != c and b != d else p
			dst[i + w2] = c if d == c and d != b and c != a else p
			dst[i + w2 + 1] = d if b == d and b != a and d != c else p
	return dst


## Desenha a peça `tex` em `ci`, centrada em `c`, presa aos pixels (na transformação que `ci` estiver usando).
static func sprite(ci: CanvasItem, tex: Texture2D, c: Vector2, mod := Color.WHITE) -> void:
	var sz := Vector2(tex.get_size())
	ci.draw_texture_rect(tex, Rect2((c - sz / 2.0).floor(), sz), false, mod)
