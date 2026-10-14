extends "res://scripts/ui/background_view.gd"
## Os objetos da mesa do cenário (`Background`) e o tampo: listas, unidade de despacho, bloco de fichas, calculógrafo, jornal,
## caneca e o relógio de flip (e a prancheta, pendurada na lateral da mesa comutadora), cada um posto na sala e passado pela câmera (`_box`, `_flat`, `_project`).

const DESK_T := 1.25    ## o fundo do tampo, Z0/DESK_T: a mesa fica afastada da parede (o armário cabe atrás)
const PLANKS := 6       ## as tábuas do tampo, todas da mesma largura (a câmera as espaça)
const POOL_R := 112.0   ## o raio da poça de luz da luminária no tampo
const SHADE_MAX := 0.3   ## o mais escuro que um objeto da mesa fica, longe da poça de luz (`_shade`)
const WALL_PAD := 2.0           ## a folga dos objetos da mesa até a parede da direita (x da sala)
const MUG_ID := "caneca"   ## a caneca: sob o mouse se ergue como os objetos das ferramentas; clicada, um gole (`Background.sip`)
const MUG_SIPS := 5       ## os goles do café da caneca
const EDGE_PX := 8.0            ## e a da fileira da frente até a beira da tela (px de 2x2): perto, a parede já passou dela, e o jornal saía cortado
const PROP_K := 0.75 * 93.0 / 66.0   ## a escala dos objetos da mesa: no tamanho de verdade deles na sala (`_cm`; as listas com 21 cm), maiores que o plug em pé (uns 9 cm)
## A unidade de despacho (`_draw_dispatch_unit`, na escala dos objetos, `PROP_K`): largura, altura da base e fundo da
## base até o painel (fração do tampo); o painel: a altura acima da base, o quanto o alto dele recua (fração do tampo,
## para ficar inclinado, de frente para os olhos) e o fundo do móvel todo (fração do tampo).
const UNIT := Vector3(39, 6, 0.17)
const BOOKS_SPAN := 40.0   ## o lugar das listas na fileira (na escala dos objetos): os 31 delas mais os volumes desencontrados e a lombada
const UNIT_PANEL := 16.0
const PAD_W := 26.0    ## a largura do bloco de fichas (na escala dos objetos, uns 18 cm; o caderno aberto, com 46, tomava a fileira da frente)
const NEWS_W := 25.0   ## a largura do jornal dobrado (na escala dos objetos, uns 16 cm): com 32, o calculógrafo não cabia do lado
const UNIT_TILT := 0.11
const UNIT_D := 0.3
## O calculógrafo (`_draw_calculograph`, na escala dos objetos, `PROP_K`): a largura (uns 18 cm, com o bilhete de 6; com
## 14, o carimbo tinha 2 cm e o plug parecia gigante; com 22, larga e baixa demais perto da aberta), a altura da máquina,
## na proporção da da ferramenta (632 × 104), e o fundo dela (fração do tampo); na frente dela, a mesinha dela, na
## proporção da mesa da ferramenta (`Toll.NOMINAL`).
const CALC := Vector3(28, 4.6, 0.06)
const TOLL_BOX_H := 4.5   ## a altura da caixinha dos bilhetes (na sala, uns 2 cm)
const STAMP_ART := [   ## o carimbo em pé na mesinha, como o da ferramenta (21 × 35 px, uns 6 cm): o cabo de baquelite com o medalhão, a haste, o corpo com a plaqueta, as rodas de latão entre as pernas e a sapata vazada
	"......kkKKKKKkk......",
	"....kKKhhKKKKKKKk....",
	"....kKhgKmMbMmKKk....",
	"....kKhhKKmmmKKKk....",
	"....kkKKKKKKKKKkk....",
	".....kkkkkkkkkkk.....",
	"........cpcCd........",
	".......ccpcCdd.......",
	"........cpcCd........",
	"........cpcCd........",
	"........cpcCd........",
	".......ccpccCdd......",
	"..cppppppppppppppCd..",
	"..cpppppppppppppcCd..",
	"..cCCCCCCCCCCCCCCCd..",
	"..cCpppppppppppppCd..",
	"..cCpiiiiiiiiiiipCd..",
	"..cCpppppppppppppCd..",
	"..cCCCCCCCCCCCCCCCd..",
	"..ddddddddddddddddd..",
	"cCdeeeeeeeeeeeeeeecCd",
	"cbd.bBbBbBbBbBbBb.cCd",
	"cCd.BbBbBbBbBbBbB.cCd",
	"cCd.bBbBbBbBbBbBb.cCd",
	"cCd....bbbbbbb....cCd",
	"cCd....bBBBBBb....cCd",
	"cCd...............cCd",
	"cbd...............cCd",
	"cCd...............cCd",
	"cpppppppppppppppppppd",
	"cpp...............ppd",
	"cpp...............ppd",
	"cpppppppppppppppppppd",
	"CCCCCCCCCCCCCCCCCCCCd",
	"ddddddddddddddddddddd",
]
const CLOCK := Vector3(24, 12.5, 14) * PROP_K   ## o relógio de flip da mesa: largura, altura e fundo (na escala da sala; ~15 × 8 × 9 cm, como as listas de 21 cm)
## Quanto ele está virado para os olhos do operador (1 = de frente para eles; 0 = reto, para a parede). Reto: virado
## pela metade (13°), a frente descia uns 5° entre as horizontais da sala e o lado, que mostra que é uma caixa, quase
## sumia; certo na conta, mas parecia um relógio inclinado numa mesa plana.
const CLOCK_TURN := 0.0
const FLIP_SEC := 0.24      ## quanto a plaqueta leva para virar
## Os algarismos das plaquetas, 9×19 px, desenhados à mão (estreitos, cantos redondos em degrau de 1 px, as hastes
## de 2 px e as barras de 1: com tudo em 2 px pareciam uma fonte de 5×10 ampliada, de pixels dobrados), lado a lado.
const DIGITS := [
	"..#####.. ....##... ..#####.. ..#####.. ##....##. ######### ..#####.. ######### ..#####.. ..#####..",
	".##...##. ...###... .##...##. .##...##. ##....##. ##....... .##...##. .......## .##...##. .##...##.",
	"##.....## ..#.##... ##.....## ##.....## ##....##. ##....... ##.....## .......## ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##....##. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##....##. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##....##. ##....... ##....... ......##. ##.....## ##.....##",
	"##.....## ....##... .......## .......## ##....##. ##....... ##....... .....##.. ##.....## ##.....##",
	"##.....## ....##... ......##. .......## ##....##. #######.. ##.####.. .....##.. ##.....## ##.....##",
	"##.....## ....##... .....##.. ......##. ##....##. ......##. ###...##. .....##.. .##...##. ##.....##",
	"##.....## ....##... ....##... ..#####.. ##....##. .......## ##.....## ....##... ..#####.. ##.....##",
	"##.....## ....##... ...##.... ......##. ##....##. .......## ##.....## ....##... .##...##. .##...###",
	"##.....## ....##... ..##..... .......## ######### .......## ##.....## ....##... ##.....## ..####.##",
	"##.....## ....##... .##...... .......## ......##. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... .......## ......##. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... .......## ......##. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... .......## ......##. .......## ##.....## ...##.... ##.....## .......##",
	"##.....## ....##... ##....... ##.....## ......##. ##.....## ##.....## ...##.... ##.....## ##.....##",
	".##...##. ....##... ##....... .##...##. ......##. .##...##. .##...##. ...##.... .##...##. .##...##.",
	"..#####.. ....##... ######### ..#####.. ......##. ..#####.. ..#####.. ...##.... ..#####.. ..#####..",
]

