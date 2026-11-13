class_name ChatTopic
extends Resource
## Um assunto de conversa fiada: quem espera a transferência puxa `line` (sozinha ou porque o operador puxou
## conversa); as `replies` viram opções do operador e a pessoa continua com a `follow` da resposta escolhida.
## Cada assunto traz as próprias respostas, para nenhuma resposta cair fora do assunto. Os gerais ficam em
## `GameContent.smalltalk`; as novidades de uma noite, em `Night.smalltalk`.

## Clima em que o assunto faz sentido (vazio = qualquer um).
@export_enum("Qualquer:", "rain", "fog", "clear") var weather := ""
## Vozes que podem dizer o assunto (`PhoneCall.voice`: "f", "m", "w"...; vazio = qualquer uma): "Meu marido..." só
## numa voz de mulher.
@export var voices: PackedStringArray = []
## Só quando ela mesma puxa conversa: não cabe como resposta a "E aí, como vai a noite?" ("Desculpe ligar tão tarde.").
@export var unprompted_only := false
## Só aparece se os marcadores baterem (StoryFlags.allows): a cidade lembra do que o operador disse antes.
## Assunto com condição é novidade, como os da noite: vem antes dos outros e só uma vez por noite.
@export var requires: PackedStringArray = []
## Só no atendimento de um lugar pelo discador (`DirectoryEntry.answers`): as noites em que vale. Atendimento com
## noite ou condição é o da ocasião (a cidade lembra do que houve): vem no lugar dos de todo dia (`Conversation._outgoing`).
@export var from_night := 0
@export var to_night := 99
@export var line := ""
## Respostas do operador (de preferência uma simpática e uma seca).
@export var replies: Array[ChatReply] = []
