class_name Background
extends "res://scripts/ui/background_props.gd"
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
## Objetos na mesa, ao alcance do operador, abrem as ferramentas (`prop_clicked`, o id da ferramenta, `Tools.DIRECTORY`...): as
## listas telefônicas, a unidade de despacho, o caderno aberto, o calculógrafo e a prancheta do registro, pendurada na
## lateral da mesa comutadora (o relógio de flip e a caneca só enfeitam). Ficam na sala, em centímetros da
## mesa, e passam pela mesma câmera (tamanho, escorço e o lado que aparece saem da conta), desenhados em pixels de 1x1
## com o detalhe da mesa comutadora; o resto do cenário também tem o detalhe em 1x1 (`PX`). Sob o mouse, ganham contorno, o nome da ferramenta e
## o cursor de dedo (o `SceneView` repassa o mouse, `pointer`, e desenha o contorno, `draw_hover`); o clique só vale
## sobre eles (`prop_at`) e não com o papel de uma ferramenta por cima.

signal prop_clicked(id: String)

## A luminária esquentando no começo do turno (`warm_up`): acende a WARM.x da luz e chega a ela inteira em WARM.y s,
## devagar no fim, como um filamento; em degraus de WARM_STEP (cada degrau redesenha a sala). Acima de 0,5, para não
## apagar o que segue a luminária piscando (a luz dos postes lavando as fachadas).
const WARM := Vector2(0.55, 4.0)
const WARM_STEP := 0.05
const WARM_DARK := 0.3   ## o escuro a mais na sala com a luminária ainda fria (`_draw_gloom`)
const FLICK := [1.0, 0.2, 1.0, 1.0, 0.5, 1.0, 1.0, 0.1, 1.0, 1.0, 1.0, 0.4, 1.0, 1.0, 1.0, 1.0, 0.2, 1.0, 1.0, 0.6, 1.0, 1.0, 1.0]
const WOOD := [Color("6b4529"), Color("4a2f1c"), Color("2a1a0f")]   ## madeira (luz, meio, sombra), a mesma do móvel
const SIGN_ENAMEL := Color("1f3b35")   ## a placa da companhia telefônica: o esmalte verde-escuro...
const SIGN_INK := Color("d8cfae")   ## ...e o creme das letras e do filete
const SIGN_AT := 0.62   ## onde fica o meio dela, na largura da mesa comutadora (à direita do horário do turno)
const PROPS := {Tools.DIRECTORY: T.Key.TAB_DIRECTORY, Tools.DISPATCH: T.Key.TAB_DISPATCH, Tools.LOGBOOK: T.Key.TAB_LOGBOOK, Tools.CALL_LOG: T.Key.TAB_CALL_LOG,
	Tools.NEWS: T.Key.TAB_NEWS, Tools.TOLL: T.Key.TAB_TOLL}


