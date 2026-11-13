class_name NewsView
extends VBoxContainer
## O jornal da manhã, aberto pelo jornal pregado no quadro de avisos (da segunda noite em diante): o nome do jornal, a edição e
## a manchete do dia (o título da primeira matéria da noite, `Night.stories_for`: o acontecimento grande, do jogador
## ou da cidade) e, embaixo, uma por emergência da noite anterior (`ShiftReport.news`, as mesmas do relatório); noite
## sem matéria, a primeira emergência em destaque, e sem nenhuma das duas, "noite tranquila". As consequências das escolhas ficam na sala, não só na tela final.
## A página é a do jornal pregado no quadro de avisos (`Background._draw_pinned_news`), de perto: o papel-jornal, o fio duplo embaixo do nome,
## a letra miúda das colunas (só a mancha das linhas, `_greek`) e a foto em retícula (`_photo`), a da manchete
## (`Night.photo_for`: a cidade, a rua, a viatura...). Cada noite pode trazer a sua foto, a legenda e as matérias das
## colunas (`Night.news_*`); o que ela não trouxer sai como sempre.

const PHOTO_H := 132   ## a altura da foto (a largura é a da coluna dela)
const ROW := 5         ## de quantos em quantos px vem uma linha da letra miúda
## O pontilhado ordenado da retícula da foto (4 × 4).
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
## As fotos da primeira página (`Night.news_photo`, `StoryText.photo`; vazio, a cidade), desenhadas em `_tone`.
const PHOTOS := ["cidade", "rua", "viatura", "armas", "torre", "hotel", "mulher", "papeis"]
## O letreiro da foto do hotel, 3 × 5 por letra e uma coluna entre elas.
const HOTEL := ["1010111011101110100", "1010101001001000100", "1110101001001100100", "1010101001001000100", "1010111001001110111"]

var _news: Array = []
var _night: Night
var _stories := PackedStringArray()   ## as matérias desta noite, com os marcadores de quando o jornal chegou (`Night.stories_for`)
var _pic := PackedStringArray(["", ""])   ## a foto e a legenda da manchete (`Night.photo_for`)
var _n := 0   # o número da noite: a data da edição

static var _photos := {}   # "tamanho foto" -> a foto (no máximo uma por foto de `PHOTOS`: o tamanho é o da coluna)


func _ready() -> void:
	$Rule.draw.connect(_draw_rule)
	$Page/Text/Columns.draw.connect(_draw_columns)
	$Page/Photo.draw.connect(_draw_photo)


func show_news(news: Array, night: Night, n: int, flags: StoryFlags = null) -> void:
	_news = news
	_night = night
	_stories = night.stories_for(flags) if night else PackedStringArray()
	_pic = night.photo_for(flags) if night else PackedStringArray(["", ""])
	_n = n
	_render()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_render()


func _render() -> void:
	if _night == null:   # (ainda sem jornal: só da segunda noite em diante)
		return
	# o nome do jornal, a fonte ampliada 2× em letra vazada (`PixelArt.big`: na fonte em 22, os pixels dela viravam blocos de 2 px; 4× não cabe na página em 960 × 540)
	$Masthead.texture = PixelArt.art(PixelArt.big(T.text(T.Key.NEWS_MASTHEAD), 1), {"u": Pal.INK, "d": Pal.INK, "+": Pal.NEWS_INK})
	$Edition.text = T.text(T.Key.NEWS_EDITION) % GameData.date_text(_n)
	# a primeira em 11 e em negrito (`InkBoldLabel`, a sombra 1 px ao lado): em 22, os pixels da fonte viravam blocos de 2 px
	var lead := _story(0).get_slice("\n", 0)
	var first := 0 if lead != "" else 1   # sem matéria, a primeira emergência é a manchete
	if lead == "":
		lead = T.text(T.Key.REPORT_QUIET) if _news.is_empty() else ShiftReport.headline(_news[0])
	$Page/Text/Lead.text = lead
	var s := ""
	for i in range(first, _news.size()):
		s += "• %s\n\n" % ShiftReport.headline(_news[i]).replace("[", "(")
	$Page/Text/Headlines.text = s.strip_edges()
	$Page/Text/Headlines.visible = not s.is_empty()
	$Page/Text/Columns.queue_redraw()
	$Page/Photo.queue_redraw()


