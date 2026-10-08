extends "res://scripts/ui/background_view.gd"
## Os objetos da mesa do cenário (`Background`) e o tampo: listas, unidade de despacho, caderno, prancheta, jornal,
## caneca e o relógio de flip, cada um posto na sala e passado pela câmera (`_box`, `_flat`, `_project`).

const DESK_T := 1.25    ## o fundo do tampo, Z0/DESK_T: a mesa fica afastada da parede (o armário cabe atrás)
const PLANKS := 6       ## as tábuas do tampo, todas da mesma largura (a câmera as espaça)
const POOL_R := 150.0   ## o raio da poça de luz da luminária no tampo
const SHADE_MAX := 0.3   ## o mais escuro que um objeto da mesa fica, longe da poça de luz (`_shade`)
const WALL_PAD := 10.0           ## a folga dos objetos da mesa até a parede da direita (x da sala)
const PROP_K := 93.0 / 66.0   ## a escala dos objetos da mesa: a mesma dos plugs, que cresceram até o tamanho das tomadas (antes, o plug ficava maior que o relógio e o caderno)
## A unidade de despacho (`_draw_dispatch_unit`, na escala dos objetos, `PROP_K`): largura, altura da base e fundo da
## base até o painel (fração do tampo); o painel: a altura acima da base, o quanto o alto dele recua (fração do tampo,
## para ficar inclinado, de frente para os olhos) e o fundo do móvel todo (fração do tampo).
const UNIT := Vector3(39, 6, 0.17)
const BOOKS_SPAN := 40.0   ## o lugar das listas na fileira (na escala dos objetos): os 31 delas mais os volumes desencontrados e a lombada
const UNIT_PANEL := 16.0
const UNIT_TILT := 0.11
const UNIT_D := 0.3
const CLOCK := Vector3(24, 12.5, 14) * PROP_K   ## o relógio de flip da mesa: largura, altura e fundo (na escala da sala; ~15 × 8 × 9 cm, como as listas de 21 cm)
## Quanto ele está virado para os olhos do operador (1 = de frente para eles; 0 = reto, para a parede). Reto: virado
## pela metade (13°), a frente descia uns 5° entre as horizontais da sala e o lado, que mostra que é uma caixa, quase
## sumia; certo na conta, mas parecia um relógio inclinado numa mesa plana.
const CLOCK_TURN := 0.0
const FLIP_SEC := 0.24      ## quanto a plaqueta leva para virar
const DIGITS := [   ## os algarismos das plaquetas, 9×19 px, desenhados à mão (estreitos, cantos redondos, traço de 2 px), lado a lado
	"..#####.. ....##... ..#####.. ..#####.. ##...##.. ######### ..#####.. ######### ..#####.. ..#####..",
	".#######. ...###... .#######. .#######. ##...##.. ######### .#######. ######### .#######. .#######.",
	"##.....## ..####... ##.....## ##.....## ##...##.. ##....... ##.....## .......## ##.....## ##.....##",
	"##.....## .##.##... .......## .......## ##...##.. ##....... ##....... .......## ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##...##.. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##...##.. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##...##.. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... ......##. .......## ##...##.. #######.. ##....... .....##.. .#######. ##.....##",
	"##.....## ....##... .....##.. ...#####. ##...##.. ########. ##.####.. .....##.. .#######. .########",
	"##.....## ....##... ....##... ...#####. ##...##.. .......## ########. .....##.. ##.....## ..####.##",
	"##.....## ....##... ...##.... .......## ##...##.. .......## ##.....## ....##... ##.....## .......##",
	"##.....## ....##... ..##..... .......## ######### .......## ##.....## ....##... ##.....## .......##",
	"##.....## ....##... .##...... .......## ######### .......## ##.....## ....##... ##.....## .......##",
	"##.....## ....##... ##....... .......## .....##.. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... .......## .....##.. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... .......## .....##.. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... ##.....## .....##.. ##.....## ##.....## ...##.... ##.....## ##.....##",
	".#######. ....##... ######### .#######. .....##.. .#######. .#######. ...##.... .#######. .#######.",
	"..#####.. ....##... ######### ..#####.. .....##.. ..#####.. ..#####.. ...##.... ..#####.. ..#####..",
]

@export var desk_art: Texture2D     ## imagem da madeira da mesa (repetida), no lugar do desenho
# O estado do jogo nos objetos da mesa, para ler de relance sem abrir nada (o Main atualiza):
var pending := 0     ## registros esperando no caderno: uma tira de papel saindo dele por registro
var unread := false  ## o registro das conversas tem fala nova: uma folha nova presa na prancheta
var alert := false     ## há uma emergência em andamento: a luz vermelha da unidade de despacho (o Main atualiza)
var card_out := false  ## há um cartão perfurado na mesa: ele sai da fenda da impressora da unidade, com a luz âmbar
var news := false    ## o jornal da manhã está na mesa (da segunda noite em diante; `Main.set_news`)
var clock_x := 0.0   ## onde o relógio está na tela (x global): de lá vêm a badalada das horas e a campainha do turno
var _yaw := 0.0   # quanto o relógio da mesa está girado (rad; `_draw_flip_clock`)
var _props := {}       # objeto que abre ferramenta -> retângulo dele (px da tela), do último desenho
var _lamp_x := 0.0     # onde está a luminária, no meio da tela (px de 2x2): a luz na mesa e a sombra dos objetos dependem dela
var _zd := Vector2.ZERO   # a frente e o fundo do tampo (z)
var _side_x := 0.0     # a lateral da mesa comutadora na sala (x): os objetos da mesa ficam à direita dela
var _hom := Basis()          # a perspectiva do objeto chato sendo desenhado (`_flat`, `_homography`): o que vai por cima dele, na tela
var _hom_sz := Vector2.ONE   # o tamanho do desenho de frente dele (px)
var _occ: Array = []         # os objetos da mesa (px da tela, convexos): o que fica na frente da parede e do armário
var occ_ids := PackedStringArray()   # quem é cada um de `_occ` (o id da ferramenta, "relogio", "caneca"; o teste da mesa usa)
var _mug_mouth := Vector2.ZERO   # o meio do café na caneca (px da tela), de onde sobe o vapor
var _mug_w := 0.0               # a largura da caneca na tela (px; 0 = ainda não desenhada)


## Em que passo da virada está a plaqueta do relógio (0 a 2; 3 = parada).
func _flip_step() -> int:
	return mini(3, int((Time.get_ticks_msec() - _flip_at) / (FLIP_SEC * 1000.0 / 3.0)))


## Tampo de madeira visto de cima e da frente, de `r.position.y` (o fundo dele) até `front` (a borda da frente,
## com a espessura do tampo embaixo): tábuas compridas de um lado ao outro, sem juntas (com juntas parecia assoalho),
## com as emendas mais juntas no fundo e mais espaçadas na frente, e o fundo mais escuro. Por cima, a poça de luz quente
## da luminária, que escurece para longe dela (a luz da janela, de lado, vem com a parede da direita).
func _draw_desk(r: Rect2, front: float) -> void:
	var depth := front - r.position.y
	var w2 := r.size.x * 2.0
	if desk_art:
		draw_texture_rect(desk_art, Rect2(r.position, Vector2(r.size.x, depth)), true)
	else:
		_r(r.position.x, r.position.y, r.size.x, depth, Color("241a12"))
		# as emendas: tábuas da mesma largura, espaçadas pela câmera (mais juntas no fundo)
		var zb := Z0 / DESK_T
		var zf := Z0 * _yd / (front - _vp.y)
		for k in PLANKS:
			var y0 := roundf(_proj(0, _yd, lerpf(zb, zf, float(k) / PLANKS)).y * 2.0)
			var y1 := roundf(_proj(0, _yd, lerpf(zb, zf, float(k + 1) / PLANKS)).y * 2.0)
			_p(0, y1 - 1, w2, 1, Color("1a120c"))
			_p(0, y0, w2, 1, Color("2b2016"))   # a beira de cada tábua pega luz
			for i in int(w2 / 60.0):   # os veios, mais compridos na frente (mais perto)
				var gx := fmod(i * 197.0 + k * 61.0, w2)
				var gy := roundf(y0 + (y1 - y0) * (0.25 + 0.5 * ((i * 7 + k) % 5) / 4.0))
				var gl := 16.0 + (i % 4) * 10.0 + k * 10.0
				_p(gx, gy, gl, 1, Color("2e2219"))
				_p(gx + gl * 0.3, gy + 1, gl * 0.5, 1, Color("20170f"))
		for k in 2:   # o fundo escurece de leve (sem linha na quina: com ela parecia o rodapé de um chão)
			_r(r.position.x, r.position.y, r.size.x, depth * (0.16 - k * 0.08), Color(0, 0, 0, 0.04))
	# a luz da luminária: um círculo no tampo, embaixo dela (que fica um pouco à frente do fundo da mesa), liso e mais
	# forte no meio; o que passaria do fundo do tampo fica na parede (o arco de `_draw_wall_light`)
	var pool := _pool()
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(_proj(pool.x + cos(a) * POOL_R, _yd, clampf(pool.y + sin(a) * POOL_R * 0.5, 40.0, Z0 / DESK_T)))
	_light_fan(_proj(pool.x, _yd, pool.y), pts, Color(1.0, 0.78, 0.48, 0.22 * lamp_level))
	# a borda da frente: o canto arredondado do tampo pega a luz, a espessura dele e, embaixo, o escuro sob a mesa
	var f := front * 2.0
	_p(0, f - 2, w2, 1, Color("5a4030"))
	_p(0, f - 1, w2, 1, Color("7a5434"))
	_p(0, f, w2, 2, Color("6b4529"))
	_p(0, f + 2, w2, 8, Color("3a2616"))
	_p(0, f + 4, w2, 1, Color("442c1a"))   # um friso na espessura
	_p(0, f + 10, w2, 2, Color("1a120c"))
	_r(r.position.x, front + 6, r.size.x, r.end.y - front - 6, Color("0a0705"))


## Na mesa, embaixo da janela, ao alcance do operador: as listas telefônicas, o caderno aberto, a caneca de café, a
## prancheta do registro e o mapa dobrado, do fundo para a frente (quem está mais perto é desenhado por cima). Cada um
## fica num lugar da sala (x a partir dos olhos, z a distância; ver `Z0`) e é desenhado em px da tela (1x1).
func _draw_desk_props() -> void:
	draw_set_transform(Vector2.ZERO)
	# em duas fileiras, distribuídas de ponta a ponta entre a lateral da mesa comutadora e a parede da direita (a
	# mesma folga entre eles, em qualquer largura de janela: presos a uma ponta só, sobrava mesa vazia na outra, e
	# presos a pontas diferentes, eles se trombavam). Atrás, o que é alto: a unidade de despacho, o caderno e o relógio
	# com a caneca na frente dele; na frente: prancheta, listas (fora da frente da unidade, para não tampar as fendas
	# dela) e o lugar do jornal (guardado mesmo sem ele, para nada mudar de lugar entre as noites).
	# Todos em `PROP_K`, a escala dos plugs da mesa comutadora (que seguem as tomadas)
	var l := _side_x + 8.0
	var r := _cx - _vp.x - WALL_PAD   # a parede da direita é o plano x = quina (na escala da parede do fundo)
	var k := PROP_K
	var cw := CLOCK.x + 2.0   # o relógio, meio virado, ocupa um pouco mais que a largura dele
	var mr := 6.6 * k         # a caneca, na frente do relógio, encostada na ponta direita dele
	# (maiores, e com a prancheta funda, eles se encostavam e a mesa parecia apertada)
	# (a fileira de trás começa encostada na lateral da mesa comutadora; as listas ocupam mais que a largura delas,
	# com os volumes desencontrados, `BOOKS_SPAN`: sem isso, o relógio encostava na pilha)
	var back := _row(_side_x + 2.0, r, [UNIT.x * k, BOOKS_SPAN * k, cw + mr])
	var near := _row(l + 6.0, r, [26.0 * k, 46.0 * k, 32.0 * k])
	_draw_dispatch_unit(back[0], _at(0.5), UNIT.x * k)
	_draw_books(back[1], _at(0.54), 31 * k, _deep(0.3 * k))
	_flat(Tools.LOGBOOK, near[1], _at(0.06), 46 * k, _deep(0.26 * k), 2 * k, Color("3a2414"), _art_notebook, [], deg_to_rad(-2.0), _notebook_marks)
	_draw_flip_clock(back[2] + cw / 2.0, _at(0.72))   # logo atrás da caneca (desenhado antes dela)
	_draw_mug(back[2] + cw, _at(0.46), mr, 13 * k)   # mais larga que alta, como as esmaltadas
	# papel tem 1 px de beira, e a prancheta, uns 2 (mais grossos, pareciam tábuas)
	_flat(Tools.CALL_LOG, near[0], _at(0.05), 26 * k, _deep(0.26 * k), 1.0, Color("4a3018"), _art_clipboard, [unread], deg_to_rad(-4.0),
		_clipboard_print)
	if news:
		_flat(Tools.NEWS, near[2], _at(0.07), 32 * k, _deep(0.19 * k), 0.5, Color("a89c78"), _art_newspaper, [], deg_to_rad(6.0),
			_newspaper_print)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O relógio da sala: um relógio de flip na mesa (centro `xc`, `zc`; medidas em `CLOCK`), meio virado para o operador