const TIP_SEC := 1.3   ## o bilhete subindo na fenda do calculógrafo da mesa: o tempo do som da impressora ("printer")
const HUNG := Vector2(18, 24)   ## a prancheta do registro pendurada na lateral do painel: funda (z) e alta (y), na sala
const HUNG_AT := 0.3   ## onde fica o alto dela, na altura do painel
const CALENDAR := "calendario"   ## a folhinha do armário: sob o mouse, a data da noite (não abre ferramenta)
const DETAILS := ["cartaz_quermesse", "numero_anotado", "armario_entreaberto"]   ## o que `RoomChange.detail` pode pedir
const BOARD_SINK := 10.0   ## o fundo do tampo, em px da tela acima da base do painel: fica atrás da mesa comutadora (o painel recuado para a parede, a prateleira funda)
const LAMP_Y := -22.0      ## a boca da luminária, acima da tela (px de 2x2): de onde sai a luz e saem as sombras na parede
const WALL_GAP := 30.0     ## quanto a luminária fica à frente da parede (px de 2x2): abre o arco de luz nela
# A câmera. Medidas da sala na escala da parede do fundo (px de 2x2 lá; ~0,56 cm): x para a direita e y para baixo a
# partir dos olhos, z a distância deles (a parede fica a `Z0`; mais perto, tudo cresce Z0/z vezes).
const VP_AT := 0.20     ## o ponto de fuga no espaço da mesa, da mesa comutadora (0) à quina (1): perto dos objetos (longe dele, eles entortam; com os olhos baixos, mais); com 0,32, a lateral da mesa comutadora saía larga e inclinada demais
const CORNER := 0.64    ## a quina das paredes, na largura da área das ferramentas
const BOARD_GAP := 6.0  ## o vão entre o fundo da mesa comutadora e o fundo do tampo (z, ~4 cm): o móvel vai quase até ele (raso, o tampo atrás dela sobrava); a lateral foge para o ponto de fuga
const DESK_LIP := 2.5   ## o tampo na frente do console (px de 2x2): a borda da frente fica um pouco abaixo da faixa de mesa
const DUST := 240        ## grãos de poeira na luz da luminária
const BEADS := 50        ## gotas paradas no vidro, na chuva
const RAIN := 320        ## pingos caindo lá fora, na chuva
const RAIN_FALL := Vector2(7.0, 12.0)   ## quanto o pingo cai a cada quadro da vista (px de 2x2), do mais longe ao mais perto: cruza o vidro em meio segundo
const BOLT_RAIN := 0.55
## Na noite limpa, nuvens passam pela lua (`CLOUDS`, devagar, `CLOUD_SPEED` da largura do vidro por segundo): coberta,
## ela escurece, e o brilho azul da janela na sala junto (até `MOON_DIM` dele).
const CLOUDS := 5
const MOON_DIM := 0.45
## O vidro embaçado nos cantos e no pé (`_draw_mist`), liso: a força em cada clima (na chuva, menos quanto mais forte).
const MIST := {"fog": 0.38, "clear": 0.34, "rain": 0.26}
const MIST_TINT := Color(0.66, 0.72, 0.78)
const DROP_SHADOW := 1.8   ## a sombra das gotas do vidro na luz da rua na mesa (`_draw_drop_shadows`), em relação à força da luz ali
const NOIR := Color(0.012, 0.022, 0.045, 0.72)   ## o escuro frio da sala fora da luz da luminária (`_draw_gloom`)
const GLOOM_R := Vector2(615, 248)   ## até onde vai a luz da luminária antes do escuro todo (px da tela, elipse em volta da poça na mesa: larga, a mesa toda na luz)
const GLOOM_IN := 0.25   ## dentro dessa fração do raio, nada de escuro: dali para fora ele cresce liso
const WINDOW_GLOW := Color(0.45, 0.62, 1.0, 0.12)   ## o brilho azul da noite entrando pela janela (`_draw_window_glow`)
const WINDOW_GLOW_R := 315.0   ## até onde ele chega (px da tela, a partir do meio do vidro)
const STREET_LIGHT := 1.15   ## a luz da rua entrando pela janela: quanto ela desce para cada unidade que entra na sala (com 1,6, caía perto da parede, um quadrado pequeno para a janela grande)
const CAR_EVERY := Vector2(35, 80)   ## de quanto em quanto tempo passa um carro lá fora (s, sorteado)
const CAR_SEC := 3.2      ## quanto ele leva passando na rua (a ~40 km/h), com os faróis na rua da vista
const WALK_EVERY := Vector2(2, 5)    ## de quanto em quanto tempo alguém passa pela calçada de lá às 18h (s, sorteado)...
const WALK_FROM := 18.0 * 60.0   ## ...e daí (min do dia) o intervalo cresce, cada vez menos gente...
const WALK_UNTIL := 22.0 * 60.0  ## ...até ninguém mais passar (só o homem do mistério)
const WALK_PAIR := 0.2    ## a chance de virem dois juntos
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
const THUNDER_AFTER := Vector2(1.2, 3.5)   ## o trovão vem depois (s, sorteado: longe ou perto)
## O clarão do relâmpago na sala (`_bolt_layer`, somado à luz, `_bolt_build`): quase branco (azulado e espalhado na sala
## inteira, até na frente da mesa comutadora, parecia a noite clareando), só no que a janela alcança.
const BOLT_LIGHT := Color(0.93, 0.96, 1.0)
const BOLT_DIR := Vector2(-1.4, 0.45)   ## para onde a luz dele anda a cada unidade para o fundo (x, para a esquerda; y, para baixo): a sombra do armário na parede
const BOLT_STEEP := 1.2   ## quanto ela desce para cada unidade que entra na sala, até a mesa (a janela desenhada no tampo)
const SIGN_GLOW := Color(1.0, 0.25, 0.18, 0.05)   ## o reflexo vermelho dele na parede, perto da janela
const CAB_W := 82.0             ## a largura do armário de aço, encostado na parede (px de 2x2 lá)
const POSTER_W := 22.0           ## a largura do cartaz da quermesse (px de 2x2)
const CAB_TOP := -26.0           ## o alto dele (cm a partir dos olhos, para baixo): acima deles, ~1,5 m do chão (o tampo não aparece)
const CAB_T := 1.15              ## a frente dele (escala): ~35 cm de fundo
const SILL_D := 9.0        ## quanto o peitoril de dentro sai da parede para a sala
const SHIFT_START := 18.0 * 60.0   ## o começo do turno (min do dia): o café da caneca está quente
const STEAM_FOR := 210.0    ## em quantos minutos de jogo o café esfria e o vapor some (às 21h30)
const BLIND := 0.12        ## até onde a persiana desce (fração da altura do vão)
const TRANSOM := 0.27      ## a travessa do caixilho (fração da altura do vão), alta como a de uma bandeira: no horizonte, ela escondia o fim da rua do cruzamento e a igreja
const X2 := Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2.ZERO)   ## a escala dos px de 2x2 (`_sprite` volta a ela)

