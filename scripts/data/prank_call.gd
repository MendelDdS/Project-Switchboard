class_name PrankCall
extends Resource
## Roteiro de um trote.

@export_enum("f", "m", "k", "w") var voice := "k"
@export var caller := ""
## Endereço falso que vai para o caderno ("—" se não houver).
@export var fake_address := "—"
## Na ligação do roteiro (`StoryCall`): um trote de verdade, que o caderno registra como trote; desligado, a conversa
## do roteiro é ligação comum.
@export var prank := false
@export var steps: Array[PrankStep] = []