## (`CLOCK_TURN` do ângulo até os olhos, `_yaw`): caixa de baquelite creme numa base escura e, na janela, as duas plaquetas (horas e minutos), que viram
## quando a hora muda (`minutes`, `_flip_step`); no tampo, as fendas e o botão do alarme; no lado, a rodinha de
## acertar a hora. É o único relógio da tela.
func _draw_flip_clock(xc: float, zc: float) -> void:
	_yaw = -CLOCK_TURN * atan2(xc, zc)   # a frente gira para os olhos (que estão na origem)
	var hw := CLOCK.x / 2.0
	var hd := CLOCK.z / 2.0
	var bh := 1.5 * PROP_K   # a base, um pouco maior que a caixa, que a levanta da mesa
	_desk_shadow(PackedVector2Array([_clock_pt(xc, zc, -hw - 1, hd + 1, _yd), _clock_pt(xc, zc, hw + 1, hd + 1, _yd),
		_clock_pt(xc, zc, hw + 1, -hd - 1, _yd), _clock_pt(xc, zc, -hw - 1, -hd - 1, _yd)]))
	var dark := _shade(xc, zc)
	var lit := Color.WHITE.darkened(dark)   # longe da luz
	var base := _clock_box(xc, zc, hw + 0.8, hd + 0.8, _yd, bh, Color("4e3a28"), Color("2a1d13"), Color("3a2a1c"))
	var box := _clock_box(xc, zc, hw, hd, _yd - bh, CLOCK.y, Color("dccfa8"), Color("998a66"), Color.TRANSPARENT)
	var hull := PackedVector2Array()
	for faces: Dictionary in [base, box]:
		for q: PackedVector2Array in faces.values():
			hull.append_array(q)
	_occ.append(Geometry2D.convex_hull(hull))
	occ_ids.append("relogio")
	var y1 := _yd - bh - CLOCK.y
	clock_x = global_position.x + _bounds(box["top"]).get_center().x
	for i in 4:   # as fendas do alarme, no fundo do tampo
		var v := hd - 1.6 - i * 1.1
		_pixel_line(_clock_pt(xc, zc, -hw * 0.75, v, y1), _clock_pt(xc, zc, 0.0, v, y1), [Color("a89a76").darkened(dark)])
	var bt := _clock_pt(xc, zc, hw * 0.55, hd * 0.3, y1)   # o botão niquelado do alarme
	_sprite(PixelArt.disc(7, [[3.5, Color(0, 0, 0, 0.3)]]), bt + Vector2(1, 0))
	_sprite(PixelArt.disc(6, [[1.2, Color("f4f0e6")], [3.0, Color("d6d1c3"), Color("8e897c"), Color("45413a")]]), bt - Vector2(0, 2), lit)
	if box.has("left"):   # a rodinha serrilhada de acertar a hora, saindo do lado
		var a := _clock_pt(xc, zc, -hw - 0.8, hd * 0.3, y1 + CLOCK.y * 0.5 - 2.4).round()
		var b := _clock_pt(xc, zc, -hw - 0.8, hd * 0.3, y1 + CLOCK.y * 0.5 + 2.4).round()
		draw_rect(Rect2(a.x + 2, a.y + 1, 1, b.y - a.y), Color(0, 0, 0, 0.35))   # a sombra no lado
		for y in range(int(a.y), int(b.y)):
			draw_rect(Rect2(a.x - 1, y, 3, 1), (Color("b8b2a2") if int(y - a.y) % 2 == 0 else Color("5a574e")).darkened(dark))
	if not box.has("front"):
		return
	# a frente: montada reta, pixel a pixel (`_clock_face`), e posta coluna a coluna na perspectiva (como imagem torta
	# por uma transformação, os algarismos quebravam): cada coluna da tela é um raio dos olhos, que acerta a frente num
	# ponto dela (`a`, de 0 a 1 na largura) a uma distância `z`; de pé, a coluna vai da altura de cima à de baixo nela
	var front: PackedVector2Array = box["front"]
	var l := _clock_xz(xc, zc, -hw, -hd)
	var r := _clock_xz(xc, zc, hw, -hd)
	var x0 := roundi(front[0].x)
	var w := roundi(front[1].x) - x0
	var h := roundi(((front[3].y - front[0].y) + (front[2].y - front[1].y)) / 2.0)
	if w < 8 or h < 8:
		return
	var face := _clock_face(Vector2i(w, h))
	for i in w:
		var t := ((x0 + i + 0.5) / 2.0 - _vp.x) / Z0   # o rumo do raio: x/z
		var a := clampf((t * l.y - l.x) / ((r.x - l.x) - t * (r.y - l.y)), 0.0, 0.999)
		var p := l.lerp(r, a)
		var y0 := roundf(_p3(0, y1, p.y).y)
		var y2 := roundf(_p3(0, y1 + CLOCK.y, p.y).y)
		var sh := _shade(p.x, p.y)   # longe da luz, coluna a coluna
		draw_texture_rect_region(face, Rect2(x0 + i, y0, 1, y2 - y0), Rect2(floorf(a * w), 0, 1, h), Color.WHITE.darkened(sh))
		draw_rect(Rect2(x0 + i, y0 - 1, 1, 1), Color("dccfa8").darkened(sh))   # a quina com o tampo (sem ela, sobravam furos)


## Onde fica na sala (x, z) o ponto do relógio a `u` na largura e `v` no fundo, a partir do centro (`xc`, `zc`), girado
## por `_yaw`.
func _clock_xz(xc: float, zc: float, u: float, v: float) -> Vector2:
	return Vector2(xc + u * cos(_yaw) - v * sin(_yaw), zc + u * sin(_yaw) + v * cos(_yaw))


## Um ponto do relógio da mesa na tela (`_clock_xz`); `y`, a altura.
func _clock_pt(xc: float, zc: float, u: float, v: float, y: float) -> Vector2:
	var p := _clock_xz(xc, zc, u, v)
	return _p3(p.x, y, p.y)


## Uma caixa do relógio, girada como ele (meia largura `hw`, meio fundo `hd`, de `y0` até `h` acima): só as faces
## viradas para os olhos, as de pé em `side` (a da frente em `front`; transparente, quem chama a desenha) e o tampo em
## `top`, escurecendo ponto a ponto longe da luz (`_shade`). Devolve as faces que apareceram ("front", "right", "back",
## "left", "top").
func _clock_box(xc: float, zc: float, hw: float, hd: float, y0: float, h: float, top: Color, side: Color, front: Color) -> Dictionary:
	var cs := cos(_yaw)
	var sn := sin(_yaw)
	var y1 := y0 - h
	var out := {}
	# [nome, normal (u, v), de onde a onde (u, v), da esquerda para a direita de quem olha de fora]
	for f in [["front", Vector2(0, -1), Vector2(-hw, -hd), Vector2(hw, -hd)], ["right", Vector2(1, 0), Vector2(hw, -hd), Vector2(hw, hd)],
			["back", Vector2(0, 1), Vector2(hw, hd), Vector2(-hw, hd)], ["left", Vector2(-1, 0), Vector2(-hw, hd), Vector2(-hw, -hd)]]:
		var n: Vector2 = f[1]
		var m: Vector2 = (f[2] + f[3]) / 2.0
		if Vector2(n.x * cs - n.y * sn, n.x * sn + n.y * cs).dot(-Vector2(xc + m.x * cs - m.y * sn, zc + m.x * sn + m.y * cs)) <= 0.0:
			continue
		var q := PackedVector2Array([_clock_pt(xc, zc, f[2].x, f[2].y, y1), _clock_pt(xc, zc, f[3].x, f[3].y, y1),
			_clock_pt(xc, zc, f[3].x, f[3].y, y0), _clock_pt(xc, zc, f[2].x, f[2].y, y0)])
		if _bounds(q).size.x < 1.0:   # quase de perfil, não aparece (e o polígono nem fecha)
			continue
		out[f[0]] = q
		var col: Color = front if f[0] == "front" else side
		if col.a > 0.0:
			var a := _clock_xz(xc, zc, f[2].x, f[2].y)
			var b := _clock_xz(xc, zc, f[3].x, f[3].y)
			_shaded(q, [a, b, b, a], col)
			if f[0] == "left":   # a quina com a frente pega a luz
				draw_line(q[1], q[2], col.lightened(0.15).darkened(_shade(b.x, b.y)), 1.0)
			elif f[0] == "right":
				draw_line(q[0], q[3], col.lightened(0.15).darkened(_shade(a.x, a.y)), 1.0)
	out["top"] = PackedVector2Array([_clock_pt(xc, zc, -hw, hd, y1), _clock_pt(xc, zc, hw, hd, y1), _clock_pt(xc, zc, hw, -hd, y1), _clock_pt(xc, zc, -hw, -hd, y1)])
	_shaded(out["top"], [_clock_xz(xc, zc, -hw, hd), _clock_xz(xc, zc, hw, hd), _clock_xz(xc, zc, hw, -hd), _clock_xz(xc, zc, -hw, -hd)], top)
	return out


## Uma face na cor `col`, escurecendo ponto a ponto longe da luz (`xz`: os pontos dela na sala).
func _shaded(pts: PackedVector2Array, xz: Array, col: Color) -> void:
	var cols := PackedColorArray()
	for p in xz:
		cols.append(col.darkened(_shade(p.x, p.y)))
	_fill(pts, cols)


## A frente do relógio, de frente, em `sz` px: a caixa creme, a janela preta de aro niquelado com as duas plaquetas
## (horas e minutos) e a plaquinha de latão da marca embaixo. Guardada até a hora ou a virada mudar; aí a mesma
## textura é refeita (o `_process` pergunta a cada quadro): a sala, já desenhada com ela, mostra a hora nova sem se
## redesenhar.
var _face_key := []
var _face: ImageTexture


