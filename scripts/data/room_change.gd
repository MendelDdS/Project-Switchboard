class_name RoomChange
extends Resource
## Uma mudança na sala do operador (GameContent.room): um detalhe do cenário (`detail`, desenhado por `Background`)
## que aparece entre duas noites, quando os marcadores do roteiro batem (`requires`, como em StoryCall). Assim o
## mistério e as escolhas do jogador também moram no cenário, não só nas ligações. Detalhes que existem
## (`Background.DETAILS`): o cartaz da quermesse e os panfletos do quadro de avisos (`Background.PINNED`).

@export var detail := ""
## Todos ligados ("!" = desligado); vazio = sempre. Vale na hora: um marcador ligado no meio da noite já muda a sala
## (a não ser que `from_night` ainda não tenha chegado).
@export var requires: PackedStringArray = []
@export_range(1, 15) var from_night := 1
@export_range(1, 15) var to_night := 15   ## a última noite em que ele está lá
