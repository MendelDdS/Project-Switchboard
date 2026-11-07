extends "res://scripts/ui/background_view.gd"
## Os objetos da mesa do cenário (`Background`) e o tampo: listas, unidade de despacho, bloco de fichas, calculógrafo, jornal,
## caneca e o relógio de flip (e a prancheta, pendurada na lateral da mesa comutadora), cada um posto na sala e passado pela câmera (`_box`, `_flat`, `_project`).

const DESK_T := 1.25    ## o fundo do tampo, Z0/DESK_T: a mesa fica afastada da parede (o gaveteiro cabe atrás)
const PLANKS := 6       ## as tábuas do tampo, todas da mesma largura (a câmera as espaça)
const POOL_R := 112.0   ## o raio da poça de luz da luminária no tampo
const DESK_SPILL := 30.0   ## até onde as luzes acesas dos objetos (a unidade de despacho, o calculógrafo) iluminam o tampo em volta (px)
## O miolo quente da poça (a fração do raio dela e a força): só clareia o meio da mesa, para o olho cair nos objetos;
## as pontas, com o relógio, ficam na luz de sempre.
const POOL_HOT := Vector2(0.42, 0.16)
const SHADE_MAX := 0.3   ## o mais escuro que um objeto da mesa fica, longe da poça de luz (`_shade`)
const FRONT_LIGHT := 1.6   ## da poça para a frente da mesa, a luz vai essa vez mais longe (`_shade`, `_noir_params`): a fileira da frente ficava escura demais
const DESK_RAG := 0.16     ## o quanto a borda de cada faixa de luz do tampo anda de uma linha para outra, em raios da poça (`_desk_row`)
const PAPER_RAG := 0.12    ## o mesmo nos papéis da mesa, na luz parada (`_lit_at`)
const WALL_PAD := 2.0           ## a folga dos objetos da mesa até a parede da direita (x da sala)
const MUG_ID := "caneca"   ## a caneca: sob o mouse se ergue como os objetos das ferramentas; clicada, um gole (`Background.sip`)
const MUG_SIPS := 5       ## os goles do café da caneca
const TAPES_ID := "fitas"   ## a pilha das fitas tiradas do gravador (B4): sob o mouse se ergue; clicada, abre de perto (`tapes_clicked`)
const EDGE_PX := 8.0            ## e a da fileira da frente até a beira da tela (px de 2x2): perto, a parede já passou dela, e o jornal saía cortado
const PROP_K := 0.75 * 93.0 / 66.0   ## a escala dos objetos da mesa: no tamanho de verdade deles na sala (`_cm`; as listas com 21 cm), maiores que o plug em pé (uns 9 cm)
## A unidade de despacho (`_draw_dispatch_unit`, na escala dos objetos, `PROP_K`): largura, altura da base e fundo da
## base até o painel (fração do tampo); o painel: a altura acima da base, o quanto o alto dele recua (fração do tampo,
## para ficar inclinado, de frente para os olhos) e o fundo do móvel todo (fração do tampo).
const UNIT := Vector3(47, 7.5, 0.17)   # (era 39 × 6 × 16 de painel: do tamanho das listas, pequena demais perto dos outros objetos)
const BOOKS_SPAN := 40.0   ## o lugar das listas na fileira (na escala dos objetos): os 31 delas mais os volumes desencontrados e a lombada
const UNIT_PANEL := 20.0
const PAD_W := 26.0    ## a largura do bloco de fichas (na escala dos objetos, uns 18 cm; o caderno aberto, com 46, tomava a fileira da frente)
## Onde o lápis fica largado no bloco de fichas, um lugar a cada ficha registrada (`written`): [a ponta, a borracha],
## em fração da folha abaixo da fita (x da largura, y da altura dela).
const PENCIL := [[Vector2(0.5, 0.88), Vector2(0.96, 0.18)], [Vector2(0.28, 0.82), Vector2(0.8, 0.5)],
	[Vector2(0.9, 0.86), Vector2(0.44, 0.2)], [Vector2(0.14, 0.3), Vector2(0.64, 0.9)]]
