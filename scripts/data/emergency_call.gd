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
## Depois de contar, o operador ganha uma pergunta sobre o que mudou (`worsening_question` e a resposta).
@export var worsening := ""
@export var worsening_units: PackedStringArray = []
@export var worsening_question := ""
@export var worsening_answer := ""
## O que ela conta quando fica crítica, as unidades a mais e a pergunta sobre isso.
@export var critical := ""
@export var critical_units: PackedStringArray = []
@export var critical_question := ""
@export var critical_answer := ""
## A reclamação quando o pior acontece (dá para despachar ainda, mas a emergência está perdida). As perguntas que
## sobraram saem (menos o endereço, a primeira) e fica "Tem alguém ferido?": `lost_answer` diz o estado agora, e
## `lost_units` o que isso passa a exigir.
@export var lost := ""
@export var lost_answer := ""
@export var lost_units: PackedStringArray = []


## Unidades necessárias no estágio `stage` (0 inicial, 1 agravando, 2 agravada, 3 perdida).
func required(stage: int) -> PackedStringArray:
	var out := units.duplicate()
	var more := PackedStringArray()
	for s in [[1, worsening_units], [2, critical_units], [3, lost_units]]:
		if stage >= s[0]:
			more += s[1]
	for u in more:
		if not u in out:
			out.append(u)
	return out
