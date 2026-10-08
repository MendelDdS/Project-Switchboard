class_name Background
extends Control
## O cenário atrás da interface, esticado até a borda da tela e em pixels de 1x1 como ela (desenhado numa tela própria,
## `SceneView`, na resolução da tela; as contas são em unidades de 2 px, "px de 2x2", e os detalhes finos em `PX`/`_p`):
## o canto de uma sala vista por quem
## está sentado à mesa. Uma câmera só, em perspectiva de um ponto (`_vp`, perto dos objetos da mesa e na altura dos
## olhos, `EYE` acima do fundo do tampo; `_proj`/`_p3` levam um ponto da sala para a tela): a parede do fundo, com um
## armário de aço de chão atrás da mesa (a base fica escondida por ela); a parede da direita, entrando para o fundo a partir da quina (`CORNER`), com a janela vista de lado; a mesa de madeira, afastada da
## parede (`DESK_T`), que termina na parede da direita, com a mesa comutadora em pé nela (um móvel só: o console, cuja
## frente é a faixa de mesa, e o painel na prateleira dele, `_draw_switchboard`). A luz vem de cima, do meio da tela, de
## uma luminária que não aparece (o desenho dela tirava a atenção): o arco na parede, a poça na mesa e as sombras.
## A vista da janela (a cidade com o clima da noite) é desenhada de frente num vidro fora da tela (`_vport`): ela está
## longe e não entorta com a janela; só o batente, o caixilho e a persiana ficam na perspectiva da parede e a recortam.
## A interface diz onde fica cada coisa: a área das ferramentas (`window`; com uma aberta por cima, o papel cobre o
## cenário), a faixa de baixo da coluna da esquerda (`desk`, a borda da frente do tampo) e a mesa comutadora (`board`,
## de pé no tampo). Cada camada pode virar imagem (PNG): com `wall_art`, `window_art` ou `desk_art`, a imagem entra
## no lugar do desenho daquela camada (o clima continua por cima da vista).
## `weather`: "rain" (gotas no vidro, chão molhado), "fog" (névoa passando, luzes difusas) ou "clear" (estrelas e lua).
## `stranger`: quando o homem do mistério para embaixo do poste e quando vai embora (chega e sai andando, `_man_x`).
## Objetos na mesa, ao alcance do operador, abrem as ferramentas (`prop_clicked`, o id da aba em `Tools.TABS`): as
## listas telefônicas, o mapa dobrado, o caderno aberto e a prancheta do registro (o relógio de flip e a caneca só
## enfeitam). Ficam na sala, em centímetros da
## mesa, e passam pela mesma câmera (tamanho, escorço e o lado que aparece saem da conta), desenhados em pixels de 1x1
## com o detalhe da mesa comutadora; o resto do cenário também tem o detalhe em 1x1 (`PX`). Sob o mouse, ganham contorno, o nome da ferramenta e
## o cursor de dedo (o `SceneView` repassa o mouse, `pointer`, e desenha o contorno, `draw_hover`); o clique só vale
## sobre eles (`prop_at`) e não com o papel de uma ferramenta por cima.

signal prop_clicked(id: String)

const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]   ## madeira (luz, meio, sombra), a mesma do móvel
const LIT := [Color("d59a3d"), Color("b38a3c"), Color("e2b25a")]   ## janelas acesas da cidade
const SLEEP := Vector3(19 * 60, 23 * 60 + 50, 0.15)   ## as janelas apagam entre x e y (minutos do dia); z: as que ficam acesas
const CHURCH_DARK := 22 * 60   ## a porta da igreja apaga
const SIGN_ENAMEL := Color("1f3b35")   ## a placa da companhia telefônica: o esmalte verde-escuro...
const SIGN_INK := Color("d8cfae")   ## ...e o creme das letras e do filete
const SIGN_AT := 0.62   ## onde fica o meio dela, na largura da mesa comutadora (à direita do horário do turno)
const PROPS := {"lista": T.Key.TAB_DIRECTORY, "despacho": T.Key.TAB_DISPATCH, "caderno": T.Key.TAB_LOGBOOK, "registro": T.Key.TAB_CALL_LOG,
	"jornal": T.Key.TAB_NEWS}
const DETAILS := ["cartaz_quermesse", "numero_anotado", "armario_entreaberto"]   ## o que `RoomChange.detail` pode pedir
const SKY := {"rain": Color("0b141c"), "fog": Color("1b252b"), "clear": Color("0a1422")}
const BOARD_SINK := 30.0   ## o fundo do tampo, em px da tela acima da base do painel: fica atrás da mesa comutadora
const PX := 0.5          ## um pixel da tela nas unidades da câmera (px de 2x2): os detalhes são desenhados em 1x1
const LAMP_Y := -30.0      ## a boca da luminária, acima da tela (px de 2x2): de onde sai a luz e saem as sombras na parede
const WALL_GAP := 40.0     ## quanto a luminária fica à frente da parede (px de 2x2): abre o arco de luz nela
# A câmera. Medidas da sala na escala da parede do fundo (px de 2x2 lá; ~0,56 cm): x para a direita e y para baixo a
# partir dos olhos, z a distância deles (a parede fica a `Z0`; mais perto, tudo cresce Z0/z vezes).
const VP_AT := 0.32     ## o ponto de fuga no espaço da mesa, da mesa comutadora (0) à quina (1): perto dos objetos (longe dele, eles entortam; com os olhos baixos, mais)
## A altura dos olhos acima do fundo do tampo, na tela (px de 2x2): o ponto de fuga, dentro da tela, na altura da
## janela. Era 210 (logo acima da tela): a mesa vista mais de cima, mas a parede da janela ficava a 44 cm da cabeça e a
## janela, bem abaixo dos olhos, descia uns 40°. Mais baixo, o que fica longe do ponto de fuga entorta mais.
const EYE := 120.0
# O operador está sentado à mesa e a câmera são os olhos dele: `SEAT_EYE` cm acima do tampo, com o fundo do tampo a
# `SEAT_BACK` cm (a parte da frente do tampo fica sob o console do painel; a tela mostra a de trás). A tela fixa onde
# ficam o ponto de fuga e o fundo do tampo (`EYE` px abaixo dele); o que resta é a distância focal, que sai da
# conta: a altura dos olhos sobre a distância ao fundo do tampo é a mesma na sala e na tela (`EYE` / `Z0` × `DESK_T`).
# Com uma distância focal menor (era 330), a mesa era vista de cima como por alguém em pé (a ~38° em vez de ~22–29°
# para baixo) e as profundidades saíam exageradas: a prancheta mais larga que funda, o relógio torto.
const SEAT_EYE := 45.0    ## a altura dos olhos acima do tampo (cm), sentado
const SEAT_BACK := 110.0  ## dos olhos ao fundo do tampo (cm), na horizontal
const Z0 := EYE * SEAT_BACK / SEAT_EYE   ## a distância dos olhos à parede do fundo (e a distância focal, em px de 2x2)
const DESK_T := 1.25    ## o fundo do tampo, Z0/DESK_T: a mesa fica afastada da parede (o armário cabe atrás)
const CORNER := 0.64    ## a quina das paredes, na largura da área das ferramentas
const BOARD_D := 14.0   ## o fundo do painel da mesa comutadora (z), atrás da prateleira: raso, como o das mesas de verdade (o corpo do móvel é o console); a lateral dele foge para o ponto de fuga
const PLANKS := 6       ## as tábuas do tampo, todas da mesma largura (a câmera as espaça)
const POOL_R := 150.0   ## o raio da poça de luz da luminária no tampo
const DUST := 240        ## grãos de poeira na luz da luminária
const BEADS := 50        ## gotas paradas no vidro, na chuva
const RAIN := 320        ## pingos caindo lá fora, na chuva
const RAIN_FALL := Vector2(9.0, 16.0)   ## quanto o pingo cai a cada quadro da vista (px de 2x2), do mais longe ao mais perto: cruza o vidro em meio segundo
const RAIN_STREAK := Vector2(6.0, 14.0) ## o comprimento do risco (px da tela), do mais longe ao mais perto: o rastro do quadro
const RAIN_SLANT := 0.18 ## o vento: quanto o pingo anda para a esquerda a cada px que cai
const NOIR := Color(0.012, 0.022, 0.045, 0.72)   ## o escuro frio da sala fora da luz da luminária (`_draw_gloom`)
const GLOOM_R := Vector2(820, 330)   ## até onde vai a luz da luminária antes do escuro todo (px da tela, elipse em volta da poça na mesa: larga, a mesa toda na luz)
const GLOOM_IN := 0.25   ## dentro dessa fração do raio, nada de escuro: dali para fora ele cresce liso
const WINDOW_GLOW := Color(0.45, 0.62, 1.0, 0.12)   ## o brilho azul da noite entrando pela janela (`_draw_window_glow`)
const WINDOW_GLOW_R := 420.0   ## até onde ele chega (px da tela, a partir do meio do vidro)
const STREET_LIGHT := 1.15   ## a luz da rua entrando pela janela: quanto ela desce para cada unidade que entra na sala (com 1,6, caía perto da parede, um quadrado pequeno para a janela grande)
const CAR_EVERY := Vector2(35, 80)   ## de quanto em quanto tempo passa um carro lá fora (s, sorteado)
const CAR_SEC := 3.2      ## quanto ele leva passando na rua (a ~40 km/h), com os faróis na rua da vista
const WALK_EVERY := Vector2(2, 5)    ## de quanto em quanto tempo alguém passa pela calçada de lá às 18h (s, sorteado)...
const WALK_FROM := 18.0 * 60.0   ## ...e daí (min do dia) o intervalo cresce, cada vez menos gente...
const WALK_UNTIL := 22.0 * 60.0  ## ...até ninguém mais passar (só o homem do mistério)
const WALK_PAIR := 0.2    ## a chance de virem dois juntos
const WALK_SEC := 18.0    ## quanto leva atravessando a vista (~1,8 m/s, de 16 m a 16 m; cada um ±20%)
const WALK_STEPS := 2.2   ## passos por segundo (as pernas alternam nesse ritmo)
const LATE_FROM := 22.0 * 60.0   ## a partir de que hora (min do dia) a cidade começa a se calar: menos carros e pedestres
const LATE_TO := 24.0 * 60.0     ## até quando (aí, os intervalos entre eles chegam a `LATE_EVERY` vezes)
const LATE_EVERY := 3.0
const DOG_FROM := 21.0 * 60.0   ## a partir de que hora (min do dia) cachorros latem bem longe, de vez em quando
const DOG_EVERY := Vector2(45, 120)   ## de quanto em quanto tempo (s, sorteado)
const DOG_REPLY := 0.45   ## a chance de outro cachorro responder, mais longe, `DOG_REPLY_AFTER` s depois (sorteado)
const DOG_REPLY_AFTER := Vector2(1.8, 3.5)
const BELL_AFTER := 1.6   ## o sino da igreja começa a bater a hora depois do gongo da mesa (s), uma badalada a cada `BELL_GAP`
const BELL_GAP := 2.3
const RATTLE_NEAR := 2.0  ## trovão que vem até esse tempo depois do clarão (s) é perto: o vidro e a persiana chocalham
const BOLT_EVERY := Vector2(45, 110)   ## de quanto em quanto tempo cai um relâmpago, na chuva (s, sorteado)
const BOLT_PULSES := [Vector2(0.0, 1.0), Vector2(0.14, 0.55), Vector2(0.42, 0.8)]   ## os clarões dele: quando (s) e a força
const THUNDER_AFTER := Vector2(1.2, 3.5)   ## o trovão vem depois (s, sorteado: longe ou perto)
## O clarão do relâmpago na sala (`_bolt_layer`, somado à luz, `_bolt_build`): quase branco (azulado e espalhado na sala
## inteira, até na frente da mesa comutadora, parecia a noite clareando), só no que a janela alcança.
const BOLT_LIGHT := Color(0.93, 0.96, 1.0)
const BOLT_DIR := Vector2(-1.4, 0.45)   ## para onde a luz dele anda a cada unidade para o fundo (x, para a esquerda; y, para baixo): a sombra do armário na parede
const BOLT_STEEP := 1.2   ## quanto ela desce para cada unidade que entra na sala, até a mesa (a janela desenhada no tampo)
## A vista é uma cena 3D simples projetada para o vidro (pensada antes, não elemento por elemento): uma câmera dentro
## do prédio, na altura de quem está na janela (`OUT_EYE` m acima da rua: o horizonte passa ali), olhando para fora,
## de frente para uma rua que passa ao lado do prédio e continua para os dois lados. Um ponto de fuga só, no meio do
## horizonte, que é o da sala (a altura dos olhos, `_vp`: uma câmera só para o cenário inteiro): para ele fogem só as linhas que vão para longe (a rua do cruzamento,
## as laterais dos prédios); a rua, os meios-fios e as fachadas de frente ficam na horizontal, e as paredes na
## vertical. Não é a perspectiva da janela (a diagonal dela é só do primeiro plano). Tudo em metros (`_o`: `x` ao longo
## da rua, `z` a distância dos olhos, `h` a altura), no tamanho de verdade.
const OUT_EYE := 4.5      ## os olhos acima da rua (m)
const OUT_F := 60.0       ## a distância focal (px de 2x2 de um metro a um metro)
## A rua, de perto para longe (z, m): a nossa fachada, a nossa calçada até o meio-fio, as duas mãos (a faixa no meio),
## o meio-fio de lá, a calçada de lá e as fachadas do outro lado, apoiadas nela.
const STREET := {"curb": 3.2, "lane": 7.2, "far_curb": 11.2, "far": 14.0}
const CROSSING := Vector2(-6.0, 2.0)   ## a rua do cruzamento, indo embora entre os prédios de lá (x, m)
const FAR_LAMPS := [2.6, -17.0, 19.0]  ## os postes da calçada de lá (x, m): o primeiro na esquina do prédio de tijolos, com o homem
const MAN_X := 3.4        ## onde o homem fica, embaixo do poste da esquina
const MAN_FROM := 16.0    ## de onde ele vem pela calçada (x, m; fora da vista) e para onde volta
const MAN_WALK := 6.0     ## quanto ele leva andando de lá até o poste (min de jogo: ~8 s, ~1,6 m/s)
const MAN_STRIDE := 0.75  ## o passo dele (m)
const HOTEL_X := -9.5     ## o letreiro do hotel, no prédio do outro lado da esquina
## As duas mãos da rua: [o meio do carro (z, m), o sentido (-1: para a esquerda)]. Pela mão de lá, da direita para a
## esquerda; pela de cá, entre o nosso meio-fio e a faixa do meio, voltando, da esquerda para a direita.
const CAR_LANES := [Vector2(9.2, -1.0), Vector2(6.4, 1.0)]
## O arbusto plantado junto da nossa parede, embaixo da janela: é do primeiro plano, como a janela, e fica no plano da
## parede dela (não na vista). O meio e a meia largura (fração da largura do vão) e quanto a copa sobe acima do
## peitoril (fração da altura).
const SHRUB := Vector3(0.62, 0.15, 0.11)
const CHURCH_K := 0.45    ## a escala da igreja (desenhada em px de 2x2), no fim da rua do cruzamento
const SIGN_RED := Color("ff4a3a")    ## o neon dele aceso (apagado, quase preto)
const SIGN_GLOW := Color(1.0, 0.25, 0.18, 0.05)   ## o reflexo vermelho dele na parede, perto da janela
const FOG := Color(0.55, 0.62, 0.66)   ## a cor da névoa (`_draw_fog`)
const FOG_VEIL := 0.2    ## o véu dela por cima de tudo lá fora (o longe some nele)
const FOG_GROUND := 0.2  ## o tanto a mais rente ao chão, sumindo até 3 m de altura
const FOG_WISPS := 9     ## os fiapos passando pela rua
const SHADE_MAX := 0.3   ## o mais escuro que um objeto da mesa fica, longe da poça de luz (`_shade`)
const CAB_W := 110.0             ## a largura do armário de aço, encostado na parede (px de 2x2 lá)
const POSTER_W := 30.0           ## a largura do cartaz da quermesse (px de 2x2)
const WALL_PAD := 10.0           ## a folga dos objetos da mesa até a parede da direita (x da sala)
const CAB_TOP := -26.0           ## o alto dele (cm a partir dos olhos, para baixo): acima deles, ~1,5 m do chão (o tampo não aparece)
const CAB_T := 1.15              ## a frente dele (escala): ~35 cm de fundo
const SIDE_T := 1.06        ## onde a janela começa na parede da direita (escala); termina perto da borda da tela
const SIDE_W := 150.0       ## a largura do vão, de frente (só a resolução da projeção)
const WIN_TOP := -28.0      ## o alto do vão (cm a partir dos olhos, para baixo): acima deles
## O peitoril (cm abaixo dos olhos): uns 24 cm acima do tampo, como numa sala de verdade (desce pouco: a parede fica a
## uns 70 cm da cabeça). Com os olhos acima da tela e o peitoril 38 cm abaixo deles, a janela descia uns 40° e parecia
## vista de cima.
const WIN_SILL := 21.0
const WALL_D := 16.0        ## a espessura da parede (para fora, nas unidades da parede do fundo): o vidro fica do lado de fora
const SILL_D := 12.0        ## quanto o peitoril de dentro sai da parede para a sala
const SHIFT_START := 18.0 * 60.0   ## o começo do turno (min do dia): o café da caneca está quente
const STEAM_FOR := 210.0    ## em quantos minutos de jogo o café esfria e o vapor some (às 21h30)
const BLIND := 0.3         ## até onde a persiana desce (fração da altura do vão)
const X2 := Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2.ZERO)   ## a escala dos px de 2x2 (`_sprite` volta a ela)
const PROP_K := 93.0 / 66.0   ## a escala dos objetos da mesa: a mesma dos plugs, que cresceram até o tamanho das tomadas (antes, o plug ficava maior que o relógio e o caderno)
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

@export var window: Control   ## a área das ferramentas: a quina e a janela ficam na parede dela
@export var desk: Control     ## a faixa da miniatura do painel (`ConsoleMini`), a frente do console da mesa comutadora: a borda da frente do tampo fica logo abaixo dela
@export var board: Control    ## o painel da mesa comutadora: pousa na prateleira do console; o fundo do tampo fica `BOARD_SINK` px acima da base dele
@export var dust: Control     ## onde a poeira do feixe é desenhada: acima da mesa comutadora (que fica no ar, na frente dela) e abaixo do painel e dos menus
@export var wall_art: Texture2D     ## imagem da parede (repetida), no lugar do desenho
@export var window_art: Texture2D   ## imagem da vista da janela (esticada, de frente), no lugar da cidade desenhada
@export var desk_art: Texture2D     ## imagem da madeira da mesa (repetida), no lugar do desenho

var flick := false
var lamp_level := 1.0
var weather := "rain"
var stranger := Vector2(INF, INF)   ## quando o homem do mistério para embaixo do poste e quando vai embora (min do dia; o Main atualiza)
# O estado do jogo nos objetos da mesa, para ler de relance sem abrir nada (o Main atualiza):
var pending := 0     ## registros esperando no caderno: uma tira de papel saindo dele por registro
var unread := false  ## o registro das conversas tem fala nova: uma folha nova presa na prancheta
var news := false    ## o jornal da manhã está na mesa (da segunda noite em diante; `Main.set_news`)
# A sala muda ao longo das noites (o Main atualiza): os detalhes valendo (`RoomChange.detail`) e a noite (o calendário
# do armário risca um dia por noite).
var details := PackedStringArray()
var night := 1
var minutes := 18 * 60.0:   ## a hora do jogo (minutos do dia; o Main atualiza): o relógio de flip da mesa
	set(v):
		if int(v) != int(minutes):   # a plaqueta vira
			_flip_from = int(minutes)
			_flip_at = Time.get_ticks_msec()
		minutes = v
