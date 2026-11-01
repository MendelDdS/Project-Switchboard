extends Resource
## Um texto que só vale com os marcadores certos (`StoryFlags.allows`): uma versão do bilhete do supervisor ou uma
## matéria do jornal que depende do que o jogador fez (`Night.notes`, `Night.news_if`).

@export_multiline var text := ""
## Os marcadores que precisam bater ("nome" ligado, "!nome" desligado; vazio: sempre).
@export var requires: PackedStringArray = []
