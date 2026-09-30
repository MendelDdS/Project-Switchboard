class_name PrankStep
extends Resource
## Um passo do roteiro de um trote.

enum Kind {
	CALLER,    ## o solicitante fala `text`
	OPERATOR,  ## o operador escolhe uma das `options`
	PAUSE,     ## silêncio de `seconds`
	END,       ## desligam do outro lado
}

@export var kind := Kind.CALLER
@export var text := ""
@export var options: PackedStringArray = []
@export var seconds := 0.0