var clock_x := 0.0   ## onde o relógio está na tela (x global): de lá vêm a badalada das horas e a campainha do turno
var _yaw := 0.0   # quanto o relógio da mesa está girado (rad; `_draw_flip_clock`)
var _flip_from := -1   # o minuto que a plaqueta mostrava antes de virar
var _flip_at := -100000   # quando ela começou a virar (ms)
var _drops: Array = []   # pingos caindo: Vector3(x, y em frações da vista, perto: 0 = longe, 1 = perto)
var _dust: Control       # a poeira no feixe da luminária (`dust`): desenhada à parte, a 30 quadros por segundo, sem redesenhar a sala
var _motes: Array = []   # os grãos: Vector3(x de -1 a 1 na largura da luz, y de 0 a 1 do alto da tela ao fundo do tampo, fase do brilho)
var _beads: Array = []   # gotas paradas no vidro: Vector4(x, y em frações do vidro à vista, tamanho, velocidade; 0 = parada)
var _glass_from := 0.6   # de que fração da altura da vista o vidro aparece (acima: fora da tela ou atrás da persiana)
var _cab_x0 := 0.0       # o armário na parede do fundo (x a partir do ponto de fuga, px de 2x2): o reflexo no vidro o espelha
var _top := 200.0        # o fundo do tampo (px de 2x2), do último desenho: onde o feixe da luminária acaba
var _stars: Array[Vector2] = []
var _houses: Array = []        # os prédios do outro lado da rua, de frente: {x0, x1, h, col, brick, wins: [Vector3(x, andar, hora de apagar)]} (m)
var _canyon: Array = []        # as paredes da rua do cruzamento: {x, z0, z1, h, col, wins: [Vector3(z, altura, hora de apagar)]} (m)
var _city: Array = []          # a cidade no fundo: {x, w, h, row, lit: [Vector3...]} (px do vidro; z: o minuto em que a janela apaga)
var _city_for := Vector2.ZERO  # tamanho do vidro para o qual `_city` foi montada
var _mist := 0.0
var _win := Vector2(104, 38)   # a vista da janela, em pixels de 2x2 (do último desenho)
var _acc := 0.0
var _props := {}       # objeto que abre ferramenta -> retângulo dele (px da tela), do último desenho
var _hot := ""         # objeto sob o mouse
var _lamp_x := 0.0     # onde está a luminária, no meio da tela (px de 2x2): a luz na mesa e a sombra dos objetos dependem dela
var _vp := Vector2.ZERO   # o ponto de fuga (px de 2x2)
var _yd := 0.0         # a altura do tampo (y da sala, abaixo dos olhos)
var _zd := Vector2.ZERO   # a frente e o fundo do tampo (z)
var _side_x := 0.0     # a lateral da mesa comutadora na sala (x): os objetos da mesa ficam à direita dela
var _shelf := Vector2(INF, INF)   # `shelf()`, em px do cenário
var _cx := 0.0         # a quina das paredes (px de 2x2, na tela)
var _t2 := 1.6         # onde a janela termina na parede da direita (escala)
var _ci: CanvasItem    # onde a vista da janela é desenhada: aqui, ou no vidro fora da tela
var _view: Control     # desenha a vista da janela no `_vport`: a frente dela, a cada quadro da vista
var _back: Control     # a parte de trás da vista, embaixo da `_view`: só se redesenha quando muda (`_back_state`)
var _back_drawn := []
var _vport: SubViewport
var _hom := Basis()          # a perspectiva do objeto chato sendo desenhado (`_flat`, `_homography`): o que vai por cima dele, na tela
var _hom_sz := Vector2.ONE   # o tamanho do desenho de frente dele (px)
var _cover := Rect2()   # onde está o papel da ferramenta aberta (px da tela, não de 2x2): luz embaixo dele não brilha
var _drawn := []        # o `_state` do último desenho da sala
var _over: Control      # por cima da sala, o que muda sozinho sem mexer nela (`_draw_over`)
var _over_drawn := []   # o estado do último desenho dela
var _glows: Array = []  # as luzes da sala para o brilho (`_light`): [retângulo, cor, halo, miolo, redonda]
var _sign_glow := Rect2()   # o halo do letreiro no vidro (vazio = fora do vidro); brilha só aceso
var _bolt_layer: Control   # o clarão do relâmpago, por cima de tudo e somado: só a força muda, no `modulate`
var _bolt_lit: Array = []    # o que ele acende: [polígono (px da tela), cores], medido com a sala (`_bolt_build`)
var _occ: Array = []         # os objetos da mesa (px da tela, convexos): o que fica na frente da parede e do armário
var _occ_board := PackedVector2Array()   # a mesa comutadora inteira (px da tela)
var _side_faces: Array = []  # a lateral da mesa comutadora (px da tela), virada para a janela
var _cab := [Rect2(), Rect2()]   # o armário: o fundo dele (na parede) e a frente (px de 2x2)
var _mug_mouth := Vector2.ZERO   # o meio do café na caneca (px da tela), de onde sobe o vapor
var _mug_w := 0.0               # a largura da caneca na tela (px; 0 = ainda não desenhada)
var _headless := false   # sem tela (os testes): a vista da janela não é desenhada
var _sill_lit: Array = []   # o peitoril na luz de fora: [polígono (px da tela), cores], desenhado por cima do escuro da sala
var _glass := PackedVector2Array()   # o vidro da janela abaixo da persiana (px da tela): o escuro da sala não passa nele
var _view_at := Vector2.ZERO   # onde a vista começa na tela (px de 2x2): o arbusto é posto pela parede da sala
var _near := 0.0         # a vista passa do peitoril de longe para baixo (px de 2x2): a parte de perto da janela, mais alta na tela, mostra a calçada embaixo dela
var _sign_px := Vector2.ZERO   # onde o letreiro aparece no vidro (px da tela; zero = fora do vidro)
var _cars: Array[Dictionary] = []   # os carros passando lá fora: {"t": de 0 a 1, "lane": em `CAR_LANES`}
var _car_in := [20.0, 32.0]          # quanto falta para o próximo de cada mão (s)
var _walkers: Array = []   # quem está passando na calçada de lá (`_walker`), na ordem do desenho: os de mais longe primeiro
var _walk_in := 3.0      # quanto falta para o próximo (s)
var _dog_in := randf_range(15.0, 50.0)   # quanto falta para o próximo latido, contado a partir de `DOG_FROM` (s)
var _dog_reply := -1.0   # quanto falta para o cachorro que responde (-1 = nenhum)
var _tolls := 0          # badaladas do sino que faltam bater
var _toll_in := 0.0      # quanto falta para a próxima (s)
var _late_sent := -1.0   # o quanto da noite avançada já foi passado ao `Sfx`
var _lamp_dim := false   # a luminária estava baixa no quadro anterior (ao piscar, estala)
var _sign_was := true    # o letreiro estava aceso no quadro anterior (ao falhar, estala)
var _bolt := -1.0        # há quanto tempo caiu o relâmpago (s; -1 = nenhum)
var _bolt_in := 30.0     # quanto falta para o próximo (s)
var _thunder_at := 2.0   # quando, depois dele, vem o trovão (s)


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # o mouse chega pelo `SceneView`
	_ci = self
	_vport = SubViewport.new()
	_vport.size = Vector2i(64, 64)
	_vport.render_target_update_mode = SubViewport.UPDATE_ONCE   # a cada quadro da vista (`_process`)
	_back = Control.new()
	_back.draw.connect(_draw_view_back)
	_vport.add_child(_back)
	_view = Control.new()
	_view.draw.connect(_draw_view)
	_vport.add_child(_view)
	add_child(_vport)
	_over = Control.new()
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.draw.connect(_draw_over)
	add_child(_over)
	_bolt_layer = Control.new()
	_bolt_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bolt_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # luz: soma, não cobre
	_bolt_layer.material = add
	_bolt_layer.visible = false
	_bolt_layer.draw.connect(_draw_bolt)
	add_child(_bolt_layer)
	_show()
	for i in RAIN:   # pingos e estrelas em frações do vidro: a janela muda de tamanho com a tela
		_drops.append(Vector3(randf() * 1.2, randf(), randf()))
	for i in 30:
		_stars.append(Vector2(randf() * 0.95 + 0.02, randf() * 0.45 + 0.03))
	_dust = dust
	if _dust == null:   # (sem a camada da cena: aqui mesmo, atrás da interface)
		_dust = Control.new()
		_dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_dust)
	_dust.draw.connect(_draw_dust)
	for i in DUST:
		_motes.append(Vector3(randf() * 2.0 - 1.0, randf(), randf() * TAU))
	for i in BEADS:
		_beads.append(Vector4(randf(), randf(), 1 + randi() % 2, 0.0))


## A sala só se redesenha quando algo que ela mostra muda (`_state`): parada, ela custa só o desenho já guardado. O
## que muda sozinho fica fora dela: a camada de cima (`_over`, o escuro, o neon e o papel deslizando), a do relâmpago
## (`_bolt_layer`, só a força muda) e a frente do relógio, uma textura trocada no lugar (`_clock_face`). A vista da janela (chuva, névoa, estrelas) anda a 30
## quadros por segundo no vidro fora da tela, sem redesenhar a sala.
func _process(delta: float) -> void:
	_events(delta)
	var st := _state()
	if st != _drawn:
		_drawn = st
		queue_redraw()
		_over.queue_redraw()   # (depois da sala: usa o vidro e a poça de luz que ela acabou de medir)
		_bolt_layer.queue_redraw()
		_show()
	var f := snappedf(_flash(), 0.02)
	if f != _bolt_layer.modulate.a:   # o relâmpago: o desenho dele fica; só a força muda
		_bolt_layer.modulate.a = f
		if f > 0.0 and not _bolt_layer.visible:
			_bolt_layer.queue_redraw()
		_bolt_layer.visible = f > 0.0
		_show()
	var ov := [size, _paper(), lamp_level, _sign_on()]
	if ov != _over_drawn:   # (o papel deslizando entra aqui: o corte do brilho acompanha já neste quadro)
		_over_drawn = ov
		_over.queue_redraw()
		_show()
	if _face:   # a hora mudou ou a plaqueta está virando: só a frente do relógio muda
		var was := _face_key
		_clock_face(_face_key[0])
		if _face_key != was:
			_show()
	_acc += delta
	if _acc < 1.0 / 30.0:
		return
	_acc = 0.0
	_mist += 0.12
	for i in _drops.size():
		var d: Vector3 = _drops[i]
		var fall := lerpf(RAIN_FALL.x, RAIN_FALL.y, d.z)
		d.y += fall / _win.y
		d.x -= fall * RAIN_SLANT / _win.x
		if d.y > 1.05:   # volta para cima, de onde o vento o traz até ali
			d.y -= 1.1
			d.x = randf() * (1.0 + RAIN_SLANT * _win.y / _win.x)
		_drops[i] = d
	for i in _motes.size():   # a poeira: sobe e desce devagar, ao sabor do ar
		var m: Vector3 = _motes[i]
		m.x += sin(m.z * 0.7) * 0.0014
		m.y += sin(m.z * 1.3) * 0.001 - 0.0003
		m.z += 0.014
		if m.y < 0.0 or m.y > 1.0 or absf(m.x) > 1.0:
			m = Vector3(randf() * 2.0 - 1.0, randf(), randf() * TAU)
		_motes[i] = m
	_dust.queue_redraw()
	if weather == "rain":
		for i in _beads.size():   # as gotas no vidro: paradas, até pesarem e escorrerem
			var b: Vector4 = _beads[i]
			if b.w == 0.0:
				if randf() < 0.002:
					b.w = 0.006 + randf() * 0.008
			else:
				b.y += b.w
				b.x += (randf() - 0.5) * 0.003   # serpenteia um pouco
				if b.y > 1.0:
					b = Vector4(randf(), randf() * 0.8, 1 + randi() % 2, 0.0)
			_beads[i] = b
	if flick:
		lamp_level = FLICK[int(Time.get_ticks_msec() / 90.0) % FLICK.size()]
	else:
		lamp_level = 1.0
	var dim := lamp_level < 0.75
	if dim != _lamp_dim:   # a luminária piscando estala
		_lamp_dim = dim
		Sfx.play("lamp_tick")
	Sfx.lamp(lamp_level)
	if _headless:   # sem tela (testes) ninguém vê a vista: redesenhada a cada quadro, ela era 2/3 do tempo de um turno do robô
		return
	var bs := _back_state()
	if bs != _back_drawn:
		_back_drawn = bs
		_back.queue_redraw()
	_view.queue_redraw()
	_vport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_show()


## A tela do cenário (o `View` do `SceneView`) mostra um quadro novo: ela só é desenhada quando algo nela muda (a sala,
## a camada de cima, o relógio, a vista da janela a 30 quadros por segundo) ou de tamanho (`SceneView._fit`); a cada
## quadro, as ~1000 chamadas de desenho da sala parada iam para a placa de vídeo à toa.
func _show() -> void:
	var vp := get_viewport() as SubViewport
	if vp:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE


## Tudo de que o desenho da sala depende (fora o mouse, que redesenha sozinho): onde a interface pôs as coisas, a
## luminária e o estado do jogo nos objetos.
func _state() -> Array:
	return [size, board.get_global_rect() if board else Rect2(), desk.get_global_rect() if desk else Rect2(),
		window.get_global_rect() if window else Rect2(), lamp_level, pending, unread, news, details, night, weather,
		TranslationServer.get_locale()]


## Os acontecimentos lá fora, cada um na hora sorteada: um carro passando (`CAR_*`; na chuva, com o chiado da água),
## gente andando pela calçada de lá, cada vez menos até as 22h (`WALK_*`; sem som: os passos, de dentro do prédio, não
## se ouviriam), o homem do mistério chegando e indo embora (`_man_x`), e, na chuva, o
## relâmpago com o trovão depois (`BOLT_*`, `THUNDER_AFTER`; perto, a janela chocalha, `RATTLE_NEAR`); o neon do
## hotel estala quando falha, o sino da igreja bate as horas (`toll`) e, das 21h em diante, cachorros latem bem longe
## (`DOG_*`; calados antes da ligação desconhecida, `Sfx.hushed`). Das 22h à meia-noite a cidade se cala: carros
## cada vez mais raros (`LATE_*`) e os grilos mais presentes (`Sfx.set_late`). Os sons vêm da janela.
func _events(delta: float) -> void:
	var x := _bounds(_glass).get_center().x / maxf(1.0, size.x) if _glass.size() > 2 else 0.9
	var late := snappedf(clampf((minutes - LATE_FROM) / (LATE_TO - LATE_FROM), 0.0, 1.0), 0.1)
	if late != _late_sent:   # a cidade se calando: grilos mais presentes, menos gente e carro
		_late_sent = late
		Sfx.set_late(late)
	var rare := lerpf(1.0, LATE_EVERY, late)
	if _tolls > 0:   # o sino da igreja batendo a hora
		_toll_in -= delta
		if _toll_in <= 0.0:
			Sfx.play_at("bell", x)
			_tolls -= 1
			_toll_in = BELL_GAP
	if minutes >= DOG_FROM:   # um cachorro latindo longe e, às vezes, outro respondendo
		_dog_in -= delta
		if _dog_in <= 0.0:
			_dog_in = randf_range(DOG_EVERY.x, DOG_EVERY.y)
			if not Sfx.hushed():
				Sfx.play_at("dog", x, 0.0, randf_range(0.92, 1.08))
				if randf() < DOG_REPLY:
					_dog_reply = randf_range(DOG_REPLY_AFTER.x, DOG_REPLY_AFTER.y)
	if _dog_reply >= 0.0:
		_dog_reply -= delta
		if _dog_reply < 0.0 and not Sfx.hushed():
			Sfx.play_at("dog_low", x, -3.0, randf_range(0.92, 1.05))
	for lane in CAR_LANES.size():   # um carro por vez em cada mão, cada uma no seu tempo
		_car_in[lane] -= delta
		if _car_in[lane] <= 0.0:
			_cars.append({"t": 0.0, "lane": lane})
			_car_in[lane] = INF   # o próximo desta mão é sorteado quando este sair
			Sfx.play_at("car_wet" if weather == "rain" else "car", x, 2.0 if lane == 1 else 0.0)   # o de cá, mais perto
	for i in range(_cars.size() - 1, -1, -1):
		var c := _cars[i]
		c["t"] += delta / CAR_SEC
		if c["t"] >= 1.0:
			_car_in[c["lane"]] = randf_range(CAR_EVERY.x, CAR_EVERY.y) * rare
			_cars.remove_at(i)
	var crowd := 1.0 - clampf((minutes - WALK_FROM) / (WALK_UNTIL - WALK_FROM), 0.0, 1.0)
	_walk_in -= delta
	if _walk_in <= 0.0 and crowd > 0.0:
		_walk_in = randf_range(WALK_EVERY.x, WALK_EVERY.y) / maxf(crowd, 0.05)
		var w := _walker()
		_add_walker(w)
		if randf() < WALK_PAIR:   # dois juntos: lado a lado, o de trás um passo atrás
			var w2 := _walker()
			w2.merge({"t": -1.0 / 32.0, "dir": w["dir"], "sec": w["sec"], "z": w["z"] + (0.5 if w["z"] < 13.0 else -0.5)}, true)
			_add_walker(w2)
	for i in range(_walkers.size() - 1, -1, -1):
		var w: Dictionary = _walkers[i]
		w["t"] += delta / w["sec"]
		if w["t"] >= 1.0:
			_walkers.remove_at(i)
	var lit := _sign_on()
	if _sign_was and not lit and _sign_px != Vector2.ZERO:
		Sfx.play_at("neon", x)
	_sign_was = lit
	_bolt_in -= delta
	if _bolt < 0.0 and _bolt_in <= 0.0 and weather == "rain":
		_bolt = 0.0
		_thunder_at = randf_range(THUNDER_AFTER.x, THUNDER_AFTER.y)
	if _bolt >= 0.0:
		var before := _bolt
		_bolt += delta
		if before < _thunder_at and _bolt >= _thunder_at:
			Sfx.play_at("thunder", x, -6.0 * (_thunder_at - THUNDER_AFTER.x) / (THUNDER_AFTER.y - THUNDER_AFTER.x))   # longe, mais fraco
			if _thunder_at < RATTLE_NEAR:   # perto: o vidro e a persiana chocalham
				Sfx.play_at("rattle", x, -6.0 * (_thunder_at - THUNDER_AFTER.x) / (RATTLE_NEAR - THUNDER_AFTER.x))
			_bolt = -1.0
			_bolt_in = randf_range(BOLT_EVERY.x, BOLT_EVERY.y)


## O sino da igreja bate a hora (`count` badaladas), começando um pouco depois do gongo da mesa.
func toll(count: int) -> void:
	_tolls = count
	_toll_in = BELL_AFTER


## A força do clarão do relâmpago agora (0 a 1): os pulsos dele, cada um sumindo depressa.
func _flash() -> float:
	var f := 0.0
	if _bolt >= 0.0:
		for p: Vector2 in BOLT_PULSES:
			if _bolt >= p.x:
				f = maxf(f, p.y * exp(-(_bolt - p.x) / 0.07))
	return f


## O letreiro aceso: quase sempre; de vez em quando apaga um instante, como neon velho.
func _sign_on() -> bool:
	return not (int(Time.get_ticks_msec() / 110.0) % 97 in [40, 42, 43, 71])


## Em que passo da virada está a plaqueta do relógio (0 a 2; 3 = parada).
func _flip_step() -> int:
	return mini(3, int((Time.get_ticks_msec() - _flip_at) / (FLIP_SEC * 1000.0 / 3.0)))


## Onde está o papel da ferramenta aberta ou vindo do objeto (px da tela; vazio com tudo guardado).
func _paper() -> Rect2:
	for n in window.get_children() if window else []:
		if n is Control and n.visible:
			return (n as Control).get_global_transform() * Rect2(Vector2.ZERO, n.size)
	return Rect2()


## A lateral da prateleira da mesa comutadora (x, o canto da frente do console) e o tampo ao pé dele (y), em px da
## tela: além da lateral, o plug solto cai até o tampo (`Switchboard.shelf`). Antes do primeiro desenho, sem fim.
func shelf() -> Vector2:
	return _shelf + global_position if _shelf.x < INF else _shelf


## Onde fica na tela (global) o objeto da mesa que abre a ferramenta `id` (vazio se ele não está na mesa): de onde o
## papel dela sai (`Tools.origin`).
func prop_rect(id: String) -> Rect2:
	return Rect2(global_position + (_props[id] as Rect2).position, (_props[id] as Rect2).size) if _props.has(id) else Rect2()


## Uma luz do cenário (`r` em px da tela) que brilha, a não ser que o papel de uma ferramenta esteja por cima dela.
func _light(r: Rect2, col: Color, halo: float, round := false, core := true) -> void:
	if _ci == self:   # a vista da janela: as luzes dela vêm de `_draw_side_wall`, que sabe onde o vidro está
		_glows.append([r, col, halo, core, round])   # a camada de cima as acende, cortadas onde o papel está


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x, y, w, h), c)


## Um retângulo em px da tela (1x1) dentro do desenho em escala 2: os detalhes finos, na mesma densidade da interface.
func _p(x: float, y: float, w: float, h: float, c: Color) -> void:
	_ci.draw_rect(Rect2(x * PX, y * PX, w * PX, h * PX), c)


## Uma linha em pixel art de `a` a `b` (px da tela, fora da escala e da perspectiva; como traço comum, torta,
## serrilhava): um pixel por passo na direção mais longa e, na outra, a espessura em `cols` (de cima para baixo, ou da
## esquerda para a direita). Depois volta a valer `back` (a transformação de quem chamou).
func _pixel_line(a: Vector2, b: Vector2, cols: Array, back := Transform2D.IDENTITY) -> void:
	draw_set_transform(Vector2.ZERO)
	var d := b - a
	var n := maxi(1, roundi(maxf(absf(d.x), absf(d.y))))
	var flat := absf(d.x) >= absf(d.y)
	var o := floori(cols.size() / 2.0)
	for i in n + 1:
		var p := (a + d * i / n).floor()
		for k in cols.size():
			draw_rect(Rect2(p + (Vector2(0, k - o) if flat else Vector2(k - o, 0)), Vector2.ONE), cols[k])
	draw_set_transform_matrix(back)


## Uma peça redonda em pixel art (`PixelArt.disc`; como círculo, saía embolotada) centrada em `c` (px da tela),
## presa aos pixels, fora da escala e da perspectiva; depois volta a valer `back` (a transformação de quem chamou).
func _sprite(tex: Texture2D, c: Vector2, mod := Color.WHITE, back := Transform2D.IDENTITY) -> void:
	draw_set_transform(Vector2.ZERO)
	PixelArt.sprite(self, tex, c, mod)
	draw_set_transform_matrix(back)