@export var desk_art: Texture2D     ## imagem da madeira da mesa (repetida), no lugar do desenho
# O estado do jogo nos objetos da mesa, para ler de relance sem abrir nada (o Main atualiza):
var pending := 0     ## registros esperando no bloco de fichas: uma tira de papel saindo dele por registro
var unread := false  ## o registro das conversas tem fala nova: uma folha nova presa na prancheta
var alert := false     ## há uma emergência em andamento: a luz vermelha da unidade de despacho (o Main atualiza)
var card_out := false  ## há um cartão perfurado na mesa: ele sai da fenda da impressora da unidade, com a luz âmbar
var news := false    ## o jornal da manhã está na mesa (da segunda noite em diante; `Main.set_news`)
var counting := 0    ## as entradas contando um interurbano, um bit cada (`Toll.counters`): os contadores acesos do calculógrafo
var toll_desk := []  ## o que está na mesinha do calculógrafo e onde (`Toll.layout`; o Main só passa com a ferramenta fechada)
var clock_x := 0.0   ## onde o relógio está na tela (x global): de lá vêm a badalada das horas e a campainha do turno
var _yaw := 0.0   # quanto o relógio da mesa está girado (rad; `_draw_flip_clock`)
var _props := {}       # objeto que abre ferramenta -> retângulo dele (px da tela), do último desenho
var sips := 0   ## os goles já tomados do café: ele baixa na caneca (`_mug_art`) e, acabado, o vapor some
var _up_id := ""       # o objeto erguido sob o mouse, subindo ou assentando ("" = nenhum): fica na camada dele (`_lifted`), não na sala
var _lamp_x := 0.0     # onde está a luminária, no meio da tela (px de 2x2): a luz na mesa e a sombra dos objetos dependem dela
var _zd := Vector2.ZERO   # a frente e o fundo do tampo (z)
var _side_x := 0.0     # a lateral da mesa comutadora na sala (x): os objetos da mesa ficam à direita dela
var _tip := Rect2()   # a ponta do bilhete saindo da fenda do calculógrafo, inteira (px da tela; a camada dela a desenha)
var _tip_dark := 0.0
var _tip_cover: Array = []   # o carimbo em pé na mesinha [textura, meio, cor]: fica na frente da fenda, e a camada da ponta o desenha de novo por cima dela
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
		_ci.draw_texture_rect(desk_art, Rect2(r.position, Vector2(r.size.x, depth)), true)
	else:
		_r(r.position.x, r.position.y, r.size.x, depth, Pal.DESK)
		# as emendas: tábuas da mesma largura, espaçadas pela câmera (mais juntas no fundo)
		var zb := Z0 / DESK_T
		var zf := Z0 * _yd / (front - _vp.y)
		for k in PLANKS:
			var y0 := roundf(_proj(0, _yd, lerpf(zb, zf, float(k) / PLANKS)).y * 2.0)
			var y1 := roundf(_proj(0, _yd, lerpf(zb, zf, float(k + 1) / PLANKS)).y * 2.0)
			_p(0, y1 - 1, w2, 1, Pal.DESK_GRAIN[0])
			_p(0, y0, w2, 1, Pal.DESK_GRAIN[1])   # a beira de cada tábua pega luz
			for i in int(w2 / 60.0):   # os veios, mais compridos na frente (mais perto)
				var gx := fmod(i * 197.0 + k * 61.0, w2)
				var gy := roundf(y0 + (y1 - y0) * (0.25 + 0.5 * ((i * 7 + k) % 5) / 4.0))
				var gl := 16.0 + (i % 4) * 10.0 + k * 10.0
				_p(gx, gy, gl, 1, Pal.DESK_GRAIN[2])
				_p(gx + gl * 0.3, gy + 1, gl * 0.5, 1, Pal.DESK_GRAIN[3])
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
	_p(0, f - 2, w2, 1, Pal.DESK_EDGE[0])
	_p(0, f - 1, w2, 1, Pal.DESK_EDGE[1])
	_p(0, f, w2, 2, Pal.DESK_EDGE[2])
	_p(0, f + 2, w2, 8, Pal.DESK_EDGE[3])
	_p(0, f + 4, w2, 1, Pal.DESK_EDGE[4])   # um friso na espessura
	_p(0, f + 10, w2, 2, Pal.DESK_GRAIN[0])
	_r(r.position.x, front + 6, r.size.x, r.end.y - front - 6, Color("0a0705"))


