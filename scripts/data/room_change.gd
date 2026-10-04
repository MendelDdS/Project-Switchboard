class_name RoomChange
extends Resource
## Uma mudança na sala do operador (GameContent.room): um detalhe do cenário (`detail`, desenhado por `Background`)
## que aparece a partir de uma noite, quando os marcadores do roteiro batem (`requires`, como em StoryCall). Assim o
## mistério e as escolhas do jogador também moram no cenário, não só nas ligações. Detalhes que existem:
## "cartaz_quermesse" (cartaz na parede), "numero_anotado" (bilhete com um número colado no armário) e
## "armario_entreaberto" (a porta direita do armário de aço aberta, com as pastas dentro).

@export var detail := ""
## Todos ligados ("!" = desligado); vazio = sempre. Vale na hora: um marcador ligado no meio da noite já muda a sala
## (a não ser que `from_night` ainda não tenha chegado).
@export var requires: PackedStringArray = []
@export_range(1, 15) var from_night := 1