func _draw() -> void:
	_glows.clear()
	_props.clear()
	_occ.clear()
	_side_faces.clear()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var w := ceilf(size.x / 2.0)
	var h := ceilf(size.y / 2.0)
	# o fundo do tampo: atrás da mesa comutadora, que fica de pé nele
	var top := floorf((board.global_position.y - global_position.y + board.size.y - BOARD_SINK) / 2.0) if board else 200.0
	# a borda da frente do tampo: logo abaixo da faixa de mesa (o painel do operador cobre o resto)
	var front := floorf((desk.global_position.y - global_position.y + desk.size.y) / 2.0) + 1.0 if desk else h - 20.0
	_lamp_x = floorf(w / 2.0)
	var area := Rect2((window.global_position - global_position) / 2.0, window.size / 2.0) if window else Rect2(320, 26, 300, 180)
	_yd = EYE / DESK_T
	_cx = floorf(area.position.x + area.size.x * CORNER)
	var b := Rect2((board.global_position - global_position) / 2.0, board.size / 2.0) if board else Rect2()
	# o ponto de fuga fica na mesma fração do espaço da mesa (da mesa comutadora à quina) em qualquer largura: preso
	# à largura da tela, numa janela larga ele fugia dos objetos e os da ponta apareciam bem de lado
	_vp = Vector2(floorf(lerpf(b.end.x, _cx, VP_AT)), top - EYE)
	_top = top
	_draw_wall(Rect2(0, 0, w, top))
	_draw_wall_light(top)
	if board:   # a mesa comutadora, de pé na frente da parede, faz sombra nela (o tampo cobre a parte de baixo)
		_cast(b, 1.1)
		_draw_company_sign(Rect2(b.position * 2.0, b.size * 2.0))
	# na parede, entre a mesa comutadora e a quina, com a mesma folga entre eles em qualquer largura de janela: o
	# armário e o lugar do cartaz (guardado mesmo sem ele, para o armário não mudar de lugar de uma noite para outra)
	var gap := (_cx - b.end.x - CAB_W * CAB_T - POSTER_W) / 3.0
	_draw_conduit(b, b.end.x + gap * 0.5)
	var cab := _draw_steel_cabinet((b.end.x + gap - _vp.x) / CAB_T)
	if "cartaz_quermesse" in details:
		_draw_poster(Rect2(floorf(cab.end.x + gap), 34, POSTER_W, 38))
	_zd = Vector2(Z0 * _yd / (front - _vp.y), Z0 / DESK_T)
	_draw_desk(Rect2(0, top, w, h - top), front)
	_draw_switchboard(front)
	_draw_side_wall(top, front, w)
	_draw_desk_props()
	_draw_street_light(w)
	_bolt_build(top)


## A camada por cima da sala (`_over`), com o que muda sozinho sem mexer nela: o escuro (`_draw_gloom`, que segue a
## luminária), o que entra pela janela (o relâmpago e o neon, `_draw_window_glow`), o escuro e a sombra atrás do papel
## de uma ferramenta aberta e as luzes da sala no brilho (`Bloom`), cortadas onde o papel está. (Tudo na sala, ela se
## redesenhava 3 a 4 vezes por segundo parada e a cada quadro do relâmpago e do papel deslizando, ~20 ms cada vez.)
## O relâmpago tem a camada dele (`_bolt_layer`).
func _draw_over() -> void:
	_ci = _over
	_cover = _paper()   # o papel da ferramenta aberta (ou deslizando) cobre o cenário por estar na frente
	Bloom.clear(_over)
	for l: Array in _glows:
		if not _cover.intersects(l[0]):
			Bloom.light(_over, l[0], l[1], l[2], l[3], l[4])
	if _sign_glow.has_area() and _sign_on() and not _cover.intersects(_sign_glow):   # só o halo: as letras ficam à vista
		Bloom.light(_over, _sign_glow, SIGN_RED, 0.5, false, false)
	_draw_gloom()
	_draw_window_glow()
	if _cover.has_area():   # uma ferramenta na frente do operador: o cenário atrás escurece e o papel faz sombra nele
		_ci.draw_set_transform(Vector2.ZERO)
		_ci.draw_rect(Rect2(_cover.position + Vector2(10, 12), _cover.size), Color(0, 0, 0, 0.35))
		_ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.28))
	_ci = self


## O clarão do relâmpago (`_bolt_layer`, uma camada somada por cima de tudo: a força é o `modulate`, o desenho fica): o que
## ele acende, medido com a sala (`_bolt_build`).
func _draw_bolt() -> void:
	_ci = _bolt_layer
	for l: Array in _bolt_lit:
		_fill(l[0], l[1])
	_ci = self


## O que o clarão do relâmpago acende (`_bolt_lit`, px da tela), só o que a janela alcança: a parede do fundo, mais
## forte perto da quina, menos a sombra do armário (a caixa dele levada até a parede pela luz, `BOLT_DIR`); a frente do
## armário (e o lado dele, se for o virado para a janela); a lateral da mesa comutadora; e, no tampo, a janela abaixo
## da persiana com a cruz do caixilho, nítida, e um halo em volta (`BOLT_STEEP`). O que fica na frente da parede e do
## armário (a mesa comutadora, os objetos da mesa, o tampo) sai do clarão; a frente da mesa comutadora fica no escuro.
func _bolt_build(top: float) -> void:
	_bolt_lit.clear()
	var xc := _cx - _vp.x
	if xc < 20.0 or _cab[1].size.x <= 0.0:
		return
	var wall := Rect2(0, 0, _cx * 2.0, top * 2.0)   # a parede do fundo à vista, acima do tampo
	var lit := func(poly: PackedVector2Array, force: Callable, occ: Array) -> void:
		for part: PackedVector2Array in _cut(poly, occ):
			var cols := PackedColorArray()
			for p in part:
				cols.append(Color(BOLT_LIGHT, force.call(p)))
			_bolt_lit.append([part, cols])
	var quad := func(r: Rect2) -> PackedVector2Array:
		return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var back: Rect2 = _cab[0]
	var front: Rect2 = _cab[1]
	var shadow := PackedVector2Array()   # a sombra do armário: o fundo dele e a frente levada até a parede pela luz
	var cab := PackedVector2Array()
	for c: Vector2 in quad.call(back):
		shadow.append_array([c * 2.0, (c + BOLT_DIR * (Z0 - Z0 / CAB_T)) * 2.0])
		cab.append(c * 2.0)
	for c: Vector2 in quad.call(front):
		cab.append(c * 2.0)
	shadow = Geometry2D.convex_hull(shadow)
	cab = Geometry2D.convex_hull(cab)
	var n := 16   # em faixas, para o degradê ficar liso
	for i in n:
		lit.call(quad.call(Rect2(wall.size.x * i / n, 0, wall.size.x / n, wall.size.y)), func(p: Vector2) -> float:
			return 0.3 * lerpf(0.3, 1.0, smoothstep(0.0, 1.0, p.x / wall.size.x)) * lerpf(0.75, 1.0, p.y / wall.size.y),
			[shadow, cab, _occ_board] + _occ)
	var f2 := Rect2(front.position * 2.0, front.size * 2.0).intersection(wall)   # a frente do armário: mais forte do lado da janela
	for i in 6:
		lit.call(quad.call(Rect2(f2.position.x + f2.size.x * i / 6.0, f2.position.y, f2.size.x / 6.0, f2.size.y)),
			func(p: Vector2) -> float: return 0.3 * lerpf(0.55, 1.0, (p.x - f2.position.x) / f2.size.x), _occ)
	if back.end.x > front.end.x:   # o lado dele que aparece é o da janela
		lit.call(PackedVector2Array([Vector2(front.end.x, front.position.y) * 2.0, Vector2(back.end.x, back.position.y) * 2.0,
			back.end * 2.0, front.end * 2.0]), func(_p: Vector2) -> float: return 0.42, _occ)
	for face: PackedVector2Array in _side_faces:
		lit.call(face, func(_p: Vector2) -> float: return 0.4, _occ)
	# no tampo: a janela abaixo da persiana, entrando na sala e descendo (`BOLT_STEEP`), com a cruz do caixilho (a
	# travessa e o montante, como em `_draw_side_wall`); ao longo da parede, z é linear (`_side_pt`); o que cairia atrás
	# do fundo do tampo fica fora
	var gh := _cm(WIN_SILL - WIN_TOP)
	var y0 := _cm(WIN_TOP)
	var ty := floorf(gh * 0.55) - 1.0
	var zfar := Z0 / SIDE_T   # a janela ao longo da parede: do lado da quina...
	var znear := Z0 / _t2     # ...ao de perto
	var zb := Z0 / DESK_T
	var zm := lerpf(zfar, znear, 0.5)
	var e := (zfar - znear) / SIDE_W   # meia largura do montante
	var land := func(y: float) -> float: return xc - (_yd - y) / BOLT_STEEP   # onde o raio que passa na altura `y` cai
	var pane := Color(BOLT_LIGHT, 0.5)
	for r: Vector2 in [Vector2(y0 + floorf(gh * BLIND), y0 + ty), Vector2(y0 + ty + 2.0, y0 + gh)]:
		for c: Vector2 in [Vector2(minf(zfar, zb), zm + e), Vector2(minf(zm - e, zb), znear)]:
			if c.x > c.y:
				var a: float = land.call(r.x)
				var b: float = land.call(r.y)
				_bolt_lit.append([PackedVector2Array([_p3(a, _yd, c.x), _p3(b, _yd, c.x), _p3(b, _yd, c.y), _p3(a, _yd, c.y)]),
					PackedColorArray([pane])])
	var za := minf(zfar, zb)
	if za > znear:   # o halo em volta, sumindo
		var xa: float = land.call(y0 + floorf(gh * BLIND))
		var xb: float = land.call(y0 + gh)
		var m := 10.0
		var inner := [_p3(xa, _yd, za), _p3(xb, _yd, za), _p3(xb, _yd, znear), _p3(xa, _yd, znear)]
		var outer := [_p3(xa - m, _yd, minf(za + m, zb)), _p3(minf(xb + m, xc), _yd, minf(za + m, zb)),
			_p3(minf(xb + m, xc), _yd, znear - m), _p3(xa - m, _yd, znear - m)]
		var glow := Color(BOLT_LIGHT, 0.14)
		for i in 4:
			_bolt_lit.append([PackedVector2Array([inner[i], inner[(i + 1) % 4], outer[(i + 1) % 4], outer[i]]),
				PackedColorArray([glow, glow, Color(glow, 0.0), Color(glow, 0.0)])])
	for part: Array in _sill_lit:   # o peitoril e a guarnição, junto do vidro
		var cols := PackedColorArray()
		for k: Color in part[1]:
			cols.append(Color(BOLT_LIGHT, k.a * 0.7))
		_bolt_lit.append([part[0], cols])


## `poly` sem o que fica na frente dele (`occ`, polígonos convexos): os pedaços que sobram. Antes de recortar, cada
## pedaço que encosta num deles é partido ao meio dele, na vertical: assim ele nunca fica inteiro dentro de um pedaço
## (o recorte viraria um buraco, que `_fill` pintaria cheio).
func _cut(poly: PackedVector2Array, occ: Array) -> Array:
	var parts := [poly]
	for o: PackedVector2Array in occ:
		if o.size() < 3:
			continue
		var ob := _bounds(o)
		var mid := ob.get_center().x
		var next := []
		for p: PackedVector2Array in parts:
			if not _bounds(p).intersects(ob):
				next.append(p)
				continue
			for half: Rect2 in [Rect2(-1e5, -1e5, 1e5 + mid, 2e5), Rect2(mid, -1e5, 1e5, 2e5)]:
				var hp := PackedVector2Array([half.position, Vector2(half.end.x, half.position.y), half.end, Vector2(half.position.x, half.end.y)])
				for q: PackedVector2Array in Geometry2D.intersect_polygons(p, hp):
					next.append_array(Geometry2D.clip_polygons(q, o))
		parts = next
	return parts


