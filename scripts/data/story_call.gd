class_name StoryCall
extends Resource
## Ligação do roteiro de uma noite: um roteiro escrito (TransferCall, EmergencyCall ou PrankCall) num horário fixo.
## Conta como qualquer outra ligação (advertências, retornos, caderno).

## Minutos depois do início do turno (18:00).
@export var at := 60.0
@export var call: Resource
## Só toca se os marcadores baterem na hora de tocar (StoryFlags): todos ligados; com "!" na frente, desligados.
## Ex.: ["prometeu_quermesse", "!senha_hotel_4"].
@export var requires: PackedStringArray = []
## Um pedido das autoridades (polícia, Alta Cúpula, supervisor; o roteiro, a partir da noite 7): o que ela pedir passa
## sem advertência das burocracias, mesmo contra a regra (só o registro de decisões, `Bureaucracy.before_transfer`).
@export var authority := false

@export_group("Desfecho")
## Marcadores ligados ("nome") ou desligados ("!nome") pelo fim da ligação (`StoryFlags.apply`; `{dest}` vira o número
## a que ela foi conectada): transferida para o número pedido (`target`), quando a conversa acaba...
@export var if_connected: PackedStringArray = []
## ...transferida para outro número (um acordo da B2, um engano)...
@export var if_elsewhere: PackedStringArray = []
## ...atendida e encerrada sem transferir (o operador desligou, quem ligou desistiu na espera ou desligou, o turno
## acabou), ou transferida e cortada pelo operador antes do fim da conversa (desobedecer às autoridades)...
@export var if_dropped: PackedStringArray = []
## ...ou deixada tocando até a pessoa desistir.
@export var if_missed: PackedStringArray = []
## Encerrada pelo operador (desligou na cara), além do `if_dropped`.
@export var if_hung_up: PackedStringArray = []
## Gravada (B4) e entregue às autoridades no fim do turno com alguma palavra-chave (`Tapes.hand_over`).
@export var if_delivered: PackedStringArray = []
## Gravada (B4) e dada a Sebastião (o pacote branco, `Tapes.give`), no fim do turno.
@export var if_sebastiao: PackedStringArray = []
## Não atendida ou mal resolvida, a pessoa liga de novo uma vez, como as outras (`Supervisor.call_again`). Desligado,
## não liga: as novas tentativas ficam por conta do roteiro (outras `StoryCall` com `requires`).
@export var again := true
