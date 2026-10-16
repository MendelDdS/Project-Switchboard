extends "res://scripts/ui/background_base.gd"
## A vista da janela do cenário (`Background`): a rua lá fora numa cena 3D simples (`OUT_*`, `_o`), com a cidade,
## o clima, quem passa, os carros, o homem do mistério e o arbusto. Desenhada de frente no vidro (`_vport`).

const SLEEP := Vector3(19 * 60, 23 * 60 + 50, 0.15)   ## as janelas apagam entre x e y (minutos do dia); z: as que ficam acesas
const CHURCH_DARK := 22 * 60   ## a porta da igreja apaga
const RAIN_STREAK := Vector2(6.0, 14.0) ## o comprimento do risco (px da tela), do mais longe ao mais perto: o rastro do quadro
const RAIN_SLANT := 0.18 ## o vento: quanto o pingo anda para a esquerda a cada px que cai
const WALK_SPAN := 16.0   ## de onde a onde quem passa anda (m dos dois lados do meio): fora do vidro, para entrar e sair pelas beiras dele (com 11, nascia e sumia no vidro)
const WALK_SEC := 18.0    ## quanto leva atravessando (~1,8 m/s, de 16 m a 16 m; cada um ±20%)
const WALK_STEPS := 2.2   ## passos por segundo (as pernas alternam nesse ritmo)
## A vista é uma cena 3D simples projetada para o vidro (pensada antes, não elemento por elemento): uma câmera dentro
## do prédio, na altura de quem está na janela (`OUT_EYE` m acima da rua: o horizonte passa ali), olhando para fora,
## de frente para uma rua que passa ao lado do prédio e continua para os dois lados. Um ponto de fuga só, no meio do
## horizonte (`OUT_AT`, ao lado do montante), na altura do da sala (a altura dos olhos, `_vp`: uma câmera só para o cenário inteiro): para ele fogem só as linhas que vão para longe (a rua do cruzamento,
## as laterais dos prédios); a rua, os meios-fios e as fachadas de frente ficam na horizontal, e as paredes na
## vertical. Não é a perspectiva da janela (a diagonal dela é só do primeiro plano). Tudo em metros (`_o`: `x` ao longo
## da rua, `z` a distância dos olhos, `h` a altura), no tamanho de verdade.
const OUT_EYE := 3.8      ## os olhos acima da rua (m)
const OUT_F := 38.0       ## a distância focal (px de 2x2 de um metro a um metro): com 45, a vista ficava perto e o vidro mostrava pouco da rua; com 32 e a rua mais larga, quem passava era um palito
## O ponto de fuga lá fora, de lado a lado do vidro de perto (do montante, 0, ao batente de perto, 1): no meio da vista,
## a rua do cruzamento e a igreja ficavam atrás do montante.
const OUT_AT := 0.4
## O horizonte lá fora abaixo da altura dos olhos (cm): a janela desceu (`WIN_TOP`, `WIN_SILL`) e a vista desceu com
## ela, para os prédios ficarem no meio do vidro, abaixo da persiana, em vez de atrás dela.
const OUT_DROP := 18.0
## A rua, de perto para longe (z, m): a nossa fachada, a nossa calçada até o meio-fio, as duas mãos (a faixa no meio),
## o meio-fio de lá, a calçada de lá e as fachadas do outro lado, apoiadas nela.
const STREET := {"curb": 2.8, "lane": 5.2, "far_curb": 7.6, "far": 9.4}   # (era de 14 m: quem passava tinha 8 px)
const CROSSING := Vector2(-3.7, 1.2)   ## a rua do cruzamento, indo embora entre os prédios de lá (x, m)
const FAR_LAMPS := [1.6, -10.4, 11.6]  ## os postes da calçada de lá (x, m): o primeiro na esquina do prédio de tijolos, com o homem
const MAN_X := 2.1        ## onde o homem fica, embaixo do poste da esquina
const MAN_FROM := 14.0    ## de onde ele vem pela calçada (x, m; fora do vidro) e para onde volta
const MAN_WALK := 6.0     ## quanto ele leva andando de lá até o poste (min de jogo: ~8 s, ~1,6 m/s)
const MAN_STRIDE := 0.75  ## o passo dele (m)
## A porta do bar, ao lado da vitrine (de x a y, m): de vez em quando alguém sai por ela (`_bar_t`, posto pelo
## `Background`); ela abre em BAR_SWING s, fica aberta e fecha, em BAR_SEC s ao todo.
const BAR_DOOR := Vector2(3.85, 4.65)
const BAR_SWING := 0.3
const BAR_SEC := 2.4
const RIM := Color(1.0, 0.8, 0.5)   ## a luz dos postes na beira de quem passa embaixo deles
## Alguém fuma na varanda do apartamento de vez em quando (`_smoke_t`, posto pelo `Background`): sai pela porta, fica
## SMOKE_SEC s no gradil, na frente da janela da TV, com a brasa acendendo a cada tragada (`PUFF_EVERY`), e volta.
const SMOKE_SEC := 40.0
const PUFF_EVERY := 7.0
const EMBER := Color(1.0, 0.45, 0.15)
## O gato de algumas noites (`CAT_NIGHTS` delas, sorteado pela noite, `_cat_plan`): sentado na marquise do hotel ou no
## gradil da varanda por um tempo, piscando os olhos acesos e mexendo o rabo.
const CAT_NIGHTS := 0.5
const CAT_EYES := Color(0.85, 0.9, 0.35)
const BIKE_SEC := 7.0     ## quanto quem passa de bicicleta leva de um lado ao outro (~4,5 m/s; cada um ±15%)
## Os telefones da lista que se veem do outro lado da rua (`phones`, posto pelo Main): o Hotel Estrela, no saguão, pela
## porta embaixo da marquise, e o Bar do Zé, atrás da vitrine. Transferida a ligação para um deles, alguém vem atender.
const CALLED := [305, 327]
const PHONE_WALK := 1.6   ## quanto a pessoa leva até o telefone (s)
const HOTEL_X := -5.8     ## o letreiro do hotel, no prédio do outro lado da esquina
## O táxi que para na marquise do hotel (`Background.TAXI_STOPS` por noite): pela mão de lá, chega freando em
## `TAXI_STOP.x` s com o meio na porta, fica parado `TAXI_STOP.y` s e sai acelerando em `TAXI_STOP.z` s (`_taxi_x`).
## O passageiro (`GUEST`) desce do lado da calçada `x` s depois de parar, a porta bate em `y` e ele leva `z` s com a
## mala até a porta do hotel, onde some (`_draw_guest`).
const TAXI_STOP := Vector3(3.2, 6.5, 3.0)
const GUEST := Vector3(0.5, 1.2, 3.6)
## Um vira-lata caramelo trotando pela calçada de lá de vez em quando (`Background.STRAY_EVERY`; com chuva, não): em
## pixel art, dois quadros do trote (`STRAY_ART`), virado para onde vai; uns pixels maior que o de verdade, como o gato.
## Escuro, sumia na calçada: o pelo caramelo, apagado pela noite, aparece contra ela.
const STRAY_SEC := 22.0   ## quanto ele leva de um lado ao outro (~1,5 m/s; cada um ±15%)
const STRAY_COAT := Color("4e3218")
## As roupas de quem passa na calçada de lá (`_walker` sorteia), em cores apagadas pela noite, como o pelo do
## vira-lata: aparecem contra a calçada e acendem embaixo dos postes. Casacos e paletós; vestidos e saias; calças;
## a pele; os guarda-chuvas.
const WALK_COATS := [Color("4a3020"), Color("2c3448"), Color("444232"), Color("4e2426"), Color("5e5440"), Color("38383c"),
	Color("1c1c20"), Color("3e2c3a")]
const WALK_DRESSES := [Color("5e2a34"), Color("2a4452"), Color("6a5c30"), Color("365032"), Color("4c3050"), Color("5a4a44")]
const WALK_LEGS := [Color("18181c"), Color("26221c"), Color("262a34"), Color("3a342a")]
const WALK_SKIN := [Color("b08868"), Color("8a5e40"), Color("62422c"), Color("44302a")]
const WALK_UMBRELLAS := [Color("121318"), Color("121318"), Color("4e1a1e"), Color("1c2640"), Color("2a3426")]
const STRAY_ART := [["......#...", "#.....###.", ".#########", ".######...", "#..#.#..#.", "#..#.#..#."],
	["......#...", "#.....###.", ".#########", ".######...", ".##...##..", ".##...##.."]]