## O fio embaixo do nome do jornal: um grosso e, logo abaixo, um fino.
func _draw_rule() -> void:
	var r: Control = $Rule
	r.draw_rect(Rect2(0, 0, r.size.x, 3), Pal.INK)
	r.draw_rect(Rect2(0, 5, r.size.x, 1), Pal.INK)


## Embaixo das manchetes, duas colunas (o texto da matéria da manchete e a segunda matéria) com o fio entre elas.
func _draw_columns() -> void:
	var c: Control = $Page/Text/Columns
	var w := floorf((c.size.x - 15.0) / 2.0)
	_column(c, Rect2(0, 0, w, c.size.y), "\n" + _story(0).get_slice("\n", 1), 0)   # a da manchete: só o texto
	c.draw_rect(Rect2(w + 7, 0, 1, c.size.y), Color(Pal.NEWS_INK, 0.5))
	_column(c, Rect2(w + 15, 0, w, c.size.y), _story(1), 5)


## A foto da manchete, a legenda e a coluna seguindo embaixo dela (a terceira matéria).
func _draw_photo() -> void:
	var c: Control = $Page/Photo
	if c.size.x < 8.0:   # (a página ainda sem tamanho)
		return
	c.draw_texture(_photo(Vector2i(int(c.size.x), PHOTO_H), _pic[0]), Vector2.ZERO)
	var y := PHOTO_H + 4.0
	var caption := tr(_pic[1]) if _pic[1] != "" else ""
	if caption == "":
		c.draw_rect(Rect2(0, y, floorf(c.size.x * 0.6), 2), Pal.INK_SOFT)
		y += 10.0
	else:
		y += _text(c, Vector2(0, y), caption, c.size.x, Pal.INK_SOFT) + 6.0
	_column(c, Rect2(0, y, c.size.x, c.size.y - y), _story(2), 11)


## A matéria `i` da noite (traduzida), ou vazio.
func _story(i: int) -> String:
	return tr(_stories[i]) if i < _stories.size() else ""


## Uma coluna em `r`: a matéria no alto (`story`: a primeira linha é o título, em tinta; o texto, mais apagado) e,
## no que sobrar, a letra miúda.
func _column(ci: CanvasItem, r: Rect2, story: String, seed: int) -> void:
	var y := r.position.y
	if story != "":
		var parts := story.split("\n", true, 1)
		if parts[0] != "":
			y += _text(ci, Vector2(r.position.x, y), parts[0], r.size.x, Pal.INK) + 4.0
		if parts.size() > 1:
			y += _text(ci, Vector2(r.position.x, y), parts[1].strip_edges(), r.size.x, Pal.INK_SOFT) + 8.0
	_greek(ci, Rect2(r.position.x, y, r.size.x, r.end.y - y), seed)


## Texto quebrado na largura `w` a partir de `at` (o alto dele); devolve a altura que ocupou.
static func _text(ci: CanvasItem, at: Vector2, txt: String, w: float, col: Color) -> float:
	ci.draw_multiline_string(Pal.ui, at + Vector2(0, Pal.ui.get_ascent(11)), txt, HORIZONTAL_ALIGNMENT_LEFT, w, 11, -1, col)
	return Pal.ui.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, w, 11).y


## A mancha da letra miúda em `r`: linhas de palavras de 2 px a cada `ROW` px, sempre as mesmas (pela posição e por
## `seed`), com o recuo e a linha curta de cada parágrafo.
static func _greek(ci: CanvasItem, r: Rect2, seed: int) -> void:
	var line := seed
	var y := r.position.y + 1.0
	while y + 2.0 <= r.end.y:
		line += 1
		var x := r.position.x + (8.0 if line % 9 == 1 else 0.0)
		var end := r.end.x if line % 9 != 0 else r.position.x + floorf(r.size.x * 0.55)
		while x < end - 2.0:
			var w := minf(3.0 + float((line * 7 + int(x) * 13) % 9), end - x)
			ci.draw_rect(Rect2(x, y, w, 2), Pal.NEWS_INK)
			x += w + 3.0
		y += ROW


