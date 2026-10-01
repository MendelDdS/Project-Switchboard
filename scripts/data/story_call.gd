class_name StoryCall
extends Resource
## Ligação do roteiro de uma noite: um roteiro escrito (TransferCall, EmergencyCall ou PrankCall) num horário fixo.
## Conta como qualquer outra ligação (advertências, retornos, caderno).

## Minutos depois do início do turno (18:00).
@export var at := 60.0
@export var call: Resource