## O escuro da sala (noir): tudo o que a luz da luminária não alcança fica frio e escuro (`NOIR`), liso, crescendo da
## luz para fora (`GLOOM_IN`, `GLOOM_R`; com uma borda marcada, parecia um recorte). O vidro da janela fica de fora: a
## rua tem a luz dela. A luminária piscando escurece tudo junto.
func _draw_gloom() -> void:
	_ci.draw_set_transform(Vector2.ZERO)
	var pool := _pool()
	var c := _proj(pool.x, _yd, pool.y) * 2.0
	var dark := func(p: Vector2) -> Color:
		var k := smoothstep(GLOOM_IN, 1.0, ((p - c) / GLOOM_R).length())
		return Color(NOIR, clampf(NOIR.a * k + (1.0 - lamp_level) * 0.3, 0.0, 0.9))
	var glass := _bounds(_glass) if _glass.size() > 2 else Rect2()
	var n := Vector2i(40, 24)
	var cell := size / Vector2(n)
	var at := PackedColorArray()   # a cor em cada vértice da grade (cada um é de quatro células)
	for j in n.y + 1:
		for i in n.x + 1:
			at.append(dark.call(cell * Vector2(i, j)))
	for j in n.y:
		for i in n.x:
			var a := cell * Vector2(i, j)
			var quad := PackedVector2Array([a, a + Vector2(cell.x, 0), a + cell, a + Vector2(0, cell.y)])
			if not glass.intersects(Rect2(a, cell)):
				var k := j * (n.x + 1) + i
				_fill(quad, PackedColorArray([at[k], at[k + 1], at[k + n.x + 2], at[k + n.x + 1]]))
				continue
			for poly: PackedVector2Array in Geometry2D.clip_polygons(quad, _glass):
				var cols := PackedColorArray()
				for p in poly:
					cols.append(dark.call(p))
				_fill(poly, cols)
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O que entra pela janela, por cima do escuro da sala: um brilho azul bem fraco (a noite lá fora; liso, sumindo em
## volta dela) e o reflexo vermelho do letreiro. (A luz dos faróis de um carro varrendo a sala saiu a pedido: não
## parecia luz. O relâmpago é a camada `_bolt_layer`.)
func _draw_window_glow() -> void:
	if _glass.size() < 3:
		return
	_ci.draw_set_transform(Vector2.ZERO)
	var c := _bounds(_glass).get_center()
	var strength: float = WINDOW_GLOW.a * {"clear": 1.0, "rain": 0.8, "fog": 1.2}.get(weather, 1.0)
	_light_fan(c, _ring(c, WINDOW_GLOW_R), Color(WINDOW_GLOW, strength))
	if _sign_px != Vector2.ZERO and _sign_on():
		_light_fan(_sign_px, _ring(_sign_px, WINDOW_GLOW_R * 0.6), SIGN_GLOW)
	var sill := Color(0.42, 0.52, 0.66)
	for part: Array in _sill_lit:   # o peitoril na luz de fora
		var cols := PackedColorArray()
		for k: Color in part[1]:
			cols.append(Color(sill, k.a * 0.35))
		_fill(part[0], cols)
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Um círculo de raio `r` em volta de `c` (a borda de uma luz lisa, `_light_fan`).
func _ring(c: Vector2, r: float) -> PackedVector2Array:
	var rim := PackedVector2Array()
	for i in 32:
		rim.append(c + Vector2.from_angle(TAU * i / 32.0) * r)
	return rim


## A placa esmaltada da companhia telefônica, na parede acima da mesa comutadora (`b`, em px da tela), à direita do
## horário do turno colado ali: fundo verde-escuro, filete creme, o nome em creme (`SIGN_COMPANY`), um parafuso de
## latão em cada ponta e a sombra na parede. Em px da tela (1x1: o texto fica nítido).
func _draw_company_sign(b: Rect2) -> void:
	draw_set_transform(Vector2.ZERO)
	var company := T.text(T.Key.SIGN_COMPANY)
	var tw := Pal.mono.get_string_size(company, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var r := Rect2(roundf(b.position.x + b.size.x * SIGN_AT - (tw + 44.0) / 2.0), b.position.y - 36.0, roundf(tw + 44.0), 24.0)
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r.grow(1), Switchboard.EDGE_DARK)
	draw_rect(r, SIGN_ENAMEL)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), SIGN_ENAMEL.lightened(0.25))   # a luz na beira de cima
	draw_rect(r.grow(-3), SIGN_INK, false, 1.0)   # o filete
	for x in [r.position.x + 9.0, r.end.x - 9.0]:
		_sprite(PixelArt.disc(5, [[1.5, Color("e6cf8e"), Color("c4a35a"), Color("7a6230")], [2.5, Color("3a2a12")]]), Vector2(x, r.get_center().y))
	draw_string(Pal.mono, Vector2(roundf(r.get_center().x - tw / 2.0), r.position.y + 16.0), company, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, SIGN_INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O objeto sob o mouse: contorno e o nome da ferramenta que ele abre, desenhados em `ci` (o `SceneView`, por cima do
## cenário e na resolução da interface: o texto fica nítido).
func draw_hover(ci: CanvasItem) -> void:
	if _hot == "" or not _props.has(_hot):
		return
	var hr: Rect2 = _props[_hot]
	ci.draw_rect(hr.grow(2), Color(Pal.GLOW, 0.8), false, 2.0)
	var cap := T.text(PROPS[_hot])
	var cw := Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var at := Vector2(clampf(hr.get_center().x - cw / 2.0 - 5, 4, size.x - cw - 14), hr.position.y - 22)
	ci.draw_rect(Rect2(at, Vector2(cw + 10, 16)), Color(0, 0, 0, 0.8))
	ci.draw_string(Pal.ui, at + Vector2(5, 12), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT)


## O objeto da cena em `p` (px da tela), ou "" (nenhum, ou o papel de uma ferramenta por cima).
func prop_at(p: Vector2) -> String:
	if _cover.has_point(p):
		return ""
	for id in _props:
		if (_props[id] as Rect2).grow(2).has_point(p):
			return id
	return ""


## O mouse no cenário (o `SceneView` repassa: o cenário fica numa tela própria, fora da árvore da interface).
## Devolve se o evento foi usado (o clique num objeto).
func pointer(e: InputEvent) -> bool:
	if e is InputEventMouseMotion:
		var id := prop_at(e.position)
		if id != _hot:
			_hot = id
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id := prop_at(e.position)
		if id != "":
			prop_clicked.emit(id)
			return true
	return false


## O objeto sob o mouse ("" = nenhum).
func hot() -> String:
	return _hot


## O mouse saiu de cima do cenário.
func leave() -> void:
	if _hot != "":
		_hot = ""
		queue_redraw()


# ---------------------------------------------------------------- câmera

## Um ponto da sala na tela (px de 2x2): x e y a partir dos olhos, z a distância (ver `Z0`).
func _proj(x: float, y: float, z: float) -> Vector2:
	return _vp + Vector2(x, y) * (Z0 / z)


## O mesmo, em px da tela (os objetos da mesa, desenhados em 1x1).
func _p3(x: float, y: float, z: float) -> Vector2:
	return _proj(x, y, z) * 2.0


## O retângulo que contém os pontos `pts`.
func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


# ---------------------------------------------------------------- parede

## Papel de parede verde-escuro com listras e um friso de losangos (sem rodapé: embaixo dela é a mesa, não o chão).
func _draw_wall(r: Rect2) -> void:
	if wall_art:
		draw_texture_rect(wall_art, r, true)
		return
	_r(r.position.x, r.position.y, r.size.x, r.size.y, Color("172023"))
	var h := r.size.y * 2.0
	for x in range(0, int(r.size.x) * 2, 44):   # as listras: a larga com o fio de luz e, no meio, a fina
		_p(x, 0, 3, h, Color("141c1f"))
		_p(x + 3, 0, 1, h, Color("1b2629"))
		_p(x + 22, 0, 1, h, Color("1a2427"))
	var frieze := Color("1e2a2d")   # o friso no alto: dois fios e os losangos entre eles
	_p(0, 7, r.size.x * 2.0, 1, frieze)
	_p(0, 17, r.size.x * 2.0, 1, frieze)
	for x in range(0, int(r.size.x) * 2, 22):
		for i in 5:
			var half := 2 - absi(i - 2)
			_p(x + 9 - half, 10 + i, half * 2 + 1, 1, frieze)


## A luz da luminária na parede, atrás dela: o cone que desce da boca corta a parede num arco (alto no meio, descendo
## para os lados) e acaba no tampo, onde vira a poça de `_draw_desk`; a dobra na quina mostra que são dois planos.
## Lisa: mais forte embaixo da luminária, na quina com o tampo, e sumindo até o arco (`_light_fan`).
func _draw_wall_light(top: float) -> void:
	var m := 0.75
	var w := sqrt(pow((top - LAMP_Y) / m, 2.0) - WALL_GAP * WALL_GAP)
	var pts := PackedVector2Array()
	for i in 25:
		var x := _lamp_x - w + w * 2.0 * i / 24.0
		pts.append(Vector2(x, minf(top, LAMP_Y + sqrt(pow(x - _lamp_x, 2.0) + WALL_GAP * WALL_GAP) * m)))
	_light_fan(Vector2(_lamp_x, top), pts, Color(1.0, 0.8, 0.52, 0.15 * lamp_level))


## Uma luz lisa, sem camadas: a cor `col` no ponto `c`, sumindo até a borda `rim` (fechada, vista de `c`), com a cor
## variando ponto a ponto (forte perto de `c` e caindo depressa, como a luz; em camadas, parecia artificial).
func _light_fan(c: Vector2, rim: PackedVector2Array, col: Color) -> void:
	var mid := Color(col, col.a * 0.35)
	var out := Color(col, 0.0)
	for i in rim.size():
		var a := rim[i]
		var b := rim[(i + 1) % rim.size()]
		_ci.draw_primitive(PackedVector2Array([c, c.lerp(a, 0.5), c.lerp(b, 0.5)]), PackedColorArray([col, mid, mid]), PackedVector2Array())
		_fill(PackedVector2Array([c.lerp(a, 0.5), a, b, c.lerp(b, 0.5)]), PackedColorArray([mid, out, out, mid]))


## Sombra na parede de um objeto à frente dela (`r` em px de 2x2): a silhueta ampliada a partir da luminária, `s` vezes
## (mais longe da parede, maior), com a penumbra em degraus.
func _cast(r: Rect2, s: float) -> void:
	var l := Vector2(_lamp_x, LAMP_Y)
	for k in 3:
		var f := 1.0 + (s - 1.0) * (1.0 + k * 0.35)
		var p := (l + (r.position - l) * f).round()
		_r(p.x, p.y, roundf(r.size.x * f), roundf(r.size.y * f), Color(0, 0, 0, 0.14))


## Calendário de folhinha: cabeçalho vermelho e a grade dos dias, um deles riscado.
func _draw_calendar(r: Rect2) -> void:
	_cast(r, 1.01)
	var o := r.position * 2.0
	_p(o.x, o.y, r.size.x * 2.0, r.size.y * 2.0, Color("e3d6b2"))
	_p(o.x, o.y, r.size.x * 2.0, 12, Color("8e2a22"))   # o cabeçalho com o mês
	_p(o.x, o.y, r.size.x * 2.0, 1, Color("b04a3e"))
	_p(o.x + 10, o.y + 5, r.size.x * 2.0 - 20, 2, Color("e3d6b2"))
	for k in 20:   # os dias; os que já passaram (uma noite cada) ficam riscados de vermelho
		var d := o + Vector2(5 + (k % 5) * 9, 17 + (k / 5) * 8)
		_p(d.x, d.y, 1, 4, Color("6e6450"))
		_p(d.x + 2, d.y, 2, 1, Color("6e6450"))
		_p(d.x + 3, d.y + 1, 1, 3, Color("6e6450"))
		if k < night - 1:
			_ci.draw_line((d + Vector2(-1, 5)) * PX, (d + Vector2(6, -1)) * PX, Color("b03a2e"), PX)
	_p(o.x + r.size.x - 1, o.y - 2, 2, 2, Color("3a3a3a"))   # o prego


# ---------------------------------------------------------------- parede da direita e janela

## `v` cm da sala nas unidades da parede do fundo (px de 2x2 lá): a altura dos olhos acima do tampo é `SEAT_EYE`.
func _cm(v: float) -> float:
	return v * _yd / SEAT_EYE


## Um ponto do vão da janela (`p`: ao longo da parede, de 0 a `SIDE_W`, e a altura a partir do alto do vão; pode
## passar da borda) na tela (px de 2x2). A distância ao longo da parede é linear em 1/t: a perspectiva certa.
## `out`: para fora da parede (negativo: para dentro da sala), na mesma profundidade.
func _side_pt(p: Vector2, out := 0.0) -> Vector2:
	var t := 1.0 / lerpf(1.0 / SIDE_T, 1.0 / _t2, p.x / SIDE_W)
	return _vp + Vector2(_cx - _vp.x + out, _cm(WIN_TOP) + p.y) * t


## Um retângulo do vão da janela projetado na parede.
func _side_quad(r: Rect2, out := 0.0) -> PackedVector2Array:
	return PackedVector2Array([_side_pt(r.position, out), _side_pt(Vector2(r.end.x, r.position.y), out), _side_pt(r.end, out),
		_side_pt(Vector2(r.position.x, r.end.y), out)])


## A vista da janela, de frente, no vidro fora da tela (`_vport`, do tamanho da janela na tela, em px da tela; a
## vista é desenhada nas mesmas unidades do resto, em escala 2, com os detalhes em `PX`).
func _draw_view() -> void:
	_ci = _view
	_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var g := Rect2(Vector2.ZERO, Vector2(_vport.size) / 2.0)
	_win = g.size
	if not window_art:
		_draw_city_front(Rect2(g.position, g.size - Vector2(0, _near)))
		_draw_shrub()
	_draw_reflection(g)
	_draw_glass_weather(g)
	_ci = self


## A parte de trás da vista (`_back`), embaixo da frente: o céu, a cidade, a rua e as fachadas, que só mudam quando
## uma janela apaga, o neon falha, a luminária pisca, cai um relâmpago ou uma estrela pisca (`_back_state`).
## Redesenhada a cada quadro da vista com o resto, ela era dois terços do custo dela.
func _draw_view_back() -> void:
	_ci = _back
	_back.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var g := Rect2(Vector2.ZERO, Vector2(_vport.size) / 2.0)
	_win = g.size
	if window_art:
		_back.draw_texture_rect(window_art, g, false)
	else:
		_draw_city(Rect2(g.position, g.size - Vector2(0, _near)))   # a cidade até o peitoril de longe; embaixo, a rua de perto
	_ci = self


## Tudo de que a parte de trás da vista depende.
func _back_state() -> Array:
	var stars := 0   # as estrelas acesas agora (elas piscam)
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			if sin(tw + i * 1.7) > -0.6:
				stars |= 1 << i
	return [_vport.size, _near, weather, window_art, int(minutes), flick, lamp_level > 0.5, snappedf(_flash(), 0.02),
		_sign_on(), stars]


## À noite, com a sala acesa, o vidro reflete um pouco dela, por cima da cidade (e da silhueta, que fica atrás do
## reflexo): a luz da luminária, o contorno claro do armário e a luz quente da sala subindo de baixo. Liso, sem
## camadas, e acompanhando a luminária quando ela pisca. A vista passa da borda de cima da tela: só aparece do
## horizonte (58% da altura dela) para baixo, e é ali que o reflexo fica.
func _draw_reflection(g: Rect2) -> void:
	# o vidro é um espelho fraco: o que ele reflete é a sala espelhada no plano dele (fora da parede, `WALL_D`), vista
	# pela mesma câmera. De lado como ele está, só aparece o canto da parede do fundo perto da quina, com o resto do
	# arco de luz da luminária, e o armário, se ele cair ali; a luminária e a mesa ficam fora
	var xg := _cx - _vp.x + WALL_D
	var m := func(x: float, y: float, z: float) -> Vector2: return _proj(2.0 * xg - x, y, z) - _view_at
	var lamp := Color(1.0, 0.82, 0.55, 0.1 * lamp_level)
	var none := Color(lamp, 0.0)
	var lx := _lamp_x - _vp.x
	var xc := _cx - _vp.x
	var y0 := LAMP_Y - _vp.y
	var y1 := _top - _vp.y
	_fill(PackedVector2Array([m.call(lx, y0, Z0), m.call(xc, y0, Z0), m.call(xc, y1, Z0), m.call(lx, y1, Z0)]),
		PackedColorArray([lamp, Color(lamp, lamp.a * 0.3), none, Color(lamp, lamp.a * 0.4)]))
	var zf := Z0 / CAB_T   # a frente do armário: clara no meio (a luz da luminária), sumindo para baixo
	var steel := Color(0.75, 0.8, 0.65, 0.07 * lamp_level)
	var ct := _cm(CAB_TOP)
	var cx0 := _cab_x0
	var cx1 := _cab_x0 + CAB_W
	_fill(PackedVector2Array([m.call(cx0, ct, zf), m.call(cx1, ct, zf), m.call(cx1, y1, zf), m.call(cx0, y1, zf)]),
		PackedColorArray([steel, Color(steel, steel.a * 0.5), Color(steel, 0.0), Color(steel, 0.0)]))


## A mesa comutadora é um móvel só, em pé no tampo: embaixo, o console, cuja frente é a faixa de mesa (`desk`, com o
## rádio embutido) e cujo alto é a prateleira, onde ficam o encaixe do FONE e os buracos dos cabos com os plugs em pé
## (a mesa desenha); no fundo da prateleira, o painel (`board`). A interface é a frente do painel e do rádio; aqui
## ficam a frente do console em volta dele, a prateleira com o rodapé e a sombra do painel, a lateral em L virada para o ponto de fuga (o console até o fundo do móvel,
## `BOARD_D`, e o painel em cima dele) e, com os olhos acima dele, o tampo do painel. Painel e console têm a mesma
## largura na sala: o console, mais perto, sai mais largo na tela (a esquerda passa da borda). Em px da tela (1x1).
func _draw_switchboard(front: float) -> void:
	if not (board and desk):
		return
	draw_set_transform(Vector2.ZERO)
	var vp := _vp * 2.0
	var b := Rect2(board.global_position - global_position, board.size)
	var sy := desk.global_position.y - global_position.y   # a prateleira, no alto da faixa de mesa
	var fy := front * 2.0                                  # o pé do console, na borda da frente do tampo
	var k := (b.end.y - vp.y) / maxf(1.0, sy - vp.y)       # quanto o painel encolhe visto da frente do console
	var zp := _zd.x / k                                    # o painel (z): o console começa na frente do tampo
	var kb := zp / (zp + BOARD_D)
	_side_x = (b.end.x / 2.0 - _vp.x) * zp / Z0
	var near := func(p: Vector2) -> Vector2: return vp + (p - vp) / k    # da linha do painel para a frente
	var back := func(p: Vector2) -> Vector2: return vp + (p - vp) * kb   # da linha do painel para o fundo
	var fx0: float = near.call(Vector2(b.position.x, b.end.y)).x
	var fx1: float = near.call(b.end).x
	var low := Vector2(fx1, fy)   # o canto de baixo da frente, do lado do ponto de fuga
	_shelf = low
	var deep := func(p: Vector2) -> Vector2: return vp + (p - vp) * k * kb   # da frente do console para o fundo
	var low_back: Vector2 = deep.call(low)
	_desk_shadow(PackedVector2Array([Vector2(fx0, fy), low, low_back, deep.call(Vector2(fx0, fy))]))
	if b.end.x < vp.x - 2.0:   # a lateral em L: o console e, em cima dele, o painel
		var side := WOOD[2] as Color
		_side_faces = [PackedVector2Array([Vector2(fx1, sy), low, low_back, back.call(b.end)]),
			PackedVector2Array([Vector2(b.end.x, b.position.y), b.end, back.call(b.end), back.call(Vector2(b.end.x, b.position.y))])]
		for q: PackedVector2Array in _side_faces:
			_poly(q, side)
		for i in range(1, 7):   # o veio, no rumo do ponto de fuga
			var p := Vector2(b.end.x, b.position.y + b.size.y * i / 7.0 + (i % 2) * 5.0)
			draw_line(p, back.call(p), WOOD[1], 1.0)
		for y in [sy + (fy - sy) * 0.4, sy + (fy - sy) * 0.75]:
			draw_line(Vector2(fx1, y), deep.call(Vector2(fx1, y)), WOOD[1], 1.0)
		draw_line(Vector2(b.end.x, b.position.y), b.end, WOOD[0], 1.0)   # as quinas da frente pegam a luz
		draw_line(Vector2(fx1, sy), low, WOOD[0], 1.0)
	# a frente do console (aparece entre as peças embutidas), com a beira de cima e o rodapé
	_r(fx0, sy, fx1 - fx0, fy - sy, WOOD[1])
	_r(fx0, sy, fx1 - fx0, 2, WOOD[0])
	_r(fx0, fy - 3, fx1 - fx0, 3, WOOD[2])
	# a prateleira: o painel pousa no fundo dela, num rodapé, com a sombra de contato na frente
	_poly(PackedVector2Array([Vector2(fx0, sy), Vector2(fx1, sy), b.end, Vector2(b.position.x, b.end.y)]), Color("5a3a22"))
	for t in [0.3, 0.55, 0.8]:   # os veios da prateleira, de lado a lado
		var y := roundf(lerpf(sy, b.end.y, t))
		_r(lerpf(fx0, b.position.x, t), y, lerpf(fx1, b.end.x, t) - lerpf(fx0, b.position.x, t), 1, Color("4e321d"))
	_r(fx0, sy - 1, fx1 - fx0, 2, Color("8a6a2e"))   # o friso de latão na beira
	_r(fx0, sy - 1, fx1 - fx0, 1, Color("c4a35a"))
	var radio := desk.get_node_or_null("Mini") as Control
	if radio and radio.visible:   # na frente do console, em volta da miniatura do painel: a plaqueta e os botões dele
		var rr := Rect2(radio.global_position - global_position, radio.size)
		var my := roundf((sy + fy) / 2.0)
		var plate := Rect2(rr.position.x - 74, my - 8, 56, 16)
		draw_rect(Rect2(plate.position + Vector2(1, 1), plate.size), Color(0, 0, 0, 0.35))
		draw_rect(plate, Color("8a6a2e"))
		draw_rect(Rect2(plate.position, Vector2(plate.size.x, 1)), Color("c4a35a"))
		for i in 2:   # o nome gravado (as letras não se leem dessa distância)
			draw_rect(Rect2(plate.position.x + 8, plate.position.y + 5 + i * 5, plate.size.x - 16 - i * 12, 1), Color("4a3a18"))
		for i in 2:   # baquelite: a borda em volta do tampo, os dois com a luz no alto à esquerda
			var c := Vector2(rr.end.x + 24 + i * 30, my)
			_sprite(PixelArt.disc(19, [[9.0, Color(0, 0, 0, 0.35)]]), c + Vector2(1, 2))
			_sprite(PixelArt.disc(17, [[5.5, Color("5a5048"), Color("3a332c"), Color("2a2420")],
				[7.5, Color("4a4038"), Color("2a2420"), Color("1a1612")], [8.5, Color("120e0a")]]), c)
			var a := -PI * 0.75 + i * 1.1
			for j in range(2, 7):   # o risco de posição, pixel a pixel
				draw_rect(Rect2((c + Vector2(cos(a), sin(a)) * j).floor(), Vector2.ONE), Color("d6d1c3"))
	for p in [Vector2(fx1 - 8, sy + 8), Vector2(fx1 - 8, fy - 10), Vector2(8, sy + 8), Vector2(8, fy - 10)]:   # os parafusos
		if p.x > fx0 + 4:
			_sprite(PixelArt.disc(5, [[2.5, Color("4a3a24"), Color("2a1a0f"), Color("1a0f08")]]), p)
			draw_rect(Rect2(p.floor() - Vector2(1, 0), Vector2(3, 1)), Color("8e7a5a"))   # a fenda
	draw_rect(Rect2(b.position.x, b.end.y, b.size.x, 3), WOOD[2])
	_poly(PackedVector2Array([Vector2(b.position.x, b.end.y + 3), Vector2(b.end.x, b.end.y + 3),
		Vector2(b.end.x + 2, b.end.y + 7), Vector2(b.position.x - 3, b.end.y + 7)]), Color(0, 0, 0, 0.3))
	if b.position.y > vp.y + 1.0:   # os olhos estão acima do painel: o tampo dele aparece
		var tl := b.position
		var tr := Vector2(b.end.x, b.position.y)
		_poly(PackedVector2Array([tl, tr, back.call(tr), back.call(tl)]), WOOD[0])
	_occ_board = Geometry2D.convex_hull(PackedVector2Array([b.position, Vector2(b.end.x, b.position.y), b.end, Vector2(b.position.x, b.end.y),
		back.call(b.end), back.call(Vector2(b.end.x, b.position.y)), Vector2(fx1, sy), low, low_back, Vector2(fx0, fy), Vector2(fx0, sy)]))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## A parede da direita, entrando para o fundo a partir da quina (`_cx`): cobre o que fica atrás dela (a mesa termina
## nela, numa linha que foge para o ponto de fuga; entre a quina e o fundo do tampo ela desce atrás da mesa), com as
## listras do papel de parede alargando para a frente, o friso subindo para fora da tela e a janela vista de lado:
## batente, o lado de dentro do vão perto da quina, a vista (reta: está longe) recortada pelo vidro, o caixilho e a
## persiana na perspectiva da parede, e o peitoril. A luz da rua entra por ela e cai na mesa, na diagonal.
func _draw_side_wall(top: float, front: float, w: float) -> void:
	var xc := _cx - _vp.x
	if xc < 20.0:   # a tela ainda não se arrumou (primeiro quadro)
		return
	var te := (w - _vp.x) / xc   # a escala na borda da tela
	var j := _vp + Vector2(xc, _yd) * te
	var d := _vp + Vector2(xc, _yd) * DESK_T
	_t2 = (w - 14.0 - _vp.x) / xc
	var wall := Color("202d30")   # virada para a luminária: mais clara que a do fundo (é o que mostra a quina)
	_poly(PackedVector2Array([Vector2(_cx, 0), Vector2(w, 0), j, d, Vector2(_cx, top)]), wall)
	var k := 1
	while true:   # as listras: passos iguais na parede são passos iguais em 1/t
		var inv := 1.0 - k * 0.04
		if inv <= 0.0:
			break
		var t := 1.0 / inv
		var x := _vp.x + xc * t
		if x >= w:
			break
		var bottom := top if t < DESK_T else _vp.y + _yd * t
		var sw := maxf(2.0, roundf(3.0 * t))   # mais perto, mais larga (em px da tela)
		_p(roundf(x * 2.0), 0, sw, roundf(bottom * 2.0), Color("1b2629"))
		_p(roundf(x * 2.0) + sw, 0, 1, roundf(bottom * 2.0), Color("24323a"))
		k += 1
	for fy in [3.5, 8.5]:   # o friso: os dois fios, subindo para fora da tela
		draw_line(Vector2(_cx, fy), Vector2(w, _vp.y + (fy - _vp.y) * te), Color("26353a"), PX)
	for i in 3:   # a quina: a parede da direita escurece de leve perto dela
		_r(_cx, 0, 6 - i * 2, top, Color(0, 0, 0, 0.06))
	# o vão tem a espessura da parede (`WALL_D`): a guarnição fica na parede, o vidro do lado de fora. Sair da parede é
	# andar na horizontal da tela (a mesma profundidade, mais longe de lado): aparecem o lado de dentro do batente de
	# longe (perto da quina) e o fundo do vão embaixo, e o batente de perto esconde uma tira do vidro
	var gw := SIDE_W
	var gh := _cm(WIN_SILL - WIN_TOP)
	var blind := floorf(gh * BLIND)
	var inner := _side_quad(Rect2(0, 0, gw, gh))
	var outer := _side_quad(Rect2(0, 0, gw, gh), WALL_D)
	var cut := Geometry2D.intersect_polygons(inner, outer)
	if cut.is_empty():
		return
	var q: PackedVector2Array = cut[0]   # o vidro que aparece pelo vão
	_poly(_side_quad(Rect2(-5, -5, gw + 10, gh + 10)), WOOD[2])   # a guarnição, na parede
	_poly(_side_quad(Rect2(-4, -4, gw + 8, gh + 8)), WOOD[1])
	_poly(_side_quad(Rect2(-4, -4, gw + 8, 1)), WOOD[0])
	# a vista, reta, recortada pelo vidro: o horizonte dela na altura dos olhos
	var box := _bounds(outer)
	box = box.intersection(Rect2(0, 0, w, box.end.y))
	# a cidade põe o horizonte a 58% da altura: na altura dos olhos, com a rua logo acima do peitoril de longe
	var low := _side_pt(Vector2(0, gh)).y
	var vh := (low - _vp.y) / 0.42
	_near = ceilf(maxf(0.0, minf(box.end.y, _side_pt(Vector2(gw, gh)).y) - low))   # o vidro de perto desce mais: ali aparece a rua embaixo da janela
	var view := Rect2(floorf(box.position.x), floorf(low - vh), ceilf(box.size.x) + 1, ceilf(vh) + _near)
	_view_at = view.position
	# o vidro que aparece começa abaixo da persiana (e da borda de cima da tela): as gotas ficam dali para baixo
	_glass_from = clampf((maxf(0.0, _side_pt(Vector2(gw * 0.5, blind)).y) - view.position.y) / view.size.y, 0.0, 0.95)
	if _vport.size != Vector2i(view.size * 2.0):   # o vidro em px da tela: a vista também é desenhada em 1x1
		_vport.size = Vector2i(view.size * 2.0)
		_back.queue_redraw()   # já, e não no próximo quadro dela: na pausa (a janela mudando de tamanho), ficava vazia
		_view.queue_redraw()
		_vport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var uv := PackedVector2Array()
	for p in q:
		uv.append((p - view.position) / view.size)
	draw_polygon(q, PackedColorArray([Color.WHITE]), uv, _vport.get_texture())
	# as luzes da vista brilham onde aparecem no vidro: o relógio da igreja e o poste
	var cg := Rect2(view.position, view.size - Vector2(0, _near))   # a cidade, como `_draw_city` a vê
	var face := _church_pos(cg) - Vector2(0, 40 * CHURCH_K)
	if Geometry2D.is_point_in_polygon(face, q):
		_light(Rect2(face * 2.0 - Vector2(2.6, 2.6), Vector2(5.2, 5.2)), Color("e2b25a"), 0.5, true)
	var sign := _hotel_pos(cg) + Vector2(2, 8)
	_sign_px = sign * 2.0 if Geometry2D.is_point_in_polygon(sign, q) else Vector2.ZERO
	_sign_glow = Rect2(_sign_px - Vector2(4, 16), Vector2(8, 32)) if _sign_px != Vector2.ZERO else Rect2()
	for lamp: Vector2 in _lamp_heads(cg):   # os postes de lá
		if lamp_level > 0.5 and Geometry2D.is_point_in_polygon(lamp, q):
			_light(Rect2((lamp + Vector2(-1.5, 0)) * 2.0, Vector2(6, 3)), Color("ffd88a"), 0.8)
	# o caixilho em cruz, no vidro: a frente dele e, por estar abaixo e ao lado dos olhos, o alto da travessa e o lado
	# de perto do montante; o que passa do vão fica atrás do batente
	var bar := func(poly: PackedVector2Array, col: Color) -> void:
		for part in Geometry2D.intersect_polygons(poly, inner):
			_poly(part, col)
	var mx := gw / 2.0
	var ty := floorf(gh * 0.55) - 1
	var f := WALL_D - 3.0
	bar.call(PackedVector2Array([_side_pt(Vector2(0, ty), f), _side_pt(Vector2(gw, ty), f), _side_pt(Vector2(gw, ty), WALL_D),
		_side_pt(Vector2(0, ty), WALL_D)]), WOOD[0])
	bar.call(_side_quad(Rect2(0, ty, gw, 2), f), WOOD[1])
	bar.call(PackedVector2Array([_side_pt(Vector2(mx + 1, 0), f), _side_pt(Vector2(mx + 1, 0), WALL_D), _side_pt(Vector2(mx + 1, gh), WALL_D),
		_side_pt(Vector2(mx + 1, gh), f)]), WOOD[2])
	bar.call(_side_quad(Rect2(mx - 1, 0, 2, gh), f), WOOD[1])
	# as faces do vão: frias de fora (a rua) para dentro; o alto dele (a verga) passa da borda de cima da tela
	var lit := Color("3a5263")
	var dim := Color("223033")
	_fill(PackedVector2Array([inner[0], outer[0], outer[3], inner[3]]), PackedColorArray([dim, lit, lit, dim]))   # o batente de longe
	# o fundo do vão: a tábua do peitoril vai da sala até o caixilho, na mesma madeira (escura, parecia um buraco), com
	# o trilho de baixo do caixilho no pé do vidro; o que passa do batente de perto fica atrás da parede
	for part in Geometry2D.intersect_polygons(PackedVector2Array([inner[3], inner[2], outer[2], outer[3]]), inner):
		_poly(part, WOOD[1])
	for part in Geometry2D.intersect_polygons(_side_quad(Rect2(0, gh - 2.5, gw, 2.5), WALL_D - 1.0), inner):
		_poly(part, WOOD[2])
	for part in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([_side_pt(Vector2(0, gh - 2.5), WALL_D - 1.0),
			_side_pt(Vector2(gw, gh - 2.5), WALL_D - 1.0)]), inner):
		draw_polyline(part, WOOD[0], PX)
	_poly(PackedVector2Array([inner[0], inner[1], outer[1], outer[0]]), Color("0d1315"))
	# a persiana meio baixada, presa no lado de dentro do vão
	_glass = PackedVector2Array()
	var below := Geometry2D.intersect_polygons(_side_quad(Rect2(0, blind, gw, gh - blind)), _side_quad(Rect2(0, blind, gw, gh - blind), WALL_D))
	if not below.is_empty():
		for p in below[0]:
			_glass.append(p * 2.0)
	for y in range(0, int(blind), 2):   # as lâminas: a face clara, o fio de luz na beira e a sombra embaixo
		_poly(_side_quad(Rect2(0, y, gw, 1.5)), Color("8a8070"))
		_poly(_side_quad(Rect2(0, y, gw, PX)), Color("a89e8a"))
		_poly(_side_quad(Rect2(0, y + 1.5, gw, PX)), Color("3a352c"))
	draw_line(_side_pt(Vector2(gw * 0.8, blind)), _side_pt(Vector2(gw * 0.8, blind + 8)), Color("8a8070"), PX)   # o cordão
	_poly(_side_quad(Rect2(gw * 0.8 - 1, blind + 8, 2, 2)), Color("6b5f4c"))   # o puxador dele
	# o peitoril de dentro: uma tábua saindo da parede para a sala (`SILL_D`), com o tampo à vista (fica abaixo dos
	# olhos), a beira da frente e a sombra dela na parede
	var s0 := Vector2(-5, gh)   # do tamanho da guarnição (passando dela, saía da janela)
	var s1 := Vector2(gw + 5, gh)
	_poly(_side_quad(Rect2(-5, gh + 3, gw + 10, 6)), Color(0, 0, 0, 0.25))
	_poly(PackedVector2Array([_side_pt(s0), _side_pt(s1), _side_pt(s1, -SILL_D), _side_pt(s0, -SILL_D)]), WOOD[1])
	_poly(_side_quad(Rect2(-5, gh, gw + 10, 3), -SILL_D), WOOD[2])
	draw_line(_side_pt(s0, -SILL_D), _side_pt(s1, -SILL_D), WOOD[0], PX)
	# a ponta de perto da tábua, virada para quem olha: fecha a lateral dela
	_poly(PackedVector2Array([_side_pt(s1), _side_pt(s1, -SILL_D), _side_pt(s1 + Vector2(0, 3), -SILL_D),
		_side_pt(s1 + Vector2(0, 3))]), WOOD[1])
	# a luz de fora no peitoril: ele fica fora do vidro, e o escuro da sala o deixava quase preto (parecia um buraco);
	# mais clara junto do vidro, sumindo para a sala
	_sill_lit.clear()
	var x2 := func(poly: PackedVector2Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in poly:
			out.append(p * 2.0)
		return out
	for part in Geometry2D.intersect_polygons(PackedVector2Array([inner[3], inner[2], outer[2], outer[3]]), inner):
		var cols := PackedColorArray()
		for p in part:
			cols.append(Color(0, 0, 0, 0.7))   # (a força relativa; a cor vem na hora de desenhar)
		_sill_lit.append([x2.call(part), cols])
	_sill_lit.append([x2.call(PackedVector2Array([_side_pt(s0), _side_pt(s1), _side_pt(s1, -SILL_D), _side_pt(s0, -SILL_D)])),
		PackedColorArray([Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.15), Color(0, 0, 0, 0.15)])])
	# a guarnição do lado de perto (ficava quase preta e, com a ponta da tábua aberta, parecia um vão): mais clara
	# junto do vidro
	_sill_lit.append([x2.call(PackedVector2Array([_side_pt(Vector2(gw, -4)), _side_pt(Vector2(gw + 5, -4)), _side_pt(Vector2(gw + 5, gh)),
		_side_pt(Vector2(gw, gh))])), PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.1), Color(0, 0, 0, 0.1), Color(0, 0, 0, 0.45)])])