## Na mesa, embaixo da janela, ao alcance do operador: as listas telefônicas, o bloco de fichas, a caneca de café, o
## calculógrafo e a unidade de despacho, do fundo para a frente (quem está mais perto é desenhado por cima). Cada um
## fica num lugar da sala (x a partir dos olhos, z a distância; ver `Z0`) e é desenhado em px da tela (1x1).
func _draw_desk_props() -> void:
	_ci.draw_set_transform(Vector2.ZERO)
	# em duas fileiras, distribuídas de ponta a ponta entre a lateral da mesa comutadora e a parede da direita, com a
	# mesma folga entre eles e antes do primeiro (encostado na mesa comutadora, parecia apertado), em qualquer largura de
	# janela: presos a uma ponta só, sobrava mesa vazia na outra, e presos a pontas diferentes, eles se trombavam. Atrás,
	# o que é alto: a unidade de despacho, as listas e o relógio com a caneca na frente dele; na frente: o calculógrafo (no
	# meio da unidade de despacho, alinhado com ela),
	# o bloco de fichas (era um caderno aberto, que tomava a fileira) e o lugar do jornal (guardado mesmo sem ele, para
	# nada mudar de lugar entre as noites). Todos em `PROP_K`, no tamanho de verdade; o jornal, dobrado estreito
	var r := _cx - _vp.x - WALL_PAD   # a parede da direita é o plano x = quina (na escala da parede do fundo)
	var k := PROP_K
	var cw := CLOCK.x + 2.0   # o relógio, meio virado, ocupa um pouco mais que a largura dele
	var mr := 6.6 * k         # a caneca, na frente do relógio, encostada na ponta direita dele
	# (a fileira de trás conta a folga da lateral, onde a prancheta fica pendurada; as listas ocupam mais que a largura
	# delas, com os volumes desencontrados, `BOOKS_SPAN`: sem isso, o relógio encostava na pilha)
	var back := _row(_side_x - 4.0, r, [0.0, UNIT.x * k, BOOKS_SPAN * k, cw + mr]).slice(1)   # (o 0: a mesma folga antes do primeiro)
	var cx: float = back[0] + (UNIT.x - CALC.x) * k / 2.0   # o calculógrafo no meio da unidade de despacho, logo atrás dele
	var edge := (size.x / 2.0 - EDGE_PX - _vp.x) * _at(0.06) / Z0   # perto, a parede já passou da beira da tela: o jornal vai até ela
	var near := _row(cx + CALC.x * k, minf(r, edge), [0.0, PAD_W * k, NEWS_W * k]).slice(1)   # e os outros dois depois dele
	if _here(Tools.DISPATCH):
		_draw_dispatch_unit(back[0], _at(0.6), UNIT.x * k)   # recuada: a máquina do calculógrafo, na frente dela, não tampa a base
	if _here(Tools.DIRECTORY):
		_draw_books(back[1], _at(0.54), 31 * k, _deep(0.3 * k))
	if _here(Tools.LOGBOOK):
		_flat(Tools.LOGBOOK, near[0], _at(0.06), PAD_W * k, _deep(0.26 * k), 2 * k, Pal.NOTE_PAGE.darkened(0.25), _art_pad, [], deg_to_rad(-2.0),
			_pad_marks)
	if _here("relogio"):
		_draw_flip_clock(back[2] + cw / 2.0, _at(0.72))   # logo atrás da caneca (desenhado antes dela)
	if _here(MUG_ID):
		_draw_mug(back[2] + cw, _at(0.46), mr, 13 * k)   # mais larga que alta, como as esmaltadas
	if _here(Tools.TOLL):
		_draw_calculograph(cx, _at(0.06))   # na linha do bloco de fichas
	# papel tem 1 px de beira (mais grosso, parecia tábua)
	if news and _here(Tools.NEWS):
		_flat(Tools.NEWS, near[1], _at(0.07), NEWS_W * k, _deep(0.19 * k), 0.5, Color("a89c78"), _art_newspaper, [], deg_to_rad(6.0),
			_newspaper_print)
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O calculógrafo, que abre a tarifação (`x0`, a frente em `zf`; medidas em `CALC`), como a ferramenta aberta. Atrás, a
## máquina, uma caixa baixa no material das máquinas do despacho; na frente dela, sem relógio (o da mesa fica ao lado),
## os dez contadores em duas fileiras (a plaquinha, os tambores e a luz âmbar de cada entrada contando, `counting`), a
## plaqueta de latão com a luz e a saída de ar e, embaixo, a fenda, de onde sai o bilhete (a ponta numa camada própria,
## `_tip`, `Background._draw_tip`). Na frente dela, a mesinha (o que está nela e onde, `toll_desk`): a almofada com a
## tampa aberta, os bilhetes soltos com as marcas do carimbo, a caixinha com os guardados e o carimbo em pé.
func _draw_calculograph(x0: float, zf: float) -> void:
	_yaw = 0.0
	_tip_cover = []
	var w := CALC.x * PROP_K
	var d := w * Toll.NOMINAL.y / Toll.NOMINAL.x
	var zb := zf + d   # o fundo da mesinha: a frente da máquina
	var hw := w / 2.0
	var hd := _deep(CALC.z * PROP_K) / 2.0
	var xc := x0 + hw
	var zc := zb + hd
	_desk_shadow(PackedVector2Array([_clock_pt(xc, zc, -hw, hd, _yd), _clock_pt(xc, zc, hw, hd, _yd), _clock_pt(xc, zc, hw, -hd, _yd),
		_clock_pt(xc, zc, -hw, -hd, _yd)]))
	var box := _clock_box(xc, zc, hw, hd, _yd, CALC.y * PROP_K, Pal.PANEL_HI, Pal.PANEL_LO, Pal.PANEL)
	var hull := PackedVector2Array()
	for f: PackedVector2Array in box.values():
		hull.append_array(f)
	var dark := _shade(xc, zb)
	if box.has("front"):
		var f := _bounds(box["front"])
		f = Rect2(f.position.round(), f.size.round())
		var win := Rect2(f.position.x + 3.0, f.position.y + 2.0, roundf(f.size.x * 0.76) - 3.0, 0)   # o visor, como o da aberta (`Toll._screen`)
		var cell := Vector2(floorf(win.size.x / 5.0), maxf(floorf((f.size.y - 7.0) / 2.0), 1.0))   # (sem tela, no primeiro desenho, a frente tem 1 px)
		win.size.y = cell.y * 2.0
		_ci.draw_rect(win, Pal.PANEL_LO.darkened(dark))
		for n in range(1, Exchange.LINES + 1):
			var o := win.position + Vector2((n - 1) % 5, (n - 1) / 5) * cell + Vector2(0, roundf(cell.y / 2.0) - 1.0)
			var on := (counting & (1 << n)) != 0
			_ci.draw_rect(Rect2(o + Vector2(1, 0), Vector2(2, 2)), Pal.BRASS.darkened(dark))   # a plaquinha da entrada
			_ci.draw_rect(Rect2(o + Vector2(4, 0), Vector2(cell.x - 8.0, 2)), (Pal.SHEET_NEW if on else Pal.PANEL_HI).darkened(dark))   # os tambores
			var led := Rect2(o + Vector2(cell.x - 3.0, 0), Vector2(2, 2))
			_ci.draw_rect(led, Pal.AMBER if on else Pal.AMBER.darkened(0.75))
			if on:
				_light(led, Pal.AMBER, 0.4, true)
		var side := Rect2(win.end.x + 3.0, f.position.y + 2.0, f.end.x - win.end.x - 6.0, f.size.y)
		_ci.draw_rect(Rect2(side.position, Vector2(side.size.x, 3)), Pal.BRASS.darkened(0.25 + dark))   # a plaqueta
		_ci.draw_rect(Rect2(side.position + Vector2(1, 1), Vector2(side.size.x - 2.0, 1)), Pal.BRASS.darkened(dark))
		var lamp := Rect2(side.position + Vector2(0, 6), Vector2(2, 2))
		_ci.draw_rect(lamp, Pal.AMBER if counting else Pal.AMBER.darkened(0.75))
		if counting:
			_light(lamp, Pal.AMBER, 0.6, true)
		for i in 3:   # a saída de ar
			_ci.draw_rect(Rect2(side.position.x + 4.0, side.position.y + 6.0 + i * 2.0, side.size.x - 4.0, 1), Pal.PANEL_LO.darkened(dark))
		var mw := roundf(f.size.x * TollTicket.SIZE.x / Toll.NOMINAL.x)   # a fenda, embaixo do meio dos contadores
		var mouth := Rect2(roundf(win.get_center().x - mw / 2.0), f.end.y - 3.0, mw, 1)
		_ci.draw_rect(mouth, Pal.EDGE)
		_ci.draw_rect(Rect2(mouth.position + Vector2(0, 1), mouth.size), Pal.PANEL_HI.darkened(dark))
		# a ponta do bilhete saindo dela para a mesinha fica com a camada dela, que a faz descer sem redesenhar a sala
		_tip = Rect2(mouth.position + Vector2(1, 1), Vector2(mw - 2.0, 6))
		_tip_dark = dark
		hull.append_array(PackedVector2Array([_tip.position, _tip.end]))
	var pt := func(p: Vector2, y: float) -> Vector2: return _p3(x0 + p.x * w, _yd - y, zb - p.y * d)   # um ponto da mesinha (fração dela), `y` acima
	var quad := func(r: Rect2) -> PackedVector2Array:
		return PackedVector2Array([pt.call(r.position, 0.0), pt.call(Vector2(r.end.x, r.position.y), 0.0), pt.call(r.end, 0.0),
			pt.call(Vector2(r.position.x, r.end.y), 0.0)])
	hull.append_array(quad.call(Rect2(0, 0, 1, 1)))
	if toll_desk.size() >= 4:
		dark = _shade(xc, zf + d / 2.0)
		var pad: Rect2 = toll_desk[0]
		var lid := Toll.LID / Toll.NOMINAL.x * w
		_poly(PackedVector2Array([pt.call(pad.position, lid), pt.call(Vector2(pad.end.x, pad.position.y), lid),
			pt.call(Vector2(pad.end.x, pad.position.y), 0.0), pt.call(pad.position, 0.0)]), Pal.NICKEL[3].darkened(dark))   # a tampa aberta, de costas
		_poly(quad.call(pad), Pal.NICKEL[2].darkened(dark))
		var rim := Vector2(5, 5) / Toll.NOMINAL
		_poly(quad.call(Rect2(pad.position + rim, pad.size - rim * 2.0)), TollTicket.MARK.darkened(0.5 + dark))   # o feltro
		for i in range(4, toll_desk.size()):   # os bilhetes soltos, na ordem em que estão empilhados
			var r: Rect2 = toll_desk[i][0]
			var q: PackedVector2Array = quad.call(r)
			var sh := PackedVector2Array()
			for p in q:
				sh.append(p + Vector2(1, 1))
			_poly(sh, Lift.SHADOW)
			_poly(q, TollTicket.PAPER.darkened(dark))
			_poly(quad.call(Rect2(r.position, Vector2(r.size.x, r.size.y * TollTicket.BAND / TollTicket.SIZE.y))), TollTicket.FORM.darkened(dark))
			var half := TollTicket.MARK_SIZE / TollTicket.SIZE / 2.0
			for m: Vector3 in toll_desk[i][1]:   # as marcas, cortadas no papel
				var mr := Rect2(Vector2(m.x, m.y) - half, half * 2.0).intersection(Rect2(0, 0, 1, 1))
				if mr.has_area():
					_poly(quad.call(Rect2(r.position + mr.position * r.size, mr.size * r.size)), Color(TollTicket.MARK, lerpf(0.25, 0.75, m.z)).darkened(dark))
		var bx: Rect2 = toll_desk[1]
		var shoe: Rect2 = toll_desk[3]
		var draw_box := func() -> PackedVector2Array:   # a caixinha: a madeira, a boca escura com os guardados de pé e a plaqueta na frente
			var bc := Vector2(x0 + bx.get_center().x * w, zb - bx.get_center().y * d)
			var bh := bx.size * Vector2(w, d) / 2.0
			_desk_shadow(quad.call(bx))
			var faces := _clock_box(bc.x, bc.y, bh.x, bh.y, _yd, TOLL_BOX_H, Pal.BOARD[0], Pal.BOARD[2], Pal.BOARD[1])
			var y1 := _yd - TOLL_BOX_H
			var e := 0.5
			_poly(PackedVector2Array([_clock_pt(bc.x, bc.y, -bh.x + e, bh.y - e, y1), _clock_pt(bc.x, bc.y, bh.x - e, bh.y - e, y1),
				_clock_pt(bc.x, bc.y, bh.x - e, -bh.y + e, y1), _clock_pt(bc.x, bc.y, -bh.x + e, -bh.y + e, y1)]), Color("140e09"))
			for i in mini(toll_desk[2], 3):
				var v := lerpf(bh.y - e * 3.0, -bh.y + e * 3.0, 0.3 + i * 0.25)
				_pixel_line(_clock_pt(bc.x, bc.y, -bh.x + e * 3.0, v, y1 + 0.4), _clock_pt(bc.x, bc.y, bh.x - e * 3.0, v, y1 + 0.4),
					[TollTicket.PAPER.darkened(0.3 + dark)])
			if faces.has("front"):
				var bf := _bounds(faces["front"])
				_ci.draw_rect(Rect2(roundf(bf.get_center().x - bf.size.x * 0.22), roundf(bf.get_center().y - 1.0), roundf(bf.size.x * 0.44), 2),
					Pal.BRASS.darkened(0.15 + dark))
			var out := PackedVector2Array()
			for g: PackedVector2Array in faces.values():
				out.append_array(g)
			return out
		var draw_stamp := func() -> PackedVector2Array:   # o carimbo, em pé onde a sapata está
			_desk_shadow(quad.call(shoe))
			var tex := _stamp_art()
			var foot: Vector2 = pt.call(Vector2(shoe.get_center().x, shoe.end.y), 0.0)
			var c := foot.round() - Vector2(0, tex.get_height() / 2.0)
			_sprite(tex, c, Color.WHITE.darkened(dark))
			_tip_cover = [tex, c, Color.WHITE.darkened(dark)]
			return PackedVector2Array([c - tex.get_size() / 2.0, c + tex.get_size() / 2.0])
		var near: Array = [draw_box, draw_stamp] if shoe.end.y >= bx.end.y else [draw_stamp, draw_box]   # quem está mais perto vai por cima
		for draw_it: Callable in near:
			hull.append_array(draw_it.call())
	_mark(Tools.TOLL, _bounds(hull), Geometry2D.convex_hull(hull))


