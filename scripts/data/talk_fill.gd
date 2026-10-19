class_name TalkFill
extends Resource
## Uma lacuna das conversas escutadas (`Motive.talks`, `TransferCall.overheard`): `{key}` na fala vira um dos `values`,
## sorteado uma vez por conversa (a mesma em todas as falas dela). Assim o que se ouve muda de uma ligação para outra
## (a hora, o tempo, a cor) e não dá para decorar. {street} e {house}, uma rua e um número dos setores atendidos,
## vêm do mapa (`GameData.talk_vars`).

## O nome da lacuna, sem as chaves ("hour" para {hour}).
@export var key := ""
## Os valores, cada um servindo em todas as falas que usam a lacuna (concordância e preposição ficam na fala).
@export var values: PackedStringArray = []
