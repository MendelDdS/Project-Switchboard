extends Resource
## Uma tarefa do roteiro no diário de Maria (`Night.tasks`, `Diary`): o que alguém pediu a ela na noite (uma ligação,
## a carta, o bilhete do supervisor). Entra quando os marcadores deixam (`requires`, ou no começo da noite) e fica até o
## fim dela; riscada pelos marcadores de `done`, com X se o prazo passa. Os pedidos de "não fazer" (`at_close`) só se
## resolvem no turno encerrado. Pedidos que se contradizem entram os dois.

@export var text := ""   ## como Maria anotou (português; traduzido ao mostrar)
## Quando entra (`StoryFlags.allows`; vazio: no começo da noite). Uma vez anotada, fica, mesmo que o marcador desligue.
@export var requires: PackedStringArray = []
@export var letter := false   ## pedido da carta da noite: entra só depois de lida
## Cumprida com estes marcadores (`StoryFlags.allows`: todos; com `done_any`, qualquer um deles).
@export var done: PackedStringArray = []
@export var done_any := false
@export var until := -1.0      ## minutos do turno: passou sem cumprir, X (-1: sem prazo; o X vem com o turno fechando)
@export var at_close := false  ## só se resolve no turno encerrado (o pedido de não fazer algo): cumprida ou X


## Os marcadores `f` cumprem a tarefa.
func met(f: StoryFlags) -> bool:
	if not done_any:
		return f.allows(done)
	for d in done:
		if f.allows([d]):
			return true
	return false