## Os fios da mesa comutadora indo para a cidade: um feixe de cabos de pano sai do alto do painel (`b`, px de 2x2)
## e entra numa caixa de passagem na parede, de onde um conduíte de ferro sobe até o teto (em `x`, no vão entre a mesa
## comutadora e o armário), preso por braçadeiras. A mesa esconde o pé dele.
func _draw_conduit(b: Rect2, x: float) -> void:
	var pipe := Color("4a5256")
	_r(x - 2, 0, 4, _top, pipe)
	_r(x - 2, 0, 1, _top, pipe.lightened(0.3))   # a luz da luminária do lado de cá
	_r(x + 2 - PX, 0, PX, _top, pipe.darkened(0.45))
	_r(x + 2, 0, 1.5, _top, Color(0, 0, 0, 0.25))   # a sombra na parede
	var y := 6.0
	while y < _top:   # as braçadeiras
		_r(x - 3, y, 6, 1.5, pipe.lightened(0.15))
		_r(x - 3, y + 1.5, 6, PX, pipe.darkened(0.35))
		y += 36.0
	var box := Rect2(x - 6, b.position.y - 34, 12, 14)   # a caixa de passagem, com a tampa parafusada
	_r(box.position.x + 1, box.position.y + 1, box.size.x, box.size.y, Color(0, 0, 0, 0.25))
	_r(box.position.x, box.position.y, box.size.x, box.size.y, Color("4a5256"))
	_r(box.position.x, box.position.y, box.size.x, PX, Color("6e777b"))
	_r(box.position.x + 1, box.position.y + 1, box.size.x - 2, box.size.y - 2, Color("545c60"))
	for c in [Vector2(1.5, 1.5), Vector2(box.size.x - 2.5, 1.5), Vector2(1.5, box.size.y - 2.5), Vector2(box.size.x - 2.5, box.size.y - 2.5)]:
		_r(box.position.x + c.x, box.position.y + c.y, 1, 1, Color("7a8286"))
	# os cabos: da boca de baixo da caixa até o alto do painel, um pouco caídos, cada um num pano velho
	var cloth := [Color("4a3a2c"), Color("5a3428"), Color("37403f"), Color("524430")]
	for i in cloth.size():
		var a := Vector2(box.position.x + 2.5 + i * 2.0, box.end.y)
		var e := Vector2(b.end.x - 12 - i * 6.0, b.position.y + 2)
		var pts := PackedVector2Array()
		for k in 13:
			var t := k / 12.0
			pts.append(a.lerp(e, t) + Vector2(0, sin(PI * t) * (4.0 + i * 1.5)))
		draw_polyline(pts, (cloth[i] as Color).darkened(0.4), 1.5)
		draw_polyline(pts, cloth[i], 1.0)
		draw_polyline(pts, (cloth[i] as Color).lightened(0.25), PX)


## A luz da rua na mesa: a parte do vão abaixo da persiana projetada no tampo, descendo para dentro da sala
## (`STREET_LIGHT`). O peitoril faz sombra junto da parede, então ela começa um pouco longe dela, e o que cairia atrás
## do fundo do tampo fica fora da mesa. Desenhada depois dos objetos da mesa: eles ficam na luz também. Grande e bem
## lisa: sobe devagar do lado do peitoril e do fundo do tampo, some devagar para longe e para a frente, espalhando-se
## além da janela (a luz da noite é difusa).
func _draw_street_light(w: float) -> void:
	var xc := _cx - _vp.x
	if xc < 20.0:
		return
	var te := (w - _vp.x) / xc
	var cool: float = {"clear": 0.05, "rain": 0.035, "fog": 0.02}.get(weather, 0.035)
	var gh := _cm(WIN_SILL - WIN_TOP)
	var hs: Array[float] = [_cm(WIN_SILL), _cm(WIN_TOP) + floorf(gh * BLIND)]   # do peitoril ao pé da persiana
	var ts: Array[float] = [maxf(SIDE_T, DESK_T), minf(_t2, te)]
	if ts[1] < ts[0] + 0.02:   # (com a tela mudando de tamanho, a janela pode ainda não chegar à mesa)
		return
	var street := Color(0.6, 0.72, 0.9)
	var on_desk := func(u: float, v: float) -> Vector2:   # u: do peitoril (0) ao alto (1), e além; v: ao longo da parede, e além
		var drop := _yd - lerpf(hs[0], hs[1], u)
		return _proj(xc - drop / STREET_LIGHT, _yd, Z0 / maxf(DESK_T, lerpf(ts[0], ts[1], v)))   # (nunca atrás do tampo)
	var glow := func(u: float, v: float) -> Color:
		var a := smoothstep(-0.35, 0.45, u) * smoothstep(1.65, 0.6, u) * smoothstep(0.0, 0.45, v) * smoothstep(1.35, 0.55, v)
		return Color(street, cool * a * 4.5)
	var n := 14
	for i in n:
		for k in n:
			var u0 := lerpf(-0.35, 1.65, float(i) / n)
			var u1 := lerpf(-0.35, 1.65, float(i + 1) / n)
			var v0 := lerpf(0.0, 1.35, float(k) / n)
			var v1 := lerpf(0.0, 1.35, float(k + 1) / n)
			_fill(PackedVector2Array([on_desk.call(u0, v0), on_desk.call(u0, v1), on_desk.call(u1, v1), on_desk.call(u1, v0)]),
				PackedColorArray([glow.call(u0, v0), glow.call(u0, v1), glow.call(u1, v1), glow.call(u1, v0)]))


## Armário de aço antigo, de chão, encostado na parede do fundo atrás da mesa (`x0` a partir do ponto de fuga, `CAB_W`, `CAB_TOP`, `CAB_T`; a mesa,
## desenhada depois, esconde a base): cornija no alto, duas portas verde-acinzentadas com venezianas, o porta-etiqueta
## niquelado, o puxador com a fechadura, as dobradiças e um calendário preso com ímã. Devolve a frente (px de 2x2).
func _draw_steel_cabinet(x0: float) -> Rect2:
	_cab_x0 = x0
	var back := Rect2(_vp + Vector2(x0, _cm(CAB_TOP)), Vector2(CAB_W, 400))
	_cast(back, 1.05)
	var f := Rect2((_vp + Vector2(x0, _cm(CAB_TOP)) * CAB_T).round(), (Vector2(CAB_W, 400) * CAB_T).round())
	_cab = [back, f]
	var steel := Color("566052")
	if back.position.x < f.position.x:   # à direita do ponto de fuga: aparece o lado esquerdo, fugindo para a parede
		_poly(PackedVector2Array([back.position, f.position, Vector2(f.position.x, f.end.y), Vector2(back.position.x, back.end.y)]),
			steel.darkened(0.45))
	elif back.end.x > f.end.x:   # à esquerda: o lado direito
		_poly(PackedVector2Array([Vector2(f.end.x, f.position.y), Vector2(back.end.x, back.position.y), back.end, f.end]),
			steel.darkened(0.3))
	if CAB_TOP > 0.0:   # os olhos acima dele: o tampo aparece, fugindo para a parede
		_poly(PackedVector2Array([back.position + Vector2(-2, 0), Vector2(back.end.x + 2, back.position.y),
			Vector2(f.end.x + 2, f.position.y - 1), Vector2(f.position.x - 2, f.position.y - 1)]), steel.darkened(0.2))
	_r(f.position.x, f.position.y, f.size.x, f.size.y, steel)
	for i in 36:   # a luz da luminária, mais forte do lado dela, caindo pixel a pixel (em faixas largas, pareciam camadas)
		_r(f.position.x + i * PX, f.position.y, PX, f.size.y, Color(1.0, 0.85, 0.6, 0.09 * (1.0 - i / 36.0) * lamp_level))
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, 5, steel.darkened(0.15))   # a cornija, com o friso
	_r(f.position.x - 2, f.position.y - 1, f.size.x + 4, PX, steel.lightened(0.3))
	_r(f.position.x - 2, f.position.y + 1.5, f.size.x + 4, PX, steel.darkened(0.3))
	_r(f.position.x - 2, f.position.y + 4, f.size.x + 4, 1, Color("23281f"))
	_r(f.position.x, f.position.y + 5, PX, f.size.y, steel.lightened(0.15))   # a luz à esquerda, a sombra à direita
	_r(f.end.x - PX, f.position.y + 5, PX, f.size.y, steel.darkened(0.3))
	var mid := floorf(f.get_center().x)
	var doors := f.position.y + 8
	_r(mid - PX, doors, PX, f.size.y, Color("23281f"))   # a fresta entre as portas
	_r(mid, doors, PX, f.size.y, steel.lightened(0.12))
	var low := _top - 30.0   # a parte de baixo que aparece, logo acima da mesa (ela esconde o pé)
	for door in [Rect2(f.position.x + 3, doors, mid - f.position.x - 5, 60), Rect2(mid + 2, doors, f.end.x - mid - 5, 60)]:
		for y0 in [door.position.y + 4, low]:   # as venezianas, no alto e embaixo de cada porta: a fenda e a aba que pega a luz
			for i in 6:
				_r(door.position.x + 6, y0 + i * 4, door.size.x - 12, 1.5, Color("2e342b"))
				_r(door.position.x + 6, y0 + 1.5 + i * 4, door.size.x - 12, PX, steel.lightened(0.25))
				_r(door.position.x + 6, y0 + i * 4, PX, 2, steel.darkened(0.2))
	# um amassado antigo na porta da esquerda, perto de baixo: a sombra em cima e a luz embaixo
	var dent := Vector2(f.position.x + 30, low - 16)
	_r(dent.x, dent.y, 9, PX, steel.darkened(0.3))
	_r(dent.x + 1, dent.y + PX, 7, PX, steel.darkened(0.18))
	_r(dent.x + 1, dent.y + 2, 7, PX, steel.lightened(0.15))
	for i in 5:   # riscos de chave e de sapato na beira de baixo
		_r(f.position.x + 8 + i * 13.0 + (i * 7) % 5, low - 4 - (i % 3), 3 + i % 2, PX, steel.lightened(0.22))
	# o porta-etiqueta na porta da esquerda, com o cartão datilografado
	var lab := Rect2(f.position.x + 12, doors + 34, 24, 11)
	_r(lab.position.x - PX, lab.position.y - PX, lab.size.x + 1, lab.size.y + 1, Color("8e897c"))
	_r(lab.position.x - PX, lab.position.y - PX, lab.size.x + 1, PX, Color("c9c4b5"))
	_r(lab.position.x, lab.position.y, lab.size.x, lab.size.y, Color("e3d6b2"))
	for i in 3:
		_r(lab.position.x + 2.5, lab.position.y + 2.5 + i * 2.5, lab.size.x - 5 - i * 4, PX, Color("4a4438"))
	# o puxador e a fechadura, junto da fresta, na altura da mão
	var hy := floorf((doors + low) / 2.0)   # na altura da mão: no meio da porta
	_r(mid + 4, hy, 2.5, 16, Color("3a3d33"))
	_r(mid + 4, hy, 2, 15.5, Color("b8b2a2"))
	_r(mid + 4, hy, PX, 15.5, Color("ece7da"))
	_sprite(PixelArt.disc(8, [[3.0, Color("b8b2a2"), Color("8e897c"), Color("5a574e")], [4.0, Color.BLACK]]), Vector2(mid + 5.25, hy - 5) * 2.0, Color.WHITE, X2)
	_r(mid + 5, hy - 6, PX, 1.5, Color("23281f"))
	for y in [doors + 4, floorf((doors + low) / 2.0) + 10.0, low]:   # as dobradiças
		for x in [f.position.x - 1, f.end.x - 1]:
			_r(x, y, 1.5, 7, Color("8e897c"))
			_r(x, y, PX, 7, Color("c9c4b5"))
			_r(x, y + 3.5, 1.5, PX, Color("4a4840"))
	if "armario_entreaberto" in details:   # a porta da direita aberta: o vão com as prateleiras e as pastas, a porta de lado
		var inside := Rect2(mid + 1, doors, f.end.x - mid - 1, f.end.y - doors)
		var bk := func(p: Vector2) -> Vector2: return _vp + (p - _vp) / CAB_T   # o fundo do armário, na parede
		var tl := inside.position
		var tr := Vector2(inside.end.x, inside.position.y)
		var bl := Vector2(inside.position.x, inside.end.y)
		_r(inside.position.x, inside.position.y, inside.size.x, inside.size.y, Color("0d110d"))
		_poly(PackedVector2Array([bk.call(tl), bk.call(tr), bk.call(inside.end), bk.call(bl)]), Color("151a14"))   # o fundo
		# a parede de dentro virada para quem olha (o vão fica à direita do ponto de fuga)
		_poly(PackedVector2Array([tr, bk.call(tr), bk.call(inside.end), inside.end]), Color("1d241c"))
		_r(inside.position.x, inside.position.y, inside.size.x, 3, Color(0, 0, 0, 0.5))   # a sombra do alto
		for k in int((_top - doors - 24.0) / 30.0) + 1:   # as prateleiras até a mesa (abaixo dos olhos o tampo aparece; acima, o lado de baixo, mais escuro) com pastas
			var sy := doors + 24.0 + k * 30.0
			var a := Vector2(inside.position.x, sy)
			var c := Vector2(inside.end.x, sy)
			if absf(sy - _vp.y) > 2.0:   # (na altura dos olhos a prateleira é só a beira)
				_poly(PackedVector2Array([a, c, bk.call(c), bk.call(a)]), Color("3a4236") if sy > _vp.y else Color("1c211b"))
			_r(a.x, sy, inside.size.x, 1.5, steel.darkened(0.2))   # a beira da prateleira
			_r(a.x, sy, inside.size.x, PX, steel.lightened(0.1))
			var px := inside.position.x + 3
			var n := k * 3   # a próxima pasta (a cor e o tamanho variam por ela)
			var base: float = sy - 1.0 + minf(0.0, (bk.call(a) as Vector2).y - sy) * 0.4   # em pé um pouco para dentro (acima dos olhos, o tampo não aparece)
			while px < inside.end.x - 6:
				var pw := 3.0 + (n * 7) % 4
				var ph := 14.0 + (n * 5) % 8
				var col: Color = [Color("6e5a3a"), Color("8a7a5a"), Color("4a5a6a"), Color("7a3a2a"), Color("6e5a3a")][(n * 3) % 5]
				n += 1
				_r(px, base - ph, pw, ph, col)
				_r(px, base - ph, PX, ph, col.lightened(0.2))   # a lombada pega a luz
				_r(px + pw - PX, base - ph, PX, ph, col.darkened(0.3))
				_r(px + PX, base - ph + 3, pw - 1, 1.5, Color("e3d6b2"))   # a etiqueta
				px += pw + 1
		# a porta aberta, de lado: a face de dentro com o painel rebaixado e a beira (a espessura) pegando a luz
		var d0 := Vector2(f.end.x, doors - 1)
		var d1 := Vector2(f.end.x + 16, doors - 6)
		var d2 := Vector2(f.end.x + 16, f.end.y + 8)
		var d3 := Vector2(f.end.x, f.end.y)
		_poly(PackedVector2Array([d0, d1, d2, d3]), steel.darkened(0.1))
		_poly(PackedVector2Array([d0.lerp(d1, 0.25) + Vector2(0, 8), d1.lerp(d0, 0.25) + Vector2(0, 8),
			d2.lerp(d3, 0.25) - Vector2(0, 10), d3.lerp(d2, 0.25) - Vector2(0, 10)]), steel.darkened(0.25))
		draw_line(d1, d2, steel.lightened(0.25), PX)
		draw_line(d1 + Vector2(PX, 0), d2 + Vector2(PX, 0), steel.lightened(0.05), PX)
		draw_line(d1 + Vector2(1, 0), d2 + Vector2(1, 0), steel.darkened(0.45), PX)
		var rod := d1.lerp(d0, 0.3)   # a haste da fechadura
		draw_line(rod + Vector2(0, 30), rod + Vector2(0, 52), Color("8e897c"), PX)
	else:
		_draw_calendar(Rect2(mid + 14, doors + 46, 24, 26))   # preso com ímã
	if "numero_anotado" in details:   # o número de quem ligou, anotado num bilhete e colado com fita
		var n := Rect2(f.position.x + 10, doors + 52, 26, 14)
		_cast(n, 1.01)
		_r(n.position.x, n.position.y, n.size.x, n.size.y, Color("efe6cc"))
		var ink := Color("2a2a4a")
		for k in 5:   # os algarismos, à mão, em traço de caneta (px da tela)
			var d := (n.position + Vector2(3 + k * 4, 3.5 + (k % 2) * PX)) * 2.0
			match k % 3:
				0:   # um "1"
					_p(d.x + 2, d.y, 1, 7, ink)
					_p(d.x + 1, d.y + 1, 1, 1, ink)
				1:   # um "7"
					_p(d.x, d.y, 5, 1, ink)
					_p(d.x + 4, d.y + 1, 1, 2, ink)
					_p(d.x + 3, d.y + 3, 1, 4, ink)
				_:   # um "0"
					_p(d.x + 1, d.y, 3, 1, ink)
					_p(d.x, d.y + 1, 1, 5, ink)
					_p(d.x + 4, d.y + 1, 1, 5, ink)
					_p(d.x + 1, d.y + 6, 3, 1, ink)
		_r(n.position.x + 3, n.position.y + 10.5, n.size.x - 6, PX, Color("b03a2e"))   # sublinhado
		_r(n.position.x + 3, n.position.y + 11.5, n.size.x - 9, PX, Color("b03a2e"))
		_r(n.position.x - 2, n.position.y - 1, 6, 3, Color(1, 1, 1, 0.35))   # a fita
		_r(n.end.x - 4, n.position.y - 1, 6, 3, Color(1, 1, 1, 0.35))
	return f