## O carimbo da mesinha do calculógrafo (`STAMP_ART`), nas cores do da ferramenta.
func _stamp_art() -> ImageTexture:
	var k: Color = Switchboard.CORD_COLORS[5][0]
	var n := Pal.NICKEL
	return PixelArt.art(STAMP_ART, {"k": k.darkened(0.5), "K": k, "h": k.lerp(Switchboard.CORD_COLORS[5][1], 0.6), "g": Toll.GLINT,
		"m": Pal.BRASS, "M": Pal.BRASS.darkened(0.3), "c": n[1], "C": n[2], "d": n[3], "p": n[0], "i": Pal.INK, "b": Pal.BRASS,
		"B": Pal.BRASS.darkened(0.3), "e": Pal.EDGE})


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
		_ci.draw_rect(Rect2(a.x + 2, a.y + 1, 1, b.y - a.y), Color(0, 0, 0, 0.35))   # a sombra no lado
		for y in range(int(a.y), int(b.y)):
			_ci.draw_rect(Rect2(a.x - 1, y, 3, 1), (Color("b8b2a2") if int(y - a.y) % 2 == 0 else Color("5a574e")).darkened(dark))
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
		_ci.draw_rect(Rect2(x0 + i, y0 - 1, 1, 1), Color("dccfa8").darkened(sh))   # a quina com o tampo (sem ela, sobravam furos)


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
				_ci.draw_line(q[1], q[2], col.lightened(0.15).darkened(_shade(b.x, b.y)), 1.0)
			elif f[0] == "right":
				_ci.draw_line(q[0], q[3], col.lightened(0.15).darkened(_shade(a.x, a.y)), 1.0)
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
	if sz.y < 2:   # (a tela ainda se arrumando: o relógio minúsculo)
		return
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
## pousados por cima do tampo). Erguido (`_raised`), a sombra fica na mesa, se afasta um pouco e o escuro da base some.
func _desk_shadow(foot: PackedVector2Array) -> void:
	var off := Vector2(clampf((_bounds(foot).get_center().x - _lamp_x * 2.0) / 60.0, -6.0, 8.0), 4.0).round()
	var up := _raised()
	off += up + (off.normalized() * up.length() * 0.5).round()
	var pts := PackedVector2Array()
	for p in foot:
		pts.append(p + off)
	for g in Geometry2D.offset_polygon(pts, 1.5, Geometry2D.JOIN_MITER):
		_poly(g, Color(0, 0, 0, 0.15))
	_poly(pts, Color(0, 0, 0, 0.3))
	if up == Vector2.ZERO:
		for g in Geometry2D.offset_polygon(foot, 1.0, Geometry2D.JOIN_MITER):
			_poly(g, Color(0, 0, 0, 0.45))