func _clock_face(sz: Vector2i) -> ImageTexture:
	var m := int(minutes) % 1440
	var was := (_flip_from + 1440) % 1440
	var step := _flip_step()
	var key := [sz, m, was, step]
	if key == _face_key:
		return _face
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Color("c9bb92"))   # um creme envelhecido: mais claro, puxava o olho mais que os outros objetos
	img.fill_rect(Rect2i(0, 0, sz.x, 1), Color("e4d8b4"))
	img.fill_rect(Rect2i(0, sz.y - 1, sz.x, 1), Color("998a66"))
	var win := Rect2i(3, 3, sz.x - 6, sz.y - 8)
	img.fill_rect(win.grow(1), Color("998a66"))   # o rebaixo em volta do aro
	img.fill_rect(win, Color("b8b2a2"))   # o aro niquelado: claro em cima, escuro embaixo
	img.fill_rect(Rect2i(win.position.x, win.end.y - 1, win.size.x, 1), Color("5a574e"))
	img.fill_rect(win.grow(-1), Color("0e0c0a"))
	img.fill_rect(Rect2i(sz.x / 2 - 6, sz.y - 4, 12, 2), Color("8a6a2e"))   # a plaquinha da marca, embaixo da janela
	img.fill_rect(Rect2i(sz.x / 2 - 6, sz.y - 4, 12, 1), Color("c4a35a"))
	var card := Vector2i((win.size.x - 5) / 2, win.size.y - 4)
	_flip_card(img, Vector2i(win.position.x + 2, win.position.y + 2), card, "%02d" % (was / 60), "%02d" % (m / 60), step)
	_flip_card(img, Vector2i(win.end.x - 2 - card.x, win.position.y + 2), card, "%02d" % (was % 60), "%02d" % (m % 60), step)
	_face_key = key
	if _face and _face.get_size() == Vector2(sz):
		_face.update(img)
	else:
		_face = ImageTexture.create_from_image(img)
	return _face


## Uma plaqueta do relógio em `img`, em `at` e do tamanho `sz`, virando de `a` para `b` no passo `step` (0: a metade
## de cima de `a` caindo; 1: ela de lado; 2: a metade de baixo de `b` descendo; 3: parada em `b`). Atrás da que cai,
## em cima já está `b` e embaixo ainda `a`.
func _flip_card(img: Image, at: Vector2i, sz: Vector2i, a: String, b: String, step: int) -> void:
	var cb := _card(b, sz)
	if step >= 3 or a == b:
		img.blit_rect(cb, Rect2i(Vector2i.ZERO, sz), at)
		return
	var ca := _card(a, sz)
	var h := sz.y / 2
	img.blit_rect(cb, Rect2i(0, 0, sz.x, h), at)
	img.blit_rect(ca, Rect2i(0, h, sz.x, sz.y - h), at + Vector2i(0, h))
	if step == 1:   # de lado: só a espessura dela
		img.fill_rect(Rect2i(at.x, at.y + h - 1, sz.x, 2), Color("3a352e"))
		return
	var flap := (ca if step == 0 else cb).get_region(Rect2i(0, 0, sz.x, h) if step == 0 else Rect2i(0, h, sz.x, sz.y - h))
	flap.resize(sz.x, maxi(1, flap.get_height() / 2), Image.INTERPOLATE_NEAREST)   # inclinada, encurta
	flap.adjust_bcs(0.8, 1.0, 1.0)   # e pega menos luz
	img.blit_rect(flap, Rect2i(Vector2i.ZERO, flap.get_size()), at + Vector2i(0, h - flap.get_height() if step == 0 else h))


## A plaqueta com os dois algarismos `text` (`DIGITS`; reduzidos se a plaqueta for menor), do tamanho `sz`: preta,
## com a beira de cima clara e a divisa no meio, onde ela dobra. Guardada.
static var _cards := {}


func _card(text: String, sz: Vector2i) -> Image:
	var key := text + str(sz)
	if _cards.has(key):
		return _cards[key]
	if _cards.size() > 200:   # a tela mudou de tamanho: o relógio também
		_cards.clear()
	var img := Image.create(maxi(1, sz.x), maxi(1, sz.y), false, Image.FORMAT_RGBA8)
	img.fill(Color("1e1b17"))
	img.fill_rect(Rect2i(0, 0, sz.x, 1), Color("3a352e"))
	img.fill_rect(Rect2i(0, sz.y / 2, sz.x, 1), Color("060505"))   # a divisa (por baixo dos algarismos: cortados, não se liam)
	var ink := Image.create(21, 19, false, Image.FORMAT_RGBA8)   # os dois algarismos, com 3 px entre eles
	for i in 2:
		for r in 19:
			var row: String = DIGITS[r].substr(int(text[i]) * 10, 9)
			for c in 9:
				if row[c] == "#":
					ink.set_pixel(i * 12 + c, r, Color("efe4c4"))
	var fit := minf(1.0, minf((sz.x - 2) / 21.0, (sz.y - 4) / 19.0))
	if fit < 1.0:
		ink.resize(maxi(1, int(21 * fit)), maxi(1, int(19 * fit)), Image.INTERPOLATE_NEAREST)
	img.blend_rect(ink, Rect2i(Vector2i.ZERO, ink.get_size()), (sz - ink.get_size() + Vector2i(0, 1)) / 2)
	_cards[key] = img
	return img


## Uma fileira de objetos das larguras `ws` de `a` a `b` (x da sala), com a mesma folga entre eles (nunca negativa:
## numa tela estreita demais, eles se encostam e passam de `b`). Devolve onde cada um começa.
func _row(a: float, b: float, ws: Array) -> Array:
	var total := 0.0
	for w in ws:
		total += w
	var gap := maxf(0.0, (b - a - total) / maxf(1.0, ws.size() - 1.0))
	var out := []
	for w in ws:
		out.append(a)
		a += w + gap
	return out


## Onde fica no tampo (z) o que está a `t` da frente dele (0 = a borda da frente, 1 = o fundo): os objetos da mesa
## ficam no tampo seja qual for a câmera.
func _at(t: float) -> float:
	return lerpf(_zd.x, _zd.y, t)


## Uma profundidade (z) que é a fração `t` do tampo.
func _deep(t: float) -> float:
	return t * (_zd.y - _zd.x)


## Os cantos de uma caixa deitada na mesa (px da tela): de `x0` a `x0 + wx`, de `zf` (frente) a `zf + dz` (fundo), do
## chão `y0` até `h` acima. Devolve {top: [fundo-esq, fundo-dir, frente-dir, frente-esq], front: Rect2, side: [...]}.
func _box(x0: float, zf: float, wx: float, dz: float, y0: float, h: float) -> Dictionary:
	var y1 := y0 - h
	var front := Rect2(_p3(x0, y1, zf).round(), Vector2.ZERO).expand(_p3(x0 + wx, y0, zf).round())
	var sx := x0 if x0 > 0.0 else x0 + wx   # o lado virado para o ponto de fuga (atravessando-o, nenhum)
	var side := PackedVector2Array()
	if x0 > 0.0 or x0 + wx < 0.0:
		side = PackedVector2Array([_p3(sx, y1, zf + dz), _p3(sx, y1, zf), _p3(sx, y0, zf), _p3(sx, y0, zf + dz)])
	return {
		"top": PackedVector2Array([_p3(x0, y1, zf + dz), _p3(x0 + wx, y1, zf + dz), _p3(x0 + wx, y1, zf), _p3(x0, y1, zf)]),
		"front": front,
		"side": side,
	}


## Um paralelogramo da tela (o tampo `q` de uma caixa) como transformação de um retângulo de px (0, 0)–`size`: o
## desenho de frente de um objeto chato vira o tampo dele na perspectiva. Devolve [Transform2D, size].
func _top_xf(q: PackedVector2Array) -> Array:
	var u := ((q[1] - q[0]) + (q[2] - q[3])) / 2.0
	var v := ((q[3] - q[0]) + (q[2] - q[1])) / 2.0
	var s := Vector2(maxf(1.0, roundf(u.length())), maxf(1.0, roundf(absf(v.y))))
	var c := (q[0] + q[1] + q[2] + q[3]) / 4.0
	return [Transform2D(u / s.x, v / s.y, c - u / 2.0 - v / 2.0), s]


## Sombra de um objeto na mesa (`foot`, a marca dele no tampo), apontando para longe da luminária, em degraus: a
## penumbra em volta, a sombra e, colado na base, o escuro de onde ele encosta na mesa (sem ele, os objetos pareciam
## pousados por cima do tampo).
func _desk_shadow(foot: PackedVector2Array) -> void:
	var off := Vector2(clampf((_bounds(foot).get_center().x - _lamp_x * 2.0) / 60.0, -6.0, 8.0), 4.0).round()
	var pts := PackedVector2Array()
	for p in foot:
		pts.append(p + off)
	for g in Geometry2D.offset_polygon(pts, 1.5, Geometry2D.JOIN_MITER):
		_poly(g, Color(0, 0, 0, 0.15))
	_poly(pts, Color(0, 0, 0, 0.3))
	for g in Geometry2D.offset_polygon(foot, 1.0, Geometry2D.JOIN_MITER):
		_poly(g, Color(0, 0, 0, 0.45))


## Onde fica a poça de luz da luminária no tampo (x, z da sala): embaixo dela, um pouco à frente do fundo da mesa.
func _pool() -> Vector2:
	var zl := Z0 / DESK_T * 0.85
	return Vector2((_lamp_x - _vp.x) * zl / Z0, zl)


## Quanto o ponto (`x`, `z`) da mesa fica no escuro: nada embaixo da luminária e mais longe da poça de luz, até
## `SHADE_MAX`; a luminária piscando escurece tudo junto (os objetos tinham a mesma cor em qualquer lugar da mesa e
## pareciam soltos da luz da sala). Contínuo: cada objeto escurece ponto a ponto (`_dim`), não de um tom só.
func _shade(x: float, z: float) -> float:
	var p := _pool()
	var d := Vector2((x - p.x) / POOL_R, (z - p.y) / (POOL_R * 0.5)).length()
	return clampf((d - 0.35) * 0.5, 0.0, SHADE_MAX) + (1.0 - lamp_level) * 0.3


## Escurece o polígono `pts` (px da tela) longe da luz, ponto a ponto: `xz` são os mesmos pontos na sala (x, z), e o
## escuro de cada um (`_shade`) varia liso entre eles.
func _dim(pts: PackedVector2Array, xz: Array) -> void:
	var cols := PackedColorArray()
	for p in xz:
		cols.append(Color(0, 0, 0, _shade(p.x, p.y)))
	_fill(pts, cols)


## Os cantos no tampo (x, z da sala) de um objeto de `wx` por `dz` com o meio em (`cx`, `cz`), girado `yaw` (rad):
## [fundo-esq, fundo-dir, frente-dir, frente-esq]. Girados uns graus cada um, os objetos parecem largados na mesa
## (todos retos, em fileira, a mesa parecia montada).
func _turned(cx: float, cz: float, wx: float, dz: float, yaw: float) -> Array:
	var out := []
	for c: Vector2 in [Vector2(-wx, dz), Vector2(wx, dz), Vector2(wx, -dz), Vector2(-wx, -dz)]:
		var u := c.x / 2.0
		var v := c.y / 2.0
		out.append(Vector2(cx + u * cos(yaw) - v * sin(yaw), cz + u * sin(yaw) + v * cos(yaw)))
	return out


## As faces de pé de uma caixa girada (`xz`, de `_turned`) de `y0` a `y1` que ficam viradas para os olhos: cada uma
## [quad (px da tela), i, normal (x, z)]; a face `i` vai do canto `i` ao seguinte (0 fundo, 1 direita, 2 frente,
## 3 esquerda).
func _faces(xz: Array, y0: float, y1: float) -> Array:
	var out := []
	for i in 4:
		var a: Vector2 = xz[i]
		var b: Vector2 = xz[(i + 1) % 4]
		var n := Vector2(a.y - b.y, b.x - a.x)   # para fora (os cantos vão no sentido do relógio)
		if n.dot(-(a + b) / 2.0) <= 0.0:
			continue
		out.append([PackedVector2Array([_p3(a.x, y1, a.y), _p3(b.x, y1, b.y), _p3(b.x, y0, b.y), _p3(a.x, y0, a.y)]), i, n.normalized()])
	return out