## O cartaz da quermesse preso na parede (a pessoa prometeu ir): papel creme com bandeirinhas coloridas em zigue-zague,
## a fogueira e as linhas do convite.
func _draw_poster(r: Rect2) -> void:
	_cast(r, 1.01)
	_r(r.position.x, r.position.y, r.size.x, r.size.y, Color("e8dcc0"))
	var cols := [Color("b03a2e"), Color("e0b040"), Color("3a6aa0"), Color("4a8a4a")]
	for k in int(r.size.x / 5.0):   # as bandeirinhas
		var x := r.position.x + 1 + k * 5
		_poly(PackedVector2Array([Vector2(x, r.position.y + 3), Vector2(x + 4, r.position.y + 3), Vector2(x + 2, r.position.y + 7)]), cols[k % 4])
	_r(r.position.x + 1, r.position.y + 2.5, r.size.x - 2, PX, Color("5a4d3a"))   # o barbante
	var c := Vector2(r.get_center().x, r.position.y + 21)   # a fogueira
	_poly(PackedVector2Array([c + Vector2(-6, 5), c + Vector2(0, -7), c + Vector2(6, 5)]), Color("e07a2a"))
	_poly(PackedVector2Array([c + Vector2(-3, 5), c + Vector2(0, -2), c + Vector2(3, 5)]), Color("f0c040"))
	_r(c.x - 7, c.y + 5, 14, 1, Color("6b4529"))   # as toras, cruzadas
	_r(c.x - 6, c.y + 6, 12, 1, Color("4a2f1c"))
	_r(c.x - 7, c.y + 5, 14, PX, Color("8a5a36"))
	for k in 4:   # o convite
		_r(r.position.x + 4, r.position.y + 29 + k * 1.5, r.size.x - 8 - (k % 2) * 4, PX, Color("5a4d3a"))
	_sprite(PixelArt.disc(5, [[2.5, Color("e07060"), Color("b03a2e"), Color("7a2418")]]), Vector2(r.get_center().x, r.position.y) * 2.0, Color.WHITE, X2)   # a tachinha


## A vista: céu do clima, morros ao fundo, casas e a igreja com o relógio aceso, a rua com o poste (a silhueta do
## mistério fica contra a luz dele) e, na chuva, o chão molhado refletindo as luzes.
func _draw_city(g: Rect2) -> void:
	var wx := g.position.x
	var wy := g.position.y
	var ww := g.size.x
	var wh := g.size.y
	var fog := weather == "fog"
	var hzy := _hz(g)
	var sky: Color = (SKY.get(weather, SKY["rain"]) as Color).lerp(Color("a2acbc"), _flash())   # o relâmpago clareia o céu
	_r(wx, wy, ww, wh, sky)
	var hz := sky.lightened(0.12)   # o céu clareia perto do horizonte, liso (em faixas, pareciam camadas)
	_fill(PackedVector2Array([Vector2(wx, hzy - 50), Vector2(wx + ww, hzy - 50), Vector2(wx + ww, hzy), Vector2(wx, hzy)]),
		PackedColorArray([sky, sky, hz, hz]))
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			_r(wx + floorf(s.x * ww), wy + floorf(s.y * (hzy - wy)), PX, PX, Color("c9d2dc") if sin(tw + i * 1.7) > -0.6 else Color("56606c"))
		var moon := Vector2(wx + floorf(ww * 0.22), hzy - 40)
		_ci.draw_circle(moon, 3.5, Color("d8d0a8"))
		_ci.draw_circle(moon + Vector2(1.3, -0.7), 3.1, sky)
	if hzy - wy < 40.0:   # (a tela ainda não se arrumou: o vidro ainda não tem o tamanho dele)
		return
	if _city_for != g.size:
		_build_city(g.size)
	var house := Color("141c22") if fog else Color("070b10")
	# bem longe: a cidade no fim da rua do cruzamento (os prédios de lá escondem o resto), em duas fileiras na névoa
	var flicked := 0
	for r in [0, 1]:
		var z: float = [400.0, 250.0][r]
		var haze: float = [0.55, 0.35][r] * (1.4 if fog else 1.0)
		var base := _o(g, 0.0, z).y
		var col := house.lerp(hz, haze)
		for b in _city:
			if b["row"] != r:
				continue
			_r(wx + b["x"], base - b["h"], b["w"], b["h"], col)
			for p in b["lit"]:
				if minutes >= p.z:
					continue
				flicked += 1
				if flick and flicked % 3 == 0:
					continue
				_r(wx + b["x"] + p.x, base - b["h"] + p.y, PX, PX, (LIT[int(p.x + p.y) % LIT.size()] as Color).lerp(hz, haze * 0.7))
	_draw_church(_church_pos(g), house.lerp(hz, 0.25))
	# o chão (a rua do cruzamento indo embora, a rua passando na frente, as calçadas e os meios-fios), as luzes nele
	_draw_street(g, hz)
	if weather == "rain":
		_draw_wet(g)
	# o outro lado: as paredes da rua do cruzamento (de longe para perto) e as fachadas de frente, apoiadas na calçada
	for i in range(_canyon.size() - 1, -1, -1):
		_draw_canyon_wall(g, _canyon[i], hz)
	# a névoa da noite na rua do cruzamento, clareando lisa para o fundo (a igreja aparece nela)
	var ff: float = STREET["far"]
	var mouth := PackedVector2Array([_o(g, CROSSING.x, ff), _o(g, CROSSING.y, ff), _o(g, CROSSING.y, ff, 16.0), _o(g, CROSSING.x, ff, 16.0)])
	_light_fan(Vector2(_o(g, (CROSSING.x + CROSSING.y) / 2.0, 200.0).x, _hz(g)), mouth, Color(hz.lightened(0.15), 0.5 if fog else 0.3))
	for b in _houses:
		_draw_far_house(g, b, hz)
	_draw_shopfront(g)
	_draw_marquee(g)
	if lamp_level > 0.5:   # a luz dos postes lavando as fachadas atrás deles, lisa
		for x: float in FAR_LAMPS:
			var c := _o(g, x, ff, 4.2)
			var rim := PackedVector2Array()
			for i in 20:
				var an := TAU * i / 20.0
				rim.append(_o(g, x + cos(an) * 3.2, ff, 4.2 + sin(an) * 3.4))
			_light_fan(c, rim, Color(1.0, 0.8, 0.5, 0.1))


## A frente da vista, por cima da de trás (`_draw_city`) e redesenhada a cada quadro dela: o letreiro (o T falha
## sozinho), quem passa, os postes, o homem, o carro (na chuva, com o farol espelhado na rua) e a névoa.
func _draw_city_front(g: Rect2) -> void:
	if _hz(g) - g.position.y < 40.0:   # (a tela ainda não se arrumou: o vidro ainda não tem o tamanho dele)
		return
	_draw_hotel_sign(_hotel_pos(g))
	for w: Dictionary in _walkers:   # passam atrás dos postes e do homem
		_draw_walker(g, w)
	for x: float in FAR_LAMPS:
		_draw_lamp_post(g, x, STREET["far_curb"] + 0.4)
	var mx := _man_x()
	if not is_nan(mx):
		_draw_stranger(g, mx)
	_cars.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["lane"] < b["lane"])   # o de lá primeiro
	for c in _cars:
		if weather == "rain":
			_draw_wet(g, c)
		_draw_car(g, c)
	if weather == "fog":
		_draw_fog(g)


## A névoa, por cima da rua e do outro lado (o arbusto, perto, fica fora dela): um véu liso, mais grosso rente ao chão
## (`FOG_VEIL`, `FOG_GROUND`), fiapos largos e lisos atravessando a rua devagar (`FOG_WISPS`, com o vento, `_mist`) e as
## luzes espalhando nela: um halo e um cone embaixo de cada poste e o vermelho do neon em volta do letreiro.
func _draw_fog(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var base := _o(g, 0.0, ff).y   # o pé das fachadas de lá
	var high := _o(g, 0.0, ff, 3.0).y
	var x0 := g.position.x
	var x1 := g.end.x
	var y1 := g.end.y + _near   # até o pé do vidro: a rua de perto também
	_r(x0, g.position.y, g.size.x, y1 - g.position.y, Color(FOG, FOG_VEIL))
	_fill(PackedVector2Array([Vector2(x0, high), Vector2(x1, high), Vector2(x1, base), Vector2(x0, base)]),
		PackedColorArray([Color(FOG, 0.0), Color(FOG, 0.0), Color(FOG, FOG_GROUND), Color(FOG, FOG_GROUND)]))
	_fill(PackedVector2Array([Vector2(x0, base), Vector2(x1, base), Vector2(x1, y1), Vector2(x0, y1)]),
		PackedColorArray([Color(FOG, FOG_GROUND), Color(FOG, FOG_GROUND), Color(FOG, FOG_GROUND * 0.4), Color(FOG, FOG_GROUND * 0.4)]))
	for k in FOG_WISPS:   # cada um na sua distância, altura, tamanho e velocidade, sempre os mesmos
		var z := lerpf(STREET["curb"] + 1.0, ff, fmod(k * 0.37, 1.0))
		var c := _o(g, fposmod(k * 13.7 + _mist * (0.08 + (k % 3) * 0.03), 70.0) - 35.0, z, 0.3 + fmod(k * 0.53, 1.0) * 1.6)
		var rx := OUT_F * (5.0 + (k % 4) * 1.5) / z
		var ry := OUT_F * (0.5 + (k % 3) * 0.25) / z
		var rim := PackedVector2Array()
		for i in 16:
			rim.append(c + Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * ry))
		_light_fan(c, rim, Color(FOG, 0.14))
	if lamp_level > 0.5:
		var heads := _lamp_heads(g)
		var lit := Color(1.0, 0.85, 0.55, 0.14)
		for i in FAR_LAMPS.size():
			var x: float = FAR_LAMPS[i]
			var z: float = STREET["far_curb"] - 0.2
			var h: Vector2 = heads[i]
			var foot := _o(g, x, z)
			var w := Vector2(1, 0)
			# o cone: claro no meio, sumindo para os lados (com a borda reta, parecia um triângulo recortado)
			_fill(PackedVector2Array([h - w, h, foot, _o(g, x - 3.5, z)]), PackedColorArray([Color(lit, 0.0), lit, Color(lit, lit.a * 0.4), Color(lit, 0.0)]))
			_fill(PackedVector2Array([h, h + w, _o(g, x + 3.5, z), foot]), PackedColorArray([lit, Color(lit, 0.0), Color(lit, 0.0), Color(lit, lit.a * 0.4)]))
			var halo := PackedVector2Array()
			for k in 20:
				halo.append(h + Vector2(cos(TAU * k / 20.0), sin(TAU * k / 20.0)) * OUT_F * 2.2 / z)
			_light_fan(h, halo, Color(lit, 0.22))
	if _sign_on():
		var sc := _hotel_pos(g) + Vector2(2, 8)
		var glow := PackedVector2Array()
		for k in 20:
			glow.append(sc + Vector2(cos(TAU * k / 20.0) * 12.0, sin(TAU * k / 20.0) * 24.0))
		_light_fan(sc, glow, Color(SIGN_RED, 0.12))


## O horizonte da vista `g` (a altura dos olhos).
func _hz(g: Rect2) -> float:
	return g.position.y + _vp.y - _view_at.y


## Um ponto lá fora na vista `g`: `x` m ao longo da rua (a partir da frente da janela), a `z` m dos olhos e `h` m acima
## da rua. A câmera olha de frente para a rua: a linha que vai para longe foge para o meio do horizonte.
func _o(g: Rect2, x: float, z: float, h := 0.0) -> Vector2:
	z = maxf(0.3, z)
	return Vector2(g.position.x + g.size.x * 0.5 + OUT_F * x / z, _hz(g) + OUT_F * (OUT_EYE - h) / z)


## Um retângulo no chão (ou na altura `h`) de `x0` a `x1` ao longo da rua e de `z0` a `z1` de distância.
func _patch(g: Rect2, x0: float, x1: float, z0: float, z1: float, h := 0.0) -> PackedVector2Array:
	return PackedVector2Array([_o(g, x0, z0, h), _o(g, x1, z0, h), _o(g, x1, z1, h), _o(g, x0, z1, h)])


## O pé da igreja, no fim da rua do cruzamento.
func _church_pos(g: Rect2) -> Vector2:
	return _o(g, (CROSSING.x + CROSSING.y) / 2.0, 120.0)


## O alto do letreiro do hotel, preso na fachada do outro lado.
func _hotel_pos(g: Rect2) -> Vector2:
	return _o(g, HOTEL_X, STREET["far"] - 0.6, 10.0)


## As cabeças dos postes da calçada de lá (para o brilho delas no vidro).
func _lamp_heads(g: Rect2) -> Array:
	var out := []
	for x: float in FAR_LAMPS:
		out.append(_o(g, x, STREET["far_curb"] - 0.6, 5.0))
	return out


## A cabeça do poste da esquina, o mais perto (as gotas no vidro esquentam perto dele).
func _post(g: Rect2) -> Vector2:
	return _lamp_heads(g)[0]


## Onde está a frente do carro `c` (x, m): entra por um lado da vista e sai pelo outro, no sentido da mão dele.
func _car_x(c: Dictionary) -> float:
	var d: float = CAR_LANES[c["lane"]].y
	return lerpf(16.0, -21.0, c["t"]) * -d


## O chão: a rua do cruzamento indo embora (com as calçadas e os postes dela, menores com a distância), a nossa calçada
## de lajotas até o meio-fio, o asfalto da rua (manchas, desgaste dos pneus nas duas mãos, grão perto, poças espelhando o
## céu, a faixa tracejada no meio e a faixa de pedestres na boca do cruzamento), o meio-fio de lá com a face virada para
## nós, a calçada de lá e a luz dos postes no chão. Tudo no mesmo plano horizontal; só a perspectiva inclina as linhas
## que vão para longe.
func _draw_street(g: Rect2, hz: Color) -> void:
	var fog := weather == "fog"
	var asphalt := Color("090c10") if not fog else Color("141a1f")
	var walk := Color("1b2227") if not fog else Color("232b31")
	var cu: float = STREET["curb"]
	var fc: float = STREET["far_curb"]
	var ff: float = STREET["far"]
	var cx0 := CROSSING.x
	var cx1 := CROSSING.y
	var wide := 80.0
	_poly(PackedVector2Array([Vector2(g.position.x, _hz(g)), Vector2(g.end.x, _hz(g)), Vector2(g.end.x, g.end.y + _near),
		Vector2(g.position.x, g.end.y + _near)]), asphalt)
	# a rua do cruzamento, indo embora até a praça da igreja, com as calçadas dela
	var far := asphalt.lerp(hz, 0.35)
	_fill(_patch(g, cx0 + 1.8, cx1 - 1.8, fc, 130.0), PackedColorArray([asphalt, asphalt, far, far]))
	for side: Vector2 in [Vector2(cx0, cx0 + 1.8), Vector2(cx1 - 1.8, cx1)]:
		_fill(_patch(g, side.x, side.y, ff, 130.0), PackedColorArray([walk, walk, walk.lerp(hz, 0.35), walk.lerp(hz, 0.35)]))
		var curb_x := side.y if side.x == cx0 else side.x
		_ci.draw_line(_o(g, curb_x, ff, 0.15), _o(g, curb_x, 130.0, 0.15), Color(hz, 0.6), PX)
	for i in 6:   # os postes dela, menores e mais juntos com a distância
		var z := 24.0 + i * 16.0
		for x in [cx0 + 1.4, cx1 - 1.4]:
			var foot := _o(g, x, z)
			var head := _o(g, x, z, 5.0)
			var near := clampf(24.0 / z, 0.0, 1.0)
			_r(foot.x, head.y, PX, foot.y - head.y, Color("1d262c").lerp(hz, 1.0 - near))
			if lamp_level > 0.5:
				_r(head.x - PX, head.y - PX, maxf(PX, 1.5 * near), maxf(PX, near), Color("ffd88a").lerp(hz, (1.0 - near) * 0.6))
				_r(foot.x - 2.0 * near, foot.y - PX, 4.0 * near + PX, PX, Color(1.0, 0.85, 0.55, 0.2 * near))
	# a calçada de lá, dos dois lados da boca do cruzamento (a nossa não aparece: o que encosta no nosso prédio diria
	# para que lado a nossa parede vai, e a sala já diz outra coisa)
	_poly(_patch(g, -wide, cx0, fc, ff), walk)
	_poly(_patch(g, cx1, wide, fc, ff), walk)
	# o asfalto não é liso: manchas e remendos, o desgaste dos pneus em cada mão, poças e o grão perto
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	for i in 36:
		var x := rng.randf_range(-20.0, 20.0)
		var z := rng.randf_range(cu + 0.3, fc - 0.5)
		var tone := Color(1, 1, 1, rng.randf_range(0.015, 0.035)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(0.1, 0.22))
		_poly(_patch(g, x, x + rng.randf_range(1.0, 5.0), z, z + rng.randf_range(0.3, 1.2)), tone)
	for lane: float in [cu + 1.3, cu + 2.7, fc - 2.7, fc - 1.3]:
		_poly(_patch(g, -wide, wide, lane - 0.3, lane + 0.3), Color(0.6, 0.7, 0.8, 0.035))
	var wet := 2.0 if weather == "rain" else 1.0
	for i in 12:   # as poças: espelham o céu (na chuva, mais)
		var x := rng.randf_range(-14.0, 14.0)
		var z := rng.randf_range(cu + 0.4, fc - 0.8)
		var puddle := _patch(g, x, x + rng.randf_range(1.0, 2.6), z, z + rng.randf_range(0.4, 0.9))
		_poly(puddle, Color(0.45, 0.55, 0.7, 0.05 * wet))
		_ci.draw_line(puddle[2], puddle[3], Color(0.6, 0.7, 0.85, 0.08 * wet), PX)
	for i in 240:
		var gp := _o(g, rng.randf_range(-8.0, 8.0), rng.randf_range(cu + 0.5, 6.5))
		_r(floorf(gp.x * 2.0) * PX, floorf(gp.y * 2.0) * PX, PX, PX, Color(1, 1, 1, 0.04) if i % 2 else Color(0, 0, 0, 0.2))
	var x0 := -wide   # a faixa tracejada no meio
	while x0 < wide:
		_poly(_patch(g, x0, x0 + 3.0, STREET["lane"] - 0.08, STREET["lane"] + 0.08), Color(0.75, 0.72, 0.6, 0.3))
		x0 += 9.0
	# as juntas das lajotas de lá: ao longo da rua (na horizontal) e para longe (para o ponto de fuga)
	var joint := Color(0, 0, 0, 0.35)
	_ci.draw_line(_o(g, -wide, fc + 1.4), _o(g, cx0, fc + 1.4), joint, PX)
	_ci.draw_line(_o(g, cx1, fc + 1.4), _o(g, wide, fc + 1.4), joint, PX)
	var xj := -30.0
	while xj < 30.0:
		if xj < cx0 or xj > cx1:
			_ci.draw_line(_o(g, xj, fc), _o(g, xj, ff), joint, PX)
		xj += 1.5
	# perto, embaixo da janela, a rua some na sombra do nosso prédio, lisa e sem nenhuma linha
	var dark := Color(0, 0, 0, 0.6)
	_fill(_patch(g, -wide, wide, 0.3, cu + 1.5), PackedColorArray([dark, dark, Color(dark, 0.0), Color(dark, 0.0)]))
	# o meio-fio de lá, com a face virada para nós e a quina
	for seg: Vector2 in [Vector2(-wide, cx0), Vector2(cx1, wide)]:
		_poly(PackedVector2Array([_o(g, seg.x, fc), _o(g, seg.y, fc), _o(g, seg.y, fc, 0.15), _o(g, seg.x, fc, 0.15)]), Color("2a3237"))
		_ci.draw_line(_o(g, seg.x, fc, 0.15), _o(g, seg.y, fc, 0.15), Color("4a555c"), PX)
	if lamp_level > 0.5:   # a luz de cada poste de lá no chão, em volta do pé dele
		for x: float in FAR_LAMPS:
			var c := _o(g, x, fc - 0.2)
			var rim := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				rim.append(_o(g, x + cos(a) * 4.5, fc - 0.2 + sin(a) * 3.0))
			_light_fan(c, rim, Color(1.0, 0.85, 0.55, 0.28))


## A chuva no chão: o asfalto molhado espelha as luzes em riscos verticais, quebrados, embaixo de cada uma (os postes
## e o letreiro; com `car`, só o farol daquele carro, que anda: vai na frente da vista), mais fracos para baixo.
func _draw_wet(g: Rect2, car: Dictionary = {}) -> void:
	var lights := []   # [cabeça, pé, cor]
	if not car.is_empty():
		var z: float = CAR_LANES[car["lane"]].x
		lights.append([_o(g, _car_x(car), z - 0.9, 0.7), _o(g, _car_x(car), z - 1.2), Color("fff1c8")])
	else:
		if lamp_level > 0.5:
			for i in FAR_LAMPS.size():
				lights.append([_lamp_heads(g)[i], _o(g, FAR_LAMPS[i], STREET["far_curb"] - 0.5), Color(1.0, 0.85, 0.55)])
		if _sign_on():
			lights.append([_hotel_pos(g), _o(g, HOTEL_X, STREET["far_curb"] - 0.5), SIGN_RED])
	for l: Array in lights:
		var head: Vector2 = l[0]
		var foot: Vector2 = l[1]
		var length := (foot.y - head.y) * 0.9
		var n := maxi(3, int(length / 1.5))
		for k in n:
			if k % 3 == 2:
				continue   # quebrado pelas poças e pelos pingos
			_r(foot.x - PX * (k % 2), foot.y + length * k / n, maxf(PX, 1.5 - k * 0.05), PX, Color(l[2], 0.32 * (1.0 - float(k) / n)))