@export var window: Control   ## a área das ferramentas: a quina e a janela ficam na parede dela
@export var desk: Control     ## a faixa da miniatura do painel (`ConsoleMini`), a frente do console da mesa comutadora: a borda da frente do tampo fica logo abaixo dela
@export var board: Control    ## o painel da mesa comutadora: pousa na prateleira do console; o fundo do tampo fica `BOARD_SINK` px acima da base dele
@export var dust: Control     ## onde a poeira do feixe é desenhada: acima da mesa comutadora (que fica no ar, na frente dela) e abaixo do painel e dos menus
@export var wall_art: Texture2D     ## imagem da parede (repetida), no lugar do desenho
@export var window_art: Texture2D   ## imagem da vista da janela (esticada, de frente), no lugar da cidade desenhada
# A sala muda ao longo das noites (o Main atualiza): os detalhes valendo (`RoomChange.detail`).
var details := PackedStringArray()
var _dust: Control       # a poeira no feixe da luminária (`dust`): desenhada à parte, a 30 quadros por segundo, sem redesenhar a sala
var _motes: Array = []   # os grãos: Vector3(x de -1 a 1 na largura da luz, y de 0 a 1 do alto da tela ao fundo do tampo, fase do brilho)
var _cab_x0 := 0.0       # o armário na parede do fundo (x a partir do ponto de fuga, px de 2x2): o reflexo no vidro o espelha
var _top := 200.0        # o fundo do tampo (px de 2x2), do último desenho: onde o feixe da luminária acaba
var _win := Vector2(104, 38)   # a vista da janela, em pixels de 2x2 (do último desenho)
var _acc := 0.0
var _hot := ""         # objeto sob o mouse
var _shelf := Vector2(INF, INF)   # `shelf()`, em px do cenário
var _view: Control     # desenha a vista da janela no `_vport`: a frente dela, a cada quadro da vista
var _back: Control     # a parte de trás da vista, embaixo da `_view`: só se redesenha quando muda (`_back_state`)
var _back_drawn := []
var _vport: SubViewport
var _cover := Rect2()   # onde está o papel da ferramenta aberta (px da tela, não de 2x2): luz embaixo dele não brilha
var _drawn := []        # o `_state` do último desenho da sala
var _over: Control      # por cima da sala, o que muda sozinho sem mexer nela (`_draw_over`)
var _over_drawn := []   # o estado do último desenho dela
var _sign_glow := Rect2()   # o halo do letreiro no vidro (vazio = fora do vidro); brilha só aceso
var _bolt_layer: Control   # o clarão do relâmpago, por cima de tudo e somado: só a força muda, no `modulate`
var _bolt_lit: Array = []    # o que ele acende: [polígono (px da tela), cores], medido com a sala (`_bolt_build`)
var _occ_board := PackedVector2Array()   # a mesa comutadora inteira (px da tela)
var _side_faces: Array = []  # a lateral da mesa comutadora (px da tela), virada para a janela: [o console, o painel]
var _panel_z := 0.0  # a frente do painel da mesa comutadora (z)
var tickets := 0          ## bilhetes de tarifação esperando na fenda do calculógrafo (impressos com a ferramenta fechada): a ponta de um saindo dela
var _tip_layer: Control   # a ponta do bilhete no calculógrafo da mesa (`_draw_tip`)
var _tip_n := 0           # quantos bilhetes ela mostrava
var _tip_t := TIP_SEC     # desde que o último saiu (s)
var _tip_h := 0           # a altura dela, desenhada (px)
var _cab := [Rect2(), Rect2()]   # o armário: o fundo dele (na parede) e a frente (px de 2x2)
var _headless := false   # sem tela (os testes): a vista da janela não é desenhada
var _sill_lit: Array = []   # o peitoril na luz de fora: [polígono (px da tela), cores], desenhado por cima do escuro da sala
var _glass := PackedVector2Array()   # o vidro da janela abaixo da persiana (px da tela): o escuro da sala não passa nele
var _sign_px := Vector2.ZERO   # onde o letreiro aparece no vidro (px da tela; zero = fora do vidro)
var _car_in := [20.0, 32.0]          # quanto falta para o próximo de cada mão (s)
var _car_next := ["", ""]            # o modelo do próximo de cada mão (vazio: sorteado; o painel de debug escolhe)
var _walk_in := 3.0      # quanto falta para o próximo (s)
var _dog_in := randf_range(15.0, 50.0)   # quanto falta para o próximo latido, contado a partir de `DOG_FROM` (s)
var _dog_reply := -1.0   # quanto falta para o cachorro que responde (-1 = nenhum)
var _tolls := 0          # badaladas do sino que faltam bater
var _toll_in := 0.0      # quanto falta para a próxima (s)
var _late_sent := -1.0   # o quanto da noite avançada já foi passado ao `Sfx`
var _warm_t := -1.0   # s desde que a luminária acendeu (`warm_up`; -1 = já quente)
var _lamp_dim := false   # a luminária estava baixa no quadro anterior (ao piscar, estala)
var _rain_sent := -1.0   # a força da chuva já passada ao `Sfx`
var _street_map := []   # a conta da luz da rua na mesa (`_draw_street_light`): [x da quina, alturas, fundos, força]
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
	_tip_layer = Control.new()
	_tip_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tip_layer.draw.connect(_draw_tip)
	add_child(_tip_layer)
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
	for i in CLOUDS:
		_clouds.append(Vector3(randf() * 1.4, randf_range(0.1, 0.75), randf_range(0.7, 1.3)))
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
		_tip_layer.queue_redraw()
		_show()
	if tickets > _tip_n:   # saiu um bilhete: a ponta desce da fenda de novo, no tempo da impressora
		_tip_t = 0.0
	_tip_n = tickets
	_tip_t = minf(_tip_t + delta, TIP_SEC)
	var tip := 0 if tickets == 0 else roundi(_tip.size.y * _tip_t / TIP_SEC)
	if tip != _tip_h:
		_tip_h = tip
		_tip_layer.queue_redraw()
		_show()
	var f := snappedf(_flash(), 0.02)
	if f != _bolt_layer.modulate.a:   # o relâmpago: o desenho dele fica; só a força muda
		_bolt_layer.modulate.a = f
		if f > 0.0 and not _bolt_layer.visible:
			_bolt_layer.queue_redraw()
		_bolt_layer.visible = f > 0.0
		_show()
	var ov := [size, _paper(), lamp_level, _sign_on(), _moon_glow(), _mist_force()]
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
	if _warm_t >= 0.0:
		_warm_t += 1.0 / 30.0
		warm = snappedf(1.0 - pow(1.0 - minf(_warm_t / WARM.y, 1.0), 2.0), WARM_STEP)
		if warm >= 1.0:
			_warm_t = -1.0
	var base := lerpf(WARM.x, 1.0, warm)
	if flick:
		lamp_level = FLICK[int(Time.get_ticks_msec() / 90.0) % FLICK.size()] * base
	else:
		lamp_level = base
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