## A foto da primeira página (`kind`, uma de `PHOTOS`), pixel a pixel e guardada: o tom de cada pixel (`_tone`) em
## retícula de jornal, a tinta sobre o papel em pontilhado ordenado, na moldura escura da foto do jornal da mesa.
static func _photo(sz: Vector2i, kind: String) -> ImageTexture:
	var key := "%s %s" % [sz, kind]
	if _photos.has(key):
		return _photos[key]
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var ink := Pal.NEWS_PHOTO[0]
	for y in sz.y:
		for x in sz.x:
			var t := _tone(kind, x, y, sz)
			img.set_pixel(x, y, ink if t * 16.0 > BAYER[(y % 4) * 4 + x % 4] + 0.5 else Pal.NEWSPRINT)
	for p in [Rect2i(0, 0, sz.x, 1), Rect2i(0, sz.y - 1, sz.x, 1), Rect2i(0, 0, 1, sz.y), Rect2i(sz.x - 1, 0, 1, sz.y)]:
		img.fill_rect(p, ink)
	_photos[key] = ImageTexture.create_from_image(img)
	return _photos[key]


## O tom (0 o papel, 1 a tinta cheia) do pixel `x`, `y` da foto `kind` em `sz`. A cidade se ajusta ao tamanho; as
## outras são desenhadas em 150 × 132 (o tamanho da coluna da foto) e esticadas a ele.
static func _tone(kind: String, x: int, y: int, sz: Vector2i) -> float:
	var p := Vector2(x * 150.0 / sz.x, y * 132.0 / sz.y)
	match kind:
		"rua":   # a rua vazia de noite: o poste aceso com os fios do telefone, as janelas quase todas apagadas
			var t := 0.55 + 0.15 * p.y / 92.0   # o céu (cheio de tinta, os fios sumiam nele)
			var b := int(p.x) / 22   # os prédios do fundo, cada um na sua altura
			var top := 50 + b * 7 % 4 * 5
			if p.y >= top:
				t = 0.94
				if int(p.x) % 22 in [6, 7, 8, 9, 14, 15, 16, 17] and int(p.y - top) % 12 in [3, 4, 5, 6, 7]:
					t = 0.0 if (b + int(p.x) % 22 / 12 + int(p.y - top) / 12) % 3 == 1 else 1.0   # uma janela acesa aqui e ali
			if p.x < 26.0 and p.y >= 8.0 or p.x > 128.0 and p.y >= 22.0:   # as fachadas de perto, sem luz
				t = 0.88 if fmod(p.y, 16.0) > 2.0 else 1.0
			if p.y >= 92.0:   # a rua
				t = 0.75
			var cone := (p.y - 36.0) * 0.4   # a luz do poste, no ar (mais fraca para a beira) e no chão
			if p.y > 36.0 and p.y < 92.0 and absf(p.x - 106.0) < cone:
				t *= 0.8 + 0.2 * absf(p.x - 106.0) / cone
			if Vector2((p.x - 106.0) / 22.0, (p.y - 104.0) / 6.0).length() < 1.0:
				t = 0.3
			for w in [[22.0, 9.0], [27.0, 7.0]]:   # os fios, de ponta a ponta passando pelo alto do poste, caídos no meio
				var a := 96.0 if p.x > 96.0 else 0.0
				var u := (p.x - a) / (150.0 - 96.0 if a > 0.0 else 96.0)
				var wy: float = lerpf(w[0] if a == 0.0 else 31.0, 31.0 if a == 0.0 else w[0] + 4.0, u) + w[1] * sin(PI * u)
				if absf(p.y - wy) < 0.6:
					t = 1.0
			if absf(p.x - 95.5) < 1.0 and p.y >= 30.0 and p.y < 102.0 or p.y >= 30.0 and p.y < 32.0 and p.x >= 95.0 and p.x < 107.0:
				t = 1.0   # o poste e o braço
			if absf(p.x - 97.0) < 0.5 and p.y >= 36.0 and p.y < 102.0:
				t = 0.3   # a beira do poste do lado da lâmpada, para ele não sumir na frente dos prédios
			if p.x >= 102.0 and p.x < 110.0 and p.y >= 32.0 and p.y < 36.0:
				t = 0.0   # a lâmpada
			return t
		"viatura":   # a viatura parada de dia na frente de um muro, e o cavalete da barreira listrado
			var t := 0.18 if p.y < 40.0 else 0.45
			if p.y >= 40.0 and p.y < 42.0:
				t = 0.8   # a beira do muro
			if p.x >= 18.0 and p.x < 34.0 and p.y >= 56.0 and p.y < 96.0:
				t = 0.85   # um portão
			if p.y >= 96.0:
				t = 0.55
			if p.y >= 100.0 and p.y < 104.0 and p.x >= 48.0 and p.x < 132.0:
				t = 0.9   # a sombra embaixo
			var cab := p.y >= 58.0 and p.y < 74.0 and p.x >= 66.0 + (74.0 - p.y) * 0.5 and p.x < 116.0 - (74.0 - p.y) * 0.7
			if cab or p.y >= 74.0 and p.y < 100.0 and p.x >= 50.0 and p.x < 132.0 and not (p.y < 78.0 and p.x >= 126.0):
				t = 0.85   # a cabine e a carroceria (o capô mais baixo)
				if cab and p.y >= 62.0 and p.y < 72.0 and (p.x >= 74.0 and p.x < 89.0 or p.x >= 93.0 and p.x < 106.0):
					t = 0.3   # os vidros
				if p.y >= 84.0 and p.y < 88.0:
					t = 0.12   # a faixa da polícia
				if p.x >= 129.0 and p.y >= 80.0 and p.y < 84.0:
					t = 0.0   # o farol
			if p.x >= 86.0 and p.x < 93.0 and p.y >= 52.0 and p.y < 58.0:
				t = 0.1   # a sirene
			for wx in [66.0, 114.0]:
				var d := p.distance_to(Vector2(wx, 100.0))
				if d < 8.5:
					t = 1.0 if d > 3.0 else 0.4   # as rodas
			if p.x >= 4.0 and p.x < 44.0 and p.y >= 82.0 and p.y < 90.0:
				t = 0.95 if int(p.x + p.y) / 6 % 2 == 0 else 0.08   # a tábua listrada do cavalete
			if (absf(p.x - 9.0) < 1.0 or absf(p.x - 39.0) < 1.0) and p.y >= 90.0 and p.y < 110.0:
				t = 1.0
			return t
		"armas":   # caixotes empilhados em cima de uma mesa e dois fuzis encostados
			var t := 0.44 + 0.18 * (1.0 - p.x / 150.0)
			if p.y >= 86.0:
				t = 0.85 if p.y < 92.0 else 0.7   # o tampo e a frente da mesa
			for r: Rect2 in [Rect2(14, 40, 60, 46), Rect2(78, 52, 50, 34), Rect2(22, 12, 44, 28)]:
				if r.has_point(p):
					var q := p - r.position
					t = 0.32 if int(q.y) % 9 != 0 else 0.7   # as tábuas
					if q.x < 2.0 or q.y < 2.0 or q.x >= r.size.x - 2.0 or q.y >= r.size.y - 2.0:
						t = 0.9
					if absf(q.x - r.size.x / 2.0) < 7.0 and absf(q.y - r.size.y / 2.0) < 3.0:
						t = 0.85   # a marca pintada
			for g in [[Vector2(134, 86), Vector2(126, 24)], [Vector2(143, 86), Vector2(139, 20)]]:
				var a: Vector2 = g[0]
				var u := clampf((p - a).dot(g[1] - a) / a.distance_squared_to(g[1]), 0.0, 1.0)
				if p.distance_to(a.lerp(g[1], u)) < (3.2 if u < 0.25 else 1.6):
					t = 1.0   # o fuzil, com a coronha mais grossa embaixo
			return t
		"torre":   # a torre da emissora em treliça contra o céu, a casa do transmissor embaixo
			var t := 0.1 + 0.2 * p.y / 132.0
			if p.y > 104.0 - 5.0 * sin(p.x * 0.05):
				t = 0.4   # os morros
			if p.y >= 118.0:
				t = 0.62
			var hw := 2.0 + 24.0 * (p.y - 8.0) / 102.0
			if p.y >= 8.0 and p.y < 110.0:
				var seg := floorf((p.y - 8.0) / 12.75)
				var u := (p.y - 8.0 - seg * 12.75) / 12.75
				var l0 := 75.0 - hw
				var dx := absf(p.x - 75.0)
				if absf(dx - hw) < 1.0 or u < 0.08 and dx <= hw:
					t = 1.0   # as pernas e as travessas
				if dx <= hw and (absf(p.x - (l0 + u * 2.0 * hw)) < 0.7 or absf(p.x - (75.0 + hw - u * 2.0 * hw)) < 0.7):
					t = 1.0   # o xis de cada lance
			if absf(p.x - 74.5) < 1.0 and p.y < 8.0:
				t = 1.0   # a antena
			if p.x >= 22.0 and p.x < 56.0 and p.y >= 98.0 and p.y < 120.0:
				t = 0.75 if not (int(p.x) % 10 in [4, 5, 6] and p.y >= 104.0 and p.y < 110.0) else 0.25
			return t
		"hotel":   # a fachada do hotel: as venezianas fechadas, o letreiro e a porta com as tiras do lacre em xis
			var t := 0.4
			if p.y < 6.0 or p.y >= 68.0 and p.y < 72.0:
				t = 0.8   # a cornija e a marquise
			for i in 4:
				for top in [14.0, 42.0]:
					var q := p - Vector2(12.0 + i * 34.0, top)
					if q.x >= 0.0 and q.x < 22.0 and q.y >= 0.0 and q.y < 22.0:
						t = 0.88 if int(q.y) % 3 != 0 else 0.55   # as venezianas
			if p.x >= 46.0 and p.x < 104.0 and p.y >= 76.0 and p.y < 90.0:
				t = 0.92   # o letreiro, com as letras claras de 2 px
				var lx := int(p.x - 56.0) / 2
				var ly := int(p.y - 78.0) / 2
				if p.x >= 56.0 and lx < 19 and ly >= 0 and ly < 5 and HOTEL[ly][lx] == "1":
					t = 0.05
			if p.x >= 56.0 and p.x < 94.0 and p.y >= 94.0 and p.y < 126.0:
				t = 0.9   # a porta
				var q := Vector2((p.x - 56.0) / 38.0, (p.y - 94.0) / 32.0)
				if absf(q.x - q.y) < 0.09 or absf(1.0 - q.x - q.y) < 0.09:
					t = 0.04   # o lacre
			if p.y >= 126.0:
				t = 0.6
			return t
		"mulher":   # o retrato de uma mulher sorrindo: o cabelo curto repartido de lado, a blusa de decote em vê
			var t := 0.3 + 0.2 * p.x / 150.0
			var hair := Vector2((p.x - 75.0) / 27.0, (p.y - 48.0) / 31.0).length() < 1.0 \
					or p.y >= 48.0 and p.y < 80.0 + 2.0 * sin(p.x * 0.3) and absf(p.x - 75.0) < 27.0 - (p.y - 48.0) * 0.25
			if hair:
				t = 0.85
			if absf(p.x - 75.0) < 7.0 and p.y >= 74.0:
				t = 0.22   # o pescoço
			if p.y >= 90.0 and absf(p.x - 75.0) < 22.0 + (p.y - 90.0) * 1.6 and absf(p.x - 75.0) >= 7.0 - (p.y - 90.0) * 0.5:
				t = 0.65   # os ombros, com o decote
			if Vector2((p.x - 75.0) / 19.0, (p.y - 55.0) / 24.0).length() < 1.0 and p.y > 37.0 + (p.x - 75.0) * 0.2:
				t = 0.1   # o rosto, a franja descendo para um lado
				for ex in [67.0, 83.0]:   # os olhos apertados do sorriso
					if absf(p.x - ex) < 3.0 and absf(p.y - (52.0 + absf(p.x - ex) * 0.4)) < 0.6:
						t = 1.0
				if absf(p.x - 75.0) < 1.0 and p.y >= 57.0 and p.y < 61.0:
					t = 0.45   # a sombra do nariz
				if absf(p.x - 75.0) <= 6.5 and absf(p.y - (66.0 - pow(p.x - 75.0, 2.0) / 16.0)) < 0.7:
					t = 1.0   # a boca
			return t
		"papeis":   # o muro com os cartazes colados e os panfletos espalhados pela plataforma
			var t := 0.58 if int(p.y) % 6 != 0 and int(p.x + int(p.y) / 6 % 2 * 7) % 14 != 0 else 0.82   # os tijolos
			if p.y >= 70.0:
				t = 0.9 if p.y < 74.0 else 0.5   # a beira e o chão da plataforma
			for r: Rect2 in [Rect2(14, 10, 34, 46), Rect2(60, 14, 30, 40), Rect2(102, 8, 36, 48)]:
				if r.has_point(p) and not (p.x > r.end.x - 7.0 and p.y > r.end.y - 7.0 + (r.end.x - p.x)):
					var q := p - r.position
					t = 0.08   # o cartaz (um canto rasgado)
					if q.x >= 4.0 and q.x < r.size.x - 4.0 and (q.y >= 4.0 and q.y < 12.0 or int(q.y) % 4 == 2 and q.y >= 16.0):
						t = 0.9 if q.y < 12.0 else 0.55   # o título e as linhas
			for f in [[30, 96, 22, 16, 0.3], [70, 112, 20, 15, -0.5], [112, 92, 22, 16, 0.9], [50, 124, 18, 13, 1.3], [128, 118, 20, 14, -0.2], [90, 84, 16, 11, 0.1]]:
				var q: Vector2 = (p - Vector2(f[0], f[1])).rotated(-f[4])
				if absf(q.x) < f[2] / 2.0 and absf(q.y) < f[3] / 2.0:
					t = 0.6 if absf(q.x) < f[2] / 2.0 - 3.0 and int(q.y + f[3] / 2.0) % 3 == 1 else 0.04
			return t
	# a cidade de manhã: o céu clareando para o horizonte, os morros, os telhados com as janelas e a torre da igreja
	var hz := int(sz.y * 0.66)   # a rua
	var church := int(sz.x * 0.64)
	var t := 0.32 - 0.16 * float(y) / hz   # o céu
	if y > hz - 26 - int(6.0 * sin(x * 0.045)):   # os morros
		t = 0.45
	var b := x / 18   # os telhados: cada casa na sua altura, com a cumeeira no meio
	var roof := hz - 16 - (b * 37 % 5) * 5 - (9 - absi(x % 18 - 9)) / 2
	if y >= roof:
		t = 0.72
		var wx := x % 18
		if (wx in [4, 5, 12, 13]) and (y - roof) % 10 in [5, 6, 7] and y < hz - 3:
			t = 0.95
	if absi(x - church) <= 6 and y >= hz - 62 or absi(x - church) <= (y - (hz - 86)) / 4 and y >= hz - 86 and y < hz - 62:
		t = 0.85   # a torre e a ponta dela
		if Vector2(x - church, y - (hz - 52)).length() < 3.5:
			t = 0.15   # o relógio
	if y >= hz:   # a rua, clareando no meio
		t = 0.6 - 0.2 * (1.0 - absf(x - sz.x / 2.0) / (sz.x / 2.0)) * float(y - hz) / (sz.y - hz)
	return t