## Uma parede da rua do cruzamento (`w`: o lado `x`, de `z0` a `z1`, `h` m), indo embora para o ponto de fuga, com
## algumas janelas acesas.
func _draw_canyon_wall(g: Rect2, w: Dictionary, hz: Color) -> void:
	var x: float = w["x"]
	var z0: float = w["z0"]
	var z1: float = w["z1"]
	var ht: float = w["h"]
	var col: Color = (w["col"] as Color).lerp(hz, clampf((z0 - 14.0) / 160.0, 0.0, 0.5))
	_poly(PackedVector2Array([_o(g, x, z0), _o(g, x, z1), _o(g, x, z1, ht), _o(g, x, z0, ht)]), col)
	_ci.draw_line(_o(g, x, z0), _o(g, x, z0, ht), col.darkened(0.4), PX)   # a quina
	for wv: Vector3 in w["wins"]:   # (z, altura, hora de apagar)
		if wv.z > minutes:
			var p := _o(g, x, wv.x, wv.y)
			_r(p.x, p.y, PX, maxf(PX, 1.2 * OUT_F / wv.x), LIT[int(wv.x) % LIT.size()])


## Um prédio do outro lado da rua, de frente (`b`: de `x0` a `x1`, `h` m, andares de 3,2 m), apoiado na calçada de lá:
## a fachada vertical (de tijolos, no da esquina), a cornija, a faixa acima do térreo, a porta e a vitrine no térreo e as
## janelas, acesas até a hora delas ou apagadas com o reflexo da rua.
func _draw_far_house(g: Rect2, b: Dictionary, hz: Color) -> void:
	var ff: float = STREET["far"]
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var ht: float = b["h"]
	var col: Color = b["col"]
	var a := _o(g, x0, ff, ht)
	var e := _o(g, x1, ff)
	var k := OUT_F / ff   # px de 2x2 por metro na fachada
	_r(a.x, a.y, e.x - a.x, e.y - a.y, col)
	if b["brick"]:   # as fiadas de tijolo, de meio em meio metro
		var hb := 0.5
		while hb < ht:
			_r(a.x, _o(g, x0, ff, hb).y, e.x - a.x, PX, col.darkened(0.22))
			hb += 0.5
	_r(a.x - PX, a.y - 1, e.x - a.x + PX * 2.0, 1, col.lightened(0.18))   # a cornija, com a sombra embaixo
	_r(a.x, a.y, e.x - a.x, PX, Color(0, 0, 0, 0.4))
	_r(a.x, _o(g, x0, ff, 3.4).y, e.x - a.x, PX, col.lightened(0.12))   # a faixa acima do térreo
	_r(a.x, a.y, PX, e.y - a.y, col.darkened(0.4))   # a divisa com o vizinho
	_r(a.x, e.y - PX, e.x - a.x, PX, Color(0, 0, 0, 0.45))   # o pé, na calçada
	for wv: Vector3 in b["wins"]:   # (x do meio, andar, hora de apagar; -1: apagada)
		var ground := wv.y == 0.0
		var w := (1.8 if ground else 1.2) * k
		var top := _o(g, wv.x, ff, 2.6 if ground else wv.y * 3.2 + 2.5)
		var h := (2.6 if ground else 1.5) * k
		var p := Vector2(top.x - w / 2.0, top.y)
		_r(p.x - PX, p.y - PX, w + PX * 2.0, h + PX, col.darkened(0.55))   # o vão
		if wv.z > minutes:
			var lc: Color = LIT[int(wv.x + wv.y) % LIT.size()]
			_r(p.x, p.y, w, h, lc)
			_r(p.x, p.y + h * 0.45, w, PX, lc.darkened(0.45))   # a travessa
			_r(p.x, p.y, w * 0.3, h, lc.darkened(0.25))   # a cortina
			_r(p.x, p.y, w, maxf(PX, 0.15 * k), lc.darkened(0.5))   # a sombra da verga: a janela é funda
		else:
			_r(p.x, p.y, w, h, Color("080b0e"))
			_r(p.x, p.y, w, PX, Color(hz, 0.5))   # o reflexo da rua no vidro
		if not ground:
			_r(p.x - PX * 2.0, p.y + h, w + PX * 4.0, PX, col.lightened(0.25))   # o peitoril, saindo da parede, e a sombra dele
			_r(p.x - PX, p.y + h + PX, w + PX * 2.0, PX, col.darkened(0.35))
			_r(p.x - PX * 2.0, p.y - PX * 2.0, w + PX * 4.0, PX, col.darkened(0.3))   # a verga