## Se o objeto `id` entra neste desenho: na sala, todos menos o erguido sob o mouse (`_up_id`); na camada dele
## (`_lifted`), só ele.
func _here(id: String) -> bool:
	return (id == _up_id) == (_ci == _lifted)


## Quanto o objeto sendo desenhado saiu do lugar (px da tela): a camada dele anda inteira, e a sombra volta isso para
## ficar onde estava (na mesa, na lateral da mesa comutadora).
func _raised() -> Vector2:
	return -_lifted.position if _ci == _lifted else Vector2.ZERO


## Guarda onde ficou o objeto `id` que abre ferramenta (px da tela): o retângulo do mouse (`_props`) e o contorno (`_occ`).
func _mark(id: String, rect: Rect2, hull: PackedVector2Array) -> void:
	_props[id] = rect
	var i := occ_ids.find(id)
	if i >= 0:
		_occ[i] = hull
	else:
		_occ.append(hull)
		occ_ids.append(id)


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
	_mark(id, _bounds(foot + top), Geometry2D.convex_hull(foot + top))
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
	_ci.draw_texture(_projected[full], Vector2(at))


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
						_ci.draw_rect(Rect2(p - Vector2(3, 0), Vector2(6, 2)), col)
						_ci.draw_rect(Rect2(p - Vector2(3, 0), Vector2(6, 1)), col.lightened(0.15))
						_ci.draw_rect(Rect2(p + Vector2(-3, 2), Vector2(6, 1)), Color(0, 0, 0, 0.35))
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
	_mark(Tools.DIRECTORY, _bounds(all), Geometry2D.convex_hull(all))


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
	var img := _mug_art(int(body.size.x), int(body.size.y), int(ry), int(rb), sips)
	_ci.draw_texture(img, body.position - Vector2(0, ry), Color.WHITE.darkened(_shade(xc, zc)))
	var hull := PackedVector2Array()
	for p in _mug_hulls[Vector4i(int(body.size.x), int(body.size.y), int(ry), int(rb))]:
		hull.append(p + body.position - Vector2(0, ry))
	_mark(MUG_ID, _bounds(hull), hull)


