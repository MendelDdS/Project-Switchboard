class_name EmergencyCase
extends Resource
## Uma variação de uma emergência (EmergencyCall.cases): o que muda nas respostas e, por isso, quais unidades
## resolvem. Assim o mesmo roteiro (ex.: incêndio) pode pedir só bombeiros ou bombeiros e ambulância.

## Respostas na ordem das perguntas; "" mantém a resposta do roteiro.
@export var answers: PackedStringArray = []
## Unidades necessárias neste caso ("pol", "bomb", "amb"): o que as respostas revelam, pelo protocolo.
@export var units: PackedStringArray = []
