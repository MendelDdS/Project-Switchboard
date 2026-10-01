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
## O passo só acontece se os marcadores baterem (StoryFlags): todos ligados; com "!" na frente, desligados.
@export var requires: PackedStringArray = []
## OPERATOR: o que cada opção faz nos marcadores, na mesma ordem de `options`: "nome" liga, "!nome" desliga, vazio nada.
@export var sets: PackedStringArray = []