## Um objeto chato que abre a ferramenta `id`, girado `yaw` (rad) em volta do meio: a sombra, a espessura (`h`, na cor
## `edge`: as faces de pé viradas para os olhos, as de lado mais escuras) e o tampo, que `art` desenha de frente numa
## imagem (do tamanho que ele tem na tela, `_top_xf`) e `_project` põe na perspectiva pixel a pixel; `key` é o que
## muda o desenho (a imagem fica guardada até mudar). `post` desenha por cima, já na tela, o que não pode entortar
## (lápis, alfinete, tiras), com `_tex_pt`. Devolve o tampo (px da tela).
func _flat(id: String, x0: float, zf: float, wx: float, dz: float, h: float, edge: Color, art: Callable, key: Array,
		yaw := 0.0, post := Callable()) -> PackedVector2Array:
	var xz := _turned(x0 + wx / 2.0, zf + dz / 2.0, wx, dz, yaw)
	var foot := PackedVector2Array()
	var top := PackedVector2Array()
	for p: Vector2 in xz:
		foot.append(_p3(p.x, _yd, p.y))
		top.append(_p3(p.x, _yd - h, p.y))
	_desk_shadow(foot)
	var dark := _shade(x0 + wx / 2.0, zf + dz / 2.0)
	for f: Array in _faces(xz, _yd, _yd - h):
		_poly(f[0], edge.darkened(0.35 * absf((f[2] as Vector2).x)).darkened(dark))
	var sz := Vector2i(_top_xf(top)[1])
	if sz.x >= 8 and sz.y >= 4:   # (a tela ainda se arrumando)
		_hom = _homography(top)
		_hom_sz = Vector2(sz)
		_project([id, sz, key], art, top, sz)
		if post.is_valid():
			post.call(sz)
	_dim(top, xz)   # longe da luz, ponto a ponto
	_props[id] = _bounds(foot + top)
	_occ.append(Geometry2D.convex_hull(foot + top))
	occ_ids.append(id)
	return top


## A homografia que leva o retângulo unitário (u, v: 0 no fundo-esq, u para a direita, v para a frente) ao quadrilátero
## `q` da tela ([fundo-esq, fundo-dir, frente-dir, frente-esq]): a perspectiva exata de um retângulo no tampo.
func _homography(q: PackedVector2Array) -> Basis:
	var sx := q[0].x - q[1].x + q[2].x - q[3].x
	var sy := q[0].y - q[1].y + q[2].y - q[3].y
	var g := 0.0
	var h := 0.0
	if absf(sx) > 0.0001 or absf(sy) > 0.0001:
		var d1 := q[1] - q[2]
		var d2 := q[3] - q[2]
		var det := d1.x * d2.y - d2.x * d1.y
		if absf(det) > 0.0001:
			g = (sx * d2.y - d2.x * sy) / det
			h = (d1.x * sy - sx * d1.y) / det
	return Basis(Vector3(q[1].x - q[0].x + g * q[1].x, q[1].y - q[0].y + g * q[1].y, g),
		Vector3(q[3].x - q[0].x + h * q[3].x, q[3].y - q[0].y + h * q[3].y, h), Vector3(q[0].x, q[0].y, 1.0))


## Onde cai na tela o ponto `p` do desenho de frente do objeto chato sendo desenhado (px do desenho).
func _tex_pt(p: Vector2) -> Vector2:
	var v := _hom * Vector3(p.x / _hom_sz.x, p.y / _hom_sz.y, 1.0)
	return Vector2(v.x / v.z, v.y / v.z)


## As alturas (y do desenho de frente, px) de `y0` até `y1` que caem a cada `step` px da tela, no meio do objeto chato
## sendo desenhado: o espaço entre as linhas de texto é o da tela, não o do papel. (No papel, linhas de 1 px a cada 2
## viravam moiré e zigue-zague: a perspectiva aperta o fundo e estica a frente, e pulava ou dobrava linhas.)
func _rows(y0: float, y1: float, step: float) -> Array:
	var a := _tex_pt(Vector2(_hom_sz.x / 2.0, y0))
	var b := _tex_pt(Vector2(_hom_sz.x / 2.0, y1))
	var span := b.y - a.y
	var out := []
	if span < step:
		return out
	var inv := _hom.inverse()
	for k in floori(span / step) + 1:
		var p := a.lerp(b, k * step / span)
		var r := inv * Vector3(p.x, p.y, 1.0)
		out.append(r.y / r.z * _hom_sz.y)
	return out


## Um risco de tinta no objeto chato sendo desenhado, de `x0` a `x1` na altura `y` do desenho de frente, posto na
## tela em pixel art (`cols`: a espessura, de cima para baixo), como o lápis do caderno.
func _ink(x0: float, x1: float, y: float, cols: Array) -> void:
	_pixel_line(_tex_pt(Vector2(x0, y)), _tex_pt(Vector2(x1, y)), cols)


## O desenho de frente de um objeto chato posto no quadrilátero `q` da tela pixel a pixel, como a frente do relógio:
## cada pixel da tela pega o texel que cai nele, pela homografia (torto por transformação, o desenho esticava e
## entortava os pixels: uma linha de 1 px virava 0 ou 2, e destoava do resto do jogo). Guardado por `key`.
static var _projected := {}


func _project(key: Array, art: Callable, q: PackedVector2Array, sz: Vector2i) -> void:
	var box := _bounds(q)
	var at := Vector2i(floori(box.position.x), floori(box.position.y))
	var full := [key, at, Vector2i(ceili(box.end.x), ceili(box.end.y))]
	if not _projected.has(full):
		if _projected.size() > 40:   # a tela mudou de tamanho: tudo muda junto
			_projected.clear()
		var img: Image = art.call(sz)
		var inv := _hom.inverse()
		var out := Image.create(maxi(1, ceili(box.end.x) - at.x), maxi(1, ceili(box.end.y) - at.y), false, Image.FORMAT_RGBA8)
		for y in out.get_height():
			for x in out.get_width():
				var r := inv * Vector3(at.x + x + 0.5, at.y + y + 0.5, 1.0)
				var u := r.x / r.z
				var v := r.y / r.z
				if u >= 0.0 and u < 1.0 and v >= 0.0 and v < 1.0:
					out.set_pixel(x, y, img.get_pixel(int(u * sz.x), int(v * sz.y)))
		_projected[full] = ImageTexture.create_from_image(out)
	draw_texture(_projected[full], Vector2(at))


