class_name ChatReply
extends Resource
## Uma resposta do operador a um assunto de conversa fiada (`ChatTopic.replies`) e como a pessoa continua.

enum Tone {
	NEUTRAL,  ## só continua o assunto
	WARM,     ## simpática: ela gosta da conversa e espera mais antes de reclamar (`Conversation.CHAT_WARM_PATIENCE`)
	CURT,     ## seca: ela entende o recado e não puxa mais assunto nesta ligação
}

@export var text := ""
## O que quem ligou diz depois desta resposta.
@export var follow := ""
@export var tone := Tone.NEUTRAL
## Marcadores que esta resposta altera (StoryFlags.apply): "nome" liga, "!nome" desliga. Ex.: prometeu ir à quermesse.
@export var sets: PackedStringArray = []
