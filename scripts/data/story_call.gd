class_name StoryCall
extends Resource
## Ligação do roteiro de uma noite: um roteiro escrito (TransferCall, EmergencyCall ou PrankCall) num horário fixo.
## Conta como qualquer outra ligação (advertências, retornos, caderno).

## Minutos depois do início do turno (18:00).
@export var at := 60.0
@export var call: Resource
## Só toca se os marcadores baterem na hora de tocar (StoryFlags): todos ligados; com "!" na frente, desligados.
## Ex.: ["respondeu_a_luz", "!ligou_de_volta_1"].
@export var requires: PackedStringArray = []
## Um pedido das autoridades (polícia, Alta Cúpula, supervisor; o roteiro, a partir da noite 7): o que ela pedir passa
## sem advertência das burocracias, mesmo contra a regra (só o registro de decisões, `Bureaucracy.before_transfer`).
@export var authority := false

@export_group("Desfecho")
## Marcadores ligados ("nome") ou desligados ("!nome") pelo fim da ligação (`StoryFlags.apply`; `{dest}` vira o número
## a que ela foi conectada): transferida para o número pedido (`target`)...
@export var if_connected: PackedStringArray = []
## ...transferida para outro número (um acordo da B2, um engano)...
@export var if_elsewhere: PackedStringArray = []
## ...atendida e encerrada sem transferir (o operador desligou, quem ligou desistiu na espera ou desligou, o turno
## acabou)...
@export var if_dropped: PackedStringArray = []
## ...ou deixada tocando até a pessoa desistir.
@export var if_missed: PackedStringArray = []
## Gravada (B4) e entregue às autoridades no fim do turno com alguma palavra-chave (`Tapes.hand_over`).
@export var if_delivered: PackedStringArray = []
## Não atendida ou mal resolvida, a pessoa liga de novo uma vez, como as outras (`Supervisor.call_again`). Desligado,
## não liga: as novas tentativas ficam por conta do roteiro (outras `StoryCall` com `requires`).
@export var again := true
