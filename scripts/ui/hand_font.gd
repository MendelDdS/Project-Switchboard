extends RefCounted
## A letra de mão (o diário, a carta, o recado e o parecer do supervisor, o `[hand]` do `paper_ink.gd`): uma fonte em
## pixel desenhada aqui, letra a letra, montada uma vez numa `FontFile` de bitmap (`font()`), nas medidas da Departure
## Mono no 11 (11 px acima da linha de base, 3 abaixo), para trocar uma pela outra sem mexer nas linhas. A única exceção
## à fonte única; o que ela não tem (símbolos raros) vem da Departure Mono (`fallbacks`). Só vale no tamanho 11.
##
## Cada letra: a altura da primeira fileira acima da linha de base (1 = a fileira que pousa nela) e as fileiras, `#` o
## pixel; as que passam do número descem abaixo da linha. Minúsculas com 5 de altura, hastes com 8, maiúsculas e
## números com 7, descidas com 3. Os acentos se montam por cima da letra (`ACCENTS`); o `i` acentuado perde o pingo.

const SIZE := 11
const ASCENT := 11
const DESCENT := 3
const SPACE := 3   ## o avanço do espaço
const GAP := 1   ## o espaço entre uma letra e a seguinte

const GLYPHS := {
	"a": [5, ".##..", "#..#.", "#..#.", "#..#.", ".##.#"],
	"b": [8, "#...", "#...", "#...", "###.", "#..#", "#..#", "#..#", "###."],
	"c": [5, ".##", "#..", "#..", "#..", ".##"],
	"d": [8, "...#.", "...#.", "...#.", ".###.", "#..#.", "#..#.", "#..#.", ".##.#"],
	"e": [5, ".##.", "#..#", "###.", "#...", ".###"],
	"f": [8, "..##", ".#..", ".#..", "###.", ".#..", ".#..", ".#..", ".#.."],
	"g": [5, ".###", "#..#", "#..#", "#..#", ".###", "...#", "#..#", ".##."],
	"h": [8, "#...", "#...", "#...", "###.", "#..#", "#..#", "#..#", "#..#"],
	"i": [7, "#.", "..", "#.", "#.", "#.", "#.", ".#"],
	"ı": [5, "#.", "#.", "#.", "#.", ".#"],
	"j": [7, "..#", "...", "..#", "..#", "..#", "..#", "..#", "#.#", ".#."],
	"k": [8, "#...", "#...", "#...", "#..#", "#.#.", "##..", "#.#.", "#..#"],
	"l": [8, "#.", "#.", "#.", "#.", "#.", "#.", "#.", ".#"],
	"m": [5, "##.#.", "#.#.#", "#.#.#", "#.#.#", "#.#.#"],
	"n": [5, "#.#.", "##.#", "#..#", "#..#", "#..#"],
	"o": [5, ".##.", "#..#", "#..#", "#..#", ".##."],
	"p": [5, "###.", "#..#", "#..#", "#..#", "###.", "#...", "#...", "#..."],
	"q": [5, ".###", "#..#", "#..#", "#..#", ".###", "...#", "...#", "...##"],
	"r": [5, "#.##", "##..", "#...", "#...", "#..."],
	"s": [5, ".###", "#...", ".##.", "...#", "###."],
	"t": [7, ".#..", ".#..", "####", ".#..", ".#..", ".#..", "..##"],
	"u": [5, "#..#.", "#..#.", "#..#.", "#..#.", ".##.#"],
	"v": [5, "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
	"w": [5, "#...#", "#...#", "#.#.#", "#.#.#", ".#.#."],
	"x": [5, "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
	"y": [5, "#..#", "#..#", "#..#", "#..#", ".###", "...#", "#..#", ".##."],
	"z": [5, "####", "...#", ".##.", "#...", "####"],
	"A": [7, "..#..", ".#.#.", ".#.#.", "#...#", "#####", "#...#", "#...#"],
	"B": [7, "###.", "#..#", "#..#", "###.", "#..#", "#..#", "###."],
	"C": [7, ".###", "#...", "#...", "#...", "#...", "#...", ".###"],
	"D": [7, "###.", "#..#", "#..#", "#..#", "#..#", "#..#", "###."],
	"E": [7, ".###", "#...", "#...", "###.", "#...", "#...", ".###"],
	"F": [7, "####", "#...", "#...", "###.", "#...", "#...", "#..."],
	"G": [7, ".###", "#...", "#...", "#.##", "#..#", "#..#", ".##."],
	"H": [7, "#..#", "#..#", "#..#", "####", "#..#", "#..#", "#..#"],
	"I": [7, "###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": [7, "..##", "...#", "...#", "...#", "...#", "#..#", ".##."],
	"K": [7, "#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": [7, "#...", "#...", "#...", "#...", "#...", "#...", ".###"],
	"M": [7, "#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": [7, "#...#", "##..#", "#.#.#", "#.#.#", "#..##", "#...#", "#...#"],
	"O": [7, ".##.", "#..#", "#..#", "#..#", "#..#", "#..#", ".##."],
	"P": [7, "###.", "#..#", "#..#", "###.", "#...", "#...", "#..."],
	"Q": [7, ".##.", "#..#", "#..#", "#..#", "#..#", "#..#", ".##.", "...#"],
	"R": [7, "###.", "#..#", "#..#", "###.", "#.#.", "#..#", "#..#"],
	"S": [7, ".###", "#...", "#...", ".##.", "...#", "...#", "###."],
	"T": [7, "#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": [7, "#..#", "#..#", "#..#", "#..#", "#..#", "#..#", ".##."],
	"V": [7, "#...#", "#...#", "#...#", ".#.#.", ".#.#.", ".#.#.", "..#.."],
	"W": [7, "#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": [7, "#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": [7, "#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": [7, "#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [7, ".##.", "#..#", "#..#", "#..#", "#..#", "#..#", ".##."],
	"1": [7, "..#", ".##", "#.#", "..#", "..#", "..#", "..#"],
	"2": [7, ".##.", "#..#", "...#", "..#.", ".#..", "#...", "####"],
	"3": [7, "###.", "...#", "...#", ".##.", "...#", "...#", "###."],
	"4": [7, "...#", "..##", ".#.#", "#..#", "####", "...#", "...#"],
	"5": [7, "####", "#...", "###.", "...#", "...#", "#..#", ".##."],
	"6": [7, ".##.", "#...", "#...", "###.", "#..#", "#..#", ".##."],
	"7": [7, "####", "...#", "..#.", "..#.", ".#..", ".#..", ".#.."],
	"8": [7, ".##.", "#..#", "#..#", ".##.", "#..#", "#..#", ".##."],
	"9": [7, ".##.", "#..#", "#..#", ".###", "...#", "...#", ".##."],
	".": [1, "#"],
	",": [1, ".#", "#."],
	";": [4, ".#", "..", "..", ".#", "#."],
	":": [4, "#", ".", ".", "#"],
	"·": [3, "#"],
	"!": [7, "#", "#", "#", "#", "#", ".", "#"],
	"?": [7, ".##.", "#..#", "...#", "..#.", ".#..", "....", ".#.."],
	"¡": [5, "#", ".", "#", "#", "#", "#", "#", "#"],
	"¿": [5, "..#.", "....", "..#.", ".#..", "#...", "#..#", ".##."],
	"'": [7, "#", "#"],
	"\"": [7, "#.#", "#.#"],
	"-": [3, "###"],
	"–": [3, "#####"],
	"_": [0, "####"],
	"(": [7, ".#", "#.", "#.", "#.", "#.", "#.", "#.", ".#"],
	")": [7, "#.", ".#", ".#", ".#", ".#", ".#", ".#", "#."],
	"[": [7, "##", "#.", "#.", "#.", "#.", "#.", "#.", "##"],
	"]": [7, "##", ".#", ".#", ".#", ".#", ".#", ".#", "##"],
	"/": [7, "...#", "..#.", "..#.", ".#..", ".#..", "#...", "#..."],
	"%": [7, "#...#", "#..#.", "...#.", "..#..", ".#...", ".#..#", "#...#"],
	"+": [4, ".#.", "###", ".#."],
	"&": [7, ".#..", "#.#.", "#.#.", ".#..", "#.##", "#.#.", ".#.#"],
	"º": [7, ".#.", "#.#", ".#.", "...", "###"],
}

## Os acentos: as fileiras deles, pousadas uma fileira acima do alto da letra.
const ACCENTS := {
	"acute": [".#", "#."],
	"grave": ["#.", ".#"],
	"circ": [".#.", "#.#"],
	"tilde": [".#.#", "#.#."],
	"dier": ["#.#"],
}

## As letras acentuadas: a letra de base e o acento (a cedilha é à parte, embaixo).
const COMPOSED := {
	"á": ["a", "acute"], "à": ["a", "grave"], "â": ["a", "circ"], "ã": ["a", "tilde"],
	"é": ["e", "acute"], "ê": ["e", "circ"], "í": ["ı", "acute"], "ó": ["o", "acute"], "ô": ["o", "circ"],
	"õ": ["o", "tilde"], "ú": ["u", "acute"], "ü": ["u", "dier"], "ñ": ["n", "tilde"], "ç": ["c", ""],
	"À": ["A", "grave"], "Á": ["A", "acute"], "Ã": ["A", "tilde"], "É": ["E", "acute"], "Ê": ["E", "circ"],
	"Í": ["I", "acute"], "Ó": ["O", "acute"], "Ô": ["O", "circ"], "Ú": ["U", "acute"], "Ñ": ["N", "tilde"],
	"Ç": ["C", ""],
}

static var _font: FontFile


## A fonte, montada na primeira vez: todas as letras numa imagem só, uma fileira de células de 14 px.
static func font() -> FontFile:
	if _font:
		return _font
	var glyphs := {}
	for k: String in GLYPHS:
		glyphs[k] = GLYPHS[k]
	for k: String in COMPOSED:
		glyphs[k] = _compose(COMPOSED[k][0], COMPOSED[k][1])
	var cell := ASCENT + DESCENT
	var x := 0
	var place := {}
	for k: String in glyphs:
		place[k] = x
		x += (glyphs[k][1] as String).length() + 1
	var img := Image.create_empty(x, cell, false, Image.FORMAT_LA8)
	for k: String in glyphs:
		var g: Array = glyphs[k]
		for r in g.size() - 1:
			var row: String = g[r + 1]
			for c in row.length():
				if row[c] == "#":
					img.set_pixel(place[k] + c, ASCENT - g[0] + r, Color.WHITE)
	var f := FontFile.new()
	f.fixed_size = SIZE
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.allow_system_fallback = false
	f.fallbacks = [load("res://fonts/DepartureMono-Regular.otf")]
	var sz := Vector2i(SIZE, 0)
	f.set_cache_ascent(0, SIZE, ASCENT)
	f.set_cache_descent(0, SIZE, DESCENT)
	f.set_texture_image(0, sz, 0, img)
	for k: String in glyphs:
		var w := (glyphs[k][1] as String).length()
		var ch := k.unicode_at(0)
		f.set_glyph_advance(0, SIZE, ch, Vector2(w + GAP, 0))
		f.set_glyph_offset(0, sz, ch, Vector2(0, -ASCENT))
		f.set_glyph_size(0, sz, ch, Vector2(w, cell))
		f.set_glyph_uv_rect(0, sz, ch, Rect2(place[k], 0, w, cell))
		f.set_glyph_texture_idx(0, sz, ch, 0)
	f.set_glyph_advance(0, SIZE, 32, Vector2(SPACE, 0))
	_font = f
	return f


## A letra `base` com o `accent` por cima (vazio: a cedilha embaixo), centrado nela.
static func _compose(base: String, accent: String) -> Array:
	var g: Array = GLYPHS[base].duplicate()
	var w := (g[1] as String).length()
	if accent == "":   # a cedilha: duas fileiras abaixo da linha, no meio da letra
		var mid := floori(w / 2.0)
		g.append(".".repeat(mid) + "#" + ".".repeat(w - mid - 1))
		g.append(".".repeat(maxi(0, mid - 1)) + "#" + ".".repeat(w - maxi(0, mid - 1) - 1))
		return g
	var a: Array = ACCENTS[accent]
	var aw := (a[0] as String).length()
	var left := ceili((w - aw) / 2.0)
	var rows := []
	for r: String in a:
		rows.append((".".repeat(left) + r + ".".repeat(w)).substr(0, w))
	rows.append(".".repeat(w))   # a fileira vazia entre o acento e a letra
	var out := [g[0] + rows.size()]
	out.append_array(rows)
	out.append_array(g.slice(1))
	return out
