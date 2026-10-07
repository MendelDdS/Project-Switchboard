class_name PixelArt
## Pixel art feita em código, guardada em texturas: mapas de texto (`art`), peças redondas (`disc`) e a fonte gravada
## do painel (`tiny`). Mesa comutadora, cenário, painel do operador e bloom desenham com elas. Cada textura fica
## guardada pela chave (o mapa e as cores; o diâmetro e as camadas; o texto) e o cache não esvazia: cor que muda a cada
## quadro vai no `modulate` do desenho, nunca nas cores daqui. `tools/sprite_sheet.gd` mostra tudo ampliado.

const LIGHT := Vector2(-0.7071, -0.7071)   # de onde vem a luz das peças redondas (alto à esquerda)
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
	".": ".../.../.../.../.#.", "-": ".../.../###/.../...", ":": ".../.#./.../.#./...", "/": "..#/..#/.#./#../#..",
	"(": ".#./#../#../#../.#.", ")": ".#./..#/..#/..#/.#."}
const TINY_MARKS := {"´": "..#/.#.", "`": "#../.#.", "^": ".#./#.#", "~": ".##/##.", "¨": "#.#/...", ",": ".#./##."}   ## acentos (2 linhas acima da letra; a cedilha, abaixo)
const TINY_ACCENTS := {"Á": "A´", "À": "A`", "Â": "A^", "Ã": "A~", "Ä": "A¨", "É": "E´", "È": "E`", "Ê": "E^", "Ë": "E¨",
	"Í": "I´", "Ì": "I`", "Î": "I^", "Ï": "I¨", "Ó": "O´", "Ò": "O`", "Ô": "O^", "Õ": "O~", "Ö": "O¨", "Ú": "U´", "Ù": "U`",
	"Û": "U^", "Ü": "U¨", "Ñ": "N~", "Ç": "C,"}


## O texto `text` na fonte do painel (`TINY`), em maiúsculas, branco (a cor vem na hora de desenhar): 4 px por letra
## e 10 de altura (os acentos nas linhas 0 e 1, as letras de 3 a 7, a cedilha em 8 e 9). Guardado.
static var _tinies := {}
static func tiny(text: String) -> ImageTexture:
	text = text.to_upper()
	if not _tinies.has(text):
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
## `layers` de dentro para fora, [raio em pixels, cor] ou [raio, luz, meio, sombra] (a luz vem de `LIGHT`) ou
## [raio, luz, meio, sombra, true] (côncava: a luz bate do lado oposto, como no fundo de um furo). Guardada. Toda peça
## redonda do jogo sai daqui (o mesmo acabamento em todas).
static var _discs := {}
static func disc(d: int, layers: Array) -> ImageTexture:
	var key := str(d, layers)
	if _discs.has(key):
		return _discs[key]
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var mid := Vector2(d, d) / 2.0
	for y in d:
		for x in d:
			var o := Vector2(x + 0.5, y + 0.5) - mid
			for l in layers:
				if o.length() <= l[0]:
					var col: Color = l[1]
					if l.size() >= 4:
						var t := o.normalized().dot(LIGHT) if o.length() > 0.01 else 0.0
						if l.size() >= 5 and l[4]:
							t = -t
						col = l[1] if t > 0.38 else (l[3] if t < -0.38 else l[2])
					img.set_pixel(x, y, col)
					break
	var tex := ImageTexture.create_from_image(img)
	_discs[key] = tex
	return tex


## Desenha a peça `tex` em `ci`, centrada em `c`, presa aos pixels (na transformação que `ci` estiver usando).
static func sprite(ci: CanvasItem, tex: Texture2D, c: Vector2, mod := Color.WHITE) -> void:
	var sz := Vector2(tex.get_size())
	ci.draw_texture_rect(tex, Rect2((c - sz / 2.0).floor(), sz), false, mod)