## A luminária acende agora (começo do turno): fraca e alaranjada, esquentando até a luz inteira (`WARM`).
func warm_up() -> void:
	_warm_t = 0.0
	warm = 0.0


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
		window.get_global_rect() if window else Rect2(), lamp_level, pending, unread, alert, card_out, news, counting, toll_desk, details, night, weather,
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
			var kind: String = _car_next[lane] if _car_next[lane] != "" else _car_kind()
			_car_next[lane] = ""
			_cars.append({"t": 0.0, "lane": lane, "kind": kind, "col": CAR_COLORS.pick_random(),
				"taxi": kind in TAXI_KINDS and randf() < TAXI})
			_car_in[lane] = INF   # o próximo desta mão é sorteado quando este sair
			Sfx.play_at(("car_wet" if weather == "rain" else "car") + ("_near" if lane == 1 else ""), x, 0.0,
				CAR_KINDS[kind]["pitch"] * randf_range(0.97, 1.03))   # o de cá, mais perto; cada modelo no tom dele
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
	_bolt_in -= delta
	if weather == "rain" and rain_level() != _rain_sent:   # a chuva engrossa e afina: o som acompanha
		_rain_sent = rain_level()
		Sfx.set_rain(_rain_sent)
	if _bolt < 0.0 and _bolt_in <= 0.0 and weather == "rain" and rain_level() > BOLT_RAIN:   # só na chuva forte
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


## Faz passar agora um carro na mão `lane` (0: a de lá), do modelo `kind` (vazio: sorteado), se ela estiver livre (debug).
func pass_car(lane: int, kind := "") -> void:
	if _cars.all(func(c: Dictionary) -> bool: return c["lane"] != lane):
		_car_in[lane] = 0.0
		_car_next[lane] = kind


## Um modelo de carro sorteado pelo quanto ele passa (`CAR_KINDS`, `weight`).
func _car_kind() -> String:
	var total := 0.0
	for k: String in CAR_KINDS:
		total += CAR_KINDS[k]["weight"]
	var r := randf() * total
	for k: String in CAR_KINDS:
		r -= CAR_KINDS[k]["weight"]
		if r <= 0.0:
			return k
	return "fusca"


## O sino da igreja bate a hora (`count` badaladas), começando um pouco depois do gongo da mesa.
func toll(count: int) -> void:
	_tolls = count
	_toll_in = BELL_AFTER


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


## Os olhos do operador, o ponto de fuga da sala, em px da tela: a mesa comutadora tira deles a paralaxe dos plugs
## encaixados (`Switchboard.eye`). Antes do primeiro desenho, INF.
func eye() -> Vector2:
	return _vp * 2.0 + global_position if _vp != Vector2.ZERO else Vector2(INF, INF)


## Onde fica na tela (global) o objeto da mesa que abre a ferramenta `id` (vazio se ele não está na mesa): de onde o
## papel dela sai (`Tools.origin`).
func prop_rect(id: String) -> Rect2:
	return Rect2(global_position + (_props[id] as Rect2).position, (_props[id] as Rect2).size) if _props.has(id) else Rect2()