## Um retângulo cheio na imagem `img`, cortado na borda dela.
func _fr(img: Image, x: float, y: float, w: float, h: float, c: Color) -> void:
	if w < 1.0 or h < 1.0:
		return
	var r := Rect2i(int(x), int(y), int(w), int(h)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.has_area():
		img.fill_rect(r, c)


## Uma linha de 1 px na imagem `img`, pixel a pixel, de `a` a `b`.
func _fl(img: Image, a: Vector2, b: Vector2, c: Color) -> void:
	var n := maxi(1, int(maxf(absf(b.x - a.x), absf(b.y - a.y))))
	for i in n + 1:
		var p := a.lerp(b, float(i) / n).round()
		if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
			img.set_pixel(int(p.x), int(p.y), c)


## As listas telefônicas, três volumes grossos empilhados meio tortos: a lombada na cor da capa, do lado virado para o
## ponto de fuga, com os filetes dourados; na frente, o miolo de papel com as folhas marcadas entre as capas; e, no de
## cima, o tampo com a faixa do título e o emblema da central.
func _draw_books(x0: float, zf: float, wx: float, dz: float) -> void:
	var cols := [Pal.SEAL, Color("2a4a7c"), Pal.BOOK]
	var offs := [Vector2(1, 0) * PROP_K, Vector2(3, 2) * PROP_K, Vector2(0, 1) * PROP_K]   # meio tortos: x e z de cada volume
	var yaws := [deg_to_rad(-3.0), deg_to_rad(3.5), deg_to_rad(-1.0)]   # e cada um girado para um lado
	var bh := 5.5 * PROP_K
	var all := PackedVector2Array()
	var foot := PackedVector2Array()
	for p: Vector2 in _turned(x0 + wx / 2.0, zf + dz / 2.0, wx, dz, yaws[0]):
		foot.append(_p3(p.x, _yd, p.y))
	_desk_shadow(foot)
	for b in 3:
		var c: Color = cols[b]
		var cx: float = x0 + offs[b].x + wx / 2.0
		var xz := _turned(cx, zf + offs[b].y + dz / 2.0, wx, dz, yaws[b])
		var y0 := _yd - b * bh
		var spine := 1 if cx < 0.0 else 3   # a lombada fica do lado virado para o ponto de fuga; nos outros, o miolo
		for f: Array in _faces(xz, y0, y0 - bh):
			var q: PackedVector2Array = f[0]
			var i: int = f[1]
			var at := func(u: float, v: float) -> Vector2: return q[0].lerp(q[1], u).lerp(q[3].lerp(q[2], u), v)   # um ponto da face
			if i == spine:   # a lombada: os filetes dourados e, entre eles, a etiqueta escura do volume com o número
				_poly(q, c.darkened(0.2))
				_pixel_line(at.call(0.0, 0.2), at.call(1.0, 0.2), [Pal.GOLD])
				_pixel_line(at.call(0.0, 0.8), at.call(1.0, 0.8), [Pal.GOLD])
				_poly(PackedVector2Array([at.call(0.32, 0.34), at.call(0.68, 0.34), at.call(0.68, 0.66), at.call(0.32, 0.66)]), c.darkened(0.5))
				_pixel_line(at.call(0.44, 0.5), at.call(0.56, 0.5), [Pal.GOLD])
			else:
				# o miolo entre as capas, com as folhas em linhas finas: numa imagem posta pixel a pixel, como a capa (em
				# linhas tortas desenhadas na tela, elas viravam degraus quebrados e faixas)
				var fs := Vector2i(roundi(q[0].distance_to(q[1])), roundi(q[0].distance_to(q[3])))
				if fs.x >= 4 and fs.y >= 3:
					_hom = _homography(q)
					_hom_sz = Vector2(fs)
					var dk := 0.15 * absf((f[2] as Vector2).x)
					_project(["folhas", b, i, fs], _art_pages.bind(c, dk), q, fs)
				if i == 2:   # tiras de papel marcando páginas, saindo da frente (cada volume as dele)
					for m: Vector2 in [[Vector2(0.72, 0.0)], [Vector2(0.3, 1.0), Vector2(0.82, 0.0)], [Vector2(0.55, 1.0)]][b]:
						var p: Vector2 = (at.call(m.x, 0.55) as Vector2).round()   # deitada entre as folhas: uma aba fina, com a sombra embaixo
						var col := Pal.FORM_RED if m.y == 0.0 else Pal.STRIP
						draw_rect(Rect2(p - Vector2(3, 0), Vector2(6, 2)), col)
						draw_rect(Rect2(p - Vector2(3, 0), Vector2(6, 1)), col.lightened(0.15))
						draw_rect(Rect2(p + Vector2(-3, 2), Vector2(6, 1)), Color(0, 0, 0, 0.35))
			_dim(q, [xz[i], xz[(i + 1) % 4], xz[(i + 1) % 4], xz[i]])
			all.append_array(q)
		var top := PackedVector2Array()
		for p: Vector2 in xz:
			top.append(_p3(p.x, y0 - bh, p.y))
		var cover := c.darkened(0.15)   # a capa, que pega a luz de cima de chapa, um tom abaixo da cor do cabo
		_poly(top, cover)
		all.append_array(top)
		var sz := Vector2i(_top_xf(top)[1])
		if b == 2 and sz.x >= 8 and sz.y >= 4:   # a capa do volume de cima, pixel a pixel como os objetos chatos
			_hom = _homography(top)
			_hom_sz = Vector2(sz)
			_project([Tools.DIRECTORY, sz], _art_book_cover.bind(cover), top, sz)
		_dim(top, xz)   # longe da luz, ponto a ponto: cada volume logo depois de desenhado (os de cima cobrem os de baixo)
	_props[Tools.DIRECTORY] = _bounds(all)
	_occ.append(Geometry2D.convex_hull(all))
	occ_ids.append(Tools.DIRECTORY)


## A caneca de café em pé na mesa (centro `xc`, `zc`; raio `rr`, altura `hh`): uma caneca esmaltada de época,
## branco-gelo com a borda azul-marinho, montada pixel a pixel numa imagem do tamanho dela na tela (`_mug_art`) e
## escurecida longe da luz. A boca e o pé saem da câmera (elipses mais ou menos abertas pela altura de cada um).
func _draw_mug(xc: float, zc: float, rr: float, hh: float) -> void:
	var a := _p3(xc - rr, _yd - hh, zc).round()
	var body := Rect2(a, _p3(xc + rr, _yd, zc).round() - a)
	var ry := maxf(2.0, roundf((_p3(xc, _yd - hh, zc - rr).y - _p3(xc, _yd - hh, zc + rr).y) / 2.0))   # a boca
	var rb := maxf(2.0, roundf((_p3(xc, _yd, zc - rr).y - _p3(xc, _yd, zc + rr).y) / 2.0))   # o pé, mais aberto (mais abaixo dos olhos)
	if body.size.x < 10.0 or body.size.y < 10.0:   # (a tela ainda se arrumando)
		return
	_mug_mouth = body.position + Vector2(body.size.x / 2.0, ry * 0.3)   # o vapor sai do café (`_draw_steam`)
	_mug_w = body.size.x
	_desk_shadow(PackedVector2Array([body.position + Vector2(0, body.size.y - rb), body.end - Vector2(0, rb), body.end + Vector2(0, rb),
		Vector2(body.position.x, body.end.y + rb)]))
	var img := _mug_art(int(body.size.x), int(body.size.y), int(ry), int(rb))
	draw_texture(img, body.position - Vector2(0, ry), Color.WHITE.darkened(_shade(xc, zc)))
	var hull := PackedVector2Array()
	for p in _mug_hulls[Vector4i(int(body.size.x), int(body.size.y), int(ry), int(rb))]:
		hull.append(p + body.position - Vector2(0, ry))
	_occ.append(hull)
	occ_ids.append("caneca")


## A caneca esmaltada de frente, com `w` de largura e `h` da boca ao pé (px), a boca e o pé em elipses de meia altura
## `ry` e `rb`: o corpo sombreado como um cilindro pela luz da luminária (do alto à esquerda: o brilho numa coluna, a
## sombra à direita, em tons fixos de pixel art), a borda azul-marinho em volta da boca e o filete dela no pé, o lado de
## dentro com o café embaixo (a luz da luminária refletida nele), a alça em C do lado da sombra e duas lascas no esmalte
## mostrando o ferro. Guardada por tamanho.
static var _mugs := {}
static var _mug_hulls := {}   # o contorno de cada caneca (px dela), da mesma chave


func _mug_art(w: int, h: int, ry: int, rb: int) -> ImageTexture:
	var key := Vector4i(w, h, ry, rb)
	if _mugs.has(key):
		return _mugs[key]
	var hw := 9   # a alça, para fora do lado direito
	var img := Image.create(w + hw, h + ry + rb + 1, false, Image.FORMAT_RGBA8)
	var ramp := [Color("e2dbca"), Color("d3cbb7"), Color("bfb69f"), Color("a49b83"), Color("857c66"), Color("5e5848")]
	var navy := [Color("4a608a"), Color("34486c"), Color("243452"), Color("18223a")]
	var light := Vector2(-0.6, 0.8).normalized()   # (x de lado, z para os olhos): a luz vem do alto à esquerda
	var top := float(ry)   # o centro da boca na imagem
	for x in w:   # o corpo, coluna a coluna
		var nx := (x + 0.5) / w * 2.0 - 1.0
		var nz := sqrt(maxf(0.0, 1.0 - nx * nx))
		var d := clampf(Vector2(nx, nz).dot(light), 0.0, 1.0)
		var tone: Color = ramp[clampi(int((1.0 - d) * 5.99), 0, 5)]
		var y0 := int(top + nz * ry)   # a beira da frente da boca
		var y1 := int(top + h + nz * rb)   # a beira da frente do pé
		_fr(img, x, y0, 1, y1 - y0, tone)
		_fr(img, x, y0, 1, 2, navy[clampi(int((1.0 - d) * 3.99), 0, 3)])   # a borda
		_fr(img, x, y1 - 1, 1, 1, navy[mini(3, clampi(int((1.0 - d) * 3.99), 0, 3) + 1)])   # o filete do pé
	var gx := int(w * 0.28)   # o brilho do esmalte: uma coluna clara no alto do lado da luz
	_fr(img, gx, int(top + ry) + 3, 1, int(h * 0.55), Color("eee8da"))
	_fr(img, gx + 1, int(top + ry) + 4, 1, int(h * 0.3), Color("e8e2d2"))
	# a boca: o aro azul, o lado de dentro esmaltado (a parede de trás aparece acima do café) e o café com a luz nele
	for y in range(0, ry * 2 + 1):
		for x in w:
			var e := Vector2((x + 0.5 - w / 2.0) / (w / 2.0), (y + 0.5 - top) / maxf(1.0, ry))
			var r2 := e.length_squared()
			if r2 > 1.0:
				continue
			var c: Color = navy[1]
			if r2 < 0.72:   # dentro do aro
				c = Color("c9c1ab") if e.x < 0.3 else Color("aea690")   # a parede de dentro, mais escura do lado da sombra
				var f := Vector2(e.x / 0.78, (e.y - 0.3) / 0.62)   # o café, mais baixo que a boca
				if f.length_squared() < 1.0:
					c = Color("2e1c10")
					if f.y > -0.55 and f.y < -0.2 and f.x > -0.55 and f.x < -0.05:
						c = Color("4a301c")   # a luz da luminária refletida no café: um risco do lado dela
			elif e.y < -0.2:
				c = navy[0]   # o aro, mais claro atrás (pega a luz por cima)
			img.set_pixel(x, y, c)
	var hy0 := top + ry + 2.0   # a alça em C, do lado da sombra: um anel grosso com o furo (fina, parecia arame), a
	var hy1 := top + ry + h * 0.66   # beira de cima pegando a luz e a volta de fora na sombra
	var hc := Vector2(w - 2.0, (hy0 + hy1) / 2.0)
	var ho := Vector2(hw + 0.5, (hy1 - hy0) / 2.0)   # o anel por fora e o furo
	var hi := Vector2(hw - 5.0, maxf(1.0, ho.y - 4.5))
	for y in range(int(hy0), int(hy1) + 1):
		for x in range(w - 1, w + hw):
			var q := Vector2(x + 0.5, y + 0.5) - hc
			var out := (q / ho).length_squared()
			if out > 1.0 or (q / hi).length_squared() < 1.0:
				continue
			var c := Color("bfb69f")
			if q.y < -ho.y * 0.4:
				c = Color("d3cbb7")   # o alto, na luz
			elif out > 0.8 and (q.x > hw * 0.4 or q.y > 0.0):
				c = Color("958c76")   # a volta de fora e o pé, na sombra (mais escura, sumia na parede escura)
			img.set_pixel(x, y, c)
	for p in [Vector2i(int(w * 0.62), int(top + ry) + 1), Vector2i(int(w * 0.18), int(top + h) - 3)]:   # as lascas no esmalte
		_fr(img, p.x, p.y, 2, 1, Color("2a2620"))
		img.set_pixel(p.x, p.y + 1, Color("4a443c"))
	var tex := ImageTexture.create_from_image(img)
	_mugs[key] = tex
	var bm := BitMap.new()   # o contorno dela, pelo que não é transparente (o relâmpago não passa por ela)
	bm.create_from_image_alpha(img)
	var pts := PackedVector2Array()
	for poly in bm.opaque_to_polygons(Rect2i(Vector2i.ZERO, img.get_size()), 1.0):
		pts.append_array(poly)
	_mug_hulls[key] = Geometry2D.convex_hull(pts)
	return tex


## O miolo de uma lista telefônica visto de lado (`sz`), entre as capas na cor `c`: as folhas em linhas finas, de 2
## em 2 px, umas mais escuras que as outras, mais sujas junto das capas; `dk` escurece o lado que não está de frente.
func _art_pages(sz: Vector2i, c: Color, dk: float) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var paper := Color("c6b994").darkened(dk)
	img.fill(paper)
	for y in range(2, sz.y - 2, 2):   # as folhas
		var line := paper.darkened(0.05 if (y * 7) % 5 < 3 else 0.09)
		var x := 0
		while x < sz.x:   # cada linha com uma falha aqui e ali (folha mais curta)
			var n := 6 + (x * 13 + y * 7) % 23
			_fr(img, x, y, mini(n, sz.x - x), 1, line)
			x += n + (1 if (x + y) % 3 == 0 else 0)
	_fr(img, 0, 1, sz.x, 1, paper.darkened(0.14))   # mais sujo junto das capas
	_fr(img, 0, sz.y - 3, sz.x, 1, paper.darkened(0.14))
	_fr(img, 0, 0, sz.x, 1, c.lightened(0.15).darkened(dk))   # a capa de cima e a de baixo
	_fr(img, 0, sz.y - 2, sz.x, 2, c.darkened(0.3).darkened(dk))
	return img


## A capa da lista telefônica de cima, de frente: o pano na cor dela com a luz na beira de cima e da esquerda e os
## cantos gastos, o título dourado numa faixa em baixo-relevo, o fone da companhia em dourado no meio, a etiqueta
## colada com o ano, a marca de uma caneca que alguém pousou nela e a ponta da frente dobrada, mostrando a folha.
func _art_book_cover(sz: Vector2i, c: Color) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var gold := Pal.GOLD
	img.fill(c)
	for y in sz.y:   # o grão do papelão: pontos um pouco mais escuros ou claros, sempre os mesmos
		for x in sz.x:
			var g := (x * 73 + y * 151 + x * y * 7) % 97
			if g < 6:
				img.set_pixel(x, y, c.darkened(0.07))
			elif g > 92:
				img.set_pixel(x, y, c.lightened(0.05))
	_fr(img, 2, 2, sz.x - 4, 1, c.darkened(0.16))   # o friso em volta, em baixo-relevo: a sombra em cima e à esquerda...
	_fr(img, 2, 2, 1, sz.y - 4, c.darkened(0.16))
	_fr(img, 2, sz.y - 3, sz.x - 4, 1, c.lightened(0.1))   # ...e a luz embaixo e à direita
	_fr(img, sz.x - 3, 2, 1, sz.y - 4, c.lightened(0.1))
	_fr(img, 0, 0, sz.x, 1, c.lightened(0.22))
	_fr(img, 0, 0, 1, sz.y, c.lightened(0.1))
	_fr(img, sz.x - 1, 0, 1, sz.y, c.darkened(0.25))
	_fr(img, 0, sz.y - 1, sz.x, 1, c.darkened(0.25))
	for p in [Vector2i(0, 0), Vector2i(sz.x - 2, 0), Vector2i(0, sz.y - 2)]:   # os cantos gastos
		_fr(img, p.x, p.y, 2, 2, c.lightened(0.3))
	var band := Rect2i(3, 2, sz.x - 6, maxi(3, int(sz.y * 0.26)))   # o título
	_fr(img, band.position.x, band.position.y, band.size.x, band.size.y, c.darkened(0.3))
	_fr(img, band.position.x, band.position.y, band.size.x, 1, c.darkened(0.45))
	_fr(img, band.position.x, band.end.y, band.size.x, 1, c.lightened(0.12))
	var x := band.position.x + 3
	var ty := band.position.y + band.size.y / 2
	while x < band.end.x - 3:   # as letras, em dourado
		var n := 2 + (x * 7) % 3
		_fr(img, x, ty, n, 1, gold)
		x += n + 1 + (2 if (x * 5) % 7 == 0 else 0)
	var h := Vector2i(sz.x / 2, band.end.y + maxi(3, int(sz.y * 0.22)))   # o fone: o cabo com o fone de ouvido e o de boca
	_fr(img, h.x - 4, h.y, 9, 1, gold)
	_fr(img, h.x - 5, h.y + 1, 3, 2, gold)
	_fr(img, h.x + 3, h.y + 1, 3, 2, gold)
	_fr(img, h.x - 4, h.y + 1, 9, 1, gold.darkened(0.35))
	var tag := Rect2i(4, sz.y - 7, 13, 5)   # a etiqueta colada com o ano
	if tag.position.y > band.end.y + 1:
		_fr(img, tag.position.x + 1, tag.position.y + 1, tag.size.x, tag.size.y, c.darkened(0.35))
		_fr(img, tag.position.x, tag.position.y, tag.size.x, tag.size.y, Color("e2d7b6"))
		_fr(img, tag.position.x + 2, tag.position.y + 2, tag.size.x - 4, 1, Color("4a4038"))
	var ring := Vector2(sz.x * 0.72, sz.y * 0.68)   # a marca da caneca: um anel mais escuro, aberto de um lado
	for k in 28:
		var an := TAU * k / 28.0
		if an > 0.6 and an < 1.6:
			continue
		var p := (ring + Vector2(cos(an) * 5.0, sin(an) * 2.5)).round()
		if p.x >= 0 and p.y >= 0 and p.x < sz.x and p.y < sz.y:
			img.set_pixel(int(p.x), int(p.y), c.darkened(0.22))
	for y in 5:   # a ponta da frente dobrada: a folha à mostra e a aba virada por cima, com a dobra
		for xx in 5 - y:
			img.set_pixel(sz.x - 1 - xx, sz.y - 5 + y + xx, Color("d8cba6"))
	for k in 5:
		img.set_pixel(sz.x - 1 - k, sz.y - 5 + k - (1 if k > 0 else 0), c.lightened(0.25) if k < 4 else c.darkened(0.3))
	return img


## O mapa da cidade sob o vidro da unidade de despacho (`_art_glass`): o mapa aberto (`CityMap`) em miniatura, com as
## mesmas folhas (as dos bairros atendidos, enquadradas como ele abre; o papel tem a proporção delas), os quarteirões no
## tom de cada bairro com as casas em volta e as árvores dos quintais (`CityMap.lots`), os lugares de telhado de barro,
## a praça com os caminhos e o coreto, a zona rural, as divisas e o selo vermelho. Os nomes ficam de fora: nesse
## tamanho, seriam só ruído.
func _art_map(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.MAP_PAPER)   # o papel, e as ruas são ele à mostra
	var fr := CityMap.frame_of(GameData.sectors)
	var s := Vector2(sz) / fr.size   # px do mapa -> px do desenho (o tampo como é visto: bem mais baixo que largo)
	var pt := func(p: Vector2) -> Vector2: return ((p - fr.position) * s).round()
	var put := func(r: Rect2, c: Color) -> Rect2:   # um retângulo do mapa no desenho, em px inteiros (ao menos 1)
		var a: Vector2 = pt.call(r.position)
		var b := Rect2(a, (pt.call(r.end) - a).max(Vector2.ONE))
		_fr(img, b.position.x, b.position.y, b.size.x, b.size.y, c)
		return b
	for sheet in MapGrid.SHEETS:
		if not CityMap.shown(sheet):
			continue
		var o: Vector2 = MapGrid.SHEETS[sheet]
		if sheet == 0:   # a zona rural: as roças, as estradas de terra e o rio
			for ci in 5:
				for ri in 4:
					var f := CityMap.field_rect(ci, ri)
					put.call(Rect2(o + f.position, f.size), Pal.MAP_FIELDS[(ci + ri) % 2])
			for v in CityMap.ROADS_V:
				put.call(Rect2(o + Vector2(v - 5.0, 0), Vector2(10, 440)), Pal.MAP_DIRT)
			for h in CityMap.ROADS_H:
				put.call(Rect2(o + Vector2(0, h - 5.0), Vector2(600, 10)), Pal.MAP_DIRT)
			for i in CityMap.RIVER.size() - 1:
				for d in [Vector2.ZERO, Vector2(1, 0)]:
					_fl(img, pt.call(o + CityMap.RIVER[i]) + d, pt.call(o + CityMap.RIVER[i + 1]) + d, Pal.MAP_RIVER)
			continue
		var tint: Color = Pal.MAP_TINTS[MapGrid.SHEET_SECTOR[sheet]]
		var roof := tint.darkened(0.22)
		for ci in 5:
			for ri in 4:
				var r := CityMap.block_rect(ci, ri)
				r.position += o
				var lm: int = MapGrid.LM.get(sheet, {}).get("%d,%d" % [ci, ri], -1)
				var b: Rect2 = put.call(r, tint.darkened(0.3))   # a beira da quadra, de 1 px
				_fr(img, b.position.x + 1, b.position.y + 1, b.size.x - 2, b.size.y - 2, Pal.MAP_PLAZA if lm == T.Key.MAP_SQUARE else tint)
				if lm == T.Key.MAP_SQUARE:
					var q := r.grow(-2)
					for seg: Array in CityMap.square_paths(q):
						_fl(img, pt.call(seg[0]), pt.call(seg[1]), Pal.MAP_PAPER)
					for p: Vector2 in CityMap.square_trees(q):
						put.call(Rect2(p, Vector2(8, 8)), Pal.MAP_TREE)
					var c: Rect2 = put.call(Rect2(q.get_center() - Vector2(14, 12), Vector2(28, 24)), CityMap.LINE)   # o coreto
					_fr(img, c.position.x + 1, c.position.y + 1, c.size.x - 2, c.size.y - 2, Pal.MAP_BANDSTAND)
				elif lm != -1:   # o lugar: um prédio só, com a metade de cima (ou da esquerda) do telhado na luz; a beira
					var mb := r.grow(-8)   # no barro escuro (no traço do mapa, 1 px aqui é um muro de 10 lá)
					var lb: Rect2 = put.call(mb, Pal.MAP_LANDMARK.darkened(0.5))
					var inner := lb.grow(-1)
					_fr(img, inner.position.x, inner.position.y, inner.size.x, inner.size.y, Pal.MAP_LANDMARK)
					var lit := inner.size * (Vector2(1, 0.5) if mb.size.x >= mb.size.y else Vector2(0.5, 1))
					_fr(img, inner.position.x, inner.position.y, lit.x, lit.y, Pal.MAP_LANDMARK.lightened(0.12))
				else:
					for lot: Array in CityMap.lots(r.grow(-4), sheet * 31 + ci * 7 + ri * 3):
						var lr: Rect2 = lot[0]
						if lot[1] == CityMap.Lot.TREE:
							put.call(lr, Pal.MAP_TREE)
							continue
						var h: Rect2 = put.call(lr, roof)
						var half := Vector2(floorf(h.size.x / 2.0), h.size.y) if lot[1] == CityMap.Lot.HOUSE_ACROSS else Vector2(h.size.x, floorf(h.size.y / 2.0))
						_fr(img, h.position.x, h.position.y, half.x, half.y, roof.lightened(0.1))
	for seg: Array in CityMap.BORDERS:   # as divisas entre os bairros, tracejadas
		if CityMap.shown(seg[0]) and CityMap.shown(seg[1]):
			var n := int((seg[2] as Vector2).distance_to(seg[3]) / 24.0)
			for i in n:
				var a: Vector2 = (seg[2] as Vector2).lerp(seg[3], float(i) / n)
				var e: Vector2 = (seg[2] as Vector2).lerp(seg[3], (i + 0.5) / n)
				put.call(Rect2(a, e - a).abs().grow(1.5), Pal.MAP_PAPER.lerp(CityMap.LINE, 0.5))
	var sw := maxi(12, roundi(sz.x * 0.19))   # o selo no canto, como no mapa aberto: a moldura vermelha, a seta do
	var sh := maxi(5, roundi(sz.y * 0.08))    # norte e o nome da cidade
	var sp := Vector2i(sz.x - sw - maxi(2, sz.x / 100), sz.y - sh - 2)
	_fr(img, sp.x, sp.y, sw, sh, Pal.SEAL)
	_fr(img, sp.x + 1, sp.y + 1, sw - 2, sh - 2, Pal.MAP_PAPER)
	_fr(img, sp.x + 3, sp.y + 2, 1, sh - 4, CityMap.LINE)
	_fr(img, sp.x + roundi(sw * 0.35), sp.y + sh / 2, roundi(sw * 0.55), 1, CityMap.LINE)
	return img


## A unidade de despacho, que abre o despacho (`x0`, a frente em `zf`, `wx` de largura; medidas em `UNIT`): um móvel
## de metal no material das máquinas da ficha (`Pal.PANEL`), como um terminal antigo. Embaixo, a base, com as três
## máquinas embutidas no tampo, na mesma disposição do despacho aberto (`_art_deck`: o transmissor à esquerda, a
## impressora no meio e o triturador à direita) e, na frente, a plaqueta de latão e as luzes; em
## cima, atrás, o painel inclinado com o mapa de papel sob o vidro (`_art_glass`). O estado do
## jogo nela: a luz vermelha com uma emergência em andamento (`alert`) e o cartão saindo da impressora enquanto há um
## na mesa (`card_out`), com a luz âmbar.
func _draw_dispatch_unit(x0: float, zf: float, wx: float) -> void:
	var k := PROP_K
	var x1 := x0 + wx
	var dd := _deep(UNIT.z * k)   # o fundo da base até o painel
	var zb := zf + dd
	var zt := zb + _deep(UNIT_TILT * k)   # o alto do vidro, mais para trás
	var ze := zf + _deep(UNIT_D * k)   # o fundo do móvel
	var yd := _yd - UNIT.y * k   # o tampo da base
	var yt := yd - UNIT_PANEL * k   # o alto do painel
	_desk_shadow(PackedVector2Array([_p3(x0, _yd, ze), _p3(x1, _yd, ze), _p3(x1, _yd, zf), _p3(x0, _yd, zf)]))
	var dark := _shade(x0 + wx / 2.0, (zf + ze) / 2.0)
	var all := PackedVector2Array()
	var sx := x0 if x0 > 0.0 else x1   # o lado virado para o ponto de fuga (atravessando-o, nenhum)
	if x0 > 0.0 or x1 < 0.0:
		var base := PackedVector2Array([_p3(sx, yd, ze), _p3(sx, yd, zf), _p3(sx, _yd, zf), _p3(sx, _yd, ze)])
		_poly(base, Pal.PANEL_LO.darkened(dark))
		var side := PackedVector2Array([_p3(sx, yt, zt), _p3(sx, yt, ze), _p3(sx, yd, ze), _p3(sx, yd, zb)])
		_poly(side, Pal.PANEL_LO.lightened(0.04).darkened(dark))
		all.append_array(base + side)
	var top := PackedVector2Array([_p3(x0, yt, ze), _p3(x1, yt, ze), _p3(x1, yt, zt), _p3(x0, yt, zt)])   # o alto do painel
	_poly(top, Pal.PANEL_HI.darkened(dark))
	_dim(top, [Vector2(x0, ze), Vector2(x1, ze), Vector2(x1, zt), Vector2(x0, zt)])
	var glass := PackedVector2Array([_p3(x0, yt, zt), _p3(x1, yt, zt), _p3(x1, yd, zb), _p3(x0, yd, zb)])
	_flat_art("despacho_vidro", glass, _art_glass, [GameData.sectors.duplicate()], dark)
	var deck := PackedVector2Array([_p3(x0, yd, zb), _p3(x1, yd, zb), _p3(x1, yd, zf), _p3(x0, yd, zf)])
	_flat_art("despacho_base", deck, _art_deck, [], dark)
	if card_out:   # o cartão saindo da fenda da impressora, no meio, para trás (para cima do vidro)
		var sz := _hom_sz
		var card := PackedVector2Array([_tex_pt(sz * Vector2(0.38, 0.0)), _tex_pt(sz * Vector2(0.62, 0.0)),
			_tex_pt(sz * Vector2(0.62, 0.46)), _tex_pt(sz * Vector2(0.38, 0.46))])
		_poly(card, PunchCard.CARD.darkened(dark))
		_pixel_line(_tex_pt(sz * Vector2(0.39, 0.15)), _tex_pt(sz * Vector2(0.61, 0.15)), [Pal.FORM_RED.darkened(dark)])
	var front := Rect2(_p3(x0, yd, zf).round(), Vector2.ZERO).expand(_p3(x1, _yd, zf).round())   # a frente da base
	draw_rect(front, Pal.PANEL.darkened(dark))
	draw_rect(Rect2(front.position, Vector2(front.size.x, 1)), Pal.PANEL_HI.darkened(dark))
	draw_rect(Rect2(front.position.x, front.end.y - 1, front.size.x, 1), Pal.EDGE)
	var mid := front.position.y + floorf(front.size.y / 2.0)
	var plate := Rect2(front.position.x + roundf(front.size.x * 0.36), mid - 2, roundf(front.size.x * 0.28), 4)
	draw_rect(plate, Pal.BRASS.darkened(0.25 + dark))   # a plaqueta do fabricante
	draw_rect(plate.grow(-1), Pal.BRASS.darkened(dark))
	for i in 3:   # a saída de ar, à direita
		draw_rect(Rect2(front.end.x - roundf(front.size.x * 0.22), mid - 2 + i * 2, roundf(front.size.x * 0.16), 1), Pal.PANEL_LO)
	for l: Array in [[0.06, alert, Pal.RED], [0.14, card_out, Pal.AMBER]]:   # as luzes: ocorrência e cartão na mesa
		var lr := Rect2(front.position.x + roundf(front.size.x * l[0]), mid - 1, 3, 3)
		draw_rect(lr.grow(1), Pal.EDGE)
		draw_rect(lr, l[2] if l[1] else (l[2] as Color).darkened(0.75))
		if l[1]:
			_light(lr, l[2], 0.6, true)
	all.append_array(top + glass + deck)
	all.append_array(PackedVector2Array([front.position, front.end, Vector2(front.position.x, front.end.y)]))
	_props[Tools.DISPATCH] = _bounds(all)
	_occ.append(Geometry2D.convex_hull(all))
	occ_ids.append(Tools.DISPATCH)


## O desenho de frente `art` (com `key`) posto no quadrilátero `q` da tela pixel a pixel (`_project`), escurecido
## `dark` longe da luz; deixa `_hom` dele para o que vai por cima (`_tex_pt`).
func _flat_art(id: String, q: PackedVector2Array, art: Callable, key: Array, dark: float) -> void:
	var sz := Vector2i(_top_xf(q)[1])
	if sz.x < 8 or sz.y < 3:   # (a tela ainda se arrumando)
		return
	_hom = _homography(q)
	_hom_sz = Vector2(sz)
	_project([id, sz, key], art, q, sz)
	if dark > 0.0:
		_poly(q, Color(0, 0, 0, dark))


## O tampo da base da unidade de despacho, de cima (o alto do desenho é o fundo): a chapa com a beira clara e as três
## fendas lado a lado, como no despacho aberto (`CardMachines`): o transmissor à esquerda, com as marcas âmbar, a
## impressora no meio e o triturador à direita, com as faixas de perigo.
func _art_deck(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.PANEL)
	_fr(img, 0, 0, sz.x, 1, Pal.PANEL_HI)
	_fr(img, 0, sz.y - 1, sz.x, 1, Pal.PANEL_HI)
	var slot := func(x: float, y: float, w: float) -> Vector2i:   # uma fenda: o lábio e o escuro de dentro
		var a := Vector2i(roundi(x * sz.x), roundi(y * sz.y))
		var n := roundi(w * sz.x)
		_fr(img, a.x - 1, a.y - 1, n + 2, 3, Pal.PANEL_LO)
		_fr(img, a.x, a.y, n, 1, Pal.EDGE)
		_fr(img, a.x - 1, a.y + 2, n + 2, 1, Pal.PANEL_HI)
		return a
	var tx: Vector2i = slot.call(0.05, 0.45, 0.27)   # o transmissor
	_fr(img, tx.x, tx.y + 3, 2, 1, Pal.AMBER)
	_fr(img, tx.x + roundi(0.27 * sz.x) - 2, tx.y + 3, 2, 1, Pal.AMBER)
	slot.call(0.365, 0.45, 0.27)   # a impressora
	var sh: Vector2i = slot.call(0.68, 0.45, 0.27)   # o triturador
	for i in range(0, roundi(0.27 * sz.x), 4):
		_fr(img, sh.x + i, sh.y + 3, 2, 1, CardMachines.HAZARD)
	return img


## O painel da unidade de despacho, de frente: a moldura de metal e, sob o vidro, o mapa de papel (`_art_map`, na
## proporção das folhas, com papel em volta; um pouco mais escuro perto da moldura), a sombra da moldura no alto e o
## reflexo do vidro na diagonal. Papel sob a luz da sala, não uma tela acesa.
func _art_glass(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.PANEL)
	_fr(img, 0, 0, sz.x, 1, Pal.PANEL_HI)
	_fr(img, 0, 0, 1, sz.y, Pal.PANEL_HI)
	_fr(img, sz.x - 1, 0, 1, sz.y, Pal.PANEL_LO)
	var inner := _glass_inner(sz)
	if inner.size.x < 4 or inner.size.y < 4:
		return img
	var paper := Image.create(inner.size.x, inner.size.y, false, Image.FORMAT_RGBA8)
	paper.fill(Pal.MAP_PAPER)
	var at := _glass_map(sz)
	paper.blit_rect(_art_map(at.size), Rect2i(Vector2i.ZERO, at.size), at.position - inner.position)
	for y in inner.size.y:
		for x in inner.size.x:
			var d := Vector2((x + 0.5) / inner.size.x - 0.5, (y + 0.5) / inner.size.y - 0.5).length() * 2.0
			var c := paper.get_pixel(x, y).darkened(0.12 + 0.2 * d * d)   # o papel atrás do vidro, mais escuro na moldura
			if absf((x - inner.size.x * 0.25) - (inner.size.y - y) * 0.8) < inner.size.x * 0.06:   # o reflexo do vidro
				c = c.lightened(0.08)
			img.set_pixel(inner.position.x + x, inner.position.y + y, c)
	for x in inner.size.x:   # a sombra da moldura no alto do vidro
		var c := img.get_pixel(inner.position.x + x, inner.position.y)
		img.set_pixel(inner.position.x + x, inner.position.y, c.darkened(0.35))
	return img


## O vidro dentro da moldura do painel da unidade de despacho (`_art_glass` de `sz` px).
func _glass_inner(sz: Vector2i) -> Rect2i:
	var m := maxi(2, roundi(sz.x * 0.05))
	return Rect2i(m, m, sz.x - m * 2, sz.y - m * 2)


## Onde fica o mapa no painel da unidade de despacho (px do desenho de `sz`): no meio do vidro, na proporção das folhas.
func _glass_map(sz: Vector2i) -> Rect2i:
	var inner := _glass_inner(sz)
	var fr := CityMap.frame_of(GameData.sectors)
	var fit := minf(float(inner.size.x) / fr.size.x, float(inner.size.y) / fr.size.y)
	var msz := Vector2i(maxi(1, floori(fr.size.x * fit) - 2), maxi(1, floori(fr.size.y * fit) - 2))
	return Rect2i(inner.position + (inner.size - msz) / 2, msz)


## O caderno de ocorrências aberto: a capa de couro com a beira gasta, duas páginas creme (não brancas: chamavam mais o
## olho que tudo) com a margem vermelha, a sombra da dobra no meio e a espessura das folhas embaixo. A pauta e a letra
## de mão vão por cima, na tela (`_notebook_marks`).
func _art_notebook(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.LEATHER[1])   # a capa
	_fr(img, 0, 0, sz.x, 1, Pal.LEATHER[0])
	_fr(img, 0, sz.y - 1, sz.x, 1, Pal.LEATHER[2])
	var half := sz.x / 2
	for k in 2:
		var x0 := 2 if k == 0 else half + 1
		var x1 := half - 1 if k == 0 else sz.x - 2
		_fr(img, x0, 1, x1 - x0, sz.y - 3, Pal.NOTE_PAGE)
		_fr(img, x0, sz.y - 3, x1 - x0, 1, Color("a89a74"))   # a espessura das folhas
		_fr(img, x0, 1, x1 - x0, 1, Color("ddd2b0"))   # a beira de cima pega a luz
	for i in 3:   # a sombra da dobra no meio, mais escura no fundo dela
		_fr(img, half - 2 + i, 1, 1, sz.y - 3, Color("8a7a58").lerp(Color("b8ab86"), absf(i - 1.0)))
	return img


## Por cima do caderno, na tela: a pauta e a letra de mão (umas palavras por linha, linha sim, linha não: cheia, era
## ruído), a 3 px da tela uma linha da outra (`_rows`), as tiras dos registros pendentes saindo do fundo dele (uma por
## registro, até seis) e o lápis apoiado na página da direita, em pixel art na tela (torto pela perspectiva, serrilhava).
func _notebook_marks(sz: Vector2i) -> void:
	var half := sz.x / 2
	var rows := _rows(4.0, sz.y - 4.0, 3.0)
	for k in 2:
		var x0 := 2.0 if k == 0 else half + 3.0   # a pauta para antes da sombra da dobra
		var x1 := half - 3.0 if k == 0 else sz.x - 3.0
		for row in rows.size():
			var y: float = rows[row]
			_ink(x0, x1, y, [Pal.NOTE_RULE])
			if (row + k) % 2 == 0 or (row * 7 + k * 3) % 5 == 0:
				continue
			var a := _tex_pt(Vector2(x0 + 6, y)) - Vector2(0, 1)   # as palavras, logo acima da pauta
			var b := _tex_pt(Vector2(x0 + 6 + (x1 - x0 - 10) * (0.45 + 0.1 * ((row * 3 + k) % 5)), y)) - Vector2(0, 1)
			var t := 0.0
			var span := a.distance_to(b)
			while t < span:
				var n := 3.0 + (int(t) * 3 + row * 5 + k) % 4
				_pixel_line(a.lerp(b, t / span), a.lerp(b, minf(t + n - 1.0, span) / span), [Color("6a6474")])
				t += n + 2.0
		var mx := (2.0 if k == 0 else half + 1.0) + 4.0   # a margem vermelha, impressa por cima da pauta
		_pixel_line(_tex_pt(Vector2(mx, 1)), _tex_pt(Vector2(mx, sz.y - 3)), [Pal.NOTE_MARGIN])
	for i in mini(pending, 6):
		var p := _tex_pt(Vector2(8 + i * floorf((sz.x - 22) / 6.0), 0)).round()
		var up := 6.0 + (i * 5) % 4
		var col := Pal.PENDING[i % 2]
		draw_rect(Rect2(p.x, p.y - up, 6, up + 2), col)
		draw_rect(Rect2(p.x + 5, p.y - up, 1, up + 2), col.darkened(0.2))   # o lado na sombra
		draw_rect(Rect2(p.x, p.y - up, 5, 1), col.lightened(0.12))   # a beira de cima, na luz
		draw_rect(Rect2(p.x + 1, p.y - up + 2, 3, 1), Pal.FORM_RED)
		draw_rect(Rect2(p.x, p.y + 1, 6, 1), Color(0, 0, 0, 0.3))   # onde ela entra no caderno
	var a := _tex_pt(Vector2(half + 10, sz.y - 5)).round()
	var b := _tex_pt(Vector2(sz.x - 6, 4)).round()
	var d := (b - a).normalized()
	_pixel_line(a + Vector2(2, 2), b + d * 7 + Vector2(2, 2), [Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3)])
	_pixel_line(a, b, [Color("c4a042"), Color("957622"), Color("67521a")])   # o corpo, amarelo de lápis gasto
	_pixel_line(a - d * 4, a, [Color("c8aa80"), Color("b0926a"), Color("8a7050")])   # a madeira apontada
	_pixel_line(a - d * 6, a - d * 4, [Color("2a2620")])   # o grafite
	_pixel_line(b, b + d * 4, Pal.NICKEL.slice(1))   # a ponteira, no níquel da mesa
	_pixel_line(b + d * 4, b + d * 7, [Color("c08a80"), Color("a86a62"), Color("7a4a44")])   # a borracha


