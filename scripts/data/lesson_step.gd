class_name LessonStep
extends Resource
## Um passo do treinamento da noite 0 (`Night.lesson`): a telefonista veterana (`Night.teacher`) liga, explica e
## espera o jogador fazer cada coisa na mesa, como uma colega ao lado. Quem conduz é o `Training`; aqui só o roteiro.

enum Kind {
	RING,      ## ela liga pela entrada `line` e espera o jogador atender (com `call`, a ligação é esse pedido de transferência)
	SAY,       ## ela diz `text` (e espera `seconds`, se houver)
	OPERATOR,  ## o operador escolhe uma das `options`
	WAIT,      ## espera o jogador fazer `until`; `hint` vai no papel do manual
	PAUSE,     ## silêncio de `seconds`
	HANG_UP,   ## ela desliga
}

@export var kind := Kind.SAY
@export_multiline var text := ""
@export var options: PackedStringArray = []
@export var seconds := 0.0
## RING: a entrada por onde ela liga.
@export var line := 1
## RING: a emergência de treino desta ligação (ela finge pedir socorro): o despacho a espera como uma de verdade
## (`Dispatch.set_incident`), mas a chegada não vai para o relatório nem para o jornal.
@export var emergency: EmergencyCall
## RING: o pedido de transferência que ela faz nesta ligação (vazio = ligação só para conversar). O destino sempre
## atende e a ligação completa sai do treinamento como as outras (os dois conectados pelo cabo).
@export var call: TransferCall
## WAIT: o que o jogador precisa fazer (`Training.done`):
## "directory" (abriu a lista telefônica), "cord_out" (um cabo de conexão na saída da linha dela), "cord_dest" (a
## outra ponta no destino que ela pediu), "transfer" (apertou Transferir), "connected" (o destino atendeu e os dois
## ficaram ligados), "line_done" (a conversa dos dois terminou: lâmpada vermelha), "line_free" (o jogador tirou as
## pontas do cabo), "logbook" (abriu o caderno), "registered" (nada mais esperando registro no caderno), "call_log"
## (abriu a prancheta do registro), "dispatch" (abriu a unidade de despacho), "card" (saiu um cartão para o lugar
## `street`/`block`; vazio = o da emergência de treino), "shred" (o cartão foi para a trituradora), "punched" (o cartão
## do lugar da emergência de treino perfurado com o tipo e as unidades dela), "sent" (um cartão entrou no
## transmissor), "arrived" (as unidades chegaram à emergência de treino e o rádio falou), "hold" (o FONE saiu da
## entrada dela: ela ficou em espera), "resume" (o FONE voltou para a entrada dela).
@export_enum("directory", "cord_out", "cord_dest", "transfer", "connected", "line_done", "line_free", "logbook",
		"registered", "call_log", "dispatch", "card", "shred", "punched", "sent", "arrived", "hold", "resume") var until := "directory"
## WAIT "card": o lugar do cartão (`id` da rua e trecho, como em `EmergencyCall`); vazio = o da emergência de treino.
@export var street := ""
@export_range(0, 5) var block := 0
## RING e WAIT: a dica do manual enquanto o jogador não faz (com %d, a entrada da ligação).
@export_multiline var hint := ""
## WAIT: o que ela diz se o jogador demorar `seconds` (uma de cada vez, na ordem; só se ela estiver na linha).
@export var nudges: PackedStringArray = []
## WAIT: o que ela diz quando o jogador faz errado (cabo no lugar errado, com %d a tomada; em "registered", um tipo
## que não é Comum; em "card", o cartão de outro lugar; em "punched", um furo errado; só se ela estiver na linha).
@export var wrong := ""