## As mariposas em volta das cabeças acesas dos postes, nas noites limpas: quantas por poste e a cor delas na luz.
const MOTHS := 5
const MOTH := Color(1.0, 0.94, 0.78)
## O prédio de tijolos da esquina é de apartamentos: no 3º andar (de `floor` m), uma varanda de `x0` a `x1` (m ao longo
## da rua), saindo `deep` m da fachada, com a porta (`door`, de x a y) e a janela da sala (`win`), onde a TV fica ligada.
const APT := {"x0": 1.9, "x1": 4.9, "floor": 6.5, "deep": 1.0, "door": Vector2(2.2, 2.9), "win": Vector2(3.4, 4.6)}
const APT_DARK := 21 * 60 + 40   ## a luz da sala do apartamento apaga: dali em diante, só a TV
const TV_OFF := 23 * 60 + 35     ## e a TV também (alguém dormiu na frente dela)
const TV_BLUE := Color(0.42, 0.58, 0.95)   ## a luz da TV no vidro
## Janelas que acendem de madrugada (alguém levantou): `WAKE.x` delas, das janelas que já apagaram, acendem de novo
## uma vez entre `WAKE_FROM` e a meia-noite, por `WAKE_FOR` min (sorteado, sempre o mesmo).
const WAKE := 0.14
const WAKE_FROM := 21 * 60 + 30
const WAKE_FOR := Vector2(4, 14)
## As duas mãos da rua: [o meio do carro (z, m), o sentido (-1: para a esquerda)]. Pela mão de lá, da direita para a
## esquerda; pela de cá, entre o nosso meio-fio e a faixa do meio, voltando, da esquerda para a direita.
const CAR_LANES := [Vector2(6.4, -1.0), Vector2(4.5, 1.0)]
## Os carros da rua, os de 1973 (em metros, a partir da frente: `along`, altura): o comprimento e a largura, o lado
## de cá (`body`, e a cabine da picape, `cab`), os vidros do lado (`win`: os quatro cantos, de baixo da frente ao de
## baixo de trás) e as colunas entre eles, o que se vê de cima (`tops`: de, até, altura), os vidros inclinados (`glass`:
## de, altura, até, altura) e as chapas inclinadas (`slopes`), a altura da frente e da traseira (e o vidro delas, numa
## Kombi), os frisos, as portas, as rodas (onde e o raio), a altura dos faróis, a linha de cintura (`belt`) e o som (o
## tom do motor, `pitch`). `weight`: quantos passam (o Fusca é o mais comum). O Fusca tem os faróis nos para-lamas
## (`lamp_at`) e os para-lamas saltados (`fenders`); a picape, a caçamba (`bed`); o caminhão, o baú (`box`, na cor
## `box_col`).
const CAR_KINDS := {
	"fusca": {"weight": 4.0, "pitch": 1.1, "len": 4.05, "wide": 1.55, "belt": 0.86, "lamp": 0.66, "lamp_at": 0.22, "fenders": true,
		"body": [Vector2(0, 0.3), Vector2(0, 0.5), Vector2(0.06, 0.62), Vector2(0.2, 0.74), Vector2(0.5, 0.82), Vector2(0.95, 0.86),
			Vector2(3.0, 0.88), Vector2(3.45, 0.82), Vector2(3.8, 0.7), Vector2(3.98, 0.55), Vector2(4.05, 0.42), Vector2(4.05, 0.3)],
		"win": [Vector2(1.0, 0.9), Vector2(1.32, 1.34), Vector2(1.55, 1.43), Vector2(2.35, 1.44), Vector2(2.7, 1.3), Vector2(3.0, 0.92)],
		"pillars": [1.95],
		"tops": [Vector3(0.2, 0.95, 0.82), Vector3(1.55, 2.4, 1.48), Vector3(3.1, 3.75, 0.78)],
		"glass": [Vector4(0.95, 0.86, 1.3, 1.4), Vector4(1.3, 1.4, 1.55, 1.48)],
		"slopes": [Vector4(0.0, 0.78, 0.2, 0.82), Vector4(2.4, 1.48, 2.75, 1.36), Vector4(2.75, 1.36, 3.0, 1.1), Vector4(3.0, 1.1, 3.1, 0.78),
			Vector4(3.75, 0.78, 4.05, 0.72)],   # fechando com o capô, a tampa do motor e a frente e a traseira (com degraus, via-se a rua por cima dele)
		"front": 0.78, "back": 0.72, "trim": [0.86], "doors": [2.0], "wheels": [0.7, 3.15], "wheel": 0.32},
	"brasilia": {"weight": 2.0, "pitch": 1.05, "len": 4.0, "wide": 1.6, "belt": 0.85, "lamp": 0.66,
		"body": [Vector2(0, 0.3), Vector2(0, 0.7), Vector2(0.08, 0.82), Vector2(3.95, 0.86), Vector2(4.0, 0.75), Vector2(4.0, 0.3)],
		"win": [Vector2(0.95, 0.88), Vector2(1.45, 1.38), Vector2(3.75, 1.38), Vector2(3.9, 0.88)], "pillars": [2.2, 3.05],
		"tops": [Vector3(0.05, 0.95, 0.82), Vector3(1.45, 3.8, 1.42)], "glass": [Vector4(0.95, 0.84, 1.45, 1.42)],
		"front": 0.82, "back": 1.38, "back_glass": Vector2(0.92, 1.32), "trim": [0.82], "doors": [2.25], "wheels": [0.75, 3.25], "wheel": 0.3},
	"sedan": {"weight": 2.5, "pitch": 0.95, "len": 4.5, "wide": 1.8, "belt": 0.95, "lamp": 0.7,
		"body": [Vector2(0, 0.3), Vector2(0, 0.8), Vector2(0.1, 0.95), Vector2(4.4, 0.95), Vector2(4.5, 0.8), Vector2(4.5, 0.3)],
		"win": [Vector2(1.1, 0.97), Vector2(1.6, 1.43), Vector2(3.2, 1.43), Vector2(3.6, 0.97)], "pillars": [2.35],
		"tops": [Vector3(0.0, 1.1, 0.95), Vector3(1.6, 3.2, 1.45), Vector3(3.6, 4.5, 0.95)],
		"glass": [Vector4(1.1, 0.95, 1.6, 1.45), Vector4(3.6, 0.95, 3.2, 1.45)],
		"front": 0.95, "back": 0.95, "trim": [0.95, 0.4], "doors": [2.3], "wheels": [0.8, 3.6], "wheel": 0.31},
	"perua": {"weight": 1.5, "pitch": 1.0, "len": 4.0, "wide": 1.55, "belt": 1.0, "lamp": 0.72,   # (4,4 por 1,75 e 1,42 de altura, saía larga e baixa)
		"body": [Vector2(0, 0.3), Vector2(0, 0.88), Vector2(0.1, 1.0), Vector2(3.95, 1.0), Vector2(4.0, 0.88), Vector2(4.0, 0.3)],
		"win": [Vector2(0.95, 1.02), Vector2(1.4, 1.57), Vector2(3.85, 1.57), Vector2(3.9, 1.02)], "pillars": [2.1, 3.05],
		"tops": [Vector3(0.0, 0.95, 1.0), Vector3(1.4, 3.9, 1.6)], "glass": [Vector4(0.95, 1.0, 1.4, 1.6)],
		"front": 1.0, "back": 1.6, "back_glass": Vector2(1.05, 1.52), "trim": [1.0], "doors": [2.05], "wheels": [0.72, 3.25], "wheel": 0.32},
	"kombi": {"weight": 1.3, "pitch": 0.9, "len": 4.3, "wide": 1.75, "belt": 1.1, "lamp": 0.8,
		"body": [Vector2(0, 0.3), Vector2(0, 1.85), Vector2(0.12, 1.95), Vector2(4.2, 1.95), Vector2(4.3, 1.8), Vector2(4.3, 0.3)],
		"upper": [Vector2(0, 1.1), Vector2(0, 1.85), Vector2(0.12, 1.95), Vector2(4.2, 1.95), Vector2(4.3, 1.8), Vector2(4.3, 1.1)],
		"win": [Vector2(0.2, 1.15), Vector2(0.2, 1.75), Vector2(4.1, 1.75), Vector2(4.1, 1.15)], "pillars": [1.1, 2.0, 3.0],
		"tops": [Vector3(0.1, 4.2, 1.95)], "glass": [],
		"front": 1.9, "front_glass": Vector2(1.2, 1.75), "back": 1.85, "trim": [1.1], "doors": [1.15], "wheels": [0.6, 3.0], "wheel": 0.3},
	"picape": {"weight": 1.2, "pitch": 0.85, "len": 4.9, "wide": 1.9, "belt": 1.05, "lamp": 0.8,
		"body": [Vector2(0, 0.4), Vector2(0, 0.95), Vector2(0.1, 1.05), Vector2(4.85, 1.05), Vector2(4.9, 0.95), Vector2(4.9, 0.4)],
		"cab": [Vector2(1.5, 1.05), Vector2(1.85, 1.75), Vector2(2.65, 1.75), Vector2(2.65, 1.05)],
		"win": [Vector2(1.62, 1.08), Vector2(1.9, 1.68), Vector2(2.55, 1.68), Vector2(2.55, 1.08)], "pillars": [],
		"tops": [Vector3(0.0, 1.5, 1.05), Vector3(1.85, 2.65, 1.75)], "glass": [Vector4(1.5, 1.05, 1.85, 1.75)], "bed": Vector2(2.75, 4.85),
		"front": 1.05, "back": 1.05, "trim": [0.75], "doors": [2.6], "wheels": [0.95, 3.95], "wheel": 0.38},
	"caminhao": {"weight": 0.4, "pitch": 0.7, "len": 6.5, "wide": 2.2, "belt": 1.4, "lamp": 0.95,
		"body": [Vector2(0, 0.5), Vector2(0, 1.25), Vector2(0.15, 1.32), Vector2(1.4, 1.38), Vector2(1.4, 1.1), Vector2(6.5, 1.1), Vector2(6.5, 0.5)],
		"cab": [Vector2(1.4, 1.1), Vector2(1.4, 1.4), Vector2(1.6, 2.3), Vector2(2.8, 2.3), Vector2(2.8, 1.1)],
		"box": [Vector2(2.95, 1.05), Vector2(2.95, 3.0), Vector2(6.5, 3.0), Vector2(6.5, 1.05)], "box_col": Color("3e3a30"),
		"win": [Vector2(1.55, 1.45), Vector2(1.7, 2.15), Vector2(2.6, 2.15), Vector2(2.6, 1.45)], "pillars": [],
		"tops": [Vector3(0.0, 1.4, 1.32), Vector3(1.6, 2.8, 2.3), Vector3(2.95, 6.5, 3.0)], "glass": [Vector4(1.4, 1.4, 1.6, 2.28)],
		"front": 1.32, "back": 3.0, "trim": [], "doors": [2.55], "wheels": [1.0, 5.3], "wheel": 0.48},
	# o ônibus da linha da cidade: nunca sorteado, passa nos horários dele (`Background.BUS_TIMES`), mais devagar (`sec`)
	"onibus": {"weight": 0.0, "sec": 5.0, "pitch": 0.62, "len": 10.5, "wide": 2.5, "belt": 1.5, "lamp": 0.9,
		"body": [Vector2(0, 0.35), Vector2(0, 2.95), Vector2(0.2, 3.1), Vector2(10.3, 3.1), Vector2(10.5, 2.95), Vector2(10.5, 0.35)],
		"upper": [Vector2(0, 1.55), Vector2(0, 2.95), Vector2(0.2, 3.1), Vector2(10.3, 3.1), Vector2(10.5, 2.95), Vector2(10.5, 1.55)],
		"win": [Vector2(0.9, 1.65), Vector2(0.9, 2.7), Vector2(10.1, 2.7), Vector2(10.1, 1.65)], "pillars": [2.15, 3.4, 4.65, 5.9, 7.15, 8.4],
		"tops": [Vector3(0.1, 10.4, 3.1)], "glass": [],
		"front": 3.0, "front_glass": Vector2(1.5, 2.75), "back": 2.95, "trim": [1.5], "doors": [1.0, 5.6], "wheels": [2.0, 8.3], "wheel": 0.5},
}
## As cores dos carros, de noite (escurecidas): azul, vinho, bege, verde, branco, cinza, mostarda.
const CAR_COLORS := [Color("1b2530"), Color("2e1816"), Color("35312a"), Color("18261d"), Color("3c403f"), Color("222228"), Color("362b16")]
const CAR_UPPER := Color("4a4c48")   ## a parte de cima da Kombi, clara
const CAR_SKY := Color("2a3440")   ## o céu refletido no teto e no capô (de noite, a luz que vem de cima)
const CAR_SHEEN := 2.4   ## até onde (m ao longo da rua) a luz de um poste corre pela lataria
const CAR_WET := 1.6   ## na chuva, a lataria molhada: a luz dos postes nela mais forte e mais espalhada
const TAXI := 0.15   ## dos Fuscas e sedãs, quantos são táxi (com a placa acesa no teto)
const TAXI_KINDS := ["fusca", "sedan"]
const CAR_HEAD := Color("fff1c8")   ## os faróis
const TAXI_SIGN := Color("f0d88a")   ## a placa acesa do táxi
const CAR_SPRAY := 14   ## os pontos do borrifo atrás de cada roda, na chuva
const CAR_TAIL := Color("8a1e14")   ## as lanternas
const CANYON_WIN := Vector2(2.6, 0.5)   ## as janelas das paredes da rua do cruzamento: de quantos em quantos metros e quantas acesas
const BEAM := 5.0   ## até onde vai o facho dos faróis no asfalto (m)
## Quanto da profundidade do carro (a largura dele, de um lado ao outro da mão) entra no recuo para o ponto de fuga: a
## vista é grande-angular, e longe do meio o carro se inclinava tanto que parecia ter metade da largura do comprimento.
const CAR_DEPTH := 0.4
## O arbusto plantado junto da nossa parede, embaixo da janela: é do primeiro plano, como a janela, e fica no plano da
## parede dela (não na vista). O meio e a meia largura (fração da largura do vão) e quanto a copa sobe acima do
## peitoril (fração da altura).
const SHRUB := Vector3(0.62, 0.15, 0.11)
const HEDGE := 110   ## as folhas da cerca viva embaixo dela, até o batente de perto (sem ela, sobrava a rua vazia entre a copa e o peitoril)
## As rajadas de vento no arbusto: as duas ondas lentas que as fazem (rad/s) e quanto elas empurram a copa para a
## esquerda (px da tela no alto dela).
const GUST := Vector3(0.23, 0.071, 2.5)
const MOON_BIG := 1.6     ## a lua no horizonte, maior (a ilusão da lua no horizonte); volta a 1 ao subir
const MOON_SHRINK := 0.4  ## até onde da subida (`_moon_t`) ela ainda está encolhendo
## Na névoa, a lua espalhada: o raio do clarão em volta (vezes o halo de sempre), a força dele, a do miolo e a do
## disco (quase apagado).
const FOG_MOON := Vector4(6.0, 0.3, 0.55, 0.3)
const OVERCAST := 14      ## as nuvens do céu da chuva (`_draw_overcast`)
const OVERCAST_SPEED := 0.012
const CHURCH_K := 0.32    ## a escala da igreja (desenhada em px de 2x2), no fim da rua do cruzamento (na distância focal, `OUT_F`)
const SIGN_RED := Color("ff4a3a")    ## o neon dele aceso (apagado, quase preto)
const FOG := Color(0.55, 0.62, 0.66)   ## a cor da névoa (`_draw_fog`)
const FOG_VEIL := 0.2    ## o véu dela por cima de tudo lá fora (o longe some nele)
const FOG_GROUND := 0.2  ## o tanto a mais rente ao chão, sumindo até 3 m de altura
const FOG_WISPS := 9     ## os fiapos passando pela rua
## O peitoril (cm abaixo dos olhos): uns 24 cm acima do tampo, como numa sala de verdade (desce pouco: a parede fica a
## uns 70 cm da cabeça). Com os olhos acima da tela e o peitoril 38 cm abaixo deles, a janela descia uns 40° e parecia
## vista de cima.
const WIN_SILL := 39.0
const WALL_D := 16.0        ## a espessura da parede (para fora, nas unidades da parede do fundo): o vidro fica do lado de fora

var _spray_rng := RandomNumberGenerator.new()   # o sorteio do borrifo dos pneus (`_spray`), sem criar um a cada quadro
var flick := false
var lamp_level := 1.0
var warm := 1.0   ## o quanto a luminária já esquentou (0..1, `warm_up`): o Main tinge o brilho dela de laranja até chegar a 1
var stranger := Vector2(INF, INF)   ## quando o homem do mistério para embaixo do poste e quando vai embora (min do dia; o Main atualiza)
var _drops: Array = []   # pingos caindo: Vector3(x, y em frações da vista, perto: 0 = longe, 1 = perto)
var _beads: Array = []   # gotas paradas no vidro: Vector4(x, y em frações do vidro à vista, tamanho, velocidade; 0 = parada)
var _moon_tex := {}   # a lua na fase da noite (`_moon_art`), por tamanho, guardada pela idade (`_moon_for`)
var _moon_for := -1.0
var _fog_moon := Vector4.ZERO   # na névoa, onde está a lua (x, y), o diâmetro e o quanto ela brilha: o clarão vai por cima do véu
var _glass_from := 0.6   # de que fração da altura da vista o vidro aparece (acima: fora da tela ou atrás da persiana)
var _stars: Array[Vector2] = []
var _houses: Array = []        # os prédios do outro lado da rua, de frente: {x0, x1, h, col, brick, wins: [Vector3(x, andar, hora de apagar)]} (m)
var _canyon: Array = []        # as paredes da rua do cruzamento: {x, z0, z1, h, col, wins: [Vector3(z, altura, hora de apagar)]} (m)
var _city: Array = []          # a cidade no fundo: {x, w, h, row, lit: [Vector3...]} (px do vidro; z: o minuto em que a janela apaga)
var _city_for := Vector2.ZERO  # tamanho do vidro para o qual `_city` foi montada
var _view_at := Vector2.ZERO   # onde a vista começa na tela (px de 2x2): o arbusto é posto pela parede da sala
var _out_x := 38.0   # o ponto de fuga lá fora, a partir da esquerda da vista (px de 2x2; `OUT_AT`)
var _car_z := 0.0   # desenhando um carro: o meio da mão dele (m), onde a profundidade se encolhe (`CAR_DEPTH`); 0 = fora dele
var _near := 0.0         # a vista passa do peitoril de longe para baixo (px de 2x2): a parte de perto da janela, mais alta na tela, mostra a calçada embaixo dela
var _cars: Array[Dictionary] = []   # os carros passando lá fora: {"t": de 0 a 1, "lane": em `CAR_LANES`, "kind": em `CAR_KINDS`, "col", "taxi"}
var _walkers: Array = []   # quem está passando na calçada de lá (`_walker`), na ordem do desenho: os de mais longe primeiro
var _bar_t := -1.0   # há quanto tempo a porta do bar abriu (s; -1 = fechada)
var _smoke_t := -1.0   # há quanto tempo alguém saiu para fumar na varanda (s; -1 = ninguém)
var _cat_for := -1     # a noite do `_cat_plan`
var _cat_plan := Vector4.ZERO   # o gato desta noite: x 1 se vier, y onde (0 marquise, 1 gradil), de z a w (min do dia)
var cat_here := false  ## o gato aparece já, a noite toda (a captura de tela)
var phones := [0, 0]   ## o estado dos telefones de `CALLED`: 0 quieto, 1 tocando (alguém vai atender), 2 na linha
var _phone_seen := [0, 0]
var _phone_from := [0, 0]   # o estado de antes (saindo do telefone, a pessoa vai embora)
var _phone_at := [0.0, 0.0]   # quando o estado mudou (s)


