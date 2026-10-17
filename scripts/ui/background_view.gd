extends "res://scripts/ui/background_base.gd"
## A vista da janela do cenário (`Background`): a rua lá fora numa cena 3D simples (`OUT_*`, `_o`), com a cidade,
## o clima, quem passa, os carros, o homem do mistério e o arbusto. Desenhada de frente no vidro (`_vport`).

const SLEEP := Vector3(19 * 60, 23 * 60 + 50, 0.15)   ## as janelas apagam entre x e y (minutos do dia); z: as que ficam acesas
const RAIN_STREAK := Vector2(6.0, 14.0) ## o comprimento do risco (px da tela), do mais longe ao mais perto: o rastro do quadro
const RAIN_SLANT := 0.18 ## o vento: quanto o pingo anda para a esquerda a cada px que cai
const WALK_SPAN := 12.0   ## de onde a onde quem passa anda (m dos dois lados do meio): fora do vidro, para entrar e sair pelas beiras dele (com a vista mais perto, `OUT_F`, o vidro mostra ~9 m para cada lado)
const WALK_SEC := 13.0    ## quanto leva atravessando (~1,8 m/s, de 12 m a 12 m; cada um ±20%)
const WALK_STEPS := 2.2   ## passos por segundo (as pernas alternam nesse ritmo)
const TURN_Z := 30.0      ## de onde (z, m) quem vira a esquina vem pela calçada da rua do cruzamento, ou até onde vai (`_walk_at`)...
const TURN_FAR := 70.0    ## ...e de manhã, até onde (mais gente vem de longe, contra o sol)
## A vista é uma cena 3D simples projetada para o vidro (pensada antes, não elemento por elemento): uma câmera dentro
## do prédio, na altura de quem está na janela (`OUT_EYE` m acima da rua: o horizonte passa ali), olhando para fora,
## de frente para uma rua que passa ao lado do prédio e continua para os dois lados. Um ponto de fuga só, no meio do
## horizonte (`OUT_AT`), na altura do da sala (a altura dos olhos, `_vp`: uma câmera só para o cenário inteiro): para ele fogem só as linhas que vão para longe (a rua do cruzamento,
## as laterais dos prédios); a rua, os meios-fios e as fachadas de frente ficam na horizontal, e as paredes na
## vertical. Não é a perspectiva da janela (a diagonal dela é só do primeiro plano). Tudo em metros (`_o`: `x` ao longo
## da rua, `z` a distância dos olhos, `h` a altura), no tamanho de verdade.
const OUT_EYE := 3.8      ## os olhos acima da rua (m)
const OUT_F := 48.0       ## a distância focal (px de 2x2 de um metro a um metro): quem passa na calçada de lá tem ~18 px (com 54 e 64, perto demais; com 38, ~13; com 32 e a rua mais larga, um palito; mais perto, a mão de cá sai cortada pelo peitoril)
const OUT_K := OUT_F / 38.0   ## o que é desenhado em px fixos (a igreja, o sol, a lua, o letreiro) cresce junto, da distância focal em que foi desenhado
## O ponto de fuga lá fora, de lado a lado do vidro (do batente de longe, 0, ao de perto, 1).
const OUT_AT := 0.5
## O horizonte lá fora abaixo da altura dos olhos (cm): com a vista perto (`OUT_F`), nos olhos ele subia demais (a rua
## enchia o vidro e o alto dos prédios e o letreiro saíam por cima); com 18, a mão de lá ficava atrás do peitoril.
const OUT_DROP := 10.0
## A rua, de perto para longe (z, m): a nossa fachada, a nossa calçada até o meio-fio, as duas mãos (a faixa no meio),
## o meio-fio de lá, a calçada de lá e as fachadas do outro lado, apoiadas nela.
const STREET := {"curb": 2.8, "lane": 5.2, "far_curb": 7.6, "far": 9.4}   # (era de 14 m: quem passava tinha 8 px)
const CROSSING := Vector2(-4.2, 5.8)   ## a rua do cruzamento, indo embora entre os prédios de lá (x, m; 10 m: com 4,9, era um corredor, e com 8, estreita)
const CURB_LIT := 2.5   ## até onde dos dois lados do pé de cada poste (m) a quina do meio-fio fica na luz dele
const MANHOLE := Vector2(-0.6, 4.8)   ## a tampa do bueiro no asfalto (x, z em m)
const CROSS_MANHOLE := Vector2(0.6, 19.0)   ## ...e a da rua do cruzamento
const CROSS_DETAIL := 45.0   ## até onde (z, m) o chão da rua do cruzamento tem detalhe (depois, menor que um pixel)
const DRAINS := [-9.1, 11.0]          ## as bocas de lobo no meio-fio de lá (x, m)
const FAR_LAMPS := [6.2, -10.9, 15.1]  ## os postes da calçada de lá (x, m): o primeiro na esquina do prédio de tijolos, com o homem
const MAN_X := 6.7        ## onde o homem fica, embaixo do poste da esquina
const MAN_FROM := 13.0    ## de onde ele vem pela calçada (x, m; fora do vidro) e para onde volta
const MAN_WALK := 4.5     ## quanto ele leva andando de lá até o poste (min de jogo: ~5 s, ~1,6 m/s)
const MAN_STRIDE := 0.75  ## o passo dele (m)
## A porta do bar, ao lado da vitrine (de x a y, m): de vez em quando alguém sai por ela (`_bar_t`, posto pelo
## `Background`); ela abre em BAR_SWING s, fica aberta e fecha, em BAR_SEC s ao todo.
const BAR_DOOR := Vector2(8.45, 9.25)
const BAR_SWING := 0.3
const BAR_SEC := 2.4
const BEHIND_SEC := 2.6   ## quanto quem passa atrás de uma janela acesa do prédio de tijolos leva de um lado ao outro dela (s)
const BAR_OPENS := 29 * 60 + 30   ## de manhã, o dono abre o bar (min do dia, depois da meia-noite) e fica na porta, olhando a rua
const RACK_KINDS := ["fusca", "brasilia", "sedan", "perua"]   ## os carros que podem vir com o bagageiro no teto...
const RACK := Vector2(0.08, 0.35)   ## ...e quantos vêm, de noite e às 6h (quem pega a estrada cedo)
const DAMP := 0.4    ## de manhã, o asfalto úmido do sereno espelha os faróis e as lanternas, fraco (na chuva, 1)
const MIRROR_A := 0.3   ## a força do reflexo das vitrines e portas acesas no asfalto molhado (`_mirror`)
const RIM := Color(1.0, 0.8, 0.5)   ## a luz dos postes na beira de quem passa embaixo deles
## Alguém fuma na varanda do apartamento de vez em quando (`_smoke_t`, posto pelo `Background`): sai pela porta, fica
## SMOKE_SEC s no gradil, na frente da janela da TV, com a brasa acendendo a cada tragada (`PUFF_EVERY`), e volta.
const SMOKE_SEC := 40.0
const PUFF_EVERY := 7.0
const SMOKE_LIT := 6.0   ## até quantos metros da cabeça do poste ela pega a luz dele (`RIM`)
const SMOKE_PUFF := 6.0  ## quanto o sopro da tragada leva para sumir (s)
const NEON_GHOST := 0.16     ## o letreiro refletido no vidro da sala (`_draw_neon_glass`): a força das letras...
const NEON_SHIFT := Vector2(5, 3)   ## ...e quanto elas ficam deslocadas das de verdade (px da tela)
const NEON_T_OFF := 0.7      ## a força do reflexo com o T apagado
const NEON_BEADS := 22.0     ## até onde as gotas no vidro pegam o vermelho dele (px de 2x2)
const EMBER := Color(1.0, 0.45, 0.15)
## O gato de algumas noites (`CAT_NIGHTS` delas, sorteado pela noite, `_cat_plan`): sentado na marquise do hotel ou no
## gradil da varanda por um tempo, piscando os olhos acesos e mexendo o rabo.
const CAT_NIGHTS := 0.5
const CAT_EYES := Color(0.85, 0.9, 0.35)
const BIKE_SEC := 4.8     ## quanto quem passa de bicicleta leva de um lado ao outro (~4,5 m/s; cada um ±15%)
## Os telefones da lista que se veem do outro lado da rua (`phones`, posto pelo Main): o Hotel Estrela, no saguão, pela
## porta embaixo da marquise, e o Bar do Zé, atrás da vitrine. Transferida a ligação para um deles, alguém vem atender.
const CALLED := [305, 327]
const PHONE_WALK := 1.6   ## quanto a pessoa leva até o telefone (s)
const SIGN := Vector2(8.0, 26.0)   ## a caixa do letreiro do hotel (px de 2x2), com as cinco letras na fonte de 11, uma embaixo da outra (`SIGN_STEP` px)
const SIGN_STEP := 10
const HOTEL_X := -6.3     ## o letreiro do hotel, no prédio do outro lado da esquina
## O táxi que para na marquise do hotel (`Background.TAXI_STOPS` por noite): pela mão de lá, chega freando em
## `TAXI_STOP.x` s com o meio na porta, fica parado `TAXI_STOP.y` s e sai acelerando em `TAXI_STOP.z` s (`_taxi_x`).
## O passageiro (`GUEST`) desce do lado da calçada `x` s depois de parar, a porta bate em `y` e ele leva `z` s com a
## mala até a porta do hotel, onde some (`_draw_guest`).
const TAXI_STOP := Vector3(3.2, 6.5, 3.0)
const GUEST := Vector3(0.5, 1.2, 3.6)
## Um vira-lata caramelo trotando pela calçada de lá de vez em quando (`Background.STRAY_EVERY`; com chuva, não): em
## pixel art, dois quadros do trote (`STRAY_ART`), virado para onde vai; uns pixels maior que o de verdade, como o gato.
## Escuro, sumia na calçada: o pelo caramelo, apagado pela noite, aparece contra ela (`Pal.STRAY_COAT`).
const STRAY_SEC := 15.0   ## quanto ele leva de um lado ao outro (~1,5 m/s; cada um ±15%)
const STRAY_ART := [["......#...", "#.....###.", ".#########", ".######...", "#..#.#..#.", "#..#.#..#."],
	["......#...", "#.....###.", ".#########", ".######...", ".##...##..", ".##...##.."]]
## As mariposas em volta das cabeças acesas dos postes, nas noites limpas: quantas por poste e a cor delas na luz.
const MOTHS := 5
const MOTH := Color(1.0, 0.94, 0.78)
## O prédio de tijolos da esquina é de apartamentos: no 3º andar (de `floor` m), uma varanda de `x0` a `x1` (m ao longo
## da rua), saindo `deep` m da fachada, com a porta (`door`, de x a y) e a janela da sala (`win`), onde a TV fica ligada.
const APT := {"x0": 6.5, "x1": 9.5, "floor": 6.5, "deep": 1.0, "door": Vector2(6.8, 7.5), "win": Vector2(8.0, 9.2)}
const APT_DARK := 21 * 60 + 40   ## a luz da sala do apartamento apaga: dali em diante, só a TV
const TV_OFF := 23 * 60 + 35     ## e a TV também (alguém dormiu na frente dela)
const TV_BLUE := Color(0.42, 0.58, 0.95)   ## a luz da TV no vidro
## Janelas que acendem de madrugada (alguém levantou): `WAKE.x` delas, das janelas que já apagaram, acendem de novo
## uma vez entre `WAKE_FROM` e a meia-noite, por `WAKE_FOR` min (sorteado, sempre o mesmo).
const BRICK_LIT := 0.5   ## das janelas apagadas do prédio de tijolos, quantas ficam acesas até depois das 22h
const WAKE := 0.14
const WAKE_FROM := 21 * 60 + 30
const WAKE_FOR := Vector2(4, 14)
const WAKE_DAWN := 0.3   ## e quantas das que apagaram acendem de novo de madrugada (a última noite), de vez
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
		"box": [Vector2(2.95, 1.05), Vector2(2.95, 3.0), Vector2(6.5, 3.0), Vector2(6.5, 1.05)], "box_col": Pal.TRUCK_BOX,
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
const CAR_SHEEN := 2.4   ## até onde (m ao longo da rua) a luz de um poste corre pela lataria
const CAR_WET := 1.6   ## na chuva, a lataria molhada: a luz dos postes nela mais forte e mais espalhada
const TAXI := 0.15   ## dos Fuscas e sedãs, quantos são táxi (com a placa acesa no teto)
const TAXI_KINDS := ["fusca", "sedan"]
const CAR_SPRAY := 14   ## os pontos do borrifo atrás de cada roda, na chuva
const BRICK_VARY := Vector2(0.16, 0.28)   ## dos tijolos da fachada, quantos mais claros (até x) e mais escuros (até y)
const BOUNCE := Vector3(3.0, 2.6, 0.22)   ## de manhã, o rebatido da faixa de sol nas fachadas da boca do cruzamento: até onde para o lado e para cima (m) e a força
const SKY_TOP := 0.35   ## de manhã, o quanto o alto das fachadas de lá clareia na luz do céu
const CANYON_WIN := Vector2(2.6, 0.5)
const PARKED := Vector3(2.4, 13.0, 4.0)   ## o carro estacionado na rua do cruzamento, junto do meio-fio da direita: x do lado de fora, z da traseira e o comprimento (m)
const SHOP_Z := 60.0   ## até onde (z, m) o térreo das paredes da rua do cruzamento tem portas e lojas (depois, menores que um pixel)
## com o sol, a parede da esquerda da rua do cruzamento acesa de raspão (`_draw_canyon_wall`): fraca, porque o sol está
## quase no eixo da rua e a luz chega muito deitada nela (~1/4 da do chão; com 0,45, tão dourada quanto a faixa)
const WALL_LIT := 0.2
const CANYON_GRAIN := 0.12   ## a força da textura das paredes da rua do cruzamento (as fiadas e os remendos, translúcidos)   ## as janelas das paredes da rua do cruzamento: de quantos em quantos metros e quantas acesas
const BEAM := 5.0   ## até onde vai o facho dos faróis no asfalto (m)
## Quanto da profundidade do carro (a largura dele, de um lado ao outro da mão) entra no recuo para o ponto de fuga: a
## vista é grande-angular, e longe do meio o carro se inclinava tanto que parecia ter metade da largura do comprimento.
const CAR_DEPTH := 0.4
## A árvore nova da nossa calçada, junto da parede, embaixo da janela: é do primeiro plano, como a janela, e fica no
## plano da parede dela (não na vista). O meio e a meia largura da copa (fração da largura do vão) e quanto ela sobe
## acima do peitoril (fração da altura): baixa, a pedido, para não esconder o outro lado da rua.
const SHRUB := Vector3(0.66, 0.24, 0.15)
const CLUMPS := 18        ## os tufos de folhas da copa...
const CLUMP_LEAVES := 30  ## ...e as folhas de cada um
const CLUMP_R := Vector2(7, 12)   ## o raio dos tufos (px da tela, sorteado): de perto, maiores que os do arbusto
## Os galhos que aparecem entre os tufos: do tronco, saindo do peitoril, até o meio de alguns deles.
const BRANCHES := 5
const HEDGE := 110   ## as folhas da cerca viva embaixo dela, até o batente de perto (sem ela, sobrava a rua vazia entre a copa e o peitoril)
## As rajadas de vento no arbusto: as duas ondas lentas que as fazem (rad/s) e quanto elas empurram a copa para a
## esquerda (px da tela no alto dela).
const GUST := Vector3(0.23, 0.071, 2.5)
const DAY_GAIN := 1.5    ## de dia, o quanto a cor da cidade cresce, vezes a do céu (o `modulate` dela, `_process`)...
const DAY_WARM := 0.5   ## ...que é a do alto indo para a do horizonte (com 0,4, azulada, desbotava as cores quentes)
## o quanto o céu já é de dia às 6h (`_day_sky`: as nuvens brancas, o clarão e o halo do sol encolhendo): pouco, porque
## o turno acaba às 6h, e o céu dessa hora fica quente (de dia, branco e azul, o sol sumia no horizonte claro)
const DAY_SKY := 0.25
const SUN_R := 7.0 * OUT_K        ## o raio do sol (px de 2x2; o disco, `_sun_at`)...
const SUN_DISC := 0.55   ## ...o do disco, em raios dele (pequeno, a pedido, quase todo miolo branco e com o brilho forte em volta, `_draw_dawn`)...
const SUN_GLOW := Vector2(3.4, 1.0)   ## ...o brilho que sai dele, por cima da beira: até quantos raios do disco e a força no meio...
## ...e onde ele está às 6h, ainda baixo, ao lado da torre (como na referência): x, raios dele à direita do eixo; y, a
## altura em unidades da igreja (`CHURCH_K`; o telhado da nave fica em 26)
const SUN_LOW := Vector2(0.5, 36.0)
const RAYS := 160         ## as fatias do leque dos raios crepusculares em volta do sol (`_draw_crepuscular`)...
const COVER_STEPS := 12   ## ...os pontos de cada um conferidos contra a igreja (`_church_cover`)...
const RAY_A := 0.55       ## ...a força deles...
const CHURCH_SHADOW := 0.6   ## ...e a da sombra da igreja neles
## Com o sol subindo, a luz dele lá fora clareia do laranja para a do dia (`Pal.SUN_HIGH`, o quanto às 6h, `_sun_tint`)
## e a faixa dele na rua e a sombra em volta dela se apagam no dia (o quanto fica delas às 6h; laranja e forte até o
## fim, parecia o sol ainda nascendo, pedido 273).
const SUN_PALE := 0.75
const SUN_FADE := Vector2(0.65, 0.45)
const STRIP_A := 0.5      ## a faixa de sol que entra pela rua do cruzamento e atravessa a nossa (`_draw_street`)...
const STREET_SHADE := 0.62 ## ...a sombra dos prédios de lá no resto da rua...
const SHADOW_A := 0.75    ## ...e as sombras compridas nela (`_sun_shadow`)
## ...e até onde vai a de um poste (m): o sol não é um ponto, e a de algo fino some a ~100 vezes a largura dele (inteiras,
## 70 m, emendavam umas nas outras numa listra, como um meio-fio)
const POST_UMBRA := 16.0
const STRIP_EDGE := 0.5   ## a faixa de sol: a sombra das paredes nas beiras dela (m)
const STRIP_NEAR := 0.6   ## ...o quanto ela avermelha para cá (`Pal.SUN_DEEP`)...
## ...e, na boca do cruzamento, o quanto ela clareia para o laranja claro (`Pal.SUN_RIM`) e o quanto fica mais cheia (a
## força vezes isto: translúcido por cima do asfalto, o amarelo ficava cáqui)...
const STRIP_MOUTH := Vector2(0.45, 1.35)
## ...e as beiras dela, esmaecendo da luz à sombra (m): a largura de cada lado e o quanto a da direita cresce por m de
## sombra da parede (a luz de um sol baixo chega espalhada; num degrau só, parecia recortada)
const STRIP_SOFT := Vector2(0.45, 0.12)
## o sol espelhado no asfalto úmido, na faixa (`_draw_glints`): a meia largura da coluna na tela no horizonte e o quanto
## ela cresce por px descendo e a força...
const GLINT := Vector2(2.0, 0.45)
const GLINT_A := 0.75
const GLINT_WAVES := Vector2(0.9, 0.37)   ## ...os trechos secos e úmidos das marcas de pneu, por m...
const GLINT_BASE := 0.18   ## ...e o quanto brilha o resto do asfalto
## as marcas dos pneus na rua (`_draw_street`): na nossa, z (m); na do cruzamento, x (m; os carros desviam do
## estacionado); a largura e a força
const TRACKS_NEAR := [4.1, 4.9, 5.5, 6.3]
const TRACKS_FAR := [-1.6, -0.3, 0.9, 2.2]
const TRACK_W := 0.55
const TRACK_A := 0.8
## a sombra dos prédios de lá na rua: junto da faixa de sol, a luz rebatida dela (a largura em m e o quanto esquenta);
## a força perto e no longe, pela do meio (`STREET_SHADE`), e a do escuro junto dos meios-fios
const BOUNCE_SHADE := Vector2(1.6, 0.3)
const SHADE_DEPTH := Vector2(1.25, 0.55)
const SHADE_CORNER := 0.5
const CIRRUS := 22        ## os fiapos de nuvem do céu do amanhecer (`_draw_cirrus`)
## Os bancos de nuvem do amanhecer, em faixas largas no alto do céu, como na referência (`_draw_banks`): quantos, os
## gomos de cada um e até onde do céu à vista eles descem (fração, do alto ao horizonte).
const BANKS := Vector3(10, 6, 0.8)
const SHOP_POOL := 0.3   ## com os postes apagados, a luz das vitrines acesas na calçada
const PUDDLES := 7       ## as poças do amanhecer, espelhando o céu (`_draw_puddles`)...
const PUDDLE_A := 0.5    ## ...e a força delas
const MIST_A := 0.45      ## a neblina baixa no fundo da rua, de madrugada (`_draw_dawn_mist`)
## Os reflexos da lente na linha do sol ao meio da vista: Vector3(onde, de 0 no sol a 1 no meio e além; o raio, px de
## 2x2; a força), cada um na sua cor (`Pal.FLARE`).
const FLARES: Array[Vector3] = [Vector3(0.45, 2.0, 0.22), Vector3(0.8, 4.5, 0.1), Vector3(1.2, 1.5, 0.25), Vector3(1.6, 7.0, 0.07)]
const MOON_BIG := 1.6     ## a lua no horizonte, maior (a ilusão da lua no horizonte); volta a 1 ao subir
const MOON_SHRINK := 0.4  ## até onde da subida (`_moon_t`) ela ainda está encolhendo
## Na névoa, a lua espalhada: o raio do clarão em volta (vezes o halo de sempre), a força dele, a do miolo e a do
## disco (quase apagado).
const FOG_MOON := Vector4(6.0, 0.3, 0.55, 0.3)
const OVERCAST := 14      ## as nuvens do céu da chuva (`_draw_overcast`)
const OVERCAST_SPEED := 0.012
## Os planos da cidade de longe, no fim da rua do cruzamento: a distância (m) e o quanto cada um some no ar. O 2, entre
## os outros, são os prédios altos atrás da igreja, como os da referência do amanhecer.
const FAR_ROWS := [Vector2(400.0, 0.55), Vector2(250.0, 0.35), Vector2(320.0, 0.5)]
const CHURCH_K := 0.4 * OUT_K    ## a escala da igreja (desenhada em px de 2x2), no fim da rua do cruzamento (na distância focal, `OUT_F`)...
## ...e a torre, fina como a da referência (em unidades de `CHURCH_K`): o alto dela, a ponta e o relógio (com 60 e 78,
## alta demais, a pedido)
const CHURCH_TOWER := Vector3(46.0, 62.0, 34.0)
const FOG := Color(0.55, 0.62, 0.66)   ## a cor da névoa (`_draw_fog`)
const FOG_VEIL := 0.2    ## o véu dela por cima de tudo lá fora (o longe some nele)
const FOG_GROUND := 0.2  ## o tanto a mais rente ao chão, sumindo até 3 m de altura
const FOG_WISPS := 9     ## os fiapos passando pela rua
## O peitoril (cm abaixo dos olhos): uns 24 cm acima do tampo, como numa sala de verdade (desce pouco: a parede fica a
## uns 70 cm da cabeça). Com os olhos acima da tela e o peitoril 38 cm abaixo deles, a janela descia uns 40° e parecia
## vista de cima.
const WIN_SILL := 46.0
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
var _cars: Array[Dictionary] = []   # os carros passando lá fora: {"t": de 0 a 1, "lane": em `CAR_LANES`, "kind": em `CAR_KINDS`, "tones": a rampa da lataria em `Pal.CAR_TONES`, "taxi"}
var _walkers: Array = []   # quem está passando na calçada de lá (`_walker`), na ordem do desenho: os de mais longe primeiro
var _bar_t := -1.0   # há quanto tempo a porta do bar abriu (s; -1 = fechada)
var _indoor := Vector3(-1.0, 0.0, 1.0)   # alguém passando atrás de uma janela acesa do prédio de tijolos: há quanto tempo (s; -1 = ninguém), qual janela e para que lado
var _smoke_t := -1.0   # há quanto tempo alguém saiu para fumar na varanda (s; -1 = ninguém)
var _cat_for := -1     # a noite do `_cat_plan`
var _cat_plan := Vector4.ZERO   # o gato desta noite: x 1 se vier, y onde (0 marquise, 1 gradil), de z a w (min do dia)
var cat_here := false  ## o gato aparece já, a noite toda (a captura de tela)
var phones := [0, 0]   ## o estado dos telefones de `CALLED`: 0 quieto, 1 tocando (alguém vai atender), 2 na linha
var _phone_seen := [0, 0]
var _phone_from := [0, 0]   # o estado de antes (saindo do telefone, a pessoa vai embora)
var _phone_at := [0.0, 0.0]   # quando o estado mudou (s)