## A fita cassete deitada na mesa (as entregues, `tapes_out`, na escala dos objetos, `PROP_K`), de comprido para o fundo
## (de frente, com 10 cm de largura, não cabia ao lado do bloco de fichas): largura (6,4 cm), fundo (10 cm, fração do
## tampo) e grossura; giradas um pouco, cada uma para um lado (`TAPE_YAW`).
const TAPE := Vector3(9.2, 0.2, 1.7)
const TAPE_YAW := [-5.0, 4.0, -2.0, 7.0]
const LETTER_W := 19.0   ## a largura do envelope da carta (uns 12 cm), em cima do diário...
const LETTER_D := 0.62   ## ...e o fundo dele, em fração do fundo do jornal dobrado
const DIARY_W := 20.0   ## o diário de Maria, no lugar do jornal (que foi para o quadro de avisos): a largura (uns 13 cm, um caderno pequeno), o fundo (fração do tampo) e a grossura
const DIARY_D := 0.12
const DIARY_H := 1.5
const NEWS_W := 25.0   ## o lugar do diário na fileira da frente, o do jornal dobrado que ficava ali (na escala dos objetos, uns 16 cm): com 32, o calculógrafo não cabia do lado
const UNIT_TILT := 0.11
const UNIT_D := 0.3
const UNIT_AT := 0.76   ## a frente da unidade de despacho (fração do tampo): recuada, com folga da máquina do calculógrafo na frente dela (com 0,6, a de 34 tampava a base)
## O calculógrafo (`_draw_calculograph`, na escala dos objetos, `PROP_K`): a largura (uns 18 cm, com o bilhete de 6; com
## 14, o carimbo tinha 2 cm e o plug parecia gigante; com 22, larga e baixa demais perto da aberta), a altura da máquina,
## na proporção da da ferramenta (632 × 104), e o fundo dela (fração do tampo); na frente dela, a mesinha dela, na
## proporção da mesa da ferramenta (`Toll.NOMINAL`).
const CALC := Vector3(38, 6.25, 0.06)   # (era 28, depois 34: uma tira fina perto da unidade de despacho e das listas; com 42, tampava a base dela)
const CALC_AT := 0.045   ## a frente da mesinha do calculógrafo (fração do tampo): mais perto da beira que o bloco de fichas (0,06), com folga da unidade de despacho atrás
const CABLE_STEPS := 24   # os trechos retos da curva de cada fio das máquinas até o fundo da mesa (`_draw_cable`)
const CABLE_SAG := 0.12   # o quanto cada um já recua ao sair da máquina, até o fundo da mesa
const CABLE_D := 2.0   # a grossura deles (na sala; na tela, 4 a 6 px pela distância: com 3, não cabem as faixas do cilindro)
const CABLE_LIGHT := Vector2(0.45, -0.9)   # de onde vem a luz neles (a luminária, no alto à direita): o brilho fica desse lado
const CABLE_SHADE := Vector2(-1, 2)   # a sombra deles no tampo, do outro lado (px)
const TOLL_BOX_H := 4.5   ## a altura da caixinha dos bilhetes (na sala, uns 2 cm)
## O carimbo em pé na mesinha, como o da ferramenta (`Toll.STAMP`, 88 × 201, na proporção de um datador de verdade, uns 10 cm de alto
## por 4,5 de largo), em 21 × 50 px: do tamanho do plug guardado da mesa comutadora, que tem 48 à mostra (com 25 e 31 de
## largura, crescia para os lados e ficava atarracado): o cabo de baquelite em cogumelo,
## com o medalhão de latão no tampo e as faixas de luz de um cilindro (as do da ferramenta, `Toll.BAND_U`), afinando até
## o anel e a haste de níquel; o corpo com o tampo à vista e a plaqueta escrita; as rodas de latão com os tipos sujos de
## tinta e as pontas do eixo; as pernas e a sapata vazada. (Antes, o cabo era um disco escuro com dois pontos de latão
## e as rodas, um xadrez: parecia um robozinho.)
const STAMP_ART := [
	".......kkkkkkk.......",
	".....kKKKKKKKKKk.....",
	"....kKKKKKKKKKKKk....",
	"....kKKKMmmmMKKKk....",
	"....kKKKmllmmKKKk....",
	"....kKKKmlmmmKKKk....",
	"....kKKKMmmmMKKKk....",
	"....khhHhhKKjjjkk....",
	"....khhHhhKKjjjkk....",
	".....khHhhKKjjkk.....",
	"......khHhKKjjk......",
	".......kHhKjjk.......",
	"........khKjk........",
	"........khKjk........",
	"........khKjk........",
	"........khKjk........",
	".......kHhKjjk.......",
	".......dppcCdd.......",
	".........pcC.........",
	".........pcC.........",
	".cpppppppnCnpppppppC.",
	".cpppppppppppppppppC.",
	".cpppppppppppppppppC.",
	".cpppppppppppppppppC.",
	".cpppppppppppppppppC.",
	".pncccccccccccccccCd.",
	".pncpppppppppppppcCd.",
	".pncppiiiiiiiiippcCd.",
	".pncpppppppppppppcCd.",
	".pncpppiiiiiiipppcCd.",
	".pncpppppppppppppcCd.",
	".pncccccccccccccccCd.",
	".ddddddddddddddddddd.",
	"CcpllllllllllllllnCdC",
	"nCpbbbBbbbBbbbBbbbCdn",
	"CcpBrBBBrBBBrBBBrBCdC",
	".cp...............Cd.",
	".cp...............Cd.",
	".cp...............Cd.",
	".cp...............Cd.",
	".cp...............Cd.",
	".cp...............Cd.",
	".cp...............Cd.",
	".cp...............Cd.",
	".cp...............Cd.",
	"cpppppppppppppppppppd",
	"cpp...............Cpd",
	"cpp...............Cpd",
	"cpppppppppppppppppppd",
	"CCCCCCCCCCCCCCCCCCCCd",
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
var pending := PackedColorArray()   ## registros esperando no bloco de fichas: uma tira de papel saindo dele por registro, na cor do tipo
var unread := false  ## o registro das conversas tem fala nova: uma folha nova presa na prancheta
var alert := false     ## há uma emergência em andamento: a luz vermelha da unidade de despacho (o Main atualiza)
var card_out := false  ## há um cartão perfurado na mesa: ele sai da fenda da impressora da unidade, com a luz âmbar
var news := false    ## o jornal da manhã está pregado no quadro de avisos (da segunda noite em diante; `Main.set_news`)
var letter := false   ## há carta na noite (`Night.letter_for`, `Main`): um envelope lacrado em cima do diário...
var letter_read := false   ## ...que, aberta, volta sem o lacre
var diary_new := false   ## Maria anotou tarefa nova: o lápis atravessado em cima do diário até ele abrir (`Main`, `Diary.added`)
var written := 0     ## fichas registradas na noite: o lápis fica num lugar do bloco a cada uma (`PENCIL`)
var tapes_out: Array = []   ## as fitas tiradas do gravador na noite (B4, posto pelo gravador), cada uma pelo destino (`Tape.To`: 0 a fita, 1 o pacote branco de Sebastião, 2 o amarelo das autoridades): empilhadas ao lado do bloco de fichas até o fim do turno
var counting := 0    ## as entradas contando um interurbano, um bit cada (`Toll.counters`): os contadores acesos do calculógrafo
var toll_desk := []  ## o que está na mesinha do calculógrafo e onde (`Toll.layout`; o Main só passa com a ferramenta fechada)
var clock_x := 0.0   ## onde o relógio está na tela (x global): de lá vêm a badalada das horas e a campainha do turno
var _yaw := 0.0   # quanto o relógio da mesa está girado (rad; `_draw_flip_clock`)
var _props := {}       # objeto que abre ferramenta -> retângulo dele (px da tela), do último desenho
var _tape_next := Rect2()   # o tampo da próxima fita entregue na pilha (`tape_spot`), do último desenho
var sips := 0   ## os goles já tomados do café: ele baixa na caneca (`_mug_art`) e, acabado, o vapor some
var _up_id := ""       # o objeto erguido sob o mouse, subindo ou assentando ("" = nenhum): fica na camada dele (`_lifted`), não na sala
var _mug_rim := []     # a caneca na tela (o corpo e a meia altura da boca), para a beira acesa pelo sol (`Background._draw_sun_edge`)
var _clock_rim := {}   # as faces do relógio na tela (`_clock_box`), para o mesmo
var _lamp_x := 0.0     # onde está a luminária, no meio da tela (px de 2x2): a luz na mesa e a sombra dos objetos dependem dela
var _zd := Vector2.ZERO   # a frente e o fundo do tampo (z)
var _side_x := 0.0     # a lateral da mesa comutadora na sala (x): os objetos da mesa ficam à direita dela
static var _cable_art := {}   # os fios já montados (das máquinas e da caixa na parede): [pontos, grossura, beira, tons, sombra] -> [canto, textura] (`_cable_at`)
var _tip := Rect2()   # a ponta do bilhete saindo da fenda do calculógrafo, inteira (px da tela; a camada dela a desenha)
var _tip_tones: Array = [Pal.TICKET, Pal.TICKET_EDGE]   # o bilhete e a beira dele na luz da fenda
var _nags := {}   # objeto (`Tools`) -> os papéis esquecidos nele, cada um o quadrilátero dele na tela: a camada `_nag_layer` os faz pulsar
var _rising := -1   # a tira do registro novo subindo do bloco de fichas (o índice dela; -1: nenhuma): a sala não a desenha...
var _slip := []     # ...e a camada `_slip_layer` desenha, com isto: [onde ela entra embaixo do bloco, a altura toda, a cor]
var _tip_cover: Array = []   # o carimbo em pé na mesinha [textura, meio, cor]: fica na frente da fenda, e a camada da ponta o desenha de novo por cima dela
var _hom := Basis()          # a perspectiva do objeto chato sendo desenhado (`_flat`, `_homography`): o que vai por cima dele, na tela
var _hom_sz := Vector2.ONE   # o tamanho do desenho de frente dele (px)
var _hom_light := PackedFloat32Array()   # a luz parada nos cantos dele (`_still`; fundo-esq, fundo-dir, frente-dir, frente-esq), se for papel: cada pixel troca de tom por ela (`_lit_at`)
var _occ: Array = []         # os objetos da mesa (px da tela, convexos): o que fica na frente da parede e do gaveteiro
var occ_ids := PackedStringArray()   # quem é cada um de `_occ` (o id da ferramenta, "relogio", "caneca"; o teste da mesa usa)
var _mug_mouth := Vector2.ZERO   # o meio do café na caneca (px da tela), de onde sobe o vapor
var _mug_w := 0.0               # a largura da caneca na tela (px; 0 = ainda não desenhada)
var _mug_glint := Rect2()       # o risco da luz da luminária no café (px da tela), onde ela treme (`_draw_glint`)
var _lamp_shades: Array[PackedVector2Array] = []   # as sombras da luminária no tampo (`_desk_shadow`), para a camada delas


## Em que passo da virada está a plaqueta do relógio (0 a 2; 3 = parada).
func _flip_step() -> int:
	return mini(3, int((PixelArt.ms() - _flip_at) / (FLIP_SEC * 1000.0 / 3.0)))


## Tampo de madeira visto de cima e da frente, de `r.position.y` (o fundo dele) até `front` (a borda da frente,
## com a espessura do tampo embaixo): tábuas compridas de um lado ao outro, sem juntas (com juntas parecia assoalho),
## com as emendas mais juntas no fundo e mais espaçadas na frente, e o fundo mais escuro. A madeira escolhe o tom pela
## luz de cada lugar (`Pal.desk`, `_shade`), em faixas em volta da poça: quente embaixo da luminária e fria longe dela,
## e os veios, a beira e a emenda de cada tábua acima e abaixo do tom do lugar. Por cima, a poça de luz quente da
## luminária, lisa (a luz da janela, de lado, vem com a parede da direita).
func _draw_desk(r: Rect2, front: float) -> void:
	var depth := front - r.position.y
	var w2 := r.size.x * 2.0
	var zf := _desk_z(front * 2.0)
	if desk_art:
		_ci.draw_texture_rect(desk_art, Rect2(r.position, Vector2(r.size.x, depth)), true)
	else:
		var wood := _bands(func(lit: float) -> Color: return Pal.desk(lit))
		var tones := func(step: int) -> PackedColorArray:
			var out := PackedColorArray()
			for b: Array in wood:
				out.append(Pal.desk(b[1], step))
			return out
		var base: PackedColorArray = tones.call(0)
		var bright: PackedColorArray = tones.call(1)
		var seam: PackedColorArray = tones.call(-2)
		var under: PackedColorArray = tones.call(-1)
		_r(r.position.x, r.position.y, r.size.x, depth, base[0])
		for y in range(int(r.position.y * 2.0), int(front * 2.0)):   # as faixas de dentro, linha a linha
			_desk_row(y, 1, 0, w2, _desk_z(y), wood, base, 1)
		# as emendas: tábuas da mesma largura, espaçadas pela câmera (mais juntas no fundo)
		var zb := Z0 / DESK_T
		for k in PLANKS:
			var za := lerpf(zb, zf, float(k) / PLANKS)
			var zc := lerpf(zb, zf, float(k + 1) / PLANKS)
			var y0 := roundf(_proj(0, _yd, za).y * 2.0)
			var y1 := roundf(_proj(0, _yd, zc).y * 2.0)
			_desk_row(y1 - 1, 1, 0, w2, zc, wood, seam)
			_desk_row(y0, 1, 0, w2, za, wood, bright)   # a beira de cada tábua pega luz
			for i in int(w2 / 60.0):   # os veios, mais compridos na frente (mais perto)
				var gx := fmod(i * 197.0 + k * 61.0, w2)
				var gy := roundf(y0 + (y1 - y0) * (0.25 + 0.5 * ((i * 7 + k) % 5) / 4.0))
				var gl := 16.0 + (i % 4) * 10.0 + k * 10.0
				var gz := _desk_z(gy)
				_desk_row(gy, 1, gx, gx + gl, gz, wood, bright)
				_desk_row(gy + 1, 1, gx + gl * 0.3, gx + gl * 0.8, gz, wood, under)   # e a sombra dele
		for k in 2:   # o fundo escurece de leve (sem linha na quina: com ela parecia o rodapé de um chão)
			_r(r.position.x, r.position.y, r.size.x, depth * (0.16 - k * 0.08), Color(0, 0, 0, 0.04))
	# a luz da luminária: um círculo no tampo, embaixo dela (que fica um pouco à frente do fundo da mesa), liso e mais
	# forte no meio; o que passaria do fundo do tampo fica na parede (o arco de `_draw_wall_light`)
	var pool := _pool()
	for ring: Vector3 in [Vector3(1.0, 0.22, 0.0), Vector3(POOL_HOT.x, POOL_HOT.y, 1.0)]:   # a poça e, por cima, o miolo dela, mais quente
		var pts := PackedVector2Array()
		for i in 32:
			var a := TAU * i / 32.0
			pts.append(_proj(pool.x + cos(a) * POOL_R * ring.x, _yd, clampf(pool.y + sin(a) * POOL_R * 0.5 * ring.x, 40.0, Z0 / DESK_T)))
		_light_fan(_proj(pool.x, _yd, pool.y), pts, Color(1.0, 0.78 + 0.08 * ring.z, 0.48 + 0.12 * ring.z, ring.y))
	# a borda da frente (`Pal.DESK_EDGE_ROWS`): o canto arredondado do tampo pega a luz, a espessura dele com um friso e,
	# embaixo, o escuro sob a mesa; cada faixa no tom da luz ali (`Pal.desk_edge`)
	var edge := _bands(func(lit: float) -> Color: return Pal.desk_edge(lit))
	for row: Array in Pal.DESK_EDGE_ROWS:
		var cols := PackedColorArray()
		for b: Array in edge:
			cols.append(Pal.desk_edge(b[1], row[2]))
		_desk_row(front * 2.0 - 2.0 + row[0], row[1], 0, w2, zf, edge, cols)
	_r(r.position.x, front + 6, r.size.x, r.end.y - front - 6, Pal.DESK_UNDER)


## Na mesa, embaixo da janela, ao alcance do operador: as listas telefônicas, o bloco de fichas, a caneca de café, o
## calculógrafo e a unidade de despacho, do fundo para a frente (quem está mais perto é desenhado por cima). Cada um
## fica num lugar da sala (x a partir dos olhos, z a distância; ver `Z0`) e é desenhado em px da tela (1x1).
func _draw_desk_props() -> void:
	_ci.draw_set_transform(Vector2.ZERO)
	_snap = true
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
	if _here(Tools.DISPATCH):   # o fio antes da máquina, que tapa a ponta dele (sai da traseira dela; o do calculógrafo saiu a pedido)
		_draw_cable(back[0], _at(UNIT_AT) + _deep(UNIT_D * k), 7.0)
		_draw_dispatch_unit(back[0], _at(UNIT_AT), UNIT.x * k)
	if _here(Tools.DIRECTORY):
		_draw_books(back[1], _at(0.54), 31 * k, _deep(0.3 * k))
	if _here(Tools.LOGBOOK):
		_flat(Tools.LOGBOOK, near[0], _at(0.06), PAD_W * k, _deep(0.26 * k), 2 * k, Pal.NOTE_PAGE.darkened(0.25), _art_pad, [], deg_to_rad(-2.0),
			_pad_marks)
	_draw_tapes(cx + CALC.x * k, near[0], _at(0.06) + (_deep(0.26 * k) - _deep(TAPE.y * k)) / 2.0)
	if _here("relogio"):
		_draw_flip_clock(back[2] + cw / 2.0, _at(0.72))   # logo atrás da caneca (desenhado antes dela)
	if _here(MUG_ID):
		_draw_mug(back[2] + cw, _at(0.46), mr, 13 * k)   # mais larga que alta, como as esmaltadas
	if _here(Tools.TOLL):
		_draw_calculograph(cx, _at(CALC_AT))
	# papel tem 1 px de beira (mais grosso, parecia tábua)
	var dx: float = near[1] + (NEWS_W - DIARY_W) * k / 2.0
	if _here(Tools.DIARY):
		_flat(Tools.DIARY, dx, _at(0.07), DIARY_W * k, _deep(DIARY_D * k), DIARY_H * k, Pal.BOOK_LEAVES.darkened(0.2), _art_diary, [],
			deg_to_rad(-4.0), _diary_marks.bind(diary_new))
	if letter and (_up_id in [Tools.LETTER, Tools.DIARY]) == (_ci == _lifted):   # em cima do diário: erguido o diário, ela sobe junto
		var ld := _deep(DIARY_D * k) * LETTER_D
		var yd := _yd
		_yd -= DIARY_H * k   # (a grossura do diário embaixo dela)
		_flat(Tools.LETTER, dx + (DIARY_W - LETTER_W) * k * 0.4, _at(0.07) + (_deep(DIARY_D * k) - ld) / 2.0, LETTER_W * k, ld, 0.5,
			Pal.SHEET_NEW.darkened(0.25), _art_envelope.bind(letter_read), [letter_read], deg_to_rad(-3.0),
			_envelope_seal.bind(letter_read))
		_yd = yd
	_snap = false
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O diário de Maria fechado (`sz`, de frente): a capa de pano vinho com o grão, a lombada à esquerda, a etiqueta
## colada e os cantos gastos.
func _art_diary(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	for y in sz.y:
		for x in sz.x:
			var g := (x * 73 + y * 151 + x * y * 7) % 97
			img.set_pixel(x, y, Pal.DIARY_COVER[1].darkened(0.08) if g < 8 else Pal.DIARY_COVER[1])
	var spine := maxi(2, sz.x / 9)
	_fr(img, 0, 0, spine, sz.y, Pal.DIARY_COVER[2])   # a lombada, de pano mais escuro, e o vinco dela
	_fr(img, spine, 0, 1, sz.y, Pal.DIARY_COVER[0])
	_fr(img, 0, 0, sz.x, 1, Pal.DIARY_COVER[0])   # as beiras: a de trás na luz, as longe dela na sombra
	_fr(img, sz.x - 1, 0, 1, sz.y, Pal.DIARY_COVER[2])
	_fr(img, 0, sz.y - 1, sz.x, 1, Pal.DIARY_COVER[2])
	var lab := Rect2i(spine + (sz.x - spine) / 3, sz.y / 4, (sz.x - spine) / 3, maxi(3, sz.y / 4))   # a etiqueta, amarelada
	_fr(img, lab.position.x, lab.position.y, lab.size.x, lab.size.y, Pal.DIARY_PAGE.darkened(0.12))
	_fr(img, lab.position.x, lab.end.y - 1, lab.size.x, 1, Pal.DIARY_PAGE.darkened(0.3))
	_fr(img, lab.position.x + 2, lab.position.y + lab.size.y / 2, lab.size.x - 4, 1, Pal.DIARY_HAND)   # o nome dela, a lápis
	for p: Vector2i in [Vector2i(sz.x - 1, 0), sz - Vector2i.ONE]:   # os cantos de fora, gastos
		img.set_pixel(p.x, p.y, Pal.DIARY_COVER[0])
	return img


## Por cima do diário fechado: o lápis atravessado, enquanto há tarefa nova que Maria anotou e o jogador não viu (`new`).
func _diary_marks(sz: Vector2i, new: bool) -> void:
	if new:
		_pencil(_tex_pt(Vector2(sz.x * 0.2, sz.y * 0.85)).round(), _tex_pt(Vector2(sz.x * 0.85, sz.y * 0.15)).round(), Vector2(sz) / 2.0)


## O envelope da carta (`sz`, de frente): papel claro com a aba fechada em V; aberta (`read`), a aba solta, um pouco
## erguida. O lacre vai por cima, na tela (`_envelope_seal`).
func _art_envelope(sz: Vector2i, read := false) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.SHEET_NEW)
	_fr(img, sz.x - 1, 0, 1, sz.y, Pal.SHEET_NEW.darkened(0.1))   # as beiras longe da luz
	_fr(img, 0, sz.y - 1, sz.x, 1, Pal.SHEET_NEW.darkened(0.12))
	var tip := Vector2i(sz.x / 2, roundi(sz.y * 0.55))
	for x in sz.x:   # a aba: as duas beiras do V, do canto de cima até a ponta
		var y := roundi(tip.y * (1.0 - absf(x - tip.x) / maxf(1.0, tip.x)))
		img.set_pixel(x, clampi(y, 0, sz.y - 1), Pal.SHEET_NEW.darkened(0.2 if read else 0.14))
		if read and y + 1 < sz.y:   # solta, a aba faz sombra na frente do envelope
			img.set_pixel(x, y + 1, Pal.SHEET_NEW.darkened(0.08))
	return img


## O lacre de cera vermelho na ponta da aba do envelope ainda fechado (`read` falso), o sinal de que há carta:
## desenhado na tela, deitado como o envelope (mais largo que alto); posto no desenho de frente, a perspectiva o
## entortava num losango.
const SEAL := ["  ####", " ######", "#######", " ######"]   ## o lacre, linha a linha (a de cima na luz, a de baixo na sombra)


func _envelope_seal(sz: Vector2i, read: bool) -> void:
	if read:
		return
	var tip := Vector2(sz.x / 2.0, roundf(sz.y * 0.55))
	var c := _tex_pt(tip).round() - Vector2(3, 2)
	for y in SEAL.size():
		var col: Color = Pal.SEAL.lightened(0.25) if y == 0 else Pal.SEAL.darkened(0.25) if y == SEAL.size() - 1 else Pal.SEAL
		col = _tone(col, tip)
		var row: String = SEAL[y]
		for x in row.length():
			if row[x] == "#":
				_ci.draw_rect(Rect2(c + Vector2(x, y), Vector2.ONE), col)


## As fitas tiradas do gravador (`tapes_out`), deitadas e empilhadas no meio do vão entre `a` e `b` (a mesinha do calculógrafo e
## o bloco de fichas), com o fundo em `z`; e onde a próxima vai cair (`_tape_next`, a fita voando do gravador mira nela).
func _draw_tapes(a: float, b: float, z: float) -> void:
	var w := TAPE.x * PROP_K
	var x := (a + b - w) / 2.0 - 0.6   # (um pouco para a esquerda: a beira do bloco, girado, vem para cá na frente)
	var h := TAPE.z * PROP_K
	var yd := _yd
	if _here(TAPES_ID):
		var all := Rect2()
		for i in tapes_out.size():
			_yd = yd - h * i   # a de baixo é o tampo da de cima
			var k: int = tapes_out[i]
			var side: Color = [Pal.BAKELITE[1], Pal.PARCEL_WHITE.darkened(0.35), Pal.PARCEL_YELLOW.darkened(0.35)][k]
			_flat(TAPES_ID, x, z, w, _deep(TAPE.y * PROP_K), h, side, _art_tape.bind(k), [k], deg_to_rad(TAPE_YAW[i % TAPE_YAW.size()]))
			all = _props[TAPES_ID] if i == 0 else all.merge(_props[TAPES_ID])
		if not tapes_out.is_empty():
			_props[TAPES_ID] = all   # o mouse vale na pilha inteira, não só na de cima
		_yd = yd
		var top := yd - h * (tapes_out.size() + 1)
		var dz := _deep(TAPE.y * PROP_K)
		_tape_next = PixelArt.bounds(PackedVector2Array([_p3(x, top, z), _p3(x + w, top, z), _p3(x + w, top, z + dz), _p3(x, top, z + dz)]))


## A fita deitada vista de cima, de comprido para o fundo: o plástico escuro e a etiqueta creme do lado esquerdo (a
## janelinha das bobinas, nesse tamanho, parecia um risco). Embrulhada (`to` 1 ou 2), o pacote: o branco de carta com o
## selo vermelho num canto; o amarelo oficial com o risco azul de ponta a ponta, no meio.
func _art_tape(sz: Vector2i, to := 0) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	if to != 0:
		var col := Pal.PARCEL_WHITE if to == 1 else Pal.PARCEL_YELLOW
		img.fill(col)
		_fr(img, 0, 0, sz.x, 1, col.lightened(0.2))   # a beira do fundo, na luz
		if to == 1:
			_fr(img, sz.x - 3, 1, 2, 2, Pal.RED)   # o selo
		else:
			_fr(img, sz.x / 2, 0, maxi(1, sz.x / 5), sz.y, Pal.PARCEL_STRIPE)
		return img
	img.fill(Pal.BAKELITE[3])
	var lw := maxi(roundi(sz.x * 0.6), 2)
	var ly := maxi(roundi(sz.y * 0.08), 1)
	_fr(img, 1, ly, lw, sz.y - ly * 2, Pal.LABEL_PAPER)
	_fr(img, 0, 0, sz.x, 1, Pal.BAKELITE[5])   # a beira do fundo, na luz
	return img


## Onde (na tela) a próxima fita entregue cai em cima da pilha (`_draw_tapes`).
func tape_spot() -> Rect2:
	return Rect2(global_position + _tape_next.position, _tape_next.size)


## Um fio de uma máquina da mesa, como esses aparelhos são ligados: sai rente ao tampo atrás da traseira dela (o canto
## de trás à esquerda em `x`, `z`; a ponta fica escondida atrás dela, desenhada depois), vai para o lado, recuando um
## pouco (`CABLE_SAG`), e, rente ao console (`gap` além da lateral dele), para o fundo, onde passa da beira de trás do
## tampo e cai no vão entre a mesa e a parede: o tampo tapa a queda, e nada dele passa da beira (pintado na parede,
## parecia encostado nela). Nunca vem para a frente da traseira (parecia sair de baixo da máquina). Borracha
## cinza-escura sem contorno, como os cabos de conexão: o brilho em cima, a sombra embaixo, a grossura pela distância
## (`CABLE_D`). Montado pixel a pixel numa imagem guardada (`_cable_art`; em trechos de `_pixel_line`, a curva ficava
## com furos).
## ponytail: com a máquina erguida sob o mouse, a ponta escondida do fio pode aparecer embaixo dela por um instante.
func _draw_cable(x: float, z: float, gap: float) -> void:
	var deep := _zd.y - _zd.x
	var st := Vector2(x + 6.0, z + 0.01 * deep)   # rente atrás da traseira (na frente dela, parecia sair de baixo da máquina)
	var e := Vector2(_side_x + gap, _zd.y + 0.04 * deep)   # um pouco além da beira de trás: o corte fica com a grossura inteira
	var c1 := Vector2(e.x, lerpf(z, e.y, CABLE_SAG))   # para o lado antes do fundo (em diagonal, o do calculógrafo passava
	var c2 := Vector2(e.x, lerpf(z, e.y, 0.5))         # por baixo da quina da unidade de despacho)
	var pts := PackedVector2Array()
	for i in CABLE_STEPS + 1:
		var q := st.bezier_interpolate(c1, c2, e, float(i) / CABLE_STEPS)
		pts.append(_p3(q.x, _yd - CABLE_D / 2.0, q.y))
	var mid := st.bezier_interpolate(c1, c2, e, 0.5)
	var w := clampi(roundi(_p3(mid.x, _yd, mid.y).y - _p3(mid.x, _yd - CABLE_D, mid.y).y), 4, 6)
	var edge := roundf(_p3(x, _yd, _zd.y).y)   # a beira de trás do tampo na tela (é horizontal)
	var art := _cable_at(pts, w, edge)
	_ci.draw_texture(art[1], art[0])


## O fio pelos pontos `pts` já montado (`_cable_image`), guardado em `_cable_art`.
func _cable_at(pts: PackedVector2Array, w: int, edge: float, tones := [], shade := CABLE_SHADE) -> Array:
	var key := [pts, w, edge, tones, shade]
	if not _cable_art.has(key):
		if _cable_art.size() > 16:   # a tela mudou de tamanho
			_cable_art.clear()
		_cable_art[key] = _cable_image(pts, w, edge, tones, shade)
	return _cable_art[key]


## A imagem do fio pelos pontos `pts` (px da tela), de `w` px, e onde ela vai: cada pixel pela distância dele à linha
## do meio, de través (com quadrados carimbados ao longo dela, o fio engrossava nas diagonais e o brilho corria pelo
## comprimento nos trechos em pé: parecia amassado), em faixas de cilindro: a beira de cima, o brilho do lado da
## luminária (`CABLE_LIGHT`), o miolo e o lado de baixo, escuro (`tones`, do lado da luz ao outro; vazio, a borracha
## das máquinas); a sombra rente no tampo é a mesma linha deslocada `shade` (zero: sem sombra). Nada acima do fio
## deitado em `edge` (a beira de trás do tampo).
func _cable_image(pts: PackedVector2Array, w: int, edge: float, tones := [], shade_at := CABLE_SHADE) -> Array:
	var r := PixelArt.bounds(pts).grow(w + 3.0)
	r = Rect2(r.position.floor(), r.size.ceil() + Vector2.ONE)
	var img := Image.create(int(r.size.x), int(r.size.y), false, Image.FORMAT_RGBA8)
	var rad := w / 2.0
	if tones.is_empty():
		tones = [Pal.SHELL[0], Pal.SHELL[2], Pal.SHELL[0], Pal.BAKELITE[1]]   # borracha cinza-escura (marrom, sumia no tampo)
	var top := int(edge - r.position.y) - w   # (deitado na beira, o fio passa dela a grossura dele, na frente da parede)
	for y in range(maxi(top, 0), img.get_height()):
		for x in img.get_width():
			var c := Vector2(x, y) + r.position + Vector2(0.5, 0.5)
			var best := INF
			var side := 0.0
			var shade := INF
			for i in pts.size() - 1:
				var q := Geometry2D.get_closest_point_to_segment(c, pts[i], pts[i + 1])
				var dd := c.distance_to(q)
				if dd < best:
					var n := (pts[i + 1] - pts[i]).orthogonal().normalized()
					if n.dot(CABLE_LIGHT) < 0.0:
						n = -n
					best = dd
					side = (c - q).dot(n)
				shade = minf(shade, (c - shade_at).distance_to(Geometry2D.get_closest_point_to_segment(c - shade_at, pts[i], pts[i + 1])))
			if best < rad:
				var t := -side / rad   # de -1, do lado da luz, a 1, do outro
				img.set_pixel(x, y, tones[0 if t < -0.6 else (1 if t < -0.15 else (2 if t < 0.45 else 3))])
			elif shade < rad:
				img.set_pixel(x, y, Color(0, 0, 0, 0.35))
	return [r.position, ImageTexture.create_from_image(img)]


## O calculógrafo, que abre a tarifação (`x0`, a frente em `zf`; medidas em `CALC`), como a ferramenta aberta. Atrás, a
## máquina, uma caixa baixa no material das máquinas do despacho; na frente dela, sem relógio (o da mesa fica ao lado),
## os dez contadores em duas fileiras (a plaquinha, os tambores e a luz âmbar de cada entrada contando, `counting`), a
## etiqueta creme com a luz e a saída de ar e, embaixo, a fenda, de onde sai o bilhete (a ponta numa camada própria,
## `_tip`, `Background._draw_tip`). Na frente dela, a mesinha (o que está nela e onde, `toll_desk`): a almofada com a
## tampa aberta, os bilhetes soltos com as marcas do carimbo, a caixinha com os guardados e o carimbo em pé.
func _draw_calculograph(x0: float, zf: float) -> void:
	_yaw = 0.0
	_nags[Tools.TOLL] = []
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
	var step := _paper_step(_still(xc, zb))   # a máquina num degrau só da luz parada, como a unidade de despacho
	var tone := func(c: Color) -> Color: return Pal.lit(c, step)
	var box := _clock_box(xc, zc, hw, hd, _yd, CALC.y * PROP_K, Pal.SHELL[3], Pal.SHELL[0], Pal.SHELL[2], tone)   # o plástico creme, três tons abaixo do aberto (a luminária ali o deixava branco)
	var hull := PackedVector2Array()
	for f: PackedVector2Array in box.values():
		hull.append_array(f)
	if box.has("front"):
		var f := PixelArt.bounds(box["front"])
		f = Rect2(f.position.round(), f.size.round())
		var win := Rect2(f.position.x + 3.0, f.position.y + 2.0, f.size.x - 6.0, 0)   # o visor na frente toda, como o da aberta (`Toll._screen`)
		var cell := Vector2(floorf(win.size.x / 5.0), maxf(floorf((f.size.y - 7.0) / 2.0), 1.0))   # (sem tela, no primeiro desenho, a frente tem 1 px)
		win.size.y = cell.y * 2.0
		_ci.draw_rect(win, tone.call(Pal.BOARD_INSET))
		for n in range(1, Exchange.LINES + 1):   # cada contador como o da aberta, em escala: plaquinha, tambores e lâmpada, no meio da célula
			var o := win.position + Vector2((n - 1) % 5, (n - 1) / 5) * cell + Vector2(floorf((win.size.x - cell.x * 4.0 - 16.0) / 2.0), roundf(cell.y / 2.0) - 1.0)
			var on := (counting & (1 << n)) != 0
			_ci.draw_rect(Rect2(o, Vector2(5, 2)), tone.call(Pal.BOARD_TAG))   # a plaquinha da entrada
			_ci.draw_rect(Rect2(o + Vector2(6, 0), Vector2(7, 2)), tone.call(Pal.INK))   # os tambores, escuros, com os algarismos
			for i in 3:
				_ci.draw_rect(Rect2(o + Vector2(7 + i * 2, 0), Vector2(1, 2)), tone.call(Pal.TEXT if on else Pal.INK_SOFT))
			var led := Rect2(o + Vector2(14, 0), Vector2(2, 2))
			_ci.draw_rect(led, Pal.AMBER if on else tone.call(Pal.LAMP_GLASS))   # apagada, o vidro, como a `CardMachines.led`
			if on:
				_light(led, Pal.AMBER, 0.4, true)
		var mw := roundf(f.size.x * TollTicket.SIZE.x / Toll.NOMINAL.x)   # a fenda, no meio
		var mouth := Rect2(roundf(win.get_center().x - mw / 2.0), f.end.y - 3.0, mw, 1)
		_ci.draw_rect(mouth, Pal.EDGE)
		_ci.draw_rect(Rect2(mouth.position + Vector2(0, 1), mouth.size), tone.call(Pal.SHELL[4]))
		var bx := roundf((mouth.end.x + win.end.x) / 2.0) - 3.0   # o selo da companhia, entre a fenda e a beira (o da aberta, `Switchboard.badge`, de 6 × 3)
		for row: Vector3 in [Vector3(1, 0, 4), Vector3(0, 1, 6), Vector3(1, 2, 4)]:
			_ci.draw_rect(Rect2(bx + row.x, mouth.position.y - 1.0 + row.y, row.z, 1), tone.call(Pal.BOARD_INK))
		_ci.draw_rect(Rect2(bx + 1.0, mouth.position.y, 4, 1), tone.call(Pal.KEY_CAP[2]))
		# a ponta do bilhete saindo dela para a mesinha fica com a camada dela, que a faz descer sem redesenhar a sala
		_tip = Rect2(mouth.position + Vector2(1, 1), Vector2(mw - 2.0, 6))
		_tip_tones = [tone.call(Pal.TICKET), tone.call(Pal.TICKET_EDGE)]
		hull.append_array(PackedVector2Array([_tip.position, _tip.end]))
	var pt := func(p: Vector2, y: float) -> Vector2: return _p3(x0 + p.x * w, _yd - y, zb - p.y * d)   # um ponto da mesinha (fração dela), `y` acima
	var quad := func(r: Rect2) -> PackedVector2Array:
		return PackedVector2Array([pt.call(r.position, 0.0), pt.call(Vector2(r.end.x, r.position.y), 0.0), pt.call(r.end, 0.0),
			pt.call(Vector2(r.position.x, r.end.y), 0.0)])
	hull.append_array(quad.call(Rect2(0, 0, 1, 1)))
	if toll_desk.size() >= 4:
		var paper := _paper_step(_still(xc, zf + d / 2.0))   # a mesinha no tom da luz parada ali
		var desk := func(c: Color) -> Color: return Pal.lit(c, paper)
		var pad: Rect2 = toll_desk[0]
		var lid := Toll.LID / Toll.NOMINAL.x * w
		_poly(PackedVector2Array([pt.call(pad.position, lid), pt.call(Vector2(pad.end.x, pad.position.y), lid),
			pt.call(Vector2(pad.end.x, pad.position.y), 0.0), pt.call(pad.position, 0.0)]), desk.call(Pal.NICKEL[3]))   # a tampa aberta, de costas
		_poly(quad.call(pad), desk.call(Pal.NICKEL[2]))
		var rim := Vector2(5, 5) / Toll.NOMINAL
		_poly(quad.call(Rect2(pad.position + rim, pad.size - rim * 2.0)), desk.call(Pal.TOLL_INK.darkened(0.5)))   # o feltro
		for i in range(4, toll_desk.size()):   # os bilhetes soltos, na ordem em que estão empilhados
			var r: Rect2 = toll_desk[i][0]
			var q: PackedVector2Array = quad.call(r)
			var sh := PackedVector2Array()
			for p in q:
				sh.append(p + Vector2(1, 1))
			_poly(sh, Lift.SHADOW)
			_poly(q, Pal.lit(Pal.TICKET, paper))
			_nags[Tools.TOLL].append(q)   # fora da caixinha: pulsa
			_poly(quad.call(Rect2(r.position, Vector2(r.size.x, r.size.y * TollTicket.BAND / TollTicket.SIZE.y))), Pal.lit(Pal.TICKET_FORM, paper))
			var half := TollTicket.MARK_SIZE / TollTicket.SIZE / 2.0
			for m: Vector3 in toll_desk[i][1]:   # as marcas, cortadas no papel
				var mr := Rect2(Vector2(m.x, m.y) - half, half * 2.0).intersection(Rect2(0, 0, 1, 1))
				if mr.has_area():
					_poly(quad.call(Rect2(r.position + mr.position * r.size, mr.size * r.size)), Color(Pal.lit(Pal.TOLL_INK, paper), lerpf(0.25, 0.75, m.z)))
		var bx: Rect2 = toll_desk[1]
		var shoe: Rect2 = toll_desk[3]
		var draw_box := func() -> PackedVector2Array:   # a caixinha: o plástico oliva, a boca com os guardados de pé e a etiqueta na frente
			var bc := Vector2(x0 + bx.get_center().x * w, zb - bx.get_center().y * d)
			var bh := bx.size * Vector2(w, d) / 2.0
			_desk_shadow(quad.call(bx), false)
			var faces := _clock_box(bc.x, bc.y, bh.x, bh.y, _yd, TOLL_BOX_H, Pal.BOARD_METAL[5], Pal.BOARD_METAL[1], Pal.BOARD_METAL[3], desk)
			var y1 := _yd - TOLL_BOX_H
			var e := 0.5
			# pela boca, vista de cima e da frente, aparece a parede de trás por dentro, na sombra da caixa, e embaixo, rente à
			# beira da frente, o fundo escuro (toda escura, parecia um buraco)
			var lip := [_clock_pt(bc.x, bc.y, bh.x - e, -bh.y + e, y1).round(), _clock_pt(bc.x, bc.y, -bh.x + e, -bh.y + e, y1).round()]
			_poly(PackedVector2Array([_clock_pt(bc.x, bc.y, -bh.x + e, bh.y - e, y1), _clock_pt(bc.x, bc.y, bh.x - e, bh.y - e, y1),
				lip[0], lip[1]]), desk.call(Pal.BOARD_METAL[2]))
			_poly(PackedVector2Array([lip[1] - Vector2(0, 2), lip[0] - Vector2(0, 2), lip[0], lip[1]]), Pal.TOLL_BOX_MOUTH)
			for i in mini(toll_desk[2], 3):   # de trás para a frente, cada um mais claro que o de trás (o vão entre eles, na sombra)
				var v := lerpf(bh.y - e * 3.0, -bh.y + e * 3.0, 0.3 + i * 0.25)
				var a := _clock_pt(bc.x, bc.y, -bh.x + e * 3.0, v, y1 + 0.4)
				_pixel_line(a, _clock_pt(bc.x, bc.y, bh.x - e * 3.0, v, y1 + 0.4), [Pal.lit(Pal.TICKET, paper).darkened(0.4 - i * 0.12)])
				_ci.draw_rect(Rect2(a.round() + Vector2(4 + i * 5, 0), Vector2(2, 1)), Pal.lit(Pal.TOLL_INK.darkened(0.35), paper))   # o carimbo na beira (a tinta seca, como nas rodas do carimbo)
			if faces.has("front"):   # a etiqueta creme impressa em oliva, como a da caixinha aberta (`Toll`)
				var bf := PixelArt.bounds(faces["front"])
				var word := PixelArt.tiny(T.text(T.Key.TOLL_BOX))
				var tag := Rect2(roundf(bf.get_center().x - word.get_width() / 2.0) - 2.0, roundf(bf.get_center().y - 3.0), word.get_width() + 4, 7)
				_ci.draw_rect(tag, desk.call(Pal.BOARD_TAG))
				_ci.draw_texture(word, tag.position + Vector2(2, -2), desk.call(Pal.BOARD_METAL[1]))
			var out := PackedVector2Array()
			for g: PackedVector2Array in faces.values():
				out.append_array(g)
			return out
		var draw_stamp := func() -> PackedVector2Array:   # o carimbo, em pé onde a sapata está
			_desk_shadow(quad.call(shoe), false)
			var tex := _stamp_art(paper)
			var foot: Vector2 = pt.call(Vector2(shoe.get_center().x, shoe.end.y), 0.0)
			var c := foot.round() - Vector2(0, tex.get_height() / 2.0)
			_sprite(tex, c, Color.WHITE)
			_tip_cover = [tex, c, Color.WHITE]
			return PackedVector2Array([c - tex.get_size() / 2.0, c + tex.get_size() / 2.0])
		var near: Array = [draw_box, draw_stamp] if shoe.end.y >= bx.end.y else [draw_stamp, draw_box]   # quem está mais perto vai por cima
		for draw_it: Callable in near:
			hull.append_array(draw_it.call())
	_mark(Tools.TOLL, PixelArt.bounds(hull), Geometry2D.convex_hull(hull))


## O carimbo da mesinha do calculógrafo (`STAMP_ART`), nas cores do da ferramenta, no degrau `step` da luz parada ali
## (`Pal.lit`).
func _stamp_art(step: int) -> ImageTexture:
	var k: Color = Switchboard.CORD_COLORS[5][0]
	var n := Pal.NICKEL
	var lit: Color = Switchboard.CORD_COLORS[5][1]
	var cols := {"k": k.darkened(0.5), "j": k.darkened(0.25), "K": k, "h": k.lerp(lit, 0.6), "H": lit, "m": Pal.BRASS,
		"M": Pal.BRASS.darkened(0.3), "l": Pal.BRASS.lightened(0.3), "c": n[1], "C": n[2], "d": n[3], "p": n[0],
		"n": n[1].lerp(n[2], 0.5), "i": Pal.INK, "b": Pal.BRASS, "B": Pal.BRASS.darkened(0.45), "r": Pal.TOLL_INK.darkened(0.25)}
	for key: String in cols:
		cols[key] = Pal.lit(cols[key], step)
	return PixelArt.art(STAMP_ART, cols)


## O relógio da sala: um relógio de flip na mesa (centro `xc`, `zc`; medidas em `CLOCK`), meio virado para o operador
## (`CLOCK_TURN` do ângulo até os olhos, `_yaw`): caixa de baquelite creme numa base escura e, na janela, as duas plaquetas (horas e minutos), que viram
## quando a hora muda (`minutes`, `_flip_step`); no tampo, as fendas e o botão do alarme; no lado, a rodinha de
## acertar a hora. É o único relógio da tela.
func _draw_flip_clock(xc: float, zc: float) -> void:
	_yaw = -CLOCK_TURN * atan2(xc, zc)   # a frente gira para os olhos (que estão na origem)
	var hw := CLOCK.x / 2.0
	var hd := CLOCK.z / 2.0
	var bh := 1.5 * PROP_K   # a base, um pouco maior que a caixa, que a levanta da mesa
	_desk_shadow(PackedVector2Array(_clock_corners(xc, zc, hw + 0.8, hd + 0.8, _yd, bh, 1)[1]))   # (o pé da base: a risca do contato acompanha a beira dela)
	var dark := _shade(xc, zc)
	var lit := Color.WHITE.darkened(dark)   # longe da luz
	var base := _clock_box(xc, zc, hw + 0.8, hd + 0.8, _yd, bh, Pal.CLOCK_BASE[2], Pal.CLOCK_BASE[0], Pal.CLOCK_BASE[1], Callable(), 1)
	var box := _clock_box(xc, zc, hw, hd, _yd - bh, CLOCK.y, Pal.CLOCK_CASE[3], Pal.CLOCK_CASE[0], Color.TRANSPARENT)
	_clock_rim = box
	var hull := PackedVector2Array()
	for faces: Dictionary in [base, box]:
		for q: PackedVector2Array in faces.values():
			hull.append_array(q)
	_occ.append(Geometry2D.convex_hull(hull))
	occ_ids.append("relogio")
	var y1 := _yd - bh - CLOCK.y
	clock_x = global_position.x + PixelArt.bounds(box["top"]).get_center().x
	for i in 4:   # as fendas do alarme, no fundo do tampo
		var v := hd - 1.6 - i * 1.1
		_pixel_line(_clock_pt(xc, zc, -hw * 0.75, v, y1), _clock_pt(xc, zc, 0.0, v, y1), [Pal.CLOCK_CASE[1].darkened(dark)])
	var bt := _clock_pt(xc, zc, hw * 0.55, hd * 0.3, y1)   # o botão niquelado do alarme
	_sprite(PixelArt.disc(7, [[3.5, Color(0, 0, 0, 0.3)]]), bt + Vector2(1, 0))
	_sprite(PixelArt.disc(6, [[1.2, Pal.NICKEL[0]], [3.0, Pal.NICKEL[1], Pal.NICKEL[2], Pal.NICKEL[3]]]), bt - Vector2(0, 2), lit)
	if box.has("left"):   # a rodinha serrilhada de acertar a hora, saindo do lado
		var a := _clock_pt(xc, zc, -hw - 0.8, hd * 0.3, y1 + CLOCK.y * 0.5 - 2.4).round()
		var b := _clock_pt(xc, zc, -hw - 0.8, hd * 0.3, y1 + CLOCK.y * 0.5 + 2.4).round()
		_ci.draw_rect(Rect2(a.x + 2, a.y + 1, 1, b.y - a.y), Color(0, 0, 0, 0.35))   # a sombra no lado
		for y in range(int(a.y), int(b.y)):
			_ci.draw_rect(Rect2(a.x - 1, y, 3, 1), (Pal.CHROME[4] if int(y - a.y) % 2 == 0 else Pal.CHROME[2]).darkened(dark))
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
		_ci.draw_texture_rect_region(face, Rect2(x0 + i, y0, 1, y2 - y0), Rect2(floorf(a * w), 0, 1, h), Color.WHITE.darkened(sh))
		_ci.draw_rect(Rect2(x0 + i, y0 - 1, 1, 1), Pal.CLOCK_CASE[3].darkened(sh))   # a quina com o tampo (sem ela, sobravam furos)


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
## `top`, escurecendo ponto a ponto longe da luz (`_shade`); com `tone` (a cor -> o tom na luz parada, `Pal.lit`), cada
## face num tom só, como as peças de metal. `level`: a beira do lado levada à inclinação limpa (`_clock_corners`).
## Devolve as faces que apareceram ("front", "right", "back", "left", "top").
func _clock_box(xc: float, zc: float, hw: float, hd: float, y0: float, h: float, top: Color, side: Color, front: Color,
		tone := Callable(), level := 0) -> Dictionary:
	var cs := cos(_yaw)
	var sn := sin(_yaw)
	var c := _clock_corners(xc, zc, hw, hd, y0, h, level)
	var up: Array = c[0]
	var low: Array = c[1]
	var out := {}
	# [nome, normal (u, v), de onde a onde (u, v), da esquerda para a direita de quem olha de fora, e os cantos (`_clock_corners`)]
	for f in [["front", Vector2(0, -1), Vector2(-hw, -hd), Vector2(hw, -hd), 3, 2], ["right", Vector2(1, 0), Vector2(hw, -hd), Vector2(hw, hd), 2, 1],
			["back", Vector2(0, 1), Vector2(hw, hd), Vector2(-hw, hd), 1, 0], ["left", Vector2(-1, 0), Vector2(-hw, hd), Vector2(-hw, -hd), 0, 3]]:
		var n: Vector2 = f[1]
		var m: Vector2 = (f[2] + f[3]) / 2.0
		if Vector2(n.x * cs - n.y * sn, n.x * sn + n.y * cs).dot(-Vector2(xc + m.x * cs - m.y * sn, zc + m.x * sn + m.y * cs)) <= 0.0:
			continue
		var q := PackedVector2Array([up[f[4]], up[f[5]], low[f[5]], low[f[4]]])
		if PixelArt.bounds(q).size.x < 1.0:   # quase de perfil, não aparece (e o polígono nem fecha)
			continue
		out[f[0]] = q
		var col: Color = front if f[0] == "front" else side
		if col.a > 0.0:
			var a := _clock_xz(xc, zc, f[2].x, f[2].y)
			var b := _clock_xz(xc, zc, f[3].x, f[3].y)
			if tone.is_valid():
				_poly(q, tone.call(col))
			else:
				_shaded(q, [a, b, b, a], col)
			if f[0] == "left":   # a quina com a frente pega a luz: a última coluna da face, rente à beira dela
				_pixel_line(q[1] - Vector2(1, 0), q[2] - Vector2(1, 1), [tone.call(col.lightened(0.15)) if tone.is_valid() else col.lightened(0.15).darkened(_shade(b.x, b.y))])
			elif f[0] == "right":   # (a primeira)
				_pixel_line(q[0], q[3] - Vector2(0, 1), [tone.call(col.lightened(0.15)) if tone.is_valid() else col.lightened(0.15).darkened(_shade(a.x, a.y))])
	out["top"] = PackedVector2Array(up)
	if tone.is_valid():
		_poly(out["top"], tone.call(top))
	else:
		_shaded(out["top"], [_clock_xz(xc, zc, -hw, hd), _clock_xz(xc, zc, hw, hd), _clock_xz(xc, zc, hw, -hd), _clock_xz(xc, zc, -hw, -hd)], top)
	return out



## Os cantos de uma caixa do relógio na tela, no pixel inteiro: [os de cima, os de baixo], cada um fundo-esq, fundo-dir,
## frente-dir e frente-esq. As beiras do lado (do fundo à frente) na altura `level` (0 em cima, 1 embaixo: a que aparece)
## em degraus iguais (`exact_slope`, `FLAT_TOL`): o canto do fundo anda, em cima e embaixo juntos (a quina dele
## continua em pé). Arredondados um a um, saíam 2-2-2-1 e 2-2-3-2.
func _clock_corners(xc: float, zc: float, hw: float, hd: float, y0: float, h: float, level: int) -> Array:
	var out := [[], []]
	for k in 2:
		for uv: Vector2 in [Vector2(-hw, hd), Vector2(hw, hd), Vector2(hw, -hd), Vector2(-hw, -hd)]:
			out[k].append(_clock_pt(xc, zc, uv.x, uv.y, y0 - h if k == 0 else y0).round())
	for i in [0, 1]:   # (0 e 1 no fundo; 3 e 2, os da frente)
		var d: Vector2 = exact_slope(out[level][3 - i], out[level][i], FLAT_TOL) - out[level][i]
		out[0][i] += d
		out[1][i] += d
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
	img.fill(Pal.CLOCK_CASE[2])   # um creme envelhecido: mais claro, puxava o olho mais que os outros objetos
	img.fill_rect(Rect2i(0, 0, sz.x, 1), Pal.CLOCK_CASE[4])
	img.fill_rect(Rect2i(0, sz.y - 1, sz.x, 1), Pal.CLOCK_CASE[0])
	var win := Rect2i(3, 3, sz.x - 6, sz.y - 8)
	img.fill_rect(win.grow(1), Pal.CLOCK_CASE[0])   # o rebaixo em volta do aro
	img.fill_rect(win, Pal.CHROME[4])   # o aro niquelado: claro em cima, escuro embaixo
	img.fill_rect(Rect2i(win.position.x, win.end.y - 1, win.size.x, 1), Pal.CHROME[2])
	img.fill_rect(win.grow(-1), Pal.CLOCK_WINDOW)
	img.fill_rect(Rect2i(sz.x / 2 - 6, sz.y - 4, 12, 2), Pal.BRASS_PLATE[3])   # a plaquinha da marca, embaixo da janela
	img.fill_rect(Rect2i(sz.x / 2 - 6, sz.y - 4, 12, 1), Pal.BRASS_PLATE[5])
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
		img.fill_rect(Rect2i(at.x, at.y + h - 1, sz.x, 2), Pal.FLIP_CARD[2])
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
	img.fill(Pal.FLIP_CARD[1])
	img.fill_rect(Rect2i(0, 0, sz.x, 1), Pal.FLIP_CARD[2])
	img.fill_rect(Rect2i(0, sz.y / 2, sz.x, 1), Pal.FLIP_CARD[0])   # a divisa (por baixo dos algarismos: cortados, não se liam)
	var ink := Image.create(21, 19, false, Image.FORMAT_RGBA8)   # os dois algarismos, com 3 px entre eles
	for i in 2:
		for r in 19:
			var row: String = DIGITS[r].substr(int(text[i]) * 10, 9)
			for c in 9:
				if row[c] == "#":
					ink.set_pixel(i * 12 + c, r, Pal.FLIP_CARD[3])
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
## A da luminária, caindo no tampo (`on_desk`; não na mesinha do calculógrafo), vai para a camada dela
## (`_lamp_shades`), embaixo do sol, que a apaga com o dia (`Background.LAMP_SHADE`).
func _desk_shadow(foot: PackedVector2Array, on_desk := true) -> void:
	var off := Vector2(clampf((PixelArt.bounds(foot).get_center().x - _lamp_x * 2.0) / 60.0, -6.0, 8.0), 4.0).round()
	var up := _raised()
	off += up + (off.normalized() * up.length() * 0.5).round()
	var pts := PackedVector2Array()
	for p in foot:
		pts.append(p + off)
	if on_desk and up == Vector2.ZERO and _ci == _props_layer:
		_lamp_shades.append(pts)
	else:
		_lamp_shade(pts)
	if up == Vector2.ZERO:   # o contato: o pé deslocado 1 px para cada lado, a beira dele nos mesmos degraus da do objeto (aberto 1 px pelo `offset_polygon`, a risca alternava 1 e 2 px)
		var rim := PackedVector2Array()
		for p in foot:
			for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				rim.append(p.round() + d)
		var hull := Geometry2D.convex_hull(rim)   # (os pés são todos convexos)
		hull.remove_at(hull.size() - 1)   # (o primeiro ponto volta no fim)
		_poly(hull, Color(0, 0, 0, 0.45))


## A sombra da luminária de um objeto (`_desk_shadow`): a penumbra em volta e a sombra.
func _lamp_shade(pts: PackedVector2Array) -> void:
	for g in Geometry2D.offset_polygon(pts, 1.5, Geometry2D.JOIN_MITER):
		_poly(g, Color(0, 0, 0, 0.15))
	_poly(pts, Color(0, 0, 0, 0.3))


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
## `SHADE_MAX` (os objetos tinham a mesma cor em qualquer lugar da mesa e pareciam soltos da luz da sala); a luminária
## piscando escurece tudo junto no shader do escuro da sala (`_noir`), sem redesenhar. Contínuo: cada objeto escurece ponto a ponto (`_shaded`), não de um tom só.
func _shade(x: float, z: float) -> float:
	return _spread(_pool_d(x, z))


## A distância do ponto (`x`, `z`) da mesa à poça de luz, em raios dela, já com o alcance da luz (`_reach`).
func _pool_d(x: float, z: float) -> float:
	var p := _pool()
	var v := Vector2((x - p.x) / POOL_R, (z - p.y) / (POOL_R * 0.5))
	return v.length() / _reach(v.y)


## O escuro pela distância `d` à poça: nada perto dela e mais longe, até `SHADE_MAX`.
static func _spread(d: float) -> float:
	return clampf((d - 0.35) * 0.5, 0.0, SHADE_MAX)


## A luz parada no ponto (`x`, `z`) da mesa (`_shade` de 0 a 1), de 0, embaixo dela, a 1, longe da poça
## (`SHADE_MAX`): a que os papéis guardam no desenho, em degraus (`_paper_step`).
func _still(x: float, z: float) -> float:
	return _spread(_pool_d(x, z)) / SHADE_MAX


## O degrau da rampa do papel (`Pal.lit`) na luz parada `t` (`_still`): um acima bem embaixo da luminária, o tom de
## sempre perto dela e até três abaixo longe.
static func _paper_step(t: float) -> int:
	return 1 if t <= 0.0 else -mini(3, int(t * 4.0))


## A luz parada (`_still`) no ponto `p` do desenho de frente do papel sendo desenhado (px do desenho; `_hom_light`), com
## a troca de degrau andando um pouco de uma linha do papel para outra (`PAPER_RAG`), como a borda das faixas do tampo.
func _lit_at(p: Vector2) -> float:
	var u := clampf(p.x / _hom_sz.x, 0.0, 1.0)
	var v := clampf(p.y / _hom_sz.y, 0.0, 1.0)
	var l := _hom_light
	var t := lerpf(lerpf(l[0], l[1], u), lerpf(l[3], l[2], u), v)
	return t + (fposmod(sin(floorf(p.y) * 12.9898) * 43758.55, 1.0) - 0.5) * PAPER_RAG


## O tom `c` no ponto `p` do desenho de frente do papel sendo desenhado, pela luz parada ali (`Pal.lit`); fora de um
## papel, `c`.
func _tone(c: Color, p: Vector2) -> Color:
	return c if _hom_light.is_empty() else Pal.lit(c, _paper_step(_lit_at(p)))


## A luz parada nos cantos `xz` (da sala) de um papel, para o `_hom_light`.
func _still_at(xz: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p: Vector2 in xz:
		out.append(_still(p.x, p.y))
	return out


## Quantas vezes a luz da poça vai mais longe na direção `vy` (na distância, em meios raios dela; negativo é para a
## frente da mesa, onde ela vai `FRONT_LIGHT` vezes mais longe).
static func _reach(vy: float) -> float:
	return lerpf(1.0, FRONT_LIGHT, smoothstep(0.0, 0.5, -vy))


## As faixas de luz do tampo em volta da poça para a rampa `tone` (a luz, de 0 a 1, para o tom em degraus: `Pal.desk`,
## `Pal.desk_edge`), de fora para dentro: [até que distância da poça ela vai (`_dark`), uma luz dentro dela]. A de
## fora vai até longe (`INF`).
func _bands(tone: Callable) -> Array:
	const FAR := 2.0   # daí para fora, o escuro já é o maior
	const N := 48
	var out := [[INF, 1.0 - _spread(FAR)]]
	var prev: Color = tone.call(1.0 - _spread(FAR))
	for i in range(N - 1, -1, -1):
		var a := FAR * i / N
		var c: Color = tone.call(1.0 - _spread(a))
		if c == prev:
			continue
		var b := FAR * (i + 1) / N   # o tom muda entre a (dentro) e b (fora): a troca, ao meio pixel
		for k in 8:
			var m := (a + b) / 2.0
			if tone.call(1.0 - _spread(m)) == c:
				a = m
			else:
				b = m
		out.append([b, 1.0 - _spread(a)])
		prev = c
	return out


## Uma linha do tampo (px da tela: `y`, a altura `h`, de `x0` a `x1`) na distância `z` da sala, cada trecho no tom da
## faixa de luz em que cai (`bands`, de `_bands`; `cols`, o tom de cada uma): a de fora inteira e, por cima, as de
## dentro até onde elas chegam nessa linha (a partir da `first`).
func _desk_row(y: float, h: float, x0: float, x1: float, z: float, bands: Array, cols: PackedColorArray, first := 0) -> void:
	var p := _pool()
	var vy := (z - p.y) / (POOL_R * 0.5)
	var k := _reach(vy)
	var cx := (_vp.x + p.x * Z0 / z) * 2.0   # o meio da poça nessa linha
	var u := POOL_R * Z0 / z * 2.0           # um raio da poça nessa linha
	for i in range(first, bands.size()):
		var half := INF
		var rag := Vector2.ZERO
		if not is_inf(bands[i][0]):
			var q: float = pow(bands[i][0] * k, 2) - vy * vy
			if q <= 0.0:
				return   # as de dentro são menores: nenhuma chega a esta linha
			half = sqrt(q) * u
			# a troca de tom anda um pouco em cada linha, para os dois lados, como um veio pegando a luz: numa curva lisa,
			# a borda da faixa parecia o contorno de uma luz em degraus
			rag = (Vector2(fposmod(sin(y * 12.9898 + i) * 43758.55, 1.0), fposmod(sin(y * 78.233 + i) * 43758.55, 1.0)) - Vector2(0.5, 0.5)) * DESK_RAG * u
		var a := maxf(x0, roundf(cx - half + rag.x))
		var b := minf(x1, roundf(cx + half + rag.y))
		if b > a:
			_p(a, y, b - a, h, cols[i])


## A distância na sala da linha `y` (px da tela) do tampo.
func _desk_z(y: float) -> float:
	return Z0 * _yd / (y / 2.0 - _vp.y)


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
## [quad (px da tela, no pixel inteiro, como o `_fill` com `_snap`: a textura projetada nele pisa onde a face pisa), i,
## normal (x, z)]; a face `i` vai do canto `i` ao seguinte (0 fundo, 1 direita, 2 frente, 3 esquerda).
func _faces(xz: Array, y0: float, y1: float) -> Array:
	var out := []
	for i in 4:
		var a: Vector2 = xz[i]
		var b: Vector2 = xz[(i + 1) % 4]
		var n := Vector2(a.y - b.y, b.x - a.x)   # para fora (os cantos vão no sentido do relógio)
		if n.dot(-(a + b) / 2.0) <= 0.0:
			continue
		out.append([PackedVector2Array([_p3(a.x, y1, a.y).round(), _p3(b.x, y1, b.y).round(), _p3(b.x, y0, b.y).round(),
			_p3(a.x, y0, a.y).round()]), i, n.normalized()])
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
		foot.append(_p3(p.x, _yd, p.y).round())
		top.append(_p3(p.x, _yd - h, p.y).round())
	for i in [0, 1]:   # as beiras do lado, as compridas, em degraus iguais (`clean_slope`): o canto do fundo se ajeita, e o pé com ele
		var moved := clean_slope(top[3 - i], top[i], Vector2(1, 0), FLAT_TOL)   # (0 e 1 no fundo; 3 e 2, os da frente; só para o lado: a beira do fundo fica onde estava, e as pautas com ela)
		foot[i] += moved - top[i]
		top[i] = moved
	_desk_shadow(foot)
	var step := _paper_step(_still(x0 + wx / 2.0, zf + dz / 2.0))
	for f: Array in _faces(xz, _yd, _yd - h):   # (de pé entre o tampo e o pé, como eles ficaram)
		var i: int = f[1]
		var j := (i + 1) % 4
		_poly(PackedVector2Array([top[i], top[j], foot[j], foot[i]]), Pal.lit(edge, step).darkened(0.35 * absf((f[2] as Vector2).x)))
	var sz := Vector2i(_top_xf(top)[1])
	if sz.x >= 8 and sz.y >= 4:   # (a tela ainda se arrumando)
		_hom = _homography(top)
		_hom_sz = Vector2(sz)
		_hom_light = _still_at(xz)   # cada pixel no tom da luz parada dele, e o que vai por cima também (`_tone`)
		_project([id, sz, key], art, top, sz)
		if post.is_valid():
			post.call(sz)
		_hom_light = PackedFloat32Array()
	_mark(id, PixelArt.bounds(foot + top), Geometry2D.convex_hull(foot + top))
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
	var lit := []
	for c: Color in cols:
		lit.append(_tone(c, Vector2((x0 + x1) / 2.0, y)))
	_pixel_line(_tex_pt(Vector2(x0, y)), _tex_pt(Vector2(x1, y)), lit)


## O desenho de frente de um objeto chato posto no quadrilátero `q` da tela pixel a pixel, como a frente do relógio:
## cada pixel da tela pega o texel que cai nele, pela homografia (torto por transformação, o desenho esticava e
## entortava os pixels: uma linha de 1 px virava 0 ou 2, e destoava do resto do jogo). Guardado por `key`.
static var _projected := {}
const FLAT_TOL := 0.16   ## a tolerância do `clean_slope` nas beiras do lado dos objetos chatos (com 12%, a do bloco, 1,73, ficava em 2-2-1)
const BOOK_TOL := 0.25   ## a do `clean_slope` nos livros, meio tortos: o canto de trás andando uns px é só o volume um pouco mais girado (com 16%, a capa de cima, 1,25 e 1,29, ficava como estava)
const EDGE_EPS := 0.0001   ## a folga do desempate nas beiras do `_project` (fração do desenho; o erro da conta fica perto de 1e-6)


func _project(key: Array, art: Callable, q: PackedVector2Array, sz: Vector2i) -> void:
	var box := PixelArt.bounds(q)
	var at := Vector2i(floori(box.position.x), floori(box.position.y))
	var full := [key, at, Vector2i(ceili(box.end.x), ceili(box.end.y)), _hom_light]
	if not _projected.has(full):
		if _projected.size() > 40:   # a tela mudou de tamanho: tudo muda junto
			_projected.clear()
		var img: Image = art.call(sz)
		var inv := _hom.inverse()
		var out := Image.create(maxi(1, ceili(box.end.x) - at.x), maxi(1, ceili(box.end.y) - at.y), false, Image.FORMAT_RGBA8)
		var tones := {}   # num papel, (tom, degrau) -> o tom na luz (`Pal.lit`), uma conta por par
		for y in out.get_height():
			for x in out.get_width():
				var r := inv * Vector3(at.x + x + 0.5, at.y + y + 0.5, 1.0)
				var u := r.x / r.z
				var v := r.y / r.z
				# (numa beira de inclinação limpa entre pontos inteiros, a reta passa pelos centros dos pixels: o empate fica
				# dentro numa ponta e fora na outra, sempre; decidido pelo erro da conta, a beira saía com dentes, +2 e 0)
				if u >= -EDGE_EPS and u < 1.0 - EDGE_EPS and v >= -EDGE_EPS and v < 1.0 - EDGE_EPS:
					var tex := Vector2i(int(u * sz.x), int(v * sz.y))
					var c := img.get_pixel(tex.x, tex.y)
					if not _hom_light.is_empty():
						var step := _paper_step(_lit_at(Vector2(tex)))
						var k := c.to_rgba32() * 8 + step + 4
						if not tones.has(k):
							tones[k] = Pal.lit(c, step)
						c = tones[k]
					out.set_pixel(x, y, c)
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
	var cols := [Pal.SEAL, Pal.BOOK_BLUE, Pal.BOOK]
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
		var top := PackedVector2Array()
		var low := PackedVector2Array()
		for p: Vector2 in xz:
			top.append(_p3(p.x, y0 - bh, p.y).round())
			low.append(_p3(p.x, y0, p.y).round())
		for i in [0, 1]:   # as beiras do lado em degraus iguais (`exact_slope`, como no relógio); as faces saem dos mesmos cantos
			var d := exact_slope(top[3 - i], top[i], BOOK_TOL) - top[i]
			top[i] += d
			low[i] += d
		for f: Array in _faces(xz, y0, y0 - bh):
			var i: int = f[1]
			var q := PackedVector2Array([top[i], top[(i + 1) % 4], low[(i + 1) % 4], low[i]])
			var at := func(u: float, v: float) -> Vector2: return q[0].lerp(q[1], u).lerp(q[3].lerp(q[2], u), v)   # um ponto da face
			var ends: Array = [xz[i], xz[(i + 1) % 4], xz[(i + 1) % 4], xz[i]]   # os cantos da face no tampo (em cima e embaixo, os mesmos)
			if i == spine:   # a lombada: os filetes dourados e, entre eles, a etiqueta escura do volume com o número
				var step := _paper_step(_still((ends[0].x + ends[1].x) / 2.0, (ends[0].y + ends[1].y) / 2.0))
				_poly(q, Pal.lit(c.darkened(0.2), step))
				_pixel_line(at.call(0.0, 0.2), at.call(1.0, 0.2), [Pal.lit(Pal.GOLD, step)])
				_pixel_line(at.call(0.0, 0.8), at.call(1.0, 0.8), [Pal.lit(Pal.GOLD, step)])
				_poly(PackedVector2Array([at.call(0.32, 0.34), at.call(0.68, 0.34), at.call(0.68, 0.66), at.call(0.32, 0.66)]), Pal.lit(c.darkened(0.5), step))
				_pixel_line(at.call(0.44, 0.5), at.call(0.56, 0.5), [Pal.lit(Pal.GOLD, step)])
			else:
				# o miolo entre as capas, com as folhas em linhas finas: numa imagem posta pixel a pixel, como a capa (em
				# linhas tortas desenhadas na tela, elas viravam degraus quebrados e faixas)
				var fs := Vector2i(roundi(q[0].distance_to(q[1])), roundi(q[0].distance_to(q[3])))
				if fs.x >= 4 and fs.y >= 3:
					_hom = _homography(q)
					_hom_sz = Vector2(fs)
					var dk := 0.15 * absf((f[2] as Vector2).x)
					_hom_light = _still_at(ends)
					_project(["folhas", b, i, fs], _art_pages.bind(c, dk), q, fs)
				if i == 2:   # tiras de papel marcando páginas, saindo da frente (cada volume as dele)
					for m: Vector2 in [[Vector2(0.72, 0.0)], [Vector2(0.3, 1.0), Vector2(0.82, 0.0)], [Vector2(0.55, 1.0)]][b]:
						var p: Vector2 = (at.call(m.x, 0.55) as Vector2).round()   # deitada entre as folhas: uma aba fina, com a sombra embaixo
						var col := _tone(Pal.FORM_RED if m.y == 0.0 else Pal.STRIP, Vector2(m.x, 0.55) * Vector2(fs))
						_ci.draw_rect(Rect2(p - Vector2(3, 0), Vector2(6, 2)), col)
						_ci.draw_rect(Rect2(p - Vector2(3, 0), Vector2(6, 1)), col.lightened(0.15))
						_ci.draw_rect(Rect2(p + Vector2(-3, 2), Vector2(6, 1)), Color(0, 0, 0, 0.35))
				_hom_light = PackedFloat32Array()
			all.append_array(q)
		var cover := c.darkened(0.15)   # a capa, que pega a luz de cima de chapa, um tom abaixo da cor do cabo
		all.append_array(top)
		var sz := Vector2i(_top_xf(top)[1])
		if b == 2 and sz.x >= 8 and sz.y >= 4:   # a capa do volume de cima, pixel a pixel como os objetos chatos (sem o tom liso por baixo: ele aparecia nos pixels da beira que ela não pega)
			_hom = _homography(top)
			_hom_sz = Vector2(sz)
			_hom_light = _still_at(xz)
			_project([Tools.DIRECTORY, sz], _art_book_cover.bind(cover), top, sz)
			_hom_light = PackedFloat32Array()
		else:
			_poly(top, Pal.lit(cover, _paper_step(_still(cx, zf + offs[b].y + dz / 2.0))))
	_mark(Tools.DIRECTORY, PixelArt.bounds(all), Geometry2D.convex_hull(all))


## A caneca de café em pé na mesa (centro `xc`, `zc`; raio `rr`, altura `hh`): uma caneca esmaltada de época,
## branco-gelo com a borda azul-marinho, montada pixel a pixel numa imagem do tamanho dela na tela (`_mug_art`), nos
## tons das rampas do esmalte e da borda pela luz no lugar dela (`_shade`): longe da poça, mais escura e mais fria (antes
## era a mesma imagem escurecida por cima). A boca e o pé saem da câmera (elipses mais ou menos abertas pela altura).
func _draw_mug(xc: float, zc: float, rr: float, hh: float) -> void:
	var a := _p3(xc - rr, _yd - hh, zc).round()
	var body := Rect2(a, _p3(xc + rr, _yd, zc).round() - a)
	var ry := maxf(2.0, roundf((_p3(xc, _yd - hh, zc - rr).y - _p3(xc, _yd - hh, zc + rr).y) / 2.0))   # a boca
	var rb := maxf(2.0, roundf((_p3(xc, _yd, zc - rr).y - _p3(xc, _yd, zc + rr).y) / 2.0))   # o pé, mais aberto (mais abaixo dos olhos)
	if body.size.x < 10.0 or body.size.y < 10.0:   # (a tela ainda se arrumando)
		return
	_mug_mouth = body.position + Vector2(body.size.x / 2.0, ry * 0.3)   # o vapor sai do café (`_draw_steam`)
	_mug_rim = [body, ry]
	_mug_w = body.size.x
	var low := float(sips) / MUG_SIPS   # o risco de luz no café (`_mug_art`), na tela: o brilho tremendo vai em cima dele
	var e := Vector2(-0.3 * (0.78 - low * 0.2), -0.375 * (0.62 - low * 0.3) + 0.3 + low * 0.4)
	var half := Vector2(0.25 * (0.78 - low * 0.2) * body.size.x / 2.0, 0.175 * (0.62 - low * 0.3) * ry)
	_mug_glint = Rect2(body.position + Vector2(body.size.x / 2.0 + e.x * body.size.x / 2.0, e.y * ry) - half, half * 2.0)
	var foot := PackedVector2Array()   # o pé é redondo: num retângulo, a sombra virava um quadrado escuro no sol do amanhecer
	for p in _ring(Vector2.ZERO, 1.0):
		foot.append(Vector2(body.get_center().x, body.end.y) + p * Vector2(body.size.x / 2.0, rb))
	_desk_shadow(foot)
	var place := snappedf(1.0 - _shade(xc, zc), 0.05)   # a luz no lugar dela, em degraus (a imagem é guardada por ela)
	var img := _mug_art(int(body.size.x), int(body.size.y), int(ry), int(rb), sips, place)
	_ci.draw_texture(img, body.position - Vector2(0, ry))
	var hull := PackedVector2Array()
	for p in _mug_hulls[Vector4i(int(body.size.x), int(body.size.y), int(ry), int(rb))]:
		hull.append(p + body.position - Vector2(0, ry))
	_mark(MUG_ID, PixelArt.bounds(hull), hull)


## A caneca esmaltada de frente, com `w` de largura e `h` da boca ao pé (px), a boca e o pé em elipses de meia altura
## `ry` e `rb`: o corpo sombreado como um cilindro pela luz da luminária (do alto à esquerda: o brilho numa coluna, a
## sombra à direita), cada tom tirado das rampas `Pal.MUG_ENAMEL` e `Pal.MUG_RIM` pela luz dele vezes a do lugar
## (`place`, 0 a 1), a borda azul-marinho em volta da boca e o filete dela no pé, o lado de dentro com o café embaixo (a
## luz da luminária refletida nele), a alça em C do lado da sombra e duas lascas no esmalte mostrando o ferro. Guardada
## por tamanho, pelos goles já tomados (`drunk`: o café mais baixo; acabado, só a borra no fundo) e pela luz.
static var _mugs := {}
static var _mug_hulls := {}   # o contorno de cada caneca (px dela), da mesma chave


func _mug_art(w: int, h: int, ry: int, rb: int, drunk: int, place: float) -> ImageTexture:
	var key := [w, h, ry, rb, drunk, place]
	if _mugs.has(key):
		return _mugs[key]
	if _mugs.size() > 48:   # (a janela mudou de tamanho, ou a luminária piscou por todos os degraus)
		_mugs.clear()
	var low := float(drunk) / MUG_SIPS   # o quanto o café já baixou
	var hw := 9   # a alça, para fora do lado direito
	var img := Image.create(w + hw, h + ry + rb + 1, false, Image.FORMAT_RGBA8)
	var enamel := func(lit: float) -> Color: return Pal.ramp(Pal.MUG_ENAMEL, lit * place)
	var rim := func(lit: float) -> Color: return Pal.ramp(Pal.MUG_RIM, lit * place)
	var light := Vector2(-0.6, 0.8).normalized()   # (x de lado, z para os olhos): a luz vem do alto à esquerda
	var top := float(ry)   # o centro da boca na imagem
	for x in w:   # o corpo, coluna a coluna
		var nx := (x + 0.5) / w * 2.0 - 1.0
		var nz := sqrt(maxf(0.0, 1.0 - nx * nx))
		var d := 0.25 + 0.75 * clampf(Vector2(nx, nz).dot(light), 0.0, 1.0)   # (o lado de lá ainda pega a luz da sala)
		var y0 := int(top + nz * ry)   # a beira da frente da boca
		var y1 := int(top + h + nz * rb)   # a beira da frente do pé
		_fr(img, x, y0, 1, y1 - y0, enamel.call(d))
		_fr(img, x, y0, 1, 2, rim.call(d))   # a borda
		_fr(img, x, y1 - 1, 1, 1, rim.call(d - 0.2))   # o filete do pé
	var gx := int(w * 0.28)   # o brilho do esmalte: uma coluna clara no alto do lado da luz
	_fr(img, gx, int(top + ry) + 3, 1, int(h * 0.55), (enamel.call(1.0) as Color).lightened(0.12))
	_fr(img, gx + 1, int(top + ry) + 4, 1, int(h * 0.3), (enamel.call(1.0) as Color).lightened(0.06))
	# a boca: o aro azul, o lado de dentro esmaltado (a parede de trás aparece acima do café) e o café com a luz nele
	for y in range(0, ry * 2 + 1):
		for x in w:
			var e := Vector2((x + 0.5 - w / 2.0) / (w / 2.0), (y + 0.5 - top) / maxf(1.0, ry))
			var r2 := e.length_squared()
			if r2 > 1.0:
				continue
			var c: Color = rim.call(0.45)
			if r2 < 0.72:   # dentro do aro
				c = enamel.call(0.8 if e.x < 0.3 else 0.68)   # a parede de dentro, mais escura do lado da sombra
				var f := Vector2(e.x / (0.78 - low * 0.2), (e.y - 0.3 - low * 0.4) / (0.62 - low * 0.3))   # o café, mais baixo que a boca
				if low >= 1.0:
					f = Vector2(e.x / 0.4, (e.y - 0.68) / 0.16)   # acabado: a borra no fundo
				if f.length_squared() < 1.0:
					c = Pal.COFFEE[0] if low < 1.0 else Pal.COFFEE[1]
					if low < 1.0 and f.y > -0.55 and f.y < -0.2 and f.x > -0.55 and f.x < -0.05:
						c = Pal.COFFEE[0].lerp(Pal.COFFEE[2], place)   # a luz da luminária refletida no café: um risco do lado dela
			elif e.y < -0.2:
				c = rim.call(0.85)   # o aro, mais claro atrás (pega a luz por cima)
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
			var c: Color = enamel.call(0.68)
			if q.y < -ho.y * 0.4:
				c = enamel.call(0.8)   # o alto, na luz
			elif out > 0.8 and (q.x > hw * 0.4 or q.y > 0.0):
				c = enamel.call(0.55)   # a volta de fora e o pé, na sombra (mais escura, sumia na parede escura)
			img.set_pixel(x, y, c)
	for p in [Vector2i(int(w * 0.62), int(top + ry) + 1), Vector2i(int(w * 0.18), int(top + h) - 3)]:   # as lascas no esmalte
		_fr(img, p.x, p.y, 2, 1, Pal.MUG_CHIP[0])
		img.set_pixel(p.x, p.y + 1, Pal.MUG_CHIP[1])
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
	var paper := Pal.BOOK_LEAVES.darkened(dk)
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
		_fr(img, tag.position.x, tag.position.y, tag.size.x, tag.size.y, Pal.BOOK_TAG[0])
		_fr(img, tag.position.x + 2, tag.position.y + 2, tag.size.x - 4, 1, Pal.BOOK_TAG[1])
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
			img.set_pixel(sz.x - 1 - xx, sz.y - 5 + y + xx, Pal.BOOK_TAG[2])
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
## como um terminal antigo, todo no plástico creme das máquinas (`Pal.SHELL`), no degrau da luz parada no
## meio dele, na rampa do metal e na do cartão (`Pal.lit`, `_lit_image`). Embaixo,
## a base, com as três máquinas embutidas no tampo, na mesma disposição do despacho aberto (`_art_deck`: o
## transmissor à esquerda, a impressora no meio e o triturador à direita) e, na frente, a etiqueta e as luzes;
## em cima, atrás, o painel inclinado com o mapa de papel sob o vidro (`_art_glass`). O estado do
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
	var step := _paper_step(_still(x0 + wx / 2.0, (zf + ze) / 2.0))
	var tone := func(c: Color) -> Color: return Pal.lit(c, step)
	var all := PackedVector2Array()
	var sx := x0 if x0 > 0.0 else x1   # o lado virado para o ponto de fuga (atravessando-o, nenhum)
	if x0 > 0.0 or x1 < 0.0:
		var base := PackedVector2Array([_p3(sx, yd, ze), _p3(sx, yd, zf), _p3(sx, _yd, zf), _p3(sx, _yd, ze)])
		_poly(base, tone.call(Pal.SHELL[0]))
		var side := PackedVector2Array([_p3(sx, yt, zt), _p3(sx, yt, ze), _p3(sx, yd, ze), _p3(sx, yd, zb)])
		_poly(side, tone.call(Pal.SHELL[2]))
		all.append_array(base + side)
	var top := PackedVector2Array([_p3(x0, yt, ze), _p3(x1, yt, ze), _p3(x1, yt, zt), _p3(x0, yt, zt)])   # o alto do painel...
	var cut := Vector2(2, 0)   # ...recuado nas pontas, onde os cantos de cima do vidro são redondos (`_art_glass`)
	_poly(PackedVector2Array([top[0] + cut, top[1] - cut, top[2] - cut, top[3] + cut]), tone.call(Pal.SHELL[5]))
	var glass := PackedVector2Array([_p3(x0, yt, zt), _p3(x1, yt, zt), _p3(x1, yd, zb), _p3(x0, yd, zb)])
	_flat_art("despacho_vidro", glass, func(sz: Vector2i) -> Image: return _lit_image(_art_glass(sz), step),
		[GameData.sectors.duplicate(), step])
	var deck := PackedVector2Array([_p3(x0, yd, zb), _p3(x1, yd, zb), _p3(x1, yd, zf), _p3(x0, yd, zf)])
	_flat_art("despacho_base", deck, func(sz: Vector2i) -> Image: return _lit_image(_art_deck(sz), step), [step])
	if card_out:   # o cartão saindo da fenda da impressora, no meio, para trás (para cima do vidro)
		var sz := _hom_sz
		var card := PackedVector2Array([_tex_pt(sz * Vector2(0.38, 0.0)), _tex_pt(sz * Vector2(0.62, 0.0)),
			_tex_pt(sz * Vector2(0.62, 0.46)), _tex_pt(sz * Vector2(0.38, 0.46))])
		_poly(card, tone.call(Pal.CARD))
		_pixel_line(_tex_pt(sz * Vector2(0.39, 0.15)), _tex_pt(sz * Vector2(0.61, 0.15)), [tone.call(Pal.CARD_FORM)])
	var front := Rect2(_p3(x0, yd, zf).round(), Vector2.ZERO).expand(_p3(x1, _yd, zf).round())   # a frente da base
	_ci.draw_rect(front, tone.call(Pal.SHELL[2]))   # (três tons abaixo do despacho aberto: a luminária ali o deixava branco)
	_ci.draw_rect(Rect2(front.position, Vector2(front.size.x, 1)), tone.call(Pal.SHELL[4]))
	_ci.draw_rect(Rect2(front.position.x, front.end.y - 1, front.size.x, 1), tone.call(Pal.SHELL[0]))
	var mid := front.position.y + floorf(front.size.y / 2.0)
	var plate := Rect2(front.position.x + roundf(front.size.x * 0.36), mid - 2, roundf(front.size.x * 0.28), 4)
	_ci.draw_rect(plate, tone.call(Pal.SHELL[0]))   # a etiqueta do fabricante
	_ci.draw_rect(plate.grow(-1), tone.call(Pal.BOARD_TAG))
	for l: Array in [[0.06, alert, Pal.RED], [0.14, card_out, Pal.AMBER]]:   # as luzes: ocorrência e cartão na mesa
		var lr := Rect2(front.position.x + roundf(front.size.x * l[0]), mid - 1, 3, 3)
		_ci.draw_rect(lr.grow(1), tone.call(Pal.SHELL[4]))   # o aro creme, como o das lâmpadas da mesa
		_ci.draw_rect(lr, l[2] if l[1] else (l[2] as Color).darkened(0.75))
		if l[1]:
			_light(lr, l[2], 0.6, true, true, DESK_SPILL)
	all.append_array(top + glass + deck)
	all.append_array(PackedVector2Array([front.position, front.end, Vector2(front.position.x, front.end.y)]))
	_mark(Tools.DISPATCH, PixelArt.bounds(all), Geometry2D.convex_hull(all))


## O desenho de frente `art` (com `key`) posto no quadrilátero `q` da tela pixel a pixel (`_project`), cada pixel no
## tom da luz parada `light` (nos cantos de `q`, `_still_at`; sem ela, como o desenho vem); deixa `_hom` dele para o
## que vai por cima (`_tex_pt`).
func _flat_art(id: String, q: PackedVector2Array, art: Callable, key: Array, light := PackedFloat32Array()) -> void:
	var sz := Vector2i(_top_xf(q)[1])
	if sz.x < 8 or sz.y < 3:   # (a tela ainda se arrumando)
		return
	_hom = _homography(q)
	_hom_sz = Vector2(sz)
	_hom_light = light   # cada pixel no tom da luz parada (quem chama zera depois do que desenha por cima)
	_project([id, sz, key], art, q, sz)


## A imagem `img` no degrau `step` da luz parada (`Pal.lit`, pixel a pixel), por inteiro: um objeto pequeno de metal num
## tom só, sem a troca de degrau andando de uma linha para outra, como nos papéis (no metal, parecia escovado).
static func _lit_image(img: Image, step: int) -> Image:
	if step == 0:
		return img
	var tones := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var k := c.to_rgba32()
			if not tones.has(k):
				tones[k] = Pal.lit(c, step)
			img.set_pixel(x, y, tones[k])
	return img


## O tampo da base da unidade de despacho, de cima (o alto do desenho é o fundo): o plástico creme com a beira clara e as três
## fendas lado a lado, como no despacho aberto (`CardMachines`): o transmissor à esquerda, com as marcas ciano, a
## impressora no meio e o triturador à direita, com as faixas de perigo.
func _art_deck(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.SHELL[3])
	_fr(img, 0, 0, sz.x, 1, Pal.SHELL[5])
	_fr(img, 0, sz.y - 1, sz.x, 1, Pal.SHELL[5])
	var slot := func(x: float, y: float, w: float) -> Vector2i:   # uma fenda: o lábio e o escuro de dentro
		var a := Vector2i(roundi(x * sz.x), roundi(y * sz.y))
		var n := roundi(w * sz.x)
		_fr(img, a.x - 1, a.y - 1, n + 2, 3, Pal.SHELL[0])
		_fr(img, a.x, a.y, n, 1, Pal.EDGE)
		_fr(img, a.x - 1, a.y + 2, n + 2, 1, Pal.SHELL[5])
		return a
	var tx: Vector2i = slot.call(0.05, 0.45, 0.27)   # o transmissor
	_fr(img, tx.x, tx.y + 3, 2, 1, Pal.KEY_CAP[3])
	_fr(img, tx.x + roundi(0.27 * sz.x) - 2, tx.y + 3, 2, 1, Pal.KEY_CAP[3])
	slot.call(0.365, 0.45, 0.27)   # a impressora
	var sh: Vector2i = slot.call(0.68, 0.45, 0.27)   # o triturador
	for i in range(0, roundi(0.27 * sz.x), 4):
		_fr(img, sh.x + i, sh.y + 3, 2, 1, Pal.HAZARD)
	return img


## O painel da unidade de despacho, de frente: a carcaça creme, o rebaixo da tela de cantos redondos e, sob o vidro, o
## mapa de papel (`_art_map`, na proporção das folhas, com o fundo da tela em volta, `Pal.MAP_BACK`; um pouco mais
## escuro perto da moldura), a sombra da moldura no alto e o
## reflexo do vidro na diagonal. Papel sob a luz da sala, não uma tela acesa. Na moldura da direita, mais larga, o
## anel de aproximar do despacho aberto (`CardMachines._draw_knob`).
func _art_glass(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.SHELL[5])   # a carcaça creme, como a da unidade aberta (`CardMachines._draw_bezel`)
	_fr(img, 0, 0, sz.x, 1, Pal.SHELL[7])
	_fr(img, 0, 0, 1, sz.y, Pal.SHELL[6])
	_fr(img, sz.x - 1, 0, 1, sz.y, Pal.SHELL[3])
	var inner := _glass_inner(sz)
	if inner.size.x < 4 or inner.size.y < 4:
		return img
	var rim := Rect2i(inner.position - Vector2i.ONE, inner.size + Vector2i(2, 2))   # o rebaixo da tela
	_fr(img, rim.position.x, rim.position.y, rim.size.x, rim.size.y, Pal.BOARD_INSET)
	var kh := maxi(3, roundi(inner.size.y * 0.22))   # o anel ciano, com um sulco escuro no meio
	var kx := inner.end.x + maxi(1, (sz.x - inner.end.x - 2) / 2)
	var ky := inner.position.y + (inner.size.y - kh) / 2
	_fr(img, kx, ky, 2, kh, Pal.KEY_CAP[2])
	for y in range(ky + 1, ky + kh - 1, 2):
		_fr(img, kx, y, 2, 1, Pal.KEY_CAP[0])
	var paper := Image.create(inner.size.x, inner.size.y, false, Image.FORMAT_RGBA8)
	paper.fill(Pal.MAP_BACK)
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
	var rad := clampi(inner.size.y / 5, 3, 6)   # os cantos redondos, como os do despacho aberto (`CardMachines._corner`)
	_round(img, inner, rad, Pal.BOARD_INSET)
	_round(img, rim, rad + 1, Pal.SHELL[5])
	_round(img, Rect2i(Vector2i.ZERO, sz), 3, Color.TRANSPARENT, false)   # e os de cima da carcaça (embaixo fica a base)
	return img


## Arredonda os cantos de `r` na imagem `img` com raio `rad` (sem `bottom`, só os de cima): o que fica fora do arco
## vira `col`.
static func _round(img: Image, r: Rect2i, rad: int, col: Color, bottom := true) -> void:
	for j in rad:
		for i in rad:
			if Vector2(rad - i - 0.5, rad - j - 0.5).length() > rad:
				var at := [Vector2i(r.position.x + i, r.position.y + j), Vector2i(r.end.x - 1 - i, r.position.y + j)]
				if bottom:
					at.append_array([Vector2i(r.position.x + i, r.end.y - 1 - j), Vector2i(r.end.x - 1 - i, r.end.y - 1 - j)])
				for c: Vector2i in at:
					img.set_pixelv(c, col)


## O vidro dentro da moldura do painel da unidade de despacho (`_art_glass` de `sz` px).
func _glass_inner(sz: Vector2i) -> Rect2i:
	var m := maxi(2, roundi(sz.x * 0.05))
	return Rect2i(m, m, sz.x - m * 2 - maxi(2, m - 1), sz.y - m * 2)   # (à direita, a moldura do anel)


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
## pela perspectiva, serrilhava), largado num lugar a cada ficha registrada (`PENCIL`).
func _pad_marks(sz: Vector2i) -> void:
	var t := _pad_tape(sz)
	_nags[Tools.LOGBOOK] = []
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
		_ink(3.0, mx - 3.0, y - 1.0, [Pal.NOTE_HAND])   # a hora
		var a := _tex_pt(Vector2(mx + 3.0, y)) - Vector2(0, 1)   # as palavras, logo acima da pauta
		var b := _tex_pt(Vector2(mx + 3.0 + (sz.x - mx - 8.0) * (0.45 + 0.1 * ((row * 3) % 5)), y)) - Vector2(0, 1)
		var w := 0.0
		var span := a.distance_to(b)
		while w < span:
			var n := 3.0 + (int(w) * 3 + row * 5) % 4
			_pixel_line(a.lerp(b, w / span), a.lerp(b, minf(w + n - 1.0, span) / span), [Pal.NOTE_HAND])
			w += n + 2.0
	if rows.size() > 1:   # a margem vermelha, impressa, do fio do cabeçalho para baixo
		_pixel_line(_tex_pt(Vector2(mx, rows[1])), _tex_pt(Vector2(mx, sz.y - 2)), [_tone(Pal.NOTE_MARGIN, Vector2(mx, sz.y / 2.0))])
	for i in mini(pending.size(), 6):
		var p := _tex_pt(Vector2(5 + i * floorf((sz.x - 12) / 6.0), 0)).round()
		var up := 6.0 + (i * 5) % 4
		var spot := Vector2(5 + i * floorf((sz.x - 12) / 6.0), 0)
		var col := _tone(pending[i], spot)
		if i == _rising:   # subindo: é da camada dela (`_draw_slip`)
			_slip = [p, up, col]
			continue
		_ci.draw_rect(Rect2(p.x, p.y - up, 6, up + 2), col)
		var r := Rect2(p.x, p.y - up, 6, up + 1)   # por registrar: pulsa
		_nags[Tools.LOGBOOK].append(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]))
		_ci.draw_rect(Rect2(p.x + 5, p.y - up, 1, up + 2), col.darkened(0.2))   # o lado na sombra
		_ci.draw_rect(Rect2(p.x, p.y - up, 5, 1), col.lightened(0.12))   # a beira de cima, na luz
		_ci.draw_rect(Rect2(p.x, p.y + 1, 6, 1), Color(0, 0, 0, 0.3))   # onde ela entra embaixo do bloco
	var at: Array = PENCIL[written % PENCIL.size()]
	var page := func(f: Vector2) -> Vector2:   # a fração da folha abaixo da fita, na tela
		return _tex_pt(Vector2(lerpf(4.0, sz.x - 4.0, f.x), lerpf(t + 3.0, sz.y - 3.0, f.y))).round()
	_pencil(page.call(at[0]), page.call(at[1]), (at[0] + at[1]) / 2.0 * Vector2(sz))