## A vista: céu do clima, morros ao fundo, casas e a igreja com o relógio aceso, a rua com o poste (a silhueta do
## mistério fica contra a luz dele) e, na chuva, o chão molhado refletindo as luzes.
func _draw_city(g: Rect2) -> void:
	var wx := g.position.x
	var wy := g.position.y
	var ww := g.size.x
	var wh := g.size.y
	var fog := weather == "fog"
	var hzy := _hz(g)
	var sky: Color = (Pal.SKY.get(weather, Pal.SKY["rain"]) as Color).lerp(Pal.FLASH, _flash())   # o relâmpago clareia o céu
	_r(wx, wy, ww, wh, sky)
	var hz := sky.lightened(0.12)   # o céu clareia perto do horizonte, liso (em faixas, pareciam camadas)
	_fill(PackedVector2Array([Vector2(wx, hzy - 50), Vector2(wx + ww, hzy - 50), Vector2(wx + ww, hzy), Vector2(wx, hzy)]),
		PackedColorArray([sky, sky, hz, hz]))
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			_r(wx + floorf(s.x * ww), wy + floorf(s.y * (hzy - wy)), PX, PX, Pal.STARS[1] if sin(tw + i * 1.7) > -0.6 else Pal.STARS[0])
		_draw_moon(g, sky, hzy)
	elif weather == "fog":
		_draw_moon(g, sky, hzy)   # difusa: a névoa espalha a luz dela
	elif weather == "rain":
		_draw_overcast(g, sky, hzy)
	if hzy - wy < 40.0:   # (a tela ainda não se arrumou: o vidro ainda não tem o tamanho dele)
		return
	if _city_for != g.size:
		_build_city(g.size)
	var house := Pal.CITY_FAR[1] if fog else Pal.CITY_FAR[0]
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
				_r(wx + b["x"] + p.x, base - b["h"] + p.y, PX, PX, (Pal.CITY_LIT[int(p.x + p.y) % Pal.CITY_LIT.size()] as Color).lerp(hz, haze * 0.7))
	_draw_church(_church_pos(g), house.lerp(hz, 0.25))
	# o chão (a rua do cruzamento indo embora, a rua passando na frente, as calçadas e os meios-fios), as luzes nele
	_draw_street(g, hz)
	if weather == "rain":
		_draw_wet(g)
	# o outro lado: as paredes da rua do cruzamento (de longe para perto) e as fachadas de frente, apoiadas na calçada
	var taken := {}   # os pixels das janelas finas já acesos
	for i in range(_canyon.size() - 1, -1, -1):
		_draw_canyon_wall(g, _canyon[i], hz, taken)
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


## A lua da noite limpa subindo (`_moon_at`, `MOON_RISE`): nasce atrás da igreja, grande e alaranjada no horizonte
## (a ilusão da lua no horizonte, `MOON_BIG`, e o ar mais grosso avermelhando), e diminui até o tamanho dela ao subir,
## até sumir atrás da persiana. Com o halo e as nuvens passando devagar (`_clouds`): manchas lisas, um pouco mais
## claras que o céu (a cidade as ilumina por baixo), mais claras na beira quando estão na frente da lua; coberta, a lua
## e o halo escurecem (`_moon_light`). Desenhada antes da cidade, que a cobre no horizonte.
func _draw_moon(g: Rect2, sky: Color, hzy: float) -> void:
	var top := g.position.y + (g.size.y + _near) * _glass_from
	var sh := hzy - top
	var light := _moon_light()
	_moon_x0 = (_church_pos(g).x - g.position.x) / g.size.x
	var pos := _moon_at()
	var moon := Vector2(g.position.x + g.size.x * pos.x, lerpf(top, hzy, pos.y))   # (sem prender à grade de 2x2: ela anda 1 px por vez)
	var low := 1.0 - smoothstep(0.0, MOON_SHRINK, _moon_t())   # 1 no horizonte, 0 já no alto
	var d := int(roundf(14.0 * lerpf(1.0, MOON_BIG, low)))   # o diâmetro (px da tela), encolhendo 1 px por vez
	var fog := weather == "fog"
	_fog_moon = Vector4.ZERO
	var shine := 0.3 + 0.7 * _moon_lit()
	var tone := Color(0.75, 0.78, 0.7).lerp(Pal.MOON_LOW, low)
	if moon.y * 2.0 + d / 2.0 > top * 2.0:   # (acima disso, já atrás da persiana)
		if fog:   # o clarão espalhado na névoa vai por cima do véu dela (`_draw_fog`, `_fog_moon`)
			_fog_moon = Vector4(moon.x, moon.y, d, shine)
		else:
			_light_fan(moon, _ring(moon, 16.0 * d / 14.0), Color(tone, 0.16 * light * shine))
		_ci.draw_set_transform(Vector2.ZERO)   # a lua em pixel art, em px da tela, na fase da noite (`_moon_art`)
		var col := Pal.MOON.lerp(Pal.MOON_LOW, low).lerp(sky, (1.0 - light) * 0.6)
		PixelArt.sprite(_ci, _moon_art(_moon_age(), d), (moon * 2.0).round(), Color(col.lerp(tone, 0.4), FOG_MOON.w) if fog else col)
		_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	if fog:
		return
	for c in _clouds:
		var at := Vector2(g.position.x + _cloud_x(c) * g.size.x, top + c.y * sh)
		var r := Vector2(0.16 * c.z * g.size.x, 0.09 * c.z * sh)
		var lit := 1.0 - smoothstep(0.0, 1.6, ((at - moon) / r).length())   # na frente da lua, a beira pega a luz dela
		var col := sky.lightened(0.1).lerp(Pal.CLOUD_RIM, 0.12 * lit * light)
		for k in 3:   # três manchas juntas, a do meio maior
			var o := at + Vector2((k - 1) * r.x * 0.55, (k % 2) * -r.y * 0.25)
			var rim := PackedVector2Array()
			for i in 12:
				rim.append(o + Vector2(cos(TAU * i / 12.0) * r.x * (0.9 if k == 1 else 0.6), sin(TAU * i / 12.0) * r.y * (1.0 if k == 1 else 0.7)))
			_light_fan(o, rim, Color(col, 0.85))


## O céu da chuva, nublado: nuvens grandes e lisas cobrindo tudo, passando com o vento (`OVERCAST_SPEED`), clareadas
## por baixo pela luz da cidade (mais perto do horizonte, `Pal.OVERCAST_LIT`), com vãos mais escuros entre elas
## (`Pal.OVERCAST_DARK`), e acesas pelo relâmpago (`_flash`). Sorteadas pelo índice, sempre as mesmas.
func _draw_overcast(g: Rect2, sky: Color, hzy: float) -> void:
	var top := g.position.y + (g.size.y + _near) * _glass_from
	var sh := hzy - top
	var flash := _flash()
	var deck := Pal.OVERCAST_DECK.lerp(Pal.FLASH, flash * 0.6)   # o fundo: o céu inteiro coberto, clareando para o horizonte
	var deck_low := Pal.OVERCAST_LIT.lerp(Pal.FLASH, flash * 0.6)
	_fill(PackedVector2Array([Vector2(g.position.x, g.position.y), Vector2(g.end.x, g.position.y), Vector2(g.end.x, hzy), Vector2(g.position.x, hzy)]),
		PackedColorArray([deck, deck, deck_low, deck_low]))
	for k in OVERCAST:
		var y := fmod(k * 0.618, 1.0) * 1.1 - 0.1   # (fração do céu à vista; as de cima passam da persiana)
		var at := Vector2(g.position.x + _overcast_x(k) * g.size.x, top + y * sh)
		var r := Vector2((0.22 + fmod(k * 0.37, 1.0) * 0.2) * g.size.x, (0.12 + fmod(k * 0.71, 1.0) * 0.1) * sh)
		var col := Pal.OVERCAST_DARK if k % 3 == 0 else Pal.OVERCAST_DECK.lerp(Pal.OVERCAST_LIT, clampf(y, 0.0, 1.0)).lightened(0.12)
		col = col.lerp(Pal.FLASH, flash * (0.0 if k % 3 == 0 else 0.7))
		var rim := PackedVector2Array()
		for i in 16:
			rim.append(at + Vector2(cos(TAU * i / 16.0) * r.x, sin(TAU * i / 16.0) * r.y))
		_light_fan(at, rim, Color(col, 0.8))


## Onde está a nuvem `k` do céu nublado (fração do vidro), andando com o vento.
func _overcast_x(k: int) -> float:
	return fposmod(fmod(k * 0.53, 1.0) * 1.6 - _mist / 3.6 * OVERCAST_SPEED, 1.6) - 0.3


## A lua na fase dela (`age`: dias desde a lua nova) e no diâmetro `size`, pixel a pixel e guardada: a parte acesa
## vai até o terminador (a meia elipse que separa a luz da sombra), a beira um pouco mais escura e o lado apagado bem
## fraco (a luz da Terra).
## No hemisfério sul a crescente tem a luz à esquerda e a minguante à direita (o contrário do norte).
func _moon_art(age: float, size: int) -> Texture2D:
	var key := snappedf(age, 0.25)
	if key != _moon_for:   # outra noite: os tamanhos guardados eram de outra fase
		_moon_for = key
		_moon_tex.clear()
	if _moon_tex.has(size):
		return _moon_tex[size]
	var c := cos(TAU * key / SYNODIC)
	var waxing := key < SYNODIC / 2.0
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) / (size / 2.0) - Vector2.ONE
			if p.length() > 1.0:
				continue
			var s := sqrt(1.0 - p.y * p.y)
			var u := -p.x   # (espelhado: hemisfério sul)
			var on := u > s * c if waxing else u < -s * c
			img.set_pixel(x, y, Color.WHITE.darkened(0.22 * p.length_squared()) if on else Color(1, 1, 1, 0.07))
	_moon_tex[size] = ImageTexture.create_from_image(img)
	return _moon_tex[size]


## A frente da vista, por cima da de trás (`_draw_city`) e redesenhada a cada quadro dela: o letreiro (o T falha
## sozinho), quem passa, os postes, o homem, o carro (na chuva, com o farol espelhado na rua) e a névoa.
func _draw_city_front(g: Rect2) -> void:
	if _hz(g) - g.position.y < 40.0:   # (a tela ainda não se arrumou: o vidro ainda não tem o tamanho dele)
		return
	_draw_hotel_sign(_hotel_pos(g))
	_draw_balcony_front(g)
	_draw_bar_door(g)
	_draw_phones(g)
	_draw_cat(g)
	_draw_guest(g)
	for w: Dictionary in _walkers:   # passam atrás dos postes e do homem
		_draw_walker(g, w)
	for x: float in FAR_LAMPS:
		_draw_lamp_post(g, x, STREET["far_curb"] + 0.4)
	if weather == "clear" and lamp_level > 0.5:
		_draw_moths(g)
	var mx := _man_x()
	if not is_nan(mx):
		_draw_stranger(g, mx)
	_cars.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["lane"] < b["lane"])   # o de lá primeiro
	for c in _cars:
		if weather == "rain":
			_draw_wet(g, c)
		_car_z = CAR_LANES[c["lane"]].x
		_draw_car(g, c)
		_car_z = 0.0
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
	if _fog_moon.z > 0.0:   # a lua na névoa: a luz dela espalhada num clarão largo e liso, mais forte no meio
		var m := Vector2(_fog_moon.x, _fog_moon.y)
		var tone := Color(0.8, 0.82, 0.76)
		_light_fan(m, _ring(m, 16.0 * _fog_moon.z / 14.0 * FOG_MOON.x), Color(tone, FOG_MOON.y * _fog_moon.w))
		_light_fan(m, _ring(m, 9.0 * _fog_moon.z / 14.0), Color(tone.lightened(0.4), FOG_MOON.z * _fog_moon.w))
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


## O horizonte da vista `g` (a altura dos olhos, descida em `OUT_DROP`).
func _hz(g: Rect2) -> float:
	return g.position.y + _vp.y + _cm(OUT_DROP) - _view_at.y


## Um ponto lá fora na vista `g`: `x` m ao longo da rua (a partir da frente da janela), a `z` m dos olhos e `h` m acima
## da rua. A câmera olha de frente para a rua: a linha que vai para longe foge para o meio do horizonte.
func _o(g: Rect2, x: float, z: float, h := 0.0) -> Vector2:
	z = maxf(0.3, z)
	var zx := z if _car_z == 0.0 else _car_z + (z - _car_z) * CAR_DEPTH
	return Vector2(g.position.x + _out_x + OUT_F * x / zx, _hz(g) + OUT_F * (OUT_EYE - h) / z)


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
	if c.has("stop"):
		return _taxi_x(c)
	var d: float = CAR_LANES[c["lane"]].y
	return lerpf(16.0, -21.0 - maxf(0.0, CAR_KINDS[c["kind"]]["len"] - 4.5), c["t"]) * -d   # (o comprido sai inteiro da vista)


## Onde está a frente do táxi que para no hotel (`c`, com "stop"; x, m), pelos segundos dele (`s`): chegando,
## freando; parado com o meio na porta; saindo, acelerando (`TAXI_STOP`).
func _taxi_x(c: Dictionary) -> float:
	var stop: float = _taxi_mid() - CAR_KINDS[c["kind"]]["len"] / 2.0   # (a frente vai para a esquerda)
	var s: float = c["s"]
	if s < TAXI_STOP.x:
		var u := 1.0 - s / TAXI_STOP.x
		return lerpf(stop, 16.0, u * u)
	s -= TAXI_STOP.x + TAXI_STOP.y
	if s < 0.0:
		return stop
	var u := s / TAXI_STOP.z
	return lerpf(stop, -21.0, u * u)


## Onde o meio do táxi parado fica (x, m): um pouco antes da porta do hotel, vista daqui (mais perto, o x que cai nela
## é menor: tudo vai para o ponto de fuga); na frente dela, metade dele ficava atrás do montante da janela.
func _taxi_mid() -> float:
	return (HOTEL_X - 1.4) * CAR_LANES[0].x / STREET["far"]