## A caneca esmaltada de frente, com `w` de largura e `h` da boca ao pé (px), a boca e o pé em elipses de meia altura
## `ry` e `rb`: o corpo sombreado como um cilindro pela luz da luminária (do alto à esquerda: o brilho numa coluna, a
## sombra à direita, em tons fixos de pixel art), a borda azul-marinho em volta da boca e o filete dela no pé, o lado de
## dentro com o café embaixo (a luz da luminária refletida nele), a alça em C do lado da sombra e duas lascas no esmalte
## mostrando o ferro. Guardada por tamanho e pelos goles já tomados (`drunk`: o café mais baixo; acabado, só a borra no fundo).
static var _mugs := {}
static var _mug_hulls := {}   # o contorno de cada caneca (px dela), da mesma chave


func _mug_art(w: int, h: int, ry: int, rb: int, drunk: int) -> ImageTexture:
	var key := [w, h, ry, rb, drunk]
	if _mugs.has(key):
		return _mugs[key]
	var low := float(drunk) / MUG_SIPS   # o quanto o café já baixou
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
				var f := Vector2(e.x / (0.78 - low * 0.2), (e.y - 0.3 - low * 0.4) / (0.62 - low * 0.3))   # o café, mais baixo que a boca
				if low >= 1.0:
					f = Vector2(e.x / 0.4, (e.y - 0.68) / 0.16)   # acabado: a borra no fundo
				if f.length_squared() < 1.0:
					c = Color("2e1c10") if low < 1.0 else Color("3a2618")
					if low < 1.0 and f.y > -0.55 and f.y < -0.2 and f.x > -0.55 and f.x < -0.05:
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
	var hk := Vector4i(w, h, ry, rb)   # (o contorno não muda com o café)
	if _mug_hulls.has(hk):
		return tex
	var bm := BitMap.new()   # o contorno dela, pelo que não é transparente (o relâmpago não passa por ela)
	bm.create_from_image_alpha(img)
	var pts := PackedVector2Array()
	for poly in bm.opaque_to_polygons(Rect2i(Vector2i.ZERO, img.get_size()), 1.0):
		pts.append_array(poly)
	_mug_hulls[hk] = Geometry2D.convex_hull(pts)
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
	_ci.draw_rect(front, Pal.PANEL.darkened(dark))
	_ci.draw_rect(Rect2(front.position, Vector2(front.size.x, 1)), Pal.PANEL_HI.darkened(dark))
	_ci.draw_rect(Rect2(front.position.x, front.end.y - 1, front.size.x, 1), Pal.EDGE)
	var mid := front.position.y + floorf(front.size.y / 2.0)
	var plate := Rect2(front.position.x + roundf(front.size.x * 0.36), mid - 2, roundf(front.size.x * 0.28), 4)
	_ci.draw_rect(plate, Pal.BRASS.darkened(0.25 + dark))   # a plaqueta do fabricante
	_ci.draw_rect(plate.grow(-1), Pal.BRASS.darkened(dark))
	for i in 3:   # a saída de ar, à direita
		_ci.draw_rect(Rect2(front.end.x - roundf(front.size.x * 0.22), mid - 2 + i * 2, roundf(front.size.x * 0.16), 1), Pal.PANEL_LO)
	for l: Array in [[0.06, alert, Pal.RED], [0.14, card_out, Pal.AMBER]]:   # as luzes: ocorrência e cartão na mesa
		var lr := Rect2(front.position.x + roundf(front.size.x * l[0]), mid - 1, 3, 3)
		_ci.draw_rect(lr.grow(1), Pal.EDGE)
		_ci.draw_rect(lr, l[2] if l[1] else (l[2] as Color).darkened(0.75))
		if l[1]:
			_light(lr, l[2], 0.6, true)
	all.append_array(top + glass + deck)
	all.append_array(PackedVector2Array([front.position, front.end, Vector2(front.position.x, front.end.y)]))
	_mark(Tools.DISPATCH, _bounds(all), Geometry2D.convex_hull(all))


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