## Os tons do céu agora, do alto ao horizonte (em `Pal.DAWN_STOPS`): o do clima (o horizonte um pouco mais claro) ou,
## na última noite, o do amanhecer (`Pal.DAWN_SKY`, pelo `dawn`); clareados pelo relâmpago.
func _sky_stops() -> Array[Color]:
	var top: Color = Pal.SKY.get(weather, Pal.SKY["rain"])
	var out: Array[Color] = [top, top, top.lightened(0.04), top.lightened(0.12)]
	var d := dawn()
	if d > 0.0:
		var keys := Pal.DAWN_SKY
		var i := 1
		while i < keys.size() - 1 and d > keys[i][0]:
			i += 1
		var k := smoothstep(keys[i - 1][0], keys[i][0], d)
		for j in out.size():
			out[j] = (keys[i - 1][1][j] as Color).lerp(keys[i][1][j], k)
	var f := _flash()
	for j in out.size():
		out[j] = out[j].lerp(Pal.FLASH, f)
	return out


## O céu agora, no alto e no horizonte (`_sky_stops`).
func _sky_tones() -> Array[Color]:
	var s := _sky_stops()
	return [s[0], s[3]]


## O céu da vista (na camada `_sky`, embaixo da cidade, fora da luz do dia dela): do alto ao horizonte, liso (em faixas,
## pareciam camadas; de noite, só perto do horizonte; amanhecendo, nos quatro tons pelo céu todo), as estrelas, a lua e
## as nuvens, o nublado da chuva e, no amanhecer, o clarão e o sol.
func _draw_sky(g: Rect2) -> void:
	var wx := g.position.x
	var wy := g.position.y
	var ww := g.size.x
	var wh := g.size.y
	var hzy := _hz(g)
	var stops := _sky_stops()
	var sky := stops[0]
	var d := dawn()
	_r(wx, wy, ww, wh, sky)
	var from := _sky_from(g)
	for j in 3:
		var y0 := lerpf(from, hzy, Pal.DAWN_STOPS[j])
		var y1 := lerpf(from, hzy, Pal.DAWN_STOPS[j + 1])
		_fill(PackedVector2Array([Vector2(wx, y0), Vector2(wx + ww, y0), Vector2(wx + ww, y1), Vector2(wx, y1)]),
			PackedColorArray([stops[j], stops[j], stops[j + 1], stops[j + 1]]))
	if weather == "clear":
		var tw := Time.get_ticks_msec() / 700.0
		var fade := smoothstep(0.0, 0.22, d)   # às 4h30 já não há estrelas
		if fade < 1.0:
			for i in _stars.size():
				var s: Vector2 = _stars[i]
				var star: Color = Pal.STARS[1] if sin(tw + i * 1.7) > -0.6 else Pal.STARS[0]
				_r(wx + floorf(s.x * ww), wy + floorf(s.y * (hzy - wy)), PX, PX, star.lerp(sky, fade))
		_draw_cirrus(g, hzy)
		_draw_banks(g, hzy)
		_draw_dawn(g, hzy)   # (por cima das nuvens: um banco passando na frente apagava o sol)
		_draw_moon(g, sky, hzy)
		_draw_crepuscular(g, _sun_at(g), hzy)   # (por cima das nuvens: elas cortavam a sombra da igreja)
	elif weather == "fog":
		_draw_moon(g, sky, hzy)   # difusa: a névoa espalha a luz dela
	elif weather == "rain":
		_draw_overcast(g, sky, hzy)


## Onde está o sol (na vista `g`), ou um ponto fora dela antes de ele nascer: a janela olha para o leste e ele nasce às
## 5h25 no fundo da rua do cruzamento, atrás da igreja (a lua também nasce atrás dela), e sobe devagar ao lado da
## torre, ainda baixo às 6h (`SUN_LOW`).
func _sun_at(g: Rect2) -> Vector2:
	var church := _church_pos(g)
	church.x = floorf(church.x / PX) * PX + PX / 2.0   # (no eixo da torre, como `_draw_church`)
	var up := (minutes - SUNRISE) / (DAWN.y - SUNRISE)
	return Vector2(church.x + SUN_R * SUN_LOW.x * clampf(up, 0.0, 1.0), lerpf(_hz(g) + SUN_R * 0.6, church.y - SUN_LOW.y * CHURCH_K, up))


## O quanto o sol já ilumina a cidade (0 até pouco antes de ele nascer, 1 logo depois; só no céu limpo): a luz quente
## de lado nas paredes, a faixa de sol na rua e as sombras compridas nela.
func _sunlit() -> float:
	return smoothstep(SUNRISE - 10.0, SUNRISE + 15.0, minutes) if weather == "clear" else 0.0


## O quanto o céu já é de dia (0 no amanhecer, `DAY_SKY` às 6h): as nuvens branqueando, o clarão do horizonte e o
## halo do sol encolhendo.
func _day_sky() -> float:
	return DAY_SKY * smoothstep(0.8, 1.0, dawn())


## Quantos metros de sombra no chão por metro de altura: o sol baixo as estica e, subindo, elas encurtam.
func _shadow_k() -> float:
	return lerpf(14.0, 6.0, smoothstep(SUNRISE, DAWN.y, minutes))


## A sombra comprida no chão de algo de pé em `z` (m), de `x0` a `x1` e `h` m de altura, vindo para cá: o sol está no
## fim da rua do cruzamento, e ela só aparece na faixa de sol que entra por ali (`_strip_end`; fora dela, a rua já está
## na sombra dos prédios de lá), um pouco para a esquerda (`_wall_shade`), sumindo na ponta.
func _sun_shadow(g: Rect2, x0: float, x1: float, z: float, h: float) -> void:
	var sun := _sunlit()
	if sun <= 0.0:
		return
	var a := maxf(x0, CROSSING.x + STRIP_EDGE)
	var b := minf(x1, _strip_end(g, z))
	if b <= a:
		return
	var col := Color(Pal.RAY_SHADOW, SHADOW_A * sun)
	var side := _wall_shade(g, h)   # (o sol um pouco à direita do eixo da rua: ela vem para cá e para a esquerda)
	var near := maxf(z - h * _shadow_k(), 1.0)
	_fill(PackedVector2Array([_o(g, a, z), _o(g, b, z), _o(g, b - side, near), _o(g, a - side, near)]),
		PackedColorArray([col, col, Color(col, 0.0), Color(col, 0.0)]))


## Os fiapos de nuvem do amanhecer pelo céu todo (`CIRRUS`, sempre os mesmos, andando devagar): compridos e finos, o
## alto ainda frio e a beira de baixo rosa, dourando com o sol e mais quente perto do horizonte; de dia, brancos e fracos.
func _draw_cirrus(g: Rect2, hzy: float) -> void:
	var tint := smoothstep(0.25, 0.55, dawn())
	if tint <= 0.0:
		return
	var top := g.position.y + (g.size.y + _near) * _glass_from
	var day := _day_sky()
	var a := tint * lerpf(0.75, 0.35, day)
	for k in CIRRUS:
		var y := fmod(k * 0.618, 1.0) * 0.85   # (fração do céu à vista, longe do horizonte)
		var at := Vector2(g.position.x + fposmod(fmod(k * 0.37, 1.0) * 1.4 + minutes * 0.002, 1.4) * g.size.x - 0.2 * g.size.x, lerpf(top, hzy - 8.0, y))
		var size := Vector2(8.0 + fmod(k * 0.53, 1.0) * 18.0, 0.8 + fmod(k * 0.29, 1.0) * 0.9)
		var low := Pal.DAWN_CLOUD.lerp(Pal.SUN_RIM, 0.6 * _sunlit() * y).lerp(Pal.DAY_CLOUD, day)
		var high := Pal.DAWN_CLOUD_TOP.lerp(Pal.DAY_CLOUD, day)
		for layer in [1, 0]:   # a de baixo um pouco mais baixa, para sobrar a beira dela
			var mid := at + Vector2(0, size.y * 0.5 * layer)
			_light_fan(mid, PackedVector2Array(Array(_ring(Vector2.ZERO, 1.0)).map(func(p: Vector2) -> Vector2: return mid + p * size)),
				Color(low if layer else high, a))


## Os bancos de nuvem do amanhecer (`BANKS`, sempre os mesmos, andando devagar): faixas compridas de gomos achatados
## no alto do céu, de beira nítida, o corpo ainda na sombra (`Pal.DAWN_CLOUD_TOP`) e a beira de baixo acesa por baixo, rosa
## antes do sol e laranja com ele, mais nos de baixo; de dia, brancos e fracos.
func _draw_banks(g: Rect2, hzy: float) -> void:
	var tint := smoothstep(0.2, 0.5, dawn())
	if tint <= 0.0:
		return
	var top := g.position.y + (g.size.y + _near) * _glass_from
	var day := _day_sky()
	var a := tint * lerpf(0.95, 0.4, day)
	var lits := []   # as beiras acesas primeiro e os corpos por cima, cada um num laço: o lote não quebra
	var bodies := []
	for k in int(BANKS.x):
		var y := lerpf(top + 4.0, lerpf(top, hzy, BANKS.z), fmod(k * 0.618 + 0.1, 1.0))
		var x0 := g.position.x + fposmod(fmod(k * 0.43, 1.0) * 1.5 + minutes * 0.0015 * (1.0 + 0.2 * k), 1.5) * g.size.x - 0.4 * g.size.x
		var low := smoothstep(top, hzy, y)   # (os de baixo pegam mais o sol)
		var under := Pal.DAWN_CLOUD.lerp(Pal.SUN_RIM, (0.4 + 0.5 * low) * _sunlit()).lerp(Pal.DAY_CLOUD, day)
		var body := Pal.DAWN_CLOUD_TOP.lerp(Pal.DAWN_CLOUD, 0.25 + 0.3 * low).lerp(Pal.DAY_CLOUD, day)
		for j in int(BANKS.y):
			var u := fmod((k * 7 + j) * 0.381, 1.0)
			var size := Vector2((0.06 + 0.06 * u) * g.size.x, 1.5 + 2.0 * fmod((k + j) * 0.29, 1.0))
			var mid := (Vector2(x0 + j * 0.07 * g.size.x, y - size.y * 0.4 * sin(j * 1.3 + k)) / PX).round() * PX
			lits.append([mid + Vector2(0, maxf(PX, size.y * 0.45)), size, Color(under, a)])
			bodies.append([mid, size, Color(body, a)])
	for e: Array in lits + bodies:   # (12 pontos presos aos pixels: a beira nítida, em degraus)
		var oval := PackedVector2Array()
		for i in 12:
			oval.append(((e[0] + Vector2.from_angle(TAU * i / 12.0) * e[1]) / PX).round() * PX)
		_poly(oval, e[2])


## A neblina baixa da madrugada no fundo da rua (na frente da cidade de longe e da igreja, atrás das paredes da rua do
## cruzamento): uma faixa lisa no horizonte, dourada no lado do sol, sumindo com ele nascendo (na frente da igreja, a
## luz dela parecia atravessá-la).
func _draw_dawn_mist(g: Rect2) -> void:
	var m := smoothstep(DAWN.x, DAWN.x + 40.0, minutes) * (1.0 - _sunlit()) * MIST_A
	if m <= 0.0 or weather != "clear":
		return
	var hzy := _hz(g)
	var sx := _sun_at(g).x
	var cool := Color(Pal.DAWN_MIST, m)
	var warm := Color(Pal.DAWN_MIST.lerp(Pal.SUN_RIM, 0.7 * smoothstep(SUNRISE - 30.0, SUNRISE + 5.0, minutes)), m)
	for side: float in [g.position.x, g.end.x]:   # do alto, sumindo para cima, ao horizonte e dele ao chão, sumindo para baixo
		_fill(PackedVector2Array([Vector2(side, hzy - 12.0), Vector2(sx, hzy - 12.0), Vector2(sx, hzy), Vector2(side, hzy)]),
			PackedColorArray([Color(cool, 0.0), Color(warm, 0.0), warm, cool]))
		_fill(PackedVector2Array([Vector2(side, hzy), Vector2(sx, hzy), Vector2(sx, hzy + 8.0), Vector2(side, hzy + 8.0)]),
			PackedColorArray([cool, warm, Color(warm, m * 0.3), Color(cool, m * 0.3)]))


## A cor `c` de uma luz do sol na cidade, dividida pela luz do dia que a clareia (`_day`): multiplicado por ele (~2 às
## 5h40), o laranja estourava no vermelho e no verde e saía amarelo-cáqui.
func _sunny(c: Color) -> Color:
	return Color(c.r / _day.r, c.g / _day.g, c.b / _day.b, c.a)


## A luz do sol `c` lá fora agora (`_sunny`): a do nascer, clareando com ele subindo para a do dia (`SUN_PALE`).
func _sun_tint(c: Color) -> Color:
	return _sunny(c.lerp(Pal.SUN_HIGH, SUN_PALE * smoothstep(SUNRISE, DAWN.y, minutes)))


## Onde começa o degradê do céu (`_draw_sky`): no alto do céu à vista (acima, o vidro acaba) ou, de noite, só nos 50 de
## baixo.
func _sky_from(g: Rect2) -> float:
	return lerpf(_hz(g) - 50.0, g.position.y + (g.size.y + _near) * _glass_from, smoothstep(0.0, 0.3, dawn()))


## A cor do céu na altura `y` da vista (o degradê do `_draw_sky`, nos tons de `_sky_stops`).
func _sky_at(g: Rect2, y: float) -> Color:
	var stops := _sky_stops()
	var t := inverse_lerp(_sky_from(g), _hz(g), y)
	for j in 3:
		if t <= Pal.DAWN_STOPS[j + 1]:
			return stops[j].lerp(stops[j + 1], clampf(inverse_lerp(Pal.DAWN_STOPS[j], Pal.DAWN_STOPS[j + 1], t), 0.0, 1.0))
	return stops[3]


## O amanhecer no lado do sol: o clarão no horizonte crescendo antes dele e, das 5h25, o disco subindo de trás da
## igreja, com o halo (na frente da cidade, os raios e os reflexos da lente ficam na camada `_rays`, `_draw_rays`).
func _draw_dawn(g: Rect2, hzy: float) -> void:
	var d := dawn()
	if d <= 0.0:
		return
	var sun := _sun_at(g)
	var sky_h := hzy - g.position.y
	var glow := smoothstep(0.25, 0.7, d) * (1.0 - _day_sky())   # (o laranja por cima do azul do dia o deixava cinza)
	var low := Vector2(sun.x, hzy)
	_light_fan(low, PackedVector2Array(Array(_ring(Vector2.ZERO, 1.0)).map(func(p: Vector2) -> Vector2: return low + p * Vector2(g.size.x * 0.7, sky_h * 0.8))),
		Color(Pal.DAWN_GLOW, 0.55 * glow))
	if minutes >= SUNRISE - 2.0:
		var day := _day_sky()   # (de dia, o halo encolhe e o céu fica azul em volta)
		_light_fan(sun, _ring(sun, SUN_R * lerpf(3.0, 2.2, day)), Color(Pal.SUN.lerp(Pal.SUN_CORE, day), lerpf(0.45, 0.3, day)))   # (curto: o sol pequeno e nítido; amarelo, sem o laranja da beira, a pedido)
		_light_fan(sun, _ring(sun, SUN_R * 1.5), Color(Pal.SUN, 0.7))
	if minutes < SUNRISE - 2.0:
		return
	var d2 := int(SUN_R * SUN_DISC * 4.0)   # o disco em px da tela (1x1): o miolo branco, a passagem e o amarelo, sem beira (a laranja saiu, a pedido)
	_ci.draw_set_transform(Vector2.ZERO)
	PixelArt.sprite(_ci, PixelArt.disc(d2, [[d2 * 0.47, Pal.SUN_CORE], [d2 * 0.49, Pal.SUN_CORE.lerp(Pal.SUN, 0.5)],
		[d2 * 0.5, Pal.SUN]]), (sun * 2.0).round())
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	_light_fan(sun, _ring(sun, SUN_R * SUN_DISC * SUN_GLOW.x), Color(Pal.SUN_CORE, SUN_GLOW.y))   # o brilho saindo dele por cima da beira, esmaecendo


## Na frente da vista, somados (na camada `_rays`, `_draw_view_rays`): com o sol à vista (`_sun_seen`), os reflexos na
## linha do sol ao meio da vista (o brilho dele por cima da igreja saiu: ela está na frente dele).
func _draw_rays(g: Rect2) -> void:
	if dawn() <= 0.0 or weather != "clear" or minutes < SUNRISE - 2.0:
		return
	var sun := _sun_at(g)
	var hzy := _hz(g)
	var parts := _church_parts(_church_pos(g))
	var seen := _sun_seen(parts, sun, hzy)
	if seen <= 0.0:
		return
	var mid := g.get_center()
	_ci.draw_set_transform(Vector2.ZERO)
	for k in FLARES.size():   # os reflexos: discos lisos na linha do sol ao meio da vista e além
		var f: Vector3 = FLARES[k]
		var at := sun + (mid - sun) * f.x
		var d := int(f.y * 2.0) * 2
		var apart := smoothstep(SUN_R, SUN_R * 2.5, at.distance_to(sun))   # (em cima do sol, às 6h perto do meio, parecia um segundo sol)
		PixelArt.sprite(_ci, PixelArt.disc(d, [[d / 2.0, Color(Pal.FLARE[k % Pal.FLARE.size()], f.z)]]), (at * 2.0).round(), Color(1, 1, 1, seen * apart))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## Os raios crepusculares no céu (embaixo da cidade, por cima do halo do sol): feixes largos e lisos saindo do sol,
## a força variando devagar com o ângulo, e onde a igreja tapa o sol (`_church_cover`) a sombra dela, escura (`Pal.RAY_SHADOW`,
## `CHURCH_SHADOW`): com o sol atrás da torre, a ponta e a cruz deixam feixes escuros no meio dos claros, a forma da
## igreja nos raios. Fracos antes de o sol nascer, fortes com ele atrás dela e quase sumindo quando ele passa da cruz.
func _draw_crepuscular(g: Rect2, sun: Vector2, hzy: float) -> void:
	var parts := _church_parts(_church_pos(g))
	var force := smoothstep(SUNRISE - 20.0, SUNRISE + 5.0, minutes) * (1.0 - 0.9 * smoothstep(SUNRISE + 20.0, DAWN.y, minutes))
	if force <= 0.0:
		return
	var far := (hzy - g.position.y) * 1.6
	var r0 := SUN_R * SUN_DISC   # (da beira do disco: por cima dele, a sombra o manchava)
	var step := (PI + 0.4) / RAYS
	var cover := PackedFloat32Array()
	for i in RAYS + 1:
		cover.append(_church_cover(parts, sun, -PI - 0.2 + i * step))
	var near := PackedVector2Array()
	var ends := PackedVector2Array()
	var cols := PackedColorArray()
	for i in RAYS + 1:   # um leque de fatias, cada beira com a sua cor: o raio vai clareando e escurecendo sem riscas
		var a := -PI - 0.2 + i * step
		var dark := (cover[maxi(i - 1, 0)] + cover[i] * 2.0 + cover[mini(i + 1, RAYS)]) / 4.0   # (alisada)
		var shine := clampf(0.5 + 0.32 * sin(a * 11.0 + 0.7) + 0.18 * sin(a * 27.0 + 2.3), 0.0, 1.0)
		shine *= shine   # (feixes largos com vãos entre eles)
		near.append(sun + Vector2.from_angle(a) * r0)
		ends.append(sun + Vector2.from_angle(a) * far * lerpf(0.55, 1.0, shine))
		cols.append(Color(Pal.SUN_RAY, RAY_A * force * shine).lerp(Color(Pal.RAY_SHADOW, CHURCH_SHADOW * force), dark))
	for i in RAYS:
		_fill(PackedVector2Array([near[i], near[i + 1], ends[i + 1], ends[i]]),
			PackedColorArray([cols[i], cols[i + 1], Color(cols[i + 1], 0.0), Color(cols[i], 0.0)]))


## Quanto do sol está à vista (0 escondido atrás da igreja ou do horizonte, 1 inteiro): pontos do disco fora dela.
func _sun_seen(parts: Array, sun: Vector2, hzy: float) -> float:
	var n := 0
	for i in 12:
		var p := sun + Vector2.from_angle(TAU * i / 12.0) * SUN_R * 0.8
		if p.y < hzy and not _in_church(parts, p):
			n += 1
	return n / 12.0


## Quanto do sol a igreja tapa na direção `a` (0 nada, 1 tudo): os pontos do meio dele até a beira do halo, nessa
## direção, que caem nela. Como o desfoque radial dos raios de luz dos jogos: a torre e a cruz, na frente do disco,
## tapam a luz que sai para cima, e para os lados ela passa.
func _church_cover(parts: Array, sun: Vector2, a: float) -> float:
	var dir := Vector2.from_angle(a)
	var n := 0
	for k in COVER_STEPS:
		if _in_church(parts, sun + dir * SUN_R * 1.5 * (k + 0.5) / COVER_STEPS):
			n += 1
	return float(n) / COVER_STEPS


func _in_church(parts: Array, p: Vector2) -> bool:
	for part: PackedVector2Array in parts:
		if Geometry2D.is_point_in_polygon(p, part):
			return true
	return false