## O lápis largado num objeto chato, da ponta `a` à borracha `b` (px da tela), na luz do ponto `mid` do desenho dele.
func _pencil(a: Vector2, b: Vector2, mid: Vector2) -> void:
	var d := (b - a).normalized()
	var lit := func(cols: Array) -> Array: return cols.map(func(c: Color) -> Color: return _tone(c, mid))
	_pixel_line(a + Vector2(2, 2), b + d * 7 + Vector2(2, 2), [Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3)])
	_pixel_line(a, b, lit.call(Pal.PENCIL_BODY))   # o corpo, amarelo de lápis gasto
	_pixel_line(a - d * 4, a, lit.call(Pal.PENCIL_WOOD))   # a madeira apontada
	_pixel_line(a - d * 6, a - d * 4, lit.call([Pal.PENCIL_LEAD]))   # o grafite
	_pixel_line(b, b + d * 4, Pal.NICKEL.slice(1))   # a ponteira, no níquel da mesa
	_pixel_line(b + d * 4, b + d * 7, lit.call(Pal.PENCIL_ERASER))   # a borracha


const SHEET_TURN := 3.5   ## graus que a folha nova da prancheta fica girada (reta, lia como um risco no meio da de baixo)


## A prancheta do registro: tábua de duratex com os cantos cortados e a beira gasta e a folha. Com fala nova no registro
## (`unread`), uma folha nova, mais clara, presa por cima, girada (`SHEET_TURN`) e com a ponta dobrada. O datilografado
## das folhas e o prendedor vão por cima, na tela (`_clipboard_print`).
func _art_clipboard(sz: Vector2i) -> Image:
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	img.fill(Pal.BOARD[1])
	_fr(img, 0, 0, sz.x, 1, Pal.BOARD[0])
	_fr(img, 0, 0, 1, sz.y, Pal.BOARD[3])
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
				_pixel_line(_tex_pt(pa), _tex_pt(pb), [_tone(col, pa)])
			if k == 0:
				line.call(x0 + 2, x0 + 2 + (w - 4) / 2.0 - 1, Pal.SHEET_INK[0])   # o título
			elif k == 1:
				line.call(x0 + 2, x0 + w - 3, Pal.FORM_RED)   # o fio vermelho do cabeçalho
			elif k >= 4 and (k - 4) % 3 == 0 and n < sheets[i][2]:
				line.call(x0 + 2, x0 + 4, Pal.SHEET_INK[1])   # a hora
				line.call(x0 + 7, x0 + w - 3 - (k * 7) % 9 - (6 if i == 1 else 0), Pal.SHEET_INK[1])
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