## O bloco de fichas de ocorrência (a ficha da noite vai para o supervisor no fim do turno), de pé no tampo: a folha de
## cima, creme (não branca: chamava mais o olho que tudo), e, no alto, a fita de pano da colagem com a sombra dela na
## folha. A espessura do bloco é a beira das folhas, pelo `_flat`; o impresso, a pauta e a letra de mão vão por cima,
## na tela (`_pad_marks`).
func _art_pad(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.NOTE_PAGE)
	var t := _pad_tape(sz)
	_fr(img, 0, 0, sz.x, 1, Pal.PAD_TAPE[0])   # a fita: a dobra de cima na luz...
	_fr(img, 0, 1, sz.x, t - 2, Pal.PAD_TAPE[1])
	_fr(img, 0, t - 1, sz.x, 1, Pal.PAD_TAPE[2])   # ...e a beira de baixo, na sombra
	_fr(img, 0, t, sz.x, 1, Pal.NOTE_PAGE.darkened(0.15))   # a sombra dela na folha
	_fr(img, sz.x - 1, t, 1, sz.y - t, Pal.NOTE_PAGE.darkened(0.08))   # a beira da direita, longe da luz
	_fr(img, 0, sz.y - 1, sz.x, 1, Pal.NOTE_PAGE.darkened(0.1))
	return img


## A altura da fita da colagem no desenho do bloco de fichas (`sz`): uns 10% da folha (com 7, de longe era um fio), nunca menos de 3 px.
func _pad_tape(sz: Vector2i) -> int:
	return maxi(3, roundi(sz.y * 0.1))