const CLIP_ART := [   ## o prendedor da prancheta, de pé na beira de cima (16 × 8): a alavanca em arco e o corpo com os rebites
	"....eeeeeeee....",
	"...eHLLLLLLMDe..",
	"..eLM.......MDe.",
	".eeeeeeeeeeeeee.",
	"eHLLLLLLLLLLLLMe",
	"eLoMMMMMMMMMMoDe",
	"eMDDDDDDDDDDDDDe",
	".eeeeeeeeeeeeee.",
]
## O níquel do prendedor: o mesmo do aro das lâmpadas da mesa comutadora (luz, meio, sombra), o brilho e os rebites.
const CLIP_PAL := {"H": Pal.NICKEL[0], "L": Pal.NICKEL[1], "M": Pal.NICKEL[2], "D": Pal.NICKEL[3], "o": Color("ece7da"),
	"e": Color("2a2620")}


const SHEET_TURN := 3.5   ## graus que a folha nova da prancheta fica girada (reta, lia como um risco no meio da de baixo)


## A prancheta do registro: tábua de duratex com os cantos cortados e a beira gasta e a folha. Com fala nova no registro
## (`unread`), uma folha nova, mais clara, presa por cima, girada (`SHEET_TURN`) e com a ponta dobrada. O datilografado
## das folhas e o prendedor vão por cima, na tela (`_clipboard_print`).
func _art_clipboard(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.BOARD[1])
	_fr(img, 0, 0, sz.x, 1, Pal.BOARD[0])
	_fr(img, 0, 0, 1, sz.y, Color("7e5634"))
	_fr(img, sz.x - 1, 0, 1, sz.y, Pal.BOARD[2])
	_fr(img, 0, sz.y - 1, sz.x, 1, Pal.BOARD[2])
	for c in [Vector2i(0, 0), Vector2i(sz.x - 2, 0), Vector2i(0, sz.y - 2), Vector2i(sz.x - 2, sz.y - 2)]:   # os cantos cortados
		img.set_pixel(c.x + (0 if c.x == 0 else 1), c.y + (0 if c.y == 0 else 1), Color(0, 0, 0, 0))
	var sheets := _sheets(sz)
	var r: Rect2i = sheets[0][0]
	_fr(img, r.position.x + 1, r.position.y + 1, r.size.x, r.size.y, Pal.BOARD[2])   # a sombra da folha na tábua
	_fr(img, r.position.x, r.position.y, r.size.x, r.size.y, sheets[0][1])
	_fr(img, r.position.x, r.position.y, r.size.x, 1, (sheets[0][1] as Color).lightened(0.12))
	if sheets.size() > 1:   # a folha nova, girada em volta do prendedor, com a sombra na de baixo e a ponta dobrada
		var n: Rect2i = sheets[1][0]
		var base: Color = sheets[1][1]
		var box := n.grow(4)
		for y in range(maxi(0, box.position.y), mini(sz.y, box.end.y)):
			for x in range(maxi(0, box.position.x), mini(sz.x, box.end.x)):
				var l := _unturn(Vector2(x + 0.5, y + 0.5), n)   # o pixel na folha reta
				var u := l.x - (n.end.x - 5.0)   # a ponta de baixo à direita
				var v := l.y - (n.end.y - 5.0)
				var corner := u > 0.0 and v > 0.0 and u + v > 5.0
				if Rect2(n).has_point(l) and not corner:
					var c := base.lightened(0.12) if l.y < n.position.y + 1.0 else base
					if u > 0.0 and v > 0.0 and u + v > 3.0:
						c = base.darkened(0.14) if u + v < 4.5 else base.lightened(0.06)   # a aba virada, com a dobra
					img.set_pixel(x, y, c)
				elif Rect2(n).has_point(l - Vector2(1, 1)) and not corner:
					img.set_pixel(x, y, (sheets[0][1] as Color).darkened(0.25))   # a sombra dela
	return img


