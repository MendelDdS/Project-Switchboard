extends BureaucracyRule
## B4. Gravação de conversas em fitas: as autoridades marcam ligações (`TransferCall.suspicious`; o operador vê o aviso
## no começo dela); o operador põe uma fita do compartimento no gravador, prende a tecla REC e escuta a conversa
## (`Eavesdrop`, com a desconfiança de sempre; a ordem não importa): a fita grava a conversa e as palavras-chave que ele
## ouvir dela (`Bureaucracy.tapes`). Tirada do gravador, fica na mesa e, no fim do turno, é entregue e vale pontos de
## eficiência pelo valor; descartada da mesa (ou esquecida no gravador no fim da noite), se perde. Os
## dois notaram a escuta numa ligação marcada: advertência na gravidade da regra (trabalho malfeito para as autoridades,
## que pediram), no lugar da por escuta. `tapes_per_night` virgens por noite. Ligação marcada sem a fita dela entregue:
## nada na hora (as autoridades não sabem o que ela tinha); `found_after` noites depois descobrem e vem a advertência
## de descuido (`missed_severity`, `missed_text`), e o marcador `authorities_questioning_pending` fica para o roteiro.
## Só as ligações do roteiro vêm marcadas (`TransferCall.suspicious`).
## Equipamentos (`equipment` no `.tres`): o compartimento de fitas e o gravador chegam na mesa na primeira vez que ela vale e
## ficam (`keep_equipment`), mesmo desligada.
##
## Roteiro: `activate("b4_fitas")` (os equipamentos chegam; `equipment_unlocked` avisa para encenar a chegada).

@export var tapes_per_night := 3
@export var points_per_word := 5   ## (com 10, uma fita de quatro palavras valia mais que uma advertência grave)
@export var max_tape_points := 20   ## o máximo de uma fita, o de uma emergência resolvida a tempo
@export var found_after := 2   ## noites até as autoridades darem pela ligação marcada que não chegou gravada
@export var missed_severity := ShiftReport.Severity.MEDIUM
@export var missed_text := "FAULT_TAPE_MISSED"

var _marked: Array[PhoneCall] = []   ## as ligações marcadas nesta noite


func night_started() -> void:
	desk.tapes.rule_id = id
	desk.tapes.per_word = points_per_word
	desk.tapes.max_points = max_tape_points
	desk.tapes.mark_key = "b4"
	desk.tapes.reset(tapes_per_night)
	_marked.clear()


func call_started(c: PhoneCall) -> Array:
	var t := c.data as TransferCall
	if t != null and t.suspicious:
		_marked.append(c)
		c.meta["b4"] = true
		c.sys(T.text(T.Key.SYS_RECORD_REQUEST))
	return []


## A chave de escuta subiu com fita no gravador: a fita passa a gravar esta conversa.
func listening(n: int, on: bool) -> void:
	var c := desk.main.eavesdrop.call_of(n)
	if on and c != null and desk.tapes.recording():
		desk.tapes.bind(c)


func clue_heard(k: Clue) -> void:
	if not desk.tapes.recording():
		return
	desk.tapes.bind(k.call)
	if desk.tapes.inside.call == k.call:
		desk.tapes.inside.words.append(k.word)


## A conversa gravada acabou: a REC solta sozinha (a fita já tem a conversa dela).
func call_ended(c: PhoneCall, _reason: PhoneCall.End) -> void:
	if desk.tapes.inside != null and desk.tapes.inside.call == c:
		desk.tapes.rec = false


func caught_listening(c: PhoneCall) -> bool:
	if not c.meta.has("b4"):
		return false
	desk.main.supervisor.fault_later(id, desk.main.supervisor.who(c), severity, T.Key[fault_text])
	desk.log_decision(id, c, "foi pego escutando a ligação marcada", "advertência amanhã")
	return true


func night_ended() -> void:
	desk.tapes.left_behind()
	desk.tapes.hand_over()
	for c in _marked.filter(func(c: PhoneCall): return not desk.tapes.delivered(c)):
		desk.main.supervisor.fault_later(id, desk.main.supervisor.who(c), missed_severity, T.Key[missed_text], found_after)
		desk.main.flags.apply("authorities_questioning_pending")
		desk.log_decision(id, c, "não entregou a gravação da ligação marcada", "advertência daqui a %d noites" % found_after)


func debug_info() -> String:
	var tp := desk.tapes
	var lines := ["Na coluna à direita do painel: clique no compartimento (fita no gravador), conecte a ligação marcada, "
		+ "aperte REC e escute (Z); clique na fita para tirá-la (vai para a mesa); para descartar, clique na pilha.", "virgens: %d · no gravador: %s · marcadas na noite: %d, entregues: %d" % [tp.blank,
		"nada" if tp.inside == null else "%s %s" % [tp.inside.who if tp.inside.who != "" else "virgem", tp.inside.words], _marked.size(),
		_marked.filter(func(c: PhoneCall): return tp.delivered(c)).size()]]
	lines[1] += " · REC %s" % ("presa" if tp.rec else "solta")
	for t in tp.done:
		lines.append("· %s: %s, %d pontos (%s)" % [t.who, t.words, t.value, Bureaucracy.Tapes.Tape.Fate.find_key(t.fate)])
	return "\n".join(lines)


func debug_actions() -> Array:
	return [["Resetar fitas", night_started], ["+1 fita", desk.tapes.add_blank]]