## A silhueta da igreja de pé em `base` (na escala dela, `CHURCH_K`): nave, telhado, torre, ponta e cruz, como
## polígonos (desenhados por `_draw_church` e usados pelos raios do amanhecer, `_church_cover`).
func _church_parts(base: Vector2) -> Array:
	var k := CHURCH_K
	base.x = floorf(base.x / PX) * PX + PX / 2.0   # o eixo no meio de um pixel: a torre, a ponta e a cruz simétricas nele
	var half := func(w: float) -> float: return (roundf(w / PX - 0.5) + 0.5) * PX   # meia largura de um número ímpar de pixels
	var box := func(x: float, y: float, w: float, h: float) -> PackedVector2Array:
		return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])
	var tw: float = half.call(3.5 * k)
	var sw: float = half.call(4.5 * k)
	var tower := CHURCH_TOWER.x * k
	var top := Vector2(base.x, roundf((base.y - CHURCH_TOWER.y * k) / PX) * PX)   # a ponta da torre, presa ao pixel
	return [box.call(base.x - 17 * k, base.y - 2 * PX, 34 * k, 2 * PX),   # o adro: a escadaria, dois degraus
		box.call(base.x - 14 * k, base.y - 4 * PX, 28 * k, 2 * PX),
		box.call(base.x - 12 * k, base.y - 18 * k, 24 * k, 18 * k),
		PackedVector2Array([base + Vector2(-13, -18) * k, base + Vector2(0, -26) * k, base + Vector2(13, -18) * k]),
		box.call(base.x - tw, base.y - tower, 2 * tw, tower - 18 * k),
		PackedVector2Array([Vector2(base.x - sw, base.y - tower), top, Vector2(base.x + sw, base.y - tower)]),
		box.call(top.x - PX / 2.0, top.y - 2.5, PX, 3.0),   # a cruz: a haste entra na ponta, e os braços ficam no alto dela
		box.call(top.x - 2.5 * PX, top.y - 1.5, 5 * PX, PX)]


## A cidade lá fora (na camada `_back`, por cima do céu, `_draw_sky`): a de longe, a igreja, a rua, as paredes da rua do
## cruzamento e os prédios de lá, com as luzes deles.
func _draw_city(g: Rect2) -> void:
	var wx := g.position.x
	var wy := g.position.y
	var fog := weather == "fog"
	var hzy := _hz(g)
	var hz := _sky_tones()[1]
	if hzy - wy < 40.0:   # (a tela ainda não se arrumou: o vidro ainda não tem o tamanho dele)
		return
	if _city_for != g.size:
		_build_city(g.size)
	var house := Pal.CITY_FAR[1] if fog else Pal.CITY_FAR[0]
	# bem longe: a cidade no fim da rua do cruzamento (os prédios de lá escondem o resto), em três planos na névoa, do
	# mais longe ao mais perto (`FAR_ROWS`), cada um mais apagado no ar (a cor do horizonte; de dia, sem a luz do dia
	# por cima, para o de longe sumir no céu de verdade)
	var air := _sunny(hz)
	# o chão, do horizonte para baixo, antes do que fica de pé nele (depois, cobria o pé da igreja e a escadaria: uma
	# faixa escura entre o fim da rua do cruzamento e o horizonte; desenhar a igreja depois da rua quebrava o lote, de
	# 380 para 860 chamadas)
	_poly(PackedVector2Array([Vector2(wx, hzy), Vector2(g.end.x, hzy), Vector2(g.end.x, g.end.y + _near), Vector2(wx, g.end.y + _near)]),
		(Pal.ASPHALT_TONES[1 if fog else 0] as Array)[Pal.STREET_MID])
	var flicked := 0
	var gap := Vector2.ONE * _church_pos(g).x + SUN_R * Vector2(0.3, SUN_LOW.x + 1.2)   # os prédios altos abrem um vão onde o sol nasce, ao lado da torre
	for r in [0, 2, 1]:
		var z: float = FAR_ROWS[r].x
		var haze: float = minf(1.0, FAR_ROWS[r].y * (1.4 if fog else 1.0) + 0.15 * _sunlit())
		var base := _o(g, 0.0, z).y
		var col := house.lerp(air, haze)
		for b in _city:
			if b["row"] != r or (r == 2 and wx + b["x"] < gap.y and wx + b["x"] + b["w"] > gap.x):
				continue
			_r(wx + b["x"], base - b["h"], b["w"], b["h"], col)
			for p in b["lit"]:
				if minutes >= p.z:
					continue
				flicked += 1
				if flick and flicked % 3 == 0:
					continue
				_r(wx + b["x"] + p.x, base - b["h"] + p.y, PX, PX, (Pal.CITY_LIT[int(p.x + p.y) % Pal.CITY_LIT.size()] as Color).lerp(air, haze * 0.7))
	# o chão (a rua do cruzamento indo embora, a rua passando na frente, as calçadas e os meios-fios), as luzes nele
	_draw_church(g, house.lerp(air, 0.25).lerp(_sunny(Pal.CHURCH_DAWN), _sunlit()))   # (contra o sol, arroxeada e da força de antes: mais escura, sumia nos prédios atrás)
	_draw_street(g, hz)


## O que fica em pé na cidade (na camada `_upright`, por cima da luz do sol no chão, `_draw_sun_strip`): os postes da
## rua do cruzamento, a sombra do nosso prédio na rua de perto, a chuva e a neblina no chão, as paredes da rua do
## cruzamento e as fachadas de lá.
func _draw_city_upright(g: Rect2) -> void:
	if _city_for != g.size:   # (`_draw_city` ainda não montou a cidade)
		return
	var fog := weather == "fog"
	var hz := _sky_tones()[1]
	var ff: float = STREET["far"]
	# perto, embaixo da janela, a rua some na sombra do nosso prédio, lisa e sem nenhuma linha
	var dark := Color(0, 0, 0, 0.6)
	_fill(_patch(g, -80.0, 80.0, 0.3, STREET["curb"] + 1.5), PackedColorArray([dark, dark, Color(dark, 0.0), Color(dark, 0.0)]))
	if weather == "rain" or morning() > 0.0:   # (de manhã, o asfalto úmido do sereno; as vitrines, na frente da vista, `_draw_city_front`)
		_draw_wet(g, {}, 1.0 if weather == "rain" else 2.0 * DAMP)
	if dawn() > 0.0 and weather == "clear":
		_draw_puddles(g)
	_draw_dawn_mist(g)
	# o outro lado: as paredes da rua do cruzamento (de longe para perto) e as fachadas de frente, apoiadas na calçada
	var taken := {}   # os pixels das janelas finas já acesos
	for i in range(_canyon.size() - 1, -1, -1):
		_draw_canyon_wall(g, _canyon[i], hz, taken)
	# a névoa da noite na rua do cruzamento, clareando lisa para o fundo (a igreja aparece nela)
	var mouth := PackedVector2Array([_o(g, CROSSING.x, ff), _o(g, CROSSING.y, ff), _o(g, CROSSING.y, ff, 16.0), _o(g, CROSSING.x, ff, 16.0)])
	var sunk := _sunlit()   # com o sol atrás da igreja, o clarão some: por cima dela, a luz parecia atravessá-la
	if sunk < 1.0:
		_light_fan(Vector2(_o(g, (CROSSING.x + CROSSING.y) / 2.0, 200.0).x, _hz(g)), mouth,
			Color(hz.lightened(0.15).lerp(_sunny(Pal.SUN_RIM), sunk), (0.5 if fog else 0.3) * (1.0 - sunk)))
	_draw_crossing_posts(g, hz)   # (na frente das paredes: desenhados antes, elas os cobriam)
	_draw_parked(g, hz)
	for b in _houses:
		_draw_far_house(g, b, hz)
	_draw_shopfront(g)
	_draw_marquee(g)
	if _posts_on():   # a luz dos postes lavando as fachadas atrás deles, lisa
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
	var d := int(roundf(14.0 * OUT_K * lerpf(1.0, MOON_BIG, low)))   # o diâmetro (px da tela), encolhendo 1 px por vez
	var fog := weather == "fog"
	_fog_moon = Vector4.ZERO
	var shine := 0.3 + 0.7 * _moon_lit()
	var tone := Color(0.75, 0.78, 0.7).lerp(Pal.MOON_LOW, low)
	if moon.y * 2.0 + d / 2.0 > top * 2.0:   # (acima disso, já atrás da persiana)
		if fog:   # o clarão espalhado na névoa vai por cima do véu dela (`_draw_fog`, `_fog_moon`)
			_fog_moon = Vector4(moon.x, moon.y, d, shine)
		else:
			_light_fan(moon, _ring(moon, 16.0 * d / 14.0), Color(tone, 0.16 * light * shine * (1.0 - dawn())))
		_ci.draw_set_transform(Vector2.ZERO)   # a lua em pixel art, em px da tela, na fase da noite (`_moon_art`)
		var col := Pal.MOON.lerp(Pal.MOON_LOW, low).lerp(sky, maxf((1.0 - light) * 0.6, smoothstep(0.3, 1.0, dawn()) * 0.8))   # (de dia, quase some)
		PixelArt.sprite(_ci, _moon_art(_moon_age(), d), (moon * 2.0).round(), Color(col.lerp(tone, 0.4), FOG_MOON.w) if fog else col)
		_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	if fog:
		return
	for c in _clouds:
		var at := Vector2(g.position.x + _cloud_x(c) * g.size.x, top + c.y * sh)
		var r := Vector2(0.16 * c.z * g.size.x, 0.09 * c.z * sh)
		var lit := 1.0 - smoothstep(0.0, 1.6, ((at - moon) / r).length())   # na frente da lua, a beira pega a luz dela
		var col := sky.lightened(0.1).lerp(Pal.CLOUD_RIM, 0.12 * lit * light)
		# amanhecendo, acesas por baixo: a beira de baixo rosa, dourando com o sol, e o alto ainda frio; de dia, brancas
		var day := _day_sky()
		var tint := smoothstep(0.2, 0.6, dawn())
		var under := col.lerp(Pal.DAWN_CLOUD.lerp(Pal.SUN_RIM, 0.5 * _sunlit()).lerp(Pal.DAY_CLOUD, day), tint)
		col = col.lerp(Pal.DAWN_CLOUD_TOP.lerp(Pal.DAY_CLOUD, day), tint)
		for k in 3:   # três manchas juntas, a do meio maior
			var o := at + Vector2((k - 1) * r.x * 0.55, (k % 2) * -r.y * 0.25)
			var size := Vector2(r.x * (0.9 if k == 1 else 0.6), r.y * (1.0 if k == 1 else 0.7))
			for layer in ([1, 0] if tint > 0.0 else [0]):   # a de baixo um pouco mais baixa, para sobrar a beira dela
				var mid := o + Vector2(0, size.y * 0.3 * layer)
				var rim := PackedVector2Array()
				for i in 12:
					rim.append(mid + Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0)) * size)
				_light_fan(mid, rim, Color(under if layer else col, 0.85))


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
	if weather == "rain" or morning() > 0.0:   # a vitrine do bar e a porta do hotel, sempre acesas, no asfalto molhado: aqui, e não no chão, porque o carro passando na frente as tapa (`_mirror`)
		var a := 1.0 if weather == "rain" else 2.0 * DAMP
		_mirror(g, CROSSING.y + 0.5, CROSSING.y + 2.5, 2.5, _sunny(Pal.BAR_LIGHT[1]), a)
		_mirror(g, HOTEL_X - 0.6, HOTEL_X + 0.6, 2.3, _sunny(Pal.HOTEL_DOOR[1]), a)
	_draw_hotel_sign(_hotel_pos(g))
	_draw_balcony_front(g)
	_draw_bar_door(g)
	_draw_behind(g)
	_draw_phones(g)
	_draw_cat(g)
	_draw_guest(g)
	for w: Dictionary in _walkers:   # passam atrás dos postes e do homem
		_draw_walker(g, w)
	for x: float in FAR_LAMPS:
		_draw_lamp_post(g, x, STREET["far_curb"] + 0.4)
	if weather == "clear" and _posts_on():
		_draw_moths(g)
	var mx := _man_x()
	if not is_nan(mx):
		_draw_stranger(g, mx)
	_cars.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["lane"] < b["lane"])   # o de lá primeiro
	for c in _cars:
		if weather == "rain" or morning() > 0.0:
			_draw_wet(g, c, 1.0 if weather == "rain" else DAMP)
		var cx := _car_x(c)   # a sombra comprida dele, na faixa de sol
		var back: float = cx - CAR_LANES[c["lane"]].y * CAR_KINDS[c["kind"]]["len"]
		_sun_shadow(g, minf(cx, back), maxf(cx, back), CAR_LANES[c["lane"]].x - 0.8, 1.4)
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
	var a := _clearing()   # (abrindo, o véu e as luzes nele somem aos poucos)
	var base := _o(g, 0.0, ff).y   # o pé das fachadas de lá
	var high := _o(g, 0.0, ff, 3.0).y
	var x0 := g.position.x
	var x1 := g.end.x
	var y1 := g.end.y + _near   # até o pé do vidro: a rua de perto também
	_r(x0, g.position.y, g.size.x, y1 - g.position.y, Color(FOG, FOG_VEIL * a))
	_fill(PackedVector2Array([Vector2(x0, high), Vector2(x1, high), Vector2(x1, base), Vector2(x0, base)]),
		PackedColorArray([Color(FOG, 0.0), Color(FOG, 0.0), Color(FOG, FOG_GROUND * a), Color(FOG, FOG_GROUND * a)]))
	_fill(PackedVector2Array([Vector2(x0, base), Vector2(x1, base), Vector2(x1, y1), Vector2(x0, y1)]),
		PackedColorArray([Color(FOG, FOG_GROUND * a), Color(FOG, FOG_GROUND * a), Color(FOG, FOG_GROUND * 0.4 * a), Color(FOG, FOG_GROUND * 0.4 * a)]))
	if _fog_moon.z > 0.0:   # a lua na névoa: a luz dela espalhada num clarão largo e liso, mais forte no meio
		var m := Vector2(_fog_moon.x, _fog_moon.y)
		var tone := Color(0.8, 0.82, 0.76)
		_light_fan(m, _ring(m, 16.0 * _fog_moon.z / 14.0 * FOG_MOON.x), Color(tone, FOG_MOON.y * _fog_moon.w * a))
		_light_fan(m, _ring(m, 9.0 * _fog_moon.z / 14.0), Color(tone.lightened(0.4), FOG_MOON.z * _fog_moon.w * a))
	for k in FOG_WISPS:   # cada um na sua distância, altura, tamanho e velocidade, sempre os mesmos
		var z := lerpf(STREET["curb"] + 1.0, ff, fmod(k * 0.37, 1.0))
		var c := _o(g, fposmod(k * 13.7 + _mist * (0.08 + (k % 3) * 0.03), 70.0) - 35.0, z, 0.3 + fmod(k * 0.53, 1.0) * 1.6)
		var rx := OUT_F * (5.0 + (k % 4) * 1.5) / z
		var ry := OUT_F * (0.5 + (k % 3) * 0.25) / z
		var rim := PackedVector2Array()
		for i in 16:
			rim.append(c + Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * ry))
		_light_fan(c, rim, Color(FOG, 0.14 * a))
	if _posts_on():
		var heads := _lamp_heads(g)
		var lit := Color(1.0, 0.85, 0.55, 0.14 * a)
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
			_light_fan(h, halo, Color(lit, 0.22 * a))
	if _sign_on():
		var sc := _hotel_pos(g) + SIGN / 2.0
		var glow := PackedVector2Array()
		for k in 20:
			glow.append(sc + Vector2(cos(TAU * k / 20.0) * 12.0, sin(TAU * k / 20.0) * 24.0) * OUT_K)
		_light_fan(sc, glow, Color(Pal.SIGN_RED, 0.12 * a))


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
## é menor: tudo vai para o ponto de fuga).
func _taxi_mid() -> float:
	return (HOTEL_X - 1.4) * CAR_LANES[0].x / STREET["far"]


## A rua toda na sombra dos prédios de lá e o sol entrando pela rua do cruzamento e atravessando a nossa, numa faixa,
## como luz e não como tinta: a sombra na camada que multiplica (`add` falso, `_street_mul`) e a faixa na somada
## (`_street_add`), entre o chão (`_draw_street`) e o que fica em pé nele (`_draw_city_upright`). Pintadas por cima, elas
## cobriam a textura da rua (a faixa ficava chapada, só com as rachaduras riscando) e o amarelo translúcido ficava
## cáqui. As cores são as da pintura que foi ajustada à vista, passadas a luz por `_lit`.
func _draw_sun_strip(g: Rect2, add: bool) -> void:
	var sun := _sunlit()
	if sun <= 0.0:
		return
	var base: Color = Pal.ASPHALT_TONES[1 if weather == "fog" else 0][Pal.STREET_MID]
	var wide := 80.0
	var ff: float = STREET["far"]
	var high := smoothstep(SUNRISE, DAWN.y, minutes)   # (o sol subindo: o céu enche a sombra e a faixa se apaga no dia, `SUN_FADE`)
	var shade := Color(Pal.DAWN_SHADOW, STREET_SHADE * sun * lerpf(1.0, SUN_FADE.y, high))   # (azul-violeta: preta, apagava a rua)
	var shade_at := func(z: float) -> Color:
		var k := lerpf(SHADE_DEPTH.x, 1.0, z / ff) if z <= ff else lerpf(1.0, SHADE_DEPTH.y, smoothstep(ff, 130.0, z))
		return Color(shade, minf(1.0, shade.a * k))
	# a luz é a da cor já sem a luz do dia por cima (`_sunny`), que a levava ao amarelo-cáqui; ao longo da faixa, mais
	# clara e dourada na boca do cruzamento, onde o sol bate em cheio (`STRIP_MOUTH`), e mais vermelha e mais fraca para
	# cá, sumindo no longe
	var lit := Color(_sun_tint(Pal.SUN_STREET), STRIP_A * sun * lerpf(1.0, SUN_FADE.x, high))
	var near := Color(lit.lerp(_sun_tint(Pal.SUN_DEEP), STRIP_NEAR), lit.a * 0.4)
	var mouth := Color(lit.lerp(_sun_tint(Pal.SUN_RIM), STRIP_MOUTH.x), minf(1.0, lit.a * STRIP_MOUTH.y))
	var light_at := func(z: float) -> Color:
		if z <= ff:
			return near.lerp(mouth, clampf((z - 1.0) / (ff - 1.0), 0.0, 1.0))
		return mouth.lerp(Color(lit, 0.0), (z - ff) / (130.0 - ff))
	# os trechos ao longo dela, cada um com a altura da parede da direita que faz sombra nele (a da esquina na nossa
	# rua): a beira da sombra muda de prédio para prédio
	var segs: Array[Vector3] = []   # (de, até, a altura da parede)
	for w: Dictionary in _canyon:   # (por z, de perto para longe)
		if w["x"] > 0.0:
			if segs.is_empty():
				segs.append(Vector3(0.3, ff, w["h"]))
			if w["z1"] > ff and w["z0"] < 130.0:
				segs.append(Vector3(maxf(w["z0"], ff), minf(w["z1"], 130.0), w["h"]))
	if segs.is_empty():
		segs.append(Vector3(0.3, 130.0, 0.0))
	elif segs[-1].y < 130.0:
		segs.append(Vector3(segs[-1].y, 130.0, segs[-1].z))
	for sg in segs:
		# as beiras esmaecem da luz à sombra, sem degrau (`STRIP_SOFT`), a da sombra da parede mais larga quanto mais
		# comprida ela é (a luz de um sol baixo chega espalhada)
		var w := _wall_shade(g, sg.z)
		var a := CROSSING.x + STRIP_EDGE
		var b := CROSSING.y - STRIP_EDGE - w
		var sa := STRIP_SOFT.x
		var sb := STRIP_SOFT.x + STRIP_SOFT.y * w
		var mid := (a + b) / 2.0
		# a sombra: junto da faixa, a luz rebatida dela, quente (`BOUNCE_SHADE`); de resto mais escura perto e mais clara
		# no longe, no ar (`SHADE_DEPTH`)
		var bw := BOUNCE_SHADE.x
		var xs := [-wide, a - sa - bw, a - sa, minf(a + sa, mid), maxf(b - sb, mid), b + sb, b + sb + bw, wide]
		var ts := [0.0, 0.0, 2.0, 1.0, 1.0, 2.0, 0.0, 0.0]   # (0 sombra, 2 a sombra quente, 1 luz)
		for i in 7:
			var cols := PackedColorArray()
			for k in [[i, sg.x], [i + 1, sg.x], [i + 1, sg.y], [i, sg.y]]:
				var t: float = ts[k[0]]
				var z: float = k[1]
				var sh: Color = shade_at.call(z)
				var c: Color = light_at.call(z)
				if t == 2.0:
					c = Color(sh.lerp(_sun_tint(Pal.SUN_DEEP), BOUNCE_SHADE.y), sh.a * 0.8)
				else:
					c = Color(sh.lerp(c, t), lerpf(sh.a, c.a, t))
				cols.append(c)
			_lit(PackedVector2Array([_o(g, xs[i], sg.x), _o(g, xs[i + 1], sg.x), _o(g, xs[i + 1], sg.y), _o(g, xs[i], sg.y)]), cols, base, add)
	if not add:
		# o escuro junto do meio-fio de lá e dos do cruzamento, onde a luz do céu chega menos
		var ao := Color(Pal.DAWN_SHADOW, SHADE_CORNER * sun)
		var clear := Color(ao, 0.0)
		var fc: float = STREET["far_curb"]
		for span: Vector2 in [Vector2(-wide, CROSSING.x), Vector2(CROSSING.y, wide)]:
			_lit(_patch(g, span.x, span.y, fc - 0.8, fc), PackedColorArray([clear, clear, ao, ao]), base, false)
		for curb: Vector2 in [Vector2(CROSSING.x + 1.8, 0.6), Vector2(CROSSING.y - 1.8, -0.6)]:
			_lit(_patch(g, curb.x, curb.x + curb.y, ff, 60.0), PackedColorArray([ao, clear, clear, Color(ao, 0.0)]), base, false)
	if add:
		_draw_glints(g, segs, sun)