## O ponto `p` do desenho da prancheta na folha nova `n` antes de girar (o giro é em volta do meio do alto dela, onde
## fica o prendedor).
func _unturn(p: Vector2, n: Rect2i) -> Vector2:
	var c := Vector2(n.get_center().x, n.position.y)
	return (p - c).rotated(-deg_to_rad(SHEET_TURN)) + c


## O ponto `p` da folha nova `n` reta, girado como ela fica na prancheta.
func _turn(p: Vector2, n: Rect2i) -> Vector2:
	var c := Vector2(n.get_center().x, n.position.y)
	return (p - c).rotated(deg_to_rad(SHEET_TURN)) + c


## As folhas da prancheta (`sz`, o desenho de frente): [retângulo, cor do papel, quantas linhas]; com fala nova no
## registro, a folha nova por cima cobre só o alto da de baixo (inteira, a prancheta parecia vazia).
func _sheets(sz: Vector2i) -> Array:
	var out := [[Rect2i(3, 4, sz.x - 6, sz.y - 6), Pal.SHEET, 99]]
	if unread:
		out.append([Rect2i(5, 3, sz.x - 10, int(sz.y * 0.55)), Pal.SHEET_NEW, 3])
	return out


## Por cima da prancheta, na tela: o datilografado de cada folha, o cabeçalho (o título e o fio vermelho) e as linhas
## em duas colunas (a hora e o resto), a 3 px da tela uma da outra (`_rows`). Na de baixo, só o que a nova não cobre.
func _clipboard_print(sz: Vector2i) -> void:
	var sheets := _sheets(sz)
	var cover := -1.0   # até onde a folha nova cobre a de baixo (y do desenho; girada, desce um pouco de um lado)
	if sheets.size() > 1:
		cover = (sheets[1][0] as Rect2i).end.y + 4.0
	for i in sheets.size():
		var r: Rect2i = sheets[i][0]
		var rows := _rows(r.position.y + 2.0, r.end.y - 1.0, 1.0)
		var x0 := float(r.position.x)
		var w := float(r.size.x)
		var n := 0
		for k in rows.size():
			var y: float = rows[k]
			if i == 0 and y <= cover:
				continue
			var line := func(a: float, b: float, col: Color) -> void:   # na folha nova, girado com ela
				var pa := Vector2(a, y)
				var pb := Vector2(b, y)
				if i == 1:
					pa = _turn(pa, r)
					pb = _turn(pb, r)
				_pixel_line(_tex_pt(pa), _tex_pt(pb), [col])
			if k == 0:
				line.call(x0 + 2, x0 + 2 + (w - 4) / 2.0 - 1, Color("5a5448"))   # o título
			elif k == 1:
				line.call(x0 + 2, x0 + w - 3, Pal.FORM_RED)   # o fio vermelho do cabeçalho
			elif k >= 4 and (k - 4) % 3 == 0 and n < sheets[i][2]:
				line.call(x0 + 2, x0 + 4, Color("6a6458"))   # a hora
				line.call(x0 + 7, x0 + w - 3 - (k * 7) % 9 - (6 if i == 1 else 0), Color("6a6458"))
				n += 1
	# o prendedor, de pé na beira de cima, com a sombra na folha (deitado no papel, era um borrão cinza)
	var at := (_tex_pt(Vector2(sz.x / 2.0, 3.0)) - Vector2(8, 6)).round()
	draw_texture(PixelArt.art(CLIP_ART, {"*": Color(0, 0, 0, 0.35)}), at + Vector2(1, 2))
	draw_texture(PixelArt.art(CLIP_ART, CLIP_PAL), at)


