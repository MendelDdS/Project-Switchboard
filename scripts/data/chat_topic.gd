class_name ChatTopic
extends Resource
## Um assunto de conversa fiada: quem espera a transferência puxa `line`; o operador pode responder com uma das
## `replies` (sorteada, aparece como opção) e a pessoa continua com a `follow` do mesmo índice.
## Cada assunto traz as próprias respostas, para nenhuma resposta cair fora do assunto.

## Clima em que o assunto faz sentido (vazio = qualquer um).
@export_enum("Qualquer:", "rain", "fog", "clear") var weather := ""
@export var line := ""
## Respostas do operador.
@export var replies: PackedStringArray = []
## Continuação de quem ligou para cada resposta, na mesma ordem de `replies`.
@export var follow: PackedStringArray = []
