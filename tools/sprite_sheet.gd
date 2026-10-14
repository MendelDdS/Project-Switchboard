extends SceneTree
## Folha de prévia da pixel art feita em código: tudo ampliado `SCALE` vezes num PNG, para ver cada peça isolada
## enquanto mexe nela. Rode e abra build/sprites.png:
##   Godot --headless --path . -s tools/sprite_sheet.gd
## Primeiro os mapas de texto, com nome (buraco, tomadas, plugs, algarismos do relógio, a fonte do painel); depois
## tudo o que a mesa e o cenário montaram nos primeiros quadros da noite 1, como está na tela: os mapas nas cores do
## jogo (sombras e luzes também), as peças redondas, os objetos da mesa já na perspectiva e a caneca.

const OUT := "res://build/sprites.png"
const SCALE := 8
const WIDTH := 240   # largura de cada fileira, antes de ampliar (px)
const GAP := 4
const BG := Color("4a4640")

var _items: Array = []   # [Image, posição]
var _at := Vector2i.ZERO
var _row_h := 0
var _size := Vector2i.ZERO
var _seen := {}   # o que já entrou na folha (os mapas com nome não se repetem nos do jogo)


func _initialize() -> void:
	var m: Node = load("res://scenes/main.tscn").instantiate()
	m.night_no = 1   # não lê nem grava o progresso salvo
	root.add_child(m)
	# carregadas aqui, não pelo nome: com -s, este script compila antes dos autoloads que elas usam (Sfx...)
	var S: GDScript = load("res://scripts/ui/switchboard.gd")
	var B: GDScript = load("res://scripts/ui/background.gd")
	for i in 30:   # a tela se arruma...
		await process_frame
	for cache: Dictionary in [PixelArt._arts, PixelArt._discs, B._projected, B._mugs]:
		cache.clear()   # ...e o que foi montado enquanto ela se arrumava sai (objetos no tamanho errado)
	for n in m.find_children("*", "CanvasItem", true, false):
		n.queue_redraw()
	for i in 5:
		await process_frame
	var sb: Node = m.find_children("*", "Switchboard", true, false)[0]

	_section("MESA")
	_add(PixelArt.art(S.HOLE_ART, S.HOLE_PAL), "BURACO")
	_add(sb._jack_tex(0.0), "ENTRADA")
	_add(sb._jack_tex(0.25), "SAÍDA")
	for i in S.CORD_COLORS.size():
		_add(PixelArt.art(S.PLUG_ART, sb._plug_pal(S.CORD_COLORS[i])), "FONE" if i == 0 else "CABO %d" % i)
	_section("RELÓGIO")
	_add(PixelArt.art(B.DIGITS, {"#": Color.WHITE}), "ALGARISMOS")
	_section("FONTE DO PAINEL")
	_add(PixelArt.tiny("".join(PixelArt.TINY.keys())))
	_add(PixelArt.tiny("".join(PixelArt.TINY_ACCENTS.keys())))
	_section("MAPAS NAS CORES DO JOGO")
	_all(PixelArt._arts.values())
	_section("PEÇAS REDONDAS")
	_all(PixelArt._discs.values())
	_section("OBJETOS DA MESA")
	_all(B._projected.values())
	_all(B._mugs.values())

	var sheet := Image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(BG)
	for it: Array in _items:
		var img: Image = it[0]
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), it[1])
	sheet.resize(_size.x * SCALE, _size.y * SCALE, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	FileAccess.open(OUT.get_base_dir() + "/.gdignore", FileAccess.WRITE)   # o editor não importa o que fica em build/
	sheet.save_png(ProjectSettings.globalize_path(OUT))
	print("%s (%d × %d)" % [ProjectSettings.globalize_path(OUT), sheet.get_width(), sheet.get_height()])
	quit()


## Começa uma fileira nova com o título `title`.
func _section(title: String) -> void:
	if _at.x > 0:
		_at = Vector2i(0, _at.y + _row_h + GAP)
	_row_h = 0
	if _at.y > 0:
		_at.y += GAP * 2
	_add(PixelArt.tiny(title))
	_at = Vector2i(0, _at.y + _row_h + GAP)
	_row_h = 0


## Uma peça (textura ou imagem) na fileira, com o nome embaixo; não cabendo, passa para a fileira de baixo.
func _add(what: Variant, label := "") -> void:
	_seen[what] = true
	var img: Image = (what as Texture2D).get_image() if what is Texture2D else (what as Image)
	img = img.duplicate()   # a do cache continua como estava
	img.convert(Image.FORMAT_RGBA8)
	var tag: Image = null
	if label != "":
		tag = PixelArt.tiny(label).get_image()
		tag.convert(Image.FORMAT_RGBA8)
	var w := maxi(img.get_width(), tag.get_width() if tag else 0)
	var h := img.get_height() + (tag.get_height() + 1 if tag else 0)
	if _at.x > 0 and _at.x + w > WIDTH:
		_at = Vector2i(0, _at.y + _row_h + GAP)
		_row_h = 0
	_items.append([img, _at])
	if tag:
		_items.append([tag, _at + Vector2i(0, img.get_height() + 1)])
	_row_h = maxi(_row_h, h)
	_size = Vector2i(maxi(_size.x, _at.x + w), maxi(_size.y, _at.y + h))
	_at.x += w + GAP


func _all(list: Array) -> void:
	for what in list:
		if not _seen.has(what):
			_add(what)