## O sol espelhado no asfalto úmido do sereno, como na referência do usuário: embaixo dele na tela (o reflexo de uma
## luz longe num chão liso cai na vertical dela), numa coluna larga para cá, forte no fundo e mais fraca perto de nós.
## Brilham as marcas dos pneus, lisas e úmidas (`TRACKS_FAR`: fios indo embora pela rua do cruzamento, quebrados onde
## o asfalto secou; `TRACKS_NEAR`: riscos de lado na nossa), e o resto do asfalto só de leve (`GLINT_BASE`); só onde a
## faixa está acesa (`segs`, a sombra da parede da direita pela altura de cada um). (Em brilhos curtos sorteados, saía
## um confete branco; numa coluna só, quebrada em faixas, manchas ovais que não vinham de nada da rua.)
func _draw_glints(g: Rect2, segs: Array[Vector3], sun: float) -> void:
	var at := _sun_at(g)
	var hz := _hz(g)
	var y1 := _o(g, 0.0, 1.0).y
	var hot := _sunny(Pal.SUN_CORE)
	var warm := _sun_tint(Pal.SUN_RIM)
	var fc: float = STREET["far_curb"]
	var tw := TRACK_W / 2.0
	var shades: Array[float] = []   # (uma vez por trecho: a cada linha, a conta do sol pesava no redesenho)
	for sg in segs:
		shades.append(_wall_shade(g, sg.z))
	var y := hz + PX
	while y < y1:
		var z := OUT_F * OUT_EYE / (y - hz)
		var top := y
		y += PX
		var near := clampf((top - hz) / (y1 - hz), 0.0, 1.0)   # (0 no horizonte, 1 perto de nós)
		var wide := GLINT.x + GLINT.y * (top - hz)   # (a meia largura da coluna na tela)
		var a := sun * GLINT_A * (1.0 - 0.75 * near)
		var shade := 0.0
		for i in segs.size():
			if z >= segs[i].x and z < segs[i].y:
				shade = shades[i]
		var lo := _o(g, CROSSING.x + STRIP_EDGE, z).x
		var hi := _o(g, CROSSING.y - STRIP_EDGE - shade, z).x
		var mid := at.x
		var c := Color(warm.lerp(hot, 0.6 * (1.0 - near)), a)
		var band := func(x0: float, x1: float, k: float) -> void:   # (um trecho da linha, esmaecendo pela distância da coluna)
			x0 = maxf(x0, lo)
			x1 = minf(x1, hi)
			if x1 <= x0:
				return
			var k0 := exp(-2.0 * pow((x0 - mid) / wide, 2.0)) * k
			var k1 := exp(-2.0 * pow((x1 - mid) / wide, 2.0)) * k
			_fill(PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, y), Vector2(x0, y)]),
				PackedColorArray([Color(c, a * k0), Color(c, a * k1), Color(c, a * k1), Color(c, a * k0)]))
		band.call(mid - wide * 2.0, mid, GLINT_BASE)
		band.call(mid, mid + wide * 2.0, GLINT_BASE)
		if z > fc:
			for i in TRACKS_FAR.size():
				var x: float = TRACKS_FAR[i]
				var wet := smoothstep(0.35, 0.8, 0.5 + 0.5 * sin(z * GLINT_WAVES.x + i * 1.7) * sin(z * GLINT_WAVES.y + i * 2.9))
				wet = lerpf(wet, 0.25, smoothstep(0.5, 2.0, (z - OUT_F * OUT_EYE / (y - hz)) * GLINT_WAVES.x))   # (no longe, uma linha passa por vários trechos: a média deles, não pontos soltos)
				if wet > 0.0:
					var x0 := _o(g, x - tw * 0.7, z).x
					band.call(x0, maxf(_o(g, x + tw * 0.7, z).x, x0 + PX), 1.3 * wet)
		else:
			for tz: float in TRACKS_NEAR:
				if absf(z - tz) < tw * 0.6:
					band.call(mid - wide * 1.5, mid + wide * 1.5, 0.8)


## A sombra da parede da direita da rua do cruzamento na faixa de sol, em m de lado por m de altura dela: o sol fica um
## pouco à direita do eixo da rua (`SUN_LOW`), e a luz, vindo de lado, deixa o alto da parede no chão, para a esquerda.
## Por um ponto a h m do chão, a sombra anda h·dx/dy de lado (dx e dy: o sol na tela a partir do ponto de fuga da rua;
## dx o das 6h: com o de agora, que sai do eixo da rua, a sombra crescia logo depois de ele nascer e depois voltava).
## ponytail: na nossa rua, a beira devia ir um pouco para a esquerda, vindo para cá.
func _wall_ratio(g: Rect2) -> float:
	var vp := _o(g, 0.0, 1.0e4)
	var dx := _church_pos(g).x + SUN_R * SUN_LOW.x - vp.x
	var dy := vp.y - _sun_at(g).y
	if dx <= 0.0:
		return 0.0
	return 1.0e3 if dy <= 0.0 else dx / dy


## A sombra no chão de algo de `h` m de pé na rua do cruzamento (m para a esquerda, `_wall_ratio`): rente ao
## horizonte, quase a faixa toda (sobra 1 m de sol), e só encolhendo com o sol subindo (crescendo antes, a partir de
## nenhuma, ela ia e voltava).
func _wall_shade(g: Rect2, h: float) -> float:
	return minf(h * _wall_ratio(g), CROSSING.y - CROSSING.x - 2.0 * STRIP_EDGE - 1.0)


## Onde a faixa de sol acaba, à direita, em `z` (m): na sombra da parede da direita que está ali (num vão, a de antes).
func _strip_end(g: Rect2, z: float) -> float:
	var h := 0.0
	for w: Dictionary in _canyon:   # (por z, de perto para longe)
		if w["x"] > 0.0 and (h == 0.0 or w["z0"] <= z):
			h = w["h"]
	return CROSSING.y - STRIP_EDGE - _wall_shade(g, h)


## Uma pintura (`cols`: a cor e a força com que ela iria por cima de `base`) passada a luz: o quanto ela multiplica o que
## está embaixo (na camada que multiplica) ou o quanto soma (`add`, na somada), para dar a mesma cor em cima de `base` e
## manter as manchas e o grão de baixo. Por canal: a pintura dá b(1 - a) + c·a = b·L; até 1, L multiplica, e o que
## passa de 1 é somado, b(L - 1) = a(c - b) (a somada leva a luz do dia, como o chão).
func _lit(pts: PackedVector2Array, cols: PackedColorArray, base: Color, add: bool) -> void:
	var out := PackedColorArray()
	for c in cols:
		if add:
			out.append(Color(maxf(c.a * (c.r - base.r), 0.0), maxf(c.a * (c.g - base.g), 0.0), maxf(c.a * (c.b - base.b), 0.0)))
		else:
			out.append(Color(minf(1.0 - c.a + c.a * c.r / base.r, 1.0), minf(1.0 - c.a + c.a * c.g / base.g, 1.0),
				minf(1.0 - c.a + c.a * c.b / base.b, 1.0)))
	_fill(pts, out)


## Os postes da rua do cruzamento, menores e mais juntos com a distância, com a sombra comprida no sol.
func _draw_crossing_posts(g: Rect2, hz: Color) -> void:
	var sun := _sunlit()
	var cast := Vector2(-_wall_shade(g, 5.0), -5.0 * _shadow_k())   # (de lado e para cá, como a da parede da direita)
	cast *= minf(1.0, POST_UMBRA / cast.length())
	var dark := Color(Pal.RAY_SHADOW, 0.6 * SHADOW_A * sun)
	for i in 6:
		var z := 24.0 + i * 16.0
		var lit := Vector2(CROSSING.x + STRIP_EDGE, _strip_end(g, z))
		for x in [CROSSING.x + 1.4, CROSSING.y - 1.4]:
			var foot := _o(g, x, z)
			var head := _o(g, x, z, 5.0)
			var near := clampf(24.0 / z, 0.0, 1.0)
			_r(foot.x, head.y, PX, foot.y - head.y, Pal.LAMP_POST.lerp(hz, 1.0 - near))
			if sun > 0.0 and x > lit.x and x < lit.y:   # a sombra dele, vindo para cá, só onde há sol
				var tip := _o(g, x + cast.x, maxf(z + cast.y, STREET["far"]))
				_fill(PackedVector2Array([foot, tip, tip + Vector2(PX, 0), foot + Vector2(PX, 0)]),
					PackedColorArray([dark, Color(dark, 0.0), Color(dark, 0.0), dark]))
			if _posts_on():
				_r(head.x - PX, head.y - PX, maxf(PX, 1.5 * near), maxf(PX, near), Pal.STREET_LAMP.lerp(hz, (1.0 - near) * 0.6))
				_r(foot.x - 2.0 * near, foot.y - PX, 4.0 * near + PX, PX, Color(1.0, 0.85, 0.55, 0.2 * near))


