class_name DirectoryEntry
extends Resource
## Uma linha da lista telefônica. O número também é a tomada de destino na mesa.

@export var name := ""
## Quem atende, quando o nome não diz (ex.: "Pe. Anselmo" na Casa Paroquial, "recepção" na clínica).
@export var note := ""
@export var address := ""
@export var number := ""
## Ramo do estabelecimento (ex.: "farmácia"). Quando ele não atende, o operador pode oferecer outro do mesmo ramo
## (`GameData.alternative`); por isso só ganha ramo quem pode ser trocado por outro para qualquer um dos `reasons`.
## Vazio = sempre atende.
@export var category := ""
## Polícia, bombeiros e hospital: não têm tomada na mesa; vão pelo despacho.
@export var dispatch_only := false
## Como as pessoas se referem ao lugar ao pedir o número (ex.: "o Hotel Estrela"). Vazio = ninguém pede.
@export var spoken := ""
## Por que alguém liga para cá, cada um com a conversa que vem depois (`Motive`). Vazio = não entra nos moldes.
@export var motives: Array[Motive] = []
## Como o lugar atende o telefone ("Hotel Estrela, boa noite."): a primeira fala de quem escuta a linha (`Eavesdrop`).
## Vazio (as pessoas): um "alô" sorteado (`GameContent.overheard_hello`).
@export var hello := ""
## A voz de quem atende (`SfxSynth.VOICE`: f, m, k, w), para bater com o nome (a Dona Cota, o Zé). Vazio: uma pelo nome,
## sempre a mesma (`GameData.voice_of`).
@export var voice := ""
