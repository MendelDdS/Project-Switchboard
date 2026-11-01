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
## Quão desconfiado quem atende aqui é da escuta: multiplica a de quem ligou (`TransferCall.wary`) na subida da
## suspeita (a pensão cismada, 1,6, percebe logo; o bar barulhento, 0,5, quase não nota).
@export_range(0.0, 3.0, 0.1) var wary := 1.0
## Quando o operador liga para cá (o discador, `Dialing`): cada atendimento é um assunto (`ChatTopic`), sorteado entre
## os que valem agora (`requires`, `weather`): a `line` é como atendem ("Rádio Serena, boa noite! O que deseja?") e as
## `replies`, as perguntas que o operador pode fazer (o `text`), cada uma com a resposta (`follow`) e os marcadores
## dela (`sets`; o `tone` não conta aqui). Vazio: ninguém atende.
@export var answers: Array[ChatTopic] = []
## A despedida quando o operador encerra (vazio: uma das gerais, `GameContent.dial_byes`).
@export var bye := ""
## Quando o lugar fecha e ninguém mais atende o discador (minutos depois das 18h; -1: atende a noite toda).
@export var closes := -1.0
## A última noite em que alguém atende o discador (depois, toca e ninguém atende; a Cecília, que largou o setor).
@export var answers_until := 99
## A noite em que o número deixa de existir (0: nunca).
@export var gone_from := 0