## A vitrine acesa de um bar no térreo do prédio de tijolos, logo atrás do homem (`MAN_X`): ele fica em silhueta contra
## ela. Vidro quente com o caixilho e o letreiro pintado, e a luz dela saindo pela calçada.
func _draw_shopfront(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var x0 := CROSSING.y + 0.5   # (a quina do prédio fica em CROSSING.y: antes, a vitrine passava dela)
	var x1 := CROSSING.y + 2.5   # (com três divisões, encostava na porta)
	var a := _o(g, x0, ff, 2.5)
	var e := _o(g, x1, ff, 0.4)
	_r(a.x - PX, a.y - PX, e.x - a.x + 1, e.y - a.y + 1, Color("1a0f0a"))
	_fill(PackedVector2Array([a, Vector2(e.x, a.y), e, Vector2(a.x, e.y)]),
		PackedColorArray([Color("c98a3e"), Color("c98a3e"), Color("f0c070"), Color("f0c070")]))
	_r(lerpf(a.x, e.x, 0.5), a.y, PX, e.y - a.y, Color("3a2414"))   # o caixilho
	_r(a.x, lerpf(a.y, e.y, 0.3), e.x - a.x, PX, Color("3a2414"))
	_r(lerpf(a.x, e.x, 0.12), lerpf(a.y, e.y, 0.12), (e.x - a.x) * 0.5, PX, Color("7a3a1a"))   # o letreiro pintado no vidro
	var c := _o(g, MAN_X, STREET["far_curb"] + 0.3)   # a luz dela na calçada e no meio-fio
	var rim := PackedVector2Array()
	for i in 20:
		var an := TAU * i / 20.0
		rim.append(_o(g, MAN_X + cos(an) * 2.6, ff - 1.2 + sin(an) * 1.6))
	_light_fan(c, rim, Color(1.0, 0.75, 0.4, 0.2))


## A marquise do hotel sobre a porta (embaixo do letreiro): saindo 1,2 m da fachada, o alto visto de cima (os olhos
## ficam acima), a beira da frente e a luz quente embaixo dela, na porta e na calçada.
func _draw_marquee(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var x0 := HOTEL_X - 1.8
	var x1 := HOTEL_X + 1.8
	var door := _o(g, HOTEL_X - 0.6, ff, 2.3)
	var de := _o(g, HOTEL_X + 0.6, ff)
	_fill(PackedVector2Array([door, Vector2(de.x, door.y), de, Vector2(door.x, de.y)]),
		PackedColorArray([Color("8a5a2a"), Color("8a5a2a"), Color("e0a858"), Color("e0a858")]))   # a porta aberta, com a luz do saguão
	var c := _o(g, HOTEL_X, ff - 0.6)
	var rim := PackedVector2Array()
	for i in 20:
		var an := TAU * i / 20.0
		rim.append(_o(g, HOTEL_X + cos(an) * 2.8, ff - 0.8 + sin(an) * 1.4))
	_light_fan(c, rim, Color(1.0, 0.78, 0.45, 0.22))
	var top := PackedVector2Array([_o(g, x0, ff, 3.0), _o(g, x1, ff, 3.0), _o(g, x1, ff - 1.2, 3.0), _o(g, x0, ff - 1.2, 3.0)])
	_poly(top, Color("2a1c16"))
	_poly(PackedVector2Array([top[3], top[2], _o(g, x1, ff - 1.2, 2.75), _o(g, x0, ff - 1.2, 2.75)]), Color("6a1e18"))   # a beira, vermelha
	_ci.draw_line(_o(g, x0, ff - 1.2, 2.75), _o(g, x1, ff - 1.2, 2.75), Color(1.0, 0.8, 0.5, 0.6), PX)   # a luz embaixo dela


## Um poste da calçada de lá (em `x`, `z`), com 5 m: o tubo, o braço virado para a rua e a cabeça acesa.
func _draw_lamp_post(g: Rect2, x: float, z: float) -> void:
	var foot := _o(g, x, z)
	var top := _o(g, x, z, 5.0)
	var head := _o(g, x, z - 1.0, 5.0)
	var k := (foot.y - top.y) / 5.0
	var pole := Color("1d262c")
	_r(foot.x - maxf(PX, 0.08 * k), top.y, maxf(PX, 0.16 * k), foot.y - top.y, pole)
	_ci.draw_line(top, head, pole, maxf(PX, 0.1 * k))
	_r(head.x - 0.3 * k, head.y, 0.6 * k, maxf(PX, 0.15 * k), pole)
	if lamp_level > 0.5:
		_r(head.x - 0.25 * k, head.y + 0.15 * k, 0.5 * k, maxf(PX, 0.12 * k), Color("ffd88a"))
		_poly(PackedVector2Array([head + Vector2(-0.25 * k, 0.2 * k), head + Vector2(0.25 * k, 0.2 * k),
			Vector2(head.x + 1.6 * k, foot.y), Vector2(head.x - 1.6 * k, foot.y)]), Color(1.0, 0.85, 0.55, 0.05))


## Onde está o homem do mistério na calçada de lá (x, m), ou NAN sem ele: vem andando de `MAN_FROM`, fica parado
## embaixo do poste da esquina (`MAN_X`) de `stranger.x` a `stranger.y` e volta por onde veio (`MAN_WALK` min para cada
## lado). Sai da hora do jogo: pausa e pulo do relógio valem para ele também.
func _man_x() -> float:
	if minutes < stranger.x - MAN_WALK or minutes >= stranger.y + MAN_WALK:
		return NAN
	if minutes < stranger.x:
		return lerpf(MAN_FROM, MAN_X, (minutes - stranger.x + MAN_WALK) / MAN_WALK)
	if minutes < stranger.y:
		return MAN_X
	return lerpf(MAN_X, MAN_FROM, (minutes - stranger.y) / MAN_WALK)


## O homem do mistério na calçada de lá, em `x` (`_man_x`), de chapéu e casaco comprido, com 1,8 m: andando, as pernas
## alternam a cada passo; parado embaixo do poste da esquina, fica contra a luz dele, com a sombra no chão para longe
## dela. Em px da tela; a névoa e a chuva passam por cima.
func _draw_stranger(g: Rect2, x: float) -> void:
	var z: float = STREET["far_curb"] + 1.1
	var walking := x != MAN_X
	var steps := int(absf(x - MAN_FROM) / MAN_STRIDE)
	var foot := (_o(g, x, z) * 2.0).floor() - Vector2(0, steps % 2 if walking else 0)
	var k := OUT_F / z * 2.0   # px da tela por metro
	var hc := _o(g, x, z, 1.0)
	var halo := PackedVector2Array()   # a luz do poste atrás dele, lisa
	for i in 24:
		halo.append(hc + Vector2.from_angle(TAU * i / 24.0) * k * 0.45)
	_light_fan(hc, halo, Color(0.85, 0.62, 0.3, 0.16 * clampf(1.0 - absf(x - MAN_X) / 2.0, 0.0, 1.0)))
	var dir := 1.0 if x >= (FAR_LAMPS[0] as float) else -1.0
	_poly(PackedVector2Array([_o(g, x - 0.2, z), _o(g, x + 0.2, z), _o(g, x + dir * 2.4, z + 0.6), _o(g, x + dir * 2.0, z + 0.6)]),
		Color(0, 0, 0, 0.5))
	# (x de um lado a outro, altura de baixo para cima), em metros: pernas, casaco, ombros, cabeça, aba e copa do chapéu
	var legs: Array[Rect2] = [Rect2(-0.17, 0.0, 0.13, 0.8), Rect2(0.04, 0.0, 0.13, 0.8)]
	if walking and steps % 2 == 0:
		legs = [Rect2(-0.22, 0.0, 0.13, 0.8), Rect2(0.09, 0.0, 0.13, 0.8)]
	elif walking:
		legs = [Rect2(-0.07, 0.0, 0.14, 0.8)]
	for part: Rect2 in legs + [Rect2(-0.24, 0.55, 0.48, 0.8),
			Rect2(-0.27, 1.25, 0.54, 0.2), Rect2(-0.1, 1.45, 0.2, 0.22), Rect2(-0.2, 1.66, 0.4, 0.05), Rect2(-0.11, 1.7, 0.22, 0.13)]:
		var a := Vector2(roundf(part.position.x * k), -roundf((part.position.y + part.size.y) * k))
		var b := Vector2(roundf(part.end.x * k), -roundf(part.position.y * k))
		_p(foot.x + a.x, foot.y + a.y, maxf(1.0, b.x - a.x), maxf(1.0, b.y - a.y), Color.BLACK)


## Alguém novo na calçada de lá, indo de um lado ao outro: cada um com o seu passo, a sua altura, a sua distância das
## fachadas e, sem chuva, de chapéu ou não. `t` vai de 0 a 1 (negativo: ainda não entrou na rua).
func _walker() -> Dictionary:
	return {"t": 0.0, "dir": 1.0 if randf() < 0.5 else -1.0, "sec": WALK_SEC * randf_range(0.8, 1.2), "z": randf_range(12.4, 13.6),
		"h": randf_range(0.92, 1.06), "hat": randf() < 0.5}


## Põe `w` na calçada, na ordem do desenho (os de mais longe primeiro).
func _add_walker(w: Dictionary) -> void:
	_walkers.insert(_walkers.bsearch_custom(w, func(a: Dictionary, b: Dictionary) -> bool: return a["z"] > b["z"]), w)


## Alguém passando pela calçada de lá (`w`, de `_walker`; fora da vista, não desenha): silhueta escura de 1,7 m contra as luzes, as pernas
## alternando a cada passo, com um balanço leve, e de guarda-chuva aberto na chuva. Em px da tela, como o homem.
func _draw_walker(g: Rect2, w: Dictionary) -> void:
	var z: float = w["z"]
	var x: float = lerpf(-16.0, 16.0, w["t"]) * w["dir"]
	if absf(x) > g.size.x * 0.5 * z / OUT_F + 1.0:
		return
	var steps := int(w["t"] * w["sec"] * WALK_STEPS)
	var foot := (_o(g, x, z) * 2.0).floor() - Vector2(0, posmod(steps, 2))
	var k: float = OUT_F / z * 2.0 * w["h"]   # px da tela por metro (na altura dele)
	var dark := Color("07090c")
	_poly(PackedVector2Array([_o(g, x - 0.3, z), _o(g, x + 0.3, z), _o(g, x + 0.3, z + 0.2), _o(g, x - 0.3, z + 0.2)]), Color(0, 0, 0, 0.35))
	var parts: Array[Rect2] = [Rect2(-0.2, 0.75, 0.4, 0.68), Rect2(-0.1, 1.43, 0.2, 0.22)]   # o casaco e a cabeça
	parts.append_array([Rect2(-0.22, 0.0, 0.13, 0.8), Rect2(0.09, 0.0, 0.13, 0.8)] if posmod(steps, 2) == 0 else [Rect2(-0.07, 0.0, 0.14, 0.8)])
	if weather == "rain":   # o guarda-chuva: a cúpula, a beira e o cabo
		parts.append_array([Rect2(-0.55, 1.74, 1.1, 0.1), Rect2(-0.42, 1.84, 0.84, 0.1), Rect2(-0.2, 1.94, 0.4, 0.05), Rect2(-0.02, 1.4, 0.04, 0.36)])
	elif w["hat"]:
		parts.append_array([Rect2(-0.18, 1.63, 0.36, 0.04), Rect2(-0.1, 1.66, 0.2, 0.1)])
	for part in parts:
		var a := Vector2(roundf(part.position.x * k), -roundf((part.position.y + part.size.y) * k))
		var b := Vector2(roundf(part.end.x * k), -roundf(part.position.y * k))
		_p(foot.x + a.x, foot.y + a.y, maxf(1.0, b.x - a.x), maxf(1.0, b.y - a.y), dark)


## O carro `c` passando pela mão dele (`CAR_LANES`), apoiado no asfalto: a sombra de contato, o facho dos faróis no
## chão à frente, o lado de cá (vidros, coluna, frisos, rodas com calota), o capô, o teto e o porta-malas vistos um
## pouco de cima (os olhos ficam acima dele) e a frente ou a traseira, a que estiver virada para nós. Posto a partir da
## frente (`_car_x`), no sentido em que anda: o de lá vai para a esquerda, o de cá volta para a direita. 4,5 × 1,8 ×
## 1,45 m.
func _draw_car(g: Rect2, c: Dictionary) -> void:
	var lane: Vector2 = CAR_LANES[c["lane"]]
	var d := lane.y   # o sentido: a frente vai para lá
	var x := _car_x(c)
	var at := func(a: float) -> float: return x - d * a   # a metros da frente, para trás
	var span := func(a: float, b: float) -> Vector2: return Vector2(minf(at.call(a), at.call(b)), maxf(at.call(a), at.call(b)))
	var z0 := lane.x - 0.9   # o lado de cá
	var z1 := lane.x + 0.9
	var body := Color("1b2530")
	var top := Color("2e3a46")
	var glass := Color("0b1218")
	var chrome := Color("5a6670")
	var all: Vector2 = span.call(-0.2, 4.7)
	_poly(_patch(g, all.x, all.y, z0 - 0.15, z1 + 0.15), Color(0, 0, 0, 0.55))   # o contato com o asfalto
	_poly(PackedVector2Array([_o(g, x, z0 + 0.2), _o(g, x, z1 - 0.2), _o(g, x + d * 8.0, z1 + 0.6), _o(g, x + d * 8.0, z0 - 0.6)]),
		Color(1.0, 0.95, 0.8, 0.12))   # o facho dos faróis
	var trunk: Vector2 = span.call(3.6, 4.5)
	_poly(_patch(g, trunk.x, trunk.y, z0, z1, 0.95), top)   # o porta-malas
	var roof: Vector2 = span.call(1.6, 3.2)
	_poly(_patch(g, roof.x, roof.y, z0 + 0.15, z1 - 0.15, 1.45), top.lightened(0.08))   # o teto
	_poly(PackedVector2Array([_o(g, at.call(1.1), z0 + 0.1, 0.95), _o(g, at.call(1.6), z0 + 0.15, 1.45),
		_o(g, at.call(1.6), z1 - 0.15, 1.45), _o(g, at.call(1.1), z1 - 0.1, 0.95)]), glass)   # o para-brisa
	var hood: Vector2 = span.call(0.0, 1.1)
	_poly(_patch(g, hood.x, hood.y, z0, z1, 0.95), top)   # o capô
	var rear: float = at.call(4.5)
	if d * x < 0.0:   # a frente, virada para nós enquanto ele vem
		_poly(PackedVector2Array([_o(g, x, z0, 0.3), _o(g, x, z1, 0.3), _o(g, x, z1, 0.95), _o(g, x, z0, 0.95)]), body.darkened(0.2))
	elif d * rear > 0.0:   # a traseira, quando ele já passou
		_poly(PackedVector2Array([_o(g, rear, z0, 0.3), _o(g, rear, z1, 0.3), _o(g, rear, z1, 0.95), _o(g, rear, z0, 0.95)]),
			body.darkened(0.2))
	var side := PackedVector2Array()   # o lado de cá
	for p: Vector2 in [Vector2(0.0, 0.3), Vector2(0.0, 0.8), Vector2(0.1, 0.95), Vector2(4.4, 0.95), Vector2(4.5, 0.8), Vector2(4.5, 0.3)]:
		side.append(_o(g, at.call(p.x), z0, p.y))
	_poly(side, body)
	var win := PackedVector2Array()
	for p: Vector2 in [Vector2(1.1, 0.97), Vector2(1.6, 1.43), Vector2(3.2, 1.43), Vector2(3.6, 0.97)]:
		win.append(_o(g, at.call(p.x), z0 + 0.05, p.y))
	_poly(win, glass)
	_ci.draw_line(_o(g, at.call(2.35), z0, 0.97), _o(g, at.call(2.35), z0, 1.43), body, PX)   # a coluna do meio
	_ci.draw_line(_o(g, at.call(1.5), z0, 1.2), _o(g, at.call(1.9), z0, 1.38), Color("3a4a58"), PX)   # o reflexo
	_ci.draw_line(_o(g, x, z0, 0.95), _o(g, rear, z0, 0.95), chrome, PX)   # os frisos
	_ci.draw_line(_o(g, x, z0, 0.4), _o(g, rear, z0, 0.4), chrome, PX)
	_ci.draw_line(_o(g, at.call(2.3), z0, 0.4), _o(g, at.call(2.3), z0, 0.95), Color(0, 0, 0, 0.5), PX)   # a porta
	for wx2 in [0.8, 3.6]:   # as rodas, com a calota
		var a := _o(g, minf(at.call(wx2 - 0.33), at.call(wx2 + 0.33)), z0, 0.62)
		var b := _o(g, maxf(at.call(wx2 - 0.33), at.call(wx2 + 0.33)), z0, 0.0)
		_r(a.x, a.y, b.x - a.x, b.y - a.y, Color("030506"))
		var m := (a + b) / 2.0
		_r(m.x - (b.x - a.x) * 0.2, m.y - (b.y - a.y) * 0.2, (b.x - a.x) * 0.4, (b.y - a.y) * 0.4, Color("3a444b"))
	var k := OUT_F / z0
	var w := maxf(1.0, 0.2 * k)
	var hl := _o(g, x, z0, 0.7)
	_r(hl.x - PX if d < 0.0 else hl.x - w + PX, hl.y - 0.08 * k, w, maxf(1.0, 0.16 * k), Color("fff1c8"))   # o farol
	var tw := maxf(PX, 0.15 * k)
	var tl := _o(g, rear, z0, 0.75)
	_r(tl.x - tw if d < 0.0 else tl.x, tl.y - 0.08 * k, tw, maxf(1.0, 0.16 * k), Color("8a1e14"))   # a lanterna


## O arbusto plantado junto da nossa parede, embaixo da janela (`SHRUB`): só a copa aparece, subindo do peitoril
## atrás do vidro, posta pela parede da sala (`_side_pt`) e não pela câmera da vista. Folhas em quatro tons (as de
## cima pegando a luz da rua), maiores do lado de perto, mexendo com o vento.
func _draw_shrub() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var t := Time.get_ticks_msec() / 1000.0
	var wind := {"rain": 1.0, "clear": 0.6, "fog": 0.3}.get(weather, 0.6) as float
	var tones := [Color("08120c"), Color("0f2016"), Color("193323"), Color("2a4a33")]
	var f := _flash()
	_ci.draw_set_transform(Vector2.ZERO)   # as folhas em px da tela
	var gw := SIDE_W
	var gh := _cm(WIN_SILL - WIN_TOP)
	for i in 360:
		var hgt := pow(rng.randf(), 0.7) * SHRUB.z
		var r := SHRUB.y * sqrt(maxf(0.0, 1.0 - pow(hgt / SHRUB.z, 2.0)))   # a copa: redonda, mais larga embaixo
		var dx := rng.randf_range(-r, r)
		var w := Vector2((SHRUB.x + dx) * gw, gh * (1.0 - hgt) + rng.randf_range(-1.0, 1.0))
		var p := (_side_pt(w, WALL_D + 8.0) - _view_at) * 2.0   # do lado de fora, atrás do vidro
		var k := clampf(_side_pt(w + Vector2(0, 1)).y - _side_pt(w).y, 0.8, 1.6)   # a escala da parede ali
		var sway := roundf(sin(t * 1.4 + i * 0.7) * wind * hgt / SHRUB.z * 1.5)
		var lit := clampf(hgt / SHRUB.z * 0.7 + (dx / maxf(0.01, r)) * 0.15 + rng.randf_range(-0.25, 0.2), 0.0, 0.99)
		var c: Color = (tones[int(lit * tones.size())] as Color).lerp(Color("5a7090"), f * 0.5)
		var px := p.floor() + Vector2(sway, 0)
		var lw := roundf(5.0 * k)
		var lh := roundf(3.0 * k)
		_ci.draw_rect(Rect2(px, Vector2(lw, lh)), c)
		_ci.draw_rect(Rect2(px + Vector2(1, -1), Vector2(lw - 2, 1)), c)
		_ci.draw_rect(Rect2(px + Vector2(1, lh), Vector2(lw - 2, 1)), c.darkened(0.3))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O letreiro de neon do hotel, preso na fachada do outro lado (`o`: o alto dele): HOTEL de cima para baixo, na fonte
## gravada da mesa comutadora (`PixelArt.tiny`). Aceso quase sempre (`_sign_on`); o T falha sozinho.
func _draw_hotel_sign(o: Vector2) -> void:
	_r(o.x + 5, o.y + 2, 1.5, PX, Color("1d262c"))   # o braço
	_r(o.x, o.y, 5, 31 * PX, Color("0a0d10"))   # a caixa
	var on := _sign_on()
	var buzz := on and not (int(Time.get_ticks_msec() / 70.0) % 23 in [3, 4, 9, 15, 16, 17])
	_ci.draw_set_transform(Vector2.ZERO)
	for i in 5:
		var lit := buzz if i == 2 else on
		var tex := PixelArt.tiny("HOTEL"[i])
		_ci.draw_texture(tex, (o * 2.0 + Vector2(3, i * 6 - 2)).floor(), SIGN_RED if lit else Color("3a1512"))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Sorteados sempre do mesmo jeito: a cidade no fundo (em px de 2x2, para cada tamanho de vidro: duas fileiras), os
## prédios do outro lado da rua, de frente (`_houses`, em metros: o de tijolos na esquina, à direita do cruzamento) e
## as paredes da rua do cruzamento (`_canyon`); cada janela acesa com a hora em que apaga (`SLEEP`; algumas ficam
## acesas a noite toda).
func _build_city(gs: Vector2) -> void:
	_city.clear()
	_city_for = gs
	var rng := RandomNumberGenerator.new()
	rng.seed = 1957
	var sleep := RandomNumberGenerator.new()   # à parte: as casas continuam as mesmas
	sleep.seed = 1958
	var off := func() -> float:
		return INF if sleep.randf() < SLEEP.z else sleep.randf_range(SLEEP.x, SLEEP.y)
	for r in [0, 1]:
		var k: float = OUT_F / [400.0, 250.0][r]
		var x := -rng.randf() * 4.0
		while x < gs.x:
			var bw := rng.randf_range(15.0, 35.0) * k
			var bh := (rng.randf_range(30.0, 80.0) if r == 0 else rng.randf_range(15.0, 45.0)) * k
			var lit: Array[Vector3] = []
			var yy := 1.5
			while yy < bh - 1.0:
				var xx := 1.0
				while xx < bw - 1.0:
					if rng.randf() < 0.2:
						lit.append(Vector3(xx, yy, off.call()))
					xx += 2.0
				yy += 2.0
			_city.append({"x": x, "w": bw, "h": bh, "row": r, "lit": lit})
			x += bw + rng.randf_range(0.0, 1.5)
	_houses.clear()
	var tones := [Color("1c1714"), Color("13171b"), Color("1a1512"), Color("171a1d")]
	var spans := [Vector2(CROSSING.y, CROSSING.y + 15.0)]   # o de tijolos, na esquina
	var x := CROSSING.y + 15.0
	while x < 40.0:
		var w := rng.randf_range(9.0, 14.0)
		spans.append(Vector2(x, x + w))
		x += w
	x = CROSSING.x
	while x > -40.0:
		var w := rng.randf_range(9.0, 14.0)
		spans.append(Vector2(x - w, x))
		x -= w
	for i in spans.size():
		var sp: Vector2 = spans[i]
		var floors := 4 if i == 0 else rng.randi_range(2, 4)
		var wins: Array[Vector3] = []
		for f in floors:
			var wsx := sp.x + 1.5
			while wsx < sp.y - 1.0:
				var o := -1.0   # apagada
				if rng.randf() < (0.35 if f > 0 else 0.25):
					o = off.call()
				wins.append(Vector3(wsx, f, o))
				wsx += 3.0
		_houses.append({"x0": sp.x, "x1": sp.y, "h": floors * 3.2 + 0.8, "col": Color("3a2219") if i == 0 else tones[rng.randi_range(0, 3)],
			"brick": i == 0, "wins": wins})
	_canyon.clear()   # as paredes da rua do cruzamento: os fundos dos prédios da esquina e os que vêm depois, até a praça
	for side: float in [CROSSING.x, CROSSING.y]:
		var z := STREET["far"] as float
		while z < 118.0:
			var d := rng.randf_range(10.0, 22.0)
			var ht := rng.randf_range(7.0, 16.0)
			var wins: Array[Vector3] = []
			for i in 6:
				if rng.randf() < 0.4:
					wins.append(Vector3(rng.randf_range(z + 1.0, z + d - 1.0), rng.randf_range(2.0, ht - 1.5), off.call()))
			_canyon.append({"x": side, "z0": z, "z1": z + d, "h": ht, "col": tones[rng.randi_range(0, 3)], "wins": wins})
			z += d
	_canyon.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["z0"] < b["z0"])


## A igreja no fim da rua do cruzamento (na escala dela, `CHURCH_K`): nave, torre com a ponta e o relógio aceso no
## alto; a porta acesa até `CHURCH_DARK`.
func _draw_church(base: Vector2, col: Color) -> void:
	var k := CHURCH_K
	_r(base.x - 12 * k, base.y - 18 * k, 24 * k, 18 * k, col)
	_poly(PackedVector2Array([base + Vector2(-13, -18) * k, base + Vector2(0, -26) * k, base + Vector2(13, -18) * k]), col)
	_r(base.x - 4 * k, base.y - 48 * k, 8 * k, 30 * k, col)
	_poly(PackedVector2Array([base + Vector2(-5, -48) * k, base + Vector2(0, -60) * k, base + Vector2(5, -48) * k]), col)
	_r(base.x - PX, base.y - 64 * k, PX, 4 * k, col)   # a cruz
	_r(base.x - 1, base.y - 63 * k, 2, PX, col)
	var face := base + Vector2(0, -40 * k)
	_ci.draw_circle(face, 1.3, Color("e2b25a"))
	_r(face.x - PX, face.y - 1, PX, 1, Color("2a2016"))   # os ponteiros
	if minutes < CHURCH_DARK:
		_r(base.x - 1, base.y - 4, 2, 4, Color(LIT[1], 0.8))   # a porta, com luz dentro (o relógio fica aceso)


## A poeira na luz da luminária: grãos de um pixel em toda a área que ela ilumina (a do brilho da luz de teto,
## `%Glow`: um círculo largo a partir do alto do meio da tela, que passa por cima da mesa comutadora), mais claros
## perto da luminária e brilhando devagar ao virarem na luz. Fica na camada `dust`, acima da mesa comutadora (a
## poeira que passa na frente dela); o papel de uma ferramenta fica na frente, e ela não desce abaixo do fundo do tampo.
func _draw_dust() -> void:
	_draw_steam()
	var k := lamp_level * (0.5 if _cover.has_area() else 1.0)
	var c := Vector2(_lamp_x * 2.0, 0.0)   # px da tela
	var reach := size.x * 0.5
	for m in _motes:
		var p := Vector2(c.x + m.x * reach, m.y * _top * 2.0)
		var a := (1.0 - minf(1.0, p.distance_to(c) / reach)) * (0.5 + 0.5 * sin(m.z)) * 0.6 * k
		if a > 0.02 and not _cover.has_point(p):
			_dust.draw_rect(Rect2(p.floor(), Vector2.ONE), Color(1.0, 0.9, 0.7, a))


## O vapor do café subindo da caneca, na camada da poeira (anda sem redesenhar a sala): dois fios grossos ondulando
## e alargando para cima, com a beira mais fraca, em sopros que sobem e somem; o café esfria e o vapor some com as horas (`STEAM_FOR`), o
## segundo fio primeiro. Mais visível na luz da luminária.
func _draw_steam() -> void:
	var heat := 1.0 - clampf((minutes - SHIFT_START) / STEAM_FOR, 0.0, 1.0)
	if heat <= 0.0 or _mug_w <= 0.0:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var rise := _mug_w * 1.6
	for wisp in 2:
		var hot := heat if wisp == 0 else clampf(heat * 2.0 - 1.0, 0.0, 1.0)
		if hot <= 0.0:
			continue
		var x0 := _mug_mouth.x + (wisp * 2 - 1) * _mug_w * 0.12
		for s in int(rise):
			var f := s / rise
			var puff := 0.5 + 0.5 * sin(s * 0.22 - t * 2.6 + wisp * 1.9)   # os sopros, subindo
			var a := hot * 0.4 * puff * pow(1.0 - f, 1.5) * smoothstep(0.0, 4.0, s) * lamp_level
			if a < 0.02:
				continue
			var x := x0 + sin(s * 0.13 - t * 1.4 + wisp * 2.4) * (1.0 + s * 0.12)
			var p := Vector2(x, _mug_mouth.y - s).floor()
			if not _cover.has_point(p):   # grosso: o miolo e uma beira mais fraca de cada lado, alargando para cima
				var wd := 2.0 + floorf(f * 4.0)
				var col := Color(0.96, 0.93, 0.86, a)
				_dust.draw_rect(Rect2(p - Vector2(floorf(wd / 2.0), 0), Vector2(wd, 1)), col)
				_dust.draw_rect(Rect2(p - Vector2(floorf(wd / 2.0) + 1.0, 0), Vector2(1, 1)), Color(col, a * 0.45))
				_dust.draw_rect(Rect2(p + Vector2(ceilf(wd / 2.0), 0), Vector2(1, 1)), Color(col, a * 0.45))


## O clima no vidro: a chuva passando e as gotas paradas no vidro, que às vezes escorrem (chuva), e um reflexo na
## diagonal (a névoa fica na vista, `_draw_fog`).
func _draw_glass_weather(g: Rect2) -> void:
	if weather == "rain":
		# os pingos: riscos de 1 px inclinados pelo vento, mais longos e claros os de perto, e acesos perto dos postes
		var heads := _lamp_heads(g)
		for d in _drops:
			if d.x < 0.0 or d.x >= 1.0 or d.y < 0.0:
				continue
			var hp := Vector2(g.position.x + floorf(d.x * g.size.x * 2.0) * PX, g.position.y + floorf(d.y * g.size.y * 2.0) * PX)
			var lit := 0.0
			for h: Vector2 in heads:
				lit = maxf(lit, 1.0 - hp.distance_to(h) / 45.0)
			var col := Color(0.62, 0.72, 0.8).lerp(Color("ffd88a"), lit * 0.7)
			col.a = lerpf(0.14, 0.34, d.z) + lit * 0.3
			var n := lerpf(RAIN_STREAK.x, RAIN_STREAK.y, d.z)
			var cols := 1 + int(n * RAIN_SLANT)   # o rastro sobe para a direita, de onde ele veio, em degraus de 1 px
			var seg := ceilf(n / cols)
			for k in cols:
				_r(hp.x + k * PX, hp.y - (k + 1) * seg * PX, PX, seg * PX, col)
			_r(hp.x, hp.y, PX, PX, Color(col, minf(1.0, col.a * 1.6)))   # a ponta, mais clara
		# as gotas no vidro, só na parte dele que aparece: escuras, com um brilho, quente perto do poste (`_draw_city`)
		var top := g.position.y + g.size.y * _glass_from
		var post := _post(Rect2(g.position, g.size - Vector2(0, _near)))
		for b in _beads:
			var p := Vector2(g.position.x + floorf(b.x * g.size.x * 2.0) * PX, top + floorf(b.y * (g.end.y - top) * 2.0) * PX)
			if b.w > 0.0:   # escorrendo: o rastro molhado acima dela
				for k in 4:
					_r(p.x, p.y - (k + 1) * PX, PX, PX, Color(0.55, 0.66, 0.74, 0.2 - k * 0.045))
			_r(p.x, p.y, b.z * PX, b.z * PX, Color("1c2a32"))
			var warm := clampf(1.0 - p.distance_to(post) / 30.0, 0.0, 1.0) if lamp_level > 0.5 else 0.0
			_r(p.x, p.y, PX, PX, Color("7f98a8").lerp(Color("ffd88a"), warm))
	_poly(PackedVector2Array([g.position + Vector2(g.size.x * 0.12, 0), g.position + Vector2(g.size.x * 0.22, 0),
		g.position + Vector2(g.size.x * 0.02, g.size.y * 0.5), g.position + Vector2(0, g.size.y * 0.5)]), Color(1, 1, 1, 0.03))


# ---------------------------------------------------------------- mesa

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
	# presos a pontas diferentes, eles se trombavam). Atrás: listas, caderno e o relógio com a caneca na frente dele;
	# na frente: mapa, prancheta e o lugar do jornal (guardado mesmo sem ele, para nada mudar de lugar entre as noites).
	# Todos em `PROP_K`, a escala dos plugs da mesa comutadora (que seguem as tomadas)
	var l := _side_x + 8.0
	var r := _cx - _vp.x - WALL_PAD   # a parede da direita é o plano x = quina (na escala da parede do fundo)
	var k := PROP_K
	var cw := CLOCK.x + 2.0   # o relógio, meio virado, ocupa um pouco mais que a largura dele
	var mr := 6.6 * k         # a caneca, na frente do relógio, encostada na ponta direita dele
	# (maiores, e com a prancheta funda, eles se encostavam e a mesa parecia apertada)
	var back := _row(l, r, [31.0 * k, 46.0 * k, cw + mr])
	var near := _row(l + 6.0, r, [35.0 * k, 26.0 * k, 32.0 * k])
	_draw_books(back[0], _at(0.54), 31 * k, _deep(0.3 * k))
	_flat("caderno", back[1], _at(0.56), 46 * k, _deep(0.26 * k), 2 * k, Color("3a2414"), _art_notebook, [], deg_to_rad(-2.0), _notebook_marks)
	_draw_flip_clock(back[2] + cw / 2.0, _at(0.72))   # logo atrás da caneca (desenhado antes dela)
	_draw_mug(back[2] + cw, _at(0.46), mr, 13 * k)   # mais larga que alta, como as esmaltadas
	# papel tem 1 px de beira, e a prancheta, uns 2 (mais grossos, pareciam tábuas)
	var city := CityMap.frame_of(GameData.sectors)   # o mapa tem a proporção das folhas dos bairros atendidos
	_flat("despacho", near[0], _at(0.06), 35 * k, 35 * k * city.size.y / city.size.x, 0.5, Color("a89a76"), _art_map,
		[GameData.sectors.duplicate()], deg_to_rad(3.0), _map_pin)
	_flat("registro", near[1], _at(0.05), 26 * k, _deep(0.26 * k), 1.0, Color("4a3018"), _art_clipboard, [unread], deg_to_rad(-4.0),
		_clipboard_print)
	if news:
		_flat("jornal", near[2], _at(0.07), 32 * k, _deep(0.19 * k), 0.5, Color("a89c78"), _art_newspaper, [], deg_to_rad(6.0),
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


## Uma face de objeto (sem contorno: um fio preto torto pela perspectiva serrilhava e parecia desenho mal feito; as
## faces se separam pela luz, o tampo mais claro e os lados mais escuros).
func _poly(pts: PackedVector2Array, col: Color) -> void:
	_fill(pts, PackedColorArray([col]))


## Um polígono cheio em `_ci` com a cor de cada ponto (`cols`, ou uma só para tudo), em primitivos: o Godot junta os
## `draw_primitive` seguidos numa chamada de desenho só, e cada `draw_polygon` era uma (a sala passava de 2000 por
## quadro, 6 ms de renderização parada, e cada redesenho criava mil polígonos). O quadrilátero vai inteiro (os da sala
## são convexos); o resto, em triângulos. Sem área (uma face vista de quina), não aparece nada.
func _fill(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if pts.size() <= 4:
		_ci.draw_primitive(pts, cols, PackedVector2Array())
		return
	var tri := Geometry2D.triangulate_polygon(pts)
	for i in range(0, tri.size(), 3):
		var c := cols if cols.size() == 1 else PackedColorArray([cols[tri[i]], cols[tri[i + 1]], cols[tri[i + 2]]])
		_ci.draw_primitive(PackedVector2Array([pts[tri[i]], pts[tri[i + 1]], pts[tri[i + 2]]]), c, PackedVector2Array())


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
			_project(["lista", sz], _art_book_cover.bind(cover), top, sz)
		_dim(top, xz)   # longe da luz, ponto a ponto: cada volume logo depois de desenhado (os de cima cobrem os de baixo)
	_props["lista"] = _bounds(all)
	_occ.append(Geometry2D.convex_hull(all))


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


## O mapa da cidade dobrado em sanfona, aberto na mesa: o mapa aberto (`CityMap`) em miniatura, com as mesmas folhas
## (as dos bairros atendidos, enquadradas como ele abre; o papel tem a proporção delas, `_draw_desk_props`), os
## quarteirões no tom de cada bairro com as casas em volta e as árvores dos quintais (`CityMap.lots`), os lugares de
## telhado de barro, a praça com os caminhos e o coreto, a zona rural, as divisas, o selo vermelho e as dobras da
## sanfona alternando luz e sombra. Os nomes ficam de fora: nesse tamanho, seriam só ruído.
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
	var pw := sz.x / 4   # as dobras: quatro painéis em sanfona, um virado para a luz e o outro não, e o vinco do meio
	for k in [1, 3]:
		for y in sz.y:
			for x in range(k * pw, mini(sz.x, (k + 1) * pw)):
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.14))
	for x in sz.x:
		img.set_pixel(x, sz.y / 2, img.get_pixel(x, sz.y / 2).darkened(0.08))
	for k in [1, 2, 3]:
		_fr(img, k * pw - (1 if k != 2 else 0), 0, 1, sz.y, Color("f0e6c8") if k == 2 else Color("8a7c5a"))
	_fr(img, 0, sz.y - 1, sz.x, 1, Color("8a7c5a"))   # a beira de baixo do papel
	return img


## O alfinete do mapa no local marcado, por cima do mapa, na tela: a cabeça redonda vista de cima (torta, serrilhava).
## Parado: piscando e brilhando com uma emergência em andamento, não fazia sentido (um alfinete não acende).
func _map_pin(sz: Vector2i) -> void:
	var sp := _tex_pt(Vector2(sz.x * 0.7, sz.y * 0.42)).round()
	_sprite(PixelArt.disc(6, [[3.0, Color(0, 0, 0, 0.35)]]), sp + Vector2(2, 2))
	_sprite(PixelArt.disc(6, [[1.2, Color("f0a090")], [3.0, Color("e07060"), Color("b03a2e"), Color("7a2418")]]), sp)


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
