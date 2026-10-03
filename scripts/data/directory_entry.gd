class_name DirectoryEntry
extends Resource
## Uma linha da lista telefônica. O número também é a tomada de destino na mesa.

@export var name := ""
## Quem atende, quando o nome não diz (ex.: "Pe. Anselmo" na Casa Paroquial, "recepção" na clínica).
@export var note := ""
@export var address := ""
@export var number := ""
## Polícia, bombeiros e hospital: não têm tomada na mesa; vão pelo despacho.
@export var dispatch_only := false
## Como as pessoas se referem ao lugar ao pedir o número (ex.: "o Hotel Estrela"). Vazio = ninguém pede.
@export var spoken := ""
## Por que alguém liga para cá, uma frase cada (lacuna {reason} dos moldes). Vazio = não entra nos moldes.
@export var reasons: PackedStringArray = []