func _draw() -> void:
	_glows.clear()
	_props.clear()
	_occ.clear()
	occ_ids.clear()
	_side_faces.clear()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var w := ceilf(size.x / 2.0)
	var h := ceilf(size.y / 2.0)
	# o fundo do tampo: atrás da mesa comutadora, que fica de pé nele
	var top := floorf((board.global_position.y - global_position.y + board.size.y - BOARD_SINK) / 2.0) if board else 200.0
	# a borda da frente do tampo: um pouco abaixo da faixa de mesa, a frente do console (o painel do operador cobre o resto)
	var front := floorf((desk.global_position.y - global_position.y + desk.size.y) / 2.0) + 1.0 + DESK_LIP if desk else h - 20.0
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
		_draw_poster(Rect2(floorf(cab.end.x + gap), 26, POSTER_W, 28))
	_zd = Vector2(Z0 * _yd / (front - _vp.y), Z0 / DESK_T)
	_draw_desk(Rect2(0, top, w, h - top), front)
	_draw_switchboard()
	_draw_side_wall(top, front, w)
	_draw_hung_clipboard()
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
	_draw_mist()
	if _cover.has_area():   # uma ferramenta na frente do operador: o cenário atrás escurece e o papel faz sombra nele
		_ci.draw_set_transform(Vector2.ZERO)
		_ci.draw_rect(Rect2(_cover.position + Vector2(10, 12), _cover.size), Color(0, 0, 0, 0.35))
		_ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.28))
	_ci = self


## A ponta do bilhete de tarifação saindo da fenda do calculógrafo da mesa para a mesinha dele (`_tip`, `_tip_layer`),
## a beira serrilhada na frente, como sai na ferramenta, descendo pixel a pixel enquanto ele é impresso (`TIP_SEC`; na
## sala, ela se redesenhava a cada um).
func _draw_tip() -> void:
	if _tip_h <= 0:
		return
	var r := Rect2(_tip.position, Vector2(_tip.size.x, _tip_h))
	_tip_layer.draw_rect(r, TollTicket.PAPER.darkened(_tip_dark))
	for x in range(0, int(r.size.x), 2):
		_tip_layer.draw_rect(Rect2(r.position.x + x, r.end.y - 1.0, 1, 1), TollTicket.EDGE.darkened(_tip_dark))
	if not _tip_cover.is_empty() and Rect2(_tip_cover[1] - _tip_cover[0].get_size() / 2.0, _tip_cover[0].get_size()).intersects(r):
		PixelArt.sprite(_tip_layer, _tip_cover[0], _tip_cover[1], _tip_cover[2])   # o carimbo em pé na frente da fenda tampa a ponta


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
	var ty := floorf(gh * TRANSOM) - 1.0
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
## rua tem a luz dela. A luminária piscando ou ainda esquentando (`warm`) escurece tudo junto.
func _draw_gloom() -> void:
	_ci.draw_set_transform(Vector2.ZERO)
	var pool := _pool()
	var c := _proj(pool.x, _yd, pool.y) * 2.0
	var dark := func(p: Vector2) -> Color:
		var k := smoothstep(GLOOM_IN, 1.0, ((p - c) / GLOOM_R).length())
		return Color(NOIR, clampf(NOIR.a * k + (1.0 - lamp_level) * 0.3 + (1.0 - warm) * WARM_DARK, 0.0, 0.9))
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
	var strength: float = WINDOW_GLOW.a * {"clear": 1.0, "rain": 0.8, "fog": 1.2}.get(weather, 1.0) * lerpf(MOON_DIM, 1.0, _moon_glow())
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


## O vidro embaçado do lado de dentro: liso, nos cantos e no pé dele (onde a água junta), só na parte que aparece
## abaixo da persiana (`_glass`). A força é do clima (`_mist_force`).
func _draw_mist() -> void:
	var force := _mist_force()
	if _glass.size() < 3 or force <= 0.0:
		return
	_ci.draw_set_transform(Vector2.ZERO)
	var b := _bounds(_glass)
	var fog := func(p: Vector2) -> Color:
		var u := (p - b.position) / b.size
		var e := pow(pow(absf(u.x * 2.0 - 1.0), 2.0) + pow(absf(u.y * 2.0 - 1.0), 2.0), 0.5)   # mais nos cantos
		return Color(MIST_TINT, force * clampf(smoothstep(0.75, 1.4, e) + pow(clampf(u.y, 0.0, 1.0), 5.0) * 0.45, 0.0, 1.0))
	var n := Vector2i(12, 10)
	var cell := b.size / Vector2(n)
	for j in n.y:
		for i in n.x:
			var a := b.position + cell * Vector2(i, j)
			var quad := PackedVector2Array([a, a + Vector2(cell.x, 0), a + cell, a + Vector2(0, cell.y)])
			for part: PackedVector2Array in Geometry2D.intersect_polygons(quad, _glass):
				var cols := PackedColorArray()
				for p in part:
					cols.append(fog.call(p))
				_fill(part, cols)
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## A força do vidro embaçado agora (`MIST`): na chuva, mais fraco quanto mais forte ela está.
func _mist_force() -> float:
	var f: float = MIST.get(weather, 0.0)
	return snappedf(f * (1.0 - 0.5 * rain_level()) if weather == "rain" else f, 0.02)