## O chão: a rua do cruzamento indo embora (com as calçadas e os postes dela, menores com a distância), a nossa calçada
## de lajotas até o meio-fio, o asfalto da rua (manchas, desgaste dos pneus nas duas mãos, grão perto, poças espelhando o
## céu, a faixa tracejada no meio e a faixa de pedestres na boca do cruzamento), o meio-fio de lá com a face virada para
## nós, a calçada de lá e a luz dos postes no chão. Tudo no mesmo plano horizontal; só a perspectiva inclina as linhas
## que vão para longe.
func _draw_street(g: Rect2, hz: Color) -> void:
	var fog := weather == "fog"
	var asphalt := Pal.ASPHALT[1] if fog else Pal.ASPHALT[0]
	var walk := Pal.SIDEWALK[1] if fog else Pal.SIDEWALK[0]
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
			_r(foot.x, head.y, PX, foot.y - head.y, Pal.LAMP_POST.lerp(hz, 1.0 - near))
			if lamp_level > 0.5:
				_r(head.x - PX, head.y - PX, maxf(PX, 1.5 * near), maxf(PX, near), Pal.STREET_LAMP.lerp(hz, (1.0 - near) * 0.6))
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
	var wet := 1.0 + 1.6 * _soaked() if weather == "rain" else 1.0   # as poças crescem com a noite de chuva
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
		_poly(PackedVector2Array([_o(g, seg.x, fc), _o(g, seg.y, fc), _o(g, seg.y, fc, 0.15), _o(g, seg.x, fc, 0.15)]), Pal.CURB[0])
		_ci.draw_line(_o(g, seg.x, fc, 0.15), _o(g, seg.y, fc, 0.15), Pal.CURB[1], PX)
	if lamp_level > 0.5:   # a luz de cada poste de lá no chão, em volta do pé dele
		for x: float in FAR_LAMPS:
			var c := _o(g, x, fc - 0.2)
			var rim := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				rim.append(_o(g, x + cos(a) * 4.5, fc - 0.2 + sin(a) * 3.0))
			_light_fan(c, rim, Color(1.0, 0.85, 0.55, 0.28))


## A chuva no chão: o asfalto molhado espelha as luzes em riscos verticais, quebrados, embaixo de cada uma (os postes
## e o letreiro; com `car`, só o farol e a lanterna daquele carro, que anda: vai na frente da vista), mais fracos para
## baixo.
func _draw_wet(g: Rect2, car: Dictionary = {}) -> void:
	var lights := []   # [cabeça, pé, cor]
	if not car.is_empty():
		var z: float = CAR_LANES[car["lane"]].x
		var m: Dictionary = CAR_KINDS[car["kind"]]
		var rear: float = _car_x(car) - CAR_LANES[car["lane"]].y * m["len"]
		lights.append([_o(g, _car_x(car), z - 0.9, m["lamp"]), _o(g, _car_x(car), z - 1.2), CAR_HEAD])
		lights.append([_o(g, rear, z - 0.9, m["lamp"]), _o(g, rear, z - 1.2), CAR_TAIL.lightened(0.3)])
	else:
		if lamp_level > 0.5:
			for i in FAR_LAMPS.size():
				lights.append([_lamp_heads(g)[i], _o(g, FAR_LAMPS[i], STREET["far_curb"] - 0.5), Color(1.0, 0.85, 0.55)])
		if _sign_on():   # embaixo das letras (o meio delas fica 2,25 px de 2x2 dentro da caixa; o risco tem 1,5 de largura)
			var s := _hotel_pos(g) + Vector2(2.25, 0.0)
			lights.append([s, Vector2(s.x - 0.75, _o(g, HOTEL_X, STREET["far_curb"] - 0.5).y), SIGN_RED])
	for l: Array in lights:
		_wet_streak(l[0], l[1], l[2])


## O reflexo da luz `col` (que fica em `head`) no asfalto molhado, um risco vertical quebrado descendo de `foot`.
func _wet_streak(head: Vector2, foot: Vector2, col: Color) -> void:
	var length := (foot.y - head.y) * 0.9
	var n := maxi(3, int(length / 1.5))
	for k in n:
		if k % 3 == 2:
			continue   # quebrado pelas poças e pelos pingos
		_r(foot.x - PX * (k % 2), foot.y + length * k / n, maxf(PX, 1.5 - k * 0.05), PX, Color(col, 0.32 * (1.0 - float(k) / n)))


## Uma parede da rua do cruzamento (`w`: o lado `x`, de `z0` a `z1`, `h` m), indo embora para o ponto de fuga, com
## janelas em andares (acesas ou não) e a laje de cada andar. `taken`: os pixels das janelas finas já acesos.
func _draw_canyon_wall(g: Rect2, w: Dictionary, hz: Color, taken: Dictionary) -> void:
	var x: float = w["x"]
	var z0: float = w["z0"]
	var z1: float = w["z1"]
	var ht: float = w["h"]
	var col: Color = (w["col"] as Color).lerp(hz, clampf((z0 - 14.0) / 160.0, 0.0, 0.5))
	_poly(PackedVector2Array([_o(g, x, z0), _o(g, x, z1), _o(g, x, z1, ht), _o(g, x, z0, ht)]), col)
	_ci.draw_line(_o(g, x, z0), _o(g, x, z0, ht), col.darkened(0.4), PX)   # a quina
	_ci.draw_line(_o(g, x, z0, ht), _o(g, x, z1, ht), col.lightened(0.12), PX)   # a cornija
	for f in range(1, int((ht - 0.8) / 3.2)):   # a laje de cada andar, fugindo para o ponto de fuga com as janelas
		_ci.draw_line(_o(g, x, z0, f * 3.2), _o(g, x, z1, f * 3.2), col.lightened(0.06), PX)
	var dark := col.darkened(0.5)
	for wv: Vector3 in w["wins"]:   # (z do meio, altura do peitoril, hora de apagar), 1 m por 1,4 m
		var lit := wv.z > minutes
		var a := _o(g, x, wv.x - 0.5, wv.y + 1.4)
		var b := _o(g, x, wv.x + 0.5, wv.y)
		var col_w: Color = Pal.CITY_LIT[int(wv.x) % Pal.CITY_LIT.size()] if lit else dark
		if absf(b.x - a.x) >= PX:
			_poly(PackedVector2Array([a, _o(g, x, wv.x + 0.5, wv.y + 1.4), b, _o(g, x, wv.x - 0.5, wv.y)]), col_w)
		elif lit:   # mais fina que um pixel: 1 px, com um vazio ao lado (juntas, as de longe viravam um borrão amarelo)
			var at := Vector2i(floori(a.x), floori(wv.y / 3.2))   # (px de 2x2: um vazio de 1 px da tela entre elas)
			if not taken.has(at):
				taken[at] = true
				_r(roundf(a.x * 2.0) / 2.0, a.y, PX, maxf(PX, b.y - a.y), col_w)


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
	var wake: Dictionary = b["wake"]
	for j in b["wins"].size():   # (x do meio, andar, hora de apagar; -1: apagada)
		var wv: Vector3 = b["wins"][j]
		var ground := wv.y == 0.0
		var w := (1.8 if ground else 1.2) * k
		var top := _o(g, wv.x, ff, 2.6 if ground else wv.y * 3.2 + 2.5)
		var h := (2.6 if ground else 1.5) * k
		var p := Vector2(top.x - w / 2.0, top.y)
		_r(p.x - PX, p.y - PX, w + PX * 2.0, h + PX, col.darkened(0.55))   # o vão
		var woke: Vector2 = wake.get(j, Vector2.ZERO)
		if wv.z > minutes or (minutes >= woke.x and minutes < woke.y):
			var lc: Color = Pal.CITY_LIT[int(wv.x + wv.y) % Pal.CITY_LIT.size()]
			_r(p.x, p.y, w, h, lc)
			_r(p.x, p.y + h * 0.45, w, PX, lc.darkened(0.45))   # a travessa
			_r(p.x, p.y, w * 0.3, h, lc.darkened(0.25))   # a cortina
			_r(p.x, p.y, w, maxf(PX, 0.15 * k), lc.darkened(0.5))   # a sombra da verga: a janela é funda
		else:
			_r(p.x, p.y, w, h, Pal.WINDOW_DARK)
			_r(p.x, p.y, w, PX, Color(hz, 0.5))   # o reflexo da rua no vidro
		if not ground:
			_r(p.x - PX * 2.0, p.y + h, w + PX * 4.0, PX, col.lightened(0.25))   # o peitoril, saindo da parede, e a sombra dele
			_r(p.x - PX, p.y + h + PX, w + PX * 2.0, PX, col.darkened(0.35))
			_r(p.x - PX * 2.0, p.y - PX * 2.0, w + PX * 4.0, PX, col.darkened(0.3))   # a verga
	if b["brick"]:
		_draw_balcony_back(g, col)