## Por cima do bloco de fichas, na tela: o impresso da ficha (o título e o fio vermelho embaixo dele, como o cabeçalho
## da ficha aberta), a pauta a 3 px da tela uma linha da outra (`_rows`) com a margem vermelha, a letra de mão (a hora
## antes da margem e umas palavras depois, linha sim, linha não: cheia, era ruído), as tiras dos registros pendentes
## saindo de baixo dele, por trás (uma por registro, até seis), e o lápis apoiado na folha, em pixel art na tela (torto
## pela perspectiva, serrilhava).
func _pad_marks(sz: Vector2i) -> void:
	var t := _pad_tape(sz)
	var rows := _rows(t + 2.0, sz.y - 3.0, 3.0)
	var mx := roundf(sz.x * 0.16)   # a margem, depois da coluna da hora (a da ficha aberta)
	for row in rows.size():
		var y: float = rows[row]
		if row == 0:   # o título impresso, em tipos iguais
			for x in range(3, int(sz.x * 0.62), 4):
				_ink(x, x + 2.0, y - 1.0, [Pal.INK_SOFT])
			continue
		_ink(2.0, sz.x - 2.0, y, [Pal.FORM_RED if row == 1 else Pal.NOTE_RULE])
		if row < 2 or row % 2 == 1 or row > rows.size() - 3:
			continue
		_ink(3.0, mx - 3.0, y - 1.0, [Color("6a6474")])   # a hora
		var a := _tex_pt(Vector2(mx + 3.0, y)) - Vector2(0, 1)   # as palavras, logo acima da pauta
		var b := _tex_pt(Vector2(mx + 3.0 + (sz.x - mx - 8.0) * (0.45 + 0.1 * ((row * 3) % 5)), y)) - Vector2(0, 1)
		var w := 0.0
		var span := a.distance_to(b)
		while w < span:
			var n := 3.0 + (int(w) * 3 + row * 5) % 4
			_pixel_line(a.lerp(b, w / span), a.lerp(b, minf(w + n - 1.0, span) / span), [Color("6a6474")])
			w += n + 2.0
	if rows.size() > 1:   # a margem vermelha, impressa, do fio do cabeçalho para baixo
		_pixel_line(_tex_pt(Vector2(mx, rows[1])), _tex_pt(Vector2(mx, sz.y - 2)), [Pal.NOTE_MARGIN])
	for i in mini(pending, 6):
		var p := _tex_pt(Vector2(5 + i * floorf((sz.x - 12) / 6.0), 0)).round()
		var up := 6.0 + (i * 5) % 4
		var col := Pal.PENDING[i % 2]
		_ci.draw_rect(Rect2(p.x, p.y - up, 6, up + 2), col)
		_ci.draw_rect(Rect2(p.x + 5, p.y - up, 1, up + 2), col.darkened(0.2))   # o lado na sombra
		_ci.draw_rect(Rect2(p.x, p.y - up, 5, 1), col.lightened(0.12))   # a beira de cima, na luz
		_ci.draw_rect(Rect2(p.x + 1, p.y - up + 2, 3, 1), Pal.FORM_RED)
		_ci.draw_rect(Rect2(p.x, p.y + 1, 6, 1), Color(0, 0, 0, 0.3))   # onde ela entra embaixo do bloco
	var a := _tex_pt(Vector2(sz.x * 0.5, sz.y - 4)).round()
	var b := _tex_pt(Vector2(sz.x - 5, t + 5)).round()
	var d := (b - a).normalized()
	_pixel_line(a + Vector2(2, 2), b + d * 7 + Vector2(2, 2), [Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3)])
	_pixel_line(a, b, [Color("c4a042"), Color("957622"), Color("67521a")])   # o corpo, amarelo de lápis gasto
	_pixel_line(a - d * 4, a, [Color("c8aa80"), Color("b0926a"), Color("8a7050")])   # a madeira apontada
	_pixel_line(a - d * 6, a - d * 4, [Color("2a2620")])   # o grafite
	_pixel_line(b, b + d * 4, Pal.NICKEL.slice(1))   # a ponteira, no níquel da mesa
	_pixel_line(b + d * 4, b + d * 7, [Color("c08a80"), Color("a86a62"), Color("7a4a44")])   # a borracha


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
	# o prendedor de níquel na beira de cima, na perspectiva da prancheta: o corpo (a luz no alto, a sombra embaixo e
	# a da folha), a alavanca por cima e o prego no furo dela
	var quad := func(x0: float, x1: float, y0: float, y1: float, off := Vector2.ZERO) -> PackedVector2Array:
		return PackedVector2Array([_tex_pt(Vector2(x0, y0)) + off, _tex_pt(Vector2(x1, y0)) + off, _tex_pt(Vector2(x1, y1)) + off,
			_tex_pt(Vector2(x0, y1)) + off])
	var a := sz.x * 0.2
	var c := sz.x * 0.8
	_poly(quad.call(a, c, 1.0, 6.0, Vector2(1, 2)), Color(0, 0, 0, 0.35))
	_poly(quad.call(a, c, 1.0, 6.0), Pal.NICKEL[2])
	_pixel_line(_tex_pt(Vector2(a, 1.0)), _tex_pt(Vector2(c, 1.0)), [Pal.NICKEL[0]])
	_pixel_line(_tex_pt(Vector2(a, 5.0)), _tex_pt(Vector2(c, 5.0)), [Pal.NICKEL[3]])
	_pixel_line(_tex_pt(Vector2(sz.x * 0.35, -1.0)), _tex_pt(Vector2(sz.x * 0.65, -1.0)), [Pal.NICKEL[1], Pal.NICKEL[3]])
	_poly(quad.call(sz.x * 0.45, sz.x * 0.55, -5.0, -3.0), Pal.NICKEL[3])


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
