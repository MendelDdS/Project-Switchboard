class_name NewsView
extends VBoxContainer
## O jornal da manhã, aberto pelo jornal dobrado na mesa (da segunda noite em diante): o nome do jornal, a edição e
## uma manchete por emergência da noite anterior (`ShiftReport.news`, as mesmas do relatório), a primeira em destaque;
## noite sem emergência, "noite tranquila". As consequências das escolhas ficam na sala, não só na tela final.
## A página é a do jornal da mesa (`Background._art_newspaper`), de perto: o papel-jornal, o fio duplo embaixo do nome,
## a letra miúda das colunas (só a mancha das linhas, `_greek`) e a foto da cidade em retícula (`_photo`). Cada noite
## pode trazer a sua foto, a legenda e as matérias das colunas (`Night.news_*`); o que ela não trouxer sai como sempre.

const PHOTO_H := 132   ## a altura da foto (a largura é a da coluna dela)
const ROW := 5         ## de quantos em quantos px vem uma linha da letra miúda
## O pontilhado ordenado da retícula da foto (4 × 4).
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var _news: Array = []
var _night: Night
var _stories := PackedStringArray()   ## as matérias desta noite, com os marcadores de quando o jornal chegou (`Night.stories_for`)
var _n := 0   # o número da noite: a data da edição

static var _photos := {}   # tamanho -> a foto


func _ready() -> void:
	$Rule.draw.connect(_draw_rule)
	$Page/Text/Columns.draw.connect(_draw_columns)
	$Page/Photo.draw.connect(_draw_photo)


func show_news(news: Array, night: Night, n: int, flags: StoryFlags = null) -> void:
	_news = news
	_night = night
	_stories = night.stories_for(flags) if night else PackedStringArray()
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
	$Page/Text/Lead.text = T.text(T.Key.REPORT_QUIET) if _news.is_empty() else ShiftReport.headline(_news[0])
	var s := ""
	for i in range(1, _news.size()):
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


## Embaixo das manchetes, duas colunas (as duas primeiras matérias da noite) com o fio entre elas.
func _draw_columns() -> void:
	var c: Control = $Page/Text/Columns
	var w := floorf((c.size.x - 15.0) / 2.0)
	_column(c, Rect2(0, 0, w, c.size.y), _story(0), 0)
	c.draw_rect(Rect2(w + 7, 0, 1, c.size.y), Color(Pal.NEWS_INK, 0.5))
	_column(c, Rect2(w + 15, 0, w, c.size.y), _story(1), 5)


## A foto (a da noite, ou a cidade desenhada), a legenda e a coluna seguindo embaixo dela (a terceira matéria).
func _draw_photo() -> void:
	var c: Control = $Page/Photo
	if c.size.x < 8.0:   # (a página ainda sem tamanho)
		return
	var box := Rect2(0, 0, c.size.x, PHOTO_H)
	var pic: Texture2D = _night.news_photo if _night else null
	if pic:   # ajustada à caixa sem deformar, no alto dela, na moldura escura
		var k := minf(box.size.x / pic.get_width(), box.size.y / pic.get_height())
		box = Rect2(Vector2(floorf((box.size.x - pic.get_width() * k) / 2.0), 0), (pic.get_size() * k).floor())
		c.draw_texture_rect(pic, box, false)
		c.draw_rect(box, Pal.NEWS_PHOTO[0], false, 1.0)
	else:
		c.draw_texture(_photo(Vector2i(int(box.size.x), PHOTO_H)), Vector2.ZERO)
	var y := box.end.y + 4.0
	var caption := tr(_night.news_caption) if _night and _night.news_caption != "" else ""
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


## A foto da primeira página, pixel a pixel e guardada por tamanho: a cidade de manhã (o céu clareando para o
## horizonte, os morros, os telhados com as janelas e a torre da igreja com o relógio) em retícula de jornal, a tinta
## sobre o papel em pontilhado ordenado, na moldura escura da foto do jornal da mesa.
static func _photo(sz: Vector2i) -> ImageTexture:
	if _photos.has(sz):
		return _photos[sz]
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var ink := Pal.NEWS_PHOTO[0]
	var hz := int(sz.y * 0.66)   # a rua
	var church := int(sz.x * 0.64)
	for y in sz.y:
		for x in sz.x:
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
			img.set_pixel(x, y, ink if t * 16.0 > BAYER[(y % 4) * 4 + x % 4] + 0.5 else Pal.NEWSPRINT)
	for p in [Rect2i(0, 0, sz.x, 1), Rect2i(0, sz.y - 1, sz.x, 1), Rect2i(0, 0, 1, sz.y), Rect2i(sz.x - 1, 0, 1, sz.y)]:
		img.fill_rect(p, ink)
	_photos[sz] = ImageTexture.create_from_image(img)
	return _photos[sz]
