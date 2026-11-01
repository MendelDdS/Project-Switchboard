extends Resource
## Um texto que só vale com os marcadores certos (`StoryFlags.allows`): uma versão do bilhete do supervisor ou uma
## matéria do jornal que depende do que o jogador fez (`Night.notes`, `Night.news_if`).

@export_multiline var text := ""
## O título, nos textos de uma tela inteira (`Night.endings`; vazio: o de toda noite).
@export var title := ""
## Os marcadores que precisam bater ("nome" ligado, "!nome" desligado; vazio: sempre).
@export var requires: PackedStringArray = []