## O chão da rua do cruzamento, como o da nossa: manchas e remendos com a junta acesa, a tampa do bueiro, rachaduras ao
## comprido, a mancha de óleo embaixo do carro estacionado, a sarjeta escura junto dos meios-fios, a face deles virada
## para a rua (a da esquerda, virada para o sol, acesa) e as juntas das lajotas das calçadas; tudo no ar da distância
## e só até onde ainda cabe um pixel (`CROSS_DETAIL`).
func _draw_crossing_ground(g: Rect2, road: Array, walks: Array, hz: Color) -> void:
	var fc: float = STREET["far_curb"]
	var ff: float = STREET["far"]
	var l0 := CROSSING.x + 1.8   # (o meio-fio da esquerda e o da direita)
	var l1 := CROSSING.y - 1.8
	var air := func(c: Color, z: float) -> Color: return c.lerp(hz, 0.35 * clampf((z - fc) / (130.0 - fc), 0.0, 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 709
	var cut := RandomNumberGenerator.new()
	cut.seed = 711
	for i in 22:
		var z := ff + (CROSS_DETAIL - ff) * pow(rng.randf(), 1.6)   # (mais perto, onde se veem)
		var x := rng.randf_range(l0, l1 - 0.6)
		var light := rng.randf() < 0.4
		var tone: Color = road[Pal.STREET_MID + (1 if light else -1 - rng.randi_range(0, 1))]
		_convex(_blot(g, x, minf(x + rng.randf_range(0.5, 1.6), l1), z, z + rng.randf_range(1.5, 5.0), cut), Color(air.call(tone, z), rng.randf_range(0.5, 0.9)))
	var fresh: Color = road[Pal.STREET_MID - 2]
	var seam: Color = road[Pal.STREET_MID + 1]
	for i in 4:   # os remendos, com a junta de cá acesa
		var z := rng.randf_range(ff + 1.0, 36.0)
		var x := rng.randf_range(l0 + 0.3, l1 - 1.6)
		var pr := _patch(g, x, x + rng.randf_range(0.8, 1.5), z, z + rng.randf_range(1.2, 3.0))
		_poly(pr, air.call(fresh, z))
		_ci.draw_line(pr[0], pr[1], air.call(seam, z), PX)
	var lid := PackedVector2Array()   # a tampa do bueiro, no meio da rua
	for i in 10:
		var a := TAU * (i + 0.5) / 10.0
		lid.append(_o(g, CROSS_MANHOLE.x + cos(a) * 0.4, CROSS_MANHOLE.y + sin(a) * 0.4))
	_poly(lid, air.call(seam, CROSS_MANHOLE.y))
	_ci.draw_line(lid[7], lid[3], air.call(fresh, CROSS_MANHOLE.y), PX)
	for i in 4:   # as rachaduras, ao comprido, em zigue-zague
		var c := Vector2(rng.randf_range(l0 + 0.5, l1 - 0.5), rng.randf_range(ff + 0.5, 30.0))
		for k in rng.randi_range(3, 5):
			var n := c + Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(0.8, 2.0))
			_ci.draw_line(_o(g, c.x, c.y), _o(g, n.x, n.y), Color(air.call(fresh, c.y), 0.7), PX)
			c = n
	# a mancha de óleo embaixo do carro estacionado, saindo um pouco por trás
	_poly(_patch(g, PARKED.x + 0.3, PARKED.x + 1.3, PARKED.y - 0.6, PARKED.y + PARKED.z - 0.8), Color(air.call(road[Pal.STREET_MID - 2], PARKED.y), 0.7))
	for side: Vector2 in [Vector2(l0, 1.0), Vector2(l1, -1.0)]:
		# a sarjeta, mais escura e úmida, e a face do meio-fio virada para a rua
		var gut := Color(road[Pal.STREET_MID - 2], 0.75)
		_fill(_patch(g, side.x, side.x + 0.35 * side.y, fc, 130.0), PackedColorArray([gut, Color(gut, 0.0), Color(gut, 0.0), Color(air.call(gut, 130.0), 0.4)]))
		var face: Color = Pal.CURB[0]
		if side.y > 0.0:
			face = face.lerp(_sun_tint(Pal.SUN_STREET), WALL_LIT * _sunlit())
		var foot := _o(g, side.x, 130.0)   # (no longe, com 1 px de altura: mais fina, saía tracejada)
		_fill(PackedVector2Array([_o(g, side.x, ff), foot, foot - Vector2(0, PX), _o(g, side.x, ff, 0.15)]),
			PackedColorArray([face, air.call(face, 130.0), air.call(face, 130.0), face]))
	# as juntas das lajotas das calçadas do cruzamento: de lado, de 1,5 em 1,5 m, e uma ao comprido no meio
	var joint: Color = walks[Pal.STREET_MID - 1]
	for wk: Vector2 in [Vector2(CROSSING.x, l0), Vector2(l1, CROSSING.y)]:
		var z := ff + 1.5
		while z < CROSS_DETAIL:
			_ci.draw_line(_o(g, wk.x, z), _o(g, wk.y, z), air.call(joint, z), PX)
			z += 1.5
		var xm := (wk.x + wk.y) / 2.0
		_ci.draw_line(_o(g, xm, ff), _o(g, xm, CROSS_DETAIL), joint, PX)


## O carro estacionado na rua do cruzamento (`PARKED`), de traseira para nós e visto do alto: a lateral virada para o
## meio da rua, com as rodas, a traseira com as lanternas apagadas e o para-choque, a tampa do motor, a cabine com o
## vidro de trás e o teto, que pega o céu (e o sol, de manhã).
func _draw_parked(g: Rect2, hz: Color) -> void:
	var x0 := PARKED.x
	var x1 := x0 + 1.6
	var z0 := PARKED.y
	var z1 := z0 + PARKED.z
	var haze := clampf((z0 - 14.0) / 160.0, 0.0, 0.5)
	var tones: Array = Pal.CAR_TONES[1]
	var tone := func(k: int) -> Color: return (tones[Pal.CAR_MID + k] as Color).lerp(hz, haze)
	var sun := _sunlit()
	var top: Color = (tone.call(1) as Color).lerp(Pal.CAR_SKY, 0.3).lerp(_sun_tint(Pal.SUN_STREET), 0.25 * sun)
	var side := func(x: float, za: float, zb: float, h0: float, h1: float) -> PackedVector2Array:
		return PackedVector2Array([_o(g, x, za, h0), _o(g, x, zb, h0), _o(g, x, zb, h1), _o(g, x, za, h1)])
	var flat := func(xa: float, xb: float, za: float, zb: float, h: float) -> PackedVector2Array:
		return PackedVector2Array([_o(g, xa, za, h), _o(g, xb, za, h), _o(g, xb, zb, h), _o(g, xa, zb, h)])
	_poly(flat.call(x0 - 0.15, x1 + 0.1, z0 - 0.1, z1 + 0.2, 0.0), Color(0, 0, 0, 0.4))   # a sombra embaixo
	_poly(side.call(x0, z0, z1, 0.25, 0.85), tone.call(-1))   # a lateral
	for zw: float in [z0 + 0.75, z1 - 0.8]:   # as rodas
		_poly(side.call(x0, zw - 0.32, zw + 0.32, 0.0, 0.55), Pal.CAR_TYRE[1].lerp(hz, haze))
	_poly(flat.call(x0, x1, z0, z0, 0.0), tone.call(-2))   # (a traseira é a face de z0, de 0,25 a 0,85)
	_poly(PackedVector2Array([_o(g, x0, z0, 0.25), _o(g, x1, z0, 0.25), _o(g, x1, z0, 0.85), _o(g, x0, z0, 0.85)]), tone.call(-2))
	for xl: float in [x0 + 0.12, x1 - 0.3]:   # as lanternas, apagadas
		_poly(PackedVector2Array([_o(g, xl, z0, 0.6), _o(g, xl + 0.18, z0, 0.6), _o(g, xl + 0.18, z0, 0.75), _o(g, xl, z0, 0.75)]), Pal.CAR_TAIL.darkened(0.5).lerp(hz, haze))
	_ci.draw_line(_o(g, x0, z0, 0.3), _o(g, x1, z0, 0.3), Pal.CAR_CHROME.lerp(hz, 0.4 + haze), PX)   # o para-choque
	_poly(flat.call(x0, x1, z0, z1, 0.85), top)   # a tampa e o capô
	var cz0 := z0 + 1.0
	var cz1 := z1 - 1.3
	_poly(side.call(x0 + 0.15, cz0, cz1, 0.85, 1.35), Pal.CAR_GLASS.lerp(hz, haze))   # os vidros do lado
	_poly(PackedVector2Array([_o(g, x0 + 0.15, cz0, 0.85), _o(g, x1 - 0.15, cz0, 0.85), _o(g, x1 - 0.15, cz0, 1.35), _o(g, x0 + 0.15, cz0, 1.35)]), Pal.CAR_GLASS.lerp(Pal.CAR_GLINT, 0.3).lerp(hz, haze))   # o vidro de trás
	_poly(flat.call(x0 + 0.15, x1 - 0.15, cz0, cz1, 1.35), top.lightened(0.08))   # o teto


## O chão: a rua do cruzamento indo embora (com as calçadas e os postes dela, menores com a distância), a nossa calçada
## de lajotas até o meio-fio, o asfalto da rua (manchas, remendos, a tampa do bueiro, rachaduras, desgaste dos pneus nas
## duas mãos, grão perto, poças espelhando o céu e a faixa tracejada no meio, gasta), a sarjeta e o meio-fio de lá com
## a face virada para nós e as bocas de lobo, a calçada de lá e a luz dos postes no chão. Tudo no mesmo plano horizontal; só a perspectiva inclina as linhas
## que vão para longe.
func _draw_street(g: Rect2, hz: Color) -> void:
	var fog := weather == "fog"
	var road: Array = Pal.ASPHALT_TONES[1 if fog else 0]
	var walks: Array = Pal.SIDEWALK_TONES[1 if fog else 0]
	var asphalt: Color = road[Pal.STREET_MID]
	var walk: Color = walks[Pal.STREET_MID]
	var cu: float = STREET["curb"]
	var fc: float = STREET["far_curb"]
	var ff: float = STREET["far"]
	var cx0 := CROSSING.x
	var cx1 := CROSSING.y
	var wide := 80.0
	# a rua do cruzamento, indo embora até a praça da igreja, com as calçadas dela
	var far := asphalt.lerp(hz, 0.35)
	_fill(_patch(g, cx0 + 1.8, cx1 - 1.8, fc, 130.0), PackedColorArray([asphalt, asphalt, far, far]))
	for side: Vector2 in [Vector2(cx0, cx0 + 1.8), Vector2(cx1 - 1.8, cx1)]:
		_fill(_patch(g, side.x, side.y, ff, 130.0), PackedColorArray([walk, walk, walk.lerp(hz, 0.35), walk.lerp(hz, 0.35)]))
		var curb_x := side.y if side.x == cx0 else side.x
		_ci.draw_line(_o(g, curb_x, ff, 0.15), _o(g, curb_x, 130.0, 0.15), Color(hz, 0.6), PX)
	_draw_crossing_ground(g, road, walks, hz)
	# a calçada de lá, dos dois lados da boca do cruzamento (a nossa não aparece: o que encosta no nosso prédio diria
	# para que lado a nossa parede vai, e a sala já diz outra coisa)
	_poly(_patch(g, -wide, cx0, fc, ff), walk)
	_poly(_patch(g, cx1, wide, fc, ff), walk)
	# o asfalto não é liso: manchas e remendos, embaixo da luz do sol (por cima, eram blocos escuros no meio da faixa),
	# o desgaste dos pneus em cada mão, poças e o grão perto
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	var cut := RandomNumberGenerator.new()   # (a beira de cada uma num sorteio à parte: o resto fica onde estava)
	cut.seed = 710
	for i in 36:
		var x := rng.randf_range(-20.0, 20.0)
		var z := rng.randf_range(cu + 0.3, fc - 0.5)
		var light := rng.randf() < 0.5
		var a := rng.randf_range(0.015, 0.035) if light else rng.randf_range(0.1, 0.22)   # (o sorteio de sempre: as mesmas manchas)
		var tone: Color = road[Pal.STREET_MID + (1 if light else (-1 if a < 0.16 else -2))]
		_convex(_blot(g, x, x + rng.randf_range(1.0, 5.0), z, z + rng.randf_range(0.3, 1.2), cut), tone)
	var fix := RandomNumberGenerator.new()   # os remendos, de beira reta, e o resto (no sorteio deles: as manchas ficam as mesmas)
	fix.seed = 708
	var fresh: Color = road[Pal.STREET_MID - 2]
	var seam: Color = road[Pal.STREET_MID + 1]
	for i in 5:
		var x := fix.randf_range(-12.0, 12.0)
		var z := fix.randf_range(cu + 0.6, fc - 1.2)
		var r := _patch(g, x, x + fix.randf_range(1.2, 3.0), z, z + fix.randf_range(0.5, 1.0))
		_poly(r, fresh)
		_poly(PackedVector2Array([r[0], r[1], r[1] + Vector2(0, PX), r[0] + Vector2(0, PX)]), seam)   # a junta da beira de lá, que pega a luz
	var lid := PackedVector2Array()   # a tampa de ferro do bueiro, na mão de cá, com o aro e a grade em cruz
	var hole := PackedVector2Array()
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		lid.append(_o(g, MANHOLE.x + cos(a) * 0.4, MANHOLE.y + sin(a) * 0.4))
		hole.append(_o(g, MANHOLE.x + cos(a) * 0.32, MANHOLE.y + sin(a) * 0.32))
	_poly(lid, seam)
	_poly(hole, fresh)
	for k in 3:
		var x := MANHOLE.x + (k - 1) * 0.14
		_poly(_patch(g, x - 0.02, x + 0.02, MANHOLE.y - 0.24, MANHOLE.y + 0.24), seam)
	# o grão perto e as juntas entram como escuro ou claro translúcido sobre o asfalto (`over`)
	var lum := asphalt.get_luminance()
	var over := func(c: Color) -> Color:
		var l := c.get_luminance()
		return Color(0, 0, 0, 1.0 - l / lum) if l < lum else Color(1, 1, 1, (l - lum) / (1.0 - lum))
	# as marcas dos pneus, mais escuras e lisas, esmaecendo dos lados: ao longo da nossa rua e indo embora pela do
	# cruzamento, sumindo no longe (o desenho da rua no comprimento, que aparece na sombra e na luz)
	var worn := Color(road[Pal.STREET_MID - 2], TRACK_A)
	var none := Color(worn, 0.0)
	var tw := TRACK_W / 2.0
	for z: float in TRACKS_NEAR:
		_fill(_patch(g, -wide, wide, z - tw, z), PackedColorArray([none, none, worn, worn]))
		_fill(_patch(g, -wide, wide, z, z + tw), PackedColorArray([worn, worn, none, none]))
	for x: float in TRACKS_FAR:
		var gone := Color(worn, TRACK_A * 0.3)
		for side in [[x - tw, x, none, worn], [x, x + tw, worn, none]]:
			var c0: Color = side[2]
			var c1: Color = side[3]
			_fill(_patch(g, side[0], side[1], fc, 70.0), PackedColorArray([c0, c1, Color(c1, c1.a * 0.3), Color(c0, c0.a * 0.3)]))
		_fill(_patch(g, x - tw * 0.5, x + tw * 0.5, 70.0, 130.0), PackedColorArray([gone, gone, none, none]))
	var wet := 1.0 + 1.6 * _soaked() if weather == "rain" else 1.0   # as poças crescem com a noite de chuva
	for i in 12:   # as poças: espelham o céu (na chuva, mais)
		var x := rng.randf_range(-14.0, 14.0)
		var z := rng.randf_range(cu + 0.4, fc - 0.8)
		var puddle := _patch(g, x, x + rng.randf_range(1.0, 2.6), z, z + rng.randf_range(0.4, 0.9))
		_poly(puddle, Color(Color(0.45, 0.55, 0.7).lerp(_sunny(Pal.DAWN_CLOUD), 0.5 * _sunlit()), (0.05 + 0.05 * _sunlit()) * wet))   # (de manhã, o céu claro nelas: a rua ainda úmida da noite)
		_ci.draw_line(puddle[2], puddle[3], Color(0.6, 0.7, 0.85, 0.08 * wet), PX)
	for i in 6:   # as rachaduras: finas, em zigue-zague, mais na mão de cá, onde o caminhão pesa
		var c := Vector2(fix.randf_range(-12.0, 12.0), fix.randf_range(cu + 0.4, STREET["lane"]))
		var crack: Color = over.call(fresh)
		for k in fix.randi_range(3, 5):
			var n := c + Vector2(fix.randf_range(0.3, 0.8) * (1.0 if i % 2 else -1.0), fix.randf_range(-0.2, 0.2))
			var a := _o(g, c.x, c.y)
			var b := _o(g, n.x, n.y)
			_poly(PackedVector2Array([a, b, b + Vector2(0, PX), a + Vector2(0, PX)]), crack)
			c = n
	for i in 240:
		var gp := _o(g, rng.randf_range(-8.0, 8.0), rng.randf_range(cu + 0.5, 6.5))
		_r(floorf(gp.x * 2.0) * PX, floorf(gp.y * 2.0) * PX, PX, PX, over.call(road[Pal.STREET_MID + (1 if i % 2 else -1)]))
	var x0 := -wide   # a faixa tracejada no meio
	while x0 < wide:
		_poly(_patch(g, x0, x0 + 3.0, STREET["lane"] - 0.08, STREET["lane"] + 0.08), Color(0.75, 0.72, 0.6, 0.3 * fix.randf_range(0.5, 1.0)))   # (cada traço gasto do seu jeito)
		x0 += 9.0
	# as juntas das lajotas de lá: ao longo da rua (na horizontal) e para longe (para o ponto de fuga)
	var joint: Color = walks[Pal.STREET_MID - 1]
	_ci.draw_line(_o(g, -wide, fc + 1.4), _o(g, cx0, fc + 1.4), joint, PX)
	_ci.draw_line(_o(g, cx1, fc + 1.4), _o(g, wide, fc + 1.4), joint, PX)
	var xj := -30.0
	while xj < 30.0:
		if xj < cx0 or xj > cx1:
			_ci.draw_line(_o(g, xj, fc), _o(g, xj, ff), joint, PX)
		xj += 1.5
	# a sarjeta e o meio-fio de lá, com a face virada para nós, a quina e as bocas de lobo
	for seg: Vector2 in [Vector2(-wide, cx0), Vector2(cx1, wide)]:
		_poly(_patch(g, seg.x, seg.y, fc - 0.35, fc), over.call(walks[Pal.STREET_MID - 1]))   # (translúcida: o sol passa por ela)
		_poly(PackedVector2Array([_o(g, seg.x, fc), _o(g, seg.y, fc), _o(g, seg.y, fc, 0.15), _o(g, seg.x, fc, 0.15)]), Pal.CURB[0])
		_ci.draw_line(_o(g, seg.x, fc, 0.15), _o(g, seg.y, fc, 0.15), Pal.CURB[1], PX)
		if _posts_on():   # a quina pega a luz de cada poste em volta do pé dele (a face fica de costas para ele)
			for x: float in FAR_LAMPS:
				var a := maxf(seg.x, x - CURB_LIT)
				var e := minf(seg.y, x + CURB_LIT)
				if e > a:
					_ci.draw_line(_o(g, a, fc, 0.15), _o(g, e, fc, 0.15), Pal.CURB[2], PX)
	for x: float in DRAINS:
		_poly(PackedVector2Array([_o(g, x, fc, 0.02), _o(g, x + 0.9, fc, 0.02), _o(g, x + 0.9, fc, 0.12), _o(g, x, fc, 0.12)]), Color(0, 0, 0, 0.8))
	if _posts_on():   # a luz de cada poste de lá no chão, em volta do pé dele
		for x: float in FAR_LAMPS:
			var c := _o(g, x, fc - 0.2)
			var rim := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				rim.append(_o(g, x + cos(a) * 4.5, fc - 0.2 + sin(a) * 3.0))
			_light_fan(c, rim, Color(1.0, 0.85, 0.55, 0.28))


## As poças que a chuva deixou (na última noite ela para à meia-noite, `clears_at`), espelhando o céu do amanhecer: por
## cima da luz no chão (o espelho não escurece na sombra dos prédios), cada uma no céu que ela reflete (perto, o do alto,
## rosa; longe, o de baixo, laranja), com a beira de lá mais clara.
func _draw_puddles(g: Rect2) -> void:
	var stops := _sky_stops()
	var a := PUDDLE_A * smoothstep(0.2, 0.6, dawn())
	var rng := RandomNumberGenerator.new()
	rng.seed = 712
	var fc: float = STREET["far_curb"]
	for i in PUDDLES:
		var cross := i < 2   # (duas na rua do cruzamento, compridas)
		var x := rng.randf_range(CROSSING.x + 2.0, CROSSING.y - 3.0) if cross else rng.randf_range(-12.0, 12.0)
		var z := rng.randf_range(STREET["far"] + 2.0, 24.0) if cross else rng.randf_range(STREET["curb"] + 1.6, fc - 0.9)
		var p := _blot(g, x, x + rng.randf_range(0.8, 1.4) if cross else x + rng.randf_range(1.2, 3.2), z, z + (rng.randf_range(2.0, 5.0) if cross else rng.randf_range(0.4, 0.9)), rng)
		var sky := stops[1].lerp(stops[2], clampf(z / fc, 0.0, 1.0)) if not cross else stops[2].lerp(stops[3], 0.5)
		_convex(p, Color(_sunny(sky), a))
		_ci.draw_line(p[5], p[6], Color(_sunny(stops[3]), a), PX)


## Um polígono convexo (`pts`, como o de `_blot`) em quadriláteros em leque: em triângulos, como o `_poly` faz com mais
## de quatro pontos, cada mancha quebrava o lote das chamadas de desenho (a rua passava de 380 para 870 por quadro).
func _convex(pts: PackedVector2Array, col: Color) -> void:
	for i in range(1, pts.size() - 2, 2):
		_poly(PackedVector2Array([pts[0], pts[i], pts[i + 1], pts[i + 2]]), col)


## Uma mancha no chão de `x0` a `x1` e de `z0` a `z1` (m), de beira torta: o retângulo com cada canto cortado do seu
## jeito (`rng`). (Em retângulos, na faixa de sol, a rua virava uma colcha de remendos; os remendos continuam retos.)
func _blot(g: Rect2, x0: float, x1: float, z0: float, z1: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var corners := [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	var pts := PackedVector2Array()
	for i in 4:
		var c: Vector2 = corners[i]
		var p := c.lerp(corners[(i + 3) % 4], rng.randf_range(0.15, 0.45))
		var n := c.lerp(corners[(i + 1) % 4], rng.randf_range(0.15, 0.45))
		pts.append(_o(g, p.x, p.y))
		pts.append(_o(g, n.x, n.y))
	return pts


## A chuva no chão: o asfalto molhado espelha as luzes em riscos verticais, quebrados, embaixo de cada uma (os postes
## e o letreiro; com `car`, só o farol e a lanterna daquele carro, que anda: vai na frente da vista), mais fracos para
## baixo.
func _draw_wet(g: Rect2, car: Dictionary = {}, a := 1.0) -> void:
	var lights := []   # [cabeça, pé, cor]
	if not car.is_empty():
		var z: float = CAR_LANES[car["lane"]].x
		var m: Dictionary = CAR_KINDS[car["kind"]]
		var rear: float = _car_x(car) - CAR_LANES[car["lane"]].y * m["len"]
		lights.append([_o(g, _car_x(car), z - 0.9, m["lamp"]), _o(g, _car_x(car), z - 1.2), Pal.CAR_HEAD])
		lights.append([_o(g, rear, z - 0.9, m["lamp"]), _o(g, rear, z - 1.2), Pal.CAR_TAIL.lightened(0.3)])
	else:
		if _posts_on():
			for i in FAR_LAMPS.size():
				lights.append([_lamp_heads(g)[i], _o(g, FAR_LAMPS[i], STREET["far_curb"] - 0.5), Color(1.0, 0.85, 0.55)])
		if _sign_on():   # embaixo das letras (no meio da caixa; o risco tem 1,5 de largura)
			var s := _hotel_pos(g) + Vector2(SIGN.x / 2.0 - 0.25, 0.0)
			lights.append([s, Vector2(s.x - 0.75, _o(g, HOTEL_X, STREET["far_curb"] - 0.5).y), Pal.SIGN_RED])
	for l: Array in lights:
		_wet_streak(l[0], l[1], l[2], a)


## O reflexo da luz `col` (que fica em `head`) no asfalto molhado, um risco vertical quebrado descendo de `foot`.
func _wet_streak(head: Vector2, foot: Vector2, col: Color, a := 1.0) -> void:
	var length := (foot.y - head.y) * 0.9
	var n := maxi(3, int(length / 1.5))
	for k in n:
		if k % 3 == 2:
			continue   # quebrado pelas poças e pelos pingos
		_r(foot.x - PX * (k % 2), foot.y + length * k / n, maxf(PX, 1.5 - k * 0.05), PX, Color(col, 0.32 * a * (1.0 - float(k) / n)))


## O reflexo de uma abertura acesa no térreo da fachada de lá (de `x0` a `x1` m, `h` m de altura) no asfalto molhado:
## da largura dela, descendo reto do meio-fio (não para o ponto de fuga), em linhas quebradas que somem para baixo
## (num risco fino, como o dos postes, de manhã quase não se via). O carro na rua tapa o reflexo da beira de lá do chão
## dele para cá (`_car_ground`): por baixo da sombra dele, aparecia uma listra de luz (pedido 276).
func _mirror(g: Rect2, x0: float, x1: float, h: float, col: Color, a: float) -> void:
	var ff: float = STREET["far"]
	var left := _o(g, x0, ff).x
	var right := _o(g, x1, ff).x
	var y := _o(g, x0, STREET["far_curb"] - 0.3).y
	var n := int((_o(g, x0, ff).y - _o(g, x0, ff, h).y) * 0.8 / PX)
	var cuts: Array[Vector3] = []   # [de x, até x, a beira de lá] de cada carro
	for c in _cars:
		var q := _car_ground(g, c)
		cuts.append(Vector3(minf(q[0].x, q[3].x), maxf(q[1].x, q[2].x), q[3].y))
	for k in n:
		if k % 3 == 2:   # (quebrado pelas poças e pelo vento na água)
			continue
		var at := y + k * PX
		var segs: Array[Vector2] = [Vector2(left, right - PX) + Vector2.ONE * PX * (k % 2)]
		for v in cuts:
			if at + PX <= v.z:
				continue
			var rest: Array[Vector2] = []
			for s in segs:
				if v.x > s.x:
					rest.append(Vector2(s.x, minf(s.y, v.x)))
				if v.y < s.y:
					rest.append(Vector2(maxf(s.x, v.y), s.y))
			segs = rest
		for s in segs:
			if s.y > s.x:
				_r(s.x, at, s.y - s.x, PX, Color(col, MIRROR_A * a * (1.0 - float(k) / n)))


## Uma parede da rua do cruzamento (`w`: o lado `x`, de `z0` a `z1`, `h` m), indo embora para o ponto de fuga, com
## janelas em andares (acesas ou não) e a laje de cada andar. `taken`: os pixels das janelas finas já acesos.
func _draw_canyon_wall(g: Rect2, w: Dictionary, hz: Color, taken: Dictionary) -> void:
	var x: float = w["x"]
	var z0: float = w["z0"]
	var z1: float = w["z1"]
	var ht: float = w["h"]
	var haze := clampf((z0 - 14.0) / 160.0, 0.0, 0.5)
	var tone := func(k: int) -> Color: return (w["tones"][Pal.FACADE_MID + k] as Color).lerp(hz, haze)   # o tom da rampa, no ar da distância
	var col: Color = tone.call(0)
	var rim := _sun_tint(Pal.SUN_STREET)
	# o sol baixo no fundo da rua, um pouco à direita do eixo: a parede da direita, de costas para ele, na sombra, só a
	# beira de cima acesa (a cornija); a da esquerda, virada para ele, pega a luz de raspão inteira, junto com o chão:
	# a sombra da parede da frente no chão nunca chega até ela (`_draw_sun_strip` deixa a faixa desse lado)
	var sun := _sunlit()
	var face := col.lerp(rim, WALL_LIT * sun) if x < 0.0 else col.lerp(Pal.DAWN_SHADE, 0.3 * sun)
	var far := face.lerp(rim, 0.6 * sun * clampf((z1 - 20.0) / 90.0, 0.0, 1.0))   # e as duas, no fundo, somem no ar dourado do sol
	face = face.lerp(rim, 0.6 * sun * clampf((z0 - 20.0) / 90.0, 0.0, 1.0))
	_fill(PackedVector2Array([_o(g, x, z0), _o(g, x, z1), _o(g, x, z1, ht), _o(g, x, z0, ht)]), PackedColorArray([face, far, far, face]))
	# a textura por cima da luz, translúcida para o degradê dela continuar: as fiadas fugindo para o fundo e os
	# remendos, mais escuros (no frio da sombra) ou mais claros
	var rng := RandomNumberGenerator.new()
	rng.seed = int(z0 * 31.0) + (7 if x < 0.0 else 3)
	var course := Color(tone.call(-3), CANYON_GRAIN)
	var hc := 0.8
	while hc < ht:
		_ci.draw_line(_o(g, x, z0, hc), _o(g, x, z1, hc), course, PX)
		hc += 0.8
	for i in rng.randi_range(3, 5):
		var za := rng.randf_range(z0, z1 - 2.0)
		var zb := za + rng.randf_range(1.5, 4.0)
		var ha := rng.randf_range(0.5, ht - 2.0)
		var hb := ha + rng.randf_range(0.8, 2.0)
		var c := Color(tone.call(-3), 2.0 * CANYON_GRAIN) if rng.randf() < 0.6 else Color(tone.call(3), CANYON_GRAIN)
		_poly(PackedVector2Array([_o(g, x, za, ha), _o(g, x, zb, ha), _o(g, x, zb, hb), _o(g, x, za, hb)]), c)
	_ci.draw_line(_o(g, x, z0), _o(g, x, z0, ht), tone.call(-2), PX)   # a quina
	_ci.draw_line(_o(g, x, z0, ht), _o(g, x, z1, ht), tone.call(2).lerp(rim, 0.85 * sun), PX)   # a cornija, acesa pelo sol
	for f in range(1, int((ht - 0.8) / 3.2)):   # a laje de cada andar, fugindo para o ponto de fuga com as janelas
		_ci.draw_line(_o(g, x, z0, f * 3.2), _o(g, x, z1, f * 3.2), tone.call(1), PX)
	var dark: Color = tone.call(-3)
	for wv: Vector3 in w["wins"]:   # (z do meio, altura do peitoril, hora de apagar), 1 m por 1,4 m
		var lit := wv.z > minutes
		var a := _o(g, x, wv.x - 0.5, wv.y + 1.4)
		var b := _o(g, x, wv.x + 0.5, wv.y)
		var col_w: Color = _sunny(Pal.CITY_LIT[int(wv.x) % Pal.CITY_LIT.size()]) if lit else dark
		if absf(b.x - a.x) >= PX:
			_poly(PackedVector2Array([a, _o(g, x, wv.x + 0.5, wv.y + 1.4), b, _o(g, x, wv.x - 0.5, wv.y)]), col_w)
			# o peitoril e a sombra dele embaixo
			_ci.draw_line(_o(g, x, wv.x - 0.65, wv.y - 0.05), _o(g, x, wv.x + 0.65, wv.y - 0.05), tone.call(3), PX)
			_ci.draw_line(_o(g, x, wv.x - 0.6, wv.y - 0.25), _o(g, x, wv.x + 0.6, wv.y - 0.25), Color(tone.call(-3), 0.5), PX)
		elif lit:   # mais fina que um pixel: 1 px, com um vazio ao lado (juntas, as de longe viravam um borrão amarelo)
			var at := Vector2i(floori(a.x), floori(wv.y / 3.2))   # (px de 2x2: um vazio de 1 px da tela entre elas)
			if not taken.has(at):
				taken[at] = true
				_r(roundf(a.x * 2.0) / 2.0, a.y, PX, maxf(PX, b.y - a.y), col_w)
	# o térreo: as lojas abertas, com a vitrine acesa e a luz dela na calçada, e as fechadas com a porta de enrolar
	# (as ripas fugindo para o fundo), e as portas de madeira com a bandeira de vidro acesa em cima
	for sv: Vector3 in w.get("shops", []):
		var za := sv.x - sv.y / 2.0
		var zb := sv.x + sv.y / 2.0
		var top := 2.4 if sv.y > 1.0 else 2.2
		var open := sv.z > minutes
		var lc: Color = _sunny(Pal.CITY_LIT[int(sv.x) % Pal.CITY_LIT.size()]).lerp(hz, haze)
		var quad := func(h0: float, h1: float) -> PackedVector2Array:
			return PackedVector2Array([_o(g, x, za, h0), _o(g, x, zb, h0), _o(g, x, zb, h1), _o(g, x, za, h1)])
		_poly(quad.call(0.0, top + 0.15), dark)   # o vão
		if sv.y > 1.0:
			if open:
				_poly(quad.call(0.05, top), lc)
				_ci.draw_line(_o(g, x, za, 1.0), _o(g, x, zb, 1.0), lc.darkened(0.55), PX)   # o balcão contra a luz
			else:
				_poly(quad.call(0.05, top), tone.call(-1))
				for i in range(1, 6):
					_ci.draw_line(_o(g, x, za, top * i / 6.0), _o(g, x, zb, top * i / 6.0), Color(dark, 0.7), PX)
		else:
			_poly(quad.call(0.05, top - 0.4), Pal.BAR_WOOD.lerp(hz, haze))
			_poly(quad.call(top - 0.3, top), lc if open else dark)   # a bandeira


## O vidro da janela `wv` de um prédio de lá (`_houses`, fora do térreo) na tela (px de 2x2), como `_draw_far_house` a desenha.
func _win_rect(g: Rect2, wv: Vector3) -> Rect2:
	var k: float = OUT_F / STREET["far"]
	var top := _o(g, wv.x, STREET["far"], wv.y * 3.2 + 2.5)
	return Rect2(top.x - 0.6 * k, top.y, 1.2 * k, 1.5 * k)


## A janela `j` do prédio `b` acesa agora: até a hora dela apagar ou, apagada, acesa de novo (`wake`).
func _win_lit(b: Dictionary, j: int) -> bool:
	var wv: Vector3 = b["wins"][j]
	var woke: Vector2 = b["wake"].get(j, Vector2.ZERO)
	return wv.z > minutes or (minutes >= woke.x and minutes < woke.y)


## Alguém passando dentro de casa, atrás de uma janela acesa do prédio de tijolos (`_indoor`): a cabeça e os ombros
## contra a luz, recortados no vidro, entrando por um lado e saindo pelo outro.
func _draw_behind(g: Rect2) -> void:
	if _indoor.x < 0.0 or _houses.is_empty():
		return
	var b: Dictionary = _houses[0]
	var wv: Vector3 = b["wins"][int(_indoor.y)]
	var r := _win_rect(g, wv)
	var k: float = OUT_F / STREET["far"]
	var u := _indoor.x / BEHIND_SEC
	var x := lerpf(r.position.x - 0.5 * k, r.end.x, u if _indoor.z > 0.0 else 1.0 - u)
	var dark: Color = _sunny(Pal.CITY_LIT[int(wv.x + wv.y) % Pal.CITY_LIT.size()]).darkened(0.6)
	for part: Rect2 in [Rect2(x + 0.14 * k, r.position.y + 0.3 * k, 0.22 * k, 0.26 * k), Rect2(x, r.position.y + 0.56 * k, 0.5 * k, r.size.y)]:
		var cut := part.intersection(r)
		if cut.has_area():
			_r(cut.position.x, cut.position.y, cut.size.x, cut.size.y, dark)


## Um prédio do outro lado da rua, de frente (`b`: de `x0` a `x1`, `h` m, andares de 3,2 m), apoiado na calçada de lá:
## a fachada vertical (de tijolos, no da esquina), a cornija, a faixa acima do térreo, a porta e a vitrine no térreo e as
## janelas, acesas até a hora delas ou apagadas com o reflexo da rua.
func _draw_far_house(g: Rect2, b: Dictionary, hz: Color) -> void:
	var ff: float = STREET["far"]
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var ht: float = b["h"]
	var tones: Array = b["tones"]
	# com o sol, as fachadas de lá, de costas para ele, ficam na luz fria do céu (uma sombra andando nelas não tinha de
	# onde vir), com a beira de cima acesa contra ele
	var sun := _sunlit()
	var rim := _sun_tint(Pal.SUN_STREET)
	var tone := func(k: int) -> Color: return (tones[Pal.FACADE_MID + k] as Color).lerp(Pal.DAWN_SHADE, 0.12 * sun)
	var col: Color = tone.call(0)
	var a := _o(g, x0, ff, ht)
	var e := _o(g, x1, ff)
	var k := OUT_F / ff   # px de 2x2 por metro na fachada
	_r(a.x, a.y, e.x - a.x, e.y - a.y, col)
	_draw_facade_wear(g, b, tone)
	_r(a.x - PX, a.y - 1, e.x - a.x + PX * 2.0, 1, tone.call(2))   # a cornija, com a sombra embaixo
	if sun > 0.0:
		_r(a.x - PX, a.y - 1, e.x - a.x + PX * 2.0, PX, tone.call(2).lerp(rim, 0.6 * sun))
		if is_equal_approx(x1, CROSSING.x):
			_r(e.x - PX, a.y, PX, e.y - a.y, col.lerp(rim, 0.5 * sun))
	_r(a.x, a.y, e.x - a.x, PX, Color(0, 0, 0, 0.4))
	_r(a.x, _o(g, x0, ff, 3.4).y, e.x - a.x, PX, tone.call(1))   # a faixa acima do térreo
	_r(a.x, a.y, PX, e.y - a.y, tone.call(-2))   # a divisa com o vizinho
	_r(a.x, e.y - PX, e.x - a.x, PX, Color(0, 0, 0, 0.45))   # o pé, na calçada
	for j in b["wins"].size():   # (x do meio, andar, hora de apagar; -1: apagada)
		var wv: Vector3 = b["wins"][j]
		var ground := wv.y == 0.0
		var w := (1.8 if ground else 1.2) * k
		var top := _o(g, wv.x, ff, 2.6 if ground else wv.y * 3.2 + 2.5)
		var variety := int(absf(wv.x) * 7.0 + wv.y * 3.0)
		var h := (2.6 if ground else 1.5) * k
		var p := Vector2(top.x - w / 2.0, top.y)
		if not b["brick"] and not ground:   # a moldura da janela, saliente
			_r(p.x - PX * 3.0, p.y - PX * 3.0, w + PX * 6.0, h + PX * 3.0, col.lerp(tone.call(1), 0.6))
		_r(p.x - PX, p.y - PX, w + PX * 2.0, h + PX, tone.call(-3))   # o vão
		if _win_lit(b, j):
			var lc: Color = _sunny(Pal.CITY_LIT[int(wv.x + wv.y) % Pal.CITY_LIT.size()])
			var inside := lc.darkened(0.6)   # o que fica contra a luz lá dentro
			_r(p.x, p.y, w, h, lc)
			if ground:   # a loja: o balcão, uma mesa com as cadeiras e a prateleira no fundo
				_r(p.x, p.y + h * 0.25, w, PX, inside)
				_r(p.x + w * 0.55, p.y + h * 0.62, w * 0.4, PX, inside)
				_r(p.x + w * 0.73, p.y + h * 0.62, PX, h * 0.38, inside)
				for cx: float in [0.48, 0.97]:
					_r(p.x + w * cx - PX, p.y + h * 0.55, PX, h * 0.45, inside)
				_r(p.x + w * 0.05, p.y + h * 0.7, w * 0.35, h * 0.3, inside)
			else:
				match variety % 4:   # cada janela de um jeito: a cortina de um lado, as duas, a persiana descida, um móvel
					0: _r(p.x, p.y, w * 0.3, h, lc.darkened(0.25))
					1:
						_r(p.x, p.y, w * 0.22, h, lc.darkened(0.25))
						_r(p.x + w * 0.78, p.y, w * 0.22, h, lc.darkened(0.25))
					2: _r(p.x, p.y, w, h * 0.4, lc.darkened(0.35))
					3: _r(p.x + w * 0.6, p.y + h * 0.55, w * 0.3, h * 0.45, inside)   # (um armário, um abajur)
			_r(p.x, p.y + h * 0.45, w, PX, lc.darkened(0.45))   # a travessa
			_r(p.x, p.y, w, maxf(PX, 0.15 * k), lc.darkened(0.5))   # a sombra da verga: a janela é funda
			if ground and minutes >= STREET_OFF:   # com os postes apagados, a luz da vitrine aparece na calçada
				var c := _o(g, wv.x, ff - 0.6)
				var pool := PackedVector2Array()
				for i in 16:
					pool.append(_o(g, wv.x + cos(TAU * i / 16.0) * 1.8, ff - 0.6 + sin(TAU * i / 16.0) * 1.0))
				_light_fan(c, pool, Color(lc, SHOP_POOL))
			if ground and (weather == "rain" or morning() > 0.0):   # e ela espelhada no asfalto molhado (`_draw_wet`)
				_mirror(g, wv.x - 0.9, wv.x + 0.9, 2.6, lc, 1.0 if weather == "rain" else 2.0 * DAMP)
		else:
			_r(p.x, p.y, w, h, Pal.WINDOW_DARK)
			if variety % 3 == 0:   # a cortina fechada, mal vista no escuro
				_r(p.x + w * 0.5, p.y, w * 0.5, h, Pal.WINDOW_DARK.lerp(tone.call(-3), 0.5))
			elif variety % 3 == 1:   # o caixilho
				_r(p.x + w * 0.5, p.y, PX, h, tone.call(-3))
			_r(p.x, p.y, w, PX, Color(hz, 0.5))   # o reflexo da rua no vidro
		if ground and absf(wv.x - HOTEL_X) > 1.5 and (wv.x < CROSSING.y or wv.x > BAR_DOOR.y + 0.5):   # o térreo (o bar e a marquise do hotel têm o deles)
			_draw_shop_trim(p, w, h, k, variety, _win_lit(b, j), tone)
		if not ground:
			_r(p.x - PX * 2.0, p.y + h, w + PX * 4.0, PX, tone.call(3))   # o peitoril, saindo da parede, e a sombra dele
			_r(p.x - PX, p.y + h + PX, w + PX * 2.0, PX, tone.call(-2))
			_r(p.x - PX * 2.0, p.y - PX * 2.0, w + PX * 4.0, PX, tone.call(-1))   # a verga
			if b["brick"] and variety % 5 == 1:   # no prédio de tijolos, os vasos no peitoril
				for vx: float in [0.15, 0.6]:
					_r(p.x + w * vx, p.y + h - 0.2 * k, 0.22 * k, 0.2 * k, Pal.BALCONY_POT)
					_r(p.x + w * vx - PX, p.y + h - 0.45 * k, 0.22 * k + 2.0 * PX, 0.25 * k, Pal.BALCONY_PLANT[int(vx * 10.0) % 2])
			elif b["brick"] and variety % 5 == 3 and _win_lit(b, j):   # e a gaiola do passarinho pendurada na janela
				var cage := Rect2(p.x + w * 0.62, p.y + 0.25 * k, 0.28 * k, 0.36 * k)
				_ci.draw_rect(cage, Color(Pal.SILHOUETTE, 0.7), false, PX)
				_r(cage.position.x + cage.size.x / 2.0 - PX / 2.0, p.y, PX, 0.25 * k, Color(Pal.SILHOUETTE, 0.7))
			if variety % 3 != 1:   # o escorrido da chuva embaixo do peitoril, sumindo para baixo
				_r(p.x + w * 0.1, p.y + h + PX * 2.0, w * 0.8, 0.35 * k, col.lerp(tone.call(-2), 0.4))
				_r(p.x + w * 0.25, p.y + h + PX * 2.0 + 0.35 * k, w * 0.5, 0.6 * k, col.lerp(tone.call(-2), 0.2))
	if b["brick"]:
		_draw_balcony_back(g, tone)
	if sun > 0.0:   # o rebatido quente da faixa de sol da rua, embaixo, junto da boca do cruzamento (as cores se misturam)
		for side: float in [CROSSING.x, CROSSING.y]:
			if is_equal_approx(x1, side) or is_equal_approx(x0, side):
				var out := -BOUNCE.x if is_equal_approx(x1, side) else BOUNCE.x
				var warm := Color(_sun_tint(Pal.SUN_STREET), BOUNCE.z * sun)
				var c := _o(g, side, ff)
				var prev := _o(g, side, ff, BOUNCE.y)
				for i in range(1, 9):   # um quarto de elipse, da quina para cima e para o lado
					var t := PI / 2.0 * i / 8.0
					var p := _o(g, side + out * sin(t), ff, BOUNCE.y * cos(t))
					_ci.draw_primitive(PackedVector2Array([c, prev, p]), PackedColorArray([warm, Color(warm, 0.0), Color(warm, 0.0)]), PackedVector2Array())
					prev = p


## O que uma loja do térreo de lá tem em volta da vitrine (`p`, `w`, `h`: o vão em px de 2x2; `k` px por metro): o
## batente, a tábua da placa em cima, com as letras só sugeridas em traços (nada de fonte), e, numa em cada duas, o
## toldo de lona com a franja e a sombra embaixo; fechada, a grade de ferro na frente do vidro.
func _draw_shop_trim(p: Vector2, w: float, h: float, k: float, variety: int, lit: bool, tone: Callable) -> void:
	_r(p.x - PX * 2.0, p.y - PX, PX, h + PX, tone.call(2))   # o batente, claro de um lado e escuro do outro
	_r(p.x + w + PX, p.y - PX, PX, h + PX, tone.call(-2))
	var board := Rect2(p.x - PX, p.y - 0.55 * k, w + PX * 2.0, 0.4 * k)
	_r(board.position.x, board.position.y, board.size.x, board.size.y, Pal.SHOP_BOARD)
	var ink: Color = Pal.CITY_LIT[2] if lit else tone.call(-1)   # as letras, pintadas: acesas pela vitrine
	var lx := board.position.x + 2.0 * PX
	var r := variety * 7
	while lx < board.end.x - 3.0 * PX:   # uma palavra ou duas: traços de 1 a 3 px com um vão entre elas
		var lw := PX * (1 + (r % 3))
		_r(lx, board.position.y + board.size.y * 0.35, lw, maxf(PX, board.size.y * 0.3), Color(ink, 0.8))
		lx += lw + PX * (3.0 if r % 5 == 0 else 1.0)
		r = r * 13 + 7
	if variety % 2 == 0:   # o toldo, inclinado para a rua: a lona, a franja recortada e a sombra na vitrine
		var cloth: Color = Pal.AWNINGS[variety % Pal.AWNINGS.size()]
		var top := p.y - 0.12 * k
		_r(p.x - PX * 2.0, top, w + PX * 4.0, 0.35 * k, cloth)
		_r(p.x - PX * 2.0, top, w + PX * 4.0, PX, Pal.lit(cloth, 1))
		var fx := p.x - PX * 2.0
		while fx < p.x + w + PX * 2.0:
			_r(fx, top + 0.35 * k, PX, PX, Pal.lit(cloth, -2))
			fx += PX * 2.0
		_r(p.x, top + 0.35 * k + PX, w, 0.25 * k, Color(0, 0, 0, 0.3))
	if not lit:   # a grade de ferro na frente do vidro escuro
		var gx := p.x + PX
		while gx < p.x + w:
			_r(gx, p.y, PX, h, Color(Pal.SILHOUETTE, 0.6))
			gx += maxf(PX * 2.0, 0.22 * k)
		_r(p.x, p.y + h * 0.5, w, PX, Color(Pal.SILHOUETTE, 0.6))


## O uso de anos numa fachada de lá (`b`), por cima da tinta e embaixo das janelas, sempre o mesmo (sorteio pelo
## lugar): nas de reboco, os remendos num tom vizinho, com a beira desencontrada; nas de tijolo, as fiadas
## desencontradas, cada tijolo no seu tom; o rodapé de pedra com as juntas e o encardido de respingo em cima, o cano
## de descida com as braçadeiras e, de manhã, o alto na luz do céu. Num tom só, a fachada era uma massa.
func _draw_facade_wear(g: Rect2, b: Dictionary, tone: Callable) -> void:
	var ff: float = STREET["far"]
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var ht: float = b["h"]
	var col: Color = tone.call(0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(x0) * 97.0) + 5
	# a fachada está toda na mesma distância: a tela anda por igual nela (`ox` + m × `kx`), sem chamar `_o` a cada peça
	var o := _o(g, x0, ff)
	var kx := _o(g, x0 + 1.0, ff).x - o.x
	var ky := _o(g, x0, ff, 1.0).y - o.y
	var y := func(h: float) -> float: return o.y + h * ky
	var xs := func(x: float) -> float: return o.x + (x - x0) * kx
	var span := Rect2(o.x, o.y + ht * ky, (x1 - x0) * kx, -ht * ky)
	if b["brick"]:   # as fiadas de meio em meio metro, desencontradas, e um tijolo em cada tanto mais claro ou mais escuro
		var light: Color = col.lerp(tone.call(1), 0.5)
		var dark: Color = col.lerp(tone.call(-1), 0.5)
		var joints := PackedVector2Array()   # as juntas de pé, todas numa chamada só
		var row := 0
		var hb := 0.0
		while hb < ht:
			var yb := o.y + hb * ky
			var yt := o.y + minf(hb + 0.5, ht) * ky
			_r(span.position.x, yt, span.size.x, PX, tone.call(-1))
			var bx := x0 - (0.5 if row % 2 else 0.0)
			while bx < x1:
				var v := rng.randf()
				var l := o.x + (maxf(bx, x0) - x0) * kx
				var r := o.x + (minf(bx + 1.0, x1) - x0) * kx
				if v < BRICK_VARY.y:
					_r(l, yt + PX, r - l - PX, yb - yt - PX, light if v < BRICK_VARY.x else dark)
				var jx := floorf(r * 2.0) * PX - PX / 2.0   # (no meio do pixel, para a linha de 1 px não se espalhar)
				joints.append_array([Vector2(jx, yt), Vector2(jx, yb)])
				bx += 1.0
			hb += 0.5
			row += 1
		_ci.draw_multiline(joints, col.lerp(tone.call(-1), 0.7), PX)
	else:   # o reboco: o friso de cada andar, as pilastras entre as janelas (em metade dos prédios) e os remendos
		var floors := int((ht - 0.8) / 3.2)
		for f in range(1, floors):
			var fy: float = y.call(f * 3.2 + 0.5)
			_r(span.position.x, fy, span.size.x, PX, tone.call(1))
			_r(span.position.x, fy + PX, span.size.x, PX, tone.call(-1))
		if rng.randf() < 0.5:
			var px0 := x0 + 3.0
			while px0 < x1 - 0.8:
				var l: float = xs.call(px0 - 0.25)
				var r: float = xs.call(px0 + 0.25)
				_r(l, y.call(ht - 0.4), r - l, y.call(3.4) - y.call(ht - 0.4), col.lerp(tone.call(1), 0.45))
				_r(r, y.call(ht - 0.4), PX, y.call(3.4) - y.call(ht - 0.4), tone.call(-1))
				px0 += 3.0
		for i in rng.randi_range(4, 7):
			var pw := rng.randf_range(1.2, 3.0)
			var pv := rng.randf_range(0.5, 1.4)
			var px := rng.randf_range(x0 + 0.4, maxf(x0 + 0.4, x1 - pw - 0.4))
			var ph := rng.randf_range(1.2, maxf(1.2, ht - pv - 1.2))
			var c: Color = col.lerp(tone.call(1 if rng.randf() < 0.5 else -1), 0.65)
			_r(xs.call(px), y.call(ph + pv), xs.call(px + pw) - xs.call(px), y.call(ph) - y.call(ph + pv), c)
			_r(xs.call(px), y.call(ph + pv), xs.call(px + pw) - xs.call(px), PX, col.lerp(tone.call(-2), 0.5))   # a beira de cima, descascando
			var dx := rng.randf_range(0.2, pw * 0.5)   # a beira desencontrada: um pedaço a mais, por cima ou por baixo
			var up := rng.randf() < 0.5
			var h0 := ph + pv if up else ph - 0.3
			_r(xs.call(px + dx), y.call(h0 + 0.3), xs.call(px + dx + pw * 0.4) - xs.call(px + dx), y.call(h0) - y.call(h0 + 0.3), c)
	# o rodapé de pedra, com a beira de cima na luz e as juntas, e o encardido do respingo em cima dele
	_r(span.position.x, y.call(1.3), span.size.x, y.call(0.6) - y.call(1.3), col.lerp(tone.call(-1), 0.35))
	_r(span.position.x, y.call(0.6), span.size.x, y.call(0.0) - y.call(0.6), tone.call(-1))
	_r(span.position.x, y.call(0.6), span.size.x, PX, tone.call(1))
	var jx := x0 + 1.1
	while jx < x1:
		_r(xs.call(jx), y.call(0.6) + PX, PX, y.call(0.0) - y.call(0.6) - PX, tone.call(-2))
		jx += 1.1
	# o cano de descida, do alto ao chão, com o lado da rua do cruzamento na luz e as braçadeiras
	var dp: float = xs.call(x1 - 0.45 if rng.randf() < 0.5 else x0 + 0.45)
	_r(dp, span.position.y + PX * 2.0, PX * 2.0, span.size.y - PX * 2.0, tone.call(-2))
	_r(dp, span.position.y + PX * 2.0, PX, span.size.y - PX * 2.0, tone.call(1))
	var bh := 1.6
	while bh < ht - 0.5:
		_r(dp - PX, y.call(bh), PX * 4.0, PX, tone.call(-3))
		bh += 3.2
	var sun := _sunlit()
	if sun > 0.0:   # de manhã, o alto na luz do céu (vê mais céu que a parte de baixo, que vê a rua)
		var sky := Color(tone.call(2).lerp(Pal.DAWN_SHADE, 0.4), SKY_TOP * sun)
		_fill(PackedVector2Array([span.position, Vector2(span.end.x, span.position.y), Vector2(span.end.x, y.call(ht * 0.4)),
			Vector2(span.position.x, y.call(ht * 0.4))]), PackedColorArray([sky, sky, Color(sky, 0.0), Color(sky, 0.0)]))


## A vitrine acesa de um bar no térreo do prédio de tijolos, logo atrás do homem (`MAN_X`): ele fica em silhueta contra
## ela. Vidro quente com o caixilho e o letreiro pintado, e a luz dela saindo pela calçada.
func _draw_shopfront(g: Rect2) -> void:
	var ff: float = STREET["far"]
	var x0 := CROSSING.y + 0.5   # (a quina do prédio fica em CROSSING.y: antes, a vitrine passava dela)
	var x1 := CROSSING.y + 2.5   # (com três divisões, encostava na porta)
	var a := _o(g, x0, ff, 2.5)
	var e := _o(g, x1, ff, 0.4)
	_r(a.x - PX, a.y - PX, e.x - a.x + 1, e.y - a.y + 1, Pal.BAR_JAMB)
	var hi := _sunny(Pal.BAR_LIGHT[0])   # (sem a luz do dia por cima: de manhã, estourava num amarelo-claro chapado)
	var lo := _sunny(Pal.BAR_LIGHT[1])
	_fill(PackedVector2Array([a, Vector2(e.x, a.y), e, Vector2(a.x, e.y)]), PackedColorArray([hi, hi, lo, lo]))
	var inside := _sunny(Pal.BAR_LIGHT[0].darkened(0.6))   # o salão: a prateleira com as garrafas no fundo e o balcão
	var shelf := roundf(lerpf(a.y, e.y, 0.45) / PX) * PX
	_r(a.x, shelf, e.x - a.x, PX, inside)
	var bx := a.x + PX
	var n := 0
	while bx < e.x - PX:
		_r(bx, shelf - PX * (2 + n % 2), PX, PX * (2 + n % 2), inside)
		bx += PX * 2.0
		n += 1
	var desk := roundf(lerpf(a.y, e.y, 0.72) / PX) * PX
	_r(a.x, desk, e.x - a.x, e.y - desk, inside)
	_r(a.x, desk, e.x - a.x, PX, lo.darkened(0.3))   # o tampo
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
		_figure(foot, OUT_F / spot.y * 2.0, parts, Pal.CLERK if i == 0 else Color(0.17, 0.09, 0.04, 0.9), clip)


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
		_figure((_o(g, x, z) * 2.0).floor(), OUT_F / z * 2.0, parts, Pal.SILHOUETTE, clip)


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
				_p(px, foot.y - rows.size() + y, 1, 1, Pal.STRAY_COAT.lerp(RIM, 0.2 + 0.4 * lit) if top else Pal.lit(Pal.STRAY_COAT, -3 if y > 3 else 0))


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
			var r := (5.0 + (i % 3) * 2.5 + sin(t * 1.3 + ph) * 1.5) * OUT_K   # (rente à cabeça, sumiam no brilho dela)
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
	var dark := Pal.CAT
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
	_figure(foot, k, _body(int(_smoke_t * WALK_STEPS * 2.0), away > 0.0, up), Pal.SILHOUETTE)
	var ember := foot + (Vector2(0.14, -1.55) if up else Vector2(0.24, -0.85)) * k
	_p(roundf(ember.x), roundf(ember.y), 1, 1, EMBER if up else EMBER.darkened(0.45))
	_p(roundf(ember.x) - 1, roundf(ember.y) - 1, 3, 3, Color(EMBER, 0.25 if up else 0.1))
	_draw_smoke(g, foot, k, ember, away == 0.0 and not up, puff - 1.2 if away == 0.0 and puff > 1.2 else -1.0)


## A fumaça de quem fuma (`_draw_smoker`; em px da tela): o fio fino subindo da brasa enquanto o cigarro está na mão
## (`thread`) e o sopro da tragada (`after`: segundos desde que ele tirou o cigarro da boca, -1 sem sopro), que sai da
## boca, sobe, abre e vai com o vento (`GUST`, como o arbusto), sumindo em `SMOKE_PUFF` s. Cinza, pegando a luz quente
## do poste da esquina, logo abaixo da varanda, quanto mais perto da cabeça dele (`SMOKE_LIT`): é ali que ela aparece.
func _draw_smoke(g: Rect2, foot: Vector2, k: float, ember: Vector2, thread: bool, after: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var gust := pow(maxf(0.0, sin(t * GUST.x) * sin(t * GUST.y + 1.3)), 0.6)
	var drift := -(0.25 + gust) * k   # para onde o vento leva (o mesmo lado do arbusto)
	var head := _post(g) * 2.0
	var tint := func(q: Vector2, a: float) -> Color:
		var lit := clampf(1.0 - q.distance_to(head) / (SMOKE_LIT * k), 0.0, 1.0)
		return Color(Pal.SMOKE.lerp(RIM, lit * 0.75), a * (0.55 + 0.9 * lit))
	if thread:   # o fio da brasa: sobe ondulando e some
		for i in roundi(1.2 * k):
			var f := i / (1.2 * k)
			var q := ember + Vector2(sin(i * 0.9 - t * 2.2) * f * 1.5 + drift * 0.15 * f, -1.0 - i)
			_p(roundf(q.x), roundf(q.y), 1, 1, tint.call(q, 0.45 * (1.0 - f)))
	if after >= 0.0 and after < SMOKE_PUFF:   # o sopro: grãos que saem juntos da boca e se espalham subindo
		var f := after / SMOKE_PUFF
		var mouth := foot + Vector2(0.12, -1.6) * k
		var mid := mouth + Vector2(drift * f * 1.5, -(0.15 + f * 1.8) * k)   # o meio da nuvem, subindo e indo com o vento
		for i in 14:
			var h := Vector2(fposmod(sin(i * 12.99) * 437.58, 1.0), fposmod(sin(i * 78.23) * 437.58, 1.0)) - Vector2(0.5, 0.5)   # cada grão, sempre o mesmo
			var q := mid + h * (0.2 + f * 1.1) * k + Vector2(sin(t * 1.3 + i) * f, 0.0)
			var a := 0.6 * pow(1.0 - f, 1.1) * (1.0 - h.length())
			_p(roundf(q.x), roundf(q.y), 1 if f < 0.4 else 2, 1, tint.call(q, a))


## Quem passa de bicicleta (`w`, de `_walker`, com "bike"; `x` onde está): as rodas, o quadro, o ciclista pedalando
## (as pernas giram com o pé de vela) e a luz fraca do farol na frente. Em px da tela; virado para onde vai.
func _draw_bike(g: Rect2, w: Dictionary, x: float) -> void:
	var z: float = w["z"]
	var k := OUT_F / z * 2.0
	var s: float = w["dir"]
	var foot := (_o(g, x, z) * 2.0).floor()
	var at := func(p: Vector2) -> Vector2: return (foot + Vector2(p.x * s, -p.y) * k).floor()
	var dark := Pal.SILHOUETTE
	var a: float = w["t"] * w["sec"] * TAU * 1.2   # o pé de vela
	_sun_shadow(g, x - 0.6, x + 0.6, z, 1.6)
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
	if w.get("papers", false):   # o menino do jornal: o boné com a pala para a frente e a sacola cheia na garupa
		_ci.draw_rect(Rect2(at.call(shoulder + Vector2(-0.12 if s > 0.0 else 0.12, 0.3)), Vector2(0.34, 0.06) * k).abs(), dark)
		var bag := Rect2(at.call(Vector2(-0.78 if s > 0.0 else -0.28, 0.9)), Vector2(0.5, 0.36) * k)
		_ci.draw_rect(bag, Pal.PAPERBOY[0])
		_ci.draw_rect(Rect2(bag.position + Vector2(1, -maxf(1.0, 0.06 * k)), Vector2(bag.size.x - 2, maxf(1.0, 0.06 * k))), Pal.PAPERBOY[1])   # os jornais dobrados, saindo dela
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
	var owner := clampf((minutes - BAR_OPENS) / 2.0, 0.0, 1.0)   # (a porta abre em 2 min de jogo e fica aberta)
	open = maxf(open, owner)
	_r(a.x - PX, a.y - PX, e.x - a.x + PX * 2.0, e.y - a.y + PX, Pal.BAR_JAMB)   # o batente
	_fill(PackedVector2Array([a, Vector2(e.x, a.y), e, Vector2(a.x, e.y)]),
		PackedColorArray([_sunny(Pal.BAR_LIGHT[0]), _sunny(Pal.BAR_LIGHT[0]), _sunny(Pal.BAR_LIGHT[1]), _sunny(Pal.BAR_LIGHT[1])]))   # o salão aceso
	var leaf := (e.x - a.x) * (1.0 - open * 0.8)   # a folha girando para dentro, cada vez mais estreita
	_r(a.x, a.y, leaf, e.y - a.y, Pal.BAR_WOOD)
	_r(a.x + leaf * 0.2, a.y + (e.y - a.y) * 0.12, leaf * 0.6, (e.y - a.y) * 0.3, _sunny(Pal.BAR_GLASS))   # o vidro, com a luz de dentro
	if owner >= 1.0:   # o dono no vão, em silhueta contra o salão aceso, com a mão no batente
		var z := ff + 0.4
		var x := BAR_DOOR.y - 0.3
		_figure((_o(g, x, z) * 2.0).floor(), OUT_F / z * 2.0, _body(0, false, true, 1.0), Pal.SILHOUETTE, Rect2(a * 2.0, (e - a) * 2.0))
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
	var lobby := [_sunny(Pal.HOTEL_DOOR[0]), _sunny(Pal.HOTEL_DOOR[1])]
	_fill(PackedVector2Array([door, Vector2(de.x, door.y), de, Vector2(door.x, de.y)]),
		PackedColorArray([lobby[0], lobby[0], lobby[1], lobby[1]]))   # a porta aberta, com a luz do saguão
	var c := _o(g, HOTEL_X, ff - 0.6)
	var rim := PackedVector2Array()
	for i in 20:
		var an := TAU * i / 20.0
		rim.append(_o(g, HOTEL_X + cos(an) * 2.8, ff - 0.8 + sin(an) * 1.4))
	_light_fan(c, rim, Color(1.0, 0.78, 0.45, 0.22))
	_r(door.x, door.y, de.x - door.x, PX, Pal.BAR_JAMB)   # o caixilho da porta de vidro, com a folha do meio
	_r((door.x + de.x) / 2.0, door.y, PX, de.y - door.y, Pal.BAR_JAMB)
	_r(door.x + (de.x - door.x) * 0.15, de.y - (de.y - door.y) * 0.35, (de.x - door.x) * 0.3, (de.y - door.y) * 0.35, Color(Pal.BAR_JAMB, 0.7))   # o balcão do saguão
	if minutes >= BAR_OPENS:   # de manhã, o porteiro na porta, em silhueta contra o saguão aceso (como na referência)
		var z := ff + 0.3
		_figure((_o(g, HOTEL_X + 0.25, z) * 2.0).floor(), OUT_F / z * 2.0, _body(0, false, false), Pal.SILHOUETTE, Rect2(door * 2.0, (de - door) * 2.0))
	var shade := _o(g, x0, ff, 3.0)   # a sombra dela na fachada
	_r(shade.x, shade.y, _o(g, x1, ff).x - shade.x, (_o(g, x0, ff, 2.4).y - shade.y), Color(0, 0, 0, 0.3))
	var top := PackedVector2Array([_o(g, x0, ff, 3.0), _o(g, x1, ff, 3.0), _o(g, x1, ff - 1.2, 3.0), _o(g, x0, ff - 1.2, 3.0)])
	_poly(top, Pal.MARQUEE[0])
	_poly(PackedVector2Array([top[3], top[2], _o(g, x1, ff - 1.2, 2.75), _o(g, x0, ff - 1.2, 2.75)]), Pal.MARQUEE[1])   # a beira, vermelha
	var fl := _o(g, x0, ff - 1.2, 2.75)   # a franja: os dentes da beira, um pixel sim, outro não
	var fx := fl.x
	while fx < _o(g, x1, ff - 1.2).x:
		_r(fx, fl.y, PX, PX, Pal.MARQUEE[1].darkened(0.3))
		fx += PX * 2.0
	_ci.draw_line(_o(g, x0, ff - 1.2, 2.75), _o(g, x1, ff - 1.2, 2.75), Color(1.0, 0.8, 0.5, 0.6), PX)   # a luz embaixo dela


## A parte parada da varanda do apartamento no prédio de tijolos (`APT`), na camada de trás: a porta (acesa, com a
## cortina, até `APT_DARK`), o vão da janela da sala (o vidro com a TV é da frente, `_draw_balcony_front`), os vasos de
## planta nos cantos e o lado de baixo da laje, visto de baixo (os olhos ficam abaixo dela).
func _draw_balcony_back(g: Rect2, tone: Callable) -> void:
	var ff: float = STREET["far"]
	var fl: float = APT["floor"]
	var dz: float = ff - APT["deep"]
	var d: Vector2 = APT["door"]
	var a := _o(g, d.x, ff, fl + 2.3)
	var e := _o(g, d.y, ff, fl + 0.05)
	_r(a.x - PX, a.y - PX, e.x - a.x + PX * 2.0, e.y - a.y + PX, tone.call(-3))
	if minutes < APT_DARK:
		var lc: Color = (Pal.CITY_LIT[1] as Color).darkened(0.15)
		_r(a.x, a.y, e.x - a.x, e.y - a.y, lc)
		_r(a.x, a.y, (e.x - a.x) * 0.6, e.y - a.y, lc.darkened(0.3))   # a cortina
	else:
		_r(a.x, a.y, e.x - a.x, e.y - a.y, Pal.WINDOW_DARK)
		_r(a.x, a.y, e.x - a.x, PX, Color(0.5, 0.55, 0.6, 0.3))
	_r((a.x + e.x) / 2.0, a.y, PX, e.y - a.y, tone.call(-3))   # as duas folhas
	var w: Vector2 = APT["win"]
	var wa := _o(g, w.x, ff, fl + 2.4)
	var we := _o(g, w.y, ff, fl + 0.9)
	_r(wa.x - PX, wa.y - PX, we.x - wa.x + PX * 2.0, we.y - wa.y + PX, tone.call(-3))
	_r(wa.x, wa.y, we.x - wa.x, we.y - wa.y, Pal.WINDOW_DARK)
	_r(wa.x - PX * 2.0, wa.y - PX * 2.0, we.x - wa.x + PX * 4.0, PX, tone.call(-1))   # a verga
	for px: float in [APT["x0"] + 0.35, APT["x1"] - 0.4]:   # os vasos, atrás do gradil
		var foot := _o(g, px, dz + 0.3, fl + 0.15)
		var k := OUT_F / (dz + 0.3)
		_r(foot.x - 0.18 * k, foot.y - 0.35 * k, 0.36 * k, 0.35 * k, Pal.BALCONY_POT)
		for i in 7:
			var lx := foot.x + (fposmod(i * 0.37, 1.0) - 0.5) * 0.6 * k
			var ly := foot.y - (0.35 + 0.15 + fposmod(i * 0.61, 1.0) * 0.5) * k
			_r(lx - PX, ly, PX * 3.0, PX * 2.0, Pal.BALCONY_PLANT[0] if i % 2 else Pal.BALCONY_PLANT[1])
	var under := PackedVector2Array([_o(g, APT["x0"], ff, fl), _o(g, APT["x1"], ff, fl), _o(g, APT["x1"], dz, fl), _o(g, APT["x0"], dz, fl)])
	_poly(under, tone.call(-4))
	var lz: float = dz + 0.5   # o varal, de um lado ao outro, com a roupa
	var la := _o(g, APT["x0"] + 0.1, lz, fl + 2.2)
	var lb := _o(g, APT["x0"] + 1.4, lz, fl + 2.2)
	_ci.draw_line(la, lb, tone.call(-3), PX)
	var kk := OUT_F / lz
	for i in Pal.LAUNDRY.size():
		var cx := la.x + (lb.x - la.x) * (0.15 + i * 0.3)
		_r(cx, la.y, 0.28 * kk, (0.45 + 0.15 * (i % 2)) * kk, Pal.LAUNDRY[i])


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
	if _posts_on():
		_r(head.x - 0.25 * k, head.y + 0.15 * k, 0.5 * k, maxf(PX, 0.12 * k), Pal.STREET_LAMP)
		_poly(PackedVector2Array([head + Vector2(-0.25 * k, 0.2 * k), head + Vector2(0.25 * k, 0.2 * k),
			Vector2(head.x + 1.6 * k, foot.y), Vector2(head.x - 1.6 * k, foot.y)]), Color(1.0, 0.85, 0.55, 0.05))


## Os postes da rua acesos: apagam com a luminária piscando (a ligação desconhecida) e, na última noite, de manhã
## (`STREET_OFF`).
func _posts_on() -> bool:
	return lamp_level > 0.5 and minutes < STREET_OFF


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
		"coat": (Pal.WALK_DRESSES if dress else Pal.WALK_COATS).pick_random(), "legs": Pal.WALK_LEGS.pick_random(), "skin": Pal.WALK_SKIN.pick_random(),
		"umbrella": Pal.WALK_UMBRELLAS.pick_random(), "hat": ["", "", "scarf"].pick_random() if dress else ["", "fedora", "fedora", "cap"].pick_random(),
		"bag": randf() < 0.3}


## Onde `w` está (x, z em m): de um lado ao outro da calçada de lá, pelo `t`, no sentido `dir`. Quem vira a esquina
## (`corner`: o x da calçada da rua do cruzamento) desce por ela desde `TURN_Z` e segue pela calçada de lá (`out`), ou
## vem pela calçada de lá e sobe por ela.
func _walk_at(w: Dictionary) -> Vector2:
	var z: float = w["z"]
	if not w.has("corner"):
		return Vector2(lerpf(-WALK_SPAN, WALK_SPAN, w["t"]) * w["dir"], z)
	var cx: float = w["corner"]
	var turn: float = w.get("turn", TURN_Z)
	var up := turn - z   # o trecho na rua do cruzamento...
	var side := absf(WALK_SPAN * w["dir"] - cx) if w["out"] else absf(cx + WALK_SPAN * w["dir"])   # ...e o da calçada de lá
	var d: float = w["t"] * (up + side)
	if not w["out"]:
		d = up + side - d   # (o mesmo caminho, do fim para o começo)
	if d < up:
		return Vector2(cx, turn - d)
	return Vector2(cx + (d - up) * (w["dir"] if w["out"] else -w["dir"]), z)


## Põe `w` na calçada, na ordem do desenho (os de mais longe primeiro).
func _add_walker(w: Dictionary) -> void:
	_walkers.insert(_walkers.bsearch_custom(w, func(a: Dictionary, b: Dictionary) -> bool: return a["z"] > b["z"]), w)


## Alguém passando pela calçada de lá (`w`, de `_walker`; fora da vista, não desenha): silhueta escura de 1,7 m contra as luzes, as pernas
## alternando a cada passo, com um balanço leve, e de guarda-chuva aberto na chuva. Perto de um poste, a luz dele
## acende a beira de cima e o lado virado para ele (`RIM`); na chuva, ele se espelha na calçada molhada, apagado e
## sumindo para baixo. Em px da tela, como o homem.
func _draw_walker(g: Rect2, w: Dictionary) -> void:
	var at := _walk_at(w)
	var x := at.x
	var z := at.y
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
	var dark := Pal.SILHOUETTE
	_poly(PackedVector2Array([_o(g, x - 0.3, z), _o(g, x + 0.3, z), _o(g, x + 0.3, z + 0.2), _o(g, x - 0.3, z + 0.2)]), Color(0, 0, 0, 0.35))
	_sun_shadow(g, x - 0.22, x + 0.22, z, 1.7 * w["h"])
	var s: float = w["dir"]   # (o que tem frente, a aba da boina e a bolsa, vira para onde ele vai)
	var coat: Color = w["coat"]
	var legs: Color = w["legs"]
	var parts: Array = []   # [peça, cor], de trás para a frente
	var apart := posmod(steps, 2) == 0
	var sleeve := Pal.lit(coat, -2)
	var swing := (0.06 if apart else -0.06) * s   # os braços balançando com o passo, um para cada lado
	parts.append([Rect2(-0.03 - swing, 0.8, 0.08, 0.55), Pal.lit(coat, -3)])   # o braço de lá, atrás do corpo
	if w["dress"]:   # as pernas finas embaixo da saia, os sapatos, o vestido e o casaquinho por cima
		parts.append_array([[Rect2(-0.16, 0.0, 0.1, 0.5), legs], [Rect2(0.06, 0.0, 0.1, 0.5), legs]] if apart else [[Rect2(-0.06, 0.0, 0.12, 0.5), legs]])
		parts.append_array([[Rect2(-0.17, 0.0, 0.12, 0.06), dark], [Rect2(0.05, 0.0, 0.12, 0.06), dark]] if apart else [[Rect2(-0.07, 0.0, 0.14, 0.06), dark]])
		parts.append_array([[Rect2(-0.24, 0.42, 0.48, 0.5), coat], [Rect2(-0.24, 0.42, 0.48, 0.05), Pal.lit(coat, -2)],
			[Rect2(-0.18, 0.9, 0.36, 0.53), Pal.lit(coat, -3) if w["long"] else coat]])
	else:
		parts.append_array([[Rect2(-0.22, 0.0, 0.13, 0.8), legs], [Rect2(0.09, 0.0, 0.13, 0.8), legs]] if apart else [[Rect2(-0.07, 0.0, 0.14, 0.8), legs]])
		parts.append_array([[Rect2(-0.24, 0.0, 0.16, 0.07), dark], [Rect2(0.08, 0.0, 0.16, 0.07), dark]] if apart else [[Rect2(-0.09, 0.0, 0.18, 0.07), dark]])
		parts.append([Rect2(-0.21, 0.45, 0.42, 0.98) if w["long"] else Rect2(-0.2, 0.75, 0.4, 0.68), coat])
		parts.append([Rect2(-0.21, 0.45, 0.42, 0.06) if w["long"] else Rect2(-0.2, 0.75, 0.4, 0.06), sleeve])   # a barra do casaco
		parts.append([Rect2(-0.05, 1.33, 0.1, 0.1), Pal.lit(coat, 1)])   # a gola
	parts.append([Rect2(-0.08 + swing, 0.82, 0.08, 0.55), sleeve])   # o braço de cá, na frente
	parts.append([Rect2(-0.08 + swing, 0.8, 0.08, 0.06), w["skin"]])   # a mão
	parts.append([Rect2(-0.1, 1.43, 0.2, 0.22), w["skin"]])   # a cabeça
	if w["hat"] in ["", "cap"] and weather != "rain":   # o cabelo, atrás e em cima (o chapéu e o guarda-chuva o cobrem)
		parts.append_array([[Rect2(-0.1, 1.58, 0.2, 0.07), dark], [Rect2(-0.1 if s > 0.0 else 0.04, 1.45, 0.06, 0.15), dark]])
	if w["bag"]:   # a bolsa no ombro, ou a pasta na mão
		parts.append([Rect2(0.14 * s - 0.06, 0.82, 0.12, 0.16), Pal.lit(Pal.lit(coat, -3), -2)] if w["dress"] else [Rect2(0.16 * s - 0.08, 0.3, 0.16, 0.24), Pal.BRIEFCASE])
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
	var edge := glow
	var back := _sunlit() * smoothstep(STREET["far"], STREET["far"] + 1.5, z)
	var top := glow   # (de manhã, contra o sol, a beira acesa só do lado: no alto de cada peça, a figura virava um contorno de arame)
	if back > glow:   # na rua do cruzamento, de manhã, entre nós e o sol: quase em silhueta, com a beira acesa se ele
		# estiver na faixa de sol (na sombra da parede, não), e só de perto (de longe, com 2 px, a figura virava um risco laranja)
		edge = back * smoothstep(3.0, 8.0, k) * float(x > CROSSING.x + STRIP_EDGE and x < _strip_end(g, z))
		top = 0.0
		side = 1.0   # (o sol um pouco à direita do eixo da rua)
		rim = Color(_sun_tint(Pal.SUN_STREET), edge * 0.6)
	var against := _sunny(Pal.BACKLIT)
	for pc: Array in parts:
		var part: Rect2 = pc[0]
		var a := Vector2(roundf(part.position.x * k), -roundf((part.position.y + part.size.y) * k))
		var b := Vector2(roundf(part.end.x * k), -roundf(part.position.y * k))
		var sz := Vector2(maxf(1.0, b.x - a.x), maxf(1.0, b.y - a.y))
		_p(foot.x + a.x, foot.y + a.y, sz.x, sz.y, (pc[1] as Color).lerp(RIM, 0.15 * glow).lerp(against, 0.8 * back))
		if edge > 0.0:
			if sz.y > 2.0 and top > 0.0:   # (as peças finas, como o guarda-chuva e a aba, só no lado: no alto, ficavam acesas inteiras)
				_p(foot.x + a.x, foot.y + a.y, sz.x, 1, rim)
			_p(foot.x + (a.x + sz.x - 1.0 if side > 0.0 else a.x), foot.y + a.y, 1, sz.y, rim)
		if weather == "rain":   # o reflexo, de cabeça para baixo a partir dos pés: mais fraco quanto mais longe deles
			_p(foot.x + a.x, foot.y - a.y - sz.y, sz.x, sz.y, Color(0, 0, 0, 0.35 * (1.0 - (-a.y) / (2.2 * k))))


## O carro `c` passando pela mão dele (`CAR_LANES`), apoiado no asfalto, na forma do modelo dele (`CAR_KINDS`) e na cor
## dele: a sombra de contato, o facho dos faróis no chão à frente, o capô, o teto e o porta-malas vistos um pouco de
## cima (os olhos ficam acima dele; mais escuros que o lado, porque de noite não vem luz do alto, só um pouco do céu,
## `Pal.CAR_SKY`), os vidros inclinados, a frente ou a traseira (a que estiver virada para nós) e o lado de cá (vidros,
## colunas, frisos, rodas redondas com calota nos arcos dos para-lamas). A luz dos postes
## corre pela lataria quando ele passa embaixo deles (`_sheen`; molhada, mais, `CAR_WET`), faróis e lanternas acesos
## com halo (o par deles quando a frente ou a traseira está virada para nós), a placa do táxi (`taxi`) e, na chuva, o
## borrifo dos pneus (`_spray`). Posto a partir da frente (`_car_x`), no sentido em que
## anda: o de lá vai para a esquerda, o de cá volta para a direita.
## O chão embaixo do carro `c`, na tela: a sombra de contato dele.
func _car_ground(g: Rect2, c: Dictionary) -> PackedVector2Array:
	var m: Dictionary = CAR_KINDS[c["kind"]]
	var lane: Vector2 = CAR_LANES[c["lane"]]
	var x := _car_x(c)
	var back: float = x - lane.y * (m["len"] + 0.2)
	var front := x + lane.y * 0.2
	return _patch(g, minf(front, back), maxf(front, back), lane.x - m["wide"] / 2.0 - 0.15, lane.x + m["wide"] / 2.0 + 0.15)


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
	var tones: Array = c["tones"]
	var tone := func(k: int) -> Color: return tones[Pal.CAR_MID + k]   # a sombra fria e a luz quente da lataria
	var body: Color = tone.call(0)
	var wet := weather == "rain"
	var top: Color = tone.call(-1).lerp(Pal.CAR_SKY, 0.3 if wet else 0.15)   # molhado, espelha mais o céu
	var roof := top.lerp(Pal.CAR_SKY, 0.1).lightened(0.12)   # o teto, mais claro que os vidros (no mesmo tom, a cabine parecia quebrada)
	var glass := Pal.CAR_GLASS.lerp(Pal.CAR_SKY, 0.45)   # o céu refletido: quase preto, o vidro sumia no asfalto atrás e o carro parecia só a lataria, baixo
	roof = roof.lerp(Pal.SUN_RIM, 0.25 * _sunlit())   # (com o sol, o teto e os vidros espelham o céu dourado)
	glass = glass.lerp(Pal.DAWN_CLOUD, 0.3 * _sunlit())
	var chrome := Pal.CAR_CHROME
	_poly(_car_ground(g, c), Color(0, 0, 0, 0.55))   # o contato com o asfalto
	var beam := Color(1.0, 0.95, 0.8, 0.12)   # o facho dos faróis, sumindo à frente (inteiro, era uma laje cinza colada no carro)
	_fill(PackedVector2Array([_o(g, x, z0 + 0.2), _o(g, x, z1 - 0.2), _o(g, x + d * BEAM, z1 + 0.5), _o(g, x + d * BEAM, z0 - 0.5)]),
		PackedColorArray([beam, beam, Color(beam, 0.0), Color(beam, 0.0)]))
	if m.has("bed"):   # a caçamba: o fundo dela, mais escuro, entre as paredes
		var bed: Vector2 = m["bed"]
		var bs: Vector2 = span.call(bed.x, bed.y)
		_poly(_patch(g, bs.x, bs.y, z0 + 0.08, z1 - 0.08, 0.75), tone.call(-3))
		_poly(PackedVector2Array([_o(g, bs.x, z1 - 0.08, 0.75), _o(g, bs.y, z1 - 0.08, 0.75), _o(g, bs.y, z1 - 0.08, m["belt"]),
			_o(g, bs.x, z1 - 0.08, m["belt"])]), tone.call(-2))   # a parede de lá, por dentro
		_poly(_patch(g, bs.x, bs.y, z1 - 0.08, z1, m["belt"]), top.lightened(0.1))   # as beiras dela, a de lá e a de cá
		_poly(_patch(g, bs.x, bs.y, z0, z0 + 0.08, m["belt"]), top.lightened(0.1))
		var back: float = at.call(m["cab"][3].x)   # a parede de trás da cabine, virada para a caçamba
		if d * back > 0.0:
			_poly(PackedVector2Array([_o(g, back, z0, 0.75), _o(g, back, z1, 0.75), _o(g, back, z1, 1.75), _o(g, back, z0, 1.75)]),
				tone.call(-1))
			var gl := PackedVector2Array([_o(g, back, z0 + 0.4, 1.2), _o(g, back, z1 - 0.4, 1.2), _o(g, back, z1 - 0.4, 1.6),
				_o(g, back, z0 + 0.4, 1.6)])
			if gl[1].distance_to(gl[0]) >= 3.0 * PX:   # o vidro de trás (de viés, mais estreito que isso, era um borrão no teto)
				_poly(gl, glass)
	var boxes: Array = m.get("box_col", tones)
	var box: Color = boxes[Pal.CAR_MID]
	if m.has("box") and d * x < 0.0:   # a parede da frente do baú, acima da cabine, enquanto ele vem
		var bx: float = at.call(m["box"][0].x)
		var bh: float = m["box"][1].y
		_poly(PackedVector2Array([_o(g, bx, z0, m["belt"]), _o(g, bx, z1, m["belt"]), _o(g, bx, z1, bh), _o(g, bx, z0, bh)]),
			boxes[Pal.CAR_MID - 1])
	for t: Vector3 in m["tops"]:   # o que se vê de cima: capô, teto, porta-malas (e o teto do baú)
		var ts: Vector2 = span.call(t.x, t.y)
		var tc: Color = boxes[Pal.CAR_MID - 2] if m.has("box") and t.x >= m["box"][0].x else (roof if t.z > 1.3 else top)
		_poly(_patch(g, ts.x, ts.y, z0, z1, t.z), tc)
	if c.get("rack", false):   # o bagageiro no teto: a grade cromada e a carga embaixo da lona amarrada
		var rt: Vector3 = (m["tops"] as Array).filter(func(t: Vector3) -> bool: return t.z > 1.3)[0]
		var rs: Vector2 = span.call(rt.x + 0.05, rt.y - 0.05)
		var ls: Vector2 = span.call(rt.x + 0.2, rt.y - 0.25)
		var lh := rt.z + 0.38
		_poly(_patch(g, ls.x, ls.y, z0 + 0.22, z1 - 0.22, lh), Pal.CAR_LOAD[1])
		_poly(PackedVector2Array([_o(g, ls.x, z0 + 0.22, rt.z), _o(g, ls.y, z0 + 0.22, rt.z), _o(g, ls.y, z0 + 0.22, lh), _o(g, ls.x, z0 + 0.22, lh)]), Pal.CAR_LOAD[0])
		for u in [0.33, 0.66]:   # as cordas
			var ux := lerpf(ls.x, ls.y, u)
			_poly(PackedVector2Array([_o(g, ux - 0.03, z0 + 0.2, rt.z), _o(g, ux + 0.03, z0 + 0.2, rt.z), _o(g, ux + 0.03, z0 + 0.2, lh), _o(g, ux - 0.03, z0 + 0.2, lh)]), tone.call(-3))
		_poly(PackedVector2Array([_o(g, rs.x, z0 + 0.1, rt.z + 0.06), _o(g, rs.y, z0 + 0.1, rt.z + 0.06), _o(g, rs.y, z0 + 0.1, rt.z + 0.14),
			_o(g, rs.x, z0 + 0.1, rt.z + 0.14)]), chrome)   # a grade do lado de cá, na frente da carga
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
		var fc: Array = boxes if m.has("box") and not front else tones
		_poly(PackedVector2Array([_o(g, face.x, z0, 0.3), _o(g, face.x, z1, 0.3), _o(g, face.x, z1, face.y), _o(g, face.x, z0, face.y)]),
			fc[Pal.CAR_MID - 1])
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
		_poly(up, Pal.CAR_UPPER)
	var win := PackedVector2Array()
	for p: Vector2 in m["win"]:
		win.append(_o(g, at.call(p.x), z0 + 0.05, p.y))
	_poly(win, glass)
	var wb: Vector2 = Vector2(m["win"][0].y, m["win"][1].y)   # a altura dos vidros: para as colunas
	for a: float in m["pillars"]:   # as colunas
		_ci.draw_line(_o(g, at.call(a), z0, wb.x), _o(g, at.call(a), z0, maxf(wb.y, m["win"][2].y)), Pal.CAR_UPPER if m.has("upper") else body, PX)
	var w0: Vector2 = m["win"][0]
	var w1: Vector2 = m["win"][1]
	_ci.draw_line(_o(g, at.call(lerpf(w0.x, w1.x, 0.6) + 0.1), z0, lerpf(w0.y, w1.y, 0.5)), _o(g, at.call(w1.x + 0.3), z0, w1.y - 0.05),
		Pal.CAR_GLINT, PX)   # o reflexo
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
			_o(g, tx + 0.25, z0 + 0.6, cab.z + 0.16), _o(g, tx - 0.25, z0 + 0.6, cab.z + 0.16)]), Pal.TAXI_SIGN)
		var tc := _o(g, tx, z0 + 0.6, cab.z + 0.08)
		_light_fan(tc, _ring(tc, 0.5 * OUT_F / z0), Color(Pal.TAXI_SIGN, 0.3))
	var r: float = m["wheel"]
	_ci.draw_set_transform(Vector2.ZERO)   # as rodas em pixel art, em px da tela
	for wx2: float in m["wheels"]:   # o arco do para-lama, o pneu e a calota
		var mid := _o(g, at.call(wx2), z0, r) * 2.0
		var dia := maxi(3, roundi(r * 2.0 * OUT_F / z0 * 2.0))
		var arch := dia + 2
		if m.get("fenders", false):   # o para-lama saltado do Fusca, com a luz na beira de cima
			PixelArt.sprite(_ci, PixelArt.disc(arch + 2, [[(arch + 2) / 2.0, tone.call(1)]]), mid - Vector2(0, 2))
		PixelArt.sprite(_ci, PixelArt.disc(arch, [[arch / 2.0, tone.call(-4)]]), mid - Vector2(0, 1))
		PixelArt.sprite(_ci, PixelArt.disc(dia, [[dia * 0.22, Pal.CAR_HUBCAP[2], Pal.CAR_HUBCAP[1], Pal.CAR_HUBCAP[0]],
			[dia / 2.0, Pal.CAR_TYRE[2], Pal.CAR_TYRE[1], Pal.CAR_TYRE[0]]]), mid)
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	if wet:
		_spray(g, c, m, at, z0)
	var k := OUT_F / z0
	var w := maxf(1.0, 0.2 * k)
	# o farol e a lanterna do lado de cá, só na ponta que não está virada para nós (nela, o par de baixo já tem a do
	# lado: com as duas, a traseira do Fusca tinha três lanternas)
	if not (face.y > 0.0 and front):
		var hl := _o(g, at.call(m.get("lamp_at", 0.0)), z0, m["lamp"])
		_r(hl.x - PX if d < 0.0 else hl.x - w + PX, hl.y - 0.08 * k, w, maxf(1.0, 0.16 * k), Pal.CAR_HEAD)   # o farol
		_light_fan(hl, _ring(hl, 0.35 * k), Color(Pal.CAR_HEAD, 0.3))
	if not (face.y > 0.0 and not front):
		var tw := maxf(PX, 0.15 * k)
		var tl := _o(g, rear, z0, m["lamp"] + 0.05)
		_r(tl.x - tw if d < 0.0 else tl.x, tl.y - 0.08 * k, tw, maxf(1.0, 0.16 * k), Pal.CAR_TAIL)   # a lanterna
		_light_fan(tl, _ring(tl, 0.25 * k), Color(Pal.CAR_TAIL.lightened(0.3), 0.3))
	if face.y > 0.0:   # de frente (ou de costas) para nós, o par de faróis (ou de lanternas) acesos, com o halo
		for zl: float in [z0 + 0.3, z1 - 0.3]:
			var p := _o(g, face.x, zl, m["lamp"] + (0.0 if front else 0.05))
			var kk := OUT_F / zl
			var col := Pal.CAR_HEAD if front else Pal.CAR_TAIL
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