## A placa esmaltada da companhia telefônica, na parede acima da mesa comutadora (`b`, em px da tela), à direita do
## horário do turno colado ali: fundo verde-escuro, filete creme, o nome em creme (`SIGN_COMPANY`), um parafuso de
## latão em cada ponta e a sombra na parede. Em px da tela (1x1: o texto fica nítido).
func _draw_company_sign(b: Rect2) -> void:
	draw_set_transform(Vector2.ZERO)
	var company := T.text(T.Key.SIGN_COMPANY)
	var tw := Pal.mono.get_string_size(company, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var r := Rect2(roundf(b.position.x + b.size.x * SIGN_AT - (tw + 36.0) / 2.0), b.position.y - 28.0, roundf(tw + 36.0), 20.0)
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r.grow(1), Switchboard.EDGE_DARK)
	draw_rect(r, SIGN_ENAMEL)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), SIGN_ENAMEL.lightened(0.25))   # a luz na beira de cima
	draw_rect(r.grow(-3), SIGN_INK, false, 1.0)   # o filete
	for x in [r.position.x + 8.0, r.end.x - 8.0]:
		_sprite(PixelArt.disc(5, [[1.5, Color("e6cf8e"), Color("c4a35a"), Color("7a6230")], [2.5, Color("3a2a12")]]), Vector2(x, r.get_center().y))
	draw_string(Pal.mono, Vector2(roundf(r.get_center().x - tw / 2.0), r.position.y + 14.0), company, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, SIGN_INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O objeto sob o mouse: contorno e o nome da ferramenta que ele abre, desenhados em `ci` (o `SceneView`, por cima do
## cenário e na resolução da interface: o texto fica nítido).
func draw_hover(ci: CanvasItem) -> void:
	if _hot == "" or not _props.has(_hot):
		return
	var hr: Rect2 = _props[_hot]
	ci.draw_rect(hr.grow(2), Color(Pal.GLOW, 0.8), false, 2.0)
	var cap := GameData.date_text(night) if _hot == CALENDAR else T.text(PROPS[_hot])
	var cw := Pal.ui.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var at := Vector2(clampf(hr.get_center().x - cw / 2.0 - 5, 4, size.x - cw - 14), hr.position.y - 22)
	var b := Rect2(board.global_position - global_position, board.size) if board else Rect2()
	if hr.get_center().x > b.end.x and at.x < b.end.x:   # a mesa comutadora fica por cima do cenário: o nome da prancheta, na lateral dela, vai todo para fora
		at.x = b.end.x + 2.0
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
		if id in PROPS:
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


## Sombra na parede de um objeto à frente dela (`r` em px de 2x2): a silhueta ampliada a partir da luminária, `s` vezes
## (mais longe da parede, maior), com a penumbra em degraus.
func _cast(r: Rect2, s: float) -> void:
	var l := Vector2(_lamp_x, LAMP_Y)
	for k in 3:
		var f := 1.0 + (s - 1.0) * (1.0 + k * 0.35)
		var p := (l + (r.position - l) * f).round()
		_r(p.x, p.y, roundf(r.size.x * f), roundf(r.size.y * f), Color(0, 0, 0, 0.14))


## A prancheta do registro, pendurada num prego na lateral do painel da mesa comutadora (a virada para a janela), rente
## a ela e na perspectiva dela (`HUNG`, na sala; mais funda que o painel, passa um pouco da quina de trás): o mesmo
## desenho da que ficava na mesa (`_art_clipboard`, `_clipboard_print`), com a sombra na lateral.
func _draw_hung_clipboard() -> void:
	if _side_faces.size() < 2:
		return
	draw_set_transform(Vector2.ZERO)
	var b := Rect2(board.global_position - global_position, board.size)
	var y0 := ((b.position.y + b.size.y * HUNG_AT) / 2.0 - _vp.y) * _panel_z / Z0
	var at := func(dz: float, dy: float) -> Vector2: return _p3(_side_x, y0 + dy, _panel_z + 1.5 + dz)
	var q := PackedVector2Array([at.call(0, 0), at.call(HUNG.x, 0), at.call(HUNG.x, HUNG.y), at.call(0, HUNG.y)])
	var drop := PackedVector2Array([at.call(1, 1.5), at.call(HUNG.x + 1, 1.5), at.call(HUNG.x + 1, HUNG.y + 1.5), at.call(1, HUNG.y + 1.5)])
	for s: PackedVector2Array in Geometry2D.intersect_polygons(drop, _side_faces[1]):   # a sombra: só onde há lateral atrás
		_poly(s, Color(0, 0, 0, 0.3))
	_flat_art(Tools.CALL_LOG, q, _art_clipboard, [unread], 0.12)
	_clipboard_print(Vector2i(_hom_sz))
	_props[Tools.CALL_LOG] = _bounds(q)
	_occ.append(q)
	occ_ids.append(Tools.CALL_LOG)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Calendário de folhinha: o mês da noite (`GameData.date_of`) com o cabeçalho vermelho e a semana começando na
## segunda, os domingos em vermelho, os dias que já passaram riscados e o de hoje circulado. Sob o mouse, a data
## por extenso (`CALENDAR`).
func _draw_calendar(r: Rect2) -> void:
	_cast(r, 1.01)
	var o := r.position * 2.0
	var w := r.size.x * 2.0
	_props[CALENDAR] = Rect2(o, r.size * 2.0)
	_p(o.x, o.y, w, r.size.y * 2.0, Color("e3d6b2"))
	_p(o.x, o.y, w, 12, Color("8e2a22"))   # o cabeçalho com o mês
	_p(o.x, o.y, w, 1, Color("b04a3e"))
	var today := GameData.date_of(night)
	var first := (int(today.weekday) - int(today.day) + 7 * 6) % 7   # a coluna do dia 1 (0 = segunda)
	var days: int = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict({"year": today.year,
		"month": today.month % 12 + 1, "day": 1, "hour": 12}) - 86400).day   # o último dia do mês
	_ci.draw_set_transform(Vector2.ZERO)   # os algarismos na fonte gravada, em px da tela
	var head := PixelArt.tiny("%s %d" % [T.text(T.Key.CALENDAR_MONTH), today.year])
	_ci.draw_texture(head, (o + Vector2((w - head.get_width()) / 2.0, 0)).floor(), Color("e3d6b2"))
	var cells := {}
	for day in range(1, days + 1):
		var k: int = first + day - 1
		var c := o + Vector2(2 + (k % 7) * 10, 14 + (k / 7) * 8)   # 10 px: com 9, os números de dois algarismos se encostavam
		cells[day] = c
		var tex := PixelArt.tiny(str(day))
		_ci.draw_texture(tex, (c + Vector2(5.5 - tex.get_width() / 2.0, -2)).floor(), Color("a8382c") if k % 7 == 6 else Color("4e4636"))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	for day: int in cells:
		var c: Vector2 = cells[day]
		if day < today.day:   # já passou: riscado de vermelho
			_ci.draw_line((c + Vector2(1, 7)) * PX, (c + Vector2(10, 0)) * PX, Color("b03a2e", 0.85), PX)
		elif day == today.day:   # hoje: circulado
			_ci.draw_rect(Rect2((c + Vector2(0, -1)) * PX, Vector2(11, 9) * PX), Color("b03a2e"), false, PX)
	_p(o.x + r.size.x - 1, o.y - 2, 2, 2, Color("3a3a3a"))   # o prego


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
	var clouds := 0   # as nuvens andam um pixel
	if weather == "clear" and not _clouds.is_empty():
		clouds = int(_cloud_x(_clouds[0]) * _vport.size.x)
	elif weather == "rain":
		clouds = int(_overcast_x(0) * _vport.size.x)
	return [_vport.size, _near, weather, window_art, int(minutes), flick, lamp_level > 0.5, snappedf(_flash(), 0.02),
		_sign_on(), stars, clouds, _moon_light(), snappedf(minutes, 0.5) if weather != "rain" and _moon_t() < 1.0 else 0.0]   # (a lua subindo: meio minuto, ~0,6 px)


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
## quase até o fundo do tampo, `BOARD_GAP`, e o painel em cima dele) e, com os olhos acima dele, o tampo do painel. Painel e console têm a mesma
## largura na sala: o console, mais perto, sai mais largo na tela (a esquerda passa da borda). Em px da tela (1x1).
func _draw_switchboard() -> void:
	if not (board and desk):
		return
	draw_set_transform(Vector2.ZERO)
	var vp := _vp * 2.0
	var b := Rect2(board.global_position - global_position, board.size)
	var sy := desk.global_position.y - global_position.y   # a prateleira, no alto da faixa de mesa
	var fy := sy + desk.size.y                             # o pé do console, no tampo, `DESK_LIP` atrás da borda
	var k := (b.end.y - vp.y) / maxf(1.0, sy - vp.y)       # quanto o painel encolhe visto da frente do console
	var zp := Z0 * _yd / (fy / 2.0 - _vp.y) / k            # o painel (z), a partir do pé do console
	var kb := zp / (Z0 / DESK_T - BOARD_GAP)
	_panel_z = zp
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
		var px := maxf(fx0, 0.0) + 8.0   # a coluna dos parafusos da beira: a plaqueta fica no meio entre ela e a miniatura
		Switchboard.draw_maker_plate(self, Rect2(roundf((px + rr.position.x - 96.0) / 2.0), my - 13, 96, 26))   # a plaqueta do fabricante
		for i in 2:   # baquelite: a borda em volta do tampo, os dois com a luz no alto à esquerda, a espaços iguais entre a miniatura e a beira
			var c := Vector2(rr.end.x + roundf((fx1 - rr.end.x) * (i + 1) / 3.0), my)
			_sprite(PixelArt.disc(15, [[7.0, Color(0, 0, 0, 0.35)]]), c + Vector2(1, 2))
			_sprite(PixelArt.disc(13, [[4.0, Color("5a5048"), Color("3a332c"), Color("2a2420")],
				[5.5, Color("4a4038"), Color("2a2420"), Color("1a1612")], [6.5, Color("120e0a")]]), c)
			var a := -PI * 0.75 + i * 1.1
			for j in range(2, 5):   # o risco de posição, pixel a pixel
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
	var mx := gw / 2.0
	var ty := floorf(gh * TRANSOM) - 1
	var near_x := minf(_side_pt(Vector2(gw, ty)).x, w)   # o batente de perto, ou a borda da tela
	var out_x := roundf(lerpf(_side_pt(Vector2(mx + 1, ty), WALL_D).x, near_x, OUT_AT) - view.position.x)
	if _vport.size != Vector2i(view.size * 2.0) or out_x != _out_x:   # o vidro em px da tela: a vista também é desenhada em 1x1
		_out_x = out_x
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
		_light(Rect2(Vector2(floorf(face.x * 2.0) - 1.0, roundf(face.y * 2.0) - 1.0), Vector2(3, 3)), Color("e2b25a"), 0.25, true)   # (do tamanho dele, 3 px; `_draw_church`)
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
	_street_map = [xc, hs, ts, cool]
	var street := Color(0.6, 0.72, 0.9)
	var on_desk := _street_pt
	var glow := func(u: float, v: float) -> Color:
		return Color(street, _street_glow(u, v))
	var n := 14
	for i in n:
		for k in n:
			var u0 := lerpf(-0.35, 1.65, float(i) / n)
			var u1 := lerpf(-0.35, 1.65, float(i + 1) / n)
			var v0 := lerpf(0.0, 1.35, float(k) / n)
			var v1 := lerpf(0.0, 1.35, float(k + 1) / n)
			_fill(PackedVector2Array([on_desk.call(u0, v0), on_desk.call(u0, v1), on_desk.call(u1, v1), on_desk.call(u1, v0)]),
				PackedColorArray([glow.call(u0, v0), glow.call(u0, v1), glow.call(u1, v1), glow.call(u1, v0)]))


## Onde cai na mesa o ponto (`u`, `v`) do vão da janela (`u`: do peitoril, 0, ao pé da persiana, 1; `v`: ao longo da
## parede), na luz da rua (`_draw_street_light`, que guarda a conta em `_street_map`); em px de 2x2.
func _street_pt(u: float, v: float) -> Vector2:
	var hs: Array[float] = _street_map[1]
	var ts: Array[float] = _street_map[2]
	var drop := _yd - lerpf(hs[0], hs[1], u)
	return _proj(_street_map[0] - drop / STREET_LIGHT, _yd, Z0 / maxf(DESK_T, lerpf(ts[0], ts[1], v)))   # (nunca atrás do tampo)


## A força da luz da rua na mesa no ponto (`u`, `v`) do vão: lisa, sumindo nas beiras.
func _street_glow(u: float, v: float) -> float:
	var a := smoothstep(-0.35, 0.45, u) * smoothstep(1.65, 0.6, u) * smoothstep(0.0, 0.45, v) * smoothstep(1.35, 0.55, v)
	return _street_map[3] * a * 4.5


## Na chuva, as gotas paradas e escorrendo no vidro (`_beads`) fazem sombra na luz da rua na mesa, levadas pela mesma
## conta dela (`_street_pt`): a luz é fraca, então são só manchinhas sem borda (o miolo e um halo mais fraco em volta)
## e, nas que escorrem, um rastro apagado; mais fortes onde a luz é mais forte. Na camada da poeira (anda a 30 quadros
## por segundo sem redesenhar a sala).
func _draw_drop_shadows() -> void:
	if weather != "rain" or _street_map.is_empty() or lamp_level <= 0.5:
		return
	for b: Vector4 in _beads:
		var u := 1.0 - b.y   # o vidro à vista, de cima para baixo; na mesa, do alto do vão (longe da parede) ao peitoril
		var v := b.x
		var a := _street_glow(u, v) * DROP_SHADOW
		if a < 0.01:
			continue
		var p := (_street_pt(u, v) * 2.0).floor()
		if _cover.has_point(p):
			continue
		var shade := Color(0.0, 0.01, 0.03, a * 0.4)
		_dust.draw_rect(Rect2(p - Vector2(1, 1), Vector2(b.z + 3.0, b.z + 2.0)), shade)   # o halo, sem borda marcada
		_dust.draw_rect(Rect2(p, Vector2(b.z + 1.0, b.z)), shade)   # e o miolo, por cima
		if b.w > 0.0:   # escorrendo: o rastro molhado, apagado, para trás (para longe da parede)
			var q := (_street_pt(minf(1.0, u + 0.06), v) * 2.0).floor()
			for k in 5:
				_dust.draw_rect(Rect2(p.lerp(q, (k + 1) / 5.0).floor(), Vector2(2, 1)), Color(shade, a * (0.25 - k * 0.04)))


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
		_draw_calendar(Rect2(mid + 10, doors + 44, 37, 28))   # preso com ímã
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


## A poeira na luz da luminária: grãos de um pixel em toda a área que ela ilumina (a do brilho da luz de teto,
## `%Glow`: um círculo largo a partir do alto do meio da tela, que passa por cima da mesa comutadora), mais claros
## perto da luminária e brilhando devagar ao virarem na luz. Fica na camada `dust`, acima da mesa comutadora (a
## poeira que passa na frente dela); o papel de uma ferramenta fica na frente, e ela não desce abaixo do fundo do tampo.
func _draw_dust() -> void:
	_draw_steam()
	_draw_drop_shadows()
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