## A vitrine acesa de um bar no térreo do prédio de tijolos, logo atrás do homem (`MAN_X`): ele fica em silhueta contra
## ela. Vidro quente com o caixilho e o letreiro pintado, e a luz dela saindo pela calçada.
func _draw_shopfront(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var x0 := CROSSING.y + 0.5   # (a quina do prédio fica em CROSSING.y: antes, a vitrine passava dela)
	var x1 := CROSSING.y + 2.5   # (com três divisões, encostava na porta)
	var a := _o(g, x0, ff, 2.5)
	var e := _o(g, x1, ff, 0.4)
	_r(a.x - PX, a.y - PX, e.x - a.x + 1, e.y - a.y + 1, Pal.BAR_JAMB)
	_fill(PackedVector2Array([a, Vector2(e.x, a.y), e, Vector2(a.x, e.y)]),
		PackedColorArray([Pal.BAR_LIGHT[0], Pal.BAR_LIGHT[0], Pal.BAR_LIGHT[1], Pal.BAR_LIGHT[1]]))
	_r(lerpf(a.x, e.x, 0.5), a.y, PX, e.y - a.y, Pal.BAR_WOOD)   # o caixilho
	_r(a.x, lerpf(a.y, e.y, 0.3), e.x - a.x, PX, Pal.BAR_WOOD)
	_r(lerpf(a.x, e.x, 0.12), lerpf(a.y, e.y, 0.12), (e.x - a.x) * 0.5, PX, Pal.BAR_LETTERING)   # o letreiro pintado no vidro
	var c := _o(g, MAN_X, STREET["far_curb"] + 0.3)   # a luz dela na calçada e no meio-fio
	var rim := PackedVector2Array()
	for i in 20:
		var an := TAU * i / 20.0
		rim.append(_o(g, MAN_X + cos(an) * 2.6, ff - 1.2 + sin(an) * 1.6))
	_light_fan(c, rim, Color(1.0, 0.75, 0.4, 0.2))


## Uma silhueta (`parts`: retângulos em metros a partir dos pés, x para o lado e y para cima) em `foot` (px da tela),
## `k` px por metro, na cor `col`, recortada em `clip` (px da tela; vazio = sem recorte).
func _figure(foot: Vector2, k: float, parts: Array, col: Color, clip := Rect2()) -> void:
	for part: Rect2 in parts:
		var a := Vector2(roundf(part.position.x * k), -roundf((part.position.y + part.size.y) * k))
		var b := Vector2(roundf(part.end.x * k), -roundf(part.position.y * k))
		var r := Rect2(foot + a, Vector2(maxf(1.0, b.x - a.x), maxf(1.0, b.y - a.y)))
		if clip.has_area():
			r = r.intersection(clip)
		if r.has_area():
			_p(r.position.x, r.position.y, r.size.x, r.size.y, col)


## As peças de alguém de pé (m, a partir dos pés): andando (as pernas abertas no passo `step` ímpar) ou parado, com o
## braço do lado de `side` levantado até a orelha (`up`: o fone, o cigarro) ou caído.
func _body(step: int, walking: bool, up: bool, side := 1.0) -> Array:
	var parts: Array = [Rect2(-0.2, 0.75, 0.4, 0.68), Rect2(-0.1, 1.43, 0.2, 0.22)]   # o casaco e a cabeça
	if walking and step % 2 == 0:
		parts.append_array([Rect2(-0.22, 0.0, 0.13, 0.8), Rect2(0.09, 0.0, 0.13, 0.8)])
	else:
		parts.append(Rect2(-0.13, 0.0, 0.26, 0.8))
	if up:
		parts.append(Rect2(0.12 * side - 0.04, 1.2, 0.09, 0.42))
	return parts


## Quem atende o telefone do outro lado da rua (`CALLED`, `phones`): enquanto ele toca (só se for atender), a pessoa
## chega até ele; atendido, fica com o fone na orelha enquanto a conversa dura; desligado, vai embora. No hotel, no
## saguão, pela porta acesa embaixo da marquise; no bar, atrás da vitrine, contra a luz do salão.
func _draw_phones(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var now := Time.get_ticks_msec() / 1000.0
	for i in CALLED.size():
		var st: int = phones[i] if i < phones.size() else 0
		if st != _phone_seen[i]:
			_phone_from[i] = _phone_seen[i]
			_phone_seen[i] = st
			_phone_at[i] = now
		var t: float = now - _phone_at[i]
		var away := 0.0   # 0 no telefone, 1 fora da vista, do lado
		if st == 1:
			away = 1.0 - clampf(t / PHONE_WALK, 0.0, 1.0)
		elif st == 0:
			if _phone_from[i] == 0 or t > PHONE_WALK:
				continue
			away = t / PHONE_WALK
		var spot := Vector2(HOTEL_X + 0.15, ff + 1.2) if i == 0 else Vector2(CROSSING.y + 2.1, ff + 1.5)   # o telefone (x na fachada, z lá dentro)
		var clip := Rect2(_o(g, HOTEL_X - 0.6, ff, 2.3) * 2.0, (_o(g, HOTEL_X + 0.6, ff) - _o(g, HOTEL_X - 0.6, ff, 2.3)) * 2.0) if i == 0 \
			else Rect2(_o(g, CROSSING.y + 0.5, ff, 2.5) * 2.0, (_o(g, CROSSING.y + 2.5, ff, 0.4) - _o(g, CROSSING.y + 0.5, ff, 2.5)) * 2.0)
		var x := spot.x * spot.y / ff + away * 1.4   # (lá dentro, o x que cai na porta ou na vitrine: mais longe, tudo vai para o ponto de fuga)
		var foot := (_o(g, x, spot.y) * 2.0).floor()
		var walking := away > 0.0
		var parts := _body(int(t * WALK_STEPS * 2.0), walking, st == 2 and not walking, -1.0)
		_figure(foot, OUT_F / spot.y * 2.0, parts, Color("120a06") if i == 0 else Color(0.17, 0.09, 0.04, 0.9), clip)


## O passageiro do táxi parado no hotel (`_taxi_x`, `GUEST`): desce do lado da calçada, atrás do carro, e anda com a
## mala até a porta acesa embaixo da marquise, sumindo nela. Antes dos carros (o táxi fica na frente dele).
func _draw_guest(g: Rect2) -> void:
	var ff: float = STREET["far"]
	for c in _cars:
		var p: float = c.get("s", 0.0) - TAXI_STOP.x - GUEST.x
		if not c.has("stop") or p < 0.0 or p > GUEST.z:
			continue
		var u := p / GUEST.z
		var z0: float = CAR_LANES[0].x + 1.0   # da porta de trás do táxi, do lado da calçada...
		var z := lerpf(z0, ff + 0.8, u)
		var clip := Rect2()   # passando da fachada, só pela porta
		if z > ff:
			var a := _o(g, HOTEL_X - 0.6, ff, 2.3)
			clip = Rect2(a * 2.0, (_o(g, HOTEL_X + 0.6, ff) - a) * 2.0)
		var parts := _body(int(p * WALK_STEPS * 2.0), true, false)
		parts.append(Rect2(0.2, 0.08, 0.3, 0.34))   # a mala
		var x := lerpf((_taxi_mid() + 0.6) * z0 / CAR_LANES[0].x, HOTEL_X * (ff + 0.8) / ff, u)   # ...até a porta do hotel
		_figure((_o(g, x, z) * 2.0).floor(), OUT_F / z * 2.0, parts, Color("07090c"), clip)


## O vira-lata trotando pela calçada de lá (`w`, de `_walker`, com "dog"; `x` onde está): o desenho do quadro do trote
## (`STRAY_ART`), virado para onde vai, apoiado na calçada; perto de um poste, a beira de cima pega a luz dele.
func _draw_stray(g: Rect2, w: Dictionary, x: float) -> void:
	var foot := (_o(g, x, w["z"]) * 2.0).floor()
	var rows: Array = STRAY_ART[int(w["t"] * w["sec"] * WALK_STEPS * 2.0) % 2]
	var lit := 0.0
	for lx: float in FAR_LAMPS:
		lit = maxf(lit, clampf(1.0 - absf(x - lx) / 3.0, 0.0, 1.0))
	for y in rows.size():
		var row: String = rows[y]
		for i in row.length():
			if row[i] == "#":
				var px := foot.x + (i - 5 if w["dir"] > 0.0 else 4 - i)
				var top := y == 0 or (rows[y - 1] as String)[i] != "#"   # a beira de cima
				_p(px, foot.y - rows.size() + y, 1, 1, STRAY_COAT.lerp(RIM, 0.2 + 0.4 * lit) if top else STRAY_COAT.darkened(0.25 if y > 3 else 0.0))


## As mariposas da noite limpa em volta da luz de cada poste (`MOTHS`): pontos de 1 px voando em voltas tortas, cada uma
## no seu raio e na sua velocidade, as asas piscando na luz.
func _draw_moths(g: Rect2) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var heads := _lamp_heads(g)
	for l in heads.size():
		var c: Vector2 = (heads[l] as Vector2) * 2.0 + Vector2(0, 2)
		for i in MOTHS:
			var ph := i * 1.7 + l * 3.1
			var a := t * (2.0 + i * 0.45) + ph + sin(t * 3.3 + ph) * 0.9
			var r := 5.0 + (i % 3) * 2.5 + sin(t * 1.3 + ph) * 1.5   # (rente à cabeça, sumiam no brilho dela)
			var at := (c + Vector2(cos(a) * r, sin(a * 1.6) * r * 0.6 - 1.0)).round()
			_p(at.x, at.y, 1, 1, Color(MOTH, 0.9 if fmod(t * 11.0 + i * 0.37, 1.0) < 0.6 else 0.45))


## O gato da noite (`_cat_plan`, sorteado pela noite: em metade delas, `CAT_NIGHTS`): sentado de frente na marquise do
## hotel ou no gradil da varanda, os olhos acesos na luz da rua piscando de vez em quando e o rabo mexendo. Uns pixels
## a mais que no tamanho de verdade (com 3 px, não se via que era um gato).
func _draw_cat(g: Rect2) -> void:
	if _cat_for != night:
		_cat_for = night
		var rng := RandomNumberGenerator.new()
		rng.seed = night * 7919 + 13
		var from := 18 * 60 + rng.randf_range(15.0, 220.0)
		_cat_plan = Vector4(1.0 if rng.randf() < CAT_NIGHTS else 0.0, float(rng.randi() % 2), from, from + rng.randf_range(40.0, 110.0))
	if not cat_here and (_cat_plan.x == 0.0 or minutes < _cat_plan.z or minutes > _cat_plan.w):
		return
	var at := _o(g, HOTEL_X + 1.1, STREET["far"] - 0.5, 3.0) if _cat_plan.y == 0.0 \
		else _o(g, APT["x0"] + 0.5, STREET["far"] - APT["deep"], APT["floor"] + 1.05)
	var o := (at * 2.0).floor() - Vector2(2, 5)   # (px da tela: o canto de cima do desenho, sentado em `at`)
	var t := Time.get_ticks_msec() / 1000.0
	var dark := Color("0b0c0f")
	for p: Vector2i in [Vector2i(0, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 2), Vector2i(2, 2),
			Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]:
		_p(o.x + p.x, o.y + p.y, 1, 1, dark)
	var tail := Vector2(4, 4) if fmod(t, 2.4) < 1.6 else Vector2(4, 3)   # o rabo, mexendo de vez em quando
	_p(o.x + tail.x, o.y + tail.y, 1, 1, dark)
	_p(o.x + 5, o.y + tail.y - 1, 1, 1, dark)
	if fmod(t + _cat_plan.z, 4.3) > 0.15:   # os olhos, piscando
		_p(o.x + 1, o.y + 1, 1, 1, CAT_EYES)
		_p(o.x + 2, o.y + 1, 1, 1, CAT_EYES)


## Quem fuma na varanda do apartamento (`_smoke_t`): sai pela porta, anda até o gradil, na frente da janela da TV, e
## fica ali, levando o cigarro à boca a cada `PUFF_EVERY` s (a brasa acende e a fumaça sobe e some), até voltar para
## dentro. Atrás do gradil (desenhado antes dele).
func _draw_smoker(g: Rect2) -> void:
	if _smoke_t < 0.0:
		return
	var dz: float = STREET["far"] - APT["deep"]
	var z := dz + 0.35
	var door: Vector2 = APT["door"]
	var spot := (APT["win"] as Vector2).x + 0.4
	var walk := 2.5
	var away := 1.0 - clampf(minf(_smoke_t, SMOKE_SEC - _smoke_t) / walk, 0.0, 1.0)   # 1 na porta, 0 no gradil
	var x := lerpf(spot, (door.x + door.y) / 2.0, away)
	var k := OUT_F / z * 2.0
	var foot := (_o(g, x, z, APT["floor"]) * 2.0).floor()
	var puff := fmod(_smoke_t, PUFF_EVERY)
	var up := away == 0.0 and puff < 1.2
	_figure(foot, k, _body(int(_smoke_t * WALK_STEPS * 2.0), away > 0.0, up), Color("07090c"))
	var ember := foot + (Vector2(0.14, -1.55) if up else Vector2(0.24, -0.85)) * k
	_p(roundf(ember.x), roundf(ember.y), 1, 1, EMBER if up else EMBER.darkened(0.45))
	_p(roundf(ember.x) - 1, roundf(ember.y) - 1, 3, 3, Color(EMBER, 0.25 if up else 0.1))
	if away == 0.0 and puff > 1.2 and puff < 4.0:   # a fumaça da tragada, subindo devagar e sumindo
		var f := (puff - 1.2) / 2.8
		for j in 3:
			var q := foot + Vector2(0.05 + j * 0.06 + f * 0.25, -1.6 - j * 0.08 - f * 0.5) * k
			_p(roundf(q.x), roundf(q.y), 1, 1, Color(0.7, 0.72, 0.76, 0.35 * (1.0 - f)))


## Quem passa de bicicleta (`w`, de `_walker`, com "bike"; `x` onde está): as rodas, o quadro, o ciclista pedalando
## (as pernas giram com o pé de vela) e a luz fraca do farol na frente. Em px da tela; virado para onde vai.
func _draw_bike(g: Rect2, w: Dictionary, x: float) -> void:
	var z: float = w["z"]
	var k := OUT_F / z * 2.0
	var s: float = w["dir"]
	var foot := (_o(g, x, z) * 2.0).floor()
	var at := func(p: Vector2) -> Vector2: return (foot + Vector2(p.x * s, -p.y) * k).floor()
	var dark := Color("07090c")
	var a: float = w["t"] * w["sec"] * TAU * 1.2   # o pé de vela
	_ci.draw_set_transform(Vector2.ZERO)
	for wx in [-0.5, 0.5]:   # as rodas
		_ci.draw_arc(at.call(Vector2(wx, 0.33)), 0.33 * k, 0.0, TAU, 14, dark, 1.0)
	for seg: Array in [[Vector2(-0.5, 0.33), Vector2(-0.18, 0.85)], [Vector2(-0.18, 0.85), Vector2(0.38, 0.92)], [Vector2(0.38, 0.92), Vector2(0.5, 0.33)],
			[Vector2(0.0, 0.33), Vector2(-0.18, 0.85)], [Vector2(0.0, 0.33), Vector2(0.38, 0.92)]]:   # o quadro
		_ci.draw_line(at.call(seg[0]), at.call(seg[1]), dark, 1.0)
	var hip := Vector2(-0.18, 0.92)
	var shoulder := Vector2(0.12, 1.45)
	_ci.draw_line(at.call(hip), at.call(shoulder), dark, maxf(2.0, 0.3 * k))   # o tronco, inclinado
	_ci.draw_rect(Rect2(at.call(shoulder + Vector2(0.0, 0.25)) - Vector2(0.1, 0.0) * k, Vector2(0.2, 0.22) * k), dark)   # a cabeça
	_ci.draw_line(at.call(shoulder), at.call(Vector2(0.38, 0.95)), dark, maxf(1.0, 0.08 * k))   # o braço
	for ph in [0.0, PI]:   # as pernas, cada uma num pedal
		var pedal := Vector2(0.0, 0.33) + Vector2(cos(a + ph), sin(a + ph)) * 0.17
		_ci.draw_line(at.call(hip), at.call(pedal), dark, maxf(1.0, 0.12 * k))
	var lamp: Vector2 = at.call(Vector2(0.42, 0.9))
	_ci.draw_rect(Rect2(lamp, Vector2.ONE), Color(1.0, 0.9, 0.6, 0.9))
	_light_fan(lamp, _ring(lamp, 0.25 * k), Color(1.0, 0.85, 0.55, 0.1))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## A porta do bar, ao lado da vitrine (`BAR_DOOR`): fechada, a madeira com o vidro aceso no alto; quando alguém sai
## (`_bar_t`), ela abre para dentro, a luz do salão aparece no vão e sai pela calçada, e ela fecha de novo.
func _draw_bar_door(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var a := _o(g, BAR_DOOR.x, ff, 2.2)
	var e := _o(g, BAR_DOOR.y, ff)
	var open := 0.0
	if _bar_t >= 0.0:
		open = clampf(minf(_bar_t, BAR_SEC - _bar_t) / BAR_SWING, 0.0, 1.0)
	_r(a.x - PX, a.y - PX, e.x - a.x + PX * 2.0, e.y - a.y + PX, Pal.BAR_JAMB)   # o batente
	_fill(PackedVector2Array([a, Vector2(e.x, a.y), e, Vector2(a.x, e.y)]),
		PackedColorArray([Pal.BAR_LIGHT[0], Pal.BAR_LIGHT[0], Pal.BAR_LIGHT[1], Pal.BAR_LIGHT[1]]))   # o salão aceso
	var leaf := (e.x - a.x) * (1.0 - open * 0.8)   # a folha girando para dentro, cada vez mais estreita
	_r(a.x, a.y, leaf, e.y - a.y, Pal.BAR_WOOD)
	_r(a.x + leaf * 0.2, a.y + (e.y - a.y) * 0.12, leaf * 0.6, (e.y - a.y) * 0.3, Pal.BAR_GLASS)   # o vidro, com a luz de dentro
	if open > 0.0:   # a luz saindo pela calçada
		var c := _o(g, (BAR_DOOR.x + BAR_DOOR.y) / 2.0, ff - 0.1)
		var rim := PackedVector2Array()
		for i in 20:
			var an := TAU * i / 20.0
			rim.append(_o(g, (BAR_DOOR.x + BAR_DOOR.y) / 2.0 + cos(an) * 1.4, ff - 0.9 + sin(an) * 0.9))
		_light_fan(c, rim, Color(1.0, 0.75, 0.4, 0.3 * open))


## A marquise do hotel sobre a porta (embaixo do letreiro): saindo 1,2 m da fachada, o alto visto de cima (os olhos
## ficam acima), a beira da frente e a luz quente embaixo dela, na porta e na calçada.
func _draw_marquee(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var x0 := HOTEL_X - 1.8
	var x1 := HOTEL_X + 1.8
	var door := _o(g, HOTEL_X - 0.6, ff, 2.3)
	var de := _o(g, HOTEL_X + 0.6, ff)
	_fill(PackedVector2Array([door, Vector2(de.x, door.y), de, Vector2(door.x, de.y)]),
		PackedColorArray([Pal.HOTEL_DOOR[0], Pal.HOTEL_DOOR[0], Pal.HOTEL_DOOR[1], Pal.HOTEL_DOOR[1]]))   # a porta aberta, com a luz do saguão
	var c := _o(g, HOTEL_X, ff - 0.6)
	var rim := PackedVector2Array()
	for i in 20:
		var an := TAU * i / 20.0
		rim.append(_o(g, HOTEL_X + cos(an) * 2.8, ff - 0.8 + sin(an) * 1.4))
	_light_fan(c, rim, Color(1.0, 0.78, 0.45, 0.22))
	var top := PackedVector2Array([_o(g, x0, ff, 3.0), _o(g, x1, ff, 3.0), _o(g, x1, ff - 1.2, 3.0), _o(g, x0, ff - 1.2, 3.0)])
	_poly(top, Pal.MARQUEE[0])
	_poly(PackedVector2Array([top[3], top[2], _o(g, x1, ff - 1.2, 2.75), _o(g, x0, ff - 1.2, 2.75)]), Pal.MARQUEE[1])   # a beira, vermelha
	_ci.draw_line(_o(g, x0, ff - 1.2, 2.75), _o(g, x1, ff - 1.2, 2.75), Color(1.0, 0.8, 0.5, 0.6), PX)   # a luz embaixo dela


## A parte parada da varanda do apartamento no prédio de tijolos (`APT`), na camada de trás: a porta (acesa, com a
## cortina, até `APT_DARK`), o vão da janela da sala (o vidro com a TV é da frente, `_draw_balcony_front`), os vasos de
## planta nos cantos e o lado de baixo da laje, visto de baixo (os olhos ficam abaixo dela).
func _draw_balcony_back(g: Rect2, col: Color) -> void:
	var ff: float = STREET["far"]
	var fl: float = APT["floor"]
	var dz: float = ff - APT["deep"]
	var d: Vector2 = APT["door"]
	var a := _o(g, d.x, ff, fl + 2.3)
	var e := _o(g, d.y, ff, fl + 0.05)
	_r(a.x - PX, a.y - PX, e.x - a.x + PX * 2.0, e.y - a.y + PX, col.darkened(0.55))
	if minutes < APT_DARK:
		var lc: Color = (Pal.CITY_LIT[1] as Color).darkened(0.15)
		_r(a.x, a.y, e.x - a.x, e.y - a.y, lc)
		_r(a.x, a.y, (e.x - a.x) * 0.6, e.y - a.y, lc.darkened(0.3))   # a cortina
	else:
		_r(a.x, a.y, e.x - a.x, e.y - a.y, Pal.WINDOW_DARK)
		_r(a.x, a.y, e.x - a.x, PX, Color(0.5, 0.55, 0.6, 0.3))
	_r((a.x + e.x) / 2.0, a.y, PX, e.y - a.y, col.darkened(0.5))   # as duas folhas
	var w: Vector2 = APT["win"]
	var wa := _o(g, w.x, ff, fl + 2.4)
	var we := _o(g, w.y, ff, fl + 0.9)
	_r(wa.x - PX, wa.y - PX, we.x - wa.x + PX * 2.0, we.y - wa.y + PX, col.darkened(0.55))
	_r(wa.x, wa.y, we.x - wa.x, we.y - wa.y, Pal.WINDOW_DARK)
	_r(wa.x - PX * 2.0, wa.y - PX * 2.0, we.x - wa.x + PX * 4.0, PX, col.darkened(0.3))   # a verga
	for px: float in [APT["x0"] + 0.35, APT["x1"] - 0.4]:   # os vasos, atrás do gradil
		var foot := _o(g, px, dz + 0.3, fl + 0.15)
		var k := OUT_F / (dz + 0.3)
		_r(foot.x - 0.18 * k, foot.y - 0.35 * k, 0.36 * k, 0.35 * k, Pal.BALCONY_POT)
		for i in 7:
			var lx := foot.x + (fposmod(i * 0.37, 1.0) - 0.5) * 0.6 * k
			var ly := foot.y - (0.35 + 0.15 + fposmod(i * 0.61, 1.0) * 0.5) * k
			_r(lx - PX, ly, PX * 3.0, PX * 2.0, Pal.BALCONY_PLANT[0] if i % 2 else Pal.BALCONY_PLANT[1])
	var under := PackedVector2Array([_o(g, APT["x0"], ff, fl), _o(g, APT["x1"], ff, fl), _o(g, APT["x1"], dz, fl), _o(g, APT["x0"], dz, fl)])
	_poly(under, col.darkened(0.65))


## A parte da varanda que muda ou fica na frente, na camada da frente: o vidro da janela da sala com a luz da TV
## piscando (as cenas trocando, `TV_BLUE`; com a luz da sala acesa, mistura com ela; até `TV_OFF`), a beira da laje e o
## gradil de ferro na frente de tudo, que a TV tinge quando a sala está escura.
func _draw_balcony_front(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var fl: float = APT["floor"]
	var dz: float = ff - APT["deep"]
	var tv := Color(0, 0, 0, 0)
	if minutes < TV_OFF:
		var t := Time.get_ticks_msec() / 1000.0
		var cut := floorf(t * 0.8 + sin(t * 0.31) * 0.7)   # cada cena, um brilho e um tom
		var lv := 0.45 + 0.45 * fposmod(sin(cut * 12.9898) * 43758.5453, 1.0) + 0.05 * sin(t * 17.0)
		var tint := TV_BLUE.lerp(Color(0.8, 0.88, 1.0), fposmod(sin(cut * 78.233) * 12345.6, 1.0) * 0.5)
		var w: Vector2 = APT["win"]
		var wa := _o(g, w.x, ff, fl + 2.4)
		var we := _o(g, w.y, ff, fl + 0.9)
		var glass: Color
		if minutes < APT_DARK:
			glass = (Pal.CITY_LIT[0] as Color).darkened(0.1).lerp(tint, 0.3 * lv)
		else:
			glass = Pal.BALCONY_ROOM.lerp(tint, 0.2 + 0.55 * lv)
			tv = Color(tint, lv)
			var c := (wa + we) / 2.0
			var rim := PackedVector2Array()
			for i in 16:
				rim.append(c + Vector2(cos(TAU * i / 16.0) * (we.x - wa.x) * 1.4, sin(TAU * i / 16.0) * (we.y - wa.y) * 1.3))
			_light_fan(c, rim, Color(tint, 0.1 * lv))
		_r(wa.x, wa.y, we.x - wa.x, we.y - wa.y, glass)
		_r(we.x - (we.x - wa.x) * 0.25, wa.y, (we.x - wa.x) * 0.25, we.y - wa.y, glass.darkened(0.45))   # a cortina
		_r(wa.x, wa.y, we.x - wa.x, maxf(PX, 0.15 * OUT_F / ff), glass.darkened(0.5))   # a sombra da verga
	_draw_smoker(g)
	var iron := Pal.BALCONY_IRON
	var x0: float = APT["x0"]
	var x1: float = APT["x1"]
	_poly(PackedVector2Array([_o(g, x0, dz, fl), _o(g, x1, dz, fl), _o(g, x1, dz, fl + 0.15), _o(g, x0, dz, fl + 0.15)]), Pal.BALCONY_SLAB)
	for h: float in [fl + 0.25, fl + 1.05]:   # o gradil: os corrimãos, o da frente e os dos lados até a fachada
		_ci.draw_line(_o(g, x0, dz, h), _o(g, x1, dz, h), iron, PX)
		_ci.draw_line(_o(g, x0, dz, h), _o(g, x0, ff, h), iron, PX)
		_ci.draw_line(_o(g, x1, dz, h), _o(g, x1, ff, h), iron, PX)
	var xb := x0
	while xb <= x1 + 0.01:
		var w: Vector2 = APT["win"]
		var bar := iron.lerp(tv, 0.35 * tv.a) if xb > w.x - 0.6 and xb < w.y + 0.6 else iron
		_r(_o(g, xb, dz).x, _o(g, xb, dz, fl + 1.05).y, PX, _o(g, xb, dz, fl + 0.15).y - _o(g, xb, dz, fl + 1.05).y, bar)
		xb += 0.25


## Um poste da calçada de lá (em `x`, `z`), com 5 m: o tubo, o braço virado para a rua e a cabeça acesa.
func _draw_lamp_post(g: Rect2, x: float, z: float) -> void:
	var foot := _o(g, x, z)
	var top := _o(g, x, z, 5.0)
	var head := _o(g, x, z - 1.0, 5.0)
	var k := (foot.y - top.y) / 5.0
	var pole := Pal.LAMP_POST
	_r(foot.x - maxf(PX, 0.08 * k), top.y, maxf(PX, 0.16 * k), foot.y - top.y, pole)
	_ci.draw_line(top, head, pole, maxf(PX, 0.1 * k))
	_r(head.x - 0.3 * k, head.y, 0.6 * k, maxf(PX, 0.15 * k), pole)
	if lamp_level > 0.5:
		_r(head.x - 0.25 * k, head.y + 0.15 * k, 0.5 * k, maxf(PX, 0.12 * k), Pal.STREET_LAMP)
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
## fachadas e a sua roupa: de vestido ou de calça (`dress`), o casaco curto ou comprido (`long`), as cores
## (`WALK_*`), o chapéu, a boina, o lenço ou nada (`hat`, sem chuva) e às vezes uma bolsa ou uma pasta (`bag`).
## `t` vai de 0 a 1 (negativo: ainda não entrou na rua).
func _walker() -> Dictionary:
	var dress := randf() < 0.4
	return {"t": 0.0, "dir": 1.0 if randf() < 0.5 else -1.0, "sec": WALK_SEC * randf_range(0.8, 1.2), "z": randf_range(STREET["far_curb"] + 0.5, STREET["far"] - 0.4),
		"h": randf_range(0.88, 0.98) if dress else randf_range(0.94, 1.06), "dress": dress, "long": randf() < 0.35,
		"coat": (WALK_DRESSES if dress else WALK_COATS).pick_random(), "legs": WALK_LEGS.pick_random(), "skin": WALK_SKIN.pick_random(),
		"umbrella": WALK_UMBRELLAS.pick_random(), "hat": ["", "", "scarf"].pick_random() if dress else ["", "fedora", "fedora", "cap"].pick_random(),
		"bag": randf() < 0.3}


## Põe `w` na calçada, na ordem do desenho (os de mais longe primeiro).
func _add_walker(w: Dictionary) -> void:
	_walkers.insert(_walkers.bsearch_custom(w, func(a: Dictionary, b: Dictionary) -> bool: return a["z"] > b["z"]), w)


## Alguém passando pela calçada de lá (`w`, de `_walker`; fora da vista, não desenha): silhueta escura de 1,7 m contra as luzes, as pernas
## alternando a cada passo, com um balanço leve, e de guarda-chuva aberto na chuva. Perto de um poste, a luz dele
## acende a beira de cima e o lado virado para ele (`RIM`); na chuva, ele se espelha na calçada molhada, apagado e
## sumindo para baixo. Em px da tela, como o homem.
func _draw_walker(g: Rect2, w: Dictionary) -> void:
	var z: float = w["z"]
	var x: float = lerpf(-WALK_SPAN, WALK_SPAN, w["t"]) * w["dir"]
	if absf(_out_x + OUT_F * x / z - g.size.x * 0.5) > g.size.x * 0.5 + OUT_F / z * 2.0:
		return
	if w.get("bike", false):
		_draw_bike(g, w, x)
		return
	if w.get("dog", false):
		_draw_stray(g, w, x)
		return
	var steps := int(w["t"] * w["sec"] * WALK_STEPS)
	var foot := (_o(g, x, z) * 2.0).floor() - Vector2(0, posmod(steps, 2))
	var k: float = OUT_F / z * 2.0 * w["h"]   # px da tela por metro (na altura dele)
	var dark := Color("07090c")
	_poly(PackedVector2Array([_o(g, x - 0.3, z), _o(g, x + 0.3, z), _o(g, x + 0.3, z + 0.2), _o(g, x - 0.3, z + 0.2)]), Color(0, 0, 0, 0.35))
	var s: float = w["dir"]   # (o que tem frente, a aba da boina e a bolsa, vira para onde ele vai)
	var coat: Color = w["coat"]
	var legs: Color = w["legs"]
	var parts: Array = []   # [peça, cor], de trás para a frente
	var apart := posmod(steps, 2) == 0
	if w["dress"]:   # as pernas finas embaixo da saia, o vestido e o casaquinho por cima
		parts.append_array([[Rect2(-0.16, 0.0, 0.1, 0.5), legs], [Rect2(0.06, 0.0, 0.1, 0.5), legs]] if apart else [[Rect2(-0.06, 0.0, 0.12, 0.5), legs]])
		parts.append_array([[Rect2(-0.24, 0.42, 0.48, 0.5), coat], [Rect2(-0.18, 0.9, 0.36, 0.53), coat.darkened(0.25) if w["long"] else coat]])
	else:
		parts.append_array([[Rect2(-0.22, 0.0, 0.13, 0.8), legs], [Rect2(0.09, 0.0, 0.13, 0.8), legs]] if apart else [[Rect2(-0.07, 0.0, 0.14, 0.8), legs]])
		parts.append([Rect2(-0.21, 0.45, 0.42, 0.98) if w["long"] else Rect2(-0.2, 0.75, 0.4, 0.68), coat])
	parts.append([Rect2(-0.1, 1.43, 0.2, 0.22), w["skin"]])   # a cabeça
	if w["bag"]:   # a bolsa no ombro, ou a pasta na mão
		parts.append([Rect2(0.14 * s - 0.06, 0.82, 0.12, 0.16), coat.darkened(0.45)] if w["dress"] else [Rect2(0.16 * s - 0.08, 0.3, 0.16, 0.24), Color("2a1a10")])
	if weather == "rain":   # o guarda-chuva: a cúpula, a beira e o cabo
		var u: Color = w["umbrella"]
		parts.append_array([[Rect2(-0.55, 1.74, 1.1, 0.1), u], [Rect2(-0.42, 1.84, 0.84, 0.1), u], [Rect2(-0.2, 1.94, 0.4, 0.05), u], [Rect2(-0.02, 1.4, 0.04, 0.36), dark]])
	else:
		match w["hat"]:
			"fedora":
				parts.append_array([[Rect2(-0.18, 1.63, 0.36, 0.04), dark], [Rect2(-0.1, 1.66, 0.2, 0.1), dark]])
			"cap":   # a boina, com a pala para a frente
				parts.append_array([[Rect2(-0.11, 1.62, 0.22, 0.07), legs], [Rect2(0.13 * s - 0.05, 1.62, 0.1, 0.03), legs]])
			"scarf":   # o lenço amarrado na cabeça
				parts.append([Rect2(-0.12, 1.52, 0.24, 0.16), coat.lightened(0.15)])
	var glow := 0.0   # o poste mais perto: até 3 m dele
	var side := 1.0
	for lx: float in FAR_LAMPS:
		var near := clampf(1.0 - absf(x - lx) / 3.0, 0.0, 1.0)
		if near > glow:
			glow = near
			side = 1.0 if lx >= x else -1.0
	var rim := Color(dark.lerp(RIM, 0.45), glow * 0.8)
	for pc: Array in parts:
		var part: Rect2 = pc[0]
		var a := Vector2(roundf(part.position.x * k), -roundf((part.position.y + part.size.y) * k))
		var b := Vector2(roundf(part.end.x * k), -roundf(part.position.y * k))
		var sz := Vector2(maxf(1.0, b.x - a.x), maxf(1.0, b.y - a.y))
		_p(foot.x + a.x, foot.y + a.y, sz.x, sz.y, (pc[1] as Color).lerp(RIM, 0.15 * glow))
		if glow > 0.0:
			if sz.y > 2.0:   # (as peças finas, como o guarda-chuva e a aba, só no lado: no alto, ficavam acesas inteiras)
				_p(foot.x + a.x, foot.y + a.y, sz.x, 1, rim)
			_p(foot.x + (a.x + sz.x - 1.0 if side > 0.0 else a.x), foot.y + a.y, 1, sz.y, rim)
		if weather == "rain":   # o reflexo, de cabeça para baixo a partir dos pés: mais fraco quanto mais longe deles
			_p(foot.x + a.x, foot.y - a.y - sz.y, sz.x, sz.y, Color(0, 0, 0, 0.35 * (1.0 - (-a.y) / (2.2 * k))))


## O carro `c` passando pela mão dele (`CAR_LANES`), apoiado no asfalto, na forma do modelo dele (`CAR_KINDS`) e na cor
## dele: a sombra de contato, o facho dos faróis no chão à frente, o capô, o teto e o porta-malas vistos um pouco de
## cima (os olhos ficam acima dele; mais escuros que o lado, porque de noite não vem luz do alto, só um pouco do céu,
## `CAR_SKY`), os vidros inclinados, a frente ou a traseira (a que estiver virada para nós) e o lado de cá (vidros,
## colunas, frisos, rodas redondas com calota nos arcos dos para-lamas). A luz dos postes
## corre pela lataria quando ele passa embaixo deles (`_sheen`; molhada, mais, `CAR_WET`), faróis e lanternas acesos
## com halo (o par deles quando a frente ou a traseira está virada para nós), a placa do táxi (`taxi`) e, na chuva, o
## borrifo dos pneus (`_spray`). Posto a partir da frente (`_car_x`), no sentido em que
## anda: o de lá vai para a esquerda, o de cá volta para a direita.
func _draw_car(g: Rect2, c: Dictionary) -> void:
	var m: Dictionary = CAR_KINDS[c["kind"]]
	var lane: Vector2 = CAR_LANES[c["lane"]]
	var d := lane.y   # o sentido: a frente vai para lá
	var x := _car_x(c)
	var L: float = m["len"]
	var at := func(a: float) -> float: return x - d * a   # a metros da frente, para trás
	var span := func(a: float, b: float) -> Vector2: return Vector2(minf(at.call(a), at.call(b)), maxf(at.call(a), at.call(b)))
	var z0: float = lane.x - m["wide"] / 2.0   # o lado de cá
	var z1: float = lane.x + m["wide"] / 2.0
	var body: Color = c["col"]
	var wet := weather == "rain"
	var top := body.darkened(0.3).lerp(CAR_SKY, 0.3 if wet else 0.15)   # molhado, espelha mais o céu
	var roof := top.lerp(CAR_SKY, 0.1).lightened(0.12)   # o teto, mais claro que os vidros (no mesmo tom, a cabine parecia quebrada)
	var glass := Color("0b1218").lerp(CAR_SKY, 0.45)   # o céu refletido: quase preto, o vidro sumia no asfalto atrás e o carro parecia só a lataria, baixo
	var chrome := Color("5a6670")
	var all: Vector2 = span.call(-0.2, L + 0.2)
	_poly(_patch(g, all.x, all.y, z0 - 0.15, z1 + 0.15), Color(0, 0, 0, 0.55))   # o contato com o asfalto
	var beam := Color(1.0, 0.95, 0.8, 0.12)   # o facho dos faróis, sumindo à frente (inteiro, era uma laje cinza colada no carro)
	_fill(PackedVector2Array([_o(g, x, z0 + 0.2), _o(g, x, z1 - 0.2), _o(g, x + d * BEAM, z1 + 0.5), _o(g, x + d * BEAM, z0 - 0.5)]),
		PackedColorArray([beam, beam, Color(beam, 0.0), Color(beam, 0.0)]))
	if m.has("bed"):   # a caçamba: o fundo dela, mais escuro, entre as paredes
		var bed: Vector2 = m["bed"]
		var bs: Vector2 = span.call(bed.x, bed.y)
		_poly(_patch(g, bs.x, bs.y, z0 + 0.08, z1 - 0.08, 0.75), body.darkened(0.45))
		_poly(PackedVector2Array([_o(g, bs.x, z1 - 0.08, 0.75), _o(g, bs.y, z1 - 0.08, 0.75), _o(g, bs.y, z1 - 0.08, m["belt"]),
			_o(g, bs.x, z1 - 0.08, m["belt"])]), body.darkened(0.3))   # a parede de lá, por dentro
		_poly(_patch(g, bs.x, bs.y, z1 - 0.08, z1, m["belt"]), top.lightened(0.1))   # as beiras dela, a de lá e a de cá
		_poly(_patch(g, bs.x, bs.y, z0, z0 + 0.08, m["belt"]), top.lightened(0.1))
		var back: float = at.call(m["cab"][3].x)   # a parede de trás da cabine, virada para a caçamba
		if d * back > 0.0:
			_poly(PackedVector2Array([_o(g, back, z0, 0.75), _o(g, back, z1, 0.75), _o(g, back, z1, 1.75), _o(g, back, z0, 1.75)]),
				body.darkened(0.25))
			var gl := PackedVector2Array([_o(g, back, z0 + 0.4, 1.2), _o(g, back, z1 - 0.4, 1.2), _o(g, back, z1 - 0.4, 1.6),
				_o(g, back, z0 + 0.4, 1.6)])
			if gl[1].distance_to(gl[0]) >= 3.0 * PX:   # o vidro de trás (de viés, mais estreito que isso, era um borrão no teto)
				_poly(gl, glass)
	var box: Color = m.get("box_col", body)
	if m.has("box") and d * x < 0.0:   # a parede da frente do baú, acima da cabine, enquanto ele vem
		var bx: float = at.call(m["box"][0].x)
		var bh: float = m["box"][1].y
		_poly(PackedVector2Array([_o(g, bx, z0, m["belt"]), _o(g, bx, z1, m["belt"]), _o(g, bx, z1, bh), _o(g, bx, z0, bh)]),
			box.darkened(0.15))
	for t: Vector3 in m["tops"]:   # o que se vê de cima: capô, teto, porta-malas (e o teto do baú)
		var ts: Vector2 = span.call(t.x, t.y)
		var tc := box.darkened(0.3) if m.has("box") and t.x >= m["box"][0].x else (roof if t.z > 1.3 else top)
		_poly(_patch(g, ts.x, ts.y, z0, z1, t.z), tc)
	var faces := func(q: Vector4) -> bool:   # a chapa inclinada de (q.x, q.y) a (q.z, q.w) está virada para os olhos? (por trás, o para-brisa sumia atrás do teto e saía como um borrão preto)
		var xa: float = at.call(q.x)
		var xb: float = at.call(q.z)
		var n := Vector2(q.y - q.w, xb - xa) * signf(xb - xa)   # a normal, para cima
		return n.dot(Vector2(-xa, OUT_EYE - q.y)) > 0.0
	for q: Vector4 in m["glass"]:   # os vidros inclinados (para-brisa, vigia)
		if faces.call(q):
			_poly(PackedVector2Array([_o(g, at.call(q.x), z0, q.y), _o(g, at.call(q.z), z0, q.w),
				_o(g, at.call(q.z), z1, q.w), _o(g, at.call(q.x), z1, q.y)]), glass)
	for q: Vector4 in m.get("slopes", []):   # as chapas inclinadas (a traseira arredondada do Fusca), as do teto no tom dele
		if faces.call(q):
			_poly(PackedVector2Array([_o(g, at.call(q.x), z0, q.y), _o(g, at.call(q.z), z0, q.w),
				_o(g, at.call(q.z), z1, q.w), _o(g, at.call(q.x), z1, q.y)]), roof if maxf(q.y, q.w) > 1.3 else top)
	var rear: float = at.call(L)
	var face := Vector2.ZERO   # a frente ou a traseira virada para nós: onde (x) e até que altura
	var front := d * x < 0.0   # a frente, enquanto ele vem (comparar `face.x` com `x` falhava: o Vector2 é de 32 bits)
	var face_glass := Vector2.ZERO
	if front:
		face = Vector2(x, m["front"])
		face_glass = m.get("front_glass", Vector2.ZERO)
	elif d * rear > 0.0:   # a traseira, quando ele já passou
		face = Vector2(rear, m["back"])
		face_glass = m.get("back_glass", Vector2.ZERO)
	if face.y > 0.0:
		var fc := box if m.has("box") and not front else body
		_poly(PackedVector2Array([_o(g, face.x, z0, 0.3), _o(g, face.x, z1, 0.3), _o(g, face.x, z1, face.y), _o(g, face.x, z0, face.y)]),
			fc.darkened(0.2))
		if face_glass != Vector2.ZERO:
			_poly(PackedVector2Array([_o(g, face.x, z0 + 0.1, face_glass.x), _o(g, face.x, z1 - 0.1, face_glass.x),
				_o(g, face.x, z1 - 0.1, face_glass.y), _o(g, face.x, z0 + 0.1, face_glass.y)]), glass)
	for key in ["body", "cab", "box"]:   # o lado de cá (e a cabine da picape e do caminhão, e o baú)
		if m.has(key):
			var side := PackedVector2Array()
			for p: Vector2 in m[key]:
				side.append(_o(g, at.call(p.x), z0, p.y))
			_poly(side, box if key == "box" else body)
	if m.has("upper"):   # a Kombi em duas cores: a de cima clara
		var up := PackedVector2Array()
		for p: Vector2 in m["upper"]:
			up.append(_o(g, at.call(p.x), z0, p.y))
		_poly(up, CAR_UPPER)
	var win := PackedVector2Array()
	for p: Vector2 in m["win"]:
		win.append(_o(g, at.call(p.x), z0 + 0.05, p.y))
	_poly(win, glass)
	var wb: Vector2 = Vector2(m["win"][0].y, m["win"][1].y)   # a altura dos vidros: para as colunas
	for a: float in m["pillars"]:   # as colunas
		_ci.draw_line(_o(g, at.call(a), z0, wb.x), _o(g, at.call(a), z0, maxf(wb.y, m["win"][2].y)), CAR_UPPER if m.has("upper") else body, PX)
	var w0: Vector2 = m["win"][0]
	var w1: Vector2 = m["win"][1]
	_ci.draw_line(_o(g, at.call(lerpf(w0.x, w1.x, 0.6) + 0.1), z0, lerpf(w0.y, w1.y, 0.5)), _o(g, at.call(w1.x + 0.3), z0, w1.y - 0.05),
		Color("3a4a58"), PX)   # o reflexo
	for h: float in m["trim"]:   # os frisos
		_ci.draw_line(_o(g, at.call(0.05), z0, h), _o(g, at.call(L - 0.05), z0, h), chrome, PX)
	for a: float in m.get("doors", []):   # as portas
		_ci.draw_line(_o(g, at.call(a), z0, 0.4), _o(g, at.call(a), z0, m["belt"]), Color(0, 0, 0, 0.5), PX)
	var shine := CAR_WET if wet else 1.0
	for t: Vector3 in m["tops"]:   # a luz dos postes na beira de lá do capô, do teto e do porta-malas
		_sheen(g, at.call(t.x), at.call(t.y), z1 - 0.15, t.z, 0.55 * shine, shine)
	for h: float in m["trim"]:   # e nos frisos
		_sheen(g, at.call(0.05), at.call(L - 0.05), z0, h, 0.35 * shine, shine)
	if c.get("taxi", false):   # o táxi: a placa acesa no teto
		var cab: Vector3 = m["tops"][1]
		var tx: float = at.call((cab.x + cab.y) / 2.0)
		_poly(PackedVector2Array([_o(g, tx - 0.25, z0 + 0.6, cab.z), _o(g, tx + 0.25, z0 + 0.6, cab.z),
			_o(g, tx + 0.25, z0 + 0.6, cab.z + 0.16), _o(g, tx - 0.25, z0 + 0.6, cab.z + 0.16)]), TAXI_SIGN)
		var tc := _o(g, tx, z0 + 0.6, cab.z + 0.08)
		_light_fan(tc, _ring(tc, 0.5 * OUT_F / z0), Color(TAXI_SIGN, 0.3))
	var r: float = m["wheel"]
	_ci.draw_set_transform(Vector2.ZERO)   # as rodas em pixel art, em px da tela
	for wx2: float in m["wheels"]:   # o arco do para-lama, o pneu e a calota
		var mid := _o(g, at.call(wx2), z0, r) * 2.0
		var dia := maxi(3, roundi(r * 2.0 * OUT_F / z0 * 2.0))
		var arch := dia + 2
		if m.get("fenders", false):   # o para-lama saltado do Fusca, com a luz na beira de cima
			PixelArt.sprite(_ci, PixelArt.disc(arch + 2, [[(arch + 2) / 2.0, body.lightened(0.12)]]), mid - Vector2(0, 2))
		PixelArt.sprite(_ci, PixelArt.disc(arch, [[arch / 2.0, body.darkened(0.6)]]), mid - Vector2(0, 1))
		PixelArt.sprite(_ci, PixelArt.disc(dia, [[dia * 0.22, Color("4a545b"), Color("3a444b"), Color("22292e")],
			[dia / 2.0, Color("14181b"), Color("0a0d0f"), Color("030506")]]), mid)
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	if wet:
		_spray(g, c, m, at, z0)
	var k := OUT_F / z0
	var w := maxf(1.0, 0.2 * k)
	var hl := _o(g, at.call(m.get("lamp_at", 0.0)), z0, m["lamp"])
	_r(hl.x - PX if d < 0.0 else hl.x - w + PX, hl.y - 0.08 * k, w, maxf(1.0, 0.16 * k), CAR_HEAD)   # o farol
	_light_fan(hl, _ring(hl, 0.35 * k), Color(CAR_HEAD, 0.3))
	var tw := maxf(PX, 0.15 * k)
	var tl := _o(g, rear, z0, m["lamp"] + 0.05)
	_r(tl.x - tw if d < 0.0 else tl.x, tl.y - 0.08 * k, tw, maxf(1.0, 0.16 * k), CAR_TAIL)   # a lanterna
	_light_fan(tl, _ring(tl, 0.25 * k), Color(CAR_TAIL.lightened(0.3), 0.3))
	if face.y > 0.0:   # de frente (ou de costas) para nós, o par de faróis (ou de lanternas) acesos, com o halo
		for zl: float in [z0 + 0.3, z1 - 0.3]:
			var p := _o(g, face.x, zl, m["lamp"] + (0.0 if front else 0.05))
			var kk := OUT_F / zl
			var col := CAR_HEAD if front else CAR_TAIL
			_light_fan(p, _ring(p, (0.7 if front else 0.35) * kk), Color(col.lightened(0.0 if front else 0.3), 0.45 if front else 0.35))
			_r(p.x - 0.1 * kk, p.y - 0.07 * kk, maxf(PX, 0.2 * kk), maxf(PX, 0.14 * kk), col)


## Na chuva, a água que os pneus levantam: um borrifo atrás de cada roda, mais alto perto dela e sumindo para trás,
## tremendo a cada quadro (os pontos sorteados pelo tempo).
func _spray(g: Rect2, c: Dictionary, m: Dictionary, at: Callable, z0: float) -> void:
	var rng := _spray_rng
	rng.seed = int(Time.get_ticks_msec() / 60)
	var r: float = m["wheel"]
	for wx2: float in m["wheels"]:
		for i in CAR_SPRAY:
			var back := rng.randf() * 1.4
			var h := rng.randf() * r * 1.6 * (1.0 - back / 1.6)
			var p := _o(g, at.call(wx2 + r * 0.6 + back), z0 - 0.05, h)
			_p(roundf(p.x * 2.0), roundf(p.y * 2.0), 1, 1, Color(0.75, 0.8, 0.85, 0.35 * (1.0 - back / 1.4)))


## A luz dos postes (`FAR_LAMPS`) refletida numa linha da lataria, de `x0` a `x1` (m ao longo da rua) a `z` m e `h` de
## altura: um pixel por coluna da tela, mais forte quanto mais perto de um poste (`CAR_SHEEN`, vezes `spread`); `alpha`
## no máximo.
func _sheen(g: Rect2, x0: float, x1: float, z: float, h: float, alpha: float, spread := 1.0) -> void:
	var a := _o(g, x0, z, h)
	var b := _o(g, x1, z, h)
	var n := absi(roundi((b.x - a.x) * 2.0))
	for i in n + 1:
		var u := float(i) / maxf(1.0, n)
		var lit := 0.0
		for lx: float in FAR_LAMPS:
			lit += exp(-pow((lerpf(x0, x1, u) - lx) / (CAR_SHEEN * spread), 2.0))
		if lit > 0.05:
			var q := a.lerp(b, u)
			_p(roundf(q.x * 2.0), roundf(q.y * 2.0), 1, 1, Color(1.0, 0.85, 0.55, alpha * minf(lit, 1.0)))


## O arbusto plantado junto da nossa parede, embaixo da janela (`SHRUB`, com a cerca viva embaixo, `HEDGE`): só a copa
## aparece, subindo do peitoril atrás do vidro, posta pela parede da sala (`_side_pt`) e não pela câmera da vista. Folhas em quatro tons (as de
## cima pegando a luz da rua), maiores do lado de perto, mexendo com o vento.
func _draw_shrub() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var t := Time.get_ticks_msec() / 1000.0
	var wind := {"rain": 0.5 + rain_level(), "clear": 0.6, "fog": 0.3}.get(weather, 0.6) as float
	# as rajadas: o vento cresce e some em ondas lentas e empurra a copa para um lado (`GUST`)
	var gust := pow(maxf(0.0, sin(t * GUST.x) * sin(t * GUST.y + 1.3)), 0.6)
	var tones := Pal.SHRUB
	var f := _flash()
	_ci.draw_set_transform(Vector2.ZERO)   # as folhas em px da tela
	var gw := SIDE_W
	var gh := _cm(WIN_SILL - WIN_TOP)
	for i in 360 + HEDGE:
		var hgt := lerpf(-0.06, SHRUB.z, pow(rng.randf(), 0.8))   # (abaixo de 0, atrás do peitoril: o vidro corta)
		var r := SHRUB.y * sqrt(maxf(0.0, 1.0 - pow(maxf(hgt, 0.0) / SHRUB.z, 2.0)))   # a copa: redonda, mais larga embaixo
		var dx := rng.randf_range(-r, r)
		if i >= 360:   # a cerca viva embaixo dela, até o batente de perto
			hgt = rng.randf_range(-0.08, 0.035)
			r = SHRUB.y
			dx = rng.randf_range(-r, 1.05 - SHRUB.x)
		var w := Vector2((SHRUB.x + dx) * gw, gh * (1.0 - hgt) + rng.randf_range(-1.0, 1.0))
		var p := (_side_pt(w, WALL_D + 8.0) - _view_at) * 2.0   # do lado de fora, atrás do vidro
		var k := clampf(_side_pt(w + Vector2(0, 1)).y - _side_pt(w).y, 0.8, 1.6)   # a escala da parede ali
		var sway := roundf((sin(t * (1.4 + gust) + i * 0.7) * (1.0 + gust) - gust * GUST.z) * wind * maxf(hgt, 0.0) / SHRUB.z * 1.5)
		var lit := clampf(maxf(hgt, 0.0) / SHRUB.z * 0.7 + (dx / maxf(0.01, r)) * 0.15 + rng.randf_range(-0.25, 0.2), 0.0, 0.99)
		var c: Color = (tones[int(lit * tones.size())] as Color).lerp(Pal.SHRUB_FLASH, f * 0.5)
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
	var up := RandomNumberGenerator.new()   # quem levanta de madrugada, também à parte
	up.seed = 1959
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
	var tones := Pal.FACADES
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
		if sp.x <= HOTEL_X and HOTEL_X <= sp.y:   # o do hotel cobre o letreiro (alto a 10 m, `_hotel_pos`)
			floors = 4
		var wins: Array[Vector3] = []
		for f in floors:
			var wsx := sp.x + 1.5
			while wsx < sp.y - 1.0:
				if i == 0 and f == 2 and wsx < APT["x1"]:   # a varanda do apartamento (`_draw_balcony`)
					wsx += 3.0
					continue
				var o := -1.0   # apagada
				if rng.randf() < (0.35 if f > 0 else 0.25):
					o = off.call()
				wins.append(Vector3(wsx, f, o))
				wsx += 3.0
		var wake := {}   # janela -> quando ela acende de novo (min do dia, de x a y)
		for j in wins.size():
			var wv := wins[j]
			if wv.y > 0.0 and wv.z < INF and up.randf() < WAKE:
				var at := up.randf_range(maxf(wv.z, WAKE_FROM) + 10.0, 23 * 60 + 50)
				wake[j] = Vector2(at, at + up.randf_range(WAKE_FOR.x, WAKE_FOR.y))
		_houses.append({"x0": sp.x, "x1": sp.y, "h": floors * 3.2 + 0.8, "col": Pal.BRICK if i == 0 else tones[rng.randi_range(0, 3)],
			"brick": i == 0, "wins": wins, "wake": wake})
	_canyon.clear()   # as paredes da rua do cruzamento: os fundos dos prédios da esquina e os que vêm depois, até a praça
	for side: float in [CROSSING.x, CROSSING.y]:
		var z := STREET["far"] as float
		while z < 118.0:
			var d := rng.randf_range(10.0, 22.0)
			var ht := rng.randf_range(7.0, 16.0)
			if z == STREET["far"]:   # a lateral do prédio da esquina: a altura da fachada dele
				for b: Dictionary in _houses:
					if is_equal_approx(b["x1"], side) or is_equal_approx(b["x0"], side):
						ht = b["h"]
			var wins: Array[Vector3] = []   # em andares e colunas (soltas ao acaso, pareciam pontos sem prédio)
			var cols := int((d - 1.0) / CANYON_WIN.x)
			var z1 := z + (d - (cols - 1) * CANYON_WIN.x) / 2.0   # as colunas centradas na parede
			for f in range(1, int((ht - 0.8) / 3.2)):   # o térreo sem janelas
				for c in cols:
					wins.append(Vector3(z1 + c * CANYON_WIN.x, f * 3.2 + 0.9, off.call() if rng.randf() < CANYON_WIN.y else 0.0))
			_canyon.append({"x": side, "z0": z, "z1": z + d, "h": ht, "col": tones[rng.randi_range(0, 3)], "wins": wins})
			z += d
	_canyon.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["z0"] < b["z0"])


## A igreja no fim da rua do cruzamento (na escala dela, `CHURCH_K`): nave, torre com a ponta e o relógio aceso no
## alto; a porta acesa até `CHURCH_DARK`.
func _draw_church(base: Vector2, col: Color) -> void:
	var k := CHURCH_K
	base.x = floorf(base.x / PX) * PX + PX / 2.0   # o eixo no meio de um pixel: a torre, a ponta e a cruz simétricas nele
	var half := func(w: float) -> float: return (roundf(w / PX - 0.5) + 0.5) * PX   # meia largura de um número ímpar de pixels
	_r(base.x - 12 * k, base.y - 18 * k, 24 * k, 18 * k, col)
	_poly(PackedVector2Array([base + Vector2(-13, -18) * k, base + Vector2(0, -26) * k, base + Vector2(13, -18) * k]), col)
	var tw: float = half.call(4 * k)
	_r(base.x - tw, base.y - 48 * k, 2 * tw, 30 * k, col)
	var sw: float = half.call(5 * k)
	var top := Vector2(base.x, roundf((base.y - 60 * k) / PX) * PX)   # a ponta da torre, presa ao pixel
	_poly(PackedVector2Array([Vector2(base.x - sw, base.y - 48 * k), top, Vector2(base.x + sw, base.y - 48 * k)]), col)
	# a cruz e o relógio em pixels, do tamanho da torre (maiores que ela, com a igreja diminuída, viravam um poste aceso)
	_r(top.x - PX / 2.0, top.y - 2.5, PX, 3.0, col)   # a cruz: a haste entra na ponta, e os braços ficam no alto dela
	_r(top.x - 2.5 * PX, top.y - 1.5, 5 * PX, PX, col)
	var face := Vector2(top.x, roundf((base.y - 40 * k) / PX) * PX)
	_r(face.x - 1.5 * PX, face.y - PX, 3 * PX, 3 * PX, Pal.CHURCH_CLOCK[1])
	_r(face.x - PX / 2.0, face.y - PX, PX, 2 * PX, Pal.CHURCH_CLOCK[0])   # os ponteiros
	if minutes < CHURCH_DARK:
		_r(base.x - 1, base.y - 4, 2, 4, Color(Pal.CITY_LIT[1], 0.8))   # a porta, com luz dentro (o relógio fica aceso)


## O clima no vidro: a chuva passando e as gotas paradas no vidro, que às vezes escorrem (chuva), e um reflexo na
## diagonal (a névoa fica na vista, `_draw_fog`).
func _draw_glass_weather(g: Rect2) -> void:
	if weather == "rain":
		# os pingos: riscos de 1 px inclinados pelo vento, mais longos e claros os de perto, e acesos perto dos postes
		var heads := _lamp_heads(g)
		var many := int(_drops.size() * rain_level())   # na garoa, poucos
		for i in many:
			var d: Vector3 = _drops[i]
			if d.x < 0.0 or d.x >= 1.0 or d.y < 0.0:
				continue
			var hp := Vector2(g.position.x + floorf(d.x * g.size.x * 2.0) * PX, g.position.y + floorf(d.y * g.size.y * 2.0) * PX)
			var lit := 0.0
			for h: Vector2 in heads:
				lit = maxf(lit, 1.0 - hp.distance_to(h) / 45.0)
			var col := Color(0.62, 0.72, 0.8).lerp(Pal.STREET_LAMP, lit * 0.7)
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
			_r(p.x, p.y, b.z * PX, b.z * PX, Pal.RAIN_BEAD[0])
			var warm := clampf(1.0 - p.distance_to(post) / 30.0, 0.0, 1.0) if lamp_level > 0.5 else 0.0
			_r(p.x, p.y, PX, PX, Pal.RAIN_BEAD[1].lerp(Pal.STREET_LAMP, warm))
	_poly(PackedVector2Array([g.position + Vector2(g.size.x * 0.12, 0), g.position + Vector2(g.size.x * 0.22, 0),
		g.position + Vector2(g.size.x * 0.02, g.size.y * 0.5), g.position + Vector2(0, g.size.y * 0.5)]), Color(1, 1, 1, 0.03))