## A árvore da nossa calçada, embaixo da janela (`SHRUB`, com a cerca viva embaixo, `HEDGE`): o tronco sobe do
## peitoril e só a copa aparece, em tufos, atrás do vidro, posta pela parede da sala (`_side_pt`) e não pela câmera da
## vista; os galhos (`BRANCHES`) aparecem entre os tufos. Folhas em quatro tons (as de cima pegando a luz da rua),
## maiores do lado de perto, mexendo com o vento.
func _draw_shrub() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var t := Time.get_ticks_msec() / 1000.0
	var wind := {"rain": 0.5 + rain_level(), "clear": 0.6, "fog": 0.3}.get(weather, 0.6) as float
	# as rajadas: o vento cresce e some em ondas lentas e empurra a copa para um lado (`GUST`)
	var gust := pow(maxf(0.0, sin(t * GUST.x) * sin(t * GUST.y + 1.3)), 0.6)
	var tones := Pal.SHRUB
	var f := _flash()
	var sun := _sunlit()   # (a copa, no alto, pega o sol)
	_ci.draw_set_transform(Vector2.ZERO)   # as folhas em px da tela
	var gw := SIDE_W
	var gh := _cm(WIN_SILL - WIN_TOP)
	var clumps: Array[Vector3] = []   # os tufos da copa (x, altura, raio em px), de baixo para cima: o de cima cobre a beira de baixo do outro
	for j in CLUMPS:
		var ch := lerpf(0.0, SHRUB.z * 0.85, pow(rng.randf(), 0.7))
		var cr := SHRUB.y * sqrt(maxf(0.0, 1.0 - pow(ch / SHRUB.z, 2.0)))   # a copa: redonda, mais larga embaixo
		clumps.append(Vector3(rng.randf_range(-cr, cr) * 0.75, ch, rng.randf_range(CLUMP_R.x, CLUMP_R.y)))
	clumps.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.y < q.y)
	var at := func(dx: float, hgt: float) -> Vector2:   # um ponto da árvore (fração do vão, do meio dela e acima do peitoril) em px da tela
		return ((_side_pt(Vector2((SHRUB.x + dx) * gw, gh * (1.0 - hgt)), WALL_D + 8.0) - _view_at) * 2.0).floor()
	var foot: Vector2 = at.call(-0.02, -0.1)
	for j in BRANCHES:   # os galhos, do tronco ao meio de um tufo, mexendo com a copa
		var cl := clumps[clumps.size() - 1 - j * 3]
		var tip: Vector2 = at.call(cl.x, cl.y) + Vector2(roundf(-gust * GUST.z * wind * cl.y / SHRUB.z), 0)
		var fork: Vector2 = at.call(cl.x * 0.3, cl.y * 0.4)
		var bark: Color = Pal.TREE_BARK[1 if cl.x > 0.0 else 0].lerp(Pal.SHRUB_FLASH, f * 0.3)
		_ci.draw_line(foot, fork, bark, 3.0)
		_ci.draw_line(fork, tip, bark, 2.0 if j < 2 else 1.0)
	for i in CLUMPS * CLUMP_LEAVES + HEDGE:
		var hgt := 0.0
		var r := SHRUB.y
		var dx := 0.0
		var up := 0.0   # onde a folha fica no tufo dela: 1 no alto, -1 embaixo (o volume e a beira acesa)
		if i < CLUMPS * CLUMP_LEAVES:
			var cl := clumps[floori(float(i) / CLUMP_LEAVES)]
			var o := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * Vector2(cl.z, cl.z * 0.7)
			dx = cl.x + o.x / gw
			hgt = cl.y - o.y / gh
			r = absf(cl.x) + cl.z / gw
			up = -o.y / (cl.z * 0.7)
		else:   # a cerca viva embaixo dela, até o batente de perto
			hgt = rng.randf_range(-0.08, 0.035)
			dx = rng.randf_range(-r, 1.05 - SHRUB.x)
		var w := Vector2((SHRUB.x + dx) * gw, gh * (1.0 - hgt) + rng.randf_range(-1.0, 1.0))
		var p := (_side_pt(w, WALL_D + 8.0) - _view_at) * 2.0   # do lado de fora, atrás do vidro
		var k := clampf(_side_pt(w + Vector2(0, 1)).y - _side_pt(w).y, 0.8, 1.6)   # a escala da parede ali
		var sway := roundf((sin(t * (1.4 + gust) + i * 0.7) * (1.0 + gust) - gust * GUST.z) * wind * maxf(hgt, 0.0) / SHRUB.z * 1.5)
		var lit := clampf(maxf(hgt, 0.0) / SHRUB.z * 0.5 + up * 0.25 + 0.15 + (dx / maxf(0.01, r)) * 0.1 + rng.randf_range(-0.2, 0.15), 0.0, 0.99)
		var c: Color = (tones[int(lit * tones.size())] as Color).lerp(Pal.SHRUB_FLASH, f * 0.5)
		# o sol baixo: as folhas acendem de verde-amarelo, mais nos tufos do alto e na beira de cima de cada um, e as
		# de baixo do tufo ficam no verde-escuro (`Pal.LEAF_SUN`)
		c = c.lerp(_sunny(Pal.LEAF_SUN[0]), sun * clampf(lit * 0.9, 0.0, 0.7))
		c = c.lerp(_sunny(Pal.LEAF_SUN[1]), sun * 0.75 * smoothstep(0.4, 0.9, up) * (0.4 + 0.6 * hgt / SHRUB.z))
		var px := p.floor() + Vector2(sway, 0)
		var lw := roundf(6.0 * k)
		var lh := roundf(4.0 * k)
		_ci.draw_rect(Rect2(px, Vector2(lw, lh)), c)
		_ci.draw_rect(Rect2(px + Vector2(1, -1), Vector2(lw - 2, 1)), c)
		_ci.draw_rect(Rect2(px + Vector2(1, lh), Vector2(lw - 2, 1)), c.darkened(0.3))
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))


