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
