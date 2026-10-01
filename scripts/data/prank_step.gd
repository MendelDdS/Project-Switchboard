class_name PrankStep
extends Resource
## Um passo de um roteiro falado: trotes e a ligação desconhecida de cada noite (Night.mystery).

enum Kind {
	CALLER,    ## quem ligou fala `text` (e espera `seconds`, se houver)
	OPERATOR,  ## o operador escolhe uma das `options`
	PAUSE,     ## silêncio de `seconds`
	END,       ## desligam do outro lado
	EFFECT,    ## efeito na sala: `effect` = "static", "static_loud" ou "flick"
}

@export var kind := Kind.CALLER
@export var text := ""
@export var options: PackedStringArray = []
@export var seconds := 0.0
@export_enum("static", "static_loud", "flick") var effect := "static"