## O letreiro de neon do hotel, preso na fachada do outro lado (`o`: o alto dele): HOTEL de cima para baixo, na fonte
## gravada da mesa comutadora (`PixelArt.tiny`). Aceso quase sempre (`_sign_on`); o T falha sozinho.
func _draw_hotel_sign(o: Vector2) -> void:
	_r(o.x + SIGN.x, o.y + 3, 2.5, PX, Pal.LAMP_POST)   # o braço
	var on := _sign_on()
	_r(o.x, o.y, SIGN.x, SIGN.y, Pal.SIGN_BOX[1 if on else 0])   # a caixa: a beira pega o vermelho do neon
	_r(o.x + PX, o.y + PX, SIGN.x - 2 * PX, SIGN.y - 2 * PX, Pal.SIGN_BOX[0])
	var buzz := _sign_t_on()
	_sign_letters(o * 2.0, func(i: int) -> Color: return Pal.SIGN_RED if (buzz if i == 2 else on) else Pal.SIGN_OFF)


## As letras do letreiro do hotel a partir de `at` (o canto da caixa, px da tela), cada uma na cor `col(i)` (`null`:
## não desenha), centradas na caixa.
func _sign_letters(at: Vector2, col: Callable) -> void:
	_ci.draw_set_transform(Vector2.ZERO)
	var asc := Pal.mono.get_ascent(11)
	for i in 5:
		var c: Variant = col.call(i)
		if c != null:
			var w := Pal.mono.get_char_size("HOTEL".unicode_at(i), 11).x
			_ci.draw_char(Pal.mono, (at + Vector2((SIGN.x * 2.0 - w) / 2.0, 2 + i * SIGN_STEP + asc - 2)).floor(), "HOTEL"[i], 11, c)
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
	var tall := RandomNumberGenerator.new()   # os prédios altos atrás da igreja, também à parte
	tall.seed = 1960
	for r in [0, 1, 2]:
		var k: float = OUT_F / FAR_ROWS[r].x
		var rr := tall if r == 2 else rng
		var x := -rr.randf() * 4.0
		while x < gs.x:
			var bw := rr.randf_range(15.0, 35.0) * k if r < 2 else rr.randf_range(12.0, 22.0) * k
			var bh := (rng.randf_range(30.0, 80.0) if r == 0 else rng.randf_range(15.0, 45.0) if r == 1 else rr.randf_range(90.0, 170.0)) * k
			var lit: Array[Vector3] = []
			var yy := 1.5
			while yy < bh - 1.0:
				var xx := 1.0
				while xx < bw - 1.0:
					if rr.randf() < 0.2:
						lit.append(Vector3(xx, yy, off.call() if r < 2 else rr.randf_range(SLEEP.x, SLEEP.y)))   # (o sorteio das outras fica o mesmo)
					xx += 2.0
				yy += 2.0
			_city.append({"x": x, "w": bw, "h": bh, "row": r, "lit": lit})
			x += bw + rr.randf_range(0.0, 1.5)
	_houses.clear()
	var tones := Pal.FACADE_TONES
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
				elif i == 0 and f > 0 and up.randf() < BRICK_LIT:   # o prédio de tijolos, o mais perto, tem mais gente em casa (à parte: o sorteio dos outros fica o mesmo)
					o = up.randf_range(22 * 60, SLEEP.y)
				wins.append(Vector3(wsx, f, o))
				wsx += 3.0
		var wake := {}   # janela -> quando ela acende de novo (min do dia, de x a y)
		for j in wins.size():
			var wv := wins[j]
			if wv.y > 0.0 and wv.z < INF and up.randf() < WAKE:
				var at := up.randf_range(maxf(wv.z, WAKE_FROM) + 10.0, 23 * 60 + 50)
				wake[j] = Vector2(at, at + up.randf_range(WAKE_FOR.x, WAKE_FOR.y))
			elif wv.z < INF and up.randf() < WAKE_DAWN:   # de madrugada, gente acordando: acende e fica
				wake[j] = Vector2(up.randf_range(MORNING.x - 30.0, MORNING.y - 10.0), INF)
		_houses.append({"x0": sp.x, "x1": sp.y, "h": floors * 3.2 + 0.8, "tones": Pal.BRICK_TONES if i == 0 else tones[rng.randi_range(0, 3)],
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
			var shops: Array[Vector3] = []   # o térreo: portas e lojas (z do meio, largura, hora de fechar; -1: fechada)
			var zs := z + rng.randf_range(1.0, 2.5)
			while zs < z + d - 2.5 and z < SHOP_Z:
				var wide := rng.randf() < 0.55
				var open := rng.randf() < 0.45
				shops.append(Vector3(zs + (1.0 if wide else 0.5), 2.0 if wide else 1.0, rng.randf_range(19 * 60, 23 * 60 + 50) if open else -1.0))
				zs += (2.0 if wide else 1.0) + rng.randf_range(1.2, 3.5)
			_canyon.append({"x": side, "z0": z, "z1": z + d, "h": ht, "tones": tones[rng.randi_range(0, 3)], "wins": wins, "shops": shops})
			z += d
	_canyon.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["z0"] < b["z0"])


## A igreja no fim da rua do cruzamento (na escala dela, `CHURCH_K`): nave, torre com a ponta e o relógio no alto, sem
## luz nenhuma (a porta e o relógio acesos saíram, a pedido).
func _draw_church(g: Rect2, col: Color) -> void:
	var k := CHURCH_K
	var base := _church_pos(g)
	for part: PackedVector2Array in _church_parts(base):
		_poly(part, col)
	base.x = floorf(base.x / PX) * PX + PX / 2.0
	for i in 2:   # a beira de cada degrau, pegando a luz do céu
		_r(base.x - (17 - 3 * i) * k, base.y - (2 + 2 * i) * PX, (34 - 6 * i) * k, PX, col.lightened(0.12))
	var face := Vector2(base.x, roundf((base.y - CHURCH_TOWER.z * k) / PX) * PX)
	_r(face.x - 1.5 * PX, face.y - PX, 3 * PX, 3 * PX, col.lightened(0.15))   # o mostrador, apagado
	_r(face.x - PX / 2.0, face.y - PX, PX, 2 * PX, Pal.CHURCH_CLOCK)   # os ponteiros
	# o campanário vazado, acima do relógio: o arco com o céu atrás e o sino pendurado nele (lisa, a torre era só uma
	# mancha; o céu de trás, não luz na frente dela)
	var bell := Vector2(base.x, roundf((base.y - (CHURCH_TOWER.x - 2.0) * k) / PX) * PX)
	var sky := _sunny(_sky_at(g, bell.y))
	_r(bell.x - 1.5 * PX, bell.y, 3 * PX, 5 * PX, sky)
	_r(bell.x - 0.5 * PX, bell.y - PX, PX, PX, sky)
	_r(bell.x - 0.5 * PX, bell.y, PX, 3 * PX, col)


## O letreiro do hotel refletido no vidro da janela da sala: o fantasma dele, as letras de novo, fracas e um pouco
## deslocadas (a outra face do vidro), acesas como as de verdade: apaga com o neon e o T falha junto. Na chuva, as gotas
## perto dele pegam o vermelho (`_draw_glass_weather`).
func _draw_neon_glass(g: Rect2) -> void:
	if not _sign_on():
		return
	var o := _hotel_pos(Rect2(g.position, g.size - Vector2(0, _near)))
	var t := _sign_t_on()
	_sign_letters(o * 2.0 + NEON_SHIFT, func(i: int) -> Variant: return Color(Pal.SIGN_RED, NEON_GHOST) if i != 2 or t else null)


## A força do letreiro no vidro: 1 aceso, menos com o T falhando (uma letra de cinco), 0 apagado.
func _neon_on_glass() -> float:
	return 0.0 if not _sign_on() else (1.0 if _sign_t_on() else NEON_T_OFF)


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
		var sign := _hotel_pos(Rect2(g.position, g.size - Vector2(0, _near))) + SIGN / 2.0
		var neon := _neon_on_glass()
		for b in _beads:
			var p := Vector2(g.position.x + floorf(b.x * g.size.x * 2.0) * PX, top + floorf(b.y * (g.end.y - top) * 2.0) * PX)
			if b.w > 0.0:   # escorrendo: o rastro molhado acima dela
				for k in 4:
					_r(p.x, p.y - (k + 1) * PX, PX, PX, Color(0.55, 0.66, 0.74, 0.2 - k * 0.045))
			_r(p.x, p.y, b.z * PX, b.z * PX, Pal.RAIN_BEAD[0])
			var warm := clampf(1.0 - p.distance_to(post) / 30.0, 0.0, 1.0) if _posts_on() else 0.0
			var red := clampf(1.0 - p.distance_to(sign) / NEON_BEADS, 0.0, 1.0) * neon   # e vermelho perto do letreiro
			_r(p.x, p.y, PX, PX, Pal.RAIN_BEAD[1].lerp(Pal.STREET_LAMP, warm).lerp(Pal.SIGN_RED, red * 0.8))
	_draw_neon_glass(g)
	_poly(PackedVector2Array([g.position + Vector2(g.size.x * 0.12, 0), g.position + Vector2(g.size.x * 0.22, 0),
		g.position + Vector2(g.size.x * 0.02, g.size.y * 0.5), g.position + Vector2(0, g.size.y * 0.5)]), Color(1, 1, 1, 0.03))
