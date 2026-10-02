class_name ChatTopic
extends Resource
## Um assunto de conversa fiada: quem espera a transferência puxa `line` (sozinha ou porque o operador puxou
## conversa); as `replies` viram opções do operador e a pessoa continua com a `follow` da resposta escolhida.
## Cada assunto traz as próprias respostas, para nenhuma resposta cair fora do assunto.

## Clima em que o assunto faz sentido (vazio = qualquer um).
@export_enum("Qualquer:", "rain", "fog", "clear") var weather := ""
## Vozes que podem dizer o assunto (`PhoneCall.voice`: "f", "m", "w"...; vazio = qualquer uma): "Meu marido..." só
## numa voz de mulher.
@export var voices: PackedStringArray = []
@export var line := ""
## Respostas do operador.
@export var replies: PackedStringArray = []
## Continuação de quem ligou para cada resposta, na mesma ordem de `replies`.
@export var follow: PackedStringArray = []
