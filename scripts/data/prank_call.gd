class_name PrankCall
extends Resource
## Roteiro de um trote.

@export_enum("f", "m", "k", "w") var voice := "k"
@export var caller := ""
## Endereço falso que vai para o caderno ("—" se não houver).
@export var fake_address := "—"
@export var steps: Array[PrankStep] = []
