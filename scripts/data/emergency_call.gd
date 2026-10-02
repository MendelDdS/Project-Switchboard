class_name EmergencyCall
extends Resource
## Roteiro de uma emergência: o que a pessoa diz, onde é (trecho do mapa) e quais unidades resolvem.

@export_enum("f", "m", "k", "w") var voice := "f"
@export var caller := ""
@export_multiline var opening := ""
## Perguntas do operador e as respostas, na mesma ordem.
@export var questions: PackedStringArray = []
@export var answers: PackedStringArray = []

@export_group("Local e resposta")
## `id` da rua em GameContent.streets.
@export var street := ""
## Trecho da rua: 0 = 1–99, 1 = 100–199, 2 = 200–299.
@export_range(0, 2) var block := 0
@export var address := ""
@export var occurrence := ""
## Unidades necessárias ("pol", "bomb", "amb"), pelo protocolo: polícia para crime, briga, arma ou rua
## bloqueada; bombeiros para fogo, fumaça, fio ou gás, ou alguém preso; ambulância para alguém ferido, passando
## mal ou preso (batida leve sem feridos não leva). As respostas precisam revelar cada uma delas, sem ambiguidade (o tipo da ocorrência não marca nada).
@export var units: PackedStringArray = []
## Variações sorteadas a cada vez (vazio = sempre como acima); cada caso troca respostas e unidades.
@export var cases: Array[EmergencyCase] = []
## O que a pessoa diz quando as unidades são enviadas.
@export var after := ""

@export_group("Agravamento")
## Enquanto ninguém despacha, a situação piora (barra abaixo da conversa; para durante pergunta e resposta).
## Segundos de cada estágio: inicial, agravando, agravada; depois disso está perdida. Situações perigosas
## (fogo, AVC) correm mais rápido.
@export var stage_sec := Vector3(45.0, 22.0, 22.0)
## O que a pessoa conta quando a situação começa a piorar e as unidades que isso passa a exigir (somam às do caso).
@export var worsening := ""
@export var worsening_units: PackedStringArray = []
## O que ela conta quando fica crítica, e as unidades a mais.
@export var critical := ""
@export var critical_units: PackedStringArray = []
## A reclamação quando o pior acontece (dá para despachar ainda, mas a emergência está perdida).
@export var lost := ""


## Unidades necessárias no estágio `stage` (0 inicial, 1 agravando, 2 agravada ou depois).
func required(stage: int) -> PackedStringArray:
	var out := units.duplicate()
	for u in (worsening_units if stage >= 1 else PackedStringArray()) + (critical_units if stage >= 2 else PackedStringArray()):
		if not u in out:
			out.append(u)
	return out