## O jornal da manhã dobrado ao meio: papel-jornal amarelado com a foto da primeira página (o céu claro em cima, o
## escuro embaixo). O que é risco (o nome, a data, a manchete, as colunas e o vinco) vai por cima, na tela
## (`_newspaper_print`); a foto era um xadrez em retícula, que a perspectiva virava moiré.
func _art_newspaper(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.NEWSPRINT)   # papel-jornal amarelado (cinza, longe da luz, sumia no escuro)
	_fr(img, 0, 0, sz.x, 1, Color("e2d6b2"))
	_fr(img, sz.x - 1, 0, 1, sz.y, Color("a89c78"))
	_fr(img, 0, sz.y - 1, sz.x, 1, Color("a89c78"))
	var photo := _news_photo(sz)
	_fr(img, photo.position.x - 1, photo.position.y - 1, photo.size.x + 2, photo.size.y + 2, Color("3e382e"))
	_fr(img, photo.position.x, photo.position.y, photo.size.x, photo.size.y, Color("938767"))
	_fr(img, photo.position.x, photo.position.y + photo.size.y * 0.45, photo.size.x, photo.size.y * 0.55 + 1, Color("675f4c"))
	return img


## Onde fica a foto do jornal no desenho de frente dele (`sz`).
func _news_photo(sz: Vector2i) -> Rect2i:
	return Rect2i(sz.x - int(sz.x * 0.3) - 2, 13, int(sz.x * 0.3), int(sz.y * 0.45))


## Por cima do jornal, na tela: o nome numa faixa escura, a linha da data, a manchete grossa em duas linhas, as
## colunas de texto miúdo (a da direita embaixo da foto) e o vinco da dobra, cada risco com 1 px da tela (`_rows`).
func _newspaper_print(sz: Vector2i) -> void:
	var rows := _rows(2.0, sz.y - 2.0, 1.0)   # a altura no papel de cada px da tela, a partir do nome
	if rows.size() < 16:
		return
	var ink := Color("2a2620")
	var head := Color("3a3630")
	_ink(2, sz.x - 2, rows[2], [ink, ink, ink])   # o nome do jornal (afastado da beira: colado, ela saía picotada)
	_ink(2, sz.x - 2, rows[5], [Color("8a8068")])   # a data
	_ink(2, 2 + sz.x * 0.72, rows[8], [head, head])   # a manchete
	_ink(2, 2 + sz.x * 0.5, rows[11], [head, head])
	var photo := _news_photo(sz)
	var cw := (photo.position.x - 6) / 2.0
	for k in range(14, rows.size() - 1, 2):   # as colunas de texto
		var y: float = rows[k]
		for col in 3:
			var x0 := 2.0 + col * (cw + 2.0)
			var w := cw - (k * 3 + col) % 4
			if col == 2:
				if y < photo.end.y + 2:
					continue
				x0 = photo.position.x
				w = photo.size.x - (k * 3) % 4
			_ink(x0, x0 + w - 1.0, y, [Pal.NEWS_INK])
	_ink(0, sz.x - 1, sz.y / 2.0, [Color("a89c78"), Color("dccfa8")])   # o vinco
