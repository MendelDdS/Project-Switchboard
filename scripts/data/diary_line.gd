extends Resource
## Uma linha das anotações do diário de Maria (`Night.diary`, `Diary`), na primeira pessoa. Escrita quando acontece o
## fato: o fim de uma ligação do roteiro (`call`, com um dos desfechos de `outcomes`), os marcadores (`requires`), a
## carta lida (`letter`); ou, com `at_close`, o balanço da noite, escrito com o turno fechando. Sem nenhuma condição,
## no começo da noite (só o que o bilhete do supervisor já contou: nada no diário antes de alguém avisar).

@export_multiline var text := ""   ## como Maria escreveu (português; traduzido ao mostrar)
## A ligação do roteiro desta noite (uma `StoryCall` de `Night.story`, `calls` ou de um `callback`) cujo fim escreve a
## linha, com um destes desfechos (`Main.story_ends`: "connected", "elsewhere", "dropped", "missed"; vazio: atendida).
@export var call: Resource
@export var outcomes: PackedStringArray = []
@export var requires: PackedStringArray = []   ## e os marcadores batendo (`StoryFlags.allows`)
@export var letter := false     ## só depois de lida a carta da noite
@export var at_close := false   ## o balanço: só com o turno fechando (`Main.ending`)


## A linha já pode ser escrita: `ends` são os desfechos das ligações do roteiro (`Main.story_ends`).
func due(f: StoryFlags, ends: Dictionary, read: bool, closing: bool) -> bool:
	if (at_close and not closing) or (letter and not read) or not f.allows(requires):
		return false
	if call == null:
		return true
	var end: String = ends.get(call, "")
	return end in outcomes if not outcomes.is_empty() else end not in ["", "missed"]
