class_name EmergencyCase
extends Resource
## Uma variação de uma emergência (EmergencyCall.cases): o que muda nas respostas e, por isso, quais unidades
## resolvem. Assim o mesmo roteiro (ex.: incêndio) pode pedir só bombeiros ou bombeiros e ambulância.

## Respostas na ordem das perguntas; "" mantém a resposta do roteiro.
@export var answers: PackedStringArray = []
## Unidades necessárias neste caso ("pol", "bomb", "amb"): o que as respostas revelam, pelo protocolo.
@export var units: PackedStringArray = []
## O que mais o caso troca, quando a história dele é outra ("" mantém o do roteiro): a fala de depois do socorro e as
## da piora (os mesmos campos da `EmergencyCall`; `GameData.with_case`).
@export var after := ""
@export var worsening := ""
@export var worsening_answer := ""
@export var critical := ""
@export var critical_answer := ""
@export var lost := ""
@export var lost_answer := ""
